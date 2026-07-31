#ifndef ESP32_RANDOM_H
#define ESP32_RANDOM_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <vector>
#include <cstdint>

#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#endif

namespace godot {

class ESP32Random : public RefCounted {
    GDCLASS(ESP32Random, RefCounted)

private:
#ifdef _WIN32
    HANDLE serial_handle = INVALID_HANDLE_VALUE;
#else
    int serial_fd = -1;
#endif
    std::vector<uint8_t> byte_buffer;
    bool port_open = false;

    bool _fill_buffer(size_t p_min_bytes);
    uint32_t _pop_uint32();

protected:
    static void _bind_methods();

public:
    ESP32Random();
    ~ESP32Random();

    bool open_port(const String &p_path, int p_baudrate);
    void close_port();
    bool is_open() const;

    PackedByteArray get_random_bytes(int p_count);
    int get_random_int(int p_min, int p_max);
    PackedInt32Array get_random_int_array(int p_min, int p_max, int p_count);
    float get_random_float();
};

} // namespace godot

#endif // ESP32_RANDOM_H
