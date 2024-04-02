////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_NAND_FLASH
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
// This module contains the PFL (NAND Flash) block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_nand_flash
(
	pfl_nreset,
	pfl_clk,
	
	// FPGA IOs
	fpga_data,
	dclk,
	fpga_nconfig,
	fpga_conf_done,
	fpga_nstatus,
	fpga_pgm,
	
	pfl_nreconfigure,	
	pfl_reset_watchdog,
	pfl_watchdog_error,
	
	// NAND Flash IOs
	flash_io,
	flash_rdy,
	flash_nce,
	flash_nwe,
	flash_noe,
	flash_cle,
	flash_ale,
	
	// arbiter
	pfl_flash_access_request,
	pfl_flash_access_granted
);

// General parameter
parameter	FLASH_DATA_WIDTH				= 8;
parameter	FLASH_ADDR_WIDTH				= 26;
parameter 	FEATURES_CFG					= 1;
parameter 	FEATURES_PGM					= 1;
parameter 	TRISTATE_CHECKBOX				= 1;
parameter 	N_FLASH							= 1;
parameter	FLASH_MFC						= "NUMONYX";
parameter	US_UNIT_COUNTER				= 16;

parameter 	RESERVED_BLOCK_START_ADDR = NRB_ADDR/131072;
parameter 	NAND_SIZE						= 67108864;
parameter 	NRB_ADDR						= 65667072;
parameter 	FLASH_ECC_CHECKBOX				= 0;
parameter 	OPTION_START_ADDR				= 'h3E00000;
	
// Configuration parameter
parameter 	CONF_DATA_WIDTH				= 8;
parameter 	SAFE_MODE_HALT 				= 0;
parameter 	SAFE_MODE_RETRY 			= 1;
parameter 	SAFE_MODE_REVERT 			= 0;
parameter 	SAFE_MODE_REVERT_ADDR		= 'hABCDEF;
parameter 	DCLK_DIVISOR 				= 1;
parameter	DCLK_CREATE_DELAY			= 0;
parameter 	CLK_DIVISOR					= 3;
parameter	PAGE_CLK_DIVISOR			= 200;
parameter 	CONF_WAIT_TIMER_WIDTH 		= 16;
parameter 	DECOMPRESSOR_MODE			= "NONE";
parameter 	PFL_RSU_WATCHDOG_ENABLED	= 0;
parameter 	RSU_WATCHDOG_COUNTER		= 100000000;

// Programming parameter
parameter 	PFL_IR_BITS					= 4;

// Port Declaration

input 	pfl_nreset;
input 	pfl_clk;
// FPGA IOs
output 	[CONF_DATA_WIDTH-1:0] fpga_data;
output 	dclk;
output 	fpga_nconfig;
input 	fpga_conf_done;
input 	fpga_nstatus;
input	[2:0] fpga_pgm;
input 	pfl_nreconfigure;

// NAND Flash IOs
inout	[FLASH_DATA_WIDTH-1:0] flash_io;
input	flash_rdy;
output	flash_nce;
output	flash_nwe;
output	flash_noe;
output	flash_cle;
output	flash_ale;

// arbiter
output	pfl_flash_access_request;
input	pfl_flash_access_granted;

// RSU
input pfl_reset_watchdog;
output pfl_watchdog_error;

	wire 	enable_configuration;
	wire	prog_highz_io;
	wire	[FLASH_DATA_WIDTH-1:0] prog_io_in;
	wire	[FLASH_DATA_WIDTH-1:0] prog_io_out;
	wire	prog_flash_cle;
	wire	prog_flash_ale;
	wire	prog_flash_noe;
	wire	prog_flash_nwe;
	wire 	prog_flash_nce;
	wire	prog_request_flash;
	wire	cfg_highz_io;
	wire	[FLASH_DATA_WIDTH-1:0] cfg_io_in;
	wire	[FLASH_DATA_WIDTH-1:0] cfg_io_out;
	wire	cfg_flash_cle;
	wire	cfg_flash_ale;
	wire	cfg_flash_noe;
	wire	cfg_flash_nwe;
	wire 	cfg_flash_nce;
	wire	cfg_request_flash;
	
	assign flash_io	= enable_configuration ? (cfg_highz_io ? {(FLASH_DATA_WIDTH){1'bZ}} : cfg_io_out) : (prog_highz_io ? {(FLASH_DATA_WIDTH){1'bZ}} : prog_io_out);
	assign flash_cle = enable_configuration ? cfg_flash_cle : prog_flash_cle;
	assign flash_ale = enable_configuration ? cfg_flash_ale : prog_flash_ale;
	assign flash_noe = enable_configuration ? cfg_flash_noe : prog_flash_noe;
	assign flash_nwe = enable_configuration ? cfg_flash_nwe : prog_flash_nwe;
	assign flash_nce = enable_configuration ? cfg_flash_nce : prog_flash_nce;
	assign pfl_flash_access_request	= enable_configuration ? cfg_request_flash : prog_request_flash;

	generate 
	if (FEATURES_CFG == 1) begin
		assign cfg_io_in = flash_io;
		
		alt_pfl_nand_flash_cfg alt_pfl_nand_flash_cfg (
			.clk(pfl_clk),
			.nreset(pfl_nreset),
			.flash_highz_io(cfg_highz_io), 
			.flash_io_in(cfg_io_in), 		
			.flash_io_out(cfg_io_out),		
			.flash_cle(cfg_flash_cle),
			.flash_ale(cfg_flash_ale),
			.flash_noe(cfg_flash_noe),
			.flash_nwe(cfg_flash_nwe),
			.flash_nce(cfg_flash_nce),
			
			.flash_access_request(cfg_request_flash),
			.flash_access_granted(pfl_flash_access_granted),
			
			.fpga_data(fpga_data),
			.fpga_dclk(dclk),
			.fpga_nconfig(fpga_nconfig),
			.fpga_conf_done(fpga_conf_done),
			.fpga_nstatus(fpga_nstatus),
			
			.pfl_nreconfigure(pfl_nreconfigure), 
			.enable_configuration(enable_configuration),
			.page_sel(fpga_pgm),
			
			.pfl_reset_watchdog(pfl_reset_watchdog),
			.pfl_watchdog_error(pfl_watchdog_error)
		);
		defparam 
		// RSU 
			alt_pfl_nand_flash_cfg.PFL_RSU_WATCHDOG_ENABLED = PFL_RSU_WATCHDOG_ENABLED,
			alt_pfl_nand_flash_cfg.RSU_WATCHDOG_COUNTER		= RSU_WATCHDOG_COUNTER,
		//Flash
			alt_pfl_nand_flash_cfg.FLASH_ADDR_WIDTH = FLASH_ADDR_WIDTH,
			alt_pfl_nand_flash_cfg.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH,
			alt_pfl_nand_flash_cfg.NRB_ADDR = NRB_ADDR,
			alt_pfl_nand_flash_cfg.CLK_DIVISOR = CLK_DIVISOR,
			alt_pfl_nand_flash_cfg.PAGE_CLK_DIVISOR = PAGE_CLK_DIVISOR,
			alt_pfl_nand_flash_cfg.FLASH_ECC_CHECKBOX = FLASH_ECC_CHECKBOX,
			alt_pfl_nand_flash_cfg.US_UNIT_COUNTER = US_UNIT_COUNTER,

		// Control block parameter
			alt_pfl_nand_flash_cfg.SAFE_MODE_HALT 			= SAFE_MODE_HALT,
			alt_pfl_nand_flash_cfg.SAFE_MODE_RETRY 			= SAFE_MODE_RETRY,
			alt_pfl_nand_flash_cfg.SAFE_MODE_REVERT 		= SAFE_MODE_REVERT,
			alt_pfl_nand_flash_cfg.SAFE_MODE_REVERT_ADDR	= SAFE_MODE_REVERT_ADDR,
			alt_pfl_nand_flash_cfg.FLASH_OPTIONS_ADDR 		= OPTION_START_ADDR,
		// FPGA block parameter
			alt_pfl_nand_flash_cfg.CONF_DATA_WIDTH 			= CONF_DATA_WIDTH,
			alt_pfl_nand_flash_cfg.DCLK_DIVISOR 			= DCLK_DIVISOR,
			alt_pfl_nand_flash_cfg.CONF_WAIT_TIMER_WIDTH 	= CONF_WAIT_TIMER_WIDTH,
			alt_pfl_nand_flash_cfg.DCLK_CREATE_DELAY 		= DCLK_CREATE_DELAY,
		// Decompressor block parameter
			alt_pfl_nand_flash_cfg.DECOMPRESSOR_MODE		= DECOMPRESSOR_MODE,	
			alt_pfl_nand_flash_cfg.FLASH_MFC				= FLASH_MFC;
		// Read mode: Normal_mode (default)
	end
	else begin
		assign cfg_highz_io 		   = 1'b1;
		assign cfg_io_out 			= {(FLASH_DATA_WIDTH){1'b0}};
		assign cfg_request_flash 	= 1'b0;
		assign cfg_flash_cle 		= 1'b0;
		assign cfg_flash_ale 		= 1'b0;
		assign cfg_flash_noe 		= 1'b0;
		assign cfg_flash_nwe 		= 1'b0;
		assign cfg_flash_nce	 	= 1'b1;
	end
	endgenerate

	generate 
	if (FEATURES_PGM == 1) begin
		assign prog_io_in = flash_io;
		
		alt_pfl_nand_flash_pgm alt_pfl_nand_flash_pgm (
			.flash_highz_io(prog_highz_io), 
			.flash_io_in(prog_io_in), 		
			.flash_io_out(prog_io_out),	
			.flash_cle(prog_flash_cle),
			.flash_ale(prog_flash_ale),
			.flash_noe(prog_flash_noe),
			.flash_nwe(prog_flash_nwe),
			.flash_nce(prog_flash_nce),
			.enable_configuration(enable_configuration),
			.flash_access_request(prog_request_flash),
			.flash_access_granted(pfl_flash_access_granted)
		);
		defparam
			alt_pfl_nand_flash_pgm.PFL_IR_BITS = PFL_IR_BITS,
			alt_pfl_nand_flash_pgm.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH,
			alt_pfl_nand_flash_pgm.RESERVED_BLOCK_START_ADDR = RESERVED_BLOCK_START_ADDR,
			alt_pfl_nand_flash_pgm.FLASH_MFC				= FLASH_MFC;
	end
	else begin
		assign enable_configuration = 1'b1;
		assign prog_highz_io = 1'b0;
		assign prog_io_out 			= {(FLASH_DATA_WIDTH){1'b0}};
		assign prog_request_flash 	= 1'b0;
		assign prog_flash_cle 		= 1'b0;
		assign prog_flash_ale 		= 1'b0;
		assign prog_flash_noe 		= 1'b0;
		assign prog_flash_nwe 		= 1'b0;
		assign prog_flash_nce	 	= 1'b1;
	end
	endgenerate

endmodule
