// SPR:372839 - For Stratix V, this clock assignment is already covered by the one in sv_xcvr_reconfig_basic.sv - this one is just for consistency, and will usually be ignored
//  -Note that the frequency assignment is somewhat arbitrary (matching nominal reconfig_clk frequency), since the testbus is effectively asyncrhonous.
//  force language to Verilog 2001 to avoid errors for ALTERA_ATTRIBUTE syntax if using Verilog 1995
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
(* ALTERA_ATTRIBUTE = "-name SDC_STATEMENT \"create_clock -name alt_cal_sv_edge_detect_clk -period 10 [get_registers *alt_cal_sv*\|*pd*_det\|alt_edge_det_ff?]\"; -name SDC_STATEMENT \"set_clock_groups -exclusive -group [get_clocks {alt_cal_sv_edge_detect_clk}]\";suppress_da_rule_internal=\"C101,C103,C104,C106,D101\"" *) module alt_cal_edge_detect (

  output pd_edge,
  input reset,
  input testbus 
);

  wire pd_xor;
  wire pd_posedge;
  wire pd_negedge;
  assign pd_xor = ~(pd_posedge ^ pd_negedge);
  
  // pd_edge will be asserted when both a positive and negative edge are detected - both up and down transition has occurred, which implies toggling
  dffeas ff2 (
    .clk     (pd_xor),
    .d       (1'b1),
    .asdata  (1'b1),
    .clrn    (~reset),
    .aload   (1'b0),
    .q       (pd_edge),
    .sload   (1'b0),
    .sclr    (1'b0),
    .ena     (1'b1)
  );
  
  // essentially a latch - testbus may toggle very fast (1GHz+)
  dffeas alt_edge_det_ff0 (
    .clk     (testbus),
    .d       (1'b1),
    .asdata  (1'b0),
    .clrn    (1'b1),
    .aload   (reset),
    .q       (pd_posedge),
    .sload   (1'b1),
    .sclr    (1'b1),
    .ena     (1'b1)
  );
  
  // essentially a latch - testbus may toggle very fast (1GHz+)
  dffeas alt_edge_det_ff1 (
    .clk     (~testbus),
    .d       (1'b0),
    .asdata  (1'b1),
    .clrn    (1'b1),
    .aload   (reset),
    .q       (pd_negedge),
    .sload   (1'b0),
    .sclr    (1'b0),
    .ena     (1'b1)
  );

endmodule


(* ALTERA_ATTRIBUTE = "-name SDC_STATEMENT \"set_disable_timing [get_cells -compatibility_mode *\|alt_cal_channel\[*\]] -to q \";-name SDC_STATEMENT \"set_disable_timing [get_cells -compatibility_mode *\|alt_cal_busy] -to q \";suppress_da_rule_internal=\"C101,C103,C104,C106,D101\"" *) module alt_cal_sv #(
  parameter sim_model_mode        = "FALSE",
  parameter lpm_type              = "alt_cal_sv",
  parameter lpm_hint              = "UNUSED",
  parameter number_of_channels    = 4,
  parameter channel_address_width = 2,
  parameter sample_length         = 8'd100,
  parameter pma_base_address      = 12'h0, // current pma_base_address is 0

  parameter IDLE            = 5'd0,
  parameter CH_WAIT         = 5'd1,
  parameter TESTBUS_SET     = 5'd2,
  parameter OFFSETS_PDEN_RD = 5'd3,
  parameter OFFSETS_PDEN_WR = 5'd4,
  parameter CAL_PD_WR       = 5'd5,
  parameter CAL_RX_RD       = 5'd6,
  parameter CAL_RX_WR       = 5'd7,
  parameter DPRIO_WAIT      = 5'd8,
  parameter SAMPLE_TB       = 5'd9,
  parameter TEST_INPUT      = 5'd10,
  parameter OC_REQUIRED_RD  = 5'd11,
  parameter CH_ADV          = 5'd12,
  parameter OC_PD_RD        = 5'd13,
  parameter DPRIO_READ      = 5'd14,
  parameter DPRIO_WRITE     = 5'd15,
  parameter OC_PD_WR        = 5'd16,
  parameter PDOF_TEST_RD    = 5'd17,
  parameter PDOF_TEST_WR    = 5'd18,
  parameter CHECK_PLL_RD    = 5'd19
) (
  input         clock,         // reconfig clk
  input         reset,         // reconfig reset (if applicable)
  input         start,         // disconnect for now?
  output        busy,          // output to alt4gxb_reconfig's busy, and to reconfig_togxb bus
  output [15:0] dprio_addr,    // mux into alt_dprio
  output [8:0]  quad_addr,
  output [15:0] dprio_dataout, // mux into alt_dprio
  input  [15:0] dprio_datain,  // from alt_dprio
  output        dprio_wren,    // mux into alt_dprio
  output        dprio_rden,    // mux into alt_dprio
  input         dprio_busy,    // from alt_dprio
  input  [11:0] remap_addr,    // from the logical channel address remapper registers
  input  [7:0]  testbuses      // testbus input from the transceiver - always 8 bits, since muxing is done at the 'B' block for SV
);

  localparam  RECAL_MAX_ATTEMPTS = 2'd3; // recalibrate up to 3 times if we get any knob 'maxed out'

  // p0addr is from cbx_dcfifo_low_latency_stratixii.cpp
  reg         p0addr/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */;
  wire        powerup;
  assign      powerup = p0addr;

  reg [16:0]  delay_oc_count;
  reg [4:0]   state;
  reg [4:0]   ret_state;
  reg         alt_cal_busy;
  reg [11:0]  address;
  reg [15:0]  dataout;
  reg         write_reg;
  reg         read;
  reg         did_dprio;
  reg         done/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */;
  reg [9:0]   alt_cal_channel;

  reg         cal_en;
  reg         do_recal;
  reg  [1:0]  recal_counter/* synthesis ALTERA_ATTRIBUTE="PRESERVE_REGISTER=ON;POWER_UP_LEVEL=LOW" */; 

  reg [7:0]   counter;
  reg [4:0]   cal_rx_lr, cal_rx_lr_l;
  reg [3:0]   cal_pd0, cal_pd90, cal_pd180, cal_pd270;
  reg [3:0]   cal_pd0_l, cal_pd90_l, cal_pd180_l, cal_pd270_l;
  reg [3:0]   cal_done, cal_inc;
  reg         rx_done, rx_inc;
  wire [7:0]  cal_rx;
  wire [15:0] cal_pd;
  reg  [3:0]  ch_testbus0q, ch_testbus1q;
  wire [3:0]  int_pd0, int_pd90, int_pd180, int_pd270;
  wire [3:0]  src_pd0, src_pd90, src_pd180, src_pd270;
  wire [4:0]  avg_pd0, avg_pd90, avg_pd180, avg_pd270;
  wire [5:0]  avg_cal_rx;
 
  assign busy       = alt_cal_busy;
  assign cal_rx     = (cal_rx_lr[4] == 1'b0) ? {4'd0, 4'hF - cal_rx_lr[3:0]} : {cal_rx_lr[3:0], 4'd0};
  assign src_pd0    = (rx_done == 1'b0 ? cal_rx_lr[4:1] : cal_pd0);
  assign src_pd90   = (rx_done == 1'b0 ? cal_rx_lr[4:1] : cal_pd90);
  assign src_pd180  = (rx_done == 1'b0 ? cal_rx_lr[4:1] : cal_pd180);
  assign src_pd270  = (rx_done == 1'b0 ? cal_rx_lr[4:1] : cal_pd270);
  assign int_pd0    = (src_pd0[3] == 1'b0 ? (4'hF - src_pd0) : {1'b0, src_pd0[2:0]});
  assign int_pd90   = (src_pd90[3] == 1'b0 ? (4'hF - src_pd90) : {1'b0, src_pd90[2:0]});
  assign int_pd180  = (src_pd180[3] == 1'b0 ? (4'hF - src_pd180) : {1'b0, src_pd180[2:0]});
  assign int_pd270  = (src_pd270[3] == 1'b0 ? (4'hF - src_pd270) : {1'b0, src_pd270[2:0]});
  assign cal_pd     = {int_pd0, int_pd90, int_pd180, int_pd270};
  assign avg_pd0    = cal_pd0 + cal_pd0_l;
  assign avg_pd90   = cal_pd90 + cal_pd90_l;
  assign avg_pd180  = cal_pd180 + cal_pd180_l;
  assign avg_pd270  = cal_pd270 + cal_pd270_l;
  assign avg_cal_rx = cal_rx_lr + cal_rx_lr_l;

// DPRIO addressing is much simpler in SV
// - Basically, we can use the logical channel for everything, and the 'B' will automatically figure out the physical address
// - However, we will preserve the existing channel arrangement the way it was done for Stratix IV in order to avoid port changes and simulation model changes
  assign dprio_dataout = dataout;
  assign dprio_wren    = write_reg;
  assign dprio_rden    = read;
  assign dprio_addr    = {1'b0, alt_cal_channel[1:0], address[11:0]};
  assign quad_addr     = {1'b0, alt_cal_channel[9:2]};

// {pd_0,pd_1,pd_0_p,pd_1_p} == 0110 == positive solid edge
// {pd_0,pd_1,pd_0_p,pd_1_p} == 1001 == negative solid edge
// look for (pd_0 ^ pd_0_p) & (pd_1 ^ pd_1_p) for solid edges
  reg  [3:0] pd_0, pd_1;
  reg  [3:0] pd_0_p, pd_1_p;
  wire [3:0] data_e;
  reg  [3:0] data_e0q, data_e1q;
  reg  [3:0] ignore_solid;
  wire [3:0] solid_edges = (pd_0 ^ pd_0_p) & (pd_1 ^ pd_1_p);
  wire [3:0] data_solid  = solid_edges & (~ignore_solid);
  wire       samp_reset  = (state == DPRIO_WRITE) ? 1'b1 : 1'b0;

  alt_cal_edge_detect pd0_det (
    .pd_edge (data_e[0]),
    .reset   (samp_reset),
    .testbus (testbuses[0])
  );
  alt_cal_edge_detect pd90_det (
    .pd_edge (data_e[1]),
    .reset   (samp_reset),
    .testbus (testbuses[1])
  );
  alt_cal_edge_detect pd180_det (
    .pd_edge (data_e[2]),
    .reset   (samp_reset),
    .testbus (testbuses[2])
  );
  alt_cal_edge_detect pd270_det (
    .pd_edge (data_e[3]),
    .reset   (samp_reset),
    .testbus (testbuses[3])
  );
  
  // synchronize edge detection output into the reconfig clock domain 
  always @ (posedge clock or posedge reset) begin
    if (reset) begin
      data_e0q     <= 4'b0;
      data_e1q     <= 4'b0;
      ch_testbus0q <= 4'b0;
      ch_testbus1q <= 4'b0;
    end else begin
      data_e0q     <= data_e;
      data_e1q     <= data_e0q;
      ch_testbus0q <= testbuses[3:0];
      ch_testbus1q <= ch_testbus0q;
    end
  end
  
  // edges is a level, and is used in the state machine, which is on reconfig clock
  wire [3:0] edges = data_e1q | data_solid;
  
  // synopsys translate_off
  initial begin
    delay_oc_count  = 16'h0000;
    state           = 5'h0;
    ret_state       = 5'h0;
    alt_cal_busy    = 1'b0;
    address         = 12'h000;
    dataout         = 16'h0000;
    write_reg       = 1'b0;
    read            = 1'b0;
    did_dprio       = 1'b0;
    done            = 1'b0;
    alt_cal_channel = 10'h000;
    cal_en          = 1'b0;
    counter         = 8'h00;
    cal_rx_lr       = 5'h00;
    cal_rx_lr_l     = 5'h00;
    cal_pd0         = 4'h0;
    cal_pd90        = 4'h0;
    cal_pd180       = 4'h0;
    cal_pd270       = 4'h0;
    cal_pd0_l       = 4'h0;
    cal_pd90_l      = 4'h0;
    cal_pd180_l     = 4'h0;
    cal_pd270_l     = 4'h0;
    cal_done        = 4'h0;
    cal_inc         = 4'h0;
    rx_done         = 1'b0;
    rx_inc          = 1'b0;
    pd_0            = 4'h0;
    pd_1            = 4'h0;
    pd_0_p          = 4'h0;
    pd_1_p          = 4'h0;
    ignore_solid    = 4'h0;
    recal_counter   = 2'b0;
  end
  // synopsys translate_on


  always @ (posedge clock) begin
    p0addr <= 1'b1; // first clock edge starts offset cancellation
  end

  // main state machine - should be recoded as a 2 or 3 always block state machine, but it already works, so leave it
  always @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin 
      state           <= IDLE;
      ret_state       <= IDLE;
      alt_cal_busy    <= 1'b0;
      address         <= 12'd0;
      dataout         <= 16'd0;
      write_reg       <= 1'b0;
      read            <= 1'b0;
      did_dprio       <= 1'b0;
//      done <= 1'b0; // pull out of the reset loop so reset will not automatically restart offset cancellation
      alt_cal_channel <= 10'd0;
      cal_en          <= 1'b0;
      cal_rx_lr       <= 5'h00;
      cal_rx_lr_l     <= 5'h00;
      {cal_pd0, cal_pd90, cal_pd180, cal_pd270}         <= {16'h0000};
      {cal_pd0_l, cal_pd90_l, cal_pd180_l, cal_pd270_l} <= {16'h0000};
      {rx_done, rx_inc}   <= {2{1'd0}};
      {cal_done, cal_inc} <= {2{4'd0}};
      counter         <= 8'd0;
      ignore_solid    <= 4'd0;
      do_recal        <= 1'b0;
      recal_counter   <= 2'b0;
    end else begin
      case (state)
      IDLE: begin
          cal_en          <= 1'b0;
          alt_cal_channel <= 10'd0;
          if ((powerup == 1'b1 & done == 1'b0) || start == 1'b1) begin
            state        <= CH_WAIT;
            alt_cal_busy <= 1'b1;
          end else begin
            state        <= IDLE;
            alt_cal_busy <= 1'b0;
          end
        end
      CH_WAIT: begin
          {cal_pd0, cal_pd90, cal_pd180, cal_pd270}         <= {16'h0000};
          {cal_pd0_l, cal_pd90_l, cal_pd180_l, cal_pd270_l} <= {16'h0000};
          cal_rx_lr           <= 5'h00;
          cal_rx_lr_l         <= 5'h00;
          {rx_done, rx_inc}   <= {2{1'd0}};
          {cal_done, cal_inc} <= {2{4'd0}};
          ignore_solid        <= 4'hF;
          counter             <= 8'd0;
          done                <= 1'd0; // reset done when we start again (incase triggered by the start signal
          state               <= TESTBUS_SET;
          do_recal            <= 1'b0;
        end
      TESTBUS_SET: begin
          if (remap_addr[11:0] == 12'hFFF) begin
            state <= CH_ADV;
          end else begin
            state  <= OC_REQUIRED_RD;
            cal_en <= ~cal_en;
          end
        end
// check whether the channel requires offset cancellation by reading the reserved register in the PMA
      OC_REQUIRED_RD: begin
          address   <= 12'h17 + pma_base_address; // 0x17 bit 0
          read      <= 1'b0;
          did_dprio <= 1'b0;
          state     <= DPRIO_READ;
          ret_state <= CHECK_PLL_RD;
        end
      CHECK_PLL_RD: begin // check whether the channel is a PLL interface
          address   <= 12'h0f + pma_base_address; // 0xF bit 15
          read      <= 1'b0;
          did_dprio <= 1'b0;
          state     <= (dprio_datain[0] ? DPRIO_READ : CH_ADV); // if bit 0 of register 0x17 is set (from previous read), we might need to do OC on this channel; else skip to next channel
          ret_state <= OFFSETS_PDEN_RD;
      end
      OFFSETS_PDEN_RD: begin
          address   <= 12'h030 + pma_base_address;  // ch_reg_30 bit offset 3, address 0x30
          read      <= 1'b0;
          did_dprio <= 1'b0;
          state     <= (~dprio_datain[15] ? DPRIO_READ : CH_ADV); // if bit 15 of register 0xF is set, the channel is a PLL and we should skip it, else do OC on this channel
          ret_state <= OFFSETS_PDEN_WR;
        end
      OFFSETS_PDEN_WR: begin  // use rint_cal_en and set to '1' for calibration mode to enable core control of oc_cal_en
          dataout   <= {dprio_datain[15:4], 1'b1, dprio_datain[2:0]};  // buffer powerdown will be done by oc_cal_en signal
          write_reg <= 1'b0;
          did_dprio <= 1'b0;
          state     <= DPRIO_WRITE;
          ret_state <= OC_PD_RD; // read-modify-write the rrx_oc_pd bit to enable/disable offset cancellation mode
        end
      OC_PD_RD: begin
          address   <= 12'h019 + pma_base_address;  // register address 0x19 offset 9
          read      <= 1'b0;
          did_dprio <= 1'b0;
          state     <= DPRIO_READ; 
          ret_state <= OC_PD_WR;
      end
      OC_PD_WR: begin
          dataout   <= {dprio_datain[15:10], 1'b0, dprio_datain[8:0]}; // offset cancellation enable is active low - write 0 to allow cancellation
          write_reg <= 1'b0;
          did_dprio <= 1'b0;
          state     <= DPRIO_WRITE;
          ret_state <= PDOF_TEST_RD; // disable/enable BBPD toggling on testbus
      end
      PDOF_TEST_RD: begin
          address   <= 12'h0e + pma_base_address;  // register address 0xe offset 2
          read      <= 1'b0;
          did_dprio <= 1'b0;
          state     <= DPRIO_READ;
          ret_state <= PDOF_TEST_WR;
      end
      PDOF_TEST_WR: begin
          dataout   <= {dprio_datain[15:3], cal_en, dprio_datain[1:0]}; // either disable or re-enable BBPD toggling on testbus
          write_reg <= 1'b0;
          did_dprio <= 1'b0;
          state     <= DPRIO_WRITE;
          ret_state <= (cal_en ? CAL_PD_WR : CH_ADV); // disable/enable BBPD toggling on testbus - go to next channel if cal_en is low (we are done re-enabling this channel)
      end
      CAL_PD_WR: begin
          address   <= 12'h0d + pma_base_address;  // ch_reg_7, address 0xd - bit width might change later - fix me!
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
            dataout   <= {cal_pd};
          end
          write_reg <= 1'b0;
          did_dprio <= 1'b0;
          state     <= DPRIO_WRITE;
          ret_state <= CAL_RX_RD;
        end
      CAL_RX_RD: begin
          address     <= 12'h01a + pma_base_address;  // ch_reg_20 bit offset 1, address 0x1a - bit width might change later - fix me!
          read        <= 1'b0;
          did_dprio   <= 1'b0;
          state       <= DPRIO_READ;
          ret_state   <= CAL_RX_WR;
        end
      CAL_RX_WR: begin
          address   <= 12'h01a + pma_base_address;  // ch_reg_20 bit offset 1, address 0x1a - bit width might change later - fix me!
          if (rx_done && (&cal_rx[3:0] || &cal_rx[7:4])) begin // we are done and value is maxed out (either +max or -max) - revert to '0'
            dataout  <= {dprio_datain[15:9], 8'b0, dprio_datain[0]};
            do_recal <= 1'b1;
          end else begin
            dataout  <= {dprio_datain[15:9], cal_rx, dprio_datain[0]};
            do_recal <= 1'b0;
          end
          write_reg <= 1'b0;
          did_dprio <= 1'b0;
          state     <= DPRIO_WRITE;
          ret_state <= DPRIO_WAIT;
          counter   <= 8'd0;
        end
      DPRIO_WAIT: begin
          if (counter == 8'd6) begin
            counter      <= 8'd0;
            state        <= SAMPLE_TB;
            pd_0_p       <= pd_0;
            pd_1_p       <= pd_1;
            {pd_0, pd_1} <= 8'hFF;
          end else begin
            counter <= counter + 8'd1;
            state   <= DPRIO_WAIT;
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
          end else begin
            counter <= counter + 8'd1;
            state   <= SAMPLE_TB;
          end
        end
      TEST_INPUT: begin
          if ({rx_done, cal_done} == 5'b11111) begin
            state <= TESTBUS_SET;
          end else begin
            state <= CAL_PD_WR;
          end

          if (rx_done == 1'b0) begin
            if (edges[0] | edges[2]) begin
              ignore_solid <= 4'hF;
              if (rx_inc == 1'b0) begin
                cal_rx_lr_l <= cal_rx_lr;
                rx_inc      <= 1'b1;
                cal_rx_lr   <= 5'b11111;
              end else begin
                cal_rx_lr <= avg_cal_rx[5:1];
                rx_done   <= 1'b1;  //done, state <= testbus_set
              end
            end else if ((cal_rx_lr == 5'b11111 && rx_inc == 1'b0) || (cal_rx_lr == cal_rx_lr_l && rx_inc == 1'b1)) begin
              rx_done      <= 1'b1;  //error
              ignore_solid <= 4'hF;
              cal_rx_lr    <= rx_inc ? cal_rx_lr : 5'b11111;
            end else begin
              cal_rx_lr    <= cal_rx_lr + (rx_inc ? 5'b11111 : 5'b00001);
              ignore_solid <= 4'h0;
            end
          end
          
          if (rx_done && cal_done[0] == 1'b0) begin
            if (edges[0]) begin
              cal_inc[0]      <= 1'b1;
              ignore_solid[0] <= 1'b1;
              if (cal_inc[0] == 1'b0) begin
                cal_pd0_l <= cal_pd0;
                cal_pd0   <= 4'hF;
              end else begin
                cal_pd0     <= avg_pd0[4:1];
                cal_done[0] <= 1'b1;  //done
              end
            end else if ((cal_pd0 == 4'hF && cal_inc[0] == 1'b0) || (cal_pd0 == cal_pd0_l && cal_inc[0] == 1'b1)) begin
              cal_done[0]     <= 1'b1;    //error
              ignore_solid[0] <= 1'b1;
              cal_pd0         <= cal_inc[0] ? cal_pd0 : 4'h0;
            end else begin
              cal_pd0         <= cal_pd0 + (cal_inc[0] ? 4'hF : 4'h1);
              ignore_solid[0] <= 1'b0;
            end
          end

          if (rx_done && cal_done[1] == 1'b0) begin
            if (edges[1]) begin
              cal_inc[1]      <= 1'b1;
              ignore_solid[1] <= 1'b1;
              if (cal_inc[1] == 1'b0) begin
                cal_pd90_l <= cal_pd90;
                cal_pd90   <= 4'hF;
              end else begin
                cal_pd90    <= avg_pd90[4:1];
                cal_done[1] <= 1'b1;  //done
              end
            end else if ((cal_pd90 == 4'hF && cal_inc[1] == 1'b0) || (cal_pd90 == cal_pd90_l && cal_inc[1] == 1'b1)) begin
              cal_done[1]     <= 1'b1;    //error
              ignore_solid[1] <= 1'b1;
              cal_pd90        <= cal_inc[1] ? cal_pd90 : 4'h0;
            end else begin
              cal_pd90        <= cal_pd90 + (cal_inc[1] ? 4'hF : 4'h1);
              ignore_solid[1] <= 1'b0;
            end
          end

          if (rx_done && cal_done[2] == 1'b0) begin
            if (edges[2]) begin
              cal_inc[2]      <= 1'b1;
              ignore_solid[2] <= 1'b1;
              if (cal_inc[2] == 1'b0) begin
                cal_pd180_l <= cal_pd180;
                cal_pd180   <= 4'hF;
              end else begin
                cal_pd180   <= avg_pd180[4:1];
                cal_done[2] <= 1'b1;  //done
              end
            end else if ((cal_pd180 == 4'hF && cal_inc[2] == 1'b0) || (cal_pd180 == cal_pd180_l && cal_inc[2] == 1'b1)) begin
              cal_done[2]     <= 1'b1;    //error
              ignore_solid[2] <= 1'b1;
              cal_pd180       <= cal_inc[2] ? cal_pd180 : 4'h0;
            end else begin
              cal_pd180       <= cal_pd180 + (cal_inc[2] ? 4'hF : 4'h1);
              ignore_solid[2] <= 1'b0;
            end
          end

          if (rx_done && cal_done[3] == 1'b0) begin
            if (edges[3]) begin
              cal_inc[3]      <= 1'b1;
              ignore_solid[3] <= 1'b1;
              if (cal_inc[3] == 1'b0) begin
                cal_pd270_l <= cal_pd270;
                cal_pd270   <= 4'hF;
              end else begin
                cal_pd270   <= avg_pd270[4:1];
                cal_done[3] <= 1'b1;  //done
              end
            end else if ((cal_pd270 == 4'hF && cal_inc[3] == 1'b0) || (cal_pd270 == cal_pd270_l && cal_inc[3] == 1'b1)) begin
              cal_done[3]     <= 1'b1;    //error
              ignore_solid[3] <= 1'b1;
              cal_pd270       <= cal_inc[3] ? cal_pd270 : 4'hF;
            end else begin
              cal_pd270       <= cal_pd270 + (cal_inc[3] ? 4'hF : 4'h1);
              ignore_solid[3] <= 1'b0;
            end
          end
        end
      CH_ADV: begin
          //if (channel == (number_of_channels - 1)) begin
          if (alt_cal_channel >= (number_of_channels - 1)) begin
            done  <= 1'b1;
            state <= IDLE;
          end else begin
            alt_cal_channel <= alt_cal_channel + 10'd1;
            state           <= CH_WAIT;
          end
        end
      DPRIO_READ: begin
          // always first wait for old dprio transactions to end
          // send read command, then wait for data to arrive before continuing
          if(~dprio_busy) begin
            if(did_dprio) begin
              if(read == 1'b0) begin
                state      <= ret_state;
              end else begin
                if (remap_addr == 12'hfff) begin // invalid channel
                  read <= 1'b0;
                  state <= CH_ADV;
                end else begin
                  read  <= 1'b1;
                  state <= DPRIO_READ;
                end
              end
            end else begin
              read      <= 1'b1;
              did_dprio <= 1'b1;
              state     <= DPRIO_READ;
            end
          end else begin
            // waiting for dprio to finish
            read  <= 1'b0;
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
              end else begin
                if (remap_addr == 12'hfff) begin // invalid channel
                  write_reg <= 1'b0;
                  state     <= CH_ADV;
                end else begin
                  write_reg <= 1'b1;
                  state     <= DPRIO_WRITE;
                end
              end
            end else begin
              write_reg <= 1'b1;
              did_dprio <= 1'b1;
              state     <= DPRIO_WRITE;
            end
          end else begin
            // waiting for dprio to finish
            write_reg <= 1'b0;
            state     <= DPRIO_WRITE;
          end
        end
      default: begin
        state        <= IDLE;
        alt_cal_busy <= 1'b0;
        done         <= 1'b0;
        end
      endcase
    end
  end

endmodule

