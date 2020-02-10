`timescale 1 ns / 100 ps

module mul10(
    input ap_clk,
    input ap_rst,
    input ap_start,
    output reg ap_ready,
    output reg ap_done,
    input [15:0] n,
    output reg [31:0] ap_return
);

    logic [19:0] mul8;
    logic [16:0] mul2;

    logic [1:0]mul_state;

    always @(posedge ap_clk or posedge ap_rst)
        if(ap_rst) begin
            ap_ready <= 1'b0;
            ap_return <= 32'h00000000;
            mul_state <= 2'b00;
            ap_done <= 1'b0;
        end else begin
            case (mul_state)
                2'b00 : begin
                    if(ap_start) begin
                        ap_ready <= 1'b0;
                        mul8 <= n*8;
                        mul2 <= n*2;
                        mul_state <= 2'b01;
                    end else
                        ap_ready <= 1'b1;
                end
                2'b01 : begin
                    ap_return <= mul8 + mul2;
                    mul_state <= 2'b10;
                end
                2'b10, 2'b11 : begin
                    if(ap_start == 0) begin
                        mul_state <= 2'b00;
                        ap_done <= 1'b0;
                    end else
                        ap_done <= 1'b1;
                end
            endcase
        end
endmodule
