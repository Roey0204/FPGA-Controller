module alt_aeq_s4(
  reconfig_clk, 
  aclr, 
  calibrate, 
  recalibrate,
  shutdown,
  all_channels, 
  logical_channel_address,
  remap_address,
  quad_address,
  adce_done, // comes from gxb instance
  busy, 
  adce_standby, // output to the RX PMA
  adce_continuous,
  adce_cal_busy,
  
  dprio_busy, 
  dprio_in, 
  dprio_wren, 
  dprio_rden, 
  dprio_addr, 
  dprio_data, 

  eqout,
  timeout,
  testbuses,  // will need to expand to accomodate testbus[7:1]
  testbus_sels
// SHOW_ERRORS option
  , 
  conv_error,
  error
// end SHOW_ERRORS option
 );

//********************************************************************************
// PARAMETERS
//********************************************************************************
  parameter show_errors = "NO";  // "YES" = show errors; anything else = do not show errors
  parameter radce_hflck = 15'b0011_0010_1110_101; // settings for RADCE_HFLCK CRAM settings
  parameter radce_lflck = 15'b0011_0011_1101_100; // settings for RADCE_LFLCK CRAM settings
  parameter use_hw_conv_det = 1'b0; // use hardware convergence detect macro if set to 1'b1 - else, default to soft ip.

  parameter number_of_channels = 5;
  parameter channel_address_width = 3;
  parameter lpm_type = "alt_aeq_s4";
  parameter lpm_hint = "UNUSED";

//********************************************************************************
// DECLARATIONS
//********************************************************************************
  input                             reconfig_clk;
  input                             aclr;
  input                             calibrate; // 'start'
  input                             recalibrate; // recalibrate offset
  input                             shutdown; // shut down (return to manual EQ)
  input                             all_channels;
  input [channel_address_width-1:0] logical_channel_address;
  input                      [11:0] remap_address;
  output                      [8:0] quad_address;
  input    [number_of_channels-1:0] adce_done;
  output                            busy;
  output   [number_of_channels-1:0] adce_standby; // put channels into standby - to RX PMA
  input                             adce_continuous; // put channel (or all if all_channels is asserted) into continuous mode if asserted
  output                            adce_cal_busy;

// multiplexed signals for interfacing with DPRIO
  input                             dprio_busy;
  input  [15:0]                     dprio_in;
  output                            dprio_wren;
  output                            dprio_rden;
  output [15:0]                     dprio_addr;
  output [15:0]                     dprio_data;
  
  output [3:0]                      eqout;
  output                            timeout;
  input  [7*number_of_channels-1:0] testbuses;
  output [4*number_of_channels-1:0] testbus_sels;
  
// SHOW_ERRORS option
  output [number_of_channels-1:0]   conv_error;
  output [number_of_channels-1:0]   error;
// end SHOW_ERRORS option

  wire [number_of_channels-1:0]     lf_not_found;
  wire [number_of_channels-1:0]     hf_not_found;
  wire [number_of_channels-1:0]     no_convergence;

  wire [9:0]                        logical_ch;
  wire [number_of_channels-1:0]     ch_done;

// signals for interfacing with the channel-specific state machine
  wire [6:0]                        ch_testbus;
  wire [3:0]                        ch_testbus_sel;
  wire [9:0]                        ch_dprio_addr;
  wire                              reset_n;
  wire                              ch_lf_not_found;
  wire                              ch_hf_not_found;
  wire                              ch_conv_error;
  wire                              ch_busy;
  wire                              ch_recal;
  wire                              ch_start;
  wire                              ch_disable;
  wire                              ch_adce_done;
  wire                              ch_shutdown;

//********************************************************************************
// FUNCTIONALITY
//********************************************************************************  

assign reset_n = !aclr;

// the upper 6 bits determine the channel
// address = {2'b0, channel_number, 2'b11} which results in the following:
// channel 0 = 6'h3
// channel 1 = 6'h7
// channel 2 = 6'hB
// channel 3 = 6'hF
assign dprio_addr = {2'b00, logical_ch[1:0], 2'b11, ch_dprio_addr[9:0]};
assign quad_address = {1'b0, logical_ch[9:2]};


// instantiation of the channel-oriented verilog model
  alt_aeq_ch_adce alt_aeq_ch_adce_inst0 ( // channel_adce
    .i_clock             (reconfig_clk),
    .i_reset_n           (reset_n),
    .i_start             (ch_start),
    .i_testbus           (ch_testbus), // increase width for additional signals
    .i_adce_done         (ch_adce_done),
    .i_adce_continuous   (adce_continuous),
    .o_testbus_sel0q     (ch_testbus_sel),
    .o_lf_not_found0q    (ch_lf_not_found),
    .o_hf_not_found0q    (ch_hf_not_found),
    .o_conv_error0q      (ch_conv_error),
    .o_timeout0q         (timeout),
    .i_dprio_busy        (dprio_busy),
    .i_dprio_in          (dprio_in),
    .o_busy0q            (ch_busy),
    .o_adce_cal_busy0q   (adce_cal_busy),
    .o_shutdown0q        (ch_shutdown),
    .i_recal             (ch_recal),
    .i_disable           (ch_disable),
    .o_eqout0q           (eqout),
    .o_dprio_data0q      (dprio_data),
    .o_dprio_addr0q      (ch_dprio_addr),
    .o_dprio_wren0q      (dprio_wren),
    .o_dprio_rden0q      (dprio_rden)
  );
  defparam
    alt_aeq_ch_adce_inst0.RADCE_HFLCK = radce_hflck,
    alt_aeq_ch_adce_inst0.RADCE_LFLCK = radce_lflck,
    alt_aeq_ch_adce_inst0.USE_HW_CONV_DET = use_hw_conv_det;

// because continuous mode doesn't work, the standby mode is not used - one
// time mode already automatically puts the channel in standby after running.
// So, we can use the standby command as the command to disable ADCE and
// switch back to manual EQ.  This is okay because we never exposed the
// shutdown command to customers.

// instantiaion of multi-channel adce model
  alt_aeq_full_adce alt_aeq_full_adce_inst0 ( //multi_channel_adce
    .i_clock           (reconfig_clk),
    .i_reset_n         (reset_n),
    .o_busy0q          (busy),
    .i_calibrate       (calibrate),
    .i_recal           (recalibrate),
    .i_all_ch          (all_channels),
    .i_current_ch      (logical_channel_address),
    .i_remap_addr      (remap_address),
    .i_shutdown_ch     (ch_shutdown),
    .i_disable_ch      (shutdown), // use shutdown to disable adce to allow users to use manual EQ
    .o_lf_not_found0q  (lf_not_found),
    .o_hf_not_found0q  (hf_not_found),
    .o_conv_error0q    (no_convergence),
    .o_ch_start0q      (ch_start),
    .o_ch_disable0q    (ch_disable),
    .i_ch_busy         (ch_busy),
    .o_ch_shutdown0q   (adce_standby), // don't touch this - soft-convergence macro needs this to stop the engine
    .i_ch_lf_not_found (ch_lf_not_found),
    .i_ch_hf_not_found (ch_hf_not_found),
    .i_ch_conv_error   (ch_conv_error),
    .o_logical_ch0q    (logical_ch),
    .o_ch_done0q       (ch_done)
  );
  defparam
    alt_aeq_full_adce_inst0.N_CH = number_of_channels,
    alt_aeq_full_adce_inst0.N_SEL = channel_address_width;

// instantiation of multiplexers
  alt_aeq_ch_muxes alt_aeq_ch_muxes_inst0 ( // ch_signal_muxes
    .i_logical_ch      (logical_ch[channel_address_width-1:0]),
    .i_testbuses       (testbuses),
    .o_ch_testbus      (ch_testbus),
    .i_adce_done       (adce_done),
    .o_ch_adce_done    (ch_adce_done),
    .i_ch_done         (ch_done),
    .o_ch_recal        (ch_recal)
  );
  defparam
    alt_aeq_ch_muxes_inst0.N_CH = number_of_channels,
    alt_aeq_ch_muxes_inst0.N_SEL = channel_address_width;


  genvar t;
  generate
    for(t = 0; t < number_of_channels; t = t + 1) begin: tb_sels
      assign testbus_sels[(t*4+3):(t*4)] = ch_testbus_sel;
    end
  endgenerate


  genvar e;
  generate
    if(show_errors == "YES") begin : gen_show_errors
      for(e = 0; e < number_of_channels; e = e + 1) begin: or_errs
        assign error[e] = lf_not_found[e] | hf_not_found[e];
        assign conv_error[e] = no_convergence[e];
      end
    end else begin : tieoff_errors
      for(e = 0; e < number_of_channels; e = e + 1) begin: zero_errs
        assign error[e] = 1'b0;
        assign conv_error[e] = 1'b0;
      end
    end
  endgenerate

endmodule
