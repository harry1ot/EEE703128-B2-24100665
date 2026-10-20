module j04_display_core_tb;
    logic clk=0,rst_n=0,enable=0,blank_leading_zero=0;
    logic [7:0] brightness;
    logic [15:0] bcd_digits;
    logic [6:0] seg;
    logic [1:0] digit_sel;
    logic display_active;

    j04_display_core dut(
        .clk(clk),.rst_n(rst_n),.enable(enable),
        .blank_leading_zero(blank_leading_zero),
        .brightness(brightness),.bcd_digits(bcd_digits),
        .seg(seg),.digit_sel(digit_sel),
        .display_active(display_active)
    );

    always #5 clk=~clk;

    initial begin
        brightness=8'hFF;
        bcd_digits=16'h1234;
        repeat(3) @(posedge clk);
        rst_n=1; enable=1;

        // Four different digits.
        repeat(1024) @(posedge clk);

        // Leading-zero case.
        bcd_digits=16'h0042;
        blank_leading_zero=1;
        repeat(1024) @(posedge clk);

        // Brightness change.
        brightness=8'h40;
        repeat(1024) @(posedge clk);

        // Boundary: 0000.
        bcd_digits=16'h0000;
        repeat(1024) @(posedge clk);

        $display("J04 RTL testbench completed");
        $finish;
    end
endmodule
