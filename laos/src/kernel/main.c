#include "la32r.h"
#include "spinlock.h"


volatile static int started = 0;

void main() {
    struct spinlock lck[1];
    initlock(lck, "main");
    acquire(lck);
    
    if (r_cpuid() == 0) {


        synchronize();
        started = 1;
    } else {
        // 当前假定只有一个 hart
        while (started == 0)
            ;
        synchronize();
    }


}