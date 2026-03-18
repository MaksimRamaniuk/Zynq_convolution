`timescale 1ns / 1ps

module tb_conv2d_top;

    parameter WIDTH = 8;
    parameter SIZE = 3;
    parameter PictureWidth = 16;  
    parameter PictureHeight = 16;

    logic clk;
    logic rst;
    logic enable;

    logic [WIDTH-1:0] pixel_in;
    logic [WIDTH-1:0] kernel [0:SIZE-1][0:SIZE-1];

    logic ready;
    logic [WIDTH-1:0] pixel_out;
    integer count;
    integer divisior;
    logic tlast;

    conv2d_top #(
        .WIDTH(WIDTH),
        .SIZE(SIZE),
        .PictureWidth(PictureWidth)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .pixel_in(pixel_in),
        .kernel(kernel),
        .divisior(divisior),
        .ready(ready),
        .pixel_out(pixel_out),
        .tlast(tlast)
    );

    always #5 clk = ~clk;

    initial begin
        for (int r = 0; r < SIZE; r++)
            for (int c = 0; c < SIZE; c++)
                kernel[r][c] <= 0;
        kernel[(SIZE-1)/2][(SIZE-1)/2] <= 1;
        divisior = 1;
    end

    logic [WIDTH-1:0] image [0:PictureHeight-1][0:PictureWidth-1];

    initial begin
        clk = 0;rst = 1;#20;
        rst = 0;
        enable = 0;
        count = 1;
        for (int r = 0; r < PictureHeight; r++) begin
            for (int c = 0; c < PictureWidth; c++) begin
                image[r][c] = count;
                count++;
            end
        end

        #20;
        rst = 1;
        #25;
        enable = 1;

        for (int r = 0; r < PictureHeight; r++) begin
            for (int c = 0; c < PictureWidth; c++) begin
                @(posedge clk);
                pixel_in <= image[r][c];
            end
        end
        @(posedge clk);
        pixel_in <= 'x;
        enable <= 0;
        wait(!ready);
        @(posedge clk);@(posedge clk);       
        $finish;
    end

endmodule