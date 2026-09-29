module cpu (
    input logic clk,
    input logic reset
);

    // Program Counter
    logic [31:0] pc;

    logic [31:0] next_pc;


    // Instruction Memory
    logic [31:0] instruction_memory [0:255];

    logic [31:0] instruction;


    // Decoder Signals
    logic        reg_write;
    logic        alu_src;

    logic [2:0]  alu_control;

    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;

    logic [31:0] immediate;


    // Register File Signals
    logic [31:0] register_data1;
    logic [31:0] register_data2;



    // ALU Signals
    logic [31:0] alu_input_b;
    logic [31:0] alu_result;


    // Writeback
    logic [31:0] writeback_data;


    // Instruction Fetch
    assign instruction = instruction_memory[pc >> 2];


    // PC
    assign next_pc = pc + 32'd4;


    always @(posedge clk) begin

        if (reset)
            pc <= 32'b0;

        else
            pc <= next_pc;

    end


    // Decoder
    decoder decoder_unit (

        .instruction(instruction),

        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_control(alu_control),

        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),

        .immediate(immediate)

    );


    // Register File
    register_file register_file_unit (

        .clk(clk),
        .reset(reset),

        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),

        .write_data(writeback_data),
        .reg_write(reg_write),

        .read_data1(register_data1),
        .read_data2(register_data2)

    );


    // ALU Input Mux
    assign alu_input_b =
        alu_src ? immediate : register_data2;


    // ALU
    alu alu_unit (

        .a(register_data1),
        .b(alu_input_b),

        .alu_control(alu_control),

        .result(alu_result)

    );


    // Writeback
    assign writeback_data = alu_result;


    // Initialize instruction memory
    integer i;

    initial begin

        for (i = 0; i < 256; i = i + 1)
            instruction_memory[i] = 32'b0;

    end

endmodule