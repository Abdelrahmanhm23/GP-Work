module app_layer_slave1 (clk,reset,INIT_START,INIT_FINISH,SLEEP_CMD,MASTER_REQ,MASTER_REQ_frame, FRAME_TYPE, NAD1,NAD2,
                        master_publisher,master_subscriber,OLD_DATA1,OLD_DATA2,			
			SWR_en1,SWR_en2,SWR_ADDR1,SWR_ADDR2,SWR_data1,SWR_data2,
			initial_NAD1,initial_NAD2,updated_signal1,updated_signal2, DATA_VALID,MASTER_REQ_VALID);
 
 parameter [63:0] NEW_DATA1=64'h12345612345625, 
                  NEW_DATA2= 64'h12345612345626;

 
input clk,reset;
input INIT_START;             //when initialization starts
input INIT_FINISH;            //when initialization is done
input master_publisher;       //=1 when master is publisher and =0 when slave is publisher
input master_subscriber;     // =1 when master is subscriber and =0 when slave is subscriber
input [63:0] OLD_DATA1,OLD_DATA2;
input SLEEP_CMD;             //sleep Command recieved during operational state
input MASTER_REQ;            //header received 
input MASTER_REQ_frame;     //master request frame during diagnostics
input [1:0] FRAME_TYPE;     //to know if the frame is unconditional , event triggered or diagnostic 
input [3:0] NAD1,NAD2;           //NAD of slave node (which was initial NAD) to compare it with NAD recieved in the request frame




output reg SWR_en1,SWR_en2;
output reg [31:0] SWR_ADDR1,SWR_ADDR2;     //write address to write data to memory
output  [31:0] SWR_data1,SWR_data2;     //write data to memory
output reg [3:0] initial_NAD1,initial_NAD2;  //initial NAD set during initialization
output reg updated_signal1,updated_signal2;
output reg MASTER_REQ_VALID;
output DATA_VALID;

parameter [2:0] init=3'b000,       //initialization state
				operation=3'b001, //operational state when the node starts transmitting or recieving frames
				idle =3'b010,    //when the node is not either transmitting or recieving frames (sleep state)
				RX_REQ =3'b011,  //in case of diagnostics  when the node received frame request
				TX_RESP=3'b100;  //in case of diagnostics when the node starts transmitting physical response

wire req_done,resp_done; 			
reg [1:0] current_state,next_state;
reg [31:0] SWR_ADDR_temp1,SWR_ADDR_temp2;
reg [3:0] counter_req ,counter_resp ;
wire [31:0] addr0,addr1,data1,data2;



slave_RAM mem (addr0,addr1, data1,data2); 

assign SWR_data1 = (INIT_START && !INIT_FINISH)? data1 : (FRAME_TYPE == 2'h2 && updated_signal1 && SWR_ADDR1 == 1'b0 )? NEW_DATA1[31:0] :(FRAME_TYPE == 2'h2 && updated_signal1 && SWR_ADDR1 == 1'b1 )? NEW_DATA1[63:32] :32'hzzzzzzzz; 
assign SWR_data2 = (INIT_START && !INIT_FINISH)? data2 : (FRAME_TYPE == 2'h2 && updated_signal2 && SWR_ADDR2 == 1'b0 )? NEW_DATA2[31:0] :(FRAME_TYPE == 2'h2 && updated_signal2 && SWR_ADDR2 == 1'b1 )? NEW_DATA2[63:32] :32'hzzzzzzzz;
assign addr0 = SWR_ADDR1;
assign addr1 = SWR_ADDR2; 
assign req_done = (counter_req == 4'h7)? 1'b1:1'b0;
assign resp_done = (counter_resp == 4'h7)? 1'b1:1'b0;
//assign  DATA_VALID =(SWR_ADDR_temp2 == 32'h2 && FRAME_TYPE == 2'h2)? 1'b1 : 1'b0;

always @(posedge clk or negedge reset) 
	begin 
	   if(!reset) begin
	      		
		 next_state <= init; 
		 counter_req <= 4'h0; 
		 counter_resp <= 4'h0;
		 SWR_ADDR_temp1 <= 32'h0;
		 SWR_ADDR_temp2 <= 32'h0;

	  end 	
	  else begin
		
   	
           case (next_state) 
           init:
				begin 
					if(INIT_START && !INIT_FINISH) begin
                        next_state <= init; 
						SWR_ADDR1 = SWR_ADDR_temp1 ;
						SWR_ADDR2 = SWR_ADDR_temp2 ;
						SWR_en1 <= 1'b1;
						SWR_en2 <= 1'b1;
						                     
					    initial_NAD1 <= 4'h1;
						initial_NAD2 <= 4'h2;
						SWR_ADDR_temp1 <= SWR_ADDR_temp1+1;
						SWR_ADDR_temp2 <= SWR_ADDR_temp2+1;
						
					end
					
					else if (INIT_START && INIT_FINISH) begin
						next_state <= operation;
						SWR_en1 <= 1'bz;
						SWR_en2 <= 1'bz;
						SWR_ADDR_temp1 <= 32'h0;
						SWR_ADDR_temp2 <= 32'h0;
                          
					 end 
				end
	
             


          operation: 
                 begin
				 
				     
					if(SLEEP_CMD)  //if the slave received sleep request frame from the master node 
					  next_state <= idle;
					  
					  
					else begin
				   
				      next_state <= operation;
					  																
                          case (FRAME_TYPE) 
                    
					   //unconditional frame when the slave node 1 is the publisher or subscriber
					   
                      2'b00: begin 
					   
							if(!master_publisher) //this means that the publisher is the slave node and needs to read data from memory
								SWR_en1 <= 1'b0;
			
							else  //not subscriber nor publisher					   
								SWR_en1 <= 1'bz;
					   
				end
					   
					  //diagnostic frame
					  
                     2'b01: begin 
					 
					        if(MASTER_REQ_frame && NAD1 == initial_NAD1) begin
							    
			                                       next_state <= RX_REQ; 
								 SWR_en1 <= 1'b0;
							         MASTER_REQ_VALID <= 1'b1;
								 
								 
							end	 
								
							else if (MASTER_REQ_frame && NAD1 !== initial_NAD1) begin
					              next_state <= operation;	
						          SWR_en1 <= 1'b0;	
							  MASTER_REQ_VALID <= 1'b0;	  
					   
					        end
				end 
					 
					  //event_triggered frame 
                       2'b10: begin
			

							if(OLD_DATA1[31:0] == NEW_DATA1 [31:0])begin
 							   
							    if(OLD_DATA1 [63:32] == NEW_DATA1 [63:32])begin 
									   updated_signal1 <= 1'b0;
									   SWR_en1 <= 1'b0;
									 
									   
                                    		           end 									   
							   else begin 
					                   updated_signal1 <= 1'b1;
							   SWR_en1 <= 1'b1;
							   SWR_ADDR1 = SWR_ADDR_temp1;
							   SWR_ADDR_temp1 = SWR_ADDR_temp1 +1; 
									                   if(SWR_ADDR_temp1 == 32'h3)
										             SWR_ADDR_temp1 = 32'h0;
							   end	
							end
							else begin 
							        updated_signal1 <= 1'b1; 
								SWR_en1 <= 1'b1;
								SWR_ADDR1 = SWR_ADDR_temp1;
								SWR_ADDR_temp1 = SWR_ADDR_temp1 +1; 
										 	if(SWR_ADDR_temp1 == 32'h3)
										   	SWR_ADDR_temp1 = 32'h0;
							end	
	
							if(OLD_DATA2[31:0] == NEW_DATA2 [31:0])begin  //no updated signal
 							      
								    if(OLD_DATA2 [63:32] == NEW_DATA2 [63:32])begin //no updated signal
									   updated_signal2 <= 1'b0;
									   SWR_en2 <= 1'b0;
									  
									   
                                    				      end 									   
								   else begin 
					                  		updated_signal2 <= 1'b1; 
									SWR_en2 <= 1'b1;  
									SWR_ADDR2 = SWR_ADDR_temp2;  
									SWR_ADDR_temp2 = SWR_ADDR_temp2 +1;

									  	if(SWR_ADDR_temp2 == 32'h2)
									  	SWR_ADDR_temp2 = 32'h0;
								end 
							end
							else   begin
							        updated_signal2 <= 1'b1;
								 SWR_en2 <= 1'b1;
								 SWR_ADDR2 = SWR_ADDR_temp2; 
								 SWR_ADDR_temp2 = SWR_ADDR_temp2 +1;

					   				if(SWR_ADDR_temp2 == 32'h2)
									  SWR_ADDR_temp2 = 32'h0;
                       				       end
					                
					               					    					

				end 
                       		default: SWR_en1 <= 0;
                     		endcase 

                 end

	     end	
				
		  RX_REQ:  
                          begin
		  		        				    
				    counter_req <= counter_req+1; 
					
                   		if (req_done) 
				   
                    		next_state <= TX_RESP;
					
				   else 
				    next_state <= RX_REQ;
					
                 end   


         TX_RESP: begin
                  counter_resp <= counter_resp +1; 
				  
                  		if(resp_done)		 
				    next_state <=operation;
					
					
				  else 
				   next_state <= TX_RESP;
				   
	 end 		   
          idle: 
		       begin
			     if (MASTER_REQ) 
 
					next_state <= init;
					
				 else                  				 
									
					next_state <= idle;	
		  
		        end 
				
	 
	default : next_state <= idle;
        endcase 
  end
end
	
endmodule

			    
		
		

