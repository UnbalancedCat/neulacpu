#include "defs.h"

#ifndef KERNEL_H__
#define KERNEL_H__

void _entry() __attribute__ ((section (".entry")));

void start();
void main();

#endif