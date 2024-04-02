////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_CFG_FLASH_RESET
//
//  Copyright (C) 1991-2013 Altera Corporation
//  Your use of Altera Corporation's design tools, logic functions  
//  and other software and tools, and its AMPP partner logic  
//  functions, and any output files from any of the foregoing  
//  (including device programming or simulation files), and any  
//  associated documentation or information are expressly subject  
//  to the terms and conditions of the Altera Program License  
//  Subscription Agreement, Altera MegaCore Function License  
//  Agreement, or other applicable license agreement, including,  
//  without limitation, that your use is for the sole purpose of  
//  programming logic devices manufactured by Altera and sold by  
//  Altera or its authorized distributors.  Please refer to the  
//  applicable agreement for further details. 
//  
//  Quartus II 13.0.0 Build 156 04/24/2013 
//
//
//
////////////////////////////////////////////////////////////////////

//************************************************************
// Description:
//
// This module contains the PFL spansion flash nreset block
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_cfg_flash_reset (
	pfl_clk,
	pfl_nreset,
	assert_flash_nreset,
	enable_operation
	
);
	parameter FLASH_NRESET_COUNTER = 1;
	parameter COUNTER_WIDTH =(log2(FLASH_NRESET_COUNTER) + 2); 

	wire [COUNTER_WIDTH-1:0]total_bit_count;
	wire [COUNTER_WIDTH-1:0]internal_total_bit_count;
	wire disable_count,internal_disable_count;
	reg pfl_nreset_reg;

	input	pfl_clk;
	input	pfl_nreset;

	output	assert_flash_nreset;
	output  enable_operation;

	always @(posedge pfl_clk)
	begin
		pfl_nreset_reg = pfl_nreset;
	end

	lpm_counter bit_counter 
		(
			.clock(pfl_clk),
			.clk_en(~internal_disable_count & pfl_nreset),  
			.cnt_en(1'b1),			
			.updown(1'b1),		   
			.aclr(~pfl_nreset_reg), 
			.q(total_bit_count) 	
		);
	defparam
	bit_counter.lpm_width = COUNTER_WIDTH; 

	assign disable_count=(total_bit_count>FLASH_NRESET_COUNTER  )  ? 1'b1 : 1'b0;
	assign assert_flash_nreset =disable_count;
	assign internal_disable_count=( total_bit_count==(FLASH_NRESET_COUNTER + FLASH_NRESET_COUNTER) ) ? 1'b1 : 1'b0;
	assign  enable_operation=internal_disable_count;

	
	function integer log2;
		input integer value;
		begin
			for (log2=0; value>0; log2=log2+1) 
					value = value >> 1;
		end
	endfunction
	
endmodule	