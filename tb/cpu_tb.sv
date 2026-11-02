`timescale 1ns/1ps

module cpu_tb;

    logic clk;
    logic reset;
    integer failures;


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
        failures = 0;
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

        // ADDI x8, x0, 123 (baseline for unsupported-instruction checks)
        dut.instruction_memory[7] = 32'h07B00413;

        // Unsupported R-type encoding: must not modify x8
        dut.instruction_memory[8] = 32'h00209433;

        // Unsupported I-type encoding (funct3=001): must not modify x8
        dut.instruction_memory[9] = 32'h00141413;


        // Wait for instructions to execute

        #110;


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
        $display("x8 = %0d", dut.register_file_unit.registers[8]);
        $display("x0 = %0d", dut.register_file_unit.registers[0]);


        // PASS / FAIL
        if (dut.register_file_unit.registers[1] == 32'd10)
            $display("x1 TEST PASSED");
        else begin
            $display("x1 TEST FAILED");
            failures = failures + 1;
        end


        if (dut.register_file_unit.registers[2] == 32'd20)
            $display("x2 TEST PASSED");
        else begin
            $display("x2 TEST FAILED");
            failures = failures + 1;
        end


        if (dut.register_file_unit.registers[3] == 32'd30)
            $display("x3 TEST PASSED");
        else begin
            $display("x3 TEST FAILED");
            failures = failures + 1;
        end


        if (dut.register_file_unit.registers[4] == 32'd20)
            $display("x4 TEST PASSED");
        else begin
            $display("x4 TEST FAILED");
            failures = failures + 1;
        end


        if (dut.register_file_unit.registers[5] == 32'd0)
            $display("x5 TEST PASSED");
        else begin
            $display("x5 TEST FAILED");
            failures = failures + 1;
        end


        if (dut.register_file_unit.registers[6] == 32'd30)
            $display("x6 TEST PASSED");
        else begin
            $display("x6 TEST FAILED");
            failures = failures + 1;
        end


        if (dut.register_file_unit.registers[7] == 32'd30)
            $display("x7 TEST PASSED");
        else begin
            $display("x7 TEST FAILED");
            failures = failures + 1;
        end

        if (dut.register_file_unit.registers[8] == 32'd123)
            $display("unsupported instruction TEST PASSED");
        else begin
            $display("unsupported instruction TEST FAILED");
            failures = failures + 1;
        end


        // x0 must always be zero

        if (dut.register_file_unit.registers[0] == 32'd0)
            $display("x0 TEST PASSED");
        else begin
            $display("x0 TEST FAILED");
            failures = failures + 1;
        end


        $display("==============================");
        if (failures == 0)
            $display("CPU TEST COMPLETE: PASS");
        else begin
            $display("CPU TEST COMPLETE: FAIL (%0d failures)", failures);
            $fatal(1, "CPU test failed");
        end
        $display("==============================");


        $finish;

    end

endmodule
