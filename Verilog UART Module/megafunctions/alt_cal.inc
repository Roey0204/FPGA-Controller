------------------------------------------------------------------
-- alt_cal parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION alt_cal (
	clock,
	dprio_busy,
	dprio_datain[15..0],
	remap_addr[11..0],
	reset,
	start,
	testbuses[NUMBER_OF_CHANNELS*4-1..0],
	transceiver_init
)
WITH (
	CAL_BBPD_FIRST,
	CHANNEL_ADDRESS_WIDTH,
	ERROR_SIGNALS,
	NUMBER_OF_CHANNELS,
	SIM_MODEL_MODE,
	WATCH_LENGTH
)
RETURNS (
	busy,
	cal_error[NUMBER_OF_CHANNELS-1..0],
	dprio_addr[15..0],
	dprio_dataout[15..0],
	dprio_rden,
	dprio_wren,
	quad_addr[8..0],
	retain_addr
);
