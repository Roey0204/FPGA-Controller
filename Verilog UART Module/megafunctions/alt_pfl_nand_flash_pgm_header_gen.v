////////////////////////////////////////////////////////////////////
//
//   ALT_PFL_NAND_FLASH_PGM_HEADER_GEN
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
// This module contains the PFL Programming NAND flash read-back header compression
//************************************************************

// synthesis VERILOG_INPUT_VERSION VERILOG_2001

module alt_pfl_nand_flash_pgm_header_gen
(
	clr,
	clk,
	datain,
	counter_en,
	shiften,
	shiftout,
	toggle
);

	parameter FLASH_DATA_WIDTH = 8; 
	localparam HEADER_WIDTH = 8;
	localparam COUNTER_SIZE = (FLASH_DATA_WIDTH == 8) ? 8 : 7;

	input clr, clk, counter_en, shiften;
	input [FLASH_DATA_WIDTH-1:0] datain; 
	output shiftout, toggle;

	reg one_diff, zero_diff, out_flag0, out_flag1, busy;
	reg [HEADER_WIDTH-1:0] r; 

	assign toggle = ~busy && clk;

	// compare 0xFF
	always @(posedge clr or posedge busy or posedge clk) begin
		if (clr || busy) begin
			out_flag1 <= 1'b1;
		end
		else begin
			case(FLASH_DATA_WIDTH)
				8:	if(datain == 8'hFF) out_flag1 <= 1'b1; 
					else out_flag1 <= 1'b0;
				16:	if(datain == 16'hFFFF) out_flag1 <= 1'b1;
					else out_flag1 <= 1'b0;
				default: out_flag1 <= 1'b1;
			endcase
		end
	end

	// compare 0x00
	always @(posedge clr or posedge busy or posedge clk) begin
		if (clr || busy) begin
			out_flag0 <= 1'b1;
		end
		else begin
			case(FLASH_DATA_WIDTH)
				8:	if(datain == 8'h0) out_flag0 <= 1'b1;
					else out_flag0 <= 1'b0;
				16:	if(datain == 16'h0) out_flag0 <= 1'b1;
					else out_flag0 <= 1'b0;
				default: out_flag0 <= 1'b1;
			endcase
		end
	end

	always @(negedge busy or negedge out_flag1) begin
		if (~out_flag1)
			one_diff <= 1'b1;
		else
			one_diff <= 1'b0;
	end

	always @(negedge busy or negedge out_flag0) begin
		if (~out_flag0)
			zero_diff <= 1'b1;
		else
			zero_diff <= 1'b0;
	end

	assign shiftout = r[0];
	always @(posedge clr or posedge clk) begin
		if (clr) begin
			busy <= 1'b1;
			r <= 0;
		end
		else begin
			if (shiften) begin
				busy <= 1'b1;
				{r[HEADER_WIDTH-1:1],r[0]} <= {r[0],r[HEADER_WIDTH-1:1]};
			end
			else if (counter_en) begin
				case(FLASH_DATA_WIDTH)
					8:	begin
							case (header_counter_q)
								//Initialization				
								0:		begin
										busy <= 1'b0;
										r <= 0;
										end
								
								//Group of 128 bytes
								32:		busy <= 1'b1;
								33:		begin
										r[7] <= (zero_diff==0 || one_diff==0) ? 1'b1:1'b0;
										r[3] <= (one_diff==0) ? 1'b1:1'b0; 
										busy <= 1'b0;
										end
								65:		busy <= 1'b1;
								66:		begin
										r[6] <= (zero_diff==0 || one_diff==0) ? 1'b1:1'b0;
										r[2] <= (one_diff==0) ? 1'b1:1'b0; 
										busy <= 1'b0;
										end				
								98:		busy <= 1'b1;
								99:		begin
										r[5] <= (zero_diff==0 || one_diff==0) ? 1'b1:1'b0;
										r[1] <= (one_diff==0) ? 1'b1:1'b0; 
										busy <= 1'b0;
										end
								131:	busy <= 1'b1;
								132:	begin
										r[4] <= (zero_diff==0 || one_diff==0) ? 1'b1:1'b0;
										r[0] <= (one_diff==0) ? 1'b1:1'b0;
										busy <= 1'b1;
										end
								133:	busy <= 1'b1;
								default:
									busy <= 1'b0;	
							endcase
						end
					16:begin
							case (header_counter_q)
								//Initialization				
								0:		begin
										busy <= 1'b0;
										r <= 0;
										end
								
								//Group of 64 words
								16:		busy <= 1'b1;
								17:		begin
										r[7] <= (zero_diff==0 || one_diff==0) ? 1'b1:1'b0;
										r[3] <= (one_diff==0) ? 1'b1:1'b0; 
										busy <= 1'b0;
										end
								33:		busy <= 1'b1;
								34:		begin
										r[6] <= (zero_diff==0 || one_diff==0) ? 1'b1:1'b0;
										r[2] <= (one_diff==0) ? 1'b1:1'b0; 
										busy <= 1'b0;
										end				
								50:		busy <= 1'b1;
								51:		begin
										r[5] <= (zero_diff==0 || one_diff==0) ? 1'b1:1'b0;
										r[1] <= (one_diff==0) ? 1'b1:1'b0; 
										busy <= 1'b0;
										end
								67:	busy <= 1'b1;
								68:	begin
										r[4] <= (zero_diff==0 || one_diff==0) ? 1'b1:1'b0;
										r[0] <= (one_diff==0) ? 1'b1:1'b0;
										busy <= 1'b1;
										end
								69:	busy <= 1'b1;
								default:
									busy <= 1'b0;	
							endcase
						end
					default: 
						busy <= 1'b1;
				endcase
			end
			else begin
				busy <= 1'b1;
			end
		end
	end

	reg [COUNTER_SIZE-1:0] header_counter_q;
	lpm_counter addr_counter (
			.clock(clk),
			.cnt_en(counter_en),
			.sclr(~counter_en),
			.q(header_counter_q)
	);
	defparam
	addr_counter.lpm_type = "LPM_COUNTER",
	addr_counter.lpm_direction= "UP",
	addr_counter.lpm_width = COUNTER_SIZE;

endmodule 