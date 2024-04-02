FUNCTION alt_eyemon
(
	i_resetn, 
	i_avmm_clk,
	i_avmm_saddress[avmm_slave_addr_width - 1..0],
	i_avmm_sread,
	i_avmm_swrite,
	i_avmm_swritedata[avmm_slave_wdata_width - 1..0],
	i_avmm_sbegintransfer,
	i_remap_phase,
	i_remap_address[11..0],
	i_dprio_busy,
	i_dprio_in[dprio_data_width - 1..0]
)
WITH
(
	channel_address_width,
	avmm_slave_addr_width,
	avmm_slave_rdata_width,
	avmm_slave_wdata_width,
	avmm_master_addr_width,
	avmm_master_rdata_width,
	avmm_master_wdata_width,
	dprio_addr_width,
	dprio_data_width,
	ireg_chaddr_width,
	ireg_wdaddr_width,
	ireg_data_width
)
RETURNS
(
	o_avmm_sreaddata[avmm_slave_rdata_width - 1..0],
	o_avmm_swaitrequest,
	o_quad_address[8..0],
	o_reconfig_busy,
	o_dprio_wren,
	o_dprio_rden,
	o_dprio_addr[dprio_addr_width - 1..0],
	o_dprio_data[dprio_data_width - 1..0]

);
