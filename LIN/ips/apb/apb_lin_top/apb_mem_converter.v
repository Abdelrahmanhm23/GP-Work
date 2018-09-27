//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/02/2018 03:12:18 PM
// Design Name:
// Module Name: apb_mem_converter
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


module apb_mem_converter_lin

 #  ( parameter addr_width = 12,
      parameter data_width = 32,
    //  parameter reg_addr_width = 3,
      parameter mem_addr_width = 4
     )

  (
     //Memory interface
     output reg                         reg_we,
     output reg                         reg_re,
     output reg [data_width-1:0]        reg_data_o,
     input      [data_width-1:0]        reg_data_i,
     output reg [3:0]    reg_addr_wr,
     output reg [3:0]    reg_addr_rd,

     output reg                        tx_mem_we,
     output reg [data_width-1:0]       tx_mem_data,
     output reg [mem_addr_width-1:0]   tx_addr,

     output reg                        rx_mem_re,
     input      [data_width-1:0]       rx_mem_data,
     output reg [mem_addr_width-1:0]   rx_addr,
         // SLAVE PORT (PULPino interface)
     input                              pclk,
     input                              preset_i,
     input                              psel_i,
     input                              penable_i,
     input                              pwrite_i,
     input      [addr_width-1:0]        paddr_i,
     input      [data_width-1:0]        pwdata_i,
     output reg [data_width-1:0]        prdata_o,
     output reg                         pready_o,
     output                             pslverr_o
   );

  assign pslverr_o = 1'b0 ;// pulling it to zero , as it is not supported here
  reg [1:0] read_state ;
  parameter init = 2'b00 , do_nothing = 2'b01 , read_data = 2'b10 ;


   always @(posedge pclk or negedge preset_i)
   begin
      if(~preset_i)
       begin
		  read_state <= init ;

          reg_re       <= 0;
		  reg_we       <= 0;
		  reg_data_o   <= 0;
		  reg_addr_rd     <= 0;
          reg_addr_wr     <= 0;

          tx_mem_we    <= 0;
          tx_addr      <= 0;
          tx_mem_data  <= 0;

          rx_mem_re    <= 0;
		  rx_addr      <= 0;

          pready_o     <= 0;
          prdata_o     <= 0;
       end
      else if (psel_i && penable_i && pwrite_i) // write state
      begin
          pready_o <= ~pready_o ; // pready will be 1'b1 next C/Cs , so it takes 2 C/Cs
          if (~pready_o)// writing data to the memory interface
            begin
              if ((paddr_i[5:0] <= 6'b101000) && (paddr_i[6]!= 1)) // reg file , let all of it R/W for now
              begin
                  reg_we     <= 1;
                  reg_addr_wr   <= paddr_i[5:2];
                  reg_data_o <= pwdata_i ;
              end
              else if (paddr_i[6]== 1)
              begin // writing to TX mem
                  tx_mem_we   <= 1 ;
                  tx_addr     <= paddr_i[5:2];
                  tx_mem_data <= pwdata_i ;
              end
          end
      end
      else if  (psel_i && penable_i && ~pwrite_i) //read state
      begin
		case(read_state)
			init :
                begin
		          read_state <= do_nothing ;

		             if (((paddr_i[5:0] <= 6'b101000) ) && (paddr_i[7]!= 1)) // reg file , let all of it R/W for now
                        begin
                            reg_we <= 0;
                            reg_re <= 1;
                            reg_addr_rd <= paddr_i[5:2];
                        end
                        else if (paddr_i[7]==1) // reading from RX memory
                        begin
                            rx_mem_re <= 1 ;
                            rx_addr <= paddr_i[5:2];
                        end
                end
			do_nothing :
                begin
		          	read_state <= read_data ;
                end
			read_data :
                begin
		          pready_o <= 1'b1 ;// FIX ME
		          if (((paddr_i[5:0] <= 6'b101000) ) && (paddr_i[7]!= 1))//getting data from register file
                        begin
                            prdata_o <= reg_data_i;
                        end
                        else if (paddr_i[7]==1)// read from RX mem
                        begin
                            prdata_o <= rx_mem_data ;
                        end
                        else // reading from not allwoed place
                        begin
                            prdata_o <= 32'b0 ; // make it unknown for now
                        end
                end
		endcase
      end
      else
      begin
		  read_state <= init ;
          reg_re       <= 0;
		  reg_we       <= 0;
		  reg_data_o   <= 0;
		  reg_addr_rd     <= 0;
          reg_addr_wr     <= 0;
          tx_mem_we    <= 0;
          tx_addr      <= 0;
          tx_mem_data  <= 0;

          rx_mem_re    <= 0;
		  rx_addr      <= 0;

          pready_o     <= 0;
          prdata_o     <= 0;
      end
   end

endmodule
