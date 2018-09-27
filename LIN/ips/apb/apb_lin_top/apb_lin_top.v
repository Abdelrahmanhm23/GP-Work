//`timescale 1ns / 1ps // was not commented
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/12/2018 04:28:36 PM
// Design Name:
// Module Name: apb_lin_top
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
`define PULPino_address_width   (12)
`define PULPino_data_width      (32)
`define PULPino_reg_addr_width  (3 )
`define PULPino_data_addr_width (4 )
`define TX_RX_data_width        (32)
`define TX_RX_addr_width        (4 )
`define mem_depth               (16)
`define REG_data_width          (32)
//`define REG_addr_width          (4 )
`define Reg_depth               (10)



module apb_lin_top(

        pclk,
        preset_i,
        psel_i,
        penable_i,
        pwrite_i,
        paddr_i,
        pwdata_i,
        prdata_o,
        pready_o,
        pslverr_o,
////////////////////master top signals////////////////////////
        data_in_lin,
        data_out_lin,
        rx_flag1
        //,clk_lin
      );

    input                                       pclk;
    input                                       preset_i;
    input                                       psel_i;
    input                                       penable_i;
    input                                       pwrite_i;
    input      [`PULPino_address_width-1:0]     paddr_i;
    input      [`PULPino_data_width-1:0]        pwdata_i;
    output     [`PULPino_data_width-1:0]        prdata_o;
    output                                      pready_o;
    output                                      pslverr_o;

/////////////////////////master top signals////////////////////////
    input  [9:0]                                data_in_lin;    //data in to lin bus
    output [9:0]                                data_out_lin;  //data out from lin bus
    //input                                       clk_lin;
    //input reset_lin;
    output                                        rx_flag1;


//////////////////wires//////////////////////////
 /********************************************************/
   wire [`TX_RX_data_width -1:0]  tx_data_in;
   wire [`TX_RX_addr_width -1:0]  tx_address;
   wire                           tx_we;
 /*******************************************************/
   wire [`TX_RX_data_width-1:0]  rx_data_out;
   wire [`TX_RX_addr_width-1:0]  rx_address;
   wire                          rx_re;
 /*****************************************************/
   wire [`REG_data_width-1:0]   conv_reg_data_in;
   wire [`REG_data_width-1:0]   conv_reg_data_out;
   wire [3:0]   reg_address_wr;
   wire [3:0]   reg_address_rd;
   wire                         reg_ren;
   wire                         reg_wen;
 /*****************************************************/
  

// connected modules : apb_mem_converter --> LIN master_top
//

   apb_mem_converter_lin

    #  ( .addr_width       (`PULPino_address_width),
         .data_width       (`PULPino_data_width),
         //.reg_addr_width   (`PULPino_reg_addr_width),
		     .mem_addr_width   (`PULPino_data_addr_width)
        )
    apb_converter_lin
     (
        //Memory interface
             .reg_we            (reg_wen), // reg_ren
             .reg_re            (reg_ren),  
             .reg_data_o        (conv_reg_data_out),             
             .reg_data_i        (conv_reg_data_in),
             
             .reg_addr_wr       (reg_address_wr),
             .reg_addr_rd       (reg_address_rd),
             .tx_mem_we         (tx_we),
             .tx_mem_data       (tx_data_in),
             .tx_addr           (tx_address),

             .rx_mem_re         (rx_re),
             .rx_mem_data       (rx_data_out),
             .rx_addr           (rx_address),
            // SLAVE PORT (PULPino interface)
             .pclk              (pclk   ),
             .preset_i          (preset_i),
             .psel_i            (psel_i ),
             .penable_i         (penable_i ),
             .pwrite_i          (pwrite_i ),
             .paddr_i           (paddr_i ),
             .pwdata_i          (pwdata_i),
             .prdata_o          (prdata_o ),
             .pready_o          (pready_o ),
             .pslverr_o         (pslverr_o)

      );


top lin_master_top (  .clk           (pclk),
                      .reset         (preset_i),
                      .WR_en         (reg_wen),  //reg_ren
                      .Rd_en         (reg_ren),  //
                      .WR_addr       (reg_address_wr),
                      .WR_data       (conv_reg_data_out),
                      .rdAddrA       (reg_address_rd),
                      .dataO_apb     (conv_reg_data_in),
                      .RD_en_apb     (rx_re),
                      .WR_en_apb     (tx_we),
                      .RD_ADDR_apb   (rx_address),
                      .WR_ADDR_apb   (tx_address),
                      .WR_data_apb   (tx_data_in),
                      .RD_data_apb   (rx_data_out),
                      .data_in_lin   (data_in_lin),
                      .data_out_lin  (data_out_lin),
                      .rx_flag1      (rx_flag1)
                   );
                   


endmodule
