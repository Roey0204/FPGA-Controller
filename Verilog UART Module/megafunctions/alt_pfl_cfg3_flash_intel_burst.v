////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG3_FLASH_INTEL_BURST
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
// This module only specially handle FPPx16 and FPPx32
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

// altera message_off 10030

module alt_pfl_cfg3_flash_intel_burst (
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
);

	parameter FLASH_DATA_WIDTH					= 16;
	parameter FLASH_ADDR_WIDTH					= 25;
	parameter BURST_CLOCK_DIVIDER				= 0;
	parameter ACCESS_CLK_DIVISOR				= 10;
	parameter BURST_MODE_SPANSION				= 0;
	parameter BURST_MODE_NUMONYX				= 0;
	parameter FLASH_BURST_EXTRA_CYCLE		= 0;
	parameter BURST_MODE_LATENCY_COUNT		= 4;
	
	localparam LATENCY_COUNT = (BURST_MODE_LATENCY_COUNT < 3) ? 3 : 
										(BURST_MODE_LATENCY_COUNT > 7) ? 7 : BURST_MODE_LATENCY_COUNT;
	// 'h18CF;  // cschai: latency of 3
	// 'h20CF;	// cschai: latency of 4
	// 'h38CF;	// cschai: latency of 7					
	localparam LATENCY_CODE = {2'b00, LATENCY_COUNT[2:0], 11'h0CF};
	
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
	input		flash_rdy;
	output	flash_nreset;
	output	flash_data_highz;
	
	input 	[FLASH_ADDR_WIDTH-1:0] addr_in;
	input		[FLASH_ADDR_WIDTH-1:0] stop_addr_in;
	input		addr_sload;
	input		addr_cnt_en;
	output	done;
	
	input		data_request;
	output	data_ready;
	output	[FLASH_DATA_WIDTH-1:0] data;
	
	output	flash_access_request;
	input		flash_access_granted;

	reg	rcr_addr;
	reg	rcr_write;
	reg	rcr_hold;		  

	wire	[2:0] counter_q;
	wire	[FLASH_ADDR_WIDTH-1:0] addr_counter_q;
	reg	flash_write_reg;
	reg	flash_clk_reg;
	wire	access_counter_cycle;
	wire	access_counter_out;
	  
	parameter	MAX_RCR_WORDS = 8;
	integer		RCR_DATA[MAX_RCR_WORDS-1:0];
	integer		RCR_ADDR[MAX_RCR_WORDS-1:0];
	integer		RCR_WORDS;
	integer		READ_LATENCY;
	parameter	DONT_CARE = 'hDEADBEEF;
	
	wire alt_pfl_data_read;
	alt_pfl_data alt_pfl_data
	(
		.clk(clk),
		.data_request(data_request),
		.data_in(flash_data_in),
		.data_in_ready(current_state_is_read_toggle_high),
		.data_in_read(alt_pfl_data_read),
	
		.data_out(data),
		.data_out_ready(data_ready),
		.data_out_read(addr_cnt_en)
	);
	defparam
		alt_pfl_data.DATA_WIDTH = FLASH_DATA_WIDTH;
	
	initial begin
		if (BURST_MODE_SPANSION==1) begin
			RCR_WORDS = 5;
			READ_LATENCY = 4;
			RCR_DATA[0] 			= 'hAA;
			RCR_ADDR[0] 			= 'h555;
			RCR_DATA[1] 			= 'h55;
			RCR_ADDR[1] 			= 'h2AA;
			RCR_DATA[2] 			= 'hD0;
			RCR_ADDR[2] 			= 'h555;
			RCR_DATA[3] 			= 'h1FC8;
			RCR_ADDR[3] 			= 'h000;
			RCR_DATA[4] 			= 'hF0;
			RCR_ADDR[4] 			= 'h000;
			RCR_DATA[5]				= 'h0;
			RCR_ADDR[5]				= 'h0;
			RCR_DATA[6]				= 'h0;
			RCR_ADDR[6]				= 'h0;
			RCR_DATA[7]				= 'h0;
			RCR_ADDR[7]				= 'h0;
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
			RCR_DATA[5] 		   = 'h0;
			RCR_ADDR[5] 		   = 'h0;
			RCR_DATA[6] 		   = 'h0;
			RCR_ADDR[6] 		   = 'h0;
			RCR_DATA[7] 		   = 'h0;
			RCR_ADDR[7] 		   = 'h0;
		end
		else begin
			RCR_WORDS 			   = 2;
			READ_LATENCY 		   = LATENCY_COUNT;
			RCR_DATA[0] 		   = 'h00600060;
			RCR_ADDR[0]			   = LATENCY_CODE;
			RCR_DATA[1] 		   = 'h00030003;
			RCR_ADDR[1]			   = LATENCY_CODE;
			RCR_DATA[2] 		   = 'h0;
			RCR_ADDR[2] 		   = 'h0;
			//Dummy data to avoid warnings
			RCR_DATA[3] 		   = 'h0;
			RCR_ADDR[3] 		   = 'h0;
			RCR_DATA[4] 		   = 'h0;
			RCR_ADDR[4] 		   = 'h0;
			RCR_DATA[5] 		   = 'h0;
			RCR_ADDR[5] 		   = 'h0;
			RCR_DATA[6] 		   = 'h0;
			RCR_ADDR[6] 		   = 'h0;
			RCR_DATA[7] 		   = 'h0;
			RCR_ADDR[7] 		   = 'h0;
		end
	end

	// State Combination
	wire is_addr_state = current_state_is_addr_low | current_state_is_addr_toggle_high | current_state_is_addr;
	wire is_latency_state = current_state_is_latency_low | current_state_is_latency_toggle_high | current_state_is_latency;
	wire is_read_state = current_state_is_read_low | current_state_is_read_toggle_high | current_state_is_read;
								
	wire [FLASH_ADDR_WIDTH-1:0] virtual_flash_addr;
	wire accross_die = addr_counter_q == {1'b0, {(FLASH_ADDR_WIDTH-1){1'b1}}};
	assign virtual_flash_addr = {addr_counter_q[FLASH_ADDR_WIDTH-1],{(FLASH_ADDR_WIDTH-1){1'b0}}};
	assign flash_addr = current_state_is_rcr ? {addr_counter_q[FLASH_ADDR_WIDTH-1] , RCR_ADDR[counter_q][FLASH_ADDR_WIDTH-2:0]} :
								(is_addr_state || is_latency_state) ? addr_counter_q :						
								virtual_flash_addr;						
	assign flash_data_out = current_state_is_rcr ? RCR_DATA[counter_q][FLASH_DATA_WIDTH-1:0] :
									{DONT_CARE[FLASH_DATA_WIDTH-1:0]};
	assign flash_write = flash_write_reg & current_state_is_rcr & rcr_write;
	assign flash_read = is_latency_state | is_read_state;
	assign flash_data_highz = flash_read;
	assign flash_clk = current_state_is_addr | current_state_is_latency | current_state_is_read;
	assign flash_nadv = ~(current_state_is_reset | is_addr_state | current_state_is_rcr);

	reg flash_nreset_reg;
	assign flash_nreset = flash_nreset_reg;
	always @(posedge clk or negedge nreset)
	begin
		if (~nreset)
			flash_nreset_reg = 0;
		else
			flash_nreset_reg = ~(current_state_is_reset && counter_q == 0);
	end
	
	reg granted;
	reg request;
	reg addr_latched;
	assign flash_select = (current_state_is_die && counter_q == 0) ? 1'b0 : granted;
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
			if (next_state_is_rcr) begin
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
	
	wire counter_cnt_en = current_state_is_rcr ? access_counter_cycle & rcr_hold :
									current_state_is_latency ? 1'b1 :
									access_counter_out; // this is for BURST_RESET + DIE
	wire counter_clear = 	next_state_is_rcr | next_state_is_addr |
									next_state_is_reset ||  next_state_is_die;
	lpm_counter counter
	(
		.clock(clk),
		.sclr(counter_clear),
		.cnt_en(counter_cnt_en),
		.q(counter_q)
	);
	defparam counter.lpm_width=3;

	alt_pfl_counter addr_counter
	(
		.clock(clk),
		.sload(addr_sload),
		.data(addr_in),
		.cnt_en(alt_pfl_data_read & ~addr_latched),
		.q(addr_counter_q)
	);
	defparam addr_counter.WIDTH=FLASH_ADDR_WIDTH;
	
	wire 	[3:0] access_counter_q;
	assign access_counter_out = access_counter_q == ACCESS_CLK_DIVISOR;
	wire access_counter_cnt_en = current_state_is_rcr | current_state_is_reset | current_state_is_dummy | current_state_is_die;
	wire access_counter_clear = access_counter_out | next_state_is_rcr | next_state_is_reset | next_state_is_dummy | next_state_is_die ;
	lpm_counter access_counter
	(
		.clock(clk),
		.sclr(access_counter_clear),
		.cnt_en(access_counter_cnt_en),
		.q(access_counter_q)
	);
	defparam access_counter.lpm_width=4;

	always @(posedge clk or negedge nreset) begin
		if (~nreset)
			flash_write_reg = 0;
		else begin
			if (next_state_is_rcr)
				flash_write_reg = 1;
			else if (next_state_is_wait)
				flash_write_reg = 0;
			else if (current_state_is_rcr && access_counter_out)
				flash_write_reg = ~flash_write_reg;
		end
	end
	assign access_counter_cycle = access_counter_out && ~flash_write_reg;

	always @ (posedge clk or negedge nreset) begin
		if (~nreset)
			addr_latched = 0;
		else if (addr_sload)
			addr_latched = 1;
		else if (next_state_is_latency)
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
	
	// STATE MACHINE
	reg current_state_is_wait;
	reg current_state_is_die;
	reg current_state_is_reset;
	reg current_state_is_rcr;
	reg current_state_is_dummy;
	reg current_state_is_addr_low;
	reg current_state_is_addr_toggle_high;
	reg current_state_is_addr;
	reg current_state_is_latency_low;
	reg current_state_is_latency_toggle_high;
	reg current_state_is_latency;
	reg current_state_is_read_low;
	reg current_state_is_read_toggle_high;
	reg current_state_is_read;
	
	wire reset_state_machine = ~data_request | ~granted | ~current_state_machine_active;
	// WAIT 
	wire next_state_is_wait = current_state_is_wait? 1'b0 : reset_state_machine;
	always @ (posedge clk) begin
		current_state_is_wait = reset_state_machine;
	end
	// DIE
	wire next_state_is_die = (current_state_is_wait & addr_latched & granted & data_request) |
										((current_state_is_read_low | current_state_is_read_toggle_high | current_state_is_read) & 
										((accross_die & alt_pfl_data_read) | addr_latched));
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_reset)
			current_state_is_die = 1'b0;
		else begin
			if (~current_state_is_die) begin
				current_state_is_die = next_state_is_die;
			end
		end
	end
	// RESET
	wire next_state_is_reset = current_state_is_die & access_counter_out & (counter_q == 3'd3);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_rcr) 
			current_state_is_reset = 1'b0;
		else begin
			if (~current_state_is_reset) begin
				current_state_is_reset = next_state_is_reset;
			end
		end
	end
	// RCR
	wire next_state_is_rcr = current_state_is_reset & access_counter_out & (counter_q == 3'd3);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_dummy)
			current_state_is_rcr = 1'b0;
		else begin
			if (~current_state_is_rcr) begin
				current_state_is_rcr = next_state_is_rcr;
			end
		end
	end
	// DUMMY
	wire next_state_is_dummy = current_state_is_rcr & (counter_q == RCR_WORDS-1) & access_counter_cycle & rcr_hold;
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_addr_low | next_state_is_addr_toggle_high)
			current_state_is_dummy = 1'b0;
		else begin
			if (~current_state_is_dummy) begin
				current_state_is_dummy = next_state_is_dummy;
			end
		end
	end
	// ADDR_LOW
	wire next_state_is_addr_low = current_state_is_dummy & access_counter_out & (FLASH_BURST_EXTRA_CYCLE != 0);
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_addr_low = 1'b0;
		else begin
			current_state_is_addr_low = next_state_is_addr_low;
		end
	end
	// ADDR_TOGGLE_HIGH
	wire next_state_is_addr_toggle_high = (current_state_is_dummy & access_counter_out & (FLASH_BURST_EXTRA_CYCLE == 0)) |
														current_state_is_addr_low;
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_addr_toggle_high = 1'b0;
		else begin
			current_state_is_addr_toggle_high = next_state_is_addr_toggle_high;
		end
	end
	// ADDR
	wire next_state_is_addr = current_state_is_addr_toggle_high;
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_addr = 1'b0;
		else begin
			current_state_is_addr = next_state_is_addr;
		end
	end
	// LATENCY_LOW
	wire next_state_is_latency_low = (current_state_is_addr & (FLASH_BURST_EXTRA_CYCLE != 0)) |
													(current_state_is_latency & (counter_q != READ_LATENCY-1) & (FLASH_BURST_EXTRA_CYCLE != 0));
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_latency_low = 1'b0;
		else begin
			current_state_is_latency_low = next_state_is_latency_low;
		end
	end
	// LATENCY_TOGGLE_HIGH
	wire next_state_is_latency_toggle_high = (current_state_is_addr & (FLASH_BURST_EXTRA_CYCLE == 0)) |
															current_state_is_latency_low |
															(current_state_is_latency & (counter_q != READ_LATENCY-1) & (FLASH_BURST_EXTRA_CYCLE == 0));
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_latency_toggle_high = 1'b0;
		else begin
			current_state_is_latency_toggle_high = next_state_is_latency_toggle_high;
		end
	end
	// LATENCY
	wire next_state_is_latency = current_state_is_latency_toggle_high;
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_latency = 1'b0;
		else begin
			current_state_is_latency = next_state_is_latency;
		end
	end
	// READ_LOW
	wire next_state_is_read_low = (current_state_is_latency & (counter_q == READ_LATENCY-1) & (FLASH_BURST_EXTRA_CYCLE != 0)) |
											(current_state_is_read & ~next_state_is_die & (FLASH_BURST_EXTRA_CYCLE != 0));
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_read_low = 1'b0;
		else begin
			current_state_is_read_low = next_state_is_read_low;
		end
	end
	// READ_TOGGLE_HIGH
	wire next_state_is_read_toggle_high = (current_state_is_latency & (counter_q == READ_LATENCY-1) & (FLASH_BURST_EXTRA_CYCLE == 0)) |
														(current_state_is_read_low & ~next_state_is_die) |
														(current_state_is_read & ~next_state_is_die & (FLASH_BURST_EXTRA_CYCLE == 0));
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_die | next_state_is_read)
			current_state_is_read_toggle_high = 1'b0;
		else begin
			if (~current_state_is_read_toggle_high) begin
				current_state_is_read_toggle_high = next_state_is_read_toggle_high;
			end
		end
	end
	// READ
	wire next_state_is_read = (current_state_is_read_toggle_high & ~next_state_is_die & alt_pfl_data_read);
	always @ (posedge clk) begin
		if (reset_state_machine)
			current_state_is_read = 1'b0;
		else begin
			current_state_is_read = next_state_is_read;
		end
	end 
	
	reg current_state_machine_active;
	reg next_state_machine_active;
	always @ (*) begin
		case (current_state_machine_active)
			1'b0:
				next_state_machine_active = 1'b1;
			1'b1:
				next_state_machine_active = 1'b1;
			default:
				next_state_machine_active = 1'b0;
		endcase
	end
	always @ (negedge nreset or posedge clk) begin
		if (~nreset)
			current_state_machine_active = 1'b0;
		else
			current_state_machine_active = next_state_machine_active;
	end
			
	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
					value = value >> 1;
		end
	endfunction
endmodule
