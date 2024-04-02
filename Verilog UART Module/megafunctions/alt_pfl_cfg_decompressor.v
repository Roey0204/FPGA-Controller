////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG_DECOMPRESSOR
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

module alt_pfl_cfg_decompressor (
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
	input 	clk;
	input 	nreset;
	
	input	flash_data_ready;
	output	flash_data_read;
	input	[7:0] flash_data;
	input	control_ready;
	
	output	[7:0] fpga_data;
	output	fpga_data_ready;
	input	fpga_data_read;
	
	input 	enable;

	reg [3:0] current_state /* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
	reg [3:0] next_state;
	
	// State machine
	parameter DCMP_SAME 					= 4'd0;
	parameter DCMP_INIT 					= 4'd1;	// wait FLASH to be ready
	parameter DCMP_HEADER 					= 4'd2;
	parameter DCMP_SECOND_HEADER			= 4'd3;
	parameter DCMP_VARIABLE_DATA			= 4'd4;
	parameter DCMP_SEND_VARIABLE			= 4'd5;
	parameter DCMP_UPDATE_ZDV				= 4'd6;
	parameter DCMP_SEND_DATA 				= 4'd7;
	parameter DCMP_NIBBLE_SIZE				= 4'd8;
	parameter DCMP_NIBBLE_BIT				= 4'd9;
	parameter DCMP_NIBBLE					= 4'd10;

	wire [7:0] nibble_data;
	wire [7:0] fpga_data_wire = (current_state == DCMP_NIBBLE) ? nibble_data :
								(current_state == DCMP_SEND_DATA)? flash_data :
								variable;
	wire fpga_data_ready_wire = ((current_state == DCMP_SEND_DATA || current_state == DCMP_NIBBLE)
									&& flash_data_ready) || current_state == DCMP_SEND_VARIABLE;							
	wire flash_data_read_wire = ((fpga_data_read && (current_state == DCMP_SEND_DATA || 
								(current_state == DCMP_NIBBLE && need_extra_data))) ||
								current_state == DCMP_HEADER ||
								current_state == DCMP_SECOND_HEADER ||
								current_state == DCMP_VARIABLE_DATA || 
								current_state == DCMP_NIBBLE_BIT) && flash_data_ready;
	// version4
	assign fpga_data_ready = enable? fpga_data_ready_wire : flash_data_ready;
	assign fpga_data = enable? fpga_data_wire: flash_data;
	assign flash_data_read = enable? flash_data_read_wire : fpga_data_read;
							 
	reg [11:0] 	header_size;
	reg [5:0] 	multi_size;
	always @(posedge clk)
	begin
		if(current_state == DCMP_HEADER && flash_data_ready)
		begin
			if(flash_data[6:4] == 3'b011) begin
				multi_size[5:2]	= 4'b0;
				multi_size[1:0]	= flash_data[3:2];
				header_size[11:2] = 10'b0;
				header_size[1:0] = flash_data[1:0];
			end
			else begin
				header_size[11:4] = 8'b0;
				header_size[3:0] = flash_data[3:0];
				multi_size[5:0] = 6'b0;
			end
		end
		else if(current_state == DCMP_SECOND_HEADER && flash_data_ready) begin
			if(compressed_multi_variable) begin
				multi_size[5:2]	= flash_data[7:4];
				header_size[5:2] = flash_data[3:0];
			end
			else begin	
				header_size[11:4] = flash_data;
			end
		end
		else if(current_state == DCMP_VARIABLE_DATA) begin
			if(compressed_zero_variable)
				header_size[11:0] = 12'b0;
		end
		else if(current_state == DCMP_UPDATE_ZDV) begin
			header_size[11:0] = 12'b1;
		end
	end
	
	reg compressed_zero_variable;
	reg compressed_zero_two_variable;
	reg compressed_variable;
	reg compressed_multi_variable;
	reg compressed_none;
	reg compressed_nibble;
	reg[7:0] variable;
	
	always @(posedge clk)
	begin
		if(current_state == DCMP_HEADER && flash_data_ready) begin
			compressed_zero_variable = (flash_data[6:4] == 3'b001);
			compressed_zero_two_variable = (flash_data[6:4] == 3'b110);
			compressed_variable = (flash_data[6:4] == 3'b010);
			compressed_multi_variable = (flash_data[6:4] == 3'b011);
			compressed_none = (flash_data[6:4] == 3'b101);
			compressed_nibble = (flash_data[6:4] == 3'b100);
		end
		else if(current_state == DCMP_VARIABLE_DATA) begin
		
			if(compressed_zero_variable) begin
				compressed_zero_variable = 1'b0;
			end
				
			if(compressed_multi_variable) begin
				if(mv_count_q == multi_size) begin
					compressed_multi_variable = 1'b0;
				end
			end	
		end
		else if(current_state == DCMP_UPDATE_ZDV) begin
			compressed_zero_two_variable = 1'b0;
		end
	end
	
	always @(posedge clk) begin
		if(current_state == DCMP_HEADER) begin
			if (flash_data[6:5] == 2'b00 || flash_data[6:4] == 3'b110)
				variable = 8'h00;
			else if(flash_data[6:4] == 3'b111)
				variable = 8'hFF;
		end
		else if(current_state == DCMP_VARIABLE_DATA && flash_data_ready)
			variable = flash_data;
	end
	
	reg [11:0] decompress_count_q;
	wire sclr_decompress_counter = (next_state == DCMP_SEND_VARIABLE ||
									next_state == DCMP_SEND_DATA ||
									next_state == DCMP_UPDATE_ZDV ||
									(next_state == DCMP_NIBBLE_SIZE && current_state != DCMP_NIBBLE));
	lpm_counter decompress_counter (
		.clock(clk),
		.cnt_en(fpga_data_ready_wire && fpga_data_read),
		.sclr(sclr_decompress_counter),
		.q(decompress_count_q)
	);
	defparam
	decompress_counter.lpm_type = "LPM_COUNTER",
	decompress_counter.lpm_direction= "UP",
	decompress_counter.lpm_width = 12;
	
	reg [5:0] mv_count_q;	
	wire en_mv_counter = compressed_multi_variable && current_state == DCMP_SEND_VARIABLE &&
							next_state == DCMP_VARIABLE_DATA;
	lpm_counter mv_counter (
		.clock(clk),
		.cnt_en(en_mv_counter),
		.sclr(next_state == DCMP_HEADER),
		.q(mv_count_q)
	);
	defparam
	mv_counter.lpm_type = "LPM_COUNTER",
	mv_counter.lpm_direction= "UP",
	mv_counter.lpm_width = 6;
	
	reg [3:0] nibble_count_q;
	always @(posedge clk)
	begin
		if(next_state == DCMP_NIBBLE_SIZE)
			nibble_count_q[3:0] = 4'b0001;
		else if(current_state == DCMP_NIBBLE_BIT && flash_data_ready)
			nibble_count_q[3:0] = {nibble_count_q[2:0], 1'b0};
	end
	
	reg [3:0] byte_count_q;	
	wire en_byte_counter = (current_state == DCMP_NIBBLE && fpga_data_read && flash_data_ready);
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
				if (current_state == DCMP_NIBBLE_BIT && flash_data_ready) begin
					if (nibble_count_q[i]) begin
						nibble_info[i*8+7:i*8] 	 = flash_data[7:0];
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
		else if (current_state == DCMP_NIBBLE_BIT && flash_data_ready) begin
			if (nibble_count_q[0]) begin
				replace_all <= flash_data[1:0] == 2'b11;
				replace_front_nibble <= flash_data[1:0] == 2'b10;
				replace_end_nibble <= flash_data[1:0] == 2'b01;
				need_extra_data <= flash_data[1:0] == 2'b11 || (flash_data[1] ^ flash_data[0]);
				advanced_accumulate_exra_data <= flash_data[1] ^ flash_data[0];
			end
		end
		else if (next_state == DCMP_NIBBLE_BIT || next_state == DCMP_HEADER) begin
			replace_all <= 0;
			replace_front_nibble <= 0;
			replace_end_nibble <= 0;
			current_accumulate_extra_data <= 0;
			advanced_accumulate_exra_data <= 0;
			need_extra_data <= 0;
		end
	end
	
	assign nibble_data = replace_all? (current_accumulate_extra_data ? {flash_data[3:0], previous_flash_data[7:4]} : flash_data) :
							replace_front_nibble? (current_accumulate_extra_data ? {previous_flash_data[7:4], 4'b0000} : {flash_data[3:0], 4'b0000}) :
							replace_end_nibble? (current_accumulate_extra_data ? {4'b0000, previous_flash_data[7:4]} : {4'b0000, flash_data[3:0]}) :
							8'h00;
	
	reg [7:0]previous_flash_data;
	always @(posedge clk) begin
		if(flash_data_read)
			previous_flash_data = flash_data;		
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
	
	always @(nreset, current_state, fpga_data_read, flash_data_ready, flash_data, 
				decompress_count_q, byte_count_q, nibble_size, header_size, compressed_none,
				 compressed_variable, compressed_nibble, compressed_multi_variable, 
				 compressed_zero_variable, compressed_zero_two_variable,
				 control_ready, nibble_count_q, enable
			)
	begin
		if (~nreset | ~control_ready | ~enable)
			next_state = DCMP_INIT;
		else begin
			case (current_state)
				DCMP_INIT:		// 1
					if(control_ready)
						next_state = DCMP_HEADER;
					else
						next_state = DCMP_SAME;
				DCMP_HEADER:	// 2
					if (flash_data_ready) begin
						if(flash_data[7])
							next_state = DCMP_SECOND_HEADER;
						else begin
							if(flash_data[6:4] == 3'b101)			// compressed_none
								next_state = DCMP_SEND_DATA;
							else if(flash_data[6:5] == 2'b01)		// compressed variable
								next_state = DCMP_VARIABLE_DATA;
							else if(flash_data[6:4] == 3'b100)
								next_state = DCMP_NIBBLE_SIZE;
							else									// compressed zero or compressed high
								next_state = DCMP_SEND_VARIABLE;
						end
					end
					else
						next_state = DCMP_SAME;
				DCMP_SECOND_HEADER:	// 3
					if (flash_data_ready) begin
						if(compressed_none)					// compressed_none
							next_state = DCMP_SEND_DATA;
						else if(compressed_variable || compressed_multi_variable)	// compressed variable
							next_state = DCMP_VARIABLE_DATA;
						else if(compressed_nibble)
							next_state = DCMP_NIBBLE_SIZE;
						else								// compressed zero or compressed high
							next_state = DCMP_SEND_VARIABLE;
					end
					else
						next_state = DCMP_SAME;
				DCMP_VARIABLE_DATA:	// 4
					if(flash_data_ready)
						next_state = DCMP_SEND_VARIABLE;
					else
						next_state = DCMP_SAME;
				DCMP_SEND_VARIABLE:	// 5
					if((decompress_count_q == header_size) && fpga_data_read) begin
						if(compressed_zero_variable || compressed_multi_variable)
							next_state = DCMP_VARIABLE_DATA;
						else if(compressed_zero_two_variable)
							next_state = DCMP_UPDATE_ZDV;
						else
							next_state = DCMP_HEADER;
					end
					else 
						next_state = DCMP_SAME;
				DCMP_UPDATE_ZDV:	// 6
					next_state = DCMP_SEND_DATA;
				DCMP_SEND_DATA:		// 7
					if((decompress_count_q == header_size) && fpga_data_read && flash_data_ready) begin
						next_state = DCMP_HEADER;
					end
					else
						next_state = DCMP_SAME;
				DCMP_NIBBLE_SIZE:	// 8					
					next_state = DCMP_NIBBLE_BIT;
				DCMP_NIBBLE_BIT:	// 9
					if((nibble_count_q[nibble_size]) && flash_data_ready)
						next_state = DCMP_NIBBLE;
					else
						next_state = DCMP_SAME;		
				DCMP_NIBBLE:		// 10
					if(decompress_count_q == header_size && fpga_data_read && flash_data_ready)
						next_state = DCMP_HEADER;
					else if(byte_count_q == 15 && fpga_data_read && flash_data_ready)
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

endmodule
