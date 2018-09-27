module parity_comp (hdr_id , parity_op);
input [5:0] hdr_id; 
output reg [1:0] parity_op; 

 
always@*
begin
   
  
 parity_op[0] <=  hdr_id[0]^hdr_id[1]^hdr_id[2]^hdr_id[4] ;
 parity_op[1] <=  ~(hdr_id[1]^hdr_id[3]^hdr_id[4]^hdr_id[5]);
   
 
end 


endmodule
 
//----------------------------------------------------------------------------------------------------

module rx_parity_check (PID_symbol,clk,reset,rx_parity_op,PID_chkd);
input [9:0] PID_symbol;
input clk,reset;
output reg [1:0] rx_parity_op;
output reg PID_chkd;

wire [5:0] PID_rx;
wire [1:0] parity_op;

assign PID_rx = PID_symbol[6:1];


parity_comp P (PID_rx,parity_op);

      always @ (posedge clk or negedge reset) 
      begin 
        if(!reset)
          begin
             rx_parity_op <=0;
              
           end
        else          
             rx_parity_op <=parity_op;           
         
      end

   always @(posedge clk) 
begin 
     if(PID_symbol[8:7]==parity_op) 
              begin 
                
             PID_chkd <=1;
              end
           else 
             
            PID_chkd <=0;
end

endmodule

   