------------------------------------------------------------------
-- cycloneiii_io_ibuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------

FUNCTION cycloneiii_io_ibuf(
	i,
	ibar
)
WITH(
	bus_hold,
	differential_mode,
	lpm_hint,
	lpm_type,
	simulate_z_as
)
RETURNS(
	o
);