//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/17/2018 03:06:25 PM
// Design Name:
// Module Name: dual_port_tx_mem
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module dual_port_mem
   #(  parameter data_width= 32,
       parameter mem_depth = 16,
       parameter addr_width = 4  // has to be log2 operation

     )
    (
     input     [data_width-1:0]  data_in,
     input     [addr_width-1:0]  addr1 ,addr2,
     input                       we,re,
     input                       clk,
     input                       reset,
     output reg [data_width-1:0] data_out
    );

    reg [data_width-1:0] mem [0:mem_depth-1];
    integer i;
   //reset
     always @(posedge clk)
          begin
             if(~reset)
               begin
                 for(i=0;i<mem_depth;i=i+1)
                  begin
                   mem[i] <= 0;
                  end
               end

			  else if (we)      //high > write   ,low > read
              begin
                mem[addr1] <= data_in;
              end
			  if (re)      //high > write   ,low > read
                begin
                 data_out <= mem[addr2];
                end
            end


endmodule
