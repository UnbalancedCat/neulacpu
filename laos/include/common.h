#include "defs.h"

#ifndef COMMON_H__
#define COMMON_H__

void main();
void start();
void _entry() __attribute__ ((section (".entry")));

#endif // COMMON_H__