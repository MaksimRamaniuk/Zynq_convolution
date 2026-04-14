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
    logic tready;
    logic tlast;

    conv2d_top #(
        .CHANELS(1),
        .WIDTH(WIDTH),
        .SIZE(SIZE),
        .PictureWidth(PictureWidth),
        .PictureHeight(PictureHeight)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .tvalid(enable),
        .pixel_in(pixel_in),
        .kernelEnable(kernelEnable),
        .kernelType(kernelType),
        .ready(ready),
        .pixel_out(pixel_out),
        .tready(tready),
        .tlast(tlast)
    );

    always #5 clk = ~clk;

    logic [WIDTH-1:0] image [0:PictureHeight-1][0:PictureWidth-1];

    always_comb begin
        if(!rst) 
            enable = 0;
        else 
            enable = tready;  
    end
//    assign enable = tready;
    
    initial begin
        clk = 0;
        rst = 0;
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
        kernelType = 0;
        
        for (int r = 0; r < PictureHeight; r++) begin
            @(posedge clk);
            wait(enable);
            for (int c = 0; c < PictureWidth; c++) begin
                pixel_in <= image[r][c];
                @(posedge clk);
            end
        end
        
        @(posedge clk);
        pixel_in <= 'x;
        @(posedge clk);@(posedge clk);@(posedge clk); 
        @(posedge clk);@(posedge clk);@(posedge clk);
        @(posedge clk);@(posedge clk);@(posedge clk); 
        @(posedge clk);@(posedge clk);@(posedge clk); 
        $finish;
    end

endmodule