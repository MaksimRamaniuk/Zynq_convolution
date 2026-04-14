`timescale 1ns / 1ps

module convolution #(
    parameter WIDTH = 8,
    parameter SIZE  = 3
)(
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [WIDTH-1:0] InData [0:SIZE-1][0:SIZE-1],
    input logic [WIDTH-1:0] kernel [0:SIZE-1][0:SIZE-1],
    input logic [WIDTH-1:0] divider,

    output logic ready,
    output logic [WIDTH-1:0] OutData
);

    logic [2*WIDTH-1:0] sum;
    logic [2*WIDTH-1:0] product;

    always_ff @(posedge clk) begin
        if (rst) begin
            OutData <= 0;
            ready <= 0;
        end
        else begin
            ready <= 0;

            if (enable) begin
                sum = 0;

                for (int i = 0; i < SIZE; i++) begin
                    for (int j = 0; j < SIZE; j++) begin
                        product = InData[i][j] * kernel[i][j];
                        sum += product;
                    end
                end
                sum /= divider;
                
                if (sum > ((1 << WIDTH) - 1))
                    OutData <= sum - ((1 << WIDTH)-1);
                else
                    OutData <= sum[WIDTH-1:0];
                    
                ready <= 1;
            end
        end
    end

endmodule