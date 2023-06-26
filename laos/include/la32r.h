

#include "asm.h"
#include "defs.h"
#include "latype.h"
#include "macro.h"

#ifndef __loongarch32r
#define __loongarch32r
#endif

#include "larchintrin.h"

#ifndef LA32R_H__
#define LA32R_H__

static inline uint r_crmd() {
    uint recv;
    asm volatile ("csrrd %0, " TOSTRING(CRMD) : "=r" (recv));
    return recv;
}

static inline void w_crmd(uint wdata) {
    asm volatile ("csrwr %0, " TOSTRING(CRMD) : "=r" (wdata));
}

static inline void w_eentry(uint wdata) {
    asm volatile ("csrwr %0, " TOSTRING(EENTRY) : "=r" (wdata));
}

static inline uint r_cpuid() {
    uint recv;
    asm volatile ("csrrd %0, " TOSTRING(CPUID) : "=r" (recv));
    return recv;
}

//
// specified register io
//

static inline uint r_sp() {
    uint recv;
    asm volatile ("add.w %0, $sp, $zero" : "=r" (recv));
    return recv;
}

static inline uint r_tp() {
    uint recv;
    asm volatile ("add.w %0, $tp, $zero" : "=r" (recv));
    return recv;
}

static inline void w_tp(uint wdata) {
    asm volatile("add.w $tp, %0, $zero" : : "r" (wdata));
}

static inline uint r_ra() {
    uint recv;
    asm volatile ("add.w %0, $ra, $zero" : "=r" (recv));
    return recv;
}

//
// mem misc
//

// need to be tested
static inline void synchronize() {
    __dbar(0);
    __ibar(0);
}


//
// tlb misc
//

//
// cache misc
//


//
// atomic
//

static inline uint llw(intptr_t addr) {
    uint recv;
    asm volatile ("ll.w %0, %1, 0": "=r" (recv) : "r" (addr));
    return recv;
}

static inline uint scw(uint wdata, intptr_t addr) {
    uint recv;
    asm volatile (
        "add.w %0, %1, $zero" "\n\t"
        "sc.w %0, %2, 0"
        : "=r" (recv)
        : "r"  (wdata),
          "r"  (addr));
    return recv;
}



#endif