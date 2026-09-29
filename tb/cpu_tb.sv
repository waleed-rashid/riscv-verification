`timescale 1ns/1ps

module cpu_tb;

    logic clk;
    logic reset;


    // Instantiate CPU
    cpu dut (
        .clk(clk),
        .reset(reset)
    );


    // Clock
    initial begin

        clk = 0;

        forever #5 clk = ~clk;

    end


    // Test
    initial begin

        // Create waveform
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);


        // Reset CPU
        reset = 1;

        #12;

        reset = 0;


        // Program

        // ADDI x1, x0, 10
        dut.instruction_memory[0] = 32'h00A00093;

        // ADDI x2, x0, 20
        dut.instruction_memory[1] = 32'h01400113;

        // ADD x3, x1, x2
        dut.instruction_memory[2] = 32'h002081B3;

        // SUB x4, x3, x1
        dut.instruction_memory[3] = 32'h40118233;

        // AND x5, x1, x2
        dut.instruction_memory[4] = 32'h0020F2B3;

        // OR x6, x1, x2
        dut.instruction_memory[5] = 32'h0020E333;

        // XOR x7, x1, x2
        dut.instruction_memory[6] = 32'h0020C3B3;


        // Wait for instructions to execute

        #80;


        // Check results
        $display("");
        $display("==============================");
        $display("CPU TEST RESULTS");
        $display("==============================");

        $display("x1 = %0d", dut.register_file_unit.registers[1]);
        $display("x2 = %0d", dut.register_file_unit.registers[2]);
        $display("x3 = %0d", dut.register_file_unit.registers[3]);
        $display("x4 = %0d", dut.register_file_unit.registers[4]);
        $display("x5 = %0d", dut.register_file_unit.registers[5]);
        $display("x6 = %0d", dut.register_file_unit.registers[6]);
        $display("x7 = %0d", dut.register_file_unit.registers[7]);


        // PASS / FAIL
        if (dut.register_file_unit.registers[1] == 32'd10)
            $display("x1 TEST PASSED");
        else
            $display("x1 TEST FAILED");


        if (dut.register_file_unit.registers[2] == 32'd20)
            $display("x2 TEST PASSED");
        else
            $display("x2 TEST FAILED");


        if (dut.register_file_unit.registers[3] == 32'd30)
            $display("x3 TEST PASSED");
        else
            $display("x3 TEST FAILED");


        if (dut.register_file_unit.registers[4] == 32'd20)
            $display("x4 TEST PASSED");
        else
            $display("x4 TEST FAILED");


        if (dut.register_file_unit.registers[5] == 32'd0)
            $display("x5 TEST PASSED");
        else
            $display("x5 TEST FAILED");


        if (dut.register_file_unit.registers[6] == 32'd30)
            $display("x6 TEST PASSED");
        else
            $display("x6 TEST FAILED");


        if (dut.register_file_unit.registers[7] == 32'd30)
            $display("x7 TEST PASSED");
        else
            $display("x7 TEST FAILED");


        // x0 must always be zero

        if (dut.register_file_unit.registers[0] == 32'd0)
            $display("x0 TEST PASSED");
        else
            $display("x0 TEST FAILED");


        $display("==============================");
        $display("CPU TEST COMPLETE");
        $display("==============================");


        $finish;

    end

endmodule