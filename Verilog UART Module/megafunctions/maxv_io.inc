------------------------------------------------------------------
-- maxv_io parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION maxv_io (
	datain,
	oe
)
WITH (
	BUS_HOLD,
	OPEN_DRAIN_OUTPUT,
	OPERATION_MODE
)
RETURNS (
	combout,
	padio
);
