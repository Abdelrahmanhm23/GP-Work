module data_memory (clk,reset,SWR_en,SWR_data,SWR_ADDR,SRD_ADDR,SRD_data);
input clk,reset,SWR_en;
input [31:0] SWR_ADDR,SRD_ADDR;
input [31:0] SWR_data;
output reg [31:0] SRD_data;

reg [31:0] mem2[7:0]; 

always @(posedge clk or negedge reset) 
begin  
     if(!reset) begin  
     SRD_data<=0;
      
    end 
     else begin 
           if (SWR_en)
            mem2[SWR_ADDR] <= SWR_data;
            
           
            SRD_data <= mem2[SRD_ADDR];
	   
    end   
  end       
endmodule
