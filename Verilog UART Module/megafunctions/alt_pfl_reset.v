////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_RESET
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
// This module used by PFL to reset PFL
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_reset
(
	clk,
	nreset_in,
	nreset_out
);

	input clk;
	input nreset_in;
	output nreset_out = (counter_q == 4'b1110);
	
	reg [3:0] counter_q;
	always @ (negedge nreset_in or posedge clk) begin
		if (~nreset_in)
			counter_q = 4'b0001;
		else begin
			if (nreset_out)
				counter_q = counter_q;
			else 
				counter_q = counter_q + 4'b0001;;
		end
	end
	
	initial begin
		counter_q = 4'b0000;
	end

endmodule


