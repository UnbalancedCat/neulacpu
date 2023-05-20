#include "latype.h"

#ifndef SPINLOCK_H__
#define SPINLOCK_H__

struct spinlock {
    uint locked;

    // debugging
    char *name;
    struct cpu *cpu;
};

void initlock(struct spinlock *lck, char *name);

void acquire(struct spinlock *lck);
void release(struct spinlock *lck);

int  holding(struct spinlock *lck);
void push_off();
void pop_off();

#endif