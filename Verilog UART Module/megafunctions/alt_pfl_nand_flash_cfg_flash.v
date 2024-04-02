////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_NAND_FLASH_CFG_FLASH
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
// This module contains the PFL configuration NAND flash reader block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_nand_flash_cfg_flash (
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
	parameter 	FLASH_LOW_CYCLE			= CLK_DIVISOR-1;
	parameter	CLK_DIVISOR      			= 3;
	parameter	PAGE_CLK_DIVISOR 			= 200;
	parameter   NRB_ADDR                = 'h03EA0000;
	parameter	FLASH_MFC					= "NUMONYX";
	parameter	FLASH_ECC_CHECKBOX 		= 0;
	parameter 	US_UNIT_COUNTER			= 16;

	parameter	FLASH_ADDR_CYCLE 			= (FLASH_ADDR_WIDTH > 25) ? 4 : 3;
	parameter	FLASH_CMD_CYCLE 			= 1;
	parameter 	FLASH_DATA_CYCLE 			= 1; 
	parameter	FLASH_BBT_DATA_CYCLE		= 2;
	parameter	FLASH_WAIT_CYCLE			= (FLASH_ECC_CHECKBOX == 1) ? 2*PAGE_CLK_DIVISOR : PAGE_CLK_DIVISOR;
	
	localparam	MT29_BLOCK_ADDR_WIDTH	= 10;
	localparam	MT29_PAGE_ADDR_WIDTH		= 6;
	localparam  MT29_COL_ADDR_WIDTH 		= (FLASH_DATA_WIDTH == 8) ? 11 : 10;
	
	localparam	GENERIC_BLOCK_ADDR_WIDTH	= ((FLASH_ADDR_WIDTH > 25) ? 12 : 11);
	localparam	GENERIC_PAGE_ADDR_WIDTH		= 5;
	localparam  GENERIC_COL_ADDR_WIDTH 		= 9;
	
	localparam	BLOCK_ADDR_WIDTH			= (FLASH_MFC == "MICRON") ? MT29_BLOCK_ADDR_WIDTH : GENERIC_BLOCK_ADDR_WIDTH;
	localparam	PAGE_ADDR_WIDTH			= (FLASH_MFC == "MICRON") ? MT29_PAGE_ADDR_WIDTH : GENERIC_PAGE_ADDR_WIDTH;
	localparam  COL_ADDR_WIDTH          = (FLASH_MFC == "MICRON") ? MT29_COL_ADDR_WIDTH : GENERIC_COL_ADDR_WIDTH; 
	localparam	PAGE_COL_ADDR_WIDTH		= FLASH_ADDR_WIDTH-BLOCK_ADDR_WIDTH;
	localparam	RB_SIZE						= (FLASH_MFC == "MICRON") ? 8'h14 : 8'h57;
	
	// State machine parameter
	parameter	NFLASH_SAME	 	       = 5'd0;
	parameter	NFLASH_RAMP_WAIT		 = 5'd19;
	parameter 	NFLASH_RESET_CMD 		 = 5'd20;
	parameter	NFLASH_RESET_WAIT	    = 5'd21;
	parameter	NFLASH_FEAT_CMD 		 = 5'd22;
	parameter	NFLASH_FEAT_ADDR	    = 5'd23;
	parameter	NFLASH_FEAT_WAIT	    = 5'd24;
	parameter 	NFLASH_FEAT_DATA		 = 5'd25;
	parameter 	NFLASH_FEAT_PREWAIT 	 = 5'd26;
	parameter 	NFLASH_STATUS_CMD 	 = 5'd27;
	parameter	NFLASH_STATUS_WAIT	 = 5'd28;
	parameter	NFLASH_STATUS_DATA	 = 5'd29;
	parameter	NFLASH_READ_CMD	 	 = 5'd30;
	parameter 	NFLASH_INIT		       = 5'd1;
	parameter	NFLASH_BBM_CMD	       = 5'd2;
	parameter	NFLASH_BBM_ADDR	    = 5'd3;
	parameter	NFLASH_BBM_CNFM_CMD	 = 5'd4;
	parameter	NFLASH_BBM_HEADER	    = 5'd6;
	parameter	NFLASH_BBM_HEADER_VERIFY = 5'd7;
	parameter   NFLASH_BBT_DATA_STORE = 5'd8;
	parameter 	NFLASH_CMD 		       = 5'd9;
	parameter 	NFLASH_ADDR		       = 5'd10;
	parameter	NFLASH_CNFM_CMD	 	 = 5'd11;
	parameter 	NFLASH_WAIT		       = 5'd12;
	parameter	NFLASH_DATA 	       = 5'd13;	
	parameter	NFLASH_BBT_DATA0 	    = 5'd14;
	parameter	NFLASH_BBT_DATA	    = 5'd15;
	parameter	NFLASH_BBT_CMD 	    = 5'd16;
	parameter	NFLASH_BBT_ADDR	    = 5'd17;
	parameter	NFLASH_BBT_CNFM_CMD	 = 5'd18;

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
	
	wire 		addr_state = (current_state == NFLASH_ADDR || current_state == NFLASH_BBM_ADDR || current_state == NFLASH_BBT_ADDR || current_state == NFLASH_FEAT_ADDR);
	wire 		data_state = (current_state == NFLASH_DATA || current_state == NFLASH_BBT_DATA || current_state == NFLASH_BBT_DATA0 || current_state == NFLASH_BBM_HEADER || current_state == NFLASH_STATUS_DATA);
	wire		cmd_state = (current_state == NFLASH_CMD || current_state == NFLASH_BBM_CMD || current_state == NFLASH_BBT_CMD || current_state == NFLASH_RESET_CMD || current_state == NFLASH_FEAT_CMD || current_state == NFLASH_STATUS_CMD || current_state == NFLASH_READ_CMD);
	wire 		cnfm_state = (current_state == NFLASH_BBM_CNFM_CMD || current_state == NFLASH_BBT_CNFM_CMD || current_state == NFLASH_CNFM_CMD);
	wire 		wait_state = (current_state == NFLASH_WAIT || current_state == NFLASH_RAMP_WAIT || current_state == NFLASH_RESET_WAIT || current_state == NFLASH_FEAT_WAIT || current_state == NFLASH_FEAT_PREWAIT || current_state == NFLASH_STATUS_WAIT);
	wire 		wdata_state = (current_state == NFLASH_FEAT_DATA);
	
	//Flash IOs
	assign	flash_nce = ~granted;
	assign 	flash_ale = (addr_state || current_state == NFLASH_INIT) ? 1'b1 : 1'b0; 
	assign 	flash_cle = (cmd_state || cnfm_state || current_state == NFLASH_INIT) ? 1'b1 : 1'b0; 
	assign	flash_noe = (data_state) ? !(flash_clk_count < FLASH_LOW_CYCLE) : 1'b1;
	assign 	flash_nwe = ((cmd_state || addr_state || cnfm_state || wdata_state) && (next_state == NFLASH_SAME)) ? !(flash_clk_count < FLASH_LOW_CYCLE) : 1'b1;
	assign	flash_highz_io = (data_state || current_state == NFLASH_WAIT) ? 1'b1 : 1'b0;
	wire		[FLASH_DATA_WIDTH-1:0] flash_io_out_wire = (cmd_state || cnfm_state) ? flash_cmd_out : 
																		 (wdata_state) ? flash_data_out : 
																			flash_addr_out;
	
	// Address selection
	wire 	[FLASH_ADDR_WIDTH-1:0] physical_addr = (current_state == NFLASH_BBM_CMD || current_state == NFLASH_BBM_ADDR) ? {rba_block_cnt_q[BLOCK_ADDR_WIDTH-1:0], {(PAGE_COL_ADDR_WIDTH){1'b0}}} :
													(current_state == NFLASH_BBT_CMD || current_state == NFLASH_BBT_ADDR) ? {rba_block_cnt_q[BLOCK_ADDR_WIDTH-1:0], {(PAGE_ADDR_WIDTH){1'b0}}, bbt_byte_cnt_q[COL_ADDR_WIDTH-1:0]} : 
													{physical_blk_addr[BLOCK_ADDR_WIDTH-1:0], logical_addr_cnt_q[PAGE_COL_ADDR_WIDTH-1:0]};
	wire	[FLASH_DATA_WIDTH-1:0] flash_cmd_out = (current_state == NFLASH_RESET_CMD) ? 8'hFF : 
																	(FLASH_MFC != "MICRON") ? ((physical_addr[8]) ? 8'h01 : 8'h00) : 
																	(current_state == NFLASH_FEAT_CMD) ? 8'hEF :
																	(current_state == NFLASH_STATUS_CMD) ? 8'h70 :
																	(current_state == NFLASH_READ_CMD) ? 8'h00 : 
																	(cnfm_state) ? 8'h30 : 8'h00; 
	reg 	[FLASH_DATA_WIDTH-1:0] flash_addr_out;
	always @ (posedge clk)
	begin
		if (addr_state	&& flash_clk_count < FLASH_LOW_CYCLE)
				if (FLASH_MFC == "MICRON") begin
					if (FLASH_DATA_WIDTH == 8)
						flash_addr_out = (op_count == 0) ? ((current_state == NFLASH_FEAT_ADDR) ? 8'h90 : physical_addr[7:0]) : 
												(op_count == 1) ? {{(5){1'b0}}, physical_addr[10:8]} : 
												(op_count == 2) ? physical_addr[18:11] : 
												 physical_addr[26:19];
					else
						flash_addr_out = (op_count == 0) ? ((current_state == NFLASH_FEAT_ADDR) ? 16'h0090 : {{(8){1'b0}}, physical_addr[7:0]}) : 
												(op_count == 1) ? {{(14){1'b0}}, physical_addr[9:8]} : 
												(op_count == 2) ? {{(8){1'b0}}, physical_addr[17:10]} : 
												 physical_addr[25:18];
				end
				else
					flash_addr_out = (op_count == 0) ? physical_addr[7:0] : 
												(op_count == 1) ? physical_addr[16:9] : 
												(op_count == 2) ? physical_addr[24:17] : 
												(FLASH_ADDR_WIDTH > 25) ? physical_addr[FLASH_ADDR_WIDTH-1:25] : {(8){1'bZ}};
	end
	
	reg 	[FLASH_DATA_WIDTH-1:0] flash_data_out;
	always @ (posedge clk)
	begin
		if (wdata_state && flash_clk_count < FLASH_LOW_CYCLE)
			if (FLASH_ECC_CHECKBOX == 1)
				flash_data_out = (op_count == 0) ? {{(FLASH_DATA_WIDTH-4){1'b0}},4'b1000} : {(FLASH_DATA_WIDTH){1'b0}};
			else
				flash_data_out = {(FLASH_DATA_WIDTH){1'b0}};
	end
												
	// BBM_Header checking, BBM DATA0 keeping, BBT_DATA reading & replacement
	wire  match_found = (current_state == NFLASH_BBT_DATA_STORE) && 
								(logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] == bbt_word0) &&
								header_found_reg;

	wire 	header_found = (bbt_word0 == 'hA101) || (bbt_word0 == 'hA100);
	reg 	header_found_reg;
	reg 	[15:0] total_bad_block;
	reg 	[BLOCK_ADDR_WIDTH-1:0] physical_blk_addr;
	
	always @ (negedge nreset or posedge clk)
	begin
		if (~nreset) begin
			header_found_reg = 1'b0;
			total_bad_block = 'hFFFF;
		end
		else if (current_state == NFLASH_BBM_HEADER && flash_noe)
			header_found_reg = header_found; 
		else if (current_state == NFLASH_BBT_DATA0)
			total_bad_block = bbt_word1;
	end
	
	always @ (posedge clk) begin
		if(total_bad_block != 'h0000 && header_found_reg) begin
			if(current_state == NFLASH_CMD || current_state == NFLASH_ADDR || match_found_reg) begin
				if(logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] == bbt_word0)
					physical_blk_addr = bbt_word1[BLOCK_ADDR_WIDTH-1:0];
				else if(logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] == bbt_word0)
					physical_blk_addr = bbt_word1[BLOCK_ADDR_WIDTH-1:0];
				else
					physical_blk_addr = logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH];
			end
		end
		else
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
			if (FLASH_DATA_WIDTH == 8)
				if (bbt_byte_cnt_q[0] == 0) 
					if (bbt_byte_cnt_q[1] == 0) begin
						bbt_word0[15:8] = (current_state == NFLASH_BBM_HEADER || current_state == NFLASH_BBT_DATA) ? flash_io_in : bbt_word0[15:8];
					end 
					else begin
						bbt_word1[15:8] = (current_state == NFLASH_BBT_DATA0 || current_state == NFLASH_BBT_DATA) ? flash_io_in : bbt_word1[15:8];
					end
				else 
					if (bbt_byte_cnt_q[1] == 0) begin
						bbt_word0[7:0] = (current_state == NFLASH_BBM_HEADER || current_state == NFLASH_BBT_DATA) ? flash_io_in : bbt_word0[7:0];
					end
					else begin
						bbt_word1[7:0] = (current_state == NFLASH_BBT_DATA0 || current_state == NFLASH_BBT_DATA) ? flash_io_in : bbt_word1[7:0];
					end
			else 
				if (bbt_byte_cnt_q[0] == 0) begin
					bbt_word0 = flash_io_in;
				end
				else begin 	
					bbt_word1 = flash_io_in;
				end
		end
	end
	
	//Status register capture
	reg [7:0] sr;
	always @ (posedge clk)
	begin
		if (~nreset) 
			sr = 8'h00;
		else if (current_state == NFLASH_STATUS_DATA)
			sr = flash_io_in[7:0];
	end
	
	// Control data
	reg 	[FLASH_DATA_WIDTH-1:0] flash_io_in_reg;
	reg 	data_ready_delay_one;
	always @(posedge clk) begin
		data_ready_delay_one = (current_state == NFLASH_DATA) && flash_noe;
	end
	always @(posedge clk) begin
		if((current_state == NFLASH_DATA) && flash_noe && ~data_ready_delay_one) begin
			flash_io_in_reg = flash_io_in;
		end
	end
	assign data_ready = (current_state == NFLASH_DATA) && flash_noe && data_ready_delay_one;
	assign data = flash_io_in_reg;

	// NAND flash command monitor
	wire		next_page;
	wire  	next_block;
	assign 	next_page = (&logical_addr_cnt_q[COL_ADDR_WIDTH-1:0]) && addr_cnt_en;
	assign  	next_block = (&logical_addr_cnt_q[PAGE_COL_ADDR_WIDTH-1:0]) && addr_cnt_en;
		
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
	
	// Reserved block area counter
	wire	[BLOCK_ADDR_WIDTH-1:0] rba_block_cnt_q;
	wire 	[31:0] rba_start_addr = NRB_ADDR;
	wire 	[BLOCK_ADDR_WIDTH-1:0] rba_last_block_addr = rba_start_addr[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] + RB_SIZE;
	lpm_counter rba_counter (
		.clock(clk),
		.cnt_en((current_state == NFLASH_BBM_HEADER_VERIFY || current_state == NFLASH_STATUS_DATA) && next_state == NFLASH_BBM_CMD),
		.sload(current_state == NFLASH_INIT && next_state == NFLASH_BBM_CMD),
		.data(rba_last_block_addr),
		.q(rba_block_cnt_q)
	);
	defparam 	rba_counter.LPM_WIDTH = BLOCK_ADDR_WIDTH;
	defparam		rba_counter.LPM_DIRECTION = "DOWN";
	
	// Bad block table counter 
	wire	[COL_ADDR_WIDTH-1:0] bbt_byte_cnt_q;
	wire 	[COL_ADDR_WIDTH-1:0] stop_bbt_byte_cnt = {total_bad_block[6:0], 2'b11}; 
	wire 	bbt_cnt_en = ((current_state == NFLASH_BBT_DATA0) || (current_state == NFLASH_BBT_DATA) || (current_state == NFLASH_BBM_HEADER)) && (flash_clk_count == CLK_DIVISOR-1);
	lpm_counter bbt_counter (
		.clock(clk),
		.cnt_en(bbt_cnt_en),
		.sclr(current_state == NFLASH_INIT || (current_state == NFLASH_BBM_HEADER_VERIFY && !header_found)),
		.sload(addr_sload),
		.data({{(COL_ADDR_WIDTH-3){1'b0}}, 3'b100}), 
		.q(bbt_byte_cnt_q)
	);
	defparam 	bbt_counter.LPM_WIDTH = COL_ADDR_WIDTH;
	
	// Flash clock counter
	wire 	[log2(CLK_DIVISOR)-1:0] flash_clk_count;
	wire 	flash_clk_clear = (next_state == NFLASH_CMD || next_state == NFLASH_ADDR || next_state == NFLASH_DATA || next_state == NFLASH_WAIT) || 
										(next_state == NFLASH_BBM_CMD || next_state == NFLASH_BBM_ADDR || next_state == NFLASH_BBM_HEADER) || 
										(next_state == NFLASH_BBT_CMD || next_state == NFLASH_BBT_ADDR || next_state == NFLASH_BBT_DATA0 || next_state == NFLASH_BBT_DATA) ||
										(next_state == NFLASH_RAMP_WAIT || next_state == NFLASH_RESET_CMD || next_state == NFLASH_RESET_WAIT) ||
										(next_state == NFLASH_FEAT_CMD || next_state == NFLASH_FEAT_ADDR || next_state == NFLASH_FEAT_WAIT || next_state == NFLASH_FEAT_DATA || next_state == NFLASH_FEAT_PREWAIT) ||
										next_state == NFLASH_STATUS_DATA || next_state == NFLASH_READ_CMD;
	wire 	counter_en = cnfm_state || cmd_state || addr_state || wait_state || (current_state == NFLASH_FEAT_DATA) || 
								(current_state == NFLASH_DATA && !flash_noe) || 
								(current_state == NFLASH_BBT_DATA0) || 
								(current_state == NFLASH_BBT_DATA) || 
								(current_state == NFLASH_BBM_HEADER) ||
								(current_state == NFLASH_STATUS_DATA);
	lpm_counter flash_clk_counter (
		.clock(clk),
		.sclr(flash_clk_clear),
		.cnt_en(counter_en),
		.q(flash_clk_count)
	);
	defparam	flash_clk_counter.lpm_width = log2(CLK_DIVISOR);
	
	// Operation counter
	wire	[log2(US_UNIT_COUNTER*1000)-1:0] op_count;
	wire 	op_clear = (current_state != next_state) && (next_state != NFLASH_SAME);
	lpm_counter flash_op_counter (
		.clock(clk),
		.sclr(op_clear),
		.cnt_en(counter_en && (flash_clk_count == CLK_DIVISOR-1)),
		.q(op_count) 
	);
	defparam flash_op_counter.lpm_width = log2(US_UNIT_COUNTER*1000);
	
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
	
	// Data stage
	reg [2:0] session;
	always @ (posedge clk or negedge nreset) begin
		if (~nreset) 
			session = 3'b000;
		else if (next_state == NFLASH_BBM_CMD) 
			session = 3'b001;
		else if (next_state == NFLASH_CMD) 
			session = 3'b010;
		else if (next_state == NFLASH_BBT_CMD) 
			session = 3'b011;
	end
	
	// State machine flow
	always @ (nreset, current_state, op_count, data_request, addr_sload, granted, next_page, done, header_found, header_found_reg, total_bad_block, 
				 flash_clk_count, physical_addr, rba_start_addr, bbt_byte_cnt_q, stop_bbt_byte_cnt, logical_addr_cnt_q, bbt_word0, 
				 match_found, next_block, addr_cnt_en, rba_block_cnt_q, session, sr)	
	begin
		if (~nreset) begin
			next_state = NFLASH_RAMP_WAIT;
		end
		else begin 
			case (current_state)
				NFLASH_RAMP_WAIT:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == US_UNIT_COUNTER*100-1)) 
						next_state = NFLASH_RESET_CMD;
					else
						next_state = NFLASH_SAME;
				NFLASH_RESET_CMD:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_RESET_WAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_RESET_WAIT: 
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == US_UNIT_COUNTER*1000-1)) 
						next_state = (FLASH_MFC == "MICRON") ? NFLASH_FEAT_CMD : NFLASH_INIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_FEAT_CMD:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_FEAT_ADDR;
					else
						next_state = NFLASH_SAME;
				NFLASH_FEAT_ADDR:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_FEAT_PREWAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_FEAT_PREWAIT:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == 1)) 
						next_state = NFLASH_FEAT_DATA;
					else
						next_state = NFLASH_SAME;
				NFLASH_FEAT_DATA:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == 3)) 
						next_state = NFLASH_FEAT_WAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_FEAT_WAIT:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == US_UNIT_COUNTER-1)) 
						next_state = NFLASH_INIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_INIT: 
					if (data_request && granted) begin
						if (header_found_reg) begin
							if (total_bad_block =='h0000) begin
								next_state = NFLASH_CMD;
							end
							else begin 
								next_state = NFLASH_BBT_CMD;
							end
						end
						else begin 
							next_state = NFLASH_BBM_CMD;
						end
					end
					else
						next_state = NFLASH_SAME;
				NFLASH_BBM_CMD:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_BBM_ADDR;
					else
						next_state = NFLASH_SAME;
				NFLASH_BBM_ADDR:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_ADDR_CYCLE-1))
						next_state = (FLASH_MFC != "MICRON") ? NFLASH_WAIT : NFLASH_BBM_CNFM_CMD;
					else if(flash_clk_count == CLK_DIVISOR-1)
						next_state = NFLASH_BBM_ADDR;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBM_CNFM_CMD:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_WAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_BBM_HEADER:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_BBT_DATA_CYCLE-1)) begin
						next_state = NFLASH_BBM_HEADER_VERIFY;
					end
					else if (flash_clk_count == CLK_DIVISOR-1)
						next_state = NFLASH_BBM_HEADER;
					else 	
						next_state = NFLASH_SAME;
				NFLASH_BBM_HEADER_VERIFY:
					if (header_found)
						next_state = NFLASH_BBT_DATA0;
					else if (rba_block_cnt_q != rba_start_addr[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH]) begin
						next_state = NFLASH_BBM_CMD;
					end
					else begin
						next_state = NFLASH_CMD;	
					end
				NFLASH_BBT_DATA0:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_BBT_DATA_CYCLE-1))
						if (total_bad_block == 'h0000) begin
							next_state = NFLASH_CMD;
						end
						else
							next_state = NFLASH_BBT_DATA;
					else if(flash_clk_count == CLK_DIVISOR-1) 
							next_state = NFLASH_BBT_DATA0;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBT_DATA:
					if(bbt_byte_cnt_q > stop_bbt_byte_cnt) begin
						next_state = NFLASH_CMD;
					end
					else if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_BBT_DATA_CYCLE*2-1)) begin
						if (logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] < bbt_word0) begin
							next_state = NFLASH_CMD;
						end
						else
							next_state = NFLASH_BBT_DATA;
						end
					else if(flash_clk_count == CLK_DIVISOR-1)
						next_state = NFLASH_BBT_DATA;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBT_DATA_STORE: 
					if (match_found) begin
						next_state = NFLASH_CMD;
					end
					else if (logical_addr_cnt_q[FLASH_ADDR_WIDTH-1:PAGE_COL_ADDR_WIDTH] < bbt_word0) begin
						next_state = NFLASH_CMD;
					end
					else begin 
						next_state = NFLASH_BBT_CMD; 
					end
				NFLASH_CMD:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_ADDR;
					else
						next_state = NFLASH_SAME;
				NFLASH_ADDR:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_ADDR_CYCLE-1))
						next_state = (FLASH_MFC != "MICRON") ? NFLASH_WAIT : NFLASH_CNFM_CMD;
					else if(flash_clk_count == CLK_DIVISOR-1)
						next_state = NFLASH_ADDR;
					else 
						next_state = NFLASH_SAME;
				NFLASH_CNFM_CMD: 
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_WAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_WAIT: 	
					if (flash_clk_count == CLK_DIVISOR-1) begin
						case (session)
							3'b001: begin
								if (op_count == FLASH_WAIT_CYCLE-1)
									next_state = (FLASH_ECC_CHECKBOX == 1) ? NFLASH_STATUS_CMD : NFLASH_BBM_HEADER;
								else
									next_state = NFLASH_WAIT;
							end
							3'b010: begin
								if (op_count == FLASH_WAIT_CYCLE-1)
									next_state = (FLASH_ECC_CHECKBOX == 1) ? NFLASH_STATUS_CMD : NFLASH_DATA;
								else
									next_state = NFLASH_WAIT;
							end 
							3'b011: begin
								if (op_count == FLASH_WAIT_CYCLE-1)
									next_state = (FLASH_ECC_CHECKBOX == 1) ? NFLASH_STATUS_CMD : NFLASH_BBT_DATA;
								else
									next_state = NFLASH_WAIT;
							end
							default: 
								next_state = NFLASH_SAME;
						endcase
					end
					else 
						next_state = NFLASH_SAME;
				NFLASH_STATUS_CMD: 
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_STATUS_WAIT;
					else
						next_state = NFLASH_SAME;
				NFLASH_STATUS_WAIT:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == 1)) 
						next_state = NFLASH_STATUS_DATA;
					else
						next_state = NFLASH_SAME;
				NFLASH_STATUS_DATA:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_DATA_CYCLE-1))
						if (sr[0] == 1'b1) begin
							if (session == 3'b001)
								next_state = NFLASH_BBM_CMD;
							else
								next_state = NFLASH_INIT;
						end
						else 
							next_state = NFLASH_READ_CMD;
					else if(flash_clk_count == CLK_DIVISOR-1) 
						next_state = NFLASH_STATUS_DATA;
					else 
						next_state = NFLASH_SAME;
				NFLASH_READ_CMD:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						begin
							case (session)
								3'b001: 
									next_state = NFLASH_BBM_HEADER;
								3'b010: 
									next_state = NFLASH_DATA;	
								3'b011: 
									next_state = NFLASH_BBT_DATA;
								default: 
									next_state = NFLASH_SAME;
							endcase
						end
					else
						next_state = NFLASH_SAME;
				NFLASH_DATA: 
					if (addr_sload)
						if (total_bad_block == 'h0000 || !header_found_reg) begin
							next_state = NFLASH_CMD;
						end
						else begin
							next_state = NFLASH_BBT_CMD;
						end
					else if (next_block)
						if (total_bad_block == 'h0000 || !header_found_reg) begin
							next_state = NFLASH_CMD;
						end
						else if (bbt_byte_cnt_q > 9'b0_0000_0111)
							next_state = NFLASH_BBT_DATA_STORE;
						else begin
							next_state = NFLASH_BBT_CMD;
						end
					else if (next_page && !next_block) begin
						next_state = NFLASH_CMD;
					end
					else if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_DATA_CYCLE-1)) 
						if (addr_cnt_en)
							next_state = NFLASH_DATA;
						else 
							next_state = NFLASH_SAME;
					else 	
						next_state = NFLASH_SAME;
				NFLASH_BBT_CMD:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_BBT_ADDR;
					else
						next_state = NFLASH_SAME;
				NFLASH_BBT_ADDR:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_ADDR_CYCLE-1)) 
						next_state = (FLASH_MFC != "MICRON") ? NFLASH_WAIT : NFLASH_BBT_CNFM_CMD;
					else if(flash_clk_count == CLK_DIVISOR-1)
						next_state = NFLASH_BBT_ADDR;
					else 
						next_state = NFLASH_SAME;
				NFLASH_BBT_CNFM_CMD:
					if ((flash_clk_count == CLK_DIVISOR-1) && (op_count == FLASH_CMD_CYCLE-1)) 
						next_state = NFLASH_WAIT;
					else
						next_state = NFLASH_SAME;
				default:
					next_state = NFLASH_RAMP_WAIT;
			endcase
		end	
	end
	
	initial begin
		current_state = NFLASH_RAMP_WAIT;
	end

	always @(negedge nreset or posedge clk)
	begin
		if(~nreset) begin
			current_state = NFLASH_RAMP_WAIT;
		end
		else begin
			if (next_state != NFLASH_SAME) begin
				current_state = next_state;
			end
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
