#pragma once

#include <device.hh>

class Memory : public WRDevice<Memory> {
  char *data;
  bool wen;
  bool ren;
  bool xen;
public:
  Memory(size_t siz, bool w = true, bool r = true, bool x = true);
  ~Memory();

  void load(const char *path);
  void load(Memory *mem, size_t addr, size_t len);

  void write(char *buf, size_t addr, size_t len);
  void read(char *buf, size_t addr, size_t len);
};