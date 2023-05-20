#include "latype.h"

#ifndef STRING_H__
#define STRING_H__

void   *memset  (void *dst  , int c, uint n);
int     memcmp  (const void *m1, const void *m2, uint n);
void   *memmove (void *dst, const void *src, uint n);
void   *memcpy  (void *dst, const void *src, uint n);

int     strncmp (const char *p, const char *q, uint n);
char   *strncpy (char *s, const char *t, int n);
char   *strcpy_s(char *s, const char *t, int n);
int     strlen  (const char *s);

#endif