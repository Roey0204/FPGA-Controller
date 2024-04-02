////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_QUAD_IO_FLASH_PGM
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
// This module contains the PFL (Quad IO Flash) Flash Programming block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_quad_io_flash_pgm
(
	// Hub IOs
	ir_in,
	ir_out,
	tdi,
	tck,
	sdr,
	udr,
	tdo,
	
	// Flash IOs
	flash_sck,
	flash_ncs,
	flash_io0,
	flash_io1,
	
	// This is for powerful
	powerful,
	p_prog_sck,
	p_prog_ncs,
	p_prog_io0,
	p_prog_io1,
	p_prog_io2,
	p_prog_io3,
	
	enable_configuration,
	
	// arbiter
	flash_access_request,
	flash_access_granted
);

	// parameter
	parameter PFL_IR_BITS 							= 8;
	parameter N_FLASH 								= 4;
	parameter EXTRA_ADDR_BYTE						= 0;
	parameter FLASH_MFC								= "ALTERA";

	// local parameter
	localparam QPFL_VERSION 						= 1;
	localparam OPCODE_ONE_BIT_SIZE 				= 8;
	localparam OPCODE_TWO_BIT_SIZE 				= 16;
	localparam OPCODE_THREE_BIT_SIZE 			= 24;
	localparam OPCODE_FOUR_BIT_SIZE 				= 32;
	localparam OPCODE_FIVE_BIT_SIZE 				= 40;
	localparam OPCODE_SIX_BIT_SIZE				= 48;
	localparam DATA_REG_WIDTH						= 268; 
	localparam DATA_MAX_SHIFT						= 264;
	localparam REAL_DATA_SIZE						= (EXTRA_ADDR_BYTE == 1)? 
																((N_FLASH == 8) ? 16672 : ((N_FLASH == 4)? 8356 : (N_FLASH == 2)? 4196 : 2116)):
																((N_FLASH == 8) ? 16664 : ((N_FLASH == 4)? 8348 : (N_FLASH == 2)? 4188 : 2108));
	localparam OPCODE_ADDRESS_SIZE				= (EXTRA_ADDR_BYTE == 1)? 40 : 32;
	localparam CRC_STORAGE_SIZE 					= 256;
	localparam SHIFT_CRC_START_INDEX 			= REAL_DATA_SIZE + 5;
	localparam SHIFT_CRC_STOP_INDEX 				= SHIFT_CRC_START_INDEX + 16;
	localparam CRC_DATA_WIDTH 						= 16;
	localparam IO1_OPERATION_WIDTH				= 2;
	localparam DECODER_WIDTH						= log2(N_FLASH-1);
	localparam ACTIVE_DEVICE_COUNTER_WIDTH		= DECODER_WIDTH + 2;
	localparam COUNTER_WIDTH 						= log2(REAL_DATA_SIZE-1) + 1;
	localparam JTAG_COMPLIANT_COUNT_WIDTH 		= log2(DATA_REG_WIDTH-1) + 1;

	// Port Declaration 
	// Hub IOs
	input	[PFL_IR_BITS-1:0]ir_in;
	output	[PFL_IR_BITS-1:0]ir_out;
	input	tdi;
	input 	tck;
	input	sdr;
	input 	udr;
	output	tdo;

	// Flash IOs
	output	[N_FLASH-1:0] flash_sck;
	output	[N_FLASH-1:0] flash_ncs;
	output	[N_FLASH-1:0] flash_io0;
	input	[N_FLASH-1:0] flash_io1;
	output	enable_configuration;

	// arbiter
	output flash_access_request;
	input flash_access_granted;
	
	// powerful
	output powerful = powerful_write;
	output p_prog_sck = powerful_write & udr_reg & ~tck & ~p_prog_ncs_reg;  
	output p_prog_ncs = p_prog_ncs_reg;
	output p_prog_io0 = p_prog_io0_reg;
	output p_prog_io1 = p_prog_io1_reg;
	output p_prog_io2 = p_prog_io2_reg;
	output p_prog_io3 = p_prog_io3_reg;
	
	reg udr_reg;
	always @ (posedge tck) begin
		udr_reg = udr;
	end
	
	reg p_prog_ncs_reg;
	reg p_prog_io0_reg;
	reg p_prog_io1_reg;
	reg p_prog_io2_reg;
	reg p_prog_io3_reg;
	
	always @ (posedge tck) begin
		if(powerful) begin
			if (udr) begin
				p_prog_ncs_reg = powerful_reg_value[4];
				p_prog_io0_reg = powerful_reg_value[3];
				p_prog_io1_reg = powerful_reg_value[2];
				p_prog_io2_reg = powerful_reg_value[1];
				p_prog_io3_reg = powerful_reg_value[0];
			end
			else begin
				p_prog_ncs_reg = p_prog_ncs_reg;
				p_prog_io0_reg = p_prog_io0_reg;
				p_prog_io1_reg = p_prog_io1_reg;
				p_prog_io2_reg = p_prog_io2_reg;
				p_prog_io3_reg = p_prog_io3_reg;
			end
		end
		else begin
			p_prog_ncs_reg = 1'b1;
			p_prog_io0_reg = 1'b0;
			p_prog_io1_reg = 1'b0;
			p_prog_io2_reg = 1'b0;
			p_prog_io3_reg = 1'b0;			
		end
	end
	
	
	// All about Virtual IR
	assign enable_configuration 		= (ir_in[PFL_IR_BITS-1:0] == 'h00) ? 1'b1: 1'b0;
	assign sw_reset 						= (ir_in[PFL_IR_BITS-1:0] == 'h10) ? 1'b1: 1'b0;
	assign set_io1_operation			= (ir_in[PFL_IR_BITS-1:0] == 'h01) ? 1'b1: 1'b0;
	assign set_opcode_active_flash	= (ir_in[PFL_IR_BITS-1:0] == 'h11) ? 1'b1: 1'b0;
	assign load_opcode_byte 			= (ir_in[PFL_IR_BITS-1:0] == 'h02) ? 1'b1: 1'b0;
	assign push_crc_byte 				= (ir_in[PFL_IR_BITS-1:0] == 'h12) ? 1'b1: 1'b0;
	assign push_opcode_one 				= (ir_in[PFL_IR_BITS-1:0] == 'h03) ? 1'b1: 1'b0;
	assign push_opcode_two 				= (ir_in[PFL_IR_BITS-1:0] == 'h13) ? 1'b1: 1'b0;
	assign push_opcode_three 			= (ir_in[PFL_IR_BITS-1:0] == 'h04) ? 1'b1: 1'b0;
	assign push_opcode_four 			= (ir_in[PFL_IR_BITS-1:0] == 'h14) ? 1'b1: 1'b0;
	assign push_opcode_five 			= (ir_in[PFL_IR_BITS-1:0] == 'h05) ? 1'b1: 1'b0;
	assign push_opcode_six				= (ir_in[PFL_IR_BITS-1:0] == 'h15) ? 1'b1: 1'b0;
	assign load_data_byte				= (ir_in[PFL_IR_BITS-1:0] == 'h08) ? 1'b1: 1'b0;
	assign push_data_byte 				= (ir_in[PFL_IR_BITS-1:0] == 'h18) ? 1'b1: 1'b0;
	assign clear_verify_status 		= (ir_in[PFL_IR_BITS-1:0] == 'h09) ? 1'b1: 1'b0;
	assign push_verify_status 			= (ir_in[PFL_IR_BITS-1:0] == 'h19) ? 1'b1: 1'b0;
	assign powerful_write				= (ir_in[PFL_IR_BITS-1:0] == 'hFA) ? 1'b1: 1'b0;

	// Evo of Virtual IR
	assign push_opcode_byte				= push_opcode_one | push_opcode_two | push_opcode_three | push_opcode_four | push_opcode_five | push_opcode_six;
	assign enable_opcode_byte 			= load_opcode_byte	| push_opcode_byte;
	assign enable_data_byte				= load_data_byte	| push_data_byte;
	assign load_instruction 			= load_opcode_byte	| load_data_byte;
	assign push_instruction 			= push_opcode_byte  | push_data_byte;
	assign valid_instruction 			= load_instruction 	| push_instruction;
	assign flash_access_request		= valid_instruction | push_crc_byte | set_io1_operation | set_opcode_active_flash | sw_reset | 
													clear_verify_status | push_verify_status | powerful_write;

	// Wire
	wire sw_reset;
	wire set_io1_operation;
	wire set_opcode_active_flash;
	wire load_opcode_byte;
	wire push_crc_byte;
	wire push_opcode_one;
	wire push_opcode_two;
	wire push_opcode_three;
	wire push_opcode_four;
	wire push_opcode_five;
	wire push_opcode_six;
	wire load_data_byte;
	wire push_data_byte;
	wire push_opcode_byte;
	wire enable_opcode_byte;
	wire enable_data_byte;
	wire load_instruction;
	wire push_instruction;
	wire valid_instruction;
	wire clear_verify_status;
	wire push_verify_status;
	wire powerful_write;
	// Connection with reg
	wire opcode_byte_reg_sout;
	wire data_byte_reg_sout;
	wire bypass_reg_sout;
	wire io1_operation_reg_sout;
	//wire single_crc_storage_reg_sout;
	//wire crc_shifter_reg_sout;
	wire opcode_active_flash_reg_sout;
	wire powerful_reg_sout;
	wire [IO1_OPERATION_WIDTH-1:0]io1_operation_reg_value;
	wire [N_FLASH-1:0] opcode_active_flash_reg_value;
	wire [COUNTER_WIDTH-1:0]count_q;
	wire [ACTIVE_DEVICE_COUNTER_WIDTH-1:0]active_device_count_q;
	wire [JTAG_COMPLIANT_COUNT_WIDTH-1:0]jtag_compliant_count_q;
	wire [4:0]powerful_reg_value;
	wire trimode = (FLASH_MFC == "NUMONYX")? 1'b1 : 1'b0;
	

	// Enabled Flash's clock depends on count value
	wire enable_flash_clock_counter;
	wire[N_FLASH-1:0] enable_flash_clock;
	reg[N_FLASH-1:0] enable_flash_clock_reg;
	wire enable_all_flash_clock;

	// Logic
	assign enable_flash_clock_counter = ~enable_all_flash_clock & enable_jtag_compliant_clock_reg & enable_data_stream_clock_reg;

	// This is for OPCODE and Addressing
	assign enable_all_flash_clock = push_data_byte & count_q < OPCODE_ADDRESS_SIZE;
	reg enable_all_flash_clock_reg;
	always @(negedge tck) begin
		enable_all_flash_clock_reg = enable_all_flash_clock;
	end
	
	// This is for JTAG Compliant
	wire enable_jtag_compliant_clock = push_data_byte & jtag_compliant_count_q < DATA_MAX_SHIFT;
	reg enable_jtag_compliant_clock_reg;
	always @(negedge tck) begin
		enable_jtag_compliant_clock_reg = enable_jtag_compliant_clock;
	end 
	
	// This is for Data Stream
	wire enable_data_stream_clock = push_data_byte & count_q < REAL_DATA_SIZE;
	reg enable_data_stream_clock_reg;
	always @(negedge tck) begin
		enable_data_stream_clock_reg = enable_data_stream_clock;
	end 

	// this is hardcoded
	reg push_opcode_tdo;
	reg push_data_tdo;
	reg verify_status;
	
	generate
		if (N_FLASH > 1) begin
			lpm_decode lpm_decode
			(
				.enable(enable_flash_clock_counter),
				.data(active_device_count_q[2+DECODER_WIDTH-1:2]),
				.eq(enable_flash_clock)
			);
				defparam lpm_decode.LPM_WIDTH = DECODER_WIDTH;
				defparam lpm_decode.LPM_DECODES = N_FLASH;
		end
	endgenerate
	
	generate
		if(N_FLASH == 8) begin
			assign ir_out = {flash_access_granted, trimode, 6'b010001};
			wire and_operated_io1 = flash_io1[7] & flash_io1[6] & flash_io1[5] & flash_io1[4] & flash_io1[3] & flash_io1[2] & flash_io1[1] & flash_io1[0];
			wire or_operated_io1 = flash_io1[7] | flash_io1[6] | flash_io1[5] | flash_io1[4] | flash_io1[3] | flash_io1[2] | flash_io1[1] | flash_io1[0];
			always @(flash_io1, io1_operation_reg_value, and_operated_io1, or_operated_io1,
					opcode_active_flash_reg_value)
			begin
				if(io1_operation_reg_value == 2'b01)
					push_opcode_tdo = and_operated_io1;
				else if(io1_operation_reg_value == 2'b10)
					push_opcode_tdo = or_operated_io1;
				else begin
					if(opcode_active_flash_reg_value[0])
						push_opcode_tdo = flash_io1[0];
					else if(opcode_active_flash_reg_value[1])
						push_opcode_tdo = flash_io1[1];
					else if(opcode_active_flash_reg_value[2])
						push_opcode_tdo = flash_io1[2];
					else if(opcode_active_flash_reg_value[3])
						push_opcode_tdo = flash_io1[3];
					else if(opcode_active_flash_reg_value[4])
						push_opcode_tdo = flash_io1[4];
					else if(opcode_active_flash_reg_value[5])
						push_opcode_tdo = flash_io1[5];
					else if(opcode_active_flash_reg_value[6])
						push_opcode_tdo = flash_io1[6];
					else if(opcode_active_flash_reg_value[7])
						push_opcode_tdo = flash_io1[7];
					else
						push_opcode_tdo = flash_io1[0];
				end
			end
			always @(enable_flash_clock_reg, flash_io1)
			begin
				if(enable_flash_clock_reg[0])
					push_data_tdo = flash_io1[0];
				else if(enable_flash_clock_reg[1])
					push_data_tdo = flash_io1[1];
				else if(enable_flash_clock_reg[2])
					push_data_tdo = flash_io1[2];
				else if(enable_flash_clock_reg[3])
					push_data_tdo = flash_io1[3];
				else if(enable_flash_clock_reg[4])
					push_data_tdo = flash_io1[4];
				else if(enable_flash_clock_reg[5])
					push_data_tdo = flash_io1[5];
				else if(enable_flash_clock_reg[6])
					push_data_tdo = flash_io1[6];
				else if(enable_flash_clock_reg[7])
					push_data_tdo = flash_io1[7];
				else
					push_data_tdo = flash_io1[0];
			end
		end
		else if(N_FLASH == 4) begin
			assign ir_out = {flash_access_granted, trimode, 6'b001001};
			wire and_operated_io1 = flash_io1[3] & flash_io1[2] & flash_io1[1] & flash_io1[0];
			wire or_operated_io1 = flash_io1[3] | flash_io1[2] | flash_io1[1] | flash_io1[0];
			always @(flash_io1, io1_operation_reg_value, and_operated_io1, or_operated_io1,
					opcode_active_flash_reg_value)
			begin
				if(io1_operation_reg_value == 2'b01)
					push_opcode_tdo = and_operated_io1;
				else if(io1_operation_reg_value == 2'b10)
					push_opcode_tdo = or_operated_io1;
				else begin
					if(opcode_active_flash_reg_value[0])
						push_opcode_tdo = flash_io1[0];
					else if(opcode_active_flash_reg_value[1])
						push_opcode_tdo = flash_io1[1];
					else if(opcode_active_flash_reg_value[2])
						push_opcode_tdo = flash_io1[2];
					else if(opcode_active_flash_reg_value[3])
						push_opcode_tdo = flash_io1[3];
					else
						push_opcode_tdo = flash_io1[0];
				end
			end
			
			always @(enable_flash_clock_reg, flash_io1)
			begin
				if(enable_flash_clock_reg[0])
					push_data_tdo = flash_io1[0];
				else if(enable_flash_clock_reg[1])
					push_data_tdo = flash_io1[1];
				else if(enable_flash_clock_reg[2])
					push_data_tdo = flash_io1[2];
				else if(enable_flash_clock_reg[3])
					push_data_tdo = flash_io1[3];
				else
					push_data_tdo = flash_io1[0];
			end
			
		end
		else if (N_FLASH == 2) begin
			assign ir_out = {flash_access_granted, trimode, 6'b000101};
			wire and_operated_io1 = flash_io1[1] & flash_io1[0];
			wire or_operated_io1 = flash_io1[1] | flash_io1[0];
			always @(flash_io1, io1_operation_reg_value, and_operated_io1, or_operated_io1, opcode_active_flash_reg_value)
			begin
				if(io1_operation_reg_value == 2'b01)
					push_opcode_tdo = and_operated_io1;
				else if(io1_operation_reg_value == 2'b10)
					push_opcode_tdo = or_operated_io1;
				else begin
					if(opcode_active_flash_reg_value[0])
						push_opcode_tdo = flash_io1[0];
					else if(opcode_active_flash_reg_value[1])
						push_opcode_tdo = flash_io1[1];
					else
						push_opcode_tdo = flash_io1[0];

				end
			end
			
			always @(enable_flash_clock_reg, flash_io1)
			begin
				if(enable_flash_clock_reg[0])
					push_data_tdo = flash_io1[0];
				else if(enable_flash_clock_reg[1])
					push_data_tdo = flash_io1[1];
				else
					push_data_tdo = flash_io1[0];
			end
			
		end
		else begin
			assign ir_out = {flash_access_granted, trimode, 6'b000011};
			assign enable_flash_clock[0] = enable_flash_clock_counter;
			always @(flash_io1)
			begin
				push_opcode_tdo = flash_io1[0];
			end
			
			always @(enable_flash_clock_reg, flash_io1)
			begin
				push_data_tdo = flash_io1[0];
			end
			
		end
	endgenerate
								
	//	Connection with JTAG
	reg tdo;
	always @ (push_crc_byte, push_opcode_byte, push_opcode_tdo, push_data_byte, enable_flash_clock, 
				load_opcode_byte, load_data_byte, push_data_byte, push_verify_status, verify_status, //crc_shifter_reg_sout, 
				io1_operation_reg_sout, push_data_tdo, opcode_byte_reg_sout, data_byte_reg_sout, 
				bypass_reg_sout, set_io1_operation, set_opcode_active_flash, opcode_active_flash_reg_sout,
				powerful_write, powerful_reg_sout)
	begin
		if(push_verify_status)
			tdo = verify_status;
		else if(push_data_byte)
			tdo = push_data_tdo;
		else if(push_opcode_byte)
			tdo = push_opcode_tdo;
		else if (set_io1_operation)
			tdo = io1_operation_reg_sout;
		else if (set_opcode_active_flash)
			tdo = opcode_active_flash_reg_sout;
		else if(load_opcode_byte)
			tdo = opcode_byte_reg_sout;
		else if(load_data_byte)
			tdo = data_byte_reg_sout;
		//else if(push_crc_byte)
		//	tdo = crc_shifter_reg_sout;
		else if(powerful_write)
			tdo = powerful_reg_sout;
		else
			tdo = bypass_reg_sout;
	end

	// Connection with outside world
	// Chip Enable Signal
	reg flash_en;
	always @ (push_opcode_one, push_opcode_two, push_opcode_three, push_opcode_four, push_opcode_five,
				 push_opcode_six, push_data_byte, sdr, count_q)
	begin
		if(push_opcode_one & sdr & count_q < OPCODE_ONE_BIT_SIZE)
			flash_en <= 1'b1;
		else if(push_opcode_two & sdr & count_q < OPCODE_TWO_BIT_SIZE)
			flash_en <= 1'b1;
		else if(push_opcode_three & sdr & count_q < OPCODE_THREE_BIT_SIZE)
			flash_en <= 1'b1;
		else if(push_opcode_four & sdr & count_q < OPCODE_FOUR_BIT_SIZE)
			flash_en <= 1'b1;
		else if(push_opcode_five & sdr & count_q < OPCODE_FIVE_BIT_SIZE)
			flash_en <= 1'b1;
		else if(push_opcode_six & sdr & count_q < OPCODE_SIX_BIT_SIZE)
			flash_en <= 1'b1;
		else if(push_data_byte & ((sdr & count_q < 10) | (count_q > 9 & count_q < REAL_DATA_SIZE)))
			flash_en <= 1'b1;
		else
			flash_en <= 1'b0;
	end

	reg flash_en_reg;
	always @ (negedge tck) begin
		flash_en_reg = flash_en;
	end
	reg flash_ncs_reg;
	always @ (negedge tck) begin
		flash_ncs_reg = !flash_en;
	end
	reg flash_ncs_reg_reg;
	always @ (negedge tck) begin
		flash_ncs_reg_reg = flash_ncs_reg;
	end
	assign flash_ncs = {(N_FLASH){flash_ncs_reg_reg & flash_ncs_reg}};
	
	// CLOCK to Flash
	genvar i;
	generate
		for(i = 0; i < N_FLASH; i=i+1) begin: ENABLE_FLASH_CLOCK_LOOP
			always @(negedge tck)  begin
				enable_flash_clock_reg[i] = enable_flash_clock[i] & sdr;
			end
		end
	endgenerate
	
	reg [N_FLASH-1:0] flash_sck;
	generate
		for(i = 0; i < N_FLASH; i=i+1) begin: SCK_LOOP
			always @ (push_opcode_byte, enable_all_flash_clock_reg, push_data_byte, 
				enable_flash_clock_reg[i], enable_flash_clock_counter, tck, flash_en_reg)
			begin
				if(push_opcode_byte)
					flash_sck[i] <= tck & flash_en_reg;
				else if(enable_all_flash_clock_reg)
					flash_sck[i] <= tck & flash_en_reg;
				else if(push_data_byte & enable_flash_clock_reg[i] & enable_flash_clock_counter)
					flash_sck[i] <= tck & flash_en_reg;
				else
					flash_sck[i] <= 1'b0;
			end
		end
	endgenerate

	// IO Input to Flash
	reg flash_io0_prog;
	reg flash_io0_prog_neg;
	always @(push_data_byte, push_opcode_byte, data_byte_reg_sout, opcode_byte_reg_sout)
	begin
		if(push_data_byte)
			flash_io0_prog <= data_byte_reg_sout;
		else if(push_opcode_byte)
			flash_io0_prog <= opcode_byte_reg_sout;
		else
			flash_io0_prog <= 1'b0;
	end


	always @(negedge tck) begin
		flash_io0_prog_neg = flash_io0_prog;	
	end
	
	assign flash_io0 = {(N_FLASH){flash_io0_prog_neg}};

	/*
	// About CRC
	// Connection with JTAG
	wire [CRC_DATA_WIDTH-1:0]crc_wire;
	reg [CRC_DATA_WIDTH-1:0]crc_reg;
	
	assign crc_wire[0] = crc_reg[15] ^ push_data_tdo;
	assign crc_wire[1] = crc_reg[0];
	assign crc_wire[2] = crc_reg[1];
	assign crc_wire[3] = crc_reg[2];
	assign crc_wire[4] = crc_reg[3];
	assign crc_wire[5] = crc_reg[4] ^ crc_wire[0];
	assign crc_wire[6] = crc_reg[5];
	assign crc_wire[7] = crc_reg[6];
	assign crc_wire[8] = crc_reg[7];
	assign crc_wire[9] = crc_reg[8];
	assign crc_wire[10] = crc_reg[9];
	assign crc_wire[11] = crc_reg[10];
	assign crc_wire[12] = crc_reg[11] ^ crc_wire[0];
	assign crc_wire[13] = crc_reg[12];
	assign crc_wire[14] = crc_reg[13];
	assign crc_wire[15] = crc_reg[14];

	wire enable_crc_storage = push_data_byte & sdr & (count_q == (SHIFT_CRC_START_INDEX - 1));
	wire enable_crc_shift = push_data_byte & sdr & (count_q >= SHIFT_CRC_START_INDEX) & (count_q < SHIFT_CRC_STOP_INDEX);

	// CRC calculation
	always @(posedge tck)
	begin
		if(sw_reset || load_instruction)
			crc_reg <= 16'h0;
		else if(push_data_byte & sdr & enable_flash_clock_counter)
			crc_reg <= crc_wire;
		else
			crc_reg <= crc_reg;
	end

	lpm_shiftreg crc_shifter_reg (
		.clock(tck),
		.enable((push_crc_byte & sdr) | enable_crc_shift),
		.shiftin(single_crc_storage_reg_sout),
		.shiftout(crc_shifter_reg_sout)
	);
	defparam
	crc_shifter_reg.lpm_type = "LPM_SHIFTREG",
	crc_shifter_reg.lpm_width = CRC_STORAGE_SIZE,
	crc_shifter_reg.lpm_direction = "RIGHT";

	lpm_shiftreg single_crc_storage_reg (
		.clock(tck),
		.enable(enable_crc_storage || enable_crc_shift),
		.load(enable_crc_storage),
		.data(crc_reg),
		.shiftout(single_crc_storage_reg_sout)
	);
	defparam
	single_crc_storage_reg.lmp_type = "LPM_SHIFTREG",
	single_crc_storage_reg.lpm_width = CRC_DATA_WIDTH,
	single_crc_storage_reg.lpm_direction = "RIGHT";
	*/
	always @(posedge tck)
	begin
		if(clear_verify_status)
			verify_status = 1'b1;
		else if(push_data_byte & sdr & enable_flash_clock_counter)
			verify_status = verify_status && (data_byte_reg_sout == push_data_tdo);
		else
			verify_status = verify_status;
	end


	lpm_shiftreg bypass_reg (
		.clock(tck),
		.enable(~valid_instruction),
		.shiftin(tdi),
		.shiftout(bypass_reg_sout)
	);
	defparam
	bypass_reg.lmp_type = "LPM_SHIFTREG",
	bypass_reg.lpm_width = 1,
	bypass_reg.lpm_direction = "RIGHT";

	lpm_shiftreg io1_operation_reg (
		.clock(tck),
		.enable(set_io1_operation & sdr),
		.shiftin(tdi),
		.q(io1_operation_reg_value),
		.shiftout(io1_operation_reg_sout)
	);
	defparam
	io1_operation_reg.lmp_type = "LPM_SHIFTREG",
	io1_operation_reg.lpm_width = IO1_OPERATION_WIDTH,
	io1_operation_reg.lpm_direction = "RIGHT";
	
	lpm_shiftreg opcode_active_flash_reg (
		.clock(tck),
		.enable(set_opcode_active_flash & sdr),
		.shiftin(tdi),
		.q(opcode_active_flash_reg_value),
		.shiftout(opcode_active_flash_reg_sout)
	);
	defparam
	opcode_active_flash_reg.lmp_type = "LPM_SHIFTREG",
	opcode_active_flash_reg.lpm_width = N_FLASH,
	opcode_active_flash_reg.lpm_direction = "RIGHT";
	
	lpm_shiftreg opcode_byte_reg (
		.clock(tck),
		.enable(enable_opcode_byte & sdr),
		.shiftin(tdi),
		.shiftout(opcode_byte_reg_sout)
	);
	defparam
	opcode_byte_reg.lmp_type = "LPM_SHIFTREG",
	opcode_byte_reg.lpm_width = OPCODE_SIX_BIT_SIZE + 1,
	opcode_byte_reg.lpm_direction = "RIGHT";

	lpm_shiftreg data_byte_reg (
		.clock(tck),
		.enable(enable_data_byte & sdr),
		.shiftin(tdi),
		.shiftout(data_byte_reg_sout)
	);
	defparam
	data_byte_reg.lmp_type = "LPM_SHIFTREG",
	data_byte_reg.lpm_width = DATA_REG_WIDTH,
	data_byte_reg.lpm_direction = "RIGHT";
	
	lpm_shiftreg powerful_reg (
		.clock(tck),
		.enable(powerful_write & sdr),
		.shiftin(tdi),
		.q(powerful_reg_value),
		.shiftout(powerful_reg_sout)
	);
	defparam
	powerful_reg.lmp_type = "LPM_SHIFTREG",
	powerful_reg.lpm_width = 5,
	powerful_reg.lpm_direction = "RIGHT";

	// LPM counter
	lpm_counter bit_counter (
		.clock(tck),
		.clk_en(valid_instruction & sdr & ~stop_bit_counter),
		.cnt_en(~count_q[COUNTER_WIDTH-1]),
		.sclr(sw_reset | load_instruction),
		.q(count_q)
	);
	defparam
	bit_counter.lpm_type = "LPM_COUNTER",
	bit_counter.lpm_direction= "UP",
	bit_counter.lpm_width = COUNTER_WIDTH;

	// LPM counter
	lpm_counter active_device_counter (
		.clock(tck),
		.cnt_en(sdr & enable_flash_clock_counter),
		.sclr(sw_reset | load_instruction),
		.q(active_device_count_q)
	);
	defparam
	active_device_counter.lpm_type = "LPM_COUNTER",
	active_device_counter.lpm_direction= "UP",
	active_device_counter.lpm_width = ACTIVE_DEVICE_COUNTER_WIDTH;

	// LPM counter
	lpm_counter jtag_compliant_counter (
		.clock(tck),
		.clk_en(push_data_byte & sdr),
		.cnt_en(~jtag_compliant_count_q[JTAG_COMPLIANT_COUNT_WIDTH-1]),
		.aclr(udr | load_instruction),
		.q(jtag_compliant_count_q)
	);
	defparam
	jtag_compliant_counter.lpm_type = "LPM_COUNTER",
	jtag_compliant_counter.lpm_direction= "UP",
	jtag_compliant_counter.lpm_width = JTAG_COMPLIANT_COUNT_WIDTH;
	wire stop_bit_counter = push_data_byte & (jtag_compliant_count_q >= (DATA_REG_WIDTH));
	
	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
					value = value >> 1;
		end
	endfunction

	endmodule
