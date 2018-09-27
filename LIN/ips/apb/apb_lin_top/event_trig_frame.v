module event_trig_frame (clk,reset,en_evenTrig_frame ,updated_signal1,updated_signal2,data_byte1,data_byte2,data_published);
parameter [5:0] UNCOND_FRAME1=6'h25, UNCOND_FRAME2=6'h26;

input clk,reset; 
input en_evenTrig_frame,updated_signal1,updated_signal2; 
//output reg collision_detected;
input [9:0] data_byte1,data_byte2;
output reg [9:0] data_published;

wire [31:0] start_addr1,start_addr2;
wire [31:0] SRD_data1,SRD_data2; 
wire en_collision_table;
wire [3:0] NAD1,NAD2;



always@(*) 
begin 

	/*if(!reset) begin 
 		data_published <=0;
                //collision_detected <=0;
 		
       end */
           if(en_evenTrig_frame) begin
               if(updated_signal1 && updated_signal2)		 
 			data_published <= (data_byte1 & data_byte2); //to publish dominant zero on the bus if 100101(6'h25) and 100110 (6'h26) = 100100 
		 
	       else if(updated_signal1)		 
 			data_published <= data_byte1;		  //only publish the updated signal data_byte of slave 1	
		
		else if(updated_signal2)		 
 			data_published <= data_byte2;		//only publish the updated signal data_byte of slave 2
		
			
			else 
    	                  data_published <= 32'hzzzzzzzz; 
          end 
          else 
             data_published <= 32'hzzzzzzzz; 
           
end

/*always @(*) 
begin 

	case (data_published) 
                {1'b1,1'b0,1'b0,UNCOND_FRAME1,1'b0} 		: collision_detected <= 1'b0;     		     // {1'b1,00_100101,1'b0}  first PID of 6'h25 is published on the bus
		{1'b1,1'b1,1'b0,UNCOND_FRAME2,1'b0}		:  collision_detected <= 1'b0;                    // {1'b1,10_ 100110,1'b0}  2nd PID of 6'h26 is published on the bus	
                {1'b1,1'b0,1'b0,UNCOND_FRAME1 & UNCOND_FRAME2,1'b0}:  collision_detected <= 1'b1;   // {1'b1, (00_100101 && 10_ 100110) , 1'b0} the anding of the 2 PIDs that means collision is detected
		default: collision_detected <= 1'b0 ;	  					
	endcase

end */
endmodule 