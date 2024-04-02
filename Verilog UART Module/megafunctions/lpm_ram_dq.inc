FUNCTION lpm_ram_dq(data[LPM_WIDTH-1..0], address[LPM_WIDTHAD-1..0],
		we, inclock, outclock)
	WITH (LPM_WIDTH, LPM_WIDTHAD, LPM_NUMWORDS, LPM_FILE,
		LPM_INDATA, LPM_ADDRESS_CONTROL, LPM_OUTDATA)
	RETURNS (q[LPM_WIDTH-1..0]);