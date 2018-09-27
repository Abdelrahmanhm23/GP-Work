module rx_checksum (data_in,  checksum_chkd , checksum_error); 
input [89:0] data_in; 
output reg checksum_chkd , checksum_error; 


wire [79:0] data_field ;   //is the  received data symbols without the checksum field 
wire [9:0] data_out;       //the output of the sum of all data fields 
wire [7:0] sum ;           //to add the checksum field recieved and the ouput of the sum of all data fields 

assign data_field = data_in [79:0];
sum s1 (data_field,data_out);

assign sum = data_out[8:1] + data_in [88:81];  //for correct checksun the sum of the data_out and the checksum field will be equal to zero
 
//because the checksum is equal to one's complement the sum of all data fields  



always @* 
begin     
    if ( sum == 8'b11111111)
    begin
       checksum_chkd <= 1;
       checksum_error <= 0;
    end
      else 
    begin
       checksum_chkd <= 0;
       checksum_error <= 1;
     end 
end

endmodule
