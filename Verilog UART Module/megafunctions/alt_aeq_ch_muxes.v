module alt_aeq_ch_muxes (	
  i_logical_ch, 
  i_testbuses, 
  i_ch_done,
  i_adce_done,
  o_ch_adce_done,
  o_ch_testbus,
  o_ch_recal
);

  parameter N_CH  = 5;
  parameter N_SEL = 3;

//********************************************************************************
// Port Declarations
//********************************************************************************
  input [N_SEL-1:0]  i_logical_ch;
  input [7*N_CH-1:0] i_testbuses;
  input [N_CH-1:0]   i_adce_done; // from gxb instances
  input [N_CH-1:0]   i_ch_done;

  output             o_ch_adce_done;
  output [6:0]       o_ch_testbus;
  output             o_ch_recal;

//********************************************************************************
// Wires and regs
//********************************************************************************
  wire [6:0]         o_ch_testbus;
  wire               o_ch_recal;
  wire               o_ch_adce_done;

//********************************************************************************
// FUNCTIONALITY
//********************************************************************************	

  generate
    if(N_CH == 1) begin: one_channel_muxes
      assign o_ch_testbus   = i_testbuses;
      assign o_ch_recal     = i_ch_done;
      assign o_ch_adce_done = i_adce_done;
    end else begin: all_ch_muxes
      // instantiation of testbus multiplexer
      lpm_mux	lpm_mux_testbus (
        .sel    (i_logical_ch[N_SEL-1:0]),
        .data   (i_testbuses),
        .result (o_ch_testbus)
        // synopsys translate_off
        ,
        .aclr   (), 
        .clken  (), 
        .clock  ()
        // synopsys translate_on
      );
      defparam
        lpm_mux_testbus.lpm_size   = N_CH,			// number of busses
        lpm_mux_testbus.lpm_type   = "LPM_MUX",
        lpm_mux_testbus.lpm_width  = 7,		// bus size
        lpm_mux_testbus.lpm_widths = N_SEL;		// sel size

      // instantiation of recal multiplexer
      lpm_mux	lpm_mux_recal (
        .sel    (i_logical_ch[N_SEL-1:0]),
        .data   (i_ch_done),
        .result (o_ch_recal)
        // synopsys translate_off
        , 
        .aclr   (),
        .clken  (), 
        .clock  ()
        // synopsys translate_on
      );
      defparam
        lpm_mux_recal.lpm_size   = N_CH,			// number of busses
        lpm_mux_recal.lpm_type   = "LPM_MUX",
        lpm_mux_recal.lpm_width  = 1,		// bus size
        lpm_mux_recal.lpm_widths = N_SEL;		// sel size

      // instantiation of adce_done multiplexer
      lpm_mux	lpm_mux_adce_done (
        .sel    (i_logical_ch[N_SEL-1:0]),
        .data   (i_adce_done),
        .result (o_ch_adce_done)
        // synopsys translate_off
        , 
        .aclr   (),
        .clken  (), 
        .clock  ()
        // synopsys translate_on
      );
      defparam
        lpm_mux_adce_done.lpm_size   = N_CH,			// number of busses
        lpm_mux_adce_done.lpm_type   = "LPM_MUX",
        lpm_mux_adce_done.lpm_width  = 1,		// bus size
        lpm_mux_adce_done.lpm_widths = N_SEL;		// sel size
      
    end
  endgenerate

endmodule