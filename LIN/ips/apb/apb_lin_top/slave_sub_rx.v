
module Slave_sub_rx (clk,reset,NAD,status_headder,master_subscriber,en_slv_operation,headder_in,data_in,status_error,MWR_en,MWR_ADDR,MWR_data,error_ctrl,collision_detected,sleep_cmd,NAD_rcv,data_valid_mem,diagnostic_end );
//parameter INACTIVE = 30;
parameter [5:0] UNCOND_FRAME1=6'h25, UNCOND_FRAME2=6'h26;
input clk,reset;
input [3:0] NAD; 
input [5:0] status_headder;
input master_subscriber;
input en_slv_operation;    
input [9:0] headder_in,data_in;

output reg [7:0] status_error;	     //save the status error of the current frame when any error occured and send it to the publisher to publisher the status response
output reg MWR_en;	
//SWR_ADDR,SWR_data;     //write data to memory
output reg [3:0] MWR_ADDR;
output reg [31:0] MWR_data; 
output reg collision_detected;
output reg error_ctrl;
output reg sleep_cmd;
output [3:0] NAD_rcv; 
output reg data_valid_mem;
output reg diagnostic_end;

reg [31:0] mem_model [255:0];       //memory to write data recieved 
reg [3:0] MWR_ADDR_temp; 

reg [9:0]  data_symb1,data_symb2,data_symb3,data_symb4,data_symb5,data_symb6,data_symb7,data_symb8,data_symb9;
reg [7:0] count_inact2;
wire en,brkSync_error,brk_seq_chkd; 
wire checksum_error,checksum_chkd,PID_known,PID_unknown;
reg [3:0] current_state,next_state ;
wire [9:0] data_byte0,data_byte;
wire [9:0] new_rx_data;
wire [89:0] data_field;
wire PID_chkd;
wire slave_type = 1'b0;
wire [1:0] rx_parity_op;
wire [39:0] data_field1,data_field2;
reg [79:0] data_saved;






brk_sync_det S_BD (clk,reset,headder_in,en_slv_operation,brkSync_error,brk_seq_chkd); 
PID_detector PD (clk,reset,en,slave_type,NAD,new_rx_data,PID_known,PID_unknown,frame_type);
rx_parity_check RPC (new_rx_data,clk,reset,rx_parity_op,PID_chkd);
rx_checksum R_chk(data_field,  checksum_chkd , checksum_error); 

parameter [3:0] d1=4'b0000,d2=4'b0001,d3=4'b0010,d4=4'b0011,d5=4'b0100,d6=4'b0101,d7=4'b0110,d8=4'b0111,d9=4'b1000,d10=4'b1001,d11=4'b1010;


assign new_rx_data = (headder_in !== 10'h000 && headder_in !== 10'h2aa && headder_in !== 10'h200 && brk_seq_chkd) ? headder_in :10'hz; 
assign data_field1 [39:0] = { data_symb4,data_symb3,data_symb2,data_symb1};
assign data_field2 [39:0] = {data_symb8,data_symb7,data_symb6,data_symb5};
assign data_field [89:0] = {data_symb9,data_saved};
assign NAD_rcv = (!master_subscriber && headder_in[6:1] == 6'h3c)? data_symb1: 4'hz; 
      

    
    always @(posedge clk or negedge reset) 
 begin  
     if(! reset) 
       begin 
         current_state <= d1;
 	status_error<=0;
 	collision_detected <= 1'b0 ;
 	MWR_ADDR_temp <= 0;
 	//MWR_ADDR <= 4'h0;
 	MWR_data <=32'h0;
 	MWR_en <= 0;
 	data_valid_mem <= 1'b0;
 	diagnostic_end <=1'b0;
         //SWR_en <=0; 
         //SWR_ADDR <= 32'h80;
       end   

      else if (en_slv_operation) 
       current_state <= next_state;        
end
    
    always @(posedge clk) 
begin 
//-----------in case the subscriber is the SLAVE node and it recieves any frame except the status headder ,it should save the status error of the frame---------------//
         if(!master_subscriber && new_rx_data[6:1] !== status_headder && headder_in !== 10'h000 && headder_in !== 10'h200 && headder_in !== 10'h2aa)
      status_error <= {checksum_error,~PID_chkd,brkSync_error};
         

//-----------in case the subscriber is the MASTER node and it recieves the status headder it should read the status response that was published by the slave node-----//     
           else if (new_rx_data[6:1] == status_headder && master_subscriber ) begin 
        		if( data_symb2[1]|data_symb2[2]| data_symb2[3]| data_symb2[4]|data_symb2[5] == 1'b1) 
                          error_ctrl = 1'b1; 
                        else 
                          error_ctrl =1'b0;
      
        end 
                        

end
//-------------------in case master node is subscriber to any frame and recieves an error------------------------//
always @(*) begin 
	    if ( master_subscriber && new_rx_data[6:1] !== status_headder ) begin 
                if(status_error [0] | status_error [1] | status_error [2] == 1'b1)
                          error_ctrl = 1'b1; 
                        else 
                          error_ctrl =1'b0;
      
        end
end
//the slave task of the master node is the subscriber of the event triggered frame 
  always @(posedge clk) 
begin 
     if(headder_in[6:1] == 6'h22 && master_subscriber) begin
	case (data_in) 
                {1'b1,1'b0,1'b0,UNCOND_FRAME1,1'b0} 		: collision_detected <= 1'b0;     		     // {1'b1,00_100101,1'b0}  first PID of 6'h25 is published on the bus
		{1'b1,1'b0,1'b0,UNCOND_FRAME2,1'b0}		:  collision_detected <= 1'b0;                      // {1'b1,00_ 100110,1'b0}  2nd PID of 6'h26 is published on the bus	
                {1'b1,1'b0,1'b0,UNCOND_FRAME1 & UNCOND_FRAME2,1'b0}:  collision_detected <= 1'b1;   // {1'b1, (00_100101 && 00_ 100110) , 1'b0} the anding of the 2 PIDs that means collision is detected
		default: collision_detected <= 1'b0 ;	  					
	endcase
   end
      
end 

/*always @(posedge clk) 
begin
	if(headder_in !==BREAK_BITS) begin
      count_inact2 <= count_inact2 +1;
           if(count_inact2 == INACTIVE) 
              not_subscriber <= 1'b1;
           else 
	     not_subscriber <= 1'b0;	              
 
       end
       else 
      count_inact2 <= 0;
end*/

     always @(current_state or PID_known or PID_chkd or data_in) 
begin 

  
  if(PID_known && PID_chkd) begin 
    if (!master_subscriber && new_rx_data[6:1] !== 6'h3c) begin //subscriber is the slave node and is receiving normal frame

     //SWR_en <=1'b1;
       MWR_en <= 0;
 case (current_state)
    d1:begin data_symb1 <= data_in;
        next_state <=d2;      
	//SWR_ADDR<=32'h9;
       end
    d2:begin data_symb2 <= data_in;
        next_state <=d3;
	end
    d3: begin data_symb3 <= data_in;
        next_state <=d4;
	end
    d4: begin data_symb4 <= data_in;
        next_state <=d5;                
	end 
    d5: begin data_symb5 <= data_in;
        next_state <=d6;
        //SWR_data [31:0] <= { data_field1 [38:31],data_field1 [28:21],data_field1 [18:11],data_field1 [8:1] } ;
	//SWR_ADDR <= SWR_ADDR +1;
        end 
    d6: begin data_symb6 <= data_in;
        next_state <=d7;
	end  
    d7: begin data_symb7 <= data_in;
        next_state <=d8;
	end
    d8: begin data_symb8 <= data_in;
        next_state <=d9;
 
	end
    d9: begin data_symb9 <= data_in;
        next_state <=d1;
        data_saved <= {data_field2,data_field1};
      //SWR_data [31:0] <= { data_field2 [38:31],data_field2 [28:21],data_field2 [18:11],data_field2 [8:1] } ;
	end      
	default : next_state <= d1;
    endcase
   
  end 
  
    else if (master_subscriber) begin 
     MWR_en <=1'b1;
     
     MWR_ADDR<=MWR_ADDR_temp;
     //MWR_data [8:1] <= headder_in;
 case (current_state)
     d1: begin 
     
     
       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
       
       
     next_state <= d2;
      data_valid_mem <= 1'b0;
        
		end
   
     d2:begin data_symb1 <= data_in;
     
            if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
		
     data_valid_mem <= 1'b0;
        next_state <=d3;
       
      // MWR_data [7:0] <= headder_in[8:1];
       end
    d3:begin data_symb2 <= data_in;
    
			       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
       
        next_state <=d4;
        data_valid_mem <= 1'b0;
	end
    d4: begin data_symb3 <= data_in;
			       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
    
        next_state <=d5;
        data_valid_mem <= 1'b0;
	end
    d5: begin data_symb4 <= data_in;
    
			       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
       
        next_state <=d6; 
        MWR_ADDR_temp <= 0;
        data_valid_mem <= 1'b0;
        //MWR_ADDR_temp <= MWR_ADDR_temp+1;
         //MWR_en <=1'b1;               
	end 
    d6: begin data_symb5 <= data_in;
    
			       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
       
        next_state <=d7;
        
        //MWR_ADDR = 4'h0;
        MWR_data [31:0] <= {data_symb3[8:1],data_symb2[8:1],data_symb1[8:1],headder_in[8:1] };
        data_valid_mem <= 1'b0;
	
        end 
    d7: begin data_symb6 <= data_in;
			       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
       
        next_state <=d8;
        MWR_ADDR_temp <= MWR_ADDR_temp+1;
        data_valid_mem <= 1'b0;
	//MWR_ADDR <= MWR_ADDR +1;
	end  
    d8: begin data_symb7 <= data_in;
			       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
       
        next_state <=d9;
        //MWR_ADDR_temp <= MWR_ADDR_temp+1;
        //MWR_ADDR = MWR_ADDR +1;
	 MWR_data [31:0] <= {data_symb6[8:1],data_symb5[8:1],data_symb4[8:1],headder_in[8:1]};
       data_valid_mem <= 1'b0;

	end
    d9: begin data_symb8 <= data_in;
			       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b0;end
        next_state <=d10;
           MWR_ADDR_temp <= MWR_ADDR_temp+1;
           data_valid_mem <= 1'b0;
	end
    d10: begin data_symb9 <= data_in;
    
			       if(new_rx_data[6:1] == 6'h3d) begin
       diagnostic_end <=1'b1;end
       
        next_state <=d1;
		data_saved <= {data_field2,data_field1};
	    //MWR_ADDR = MWR_ADDR +1;
        MWR_data [31:0] = {data_symb8[8:1],data_symb7[8:1],headder_in[8:1] };
        MWR_en <=1;
        data_valid_mem <= 1'b1;
        //MWR_ADDR_temp <= 0;
        //MWR_ADDR <= 4'h0;
        //MWR_ADDR_temp <= MWR_ADDR_temp+1;
	end  
	
	/*d11: begin
	MWR_ADDR_temp <= MWR_ADDR_temp+1;
	next_state <=d1;
	
	end  */  
	default : next_state <= d1;
    endcase
    
   
 
  end 

  else if (!master_subscriber && new_rx_data [6:1] == 6'h3c) begin 
   MWR_en <= 0;
 
 case (current_state)
    d1:begin  if(data_in[8:1] == 8'h00)
         next_state <=d2;
              else data_symb1 <= data_in;
       end
    d2:begin if(data_in[8:1] == 8'hff)
        next_state <=d3;
              else data_symb2 <= data_in;
	end
    d3: begin if (data_in[8:1] == 8'hff)
         next_state <=d4;
              else data_symb3 <= data_in;
	end
    d4: begin if (data_in[8:1] == 8'hff)
         next_state <=d5;  
		else data_symb4 <= data_in;             
	end 
    d5: begin if(data_in[8:1] == 8'hff)
        next_state <=d6;
		else data_symb5 <= data_in;
        end 
    d6: begin if (data_in[8:1] == 8'hff)
        next_state <=d7;
		else data_symb6 <= data_in;
	end  
    d7: begin  if (data_in[8:1] == 8'hff)
        next_state <=d8;
		else data_symb7 <= data_in;
	end
    d8: begin if(data_in[8:1] == 8'hff) begin 
        next_state <=d9;
	sleep_cmd <= 1'b1;
              end 
                else data_symb8 <= data_in;
	end
    d9: begin 
        next_state <=d1;
    
	end      
	default : next_state <= d1;
    endcase
   
    
  end 
         else  begin
        	next_state <= d1; 
        	MWR_en <= 0;    
            end 
 	end
            else  begin
        	next_state <= d1; 
        	MWR_en <= 0;    
            end 
 
end
endmodule

           


