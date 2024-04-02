module alt_aeq_full_adce(  
  i_clock, 
  i_reset_n, 
  o_busy0q, 
  i_calibrate,
  i_recal,
  i_all_ch, 
  i_current_ch,
  i_remap_addr,
  i_shutdown_ch,
  i_disable_ch,
  o_ch_shutdown0q,
  o_ch_disable0q,
  o_lf_not_found0q, 
  o_hf_not_found0q,
  o_conv_error0q,
  o_ch_start0q,
  i_ch_busy, 
  i_ch_lf_not_found, 
  i_ch_hf_not_found, 
  i_ch_conv_error,
  o_logical_ch0q, 
  o_ch_done0q
);

//********************************************************************************
// PARAMETERS
//********************************************************************************
// o_logical_ch ignores the 5th and 6th channels: [1:0] is the channel, [n:2] is the quad address
  parameter N_CH  = 5;
  parameter N_SEL = 3;
  
  parameter ST_IDLE                  = 2'd0;
  parameter ST_ADAPT_LOOPS_WAIT_ADDR = 2'd1;
  parameter ST_ADAPT_LOOPS_START     = 2'd2;
  parameter ST_ADAPT_LOOPS_FINISH    = 2'd3;
 
//********************************************************************************
// Declarations
//********************************************************************************
  input                 i_clock;
  input                 i_reset_n;
  input                 i_calibrate;
  input                 i_recal;
  input                 i_all_ch;
  input  [N_SEL-1:0]    i_current_ch;
  input  [11:0]         i_remap_addr;
  input                 i_shutdown_ch;
  input                 i_disable_ch;

  output reg            o_busy0q/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON" */;
  output reg [N_CH-1:0] o_ch_shutdown0q/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=HIGH" */;
  output reg [N_CH-1:0] o_lf_not_found0q;
  output reg [N_CH-1:0] o_hf_not_found0q;
  output reg [N_CH-1:0] o_conv_error0q;

  output reg [N_CH-1:0] o_ch_done0q/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */;
  output reg [9:0]      o_logical_ch0q/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON" */;
  
// signals for interfacing with the channel-specific state machine
  input                 i_ch_lf_not_found;
  input                 i_ch_hf_not_found;
  input                 i_ch_conv_error;
  input                 i_ch_busy;
  output reg            o_ch_start0q;
  output reg            o_ch_disable0q;

// regs for this module
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [1:0] state;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [1:0] state_next;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg cal_all_ch;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg cal_all_ch0q;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [N_CH-1:0] ch_done;

  reg            busy/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON" */;
  reg [N_CH-1:0] ch_shutdown/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=HIGH" */;
  reg [N_CH-1:0] lf_not_found;
  reg [N_CH-1:0] hf_not_found;
  reg [N_CH-1:0] conv_error;
  
  reg [9:0]      logical_ch/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON" */;
  reg            ch_start;
  reg            ch_disable;
  reg            disable_flag, disable_flag0q;
  
// synopsys translate_off
initial begin
  state            = ST_IDLE;
  state_next       = ST_IDLE;
  cal_all_ch       = 1'b0;
  cal_all_ch0q     = 1'b0;
  ch_done          = {N_CH{1'b0}};
  o_busy0q         = 1'b0;
  o_ch_shutdown0q  = {N_CH{1'b1}};
  ch_shutdown      = {N_CH{1'b1}};
  o_ch_done0q      = {N_CH{1'b0}};
end
// synopsys translate_on

  
//********************************************************************************
// Sequential logic
//********************************************************************************  
always @ (posedge i_clock or negedge i_reset_n) begin
  if (~i_reset_n) begin
    o_busy0q         <= 1'b0;
    o_lf_not_found0q <= {N_CH{1'b0}};
    o_hf_not_found0q <= {N_CH{1'b0}};
    o_conv_error0q   <= {N_CH{1'b0}};
    o_ch_done0q      <= {N_CH{1'b0}};
    o_ch_shutdown0q  <= {N_CH{1'b1}}; // adcestandby is active low
    o_logical_ch0q   <= 10'b0;
    o_ch_start0q     <= 1'b0;
    o_ch_disable0q   <= 1'b0;
    cal_all_ch0q     <= 1'b0;
	disable_flag0q   <= 1'b0;
    state            <= ST_IDLE;
  end else begin
    o_busy0q         <= busy;
    o_lf_not_found0q <= lf_not_found;
    o_hf_not_found0q <= hf_not_found;
    o_conv_error0q   <= conv_error;
    o_ch_done0q      <= ch_done;
    o_ch_shutdown0q  <= ch_shutdown;
    o_logical_ch0q   <= logical_ch;
    o_ch_start0q     <= ch_start;
    o_ch_disable0q   <= ch_disable;
    cal_all_ch0q     <= cal_all_ch;
	disable_flag0q   <= disable_flag;
    state            <= state_next;  
  end
end

//********************************************************************************
// Combinational logic
//********************************************************************************  
// ADCE mode-oriented model
  always @ (*) begin
    // set defaults to avoid latch inferences
    busy         = o_busy0q;
    ch_done      = o_ch_done0q;
    ch_shutdown  = o_ch_shutdown0q;
    ch_start     = o_ch_start0q;
    ch_disable   = o_ch_disable0q;
    lf_not_found = o_lf_not_found0q;
    hf_not_found = o_hf_not_found0q;
    conv_error   = o_conv_error0q;
    cal_all_ch   = cal_all_ch0q;
    logical_ch   = o_logical_ch0q;
	disable_flag = disable_flag0q;
  
    case(state)
      ST_ADAPT_LOOPS_WAIT_ADDR: begin // wait for addres_pres_reg to be ready
        busy       = 1'b1;
        state_next = ST_ADAPT_LOOPS_START;
      end
      ST_ADAPT_LOOPS_START: begin
        if (i_remap_addr == 12'hfff || i_remap_addr[2]) begin // channel 5, 6, or invalid channel has been selected
          ch_start   = 1'b0;
          ch_disable = 1'b0;
          busy       = 1'b1;
          state_next = ST_IDLE;
        end else begin
          ch_start   = ~disable_flag0q;
          ch_disable = disable_flag0q;
          busy       = 1'b1;
          state_next = i_ch_busy ? ST_ADAPT_LOOPS_FINISH : ST_ADAPT_LOOPS_START;
        end
      end
      ST_ADAPT_LOOPS_FINISH: begin
        ch_start   = 1'b0;
        ch_disable = 1'b0;
        busy       = 1'b1;
        if (i_shutdown_ch) begin // we are 'faking' one-time mode - shut down the channel
          ch_shutdown[o_logical_ch0q] = 1'b0;
        end
        if(i_ch_busy) begin
          state_next = ST_ADAPT_LOOPS_FINISH;
        end else begin
          lf_not_found[o_logical_ch0q] = i_ch_lf_not_found;
          hf_not_found[o_logical_ch0q] = i_ch_hf_not_found;
          conv_error[o_logical_ch0q]   = i_ch_conv_error;
          ch_done[o_logical_ch0q]      = 1'b1;
          state_next               = ST_IDLE;
        end
      end
      default: begin //ST_IDLE: begin
        ch_start = 1'b0;
        disable_flag = i_disable_ch;
        if(~cal_all_ch0q && (i_calibrate || i_recal || i_disable_ch)) begin
          if(i_all_ch) begin
            if (i_recal) begin
              ch_done    = {N_CH{1'b0}}; // wipe out the 'done' register so we recal
            end
            cal_all_ch   = 1'b1;
            logical_ch   = 10'd0;
            lf_not_found = {N_CH{1'b0}};
            hf_not_found = {N_CH{1'b0}};
            conv_error   = {N_CH{1'b0}};
            ch_shutdown  = {N_CH{1'b1}}; // adce_standby is active low
          end else begin
            if (i_recal) begin
              ch_done[i_current_ch[N_SEL-1:0]]    = 1'b0; // wipe out the 'done' register so we recal
            end
            logical_ch                            = {{(10-N_SEL){1'b0}}, i_current_ch[N_SEL-1:0]};
            lf_not_found[i_current_ch[N_SEL-1:0]] = 1'b0;
            hf_not_found[i_current_ch[N_SEL-1:0]] = 1'b0;
            conv_error[i_current_ch[N_SEL-1:0]]   = 1'b0;
            ch_shutdown[i_current_ch[N_SEL-1:0]]  = 1'b1; // adce_standby is active low
          end
          state_next = ST_ADAPT_LOOPS_WAIT_ADDR;
          busy       = 1'b1;
        end else if(cal_all_ch0q) begin
          if(o_logical_ch0q < (N_CH - 1'b1)) begin // subtract 1 since channels start from 0
            logical_ch = o_logical_ch0q + 1'd1;
            busy       = 1'b1;
            state_next = ST_ADAPT_LOOPS_WAIT_ADDR;
          end else begin
            logical_ch = 10'd0;
            cal_all_ch = 1'b0;
            busy       = 1'b0;
            state_next = ST_IDLE;
          end
      end else if (i_shutdown_ch) begin
        busy       = 1'b0;
        if (i_all_ch) begin
          ch_shutdown = {N_CH{1'b0}}; // adce_standby is active low
        end else begin
          ch_shutdown[i_current_ch[N_SEL-1:0]] = 1'b0; // shutdown just the one channel - adce_standby is active low
        end
        state_next = ST_IDLE;
        end else begin
          logical_ch = 10'd0;
          cal_all_ch = 1'b0;
          busy       = 1'b0;
          state_next = ST_IDLE;
        end
      end // default
    endcase
  end // always

endmodule
