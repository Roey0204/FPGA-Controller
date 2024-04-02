// SPR:372839 - this embedded create_clock assignment provides a clock assignment for the PMA testbus.
//  -The PMA testbus is treated as a clock by the tool, since it drives the clock port on registers that are being used for edge detection circuitry, 
//  -Note that the frequency assignment is somewhat arbitrary (matching nominal reconfig_clk frequency), since the testbus is effectively asyncrhonous.
//  force language to Verilog 2001 to avoid errors for ALTERA_ATTRIBUTE syntax if using Verilog 1995
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
(* ALTERA_ATTRIBUTE = " -name SDC_STATEMENT \"create_clock -name alt_cal_edge_detect_ff0_clk -period 20 [get_pins -compatibility_mode *|*pd*_det\|alt_edge_det_ff0\|clk]\"; -name SDC_STATEMENT \"create_clock -name alt_cal_edge_detect_ff0q_clk -period 20 [get_pins -compatibility_mode *|*pd*_det\|alt_edge_det_ff0\|q]\"; -name SDC_STATEMENT \"create_clock -name alt_cal_edge_detect_ff1_clk -period 20 [get_pins -compatibility_mode *|*pd*_det\|alt_edge_det_ff1\|clk]\"; -name SDC_STATEMENT \"create_clock -name alt_cal_edge_detect_ff1q_clk -period 20 [get_pins -compatibility_mode *|*pd*_det\|alt_edge_det_ff1\|q]\"; -name SDC_STATEMENT \"set_clock_groups -asynchronous -group [get_clocks {alt_cal_edge_detect_ff0_clk}]\"; -name SDC_STATEMENT \"set_clock_groups -asynchronous -group [get_clocks {alt_cal_edge_detect_ff0q_clk}]\"; -name SDC_STATEMENT \"set_clock_groups -asynchronous -group [get_clocks {alt_cal_edge_detect_ff1_clk}]\"; -name SDC_STATEMENT \"set_clock_groups -asynchronous -group [get_clocks {alt_cal_edge_detect_ff1q_clk}]\"; suppress_da_rule_internal=\"C101,C103,C104,C106,D101,R105\"" *) module alt_cal_edge_detect_mm (
	pd_edge,
	reset,
	testbus
);
output pd_edge;
input reset;
input testbus;

wire pd_xor;
wire pd_posedge;
wire pd_negedge;
assign pd_xor = ~(pd_posedge ^ pd_negedge);

dffeas ff2 (
.clk (pd_xor),
.d (1'b1),
.asdata (1'b1),
.clrn (~reset),
.aload (1'b0),
.q (pd_edge),
.sload (1'b0),
.sclr (1'b0),
.ena (1'b1)
);

dffeas alt_edge_det_ff0 (
.clk (testbus),
.d (1'b1),
.asdata (1'b0),
.clrn (1'b1),
.aload (reset),
.q (pd_posedge),
.sload (1'b0),
.sclr (1'b0),
.ena (1'b1)
);

dffeas alt_edge_det_ff1 (
.clk (~testbus),
.d (1'b0),
.asdata (1'b1),
.clrn (1'b1),
.aload (reset),
.q (pd_negedge),
.sload (1'b0),
.sclr (1'b0),
.ena (1'b1)
);

endmodule

(* ALTERA_ATTRIBUTE = "-name SDC_STATEMENT \"set_false_path -from [get_cells -compatibility_mode *\|alt_cal_channel\[*\]] \";-name SDC_STATEMENT \"set_false_path -from [get_cells -compatibility_mode *\|alt_cal_busy] \";suppress_da_rule_internal=\"C101,C103,C104,C106,D101\";-name MESSAGE_DISABLE \"19017\"" *) module alt_cal_mm (
	clock,
	reset,
	start,
	transceiver_init,
	busy,
	dprio_addr,
	quad_addr,
	dprio_dataout,
	dprio_datain,
	dprio_wren,
	dprio_rden,
	dprio_busy,
	retain_addr,
	remap_addr,
	testbuses,
	cal_error
);
	parameter sim_model_mode = "FALSE";
	parameter lpm_type = "alt_cal_mm";
	parameter lpm_hint = "UNUSED";

	parameter number_of_channels = 4;
	parameter channel_address_width = 2;
	parameter sample_length = 8'd100;

	input clock;				// reconfig clk
	input reset;				// reconfig reset (if applicable)
	input transceiver_init; // begin kickstart operation
	input start;				// disconnect for now?
	output busy;				// output to alt4gxb_reconfig's busy, and to reconfig_togxb bus
	output [15:0] dprio_addr;		// mux into alt_dprio
	output [8:0] quad_addr;
	output [15:0] dprio_dataout;		// mux into alt_dprio
	input [15:0] dprio_datain;		// from alt_dprio
	output dprio_wren;			// mux into alt_dprio
	output dprio_rden;			// mux into alt_dprio
	input dprio_busy;			// from alt_dprio
	output retain_addr;			// to alt_dprio to skip the addr frame on writes
	input [11:0] remap_addr;		// from the logical channel address remapper registers
	input [(number_of_channels*4)-1:0] testbuses;		// input from reconfig_fromgxb bus, should be number_of_channels * 4
	output [(number_of_channels-1):0] cal_error;

	assign cal_error = {(number_of_channels-1){1'b0}};

parameter IDLE			= 5'd0;
parameter CH_WAIT		= 5'd1;
parameter TESTBUS_SET		= 5'd2;
parameter OFFSETS_PDEN_RD	= 5'd3;
parameter OFFSETS_PDEN_WR	= 5'd4;
parameter CAL_PD_WR		= 5'd5;
parameter CAL_RX_RD		= 5'd6;
parameter CAL_RX_WR		= 5'd7;
parameter DPRIO_WAIT		= 5'd8;
parameter SAMPLE_TB		= 5'd9;
parameter TEST_INPUT		= 5'd10;
parameter CH_ADV		= 5'd12;
parameter DPRIO_READ		= 5'd14;
parameter DPRIO_WRITE		= 5'd15;
parameter KICK_SETWAIT 		= 5'd11;
parameter KICK_START_RD 	= 5'd13;
parameter KICK_START_WR 	= 5'd16;
parameter KICK_PAUSE 		= 5'd17;
parameter KICK_DELAY_OC   = 5'd18;
parameter TESTBUS_ON_RD   = 5'd19;
parameter TESTBUS_ON_WR   = 5'd20;
parameter TESTBUS_OFF_RD   = 5'd21;
parameter TESTBUS_OFF_WR   = 5'd22;

localparam TESTBUS_ENABLE = 1'b1; // set RPDOF_TEST to 1'b1 to enable the testbus
localparam RECAL_MAX_ATTEMPTS = 2'd3; // recalibrate up to 3 times if we get any knob 'maxed out'

// p0addr is from cbx_dcfifo_low_latency_stratixii.cpp
reg	p0addr/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */;
wire powerup;
assign powerup = p0addr;

	wire [15:0] addr;

   reg [16:0] 	delay_oc_count;
	reg [4:0] state;
	reg [4:0] ret_state;
	reg alt_cal_busy;
	reg [11:0] address;
	reg [15:0] dataout;
	reg write_reg;
	reg read;
	reg did_dprio;
	reg done/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */;
	reg [9:0] alt_cal_channel;
	reg quad_done;
	reg powerdown_done/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */;
	reg kick_done/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */;
	reg powerup_done/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */;

	reg cal_en;
	reg do_recal;
	reg [1:0] recal_counter/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */; 
	reg [7:0] counter;
	reg [7:0] dprio_save;
	reg dprio_reuse;
	reg [4:0] cal_rx_lr, cal_rx_lr_l;
	reg [3:0] cal_pd0, cal_pd90, cal_pd180, cal_pd270;
	reg [3:0] cal_pd0_l, cal_pd90_l, cal_pd180_l, cal_pd270_l;
	reg [3:0] cal_done, cal_inc;
	reg rx_done, rx_inc;
	wire [7:0] cal_rx;
	wire [15:0] cal_pd;
	wire [3:0] ch_testbus;
	reg  [3:0] ch_testbus0q, ch_testbus1q;
	wire [3:0] int_pd0, int_pd90, int_pd180, int_pd270;
	wire [3:0] src_pd0, src_pd90, src_pd180, src_pd270;
	wire [4:0] avg_pd0, avg_pd90, avg_pd180, avg_pd270;
	wire [5:0] avg_cal_rx;
	wire kickstart_done;

	assign busy = alt_cal_busy;
	assign cal_rx = (cal_rx_lr[4] == 1'b0) ? {4'd0, 4'hF - cal_rx_lr[3:0]} : {cal_rx_lr[3:0], 4'd0};
	assign src_pd0 = (rx_done == 1'b0 ? cal_rx_lr[4:1] : cal_pd0);
	assign src_pd90 = (rx_done == 1'b0 ? cal_rx_lr[4:1] : cal_pd90);
	assign src_pd180 = (rx_done == 1'b0 ? cal_rx_lr[4:1] : cal_pd180);
	assign src_pd270 = (rx_done == 1'b0 ? cal_rx_lr[4:1] : cal_pd270);
	assign int_pd0 = (src_pd0[3] == 1'b0 ? (4'hF - src_pd0) : {1'b0, src_pd0[2:0]});
	assign int_pd90 = (src_pd90[3] == 1'b0 ? (4'hF - src_pd90) : {1'b0, src_pd90[2:0]});
	assign int_pd180 = (src_pd180[3] == 1'b0 ? (4'hF - src_pd180) : {1'b0, src_pd180[2:0]});
	assign int_pd270 = (src_pd270[3] == 1'b0 ? (4'hF - src_pd270) : {1'b0, src_pd270[2:0]});
	assign cal_pd = {int_pd0, int_pd90, int_pd180, int_pd270};
	assign avg_pd0 = cal_pd0 + cal_pd0_l;
	assign avg_pd90 = cal_pd90 + cal_pd90_l;
	assign avg_pd180 = cal_pd180 + cal_pd180_l;
	assign avg_pd270 = cal_pd270 + cal_pd270_l;
	assign avg_cal_rx = cal_rx_lr + cal_rx_lr_l;
	assign kickstart_done = powerdown_done & kick_done & powerup_done;


generate
if (number_of_channels == 1) begin: alt_cal_nomux_gen
	assign ch_testbus = testbuses[3:0];
end
else begin: alt_cal_mux_gen
	lpm_mux	testbus_mux (
			.sel (alt_cal_channel[channel_address_width-1:0]),
			.data (testbuses),
			.result (ch_testbus)
			// synopsys translate_off
			,.aclr (),.clken (),.clock ()
			// synopsys translate_on
			);
	defparam
		testbus_mux.lpm_size = number_of_channels,
		testbus_mux.lpm_type = "LPM_MUX",
		testbus_mux.lpm_width = 4,
		testbus_mux.lpm_widths = channel_address_width;
end
endgenerate
	
	reg kickstart_ch;
	reg [1:0] channel_backup;

	assign dprio_dataout = dataout;
	assign dprio_wren = write_reg;
	assign dprio_rden = read;
	assign dprio_addr = {kickstart_ch, alt_cal_channel[1:0], address[11:0]};
	assign quad_addr = {1'b0, alt_cal_channel[9:2]};
	assign retain_addr = 1'b0;

// {pd_0,pd_1,pd_0_p,pd_1_p} == 0110 == positive solid edge
// {pd_0,pd_1,pd_0_p,pd_1_p} == 1001 == negative solid edge
// look for (pd_0 ^ pd_0_p) & (pd_1 ^ pd_1_p) for solid edges
reg [3:0] pd_0, pd_1;
reg [3:0] pd_0_p, pd_1_p;
wire [3:0] solid_edges = (pd_0 ^ pd_0_p) & (pd_1 ^ pd_1_p);
wire [3:0] data_e;
reg  [3:0] data_e0q, data_e1q;
wire samp_reset = (state == DPRIO_WRITE) ? 1'b1 : 1'b0;
reg [3:0] ignore_solid;
wire [3:0] data_solid = solid_edges & (~ignore_solid);

alt_cal_edge_detect_mm pd0_det (
	.pd_edge (data_e[0]),
	.reset (samp_reset),
	.testbus (ch_testbus[0])
);
alt_cal_edge_detect_mm pd90_det (
	.pd_edge (data_e[1]),
	.reset (samp_reset),
	.testbus (ch_testbus[1])
);
alt_cal_edge_detect_mm pd180_det (
	.pd_edge (data_e[2]),
	.reset (samp_reset),
	.testbus (ch_testbus[2])
);
alt_cal_edge_detect_mm pd270_det (
	.pd_edge (data_e[3]),
	.reset (samp_reset),
	.testbus (ch_testbus[3])
);

// synchronize edge detection output into the reconfig clock domain 
always @ (posedge clock) begin
	if (reset) begin
		data_e0q     <= 4'b0;
		data_e1q     <= 4'b0;
		ch_testbus0q <= 4'b0;
		ch_testbus1q <= 4'b0;
	end else begin
		data_e0q     <= data_e;
		data_e1q     <= data_e0q;
		ch_testbus0q <= ch_testbus[3:0];
		ch_testbus1q <= ch_testbus0q;
	end
end
  
// edges is a level, and is used in the state machine, which is on reconfig clock
wire [3:0] edges = data_e1q | data_solid;

// synopsys translate_off
initial
begin
    delay_oc_count = 16'h0000;
	state = 5'h00;
	ret_state = 5'h00;
	alt_cal_busy = 1'b0;
	address = 12'h000;
	dataout = 16'h0000;
	write_reg = 1'b0;
	read = 1'b0;
	did_dprio = 1'b0;
	done = 1'b0;
	alt_cal_channel = 10'h000;
	quad_done = 1'b0;
	powerdown_done = 1'b0;
	kick_done = 1'b0;
	powerup_done = 1'b0;

	cal_en = 1'b0;
	counter = 8'h00;
	dprio_save = 8'h00;
	dprio_reuse = 1'b0;
	cal_rx_lr = 5'h00;
	cal_rx_lr_l = 5'h00;
	cal_pd0 = 4'h0;
	cal_pd90 = 4'h0;
	cal_pd180 = 4'h0;
	cal_pd270 = 4'h0;
	cal_pd0_l = 4'h0;
	cal_pd90_l = 4'h0;
	cal_pd180_l = 4'h0;
	cal_pd270_l = 4'h0;
	cal_done = 4'h0;
	cal_inc = 4'h0;
	rx_done = 1'b0;
	rx_inc = 1'b0;
	kickstart_ch = 1'b0;
	channel_backup = 2'b00;
	pd_0 = 4'h0;
	pd_1 = 4'h0;
    pd_0_p = 4'h0;
    pd_1_p = 4'h0;
    ignore_solid = 4'h0;
    recal_counter   = 2'b0;
end
// synopsys translate_on


	always @(posedge clock) begin
		p0addr <= 1'b1;
		if (reset == 1'b1) begin
			state <= IDLE;
			ret_state <= IDLE;
			alt_cal_busy <= 1'b0;
			address <= 12'd0;
			dataout <= 16'd0;
			write_reg <= 1'b0;
			read <= 1'b0;
			did_dprio <= 1'b0;
//			done <= 1'b0; // pull out of the reset loop so reset will not automatically restart offset cancellation
			alt_cal_channel <= 10'd0;
			
			cal_en <= 1'b0;
			cal_rx_lr <= 5'h00;
			cal_rx_lr_l <= 5'h00;
			{cal_pd0, cal_pd90, cal_pd180, cal_pd270} <= {16'h0000};
			{cal_pd0_l, cal_pd90_l, cal_pd180_l, cal_pd270_l} <= {16'h0000};
			{rx_done, rx_inc} <= {2{1'd0}};
			{cal_done, cal_inc} <= {2{4'd0}};
			counter <= 8'd0;
			dprio_save <= 8'd0;
			dprio_reuse <= 1'b0;
			ignore_solid <= 4'd0;
			powerdown_done <= 1'b0;
			kick_done <= 1'b0;
			powerup_done <= 1'b0;
			quad_done <= 1'b0;
			do_recal <= 1'b0;
			recal_counter <= 2'b0;
		end
		else begin
			case (state)
			IDLE: begin
					cal_en <= 1'b0;
					alt_cal_channel <= 10'd0;
					// -the kickstart IP will run before offset cancellation
					if ((~kickstart_done & powerup == 1'b1 & done == 1'b0) || transceiver_init == 1'b1) begin
						// reset all the kickstart flags (for case where transceiver_init == 1'b1)
						powerdown_done <= 1'b0;
						kick_done <= 1'b0; 
						powerup_done <= 1'b0;
						quad_done <= 1'b0;
						state <= KICK_SETWAIT;
						alt_cal_busy <= 1'b1;
					end
					else if ((kickstart_done & powerup == 1'b1 & done == 1'b0) || start == 1'b1) begin
						state <= CH_WAIT;
						alt_cal_busy <= 1'b1;
					end
					else begin
						state <= IDLE;
						alt_cal_busy <= 1'b0;
					end
				end
			KICK_SETWAIT: begin // wait one cycle for address_pres_reg to respond
					counter <= 8'd5; // wait at least 100ns -> 5 clock cycles @ 50 MHZ (20ns)
					state <= KICK_START_RD;
				end
				
			KICK_START_RD: begin
					if (remap_addr[11:0] == 12'hFFF) begin
						state <= CH_ADV;
					end else begin
						if (powerdown_done && ~kick_done) begin // we are doing the kickstart operation 
							kickstart_ch <= 1'b0;
							address <= 12'h803;	// NPP table 31
							dataout[10:7] <= 4'b1001;
						end else begin //if (~powerdown_done || ~powerup_done) begin // powerdown and powerup read from the same reg
							alt_cal_channel[1:0] <= 2'b10;
							channel_backup <= alt_cal_channel[1:0]; // non-blocking, this will grab the original channel value
							address <= 12'h0; // NPP table 75
							kickstart_ch <= 1'b1;
							quad_done <= 1'b1; // we will have successfully powered down a quad - we can advance to the next quad
						end 
						read <= 1'b0;
						did_dprio <= 1'b0;
						state <= DPRIO_READ;
						ret_state <= KICK_START_WR;
					end
				end
			KICK_START_WR: begin
					if (~powerdown_done) begin // priority encoded
						dataout <= {1'b0, dprio_datain[14], 2'b0, 1'b1, 11'b0}; // bit 11 = powerdown, bit 14 = loopback (disable loopback)
						quad_done <= 1'b1;
						ret_state <= CH_ADV;
					end else if (~kick_done) begin // kick start
						// data is pre-set in the previous state
						dataout <= {dprio_datain[15:11], dataout[10:7], dprio_datain[6:0]};
						if (dataout[10:7] == 4'b1001) begin
							ret_state <= KICK_PAUSE;
						end else begin
							ret_state <= CH_ADV;
						end
					end else begin //if (~ powerup_done) begin
						dataout <= {1'b0, dprio_datain[14], 2'b0, 1'b0, 11'b0}; // bit 11 = powerdown, bit 14 = loopback (disable loopback)
						quad_done <= 1'b1;
						ret_state <= CH_ADV;
					end 
					write_reg <= 1'b0;
					did_dprio <= 1'b0;
					state <= DPRIO_WRITE;
				end
				
			KICK_PAUSE: begin
					if (|counter) begin
						counter <= counter - 1'b1;
						state <= KICK_PAUSE;
					end else begin
						dataout[10:7] <= 4'b0000;
						state <= KICK_START_WR;
					end
				end
			KICK_DELAY_OC: begin
					if (|delay_oc_count) begin
						delay_oc_count <= delay_oc_count - 1'b1;
						state <= KICK_DELAY_OC;
					end else begin
						kick_done <= 1'b1;
						state <= KICK_SETWAIT; // now go back and do powerup
					end
				end
			CH_WAIT: begin
					{cal_pd0, cal_pd90, cal_pd180, cal_pd270} <= {16'h0000};
					{cal_pd0_l, cal_pd90_l, cal_pd180_l, cal_pd270_l} <= {16'h0000};
					cal_rx_lr <= 5'h00;
					cal_rx_lr_l <= 5'h00;
					{rx_done, rx_inc} <= {2{1'd0}};
					{cal_done, cal_inc} <= {2{4'd0}};
					ignore_solid <= 4'hF;
					counter <= 8'd0;
					dprio_reuse <= 1'b0;
					do_recal <= 1'b0;
					state <= TESTBUS_SET;
				end
			TESTBUS_SET: begin
					if (remap_addr[11:0] == 12'hFFF) begin
						state <= CH_ADV;
					end else begin
						state <= TESTBUS_ON_RD; // channel exists - always turn on the testbus (regardless of the channel - since later, we always turn it off afterwards)
						cal_en <= ~cal_en;
					end
				end
			TESTBUS_ON_RD: begin // the assembler default for the testbus should be 'off'
					address <= 12'hC05; // NPP table 41
					read    <= 1'b0;
					did_dprio <= 1'b0;
					state     <= DPRIO_READ;
					ret_state <= TESTBUS_ON_WR;
			end
			TESTBUS_ON_WR: begin
					address <= 12'hC05;
					dataout <= {dprio_datain[15:6], TESTBUS_ENABLE, dprio_datain[4:0]}; // turn on the testbus here (bit [5])
					write_reg <= 1'b0;
					did_dprio <= 1'b0;
					state     <= DPRIO_WRITE;
					ret_state <= OFFSETS_PDEN_RD;
			end
			OFFSETS_PDEN_RD: begin
					address <= 12'hC02;	// NPP table 38
					read <= 1'b0;
					did_dprio <= 1'b0;
					state <= DPRIO_READ;
					ret_state <= OFFSETS_PDEN_WR;
				end
			OFFSETS_PDEN_WR: begin
					dataout <= {dprio_datain[15:7], cal_en, dprio_datain[5:0]};
					write_reg <= 1'b0;
					did_dprio <= 1'b0;
					// if the channel doesn't need calibration, skip it
					cal_en <= (dprio_datain[2] == 1'b0 ? 1'b0 : cal_en);
					state <= (dprio_datain[2] == 1'b0 ? TESTBUS_OFF_RD: DPRIO_WRITE); // if the channel is not an RX, we still should turn off testbus in this case
					ret_state <= (cal_en == 1'b1 ? CAL_PD_WR : TESTBUS_OFF_RD); // instead, go to 'turn off testbus state' here for case when cal_en=1'b0, because this means we are done with this channel
				end
			CAL_PD_WR: begin
					address <= 12'hC06;	// NPP table 42
					if (&cal_done) begin // check each PD result at the end - if maxed out, either +70 or -70mV, return it back to 0
						if (&cal_pd[2:0] || &cal_pd[6:4] || &cal_pd[10:8] || &cal_pd[14:12]) begin // pd values maxed out if lower 3 bits are all 1, fourth bit is 'sign' bit only
							do_recal       <= 1'b1; 
						end else begin
							do_recal       <= 1'b0; 
						end
						dataout[3:0]   <= (&cal_pd[2:0])   ? 4'b0000 : cal_pd[3:0];
						dataout[7:4]   <= (&cal_pd[6:4])   ? 4'b0000 : cal_pd[7:4];
						dataout[11:8]  <= (&cal_pd[10:8])  ? 4'b0000 : cal_pd[11:8];
						dataout[15:12] <= (&cal_pd[14:12]) ? 4'b0000 : cal_pd[15:12];
					end else begin
						dataout <= {cal_pd};
					end
					write_reg <= 1'b0;
					did_dprio <= 1'b0;
					state <= DPRIO_WRITE;
					ret_state <= CAL_RX_RD;
				end
			CAL_RX_RD: begin
					address <= 12'hC01;	// NPP table 37
					read <= 1'b0;
					did_dprio <= 1'b0;
					dprio_reuse <= 1'b1;
					state <= (dprio_reuse == 1'b1 ? CAL_RX_WR : DPRIO_READ);
					ret_state <= CAL_RX_WR;
				end
			CAL_RX_WR: begin
					address <= 12'hC01;	// NPP table 37
					if (rx_done && (&cal_rx[3:0] || &cal_rx[7:4])) begin // we are done and value is maxed out (either +max or -max) - revert to '0'
						dataout  <= {dprio_save[7:3], 8'b0, dprio_save[2:0]};
						do_recal <= 1'b1;
					end else begin
						dataout <= {dprio_save[7:3], cal_rx, dprio_save[2:0]};
					end
					write_reg <= 1'b0;
					did_dprio <= 1'b0;
					state <= DPRIO_WRITE;
					ret_state <= DPRIO_WAIT;
					counter <= 8'd0;
				end
			DPRIO_WAIT: begin
					if (counter == 8'd6) begin
						counter <= 8'd0;
						state <= SAMPLE_TB;
						pd_0_p <= pd_0;
						pd_1_p <= pd_1;
						{pd_0, pd_1} <= 8'hFF;
					end
					else begin
						counter <= counter + 8'd1;
						state <= DPRIO_WAIT;
					end
				end
			SAMPLE_TB: begin
					pd_0 <= pd_0 & ~ch_testbus1q;
					pd_1 <= pd_1 & ch_testbus1q;
					if (counter == sample_length) begin
			            state   <= TEST_INPUT;
			            if (do_recal && (recal_counter < RECAL_MAX_ATTEMPTS)) begin // if we need to recalibrate, reset all the counters and restart calibration procedure
							{cal_pd0_l, cal_pd90_l, cal_pd180_l, cal_pd270_l} <= {16'h0000};
							cal_rx_lr           <= 5'h00;
							cal_rx_lr_l         <= 5'h00;
							{rx_done, rx_inc}   <= {2{1'd0}};
							{cal_done, cal_inc} <= {2{4'd0}};
							ignore_solid        <= 4'hF;
							counter             <= 8'd0;
							do_recal            <= 1'b0;
							recal_counter       <= recal_counter + 1'b1; // increment the recalibration counter
						end 
					end
					else begin
						counter <= counter + 8'd1;
						state <= SAMPLE_TB;
					end
				end
			TEST_INPUT: begin
					if ({rx_done, cal_done} == 5'b11111) begin
						state <= TESTBUS_SET;
					end
					else begin
						state <= CAL_PD_WR;
					end

					if (rx_done == 1'b0) begin
						if (edges[0] | edges[2]) begin
							ignore_solid <= 4'hF;
							if (rx_inc == 1'b0) begin
								cal_rx_lr_l <= cal_rx_lr;
								rx_inc <= 1'b1;
								cal_rx_lr <= 5'b11111;
							end
							else begin
								cal_rx_lr <= avg_cal_rx[5:1];
								rx_done <= 1'b1;	//done, state <= testbus_set
							end
						end
						else if ((cal_rx_lr == 5'b11111 && rx_inc == 1'b0) ||
					       		(cal_rx_lr == cal_rx_lr_l && rx_inc == 1'b1)) begin
							rx_done <= 1'b1;	//error
							ignore_solid <= 4'hF;
							cal_rx_lr <= rx_inc ? cal_rx_lr : 5'b11111;
						end
						else begin
							cal_rx_lr <= cal_rx_lr + (rx_inc ? 5'b11111 : 5'b00001);
							ignore_solid <= 4'h0;
						end
					end
					
					if (rx_done && cal_done[0] == 1'b0) begin
						if (edges[0]) begin
							cal_inc[0] <= 1'b1;
							ignore_solid[0] <= 1'b1;
							if (cal_inc[0] == 1'b0) begin
								cal_pd0_l <= cal_pd0;
								cal_pd0 <= 4'hF;
							end
							else begin
								cal_pd0 <= avg_pd0[4:1];
								cal_done[0] <= 1'b1;	//done
							end
						end
						else if ((cal_pd0 == 4'hF && cal_inc[0] == 1'b0) ||
					       		(cal_pd0 == cal_pd0_l && cal_inc[0] == 1'b1)) begin
							cal_done[0] <= 1'b1;		//error
							ignore_solid[0] <= 1'b1;
							cal_pd0 <= cal_inc[0] ? cal_pd0 : 4'h0;
						end
						else begin
							cal_pd0 <= cal_pd0 + (cal_inc[0] ? 4'hF : 4'h1);
							ignore_solid[0] <= 1'b0;
						end
					end

					if (rx_done && cal_done[1] == 1'b0) begin
						if (edges[1]) begin
							cal_inc[1] <= 1'b1;
							ignore_solid[1] <= 1'b1;
							if (cal_inc[1] == 1'b0) begin
								cal_pd90_l <= cal_pd90;
								cal_pd90 <= 4'hF;
							end
							else begin
								cal_pd90 <= avg_pd90[4:1];
								cal_done[1] <= 1'b1;	//done
							end
						end
						else if ((cal_pd90 == 4'hF && cal_inc[1] == 1'b0) ||
					       		(cal_pd90 == cal_pd90_l && cal_inc[1] == 1'b1)) begin
							cal_done[1] <= 1'b1;		//error
							ignore_solid[1] <= 1'b1;
							cal_pd90 <= cal_inc[1] ? cal_pd90 : 4'h0;
						end
						else begin
							cal_pd90 <= cal_pd90 + (cal_inc[1] ? 4'hF : 4'h1);
							ignore_solid[1] <= 1'b0;
						end
					end

					if (rx_done && cal_done[2] == 1'b0) begin
						if (edges[2]) begin
							cal_inc[2] <= 1'b1;
							ignore_solid[2] <= 1'b1;
							if (cal_inc[2] == 1'b0) begin
								cal_pd180_l <= cal_pd180;
								cal_pd180 <= 4'hF;
							end
							else begin
								cal_pd180 <= avg_pd180[4:1];
								cal_done[2] <= 1'b1;	//done
							end
						end
						else if ((cal_pd180 == 4'hF && cal_inc[2] == 1'b0) ||
					       		(cal_pd180 == cal_pd180_l && cal_inc[2] == 1'b1)) begin
							cal_done[2] <= 1'b1;		//error
							ignore_solid[2] <= 1'b1;
							cal_pd180 <= cal_inc[2] ? cal_pd180 : 4'h0;
						end
						else begin
							cal_pd180 <= cal_pd180 + (cal_inc[2] ? 4'hF : 4'h1);
							ignore_solid[2] <= 1'b0;
						end
					end

					if (rx_done && cal_done[3] == 1'b0) begin
						if (edges[3]) begin
							cal_inc[3] <= 1'b1;
							ignore_solid[3] <= 1'b1;
							if (cal_inc[3] == 1'b0) begin
								cal_pd270_l <= cal_pd270;
								cal_pd270 <= 4'hF;
							end
							else begin
								cal_pd270 <= avg_pd270[4:1];
								cal_done[3] <= 1'b1;	//done
							end
						end
						else if ((cal_pd270 == 4'hF && cal_inc[3] == 1'b0) ||
					       		(cal_pd270 == cal_pd270_l && cal_inc[3] == 1'b1)) begin
							cal_done[3] <= 1'b1;		//error
							ignore_solid[3] <= 1'b1;
							cal_pd270 <= cal_inc[3] ? cal_pd270 : 4'hF;
						end
						else begin
							cal_pd270 <= cal_pd270 + (cal_inc[3] ? 4'hF : 4'h1);
							ignore_solid[3] <= 1'b0;
						end
					end
				end
            TESTBUS_OFF_RD: begin // turn off the testbus here
					address <= 12'hC05; // NPP table 41
					read    <= 1'b0;
                    did_dprio <= 1'b0;
                    state     <= DPRIO_READ;
                    ret_state <= TESTBUS_OFF_WR;
            end
            TESTBUS_OFF_WR: begin
					address <= 12'hC05;
					dataout <= {dprio_datain[15:6], (TESTBUS_ENABLE ^ 1'b1), dprio_datain[4:0]};
					write_reg <= 1'b0;
					did_dprio <= 1'b0;
					state     <= DPRIO_WRITE;
					ret_state <= CH_ADV;
            end
			CH_ADV: begin
					//if (channel == (number_of_channels - 1)) begin
					if (alt_cal_channel >= (number_of_channels - 1)) begin
						if (kickstart_done) begin
							done <= 1'b1;
							state <= IDLE;
						end else begin
							if (~powerdown_done) begin // we were doing powerdown when we got here
								powerdown_done <= 1'b1;
								alt_cal_channel <= 10'd0; // reset the channel count
								state <= KICK_SETWAIT; // now go back and do the kickstart operation
							end else if (~kick_done) begin // we were doing the kickstart operation when we got here
								delay_oc_count <= 17'd130_000; // 130,000 cycle delay for approx 3ms + 42 ch. kickstart
								alt_cal_channel <= 10'd0; // reset the channel count
								state <= KICK_DELAY_OC; // now go and wait for all kick starts to finish
							end else if (~powerup_done) begin // we were doing powerup when we got here
								powerup_done <= 1'b1;
								state <= IDLE;
								// don't need to reset channel count, it will occur in IDLE
							end
						end
					end else begin
						if (kickstart_done) begin
							alt_cal_channel <= alt_cal_channel + 10'd1;
							state <= CH_WAIT;
						end else begin
							state <= KICK_SETWAIT; 
							if (powerdown_done && ~kick_done) begin
								alt_cal_channel <= alt_cal_channel + 10'd1; // increment to the next channel
							end else begin // if (~powerdown_done || (kick_done && ~powerup_done)) begin
								if (quad_done) begin // check to see if quad powerdown was successful for the quad that the current channel was in
									alt_cal_channel[9:2] <= alt_cal_channel[9:2] + 1'b1; // increment to the next quad - might exceed 'number_of_channels', so update if-condition accordingly
									alt_cal_channel[1:0] <= 2'b00; 
									quad_done <= 1'b0;
								end else begin
									alt_cal_channel <= alt_cal_channel + 10'd1; // increment to the next channel
								end
							end
						end
					end
				end
			DPRIO_READ: begin
					// always first wait for old dprio transactions to end
					// send read command, then wait for data to arrive before continuing
					if(~dprio_busy) begin
						if(did_dprio) begin
							if(read == 1'b0) begin
								state <= ret_state;
								dprio_save <= {dprio_datain[15:11], dprio_datain[2:0]};
							end
							else begin
								if (remap_addr == 12'hfff) begin // invalid channel
									read <= 1'b0;
									state <= CH_ADV;
								end else begin
									read <= 1'b1;
									state <= DPRIO_READ;
								end
							end
						end
						else begin
							read <= 1'b1;
							did_dprio <= 1'b1;
							state <= DPRIO_READ;
						end
					end
					else begin
						// waiting for dprio to finish
						read <= 1'b0;
						state <= DPRIO_READ;
					end
				end
			DPRIO_WRITE: begin
					// always first wait for old dprio transactions to end
					// send write command, then wait for data to be sent before continuing
					if(~dprio_busy) begin
						if(did_dprio) begin
							if(write_reg == 1'b0) begin
								if (kickstart_ch) begin // for those cases where kickstart_ch is high, we return the channel to its backed up state to make sure CH_ADV works properly
									alt_cal_channel[1:0] <= channel_backup[1:0];
									kickstart_ch <= 1'b0;
								end
								state <= ret_state;
							end
							else begin
								if (remap_addr == 12'hfff) begin // invalid channel
									write_reg <= 1'b0;
									state <= CH_ADV;
								end else begin
									write_reg <= 1'b1;
									state <= DPRIO_WRITE;
								end 
							end
						end
						else begin
							write_reg <= 1'b1;
							did_dprio <= 1'b1;
							state <= DPRIO_WRITE;
						end
					end
					else begin
						// waiting for dprio to finish
						write_reg <= 1'b0;
						state <= DPRIO_WRITE;
					end
				end
			default: begin
				state <= IDLE;
				alt_cal_busy <= 1'b0;
				done <= 1'b0;
				end
			endcase
		end
	end

endmodule

