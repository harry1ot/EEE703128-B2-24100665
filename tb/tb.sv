`default_nettype none
`timescale 1ns / 1ps

module tb;
    reg  [7:0] ui_in;
    reg  [7:0] uio_in;
    reg        ena;
    reg        clk;
    reg        rst_n;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    integer failures;
    reg found;

    tt_um_eee703128_24100665 #(
        .CLK_HZ(40),
        .DIGIT_HZ(1)
    ) dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task load_pair;
        input [7:0] pair;
        begin
            @(negedge clk);
            ui_in = pair;
            uio_in[3] = 1'b0;
            @(negedge clk);
            uio_in[3] = 1'b1;
            @(negedge clk);
            uio_in[3] = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    task expect_digit;
        input [3:0] active_low_select;
        input [6:0] expected_segments;
        integer cycles;
        begin
            found = 1'b0;
            for (cycles = 0; cycles < 120; cycles = cycles + 1) begin
                @(negedge clk);
                if (uio_out[7:4] == active_low_select) begin
                    found = 1'b1;
                    if (uo_out[6:0] !== expected_segments) begin
                        failures = failures + 1;
                        $display("FAIL: select=%b segments=%b expected=%b",
                                 active_low_select, uo_out[6:0], expected_segments);
                    end
                end
            end
            if (!found) begin
                failures = failures + 1;
                $display("FAIL: digit select %b was never active", active_low_select);
            end
        end
    endtask

    initial begin
        ui_in = 8'd0;
        uio_in = 8'd7;  // Brightness 7/7; load strobe initially low.
        ena = 1'b1;
        rst_n = 1'b0;
        failures = 0;
        found = 1'b0;

        repeat (2) @(negedge clk);
        if (uio_oe !== 8'b11110000) begin
            failures = failures + 1;
            $display("FAIL: unexpected uio_oe=%b", uio_oe);
        end
        if (uio_out[7:4] !== 4'b1111) begin
            failures = failures + 1;
            $display("FAIL: digit outputs should be off during reset");
        end
        rst_n = 1'b1;

        // The first byte is staged; it must not partially update the display.
        load_pair(8'h12);
        repeat (20) @(negedge clk);
        if (uo_out[6:0] !== 7'b0000001) begin
            failures = failures + 1;
            $display("FAIL: display changed before the second pair arrived");
        end

        // A full frame is displayed right-to-left as 1, 2, 3, 4.
        load_pair(8'h34);
        expect_digit(4'b1110, 7'b1001100); // digit 0 = 4
        expect_digit(4'b1101, 7'b0000110); // digit 1 = 3
        expect_digit(4'b1011, 7'b0010010); // digit 2 = 2
        expect_digit(4'b0111, 7'b1001111); // digit 3 = 1

        // A BCD nibble outside 0..9 is blank, not an arbitrary glyph.
        load_pair(8'hA1);
        load_pair(8'hB2);
        expect_digit(4'b0111, 7'b1111111);

        // Holding the strobe high must not be mistaken for a second load.
        @(negedge clk);
        ui_in = 8'h56;
        uio_in[3] = 1'b0;
        @(negedge clk);
        uio_in[3] = 1'b1;
        @(negedge clk);
        ui_in = 8'h99;
        repeat (20) @(negedge clk);
        expect_digit(4'b1110, 7'b0010010); // Previous frame's digit 0 is still 2.
        uio_in[3] = 1'b0;

        // Brightness code zero disables all digit selects.
        uio_in[2:0] = 3'd0;
        repeat (20) @(negedge clk);
        if (uio_out[7:4] !== 4'b1111) begin
            failures = failures + 1;
            $display("FAIL: brightness zero did not blank the display");
        end

        if (failures == 0)
            $display("PASS: reset, two-pair loading, scan/decode, invalid BCD, brightness");
        else
            $display("FAIL: %0d test failure(s)", failures);
        $finish;
    end
endmodule

`default_nettype wire
