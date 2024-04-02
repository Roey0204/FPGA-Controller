-- altera message_off 10036
-- altera message_off 10541
---------------- SFL -----------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;

entity altserial_flash_loader is
	generic
	(
		intended_device_family	: STRING := "Cyclone";
		enable_shared_access	: STRING := "OFF";
		enhanced_mode			: natural := 0;
		enable_quad_spi_support : natural :=0;
		lpm_type				: STRING := "ALTSERIAL_FLASH_LOADER"
	);
	port
	(
		scein					: IN STD_LOGIC := '0';
		dclkin					: IN STD_LOGIC := '0';
		sdoin					: IN STD_LOGIC := '0';
		noe						: IN STD_LOGIC := '0';
		asmi_access_granted		: IN std_logic := '1';
		data0out				: OUT STD_LOGIC;
		asmi_access_request		: OUT std_logic;
		
		-- this is for Quad SPI (EPCQ) support
		data_in					: IN STD_LOGIC_VECTOR (3 DOWNTO 0) := (others=>'0');
		data_oe					: IN STD_LOGIC_VECTOR (3 DOWNTO 0) := (others=>'0');
		data_out				: OUT STD_LOGIC_VECTOR (3 downto 0)
	);
end entity altserial_flash_loader;

architecture rtl of altserial_flash_loader is
	component alt_sfl
	port
	(
		-- ASMI IOs
		dclkin				: OUT STD_LOGIC ;
		scein               : OUT STD_LOGIC ;
		sdoin               : OUT STD_LOGIC ;
		asmi_access_request : OUT STD_LOGIC;
		data0out            : IN STD_LOGIC;
		asmi_access_granted : IN STD_LOGIC
	);
	end component;

	component alt_sfl_enhanced
	GENERIC
	(
		QUAD_SPI_SUPPORT : NATURAL := 0
	);
	port
	(
		-- ASMI IOs
		dclkin					: OUT STD_LOGIC ;
		scein					: OUT STD_LOGIC ;
		sdoin					: OUT STD_LOGIC ;
		data1in					: OUT STD_LOGIC ;
		data2in					: OUT STD_LOGIC ;
		data3in					: OUT STD_LOGIC ;
		
		data0oe					: OUT STD_LOGIC ;
		data1oe					: OUT STD_LOGIC ;
		data2oe					: OUT STD_LOGIC ;
		data3oe					: OUT STD_LOGIC ;
		
		asmi_access_request		: OUT STD_LOGIC;
		data0out				: IN STD_LOGIC;
		data1out				: IN STD_LOGIC;
		data2out				: IN STD_LOGIC;
		data3out				: IN STD_LOGIC;
		asmi_access_granted		: IN STD_LOGIC
	);
	end component;

	COMPONENT cyclone_asmiblock 
	port
	(
		dclkin   : in STD_LOGIC;
		scein    : in STD_LOGIC;
		sdoin    : in STD_LOGIC;
		data0out : out STD_LOGIC;
		oe       : in STD_LOGIC
	);
	END COMPONENT;

	COMPONENT cycloneii_asmiblock 
	port
	(
		dclkin   : in STD_LOGIC;
		scein    : in STD_LOGIC;
		sdoin    : in STD_LOGIC;
		data0out : out STD_LOGIC;
		oe       : in STD_LOGIC
	);
	END COMPONENT;

	COMPONENT stratixii_asmiblock 
	port
	(
		dclkin   : in STD_LOGIC;
		scein    : in STD_LOGIC;
		sdoin    : in STD_LOGIC;
		data0out : out STD_LOGIC;
		oe       : in STD_LOGIC
	);
	END COMPONENT;

	COMPONENT stratixiii_asmiblock 
	port
	(
		dclkin   : in STD_LOGIC;
		scein    : in STD_LOGIC;
		sdoin    : in STD_LOGIC;
		data0out : out STD_LOGIC;
		oe       : in STD_LOGIC
	);
	END COMPONENT;

	COMPONENT stratixiv_asmiblock 
	port
	(
		dclkin   : in STD_LOGIC;
		scein    : in STD_LOGIC;
		sdoin    : in STD_LOGIC;
		data0out : out STD_LOGIC;
		oe       : in STD_LOGIC
	);
	END COMPONENT;
	
	COMPONENT stratixv_asmiblock 
	port
	(
		dclk     : in STD_LOGIC;
		sce      : in STD_LOGIC;
		oe       : in STD_LOGIC;
		
		data0out : in STD_LOGIC;
		data1out : in STD_LOGIC;
		data2out : in STD_LOGIC;
		data3out : in STD_LOGIC;
		
		data0oe  : in STD_LOGIC;
		data1oe  : in STD_LOGIC;
		data2oe  : in STD_LOGIC;
		data3oe  : in STD_LOGIC;
		
		data0in  : out STD_LOGIC;
		data1in  : out STD_LOGIC;
		data2in  : out STD_LOGIC;
		data3in  : out STD_LOGIC
	);
	END COMPONENT;
	
	COMPONENT arriav_asmiblock 
	port
	(
		dclk     : in STD_LOGIC;
		sce      : in STD_LOGIC;
		oe       : in STD_LOGIC;
		
		data0out : in STD_LOGIC;
		data1out : in STD_LOGIC;
		data2out : in STD_LOGIC;
		data3out : in STD_LOGIC;
		
		data0oe  : in STD_LOGIC;
		data1oe  : in STD_LOGIC;
		data2oe  : in STD_LOGIC;
		data3oe  : in STD_LOGIC;
		
		data0in  : out STD_LOGIC;
		data1in  : out STD_LOGIC;
		data2in  : out STD_LOGIC;
		data3in  : out STD_LOGIC
	);
	END COMPONENT;

	COMPONENT cyclonev_asmiblock 
	port
	(
		dclk     : in STD_LOGIC;
		sce      : in STD_LOGIC;
		oe       : in STD_LOGIC;
		
		data0out : in STD_LOGIC;
		data1out : in STD_LOGIC;
		data2out : in STD_LOGIC;
		data3out : in STD_LOGIC;
		
		data0oe  : in STD_LOGIC;
		data1oe  : in STD_LOGIC;
		data2oe  : in STD_LOGIC;
		data3oe  : in STD_LOGIC;
		
		data0in  : out STD_LOGIC;
		data1in  : out STD_LOGIC;
		data2in  : out STD_LOGIC;
		data3in  : out STD_LOGIC
	);
	END COMPONENT;

	constant ASMI_TYPE_0           : boolean :=
		(
			(intended_device_family = "Cyclone")
		);

	constant ASMI_TYPE_1           : boolean :=
		(
			(intended_device_family = "Cyclone II")
			OR
			(intended_device_family = "Cyclone III")
			OR
			(intended_device_family = "Cyclone III LS")
			OR
			(intended_device_family = "Cyclone IV E")
			OR
			(intended_device_family = "Cyclone IV GX")			
		);

	constant ASMI_TYPE_2           : boolean :=
		(
			(intended_device_family = "Stratix II")
			OR
			(intended_device_family = "Stratix II GX")
			OR
			(intended_device_family = "Arria GX")
		);

	constant ASMI_TYPE_3           : boolean :=
		(
			(intended_device_family = "Stratix III")
		);

	constant ASMI_TYPE_4           : boolean :=
		(
			(intended_device_family = "Stratix IV")
			OR
			(intended_device_family = "Arria II GX")
			OR
			(intended_device_family = "Arria II GZ")
		);
		
	constant ASMI_TYPE_5           : boolean :=
		(
			(intended_device_family = "Stratix V")
		);
		
	constant ASMI_TYPE_6           : boolean :=
		(
			(intended_device_family = "Arria V")
		);

	constant ASMI_TYPE_7           : boolean :=
		(
			(intended_device_family = "Cyclone V")
		);

	signal dclkin_int              : STD_LOGIC;
	signal sdoin_int               : STD_LOGIC;
	signal scein_int               : STD_LOGIC;
	signal noe_int                 : STD_LOGIC;
	signal data0out_int            : STD_LOGIC;

	signal dclkin_sfl              : STD_LOGIC;
	signal sdoin_sfl               : STD_LOGIC;
	signal scein_sfl               : STD_LOGIC;
	signal asmi_access_request_sfl : STD_LOGIC;
	signal asmi_access_granted_sfl : STD_LOGIC;

	signal sfl_has_access          : STD_LOGIC;
	
	-- this is for Quad SPI (or EPCQ) support
	signal data0in_int : STD_LOGIC;
	signal data1in_int : STD_LOGIC;
	signal data2in_int : STD_LOGIC;
	signal data3in_int : STD_LOGIC;
	
	signal data0oe_int : STD_LOGIC;
	signal data1oe_int : STD_LOGIC;
	signal data2oe_int : STD_LOGIC;
	signal data3oe_int : STD_LOGIC;
	
	signal data1out_int : STD_LOGIC;
	signal data2out_int : STD_LOGIC;
	signal data3out_int : STD_LOGIC;
	
	signal data1in_sfl : STD_LOGIC;
	signal data2in_sfl : STD_LOGIC;
	signal data3in_sfl : STD_LOGIC;
	
	signal data0oe_sfl : STD_LOGIC;
	signal data1oe_sfl : STD_LOGIC;
	signal data2oe_sfl : STD_LOGIC;
	signal data3oe_sfl : STD_LOGIC;
	
	signal data_from_flash : STD_LOGIC;
	
	attribute altera_attribute : string;
	attribute altera_attribute of rtl: architecture is "SUPPRESS_DA_RULE_INTERNAL=C104";

begin

	DEFAULT_PGM: if (enhanced_mode = 0) generate
	sfl_inst: alt_sfl
	port map
	(
		-- ASMI IOs
		dclkin => dclkin_sfl,
		scein => scein_sfl,
		sdoin => sdoin_sfl,
		asmi_access_request => asmi_access_request_sfl,
		data0out => data_from_flash,
		asmi_access_granted => asmi_access_granted_sfl
	);
	end generate;

	ENHANCED_PGM: if (enhanced_mode = 1 and enable_quad_spi_support = 0) generate
		sfl_inst_enhanced: alt_sfl_enhanced
		GENERIC MAP
		(
			QUAD_SPI_SUPPORT => ENABLE_QUAD_SPI_SUPPORT
		)
		port map
		(
			-- ASMI IOs
			dclkin => dclkin_sfl,
			scein => scein_sfl,
			sdoin => sdoin_sfl,
			asmi_access_request => asmi_access_request_sfl,
			data0out => '0',
			data1out => data_from_flash,
			data2out => '0',
			data3out => '0',
			asmi_access_granted => asmi_access_granted_sfl
		);
	end generate;
	
	ENHANCED_PGM_QUAD: if (enhanced_mode = 1 and enable_quad_spi_support = 1) generate
		sfl_inst_enhanced: alt_sfl_enhanced
		port map
		(
			-- ASMI IOs
			dclkin => dclkin_sfl,
			scein => scein_sfl,
			sdoin => sdoin_sfl,
			data1in => data1in_sfl,
			data2in => data2in_sfl,
			data3in => data3in_sfl,
			
			data0oe => data0oe_sfl,
			data1oe => data1oe_sfl,
			data2oe => data2oe_sfl,
			data3oe => data3oe_sfl,
			
			asmi_access_request => asmi_access_request_sfl,
			data0out => data0out_int,
			data1out => data1out_int,
			data2out => data2out_int,
			data3out => data3out_int,
			asmi_access_granted => asmi_access_granted_sfl
		);
	end generate;

	SHARED_ACCESS_OFF: if (enable_shared_access = "OFF" and enable_quad_spi_support = 0) generate
		dclkin_int <= dclkin_sfl;
		scein_int <= scein_sfl;
		sdoin_int <= sdoin_sfl;
		data0in_int <= sdoin_sfl;
		data0oe_int <= '1';
		data1oe_int <= '0';
		data2oe_int <= '1';
		data2in_int <= '1';
		data3oe_int <= '1';
		data3in_int <= '1';
		noe_int <= '0';
		asmi_access_granted_sfl <= '1';
	end generate;
	
	SHARED_ACCESS_OFF_QUAD: if (enable_shared_access = "OFF" and enable_quad_spi_support = 1) generate
		dclkin_int <= dclkin_sfl;
		scein_int <= scein_sfl;

		data0in_int <= sdoin_sfl;
		data1in_int <= data1in_sfl;
		data2in_int <= data2in_sfl;
		data3in_int <= data3in_sfl;
		
		data0oe_int <= data0oe_sfl;
		data1oe_int <= data1oe_sfl;
		data2oe_int <= data2oe_sfl;
		data3oe_int <= data3oe_sfl;
		
		noe_int <= '0';
		asmi_access_granted_sfl <= '1';
	end generate;

	SHARED_ACCESS_ON: if (enable_shared_access = "ON" and enable_quad_spi_support = 0) generate
		dclkin_int <= (sfl_has_access and dclkin_sfl) or (not sfl_has_access and dclkin);
		scein_int <= (sfl_has_access and scein_sfl) or (not sfl_has_access and scein);
		sdoin_int <= (sfl_has_access and sdoin_sfl) or (not sfl_has_access and sdoin);
		data0in_int <= (sfl_has_access and sdoin_sfl) or (not sfl_has_access and sdoin);
		data2in_int <= '1';
		data3in_int <= '1';
		data0oe_int <= '1';
		data1oe_int <= '0';
		data2oe_int <= '1';
		data3oe_int <= '1';
		noe_int <= noe;
		asmi_access_granted_sfl <= asmi_access_granted;
	end generate;
	
	SHARED_ACCESS_ON_QUAD: if (enable_shared_access = "ON" and enable_quad_spi_support = 1) generate
		dclkin_int <= (sfl_has_access and dclkin_sfl) or (not sfl_has_access and dclkin);
		scein_int <= (sfl_has_access and scein_sfl) or (not sfl_has_access and scein);
	
		data0in_int <= (sfl_has_access and sdoin_sfl) or (not sfl_has_access and data_in(0));
		data1in_int <= (sfl_has_access and data1in_sfl) or (not sfl_has_access and data_in(1));
		data2in_int <= (sfl_has_access and data2in_sfl) or (not sfl_has_access and data_in(2));
		data3in_int <= (sfl_has_access and data3in_sfl) or (not sfl_has_access and data_in(3));

		data0oe_int <= (sfl_has_access and data0oe_sfl) or (not sfl_has_access and data_oe(0));
		data1oe_int <= (sfl_has_access and data1oe_sfl) or (not sfl_has_access and data_oe(1));
		data2oe_int <= (sfl_has_access and data2oe_sfl) or (not sfl_has_access and data_oe(2));
		data3oe_int <= (sfl_has_access and data3oe_sfl) or (not sfl_has_access and data_oe(3));
		
		noe_int <= noe;
		asmi_access_granted_sfl <= asmi_access_granted;
	end generate;

	sfl_has_access <= asmi_access_request_sfl and asmi_access_granted_sfl;

	GEN_ASMI_TYPE_0: if (ASMI_TYPE_0) generate
	asmi_inst: cyclone_asmiblock 
	port map
	(
		dclkin => dclkin_int,
		scein => scein_int,
		sdoin => sdoin_int,
		data0out => data0out_int,
		oe => noe_int and not sfl_has_access -- oe is an active low signal
	);
	end generate GEN_ASMI_TYPE_0;

	GEN_ASMI_TYPE_1: if (ASMI_TYPE_1) generate
	asmi_inst: cycloneii_asmiblock 
	port map
	(
		dclkin => dclkin_int,
		scein => scein_int,
		sdoin => sdoin_int,
		data0out => data0out_int,
		oe => noe_int and not sfl_has_access -- oe is an active low signal
	);
	end generate GEN_ASMI_TYPE_1;

	GEN_ASMI_TYPE_2: if (ASMI_TYPE_2) generate
	asmi_inst: stratixii_asmiblock 
	port map
	(
		dclkin => dclkin_int,
		scein => scein_int,
		sdoin => sdoin_int,
		data0out => data0out_int,
		oe => noe_int and not sfl_has_access -- oe is an active low signal
	);
	end generate GEN_ASMI_TYPE_2;

	GEN_ASMI_TYPE_3: if (ASMI_TYPE_3) generate
	asmi_inst: stratixiii_asmiblock 
	port map
	(
		dclkin => dclkin_int,
		scein => scein_int,
		sdoin => sdoin_int,
		data0out => data0out_int,
		oe => noe_int and not sfl_has_access -- oe is an active low signal
	);
	end generate GEN_ASMI_TYPE_3;

	GEN_ASMI_TYPE_4: if (ASMI_TYPE_4) generate
	asmi_inst: stratixiv_asmiblock 
	port map
	(
		dclkin => dclkin_int,
		scein => scein_int,
		sdoin => sdoin_int,
		data0out => data0out_int,
		oe => noe_int and not sfl_has_access -- oe is an active low signal
	);
	end generate GEN_ASMI_TYPE_4;
	
	GEN_ASMI_TYPE_5: if (ASMI_TYPE_5) generate
	asmi_inst: stratixv_asmiblock 
	port map
	(
		dclk => dclkin_int,
		sce => scein_int,
		oe => noe_int and not sfl_has_access, -- oe is an active low signal
		--oe => not noe_int or sfl_has_access, -- oe is an active high signal
		
		data0out => data0in_int,
		data1out => data1in_int,
		data2out => data2in_int,
		data3out => data3in_int,
		
		data0oe => data0oe_int,
		data1oe => data1oe_int,
		data2oe => data2oe_int,
		data3oe => data3oe_int,
		
		data0in => data0out_int,
		data1in => data1out_int,
		data2in => data2out_int,
		data3in => data3out_int
	);
	end generate GEN_ASMI_TYPE_5;
	
	GEN_ASMI_TYPE_6: if (ASMI_TYPE_6) generate
	asmi_inst: arriav_asmiblock 
	port map
	(
		dclk => dclkin_int,
		sce => scein_int,
		oe => noe_int and not sfl_has_access, -- oe is an active low signal
		--oe => not noe_int or sfl_has_access, -- oe is an active high signal
		
		data0out => data0in_int,
		data1out => data1in_int,
		data2out => data2in_int,
		data3out => data3in_int,
		
		data0oe => data0oe_int,
		data1oe => data1oe_int,
		data2oe => data2oe_int,
		data3oe => data3oe_int,
		
		data0in => data0out_int,
		data1in => data1out_int,
		data2in => data2out_int,
		data3in => data3out_int
	);
	end generate GEN_ASMI_TYPE_6;
	
	GEN_ASMI_TYPE_7: if (ASMI_TYPE_7) generate
	asmi_inst: cyclonev_asmiblock 
	port map
	(
		dclk => dclkin_int,
		sce => scein_int,
		oe => noe_int and not sfl_has_access, -- oe is an active low signal
		--oe => not noe_int or sfl_has_access, -- oe is an active high signal
		
		data0out => data0in_int,
		data1out => data1in_int,
		data2out => data2in_int,
		data3out => data3in_int,
		
		data0oe => data0oe_int,
		data1oe => data1oe_int,
		data2oe => data2oe_int,
		data3oe => data3oe_int,
		
		data0in => data0out_int,
		data1in => data1out_int,
		data2in => data2out_int,
		data3in => data3out_int
	);
	end generate GEN_ASMI_TYPE_7;
	
	DUMMY_OUT_QUAD_ON: if (enable_quad_spi_support = 1) generate
		data0out <= '0';
		data_out(0) <= data0out_int;
		data_out(1) <= data1out_int;
		data_out(2) <= data2out_int;
		data_out(3) <= data3out_int;
	end generate;
	
	DUMMY_OUT_QUAD_OFF_NONE_SV: if (enable_quad_spi_support = 0 and not (ASMI_TYPE_5 or ASMI_TYPE_6 or ASMI_TYPE_7)) generate
		data0out <= data0out_int;
		data_from_flash <= data0out_int;
		data_out <= "0000";
	end generate;
	
	DUMMY_OUT_QUAD_OFF_SV: if (enable_quad_spi_support = 0 and (ASMI_TYPE_5 or ASMI_TYPE_6 or ASMI_TYPE_7)) generate
		data0out <= data1out_int;
		data_from_flash <= data1out_int;
		data_out <= "0000";
	end generate;

	asmi_access_request <= asmi_access_request_sfl;

end architecture;
