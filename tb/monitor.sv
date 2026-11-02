`timescale 1ns/1ps

module monitor (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] pc,
    input  logic [31:0] instruction,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [2:0]  alu_control,
    input  logic [31:0] alu_result,
    input  logic        reg_write,
    input  logic [31:0] writeback_data
);

    // This passive monitor intentionally has no checking logic. It observes
    // the transaction-level DUT signals consumed by the scoreboard.
    always @(posedge clk) begin
        if (!reset)
            $display("MONITOR pc=%08h instr=%08h rs1=%0d rs2=%0d rd=%0d alu=%0d result=%08h we=%b wb=%08h",
                     pc, instruction, rs1, rs2, rd, alu_control,
                     alu_result, reg_write, writeback_data);
    end

endmodule
