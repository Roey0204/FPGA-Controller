
FUNCTION alt_aeq_s4(
                            reconfig_clk,
                            aclr,
                            calibrate,
                            shutdown,
                            all_channels,
                            logical_channel_address[CHANNEL_ADDRESS_WIDTH-1..0],
                            remap_address[11..0],
                            adce_done[NUMBER_OF_CHANNELS-1..0],
                            adce_continuous,
                            testbuses[NUMBER_OF_CHANNELS-1..0],
                            dprio_busy,
                            dprio_in[15..0]
						)

						WITH (
						show_errors,
						radce_hflck,
						radce_lflck,
						use_hw_conv_det,
						number_of_channels,
						channel_address_width
						)

						RETURNS	(
                            quad_address[8..0],
                            busy,
                            adce_standby[NUMBER_OF_CHANNELS-1..0],
                            dprio_wren,
                            dprio_rden,
                            dprio_addr[15..0],
                            dprio_data[15..0],
                            testbus_sels[(NUMBER_OF_CHANNELS) * (4) - (1)..0],
                            error[NUMBER_OF_CHANNELS-1..0]
						);


