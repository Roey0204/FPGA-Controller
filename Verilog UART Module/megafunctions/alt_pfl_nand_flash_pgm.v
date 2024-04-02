////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_NAND_FLASH_PGM
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
// This module contains the PFL (NAND Flash) Programming block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_nand_flash_pgm
(
	flash_highz_io,
	flash_io_in,
	flash_io_out,
	flash_cle,
	flash_ale,
	flash_noe,
	flash_nwe,
	flash_nce,
	enable_configuration,
	flash_access_request,
	flash_access_granted
);

	// General parameter
	parameter	FLASH_DATA_WIDTH 			= 8;
	parameter	INFO_SIZE 					= 17;
	parameter 	FLASH_MFC 					= "NUMONYX";
	parameter	IS_MICRON					= (FLASH_MFC == "MICRON") ? 1'b1: 1'b0;
	
	parameter RESERVED_BLOCK_START_ADDR = 14'h1F5; 

	// Programming parameter
	parameter	PFL_IR_BITS 				= 4;
	parameter	NPFL_NODE_ID				= 12; 
	
	localparam [PFL_IR_BITS-1:0] EN_CONFIG_INST = 'h00; 
	localparam [PFL_IR_BITS-1:0] INFO_SHIFT_INST = 'h01;
	localparam [PFL_IR_BITS-1:0] WRITE_DATA_SEL_INST = 'h02; 
	localparam [PFL_IR_BITS-1:0] READ_DATA_SEL_INST = 'h03; 
	localparam [PFL_IR_BITS-1:0] COMMAND_SEL_INST = 'h04;
	localparam [PFL_IR_BITS-1:0] ADDRESS_SEL_INST = 'h05;
	localparam [PFL_IR_BITS-1:0] HEADER_GEN_INST = 'h06;
	
	//inout	[FLASH_DATA_WIDTH-1:0] flash_io;
	output	flash_highz_io;
	input		[FLASH_DATA_WIDTH-1:0] flash_io_in;
	output	[FLASH_DATA_WIDTH-1:0] flash_io_out;
	output	flash_cle;
	output	flash_ale;
	output	flash_noe;
	output	flash_nwe;
	output	flash_nce;
	output	enable_configuration;
	output 	flash_access_request;
	input 	flash_access_granted;
	
	//Virtual IR
	wire shift_info_inst = ir_in == INFO_SHIFT_INST ? 1'b1 : 1'b0;
	wire write_data_inst = ir_in == WRITE_DATA_SEL_INST ? 1'b1 : 1'b0;
	wire read_data_inst = ir_in == READ_DATA_SEL_INST ? 1'b1 : 1'b0;
	wire cmd_sel_inst = ir_in == COMMAND_SEL_INST ? 1'b1 : 1'b0;
	wire addr_sel_inst = ir_in == ADDRESS_SEL_INST ? 1'b1 : 1'b0;
	wire gen_header_inst = ir_in == HEADER_GEN_INST ? 1'b1 : 1'b0;
	assign enable_configuration = ir_in == EN_CONFIG_INST ? 1'b1 : 1'b0;

	// SLD node 
	wire [PFL_IR_BITS-1:0] ir_in;
	wire [PFL_IR_BITS-1:0] ir_out = ir_in [PFL_IR_BITS-1:0];
	wire tdi;
	wire tck;
	wire sdr;
	wire udr;
	wire uir;
	wire tdo;
	wire cdr;
	wire rti;
	
	// Flash IO 
	wire write_mode = write_data_inst || cmd_sel_inst || addr_sel_inst;
	wire read_mode = read_data_inst || gen_header_inst;
	
	wire jtag_flash_ioreg_enable = jtag_flash_ioreg_load || sdr;	
	wire jtag_flash_ioreg_load = (read_data_inst && (udr || uir)) || (gen_header_inst && (udr || uir) && toggle);
	
	wire [FLASH_DATA_WIDTH-1:0] flash_io_in;
	wire [FLASH_DATA_WIDTH-1:0] flash_io_out;
	assign 	flash_highz_io = (read_mode || shift_info_inst) ? 1'b1 : 1'b0;
	
	wire toggle;
	wire sreg_tdo;
	wire header_output_reg_sout;
	
	//active high
	assign	flash_ale	= addr_sel_inst;
	assign	flash_cle	= cmd_sel_inst;

	//active low
	assign 	flash_nwe		= ~(write_mode && udr);
	assign 	flash_noe 		= ~jtag_flash_ioreg_load;
	assign 	flash_nce 	= ~(flash_nwe || flash_noe);
	
	// arbiter
	assign flash_access_request = shift_info_inst || write_mode || read_mode;
	
	assign 	tdo = (gen_header_inst && sdr) ? header_output_reg_sout : (shift_info_inst ? info_sout : sreg_tdo);
	
	reg [INFO_SIZE-1:0] info_sreg; 
	wire info_sout = info_sreg[0];
	always @(posedge tck) begin
		if (shift_info_inst && sdr) begin
			{info_sreg[INFO_SIZE-1:1],info_sreg[0]} <= {info_sreg[0],info_sreg[INFO_SIZE-1:1]};
		end
		else begin
			info_sreg[INFO_SIZE-1:0] <= {flash_access_granted, FLASH_DATA_WIDTH[4], IS_MICRON, RESERVED_BLOCK_START_ADDR[INFO_SIZE-4:0]};
		end
	end
	
	alt_pfl_nand_flash_pgm_header_gen header_generation (
		 .clr(~gen_header_inst),
		 .clk(tck),
		 .datain(flash_io_in),
		 .counter_en(gen_header_inst && rti),
		 .shiften(gen_header_inst && sdr),
		 .shiftout(header_output_reg_sout),
		 .toggle(toggle)
	 );
	 defparam
	 header_generation.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH;
	
	lpm_shiftreg jtag_flash_ioreg (
		.clock(tck),
		.shiftin(tdi),
		.shiftout(sreg_tdo),
		.q(flash_io_out),
		.data(flash_io_in),
		.enable(jtag_flash_ioreg_enable),
		.load(jtag_flash_ioreg_load)
	);
	defparam
	jtag_flash_ioreg.lpm_width = FLASH_DATA_WIDTH,
	jtag_flash_ioreg.lpm_direction = "RIGHT";

	sld_virtual_jtag_basic vjtag_module (
		.ir_in(ir_in),
		.ir_out(ir_out),
		.tdi(tdi),
		.tck(tck),
		.virtual_state_cdr(cdr),
		.virtual_state_sdr(sdr),
		.virtual_state_udr(udr),
		.virtual_state_uir(uir),
		.tdo(tdo),
		.jtag_state_rti(rti)
	);
	defparam
	vjtag_module.sld_ir_width			= PFL_IR_BITS,
	vjtag_module.sld_version 			= 1,
	vjtag_module.sld_type_id 			= NPFL_NODE_ID,
	vjtag_module.sld_mfg_id 			= 110,
	vjtag_module.sld_instance_index	= 0;
	
endmodule 
