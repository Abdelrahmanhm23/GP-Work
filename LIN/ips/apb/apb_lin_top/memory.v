
module memory_tx (clk,reset,WR_en,WR_data,WR_ADDR,RD_ADDR, RD_data1);
input clk,reset,WR_en;
input [3:0] WR_ADDR,RD_ADDR;
input [31:0] WR_data;
output reg [31:0] RD_data1;
//output reg [95:0] RD_data2;

reg [31:0] mem[255:0];
 
//reg [31:0] data1,data2,data3;
 //RD_data2 ;

always @(posedge clk or negedge reset) 
begin  
     if(!reset) begin
         RD_data1<=0;
        
     end
     else begin
           if (WR_en)
            mem[WR_ADDR] <= WR_data;
            
            RD_data1 <= mem[RD_ADDR]; 
          
     end
  end       
endmodule 

/*module memory2 (clk,reset,SWR_en,SWR_data,SWR_ADDR,SRD_ADDR, SRD_data);
input clk,reset,SWR_en;
input [7:0] SWR_ADDR,SRD_ADDR;
input [31:0] SWR_data;
output reg [31:0] SRD_data;

reg [31:0] mem2[255:0]; 

always @(posedge clk or negedge reset) 
begin  
     if(!reset) 
     SRD_data<=0; 
     else 
           if (SWR_en)
            mem2[SWR_ADDR] <= SWR_data;
            
            SRD_data <= mem2[SRD_ADDR];  
  end       
endmodule */
