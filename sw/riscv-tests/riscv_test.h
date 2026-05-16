// ============================================================
// riscv_test.h — Custom environment for riscv-tests on RV32IM SoC
//
// Pass/fail convention (tohost = DMEM[0] = 0x20000000):
//   tohost == 0              still running
//   tohost == 1              PASS — all test cases passed
//   tohost == (N<<1)|1       FAIL — test case N failed (always odd, > 1)
// ============================================================
#ifndef _RISCV_TEST_H
#define _RISCV_TEST_H

// TESTNUM: register that holds the current test case number
#define TESTNUM gp

// Declare as both RV32 and RV64 so the shared rv64ui test bodies compile
// for RV32 (rv32ui wrappers redefine RVTEST_RV64U → RVTEST_RV32U).
#define RVTEST_RV32U
#define RVTEST_RV64U

// ---------------------------------------------------------------
// Code section start
// ---------------------------------------------------------------
#define RVTEST_CODE_BEGIN        \
    .section .text.init;         \
    .align   2;                  \
    .globl   _start;             \
_start:                          \
    li  TESTNUM, 0;

// ---------------------------------------------------------------
// Code section end — most test files call TEST_PASSFAIL explicitly
// before this, so this must be empty to avoid duplicate fail:/pass: labels.
// simple.S uses RVTEST_PASS directly and has no TEST_CASE bne-to-fail refs.
// ---------------------------------------------------------------
#define RVTEST_CODE_END

// ---------------------------------------------------------------
// Pass: write 1 to tohost, then spin forever
// ---------------------------------------------------------------
#define RVTEST_PASS              \
    li  t0, 1;                   \
    la  t1, tohost;              \
    sw  t0, 0(t1);               \
1:  j   1b;

// ---------------------------------------------------------------
// Fail: write (TESTNUM<<1)|1 to tohost (odd, > 1), then spin
// ---------------------------------------------------------------
#define RVTEST_FAIL              \
    sll t0, TESTNUM, 1;          \
    ori t0, t0, 1;               \
    la  t1, tohost;              \
    sw  t0, 0(t1);               \
1:  j   1b;

// ---------------------------------------------------------------
// Data section: reserve 'tohost' as the first word of DMEM
// The linker script places .data at 0x20000000, so tohost = DMEM[0].
// ---------------------------------------------------------------
#define RVTEST_DATA_BEGIN        \
    .data;                       \
    .align  3;                   \
    .globl  tohost;              \
tohost:                          \
    .word   0;                   \
    .word   0;

#define RVTEST_DATA_END

#endif /* _RISCV_TEST_H */
