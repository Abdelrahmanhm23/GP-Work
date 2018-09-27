
/*This module describe the process of sending the headder each headder is sent every 13 clock cycles (at each entry at the schedule table)
the 1st break bits "0000000000" are sent at the first clock cycle then 2nd brk bits "1000000000" then synchronization 1010101010 then PID symbol with parity computed */
module headder_creation (clk,reset,en_operation,en_collision_table,en_diagnostic_table,data_in,headder_out,headder_recieved);  
parameter  n=14;
input clk,reset;
input en_collision_table;
input en_diagnostic_table;
input en_operation;
input [5:0] data_in;  

output reg [9:0] headder_out;
output reg headder_recieved;

reg [2:0] current_state , next_state;
wire [9:0] brk_bits1,brk_bits2,sync_bits,PID_symbol_bits;
wire clear;

parameter [2:0] S0 = 3'b000, // (reset state) send brk_bits
          S1 = 3'b001, // send second symbol of brk bits
          S2 = 3'b010, //send sync bits
          S3 = 3'b011,//send PID symbol 
	  S4 = 3'b100; //leave the line

reg [3:0] counter,counter2;

wire [1:0] parity_op;
wire PID_known,PID_unknown;
wire [9:0]data_byte;
wire [5:0] data;
//wire en_operation;

assign data = data_in; 
                                         
parity_comp PC (data , parity_op); //to calculate the parity of the PID bits parity op is 2 bits 


assign brk_bits1 = 10'h0;
assign brk_bits2=  10'h200;
assign sync_bits= {1'b1,8'h55,1'b0};
assign PID_symbol_bits = {1'b1, parity_op ,data_in ,1'b0};
       
always@(posedge clk or negedge reset)
   begin 
        if(!reset || clear) begin 
                     current_state <= S0;
                     counter <= 4'b0;
	             counter2 <= 4'hC;
		     headder_recieved <= 1'b0;
		      headder_out <= 10'hzzz;
        end 
        else begin
             current_state <= next_state;
                    //in case of normal schedule 
                    if(en_operation)begin
		
				if ( counter == n) begin //when counter = 12  return to the first state 
            			
                                    counter <= 4'b0; 
				    current_state <= S0;
			        end 
			        else  counter <= counter +1; //else increment counter 	                    	
      				
                    end 
					
		   //in case of collision table 
		   else if( en_collision_table || en_diagnostic_table) begin 

			           counter <= 4'hE;      //let the counter of normal schedule = 0 
		                   

			         if ( counter2 == n) begin // same as normal shedule but in collision table when counter2 = 12  return to the first state 
            			
                                       counter2 <= 4'b0;
				       current_state <= S0;
				end 							
				else counter2 <= counter2 +1;

                    end 
                    else  counter <= 4'b0;

                 
            end 
             
   end          

always @(current_state) //state transitions
 begin
   if(en_operation || en_collision_table || en_diagnostic_table) begin 
  			
			
  case (current_state)
   

   S0:begin 
        headder_out <= brk_bits1;
        headder_recieved <= 1'b0;  
	//headder <= headder_in[39:30]; 
        next_state <= S1; 
	end
          

   S1:  begin  
         headder_out <= brk_bits2; 
         headder_recieved <= 1'b0;
	//headder <= headder_in[29:20]; 
        next_state <= S2; 
	end
        

   S2:  begin 
          headder_out <= sync_bits; 
         headder_recieved <= 1'b0;
	//headder <= headder_in[19:10]; 
        next_state <= S3; 
	end

     S3:  begin   
	headder_out <= PID_symbol_bits ; 
         next_state <= S4;
        headder_recieved <= 1'b0;
        //next_state <= S4; 
	end
  
      S4:  begin   
	//headder_out <= 10'hzzz; 
	headder_recieved <= 1'b1;
        next_state <= S4; 
	end 
   

   default: next_state <= S0;
  endcase
        
   
end   
      else
     current_state <= S0; 
          

end
endmodule