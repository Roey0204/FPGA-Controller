------------------------------------------------------------------
-- alt_c3gxb_reconfig parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION alt_c3gxb_reconfig (
	gxb_address[3-1..0],
	logical_channel_address[CHANNEL_ADDRESS_WIDTH-1..0],
	offset_cancellation_reset,
	read,
	reconfig_address[MIF_ADDRESS_WIDTH-1..0],
	reconfig_clk,
	reconfig_data[16-1..0],
	reconfig_data_mask[16-1..0],
	reconfig_fromgxb[RECONFIG_FROMGXB_WIDTH-1..0],
	reconfig_mode_sel[RECONFIG_MODE_SEL_WIDTH-1..0],
	reconfig_reset,
	reset_reconfig_address,
	rx_eqctrl[BASE_PORT_WIDTH*4-1..0],
	rx_eqdcgain[BASE_PORT_WIDTH*RX_EQDCGAIN_PORT_WIDTH-1..0],
	rx_tx_duplex_sel[2-1..0],
	tx_preemp[BASE_PORT_WIDTH*TX_PREEMP_PORT_WIDTH-1..0],
	tx_vodctrl[BASE_PORT_WIDTH*3-1..0],
	write_all
)
WITH (
	BASE_PORT_WIDTH = 1,
	CHANNEL_ADDRESS_WIDTH = 1,
	DATA_LATENCY,
	ENABLE_BUF_CAL,
	ENABLE_BUF_CAL_FUNC_SIM,
	ENABLE_CHL_ADDR_FOR_ANALOG_CTRL,
	enable_full_write,
	ENABLE_ILLEGAL_MODE_CHECK,
	ENABLE_RX_EQUALIZATION,
	ENABLE_RX_TX_DUPLEX_SEL,
	ENABLE_SELF_RECOVERY,
	MIF_ADDRESS_WIDTH = 5,
	NUMBER_OF_CHANNELS,
	NUMBER_OF_RECONFIG_PORTS,
	READ_BASE_PORT_WIDTH = 1,
	RECONFIG_FROMGXB_WIDTH = 5,
	RECONFIG_MODE_SEL_WIDTH = 3,
	RECONFIG_TOGXB_WIDTH = 4,
	RX_EQDCGAIN_PORT_WIDTH = 2,
	TX_PREEMP_PORT_WIDTH = 4
)
RETURNS (
	busy,
	channel_reconfig_done,
	data_valid,
	error,
	reconfig_address_en,
	reconfig_address_out[MIF_ADDRESS_WIDTH-1..0],
	reconfig_data_out[16-1..0],
	reconfig_togxb[RECONFIG_TOGXB_WIDTH-1..0],
	rx_eqctrl_out[READ_BASE_PORT_WIDTH*4-1..0],
	rx_eqdcgain_out[READ_BASE_PORT_WIDTH*RX_EQDCGAIN_PORT_WIDTH-1..0],
	tx_preemp_out[READ_BASE_PORT_WIDTH*TX_PREEMP_PORT_WIDTH-1..0],
	tx_vodctrl_out[READ_BASE_PORT_WIDTH*3-1..0]
);
