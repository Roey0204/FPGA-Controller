--------------------------------------------------------------------
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

-- START_FILE_HEADER --------------------------------------------------
--
-- Filename    : altera_fabric_endpoint.vhd
--
-- Description : This component passes information to Quartus so that it
--               can be automatically connected to other debug fabric
--               endpoints 
-- 
-- Authors     : adraper
--
-- Copyright (c) Altera Corporation 2012
-- All rights reserved
--
-- END_FILE_HEADER --------------------------------------------------

-- LIBRARY USED-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

---START_ENTITY_HEADER-------------------------------------------------
--
-- Entity Name     : altera_fabric_endpoint
--
-- Description     : An endpoint which can be connected by quartus
--
-- Results Expected: None
--
-- Authors         : adraper
--
---END_ENTITY_HEADER-------------------------------------------------

entity altera_fabric_endpoint is
	generic
	(
		SLD_NODE_INFO            : natural := 0;
		SLD_ENDPOINT_TYPE        : natural := 0;
		SEND_WIDTH               : natural := 4;
		RECEIVE_WIDTH            : natural := 4;
		SETTINGS                 : string := ""
	);
	port
	(
		send           : in std_logic_vector(SEND_WIDTH - 1 downto 0);  -- Sent from node
		receive        : out std_logic_vector(RECEIVE_WIDTH - 1 downto 0) := (others => '0'); -- Received by node

		-- These signals are for connection by Quartus, do not manually connect
		fabric_send    : out std_logic_vector(SEND_WIDTH - 1 downto 0);
		fabric_receive : in std_logic_vector(RECEIVE_WIDTH - 1 downto 0) := (others => '0')
    );
end altera_fabric_endpoint;

architecture rtl of altera_fabric_endpoint is

begin

	assert( SLD_NODE_INFO = 0 )
	report "Do not overwrite the value of SLD_NODE_INFO, which must be 0."
	severity FAILURE;

	fabric_send <= send;
	receive <= fabric_receive;
end rtl;

