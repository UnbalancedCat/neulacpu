#include "defs.h"

#ifndef ASM_H__
#define ASM_H__

// CSR infos
#define CRMD        0x000 /* 当前模式信息 */
#define PRMD        0x001 /* 例外前模式信息 */
#define EUEN        0x002 /* 拓展部件使能 */
#define ECFG        0x004 /* 例外配置 */
#define ESTAT       0x005 /* 例外状态 */
#define ERA         0x006 /* 例外返回地址 */
#define BADV        0x007 /* 出错虚地址 */
#define EENTRY      0x00c /* 例外地址入口 */
#define TLBIDX      0x010 /* TLB 索引 */
#define TLBEHI      0x011 /* TLB 表项高位 */
#define TLBELO0     0x012 /* TLB 表项低位 0 */
#define TLBELO1     0x013 /* TLB 表项低位 1 */
#define ASID        0x018 /* 地址空间标识符 */
#define PGDL        0x019 /* 低半地址空间全局目录基址 */
#define PGDH        0x01a /* 高半地址空间全局目录基址 */
#define PGD         0x01b /* 全局目录基址 */
#define CPUID       0x020 /* 处理器编号 */
#define SAVE0       0x030 /* 数据保存 0*/
#define SAVE1       0x031 /* 数据保存 1*/
#define SAVE2       0x032 /* 数据保存 2 */
#define SAVE3       0x033 /* 数据保存 3 */
#define TID         0x040 /* 定时器编号 */
#define TCFG        0x041 /* 定时器配置 */
#define TVAL        0x042 /* 定时器值 */
#define TICLR       0x044 /* 定时中断清除 */
#define LLBCTL      0x060 /* LLBit 控制 */
#define TLBRENTRY   0x088 /* TLB 重填例外入口 */
#define CTAG        0x098 /* 高速缓存标签 */
#define DMW0        0x180 /* 直接映射配置窗口 0 */
#define DMW1        0x181 /* 直接映射配置窗口 1 */

#endif