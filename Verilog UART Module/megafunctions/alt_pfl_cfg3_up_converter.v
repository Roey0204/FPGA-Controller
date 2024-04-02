////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG3_UP_CONVERTER
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
// This module contains the PFL upsize data converter
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg3_up_converter (
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
	parameter	DATA_IN_WIDTH		= 8;
	parameter	DATA_OUT_WIDTH		= 16;
	parameter	DATA_SIZE_DIFF		= DATA_OUT_WIDTH / DATA_IN_WIDTH;
	parameter	SEL_DATA_WIDTH		= log2(DATA_SIZE_DIFF) - 1;
	
	input 	clk;
	input		nreset;

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
	reg		[DATA_OUT_WIDTH-1:0] data_out_reg;
	wire	sel_max;
	reg		buf_full;
	
	assign flash_data_request = data_request;
	assign flash_data_read = flash_data_ready & ~waiting;
	assign data_ready = (buf_full && ~sel_max) || data_ready_reg;
	
	wire waiting = data_ready & ~data_read;
	reg data_ready_reg;
	always @(posedge clk) begin
		if (data_read)
			data_ready_reg = 1'b0;
		else if (buf_full && ~sel_max)
			data_ready_reg = 1'b1;
	end
	
	assign data_out = data_out_reg;
	
	lpm_counter sel_cntr(
		.clock		(clk),
		.cnt_en		(flash_data_read),
		.sclr		(~nreset),
		.q			(sel_out),
		.cout		(sel_max)
	);
	defparam
		sel_cntr.lpm_width = SEL_DATA_WIDTH;
	
	genvar i;
	
	generate
		for (i=0; i<DATA_SIZE_DIFF; i=i+1) begin: data_buffer
			always @(posedge clk) begin
				if (flash_data_read) begin
					if (sel_out == i) begin
						data_out_reg [(DATA_IN_WIDTH*(i+1))-1:DATA_IN_WIDTH*i] = data_in[DATA_IN_WIDTH-1:0];
					end
				end
			end
		end
	endgenerate
	
	always @ (posedge clk) begin
		if(~nreset)
			buf_full = 1'b0;	
		else begin
			if (sel_max)
				buf_full = 1'b1;	
			else if (buf_full & data_read)
				buf_full = 1'b0;
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
