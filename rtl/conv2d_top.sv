`timescale 1ns / 1ps

module conv2d_top #(
    parameter CHANELS = 3,
    parameter WIDTH = 8,
    parameter SIZE = 3,
    parameter PictureWidth = 1280,      //1920
    parameter PictureHeight = 720       //1080
)(
    input logic clk,
    input logic rst,
    input logic tvalid,

    input logic [CHANELS*WIDTH-1:0] pixel_in,
    input kernelEnable,
    input logic [1:0] kernelType,

    output logic ready,
    output logic [CHANELS*WIDTH-1:0] pixel_out,
    output logic tready,
    output logic tlast
);
    logic [WIDTH-1:0] kernel [0:SIZE-1][0:SIZE-1];
    logic [WIDTH-1:0] divider;
    
    logic [WIDTH-1:0] convOut [0:CHANELS-1];
    
    localparam PAD = (SIZE-1)/2;
    localparam WARMUP = PictureWidth*PAD + (SIZE-1);
    
    logic [CHANELS*WIDTH-1:0] window [0:SIZE-1][0:SIZE-1];
    logic [CHANELS*WIDTH-1:0] line_buffer [0:SIZE-2];
    logic [CHANELS*WIDTH-1:0] windowIn;
    logic enable;
    logic padding;
    logic paddingEnd;
    logic endOfFrame;
    logic reset;
    logic convReady;
    
    logic [10:0] col_cnt, row_cnt, end_cnt, ready_cnt;
    logic [1:0] pad_cnt;
    logic conv_enable;

    logic warmup_done;
    
    assign enable = tvalid || padding || paddingEnd;
    assign reset = !rst || endOfFrame;
    assign ready = convReady;
    assign tlast = (ready_cnt == PictureHeight);
    
    KernelComponent #(
        .WIDTH(WIDTH),
        .SIZE(SIZE)
    ) core (
        .clk(clk),
        .ReadEnable(kernelEnable),
        .kernelType(kernelType),
        .kernel(kernel),
        .divider(divider)
    );

    genvar j;
    generate
        for (j = 0; j < SIZE-1; j++) begin : fifo
            line_bufer #(
                .WIDTH(CHANELS*WIDTH),
                .PictureWidth(PictureWidth - 1)
            ) buffer (
                .clk(clk),
                .rst(reset),
                .enable(enable),
                .pixel_in(window[j][SIZE-1]),
                .pixel_out(line_buffer[j])
            );
        end
    endgenerate

    always_comb begin
        if (tvalid) 
            windowIn <= pixel_in;
        else 
            windowIn <= '0;
    end
    
   always_comb begin
        if (convReady) 
            ready_cnt++;
        else 
            ready_cnt <= 0;
    end
    
    always_ff @(posedge clk) begin
        if(end_cnt == WARMUP)
            endOfFrame <= 1;
        else
            endOfFrame <= 0;
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            paddingEnd = 0;
            end_cnt = 0;
        end else if(paddingEnd)
            end_cnt++;
        else if (row_cnt == PictureHeight && col_cnt == 0)
            paddingEnd = 1;
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            pad_cnt <= 0;
            padding <= 1;
        end
        else begin
            if (paddingEnd)
                if(end_cnt < SIZE && end_cnt > PAD-1)
                    padding <= 0;
                else
                    padding <= 1;
            else begin
                if (col_cnt == PictureWidth-1) begin
                    padding <= 1;
                    pad_cnt <= 0; 
                end
                else if (padding) begin
                    if (pad_cnt == PAD) begin
                        padding <= 0;
                        pad_cnt <= 0;
                    end
                    else
                        pad_cnt++;
                end
            end
        end
    end
    
    assign tready = !padding && !paddingEnd;
    
    always_ff @(posedge clk) begin
        if (enable) begin
            for (int i = 0; i < SIZE; i++)
                for (int j = SIZE-1; j > 0; j--)
                    window[i][j] <= window[i][j-1];

            for (int i = 1; i < SIZE; i++)
                window[i][0] <= line_buffer[i-1];

            window[0][0] <= windowIn;
            
            if(!warmup_done)
                window[1][SIZE-1] <= '0;
             
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            warmup_done <= 0;
        end
        else if (row_cnt == PAD && col_cnt == PAD) begin
            warmup_done <= 1;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            col_cnt <= 0;
            row_cnt <= 0;
        end else if (tvalid) begin
            if (col_cnt == PictureWidth-1) begin
                col_cnt <= 0;
                row_cnt++;
            end else
                col_cnt <= col_cnt + 1;
        end
    end

    always_comb begin
        if (warmup_done && ((col_cnt > PAD) || padding))
            conv_enable <= 1;
        else
            conv_enable <= 0; 
    end

    generate
        for (j = 0; j < CHANELS; j++) begin : convol
            convolution #(
                .WIDTH(WIDTH),
                .SIZE(SIZE)
            ) conv (
                .clk(clk),
                .rst(reset),
                .enable(conv_enable),
                .InData(window),
                .kernel(kernel),
                .divider(divider),
                .ready(convReady),
                .OutData(convOut[j])
            );
        end
    endgenerate
    
    always_comb begin
        if (convReady) begin
            for (int i = 0; i < CHANELS; i++)
                pixel_out[i*WIDTH +: WIDTH] = convOut[i];
        end
    end

endmodule