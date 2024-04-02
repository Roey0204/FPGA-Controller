////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_QUAD_IO_FLASH_CFG_FLASH
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
// This module contains the PFL (Quad IO Flash) Configuration Flash block
//************************************************************

module alt_pfl_quad_io_flash_cfg_flash
(
	// FPGA IOs
	nreset,
	clk,
	
	// QPFL IOs
	flash_sck,
	flash_ncs,
	flash_io0_out,
	flash_io0_in,
	flash_io1_out,
	flash_io1_in,
	flash_io2_in,
	flash_io2_out,
	flash_io3_in,
	flash_io3_out,
	flash_highz_io0,
	flash_highz_io1,
	flash_highz_io2,
	flash_highz_io3,
	
	addr_in,
	stop_addr_in,
	addr_sload,
	addr_cnt_en,
	done,
	
	data_request,
	data_ready,
	data,
	
	flash_access_request,
	flash_access_granted
);

	// parameter
	parameter N_FLASH = 4;
	parameter FLASH_ADDR_WIDTH = 22;
	parameter EXTRA_ADDR_BYTE = 0;
	parameter FLASH_MFC = "MACRONIX";
	
	// local parameter
	localparam	REAL_ADDR_INDEX = (N_FLASH == 8) ? 3 :
											(N_FLASH == 4) ? 2 :
											(N_FLASH == 2) ? 1 : 0;
	localparam	REAL_ADDR_WIDTH = FLASH_ADDR_WIDTH - REAL_ADDR_INDEX;	
	localparam	UNUSED_ADDR_WIDTH = (EXTRA_ADDR_BYTE == 1) ? 32 - REAL_ADDR_WIDTH : 24 - REAL_ADDR_WIDTH;
	localparam	CFG_ADDR_BIT = (EXTRA_ADDR_BYTE == 1) ? 32 : 24;
	localparam 	DATA_WIDTH = N_FLASH * 4;
	localparam	[7:0] rcr_data_in = (FLASH_MFC == "SPANSION" || FLASH_MFC == "WINBOND") ? 8'h35 :
									(FLASH_MFC == "ATMEL") ? 8'h3F : 8'h05;
	localparam	[5:0] rcr_qe_bit = (FLASH_MFC == "SPANSION" || FLASH_MFC == "WINBOND") ? 6'd15 :
										(FLASH_MFC == "ATMEL") ? 6'd9 : 6'd10;
	localparam	[15:0] wrr_qe_value = (FLASH_MFC == "ATMEL") ? 16'h3E80 : 16'h0140;
	localparam	[5:0] wrr_qe_size = (FLASH_MFC == "SPANSION" || FLASH_MFC == "WINBOND") ? 6'd24 : 6'd16;
	localparam	[7:0] QUAD_IO_READ_OPCODE = ((FLASH_MFC == "SPANSION") && (EXTRA_ADDR_BYTE == 1)) ? 8'b1110_1100 : 8'b1110_1011;
	
	// Addressing is a bit tricky
	// Standardize the flow
	// Control Block always give BYTE addressing so it does not need to know the number of flash attached
	localparam	FAKE_ADDR_INDEX = (N_FLASH == 8) ? 2 :
											(N_FLASH == 4) ? 1 : 
											(N_FLASH == 2) ? 0 : -1;
	localparam	FAKE_END_ADDR_INDEX = (N_FLASH == 8) ? 2 :
													(N_FLASH == 4) ? 1 : 0;
	localparam	FAKE_EXTRA_BIT = (N_FLASH == 1) ? 1 : 0;
									
	// STATE machine
	localparam BURST_SAME 				= 4'b0000;	// 0
	localparam BURST_INIT 				= 4'b0001;	// 1
	localparam BURST_WAIT			 	= 4'b0010;	// 2
	localparam BURST_WRITE_ENABLE		= 4'b0011;	// 3
	localparam BURST_UPPER_ADDR		= 4'b0100;	// 4
	localparam BURST_RCR 				= 4'b0101;	// 5
	localparam BURST_WE 					= 4'b0110;	// 6
	localparam BURST_WRR 				= 4'b0111;	// 7
	localparam BURST_POLL 				= 4'b1000;	// 8
	localparam BURST_ADDR_OPCODE		= 4'b1001;	// 9
	localparam BURST_ADDR 				= 4'b1010;	// 10
	localparam BURST_ADDR_DUMMY 		= 4'b1011;	// 11
	localparam BURST_READ 				= 4'b1100;	// 12
	localparam BURST_READ_HIGH 		= 4'b1101;	// 13
	localparam BURST_NCS_HIGH			= 4'b1110;	// 14

	// Port Declaration

	// FPGA IOs
	input nreset;
	input clk;

	// QPFL IOs
	output	[N_FLASH-1:0] flash_sck;
	output	[N_FLASH-1:0] flash_ncs;
	output	[N_FLASH-1:0] flash_io0_out;
	input		[N_FLASH-1:0] flash_io0_in;
	output	[N_FLASH-1:0] flash_io1_out;
	input		[N_FLASH-1:0] flash_io1_in;
	output	[N_FLASH-1:0] flash_io2_out;
	input		[N_FLASH-1:0] flash_io2_in;
	output	[N_FLASH-1:0] flash_io3_out;
	input		[N_FLASH-1:0] flash_io3_in;
	output 	flash_highz_io0 = current_state == BURST_READ || current_state == BURST_READ_HIGH;
	output 	flash_highz_io1 = ~(current_state == BURST_ADDR || current_state == BURST_ADDR_DUMMY);
	output 	flash_highz_io2 = current_state == BURST_READ || current_state == BURST_READ_HIGH;
	output 	flash_highz_io3 = current_state == BURST_READ || current_state == BURST_READ_HIGH;

	// From Controller
	input	[FLASH_ADDR_WIDTH-1:0]addr_in;
	input	[FLASH_ADDR_WIDTH-1:0]stop_addr_in;
	input	addr_sload;
	input	addr_cnt_en;
	output	done;

	input		data_request;
	output	data_ready = data_ready_wire & ~data_auto_ignore;
	output	[DATA_WIDTH-1:0]data;

	output	flash_access_request;
	input	flash_access_granted;
	
	wire [FLASH_ADDR_WIDTH-FAKE_ADDR_INDEX-1:0] fake_addr_in = {addr_in[FLASH_ADDR_WIDTH-1:FAKE_END_ADDR_INDEX], {(FAKE_EXTRA_BIT){1'b0}}};
	wire [FLASH_ADDR_WIDTH-FAKE_ADDR_INDEX-1:0] fake_addr_stop = {stop_addr_in[FLASH_ADDR_WIDTH-1:FAKE_END_ADDR_INDEX], {(FAKE_EXTRA_BIT){1'b0}}};

	// out reg
	// Wire
	// Configuration sout
	wire upper_addr_io0_reg_sout;
	wire rcr_io0_reg_sout;
	wire we_io0_reg_sout;
	wire wrr_io0_reg_sout;
	wire poll_io0_reg_sout;
	wire addr_opcode_io0_reg_sout;
	wire [5:0]cfg_count_q;
						
	// Connection with outside world

	// change SCE on Failing edge
	assign flash_ncs = {(N_FLASH){flash_ncs_cfg}};
	assign flash_sck = {(N_FLASH){flash_sck_cfg | flash_read_sck}};

	reg flash_ncs_cfg;
	always @ (posedge clk) begin
		if (next_state == BURST_INIT || next_state == BURST_WAIT)
			flash_ncs_cfg = 1'b1;
		else if (current_state == BURST_NCS_HIGH && next_state == BURST_SAME)
			flash_ncs_cfg = 1'b1;
		else if (next_state == BURST_SAME || next_state == BURST_NCS_HIGH)
			flash_ncs_cfg = flash_ncs_cfg;
		else
			flash_ncs_cfg = 1'b0;
	end
							
	// CLOCK to QSPI_1

	reg  qpfl_io0_cfg;
	wire qpfl_io1_cfg;
	wire qpfl_io2_cfg;
	wire qpfl_io3_cfg;
	always @ (current_state, rcr_io0_reg_sout, we_io0_reg_sout, wrr_io0_reg_sout, poll_io0_reg_sout,
				addr_opcode_io0_reg_sout, upper_addr_io0_reg_sout, addr_io[0])
	begin
		if (current_state == BURST_RCR)
			qpfl_io0_cfg <= rcr_io0_reg_sout;
		else if (current_state == BURST_WE || current_state == BURST_WRITE_ENABLE)
			qpfl_io0_cfg <= we_io0_reg_sout;
		else if (current_state == BURST_WRR)
			qpfl_io0_cfg <= wrr_io0_reg_sout;
		else if (current_state == BURST_POLL)
			qpfl_io0_cfg <= poll_io0_reg_sout;
		else if (current_state == BURST_ADDR_OPCODE)
			qpfl_io0_cfg <= addr_opcode_io0_reg_sout;
		else if (current_state == BURST_ADDR)
			qpfl_io0_cfg <= addr_io[0];
		else if (current_state == BURST_UPPER_ADDR)
			qpfl_io0_cfg <= upper_addr_io0_reg_sout;
		else if (current_state == BURST_ADDR_DUMMY)
			qpfl_io0_cfg <= 1'b0;
		else
			qpfl_io0_cfg <= 1'b0;
	end
	
	assign qpfl_io1_cfg = current_state == BURST_ADDR ? addr_io[1] : 1'b0;
	assign qpfl_io2_cfg = current_state == BURST_ADDR ? addr_io[2] : current_state == BURST_ADDR_DUMMY ? 1'b0 : 1'b1;
	assign qpfl_io3_cfg = current_state == BURST_ADDR ? addr_io[3] : current_state == BURST_ADDR_DUMMY ? 1'b0 : 1'b1;

	assign flash_io0_out = {(N_FLASH){qpfl_io0_cfg}};
	assign flash_io1_out = {(N_FLASH){qpfl_io1_cfg}};
	assign flash_io2_out = {(N_FLASH){qpfl_io2_cfg}};
	assign flash_io3_out = {(N_FLASH){qpfl_io3_cfg}};
	
	lpm_shiftreg upper_addres_io0_reg (
		.clock(clk),
		.enable((next_state == BURST_UPPER_ADDR || (current_state == BURST_UPPER_ADDR && flash_sck_cfg))),
		.load(next_state == BURST_UPPER_ADDR),
		.data(8'b1011_0111),
		.shiftin(1'b0),
		.shiftout(upper_addr_io0_reg_sout)
	);
	defparam
	upper_addres_io0_reg.lmp_type = "LPM_SHIFTREG",
	upper_addres_io0_reg.lpm_width = 8,
	upper_addres_io0_reg.lpm_direction = "LEFT";

	lpm_shiftreg rcr_io0_reg (
		.clock(clk),
		.enable((next_state == BURST_RCR || (current_state == BURST_RCR && flash_sck_cfg))),
		.load(next_state == BURST_RCR),
		.data(rcr_data_in),
		.shiftin(1'b0),
		.shiftout(rcr_io0_reg_sout)
	);
	defparam
	rcr_io0_reg.lmp_type = "LPM_SHIFTREG",
	rcr_io0_reg.lpm_width = 8,
	rcr_io0_reg.lpm_direction = "LEFT";

	lpm_shiftreg we_io0_reg (
		.clock(clk),
		.enable((next_state == BURST_WE || (current_state == BURST_WE && flash_sck_cfg)) ||
					(next_state == BURST_WRITE_ENABLE || (current_state == BURST_WRITE_ENABLE && flash_sck_cfg))),
		.load(next_state == BURST_WE || next_state == BURST_WRITE_ENABLE),
		.data(8'b0000_0110),
		.shiftin(1'b0),
		.shiftout(we_io0_reg_sout)
	);
	defparam
	we_io0_reg.lmp_type = "LPM_SHIFTREG",
	we_io0_reg.lpm_width = 8,
	we_io0_reg.lpm_direction = "LEFT";
	
	wire wrr_done;
	generate
	if (FLASH_MFC == "SPANSION" || FLASH_MFC == "WINBOND")
	begin
		assign wrr_done = cfg_count_q[4] && cfg_count_q[3];
		lpm_shiftreg wrr_io0_reg (
			.clock(clk),
			.enable((next_state == BURST_WRR || (current_state == BURST_WRR && flash_sck_cfg))),
			.load(next_state == BURST_WRR),
			.data(24'b0000_0001_0000_0000_0000_0010),
			.shiftin(1'b0),
			.shiftout(wrr_io0_reg_sout)
		);
		defparam
		wrr_io0_reg.lmp_type = "LPM_SHIFTREG",
		wrr_io0_reg.lpm_width = 24,
		wrr_io0_reg.lpm_direction = "LEFT";
	end
	else begin
		assign wrr_done = cfg_count_q[4];
		lpm_shiftreg wrr_io0_reg (
			.clock(clk),
			.enable((next_state == BURST_WRR || (current_state == BURST_WRR && flash_sck_cfg))),
			.load(next_state == BURST_WRR),
			.data(wrr_qe_value),
			.shiftin(1'b0),
			.shiftout(wrr_io0_reg_sout)
		);
		defparam
		wrr_io0_reg.lmp_type = "LPM_SHIFTREG",
		wrr_io0_reg.lpm_width = 16,
		wrr_io0_reg.lpm_direction = "LEFT";
	end
	endgenerate

	lpm_shiftreg poll_io0_reg (
		.clock(clk),
		.enable((next_state == BURST_POLL || (current_state == BURST_POLL && flash_sck_cfg))),
		.load(next_state == BURST_POLL),
		.data(8'b0000_0101),
		.shiftin(1'b0),
		.shiftout(poll_io0_reg_sout)
	);
	defparam
	poll_io0_reg.lmp_type = "LPM_SHIFTREG",
	poll_io0_reg.lpm_width = 8,
	poll_io0_reg.lpm_direction = "LEFT";

	reg[CFG_ADDR_BIT-1:0] read_address;
	reg[3:0] addr_io;
	always @(posedge clk) begin
		if (addr_sload)
			read_address = {{(UNUSED_ADDR_WIDTH){1'b0}}, addr_in[FLASH_ADDR_WIDTH-1:REAL_ADDR_INDEX]}; 
	end
	
	wire read_addr_done;
	generate
	if (EXTRA_ADDR_BYTE == 1) begin
		assign read_addr_done = cfg_count_q[3];
		always @(posedge clk) begin
			if (flash_sck_cfg) begin
				if (next_state == BURST_ADDR)
					addr_io = read_address[31:28];
				else if (current_state == BURST_ADDR) begin
					if (cfg_count_q == 1)
						addr_io = read_address[27:24];
					else if (cfg_count_q == 2)
						addr_io = read_address[23:20];
					else if (cfg_count_q == 3)
						addr_io = read_address[19:16];
					else if (cfg_count_q == 4)
						addr_io = read_address[15:12];
					else if (cfg_count_q == 5)
						addr_io = read_address[11:8];
					else if (cfg_count_q == 6)
						addr_io = read_address[7:4];
					else if (cfg_count_q == 7)
						addr_io = read_address[3:0];
				end
			end
		end
	end
	else begin
		assign read_addr_done = cfg_count_q[2] & cfg_count_q[1];
		always @ (posedge clk) begin
			if (flash_sck_cfg) begin
				if (next_state == BURST_ADDR)
					addr_io = read_address[23:20];
				else if (current_state == BURST_ADDR) begin
					if (cfg_count_q == 1)
						addr_io = read_address[19:16];
					else if (cfg_count_q == 2)
						addr_io = read_address[15:12];
					else if (cfg_count_q == 3)
						addr_io = read_address[11:8];
					else if (cfg_count_q == 4)
						addr_io = read_address[7:4];
					else if (cfg_count_q == 5)
						addr_io = read_address[3:0];
				end
			end
		end
	end
	endgenerate
	
	lpm_shiftreg addr_opcode_io0_reg (
		.clock(clk),
		.enable((next_state == BURST_ADDR_OPCODE || (current_state == BURST_ADDR_OPCODE && flash_sck_cfg))),
		.load(next_state == BURST_ADDR_OPCODE),
		.data(QUAD_IO_READ_OPCODE),
		.shiftin(1'b0),
		.shiftout(addr_opcode_io0_reg_sout)
	);
	defparam
	addr_opcode_io0_reg.lmp_type = "LPM_SHIFTREG",
	addr_opcode_io0_reg.lpm_width = 8,
	addr_opcode_io0_reg.lpm_direction = "LEFT";

	wire sload_cfg_counter = (next_state == BURST_RCR || next_state == BURST_WE || next_state == BURST_WRR || 
										next_state == BURST_POLL || next_state == BURST_ADDR_OPCODE || next_state == BURST_ADDR ||
										next_state == BURST_ADDR_DUMMY || next_state == BURST_WAIT || next_state == BURST_NCS_HIGH ||
										next_state == BURST_WRITE_ENABLE || next_state == BURST_UPPER_ADDR);
	wire en_cfg_counter = ((current_state == BURST_RCR || current_state == BURST_WE || current_state == BURST_WRR || 
							current_state == BURST_POLL || current_state == BURST_ADDR_OPCODE || current_state == BURST_ADDR || 
							current_state == BURST_ADDR_DUMMY || current_state == BURST_WRITE_ENABLE || current_state == BURST_UPPER_ADDR) && flash_sck_cfg) || 
							current_state == BURST_WAIT || current_state == BURST_NCS_HIGH;
	// LPM counter
	lpm_counter cfg_counter (
		.clock(clk),
		.sload(sload_cfg_counter),
		.data(6'h01),
		.cnt_en(en_cfg_counter),
		.q(cfg_count_q)
	);
	defparam
	cfg_counter.lpm_type = "LPM_COUNTER",
	cfg_counter.lpm_direction= "UP",
	cfg_counter.lpm_width = 6;
								
	reg [FLASH_ADDR_WIDTH-FAKE_ADDR_INDEX-1:0] addr_counter_q;
	lpm_counter addr_counter
	(
		.clock(clk),
		.sload(addr_sload),
		.data(fake_addr_in),
		.cnt_en(addr_cnt_en & ~addr_latched),
		.q(addr_counter_q)
	);
	defparam addr_counter.lpm_width=FLASH_ADDR_WIDTH-FAKE_ADDR_INDEX;

	// Configuration
	reg [3:0] current_state;
	reg [3:0] next_state;

	reg rcr_result;
	always @ (posedge clk)
	begin
		if (current_state == BURST_RCR) begin
			if (cfg_count_q == 3 && flash_sck_cfg) begin
				rcr_result = 1'b0;
			end
			else if (cfg_count_q == rcr_qe_bit && flash_sck_cfg) begin
				rcr_result = (flash_io1_in == {(N_FLASH){1'b1}});
			end
		end
	end

	reg poll_result;
	always @ (posedge clk)
	begin
		if (current_state == BURST_POLL) begin
			if (cfg_count_q == 3 && flash_sck_cfg) begin
				poll_result = 1'b0;
			end
			else if (cfg_count_q == 16 && flash_sck_cfg) begin
				poll_result = (flash_io1_in == {(N_FLASH){1'b0}});
			end 
		end
	end

	reg addr_latched;
	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			addr_latched = 0;
		else if (addr_sload)
			addr_latched = 1;
		else if (next_state == BURST_ADDR)
			addr_latched = 0;
	end

	reg addr_done;
	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			addr_done = 0;
		else if (addr_sload)
			addr_done = 0;
		else if (addr_counter_q == fake_addr_stop)	
			addr_done = 1;
	end
	assign done = addr_done;

	reg request;
	reg granted;
	assign flash_access_request = request;
	always @ (posedge clk or negedge nreset)
	begin
		if (~nreset) begin
			granted = 0;
			request = 0;
		end
		else begin
			request = data_request;
			if (data_request && ~granted)
				granted = flash_access_granted;
			else if (~data_request)
				granted = 0;
		end
	end

	wire flash_read_sck;		// Running at PFL speed
	reg flash_sck_cfg;		// Running at Half of the PFL speed
	reg data_auto_ignore;
	wire flash_data_read = addr_cnt_en || (data_ready_wire & data_auto_ignore);
	wire data_ready_wire = current_state == BURST_READ_HIGH;

	always @ (posedge clk) begin
		if (current_state == BURST_INIT || current_state == BURST_WAIT ||
				current_state == BURST_READ || current_state == BURST_READ_HIGH || current_state == BURST_NCS_HIGH)
			flash_sck_cfg = 1'b0;
		else
			flash_sck_cfg = ~flash_sck_cfg;
	end
	assign flash_read_sck = current_state == BURST_READ_HIGH;
	
	reg unalign_data;
	always @ (posedge clk) begin
		if (addr_sload)
			unalign_data = addr_in[2];
	end
	generate
	if (N_FLASH == 8) begin // Need special case of N_FLASH == 8 for address that does not align to 64 bit
		always @ (posedge clk) begin
			if (next_state == BURST_ADDR)
				data_auto_ignore = unalign_data;
			else if (~data_request || data_ready_wire)
				data_auto_ignore = 1'b0;
			else
				data_auto_ignore = data_auto_ignore;
		end
	end
	else begin
		always @ (posedge clk) begin
			data_auto_ignore = 1'b0;
		end
	end
	endgenerate
	
	generate
	if (N_FLASH == 8) begin
		assign data = {flash_io0_in[7], flash_io1_in[7], flash_io2_in[7], flash_io3_in[7],
							flash_io0_in[6], flash_io1_in[6], flash_io2_in[6], flash_io3_in[6],
							flash_io0_in[5], flash_io1_in[5], flash_io2_in[5], flash_io3_in[5],
							flash_io0_in[4], flash_io1_in[4], flash_io2_in[4], flash_io3_in[4],
							flash_io0_in[3], flash_io1_in[3], flash_io2_in[3], flash_io3_in[3],
							flash_io0_in[2], flash_io1_in[2], flash_io2_in[2], flash_io3_in[2],
							flash_io0_in[1], flash_io1_in[1], flash_io2_in[1], flash_io3_in[1],
							flash_io0_in[0], flash_io1_in[0], flash_io2_in[0], flash_io3_in[0]};
	end
	else if (N_FLASH == 4) begin
		assign data = {flash_io0_in[3], flash_io1_in[3], flash_io2_in[3], flash_io3_in[3],
							flash_io0_in[2], flash_io1_in[2], flash_io2_in[2], flash_io3_in[2],
							flash_io0_in[1], flash_io1_in[1], flash_io2_in[1], flash_io3_in[1],
							flash_io0_in[0], flash_io1_in[0], flash_io2_in[0], flash_io3_in[0]};
	end
	else if (N_FLASH == 2) begin
		assign data = {flash_io0_in[1], flash_io1_in[1], flash_io2_in[1], flash_io3_in[1],
							flash_io0_in[0], flash_io1_in[0], flash_io2_in[0], flash_io3_in[0]};
	end
	else begin
		assign data = {flash_io0_in[0], flash_io1_in[0], flash_io2_in[0], flash_io3_in[0]};
	end
	endgenerate

	reg is_previous_upper_addr;
	reg is_previous_rcr;
	reg is_previous_we;
	reg is_previous_wrr;
	reg is_previous_write_enable;

	always @ (posedge clk) begin
		if (current_state == BURST_INIT || current_state == BURST_WAIT) begin
			is_previous_rcr = 1'b0;
			is_previous_we = 1'b0;
			is_previous_wrr = 1'b0;
			is_previous_upper_addr = 1'b0;
			is_previous_write_enable = 1'b0;
		end
		else if (current_state == BURST_WRITE_ENABLE)
			is_previous_write_enable = 1'b1;
		else if (current_state == BURST_UPPER_ADDR)
			is_previous_upper_addr = 1'b1;
		else if (current_state == BURST_RCR)
			is_previous_rcr = 1'b1;
		else if (current_state == BURST_WE)
			is_previous_we = 1'b1;
		else if (current_state == BURST_WRR)
			is_previous_wrr = 1'b1;
		else if (current_state == BURST_NCS_HIGH && next_state != BURST_SAME) begin
			is_previous_rcr = 1'b0;
			is_previous_we = 1'b0;
			is_previous_wrr = 1'b0;
			is_previous_upper_addr = 1'b0;
			is_previous_write_enable = 1'b0;
		end
	end

	always @ (nreset, current_state, cfg_count_q, rcr_result, poll_result, addr_latched,
				granted, data_request, is_previous_rcr, is_previous_we,
				is_previous_wrr, flash_sck_cfg, read_addr_done, wrr_done, is_previous_write_enable,
				is_previous_upper_addr, flash_data_read)
	begin
		if (~nreset)
			next_state = BURST_INIT;
		else
			case (current_state)
				BURST_INIT:			// 1
					next_state = BURST_WAIT;
				BURST_WAIT:			// 2
					if (cfg_count_q > 32) 
					begin
						if(addr_latched & granted & data_request) begin
							if (EXTRA_ADDR_BYTE == 1)
								next_state = BURST_WRITE_ENABLE;
							else begin
								if (FLASH_MFC == "ALTERA" || FLASH_MFC == "NUMONYX")
									next_state = BURST_ADDR_OPCODE;
								else
									next_state = BURST_RCR;
							end
						end
						else
							next_state = BURST_SAME;
					end
					else
						next_state = BURST_SAME;
				BURST_WRITE_ENABLE: // 3 - Numonyx/Micron required this before enable upper address
					if (cfg_count_q[3] && flash_sck_cfg)
						next_state = BURST_NCS_HIGH;
					else
						next_state = BURST_SAME;
				BURST_UPPER_ADDR: // 4 - 4 Bytes addressing
					if (cfg_count_q[3] && flash_sck_cfg)
						next_state = BURST_NCS_HIGH;
					else
						next_state = BURST_SAME;
				BURST_RCR:			// 5 - Read Config Reg to make sure device is in Quad Mode
					if (cfg_count_q[4] && flash_sck_cfg)
						next_state = BURST_NCS_HIGH;
					else
						next_state = BURST_SAME;
				BURST_WE:			// 6 - Write Enable in case we need to write Config Reg
					if (cfg_count_q[3] && flash_sck_cfg)
						next_state = BURST_NCS_HIGH;
					else
						next_state = BURST_SAME;
				BURST_WRR:			// 7 - Writing Config Reg
					if (wrr_done && flash_sck_cfg)
						next_state = BURST_NCS_HIGH;
					else 
						next_state = BURST_SAME;
				BURST_POLL:			// 8 - Polling
					if (cfg_count_q[4] && flash_sck_cfg)
						next_state = BURST_NCS_HIGH;
					else
						next_state = BURST_SAME;
				BURST_ADDR_OPCODE:	// 9 - Read Opcode
					if (cfg_count_q[3] && flash_sck_cfg)
						next_state = BURST_ADDR;
					else
						next_state = BURST_SAME; 
				BURST_ADDR:			// 10 - Address
					if (read_addr_done && flash_sck_cfg)
						next_state = BURST_ADDR_DUMMY;
					else
						next_state = BURST_SAME;
				BURST_ADDR_DUMMY:	// 11 - Dummy
					if (cfg_count_q[2] && cfg_count_q[1] && flash_sck_cfg)
						next_state = BURST_READ;
					else
						next_state = BURST_SAME;	
				BURST_READ:			// 12 - Data Ready
					if (addr_latched | ~granted)
						next_state = BURST_WAIT;
					else
						next_state = BURST_READ_HIGH;
				BURST_READ_HIGH:		// 10
					if (addr_latched | ~granted)
						next_state = BURST_WAIT;
					else if (flash_data_read)
						next_state = BURST_READ;
					else
						next_state = BURST_SAME;
				BURST_NCS_HIGH:		// 13
					if (cfg_count_q[4]) begin
						if (is_previous_rcr) begin
							if (rcr_result)
								next_state = BURST_ADDR_OPCODE;
							else
								next_state = BURST_WE;
						end
						else if (is_previous_we)
							next_state = BURST_WRR;
						else if (is_previous_wrr)
							next_state = BURST_POLL;
						else if (is_previous_write_enable)
							next_state = BURST_UPPER_ADDR;
						else if (is_previous_upper_addr) begin
							if (FLASH_MFC == "ALTERA" || FLASH_MFC == "NUMONYX")
								next_state = BURST_ADDR_OPCODE;
							else
								next_state = BURST_RCR;
						end
						else begin
							if (poll_result)
								next_state = BURST_RCR;
							else
								next_state = BURST_POLL;	
						end
					end
					else
						next_state = BURST_SAME;
				default:
					next_state = BURST_INIT;
			endcase
	end

	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			current_state = BURST_INIT;
		else
			if (next_state != BURST_SAME)
				current_state = next_state;
	end

endmodule
