------------------------------------------------------------------
-- altfp_matrix_inv parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION altfp_matrix_inv (
	datain[WIDTH_EXP+WIDTH_MAN+1-1..0],
	enable,
	load,
	reset,
	sysclk
)
WITH (
	BLOCKS,
	CLUSTER,
	DIMENSION,
	WIDTH_EXP = 8,
	WIDTH_MAN = 23
)
RETURNS (
	busy,
	dataout[WIDTH_EXP+WIDTH_MAN+1-1..0],
	done,
	outvalid
);
