`timescale 1ns / 1ps

module fifo_buffer #(
    parameter WIDTH = 8,
    parameter SIZE = 3,
    parameter PictureWidth = 1280
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,
    input  logic padding,

    input  logic [WIDTH-1:0] pixel_in,
    input  logic [WIDTH-1:0] array_in[0:SIZE-1],

    output logic [WIDTH-1:0] pixel_out,
    output logic [WIDTH-1:0] array_out[0:SIZE-1]
);

    logic [WIDTH-1:0] mem [0:PictureWidth-1];
    int address;

    assign pixel_out = mem[address];

    always_ff @(posedge clk) begin
        if (!rst) begin
            for (int i = 0; i < PictureWidth; i++)
                mem[i] <= '0;

            address <= 0;
        end
        else if (enable) begin
            int addr;
            addr = address;

            mem[addr] <= pixel_in;

            if (padding) begin
                for (int i = SIZE-1; i >= 0; i--) begin
                    mem[addr] <= array_in[i];

                    if (addr == PictureWidth-1)
                        addr = 0;
                    else
                        addr++;
                end
            end
            else begin
                if (addr == PictureWidth-1)
                    addr = 0;
                else
                    addr++;
            end

            address <= addr;
        end
    end
    
    always_comb begin
        int addr;
        addr = address;
        if (padding) begin
            for (int i = SIZE-1; i >= 0; i--) begin
                array_out[i] = mem[addr];
    
                if (addr == PictureWidth-1)
                    addr = 0;
                else
                    addr++;
            end
        end
    end
endmodule