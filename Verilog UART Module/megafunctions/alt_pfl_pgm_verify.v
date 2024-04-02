module alt_pfl_pgm_verify 
(
	vjtag_tck, vjtag_tdi, vjtag_virtual_state_sdr, vjtag_virtual_state_uir,
	reset_crc_register, vjtag_ir_in, flash_data_in, vjtag_tdo, 
	crc_verify_enable, addr_count
)
			/* synthesis altera_attribute = "SUPPRESS_DA_RULE_INTERNAL=C106"*/;


parameter 	DATA_WIDTH 			= 16;
parameter 	PFL_IR_BITS 		= 5;
localparam 	VERIFY_BYTE_SIZE 	= 12; // 2048 dec = 800 hex (need 12 bits)
localparam 	CRC_SIZE 			= 16;

// State Machine
parameter CRC_SAME 			= 3'h0;
parameter CRC_INIT 			= 3'h1;
parameter CRC_DUMMY 			= 3'h2;
parameter CRC_EXTRA_DUMMY 	= 3'h3;
parameter CRC_ADDR 			= 3'h4;

reg [2:0] current_state;
reg [2:0] next_state;

parameter [PFL_IR_BITS-1:0] ir_reset_crc = 'h1C; // 11100
parameter [PFL_IR_BITS-1:0] ir_reset_crc_dummy = 'h1E; // 11110
parameter [PFL_IR_BITS-1:0] ir_crc_output = 'h1D; // 11101

wire crc_reset_inst = (vjtag_ir_in == ir_reset_crc || vjtag_ir_in == ir_reset_crc_dummy)? 1'b1 : 1'b0;
wire crc_output_inst = vjtag_ir_in == ir_crc_output ? 1'b1 : 1'b0;
wire crc_need_extra_dummy = vjtag_ir_in == ir_reset_crc_dummy ? 1'b1 : 1'b0;

input vjtag_tck;
input vjtag_tdi;
input vjtag_virtual_state_sdr;
input vjtag_virtual_state_uir;
input reset_crc_register;
input [PFL_IR_BITS-1:0] vjtag_ir_in;
input [DATA_WIDTH-1:0] flash_data_in;
			
output vjtag_tdo;
output crc_verify_enable;
output addr_count;

reg crc_output_reg_sout;
reg bypass_reg_sout;
wire [15:0] dataout_wire;

assign crc_verify_enable = crc_reset_inst | crc_output_inst; 
assign vjtag_tdo = crc_output_inst ? crc_output_reg_sout : bypass_reg_sout;

initial 
begin
crc_ena_reg = 1'b0;
addr_counter_q = {VERIFY_BYTE_SIZE{1'b0}};
flash_data_in_reg = {8{1'b0}};
crc_on_process = 1'b0;
end

reg crc_on_process;

always @(posedge vjtag_tck)
begin
	if (vjtag_virtual_state_uir) begin
		if (crc_reset_inst) 
			crc_on_process = 1'b1;
		else
			crc_on_process = 1'b0;
	end
end

reg crc_ena_reg;
always @(posedge vjtag_tck)
begin
	if (current_state == CRC_ADDR)
		crc_ena_reg = 1'b1;
	else
		crc_ena_reg = 1'b0;
end

wire [7:0] flash_data_in_wire;
reg  [7:0] flash_data_in_reg;
generate
	if (DATA_WIDTH == 8) begin
		assign flash_data_in_wire = flash_data_in;
		assign addr_count = current_state == CRC_ADDR;
	end
	else if (DATA_WIDTH == 16) begin
		assign flash_data_in_wire = addr_counter_q[0] ? flash_data_in[15:8] : flash_data_in[7:0];
		assign addr_count = (current_state == CRC_ADDR) & addr_counter_q[0];
	end
	else begin // assume this is 32 bit
		assign flash_data_in_wire = (addr_counter_q[1:0] == 2'b11) ? flash_data_in[31:24] : 
												(addr_counter_q[1:0] == 2'b10) ? flash_data_in[23:16] :
												(addr_counter_q[1:0] == 2'b01) ? flash_data_in[15:8] : flash_data_in[7:0];
		assign addr_count = (current_state == CRC_ADDR) & (addr_counter_q[1:0] == 2'b11);
	end
endgenerate

always @(posedge vjtag_tck)
begin
	if (current_state == CRC_ADDR) begin
		flash_data_in_reg = flash_data_in_wire;
	end
end

reg [VERIFY_BYTE_SIZE-1:0] addr_counter_q;
wire crc_stop_process = addr_counter_q[VERIFY_BYTE_SIZE-1];
wire addr_counter_en = current_state == CRC_ADDR;
lpm_counter addr_counter (
		.clock(vjtag_tck),
		.cnt_en(crc_on_process & addr_counter_en & ~crc_stop_process),
		.sclr(reset_crc_register),
		.q(addr_counter_q)
);
defparam
addr_counter.lpm_type = "LPM_COUNTER",
addr_counter.lpm_direction= "UP",
addr_counter.lpm_width = VERIFY_BYTE_SIZE;

alt_pfl_crc_calculate calculate_crc (
	.clk(vjtag_tck),
	.ena(crc_ena_reg),
	.clr(reset_crc_register & !crc_reset_inst & !crc_output_inst),
	.d(flash_data_in_reg),
	.shiftenable(crc_output_inst & vjtag_virtual_state_sdr),
	.shiftin(vjtag_tdi),
	.shiftout(crc_output_reg_sout)
);

lpm_shiftreg bypass_reg (
	.clock(vjtag_tck),
	.enable(!crc_reset_inst & !crc_output_inst),
	.shiftin(vjtag_tdi),
	.shiftout(bypass_reg_sout)
);
defparam
bypass_reg.lpm_type = "LPM_SHIFTREG",
bypass_reg.lpm_width = 1,
bypass_reg.lpm_direction = "RIGHT";

always @(reset_crc_register, crc_reset_inst, crc_output_inst, current_state, crc_on_process,
			crc_stop_process, crc_need_extra_dummy)
begin
	if(reset_crc_register | (~crc_reset_inst & ~crc_output_inst))
		next_state = CRC_INIT;
	else begin
		case (current_state)
			CRC_INIT:
				if (crc_on_process & !crc_stop_process)
					next_state = CRC_DUMMY;
				else
					next_state = CRC_SAME;
			CRC_DUMMY:
				if (crc_stop_process)
					next_state = CRC_SAME;
				else begin
					if (crc_need_extra_dummy)
						next_state = CRC_EXTRA_DUMMY;
					else
						next_state = CRC_ADDR;
				end
			CRC_EXTRA_DUMMY:
				if (crc_stop_process)
					next_state = CRC_SAME;
				else
					next_state = CRC_ADDR;
			CRC_ADDR:
				if (crc_stop_process)
					next_state = CRC_INIT;
				else
					next_state = CRC_DUMMY;
			default:
				next_state = CRC_INIT;
		endcase
	end
end

always @(posedge vjtag_tck)
begin
	if(reset_crc_register) begin
		current_state = CRC_INIT;
	end
	else begin
		if (next_state != CRC_SAME) begin
			current_state = next_state;
		end
	end
end

endmodule 