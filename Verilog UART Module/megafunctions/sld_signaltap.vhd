--------------------------------------------------------------------
--
--	SignalTap II Parameterized Megafunction
--
--  Copyright (C) 1991-2013 Altera Corporation
--
--  Your use of Altera Corporation's design tools, logic functions  
--  and other software and tools, and its AMPP partner logic  
--  functions, and any output files from any of the foregoing  
--  (including device programming or simulation files), and any  
--  associated documentation or information are expressly subject  
--  to the terms and conditions of the Altera Program License  
--  Subscription Agreement, Altera MegaCore Function License  
--  Agreement, or other applicable license agreement, including,  
--  without limitation, that your use is for the sole purpose of  
--  programming logic devices manufactured by Altera and sold by  
--  Altera or its authorized distributors.  Please refer to the  
--  applicable agreement for further details. 
--  
--  13.0.0 Build 156 04/24/2013 SJ Full Version
--
--
--------------------------------------------------------------------

package sld_signaltap_pack is
	constant SLD_IR_BITS					: natural := 8;	-- Constant value.  DO NOT CHANGE.
end package sld_signaltap_pack;


library ieee;
use ieee.std_logic_1164.all;
use work.sld_signaltap_pack.all;


entity sld_signaltap is
	generic 
	(
		lpm_type					: string := "sld_signaltap";

		SLD_NODE_INFO				: natural := 0;		-- The NODE ID to uniquely identify this node on the hub.
		


		-- Auto generated version definition begin
		SLD_IP_VERSION					: natural := 6;
		SLD_IP_MINOR_VERSION				: natural := 0;
		SLD_COMMON_IP_VERSION				: natural := 0;
		-- Auto generated version definition end

		
		-- ELA Input Width Parameters
		SLD_DATA_BITS				: natural := 1;		-- The ELA data input width in bits
		SLD_TRIGGER_BITS			: natural := 1;		-- The ELA trigger input width in bits
				
		-- Consistency Check Parameters
		SLD_NODE_CRC_BITS			: natural := 32;
		SLD_NODE_CRC_HIWORD			: natural := 41394;	-- High byte of the CRC word
		SLD_NODE_CRC_LOWORD			: natural := 50132;	-- Low byte of the CRC word
		SLD_INCREMENTAL_ROUTING		: natural := 0;		-- Indicate whether incremental CRC register is used

		-- Acquisition Buffer Parameters
		SLD_SAMPLE_DEPTH			: natural := 16;	-- Memory buffer size
		SLD_SEGMENT_SIZE			: natural := 0;	-- Size of each segment
		SLD_RAM_BLOCK_TYPE			: string := "AUTO";	-- Memory buffer type on the device
		SLD_STATE_BITS				: natural := 11;		-- bits needed for state encoding
		
		SLD_BUFFER_FULL_STOP		: natural := 1;		-- if set to 1, once last segment full auto stops acquisition
		
		--obsoleted
		SLD_MEM_ADDRESS_BITS		: natural := 7;		-- Memory buffer address width log2(SLD_SAMPLE_DEPTH)
		SLD_DATA_BIT_CNTR_BITS		: natural := 4;		-- = ceil(log2(SLD_DATA_BITS)) + 1
		
		-- Trigger Control Parameters
		SLD_TRIGGER_LEVEL			: natural := 10;		-- Number of trigger levels that will be used to stop the data acquisition
		SLD_TRIGGER_IN_ENABLED		: natural := 0;		-- Indicate whether to generate the trigger_in logic.  Generate if it is 1; not, otherwise.
		SLD_HPS_TRIGGER_IN_ENABLED	: natural := 0;		-- Indicate whether to generate the trigger_in logic from HPS.  Generate if it is 1; not, otherwise.
		SLD_HPS_TRIGGER_OUT_ENABLED	: natural := 0;		-- Indicate whether to generate the trigger_out logic driving HPS.  Generate if it is 1; not, otherwise.
		SLD_HPS_EVENT_ENABLED		: natural := 0;		-- Indicate whether to generate the event logic driving HPS.  Generate if it is 1; not, otherwise.
		SLD_HPS_EVENT_ID			: natural := 0;		-- Specifies the event line index, if event logic is created driving HPS.
		SLD_ADVANCED_TRIGGER_ENTITY	: string := "basic";	-- Comma delimited entity name for each advanced trigger level, or "basic" if level is using standard mode
		SLD_TRIGGER_LEVEL_PIPELINE	: natural := 1;		-- Length of trigger level pipeline.
		SLD_ENABLE_ADVANCED_TRIGGER	: natural := 0;		-- Indicate whether to deploy multi-level basic trigger level or advanced trigger level
		SLD_ADVANCED_TRIGGER_1		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_2		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_3		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_4		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_5		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_6		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_7		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_8		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_9		: string := "NONE";	-- advanced trigger expression
		SLD_ADVANCED_TRIGGER_10		: string := "NONE";	-- advanced trigger expression
		SLD_INVERSION_MASK_LENGTH	: integer := 1;		-- length of inversion mask
		SLD_INVERSION_MASK			: std_logic_vector := "0"; --inversion mask
		SLD_POWER_UP_TRIGGER		: natural := 0;		-- power-up trigger mode
		SLD_STATE_FLOW_MGR_ENTITY	: string := "state_flow_mgr_entity.vhd";	--name of generated entity controlling state flow
		SLD_STATE_FLOW_USE_GENERATED	: natural := 0;
		SLD_CURRENT_RESOURCE_WIDTH	: natural := 0;
		SLD_ATTRIBUTE_MEM_MODE		: string := "OFF";
		
		--Storage Qualifier Parameters
		SLD_STORAGE_QUALIFIER_BITS	: natural := 1;
		SLD_STORAGE_QUALIFIER_GAP_RECORD : natural := 0;
		SLD_STORAGE_QUALIFIER_MODE	: string := "OFF";
		SLD_STORAGE_QUALIFIER_ENABLE_ADVANCED_CONDITION	: natural := 0;		-- Indicate whether to deploy multi-level basic condition level or advanced condition level
		SLD_STORAGE_QUALIFIER_INVERSION_MASK_LENGTH	: natural := 0;
		SLD_STORAGE_QUALIFIER_ADVANCED_CONDITION_ENTITY	: string := "basic";
		SLD_STORAGE_QUALIFIER_PIPELINE : natural := 0
				
	);

	port 
	(
		acq_clk						: in std_logic;		-- The acquisition clock
		acq_data_in					: in std_logic_vector (SLD_DATA_BITS-1 downto 0) := (others => '0');	-- The data input source to be acquired.
		acq_trigger_in				: in std_logic_vector (SLD_TRIGGER_BITS-1 downto 0) := (others => '0');	-- The trigger input source to be analyzed.
		acq_storage_qualifier_in	: in std_logic_vector (SLD_STORAGE_QUALIFIER_BITS-1 downto 0) := (others => '0'); --the storage qualifier condition module input source signals
		trigger_in					: in std_logic := '0';		-- The trigger-in source
		crc							: in std_logic_vector (SLD_NODE_CRC_BITS-1 downto 0) := (others => '0');	-- The incremental CRC data input
		storage_enable				: in std_logic := '0';		-- Storage Qualifier control when in PORT mode
		raw_tck						: in std_logic := '0';		-- Real TCK from the JTAG HUB.
		tdi							: in std_logic := '0';		-- TDI from the JTAG HUB.  It gets the data from JTAG TDI.
		usr1						: in std_logic := '0';		-- USR1 from the JTAG HUB.  Indicate whether it is in USER1 or USER0
		rti							: in std_logic := '0';		-- RTI from the JTAG HUB.  Indicate whether it is in run-test-idle state.
		shift						: in std_logic := '0';		-- SHIFT from the JTAG HUB.  Indicate whether it is in shift state.
		update						: in std_logic := '0';		-- UPDATE from the JTAG HUB.  Indicate whether it is in update state.
		jtag_state_cdr				: in std_logic := '0';		-- CDR from the JTAG HUB.  Indicate whether it is in Capture_DR state.
		jtag_state_sdr				: in std_logic := '0';		-- SDR from the JTAG HUB.  Indicate whether it is in Shift_DR state.
		jtag_state_e1dr				: in std_logic := '0';		-- EDR from the JTAG HUB.  Indicate whether it is in Exit1_DR state.
		jtag_state_udr				: in std_logic := '0';		-- UDR from the JTAG HUB.  Indicate whether it is in Update_DR state.
		jtag_state_uir				: in std_logic := '0';		-- UIR from the JTAG HUB.  Indicate whether it is in Update_IR state.
		clr							: in std_logic := '0';		-- CLR from the JTAG HUB.  Indicate whether hub request global reset.
		ena							: in std_logic := '0';		-- ENA from the JTAG HUB.  Indicate whether this node should establish JTAG chain.
		ir_in						: in std_logic_vector (SLD_IR_BITS-1 downto 0) := (others => '0');	-- IR_OUT from the JTAG HUB.  It hold the current instruction for the node.
		
		ir_out						: out std_logic_vector (SLD_IR_BITS-1 downto 0);	-- IR_IN to the JTAG HUB.  It supplies the updated value for IR_IN.
		tdo							: out std_logic;	-- TDO to the JTAG HUB.  It supplies the data to JTAG TDO.

		acq_data_out				: out std_logic_vector (SLD_DATA_BITS-1 downto 0);	-- SHIFT to the JTAG HUB.  Indicate whether it is in shift state.
		acq_trigger_out				: out std_logic_vector (SLD_TRIGGER_BITS-1 downto 0);	-- SHIFT to the JTAG HUB.  Indicate whether it is in shift state.
		trigger_out					: out std_logic 	-- Indicating when a match occurred.	-- SHIFT from the JTAG HUB.  Indicate whether it is in shift state.
	);

end entity sld_signaltap;

architecture rtl of sld_signaltap is

	--
	-- Constant Definitions:
	--
	
	
	constant IP_MAJOR_VERSION			: natural := SLD_IP_VERSION;
	constant IP_MINOR_VERSION			: natural := SLD_IP_MINOR_VERSION;
	constant COMMON_IP_VERSION			: natural := SLD_COMMON_IP_VERSION;
	
	
	component sld_signaltap_impl is
		generic 
		(


		-- Auto generated version definition begin
		SLD_IP_VERSION					: natural := 6;
		SLD_IP_MINOR_VERSION				: natural := 0;
		SLD_COMMON_IP_VERSION				: natural := 0;
		-- Auto generated version definition end

			
			-- ELA Input Width Parameters
			SLD_DATA_BITS				: natural := 8;		-- The ELA data input width in bits
			SLD_TRIGGER_BITS			: natural := 8;		-- The ELA trigger input width in bits
			
			-- Consistency Check Parameters
			SLD_NODE_CRC_BITS			: natural := 32;
			SLD_NODE_CRC_HIWORD			: natural := 41394;	-- High byte of the CRC word
			SLD_NODE_CRC_LOWORD			: natural := 50132;	-- Low byte of the CRC word
			SLD_INCREMENTAL_ROUTING		: natural := 0;		-- Indicate whether incremental CRC register is used

			-- Acquisition Buffer Parameters
			SLD_SAMPLE_DEPTH			: natural := 128;	-- Memory buffer size
			SLD_SEGMENT_SIZE			: natural := 0;	-- Segment Size
			SLD_RAM_BLOCK_TYPE			: string := "AUTO";	-- Memory buffer type on the device
			SLD_STATE_BITS				: natural := 4;		-- bits necessary to store state
			
			SLD_BUFFER_FULL_STOP		: natural := 0;		-- if set to 1, once last segment full auto stops acquisition
			
			
			-- Trigger Control Parameters
			SLD_TRIGGER_LEVEL			: natural := 1;		-- Number of trigger levels that will be used to stop the data acquisition
			SLD_TRIGGER_IN_ENABLED		: natural := 1;		-- Indicate whether to generate the trigger_in logic.  Generate if it is 1; not, otherwise.
			SLD_HPS_TRIGGER_IN_ENABLED	: natural := 0;		-- Indicate whether to generate the trigger_in logic from HPS.  Generate if it is 1; not, otherwise.
			SLD_HPS_TRIGGER_OUT_ENABLED	: natural := 0;		-- Indicate whether to generate the trigger_out logic driving HPS.  Generate if it is 1; not, otherwise.
			SLD_HPS_EVENT_ENABLED		: natural := 0;		-- Indicate whether to generate the event logic driving HPS.  Generate if it is 1; not, otherwise.
			SLD_HPS_EVENT_ID			: natural := 0;		-- Specifies the event line index, if event logic is created driving HPS.
		SLD_ADVANCED_TRIGGER_ENTITY	: string := "basic";	-- Comma delimited entity name for each advanced trigger level, or "basic" if level is using standard mode
			SLD_TRIGGER_LEVEL_PIPELINE	: natural := 1;		-- Length of trigger level pipeline.
			SLD_ENABLE_ADVANCED_TRIGGER	: natural := 0;		-- Indicate whether to deploy multi-level basic trigger level or advanced trigger level
			SLD_ADVANCED_TRIGGER_1		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_2		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_3		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_4		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_5		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_6		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_7		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_8		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_9		: string := "NONE";	-- advanced trigger expression
			SLD_ADVANCED_TRIGGER_10		: string := "NONE";	-- advanced trigger expression
			SLD_INVERSION_MASK_LENGTH	: integer := 1;		-- length of inversion mask
			SLD_INVERSION_MASK			: std_logic_vector := "0"; --inversion mask
			SLD_POWER_UP_TRIGGER		: natural := 0;		-- power-up trigger mode
			SLD_STATE_FLOW_MGR_ENTITY	: string := "state_flow_mgr_entity.vhd";	--name of generated entity controlling state flow
			SLD_STATE_FLOW_USE_GENERATED	: natural := 0;
			SLD_CURRENT_RESOURCE_WIDTH	: natural := 0;
			SLD_ATTRIBUTE_MEM_MODE		: string := "OFF";
			
			--Storage Qualifier Parameters
			SLD_STORAGE_QUALIFIER_BITS	: natural := 1;
			SLD_STORAGE_QUALIFIER_GAP_RECORD : natural := 0;
			SLD_STORAGE_QUALIFIER_MODE	: string := "OFF";
			SLD_STORAGE_QUALIFIER_ENABLE_ADVANCED_CONDITION : natural := 0;
			SLD_STORAGE_QUALIFIER_INVERSION_MASK_LENGTH	: natural := 0;
			SLD_STORAGE_QUALIFIER_ADVANCED_CONDITION_ENTITY	: string := "basic";
			SLD_STORAGE_QUALIFIER_PIPELINE : natural := 0
					
		); 

		port 
		(
			acq_clk						: in std_logic;		-- The acquisition clock
			acq_data_in					: in std_logic_vector (SLD_DATA_BITS-1 downto 0) := (others => '0');	-- The data input source to be acquired.
			acq_trigger_in				: in std_logic_vector (SLD_TRIGGER_BITS-1 downto 0) := (others => '0');	-- The trigger input source to be analyzed.
			acq_storage_qualifier_in	: in std_logic_vector (SLD_STORAGE_QUALIFIER_BITS-1 downto 0) := (others => '0'); --storage qualifier input to condition modules
			trigger_in					: in std_logic := '0';		-- The trigger-in source
			crc							: in std_logic_vector (SLD_NODE_CRC_BITS-1 downto 0) := (others => '0');	-- The incremental CRC data input
			storage_enable				: in std_logic := '0';		-- Storage Qualifier control signal for Port mode
			raw_tck						: in std_logic := '0';		-- Real TCK from the JTAG HUB.
			tdi							: in std_logic := '0';		-- TDI from the JTAG HUB.  It gets the data from JTAG TDI.
			usr1						: in std_logic := '0';		-- USR1 from the JTAG HUB.  Indicate whether it is in USER1 or USER0
			rti							: in std_logic := '0';		-- RTI from the JTAG HUB.  Indicate whether it is in run-test-idle state.
			shift						: in std_logic := '0';		-- SHIFT from the JTAG HUB.  Indicate whether it is in shift state.
			update						: in std_logic := '0';		-- UPDATE from the JTAG HUB.  Indicate whether it is in update state.
			jtag_state_cdr				: in std_logic := '0';		-- CDR from the JTAG HUB.  Indicate whether it is in Capture_DR state.
			jtag_state_sdr				: in std_logic := '0';		-- SDR from the JTAG HUB.  Indicate whether it is in Shift_DR state.
			jtag_state_e1dr				: in std_logic := '0';		-- EDR from the JTAG HUB.  Indicate whether it is in Exit1_DR state.
			jtag_state_udr				: in std_logic := '0';		-- UDR from the JTAG HUB.  Indicate whether it is in Update_DR state.
			jtag_state_uir				: in std_logic := '0';		-- UIR from the JTAG HUB.  Indicate whether it is in Update_IR state.
			clr							: in std_logic := '0';		-- CLR from the JTAG HUB.  Indicate whether hub request global reset.
			ena							: in std_logic := '0';		-- ENA from the JTAG HUB.  Indicate whether this node should establish JTAG chain.
			ir_in						: in std_logic_vector (SLD_IR_BITS-1 downto 0) := (others => '0');	-- IR_OUT from the JTAG HUB.  It hold the current instruction for the node.
			
			ir_out						: out std_logic_vector (SLD_IR_BITS-1 downto 0);	-- IR_IN to the JTAG HUB.  It supplies the updated value for IR_IN.
			tdo							: out std_logic;	-- TDO to the JTAG HUB.  It supplies the data to JTAG TDO.

			acq_data_out				: out std_logic_vector (SLD_DATA_BITS-1 downto 0);	-- SHIFT to the JTAG HUB.  Indicate whether it is in shift state.
			acq_trigger_out				: out std_logic_vector (SLD_TRIGGER_BITS-1 downto 0);	-- SHIFT to the JTAG HUB.  Indicate whether it is in shift state.
			trigger_out					: out std_logic 	-- Indicating when a match occurred.	-- SHIFT from the JTAG HUB.  Indicate whether it is in shift state.
		);

	end component sld_signaltap_impl;

	-- Input Fanout Limit Register --
	signal acq_data_in_reg				: std_logic_vector (SLD_DATA_BITS-1 downto 0);
	signal acq_trigger_in_reg			: std_logic_vector (SLD_TRIGGER_BITS-1 downto 0);
	signal trigger_in_reg				: std_logic;
	
begin


	-- Auto generated version assertion begin
	-- Assertion fails when version of the entity is older than the required
	assert (IP_MAJOR_VERSION <= 6 or ( IP_MAJOR_VERSION = 6 and IP_MINOR_VERSION <= 0 ))
	report "The design file sld_signaltap.vhd was released with Quartus II 32-bit software Version 13.0 and is not compatible with the current version of the Quartus II 32-bit software.  Remove the design file from your project and recompile."
	severity FAILURE;

	-- Assertion fails when version of the entity is newer than the required
	assert (IP_MAJOR_VERSION >= 6 or ( IP_MAJOR_VERSION = 6 and IP_MINOR_VERSION >= 0 ))
	report "The design file sld_signaltap.vhd is released with Quartus II 32-bit software Version 13.0. It is not compatible with the parent entity. If you generated the parent entity using the SignalTap II megawizard, then you must update the parent entity using the megawizard in the current release."
	severity FAILURE;
	-- Auto generated version definition end


	--------------------------------------------------------------
	-- Register all user signals to limit fanout of source      --
	--------------------------------------------------------------
	process(acq_clk)
	begin
		if (acq_clk'EVENT and acq_clk = '1') then
			acq_data_in_reg <= acq_data_in;
			acq_trigger_in_reg <= acq_trigger_in;
		end if;
	end process;

	gen_trigger_in_enable: 
	if (SLD_TRIGGER_IN_ENABLED = 1) generate
		process(acq_clk)
		begin
			if (acq_clk'EVENT and acq_clk = '1') then
				trigger_in_reg <= trigger_in;
			end if;
		end process;
	end generate;

	gen_trigger_in_disable: 
	if (SLD_TRIGGER_IN_ENABLED = 0) generate
		trigger_in_reg <= '0';
	end generate;
	
	sld_signaltap_body : sld_signaltap_impl
		generic map
		(
			SLD_DATA_BITS				=> SLD_DATA_BITS,
			SLD_TRIGGER_BITS			=> SLD_TRIGGER_BITS,
			SLD_NODE_CRC_BITS			=> SLD_NODE_CRC_BITS,
			SLD_NODE_CRC_HIWORD			=> SLD_NODE_CRC_HIWORD,
			SLD_NODE_CRC_LOWORD			=> SLD_NODE_CRC_LOWORD,
			SLD_INCREMENTAL_ROUTING		=> SLD_INCREMENTAL_ROUTING,
			SLD_SAMPLE_DEPTH			=> SLD_SAMPLE_DEPTH,
			SLD_SEGMENT_SIZE			=> SLD_SEGMENT_SIZE,
			SLD_RAM_BLOCK_TYPE			=> SLD_RAM_BLOCK_TYPE,
			SLD_TRIGGER_LEVEL			=> SLD_TRIGGER_LEVEL,
			SLD_TRIGGER_IN_ENABLED		=> SLD_TRIGGER_IN_ENABLED,
			SLD_HPS_TRIGGER_IN_ENABLED	=> SLD_HPS_TRIGGER_IN_ENABLED,
			SLD_HPS_TRIGGER_OUT_ENABLED	=> SLD_HPS_TRIGGER_OUT_ENABLED,
			SLD_HPS_EVENT_ENABLED		=> SLD_HPS_EVENT_ENABLED,
			SLD_HPS_EVENT_ID			=> SLD_HPS_EVENT_ID,
			SLD_ADVANCED_TRIGGER_ENTITY	=> SLD_ADVANCED_TRIGGER_ENTITY,
			SLD_TRIGGER_LEVEL_PIPELINE	=> SLD_TRIGGER_LEVEL_PIPELINE,
			SLD_ENABLE_ADVANCED_TRIGGER	=> SLD_ENABLE_ADVANCED_TRIGGER,
			SLD_ADVANCED_TRIGGER_1		=> SLD_ADVANCED_TRIGGER_1,
			SLD_ADVANCED_TRIGGER_2		=> SLD_ADVANCED_TRIGGER_2,
			SLD_ADVANCED_TRIGGER_3		=> SLD_ADVANCED_TRIGGER_3,
			SLD_ADVANCED_TRIGGER_4		=> SLD_ADVANCED_TRIGGER_4,
			SLD_ADVANCED_TRIGGER_5		=> SLD_ADVANCED_TRIGGER_5,
			SLD_ADVANCED_TRIGGER_6		=> SLD_ADVANCED_TRIGGER_6,
			SLD_ADVANCED_TRIGGER_7		=> SLD_ADVANCED_TRIGGER_7,
			SLD_ADVANCED_TRIGGER_8		=> SLD_ADVANCED_TRIGGER_8,
			SLD_ADVANCED_TRIGGER_9		=> SLD_ADVANCED_TRIGGER_9,
			SLD_ADVANCED_TRIGGER_10		=> SLD_ADVANCED_TRIGGER_10,
			SLD_INVERSION_MASK_LENGTH	=> SLD_INVERSION_MASK_LENGTH,
			SLD_INVERSION_MASK			=> SLD_INVERSION_MASK,
			SLD_POWER_UP_TRIGGER		=> SLD_POWER_UP_TRIGGER,
			SLD_STATE_BITS				=> SLD_STATE_BITS,
			SLD_STATE_FLOW_MGR_ENTITY	=> SLD_STATE_FLOW_MGR_ENTITY,
			SLD_STATE_FLOW_USE_GENERATED	=> SLD_STATE_FLOW_USE_GENERATED,
			SLD_BUFFER_FULL_STOP		=> SLD_BUFFER_FULL_STOP,
			SLD_CURRENT_RESOURCE_WIDTH	=> SLD_CURRENT_RESOURCE_WIDTH,
			SLD_ATTRIBUTE_MEM_MODE		=> SLD_ATTRIBUTE_MEM_MODE,
			SLD_STORAGE_QUALIFIER_BITS	=> SLD_STORAGE_QUALIFIER_BITS,
			SLD_STORAGE_QUALIFIER_GAP_RECORD	=> SLD_STORAGE_QUALIFIER_GAP_RECORD,
			SLD_STORAGE_QUALIFIER_MODE	=> SLD_STORAGE_QUALIFIER_MODE,
			SLD_STORAGE_QUALIFIER_ENABLE_ADVANCED_CONDITION => SLD_STORAGE_QUALIFIER_ENABLE_ADVANCED_CONDITION,
			SLD_STORAGE_QUALIFIER_INVERSION_MASK_LENGTH	=> SLD_STORAGE_QUALIFIER_INVERSION_MASK_LENGTH,
			SLD_STORAGE_QUALIFIER_ADVANCED_CONDITION_ENTITY => SLD_STORAGE_QUALIFIER_ADVANCED_CONDITION_ENTITY,
			SLD_STORAGE_QUALIFIER_PIPELINE	=> SLD_STORAGE_QUALIFIER_PIPELINE
		)
		port map
		(
			acq_clk						=> acq_clk,
			acq_data_in					=> acq_data_in_reg,
			acq_trigger_in				=> acq_trigger_in_reg,
			acq_storage_qualifier_in	=> acq_storage_qualifier_in,
			storage_enable				=> storage_enable,
			trigger_in					=> trigger_in_reg,
			crc							=> crc,
			raw_tck						=> raw_tck,
			tdi							=> tdi,
			usr1						=> usr1,
			rti							=> rti,
			shift						=> shift,
			update						=> update,
			jtag_state_cdr				=> jtag_state_cdr,
			jtag_state_sdr				=> jtag_state_sdr,
			jtag_state_e1dr				=> jtag_state_e1dr,
			jtag_state_udr				=> jtag_state_udr,
			jtag_state_uir				=> jtag_state_uir,
			clr							=> clr,
			ena							=> ena,
			ir_in						=> ir_in,
			ir_out						=> ir_out,
			tdo							=> tdo,
			acq_data_out				=> acq_data_out,
			acq_trigger_out				=> acq_trigger_out,
			trigger_out					=> trigger_out
		);

end architecture rtl;



