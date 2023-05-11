#pragma once

#include <sysbus.hh>

class LA32R {
public:
  LA32R(SystemBus *bus);
  void Step(unsigned in);
};