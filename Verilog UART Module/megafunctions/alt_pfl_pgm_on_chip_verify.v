module alt_pfl_pgm_on_chip_verify 
(
	vjtag_tck, vjtag_tdi, vjtag_virtual_state_sdr, vjtag_virtual_state_uir,
	vjtag_virtual_state_udr, vjtag_virtual_state_cdr, vjtag_ir_in, 
	flash_data_in, ip_flash_data_in, crc_verify_enable, vjtag_tdo
)
			/* synthesis altera_attribute = "SUPPRESS_DA_RULE_INTERNAL=C106"*/;
parameter 	DATA_WIDTH 			= 16;
parameter 	PFL_IR_BITS 		= 5;

parameter [PFL_IR_BITS-1:0] IR_INFO = 'h11; 							// 1_0001
parameter [PFL_IR_BITS-1:0] IR_READ_DATA = 'h12; 					// 1_0010
parameter [PFL_IR_BITS-1:0] IR_FIFOSM_EXIT = 'h0F; 				// 0_1111
parameter [PFL_IR_BITS-1:0] IR_LOAD_RESET_SHIFT = 'h1C; 			// 1_1100
parameter [PFL_IR_BITS-1:0] IR_INC_COUNTER = 'h1D; 				// 1_1101


input vjtag_tck;
input vjtag_tdi;
input vjtag_virtual_state_sdr;
input vjtag_virtual_state_uir;
input vjtag_virtual_state_udr;
input vjtag_virtual_state_cdr;
input [PFL_IR_BITS-1:0] vjtag_ir_in;
input [DATA_WIDTH-1:0] flash_data_in;
input [DATA_WIDTH-1:0] ip_flash_data_in;

reg [DATA_WIDTH-1:0] flash_data_in_reg;

always @(posedge vjtag_tck) begin
	if(read_data_instruction & vjtag_virtual_state_cdr) 
		flash_data_in_reg = flash_data_in;
end
			
output vjtag_tdo;
output crc_verify_enable = load_reset_shift_instruction;

reg [15:0] verify_status;
reg [3:0] counter_q;
wire status = (flash_data_in_reg == ip_flash_data_in);
wire load_pattern1 = (vjtag_ir_in == IR_INFO);
wire load_pattern2 = (vjtag_ir_in == IR_FIFOSM_EXIT);
wire read_data_instruction = (vjtag_ir_in == IR_READ_DATA);
wire load_reset_shift_instruction = (vjtag_ir_in == IR_LOAD_RESET_SHIFT);
wire load_inc_counter_instruction = (vjtag_ir_in == IR_INC_COUNTER);


lpm_counter status_counter (
	.clock(vjtag_tck),
	.cnt_en(load_inc_counter_instruction & vjtag_virtual_state_uir),
	.sclr(load_reset_shift_instruction & vjtag_virtual_state_uir),
	.q(counter_q)
);
defparam
	status_counter.lpm_type = "LPM_COUNTER",
	status_counter.lpm_direction = "UP",
	status_counter.lpm_width = 4;
	
lpm_shiftreg status_shifter (
	.clock(vjtag_tck),
	.enable(load_reset_shift_instruction & (vjtag_virtual_state_uir | vjtag_virtual_state_sdr)),
	.load(load_reset_shift_instruction & vjtag_virtual_state_uir),
	.data(verify_status),
	.shiftin(vjtag_tdi),
	.shiftout(vjtag_tdo)
);
defparam
	status_shifter.lpm_type = "LPM_SHIFTREG",
	status_shifter.lpm_width = 16,
	status_shifter.lpm_direction = "RIGHT";
	

always @(posedge vjtag_tck) begin
	if(load_reset_shift_instruction & vjtag_virtual_state_uir)
		verify_status = 16'hFFFF;
	else if(load_pattern1 & vjtag_virtual_state_uir)
		verify_status = 16'hA5A5;
	else if(load_pattern2 & vjtag_virtual_state_uir)
		verify_status = 16'hC3C3;
	else if(read_data_instruction & vjtag_virtual_state_udr) begin
		if(counter_q == 4'd0)
			verify_status[0] = verify_status[0] & status;
		else if(counter_q == 4'd1)
			verify_status[1] = verify_status[1] & status;
		else if(counter_q == 4'd2)
			verify_status[2] = verify_status[2] & status;
		else if(counter_q == 4'd3)
			verify_status[3] = verify_status[3] & status;
		else if(counter_q == 4'd4)
			verify_status[4] = verify_status[4] & status;
		else if(counter_q == 4'd5)
			verify_status[5] = verify_status[5] & status;
		else if(counter_q == 4'd6)
			verify_status[6] = verify_status[6] & status;
		else if(counter_q == 4'd7)
			verify_status[7] = verify_status[7] & status;
		else if(counter_q == 4'd8)
			verify_status[8] = verify_status[8] & status;
		else if(counter_q == 4'd9)
			verify_status[9] = verify_status[9] & status;
		else if(counter_q == 4'd10)
			verify_status[10] = verify_status[10] & status;
		else if(counter_q == 4'd11)
			verify_status[11] = verify_status[11] & status;
		else if(counter_q == 4'd12)
			verify_status[12] = verify_status[12] & status;
		else if(counter_q == 4'd13)
			verify_status[13] = verify_status[13] & status;
		else if(counter_q == 4'd14)
			verify_status[14] = verify_status[14] & status;
		else
			verify_status[15] = verify_status[15] & status;
	end
end

endmodule 
