
module slave_RAM (addr00,addr11, data1,data2);
 input [31:0] addr00;
 input [31:0] addr11;
 output reg [31:0] data1,data2;

       
reg [31:0] addr0;
reg [31:0] addr1;

   //assign addr0 = (error_ctrl)? addr0-1 : 4'hz ; 
   

//clock_divider C1 (reset,clk, clk_out);

 always @(*)
 begin 

    addr1 <= addr11;
    addr0 <= addr00;

       case(addr0)
   32'h00: data1 = 32'h20111025; //event triggered associated to unconditional frame 25 
   32'h01: data1 = 32'h78910012;
   32'h02: data1 = 32'h0011102f;
   32'h03: data1 = 32'hcdef7891;
   32'h04: data1 = 32'hF0_01_01_3c;     //initial NAD 0x01 0xF0 0xFF 0xFF 0xFF 0xFF 0xFF (diagnostic positive response)
   32'h05: data1 =32'hFF_FF_FF_FF;
   32'h06: data1 =32'h7f_03_01_3c;	//Initial NAD 0x03 0x7F SID=0xB0 Error Code 0xFF 0xFF 0xFF
   32'h07: data1 =32'hFF_FF_aa_B0;
   default: data1 = 6'bXXXXXX;
       endcase
    
       case(addr1)
   32'h00: data2 = 32'h00cdef26;
   32'h01: data2 = 32'h22f1232a; //event triggered associated to unconditional frame 26
   
    default: data2 = 6'bXXXXXX;
       endcase
   
   

                
    
  
       
 end
 
endmodule 
































