-- suppress warnings for "object <foo> assigned a value but never read"
-- altera message_off 10036

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;

entity alt_pfl is
	generic 
	(
		-- General
		FEATURES_PGM					: natural := 1;
		FEATURES_CFG					: natural := 1;
		ADDR_WIDTH						: natural;					-- from 19 for 8Mbits, up to 25 for 512Mbits
		FLASH_DATA_WIDTH				: natural := 16;			-- valid values are 8, 16 or 32
		TRISTATE_CHECKBOX				: natural := 0;
		N_FLASH							: natural := 1;
		N_FLASH_BITS					: natural := 4;
		FLASH_NRESET_CHECKBOX 		: natural := 0;
		FLASH_NRESET_COUNTER			: natural := 1;
		
		-- Programming
		PFL_IR_BITS						: natural := 5;
		ENHANCED_FLASH_PROGRAMMING	: natural := 0;
		FIFO_SIZE		 				: natural := 16;
		DISABLE_CRC_CHECKBOX			: natural := 0;
		REG_LENGTH						: natural := 16;
		
		-- Configuration
		OPTION_START_ADDR				: natural;
		CLK_DIVISOR						: natural := 1;
		PAGE_CLK_DIVISOR				: natural := 1;
		DCLK_DIVISOR            	: natural := 2;
		CONF_DATA_WIDTH				: natural := 1;		-- valid values are 1 (PS),  8 (FPP), 16 (FPPx16) or 32 (FPPx32)
		DCLK_CREATE_DELAY				: natural := 0;
		-- Configuration (Error Handling)
		SAFE_MODE_HALT					: natural := 0;
		SAFE_MODE_RETRY				: natural := 1;
		SAFE_MODE_REVERT				: natural := 0;
		SAFE_MODE_REVERT_ADDR		: natural := 0;
		-- Configuration (Read Mode)
		NORMAL_MODE						: natural := 1;
		BURST_MODE						: natural := 0;
		PAGE_MODE						: natural := 0;
		BURST_MODE_INTEL				: natural := 0;
		BURST_MODE_SPANSION			: natural := 0;
		BURST_MODE_NUMONYX			: natural := 0;
		FLASH_BURST_EXTRA_CYCLE		: NATURAL := 0;
		CONF_WAIT_TIMER_WIDTH 		: natural := 16;
		DECOMPRESSOR_MODE				: string :=	"NONE";
		BURST_MODE_LATENCY_COUNT	: NATURAL := 4;
		-- Configuration (RSU Watchdog)
		PFL_RSU_WATCHDOG_ENABLED	: natural := 0;
		RSU_WATCHDOG_COUNTER			: natural := 100000000
	);
	port
	(
		pfl_clk							: in STD_LOGIC;
		pfl_nreset						: in STD_LOGIC;
		pfl_flash_access_granted	: in STD_LOGIC;
		pfl_flash_access_request	: out STD_LOGIC;
		pfl_nreconfigure 				: in STD_LOGIC;
		pfl_reset_watchdog			: in STD_LOGIC;
		pfl_watchdog_error			: out STD_LOGIC;

		-- flash output
		flash_addr						: out STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
		flash_data						: inout STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_nce						: out STD_LOGIC;
		flash_noe						: out STD_LOGIC;
		flash_nwe						: out STD_LOGIC;
		flash_clk						: out STD_LOGIC;
		flash_nadv						: out STD_LOGIC;
		flash_nreset					: out STD_LOGIC;
		flash_rdy						: in STD_LOGIC;
		
		-- FPGA
		fpga_pgm							: in STD_LOGIC_VECTOR (2 DOWNTO 0);
		fpga_conf_done					: in STD_LOGIC;
		fpga_nstatus					: in STD_LOGIC;
		dclk								: out STD_LOGIC;
		fpga_data						: out STD_LOGIC_VECTOR (CONF_DATA_WIDTH-1 downto 0);
		fpga_nconfig					: out STD_LOGIC
	);
end entity alt_pfl;

architecture rtl of alt_pfl is

COMPONENT alt_pfl_cfg3 is
  generic
  (
		FLASH_ADDR_WIDTH				: natural;				-- from 19 for 8Mbits, up to 25 for 512Mbits
		FLASH_OPTIONS_ADDR			: natural;
		ACCESS_CLK_DIVISOR			: natural := 1;
		PAGE_ACCESS_CLK_DIVISOR		: natural := 1;
		CONF_DATA_WIDTH				: natural := 1;		-- valid values are 16 (FPPx16) or 32 (FPPx32)
		FLASH_DATA_WIDTH				: natural := 16;   	-- valid values are 8, 16 or 32
		SAFE_MODE_HALT					: natural := 0;
		SAFE_MODE_RETRY				: natural := 1;
		SAFE_MODE_REVERT				: natural := 0;
		SAFE_MODE_REVERT_ADDR		: natural := 0;
		DCLK_DIVISOR            	: natural := 2;
		DCLK_CREATE_DELAY				: natural := 0;
		NORMAL_MODE						: natural := 1;
		BURST_MODE						: natural := 0;
		PAGE_MODE						: natural := 0;
		BURST_MODE_INTEL				: natural := 0;
		BURST_MODE_SPANSION			: natural := 0;
		BURST_MODE_NUMONYX			: natural := 0;
		FLASH_BURST_EXTRA_CYCLE		: natural := 0;
		CONF_WAIT_TIMER_WIDTH 		: natural := 16;
		DECOMPRESSOR_MODE				: string := "NONE";
		BURST_MODE_LATENCY_COUNT	: NATURAL := 4;
		PFL_RSU_WATCHDOG_ENABLED	: natural := 0;
		RSU_WATCHDOG_COUNTER			: natural := 100000000
  );
  port
  (
		clk								: in STD_LOGIC;
		nreset							: in STD_LOGIC;
		
		flash_access_granted			: in STD_LOGIC;
		flash_access_request			: out STD_LOGIC;
		pfl_nreconfigure 				: in STD_LOGIC;
		pfl_reset_watchdog			: in STD_LOGIC;
		pfl_watchdog_error			: out STD_LOGIC;
		
	-- 	flash output
		flash_addr						: out STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
		flash_data_in					: in STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_data_out					: out STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_read						: out STD_LOGIC;
		flash_select					: out STD_LOGIC;
		flash_write						: out STD_LOGIC;
		flash_clk						: out STD_LOGIC;
		flash_nadv						: out STD_LOGIC;
		flash_rdy						: in STD_LOGIC;
		flash_nreset					: out STD_LOGIC;
		flash_data_highz				: out STD_LOGIC;
				
		page_sel							: in STD_LOGIC_VECTOR (2 DOWNTO 0);

		--	FPGA
		fpga_conf_done					: in STD_LOGIC;
		fpga_nstatus					: in STD_LOGIC;
		fpga_dclk						: out STD_LOGIC;
		fpga_data						: out STD_LOGIC_VECTOR (CONF_DATA_WIDTH-1 downto 0);
		fpga_nconfig					: out STD_LOGIC;

		--	from PGM
		enable_configuration 		: in STD_LOGIC;
		enable_nconfig 				: in STD_LOGIC
	);
end COMPONENT alt_pfl_cfg3;

COMPONENT alt_pfl_cfg_flash_reset is
	generic
	(
		FLASH_NRESET_COUNTER			: natural := 1
	);
	port
	(
		pfl_clk							: in STD_LOGIC;
		pfl_nreset						: in STD_LOGIC;
	
		assert_flash_nreset 			: out STD_LOGIC;
		enable_operation 				: out STD_LOGIC
	);
end COMPONENT alt_pfl_cfg_flash_reset;

COMPONENT alt_pfl_pgm is
	generic 
	(
		PFL_IR_BITS						: natural;
		ADDR_WIDTH						: natural;	-- from 19 for 8Mbits, up to 25 for 512Mbits
		OPTION_START_ADDR				: natural;
		FLASH_DATA_WIDTH				: natural;	-- valid values are 8, 16 or 32
		N_FLASH							: natural;
		N_FLASH_BITS					: natural;
		DISABLE_CRC_CHECKBOX 		: natural := 0
	);
	port
	(
		pfl_nreset						: in STD_LOGIC;
		pfl_flash_access_granted	: in STD_LOGIC;
		pfl_flash_access_request	: out STD_LOGIC;

		--	to CFG
		enable_configuration 		: out STD_LOGIC;
		enable_nconfig					: out STD_LOGIC;
        
		--	flash output
		flash_addr						: out STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
		flash_data_in					: in STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_data_out					: out STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_read						: out STD_LOGIC;
		flash_write						: out STD_LOGIC;
		flash_select					: out STD_LOGIC;
		flash_nreset					: out STD_LOGIC;
		flash_data_highz				: out STD_LOGIC;
		active_flash_index 			: out STD_LOGIC_VECTOR (N_FLASH_BITS-1 downto 0)
	    );
end COMPONENT alt_pfl_pgm;

COMPONENT alt_pfl_pgm_enhanced is
	generic 
	(
		PFL_IR_BITS						: natural;
		ADDR_WIDTH						: natural;	-- from 19 for 8Mbits, up to 25 for 512Mbits
		OPTION_START_ADDR				: natural;
		FLASH_DATA_WIDTH				: natural;	-- valid values are 8 and 16
		FIFO_SIZE		 				: natural;
		N_FLASH							: natural;
		N_FLASH_BITS					: natural;
		DISABLE_CRC_CHECKBOX			: natural := 1
	);
	port
	(
		pfl_nreset						: in STD_LOGIC;
		pfl_flash_access_granted	: in STD_LOGIC;
		pfl_flash_access_request	: out STD_LOGIC;

		--	to CFG
		enable_configuration 		: out STD_LOGIC;
		enable_nconfig 				: out STD_LOGIC;
        
		--	flash output
		flash_addr						: out STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
		flash_data_in					: in STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_data_out					: out STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_read						: out STD_LOGIC;
		flash_write						: out STD_LOGIC;
		flash_select					: out STD_LOGIC;
		flash_nreset					: out STD_LOGIC;
		flash_data_highz				: out STD_LOGIC;
		active_flash_index 			: out STD_LOGIC_VECTOR (N_FLASH_BITS-1 downto 0)
	    );
end COMPONENT alt_pfl_pgm_enhanced;

	signal assert_flash_nreset 		: STD_LOGIC;
	signal enable_operation 			: STD_LOGIC;
	signal enable_configuration 		: STD_LOGIC;
	signal enable_nconfig 				: STD_LOGIC;
	signal pgm_flash_access_granted 	: STD_LOGIC;
	signal pgm_flash_access_request	: STD_LOGIC;
	signal pgm_flash_data_in 			: STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
	signal pgm_flash_data_out 			: STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
	signal pgm_flash_addr 				: STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
	signal pgm_flash_read 				: STD_LOGIC;
	signal pgm_flash_write 				: STD_LOGIC;
	signal pgm_flash_select				: STD_LOGIC;
	signal pgm_flash_nreset 			: STD_LOGIC;
	signal pgm_flash_data_highz 		: STD_LOGIC;
	signal cfg_flash_access_granted 	: STD_LOGIC;
	signal cfg_flash_access_request 	: STD_LOGIC;
	signal cfg_flash_data_in 			: STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
	signal cfg_flash_data_out	 		: STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
	signal cfg_flash_addr 				: STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
	signal cfg_flash_read 				: STD_LOGIC;
	signal cfg_flash_write 				: STD_LOGIC;
	signal cfg_flash_select				: STD_LOGIC;
	signal cfg_flash_clk 				: STD_LOGIC;
	signal cfg_flash_nadv 				: STD_LOGIC;
	signal cfg_flash_nreset 			: STD_LOGIC;
	signal cfg_flash_data_highz 		: STD_LOGIC;

	signal flash_data_out 				: STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
	signal flash_addr_out	 			: STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
	signal flash_read 					: STD_LOGIC;
	signal flash_write 					: STD_LOGIC;
	signal flash_select					: STD_LOGIC;
	signal flash_nadv_sig 				: STD_LOGIC;
	signal flash_clk_sig 				: STD_LOGIC;
	signal flash_nreset_sig				: STD_LOGIC;
	signal flash_data_highz 			: STD_LOGIC;

	attribute altera_attribute 			: string;
	attribute altera_attribute of rtl	: architecture is "SUPPRESS_DA_RULE_INTERNAL=""D101, D103""";
begin

INI1: if (FLASH_NRESET_CHECKBOX = 1 and FEATURES_CFG = 1)generate
	ini:alt_pfl_cfg_flash_reset
		generic map
	    (
			FLASH_NRESET_COUNTER	=> FLASH_NRESET_COUNTER
		
		)
		port map
		(
			pfl_clk 							=> pfl_clk,
			pfl_nreset 						=> pfl_nreset,
			assert_flash_nreset 			=> assert_flash_nreset,
			enable_operation 				=> enable_operation
	
		);
end generate;

PGM1: if (FEATURES_PGM = 1) generate
	DEFAULT_PGM: if (ENHANCED_FLASH_PROGRAMMING = 0) generate
		pgm: alt_pfl_pgm
		generic map
	    (
			PFL_IR_BITS 					=> PFL_IR_BITS,
			ADDR_WIDTH 						=> ADDR_WIDTH,
			OPTION_START_ADDR				=> OPTION_START_ADDR,
			FLASH_DATA_WIDTH 				=> FLASH_DATA_WIDTH, 
			N_FLASH 							=> N_FLASH,
			N_FLASH_BITS 					=> N_FLASH_BITS,
			DISABLE_CRC_CHECKBOX			=> DISABLE_CRC_CHECKBOX
		)
		port map
		(
			pfl_nreset 						=> pfl_nreset,
			pfl_flash_access_granted	=> pgm_flash_access_granted,
			pfl_flash_access_request	=> pgm_flash_access_request,
			flash_addr 						=> pgm_flash_addr,
			flash_data_in 					=> flash_data,
			flash_data_out 				=> pgm_flash_data_out,
			flash_read 						=> pgm_flash_read,
			flash_write 					=> pgm_flash_write,
			flash_select 					=> pgm_flash_select,
			flash_nreset 					=> pgm_flash_nreset,
			flash_data_highz 				=> pgm_flash_data_highz,
			enable_configuration 		=> enable_configuration,
			enable_nconfig 				=> enable_nconfig
			--active_flash_index			=> active_flash_index_si					
		);
	end generate;
	
	ENHANCED_PGM: if (ENHANCED_FLASH_PROGRAMMING = 1) generate
		pgm_enhanced: alt_pfl_pgm_enhanced
		generic map
		(
			PFL_IR_BITS 					=> PFL_IR_BITS,
			ADDR_WIDTH 						=> ADDR_WIDTH,
			OPTION_START_ADDR 			=> OPTION_START_ADDR,
			FLASH_DATA_WIDTH 				=> FLASH_DATA_WIDTH,
			FIFO_SIZE 						=> FIFO_SIZE,
			N_FLASH 							=> N_FLASH,
			N_FLASH_BITS 					=> N_FLASH_BITS,
			DISABLE_CRC_CHECKBOX 		=> DISABLE_CRC_CHECKBOX
		)
		port map
		(
			pfl_nreset 						=> pfl_nreset,
			pfl_flash_access_granted 	=> pgm_flash_access_granted,
			pfl_flash_access_request 	=> pgm_flash_access_request,
			flash_addr 						=> pgm_flash_addr,
			flash_data_in 					=> flash_data,
			flash_data_out					=> pgm_flash_data_out,
			flash_read						=> pgm_flash_read,
			flash_write 					=> pgm_flash_write,
			flash_select 					=> pgm_flash_select,
			flash_nreset 					=> pgm_flash_nreset,
			flash_data_highz 				=> pgm_flash_data_highz,
			enable_configuration	 		=> enable_configuration,
			enable_nconfig					=> enable_nconfig
			--active_flash_index			=> active_flash_index_sig
		);
	end generate;
end generate;

INI0: if (FLASH_NRESET_CHECKBOX = 0 or FEATURES_CFG = 0) generate
	assert_flash_nreset <= 'X';
	enable_operation 	<= '1';
	end generate;
PGM0: if (FEATURES_PGM = 0) generate
		pgm_flash_access_request		<= '0';
		pgm_flash_access_granted		<= 'X';
		pgm_flash_addr						<= (others => 'X');
		pgm_flash_read						<= 'X';
		pgm_flash_write					<= 'X';
		pgm_flash_select					<= 'X';
		pgm_flash_nreset					<= 'X';
		pgm_flash_data_highz				<= 'X';
		pgm_flash_data_out				<= (others => 'X');
		enable_configuration				<= '1';
		enable_nconfig						<= '0';
end generate;

CFG3: if (FEATURES_CFG = 1) generate
	cfg: alt_pfl_cfg3
    generic map
    (
		FLASH_ADDR_WIDTH 					=> ADDR_WIDTH,
		FLASH_OPTIONS_ADDR 				=> OPTION_START_ADDR,
		ACCESS_CLK_DIVISOR 				=> CLK_DIVISOR,
		PAGE_ACCESS_CLK_DIVISOR			=> PAGE_CLK_DIVISOR,
		CONF_DATA_WIDTH 					=> CONF_DATA_WIDTH,
		FLASH_DATA_WIDTH 					=> FLASH_DATA_WIDTH,
		SAFE_MODE_HALT 					=> SAFE_MODE_HALT,
		SAFE_MODE_RETRY 					=> SAFE_MODE_RETRY,
		SAFE_MODE_REVERT 					=> SAFE_MODE_REVERT,
		SAFE_MODE_REVERT_ADDR 			=> SAFE_MODE_REVERT_ADDR,
		DCLK_DIVISOR 						=> DCLK_DIVISOR,
		DCLK_CREATE_DELAY					=> DCLK_CREATE_DELAY,
		NORMAL_MODE 						=> normal_mode,
		BURST_MODE 							=> burst_mode,
		PAGE_MODE 							=> page_mode,
		BURST_MODE_INTEL 					=> burst_mode_intel,
		BURST_MODE_SPANSION 				=> burst_mode_spansion,
		BURST_MODE_NUMONYX				=> burst_mode_numonyx,
		FLASH_BURST_EXTRA_CYCLE			=> FLASH_BURST_EXTRA_CYCLE,
		BURST_MODE_LATENCY_COUNT		=> BURST_MODE_LATENCY_COUNT,
		CONF_WAIT_TIMER_WIDTH 			=> CONF_WAIT_TIMER_WIDTH,
		DECOMPRESSOR_MODE					=> DECOMPRESSOR_MODE,
		PFL_RSU_WATCHDOG_ENABLED		=> PFL_RSU_WATCHDOG_ENABLED,
		RSU_WATCHDOG_COUNTER				=> RSU_WATCHDOG_COUNTER
    )
    port map
    (
		clk 									=> pfl_clk,
		nreset 								=> pfl_nreset,
		flash_access_granted 			=> cfg_flash_access_granted,
		flash_access_request 			=> cfg_flash_access_request,
		pfl_nreconfigure 					=> pfl_nreconfigure,
		pfl_reset_watchdog				=> pfl_reset_watchdog,
		pfl_watchdog_error				=> pfl_watchdog_error,
		flash_addr 							=> cfg_flash_addr,
		flash_data_in 						=> flash_data,
		flash_data_out 					=> cfg_flash_data_out,
		flash_read 							=> cfg_flash_read,
		flash_write 						=> cfg_flash_write,
		flash_select 						=> cfg_flash_select,
		flash_clk 							=> cfg_flash_clk,
		flash_nadv 							=> cfg_flash_nadv,
		flash_rdy 							=> flash_rdy,
		flash_nreset 						=> cfg_flash_nreset,
		flash_data_highz 					=> cfg_flash_data_highz,
		page_sel 							=> fpga_pgm,
		fpga_conf_done 					=> fpga_conf_done,
		fpga_nstatus 						=> fpga_nstatus,
		fpga_dclk 							=> dclk,
		fpga_data 							=> fpga_data,
		fpga_nconfig 						=> fpga_nconfig,
		enable_configuration 			=> enable_configuration,
		enable_nconfig 					=> enable_nconfig
      );
end generate;

CFG0: if (FEATURES_CFG = 0) generate
		cfg_flash_access_request					<= '0';
		cfg_flash_data_out							<= (others => 'X');
		cfg_flash_addr									<= (others => 'X');
		cfg_flash_read									<= 'X';
		cfg_flash_write 								<= 'X';
		cfg_flash_select 								<= 'X';
		cfg_flash_clk									<= 'X';
		cfg_flash_nadv									<= 'X';
		cfg_flash_nreset 								<= 'X';
		cfg_flash_data_highz 						<= 'X';
		dclk 												<= 'X';
		fpga_data(CONF_DATA_WIDTH-1 downto 0)	<= (others => 'X');
		fpga_nconfig 									<= 'X';
  end generate;

  process (pgm_flash_access_request, cfg_flash_access_request, 
		   pgm_flash_access_granted, cfg_flash_access_granted, pfl_flash_access_granted,
		   pgm_flash_addr, pgm_flash_data_out, pgm_flash_read, pgm_flash_write, 
		   cfg_flash_addr, cfg_flash_data_out, cfg_flash_read, cfg_flash_write,
		   cfg_flash_nadv, cfg_flash_clk,
		   pgm_flash_data_highz, cfg_flash_data_highz,
		   cfg_flash_select, pgm_flash_select,
           pgm_flash_nreset, cfg_flash_nreset,assert_flash_nreset,enable_operation)
	begin
	  
		if (pgm_flash_access_request = '1') then 
			pfl_flash_access_request		<= pgm_flash_access_request;
			pgm_flash_access_granted		<= pfl_flash_access_granted;
			flash_addr_out						<= pgm_flash_addr;
			flash_data_out						<= pgm_flash_data_out;
			flash_read							<= pgm_flash_read;
			flash_write							<= pgm_flash_write;
			flash_select						<= pgm_flash_select;
			flash_data_highz					<= pgm_flash_data_highz;
			flash_nadv_sig						<= '0';
			flash_clk_sig						<= '0';
			flash_nreset_sig					<= pgm_flash_nreset;
			cfg_flash_access_granted		<= '0';
		elsif (FLASH_NRESET_CHECKBOX = 1 and FEATURES_CFG = 1 and assert_flash_nreset = '0') then
			pfl_flash_access_request		<= '0';
			flash_read							<= '0';
			flash_write							<= '0';
			flash_select						<= '0';
			flash_data_highz					<= '1';
			flash_nadv_sig						<= '0';
			flash_clk_sig						<= '0';
			flash_nreset_sig					<= assert_flash_nreset;
			flash_data_out						<= (others => 'X');
			pgm_flash_access_granted		<= '0';
			cfg_flash_access_granted		<= '0';
			flash_addr_out						<= (others => 'X');
		elsif (cfg_flash_access_request = '1' and enable_operation = '1') then
			pfl_flash_access_request		<= cfg_flash_access_request;
			cfg_flash_access_granted		<= pfl_flash_access_granted;
			flash_addr_out						<= cfg_flash_addr;
			flash_read							<= cfg_flash_read;
			flash_write							<= cfg_flash_write;
			flash_select						<= cfg_flash_select;
			flash_data_out						<= cfg_flash_data_out;
			flash_nadv_sig						<= cfg_flash_nadv;
			flash_clk_sig						<= cfg_flash_clk;
			flash_nreset_sig					<= cfg_flash_nreset;
			flash_data_highz					<= cfg_flash_data_highz;
			pgm_flash_access_granted		<= '0';
		else
			pfl_flash_access_request		<= '0';
			flash_read							<= '0';
			flash_write							<= '0';
			flash_select						<= '0';
			flash_data_highz					<= '1';
			flash_nadv_sig						<= '0';
			flash_clk_sig						<= '0';
			flash_nreset_sig					<= '1';
			flash_data_out						<= (others => 'X');
			pgm_flash_access_granted		<= '0';
			cfg_flash_access_granted		<= '0';
			flash_addr_out						<= (others => 'X');
		end if;
	end process;
        
	-- generates control signal
	ctrl_sig : process(flash_read, flash_write, flash_data_out, flash_select, pfl_flash_access_granted, 
		flash_addr_out, flash_data_highz, flash_nadv_sig, flash_clk_sig, flash_nreset_sig)
	begin
		if (TRISTATE_CHECKBOX = 0 or pfl_flash_access_granted = '1') then
			flash_nce		<= not flash_select;
			flash_nwe		<= not flash_write;
			flash_noe		<= not flash_read;
			flash_addr		<= flash_addr_out;
			flash_nadv		<= flash_nadv_sig;
			flash_clk		<= flash_clk_sig;
			flash_nreset	<= flash_nreset_sig;			
			if (flash_data_highz = '1') then
				flash_data	<= (others => 'Z');
			else
				flash_data	<= flash_data_out;
			end if;
		else
			flash_nce 		<= 'Z';
			flash_nwe 		<= 'Z';
			flash_noe 		<= 'Z';
			flash_nadv 		<= 'Z';
			flash_clk 		<= 'Z';
			flash_nreset	<= 'Z';			
			flash_data		<= (others => 'Z');
			flash_addr 		<= (others => 'Z');
		end if;		
	end process ctrl_sig;
end architecture rtl;
