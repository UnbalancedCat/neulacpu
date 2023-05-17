#pragma once

#include <cstdint>
#include <cstdlib>
#include <map>

#include <device.hh>

class SystemBus {
  std::map<uint64_t, Device *> iomap_;

  std::pair<const uint64_t, Device *> &finddev(uint64_t addr);

public:
  SystemBus() = default;

  void regdev(Device *dev, uint64_t addr);

  void write(char *buf, size_t addr, size_t len);
  void read(char *buf, size_t addr, size_t len);

  void write64(uint64_t &dword, size_t addr);
  void read64(uint64_t &dword, size_t addr);

  void write32(uint32_t &word, size_t addr);
  void read32(uint32_t &word, size_t addr);

  void write16(uint16_t &hword, size_t addr);
  void read16(uint16_t &hword, size_t addr);

  void write8(uint8_t &byte, size_t addr);
  void read8(uint8_t &byte, size_t addr);
};