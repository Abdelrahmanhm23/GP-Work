			
module master_controller(clk,reset,en_schedule,sleep_cmd,bus_inactive,bus_error,wakeup,collision_detected,collision_resolved,diagnostic_rcvd,en_operation,en_collision_table,en_diagnostic_table,wake_cluster,read_from_mem,init_start,init_finish);
    input clk,reset; 
    input en_schedule;
    input bus_inactive;
    input wakeup;
    input  sleep_cmd; 
    input bus_error;
    input collision_detected;
    input collision_resolved;
    input diagnostic_rcvd;
    
    output reg en_operation;
    output reg en_collision_table;
    output reg en_diagnostic_table;
    output reg wake_cluster; 
    output reg read_from_mem;
    output reg init_finish,init_start;

parameter n=30;//100 ms 

parameter [1:0] init=2'b00,
	  operation=2'b01, 
	 sleep=2'b10; 

reg [1:0] current_state,next_state;
reg [7:0] counter;
wire[3:0] nb_of_frames0 =4'ha;
wire [3:0] nb_of_schedules0; 
wire en_operation0, read_from_mem0,error_ctrl;
wire [31:0] addr0;
wire [31:0] data;




schedule_table_ROM2  STROM (addr0, data);


assign error_ctrl = bus_error;


always @(posedge clk or negedge reset) 
	begin 
	   if(! reset) 
	       begin		
		 current_state <= init; 
                 counter <=0;
		 en_operation<=0;
		 read_from_mem<=0;
   		 init_finish <= 1'b0;
		 en_collision_table <= 1'b0;

                 
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
            
                 en_operation<=0;                        
		init_start <= 1'b1;
                init_finish <= 1'b0;

			if(counter < n)    	//stay in initialization state					 
                next_state <= init;	
                   
                 	else 	begin			//when the time of initialization finishes go to operational state
               		init_finish <= 1'b1;		
 	               next_state <= operation;
                 
	             end
	     end 
             


          operation: 
                 begin
		            if(en_schedule && !sleep_cmd && !collision_detected )begin   
			      en_operation<= 1'b1;
			      en_collision_table <= 1'b0;
			       counter <=0;
		               read_from_mem <= 1'b1; 
			       next_state <= operation;
			     end 
			    else if(sleep_cmd )    //if sleep cmd is sent from can bus or app layer go  to sleep state (highest priority)
		  		 begin
		    			en_operation<= 1'b0;
	    			        read_from_mem <=1'b0;
		    			next_state <= sleep; 
		    
		 		  end
 		 		 else if (bus_inactive)  // send wake up signal to wake the cluster
			   	  begin 
			     		wake_cluster <= 1'b1;
			     		en_operation <= 1'b1; 
			     		next_state <= operation;
		           	  end 
		           	  
		        else if(diagnostic_rcvd && !en_schedule)
 				    begin 
					en_operation<= 1'b0; 
					read_from_mem <=1'b0;	
					en_diagnostic_table <= 1'b1;
					next_state <= operation;

				   end
 
				  else if(collision_detected && !collision_resolved )
 				    begin 
					en_operation<= 1'b0; 
					read_from_mem <=1'b0;	
					en_collision_table <= 1'b1;
					next_state <= operation;

				   end

				 
				  else if(collision_detected && collision_resolved )
 				    begin 
					en_operation<= 1'b1; 
					read_from_mem <=1'b1;	
					en_collision_table <= 1'b0;
					next_state <= operation;
				   end
				 else 
				     
			     en_operation<= 1'b0;
						
	       end 
                    
                

          
      sleep: 
		begin 
                  en_operation <= 1'b0;
		//  mster_sleep <=1'b1;
		 if ( wakeup == 1'b0) 
		  next_state <= sleep; 
		  
		else 
		  begin
		 next_state <= init; 
                 counter <=0;
		   end  
	

	 	end	
 	   
	default : next_state <= operation;
	endcase 




end 
endmodule 
