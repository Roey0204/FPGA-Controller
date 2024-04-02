------------------------------------------------------------------
-- altfp_sincos parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION altfp_sincos (
	aclr,
	clk_en,
	clock,
	data[WIDTH_EXP+WIDTH_MAN+1-1..0]
)
WITH (
	CORDIC_DEPTH,
	CORDIC_WIDTH,
	INDEXPOINT,
	OPERATION,
	PIPELINE,
	ROUNDING,
	WIDTH_EXP = 8,
	WIDTH_MAN = 23
)
RETURNS (
	nan,
	result[WIDTH_EXP+WIDTH_MAN+1-1..0],
	zero
);
