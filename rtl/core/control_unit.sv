// ============================================================
// Module  : control_unit
// Purpose : Multi-cycle FSM control unit for RV32IM
//           Decodes instructions and drives all control signals
//           States: FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK
// ============================================================

import riscv_pkg::*;
import alu_ops::*;

module control_unit (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [31:0] instruction,
    input  logic        alu_zero,

    output logic [3:0]  alu_operation,
    output logic        alu_src_b,
    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic        mem_to_reg,
    output logic        branch,
    output logic        jump,
    output logic [1:0]  pc_src,
    output logic        fetch_en,     // HIGH during STATE_FETCH only
    output logic        pc_write_en,   // HIGH when PC should update
    output logic        alu_reg_en    // HIGH during EXECUTE — captures ALU result
);

    // --------------------------------------------------------
    // Instruction field extraction
    // Break the 32-bit instruction into named fields
    // --------------------------------------------------------
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    // --------------------------------------------------------
    // FSM state register
    // --------------------------------------------------------
    (* keep = "true" *) logic [2:0] current_state;
    (* keep = "true" *) logic [2:0] next_state;

    always_ff @(posedge clk) begin
        if (rst_n == 0)
            current_state <= STATE_FETCH;
        else
            current_state <= next_state;
    end

    // --------------------------------------------------------
    // FSM next state logic
    // --------------------------------------------------------

    always @(*) begin
        case (current_state)
            STATE_FETCH:    next_state = STATE_DECODE;
            STATE_DECODE:   next_state = STATE_EXECUTE;
            STATE_EXECUTE:  begin
                case (opcode)
                    OP_R: begin
                        if (funct7 == F7_MEXT)
                            next_state = STATE_MUL_WAIT;
                        else
                            next_state = STATE_WRITEBACK;
                    end
                    OP_I_LOAD:          next_state = STATE_MEMORY;
                    OP_S:               next_state = STATE_MEMORY;
                    OP_B:               next_state = STATE_FETCH;
                    OP_JAL, OP_JALR:    next_state = STATE_FETCH;
                    default:            next_state = STATE_WRITEBACK;
                endcase
            end

            STATE_MUL_WAIT: next_state = STATE_WRITEBACK;
            STATE_MEMORY: begin
                case (opcode)
                    OP_I_LOAD: next_state = STATE_WRITEBACK;
                    default:   next_state = STATE_FETCH;
                endcase
            end

            STATE_WRITEBACK: next_state = STATE_FETCH;
            default:         next_state = STATE_FETCH;
        endcase
    end

    // --------------------------------------------------------
    // Output logic (control signal generation)
    // --------------------------------------------------------

    always @(*) begin
        alu_operation = ALU_ADD;
        alu_src_b     = 0;
        reg_write     = 0;
        mem_read      = 0;
        mem_write     = 0;
        mem_to_reg    = 0;
        branch        = 0;
        jump          = 0;
        fetch_en      = 0;
        pc_write_en   = 0;
        alu_reg_en    = 0;
        pc_src        = 2'b00;

        case (current_state)
            STATE_FETCH:    fetch_en = 0;
            STATE_DECODE:   fetch_en = 1;
            STATE_EXECUTE: begin
                alu_reg_en = (opcode == OP_R && funct7 == F7_MEXT) ? 0 : 1;
                case (opcode)
                    OP_R: begin
                        if (funct7 == F7_MEXT) begin
                            // RV32M multiply/divide
                            case (funct3)
                                3'b000:     alu_operation = ALU_MUL;
                                3'b001:     alu_operation = ALU_MULH;
                                3'b100:     alu_operation = ALU_DIV;
                                3'b101:     alu_operation = ALU_DIVU;
                                3'b110:     alu_operation = ALU_REM;
                                3'b111:     alu_operation = ALU_REMU;
                                default:    alu_operation = ALU_ADD;
                            endcase
                        end else begin
                            // RV32I operations
                            case (funct3)
                                F3_ADD_SUB: begin
                                    if (funct7 == F7_ALT)
                                            alu_operation = ALU_SUB;
                                    else
                                            alu_operation = ALU_ADD;
                                end
                                F3_AND:     alu_operation = ALU_AND;
                                F3_OR:      alu_operation = ALU_OR;
                                F3_XOR:     alu_operation = ALU_XOR;
                                F3_SLL:     alu_operation = ALU_SLL;
                                F3_SR: begin
                                    if (funct7 == F7_ALT)
                                            alu_operation = ALU_SRA;
                                    else
                                            alu_operation = ALU_SRL;
                                end
                                F3_SLT:     alu_operation = ALU_SLT;
                                F3_SLTU:    alu_operation = ALU_SLTU;
                            endcase
                        end
                    end

                    OP_B: begin
                        alu_src_b = 0;
                        alu_operation = ALU_SUB;
                        branch = 1;
                        pc_src = 2'b01;
                        pc_write_en = 1;
                    end

                    OP_JAL, OP_JALR: begin
                        jump = 1;
                        pc_src = 2'b10;
                        pc_write_en = 1;
                    end

                    default: begin
                        alu_src_b = 1;  // always use immediate
                        case (funct3)
                            F3_ADD_SUB: alu_operation = ALU_ADD;    // ADDI — no subtraction immediate
                            F3_AND:     alu_operation = ALU_AND;
                            F3_OR:      alu_operation = ALU_OR;
                            F3_XOR:     alu_operation = ALU_XOR;
                            F3_SLL:     alu_operation = ALU_SLL;
                            F3_SR: begin
                                if (funct7 == F7_ALT)
                                        alu_operation = ALU_SRA;
                                else
                                        alu_operation = ALU_SRL;
                            end
                            F3_SLT:     alu_operation = ALU_SLT;
                            F3_SLTU:    alu_operation = ALU_SLTU;
                            default:    alu_operation = ALU_ADD;
                        endcase
                    end
                endcase
            end

            // M-extension settle state: the ALU output has now had 2 full clock
            // periods to propagate. Capture it into alu_result_reg now.
            // The control unit must hold the same alu_operation here — because
            // opcode/funct3/funct7 are still in instr_reg, they are stable.
            STATE_MUL_WAIT: begin
                alu_reg_en = 1;
                case (funct3)
                    3'b000:     alu_operation = ALU_MUL;
                    3'b001:     alu_operation = ALU_MULH;
                    3'b100:     alu_operation = ALU_DIV;
                    3'b101:     alu_operation = ALU_DIVU;
                    3'b110:     alu_operation = ALU_REM;
                    3'b111:     alu_operation = ALU_REMU;
                    default:    alu_operation = ALU_ADD;
                endcase
            end

            STATE_MEMORY: begin
                case (opcode)
                    OP_I_LOAD:  mem_read = 1;
                    OP_S:       mem_write = 1;
                endcase
            end

            STATE_WRITEBACK: begin
                pc_write_en = 1;
                case (opcode)
                    OP_I_LOAD: begin
                        reg_write = 1;
                        mem_to_reg = 1;
                    end
                    default: begin
                        reg_write = 1;
                        mem_to_reg = 0;
                    end
                endcase
            end
        endcase
    end

endmodule