module register_file (
    input logic        clk,
    input logic        reset,

    input logic [4:0]  rs1,
    input logic [4:0]  rs2,
    input logic [4:0]  rd,

    input logic [31:0] write_data,
    input logic        reg_write,

    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] registers [0:31];

    integer i;

    // Read ports
    always @(*) begin

        if (rs1 == 5'd0)
            read_data1 = 32'b0;
        else
            read_data1 = registers[rs1];

        if (rs2 == 5'd0)
            read_data2 = 32'b0;
        else
            read_data2 = registers[rs2];

    end


    // Write port
    always @(posedge clk) begin

        if (reset) begin

            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;

        end
        else begin

            if (reg_write && (rd != 5'd0))
                registers[rd] <= write_data;

            // x0 is always zero
            registers[0] <= 32'b0;

        end

    end

endmodule