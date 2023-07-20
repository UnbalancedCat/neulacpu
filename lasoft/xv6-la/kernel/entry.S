        # qemu -kernel loads the kernel at 0x80000000
        # and causes each hart (i.e. CPU) to jump there.
        # kernel.ld causes the following code to
        # be placed at 0x80000000.
.section .text
.global _entry
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + (hartid * 4096)
        la.global       $sp, stack0
        li.w    $a0, 1024*4
        csrrd   $a1, CPUID
        addi.w  $a1, $a1, 1
        mul.w   $a0, $a0, $a1
        add.w   $sp, $sp, $a0
        # jump to start() in start.c
        bl      start
spin:
        b       spin
