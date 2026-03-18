`timescale 1ns / 1ps

module conv2d_top #(
    parameter WIDTH = 8,
    parameter SIZE = 3,
    parameter PictureWidth = 1280
)(
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [WIDTH-1:0] pixel_in,
    input logic [WIDTH-1:0] kernel [0:SIZE-1][0:SIZE-1],
    input logic [WIDTH-1:0] divisior,

    output logic ready,
    output logic [WIDTH-1:0] pixel_out
);

    logic [WIDTH-1:0] shift_reg [0:SIZE-1][0:SIZE-1];
    logic [WIDTH-1:0] window [0:SIZE-1][0:SIZE-1];
    logic [WIDTH-1:0] line_buffer [0:SIZE-2];

    genvar i;
    generate
        for (i = 0; i < SIZE-1; i++) begin : fifo
            line_bufer #(
                .WIDTH(WIDTH),
                .PictureWidth(PictureWidth - SIZE)
            ) buffer (
                .clk(clk),
                .rst(rst),
                .enable(enable),
                .pixel_in(shift_reg[i][SIZE-1]),
                .pixel_out(line_buffer[i])
            );
        end
    endgenerate

    always_ff @(posedge clk) begin
        if(!rst) begin
            for (int i = 0; i < SIZE; i++)
                for (int j = 0; j < SIZE; j++)
                    shift_reg[i][j] <= 'dx;
        end
        else if (enable) begin

            for (int i = 0; i < SIZE; i++)
                for (int j = SIZE-1; j > 0; j--)
                    shift_reg[i][j] <= shift_reg[i][j-1];

            for (int i = 1; i < SIZE; i++)
                shift_reg[i][0] <= line_buffer[i-1];

            shift_reg[0][0] <= pixel_in;

        end
    end

    assign window = shift_reg;

    localparam WARMUP = PictureWidth*(SIZE-1) + (SIZE-1);

    integer warmup_cnt;
    logic warmup_done;

    integer col_cnt;

    always_ff @(posedge clk) begin
        if (!rst) begin
            warmup_cnt <= 0;
            warmup_done <= 0;
        end
        else if (enable && !warmup_done) begin

            if (warmup_cnt == WARMUP) begin
                warmup_done <= 1;
            end
            else begin
                warmup_cnt <= warmup_cnt + 1;
            end

        end
    end

    always_ff @(posedge clk) begin
        if (!rst)
            col_cnt <= 0;

        else if (enable && warmup_done) begin

            if (col_cnt == PictureWidth-1)
                col_cnt <= 0;
            else
                col_cnt <= col_cnt + 1;

        end
    end

    logic conv_enable;
    always_ff @(posedge clk) begin
        if (warmup_done && (col_cnt < PictureWidth-(SIZE-1)))
            conv_enable <= 1;
        else
            conv_enable <= 0;
    end

    convolution #(
        .WIDTH(WIDTH),
        .SIZE(SIZE)
    ) CONV (
        .clk(clk),
        .rst(rst),
        .enable(conv_enable),
        .InData(window),
        .kernel(kernel),
        .divisior(divisior),
        .ready(ready),
        .OutData(pixel_out)
    );

endmodule