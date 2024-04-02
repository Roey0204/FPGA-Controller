------------------------------------------------------------------
-- altfp_atan parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION altfp_atan (
	aclr,
	clk_en,
	clock,
	data[WIDTH_EXP+WIDTH_MAN+1-1..0]
)
WITH (
	PIPELINE,
	ROUNDING,
	WIDTH_EXP = 8,
	WIDTH_MAN = 23
)
RETURNS (
	result[WIDTH_EXP+WIDTH_MAN+1-1..0]
);
