module Slave_controller (clk,reset,headder,sleep_cmd,bus_inactive,bus_error,en_slv_operation,S_read_from_mem,wake_cluster,INIT_START,INIT_FINISH,master_req);

    input clk,reset; 
    input [9:0] headder;
    input sleep_cmd;
    input bus_inactive;
    //input init_start;
    

    output bus_error; 
    output reg en_slv_operation,S_read_from_mem;
    output reg wake_cluster; 
    output reg INIT_START;
    output reg INIT_FINISH;
    output reg master_req;
  

parameter n=30; //100 ms 
reg master_inactive; 
reg wake_master;
wire headder_data;
reg  [31:0] SWR_ADDR_temp;

parameter [1:0] init=2'b00,
	  operation=2'b01, 
	 sleep=2'b10; 

reg [1:0] current_state,next_state;
reg [7:0] counter;
wire [9:0] data_byte;
wire [31:0] addr00;
wire [31:0] data;

//slave_RAM SRAM (addr00, data);


//assign addr00 = SWR_ADDR;
assign error_ctrl = bus_error;


always @(posedge clk or negedge reset) 
	begin 
	   if(! reset) 
	       begin		
		 current_state <= init; 
                 counter <=0;en_slv_operation<=0;S_read_from_mem <=0;
	         //SWR_ADDR_temp<=0;SWR_data <=data ;
                 INIT_START <= 1'b0;
                 INIT_FINISH <=1'b0;
		end

	  else
		begin
   		current_state <= next_state; 
		counter <= counter +1; 
			 

	  end 
	end 

always @ (current_state or counter)
	begin 

	       
           case (current_state) 
           init:
	      begin 
              //counter <= 0;
              INIT_START <= 1'b1;
                         en_slv_operation<=0;
			S_read_from_mem <=0;
                        

		
		if(counter < n) begin   	//stay in initialization state	  
                 next_state <= init;	
                 end  					
                else 				//when the time of initialization finishes go to operational state
                     begin 
                INIT_FINISH <=1'b1;
		next_state <= operation;
               
                     end	             
                 
	     end 
             


          operation: 
                 begin
		en_slv_operation <= 1'b1;  
		S_read_from_mem <= 1'b1;
                counter <=0;
		 //SWR_en <= 1'b0;
               
	         next_state <= operation;

               if(sleep_cmd )    //if sleep cmd is sent from can bus or app layer go  to sleep state (highest priority)
		   begin
		    en_slv_operation<= 1'b0;
		    
		    next_state <= sleep; 
		    
		  end
 		 	 else if (master_inactive)  // if 3 seconds of inactivity counts
			   begin 
			     wake_master <= 1'b1;
			     en_slv_operation <= 1'b1; 
			    S_read_from_mem <= 1'b0;
			     next_state <= operation;
			     //repeat (3) ;
		           end 

			else if (bus_inactive)  // if 3 seconds of inactivity counts
			   begin 
			     
			     en_slv_operation <= 1'b0; 
			     next_state <= sleep;
		           end 
						
	       end 

          
      sleep: 
		begin 
                  en_slv_operation <= 1'b0;

		 if ( headder == 10'h000) begin
                  master_req <= 1'b1;
		  next_state <= init; 
		  counter <=0;

 	        end 

		else 
		  begin
		 next_state <= sleep;
                 master_req <= 1'b0; 
                 
		   end  
	

	 	end	
 	   
	default : next_state <= operation;
	endcase 




end 
endmodule 
