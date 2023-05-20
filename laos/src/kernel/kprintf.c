#include <stdarg.h>

#include "latype.h"
#include "console.h"
#include "kprintf.h"
#include "spinlock.h"

volatile int panicked = 0;

// lock to avoid interleaving concurrent printf's.
static struct {
  struct spinlock lock;
  int locking;
} pr;

static char digits[] = "0123456789abcdef";

static void print_int(int xx, int base, int sign) {
    char buf[32];
    int i;
    uint x;
    if (sign && (sign = xx < 0)) {
        x = -xx;
    } else {
        x = xx;
    }

    i = 0;
    do {
        buf[i++] = digits[x % base];
    } while ((x /= base) != 0);

    if(sign) {
        buf[i++] = '-';
    }

    while(--i >= 0)
        consputc(buf[i]);
}

static void print_ptr(intptr_t x) {
    consputc('0');
    consputc('x');
    for (int i = 0; i < (sizeof(intptr_t) * 2); i++, x <<= 4)
        consputc(digits[x >> (sizeof(intptr_t) * 8 - 4)]);
}

void kprintf(char *fmt, ...) {
    va_list ap;
    int i, c, locking;
    char *s;

    locking = pr.locking;
    if(locking)
        acquire(&pr.lock);

    if (fmt == 0)
        panic("null fmt");

    va_start(ap, fmt);
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++) {
        if (c != '%') {
            consputc(c);
            continue;
        }
        c = fmt[++i] & 0xff;
        if (c == 0) {
            break;
        }

        switch (c) {
        case 'd':
            print_int(va_arg(ap, int), 10, 1);
            break;
        case 'x':
            print_int(va_arg(ap, int), 16, 1);
            break;
        case 'p':
            print_ptr(va_arg(ap, intptr_t));
            break;
        case 's':
            if((s = va_arg(ap, char*)) == 0)
                s = "(null)";
            for(; *s; s++)
                consputc(*s);
            break;
        case '%':
            consputc('%');
            break;
        default:
            // Print unknown % sequence to draw attention.
            consputc('%');
            consputc(c);
            break;
        }
    }
    va_end(ap);

    if(locking)
        release(&pr.lock);
}

void panic(char *s) {
    pr.locking = 0;
    kprintf("panic: ");
    kprintf(s);
    kprintf("\n");
    panicked = 1; // freeze serial output from other CPUs
    for(;;)
        ;
}

void kprintf_init(void) {
  initlock(&pr.lock, "pr");
  pr.locking = 1;
}