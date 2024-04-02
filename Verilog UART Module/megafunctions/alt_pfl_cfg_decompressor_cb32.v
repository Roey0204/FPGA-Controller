////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG_DECOMPRESSOR_CB32
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
// This module contains the PFL configuration decompressor block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg_decompressor_cb32 (
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
	localparam REAL_COUNTER_WIDTH = (CONF_DATA_WIDTH == 16)? 11 : 10;
	localparam MINUS_REAL_COUNTER_WIDTH = (CONF_DATA_WIDTH == 16)? 1 : 2;
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
				
				// Interface with internal
				.data_out(flash_data_in),
				.data_request(~current_state_is_init),
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
	
	input		flash_data_ready;
	output	flash_data_read;
	input		[CONF_DATA_WIDTH-1:0] flash_data;
	input		control_ready;
	
	output	[CONF_DATA_WIDTH-1:0] fpga_data;
	output	fpga_data_ready;
	input		fpga_data_read;
	
	input 	enable;

	wire [7:0] nibble_data;
	wire [CONF_DATA_WIDTH-1:0] fpga_data_wire = (current_state_is_nibble) ? {nibble_data, stored_data} :
																(current_state_is_send_data)? {flash_data_in, stored_data} :
																variable;
	wire fpga_data_ready_wire = ((current_state_is_send_data || current_state_is_nibble)
											&& flash_data_ready_in) || current_state_is_send_variable;							
	wire flash_data_read_wire = ((fpga_data_read && (current_state_is_send_data || 
											(current_state_is_nibble && need_extra_data))) ||
												current_state_is_header ||
												current_state_is_second_header ||
												current_state_is_variable_data || 
												current_state_is_nibble_bit ||
												current_state_is_capture_data ||
												(current_state_is_capture_nibble && need_extra_data)) && flash_data_ready_in;
	// version4
	assign fpga_data_ready = enable? fpga_data_ready_wire : flash_data_ready;
	assign fpga_data = enable? fpga_data_wire: flash_data;
	assign flash_data_read = enable? flash_data_read_in : fpga_data_read;
	
	reg [3:0] 	header_size_reg;
	always @(posedge clk)
	begin
		if(current_state_is_header && flash_data_ready_in) begin
			header_size_reg[3:0] = flash_data_in[3:0];
		end
	end
		
	wire compressed_variable_wire 		= (flash_data_in[6:4] == 3'b010);
	wire compressed_none_wire 				= (flash_data_in[6:4] == 3'b101);
	wire compressed_nibble_wire 			= (flash_data_in[6:4] == 3'b100);
	wire compressed_fix_variable_wire  	= (flash_data_in[6:4] == 3'b000 | flash_data_in[6:4] == 3'b111);
	reg compressed_variable;
	reg compressed_none;
	reg compressed_nibble;
	reg compressed_fix_variable;
	reg [CONF_DATA_WIDTH-1:0] variable;
	always @(posedge clk)
	begin
		if(current_state_is_header && flash_data_ready_in) begin
			compressed_variable 			= compressed_variable_wire;
			compressed_none 				= compressed_none_wire;
			compressed_nibble 			= compressed_nibble_wire;
			compressed_fix_variable		= compressed_fix_variable_wire;
		end
	end
	
	always @(posedge clk) begin
		if(current_state_is_header) begin
			if (flash_data_in[6:5] == 2'b00)
				variable = {(CONF_DATA_WIDTH){1'b0}};
			else if(flash_data_in[6:4] == 3'b111)
				variable = {(CONF_DATA_WIDTH){1'b1}};
		end
		else if(current_state_is_variable_data && flash_data_ready_in)
			variable = {(NUMBER_OF_VARIABLE_DUPLICATION){flash_data_in}};
	end

	wire [11:0] header_size = {8'b0, flash_data_in[3:0]};
	wire [11:0] second_header_size = {flash_data_in, header_size_reg};
	
	wire decompress_count_done = (decompress_count_q == 12'b0);
	reg [11:0] decompress_count_q;
	wire sload_decompress_counter = (current_state_is_header || current_state_is_second_header) & flash_data_ready_in;
	wire [11:0] decompress_count_data = (current_state_is_header) ? ((compressed_none_wire | compressed_nibble_wire) ? header_size :
																																									{{(MINUS_REAL_COUNTER_WIDTH){1'b0}}, header_size[11:MINUS_REAL_COUNTER_WIDTH]}) :
																								((compressed_none | compressed_nibble) ? second_header_size :
																																						{{(MINUS_REAL_COUNTER_WIDTH){1'b0}}, second_header_size[11:MINUS_REAL_COUNTER_WIDTH]});
	wire en_decompress_counter_without_fpga_read = (current_state_is_capture_data ||
																	current_state_is_capture_nibble) && flash_data_ready_in;			
	lpm_counter decompress_counter (
		.clock(clk),
		.cnt_en((fpga_data_ready_wire && fpga_data_read) || en_decompress_counter_without_fpga_read),
		.sload(sload_decompress_counter),
		.data(decompress_count_data),
		.q(decompress_count_q)
	);
	defparam
	decompress_counter.lpm_type = "LPM_COUNTER",
	decompress_counter.lpm_direction= "DOWN",
	decompress_counter.lpm_width = 12;
	
	reg [3:0] nibble_count_q;
	always @(posedge clk)
	begin
		if(next_state_is_nibble_size)
			nibble_count_q[3:0] = 4'b0001;
		else if(current_state_is_nibble_bit && flash_data_ready_in)
			nibble_count_q[3:0] = {nibble_count_q[2:0], 1'b0};
	end
	
	reg [3:0] byte_count_q;	
	wire en_byte_counter = (((current_state_is_nibble && fpga_data_read) ||
										(current_state_is_capture_nibble))&& flash_data_ready_in);
	wire sload_byte_counter = (next_state_is_nibble_size);
	wire byte_count_done = (byte_count_q == 4'd0);
	lpm_counter byte_counter (
		.clock(clk),
		.cnt_en(en_byte_counter),
		.sload(sload_byte_counter),
		.data(4'd15),
		.q(byte_count_q)
	);
	defparam
	byte_counter.lpm_type = "LPM_COUNTER",
	byte_counter.lpm_direction= "DOWN",
	byte_counter.lpm_width = 4;
	
	reg [33:0] nibble_info;
	always @(posedge clk) begin
		nibble_info[33:32] = 2'b00;
	end
	genvar i;
	generate
		for (i=0; i<4; i=i+1) begin: NIBBLE_INFO_LOOP
			always @(posedge clk) begin
				if (current_state_is_nibble_bit && flash_data_ready_in) begin
					if (nibble_count_q[i]) begin
						nibble_info[i*8+7:i*8] = flash_data_in[7:0];
					end
				end
				else if (en_byte_counter) begin
					nibble_info[i*8+7:i*8] = nibble_info[(i+1)*8+1:i*8+2];
				end
				else if(next_state_is_nibble_bit || next_state_is_header) begin
					nibble_info[i*8+7:i*8] = 8'h00;
				end
			end
		end
	endgenerate
	
	reg replace_all;			// when both nibble is high
	reg current_accumulate_extra_data;	//
	reg advanced_accumulate_exra_data; 
	reg replace_front_nibble;
	reg replace_end_nibble;
	reg need_extra_data;			// 
	always @(posedge clk) begin
		if (en_byte_counter) begin
			replace_all <= nibble_info[3:2] == 2'b11;
			replace_front_nibble <= nibble_info[3:2] == 2'b10;
			replace_end_nibble <= nibble_info[3:2] == 2'b01;
			current_accumulate_extra_data <= current_accumulate_extra_data ^ nibble_info[1] ^ nibble_info[0];
			advanced_accumulate_exra_data <= advanced_accumulate_exra_data ^ nibble_info[3] ^ nibble_info[2];
			need_extra_data <= (nibble_info[3:2] == 2'b11) || ((nibble_info[3] ^ nibble_info[2]) && (~advanced_accumulate_exra_data));
		end
		else if (current_state_is_nibble_bit && flash_data_ready_in) begin
			if (nibble_count_q[0]) begin
				replace_all <= flash_data_in[1:0] == 2'b11;
				replace_front_nibble <= flash_data_in[1:0] == 2'b10;
				replace_end_nibble <= flash_data_in[1:0] == 2'b01;
				need_extra_data <= flash_data_in[1:0] == 2'b11 || (flash_data_in[1] ^ flash_data_in[0]);
				advanced_accumulate_exra_data <= flash_data_in[1] ^ flash_data_in[0];
			end
		end
		else if (next_state_is_nibble_bit || next_state_is_header) begin
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
			
	reg[1:0] nibble_size;
	always @(posedge clk) begin
		if(current_state_is_nibble_size) begin
			if(decompress_count_q[11:4] == 8'b0)
				nibble_size = decompress_count_q[3:2];
			else
				nibble_size = 2'd3;
		end
	end
	
	// CB32
	wire out_of_capture_data;
	reg [CONF_DATA_WIDTH-8-1:0] stored_data;
	generate
	if (CONF_DATA_WIDTH == 16) begin
		assign out_of_capture_data = (decompress_count_q[0] == 1'b1);
		always @ (posedge clk) begin
			if (current_state_is_capture_data && flash_data_ready_in) begin
				if (decompress_count_q[0] == 1'b1) begin
					stored_data = flash_data_in;
				end
			end
			else if (current_state_is_capture_nibble && flash_data_ready_in) begin
				if (decompress_count_q[0] == 1'b1) begin
					stored_data = nibble_data;
				end
			end
		end
	end
	else begin
		assign out_of_capture_data = (decompress_count_q[1:0] == 2'b01);
		always @ (posedge clk) begin
			if (current_state_is_capture_data && flash_data_ready_in) begin
				if (decompress_count_q[1:0] == 2'b11) begin
					stored_data[7:0] = flash_data_in;
				end
				else if (decompress_count_q[1:0] == 2'b10) begin
					stored_data[15:8] = flash_data_in;
				end
				else if (decompress_count_q[1:0] == 2'b01) begin
					stored_data[23:16] = flash_data_in;
				end
			end
			else if (current_state_is_capture_nibble && flash_data_ready_in) begin
				if (decompress_count_q[1:0] == 2'b11) begin
					stored_data[7:0] = nibble_data;
				end
				else if (decompress_count_q[1:0] == 2'b10) begin
					stored_data[15:8] = nibble_data;
				end
				else if (decompress_count_q[1:0] == 2'b01) begin
					stored_data[23:16] = nibble_data;
				end
			end
		end
	end
	endgenerate
	
	// STATE MACHINE
	reg current_state_is_init;
	reg current_state_is_header;
	reg current_state_is_second_header;
	reg current_state_is_variable_data;
	reg current_state_is_send_variable;
	reg current_state_is_capture_data;
	reg current_state_is_send_data;
	reg current_state_is_nibble_size;
	reg current_state_is_nibble_bit;
	reg current_state_is_capture_nibble;
	reg current_state_is_nibble;
	wire reset_state_machine = ~current_state_machine_active | ~control_ready | ~enable;
	
	// INIT
	wire next_state_is_init = reset_state_machine;
	always @ (posedge clk) begin
		current_state_is_init = next_state_is_init;
	end
	
	// HEADER
	wire next_state_is_header = (current_state_is_init &  control_ready) |
											(current_state_is_send_variable & decompress_count_done & fpga_data_read) |
											(current_state_is_send_data & decompress_count_done & fpga_data_read & flash_data_ready_in) |
											(current_state_is_nibble & decompress_count_done & fpga_data_read & flash_data_ready_in);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_second_header | next_state_is_capture_data | 
				next_state_is_variable_data | next_state_is_nibble_size | next_state_is_send_variable)
			current_state_is_header = 1'b0;
		else begin
			if (~current_state_is_header) begin
				current_state_is_header = next_state_is_header;
			end
		end
	end
	
	// SECOND_HEADER
	wire next_state_is_second_header = current_state_is_header & flash_data_ready_in & flash_data_in[7];
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_capture_data | next_state_is_variable_data | 
				next_state_is_nibble_size | next_state_is_send_variable)
			current_state_is_second_header = 1'b0;
		else begin
			if (~current_state_is_second_header) begin
				current_state_is_second_header = next_state_is_second_header;
			end
		end
	end
	
	// VARIABLE_DATA
	wire next_state_is_variable_data = (flash_data_ready_in & 
													((current_state_is_header & ~flash_data_in[7] & compressed_variable_wire) |
														(current_state_is_second_header & compressed_variable)));
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_send_variable)
			current_state_is_variable_data = 1'b0;
		else begin
			if (~current_state_is_variable_data) begin
				current_state_is_variable_data = next_state_is_variable_data;
			end
		end
	end
	
	// SEND_VARIABLE
	wire next_state_is_send_variable = (flash_data_ready_in & 
													((current_state_is_header & ~flash_data_in[7] & compressed_fix_variable_wire) |
														(current_state_is_second_header & compressed_fix_variable) |
														current_state_is_variable_data));
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_header)
			current_state_is_send_variable = 1'b0;
		else begin
			if (~current_state_is_send_variable) begin
				current_state_is_send_variable = next_state_is_send_variable;
			end
		end
	end
	
	// CAPTURE_DATA
	wire next_state_is_capture_data = (flash_data_ready_in & 
													((current_state_is_header & ~flash_data_in[7] & compressed_none_wire) |
														(current_state_is_second_header & compressed_none) |
														current_state_is_send_data & ~decompress_count_done & fpga_data_read));
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_send_data)
			current_state_is_capture_data = 1'b0;
		else begin
			if (~current_state_is_capture_data) begin
				current_state_is_capture_data = next_state_is_capture_data;
			end
		end
	end
	
	// SEND_DATA
	wire next_state_is_send_data = (current_state_is_capture_data & out_of_capture_data & flash_data_ready_in);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_header | next_state_is_capture_data)
			current_state_is_send_data = 1'b0;
		else begin
			if (~current_state_is_send_data) begin
				current_state_is_send_data = next_state_is_send_data;
			end
		end
	end
	
	// NIBBLE_SIZE
	wire next_state_is_nibble_size = (flash_data_ready_in & 
													((current_state_is_header & ~flash_data_in[7] & compressed_nibble_wire) |
														(current_state_is_second_header & compressed_nibble) |
														current_state_is_nibble & ~decompress_count_done & byte_count_done & fpga_data_read));
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_nibble_size = 1'b0;
		else begin
			current_state_is_nibble_size = next_state_is_nibble_size;
		end
	end
	
	// NIBBLE_BIT
	wire next_state_is_nibble_bit = current_state_is_nibble_size;
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_capture_nibble)
			current_state_is_nibble_bit = 1'b0;
		else begin
			if (~current_state_is_nibble_bit) begin
				current_state_is_nibble_bit = next_state_is_nibble_bit;
			end
		end
	end
	
	// CAPTURE_NIBBLE
	wire next_state_is_capture_nibble = (flash_data_ready_in &
													((current_state_is_nibble_bit & nibble_count_q[nibble_size]) |
													(current_state_is_nibble & ~decompress_count_done & ~byte_count_done & fpga_data_read)));
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_nibble)
			current_state_is_capture_nibble = 1'b0;
		else begin
			if (~current_state_is_capture_nibble) begin
				current_state_is_capture_nibble = next_state_is_capture_nibble;
			end
		end
	end
	
	// NIBBLE
	wire next_state_is_nibble = (current_state_is_capture_nibble & out_of_capture_data & flash_data_ready_in);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_header | next_state_is_nibble_size | next_state_is_capture_nibble)
			current_state_is_nibble = 1'b0;
		else begin
			if (~current_state_is_nibble) begin
				current_state_is_nibble = next_state_is_nibble;
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

endmodule
