#include "defs.h"

//
// bnm should be large enough to hold basename
//
char *basename(char *bnm, const char *path) {
    const char *p = path;
    const char *last_slash = NULL;
    while (*p) {
        if (*p == '/' || *p == '\\') {
            last_slash = p;
        }
        p++;
    }

    char *q = bnm;
    p = last_slash + 1;
    while (*p) {
        *q++ = *p++;
    }

    return bnm;
}

//
// noext should be large enough to hold no-ext name
//
char *rmext(char *noext, const char *fname) {
    const char *p = fname;
    const char *last_dot = NULL;
    while (*p) {
        if (*p == '.') {
            last_dot = p;
        }
        p++;
    }

    char *q = noext;
    p = fname;
    while (p != last_dot) {
        *q++ = *p++;
    }

    return noext;
}


//
// bnm should be large enough to hold bearname name
//
char *bearname(char *bnm, const char *fname) {
    const char *p = fname;
    const char *last_slash = NULL;
    const char *last_dot = NULL;
    while (*p) {
        if (*p == '/' || *p == '\\') {
            last_slash = p;
        } else if (*p == '.') {
            last_dot = p;
        }
        p++;
    }

    char *q = bnm;
    p = last_slash + 1;
    while (p != last_dot) {
        *q++ = *p++;
    }

    return bnm;
}