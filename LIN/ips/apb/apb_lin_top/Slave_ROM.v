module Slave_ROM (addr,saved_PID);

 input [10:0] addr;    //6 bits PID stored in the memory as an adress and 4 bits tNAD and 1 bit slave type publisher or subscriber

 output reg  saved_PID; //if the PID is stored as address assign saved_PID to 1 if not saved_PID = 0
  //wire  [6:0] addr;
         


 always @(*) 
 begin
       
       case(addr)
   11'b1_0000_100011: saved_PID = 1'b1;  //header 6'h23 publisher= master
   11'b1_0001_100000: saved_PID = 1'b1;  //header 6'h20 publisher= slave 1
   11'b1_0001_100100: saved_PID = 1'b1;  //header 6'h24 publisher= slave 1
   11'b1_0000_110000: saved_PID = 1'b1;  //header 6'h30 publisher= master
   11'b1_0001_100010: saved_PID = 1'b1;  //event tiggered publisher= slave 1
   11'b1_0010_100010: saved_PID = 1'b1;  //event tiggered publisher= slave 2
   11'b1_0000_111100: saved_PID = 1'b1;  //diagnostic request 6'h3c publisher = master
   11'b1_0001_111101: saved_PID = 1'b1;  //diagnostic response 6'h3d publisher = slave 1
   11'b0_0000_100000: saved_PID = 1'b1;  //header 6'h20 subscriber= master
   11'b0_0000_100100: saved_PID = 1'b1;  //header 6'h24 publisher= slave 1
   11'b0_0001_111100: saved_PID = 1'b1;  //diagnostic request 6'h3c subscriber = slave 1
   11'b0_0000_111101: saved_PID = 1'b1;  //diagnostic response 6'h3d subscriber = master
   11'b0_0010_110000: saved_PID = 1'b1;  //header 6'h30 subscriber= slave 2
   11'b0_0001_110000: saved_PID = 1'b1;  //header 6'h30 subscriber= slave 1
   11'b0_0001_100011: saved_PID = 1'b1;  //header 6'h23 subscriber= slave 1
   default: saved_PID = 0;
       endcase
  
  
       
 end
 
endmodule 



