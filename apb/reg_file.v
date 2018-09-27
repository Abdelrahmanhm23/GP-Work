//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/17/2018 03:49:30 PM
// Design Name:
// Module Name: reg_file
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


module reg_file
   #( parameter data_width =32,
      parameter addr_width = 3,  // need to be a log2 opertation
      parameter reg_depth = 8
     )
   (
       input     [data_width-1:0]  data_in1, data_in2,
       input     [addr_width-1:0]  addr1 ,addr2,
       input                       we1, we2,
       input                       re1,re2,
       input                       clk,
       input                       reset,
       output reg [data_width-1:0] data_out1, data_out2 ,
       output reg                  txreq,
       output reg                  MsgRec,

       output wire                 txreq_ext_bit, // to be used by CAN/LIN module
       output wire                 msgrec_ext_bit
      );

      reg [data_width-1:0] rf [0:reg_depth-1];
      wire TXreq_bit ;
      wire MsgRec_bit;

      assign TXreq_bit = rf[2][0] ; // TXreq bit from TX_status register
      assign MsgRec_bit = rf[6][0] ; // MsgRec_bit from RX_status register

      assign txreq_ext_bit  = TXreq_bit ;
      assign msgrec_ext_bit = MsgRec_bit;

      integer i;
     //reset
      always @(posedge clk)
      begin
      if(~reset)
       begin
         txreq <= 0 ;
         MsgRec <= 0;
         for(i=0;i<reg_depth;i=i+1)
          begin
           rf[i] <= 0;
          end
       end
			 else
			  begin
			  if (we1)      //high > write   ,low > read
          begin
            txreq <= 0 ; // reseting the signal on writing again from host to reg file
            MsgRec <= 0;
            rf[addr1] <= data_in1;
          end
       else if (re1)
          begin
            data_out1 <= rf[addr1];
          end

			else if (we2)      //high > write   ,low > read
          begin
            rf[addr2] <= data_in2;
          end
      else if (re2)
         begin
           data_out2 <= rf[addr2];
         end
			  end
     end

      //this bit will be set by hardware when message arrives
      always @(posedge MsgRec_bit)
      begin
            MsgRec <= 1;
      end

      // adding functionality to detect that message is transmitted
      always @(negedge TXreq_bit)
      begin
            txreq <= 1'b1 ;
      end




  endmodule
