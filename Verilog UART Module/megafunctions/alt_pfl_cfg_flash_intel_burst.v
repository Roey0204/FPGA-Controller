////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG_FLASH_INTEL_BURST
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
// This module contains the PFL configuration burst-mode flash reader block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

// altera message_off 10030

module alt_pfl_cfg_flash_intel_burst (
	clk,
	nreset,

	// Flash pins
	flash_select,
	flash_read,
	flash_write,
	flash_data_in,
	flash_data_out,
	flash_addr,
	flash_clk,
	flash_nadv,
	flash_rdy,
	flash_nreset,
	flash_data_highz,

	// Controller address
	addr_in,
	stop_addr_in,
	addr_sload,
	addr_cnt_en,
	done,
	
	// Controller data
	data_request,
	data_ready,
	data,

	// Access control
	flash_access_request,
	flash_access_granted
)
/* synthesis altera_attribute = "SUPPRESS_DA_RULE_INTERNAL=R101"*/;

	parameter FLASH_DATA_WIDTH = 16;
	parameter FLASH_ADDR_WIDTH = 25;
	parameter BURST_CLOCK_DIVIDER = 0;
	parameter ACCESS_CLK_DIVISOR = 10;
	parameter BURST_MODE_SPANSION = 0;
	parameter BURST_MODE_NUMONYX = 0;
	parameter FLASH_ADDR_WIDTH_INDEX = (FLASH_DATA_WIDTH == 32) ? FLASH_ADDR_WIDTH + 2 :
										FLASH_ADDR_WIDTH;
	parameter FLASH_DATA_WIDTH_INDEX = (FLASH_DATA_WIDTH == 32) ? 8 :
										FLASH_DATA_WIDTH;								
	input	clk;
	input	nreset;

	output 	flash_select;
	output 	flash_read;
	output 	flash_write;
	input 	[FLASH_DATA_WIDTH-1:0] flash_data_in;
	output 	[FLASH_DATA_WIDTH-1:0] flash_data_out;
	output	[FLASH_ADDR_WIDTH-1:0] flash_addr;
	output	flash_clk;
	output	flash_nadv;
	input	flash_rdy;
	output	flash_nreset;
	output	flash_data_highz;
	
	input 	[FLASH_ADDR_WIDTH_INDEX-1:0] addr_in;
	input	[FLASH_ADDR_WIDTH_INDEX-1:0] stop_addr_in;
	input	addr_sload;
	input	addr_cnt_en;
	output	done;
	
	input	data_request;
	output	data_ready;
	reg 	data_ready;
	output	[FLASH_DATA_WIDTH_INDEX-1:0] data;
	
	output	flash_access_request;
	input	flash_access_granted;
		
	parameter BURST_SAME 		= 0;
	parameter BURST_INIT 		= 1;
	parameter BURST_WAIT		= 2;
	parameter BURST_CONVERSION 	= 2;
	parameter BURST_RESET 		= 3;
	parameter BURST_DIE 		= 4;
	parameter BURST_RCR 		= 5;
	parameter BURST_DUMMY 		= 6;
	parameter BURST_ADDR 		= 7;
	parameter BURST_LATENCY 	= 8;
	parameter BURST_READ 		= 9;
	
	reg 	[3:0] current_state /* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
	reg		[3:0] next_state;

	reg 		  rcr_addr;
	reg 		  rcr_write;
	reg 		  rcr_hold;		  

	wire [2:0] counter_q;
	wire [FLASH_ADDR_WIDTH_INDEX-1:0] addr_counter_q;
	wire [FLASH_ADDR_WIDTH-1:0] mapped_flash_addr;
		
	generate
	if(FLASH_DATA_WIDTH == 32)
		assign mapped_flash_addr = addr_counter_q[FLASH_ADDR_WIDTH_INDEX-1:2];
	else
		assign mapped_flash_addr = addr_counter_q;
	endgenerate
	
	reg	 flash_write_reg;
	wire access_counter_cycle;
	wire access_counter_out;
	  
	parameter MAX_RCR_WORDS = 5;
	integer	RCR_DATA[MAX_RCR_WORDS-1:0];
	integer	RCR_ADDR[MAX_RCR_WORDS-1:0];
	integer	RCR_WORDS;
	integer	READ_LATENCY;
	
	parameter DONT_CARE = 'hDEADBEEF;
	
	initial begin
		if (BURST_MODE_SPANSION == 1) begin
			RCR_WORDS = 5;
			READ_LATENCY = 4;
			RCR_DATA[0] = 'hAA;
			RCR_ADDR[0] = 'h555;
			RCR_DATA[1] = 'h55;
			RCR_ADDR[1] = 'h2AA;
			RCR_DATA[2] = 'hD0;
			RCR_ADDR[2] = 'h555;
			RCR_DATA[3] = 'h1FC8;
			RCR_ADDR[3] = 'h000;
			RCR_DATA[4] = 'hF0;
			RCR_ADDR[4] = 'h000;
		end
		else if (BURST_MODE_NUMONYX == 1) begin
			RCR_WORDS 			   = 2;
			READ_LATENCY 		   = 3;
			
			RCR_DATA[0] 		   = 'h60; 
			RCR_ADDR[0] 		   = 'h184F;			
			RCR_DATA[1] 		   = 'h03;
			RCR_ADDR[1] 		   = 'h184F;
			RCR_DATA[2] 		   = 'h90;
			RCR_ADDR[2] 		   = 'h0000;
			// Dummy data to avoid warnings
			RCR_DATA[3] 		   = 'h0;
			RCR_ADDR[3] 		   = 'h0;
			RCR_DATA[4] 		   = 'h0;
			RCR_ADDR[4] 		   = 'h0;
		end
		else begin
			RCR_WORDS 			   = 2;
			READ_LATENCY 		   = 4;
			RCR_DATA[0] 		   = 'h00600060;
			//RCR_ADDR[0] 		   = 'h18CF;  	// cschai: latency of 3
			RCR_ADDR[0] 		   = 'h20CF;	// cschai: latency of 4
			RCR_DATA[1] 		   = 'h00030003;
			//RCR_ADDR[1] 		   = 'h18CF;	// cschai: latency of 3
			RCR_ADDR[1] 		   = 'h20CF;	// cschai: latency of 4
			RCR_DATA[2] 		   = 'h0;
			RCR_ADDR[2] 		   = 'h0;
			//Dummy data to avoid warnings
			RCR_DATA[3] 		   = 'h0;
			RCR_ADDR[3] 		   = 'h0;
			RCR_DATA[4] 		   = 'h0;
			RCR_ADDR[4] 		   = 'h0;
		end
	end
	
	wire [FLASH_ADDR_WIDTH-1:0] virtual_flash_addr;
	wire accross_die = addr_counter_q == {1'b0, {(FLASH_ADDR_WIDTH_INDEX-1){1'b1}}};
	
	assign virtual_flash_addr = {mapped_flash_addr[FLASH_ADDR_WIDTH-1],{(FLASH_ADDR_WIDTH-1){1'b0}}};
	
	assign flash_addr = current_state == BURST_RCR ? {mapped_flash_addr[FLASH_ADDR_WIDTH-1] , RCR_ADDR[counter_q][FLASH_ADDR_WIDTH-2:0]} :
						(current_state == BURST_ADDR || current_state == BURST_LATENCY) ? mapped_flash_addr :
						virtual_flash_addr;
						
	assign flash_data_out = current_state == BURST_RCR ? RCR_DATA[counter_q][FLASH_DATA_WIDTH-1:0] :
							{DONT_CARE[FLASH_DATA_WIDTH-1:0]};
	assign flash_write = flash_write_reg && current_state == BURST_RCR && rcr_write;
	assign flash_read = current_state == BURST_LATENCY || current_state == BURST_READ;
	assign flash_data_highz = current_state == BURST_LATENCY || current_state == BURST_READ;
	assign flash_nadv = ~(current_state == BURST_INIT || current_state == BURST_RESET || current_state == BURST_ADDR || current_state == BURST_RCR) || (current_state == BURST_LATENCY || current_state == BURST_READ);

	reg flash_nreset_reg;
	assign flash_nreset = flash_nreset_reg;
	always @(posedge clk or negedge nreset)
	begin
		if (~nreset)
			flash_nreset_reg = 0;
		else
			flash_nreset_reg = ~(current_state == BURST_RESET && counter_q == 0);
	end
	
	reg granted;
	reg request;
	reg addr_latched;
	assign flash_select = (current_state == BURST_DIE && counter_q == 0) ? 1'b0 : granted;
	
	assign flash_access_request = request;
	always @(posedge clk or negedge nreset)
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

	always @(posedge clk or negedge nreset)
	begin
		if (~nreset) begin
			rcr_addr 	 = 0;
			rcr_write 	 = 0;
			rcr_hold 	 = 0;
		end
		else begin
			if (next_state == BURST_RCR) begin
				rcr_addr 	 = 1;
				rcr_write 	 = 0;
				rcr_hold 	 = 0;
			end
			else if (rcr_addr && access_counter_cycle) begin
				rcr_addr 	 = 0;
				rcr_write 	 = 1;
				rcr_hold 	 = 0;
			end
			else if (rcr_write && access_counter_cycle) begin
				rcr_addr 	 = 0;
				rcr_write 	 = 0;
				rcr_hold 	 = 1;
			end
			else if (rcr_hold && access_counter_cycle) begin
				rcr_addr 	 = 1;
				rcr_write 	 = 0;
				rcr_hold 	 = 0;
			end
		end
	end
	wire counter_cnt_en = current_state == BURST_RCR ? access_counter_cycle && rcr_hold :
						current_state == BURST_RESET ? access_counter_out :
						current_state == BURST_DIE ? access_counter_out :
						flash_clk_cycle;
	wire counter_clear = next_state == BURST_RESET || next_state == BURST_RCR || next_state == BURST_LATENCY || next_state == BURST_DIE;
	lpm_counter counter
	(
		.clock(clk),
		.sclr(counter_clear),
		.cnt_en(counter_cnt_en),
		.q(counter_q)
	);
	defparam counter.lpm_width=3;

	lpm_counter addr_counter
	(
		.clock(clk),
		.sload(addr_sload),
		.data(addr_in),
		.cnt_en(addr_cnt_en & ~addr_latched),
		.q(addr_counter_q)
	);
	defparam addr_counter.lpm_width=FLASH_ADDR_WIDTH_INDEX;
		
	wire 	[3:0] access_counter_q;
	assign access_counter_out = access_counter_q == ACCESS_CLK_DIVISOR;
	wire access_counter_cnt_en = current_state == BURST_RCR || current_state == BURST_RESET || current_state == BURST_DUMMY || current_state == BURST_DIE ;
	wire access_counter_clear = access_counter_out || next_state == BURST_RCR || next_state == BURST_RESET || next_state == BURST_DIE ;
	lpm_counter access_counter
	(
		.clock(clk),
		.sclr(access_counter_clear),
		.cnt_en(access_counter_cnt_en),
		.q(access_counter_q)
	);
	defparam access_counter.lpm_width=4;
	assign access_counter_cycle = access_counter_out && ~flash_write_reg;
	
	reg start_capture_data;
	always @(posedge clk)
	begin
		if(current_state == BURST_READ & flash_clk_cycle)
			start_capture_data = 1'b1;
		else if(current_state == BURST_RCR || addr_sload)
			start_capture_data = 1'b0;
	end
	
	wire flash_clk_cycle;
	wire flash_data_valid;
	generate
	if(FLASH_DATA_WIDTH == 32)
	begin
		assign flash_clk_cycle = flash_clk_reg & virtual_flash_clk & ~data_fifo_full;
		assign flash_data_valid = flash_clk_reg & ~virtual_flash_clk & ~data_fifo_full & start_capture_data;
	end
	else
	begin
		assign flash_clk_cycle = flash_clk_reg & ~data_fifo_full;
		assign flash_data_valid = ~flash_clk_reg & ~data_fifo_full & start_capture_data;
	end
	endgenerate

	always @(posedge clk or negedge nreset) begin
		if (~nreset)
			flash_write_reg = 0;
		else begin
			if (next_state == BURST_RCR)
				flash_write_reg = 1;
			else if (next_state == BURST_WAIT)
				flash_write_reg = 0;
			else if (current_state == BURST_RCR && access_counter_out)
				flash_write_reg = ~flash_write_reg;
		end
	end

	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			addr_latched = 0;
		else if (addr_sload)
			addr_latched = 1;
		else if (next_state == BURST_LATENCY)
			addr_latched = 0;
	end

	reg addr_done;
	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			addr_done = 0;
		else if (addr_sload)
			addr_done = 0;
		else if (addr_counter_q == stop_addr_in)	
			addr_done = 1;
	end
	assign done = addr_done;
	
	reg flash_clk_reg;
	assign flash_clk = (current_state == BURST_LATENCY || current_state == BURST_READ) ? virtual_flash_clk : 1'b0;
	always @(posedge clk or negedge nreset) 
	begin
		if (~nreset)
			flash_clk_reg = 0;
		else if(current_state == BURST_LATENCY || current_state == BURST_READ || current_state == BURST_ADDR)
		begin
			if(~data_fifo_full)
				flash_clk_reg = ~flash_clk_reg;
		end
		else
			flash_clk_reg = 1'b0;
	end
	
	reg virtual_flash_clk;
	generate
	if(FLASH_DATA_WIDTH == 32)
	begin
		always @(posedge clk or negedge nreset)
		begin
			if (~nreset)
				virtual_flash_clk = 0;
			else begin
				if(current_state == BURST_LATENCY || current_state == BURST_READ || current_state == BURST_ADDR)
				begin
					if(~data_fifo_full)
					begin
						if(flash_clk_reg)
							virtual_flash_clk = ~flash_clk;
					end
				end
				else
					virtual_flash_clk = 1'b0;
			end
		end
	end
	else
	begin
		always @(flash_clk_reg)
		begin
			virtual_flash_clk = flash_clk_reg;
		end
	end
	endgenerate

	always @(posedge clk)
	begin
		if(current_state == BURST_READ)
		begin
			if(flash_data_valid)
			begin
				fifo_in = flash_data_in;
			end
		end
	end
	
	always @(posedge clk)
	begin
		if(current_state == BURST_READ)
		begin
			valid_fifo_in = flash_data_valid;
		end
		else
			valid_fifo_in = 1'b0;
	end
	
	wire clear_fifo = ~(current_state == BURST_READ);
	reg data_fifo_empty;
	reg data_fifo_full;
	reg valid_fifo_in;
	reg [FLASH_DATA_WIDTH-1:0] fifo_in;

	generate
	if(FLASH_DATA_WIDTH == 32)
	begin	
		parameter CONTROL_FIFO_DEPTH = 16;
		parameter CONTROL_FIFO_ALMOST_FULL_VALUE = 11;
		parameter CONVERSION_COUNT = 3;
		
		wire read_fifo = conversion_next_state == BURST_CONVERSION;
		reg [FLASH_DATA_WIDTH-1:0] fifo_out;
		scfifo data_fifo (
			.clock(clk),
			.data(fifo_in),
			.empty(data_fifo_empty),
			.full(data_fifo_full),
			.q(fifo_out),
			.rdreq(read_fifo),
			.aclr(clear_fifo | addr_sload),
			.wrreq(valid_fifo_in)
		);
		defparam
		data_fifo.LPM_WIDTH = FLASH_DATA_WIDTH,
		data_fifo.LPM_NUMWORDS = 2;
		
		reg first_request;
		always @(posedge clk)
		begin
			if(next_state == BURST_READ)
				first_request = data_request;
			else if(first_request & ~control_fifo_empty)
				first_request = 1'b0;
		end
	
		always @(posedge clk)
		begin
			data_ready = ~control_fifo_empty & data_request & (next_state != BURST_DIE);
		end
		
		reg [2:0] conversion_count_q;
		always @(posedge clk)
		begin
			if(conversion_current_state == BURST_CONVERSION)
			begin	
				if(conversion_count_q == 3'b000)
					control_fifo_in = fifo_out[7:0];
				else if(conversion_count_q == 3'b001)
					control_fifo_in = fifo_out[15:8];
				else if(conversion_count_q == 3'b010)
					control_fifo_in = fifo_out[23:16];
				else if(conversion_count_q == 3'b011)
					control_fifo_in = fifo_out[31:24];
			end
		end
	
	
		always @(posedge clk)
		begin
			control_fifo_wr_req = conversion_current_state == BURST_CONVERSION;
		end
		
		//This is safe but not fast
		//reg auto_increment;
		//always @(posedge clk)
		//begin
		//	if(addr_cnt_en & control_fifo_empty)
		//		auto_increment = 1'b1;
		//	else if(auto_increment & ~control_fifo_empty)
		//		auto_increment = 1'b0;
		//end
		//wire read_control_fifo = (addr_cnt_en | auto_increment) & ~control_fifo_empty;
		
		// This is not safe but fast
		wire read_control_fifo = addr_cnt_en;
	
		wire control_fifo_empty;
		wire control_fifo_full;
		wire control_fifo_almost_full;
		reg control_fifo_wr_req;
		reg [FLASH_DATA_WIDTH_INDEX-1:0] control_fifo_in;
		scfifo control_data_fifo (
			.clock(clk),
			.data(control_fifo_in),
			.empty(control_fifo_empty),
			.full(control_fifo_full),
			.almost_full(control_fifo_almost_full),
			.q(data),
			.rdreq(first_request | read_control_fifo),
			.aclr(clear_fifo | addr_sload),
			.wrreq(control_fifo_wr_req)
		);
		defparam
		control_data_fifo.LPM_WIDTH = FLASH_DATA_WIDTH_INDEX,
		control_data_fifo.LPM_NUMWORDS = CONTROL_FIFO_DEPTH,
		control_data_fifo.ALMOST_FULL_VALUE = CONTROL_FIFO_ALMOST_FULL_VALUE;
		
		reg[1:0] conversion_current_state;
		reg[1:0] conversion_next_state;
	
		// LPM counter																				
		lpm_counter conversion_counter (
			.clock(clk),
			.cnt_en(conversion_current_state == BURST_CONVERSION),
			.sclr(conversion_next_state == BURST_CONVERSION),
			.q(conversion_count_q)
		);
		defparam
		conversion_counter.lpm_type = "LPM_COUNTER",
		conversion_counter.lpm_direction= "UP",
		conversion_counter.lpm_width = 3;
	
		always @(conversion_current_state, nreset, control_fifo_almost_full, data_fifo_empty,
				conversion_count_q, clear_fifo)
		begin
			if(~nreset)
				conversion_next_state = BURST_INIT;
			else
				case (conversion_current_state)
					BURST_INIT:
						if(control_fifo_almost_full | data_fifo_empty)
							conversion_next_state = BURST_SAME;
						else
							conversion_next_state = BURST_CONVERSION;
					BURST_CONVERSION:
						if(conversion_count_q < CONVERSION_COUNT[2:0])
							conversion_next_state = BURST_SAME;
						else
						begin
							if(control_fifo_almost_full | data_fifo_empty)
								conversion_next_state = BURST_INIT;
							else
								conversion_next_state = BURST_CONVERSION;
						end
					default:
						conversion_next_state = BURST_INIT;
				endcase
		end
	
		always @(posedge clk or negedge nreset) begin
			if (~nreset)
				conversion_current_state = BURST_INIT;
			else
			begin
				if (clear_fifo)
					conversion_current_state = BURST_INIT;
				else if (conversion_next_state != BURST_SAME)
					conversion_current_state = conversion_next_state;
			end
		end
	end
	else
	begin
		reg auto_increment;
		always @(posedge clk)
		begin
			if(addr_cnt_en & data_fifo_empty)
				auto_increment = 1'b1;
			else if(auto_increment & ~data_fifo_empty)
				auto_increment = 1'b0;
		end
	
		wire read_fifo = (addr_cnt_en | auto_increment) & ~data_fifo_empty;
		reg [FLASH_DATA_WIDTH-1:0] fifo_out;
		scfifo data_fifo (
			.clock(clk),
			.data(fifo_in),
			.empty(data_fifo_empty),
			.full(data_fifo_full),
			.q(data),
			.rdreq(first_request | read_fifo),
			.aclr(clear_fifo | addr_sload),
			.wrreq(valid_fifo_in)
		);
		defparam
		data_fifo.LPM_WIDTH = FLASH_DATA_WIDTH,
		data_fifo.LPM_NUMWORDS = 2;
		
		reg first_request;
		always @(posedge clk)
		begin
			if(next_state == BURST_READ)
				first_request = data_request;
			else if(first_request & ~data_fifo_empty)
				first_request = 1'b0;
		end
	
		always @(posedge clk)
		begin
			data_ready = ~data_fifo_empty & data_request & (next_state != BURST_DIE);
		end
	end
	endgenerate
	
	always @(current_state, nreset, counter_q, access_counter_cycle, access_counter_out, flash_clk_cycle, addr_sload, addr_latched, granted, data_request, rcr_hold, 
			RCR_WORDS, READ_LATENCY, accross_die, addr_cnt_en) begin
		if (~nreset)
			next_state = BURST_INIT;
		else
			case (current_state)
				BURST_INIT:
					next_state = BURST_WAIT;
				BURST_WAIT:
					if (addr_latched && granted && data_request)
						next_state = BURST_DIE;
					else
						next_state = BURST_SAME;
				BURST_DIE:
				    if (access_counter_out && counter_q == 3)
						next_state = BURST_RESET;
					else
						next_state = BURST_SAME;
				BURST_RESET:
					if (access_counter_out && counter_q == 3)
						next_state = BURST_RCR;
					else
						next_state = BURST_SAME;		
				BURST_RCR:
					if (counter_q == RCR_WORDS-1 && access_counter_cycle && rcr_hold) 
						next_state 	= BURST_DUMMY;
					else
						next_state 	= BURST_SAME;
				BURST_DUMMY:
				    if (access_counter_out)
						next_state = BURST_ADDR;
					else
						next_state = BURST_SAME;
				BURST_ADDR:
					if (flash_clk_cycle)
						next_state = BURST_LATENCY;
					else
						next_state = BURST_SAME;
				BURST_LATENCY:
					if (counter_q == READ_LATENCY-1 && flash_clk_cycle)
						next_state = BURST_READ;
					else
						next_state = BURST_SAME;
				BURST_READ:
					if(accross_die & addr_cnt_en)
						next_state = BURST_DIE;
					else if (addr_latched)
						next_state = BURST_DIE;
					else if (~granted)
						next_state = BURST_WAIT;
					else
						next_state = BURST_SAME;
				default:
					next_state = BURST_INIT;
			endcase
	end
	
	always @(posedge clk or negedge nreset) begin
		if (~nreset)
			current_state = BURST_INIT;
		else
			if (next_state != BURST_SAME)
				current_state = next_state;
	end
			
	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
					value = value >> 1;
		end
	endfunction
endmodule
