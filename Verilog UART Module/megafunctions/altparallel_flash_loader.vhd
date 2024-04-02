PACKAGE TOP_CONST is
	CONSTANT PFL_QUAD_IO_FLASH_IR_BITS	: NATURAL := 8;
	CONSTANT PFL_CFI_FLASH_IR_BITS		: NATURAL := 5;
	CONSTANT PFL_NAND_FLASH_IR_BITS		: NATURAL := 4;	
	CONSTANT N_FLASH_BITS					: NATURAL := 4;
END PACKAGE TOP_CONST;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_SIGNED.all;
use WORK.TOP_CONST.all;

ENTITY altparallel_flash_loader IS
	GENERIC 
	(
		-- General 
		auto_restart						: STRING := "OFF";
		lpm_type								: STRING := "ALTPARALLEL_FLASH_LOADER";
		flash_type							: STRING := "CFI_FLASH";	-- CFI_FLASH or QUAD_SPI_FLASH
		n_flash								: NATURAL := 1;
		flash_data_width					: NATURAL := 16;
		addr_width							: NATURAL := 20;
		features_pgm						: NATURAL := 1;
		features_cfg						: NATURAL := 1;
		tristate_checkbox					: NATURAL := 0;
		
		-- General (Configuration)
		option_bits_start_address		: NATURAL := 0;			-- Control Block
		safe_mode_halt						: NATURAL := 0;			-- Control Block (Error Handling)
		safe_mode_retry					: NATURAL := 1;			-- Control Block (Error Handling)
		safe_mode_revert					: NATURAL := 0;			-- Control Block (Error Handling)
		safe_mode_revert_addr			: NATURAL := 0;			-- Control Block (Error Handling)
		conf_data_width					: NATURAL := 1;			-- FPGA Block
		dclk_divisor						: NATURAL := 1;			-- FPGA Block
		conf_wait_timer_width			: NATURAL := 16; 			-- FPGA Block
		dclk_create_delay					: NATURAL := 0;			-- FPGA Block
		decompressor_mode					: STRING  := "NONE"; 		-- NONE or AREA or SPEED
		pfl_rsu_watchdog_enabled		: NATURAL := 0;			-- Enable RSU Watchdog
		rsu_watchdog_counter				: NATURAL := 100000000;
		
		-- CFI Flash (Flash Programming)
		enhanced_flash_programming		: NATURAL := 0;
		fifo_size							: NATURAL := 16;
		disable_crc_checkbox 			: NATURAL := 0;
		
		-- CFI Flash (Configuration)
		clk_divisor							: NATURAL := 1;
		page_clk_divisor					: NATURAL := 1;
		normal_mode							: NATURAL := 1;
		burst_mode							: NATURAL := 0;
		page_mode							: NATURAL := 0;
		burst_mode_intel					: NATURAL := 0;
		burst_mode_spansion				: NATURAL := 0;
		burst_mode_numonyx				: NATURAL := 0;
		flash_nreset_checkbox 			: NATURAL := 0;
		flash_nreset_counter				: NATURAL := 1;
		flash_burst_extra_cycle			: NATURAL := 0;
		BURST_MODE_LATENCY_COUNT		: NATURAL := 4;
		
		-- Quad Flash (General)
		qflash_mfc							: STRING := "ALTERA";	-- Quad Flash Manufacturer "ALTERA" "ATMEL" "MACRONIX" "NUMONYX" "SPANSION" or "WINBOND"
		extra_addr_byte					: NATURAL := 0;
		qspi_data_delay					: NATURAL := 0;
		qspi_data_delay_count			: NATURAL := 1;
		qflash_fast_speed					: NATURAL := 0;
		flash_static_wait_width			: NATURAL := 15;
		
		-- NAND Flash (General)
		nand_size							: NATURAL := 67108864;
		nrb_addr								: NATURAL := 65667072;
		flash_ecc_checkbox				: NATURAL := 0;
		nflash_mfc							: STRING := "NUMONYX";
		us_unit_counter					: NATURAL := 1
	);
	PORT
	(
		-- General
		pfl_nreset							: IN STD_LOGIC := '0';
		pfl_flash_access_granted		: IN STD_LOGIC := '0';
		pfl_flash_access_request		: OUT	STD_LOGIC;
		
		-- General (Configuration)
		pfl_clk								: IN STD_LOGIC := '0';
		fpga_nstatus						: IN STD_LOGIC := '0';
		fpga_conf_done						: IN STD_LOGIC := '0';
		pfl_nreconfigure					: IN STD_LOGIC := '1';
		fpga_pgm								: IN STD_LOGIC_VECTOR (2 DOWNTO 0) := (others=>'0');
		fpga_nconfig						: OUT STD_LOGIC;
		fpga_dclk							: OUT STD_LOGIC;
		fpga_data							: OUT STD_LOGIC_VECTOR (conf_data_width-1 downto 0);
		pfl_reset_watchdog				: IN STD_LOGIC	:= '0';
		pfl_watchdog_error				: OUT	STD_LOGIC;
		
		-- CFI flash (General)
		flash_rdy							: IN STD_LOGIC := '1';
		flash_data							: INOUT STD_LOGIC_VECTOR (flash_data_width-1 downto 0);
		flash_addr							: OUT STD_LOGIC_VECTOR (addr_width-1 downto 0);
		flash_nreset						: OUT STD_LOGIC;
		
		-- QUAD IO (General)
		flash_ncs							: OUT STD_LOGIC_VECTOR (n_flash-1 DOWNTO 0);
		flash_sck							: OUT STD_LOGIC_VECTOR (n_flash-1 DOWNTO 0);
		flash_io0 							: INOUT STD_LOGIC_VECTOR (n_flash-1 DOWNTO 0);
		flash_io1 							: INOUT STD_LOGIC_VECTOR (n_flash-1 DOWNTO 0);
		flash_io2 							: INOUT STD_LOGIC_VECTOR (n_flash-1 DOWNTO 0);
		flash_io3 							: INOUT STD_LOGIC_VECTOR (n_flash-1 DOWNTO 0);
		
		-- NAND IO (GENERAL)
		flash_io								: INOUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		flash_cle							: OUT	STD_LOGIC;
		flash_ale							: OUT	STD_LOGIC;
		
		-- CFI flash (Flash Programming) -- shared by NAND
		flash_nce							: OUT STD_LOGIC_VECTOR (n_flash-1 downto 0);
		flash_noe							: OUT STD_LOGIC;
		flash_nwe							: OUT STD_LOGIC;
		
		-- CFI flash (Configuration)
		flash_clk							: OUT STD_LOGIC;
		flash_nadv							: OUT STD_LOGIC
	);
END ENTITY altparallel_flash_loader;

ARCHITECTURE rtl OF altparallel_flash_loader IS
	COMPONENT alt_pfl
	GENERIC
	(
		-- General
		FEATURES_PGM						: NATURAL;
		FEATURES_CFG						: NATURAL;
		ADDR_WIDTH							: NATURAL;
		FLASH_DATA_WIDTH					: NATURAL;
		TRISTATE_CHECKBOX					: NATURAL := 0;
		N_FLASH								: NATURAL := 1;
		N_FLASH_BITS						: NATURAL := 4;
		FLASH_NRESET_CHECKBOX 			: NATURAL := 0;
		FLASH_NRESET_COUNTER				: NATURAL := 1;
		
		-- Programming
		PFL_IR_BITS							: NATURAL;
		ENHANCED_FLASH_PROGRAMMING		: NATURAL := 0;
		FIFO_SIZE							: NATURAL := 16;
		DISABLE_CRC_CHECKBOX 			: NATURAL := 0;
		
		-- Configuration
		OPTION_START_ADDR					: NATURAL;
		CLK_DIVISOR							: NATURAL;
		PAGE_CLK_DIVISOR					: NATURAL;
		DCLK_DIVISOR						: NATURAL := 2;
		DCLK_CREATE_DELAY					: NATURAL := 0;
		CONF_DATA_WIDTH					: NATURAL;
		-- Configuration (Error Handling)
		SAFE_MODE_HALT						: NATURAL := 0;
		SAFE_MODE_RETRY					: NATURAL := 1;
		SAFE_MODE_REVERT					: NATURAL := 0;
		SAFE_MODE_REVERT_ADDR			: NATURAL := 0;
		-- Configuration (Read Mode)
		NORMAL_MODE							: NATURAL := 1;
		BURST_MODE							: NATURAL := 0;
		PAGE_MODE							: NATURAL := 0;
		BURST_MODE_INTEL					: NATURAL := 0;
		BURST_MODE_SPANSION				: NATURAL := 0;
		BURST_MODE_NUMONYX				: NATURAL := 0;
		FLASH_BURST_EXTRA_CYCLE			: NATURAL := 0;
		CONF_WAIT_TIMER_WIDTH 			: NATURAL := 16;
		DECOMPRESSOR_MODE					: STRING := "NONE";
		BURST_MODE_LATENCY_COUNT		: NATURAL := 4;
		-- Configuration (RSU Watchdog)
		PFL_RSU_WATCHDOG_ENABLED		: NATURAL := 0;	
		RSU_WATCHDOG_COUNTER				: NATURAL := 100000000
	);
	PORT
	(
		-- General
		pfl_nreset							: IN STD_LOGIC;
		pfl_flash_access_granted		: IN STD_LOGIC;
		pfl_flash_access_request		: OUT STD_LOGIC;
		
		-- General (Configuration)
		pfl_clk								: IN STD_LOGIC;
		fpga_nstatus						: IN STD_LOGIC;
		fpga_conf_done						: IN STD_LOGIC;
		pfl_nreconfigure					: IN STD_LOGIC;
		fpga_pgm								: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		fpga_nconfig						: OUT STD_LOGIC;
		dclk									: OUT STD_LOGIC;
		fpga_data							: OUT STD_LOGIC_VECTOR (CONF_DATA_WIDTH-1 downto 0);
		pfl_reset_watchdog				: IN STD_LOGIC	:= '0';
		pfl_watchdog_error				: OUT STD_LOGIC;
		
		-- CFI flash (General)
		flash_rdy							: IN STD_LOGIC;
		flash_data							: INOUT STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_addr							: OUT STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
		flash_nreset						: OUT STD_LOGIC;

		-- CFI flash (Flash Programming)
		flash_nce							: OUT STD_LOGIC;
		flash_noe							: OUT STD_LOGIC;
		flash_nwe							: OUT STD_LOGIC;
		
		-- CFI flash (Configuration)
		flash_clk							: OUT STD_LOGIC;
		flash_nadv							: OUT STD_LOGIC
		
	);
	END COMPONENT alt_pfl;
	
	COMPONENT alt_pfl_multiple_flash
	GENERIC
	(
		-- General
		FEATURES_PGM						: NATURAL;
		FEATURES_CFG						: NATURAL;
		ADDR_WIDTH							: NATURAL;
		FLASH_DATA_WIDTH					: NATURAL;
		TRISTATE_CHECKBOX					: NATURAL := 0;
		N_FLASH								: NATURAL := 1;
		N_FLASH_BITS						: NATURAL := 4;
		
		-- Programming
		PFL_IR_BITS							: NATURAL;
		ENHANCED_FLASH_PROGRAMMING		: NATURAL := 0;
		FIFO_SIZE				 			: NATURAL := 16;
		DISABLE_CRC_CHECKBOX 			: NATURAL := 0;
		
		-- Configuration
		OPTION_START_ADDR					: NATURAL;
		CLK_DIVISOR							: NATURAL;
		PAGE_CLK_DIVISOR					: NATURAL;
		DCLK_DIVISOR            		: NATURAL := 2;
		DCLK_CREATE_DELAY					: NATURAL := 0;
		CONF_DATA_WIDTH					: NATURAL;
		-- Configuration (Error Handling)
		SAFE_MODE_HALT						: NATURAL := 0;
		SAFE_MODE_RETRY					: NATURAL := 1;
		SAFE_MODE_REVERT					: NATURAL := 0;
		SAFE_MODE_REVERT_ADDR			: NATURAL := 0;
		-- Configuration (Read Mode)
		NORMAL_MODE							: NATURAL := 1;
		BURST_MODE							: NATURAL := 0;
		PAGE_MODE							: NATURAL := 0;
		BURST_MODE_INTEL					: NATURAL := 0;
		BURST_MODE_SPANSION				: NATURAL := 0;
		BURST_MODE_NUMONYX				: NATURAL := 0;
		FLASH_BURST_EXTRA_CYCLE			: NATURAL := 0;
		CONF_WAIT_TIMER_WIDTH 			: NATURAL := 16;
		DECOMPRESSOR_MODE					: STRING  := "NONE";
		BURST_MODE_LATENCY_COUNT		: NATURAL := 4;
		-- Configuration (RSU Watchdog)
		PFL_RSU_WATCHDOG_ENABLED		: NATURAL := 0;	
		RSU_WATCHDOG_COUNTER				: NATURAL := 100000000
	);
	PORT
	(
		-- General
		pfl_nreset							: IN STD_LOGIC;
		pfl_flash_access_granted		: IN STD_LOGIC;
		pfl_flash_access_request		: OUT STD_LOGIC;
		
		-- General (Configuration)
		pfl_clk								: IN STD_LOGIC;
		fpga_nstatus						: IN STD_LOGIC;
		fpga_conf_done						: IN STD_LOGIC;
		pfl_nreconfigure					: IN STD_LOGIC;
		fpga_pgm								: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		fpga_nconfig						: OUT STD_LOGIC;
		dclk									: OUT STD_LOGIC;
		fpga_data							: OUT STD_LOGIC_VECTOR (CONF_DATA_WIDTH-1 downto 0);
		pfl_reset_watchdog				: IN STD_LOGIC	:= '0';
		pfl_watchdog_error				: OUT STD_LOGIC;
		
		-- CFI flash (General)
		flash_rdy							: IN STD_LOGIC;
		flash_data							: INOUT STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);
		flash_addr							: OUT STD_LOGIC_VECTOR (ADDR_WIDTH-1 downto 0);
		flash_nreset						: OUT STD_LOGIC;
		
		-- CFI flash (Flash Programming)
		flash_nce							: OUT STD_LOGIC_VECTOR (N_FLASH-1 downto 0);
		flash_noe							: OUT STD_LOGIC;
		flash_nwe							: OUT STD_LOGIC;
		
		-- CFI flash (Configuration)
		flash_clk							: OUT STD_LOGIC;
		flash_nadv							: OUT STD_LOGIC
	);
	END COMPONENT alt_pfl_multiple_flash;
	
	component alt_pfl_quad_io_flash
	GENERIC
	(
		-- General
		FEATURES_CFG						: NATURAL;
		FEATURES_PGM						: NATURAL;
		FLASH_MFC							: STRING	:= "ALTERA";
		QFLASH_FAST_SPEED					: NATURAL := 0;
		FLASH_STATIC_WAIT_WIDTH			: NATURAL := 15;
		ADDR_WIDTH							: NATURAL := 24;
		TRISTATE_CHECKBOX					: NATURAL := 1;
		N_FLASH								: NATURAL := 4;
		PFL_IR_BITS 						: NATURAL := 8;
		EXTRA_ADDR_BYTE					: NATURAL := 0;
		FLASH_BURST_EXTRA_CYCLE			: NATURAL := 0;
		QSPI_DATA_DELAY					: NATURAL := 0;
		QSPI_DATA_DELAY_COUNT			: NATURAL := 1;
		
		-- Configuration
		OPTION_BITS_START_ADDRESS		: NATURAL := 0;
		DCLK_DIVISOR						: NATURAL := 1;
		CONF_DATA_WIDTH					: NATURAL := 8;
		DCLK_CREATE_DELAY					: NATURAL := 0;
		-- Configuration (Error Handling)
		SAFE_MODE_HALT						: NATURAL := 0;
		SAFE_MODE_RETRY					: NATURAL := 1;
		SAFE_MODE_REVERT					: NATURAL := 0;
		SAFE_MODE_REVERT_ADDR			: NATURAL := 0;
		CONF_WAIT_TIMER_WIDTH			: NATURAL := 16;
		DECOMPRESSOR_MODE					: STRING := "NONE";
		-- Configuration (RSU Watchdog)
		PFL_RSU_WATCHDOG_ENABLED		: NATURAL := 0;	-- Enable RSU Watchdog
		RSU_WATCHDOG_COUNTER				: NATURAL := 100000000
	);
	PORT
	(
		-- General
		pfl_nreset							: IN STD_LOGIC;
		pfl_flash_access_granted 		: IN STD_LOGIC;
		pfl_flash_access_request 		: OUT STD_LOGIC;
		
		flash_ncs 							: OUT STD_LOGIC_VECTOR (N_FLASH-1 DOWNTO 0);
		flash_sck 							: OUT STD_LOGIC_VECTOR (N_FLASH-1 DOWNTO 0);
		flash_io0 							: INOUT STD_LOGIC_VECTOR (N_FLASH-1 DOWNTO 0);
		flash_io1 							: INOUT STD_LOGIC_VECTOR (N_FLASH-1 DOWNTO 0);
		flash_io2 							: INOUT STD_LOGIC_VECTOR (N_FLASH-1 DOWNTO 0);
		flash_io3 							: INOUT STD_LOGIC_VECTOR (N_FLASH-1 DOWNTO 0);
		
		-- General (Configuration)
		pfl_clk								: IN STD_LOGIC;
		fpga_nstatus						: IN STD_LOGIC;
		fpga_conf_done						: IN STD_LOGIC;
		pfl_nreconfigure					: IN STD_LOGIC;
		fpga_pgm								: IN STD_LOGIC_VECTOR (2 downto 0);
		fpga_nconfig						: OUT STD_LOGIC;
		dclk									: OUT	STD_LOGIC;
		fpga_data							: OUT	STD_LOGIC_VECTOR (CONF_DATA_WIDTH-1 DOWNTO 0);
		pfl_reset_watchdog				: IN STD_LOGIC	:= '0';
		pfl_watchdog_error				: OUT STD_LOGIC
	);
	end component alt_pfl_quad_io_flash;
	
	COMPONENT alt_pfl_nand_flash
	GENERIC
	(
		-- General
		FEATURES_PGM						: NATURAL;
		FEATURES_CFG						: NATURAL;
		FLASH_DATA_WIDTH					: NATURAL;
		FLASH_ADDR_WIDTH					: NATURAL;
		
		TRISTATE_CHECKBOX					: NATURAL := 0;
		N_FLASH								: NATURAL := 1;
		NAND_SIZE							: NATURAL := 67108864;
		NRB_ADDR								: NATURAL := 65667072;
		FLASH_ECC_CHECKBOX				: NATURAL := 0;
		FLASH_MFC							: STRING := "NUMONYX";
		US_UNIT_COUNTER					: NATURAL := 1;

		-- Programming
		PFL_IR_BITS							: NATURAL;
		
		-- Configuration
		OPTION_START_ADDR					: NATURAL;
		CLK_DIVISOR							: NATURAL;
		PAGE_CLK_DIVISOR					: NATURAL;
		DCLK_DIVISOR						: NATURAL := 2;
		DCLK_CREATE_DELAY					: NATURAL := 0;
		CONF_DATA_WIDTH					: NATURAL;
		
		-- Configuration (Error Handling)
		SAFE_MODE_HALT						: NATURAL := 0;
		SAFE_MODE_RETRY					: NATURAL := 1;
		SAFE_MODE_REVERT					: NATURAL := 0;
		SAFE_MODE_REVERT_ADDR			: NATURAL := 0;
		
		-- Configuration
		CONF_WAIT_TIMER_WIDTH 			: NATURAL := 16;
		DECOMPRESSOR_MODE					: STRING := "NONE";
		
		-- Configuration (RSU Watchdog)
		PFL_RSU_WATCHDOG_ENABLED		: NATURAL := 0;	
		RSU_WATCHDOG_COUNTER				: NATURAL := 100000000
	);
	PORT
	(
		-- General
		pfl_nreset							: IN STD_LOGIC;
		pfl_flash_access_granted		: IN STD_LOGIC;
		pfl_flash_access_request		: OUT STD_LOGIC;
		
		-- General (Configuration)
		pfl_clk								: IN STD_LOGIC;
		fpga_nstatus						: IN STD_LOGIC;
		fpga_conf_done						: IN STD_LOGIC;
		pfl_nreconfigure					: IN STD_LOGIC;
		fpga_pgm								: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		fpga_nconfig						: OUT STD_LOGIC;
		dclk									: OUT STD_LOGIC;
		fpga_data							: OUT STD_LOGIC_VECTOR (CONF_DATA_WIDTH-1 downto 0);
		pfl_reset_watchdog				: IN STD_LOGIC	:= '0';
		pfl_watchdog_error				: OUT	STD_LOGIC;
		
		-- NAND flash (General)
		flash_io								: INOUT STD_LOGIC_VECTOR (FLASH_DATA_WIDTH-1 downto 0);

		-- NAND flash (Flash Programming)
		flash_nce							: OUT STD_LOGIC;
		flash_nwe							: OUT STD_LOGIC;
		flash_noe							: OUT STD_LOGIC;
		flash_cle							: OUT	STD_LOGIC;
		flash_ale							: OUT	STD_LOGIC
	);
	END COMPONENT alt_pfl_nand_flash;
	
begin
	PFL_CFI: IF (flash_type = "CFI_FLASH" and n_flash = 1) GENERATE
		pfl_cfi_inst: alt_pfl
		GENERIC MAP
		(
			-- General
			PFL_IR_BITS						=> PFL_CFI_FLASH_IR_BITS,
			FEATURES_CFG					=> features_cfg,
			FEATURES_PGM					=> features_pgm,
			ADDR_WIDTH						=> addr_width,
			FLASH_DATA_WIDTH				=> flash_data_width,
			N_FLASH 							=> n_flash,
			N_FLASH_BITS 					=> N_FLASH_BITS,
			TRISTATE_CHECKBOX				=> tristate_checkbox,
			FLASH_NRESET_CHECKBOX		=> flash_nreset_checkbox,
			FLASH_NRESET_COUNTER			=> flash_nreset_counter,
			
			-- Flash Programming
			ENHANCED_FLASH_PROGRAMMING	=> enhanced_flash_programming,
			FIFO_SIZE 						=> fifo_size,
			DISABLE_CRC_CHECKBOX			=> disable_crc_checkbox,
			
			-- Configuration
			OPTION_START_ADDR				=> option_bits_start_address,
			CLK_DIVISOR						=> clk_divisor,
			PAGE_CLK_DIVISOR				=> page_clk_divisor,
			DCLK_DIVISOR 					=> dclk_divisor,
			CONF_DATA_WIDTH				=> conf_data_width,
			DCLK_CREATE_DELAY				=> dclk_create_delay,
			-- Configuration (Error Handling)
			SAFE_MODE_HALT 				=> safe_mode_halt,
			SAFE_MODE_RETRY 				=> safe_mode_retry,
			SAFE_MODE_REVERT 				=> safe_mode_revert,
			SAFE_MODE_REVERT_ADDR 		=> safe_mode_revert_addr,
			-- Configuration (Read Mode)
			NORMAL_MODE 					=> normal_mode,
			BURST_MODE 						=> burst_mode,
			PAGE_MODE 						=> page_mode,
			BURST_MODE_INTEL 				=> burst_mode_intel,
			BURST_MODE_SPANSION 			=> burst_mode_spansion,
			BURST_MODE_NUMONYX 			=> burst_mode_numonyx,
			FLASH_BURST_EXTRA_CYCLE		=> flash_burst_extra_cycle,
			CONF_WAIT_TIMER_WIDTH 		=> conf_wait_timer_width,
			DECOMPRESSOR_MODE				=> decompressor_mode,
			BURST_MODE_LATENCY_COUNT		=> BURST_MODE_LATENCY_COUNT,
			-- Configuration (RSU Watchdog)
			PFL_RSU_WATCHDOG_ENABLED	=> pfl_rsu_watchdog_enabled,
			RSU_WATCHDOG_COUNTER			=> rsu_watchdog_counter
		)
		PORT MAP
		(
			-- General
			pfl_clk 							=> pfl_clk,
			pfl_nreset						=> pfl_nreset,
			pfl_flash_access_granted 	=> pfl_flash_access_granted,
			pfl_flash_access_request 	=> pfl_flash_access_request,
			
			-- General (Configuration)
			fpga_nstatus					=> fpga_nstatus,
			fpga_conf_done					=> fpga_conf_done,
			pfl_nreconfigure 				=> pfl_nreconfigure,
			fpga_pgm							=> fpga_pgm,
			fpga_nconfig					=> fpga_nconfig,
			dclk								=> fpga_dclk,
			fpga_data						=> fpga_data,
			pfl_reset_watchdog			=> pfl_reset_watchdog,
			pfl_watchdog_error			=> pfl_watchdog_error,
			
			-- CFI flash (General)
			flash_rdy						=> flash_rdy,
			flash_data						=> flash_data,
			flash_addr						=> flash_addr,
			flash_nreset					=> flash_nreset,
			
			-- CFI flash (Flash Programming)
			flash_nce						=> flash_nce(0),
			flash_noe						=> flash_noe,
			flash_nwe						=> flash_nwe,
			
			-- CFI flash (Configuration)
			flash_clk						=> flash_clk,
			flash_nadv						=> flash_nadv		
		);
	END GENERATE;
	
	PFL_MULTIPLE_CFI: IF (flash_type = "CFI_FLASH" and n_flash > 1) GENERATE
		pfl_mltiple_cfi_inst: alt_pfl_multiple_flash
		GENERIC MAP
		(
			-- General
			PFL_IR_BITS						=> PFL_CFI_FLASH_IR_BITS,
			FEATURES_CFG					=> features_cfg,
			FEATURES_PGM					=> features_pgm,
			ADDR_WIDTH						=> addr_width,
			FLASH_DATA_WIDTH				=> flash_data_width,
			N_FLASH 							=> n_flash,
			N_FLASH_BITS 					=> N_FLASH_BITS,
			TRISTATE_CHECKBOX 			=> tristate_checkbox,
			
			-- Flash Programming
			ENHANCED_FLASH_PROGRAMMING	=> enhanced_flash_programming,
			FIFO_SIZE 						=> fifo_size,
			DISABLE_CRC_CHECKBOX			=> disable_crc_checkbox,

			-- Configuration
			OPTION_START_ADDR				=> option_bits_start_address,
			CLK_DIVISOR						=> clk_divisor,
			PAGE_CLK_DIVISOR				=> page_clk_divisor,
			DCLK_DIVISOR 					=> dclk_divisor,
			CONF_DATA_WIDTH				=> conf_data_width,
			DCLK_CREATE_DELAY				=> dclk_create_delay,
			-- Configuration (Error Handling)
			SAFE_MODE_HALT 				=> safe_mode_halt,
			SAFE_MODE_RETRY 				=> safe_mode_retry,
			SAFE_MODE_REVERT 				=> safe_mode_revert,
			SAFE_MODE_REVERT_ADDR 		=> safe_mode_revert_addr,
			-- Configuration (Read Mode)
			NORMAL_MODE 					=> normal_mode,
			BURST_MODE 						=> burst_mode,
			PAGE_MODE 						=> page_mode,
			BURST_MODE_INTEL 				=> burst_mode_intel,
			BURST_MODE_SPANSION 			=> burst_mode_spansion,
			BURST_MODE_NUMONYX 			=> burst_mode_numonyx,
			FLASH_BURST_EXTRA_CYCLE		=> flash_burst_extra_cycle,
			CONF_WAIT_TIMER_WIDTH 		=> conf_wait_timer_width,
			DECOMPRESSOR_MODE				=> decompressor_mode,
			BURST_MODE_LATENCY_COUNT	=> BURST_MODE_LATENCY_COUNT,
			-- Configuration (RSU Watchdog)
			PFL_RSU_WATCHDOG_ENABLED	=> pfl_rsu_watchdog_enabled,
			RSU_WATCHDOG_COUNTER			=> rsu_watchdog_counter
		)
		PORT MAP
		(
			-- General 
			pfl_clk 							=> pfl_clk,
			pfl_nreset						=> pfl_nreset,
			pfl_flash_access_granted 	=> pfl_flash_access_granted,
			pfl_flash_access_request 	=> pfl_flash_access_request,
			
			-- General (Configuration)
			fpga_nstatus					=> fpga_nstatus,
			fpga_conf_done					=> fpga_conf_done,
			pfl_nreconfigure 				=> pfl_nreconfigure,
			fpga_pgm							=> fpga_pgm,
			fpga_nconfig					=> fpga_nconfig,
			dclk								=> fpga_dclk,
			fpga_data						=> fpga_data,
			pfl_reset_watchdog			=> pfl_reset_watchdog,
			pfl_watchdog_error			=> pfl_watchdog_error,
	
			-- CFI flash (General)
			flash_rdy						=> flash_rdy,
			flash_data						=> flash_data,
			flash_addr						=> flash_addr,
			flash_nreset					=> flash_nreset,
			
			-- CFI flash (Flash Programming)
			flash_nce						=> flash_nce,
			flash_noe						=> flash_noe,
			flash_nwe						=> flash_nwe,
			
			-- CFI flash (Configuration)
			flash_clk						=> flash_clk,
			flash_nadv						=> flash_nadv
		);
	END GENERATE;
	
	PFL_QUAD_IO_FLASH: IF (flash_type = "QUAD_SPI_FLASH") GENERATE
		pfl_quad_io_inst: alt_pfl_quad_io_flash
		GENERIC MAP
		(
			-- General
			FLASH_MFC						=> qflash_mfc,
			QFLASH_FAST_SPEED				=> qflash_fast_speed,
			FLASH_STATIC_WAIT_WIDTH 	=> flash_static_wait_width,
			PFL_IR_BITS 					=> PFL_QUAD_IO_FLASH_IR_BITS,
			FEATURES_CFG					=> features_cfg,
			FEATURES_PGM					=> features_pgm,
			ADDR_WIDTH						=> addr_width,
			N_FLASH 							=> n_flash,
			EXTRA_ADDR_BYTE				=> extra_addr_byte,
			FLASH_BURST_EXTRA_CYCLE		=> FLASH_BURST_EXTRA_CYCLE,
			TRISTATE_CHECKBOX 			=> tristate_checkbox,
			
			-- Configuration
			OPTION_BITS_START_ADDRESS	=> option_bits_start_address,
			DCLK_DIVISOR					=> dclk_divisor,
			CONF_DATA_WIDTH				=> conf_data_width,
			DCLK_CREATE_DELAY				=> dclk_create_delay,
			QSPI_DATA_DELAY				=> qspi_data_delay,
			QSPI_DATA_DELAY_COUNT		=> qspi_data_delay_count,
			-- Configuration (Error Handling)
			SAFE_MODE_HALT 				=> safe_mode_halt,
			SAFE_MODE_RETRY 				=> safe_mode_retry,
			SAFE_MODE_REVERT 				=> safe_mode_revert,
			SAFE_MODE_REVERT_ADDR 		=> safe_mode_revert_addr,
			CONF_WAIT_TIMER_WIDTH 		=> conf_wait_timer_width,
			DECOMPRESSOR_MODE				=> decompressor_mode,
			-- Configuration (RSU Watchdog)
			PFL_RSU_WATCHDOG_ENABLED	=> pfl_rsu_watchdog_enabled,
			RSU_WATCHDOG_COUNTER			=> rsu_watchdog_counter
		)
		PORT MAP
		(
			-- General
			pfl_clk 							=> pfl_clk,
			pfl_nreset						=> pfl_nreset,
			pfl_flash_access_request	=> pfl_flash_access_request,
			pfl_flash_access_granted	=> pfl_flash_access_granted,
			
			flash_ncs 						=> flash_ncs,
			flash_sck 						=> flash_sck, 
			flash_io0 						=> flash_io0,
			flash_io1 						=> flash_io1,
			flash_io2 						=> flash_io2,
			flash_io3 						=> flash_io3,
			
			-- General (Configuration)
			fpga_nstatus					=> fpga_nstatus,
			fpga_conf_done					=> fpga_conf_done,
			pfl_nreconfigure 				=> pfl_nreconfigure,
			fpga_pgm							=> fpga_pgm,
			fpga_nconfig					=> fpga_nconfig,
			dclk								=> fpga_dclk,
			fpga_data						=> fpga_data,
			pfl_reset_watchdog			=> pfl_reset_watchdog,
			pfl_watchdog_error			=> pfl_watchdog_error
		);
	END GENERATE;
	
	PFL_NAND_FLASH: IF (flash_type = "NAND_FLASH") GENERATE
		pfl_nand_inst: alt_pfl_nand_flash
		GENERIC MAP
		(
			-- General
			FLASH_MFC						=> nflash_mfc,
			FEATURES_PGM					=> features_pgm,
			FEATURES_CFG					=> features_cfg,
			FLASH_DATA_WIDTH				=> flash_data_width,
			FLASH_ADDR_WIDTH				=> addr_width,
			TRISTATE_CHECKBOX				=> tristate_checkbox,
			N_FLASH							=> n_flash,
			NAND_SIZE						=> nand_size,
			NRB_ADDR							=> nrb_addr,
			FLASH_ECC_CHECKBOX			=> flash_ecc_checkbox,
			US_UNIT_COUNTER				=> us_unit_counter,

			-- Programming
			PFL_IR_BITS						=> PFL_NAND_FLASH_IR_BITS,
			
			-- Configuration
			OPTION_START_ADDR				=> option_bits_start_address,
			CLK_DIVISOR						=> clk_divisor,
			PAGE_CLK_DIVISOR				=> page_clk_divisor,
			DCLK_DIVISOR					=> dclk_divisor,
			CONF_DATA_WIDTH				=> conf_data_width,
			DCLK_CREATE_DELAY				=> dclk_create_delay,
			
			-- Configuration (Error Handling)
			SAFE_MODE_HALT					=> safe_mode_halt,
			SAFE_MODE_RETRY				=> safe_mode_retry,
			SAFE_MODE_REVERT				=> safe_mode_revert,
			SAFE_MODE_REVERT_ADDR		=> safe_mode_revert_addr,
			
			-- Configuration
			CONF_WAIT_TIMER_WIDTH		=> conf_wait_timer_width,
			DECOMPRESSOR_MODE				=> decompressor_mode,
			
			-- Configuration (RSU Watchdog)
			PFL_RSU_WATCHDOG_ENABLED	=> pfl_rsu_watchdog_enabled,	
			RSU_WATCHDOG_COUNTER			=> rsu_watchdog_counter
		)
		PORT MAP
		(
			-- General
			pfl_nreset						=> pfl_nreset,
			pfl_flash_access_granted	=> pfl_flash_access_granted,
			pfl_flash_access_request	=> pfl_flash_access_request,
			
			-- General (Configuration)
			pfl_clk							=> pfl_clk,
			fpga_nstatus					=> fpga_nstatus,
			fpga_conf_done					=> fpga_conf_done,
			pfl_nreconfigure				=> pfl_nreconfigure,
			fpga_pgm							=> fpga_pgm,
			fpga_nconfig					=> fpga_nconfig,
			dclk								=> fpga_dclk,
			fpga_data						=> fpga_data,
			pfl_reset_watchdog			=> pfl_reset_watchdog,
			pfl_watchdog_error			=> pfl_watchdog_error,
			
			-- NAND flash (General)
			flash_io							=> flash_io,

			-- NAND flash (Flash Programming)
			flash_nce						=> flash_nce(0),
			flash_nwe						=> flash_nwe,
			flash_noe						=> flash_noe,
			flash_cle						=> flash_cle,
			flash_ale						=> flash_ale
		);
	END GENERATE;
	
	CFI_DUMMY_WIRE: IF (flash_type = "CFI_FLASH" or flash_type = "NAND_FLASH") GENERATE
		flash_ncs <= (others => 'X');
		flash_sck <= (others => 'X');
		flash_io0 <= (others => 'X');
		flash_io1 <= (others => 'X');
		flash_io2 <= (others => 'X');
		flash_io3 <= (others => 'X');
	END GENERATE;

	QUAD_IO_FLASH_DUMMY_WIRE: IF (flash_type = "QUAD_SPI_FLASH" or flash_type = "NAND_FLASH") GENERATE
		flash_addr <= (others => 'X');
		flash_data <= (others => 'X');
		flash_nreset <= 'X';
		flash_clk <= 'X';
		flash_nadv <= 'X';
	END GENERATE;
	
	QUAD_IO_FLASH_DUMMY_WIRE_1: IF (flash_type = "QUAD_SPI_FLASH") GENERATE
		flash_nce <= (others => 'X');
		flash_noe <= 'X';
		flash_nwe <= 'X';
	END GENERATE;
	
	NAND_DUMMY_WIRE: IF (flash_type = "CFI_FLASH" or flash_type = "QUAD_SPI_FLASH") GENERATE
		flash_io <= (others => 'X');
		flash_cle <= 'X';
		flash_ale <= 'X';
	END GENERATE;
	
END ARCHITECTURE;
