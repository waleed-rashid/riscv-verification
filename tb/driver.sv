`timescale 1ns/1ps

module driver (
    input  logic        program_ready,
    output logic        reset
);

    integer i;

    initial begin
        reset = 1'b1;

        wait (program_ready);

        // Allow the DUT's time-zero instruction-memory initialization to
        // complete before the driver loads the directed program.
        #1;

        // The driver loads the DUT instruction memory through its testbench
        // access point. The DUT remains unchanged and keeps its simple API.
        for (i = 0; i < phase2_tb.program_count; i = i + 1)
            phase2_tb.dut.instruction_memory[i] = phase2_tb.generated_program[i];

        // Hold reset across at least one rising edge.
        #12;
        reset = 1'b0;
    end

endmodule
