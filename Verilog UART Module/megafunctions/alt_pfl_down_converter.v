////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_DOWN_CONVERTER
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

module alt_pfl_down_converter (
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
	parameter	DATA_IN_WIDTH										= 16;
	parameter	DATA_OUT_WIDTH 									= 8;
	localparam	DATA_SIZE_DIFF										= DATA_IN_WIDTH / DATA_OUT_WIDTH;
	localparam	CONV_DONE_INDEX									= DATA_SIZE_DIFF - 1;
	localparam	COUNTER_WIDTH										= log2(CONV_DONE_INDEX);
	localparam	[COUNTER_WIDTH-1:0]	CONV_COMPARE_INDEX	= CONV_DONE_INDEX[COUNTER_WIDTH-1:0];
	
	input 	clk;
	input		nreset;

	// Interface with flash
	input 	[DATA_IN_WIDTH-1:0] data_in;
	output	flash_data_request = (current_state_is_read | current_state_is_read_e);
	input 	flash_data_ready;
	output	flash_data_read = next_state_is_read_e;
	
	// Interface with controller
	output	[DATA_OUT_WIDTH-1:0] data_out = current_state_is_read ? data_in[DATA_OUT_WIDTH-1:0] :
															data_reg[DATA_OUT_WIDTH-1:0];
	input		data_request;
	output	data_ready = (current_state_is_read && flash_data_ready) || current_state_is_read_e;
	input		data_read;
	
	/*
	reg [DATA_OUT_WIDTH-1:0] data_array [0:CONV_DONE_INDEX];
	genvar i;
	generate
		for (i=0; i<DATA_SIZE_DIFF; i=i+1) begin: ARRAY_LOOP
			always @(posedge clk) begin
				if (next_state_is_read_e) begin
					data_array[i] = data_in[(DATA_OUT_WIDTH*(i+1))-1:DATA_OUT_WIDTH*i];
				end
			end
		end
	endgenerate
	*/
	reg [DATA_IN_WIDTH-DATA_OUT_WIDTH-1:0] data_reg;
	generate
	if (DATA_SIZE_DIFF == 2) begin
		always @ (posedge clk) begin
			if (next_state_is_read_e) begin
				data_reg = data_in[DATA_IN_WIDTH-1:DATA_OUT_WIDTH];
			end
		end
	end
	else begin
		always @ (posedge clk) begin
			if (next_state_is_read_e)
				data_reg = data_in[DATA_IN_WIDTH-1:DATA_OUT_WIDTH];
			else if (current_state_is_read_e & data_read)
				data_reg = {{(DATA_OUT_WIDTH){1'b0}}, data_reg[DATA_IN_WIDTH-DATA_OUT_WIDTH-1:DATA_OUT_WIDTH]};
		end
	end
	endgenerate
	
	wire counter_en = (((current_state_is_read && flash_data_ready) ||
								current_state_is_read_e) && data_read);
	wire counter_done = (counter_q == {(COUNTER_WIDTH){1'b0}} && data_read);
	wire [COUNTER_WIDTH-1:0] counter_q;
	lpm_counter	counter(
		.clock(clk),
		.cnt_en(counter_en),
		.sload(next_state_is_read),
		.data(CONV_COMPARE_INDEX),
		.q(counter_q)
	);
	defparam counter.lpm_width=COUNTER_WIDTH, 
				counter.lpm_direction="DOWN";
	
	// STATE MACHINE	
	reg current_state_is_init;
	reg current_state_is_read;
	reg current_state_is_read_e;
	
	wire reset_state_machine = ~data_request | ~current_state_machine_active;
	// INIT
	always @ (posedge clk) begin
		current_state_is_init = reset_state_machine;
	end
	// READ
	wire next_state_is_read = current_state_is_init |
										(current_state_is_read_e & counter_done);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_read_e)
			current_state_is_read = 1'b0;
		else begin
			if (~current_state_is_read) begin
				current_state_is_read = next_state_is_read;
			end
		end
	end
	// READ_E
	wire next_state_is_read_e = (current_state_is_read & flash_data_ready && data_read);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_read)
			current_state_is_read_e = 1'b0;
		else begin
			if (~current_state_is_read_e) begin
				current_state_is_read_e = next_state_is_read_e;
			end
		end
	end
	
	reg current_state_machine_active;
	reg next_state_machine_active;
	always @ (*) begin
		case (current_state_machine_active)
			1'b0:
				next_state_machine_active = 1'b1;
			1'b1:
				next_state_machine_active = 1'b1;
			default:
				next_state_machine_active = 1'b0;
		endcase
	end
	always @ (negedge nreset or posedge clk) begin
		if (~nreset)
			current_state_machine_active = 1'b0;
		else
			current_state_machine_active = next_state_machine_active;
	end
	
	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
				value = value >> 1;
		end
	endfunction
endmodule
