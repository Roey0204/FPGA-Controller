include "aglobal.inc";
---------- a_bin2gray.inc ----------
function a_bin2gray( bin[WIDTH-1..0] )
    with( WIDTH )
    returns( gray[WIDTH-1..0] );

---------- a_csnbuffer.inc ----------
FUNCTION a_csnbuffer (sin[((WIDTH)-1)..0], cin[((WIDTH)-1)..0], clk, clrn, ena)
    WITH (WIDTH, NEED_CARRY, USE_CS_BUFFERS)
    RETURNS (sout[((WIDTH)-1)..0], cout[((WIDTH)-1)..0]);
---------- a_dpfifo.inc ----------
FUNCTION a_dpfifo(	data[lpm_width-1..0], 
					wreq, rreq, clock, aclr, sclr
				 )
    WITH( LPM_WIDTH, LPM_NUMWORDS, LPM_SHOWAHEAD, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, ALLOW_RWCYCLE_WHEN_FULL )
    RETURNS(	q[lpm_width-1..0], 
    			empty, full,
    			usedw[ceil(log2(LPM_NUMWORDS))-1..0]
    	   );

---------- a_encoder.inc ----------
FUNCTION  a_encoder
		 ( d[WIDTH-1..0] )
WITH	 ( WIDTH )
RETURNS	 ( q[CEIL(LOG2(WIDTH))-1..0]);

---------- a_f2fifo.inc ----------
FUNCTION a_f2fifo(	data[lpm_width-1..0], 
					rreq, wreq, clock, aclr, sclr,
					threshlevel[ceil(log2(LPM_NUMWORDS))-1..0]
				 )
    WITH( LPM_WIDTH, LPM_NUMWORDS, LPM_SHOWAHEAD, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, ALLOW_RWCYCLE_WHEN_FULL, DEVICE_FAMILY, CARRY_CHAIN )
    RETURNS(	q[lpm_width-1..0], 
    			threshold, empty, full,
    			usedw[ceil(log2(LPM_NUMWORDS))-1..0], 
    			usedw_eq[lpm_numwords-1..0]
    	   );
---------- a_fefifo.inc ----------
FUNCTION a_fefifo (usedw_in[lpm_widthad-1..0], wreq, rreq, threshlevel[lpm_widthad-1..0], clock, aclr, sclr, usedw_is_1)
    WITH (LPM_WIDTHAD, LPM_NUMWORDS, ALLOW_RWCYCLE_WHEN_FULL, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, USEDW_IN_DELAY)
    RETURNS (usedw_out[lpm_widthad-1..0], empty, full, threshold);
---------- a_fffifo.inc ----------
FUNCTION a_fffifo( data[(lpm_width)-(1)..0],
				   wreq, rreq, clock, aclr, sclr,
				   threshlevel[CEIL(LOG2(LPM_NUMWORDS))-1..0]
				 )
    WITH( LPM_WIDTH, LPM_NUMWORDS, LPM_SHOWAHEAD, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, ALLOW_RWCYCLE_WHEN_FULL)
    RETURNS	(	q[(lpm_width)-(1)..0], 
				threshold, empty, full, 
				usedw[CEIL(LOG2(LPM_NUMWORDS))-1..0]
			);

---------- a_gray2bin.inc ----------
function a_gray2bin( gray[width-1..0] )
    with( WIDTH )
    returns( bin[width-1..0] );
---------- a_hdffe.inc ----------
FUNCTION a_hdffe (d, clk, clrn, ena) RETURNS (q);

---------- a_i2fifo.inc ----------
FUNCTION a_i2fifo( data[LPM_WIDTH-1..0], wreq, rreq, aclr, sclr, clock )
    WITH( LPM_WIDTH, LPM_NUMWORDS, LPM_SHOWAHEAD, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, ALLOW_RWCYCLE_WHEN_FULL )
    RETURNS( q[LPM_WIDTH-1..0], empty, full, usedw[((lpm_numwords>2) ? ceil(log2(lpm_numwords)) : 2) - 1..0] );

---------- a_imfifo.inc ----------
FUNCTION a_imfifo(	data[lpm_width-1..0], 
					wreq, rreq, clock, aclr, sclr, 
					threshlevel[ceil(log2(LPM_NUMWORDS))-1..0]
				 )
    WITH( LPM_WIDTH, LPM_NUMWORDS, LPM_SHOWAHEAD, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, ALLOW_RWCYCLE_WHEN_FULL, INPUT_PIPELINE, OUTPUT_PIPELINE )
    RETURNS	(	q[lpm_width-1..0], 
    			threshold, empty, full, 
    			usedw[ceil(log2(LPM_NUMWORDS))-1..0], 
    			q_avail, outpipe_empty
    		);

---------- a_mxfifo.inc ----------
FUNCTION a_mxfifo(	clock, sel, ena, 
					dataa[width-1..0], datab[width-1..0], 
					clrn, sclr
				 )
    WITH( WIDTH, CARRY_CHAIN_LENGTH )
    RETURNS( q[width-1..0] );
---------- a_priority_encoder.inc ----------
FUNCTION  a_priority_encoder
		 ( d[WIDTH-1..0] )
WITH	 ( WIDTH, LSB_PRIORITY)
RETURNS	 ( q[CEIL(LOG2(WIDTH))-1..0], zero );

---------- a_rdenreg.inc ----------
FUNCTION a_rdenreg
(
	clk,
	ena,
	e,
	d[WIDTH-1..0],
	aclr,
	aclre
)

WITH
(
	WIDTH,
	D_ACLR,	-- "NONE" or "ACLR"
	E_ACLR	-- "NONE" or "ACLR" or "ACLRE"
)
RETURNS (q[WIDTH-1..0]);

---------- a_regfifo.inc ----------
FUNCTION a_regfifo(	data[lpm_width-1..0], 
					wreq, rreq, clock, aclr, sclr
				 )
    WITH( LPM_WIDTH, LPM_NUMWORDS, LPM_SHOWAHEAD, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, ALLOW_RWCYCLE_WHEN_FULL )
    RETURNS(	q[lpm_width-1..0], 
    			empty, full,
    			usedw[0]
    	   );

---------- abs_divider.inc ----------
FUNCTION abs_divider (numerator[WIDTH_N - 1..0], denominator[WIDTH_D - 1..0], clock,
					  aclr, clk_en) 
					  WITH (WIDTH_N, WIDTH_D, NUM_REPRESENTATION, DEN_REPRESENTATION,
					  LPM_PIPELINE, MAXIMIZE_SPEED)
					  RETURNS(quotient[WIDTH_N - 1..0], remainder[WIDTH_D - 1..0]);
					  ---------- accumulate_no_wys.inc ----------
FUNCTION accumulate_no_wys (cin, data[WIDTH_IN-1..0], add_sub, clock, sload, clken, sign_data, aclr)
	WITH (WIDTH_IN, WIDTH_OUT, LPM_REPRESENTATION, EXTRA_LATENCY,DEVICE_FAMILY, USE_WYS, CARRY_CHAIN, CARRY_CHAIN_LENGTH)
	RETURNS (result[WIDTH_OUT-1..0], cout, overflow);
---------- addcore.inc ----------
FUNCTION addcore (dataa[(width) - (1)..0], datab[(width) - (1)..0], cin, 
					  add_sub, clock, aclr, clken)
    WITH (WIDTH, DIRECTION, REPRESENTATION, USE_CS_BUFFERS)
    RETURNS (result[(width) - (1)..0], cout, bg_out, bp_out, unreg_result[(width) - (1)..0], unreg_cout, overflow);
---------- alt3pram.inc ----------
FUNCTION alt3pram
(
	wren,
	data[WIDTH-1..0],
	wraddress[WIDTHAD-1..0],
	inclock,
	inclocken,
	outclock,
	outclocken,
	rden_a,
	rden_b,
	rdaddress_a[WIDTHAD-1..0],
	rdaddress_b[WIDTHAD-1..0],
	aclr
)

WITH
(
	WIDTH,
	WIDTHAD,
	NUMWORDS,
	LPM_FILE,
	INDATA_REG,
	INDATA_ACLR,
	WRITE_REG,
	WRITE_ACLR,
	RDADDRESS_REG_A,
	RDADDRESS_REG_B,
	RDADDRESS_ACLR_A,
	RDADDRESS_ACLR_B,
	RDCONTROL_REG_A,
	RDCONTROL_REG_B,
	RDCONTROL_ACLR_A,
	RDCONTROL_ACLR_B,
	OUTDATA_REG_A,
	OUTDATA_REG_B,
	OUTDATA_ACLR_A,
	OUTDATA_ACLR_B,
	USE_EAB,
	DEVICE_FAMILY
)
RETURNS (qa[WIDTH-1..0],qb[WIDTH-1..0]);
---------- alt_ded_mult.inc ----------
FUNCTION alt_ded_mult	(
							dataa[PIPELINE..0][WIDTH_A - 1..0],
							datab[PIPELINE..0][WIDTH_B - 1..0],
							clock,
							clken,
							aclr
						)
						WITH
						(
							WIDTH_A,
							WIDTH_B,
							TERMINATION_LEVEL,
							LEVEL,
							REPRESENTATION,
							PIPELINE,
							LATENCY_REMAINING,
							LEFTMOST,
							RIGHTMOST,
							INDEX,
							PARENT_OVERHANG,
							SIGN_EXTENSION_SUPPRESSION,
							PIPE_INDEX,
							A_REP,
							B_REP
						)
						RETURNS
						(
							result[(WIDTH_A == 1 ? WIDTH_B : WIDTH_B == 1 ? WIDTH_A : WIDTH_A + WIDTH_B) - 1..0],
							msb,
							db_a,
							db_b
						);
---------- alt_ded_mult_y.inc ----------
FUNCTION alt_ded_mult_y	(
							dataa[WIDTH_A - 1..0],
							datab[WIDTH_B - 1..0],
							clock[3..0],
							ena[3..0],
							aclr[3..0],
							signa,
							signb
						)
						WITH
						(
							WIDTH_A,
							WIDTH_B,
							PIPELINE,
							LEVEL,
							LATENCY_REMAINING,
							REPRESENTATION_A,
							REPRESENTATION_B,
							INPUT_REG_A,
							INPUT_ACLR_A,
							INPUT_REG_B,
							INPUT_ACLR_B,
							OUTPUT_REG,
							OUTPUT_ACLR,
							SIGN_REG_A,
							SIGN_ACLR_A,
							SIGN_REG_B,
							SIGN_ACLR_B,
							EXTERNAL_STAGE_COUNTER,
							DEDICATED_MULTIPLIER_CIRCUITRY,
							SUB_DEDICATED_MULTIPLIER_CIRCUITRY,
							PIPELINE_REG,
							PIPELINE_CLEAR
						)
						RETURNS
						(
							result[WIDTH_A + WIDTH_B - 1..0],
							scanouta[WIDTH_A - 1..0],
							scanoutb[WIDTH_B - 1..0],
							signa_out,
							signb_out
						);
---------- alt_le_rden_reg.inc ----------
FUNCTION alt_le_rden_reg	(
								mux_value[DATA_WIDTH - 1..0],
								rden,
								clock,
								ena,
								aclr
							) WITH
							(
								DATA_WIDTH
							)
							RETURNS
							(
								q[DATA_WIDTH - 1..0]
							);
---------- alt_mac_mult.inc ----------
FUNCTION alt_mac_mult(
							dataa[DATAA_WIDTH - 1..0],
							datab[DATAB_WIDTH - 1..0],
							scanina[DATAA_WIDTH - 1..0],
							scaninb[DATAB_WIDTH - 1..0],							
							sourcea,
							sourceb,
							signa,
							signb,
							round,
							saturate,
							clk[3..0],
							aclr[3..0],
							ena[3..0],
							mode,
							zeroacc
						)
						WITH
						(
							DATAA_WIDTH,
							DATAB_WIDTH,
							DATAA_CLOCK,
							DATAB_CLOCK,
							SIGNA_CLOCK,
							SIGNB_CLOCK,
							ROUND_CLOCK,
							SATURATE_CLOCK,
							OUTPUT_CLOCK,
							DATAA_CLEAR,
							DATAB_CLEAR,
							SIGNA_CLEAR,
							SIGNB_CLEAR,
							ROUND_CLEAR,
							SATURATE_CLEAR,
							OUTPUT_CLEAR,
							BYPASS_MULTIPLIER,
							
							MODE_CLOCK,
							ZEROACC_CLOCK,
							MODE_CLEAR,
							ZEROACC_CLEAR,
							
							EXTRA_OUTPUT_CLOCK,
							EXTRA_OUTPUT_CLEAR,
							EXTRA_SIGNA_CLOCK,
							EXTRA_SIGNA_CLEAR,
							EXTRA_SIGNB_CLOCK,
							EXTRA_SIGNB_CLEAR,
							MULT_PIPELINE,
							MULT_CLOCK,
							MULT_CLEAR,
							MULT_REPRESENTATION_A,
							MULT_REPRESENTATION_B,
							MULT_INPUT_A_IS_CONSTANT,
							MULT_INPUT_B_IS_CONSTANT,
							MULT_INPUT_A_FIXED_VALUE,
							MULT_INPUT_B_FIXED_VALUE,
							MULT_MAXIMIZE_SPEED
						)
						RETURNS
						(
							dataout[DATAA_WIDTH + DATAB_WIDTH - 1..0],
							scanouta[DATAA_WIDTH - 1..0],
							scanoutb[DATAB_WIDTH - 1..0]
						);
---------- alt_mac_out.inc ----------
PARAMETERS
(
	USING_LOADABLE_ACCUM = "NO",
	LOADABLE_ACCUM_SUPPORTED = "NO"
);
FUNCTION alt_mac_out	(
							dataa[DATAA_WIDTH - 1..0],
							datab[((!((OPERATION_MODE == "TWO_LEVEL_ADDER") # (OPERATION_MODE == "36_BIT_MULTIPLY") # (OPERATION_MODE == "ONE_LEVEL_ADDER") # (OPERATION_MODE == "ACCUMULATOR"))) ? 1 : DATAB_WIDTH == 0 ? 1 : DATAB_WIDTH) - 1..0],
							datac[((OPERATION_MODE == "TWO_LEVEL_ADDER") !# (OPERATION_MODE == "36_BIT_MULTIPLY")) ? 1 : DATAC_WIDTH - 1..0],
							datad[((OPERATION_MODE == "TWO_LEVEL_ADDER") !# (OPERATION_MODE == "36_BIT_MULTIPLY")) ? 1 : DATAD_WIDTH - 1..0],
							zeroacc,
							addnsub0,
							addnsub1,
							round,
							round0,
							round1,
							saturate,
							multabsaturate,
							multcdsaturate,
							signa,
							signb,
							clk[3..0],
							aclr[3..0],
							ena[3..0],
							mode0,
							mode1,
							zeroacc1,
							saturate1,
							chainin[((OPERATION_MODE == "TWO_LEVEL_ADDER_CHAIN_OUT")	?	((DATAA_WIDTH > DATAB_WIDTH) ? DATAA_WIDTH : DATAB_WIDTH) + 10 :
										%OTHERWISE%									DATAA_WIDTH + DATAB_WIDTH + DATAC_WIDTH + DATAD_WIDTH)
										-1..0],
							zerochainout,
							roundchainout,
							saturatechainout
						)
						WITH
						(
							OPERATION_MODE,
							DATAA_WIDTH,
							DATAB_WIDTH,
							DATAC_WIDTH,
							DATAD_WIDTH,
							ADDNSUB0_CLOCK,
							ADDNSUB1_CLOCK,
							ROUND0_CLOCK,
							ROUND1_CLOCK,
							SATURATE_CLOCK,
							MULTABSATURATE_CLOCK,
							MULTCDSATURATE_CLOCK,							
							ZEROACC_CLOCK,
							SIGNA_CLOCK,
							SIGNB_CLOCK,
							OUTPUT_CLOCK,
							ADDNSUB0_CLEAR,
							ADDNSUB1_CLEAR,
							ROUND0_CLEAR,
							ROUND1_CLEAR,
							SATURATE_CLEAR,
							MULTABSATURATE_CLEAR,
							MULTCDSATURATE_CLEAR,							
							ZEROACC_CLEAR,
							SIGNA_CLEAR,
							SIGNB_CLEAR,
							OUTPUT_CLEAR,
							ADDNSUB0_PIPELINE_CLOCK,
							ADDNSUB1_PIPELINE_CLOCK,
							
							USING_LOADABLE_ACCUM,
							LOADABLE_ACCUM_SUPPORTED,
							ROUND0_PIPELINE_CLOCK,
							ROUND1_PIPELINE_CLOCK,
							SATURATE_PIPELINE_CLOCK,
							MULTABSATURATE_PIPELINE_CLOCK,
							MULTCDSATURATE_PIPELINE_CLOCK,							
							
							ZEROACC_PIPELINE_CLOCK,
							SIGNA_PIPELINE_CLOCK,
							SIGNB_PIPELINE_CLOCK,
							ADDNSUB0_PIPELINE_CLEAR,
							ADDNSUB1_PIPELINE_CLEAR,
							
							ROUND0_PIPELINE_CLEAR,
							ROUND1_PIPELINE_CLEAR,
							SATURATE_PIPELINE_CLEAR,
							MULTABSATURATE_PIPELINE_CLEAR,
							MULTCDSATURATE_PIPELINE_CLEAR,
							
							ZEROACC_PIPELINE_CLEAR,
							SIGNA_PIPELINE_CLEAR,
							SIGNB_PIPELINE_CLEAR,
							
							MODE0_CLOCK,
							MODE1_CLOCK,
							ZEROACC1_CLOCK,
							SATURATE1_CLOCK,
							OUTPUT1_CLOCK,
							OUTPUT2_CLOCK,
							OUTPUT3_CLOCK,
							OUTPUT4_CLOCK,
							OUTPUT5_CLOCK,
							OUTPUT6_CLOCK,
							OUTPUT7_CLOCK,
							MODE0_CLEAR,
							MODE1_CLEAR,
							ZEROACC1_CLEAR,
							SATURATE1_CLEAR,
							OUTPUT1_CLEAR,
							OUTPUT2_CLEAR,
							OUTPUT3_CLEAR,
							OUTPUT4_CLEAR,
							OUTPUT5_CLEAR,
							OUTPUT6_CLEAR,
							OUTPUT7_CLEAR,
							MODE0_PIPELINE_CLOCK,
							MODE1_PIPELINE_CLOCK,
							ZEROACC1_PIPELINE_CLOCK,
							SATURATE1_PIPELINE_CLOCK,
							MODE0_PIPELINE_CLEAR,
							MODE1_PIPELINE_CLEAR,
							ZEROACC1_PIPELINE_CLEAR,
							SATURATE1_PIPELINE_CLEAR,
							FIRST_ADDER0_CLOCK,
							FIRST_ADDER1_CLOCK,
							FIRST_ADDER0_CLEAR,
							FIRST_ADDER1_CLEAR,
							
							DATAA_FORCED_TO_ZERO,
							DATAC_FORCED_TO_ZERO,

							USING_CHAINOUT,
							CHAININ_WIDTH,
							CHAINOUT_PIPELINE_CLOCK,
							CHAINOUT_PIPELINE_CLEAR
						)
						RETURNS
						(
							dataout[	((OPERATION_MODE == "OUTPUT_ONLY")		?	DATAA_WIDTH :
										(OPERATION_MODE == "ADDER_CHAIN")		?	DATAA_WIDTH :
										(OPERATION_MODE == "ACCUMULATOR")		?	((LOADABLE_ACCUM_SUPPORTED== "YES") ? DATAB_WIDTH + 16 : DATAA_WIDTH + 16) :
										(OPERATION_MODE == "ONE_LEVEL_ADDER")	?	((DATAA_WIDTH > DATAB_WIDTH) ? DATAA_WIDTH : DATAB_WIDTH) + 1 :
										(OPERATION_MODE == "TWO_LEVEL_ADDER")	?	((DATAA_WIDTH > DATAB_WIDTH) ? DATAA_WIDTH : DATAB_WIDTH) + 2 :
										(OPERATION_MODE == "TWO_LEVEL_ADDER_CHAIN_OUT")	?	((DATAA_WIDTH > DATAB_WIDTH) ? DATAA_WIDTH : DATAB_WIDTH) + 10 :
										(OPERATION_MODE == "36_BIT_MULTIPLY")	?	DATAA_WIDTH + DATAB_WIDTH:
										%OTHERWISE%									DATAA_WIDTH + DATAB_WIDTH + DATAC_WIDTH + DATAD_WIDTH)
										- 1..0],
							accoverflow
						);
										
---------- alt_stratix_add_sub.inc ----------
FUNCTION alt_stratix_add_sub (cin, dataa[LPM_WIDTH-1..0], datab[LPM_WIDTH-1..0], add_sub, clock, aclr, clken)
	WITH (LPM_WIDTH, LPM_REPRESENTATION, LPM_DIRECTION, ONE_INPUT_IS_CONSTANT, LPM_PIPELINE, REGISTERED_AT_END, MAXIMIZE_SPEED, USE_CS_BUFFERS)
	RETURNS (result[LPM_WIDTH-1..0], cout, overflow);
---------- alt_sync_fifo.inc ----------
FUNCTION alt_sync_fifo	(
					data[LPM_WIDTH - 1..0],
					rdclk,
					rdreq,
					wrclk,
					wrreq,
					aclr
				)
			WITH
				(
					LPM_WIDTH,
					LPM_NUMWORDS,
					LPM_SHOWAHEAD,
					UNDERFLOW_CHECKING,
					OVERFLOW_CHECKING,
					USE_EAB
				)
		  RETURNS
		  		(
					q[LPM_WIDTH - 1..0],
					rdempty,
					rdfull,
					wrempty,
					wrfull,
					rdusedw[CEIL(LOG2(LPM_NUMWORDS)) - 1..0],
					wrusedw[CEIL(LOG2(LPM_NUMWORDS)) - 1..0],
db_port[CEIL(LOG2(LPM_NUMWORDS)) - 1..0]
				);
---------- alt_u_div.inc ----------
FUNCTION alt_u_div
		( numerator[WIDTH_N-1..0], denominator[WIDTH_D-1..0],
		  clock, aclr, clk_en
		)
WITH	(
		  WIDTH_N, WIDTH_D, WIDTH_Q, WIDTH_R,
		  WIDTH_D_MIN, LPM_PIPELINE, PIPELINE_DELAY,
		  MAXIMIZE_SPEED
		)
RETURNS ( quotient[WIDTH_Q-1..0], remainder[WIDTH_R-1..0], den_out[WIDTH_D - 1..0] );

---------- altaccumulate.inc ----------
FUNCTION altaccumulate (cin, data[WIDTH_IN-1..0], add_sub, clock, sload, clken, sign_data, aclr)
	WITH (WIDTH_IN, WIDTH_OUT, LPM_REPRESENTATION, EXTRA_LATENCY,DEVICE_FAMILY, USE_WYS, CARRY_CHAIN, CARRY_CHAIN_LENGTH)
	RETURNS (result[WIDTH_OUT-1..0], cout, overflow);
---------- altaccumulate_stratix.inc ----------
FUNCTION altaccumulate_stratix (cin, data[WIDTH_IN-1..0], add_sub, clock, sload, clken, sign_data, aclr)
	WITH (WIDTH_IN, WIDTH_OUT, LPM_REPRESENTATION,EXTRA_LATENCY,USE_WYS, CARRY_CHAIN, CARRY_CHAIN_LENGTH)
	RETURNS (result[WIDTH_OUT-1..0], cout, overflow);
---------- altclklock.inc ----------
FUNCTION altclklock(inclock, inclocken, fbin)
	WITH (INCLOCK_PERIOD, INCLOCK_SETTINGS,
		VALID_LOCK_CYCLES, INVALID_LOCK_CYCLES,
		VALID_LOCK_MULTIPLIER, INVALID_LOCK_MULTIPLIER,
		OPERATION_MODE,
		CLOCK0_BOOST, CLOCK0_DIVIDE, CLOCK0_SETTINGS,
		CLOCK1_BOOST, CLOCK1_DIVIDE, CLOCK1_SETTINGS,
		OUTCLOCK_PHASE_SHIFT, CLOCK0_TIME_DELAY,
		CLOCK1_TIME_DELAY, CLOCK2_BOOST, CLOCK2_DIVIDE,
		CLOCK2_SETTINGS, CLOCK2_TIME_DELAY, CLOCK_EXT_BOOST,
		CLOCK_EXT_DIVIDE, CLOCK_EXT_SETTINGS, CLOCK_EXT_TIME_DELAY,
		INTENDED_DEVICE_FAMILY)
	RETURNS (clock0, clock1, locked, clock2, clock_ext);

---------- altddio_bidir.inc ----------
FUNCTION altddio_bidir (datain_h[(WIDTH) - (1)..0], datain_l[(WIDTH) - (1)..0], inclock, inclocken, outclock, outclocken, oe, aclr, aset, sset, sclr)
	WITH (WIDTH, POWER_UP_HIGH, OE_REG, EXTEND_OE_DISABLE, IMPLEMENT_INPUT_IN_LCELL, INTENDED_DEVICE_FAMILY)
	RETURNS (dataout_h[(WIDTH) - (1)..0], dataout_l[(WIDTH) - (1)..0], oe_out[(WIDTH) - (1)..0], combout[(WIDTH) - (1)..0], padio[(WIDTH) - (1)..0], dqsundelayedout[WIDTH-1..0]);
---------- altddio_in.inc ----------
FUNCTION altddio_in (datain[(WIDTH) - (1)..0], inclock, inclocken, aclr, aset, sclr, sset)
	WITH (WIDTH, POWER_UP_HIGH, INTENDED_DEVICE_FAMILY)
	RETURNS (dataout_h[(WIDTH) - (1)..0], dataout_l[(WIDTH) - (1)..0]);
---------- altddio_out.inc ----------
FUNCTION altddio_out (datain_h[(WIDTH) - (1)..0], datain_l[(WIDTH) - (1)..0], outclock, outclocken, aclr, aset, sclr, sset, oe)
	WITH (WIDTH, POWER_UP_HIGH, OE_REG, EXTEND_OE_DISABLE, INTENDED_DEVICE_FAMILY)
	RETURNS (dataout[(WIDTH) - (1)..0], oe_out[(WIDTH) - (1)..0]);
---------- altdpram.inc ----------
PARAMETERS
(
	WIDTH_BYTEENA = 1
);
FUNCTION altdpram
(
	wren,
	data[WIDTH-1..0],
	wraddress[WIDTHAD-1..0],
	inclock,
	inclocken,
	rden,
	rdaddress[WIDTHAD-1..0],
	outclock,
	outclocken,
	aclr,
	byteena[WIDTH_BYTEENA-1..0],
	wraddressstall,
	rdaddressstall
)

WITH
(
	WIDTH,
	WIDTHAD,
	NUMWORDS,
	FILE,
	INDATA_REG,
	INDATA_ACLR,
	WRADDRESS_REG,
	WRADDRESS_ACLR,
	WRCONTROL_REG,
	WRCONTROL_ACLR,
	RDADDRESS_REG,
	RDADDRESS_ACLR,
	RDCONTROL_REG,
	RDCONTROL_ACLR,
	OUTDATA_REG,
	OUTDATA_ACLR,
	USE_EAB,
	MAXIMUM_DEPTH,
	RAM_BLOCK_TYPE,
	READ_DURING_WRITE_MODE_MIXED_PORTS,
	WIDTH_BYTEENA,
	BYTE_SIZE
)
RETURNS (q[WIDTH-1..0]);

---------- altfp_mult.inc ----------
-------------------------------------------------------------
--
-- ALTFP_MULT.INC
--
-- Include file for ALTFP_MULT megafunction
--
-- (c) Altera Corporation, 2002
-------------------------------------------------------------

FUNCTION altfp_mult(
    clock,
    clk_en,
    aclr,
    dataa[WIDTH_EXP+WIDTH_MAN..0],
    datab[WIDTH_EXP+WIDTH_MAN..0]
)
WITH
(
    WIDTH_EXP,
    WIDTH_MAN,
    DEDICATED_MULTIPLIER_CIRCUITRY,
    REDUCED_FUNCTIONALITY,
    PIPELINE
)
RETURNS
(
    result[WIDTH_EXP+WIDTH_MAN..0],
    overflow,
    underflow,
    zero,
    denormal,
    indefinite,
    nan
);
---------- altgxb.inc ----------
FUNCTION altgxb     (
                      inclk[CEIL((NUMBER_OF_CHANNELS) DIV (4)) - (1)..0],
                      pll_areset[CEIL((NUMBER_OF_CHANNELS) DIV (4)) - (1)..0],
                      rx_in[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_coreclk[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_cruclk[CEIL((NUMBER_OF_CHANNELS) DIV (4)) - (1)..0],
                      rx_aclr[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_bitslip[(NUMBER_OF_CHANNELS) - (1)..0], 
                      rx_enacdet[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_we[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_re[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_slpbk[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_a1a2size[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_equalizerctrl[(NUMBER_OF_CHANNELS) * (3) - (1)..0],
                      rx_locktorefclk[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_locktodata[(NUMBER_OF_CHANNELS) - (1)..0],
                      tx_in[(CHANNEL_WIDTH) * (NUMBER_OF_CHANNELS) - (1)..0],
                      tx_coreclk[(NUMBER_OF_CHANNELS) - (1)..0],
                      tx_aclr[(NUMBER_OF_CHANNELS) - (1)..0],
                      tx_ctrlenable[(NUMBER_OF_CHANNELS) * (DWIDTH_FACTOR) - (1)..0],
                      tx_forcedisparity[(NUMBER_OF_CHANNELS) * (DWIDTH_FACTOR) - (1)..0],
                      tx_srlpbk[(NUMBER_OF_CHANNELS) - (1)..0],
                      tx_vodctrl[(NUMBER_OF_CHANNELS) * (3) - (1)..0],
                      tx_preemphasisctrl[(NUMBER_OF_CHANNELS) * (3) - (1)..0],
                      txdigitalreset[(NUMBER_OF_CHANNELS) - (1)..0],
                      rxdigitalreset[(NUMBER_OF_CHANNELS) - (1)..0],
                      rxanalogreset[(NUMBER_OF_CHANNELS) - (1)..0],
                      pllenable[CEIL((NUMBER_OF_CHANNELS) DIV (4)) - (1)..0]
                    )
	       WITH (
                      OPERATION_MODE,
                      LOOPBACK_MODE,
                      REVERSE_LOOPBACK_MODE,
                      PROTOCOL,
                      NUMBER_OF_CHANNELS,
                      NUMBER_OF_QUADS,
                      CHANNEL_WIDTH,
                      PLL_INCLOCK_PERIOD,
                      DATA_RATE,
                      DATA_RATE_REMAINDER,
                      RX_DATA_RATE,
                      RX_DATA_RATE_REMAINDER,
                      USE_8B_10B_MODE,
                      USE_DOUBLE_DATA_MODE,
                      DWIDTH_FACTOR,
                      DISPARITY_MODE,
                      CRU_INCLOCK_PERIOD,
                      RUN_LENGTH,
                      RUN_LENGTH_ENABLE,
                      USE_CHANNEL_ALIGN,
                      USE_AUTO_BIT_SLIP,
                      USE_RATE_MATCH_FIFO,
                      USE_SYMBOL_ALIGN,
                      ALIGN_PATTERN,
                      ALIGN_PATTERN_LENGTH,
                      INFINIBAND_INVALID_CODE,
                      CLK_OUT_MODE_REFERENCE,
                      FORCE_DISPARITY_MODE,
                      USE_SELF_TEST_MODE,
                      SELF_TEST_MODE,
                      USE_EQUALIZER_CTRL_SIGNAL,
                      EQUALIZER_CTRL_SETTING,
                      SIGNAL_THRESHOLD_SELECT,
                      RX_BANDWIDTH_TYPE,
                      RX_ENABLE_DC_COUPLING,
                      USE_VOD_CTRL_SIGNAL,
                      VOD_CTRL_SETTING,
                      USE_PREEMPHASIS_CTRL_SIGNAL,
                      PREEMPHASIS_CTRL_SETTING,
                      TX_TERMINATION,
                      PLL_BANDWIDTH_TYPE,
                      PLL_USE_DC_COUPLING,
                      RX_PPM_SETTING,
                      USE_PHASE_SHIFT,
                      USE_RX_CLKOUT,
                      USE_RX_CRUCLK,
                      USE_GENERIC_FIFO,
                      USE_RX_CORECLK,
                      USE_TX_CORECLK,
                      INSTANTIATE_TRANSMITTER_PLL,
                      CONSIDER_INSTANTIATE_TRANSMITTER_PLL_PARAM,
                      RX_FORCE_SIGNAL_DETECT,
                      FLIP_RX_OUT,
                      FLIP_TX_IN,
                      ADD_GENERIC_FIFO_WE_SYNCH_REGISTER,
                      ENABLE_TX_8B_10B_I1I2_GENERATION,
                      CONSIDER_ENABLE_TX_8B_10B_I1I2_GENERATION,
                      FOR_ENGINEERING_SAMPLE_DEVICE,
                      INTENDED_DEVICE_FAMILY
                    )
	    RETURNS (
                      pll_locked[CEIL((NUMBER_OF_CHANNELS) DIV (4)) - (1)..0],
                      coreclk_out[CEIL((NUMBER_OF_CHANNELS) DIV (4)) - (1)..0],
                      rx_out[((CLK_OUT_MODE_REFERENCE == "OFF") ? ((CHANNEL_WIDTH > 10) ? (CHANNEL_WIDTH / 2) : (CHANNEL_WIDTH)) : (CHANNEL_WIDTH)) * (NUMBER_OF_CHANNELS) - (1)..0],
                      rx_clkout[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_locked[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_freqlocked[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_rlv[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_syncstatus[(NUMBER_OF_CHANNELS) * ((CLK_OUT_MODE_REFERENCE == "OFF") ? ((DWIDTH_FACTOR == 2) ? (DWIDTH_FACTOR / 2) : (DWIDTH_FACTOR)) : (DWIDTH_FACTOR)) - (1)..0], 
                      rx_patterndetect[(NUMBER_OF_CHANNELS) * ((CLK_OUT_MODE_REFERENCE == "OFF") ? ((DWIDTH_FACTOR == 2) ? (DWIDTH_FACTOR / 2) : (DWIDTH_FACTOR)) : (DWIDTH_FACTOR)) - (1)..0], 
                      rx_ctrldetect[(NUMBER_OF_CHANNELS) * ((CLK_OUT_MODE_REFERENCE == "OFF") ? ((DWIDTH_FACTOR == 2) ? (DWIDTH_FACTOR / 2) : (DWIDTH_FACTOR)) : (DWIDTH_FACTOR)) - (1)..0], 
                      rx_errdetect[(NUMBER_OF_CHANNELS) * ((CLK_OUT_MODE_REFERENCE == "OFF") ? ((DWIDTH_FACTOR == 2) ? (DWIDTH_FACTOR / 2) : (DWIDTH_FACTOR)) : (DWIDTH_FACTOR)) - (1)..0], 
                      rx_disperr[(NUMBER_OF_CHANNELS) * ((CLK_OUT_MODE_REFERENCE == "OFF") ? ((DWIDTH_FACTOR == 2) ? (DWIDTH_FACTOR / 2) : (DWIDTH_FACTOR)) : (DWIDTH_FACTOR)) - (1)..0], 
                      rx_signaldetect[(NUMBER_OF_CHANNELS) - (1)..0],
                      -- rx_fifoempty[(NUMBER_OF_CHANNELS) - (1)..0],
                      -- rx_fifofull[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_fifoalmostempty[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_fifoalmostfull[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_channelaligned[CEIL((NUMBER_OF_CHANNELS) DIV (4)) - (1)..0],
                      rx_bisterr[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_bistdone[(NUMBER_OF_CHANNELS) - (1)..0],
                      rx_a1a2sizeout[(NUMBER_OF_CHANNELS) * ((CLK_OUT_MODE_REFERENCE == "OFF") ? ((DWIDTH_FACTOR == 2) ? (DWIDTH_FACTOR / 2) : (DWIDTH_FACTOR)) : (DWIDTH_FACTOR)) - (1)..0], 
                      tx_out[(NUMBER_OF_CHANNELS) - (1)..0]
                     );
---------- altram.inc ----------
FUNCTION altram(we, data[WIDTH-1..0], address[AD_WIDTH-1..0], clocki, clocko, be)
	WITH (WIDTH, AD_WIDTH, NUMWORDS, FILE, REGISTERINPUTMODE, MAXIMUM_DEPTH)
	RETURNS (q[WIDTH-1..0]);
---------- altrom.inc ----------
FUNCTION altrom(address[AD_WIDTH-1..0], clocki, clocko)
	WITH (WIDTH, AD_WIDTH, NUMWORDS, FILE, REGISTERINPUTMODE, MAXIMUM_DEPTH)
	RETURNS (q[WIDTH-1..0]);
---------- altshift.inc ----------
FUNCTION altshift(data[(WIDTH - 1)..0], clock, aclr, clken)
	WITH (WIDTH, DEPTH)
	RETURNS (result[(WIDTH - 1) ..0]);

---------- altshift_taps.inc ----------
FUNCTION altshift_taps (shiftin[WIDTH-1..0], clock, clken, aclr)
	WITH (NUMBER_OF_TAPS, TAP_DISTANCE, WIDTH, POWER_UP_STATE)
	RETURNS (shiftout[WIDTH-1..0], taps[(WIDTH * NUMBER_OF_TAPS)-1..0]);
---------- altsqrt.inc ----------
FUNCTION altsqrt	(
						radical[WIDTH - 1..0],
						clk,
						ena,
						aclr
					)
					WITH
					(
						WIDTH,
						PIPELINE
					)
					RETURNS
					(
						q[CEIL(WIDTH DIV 2) - 1..0],
						remainder[CEIL(WIDTH DIV 2)..0]
					);
---------- altsyncram.inc ----------
---------------------------------------------------------------------------------
-- altsyncram.inc
--
-- Altsyncram functions header
--
-- (c) Altera Corporation, 2000
--
-- Version 1.0
---------------------------------------------------------------------------------

PARAMETERS
(
	WIDTH_BYTEENA_A = 1,
	WIDTH_BYTEENA_B = 1,
	WIDTH_ECCSTATUS = 3
);

FUNCTION altsyncram	(
						wren_a,
						rden_a,
						wren_b,
						data_a[OPERATION_MODE != "ROM" ? WIDTH_A - 1 : 0..0],
						data_b[(OPERATION_MODE == "BIDIR_DUAL_PORT") ? WIDTH_B - 1 : 0..0],
						address_a[WIDTHAD_A - 1..0],
						address_b[(OPERATION_MODE == "BIDIR_DUAL_PORT" # OPERATION_MODE == "DUAL_PORT") ? WIDTHAD_B - 1 : 0..0],
						clock0,
						clock1,
						clocken0,
						clocken1,
						clocken2,
						clocken3,
						rden_b,
						aclr0,
						aclr1,
						addressstall_a,
						addressstall_b,
						byteena_a[OPERATION_MODE != "ROM" ? (WIDTH_BYTEENA_A > 1 ? WIDTH_BYTEENA_A-1 : 0) : 0..0],
						byteena_b[OPERATION_MODE == "BIDIR_DUAL_PORT" ? (WIDTH_BYTEENA_B > 1 ? WIDTH_BYTEENA_B-1 : 0) : 0..0]
					)
					WITH
					(
						OPERATION_MODE,
						WIDTH_A,
						WIDTHAD_A,
						NUMWORDS_A,
						INDATA_ACLR_A,
						WRCONTROL_ACLR_A,
						ADDRESS_ACLR_A,
						WIDTH_B,
						WIDTHAD_B,
						NUMWORDS_B,
						INDATA_REG_B,
						INDATA_ACLR_B,
						WRCONTROL_WRADDRESS_REG_B,
						WRCONTROL_ACLR_B,
						ADDRESS_ACLR_B,
						OUTDATA_REG_A,
						OUTDATA_ACLR_A,
						BYTEENA_ACLR_A,
						RDCONTROL_REG_B,
						RDCONTROL_ACLR_B,
						ADDRESS_REG_B,
						OUTDATA_REG_B,
						OUTDATA_ACLR_B,
						BYTEENA_REG_B,
						BYTEENA_ACLR_B,
						INIT_FILE,
						INIT_FILE_LAYOUT,
						MAXIMUM_DEPTH,
						WIDTH_BYTEENA_A,
						WIDTH_BYTEENA_B,
						BYTE_SIZE,
						READ_DURING_WRITE_MODE_MIXED_PORTS,
						READ_DURING_WRITE_MODE_PORT_A,
						READ_DURING_WRITE_MODE_PORT_B,
						RAM_BLOCK_TYPE,
						CLOCK_ENABLE_INPUT_A,
						CLOCK_ENABLE_INPUT_B,
						CLOCK_ENABLE_OUTPUT_A,
						CLOCK_ENABLE_OUTPUT_B,
						CLOCK_ENABLE_CORE_A,
						CLOCK_ENABLE_CORE_B,
						ENABLE_ECC,
						ECC_PIPELINE_STAGE_ENABLED,
						WIDTH_ECCSTATUS,
						DEVICE_FAMILY
					)
					RETURNS
					(
						q_a[WIDTH_A - 1..0],
						q_b[(OPERATION_MODE == "DUAL_PORT" # OPERATION_MODE == "BIDIR_DUAL_PORT") ? WIDTH_B - 1 : 0..0],
						eccstatus[WIDTH_ECCSTATUS-1..0]
					);

					---------- altsyncram_fifo.inc ----------
FUNCTION altsyncram_fifo	(
								data[LPM_WIDTH - 1..0],
								wrclk,
								rdclk,
								aclr,
								wrreq,
								rdreq
							)
							WITH
							(
								LPM_WIDTH,
								LPM_NUMWORDS,
								LPM_SHOWAHEAD,
								UNDERFLOW_CHECKING,
								OVERFLOW_CHECKING,
								USE_EAB,
								DELAY_RDUSEDW,
								DELAY_WRUSEDW,
								RDSYNC_DELAYPIPE,
								WRSYNC_DELAYPIPE
							)
							RETURNS
							(
								wrempty,
								wrfull,
								wrusedw[CEIL(LOG2(LPM_NUMWORDS)) - 1..0],
								rdempty,
								rdfull,
								rdusedw[CEIL(LOG2(LPM_NUMWORDS)) - 1..0],
								q[LPM_WIDTH - 1..0],
x_fifo_wreq_out,
x_stall_fifo,
x_valid_rreq,
x_ram_output_bus[LPM_WIDTH - 1..0],
x_ramread_address[CEIL(LOG2(LPM_NUMWORDS)) - 1..0],
x_control_pipe[2..0],
x_ram_address[CEIL(LOG2(LPM_NUMWORDS)) - 1..0],
x_ram_output_address[CEIL(LOG2(LPM_NUMWORDS)) - 1..0]
							);
---------- busmux.inc ----------
FUNCTION busmux (dataa[(width) - (1)..0], datab[(width) - (1)..0], sel)
    WITH (WIDTH)
    RETURNS (result[(width) - (1)..0]);
---------- bypassff.inc ----------
FUNCTION bypassff(d[(WIDTH - 1)..0], clk, clrn, ena)
	WITH (WIDTH)
	RETURNS (q[(WIDTH - 1)..0]);

---------- clklock.inc ----------
FUNCTION clklock (inclk)
    WITH (INPUT_FREQUENCY, CLOCKBOOST)
    RETURNS (outclk);
---------- cmpchain.inc ----------
FUNCTION cmpchain (dataa[(lpm_width) - (1)..0], datab[(lpm_width) - (1)..0], clk, aset, clken)
    WITH (lpm_width, ONE_INPUT_CONSTANT, MODE)
    RETURNS (aeb, agb);
---------- cmpconst.inc ----------
FUNCTION cmpconst (data[WIDTH-1..0]) WITH (WIDTH, CVALUE)
	RETURNS (result);
---------- comptree.inc ----------
FUNCTION comptree (dataa[(lpm_width) - (1)..0], datab[(lpm_width) - (1)..0], clk, aset, clken)
    WITH (lpm_width, CHAIN_LENGTH, ONE_INPUT_CONSTANT, OUTPUTS_CLOCKED, BURRIED_CLOCKED, MODE)
    RETURNS (aeb, agb);
---------- csa_add.inc ----------
DEFINE  L_EVEL(n)   = ((n < 4) ? 0 : 1 + L_EVEL(2*FLOOR(n DIV 3) + (n MOD 3)));

FUNCTION csa_add (data[(width) - (1)..0][(size) - (1)..0])
    WITH (size, width, END_ADDER)
    RETURNS (result[((width == 1) ? (size) : (((size) + (l_evel(width))) + (end_adder))) - (1)..0], carry_out[((width == 1) ? (size) : (((size) + (l_evel(width))) + (end_adder))) - (1)..0]);
---------- csa_cell.inc ----------
FUNCTION csa_cell (data[2..0][(size) - (1)..0])
    WITH (SIZE)
    RETURNS (sum_out[(size) - (1)..0], carry_out[(size) - (1)..0]);
---------- cyclone_ddio.inc ----------
FUNCTION cyclone_ddio_bidir(oe, datain)
WITH(extend_oe_disable)
RETURNS(padio, dataout);

FUNCTION cyclone_ddio_out(oe, datain)
WITH(extend_oe_disable)
RETURNS(padio);

FUNCTION cyclone_ddio_in(padio)
RETURNS(dataout);
---------- cycloneii_pll.inc ----------
----------------------------------------------------------------------------------------------------------
--
-- CYCLONEII_PLL.INC
--
-- Wysiwyg include file for Stratix II family PLL
--
-- (c) Altera Corporation, 2003
--
----------------------------------------------------------------------------------------------------------
FUNCTION cycloneii_pll(
						inclk[1..0],
						clkswitch,
						ena,
						areset,
						pfdena,
						sbdin,
						testclearlock,
						testupout,
						testdownout
						)
						WITH
						(
							OPERATION_MODE,
							COMPENSATE_CLOCK,
							TEST_INPUT_COMP_DELAY_CHAIN_BITS,
							TEST_FEEDBACK_COMP_DELAY_CHAIN_BITS,
							INCLK0_INPUT_FREQUENCY,
							INCLK1_INPUT_FREQUENCY,
							GATE_LOCK_SIGNAL,
							GATE_LOCK_COUNTER,
							CLK2_OUTPUT_FREQUENCY,
							CLK1_OUTPUT_FREQUENCY,
							CLK0_OUTPUT_FREQUENCY,
							CLK2_MULTIPLY_BY,
							CLK1_MULTIPLY_BY,
							CLK0_MULTIPLY_BY,
							CLK2_DIVIDE_BY,
							CLK1_DIVIDE_BY,
							CLK0_DIVIDE_BY,
							CLK2_PHASE_SHIFT,
							CLK1_PHASE_SHIFT,
							CLK0_PHASE_SHIFT,
							CLK2_DUTY_CYCLE,
							CLK1_DUTY_CYCLE,
							CLK0_DUTY_CYCLE,
							BANDWIDTH,
							BANDWIDTH_TYPE,
							M_INITIAL,
							M,
							N,
							C0_HIGH,
							C1_HIGH,
							C2_HIGH,
							C0_LOW,
							C1_LOW,
							C2_LOW,
							C0_INITIAL,
							C1_INITIAL,
							C2_INITIAL,
							C0_MODE,
							C1_MODE,
							C2_MODE,
							C0_PH,
							C1_PH,
							C2_PH,
							M_PH,
							CLK2_COUNTER,
							CLK1_COUNTER,
							CLK0_COUNTER,
							CHARGE_PUMP_CURRENT,
							LOOP_FILTER_R,
							LOOP_FILTER_C,
							VCO_POST_SCALE,
							VCO_MULTIPLY_BY,
							VCO_DIVIDE_BY,
							VCO_MIN,
							VCO_MAX,
							VCO_CENTER,
							PFD_MIN,
							PFD_MAX,
							LOCK_HIGH,
							LOCK_LOW,
							M_TEST_SOURCE,
							C0_TEST_SOURCE,
							C1_TEST_SOURCE,
							C2_TEST_SOURCE
						)
						RETURNS
						(
							clk[2..0],
							sbdout,
							locked
						);
---------- declut.inc ----------
FUNCTION declut (data[(width) - (1)..0], enable, clock, aclr, clken)
    WITH (WIDTH, STAGE, TOT_LEVELS, LATENCY)
    RETURNS (eq[((2) ^ (width)) - (1)..0], clock_out, aclr_out, clken_out);
---------- dffe_high.inc ----------
FUNCTION dffe_high
(
	d, clk, clrn, prn, ena
)
WITH
(
	power_up_high
)
RETURNS
(
	q
)
;

---------- dffeea.inc ----------
FUNCTION dffeea (d, clk, clrn, prn, ena)
    RETURNS (q);
---------- dffpipe.inc ----------
FUNCTION dffpipe( clock, d[width-1..0], ena, clrn, prn, sclr )
    WITH( WIDTH, DELAY )
    RETURNS( q[width-1..0], pq[delay..0][width-1..0] );
---------- digit_tracker.inc ----------
FUNCTION digit_tracker (denominator[WIDTH - 1..0]) WITH (WIDTH) RETURNS (out[WIDTH - 1..0]);---------- divide.inc ----------
FUNCTION DIVIDE
		( numerator[WIDTH_N-1..0], denominator[WIDTH_D-1..0],
		  clock, aclr, clk_en
		)
WITH	(
		  WIDTH_N, WIDTH_D, WIDTH_Q, WIDTH_R,
		  WIDTH_D_MIN, LPM_PIPELINE, PIPELINE_DELAY, MAXIMIZE_SPEED
		)
RETURNS ( quotient[WIDTH_Q-1..0], remainder[WIDTH_R-1..0] );

---------- look_add.inc ----------
FUNCTION look_add (bg_in[(width) - (1)..0], bp_in[(width) - (1)..0], cin)
    WITH (WIDTH)
    RETURNS (cout[(width) - (1)..0], bg_out, bp_out);
---------- lpm_abs.inc ----------
FUNCTION lpm_abs(data[LPM_WIDTH-1..0])
	WITH (LPM_WIDTH, ADDERTYPE)
	RETURNS (result[LPM_WIDTH-1..0], overflow);
---------- lpm_add_sub.inc ----------
FUNCTION lpm_add_sub (cin, dataa[LPM_WIDTH-1..0], datab[LPM_WIDTH-1..0], add_sub, clock, aclr, clken)
	WITH (LPM_WIDTH, LPM_REPRESENTATION, LPM_DIRECTION, ONE_INPUT_IS_CONSTANT, LPM_PIPELINE, REGISTERED_AT_END, MAXIMIZE_SPEED, USE_CS_BUFFERS, USE_WYS)
	RETURNS (result[LPM_WIDTH-1..0], cout, overflow);
---------- lpm_and.inc ----------
FUNCTION lpm_and(data[LPM_SIZE-1..0][LPM_WIDTH-1..0])
	WITH (LPM_WIDTH, LPM_SIZE)
	RETURNS (result[LPM_WIDTH-1..0]);
---------- lpm_bustri.inc ----------
FUNCTION lpm_bustri(data[LPM_WIDTH-1..0],
		enabletr, enabledt)
	WITH (LPM_WIDTH)
	RETURNS (tridata[LPM_WIDTH-1..0], result[LPM_WIDTH-1..0]);
---------- lpm_clshift.inc ----------
FUNCTION lpm_clshift(data[LPM_WIDTH-1..0],
		distance[LPM_WIDTHDIST-1..0], direction)
	WITH (LPM_WIDTH, LPM_WIDTHDIST, LPM_SHIFTTYPE)
	RETURNS (result[LPM_WIDTH-1..0], underflow, overflow);
---------- lpm_compare.inc ----------
FUNCTION lpm_compare (dataa[LPM_WIDTH-1..0], datab[LPM_WIDTH-1..0],
						clock, aclr, clken)
    WITH (LPM_WIDTH, LPM_REPRESENTATION, LPM_PIPELINE,
			CHAIN_SIZE, ONE_INPUT_IS_CONSTANT)
    RETURNS (alb, aeb, agb, ageb, aneb, aleb);
---------- lpm_constant.inc ----------
FUNCTION lpm_constant () WITH (LPM_WIDTH, LPM_CVALUE)
	RETURNS (result[LPM_WIDTH-1..0]);
---------- lpm_counter.inc ----------
--	(c) Altera Corporation, 1995

FUNCTION lpm_counter
					(
					-- INPUTS
					data[LPM_WIDTH-1..0],
					clock,
					clk_en,
					cnt_en,
					updown,
					cin,
					aclr,
					aset,
					aconst,
					aload,
					sclr,
					sset,
					sconst,
					sload
					)
					WITH
					(
					-- PARAMETERS
					LPM_WIDTH,
					LPM_DIRECTION,
					LPM_MODULUS,
					LPM_AVALUE,
					LPM_SVALUE,
					LPM_PORT_UPDOWN,
					CARRY_CNT_EN,
					LABWIDE_SCLR,
					USE_NEW_VERSION
					)
					RETURNS
					(
					-- OUPUTS
					q[LPM_WIDTH-1..0],
					cout,
					eq[15..0]%,
					debug_out[6..0]%
					);
---------- lpm_decode.inc ----------
FUNCTION lpm_decode(data[LPM_WIDTH-1..0], enable, clock, aclr, clken)
	WITH (LPM_WIDTH, LPM_DECODES, LPM_PIPELINE)
	RETURNS (eq[LPM_DECODES-1..0]);

---------- lpm_dff.inc ----------
FUNCTION lpm_dff (data[LPM_WIDTH-1..0], clock, enable,
		shiftin, shiften,
		sclr, sset, sconst,
		aclr, aset, aconst)
	WITH (LPM_WIDTH, LPM_AVALUE, LPM_SVALUE)
	RETURNS(q[LPM_WIDTH-1..0], shiftout);

---------- lpm_divide.inc ----------
FUNCTION lpm_divide (numer[LPM_WIDTHN-1..0], denom[LPM_WIDTHD-1..0], clock, aclr, clken)
    WITH (LPM_WIDTHN, LPM_WIDTHD, LPM_PIPELINE, LPM_NREPRESENTATION, LPM_DREPRESENTATION,
		  MAXIMIZE_SPEED, LPM_REMAINDERPOSITIVE)
    RETURNS (quotient[LPM_WIDTHN-1..0], remain[LPM_WIDTHD-1..0]);

---------- lpm_ff.inc ----------
FUNCTION lpm_ff (data[LPM_WIDTH-1..0], clock, enable,
		sclr, sset, sload,
		aclr, aset, aload)
	WITH (LPM_WIDTH, LPM_AVALUE, LPM_SVALUE, LPM_FFTYPE)
	RETURNS(q[LPM_WIDTH-1..0]);
---------- lpm_fifo.inc ----------
FUNCTION lpm_fifo( data[lpm_width-1..0], wrreq, rdreq, clock, aclr, sclr )
    WITH(	LPM_WIDTH, LPM_NUMWORDS, LPM_WIDTHU, LPM_SHOWAHEAD, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, 
    		ALLOW_RWCYCLE_WHEN_FULL, USE_EAB
    	)
    RETURNS(	q[lpm_width-1..0], 
				empty, full, 
				usedw[LPM_WIDTHU-1..0]
		   );

---------- lpm_fifo_dc.inc ----------
FUNCTION lpm_fifo_dc (data[LPM_WIDTH-1..0], rdreq, wrreq, rdclock, wrclock, aclr)
	WITH (LPM_WIDTH, LPM_NUMWORDS, LPM_WIDTHU, LPM_SHOWAHEAD,
		UNDERFLOW_CHECKING, OVERFLOW_CHECKING, ALLOW_RWCYCLE_WHEN_FULL, USE_EAB,
		DELAY_RDUSEDW, DELAY_WRUSEDW, RDSYNC_DELAYPIPE, WRSYNC_DELAYPIPE)
	RETURNS (q[LPM_WIDTH-1..0], rdempty, rdfull, wrempty, wrfull,
		rdusedw[LPM_WIDTHU-1..0], wrusedw[LPM_WIDTHU-1..0]);

---------- lpm_inv.inc ----------
FUNCTION lpm_inv(data[LPM_WIDTH-1..0])
	WITH (LPM_WIDTH)
	RETURNS (result[LPM_WIDTH-1..0]);
---------- lpm_latch.inc ----------
FUNCTION lpm_latch (
	data[LPM_WIDTH-1..0], 
	gate, 
	aclr, 
	aset, 
	aconst -- mf_only_port
	)
	WITH 
	(
	LPM_WIDTH, 
	LPM_AVALUE
	)
	RETURNS
	(
	q[LPM_WIDTH-1..0]
	);

---------- lpm_mult.inc ----------
PARAMETERS
(
	LPM_WIDTHS = 1
);

FUNCTION lpm_mult
(
	dataa[(LPM_WIDTHA - 1)..0],
	datab[(LPM_WIDTHB - 1)..0],
	sum[(LPM_WIDTHS - 1)..0],
	aclr,
	clock,
	clken
)
WITH
(
	LPM_WIDTHA,
	LPM_WIDTHB,
	LPM_WIDTHP,
	LPM_WIDTHS,
	LPM_REPRESENTATION,
	LATENCY,
	LPM_PIPELINE,
 	INPUT_A_IS_CONSTANT,
 	INPUT_B_IS_CONSTANT,
	USE_EAB,
	MAXIMIZE_SPEED,
	DEDICATED_MULTIPLIER_CIRCUITRY,
	DEDICATED_MULTIPLIER_MIN_INPUT_WIDTH_FOR_AUTO,
	DEDICATED_MULTIPLIER_MIN_OUTPUT_WIDTH_FOR_AUTO,
	INPUT_A_FIXED_VALUE,
	INPUT_B_FIXED_VALUE,
	USE_AHDL_IMPLEMENTATION
)
RETURNS
(
	result[(LPM_WIDTHP - 1)..0]
);

---------- lpm_mux.inc ----------
FUNCTION lpm_mux(data[LPM_SIZE-1..0][LPM_WIDTH-1..0], sel[LPM_WIDTHS-1..0], clock, aclr, clken)
	WITH (LPM_WIDTH, LPM_SIZE, LPM_WIDTHS, LPM_PIPELINE)
	RETURNS (result[LPM_WIDTH-1..0]);
---------- lpm_or.inc ----------
FUNCTION lpm_or(data[LPM_SIZE-1..0][LPM_WIDTH-1..0])
	WITH (LPM_WIDTH, LPM_SIZE)
	RETURNS (result[LPM_WIDTH-1..0]);
---------- lpm_ram_dp.inc ----------
FUNCTION lpm_ram_dp
(
	wren,
	data[LPM_WIDTH-1..0],
	wraddress[LPM_WIDTHAD-1..0],
	wrclock,
	wrclken,
	rden,
	rdaddress[LPM_WIDTHAD-1..0],
	rdclock,
	rdclken
)

WITH
(
	LPM_WIDTH,
	LPM_WIDTHAD,
	LPM_NUMWORDS,
	LPM_FILE,
	LPM_INDATA,
	LPM_WRADDRESS_CONTROL,
	LPM_RDADDRESS_CONTROL,
	LPM_OUTDATA
)
RETURNS (q[LPM_WIDTH-1..0]);

---------- lpm_ram_dq.inc ----------
FUNCTION lpm_ram_dq(data[LPM_WIDTH-1..0], address[LPM_WIDTHAD-1..0],
		we, inclock, outclock)
	WITH (LPM_WIDTH, LPM_WIDTHAD, LPM_NUMWORDS, LPM_FILE,
		LPM_INDATA, LPM_ADDRESS_CONTROL, LPM_OUTDATA)
	RETURNS (q[LPM_WIDTH-1..0]);
---------- lpm_ram_io.inc ----------
FUNCTION lpm_ram_io(address[LPM_WIDTHAD-1..0],
		we, inclock, outclock, outenab, memenab)
	WITH (LPM_WIDTH, LPM_WIDTHAD, LPM_NUMWORDS, LPM_FILE,
		LPM_INDATA, LPM_ADDRESS_CONTROL, LPM_OUTDATA)
	RETURNS (dio[LPM_WIDTH-1..0]);
---------- lpm_rom.inc ----------
FUNCTION lpm_rom(address[LPM_WIDTHAD-1..0],
		inclock, outclock, memenab)
	WITH (LPM_WIDTH, LPM_WIDTHAD, LPM_NUMWORDS, LPM_FILE,
		LPM_ADDRESS_CONTROL, LPM_OUTDATA)
	RETURNS (q[LPM_WIDTH-1..0]);
---------- lpm_shiftreg.inc ----------
FUNCTION lpm_shiftreg (data[LPM_WIDTH-1..0], clock, enable,
		shiftin, load,
		sclr, sset,
		aclr, aset)
	WITH (LPM_WIDTH, LPM_DIRECTION, LPM_AVALUE, LPM_SVALUE)
	RETURNS(q[LPM_WIDTH-1..0], shiftout);

---------- lpm_tff.inc ----------
FUNCTION lpm_tff (data[LPM_WIDTH-1..0], clock, enable,
		sclr, sset, sconst, sload,
		aclr, aset, aconst, aload)
	WITH (LPM_WIDTH, LPM_AVALUE, LPM_SVALUE)
	RETURNS(q[LPM_WIDTH-1..0]);
---------- lpm_xor.inc ----------
FUNCTION lpm_xor(data[LPM_SIZE-1..0][LPM_WIDTH-1..0])
	WITH (LPM_WIDTH, LPM_SIZE)
	RETURNS (result[LPM_WIDTH-1..0]);
---------- max_mcell.inc ----------
FUNCTION max_mcell (
			-- INPUTS
			clk,
			aclr,
			pexpin,
			fpin,
			pterm0[pterm0_width-1..0],
			pterm1[pterm1_width-1..0],
			pterm2[pterm2_width-1..0],
			pterm3[pterm3_width-1..0],
			pterm4[pterm4_width-1..0],
			pterm5[pterm5_width-1..0],
			pxor[pxor_width-1..0],
			pclk[pclk_width-1..0],
			pena[pena_width-1..0],
			paclr[paclr_width-1..0],
			papre[papre_width-1..0]
			)
			WITH
			(
			-- PARAMETERS
			OPERATION_MODE,
			OUTPUT_MODE,
			REGISTER_MODE,
			PEXP_MODE,
			POWER_UP,
			pterm0_width,
			pterm1_width,
			pterm2_width,
			pterm3_width,
			pterm4_width,
			pterm5_width,
			pxor_width,
			pclk_width,
			pena_width,
			paclr_width,
			papre_width
			)
			RETURNS
			(
			-- OUTPUTS
			dataout,
			pexpout
			);
---------- max_sexp.inc ----------
FUNCTION max_sexp (
		-- INPUTS
		datain[pterm_width-1..0]
		)
		WITH
		(
		--parameters
		pterm_width
		)
		RETURNS
		(
		-- OUTPUTS
		dataout
		);
---------- mpar_add.inc ----------
FUNCTION mpar_add (data[(width) - (1)..0][(size) - (1)..0], cin, clk, aclr, clken)
    WITH (size, width, REPRESENTATION, LEVEL, TOT_LEVELS, INT_LATENCY, PREV_SING_SIZE, STAGE, TOT_STAGES, BOOTH_ADDER, CREATE_MS_BOOTH_ADDER, MPARADD_OP_MODE)
    RETURNS (result[((size) + (((2) ^ ((tot_levels) - (1))) - ((2) ^ ((level) - (1))))) - (1)..0], clk_out, aclr_out, clken_out);
---------- mul_boothc.inc ----------
FUNCTION mul_boothc (b[(WIDTH-1)..0][2..0], cin[(WIDTH-1)..0], clock, aclr, clken)
    WITH (WIDTH, MS_BIT, OP_MODE)
    RETURNS (sel[(WIDTH-1)..0][2..0], cout[(WIDTH-1)..0], booth_cout[(WIDTH-1)..0]);
---------- mul_lfrg.inc ----------
FUNCTION mul_lfrg (data[(WIDTH-1)..0][1..0], select[(WIDTH-1)..0][2..0])
    WITH (WIDTH, BIT0_OF_SELECT_IS_GND, BIT2_OF_SELECT_IS_SIGN_EXT, BIT0_OF_DATA_IS_GND, INPUTS_ARE_IDENTICAL)
    RETURNS (out_bit[((WIDTH)-1)..0]);
---------- muleabz.inc ----------
FUNCTION muleabz (dataa[(widtha) - (1)..0], datab[(widthb) - (1)..0], clock, aclr, clken)
    WITH (WIDTHA, WIDTHB, A_REPRESENTATION, B_REPRESENTATION, PIPELINE, INPUT_B_IS_CONSTANT, EXT_EAB_OUT_REG, USE_EAB, MAXIMIZE_SPEED)
    RETURNS (result[((widtha) + (widthb)) - (1)..0]);
---------- multcore.inc ----------
FUNCTION multcore (dataa[(widtha) - (1)..0], datab[(widthb) - (1)..0], clock, aclr, clken)
    WITH (WIDTHA, WIDTHB, LPM_REPRESENTATION, LATENCY, ONE_INPUT_IS_CONSTANT, USE_EAB, MAXIMIZE_SPEED, OP_MODE, DEDICATED_MULTIPLIER_CIRCUITRY, SUB_DEDICATED_MULTIPLIER_CIRCUITRY)
    RETURNS (result[((widtha) + (widthb)) - (1)..0]);
---------- mux.inc ----------
FUNCTION mux (data[(width) - (1)..0], sel[(widths) - (1)..0])
    WITH (WIDTH, WIDTHS)
    RETURNS (result);
---------- muxlut.inc ----------
FUNCTION muxlut (data[(SIZE - 1)..0], select[((SIZE == 1) ? (1) : (CEIL(LOG2(SIZE)))) - (1)..0], clock, aclr, clken)
WITH (SIZE, LEVEL, TOT_LEVELS, LATENCY, REM_LATENCY, LOCAL)
RETURNS (result, clock_out, aclr_out, clken_out);
---------- parallel_add.inc ----------
DEFINE CALC_PADD_WIDTHR(w, z, s) = (s == 0) ? CEIL(LOG2(z*((2^w)-1))) : 
											  CEIL(LOG2(((2^w)-1) * (2^(z*s)-1) / ((2^s)-1)));

FUNCTION parallel_add (data[size - 1..0][width - 1..0], clock, aclr, clken)
    WITH (width, size, WIDTHR, SHIFT, REPRESENTATION, PIPELINE, MSW_SUBTRACT, DEVICE_FAMILY, CARRY_CHAIN)
    RETURNS (result[(widthr) - (1)..0]);
---------- pcpa_add.inc ----------
FUNCTION pcpa_add (data[(size) - (1)..0][(width) - (1)..0], clock, aclr)
    WITH (WIDTH, SIZE, SHIFT, REPRESENTATION, TOT_LEVELS, STAGE, LATENCY, PREV_SING_WIDTH, MSW_SUBTRACT)
    RETURNS (result[((size == 1) ? (width) : ((width) + (((((2) ^ (tot_levels)) - ((2) ^ (stage))) * (shift)) + ((tot_levels) - (stage))))) - (1)..0], clock_out, aclr_out);
---------- sfifo.inc ----------
FUNCTION sfifo(  data[lpm_width-1..0],
				 wreq, rreq, clock, clockx2, aclr, sclr,
				 threshlevel[ceil(log2(LPM_NUMWORDS))-1..0]
			  )
    WITH(	LPM_WIDTH, LPM_NUMWORDS, LPM_SHOWAHEAD, UNDERFLOW_CHECKING, OVERFLOW_CHECKING, 
    		ALLOW_RWCYCLE_WHEN_FULL, USE_EAB, OPTIMIZE_FOR_SPEED, DEVICE_FAMILY
    	)
    RETURNS(	q[lpm_width-1..0], 
				threshold, empty, full, 
				usedw[ceil(log2(LPM_NUMWORDS))-1..0]
		   );
---------- sign_div_unsign.inc ----------
FUNCTION sign_div_unsign (numerator[NUM_WIDTH - 1..0], denominator[DEN_WIDTH - 1..0],
						  clock, aclr, clk_en)
						  WITH (NUM_WIDTH, DEN_WIDTH, LPM_PIPELINE, NUM_REPRESENTATION,
							    DEN_REPRESENTATION, MAXIMIZE_SPEED)
						  RETURNS (quotient[NUM_WIDTH - 1..0], remainder[DEN_WIDTH - 1..0]);---------- stratix_ddio.inc ----------
FUNCTION stratix_ddio_in(padio, clk, clkena, areset)
with(areset_mode, power_up_mode)
	RETURNS(dataout_h, dataout_l);

FUNCTION stratix_ddio_in_no_areset(padio, clk, clkena)
with(areset_mode, power_up_mode)
	RETURNS(dataout_h, dataout_l);

FUNCTION stratix_ddio_out(clk, clkena, areset, oe, datain_h, datain_l)
with(areset_mode, power_up_mode, oe_register_mode, extend_oe_disable)
	RETURNS(padio);

FUNCTION stratix_ddio_out_no_areset(clk, clkena, oe, datain_h, datain_l)
with(areset_mode, power_up_mode, oe_register_mode, extend_oe_disable)
	RETURNS(padio);

FUNCTION stratix_ddio_bidir_out(clk, clkena, areset, oe, datain_h, datain_l, delayctrlin)
with(areset_mode, power_up_mode, oe_register_mode, extend_oe_disable, sim_dqs_input_frequency, sim_dll_phase_shift)
	RETURNS(combout, dqsundelayedout, padio);

FUNCTION stratix_ddio_bidir_out_no_areset(clk, clkena, oe, datain_h, datain_l, delayctrlin)
with(areset_mode, power_up_mode, oe_register_mode, extend_oe_disable, sim_dqs_input_frequency, sim_dll_phase_shift)
	RETURNS(combout, dqsundelayedout, padio);

FUNCTION stratix_ddio_bidir(inclk, inclkena, outclk, outclkena, areset, oe, datain_h, datain_l)
with(areset_mode, power_up_mode, oe_register_mode, extend_oe_disable)
	RETURNS(padio, dataout_h, dataout_l, combout, dqsundelayedout);

FUNCTION stratix_ddio_bidir_no_areset(inclk, inclkena, outclk, outclkena, oe, datain_h, datain_l)
with(areset_mode, power_up_mode, oe_register_mode, extend_oe_disable)
	RETURNS(padio, dataout_h, dataout_l, combout, dqsundelayedout);
---------- stratix_dll.inc ----------
------------------------------------------------------------------------------
--
-- STRATIX_DLL.INC
--
-- Wysiwyg include file for Stratix family DLL
--
-- (c) Altera Corporation, 2002
--
------------------------------------------------------------------------------
FUNCTION stratix_dll
						(
						-- INPUTS
						clk
						)
						WITH
						(
						-- PARAMETERS
						PHASE_SHIFT,
						INPUT_FREQUENCY,
						SIM_VALID_LOCK,
						SIM_INVALID_LOCK
						)
						RETURNS
						(
						-- OUTPUTS
						delayctrlout
						);


---------- stratix_io.inc ----------
FUNCTION stratix_io
						(
							datain,
							ddiodatain,
							oe,
							outclk,
							outclkena,
							inclk,
							inclkena,
							areset,
							sreset,
							delayctrlin
						)
						WITH
						(
						-- PARAMETERS
						OPERATION_MODE,
						DDIO_MODE,
						OPEN_DRAIN_OUTPUT,
						BUS_HOLD,
						OUTPUT_REGISTER_MODE,
						OUTPUT_ASYNC_RESET,
						OUTPUT_POWER_UP,
						OUTPUT_SYNC_RESET,
						TIE_OFF_OUTPUT_CLOCK_ENBLE,
						OE_REGISTER_MODE,
						OE_ASYNC_RESET,
						OE_POWER_UP,
						OE_SYNC_RESET,
						TIE_OFF_OE_CLOCK_ENBLE,
						INPUT_ASYNC_RESET,
						INPUT_POWER_UP,
						INPUT_SYNC_RESET,
						EXTEND_OE_DISABLE,
						SIM_DQS_INPUT_FREQUENCY,
						SIM_DLL_PHASE_SHIFT
						)
						RETURNS
						(
						-- OUTPUTS
						combout,
						regout,
						ddioregout,
						padio,
						dqsundelayedout

						);
---------- stratix_lcell.inc ----------
FUNCTION stratix_lcell
						(
						-- INPUTS
						clk,					-- clock input
						dataa,					-- LUT input #1
						datab,					-- LUT input #2
						datac,					-- LUT input #3
						datad,					-- LUT input #4
						aclr,					-- asynchronous clear
						aload,					-- asynchronous load					
						sclr,					-- synchronous clear
						sload,					-- synchronous load
						ena,					-- clock enable
						cin,					-- carry in
						cin0,
						cin1,
						inverta,
						regcascin

						)
						WITH
						(
						-- PARAMETERS
						OPERATION_MODE,			-- use which LCELL mode???
						LUT_MASK,				-- LUT function
						SYNCH_MODE,				-- Use synch mode
						REGISTER_CASCADE_MODE,	-- reg cascademode
						SUM_LUTC_INPUT   		--choice of LUTC input
						)
						RETURNS
						(
						-- OUTPUTS
						combout,				-- combinational output
						regout,					-- registered output
						cout,					-- carry out
						cout0,
						cout1
						);
---------- stratix_mac_mult.inc ----------
FUNCTION stratix_mac_mult(
							dataa[DATAA_WIDTH - 1..0],
							datab[DATAB_WIDTH - 1..0],
							signa,
							signb,
							clk[3..0],
							aclr[3..0],
							ena[3..0]
						)
						WITH
						(
							DATAA_WIDTH,
							DATAB_WIDTH,
							DATAA_CLOCK,
							DATAB_CLOCK,
							SIGNA_CLOCK,
							SIGNB_CLOCK,
							OUTPUT_CLOCK,
							DATAA_CLEAR,
							DATAB_CLEAR,
							SIGNA_CLEAR,
							SIGNB_CLEAR,
							OUTPUT_CLEAR
						)
						RETURNS
						(
							dataout[DATAA_WIDTH + DATAB_WIDTH - 1..0],
							scanouta[DATAA_WIDTH - 1..0],
							scanoutb[DATAB_WIDTH - 1..0]
						);
---------- stratix_mac_out.inc ----------
FUNCTION stratix_mac_out	(
							dataa[DATAA_WIDTH - 1..0],
							datab[((!((OPERATION_MODE == "TWO_LEVEL_ADDER") # (OPERATION_MODE == "36_BIT_MULTIPLY") # (OPERATION_MODE == "ONE_LEVEL_ADDER"))) ? 1 : DATAB_WIDTH) - 1..0],
							datac[((OPERATION_MODE == "TWO_LEVEL_ADDER") !# (OPERATION_MODE == "36_BIT_MULTIPLY")) ? 1 : DATAC_WIDTH - 1..0],
							datad[((OPERATION_MODE == "TWO_LEVEL_ADDER") !# (OPERATION_MODE == "36_BIT_MULTIPLY")) ? 1 : DATAD_WIDTH - 1..0],
							zeroacc,
							addnsub0,
							addnsub1,
							signa,
							signb,
							clk[3..0],
							aclr[3..0],
							ena[3..0]
						)
						WITH
						(
							OPERATION_MODE,
							DATAA_WIDTH,
							DATAB_WIDTH,
							DATAC_WIDTH,
							DATAD_WIDTH,
							ADDNSUB0_CLOCK,
							ADDNSUB1_CLOCK,
							ZEROACC_CLOCK,
							SIGNA_CLOCK,
							SIGNB_CLOCK,
							OUTPUT_CLOCK,
							ADDNSUB0_CLEAR,
							ADDNSUB1_CLEAR,
							ZEROACC_CLEAR,
							SIGNA_CLEAR,
							SIGNB_CLEAR,
							OUTPUT_CLEAR,
							ADDNSUB0_PIPELINE_CLOCK,
							ADDNSUB1_PIPELINE_CLOCK,
							ZEROACC_PIPELINE_CLOCK,
							SIGNA_PIPELINE_CLOCK,
							SIGNB_PIPELINE_CLOCK,
							ADDNSUB0_PIPELINE_CLEAR,
							ADDNSUB1_PIPELINE_CLEAR,
							ZEROACC_PIPELINE_CLEAR,
							SIGNA_PIPELINE_CLEAR,
							SIGNB_PIPELINE_CLEAR
						)
						RETURNS
						(
							dataout[	((OPERATION_MODE == "OUTPUT_ONLY")		?	DATAA_WIDTH :
										(OPERATION_MODE == "ACCUMULATOR")		?	DATAA_WIDTH + 16 :
										(OPERATION_MODE == "ONE_LEVEL_ADDER")	?	DATAA_WIDTH + 1 :
										(OPERATION_MODE == "TWO_LEVEL_ADDER")	?	DATAA_WIDTH + 2	:
										%OTHERWISE%									DATAA_WIDTH + DATAB_WIDTH)
										- 1..0],
							accoverflow
						);
										
---------- stratix_pll.inc ----------
----------------------------------------------------------------------------------------------------------
--
-- STRATIX_PLL.INC
--
-- Wysiwyg include file for Stratix family PLL
--
-- (c) Altera Corporation, 2001
--
----------------------------------------------------------------------------------------------------------
FUNCTION stratix_pll(
						inclk[1..0],
						fbin,
						ena,
						clkswitch,
						areset,
						pfdena,
						clkena[5..0],
						extclkena[3..0],
						scanclk,
						scanaclr,
						scandata,
						comparator
					)
					WITH
					(
						OPERATION_MODE,
						QUALIFY_CONF_DONE,
						COMPENSATE_CLOCK,
						PLL_TYPE,
						SCAN_CHAIN,
						-- Internal clock specifications
						CLK5_MULTIPLY_BY,
						CLK4_MULTIPLY_BY,
						CLK3_MULTIPLY_BY,
						CLK2_MULTIPLY_BY,
						CLK1_MULTIPLY_BY,
						CLK0_MULTIPLY_BY,
						CLK5_DIVIDE_BY,
						CLK4_DIVIDE_BY,
						CLK3_DIVIDE_BY,
						CLK2_DIVIDE_BY,
						CLK1_DIVIDE_BY,
						CLK0_DIVIDE_BY,
						CLK5_PHASE_SHIFT,
						CLK4_PHASE_SHIFT,
						CLK3_PHASE_SHIFT,
						CLK2_PHASE_SHIFT,
						CLK1_PHASE_SHIFT,
						CLK0_PHASE_SHIFT,
						CLK5_TIME_DELAY,
						CLK4_TIME_DELAY,
						CLK3_TIME_DELAY,
						CLK2_TIME_DELAY,
						CLK1_TIME_DELAY,
						CLK0_TIME_DELAY,
						CLK5_DUTY_CYCLE,
						CLK4_DUTY_CYCLE,
						CLK3_DUTY_CYCLE,
						CLK2_DUTY_CYCLE,
						CLK1_DUTY_CYCLE,
						CLK0_DUTY_CYCLE,
						-- External clock specifications
						EXTCLK3_MULTIPLY_BY,
						EXTCLK2_MULTIPLY_BY,
						EXTCLK1_MULTIPLY_BY,
						EXTCLK0_MULTIPLY_BY,
						EXTCLK3_DIVIDE_BY,
						EXTCLK2_DIVIDE_BY,
						EXTCLK1_DIVIDE_BY,
						EXTCLK0_DIVIDE_BY,
						EXTCLK3_PHASE_SHIFT,
						EXTCLK2_PHASE_SHIFT,
						EXTCLK1_PHASE_SHIFT,
						EXTCLK0_PHASE_SHIFT,
						EXTCLK3_TIME_DELAY,
						EXTCLK2_TIME_DELAY,
						EXTCLK1_TIME_DELAY,
						EXTCLK0_TIME_DELAY,
						EXTCLK3_DUTY_CYCLE,
						EXTCLK2_DUTY_CYCLE,
						EXTCLK1_DUTY_CYCLE,
						EXTCLK0_DUTY_CYCLE,
						PRIMARY_CLOCK,
						INCLK0_INPUT_FREQUENCY,
						INCLK1_INPUT_FREQUENCY,
						GATE_LOCK_SIGNAL,
						GATE_LOCK_COUNTER,
						LOCK_HIGH,
						LOCK_LOW,
						VALID_LOCK_MULTIPLIER,
						INVALID_LOCK_MULTIPLIER,
						SWITCH_OVER_ON_LOSSCLK,
						SWITCH_OVER_ON_GATED_LOCK,
						ENABLE_SWITCH_OVER_COUNTER,
						SWITCH_OVER_COUNTER,
						FEEDBACK_SOURCE,
						BANDWIDTH,
						BANDWIDTH_TYPE,
						SPREAD_FREQUENCY,
						DOWN_SPREAD,
						-- Advanced use parameters
						VCO_MIN,
						VCO_MAX,
						VCO_CENTER,
						PFD_MIN,
						PFD_MAX,
						M_INITIAL,
						M,
						N,
						M2,
						N2,
						SS,
						L0_HIGH,
						L1_HIGH,
						G0_HIGH,
						G1_HIGH,
						G2_HIGH,
						G3_HIGH,
						E0_HIGH,
						E1_HIGH,
						E2_HIGH,
						E3_HIGH,
						L0_LOW,
						L1_LOW,
						G0_LOW,
						G1_LOW,
						G2_LOW,
						G3_LOW,
						E0_LOW,
						E1_LOW,
						E2_LOW,
						E3_LOW,
						L0_INITIAL,
						L1_INITIAL,
						G0_INITIAL,
						G1_INITIAL,
						G2_INITIAL,
						G3_INITIAL,
						E0_INITIAL,
						E1_INITIAL,
						E2_INITIAL,
						E3_INITIAL,
						L0_MODE,
						L1_MODE,
						G0_MODE,
						G1_MODE,
						G2_MODE,
						G3_MODE,
						E0_MODE,
						E1_MODE,
						E2_MODE,
						E3_MODE,
						L0_PH,
						L1_PH,
						G0_PH,
						G1_PH,
						G2_PH,
						G3_PH,
						E0_PH,
						E1_PH,
						E2_PH,
						E3_PH,
						M_PH,
						L0_TIME_DELAY,
						L1_TIME_DELAY,
						G0_TIME_DELAY,
						G1_TIME_DELAY,
						G2_TIME_DELAY,
						G3_TIME_DELAY,
						E0_TIME_DELAY,
						E1_TIME_DELAY,
						E2_TIME_DELAY,
						E3_TIME_DELAY,
						M_TIME_DELAY,
						N_TIME_DELAY,
						EXTCLK3_COUNTER,
						EXTCLK2_COUNTER,
						EXTCLK1_COUNTER,
						EXTCLK0_COUNTER,
						CLK5_COUNTER,
						CLK4_COUNTER,
						CLK3_COUNTER,
						CLK2_COUNTER,
						CLK1_COUNTER,
						CLK0_COUNTER,
						ENABLE0_COUNTER,
						ENABLE1_COUNTER,
						CHARGE_PUMP_CURRENT,
						LOOP_FILTER_R,
						LOOP_FILTER_C,
						RX_OUTCLOCK_RESOURCE,
						SKIP_VCO
					)
					RETURNS
					(
						clk[5..0],
						extclk[3..0],
						clkbad[1..0],
						activeclock,
						locked,
						clkloss,
						enable1,
						enable0,
						scandataout
					);
---------- stratix_ram_block.inc ----------
PARAMETERS
(
	BYTE_SIZE_BLOCK = 8
);

FUNCTION stratix_ram_block (
							portadatain[PORT_A_DATA_WIDTH-1..0], 	--	DATA A
							portaaddr[(PORT_A_LAST_ADDRESS - PORT_A_FIRST_ADDRESS == 0) ?  0 : CEIL(LOG2(PORT_A_LAST_ADDRESS - PORT_A_FIRST_ADDRESS+1))-1..0],		--	ADDR A
							portawe,		--	WRITE ENABLE A		
							portbdatain[(OPERATION_MODE == "ROM" # OPERATION_MODE == "SINGLE_PORT") ? 0 : PORT_B_DATA_WIDTH-1..0],	--	DATA B
							portbaddr[(OPERATION_MODE == "ROM" # OPERATION_MODE == "SINGLE_PORT") ? 0 : (PORT_B_LAST_ADDRESS - PORT_B_FIRST_ADDRESS == 0) ? 0 :CEIL(LOG2(PORT_B_LAST_ADDRESS-PORT_B_FIRST_ADDRESS+1))-1..0],		--	ADDR B
							portbrewe,		--	READ ENABLE / WRITE ENABLE B
							clk0, 			--	CLK 0
							clk1,			--	CLK 1
							ena0,			--	ENABLE FOR CLK 0							
							ena1,			--	ENABLE FOR CLK 1
							clr0,			--	CLEAR 
							clr1,			--	CLEAR 1
							portabyteenamasks[OPERATION_MODE != "ROM" ? (PORT_A_DATA_WIDTH >= BYTE_SIZE_BLOCK ? (PORT_A_DATA_WIDTH / BYTE_SIZE_BLOCK)-1 : 0) : 0..0],	--	A BYTE ENABLE MASKS
							portbbyteenamasks[OPERATION_MODE == "BIDIR_DUAL_PORT" ? (PORT_B_DATA_WIDTH >= BYTE_SIZE_BLOCK ? (PORT_B_DATA_WIDTH / BYTE_SIZE_BLOCK)-1 : 0)  : 0..0]	--	B BYTE ENABLE MASKS
							
						)
						WITH
						(
							OPERATION_MODE,
							MIXED_PORT_FEED_THROUGH_MODE,
							RAM_BLOCK_TYPE,
							PHYSICAL_PORT,
							LOGICAL_RAM_NAME,
							INIT_FILE,
							INIT_FILE_LAYOUT,
							DATA_INTERLEAVE_WIDTH_IN_BITS,
							DATA_INTERLEAVE_OFFSET_IN_BITS,
							PORT_A_LOGICAL_RAM_DEPTH,
							PORT_A_LOGICAL_RAM_WIDTH,
							PORT_A_DATA_IN_CLEAR,
							PORT_A_ADDRESS_CLEAR,
							PORT_A_WRITE_ENABLE_CLEAR,
							PORT_A_DATA_OUT_CLOCK,
							PORT_A_DATA_OUT_CLEAR,
							PORT_A_BYTE_ENABLE_CLEAR,
							PORT_A_FIRST_ADDRESS,
							PORT_A_LAST_ADDRESS,
							PORT_A_FIRST_BIT_NUMBER,
							PORT_A_DATA_WIDTH,
							PORT_B_LOGICAL_RAM_DEPTH,
							PORT_B_LOGICAL_RAM_WIDTH,
							PORT_B_DATA_IN_CLOCK,
							PORT_B_DATA_IN_CLEAR,
							PORT_B_ADDRESS_CLOCK,
							PORT_B_ADDRESS_CLEAR,
							PORT_B_READ_ENABLE_WRITE_ENABLE_CLOCK,
							PORT_B_READ_ENABLE_WRITE_ENABLE_CLEAR,
							PORT_B_DATA_OUT_CLOCK,
							PORT_B_DATA_OUT_CLEAR,
							PORT_B_BYTE_ENABLE_CLOCK,
							PORT_B_BYTE_ENABLE_CLEAR,
							PORT_B_FIRST_ADDRESS,
							PORT_B_LAST_ADDRESS,
							PORT_B_FIRST_BIT_NUMBER,
							PORT_B_DATA_WIDTH,
							BYTE_SIZE_BLOCK
						)
						RETURNS
						(
							portadataout[PORT_A_DATA_WIDTH-1..0],	--	DATA OUT A
							portbdataout[(OPERATION_MODE == "ROM" # OPERATION_MODE == "SINGLE_PORT") ? 0 : PORT_B_DATA_WIDTH-1..0]	--	DATA OUT B
						);
						
						---------- stratix_rublock.inc ----------
FUNCTION stratix_rublock(
							clk,
							shiftnld,
							captnupdt,
							regin,
							rsttimer,
							rconfig
						)
						WITH
						(
							SIM_INIT_CONFIG,
							SIM_INIT_WATCHDOG_VALUE,
							SIM_INIT_PAGE_SELECT,
							SIM_INIT_STATUS
						)
						RETURNS
						(
							regout,
							pgmout[2..0]
						);
---------- stratixgx_hssi_receiver.inc ----------
--------------------------------------------------------------------------------
--------------------------
--
-- STRATIXGX_HSSI_RECEIVER.INC
--
-- Wysiwyg include file for Aurora HSSI receiver
--
-- (c) Altera Corporation, 2002
--
--------------------------------------------------------------------------------

FUNCTION stratixgx_hssi_receiver(
                               datain, 
                               cruclk,
                               pllclk,
                               masterclk,
                               coreclk,
                               softreset,
                               analogreset,
                               serialfdbk,
                               parallelfdbk[(USE_8B_10B_MODE == "TRUE") ? 9 : (USE_DOUBLE_DATA_MODE == "TRUE") ? ((CHANNEL_WIDTH / 2) - 1) : (CHANNEL_WIDTH - 1)..0],
                               post8b10b[(USE_8B_10B_MODE == "TRUE") ? 7 : (USE_DOUBLE_DATA_MODE == "TRUE") ? ((CHANNEL_WIDTH / 2) - 1) : (CHANNEL_WIDTH - 1)..0],
                               slpbk,
                               bitslip,
                               enacdet,
                               we,
                               re,
                               alignstatus,
                               disablefifordin,
                               disablefifowrin,
                               fifordin,
                               enabledeskew,
                               fiforesetrd,
                               xgmdatain[7..0],
                               xgmctrlin,
                               a1a2size,
                               equalizerctrl[2..0],
                               locktorefclk,
                               locktodata
                             )
	                WITH (
                               CHANNEL_NUM,
                               CHANNEL_WIDTH,
                               RUN_LENGTH,
                               RUN_LENGTH_ENABLE,
                               USE_8B_10B_MODE,
                               USE_DOUBLE_DATA_MODE,
                               USE_RATE_MATCH_FIFO,
                               RATE_MATCHING_FIFO_MODE,
                               USE_CHANNEL_ALIGN,
                               USE_SYMBOL_ALIGN,
                               USE_AUTO_BIT_SLIP,
                               SYNCHRONIZATION_MODE, 
                               ALIGN_PATTERN, 
                               ALIGN_PATTERN_LENGTH, 
                               INFINIBAND_INVALID_CODE, 
                               DISPARITY_MODE,
                               CLK_OUT_MODE_REFERENCE,
                               CRUCLK_PERIOD,
	                       CRUCLK_MULTIPLIER,
                               USE_CRUCLK_DIVIDER,
                               USE_SELF_TEST_MODE,
                               SELF_TEST_MODE,
                               USE_PARALLEL_FEEDBACK,
                               USE_POST8B10B_FEEDBACK,
                               USE_EQUALIZER_CTRL_SIGNAL,
                               EQUALIZER_CTRL_SETTING,
			       SIGNAL_THRESHOLD_SELECT,
                               BANDWIDTH_TYPE,
                               ENABLE_DC_COUPLING,
                               VCO_BYPASS,
                               FORCE_SIGNAL_DETECT,
                               FOR_ENGINEERING_SAMPLE_DEVICE
                             )
	             RETURNS (
                               dataout[CHANNEL_WIDTH-1..0],
                               syncstatus[(USE_DOUBLE_DATA_MODE=="TRUE") ? 1 : 0..0], 
                               patterndetect[(USE_DOUBLE_DATA_MODE=="TRUE") ? 1 : 0..0], 
                               ctrldetect[(USE_DOUBLE_DATA_MODE=="TRUE") ? 1 : 0..0], 
                               errdetect[(USE_DOUBLE_DATA_MODE=="TRUE") ? 1 : 0..0], 
                               disperr[(USE_DOUBLE_DATA_MODE=="TRUE") ? 1 : 0..0], 
                               syncstatusdeskew,
                               adetectdeskew,
                               rdalign,
                               xgmdataout[7..0],
                               xgmctrldet,
                               xgmrunningdisp,
                               xgmdatavalid,
                               fifofull, 
                               fifoalmostfull, 
                               fifoempty, 
                               fifoalmostempty, 
                               disablefifordout,
                               disablefifowrout,
                               fifordout,
                               signaldetect, 
                               lock, 
                               freqlock, 
                               rlv, 
                               clkout, 
                               recovclkout,
                               bisterr,
                               bistdone,
                               a1a2sizeout[(USE_DOUBLE_DATA_MODE=="TRUE") ? 1 : 0..0]
                             );
---------- stratixgx_hssi_transmitter.inc ----------
--------------------------------------------------------------------------------
--------------------------
--
-- STRATIXGX_HSSI_TRANSMITTER
--
-- Wysiwyg include file for Aurora HSSI Transmitter
--
-- (c) Altera Corporation, 2002
--
--------------------------------------------------------------------------------

FUNCTION stratixgx_hssi_transmitter(
                                  datain[CHANNEL_WIDTH-1..0],
                                  pllclk,
                                  fastpllclk,
                                  coreclk,
                                  softreset,
                                  analogreset,
                                  ctrlenable[(USE_DOUBLE_DATA_MODE=="TRUE") ? 1 : 0..0],
                                  forcedisparity[(USE_DOUBLE_DATA_MODE=="TRUE") ? 1 : 0..0],
                                  serialdatain,
                                  xgmdatain[7..0],
                                  xgmctrl,
                                  srlpbk,
                                  vodctrl[2..0],
                                  preemphasisctrl[2..0]
                                ) 
                         WITH ( 
                                  CHANNEL_NUM,
                                  CHANNEL_WIDTH,
                                  USE_DOUBLE_DATA_MODE,
                                  USE_8B_10B_MODE,
                                  USE_FIFO_MODE,
                                  FORCE_DISPARITY_MODE,
                                  TRANSMIT_PROTOCOL,
                                  USE_VOD_CTRL_SIGNAL,
                                  VOD_CTRL_SETTING,
                                  USE_PREEMPHASIS_CTRL_SIGNAL,
                                  PREEMPHASIS_CTRL_SETTING,
                                  USE_SELF_TEST_MODE,
                                  SELF_TEST_MODE,
                                  USE_REVERSE_PARALLEL_FEEDBACK,
                                  TERMINATION
                                )
                        RETURNS (
                                  dataout,
                                  xgmdataout[7..0],
                                  xgmctrlenable,
                                  rdenablesync,
                                  parallelfdbkdata[(USE_8B_10B_MODE == "TRUE") ? 9 : (USE_DOUBLE_DATA_MODE == "TRUE") ? ((CHANNEL_WIDTH / 2) - 1) : (CHANNEL_WIDTH - 1)..0],
                                  pre8b10bdata[(USE_8B_10B_MODE == "TRUE") ? 7 : (USE_DOUBLE_DATA_MODE == "TRUE") ? ((CHANNEL_WIDTH / 2) - 1) : (CHANNEL_WIDTH - 1)..0]
                                );
---------- stratixgx_pll.inc ----------
----------------------------------------------------------------------------------------------------------
--
-- stratixgx_PLL.INC
--
-- Wysiwyg include file for Stratix family PLL
--
-- (c) Altera Corporation, 2001
--
----------------------------------------------------------------------------------------------------------
FUNCTION stratixgx_pll(
						inclk[1..0],
						fbin,
						ena,
						clkswitch,
						areset,
						pfdena,
						clkena[5..0],
						extclkena[3..0],
						scanclk,
						scanaclr,
						scandata,
						comparator
					)
					WITH
					(
						OPERATION_MODE,
						QUALIFY_CONF_DONE,
						COMPENSATE_CLOCK,
						PLL_TYPE,
						SCAN_CHAIN,
						-- Internal clock specifications
						CLK5_MULTIPLY_BY,
						CLK4_MULTIPLY_BY,
						CLK3_MULTIPLY_BY,
						CLK2_MULTIPLY_BY,
						CLK1_MULTIPLY_BY,
						CLK0_MULTIPLY_BY,
						CLK5_DIVIDE_BY,
						CLK4_DIVIDE_BY,
						CLK3_DIVIDE_BY,
						CLK2_DIVIDE_BY,
						CLK1_DIVIDE_BY,
						CLK0_DIVIDE_BY,
						CLK5_PHASE_SHIFT,
						CLK4_PHASE_SHIFT,
						CLK3_PHASE_SHIFT,
						CLK2_PHASE_SHIFT,
						CLK1_PHASE_SHIFT,
						CLK0_PHASE_SHIFT,
						CLK5_TIME_DELAY,
						CLK4_TIME_DELAY,
						CLK3_TIME_DELAY,
						CLK2_TIME_DELAY,
						CLK1_TIME_DELAY,
						CLK0_TIME_DELAY,
						CLK5_DUTY_CYCLE,
						CLK4_DUTY_CYCLE,
						CLK3_DUTY_CYCLE,
						CLK2_DUTY_CYCLE,
						CLK1_DUTY_CYCLE,
						CLK0_DUTY_CYCLE,
						-- External clock specifications
						EXTCLK3_MULTIPLY_BY,
						EXTCLK2_MULTIPLY_BY,
						EXTCLK1_MULTIPLY_BY,
						EXTCLK0_MULTIPLY_BY,
						EXTCLK3_DIVIDE_BY,
						EXTCLK2_DIVIDE_BY,
						EXTCLK1_DIVIDE_BY,
						EXTCLK0_DIVIDE_BY,
						EXTCLK3_PHASE_SHIFT,
						EXTCLK2_PHASE_SHIFT,
						EXTCLK1_PHASE_SHIFT,
						EXTCLK0_PHASE_SHIFT,
						EXTCLK3_TIME_DELAY,
						EXTCLK2_TIME_DELAY,
						EXTCLK1_TIME_DELAY,
						EXTCLK0_TIME_DELAY,
						EXTCLK3_DUTY_CYCLE,
						EXTCLK2_DUTY_CYCLE,
						EXTCLK1_DUTY_CYCLE,
						EXTCLK0_DUTY_CYCLE,
						PRIMARY_CLOCK,
						INCLK0_INPUT_FREQUENCY,
						INCLK1_INPUT_FREQUENCY,
						GATE_LOCK_SIGNAL,
						GATE_LOCK_COUNTER,
						LOCK_HIGH,
						LOCK_LOW,
						VALID_LOCK_MULTIPLIER,
						INVALID_LOCK_MULTIPLIER,
						SWITCH_OVER_ON_LOSSCLK,
						SWITCH_OVER_ON_GATED_LOCK,
						ENABLE_SWITCH_OVER_COUNTER,
						SWITCH_OVER_COUNTER,
						FEEDBACK_SOURCE,
						BANDWIDTH,
						BANDWIDTH_TYPE,
						SPREAD_FREQUENCY,
						DOWN_SPREAD,
						-- Advanced use parameters
						VCO_MIN,
						VCO_MAX,
						VCO_CENTER,
						PFD_MIN,
						PFD_MAX,
						M_INITIAL,
						M,
						N,
						M2,
						N2,
						SS,
						L0_HIGH,
						L1_HIGH,
						G0_HIGH,
						G1_HIGH,
						G2_HIGH,
						G3_HIGH,
						E0_HIGH,
						E1_HIGH,
						E2_HIGH,
						E3_HIGH,
						L0_LOW,
						L1_LOW,
						G0_LOW,
						G1_LOW,
						G2_LOW,
						G3_LOW,
						E0_LOW,
						E1_LOW,
						E2_LOW,
						E3_LOW,
						L0_INITIAL,
						L1_INITIAL,
						G0_INITIAL,
						G1_INITIAL,
						G2_INITIAL,
						G3_INITIAL,
						E0_INITIAL,
						E1_INITIAL,
						E2_INITIAL,
						E3_INITIAL,
						L0_MODE,
						L1_MODE,
						G0_MODE,
						G1_MODE,
						G2_MODE,
						G3_MODE,
						E0_MODE,
						E1_MODE,
						E2_MODE,
						E3_MODE,
						L0_PH,
						L1_PH,
						G0_PH,
						G1_PH,
						G2_PH,
						G3_PH,
						E0_PH,
						E1_PH,
						E2_PH,
						E3_PH,
						M_PH,
						L0_TIME_DELAY,
						L1_TIME_DELAY,
						G0_TIME_DELAY,
						G1_TIME_DELAY,
						G2_TIME_DELAY,
						G3_TIME_DELAY,
						E0_TIME_DELAY,
						E1_TIME_DELAY,
						E2_TIME_DELAY,
						E3_TIME_DELAY,
						M_TIME_DELAY,
						N_TIME_DELAY,
						EXTCLK3_COUNTER,
						EXTCLK2_COUNTER,
						EXTCLK1_COUNTER,
						EXTCLK0_COUNTER,
						CLK5_COUNTER,
						CLK4_COUNTER,
						CLK3_COUNTER,
						CLK2_COUNTER,
						CLK1_COUNTER,
						CLK0_COUNTER,
						ENABLE0_COUNTER,
						ENABLE1_COUNTER,
						CHARGE_PUMP_CURRENT,
						LOOP_FILTER_R,
						LOOP_FILTER_C,
						RX_OUTCLOCK_RESOURCE,
                                                USE_DC_COUPLING,
                                                USE_VCO_BYPASS
					)
					RETURNS
					(
						clk[5..0],
						extclk[3..0],
						clkbad[1..0],
						activeclock,
						locked,
						clkloss,
						enable1,
						enable0,
                                                scandataout
					);
---------- stratixgx_xgm_interface.inc ----------
--------------------------------------------------------------------------------
--------------------------
--
-- STRATIXGX_XGM_INTERFACE
--
-- Wysiwyg include file for Aurora HSSI Transmitter
--
-- (c) Altera Corporation, 2002
--
--------------------------------------------------------------------------------

FUNCTION stratixgx_xgm_interface(
                               txdatain[31..0],
                               txctrl[3..0],
                               rdenablesync,
                               txclk,
                               rxdatain[31..0],
                               rxctrl[3..0],
                               rxrunningdisp[3..0],
                               rxdatavalid[3..0],
                               rxclk,
                               resetall,
                               adet[3..0],
                               syncstatus[3..0],
                               rdalign[3..0],
                               recovclk,
                               txdigitalreset[3..0],
                               rxdigitalreset[3..0],
                               rxanalogreset[3..0],
                               pllreset,
                               pllenable,
                               scanclk,
                               scanin,
                               scanshift,
                               scanmode,
                               mdiodisable,
                               mdioclk,
                               mdioin,
                               rxppmselect
                             ) 
                     WITH    (USE_CONTINUOUS_CALIBRATION_MODE,
                              MODE_IS_XAUI,
                              DIGITAL_TEST_OUTPUT_SELECT,
                              ANALOG_TEST_OUTPUT_SIGNAL_SELECT,
                              ANALOG_TEST_OUTPUT_CHANNEL_SELECT,
                              RX_PPM_SETTING_0,
                              RX_PPM_SETTING_1,
                              USE_RX_CALIBRATION_STATUS,
                              USE_GLOBAL_SERIAL_LOOPBACK,
                              RX_CALIBRATION_TEST_WRITE_VALUE,
                              ENABLE_RX_CALIBRATION_TEST_WRITE,
                              TX_CALIBRATION_TEST_WRITE_VALUE,
                              ENABLE_TX_CALIBRATION_TEST_WRITE
                             )
                     RETURNS (
                               txdataout[31..0],
                               txctrlout[3..0],
                               rxdataout[31..0],
                               rxctrlout[3..0],
                               alignstatus,
                               enabledeskew,
                               fiforesetrd,
                               txdigitalresetout[3..0],
                               txanalogresetout[3..0],
                               rxdigitalresetout[3..0],
                               rxanalogresetout[3..0],
                               pllresetout,
                               mdioout,
                               mdiooe,
                               scanout,
                               test,
                               digitalsmtest[3..0],
                               calibrationstatus[4..0] 
                             );
---------- stratixii_mac_mult.inc ----------
FUNCTION stratixii_mac_mult(
							dataa[DATAA_WIDTH - 1..0],
							datab[DATAB_WIDTH - 1..0],
							scanina[DATAA_WIDTH - 1..0],
							scaninb[DATAB_WIDTH - 1..0],
							sourcea,
							sourceb,
							signa,
							signb,
							round,
							saturate,
							mode, -- Dynamic mode
							zeroacc, -- Dynamic mode
							clk[3..0],
							aclr[3..0],
							ena[3..0]
						)
						WITH
						(
							DATAA_WIDTH,
							DATAB_WIDTH,
							DATAA_CLOCK,
							DATAB_CLOCK,
							SIGNA_CLOCK,
							SIGNB_CLOCK,
							ROUND_CLOCK,
							SATURATE_CLOCK,
							OUTPUT_CLOCK,
							DATAA_CLEAR,
							DATAB_CLEAR,
							SIGNA_CLEAR,
							SIGNB_CLEAR,
							MODE_CLOCK, -- Dynamic mode
							ZERO_ACC_CLOCK,-- Dynamic mode
							MODE_CLEAR,-- Dynamic mode
							ZERO_ACC_CLEAR,-- Dynamic mode
							ROUND_CLEAR,
							SATURATE_CLEAR,
							OUTPUT_CLEAR,
							BYPASS_MULTIPLIER
						)
						RETURNS
						(
							dataout[DATAA_WIDTH + DATAB_WIDTH - 1..0],
							scanouta[DATAA_WIDTH - 1..0],
							scanoutb[DATAB_WIDTH - 1..0]
						);
---------- stratixii_mac_out.inc ----------
PARAMETERS
(
	DATAA_WIDTH = 0,
	DATAB_WIDTH = 0,
	DATAC_WIDTH = 0,
	DATAD_WIDTH = 0
);

FUNCTION stratixii_mac_out	(
							dataa[(DATAA_WIDTH == 0 ? 1 : DATAA_WIDTH) - 1..0],
							datab[(DATAB_WIDTH == 0 ? 1 : DATAB_WIDTH) - 1..0],
							datac[(DATAC_WIDTH == 0 ? 1 : DATAC_WIDTH) - 1..0],
							datad[(DATAD_WIDTH == 0 ? 1 : DATAD_WIDTH) - 1..0],
							zeroacc,
							addnsub0,
							addnsub1,
							round0,
							round1,
							saturate,
							multabsaturate,
							multcdsaturate,
							mode0, -- Dynamic mode
							mode1, -- Dynamic mode
							zeroacc1, -- Dynamic mode
							saturate1, -- Dynamic mode
							signa,
							signb,
							clk[3..0],
							aclr[3..0],
							ena[3..0]
						)
						WITH
						(
							OPERATION_MODE,
							DATAA_WIDTH,
							DATAB_WIDTH,
							DATAC_WIDTH,
							DATAD_WIDTH,
							ADDNSUB0_CLOCK,
							ADDNSUB1_CLOCK,
							ZEROACC_CLOCK,
							SIGNA_CLOCK,
							SIGNB_CLOCK,
							ROUND0_CLOCK,
							ROUND1_CLOCK,
							SATURATE_CLOCK,
							MULTABSATURATE_CLOCK,
							MULTCDSATURATE_CLOCK,
							OUTPUT_CLOCK,
							ADDNSUB0_CLEAR,
							ADDNSUB1_CLEAR,
							ZEROACC_CLEAR,
							SIGNA_CLEAR,
							SIGNB_CLEAR,
							ROUND0_CLEAR,
							ROUND1_CLEAR,
							SATURATE_CLEAR,
							MULTABSATURATE_CLEAR,
							MULTCDSATURATE_CLEAR,
							OUTPUT_CLEAR,
							ADDNSUB0_PIPELINE_CLOCK,
							ADDNSUB1_PIPELINE_CLOCK,
							ZEROACC_PIPELINE_CLOCK,
							SIGNA_PIPELINE_CLOCK,
							SIGNB_PIPELINE_CLOCK,
							ROUND0_PIPELINE_CLOCK,
							ROUND1_PIPELINE_CLOCK,
							SATURATE_PIPELINE_CLOCK,
							MULTABSATURATE_PIPELINE_CLOCK,
							MULTCDSATURATE_PIPELINE_CLOCK,
							ADDNSUB0_PIPELINE_CLEAR,
							ADDNSUB1_PIPELINE_CLEAR,
							ZEROACC_PIPELINE_CLEAR,
							SIGNA_PIPELINE_CLEAR,
							SIGNB_PIPELINE_CLEAR,
							MODE0_CLOCK, -- Dynamic mode
							MODE1_CLOCK, -- Dynamic mode
							ZEROACC1_CLOCK, -- Dynamic mode
							SATURATE1_CLOCK, -- Dynamic mode
							OUTPUT1_CLOCK, -- Dynamic mode
							OUTPUT2_CLOCK, -- Dynamic mode
							OUTPUT3_CLOCK, -- Dynamic mode
							OUTPUT4_CLOCK, -- Dynamic mode
							OUTPUT5_CLOCK, -- Dynamic mode
							OUTPUT6_CLOCK, -- Dynamic mode
							OUTPUT7_CLOCK, -- Dynamic mode
							MODE0_PIPELINE_CLOCK, -- Dynamic mode
							MODE1_PIPELINE_CLOCK, -- Dynamic mode
							ZEROACC1_PIPELINE_CLOCK, -- Dynamic mode
							SATURATE1_PIPELINE_CLOCK, -- Dynamic mode
							MODE0_CLEAR, -- Dynamic mode
							MODE1_CLEAR, -- Dynamic mode
							ZEROACC1_CLEAR, -- Dynamic mode
							SATURATE1_CLEAR, -- Dynamic mode
							OUTPUT1_CLEAR, -- Dynamic mode
							OUTPUT2_CLEAR, -- Dynamic mode
							OUTPUT3_CLEAR, -- Dynamic mode
							OUTPUT4_CLEAR, -- Dynamic mode
							OUTPUT5_CLEAR, -- Dynamic mode
							OUTPUT6_CLEAR, -- Dynamic mode
							OUTPUT7_CLEAR, -- Dynamic mode
							MODE0_PIPELINE_CLEAR, -- Dynamic mode
							MODE1_PIPELINE_CLEAR, -- Dynamic mode
							ZEROACC1_PIPELINE_CLEAR, -- Dynamic mode
							SATURATE1_PIPELINE_CLEAR, -- Dynamic mode
							DATAA_FORCED_TO_ZERO, -- Dynamic mode
							DATAC_FORCED_TO_ZERO, -- Dynamic mode
							ROUND0_PIPELINE_CLEAR,
							ROUND1_PIPELINE_CLEAR,
							SATURATE_PIPELINE_CLEAR,
							MULTABSATURATE_PIPELINE_CLEAR,
							MULTCDSATURATE_PIPELINE_CLEAR
						)
						RETURNS
						(
							dataout[	((OPERATION_MODE == "OUTPUT_ONLY")		?	DATAA_WIDTH :
										(OPERATION_MODE == "ACCUMULATOR")		?	DATAB_WIDTH + 16 :
										(OPERATION_MODE == "ONE_LEVEL_ADDER")	?	DATAA_WIDTH + 1 :
										(OPERATION_MODE == "TWO_LEVEL_ADDER")	?	DATAA_WIDTH + 2	:
										(OPERATION_MODE == "36_BIT_MULTIPLY")	?	DATAA_WIDTH + DATAB_WIDTH:
										%OTHERWISE%									DATAA_WIDTH + DATAB_WIDTH + DATAC_WIDTH + DATAD_WIDTH)
										- 1..0],
							accoverflow
						);
										
---------- stratixii_pll.inc ----------
----------------------------------------------------------------------------------------------------------
--
-- STRATIXII_PLL.INC
--
-- Wysiwyg include file for Stratix II family PLL
--
-- (c) Altera Corporation, 2003
--
----------------------------------------------------------------------------------------------------------
FUNCTION stratixii_pll(
						inclk[1..0],
						clkswitch,
						ena,
						areset,
						pfdena,
						fbin,
						scanclk,
						scanread,
						scanwrite,
						scandata,
						testin[3..0]
					)
					WITH
					(
						OPERATION_MODE,
						QUALIFY_CONF_DONE,
						COMPENSATE_CLOCK,
						PLL_TYPE,
						-- Internal clock specifications
						CLK5_MULTIPLY_BY,
						CLK4_MULTIPLY_BY,
						CLK3_MULTIPLY_BY,
						CLK2_MULTIPLY_BY,
						CLK1_MULTIPLY_BY,
						CLK0_MULTIPLY_BY,
						CLK5_DIVIDE_BY,
						CLK4_DIVIDE_BY,
						CLK3_DIVIDE_BY,
						CLK2_DIVIDE_BY,
						CLK1_DIVIDE_BY,
						CLK0_DIVIDE_BY,
						CLK5_PHASE_SHIFT,
						CLK4_PHASE_SHIFT,
						CLK3_PHASE_SHIFT,
						CLK2_PHASE_SHIFT,
						CLK1_PHASE_SHIFT,
						CLK0_PHASE_SHIFT,
						CLK5_DUTY_CYCLE,
						CLK4_DUTY_CYCLE,
						CLK3_DUTY_CYCLE,
						CLK2_DUTY_CYCLE,
						CLK1_DUTY_CYCLE,
						CLK0_DUTY_CYCLE,
						SCLKOUT1_PHASE_SHIFT,
						SCLKOUT0_PHASE_SHIFT,
						INCLK0_INPUT_FREQUENCY,
						INCLK1_INPUT_FREQUENCY,
						VCO_MULTIPLY_BY,
						VCO_DIVIDE_BY,
						GATE_LOCK_SIGNAL,
						GATE_LOCK_COUNTER,
						LOCK_HIGH,
						LOCK_LOW,
						VALID_LOCK_MULTIPLIER,
						INVALID_LOCK_MULTIPLIER,
						SWITCH_OVER_ON_LOSSCLK,
						SWITCH_OVER_ON_GATED_LOCK,
						ENABLE_SWITCH_OVER_COUNTER,
						SWITCH_OVER_COUNTER,
						SWITCH_OVER_TYPE,
						FEEDBACK_SOURCE,
						BANDWIDTH,
						BANDWIDTH_TYPE,
						SPREAD_FREQUENCY,
						DOWN_SPREAD,
						TEST_INPUT_COMP_DELAY_CHAIN_BITS,
						TEST_FEEDBACK_COMP_DELAY_CHAIN_BITS,
						VCO_MULTIPLY_BY,
						VCO_DIVIDE_BY,
						-- Advanced use parameters
						VCO_MIN,
						VCO_MAX,
						VCO_CENTER,
						PFD_MIN,
						PFD_MAX,
						M_INITIAL,
						M,
						N,
						VCO_POST_SCALE,
						M2,
						N2,
						SS,
						C0_HIGH,
						C1_HIGH,
						C2_HIGH,
						C3_HIGH,
						C4_HIGH,
						C5_HIGH,
						C0_LOW,
						C1_LOW,
						C2_LOW,
						C3_LOW,
						C4_LOW,
						C5_LOW,
						C0_INITIAL,
						C1_INITIAL,
						C2_INITIAL,
						C3_INITIAL,
						C4_INITIAL,
						C5_INITIAL,
						C0_MODE,
						C1_MODE,
						C2_MODE,
						C3_MODE,
						C4_MODE,
						C5_MODE,
						C0_PH,
						C1_PH,
						C2_PH,
						C3_PH,
						C4_PH,
						C5_PH,
						M_PH,
						C1_USE_CASC_IN,
						C2_USE_CASC_IN,
						C3_USE_CASC_IN,
						C4_USE_CASC_IN,
						C5_USE_CASC_IN,
						C0_TEST_SOURCE,
						C1_TEST_SOURCE,
						C2_TEST_SOURCE,
						C3_TEST_SOURCE,
						C4_TEST_SOURCE,
						C5_TEST_SOURCE,
						CLK5_COUNTER,
						CLK4_COUNTER,
						CLK3_COUNTER,
						CLK2_COUNTER,
						CLK1_COUNTER,
						CLK0_COUNTER,
						ENABLE0_COUNTER,
						ENABLE1_COUNTER,
						CHARGE_PUMP_CURRENT,
						LOOP_FILTER_R,
						LOOP_FILTER_C,
						M_TEST_SOURCE,
						C0_TEST_SOURCE,
						C1_TEST_SOURCE,
						C2_TEST_SOURCE,
						C3_TEST_SOURCE,
						C4_TEST_SOURCE,
						C5_TEST_SOURCE
					)
					RETURNS
					(
						clk[5..0],
						clkbad[1..0],
						activeclock,
						locked,
						clkloss,
						sclkout[1..0],
						enable1,
						enable0,
						scandataout,
						scandone,
						testupout,
						testdownout
					);
---------- stratixii_ram_block.inc ----------

FUNCTION stratixii_ram_block (
							portadatain[PORT_A_DATA_WIDTH-1..0], 	--	DATA A
							portaaddr[PORT_A_ADDRESS_WIDTH-1..0],		--	ADDR A
							portawe,		--	WRITE ENABLE A		
							portbdatain[(OPERATION_MODE == "ROM" # OPERATION_MODE == "SINGLE_PORT") ? 0 : PORT_B_DATA_WIDTH-1..0],	--	DATA B
							portbaddr[(OPERATION_MODE == "ROM" # OPERATION_MODE == "SINGLE_PORT") ? 0 : (PORT_B_ADDRESS_WIDTH == 0) ? 0 : PORT_B_ADDRESS_WIDTH-1..0],		--	ADDR B
							portbrewe,		--	READ ENABLE / WRITE ENABLE B
							clk0, 			--	CLK 0
							clk1,			--	CLK 1
							ena0,			--	ENABLE FOR CLK 0							
							ena1,			--	ENABLE FOR CLK 1
							clr0,			--	CLEAR 
							clr1,			--	CLEAR 1
							portabyteenamasks[OPERATION_MODE != "ROM" ? (PORT_A_BYTE_ENABLE_MASK_WIDTH == 0 ? 0 : PORT_A_BYTE_ENABLE_MASK_WIDTH-1) : 0..0],	--	A BYTE ENABLE MASKS
							portbbyteenamasks[OPERATION_MODE == "BIDIR_DUAL_PORT" ? (PORT_B_BYTE_ENABLE_MASK_WIDTH == 0 ? 0 : PORT_B_BYTE_ENABLE_MASK_WIDTH-1)  : 0..0],	--	B BYTE ENABLE MASKS
							portaaddrstall,
							portbaddrstall
						)
						WITH
						(
							OPERATION_MODE,
							MIXED_PORT_FEED_THROUGH_MODE,
							RAM_BLOCK_TYPE,
							PHYSICAL_PORT,
							LOGICAL_RAM_NAME,
							INIT_FILE,
							INIT_FILE_LAYOUT,
							DATA_INTERLEAVE_WIDTH_IN_BITS,
							DATA_INTERLEAVE_OFFSET_IN_BITS,
							PORT_A_LOGICAL_RAM_DEPTH,
							PORT_A_LOGICAL_RAM_WIDTH,
							PORT_A_DATA_OUT_CLOCK,
							PORT_A_DATA_OUT_CLEAR,
							PORT_A_FIRST_ADDRESS,
							PORT_A_LAST_ADDRESS,
							PORT_A_FIRST_BIT_NUMBER,
							PORT_A_DATA_WIDTH,
							PORT_A_ADDRESS_WIDTH,
							PORT_A_BYTE_ENABLE_MASK_WIDTH,
							PORT_A_BYTE_SIZE,
							PORT_A_DISABLE_CE_ON_INPUT_REGISTERS,
							PORT_A_DISABLE_CE_ON_OUTPUT_REGISTERS,
							PORT_B_LOGICAL_RAM_DEPTH,
							PORT_B_LOGICAL_RAM_WIDTH,
							PORT_B_DATA_IN_CLOCK,
							PORT_B_ADDRESS_CLOCK,
							PORT_B_READ_ENABLE_WRITE_ENABLE_CLOCK,
							PORT_B_DATA_OUT_CLOCK,
							PORT_B_DATA_OUT_CLEAR,
							PORT_B_BYTE_ENABLE_CLOCK,
							PORT_B_FIRST_ADDRESS,
							PORT_B_LAST_ADDRESS,
							PORT_B_FIRST_BIT_NUMBER,
							PORT_B_DATA_WIDTH,
							PORT_B_ADDRESS_WIDTH,
							PORT_B_BYTE_ENABLE_MASK_WIDTH,
							PORT_B_BYTE_SIZE,
							PORT_B_DISABLE_CE_ON_INPUT_REGISTERS,
							PORT_B_DISABLE_CE_ON_OUTPUT_REGISTERS
						)
						RETURNS
						(
							portadataout[PORT_A_DATA_WIDTH-1..0],	--	DATA OUT A
							portbdataout[(OPERATION_MODE == "ROM" # OPERATION_MODE == "SINGLE_PORT") ? 0 : PORT_B_DATA_WIDTH-1..0]	--	DATA OUT B
						);
						
						---------- syn_dffe.inc ----------
FUNCTION syn_dffe
(
	d, clk, clrn, prn, ena
)
RETURNS
(
	q
)
;

---------- syn_lat.inc ----------
FUNCTION syn_lat
(
	d, ena
)
RETURNS
(
	q
)
;

---------- syn_tffe.inc ----------
FUNCTION syn_tffe
(
	t, clk, clrn, prn, ena
)
RETURNS
(
	q
)
;

---------- tffe_high.inc ----------
FUNCTION tffe_high
(
	t, clk, clrn, prn, ena
)
WITH
(
	power_up_high
)
RETURNS
(
	q
)
;

