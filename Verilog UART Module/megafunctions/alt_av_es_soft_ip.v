////////////////////////////////////////////////////////////////////
//
//   ALT_AV_ES_SOFT_IP 
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
//	Version 1.0
//
//
////////////////////////////////////////////////////////////////////


(* altera_attribute = "-name SDC_STATEMENT \"create_clock -name altera_reserved_av_osc_clk -period 22.5 [get_pins *|arriav_oscillator|clkout]; set_max_delay -from [get_clocks altera_reserved_av_osc_clk] -to [get_clocks altera_reserved_av_osc_clk] 10\"" *)
module alt_av_es_soft_ip
(
	pr_ready,
	pr_done,
	pr_error
);
	parameter SLD_NODE_INFO = 6843904;
	parameter SLD_AUTO_INSTANCE_INDEX = "YES";
	parameter INSTANCE_ID = 0;

	// note
	localparam COUNTER_WIDTH = 7;
	localparam [COUNTER_WIDTH-1:0] WAIT_CYCLE = 7'd91; 	// 0 - 91 ==> 92 cycles
																			// STATE_RESET ==> 1 cycle 
																			// STATE_REQ ==> 1 cycle
																			// PR_REQ is a register ==> 1 cycle
																			// Total of 95 cycles as required by ICD
	localparam SKIP_WAIT = 0;
	
	localparam [2:0] STATE_SAME 		= 3'd0;
	localparam [2:0] STATE_RESET 		= 3'd1;
	localparam [2:0] STATE_WAIT 		= 3'd2;
	localparam [2:0] STATE_REQ 		= 3'd3;
	localparam [2:0] STATE_HALT 		= 3'd4;
	localparam [2:0] STATE_DUMMY 		= 3'd7;
	
	// debug
	output pr_ready = dummy_wire[0];
	output pr_done = dummy_wire[1];
	output pr_error = dummy_wire[2];
	
	// Source clock
	wire enable_osc_wire = (current_state == STATE_SAME ||
									current_state == STATE_RESET ||
									current_state == STATE_WAIT ||
									current_state == STATE_REQ ||
									current_state == STATE_DUMMY);
	reg enable_osc_reg;
	always @(posedge int_clk) begin
		enable_osc_reg <= enable_osc_wire;
	end
	wire enable_osc = (enable_osc_wire | enable_osc_reg);
	
	wire int_clk;
	arriav_oscillator arriav_oscillator 
	(
		.oscena(enable_osc),
		.clkout(int_clk)
	);
	
	// PRBLOCK
	reg pr_request_reg;
	always @(posedge int_clk) begin
		if (current_state == STATE_REQ || current_state == STATE_HALT)
			pr_request_reg <= 1'b1;
		else
			pr_request_reg <= 1'b0;
	end
	wire pr_request_wire = (SKIP_WAIT == 1)? 1'b1 : pr_request_reg;
	
	wire [2:0] dummy_wire /* synthesis keep */;
	arriav_prblock arriav_prblock
	(
		.corectl(1'b1),
		.data(16'hFFFF),
		.clk(1'b1),
		.prrequest(pr_request_wire),
		.ready(dummy_wire[0]),
		.done(dummy_wire[1]),
		.error(dummy_wire[2])
	);

	// Counter -- general counter
	reg [COUNTER_WIDTH-1:0] counter_q;
	wire sclr_counter = (next_state == STATE_WAIT);				
	wire en_counter = (current_state == STATE_WAIT);	
	
	lpm_counter counter (
		.clock(int_clk),
		.cnt_en(en_counter),
		.sclr(sclr_counter),
		.q(counter_q)
	);
	defparam
	counter.lpm_type 			= "LPM_COUNTER",
	counter.lpm_direction	= "UP",
	counter.lpm_width 		= COUNTER_WIDTH;
	
	// Transition
	wire done_wait = (counter_q == WAIT_CYCLE);
	
	always @(*) begin
		case (current_state)
			STATE_RESET:
				next_state = STATE_WAIT;
			STATE_WAIT:
				if (done_wait)
					next_state = STATE_REQ;
				else
					next_state = STATE_SAME;
			STATE_REQ:
				next_state = STATE_HALT;
			STATE_HALT:
				next_state = STATE_SAME;
			default:
				next_state = STATE_RESET;
		endcase
	end
	
	reg [2:0] current_state;
	reg [2:0] next_state;
	always @(posedge int_clk) begin
		if (next_state != STATE_SAME)
			current_state <= next_state;
		else
			current_state <= current_state;
	end
	
endmodule
