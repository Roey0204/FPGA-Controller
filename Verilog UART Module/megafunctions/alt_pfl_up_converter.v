////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_UP_CONVERTER
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

module alt_pfl_up_converter (
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
	parameter	DATA_IN_WIDTH										= 8;
	parameter	DATA_OUT_WIDTH										= 16;
	localparam	DATA_SIZE_DIFF										= DATA_OUT_WIDTH / DATA_IN_WIDTH;
	localparam	CONV_DONE_INDEX									= DATA_SIZE_DIFF - 1;
	localparam 	COUNTER_WIDTH										= log2(CONV_DONE_INDEX);
	localparam	[COUNTER_WIDTH-1:0]	CONV_COMPARE_INDEX	= CONV_DONE_INDEX[COUNTER_WIDTH-1:0];
	
	input 	clk;
	input		nreset;

	// Interface with flash
	input 	[DATA_IN_WIDTH-1:0] data_in;
	output	flash_data_request = (current_state == CONV_READ || current_state == CONV_WAIT);
	input 	flash_data_ready;
	output	flash_data_read = (current_state == CONV_READ && flash_data_ready);
	
	// Interface with controller
	output	[DATA_OUT_WIDTH-1:0] data_out = fifo_data_out;
	input		data_request;
	output	data_ready = ~fifo_empty;
	input		data_read;
	
	
	reg [1:0] current_state;
	reg [1:0] next_state;
	localparam CONV_SAME 	= 2'd0;
	localparam CONV_INIT		= 2'd1;
	localparam CONV_READ		= 2'd2;
	localparam CONV_WAIT		= 2'd3;
	
	reg	[DATA_OUT_WIDTH-1:0] flash_data;
	wire	[DATA_OUT_WIDTH-1:0] fifo_data_out;
	wire	[DATA_OUT_WIDTH-1:0] fifo_data_in = (current_state == CONV_READ)? {data_in, flash_data[DATA_OUT_WIDTH-DATA_IN_WIDTH-1:0]} :
																									flash_data;
	
	genvar i;
	generate
		for (i=0; i<DATA_SIZE_DIFF; i=i+1) begin: CONV_LOOP
			always @ (posedge clk) begin
				if (current_state == CONV_READ & flash_data_ready) begin
					if (counter_q == i[COUNTER_WIDTH-1:0]) begin
						flash_data[(DATA_IN_WIDTH*(i+1))-1:DATA_IN_WIDTH*i] = data_in;
					end
				end
			end
		end
	endgenerate
	
	wire counter_en = flash_data_read;
	wire counter_done = (counter_q == CONV_COMPARE_INDEX);
	wire [COUNTER_WIDTH-1:0] counter_q;
	lpm_counter	counter(
		.clock(clk),
		.cnt_en(counter_en),
		.sclr(next_state == CONV_READ),
		.q(counter_q)
	);
	defparam counter.lpm_width=COUNTER_WIDTH, 
				counter.lpm_direction="UP";
	
	wire fifo_full;
	wire fifo_empty;
	wire rd_fifo = data_read;
	wire wr_fifo = ((current_state == CONV_READ || current_state == CONV_WAIT) && next_state == CONV_READ);
	alt_pfl_fifo compressed_fifo (
		.clock(clk),
		.data(fifo_data_in),
		.empty(fifo_empty),
		.full(fifo_full),
		.q(fifo_data_out),
		.rdreq(rd_fifo),
		.sclr(~data_request),
		.wrreq(wr_fifo),
		.aclr(~nreset)
	);
	defparam
	compressed_fifo.WIDTH = DATA_OUT_WIDTH,
	compressed_fifo.NUMWORDS = 2,
	compressed_fifo.LOOKAHEAD = "ON";
	
	always @ (current_state, data_request, counter_done, flash_data_ready, fifo_full) begin
		if (~data_request)
			next_state = CONV_INIT;
		else begin
			case (current_state)
				CONV_INIT:
					if (data_request)
						next_state = CONV_READ;
					else
						next_state = CONV_SAME;
				CONV_READ:
					if (counter_done & flash_data_ready) begin
						if (fifo_full)
							next_state = CONV_WAIT;
						else
							next_state = CONV_READ;
					end
					else
						next_state = CONV_SAME;
				CONV_WAIT:
					if (fifo_full)
						next_state = CONV_SAME;
					else
						next_state = CONV_READ;
				default:
					next_state = CONV_INIT;
			endcase
		end
	end
	
	always @ (negedge nreset or posedge clk) begin
		if (~nreset) 
			current_state = CONV_INIT;
		else begin
			if (next_state != CONV_SAME)
				current_state = next_state;
		end
	end
	
	initial begin
		current_state = CONV_INIT;
	end
	
	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
				value = value >> 1;
		end
	endfunction
	
endmodule
