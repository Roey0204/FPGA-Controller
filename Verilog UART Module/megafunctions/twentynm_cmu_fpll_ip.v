module twentynm_cmu_fpll_ip
(
	// cmu_fpll input ports
	input [8:0] avmmaddress,
	input avmmclk,
	input avmmread,
	input avmmrstn,
	input avmmwrite,
	input [7:0] avmmwritedata,	
	input [3:0] cnt_sel,
	input csr_bufin,
	input csr_clk,
	input csr_en,
	input csr_in,
	input csr_test_mode,
	input dps_rst_n,
	input fbclk_in,	
	input mdio_dis,
	input [2:0] num_phase_shifts,
	input pfden,
	input phase_en,
	input pma_csr_test_dis,
	input rst_n,
	input scan_mode_n,
	input scan_shift_n,
	input up_dn,
	input refclk,
	input core_refclk,
	input extswitch,
	input [5:0] iqtxrxclk,
	input pll_cascade_in,
	input [11:0] ref_iqclk,

	// STRATIXVI_cmu_fpll output ports
	output [7:0] avmmreaddata,
	output blockselect,
	output clk0,
	output clk180,
	output clklow,
	output csr_bufout,
	output csr_out,
	output fbclk_out,
	output fref,
	output hclk_out,
	output iqtxrxclk_out,
	output lock,
	output [3:0] outclk,
	output overrange,
	output phase_done,
	output pll_cascade_out,
	output underrange,	
	output clk0bad,
	output clk1bad,
	output extswitch_buf,
	output pllclksel
);
// Parameter used in generate statement
parameter number_of_counters = 4;

// Virtual parameters
parameter silicon_rev = "es";
parameter use_default_base_address = "true";
parameter user_base_address = 0;
parameter reference_clock_frequency = "100.0 MHz";
parameter vco_frequency = "100.0 MHz";
parameter hssi_output_clock_frequency = "0 ps";
parameter prot_mode = "basic";
parameter speed_grade = "2";
parameter bw_sel = "auto";
parameter cgb_div = "1";
parameter is_cascaded_pll = "false";
parameter refclk_select0 = "ref_iqclk0";
parameter refclk_select1 = "ref_iqclk0";
parameter output_clock_frequency_0 = "100.0 MHz";
parameter phase_shift_0 = "0 ps";
parameter duty_cycle_0 = 50;
parameter output_clock_frequency_1 = "0 ps";
parameter phase_shift_1 = "0 ps";
parameter duty_cycle_1 = 50;
parameter output_clock_frequency_2 = "0 ps";
parameter phase_shift_2 = "0 ps";
parameter duty_cycle_2 = 50;
parameter output_clock_frequency_3 = "0 ps";
parameter phase_shift_3 = "0 ps";
parameter duty_cycle_3 = 50;

// STRATIXVI_cmu_fpll_refclk_select parameters
parameter pll_clkin_0_src = "pll_clkin_0_src_vss";
parameter pll_clkin_1_src = "pll_clkin_1_src_vss";
parameter pll_auto_clk_sw_en = "false";
parameter pll_clk_loss_edge = "pll_clk_loss_both_edges";
parameter pll_clk_loss_sw_en = "false";
parameter pll_clk_sw_dly = 0;
parameter pll_manu_clk_sw_en = "false";
parameter pll_sw_refclk_src = "pll_sw_refclk_src_clk_0";
parameter mux0_inclk0_logical_to_physical_mapping = "power_down";
parameter mux0_inclk1_logical_to_physical_mapping = "power_down";
parameter mux0_inclk2_logical_to_physical_mapping = "power_down";
parameter mux0_inclk3_logical_to_physical_mapping = "power_down";
parameter mux0_inclk4_logical_to_physical_mapping = "power_down";
parameter mux1_inclk0_logical_to_physical_mapping = "power_down";
parameter mux1_inclk1_logical_to_physical_mapping = "power_down";
parameter mux1_inclk2_logical_to_physical_mapping = "power_down";
parameter mux1_inclk3_logical_to_physical_mapping = "power_down";
parameter mux1_inclk4_logical_to_physical_mapping = "power_down";

// STRATIXVI_cmu_fpll parameters
parameter pll_cal_status = "cal_done"; 
parameter pll_cal_en = "user_reset_override";
parameter pll_calibration = "false";
parameter pll_mode = "false";
parameter pll_rstn_value = "cmu_normal";
parameter pll_lpf_rstn_value = "lpf_normal";
parameter pll_ppm_clk0_src = "ppm_clk0_vss";
parameter pll_ppm_clk1_src = "ppm_clk1_vss";
parameter pll_c_counter_0_coarse_dly = "0 ps";
parameter pll_c_counter_0_fine_dly = "0 ps";
parameter pll_c_counter_0_in_src = "c_cnt_in_src_test_clk";
parameter pll_c_counter_0_ph_mux_prst = 0;
parameter pll_c_counter_0_prst = 1;
parameter pll_c_counter_0 = 1;
parameter pll_c_counter_1_coarse_dly = "0 ps";
parameter pll_c_counter_1_fine_dly = "0 ps";
parameter pll_c_counter_1_in_src = "c_cnt_in_src_test_clk";
parameter pll_c_counter_1_ph_mux_prst = 0;
parameter pll_c_counter_1_prst = 1;
parameter pll_c_counter_1 = 1;
parameter pll_c_counter_2_coarse_dly = "0 ps";
parameter pll_c_counter_2_fine_dly = "0 ps";
parameter pll_c_counter_2_in_src = "c_cnt_in_src_test_clk";
parameter pll_c_counter_2_ph_mux_prst = 0;
parameter pll_c_counter_2_prst = 1;
parameter pll_c_counter_2 = 1;
parameter pll_c_counter_3_coarse_dly = "0 ps";
parameter pll_c_counter_3_fine_dly = "0 ps";
parameter pll_c_counter_3_in_src = "c_cnt_in_src_test_clk";
parameter pll_c_counter_3_ph_mux_prst = 0;
parameter pll_c_counter_3_prst = 1;
parameter pll_c_counter_3 = 1;
parameter pll_atb = "atb_selectdisable";
parameter pll_cp_compensation = "true";
parameter pll_cp_current_setting = "cp_current_setting0";
parameter pll_cp_testmode = "cp_normal";
parameter pll_cp_lf_3rd_pole_freq = "lf_3rd_pole_setting0";
parameter pll_cp_lf_4th_pole_freq = "lf_4th_pole_setting0";
parameter pll_cp_lf_order = "lf_2nd_order";
parameter pll_lf_resistance = "lf_res_setting0";
parameter pll_lf_ripplecap = "lf_ripple_enabled";
parameter pll_cmp_buf_dly = "0 ps";
parameter pll_fbclk_mux_1 = "pll_fbclk_mux_1_glb";
parameter pll_fbclk_mux_2 = "pll_fbclk_mux_2_fb_1";
parameter pll_iqclk_mux_sel	= "power_down"; 
parameter pll_dsm_mode = "dsm_mode_integer";
parameter pll_dsm_out_sel = "pll_dsm_disable";
parameter pll_dsm_ecn_bypass = "false";
parameter pll_dsm_ecn_test_en = "false";
parameter pll_dsm_fractional_division = 1;
parameter pll_dsm_fractional_value_ready = "pll_k_ready";
parameter pll_m_counter	= 1; 
parameter pll_l_counter_bypass = "false";
parameter pll_l_counter	= 1;
parameter pll_l_counter_enable = "false";
parameter pll_lock_fltr_cfg = 1;
parameter pll_lock_fltr_test = "pll_lock_fltr_nrm";
parameter pll_unlock_fltr_cfg = 0;
parameter pll_m_counter_in_src = "m_cnt_in_src_test_clk";
parameter pll_m_counter_ph_mux_prst	= 0;
parameter pll_m_counter_prst = 1;
parameter pll_m_counter_coarse_dly = "0 ps";
parameter pll_m_counter_fine_dly = "0 ps";
parameter pll_n_counter	= 1;
parameter pll_n_counter_coarse_dly = "0 ps";
parameter pll_n_counter_fine_dly = "0 ps";
parameter pll_overrange_level = "level0";
parameter pll_ref_buf_dly = "0 ps";
parameter pll_tclk_mux_en = "false";
parameter pll_tclk_sel = "pll_tclk_m_src";
parameter pll_underrange_level = "level0";
parameter pll_vco_ph0_en = "false";
parameter pll_vco_ph1_en = "false";
parameter pll_vco_ph2_en = "false";
parameter pll_vco_ph3_en = "false";
parameter pll_vreg0_output = "vccdreg_nominal";
parameter pll_vreg1_output = "vccdreg_nominal";
parameter pll_nreset_invert = "false"; 
parameter pll_ctrl_override_setting = "true";
parameter pll_enable = "false";
parameter pll_self_reset = "false";
parameter pll_test_enable = "false";
parameter pll_vccr_pd_en = "true";

wire refclk_sel_outclk_wire;

// instantiate STRATIXVI_cmu_fpll block
STRATIXVI_cmu_fpll_refclk_select
#(
	.pll_clkin_0_src(pll_clkin_0_src),
	.pll_clkin_1_src(pll_clkin_1_src),
	.pll_auto_clk_sw_en(pll_auto_clk_sw_en),
	.pll_clk_loss_edge(pll_clk_loss_edge),
	.pll_clk_loss_sw_en(pll_clk_loss_sw_en),
	.pll_clk_sw_dly(pll_clk_sw_dly),
	.pll_manu_clk_sw_en(pll_manu_clk_sw_en),
	.pll_sw_refclk_src(pll_sw_refclk_src),
	.mux0_inclk0_logical_to_physical_mapping(mux0_inclk0_logical_to_physical_mapping),
	.mux0_inclk1_logical_to_physical_mapping(),
	.mux0_inclk2_logical_to_physical_mapping(mux0_inclk2_logical_to_physical_mapping),
	.mux0_inclk3_logical_to_physical_mapping(mux0_inclk3_logical_to_physical_mapping),
	.mux0_inclk4_logical_to_physical_mapping(mux0_inclk4_logical_to_physical_mapping),
	.mux1_inclk0_logical_to_physical_mapping(mux1_inclk0_logical_to_physical_mapping),
	.mux1_inclk1_logical_to_physical_mapping(mux1_inclk1_logical_to_physical_mapping),
	.mux1_inclk2_logical_to_physical_mapping(mux1_inclk2_logical_to_physical_mapping),
	.mux1_inclk3_logical_to_physical_mapping(mux1_inclk3_logical_to_physical_mapping),
	.mux1_inclk4_logical_to_physical_mapping(mux1_inclk4_logical_to_physical_mapping),
	.silicon_rev(silicon_rev),
	.refclk_select0(refclk_select0),
	.refclk_select1(refclk_select1)
) cmu_fpll_refclk_select_inst
(
	// Input Ports
	.avmmaddress(avmmaddress),
	.avmmclk(avmmclk),
	.avmmread(avmmread),
	.avmmrstn(avmmrstn),
	.avmmwrite(avmmwrite),
	.avmmwritedata(avmmwritedata),
	.core_refclk(core_refclk),
	.extswitch(extswitch),
	.iqtxrxclk(iqtxrxclk),
	.pll_cascade_in(pll_cascade_in),
	.ref_iqclk(ref_iqclk),
	.refclk(refclk),
	
	// Output Ports
	.avmmreaddata(),
	.blockselect(),
	.clk0bad(clk0bad),
	.clk1bad(clk1bad),
	.extswitch_buf(extswitch_buf),
	.outclk(refclk_sel_outclk_wire),
	.pllclksel(pllclksel)
);

// instantiate STRATIXVI_cmu_fpll block
STRATIXVI_cmu_fpll
#(
	.silicon_rev(silicon_rev),
	.use_default_base_address(use_default_base_address),
	.user_base_address(user_base_address),
	.reference_clock_frequency(reference_clock_frequency),
	.vco_frequency(vco_frequency),
	.hssi_output_clock_frequency(hssi_output_clock_frequency),
	.prot_mode(prot_mode),
	.speed_grade(speed_grade),
	.bw_sel(bw_sel),
	.cgb_div(cgb_div),
	.is_cascaded_pll(is_cascaded_pll),
	.output_clock_frequency_0(output_clock_frequency_0),
	.phase_shift_0(phase_shift_0),
	.duty_cycle_0(duty_cycle_0),
	.output_clock_frequency_1(output_clock_frequency_1),
	.phase_shift_1(phase_shift_1),
	.duty_cycle_1(duty_cycle_1),
	.output_clock_frequency_2(output_clock_frequency_2),
	.phase_shift_2(phase_shift_2),
	.duty_cycle_2(duty_cycle_2),
	.output_clock_frequency_3(output_clock_frequency_3),
	.phase_shift_3(phase_shift_3),
	.duty_cycle_3(duty_cycle_3),
	
	// STRATIXVI_cmu_fpll_control_block parameters
	.pll_c_counter_0(pll_c_counter_0),
	.pll_c_counter_0_in_src(pll_c_counter_0_in_src),
	.pll_c_counter_0_ph_mux_prst(pll_c_counter_0_ph_mux_prst),
	.pll_c_counter_0_prst(pll_c_counter_0_prst),
	.pll_c_counter_0_coarse_dly(pll_c_counter_0_coarse_dly),
	.pll_c_counter_0_fine_dly(pll_c_counter_0_fine_dly),
	.pll_c_counter_1(pll_c_counter_1),
	.pll_c_counter_1_in_src(pll_c_counter_1_in_src),
	.pll_c_counter_1_ph_mux_prst(pll_c_counter_1_ph_mux_prst),
	.pll_c_counter_1_prst(pll_c_counter_1_prst),
	.pll_c_counter_1_coarse_dly(pll_c_counter_1_coarse_dly),
	.pll_c_counter_1_fine_dly(pll_c_counter_1_fine_dly),
	.pll_c_counter_2(pll_c_counter_2),
	.pll_c_counter_2_in_src(pll_c_counter_2_in_src),
	.pll_c_counter_2_ph_mux_prst(pll_c_counter_2_ph_mux_prst),
	.pll_c_counter_2_prst(pll_c_counter_2_prst),
	.pll_c_counter_2_coarse_dly(pll_c_counter_2_coarse_dly),
	.pll_c_counter_2_fine_dly(pll_c_counter_2_fine_dly),
	.pll_c_counter_3(pll_c_counter_3),
	.pll_c_counter_3_in_src(pll_c_counter_3_in_src),
	.pll_c_counter_3_ph_mux_prst(pll_c_counter_3_ph_mux_prst),
	.pll_c_counter_3_prst(pll_c_counter_3_prst),
	.pll_c_counter_3_coarse_dly(pll_c_counter_3_coarse_dly),
	.pll_c_counter_3_fine_dly(pll_c_counter_3_fine_dly),
	.pll_atb(pll_atb),
	.pll_cp_compensation(pll_cp_compensation),
	.pll_cp_current_setting(pll_cp_current_setting),
	.pll_cp_testmode(pll_cp_testmode),
	.pll_cp_lf_3rd_pole_freq(pll_cp_lf_3rd_pole_freq),
	.pll_cp_lf_4th_pole_freq(pll_cp_lf_4th_pole_freq),
	.pll_cp_lf_order(pll_cp_lf_order),
	.pll_lf_resistance(pll_lf_resistance),
	.pll_lf_ripplecap(pll_lf_ripplecap),
	.pll_cmp_buf_dly(pll_cmp_buf_dly),
	.pll_fbclk_mux_1(pll_fbclk_mux_1),
	.pll_fbclk_mux_2(pll_fbclk_mux_2),
	.pll_iqclk_mux_sel(pll_iqclk_mux_sel),
	.pll_dsm_mode(pll_dsm_mode),
	.pll_dsm_out_sel(pll_dsm_out_sel),
	.pll_dsm_ecn_bypass(pll_dsm_ecn_bypass),
	.pll_dsm_ecn_test_en(pll_dsm_ecn_test_en),
	.pll_dsm_fractional_division(pll_dsm_fractional_division),
	.pll_dsm_fractional_value_ready(pll_dsm_fractional_value_ready),
	.pll_m_counter(pll_m_counter),
	.pll_l_counter_bypass(pll_l_counter_bypass),
	.pll_l_counter(pll_l_counter),
	.pll_l_counter_enable(pll_l_counter_enable),
	.pll_lock_fltr_cfg(pll_lock_fltr_cfg),
	.pll_lock_fltr_test(pll_lock_fltr_test),
	.pll_unlock_fltr_cfg(pll_unlock_fltr_cfg),
	.pll_m_counter_in_src(pll_m_counter_in_src),
	.pll_m_counter_ph_mux_prst(pll_m_counter_ph_mux_prst),
	.pll_m_counter_prst(pll_m_counter_prst),
	.pll_m_counter_coarse_dly(pll_m_counter_coarse_dly),
	.pll_m_counter_fine_dly(pll_m_counter_fine_dly),
	.pll_n_counter(pll_n_counter),
	.pll_n_counter_coarse_dly(pll_n_counter_coarse_dly),
	.pll_n_counter_fine_dly(pll_n_counter_fine_dly),
	.pll_overrange_level(pll_overrange_level),
	.pll_ref_buf_dly(pll_ref_buf_dly),
	.pll_tclk_mux_en(pll_tclk_mux_en),
	.pll_tclk_sel(pll_tclk_sel),
	.pll_underrange_level(pll_underrange_level),
	.pll_vco_ph0_en(pll_vco_ph0_en),
	.pll_vco_ph1_en(pll_vco_ph1_en),
	.pll_vco_ph2_en(pll_vco_ph2_en),
	.pll_vco_ph3_en(pll_vco_ph3_en),
	.pll_vreg0_output(pll_vreg0_output),
	.pll_vreg1_output(pll_vreg1_output),
	.pll_nreset_invert(pll_nreset_invert),
	.pll_ctrl_override_setting(pll_ctrl_override_setting),
	.pll_enable(pll_enable),
	.pll_self_reset(pll_self_reset),
	.pll_test_enable(pll_test_enable),
	.pll_vccr_pd_en(pll_vccr_pd_en)
) cmu_fpll_inst
(
	// Input Ports
	.avmmaddress(avmmaddress),
	.avmmclk(avmmclk),
	.avmmread(avmmread),
	.avmmrstn(avmmrstn),
	.avmmwrite(avmmwrite),
	.avmmwritedata(avmmwritedata),
	.cnt_sel(cnt_sel),
	.csr_bufin(csr_bufin),
	.csr_clk(csr_clk),
	.csr_en(csr_en),
	.csr_in(csr_in),
	.csr_test_mode(csr_test_mode),
	.dps_rst_n(dps_rst_n),
	.fbclk_in(fbclk_in),	
	.iqtxrxclk(iqtxrxclk),
	.mdio_dis(mdio_dis),
	.num_phase_shifts(num_phase_shifts),
	.pfden(pfden),
	.phase_en(phase_en),
	.pma_csr_test_dis(pma_csr_test_dis),
	.refclk(refclk_sel_outclk_wire),
	.rst_n(rst_n),
	.scan_mode_n(scan_mode_n),
	.scan_shift_n(scan_shift_n),
	.up_dn(up_dn),
		
	// Output Ports
	.avmmreaddata(avmmreaddata),
	.block_select(blockselect),
	.clk0(clk0),
	.clk180(clk180),
	.clklow(clklow),
	.csr_bufout(csr_bufout),
	.csr_out(csr_out),
	.fbclk_out(fbclk_out),
	.fref(fref),
	.hclk_out(hclk_out),
	.iqtxrxclk_out(iqtxrxclk_out),
	.lock(lock),
	.outclk(outclk),
	.overrange(overrange),
	.phase_done(phase_done),
	.pll_cascade_out(pll_cascade_out),
	.underrange(underrange)	
);

endmodule
