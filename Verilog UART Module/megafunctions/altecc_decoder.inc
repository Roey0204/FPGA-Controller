------------------------------------------------------------------
-- altecc_decoder parameterized megafunction include file
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
FUNCTION altecc_decoder (
	aclr,
	clock,
	clocken,
	data[width_codeword-1..0]
)
WITH (
	lpm_pipeline,
	width_codeword = 8,
	width_dataword = 8
)
RETURNS (
	err_corrected,
	err_detected,
	err_fatal,
	q[width_dataword-1..0],
	syn_e
);
