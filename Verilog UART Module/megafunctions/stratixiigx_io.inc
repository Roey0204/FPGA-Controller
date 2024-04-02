------------------------------------------------------------------
-- stratixiigx_io parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION stratixiigx_io (
	areset,
	datain,
	ddiodatain,
	ddioinclk,
	delayctrlin[5..0],
	dqsupdateen,
	inclk,
	inclkena,
	linkin,
	oe,
	offsetctrlin[5..0],
	outclk,
	outclkena,
	sreset,
	terminationcontrol[13..0]
)
WITH (
	BUS_HOLD,
	DDIO_MODE,
	DDIOINCLK_INPUT,
	DQS_CTRL_LATCHES_ENABLE,
	DQS_DELAY_BUFFER_MODE,
	DQS_EDGE_DETECT_ENABLE,
	DQS_INPUT_FREQUENCY,
	DQS_OFFSETCTRL_ENABLE,
	DQS_OUT_MODE,
	DQS_PHASE_SHIFT,
	EXTEND_OE_DISABLE,
	GATED_DQS,
	INCLK_INPUT,
	INPUT_ASYNC_RESET,
	INPUT_POWER_UP,
	INPUT_REGISTER_MODE,
	INPUT_SYNC_RESET,
	OE_ASYNC_RESET,
	OE_POWER_UP,
	OE_REGISTER_MODE,
	OE_SYNC_RESET,
	OPEN_DRAIN_OUTPUT,
	OPERATION_MODE,
	OUTPUT_ASYNC_RESET,
	OUTPUT_POWER_UP,
	OUTPUT_REGISTER_MODE,
	OUTPUT_SYNC_RESET,
	SIM_DQS_DELAY_INCREMENT,
	SIM_DQS_INTRINSIC_DELAY,
	SIM_DQS_OFFSET_INCREMENT,
	TIE_OFF_OE_CLOCK_ENABLE,
	TIE_OFF_OUTPUT_CLOCK_ENABLE
)
RETURNS (
	combout,
	ddioregout,
	dqsbusout,
	linkout,
	padio,
	regout
);