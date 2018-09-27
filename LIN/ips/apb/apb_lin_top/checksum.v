
module checksum (data_in,clk,reset,checksum_op);
input [79:0] data_in;          //8-symbols of 10 bits in tha data field
input clk,reset;  
output reg [9:0] checksum_op; 

wire [9:0] data_out;
wire [7:0] checksum;

sum s (data_in,data_out); 

assign checksum = ~data_out[8:1];  //one's complement of the final sum 

always @ (posedge clk or negedge reset) 
begin 
     if(!reset)
    checksum_op <= 0;
    else 
    checksum_op <= {1'b1,checksum,1'b0}; //store the checksum output at each clock
end

endmodule

//==============================================================================================================
module sum  (data ,f_sum);   //Combinational block to sum of all the data byte field 
input  [79:0]  data;
output reg [9:0] f_sum;

reg [7:0] sum;
wire [7:0] d1,d2,d3,d4,d5,d6,d7,d8;
wire [8:0] sum0,sum1,sum2,sum3,sum4,sum5,sum6; 

//Divide the 80 bits into 8 symbols (10 bits each)
assign d1 = data[8:1];     
assign d2 = data[18:11];
assign d3 = data[28:21];
assign d4 = data[38:31];
assign d5 = data[48:41];
assign d6 = data[58:51];
assign d7 = data[68:61];
assign d8 = data[78:71];


//Add  2 symbols and then check if the carry = 1 re-add it to each sum before adding the next symbol 
// if carry = 0 add the next symbol
assign sum0 = d1+d2;
assign sum1 = (sum0[8]==1'b1)? sum0[7:0]+1'b1+d3:sum0[7:0]+d3;  
assign sum2 = (sum1[8]==1'b1)? sum1[7:0]+1'b1+d4:sum1[7:0]+d4;
assign sum3 = (sum2[8]==1'b1)? sum2[7:0]+1'b1+d5:sum2[7:0]+d5;
assign sum4 = (sum3[8]==1'b1)? sum3[7:0]+1'b1+d6:sum3[7:0]+d6;
assign sum5 = (sum4[8]==1'b1)? sum4[7:0]+1'b1+d7:sum4[7:0]+d7;
assign sum6 = (sum5[8]==1'b1)? sum5[7:0]+1'b1+d8:sum5[7:0]+d8;

//assign the final result 
always @*
begin 
 if (sum6[8] == 1'b1) 
    sum = sum6+1;
  else 
    sum = sum6;
 
    f_sum<={1'b1,sum,1'b0};
end

endmodule



