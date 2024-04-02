module twentynm_iopll_ip
(
	// iopll input ports
	input [1:0] clken,
	input [3:0] cnt_sel,
	input [3:0] refclk,
	input core_refclk,
	input csr_clk,
	input csr_en,
	input csr_in,
	input csr_test_mode,
	input dprio_clk,
	input dprio_rst_n,
	input dps_rst_n,
	input extswitch,
	input fbclk_in,
	input fblvds_in,
	input mdio_dis,
	input rst_n,
	input [2:0] num_phase_shifts,
	input pfden,
	input phase_en,
	input pma_csr_test_dis,
	input read,
	input pll_cascade_in,
	input [8:0] dprio_address,
	input scan_mode_n,
	input scan_shift_n,
	input up_dn,
	input write,
	input [7:0] writedata,
	input zdb_in,

	// iopll output ports
	output block_select,
	output clk0_bad,
	output clk1_bad,
	output clksel,
	output csr_out,
	output [1:0] extclk_output,
	output [1:0] extclk_dft,
	output fblvds_out,
	output [1:0] loaden,
	output lock,
	output [1:0] lvds_clk,
	output phase_done,
	output pll_cascade_out,
	output [8:0] outclk,
	output dll_output,
	output fbclk_out,
	output [7:0] readdata,
	output [7:0] vcoph
);

// Parameter controlling architecture

// Parameter used in generate statement
parameter number_of_counters = 9;
parameter number_of_extclks = 2;
parameter number_of_fine_delay_chains = 4;

// Virtual parameters
parameter reference_clock_frequency = "100.0 MHz";
parameter vco_frequency = "300.0 MHz";
parameter output_clock_frequency_0 = "100.0 MHz";
parameter output_clock_frequency_1 = "0 ps";
parameter output_clock_frequency_2 = "0 ps";
parameter output_clock_frequency_3 = "0 ps";
parameter output_clock_frequency_4 = "0 ps";
parameter output_clock_frequency_5 = "0 ps";
parameter output_clock_frequency_6 = "0 ps";
parameter output_clock_frequency_7 = "0 ps";
parameter output_clock_frequency_8 = "0 ps";
parameter duty_cycle_0 = 50;
parameter duty_cycle_1 = 50;
parameter duty_cycle_2 = 50;
parameter duty_cycle_3 = 50;
parameter duty_cycle_4 = 50;
parameter duty_cycle_5 = 50;
parameter duty_cycle_6 = 50;
parameter duty_cycle_7 = 50;
parameter duty_cycle_8 = 50;
parameter phase_shift_0 = "0 ps";
parameter phase_shift_1 = "0 ps";
parameter phase_shift_2 = "0 ps";
parameter phase_shift_3 = "0 ps";
parameter phase_shift_4 = "0 ps";
parameter phase_shift_5 = "0 ps";
parameter phase_shift_6 = "0 ps";
parameter phase_shift_7 = "0 ps";
parameter phase_shift_8 = "0 ps";
parameter compensation_mode = "normal";
parameter bw_sel = "auto";
parameter silicon_rev = "reve";
parameter speed_grade = "2";
parameter use_default_base_address = "true";
parameter user_base_address = 0;
parameter is_cascaded_pll = "false";

// STRATIXVI_iopll parameters
parameter pll_atb = "atb_selectdisable";
parameter pll_auto_clk_sw_en = "false";
parameter pll_bwctrl = "pll_bw_res_setting4";
parameter pll_c0_extclk_dllout_en = "false";
parameter pll_c0_out_en = "false";
parameter pll_c1_extclk_dllout_en = "false";
parameter pll_c1_out_en = "false";
parameter pll_c2_extclk_dllout_en = "false";
parameter pll_c2_out_en = "false";
parameter pll_c3_extclk_dllout_en = "false";
parameter pll_c3_out_en = "false";
parameter pll_c4_out_en = "false";
parameter pll_c5_out_en = "false";
parameter pll_c6_out_en = "false";
parameter pll_c7_out_en = "false";
parameter pll_c8_out_en = "false";
parameter pll_c_counter_0_bypass_en = "false";
parameter pll_c_counter_0_coarse_dly = "0 ps";
parameter pll_c_counter_0_even_duty_en = "false";
parameter pll_c_counter_0_fine_dly = "0 ps";
parameter pll_c_counter_0_high = 256;
parameter pll_c_counter_0_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_0_low = 256;
parameter pll_c_counter_0_ph_mux_prst = 0;
parameter pll_c_counter_0_prst = 1;
parameter pll_c_counter_1_bypass_en = "false";
parameter pll_c_counter_1_coarse_dly = "0 ps";
parameter pll_c_counter_1_even_duty_en = "false";
parameter pll_c_counter_1_fine_dly = "0 ps";
parameter pll_c_counter_1_high = 256;
parameter pll_c_counter_1_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_1_low = 256;
parameter pll_c_counter_1_ph_mux_prst = 0;
parameter pll_c_counter_1_prst = 1;
parameter pll_c_counter_2_bypass_en = "false";
parameter pll_c_counter_2_coarse_dly = "0 ps";
parameter pll_c_counter_2_even_duty_en = "false";
parameter pll_c_counter_2_fine_dly = "0 ps";
parameter pll_c_counter_2_high = 256;
parameter pll_c_counter_2_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_2_low = 256;
parameter pll_c_counter_2_ph_mux_prst = 0;
parameter pll_c_counter_2_prst = 1;
parameter pll_c_counter_3_bypass_en = "false";
parameter pll_c_counter_3_coarse_dly = "0 ps";
parameter pll_c_counter_3_even_duty_en = "false";
parameter pll_c_counter_3_fine_dly = "0 ps";
parameter pll_c_counter_3_high = 256;
parameter pll_c_counter_3_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_3_low = 256;
parameter pll_c_counter_3_ph_mux_prst = 0;
parameter pll_c_counter_3_prst = 1;
parameter pll_c_counter_4_bypass_en = "false";
parameter pll_c_counter_4_coarse_dly = "0 ps";
parameter pll_c_counter_4_even_duty_en = "false";
parameter pll_c_counter_4_fine_dly = "0 ps";
parameter pll_c_counter_4_high = 256;
parameter pll_c_counter_4_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_4_low = 256;
parameter pll_c_counter_4_ph_mux_prst = 0;
parameter pll_c_counter_4_prst = 1;
parameter pll_c_counter_5_bypass_en = "false";
parameter pll_c_counter_5_coarse_dly = "0 ps";
parameter pll_c_counter_5_even_duty_en = "false";
parameter pll_c_counter_5_fine_dly = "0 ps";
parameter pll_c_counter_5_high = 256;
parameter pll_c_counter_5_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_5_low = 256;
parameter pll_c_counter_5_ph_mux_prst = 0;
parameter pll_c_counter_5_prst = 1;
parameter pll_c_counter_6_bypass_en = "false";
parameter pll_c_counter_6_coarse_dly = "0 ps";
parameter pll_c_counter_6_even_duty_en = "false";
parameter pll_c_counter_6_fine_dly = "0 ps";
parameter pll_c_counter_6_high = 256;
parameter pll_c_counter_6_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_6_low = 256;
parameter pll_c_counter_6_ph_mux_prst = 0;
parameter pll_c_counter_6_prst = 1;
parameter pll_c_counter_7_bypass_en = "false";
parameter pll_c_counter_7_coarse_dly = "0 ps";
parameter pll_c_counter_7_even_duty_en = "false";
parameter pll_c_counter_7_fine_dly = "0 ps";
parameter pll_c_counter_7_high = 256;
parameter pll_c_counter_7_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_7_low = 256;
parameter pll_c_counter_7_ph_mux_prst = 0;
parameter pll_c_counter_7_prst = 1;
parameter pll_c_counter_8_bypass_en = "false";
parameter pll_c_counter_8_coarse_dly = "0 ps";
parameter pll_c_counter_8_even_duty_en = "false";
parameter pll_c_counter_8_fine_dly = "0 ps";
parameter pll_c_counter_8_high =256;
parameter pll_c_counter_8_in_src = "c_m_cnt_in_src_test_clk";
parameter pll_c_counter_8_low = 256;
parameter pll_c_counter_8_ph_mux_prst = 0;
parameter pll_c_counter_8_prst = 1;
parameter pll_clk_loss_edge = "pll_clk_loss_both_edges";
parameter pll_clk_loss_sw_en = "false";
parameter pll_clk_sw_dly = 0;
parameter pll_clkin_0_src = "pll_clkin_0_src_ioclkin_0";
parameter pll_clkin_1_src = "pll_clkin_1_src_ioclkin_0";
parameter pll_cmp_buf_dly = "0 ps";
parameter pll_coarse_dly_0 = "0 ps";
parameter pll_coarse_dly_1 = "0 ps";
parameter pll_coarse_dly_2 = "0 ps";
parameter pll_coarse_dly_3 = "0 ps";
parameter pll_cp_compensation = "true";
parameter pll_cp_current_setting = "pll_cp_setting2";
parameter pll_ctrl_override_setting = "false";
parameter pll_dft_plniotri_override = "false";
parameter pll_dft_ppmclk = "c_cnt_out";
parameter pll_dll_src = "pll_dll_src_vss";
parameter pll_dly_0_enable = "false";
parameter pll_dly_1_enable = "false";
parameter pll_dly_2_enable = "false";
parameter pll_dly_3_enable = "false";
parameter pll_enable = "true";
parameter pll_extclk_0_cnt_src = "pll_extclk_cnt_src_vss";
parameter pll_extclk_0_enable = "false";
parameter pll_extclk_0_invert = "false";
parameter pll_extclk_1_cnt_src = "pll_extclk_cnt_src_vss";
parameter pll_extclk_1_enable = "false";
parameter pll_extclk_1_invert = "false";
parameter pll_fbclk_mux_1 = "pll_fbclk_mux_1_glb";
parameter pll_fbclk_mux_2 = "pll_fbclk_mux_2_fb_1";
parameter pll_fine_dly_0 = "0 ps";
parameter pll_fine_dly_1 = "0 ps";
parameter pll_fine_dly_2 = "0 ps";
parameter pll_fine_dly_3 = "0 ps";
parameter pll_lock_fltr_cfg = 25;
parameter pll_lock_fltr_test = "pll_lock_fltr_nrm";
parameter pll_m_counter_bypass_en = "true";
parameter pll_m_counter_coarse_dly = "0 ps";
parameter pll_m_counter_even_duty_en = "false";
parameter pll_m_counter_fine_dly = "0 ps";
parameter pll_m_counter_high = 256;
parameter pll_m_counter_in_src = "c_m_cnt_in_src_ph_mux_clk";
parameter pll_m_counter_low = 256;
parameter pll_m_counter_ph_mux_prst = 0;
parameter pll_m_counter_prst = 1;
parameter pll_manu_clk_sw_en = "false";
parameter pll_mode = "false";
parameter pll_n_counter_bypass_en = "true";
parameter pll_n_counter_coarse_dly = "0 ps";
parameter pll_n_counter_fine_dly = "0 ps";
parameter pll_n_counter_high = 256;
parameter pll_n_counter_low = 256;
parameter pll_n_counter_odd_div_duty_en = "false";
parameter pll_nreset_invert = "false";
parameter pll_phyfb_mux = "m_cnt_phmux_out";
parameter pll_ref_buf_dly = "0 ps";
parameter pll_ripplecap_ctrl = "pll_ripplecap_setting0";
parameter pll_self_reset = "false";
parameter pll_sw_refclk_src = "pll_sw_refclk_src_clk_0";
parameter pll_tclk_mux_en = "false";
parameter pll_tclk_sel = "pll_tclk_m_src";
parameter pll_test_enable = "false";
parameter pll_testdn_enable = "false";
parameter pll_testup_enable = "false";
parameter pll_unlock_fltr_cfg = 2;
parameter pll_vccr_pd_en = "false";
parameter pll_vco_ph0_en = "true";
parameter pll_vco_ph1_en = "true";
parameter pll_vco_ph2_en = "true";
parameter pll_vco_ph3_en = "true";
parameter pll_vco_ph4_en = "true";
parameter pll_vco_ph5_en = "true";
parameter pll_vco_ph6_en = "true";
parameter pll_vco_ph7_en = "true";
parameter pll_vreg0_output = "vccdreg_nominal";
parameter pll_vreg1_output = "vccdreg_nominal";

// instantiate STRATIXVI_iopll block
STRATIXVI_iopll iopll_inst (
	.clken(clken),
	.cnt_sel(cnt_sel),
	.core_refclk(core_refclk),
	.csr_clk(csr_clk),
	.csr_en(csr_en),
	.csr_in(csr_in),
	.csr_test_mode(csr_test_mode),
	.dprio_address(dprio_address),
	.dprio_clk(dprio_clk),
	.dprio_rst_n(dprio_rst_n),
	.dps_rst_n(dps_rst_n),
	.extswitch(extswitch),
	.fbclk_in(fbclk_in),
	.fblvds_in(fblvds_in),
	.mdio_dis(mdio_dis),
	.num_phase_shifts(num_phase_shifts),
	.pfden(pfden),
	.phase_en(phase_en),
	.pll_cascade_in(pll_cascade_in),
	.pma_csr_test_dis(pma_csr_test_dis),
	.read(read),
	.refclk(refclk),
	.rst_n(rst_n),
	.scan_mode_n(scan_mode_n),
	.scan_shift_n(scan_shift_n),
	.up_dn(up_dn),
	.write(write),
	.writedata(writedata),
	.zdb_in(zdb_in),
	
	// Output port declarations
	.block_select(block_select),
	.clk0_bad(clk0_bad),
	.clk1_bad(clk1_bad),
	.clksel(clksel),
	.csr_out(csr_out),
	.dll_output(dll_output),
	.extclk_dft(extclk_dft),
	.extclk_output(extclk_output),
	.fbclk_out(fbclk_out),
	.fblvds_out(fblvds_out),
	.loaden(loaden),
	.lock(lock),
	.lvds_clk(lvds_clk),
	.outclk(outclk),
	.phase_done(phase_done),
	.pll_cascade_out(pll_cascade_out),
	.readdata(readdata),
	.vcoph(vcoph)
);
defparam iopll_inst.reference_clock_frequency = reference_clock_frequency;
defparam iopll_inst.vco_frequency = vco_frequency;
defparam iopll_inst.output_clock_frequency_0 = output_clock_frequency_0;
defparam iopll_inst.output_clock_frequency_1 = output_clock_frequency_1;
defparam iopll_inst.output_clock_frequency_2 = output_clock_frequency_2;
defparam iopll_inst.output_clock_frequency_3 = output_clock_frequency_3;
defparam iopll_inst.output_clock_frequency_4 = output_clock_frequency_4;
defparam iopll_inst.output_clock_frequency_5 = output_clock_frequency_5;
defparam iopll_inst.output_clock_frequency_6 = output_clock_frequency_6;
defparam iopll_inst.output_clock_frequency_7 = output_clock_frequency_7;
defparam iopll_inst.output_clock_frequency_8 = output_clock_frequency_8;
defparam iopll_inst.duty_cycle_0 = duty_cycle_0;
defparam iopll_inst.duty_cycle_1 = duty_cycle_1;
defparam iopll_inst.duty_cycle_2 = duty_cycle_2;
defparam iopll_inst.duty_cycle_3 = duty_cycle_3;
defparam iopll_inst.duty_cycle_4 = duty_cycle_4;
defparam iopll_inst.duty_cycle_5 = duty_cycle_5;
defparam iopll_inst.duty_cycle_6 = duty_cycle_6;
defparam iopll_inst.duty_cycle_7 = duty_cycle_7;
defparam iopll_inst.duty_cycle_8 = duty_cycle_8;
defparam iopll_inst.phase_shift_0 = phase_shift_0;
defparam iopll_inst.phase_shift_1 = phase_shift_1;
defparam iopll_inst.phase_shift_2 = phase_shift_2;
defparam iopll_inst.phase_shift_3 = phase_shift_3;
defparam iopll_inst.phase_shift_4 = phase_shift_4;
defparam iopll_inst.phase_shift_5 = phase_shift_5;
defparam iopll_inst.phase_shift_6 = phase_shift_6;
defparam iopll_inst.phase_shift_7 = phase_shift_7;
defparam iopll_inst.phase_shift_8 = phase_shift_8;
defparam iopll_inst.compensation_mode = compensation_mode;
defparam iopll_inst.bw_sel = bw_sel;
defparam iopll_inst.silicon_rev = silicon_rev;
defparam iopll_inst.speed_grade = speed_grade;
defparam iopll_inst.use_default_base_address = use_default_base_address;
defparam iopll_inst.user_base_address = user_base_address;
defparam iopll_inst.is_cascaded_pll = is_cascaded_pll;
defparam iopll_inst.pll_atb = pll_atb;
defparam iopll_inst.pll_auto_clk_sw_en = pll_auto_clk_sw_en;
defparam iopll_inst.pll_bwctrl = pll_bwctrl;
defparam iopll_inst.pll_c0_extclk_dllout_en = pll_c0_extclk_dllout_en;
defparam iopll_inst.pll_c0_out_en = pll_c0_out_en;
defparam iopll_inst.pll_c1_extclk_dllout_en = pll_c1_extclk_dllout_en;
defparam iopll_inst.pll_c1_out_en = pll_c1_out_en;
defparam iopll_inst.pll_c2_extclk_dllout_en = pll_c2_extclk_dllout_en;
defparam iopll_inst.pll_c2_out_en = pll_c2_out_en;
defparam iopll_inst.pll_c3_extclk_dllout_en = pll_c3_extclk_dllout_en;
defparam iopll_inst.pll_c3_out_en = pll_c3_out_en;
defparam iopll_inst.pll_c4_out_en = pll_c4_out_en;
defparam iopll_inst.pll_c5_out_en = pll_c5_out_en;
defparam iopll_inst.pll_c6_out_en = pll_c6_out_en;
defparam iopll_inst.pll_c7_out_en = pll_c7_out_en;
defparam iopll_inst.pll_c8_out_en = pll_c8_out_en;
defparam iopll_inst.pll_c_counter_0_bypass_en = pll_c_counter_0_bypass_en;
defparam iopll_inst.pll_c_counter_0_coarse_dly = pll_c_counter_0_coarse_dly;
defparam iopll_inst.pll_c_counter_0_even_duty_en = pll_c_counter_0_even_duty_en;
defparam iopll_inst.pll_c_counter_0_fine_dly = pll_c_counter_0_fine_dly;
defparam iopll_inst.pll_c_counter_0_high = pll_c_counter_0_high;
defparam iopll_inst.pll_c_counter_0_in_src = pll_c_counter_0_in_src;
defparam iopll_inst.pll_c_counter_0_low = pll_c_counter_0_low;
defparam iopll_inst.pll_c_counter_0_ph_mux_prst = pll_c_counter_0_ph_mux_prst;
defparam iopll_inst.pll_c_counter_0_prst = pll_c_counter_0_prst;
defparam iopll_inst.pll_c_counter_1_bypass_en = pll_c_counter_1_bypass_en;
defparam iopll_inst.pll_c_counter_1_coarse_dly = pll_c_counter_1_coarse_dly;
defparam iopll_inst.pll_c_counter_1_even_duty_en = pll_c_counter_1_even_duty_en;
defparam iopll_inst.pll_c_counter_1_fine_dly = pll_c_counter_1_fine_dly;
defparam iopll_inst.pll_c_counter_1_high = pll_c_counter_1_high;
defparam iopll_inst.pll_c_counter_1_in_src = pll_c_counter_1_in_src;
defparam iopll_inst.pll_c_counter_1_low = pll_c_counter_1_low;
defparam iopll_inst.pll_c_counter_1_ph_mux_prst = pll_c_counter_1_ph_mux_prst;
defparam iopll_inst.pll_c_counter_1_prst = pll_c_counter_1_prst;
defparam iopll_inst.pll_c_counter_2_bypass_en = pll_c_counter_2_bypass_en;
defparam iopll_inst.pll_c_counter_2_coarse_dly = pll_c_counter_2_coarse_dly;
defparam iopll_inst.pll_c_counter_2_even_duty_en = pll_c_counter_2_even_duty_en;
defparam iopll_inst.pll_c_counter_2_fine_dly = pll_c_counter_2_fine_dly;
defparam iopll_inst.pll_c_counter_2_high = pll_c_counter_2_high;
defparam iopll_inst.pll_c_counter_2_in_src = pll_c_counter_2_in_src;
defparam iopll_inst.pll_c_counter_2_low = pll_c_counter_2_low;
defparam iopll_inst.pll_c_counter_2_ph_mux_prst = pll_c_counter_2_ph_mux_prst;
defparam iopll_inst.pll_c_counter_2_prst = pll_c_counter_2_prst;
defparam iopll_inst.pll_c_counter_3_bypass_en = pll_c_counter_3_bypass_en;
defparam iopll_inst.pll_c_counter_3_coarse_dly = pll_c_counter_3_coarse_dly;
defparam iopll_inst.pll_c_counter_3_even_duty_en = pll_c_counter_3_even_duty_en;
defparam iopll_inst.pll_c_counter_3_fine_dly = pll_c_counter_3_fine_dly;
defparam iopll_inst.pll_c_counter_3_high = pll_c_counter_3_high;
defparam iopll_inst.pll_c_counter_3_in_src = pll_c_counter_3_in_src;
defparam iopll_inst.pll_c_counter_3_low = pll_c_counter_3_low;
defparam iopll_inst.pll_c_counter_3_ph_mux_prst = pll_c_counter_3_ph_mux_prst;
defparam iopll_inst.pll_c_counter_3_prst = pll_c_counter_3_prst;
defparam iopll_inst.pll_c_counter_4_bypass_en = pll_c_counter_4_bypass_en;
defparam iopll_inst.pll_c_counter_4_coarse_dly = pll_c_counter_4_coarse_dly;
defparam iopll_inst.pll_c_counter_4_even_duty_en = pll_c_counter_4_even_duty_en;
defparam iopll_inst.pll_c_counter_4_fine_dly = pll_c_counter_4_fine_dly;
defparam iopll_inst.pll_c_counter_4_high = pll_c_counter_4_high;
defparam iopll_inst.pll_c_counter_4_in_src = pll_c_counter_4_in_src;
defparam iopll_inst.pll_c_counter_4_low = pll_c_counter_4_low;
defparam iopll_inst.pll_c_counter_4_ph_mux_prst = pll_c_counter_4_ph_mux_prst;
defparam iopll_inst.pll_c_counter_4_prst = pll_c_counter_4_prst;
defparam iopll_inst.pll_c_counter_5_bypass_en = pll_c_counter_5_bypass_en;
defparam iopll_inst.pll_c_counter_5_coarse_dly = pll_c_counter_5_coarse_dly;
defparam iopll_inst.pll_c_counter_5_even_duty_en = pll_c_counter_5_even_duty_en;
defparam iopll_inst.pll_c_counter_5_fine_dly = pll_c_counter_5_fine_dly;
defparam iopll_inst.pll_c_counter_5_high = pll_c_counter_5_high;
defparam iopll_inst.pll_c_counter_5_in_src = pll_c_counter_5_in_src;
defparam iopll_inst.pll_c_counter_5_low = pll_c_counter_5_low;
defparam iopll_inst.pll_c_counter_5_ph_mux_prst = pll_c_counter_5_ph_mux_prst;
defparam iopll_inst.pll_c_counter_5_prst = pll_c_counter_5_prst;
defparam iopll_inst.pll_c_counter_6_bypass_en = pll_c_counter_6_bypass_en;
defparam iopll_inst.pll_c_counter_6_coarse_dly = pll_c_counter_6_coarse_dly;
defparam iopll_inst.pll_c_counter_6_even_duty_en = pll_c_counter_6_even_duty_en;
defparam iopll_inst.pll_c_counter_6_fine_dly = pll_c_counter_6_fine_dly;
defparam iopll_inst.pll_c_counter_6_high = pll_c_counter_6_high;
defparam iopll_inst.pll_c_counter_6_in_src = pll_c_counter_6_in_src;
defparam iopll_inst.pll_c_counter_6_low = pll_c_counter_6_low;
defparam iopll_inst.pll_c_counter_6_ph_mux_prst = pll_c_counter_6_ph_mux_prst;
defparam iopll_inst.pll_c_counter_6_prst = pll_c_counter_6_prst;
defparam iopll_inst.pll_c_counter_7_bypass_en = pll_c_counter_7_bypass_en;
defparam iopll_inst.pll_c_counter_7_coarse_dly = pll_c_counter_7_coarse_dly;
defparam iopll_inst.pll_c_counter_7_even_duty_en = pll_c_counter_7_even_duty_en;
defparam iopll_inst.pll_c_counter_7_fine_dly = pll_c_counter_7_fine_dly;
defparam iopll_inst.pll_c_counter_7_high = pll_c_counter_7_high;
defparam iopll_inst.pll_c_counter_7_in_src = pll_c_counter_7_in_src;
defparam iopll_inst.pll_c_counter_7_low = pll_c_counter_7_low;
defparam iopll_inst.pll_c_counter_7_ph_mux_prst = pll_c_counter_7_ph_mux_prst;
defparam iopll_inst.pll_c_counter_7_prst = pll_c_counter_7_prst;
defparam iopll_inst.pll_c_counter_8_bypass_en = pll_c_counter_8_bypass_en;
defparam iopll_inst.pll_c_counter_8_coarse_dly = pll_c_counter_8_coarse_dly;
defparam iopll_inst.pll_c_counter_8_even_duty_en = pll_c_counter_8_even_duty_en;
defparam iopll_inst.pll_c_counter_8_fine_dly = pll_c_counter_8_fine_dly;
defparam iopll_inst.pll_c_counter_8_high = pll_c_counter_8_high;
defparam iopll_inst.pll_c_counter_8_in_src = pll_c_counter_8_in_src;
defparam iopll_inst.pll_c_counter_8_low = pll_c_counter_8_low;
defparam iopll_inst.pll_c_counter_8_ph_mux_prst = pll_c_counter_8_ph_mux_prst;
defparam iopll_inst.pll_c_counter_8_prst = pll_c_counter_8_prst;
defparam iopll_inst.pll_clk_loss_edge = pll_clk_loss_edge;
defparam iopll_inst.pll_clk_loss_sw_en = pll_clk_loss_sw_en;
defparam iopll_inst.pll_clk_sw_dly = pll_clk_sw_dly;
defparam iopll_inst.pll_clkin_0_src = pll_clkin_0_src;
defparam iopll_inst.pll_clkin_1_src = pll_clkin_1_src;
defparam iopll_inst.pll_cmp_buf_dly = pll_cmp_buf_dly;
defparam iopll_inst.pll_coarse_dly_0 = pll_coarse_dly_0;
defparam iopll_inst.pll_coarse_dly_1 = pll_coarse_dly_1;
defparam iopll_inst.pll_coarse_dly_2 = pll_coarse_dly_2;
defparam iopll_inst.pll_coarse_dly_3 = pll_coarse_dly_3;
defparam iopll_inst.pll_cp_compensation = pll_cp_compensation;
defparam iopll_inst.pll_cp_current_setting = pll_cp_current_setting;
defparam iopll_inst.pll_ctrl_override_setting = pll_ctrl_override_setting;
defparam iopll_inst.pll_dft_plniotri_override = pll_dft_plniotri_override;
defparam iopll_inst.pll_dft_ppmclk = pll_dft_ppmclk;
defparam iopll_inst.pll_dll_src = pll_dll_src;
defparam iopll_inst.pll_dly_0_enable = pll_dly_0_enable;
defparam iopll_inst.pll_dly_1_enable = pll_dly_1_enable;
defparam iopll_inst.pll_dly_2_enable = pll_dly_2_enable;
defparam iopll_inst.pll_dly_3_enable = pll_dly_3_enable;
defparam iopll_inst.pll_enable = pll_enable;
defparam iopll_inst.pll_extclk_0_cnt_src = pll_extclk_0_cnt_src;
defparam iopll_inst.pll_extclk_0_enable = pll_extclk_0_enable;
defparam iopll_inst.pll_extclk_0_invert = pll_extclk_0_invert;
defparam iopll_inst.pll_extclk_1_cnt_src = pll_extclk_1_cnt_src;
defparam iopll_inst.pll_extclk_1_enable = pll_extclk_1_enable;
defparam iopll_inst.pll_extclk_1_invert = pll_extclk_1_invert;
defparam iopll_inst.pll_fbclk_mux_1 = pll_fbclk_mux_1;
defparam iopll_inst.pll_fbclk_mux_2 = pll_fbclk_mux_2;
defparam iopll_inst.pll_fine_dly_0 = pll_fine_dly_0;
defparam iopll_inst.pll_fine_dly_1 = pll_fine_dly_1;
defparam iopll_inst.pll_fine_dly_2 = pll_fine_dly_2;
defparam iopll_inst.pll_fine_dly_3 = pll_fine_dly_3;
defparam iopll_inst.pll_lock_fltr_cfg = pll_lock_fltr_cfg;
defparam iopll_inst.pll_lock_fltr_test = pll_lock_fltr_test;
defparam iopll_inst.pll_m_counter_bypass_en = pll_m_counter_bypass_en;
defparam iopll_inst.pll_m_counter_coarse_dly = pll_m_counter_coarse_dly;
defparam iopll_inst.pll_m_counter_even_duty_en = pll_m_counter_even_duty_en;
defparam iopll_inst.pll_m_counter_fine_dly = pll_m_counter_fine_dly;
defparam iopll_inst.pll_m_counter_high = pll_m_counter_high;
defparam iopll_inst.pll_m_counter_in_src = pll_m_counter_in_src;
defparam iopll_inst.pll_m_counter_low = pll_m_counter_low;
defparam iopll_inst.pll_m_counter_ph_mux_prst = pll_m_counter_ph_mux_prst;
defparam iopll_inst.pll_m_counter_prst = pll_m_counter_prst;
defparam iopll_inst.pll_manu_clk_sw_en = pll_manu_clk_sw_en;
defparam iopll_inst.pll_mode = pll_mode;
defparam iopll_inst.pll_n_counter_bypass_en = pll_n_counter_bypass_en;
defparam iopll_inst.pll_n_counter_coarse_dly = pll_n_counter_coarse_dly;
defparam iopll_inst.pll_n_counter_fine_dly = pll_n_counter_fine_dly;
defparam iopll_inst.pll_n_counter_high = pll_n_counter_high;
defparam iopll_inst.pll_n_counter_low = pll_n_counter_low;
defparam iopll_inst.pll_n_counter_odd_div_duty_en = pll_n_counter_odd_div_duty_en;
defparam iopll_inst.pll_nreset_invert = pll_nreset_invert;
defparam iopll_inst.pll_phyfb_mux = pll_phyfb_mux;
defparam iopll_inst.pll_ref_buf_dly = pll_ref_buf_dly;
defparam iopll_inst.pll_ripplecap_ctrl = pll_ripplecap_ctrl;
defparam iopll_inst.pll_self_reset = pll_self_reset;
defparam iopll_inst.pll_sw_refclk_src = pll_sw_refclk_src;
defparam iopll_inst.pll_tclk_mux_en = pll_tclk_mux_en;
defparam iopll_inst.pll_tclk_sel = pll_tclk_sel;
defparam iopll_inst.pll_test_enable = pll_test_enable;
defparam iopll_inst.pll_testdn_enable = pll_testdn_enable;
defparam iopll_inst.pll_testup_enable = pll_testup_enable;
defparam iopll_inst.pll_unlock_fltr_cfg = pll_unlock_fltr_cfg;
defparam iopll_inst.pll_vccr_pd_en =pll_vccr_pd_en;
defparam iopll_inst.pll_vco_ph0_en = pll_vco_ph0_en;
defparam iopll_inst.pll_vco_ph1_en = pll_vco_ph1_en;
defparam iopll_inst.pll_vco_ph2_en = pll_vco_ph2_en;
defparam iopll_inst.pll_vco_ph3_en = pll_vco_ph3_en;
defparam iopll_inst.pll_vco_ph4_en = pll_vco_ph4_en;
defparam iopll_inst.pll_vco_ph5_en = pll_vco_ph5_en;
defparam iopll_inst.pll_vco_ph6_en = pll_vco_ph6_en;
defparam iopll_inst.pll_vco_ph7_en = pll_vco_ph7_en;
defparam iopll_inst.pll_vreg0_output = pll_vreg0_output;
defparam iopll_inst.pll_vreg1_output = pll_vreg1_output;

endmodule
