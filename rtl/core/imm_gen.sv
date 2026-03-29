// ============================================================
// Module  : imm_gen
// Purpose : Immediate value generator for RV32IM
//           Extracts and sign-extends immediates from
//           all RISC-V instruction formats (I, S, B, U, J)
// ============================================================

import riscv_pkg::*;

module imm_gen (
    input  logic [31:0] instruction,
    output logic [31:0] imm_out
);

    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            OP_I_ALU, OP_I_LOAD, OP_JALR: begin
                // I-type: imm[11:0] = instruction[31:20]
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
            end

            OP_S: begin
                // S-type: imm[11:5] = instruction[31:25]
                //         imm[4:0]  = instruction[11:7]
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            OP_B: begin
                // B-type: imm[12]   = instruction[31]
                //         imm[10:5] = instruction[30:25]
                //         imm[4:1]  = instruction[11:8]
                //         imm[11]   = instruction[7]
                //         imm[0]    = always 0
                imm_out = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end

            OP_LUI, OP_AUIPC: begin
                // U-type: imm[31:12] = instruction[31:12]
                //         imm[11:0]  = 0
                imm_out = {instruction[31:12], 12'b0};
            end

            OP_JAL: begin
                // J-type: imm[20]    = instruction[31]
                //         imm[10:1]  = instruction[30:21]
                //         imm[11]    = instruction[20]
                //         imm[19:12] = instruction[19:12]
                //         imm[0]     = always 0
                imm_out = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end

            default: imm_out = 32'b0;
        endcase
    end

endmodule