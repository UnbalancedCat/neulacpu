#include "console.h"
#include "memio.h"
#include "memlayout.h"
#include "spinlock.h"

void consputc(int c) {
    if (c == '\b') {
        memb(SERIAL_ADDR) = '\b';
        memb(SERIAL_ADDR) =  ' ';
        memb(SERIAL_ADDR) = '\b';
        return;
    }

    memb(SERIAL_ADDR) = c;
}

struct {
  struct spinlock lock;
  
  // input
#define INPUT_BUF_SIZE 128
  char buf[INPUT_BUF_SIZE];
  uint r;  // Read index
  uint w;  // Write index
  uint e;  // Edit index
} cons;


