////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG_FPGA
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
// This module contains the PFL configuration FPGA output block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg_fpga (
	clk,
	nreset,

	// Data pins from controller
	flash_data,
	flash_data_ready,
	flash_data_read,
	flash_flags,
	
	// Control pins to FPGA
	fpga_data,
	fpga_dclk
	
)/* synthesis altera_attribute = "SUPPRESS_DA_RULE_INTERNAL=\"c104,c106\""*/;
	parameter DCLK_DIVISOR = 1;
	parameter CONF_DATA_WIDTH = 8;
	parameter CONF_DATA_WIDTH_INDEX = (CONF_DATA_WIDTH == 1) ? 8 : CONF_DATA_WIDTH;
	parameter PFL_RSU_WATCHDOG_ENABLED = 0;
	parameter DCLK_COUNTER_MAX_WIDTH = (CONF_DATA_WIDTH == 32) ? 4 : 3;
	parameter PFL_NEW_COUNT_ALGO = 1;
	parameter DCLK_CREATE_DELAY = 0;
  
	input	clk;
	input	nreset;

	input 	[CONF_DATA_WIDTH_INDEX-1:0] flash_data;
	input		flash_data_ready;
	output	flash_data_read;
	input		[7:0] flash_flags;
	
	output	[CONF_DATA_WIDTH-1:0] fpga_data;
	output	fpga_dclk;
	
	genvar i;
	generate
		if (DCLK_CREATE_DELAY == 0) begin
			assign fpga_dclk = dclk_wire;
		end
		else begin
			wire  [(DCLK_CREATE_DELAY*2)-1:0] fpga_dclk_delay /* synthesis keep */;
			for (i=0; i<(DCLK_CREATE_DELAY*2); i=i+1) begin: DELAY_LOOP
				if (i == 0)
					nand (fpga_dclk_delay[i], dclk_wire, dclk_wire);
				else
					nand (fpga_dclk_delay[i], fpga_dclk_delay[i-1], fpga_dclk_delay[i-1]);
			end
			assign fpga_dclk = fpga_dclk_delay[(DCLK_CREATE_DELAY*2)-1];
		end
	endgenerate
	
	wire dclk_wire;
	wire dclk_compression_out;
	wire flags_compression = (flash_flags[0] | (flash_flags[2] & flash_flags[3])) & !skip_compression;
	wire skip_compression = (CONF_DATA_WIDTH == 8) & !flash_flags[0];
	
	wire shift_load = next_state_is_shift;
	wire shift_enable;
	wire [CONF_DATA_WIDTH_INDEX-1:0] shiftreg_q;
	lpm_shiftreg shiftreg (
			.data(flash_data),
			.clock(clk),
			.enable(shift_enable || shift_load),
			.load(shift_load),
			.q(shiftreg_q)
		);
	defparam shiftreg.lpm_width=CONF_DATA_WIDTH_INDEX, shiftreg.lpm_direction="RIGHT";
	generate
		if (CONF_DATA_WIDTH==1) begin
			// Passive serial output
			assign shift_enable = dclk_compression_out &
											(current_state_is_shift | next_state_is_shift);
		end
		else begin
			// Fast Passive Parallel output
			assign shift_enable = 0;
		end
	endgenerate
	
	// After entering usermode, stop sending clk to dclk pin (in case dclk is dual purpose I/O and for power saving)
	wire enable_dclk = current_state_is_shift;
						
	reg enable_dclk_reg;
	reg fpga_dclk_reg;
	reg [CONF_DATA_WIDTH-1:0] fpga_data_reg;
	wire dclk_pulse;
	wire dclk_divider_reset = next_state_is_shift;
							
	generate
		if (DCLK_DIVISOR==1) begin
			assign dclk_wire = ~clk && enable_dclk_reg && enable_dclk_neg_reg;
			assign fpga_data = fpga_data_reg;
			always @ (posedge clk) begin
				if(current_state_is_shift)
					fpga_data_reg = shiftreg_q[CONF_DATA_WIDTH-1:0];
			end
			always @ (negedge nreset or posedge clk) begin
				if (~nreset)
					enable_dclk_reg = 1'b0;
				else
					enable_dclk_reg = enable_dclk;
			end
			
			// get rid the glitch
			reg enable_dclk_neg_reg;
			always @ (negedge nreset or negedge clk) begin
				if (~nreset)
					enable_dclk_neg_reg = 1'b0;
				else
					enable_dclk_neg_reg = enable_dclk_reg;
			end
			assign dclk_pulse = 1;
		end
		else if (DCLK_DIVISOR>1) begin
			wire [7:0] dclk_divider_q;
			reg dclk_divider_out;
			lpm_counter dclk_divider (
				.clock(clk),
				.sclr(dclk_divider_reset || (dclk_divider_q >= DCLK_DIVISOR - 1)),
				.q(dclk_divider_q)
			);
			defparam dclk_divider.lpm_width=DCLK_DIVISOR + 1;
			always @(posedge clk or posedge dclk_divider_q ) begin
				dclk_divider_out = (dclk_divider_q >= DCLK_DIVISOR-1);
			end
			
			wire dclk_sync;			
			lpm_counter dclk_out (
				.clock(clk),
				.sclr(dclk_divider_reset),
				.cnt_en(dclk_divider_q == (DCLK_DIVISOR-1) || dclk_divider_q == ((DCLK_DIVISOR/2) -1)),
				.q(dclk_sync)				
				);
			defparam dclk_out.lpm_width = 1;			
			assign dclk_pulse = dclk_sync && dclk_divider_out;

			always @ (negedge nreset or posedge clk) begin
				if (~nreset) begin
					fpga_dclk_reg = 0;
					fpga_data_reg = 0;
				end
				else begin
					fpga_dclk_reg = (dclk_sync && enable_dclk);
					fpga_data_reg = shiftreg_q[CONF_DATA_WIDTH-1:0];
				end
			end
			assign dclk_wire = fpga_dclk_reg;
			assign fpga_data = fpga_data_reg;
		end
	endgenerate
	
	wire [DCLK_COUNTER_MAX_WIDTH-1:0] dclk_compression_q;
	assign dclk_compression_out = dclk_pulse && dclk_compression_done;
	
	generate
	if (PFL_NEW_COUNT_ALGO == 1) begin
		wire [3:0] dclk_data_ratio = flash_flags[2]? 
												((CONF_DATA_WIDTH == 8)? 4'd0 :										// S5++ FPPx8	(when compression is enabled)
												((CONF_DATA_WIDTH == 16)? (flash_flags[0] ? 4'd2 : 4'd0) :  // S5++ FPPx16	(when compression and/or encryption is enabled)
												(flash_flags[0] ? 4'd6 : 4'd2))) : 									// S5++ FPPx32	(when compression and/or encryption is enabled)
																																// PS will be taken care by dclk_compression_done checking though PS (seems) is now under FPPx32
												4'd2; 																		// S4--			(when compression and/or encryption is enabled)
		wire dclk_compression_done = (CONF_DATA_WIDTH == 1 | ~flags_compression | dclk_almost_done);
		lpm_counter dclk_compression (
			.clock(clk),
			.cnt_en(dclk_pulse),
			.data(dclk_data_ratio[DCLK_COUNTER_MAX_WIDTH-1:0]),
			.sload(dclk_divider_reset || dclk_compression_out),
			.q(dclk_compression_q)
		);
		defparam 
			dclk_compression.lpm_width=DCLK_COUNTER_MAX_WIDTH,
			dclk_compression.lpm_direction="DOWN";
			
		reg dclk_almost_done;
		always @ (negedge nreset or posedge clk) begin
			if (~nreset)
				dclk_almost_done = 1'b0;
			else begin
				if (dclk_divider_reset | dclk_compression_out)
					dclk_almost_done = 1'b0;
				else if (dclk_compression_q == {(DCLK_COUNTER_MAX_WIDTH){1'b0}} & dclk_pulse)
					dclk_almost_done = 1'b1;
			end
		end
	end
	else begin
		wire [3:0] dclk_data_ratio = flash_flags[2]? 
												((CONF_DATA_WIDTH == 8)? 4'd2 :										// S5++ FPPx8	(when compression is enabled)
												((CONF_DATA_WIDTH == 16)? (flash_flags[0] ? 4'd4 : 4'd2) :  // S5++ FPPx16	(when compression and/or encryption is enabled)
												(flash_flags[0] ? 4'd8 : 4'd4))) : 									// S5++ FPPx32	(when compression and/or encryption is enabled)
																																// PS will be taken care by dclk_compression_done checking though PS (seems) is now under FPPx32
												4'd4; 																		// S4--			(when compression and/or encryption is enabled)
		reg dclk_compression_done /* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
		lpm_counter dclk_compression (
			.clock(clk),
			.cnt_en(dclk_pulse),
			.data(dclk_data_ratio[DCLK_COUNTER_MAX_WIDTH-1:0]),
			.sload(dclk_divider_reset || dclk_compression_out),
			.q(dclk_compression_q)
		);
		defparam 
			dclk_compression.lpm_width=DCLK_COUNTER_MAX_WIDTH,
			dclk_compression.lpm_direction="DOWN";
		
		always @(posedge clk) begin
			if (CONF_DATA_WIDTH!=1 && flags_compression) begin
				if (dclk_divider_reset)
					dclk_compression_done = 0;
				else
					dclk_compression_done = (dclk_compression_q == 1 && ~dclk_pulse) || 
											(dclk_compression_q == 2 && dclk_pulse);
			end
			else begin
				dclk_compression_done = 1;
			end
		end
	end
	endgenerate
	
	reg [7:0] shift_count_q;
	wire shift_count_clear = next_state_is_shift;
	reg shift_almost_done /* synthesis altera_attribute = "-name SUPPRESS_REG_MINIMIZATION_MSG ON" */;
	wire shift_done = dclk_compression_out && shift_almost_done;
	
	always @ (posedge clk) begin
		if (shift_count_clear)
			shift_count_q = 8'h01;
		else if (dclk_compression_out & (current_state_is_shift | next_state_is_shift))
			shift_count_q = {shift_count_q[6:0], 1'b0};
	end
	always @ (posedge clk) begin
		if (CONF_DATA_WIDTH==1) begin
			shift_almost_done = (shift_count_q[7] && ~dclk_compression_out) || (shift_count_q[6] && dclk_compression_out);
		end
		else begin
			shift_almost_done = 1;
		end
	end
	
	assign flash_data_read = flash_data_ready && (current_state_is_wait | (current_state_is_shift & shift_done));

	// STATE MACHINE
	reg current_state_is_init;
	reg current_state_is_wait;
	reg current_state_is_shift;
	wire reset_state_machine = ~current_state_machine_active;
	
	// INIT
	always @ (posedge clk) begin
		current_state_is_init = reset_state_machine;
	end
	// WAIT
	wire next_state_is_wait = (current_state_is_init) |
										(current_state_is_shift & shift_done & ~flash_data_ready);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_shift)
			current_state_is_wait = 1'b0;
		else begin
			if (~current_state_is_wait) begin
				current_state_is_wait = next_state_is_wait;
			end
		end
	end
	// SHIFT
	wire next_state_is_shift = (current_state_is_wait & flash_data_ready) |
										(current_state_is_shift & shift_done & flash_data_ready);
	always @ (posedge clk) begin
		if (reset_state_machine | next_state_is_wait)
			current_state_is_shift = 1'b0;
		else begin
			if (~current_state_is_shift) begin
				current_state_is_shift = next_state_is_shift;
			end
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
	
endmodule
