#pragma once

#include <cstdint>
#include <cstdlib>

class Device {
public:
  Device() = default;

  virtual const size_t &size() const = 0;

  virtual void write(char *buf, size_t addr, size_t len) = 0;
  virtual void read(char *buf, size_t addr, size_t len) = 0;

  virtual void write64(uint64_t &dword, size_t addr) = 0;
  virtual void read64(uint64_t &dword, size_t addr) = 0;

  virtual void write32(uint32_t &word, size_t addr) = 0;
  virtual void read32(uint32_t &word, size_t addr) = 0;

  virtual void write16(uint16_t &hword, size_t addr) = 0;
  virtual void read16(uint16_t &hword, size_t addr) = 0;

  virtual void write8(uint8_t &byte, size_t addr) = 0;
  virtual void read8(uint8_t &byte, size_t addr) = 0;

  virtual ~Device() = default;
};

template <typename T>
class WRDevice : public Device{
  size_t devsiz;
public:
  WRDevice(size_t siz);

  virtual const size_t &size() const;

  virtual void write(char *buf, size_t addr, size_t len);
  virtual void read(char *buf, size_t addr, size_t len);

  virtual void write64(uint64_t &dword, size_t addr);
  virtual void read64(uint64_t &dword, size_t addr);

  virtual void write32(uint32_t &word, size_t addr);
  virtual void read32(uint32_t &word, size_t addr);

  virtual void write16(uint16_t &hword, size_t addr);
  virtual void read16(uint16_t &hword, size_t addr);

  virtual void write8(uint8_t &byte, size_t addr);
  virtual void read8(uint8_t &byte, size_t addr);

  virtual ~WRDevice() = default;
};

template <typename T>
WRDevice<T>::WRDevice(size_t siz) : devsiz(siz) {}

template <typename T>
const size_t &WRDevice<T>::size() const { return devsiz; }

template <typename T>
void WRDevice<T>::write(char *buf, size_t addr, size_t len) {}

template <typename T>
void WRDevice<T>::read(char *buf, size_t addr, size_t len) {}

template <typename T>
void WRDevice<T>::write64(uint64_t &dword, size_t addr) {
  uint8_t buf[sizeof(dword)];
  buf[0] = (dword >>  0) & 0xFF;
  buf[1] = (dword >>  8) & 0xFF;
  buf[2] = (dword >> 16) & 0xFF;
  buf[3] = (dword >> 24) & 0xFF;
  buf[4] = (dword >> 32) & 0xFF;
  buf[5] = (dword >> 40) & 0xFF;
  buf[6] = (dword >> 48) & 0xFF;
  buf[7] = (dword >> 56) & 0xFF;
  static_cast<T *>(this)->write((char *)buf, addr, sizeof(dword));
}

template <typename T>
void WRDevice<T>::read64(uint64_t &dword, size_t addr) {
  uint8_t buf[sizeof(dword)];
  static_cast<T *>(this)->read((char *)buf, addr, sizeof(dword));
  dword =  (uint64_t) buf[0];
  dword |= (uint64_t) buf[1] << 8;
  dword |= (uint64_t) buf[2] << 16;
  dword |= (uint64_t) buf[3] << 24;
  dword |= (uint64_t) buf[4] << 32;
  dword |= (uint64_t) buf[5] << 40;
  dword |= (uint64_t) buf[6] << 48;
  dword |= (uint64_t) buf[7] << 56;
}

template <typename T>
void WRDevice<T>::write32(uint32_t &word, size_t addr) {
  uint8_t buf[sizeof(word)];
  buf[0] = (word >>  0) & 0xFF;
  buf[1] = (word >>  8) & 0xFF;
  buf[2] = (word >> 16) & 0xFF;
  buf[3] = (word >> 24) & 0xFF;
  static_cast<T *>(this)->write((char *)buf, addr, sizeof(word));
}

template <typename T>
void WRDevice<T>::read32(uint32_t &word, size_t addr) {
  uint8_t buf[sizeof(word)];
  static_cast<T *>(this)->read((char *)buf, addr, sizeof(word));
  word =  (uint32_t) buf[0];
  word |= (uint32_t) buf[1] << 8;
  word |= (uint32_t) buf[2] << 16;
  word |= (uint32_t) buf[3] << 24;
}

template <typename T>
void WRDevice<T>::write16(uint16_t &hword, size_t addr) {
  uint8_t buf[sizeof(hword)];
  buf[0] = (hword >>  0) & 0xFF;
  buf[1] = (hword >>  8) & 0xFF;
  static_cast<T *>(this)->write((char *)buf, addr, sizeof(hword));
}

template <typename T>
void WRDevice<T>::read16(uint16_t &hword, size_t addr) {
  uint8_t buf[sizeof(hword)];
  static_cast<T *>(this)->read((char *)buf, addr, sizeof(hword));
  hword =  (uint16_t) buf[0];
  hword |= (uint16_t) buf[1] << 8;
}

template <typename T>
void WRDevice<T>::write8(uint8_t &byte, size_t addr) {
  static_cast<T *>(this)->write((char *)&byte, addr, sizeof(byte));
}

template <typename T>
void WRDevice<T>::read8(uint8_t &byte, size_t addr) {
  static_cast<T *>(this)->read((char *)&byte, addr, sizeof(byte));
}