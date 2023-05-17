#include "asm.h"

.section .entry
.global _entry
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + (hartid * 4096)
        la.global $sp, stack0
        lu12i.w $a0, (1024*4 >> 12) & 0xfffff
        addi.w $a0, $a0, 1024*4 & 0xfff
        csrrd $a1, CPUID
        addi.w $a1, $a1, 1
        mul.w $a0, $a0, $a1
        add.w $sp, $sp, $a0
        # jump to start() in start.c
        bl start
spin:
        b spin