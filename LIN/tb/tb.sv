// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "config.sv"
`include "tb_jtag_pkg.sv"

`define REF_CLK_PERIOD   (2*15.25us)  // 32.786 kHz --> FLL reset value --> 50 MHz
`define CLK_PERIOD       40.00ns      // 25 MHz

`define EXIT_SUCCESS  0
`define EXIT_FAIL     1
`define EXIT_ERROR   -1

module tb;
  timeunit      1ns;
  timeprecision 1ps;

  // +MEMLOAD= valid values are "SPI", "STANDALONE" "PRELOAD", "" (no load of L2)
  parameter  SPI            = "QUAD";    // valid values are "SINGLE", "QUAD"
  parameter  BAUDRATE       = 781250;    // 1562500
  parameter  CLK_USE_FLL    = 0;  // 0 or 1
  parameter  TEST           = ""; //valid values are "" (NONE), "DEBUG"

  parameter  USE_ZERO_RISCY = 0;
  parameter  RISCY_RV32F    = 0;
  parameter  ZERO_RV32M     = 1;
  parameter  ZERO_RV32E     = 0;

  int           exit_status = `EXIT_ERROR; // modelsim exit code, will be overwritten when successful

  string        memload;
  logic         s_clk   = 1'b0;
  logic         s_rst_n = 1'b0;

  logic         fetch_enable = 1'b0;

  logic [1:0]   padmode_spi_master;
  logic         spi_sck   = 1'b0;
  logic         spi_csn   = 1'b1;
  logic [1:0]   spi_mode;
  logic         spi_sdo0;
  logic         spi_sdo1;
  logic         spi_sdo2;
  logic         spi_sdo3;
  logic         spi_sdi0;
  logic         spi_sdi1;
  logic         spi_sdi2;
  logic         spi_sdi3;

  logic         uart_tx;
  logic         uart_rx;
  logic         s_uart_dtr;
  logic         s_uart_rts;
  logic         uartB_rx; // those signals of monitor of uart for top_p2
  logic         uartB_tx; // ""

  logic         scl_pad_i;
  logic         scl_pad_o;
  logic         scl_padoen_o;

  logic         sda_pad_i;
  logic         sda_pad_o;
  logic         sda_padoen_o;

// apb extension connection of p1_i1
  logic         p1_apb_extension_HCLK_o_i1    ;
  logic         p1_apb_extension_HRESETn_o_i1 ;
  logic  [11:0] p1_apb_extension_PADDR_o_i1   ;
  logic  [31:0] p1_apb_extension_PWDATA_o_i1  ;
  logic         p1_apb_extension_PWRITE_o_i1  ;
  logic         p1_apb_extension_PSEL_o_i1    ;
  logic         p1_apb_extension_PENABLE_o_i1 ;
  logic  [31:0] p1_apb_extension_PRDATA_i_i1  ;
  logic         p1_apb_extension_PREADY_i_i1  ;
  logic         p1_apb_extension_PSLVERR_i_i1 ;

  // apb extension connection of p1_i2
    logic         p1_apb_extension_HCLK_o_i2    ;
    logic         p1_apb_extension_HRESETn_o_i2 ;
    logic  [11:0] p1_apb_extension_PADDR_o_i2   ;
    logic  [31:0] p1_apb_extension_PWDATA_o_i2  ;
    logic         p1_apb_extension_PWRITE_o_i2  ;
    logic         p1_apb_extension_PSEL_o_i2    ;
    logic         p1_apb_extension_PENABLE_o_i2 ;
    logic  [31:0] p1_apb_extension_PRDATA_i_i2  ;
    logic         p1_apb_extension_PREADY_i_i2  ;
    logic         p1_apb_extension_PSLVERR_i_i2 ;

// apb extension connection of p2
  logic         p2_apb_extension_HCLK_o_i1    ;
  logic         p2_apb_extension_HRESETn_o_i1 ;
  logic  [11:0] p2_apb_extension_PADDR_o_i1   ;
  logic  [31:0] p2_apb_extension_PWDATA_o_i1  ;
  logic         p2_apb_extension_PWRITE_o_i1  ;
  logic         p2_apb_extension_PSEL_o_i1    ;
  logic         p2_apb_extension_PENABLE_o_i1 ;
  logic  [31:0] p2_apb_extension_PRDATA_i_i1  ;
  logic         p2_apb_extension_PREADY_i_i1  ;
  logic         p2_apb_extension_PSLVERR_i_i1 ;

// apb extension connection of p3
  logic         p3_apb_extension_HCLK_o_i1    ;
  logic         p3_apb_extension_HRESETn_o_i1 ;
  logic  [11:0] p3_apb_extension_PADDR_o_i1   ;
  logic  [31:0] p3_apb_extension_PWDATA_o_i1  ;
  logic         p3_apb_extension_PWRITE_o_i1  ;
  logic         p3_apb_extension_PSEL_o_i1    ;
  logic         p3_apb_extension_PENABLE_o_i1 ;
  logic  [31:0] p3_apb_extension_PRDATA_i_i1  ;
  logic         p3_apb_extension_PREADY_i_i1  ;
  logic         p3_apb_extension_PSLVERR_i_i1 ;

  tri1          scl_io;
  tri1          sda_io;


  logic [31:0]  p1_gpio_in ;
  logic [31:0]  p1_gpio_dir;
  logic [31:0]  p1_gpio_out;

  logic [31:0]  p2_gpio_in ;
  logic [31:0]  p2_gpio_dir;
  logic [31:0]  p2_gpio_out;

  logic [31:0]  p3_gpio_in ;
  logic [31:0]  p3_gpio_dir;
  logic [31:0]  p3_gpio_out;

  logic [31:0]  recv_data;

  //extra unknown of use , UART signals
  logic         p1_s_uart_dtr;
  logic         p1_s_uart_rts;

  logic         p2_s_uart_dtr;
  logic         p2_s_uart_rts;

  logic         p3_s_uart_dtr;
  logic         p3_s_uart_rts;

  // uart wires for the three micro-controllers
  logic         p1_uart_tx;
  logic         p1_uart_rx;
  logic         p2_uart_tx;
  logic         p2_uart_rx;
  logic         p3_uart_tx;
  logic         p3_uart_rx;

  //spi master wires for three micro-controllers
  logic p1_master_clk;
  logic [1:0] p1_master_mode;
  logic p1_master_CS;
  logic p1_master_out0;
  logic p1_master_in0;

  logic p2_master_clk;
  logic [1:0] p2_master_mode;
  logic p2_master_CS;
  logic p2_master_out0;
  logic p2_master_in0;

  logic p3_master_clk;
  logic [1:0] p3_master_mode;
  logic p3_master_CS;
  logic p3_master_out0;
  logic p3_master_in0;

  //spi slave wires for three micro-controllers
  logic p1_slave_clk;
  logic p1_slave_CS;
  logic [1:0] p1_slave_mode;
  logic p1_slave_in0;
  logic p1_slave_out0 ;

  logic p2_slave_clk;
  logic p2_slave_CS;
  logic [1:0] p2_slave_mode;
  logic p2_slave_in0;
  logic p2_slave_out0 ;

  logic p3_slave_clk;
  logic p3_slave_CS;
  logic [1:0] p3_slave_mode;
  logic p3_slave_in0;
  logic p3_slave_out0 ;

  //external gpio signals
  logic [31:0]  p1_external_gpio_in ;
  logic [31:0]  p1_external_gpio_dir;
  logic [31:0]  p1_external_gpio_out;


  //connections between apb_interconnect of p1 and any module (ex. CAN)

  //register file
  logic [31:0]  p1_reg_data_out ;
  logic [31:0]  p1_reg_data_in  ;
  logic [2:0]   p1_reg_addr     ;
  logic         p1_reg_we       ;
  logic         p1_reg_re       ;

  // TX memory
  logic [3:0]  p1_tx_addr ;
  logic [31:0] p1_tx_data ;
  logic        p1_tx_re ;

  // RX memory
  logic [3:0]  p1_rx_addr ;
  logic [31:0] p1_rx_data ;
  logic        p1_rx_we ;

  // msgrec and txreq bits
  logic        p1_msgrec_bit ;
  logic        p1_txreq_bit  ;

  // msgrec and txreq gpio signal
  logic       p1_msgrec_gpio ;
  logic       p1_txreq_gpio ;

  //connections between apb_interconnect of p2 and any module (ex. CAN)

  //register file
  logic [31:0]  p2_reg_data_out ;
  logic [31:0]  p2_reg_data_in  ;
  logic [2:0]   p2_reg_addr     ;
  logic         p2_reg_we       ;
  logic         p2_reg_re       ;

  // TX memory
  logic [3:0]  p2_tx_addr ;
  logic [31:0] p2_tx_data ;
  logic        p2_tx_re ;

  // RX memory
  logic [3:0]  p2_rx_addr ;
  logic [31:0] p2_rx_data ;
  logic        p2_rx_we ;

  // msgrec and txreq bits
  logic        p2_msgrec_bit ;
  logic        p2_txreq_bit  ;

  // msgrec and txreq gpio signal
  logic       p2_msgrec_gpio ;
  logic       p2_txreq_gpio ;

  //connections between apb_interconnect of p3 and any module (ex. CAN)

  //register file
  logic [31:0]  p3_reg_data_out ;
  logic [31:0]  p3_reg_data_in  ;
  logic [2:0]   p3_reg_addr     ;
  logic         p3_reg_we       ;
  logic         p3_reg_re       ;

  // TX memory
  logic [3:0]  p3_tx_addr ;
  logic [31:0] p3_tx_data ;
  logic        p3_tx_re ;

  // RX memory
  logic [3:0]  p3_rx_addr ;
  logic [31:0] p3_rx_data ;
  logic        p3_rx_we ;

  // msgrec and txreq bits
  logic        p3_msgrec_bit ;
  logic        p3_txreq_bit  ;

  // msgrec and txreq gpio signal
  logic       p3_msgrec_gpio ;
  logic       p3_txreq_gpio ;
  
  
  // connections for apb_lin
  
/////////////////////////master top signals////////////////////////
    logic  [9:0]            data_in_lin;    //data in to lin bus
    logic  [9:0]            data_out_lin;  //data out from lin bus
    logic                   rx_flag1;
  
    
    
  jtag_i jtag_if();

  adv_dbg_if_t adv_dbg_if = new(jtag_if);


  uart_bus
  #(
    .BAUD_RATE(BAUDRATE),
    .PARITY_EN(0),
    .P_NUM(1 + 48) // ascii of chracter' 1'
  )
 uart_p1
  (
    .rx         ( p1_uart_tx ),
    .tx         (  ),
    .rx_en      ( 1'b1    )
  );


  uart_bus
  #(
    .BAUD_RATE(BAUDRATE),
    .PARITY_EN(0),
    .P_NUM(2 + 48)
  )
 uart_p2
  (
    .rx         ( p2_uart_tx ),
    .tx         (  ),
    .rx_en      ( 1'b1    )
  );

  uart_bus
  #(
    .BAUD_RATE(BAUDRATE),
    .PARITY_EN(0),
    .P_NUM(3 + 48)
  )
 uart_p3
  (
    .rx         ( p3_uart_tx ),
    .tx         (  ),
    .rx_en      ( 1'b1    )
  );

/*
  i2c_buf i2c_buf_i
  (
    .scl_io       ( scl_io       ),
    .sda_io       ( sda_io       ),
    . scl_pad_i    ( scl_pad_i    ),
    .scl_pad_o    ( scl_pad_o    ),
    .scl_padoen_o ( scl_padoen_o ),
    .sda_pad_i    ( sda_pad_i    ),
    .sda_pad_o    ( sda_pad_o    ),
    .sda_padoen_o ( sda_padoen_o )
  );
*/
  i2c_eeprom_model
  #(
    .ADDRESS ( 7'b1010_000 )
  )
  i2c_eeprom_model_i
  (
    .scl_io ( scl_io  ),
    .sda_io ( sda_io  ),
    .rst_ni ( s_rst_n )
  );


/*
dummy_module dummy_module_i
(
  .clk             (p1_apb_extension_HCLK_o)  ,
  .reset           (p1_apb_extension_HRESETn_o)  ,

  .reg_data_in     (reg_data_out)  ,
  .reg_data_out    (reg_data_in)  ,
  .reg_addr        (reg_addr)  ,
  .reg_we          (reg_we)  ,
  .reg_re          (reg_re)  ,

  .tx_addr         (tx_addr)  ,
  .tx_re           (tx_re  )  ,
  .tx_data_in      (tx_data)  ,

  .rx_data_out     (rx_data)  ,
  .rx_we           (rx_we)  ,
  .rx_addr         ( rx_addr )  ,

  .TXreq_bit       (txreq_bit )  ,
  .MsgRec_bit      (msgrec_bit)

  );
*/

/*
// testing apb inter-connect
apb_mem_converter_top apb_mem_converter_top_p1
(
     .pclk         (p1_apb_extension_HCLK_o_i1   ) ,
     .preset_i     (p1_apb_extension_HRESETn_o_i1) ,

     .paddr_i      (p1_apb_extension_PADDR_o_i1  ) ,
     .pwdata_i     (p1_apb_extension_PWDATA_o_i1 ) ,
     .pwrite_i     (p1_apb_extension_PWRITE_o_i1 ) ,
     .psel_i       (p1_apb_extension_PSEL_o_i1   ) ,
     .penable_i    (p1_apb_extension_PENABLE_o_i1) ,
     .prdata_o     (p1_apb_extension_PRDATA_i_i1 ) ,
     .pready_o     (p1_apb_extension_PREADY_i_i1 ) ,
     .pslverr_o    (p1_apb_extension_PSLVERR_i_i1) ,

// should be connected to CAN module
// tx memory
     .addr2           (p1_tx_addr) ,
     .re              (p1_tx_re  ) ,
     .data_out        (p1_tx_data) ,

//rx memory
     .data_in         (p1_rx_data) ,
     .addr1           (p1_rx_addr) ,
     .we              (p1_rx_we  ) ,

// reg file
     .data_in2        (p1_reg_data_in ) ,
     .reg_addr2       (p1_reg_addr    ) ,
     .we2             (p1_reg_we      ) ,
     .re2             (p1_reg_re      ) ,
     .data_out2       (p1_reg_data_out) ,

     .txreq           (p1_txreq_gpio) , // goes to gpio
     .MsgRec          (p1_msgrec_gpio) , // goes to gpio
     .txreq_ext_bit   (p1_txreq_bit ) ,
     .msgrec_ext_bit  (p1_msgrec_bit)
);

*/


apb_lin_top  lin 
    (
       
       .pclk          (p1_apb_extension_HCLK_o_i2),
       .preset_i      (p1_apb_extension_HRESETn_o_i2),
       .psel_i        (p1_apb_extension_PSEL_o_i2),
       .penable_i     (p1_apb_extension_PENABLE_o_i2),
       .pwrite_i      (p1_apb_extension_PWRITE_o_i2),
       .paddr_i       (p1_apb_extension_PADDR_o_i2),
       .pwdata_i      (p1_apb_extension_PWDATA_o_i2),
       .prdata_o      (p1_apb_extension_PRDATA_i_i2),
       .pready_o      (p1_apb_extension_PREADY_i_i2),
       .pslverr_o     (p1_apb_extension_PSLVERR_i_i2),

////////////////////master top signals////////////////////////
        .data_in_lin   (data_in_lin),
        .data_out_lin  (data_out_lin),
        .rx_flag1      (rx_flag1)
                
     );
 

 top2  lin_slave (  .clk (p1_apb_extension_HCLK_o_i2),
                    .reset(p1_apb_extension_HRESETn_o_i2),
                    .data_in(data_out_lin),
                    .data_out(data_in_lin)
                 );



/*
apb_mem_converter_top apb_mem_converter_top_p2
(
     .pclk         (p2_apb_extension_HCLK_o_i1)    ,
     .preset_i     (p2_apb_extension_HRESETn_o_i1) ,

     .paddr_i      (p2_apb_extension_PADDR_o_i1  ) ,
     .pwdata_i     (p2_apb_extension_PWDATA_o_i1 ) ,
     .pwrite_i     (p2_apb_extension_PWRITE_o_i1 ) ,
     .psel_i       (p2_apb_extension_PSEL_o_i1   ) ,
     .penable_i    (p2_apb_extension_PENABLE_o_i1) ,
     .prdata_o     (p2_apb_extension_PRDATA_i_i1 ) ,
     .pready_o     (p2_apb_extension_PREADY_i_i1 ) ,
     .pslverr_o    (p2_apb_extension_PSLVERR_i_i1) ,

// should be connected to CAN module
// tx memory
     .addr2           (p2_tx_addr) ,
     .re              (p2_tx_re  ) ,
     .data_out        (p2_tx_data) ,

//rx memory
     .data_in         (p2_rx_data) ,
     .addr1           (p2_rx_addr) ,
     .we              (p2_rx_we  ) ,

// reg file
     .data_in2        (p2_reg_data_in ) ,
     .reg_addr2       (p2_reg_addr    ) ,
     .we2             (p2_reg_we      ) ,
     .re2             (p2_reg_re      ) ,
     .data_out2       (p2_reg_data_out) ,

     .txreq           (p2_txreq_gpio) , // goes to gpio
     .MsgRec          (p2_msgrec_gpio) , // goes to gpio
     .txreq_ext_bit   (p2_txreq_bit ) ,
     .msgrec_ext_bit  (p2_msgrec_bit)
);

apb_mem_converter_top apb_mem_converter_top_p3
(
     .pclk         (p3_apb_extension_HCLK_o_i1)    ,
     .preset_i     (p3_apb_extension_HRESETn_o_i1) ,

     .paddr_i      (p3_apb_extension_PADDR_o_i1  ) ,
     .pwdata_i     (p3_apb_extension_PWDATA_o_i1 ) ,
     .pwrite_i     (p3_apb_extension_PWRITE_o_i1 ) ,
     .psel_i       (p3_apb_extension_PSEL_o_i1   ) ,
     .penable_i    (p3_apb_extension_PENABLE_o_i1) ,
     .prdata_o     (p3_apb_extension_PRDATA_i_i1 ) ,
     .pready_o     (p3_apb_extension_PREADY_i_i1 ) ,
     .pslverr_o    (p3_apb_extension_PSLVERR_i_i1) ,

// should be connected to CAN module
// tx memory
     .addr2           (p3_tx_addr) ,
     .re              (p3_tx_re  ) ,
     .data_out        (p3_tx_data) ,

//rx memory
     .data_in         (p3_rx_data) ,
     .addr1           (p3_rx_addr) ,
     .we              (p3_rx_we  ) ,

// reg file
     .data_in2        (p3_reg_data_in ) ,
     .reg_addr2       (p3_reg_addr    ) ,
     .we2             (p3_reg_we      ) ,
     .re2             (p3_reg_re      ) ,
     .data_out2       (p3_reg_data_out) ,

     .txreq           (p3_txreq_gpio) , // goes to gpio
     .MsgRec          (p3_msgrec_gpio) , // goes to gpio
     .txreq_ext_bit   (p3_txreq_bit ) ,
     .msgrec_ext_bit  (p3_msgrec_bit)
);
*/
// wires to make gpio interrupt
assign p1_gpio_in[0] = p1_txreq_gpio;
//assign p1_gpio_in[1] = p1_msgrec_gpio;
assign p1_gpio_in[2] = rx_flag1;
/*
assign p2_gpio_in[0] = p2_txreq_gpio;
assign p2_gpio_in[1] = p2_msgrec_gpio;

assign p3_gpio_in[0] = p3_txreq_gpio;
assign p3_gpio_in[1] = p3_msgrec_gpio;
*/
  pulpino_top
  #(
    .USE_ZERO_RISCY    ( USE_ZERO_RISCY ),
    .RISCY_RV32F       ( RISCY_RV32F    ),
    .ZERO_RV32M        ( ZERO_RV32M     ),
    .ZERO_RV32E        ( ZERO_RV32E     )
   )
  top_p1
  (
    .clk               ( s_clk        ),
    .rst_n             ( s_rst_n      ),

    .clk_sel_i         ( 1'b0         ),
    .testmode_i        ( 1'b0         ),
    .fetch_enable_i    ( fetch_enable ),

    .spi_clk_i         ( p1_slave_clk      ),
    .spi_cs_i          ( p1_slave_CS      ),
    .spi_mode_o        ( p1_slave_mode     ),
    .spi_sdo0_o        ( p1_slave_out0     ),
    .spi_sdo1_o        (      ),
    .spi_sdo2_o        (      ),
    .spi_sdo3_o        (      ),
    .spi_sdi0_i        ( p1_slave_in0     ),
    .spi_sdi1_i        (      ),
    .spi_sdi2_i        (      ),
    .spi_sdi3_i        (      ),

    .spi_master_clk_o  (  p1_master_clk    ),
    .spi_master_csn0_o (   p1_master_CS   ),// test with one slave at chip 0
    .spi_master_csn1_o (                    ),
    .spi_master_csn2_o (                    ),
    .spi_master_csn3_o (                    ),
    .spi_master_mode_o ( p1_master_mode ),
    .spi_master_sdo0_o ( p1_master_out0  ),
    .spi_master_sdo1_o (    ),
    .spi_master_sdo2_o (    ),
    .spi_master_sdo3_o (    ),
    .spi_master_sdi0_i ( p1_master_in0  ),
    .spi_master_sdi1_i (    ),
    .spi_master_sdi2_i (    ),
    .spi_master_sdi3_i (    ),
/* commented to remove warnings , related to i2c peripheral
    .scl_pad_i         ( scl_pad_i    ),
    .scl_pad_o         ( scl_pad_o    ),
    .scl_padoen_o      ( scl_padoen_o ),
    .sda_pad_i         ( sda_pad_i    ),
    .sda_pad_o         ( sda_pad_o    ),
    .sda_padoen_o      ( sda_padoen_o ),
*/

    .uart_tx           ( p1_uart_tx      ), // wires to make it easier to know where it is comming from
    .uart_rx           ( p1_uart_rx      ),
    .uart_rts          ( p1_s_uart_rts   ),
    .uart_dtr          ( p1_s_uart_dtr   ),
    .uart_cts          ( 1'b0         ),
    .uart_dsr          ( 1'b0         ),

    .gpio_in           ( p1_gpio_in      ),
    .gpio_out          ( p1_gpio_out     ),
    .gpio_dir          ( p1_gpio_dir     ),
    .gpio_padcfg       (              ),

    .tck_i             ( jtag_if.tck     ),
    .trstn_i           ( jtag_if.trstn   ),
    .tms_i             ( jtag_if.tms     ),
    .tdi_i             ( jtag_if.tdi     ),
    //.tdo_o             ( jtag_if.tdo     )//commented due to warning
    .apb_extension_HCLK_o_i1     (p1_apb_extension_HCLK_o_i1   ),
    .apb_extension_HRESETn_o_i1  (p1_apb_extension_HRESETn_o_i1),
    .apb_extension_PADDR_o_i1    (p1_apb_extension_PADDR_o_i1  ),
    .apb_extension_PWDATA_o_i1   (p1_apb_extension_PWDATA_o_i1 ),
    .apb_extension_PWRITE_o_i1   (p1_apb_extension_PWRITE_o_i1 ),
    .apb_extension_PSEL_o_i1     (p1_apb_extension_PSEL_o_i1   ),
    .apb_extension_PENABLE_o_i1  (p1_apb_extension_PENABLE_o_i1),
    .apb_extension_PRDATA_i_i1   (p1_apb_extension_PRDATA_i_i1 ),
    .apb_extension_PREADY_i_i1   (p1_apb_extension_PREADY_i_i1 ),
    .apb_extension_PSLVERR_i_i1  (p1_apb_extension_PSLVERR_i_i1),

    .apb_extension_HCLK_o_i2     (p1_apb_extension_HCLK_o_i2   ),
    .apb_extension_HRESETn_o_i2  (p1_apb_extension_HRESETn_o_i2),
    .apb_extension_PADDR_o_i2    (p1_apb_extension_PADDR_o_i2  ),
    .apb_extension_PWDATA_o_i2   (p1_apb_extension_PWDATA_o_i2 ),
    .apb_extension_PWRITE_o_i2   (p1_apb_extension_PWRITE_o_i2 ),
    .apb_extension_PSEL_o_i2     (p1_apb_extension_PSEL_o_i2   ),
    .apb_extension_PENABLE_o_i2  (p1_apb_extension_PENABLE_o_i2),
    .apb_extension_PRDATA_i_i2   (p1_apb_extension_PRDATA_i_i2 ),
    .apb_extension_PREADY_i_i2   (p1_apb_extension_PREADY_i_i2 ),
    .apb_extension_PSLVERR_i_i2  (p1_apb_extension_PSLVERR_i_i2)
  );


/*

pulpino_top
#(
  .USE_ZERO_RISCY    ( USE_ZERO_RISCY ),
  .RISCY_RV32F       ( RISCY_RV32F    ),
  .ZERO_RV32M        ( ZERO_RV32M     ),
  .ZERO_RV32E        ( ZERO_RV32E     )
 )
top_p2
(
  .clk               ( s_clk        ),
  .rst_n             ( s_rst_n      ),

  .clk_sel_i         ( 1'b0         ),
  .testmode_i        ( 1'b0         ),
  .fetch_enable_i    ( fetch_enable ),

  .spi_clk_i         ( p2_slave_clk      ),
  .spi_cs_i          ( p2_slave_CS      ),
  .spi_mode_o        (  p2_slave_mode    ),
  .spi_sdo0_o        (  p2_slave_out0    ),
  .spi_sdo1_o        (      ),
  .spi_sdo2_o        (      ),
  .spi_sdo3_o        (      ),
  .spi_sdi0_i        (  p2_slave_in0    ),
  .spi_sdi1_i        (      ),
  .spi_sdi2_i        (      ),
  .spi_sdi3_i        (      ),

  .spi_master_clk_o  ( p2_master_clk    ),
  .spi_master_csn0_o ( p2_master_CS     ),
  .spi_master_csn1_o (                    ),
  .spi_master_csn2_o (                    ),
  .spi_master_csn3_o (                    ),
  .spi_master_mode_o ( p2_master_mode ),
  .spi_master_sdo0_o ( p2_master_out0  ),
  .spi_master_sdo1_o (      ),
  .spi_master_sdo2_o (      ),
  .spi_master_sdo3_o (      ),
  .spi_master_sdi0_i ( p2_master_in0  ),
  .spi_master_sdi1_i (    ),
  .spi_master_sdi2_i (    ),
  .spi_master_sdi3_i (    ),
/* commented to remove warnings , related to i2c peripheral
  .scl_pad_i         ( scl_pad_i    ),
  .scl_pad_o         ( scl_pad_o    ),
  .scl_padoen_o      ( scl_padoen_o ),
  .sda_pad_i         ( sda_pad_i    ),
  .sda_pad_o         ( sda_pad_o    ),
  .sda_padoen_o      ( sda_padoen_o ),
*/
/*
  .uart_tx           (  p2_uart_tx     ),
  .uart_rx           (  p2_uart_rx     ),
  .uart_rts          ( p2_s_uart_rts   ),
  .uart_dtr          ( p2_s_uart_dtr   ),
  .uart_cts          ( 1'b0         ),
  .uart_dsr          ( 1'b0         ),

  .gpio_in           ( p2_gpio_in      ),
  .gpio_out          ( p2_gpio_out     ),
  .gpio_dir          ( p2_gpio_dir     ),
  .gpio_padcfg       (              ),

  .tck_i             ( jtag_if.tck     ),
  .trstn_i           ( jtag_if.trstn   ),
  .tms_i             ( jtag_if.tms     ),
  .tdi_i             ( jtag_if.tdi     ),
//  .tdo_o             ( jtag_if.tdo     )//commented due to warning

  .apb_extension_HCLK_o_i1     (p2_apb_extension_HCLK_o_i1   ),
  .apb_extension_HRESETn_o_i1  (p2_apb_extension_HRESETn_o_i1),
  .apb_extension_PADDR_o_i1    (p2_apb_extension_PADDR_o_i1  ),
  .apb_extension_PWDATA_o_i1   (p2_apb_extension_PWDATA_o_i1 ),
  .apb_extension_PWRITE_o_i1   (p2_apb_extension_PWRITE_o_i1 ),
  .apb_extension_PSEL_o_i1     (p2_apb_extension_PSEL_o_i1   ),
  .apb_extension_PENABLE_o_i1  (p2_apb_extension_PENABLE_o_i1),
  .apb_extension_PRDATA_i_i1   (p2_apb_extension_PRDATA_i_i1 ),
  .apb_extension_PREADY_i_i1   (p2_apb_extension_PREADY_i_i1 ),
  .apb_extension_PSLVERR_i_i1  (p2_apb_extension_PSLVERR_i_i1)
);



pulpino_top
#(
  .USE_ZERO_RISCY    ( USE_ZERO_RISCY ),
  .RISCY_RV32F       ( RISCY_RV32F    ),
  .ZERO_RV32M        ( ZERO_RV32M     ),
  .ZERO_RV32E        ( ZERO_RV32E     )
 )
top_p3
(
  .clk               ( s_clk        ),
  .rst_n             ( s_rst_n      ),

  .clk_sel_i         ( 1'b0         ),
  .testmode_i        ( 1'b0         ),
  .fetch_enable_i    ( fetch_enable ),

  .spi_clk_i         (  p3_slave_clk     ),
  .spi_cs_i          (  p3_slave_CS     ),
  .spi_mode_o        (  p3_slave_mode    ),
  .spi_sdo0_o        (  p3_slave_out0    ),
  .spi_sdo1_o        (      ),
  .spi_sdo2_o        (      ),
  .spi_sdo3_o        (      ),
  .spi_sdi0_i        (  p3_slave_in0    ),
  .spi_sdi1_i        (      ),
  .spi_sdi2_i        (      ),
  .spi_sdi3_i        (      ),

  .spi_master_clk_o  ( p3_master_clk    ),
  .spi_master_csn0_o ( p3_master_CS    ),
  .spi_master_csn1_o (                    ),
  .spi_master_csn2_o (                    ),
  .spi_master_csn3_o (                    ),
  .spi_master_mode_o ( p3_master_mode ),
  .spi_master_sdo0_o ( p3_master_out0  ),
  .spi_master_sdo1_o (      ),
  .spi_master_sdo2_o (      ),
  .spi_master_sdo3_o (     ),
  .spi_master_sdi0_i ( p3_master_in0  ),
  .spi_master_sdi1_i (    ),
  .spi_master_sdi2_i (   ),
  .spi_master_sdi3_i (    ),
/* commented to remove warnings , related to i2c peripheral
  .scl_pad_i         ( scl_pad_i    ),
  .scl_pad_o         ( scl_pad_o    ),
  .scl_padoen_o      ( scl_padoen_o ),
  .sda_pad_i         ( sda_pad_i    ),
  .sda_pad_o         ( sda_pad_o    ),
  .sda_padoen_o      ( sda_padoen_o ),
*/
/*
  .uart_tx           (  p3_uart_tx     ),
  .uart_rx           (  p3_uart_rx     ),
  .uart_rts          ( p3_s_uart_rts   ),
  .uart_dtr          ( p3_s_uart_dtr   ),
  .uart_cts          ( 1'b0         ),
  .uart_dsr          ( 1'b0         ),

  .gpio_in           ( p3_gpio_in      ),
  .gpio_out          ( p3_gpio_out     ),
  .gpio_dir          ( p3_gpio_dir     ),
  .gpio_padcfg       (              ),

  .tck_i             ( jtag_if.tck     ),
  .trstn_i           ( jtag_if.trstn   ),
  .tms_i             ( jtag_if.tms     ),
  .tdi_i             ( jtag_if.tdi     ),
  //.tdo_o             ( jtag_if.tdo     ) //commented due to warning

  .apb_extension_HCLK_o_i1     (p3_apb_extension_HCLK_o_i1   ),
  .apb_extension_HRESETn_o_i1  (p3_apb_extension_HRESETn_o_i1),
  .apb_extension_PADDR_o_i1    (p3_apb_extension_PADDR_o_i1  ),
  .apb_extension_PWDATA_o_i1   (p3_apb_extension_PWDATA_o_i1 ),
  .apb_extension_PWRITE_o_i1   (p3_apb_extension_PWRITE_o_i1 ),
  .apb_extension_PSEL_o_i1     (p3_apb_extension_PSEL_o_i1   ),
  .apb_extension_PENABLE_o_i1  (p3_apb_extension_PENABLE_o_i1),
  .apb_extension_PRDATA_i_i1   (p3_apb_extension_PRDATA_i_i1 ),
  .apb_extension_PREADY_i_i1   (p3_apb_extension_PREADY_i_i1 ),
  .apb_extension_PSLVERR_i_i1  (p3_apb_extension_PSLVERR_i_i1)
);
*/

  generate
    if (CLK_USE_FLL) begin
      initial
      begin
        #(`REF_CLK_PERIOD/2);
        s_clk = 1'b1;
        forever s_clk = #(`REF_CLK_PERIOD/2) ~s_clk;
      
      end
    end else begin
      initial
      begin
        #(`CLK_PERIOD/2);
        s_clk = 1'b1;
        forever s_clk = #(`CLK_PERIOD/2) ~s_clk;
      end
    end
  endgenerate

  logic use_qspi;

  initial
  begin
    int i;

    if(!$value$plusargs("MEMLOAD=%s", memload))
      memload = "PRELOAD";

    $display("Using MEMLOAD method: %s", memload);

    $display("Using %s core", USE_ZERO_RISCY ? "zero-riscy" : "ri5cy");

    use_qspi = SPI == "QUAD" ? 1'b1 : 1'b0;

    s_rst_n      = 1'b0;
    fetch_enable = 1'b0;

    
    #500ns;

    s_rst_n = 1'b1;
        
    #500ns;
    if (use_qspi)begin
      $display("hey there i am qspi");
      spi_enable_qpi();
    end

    if (memload != "STANDALONE")
    begin
      /* Configure JTAG and set boot address */
      adv_dbg_if.jtag_reset();
      adv_dbg_if.jtag_softreset();
      adv_dbg_if.init();
      adv_dbg_if.axi4_write32(32'h1A10_7008, 1, 32'h0000_0000);
    end

    if (memload == "PRELOAD")
    begin
      // preload memories
      mem_preload_p1();
      //mem_preload_p2();
      //mem_preload_p3();
   // read_from_file("/home/waleed/pulpino/pulpino/files_mem/my_mem" , 4,0); // loads data from file to chosen memory in the task
    end
    else if (memload == "SPI")
    begin
      $display("hey there , i am loading from SPI \n");
      //spi_load(use_qspi);
      //spi_check(use_qspi);
    end

    #200ns;
    fetch_enable = 1'b1;

    spi_check_return_codes(exit_status);
 /*
#1680ns
p1_gpio_in[3]=0;

#450000ns
p1_gpio_in[3]=1;

#1680ns
p1_gpio_in[3]=0;
*/
#500000ns
   // write_to_file("/home/waleed/pulpino/pulpino/files_mem/output"  , 4 , 1000); // write data from chosen memory to specified file
   // compare_files("/home/waleed/pulpino/pulpino/files_mem/output" , "/home/waleed/pulpino/pulpino/files_mem/my_mem" ,4); // compare contents of two files
    $fflush();
    $stop();
  end

  // TODO: this is a hack, do it properly!
  `include "tb_spi_pkg.sv"
  `include "tb_mem_pkg_p1.sv"
  //`include "tb_mem_pkg_p2.sv"
  //`include "tb_mem_pkg_p3.sv"
  `include "spi_debug_test.svh"
  `include "mem_dpi.svh"
  //`include "load_file.sv"
  //`include "spi_monitor.sv"
  //`include "gpio_int_test.sv"

endmodule
