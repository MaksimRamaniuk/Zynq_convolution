`timescale 1ns / 1ps

module tb_conv2d_top;

    parameter WIDTH = 8;
    parameter SIZE = 3;
    parameter PictureWidth = 4;  
    parameter PictureHeight = 4;

    logic clk;
    logic rst;
    logic enable;

    logic [WIDTH-1:0] pixel_in;
    logic [WIDTH-1:0] kernel [0:SIZE-1][0:SIZE-1];

    logic ready;
    logic [WIDTH-1:0] pixel_out;
    integer count;
    integer divisior;

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
        .pixel_out(pixel_out)
    );

    always #5 clk = ~clk;

    // Инизиализация ядра свёртки
    initial begin
//        kernel[2][0] = 0; kernel[2][1] = 0; kernel[2][2] = 0;
//        kernel[1][0] = 0; kernel[1][1] = 1; kernel[1][2] = 0;
//        kernel[0][0] = 0; kernel[0][1] = 0; kernel[0][2] = 0;
        for (int r = 0; r < PictureHeight; r++)
            for (int c = 0; c < PictureWidth; c++)
                kernel[r][c] <= '0;
        kernel[(SIZE-1)/2][(SIZE-1)/2] <= 1;
        divisior = 1;
    end

    logic [WIDTH-1:0] image [0:PictureHeight-1][0:PictureWidth-1];

    initial begin
        clk = 0;
        rst = 1;
        enable = 0;
        count = 1;
        for (int r = 0; r < PictureHeight; r++) begin
            for (int c = 0; c < PictureWidth; c++) begin
                image[r][c] = count;
                count++;
            end
        end

        #20;
        rst = 0;
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
        for (int r = 0; r < SIZE-1; r++) 
            for (int c = 0; c < PictureWidth; c++)
                @(posedge clk);       
        $finish;
    end

endmodule