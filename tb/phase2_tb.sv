`timescale 1ns/1ps

module phase2_tb;

    logic clk;
    logic reset;

    logic [31:0] generated_program [0:15];
    integer program_count;
    logic program_ready;

    logic [31:0] pc;
    logic [31:0] instruction;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [2:0]  alu_control;
    logic [31:0] alu_result;
    logic        reg_write;
    logic [31:0] writeback_data;
    logic        scoreboard_done;
    logic        scoreboard_passed;

    cpu dut (
        .clk(clk),
        .reset(reset)
    );

    assign pc = dut.pc;
    assign instruction = dut.instruction;
    assign rs1 = dut.rs1;
    assign rs2 = dut.rs2;
    assign rd = dut.rd;
    assign alu_control = dut.alu_control;
    assign alu_result = dut.alu_result;
    assign reg_write = dut.reg_write;
    assign writeback_data = dut.writeback_data;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    generator gen (
        .ready(program_ready)
    );

    driver drv (
        .program_ready(program_ready),
        .reset(reset)
    );

    monitor mon (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .reg_write(reg_write),
        .writeback_data(writeback_data)
    );

    scoreboard sb (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .rd(rd),
        .writeback_data(writeback_data),
        .reg_write(reg_write),
        .x0_value(dut.register_file_unit.registers[0]),
        .done(scoreboard_done),
        .passed(scoreboard_passed)
    );

    cpu_assertions assertions (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction),
        .rd(rd),
        .reg_write(reg_write),
        .x0_value(dut.register_file_unit.registers[0])
    );

    cpu_coverage coverage (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_control(alu_control),
        .reg_write(reg_write),
        .done(scoreboard_done)
    );

    initial begin
        $dumpfile("phase2.vcd");
        $dumpvars(0, phase2_tb);

        wait (scoreboard_done);
        if (!scoreboard_passed)
            $fatal(1, "Phase 2 scoreboard failed");

        $display("PHASE 2 TEST COMPLETE: PASS");
        $finish;
    end

endmodule
