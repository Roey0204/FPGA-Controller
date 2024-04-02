(* ALTERA_ATTRIBUTE = "disable_da_rule=\"C101,C103,C104,R102,R105,D102,D103\"" *) module alt_aeq_ch_adce (  
  i_clock, 
  i_reset_n, 
  i_start,
  i_adce_done,
  i_adce_continuous,
  o_busy0q, 
  o_adce_cal_busy0q, 
  i_recal,
  i_disable,
  o_shutdown0q,
  o_state, // debug and simulation purposes
  o_eqout0q,
  i_testbus, 
  o_testbus_sel0q,
  o_lf_not_found0q, 
  o_hf_not_found0q,
  o_conv_error0q,
  o_timeout0q,
  i_dprio_busy, 
  i_dprio_in, 
  o_dprio_data0q, // should be able to remove the flops from data to save logic use (control signals already pipelined)
  o_dprio_addr0q, 
  o_dprio_wren0q, 
  o_dprio_rden0q
);
//********************************************************************************
// PARAMETERS
//********************************************************************************
parameter STABILIZE_COUNT = 8'd100;
parameter WRITE_DELAY_COUNT = 4'd3;  // should only be 2 or 3 at max
parameter DIVIDE_COUNT_MAX = 6'd63;  // maximum
parameter RADCE_HFLCK      = 15'b0011_0010_1110_101; // settings for RADCE_HFLCK CRAM settings
parameter RADCE_LFLCK      = 15'b0011_0011_1101_100; // settings for RADCE_LFLCK CRAM settings
parameter USE_HW_CONV_DET  = 1'b0;  // use hardware convergence detect macro if set to 1'b1 - else, default to soft ip.
parameter TIMEOUT_COUNT     = 16'd50000; // timeout value for soft convergence detection in clock cycles

// state declarations
parameter ST_IDLE          = 6'd0;
parameter ST_PDB_RD        = 6'd1;
parameter ST_PDB_WR        = 6'd2;
parameter ST_ADAPT_RD      = 6'd3;
parameter ST_ADAPT_WR      = 6'd4;

parameter ST_HF_CONV_RD    = 6'd5;
parameter ST_HF_CONV_WR    = 6'd6;
parameter ST_LF_CONV_RD    = 6'd7;
parameter ST_LF_CONV_WR    = 6'd8;

parameter ST_RX_PWRDN_RD   = 6'd9;
parameter ST_RX_PWRDN_WR   = 6'd10;
parameter ST_OFFSET_UP_RD  = 6'd11;
parameter ST_OFFSET_UP_WR  = 6'd12;
parameter ST_RESET_READ    = 6'd13;
parameter ST_RESET_WRITE   = 6'd14;

parameter ST_CAL_HF_LOW         = 6'd15;
parameter ST_CAL_HF_LOWMID     = 6'd16;
parameter ST_CAL_HF_ZERO = 6'd17;
parameter ST_CAL_HF_HIGHMID     = 6'd18;
parameter ST_CAL_HF_INNER_LOOP   = 6'd19;

parameter ST_CAL_LF_LOW         = 6'd20;
parameter ST_CAL_LF_LOWMID     = 6'd21;
parameter ST_CAL_LF_ZERO = 6'd22;
parameter ST_CAL_LF_HIGHMID     = 6'd23;
parameter ST_CAL_LF_INNER_LOOP   = 6'd24;

parameter ST_LOOP_FINAL       = 6'd25;
parameter ST_RX_PWRUP_RD      = 6'd26;
parameter ST_RX_PWRUP_WR      = 6'd27;
parameter ST_EQS_SET          = 6'd28;
parameter ST_RESTART_READ     = 6'd29;
parameter ST_RESTART_WRITE    = 6'd30;
parameter ST_STABILIZE        = 6'd31;
parameter ST_LF_STABILIZE     = 6'd32;

parameter ST_DPRIO_READ     = 6'd33;
parameter ST_DPRIO_WRITE    = 6'd34;

parameter ST_CAL_HF_FINAL = 6'd35;
parameter ST_CAL_LF_FINAL = 6'd36;
parameter ST_CHECK_KNOB   = 6'd37;
parameter ST_CHECK_CONV   = 6'd38;
parameter ST_CONV_ERROR1  = 6'd39;
parameter ST_CONV_ERROR2  = 6'd40;
parameter ST_CONV_ERROR3  = 6'd41;

parameter ST_DISABLE_EQCTRL_WR = 6'd42;
parameter ST_DISABLE_PDB_RD    = 6'd43;
parameter ST_DISABLE_PDB_WR    = 6'd44;
parameter ST_DISABLE_ADAPT_RD  = 6'd45;
parameter ST_DISABLE_ADAPT_WR  = 6'd46;

localparam TOGGLECOUNT_WIDTH = 8;
//********************************************************************************
// DECLARATIONS
//********************************************************************************
  input             i_clock;
  input             i_reset_n;
  input             i_start;
  input             i_adce_done;
  input             i_adce_continuous;
  input             i_recal;
  input             i_disable;
  input  [7:1]      i_testbus;
  input             i_dprio_busy;
  input [15:0]      i_dprio_in;
  
  output reg [3:0]  o_testbus_sel0q;
  output reg        o_lf_not_found0q;
  output reg        o_hf_not_found0q;
  output reg        o_conv_error0q;
  output reg        o_timeout0q;
  output reg        o_busy0q;
  output reg        o_adce_cal_busy0q;
  output reg        o_shutdown0q;
  output reg [15:0] o_dprio_data0q;
  output reg [9:0]  o_dprio_addr0q;
  output reg        o_dprio_wren0q;
  output reg        o_dprio_rden0q;
  output     [5:0]  o_state;
  output reg [3:0]  o_eqout0q;
  reg [7:2]  testbus0q;
  reg [7:2]  testbus1q;
  reg [3:0]  testbus_sel;
  reg        lf_not_found;
  reg        hf_not_found;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg        conv_error;
  reg        timeout;
  reg        busy;
  reg        adce_cal_busy;
  reg        shutdown;
  reg [15:0] dprio_data;
  reg [9:0]  dprio_addr;
  reg        dprio_wren;
  reg        dprio_rden;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"}, syn_encoding = "safe, gray" *)
  reg [5:0] state;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"}, syn_encoding = "safe, gray" *)
  reg [5:0] state_next;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"}, syn_encoding = "safe, gray" *)
  reg [5:0] return_state;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"}, syn_encoding = "safe, gray" *)
  reg [5:0] return_state_next;
  
  wire              updnn;
  
  reg [1:0]         force_recal, force_recal0q;
  reg               sample, sample0q;
  reg               correction, correction0q;
  reg  [2:0]        delay, delay0q;
  reg  [3:0]        eqout;
  reg  [7:3]        eq_knob, eq_knob0q;

  reg               did_dprio, did_dprio0q;
  reg [3:0]         write_delay, write_delay0q;
  
  reg [15:0]        timeout_counter, timeout_counter0q;
  reg [15:0]        cram_reg_0xE, cram_reg_0xE_0q;
  reg [15:0]        cram_reg_0x11, cram_reg_0x11_0q;
  
  // i_clock divider delay regs
  wire [5:0]        divide_count_less_one;
  reg  [5:0]        divide_count, divide_count0q;
  wire [TOGGLECOUNT_WIDTH-1:0] togglecount_gray_async;
  reg  [TOGGLECOUNT_WIDTH-1:0] togglecount_bin_async, togglecount_gray0q, togglecount_gray1q, togglecount_decode;

  reg               toggle_resetn, toggle_resetn0q;
  reg               updnn_0q, updnn_1q;

  reg [5:0] lf_offset, lf_offset0q;
  reg [5:0] hf_offset, hf_offset0q;
  reg lf_found, lf_found0q;
  reg hf_found, hf_found0q;

  reg prev_sample, prev_sample0q;

  wire toggle = (prev_sample0q != sample0q); // we depend only on the level according to ICD

  wire [2:0]        delay_less_one = delay0q - 1'b1;

// synopsys translate_off
initial begin
  state            = ST_IDLE;
  state_next       = ST_IDLE;
  return_state     = ST_IDLE;
  return_state_next= ST_IDLE;
  o_dprio_data0q   = 16'h0;
  o_dprio_addr0q   = 10'h0;
  o_dprio_wren0q   = 1'b0;
  o_dprio_rden0q   = 1'b0;
  did_dprio0q      = 1'b0;
  o_busy0q         = 1'b0;
  o_shutdown0q     = 1'b0;
  o_lf_not_found0q = 1'b0;
  o_hf_not_found0q = 1'b0;
  conv_error       = 1'b0;
  o_conv_error0q   = 1'b0;
  timeout          = 1'b0;
  o_timeout0q      = 1'b0;
  divide_count0q   = DIVIDE_COUNT_MAX;
  cram_reg_0xE_0q  = 16'b0;
  cram_reg_0x11_0q = 16'b0;
  timeout_counter0q= TIMEOUT_COUNT;
  correction0q     = 1'b0;
  write_delay0q    = WRITE_DELAY_COUNT;
  sample0q         = 1'b0;
  o_testbus_sel0q  = 4'b0000;
  toggle_resetn0q  = 1'b0;
  updnn_0q         = 1'b0; // sync across domain - double flop
  updnn_1q         = 1'b0;
  lf_found0q       = 1'b0;
  hf_found0q       = 1'b0;
  lf_offset0q      = 6'b0;
  hf_offset0q      = 6'b0;
  prev_sample0q    = 1'b0;
  testbus0q        = 6'b0;
  testbus1q        = 6'b0;
  force_recal      = 2'b0;
  force_recal0q    = 2'b0;
  delay            = 3'b100;
  delay0q          = 3'b100;
  eqout            = 4'b0;
  o_eqout0q        = 4'b0;
  eq_knob          = 5'b11111;
  eq_knob0q        = 5'b11111;
end
// synopsys translate_on

//********************************************************************************
// Sequential Logic
//********************************************************************************
  always @ (posedge i_clock or negedge i_reset_n) begin
    if(~i_reset_n) begin
      state            <= ST_IDLE;
      return_state     <= ST_IDLE;
      o_dprio_data0q   <= 16'h0;
      o_dprio_addr0q   <= 10'h0;
      o_dprio_wren0q   <= 1'b0;
      o_dprio_rden0q   <= 1'b0;
      did_dprio0q      <= 1'b0;
      o_busy0q         <= 1'b0;
      o_adce_cal_busy0q<= 1'b0;
      o_shutdown0q     <= 1'b0;
      o_lf_not_found0q <= 1'b0;
      o_hf_not_found0q <= 1'b0;
      o_conv_error0q   <= 1'b0;
      o_timeout0q      <= 1'b0;
      divide_count0q   <= DIVIDE_COUNT_MAX;
      cram_reg_0xE_0q  <= 16'b0;
      cram_reg_0x11_0q <= 16'b0;
      timeout_counter0q<= TIMEOUT_COUNT;
      correction0q     <= 1'b0;
      write_delay0q    <= WRITE_DELAY_COUNT;
      sample0q         <= 1'b0;
      o_testbus_sel0q  <= 4'b0000;
      toggle_resetn0q  <= 1'b0;
      updnn_0q         <= 1'b0; // sync across domain - double flop
      updnn_1q         <= 1'b0;
      testbus0q        <= 6'b0;
      testbus1q        <= 6'b0;
      lf_found0q       <= 1'b0;
      hf_found0q       <= 1'b0;
      lf_offset0q      <= 6'b0;
      hf_offset0q      <= 6'b0;
      prev_sample0q    <= 1'b0;
      force_recal0q    <= 2'b0;
      delay0q          <= 3'b00;
      o_eqout0q        <= 4'b0;
      eq_knob0q        <= 5'b11111;
      togglecount_gray0q <= {TOGGLECOUNT_WIDTH{1'b0}};
      togglecount_gray1q <= {TOGGLECOUNT_WIDTH{1'b0}};
    end else begin
      state            <= state_next;
      return_state     <= return_state_next;
      o_dprio_data0q   <= dprio_data;
      o_dprio_addr0q   <= dprio_addr;
      o_dprio_wren0q   <= dprio_wren;
      o_dprio_rden0q   <= dprio_rden;
      did_dprio0q      <= did_dprio;
      o_busy0q         <= busy;
      o_adce_cal_busy0q<= adce_cal_busy;
      o_shutdown0q     <= shutdown;
      o_lf_not_found0q <= lf_not_found;
      o_hf_not_found0q <= hf_not_found;
      o_conv_error0q   <= conv_error;
      o_timeout0q      <= timeout;
      divide_count0q   <= divide_count;
      cram_reg_0xE_0q  <= cram_reg_0xE;
      cram_reg_0x11_0q <= cram_reg_0x11;
      timeout_counter0q<= timeout_counter;
      correction0q     <= correction;
      write_delay0q    <= write_delay;
      sample0q         <= sample;
      o_testbus_sel0q  <= testbus_sel;
      toggle_resetn0q  <= toggle_resetn;
      updnn_0q         <= updnn;  // sync across domain - double flop
      updnn_1q         <= updnn_0q;
      testbus0q        <= i_testbus[7:2];
      testbus1q        <= testbus0q;
      lf_found0q       <= lf_found;
      hf_found0q       <= hf_found;
      lf_offset0q      <= lf_offset;
      hf_offset0q      <= hf_offset;
      prev_sample0q    <= prev_sample;
      force_recal0q    <= force_recal;
      delay0q          <= delay;
      o_eqout0q        <= eqout;
      eq_knob0q        <= eq_knob;
      togglecount_gray0q <= togglecount_gray_async;
      togglecount_gray1q <= togglecount_gray0q;
    end
  end  

//********************************************************************************
// Combinational Logic
//********************************************************************************  
  // rename to updnn
  assign updnn         = i_testbus[1]; // select is used to change between lf and hf
  assign o_state       = state;
  
  assign divide_count_less_one = (divide_count0q == 6'b0) ? DIVIDE_COUNT_MAX : (divide_count0q - 1'b1);

  // edge detection for testbus
  always @ (posedge updnn or negedge toggle_resetn0q) begin
    if (~toggle_resetn0q) begin
      togglecount_bin_async <= {TOGGLECOUNT_WIDTH{1'b0}};
    end else begin
      togglecount_bin_async <= togglecount_bin_async + 1'b1; // increment on every posedge of testbus
    end
  end

  // binary to gray encoder
  assign togglecount_gray_async = (togglecount_bin_async >> 1) ^ togglecount_bin_async;

  integer i;
  // gray to binary decoder
  always @ (togglecount_gray1q) begin
    for (i=0; i<TOGGLECOUNT_WIDTH; i=i+1) begin
      togglecount_decode[i] = ^(togglecount_gray1q >> i);
    end
  end


  always @ (*) begin
    // set defaults to avoid latches
    correction        = correction0q;
    dprio_rden        = o_dprio_rden0q;
    dprio_wren        = o_dprio_wren0q;
    dprio_data        = o_dprio_data0q;
    lf_not_found      = o_lf_not_found0q;
    hf_not_found      = o_hf_not_found0q;
    conv_error        = o_conv_error0q;
    timeout           = o_timeout0q;
    busy              = 1'b1;
    adce_cal_busy     = o_adce_cal_busy0q;
    shutdown          = o_shutdown0q;
    dprio_addr        = o_dprio_addr0q;
    did_dprio         = did_dprio0q;
    timeout_counter   = timeout_counter0q;
    sample            = sample0q;
    write_delay       = write_delay0q;
    divide_count      = divide_count0q;
    cram_reg_0xE      = cram_reg_0xE_0q;
    cram_reg_0x11     = cram_reg_0x11_0q;
    return_state_next = return_state;
    state_next        = state;
    testbus_sel       = o_testbus_sel0q;
    toggle_resetn     = toggle_resetn0q;
    lf_found          = lf_found0q;
    hf_found          = hf_found0q;
    lf_offset         = lf_offset0q;
    hf_offset         = hf_offset0q;
    prev_sample       = prev_sample0q;
    force_recal       = force_recal0q;
    eqout             = o_eqout0q;
    eq_knob           = eq_knob0q;
    delay             = delay0q;

    case(state)
      ST_PDB_RD: begin
        dprio_addr   = 10'h00E;  // 0x0E
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_PDB_WR;
      end

      ST_PDB_WR: begin
        // write radce_pdb bit and deassert ADCE reset
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        state_next = ST_DPRIO_WRITE;
        // rgen_bw ([15:14]), rrect_adj ([13:12]), d2a_res ([11:10]), adce_reset ([1]), adce_pdb ([0])
        dprio_data = {2'b10, 2'b00, 2'b00, i_dprio_in[9:2], 1'b0, 1'b1}; // always use continuous mode to start
          
// note - due to the unpredictable nature of the LF offset in hardware, we always recal every time ADCE is run.
//        if(i_recal && ~|force_recal0q) begin
//          return_state_next = ST_RESTART_READ;  // we can skip offset calibraiton for a 'recal', we just need to re-enable ADCE
//        end else begin
          return_state_next = ST_ADAPT_RD;
//        end
      end
            
      ST_ADAPT_RD: begin
        dprio_addr   = 10'h00C;  // 0x0C
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_ADAPT_WR;
      end
      ST_ADAPT_WR: begin 
        // lock_lf_ovd ([15]), seq_sel ([14:13]), adce_adapt ([12]), rgen_set ([11:9]), clk_div ([8:5]), hyst_lf ([4:2]), dc_freq ([1:0])
        dprio_data   = {1'b0, 2'b11, 1'b1, 3'b111, 4'b0011, 3'b000, 2'b00}; 
        dprio_wren   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_WRITE;
        return_state_next = (~i_adce_continuous && USE_HW_CONV_DET) ? ST_HF_CONV_RD : ST_RX_PWRDN_RD;
      end

      ST_HF_CONV_RD: begin
        dprio_addr   = 10'h00F;  // 0x0F
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_HF_CONV_WR;
      end
      ST_HF_CONV_WR: begin // setup the HF convergence detect macro
        dprio_data   = {i_dprio_in[15], RADCE_HFLCK}; // NEED TO DETERMINE SETTINGS 
        dprio_wren   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_WRITE;
        return_state_next = ST_LF_CONV_RD;
      end
      ST_LF_CONV_RD: begin
        dprio_addr   = 10'h010;  // 0x10
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_LF_CONV_WR;
      end
      ST_LF_CONV_WR: begin // setup the LF convergence detect macro
        dprio_data   = {i_dprio_in[15], RADCE_LFLCK}; // NEED TO DETERMINE SETTINGS 
        dprio_wren   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_WRITE;
        return_state_next = ST_RX_PWRDN_RD;
      end
      
      ST_RX_PWRDN_RD: begin
        adce_cal_busy = 1'b1; // buffers are being shut-down, be slightly pessimistic with the status flag
        dprio_addr   = 10'h002;  // 0x02
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_RX_PWRDN_WR;
      end
      ST_RX_PWRDN_WR: begin // write RRX_IB_PDB - powerdown rx buffers for analog offset cancellation
        dprio_data   = {i_dprio_in[15:5], 1'b0, i_dprio_in[3:0]};
//        dprio_data   = {i_dprio_in[15:5], 1'b1, i_dprio_in[3:0]};
        dprio_wren   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_WRITE;
        return_state_next = ST_OFFSET_UP_RD;
      end
      ST_OFFSET_UP_RD: begin
        dprio_addr   = 10'h011;  // 0x011
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_OFFSET_UP_WR;
      end
      ST_OFFSET_UP_WR: begin // upper bits of offsets to maximum - RADCE_DIGITAL
        // enable hysteresis ([6]), upper bits of hf and lf offsets ([5:2]), disable hysteresis bypass for lf, hf path ([1:0])
        dprio_data    = {i_dprio_in[15:7], 1'b1, 4'b0101, 2'b00};//i_dprio_in[1:0]};
        dprio_wren    = 1'b0;
        did_dprio     = 1'b0;
        state_next    = ST_DPRIO_WRITE;
        cram_reg_0x11 = dprio_data; // preserve bits for lf/hf offset scanning states
        return_state_next = ST_RESET_READ;
      end

      ST_RESET_READ: begin
        dprio_addr   = 10'h00E;  // 0x0E
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_RESET_WRITE;
      end
      ST_RESET_WRITE: begin // offsets to maximum, set rgen_bw, rect_adj, d2a_res
        testbus_sel   = 4'b0000;
        dprio_data   = {i_dprio_in[15:10], 8'hEE, i_dprio_in[1:0]};
        dprio_wren   = 1'b0;
        cram_reg_0xE = {i_dprio_in[15:10], 8'hEE, i_dprio_in[1:0]}; // preserve the bits in CRAM reg 0xE so we don't need to keep reading it back - guaranteed to have mutex on alt_dprio while running
        did_dprio    = 1'b0;
        hf_found     = 1'b0;
        lf_found     = 1'b0;
        prev_sample  = updnn_1q; // make sure they are the same so there is no toggle on the first data point
        sample       = updnn_1q;
        lf_offset    = 6'b011110; // -90mV
        hf_offset    = 6'b011110; // -90mV
        state_next   = ST_DPRIO_WRITE;
        return_state_next = ST_CAL_HF_LOW;
      end
      
      ST_CAL_HF_LOW: begin  // -90mV to -34mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel   = 4'b0000;
        if (cram_reg_0xE_0q[9:6] == 4'hf) begin // wrapped around - change upper bits now
          dprio_addr    = 10'h011;
          dprio_data    = {cram_reg_0x11_0q[15:6], 2'b00, cram_reg_0x11_0q[3:0]};
          cram_reg_0x11 = dprio_data;
          correction    = 1'b0;
          state_next    = ST_DPRIO_WRITE;
          return_state_next = ST_CAL_HF_LOWMID;
        end else begin
          if (toggle && cram_reg_0xE_0q[9:6] != 4'b1110) begin // ignore first time (transition from 0xE to 0xD)
            if (hf_found0q) begin
              hf_not_found = ((hf_offset0q[3:0] - cram_reg_0xE_0q[9:6]) > 1'b1); // error out if offset is more than 1 setting away
            end else begin
              hf_found = 1'b1;
              hf_offset = {cram_reg_0x11_0q[5:4], cram_reg_0xE_0q[9:6]};
            end
          end
          prev_sample   = sample0q; // preserve this value for the next time around
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:10],cram_reg_0xE_0q[9:6] - 1'b1, cram_reg_0xE_0q[5:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = hf_not_found ? ST_CAL_LF_LOW : ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_HF_LOW;
        end
      end

      ST_CAL_HF_LOWMID: begin // -32mV to -2mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel   = 4'b0000;
        correction    = 1'b1;
        if (cram_reg_0xE_0q[9:6] == 4'hf && correction0q == 1'b1) begin // wrapped around - change upper bits now
          dprio_addr    = 10'h011;
          dprio_data    = {cram_reg_0x11_0q[15:6], 2'b11, cram_reg_0x11_0q[3:0]};
          cram_reg_0x11 = dprio_data;
          correction    = 1'b0;
          state_next    = ST_DPRIO_WRITE;
          return_state_next = ST_CAL_HF_ZERO;
        end else begin
          if (toggle) begin 
            if (hf_found0q) begin
              hf_not_found = ((hf_offset0q[3:0] - cram_reg_0xE_0q[9:6]) > 1'b1) || // error out if offset is more than 1 setting away
                             ((hf_offset0q == 6'b010000) && (cram_reg_0xE_0q[9:6] != 4'hf)); // previous boundary crossing
            end else begin
              hf_found = 1'b1;
              hf_offset = {cram_reg_0x11_0q[5:4], cram_reg_0xE_0q[9:6]};
            end
          end
          prev_sample   = sample0q; // preserve this value for the next time around
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:10],cram_reg_0xE_0q[9:6] - 1'b1, cram_reg_0xE_0q[5:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = hf_not_found ? ST_CAL_LF_LOW : ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_HF_LOWMID;
        end
      end

      ST_CAL_HF_ZERO: begin // 0mV, begin move to +2mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel      = 4'b0000;
        if (correction) begin
          dprio_addr    = 10'h011;
          dprio_data    = {cram_reg_0x11_0q[15:6], 2'b10, cram_reg_0x11_0q[3:0]};
          cram_reg_0x11 = dprio_data;
          correction    = 1'b0;
          state_next         = ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_HF_HIGHMID;
        end else begin
          if (toggle) begin
            if (hf_found0q) begin
              hf_not_found = (hf_offset0q != 6'b000000); // error out if offset is more than 1 setting away
            end else begin
              hf_found = 1'b1;
              hf_offset = {cram_reg_0x11_0q[5:4], cram_reg_0xE_0q[9:6]};
            end
          end
          prev_sample   = sample0q; // preserve this value for the next time around
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:10], 4'b0000, cram_reg_0xE_0q[5:0]};
          cram_reg_0xE  = dprio_data;
          correction    = 1'b1;
          state_next         = hf_not_found ? ST_CAL_LF_LOW : ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_HF_ZERO;
        end
      end

      ST_CAL_HF_HIGHMID: begin // +2mV to +32mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel     = 4'b0000;
        if (cram_reg_0xE_0q[9:6] == 4'b0 && correction0q == 1'b1) begin // wrapped around - we are done
          dprio_addr    = 10'h011;
          dprio_data    = {cram_reg_0x11_0q[15:6], 2'b11, cram_reg_0x11_0q[3:0]};
          cram_reg_0x11 = dprio_data;
          correction    =  1'b0;
          state_next    = ST_DPRIO_WRITE;
          return_state_next = ST_CAL_HF_FINAL;
        end else begin
          if (toggle) begin 
            if (hf_found0q) begin
              hf_not_found = ((hf_offset0q[3:0] - cram_reg_0xE_0q[9:6]) > 1'b1) || // error out if offset is more than 1 setting away
                             ((hf_offset0q == 6'b000000) && (cram_reg_0xE_0q[9:6] != 4'h1)); // previous boundary crossing
            end else begin
              hf_found = 1'b1;
              hf_offset = {cram_reg_0x11_0q[5:4], cram_reg_0xE_0q[9:6]};
            end
          end
          prev_sample   = sample0q; // preserve this value for the next time around
          correction    = 1'b1;
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:10],cram_reg_0xE_0q[9:6] + 1'b1, cram_reg_0xE_0q[5:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = hf_not_found ? ST_CAL_LF_LOW : ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_HF_HIGHMID;
        end
      end
      
      ST_CAL_HF_FINAL: begin // +34mV to +90mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        if (cram_reg_0xE_0q[9:6] == 4'hf && correction0q == 1'b1) begin // wrapped around - we are done
          correction    =  1'b0;
          if (~hf_found0q) begin
            hf_not_found = 1'b1;
          end 
          testbus_sel      = 4'b0001;
          state_next = ST_CAL_LF_LOW;
        end else begin
          if (toggle) begin 
            if (hf_found0q) begin
              hf_not_found = ((hf_offset0q[3:0] - cram_reg_0xE_0q[9:6]) > 1'b1) || // error out if offset is more than 1 setting away
                             ((hf_offset0q == 6'b101111) && (cram_reg_0xE_0q[9:6] != 4'h0)); // previous boundary crossing
            end else begin
              hf_found = 1'b1;
              hf_offset = {cram_reg_0x11_0q[5:4], cram_reg_0xE_0q[9:6]};
            end
          end
          testbus_sel   = (cram_reg_0xE_0q[9:6] == 4'hE) ? 4'b0001 : 4'b0000; // stabilize to lf testbus early
          prev_sample   = sample0q; // preserve this value for the next time around
          correction    = 1'b1;
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:10],cram_reg_0xE_0q[9:6] + 1'b1, cram_reg_0xE_0q[5:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = hf_not_found ? ST_CAL_LF_LOW : ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_HF_FINAL;
        end
      end

      ST_CAL_LF_LOW: begin  // -90mV to -34mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel   = 4'b0001;
        correction =  1'b1;
        if (cram_reg_0xE_0q[5:2] == 4'hf && correction0q == 1'b1) begin // wrapped around - change upper bits now
          dprio_addr    = 10'h011;
          dprio_data    = {cram_reg_0x11_0q[15:4], 2'b00, cram_reg_0x11_0q[1:0]};
          cram_reg_0x11 = dprio_data;
          correction =  1'b0;
          state_next    = ST_DPRIO_WRITE;
          return_state_next = ST_CAL_LF_LOWMID;
        end else begin
          if (toggle && cram_reg_0xE_0q[5:2] != 4'b1110) begin // ignore first time
            if (lf_found0q) begin
              lf_not_found = ((lf_offset0q[3:0] - cram_reg_0xE_0q[5:2]) > 1'b1); // error out if offset is more than 1 setting away
            end else begin
              lf_found = 1'b1;
              lf_offset = {cram_reg_0x11_0q[3:2], cram_reg_0xE_0q[5:2]};
            end
          end
          dprio_addr    = 10'h00E;
          prev_sample   = sample0q; // preserve this value for the next time around
          dprio_data    = {cram_reg_0xE_0q[15:6],cram_reg_0xE_0q[5:2] - 1'b1, cram_reg_0xE_0q[1:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = lf_not_found ? ST_LOOP_FINAL: ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_LF_LOW;
        end
      end

      ST_CAL_LF_LOWMID: begin // -32mV to -2mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel      = 4'b0001;
        correction    = 1'b1;
        if (cram_reg_0xE_0q[5:2] == 4'hf && correction0q == 1'b1) begin // wrapped around - change upper bits now
          dprio_addr    = 10'h011;
          dprio_data    = {cram_reg_0x11_0q[15:4], 2'b11, cram_reg_0x11_0q[1:0]};
          cram_reg_0x11 = dprio_data;
          correction    = 1'b0;
          state_next    = ST_DPRIO_WRITE;
          return_state_next = ST_CAL_LF_ZERO;
        end else begin
          if (toggle) begin 
            if (lf_found0q) begin
              lf_not_found = ((lf_offset0q[3:0] - cram_reg_0xE_0q[5:2]) > 1'b1) || // error out if offset is more than 1 setting away
                             ((lf_offset == 6'b010000) && (cram_reg_0xE_0q[5:2] != 4'hf)); // previous boundary crossing
            end else begin
              lf_found = 1'b1;
              lf_offset = {cram_reg_0x11_0q[3:2], cram_reg_0xE_0q[5:2]};
            end
          end
          prev_sample   = sample0q; // preserve this value for the next time around
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:6],cram_reg_0xE_0q[5:2] - 1'b1, cram_reg_0xE_0q[1:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = lf_not_found ? ST_LOOP_FINAL: ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_LF_LOWMID;
        end
      end

      ST_CAL_LF_ZERO: begin // 0mV, +90mV to +34mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel      = 4'b0001;
        if (correction) begin
          dprio_addr    = 10'h011;
          dprio_data    = {cram_reg_0x11_0q[15:4], 2'b10, cram_reg_0x11_0q[1:0]};
          cram_reg_0x11 = dprio_data;
          correction    = 1'b0;
          state_next    = ST_DPRIO_WRITE;
          return_state_next = ST_CAL_LF_HIGHMID;
        end else begin
          if (toggle) begin 
            if (lf_found0q) begin
              lf_not_found = (lf_offset0q != 6'b000000); // error out if offset is more than 1 setting away
            end else begin
              lf_found = 1'b1;
              lf_offset = {cram_reg_0x11_0q[3:2], cram_reg_0xE_0q[5:2]};
            end
          end
          prev_sample   = sample0q; // preserve this value for the next time around
          correction    = 1'b1;
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:6], 4'b0000, cram_reg_0xE_0q[1:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = lf_not_found ? ST_LOOP_FINAL: ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_LF_ZERO;
        end
      end
      
      ST_CAL_LF_HIGHMID: begin // +2mV to +32mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel      = 4'b0001;
        if (cram_reg_0xE_0q[5:2] == 4'h0 && correction0q == 1'b1) begin // wrapped around - we are done
          dprio_addr    = 10'h011;
          dprio_data    = {cram_reg_0x11_0q[15:4], 2'b11, cram_reg_0x11_0q[1:0]};
          cram_reg_0x11 = dprio_data;
          correction    =  1'b0;
          state_next    = ST_DPRIO_WRITE;
          return_state_next = ST_CAL_LF_FINAL;
        end else begin
          if (toggle) begin 
            if (lf_found0q) begin
              lf_not_found = ((lf_offset0q[3:0] - cram_reg_0xE_0q[5:2]) > 1'b1) || // error out if offset is more than 1 setting away
                             ((lf_offset0q == 6'b000000) && (cram_reg_0xE_0q[5:2] != 4'h1)); // previous boundary crossing
            end else begin
              lf_found = 1'b1;
              lf_offset = {cram_reg_0x11_0q[3:2], cram_reg_0xE_0q[5:2]};
            end
          end
          prev_sample   = sample0q; // preserve this value for the next time around
          correction    = 1'b1;
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:6],cram_reg_0xE_0q[5:2] + 1'b1, cram_reg_0xE_0q[1:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = lf_not_found ? ST_LOOP_FINAL: ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_LF_HIGHMID;
        end
      end

      ST_CAL_LF_FINAL: begin // +34mV to +90mV
        did_dprio  = 1'b0;
        dprio_wren = 1'b0;
        testbus_sel      = 4'b0001;
        if (cram_reg_0xE_0q[5:2] == 4'hf && correction0q == 1'b1) begin // wrapped around - we are done
          if (~lf_found0q) begin
            lf_not_found = 1'b1;
          end 
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:6],cram_reg_0xE_0q[5:2], 1'b1, cram_reg_0xE_0q[0]}; // assert reset
          cram_reg_0xE  = dprio_data;
          state_next = ST_DPRIO_WRITE;
          return_state_next = ST_LOOP_FINAL;
        end else begin
          if (toggle) begin 
            if (lf_found0q) begin
              lf_not_found = ((lf_offset0q[3:0] - cram_reg_0xE_0q[5:2]) > 1'b1) || // error out if offset is more than 1 setting away
                             ((lf_offset0q == 6'b101111) && (cram_reg_0xE_0q[5:2] != 4'h0)); // previous boundary crossing
            end else begin
              lf_found = 1'b1;
              lf_offset = {cram_reg_0x11_0q[3:2], cram_reg_0xE_0q[5:2]};
            end
          end
          prev_sample   = sample0q; // preserve this value for the next time around
          correction    = 1'b1;
          dprio_addr    = 10'h00E;
          dprio_data    = {cram_reg_0xE_0q[15:6],cram_reg_0xE_0q[5:2] + 1'b1, cram_reg_0xE_0q[1:0]};
          cram_reg_0xE  = dprio_data;
          state_next         = lf_not_found ? ST_LOOP_FINAL: ST_DPRIO_WRITE;
          return_state_next  = ST_CAL_LF_FINAL;
        end
      end

      ST_LOOP_FINAL: begin
		if ((o_lf_not_found0q || o_hf_not_found0q)) begin
			// bad parts should have been screened by production test - we missed a toggle or saw too many, so re-do the search
			state_next = ST_RESET_READ;
		end else begin
			dprio_addr = 10'h011;  // 0x11 - write back the upper bits of the correct offset
			dprio_data = {cram_reg_0x11_0q[15:6], hf_offset[5:4], lf_offset[5:4], cram_reg_0x11_0q[1:0]};
			did_dprio  = 1'b0;
			dprio_wren = 1'b0;
			state_next = ST_DPRIO_WRITE;
			return_state_next = ST_RX_PWRUP_RD;
		end
      end
      ST_RX_PWRUP_RD: begin
        dprio_addr = 10'h002;  // 0x02
        dprio_rden = 1'b0;
        did_dprio  = 1'b0;
        state_next = ST_DPRIO_READ;
        return_state_next = ST_RX_PWRUP_WR;
      end
      ST_RX_PWRUP_WR: begin
        dprio_data = {i_dprio_in[15:5], 1'b1, i_dprio_in[3:0]};
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        state_next = ST_DPRIO_WRITE;
        return_state_next = ST_EQS_SET;
      end
      ST_EQS_SET: begin
        adce_cal_busy = 1'b0; // buffers are powered up before this state, but be slightly pessimistic with the status flag
        dprio_data = 16'h7FFF;
        dprio_addr = 10'h00B;  // 0x0B
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        state_next = ST_DPRIO_WRITE;
        return_state_next = ST_RESTART_READ;
      end
      ST_RESTART_READ: begin
        dprio_addr = 10'h00E;  // 0x0E
        dprio_rden = 1'b0;
        did_dprio  = 1'b0;
        state_next = ST_DPRIO_READ;
        return_state_next = ST_RESTART_WRITE;
      end
      ST_RESTART_WRITE: begin
       // write back the proper offsets (lower bits)
        dprio_data[15:2] = {i_dprio_in[15:10], hf_offset0q[3:0], lf_offset0q[3:0]};
        if (USE_HW_CONV_DET && ~i_adce_continuous) begin
          dprio_data[1:0] = {1'b0, 1'b1}; // de-assert reset, switch to one-time mode
        end else begin
          dprio_data[1:0] = {1'b0, i_dprio_in[0:0]}; // de-assert reset
        end
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        state_next = ST_DPRIO_WRITE;
        //generate
        // always check for stabilization even in continuous mode
        timeout_counter   = TIMEOUT_COUNT;
        return_state_next = ST_STABILIZE;
        toggle_resetn      = 1'b1; // take edge detection out of reset 
        testbus_sel = 4'b0000;
        //endgenerate
      end

      // we now check the engine itself to determine convergence.  Timeout is 500 us = ~25k clock cycles @ 50MHz 
      ST_STABILIZE: begin // wait for adaptation to finish - values locked in automatically once done is asserted
        if (~|timeout_counter0q || (togglecount_decode >= STABILIZE_COUNT)) begin
          state_next = ST_CHECK_KNOB;
          delay = 3'b100;
          testbus_sel = 4'b0010;
          timeout = ~|timeout_counter0q;
        end else begin 
          state_next = ST_STABILIZE;
          testbus_sel   = 4'b0000;
          timeout_counter = timeout_counter - 1'b1;
        end
      end


      ST_CHECK_KNOB: begin
        testbus_sel = 4'b0010; // check TMXSELAN and TMXSELVN
        // add an 8 cycle delay to make sure the flopped values are updated
        if (|delay0q) begin
          delay      = delay_less_one;
          state_next = ST_CHECK_KNOB;
        end else begin
          testbus_sel = 4'b0000;
          eq_knob     = testbus1q[7:3]; // save knob value
          delay       = 3'b100;
          state_next  = ST_CHECK_CONV;
        end
      end
      
      ST_CHECK_CONV: begin
        testbus_sel = 4'b0000; // check EQCTRLOUT
        // add an 8 cycle delay to make sure the flopped values are updated
        if (|delay0q) begin
          delay      = delay_less_one;
          state_next = ST_CHECK_CONV;
        end else begin
          if (~|testbus1q[7:2] && ~eq_knob[7] && (&eq_knob[6:3])) begin // EQCTRLOUT has tanked - no convergence found
            force_recal = force_recal0q + 1'b1;
            state_next  = &force_recal0q ? ST_CONV_ERROR1 : ST_PDB_RD; // error out if we already tried 3x recalibrating
          end else begin
            state_next  = ST_IDLE; // not bottomed out, return to idle (success!)
            shutdown    = 1'b1;    // success! now place adce into standby mode
          end
        // convergence output
          if (~eq_knob[3]) begin // 'V' 
            if (testbus1q[7:2] >= 6'b110110) begin // setting '111', H4
              eqout = 4'b1111;
            end else if (testbus1q[7:2] >= 6'b101111) begin // setting '110', H3
              eqout = 4'b1110;
            end else if (testbus1q[7:2] >= 6'b100111) begin // setting '100', H2
              eqout = 4'b1101;
            end else if (testbus1q[7:2] >= 6'b000111) begin // setting '001', H1
              eqout = 4'b1100;
            end else begin
              eqout = 4'b1011; // setting H0
            end
          end else if (~eq_knob[4]) begin // 'D'
            if (testbus1q[7:2] >= 6'b011011) begin // setting '011' and up, H0
              eqout = 4'b1011;
            end else begin
              eqout = 4'b1010; // setting M4
            end
          end else if (~eq_knob[5]) begin // 'C'
            if (testbus1q[7:2] >= 6'b011011) begin // setting '011' and up, M3
              eqout = 4'b1001;
            end else begin
              eqout = 4'b1000; // setting M2
            end
          end else if (~eq_knob[6]) begin // 'B'
            if (testbus1q[7:2] >= 6'b101111) begin // setting '110' and up, M1
              eqout = 4'b0111;
            end else if (testbus1q[7:2] >= 6'b101011) begin // setting '101' and up, M0
              eqout = 4'b0110;
            end else begin
              eqout = 4'b0101; // setting L4
            end
          end else if (~eq_knob[7]) begin // 'A'
            if (testbus1q[7:2] >= 6'b110111) begin // setting '111' and up, L3
              eqout = 4'b0100;
            end else if (testbus1q[7:2] >= 6'b101011) begin // setting '110' and up, L2
              eqout = 4'b0011;
            end else if (testbus1q[7:2] >= 6'b100111) begin // setting '100' and up, L1
              eqout = 4'b0010;
            end else if (testbus1q[7:2] >= 6'b011011) begin // setting '011' and up, L0
              eqout = 4'b0001;
            end else begin
              eqout = 4'b0000; // eq tanked - error condition of 0, or off
            end
          end else begin // error
            eqout = 4'b0000; // off
          end
        end
      end
      
      ST_CONV_ERROR1: begin // convergence error, must revert to manual equalization
        conv_error = 1'b1; // flag convergence error
        // write radce_pdb bit and deassert ADCE reset
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        dprio_addr = 10'h00E;  // 0x0E
        state_next = ST_DPRIO_WRITE;
        dprio_data = {cram_reg_0xE_0q[15:1], 1'b1}; // set RADCE_PDB = 1'b1
        return_state_next = ST_CONV_ERROR2;
      end
      
      ST_CONV_ERROR2: begin // write radce_adapt bit to 0 for manual equalization
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        dprio_addr = 10'h00C;  // 0x0C
        state_next = ST_DPRIO_WRITE;
        dprio_data = 16'b0; // set RADCE_ADAPT = 1'b0 - we can just zero out the whole register, since it only affects ADCE settings
        return_state_next = ST_CONV_ERROR3;
      end
      
      ST_CONV_ERROR3: begin // now write eqctrl to setting 14 (out of 16)
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        dprio_addr = 10'h00B;  // 0x0B
        state_next = ST_DPRIO_WRITE;
        dprio_data = {1'b0, 3'b111, 3'b111, 3'b111, 3'b111, 3'b100}; // equivalent to H2 manual equalization
        return_state_next = ST_IDLE;
      end
// in order to disable ADCE and return to manaul EQ control, first set
// EQ*_CTRL back to 0, then set adce_pdb = 1 and adce_adapt = 0.
      ST_DISABLE_EQCTRL_WR : begin
        dprio_data = 16'h0000; // zero out EQ*_CTRL
        dprio_addr = 10'h00B;  // 0x0B
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        state_next = ST_DPRIO_WRITE;
        return_state_next = ST_DISABLE_PDB_RD;
      end
      ST_DISABLE_PDB_RD : begin
        dprio_addr   = 10'h00E;  // 0x0E
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_DISABLE_PDB_WR;
      end

      ST_DISABLE_PDB_WR: begin
        // write radce_pdb bit and deassert ADCE reset
        dprio_wren = 1'b0;
        did_dprio  = 1'b0;
        state_next = ST_DPRIO_WRITE;
        // rgen_bw ([15:14]), rrect_adj ([13:12]), d2a_res ([11:10]), adce_reset ([1]), adce_pdb ([0])
        dprio_data = {i_dprio_in[15:2], 1'b1, 1'b1}; // set adce_reset = 1, and set adce_pdb to 1
        return_state_next = ST_DISABLE_ADAPT_RD;
      end
            
      ST_DISABLE_ADAPT_RD: begin
        dprio_addr   = 10'h00C;  // 0x0C
        dprio_rden   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_READ;
        return_state_next = ST_DISABLE_ADAPT_WR;
      end
      ST_DISABLE_ADAPT_WR: begin 
        // lock_lf_ovd ([15]), seq_sel ([14:13]), adce_adapt ([12]), rgen_set ([11:9]), clk_div ([8:5]), hyst_lf ([4:2]), dc_freq ([1:0])
        dprio_data   = {i_dprio_in[15:13], 1'b0, i_dprio_in[11:0]}; // set adce_adapt to 0 - restore control to manual EQ
        dprio_wren   = 1'b0;
        did_dprio    = 1'b0;
        state_next   = ST_DPRIO_WRITE;
        return_state_next = ST_IDLE;
      end
// the DPRIO states should really be in their own state machine, but we will leave this for now since it works
      ST_DPRIO_READ: begin
        // always first wait for old dprio transactions to end
        // send read command, then wait for data to arrive before continuing
        if(~i_dprio_busy) begin
          if(did_dprio0q) begin
            if(o_dprio_rden0q == 1'b0) begin
              state_next = return_state;
              did_dprio  = 1'b0;
            end else begin
              dprio_rden = 1'b1;
              state_next = ST_DPRIO_READ;
            end
          end else begin
            dprio_rden = 1'b1;
            did_dprio  = 1'b1;
            state_next = ST_DPRIO_READ;
          end
        end else begin
          // waiting for dprio to finish
          dprio_rden = 1'b0;
          state_next = ST_DPRIO_READ;
        end
      end
      ST_DPRIO_WRITE: begin
        // always first wait for old dprio transactions to end
        // send write command, then wait for data to be sent before continuing
        if(~i_dprio_busy) begin
          divide_count = divide_count_less_one;
          if(did_dprio0q) begin
            if(o_dprio_wren0q == 1'b0) begin
              if (return_state == ST_CAL_LF_LOWMID || return_state == ST_CAL_LF_ZERO || return_state == ST_CAL_LF_HIGHMID || 
                  return_state == ST_CAL_LF_INNER_LOOP || return_state == ST_CAL_LF_LOW || return_state == ST_CAL_HF_LOWMID ||
                  return_state == ST_CAL_HF_ZERO || return_state == ST_CAL_HF_INNER_LOOP || return_state == ST_CAL_HF_LOW ||
                  return_state == ST_CAL_HF_HIGHMID || return_state == ST_CAL_HF_FINAL || return_state == ST_CAL_LF_FINAL) begin
                if(~|divide_count0q) begin
                  write_delay = write_delay0q - 1'b1;
                end
                if(~|write_delay0q) begin
                  did_dprio  = 1'b0; // clear the status
                  sample = updnn_1q; // sample after the delay
                  state_next = return_state;
                end
              end else begin
                did_dprio  = 1'b0; // clear the status
                state_next = return_state;
              end
            end else begin
              dprio_wren = 1'b1;
              state_next = ST_DPRIO_WRITE;
            end
          end else begin
            dprio_wren = 1'b1;
            did_dprio  = 1'b1;
            state_next = ST_DPRIO_WRITE;
          end
        end else begin
          // waiting for dprio to finish
          dprio_wren   = 1'b0;

          state_next   = ST_DPRIO_WRITE;
          write_delay  = WRITE_DELAY_COUNT;
          divide_count = DIVIDE_COUNT_MAX;
        end
      end
      default: begin //ST_IDLE: begin
        dprio_rden    = 1'b0;
        dprio_wren    = 1'b0;
        toggle_resetn = 1'b0;
        testbus_sel  = 4'b0000;
        if(i_start) begin 
          adce_cal_busy = 1'b0;
          eqout         = 4'b0;
          eq_knob       = 5'b11111;
          shutdown      = 1'b0;
          force_recal  = 2'b0;
          lf_not_found = 1'b0; // clear out the registers for lf/hf_not_found
          hf_not_found = 1'b0;
          conv_error   = 1'b0; // clear any convergence error that may have occurred
          timeout      = 1'b0; // clear any timeout error that may have occurred
          testbus_sel  = 4'b0000;
          state_next   = ST_PDB_RD; // may need to add a different state for recalibration
          busy         = 1'b1;
        end else if (i_disable) begin
          state_next = ST_DISABLE_EQCTRL_WR;
          busy       = 1'b1;
          adce_cal_busy = 1'b0;
        end else begin
          state_next = ST_IDLE;
          busy       = 1'b0;
          adce_cal_busy = 1'b0;
        end
      end
    endcase
  end

endmodule
