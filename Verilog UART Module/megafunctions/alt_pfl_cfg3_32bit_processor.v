////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG3_32BIT_PROCESSOR
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
// This module contains the data processor (FPPx32) of PFL Control Module
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg3_32bit_processor (
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
	counter_byte_size,
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

	input 	clk;
	input	nreset;
	input	active;
	input	packetized;

	// Interface with CONV
	input 	[31:0] data_in;
	output	conv_data_request;
	input 	conv_data_ready;
	output	conv_data_read;
	
	// Interface with controller/FPGA
	output	[31:0] data_out;
	input	data_request;
	output	data_ready;
	input	data_read;
	
	// Interface with internal signal
	// Counter signals
	input	[15:0]counter_byte_size;
	input	counter_sload;
	input	counter_cnt_en;
	output	counter_done;
	
	// Interface with internal signal
	// Header Signals
	output	[31:0]header_data_out;
	input	header_data_request;
	output	header_data_ready;
	input	header_data_read;
	
	// basic assignment
	assign conv_data_request = (current_state != PC_INIT);
	
	parameter PC_SAME 			= 0;
	parameter PC_INIT 			= 1;
	parameter PC_HEADER			= 2;	// Make Life simple
	parameter PC_DATA 			= 3;
	parameter PC_WAIT 			= 4;
	parameter PC_DUMMY_MUX		= 5;
	parameter PC_UPDATE_MUX		= 6;
	parameter PC_CHECK_MUX		= 7;	// Check whether previous left over and updated left over is sufficient to form a double-word
	parameter PC_EXTRA			= 8;	// Enough
	parameter PC_LAST			= 9;	// Indicate end of the block
	
	
	parameter ZERO_CONST		= 16'h0000;
	parameter ONE_CONST			= 16'h0001;
	parameter TWO_CONST			= 16'h0002;
	parameter THREE_CONST		= 16'h0003;
	parameter FOUR_CONST		= 16'h0004;
	parameter FIVE_CONST		= 16'h0005;
	parameter SIX_CONST			= 16'h0006;
	parameter SEVEN_CONST		= 16'h0007;
	
	reg [3:0] current_state 	/* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
	reg [3:0] next_state;
	
	// Counter
	reg [15:0] counter_q;
	always @(negedge nreset or posedge clk) begin
		if(~nreset) begin
			counter_q = ZERO_CONST; 			
		end 
		else begin
			if(active && packetized) begin	// only packetize POF will activate the counter
				if(counter_sload)
					counter_q = counter_byte_size;						
				else if(current_state == PC_DATA && counter_cnt_en)
					counter_q = counter_q - FOUR_CONST;
			end
			else begin
				counter_q = ZERO_CONST; 
			end
		end
	end
	
	// alignment
	// alignment is to align the half double word
	// need_alignment is used to indicate (at the begin of process) current packet need alignment or not
	// it doesn't have immediate effect to the process yet
	reg need_alignment;
	always @(negedge nreset or posedge clk) begin
		if(~nreset) begin
			need_alignment = 1'b0; 			
		end 
		else begin
			if (active && packetized) begin	
				if (counter_sload) begin
					if(counter_byte_size[0] ^ counter_byte_size[1]) begin
						need_alignment = ~need_alignment;
					end
				end
			end
			else begin
				need_alignment = 1'b0; 
			end
		end
	end
	
	// base on need_alignment to determine this process need alignment or not
	reg alignment;
	always @(negedge nreset or posedge clk) begin
		if(~nreset) begin
			alignment = 1'b0; 			
		end 
		else begin
			if (active && packetized) begin	
				if (current_state != PC_INIT &&
					next_state == PC_HEADER) begin
					alignment = need_alignment;
				end
			end
			else begin
				alignment = 1'b0; 
			end
		end
	end
	
	// skip_read indicate whether we need to read next data while updating mux
	reg skip_read;
	always @(negedge nreset or posedge clk) begin
		if(~nreset) begin
			skip_read = 1'b0; 			
		end 
		else begin
			if (active && packetized) begin	
				if (counter_sload) begin
					if(counter_byte_size[0] ^ counter_byte_size[1])
						skip_read = alignment;
					else
						skip_read = 1'b0;
				end
			end
			else begin
				skip_read = 1'b0; 
			end
		end
	end
	
	
	reg [15:0] half_align_data;
	always @(posedge clk) begin
		if (conv_data_ready && conv_data_read) begin
			half_align_data = data_in[31:16];
		end
	end
	
	wire [47:0] aligned_data = alignment? {data_in[31:0], half_align_data} : {16'h0000, data_in};
	
	// MUX indication
	wire last_three = (counter_q == FIVE_CONST || counter_q == SIX_CONST || counter_q == SEVEN_CONST);
	wire [1:0] left_over = counter_q[1:0];
	
	reg [2:0] total;
	always @(negedge nreset or posedge clk) begin
		if(~nreset) begin
			total = 3'd0; 	
		end 
		else begin
			if(active && packetized) begin						// only packetize POF will activate the mux
				if(current_state == PC_CHECK_MUX) begin
					total = total_wire;
				end
				else if(current_state == PC_EXTRA) begin
					total[2] = 0;
				end
			end
			else begin
				total = 3'd0; 
			end
		end
	end
	
	wire [2:0] total_wire = total + {1'b0, left_over};
	wire sufficient = total_wire[2];
	
	wire [55:0] processed_data = (total[1:0] == 2'd3)? {aligned_data[31:0], data_reg[23:0]} :
								 (total[1:0] == 2'd2)? {aligned_data[39:0], data_reg[15:0]} :
								 (total[1:0] == 2'd1)? {aligned_data[47:0], data_reg[7:0]} : {8'h00, aligned_data};
	reg [55:0] data_reg;
	always @(posedge clk) begin
		if (current_state == PC_DATA && conv_data_ready && data_read) begin
			// total haven't been updated yet
			if (total[1:0] == 2'd0)
				data_reg[47:0] = aligned_data;
			else if (total[1:0] == 2'd1)
				data_reg[23:0] = aligned_data[47:24];
			else if (total[1:0] == 2'd2)
				data_reg[31:0] = aligned_data[31:16];
			else if (total[1:0] == 2'd3)
				data_reg[39:0] = aligned_data[31:8];
		end
		else if (current_state == PC_UPDATE_MUX && conv_data_ready) begin
			// total haven't been updated yet
			data_reg = processed_data;
		end
		else if (current_state == PC_DUMMY_MUX) begin
			// total haven't been updated yet
			data_reg = processed_data;
		end
		else if (current_state == PC_LAST && need_adjustment) begin
			// get rid first 32 bits
			data_reg[23:0] = data_reg[55:32];
		end
	end
	
	reg need_adjustment;
	always @(posedge clk) begin
		if (current_state == PC_EXTRA)
			need_adjustment = 1'b1;
		else 
			need_adjustment = 1'b0;
	end

	assign data_out = (current_state == PC_EXTRA) ? data_reg[31:0] : processed_data[31:0];
	assign header_data_out = aligned_data[31:0];
	assign counter_done = active && packetized && 
							(current_state == PC_UPDATE_MUX ||
								current_state == PC_CHECK_MUX ||
								current_state == PC_EXTRA ||
								current_state == PC_LAST);
	
	// exclude PC_EXTRA since this is data cascaded from two packet
	assign conv_data_read = (current_state == PC_DATA && data_read) ||
							(current_state == PC_HEADER && header_data_read) ||
							(current_state == PC_UPDATE_MUX && conv_data_ready);
	assign data_ready = (current_state == PC_DATA && conv_data_ready) || (current_state == PC_EXTRA);
	assign header_data_ready = (current_state == PC_HEADER && conv_data_ready);
	
	always @(nreset, active, current_state, header_data_request, data_request,
				counter_q, data_read, conv_data_ready, last_three, sufficient, left_over,
				skip_read)
	begin
		if (~nreset) begin
			next_state = PC_INIT;
		end
		else begin
			case (current_state)
				PC_INIT:
					if(active)
						if(header_data_request)
							next_state = PC_HEADER;
						else if(data_request)
							next_state = PC_DATA;
						else
							next_state = PC_SAME;
					else
						next_state = PC_SAME;
				PC_HEADER:
					if(conv_data_ready)
						next_state = PC_WAIT;
					else
						next_state = PC_SAME;
				PC_DATA:
					if(last_three && data_read) begin		// There is dummy
						if (skip_read)
							next_state = PC_DUMMY_MUX;
						else
							next_state = PC_UPDATE_MUX;
					end
					else if(counter_q == FOUR_CONST && data_read)
						next_state = PC_DUMMY_MUX;
					else
						next_state = PC_SAME;
				PC_DUMMY_MUX:
					if (left_over == 2'b00)
						next_state = PC_LAST;
					else 
						next_state = PC_CHECK_MUX;
				PC_UPDATE_MUX:
					if (left_over == 2'b00)
						next_state = PC_LAST;
					else if (conv_data_ready)
						next_state = PC_CHECK_MUX;
					else
						next_state = PC_SAME;
				PC_CHECK_MUX:
					if (sufficient)
						next_state = PC_EXTRA;
					else
						next_state = PC_LAST;
				PC_EXTRA:
					if (data_read)
						next_state = PC_LAST;
					else
						next_state = PC_SAME;
				PC_LAST:
					if(header_data_request)
						next_state = PC_HEADER;
					else
						next_state = PC_WAIT;
				PC_WAIT:
					if(header_data_request)
						next_state = PC_HEADER;
					else if(data_request)
						next_state = PC_DATA;
					else
						next_state = PC_SAME;
				default:
					next_state = PC_INIT;
			endcase
		end
	end

	initial begin
		current_state = PC_INIT;
	end

	always @(negedge nreset or posedge clk)
	begin
		if(~nreset) begin
			current_state = PC_INIT;
		end
		else begin
			if (next_state != PC_SAME) begin
				current_state = next_state;
			end
		end
	end
	
endmodule
