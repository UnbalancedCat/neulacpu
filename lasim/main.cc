#include <iostream>

#include <sysbus.hh>
#include <memory.hh>
#include <serial.hh>
#include <la32r.hh>
#include <common.h>
#include <devaddr.h>

int main(int argc, char *argv[]) {
  // if (argc < 2) {
  //   std::cout << "Usage: sim <bin>";
  //   return 0;
  // }

  SystemBus bus;
  Memory ram(2 * 1024 * 1024);
  Memory stk(256 * 1024);

  Memory flash(1024 * 1024);
  flash.load("../laos/build/neula-os");
  ram.load(&flash, 0x0, flash.size());

  bus.regdev(&ram,  RAM_ADDR);
  bus.regdev(&stk,  STK_ADDR);

  Serial bios(1);
  bus.regdev(&bios, SERIAL_PORT);

  auto cpu = new LA32R(&bus);

  while (true) {
    cpu->Step(1);
  }

  delete cpu;
  return 0;
}