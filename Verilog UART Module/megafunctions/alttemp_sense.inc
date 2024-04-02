------------------------------------------------------------------
-- alttemp_sense parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION alttemp_sense (
	aclr,
	ce,
	clk,
	clr,
	compouttest,
	fdbkctrlfromcore,
	offset[5..0],
	testin[7..0],
	tsd_trig
)
WITH (
	CLK_FREQUENCY,
	CLOCK_DIVIDER_ENABLE,
	CLOCK_DIVIDER_VALUE,
	NUMBER_OF_SAMPLES,
	POI_CAL_TEMPERATURE,
	SIM_TSDCALO,
	USE_WYS,
	USER_OFFSET_ENABLE
)
RETURNS (
	offsetout[5..0],
	tsd_avg[7..0],
	tsd_busy,
	tsdcaldone,
	tsdcalo[7..0],
	tsdcompout
);
