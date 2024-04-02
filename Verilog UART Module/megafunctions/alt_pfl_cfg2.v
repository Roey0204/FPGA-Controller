////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG2
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
// This module contains the PFL configuration block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg2 (
	clk,
	nreset,
	flash_addr,
	flash_data_in,
	flash_data_out,
	flash_select,
	flash_read,
	flash_write,
	flash_clk,
	flash_nadv,
	flash_rdy,
	flash_nreset,
	flash_data_highz,
	
	flash_access_request,
	flash_access_granted,

	fpga_data,
	fpga_dclk,
	fpga_nconfig,
	fpga_conf_done,
	fpga_nstatus,

	pfl_nreconfigure,
	pfl_reset_watchdog,
	pfl_watchdog_error,

	enable_configuration,
	enable_nconfig,
	
	page_sel
)/* synthesis altera_attribute = "SUPPRESS_DA_RULE_INTERNAL=s102"*/;
	parameter FLASH_DATA_WIDTH				= 16;
	parameter FLASH_ADDR_WIDTH 				= 25;
	parameter SAFE_MODE_HALT 				= 0;
	parameter SAFE_MODE_RETRY 				= 0;
	parameter SAFE_MODE_REVERT 				= 1;
	parameter SAFE_MODE_REVERT_ADDR			= 'hABCDEF;
	parameter FLASH_OPTIONS_ADDR 			= 'h1FE000;
	parameter DCLK_DIVISOR 					= 1;
	parameter CONF_DATA_WIDTH 				= 8;
	parameter ACCESS_CLK_DIVISOR 			= 10;
	parameter PAGE_ACCESS_CLK_DIVISOR 		= 3;
	parameter NORMAL_MODE 					= 1;
	parameter BURST_MODE 					= 0;
	parameter PAGE_MODE 					= 0;
	parameter BURST_MODE_SPANSION 			= 0;
	parameter BURST_MODE_INTEL 				= 0;
	parameter BURST_MODE_NUMONYX 			= 0;
	parameter CONF_WAIT_TIMER_WIDTH 		= 14;
	parameter DECOMPRESSOR_MODE				= "NONE";
	parameter PFL_RSU_WATCHDOG_ENABLED		= 1;	
	parameter RSU_WATCHDOG_COUNTER			= 100000000;
	
	parameter BURST_FLASH_DATA_WIDTH_INDEX 	= 8;
	parameter BURST_FLASH_ADDR_WIDTH_INDEX 	= (FLASH_DATA_WIDTH == 32) ? FLASH_ADDR_WIDTH + 2 :
												(FLASH_DATA_WIDTH == 16) ? FLASH_ADDR_WIDTH + 1 :
												FLASH_ADDR_WIDTH;
	parameter FLASH_DATA_WIDTH_INDEX 		= (FLASH_DATA_WIDTH == 32) ? 16 : FLASH_DATA_WIDTH;
	parameter FLASH_ADDR_WIDTH_INDEX 		= (FLASH_DATA_WIDTH == 32) ? FLASH_ADDR_WIDTH +1 : FLASH_ADDR_WIDTH;

	input	clk;
	input	nreset;

	output	[FLASH_ADDR_WIDTH-1:0] flash_addr;
	input	[FLASH_DATA_WIDTH-1:0] flash_data_in;
	output	[FLASH_DATA_WIDTH-1:0] flash_data_out;
	output	flash_select;
	output	flash_read;
	output	flash_write;
	output	flash_clk;
	output	flash_nadv;
	input	flash_rdy;
	output	flash_nreset;
	output	flash_data_highz;
	
	output	flash_access_request;
	input	flash_access_granted;
	
	output	[CONF_DATA_WIDTH-1:0] fpga_data;
	output	fpga_dclk;
	output	fpga_nconfig;
	input	fpga_conf_done;
	input	fpga_nstatus;

	input		pfl_nreconfigure;
	input		pfl_reset_watchdog;
	output	pfl_watchdog_error;
	
	input	enable_configuration;
	input	enable_nconfig;

	input	[2:0] page_sel;

	generate
	if(BURST_MODE == 1 && FLASH_DATA_WIDTH == 32)
	begin
		wire	[BURST_FLASH_ADDR_WIDTH_INDEX-1:0] flash_addr_control;
		wire	[BURST_FLASH_ADDR_WIDTH_INDEX-1:0] flash_stop_addr;
		wire	[BURST_FLASH_DATA_WIDTH_INDEX-1:0] flash_data;
	end
	else
	begin
		wire	[FLASH_ADDR_WIDTH_INDEX-1:0] flash_addr_control;
		wire	[FLASH_ADDR_WIDTH_INDEX-1:0] flash_stop_addr;
		wire	[FLASH_DATA_WIDTH_INDEX-1:0] flash_data;
	end
	endgenerate

	wire	flash_addr_sload;
	wire	flash_addr_cnt_en;
	wire	flash_done;
	wire	flash_data_request;
	wire	flash_data_ready;
	wire	[7:0] fpga_data_fpga;
	wire	fpga_data_request;
	wire	fpga_data_ready;
	wire	fpga_data_read;
	wire	[7:0] fpga_flags;
	wire	fpga_done;
	wire	halt_control;
	wire	error_fpga;
	wire	restart_control;
	wire	control_error_wait;
	wire 	watchdog_reset;
	
	// decompressor
	wire 	control_ready;
	wire 	[7:0] decompressor_data;
	wire 	decompressor_data_ready;
	wire	decompressor_data_read;
	wire	enable_decompressor;
	
	/* synthesis preserve */ reg 	nreset_sync_fpga; 
	/* synthesis preserve */ reg 	nreset_sync_control; 

	// RSU
	wire watchdog_error;
	assign pfl_watchdog_error = watchdog_error;
		
	always @(negedge nreset or posedge clk) begin
		if(~nreset)
			nreset_sync_fpga = 0;
		else
			nreset_sync_fpga = ~watchdog_reset;
	end
	
	always @(negedge nreset or posedge clk) begin
		if(~nreset)
			nreset_sync_control = 0;
		else
			nreset_sync_control = ~watchdog_reset;
	end
	
	generate 
		if (BURST_MODE == 1) begin
			/* synthesis preserve */ reg 	nreset_sync_intel_burst; 
			always @(negedge nreset or posedge clk) begin
				if(~nreset)
					nreset_sync_intel_burst = 0;
				else
					nreset_sync_intel_burst = ~watchdog_reset;
			end
		end
		else if (PAGE_MODE == 1 ) begin
			/* synthesis preserve */ reg 	nreset_sync_spansion_page; 
			always @(negedge nreset or posedge clk) begin
				if(~nreset)
					nreset_sync_spansion_page = 0;
				else
					nreset_sync_spansion_page = ~watchdog_reset;
			end
		end
		else begin
			/* synthesis preserve */ reg 	nreset_sync_flash_cfi; 
			always @(negedge nreset or posedge clk) begin
				if(~nreset)
					nreset_sync_flash_cfi = 0;
				else
					nreset_sync_flash_cfi = ~watchdog_reset;
			end
		end
	endgenerate
	
	generate 
		if(DECOMPRESSOR_MODE == "SPEED" || DECOMPRESSOR_MODE == "AREA") begin
			/* synthesis preserve */ reg 	nreset_sync_decompressor; 
			always @(negedge nreset or posedge clk) begin
				if(~nreset)
					nreset_sync_decompressor = 0;
				else
					nreset_sync_decompressor = ~watchdog_reset;
			end
		end
	endgenerate
	
	generate 
		if(PFL_RSU_WATCHDOG_ENABLED == 1) begin
			/* synthesis preserve */ reg 	nreset_sync_rsu; 
			always @(negedge nreset or posedge clk) begin
				if(~nreset)
					nreset_sync_rsu = 0;
				else
					nreset_sync_rsu = ~watchdog_reset;
			end
		end
		else
			assign watchdog_error = 0;	
	endgenerate
	
	alt_pfl_cfg_control alt_pfl_cfg_control (
		.clk(clk),
		.nreset(nreset_sync_control),

		// Flash reader block address pins
		.flash_stop_addr(flash_stop_addr),
		.flash_addr_out(flash_addr_control),
		.flash_addr_sload(flash_addr_sload),
		.flash_addr_cnt_en(flash_addr_cnt_en),
		.flash_done(flash_done),

		// Flash reader block data pins
		.flash_data_request(flash_data_request),
		.flash_data_ready(flash_data_ready),
		.flash_data(flash_data),
		
		// FPGA configuration block data pins
		.fpga_data(decompressor_data),
		.fpga_data_request(fpga_data_request),
		.fpga_data_ready(decompressor_data_ready),
		.fpga_data_read(decompressor_data_read),
		.fpga_flags(fpga_flags),
		.fpga_done(fpga_done),
		
		// State control pins from FPGA configuration block
		.halt(halt_control),
		.error(error_fpga),
		.restart(restart_control),
		.enable_configuration(enable_configuration),
		
		// External control pins
		.pfl_nreconfigure(pfl_nreconfigure),
		.page_sel(page_sel),
		.ready(control_ready),
		.enable_decompressor(enable_decompressor),
		.control_error_wait(control_error_wait),
		
		// RSU watchdog timed out
		.watchdog_timed_out(watchdog_error)
	);
	defparam alt_pfl_cfg_control.FLASH_DATA_WIDTH = (BURST_MODE == 1 && FLASH_DATA_WIDTH == 32)? BURST_FLASH_DATA_WIDTH_INDEX : FLASH_DATA_WIDTH;
	defparam alt_pfl_cfg_control.FLASH_ADDR_WIDTH = (BURST_MODE == 1 && FLASH_DATA_WIDTH == 32)? BURST_FLASH_ADDR_WIDTH_INDEX : FLASH_ADDR_WIDTH;
	defparam alt_pfl_cfg_control.SAFE_MODE_HALT = SAFE_MODE_HALT;
	defparam alt_pfl_cfg_control.SAFE_MODE_RETRY = SAFE_MODE_RETRY;
	defparam alt_pfl_cfg_control.SAFE_MODE_REVERT = SAFE_MODE_REVERT;
	defparam alt_pfl_cfg_control.SAFE_MODE_REVERT_ADDR = SAFE_MODE_REVERT_ADDR;
	defparam alt_pfl_cfg_control.FLASH_OPTIONS_ADDR = FLASH_OPTIONS_ADDR;
	
	generate
	if(DECOMPRESSOR_MODE == "SPEED") begin	
		alt_pfl_cfg_speed_decompressor alt_pfl_cfg_speed_decompressor (
			.clk(clk),
			.nreset(nreset_sync_decompressor),
			// with control block
			.flash_data_ready(decompressor_data_ready),
			.flash_data_read(decompressor_data_read),
			.flash_data(decompressor_data),
			.control_ready(control_ready),
			
			// with fpga block
			.fpga_data(fpga_data_fpga),
			.fpga_data_ready(fpga_data_ready),
			.fpga_data_read(fpga_data_read),
			.enable(enable_decompressor)
		);
	end
	else if(DECOMPRESSOR_MODE == "AREA") begin	
		alt_pfl_cfg_decompressor alt_pfl_cfg_decompressor (
			.clk(clk),
			.nreset(nreset_sync_decompressor),
			// with control block
			.flash_data_ready(decompressor_data_ready),
			.flash_data_read(decompressor_data_read),
			.flash_data(decompressor_data),
			.control_ready(control_ready),
			
			// with fpga block
			.fpga_data(fpga_data_fpga),
			.fpga_data_ready(fpga_data_ready),
			.fpga_data_read(fpga_data_read),
			.enable(enable_decompressor)
		);
	end
	else begin
		assign fpga_data_fpga = decompressor_data;
		assign fpga_data_ready = decompressor_data_ready;
		assign fpga_data_read = decompressor_data_read;
	end
	endgenerate

	alt_pfl_cfg_fpga alt_pfl_cfg_fpga (
		.clk(clk),
		.nreset(nreset_sync_fpga),

		// Data pins from controller
		.flash_data(fpga_data_fpga),
		.flash_data_request(fpga_data_request),
		.flash_data_ready(fpga_data_ready),
		.flash_data_read(fpga_data_read),
		.flash_flags(fpga_flags),
		.flash_done(fpga_done),
		
		// State control pins from controller
		.error(error_fpga),
		.halt(halt_control),
		.restart(restart_control),
		.enable_configuration(enable_configuration),
		.enable_nconfig(enable_nconfig),

		// Control pins to FPGA
		.fpga_data(fpga_data),
		.fpga_nconfig(fpga_nconfig),
		.fpga_conf_done(fpga_conf_done),
		.fpga_nstatus(fpga_nstatus),
		.fpga_dclk(fpga_dclk),
		
		.control_error_wait(control_error_wait),
		.user_nreconfigure(pfl_nreconfigure),
		.user_retry_revert(SAFE_MODE_HALT == 0),
		.watchdog_reset(watchdog_reset),
		
		// RSU watchdog timed out
		.watchdog_timed_out(watchdog_error)
	);
	defparam alt_pfl_cfg_fpga.DCLK_DIVISOR = DCLK_DIVISOR;
	defparam alt_pfl_cfg_fpga.CONF_DATA_WIDTH = CONF_DATA_WIDTH;
	defparam alt_pfl_cfg_fpga.wait_timer_width = CONF_WAIT_TIMER_WIDTH;

	generate
		if (BURST_MODE==1) begin
			alt_pfl_cfg_flash_intel_burst alt_pfl_cfg_flash_intel_burst (
				.clk(clk),
				.nreset(nreset_sync_intel_burst),

				// Flash pins
				.flash_select(flash_select),
				.flash_read(flash_read),
				.flash_write(flash_write),
				.flash_data_in(flash_data_in),
				.flash_data_out(flash_data_out),
				.flash_addr(flash_addr),
				.flash_nadv(flash_nadv),
				.flash_clk(flash_clk),
				.flash_rdy(flash_rdy),
				.flash_nreset(flash_nreset),
				.flash_data_highz(flash_data_highz),

				// Controller address
				.addr_in(flash_addr_control),
				.stop_addr_in(flash_stop_addr),
				.addr_sload(flash_addr_sload),
				.addr_cnt_en(flash_addr_cnt_en),
				.done(flash_done),
				
				// Controller data
				.data_request(flash_data_request),
				.data_ready(flash_data_ready),
				.data(flash_data),

				// Access control
				.flash_access_request(flash_access_request),
				.flash_access_granted(flash_access_granted)
			);
			defparam alt_pfl_cfg_flash_intel_burst.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH;
			defparam alt_pfl_cfg_flash_intel_burst.FLASH_ADDR_WIDTH = FLASH_ADDR_WIDTH;
			defparam alt_pfl_cfg_flash_intel_burst.ACCESS_CLK_DIVISOR = ACCESS_CLK_DIVISOR;
			defparam alt_pfl_cfg_flash_intel_burst.BURST_MODE_SPANSION = BURST_MODE_SPANSION;
			defparam alt_pfl_cfg_flash_intel_burst.BURST_MODE_NUMONYX = BURST_MODE_NUMONYX;
		end
		else if (PAGE_MODE == 1) begin
				alt_pfl_cfg_flash_spansion_page alt_pfl_cfg_flash_spansion_page (
				.clk(clk),
				.nreset(nreset_sync_spansion_page),

				// Flash pins
				.flash_select(flash_select),
				.flash_read(flash_read),
				.flash_write(flash_write),
				.flash_data_in(flash_data_in),
				.flash_data_out(flash_data_out),
				.flash_addr(flash_addr),
				.flash_nadv(flash_nadv),
				.flash_clk(flash_clk),
				.flash_rdy(flash_rdy),
				.flash_nreset(flash_nreset),
				.flash_data_highz(flash_data_highz),

				// Controller address
				.addr_in(flash_addr_control),
				.stop_addr_in(flash_stop_addr),
				.addr_sload(flash_addr_sload),
				.addr_cnt_en(flash_addr_cnt_en),
				.done(flash_done),
				
				// Controller data
				.data_request(flash_data_request),
				.data_ready(flash_data_ready),
				.data(flash_data),

				// Access control
				.flash_access_request(flash_access_request),
				.flash_access_granted(flash_access_granted)
			);
			defparam alt_pfl_cfg_flash_spansion_page.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH;
			defparam alt_pfl_cfg_flash_spansion_page.FLASH_ADDR_WIDTH = FLASH_ADDR_WIDTH;
			defparam alt_pfl_cfg_flash_spansion_page.ACCESS_CLK_DIVISOR = ACCESS_CLK_DIVISOR;
			defparam alt_pfl_cfg_flash_spansion_page.PAGE_ACCESS_CLK_DIVISOR =PAGE_ACCESS_CLK_DIVISOR;		
		end 
		else begin
			alt_pfl_cfg_flash_cfi alt_pfl_cfg_flash_cfi (
				.clk(clk),
				.nreset(nreset_sync_flash_cfi),

				// Flash pins
				.flash_select(flash_select),
				.flash_read(flash_read),
				.flash_write(flash_write),
				.flash_data_in(flash_data_in),
				.flash_data_out(flash_data_out),
				.flash_addr(flash_addr),
				.flash_nadv(flash_nadv),
				.flash_clk(flash_clk),
				.flash_rdy(flash_rdy),
						.flash_nreset(flash_nreset),
				.flash_data_highz(flash_data_highz),

				// Controller address
				.addr_in(flash_addr_control),
				.stop_addr_in(flash_stop_addr),
				.addr_sload(flash_addr_sload),
				.addr_cnt_en(flash_addr_cnt_en),
				.done(flash_done),
				
				// Controller data
				.data_request(flash_data_request),
				.data_ready(flash_data_ready),
				.data(flash_data),

				// Access control
				.flash_access_request(flash_access_request),
				.flash_access_granted(flash_access_granted)
			);
			defparam alt_pfl_cfg_flash_cfi.FLASH_DATA_WIDTH = FLASH_DATA_WIDTH;
			defparam alt_pfl_cfg_flash_cfi.FLASH_ADDR_WIDTH = FLASH_ADDR_WIDTH;
			defparam alt_pfl_cfg_flash_cfi.ACCESS_CLK_DIVISOR = ACCESS_CLK_DIVISOR;
		end
		
		if (PFL_RSU_WATCHDOG_ENABLED == 1)begin
			alt_pfl_cfg_rsu_wd alt_pfl_cfg_rsu_wd(
				.clk(clk),
				.nreset(nreset_sync_rsu),
				.fpga_conf_done(fpga_conf_done),
				.fpga_nstatus(fpga_nstatus),
				.pfl_nreconfigure(pfl_nreconfigure),
				.watchdog_reset(pfl_reset_watchdog),
				.watchdog_timed_out(watchdog_error)
			);
			defparam alt_pfl_cfg_rsu_wd.RSU_WATCHDOG_COUNTER = RSU_WATCHDOG_COUNTER;
		end
	endgenerate
endmodule
