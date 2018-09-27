module clock_divider (reset,clk_in, clk_out);

input reset,clk_in;
output reg clk_out;

reg [13:0] count; 
 
always @(posedge clk_in or negedge reset)
begin
  if(!reset)begin
  count <=0;
  clk_out <=0;
   end
  else 
   begin
    count <= count + 1;
       if(count == 100)
         begin
         count<=0;
         clk_out <= !clk_out;
         end
   end 
end

endmodule
