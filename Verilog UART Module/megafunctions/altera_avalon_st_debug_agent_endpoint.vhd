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
--------------------------------------------------------------------

-- START_FILE_HEADER --------------------------------------------------
--
-- Filename    : altera_avalon_st_debug_agent_endpoint.vhd
--
-- Description : 
-- 
-- Limitation  : This component will not be functional until Quartus synthesis
--               has connected it up.
--
-- Copyright (c) Altera Corporation 2013
-- All rights reserved
--
-- END_FILE_HEADER --------------------------------------------------

---START_PACKAGE_HEADER-------------------------------------------------
--
-- Package Name    :  
--
-- Description     :  
--
-- Authors         :  
--
---END_PACKAGE_HEADER-------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package altera_avalon_st_debug_agent_endpoint_package is

	function log2 (value : in natural) return natural;

	function nonzero (value : in natural) return natural;

	function ifcond (cond : in boolean; value : in natural) return natural;

end package altera_avalon_st_debug_agent_endpoint_package;

package body altera_avalon_st_debug_agent_endpoint_package is

	function log2 (value : in natural) return natural is
		variable value_int : natural := 0;
		variable ret       : natural := 0;
	begin
		value_int := value - 1;
		ret := 0;
		bit_shift_loop:
		while (value_int > 0) loop
			value_int := value_int / 2;
			ret := ret + 1;
		end loop;
		if (ret = 0) then
			ret := 1;
		end if;
		return ret;
	end function log2;

	function nonzero (value : in natural) return natural is
	begin
		if (value = 0) then
			return 1;
		end if;
		return value;
	end function nonzero;

	function ifcond (cond : in boolean; value : in natural) return natural is
	begin
		if (not cond) then
			return 0;
		end if;
		return value;
	end function ifcond;

end package body altera_avalon_st_debug_agent_endpoint_package;

-- LIBRARY USED-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.altera_avalon_st_debug_agent_endpoint_package.all;

---START_ENTITY_HEADER-------------------------------------------------
--
-- Entity Name     : altera_avalon_st_debug_agent_endpoint
--
-- Description     : 
--
-- Limitation      : The implementation uses Quartus magic to connect it
--                   to an actual component in a different partition which
--                   does the real work.
--
-- Results Expected: None
--
---END_ENTITY_HEADER-------------------------------------------------

entity altera_avalon_st_debug_agent_endpoint is
	generic
	(
        DATA_WIDTH        : natural := 8;
        CHANNEL_WIDTH     : natural := 0;
        HAS_MGMT          : natural := 0;
        READY_LATENCY     : natural := 0;
        MFR_CODE          : natural := 0;
        TYPE_CODE         : natural := 0;
        PREFER_HOST       : string  := ""
	);

	port
	(
		-- Signals to be connected up by the user
        clk               : in  std_logic;
        reset             : out std_logic;
        h2t_ready         : in  std_logic;
        h2t_valid         : out std_logic;
        h2t_data          : out std_logic_vector(DATA_WIDTH-1 downto 0);
        h2t_startofpacket : out std_logic;
        h2t_endofpacket   : out std_logic;
        h2t_channel       : out std_logic_vector(nonzero(CHANNEL_WIDTH)-1 downto 0);
        t2h_ready         : out std_logic;
        t2h_valid         : in  std_logic;
        t2h_data          : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        t2h_startofpacket : in  std_logic;
        t2h_endofpacket   : in  std_logic;
        t2h_channel       : in  std_logic_vector(nonzero(CHANNEL_WIDTH)-1 downto 0) := conv_std_logic_vector(0, nonzero(CHANNEL_WIDTH));
        mgmt_valid        : out std_logic;
        mgmt_data         : out std_logic;
        mgmt_channel      : out std_logic_vector(nonzero(CHANNEL_WIDTH)-1 downto 0)
    );

end altera_avalon_st_debug_agent_endpoint;

architecture rtl of altera_avalon_st_debug_agent_endpoint is

	component altera_fabric_endpoint is
		generic
		(
			SLD_ENDPOINT_TYPE        : natural := 0;
			SEND_WIDTH               : natural := 4;
			RECEIVE_WIDTH            : natural := 4;
			SETTINGS                 : string := ""
		);
		port
		(
			send           : in std_logic_vector(SEND_WIDTH - 1 downto 0);  -- Sent from endpoint
			receive        : out std_logic_vector(RECEIVE_WIDTH - 1 downto 0) := (others => '0') -- Received by endpoint
	    );
	end component altera_fabric_endpoint;

    constant CLK_BASE               : natural := 0;
    constant RESET_BASE             : natural := 0;
    constant H2T_READY_BASE         : natural := CLK_BASE + 1;
    constant H2T_VALID_BASE         : natural := RESET_BASE + 1;
    constant H2T_DATA_BASE          : natural := H2T_VALID_BASE + 1;
    constant H2T_STARTOFPACKET_BASE : natural := H2T_DATA_BASE + DATA_WIDTH;
    constant H2T_ENDOFPACKET_BASE   : natural := H2T_STARTOFPACKET_BASE + 1;
    constant H2T_CHANNEL_BASE       : natural := H2T_ENDOFPACKET_BASE + 1;
    constant T2H_READY_BASE         : natural := H2T_CHANNEL_BASE + ifcond(CHANNEL_WIDTH > 0, CHANNEL_WIDTH);
    constant T2H_VALID_BASE         : natural := H2T_READY_BASE + 1;
    constant T2H_DATA_BASE          : natural := T2H_VALID_BASE + 1;
    constant T2H_STARTOFPACKET_BASE : natural := T2H_DATA_BASE + DATA_WIDTH;
    constant T2H_ENDOFPACKET_BASE   : natural := T2H_STARTOFPACKET_BASE + 1;
    constant T2H_CHANNEL_BASE       : natural := T2H_ENDOFPACKET_BASE + 1;
    constant MGMT_VALID_BASE        : natural := T2H_READY_BASE + 1;
    constant MGMT_DATA_BASE         : natural := MGMT_VALID_BASE + ifcond(CHANNEL_WIDTH > 0 and HAS_MGMT /= 0, 1);
    constant MGMT_CHANNEL_BASE      : natural := MGMT_DATA_BASE + ifcond(CHANNEL_WIDTH > 0 and HAS_MGMT /= 0, 1);
    constant SEND_WIDTH    : natural := T2H_CHANNEL_BASE + ifcond(CHANNEL_WIDTH > 0, CHANNEL_WIDTH);
    constant RECEIVE_WIDTH : natural := MGMT_CHANNEL_BASE + ifcond(CHANNEL_WIDTH > 0 and HAS_MGMT /= 0, CHANNEL_WIDTH);

    constant SETTINGS      : string := "{fabric stream dir agent data_width " & integer'image(DATA_WIDTH) & 
                " channel_width " & integer'image(CHANNEL_WIDTH) & " has_mgmt " & integer'image(HAS_MGMT) & 
                " ready_latency " & integer'image(READY_LATENCY) & " mfr_code " & integer'image(MFR_CODE) & 
                " type_code " & integer'image(TYPE_CODE) & " prefer_host {" & PREFER_HOST & "} }";

	signal send : std_logic_vector(SEND_WIDTH-1 downto 0);
	signal receive : std_logic_vector(RECEIVE_WIDTH-1 downto 0);

begin
    data_width_check: if not (DATA_WIDTH = 8) generate
        assert false report "DATA_WIDTH must be 8" severity Failure;
    end generate;

    channel_width_check: if not ((CHANNEL_WIDTH >= 0 and CHANNEL_WIDTH <= 32)) generate
        assert false report "CHANNEL_WIDTH must be between 0 and 32" severity Failure;
    end generate;

    has_mgmt_check: if not (HAS_MGMT = 0) generate
        assert false report "HAS_MGMT must be 0" severity Failure;
    end generate;

    ready_latency_check: if not ((READY_LATENCY >= 0 and READY_LATENCY <= 7)) generate
        assert false report "READY_LATENCY must be between 0 and 7" severity Failure;
    end generate;

    assert_1: if not (HAS_MGMT = 0 or CHANNEL_WIDTH > 0) generate
        assert false report "CHANNEL_WIDTH must be >0 for agents with a management interface" severity Failure;
    end generate;

    send(CLK_BASE) <= clk;
    send(H2T_READY_BASE) <= h2t_ready;
    send(T2H_VALID_BASE) <= t2h_valid;
    send(T2H_DATA_BASE + DATA_WIDTH - 1 downto T2H_DATA_BASE) <= t2h_data;
    send(T2H_STARTOFPACKET_BASE) <= t2h_startofpacket;
    send(T2H_ENDOFPACKET_BASE) <= t2h_endofpacket;

present_s1: if CHANNEL_WIDTH > 0 generate
    send(T2H_CHANNEL_BASE + nonzero(CHANNEL_WIDTH) - 1 downto T2H_CHANNEL_BASE) <= t2h_channel;
end generate;

	ep : altera_fabric_endpoint
		generic map
		(
			SLD_ENDPOINT_TYPE => 0,
			SEND_WIDTH => SEND_WIDTH,
			RECEIVE_WIDTH => RECEIVE_WIDTH,
			SETTINGS => SETTINGS
		)
		port map
		(
			send      => send,
			receive   => receive
		);

    reset <= receive(RESET_BASE);
    h2t_valid <= receive(H2T_VALID_BASE);
    h2t_data <= receive(H2T_DATA_BASE + DATA_WIDTH - 1 downto H2T_DATA_BASE);
    h2t_startofpacket <= receive(H2T_STARTOFPACKET_BASE);
    h2t_endofpacket <= receive(H2T_ENDOFPACKET_BASE);
    t2h_ready <= receive(T2H_READY_BASE);

present_r1: if CHANNEL_WIDTH > 0 generate
    h2t_channel <= receive(H2T_CHANNEL_BASE + nonzero(CHANNEL_WIDTH) - 1 downto H2T_CHANNEL_BASE);
end generate;
absent_r2: if not (CHANNEL_WIDTH > 0) generate
    h2t_channel <= conv_std_logic_vector(0, nonzero(CHANNEL_WIDTH));
end generate;

present_r3: if CHANNEL_WIDTH > 0 and HAS_MGMT /= 0 generate
    mgmt_valid <= receive(MGMT_VALID_BASE);
    mgmt_data <= receive(MGMT_DATA_BASE);
    mgmt_channel <= receive(MGMT_CHANNEL_BASE + nonzero(CHANNEL_WIDTH) - 1 downto MGMT_CHANNEL_BASE);
end generate;
absent_r4: if not (CHANNEL_WIDTH > 0 and HAS_MGMT /= 0) generate
    mgmt_valid <= '0';
    mgmt_data <= '0';
    mgmt_channel <= conv_std_logic_vector(0, nonzero(CHANNEL_WIDTH));
end generate;

end rtl;

