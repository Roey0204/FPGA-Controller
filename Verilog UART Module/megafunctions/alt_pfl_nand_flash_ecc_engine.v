////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_NAND_FLASH_ECC_ENGINE
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
// This module contains the Hamming ECC engine for 1-bit error detection & correction for 128-byte data
//
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_nand_flash_ecc_engine (
	clk,
	nreset,
	
	read_req,
	read_done,
	write_req,
	write_data_rdy,
	
	ecc_in,
	data_in,
	data_out,
	addr_in,
	
	busy,
	valid
);

	parameter	RAM_LINE				= 128;
	parameter	RAM_ADDR_WIDTH		= 7;
	parameter	MAX_ECC_LENGTH 	= 24;
	parameter	ECC_LENGTH			= 2 * 7 + 6;
	
	parameter	STATE_SAME			   = 0;
	parameter	STATE_IDLE				= 1; 
	parameter	STATE_LOAD_DATA_ECC 	= 2; 
	parameter	STATE_ECC_COMPARE		= 3; 
	parameter	STATE_ECC_COUNT1		= 4; 
	parameter	STATE_ECC_LOCATE		= 5;
	parameter	STATE_DUMMY				= 6;
	parameter	STATE_DUMMY2 			= 7;
	parameter 	STATE_ECC_CORRECT 	= 8; 
	parameter	STATE_VALID				= 9; 
	parameter	STATE_ERROR				= 10;
	parameter	STATE_RAM_READ			= 11;
	
	reg		[3:0] current_state;
	reg		[3:0] next_state;
	
	input 	clk;
	input 	nreset;
	
	input		write_req;
	input		write_data_rdy;
	input		read_req;
	input		read_done;
	
	input		[7:0] ecc_in;
	input 	[7:0] data_in;
	input		[RAM_ADDR_WIDTH-1:0] addr_in;
	
	output	valid = (current_state == STATE_VALID);
	output	busy;
	output	[7:0] data_out = ram_data_out;

	assign	busy = (current_state == STATE_LOAD_DATA_ECC) || 
							(current_state == STATE_ECC_COMPARE) ||
							(current_state == STATE_ECC_COUNT1) || 
							(current_state == STATE_ECC_LOCATE) ||
							(current_state == STATE_DUMMY) ||
							(current_state == STATE_DUMMY2) || 
							(current_state == STATE_ECC_CORRECT);
					
	// 128x8 bits RAM for data
	wire 	[7:0] ram_data_out;
	wire	byte_we = (current_state == STATE_ECC_CORRECT);
	wire 	ram_we = (current_state == STATE_ECC_CORRECT) ? byte_we : 
						((current_state == STATE_LOAD_DATA_ECC) ? write_data_rdy : 1'b0); 
	wire	[RAM_ADDR_WIDTH-1:0] read_addr = (((current_state == STATE_ECC_LOCATE) || current_state == STATE_DUMMY || current_state == STATE_DUMMY2) || current_state == STATE_ECC_CORRECT) ? byte_addr : addr_in;
	wire 	[RAM_ADDR_WIDTH-1:0] address = (current_state == STATE_LOAD_DATA_ECC) ? addr_in : read_addr; 
	wire 	[7:0] ram_data = (next_state == STATE_ECC_CORRECT || current_state == STATE_ECC_CORRECT) ? data_correct : data_in;					
	lpm_ram_dq	lpm_ram_dq_component (
		.address (address),
		.data (ram_data),
		.outclock (clk),
		.we (ram_we),
		.inclock (clk),
		.q (ram_data_out));
	defparam
		lpm_ram_dq_component.lpm_address_control = "REGISTERED",
		lpm_ram_dq_component.lpm_indata = "REGISTERED",
		lpm_ram_dq_component.lpm_outdata = "REGISTERED",
		lpm_ram_dq_component.lpm_width = 8,
		lpm_ram_dq_component.lpm_widthad = 7;
	
	// 3x8 bits array of generated ECC & read back ECC
	reg 	[7:0] ecc_read [2:0];
	reg	[7:0] ecc_gen [2:0];
	always @ (posedge clk) 
	begin
		if ((current_state == STATE_LOAD_DATA_ECC) && write_data_rdy)
		begin
		
			// First generated ECC byte
			if(addr_in[0])
				ecc_gen[0][1] = ^data_in ^ ecc_gen[0][1];
			else
				ecc_gen[0][0] = ^data_in ^ ecc_gen[0][0];
			
			if(addr_in[1])
				ecc_gen[0][3] = ^data_in ^ ecc_gen[0][3];
			else
				ecc_gen[0][2] = ^data_in ^ ecc_gen[0][2];
				
			if (addr_in[2]) 
				ecc_gen[0][5] = ^data_in ^ ecc_gen[0][5];
			else 
				ecc_gen[0][4] = ^data_in ^ ecc_gen[0][4];
				
			if (addr_in[3]) 
				ecc_gen[0][7] = ^data_in ^ ecc_gen[0][7];
			else 
				ecc_gen[0][6] = ^data_in ^ ecc_gen[0][6];
			
			// Second generated ECC byte
			if (addr_in[4]) 
				ecc_gen[1][1] = ^data_in ^ ecc_gen[1][1];
			else 
				ecc_gen[1][0] = ^data_in ^ ecc_gen[1][0];
				
			if (addr_in[5]) 
				ecc_gen[1][3] = ^data_in ^ ecc_gen[1][3];
			else 
				ecc_gen[1][2] = ^data_in ^ ecc_gen[1][2];
				
			if (addr_in[6]) 
				ecc_gen[1][5] = ^data_in ^ ecc_gen[1][5];
			else 
				ecc_gen[1][4] = ^data_in ^ ecc_gen[1][4];
			
			// These 2bits are only used if data >= 256B
//			if (addr_in[7]) 
//				ecc_gen[1][7] = ^data_in ^ ecc_gen[1][7];
//			else 
//				ecc_gen[1][6] = ^data_in ^ ecc_gen[1][6];
	
			// Third generated ECC byte
			// These 2 bits are only used if data >= 512B
//			if (addr_in[8])
//				ecc_gen[2][0] = ^data_in ^ ecc_gen[2][0];
//			else 
//				ecc_gen[2][1] = ^data_in ^ ecc_gen[2][1];

			ecc_gen[2][2] = data_in[6] ^ data_in[4] ^ data_in[2] ^ data_in[0] ^ ecc_gen[2][2];
			ecc_gen[2][3] = data_in[7] ^ data_in[5] ^ data_in[3] ^ data_in[1] ^ ecc_gen[2][3];
			ecc_gen[2][4] = data_in[5] ^ data_in[4] ^ data_in[1] ^ data_in[0] ^ ecc_gen[2][4];
			ecc_gen[2][5] = data_in[7] ^ data_in[6] ^ data_in[3] ^ data_in[2] ^ ecc_gen[2][5];
			ecc_gen[2][6] = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0] ^ ecc_gen[2][6];
			ecc_gen[2][7] = data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4] ^ ecc_gen[2][7];	
			
			// Read back ECC byte
			if (addr_in == 7'b000_0000)
				ecc_read[0] = ecc_in;
			else if (addr_in == 7'b000_0001) 
				ecc_read[1] = ecc_in;
			else if (addr_in == 7'b000_0010) 
				ecc_read[2] = ecc_in;
		end
		else if(current_state == STATE_IDLE) begin
			ecc_gen[0] = 8'h00;
			ecc_gen[1] = 8'h00;
			ecc_gen[2] = 8'h00;
		end
	end
	
	// ECC Compare
	wire		[7:0] ecc_xor [2:0];
	assign	ecc_xor[0] = ecc_gen[0] ^ ecc_read[0]; 
	assign	ecc_xor[1] = ecc_gen[1] ^ ecc_read[1];
	assign	ecc_xor[2] = ecc_gen[2] ^ ecc_read[2];

	//Count number of bit difference
	wire 		[4:0] total_bit1;
	assign 	total_bit1 = 
						count_bit1((RAM_LINE >= 512) ? ecc_xor[2] : ecc_xor[2][7:2]) + 
						count_bit1((RAM_LINE >= 256) ? ecc_xor[1] : 
										(RAM_LINE >= 128) ? ecc_xor[1][5:0] : 
										((RAM_LINE >= 64) ? ecc_xor[1][3:0] : 
											((RAM_LINE >= 32) ? ecc_xor[1][1:0] : 0))) + 
						count_bit1((RAM_LINE >= 16) ? ecc_xor[0] : 
									((RAM_LINE >= 8) ? ecc_xor[0][5:0] :  ecc_xor[0][3:0]));

	wire 		[2:0] bit_addr;
	wire 		[RAM_ADDR_WIDTH-1:0] byte_addr;
	assign	bit_addr = (ecc_xor[2][5:3] & 3'b001) |
								(ecc_xor[2][6:4] & 3'b010) |
								(ecc_xor[2][7:5] & 3'b100);									
	assign 	byte_addr = (ecc_xor[0][7:1] & 7'b00000001) | 
										({{(RAM_ADDR_WIDTH-6){1'b0}},ecc_xor[0][7:2]} & 7'b00000010) |
										({{(RAM_ADDR_WIDTH-5){1'b0}},ecc_xor[0][7:3]} & 7'b00000100) |
										({{(RAM_ADDR_WIDTH-4){1'b0}},ecc_xor[0][7:4]} & 7'b00001000) |
										({{ecc_xor[1][3:0],{(RAM_ADDR_WIDTH-4){1'b0}}}} & 7'b00010000) |
										({{ecc_xor[1][4:0],{(RAM_ADDR_WIDTH-5){1'b0}}}} & 7'b00100000) |
										({{ecc_xor[1][5:0],{(RAM_ADDR_WIDTH-6){1'b0}}}} & 7'b01000000);
										//(ecc_xor[1] & 8'h80); // For 256-byte data
										//((ecc_xor[2] << 7) & 12'h100); // For 512-byte data
	
	reg	[7:0] data_correct;
	always @ (posedge clk)
	begin
		if (~nreset)
			data_correct = 8'hFF;
		else if (~byte_we) 
			data_correct = ram_data_out ^ (8'h01 << bit_addr);
	end
	
	// State machine flow
	always @ (nreset, current_state, write_req, busy, addr_in, read_done, read_req, byte_we, 
					write_data_rdy, total_bit1)	
	begin
		if (~nreset) 
			next_state = STATE_IDLE;
		else begin 
			case (current_state)
				STATE_IDLE:
					begin
						if (write_req && ~busy)
							next_state = STATE_LOAD_DATA_ECC;
						else
							next_state = STATE_SAME;
					end
				STATE_LOAD_DATA_ECC:
					if (&addr_in && write_data_rdy)
						next_state = STATE_ECC_COMPARE; 
					else 
						next_state = STATE_SAME;
				STATE_ECC_COMPARE:
					if ((ecc_xor[0] || ecc_xor[1] || ecc_xor[2]) == 0)
						next_state = STATE_VALID;
					else 
						next_state = STATE_ECC_COUNT1;
				STATE_ECC_COUNT1:
					if (total_bit1 == ECC_LENGTH/2)
						next_state = STATE_ECC_LOCATE;
					else if (total_bit1 == 1)
						next_state = STATE_VALID;
					else 
						next_state = STATE_ERROR;
				STATE_ECC_LOCATE:
					next_state = STATE_DUMMY;
				STATE_DUMMY:
					next_state = STATE_DUMMY2;
				STATE_DUMMY2:
					next_state = STATE_ECC_CORRECT;
				STATE_ECC_CORRECT:
						next_state = STATE_VALID;
				STATE_VALID:
					if (read_req && ~busy)
						next_state = STATE_RAM_READ;
					else
						next_state = STATE_SAME;
				STATE_ERROR: 
					next_state = STATE_SAME;
				STATE_RAM_READ: 	
					if (read_done)
							next_state = STATE_IDLE;
						else
							next_state = STATE_SAME;
				default:
					next_state = STATE_IDLE;
			endcase
		end	
	end
	
	initial begin
		current_state = STATE_IDLE;
	end

	always @(negedge nreset or posedge clk)
	begin
		if(~nreset) begin
			current_state = STATE_IDLE;
		end
		else begin
			if (next_state != STATE_SAME) begin
				current_state = next_state;
			end
		end
	end
	
	// Calculates number of bit 1 in a byte of data
	function [3:0] count_bit1;
		input [7:0] data;
		integer i = 0;
		begin
			count_bit1 = 4'b0;
			for (i = 0; i < 8; i = i+1) begin
				if (data[i] == 1) begin
					count_bit1 = count_bit1+4'b0001;
				end
			end
		end
	endfunction
	
endmodule
