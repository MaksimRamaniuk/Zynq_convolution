`timescale 1ns / 1ps

module line_bufer #(
    parameter WIDTH = 8,
    parameter PictureWidth = 1280
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,

    input  logic [WIDTH-1:0] pixel_in,
    output logic [WIDTH-1:0] pixel_out
);
    logic [WIDTH-1:0] mem [0:PictureWidth-1];
    integer wr_ptr;
    integer rd_ptr;

    assign pixel_out = mem[rd_ptr];
    
    always_ff @(posedge clk) begin
        if (!rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end
        else if (enable) begin

            mem[wr_ptr] <= pixel_in;

            if (wr_ptr == PictureWidth-1)
                wr_ptr <= 0;
            else
                wr_ptr <= wr_ptr + 1;

            if (rd_ptr == PictureWidth-1)
                rd_ptr <= 0;
            else
                rd_ptr <= rd_ptr + 1;
        end
    end
endmodule