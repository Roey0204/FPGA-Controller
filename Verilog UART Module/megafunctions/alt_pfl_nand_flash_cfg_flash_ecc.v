////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_NAND_FLASH_CFG_FLASH_ECC
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
// This module contains the PFL configuration NAND flash reader block with ECC checking
//
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_nand_flash_cfg_flash_ecc (
	clk,
	nreset,
	
	// Flash pins
	flash_highz_io,
	flash_io_in,
	flash_io_out,
	flash_cle,
	flash_ale,
	flash_noe,
	flash_nwe,
	flash_nce,
	flash_rdy,

	// Control data pins
	data_request,
	data_ready,
	data,
	
	// Control address pins
	addr_in,
	stop_addr_in,
	addr_sload,
	addr_cnt_en,
	done,
	
	// Access control
	flash_access_request,
	flash_access_granted
);	

	// General parameter
	parameter	FLASH_ADDR_WIDTH 			= 26; 
	parameter	FLASH_DATA_WIDTH			= 8; 
	parameter 	FLASH_LOW_CYCLE			= ECC_CLK_DIVISOR-1;
	parameter	CLK_DIVISOR      			= 3;
	parameter	PAGE_CLK_DIVISOR 			= 200;
	parameter   NRB_ADDR                = 'h03EA0000;

	parameter	FLASH_ADDR_CYCLE 			= (FLASH_ADDR_WIDTH > 25) ? 4 : 3;
	parameter	FLASH_CMD_CYCLE 			= 1;
	parameter 	FLASH_DATA_CYCLE 			= 1; 
	parameter	FLASH_BBT_DATA_CYCLE		= 2;
	parameter	FLASH_DATA_PACKET_CYCLE = 128;
	
	localparam	BLOCK_ADDR_WIDTH			= (FLASH_DATA_WIDTH == 8) ? ((FLASH_ADDR_WIDTH > 25) ? 12 : 11) : 10;
	localparam	PAGE_ADDR_WIDTH			= (FLASH_DATA_WIDTH == 8) ? 5 : 6;
	localparam  COL_ADDR_WIDTH          = (FLASH_DATA_WIDTH == 8) ? 9 : 11;
	localparam	PAGE_COL_ADDR_WIDTH		= FLASH_ADDR_WIDTH-BLOCK_ADDR_WIDTH;
	localparam	RB_SIZE						= (FLASH_DATA_WIDTH == 8) ? 8'h57 : 8'h14;
	localparam 	ECC_CLK_DIVISOR			= (CLK_DIVISOR > 4) ? CLK_DIVISOR : 4;
	
	// State machine parameter
	parameter	NFLASH_SAME	 	       = 5'd0;
	parameter 	NFLASH_INIT		       = 5'd1;
	parameter	NFLASH_BBM_CMD	       = 5'd2;
	parameter	NFLASH_BBM_ADDR	    = 5'd3;
	parameter	NFLASH_BBM_CNFM_CMD	 = 5'd4;
	parameter 	NFLASH_BBM_WAIT	    = 5'd5;
	parameter	NFLASH_BBM_SPARE_DATA = 5'd6;
	parameter	NFLASH_LOAD_DATA_PACKET = 5'd7;
	parameter	NFLASH_ECC_VALIDATION = 5'd8;
	parameter	NFLASH_BBM_HEADER	    = 5'd9;
	parameter	NFLASH_BBM_HEADER_VERIFY  = 5'd10;
	parameter   NFLASH_BBT_DATA_STORE = 5'd11;
	parameter 	NFLASH_CMD 		       = 5'd12;
	parameter 	NFLASH_ADDR		       = 5'd13;
	parameter	NFLASH_CNFM_CMD	 	 = 5'd14;
	parameter 	NFLASH_WAIT		       = 5'd15;
	parameter	NFLASH_SPARE_DATA		 = 5'd16;
	parameter	NFLASH_DATA 	       = 5'd17;	
	parameter	NFLASH_BBT_DATA0 	    = 5'd18;
	parameter	NFLASH_TOTAL_BB_VERIFY = 5'd19;
	parameter	NFLASH_BBT_DATA	    = 5'd20;
	parameter	NFLASH_BBT_CMD 	    = 5'd21;
	parameter	NFLASH_BBT_ADDR	    = 5'd22;
	parameter	NFLASH_BBT_CNFM_CMD	 = 5'd23;
	parameter	NFLASH_BBT_WAIT	    = 5'd24;
	
	reg			[4:0] current_state /* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
	reg			[4:0] next_state;

	input		clk;
	input 	nreset;
	
	input 	[FLASH_DATA_WIDTH-1:0] flash_io_in;
	output	[FLASH_DATA_WIDTH-1:0] flash_io_out = flash_io_out_wire;
	output	flash_highz_io;
	output 	flash_cle;
	output 	flash_ale;
	output 	flash_noe;
	output 	flash_nwe;
	output 	flash_nce;
	input 	flash_rdy; 
	
	output	[FLASH_DATA_WIDTH-1:0] data;
	output	data_ready;
	input		data_request;
	
	input		[FLASH_ADDR_WIDTH-1:0] addr_in;
	input 	[FLASH_ADDR_WIDTH-1:0] stop_addr_in;
	input		addr_cnt_en;
	input 	addr_sload;
	output 	done;
	
	input		flash_access_granted;
	output	flash_access_request;
	
	// Flash access control
	reg		granted;
	reg		request;
	
	assign	flash_access_request = request;
	always @ (posedge clk or negedge nreset)
	begin
		request = data_request;
		if (~nreset)
			granted = 0;
		else if (data_request && ~granted)
			granted = flash_access_granted;
		else if (~data_request)
			granted = 0;
	end
	
	// Flash address done
	reg flash_addr_done;
	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			flash_addr_done = 0;
		else if (addr_sload)
			flash_addr_done = 0;
		else if (logical_addr_cnt_q == stop_addr_in)	
			flash_addr_done = 1;
		else
			flash_addr_done = 0;
	end
	assign done = flash_addr_done;
	
	wire 		wait_state = (current_state == NFLASH_WAIT || current_state == NFLASH_BBT_WAIT || current_state == NFLASH_BBM_WAIT);
	wire 		addr_state = (current_state == NFLASH_ADDR || current_state == NFLASH_BBM_ADDR || current_state == NFLASH_BBT_ADDR);
	wire		cmd_state = (current_state == NFLASH_CMD || current_state == NFLASH_BBM_CMD || current_state == NFLASH_BBT_CMD);
	wire 		cnfm_state = (current_state == NFLASH_BBM_CNFM_CMD || current_state == NFLASH_BBT_CNFM_CMD || current_state == NFLASH_CNFM_CMD);	

	wire 		wait_state_next = (next_state == NFLASH_WAIT || next_state == NFLASH_BBT_WAIT || next_state == NFLASH_BBM_WAIT);
	wire 		addr_state_next = (next_state == NFLASH_ADDR || next_state == NFLASH_BBM_ADDR || next_state == NFLASH_BBT_ADDR);
	wire		cmd_state_next = (next_state == NFLASH_CMD || next_state == NFLASH_BBM_CMD || next_state == NFLASH_BBT_CMD);
	
	wire 		data_state = (current_state == NFLASH_LOAD_DATA_PACKET || current_state == NFLASH_SPARE_DATA || current_state == NFLASH_BBM_SPARE_DATA);
	wire 		data_state_next = (next_state == NFLASH_LOAD_DATA_PACKET || next_state == NFLASH_SPARE_DATA || next_state == NFLASH_BBM_SPARE_DATA);
	wire 		packet_data_state = (current_state == NFLASH_DATA || current_state == NFLASH_BBT_DATA || current_state == NFLASH_BBT_DATA0 || current_state == NFLASH_BBM_HEADER);

//================================================
//	NAND flash control, command & address 
//================================================

	assign	flash_nce = ~granted;
	assign 	flash_ale = (addr_state || current_state == NFLASH_INIT) ? 1'b1 : 1'b0; 
	assign 	flash_cle = (cmd_state || cnfm_state || current_state == NFLASH_INIT) ? 1'b1 : 1'b0; 
	assign	flash_noe = (data_state) ? !(flash_clk_count < FLASH_LOW_CYCLE) : 1'b1;
	assign 	flash_nwe = ((cmd_state || addr_state || cnfm_state) && (next_state == NFLASH_SAME)) ? !(flash_clk_count < FLASH_LOW_CYCLE) : 1'b1;
	assign	flash_highz_io = (data_state || wait_state) ? 1'b1 : 1'b0;
	
	wire		[FLASH_DATA_WIDTH-1:0] flash_io_out_wire = (cmd_state || cnfm_state) ? flash_cmd_out : flash_addr_out;
	wire 		ecc_ram_ready = (flash_clk_count == ECC_CLK_DIVISOR - 1);
	
	// Physical data address
	wire 	[FLASH_ADDR_WIDTH-1:0] physical_addr = 
				(current_state == NFLASH_BBM_CMD || current_state == NFLASH_BBM_ADDR || session == 2'b01) ? 
				{rba_block_cnt_q[BLOCK_ADDR_WIDTH-1:0], {(PAGE_COL_ADDR_WIDTH){1'b0}}} :
				(current_state == NFLASH_BBT_CMD || current_state == NFLASH_BBT_ADDR || session == 2'b10) ? 
				{rba_block_cnt_q[BLOCK_ADDR_WIDTH-1:0], {(PAGE_ADDR_WIDTH){1'b0}}, bbt_byte_cnt_q[COL_ADDR_WIDTH-1:0]} : 
				{physical_blk_addr[BLOCK_ADDR_WIDTH-1:0], logical_addr_cnt_q[PAGE_COL_ADDR_WIDTH-1:0]};
				
	// Physical data packet & spare address
	wire 	[FLASH_ADDR_WIDTH-1:0] physical_spare_addr = 
					(current_state == NFLASH_BBM_CMD || current_state == NFLASH_BBM_ADDR) ? 
					{rba_block_cnt_q[BLOCK_ADDR_WIDTH-1:0], {(PAGE_COL_ADDR_WIDTH){1'b0}}} :
					{physical_blk_addr[BLOCK_ADDR_WIDTH-1:0], logical_addr_cnt_q[PAGE_COL_ADDR_WIDTH-1:COL_ADDR_WIDTH], {(COL_ADDR_WIDTH){1'b0}}};
	wire 	[FLASH_ADDR_WIDTH-1:0] physical_packet_addr = 				
					(current_state == NFLASH_BBM_CMD || current_state == NFLASH_BBM_ADDR || session == 2'b01) ? 
					{rba_block_cnt_q[BLOCK_ADDR_WIDTH-1:0], {(PAGE_COL_ADDR_WIDTH){1'b0}}} :
					(current_state == NFLASH_BBT_CMD || current_state == NFLASH_BBT_ADDR || session == 2'b10) ? 
					{rba_block_cnt_q[BLOCK_ADDR_WIDTH-1:0], {(PAGE_ADDR_WIDTH){1'b0}}, packet_start_addr(bbt_byte_cnt_q[COL_ADDR_WIDTH-1:0])} : 
					{physical_blk_addr[BLOCK_ADDR_WIDTH-1:0], logical_addr_cnt_q[PAGE_COL_ADDR_WIDTH-1:COL_ADDR_WIDTH], packet_start_addr(logical_addr_cnt_q[COL_ADDR_WIDTH-1:0])}; 

	wire	[FLASH_DATA_WIDTH-1:0] flash_cmd_out = 
				(FLASH_DATA_WIDTH == 8) ? 
				(spare_cmd ? 8'h50 : (physical_packet_addr[8] ? 8'h01 : 8'h00)) : 
				((cnfm_state) ? 8'h30 : 8'h00); 
				
	reg 	[FLASH_DATA_WIDTH-1:0] flash_addr_out;
	always @ (posedge clk) begin
		if (addr_state	&& flash_clk_count < FLASH_LOW_CYCLE) begin
			if (spare_cmd) begin
				if (FLASH_DATA_WIDTH == 8)
					flash_addr_out = (op_count == 0) ? physical_spare_addr[7:0] : 
										  (op_count == 1) ? physical_spare_addr[16:9] :
										  (op_count == 2) ? physical_spare_addr[24:17] : 
											(FLASH_ADDR_WIDTH > 25) ? physical_spare_addr[FLASH_ADDR_WIDTH-1:25] : {(8){1'bZ}}; 
				else
					flash_addr_out = (op_count == 0) ? {{(8){1'b0}}, physical_spare_addr[7:0]} : 
										  (op_count == 1) ? {{(13){1'b0}}, physical_spare_addr[10:8]} :
										  (op_count == 2) ? {{(8){1'b0}}, physical_spare_addr[18:11]} :
											(FLASH_ADDR_WIDTH > 25) ? physical_spare_addr[FLASH_ADDR_WIDTH-1:19] : {(8){1'bZ}}; 
			end
			else begin 
				if (FLASH_DATA_WIDTH == 8)
					flash_addr_out = (op_count == 0) ? physical_packet_addr[7:0] : 
										  (op_count == 1) ? physical_packet_addr[16:9] :
										  (op_count == 2) ? physical_packet_addr[24:17] : 
											(FLASH_ADDR_WIDTH > 25) ? physical_packet_addr[FLASH_ADDR_WIDTH-1:25] : {(8){1'bZ}}; 
				else 
					flash_addr_out = (op_count == 0) ? {{(8){1'b0}}, physical_packet_addr[7:0]} : 
										  (op_count == 1) ? {{(13){1'b0}}, physical_packet_addr[10:8]} :
										  (op_count == 2) ? {{(8){1'b0}}, physical_packet_addr[18:11]} :
											(FLASH_ADDR_WIDTH > 25) ? physical_packet_addr[FLASH_ADDR_WIDTH-1:19] : {(8){1'bZ}}; 	
			end
		end
	end
	
	// Control data
	wire 		[FLASH_DATA_WIDTH-1:0] flash_data_in = valid_data;
	assign	data_ready = data_ready_reg2 && ~addr_sload;
	reg data_ready_reg1;
	reg data_ready_reg2;
	always @(posedge clk) begin
		if(next_state == NFLASH_DATA || addr_sload)
			data_ready_reg1 = 1'b0;
		else begin
			if(current_state == NFLASH_DATA) begin
				if(addr_cnt_en)
					data_ready_reg1 = 1'b0;
				else if(~data_ready_reg1)
					data_ready_reg1 = 1'b1;
			end
			else
				data_ready_reg1 = 1'b0;
		end
	end	
	always @(posedge clk) begin
		if(next_state == NFLASH_DATA || addr_sload)
			data_ready_reg2 = 1'b0;
		else begin
			if(current_state == NFLASH_DATA) begin
				if(addr_cnt_en)
					data_ready_reg2 = 1'b0;
				else if(data_ready_reg1)
					data_ready_reg2 = 1'b1;
			end
			else
				data_ready_reg2 = 1'b0;
		end
	end	
	assign	data = flash_data_in; 
	
	// Page/Block address monitor
	wire	next_page;
	wire  next_block;
	wire 	next_packet;
	assign 	next_packet = (logical_addr_cnt_q[6:0] == 'h7F ||
									logical_addr_cnt_q[6:0] == 'hFF ||
									logical_addr_cnt_q[6:0] == 'h17F) && addr_cnt_en;
	assign 	next_page = (&logical_addr_cnt_q[COL_ADDR_WIDTH-1:0]) && addr_cnt_en;
	assign   next_block = (&logical_addr_cnt_q[PAGE_COL_ADDR_WIDTH-1:0]) && addr_cnt_en;
	
//================================================
// COUNTERS: GENERAL OPERATION & ADDRESS  
//================================================

	// Logical address counter
	wire	[FLASH_ADDR_WIDTH-1:0] logical_addr_cnt_q;
	lpm_counter addr_counter (
		.clock(clk),
		.cnt_en(addr_cnt_en),
		.sload(addr_sload),
		.data(addr_in),
		.q(logical_addr_cnt_q)
	);
	defparam 	addr_counter.LPM_WIDTH = FLASH_ADDR_WIDTH;
	
	// Flash clock counter
	wire 		[log2(ECC_CLK_DIVISOR)-1:0] flash_clk_count;
	wire 		flash_clk_clear = cmd_state_next || addr_state_next || wait_state_next || data_state_next || (next_state == NFLASH_BBM_HEADER) || (next_state == NFLASH_BBT_DATA) || (next_state == NFLASH_BBT_DATA0);
	wire 		counter_en = cmd_state || addr_state || wait_state || data_state || (current_state == NFLASH_BBM_HEADER) || (current_state == NFLASH_BBT_DATA) || (current_state == NFLASH_BBT_DATA0);
	lpm_counter flash_clk_counter (
		.clock(clk),
		.sclr(flash_clk_clear),
		.cnt_en(counter_en),
		.q(flash_clk_count)
	);
	defparam	flash_clk_counter.lpm_width = log2(ECC_CLK_DIVISOR);
	
	// Operation counter
	wire		[7:0] op_count;
	wire 		op_clear = (current_state != next_state) && (next_state != NFLASH_SAME);
	lpm_counter flash_op_counter (
		.clock(clk),
		.sclr(op_clear),
		.cnt_en(counter_en && (flash_clk_count == ECC_CLK_DIVISOR-1)),
		.q(op_count) 
	);
	defparam flash_op_counter.lpm_width = 8;
	
//================================================
// BAD BLOCK MANAGEMENT
//================================================
						
	wire  match_found = (current_state == NFLASH_BBT_DATA_STORE) && 
								(logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] == bbt_word0) &&
								header_found_reg;
	wire 	header_found = ((bbt_word0 == 'hA101) || (bbt_word0 == 'hA100)) ? 1'b1 : 1'b0; 
	reg 	header_found_reg;
	always @ (posedge clk)
	begin
		if(current_state == NFLASH_BBM_HEADER_VERIFY)
			header_found_reg = header_found;
	end
	
	reg 	[15:0] total_bad_block;
	reg 	[BLOCK_ADDR_WIDTH-1:0] physical_blk_addr;
	always @ (negedge nreset or posedge clk)
	begin
		if (~nreset) begin
			total_bad_block = 'hFFFF;
		end
		else if (current_state == NFLASH_TOTAL_BB_VERIFY)
			total_bad_block = bbt_word1;
		else if (current_state == NFLASH_BBT_DATA && ecc_ram_ready &&
					logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] == bbt_word0)
			physical_blk_addr = bbt_word1[BLOCK_ADDR_WIDTH-1:0];
		else if (current_state == NFLASH_BBT_DATA_STORE && 
					logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] == bbt_word0)
			physical_blk_addr = bbt_word1[BLOCK_ADDR_WIDTH-1:0];	
		else if (current_state == NFLASH_CMD || current_state == NFLASH_ADDR || match_found_reg)
			physical_blk_addr = (total_bad_block != 'h0000 && header_found_reg) ? physical_blk_addr : logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH];
		else if ((current_state == NFLASH_BBT_DATA && ecc_ram_ready) || current_state == NFLASH_BBT_DATA_STORE)
			physical_blk_addr = logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH];
	end
	
	reg match_found_reg;
	always @(negedge nreset or posedge clk) begin
		if (~nreset)
			match_found_reg = 1'b0;
		else begin
			if(next_block)
				match_found_reg = 1'b0;
			else if(!match_found_reg)
				match_found_reg = match_found;
		end
	end

	// BBT word capture
	reg [15:0] bbt_word0;
	reg [15:0] bbt_word1;
	always @ (posedge clk)
	begin
		if (~nreset) begin
			bbt_word0 = 'h0000;
			bbt_word1 = 'h0000;
		end
		else begin
			if (FLASH_DATA_WIDTH == 8) begin
				if (bbt_byte_cnt_q[0] == 0) begin
					if (bbt_byte_cnt_q[1] == 0) begin 
						bbt_word0[15:8] = (current_state == NFLASH_BBM_HEADER || current_state == NFLASH_BBT_DATA) ? 
												flash_data_in : bbt_word0[15:8];
					end 
					else begin 
						bbt_word1[15:8] = (current_state == NFLASH_BBT_DATA0 || current_state == NFLASH_BBT_DATA) ? 
												flash_data_in : bbt_word1[15:8];
					end
				end
				else begin 
					if (bbt_byte_cnt_q[1] == 0) begin
						bbt_word0[7:0] = (current_state == NFLASH_BBM_HEADER || current_state == NFLASH_BBT_DATA) ? 
												flash_data_in: bbt_word0[7:0];
					end 
					else begin 
						bbt_word1[7:0] = (current_state == NFLASH_BBT_DATA0 || current_state == NFLASH_BBT_DATA) ? 
												flash_data_in : bbt_word1[7:0];
					end
				end
			end
			else begin
				if (bbt_byte_cnt_q[0] == 0) begin
					bbt_word0 = flash_data_in; 
				end
				else begin 	
					bbt_word1 = flash_data_in;
				end
			end
		end
	end
	
//================================================
// COUNTERS: BAD BLOCK MANAGEMENT  
//================================================

	// Reserved block area counter
	wire	[BLOCK_ADDR_WIDTH-1:0] rba_block_cnt_q;
	wire 	[31:0] rba_start_addr = NRB_ADDR;
	wire 	[BLOCK_ADDR_WIDTH-1:0] rba_last_block_addr = rba_start_addr[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] + RB_SIZE;
	wire 	rba_counter_en = (current_state == NFLASH_BBM_HEADER && next_state == NFLASH_BBM_CMD) || 
									(current_state == NFLASH_ECC_VALIDATION && session == 2'b01 && (~valid && end_7cycle_state) && (repeat_ecc == 2'b11));
	lpm_counter rba_counter (
		.clock(clk),
		.cnt_en(rba_counter_en),
		.sload(current_state == NFLASH_INIT && next_state == NFLASH_BBM_CMD),
		.data(rba_last_block_addr),
		.q(rba_block_cnt_q)
	);
	defparam 	rba_counter.LPM_WIDTH = BLOCK_ADDR_WIDTH;
	defparam	rba_counter.LPM_DIRECTION = "DOWN";
	
	// Bad block table counter - Addressable up to 255 bad blocks in BBT
	wire	[COL_ADDR_WIDTH-1:0] bbt_byte_cnt_q;
	wire 	[COL_ADDR_WIDTH-1:0] stop_bbt_byte_cnt = {total_bad_block[6:0], 2'b11}; 
	wire 	bbt_cnt_en = ((current_state == NFLASH_BBT_DATA0) || (current_state == NFLASH_BBT_DATA) || (current_state == NFLASH_BBM_HEADER)) && ecc_ram_ready;
	lpm_counter bbt_counter (
		.clock(clk),
		.cnt_en(bbt_cnt_en),
		.sclr(current_state == NFLASH_INIT || next_state == NFLASH_BBM_CMD),
		.sload(addr_sload),
		.data(9'b0_0000_0100),
		.q(bbt_byte_cnt_q)
	);
	defparam 	bbt_counter.LPM_WIDTH = COL_ADDR_WIDTH;

//================================================
// ECC MANAGEMENT
//================================================
	
	// Read main/spare area for BBM
	wire spare_cmd = ((current_state == NFLASH_BBM_CMD || current_state == NFLASH_BBM_ADDR) && bbm_spare) 
							|| ((current_state == NFLASH_CMD || current_state == NFLASH_ADDR) && spare);
	
	reg bbm_spare;
	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			bbm_spare = 1;
		else if (current_state == NFLASH_BBM_SPARE_DATA)
			bbm_spare = 0;
		else if (current_state == NFLASH_INIT || next_state == NFLASH_BBM_CMD)
			bbm_spare = 1;
	end
	
	// Read main/spare area for data
	reg spare;
	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			spare = 1;
		else if (current_state == NFLASH_SPARE_DATA)
			spare = 0;
		else if (~spare)
			if (addr_sload || next_packet || next_page || next_block || next_state == NFLASH_CMD)
				spare = 1;
		else if (current_state == NFLASH_INIT)
			spare = 1;
	end
	
	// Select ECC session
	reg [1:0] session;
	always @ (posedge clk or negedge nreset) 
	begin
		if (~nreset)
			session = 2'b00;
		else if (current_state == NFLASH_BBM_CMD && ~bbm_spare)
			session = 2'b01;
		else if (current_state == NFLASH_BBT_CMD && ~bbm_spare)
			session = 2'b10;
		else if ((current_state == NFLASH_CMD && ~spare) || (current_state == NFLASH_ECC_VALIDATION && next_state == NFLASH_CMD))
			session = 2'b11;
		else if (session != 2'b00)
			session = session;
	end
	
	// Store BBM & data ECC
	reg [7:0] bbm_ecc [2:0]; 
	reg [7:0] data_ecc [2:0];
	always @ (posedge clk)
	begin
		if (current_state == NFLASH_BBM_SPARE_DATA) begin
			if (op_count == 2)
				bbm_ecc[0] = flash_io_in;
			else if (op_count == 3)
				bbm_ecc[1] = flash_io_in;
			else if (op_count == 4)
				bbm_ecc[2] = flash_io_in;
		end
		else if (current_state == NFLASH_SPARE_DATA) begin
			if (packet_start_addr(logical_addr_cnt_q[COL_ADDR_WIDTH-1:0]) == 'h00) begin
				if (op_count == 2)
					data_ecc[0] = flash_io_in;
				else if (op_count == 3)
					data_ecc[1] = flash_io_in;
				else if (op_count == 4)
					data_ecc[2] = flash_io_in;
			end
			else if (packet_start_addr(logical_addr_cnt_q[COL_ADDR_WIDTH-1:0]) == 'h80) begin
				if (op_count == 6)
					data_ecc[0] = flash_io_in;
				else if (op_count == 7)
					data_ecc[1] = flash_io_in;
				else if (op_count == 8)
					data_ecc[2] = flash_io_in;
			end
			else if (packet_start_addr(logical_addr_cnt_q[COL_ADDR_WIDTH-1:0]) == 'h100) begin
				if (op_count == 9)
					data_ecc[0] = flash_io_in;
				else if (op_count == 10)
					data_ecc[1] = flash_io_in;
				else if (op_count == 11)
					data_ecc[2] = flash_io_in;
			end
			else begin
				if (op_count == 12)
					data_ecc[0] = flash_io_in;
				else if (op_count == 13)
					data_ecc[1] = flash_io_in;
				else if (op_count == 14)
					data_ecc[2] = flash_io_in;
			end
		end
	end
	
//================================================
// COUNTERS: ECC MANAGEMENT 
//================================================

	// Packet address counter
	wire	[6:0] packet_addr_cnt_q;
	wire	packet_addr_cnt_en = ((current_state == NFLASH_BBT_DATA || current_state == NFLASH_BBT_DATA0 || current_state == NFLASH_BBM_HEADER) && ecc_ram_ready) || 
											(current_state == NFLASH_DATA && addr_cnt_en);
	wire 	packet_addr_sload = (next_state == NFLASH_DATA && current_state != NFLASH_DATA) || 
											(next_state == NFLASH_BBM_HEADER && current_state != NFLASH_BBM_HEADER);
	wire start_bb_pair = (current_state != NFLASH_BBT_DATA && next_state == NFLASH_BBT_DATA);
	wire write_data_rdy = (current_state == NFLASH_LOAD_DATA_PACKET && flash_noe);
	
	lpm_counter packet_addr_counter (
		.clock(clk),
		.cnt_en(packet_addr_cnt_en || write_data_rdy),
		.sload(packet_addr_sload || start_bb_pair),
		.data(start_bb_pair? bbt_byte_cnt_q[6:0] : physical_addr[6:0]),
		.sclr(next_state == NFLASH_LOAD_DATA_PACKET && current_state != NFLASH_LOAD_DATA_PACKET),
		.q(packet_addr_cnt_q)
	);
	defparam 	packet_addr_counter.LPM_WIDTH = 7;
	
	// Clock counter 
	wire 	[3:0] count_q;
	lpm_counter clk_counter (
		.clock(clk),
		.sclr(packet_addr_sload || next_state == NFLASH_ECC_VALIDATION),
		.cnt_en(packet_addr_cnt_en || current_state == NFLASH_ECC_VALIDATION),
		.q(count_q)
	);
	defparam	clk_counter.lpm_width = 4;
	
	reg [1:0] repeat_ecc;
	always @ (posedge clk)
	begin
		if (~nreset || 
			(current_state == NFLASH_ECC_VALIDATION && next_state == NFLASH_BBM_HEADER))
			repeat_ecc = 2'b00;
		else if (current_state == NFLASH_ECC_VALIDATION && next_state == NFLASH_BBM_CMD)
			repeat_ecc = repeat_ecc + 2'b01;
	end
	
	reg 	[7:0] ecc_in;
	always @ (posedge clk or negedge nreset)
	begin
		if (~nreset)
			ecc_in = 8'hFF;
		else if (current_state == NFLASH_LOAD_DATA_PACKET && next_state == NFLASH_SAME) begin
			if (packet_addr_cnt_q == 0) begin
				if (session == 2'b01 || session == 2'b10) begin
					if (physical_packet_addr[COL_ADDR_WIDTH-1:0] == 'h00)
						ecc_in = bbm_ecc[0];
					else 
						ecc_in = 8'hFF;
				end
				else if (session == 2'b11) 
					ecc_in = data_ecc[0];
				else 
					ecc_in = 8'hFF;
			end
			else if (packet_addr_cnt_q == 1) begin
				if (session == 2'b01 || session == 2'b10) begin
					if (physical_packet_addr[COL_ADDR_WIDTH-1:0] == 'h00)
						ecc_in = bbm_ecc[1];
					else 
						ecc_in = 8'hFF;
				end
				else if (session == 2'b11) 
					ecc_in = data_ecc[1];
				else 
					ecc_in = 8'hFF;
			end
			else if (packet_addr_cnt_q == 2) begin
				if (session == 2'b01 || session == 2'b10) begin
					if (physical_packet_addr[COL_ADDR_WIDTH-1:0] == 'h00)
						ecc_in = bbm_ecc[2];
					else
						ecc_in = 8'hFF;
				end
				else if (session == 2'b11) 
					ecc_in = data_ecc[2];
				else 
					ecc_in = 8'hFF;	
			end
			else 
				ecc_in = 8'hFF;
		end
	end

//================================================
// ECC MODULE INSTANTIATION
//================================================	
	
	wire busy;	
	wire [FLASH_DATA_WIDTH-1:0] valid_data;
	wire valid;
	
	alt_pfl_nand_flash_ecc_engine alt_pfl_nand_flash_ecc_engine (
		.clk(clk),
		.nreset(nreset && ~cmd_state),
		.read_req(packet_data_state),
		.read_done(flash_addr_done),
		.write_req(current_state == NFLASH_LOAD_DATA_PACKET),
		.write_data_rdy(write_data_rdy),
		.ecc_in(ecc_in),
		.data_in(flash_io_in),
		.data_out(valid_data),
		.addr_in(packet_addr_cnt_q),
		.busy(busy),
		.valid(valid)
	);
	
//================================================
// STATE MACHINE FLOW
//================================================

	wire	end_1cycle_state = (count_q == (FLASH_DATA_CYCLE-1));
	wire	end_2cycle_state = ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_BBT_DATA_CYCLE-1));
	wire	end_4cycle_state = ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_BBT_DATA_CYCLE*2-1));
	wire  end_7cycle_state = (count_q == 10); 
	wire	cont_state = ecc_ram_ready;
	
	always @ (nreset, current_state, op_count, data_request, addr_sload, granted, next_page, done, header_found, header_found_reg, total_bad_block, 
				 flash_clk_count, physical_addr, rba_start_addr, bbt_byte_cnt_q, stop_bbt_byte_cnt, logical_addr_cnt_q, bbt_word0, 
				 match_found, next_block, addr_cnt_en, session, bbm_spare, physical_packet_addr, end_2cycle_state,
				 rba_block_cnt_q, valid, cont_state, end_4cycle_state, end_7cycle_state, spare, next_packet, 
				 end_1cycle_state, bbt_word1, bbt_word0, packet_addr_cnt_q)	
	begin
		if (~nreset) begin
			next_state = NFLASH_INIT;
		end
		else begin 
			case (current_state)
				NFLASH_INIT: 
					if (data_request && granted) begin
						if (header_found_reg) begin
							if (total_bad_block =='h0000)
								next_state = NFLASH_CMD;
							else 
								next_state = NFLASH_BBT_CMD;
						end
						else 
							next_state = NFLASH_BBM_CMD;
					end
					else
						next_state = NFLASH_SAME;
				NFLASH_BBM_CMD:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_BBM_ADDR;
					else
						next_state = NFLASH_SAME;
				NFLASH_BBM_ADDR:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_ADDR_CYCLE-1))
						next_state = (FLASH_DATA_WIDTH == 8) ? NFLASH_BBM_WAIT : NFLASH_BBM_CNFM_CMD;
					else if(flash_clk_count == ECC_CLK_DIVISOR-1)
						next_state = NFLASH_BBM_ADDR;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBM_CNFM_CMD:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_BBM_WAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_BBM_WAIT:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == PAGE_CLK_DIVISOR-1)) begin
						if (bbm_spare)
							next_state = NFLASH_BBM_SPARE_DATA;
						else
							next_state = NFLASH_LOAD_DATA_PACKET;
					end
					else if(flash_clk_count == ECC_CLK_DIVISOR-1)
						next_state = NFLASH_BBM_WAIT;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBM_SPARE_DATA:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == 14))
						next_state = NFLASH_BBM_CMD;
					else if(flash_clk_count == ECC_CLK_DIVISOR-1)
						next_state = NFLASH_BBM_SPARE_DATA;
					else 
						next_state = NFLASH_SAME;
				NFLASH_LOAD_DATA_PACKET:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (packet_addr_cnt_q == FLASH_DATA_PACKET_CYCLE-1))
						next_state = NFLASH_ECC_VALIDATION;
					else if(flash_clk_count == ECC_CLK_DIVISOR-1) 
						next_state = NFLASH_LOAD_DATA_PACKET;
					else  
						next_state = NFLASH_SAME;
				NFLASH_ECC_VALIDATION:
					if (end_7cycle_state)
						if (valid) begin
							if (session == 2'b01) 
								next_state = NFLASH_BBM_HEADER;
							else if (session == 2'b10) 
								next_state = NFLASH_BBT_DATA;
							else if (session == 2'b11) 
								next_state = NFLASH_DATA;
							else
								next_state = NFLASH_INIT;
						end
						else begin
							if (session == 2'b01) 
								if (rba_block_cnt_q != rba_start_addr[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH])
									next_state = NFLASH_BBM_CMD; 	
								else 
									next_state = NFLASH_CMD;
							else if (session == 2'b10) 
								next_state = NFLASH_BBT_CMD;
							else if (session == 2'b11) 
								next_state = NFLASH_CMD;
							else
								next_state = NFLASH_INIT;
						end
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBM_HEADER:
					if (end_2cycle_state)
						next_state = NFLASH_BBM_HEADER_VERIFY;
					else if (cont_state)
						next_state = NFLASH_BBM_HEADER;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBM_HEADER_VERIFY:
					if (header_found)
						next_state = NFLASH_BBT_DATA0;
					else if (rba_block_cnt_q != rba_start_addr[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH]) 
						next_state = NFLASH_BBM_CMD;
					else
						next_state = NFLASH_CMD;
				NFLASH_BBT_DATA0:
					if (end_2cycle_state)
						next_state = NFLASH_TOTAL_BB_VERIFY;
					else if(cont_state) 
						next_state = NFLASH_BBT_DATA0;
					else 
						next_state = NFLASH_SAME;
				NFLASH_TOTAL_BB_VERIFY:
					if (bbt_word1 == 'h0000)
						next_state = NFLASH_CMD;
					else
						next_state = NFLASH_BBT_DATA;
				NFLASH_BBT_DATA:  
					if(bbt_byte_cnt_q > stop_bbt_byte_cnt)
						next_state = NFLASH_CMD;
					else if (end_4cycle_state) begin
						if (logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] < bbt_word0)
							next_state = NFLASH_CMD;
						else
							next_state = NFLASH_BBT_DATA;
						end
					else if(cont_state)
						next_state = NFLASH_BBT_DATA;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBT_DATA_STORE: 
					if (match_found)
						next_state = NFLASH_CMD;
					else if (logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] < bbt_word0)
						next_state = NFLASH_CMD;
					else 
						next_state = NFLASH_BBT_CMD;
				NFLASH_CMD:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_ADDR;
					else
						next_state = NFLASH_SAME;
				NFLASH_ADDR:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_ADDR_CYCLE-1))
						next_state = (FLASH_DATA_WIDTH == 8) ? NFLASH_WAIT : NFLASH_CNFM_CMD;
					else if(flash_clk_count == ECC_CLK_DIVISOR-1)
						next_state = NFLASH_ADDR;
					else 
						next_state = NFLASH_SAME;
				NFLASH_CNFM_CMD: 
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_WAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_WAIT: 	
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == PAGE_CLK_DIVISOR-1)) begin
						if (spare)
							next_state = NFLASH_SPARE_DATA;
						else 
							next_state = NFLASH_LOAD_DATA_PACKET;
					end
					else if(flash_clk_count == ECC_CLK_DIVISOR-1)
						next_state = NFLASH_WAIT;
					else 
						next_state = NFLASH_SAME;
				NFLASH_SPARE_DATA:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == 14))
						next_state = NFLASH_CMD;
					else if(flash_clk_count == ECC_CLK_DIVISOR-1)
						next_state = NFLASH_SPARE_DATA;
					else 
						next_state = NFLASH_SAME;	
				NFLASH_DATA:
					if (addr_sload)
						if (total_bad_block == 'h0000 || !header_found_reg)
							next_state = NFLASH_CMD;
						else
							next_state = NFLASH_BBT_CMD;
					else if (next_block)
						if (total_bad_block == 'h0000 || !header_found_reg)
							next_state = NFLASH_CMD;
						else if (bbt_byte_cnt_q > 9'b0_0000_0111)
							next_state = NFLASH_BBT_DATA_STORE;
						else
							next_state = NFLASH_BBT_CMD;
					else if (next_packet && !next_page)
							next_state = NFLASH_CMD; 
					else if (next_page)
						next_state = NFLASH_CMD;
					else if (end_1cycle_state) 
						if (done)
							next_state = NFLASH_INIT; 
						else if (addr_cnt_en)
							next_state = NFLASH_DATA;
						else 
							next_state = NFLASH_SAME;
					else 	
						next_state = NFLASH_SAME;
				NFLASH_BBT_CMD: 
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_BBT_ADDR;
					else
						next_state = NFLASH_SAME;
				NFLASH_BBT_ADDR:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_ADDR_CYCLE-1)) 
						next_state = (FLASH_DATA_WIDTH == 8) ? NFLASH_BBT_WAIT : NFLASH_BBT_CNFM_CMD;
					else if(flash_clk_count == ECC_CLK_DIVISOR-1)
						next_state = NFLASH_BBT_ADDR;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBT_CNFM_CMD:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_BBT_WAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_BBT_WAIT:
					if ((flash_clk_count == ECC_CLK_DIVISOR-1) && (op_count == PAGE_CLK_DIVISOR-1))
						next_state = NFLASH_LOAD_DATA_PACKET;
					else if(flash_clk_count == ECC_CLK_DIVISOR-1)
						next_state = NFLASH_BBT_WAIT;
					else 
						next_state = NFLASH_SAME;
				default:
					next_state = NFLASH_INIT;
			endcase
		end	
	end
	
	initial begin
		current_state = NFLASH_INIT;
	end

	always @(negedge nreset or posedge clk)
	begin
		if(~nreset) begin
			current_state = NFLASH_INIT;
		end
		else begin
			if (next_state != NFLASH_SAME) begin
				current_state = next_state;
			end
		end
	end
	
//================================================
// FUNCTIONS
//================================================
	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
					value = value >> 1;
		end
	endfunction
				
	function [COL_ADDR_WIDTH-1:0] packet_start_addr;
		input [COL_ADDR_WIDTH-1:0] addr;
		begin
			packet_start_addr = (addr[COL_ADDR_WIDTH-1:0] >= 9'b1_1000_0000) ? 9'b1_1000_0000 :
										(addr[COL_ADDR_WIDTH-1:0] >= 9'b1_0000_0000) ? 9'b1_0000_0000 : 
										(addr[COL_ADDR_WIDTH-1:0] >= 9'b0_1000_0000) ? 9'b0_1000_0000 : 9'b0_0000_0000;
		end
	endfunction
	
endmodule
