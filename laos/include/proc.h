#include "latype.h"
#include "defs.h"
#include "spinlock.h"

#ifndef PROC_H__
#define PROC_H__

// Saved registers for kernel context switches.
struct context {
  u32 ra;
  u32 sp;

  // callee-saved
  u32 s0;
  u32 s1;
  u32 s2;
  u32 s3;
  u32 s4;
  u32 s5;
  u32 s6;
  u32 s7;
  u32 s8;
  u32 s9;
};

// Per-CPU state.
struct cpu {
  struct proc *proc;          // The process running on this cpu, or null.
  struct context context;     // swtch() here to enter scheduler().
  int noff;                   // Depth of push_off() nesting.
  int intena;                 // Were interrupts enabled before push_off()?
};

extern struct cpu cpus[NCPU];


// per-process data for the trap handling code in trampoline.S.
// sits in a page by itself just under the trampoline page in the
// user page table. not specially mapped in the kernel page table.
// uservec in trampoline.S saves user registers in the trapframe,
// then initializes registers from the trapframe's
// kernel_sp, kernel_hartid, kernel_satp, and jumps to kernel_trap.
// usertrapret() and userret in trampoline.S set up
// the trapframe's kernel_*, restore user registers from the
// trapframe, switch to the user page table, and enter user space.
// the trapframe includes callee-saved user registers like s0-s11 because the
// return-to-user path via usertrapret() doesn't return through
// the entire kernel call stack.
struct trapframe {
  /*   0 */ u32 kernel_satp;   // kernel page table
  /*   4 */ u32 kernel_sp;     // top of process's kernel stack
  /*   8 */ u32 kernel_trap;   // usertrap()
  /*  12 */ u32 eenrty;        // saved user program counter
  /*  16 */ u32 kernel_hartid; // saved kernel tp
  /*  20 */ u32 ra;
  /*  24 */ u32 tp;
  /*  28 */ u32 sp;
  /*  32 */ u32 a0;
  /*  36 */ u32 a1;
  /*  40 */ u32 a2;
  /*  44 */ u32 a3;
  /*  48 */ u32 a4;
  /*  52 */ u32 a5;
  /*  56 */ u32 a6;
  /*  60 */ u32 a7;
  /*  64 */ u32 t0;
  /*  68 */ u32 t1;
  /*  72 */ u32 t2;
  /*  76 */ u32 t3;
  /*  80 */ u32 t4;
  /*  84 */ u32 t5;
  /*  88 */ u32 t6;
  /*  92 */ u32 t7;
  /*  96 */ u32 t8;
  /* 100 */ u32 r21;
  /* 104 */ u32 s9;
  /* 108 */ u32 s0;
  /* 112 */ u32 s1;
  /* 116 */ u32 s2;
  /* 120 */ u32 s3;
  /* 124 */ u32 s4;
  /* 128 */ u32 s5;
  /* 132 */ u32 s6;
  /* 136 */ u32 s7;
  /* 140 */ u32 s8;
};

enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

// Per-process state
struct proc {
  struct spinlock lock;

  // p->lock must be held when using these:
  enum procstate state;        // Process state
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  int xstate;                  // Exit status to be returned to parent's wait
  int pid;                     // Process ID

  // wait_lock must be held when using this:
  struct proc *parent;         // Parent process

  // these are private to the process, so p->lock need not be held.
  u32 kstack;               // Virtual address of kernel stack
  u32 sz;                   // Size of process memory (bytes)
  pagetable_t pagetable;       // User page table
  struct trapframe *trapframe; // data page for trampoline.S
  struct context context;      // swtch() here to run process
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)
};

struct cpu *mycpu();

#endif