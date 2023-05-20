#include "memlayout.h"
#include "latype.h"
#include "memio.h"
#include "defs.h"

struct spinlock serial_tx_lock;
char serial_tx_buf[SERIAL_TX_BUF_SIZE];

u32 serial_tx_w; // write next to serial_tx_buf[serial_tx_w % SERIAL_TX_BUF_SIZE]
u32 serial_tx_r; // read next from serial_tx_buf[serial_tx_r % SERIAL_TX_BUF_SIZE]



void serial_putc(int c) {
    acquire(&serial_tx_lock);

    // if(panicked){
    //     for(;;)
    //         ;
    // }

    while(serial_tx_w == serial_tx_r + SERIAL_TX_BUF_SIZE){
        // buffer is full.
        // wait for serialstart() to open up space in the buffer.
        // sleep(&serial_tx_r, &serial_tx_lock);
    }
    serial_tx_buf[serial_tx_w % SERIAL_TX_BUF_SIZE] = c;
    serial_tx_w += 1;
    // serialstart();
    release(&serial_tx_lock);
}