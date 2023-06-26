#include "console.h"
#include "memio.h"
#include "memlayout.h"
#include "spinlock.h"
#include "dev.h"

void consputc(int c) {
  volatile char *out = &ioports[SERIAL_OFFSET];
  if (c == '\b') {
    *out = '\b';
    *out = ' ';
    *out = '\b';
    return;
  }

  *out = c;
}

struct {
  struct spinlock lock;

  // input
#define INPUT_BUF_SIZE 128
  char buf[INPUT_BUF_SIZE];
  uint r; // Read index
  uint w; // Write index
  uint e; // Edit index
} cons;
