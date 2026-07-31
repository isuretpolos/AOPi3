#include "esp_system.h"
#include "esp_random.h"
#include "bootloader_random.h"

void setup() {
  Serial.begin(921600);
  delay(1000);
  // Activate entropy
  bootloader_random_enable();
}

void loop() {
  uint8_t buffer[256];
  esp_fill_random(buffer, sizeof(buffer));
  Serial.write(buffer, sizeof(buffer));
}
