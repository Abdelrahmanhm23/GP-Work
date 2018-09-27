
module collision_table (address, MRD_data2);
 input [31:0] address;
 output reg [31:0]MRD_data2;

       
reg [31:0] addr;



 always @(*)
 begin 

    addr <= address;
       case(addr)
   32'h00: MRD_data2 = 32'h25; //event triggered associated with unconditional frame 32'h25 
   32'h01: MRD_data2 = 32'h26; //event triggered associated with unconditional frame 32'h26
   default: MRD_data2 = 6'bXXXXXX;
       endcase

                
    
  
       
 end
 
endmodule 
































