------------------------------------------------------------------
-- altserial_flash_loader parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------

FUNCTION altserial_flash_loader(
	asmi_access_granted,
	data_in[3..0],
	data_oe[3..0],
	dclkin,
	noe,
	scein,
	sdoin
)
WITH(
	enable_quad_spi_support,
	enable_shared_access,
	enhanced_mode,
	intended_device_family,
	lpm_hint,
	lpm_type
)
RETURNS(
	asmi_access_request,
	data0out,
	data_out[3..0]
);