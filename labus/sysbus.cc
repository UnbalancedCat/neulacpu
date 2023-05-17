#include <sysbus.hh>
#include <common.h>

std::pair<const uint64_t, Device *> &SystemBus::finddev(uint64_t addr) {
  Device *dev = nullptr;
  auto &&iter = iomap_.upper_bound(addr);
  if (iter == iomap_.begin())
    panic("device not found");
  iter--;
  if (iter->first <= addr && iter->first + iter->second->size() > addr)
    dev = iter->second;
  panicifnot(dev);
  return *iter;
}

void SystemBus::regdev(Device *dev, uint64_t addr) { iomap_.emplace(addr, dev); }

void SystemBus::write(char *buf, size_t addr, size_t len) {
  auto &&dev = finddev(addr);
  dev.second->write(buf, addr - dev.first, len);
}

void SystemBus::read(char *buf, size_t addr, size_t len) {
  auto &&dev = finddev(addr);
  dev.second->read(buf, addr - dev.first, len);
}

void SystemBus::write64(uint64_t &dword, size_t addr) {
  auto &&dev = finddev(addr);
  dev.second->write64(dword, addr - dev.first);
}

void SystemBus::read64(uint64_t &dword, size_t addr) {
  auto &&dev = finddev(addr);
  dev.second->read64(dword, addr - dev.first);
}

void SystemBus::write32(uint32_t &word, size_t addr) {
  auto &&dev = finddev(addr);
  dev.second->write32(word, addr - dev.first);
}

void SystemBus::read32(uint32_t &word, size_t addr) {
  auto &&dev = finddev(addr);
  dev.second->read32(word, addr - dev.first);
}

void SystemBus::write16(uint16_t &hword, size_t addr) {
  auto &&dev = finddev(addr);
  dev.second->write16(hword, addr - dev.first);
}

void SystemBus::read16(uint16_t &hword, size_t addr) {
  auto &&dev = finddev(addr);
  dev.second->read16(hword, addr - dev.first);
}

void SystemBus::write8(uint8_t &byte, size_t addr) {
  auto &&dev = finddev(addr);
  dev.second->write8(byte, addr - dev.first);
}

void SystemBus::read8(uint8_t &byte, size_t addr) {
  auto &&dev = finddev(addr);
  dev.second->read8(byte, addr - dev.first);
}