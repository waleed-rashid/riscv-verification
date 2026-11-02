`timescale 1ns/1ps

module alu_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [2:0]  alu_control;
    logic [31:0] result;
    integer failures;

    alu dut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result)
    );

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;

    initial begin

        failures = 0;

        // ADD
        a = 32'd10;
        b = 32'd20;
        alu_control = ALU_ADD;
        #10;

        if (result == 32'd30)
            $display("ADD PASSED");
        else begin
            $display("ADD FAILED: got %d", result);
            failures = failures + 1;
        end


        // SUB
        a = 32'd20;
        b = 32'd10;
        alu_control = ALU_SUB;
        #10;

        if (result == 32'd10)
            $display("SUB PASSED");
        else begin
            $display("SUB FAILED: got %d", result);
            failures = failures + 1;
        end


        // AND
        a = 32'hF0F0;
        b = 32'h0FF0;
        alu_control = ALU_AND;
        #10;

        if (result == 32'h00F0)
            $display("AND PASSED");
        else begin
            $display("AND FAILED: got %h", result);
            failures = failures + 1;
        end


        // OR
        a = 32'hF000;
        b = 32'h00F0;
        alu_control = ALU_OR;
        #10;

        if (result == 32'hF0F0)
            $display("OR PASSED");
        else begin
            $display("OR FAILED: got %h", result);
            failures = failures + 1;
        end


        // XOR
        a = 32'hFF00;
        b = 32'h0F0F;
        alu_control = ALU_XOR;
        #10;

        if (result == 32'hF00F)
            $display("XOR PASSED");
        else begin
            $display("XOR FAILED: got %h", result);
            failures = failures + 1;
        end


        if (failures == 0)
            $display("ALU TEST COMPLETE: PASS");
        else begin
            $display("ALU TEST COMPLETE: FAIL (%0d failures)", failures);
            $fatal(1, "ALU test failed");
        end

        $finish;

    end

endmodule
