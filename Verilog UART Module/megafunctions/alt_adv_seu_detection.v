// synthesis VERILOG_INPUT_VERSION VERILOG_2001

/* alt_adv_seu_detection module
	This  top level Advanced SEU Detection feature module. It  instantiates either 
	internal processor configuration - when SEU location reporting and lookup is 
	performed by FPGA using external memory interface, or 
	external processor configuration - when SEU location lookup is determined by 
	the external unit (such as microproccessor)
*/
module alt_adv_seu_detection
(
	clk,
	nreset,

	mem_addr,
	mem_rd,
	mem_bytesel,
	mem_wait,
	mem_data,
	mem_critical,

	critical_error,
	noncritical_error,
	crcerror_core,
	crcerror_pin,
	
	emr_data,
	emr_cache_ack,
	emr_cache_int,
	
	cache_fill_level,
	cache_full,
	cache_comparison_off
	
);

	parameter mem_addr_width = 32;
	parameter error_clock_divisor = 256;
	parameter error_delay_cycles = 0;
	parameter clock_frequency = 50;
	parameter cache_depth = 10;
	parameter enable_virtual_jtag = 1;
	parameter start_address = 0;
	parameter use_memory_interface = 1;
	parameter intended_device_family = "UNUSED";
	parameter lpm_hint = "UNUSED";
	parameter lpm_type = "alt_adv_seu_detection";
	parameter emr_data_width = 35;
	
	localparam mem_data_width = 32;

	input clk;
	input nreset;
	
	output [mem_addr_width-1:0] mem_addr;
	output mem_rd;
	output [3:0] mem_bytesel;
	input mem_wait;
	input [mem_data_width-1:0] mem_data;
	input mem_critical;
	input cache_comparison_off;
	
	output noncritical_error;
	output critical_error;
	output crcerror_core;
	output crcerror_pin;
	
	input emr_cache_ack;
	output emr_cache_int;
	
	output [3:0] cache_fill_level;
	output cache_full;

	output [emr_data_width-1:0] emr_data;

	generate
		localparam emr_reg_width = (intended_device_family == "UNUSED" || 
								intended_device_family == "Stratix III" ||
								intended_device_family == "Stratix IV" ||
								intended_device_family == "Arria II GZ" ) ? 7'd46 : 7'd67;

		if ( use_memory_interface ) begin 
			alt_adv_seu_detection_proc_int asd_processor_internal ( 
				.clk(clk),
				.nreset(nreset),

				.mem_addr(mem_addr),
				.mem_rd(mem_rd),
				.mem_wait(mem_wait),
				.mem_data(mem_data),
				.mem_bytesel(mem_bytesel),
				.mem_critical(mem_critical),

				.critical_error(critical_error),
				.noncritical_error(noncritical_error),
				.crcerror_core(crcerror_core),
				.crcerror_pin(crcerror_pin),
				
				.cache_comparison_off(cache_comparison_off)
			);
			defparam 
				asd_processor_internal.intended_device_family = intended_device_family,
				asd_processor_internal.mem_addr_width = mem_addr_width,
				asd_processor_internal.error_clock_divisor = error_clock_divisor,
				asd_processor_internal.error_delay_cycles = error_delay_cycles,
				asd_processor_internal.clock_frequency = clock_frequency,
				asd_processor_internal.cache_depth = cache_depth,
				asd_processor_internal.start_address = start_address,
				asd_processor_internal.enable_virtual_jtag = enable_virtual_jtag,
				asd_processor_internal.emr_reg_width = emr_reg_width;
				
			assign emr_cache_int = 0;	
			assign emr_data = 0;	
			assign cache_fill_level = 0;	
			assign cache_full = 0;	

		end
		else begin 
			alt_adv_seu_detection_proc_ext asd_processor_external ( 
				.clk(clk),
				.nreset(nreset),

				.emr_cache_ack(emr_cache_ack),
				.emr_cache_int(emr_cache_int),
				
				.emr_data(emr_data),

				.critical_error(critical_error),

				.cache_fill_level(cache_fill_level),
				.cache_full(cache_full),
				.cache_comparison_off(cache_comparison_off)
			);
			defparam 
				asd_processor_external.intended_device_family = intended_device_family,
				asd_processor_external.error_clock_divisor = error_clock_divisor,
				asd_processor_external.error_delay_cycles = error_delay_cycles,
				asd_processor_external.clock_frequency = clock_frequency,
				asd_processor_external.cache_depth = cache_depth,
				asd_processor_external.enable_virtual_jtag = enable_virtual_jtag,
				asd_processor_external.emr_reg_width = emr_reg_width;
				
			assign mem_rd = 0;	
			assign mem_addr = 0;	
			assign mem_bytesel = 0;	
			assign noncritical_error = 0;	
			assign crcerror_core = 0;	
			assign crcerror_pin = 0;

		end		
	endgenerate	

endmodule


/*
 Low level modules used by both alt_adv_seu_detection_proc_int and alt_adv_seu_detection_proc_ext modules
*/
module oneshot (
	clk,
	reset,
	in,
	out
	);

	input clk;
	input reset;
	input in;
	output out;

	reg last /* synthesis preserve */;
	always @(posedge clk or posedge reset)
	begin
		if (reset)
			last = 1'b0;
		else
			last = in;
	end
	assign out = ~last && in;
	
endmodule

module source_probe (
	probe,
	source
	);

	parameter width = 1;
	input [width-1:0] probe;
	output [width-1:0] source;
	
	parameter instance_id = "NONE";

	altsource_probe altsource_probe_component (
							.probe (probe),
							.source (source)
							);
	defparam
	altsource_probe_component.enable_metastability = "NO",
	altsource_probe_component.instance_id = instance_id,
	altsource_probe_component.probe_width = width,
	altsource_probe_component.sld_auto_instance_index = "YES",
	altsource_probe_component.sld_instance_index = 0,
	altsource_probe_component.source_initial_value = "0",
	altsource_probe_component.source_width = width;
endmodule

module probe (
	probe
	);

	parameter width = 1;
	input [width-1:0] probe;
	
	parameter instance_id = "NONE";

	altsource_probe altsource_probe_component (
							.probe (probe)
							);
	defparam
	altsource_probe_component.enable_metastability = "NO",
	altsource_probe_component.instance_id = instance_id,
	altsource_probe_component.probe_width = width,
	altsource_probe_component.sld_auto_instance_index = "YES",
	altsource_probe_component.sld_instance_index = 0,
	altsource_probe_component.source_initial_value = "0",
	altsource_probe_component.source_width = 0;
endmodule

module crcblock_atom (
	inclk,
	crcerror,
	regout,
	shiftnld	
	);
	
	parameter intended_device_family = "Stratix III";
	parameter error_clock_divisor = 2;
	parameter error_delay_cycles = 0;

	input wire inclk;
	input wire shiftnld;
	
	output wire crcerror;
	output wire regout;

	generate
		if  ( (intended_device_family == "Stratix III") ||
				(intended_device_family == "Arria II GZ") ||
				(intended_device_family == "Stratix IV") ) begin: generate_crcblock_atom
			stratixiii_crcblock emr_atom (
					.clk(inclk),
					.shiftnld(shiftnld),
					.regout(regout),
					.crcerror(crcerror)
				);
			defparam
				emr_atom.error_delay = error_delay_cycles,
				emr_atom.oscillator_divider = error_clock_divisor;
		end
		else if ( (intended_device_family == "Arria V") ||
					 (intended_device_family == "Cyclone V") ) begin: generate_crcblock_atom
			arriav_crcblock emr_atom (
					.clk(inclk),
					.shiftnld(shiftnld),
					.regout(regout),
					.crcerror(crcerror)
				);
			defparam
				emr_atom.error_delay = error_delay_cycles,
				emr_atom.oscillator_divider = error_clock_divisor;
		end
		else begin: generate_crcblock_atom
			stratixv_crcblock emr_atom (
					.clk(inclk),
					.shiftnld(shiftnld),
					.regout(regout),
					.crcerror(crcerror)
				);
			defparam
				emr_atom.error_delay = error_delay_cycles,
				emr_atom.oscillator_divider = error_clock_divisor;
		end
	endgenerate			

endmodule
