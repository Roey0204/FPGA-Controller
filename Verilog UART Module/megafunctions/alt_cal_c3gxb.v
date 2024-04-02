module alt_cal_c3gxb (
	clock,
	reset,
	start,
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
	parameter lpm_type = "alt_cal_c3gxb";
	parameter lpm_hint = "UNUSED";

	parameter number_of_channels = 4;
	parameter channel_address_width = 2;
	parameter sample_length = 8'd100;

	input clock;				// reconfig clk
	input reset;				// reconfig reset (if applicable)
	input start;				// disconnect for now?
	output busy;				// output to altgxb_reconfig's busy, and to reconfig_togxb bus
	output [15:0] dprio_addr;		// mux into alt_dprio(address_pres_reg)
	output [8:0] quad_addr; 
	output [15:0] dprio_dataout;		// mux into alt_dprio (dprio_datain)
	input [15:0] dprio_datain;		// from alt_dprio (dprio_dataout)
	output dprio_wren;			// mux into alt_dprio (dprio_wren)
	output dprio_rden;			// mux into alt_dprio (dprio_rden)
	input dprio_busy;			// from alt_dprio (dprio_busy)
	output retain_addr;			// to alt_dprio to skip the addr frame on writes (wren_data)
	input [11:0] remap_addr;		// from the logical channel address remapper registers (quad_address)
	input [(number_of_channels-1):0] testbuses;		// input from reconfig_fromgxb bus
	output [(number_of_channels-1):0] cal_error;

	assign cal_error = {(number_of_channels){1'b0}};

parameter IDLE				=	4'd0;
parameter CH_WAIT			=	4'd1;
parameter TESTBUS_SET		=	4'd2;
parameter OFFSETS_PDEN_RD	=	4'd3;
parameter OFFSETS_PDEN_WR	=	4'd4;
parameter CAL_PD_WR			=	4'd5;
parameter CAL_RX_RD			=	4'd6;
parameter CAL_RX_WR			=	4'd7;
parameter DPRIO_WAIT		=	4'd8;
parameter SAMPLE_TB			=	4'd9;
parameter TEST_INPUT		=	4'd10;
parameter CH_ADV			=	4'd12;
parameter DPRIO_READ		=	4'd14;
parameter DPRIO_WRITE		=	4'd15;

reg	p0addr;
wire powerup;
assign powerup = p0addr;

	wire [15:0] addr;
	
	reg [3:0] state;
	reg [3:0] ret_state;
	reg busy;
	reg [11:0] address;
	reg [15:0] dataout;
	reg write_reg;
	reg read;
	reg did_dprio;
	reg done;
	reg [9:0] channel;
	
	reg cal_en;
	reg [7:0] counter;
	reg [7:0] dprio_save;
	reg dprio_reuse;
	reg [4:0] cal_rx_lr, cal_rx_lr_l;
	reg rx_done, rx_inc;
	wire [7:0] cal_rx;
	wire [0:0] ch_testbus;
	wire [5:0] avg_cal_rx;
	
	assign cal_rx = (cal_rx_lr[4] == 1'b0) ? {4'd0, 4'hF - cal_rx_lr[3:0]} : {cal_rx_lr[3:0], 4'd0};
	assign avg_cal_rx = cal_rx_lr + cal_rx_lr_l;



generate
if (number_of_channels == 1) begin: alt_cal_nomux_gen
	assign ch_testbus = testbuses[0:0];
end
else begin: alt_cal_mux_gen
	lpm_mux	testbus_mux (
			.sel (channel[channel_address_width-1:0]),
			.data (testbuses),
			.result (ch_testbus)
			// synopsys translate_off
			,.aclr (),.clken (),.clock ()
			// synopsys translate_on
			);
	defparam
		testbus_mux.lpm_size = number_of_channels,
		testbus_mux.lpm_type = "LPM_MUX",
		testbus_mux.lpm_width = 1,
		testbus_mux.lpm_widths = channel_address_width;
end
endgenerate
	

	assign dprio_dataout = dataout;
	assign dprio_wren = write_reg;
	assign dprio_rden = read;
	assign dprio_addr = {1'b0, channel[1:0], address[11:0]};
	assign quad_addr = {1'b0, channel[9:2]};
	assign retain_addr = 1'b0;

	
	always @(posedge clock) begin
		p0addr <= 1'b1;
		if (reset == 1'b1) begin
			state <= IDLE;
			ret_state <= IDLE;
			busy <= 1'b0;
			address <= 12'd0;
			dataout <= 16'd0;
			write_reg <= 1'b0;
			read <= 1'b0;
			did_dprio <= 1'b0;
//			done <= 1'b0; // reset should not re-trigger offset cancellation, so remove this from the reset block
			channel <= 10'd0;
			
			cal_en <= 1'b0;
			cal_rx_lr <= 5'h00;
			cal_rx_lr_l <= 5'h00;
			{rx_done, rx_inc} <= {2{1'd0}};
 			counter <= 8'd0;
			dprio_save <= 8'd0;
			dprio_reuse <= 1'b0;
		end
		else begin
			case (state)
			IDLE: begin
					cal_en <= 1'b0;
					channel <= 10'd0;
					if ((powerup == 1'b1 & done == 1'b0) || start == 1'b1) begin
						state <= CH_WAIT;
						busy <= 1'b1;
					end
					else begin
						state <= IDLE;
						busy <= 1'b0;
					end
				end
			CH_WAIT: begin
					cal_rx_lr <= 5'h00;
					cal_rx_lr_l <= 5'h00;
					{rx_done, rx_inc} <= {2{1'd0}};
					counter <= 8'd0;
					dprio_reuse <= 1'b0;
					state <= TESTBUS_SET;
				end
			TESTBUS_SET: begin
					if (remap_addr[11:0] == 12'hFFF) begin
						state <= CH_ADV;
					end
					else begin
						state <= OFFSETS_PDEN_RD;
						cal_en <= ~cal_en;
					end
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
					state <= (dprio_datain[2] == 1'b0 ? CH_ADV : DPRIO_WRITE);
					ret_state <= (cal_en == 1'b1 ? CAL_RX_RD : CH_ADV);
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
					dataout <= {dprio_save[7:3], cal_rx, dprio_save[2:0]};
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
					end
					else begin
						counter <= counter + 8'd1;
						state <= DPRIO_WAIT;
					end
				end
			SAMPLE_TB: begin
					if (counter == sample_length) begin
						counter <= 8'd0;
						state <= TEST_INPUT;
					end
					else begin
						counter <= counter + 8'd1;
						state <= SAMPLE_TB;
					end
				end
			TEST_INPUT: begin
					if (rx_done == 1'b1) begin
						state <= TESTBUS_SET;
					end
					else begin
						state <= CAL_RX_RD;
					end

					if (rx_done == 1'b0) begin
						if (ch_testbus) begin
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
							cal_rx_lr <= rx_inc ? cal_rx_lr : 5'b11111;
						end
						else begin
							cal_rx_lr <= cal_rx_lr + (rx_inc ? 5'b11111 : 5'b00001);
						end
					end
				end
			CH_ADV: begin
					if (channel == (number_of_channels - 1)) begin
						done <= 1'b1;
						state <= IDLE;
					end
					else begin
						done <= 1'b0;
						state <= CH_WAIT;
						channel <= channel + 10'd1;
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
								read <= 1'b1;
								state <= DPRIO_READ;
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
								state <= ret_state;
							end
							else begin
								write_reg <= 1'b1;
								state <= DPRIO_WRITE;
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
				busy <= 1'b0;
				done <= 1'b0;
				end
			endcase
		end
	end

endmodule

