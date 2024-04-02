////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG3_16BIT_PROCESSOR
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
// This module contains the data processor (FPPx16) of PFL Control Module
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg3_16bit_processor (
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
	input 	[15:0] data_in;
	output	conv_data_request;
	input 	conv_data_ready;
	output	conv_data_read;
	
	// Interface with controller/FPGA
	output	[15:0] data_out;
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
	output	[15:0]header_data_out;
	input	header_data_request;
	output	header_data_ready;
	input	header_data_read;
	
	// basic assignment
	assign conv_data_request = (current_state != PC_INIT);
	
	parameter PC_SAME 			= 0;
	parameter PC_INIT 			= 1;
	parameter PC_HEADER1		= 2;	// Make Life simple
	parameter PC_HEADER2		= 3;	// Make Life simple
	parameter PC_DATA 			= 4;
	parameter PC_WAIT 			= 5;
	parameter PC_UPDATE_MUX		= 6;
	parameter PC_CHECK_MUX		= 7;	// Check whether previous left over and updated left over is sufficient to form a word
	parameter PC_EXTRA			= 8;	// Enough
	parameter PC_LAST			= 9;	// Indicate end of the block
	
	
	parameter ZERO_CONST		= 16'h0000;
	parameter ONE_CONST			= 16'h0001;
	parameter TWO_CONST			= 16'h0002;
	parameter THREE_CONST		= 16'h0003;
	
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
					counter_q = counter_q - TWO_CONST;
			end
			else begin
				counter_q = ZERO_CONST; 
			end
		end
	end
	
	wire left_over = counter_q[0];
	wire is_header = (current_state == PC_HEADER1 || current_state == PC_HEADER2);
	
	reg [1:0] total;
	always @(negedge nreset or posedge clk) begin
		if(~nreset) begin
			total = 2'd0; 	
		end 
		else begin
			if(active && packetized) begin						// only packetize POF will activate the mux
				if(current_state == PC_UPDATE_MUX && conv_data_ready) begin
					total = total_wire;
				end
				else if(current_state == PC_EXTRA) begin
					total[1] = 0;
				end
			end
			else begin
				total = 2'd0; 
			end
		end
	end
	
	wire [1:0] total_wire = total + {1'b0, left_over};
	wire sufficient = total_wire[1];
	
	wire [23:0] processed_data = (total[0] == 1'd1)? {data_in, data_reg[7:0]} : {8'h00, data_in};
	
	reg [23:0] data_reg;
	always @(posedge clk) begin
		if (current_state == PC_DATA && conv_data_ready && data_read) begin
			// total haven't been updated yet
			if (total[0] == 1'd0)
				data_reg[15:0] = data_in;
			else
				data_reg[7:0] = data_in[15:8];
		end
		else if (current_state == PC_UPDATE_MUX && conv_data_ready) begin
			// total haven't been updated yet
			data_reg = processed_data;
		end
		else if (current_state == PC_LAST && need_adjustment) begin
			// get rid first 16 bits
			data_reg[7:0] = data_reg[23:16];
		end
	end
	
	reg need_adjustment;
	always @(posedge clk) begin
		if (current_state == PC_EXTRA)
			need_adjustment = 1'b1;
		else 
			need_adjustment = 1'b0;
	end

	assign data_out = (current_state == PC_EXTRA) ? data_reg[15:0] : processed_data[15:0];
	assign header_data_out = data_in;
	assign counter_done = active && packetized && 
							(current_state == PC_UPDATE_MUX ||
								current_state == PC_EXTRA ||
								current_state == PC_LAST);
							
	// exclude PC_EXTRA since this is data cascaded from two packet
	assign conv_data_read = (current_state == PC_DATA && data_read) ||
							(is_header && header_data_read) ||
							(current_state == PC_UPDATE_MUX && conv_data_ready);
							
	assign data_ready = (current_state == PC_DATA && conv_data_ready) || (current_state == PC_EXTRA);
	assign header_data_ready = (is_header && conv_data_ready);
	
	always @(nreset, active, current_state, header_data_request, data_request,
				counter_q, data_read, conv_data_ready, sufficient)
	begin
		if (~nreset) begin
			next_state = PC_INIT;
		end
		else begin
			case (current_state)
				PC_INIT:
					if(active)
						if(header_data_request)
							next_state = PC_HEADER1;
						else if(data_request)
							next_state = PC_DATA;
						else
							next_state = PC_SAME;
					else
						next_state = PC_SAME;
				PC_HEADER1:
					if(conv_data_ready)
						next_state = PC_HEADER2;
					else
						next_state = PC_SAME;
				PC_HEADER2:
					if(conv_data_ready)
						next_state = PC_WAIT;
					else
						next_state = PC_SAME;
				PC_DATA:
					if(counter_q == THREE_CONST && data_read)	
						next_state = PC_UPDATE_MUX;
					else if(counter_q == TWO_CONST && data_read)	
						next_state = PC_LAST;
					else
						next_state = PC_SAME;
				PC_UPDATE_MUX:
					if (conv_data_ready) begin
						if (sufficient)
							next_state = PC_EXTRA;
						else
							next_state = PC_LAST;
					end
					else
						next_state = PC_SAME;		
				PC_EXTRA:
					if (data_read)
						next_state = PC_LAST;
					else
						next_state = PC_SAME;
				PC_LAST:
					if(header_data_request)
						next_state = PC_HEADER1;
					else
						next_state = PC_WAIT;
				PC_WAIT:
					if(header_data_request)
						next_state = PC_HEADER1;
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
