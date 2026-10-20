module j04_display_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic        blank_leading_zero,
    input  logic [7:0]  brightness,
    input  logic [15:0] bcd_digits,
    output logic [6:0]  seg,
    output logic [1:0]  digit_sel,
    output logic        display_active
);

    logic [9:0] phase;
    logic [3:0] selected_bcd;
    logic [6:0] seg_raw;

    assign digit_sel = phase[9:8];
    assign display_active = enable && (brightness != 8'h00);

    function automatic [3:0] get_digit(
        input logic [15:0] b,
        input logic [1:0] i
    );
        case (i)
            2'd0: get_digit = b[3:0];
            2'd1: get_digit = b[7:4];
            2'd2: get_digit = b[11:8];
            default: get_digit = b[15:12];
        endcase
    endfunction

    function automatic [3:0] selected_with_blank(
        input logic [15:0] b,
        input logic [1:0] i,
        input logic blank_en
    );
        logic [3:0] d3,d2,d1,d0;
        begin
            d3=b[15:12]; d2=b[11:8]; d1=b[7:4]; d0=b[3:0];
            if (!blank_en)
                selected_with_blank = get_digit(b,i);
            else case(i)
                2'd3: selected_with_blank = (d3==0) ? 4'hF : d3;
                2'd2: selected_with_blank = (d3==0 && d2==0) ? 4'hF : d2;
                2'd1: selected_with_blank = (d3==0 && d2==0 && d1==0) ? 4'hF : d1;
                default: selected_with_blank = d0;
            endcase
        end
    endfunction

    function automatic [6:0] decode7(input logic [3:0] d);
        case(d)
            4'd0: decode7=7'b1111110;
            4'd1: decode7=7'b0110000;
            4'd2: decode7=7'b1101101;
            4'd3: decode7=7'b1111001;
            4'd4: decode7=7'b0110011;
            4'd5: decode7=7'b1011011;
            4'd6: decode7=7'b1011111;
            4'd7: decode7=7'b1110000;
            4'd8: decode7=7'b1111111;
            4'd9: decode7=7'b1111011;
            default: decode7=7'b0000000;
        endcase
    endfunction

    always_comb begin
        selected_bcd = selected_with_blank(
            bcd_digits, phase[9:8], blank_leading_zero
        );
        if (selected_bcd == 4'hF)
            seg_raw = 7'b0000000;
        else
            seg_raw = decode7(selected_bcd);

        if (display_active && (phase[7:0] < brightness))
            seg = seg_raw;
        else
            seg = 7'b0000000;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            phase <= 10'd0;
        else if (!enable)
            phase <= 10'd0;
        else
            phase <= phase + 10'd1;
    end
endmodule
