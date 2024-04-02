------------------------------------------------------------------
-- altdll parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION altdll (
	dll_aload,
	dll_clk[0..0],
	dll_offset_ctrl_a_addnsub,
	dll_offset_ctrl_a_offset[DELAYCTRLOUT_WIDTH-1..0],
	dll_offset_ctrl_b_addnsub,
	dll_offset_ctrl_b_offset[DELAYCTRLOUT_WIDTH-1..0]
)
WITH (
	DELAY_BUFFER_MODE,
	DELAY_CHAIN_LENGTH,
	DELAYCTRLOUT_WIDTH = 6,
	DLL_OFFSET_CTRL_A_STATIC_OFFSET,
	DLL_OFFSET_CTRL_A_USE_OFFSET,
	DLL_OFFSET_CTRL_B_STATIC_OFFSET,
	DLL_OFFSET_CTRL_B_USE_OFFSET,
	INPUT_FREQUENCY,
	JITTER_REDUCTION,
	USE_DLL_OFFSET_CTRL_A,
	USE_DLL_OFFSET_CTRL_B
)
RETURNS (
	dll_delayctrlout[DELAYCTRLOUT_WIDTH-1..0],
	dll_dqsupdate,
	dll_offset_ctrl_a_offsetctrlout[DELAYCTRLOUT_WIDTH-1..0],
	dll_offset_ctrl_b_offsetctrlout[DELAYCTRLOUT_WIDTH-1..0]
);
