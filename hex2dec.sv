`timescale 1 ns / 100 ps

module hex2dec (
    input start,
    input [15:0] hex_data,
    output reg [7:0] ascii_data,
    output reg valid,
    output reg ready,
    input clk,
    input rstn
);
    reg div10_start;
    wire div10_done;
    wire div10_idle, div10_ready;
    reg [31:0] div10_data_in;
    wire [31:0] div10_data_out;
    div10 div10_instance(
        .ap_clk(clk),
        .ap_rst(!rstn),
        .ap_start(div10_start),
        .ap_done(div10_done),
        .ap_idle(div10_idle),
        .ap_ready(div10_ready),
        .n(div10_data_in),
        .ap_return(div10_data_out)
    );

    reg mul10_start;
    reg [15:0] mul10_data_in;
    wire [31:0] mul10_data_out;
    wire mul10_ready;
    wire mul10_done;
    mul10 mul10_instance(
        .ap_clk(clk),
        .ap_rst(!rstn),
        .ap_ready(mul10_ready),
        .ap_start(mul10_start),
        .ap_done(mul10_done),
        .n(mul10_data_in),
        .ap_return(mul10_data_out)
    );

    localparam IDLE = 3'd0;
    localparam DIV_STATE_INIT = 3'd1;
    localparam DIV_STATE_WAIT = 3'd2;
    localparam MUL10_STATE_INIT = 3'd3;
    localparam MUL10_STATE_WAIT = 3'd4;
    localparam CALC_COMPLETE = 3'd5;

    logic [2:0] h2d_state;
    logic [15:0] temp16;
    logic [2:0] div_count;
    logic [7:0] ascii_buf [0:4];
    logic [7:0]substraction;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            h2d_state <= IDLE;
            ready <= 1'b0;
            div10_start <= 1'b0;
            mul10_start <= 1'b0;
            ascii_buf[0] = 8'h00;
            ascii_buf[1] = 8'h00;
            ascii_buf[2] = 8'h00;
            ascii_buf[3] = 8'h00;
            ascii_buf[4] = 8'h00;
        end else begin
            case (h2d_state)
                IDLE : begin
                    if(start) begin
                        temp16 <= hex_data;
                        h2d_state <= DIV_STATE_INIT;
                        div_count <= 0;
                        ready <= 1'b0;
                    end else
                        ready <= 1'b1;
                end
                DIV_STATE_INIT: begin
                    if(div10_idle) begin
                        div10_data_in <= {16'h00000, temp16};
                        div10_start <= 1'b1;
                        h2d_state <= DIV_STATE_WAIT;
                    end
                end
                DIV_STATE_WAIT: begin
                    if(div10_done)begin
                        div10_start <= 1'b0;
                        h2d_state <= MUL10_STATE_INIT;
                        mul10_data_in <= div10_data_out;
                    end
                end
                MUL10_STATE_INIT : begin
                    if(mul10_ready) begin
                        mul10_start <= 1'b1;
                        h2d_state <= MUL10_STATE_WAIT;
                    end
                end
                MUL10_STATE_WAIT : begin
                    if(mul10_done) begin
                        mul10_start <= 1'b0;
                        ascii_buf[div_count] <= (temp16 - mul10_data_out) + 8'h30;
                        substraction <= temp16 - mul10_data_out;
                        div_count <= div_count + 1'b1;
                        temp16 <= div10_data_out;
                        h2d_state <= div_count >= 4 ? CALC_COMPLETE : DIV_STATE_INIT;
                    end
                end
                CALC_COMPLETE : begin
                    if(div_count > 0)
                        div_count <= div_count - 1'b1;
                    else begin
                        h2d_state <= IDLE;
                        ready <= 1'b1;
                    end
                end
            endcase
        end
    end

    always @(negedge clk)
        if(h2d_state == CALC_COMPLETE) begin
            valid <= (div_count > 0) ? 1'b1 : 1'b0;
            ascii_data <= ascii_buf[div_count-1'b1];
        end else begin
            valid <= 1'b0;
        end

endmodule : hex2dec
