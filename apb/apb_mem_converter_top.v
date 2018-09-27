//`timescale 1ns / 1ps // was not commented
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/07/2018 01:08:58 AM
// Design Name:
// Module Name: apb_mem_converter_top
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
`define REG_addr_width          (3 )
`define Reg_depth               (8)



module apb_mem_converter_top(

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

        addr2,
        re,
        data_out,

        data_in,
        addr1 ,
        we,


        data_in2,
        reg_addr2,
        we2,
        re2,
        data_out2,

        txreq,
        MsgRec,

        txreq_ext_bit ,
        msgrec_ext_bit
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
   /////////TX MEMORY/////////////////
    input     [`TX_RX_addr_width-1:0]  addr2;
    input                              re;
    output    [`TX_RX_data_width-1:0] data_out;
    /////////RX MEMORY//////////////////
    input     [`TX_RX_data_width-1:0]  data_in;
    input     [`TX_RX_addr_width-1:0]  addr1 ;
    input                              we;
    /////////REGISTER FILE/////////////
    input     [`REG_data_width-1:0]  data_in2;
    input     [`REG_addr_width-1:0]  reg_addr2;
    input                            we2;
    input                            re2;
    output   [`REG_data_width-1:0]   data_out2;

    output                           txreq;
    output                           MsgRec;
    output                            txreq_ext_bit;
    output                            msgrec_ext_bit;
 /********************************************************/
   wire [`TX_RX_data_width -1:0] tx_data_in;
   wire [`TX_RX_addr_width -1:0] tx_address;
   wire                          tx_we;
 /*******************************************************/
   wire [`TX_RX_data_width-1:0] rx_data_out;
   wire [`TX_RX_addr_width-1:0] rx_address;
   wire                         rx_re;
 /*****************************************************/
   wire [`REG_data_width-1:0]  conv_reg_data_in;
   wire [`REG_data_width-1:0]  conv_reg_data_out;
   wire [`REG_addr_width-1:0]  reg_address;
   wire                        reg_ren;
   wire                        reg_wen;
 /*****************************************************/
   apb_mem_converter

    #  ( .addr_width       (`PULPino_address_width),
         .data_width       (`PULPino_data_width),
         .reg_addr_width   (`PULPino_reg_addr_width),
		 .mem_addr_width   (`PULPino_data_addr_width)
        )
    apb_converter
     (
        //Memory interface
             .reg_we            (reg_wen   ),
             .reg_re            (reg_ren   ),
             .reg_data_i        (conv_reg_data_in   ),
             .reg_data_o        (conv_reg_data_out  ),
             .reg_addr          (reg_address    ),

             .tx_mem_we         (tx_we   ) ,
             .tx_mem_data       (tx_data_in ),
             .tx_addr           (tx_address   ) ,

             .rx_mem_re         (rx_re ),
             .rx_mem_data       (rx_data_out ),
             .rx_addr           (rx_address    ),
            // SLAVE PORT (PULPino interface)
             .pclk              (pclk   ),
             .preset_i            (preset_i),
             .psel_i            (psel_i ),
             .penable_i         (penable_i ),
             .pwrite_i          (pwrite_i ),
             .paddr_i           (paddr_i ),
             .pwdata_i          (pwdata_i),
             .prdata_o          (prdata_o ),
             .pready_o          (pready_o ),
             .pslverr_o         (pslverr_o)

      );



      dual_port_mem
         #(  .data_width (`TX_RX_data_width),
             .mem_depth  (`mem_depth),
             .addr_width (`TX_RX_addr_width)
           )
         tx_mem
          (
            .data_in    (tx_data_in ),
            .addr1      (tx_address ),
            .addr2      (addr2),
            .we         (tx_we),
            .re         (re),

            .clk          (pclk),
            .reset        (preset_i),
            .data_out     (data_out)
          );




          dual_port_mem
             #(   .data_width (`TX_RX_data_width),
                  .mem_depth  (`mem_depth),
                  .addr_width (`TX_RX_addr_width)
               )
           rx_mem
              (
                .data_in    (data_in),
                .addr1      (addr1),
                .addr2      (rx_address),
                .we         (we),
                .re         (rx_re),

                .clk          (pclk),
                .reset        (preset_i),
                .data_out     (rx_data_out)
              );




             reg_file
                 #( .data_width   (`REG_data_width),
                    .addr_width   (`REG_addr_width),
                    .reg_depth    (`Reg_depth)
                   )
                 Register_file
                 (
                     .data_in1      (conv_reg_data_out),
                     .data_in2      (data_in2),
                     .addr1         (reg_address),
                     .addr2         (reg_addr2),
                     .we1           (reg_wen),
                     .we2           (we2),
                     .re1           (reg_ren),
                     .re2           (re2),
                     .clk           (pclk),
                     .reset         (preset_i),
                     .data_out1     (conv_reg_data_in),
                     .data_out2     (data_out2),

                     .txreq         (txreq),
                     .MsgRec        (MsgRec),
                     .txreq_ext_bit (txreq_ext_bit),
                     .msgrec_ext_bit(msgrec_ext_bit)
                    );



endmodule

