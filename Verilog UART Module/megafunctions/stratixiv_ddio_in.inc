------------------------------------------------------------------
-- stratixiv_ddio_in parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------

FUNCTION stratixiv_ddio_in(
	areset,
	clk,
	clkn,
	datain,
	devclrn,
	devpor,
	ena,
	sreset
)
WITH(
	async_mode,
	lpm_hint,
	lpm_type,
	power_up,
	sync_mode,
	use_clkn
)
RETURNS(
	regouthi,
	regoutlo
);