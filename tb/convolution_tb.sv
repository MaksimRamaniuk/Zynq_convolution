`timescale 1ns / 1ps

module convolution_tb;

    parameter WIDTH = 8;
    parameter SIZE  = 3;

    logic clk;
    logic rst;
    logic enable;
    logic ready;
    logic [WIDTH-1:0] OutData;

    logic [WIDTH-1:0] InData [0:SIZE-1][0:SIZE-1];
    logic [WIDTH-1:0] kernel [0:SIZE-1][0:SIZE-1];

    // Instantiate DUT
    convolution #(
        .WIDTH(WIDTH),
        .SIZE(SIZE)
    ) uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .InData(InData),
        .kernel(kernel),
        .ready(ready),
        .OutData(OutData)
    );

    // Clock generation
    always #5 clk = ~clk;   // 100 MHz

    initial begin
        clk = 0;
        rst = 1;
        enable = 0;

        #20;
        rst = 0;

        // =========================
        // Test 1: Simple values
        // =========================

        InData[0][0] = 1;  InData[0][1] = 2;  InData[0][2] = 3;
        InData[1][0] = 4;  InData[1][1] = 5;  InData[1][2] = 6;
        InData[2][0] = 7;  InData[2][1] = 8;  InData[2][2] = 9;

        kernel[0][0] = 1;  kernel[0][1] = 0;  kernel[0][2] = 1;
        kernel[1][0] = 0;  kernel[1][1] = 1;  kernel[1][2] = 0;
        kernel[2][0] = 1;  kernel[2][1] = 0;  kernel[2][2] = 1;

        #20;
        enable = 1;
        #20;
        enable = 0;

        wait(ready);

        $display("Test1 Result = %d", OutData);

        #20;

        // =========================
        // Test 2: All ones
        // =========================

        for (int i = 0; i < SIZE; i++) begin
            for (int j = 0; j < SIZE; j++) begin
                InData[i][j] = 1;
                kernel[i][j] = 1;
            end
        end

        #10;
        enable = 1;
        #10;
        enable = 0;

        wait(ready);

        $display("Test2 Result = %d", OutData);

        #20;

        $finish;
    end

endmodule