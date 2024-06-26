------------------------------------------------------------------
-- altmult_accum parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION altmult_accum (
	accum_round,
	accum_saturation,
	accum_sload,
	accum_sload_upper_data[WIDTH_UPPER_DATA-1..0],
	aclr0,
	aclr1,
	aclr2,
	aclr3,
	addnsub,
	clock0,
	clock1,
	clock2,
	clock3,
	coefsel0[2..0],
	coefsel1[2..0],
	coefsel2[2..0],
	coefsel3[2..0],
	dataa[WIDTH_A-1..0],
	datab[WIDTH_B-1..0],
	datac[WIDTH_C-1..0],
	ena0,
	ena1,
	ena2,
	ena3,
	mult_round,
	mult_saturation,
	scanina[WIDTH_A-1..0],
	scaninb[WIDTH_B-1..0],
	signa,
	signb,
	sourcea,
	sourceb
)
WITH (
	ACCUM_DIRECTION,
	ACCUM_ROUND_ACLR,
	ACCUM_ROUND_PIPELINE_ACLR,
	ACCUM_ROUND_PIPELINE_REG,
	ACCUM_ROUND_REG,
	ACCUM_SATURATION_ACLR,
	ACCUM_SATURATION_PIPELINE_ACLR,
	ACCUM_SATURATION_PIPELINE_REG,
	ACCUM_SATURATION_REG,
	ACCUM_SLOAD_ACLR,
	ACCUM_SLOAD_PIPELINE_ACLR,
	ACCUM_SLOAD_PIPELINE_REG,
	ACCUM_SLOAD_REG,
	ACCUM_SLOAD_UPPER_DATA_ACLR,
	ACCUM_SLOAD_UPPER_DATA_PIPELINE_ACLR,
	ACCUM_SLOAD_UPPER_DATA_PIPELINE_REG,
	ACCUM_SLOAD_UPPER_DATA_REG,
	ACCUMULATOR_ROUNDING,
	ACCUMULATOR_SATURATION,
	ADDNSUB_ACLR,
	ADDNSUB_PIPELINE_ACLR,
	ADDNSUB_PIPELINE_REG,
	ADDNSUB_REG,
	COEF0_0,
	COEF0_1,
	COEF0_2,
	COEF0_3,
	COEF0_4,
	COEF0_5,
	COEF0_6,
	COEF0_7,
	COEF1_0,
	COEF1_1,
	COEF1_2,
	COEF1_3,
	COEF1_4,
	COEF1_5,
	COEF1_6,
	COEF1_7,
	COEF2_0,
	COEF2_1,
	COEF2_2,
	COEF2_3,
	COEF2_4,
	COEF2_5,
	COEF2_6,
	COEF2_7,
	COEF3_0,
	COEF3_1,
	COEF3_2,
	COEF3_3,
	COEF3_4,
	COEF3_5,
	COEF3_6,
	COEF3_7,
	COEFSEL0_ACLR,
	COEFSEL0_REGISTER,
	COEFSEL1_ACLR,
	COEFSEL1_REGISTER,
	COEFSEL2_ACLR,
	COEFSEL2_REGISTER,
	COEFSEL3_ACLR,
	COEFSEL3_REGISTER,
	DEDICATED_MULTIPLIER_CIRCUITRY,
	DOUBLE_ACCUM,
	DSP_BLOCK_BALANCING,
	EXTRA_ACCUMULATOR_LATENCY,
	EXTRA_MULTIPLIER_LATENCY,
	INPUT_ACLR_A,
	INPUT_ACLR_B,
	INPUT_ACLR_C0,
	INPUT_ACLR_C1,
	INPUT_ACLR_C2,
	INPUT_ACLR_C3,
	INPUT_REG_A,
	INPUT_REG_B,
	INPUT_REGISTER_C0,
	INPUT_REGISTER_C1,
	INPUT_REGISTER_C2,
	INPUT_REGISTER_C3,
	INPUT_SOURCE_A,
	INPUT_SOURCE_B,
	LOADCONST_CONTROL_ACLR,
	LOADCONST_CONTROL_REGISTER,
	LOADCONST_VALUE,
	MULT_ROUND_ACLR,
	MULT_ROUND_REG,
	MULT_SATURATION_ACLR,
	MULT_SATURATION_REG,
	MULTIPLIER1_DIRECTION,
	MULTIPLIER3_DIRECTION,
	MULTIPLIER_ACLR,
	MULTIPLIER_REG,
	MULTIPLIER_ROUNDING,
	MULTIPLIER_SATURATION,
	NUMBER_OF_MULTIPLIERS,
	OUTPUT_ACLR,
	OUTPUT_REG,
	PORT_ACCUM_IS_SATURATED,
	PORT_ADDNSUB,
	PORT_MULT_IS_SATURATED,
	PORT_SIGNA,
	PORT_SIGNB,
	PREADDER_DIRECTION_0,
	PREADDER_DIRECTION_1,
	PREADDER_DIRECTION_2,
	PREADDER_DIRECTION_3,
	PREADDER_MODE,
	REPRESENTATION_A,
	REPRESENTATION_B,
	SIGN_ACLR_A,
	SIGN_ACLR_B,
	SIGN_PIPELINE_ACLR_A,
	SIGN_PIPELINE_ACLR_B,
	SIGN_PIPELINE_REG_A,
	SIGN_PIPELINE_REG_B,
	SIGN_REG_A,
	SIGN_REG_B,
	SYSTOLIC_ACLR1,
	SYSTOLIC_ACLR3,
	SYSTOLIC_DELAY1,
	SYSTOLIC_DELAY3,
	WIDTH_A,
	WIDTH_B,
	WIDTH_C = 22,
	WIDTH_COEF,
	WIDTH_RESULT,
	WIDTH_UPPER_DATA = 1
)
RETURNS (
	accum_is_saturated,
	mult_is_saturated,
	overflow,
	result[WIDTH_RESULT-1..0],
	scanouta[WIDTH_A-1..0],
	scanoutb[WIDTH_B-1..0]
);
