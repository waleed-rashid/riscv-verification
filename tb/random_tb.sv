`timescale 1ns/1ps

module random_tb;

    logic clk;
    logic reset;
    integer count;
    integer i;
    integer program_loaded;
    reg [1023:0] program_file;

    cpu dut (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file)) begin
            $display("ERROR: PROGRAM plusarg is required");
            $fatal(1);
        end

        if (!$value$plusargs("COUNT=%d", count)) begin
            $display("ERROR: COUNT plusarg is required");
            $fatal(1);
        end

        // Wait for the DUT's time-zero memory initialization.
        #1;
        $readmemh(program_file, dut.instruction_memory);

        reset = 1'b1;
        #12;
        reset = 1'b0;

        // One instruction executes per clock. The extra delay allows the
        // final register-file nonblocking update to settle before sampling.
        #(count * 10 + 2);

        for (i = 0; i < 32; i = i + 1)
            $display("R[%0d]=%08h", i, dut.register_file_unit.registers[i]);
        $display("PC=%08h", dut.pc);
        $finish;
    end

endmodule
