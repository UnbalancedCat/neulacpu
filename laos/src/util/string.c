#include "string.h"
#include "latype.h"

// mem ops could be more better
// use loop unrolling

void *memset(void *dst, int c, uint n) {
    char *cdst = (char *) dst;
    for (uint i = 0; i < n; ++i) {
        cdst[i] = c;
    }
    return dst;
}

int memcmp(const void *m1, const void *m2, uint n) {
    const uchar *s1, *s2;

    s1 = m1;
    s2 = m2;

    while (n --> 0) {
        if(*s1 != *s2)
            return *s1 - *s2;
        s1++;
        s2++;
    }

    return 0;
}

void *memmove(void *dst, const void *src, uint n) {
    const char *s;
    char *d;

    if(n == 0)
        return dst;
    
    s = src;
    d = dst;
    if(s < d && s + n > d){
        s += n;
        d += n;
        while(n-- > 0)
            *--d = *--s;
    } else
        while(n-- > 0)
            *d++ = *s++;

    return dst;
}

void *memcpy(void *dst, const void *src, uint n) {
    return memmove(dst, src, n);
}

int strncmp(const char *p, const char *q, uint n) {
    while(n > 0 && *p && *p == *q)
        n--, p++, q++;
    if(n == 0)
        return 0;
    return (uchar)*p - (uchar)*q;
}

char *strncpy(char *s, const char *t, int n) {
    char *os;

    os = s;
    while(n-- > 0 && (*s++ = *t++) != 0)
        ;
    while(n-- > 0)
        *s++ = 0;
    return os;
}

char *strcpy_s(char *s, const char *t, int n) {
    char *os;

    os = s;
    if(n <= 0)
        return os;
    while(--n > 0 && (*s++ = *t++) != 0)
        ;
    *s = 0;
    return os;
}

int strlen(const char *s) {
    int n;

    for(n = 0; s[n]; n++)
        ;
    return n;
}