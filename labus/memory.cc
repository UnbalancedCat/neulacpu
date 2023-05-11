#include <memory.hh>
#include <common.h>

Memory::Memory(size_t siz, bool w, bool r, bool x)
    : WRDevice(siz), wen(w), ren(r), xen(x) {
  data = new char[siz];
  memset((void *)data, 0, siz);
}

Memory::~Memory() {
  if (data) {
    delete [] data;
  }
}

void Memory::load(const char *path) {
  std::fstream ifs(path, std::ios::in | std::ios::binary);
  panicifnot(ifs);
  ifs.read(data, this->size());
  ifs.close();
}

void Memory::load(Memory *mem, size_t addr, size_t len) {
  panicifnot(addr + len < this->size());
  memcpy(&data[addr], mem->data, len);
}

void Memory::write(char *buf, size_t addr, size_t len) {
  if (!wen)
    panic("permission denied");
  size_t actlen = addr + len >= this->size() ? this->size() - addr : len;
  memcpy(&data[addr], buf, actlen);
}

void Memory::read(char *buf, size_t addr, size_t len) {
  if (!ren)
    panic("permission denied");
  size_t actlen = addr + len >= this->size() ? this->size() - addr : len;
  memcpy(buf, &data[addr], actlen);
}