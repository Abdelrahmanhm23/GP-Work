module top (clk,reset,WR_en,Rd_en,WR_addr,WR_data,rdAddrA,dataO_apb,RD_en_apb,WR_en_apb,RD_ADDR_apb,WR_ADDR_apb,WR_data_apb,RD_data_apb,data_in_lin,data_out_lin ,rx_flag1 );

input clk,reset;
input WR_en,Rd_en;       //enable write and enable read to reg file
input [3:0] WR_addr;     //write address to reg file
input [31:0] WR_data;    //write data to reg file

input [3:0] rdAddrA; 

output [31:0] dataO_apb; //output data from reg file to apb 

input RD_en_apb,WR_en_apb; //enable write and enable read to memory
input [3:0] RD_ADDR_apb;   //read address to rx memory
input [3:0] WR_ADDR_apb;   //write address to tx memory
input [31:0] WR_data_apb;   //write address to tx memory
output [31:0] RD_data_apb;  //read data from rx memory
 
input [9:0] data_in_lin;    //data in to lin bus 
output [9:0] data_out_lin;  //data out from lin bus
output reg rx_flag1; //added by abdelrahman

wire [31:0] rf_data_out;
wire en_schedule0;
wire [31:0] RD_data_rx_mem;
wire [9:0] data_out; 
wire en_schedule,en_diagnostic_table,end_diagnostic,sleep_cmd0,sleep_cmd,bus_inactive,wakeup,INIT_FINISH,init_finish; 
wire [31:0] error_flag1;
wire [31:0] error_flag2;
wire [7:0] nb_of_frames;
wire clk_out;
wire data_valid_mem;
wire rx_flag0;  //added by abdelrahman
  
assign dataO_apb = rf_data_out;  
assign RD_data_apb = RD_data_rx_mem; 
assign data_out_lin = data_out;
assign sleep_cmd= sleep_cmd0;
assign INIT_FINISH =init_finish;
assign rx_flag1 = rx_flag0;   //added by abdelrahman
 
clock_divider TOP00 (reset,clk, clk_out);
 
//register_file TOP0 (clk_in,reset,WR_en,Rd_en,WR_addr,WR_data,rdAddrA,dataO_apb,error_flag1,error_flag2,INIT_FINISH,nb_of_frames,wakeup_cmd,sleep_cmd,bus_inactive,en_schedule,en_diagnostic,end_diagnostic);
   


register_file TOP0 (clk,reset,WR_en,Rd_en,WR_addr,WR_data,rdAddrA,rf_data_out,error_flag1,error_flag2,data_valid_mem,INIT_FINISH,
			nb_of_frames,wakeup,sleep_cmd0,bus_inactive,
		 	en_schedule0,en_diagnostic_table,end_diagnostic);




 master_top TOP1 (clk_out,clk,reset,
                 RD_en_apb,RD_ADDR_apb,
		 WR_en_apb,WR_ADDR_apb,WR_data_apb,
		sleep_cmd,data_in_lin,wakeup,bus_inactive,
		en_schedule0,nb_of_frames,
		en_diagnostic_table,end_diagnostic,
		data_out,init_finish,error_flag1,error_flag2,data_valid_mem,RD_data_rx_mem,rx_flag0//added by abdelrahman
		); 





endmodule 
