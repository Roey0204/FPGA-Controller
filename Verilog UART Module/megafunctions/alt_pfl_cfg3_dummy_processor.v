////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG3_DUMMY_PROCESSOR
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
// This module contains the data processor (general) of PFL Control Module
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg3_dummy_processor (
	clk,
	nreset,
	active,
	packetized,
	
	// Interface with CONV
	data_in,
	conv_data_request,
	conv_data_ready,
	conv_data_read,

	// Interface with controller/FPGA
	data_out,
	data_request,
	data_ready,
	data_read,
	
	// Interface with internal signal
	// Counter signals
	packet_size,
	counter_sload,
	counter_cnt_en,
	counter_done,
	
	// Interface with internal signal
	// Header Signals
	header_data_out,
	header_data_request,
	header_data_ready,
	header_data_read
);

	parameter CONF_DATA_WIDTH = 16;
	parameter COUNTER_WIDTH = (CONF_DATA_WIDTH == 16)? 15 : 14;
	
	input 	clk;
	input	nreset;
	input	active;
	input	packetized;

	// Interface with CONV
	input 	[CONF_DATA_WIDTH-1:0] data_in;
	output	conv_data_request;
	input 	conv_data_ready;
	output	conv_data_read;
	
	// Interface with controller/FPGA
	output	[CONF_DATA_WIDTH-1:0] data_out;
	input	data_request;
	output	data_ready;
	input	data_read;
	
	// Interface with internal signal
	// Counter signals
	input	[COUNTER_WIDTH-1:0] packet_size;
	input	counter_sload;
	input	counter_cnt_en;
	output	counter_done;
	
	// Interface with internal signal
	// Header Signals
	output	[CONF_DATA_WIDTH-1:0] header_data_out;
	input	header_data_request;
	output	header_data_ready;
	input	header_data_read;

	// basic assignment
	assign conv_data_request = nreset;
	
	reg [COUNTER_WIDTH-1:0] counter_q;
	lpm_counter	counter(
		.clock(clk),
		.cnt_en(counter_cnt_en),
		.sload(counter_sload),
		.data(packet_size),
		.q(counter_q)
	);
	defparam 
		counter.lpm_width=COUNTER_WIDTH, 
		counter.lpm_direction="DOWN";
		
	wire counter_done = counter_almost_done && counter_cnt_en;
	reg counter_almost_done;
	always @(negedge nreset or posedge clk) begin
		if (~nreset) begin
			counter_almost_done = 0;
		end
		else begin
			if ((counter_q == 1 && ~counter_cnt_en) || (counter_q == 2 && counter_cnt_en))
				counter_almost_done = 1;
			else
				counter_almost_done = 0;
		end
	end
	
	assign data_out = data_in;
	assign header_data_out = data_in;
	assign conv_data_read = (data_request && data_read) ||
									(header_data_request && header_data_read);
							
	assign data_ready = (data_request && conv_data_ready);
	assign header_data_ready = (header_data_request && conv_data_ready);
	
endmodule
