module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  alu_control,
    output logic [31:0] result
);

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;

    always @(*) begin
        case (alu_control)

            ALU_ADD:
                result = a + b;

            ALU_SUB:
                result = a - b;

            ALU_AND:
                result = a & b;

            ALU_OR:
                result = a | b;

            ALU_XOR:
                result = a ^ b;

            default:
                result = 32'b0;

        endcase
    end

endmodule