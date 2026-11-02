`timescale 1ns/1ps

module cpu_coverage (
    input logic        clk,
    input logic        reset,
    input logic [31:0] pc,
    input logic [31:0] instruction,
    input logic [4:0]  rs1,
    input logic [4:0]  rs2,
    input logic [4:0]  rd,
    input logic [2:0]  alu_control,
    input logic        reg_write,
    input logic        done
);

    integer operation_hits [0:5];
    logic   rd_seen [0:31];
    logic   rs1_seen [0:31];
    logic   rs2_seen [0:31];
    logic   immediate_sign_seen [0:1];
    integer reset_hits;
    integer dependency_hits;
    integer x0_operand_hits;
    integer writeback_hits;
    integer unsupported_hits;
    integer samples;
    integer i;
    logic [4:0] previous_rd;
    logic       previous_write;

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];
    wire [2:0] operation = alu_control;
    wire is_addi = (opcode == 7'b0010011) && (funct3 == 3'b000);
    wire is_supported_rtype =
        (opcode == 7'b0110011) &&
        (((funct3 == 3'b000) &&
          ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) ||
         ((funct7 == 7'b0000000) &&
          ((funct3 == 3'b100) || (funct3 == 3'b110) ||
           (funct3 == 3'b111))));
    wire is_supported = is_addi || is_supported_rtype;

    initial begin
        for (i = 0; i < 6; i = i + 1)
            operation_hits[i] = 0;
        for (i = 0; i < 32; i = i + 1) begin
            rd_seen[i] = 1'b0;
            rs1_seen[i] = 1'b0;
            rs2_seen[i] = 1'b0;
        end
        immediate_sign_seen[0] = 1'b0;
        immediate_sign_seen[1] = 1'b0;
        reset_hits = 0;
        dependency_hits = 0;
        x0_operand_hits = 0;
        writeback_hits = 0;
        unsupported_hits = 0;
        samples = 0;
        previous_rd = 5'd0;
        previous_write = 1'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            reset_hits = reset_hits + 1;
            previous_write = 1'b0;
        end
        else begin
            samples = samples + 1;
            rd_seen[rd] = 1'b1;
            rs1_seen[rs1] = 1'b1;
            rs2_seen[rs2] = 1'b1;

            if ((rs1 == 5'd0) || (rs2 == 5'd0))
                x0_operand_hits = x0_operand_hits + 1;

            if (previous_write && (previous_rd != 5'd0) &&
                ((rs1 == previous_rd) || (rs2 == previous_rd)))
                dependency_hits = dependency_hits + 1;

            if (reg_write)
                writeback_hits = writeback_hits + 1;

            if (!is_supported)
                unsupported_hits = unsupported_hits + 1;

            if (is_addi)
                immediate_sign_seen[instruction[31]] = 1'b1;

            if (is_supported) begin
                // Coverage bins are instruction classes, not raw ALU codes:
                // ADD and ADDI both use ALU_ADD but are distinct instructions.
                if (is_addi)
                    operation_hits[5] = operation_hits[5] + 1;
                else if ((funct3 == 3'b000) && (funct7 == 7'b0000000))
                    operation_hits[0] = operation_hits[0] + 1; // ADD
                else if ((funct3 == 3'b000) && (funct7 == 7'b0100000))
                    operation_hits[1] = operation_hits[1] + 1; // SUB
                else if (funct3 == 3'b111)
                    operation_hits[2] = operation_hits[2] + 1; // AND
                else if (funct3 == 3'b110)
                    operation_hits[3] = operation_hits[3] + 1; // OR
                else if (funct3 == 3'b100)
                    operation_hits[4] = operation_hits[4] + 1; // XOR
            end

            previous_rd = rd;
            previous_write = reg_write;
        end
    end

    always @(posedge done) begin
        integer operation_bins;
        integer register_bins;
        integer immediate_bins;
        operation_bins = 0;
        register_bins = 0;
        immediate_bins = 0;

        for (i = 0; i < 6; i = i + 1)
            if (operation_hits[i] > 0)
                operation_bins = operation_bins + 1;
        for (i = 0; i < 32; i = i + 1)
            if (rd_seen[i] && rs1_seen[i] && rs2_seen[i])
                register_bins = register_bins + 1;
        for (i = 0; i < 2; i = i + 1)
            if (immediate_sign_seen[i])
                immediate_bins = immediate_bins + 1;

        $display("COVERAGE SUMMARY");
        $display("  samples                 = %0d", samples);
        $display("  operations hit          = %0d/6", operation_bins);
        $display("  registers seen all ports= %0d/32", register_bins);
        $display("  immediate signs hit     = %0d/2", immediate_bins);
        $display("  dependencies            = %0d", dependency_hits);
        $display("  x0 operand scenarios    = %0d", x0_operand_hits);
        $display("  register writebacks     = %0d", writeback_hits);
        $display("  unsupported instructions= %0d", unsupported_hits);
        $display("  reset cycles            = %0d", reset_hits);
    end

endmodule
