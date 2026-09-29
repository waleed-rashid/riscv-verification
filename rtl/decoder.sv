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

                reg_write = 1'b1;
                alu_src = 1'b0;

                case (funct3)

                    // ADD / SUB
                    3'b000: begin

                        if (funct7 == 7'b0000000)
                            alu_control = 3'b000; // ADD

                        else if (funct7 == 7'b0100000)
                            alu_control = 3'b001; // SUB

                        else
                            alu_control = 3'b000;

                    end

                    // XOR
                    3'b100:
                        alu_control = 3'b100;

                    // OR
                    3'b110:
                        alu_control = 3'b011;

                    // AND
                    3'b111:
                        alu_control = 3'b010;

                    default:
                        alu_control = 3'b000;

                endcase

            end


            // -------------------------
            // ADDI
            // -------------------------

            7'b0010011: begin

                reg_write = 1'b1;
                alu_src = 1'b1;

                // ADD
                alu_control = 3'b000;

                // Sign extend 12-bit immediate
                immediate = {{20{instruction[31]}},
                             instruction[31:20]};

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