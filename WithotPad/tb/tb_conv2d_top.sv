`timescale 1ns / 1ps

module tb_conv2d_top;

    parameter WIDTH = 8;
    parameter SIZE = 3;
    parameter PictureWidth = 5;  
    parameter PictureHeight = 5;

    logic clk;
    logic rst;
    logic enable;

    logic [WIDTH-1:0] pixel_in;
    logic kernelEnable;
    logic [1:0] kernelType;

    logic ready;
    logic [WIDTH-1:0] pixel_out;
    integer count;

    conv2d_top #(
        .WIDTH(WIDTH),
        .SIZE(SIZE),
        .PictureWidth(PictureWidth)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .tvalid(enable),
        .pixel_in(pixel_in),
        .kernelEnable(kernelEnable),
        .kernelType(kernelType),
        .ready(ready),
        .pixel_out(pixel_out)
    );

    always #5 clk = ~clk;

    logic [WIDTH-1:0] image [0:PictureHeight-1][0:PictureWidth-1];

    initial begin
        clk = 0;
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
        kernelEnable = 1;
        kernelType = 1;
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
        @(posedge clk);@(posedge clk);@(posedge clk);        
        $finish;
    end

endmodule