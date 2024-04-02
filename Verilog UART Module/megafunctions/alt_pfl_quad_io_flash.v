////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_QUAD_IO_FLASH
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
// This module contains the PFL (Quad IO Flash) block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_quad_io_flash
(
	// FPGA IOs
	pfl_nreset,
	pfl_clk,
	fpga_conf_done,
	fpga_nstatus,
	fpga_data,
	dclk,
	fpga_nconfig,
	pfl_nreconfigure,
	fpga_pgm,
	pfl_reset_watchdog,
	pfl_watchdog_error,
	
	// QSFL IOs
	flash_sck,
	flash_ncs,
	flash_io0,
	flash_io1,
	flash_io2,
	flash_io3,
	
	// arbiter
	pfl_flash_access_request,
	pfl_flash_access_granted
);

// parameter
parameter FLASH_MFC						= "ALTERA";
parameter QFLASH_FAST_SPEED			= 0;
parameter FLASH_STATIC_WAIT_WIDTH	= 15;
parameter PFL_IR_BITS 					= 8;
parameter N_FLASH							= 4;
parameter ADDR_WIDTH						= 24;
parameter EXTRA_ADDR_BYTE				= 0;
parameter CONF_DATA_WIDTH				= 8;
parameter CONF_WAIT_TIMER_WIDTH		= 16;
parameter DCLK_DIVISOR					= 1;
parameter FEATURES_CFG					= 1;
parameter FEATURES_PGM					= 1;
parameter OPTION_BITS_START_ADDRESS	= 0;
parameter SAFE_MODE_HALT				= 0;
parameter SAFE_MODE_RETRY				= 1;
parameter SAFE_MODE_REVERT				= 0;
parameter SAFE_MODE_REVERT_ADDR		= 0;
parameter TRISTATE_CHECKBOX			= 1;
parameter DECOMPRESSOR_MODE			= "NONE";
parameter PFL_RSU_WATCHDOG_ENABLED	= 0;
parameter RSU_WATCHDOG_COUNTER		= 100000000;
parameter FLASH_BURST_EXTRA_CYCLE	= 0;
parameter DCLK_CREATE_DELAY			= 0;
parameter QSPI_DATA_DELAY				= 0;
parameter QSPI_DATA_DELAY_COUNT		= 1;
		
// Port Declaration
// FPGA IOs
input 	pfl_nreset;
input 	pfl_clk;
input 	fpga_conf_done;
input 	fpga_nstatus;
output 	[CONF_DATA_WIDTH-1:0]fpga_data;
output 	dclk;
output 	fpga_nconfig;
input 	pfl_nreconfigure;
input	[2:0]fpga_pgm;

// QSFL IOs
output	[N_FLASH-1:0] flash_sck;
output	[N_FLASH-1:0] flash_ncs;
inout	[N_FLASH-1:0] flash_io0;
inout	[N_FLASH-1:0] flash_io1;
inout	[N_FLASH-1:0] flash_io2;
inout	[N_FLASH-1:0] flash_io3;

// arbiter
output	pfl_flash_access_request;
input	pfl_flash_access_granted;

// RSU
input pfl_reset_watchdog;
output pfl_watchdog_error;

wire [N_FLASH-1:0] prog_sck;	
wire [N_FLASH-1:0] prog_ncs;
wire [N_FLASH-1:0] prog_io0;
wire enable_configuration;
wire [N_FLASH-1:0] cfg_sck;	
wire [N_FLASH-1:0] cfg_ncs;
wire [N_FLASH-1:0] cfg_io0_in;
wire [N_FLASH-1:0] cfg_io0_out;
wire [N_FLASH-1:0] cfg_io1_in;
wire [N_FLASH-1:0] cfg_io1_out;
wire [N_FLASH-1:0] cfg_io2_in;
wire [N_FLASH-1:0] cfg_io2_out;
wire [N_FLASH-1:0] cfg_io3_in;
wire [N_FLASH-1:0] cfg_io3_out;
wire prog_powerful;
wire p_prog_sck;
wire p_prog_ncs;
wire p_prog_io0;
wire p_prog_io1;
wire p_prog_io2;
wire p_prog_io3;
wire cfg_highz_io0;
wire cfg_highz_io1;
wire cfg_highz_io2;
wire cfg_highz_io3;
wire pgm_request_flash;
wire cfg_request_flash;

// Beside nreset, we allow user to tristate the IO when TRISTATE_CHECK is set and flash access is not granted -- in-sync with CFI-PFL
// This will allow other system to access the flash

// Port Wiring
generate
if (FLASH_MFC == "NUMONYX" || FLASH_MFC == "ALTERA" || FLASH_MFC == "MICRON") begin
	assign flash_sck 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? cfg_sck : (prog_powerful? {(N_FLASH){p_prog_sck}} : prog_sck)) : {(N_FLASH){1'bZ}};
	assign flash_ncs 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? cfg_ncs : (prog_powerful? {(N_FLASH){p_prog_ncs}} : prog_ncs)) : {(N_FLASH){1'bZ}};
	assign flash_io0 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? (cfg_highz_io0? {(N_FLASH){1'bZ}} : cfg_io0_out) : (prog_powerful? {(N_FLASH){p_prog_io0}} : prog_io0)) : {(N_FLASH){1'bZ}};
	assign flash_io1 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? (cfg_highz_io1? {(N_FLASH){1'bZ}} : cfg_io1_out) : (prog_powerful? {(N_FLASH){p_prog_io1}} : {(N_FLASH){1'bZ}})) : {(N_FLASH){1'bZ}};
	assign flash_io2 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? (cfg_highz_io2? {(N_FLASH){1'bZ}} : cfg_io2_out) : (prog_powerful? {(N_FLASH){p_prog_io2}} : {(N_FLASH){1'b1}})) : {(N_FLASH){1'bZ}};
	assign flash_io3 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? (cfg_highz_io3? {(N_FLASH){1'bZ}} : cfg_io3_out) : (prog_powerful? {(N_FLASH){p_prog_io3}} : {(N_FLASH){1'b1}})) : {(N_FLASH){1'bZ}};
end
else begin
	assign flash_sck 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? cfg_sck : prog_sck) : {(N_FLASH){1'bZ}};
	assign flash_ncs 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? cfg_ncs : prog_ncs) : {(N_FLASH){1'bZ}};
	assign flash_io0 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? (cfg_highz_io0? {(N_FLASH){1'bZ}} : cfg_io0_out) : prog_io0) : {(N_FLASH){1'bZ}};
	assign flash_io1 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? (cfg_highz_io1? {(N_FLASH){1'bZ}} : cfg_io1_out) : {(N_FLASH){1'bZ}}) : {(N_FLASH){1'bZ}};
	assign flash_io2 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? (cfg_highz_io2? {(N_FLASH){1'bZ}} : cfg_io2_out) : {(N_FLASH){1'b1}}) : {(N_FLASH){1'bZ}};
	assign flash_io3 				= (pfl_flash_access_granted || (TRISTATE_CHECKBOX == 0))? (enable_configuration? (cfg_highz_io3? {(N_FLASH){1'bZ}} : cfg_io3_out) : {(N_FLASH){1'b1}}) : {(N_FLASH){1'bZ}};
end
endgenerate 

generate
if(FEATURES_CFG == 1) begin
	assign cfg_io0_in 				= flash_io0;
	assign cfg_io1_in 				= flash_io1;
	assign cfg_io2_in 				= flash_io2;
	assign cfg_io3_in 				= flash_io3;
end
endgenerate

assign pfl_flash_access_request	= enable_configuration? cfg_request_flash : pgm_request_flash;

generate
if(FEATURES_PGM == 1) begin
	wire [PFL_IR_BITS-1:0] ir_in;
	wire [PFL_IR_BITS-1:0] ir_out;
	wire tdi;
	wire tck;
	wire sdr;
	wire udr;
	wire tdo;

	alt_pfl_quad_io_flash_pgm alt_pfl_quad_io_flash_pgm (
		.ir_in(ir_in),
		.ir_out(ir_out),
		.tdi(tdi),
		.tck(tck),
		.sdr(sdr),
		.udr(udr),
		.tdo(tdo),
		.flash_sck(prog_sck),
		.flash_ncs(prog_ncs),
		.flash_io0(prog_io0),
		.flash_io1(flash_io1),
		.powerful(prog_powerful),
		.p_prog_sck(p_prog_sck),
		.p_prog_ncs(p_prog_ncs),
		.p_prog_io0(p_prog_io0),
		.p_prog_io1(p_prog_io1),
		.p_prog_io2(p_prog_io2),
		.p_prog_io3(p_prog_io3),
		.enable_configuration(enable_configuration),
		.flash_access_request(pgm_request_flash),
		.flash_access_granted(pfl_flash_access_granted)
	);
	defparam
	alt_pfl_quad_io_flash_pgm.PFL_IR_BITS = PFL_IR_BITS,
	alt_pfl_quad_io_flash_pgm.N_FLASH = N_FLASH,
	alt_pfl_quad_io_flash_pgm.EXTRA_ADDR_BYTE = EXTRA_ADDR_BYTE,
	alt_pfl_quad_io_flash_pgm.FLASH_MFC = FLASH_MFC;
	
	sld_virtual_jtag_basic vjtag_module (
		.ir_in(ir_in),
		.ir_out(ir_out),
		.tdi(tdi),
		.tck(tck),
		.virtual_state_sdr(sdr),
		.virtual_state_udr(udr),
		.tdo(tdo)
	);
	defparam
	vjtag_module.sld_ir_width		 			= PFL_IR_BITS,
	vjtag_module.sld_version 		 			= 1,
	vjtag_module.sld_type_id 		 			= 11,
	vjtag_module.sld_mfg_id 		 			= 110,
	vjtag_module.sld_auto_instance_index	= "YES";
end
else begin
	assign enable_configuration = 1'b1;
	assign prog_powerful = 1'b0;
	assign pgm_request_flash = 1'b0;
	assign prog_sck = {(N_FLASH){1'b0}};
	assign prog_ncs = {(N_FLASH){1'b1}};
	assign prog_io0 = {(N_FLASH){1'b0}};
	assign p_prog_sck = 1'b0;
	assign p_prog_ncs = 1'b1;
	assign p_prog_io0 = 1'b0;
	assign p_prog_io1 = 1'b0;
	assign p_prog_io2 = 1'b0;
	assign p_prog_io3 = 1'b0;
end
endgenerate

generate
if(FEATURES_CFG == 1) begin
	alt_pfl_quad_io_flash_cfg alt_pfl_quad_io_flash_cfg (
		.nreset(pfl_nreset),
		.clk(pfl_clk),
		.flash_sck(cfg_sck),
		.flash_ncs(cfg_ncs),
		.flash_io0_out(cfg_io0_out),
		.flash_io0_in(cfg_io0_in),
		.flash_io1_out(cfg_io1_out),
		.flash_io1_in(cfg_io1_in),
		.flash_io2_out(cfg_io2_out),
		.flash_io2_in(cfg_io2_in),
		.flash_io3_out(cfg_io3_out),
		.flash_io3_in(cfg_io3_in),
		.flash_highz_io0(cfg_highz_io0),
		.flash_highz_io1(cfg_highz_io1),
		.flash_highz_io2(cfg_highz_io2),
		.flash_highz_io3(cfg_highz_io3),
		.fpga_conf_done(fpga_conf_done),
		.fpga_nstatus(fpga_nstatus),
		.fpga_data(fpga_data),
		.fpga_dclk(dclk),
		.fpga_nconfig(fpga_nconfig),
		.pfl_nreconfigure(pfl_nreconfigure),
		.enable_configuration(enable_configuration),
		.page_sel(fpga_pgm),
		.flash_access_request(cfg_request_flash),
		.flash_access_granted(pfl_flash_access_granted),
		.pfl_reset_watchdog(pfl_reset_watchdog),
		.pfl_watchdog_error(pfl_watchdog_error)
	);
	defparam
		alt_pfl_quad_io_flash_cfg.N_FLASH 						= N_FLASH,
		alt_pfl_quad_io_flash_cfg.ADDR_WIDTH		 			= ADDR_WIDTH,
		alt_pfl_quad_io_flash_cfg.CONF_DATA_WIDTH				= CONF_DATA_WIDTH,
		alt_pfl_quad_io_flash_cfg.CONF_WAIT_TIMER_WIDTH		= CONF_WAIT_TIMER_WIDTH,
		alt_pfl_quad_io_flash_cfg.DCLK_DIVISOR					= DCLK_DIVISOR,
		alt_pfl_quad_io_flash_cfg.FLASH_OPTIONS_ADDR			= OPTION_BITS_START_ADDRESS,
		alt_pfl_quad_io_flash_cfg.SAFE_MODE_HALT				= SAFE_MODE_HALT,
		alt_pfl_quad_io_flash_cfg.SAFE_MODE_RETRY				= SAFE_MODE_RETRY,
		alt_pfl_quad_io_flash_cfg.SAFE_MODE_REVERT			= SAFE_MODE_REVERT,
		alt_pfl_quad_io_flash_cfg.SAFE_MODE_REVERT_ADDR		= SAFE_MODE_REVERT_ADDR,
		alt_pfl_quad_io_flash_cfg.DECOMPRESSOR_MODE			= DECOMPRESSOR_MODE,
		alt_pfl_quad_io_flash_cfg.EXTRA_ADDR_BYTE				= EXTRA_ADDR_BYTE,
		alt_pfl_quad_io_flash_cfg.FLASH_BURST_EXTRA_CYCLE	= FLASH_BURST_EXTRA_CYCLE,
		alt_pfl_quad_io_flash_cfg.FLASH_MFC						= FLASH_MFC,
		alt_pfl_quad_io_flash_cfg.QFLASH_FAST_SPEED			= QFLASH_FAST_SPEED,
		alt_pfl_quad_io_flash_cfg.FLASH_STATIC_WAIT_WIDTH	= FLASH_STATIC_WAIT_WIDTH,
		alt_pfl_quad_io_flash_cfg.PFL_RSU_WATCHDOG_ENABLED	= PFL_RSU_WATCHDOG_ENABLED,
		alt_pfl_quad_io_flash_cfg.RSU_WATCHDOG_COUNTER		= RSU_WATCHDOG_COUNTER,
		alt_pfl_quad_io_flash_cfg.DCLK_CREATE_DELAY			= DCLK_CREATE_DELAY,
		alt_pfl_quad_io_flash_cfg.QSPI_DATA_DELAY				= QSPI_DATA_DELAY,
		alt_pfl_quad_io_flash_cfg.QSPI_DATA_DELAY_COUNT		= QSPI_DATA_DELAY_COUNT;
end
else begin
	assign cfg_sck 				= {(N_FLASH){1'b0}};
	assign cfg_ncs 				= {(N_FLASH){1'b1}};
	assign cfg_io0_out 			= {(N_FLASH){1'b0}};
	assign cfg_highz_io0 		= 1'b0; // always output
	assign cfg_io1_out 			= {(N_FLASH){1'b0}};
	assign cfg_highz_io1			= 1'bZ; // always input
	assign cfg_io2_out 			= {(N_FLASH){1'b0}};
	assign cfg_highz_io2			= 1'bZ; // always input
	assign cfg_io3_out 			= {(N_FLASH){1'b0}};
	assign cfg_highz_io3			= 1'bZ; // always input
	assign cfg_request_flash 	= 1'b0;
end

endgenerate
endmodule
