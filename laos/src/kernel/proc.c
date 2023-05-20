#include "proc.h"
#include "la32r.h"
#include "latype.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

struct cpu *mycpu() {
    int id = r_cpuid();
    struct cpu *c = &cpus[id];
    return c;
}