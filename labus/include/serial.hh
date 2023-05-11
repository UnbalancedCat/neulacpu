#pragma once

#include <device.hh>

class Serial : public WRDevice<Serial> {
public:
  Serial(size_t siz);

  void write(char *buf, size_t addr, size_t len);
};