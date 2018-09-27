module lin_top_module (clk,reset); 

input clk,reset; 
//output TOP_DATA_OUT;

wire [9:0] data_in,data_byte_out_slave;
wire [9:0] data_in_slave,data_out_master;
wire [9:0] headder_out,headder_in;
reg sleep_cmd,bus_error,wakeup;
wire bus_inactive;
wire header_rcvd;
//wire [9:0] TOP_DATA_OUT;


master_top TOP1 (clk,reset,sleep_cmd,data_in,bus_error,wakeup,bus_inactive,data_out_master,header_rcvd);
Slave_Top TOP2 (clk,reset,data_in_slave,data_byte_out_slave);




//assign TOP_DATA_OUT = (!header_rcvd)? data_out : (header_rcv && master_pub)? data_out : (header && !master_pub)? data_byte_out;
//assign headder_in = headder_out; 
//assign headder_in =(!header_rcvd)? data_out:10'hzzz; 
//assign data_in = (header_rcvd)? data_out:10'hzzz;
//assign headder_in = data_out;
assign data_in_slave = data_out_master;
//assign headder_in = data_out;
assign data_in = data_byte_out_slave;



endmodule 
