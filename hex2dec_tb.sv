`timescale 1 ns / 100 ps

module hex2dec_tb();

    reg start;
    reg [15:0] hex_data;
    wire [7:0]ascii_data;
    wire ascii_clk;
    wire ready, valid;
    reg clk, rstn;

    hex2dec hex2dec_instance(
        .start(start),
        .hex_data(hex_data),
        .ascii_data(ascii_data),
        .valid(valid),
        .ready(ready),
        .clk(clk),
        .rstn(rstn)
    );

    logic[15:0] hex_test_data[0:3];

    initial begin
        hex_test_data[0] = 65432;
        hex_test_data[1] = 123;
        hex_test_data[2] = 1889;
        hex_test_data[3] = 24;
        clk = 0;
        rstn = 0;
        start = 0;
        hex_data = 0;
        #1000 rstn = 1;
        $display("Run simulation");
        #100000;
        $display("Stop simulation");
        $finish();
    end

    always #10 clk <= !clk;
    int count = 0;
    always @(posedge clk) begin
        if(rstn) begin
            if(start == 0 && ready) begin
                hex_data = hex_test_data[count++];
                start = 1;
                if(count > 4)
                    $finish();
            end else if(valid) begin
                $display("%c", ascii_data);
            end
        end else begin
            count = 0;
        end
    end

    always @(negedge valid) start = 0;


    //create a VCD file for GTK wave
    initial
        begin
            $dumpfile("hex2dec.vcd");
            $dumpvars(0,hex2dec_tb);
        end

//    initial
//        $monitor($stime,, rstn,, clk,,, start,, hex_data,, ascii_clk,, ascii_data);

endmodule : hex2dec_tb
