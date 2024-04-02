////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG3_DOWN_CONVERTER
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
// This module contains the PFL downsize data converter
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg3_down_converter (
	clk,
	nreset,
	
	// Interface with flash
	data_in,
	flash_data_request,
	flash_data_ready,
	flash_data_read,

	// Interface with controller
	data_out,
	data_request,
	data_ready,
	data_read
);
	parameter	DATA_IN_WIDTH		= 16;
	parameter	DATA_OUT_WIDTH 		= 8;
	parameter	DATA_SIZE_DIFF		= DATA_IN_WIDTH / DATA_OUT_WIDTH;
	parameter	SEL_DATA_WIDTH		= log2(DATA_SIZE_DIFF) - 1;
	
	input 	clk;
	input	nreset;

	// Interface with flash
	input 	[DATA_IN_WIDTH-1:0] data_in;
	output	flash_data_request;
	input 	flash_data_ready;
	output	flash_data_read;
	
	// Interface with controller
	output	[DATA_OUT_WIDTH-1:0] data_out;
	input	data_request;
	output	data_ready;
	input	data_read;
	
	wire	[SEL_DATA_WIDTH-1:0] sel_out;
	reg		[DATA_IN_WIDTH-DATA_OUT_WIDTH-1:0] latch_data;
	wire	sel_zero;
	
	assign flash_data_request 	= data_request;
	assign sel_zero 			= (sel_out == 0) ? 1'b0 : 1'b1;
	assign data_ready 			= flash_data_ready || sel_zero;
	assign flash_data_read 		= data_read && ~sel_zero;
	
	lpm_mux down_mux (
		.data		({latch_data,data_in[DATA_OUT_WIDTH-1:0]}),
		.sel		(sel_out),
		.result		(data_out)
	);
	defparam
		down_mux.lpm_width	= DATA_OUT_WIDTH,
		down_mux.lpm_size	= DATA_SIZE_DIFF,
		down_mux.lpm_widths	= SEL_DATA_WIDTH;
	
	lpm_counter sel_cntr(
		.clock		(clk),
		.cnt_en		(data_read),
		.aclr		(~nreset),
		.q			(sel_out)
	);
	defparam
		sel_cntr.lpm_width = SEL_DATA_WIDTH;
	
	always @(posedge clk) begin
		if (data_read) begin
			if (~sel_zero) begin
				latch_data = data_in[DATA_IN_WIDTH-1:DATA_OUT_WIDTH];
			end
		end
	end
	
	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
				value = value >> 1;
		end
	endfunction
endmodule
