------------------------------------------------------------------
-- altfp_matrix_mult parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION altfp_matrix_mult (
	calcmatrix,
	enable,
	loadaa,
	loadbb,
	loaddata[WIDTH_EXP+WIDTH_MAN+1-1..0],
	loaddataimag[WIDTH_EXP+WIDTH_MAN+1-1..0],
	loaddatareal[WIDTH_EXP+WIDTH_MAN+1-1..0],
	reset,
	selbus,
	sysclk,
	vector_l_data[VEC_SIZE-1..0],
	vector_m_data[VEC_SIZE-1..0]
)
WITH (
	BLOCKS,
	CLUSTER,
	COLUMNSAA,
	COLUMNSBB,
	ROWSAA,
	VEC_SIZE = 256,
	VECTORSIZE,
	WIDTH_EXP = 8,
	WIDTH_MAN = 23
)
RETURNS (
	done,
	outdata[WIDTH_EXP+WIDTH_MAN+1-1..0],
	outdataimag[WIDTH_EXP+WIDTH_MAN+1-1..0],
	outdatareal[WIDTH_EXP+WIDTH_MAN+1-1..0],
	outvalid,
	ready,
	result[WIDTH_EXP+WIDTH_MAN+1-1..0]
);
