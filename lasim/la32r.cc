#include <unordered_map>

#include <common.h>
#include <devaddr.h>
#include <la32r.hh>

namespace {

//
// ----- ----- new type defines ----- -----
//

using u64 = uint64_t;
using i64 = int64_t;

using u32 = uint32_t;
using i32 = int32_t;

//
// ----- ----- enum defines ----- -----
//

enum regenum {
     R0,  R1,  R2,  R3,  R4,  R5,  R6,  R7,  R8,  R9,
    R10, R11, R12, R13, R14, R15, R16, R17, R18, R19,
    R20, R21, R22, R23, R24, R25, R26, R27, R28, R29,
    R30, R31, PC
};

enum CSRADDR {
    CRMD        = 0x000, /* 当前模式信息 */
    PRMD        = 0x001, /* 例外前模式信息 */
    EUEN        = 0x002, /* 拓展部件使能 */
    ECFG        = 0x004, /* 例外配置 */
    ESTAT       = 0x005, /* 例外状态 */
    ERA         = 0x006, /* 例外返回地址 */
    BADV        = 0x007, /* 出错虚地址 */
    EENTRY      = 0x00c, /* 例外地址入口 */
    TLBIDX      = 0x010, /* TLB 索引 */
    TLBEHI      = 0x011, /* TLB 表项高位 */
    TLBELO0     = 0x012, /* TLB 表项低位 0 */
    TLBELO1     = 0x013, /* TLB 表项低位 1 */
    ASID        = 0x018, /* 地址空间标识符 */
    PGDL        = 0x019, /* 低半地址空间全局目录基址 */
    PGDH        = 0x01a, /* 高半地址空间全局目录基址 */
    PGD         = 0x01b, /* 全局目录基址 */
    CPUID       = 0x020, /* 处理器编号 */
    SAVE0       = 0x030, /* 数据保存 0*/
    SAVE1       = 0x031, /* 数据保存 1*/
    SAVE2       = 0x032, /* 数据保存 2 */
    SAVE3       = 0x033, /* 数据保存 3 */
    TID         = 0x040, /* 定时器编号 */
    TCFG        = 0x041, /* 定时器配置 */
    TVAL        = 0x042, /* 定时器值 */
    TICLR       = 0x044, /* 定时中断清除 */
    LLBCTL      = 0x060, /* LLBit 控制 */
    TLBRENTRY   = 0x088, /* TLB 重填例外入口 */
    CTAG        = 0x098, /* 高速缓存标签 */
    DMW0        = 0x180, /* 直接映射配置窗口 0 */
    DMW1        = 0x181, /* 直接映射配置窗口 1 */
};

enum CSRRDATTR {
    CSR_RW, /* 软件可读写 */
    CSR_R,  /* 软件只读 */
    CSR_R0, /* 软件只 `读 0` */
    CSR_W1, /* 软件读无意义，只 `写 1` */
};

enum PLV {
    PLV0 = 0,
    // PLV1,
    // PLV2,
    PLV3 = 3,
};

enum SCOP {
    SC_RDHI,
    SC_RDLO,
    SC_RDID,
};

enum TLBOP {
    TLB_SRCH,
    TLB_RD,
    TLB_WR,
    TLB_FILL,
};

enum DATAKIND {
    BYTE,
    HWORD,
    WORD,
    DWORD,
};

//
// ----- ----- customize constant defines ----- -----
//

constexpr u32 RSTVEC    = 0x1c00'0000;
constexpr u32 IDXLEN    = 16;
constexpr u32 PALEN     = 36;
constexpr u32 TVALLEN   = 31;

static_assert(IDXLEN <= 16);               // TLB idx 宽度
static_assert(36 >= PALEN && 13 <= PALEN); // 页表物理页号长度
static_assert(TVALLEN <= 32);              // 计时器计数宽度

const char *regnames[] = {
    [R0] = "zero",
    [R1] = "ra",
    [R2] = "tp",
    [R3] = "sp",
    [R4] = "a0", [R5] = "a1",
    [R6] = "a2", [R7] = "a3", [R8] = "a4", [R9] = "a5", [R10] = "a6", [R11] = "a7",
    [R12] = "t0", [R13] = "t1", [R14] = "t2", [R15] = "t3", [R16] = "t4", [R17] = "t5", [R18] = "t6", [R19] = "t7", [R20] = "t8",
    [R21] = "r21",
    [R22] = "fp/s9",
    [R23] = "s0", [R24] = "s1", [R25] = "s2", [R26] = "s3", [R27] = "s4", [R28] = "s5", [R29] = "s6", [R30] = "s7", [R31] = "s8",
};

//
// ----- ----- struct defines ----- -----
//

struct CSRBaseInfo {
    u32 data    = 0x0;
    u32 wmask   = 0xffff'ffff;
    u32 w1mask  = 0x0;
};

//
// ----- ----- class defines ----- -----
//

class Registers {
private:
    u32 regs_[31] = {0};
    u32 pc_ = 0;
    u32 _;

public:
    Registers() = default;

    void operator >> (u32 addr) {
        pc_ = addr;
    }

    const u32 &operator()(u32 idx) {
        panicifnot((0 <= idx && 32 >= idx) || idx == PC);
        if (idx == 0) {
            return 0;
        }

        if (idx == PC) {
            return pc_;
        }

        if (1 <= idx && 32 >= idx) {
            return regs_[idx - 1];
        }

        panic("Unexpected register access");
    }

    u32 &operator[](u32 idx) {
        panicifnot(0 <= idx && 32 >= idx);
        if (idx == 0) {
            return _;
        }

        if (1 <= idx && 32 >= idx) {
            return regs_[idx - 1];
        }

        panic("Unexpected register access");
    }
};

//
// ----- ----- static values ----- -----
//

PLV PrivilegeLevel;

Registers Regs;

std::unordered_map<u32, CSRBaseInfo> CSRs;

u64 stblcnt[4] = {0};

SystemBus *sysbus;

//
// ----- ----- binary operations ----- -----
//

constexpr u32 gb(u32 hi, u32 lo, u32 data) {
    panicifnot(hi >= lo);

    data = data >> lo;
    u32 width = hi - lo + 1;
    u32 mask = (u32)(~0) >> (32 - width);
    return data & mask;
}

constexpr u32 msk(u32 hi, u32 lo) {
    panicifnot(hi >= lo);

    u32 width = hi - lo + 1;
    u32 mask = (u32)(~0) >> (32 - width);
    return mask << lo;
}

constexpr u32 msk(u32 pos) {
    return 0x1 << pos;
}

constexpr u32 sext(u32 data, u32 width) {
    u32 upper = 32 - width;
    u32 result = (i32)(data << upper) >> upper;
    return result;
}

constexpr u32 sll(u32 data, u32 sa) {
    if (sa == 0)
        return data;
    
    return data << sa;
}

constexpr u32 srl(u32 data, u32 sa) {
    if (sa == 0)
        return data;
    
    return data >> sa;
}

constexpr u32 sra(u32 data, u32 sa) {
    if (sa == 0)
        return data;
    
    return (i32)data >> sa;
}

constexpr u32 sb(u32 hi, u32 lo, u32 &data, u32 wdata) {
    auto &&mask = msk(hi, lo);
    auto &&rem = data & ~mask;
    auto &&wr  = (wdata << lo) & mask;
    data = rem | wdata;
    return data;
}

constexpr u32 sb(u32 pos, u32 &data, u32 wdata) {
    auto &&mask = msk(pos);
    auto &&rem = data & ~mask;
    auto &&wr  = (wdata << pos) & mask;
    data = rem | wdata;
    return data;
}

constexpr u32 rounddown(u32 data, u32 agn = 2) {
    return (data >> agn) << agn;
}

constexpr u32 roundfup(u32 data, u32 agn = 2) {
    auto &&upper = gb(31, agn, data);
    return (upper + 1) << agn;
}

constexpr u32 roundup(u32 data, u32 agn = 2) {
    auto &&upper = gb(31, agn, data);
    auto &&lower = agn ? gb(agn - 1, 0, data) : 0;
    return lower ? (upper + 1) << agn : upper << agn; 
}


//
// ----- ----- unit test ----- -----
//

static_assert(gb(15,  0, 0xdead'beef) == 0x0000'beef);
static_assert(gb(31, 16, 0xdead'beef) == 0x0000'dead);

static_assert(msk( 0,  0) == 0x0000'0001);
static_assert(msk(31,  0) == 0xffff'ffff);
static_assert(msk( 3,  0) == 0x0000'000f);
static_assert(msk(23, 12) == 0x00ff'f000);
static_assert(msk(31, 31) == 0x8000'0000);

static_assert(msk( 0) == 0x0000'0001);
static_assert(msk( 1) == 0x0000'0002);
static_assert(msk( 2) == 0x0000'0004);
static_assert(msk(30) == 0x4000'0000);
static_assert(msk(31) == 0x8000'0000);

static_assert(sext(0x0000'0001,  1) == 0xffff'ffff);
static_assert(sext(0x0000'0fff, 16) == 0x0000'0fff);
static_assert(sext(0x0000'dead, 16) == 0xffff'dead);
static_assert(sext(0x000f'dead, 20) == 0xffff'dead);

static_assert(sll(0x1,  0) == 0x1);
static_assert(sll(0x1,  1) == 0x2);
static_assert(sll(0x1, 31) == 0x8000'0000);

static_assert(srl(0x8000'0000,  0) == 0x8000'0000);
static_assert(srl(0x8000'0000,  1) == 0x4000'0000);
static_assert(srl(0x8000'0000, 31) == 0x1);

static_assert(srl(0x8000'0000,  0) == 0x8000'0000);
static_assert(sra(0x8000'0000,  1) == 0xc000'0000);
static_assert(sra(0x8000'0000, 31) == 0xffff'ffff);

//
// ----- ----- CSR Control ----- -----
//

#define CRMD_PLV     1, 0
#define CRMD_IE      2
#define CRMD_DA      3
#define CRMD_PG      4
#define CRMD_DATF    6, 5
#define CRMD_DATM    8, 7

#define EUEN_FPE     0

#define ECFG_LIE_09_00       9, 0
#define ECFG_LIE_12_11      12,11

#define ESTAT_IS_01_00       1, 0
// #define ESTAT_IS_09_02       9, 2
// #define ESTAT_IS_11         11
// #define ESTAT_IS_12         12
// #define ESTAT_Ecode         21,16
// #define ESTAT_EsubCode      30,22

#define TCFG_En         0
#define TCFG_Periodic   1
#define TCFG_InitVal    (TVALLEN - 1),2

#define LLBCTL_WCLLB    1
#define LLBCTL_KLO      2

#define DMW_PLV0        0
#define DMW_PLV3        3
#define DMW_MAT         5, 4
#define DMW_PSEG       27,25
#define DMW_VSEG       31,29



//
// ----- ----- control logic functions ----- -----
//

void init_csr() {
    CSRs.emplace(CRMD        , CSRBaseInfo{
        .wmask = msk(8, 7) | msk(6, 5) | msk(4) | msk(3) | msk(2) | msk(1, 0),
    });
    CSRs.emplace(PRMD        , CSRBaseInfo{
        .wmask = msk(2) | msk(1, 0),
    });
    CSRs.emplace(EUEN        , CSRBaseInfo{
        .wmask = msk(0),
    });
    CSRs.emplace(ECFG        , CSRBaseInfo{
        .wmask = msk(12, 11) | msk(9, 0),
    });
    CSRs.emplace(ESTAT       , CSRBaseInfo{
        .wmask = msk(1, 0),
    });
    CSRs.emplace(ERA         , CSRBaseInfo{
        .wmask = msk(31, 0),
    });
    CSRs.emplace(BADV        , CSRBaseInfo{
        .wmask = msk(31, 0),
    });
    CSRs.emplace(EENTRY      , CSRBaseInfo{
        .wmask = msk(31, 6),
    });
    CSRs.emplace(TLBIDX      , CSRBaseInfo{
        .wmask = msk(31) | msk(29, 24) | msk(IDXLEN - 1, 0),
    });
    CSRs.emplace(TLBEHI      , CSRBaseInfo{
        .wmask = msk(31, 13),
    });
    CSRs.emplace(TLBELO0     , CSRBaseInfo{
        .wmask = msk(31, 13),
    });
    CSRs.emplace(TLBELO1     , CSRBaseInfo{
        .wmask = msk(PALEN - 5, 8) | msk(6) | msk(5, 4) | msk(3, 2) | msk(1) | msk(0),
    });
    CSRs.emplace(ASID        , CSRBaseInfo{
        .wmask = msk(9, 0),
    });
    CSRs.emplace(PGDL        , CSRBaseInfo{
        .wmask = msk(31, 12),
    });
    CSRs.emplace(PGDH        , CSRBaseInfo{
        .wmask = msk(31, 12),
    });
    CSRs.emplace(PGD         , CSRBaseInfo{
        .wmask = 0,
    });
    CSRs.emplace(CPUID       , CSRBaseInfo{
        .wmask = 0,
    });
    CSRs.emplace(SAVE0       , CSRBaseInfo{
        .wmask = msk(31, 0),
    });
    CSRs.emplace(SAVE1       , CSRBaseInfo{
        .wmask = msk(31, 0),
    });
    CSRs.emplace(SAVE2       , CSRBaseInfo{
        .wmask = msk(31, 0),
    });
    CSRs.emplace(SAVE3       , CSRBaseInfo{
        .wmask = msk(31, 0),
    });
    CSRs.emplace(TID         , CSRBaseInfo{
        .wmask = msk(31, 0),
    });
    CSRs.emplace(TCFG        , CSRBaseInfo{
        .wmask = msk(TVALLEN - 1, 2) | msk(1) | msk(0),
    });
    CSRs.emplace(TVAL        , CSRBaseInfo{
        .wmask = 0,
    });
    CSRs.emplace(TICLR       , CSRBaseInfo{
        .w1mask = msk(0),
    });
    CSRs.emplace(LLBCTL      , CSRBaseInfo{
        .wmask = msk(2),
        .w1mask = msk(1),
    });
    CSRs.emplace(TLBRENTRY   , CSRBaseInfo{
        .wmask = msk(31, 6),
    });
    CSRs.emplace(CTAG        , CSRBaseInfo{
        .wmask = 0,
    });
    CSRs.emplace(DMW0        , CSRBaseInfo{
        .wmask = msk(31, 29) | msk(27, 25) | msk(5, 4) | msk(3) | msk(0),
    });
    CSRs.emplace(DMW1        , CSRBaseInfo{
        .wmask = msk(31, 29) | msk(27, 25) | msk(5, 4) | msk(3) | msk(0),
    });
}

/**
 * @brief 始终返回旧值
*/
u32 csr_wr(bool wen, u32 data, u32 addr) {
    auto &&csr = CSRs.at(addr);
    auto old = csr.data;
    if (wen) {
        auto &&wdata = data & (csr.wmask & ~csr.w1mask);
        auto &&must1 = data &               csr.w1mask ;
        csr.data = wdata | must1;
    }
    return old;
}

u32 stable_counter(bool rhi) {
    auto &&tid = csr_wr(false, 0x0, TID);
    return rhi ? stblcnt[tid] >> 32 : stblcnt[tid];
}

void exception_enter(u32 code) {
    panic("Not implemented yet");
}

void exception_return() {
    panic("Not implemented yet");
}

void exception_break(u32 code) {
    panic("Not implemented yet");
}

void exception_syscall(u32 code) {
    panic("Not implemented yet");
}

void cache_ctrl(u32 code, u32 addr) {
    panic("Not implemented yet");
}

void tlb_ctrl(TLBOP opcode) {
    panic("Not implemented yet");
}

void invtbl(u32 op, u32 asid, u32 vaddr) {
    panic("Not implemented yet");
}

void idle_wait() {
    panic("Not implemented yet");
}

u32 ll(u32 addr) {
    panic("Not implemented yet");
}

u32 sc(u32 addr) {
    panic("Not implemented yet");
}

u32 cache_visit(DATAKIND datakind, bool wen, u32 wdata, u32 addr) {
    
    if (wen) {

    }
    panic("Not implemented yet");
}
 
u32 cache_prefetch(u32 hint, u32 addr) {
    panic("Not implemented yet");
}

void inst_barrier(u32 hint) {}

void data_barrier(u32 hint) {}

//
// ----- ----- decode and execute ----- -----
//

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

#define BEGIN_CHECK() if (false) {}

#define INST(str, instname, extracond, ...)         \
else if (check((str), (inst)) && (extracond)) {     \
    curinst = #instname;                            \
    __VA_ARGS__;                                    \
}


u32 decode_and_exec(u32 inst, u32 curpc) {

    u32 nxtpc = curpc + 4;
    
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
    
    u32 csraddr =  gb(23, 10, inst);

    u32 offs_15_00 = gb(25, 10, inst);
    u32 offs_20_16 = gb( 4,  0, inst);
    u32 offs_25_16 = gb( 9,  0, inst);

    u32 offs16 = offs_15_00;
    u32 offs21 = offs_20_16 << 16 | offs_15_00;
    u32 offs26 = offs_25_16 << 16 | offs_15_00;

    u32 code = rk << 10 | rj << 5 | rd << 0;
    u32 level = code;
    u32 hint  = code;

    u32 code5 = rd;
    u32 hint5 = code5;
    u32 op    = code5;

    const char *curinst = nullptr;

    BEGIN_CHECK()
    INST("00000000000000000'1100'0'xxxxx'00000", RDCNTID.W, gb(4, 0, inst) == 0, Regs[rj] = csr_wr(false, 0x0, TID))
    INST("00000000000000000'1100'0'00000'xxxxx", RDCNTVL.W, gb(9, 5, inst) == 0, Regs[rd] = stable_counter(false))
    INST("00000000000000000'1100'1'00000'xxxxx", RDCNTVH.W, gb(9, 5, inst) == 0, Regs[rd] = stable_counter(true ))
    
    INST("00000000000'100000'xxxxx'xxxxx'xxxxx",     ADD.W, true, Regs[rd] = Regs(rj) + Regs(rk))
    INST("00000000000'100010'xxxxx'xxxxx'xxxxx",     SUB.W, true, Regs[rd] = Regs(rj) - Regs(rk))
    INST("00000000000'100100'xxxxx'xxxxx'xxxxx",       SLT, true, Regs[rd] = (i32)Regs(rj) < (i32)Regs(rk))
    INST("00000000000'100101'xxxxx'xxxxx'xxxxx",      SLTU, true, Regs[rd] =      Regs(rj) <      Regs(rk))
    INST("00000000000'101000'xxxxx'xxxxx'xxxxx",       NOR, true, Regs[rd] = ~(Regs(rj) | Regs(rk)))
    INST("00000000000'101001'xxxxx'xxxxx'xxxxx",       AND, true, Regs[rd] =   Regs(rj) & Regs(rk))
    INST("00000000000'101010'xxxxx'xxxxx'xxxxx",        OR, true, Regs[rd] =   Regs(rj) | Regs(rk))
    INST("00000000000'101011'xxxxx'xxxxx'xxxxx",       XOR, true, Regs[rd] =   Regs(rj) ^ Regs(rk))
    INST("00000000000'101110'xxxxx'xxxxx'xxxxx",     sll.W, true, Regs[rd] = sll(Regs(rj), gb(4, 0, Regs(rk))))
    INST("00000000000'101111'xxxxx'xxxxx'xxxxx",     srl.W, true, Regs[rd] = srl(Regs(rj), gb(4, 0, Regs(rk))))
    INST("00000000000'110000'xxxxx'xxxxx'xxxxx",     sra.W, true, Regs[rd] = sra(Regs(rj), gb(4, 0, Regs(rk))))
    INST("00000000000'111000'xxxxx'xxxxx'xxxxx",     MUL.W, true, Regs[rd] = Regs(rj) * Regs(rk))
    INST("00000000000'111001'xxxxx'xxxxx'xxxxx",    MULH.W, true, Regs[rd] = (u32)(((i64)(i32)Regs(rj) * (i64)(i32)Regs(rk)) >> 32))
    INST("00000000000'111010'xxxxx'xxxxx'xxxxx",   MULH.WU, true, Regs[rd] = (u32)(((u64)Regs(rj) * (u64)Regs(rk)) >> 32))
    INST("0000000000'1000000'xxxxx'xxxxx'xxxxx",     DIV.W, true, Regs[rd] = (i32)Regs(rj) / (i32)Regs(rk))
    INST("0000000000'1000001'xxxxx'xxxxx'xxxxx",     MOD.W, true, Regs[rd] = (i32)Regs(rj) % (i32)Regs(rk))
    INST("0000000000'1000010'xxxxx'xxxxx'xxxxx",    DIV.WU, true, Regs[rd] = Regs(rj) / Regs(rk))
    INST("0000000000'1000011'xxxxx'xxxxx'xxxxx",    MOD.WU, true, Regs[rd] = Regs(rj) % Regs(rk))
    
    INST("0000000000'1010100'xxxxx xxxxx xxxxx",     BREAK, true, exception_break  (code))
    INST("0000000000'1010110'xxxxx xxxxx xxxxx",   SYSCALL, true, exception_syscall(code))

    INST("000000000'10000'000'xxxxx'xxxxx'xxxxx",   SLLI.W, true, Regs[rd] = sll(Regs(rj), ui5))
    INST("000000000'10000'001'xxxxx'xxxxx'xxxxx",   SRLI.W, true, Regs[rd] = srl(Regs(rj), ui5))
    INST("000000000'10000'010'xxxxx'xxxxx'xxxxx",   SRAI.W, true, Regs[rd] = sra(Regs(rj), ui5))

    INST("000000'1000'xxxxxxx xxxxx'xxxxx'xxxxx",     SLTI, true, Regs[rd] = (i32)Regs(rj) < (i32)si12)
    INST("000000'1001'xxxxxxx xxxxx'xxxxx'xxxxx",    SLTUI, true, Regs[rd] =      Regs(rj) <      si12)
    INST("000000'1010'xxxxxxx xxxxx'xxxxx'xxxxx",   ADDI.W, true, Regs[rd] = Regs(rj) + si12)
    INST("000000'1101'xxxxxxx xxxxx'xxxxx'xxxxx",     ANDI, true, Regs[rd] = Regs(rj) & ui12)
    INST("000000'1110'xxxxxxx xxxxx'xxxxx'xxxxx",      ORI, true, Regs[rd] = Regs(rj) | ui12)
    INST("000000'1111'xxxxxxx xxxxx'xxxxx'xxxxx",     XORI, true, Regs[rd] = Regs(rj) ^ ui12)

    INST("00000'100'xxxxxxxxxxxxxx'00000'xxxxx",     CSRRD, gb(9, 5, inst) == 0, Regs[rd] = csr_wr(false, 0x0, csraddr))
    INST("00000'100'xxxxxxxxxxxxxx'00001'xxxxx",     CSRWR, gb(9, 5, inst) == 1, Regs[rd] = csr_wr(true, Regs(rd), csraddr))
    INST("00000'100'xxxxxxxxxxxxxx'xxxxx'xxxxx",   CSRXCHG, gb(9, 5, inst) >  1, Regs[rd] = csr_wr(true, Regs(rd) & Regs(rj), csraddr))

    INST("00000'11000'xxxxxxxxxxxx'xxxxx'xxxxx",     CACOP, true, cache_ctrl(code5, si12 + Regs[rj]))

    INST("00000'1100'1001000001'010'00000'00000",  TLBSRCH, true, tlb_ctrl(TLB_SRCH))
    INST("00000'1100'1001000001'011'00000'00000",    TLBRD, true, tlb_ctrl(TLB_RD  ))
    INST("00000'1100'1001000001'100'00000'00000",    TLBWR, true, tlb_ctrl(TLB_WR  ))
    INST("00000'1100'1001000001'101'00000'00000",  TLBFILL, true, tlb_ctrl(TLB_FILL))
    INST("00000'1100'1001000001'110'00000'00000",     ERTN, true, exception_return())

    INST("00000'1100'1001'0001'xxxxx xxxxx xxxxx",    IDLE, true, idle_wait())
    INST("00000'1100'1001'0011'xxxxx'xxxxx'xxxxx",  INVTLB, true, invtbl(op, Regs(rj), Regs(rk)))

    INST("000'1010'xxxxxxxxxxxxxxxxxxxx'xxxxx",    LU12I.W, true, Regs[rd] = si20 << 12)
    INST("000'1110'xxxxxxxxxxxxxxxxxxxx'xxxxx",  PCADDU12I, true, Regs[rd] = si20 << 12 + curpc)
    
    INST("00'100000'xxxxxxxxxxxxxx'xxxxx'xxxxx",      LL.W, true, Regs[rd] = ll((si14 << 2) + Regs[rj]))
    INST("00'100001'xxxxxxxxxxxxxx'xxxxx'xxxxx",      SC.W, true, Regs[rd] = sc((si14 << 2) + Regs[rj]))
    
    INST("00'10100000'xxxxxxxxxxxx'xxxxx'xxxxx",      LD.B, true, Regs[rd] = sext(cache_visit(BYTE, false, 0x0, si12 + Regs[rj]),  8))
    INST("00'10100001'xxxxxxxxxxxx'xxxxx'xxxxx",      LD.H, true, Regs[rd] = sext(cache_visit(BYTE, false, 0x0, si12 + Regs[rj]), 16))
    INST("00'10100010'xxxxxxxxxxxx'xxxxx'xxxxx",      LD.W, true, Regs[rd] =      cache_visit(BYTE, false, 0x0, si12 + Regs[rj])     )
    INST("00'10100100'xxxxxxxxxxxx'xxxxx'xxxxx",      ST.B, true, cache_visit(BYTE, true, Regs[rd], si12 + Regs[rj]))
    INST("00'10100101'xxxxxxxxxxxx'xxxxx'xxxxx",      ST.H, true, cache_visit(BYTE, true, Regs[rd], si12 + Regs[rj]))
    INST("00'10100110'xxxxxxxxxxxx'xxxxx'xxxxx",      ST.W, true, cache_visit(BYTE, true, Regs[rd], si12 + Regs[rj]))
    INST("00'10101000'xxxxxxxxxxxx'xxxxx'xxxxx",     LD.BU, true, Regs[rd] = cache_visit(BYTE, false, 0x0, si12 + Regs[rj]))
    INST("00'10101001'xxxxxxxxxxxx'xxxxx'xxxxx",     LD.HU, true, Regs[rd] = cache_visit(BYTE, false, 0x0, si12 + Regs[rj]))
    INST("00'10101011'xxxxxxxxxxxx'xxxxx'xxxxx",     PRELD, true, cache_prefetch(hint5, si12 + Regs[rj]))

    INST("00'111000011100100'xxxxx xxxxx xxxxx",      DBAR, true, data_barrier(hint))
    INST("00'111000011100101'xxxxx xxxxx xxxxx",      IBAR, true, inst_barrier(hint))

    INST("0'10011'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",      JIRL, true, Regs[rd] = curpc + 4; nxtpc = Regs[rj] + sext(offs16 << 2, 18))
    INST("0'10100'xxxxxxxxxxxxxxxx'xxxxx xxxxx",         B, true, nxtpc = curpc + sext(offs26 << 2, 28))
    INST("0'10101'xxxxxxxxxxxxxxxx'xxxxx xxxxx",        BL, true, Regs[R1] = curpc + 4; nxtpc = curpc + sext(offs26 << 2, 28))
    INST("0'10110'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",       BEQ, true, nxtpc =      Regs(rj) ==      Regs(rd) ? curpc + sext(offs16 << 2, 18) : nxtpc)
    INST("0'10111'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",       BNE, true, nxtpc =      Regs(rj) !=      Regs(rd) ? curpc + sext(offs16 << 2, 18) : nxtpc)
    INST("0'11000'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",       BLT, true, nxtpc = (i32)Regs(rj) <  (i32)Regs(rd) ? curpc + sext(offs16 << 2, 18) : nxtpc)
    INST("0'11001'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",       BGE, true, nxtpc = (i32)Regs(rj) >= (i32)Regs(rd) ? curpc + sext(offs16 << 2, 18) : nxtpc)
    INST("0'11010'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",      BLTU, true, nxtpc =      Regs(rj) <       Regs(rd) ? curpc + sext(offs16 << 2, 18) : nxtpc)
    INST("0'11011'xxxxxxxxxxxxxxxx'xxxxx'xxxxx",      BGEU, true, nxtpc =      Regs(rj) >=      Regs(rd) ? curpc + sext(offs16 << 2, 18) : nxtpc)

    printf("%08x: %s\n", inst, curinst);

    return nxtpc;
}

u32 fetch() {
    u32 inst;
    sysbus->read32(inst, Regs(PC));
    return inst;
}

void reset() {

    auto &&crmd = CSRs.at(CRMD).data;
    sb( CRMD_PLV, crmd, 0);
    sb(  CRMD_IE, crmd, 0);
    sb(  CRMD_DA, crmd, 1);
    sb(  CRMD_PG, crmd, 0);
    sb(CRMD_DATF, crmd, 0);
    sb(CRMD_DATM, crmd, 0);
    
    auto &&euen = CSRs.at(EUEN).data;
    sb(EUEN_FPE, euen, 0);

    auto &&ecfg = CSRs.at(ECFG).data;
    sb(ECFG_LIE_09_00, ecfg, 0);
    sb(ECFG_LIE_12_11, ecfg, 0);

    auto &&estat = CSRs.at(ESTAT).data;
    sb(ESTAT_IS_01_00, estat, 0);

    auto &&tcfg = CSRs.at(TCFG).data;
    sb(TCFG_En, tcfg, 0);

    auto &&llbctl = CSRs.at(LLBCTL).data;
    sb(LLBCTL_KLO, llbctl, 0);

    auto &&dmw0 = CSRs.at(DMW0).data;
    sb(DMW_PLV0, dmw0, 0);
    sb(DMW_PLV3, dmw0, 0);

    auto &&dmw1 = CSRs.at(DMW0).data;
    sb(DMW_PLV0, dmw1, 0);
    sb(DMW_PLV3, dmw1, 0);
}

}

LA32R::LA32R(SystemBus *bus) {
    sysbus = bus;
    init_csr();
    Regs >> RSTVEC;
}

void LA32R::Step(unsigned in) {
    u32 inst = fetch();
    auto &&nxtpc = decode_and_exec(inst, Regs(PC));
    Regs >> nxtpc;
}