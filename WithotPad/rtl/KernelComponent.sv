module KernelComponent #(
    parameter WIDTH = 8,
    parameter SIZE = 3
)(
    input clk,
    input ReadEnable,
    input logic [1:0] kernelType,
    output logic [WIDTH-1:0] kernel [0:SIZE-1][0:SIZE-1],
    output logic [WIDTH-1:0] divider
    );
    
    always_ff @(posedge clk) begin
        if(ReadEnable) begin
            if (kernelType == 1) begin               // Gaussian blur
                kernel[2][0] = 1; kernel[2][1] = 2; kernel[2][2] = 1;
                kernel[1][0] = 2; kernel[1][1] = 4; kernel[1][2] = 2;
                kernel[0][0] = 1; kernel[0][1] = 2; kernel[0][2] = 1;
                divider = 16;
            end else if (kernelType == 2) begin      // Sharpening filter
                for (int r = 0; r < SIZE; r++)
                    for (int c = 0; c < SIZE; c++)
                        kernel[r][c] <= -1;
                kernel[(SIZE-1)/2][(SIZE-1)/2] <= 9;
                divider = 1;
            end else if (kernelType == 3) begin      // Laplacian filter
                kernel[2][0] = 0; kernel[2][1] = 1; kernel[2][2] = 0;
                kernel[1][0] = 1; kernel[1][1] = -4; kernel[1][2] = 1;
                kernel[0][0] = 0; kernel[0][1] = 1; kernel[0][2] = 0;
                divider = 1;
            end else begin                              // No filter 
                for (int r = 0; r < SIZE; r++)
                    for (int c = 0; c < SIZE; c++)
                        kernel[r][c] <= 0;
                kernel[(SIZE-1)/2][(SIZE-1)/2] <= 1;
                divider = 1;
            end
        end
    end
    
endmodule
