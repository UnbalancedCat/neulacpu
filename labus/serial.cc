#include <serial.hh>
#include <common.h>

Serial::Serial(size_t siz) : WRDevice(siz) {}

void Serial::write(char *buf, size_t addr, size_t len) {
  for (size_t i = 0; i < len; ++i)
    putc(buf[i], stdout);
  fflush(stdout);
}