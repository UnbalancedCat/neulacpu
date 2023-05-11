#include <common.h>
#include <la32r.hh>

namespace {
using u64 = uint64_t;
using i64 = int64_t;

using u32 = uint32_t;
using i32 = int32_t;

SystemBus *sysbus;

enum regenum {
     R0,  R1,  R2,  R3,  R4,  R5,  R6,  R7,  R8,  R9,
    R10, R11, R12, R13, R14, R15, R16, R17, R18, R19,
    R20, R21, R22, R23, R24, R25, R26, R27, R28, R29,
    R30, R31, PC
};

enum PLV {
    PLV0, 
    // PLV1, 
    // PLV2, 
    PLV3, 
} PrivilegeLevel ;

class Registers {
private:
    u32 regs_[32] = {0};
    u32 pc_ = 0;

public:
    Registers() = default;

    u32 get(u32 idx) {
        panicifnot((0 <= idx && 32 >= idx) || idx == PC);
        if (idx == PC) {
            return pc_;
        }

        if (0 <= idx && 32 >= idx) {
            return regs_[idx];
        }

        panic("Unexpected register access");
    }

    void set(u32 idx, u32 data) {
        panicifnot((0 <= idx && 32 >= idx) || idx == PC);
        if (idx == PC) {
            pc_ = data;
        }

        if (0 <= idx && 32 >= idx) {
            regs_[idx] = data;
        }

        panic("Unexpected register access");

    }

    u32 &operator[](u32 idx) {
        if (idx == PC) {
            return pc_;
        }

        if (0 <= idx && 32 >= idx) {
            return regs_[idx];
        }

        panic("Unexpected register access");
    }
} Regs ;

constexpr u32 getbits(u32 hi, u32 lo, u32 data) {
    data = data >> lo;
    u32 mask = ((u64) 0x1 << (hi + 1)) - 1;
    return data & mask;
}

void decode_and_exec(u32 inst) {

    if (getbits(31, 15, inst) == 0b00000000000100000) {
        u32 rd = getbits( 4,  0, inst);
        u32 rj = getbits( 9,  5, inst);
        u32 rk = getbits(14, 10, inst);

        u32 tmp = Regs[rj] + Regs[rk];
        Regs[rd] = getbits(31, 0, tmp);
        return;
    }

    panic("Invalid operation or have not implemented yet.");
}

u32 fetch() {
    u32 inst;
    sysbus->read32(inst, Regs[PC]);
    return inst;
}

}


LA32R::LA32R(SystemBus *bus) {
    sysbus = bus;

    Regs[PC] = 0x0000'0000;
}

void LA32R::Step(unsigned in) {
    u32 inst = fetch();
    decode_and_exec(inst);
    Regs[PC] += 4;
}