/* This code describes the state machine of the break synchronization detection but the PID (protected identifier field) is described in another module.
 At every clock cycle the sampling of 10 bits (one symbol) occurs 
 The state s0 indicates that the block is waiting for header at each Time slot and it is the reset state and goes to S1 only when it recieves rx_data symbol 
           at S1 the comparison of the data begins and the reciever detects if the recieved symbol is the first symbol of the break field if it doesn't match it 
           then it discards the header and return to the reset state(or the "waiting for header state" .... etc */
          


module brk_sync_det (clk,reset,rx_data,en_slv_operation,error,brk_seq_chkd); 
parameter  n=14;
input  [9:0] rx_data; //symbol recieved 
input clk,reset;   
input en_slv_operation;
output reg brk_seq_chkd,error; 

reg [1:0] current_state , next_state;
reg [3:0] count;


 

parameter [1:0] S0 = 2'b00, //waiting for header (reset state) 
          S1 = 2'b01, // 1st symbol of brk_bits checked = 10h'0 
          S2 = 2'b10, //2nd symbol of brk_bits  checked = 10'h200 
          S3 = 2'b11; //dummy state that return to the first state after 1 clock cycle 
       
always@(posedge clk or negedge reset)
   begin 
           if(!reset)
          begin 
             count <= 4'b0000;
             error <= 1'b0; 
              brk_seq_chkd <= 1'b0;
             current_state <= S0;
            
             
             
          end
           else
             begin
 	  current_state <= next_state;


				if(rx_data == 10'h000) 
					current_state <= S1;
     
                        /* if ( count == n) begin //when counter = 14  return to the first state 
            			
                                       count <= 4'b0;
					current_state <= S0;
			 end 
			 else 
				
			         count <= count +1;*/
		                    	
      				
                    
             end 
             
   end          

always @(current_state or rx_data ) //state transitions
 begin
  
   if(en_slv_operation) begin
      
  case (current_state)
   

   S0: if(rx_data == 10'h0)begin  //check that 1st symbol of brk_bits = 0000000000
        next_state <= S1;
       brk_seq_chkd <=0;
          error <=0; 
        end 

       else begin
        next_state <= S0; 
         brk_seq_chkd <=0;
            error <=0;    
       end

   S1:  if(rx_data == 10'h200) begin //check that 2nd symbol of brk_bits = 1000000000
        next_state <= S2;
          brk_seq_chkd <=0;
          error <=0; 
        end

       else begin
        next_state <= S0;
	  brk_seq_chkd <=0;
            error <=1;   //error in the break
       end 

   S2:  if(rx_data[8:1] == 8'h55) begin //check that synchronization bits = 0x55
        next_state <= S3; 
        brk_seq_chkd <=1;
          error <=0;
        end
       else begin
        next_state <= S0;
	brk_seq_chkd <=0;
            error <=1; 
       end

   S3:  begin

	  if(rx_data == 10'h0)begin  //check that 1st symbol of brk_bits = 0000000000
        next_state <= S1;
       brk_seq_chkd <=0;
          error <=0; 
	end

      else if(brk_seq_chkd == 1'b1 && error == 1'b0) begin
                  brk_seq_chkd <=1;
         	  error <=0; 
       		  next_state <= S3; end
        else 
       next_state <= S0;
        end

   default:begin 
              next_state <= S0;
 	      brk_seq_chkd <=0;
              error <=0;
           end 
  endcase
      end   
      else begin 
     current_state <= S0;   
     count<= 0;
             brk_seq_chkd <=1'bz;
            error <=1'bz; 
      end 
          
    
end        


endmodule


