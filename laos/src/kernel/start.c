#include "kernel.h"
#include "la32r.h"

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

void start() {
    // 设置特权等级
    volatile u32 crmd_info = r_crmd();
    crmd_info = crmd_info & 0xfffffffc;
    w_crmd(crmd_info);

    // ERTN 返回地址
    w_eentry((intptr_t)main);

    // 设置 tp
    int id = r_cpuid();
    w_tp(id);

    asm volatile("ertn");
}