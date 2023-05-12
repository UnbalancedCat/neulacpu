#pragma once

#include <cstdlib>
#include <cstdio>
#include <ctime>
#include <cstring>
#include <fstream>

#ifndef COMMON_H__
#define COMMON_H__

#ifdef DEBUG_MODE
#define Log(fmt, ...) printf("[%s:%d %ld] " fmt "\n", __FILE__, __LINE__, clock(), ## __VA_ARGS__)

#define panic(x) do {   \
  Log(x);               \
  exit(EXIT_FAILURE);   \
} while (0)

#define panicifnot(cond) do {   \
    if (!(cond)) {              \
        Log(#cond " fail");     \
        exit(EXIT_FAILURE);     \
    }                           \
} while (0)

#else

#define Log(...)
#define panic(x)
#define panicifnot(cond)

#endif

#endif

