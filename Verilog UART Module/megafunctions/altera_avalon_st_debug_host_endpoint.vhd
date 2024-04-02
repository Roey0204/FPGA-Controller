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
-- Filename    : altera_avalon_st_debug_host_endpoint.vhd
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

package altera_avalon_st_debug_host_endpoint_package is

	function log2 (value : in natural) return natural;

	function nonzero (value : in natural) return natural;

	function ifcond (cond : in boolean; value : in natural) return natural;

end package altera_avalon_st_debug_host_endpoint_package;

package body altera_avalon_st_debug_host_endpoint_package is

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

end package body altera_avalon_st_debug_host_endpoint_package;

-- LIBRARY USED-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.altera_avalon_st_debug_host_endpoint_package.all;

---START_ENTITY_HEADER-------------------------------------------------
--
-- Entity Name     : altera_avalon_st_debug_host_endpoint
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

entity altera_avalon_st_debug_host_endpoint is
	generic
	(
        DATA_WIDTH           : natural := 8;
        CHANNEL_WIDTH        : natural := 8;
        NAME                 : string  := "";
        PRIORITY             : natural := 100
	);

	port
	(
		-- Signals to be connected up by the user
        clk                  : in  std_logic;
        reset                : in  std_logic;
        h2t_ready            : out std_logic;
        h2t_valid            : in  std_logic;
        h2t_data             : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        h2t_startofpacket    : in  std_logic;
        h2t_endofpacket      : in  std_logic;
        h2t_channel          : in  std_logic_vector(CHANNEL_WIDTH-1 downto 0);
        t2h_ready            : in  std_logic;
        t2h_valid            : out std_logic;
        t2h_data             : out std_logic_vector(DATA_WIDTH-1 downto 0);
        t2h_startofpacket    : out std_logic;
        t2h_endofpacket      : out std_logic;
        t2h_channel          : out std_logic_vector(CHANNEL_WIDTH-1 downto 0);
        mgmt_valid           : in  std_logic;
        mgmt_data            : in  std_logic;
        mgmt_channel         : in  std_logic_vector(CHANNEL_WIDTH-1 downto 0)
    );

end altera_avalon_st_debug_host_endpoint;

architecture rtl of altera_avalon_st_debug_host_endpoint is

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

    constant CLK_BASE                  : natural := 0;
    constant RESET_BASE                : natural := CLK_BASE + 1;
    constant H2T_READY_BASE            : natural := 0;
    constant H2T_VALID_BASE            : natural := RESET_BASE + 1;
    constant H2T_DATA_BASE             : natural := H2T_VALID_BASE + 1;
    constant H2T_STARTOFPACKET_BASE    : natural := H2T_DATA_BASE + DATA_WIDTH;
    constant H2T_ENDOFPACKET_BASE      : natural := H2T_STARTOFPACKET_BASE + 1;
    constant H2T_CHANNEL_BASE          : natural := H2T_ENDOFPACKET_BASE + 1;
    constant T2H_READY_BASE            : natural := H2T_CHANNEL_BASE + CHANNEL_WIDTH;
    constant T2H_VALID_BASE            : natural := H2T_READY_BASE + 1;
    constant T2H_DATA_BASE             : natural := T2H_VALID_BASE + 1;
    constant T2H_STARTOFPACKET_BASE    : natural := T2H_DATA_BASE + DATA_WIDTH;
    constant T2H_ENDOFPACKET_BASE      : natural := T2H_STARTOFPACKET_BASE + 1;
    constant T2H_CHANNEL_BASE          : natural := T2H_ENDOFPACKET_BASE + 1;
    constant MGMT_VALID_BASE           : natural := T2H_READY_BASE + 1;
    constant MGMT_DATA_BASE            : natural := MGMT_VALID_BASE + 1;
    constant MGMT_CHANNEL_BASE         : natural := MGMT_DATA_BASE + 1;
    constant SEND_WIDTH    : natural := MGMT_CHANNEL_BASE + CHANNEL_WIDTH;
    constant RECEIVE_WIDTH : natural := T2H_CHANNEL_BASE + CHANNEL_WIDTH;

    constant SETTINGS      : string := "{fabric stream dir host data_width " & integer'image(DATA_WIDTH) & 
                " channel_width " & integer'image(CHANNEL_WIDTH) & " name {" & NAME & 
                "}  priority " & integer'image(PRIORITY) & "}";

	signal send : std_logic_vector(SEND_WIDTH-1 downto 0);
	signal receive : std_logic_vector(RECEIVE_WIDTH-1 downto 0);

begin
    data_width_check: if not (DATA_WIDTH = 8) generate
        assert false report "DATA_WIDTH must be 8" severity Failure;
    end generate;

    channel_width_check: if not ((CHANNEL_WIDTH >= 2 and CHANNEL_WIDTH <= 32)) generate
        assert false report "CHANNEL_WIDTH must be between 2 and 32" severity Failure;
    end generate;

    assert_1: if not (NAME /= "") generate
        assert false report "NAME must be specified" severity Failure;
    end generate;

    send(CLK_BASE) <= clk;
    send(RESET_BASE) <= reset;
    send(H2T_VALID_BASE) <= h2t_valid;
    send(H2T_DATA_BASE + DATA_WIDTH - 1 downto H2T_DATA_BASE) <= h2t_data;
    send(H2T_STARTOFPACKET_BASE) <= h2t_startofpacket;
    send(H2T_ENDOFPACKET_BASE) <= h2t_endofpacket;
    send(H2T_CHANNEL_BASE + CHANNEL_WIDTH - 1 downto H2T_CHANNEL_BASE) <= h2t_channel;
    send(T2H_READY_BASE) <= t2h_ready;
    send(MGMT_VALID_BASE) <= mgmt_valid;
    send(MGMT_DATA_BASE) <= mgmt_data;
    send(MGMT_CHANNEL_BASE + CHANNEL_WIDTH - 1 downto MGMT_CHANNEL_BASE) <= mgmt_channel;

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

    h2t_ready <= receive(H2T_READY_BASE);
    t2h_valid <= receive(T2H_VALID_BASE);
    t2h_data <= receive(T2H_DATA_BASE + DATA_WIDTH - 1 downto T2H_DATA_BASE);
    t2h_startofpacket <= receive(T2H_STARTOFPACKET_BASE);
    t2h_endofpacket <= receive(T2H_ENDOFPACKET_BASE);
    t2h_channel <= receive(T2H_CHANNEL_BASE + CHANNEL_WIDTH - 1 downto T2H_CHANNEL_BASE);

end rtl;

