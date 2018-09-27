module Slave_pub_rx (clk,reset,NAD,status_headder,status_error,master_publisher,en_slv_operation,S_read_from_mem,headder,start_addr,RD_data2,SRD_data,data_byte,SRD_ADDR,OLD_DATA);

parameter INACTIVE = 20;    //to count inactivity of the publisher 
parameter [9:0] BREAK_BITS = 10'h000;

input clk,reset;
input [3:0] NAD ;  
input [5:0] status_headder;  //status headder is defined for each slave to handle the error
input [7:0] status_error;    //status error sent from the subscriber of the previous frame
input master_publisher;      //to know if the publisher is the slave task of master node or slave task of slave node
input en_slv_operation;      //enable slave operation
input S_read_from_mem;       //when the initialization of the slave is finished the slave should be able to read the data from memory
input [31:0] start_addr;     //the first address of the memory that the slave will start reading data from
input [9:0] headder;         //headder sent from headder creation module and used here to check for parity and break ,synch field
input [31:0] RD_data2;       //data read from schedule table when the master node is the publisher of the frame
input [31:0] SRD_data;       //the data read from the memory of the slave node

output reg [9:0] data_byte;  //data sent on the bus
output reg [31:0] SRD_ADDR;  //address to slave memory 
output reg  [63:0] OLD_DATA;  //in case of event triggered frame save the old data to check if there is an updated signal
  
reg [7:0] status_resp; //response to the status headder (for error handling) is recieved from the subscriber to the status headder
parameter [3:0] d1=4'h0,d2=4'h1,d3=4'h2,d4=4'h3,d5=4'h4,d6=4'h5,d7=4'h6,d8=4'h7,d9=4'h8,d10=4'h9,d11=4'ha,d12=4'hb;
reg [3:0] current_state,next_state;

	
reg [7:0] count_inact;
reg [79:0] data_field;
reg [31:0] RD_ADDR_temp;
reg [31:0] first_data,second_data,third_data;
wire [79:0] data_field0;
wire [9:0] checksum_op;
wire [9:0] new_rx_data;
wire [1:0] rx_parity_op; 
wire PID_chkd,PID_known,PID_unknown,brkSync_error; 
wire [9:0] headder_data;
wire [9:0] rx_data;
wire WR_en;
wire slave_type = 1'b1;                                    //publisher type =1   subscriber type =0 


brk_sync_det B1 (clk,reset,headder,en_slv_operation,brkSync_error,brk_seq_chkd); //detect the brk field and synchronization field 
PID_detector PD1  (clk,reset,en,slave_type,NAD,new_rx_data,PID_known,PID_unknown,frame_type); //detect the PID by reading the Slave ROM if the PID is saved PID_known flag = 1
rx_parity_check RPC (new_rx_data,clk,reset,rx_parity_op,PID_chkd); //when recieving the PID symbol compute the parity then compare it with parity bits 
checksum chk (data_field0,clk,reset,checksum_op); 	//combinational module to compute the checksum whenever the data_field (8 bytes) are presented 



assign data_field0 = data_field;
assign new_rx_data = (headder !== 10'h000 && headder !== 10'h2aa && headder !== 10'h200 && brk_seq_chkd) ?  headder_data:10'hzzz; 
assign headder_data = headder; 
//data of the unconditional frame 6'h25 associated the the unconditional frame




always@(posedge clk or negedge reset) 
begin 

	if(!reset) 
 	  begin

 		data_byte <=10'hzzz; 		
                 SRD_ADDR <= start_addr; 
                 current_state <= d1;
		
       end
              else 
		 current_state <= next_state;
		
            
end

always@(posedge clk) 
begin 

         if(new_rx_data[6:1]==6'h25)
	 OLD_DATA <= { data_field [78:71],data_field [68:61],data_field [58:51],data_field[48:41] ,data_field [38:31],data_field [28:21],data_field [18:11],data_field [8:1] };
       
	else 
	OLD_DATA <='z;



end

 always @(posedge clk) 
begin 
         if(headder[6:1] == status_headder)
      status_resp <= status_error; //copy the status error recieved from the subscriber to status response to be published on the bus

end


always @(*)begin

if (en_slv_operation && S_read_from_mem) begin 
   if (PID_known==1'b1 && PID_chkd==1'b1)  begin 
   
     //when the publisher is the slave node and the data published is normal data not status response
      if (!master_publisher && new_rx_data[6:1] !== status_headder  && new_rx_data[6:1] !== 6'h22) begin 
     
     

		case (current_state)
     
				d1: begin  
					next_state <= d2;
					SRD_ADDR <= start_addr;
					data_byte =  {1'b1 ,SRD_data[7:0],1'b0};
					data_field [9:0] = data_byte; 		
					end 
					
				d2: begin 
					next_state <= d3;
					data_byte =  {1'b1 ,SRD_data[15:8],1'b0};
					data_field [19:10] = data_byte;		 
					end 

				d3: begin 
					next_state <= d4;
					data_byte =  {1'b1 ,SRD_data[23:16],1'b0};
					data_field [29:20] = data_byte;
					 
					end 

				d4: begin 
					next_state <= d5;
					data_byte =  {1'b1 ,SRD_data[31:24],1'b0};
					data_field [39:30] = data_byte;
				        SRD_ADDR <= start_addr +1;           				
					end  
					
				d5: begin 
					next_state <= d6;
					data_byte =  {1'b1 ,SRD_data[7:0],1'b0};
					data_field [49:40] = data_byte; 
					next_state <= d6;
					end  
					
				d6: begin 
					next_state <= d7;
					data_byte =  {1'b1 ,SRD_data[15:8],1'b0};
					data_field [59:50] = data_byte;            
					//SRD_ADDR <= SRD_ADDR +1;
					end  

				d7: begin 
					next_state <= d8;
					data_byte =  {1'b1 ,SRD_data[23:16],1'b0};
					data_field [69:60] = data_byte;              	       
					end
					
				d8: begin 
					next_state <= d9;
					data_byte =  {1'b1 ,SRD_data[31:24],1'b0};
					data_field [79:70] = data_byte;                     
					end 
   
				d9: begin 
					next_state <= d10;
					data_byte <=  checksum_op;	   
					end 


				
				d10: begin 
					next_state <= d11;
					data_byte <=  10'hzzz;	   
					end 

				
				d11: begin 
					next_state <= d1;
					data_byte <=  10'hzzz;	   
					end 

				default : begin 
                  next_state <= d1;
                  data_byte <= 10'hzzz;
					end
		endcase 
	   end
  
    //when the publisher is the master node and the data published is normal data not the status reponse 

	     else if (master_publisher  && new_rx_data[6:1] !== status_headder && new_rx_data[6:1] !== 6'h22) begin 
			case (current_state)
     
				d1: begin 
					next_state <= d2;
					first_data <= RD_data2;
					data_byte =  {1'b1 ,RD_data2[15:8],1'b0};
					data_field [9:0] = data_byte;		
					end 
					
				d2: begin 
					next_state <= d3;
					second_data  <= RD_data2;
					data_byte =  {1'b1 ,first_data[23:16],1'b0};
					data_field [19:10] = data_byte;
					end 
					
				d3: begin 
					next_state <= d4;
                    third_data <= RD_data2;
					data_byte =  {1'b1 ,first_data[31:24],1'b0};
					data_field [29:20] = data_byte; 
					end  
					
				d4: begin 
					next_state <= d5;
					//third_data <= RD_data2;
					 if(first_data[5:0] == second_data[5:0]) begin 
					data_byte =  {1'b1 ,second_data[15:8],1'b0};
					data_field [39:30] = data_byte;
						end 
					else next_state <= d12;
  		
					end  
					
				d5: begin 
					next_state <= d6;
					data_byte =  {1'b1 ,second_data[23:16],1'b0};
					data_field [49:40] = data_byte; 
					end  
					
				d6: begin 
					next_state <= d7;
					data_byte <=  {1'b1 ,second_data[31:24],1'b0};
					data_field [59:50] = data_byte; 
					end
					
				d7: begin 
					next_state <= d8; 
					 if(second_data[5:0] == third_data[5:0]) begin 
					data_byte =  {1'b1 ,third_data[15:8],1'b0};
					data_field [69:60] = data_byte;
						end 
					else next_state <= d12;					       
					end
					
				d8: begin 
					next_state <= d9; 
					data_byte =  {1'b1 ,third_data[23:16],1'b0};
					data_field [79:70] = data_byte;          
					end 
   
				d9: begin 
					next_state <= d10;
					data_byte <=  checksum_op;
					end 
					
				d10: begin 
					next_state <= d11;
					data_byte <=  10'hzzz;
					end 

				d11: begin 
					next_state <= d1;
					data_byte <=  10'hzzz;
					end 
		

                 d12: begin
		 			next_state <= d12;
					data_byte <=  10'hzzz;
					end
				
				default : next_state <= d1;
			endcase 
		end 

//-------------------------EVENT TRIGGERED FRAME---------------------------------------------------------------//
   	     else if (!master_publisher  && new_rx_data[6:1] !== status_headder && new_rx_data[6:1] == 6'h22 && headder !== 10'h000) begin 
			SRD_ADDR = start_addr;
					
		   data_byte <=  {1'b1 ,SRD_data[7:0],1'b0};
		
 	    end


//--------when the PID recieved is that of the status_headder only send the status reponse recieved from t
	   

         else if (new_rx_data [6:1] == status_headder) begin
			//data_byte <= {1'b1,status_error,1'b0};
			case (current_state)
     
				d1: begin  
					next_state <= d2;
					
					data_byte <= {1'b1,status_resp,1'b0};
							
					end 
					
				d2: begin 
					next_state <= d3;
					data_byte <= {1'b1,status_resp,1'b0};	 
					end 

				d3: begin 
					next_state <= d4;
					data_byte <= {1'b1,status_resp,1'b0};
					 
					end 

				d4: begin 
					next_state <= d5;
					data_byte <= {1'b1,status_resp,1'b0};         				
					end  
					
				d5: begin 
					next_state <= d6;
					data_byte <= {1'b1,status_resp,1'b0}; 
					next_state <= d6;
					end  
					
				d6: begin 
					next_state <= d7;
					data_byte <= {1'b1,status_resp,1'b0};         
					//SRD_ADDR <= SRD_ADDR +1;
					end  

				d7: begin 
					next_state <= d8;
					data_byte <= {1'b1,status_resp,1'b0};             	       
					end
					
				d8: begin 
					next_state <= d9;
					data_byte <= {1'b1,status_resp,1'b0};                     
					end 
   
				d9: begin 
					next_state <= d10;
					data_byte <= {1'b1,status_resp,1'b0};	   
					end 
				d10: begin 
					next_state <= d10;
					data_byte <=  10'hzzz;	   
					end 
		
				d11: begin 
					next_state <= d1;
					data_byte <=  10'hzzz;	   
					end

				default : begin 
                    next_state <= d1;
                    data_byte <= 10'hzzz;
					end
			
			
		endcase	
	
   end
   
  end    
 	 
   else begin          //else if the PID is unkown or parity is not checked 
        next_state <= d1;
        data_byte <=10'hzzz;
        SRD_ADDR <= start_addr;
                            
   end

    end
  	else  begin
        next_state <= d1;
        data_byte <=10'hzzz;
        SRD_ADDR <= start_addr;

      end 

	
    
    
end 

endmodule 
