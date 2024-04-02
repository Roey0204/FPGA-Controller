////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_NAND_FLASH_CFG
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
// This module contains the PFL (NAND Flash) Configuration block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_nand_flash_cfg
(
	clk,
	nreset,
	
	flash_io_in,
	flash_io_out,
	flash_highz_io,
	flash_cle,
	flash_ale,
	flash_noe,
	flash_nwe,
	flash_nce,
	flash_rdy,
	
	flash_access_request,
	flash_access_granted,
	
	fpga_data,
	fpga_dclk,
	fpga_nconfig,
	fpga_conf_done,
	fpga_nstatus,
	
	pfl_nreconfigure,
	enable_configuration,
	enable_nconfig,
	
	page_sel,
	
	pfl_reset_watchdog,
	pfl_watchdog_error
);
	// Flash
	parameter CLK_DIVISOR						= 3;
	parameter PAGE_CLK_DIVISOR					= 200;
	parameter NRB_ADDR							= 65667072;
	parameter FLASH_ECC_CHECKBOX				= 0;
	parameter FLASH_MFC 							= "NUMONYX";
	parameter US_UNIT_COUNTER					= 16;
	
	// RSU 
	parameter PFL_RSU_WATCHDOG_ENABLED		= 0;	
	parameter RSU_WATCHDOG_COUNTER			= 100000000;

	// General parameter
	parameter	FLASH_ADDR_WIDTH				= 26;
	parameter	FLASH_DATA_WIDTH				= 8;
	
	// Control block parameter
	parameter 	SAFE_MODE_HALT					= 0;
	parameter 	SAFE_MODE_RETRY				= 1;
	parameter 	SAFE_MODE_REVERT				= 0;
	parameter 	SAFE_MODE_REVERT_ADDR		= 'hABCDEF;
	parameter 	FLASH_OPTIONS_ADDR			= 'h3E00000;
	
	// FPGA block parameter
	parameter 	CONF_DATA_WIDTH				= 8;
	parameter 	DCLK_DIVISOR					= 1;
	parameter 	CONF_WAIT_TIMER_WIDTH		= 16;
	parameter	DCLK_CREATE_DELAY				= 0;
	
	// Decompressor block parameter
	parameter 	DECOMPRESSOR_MODE				= "NONE";
	localparam 	FPGA_DATA_WIDTH 				= (CONF_DATA_WIDTH == 1)? 8 : CONF_DATA_WIDTH;
	
	input		clk;
	input		nreset;
	
	input 	[FLASH_DATA_WIDTH-1:0] flash_io_in;
	output	[FLASH_DATA_WIDTH-1:0] flash_io_out;
	output	flash_highz_io;
	output 	flash_cle;
	output 	flash_ale;
	output 	flash_noe;
	output 	flash_nwe;
	output 	flash_nce;
	input		flash_rdy;
	
	output 	flash_access_request;
	input		flash_access_granted;
	
	output	[CONF_DATA_WIDTH-1:0] fpga_data;
	output	fpga_dclk;
	output	fpga_nconfig;
	input		fpga_conf_done;
	input		fpga_nstatus;
	
	input		pfl_nreconfigure;
	input		enable_configuration;
	input 	enable_nconfig;
	input 	[2:0] page_sel;
	
	// RSU
	input		pfl_reset_watchdog;
	output	pfl_watchdog_error;
	
	// Control <--> Flash
	wire		[FLASH_ADDR_WIDTH-1:0] flash_addr_control;
	wire		[FLASH_ADDR_WIDTH-1:0] flash_stop_addr;
	wire		flash_addr_sload;
	wire 		flash_done;
	wire		[7:0] fpga_flags;
	
	// Interface between FLASH and CONTROL
	wire request_flash_data;
	wire [FLASH_DATA_WIDTH-1:0] flash_to_control_data;
	wire flash_to_control_data_ready;
	wire read_flash_data;
	
	// Interface between CONTROL and DECOMPRESSOR
	wire [FPGA_DATA_WIDTH-1:0] control_to_decompressor_data;
	wire control_to_decompressor_data_ready;
	wire read_control_data;
	wire control_ready;
	wire enable_decompressor;
	
	// Interface between DECOMPRESSOR and FPGA
	wire [FPGA_DATA_WIDTH-1:0] decompressor_to_fpga_data;
	wire decompressor_to_fpga_data_ready;
	wire read_decompressor_data;
	
	wire nreset_sync;
	alt_pfl_reset alt_pfl_reset
	(
		.clk(clk),
		.nreset_in(nreset),
		.nreset_out(nreset_sync)
	);
	
	generate
	if (FLASH_ECC_CHECKBOX == 1 && FLASH_MFC != "MICRON") begin
		alt_pfl_nand_flash_cfg_flash_ecc alt_pfl_nand_flash_cfg_flash_ecc (
			.clk(clk),
			.nreset(nreset_sync),
			
			// Flash pins
			.flash_highz_io(flash_highz_io), 
			.flash_io_in(flash_io_in), 		
			.flash_io_out(flash_io_out),	
			.flash_cle(flash_cle),
			.flash_ale(flash_ale),
			.flash_noe(flash_noe),
			.flash_nwe(flash_nwe),
			.flash_nce(flash_nce),
			.flash_rdy(flash_rdy),
			
			// Controller address
			.addr_in(flash_addr_control),
			.stop_addr_in(flash_stop_addr),
			.addr_sload(flash_addr_sload),
			.done(flash_done),
			
			// Controller data
			.data_request(request_flash_data),
			.data_ready(flash_to_control_data_ready),
			.data(flash_to_control_data),
			.addr_cnt_en(read_flash_data),
			
			// Access Control
			.flash_access_request(flash_access_request),
			.flash_access_granted(flash_access_granted)
		);
		defparam alt_pfl_nand_flash_cfg_flash_ecc.FLASH_ADDR_WIDTH = FLASH_ADDR_WIDTH;
		defparam alt_pfl_nand_flash_cfg_flash_ecc.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH;
		defparam alt_pfl_nand_flash_cfg_flash_ecc.NRB_ADDR = NRB_ADDR;
		defparam alt_pfl_nand_flash_cfg_flash_ecc.CLK_DIVISOR = CLK_DIVISOR;
		defparam alt_pfl_nand_flash_cfg_flash_ecc.PAGE_CLK_DIVISOR = PAGE_CLK_DIVISOR;						
	end
	else begin
		alt_pfl_nand_flash_cfg_flash alt_pfl_nand_flash_cfg_flash (
			.clk(clk),
			.nreset(nreset_sync),
			
			// Flash pins
			.flash_highz_io(flash_highz_io), 
			.flash_io_in(flash_io_in), 		
			.flash_io_out(flash_io_out),	
			.flash_cle(flash_cle),
			.flash_ale(flash_ale),
			.flash_noe(flash_noe),
			.flash_nwe(flash_nwe),
			.flash_nce(flash_nce),
			.flash_rdy(flash_rdy),
			
			// Controller address
			.addr_in(flash_addr_control),
			.stop_addr_in(flash_stop_addr),
			.addr_sload(flash_addr_sload),
			.done(flash_done),
			
			// Controller data
			.data_request(request_flash_data),
			.data_ready(flash_to_control_data_ready),
			.data(flash_to_control_data),
			.addr_cnt_en(read_flash_data),
			
			// Access Control
			.flash_access_request(flash_access_request),
			.flash_access_granted(flash_access_granted)
		);
		defparam alt_pfl_nand_flash_cfg_flash.FLASH_ADDR_WIDTH = FLASH_ADDR_WIDTH;
		defparam alt_pfl_nand_flash_cfg_flash.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH;
		defparam alt_pfl_nand_flash_cfg_flash.NRB_ADDR = NRB_ADDR;
		defparam alt_pfl_nand_flash_cfg_flash.CLK_DIVISOR = CLK_DIVISOR;
		defparam alt_pfl_nand_flash_cfg_flash.PAGE_CLK_DIVISOR = PAGE_CLK_DIVISOR;
		defparam alt_pfl_nand_flash_cfg_flash.FLASH_MFC = FLASH_MFC;
		defparam alt_pfl_nand_flash_cfg_flash.US_UNIT_COUNTER = US_UNIT_COUNTER;
		defparam alt_pfl_nand_flash_cfg_flash.FLASH_ECC_CHECKBOX = FLASH_ECC_CHECKBOX;
	end
	endgenerate

	alt_pfl_cfg3_control alt_pfl_cfg3_control (
		.clk(clk),
		.nreset(nreset_sync),

		// Flash reader block address pins
		.flash_stop_addr(flash_stop_addr),
		.flash_addr_out(flash_addr_control),
		.flash_addr_sload(flash_addr_sload),
		.flash_done(flash_done),

		// Flash reader block data pins
		.flash_data_request(request_flash_data),
		.flash_data_ready(flash_to_control_data_ready),
		.flash_data(flash_to_control_data),
		.flash_addr_cnt_en(read_flash_data),
		
		// FPGA configuration block data pins
		.fpga_data(control_to_decompressor_data),
		.fpga_data_ready(control_to_decompressor_data_ready),
		.fpga_data_read(read_control_data),
		.fpga_flags(fpga_flags),
		
		// State control pins from FPGA configuration block
		.enable_configuration(enable_configuration),
		.enable_nconfig(enable_nconfig),
		
		// External control pins
		.fpga_nstatus(fpga_nstatus),
		.fpga_nconfig(fpga_nconfig),
		.fpga_condone(fpga_conf_done),
		.pfl_nreconfigure(pfl_nreconfigure),
		.page_sel(page_sel),
		.ready(control_ready),
		.enable_decompressor(enable_decompressor),
		
		// RSU watchdog timed out
		.watchdog_timed_out(pfl_watchdog_error)
	);
		defparam alt_pfl_cfg3_control.CONF_DATA_WIDTH = FPGA_DATA_WIDTH;
		defparam alt_pfl_cfg3_control.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH;
		defparam alt_pfl_cfg3_control.FLASH_ADDR_WIDTH = FLASH_ADDR_WIDTH;
		defparam alt_pfl_cfg3_control.SAFE_MODE_HALT = SAFE_MODE_HALT;
		defparam alt_pfl_cfg3_control.SAFE_MODE_RETRY = SAFE_MODE_RETRY;
		defparam alt_pfl_cfg3_control.SAFE_MODE_REVERT = SAFE_MODE_REVERT;
		defparam alt_pfl_cfg3_control.SAFE_MODE_REVERT_ADDR = SAFE_MODE_REVERT_ADDR;
		defparam alt_pfl_cfg3_control.FLASH_OPTIONS_ADDR = FLASH_OPTIONS_ADDR;
		defparam alt_pfl_cfg3_control.CONF_WAIT_TIMER_WIDTH = CONF_WAIT_TIMER_WIDTH;
	
	generate
	if(DECOMPRESSOR_MODE == "SPEED" && (CONF_DATA_WIDTH == 1 || CONF_DATA_WIDTH == 8)) begin	
		alt_pfl_cfg_speed_decompressor alt_pfl_cfg_speed_decompressor (
			.clk(clk),
			.nreset(nreset_sync),
			// with control block
			.flash_data_ready(control_to_decompressor_data_ready),
			.flash_data_read(read_control_data),
			.flash_data(control_to_decompressor_data),
			.control_ready(control_ready),
			
			// with fpga block
			.fpga_data(decompressor_to_fpga_data),
			.fpga_data_ready(decompressor_to_fpga_data_ready),
			.fpga_data_read(read_decompressor_data),
			.enable(enable_decompressor)
		);
	end
	else if(DECOMPRESSOR_MODE == "SPEED" && (CONF_DATA_WIDTH == 16 || CONF_DATA_WIDTH == 32)) begin
		alt_pfl_cfg_speed2_decompressor_cb32 alt_pfl_cfg_speed2_decompressor_cb32 (
			.clk(clk),
			.nreset(nreset_sync),
			// with control block
			.flash_data_ready(control_to_decompressor_data_ready),
			.flash_data_read(read_control_data),
			.flash_data(control_to_decompressor_data),
			.control_ready(control_ready),
			
			// with fpga block
			.fpga_data(decompressor_to_fpga_data),
			.fpga_data_ready(decompressor_to_fpga_data_ready),
			.fpga_data_read(read_decompressor_data),
			.enable(enable_decompressor)
		);
			defparam alt_pfl_cfg_speed2_decompressor_cb32.CONF_DATA_WIDTH = CONF_DATA_WIDTH;
	end
	else if(DECOMPRESSOR_MODE == "AREA" && (CONF_DATA_WIDTH == 1 || CONF_DATA_WIDTH == 8)) begin	
		alt_pfl_cfg_decompressor alt_pfl_cfg_decompressor (
			.clk(clk),
			.nreset(nreset_sync),
			// with control block
			.flash_data_ready(control_to_decompressor_data_ready),
			.flash_data_read(read_control_data),
			.flash_data(control_to_decompressor_data),
			.control_ready(control_ready),
			
			// with fpga block
			.fpga_data(decompressor_to_fpga_data),
			.fpga_data_ready(decompressor_to_fpga_data_ready),
			.fpga_data_read(read_decompressor_data),
			.enable(enable_decompressor)
		);
	end
	else if(DECOMPRESSOR_MODE == "AREA" && (CONF_DATA_WIDTH == 16 || CONF_DATA_WIDTH == 32)) begin	
		alt_pfl_cfg_decompressor_cb32 alt_pfl_cfg_decompressor_cb32 (
			.clk(clk),
			.nreset(nreset_sync),
			// with control block
			.flash_data_ready(control_to_decompressor_data_ready),
			.flash_data_read(read_control_data),
			.flash_data(control_to_decompressor_data),
			.control_ready(control_ready),
			
			// with fpga block
			.fpga_data(decompressor_to_fpga_data),
			.fpga_data_ready(decompressor_to_fpga_data_ready),
			.fpga_data_read(read_decompressor_data),
			.enable(enable_decompressor)
		);
			defparam alt_pfl_cfg_decompressor_cb32.CONF_DATA_WIDTH = CONF_DATA_WIDTH;
	end
	else begin
		assign decompressor_to_fpga_data = control_to_decompressor_data;
		assign decompressor_to_fpga_data_ready = control_to_decompressor_data_ready;
		assign read_control_data = read_decompressor_data;
	end
	endgenerate
	
	alt_pfl_cfg_fpga alt_pfl_cfg_fpga (
		.clk(clk),
		.nreset(nreset_sync),

		// Data pins from controller
		.flash_data(decompressor_to_fpga_data),
		.flash_data_ready(decompressor_to_fpga_data_ready),
		.flash_data_read(read_decompressor_data),
		.flash_flags(fpga_flags),
		
		// Control pins to FPGA
		.fpga_data(fpga_data),
		.fpga_dclk(fpga_dclk)
	);
	defparam alt_pfl_cfg_fpga.DCLK_DIVISOR = DCLK_DIVISOR;
	defparam alt_pfl_cfg_fpga.CONF_DATA_WIDTH = CONF_DATA_WIDTH;
	defparam alt_pfl_cfg_fpga.DCLK_CREATE_DELAY = DCLK_CREATE_DELAY;

	generate
		if (PFL_RSU_WATCHDOG_ENABLED == 1)begin
			alt_pfl_cfg_rsu_wd alt_pfl_cfg_rsu_wd(
				.clk(clk),
				.nreset(nreset_sync),
				.fpga_conf_done(fpga_conf_done),
				.fpga_nstatus(fpga_nstatus),
				.pfl_nreconfigure(pfl_nreconfigure),
				.watchdog_reset(pfl_reset_watchdog),
				.watchdog_timed_out(pfl_watchdog_error)
			);
				defparam alt_pfl_cfg_rsu_wd.RSU_WATCHDOG_COUNTER = RSU_WATCHDOG_COUNTER;
		end
	endgenerate
	
endmodule
