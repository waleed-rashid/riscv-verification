`timescale 1ns/1ps

module cpu_assertions (
    input logic        clk,
    input logic        reset,
    input logic [31:0] pc,
    input logic [31:0] instruction,
    input logic [4:0]  rd,
    input logic        reg_write,
    input logic [31:0] x0_value
);

    logic [31:0] previous_pc;
    logic        have_previous_pc;
    logic        reset_seen;
    integer      assertion_failures;

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];
    wire supported =
        ((opcode == 7'b0010011) && (funct3 == 3'b000)) ||
        ((opcode == 7'b0110011) &&
         (((funct3 == 3'b000) &&
           ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) ||
          ((funct7 == 7'b0000000) &&
           ((funct3 == 3'b100) || (funct3 == 3'b110) ||
            (funct3 == 3'b111)))));

    task automatic fail_assertion(input string message);
        begin
            assertion_failures = assertion_failures + 1;
            $display("ASSERTION FAILED: %s", message);
            $fatal(1, "CPU assertion failure");
        end
    endtask

    initial begin
        previous_pc = 32'b0;
        have_previous_pc = 1'b0;
        reset_seen = 1'b0;
        assertion_failures = 0;
    end

    always @(posedge clk) begin
        if (reset) begin
            if (reset_seen && (pc !== 32'b0))
                fail_assertion("PC must be zero during reset");
            reset_seen = 1'b1;
            have_previous_pc = 1'b0;
        end
        else begin
            // x0 is architecturally hardwired to zero.
            if (x0_value !== 32'b0)
                fail_assertion("x0 changed from zero");

            // Every supported or unsupported instruction must not write x0.
            if (reg_write && (rd == 5'd0))
                fail_assertion("register write targeted x0");

            // Unsupported instructions must be side-effect free.
            if (!supported && reg_write)
                fail_assertion("unsupported instruction asserted reg_write");

            // Normal sequential execution advances the PC by four bytes.
            if (have_previous_pc && (pc !== (previous_pc + 32'd4)))
                fail_assertion("PC did not increment by four");

            previous_pc = pc;
            have_previous_pc = 1'b1;
        end
    end

endmodule
