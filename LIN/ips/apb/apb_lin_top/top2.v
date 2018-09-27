module top2 (clk,reset,data_in,data_out); 

input clk,reset; 
input [9:0] data_in; 
output [9:0] data_out; 



wire clk_out;
wire [9:0] data_byte_out;

assign data_out = data_byte_out;


clock_divider top0 (reset,clk, clk_out);
 Slave_Top top1 (clk_out,reset,data_in,data_byte_out);
 
 
 
 
 endmodule
