`timescale 1ns/1ps

module generator (
    output logic       ready
);

    initial begin
        phase2_tb.program_count = 10;

        // Directed program covering every currently supported instruction.
        phase2_tb.generated_program[0] = 32'h00A00093; // ADDI x1, x0, 10
        phase2_tb.generated_program[1] = 32'h01400113; // ADDI x2, x0, 20
        phase2_tb.generated_program[2] = 32'h002081B3; // ADD  x3, x1, x2
        phase2_tb.generated_program[3] = 32'h40118233; // SUB  x4, x3, x1
        phase2_tb.generated_program[4] = 32'h0020F2B3; // AND  x5, x1, x2
        phase2_tb.generated_program[5] = 32'h0020E333; // OR   x6, x1, x2
        phase2_tb.generated_program[6] = 32'h0020C3B3; // XOR  x7, x1, x2
        phase2_tb.generated_program[7] = 32'h07B00413; // ADDI x8, x0, 123

        // Unsupported encodings must not write back to x8.
        phase2_tb.generated_program[8] = 32'h00209433; // unsupported R-type funct3
        phase2_tb.generated_program[9] = 32'h00141413; // unsupported I-type funct3

        ready = 1'b1;
    end

endmodule
