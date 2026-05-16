# ============================================================
# File    : isa_diag.S
# Purpose : RV32IM ISA diagnostic program
#           Exercises arithmetic, logic, shifts, branches,
#           jumps, upper-immediate ops, multiply/divide, and
#           load/store behavior including LB/LBU/LH/LHU/SB/SH.
#           Writes pass/fail signatures
#           into DMEM for the CPU regression bench.
# ============================================================

.section .text
.global main

.equ STATUS_ADDR,   0x20000000
.equ DETAIL_ADDR,   0x20000004
.equ SCRATCH_ADDR,  0x20000100
.equ RUN_SIG,       0x12345678
.equ PASS_SIG,      0x1A5A1A5A
.equ FAIL_SIG,      0x0BAD0BAD

main:
    li   t0, STATUS_ADDR
    li   t1, RUN_SIG
    sw   t1, 0(t0)
    li   t0, DETAIL_ADDR
    sw   zero, 0(t0)

    # Basic arithmetic and logic
    addi s0, zero, 5
    addi s1, zero, 12
    add  s2, s0, s1
    li   t0, 17
    bne  s2, t0, fail_1

    sub  s3, s1, s0
    li   t0, 7
    bne  s3, t0, fail_2

    andi s4, s2, 6
    li   t0, 0
    bne  s4, t0, fail_3

    ori  s5, s4, 9
    li   t0, 9
    bne  s5, t0, fail_4

    xori s6, s5, 15
    li   t0, 6
    bne  s6, t0, fail_5

    slli s7, s0, 3
    li   t0, 40
    bne  s7, t0, fail_6

    srli s8, s7, 2
    li   t0, 10
    bne  s8, t0, fail_7

    addi s9, zero, -16
    srai s10, s9, 2
    li   t0, -4
    bne  s10, t0, fail_8

    slti s11, s9, 1
    li   t0, 1
    bne  s11, t0, fail_9

    sltiu s11, s9, 1
    li   t0, 0
    bne  s11, t0, fail_10

    slt  s11, s9, s0
    li   t0, 1
    bne  s11, t0, fail_11

    sltu s11, s0, s9
    li   t0, 1
    bne  s11, t0, fail_12

    # Upper-immediate ops
    lui  s11, 0x12345
    li   t0, 0x12345000
    bne  s11, t0, fail_13

auipc_anchor:
    auipc s11, 0
    la   t0, auipc_anchor
    bne  s11, t0, fail_14

    # Load/store
    li   t1, SCRATCH_ADDR
    sw   s2, 0(t1)
    lw   t2, 0(t1)
    bne  t2, s2, fail_15

    # Multiply/divide extension
    mul  a0, s0, s1
    li   t0, 60
    bne  a0, t0, fail_16

    lui  a1, 0x80000
    addi a2, zero, 2
    mulh a3, a1, a2
    li   t0, -1
    bne  a3, t0, fail_17

    div  a4, s1, s0
    li   t0, 2
    bne  a4, t0, fail_18

    divu a5, s1, s0
    li   t0, 2
    bne  a5, t0, fail_19

    rem  a6, s1, s0
    li   t0, 2
    bne  a6, t0, fail_20

    remu a7, s1, s0
    li   t0, 2
    bne  a7, t0, fail_21

    # MULHSU: signed×unsigned — upper 32 bits of 64-bit product
    # negative operand_a: sign_ext(-1) × zero_ext(0xFFFFFFFF) = 0xFFFFFFFF_00000001 → upper = -1
    addi a0, zero, -1
    addi a1, zero, -1
    mulhsu a2, a0, a1
    li   t0, -1
    bne  a2, t0, fail_54

    # positive operand_a: 5 × 12 = 60 → upper = 0
    mulhsu a2, s0, s1
    bne  a2, zero, fail_55

    # MULHU: unsigned×unsigned — upper 32 bits of 64-bit product
    # 0x80000000 × 0x80000000 = 2^62 → upper = 0x40000000
    lui  a0, 0x80000
    lui  a1, 0x80000
    mulhu a2, a0, a1
    li   t0, 0x40000000
    bne  a2, t0, fail_56

    # 0xFFFFFFFF × 0xFFFFFFFF = 0xFFFFFFFE_00000001 → upper = 0xFFFFFFFE
    addi a0, zero, -1
    addi a1, zero, -1
    mulhu a2, a0, a1
    li   t0, -2
    bne  a2, t0, fail_57

    # MULHSU corner case: INT_MIN × 0xFFFFFFFF
    # sign_ext(0x80000000) × zero_ext(0xFFFFFFFF) = (-2^31)×(2^32-1) = -2^63+2^31
    # upper 32 bits = 0x80000000
    lui  a0, 0x80000           # a0 = 0x80000000 (INT_MIN)
    addi a1, zero, -1          # a1 = 0xFFFFFFFF
    mulhsu a2, a0, a1
    lui  t0, 0x80000           # expected upper = 0x80000000
    bne  a2, t0, fail_58

    # MULHSU corner case: operand_b = 0 → product always 0
    mulhsu a2, a0, zero
    bne  a2, zero, fail_59

    # Taken and not-taken branches
    beq  s0, s0, beq_taken
    j    fail_22
beq_taken:
    beq  s0, s1, fail_23

    bne  s0, s1, bne_taken
    j    fail_24
bne_taken:
    bne  s0, s0, fail_25

    blt  s9, s0, blt_taken
    j    fail_26
blt_taken:
    blt  s0, s9, fail_27

    bge  s0, s9, bge_taken
    j    fail_28
bge_taken:
    bge  s9, s0, fail_29

    bltu s0, s9, bltu_taken
    j    fail_30
bltu_taken:
    bltu s9, s0, fail_31

    bgeu s9, s0, bgeu_taken
    j    fail_32
bgeu_taken:
    bgeu s0, s9, fail_33

    # Jump and link
    jal  ra, jal_target
jal_return:
    j    fail_34
jal_target:
    la   t0, jal_return
    bne  ra, t0, fail_35

    # Jump and link register
    la   t1, jalr_target
    jalr t2, t1, 0
jalr_return:
    j    fail_36
jalr_target:
    la   t0, jalr_return
    bne  t2, t0, fail_37

    # Subword load/store behavior
    li   t3, SCRATCH_ADDR
    li   t4, 0x80FF7F01
    sw   t4, 8(t3)

    lb   t5, 10(t3)
    li   t0, -1
    bne  t5, t0, fail_38

    lbu  t6, 10(t3)
    li   t0, 255
    bne  t6, t0, fail_39

    lb   t5, 11(t3)
    li   t0, -128
    bne  t5, t0, fail_40

    lbu  t6, 11(t3)
    li   t0, 128
    bne  t6, t0, fail_41

    lh   t5, 10(t3)
    li   t0, 0xFFFF80FF
    bne  t5, t0, fail_42

    lhu  t6, 10(t3)
    li   t0, 0x80FF
    bne  t6, t0, fail_43

    sw   zero, 12(t3)
    li   t4, -1
    sb   t4, 13(t3)
    li   t4, 0xABCD
    sh   t4, 14(t3)

    lw   t5, 12(t3)
    li   t0, 0xABCDFF00
    bne  t5, t0, fail_44

    lh   t5, 14(t3)
    li   t0, 0xFFFFABCD
    bne  t5, t0, fail_45

    lhu  t6, 14(t3)
    li   t0, 0xABCD
    bne  t6, t0, fail_46

    lb   t5, 13(t3)
    li   t0, -1
    bne  t5, t0, fail_47

    lbu  t6, 13(t3)
    li   t0, 255
    bne  t6, t0, fail_48

    # Success signature
    li   t0, DETAIL_ADDR
    sw   zero, 0(t0)
    li   t0, STATUS_ADDR
    li   t1, PASS_SIG
    sw   t1, 0(t0)

pass_loop:
    j pass_loop

fail_1:  li a0, 1;  j fail
fail_2:  li a0, 2;  j fail
fail_3:  li a0, 3;  j fail
fail_4:  li a0, 4;  j fail
fail_5:  li a0, 5;  j fail
fail_6:  li a0, 6;  j fail
fail_7:  li a0, 7;  j fail
fail_8:  li a0, 8;  j fail
fail_9:  li a0, 9;  j fail
fail_10: li a0, 10; j fail
fail_11: li a0, 11; j fail
fail_12: li a0, 12; j fail
fail_13: li a0, 13; j fail
fail_14: li a0, 14; j fail
fail_15: li a0, 15; j fail
fail_16: li a0, 16; j fail
fail_17: li a0, 17; j fail
fail_18: li a0, 18; j fail
fail_19: li a0, 19; j fail
fail_20: li a0, 20; j fail
fail_21: li a0, 21; j fail
fail_22: li a0, 22; j fail
fail_23: li a0, 23; j fail
fail_24: li a0, 24; j fail
fail_25: li a0, 25; j fail
fail_26: li a0, 26; j fail
fail_27: li a0, 27; j fail
fail_28: li a0, 28; j fail
fail_29: li a0, 29; j fail
fail_30: li a0, 30; j fail
fail_31: li a0, 31; j fail
fail_32: li a0, 32; j fail
fail_33: li a0, 33; j fail
fail_34: li a0, 34; j fail
fail_35: li a0, 35; j fail
fail_36: li a0, 36; j fail
fail_37: li a0, 37; j fail
fail_38: li a0, 38; j fail
fail_39: li a0, 39; j fail
fail_40: li a0, 40; j fail
fail_41: li a0, 41; j fail
fail_42: li a0, 42; j fail
fail_43: li a0, 43; j fail
fail_44: li a0, 44; j fail
fail_45: li a0, 45; j fail
fail_46: li a0, 46; j fail
fail_47: li a0, 47; j fail
fail_48: li a0, 48; j fail
fail_49: li a0, 49; j fail
fail_50: li a0, 50; j fail
fail_51: li a0, 51; j fail
fail_52: li a0, 52; j fail
fail_53: li a0, 53; j fail
fail_54: li a0, 54; j fail
fail_55: li a0, 55; j fail
fail_56: li a0, 56; j fail
fail_57: li a0, 57; j fail
fail_58: li a0, 58; j fail
fail_59: li a0, 59; j fail

fail:
    li   t0, DETAIL_ADDR
    sw   a0, 0(t0)
    li   t0, STATUS_ADDR
    li   t1, FAIL_SIG
    sw   t1, 0(t0)

fail_loop:
    j fail_loop
