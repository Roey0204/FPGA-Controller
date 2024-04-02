module alt_pfl_cfg_rsu_wd(
clk,
nreset,
fpga_conf_done,
fpga_nstatus,
pfl_nreconfigure,
watchdog_reset,
watchdog_timed_out
);

	parameter	RSU_WATCHDOG_COUNTER = 100000000;
	parameter 	COUNTER_WIDTH =(log2(RSU_WATCHDOG_COUNTER)); 
	
	input	clk;
	input	nreset;
	input	fpga_conf_done;
	input	fpga_nstatus;
	input	pfl_nreconfigure;
	input	watchdog_reset;
	
	output	watchdog_timed_out;
	
	reg	watchdog_reset_reg;
	
	reg [1:0] current_state;
	reg [1:0] next_state;	
	parameter WD_IDLE = 0;
	parameter WD_COUNTING = 1;
	parameter WD_TIMEOUT = 2;
	parameter WD_SAME	= 3;
	
	wire [COUNTER_WIDTH - 1:0] timeout;	
	wire	timeout_high;
	
	assign watchdog_timed_out = current_state == WD_TIMEOUT;
	
	initial begin
		current_state = WD_IDLE;
	end
	
	always @(nreset, fpga_nstatus, fpga_conf_done, current_state, timeout_high, watchdog_reset, pfl_nreconfigure, watchdog_reset_reg) begin
		if(~nreset || ~fpga_nstatus || ~fpga_conf_done || (watchdog_reset_reg ^ watchdog_reset))
			next_state = WD_IDLE;
		else begin
			case(current_state)
				WD_IDLE: 
					next_state = WD_COUNTING;
				WD_COUNTING: 
					if (timeout_high) begin
						next_state = WD_TIMEOUT;
					end
					else begin 
						next_state = WD_SAME;
					end
				WD_TIMEOUT: 
					next_state = WD_SAME;
				default: 
					next_state = WD_IDLE;
			endcase
		end
	end
	
	// toggle the watchdog reset condition
	always @ (posedge clk) begin
		watchdog_reset_reg = watchdog_reset;
	end
	
	lpm_counter watchdog_counter (
		.clock(clk),
		.cnt_en(current_state == WD_COUNTING),
		.sclr((watchdog_reset_reg ^ watchdog_reset) || current_state == WD_IDLE || ~pfl_nreconfigure),
		.q(timeout)
	);
	defparam watchdog_counter.lpm_width = COUNTER_WIDTH;
	assign timeout_high = timeout[COUNTER_WIDTH - 1];
	
	always @(posedge clk) begin
		if (next_state == WD_SAME)
			current_state = current_state;
		else
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
