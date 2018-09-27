
module master_top(clk,clk_apb,reset,
                RD_en_apb,RD_ADDR_apb,       		//read address and read enable input from apb to rx memory
		 WR_en_apb,WR_ADDR_apb,WR_data_apb,    //write data to tx memory from apb 
		sleep_cmd,data_in,wakeup,bus_inactive,	//signals set from register file and data in from slave node
		en_schedule,nb_of_frames,	       //signals set from register file
		diagnostic_rcvd,end_diagnostic,	//signals set from register file
		data_out,init_finish,			//signals set to register file and data out from master node 
		error_flag1,error_flag2,data_valid_mem,RD_data_apb,rx_flag //added by abdelrahman
		);  //signals set to register file and read data from rx memory to apb





parameter INACTIVE = 30;
parameter [9:0] BREAK_BITS = 10'h000;


input clk,clk_apb,reset;
input RD_en_apb;
input [3:0] RD_ADDR_apb;
input WR_en_apb; 
input [3:0] WR_ADDR_apb; 
input [31:0] WR_data_apb;
input sleep_cmd,wakeup;
input en_schedule,diagnostic_rcvd;
input [9:0] data_in;
input [7:0] nb_of_frames;

output reg bus_inactive;
output end_diagnostic;
output [9:0] data_out;
output init_finish;
output [31:0] error_flag1;
output [31:0] error_flag2;
output data_valid_mem ;
output [31:0] RD_data_apb;
output reg rx_flag;  //added by abdelrahman

//------------------------------------------------------------------------------------------------------------------
wire en_operation,en_collision_table,wake_cluster,read_from_mem,MWR_en,WR_en,WR_en0,WR_en_sub;

wire [31:0] WR_data,WR_data0,WR_ADDR0,WR_data_sub ,MWR_data;
wire [3:0] WR_ADDR,RD_ADDR,RD_ADDR_pub,WR_ADDR_sub ,MWR_ADDR;
wire [31:0] MRD_data,MRD_ADDR,RD_data1,RD_data_apb,RD_data_apb0; 
wire [7:0] nb_of_frames,nb_of_schedules;
wire [9:0] headder,data_published;
wire master_publisher,master_subscriber;
wire en_slv_operation,S_read_from_mem;
wire [31:0] start_addr1,SRD_data, SRD_ADDR;  //needed only when the master node is not the publisher
wire [31:0] SWR_data,SWR_ADDR;
wire SWR_en;
wire [9:0] data_byte,data_byte1,data_byte2;
reg [9:0] data,header;
wire not_publisher,not_subscriber;
wire [3:0] NAD1 = 4'h0; 
wire [5:0] status_headder=6'h24;
wire [7:0] status_resp,status_error;
wire [3:0] NAD_rcv;
reg [7:0] count_inact;
wire init_start;
wire sleep_cmd_req,sleep_cmd_slave; //added
wire [63:0] OLD_DATA;
wire header_done,diagnostic_end;

//signals of error 
wire error_ctrl,error_ctrl0;

//signals of collision  
wire collision_resolved,collision_detected0;

//signals set to reg file 
wire [31:0] error_flag10,error_flag20;
wire init_finish0;
wire data_valid_mem,data_valid_mem0;
wire en_diagnostic_table;



//-----------------------------MEMORY INTERFACE---------------------------------------------------------------------------------------------------//

memory_tx Master_TOP5 (clk_apb,reset,WR_en_apb,WR_data_apb,WR_ADDR_apb,RD_ADDR_pub, RD_data1);

memory_rx Master_TOP55 (clk_apb,reset,WR_en_sub,WR_data_sub,WR_ADDR_sub,RD_en_apb,RD_ADDR_apb,RD_data_apb0);




//-----------------------------MASTER CONTROLLER---------------------------------------------------------------------------------------------------//

master_controller Master_TOP1 (clk,reset,en_schedule,
				sleep_cmd,bus_inactive,bus_error,wakeup,
				collision_detected0,collision_resolved,diagnostic_rcvd,
				en_operation,en_collision_table,en_diagnostic_table,wake_cluster,read_from_mem,
				init_start,init_finish0);

//-----------------------------SLAVE CONTROLLER ------------------------------------------------------------------------------------------------//
Slave_controller Master_TOP2 (clk,reset,headder,sleep_cmd_req,bus_inactive,bus_error,
			     en_slv_operation,S_read_from_mem,
			     wake_cluster,init_start,INIT_FINISH, master_req);

//-----------------------------SCHEDULE TABLE----------------------------------------------------------------------------------------------------//
schedule_table Master_TOP3 (clk,reset,en_operation,en_collision_table,en_diagnostic_table,diagnostic_end,
			    read_from_mem,error_ctrl, 
			    MRD_data,nb_of_frames,nb_of_schedules,
 			    MRD_ADDR,headder,
			    master_publisher,master_subscriber,
                header_done,collision_resolved,diagnostic_done,error_flag10,error_flag20); 

//----------------------------PUBLISHER OR MASTER NODE-------------------------------------------------------------------------------------------//
Slave_pub_rx Master_TOP4 (clk,reset,NAD1,status_headder,status_error,master_publisher,
			 en_slv_operation,S_read_from_mem,
			headder,start_addr1,RD_data1,
			SRD_data,data_byte,SRD_ADDR,OLD_DATA);


//---------------------------SUBSCRIBER OF MASTER NODE-------------------------------------------------------------------------------------------//
Slave_sub_rx Msster_TOP5 (clk,reset,NAD1,status_headder,master_subscriber,
			en_slv_operation,headder,data_byte2,status_error,
			MWR_en,MWR_ADDR,MWR_data,
			error_ctrl,collision_detected0,sleep_cmd_slave,NAD_rcv,data_valid_mem0,diagnostic_end);
			

//---------------------------EVENT TRIGGERED FRAME------------------------------------------------------------------------------------------------//
event_trig_frame Master_TOP7 (clk,reset,en_evenTrig_frame ,updated_signal1,updated_signal2,data_byte1,data_byte2,data_published);






//-------------------------publisher memory read from apb-------------------------//
assign RD_ADDR_pub = MRD_ADDR;          

//-------------------------Apb read data from rx memory----------------------------//
assign RD_data_apb = RD_data_apb0;


//-----------------------subscriber write to rx memory-----------------------------//
assign WR_en_sub = MWR_en;       
assign WR_ADDR_sub = MWR_ADDR;  
assign WR_data_sub = MWR_data;

//-----------------------signal set to reg file-------------------------------------// 
assign init_finish = init_finish0;
assign error_flag1 = error_flag10; 
assign error_flag2 = error_flag20;
assign data_valid_mem = data_valid_mem0;
assign rx_flag = data_valid_mem0;    //added by abdelrahman
//----------------------data in from slave node to master node when master node is subscriber------//
assign data_byte2 = data_in; 

//--------------------------data out from master node to slave node when slave node is subscriber------//
assign data_out =(header_done)? data_byte: headder;

//---------------------------------------------------------------------------
assign error_ctrl0 = (master_subscriber)? error_ctrl:1'b0;
assign bus_error =error_ctrl;
assign MRD_data = RD_data1;

assign en_evenTrig_frame =(MRD_data[5:0] ==6'h22)? 1'b1:1'b0; 

assign header_rcvd=header_done;

assign end_diagnostic = diagnostic_end;


always @(posedge clk) 
begin
	if(headder !==BREAK_BITS) begin
      count_inact <= count_inact +1;
           if(count_inact == INACTIVE) 
              bus_inactive <= 1'b1;
           else 
	     bus_inactive <= 1'b0;	              
 
       end
       else 
      count_inact <= 0;
end

endmodule 
