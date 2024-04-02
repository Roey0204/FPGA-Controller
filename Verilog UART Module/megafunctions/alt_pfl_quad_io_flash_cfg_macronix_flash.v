////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_QUAD_IO_FLASH_CFG_MACRONIX_FLASH
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
// This module contains the PFL (Quad IO Flash -- Macronix) Configuration Flash block
//************************************************************

module alt_pfl_quad_io_flash_cfg_macronix_flash
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
	parameter FLASH_BURST_EXTRA_CYCLE = 1;
	parameter QSPI_DATA_DELAY = 0;
	parameter QSPI_DATA_DELAY_COUNT = 1;
	parameter QFLASH_FAST_SPEED = 0;
	parameter FLASH_STATIC_WAIT_WIDTH = 15;
	
	// local parameter
	localparam	REAL_ADDR_INDEX = (N_FLASH == 8) ? 3 :
											(N_FLASH == 4) ? 2 :
											(N_FLASH == 2) ? 1 : 0;
	localparam	REAL_ADDR_WIDTH = FLASH_ADDR_WIDTH - REAL_ADDR_INDEX;	
	localparam	UNUSED_ADDR_WIDTH = (EXTRA_ADDR_BYTE == 1) ? 32 - REAL_ADDR_WIDTH : 24 - REAL_ADDR_WIDTH;
	localparam	CFG_ADDR_BIT = (EXTRA_ADDR_BYTE == 1) ? 32 : 24;
	localparam 	DATA_WIDTH = N_FLASH * 4;
	localparam	QSPI_TRANSACTION_NUM = (QFLASH_FAST_SPEED == 0 && EXTRA_ADDR_BYTE == 1) ? 8 : 6;
	localparam	QSPI_TRANSACTION_WIDTH = 3;
	
	// Addressing is a bit tricky
	// Standardize the flow
	// Control Block always give BYTE addressing so it does not need to know the number of flash attached
	localparam	FAKE_ADDR_INDEX = (N_FLASH == 8) ? 2 :
											(N_FLASH == 4) ? 1 :
											(N_FLASH == 2) ? 0 : -1;
	localparam	FAKE_END_ADDR_INDEX = (N_FLASH == 8) ? 2 :
													(N_FLASH == 4) ? 1 : 0;
	localparam	FAKE_EXTRA_BIT = (N_FLASH == 1) ? 1 : 0;
	localparam	ADDR_CYCLE_COUNT = (EXTRA_ADDR_BYTE == 1)? 8 : 6;
	localparam  DUMMY_CYCLE_COUNT = (QFLASH_FAST_SPEED == 1)? 10 : 6;
	localparam 	ADDR_PLUS_DUMMY_CYCLE_COUNT = ADDR_CYCLE_COUNT + DUMMY_CYCLE_COUNT - 2;
	localparam	[4:0] ADDR_PLUS_DUMMY_DONE_CYCLE = ADDR_PLUS_DUMMY_CYCLE_COUNT[4:0];
	localparam 	PFL_IO_WIDTH = (QFLASH_FAST_SPEED == 1) ? 24 : 16;
	localparam	IO0_ZERO_COUNT = PFL_IO_WIDTH - ADDR_CYCLE_COUNT;
	// STATE machine
	reg [3:0] current_state /* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
	reg [3:0] next_state;
	localparam BURST_SAME 					= 4'd0;
	localparam BURST_INIT 					= 4'd1;
	localparam BURST_WAIT			 		= 4'd2;
	localparam BURST_SETUP					= 4'd3;
	localparam BURST_LOADING				= 4'd4;
	localparam BURST_TRANSACTION			= 4'd5;
	localparam BURST_CHECK_WAIT			= 4'd6;
	localparam BURST_STATIC_WAIT			= 4'd7;
	localparam BURST_CHECK_STOP			= 4'd8;
	localparam BURST_INC_TCOUNTER 		= 4'd9;
	localparam BURST_RESET					= 4'd10;
	localparam BURST_DUMMY					= 4'd11;
	localparam BURST_READ 					= 4'd12;
	localparam BURST_READ_HIGH				= 4'd13;

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
	output 	flash_highz_io1 = ~transaction_done;
	output 	flash_highz_io2 = current_state == BURST_READ || current_state == BURST_READ_HIGH;
	output 	flash_highz_io3 = current_state == BURST_READ || current_state == BURST_READ_HIGH;

	// From Controller
	input	[FLASH_ADDR_WIDTH-1:0] addr_in;
	input	[FLASH_ADDR_WIDTH-1:0] stop_addr_in;
	input	addr_sload;
	input	addr_cnt_en;
	output	done;
	reg		done;

	input		data_request;
	output	data_ready;
	output	[DATA_WIDTH-1:0]data;

	output	flash_access_request;
	input		flash_access_granted;
	
	// Defining constant
	// Control Bit
	// 1. NCS high or low
	// 2. Clock Needed?
	// 3. Shift-in
	// 4. Can Skip?
	// 5. Wait?
	// 6. 5 Bits Counter
	// 7. Stop? -->  Total of 11 bit
	wire [PFL_IO_WIDTH-1:0] pfl_io0 [0:QSPI_TRANSACTION_NUM-1];
	wire [ADDR_CYCLE_COUNT-1:0] pfl_io13[1:3];
	wire [10:0] pfl_control [0:QSPI_TRANSACTION_NUM-1];
	
	generate
	if (QFLASH_FAST_SPEED == 1 && EXTRA_ADDR_BYTE == 1) begin
		// Control
		assign pfl_control[0] = {1'b0, 5'd6, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0};	// Write Enable
		assign pfl_control[1] = {1'b0, 5'd31, 								1'b0, 1'b1, 1'b1, 1'b0, 1'b1};	// NCS HIGH
		assign pfl_control[2] = {1'b0, 5'd22, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0};	// Write Status Register
		assign pfl_control[3] = {1'b0, 5'd31, 								1'b1, 1'b1, 1'b1, 1'b0, 1'b1};	// NCS HIGH
		assign pfl_control[4] = {1'b0, 5'd6, 								1'b0, 1'b0, 1'b1, 1'b1, 1'b0};	// READ OPCODE
		assign pfl_control[5] = {1'b1, ADDR_PLUS_DUMMY_DONE_CYCLE, 	1'b0, 1'b0, 1'b0, 1'b1, 1'b0}; 	// ADDR
		// IO (Before Addr)
		// IO-0
		assign pfl_io0[0] = 24'b0000_0110_1111_1111_1111_1111; 	// Write Enable
		assign pfl_io0[1] = 24'b1111_1111_1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[2] = 24'b0000_0001_0100_0000_1110_0111; 	// Write Status Register
		assign pfl_io0[3] = 24'b1111_1111_1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[4] = 24'b1110_1011_1111_1111_1111_1111; 	// READ OPCODE
		// IO-Addr
		assign pfl_io0[5] = {read_address[28], read_address[24], read_address[20], read_address[16], read_address[12], read_address[8], read_address[4], read_address[0], {(IO0_ZERO_COUNT){1'b0}}};
		assign pfl_io13[1] = {read_address[29], read_address[25], read_address[21], read_address[17], read_address[13], read_address[9], read_address[5], read_address[1]};
		assign pfl_io13[2] = {read_address[30], read_address[26], read_address[22], read_address[18], read_address[14], read_address[10], read_address[6], read_address[2]};
		assign pfl_io13[3] = {read_address[31], read_address[27], read_address[23], read_address[19], read_address[15], read_address[11], read_address[7], read_address[3]};
	end
	else if (QFLASH_FAST_SPEED == 1 && EXTRA_ADDR_BYTE == 0) begin
		// Control
		assign pfl_control[0] = {1'b0, 5'd6, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0};	// Write Enable
		assign pfl_control[1] = {1'b0, 5'd31, 								1'b0, 1'b1, 1'b1, 1'b0, 1'b1};	// NCS HIGH
		assign pfl_control[2] = {1'b0, 5'd22, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0};	// Write Status Register
		assign pfl_control[3] = {1'b0, 5'd31, 								1'b1, 1'b1, 1'b1, 1'b0, 1'b1};	// NCS HIGH
		assign pfl_control[4] = {1'b0, 5'd6, 								1'b0, 1'b0, 1'b1, 1'b1, 1'b0};	// READ OPCODE
		assign pfl_control[5] = {1'b1, ADDR_PLUS_DUMMY_DONE_CYCLE,	1'b0, 1'b0, 1'b0, 1'b1, 1'b0};	// ADDR
		// IO (Before Addr)
		// IO-0
		assign pfl_io0[0] = 24'b0000_0110_1111_1111_1111_1111; 	// Write Enable
		assign pfl_io0[1] = 24'b1111_1111_1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[2] = 24'b0000_0001_0100_0000_1100_0111; 	// Write Status Register
		assign pfl_io0[3] = 24'b1111_1111_1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[4] = 24'b1110_1011_1111_1111_1111_1111; 	// READ OPCODE
		// IO-Addr
		assign pfl_io0[5] = {read_address[20], read_address[16], read_address[12], read_address[8], read_address[4], read_address[0], {(IO0_ZERO_COUNT){1'b0}}};
		assign pfl_io13[1] = {read_address[21], read_address[17], read_address[13], read_address[9], read_address[5], read_address[1]};
		assign pfl_io13[2] = {read_address[22], read_address[18], read_address[14], read_address[10], read_address[6], read_address[2]};
		assign pfl_io13[3] = {read_address[23], read_address[19], read_address[15], read_address[11], read_address[7], read_address[3]};
	end
	else if (QFLASH_FAST_SPEED == 0 && EXTRA_ADDR_BYTE == 1) begin
		// Control
		assign pfl_control[0] = {1'b0, 5'd6, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0}; // EN4B
		assign pfl_control[1] = {1'b0, 5'd31, 								1'b0, 1'b1, 1'b1, 1'b0, 1'b1}; // NCS HIGH
		assign pfl_control[2] = {1'b0, 5'd6, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0}; // Write Enable
		assign pfl_control[3] = {1'b0, 5'd31, 								1'b0, 1'b1, 1'b1, 1'b0, 1'b1}; // NCS HIGH
		assign pfl_control[4] = {1'b0, 5'd14, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0}; // Write Status Register
		assign pfl_control[5] = {1'b0, 5'd31, 								1'b1, 1'b1, 1'b1, 1'b0, 1'b1}; // NCS HIGH
		assign pfl_control[6] = {1'b0, 5'd6, 								1'b0, 1'b0, 1'b1, 1'b1, 1'b0}; // READ OPCODE
		assign pfl_control[7] = {1'b1, ADDR_PLUS_DUMMY_DONE_CYCLE, 	1'b0, 1'b0, 1'b0, 1'b1, 1'b0}; // ADDR
		// IO (Before Addr)
		// IO-0
		assign pfl_io0[0] = 16'b1011_0111_1111_1111; 	// EN4B
		assign pfl_io0[1] = 16'b1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[2] = 16'b0000_0110_1111_1111; 	// Write Enable
		assign pfl_io0[3] = 16'b1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[4] = 16'b0000_0001_0100_0000; 	// Write Status Register
		assign pfl_io0[5] = 16'b1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[6] = 16'b1110_1011_1111_1111; 	// READ OPCODE
		// IO-Addr
		assign pfl_io0[7] = {read_address[28], read_address[24], read_address[20], read_address[16], read_address[12], read_address[8], read_address[4], read_address[0], {(IO0_ZERO_COUNT){1'b0}}};
		assign pfl_io13[1] = {read_address[29], read_address[25], read_address[21], read_address[17], read_address[13], read_address[9], read_address[5], read_address[1]};
		assign pfl_io13[2] = {read_address[30], read_address[26], read_address[22], read_address[18], read_address[14], read_address[10], read_address[6], read_address[2]};
		assign pfl_io13[3] = {read_address[31], read_address[27], read_address[23], read_address[19], read_address[15], read_address[11], read_address[7], read_address[3]};
	end
	else if (QFLASH_FAST_SPEED == 0 && EXTRA_ADDR_BYTE == 0) begin
		// Control
		assign pfl_control[0] = {1'b0, 5'd6, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0};	// Write Enable
		assign pfl_control[1] = {1'b0, 5'd31, 								1'b0, 1'b1, 1'b1, 1'b0, 1'b1};	// NCS HIGH
		assign pfl_control[2] = {1'b0, 5'd14, 								1'b0, 1'b1, 1'b1, 1'b1, 1'b0};	// Write Status Register
		assign pfl_control[3] = {1'b0, 5'd31, 								1'b1, 1'b1, 1'b1, 1'b0, 1'b1};	// NCS HIGH
		assign pfl_control[4] = {1'b0, 5'd6, 								1'b0, 1'b0, 1'b1, 1'b1, 1'b0};	// READ OPCODE
		assign pfl_control[5] = {1'b1, ADDR_PLUS_DUMMY_DONE_CYCLE,	1'b0, 1'b0, 1'b0, 1'b1, 1'b0};	// ADDR
		// IO (Before Addr)
		// IO-0
		assign pfl_io0[0] = 16'b0000_0110_1111_1111; 	// Write Enable
		assign pfl_io0[1] = 16'b1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[2] = 16'b0000_0001_0100_0000; 	// Write Status Register
		assign pfl_io0[3] = 16'b1111_1111_1111_1111; 	// NCS HIGH
		assign pfl_io0[4] = 16'b1110_1011_1111_1111; 	// READ OPCODE
		// IO-Addr
		assign pfl_io0[5] = {read_address[20], read_address[16], read_address[12], read_address[8], read_address[4], read_address[0], {(IO0_ZERO_COUNT){1'b0}}};
		assign pfl_io13[1] = {read_address[21], read_address[17], read_address[13], read_address[9], read_address[5], read_address[1]};
		assign pfl_io13[2] = {read_address[22], read_address[18], read_address[14], read_address[10], read_address[6], read_address[2]};
		assign pfl_io13[3] = {read_address[23], read_address[19], read_address[15], read_address[11], read_address[7], read_address[3]};
	end
	endgenerate
	
	reg initialized;
	initial begin
		initialized = 1'b0;
	end
	
	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			initialized = 1'b0;
		else 
			if (current_state == BURST_STATIC_WAIT) begin
				initialized = 1'b1;
			end
	end
	
	wire [QSPI_TRANSACTION_WIDTH-1:0] tcount_q;
	lpm_counter tcounter (
		.clock(clk),
		.sclr(current_state == BURST_INIT || current_state == BURST_WAIT),
		.cnt_en(current_state == BURST_INC_TCOUNTER),
		.q(tcount_q)
	);
	defparam
		tcounter.lpm_type = "LPM_COUNTER",
		tcounter.lpm_direction= "UP",
		tcounter.lpm_width = QSPI_TRANSACTION_WIDTH;
	reg ncs;
	reg scking;
	reg shiftin;
	reg [4:0] counter_data;
	reg transaction_done;
	reg [PFL_IO_WIDTH-1:0] pfl_io;
	reg can_skip;
	reg static_wait;
	always @ (posedge clk) begin
		if (current_state == BURST_INIT || current_state == BURST_WAIT) begin
			ncs = 1'b1;
			scking = 1'b0;
			shiftin = 1'b1;
			counter_data = 5'd6;
			pfl_io = {(PFL_IO_WIDTH){1'b1}};
			can_skip = 1'b0;
			static_wait = 1'b0;
		end
		else if (current_state == BURST_SETUP) begin
			ncs = pfl_control[tcount_q][0] || (pfl_control[tcount_q][3] & initialized);
			scking = pfl_control[tcount_q][1];
			shiftin = pfl_control[tcount_q][2];
			can_skip = pfl_control[tcount_q][3] & initialized;
			static_wait = pfl_control[tcount_q][4];
			counter_data = pfl_control[tcount_q][9:5];
			pfl_io = pfl_io0[tcount_q];
		end
	end
	always @ (posedge clk) begin
		if (current_state == BURST_INIT || current_state == BURST_WAIT) begin
			transaction_done = 1'b0;
		end
		else if (current_state == BURST_SETUP) begin
			transaction_done = pfl_control[tcount_q][10];
		end
		else if (current_state == BURST_RESET) begin
			transaction_done = 1'b0;
		end
	end
	
	wire [FLASH_ADDR_WIDTH-FAKE_ADDR_INDEX-1:0] fake_addr_in = {addr_in[FLASH_ADDR_WIDTH-1:FAKE_END_ADDR_INDEX], {(FAKE_EXTRA_BIT){1'b0}}};
	wire [FLASH_ADDR_WIDTH-FAKE_ADDR_INDEX-1:0] fake_addr_stop = {stop_addr_in[FLASH_ADDR_WIDTH-1:FAKE_END_ADDR_INDEX], {(FAKE_EXTRA_BIT){1'b0}}};
	
	// Stage 1
	wire [DATA_WIDTH-1:0] flash_data_stage [-1:QSPI_DATA_DELAY_COUNT-1];
	wire [QSPI_DATA_DELAY_COUNT-1:-1] data_ready_stage;
	wire [QSPI_DATA_DELAY_COUNT-1:-1] data_read_stage;
	assign flash_data_stage[-1] = flash_data;
	assign data_ready_stage[-1] = data_ready_wire & ~data_auto_ignore;
	wire alt_pfl_data_read = data_read_stage[-1];
	genvar i;
	generate
		for (i = 0; i < QSPI_DATA_DELAY_COUNT; i = i + 1) begin : QSPI_DATA_LOOP
			alt_pfl_data alt_pfl_data1
			(
				.clk(clk),
				.data_request(data_request),
				.data_in(flash_data_stage[i-1]),
				.data_in_ready(data_ready_stage[i-1]),
				.data_in_read(data_read_stage[i-1]),
			
				.data_out(flash_data_stage[i]),
				.data_out_ready(data_ready_stage[i]),
				.data_out_read(data_read_stage[i])
			);
			defparam
				alt_pfl_data1.DATA_WIDTH = DATA_WIDTH,
				alt_pfl_data1.DELAY = QSPI_DATA_DELAY - ((i * QSPI_DATA_DELAY)/QSPI_DATA_DELAY_COUNT);
		end
	endgenerate
	// Stage 2
	alt_pfl_data alt_pfl_data2
	(
		.clk(clk),
		.data_request(data_request),
		.data_in(flash_data_stage[QSPI_DATA_DELAY_COUNT-1]),
		.data_in_ready(data_ready_stage[QSPI_DATA_DELAY_COUNT-1]),
		.data_in_read(data_read_stage[QSPI_DATA_DELAY_COUNT-1]),
	
		.data_out(data),
		.data_out_ready(data_ready),
		.data_out_read(addr_cnt_en)
	);
	defparam
		alt_pfl_data2.DATA_WIDTH = DATA_WIDTH;
	
	// out reg
	// Wire
	// Configuration sout
	wire [4:0] cfg_count_q;
						
	// Connection with outside world
	assign flash_ncs = {(N_FLASH){ncs}};
	assign flash_sck = {(N_FLASH){flash_sck_cfg | flash_read_sck}};

	reg flash_ncs_cfg;	
	assign flash_io0_out = {(N_FLASH){io_reg_sout[0]}};
	assign flash_io1_out = {(N_FLASH){io_reg_sout[1]}};
	assign flash_io2_out = {(N_FLASH){io_reg_sout[2]}};
	assign flash_io3_out = {(N_FLASH){io_reg_sout[3]}};
	
	wire enable_shift = scking? flash_sck_cfg : 1'b1;
	wire [3:0] io_reg_sout;
	lpm_shiftreg io_reg (
		.clock(clk),
		.enable((current_state == BURST_LOADING || (current_state == BURST_TRANSACTION && enable_shift))),
		.load(current_state == BURST_LOADING),
		.data(pfl_io),
		.shiftin(shiftin),
		.shiftout(io_reg_sout[0])
	);
	defparam
		io_reg.lmp_type = "LPM_SHIFTREG",
		io_reg.lpm_width = PFL_IO_WIDTH,
		io_reg.lpm_direction = "LEFT";
	generate
		for(i = 1; i < 4; i=i+1) begin: IO_LOOP
			lpm_shiftreg io_reg (
				.clock(clk),
				.enable((current_state == BURST_LOADING || (current_state == BURST_TRANSACTION && enable_shift))),
				.load(current_state == BURST_LOADING),
				.data(transaction_done? pfl_io13[i] : {(ADDR_CYCLE_COUNT){1'b1}}),
				.shiftin(transaction_done? 1'b0 : 1'b1),
				.shiftout(io_reg_sout[i])
			);
			defparam
				io_reg.lmp_type = "LPM_SHIFTREG",
				io_reg.lpm_width = ADDR_CYCLE_COUNT,
				io_reg.lpm_direction = "LEFT";
		end
	endgenerate
	
	reg[CFG_ADDR_BIT-1:0] read_address;
	always @(posedge clk) begin
		if (addr_sload)
			read_address = {{(UNUSED_ADDR_WIDTH){1'b0}}, addr_in[FLASH_ADDR_WIDTH-1:REAL_ADDR_INDEX]}; 
	end

	wire sload_cfg_counter = (current_state == BURST_LOADING);
	wire en_cfg_counter = (current_state == BURST_TRANSACTION)? enable_shift : 1'b0;
	// LPM counter
	lpm_counter cfg_counter (
		.clock(clk),
		.sload(sload_cfg_counter),
		.data(counter_data),
		.cnt_en(en_cfg_counter),
		.q(cfg_count_q)
	);
	defparam
	cfg_counter.lpm_type = "LPM_COUNTER",
	cfg_counter.lpm_direction= "DOWN",
	cfg_counter.lpm_width = 5;
	
	wire wait_done = static_wait_count_q[FLASH_STATIC_WAIT_WIDTH-1];
	wire [FLASH_STATIC_WAIT_WIDTH-1:0] static_wait_count_q;
	lpm_counter static_wait_counter (
		.clock(clk),
		.sclr(current_state == BURST_CHECK_WAIT),
		.cnt_en(current_state == BURST_STATIC_WAIT),
		.q(static_wait_count_q)
	);
	defparam
	static_wait_counter.lpm_type = "LPM_COUNTER",
	static_wait_counter.lpm_direction= "UP",
	static_wait_counter.lpm_width = FLASH_STATIC_WAIT_WIDTH;
	
	wire counter_done = counter_almost_done & enable_shift;
	wire counter_almost_done_wire = (cfg_count_q == 5'd0) & enable_shift;
	reg counter_almost_done;
	always @ (posedge clk) begin
		if (sload_cfg_counter)
			counter_almost_done = 1'b0;
		else if (counter_almost_done_wire)
			counter_almost_done = 1'b1;
	end
		
	reg [FLASH_ADDR_WIDTH-FAKE_ADDR_INDEX-1:0] addr_counter_q;
	lpm_counter addr_counter
	(
		.clock(clk),
		.sload(addr_sload),
		.data(fake_addr_in),
		.cnt_en(alt_pfl_data_read & ~addr_latched),
		.q(addr_counter_q)
	);
	defparam addr_counter.lpm_width=FLASH_ADDR_WIDTH-FAKE_ADDR_INDEX;

	reg addr_latched;
	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			addr_latched = 0;
		else if (addr_sload)
			addr_latched = 1;
		else if (current_state == BURST_RESET)
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
	always @ (posedge clk or negedge nreset) begin
		done = addr_done;
	end

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
	wire flash_data_read = alt_pfl_data_read || (data_ready_wire & data_auto_ignore);
	wire data_ready_wire;
	generate
		if (FLASH_BURST_EXTRA_CYCLE > 0)
			assign data_ready_wire = current_state == BURST_READ_HIGH;
		else
			assign data_ready_wire = current_state == BURST_READ;
	endgenerate
	always @ (posedge clk) begin
		if (current_state == BURST_TRANSACTION & scking)
			flash_sck_cfg = ~flash_sck_cfg;
		else
			flash_sck_cfg = 1'b0;
	end
	
	generate
	if (FLASH_BURST_EXTRA_CYCLE > 0) begin
		assign flash_read_sck = current_state == BURST_READ_HIGH;
	end
	else begin
		assign flash_read_sck = flash_data_read & ~clk;
	end
	endgenerate
	
	
	generate
	if (N_FLASH == 8) begin // Need special case of N_FLASH == 8 for address that does not align to 64 bit
		reg unalign_data;
		always @ (posedge clk) begin
			if (addr_sload)
				unalign_data = addr_in[2];
		end
		always @ (posedge clk) begin
			if (current_state == BURST_CHECK_STOP)
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
	
	wire [DATA_WIDTH-1:0] flash_data;
	generate
	if (N_FLASH == 8) begin
		assign flash_data = {flash_io0_in[7], flash_io1_in[7], flash_io2_in[7], flash_io3_in[7],
									flash_io0_in[6], flash_io1_in[6], flash_io2_in[6], flash_io3_in[6],
									flash_io0_in[5], flash_io1_in[5], flash_io2_in[5], flash_io3_in[5],
									flash_io0_in[4], flash_io1_in[4], flash_io2_in[4], flash_io3_in[4],
									flash_io0_in[3], flash_io1_in[3], flash_io2_in[3], flash_io3_in[3],
									flash_io0_in[2], flash_io1_in[2], flash_io2_in[2], flash_io3_in[2],
									flash_io0_in[1], flash_io1_in[1], flash_io2_in[1], flash_io3_in[1],
									flash_io0_in[0], flash_io1_in[0], flash_io2_in[0], flash_io3_in[0]};
	end
	else if (N_FLASH == 4) begin
		assign flash_data = {flash_io0_in[3], flash_io1_in[3], flash_io2_in[3], flash_io3_in[3],
									flash_io0_in[2], flash_io1_in[2], flash_io2_in[2], flash_io3_in[2],
									flash_io0_in[1], flash_io1_in[1], flash_io2_in[1], flash_io3_in[1],
									flash_io0_in[0], flash_io1_in[0], flash_io2_in[0], flash_io3_in[0]};
	end
	else if (N_FLASH == 2) begin
		assign flash_data = {flash_io0_in[1], flash_io1_in[1], flash_io2_in[1], flash_io3_in[1],
									flash_io0_in[0], flash_io1_in[0], flash_io2_in[0], flash_io3_in[0]};
	end
	else begin
		assign flash_data = {flash_io0_in[0], flash_io1_in[0], flash_io2_in[0], flash_io3_in[0]};
	end
	endgenerate

	always @ (nreset, current_state, addr_latched, counter_done,
					granted, data_request, transaction_done,
					flash_data_read, can_skip, static_wait, wait_done)
	begin
		case (current_state)
			BURST_INIT:				//
				next_state = BURST_WAIT;
			BURST_WAIT:				//
				if(addr_latched & granted & data_request)
					next_state = BURST_SETUP;
				else
					next_state = BURST_SAME;
			BURST_SETUP:			// Copy 
				next_state = BURST_LOADING;
			BURST_LOADING:			// LOAD
				if (can_skip)
					next_state = BURST_CHECK_STOP;
				else
					next_state = BURST_TRANSACTION;
			BURST_TRANSACTION:
				if (counter_done)
					next_state = BURST_CHECK_WAIT;
				else
					next_state = BURST_SAME;
			BURST_CHECK_WAIT:
				if (static_wait)
					next_state = BURST_STATIC_WAIT;
				else
					next_state = BURST_CHECK_STOP;
			BURST_STATIC_WAIT:
				if (wait_done)
					next_state = BURST_CHECK_STOP;
				else
					next_state = BURST_SAME;
			BURST_CHECK_STOP: 	// 
				if (transaction_done)
					next_state = BURST_RESET;
				else
					next_state = BURST_INC_TCOUNTER;
			BURST_INC_TCOUNTER:
				next_state = BURST_SETUP;
			BURST_RESET:
				next_state = BURST_DUMMY;
			BURST_DUMMY:
				next_state = BURST_READ;
			BURST_READ:				// Data Ready
				if (addr_latched | ~granted)
					next_state = BURST_WAIT;
				else if (FLASH_BURST_EXTRA_CYCLE > 0)
					next_state = BURST_READ_HIGH;
				else if (flash_data_read)
					next_state = BURST_READ;
				else
					next_state = BURST_SAME;
			BURST_READ_HIGH:		// 10
				if (addr_latched | ~granted)
					next_state = BURST_WAIT;
				else if (flash_data_read)
					next_state = BURST_READ;
				else
					next_state = BURST_SAME;
			default:
				next_state = BURST_INIT;
		endcase
	end

	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			current_state = BURST_INIT;
		else begin
			if (~data_request)
				current_state = BURST_INIT;
			else if (next_state != BURST_SAME)
				current_state = next_state;
			else
				current_state = current_state;
		end
	end

endmodule
