module Slave_Top (clk,reset,data_in,data_byte_out);

parameter [5:0] EVNT_UNCOND_FRAME1=6'h25, EVNT_UNCOND_FRAME2=6'h26;
parameter[5:0] status_headder1 = 6'h24,status_headder2=6'h34;
parameter[3:0]NAD2=4'h2;
parameter [9:0] BREAK_BITS=10'h000;
parameter INACTIVE = 30;
parameter [3:0] d0=4'h0,d1=4'h1,d2=4'h2,d3=4'h3,d4=4'h4,d5=4'h5,d6=4'h6,d7=4'h7,d8=4'h8,d9=4'h9,d10=4'ha,d11=4'hb,d12=4'hc,d13=4'hd,d14=4'he,d15=4'hf;

input clk,reset;
//input [9:0] headder_in;
input [9:0] data_in; 
output [9:0] data_byte_out; 

wire [3:0] initial_NAD1,initial_NAD2;
//wire bus_inactive;
wire [9:0] headder;
wire en_evenTrig_frame ,updated_signal1,updated_signal2;
wire [9:0] data_byte_in,data_published;
wire data_valid_mem;

wire [9:0] data_byte_out;

wire [9:0] headder_in;
reg [9:0] saved_header;
wire sleep_cmd; 
wire master_req_rcv;
wire [1:0]FRAME_TYPE;
reg  [1:0] frame_type0;
wire [3:0] NAD1;
wire MASTER_SUB,MASTER_PUB;

wire S_read_from_mem,en_slv_operation,wake_cluster,SWR_en1,SWR_en11,SWR_en2,SWR_en10,SWR_en20;
wire [31:0] SWR_ADDR1,SWR_ADDR2,SWR_ADDR10, SWR_ADDR20, 
            SRD_ADDR10,SRD_ADDR20,SRD_ADDR2,SRD_ADDR1,
            SRD_data1,SRD_data2,SRD_data10,SRD_data20,
            SWR_data1,SWR_data2, SWR_data10,SWR_data20,
            RD_data2,start_addr1,start_addr2; 

wire  init_start0,init_finish0;
wire master_publisher,master_subscriber,error_ctrl; 
wire [7:0] status_resp,status_error;
wire collision_detected,SWR_en,MRW_en;
wire [9:0] data_byte0,data_byte2;
wire [31:0]SWR_data,SWR_ADDR,MWR_data; 
wire [3:0] MWR_ADDR;

wire master_req_rx;
wire [3:0] NAD_rx;
wire [63:0] OLD_DATA1,OLD_DATA2,old_data1,old_data2; 
wire data_valid,master_req_valid;
reg [7:0] count_inact;
reg bus_inactive;
wire bus_inactive0;
reg [3:0] counter; 
reg rx_header;
reg [9:0] header,data,data_temp;
reg [3:0] current_state,next_state; 

app_layer_slave1  TOP0   (clk,reset,INIT_START,INIT_FINISH,SLEEP_CMD,MASTER_REQ,MASTER_REQ_frame, FRAME_TYPE, NAD1,NAD2,
                        MASTER_PUB,MASTER_SUB,OLD_DATA1,OLD_DATA2,		
			SWR_en10,SWR_en20,SWR_ADDR10,SWR_ADDR20,                        
                        SWR_data10,SWR_data20,
			initial_NAD1,initial_NAD2,updated_signal1,updated_signal2,data_valid,master_req_valid);


Slave_controller Slave_top1 (clk,reset,headder,sleep_cmd,bus_inactive0,bus_error,en_slv_operation,S_read_from_mem,wake_cluster,init_start0,init_finish0,master_req_rx);
Slave_pub_rx Slave_top2 (clk,reset,initial_NAD1,status_headder1,status_error,master_publisher,en_slv_operation,S_read_from_mem,headder_in,start_addr1,RD_data2,SRD_data10,data_byte0,SRD_ADDR10,old_data1);
Slave_sub_rx Slave_top3(clk,reset,initial_NAD1,status_headder1,master_subscriber,en_slv_operation,headder_in,data_byte_in,status_error,MRW_en,MWR_ADDR,MWR_data,error_ctrl,collision_detected,sleep_cmd,NAD_rx,data_valid_mem,diagnostic_end);

data_memory slave_top4 (clk,reset,SWR_en1,SWR_data1,SWR_ADDR1,SRD_ADDR1,SRD_data1);
data_memory slave_top5 (clk,reset,SWR_en2,SWR_data2,SWR_ADDR2,SRD_ADDR2,SRD_data2);
event_trig_frame Master_TOP7 (clk,reset,en_evenTrig_frame ,updated_signal1,updated_signal2,data_byte0,data_byte2,data_published);

//--------------another slave publisher to detect collision---------------------------------------------------//
Slave_pub_rx Slave_top5 (clk,reset,initial_NAD2,status_headder2,status_error,master_publisher,en_slv_operation,S_read_from_mem,headder_in,start_addr2,RD_data2,SRD_data20,data_byte2,SRD_ADDR20,old_data2);

assign headder_in =header; 
assign data_byte_in = data;

/*always @(*) 
begin 
   if (!rx_header)
     header <= data_in; 

nd */


//--------------Initialization starts and finish-------------------------------------------//
assign INIT_START = init_start0;
assign INIT_FINISH = init_finish0;
//-----------------------------------------------------------------------------------------//

assign SLEEP_CMD = (sleep_cmd)? 1'b1:1'b0;  //when the slave node recieves sleep command from the master let the application layer knows and go to idle state
//------------------------------------------------------------------------------------------*/
assign bus_inactive0 = bus_inactive;

//-----when slave in sleep state and recives master request or (break header) set "master_req_rcv" to 1--------//
assign MASTER_REQ = master_req_rx;

//------------set the frame type to the app layer ----------------------------------------------//
assign FRAME_TYPE =(saved_header[6:1] == 6'h22 && header !== 10'h000 && header !== 10'h200 && header !== 10'h2aa )? 2'b10 : 
		   (saved_header[6:1] == 6'h3c && header !== 10'h000 && header !== 10'h200 && header !== 10'h2aa)? 2'b01  :  2'b00;

//assign FRAME_TYPE = frame_type0;
//----------when diagnostic request frame recieved set the NAD recv to the first data byte sent in the master request frame----//
assign NAD1 = NAD_rx;
//----------------in case of event triggered-------------------------------------------------// 
assign OLD_DATA1 = old_data1;
assign OLD_DATA2 = old_data2;
//---------------slave node is publisher or subscriber ---------------------------------------//
assign master_subscriber = (headder_in[6:1] == 6'h24 ||headder_in[6:1]== 6'h20||headder_in[6:1]==6'h22 ||headder_in[6:1]==6'h3d)? 1'b1:1'b0;    //master node is the subscriber of those frames
assign master_publisher = (headder_in[6:1]== 6'h23 || headder_in[6:1]== 6'h30 || headder_in[6:1]== 6'h3c )? 1'b1:1'b0; //master node is the publisher of those frames
assign MASTER_PUB = master_publisher; 
assign MASTER_SUB = master_subscriber;

//----------------Write to memory 1 and memory 2------------------------------------------------//
assign SWR_en1 = (INIT_START && !INIT_FINISH)? SWR_en10:(INIT_START && INIT_FINISH && FRAME_TYPE == 2'h2 )? SWR_en10:1'b0; 
assign SWR_en2 = (INIT_START && !INIT_FINISH)? SWR_en20:(INIT_START && INIT_FINISH && FRAME_TYPE == 2'h2 )? SWR_en20:1'b0;
assign SWR_data1= (INIT_START && !INIT_FINISH)? SWR_data10:(INIT_START && INIT_FINISH && FRAME_TYPE == 2'h2)?SWR_data10:32'hzzzzzzzz; 
assign SWR_data2= (INIT_START && !INIT_FINISH)? SWR_data20:(INIT_START && INIT_FINISH && FRAME_TYPE == 2'h2)?SWR_data20:32'hzzzzzzzz; 
assign SWR_ADDR1= (INIT_START && !INIT_FINISH)? SWR_ADDR10:(INIT_START && INIT_FINISH && FRAME_TYPE == 2'h2)?SWR_ADDR10:32'hzzzzzzzz; 
assign SWR_ADDR2= (INIT_START && !INIT_FINISH)? SWR_ADDR20:(INIT_START && INIT_FINISH && FRAME_TYPE == 2'h2)?SWR_ADDR20:32'hzzzzzzzz; 

//------------------application layer read from memory--------------------------------------------//
assign SRD_ADDR1 = SRD_ADDR10;
assign SRD_ADDR2 = SRD_ADDR20; 
assign SRD_data10=  SRD_data1; 
assign SRD_data20= SRD_data2;

//--------------------in case of slave publisher-------------------------------------------------//
assign start_addr1 =(FRAME_TYPE == 2'h0 && !master_publisher)? 32'h2  :(FRAME_TYPE == 2'h1 && !master_publisher && master_req_valid)? 32'h4 :(FRAME_TYPE == 2'h1 && !master_publisher && !master_req_valid)? 32'h6
                                                                      : (FRAME_TYPE == 2'h2 && !master_publisher && updated_signal1)? 32'h0:32'hzzzzzzzz;
assign start_addr2 =(FRAME_TYPE == 2'h2&& !master_publisher && updated_signal2 )? 32'h0:32'hzzzzzzzz;


assign data_byte_out =(en_evenTrig_frame && updated_signal1 && updated_signal2 && data_in !== 10'h000)? data_published : 10'hzzz;// (en_evenTrig_frame && updated_signal1 && data_in!== 10'h000)? data_byte0 :(en_evenTrig_frame && updated_signal2 && data_in !== 10'h000)? data_byte2:data_byte0;
assign data_byte_out =(!en_evenTrig_frame )? data_byte0 : 10'hzzz;


assign status_resp1 = status_error;
assign en_evenTrig_frame =(FRAME_TYPE == 2'h2 & header !== 10'h000 && header !== 10'h200 && header !== 10'h2aa)? 1'b1:1'b0; 

//(en_evenTrig_frame &&updated_signal1 &&updated_signal2)? data_published: 
/*assign SRD_ADDR1 =( S_read_from_mem && !master_publisher) ? SRD_ADDR10: 32'hzzzzzzzz ;
assign SRD_ADDR2 =( S_read_from_mem && !master_publisher) ? SRD_ADDR20: 32'hzzzzzzzz ;
assign SRD_data1 = (S_read_from_mem && !master_publisher)? SRD_data10: 32'hzzzzzzzz ;
assign SRD_data2 = (S_read_from_mem && !master_publisher)? SRD_data20: 32'hzzzzzzzz ;
assign start_addr1 =(en_evenTrig_frame && updated_signal1)? 32'h0: 32'h0;
assign start_addr2= (en_evenTrig_frame && updated_signal2)? 32'h0:32'h0;*/
assign status_resp1 = status_error;
assign en_evenTrig_frame =(FRAME_TYPE == 2'h2)? 1'b1:1'b0; 

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


/*always @(posedge clk)begin 
     
     
                   //counter <= 4'h0;
                  
                  if( 4'h0 <= counter <= 4'h2)
                      header <= data_in; 
        
                 else if( 4'h2 < counter < 4'hc) 
                     data <= data_in;
                     
      
      


end 

always @(posedge clk or negedge reset) 
begin 
         if(!reset) begin 
          counter <=0; 
          //header <= data_in;
           end 
       else  if(en_slv_operation) begin
         counter <= counter+1; 
             
                if(counter == 4'hc) 
                   counter <= 4'h0;
                  
                 /*else if( 4'h0 <= counter <= 4'h2)
                      header <= data_in; 
        
                 else if( 4'h2 < counter < 4'hc) 
                     data <= data_in;
                     
       end 
end */

always @(posedge clk or negedge en_slv_operation ) 
begin 
       if(!en_slv_operation)begin  
      header<= data_in; 
      next_state <= d0;
      saved_header <= 10'h000;
     
     end
      else  begin
            case (next_state) 

          d0: begin  
          if(data_in == 10'h000) begin 
			header <= data_in;
			next_state <= d1;			
			
			//data_temp <= data_in;
		end
	  else begin
	        next_state <= d0;
           header <= data_in;
            
           end
 	  end

          d1: begin 
		if(data_in == 10'h200) begin 
			header <= data_in;
			next_state <= d2;			
			
			//data_temp <= data_in;
		end
	  else begin 	
	   data <= data_temp;
           data_temp <= data_in;
            next_state <= d14;
	  end 
	    
 	  end
 
          d2:  begin 
			
           header <= data_in;
            next_state <= d3;
	    
 	  end

          d3:  begin 
           header <= data_in;             
            next_state <= d4;
	    saved_header <= data_in;

 	  end

          d4: begin 
           data <= data_in;
            next_state <= d5;
 	  end
 
          d5: begin 
           data <= data_in;
            next_state <= d6;
 	  end

          d6: begin 
           data <= data_in;
            next_state <= d7;
 	  end

          d7: begin 
           data <= data_in;
            next_state <= d8;
 	  end

          d8: begin 
		if(data_in == 10'h000) begin 
			next_state <= d1;			
			header <= data_in;
			data_temp <= data_in;

		end
		
	  else begin 
           data <= data_in;
            next_state <= d9;
	       end
 	  end

          d9: begin 
		if(data_in == 10'h000) begin 
			next_state <= d1;			
			header <= data_in;
			data_temp <= data_in;

		end
		else begin 
           data <= data_in;
            next_state <= d10;
                end
 	  end

          d10: begin 
			if(data_in == 10'h000) begin 
			next_state <= d1;			
			header <= data_in;
			data_temp <= data_in;

		end
	  else begin
           data <= data_in;
            next_state <= d11;
 	  end
	end 
          d11: begin  
			if(data_in == 10'h000) begin 
			next_state <= d1;			
			header <= data_in;
			data_temp <= data_in; end
	else begin
           data <= data_in;
            next_state <= d12;
 	  end
	end
          d12:begin
  		if(data_in == 10'h000) begin 
			next_state <= d1;			
			header <= data_in;
			data_temp <= data_in;
		end
	else begin
           data <= data_in;
            next_state <= d13;
 	  end 
	end

	 d13:begin 
           if(data_in == 10'h000) begin 
			next_state <= d1;			
			header <= data_in;
			data_temp <= data_in;
	  end 
	else begin
           data <= 10'hzzz;
            next_state <= d14;
 	  end 
 	  end

	d14:begin 
           data <= 10'hzzz;
            next_state <= d0;
 	  end

	 d15:begin 
            data <= data_temp;
           
           if(data_in == 10'h000) begin
		header <= data_in;
		next_state <=d1;
               end
        
          else begin 
            data_temp <= data_in;
            next_state <= d13;
 	  end
         end
          default:next_state <=d0;
       endcase 



          
     end 
end

/*always @(posedge clk ) 
begin 
     if (data_in == 10'h000 || data_in ==10'h200 || data_in == 10'h2aa) begin
       counter <= counter +1;
       rx_header <= 1'b0;
     if (counter == 4'h3) begin
       rx_header <= 1'b1;
       counter <= 4'h0;

    end 
      //else rx_header <= 1'b0;
    end 
     else counter <= 4'h0; 


end*/

endmodule
