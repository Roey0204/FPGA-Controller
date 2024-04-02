////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG3_CONTROL
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
// This module contains the PFL configuration controller block
// This module only specially handle FPPx16 and FPPx32
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg3_control (
	clk,
	nreset,

	// Flash reader block address pins
	flash_stop_addr,
	flash_addr_out,
	flash_addr_sload,
	flash_addr_cnt_en,
	flash_done,
	
	// Flash reader block data pins
	flash_data_request,
	flash_data_ready,
	flash_data,
	
	// FPGA configuration block data pins
	fpga_data,
	fpga_data_ready,
	fpga_data_read,
	fpga_flags,
	
	// PGM allow configuration
	enable_configuration,
	enable_nconfig,
	
	// External control pins
	fpga_nstatus,
	fpga_condone,
	fpga_nconfig,
	pfl_nreconfigure,
	page_sel,
	
	// decompressor
	ready,
	enable_decompressor,
	
	// RSU watchdog timed out
	watchdog_timed_out
	
);
	parameter CONF_DATA_WIDTH								= 16;
	parameter FLASH_DATA_WIDTH 							= 16;
	parameter FLASH_ADDR_WIDTH 							= 25;
	parameter SAFE_MODE_HALT 								= 0;
	parameter SAFE_MODE_RETRY 								= 0;
	parameter SAFE_MODE_REVERT 							= 1;
	parameter SAFE_MODE_REVERT_ADDR 						= 'hABCDEF;
	parameter FLASH_OPTIONS_ADDR 							= 'h1FE000;
	parameter ALWAYS_USE_BYTE_ADDR						= 0;
	parameter FLASH_START_INDEX 							= (ALWAYS_USE_BYTE_ADDR == 1) ? 0 : 
																		((FLASH_DATA_WIDTH == 32) ? 2 : (FLASH_DATA_WIDTH == 16) ? 1 : 0);
	parameter CONF_WAIT_TIMER_WIDTH						= 16;
	localparam PACKET_WIDTH									= (CONF_DATA_WIDTH == 32)? 14 : 
																		(CONF_DATA_WIDTH == 16)? 15 : 16;
	localparam COUNTER_WIDTH								= (CONF_WAIT_TIMER_WIDTH > PACKET_WIDTH)? CONF_WAIT_TIMER_WIDTH : PACKET_WIDTH;
	localparam EXTRA_PACKET_WIDTH							= (COUNTER_WIDTH - PACKET_WIDTH);
	localparam EXTRA_TIMER_WIDTH							= (COUNTER_WIDTH - CONF_WAIT_TIMER_WIDTH);
	localparam [1:0] READ_COUNT_INDEX					= (CONF_DATA_WIDTH == 32)? 2'b00 : 
																		(CONF_DATA_WIDTH == 16)? 2'b01 : 2'b11;
	localparam [COUNTER_WIDTH-1:0] NCONFIG_TIMER		= {{(COUNTER_WIDTH-10){1'b0}}, 10'h3FF}; 	// This is for CFG_NCONFIG, CFG_NSTATUS_WAIT
	localparam [COUNTER_WIDTH-1:0] SMALLEST_TIMER	= {{(COUNTER_WIDTH-16){1'b0}}, 16'hFFFF};	// This is for CFG_USERMODE_CONFIRM
	localparam [COUNTER_WIDTH-1:0] LARGEST_TIMER		= (EXTRA_TIMER_WIDTH == 0) ? {(CONF_WAIT_TIMER_WIDTH){1'b1}} :		// This is for CFG_NSTATUS, CFG_USERMODE_WAIT
																		{{(EXTRA_TIMER_WIDTH){1'b0}}, {(CONF_WAIT_TIMER_WIDTH){1'b1}}}; 				
	
	input 	clk;
	input 	nreset;
	
	// We still need to remain this start and stop addr in nature of byte size
	// This is because the data stored in our POF file is in byte unit
	// Flash reader block address pins
	output 	[FLASH_ADDR_WIDTH-1:0] flash_stop_addr;
	output 	[FLASH_ADDR_WIDTH-1:0] flash_addr_out;
	
	output	flash_addr_sload;
	output	flash_addr_cnt_en;
	input		flash_done;
	
	// Flash reader block data pins
	output	flash_data_request;
	input		flash_data_ready;
	input		[FLASH_DATA_WIDTH-1:0] flash_data;
	
	// FPGA configuration block data pins
	output	[CONF_DATA_WIDTH-1:0] fpga_data;
	output	[7:0] fpga_flags;
	output	fpga_data_ready;
	input		fpga_data_read;

	// PGM allow configuration
	input		enable_configuration;
	input		enable_nconfig;
	
	// External control pins
	input		fpga_nstatus;
	input 	fpga_condone;
	output	fpga_nconfig;
	input		pfl_nreconfigure;
	input		[2:0] page_sel;
	
	// decompressor
	output	ready = current_state == CFG_DATA;
	output	enable_decompressor = version4 && (fpga_flags == 8'h02);

	// RSU
	input		watchdog_timed_out;
	
	// Internal Param
	parameter VERSION_OFFSET 			= 'h80;
	parameter FLASH_BYTE_ADDR_WIDTH 	= FLASH_ADDR_WIDTH + FLASH_START_INDEX;
	
	// State Machine
	reg [5:0] current_state /* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
	reg [5:0] next_state;
	parameter CFG_SAME 						= 6'd0;
	parameter CFG_POWERUP 					= 6'd1;
	parameter CFG_INIT 						= 6'd2;
	// assert NCONFIG
	parameter CFG_PRE_NCONFIG 				= 6'd3;
	parameter CFG_LOAD_NCONFIG 			= 6'd4;
	parameter CFG_NCONFIG 					= 6'd5;
	parameter CFG_RECONFIG_WAIT			= 6'd6;
	// make sure NSTATUS goes high within one period
	parameter CFG_PRE_NSTATUS				= 6'd7;
	parameter CFG_LOAD_NSTATUS				= 6'd8;
	parameter CFG_NSTATUS					= 6'd9;
	// make sure NSTATUS is stable for one period
	parameter CFG_PRE_NSTATUS_WAIT		= 6'd10;
	parameter CFG_LOAD_NSTATUS_WAIT		= 6'd11;
	parameter CFG_NSTATUS_WAIT				= 6'd12;
	// make sure CONDONE goes high within one period
	parameter CFG_PRE_USERMODE_WAIT		= 6'd13;
	parameter CFG_LOAD_USERMODE_WAIT		= 6'd14;
	parameter CFG_USERMODE_WAIT			= 6'd15;
	// make sure CONDONE is stable for one period
	parameter CFG_PRE_USERMODE_CONFIRM	= 6'd16;
	parameter CFG_LOAD_USERMODE_CONFIRM	= 6'd17;
	parameter CFG_USERMODE_CONFIRM		= 6'd18;
	// stop
	parameter CFG_USERMODE					= 6'd19;
	// read version
	parameter CFG_PRE_VERSION				= 6'd20;
	parameter CFG_LOAD_VERSION				= 6'd21;
	parameter CFG_VERSION					= 6'd22;
	parameter CFG_VERSION_DUMMY			= 6'd23;
	// read option
	parameter CFG_PRE_OPTION				= 6'd24;
	parameter CFG_LOAD_OPTION				= 6'd25;
	parameter CFG_OPTION						= 6'd26;
	parameter CFG_OPTION_DUMMY				= 6'd27;
	// read header
	parameter CFG_PRE_HEADER				= 6'd28;
	parameter CFG_LOAD_HEADER				= 6'd29;
	parameter CFG_HEADER						= 6'd30;
	parameter CFG_HEADER_DUMMY				= 6'd31;
	// read data
	parameter CFG_PRE_DATA					= 6'd32;
	parameter CFG_LOAD_DATA					= 6'd33;
	parameter CFG_DATA						= 6'd34;
	parameter CFG_DATA_DUMMY				= 6'd35;
	// Error handling
	parameter CFG_ERROR						= 6'd36;
	parameter CFG_REVERT						= 6'd37;
	parameter CFG_HALT						= 6'd38;
	parameter CFG_RECONFIG					= 6'd39;
	
	// Options bits definition and information extracted from Options bits
	reg	[31:0] option_bits;
	wire	[FLASH_BYTE_ADDR_WIDTH-1:0] page_end_addr 	= {option_bits[FLASH_BYTE_ADDR_WIDTH+3:17],13'b0};
	wire	[FLASH_BYTE_ADDR_WIDTH-1:0] page_start_addr 	= {option_bits[FLASH_BYTE_ADDR_WIDTH-13:1],13'b0};
	wire	page_done_bit = option_bits[0];

	// Header bits definition and information extracted from Header bits
	reg		[31:0]header_bits;
	wire 		[COUNTER_WIDTH-1:0] header_packet_length;
	reg		dummy_byte;
	always @ (posedge clk) begin
		if (current_state == CFG_HEADER_DUMMY) begin
			dummy_byte = (CONF_DATA_WIDTH == 8) && header_packet_length[0];
		end
	end
	generate
		if (EXTRA_PACKET_WIDTH == 0 && CONF_DATA_WIDTH == 8) begin
			assign header_packet_length = header_bits[31:16];
		end
		else if (CONF_DATA_WIDTH == 8) begin
			assign header_packet_length = {{(EXTRA_PACKET_WIDTH){1'b0}}, header_bits[31:16]};
		end
		else if (EXTRA_PACKET_WIDTH == 0 && CONF_DATA_WIDTH == 16) begin
			assign header_packet_length = header_bits[31:17];
		end
		else if (CONF_DATA_WIDTH == 16) begin
			assign header_packet_length = {{(EXTRA_PACKET_WIDTH){1'b0}}, header_bits[31:17]};
		end
		else if (EXTRA_PACKET_WIDTH == 0 && CONF_DATA_WIDTH == 32) begin
			assign header_packet_length = header_bits[31:18];
		end
		else begin
			assign header_packet_length = {{(EXTRA_PACKET_WIDTH){1'b0}}, header_bits[31:18]};
		end
	endgenerate
	
	// Conversion from byte information to flash_data_width
	wire [FLASH_BYTE_ADDR_WIDTH-1:0] option_addr_v2 = FLASH_OPTIONS_ADDR[FLASH_BYTE_ADDR_WIDTH-1:0] | {page_sel_latch,2'b0};
	wire [FLASH_BYTE_ADDR_WIDTH-1:0] option_addr_v0 = FLASH_OPTIONS_ADDR[FLASH_BYTE_ADDR_WIDTH-1:0] | {page_sel_latch,1'b0};
	reg [FLASH_BYTE_ADDR_WIDTH-1:0] flash_byte_addr_out;
	always @ (posedge clk) begin
		if (current_state == CFG_PRE_VERSION) 							// Read Version
			flash_byte_addr_out = FLASH_OPTIONS_ADDR[FLASH_BYTE_ADDR_WIDTH-1:0] | VERSION_OFFSET[FLASH_BYTE_ADDR_WIDTH-1:0];
		else if (current_state == CFG_PRE_OPTION & version2) 		// Read Option Bits (Version 2 and above)
			flash_byte_addr_out = option_addr_v2;
		else if (current_state == CFG_PRE_OPTION)						// Read Option Bits (Older version)
			flash_byte_addr_out = option_addr_v0;
		else if (current_state == CFG_PRE_HEADER & revert)			// Revert Addr		
			flash_byte_addr_out = SAFE_MODE_REVERT_ADDR[FLASH_BYTE_ADDR_WIDTH-1:0];
		else if (current_state == CFG_PRE_HEADER)						// Read Package
			flash_byte_addr_out = page_start_addr;
	end
	assign flash_addr_out = flash_byte_addr_out[FLASH_BYTE_ADDR_WIDTH-1:FLASH_START_INDEX];
	assign flash_stop_addr = page_end_addr[FLASH_BYTE_ADDR_WIDTH-1:FLASH_START_INDEX];
							
	// Defined all the data's req, ready, read signals
	// All the request signal
	wire conv_req_flash;
	reg cntl_req_conv;
	
	// All the ready signal
	wire flash_ready_conv;
	wire conv_ready_cntl;
	
	// All the read signal
	wire conv_read_flash;
	wire cntl_read_conv;
		
	// All the data
	wire[FLASH_DATA_WIDTH-1:0] 	flash_to_conv_data;
	wire[CONF_DATA_WIDTH-1:0] 		conv_to_cntl_data;
	
	// Instatiation of CONV
	generate
		// eg: CONF_DATA_WIDTH = 32 and  FLASH_DATA_WIDTH = 16
		// eg: CONF_DATA_WIDTH = 32 and  FLASH_DATA_WIDTH = 8
		// eg: CONF_DATA_WIDTH = 16 and  FLASH_DATA_WIDTH = 8
		if (CONF_DATA_WIDTH > FLASH_DATA_WIDTH) begin
			alt_pfl_up_converter alt_pfl_up_converter(
				.clk(clk),
				.nreset(nreset),
				
				// Interface with flash
				.data_in(flash_to_conv_data),
				.flash_data_request(conv_req_flash),
				.flash_data_ready(flash_ready_conv),
				.flash_data_read(conv_read_flash),
			
				// Interface with controller (Processor)
				.data_out(conv_to_cntl_data),
				.data_request(cntl_req_conv),
				.data_ready(conv_ready_cntl),
				.data_read(cntl_read_conv)
			);
			defparam
				alt_pfl_up_converter.DATA_IN_WIDTH = FLASH_DATA_WIDTH,
				alt_pfl_up_converter.DATA_OUT_WIDTH = CONF_DATA_WIDTH;
		end
		// eg: CONF_DATA_WIDTH = 16 and  FLASH_DATA_WIDTH = 32
		// eg: CONF_DATA_WIDTH = 8 and  FLASH_DATA_WIDTH = 16
		// eg: CONF_DATA_WIDTH = 8 and  FLASH_DATA_WIDTH = 32
		else if (CONF_DATA_WIDTH < FLASH_DATA_WIDTH) begin
						
			alt_pfl_down_converter alt_pfl_down_converter(
				.clk(clk),
				.nreset(nreset),
				
				// Interface with flash
				.data_in(flash_to_conv_data),
				.flash_data_request(conv_req_flash),
				.flash_data_ready(flash_ready_conv),
				.flash_data_read(conv_read_flash),
				
				// Interface with controller (Processor)
				.data_out(conv_to_cntl_data),
				.data_request(cntl_req_conv),
				.data_ready(conv_ready_cntl),
				.data_read(cntl_read_conv)
			);
			defparam
				alt_pfl_down_converter.DATA_IN_WIDTH = FLASH_DATA_WIDTH,
				alt_pfl_down_converter.DATA_OUT_WIDTH = CONF_DATA_WIDTH;
		end
		// eg: CONF_DATA_WIDTH = 32 and  FLASH_DATA_WIDTH = 32
		// eg: CONF_DATA_WIDTH = 16 and  FLASH_DATA_WIDTH = 16
		// eg: CONF_DATA_WIDTH = 8 and  FLASH_DATA_WIDTH = 8
		else begin
			assign conv_req_flash = cntl_req_conv;
			assign conv_ready_cntl = flash_ready_conv;
			assign conv_to_cntl_data = flash_to_conv_data;
			assign conv_read_flash = cntl_read_conv;
		end
	endgenerate
	
	// Make connection TO Flash module
	assign flash_data_request = conv_req_flash;
	assign flash_addr_sload = current_state == CFG_LOAD_VERSION ||
										current_state == CFG_LOAD_OPTION ||
										current_state == CFG_LOAD_HEADER;
	assign flash_addr_cnt_en = conv_read_flash;
	
	// Make connection TO CONV
	wire cntl_req_conv_wire = current_state == CFG_VERSION || current_state == CFG_OPTION ||
										current_state == CFG_HEADER || current_state == CFG_HEADER_DUMMY || 
										current_state == CFG_PRE_DATA || current_state == CFG_LOAD_DATA || 
										current_state == CFG_DATA || current_state == CFG_DATA_DUMMY;
	always @ (posedge clk) begin
		cntl_req_conv = cntl_req_conv_wire;
	end
	assign flash_to_conv_data = flash_data;
	assign flash_ready_conv = flash_data_ready;
	assign cntl_read_conv = ((current_state == CFG_OPTION || current_state == CFG_HEADER || (current_state == CFG_DATA_DUMMY & dummy_byte)) & conv_ready_cntl) ||
									(current_state == CFG_DATA & fpga_data_read);
	
	// Make connection TO FPGA module
	assign fpga_data = conv_to_cntl_data;
	assign fpga_flags = header_bits[15:8];
	assign fpga_data_ready = (conv_ready_cntl & current_state == CFG_DATA) || 
										current_state == CFG_USERMODE_WAIT || current_state == CFG_USERMODE_CONFIRM;
	
	// This is to get the version of POF
	reg 	version2;
	reg 	version3;
	reg 	version4;
	wire	virtual_version3 = version4 && (fpga_flags == 8'h00 || fpga_flags == 8'h01);
	
	always @(posedge clk)
	begin
		if (current_state == CFG_VERSION && conv_ready_cntl) begin
			version2 = (conv_to_cntl_data[7:0] == 8'hFF) ? 1'b0 : 1'b1;
			version3 = (conv_to_cntl_data[7:0] == 8'h03) ? 1'b1 : 1'b0;
			version4 = (conv_to_cntl_data[7:0] == 8'h04) ? 1'b1 : 1'b0;
		end
	end
			
	// Handling the reconfiguration (Either from Error or PFL nreconfigure)
	reg reconfigure;
	reg revert;
	reg [2:0] page_sel_latch;
	always @ (posedge clk) begin
		if (current_state == CFG_RECONFIG)
			page_sel_latch = page_sel;
		else if (current_state == CFG_PRE_VERSION & ~reconfigure)
			page_sel_latch = page_sel;
	end
	
	always @ (negedge nreset or posedge clk) begin
		if (~nreset)
			reconfigure = 1'b0;
		else begin
			if (current_state == CFG_PRE_VERSION)
				reconfigure = 1'b0;
			else if (~pfl_nreconfigure_sync)
				reconfigure = 1'b1;
		end
	end
	
	always @ (negedge nreset or posedge clk) begin
		if (~nreset)
			revert = 1'b0;
		else begin
			if (current_state == CFG_REVERT)
				revert = 1'b1;
			else if (current_state == CFG_RECONFIG)
				revert = 1'b0;
		end
	end
	initial begin
		reconfigure = 1'b0;
		revert = 1'b0;
		dummy_byte = 1'b0;
	end
	
	generate
		if (CONF_DATA_WIDTH == 8) begin
			always @(posedge clk) begin
				if (current_state == CFG_OPTION & conv_ready_cntl) begin
					if (OPTION_HEADER_BIT == 2'b11)
						option_bits[31:24] = conv_to_cntl_data;
					else if (OPTION_HEADER_BIT == 2'b10)
						option_bits[23:16] = conv_to_cntl_data;
					else if (OPTION_HEADER_BIT == 2'b01)
						option_bits[15:8] = conv_to_cntl_data;
					else
						option_bits[7:0] = conv_to_cntl_data;
				end
			end
			
			always @(posedge clk) begin
				if (current_state == CFG_HEADER & conv_ready_cntl) begin
					if (OPTION_HEADER_BIT == 2'b11)
						header_bits[31:24] = conv_to_cntl_data;
					else if (OPTION_HEADER_BIT == 2'b10)
						header_bits[23:16] = conv_to_cntl_data;
					else if (OPTION_HEADER_BIT == 2'b01)
						header_bits[15:8] = conv_to_cntl_data;
					else
						header_bits[7:0] = conv_to_cntl_data;	
				end
			end
		end
		else if (CONF_DATA_WIDTH == 16) begin
			always @(posedge clk) begin
				if (current_state == CFG_OPTION & conv_ready_cntl) begin
					if (OPTION_HEADER_BIT == 2'b01)
						option_bits[31:16] = conv_to_cntl_data;
					else
						option_bits[15:0] = conv_to_cntl_data;
				end
			end
			
			always @(posedge clk) begin
				if (current_state == CFG_HEADER & conv_ready_cntl) begin
					if (OPTION_HEADER_BIT == 2'b01)
						header_bits[31:16] = conv_to_cntl_data;
					else
						header_bits[15:0] = conv_to_cntl_data;		
				end
			end
		end
		else begin
			always @(posedge clk) begin
				if (current_state == CFG_OPTION && conv_ready_cntl)
					option_bits = conv_to_cntl_data;
			end
			
			always @(posedge clk) begin
				if (current_state == CFG_HEADER & conv_ready_cntl)
					header_bits = conv_to_cntl_data;
			end
		end
	endgenerate

	// READ counter - 14 or 15 bits counter
	wire counter_cnt_en = (current_state == CFG_NCONFIG || current_state == CFG_NSTATUS ||
									current_state == CFG_NSTATUS_WAIT || current_state == CFG_USERMODE_WAIT ||
									current_state == CFG_USERMODE_CONFIRM || 
									(current_state == CFG_DATA && fpga_data_read));
	reg [COUNTER_WIDTH-1:0] header_packet_minus_two_length;
	wire [COUNTER_WIDTH-1:0] header_packet_minus_two_length_wire = header_packet_length - {{(COUNTER_WIDTH-2){1'b0}}, 2'b10};
	always @ (posedge clk) begin
		if (current_state == CFG_HEADER_DUMMY) begin
			header_packet_minus_two_length = header_packet_minus_two_length_wire;
		end
	end
	reg [COUNTER_WIDTH-1:0] counter_data;
	always @ (posedge clk) begin
		if (current_state == CFG_PRE_NCONFIG || current_state == CFG_PRE_NSTATUS_WAIT)
			counter_data = NCONFIG_TIMER;
		else if (current_state == CFG_PRE_USERMODE_CONFIRM)
			counter_data = SMALLEST_TIMER;
		else if (current_state == CFG_PRE_NSTATUS || current_state == CFG_PRE_USERMODE_WAIT)
			counter_data = LARGEST_TIMER;
		else if (current_state == CFG_PRE_DATA)
			counter_data = header_packet_minus_two_length;
	end
	reg sload_counter;
	always @ (posedge clk) begin
		sload_counter = current_state == CFG_PRE_NCONFIG || current_state == CFG_PRE_NSTATUS_WAIT || 
								current_state == CFG_PRE_USERMODE_CONFIRM || current_state == CFG_PRE_NSTATUS || 
								current_state == CFG_PRE_USERMODE_WAIT || current_state == CFG_PRE_DATA;
	end
	wire [COUNTER_WIDTH-1:0] counter_q;
	reg read_counter_done;
	reg counter_done;

	lpm_counter counter(
		.clock(clk),
		.cnt_en(counter_cnt_en),
		.sload(sload_counter),
		.data(counter_data),
		.q(counter_q)
	);
	defparam counter.lpm_width=COUNTER_WIDTH;
	defparam counter.lpm_direction="DOWN";
	wire read_counter_almost_done = (counter_q == {(COUNTER_WIDTH){1'b0}}) & fpga_data_read;
	wire counter_done_almost_done = (counter_q == {(COUNTER_WIDTH){1'b0}});

	always @ (posedge clk) begin
		if (sload_counter)
			read_counter_done = 1'b0;
		else if (read_counter_almost_done)
			read_counter_done = 1'b1;
	end
	always @ (posedge clk) begin
		if (sload_counter)
			counter_done = 1'b0;
		else
			counter_done = counter_done_almost_done;
	end
	
	// OPTION + HEADER
	reg [1:0] OPTION_HEADER_BIT;
	always @ (posedge clk) begin
		if (current_state == CFG_PRE_OPTION || current_state == CFG_PRE_HEADER || current_state == CFG_HEADER_DUMMY)
			OPTION_HEADER_BIT = 2'b00;
		else if ((current_state == CFG_OPTION || current_state == CFG_HEADER) & conv_ready_cntl)
			OPTION_HEADER_BIT = OPTION_HEADER_BIT + 2'b01;
	end
	
	// Packetize
	wire	pof_packetized = version3 || virtual_version3;
	wire	data_block_complete = pof_packetized & read_counter_done & fpga_data_read;
	
	// syncing to avoid glitch
	wire fpga_nstatus_sync;
	wire fpga_condone_sync;
	wire enable_configuration_sync;
	wire pfl_nreconfigure_sync;
	wire enable_nconfig_sync;
	alt_pfl_glitch nstatus_sync (.clk(clk), .data_in(fpga_nstatus), .data_out(fpga_nstatus_sync)); defparam nstatus_sync.INIT = 1;
	alt_pfl_glitch condone_sync (.clk(clk), .data_in(fpga_condone), .data_out(fpga_condone_sync)); defparam condone_sync.INIT = 1;
	alt_pfl_glitch enable_sync (.clk(clk), .data_in(enable_configuration), .data_out(enable_configuration_sync)); defparam enable_sync.INIT = 0;
	alt_pfl_glitch nreconfigure_sync (.clk(clk), .data_in(pfl_nreconfigure), .data_out(pfl_nreconfigure_sync)); defparam nreconfigure_sync.INIT = 1;
	alt_pfl_glitch nconfig_sync (.clk(clk), .data_in(enable_nconfig), .data_out(enable_nconfig_sync)); defparam nconfig_sync.INIT = 0;
	
	wire fpga_nconfig_signal = ~(current_state == CFG_NCONFIG || enable_nconfig_sync);
	opndrn nconfig_opndrn (
		.in(fpga_nconfig_signal),
		.out(fpga_nconfig)
	);

	always @(*)
	begin
		case (current_state)
			CFG_POWERUP :
				if (fpga_nstatus_sync)
					next_state = CFG_INIT;
				else
					next_state = CFG_SAME;
			CFG_INIT :
				if (fpga_condone_sync)
					next_state = CFG_PRE_USERMODE_CONFIRM;
				else if (fpga_nstatus_sync)
					next_state = CFG_PRE_NSTATUS_WAIT;
				else
					next_state = CFG_PRE_NCONFIG;
			CFG_PRE_NCONFIG:
				next_state = CFG_LOAD_NCONFIG;
			CFG_LOAD_NCONFIG:
				next_state = CFG_NCONFIG;
			CFG_NCONFIG:
				if (counter_done)
					next_state = CFG_RECONFIG_WAIT;
				else
					next_state = CFG_SAME;
			CFG_RECONFIG_WAIT:
				if (pfl_nreconfigure_sync)
					next_state = CFG_PRE_NSTATUS;
				else
					next_state = CFG_SAME;
			CFG_PRE_NSTATUS:
				next_state = CFG_LOAD_NSTATUS;
			CFG_LOAD_NSTATUS:
				next_state = CFG_NSTATUS;
			CFG_NSTATUS:
				if (fpga_nstatus_sync)
					next_state = CFG_PRE_NSTATUS_WAIT;
				else if (counter_done) 								// Error where nstatus fail to go high
					next_state = CFG_ERROR;
				else
					next_state = CFG_SAME;
			CFG_PRE_NSTATUS_WAIT:
				next_state = CFG_LOAD_NSTATUS_WAIT;
			CFG_LOAD_NSTATUS_WAIT:
				next_state = CFG_NSTATUS_WAIT;
			CFG_NSTATUS_WAIT:
				if (~fpga_nstatus_sync)								// Error where nstatus is not stable for a defined period
					next_state = CFG_ERROR;
				else if (counter_done)
					next_state = CFG_PRE_VERSION;
				else
					next_state = CFG_SAME;
			CFG_PRE_USERMODE_WAIT:
				next_state = CFG_LOAD_USERMODE_WAIT;
			CFG_LOAD_USERMODE_WAIT:
				next_state = CFG_USERMODE_WAIT;
			CFG_USERMODE_WAIT:										// All data being sent, waiting condone to go high
				if (fpga_condone_sync)							
					next_state = CFG_PRE_USERMODE_CONFIRM;
				else if (~fpga_nstatus_sync)						// nstatus asserted
					next_state = CFG_ERROR;
				else if (counter_done)								// condone fail to go high
					next_state = CFG_ERROR;
				else 
					next_state = CFG_SAME;
			CFG_PRE_USERMODE_CONFIRM:
				next_state = CFG_LOAD_USERMODE_CONFIRM;
			CFG_LOAD_USERMODE_CONFIRM:
				next_state = CFG_USERMODE_CONFIRM;
			CFG_USERMODE_CONFIRM:
				if (~fpga_condone_sync | ~fpga_nstatus_sync)  // condone and nstatus fail to stay high for a defined period
					next_state = CFG_ERROR;
				else if (counter_done)
					next_state = CFG_USERMODE;
				else 
					next_state = CFG_SAME;
			CFG_USERMODE:
				if (~fpga_condone_sync | watchdog_timed_out)
					next_state = CFG_ERROR;
				else
					next_state = CFG_SAME;
			CFG_PRE_VERSION:
				next_state = CFG_LOAD_VERSION;
			CFG_LOAD_VERSION:
				next_state = CFG_VERSION;
			CFG_VERSION:
				if (conv_ready_cntl)
					next_state = CFG_VERSION_DUMMY;
				else 
					next_state = CFG_SAME;
			CFG_VERSION_DUMMY:
				if (revert)
					next_state = CFG_PRE_HEADER;
				else
					next_state = CFG_PRE_OPTION;
			CFG_PRE_OPTION:
				next_state = CFG_LOAD_OPTION;
			CFG_LOAD_OPTION:
				next_state = CFG_OPTION;
			CFG_OPTION:
				if (OPTION_HEADER_BIT == READ_COUNT_INDEX & conv_ready_cntl)
					next_state = CFG_OPTION_DUMMY;
				else
					next_state = CFG_SAME;
			CFG_OPTION_DUMMY:
				if (page_done_bit)
					next_state = CFG_ERROR;
				else
					next_state = CFG_PRE_HEADER;
			CFG_PRE_HEADER:
				next_state = CFG_LOAD_HEADER;
			CFG_LOAD_HEADER:
				next_state = CFG_HEADER;
			CFG_HEADER:
				if (OPTION_HEADER_BIT == READ_COUNT_INDEX & conv_ready_cntl)
					next_state = CFG_HEADER_DUMMY;
				else 
					next_state = CFG_SAME;
			CFG_HEADER_DUMMY:
				next_state = CFG_PRE_DATA;
			CFG_PRE_DATA:
				next_state = CFG_LOAD_DATA;
			CFG_LOAD_DATA:
				next_state = CFG_DATA;
			CFG_DATA:
				if (fpga_condone_sync)
					next_state = CFG_PRE_USERMODE_CONFIRM;
				else if (~fpga_nstatus_sync)
					next_state = CFG_ERROR;
				else if (flash_done)
					next_state = CFG_PRE_USERMODE_WAIT;
				else if (data_block_complete)
					next_state = CFG_DATA_DUMMY;
				else
					next_state = CFG_SAME;
			CFG_DATA_DUMMY:
				if (~dummy_byte | conv_ready_cntl)
					next_state = CFG_HEADER;
				else
					next_state = CFG_SAME;
			CFG_ERROR:
				if (SAFE_MODE_REVERT == 1)
					next_state = CFG_REVERT;
				else if (SAFE_MODE_HALT == 1)
					next_state = CFG_HALT;
				else
					next_state = CFG_INIT;
			CFG_REVERT:
				next_state = CFG_PRE_NCONFIG;
			CFG_HALT:
				next_state = CFG_SAME;
			CFG_RECONFIG:
				next_state = CFG_PRE_NCONFIG;
			default:
				next_state = CFG_POWERUP;
		endcase
	end
	
	initial begin
		current_state = CFG_POWERUP;
		next_state = CFG_POWERUP; 
	end
			
	always @(negedge nreset or posedge clk)
	begin
		if(~nreset) begin
			current_state = CFG_POWERUP;
		end
		else begin
			if (~enable_configuration_sync)
				current_state = CFG_POWERUP;
			else if (~reconfigure & ~pfl_nreconfigure_sync)
				current_state = CFG_RECONFIG;
			else if (next_state != CFG_SAME)
				current_state = next_state;
			else
				current_state = current_state;
		end
	end

	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
					value = value >> 1;
		end
	endfunction
	
endmodule
