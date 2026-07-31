#include "esp32_random.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cstring>
#include <climits>

#ifndef _WIN32
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#endif

using namespace godot;

#ifndef _WIN32
static speed_t _baud_to_speed(int p_baud) {
    switch (p_baud) {
        case 9600: return B9600;
        case 19200: return B19200;
        case 38400: return B38400;
        case 57600: return B57600;
        case 115200: return B115200;
        case 230400: return B230400;
#ifdef B460800
        case 460800: return B460800;
#endif
#ifdef B921600
        case 921600: return B921600;
#endif
        default: return B115200;
    }
}
#endif

ESP32Random::ESP32Random() {}

ESP32Random::~ESP32Random() {
    close_port();
}

void ESP32Random::_bind_methods() {
    ClassDB::bind_method(D_METHOD("open_port", "path", "baudrate"), &ESP32Random::open_port);
    ClassDB::bind_method(D_METHOD("close_port"), &ESP32Random::close_port);
    ClassDB::bind_method(D_METHOD("is_open"), &ESP32Random::is_open);
    ClassDB::bind_method(D_METHOD("get_random_bytes", "count"), &ESP32Random::get_random_bytes);
    ClassDB::bind_method(D_METHOD("get_random_int", "min", "max"), &ESP32Random::get_random_int);
    ClassDB::bind_method(D_METHOD("get_random_int_array", "min", "max", "count"), &ESP32Random::get_random_int_array);
    ClassDB::bind_method(D_METHOD("get_random_float"), &ESP32Random::get_random_float);
}

bool ESP32Random::open_port(const String &p_path, int p_baudrate) {
    close_port();

#ifdef _WIN32
    String win_path = p_path;
    if (!win_path.begins_with("\\\\.\\")) {
        win_path = "\\\\.\\" + win_path;
    }
    serial_handle = CreateFileA(win_path.utf8().get_data(), GENERIC_READ | GENERIC_WRITE,
                                 0, NULL, OPEN_EXISTING, 0, NULL);
    if (serial_handle == INVALID_HANDLE_VALUE) {
        UtilityFunctions::printerr("ESP32Random: Konnte Port nicht oeffnen: ", p_path);
        return false;
    }

    DCB dcb;
    ZeroMemory(&dcb, sizeof(dcb));
    dcb.DCBlength = sizeof(dcb);
    if (!GetCommState(serial_handle, &dcb)) {
        CloseHandle(serial_handle);
        serial_handle = INVALID_HANDLE_VALUE;
        return false;
    }
    dcb.BaudRate = (DWORD)p_baudrate;
    dcb.ByteSize = 8;
    dcb.StopBits = ONESTOPBIT;
    dcb.Parity = NOPARITY;
    dcb.fBinary = TRUE;
    dcb.fParity = FALSE;
    if (!SetCommState(serial_handle, &dcb)) {
        CloseHandle(serial_handle);
        serial_handle = INVALID_HANDLE_VALUE;
        return false;
    }

    COMMTIMEOUTS timeouts;
    ZeroMemory(&timeouts, sizeof(timeouts));
    timeouts.ReadIntervalTimeout = 20;
    timeouts.ReadTotalTimeoutConstant = 200;
    timeouts.ReadTotalTimeoutMultiplier = 5;
    SetCommTimeouts(serial_handle, &timeouts);

    PurgeComm(serial_handle, PURGE_RXCLEAR | PURGE_TXCLEAR);

    port_open = true;
    return true;
#else
    serial_fd = ::open(p_path.utf8().get_data(), O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (serial_fd < 0) {
        UtilityFunctions::printerr("ESP32Random: Konnte Port nicht oeffnen: ", p_path);
        return false;
    }

    struct termios tty;
    memset(&tty, 0, sizeof(tty));
    if (tcgetattr(serial_fd, &tty) != 0) {
        ::close(serial_fd);
        serial_fd = -1;
        return false;
    }

    speed_t speed = _baud_to_speed(p_baudrate);
    cfsetispeed(&tty, speed);
    cfsetospeed(&tty, speed);

    tty.c_cflag |= (CLOCAL | CREAD);
    tty.c_cflag &= ~PARENB;
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CSIZE;
    tty.c_cflag |= CS8;
    tty.c_cflag &= ~CRTSCTS;

    tty.c_lflag = 0; // raw input, kein Kanonik-Modus
    tty.c_iflag &= ~(IXON | IXOFF | IXANY);
    tty.c_iflag &= ~(ICRNL | INLCR);
    tty.c_oflag = 0;

    tty.c_cc[VMIN] = 0;
    tty.c_cc[VTIME] = 2; // 0.2s Timeout pro read()

    tcflush(serial_fd, TCIFLUSH);
    if (tcsetattr(serial_fd, TCSANOW, &tty) != 0) {
        ::close(serial_fd);
        serial_fd = -1;
        return false;
    }

    // zurueck auf blockierend fuer read() mit VTIME-Timeout
    int flags = fcntl(serial_fd, F_GETFL, 0);
    fcntl(serial_fd, F_SETFL, flags & ~O_NONBLOCK);

    port_open = true;
    return true;
#endif
}

void ESP32Random::close_port() {
#ifdef _WIN32
    if (serial_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(serial_handle);
        serial_handle = INVALID_HANDLE_VALUE;
    }
#else
    if (serial_fd >= 0) {
        ::close(serial_fd);
        serial_fd = -1;
    }
#endif
    port_open = false;
    byte_buffer.clear();
}

bool ESP32Random::is_open() const {
    return port_open;
}

bool ESP32Random::_fill_buffer(size_t p_min_bytes) {
    if (!port_open) {
        return false;
    }

    uint8_t chunk[512];
    int stale_attempts = 0;
    const int max_stale_attempts = 100; // ~ mehrere Sekunden Timeout insgesamt

    while (byte_buffer.size() < p_min_bytes) {
        int n = 0;
#ifdef _WIN32
        DWORD read_bytes = 0;
        if (ReadFile(serial_handle, chunk, sizeof(chunk), &read_bytes, NULL)) {
            n = (int)read_bytes;
        }
#else
        n = (int)::read(serial_fd, chunk, sizeof(chunk));
        if (n < 0) {
            n = 0;
        }
#endif
        if (n > 0) {
            byte_buffer.insert(byte_buffer.end(), chunk, chunk + n);
            stale_attempts = 0;
        } else {
            stale_attempts++;
            if (stale_attempts >= max_stale_attempts) {
                UtilityFunctions::printerr("ESP32Random: Timeout beim Lesen vom seriellen Port.");
                return false;
            }
        }
    }
    return true;
}

uint32_t ESP32Random::_pop_uint32() {
    uint32_t v = ((uint32_t)byte_buffer[0]) |
                 ((uint32_t)byte_buffer[1] << 8) |
                 ((uint32_t)byte_buffer[2] << 16) |
                 ((uint32_t)byte_buffer[3] << 24);
    byte_buffer.erase(byte_buffer.begin(), byte_buffer.begin() + 4);
    return v;
}

PackedByteArray ESP32Random::get_random_bytes(int p_count) {
    PackedByteArray result;
    if (p_count <= 0) {
        return result;
    }
    if (!_fill_buffer((size_t)p_count)) {
        return result;
    }
    result.resize(p_count);
    for (int i = 0; i < p_count; i++) {
        result[i] = byte_buffer[i];
    }
    byte_buffer.erase(byte_buffer.begin(), byte_buffer.begin() + p_count);
    return result;
}

int ESP32Random::get_random_int(int p_min, int p_max) {
    if (p_max < p_min) {
        int tmp = p_min;
        p_min = p_max;
        p_max = tmp;
    }

    uint64_t range64 = (uint64_t)((int64_t)p_max - (int64_t)p_min) + 1ULL;

    if (range64 >= 0x100000000ULL) {
        // Bereich deckt (fast) den kompletten uint32-Raum ab
        if (!_fill_buffer(4)) {
            return p_min;
        }
        uint32_t value = _pop_uint32();
        return p_min + (int)value;
    }

    uint32_t range = (uint32_t)range64;
    uint32_t limit = (uint32_t)(0xFFFFFFFFU - (0xFFFFFFFFU % range));

    uint32_t value;
    do {
        if (!_fill_buffer(4)) {
            return p_min;
        }
        value = _pop_uint32();
    } while (value >= limit); // Rejection Sampling gegen Modulo-Bias

    return p_min + (int)(value % range);
}

PackedInt32Array ESP32Random::get_random_int_array(int p_min, int p_max, int p_count) {
    PackedInt32Array arr;
    if (p_count <= 0) {
        return arr;
    }
    arr.resize(p_count);
    for (int i = 0; i < p_count; i++) {
        arr[i] = get_random_int(p_min, p_max);
    }
    return arr;
}

float ESP32Random::get_random_float() {
    if (!_fill_buffer(4)) {
        return 0.0f;
    }
    uint32_t v = _pop_uint32();
    return (float)v / (float)UINT32_MAX;
}
