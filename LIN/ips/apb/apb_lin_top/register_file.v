
module register_file (clk,reset,write_enable,read_enable,wrAddr,wrData,rdAddrA,rdDataA,error_flag1,error_flag2,data_valid_mem,INIT_FINISH,nb_of_frames,wakeup_cmd,sleep_cmd,bus_inactive,en_schedule,en_diagnostic,end_diagnostic);
   input clk;
   input reset;
   input write_enable;
   input read_enable;
   input [3:0] wrAddr;
   input [31:0] wrData;
   input [3:0] rdAddrA;
   input [31:0] error_flag1,error_flag2;
   input data_valid_mem;
   input INIT_FINISH;
   input bus_inactive;   //modified by sarah
   input end_diagnostic; //modified by sarah

   output reg [31:0] rdDataA;
   output reg en_schedule;
   output reg [7:0] nb_of_frames;
   output reg wakeup_cmd;
   output reg sleep_cmd;
   // output reg bus_inactive;
   output reg en_diagnostic; 
  // output reg end_diagnostic;

   reg [31:0] 	 reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7, reg8, reg9, reg10;
   reg    wr0,wr1,wr2,wr3,wr4,wr5,wr6,wr7,wr8,wr9,wr10;
   
   
   always @(posedge clk ) begin
    
	//------------------write to reg----------------------//
      if (write_enable) 
	case (wrAddr) 
	  
	  4'h3: begin reg3 <= wrData; wr0 <=1; end
	  4'h4: begin reg4 <= wrData; wr1 <=1; end
	  4'h5: begin reg5 <= wrData; wr2 <=1; end
	  4'h6: begin reg6 <= wrData; wr3 <=1; end
	  4'h8: begin reg8 <= wrData; wr5 <=1; end
	  
	  
   /* 4'h0: begin reg3 <= wrData; wr0 <=1; end
	  4'h1: begin reg4 <= wrData; wr1 <=1; end
	  4'h2: begin reg5 <= wrData; wr2 <=1; end
	  4'h3: begin reg6 <= wrData; wr3 <=1; end
	  4'h4: begin reg7 <= wrData; wr4 <=1; end
	  4'h5: begin reg8 <= wrData; wr5 <=1; end
	  4'h6: begin reg9 <= wrData; wr6 <=1; end
	*/
	  
	endcase 
   end 
   
   //--------------------read from reg----------------------//
   always @(*) begin
     if(read_enable) begin 
      case (rdAddrA)
	4'h0: rdDataA = reg0;
	4'h1: rdDataA = reg1;
	4'h2: rdDataA = reg2;	
	4'h3: rdDataA = reg3;
    4'h4: rdDataA = reg4;
	4'h5: rdDataA = reg5;
	4'h6: rdDataA = reg6;
	4'h7: rdDataA = reg7;
	4'h8: rdDataA = reg8;
	4'h9: rdDataA = reg9;
	4'ha: rdDataA = reg10;
	
	default: rdDataA = 32'h0000;
      endcase
    end
   end
   
   //------------INIT_FINISH REGISTER------------------------------------------//
    always @(posedge clk or negedge reset) begin 
	
		if(!reset)   // edited by abdelarhman to match pulpino neg reset
	      reg0 <= 32'h0; 
		  
		else 
		 
		  reg0[0] <= INIT_FINISH;
	
	end

//---------------BUS inactive----------------------------------------------//
	always @(posedge clk or negedge reset) begin 
	
		if(!reset)    // edited by abdelarhman to match pulpino neg reset
	      reg7 <= 32'h0; 
		  
		else 
		 
		 reg7[0]<= bus_inactive  ;
		 
	
	end


	
	 //------------ERROR FLAG 1 REGISTER------------------------------------------//
	
	always @(posedge clk or negedge reset) begin 
	
		if(!reset)     // edited by abdelarhman to match pulpino neg reset
	      reg1 <= 32'h0; 
		  
		else 
		 
		  reg1[0] <= error_flag1;
	
	end
   
    //-----------ERROR FLAG 2 REGISTER------------------------------------------//
   
   	always @(posedge clk or negedge reset) begin //edited by sarah
	
		if(!reset)    // edited by abdelarhman to match pulpino neg reset
	      reg2 <= 32'h0; 
		  
		else 
		 
		  reg2[0] <= error_flag2;
	
	end
	
	
	 //-----------data valid in rx memory  REGISTER------------------------------------------//
	
	always @(posedge clk or negedge reset) begin 
	
		if(!reset)     // edited by abdelarhman to match pulpino neg reset
	      reg10 <= 32'h0; 
		  
		else 
		 
		  reg10[0] <= data_valid_mem;
	
	end
/*
always @(*)
begin 
reg10[0] <= data_valid_mem;
end
*/
//-------------------End diagnostic table-------------------------------------//
 	always @(posedge clk or negedge reset) begin //edited by sarah
	
		if(!reset)    // edited by abdelarhman to match pulpino neg reset
	      reg9 <= 32'h0; 
		  
		else 
		 
		   reg9[0] <= end_diagnostic;
		 
	
	end
   
    //----------------Enable schedule table----------------------------------------------------// 	
	always @(posedge clk or negedge reset) begin 
	
		if(!reset)   // edited by abdelarhman to match pulpino neg reset
	      reg3 <= 32'h0; 
		  
		else if (wr0)
		 
		  en_schedule <= reg3[0];
		 
	
	end
	
	//---------------Set the number of frames or memory locations to schedule table---------------//
	always @(posedge clk or negedge reset) begin 
	
		if(!reset)   // edited by abdelarhman to match pulpino neg reset
	      reg4 <= 32'h0; 
		  
		else if (wr1)
		 
		  //nb_of_frames <= reg4[0];     
		   nb_of_frames <= reg4[7:0];     //edited by abdelrahman
	
	end
	
	
	//---------------------sleep command ----------------------------------------------------------//
	always @(posedge clk or negedge reset) begin 
	
		if(!reset)     // edited by abdelarhman to match pulpino neg reset
	      reg5 <= 32'h0; 
		  
		else if (wr2)
		 
		  sleep_cmd <= reg5[0];
		 
	
	end
   
     //------------------wakeup command-----------------------------------------------------------//
   
 	always @(posedge clk or negedge reset) begin 
	
		if(!reset)    // edited by abdelarhman to match pulpino neg reset
	      reg6 <= 32'h0; 
		  
		else if (wr3)
		 
		  wakeup_cmd <= reg6[0];
		 
	
	end 
   
  
	//--------------------bus_inactive---------------------------------------------------------------//
	
	 /*always @(posedge clk or negedge reset) begin 
	
		if(!reset)    // edited by abdelarhman to match pulpino neg reset
	      reg7 <= 32'h0; 
		  
		else if (wr4)
		 
		  bus_inactive <= reg7[0];
		 
	
	end*/ 
	
	//-----------------enable diagnostic_table-------------------------------------------------------//
        always @(posedge clk or negedge reset) begin 
	
		if(!reset)    // edited by abdelarhman to match pulpino neg reset
	      reg8 <= 32'h0; 
		  
		else if (wr5)
		 
		  en_diagnostic <= reg8[0];
		 
	
	end
	
	//-------------end diagnostic_table-------------------------------------------------------//
       /*always @(posedge clk or negedge reset) begin 
	
		if(!reset)    // edited by abdelarhman to match pulpino neg reset
	      reg9 <= 32'h0; 
		  
		else if (wr6)
		 
		  end_diagnostic <= reg9[0];
		 
	
	end*/
   
endmodule
