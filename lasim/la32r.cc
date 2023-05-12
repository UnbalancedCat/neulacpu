#include <common.h>
#include <devaddr.h>
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

constexpr u32 gb(u32 hi, u32 lo, u32 data) {
    panicifnot(hi >= lo);

    data = data >> lo;
    u32 width = hi - lo + 1;
    u32 mask = (u32)(~0) >> (32 - width);
    return data & mask;
}

constexpr u32 sext(u32 data, u32 width) {
    u32 upper = 32 - width;
    u32 result = (i32)(data << upper) >> upper;
    return result;
}

bool check(const char *instfmt, u32 inst) {
    size_t len = strlen(instfmt);
    panicifnot(len >= 32);
    
    u32 hit = 0;

    // alert ! i should gt 0 not geq 0
    for (size_t i = len; i > 0; --i) {
        auto idx = i - 1;

        if (std::tolower(instfmt[idx]) == 'x') {
            inst >>= 1;
            hit += 1;
            continue;
        } else if (instfmt[idx] == '0' && (inst & 0x1) == 0x0) {
            inst >>= 1;
            hit += 1;
            continue;
        } else if (instfmt[idx] == '1' && (inst & 0x1) == 0x1) {
            inst >>= 1;
            hit += 1;
            continue;
        } else if (strchr("'., ", instfmt[idx])) {
            continue;
        }

        return false;
    }

    return hit == 32;
}

u32 SLL(u32 data, u32 sa) {
    if (sa == 0)
        return data;
    
    return data << sa;
}

u32 SRL(u32 data, u32 sa) {
    if (sa == 0)
        return data;
    
    return data >> sa;
}

u32 SRA(u32 data, u32 sa) {
    if (sa == 0)
        return data;
    
    return (i32)data >> sa;
}

#define BEGIN_CHECK() if (false) {}

#define INST(str, instname, extracond, ...)     \
else if (check((str), (inst)) && (extracond)) {  \
    curinst = #instname;                    \
    __VA_ARGS__;                            \
}


void decode_and_exec(u32 inst) {

    // These decode is fixed
    u32 rd = gb( 4,  0, inst);
    u32 rj = gb( 9,  5, inst);
    u32 cj = gb( 7,  5, inst);
    u32 rk = gb(14, 10, inst);


    u32 ui5 = rk;
    u32 ui12 = gb(21, 10, inst);
    u32 si12 = sext(ui12, 12);
    u32 si14 = sext(gb(23, 10, inst), 14);
    u32 si20 = sext(gb(24,  5, inst), 20);
    
    u32 csr =  gb(23, 10, inst);

    u32 offs_15_00 = gb(25, 10, inst);
    u32 offs_20_16 = gb( 4,  0, inst);
    u32 offs_25_16 = gb( 9,  0, inst);

    u32 code = rd << 0 | rj << 5 | rk << 10;
    u32 level = code;
    u32 hint  = code;

    u32 code5 = rd;
    u32 hint5 = code5;
    u32 op    = code5;

    const char *curinst = nullptr;

    BEGIN_CHECK()
    INST("00000000000000000'1100'0'xxxxx'00000", RDCNTID.W, gb(4, 0, inst) == 0)
    INST("00000000000000000'1100'0'00000'xxxxx", RDCNTVL.W, gb(9, 5, inst) == 0)
    INST("00000000000000000'1100'1'00000'xxxxx", RDCNTVH.W, gb(9, 5, inst) == 0)
    
    INST("00000000000'100000'xxxxx'xxxxx'xxxxx",     ADD.W, true, Regs[rd] = Regs[rj] + Regs[rk])
    INST("00000000000'100010'xxxxx'xxxxx'xxxxx",     SUB.W, true, Regs[rd] = Regs[rj] - Regs[rk])
    INST("00000000000'100100'xxxxx'xxxxx'xxxxx",       SLT, true, Regs[rd] = (i32)Regs[rj] < (i32)Regs[rk])
    INST("00000000000'100101'xxxxx'xxxxx'xxxxx",      SLTU, true, Regs[rd] =      Regs[rj] <      Regs[rk])
    INST("00000000000'101000'xxxxx'xxxxx'xxxxx",       NOR, true, Regs[rd] = ~(Regs[rj] | Regs[rk]))
    INST("00000000000'101001'xxxxx'xxxxx'xxxxx",       AND, true, Regs[rd] =   Regs[rj] & Regs[rk])
    INST("00000000000'101010'xxxxx'xxxxx'xxxxx",        OR, true, Regs[rd] =   Regs[rj] | Regs[rk])
    INST("00000000000'101011'xxxxx'xxxxx'xxxxx",       XOR, true, Regs[rd] =   Regs[rj] ^ Regs[rk])
    INST("00000000000'101110'xxxxx'xxxxx'xxxxx",     SLL.W, true, Regs[rd] = SLL(Regs[rj], gb(4, 0, Regs[rk])))
    INST("00000000000'101111'xxxxx'xxxxx'xxxxx",     SRL.W, true, Regs[rd] = SRL(Regs[rj], gb(4, 0, Regs[rk])))
    INST("00000000000'110000'xxxxx'xxxxx'xxxxx",     SRA.W, true, Regs[rd] = SRA(Regs[rj], gb(4, 0, Regs[rk])))
    INST("00000000000'111000'xxxxx'xxxxx'xxxxx",     MUL.W, true, Regs[rd] = Regs[rj] * Regs[rk])
    INST("00000000000'111001'xxxxx'xxxxx'xxxxx",    MULH.W, true, Regs[rd] = (u32)(((i64)(i32)Regs[rj] * (i64)(i32)Regs[rk]) >> 32))
    INST("00000000000'111010'xxxxx'xxxxx'xxxxx",   MULH.WU, true, Regs[rd] = (u32)(((u64)Regs[rj] * (u64)Regs[rk]) >> 32))
    INST("0000000000'1000000'xxxxx'xxxxx'xxxxx",     DIV.W, true, Regs[rd] = (i32)Regs[rj] / (i32)Regs[rk])
    INST("0000000000'1000001'xxxxx'xxxxx'xxxxx",     MOD.W, true, Regs[rd] = (i32)Regs[rj] % (i32)Regs[rk])
    INST("0000000000'1000010'xxxxx'xxxxx'xxxxx",    DIV.WU, true, Regs[rd] = Regs[rj] / Regs[rk])
    INST("0000000000'1000011'xxxxx'xxxxx'xxxxx",    MOD.WU, true, Regs[rd] = Regs[rj] % Regs[rk])
    
    INST("0000000000'1010100'xxxxx xxxxx xxxxx",     BREAK, true, )
    INST("0000000000'1010110'xxxxx xxxxx xxxxx",   SYSCALL, true, )

    INST("000000000'10000'000'xxxxx'xxxxx'xxxxx",   SLLI.W, true, Regs[rd] = SLL(Regs[rj], ui5))
    INST("000000000'10000'001'xxxxx'xxxxx'xxxxx",   SRLI.W, true, Regs[rd] = SRL(Regs[rj], ui5))
    INST("000000000'10000'010'xxxxx'xxxxx'xxxxx",   SRAI.W, true, Regs[rd] = SRA(Regs[rj], ui5))

    INST("000000'1000'xxxxxxx xxxxx'xxxxx'xxxxx",     SLTI, true, Regs[rd] = (i32)Regs[rj] < (i32)si12)
    INST("000000'1001'xxxxxxx xxxxx'xxxxx'xxxxx",    SLTUI, true, Regs[rd] =      Regs[rj] <      si12)
    INST("000000'1010'xxxxxxx xxxxx'xxxxx'xxxxx",   ADDI.W, true, Regs[rd] = Regs[rj] + si12)
    INST("000000'1101'xxxxxxx xxxxx'xxxxx'xxxxx",     ANDI, true, Regs[rd] = Regs[rj] & ui12)
    INST("000000'1110'xxxxxxx xxxxx'xxxxx'xxxxx",      ORI, true, Regs[rd] = Regs[rj] | ui12)
    INST("000000'1111'xxxxxxx xxxxx'xxxxx'xxxxx",     XORI, true, Regs[rd] = Regs[rj] ^ ui12)

    INST("00000'100'xxxxxxxxxxxxxx'00000'xxxxx",     CSRRD, gb(9, 5, inst) == 0, )
    INST("00000'100'xxxxxxxxxxxxxx'00001'xxxxx",     CSRWR, gb(9, 5, inst) == 1, )
    INST("00000'100'xxxxxxxxxxxxxx'xxxxx'xxxxx",   CSRXCHG, gb(9, 5, inst) >  1, )

    INST("00000'11000'xxxxxxxxxxxx'xxxxx'xxxxx",     CACOP, true, )

    INST("00000'1100'1001000001'010'00000'00000",  TLBSRCH, true, )
    INST("00000'1100'1001000001'011'00000'00000",    TLBRD, true, )
    INST("00000'1100'1001000001'100'00000'00000",    TLBWR, true, )
    INST("00000'1100'1001000001'101'00000'00000",  TLBFILL, true, )
    INST("00000'1100'1001000001'110'00000'00000",     ERTN, true, )

    INST("00000'1100'1001'0001'xxxxx xxxxx xxxxx",    IDLE, true, )
    INST("00000'1100'1001'0011'xxxxx'xxxxx'xxxxx",  INVTLB, true, )

    INST("000'1010'xxxxxxxxxxxxxxxxxxxx'xxxxx",    LU12I.W, true, )
    INST("000'1110'xxxxxxxxxxxxxxxxxxxx'xxxxx",  PCADDU12I, true, )
    
    INST("00'100000'xxxxxxxxxxxxxx'xxxxx'xxxxx",      LL.W, true, )
    INST("00'100001'xxxxxxxxxxxxxx'xxxxx'xxxxx",      SC.W, true, )
    
    INST("00'10100000'xxxxxxxxxxxx'xxxxx'xxxxx",      LD.B, true, )
    INST("00'10100001'xxxxxxxxxxxx'xxxxx'xxxxx",      LD.H, true, )
    INST("00'10100010'xxxxxxxxxxxx'xxxxx'xxxxx",      LD.W, true, )
    INST("00'10100100'xxxxxxxxxxxx'xxxxx'xxxxx",      ST.B, true, )
    INST("00'10100101'xxxxxxxxxxxx'xxxxx'xxxxx",      ST.H, true, )
    INST("00'10100110'xxxxxxxxxxxx'xxxxx'xxxxx",      ST.W, true, )
    INST("00'10101000'xxxxxxxxxxxx'xxxxx'xxxxx",     LD.BU, true, )
    INST("00'10101001'xxxxxxxxxxxx'xxxxx'xxxxx",     LD.HU, true, )
    INST("00'10101011'xxxxxxxxxxxx'xxxxx'xxxxx",     PRELD, true, )

    INST("00'111000011100100'xxxxx xxxxx xxxxx",      DBAR, true, )
    INST("00'111000011100101'xxxxx xxxxx xxxxx",      IBAR, true, )

    INST("0'10010'xxxxxxxxxxxxxxxx'00xxx'xxxxx",     BCEQZ, gb(9, 8, inst) == 0, )
    INST("0'10010'xxxxxxxxxxxxxxxx'01xxx'xxxxx",     BCNEZ, gb(9, 8, inst) == 1, )
    INST("0'10011'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",      JIRL, true, )
    INST("0'10100'xxxxxxxxxxxxxxxx'xxxxx xxxxx",         B, true, )
    INST("0'10101'xxxxxxxxxxxxxxxx'xxxxx xxxxx",        BL, true, )
    INST("0'10110'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",       BEQ, true, )
    INST("0'10111'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",       BNE, true, )
    INST("0'11000'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",       BLT, true, )
    INST("0'11001'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",       BGE, true, )
    INST("0'11010'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",      BLTU, true, )
    INST("0'11011'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",      BGEU, true, )

    printf("%08x: %s\n", inst, curinst);
}

u32 fetch() {
    u32 inst;
    sysbus->read32(inst, Regs[PC]);
    return inst;
}

}

LA32R::LA32R(SystemBus *bus) {
    sysbus = bus;

    Regs[PC] = IMG_ADDR;
}

void LA32R::Step(unsigned in) {
    u32 inst = fetch();
    decode_and_exec(inst);
    Regs[PC] += 4;
}