////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_COUNTER
//
//  Copyright (C) 1991-2013 Altera Corporation
//  Your use of Altera Corporation's design tools, logic functions  
//  and other software and tools, and its AMPP partner logic  
//  functions, and any output files from any of the foregoing  
//  (including device programming or simulation files), and any  
//  associated documentation or information are expressly subject  
//  to the terms and conditions of the Altera Program License  
//  Subscription Agreement, Altera MegaCore Function License  
//  Agreement, or other applicable license agreement, including,  
//  without limitation, that your use is for the sole purpose of  
//  programming logic devices manufactured by Altera and sold by  
//  Altera or its authorized distributors.  Please refer to the  
//  applicable agreement for further details. 
//  
//  Quartus II 13.0.0 Build 156 04/24/2013 
//
//
//
////////////////////////////////////////////////////////////////////

//************************************************************
// Description:
//
// This module is PFL counter
//
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_counter
(
	clock,
	sclr,
	sload,
	data,
	cnt_en,
	q
);
	parameter 	WIDTH = 8;
	parameter 	DIRECTION = "UP";
	localparam 	[0:0] BIT_CHANGE = (DIRECTION == "DOWN")? 1'b0 : 1'b1;
	
	input 	clock;
	input 	sclr;
	input 	sload;
	input 	[WIDTH-1:0] data;
	input 	cnt_en;
	output 	[WIDTH-1:0] q;
	reg 		[WIDTH-1:0] q;
	
	genvar i;
	generate
		always @ (posedge clock) begin
			if (sclr)
				q[0] = 1'b0;
			else if (sload)
				q[0] = data[0];
			else if (cnt_en)
				q[0] = ~q[0];
		end
		if (WIDTH > 1) begin
			for (i=1; i<WIDTH; i=i+1) begin: BIT_LOOP
				always @ (posedge clock) begin
					if (sclr)
						q[i] = 1'b0;
					else if (sload)
						q[i] = data[i];
					else if (cnt_en && (q[i-1:0] == {(i){BIT_CHANGE[0]}}))
						q[i] = ~q[i];
				end
			end
		end
	endgenerate
	
endmodule
	