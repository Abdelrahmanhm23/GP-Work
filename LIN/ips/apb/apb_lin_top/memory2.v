module memory_rx (clk,reset,WR_en,WR_data,WR_ADDR,RD_en2,RD_ADDR2,RD_data2);
input clk,reset,WR_en,RD_en2;
input [3:0] WR_ADDR,RD_ADDR2;//RD_ADDR1
input [31:0] WR_data;
output reg [31:0] RD_data2;//RD_data1,
//output reg [95:0] RD_data2;

reg [31:0] mem1[15:0];

integer i;

always @(posedge clk or negedge reset)
begin
     if(!reset) begin
         RD_data2 <= 0 ;
         for (i=0 ; i<16; i=i+1)
          begin
             mem1[i]=0;
          end
     end
     
 end
     
 always @(posedge clk)
 begin 
           if (WR_en && (RD_en2!=1))
            mem1[WR_ADDR] <= WR_data;
            //RD_data2 <= 0 ;
 end   
         
always @(RD_en2) 
begin
          //  if (RD_en2 && (!WR_en)) //RD_data1 <= mem1[RD_ADDR1];
            RD_data2 = mem1[RD_ADDR2];
 end
 
endmodule
