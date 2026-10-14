`default_nettype none
`timescale 1ns / 1ps

module tt_um_eee703128_24100665 #(
    parameter integer CLK_HZ = 1000000,
    parameter integer DIGIT_HZ = 100
) (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Two rising load_strobe edges load one four-digit BCD frame.
    // The first byte contains digits 3:2, and the second contains digits 1:0.
    localparam integer RAW_SCAN_DIV = CLK_HZ / (DIGIT_HZ * 4);
    localparam integer SCAN_DIV = (RAW_SCAN_DIV < 1) ? 1 : RAW_SCAN_DIV;
    localparam integer SCAN_COUNTER_WIDTH =
        (SCAN_DIV <= 1) ? 1 : $clog2(SCAN_DIV);

    reg [3:0] digit3;
    reg [3:0] digit2;
    reg [3:0] digit1;
    reg [3:0] digit0;
    reg [3:0] pending_digit3;
    reg [3:0] pending_digit2;
    reg       expect_second_pair;
    reg       load_strobe_d;

    reg [SCAN_COUNTER_WIDTH-1:0] scan_counter;
    reg [1:0] scan_index;
    reg [2:0] pwm_counter;

    reg [3:0] selected_digit;
    reg [6:0] segments_n;
    reg [3:0] digit_enable_n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit3             <= 4'd0;
            digit2             <= 4'd0;
            digit1             <= 4'd0;
            digit0             <= 4'd0;
            pending_digit3     <= 4'd0;
            pending_digit2     <= 4'd0;
            expect_second_pair <= 1'b0;
            load_strobe_d      <= 1'b0;
            scan_counter       <= {SCAN_COUNTER_WIDTH{1'b0}};
            scan_index         <= 2'd0;
            pwm_counter        <= 3'd0;
        end else begin
            load_strobe_d <= uio_in[3];

            if (ena && uio_in[3] && !load_strobe_d) begin
                if (!expect_second_pair) begin
                    pending_digit3     <= ui_in[7:4];
                    pending_digit2     <= ui_in[3:0];
                    expect_second_pair <= 1'b1;
                end else begin
                    digit3             <= pending_digit3;
                    digit2             <= pending_digit2;
                    digit1             <= ui_in[7:4];
                    digit0             <= ui_in[3:0];
                    expect_second_pair <= 1'b0;
                end
            end

            if (ena) begin
                pwm_counter <= pwm_counter + 1'b1;

                if (scan_counter == SCAN_DIV - 1) begin
                    scan_counter <= {SCAN_COUNTER_WIDTH{1'b0}};
                    scan_index   <= scan_index + 1'b1;
                end else begin
                    scan_counter <= scan_counter + 1'b1;
                end
            end
        end
    end

    always @* begin
        case (scan_index)
            2'd0: selected_digit = digit0;
            2'd1: selected_digit = digit1;
            2'd2: selected_digit = digit2;
            default: selected_digit = digit3;
        endcase

        // Active-low segments, ordered a,b,c,d,e,f,g. Invalid BCD is blank.
        case (selected_digit)
            4'd0:    segments_n = 7'b0000001;
            4'd1:    segments_n = 7'b1001111;
            4'd2:    segments_n = 7'b0010010;
            4'd3:    segments_n = 7'b0000110;
            4'd4:    segments_n = 7'b1001100;
            4'd5:    segments_n = 7'b0100100;
            4'd6:    segments_n = 7'b0100000;
            4'd7:    segments_n = 7'b0001111;
            4'd8:    segments_n = 7'b0000000;
            4'd9:    segments_n = 7'b0000100;
            default: segments_n = 7'b1111111;
        endcase

        // Active-low digit selects. uio_out[4] selects digit 0.
        digit_enable_n = ~(4'b0001 << scan_index);
        if (!ena || !rst_n || (pwm_counter >= uio_in[2:0]))
            digit_enable_n = 4'b1111;
    end

    assign uo_out  = {1'b0, (!ena || !rst_n) ? 7'b1111111 : segments_n};
    assign uio_out = {digit_enable_n, 4'b0000};
    assign uio_oe  = 8'b11110000;

endmodule

`default_nettype wire
