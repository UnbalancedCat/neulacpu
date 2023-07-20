        #
        # interrupts and exceptions while in supervisor
        # mode come here.
        #
        # the current stack is a kernel stack.
        # push all registers, call kerneltrap().
        # when kerneltrap() returns, restore registers, return.
        #
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi.w  $sp, $sp, -128

        # save the registers.
        st.w    $ra, $sp, 0
        st.w    $tp, $sp, 4
        st.w    $sp, $sp, 8
        st.w    $a0, $sp, 12
        st.w    $a1, $sp, 16
        st.w    $a2, $sp, 20
        st.w    $a3, $sp, 24
        st.w    $a4, $sp, 28
        st.w    $a5, $sp, 32
        st.w    $a6, $sp, 36
        st.w    $a7, $sp, 40
        st.w    $t0, $sp, 44
        st.w    $t1, $sp, 48
        st.w    $t2, $sp, 52
        st.w    $t3, $sp, 56
        st.w    $t4, $sp, 60
        st.w    $t5, $sp, 64
        st.w    $t6, $sp, 68
        st.w    $t7, $sp, 72
        st.w    $t8, $sp, 76
        st.w    $u0, $sp, 80
        st.w    $fp, $sp, 84
        st.w    $s0, $sp, 88
        st.w    $s1, $sp, 92
        st.w    $s2, $sp, 96
        st.w    $s3, $sp, 100
        st.w    $s4, $sp, 104
        st.w    $s5, $sp, 108
        st.w    $s6, $sp, 112
        st.w    $s7, $sp, 116
        st.w    $s8, $sp, 120

        # call the C trap handler in trap.c
        bl kerneltrap

        # restore registers.
        ld.w    $ra, $sp, 0
        # not tp (contains hartid), in case we moved CPUs
        ld.w    $sp, $sp, 8
        ld.w    $a0, $sp, 12
        ld.w    $a1, $sp, 16
        ld.w    $a2, $sp, 20
        ld.w    $a3, $sp, 24
        ld.w    $a4, $sp, 28
        ld.w    $a5, $sp, 32
        ld.w    $a6, $sp, 36
        ld.w    $a7, $sp, 40
        ld.w    $t0, $sp, 44
        ld.w    $t1, $sp, 48
        ld.w    $t2, $sp, 52
        ld.w    $t3, $sp, 56
        ld.w    $t4, $sp, 60
        ld.w    $t5, $sp, 64
        ld.w    $t6, $sp, 68
        ld.w    $t7, $sp, 72
        ld.w    $t8, $sp, 76
        ld.w    $u0, $sp, 80
        ld.w    $fp, $sp, 84
        ld.w    $s0, $sp, 88
        ld.w    $s1, $sp, 92
        ld.w    $s2, $sp, 96
        ld.w    $s3, $sp, 100
        ld.w    $s4, $sp, 104
        ld.w    $s5, $sp, 108
        ld.w    $s6, $sp, 112
        ld.w    $s7, $sp, 116
        ld.w    $s8, $sp, 120

        addi    sp, sp, 128

        # return to whatever we were doing in the kernel.
        ertn

        #
        # machine-mode timer interrupt.
        #
.globl timervec
.align 4
timervec:
        # # start.c has set up the memory that mscratch points to:
        # # scratch[0,8,16] : register save area.
        # # scratch[24] : address of CLINT's MTIMECMP register.
        # # scratch[32] : desired interval between interrupts.
        
        # csrrw a0, mscratch, a0
        # sd a1, 0(a0)
        # sd a2, 8(a0)
        # sd a3, 16(a0)

        # # schedule the next timer interrupt
        # # by adding interval to mtimecmp.
        # ld a1, 24(a0) # CLINT_MTIMECMP(hart)
        # ld a2, 32(a0) # interval
        # ld a3, 0(a1)
        # add a3, a3, a2
        # sd a3, 0(a1)

        # # arrange for a supervisor software interrupt
        # # after this handler returns.
        # li a1, 2
        # csrw sip, a1

        # ld a3, 16(a0)
        # ld a2, 8(a0)
        # ld a1, 0(a0)
        # csrrw a0, mscratch, a0

        ertn
