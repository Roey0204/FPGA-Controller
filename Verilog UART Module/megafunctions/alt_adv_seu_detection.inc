------------------------------------------------------------------
-- alt_adv_seu_detection parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
DEFINE mem_data_width() = 32;

FUNCTION alt_adv_seu_detection(
	cache_comparison_off,
	clk,
	emr_cache_ack,
	mem_critical,
	mem_data[mem_data_width()-1..0],
	mem_wait,
	nreset
)
WITH(
	cache_depth,
	clock_frequency,
	emr_data_width = 35,
	enable_virtual_jtag,
	error_clock_divisor,
	error_delay_cycles,
	intended_device_family,
	lpm_hint,
	lpm_type,
	mem_addr_width = 32,
	start_address,
	use_memory_interface
)
RETURNS(
	cache_fill_level[3..0],
	cache_full,
	crcerror_core,
	crcerror_pin,
	critical_error,
	emr_cache_int,
	emr_data[emr_data_width-1..0],
	mem_addr[mem_addr_width-1..0],
	mem_bytesel[3..0],
	mem_rd,
	noncritical_error
);