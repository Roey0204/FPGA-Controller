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
-- Filename    : altera_connection_identification_rom.vhd
--
-- Description : This component behaves like a combinational rom which describes
--               the design so that a debugger can match a device to the design
-- 
-- Limitation  : This component will not be functional until Quartus synthesis
--               has connected it up.
--
-- Copyright (c) Altera Corporation 2012
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

package altera_connection_identification_rom_package is

	function log2 (value : in natural) return natural;

	function nonzero (value : in natural) return natural;

	function ifcond (cond : in boolean; value : in natural) return natural;

end package altera_connection_identification_rom_package;

package body altera_connection_identification_rom_package is

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

end package body altera_connection_identification_rom_package;

-- LIBRARY USED-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.altera_connection_identification_rom_package.all;

---START_ENTITY_HEADER-------------------------------------------------
--
-- Entity Name     : altera_connection_identification_rom
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

entity altera_connection_identification_rom is
	generic
	(
        WIDTH     : natural := 8;
        LATENCY   : natural := 0
	);

	port
	(
		-- Signals to be connected up by the user
        clk       : in  std_logic := '0';
        writedata : in  std_logic_vector(4-1 downto 0);
        address   : in  std_logic_vector(7 - log2(WIDTH)-1 downto 0);
        readdata  : out std_logic_vector(WIDTH-1 downto 0)
    );

end altera_connection_identification_rom;

architecture rtl of altera_connection_identification_rom is

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

    constant CLK_BASE       : natural := 0;
    constant WRITEDATA_BASE : natural := CLK_BASE + ifcond(LATENCY > 0, 1);
    constant ADDRESS_BASE   : natural := WRITEDATA_BASE + 4;
    constant READDATA_BASE  : natural := 0;
    constant SEND_WIDTH    : natural := ADDRESS_BASE + 7 - log2(WIDTH);
    constant RECEIVE_WIDTH : natural := READDATA_BASE + WIDTH;

    constant SETTINGS      : string := "{fabric ident width " & integer'image(WIDTH) & 
                " latency " & integer'image(LATENCY) & "}";

	signal send : std_logic_vector(SEND_WIDTH-1 downto 0);
	signal receive : std_logic_vector(RECEIVE_WIDTH-1 downto 0);

begin
    width_check: if not (WIDTH = 4 or WIDTH = 8 or WIDTH = 16 or WIDTH = 32) generate
        assert false report "WIDTH must be 4, 8, 16 or 32" severity Failure;
    end generate;

    latency_check: if not ((LATENCY >= 0 and LATENCY <= 1)) generate
        assert false report "LATENCY must be 0 or 1" severity Failure;
    end generate;


present_s1: if LATENCY > 0 generate
    send(CLK_BASE) <= clk;
end generate;
    send(WRITEDATA_BASE + 4 - 1 downto WRITEDATA_BASE) <= writedata;
    send(ADDRESS_BASE + nonzero(7 - log2(WIDTH)) - 1 downto ADDRESS_BASE) <= address;

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

    readdata <= receive(READDATA_BASE + WIDTH - 1 downto READDATA_BASE);

end rtl;

