/*this code describes the PID detection when the headder is recieved. Each slave should detect if the PID is known and defined for it or not*/

module PID_detector (clk,reset,en,slave_type,NAD,new_rx_data,PID_known,PID_unknown,frame_type);
input clk,reset,en;
input slave_type; 
input [3:0] NAD;
input [9:0] new_rx_data;  //the PID symbol recieved 
output reg PID_known,PID_unknown;
output frame_type;
wire [10:0] address;

wire saved_PID;



Slave_ROM s0 (address,saved_PID); //LUT to Give the PID as an adress and the slave id(NAD) and slave type to the ROM
//check the saved data if it is equal 1 then the PID is known else it's unknown 


assign frame_type =(new_rx_data [6:1] == 6'h16)? 1'b1:1'b0; //event triggered =1 , unconditionel frame = 1'b0
assign address ={slave_type,NAD,new_rx_data [6:1]};  //Let the address of the slave ROM is the PID 



 
 always @(*)
begin
     
       //if (en) 
         //begin           

          if (saved_PID == 1'b1)
                begin 
                 PID_known <= 1'b1;
                 PID_unknown <= 1'b0;
                end 
            else   
               begin 
                PID_known <= 1'b0;
                PID_unknown <= 1'b1;
              end
         //end
           
end
endmodule





/*
module PID_detector2 (clk,en,reset,new_rx_data,PID_known,PID_unknown);
input clk,en,reset; 
input [9:0] new_rx_data;  //the PID symbol recieved 
output reg PID_known,PID_unknown;

reg [5:0] address;
wire slave_id = 0;
wire saved_PID;



Slave_ROM s0 (clk,reset,address,slave_id,saved_PID ); //Give the PID as an adress and the slave id for the ROM
//check the saved data if it is equal 1 then the PID is known else it's unknown 

always @* 
begin
 
address <= new_rx_data [6:1];  //Let the address of the slave ROM is the PID 


end
 
 always @(posedge clk or negedge reset )
begin
     if(!reset) begin
           PID_known <= 1'b0;
           PID_unknown <= 1'b0;
       end 
        else 
           begin
        if(en) begin 
          if (saved_PID == 1'b1)
                begin 
                 PID_known <= 1'b1;
                 PID_unknown <= 1'b0;
                end 
            else   
               begin 
                PID_unknown <= 1'b0;
                PID_unknown <= 1'b1;
              end
             end
         end
              
end
endmodule 
*/

//---------------------------------------------Salve_ROM2-----------------------------------//
/*module PID_detector2 (clk,reset,new_rx_data,PID_known,PID_unknown);
input clk,reset; 
input [9:0] new_rx_data;  //the PID symbol recieved 
output reg PID_known,PID_unknown;

wire [1:0] slave_id;
wire [35:0] data;
wire [35:0] slave_PIDs; 

Slave_ROM2 ROM (clk,reset,slave_PIDs,slave_id,data);



 always @(posedge clk or negedge reset )
begin
     if(!reset) begin
           PID_known <= 1'b0;
           PID_unknown <= 1'b0;
       end 
        else 
           begin

          if (new_rx_data [6:1] == data [5:0] || new_rx_data [6:1] == data [11:6] || new_rx_data [6:1] == data [17:12] || new_rx_data [6:1] == data [23:18]|| new_rx_data [6:1] == data [29:24] || new_rx_data [6:1] == data[35:30] )
                begin 
                 PID_known <= 1'b1;
                 PID_unknown <= 1'b0;
                end 
            else   
               begin 
                PID_known <= 1'b0;
                PID_unknown <= 1'b1;
              end

         end
              
end
endmodule
*/