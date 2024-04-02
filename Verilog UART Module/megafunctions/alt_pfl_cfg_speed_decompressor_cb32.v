////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG_SPEED_DECOMPRESSOR_CB32
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
// This module contains the PFL configuration decompressor block (speed)
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg_speed_decompressor_cb32 (
	clk,
	nreset,
	
	// Control block interface
	flash_data_ready,
	flash_data_read,
	flash_data,
	control_ready,
	
	// FPGA configuration block interface
	fpga_data,
	fpga_data_ready,
	fpga_data_read,
	
	enable
);	
	parameter CONF_DATA_WIDTH = 16;
	localparam THREAD_COUNTER_WIDTH = (CONF_DATA_WIDTH == 16)? 11 : 10;
	localparam THREAD_COUNTER_LEAST_INDEX = (CONF_DATA_WIDTH == 16)? 1 : 2;
	localparam THREAD_COUNTER_LOAD_ONE = 1;
	localparam NUMBER_OF_VARIABLE_DUPLICATION = CONF_DATA_WIDTH / 8;
	
	wire [7:0] flash_data_in;
	wire flash_data_ready_in;
	wire flash_data_read_in;
	
	generate
	if (CONF_DATA_WIDTH == 8) begin
		assign flash_data_in = flash_data;
		assign flash_data_ready_in = flash_data_ready;
		assign flash_data_read_in = flash_data_read_wire;
	end
	else begin
		alt_pfl_down_converter alt_pfl_down_converter(
				.clk(clk),
				.nreset(nreset),
				
				// Interface with flash
				.data_in(flash_data),
				//.flash_data_request(), // do not need to request, CONTROL will request for you
				.flash_data_ready(flash_data_ready),
				.flash_data_read(flash_data_read_in),
				
				// Interface with controller (Processor)
				.data_out(flash_data_in),
				.data_request(current_state != DCMP_INIT),
				.data_ready(flash_data_ready_in),
				.data_read(flash_data_read_wire)
			);
			defparam
				alt_pfl_down_converter.DATA_IN_WIDTH = CONF_DATA_WIDTH,
				alt_pfl_down_converter.DATA_OUT_WIDTH = 8;
	end
	endgenerate
	
	input 	clk;
	input 	nreset;
	
	input	flash_data_ready;
	output	flash_data_read;
	input	[CONF_DATA_WIDTH-1:0] flash_data;
	input	control_ready;
	
	output	[CONF_DATA_WIDTH-1:0] fpga_data;
	output	fpga_data_ready;
	input	fpga_data_read;
	
	input 	enable;

	reg [3:0] current_state /* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
	reg [3:0] next_state;
	
	// State machine
	parameter DCMP_SAME 						= 4'd0;
	parameter DCMP_INIT 						= 4'd1;	// wait FLASH to be ready
	parameter DCMP_HEADER 					= 4'd2;
	parameter DCMP_SECOND_HEADER			= 4'd3;
	parameter DCMP_VARIABLE_DATA			= 4'd4;
	parameter DCMP_UPDATE_FIFO_WAIT		= 4'd5;
	parameter DCMP_UPDATE_FIFO				= 4'd6;
	parameter DCMP_RAW_DATA 				= 4'd7;
	parameter DCMP_NIBBLE_SIZE				= 4'd8;
	parameter DCMP_NIBBLE_BIT				= 4'd9;
	parameter DCMP_NIBBLE					= 4'd10;
	
	parameter THREAD_SAME					= 3'd0;
	parameter THREAD_INIT					= 3'd1;
	parameter THREAD_HEADER					= 3'd2;
	parameter THREAD_INTERPRETE			= 3'd3;
	parameter THREAD_VARIABLE_DATA		= 3'd4;
	parameter THREAD_RAW_DATA				= 3'd5;
	
	wire [7:0] nibble_data;
	
	wire [CONF_DATA_WIDTH-1:0] fpga_data_wire = (thread_current_state == THREAD_VARIABLE_DATA) ? 
																{(NUMBER_OF_VARIABLE_DUPLICATION){header_variable_out}}: 
																data_fifo_out;
	wire fpga_data_ready_wire = thread_current_state == THREAD_VARIABLE_DATA || 
								(thread_current_state == THREAD_RAW_DATA && raw_data_ready);
	wire flash_data_read_wire = ( (~data_fifo_full && (current_state == DCMP_RAW_DATA || 
								 (current_state == DCMP_NIBBLE && need_extra_data))) ||
								 current_state == DCMP_HEADER ||
								 current_state == DCMP_SECOND_HEADER ||
								 current_state == DCMP_VARIABLE_DATA || 
								 current_state == DCMP_NIBBLE_BIT) && flash_data_ready_in;
	// version4
	assign fpga_data_ready = enable? fpga_data_ready_wire : flash_data_ready;
	assign fpga_data = enable? fpga_data_wire: flash_data;
	assign flash_data_read = enable? flash_data_read_in : fpga_data_read;
							 
	reg [11:0] 	header_size;
	always @(posedge clk)
	begin
		if(current_state == DCMP_HEADER && flash_data_ready_in) begin
			header_size[11:4] = 8'b0;
			header_size[3:0] = flash_data_in[3:0];
		end
		else if(current_state == DCMP_SECOND_HEADER && flash_data_ready_in) begin
			header_size[11:4] = flash_data_in;
		end
	end
	
	reg compressed_variable;
	reg compressed_none;
	reg compressed_nibble;
	reg compressed_data;
	reg[7:0] variable;
	
	always @(posedge clk)
	begin
		if(current_state == DCMP_HEADER && flash_data_ready_in) begin
			compressed_variable = (flash_data_in[6:4] == 3'b010);
			compressed_none = (flash_data_in[6:4] == 3'b101);
			compressed_nibble = (flash_data_in[6:4] == 3'b100);
			compressed_data = ~(flash_data_in[6:5] == 3'b10);
		end
	end
	
	always @(posedge clk) begin
		if(current_state == DCMP_HEADER) begin
			if (flash_data_in[6:5] == 2'b00 || flash_data_in[6:4] == 3'b110)
				variable = 8'h00;
			else if(flash_data_in[6:4] == 3'b111)
				variable = 8'hFF;
		end
		else if(current_state == DCMP_VARIABLE_DATA && flash_data_ready_in)
			variable = flash_data_in;
	end
	
	reg [11:0] decompress_count_q;
	wire sclr_decompress_counter = 	next_state == DCMP_RAW_DATA ||
									(next_state == DCMP_NIBBLE_SIZE && current_state != DCMP_NIBBLE);
	wire en_decompress_counter = (current_state == DCMP_RAW_DATA || current_state == DCMP_NIBBLE);
	lpm_counter decompress_counter (
		.clock(clk),
		.cnt_en(en_decompress_counter && ~data_fifo_full && flash_data_ready_in),
		.sclr(sclr_decompress_counter),
		.q(decompress_count_q)
	);
	defparam
	decompress_counter.lpm_type = "LPM_COUNTER",
	decompress_counter.lpm_direction= "UP",
	decompress_counter.lpm_width = 12;
	
	reg [3:0] nibble_count_q;
	always @(posedge clk)
	begin
		if(next_state == DCMP_NIBBLE_SIZE)
			nibble_count_q[3:0] = 4'b0001;
		else if(current_state == DCMP_NIBBLE_BIT && flash_data_ready_in)
			nibble_count_q[3:0] = {nibble_count_q[2:0], 1'b0};
	end

	
	reg [3:0] byte_count_q;	
	wire en_byte_counter = current_state == DCMP_NIBBLE && ~data_fifo_full && flash_data_ready_in;
	lpm_counter byte_counter (
		.clock(clk),
		.cnt_en(en_byte_counter),
		.sclr(next_state == DCMP_NIBBLE),
		.q(byte_count_q)
	);
	defparam
	byte_counter.lpm_type = "LPM_COUNTER",
	byte_counter.lpm_direction= "UP",
	byte_counter.lpm_width = 4;
	
	reg [33:0] nibble_info;
	always @(posedge clk) begin
		nibble_info[33:32] = 2'b00;
	end
	genvar i;
	generate
		for (i=0; i<4; i=i+1) begin: NIBBLE_INFO_LOOP
			always @(posedge clk) begin
				if (current_state == DCMP_NIBBLE_BIT && flash_data_ready_in) begin
					if (nibble_count_q[i]) begin
						nibble_info[i*8+7:i*8] 	 = flash_data_in[7:0];
					end
				end
				else if (en_byte_counter) begin
					nibble_info[i*8+7:i*8] = nibble_info[(i+1)*8+1:i*8+2];
				end
				else if(next_state == DCMP_NIBBLE_BIT || next_state == DCMP_HEADER) begin
					nibble_info[i*8+7:i*8] = 8'h00;
				end
			end
		end
	endgenerate
	
	reg replace_all;					// when both nibble is high
	reg current_accumulate_extra_data;	//
	reg advanced_accumulate_exra_data; 
	reg replace_front_nibble;
	reg replace_end_nibble;
	reg need_extra_data;				// 
	always @(posedge clk) begin
		if(en_byte_counter) begin
			replace_all <= nibble_info[3:2] == 2'b11;
			replace_front_nibble <= nibble_info[3:2] == 2'b10;
			replace_end_nibble <= nibble_info[3:2] == 2'b01;
			current_accumulate_extra_data <= current_accumulate_extra_data ^ nibble_info[1] ^ nibble_info[0];
			advanced_accumulate_exra_data <= advanced_accumulate_exra_data ^ nibble_info[3] ^ nibble_info[2];
			need_extra_data <= (nibble_info[3:2] == 2'b11) || ((nibble_info[3] ^ nibble_info[2]) && (~advanced_accumulate_exra_data));
		end
		else if (current_state == DCMP_NIBBLE_BIT && flash_data_ready_in) begin
			if (nibble_count_q[0]) begin
				replace_all <= flash_data_in[1:0] == 2'b11;
				replace_front_nibble <= flash_data_in[1:0] == 2'b10;
				replace_end_nibble <= flash_data_in[1:0] == 2'b01;
				need_extra_data <= flash_data_in[1:0] == 2'b11 || (flash_data_in[1] ^ flash_data_in[0]);
				advanced_accumulate_exra_data <= flash_data_in[1] ^ flash_data_in[0];
			end
		end
		else if(next_state == DCMP_NIBBLE_BIT || next_state == DCMP_HEADER) begin
			replace_all <= 0;
			replace_front_nibble <= 0;
			replace_end_nibble <= 0;
			current_accumulate_extra_data <= 0;
			advanced_accumulate_exra_data <= 0;
			need_extra_data <= 0;
		end
	end
	
	assign nibble_data = replace_all? (current_accumulate_extra_data ? {flash_data_in[3:0], previous_flash_data[7:4]} : flash_data_in) :
							replace_front_nibble? (current_accumulate_extra_data ? {previous_flash_data[7:4], 4'b0000} : {flash_data_in[3:0], 4'b0000}) :
							replace_end_nibble? (current_accumulate_extra_data ? {4'b0000, previous_flash_data[7:4]} : {4'b0000, flash_data_in[3:0]}) :
							8'h00;
	
	reg [7:0]previous_flash_data;
	always @(posedge clk) begin
		if(flash_data_read_wire)
			previous_flash_data = flash_data_in;		
	end
			
	wire[11:0] diff_size = header_size - decompress_count_q;
	reg[1:0] nibble_size;
	always @(posedge clk) begin
		if(current_state == DCMP_NIBBLE_SIZE) begin
			if(diff_size < 4)
				nibble_size = 0;
			else if(diff_size < 8)
				nibble_size  = 1;
			else if(diff_size < 12)
				nibble_size = 2;
			else
				nibble_size = 3;
		end
	end
	
	wire compressed_fifo_full;
	wire compressed_fifo_empty;
	reg [THREAD_COUNTER_WIDTH-1:0] header_count_out;
	reg [7:0] header_variable_out;
	reg header_compressed_data;
	wire [THREAD_COUNTER_WIDTH+8+1-1:0] compressed_data_pre_q;
	reg wr_compressed_fifo;
	reg rd_compressed_fifo;
	always @(posedge clk) begin
		wr_compressed_fifo = next_state == DCMP_UPDATE_FIFO;
		rd_compressed_fifo = thread_next_state == THREAD_INTERPRETE;
	end
	always @(posedge clk) begin
		if (thread_next_state == THREAD_INTERPRETE) begin
			header_count_out = compressed_data_pre_q[THREAD_COUNTER_WIDTH+8+1-1:9];
			header_variable_out = compressed_data_pre_q[8:1];
			header_compressed_data = compressed_data_pre_q[0];
		end
	end
	alt_pfl_fifo compressed_fifo (
		.clock(clk),
		.data({header_size[11:THREAD_COUNTER_LEAST_INDEX], variable, compressed_data}),
		.empty(compressed_fifo_empty),
		.full(compressed_fifo_full),
		.q(compressed_data_pre_q),
		.rdreq(rd_compressed_fifo),
		.sclr(current_state == DCMP_INIT),
		.wrreq(wr_compressed_fifo),
		.aclr(~nreset)
	);
	defparam
	compressed_fifo.WIDTH = THREAD_COUNTER_WIDTH + 8 + 1,
	compressed_fifo.NUMWORDS = 4,
	compressed_fifo.LOOKAHEAD = "ON";
	
	reg [CONF_DATA_WIDTH-8-1:0] stored_data;
	wire write_fifo;
	generate
	if (CONF_DATA_WIDTH == 16) begin
		assign write_fifo = decompress_count_q[0] == 1'b1;
		always @ (posedge clk) begin
			if (current_state == DCMP_RAW_DATA && flash_data_ready_in) begin
				if (decompress_count_q[0] == 1'b0) begin
					stored_data = flash_data_in;
				end
			end
			else if (current_state == DCMP_NIBBLE && flash_data_ready_in) begin
				if (decompress_count_q[0] == 1'b0) begin
					stored_data = nibble_data;
				end
			end
		end
	end
	else begin
		assign write_fifo = decompress_count_q[1:0] == 2'b11;
		always @ (posedge clk) begin
			if (current_state == DCMP_RAW_DATA && flash_data_ready_in) begin
				if (decompress_count_q[1:0] == 2'b00) begin
					stored_data[7:0] = flash_data_in;
				end
				else if (decompress_count_q[1:0] == 2'b01) begin
					stored_data[15:8] = flash_data_in;
				end
				else if (decompress_count_q[1:0] == 2'b10) begin
					stored_data[23:16] = flash_data_in;
				end
			end
			else if (current_state == DCMP_NIBBLE && flash_data_ready_in) begin
				if (decompress_count_q[1:0] == 2'b00) begin
					stored_data[7:0] = nibble_data;
				end
				else if (decompress_count_q[1:0] == 2'b01) begin
					stored_data[15:8] = nibble_data;
				end
				else if (decompress_count_q[1:0] == 2'b10) begin
					stored_data[23:16] = nibble_data;
				end
			end
		end
	end
	endgenerate
	
	reg [CONF_DATA_WIDTH-1:0] fifo_data_reg;
	reg data_fifo_write;
	reg data_fifo_read;
	always @ (negedge clk) begin
		fifo_data_reg = (current_state == DCMP_RAW_DATA) ? {flash_data_in, stored_data} : {nibble_data, stored_data};
		data_fifo_write = (current_state == DCMP_RAW_DATA || current_state == DCMP_NIBBLE) && flash_data_ready_in && write_fifo;
		data_fifo_read = fifo_next_state == FIFO_DATA;
	end
	wire data_fifo_empty;
	wire data_fifo_full;
	wire [CONF_DATA_WIDTH-1:0] data_fifo_out_wire;
	reg [CONF_DATA_WIDTH-1:0] data_fifo_out;
	always @(posedge clk) begin
		if (fifo_next_state == FIFO_DATA)
			data_fifo_out = data_fifo_out_wire;
	end
	alt_pfl_fifo data_fifo (
		.clock(clk),
		.full(data_fifo_full),
		.empty(data_fifo_empty),
		.data(fifo_data_reg),
		.q(data_fifo_out_wire),
		.rdreq(data_fifo_read),
		.sclr(current_state == DCMP_INIT),
		.wrreq(data_fifo_write),
		.aclr(~nreset)
	);
	defparam
	data_fifo.WIDTH = CONF_DATA_WIDTH,
	data_fifo.NUMWORDS = 16,
	data_fifo.LOOKAHEAD = "ON";

	always @(nreset, current_state, fpga_data_read, flash_data_ready_in, flash_data_in, 
				decompress_count_q, byte_count_q, nibble_size, header_size, compressed_none,
				 compressed_variable, compressed_nibble, control_ready, 
				 nibble_count_q, compressed_fifo_full, data_fifo_full, enable
			)
	begin
		if (~nreset | ~control_ready | ~enable)
			next_state = DCMP_INIT;
		else begin
			case (current_state)
				DCMP_INIT:	// 1
					if(control_ready)
						next_state = DCMP_HEADER;
					else
						next_state = DCMP_SAME;
				DCMP_HEADER:	// 2
					if (flash_data_ready_in) begin
						if(flash_data_in[7])
							next_state = DCMP_SECOND_HEADER;
						else begin
							if(flash_data_in[6:5] == 2'b01)			// compressed variable
								next_state = DCMP_VARIABLE_DATA;
							else begin
								next_state = DCMP_UPDATE_FIFO_WAIT;
							end
						end
					end
					else
						next_state = DCMP_SAME;
				DCMP_SECOND_HEADER:	// 3
					if (flash_data_ready_in) begin
						if(compressed_variable)
							next_state = DCMP_VARIABLE_DATA;
						else begin
							next_state = DCMP_UPDATE_FIFO_WAIT;
						end
					end
					else
						next_state = DCMP_SAME;
				DCMP_VARIABLE_DATA:	// 4
					if (flash_data_ready_in) begin
						next_state = DCMP_UPDATE_FIFO_WAIT;
					end
					else
						next_state = DCMP_SAME;
				DCMP_UPDATE_FIFO_WAIT:	// 5
					if(compressed_fifo_full)
						next_state = DCMP_SAME;
					else
						next_state = DCMP_UPDATE_FIFO;
				DCMP_UPDATE_FIFO:	// 6
					if(compressed_nibble)
						next_state = DCMP_NIBBLE_SIZE;
					else if(compressed_none)
						next_state = DCMP_RAW_DATA;
					else
						next_state = DCMP_HEADER;
				DCMP_RAW_DATA:		// 7
					if((decompress_count_q == header_size) && flash_data_ready_in && ~data_fifo_full) begin
						next_state = DCMP_HEADER;
					end
					else
						next_state = DCMP_SAME;
				DCMP_NIBBLE_SIZE:	// 8					
					next_state = DCMP_NIBBLE_BIT;
				DCMP_NIBBLE_BIT:	// 9
					if((nibble_count_q[nibble_size]) && flash_data_ready_in)
						next_state = DCMP_NIBBLE;
					else
						next_state = DCMP_SAME;		
				DCMP_NIBBLE:		// 10
					if(decompress_count_q == header_size && flash_data_ready_in && ~data_fifo_full)
						next_state = DCMP_HEADER;
					else if(byte_count_q == 4'd15 && flash_data_ready_in && ~data_fifo_full)
						next_state = DCMP_NIBBLE_SIZE;
					else
						next_state = DCMP_SAME;
				default:
					next_state = DCMP_INIT;
			endcase
		end
	end

	initial begin
		current_state = DCMP_INIT;
	end

	always @(negedge nreset or posedge clk)
	begin
		if(~nreset) begin
			current_state = DCMP_INIT;
		end
		else begin
			if (next_state != DCMP_SAME) begin
				current_state = next_state;
			end
		end
	end
	
	///////////////////////////////////////////////
	// second thread to send data to FPGA block  //

	reg [2:0] thread_current_state;
	reg [2:0] thread_next_state;
	
	wire [THREAD_COUNTER_WIDTH-1:0] thread_count_q;
	wire sclr_thread_counter = thread_next_state == THREAD_VARIABLE_DATA || thread_next_state == THREAD_RAW_DATA;
	wire en_thread_counter = thread_current_state == THREAD_VARIABLE_DATA || (thread_current_state == THREAD_RAW_DATA && raw_data_ready);
	lpm_counter thread_counter (
		.clock(clk),
		.cnt_en(en_thread_counter && fpga_data_read),
		.sclr(sclr_thread_counter),
		.q(thread_count_q)
	);
	defparam
	thread_counter.lpm_type = "LPM_COUNTER",
	thread_counter.lpm_direction= "UP",
	thread_counter.lpm_width = THREAD_COUNTER_WIDTH;

	always @(nreset, thread_current_state, control_ready, thread_count_q, header_compressed_data, 
				fpga_data_read, header_count_out, compressed_fifo_empty, enable
				)
	begin
		if (~nreset | ~control_ready | ~enable)
			thread_next_state = THREAD_INIT;
		else begin
			case (thread_current_state)
				THREAD_INIT:  // 1
					if(control_ready)
						thread_next_state = THREAD_HEADER;
					else
						thread_next_state = THREAD_SAME;
				THREAD_HEADER: // 2
					if (compressed_fifo_empty)
						thread_next_state = THREAD_SAME;
					else
						thread_next_state = THREAD_INTERPRETE;
				THREAD_INTERPRETE: // 3
					if (header_compressed_data)
						thread_next_state = THREAD_VARIABLE_DATA;
					else
						thread_next_state = THREAD_RAW_DATA;
				THREAD_VARIABLE_DATA: // 4
					if(thread_count_q == header_count_out && fpga_data_read) begin
						if(compressed_fifo_empty)
							thread_next_state = THREAD_HEADER;
						else
							thread_next_state = THREAD_INTERPRETE;
					end
					else
						thread_next_state = THREAD_SAME;
				THREAD_RAW_DATA: // 5
					if(thread_count_q == header_count_out && fpga_data_read) begin
						if(compressed_fifo_empty)
							thread_next_state = THREAD_HEADER;
						else
							thread_next_state = THREAD_INTERPRETE;
					end
					else
						thread_next_state = THREAD_SAME;
				default:
					thread_next_state = THREAD_INIT;
			endcase
		end
	end

	initial begin
		thread_next_state = THREAD_INIT;
	end

	always @(negedge nreset or posedge clk)
	begin
		if(~nreset) begin
			thread_current_state = THREAD_INIT;
		end
		else begin
			if (thread_next_state != THREAD_SAME) begin
				thread_current_state = thread_next_state;
			end
		end
	end
	
	parameter FIFO_SAME	= 2'd0;
	parameter FIFO_INIT	= 2'd1;
	parameter FIFO_DATA	= 2'd2;
	reg [1:0] fifo_current_state;
	reg [1:0] fifo_next_state;
	
	always @ (nreset, control_ready, data_fifo_empty, fifo_current_state, thread_current_state,
				fpga_data_read)
	begin
		if (~nreset | ~control_ready)
			fifo_next_state = THREAD_INIT;
		else begin
			case (fifo_current_state)
				FIFO_INIT:
					if(data_fifo_empty)
						fifo_next_state = FIFO_SAME;
					else 
						fifo_next_state = FIFO_DATA;
				FIFO_DATA:
					if((thread_current_state == THREAD_RAW_DATA) && fpga_data_read) begin
						if(data_fifo_empty)
							fifo_next_state = FIFO_INIT;
						else
							fifo_next_state = FIFO_DATA;
					end
					else
						fifo_next_state = FIFO_SAME;
				default:
					fifo_next_state = THREAD_INIT;
			endcase
		end
	end
	
	always @(negedge nreset or posedge clk)
	begin
		if(~nreset) begin
			fifo_current_state = THREAD_INIT;
		end
		else begin
			if (fifo_next_state != FIFO_SAME) begin
				fifo_current_state = fifo_next_state;
			end
		end
	end
	wire raw_data_ready = fifo_current_state == FIFO_DATA;

endmodule
