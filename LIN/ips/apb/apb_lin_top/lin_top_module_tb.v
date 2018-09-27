module lin_top_module_tb (); 

reg clk,reset; 


lin_top_module LIN_TOP (clk,reset);



initial begin
  clk = 1'b0;
  
  forever #50 clk = ~clk; // generate a clock
end

//Set initial reset
initial     
begin
reset = 1'b0 ;
#100 reset = 1'b1 ;
end


initial begin 

  LIN_TOP.sleep_cmd =0; 
  LIN_TOP.bus_error =0; 
  LIN_TOP.wakeup =0; 

end 
endmodule 