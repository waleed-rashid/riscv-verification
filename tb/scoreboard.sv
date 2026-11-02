`timescale 1ns/1ps

module scoreboard (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] pc,
    input  logic [4:0]  rd,
    input  logic [31:0] writeback_data,
    input  logic        reg_write,
    input  logic [31:0] x0_value,
    output logic        done,
    output logic        passed
);

    logic        expected_write [0:9];
    logic [4:0]  expected_rd    [0:9];
    logic [31:0] expected_data  [0:9];
    integer      checks;
    integer      failures;
    integer      index;
    integer      i;

    initial begin
        for (i = 0; i < 10; i = i + 1) begin
            expected_write[i] = 1'b0;
            expected_rd[i] = 5'd0;
            expected_data[i] = 32'd0;
        end

        expected_write[0] = 1'b1; expected_rd[0] = 5'd1; expected_data[0] = 32'd10;
        expected_write[1] = 1'b1; expected_rd[1] = 5'd2; expected_data[1] = 32'd20;
        expected_write[2] = 1'b1; expected_rd[2] = 5'd3; expected_data[2] = 32'd30;
        expected_write[3] = 1'b1; expected_rd[3] = 5'd4; expected_data[3] = 32'd20;
        expected_write[4] = 1'b1; expected_rd[4] = 5'd5; expected_data[4] = 32'd0;
        expected_write[5] = 1'b1; expected_rd[5] = 5'd6; expected_data[5] = 32'd30;
        expected_write[6] = 1'b1; expected_rd[6] = 5'd7; expected_data[6] = 32'd30;
        expected_write[7] = 1'b1; expected_rd[7] = 5'd8; expected_data[7] = 32'd123;

        checks = 0;
        failures = 0;
        done = 1'b0;
        passed = 1'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            checks = 0;
        end
        else if (!done) begin
            index = pc >> 2;

            if (pc !== (checks * 32'd4)) begin
                $display("SCOREBOARD ERROR: PC expected=%08h got=%08h",
                         checks * 32'd4, pc);
                failures = failures + 1;
            end

            if (index < 0 || index > 9) begin
                $display("SCOREBOARD ERROR: unexpected PC %08h", pc);
                failures = failures + 1;
            end
            else begin
                if (reg_write !== expected_write[index]) begin
                    $display("SCOREBOARD ERROR: pc=%08h reg_write expected=%b got=%b",
                             pc, expected_write[index], reg_write);
                    failures = failures + 1;
                end

                if (expected_write[index] &&
                    ((rd !== expected_rd[index]) ||
                     (writeback_data !== expected_data[index]))) begin
                    $display("SCOREBOARD ERROR: pc=%08h write expected x%0d=%08h got x%0d=%08h",
                             pc, expected_rd[index], expected_data[index],
                             rd, writeback_data);
                    failures = failures + 1;
                end
            end

            if (x0_value !== 32'd0) begin
                $display("SCOREBOARD ERROR: x0 changed to %08h", x0_value);
                failures = failures + 1;
            end

            checks = checks + 1;
            if (checks == 10) begin
                done = 1'b1;
                passed = (failures == 0);
                if (passed)
                    $display("SCOREBOARD: PASS (%0d checks)", checks);
                else
                    $display("SCOREBOARD: FAIL (%0d failures)", failures);
            end
        end
    end

endmodule
