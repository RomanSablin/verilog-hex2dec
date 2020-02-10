#!/bin/sh
iverilog -Wall -g2012 -o hex2dec div10.v hex2dec.sv mul10.sv hex2dec_tb.sv
vvp hex2dec
gtkwave hex2dec.vcd

