
module schedule_table_ROM2 (addr0, data);
 input [31:0] addr0;
 output reg [31:0] data;

       
reg [31:0] addr;

//clock_divider C1 (reset,clk, clk_out);

 always @(*)
 begin 

    addr <= addr0;
       case(addr)
   32'h00: data = 32'h01234523; //PID 0 = 6'h23
   32'h01: data = 32'h81012023;
   32'h02: data = 32'h00223323;
   32'h03: data = 32'h24;        //PID 1 6'h20
   32'h04: data = 32'h20;        //PID 2 = 6'h24 status headder 
   32'h05: data = 32'habcdef30;  //PID 3 = 6'h30
   32'h06: data = 32'hfedcba30; 
   32'h07: data = 32'h00123430;
   32'h08: data = 32'h22;        //PID 4 = 6'h 22 event triggered
   32'h09: data = 32'h20;        //PID 5 = status headder 6'h20
   32'h0a: data = 32'h26;        
   32'h0b: data = 32'h20;
   32'h0c: data = 32'h3c;       //PID = 6'h3c diagnostic request frame [SID_PCI_initialNAD_3c]
   32'h0d: data = 32'h31;       
   32'h0e :data = 32'h35;     
   32'h0f: data = 32'h39;
   32'h10: data = 32'h11;
   32'h11: data = 32'h12;
   32'h12: data = 32'h15;
   32'h13: data = 32'h20;
   32'h14: data = 32'h102f;
   //------------------------------------------------------------------// collision table
   32'h15: data = 32'h25;
   32'h16: data = 32'h26;
   32'h17: data = 32'habcde;
   32'h18: data = 32'hf12345;
   32'h19: data = 32'h678910;
   32'h1a :data = 32'h678910;
   32'h1b: data = 32'habcde;
   //-------------------------------------------------------------------//diagnostic table 

   32'h1c: data = 32'hB0_06_01_3c;       //PID = 6'h3c diagnostic request frame [SID_PCI_initialNAD_3c]
   32'h1d: data = 32'hff_7f_ff_3c;       //PID = 6'h3c diagnostic request frame [ functionID(LSB)_supplierID(MSB)_supplierID(LSB)_3C]
   32'h1e: data = 32'h00_7f_ff_3c;       //PID = 6'h3c diagnostic request frame [_00_NAD_ functionID(MSB)_3C]
   32'h1f: data = 32'h3d;

   default: data = 6'bXXXXXX;
       endcase

                
    
  
       
 end
 
endmodule 
































