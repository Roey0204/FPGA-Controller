------------------------------------------------------------------
-- stratixv_mac parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION stratixv_mac (
	accumulate,
	aclr[1..0],
	ax[ax_width-1..0],
	ay[ay_scan_in_width-1..0],
	az[az_width-1..0],
	bx[bx_width-1..0],
	by[by_width-1..0],
	chainin[63..0],
	cin,
	clk[2..0],
	coefsela[2..0],
	coefselb[2..0],
	complex,
	ena[2..0],
	loadconst,
	negate,
	scanin[ay_scan_in_width-1..0],
	sub
)
WITH (
	accumulate_clock,
	ax_clock,
	ax_width = 16,
	ay_scan_in_clock,
	ay_scan_in_width = 16,
	ay_use_scan_in,
	az_clock,
	az_width = 1,
	bx_clock,
	bx_width = 16,
	by_clock,
	by_use_scan_in,
	by_width = 16,
	coef_a_0,
	coef_a_1,
	coef_a_2,
	coef_a_3,
	coef_a_4,
	coef_a_5,
	coef_a_6,
	coef_a_7,
	coef_b_0,
	coef_b_1,
	coef_b_2,
	coef_b_3,
	coef_b_4,
	coef_b_5,
	coef_b_6,
	coef_b_7,
	coef_sel_a_clock,
	coef_sel_b_clock,
	complex_clock,
	delay_scan_out_ay,
	delay_scan_out_by,
	load_const_clock,
	load_const_value,
	mode_sub_location,
	negate_clock,
	operand_source_max,
	operand_source_may,
	operand_source_mbx,
	operand_source_mby,
	operation_mode,
	output_clock,
	preadder_subtract_a,
	preadder_subtract_b,
	result_a_width = 64,
	result_b_width = 1,
	scan_out_width = 1,
	signed_max,
	signed_may,
	signed_mbx,
	signed_mby,
	sub_clock,
	use_chainadder
)
RETURNS (
	chainout[63..0],
	cout,
	dftout,
	resulta[result_a_width-1..0],
	resultb[result_b_width-1..0],
	scanout[scan_out_width-1..0]
);
