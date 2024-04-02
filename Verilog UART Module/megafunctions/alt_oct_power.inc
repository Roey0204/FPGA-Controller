------------------------------------------------------------------
-- alt_oct_power parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION alt_oct_power (
	rdn[0..0],
	rup[0..0],
	rzqin[0..0]
)
WITH (
	WIDTH_PTC = 14,
	WIDTH_STC = 14
)
RETURNS (
	parallelterminationcontrol[WIDTH_PTC-1..0],
	serdata,
	seriesterminationcontrol[WIDTH_STC-1..0],
	termination_control[16-1..0],
	terminationclock,
	terminationdata,
	terminationselect
);
