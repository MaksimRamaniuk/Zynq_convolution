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
    input integer divisior,

    output logic ready,
    output logic [WIDTH-1:0] pixel_out,
    output logic tlast
);
    
    logic [WIDTH-1:0] window [0:SIZE-1][0:SIZE-1];
    logic [WIDTH-1:0] line_buffer [0:SIZE-2];
    
    localparam PAD = (SIZE-1)/2;
    localparam WARMUP = PictureWidth*((SIZE-1)/2) + (SIZE-1);
    localparam FIFO_DEPTH = (PictureWidth - 1 > SIZE) ? (PictureWidth - 1) : SIZE;

    logic pad_done;
    logic warmup_done;
    logic conv_enable;
    logic fifo_enable;
    logic conv_ready;
    
    integer warmup_cnt;
    integer end_cnt;
    integer col_cnt, row_cnt;
    
    logic [WIDTH-1:0] window_in;
    logic [WIDTH-1:0] window_temp [0:SIZE-1];
    logic [WIDTH-1:0] line_temp [0:SIZE-2][0:SIZE-1];
    logic work;
    assign work = enable || warmup_done;
    
    always_ff @(posedge clk) begin
        window_in <= '0;
        if (work && warmup_cnt > 0) begin
            if ((col_cnt < PAD && row_cnt != 0) || (col_cnt >= PictureWidth-1)) begin
                for(int i = SIZE-1; i > 0; i--)
                    window_temp[i] <= window_temp[i-1];
                if(enable)
                    window_temp[0] <= pixel_in;
                else
                    window_temp[0] <= '0;
            end else if (end_cnt == 0) begin
                window_in <= pixel_in;
                for(int i = 0; i < SIZE; i++)
                    window_temp[i] <= '0;
            end               
        end
    end
    
    always_comb begin
        if (col_cnt == (SIZE-1)/2 && row_cnt != 0)
            pad_done <= 1;
        else 
            pad_done <= 0; 
    end
    
    always_ff @(posedge clk) begin
        if (pad_done && conv_ready) //col_cnt == ((SIZE-1)/2)
            tlast <= 1;
        else 
            tlast <= 0; 
    end
    
    always_ff @(posedge clk) begin
        if (warmup_cnt == 1 && enable) begin
            col_cnt <= 0;
            row_cnt <= 0;
        end else  begin
            if (col_cnt == PictureWidth-1) begin
                col_cnt <= 0;
                row_cnt++;
            end else
                col_cnt++;
        end
    end    
    
    genvar i;
    generate
        for (i = 0; i < SIZE-1; i++) begin : gen_fifo
            fifo_buffer #(
                .WIDTH(WIDTH),
                .SIZE(SIZE),
                .PictureWidth(FIFO_DEPTH)
            ) fifo_bufferi (
                .clk(clk),
                .rst(rst),
                .enable(fifo_enable),
                .padding(pad_done),
                .pixel_in(window[i][SIZE-1]),
                .array_in(window[i]),
                .pixel_out(line_buffer[i]),
                .array_out(line_temp[i])
            );
        end
    endgenerate

    always_ff @(posedge clk) begin
        if(!rst) begin
            for (int i = 0; i < SIZE; i++)
                for (int j = 0; j < SIZE; j++)
                    window[i][j] <= '0;
        end
        else begin
            if (!pad_done) begin
                for (int i = 0; i < SIZE; i++)
                    for (int j = SIZE-1; j > 0; j--)
                        window[i][j] <= window[i][j-1];
    
                for (int i = 1; i < SIZE; i++)
                    window[i][0] <= line_buffer[i-1];
    
                window[0][0] <= window_in;
            end else begin
                for (int i = 1; i < SIZE; i++)
                    window[i] <= line_temp[i-1];
                window[0] <= window_temp;
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (!rst) begin
            warmup_cnt <= 0;
            warmup_done <= 0;
            end_cnt <= 0;
        end
        else if (enable && !warmup_done) begin
            if (warmup_cnt == WARMUP - (PAD-1))
                warmup_done <= 1;
            else
                warmup_cnt++;
        end 
        else if(!enable && warmup_done) begin
            if(end_cnt == WARMUP-PAD) begin
                warmup_done <= 0;
            end else
                end_cnt++;
        end
    end
    
    always_ff @(posedge clk) begin
        if (warmup_done)
            conv_enable <= 1;
        else
            conv_enable <= 0;
    end
    
    always_ff @(posedge clk) begin
        if (work)
            fifo_enable <= 1;
        else
            fifo_enable <= 0;
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
        .ready(conv_ready),
        .OutData(pixel_out)
    );
    
    assign ready = conv_ready;
endmodule