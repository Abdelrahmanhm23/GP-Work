module schedule_table (clk,reset,en_operation,en_collision_table,en_diagnostic_table,diagnostic_end,read_from_mem,error_ctrl, 
      			MRD_data,nb_of_frames,nb_of_schedules,MRD_ADDR,headder,
			master_publisher,master_subscriber,header_done,collision_resolved,diagnostic_done,error_flag1,error_flag2);
 
   parameter [31:0] END_COLLISION_TABLE=32'h16,END_DIAGN_TABLE=32'h1f;
    input clk,reset;
    input en_operation;						//enable schedule table
    input en_collision_table;	                                //enable the collision table and then stop the normal schedule
    input read_from_mem;					//after initialization the schedule table starts reading from memory
    input error_ctrl;						//to monitor the bus error
    input[31:0] MRD_data;					//data read from memory 
    input [7:0] nb_of_frames,nb_of_schedules;  			 //number of frames determine the end of the schedule / nb of schedules is used to support many schedules
    input diagnostic_end;
    input en_diagnostic_table; 

    output reg [31:0] MRD_ADDR; 		        	 //address provided to memory 
    output [9:0] headder; 					//headder sent to the slave task 
    output wire master_publisher;              			//to determine if the slave task of the master node is the publisher or the slave task of the slave node 
    output wire master_subscriber;
    output header_done;
    output reg collision_resolved;
    output reg diagnostic_done;
    output reg [31:0] error_flag1,error_flag2;

wire  [5:0] data; 						//data out from memory (for break,synchronization,PID)
//wire diagnostic_end =1'b0;
wire [9:0] headder_out;
wire en_evenTrig_frame;
wire collision_detected;
reg [31:0] address; 
wire [31:0] MRD_data2;
reg [3:0] counter ,counter2,counter3,counter4;
wire header_done1;
reg [31:0] MRD_ADDR_temp0,MRD_ADDR_temp1, MRD_ADDR_temp2;

reg data_concerned ; 
reg [31:0] MRD_data_temp;


headder_creation Hdr_cr0 (clk,reset,en_operation,en_collision_table,en_diagnostic_table,data,headder_out,header_done1); //Module used to generate the headder part of the frame
collision_table ColTab   (address,MRD_data2);

assign header_done = header_done1;
assign data = MRD_data [5:0];
assign headder = headder_out;
assign master_subscriber = (MRD_data[5:0] == 6'h24 ||MRD_data[5:0]== 6'h20||MRD_data[5:0]==6'h22 ||MRD_data[5:0]==6'h25 ||MRD_data[5:0]==6'h26 ||MRD_data[5:0]==6'h3d)? 1'b1:1'b0;    //master node is the subscriber of those frames
assign master_publisher = (MRD_data[5:0]== 6'h23 || MRD_data[5:0]== 6'h30 || MRD_data[5:0]== 6'h3c )? 1'b1:1'b0; //master node is the publisher of those frames
//assign en_evenTrig_frame =(MRD_data[5:0] ==6'h22)? 1'b1:1'b0;        //enable module of event triggered frame
//assign en_diagnostics =(MRD_data[5:0] ==6'h3c) ? 1'b1:1'b0;	     //enable diagnostic frame
//assign en_collision_table = (collision_detected)? 1'b1:1'b0;       //access collision table if collision is detected


always @(*) begin 
			if(MRD_data_temp [5:0] !== MRD_data[5:0]) 
                         data_concerned <= 1'b0;
			else 
			data_concerned <= 1'b1;

end

always @(posedge clk or negedge reset ) 
 begin 
     if (!reset) 
   begin
         
      //addr0 <= 0;
      counter <=0;       //general counter for schedule table
      counter2 <=0;      //counter to get the data from 3 memory locations when the master is the publisher
      counter3 <=0;     //counter for collision table
      counter4 <=0;	//counter for diagnostic table
      MRD_ADDR <=32'h00; 
      address <= 32'h0;
      MRD_ADDR_temp0 <= 32'h0;
      MRD_ADDR_temp1 <= 32'h15; 
       MRD_ADDR_temp2 <= 32'ha;
      collision_resolved <= 1'b0;
       data_concerned <= 1'b0;
       
   end

 else if(en_operation)		//enable normal schedule table
   begin 
   address <= 32'h0;
    counter <= counter +1;     //counter to send header on the bus each time slot
    counter2 <=4'h0;
     if (read_from_mem )       //schedule table read PIDs from memory 
       begin
        if (MRD_ADDR_temp0 <= nb_of_frames)  //number of frames = maxiumum of schedule table then return back to the start of the schedule
          begin 

	    MRD_data_temp <= MRD_data;
           MRD_ADDR <= MRD_ADDR_temp0;

            if (counter == 4'hE ) begin    //after 14 clock cycles increment the address to get the next PID 
  	     counter <= 4'b0;
	       
		if(error_ctrl && master_subscriber && data == 6'h24)                  
                    MRD_ADDR_temp0 <= MRD_ADDR_temp0-3;

		if(error_ctrl && master_subscriber)                  
                    MRD_ADDR_temp0 <= MRD_ADDR_temp0;


		else 
		 MRD_ADDR_temp0 <= MRD_ADDR_temp0+1;
		
              end
		 
		
              

	   else if (master_publisher && counter !== 4'hE && counter < 4'h5 && counter > 4'h2 )begin  //in case of the master publisher loop in the memory and get the data saved in 3 memory locations
                  counter2 <= counter2 +1;
                      MRD_ADDR_temp0<= MRD_ADDR_temp0 +1; 
                      
          end 

         end
		
           else if( MRD_ADDR_temp0 > nb_of_frames) // end of schedule table then restart 
  		begin  
  
   		MRD_ADDR_temp0 <= 8'h0;
   		MRD_ADDR <= 8'h0;
   		//counter <= 4'h0;

  		 end   
              
    end
        else MRD_ADDR_temp0 <= 8'h0;       //in case of read f

   end  
   
   else if (en_diagnostic_table)begin 
    MRD_ADDR <= MRD_ADDR_temp2;
         counter <= counter +1;
          counter4 <=counter4+1;
          
   if (!diagnostic_end) 
          begin 
          
           if (counter == 4'hE)begin
         counter <= 0;
         counter4 <=0;
			end
			
			if(counter4 == 4'hE) begin
   		 MRD_ADDR_temp2<= MRD_ADDR_temp2 +1;
   		  end
   		  
			else if (master_publisher && counter !== 4'hE && counter < 4'h5 && counter > 4'h2 )begin  //in case of the master publisher loop in the memory and get the data saved in 3 memory locations
                counter4 <= counter4 +1; 	 

				MRD_ADDR_temp2<= MRD_ADDR_temp2 +1;
                       
                      
          end
       end
    else 
       counter <= 4'hE;
       
       /* else if (en_diagnostic_table)begin   
  	 MRD_ADDR <= MRD_ADDR_temp2;
         counter <= counter +1;
          counter3 <=counter3+1;
		

       if (!diagnostic_end) //number of frames = maxiumum of schedule table then return back to the start of the schedule
          begin 
         
        if (counter == 4'hE)begin
         counter <= 0;
         counter3 <=0;
        end 
         if(counter3 == 4'hE) begin
   		 MRD_ADDR_temp2<= MRD_ADDR_temp2 +1;
 		//counter3 <=0;
         end 
        else if (master_publisher && counter !== 4'hE && counter < 4'h5 && counter > 4'h2 )begin  //in case of the master publisher loop in the memory and get the data saved in 3 memory locations
                counter3 <= counter3 +1; 
		 

		MRD_ADDR_temp2<= MRD_ADDR_temp2 +1;
                       
                      
          end
    end*/
       
      
 	//counter <= 4'hE;                 
        //counter4 <= counter4+1;
        //MRD_ADDR <= MRD_ADDR_temp2;


       /* if (counter3 == 4'hC)begin
         counter3 <= 0;
	MRD_ADDR_temp2 <= MRD_ADDR_temp2 +1;
		if(MRD_ADDR== END_DIAGN_TABLE)
                  diagnostic_done <= 1'b1;
                else 
		 diagnostic_done <= 1'b0;
       end
    end */
    
    
    end
    
     
    else if (en_collision_table)begin     //when the collision is detected stop the normal schedule table (en_operation=0)  and access the collision table 
 	counter <= 4'hE;                 //set the counter == 4'hC (less than the end of the T_slot by 1) to be incremented in the next clock cycle to 4'hE and then continue the normal schedule
        counter3 <= counter3+1;
        MRD_ADDR <= MRD_ADDR_temp1;


        if (counter3 == 4'hE)begin
         counter3 <= 0;
	MRD_ADDR_temp1 <= MRD_ADDR_temp1 +1;
		if(MRD_ADDR== END_COLLISION_TABLE)
                  collision_resolved <= 1'b1;
                else 
		 collision_resolved <= 1'b0;
       end
    end 

  
end 


endmodule



    
