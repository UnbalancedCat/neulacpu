#include "spinlock.h"
#include "la32r.h"
#include "defs.h"
#include "kprintf.h"
#include "proc.h"

void initlock(struct spinlock *lck, char *name) {
    lck->name = name;
    lck->locked = 0;
    lck->cpu = 0;
}

void acquire(struct spinlock *lck) {

    if(holding(lck)) {
        panic("acquire");
    }


    do {
        // 如果已经上锁了，就等待
        while (llw((intptr_t)&lck->locked) == 1)
            ;
    // 此时没有上锁，那就开始抢锁
    // 没有抢成功就进入新的循环
    } while (scw(1, (intptr_t)&lck->locked) != 1);

    synchronize();
    lck->cpu = mycpu();
}

void release(struct spinlock *lck) {
    if (holding(lck) != 1) {
        panic("release");
    }

    lck->cpu = NULL;

    synchronize();

    do {
        // 标记上
        llw((intptr_t)&lck->locked);

    // 此时没有 hart 动，那就安全的释放
    // 否则重新循环
    } while (scw(0, (intptr_t)&lck->locked) != 1);
}

int holding(struct spinlock *lck) {
  int r;
  r = (lck->locked && lck->cpu == mycpu());
  return r;
}