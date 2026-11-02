module decoder (
    input logic [31:0] instruction,

    output logic        reg_write,
    output logic        alu_src,
    output logic [2:0]  alu_control,

    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,

    output logic [31:0] immediate
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;


    // Extract instruction fields
    always @(*) begin

        opcode = instruction[6:0];
        funct3 = instruction[14:12];
        funct7 = instruction[31:25];

        rs1 = instruction[19:15];
        rs2 = instruction[24:20];
        rd  = instruction[11:7];

        // Default values
        reg_write = 1'b0;
        alu_src = 1'b0;
        alu_control = 3'b000;
        immediate = 32'b0;


        case (opcode)

            // -------------------------
            // R-TYPE
            // -------------------------

            7'b0110011: begin

                alu_src = 1'b0;

                // Only the exact supported R-type encodings are valid.
                // Keeping reg_write deasserted until a match prevents
                // unsupported encodings from being treated as ADD.
                case ({funct7, funct3})

                    {7'b0000000, 3'b000}: begin
                        reg_write = 1'b1;
                        alu_control = 3'b000; // ADD
                    end

                    {7'b0100000, 3'b000}: begin
                        reg_write = 1'b1;
                        alu_control = 3'b001; // SUB
                    end

                    {7'b0000000, 3'b111}: begin
                        reg_write = 1'b1;
                        alu_control = 3'b010; // AND
                    end

                    {7'b0000000, 3'b110}: begin
                        reg_write = 1'b1;
                        alu_control = 3'b011; // OR
                    end

                    {7'b0000000, 3'b100}: begin
                        reg_write = 1'b1;
                        alu_control = 3'b100; // XOR
                    end

                    default: begin
                        reg_write = 1'b0;
                        alu_control = 3'b000;
                    end

                endcase

            end


            // -------------------------
            // ADDI
            // -------------------------

            7'b0010011: begin

                // ADDI is the only supported I-type operation. Check funct3
                // explicitly so other I-type instructions do not write back.
                if (funct3 == 3'b000) begin
                    reg_write = 1'b1;
                    alu_src = 1'b1;
                    alu_control = 3'b000; // ADD

                    // Sign extend 12-bit immediate
                    immediate = {{20{instruction[31]}},
                                 instruction[31:20]};
                end

            end


            // -------------------------
            // DEFAULT
            // -------------------------

            default: begin

                reg_write = 1'b0;
                alu_src = 1'b0;
                alu_control = 3'b000;
                immediate = 32'b0;

            end

        endcase

    end

endmodule
