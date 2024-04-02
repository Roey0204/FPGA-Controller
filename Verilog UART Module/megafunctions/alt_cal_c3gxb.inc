------------------------------------------------------------------
-- alt_cal_c3gxb parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION alt_cal_c3gxb (
	clock,
	dprio_busy,
	dprio_datain[15..0],
	remap_addr[11..0],
	reset,
	start,
	testbuses[NUMBER_OF_CHANNELS*5-1..0]
)
WITH (
	channel_address_width,
	number_of_channels,
	sim_model_mode
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
