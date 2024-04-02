`timescale 1ps/1ps


//--------------------------------------------------------------------------
// Module Name     : altera_mult_add_rtl
//
// Description     : Main module for altera_mult_add_rtl component
//--------------------------------------------------------------------------
module altera_mult_add_rtl (
		dataa, 
		datab,
		datac,
		scanina,
		scaninb,
		sourcea,
		sourceb,
		clock3, 
		clock2, 
		clock1, 
		clock0, 
		aclr3, 
		aclr2, 
		aclr1, 
		aclr0, 
		ena3, 
		ena2, 
		ena1, 
		ena0, 
		signa, 
		signb, 
		addnsub1, 
		addnsub3, 
		result, 
		scanouta, 
		scanoutb,
		mult01_round,
		mult23_round,
		mult01_saturation,
		mult23_saturation,
		addnsub1_round,
		addnsub3_round,
		mult0_is_saturated,
		mult1_is_saturated,
		mult2_is_saturated,
		mult3_is_saturated,
		output_round,
		chainout_round,
		output_saturate,
		chainout_saturate,
		overflow,
		chainout_sat_overflow,
		chainin,
		zero_chainout,
		rotate,
		shift_right,
		zero_loopback,
		accum_sload,
		sload_accum,
		coefsel0,
		coefsel1,
		coefsel2,
		coefsel3
	);

	//==========================================================
	// Altmult_add parameters declaration
	//==========================================================
	// general setting parameters
	parameter extra_latency                   = 0;
	parameter dedicated_multiplier_circuitry  = "AUTO";
	parameter dsp_block_balancing             = "AUTO";
	parameter selected_device_family          = "Stratix V";
	parameter lpm_type                        = "altmult_add";
	parameter lpm_hint                        = "UNUSED";
	
	
	// Input A related parameters
	parameter width_a  = 1;
	
	parameter input_register_a0  = "UNREGISTERED";
	parameter input_aclr_a0      = "NONE";
	parameter input_source_a0    = "DATAA";

	parameter input_register_a1  = "UNREGISTERED";
	parameter input_aclr_a1      = "NONE";
	parameter input_source_a1    = "DATAA";

	parameter input_register_a2  = "UNREGISTERED";
	parameter input_aclr_a2      = "NONE";
	parameter input_source_a2    = "DATAA";

	parameter input_register_a3  = "UNREGISTERED";
	parameter input_aclr_a3      = "NONE";
	parameter input_source_a3    = "DATAA";
	
	
	// Input B related parameters 
	parameter width_b  = 1;
	
	parameter input_register_b0  = "UNREGISTERED";
	parameter input_aclr_b0      = "NONE";
	parameter input_source_b0    = "DATAB";

	parameter input_register_b1  = "UNREGISTERED";
	parameter input_aclr_b1      = "NONE";
	parameter input_source_b1    = "DATAB";

	parameter input_register_b2  = "UNREGISTERED";
	parameter input_aclr_b2      = "NONE";
	parameter input_source_b2    = "DATAB";

	parameter input_register_b3  = "UNREGISTERED";
	parameter input_aclr_b3      = "NONE";
	parameter input_source_b3    = "DATAB";
	
	
	// Input C related parameters 
	parameter width_c  = 1;
	
	parameter input_register_c0  = "UNREGISTERED";
	parameter input_aclr_c0      = "NONE";
	
	parameter input_register_c1  = "UNREGISTERED";
	parameter input_aclr_c1      = "NONE";
	
	parameter input_register_c2  = "UNREGISTERED";
	parameter input_aclr_c2      = "NONE";
	
	parameter input_register_c3  = "UNREGISTERED";
	parameter input_aclr_c3      = "NONE";
	
	
	// Output related parameters
	parameter width_result     = 34;
	parameter output_register  = "UNREGISTERED";
	parameter output_aclr      = "NONE";
	
	
	// Signed related parameters
	parameter port_signa        = "PORT_UNUSED";
	parameter representation_a  = "UNSIGNED";
	
	parameter signed_register_a           = "UNREGISTERED";
	parameter signed_aclr_a               = "NONE";
	parameter signed_pipeline_register_a  = "UNREGISTERED";
	parameter signed_pipeline_aclr_a      = "NONE";
	
	parameter port_signb        = "PORT_UNUSED";
	parameter representation_b  = "UNSIGNED";
	
	parameter signed_register_b           = "UNREGISTERED";
	parameter signed_aclr_b               = "NONE";
	parameter signed_pipeline_register_b  = "UNREGISTERED";
	parameter signed_pipeline_aclr_b      = "NONE";
	
	
	// Multiplier related parameters
	parameter number_of_multipliers  = 1;
	
	parameter multiplier1_direction  = "NONE";
	parameter multiplier3_direction  = "NONE";
	
	parameter multiplier_register0  = "UNREGISTERED";
	parameter multiplier_aclr0      = "NONE";
	parameter multiplier_register1  = "UNREGISTERED";
	parameter multiplier_aclr1      = "NONE";
	parameter multiplier_register2  = "UNREGISTERED";
	parameter multiplier_aclr2      = "NONE";
	parameter multiplier_register3  = "UNREGISTERED";
	parameter multiplier_aclr3      = "NONE";
	
	
	// Adder related parameters
	parameter port_addnsub1                          = "PORT_UNUSED";
	parameter addnsub_multiplier_register1           = "UNREGISTERED";
	parameter addnsub_multiplier_aclr1               = "NONE";
	parameter addnsub_multiplier_pipeline_register1  = "UNREGISTERED";
	parameter addnsub_multiplier_pipeline_aclr1      = "NONE";
   
	parameter port_addnsub3                          = "PORT_UNUSED";
	parameter addnsub_multiplier_register3           = "UNREGISTERED";
	parameter addnsub_multiplier_aclr3	             = "NONE";
	parameter addnsub_multiplier_pipeline_register3  = "UNREGISTERED";
	parameter addnsub_multiplier_pipeline_aclr3      = "NONE";

	
	// Rounding related parameters
	parameter adder1_rounding                   = "NO";
	parameter addnsub1_round_register           = "UNREGISTERED";
	parameter addnsub1_round_aclr               = "NONE";
	parameter addnsub1_round_pipeline_register  = "UNREGISTERED";
	parameter addnsub1_round_pipeline_aclr      = "NONE";
	
	parameter adder3_rounding                   = "NO";
	parameter addnsub3_round_register           = "UNREGISTERED";
	parameter addnsub3_round_aclr               = "NONE";
	parameter addnsub3_round_pipeline_register  = "UNREGISTERED";
	parameter addnsub3_round_pipeline_aclr		  = "NONE";
	
	parameter multiplier01_rounding  = "NO";
	parameter mult01_round_register  = "UNREGISTERED";
	parameter mult01_round_aclr      = "NONE";
	
	parameter multiplier23_rounding  = "NO";
	parameter mult23_round_register  = "UNREGISTERED";
	parameter mult23_round_aclr      = "NONE";
	
	parameter width_msb                       = 17;
	
	parameter output_rounding                 = "NO";
	parameter output_round_type               = "NEAREST_INTEGER";
	parameter output_round_register           = "UNREGISTERED";
	parameter output_round_aclr               = "NONE";
	parameter output_round_pipeline_register  = "UNREGISTERED";
	parameter output_round_pipeline_aclr      = "NONE";
	
	parameter chainout_rounding                 = "NO";
	parameter chainout_round_register           = "UNREGISTERED";
	parameter chainout_round_aclr               = "NONE";
	parameter chainout_round_pipeline_register  = "UNREGISTERED";
	parameter chainout_round_pipeline_aclr      = "NONE";
	parameter chainout_round_output_register    = "UNREGISTERED";
	parameter chainout_round_output_aclr        = "NONE";
	
	
	// Saturation related parameters
	parameter multiplier01_saturation     = "NO";
	parameter mult01_saturation_register  = "UNREGISTERED";
	parameter mult01_saturation_aclr      = "NONE";
	
	parameter multiplier23_saturation     = "NO";
	parameter mult23_saturation_register  = "UNREGISTERED";
	parameter mult23_saturation_aclr      = "NONE";
	
	parameter port_mult0_is_saturated  = "NONE";
	parameter port_mult1_is_saturated  = "NONE";
	parameter port_mult2_is_saturated  = "NONE";
	parameter port_mult3_is_saturated  = "NONE";
	
	parameter width_saturate_sign = 1;
	
	parameter output_saturation                  = "NO";
	parameter port_output_is_overflow            = "PORT_UNUSED";
	parameter output_saturate_type               = "ASYMMETRIC";
	parameter output_saturate_register           = "UNREGISTERED";
	parameter output_saturate_aclr               = "NONE";
	parameter output_saturate_pipeline_register  = "UNREGISTERED";
	parameter output_saturate_pipeline_aclr      = "NONE";
	
	parameter chainout_saturation                  = "NO";
	parameter port_chainout_sat_is_overflow        = "PORT_UNUSED";
	parameter chainout_saturate_register           = "UNREGISTERED";
	parameter chainout_saturate_aclr               = "NONE";
	parameter chainout_saturate_pipeline_register  = "UNREGISTERED";
	parameter chainout_saturate_pipeline_aclr      = "NONE";
	parameter chainout_saturate_output_register    = "UNREGISTERED";
	parameter chainout_saturate_output_aclr        = "NONE";
	
	
	// Scanchain related parameters
	parameter scanouta_register  = "UNREGISTERED";
	parameter scanouta_aclr      = "NONE";
	
	
	// Chain (chainin and chainout) related parameters
	parameter width_chainin  = 1;
	
	parameter chainout_adder     = "NO";
	parameter chainout_register  = "UNREGISTERED";
	parameter chainout_aclr      = "NONE";
	
	parameter zero_chainout_output_register  = "UNREGISTERED";
	parameter zero_chainout_output_aclr      = "NONE";
	
	
	// Rotate & shift related parameters
	parameter shift_mode  = "NO";
	
	parameter rotate_register           = "UNREGISTERED";
	parameter rotate_aclr               = "NONE";
	parameter rotate_pipeline_register  = "UNREGISTERED";
	parameter rotate_pipeline_aclr      = "NONE";
	parameter rotate_output_register    = "UNREGISTERED";
	parameter rotate_output_aclr        = "NONE";
	
	parameter shift_right_register           = "UNREGISTERED";
	parameter shift_right_aclr               = "NONE";
	parameter shift_right_pipeline_register  = "UNREGISTERED";
	parameter shift_right_pipeline_aclr      = "NONE";
	parameter shift_right_output_register    = "UNREGISTERED";
	parameter shift_right_output_aclr        = "NONE";
	
	
	// Loopback related parameters
	parameter zero_loopback_register           = "UNREGISTERED";
	parameter zero_loopback_aclr               = "NONE";
	parameter zero_loopback_pipeline_register  = "UNREGISTERED";
	parameter zero_loopback_pipeline_aclr      = "NONE";
	parameter zero_loopback_output_register    = "UNREGISTERED";
	parameter zero_loopback_output_aclr        = "NONE";
	
	
	// Accumulator and loadconst related parameters
	parameter accumulator      = "NO";
	parameter accum_direction  = "ADD";
	parameter loadconst_value = 0;
	parameter use_sload_accum_port 	= "NO";
	
	parameter accum_sload_register           = "UNREGISTERED";
	parameter accum_sload_aclr               = "NONE";
	parameter accum_sload_pipeline_register  = "UNREGISTERED";
	parameter accum_sload_pipeline_aclr      = "NONE";
	
	parameter loadconst_control_register = "UNREGISTERED";
	parameter loadconst_control_aclr	 = "NONE";
	
	parameter double_accum      = "NO";
	
	// Systolic related parameters
	parameter systolic_delay1 = "UNREGISTERED";
	parameter systolic_delay3 = "UNREGISTERED";
	parameter systolic_aclr1 = "NONE";
	parameter systolic_aclr3= "NONE";
	
	// Preadder related parameters
	parameter preadder_mode  = "SIMPLE";
	
	parameter preadder_direction_0  = "ADD";
	parameter preadder_direction_1  = "ADD";
	parameter preadder_direction_2  = "ADD";
	parameter preadder_direction_3  = "ADD";
	
	parameter width_coef  = 1;
	
	parameter coefsel0_register  = "UNREGISTERED";
	parameter coefsel0_aclr	     = "NONE";
	parameter coefsel1_register  = "UNREGISTERED";
	parameter coefsel1_aclr	     = "NONE";
	parameter coefsel2_register  = "UNREGISTERED";
	parameter coefsel2_aclr	     = "NONE";
	parameter coefsel3_register  = "UNREGISTERED";
	parameter coefsel3_aclr	     = "NONE";

	parameter coef0_0  = 0;
	parameter coef0_1  = 0;
	parameter coef0_2  = 0;
	parameter coef0_3  = 0;
	parameter coef0_4  = 0;
	parameter coef0_5  = 0;
	parameter coef0_6  = 0;
	parameter coef0_7  = 0;

	parameter coef1_0  = 0;
	parameter coef1_1  = 0;
	parameter coef1_2  = 0;
	parameter coef1_3  = 0;
	parameter coef1_4  = 0;
	parameter coef1_5  = 0;
	parameter coef1_6  = 0;
	parameter coef1_7  = 0;

	parameter coef2_0  = 0;
	parameter coef2_1  = 0;
	parameter coef2_2  = 0;
	parameter coef2_3  = 0;
	parameter coef2_4  = 0;
	parameter coef2_5  = 0;
	parameter coef2_6  = 0;
	parameter coef2_7  = 0;

	parameter coef3_0  = 0;
	parameter coef3_1  = 0;
	parameter coef3_2  = 0;
	parameter coef3_3  = 0;
	parameter coef3_4  = 0;
	parameter coef3_5  = 0;
	parameter coef3_6  = 0;
	parameter coef3_7  = 0;	

	//==========================================================
	// Internal parameters declaration
	//==========================================================
	// Width related parameters
		// Register related width parameters
		parameter width_clock_all_wire_msb = 3;   // Clock wire total width
		parameter width_aclr_all_wire_msb = 3;    // Aclr wire total width
		parameter width_ena_all_wire_msb = 3;     // Clock enable wire total width
		
		// Data input width related parameters
		parameter width_a_total_msb  = (width_a * number_of_multipliers) - 1;   // Total width of dataa input
		parameter width_a_msb  = width_a - 1;     // MSB for splited dataa width
		
		parameter width_b_total_msb  = (width_b * number_of_multipliers) - 1;   // Total width of data input
		parameter width_b_msb  = width_b - 1;     // MSB for splited datab width
		
		parameter width_c_total_msb  = (width_c * number_of_multipliers) - 1;   // Total width of datac input
		parameter width_c_msb  = width_c - 1;     // MSB for splited datac width

		// Scanchain width related parameters
		parameter width_scanina = width_a;                  // Width for scanina port
		parameter width_scanina_msb = width_scanina - 1;    // MSB for scanina port
		
		parameter width_scaninb = width_b;                  // Width for scaninb port
		parameter width_scaninb_msb = width_scaninb - 1;    // MSB for scaninb port
		
		parameter width_sourcea_msb = number_of_multipliers -1;    // MSB for sourcea port
		parameter width_sourceb_msb = number_of_multipliers -1;    // MSB for sourceb port
		
		parameter width_scanouta_msb = width_a -1;    // MSB for scanouta port
		parameter width_scanoutb_msb = width_b -1;    // MSB for scanoutb port

		// chain (chainin and chainout) width related parameters
		parameter width_chainin_msb = width_chainin - 1;    // MSB for chainin port
		
		// Result width related parameters
		parameter width_result_msb = width_result - 1;      // MSB for result port
		
		// Coef width related parameters
		parameter width_coef_msb = width_coef -1;           // MSB for selected coef output
	
	
	// Internal width related parameters
		// Input data width related parameters
		parameter dataa_split_ext_require = (port_signa === "PORT_USED") ? 1 : 0;        // Determine dynamic sign extension 
		parameter dataa_port_sign = port_signa;                                          // Dynamic sign port for dataa
		parameter width_a_ext = (dataa_split_ext_require == 1) ? width_a + 1 : width_a ; // Sign extension when require
		parameter width_a_ext_msb = width_a_ext - 1;                                     // MSB for dataa
		
		parameter datab_split_ext_require = (preadder_mode === "SIMPLE") ? ((port_signb === "PORT_USED") ? 1 : 0):
		                                                                   ((port_signa === "PORT_USED") ? 1 : 0) ;   // Determine dynamic sign extension 
		parameter datab_port_sign = (preadder_mode === "SIMPLE") ? port_signb : port_signa;    // Dynamic sign port for dataa
		parameter width_b_ext = (datab_split_ext_require == 1) ? width_b + 1 : width_b;        // Sign extension when require
		parameter width_b_ext_msb = width_b_ext - 1;                                           // MSB for datab
		
		parameter coef_ext_require = (port_signb === "PORT_USED") ? 1 : 0;                // Determine dynamic sign extension 
		parameter coef_port_sign  = port_signb;                                           // Dynamic sign port for coef
		parameter width_coef_ext = (coef_ext_require == 1) ? width_coef + 1 : width_coef; // Sign extension when require
		parameter width_coef_ext_msb = width_coef_ext - 1;                                // MSB for coef
		
		parameter datac_split_ext_require = (port_signb === "PORT_USED") ? 1 : 0;        // Determine dynamic sign extension 
		parameter datac_port_sign = port_signb;                                          // Dynamic sign port for datac
		parameter width_c_ext = (datac_split_ext_require == 1) ? width_c + 1 : width_c;  // Sign extension when require
		parameter width_c_ext_msb = width_c_ext - 1;                                     // MSB for datac
		
		
		// Scanchain width related parameters
		parameter width_scanchain = (port_signa === "PORT_USED") ? width_scanina + 1 : width_scanina;  // Sign extension when require
		parameter width_scanchain_msb = width_scanchain - 1;
		parameter scanchain_port_sign = port_signa;                                      // Dynamic sign port for scanchain
		
		
		// Preadder width related parameters
		parameter preadder_representation = (port_signa === "PORT_USED") ? "SIGNED" : representation_a;   // Representation for preadder adder
		
		parameter width_preadder_input_a = (input_source_a0 === "SCANA")? width_scanchain : width_a_ext;   // Preadder input a selection width
		parameter width_preadder_input_a_msb = width_preadder_input_a - 1;                                      // MSB for preadder input a
		
		parameter width_preadder_adder_result = (width_preadder_input_a > width_b_ext)? width_preadder_input_a + 1 : width_b_ext + 1; // Adder extension by one for the largest width
		
		parameter width_preadder_output_a = (preadder_mode === "INPUT" || preadder_mode === "SQUARE" || preadder_mode === "COEF")? width_preadder_adder_result:
		                                     width_preadder_input_a;              // Preadder first output width
		parameter width_preadder_output_a_msb = width_preadder_output_a - 1;      // MSB for preadder first output width
		
		parameter width_preadder_output_b = (preadder_mode === "INPUT")? width_c_ext :
		                                    (preadder_mode === "SQUARE")? width_preadder_adder_result :
		                                    (preadder_mode === "COEF" || preadder_mode === "CONSTANT")? width_coef_ext :
														width_b_ext;                         // Preadder second output width
		parameter width_preadder_output_b_msb = width_preadder_output_b - 1;     // MSB for preadder second output width
		
		
		// Multiplier width related parameters
		parameter multiplier_input_representation_a = (port_signa === "PORT_USED") ? "SIGNED" : representation_a;   // Representation for multiplier first input
		parameter multiplier_input_representation_b = (preadder_mode === "SQUARE") ? multiplier_input_representation_a :
		                                              (port_signb === "PORT_USED") ? "SIGNED" : representation_b;   // Representation for multiplier second input
		
		parameter width_mult_source_a = width_preadder_output_a;        // Multiplier first input width
		parameter width_mult_source_a_msb = width_mult_source_a - 1;    // MSB for multiplier first input width
		
		parameter width_mult_source_b = width_preadder_output_b;        // Multiplier second input width
		parameter width_mult_source_b_msb = width_mult_source_b - 1;    // MSB for multiplier second input width
		
		parameter width_mult_result = width_mult_source_a + width_mult_source_b +
		                              ((multiplier_input_representation_a === "UNSIGNED") ? 1 : 0) +
		                              ((multiplier_input_representation_b === "UNSIGNED") ? 1 : 0);   // Multiplier result width
		parameter width_mult_result_msb = width_mult_result -1;                                       // MSB for multiplier result width
		
		
		// Adder width related parameters
		parameter width_adder_source = width_mult_result;             // Final adder or systolic adder source width
		parameter width_adder_source_msb = width_adder_source - 1;    // MSB for adder source width
		
		parameter width_adder_result = width_adder_source + ((number_of_multipliers <= 2)? 1 : 2);  // Adder extension (2 when excute two level adder, else 1) and sign extension
		parameter width_adder_result_msb = width_adder_result - 1;                                  // MSB for adder result
		
		
		// Chainout adder width related parameters
		parameter width_chainin_ext = width_result - width_chainin;
		
		// Original output width related parameters
		parameter width_original_result = width_adder_result;               // The original result width without truncated
		parameter width_original_result_msb = width_original_result - 1;    // The MSB for original result 
		
		// Output width related parameters
		parameter result_ext_width    = (width_result_msb > width_original_result_msb) ? width_result_msb - width_original_result_msb : 1;   // Width that require to extend
		
		parameter width_result_output = (width_result_msb > width_original_result_msb) ? width_result : width_original_result + 1;   // Output width that ready for truncated
		parameter width_result_output_msb = width_result_output - 1;    // MSB for output width that ready for truncated
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Data input related ports
	input [width_a_total_msb : 0] dataa;
	input [width_b_total_msb : 0] datab;
	input [width_c_total_msb : 0] datac;
	
	// Scanchain related ports
	input [width_scanina_msb : 0] scanina;
	input [width_scaninb_msb : 0] scaninb;
	input [width_sourcea_msb : 0] sourcea;
	input [width_sourceb_msb : 0] sourceb;
	
	output [width_scanouta_msb : 0] scanouta;
	output [width_scanoutb_msb : 0] scanoutb;
	
	// Clock related ports
	input clock0, clock1, clock2, clock3;
	
	// Clear related ports
	input aclr0, aclr1, aclr2, aclr3;
	
	// Clock enable related ports
	input ena0, ena1, ena2, ena3;
	
	// Signals control related ports
	input signa, signb;
	input addnsub1, addnsub3;
	
	// Rounding related ports
	input mult01_round, mult23_round;
	input addnsub1_round, addnsub3_round;
	input output_round;
	input chainout_round;
	
	// Saturation related ports
	input mult01_saturation, mult23_saturation;
	input output_saturate;
	input chainout_saturate;
	
	output mult0_is_saturated, mult1_is_saturated, mult2_is_saturated, mult3_is_saturated;
	output chainout_sat_overflow;
	
	// chain (chainin and chainout) related port
	input [width_chainin_msb : 0] chainin;
	input zero_chainout;
	
	// Rotate & shift related port
	input rotate;
	input shift_right;
	
	// Loopback related port
	input zero_loopback;
	
	// Accumulator related port
	input accum_sload;
	input sload_accum;
	
	// Preadder related port
	input [2 : 0] coefsel0, coefsel1, coefsel2, coefsel3;
	
	// Output related port
	output [width_result_msb : 0] result;
	output overflow;
	
	//==========================================================
	// Declar default driver for unused output port
	//==========================================================
	// Scanchain. Saturation and Output related ports
	
	// synthesis read_comments_as_HDL on
	//tri0 [width_scanouta_msb : 0] scanouta;
	//tri0 [width_scanoutb_msb : 0] scanoutb;
	//
	//tri0 mult0_is_saturated, mult1_is_saturated, mult2_is_saturated, mult3_is_saturated;
	//tri0 chainout_sat_overflow;
	//
	//tri0 overflow;
	// synthesis read_comments_as_HDL off
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Register related wires and registers
	wire [width_clock_all_wire_msb : 0] clock_all_wire = {clock3, clock2, clock1, clock0};
	wire [width_aclr_all_wire_msb : 0] aclr_all_wire = {aclr3, aclr2, aclr1, aclr0};
	wire [width_ena_all_wire_msb : 0] ena_all_wire = {ena3, ena2, ena1, ena0};
	
	// Input A related wires and registers
	wire [width_a_total_msb : 0] dataa_split_input = dataa;
	wire [width_a_ext_msb : 0] dataa_0_input, dataa_1_input, dataa_2_input, dataa_3_input;  // Wire contain data a after split, reg and ext
	
	// Input B related wires and registers
	wire [width_b_total_msb : 0] datab_split_input = datab;
	wire [width_b_ext_msb : 0] datab_0_input, datab_1_input, datab_2_input, datab_3_input;  // Wire contain data b after split, reg and ext
	
	// Input C related wires and registers
	wire [width_c_total_msb : 0] datac_split_input = datac;
	wire [width_c_ext_msb : 0] datac_0_input, datac_1_input, datac_2_input, datac_3_input;  // Wire contain data b after split, reg and ext
	
	// Input coef related wires and registers
	wire [width_coef_ext_msb : 0] coefsel0_input, coefsel1_input, coefsel2_input, coefsel3_input;  // Wire contain data b after split, reg and ext
	
	// Scanchain related wires and registers
	wire [width_scanchain_msb : 0] scanchain_output_0, scanchain_output_1, scanchain_output_2, scanchain_output_3;
	wire [width_scanchain_msb : 0] scanout_wire;
	
	// Signed related wire and registers
	wire signa_wire, signb_wire;  // Wire contain sign signal, before being used
	
	wire dataa_sign_wire = signa_wire;
	wire datab_sign_wire = (preadder_mode === "SIMPLE") ? signb_wire : signa_wire; // Sign representation for data a and b
	wire datac_sign_wire = signb_wire;
	wire scanchain_sign_wire = signa_wire;
	
	// Preadder related wires and registers
	wire [width_preadder_input_a_msb : 0] preadder_dataa_0_input, preadder_dataa_1_input, preadder_dataa_2_input, preadder_dataa_3_input;
	wire [width_preadder_output_a_msb : 0] preadder_output_a0, preadder_output_a1, preadder_output_a2, preadder_output_a3;
	wire [width_preadder_output_b_msb : 0] preadder_output_b0, preadder_output_b1, preadder_output_b2, preadder_output_b3;
	
	// Multiplier related wires and registers
	wire [width_mult_source_a_msb : 0] mult_input_source_a0, mult_input_source_a1, mult_input_source_a2, mult_input_source_a3;
	wire [width_mult_source_b_msb : 0] mult_input_source_b0, mult_input_source_b1, mult_input_source_b2, mult_input_source_b3;
	wire [width_mult_result_msb : 0] mult_output_0, mult_output_1, mult_output_2, mult_output_3;
	
	// Adder related wires and registers
	wire [width_adder_source_msb : 0] adder_source_0, adder_source_1, adder_source_2, adder_source_3;
	wire [width_adder_result_msb : 0] adder_output;
	
	// Systolic related wires and registers
	wire [width_result_msb : 0] systolic_adder_output;
	
	// Result related wires and registers
	wire [width_result_output_msb : 0] result_wire;
	wire [width_result_msb : 0] result_wire_ext;
	
	wire [width_result_msb : 0] result_reg_input;
	wire [width_result_msb : 0] result_reg_output;
	
	wire [width_result_msb : 0] output_wire;
	
	// Accumulator related wires and registers
	wire [width_result_msb : 0] accum_cal_source;
	wire [width_result_msb : 0] accum_prev_source;
	
	wire [width_result_msb : 0] accum_output;
	
	// Chainout adder related wires and registers
	wire [width_result_msb : 0] chainout_adder_output;
	
	
	
	//==========================================================
	// Assignment
	//==========================================================
	// Scanchain assignment
	assign scanouta = scanout_wire[width_scanouta_msb : 0];
	
	// Preadder assignment
	assign preadder_dataa_0_input = (input_source_a0 === "SCANA")? scanchain_output_0 : dataa_0_input;
	assign preadder_dataa_1_input = (input_source_a1 === "SCANA")? scanchain_output_1 : dataa_1_input;
	assign preadder_dataa_2_input = (input_source_a2 === "SCANA")? scanchain_output_2 : dataa_2_input;
	assign preadder_dataa_3_input = (input_source_a3 === "SCANA")? scanchain_output_3 : dataa_3_input;
	
	// Multiplier assignment
	assign mult_input_source_a0 = preadder_output_a0;
	assign mult_input_source_a1 = preadder_output_a1;
	assign mult_input_source_a2 = preadder_output_a2;
	assign mult_input_source_a3 = preadder_output_a3;
	
	assign mult_input_source_b0 = preadder_output_b0;
	assign mult_input_source_b1 = preadder_output_b1;
	assign mult_input_source_b2 = preadder_output_b2;
	assign mult_input_source_b3 = preadder_output_b3;
	
	// Final adder and systolic assignmnet
	assign adder_source_0 = mult_output_0;
	assign adder_source_1 = mult_output_1;
	assign adder_source_2 = mult_output_2;
	assign adder_source_3 = mult_output_3;
	
	// adder (result) related assignment
	assign result_wire = {{result_ext_width{adder_output[width_adder_result_msb]}},adder_output};
	assign result_wire_ext = (systolic_delay1 === "UNREGISTERED") ? result_wire[width_result_msb : 0] : systolic_adder_output;
	
	// Accumulator assignmnet
	assign accum_cal_source = result_wire_ext;
	assign accum_prev_source = output_wire;
	
	// Register (clock and aclr) assignment
	assign result_reg_input = chainout_adder_output;
	assign output_wire = result_reg_output;  
	
	// Final output assignment
	assign result = output_wire;  

	
	//==========================================================
	// Sign handling part
	//==========================================================
	// Sign signal registered
	ama_register_function #(.width_data_in(1), .width_data_out(1), .register_clock(signed_register_a), .register_aclr(signed_aclr_a))
	signa_reg_block(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .data_in(signa), .data_out(signa_wire));
	
	ama_register_function #(.width_data_in(1), .width_data_out(1), .register_clock(signed_register_b), .register_aclr(signed_aclr_b))
	signb_reg_block(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .data_in(signb), .data_out(signb_wire) );
	
	
	//==========================================================
	// Input data handling part
	//==========================================================
	// Dataa split and register function
	ama_data_split_reg_ext_function #(.width_data_in(width_a), .width_data_out(width_a_ext), .register_clock_0(input_register_a0), .register_aclr_0(input_aclr_a0), .register_clock_1(input_register_a1), .register_aclr_1(input_aclr_a1), .register_clock_2(input_register_a2), .register_aclr_2(input_aclr_a2), .register_clock_3(input_register_a3), .register_aclr_3(input_aclr_a3), .number_of_multipliers(number_of_multipliers), .port_sign(dataa_port_sign))
	dataa_split(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .sign(dataa_sign_wire), .data_in(dataa_split_input), .data_out_0(dataa_0_input), .data_out_1(dataa_1_input), .data_out_2(dataa_2_input), .data_out_3(dataa_3_input));
	
	// Datab split and register function
	ama_data_split_reg_ext_function #(.width_data_in(width_b), .width_data_out(width_b_ext), .register_clock_0(input_register_b0), .register_aclr_0(input_aclr_b0), .register_clock_1(input_register_b1), .register_aclr_1(input_aclr_b1), .register_clock_2(input_register_b2), .register_aclr_2(input_aclr_b2), .register_clock_3(input_register_b3), .register_aclr_3(input_aclr_b3), .number_of_multipliers(number_of_multipliers), .port_sign(datab_port_sign))
	datab_split(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .sign(datab_sign_wire), .data_in(datab_split_input), .data_out_0(datab_0_input), .data_out_1(datab_1_input), .data_out_2(datab_2_input), .data_out_3(datab_3_input));
	
	// Datac split and register function
	ama_data_split_reg_ext_function #(.width_data_in(width_c), .width_data_out(width_c_ext), .register_clock_0(input_register_c0), .register_aclr_0(input_aclr_c0), .register_clock_1(input_register_c1), .register_aclr_1(input_aclr_c1), .register_clock_2(input_register_c2), .register_aclr_2(input_aclr_c2), .register_clock_3(input_register_c3), .register_aclr_3(input_aclr_c3), .number_of_multipliers(number_of_multipliers), .port_sign(datac_port_sign))
	datac_split(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .sign(datac_sign_wire), .data_in(datac_split_input), .data_out_0(datac_0_input), .data_out_1(datac_1_input), .data_out_2(datac_2_input), .data_out_3(datac_3_input));
	
	// Coef selection and register function
	generate
		if (preadder_mode === "CONSTANT" || preadder_mode === "COEF")
		begin
			wire coef_sign_wire = signb_wire;
			
			ama_coef_reg_ext_function #(.width_coef(width_coef), .width_data_out(width_coef_ext), .register_clock_0(coefsel0_register), .register_aclr_0(coefsel0_aclr), .register_clock_1(coefsel1_register), .register_aclr_1(coefsel1_aclr), .register_clock_2(coefsel2_register), .register_aclr_2(coefsel2_aclr), .register_clock_3(coefsel3_register), .register_aclr_3(coefsel3_aclr), .number_of_multipliers(number_of_multipliers), .port_sign(coef_port_sign),
			.coef0_0(coef0_0), .coef0_1(coef0_1), .coef0_2(coef0_2), .coef0_3(coef0_3), .coef0_4(coef0_4), .coef0_5(coef0_5), .coef0_6(coef0_6), .coef0_7(coef0_7),
			.coef1_0(coef1_0), .coef1_1(coef1_1), .coef1_2(coef1_2), .coef1_3(coef1_3), .coef1_4(coef1_4), .coef1_5(coef1_5), .coef1_6(coef1_6), .coef1_7(coef1_7),
			.coef2_0(coef2_0), .coef2_1(coef2_1), .coef2_2(coef2_2), .coef2_3(coef2_3), .coef2_4(coef2_4), .coef2_5(coef2_5), .coef2_6(coef2_6), .coef2_7(coef2_7),
			.coef3_0(coef3_0), .coef3_1(coef3_1), .coef3_2(coef3_2), .coef3_3(coef3_3), .coef3_4(coef3_4), .coef3_5(coef3_5), .coef3_6(coef3_6), .coef3_7(coef3_7))
			coefsel_reg_ext_block(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .sign(coef_sign_wire), .coefsel0(coefsel0), .coefsel1(coefsel1), .coefsel2(coefsel2), .coefsel3(coefsel3), .data_out_0(coefsel0_input), .data_out_1(coefsel1_input), .data_out_2(coefsel2_input), .data_out_3(coefsel3_input));
		end
	endgenerate
	
	
	// Scanchain selection and register function
	ama_scanchain #(.width_scanin(width_scanina), .width_scanchain(width_scanchain), .input_register_clock_0(input_register_a0), .input_register_aclr_0(input_aclr_a0), .input_register_clock_1(input_register_a1), .input_register_aclr_1(input_aclr_a1), .input_register_clock_2(input_register_a2), .input_register_aclr_2(input_aclr_a2), .input_register_clock_3(input_register_a3), .input_register_aclr_3(input_aclr_a3), .scanchain_register_clock(scanouta_register), .scanchain_register_aclr(scanouta_aclr), .port_sign(scanchain_port_sign), .number_of_multipliers(number_of_multipliers))
	scanchain_block(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .sign(scanchain_sign_wire), .scanin(scanina), .data_out_0(scanchain_output_0), .data_out_1(scanchain_output_1), .data_out_2(scanchain_output_2), .data_out_3(scanchain_output_3), .scanout(scanout_wire));
	
	
	//==========================================================
	// Preadder part (input selection)
	//==========================================================
	ama_preadder_function #(.preadder_mode(preadder_mode), .width_in_a(width_preadder_input_a), .width_in_b(width_b_ext), .width_in_c(width_c_ext), .width_in_coef(width_coef_ext), .width_result_a(width_preadder_output_a), .width_result_b(width_preadder_output_b), .preadder_direction_0(preadder_direction_0), .preadder_direction_1(preadder_direction_1), .preadder_direction_2(preadder_direction_2), .preadder_direction_3(preadder_direction_3), .representation_preadder_adder(preadder_representation))
	preadder_block(.dataa_in_0(preadder_dataa_0_input), .dataa_in_1(preadder_dataa_1_input), .dataa_in_2(preadder_dataa_2_input), .dataa_in_3(preadder_dataa_3_input), .datab_in_0(datab_0_input), .datab_in_1(datab_1_input), .datab_in_2(datab_2_input), .datab_in_3(datab_3_input), .datac_in_0(datac_0_input), .datac_in_1(datac_1_input), .datac_in_2(datac_2_input), .datac_in_3(datac_3_input), .coef0(coefsel0_input), .coef1(coefsel1_input), .coef2(coefsel2_input), .coef3(coefsel3_input), .result_a0(preadder_output_a0), .result_a1(preadder_output_a1), .result_a2(preadder_output_a2), .result_a3(preadder_output_a3), .result_b0(preadder_output_b0), .result_b1(preadder_output_b1), .result_b2(preadder_output_b2), .result_b3(preadder_output_b3));
	
	
	//==========================================================
	// Multiplier part
	//==========================================================
	// Multiplier function
	ama_multiplier_function #(.width_data_in_a(width_mult_source_a), .width_data_in_b(width_mult_source_b), .multiplier_input_representation_a(multiplier_input_representation_a), .multiplier_input_representation_b(multiplier_input_representation_b), .width_data_out(width_mult_result), .number_of_multipliers(number_of_multipliers), .multiplier_register0(multiplier_register0), .multiplier_aclr0(multiplier_aclr0), .multiplier_register1(multiplier_register1), .multiplier_aclr1(multiplier_aclr1), .multiplier_register2(multiplier_register2), .multiplier_aclr2(multiplier_aclr2), .multiplier_register3(multiplier_register3), .multiplier_aclr3(multiplier_aclr3))
	multiplier_block(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .data_in_a0(mult_input_source_a0), .data_in_a1(mult_input_source_a1), .data_in_a2(mult_input_source_a2), .data_in_a3(mult_input_source_a3), .data_in_b0(mult_input_source_b0), .data_in_b1(mult_input_source_b1), .data_in_b2(mult_input_source_b2), .data_in_b3(mult_input_source_b3), .data_out_0(mult_output_0), .data_out_1(mult_output_1), .data_out_2(mult_output_2), .data_out_3(mult_output_3));
	
	
	//==========================================================
	// Final adder part
	//==========================================================
	// Final adder function
	ama_adder_function #(.width_data_in(width_adder_source), .width_data_out(width_adder_result), .number_of_adder_input(number_of_multipliers), .adder1_direction(multiplier1_direction), .adder3_direction(multiplier3_direction), .representation("SIGNED"), .port_addnsub1(port_addnsub1), .addnsub_multiplier_register1(addnsub_multiplier_register1), .addnsub_multiplier_aclr1(addnsub_multiplier_aclr1), .port_addnsub3(port_addnsub3), .addnsub_multiplier_register3(addnsub_multiplier_register3), .addnsub_multiplier_aclr3(addnsub_multiplier_aclr3))
	final_adder_block (.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .data_in_0(adder_source_0), .data_in_1(adder_source_1), .data_in_2(adder_source_2), .data_in_3(adder_source_3), .data_out(adder_output), .addnsub1(addnsub1), .addnsub3(addnsub3));
	
	
	//==========================================================
	// Systolic part
	//==========================================================
	// Systolic function
	generate
		if (systolic_delay1 != "UNREGISTERED")
		begin
			ama_systolic_adder_function #(.width_data_in(width_adder_source), .width_chainin(width_chainin), .width_data_out(width_result), .number_of_adder_input(number_of_multipliers), .systolic_delay1(systolic_delay1), .systolic_aclr1(systolic_aclr1), .systolic_delay3(systolic_delay3), .systolic_aclr3(systolic_aclr3), .adder1_direction(multiplier1_direction), .adder3_direction(multiplier3_direction), .port_addnsub1(port_addnsub1), .addnsub_multiplier_register1(addnsub_multiplier_register1), .addnsub_multiplier_aclr1(addnsub_multiplier_aclr1), .port_addnsub3(port_addnsub3), .addnsub_multiplier_register3(addnsub_multiplier_register3), .addnsub_multiplier_aclr3(addnsub_multiplier_aclr3))
			systolic_adder_block(.data_in_0(adder_source_0), .data_in_1(adder_source_1), .data_in_2(adder_source_2), .data_in_3(adder_source_3), .chainin(chainin), .clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .data_out(systolic_adder_output), .addnsub1(addnsub1), .addnsub3(addnsub3));
		end
	endgenerate
	
	
	//==========================================================
	// Accumulator part
	//==========================================================
	// Accumulator function
	ama_accumulator_function #(.width_result(width_result), .accumulator(accumulator), .accum_direction(accum_direction), .loadconst_value(loadconst_value), .accum_sload_register(accum_sload_register), .accum_sload_aclr(accum_sload_aclr), .double_accum(double_accum), .output_register(output_register), .output_aclr(output_aclr), .use_sload_accum_port(use_sload_accum_port))
	accumulator_block(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .accum_sload(accum_sload), .sload_accum(sload_accum), .data_result(accum_cal_source), .prev_result(accum_prev_source), .result(accum_output));
	
	parameter width_chainout_adder_output = (chainout_adder === "YES")? width_result : width_chainin;
	//==========================================================
	// Chainout adder part
	//==========================================================
	// Chainout adder function
	generate
		if (chainout_adder === "YES")
		begin
			// Width extend for encryption model, due to encryption model will still compile the hierarchy and cause width mistmatch for the chainin input
			//   This happen when chainin width is not equal to result width
			wire [width_result_msb : 0] chainin_wire = (width_chainin_ext > 0) ? {{width_chainin_ext{1'b0}},chainin} : chainin;
			
			ama_adder_function #(.width_data_in(width_result), .width_data_out(width_result), .number_of_adder_input(2), .adder1_direction("ADD"), .adder3_direction("ADD"), .representation("SIGNED"))
			chainout_adder_block (.data_in_0(chainin_wire), .data_in_1(accum_output), .data_in_2(), .data_in_3(), .data_out(chainout_adder_output), .clock(), .aclr(), .ena(), .addnsub1(), .addnsub3());
		end
		else
		begin
			assign chainout_adder_output = accum_output;
		end
	endgenerate
	
	//==========================================================
	// Register (clock and aclr) part
	//==========================================================
	ama_register_function #(.width_data_in(width_result), .width_data_out(width_result), .register_clock(output_register), .register_aclr(output_aclr))
	output_reg_block(.clock(clock_all_wire), .aclr(aclr_all_wire), .ena(ena_all_wire), .data_in(result_reg_input), .data_out(result_reg_output));
	
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_signed_extension_function
// Use in          : altera_mult_add_rtl
//
// Description     : Registered function with dynamic sign extension
//--------------------------------------------------------------------------
module ama_signed_extension_function (
	data_in,
	data_out
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter representation = "UNSIGNED";          // Representation for the sign extension
	parameter width_data_in = 1;                    // Input data bus width
	parameter width_data_out = width_data_in + 1;   // Output data bus width
	
	// Internal used parameters
	parameter width_data_in_msb = width_data_in - 1;    // MSB for input data
	parameter width_data_out_msb = width_data_out -1;   // MSB for output data
	
	parameter width_data_ext = width_data_in + 1;       // Extend data width
	parameter wdith_data_ext_msb = width_data_ext - 1;  // MSB for extend data width
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Data input port define
	input [width_data_in_msb : 0] data_in;
	
	// Data output port define
	output [width_data_out_msb : 0] data_out;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Bit extension selection wire
	wire data_in_bit_ext = (representation === "UNSIGNED")? 1'b0 :
                          (representation === "SIGNED")? data_in[width_data_in_msb] : 
                           1'bz;  // Decide bit for the extansion
	
	// Extended data wire
	wire [wdith_data_ext_msb : 0] data_ext = {data_in_bit_ext, data_in};
	
	
	//==========================================================
	// Assignment
	//==========================================================
	// Output assignment
	assign data_out = data_ext[width_data_out_msb : 0];
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_dynamic_signed_function
// Use in          : altera_mult_add_rtl
//
// Description     : Determine dynamic sign extension function
//--------------------------------------------------------------------------
module ama_dynamic_signed_function (
	data_in,
	sign,
	data_out
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter port_sign = "PORT_CONNECTIVITY";       // Dynamic sign extension port condition
	parameter width_data_in = 1;                     // Data input bus width
	parameter width_data_out = width_data_in + 1;    // Data output bus width
	
	// Internal used parameters
	parameter width_data_in_msb = width_data_in - 1;     // MSB for input data
	parameter width_data_out_msb = width_data_out -1;    // MSB for output data
	
	parameter width_data_out_wire = width_data_in + 1;              // Output wire width with 1 bit extra
	parameter width_data_out_wire_msb = width_data_out_wire - 1;    // MSB for output wire width
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Input port define
	input [width_data_in_msb : 0] data_in;
	
	// Dynamic sign port define
	input sign;
	
	// Output port define
	output [width_data_out_msb : 0] data_out;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Bit extension selection
	wire data_in_bit_ext = (port_sign === "PORT_USED")? ((sign == 1'b0)? 1'b0 : data_in[width_data_in_msb]) :
									1'bz;  // Decide bit for the extansion
	
	// Bit extension wire
	wire [width_data_out_wire_msb : 0] data_out_wire = {data_in_bit_ext, data_in};
	
	
	//==========================================================
	// Assignment
	//==========================================================
	// Output assignment
	assign data_out = data_out_wire[width_data_out_msb : 0];
	
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_register_function
// Use in          : altera_mult_add_rtl
//
// Description     : Asynchronous clear register function
//--------------------------------------------------------------------------
module ama_register_function (
	clock,
	aclr,
	ena,
	data_in,
	data_out
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_data_in = 1;                 // Input data bus width
	parameter width_data_out = 1;                // Output data bus width
	parameter register_clock = "UNREGISTERED";   // Clock for register
	parameter register_aclr = "NONE";          // Aclr for register
	
	// Internal used parameters
	parameter width_data_in_msb = width_data_in - 1;   // MSB for input data
	
	parameter width_data_out_msb = width_data_out -1;  // MSB for output data

	
	//==========================================================
	// Port declaration
	//==========================================================
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Input port define
	input [width_data_in_msb : 0] data_in;
	
	// Output port define
	output [width_data_out_msb : 0] data_out;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Clock that used for registered
	wire clock_used_wire;
	
	// Asynchronous clear that used for registered
	wire aclr_used_wire;
	
	// Clock enable that used for registered
	wire ena_used_wire;
	
	// Input wire
	wire [width_data_in_msb : 0] data_in_wire = data_in;
	
	// Data output after registered
	reg [width_data_out_msb : 0] data_out_wire;
	
	//==========================================================
	// Assignment
	//==========================================================
	assign clock_used_wire  = (register_clock === "CLOCK3")? clock[3] :
                             (register_clock === "CLOCK2")? clock[2] :
                             (register_clock === "CLOCK1")? clock[1] : 
                             (register_clock === "CLOCK0")? clock[0] : "";  // Clock select
	
	assign aclr_used_wire  = (register_aclr === "ACLR3")? aclr[3] : 
                            (register_aclr === "ACLR2")? aclr[2] :
                            (register_aclr === "ACLR1")? aclr[1] : 
                            (register_aclr === "ACLR0")? aclr[0] : ""; // Aclr select
	
	assign ena_used_wire  = (register_clock === "CLOCK3")? ena[3] :
                           (register_clock === "CLOCK2")? ena[2] :
                           (register_clock === "CLOCK1")? ena[1] : 
                           (register_clock === "CLOCK0")? ena[0] : 1'b1;  // Clock enable select
	
	// Output assignment
	assign data_out = (register_clock === "UNREGISTERED")? data_in_wire : data_out_wire;
	
	// Initial output data to prevent tri-state or don't careoutput happen
	initial 
	data_out_wire = {width_data_out{1'b0}};
	
	// Asynchronous clear register section
	always @(posedge clock_used_wire or posedge aclr_used_wire)
	begin
		if (aclr_used_wire == 1'b1 )
			data_out_wire <= {width_data_out{1'b0}};
		else if (ena_used_wire == 1'b1)
			data_out_wire <= data_in_wire;
	end
	
	
	//==========================================================
	// Condition check
	//==========================================================
	initial /* synthesis enable_verilog_initial_construct */
	begin
		if(register_clock != "UNREGISTERED" && register_clock != "CLOCK0" && register_clock != "CLOCK1" && register_clock != "CLOCK2" && register_clock != "CLOCK3")
			$display("Error: Clock source error: illegal value %s", register_clock);
		
		if(register_aclr != "NONE" && register_aclr != "ACLR0" && register_aclr != "ACLR1" && register_aclr != "ACLR2" && register_aclr != "ACLR3" && register_aclr != "UNUSED")
			$display("Error: Asynchronous clear source error: illegal value %s", register_aclr);
	end
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_register_with_ext_function
// Use in          : altera_mult_add_rtl
//
// Description     : Registered function with dynamic sign extension
//--------------------------------------------------------------------------
module ama_register_with_ext_function (
	clock,
	aclr,
	ena,
	sign,
	data_in,
	data_out
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_data_in = 1;                      // Data input bus width
	parameter width_data_out = width_data_in + 1;     // Data output bus width
	
	parameter register_clock = "UNREGISTERED";        // Clock for register
	parameter register_aclr = "NONE";               // Aclr for register
	parameter port_sign = "PORT_CONNECTIVITY";        // Dynamic sign extension port condition
	
	// Internal used parameters
	parameter width_data_in_msb = width_data_in - 1;   // MSB for input data
	
	parameter width_data_out_msb = width_data_out -1;  // MSB for output data
	
	parameter width_sign_ext_output = (port_sign === "PORT_USED")? width_data_in + 1 : width_data_in;   // output with extend or without extend
	parameter width_sign_ext_output_msb = width_sign_ext_output -1;  // MSB for sign extend output
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Dynamic sign port define
	input sign;
	
	// Input port define
	input [width_data_in_msb : 0] data_in;
	
	// Output port define
	output [width_data_out_msb : 0] data_out;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Data after dynamic signed extension
	//wire [width_sign_ext_output_msb : 0] sign_ext_output;
	
	//Register output
	wire [width_data_in_msb : 0] register_output;
	
	//==========================================================
	// Main function execution
	//==========================================================	
	// Register
	ama_register_function #(.width_data_in(width_data_in), .width_data_out(width_data_in), .register_clock(register_clock), .register_aclr(register_aclr))
	data_register_block (.clock(clock), .aclr(aclr), .ena(ena), .data_in(data_in), .data_out(register_output));
	
	// Sign extension
	ama_dynamic_signed_function #(.width_data_in(width_data_in), .width_data_out(width_data_out), .port_sign(port_sign))
	data_signed_extension_block (.data_in(register_output), .sign(sign), .data_out(data_out));
	
	//==========================================================
	// Condition check
	//==========================================================
	initial /* synthesis enable_verilog_initial_construct */
		if( width_sign_ext_output != width_data_out)
		begin
			$display("Error: Function output width and assign output width not same. Happen in ama_register_with_ext_function function for altera_mult_add_rtl");
		end
	
endmodule



//--------------------------------------------------------------------------
// Module Name     : ama_data_split_reg_ext_function
// Use in          : altera_mult_add_rtl
//
// Description     : Split data evenly according to the number of multiplier
//--------------------------------------------------------------------------
module ama_data_split_reg_ext_function (
	clock,
	aclr,
	ena,
	sign,
	data_in,
	data_out_0,
	data_out_1,
	data_out_2,
	data_out_3
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_data_in = 1;                    // Input data bus width
	parameter width_data_out = width_data_in + 1;   // Output data bus width
	
	parameter register_clock_0 = "UNREGISTERED";    // Clock for first data output register
	parameter register_aclr_0 = "NONE";           // Aclr for first data output register
	
	parameter register_clock_1 = "UNREGISTERED";    // Clock for second data output register
	parameter register_aclr_1 = "NONE";           // Aclr for second data output register
	
	parameter register_clock_2 = "UNREGISTERED";    // Clock for third data output register
	parameter register_aclr_2 = "NONE";           // Aclr for third data output register
	
	parameter register_clock_3 = "UNREGISTERED";    // Clock for fourth data output register
	parameter register_aclr_3 = "NONE";           // Aclr for fourth data output register
	
	parameter number_of_multipliers = 1;            // Total number of data going to be splited    
	parameter port_sign = "PORT_CONNECTIVITY";      // Dynamic sign extension port condition
	
	
	// Internal used parameters
	parameter width_data_in_msb = width_data_in - 1;    // MSB of input data
	
	parameter width_data_in_total_msb  = width_data_in * number_of_multipliers - 1;   // MSB of total input data width
	
	parameter width_data_out_msb = width_data_out -1;    // MSB of output data
	
	// Width of the individual splited data width
	parameter width_data_in_0_msb  = width_data_in - 1;
	parameter width_data_in_0_lsb  = 0;
	parameter width_data_in_1_msb  = (number_of_multipliers >= 2)? (width_data_in * 2 - 1) : 0;
	parameter width_data_in_1_lsb  = (number_of_multipliers >= 2)? (width_data_in) : 0;
	parameter width_data_in_2_msb  = (number_of_multipliers >= 3)? (width_data_in * 3 - 1) : 0;
	parameter width_data_in_2_lsb  = (number_of_multipliers >= 3)? (width_data_in * 2) : 0;
	parameter width_data_in_3_msb  = (number_of_multipliers >= 4)? (width_data_in * 4 - 1) : 0;
	parameter width_data_in_3_lsb  = (number_of_multipliers >= 4)? (width_data_in * 3) : 0;
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Dynamic sign port define
	input sign;
	
	// Data input port define
	input [width_data_in_total_msb : 0] data_in;
	
	// Data output port define
	output [width_data_out_msb : 0] data_out_0, data_out_1, data_out_2, data_out_3;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Split data
	wire [width_data_in_msb : 0] data_split_0, data_split_1, data_split_2, data_split_3;
	
	// Split data after registered and dynamic extension
	wire [width_data_out_msb : 0] data_out_wire_0, data_out_wire_1, data_out_wire_2, data_out_wire_3;
	
	
	//==========================================================
	// Assignment
	//==========================================================
	// Data split assignment
	assign data_split_0 = data_in[width_data_in_0_msb : width_data_in_0_lsb];
	assign data_split_1 = (number_of_multipliers >= 2)? data_in[width_data_in_1_msb : width_data_in_1_lsb] : {(width_data_in ){1'bx}};
	assign data_split_2 = (number_of_multipliers >= 3)? data_in[width_data_in_2_msb : width_data_in_2_lsb] : {(width_data_in ){1'bx}};
	assign data_split_3 = (number_of_multipliers == 4)? data_in[width_data_in_3_msb : width_data_in_3_lsb] : {(width_data_in ){1'bx}};
	
	// Output assignment
	assign data_out_0 = data_out_wire_0;
	assign data_out_1 = data_out_wire_1;
	assign data_out_2 = data_out_wire_2;
	assign data_out_3 = data_out_wire_3;
	
	
	//==========================================================
	// Register (clock and aclr) part
	//==========================================================
	ama_register_with_ext_function #(.width_data_in(width_data_in), .width_data_out(width_data_out), .register_clock(register_clock_0), .register_aclr(register_aclr_0), .port_sign(port_sign))
	data_register_block_0(.clock(clock), .aclr(aclr),.ena(ena), .sign(sign), .data_in(data_split_0), .data_out(data_out_wire_0));
	
	ama_register_with_ext_function #(.width_data_in(width_data_in), .width_data_out(width_data_out), .register_clock(register_clock_1), .register_aclr(register_aclr_1), .port_sign(port_sign))
	data_register_block_1(.clock(clock), .aclr(aclr),.ena(ena), .sign(sign), .data_in(data_split_1), .data_out(data_out_wire_1));
	
	ama_register_with_ext_function #(.width_data_in(width_data_in), .width_data_out(width_data_out), .register_clock(register_clock_2), .register_aclr(register_aclr_2), .port_sign(port_sign))
	data_register_block_2(.clock(clock), .aclr(aclr),.ena(ena), .sign(sign), .data_in(data_split_2), .data_out(data_out_wire_2));
	
	ama_register_with_ext_function #(.width_data_in(width_data_in), .width_data_out(width_data_out), .register_clock(register_clock_3), .register_aclr(register_aclr_3), .port_sign(port_sign))
	data_register_block_3(.clock(clock), .aclr(aclr),.ena(ena), .sign(sign), .data_in(data_split_3), .data_out(data_out_wire_3));
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_coef_reg_ext_function
// Use in          : altera_mult_add_rtl
//
// Description     : Contain coef selection function
//--------------------------------------------------------------------------
module ama_coef_reg_ext_function (
	clock,
	aclr,
	ena,
	sign,
	coefsel0,
	coefsel1,
	coefsel2,
	coefsel3,
	data_out_0,
	data_out_1,
	data_out_2,
	data_out_3
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_coef = 1;                      // Coef bus width
	parameter width_data_out = width_coef + 1;     // Coef output bus width
	
	parameter register_clock_0 = "UNREGISTERED";   // Clock for first coefsel register
	parameter register_aclr_0 = "NONE";          // aclr for first coefsel register
	
	parameter register_clock_1 = "UNREGISTERED";   // Clock for second coefsel register
	parameter register_aclr_1 = "NONE";          // aclr for second coefsel register
	
	parameter register_clock_2 = "UNREGISTERED";   // Clock for third coefsel register
	parameter register_aclr_2 = "NONE";          // aclr for third coefsel register
	
	parameter register_clock_3 = "UNREGISTERED";   // Clock for fourth coefsel register
	parameter register_aclr_3 = "NONE";          // aclr for fourth coefsel register
	
	parameter number_of_multipliers = 1;           // Number of coef output
	parameter port_sign = "PORT_CONNECTIVITY";     // Dynamic sign extension port condition
	
	// Internal used parameters
	parameter width_coef_msb = (width_coef > 1) ? width_coef - 1 : 0;   // MSB for coef data
	
	parameter width_data_out_msb = width_data_out -1;   // MSB of output data
	
	parameter width_coef_ext = (port_sign === "PORT_USED") ? width_coef + 1 : width_coef;   // Coef width with extend or without extend
	
	// Inherite parameters (ROM value)
	parameter [width_coef_msb : 0] coef0_0  = 0;   // Coef pre-define value
	parameter [width_coef_msb : 0] coef0_1  = 0;
	parameter [width_coef_msb : 0] coef0_2  = 0;
	parameter [width_coef_msb : 0] coef0_3  = 0;
	parameter [width_coef_msb : 0] coef0_4  = 0;
	parameter [width_coef_msb : 0] coef0_5  = 0;
	parameter [width_coef_msb : 0] coef0_6  = 0;
	parameter [width_coef_msb : 0] coef0_7  = 0;

	parameter [width_coef_msb : 0] coef1_0  = 0;
	parameter [width_coef_msb : 0] coef1_1  = 0;
	parameter [width_coef_msb : 0] coef1_2  = 0;
	parameter [width_coef_msb : 0] coef1_3  = 0;
	parameter [width_coef_msb : 0] coef1_4  = 0;
	parameter [width_coef_msb : 0] coef1_5  = 0;
	parameter [width_coef_msb : 0] coef1_6  = 0;
	parameter [width_coef_msb : 0] coef1_7  = 0;

	parameter [width_coef_msb : 0] coef2_0  = 0;
	parameter [width_coef_msb : 0] coef2_1  = 0;
	parameter [width_coef_msb : 0] coef2_2  = 0;
	parameter [width_coef_msb : 0] coef2_3  = 0;
	parameter [width_coef_msb : 0] coef2_4  = 0;
	parameter [width_coef_msb : 0] coef2_5  = 0;
	parameter [width_coef_msb : 0] coef2_6  = 0;
	parameter [width_coef_msb : 0] coef2_7  = 0;

	parameter [width_coef_msb : 0] coef3_0  = 0;
	parameter [width_coef_msb : 0] coef3_1  = 0;
	parameter [width_coef_msb : 0] coef3_2  = 0;
	parameter [width_coef_msb : 0] coef3_3  = 0;
	parameter [width_coef_msb : 0] coef3_4  = 0;
	parameter [width_coef_msb : 0] coef3_5  = 0;
	parameter [width_coef_msb : 0] coef3_6  = 0;
	parameter [width_coef_msb : 0] coef3_7  = 0;
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Dynamic sign port define
	input sign;
	
	// coefsel input port define
	input [2 : 0] coefsel0, coefsel1, coefsel2, coefsel3;
	
	// Data output port define
	output [width_data_out_msb : 0] data_out_0, data_out_1, data_out_2, data_out_3;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Memory that store the predefine value
	reg [width_coef_msb : 0] coef0 [7:0], coef1 [7:0], coef2 [7:0], coef3 [7:0];
	
	// Register output for coefsel
	wire [2 : 0] coefsel0_reg_out, coefsel1_reg_out, coefsel2_reg_out, coefsel3_reg_out;
	
	// Selected coef value
	wire [width_coef_msb : 0] coef0_wire, coef1_wire, coef2_wire, coef3_wire;

	
	//==========================================================
	// Coef value initialize
	//==========================================================
	initial
	begin
		coef0[0] = coef0_0;   // Assign constant coef value
		coef0[1] = coef0_1;
		coef0[2] = coef0_2;
		coef0[3] = coef0_3;
		coef0[4] = coef0_4;
		coef0[5] = coef0_5;
		coef0[6] = coef0_6;
		coef0[7] = coef0_7;
		
		coef1[0] = coef1_0;
		coef1[1] = coef1_1;
		coef1[2] = coef1_2;
		coef1[3] = coef1_3;
		coef1[4] = coef1_4;
		coef1[5] = coef1_5;
		coef1[6] = coef1_6;
		coef1[7] = coef1_7;
		
		coef2[0] = coef2_0;
		coef2[1] = coef2_1;
		coef2[2] = coef2_2;
		coef2[3] = coef2_3;
		coef2[4] = coef2_4;
		coef2[5] = coef2_5;
		coef2[6] = coef2_6;
		coef2[7] = coef2_7;
		
		coef3[0] = coef3_0;
		coef3[1] = coef3_1;
		coef3[2] = coef3_2;
		coef3[3] = coef3_3;
		coef3[4] = coef3_4;
		coef3[5] = coef3_5;
		coef3[6] = coef3_6;
		coef3[7] = coef3_7;
	end
	
	
	//==========================================================
	// Sign extension part
	//==========================================================
	ama_dynamic_signed_function #(.width_data_in(width_coef),.width_data_out(width_data_out),.port_sign(port_sign))
	coef_ext_block_0(.data_in(coef0_wire), .sign(sign), .data_out(data_out_0));
	
	ama_dynamic_signed_function #(.width_data_in(width_coef),.width_data_out(width_data_out),.port_sign(port_sign))
	coef_ext_block_1(.data_in(coef1_wire), .sign(sign), .data_out(data_out_1));
	
	ama_dynamic_signed_function #(.width_data_in(width_coef),.width_data_out(width_data_out),.port_sign(port_sign))
	coef_ext_block_2(.data_in(coef2_wire), .sign(sign), .data_out(data_out_2));
	
	ama_dynamic_signed_function #(.width_data_in(width_coef),.width_data_out(width_data_out),.port_sign(port_sign))
	coef_ext_block_3(.data_in(coef3_wire), .sign(sign), .data_out(data_out_3));
	
	
	//==========================================================
	// Register (clock and aclr) part
	//==========================================================
	ama_register_function #(.width_data_in(3),.width_data_out(3),.register_clock(register_clock_0),.register_aclr(register_aclr_0))
	coef_register_block_0(.clock(clock),.aclr(aclr),.ena(ena),.data_in(coefsel0),.data_out(coefsel0_reg_out));
	
	ama_register_function #(.width_data_in(3),.width_data_out(3),.register_clock(register_clock_1),.register_aclr(register_aclr_1))
	coef_register_block_1(.clock(clock),.aclr(aclr),.ena(ena),.data_in(coefsel1),.data_out(coefsel1_reg_out));
	
	ama_register_function #(.width_data_in(3),.width_data_out(3),.register_clock(register_clock_2),.register_aclr(register_aclr_2))
	coef_register_block_2(.clock(clock),.aclr(aclr),.ena(ena),.data_in(coefsel2),.data_out(coefsel2_reg_out));
	
	ama_register_function #(.width_data_in(3),.width_data_out(3),.register_clock(register_clock_3),.register_aclr(register_aclr_3))
	coef_register_block_3(.clock(clock),.aclr(aclr),.ena(ena),.data_in(coefsel3),.data_out(coefsel3_reg_out));
	
	
	//==========================================================
	// Assignment
	//==========================================================
	// Coef value selection and truncated into define width
	assign coef0_wire = coef0[coefsel0_reg_out];
	assign coef1_wire = coef1[coefsel1_reg_out];
	assign coef2_wire = coef2[coefsel2_reg_out];
	assign coef3_wire = coef3[coefsel3_reg_out];
	
	
	//==========================================================
	// Condition check
	//==========================================================
	initial /* synthesis enable_verilog_initial_construct */
		if( width_coef_ext != width_data_out)
		begin
			$display("Error: Function output width and assign output width not same. Happen in ama_coef_reg_ext_function function for altera_mult_add_rtl");
		end
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_adder_function
// Use in          : altera_mult_add_rtl
//
// Description     : Add input data with corresponding representation
//                     (data_in_0 + data_in_1) + (data_in_2 + data_in_3)
//--------------------------------------------------------------------------
module ama_adder_function (
	data_in_0,
	data_in_1,
	data_in_2,
	data_in_3,
	data_out,
	clock,
	aclr,
	ena,
	addnsub1,
	addnsub3
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_data_in = 1;             // Input data bus width
	parameter width_data_out = 1;            // Output data bus width
	parameter number_of_adder_input = 1;     // Total of data input to be add
	
	parameter adder1_direction = "NONE";   // First adder direction
	parameter adder3_direction = "NONE";   // Third adder direction
	
	parameter representation = "UNSIGNED";   // Representation for all the adder input
	
	parameter port_addnsub1 = "PORT_CONNECTIVITY";       // Input port addnsub1 parameter
	parameter addnsub_multiplier_register1 = "CLOCK0";   // Clock for addnsub1 signal register
	parameter addnsub_multiplier_aclr1 = "ACLR3";        // Aclr for addnsub1 signal register
	
	parameter port_addnsub3 = "PORT_CONNECTIVITY";       // Input port addnsub3 parameter
	parameter addnsub_multiplier_register3  = "CLOCK0";  // Clock for addnsub3 signal register
	parameter addnsub_multiplier_aclr3 = "ACLR3";        // Aclr for addnsub3 signal register
	
	// Internal used parameters
	parameter width_data_in_msb = width_data_in - 1;    // MSB for input data
	parameter width_data_out_msb = width_data_out -1;   // MSB for output data
	
	parameter width_adder_lvl_1 = width_data_in + 1;           // First level adder result width
	parameter width_adder_lvl_1_msb = width_adder_lvl_1 - 1;   // MSB for first level adder result
	
	parameter width_adder_lvl_2 = width_adder_lvl_1 + 1;       // Second level adder result width
	parameter width_adder_lvl_2_msb = width_adder_lvl_2 - 1;   // MSB for second level adder result
	
	parameter width_data_out_wire = width_data_in + 2;             // General adder result width
	parameter width_data_out_wire_msb = width_data_out_wire - 1;   // MSB for general adder result width
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Data input port define
	input [width_data_in_msb : 0] data_in_0, data_in_1, data_in_2, data_in_3;
	
	// Dynamic addnsub port define
	input addnsub1, addnsub3;
	
	// Data output port define
	output [width_data_out_msb : 0] data_out;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Adder input wire (with or without sign extension)
	wire signed [width_adder_lvl_1_msb : 0] data_in_ext_0, data_in_ext_1, data_in_ext_2, data_in_ext_3;
	
	// First level adder result wire
	wire signed [width_adder_lvl_1_msb : 0] adder_result_0, adder_result_1, adder_result_2, adder_result_3;

	// Second level adder result wire
	wire signed [width_adder_lvl_2_msb : 0] adder_result_ext_0, adder_result_ext_1, adder_result_ext_2, adder_result_ext_3;
	
	// General adder output wire
	wire [width_adder_lvl_2_msb : 0] data_out_wire;
	
	// Register addnsub wire
	wire addnsub1_wire, addnsub3_wire;
	
	//==========================================================
	// Assignment
	//==========================================================
	// First level adder assignment
	assign adder_result_0 = data_in_ext_0;
	
	assign adder_result_1 = (port_addnsub1 == "PORT_USED") ? (addnsub1_wire == 0) ? adder_result_0 - data_in_ext_1 : adder_result_0 + data_in_ext_1:
	                                                         (adder1_direction === "SUB") ? adder_result_0 - data_in_ext_1 : adder_result_0 + data_in_ext_1;
									
	assign adder_result_2 = data_in_ext_2; 
	
	assign adder_result_3 = (port_addnsub3 == "PORT_USED") ? (addnsub3_wire == 0) ? adder_result_2 - data_in_ext_3 : adder_result_2 + data_in_ext_3:
	                                                         (adder3_direction === "SUB") ? adder_result_2 - data_in_ext_3 : adder_result_2 + data_in_ext_3;
	
	// Output assignment (with second level adder assignment)
	assign data_out_wire = (number_of_adder_input == 1) ? adder_result_0 :
	                       (number_of_adder_input == 2) ? adder_result_1 :
	                       (number_of_adder_input == 3) ? adder_result_ext_1 + adder_result_ext_2 :
	                       (number_of_adder_input == 4) ? adder_result_ext_1 + adder_result_ext_3 :
	                       {width_data_out{1'bz}};
	
	// Output data assignmnet (with proper width assign)
	assign data_out = data_out_wire[width_data_out_msb : 0];
	
	
	//==========================================================
	// Sign extension
	//==========================================================
	// First level adder extension
	ama_signed_extension_function #(.representation(representation),.width_data_in(width_data_in),.width_data_out(width_adder_lvl_1))
	first_adder_ext_block_0(.data_in(data_in_0),.data_out(data_in_ext_0));
	
	ama_signed_extension_function #(.representation(representation),.width_data_in(width_data_in),.width_data_out(width_adder_lvl_1))
	first_adder_ext_block_1(.data_in(data_in_1),.data_out(data_in_ext_1));
	
	ama_signed_extension_function #(.representation(representation),.width_data_in(width_data_in),.width_data_out(width_adder_lvl_1))
	first_adder_ext_block_2(.data_in(data_in_2),.data_out(data_in_ext_2));
	
	ama_signed_extension_function #(.representation(representation),.width_data_in(width_data_in),.width_data_out(width_adder_lvl_1))
	first_adder_ext_block_3(.data_in(data_in_3),.data_out(data_in_ext_3));
	
	// Second level adder extension
	ama_signed_extension_function #(.representation(representation),.width_data_in(width_adder_lvl_1),.width_data_out(width_adder_lvl_2))
	second_adder_ext_block_0(.data_in(adder_result_0),.data_out(adder_result_ext_0));
	
	ama_signed_extension_function #(.representation(representation),.width_data_in(width_adder_lvl_1),.width_data_out(width_adder_lvl_2))
	second_adder_ext_block_1(.data_in(adder_result_1),.data_out(adder_result_ext_1));
	
	ama_signed_extension_function #(.representation(representation),.width_data_in(width_adder_lvl_1),.width_data_out(width_adder_lvl_2))
	second_adder_ext_block_2(.data_in(adder_result_2),.data_out(adder_result_ext_2));
	
	ama_signed_extension_function #(.representation(representation),.width_data_in(width_adder_lvl_1),.width_data_out(width_adder_lvl_2))
	second_adder_ext_block_3(.data_in(adder_result_3),.data_out(adder_result_ext_3));
	
	//==========================================================
	// Addnsub register part
	//==========================================================
	generate
		if (port_addnsub1 == "PORT_USED")
		begin
			ama_register_function #(.width_data_in(1), .width_data_out(1), .register_clock(addnsub_multiplier_register1), .register_aclr(addnsub_multiplier_aclr1))
			addnsub_reg_block(.clock(clock),.aclr(aclr),.ena(ena), .data_in(addnsub1), .data_out(addnsub1_wire));
		end
		else
		begin
			assign addnsub1_wire = 1'b0;
		end
	endgenerate
	
	generate
		if (port_addnsub3 == "PORT_USED")
		begin
			ama_register_function #(.width_data_in(1), .width_data_out(1), .register_clock(addnsub_multiplier_register3), .register_aclr(addnsub_multiplier_aclr3))
			addnsub_reg_block(.clock(clock),.aclr(aclr),.ena(ena), .data_in(addnsub3), .data_out(addnsub3_wire) );
		end
		else
		begin
			assign addnsub3_wire = 1'b0;
		end
	endgenerate

endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_multiplier_function
// Use in          : altera_mult_add_rtl
//
// Description     : Multiply input data with corresponding representation
//                     data_in_a * data_in_b
//--------------------------------------------------------------------------
module ama_multiplier_function (
	clock,
	aclr,
	ena,
	data_in_a0,
	data_in_a1,
	data_in_a2,
	data_in_a3,
	data_in_b0,
	data_in_b1,
	data_in_b2,
	data_in_b3,
	data_out_0,
	data_out_1,
	data_out_2,
	data_out_3
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_data_in_a = 1;          // Input dataa bus width
	parameter width_data_in_b = 1;          // Input datab bus width
	parameter width_data_out = 1;           // Output data bus width
	parameter number_of_multipliers = 1;    // Total of data input to be multiply
	
	parameter multiplier_input_representation_a = "UNSIGNED";   // First multiplier input sign representation
	parameter multiplier_input_representation_b = "UNSIGNED";   // Second multiplier input sign representation
	
	parameter multiplier_register0 = "UNREGISTERED";   // First multiplier register clock
	parameter multiplier_register1 = "UNREGISTERED";   // Second multiplier register clock
	parameter multiplier_register2 = "UNREGISTERED";   // Third multiplier register clock
	parameter multiplier_register3 = "UNREGISTERED";   // Fourth multiplier register clock
	
	parameter multiplier_aclr0 = "NONE";   // First multiplier register aclr
	parameter multiplier_aclr1 = "NONE";   // Second multiplier register aclr
	parameter multiplier_aclr2 = "NONE";   // Third multiplier register aclr
	parameter multiplier_aclr3 = "NONE";   // Fourth multiplier register aclr
	
	// Internal used parameters
	parameter width_data_in_a_msb = width_data_in_a - 1;   // MSB for input dataa
	parameter width_data_in_b_msb = width_data_in_b - 1;   // MSB for input datab
	parameter width_data_out_msb = width_data_out -1;      // MSB for output data
	
	
	parameter width_mult_input_a = (multiplier_input_representation_a === "UNSIGNED") ? width_data_in_a + 1 :
                                                                                       width_data_in_a;   // Multiplier first input data
	parameter width_mult_input_a_msb = width_mult_input_a - 1;   // MSB for multiplier first input data
	
	parameter width_mult_input_b = (multiplier_input_representation_b === "UNSIGNED") ? width_data_in_b + 1 :
                                                                                       width_data_in_b;   // Multiplier second input data
	parameter width_mult_input_b_msb = width_mult_input_b - 1;   // MSB for multiplier second input data

	parameter width_mult_output = width_mult_input_a + width_mult_input_b;   // Calculated multiplier result width
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Data input port define
	input [width_data_in_a_msb : 0] data_in_a0, data_in_a1, data_in_a2, data_in_a3;
	input [width_data_in_b_msb : 0] data_in_b0, data_in_b1, data_in_b2, data_in_b3;
	
	// Data output port define
	output [width_data_out_msb : 0] data_out_0, data_out_1, data_out_2, data_out_3;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Multiplier input wires (after extend or no extend)
	wire signed [width_mult_input_a_msb : 0] mult_input_a0, mult_input_a1, mult_input_a2, mult_input_a3;
	wire signed [width_mult_input_b_msb : 0] mult_input_b0, mult_input_b1, mult_input_b2, mult_input_b3;
	
	wire [width_data_out_msb : 0] data_out_wire_0, data_out_wire_1, data_out_wire_2, data_out_wire_3;
	
	//==========================================================
	// Assignment
	//==========================================================
	// Signed multiplier assignment
	assign data_out_wire_0 = mult_input_a0 * mult_input_b0;
	assign data_out_wire_1 = mult_input_a1 * mult_input_b1;
	assign data_out_wire_2 = mult_input_a2 * mult_input_b2;
	assign data_out_wire_3 = mult_input_a3 * mult_input_b3;
	
	
	//==========================================================
	// Sign extension
	//==========================================================
	// Multiplier input a extension
	ama_signed_extension_function #(.representation(multiplier_input_representation_a),.width_data_in(width_data_in_a),.width_data_out(width_mult_input_a))
	mult_input_a_ext_block_0(.data_in(data_in_a0),.data_out(mult_input_a0));
	
	ama_signed_extension_function #(.representation(multiplier_input_representation_a),.width_data_in(width_data_in_a),.width_data_out(width_mult_input_a))
	mult_input_a_ext_block_1(.data_in(data_in_a1),.data_out(mult_input_a1));
	
	ama_signed_extension_function #(.representation(multiplier_input_representation_a),.width_data_in(width_data_in_a),.width_data_out(width_mult_input_a))
	mult_input_a_ext_block_2(.data_in(data_in_a2),.data_out(mult_input_a2));
	
	ama_signed_extension_function #(.representation(multiplier_input_representation_a),.width_data_in(width_data_in_a),.width_data_out(width_mult_input_a))
	mult_input_a_ext_block_3(.data_in(data_in_a3),.data_out(mult_input_a3));
	
	// Multiplier input b extension
	ama_signed_extension_function #(.representation(multiplier_input_representation_b),.width_data_in(width_data_in_b),.width_data_out(width_mult_input_b))
	mult_input_b_ext_block_0(.data_in(data_in_b0),.data_out(mult_input_b0));
	
	ama_signed_extension_function #(.representation(multiplier_input_representation_b),.width_data_in(width_data_in_b),.width_data_out(width_mult_input_b))
	mult_input_b_ext_block_1(.data_in(data_in_b1),.data_out(mult_input_b1));
	
	ama_signed_extension_function #(.representation(multiplier_input_representation_b),.width_data_in(width_data_in_b),.width_data_out(width_mult_input_b))
	mult_input_b_ext_block_2(.data_in(data_in_b2),.data_out(mult_input_b2));
	
	ama_signed_extension_function #(.representation(multiplier_input_representation_b),.width_data_in(width_data_in_b),.width_data_out(width_mult_input_b))
	mult_input_b_ext_block_3(.data_in(data_in_b3),.data_out(mult_input_b3));
	
	
	//==========================================================
	// Register (clock and aclr) part
	//==========================================================
	ama_register_function #(.width_data_in(width_data_out), .width_data_out(width_data_out), .register_clock(multiplier_register0), .register_aclr(multiplier_aclr0))
	multiplier_register_block_0(.clock(clock),.aclr(aclr),.ena(ena),.data_in(data_out_wire_0),.data_out(data_out_0));
	
	ama_register_function #(.width_data_in(width_data_out), .width_data_out(width_data_out), .register_clock(multiplier_register1), .register_aclr(multiplier_aclr1))
	multiplier_register_block_1(.clock(clock),.aclr(aclr),.ena(ena),.data_in(data_out_wire_1),.data_out(data_out_1));
	
	ama_register_function #(.width_data_in(width_data_out), .width_data_out(width_data_out), .register_clock(multiplier_register2), .register_aclr(multiplier_aclr2))
	multiplier_register_block_2(.clock(clock),.aclr(aclr),.ena(ena),.data_in(data_out_wire_2),.data_out(data_out_2));
	
	ama_register_function #(.width_data_in(width_data_out), .width_data_out(width_data_out), .register_clock(multiplier_register3), .register_aclr(multiplier_aclr3))
	multiplier_register_block_3(.clock(clock),.aclr(aclr),.ena(ena),.data_in(data_out_wire_3),.data_out(data_out_3));
	
	
	//==========================================================
	// Condition check
	//==========================================================
	initial /* synthesis enable_verilog_initial_construct */
		if( width_mult_output != width_data_out)
		begin
			$display("Error: Function output width and assign output width not same. Happen in ama_multiplier_function function for altera_mult_add_rtl");
		end
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_preadder_function
// Use in          : altera_mult_add_rtl
//
// Description     : Determine multiplier input source and contain pre-adder 
//                     for mode other that simple mode
//--------------------------------------------------------------------------
module ama_preadder_function (
	dataa_in_0,
	dataa_in_1,
	dataa_in_2,
	dataa_in_3,
	datab_in_0,
	datab_in_1,
	datab_in_2,
	datab_in_3,
	datac_in_0,
	datac_in_1,
	datac_in_2,
	datac_in_3,
	coef0,
	coef1,
	coef2,
	coef3,
	result_a0,
	result_a1,
	result_a2,
	result_a3,
	result_b0,
	result_b1,
	result_b2,
	result_b3
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter preadder_mode  = "SIMPLE";   // Mode to determine output value
	
	parameter width_in_a  = 1;         // Dataa input bus width
	parameter width_in_b  = 1;         // Datab input bus width
	parameter width_in_c  = 1;         // Datac input bus width
	parameter width_in_coef  = 1;      // Coef input bus width
	
	parameter width_result_a = 1;   // Output result a bus width
	parameter width_result_b = 1;   // Output result b bus width
	
	parameter preadder_direction_0  = "ADD";   // First pre-adder direction
	parameter preadder_direction_1  = "ADD";   // Second pre-adder direction
	parameter preadder_direction_2  = "ADD";   // Third pre-adder direction
	parameter preadder_direction_3  = "ADD";   // Forth pre-adder direction
	
	parameter representation_preadder_adder = "UNSIGNED";   // Representation for pre-adder 
	
	// Internal used parameters
	parameter width_in_a_msb = width_in_a - 1;                 // MSB for dataa input
	parameter width_in_b_msb = width_in_b - 1;                 // MSB for datab input
	parameter width_in_c_msb = width_in_c - 1;                 // MSB for datav input
	parameter width_in_coef_msb = width_in_coef - 1;           // MSB for coef input
	parameter width_result_a_msb = width_result_a - 1;   // MSB for result a output
	parameter width_result_b_msb = width_result_b - 1;   // MSB for result b output
	
	parameter width_preadder_adder_input = (width_in_a > width_in_b) ? width_in_a : width_in_b;   // Determine pre-adder input width 
	parameter width_preadder_adder_input_msb = width_preadder_adder_input - 1;        // MSB for pre-adder input
	
	parameter width_preadder_adder_result = width_preadder_adder_input + 1;           // Pre-adder result width
	parameter width_preadder_adder_result_msb = width_preadder_adder_result - 1;      // MSB for pre-adder result
	
	parameter width_preadder_adder_input_wire = width_preadder_adder_input + 1;            // Pre-adder input width after extend
	parameter width_preadder_adder_input_wire_msb = width_preadder_adder_input_wire - 1;   // MSB for extended pre-adder input
	
	parameter width_in_a_ext = (width_preadder_adder_input > width_in_a) ? width_preadder_adder_input - width_in_a + 1 : 1;   // Width of dataa require to be extend
	parameter width_in_b_ext = (width_preadder_adder_input > width_in_b) ? width_preadder_adder_input - width_in_b + 1 : 1;   // Width of datab require to be extend
	
	parameter width_output_preadder = (preadder_mode === "SQUARE")? width_preadder_adder_result : 1;   // Prevent truncated warning happen
	parameter width_output_preadder_msb = width_output_preadder -1;

	parameter width_output_coef = (preadder_mode === "COEF" || preadder_mode === "CONSTANT")? width_in_coef : 1;   // Prevent truncated warning happen
	parameter width_output_coef_msb = width_output_coef -1;
	
	parameter width_output_datab = (preadder_mode === "SIMPLE")? width_in_b : 1;   // Prevent truncated warning happen
	parameter width_output_datab_msb = width_output_datab -1;
	
	parameter width_output_datac = (preadder_mode === "INPUT")? width_in_c : 1;   // Prevent truncated warning happen
	parameter width_output_datac_msb = width_output_datac -1;
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Data input port define
	input [width_in_a_msb : 0] dataa_in_0, dataa_in_1, dataa_in_2, dataa_in_3;
	input [width_in_b_msb : 0] datab_in_0, datab_in_1, datab_in_2, datab_in_3;
	input [width_in_c_msb : 0] datac_in_0, datac_in_1, datac_in_2, datac_in_3;
	input [width_in_coef_msb : 0] coef0, coef1, coef2, coef3;
	
	// Data output port define
	output [width_result_a_msb : 0] result_a0, result_a1, result_a2, result_a3;
	output [width_result_b_msb : 0] result_b0, result_b1, result_b2, result_b3;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Pre-adder input wire
	wire [width_preadder_adder_input_msb : 0] preadder_input_a0, preadder_input_a1, preadder_input_a2, preadder_input_a3;
	wire [width_preadder_adder_input_msb : 0] preadder_input_b0, preadder_input_b1, preadder_input_b2, preadder_input_b3;
	
	// Pre-adder input wire (for concatenate)
	wire [width_preadder_adder_input_wire_msb : 0] preadder_input_wire_a0, preadder_input_wire_a1, preadder_input_wire_a2, preadder_input_wire_a3;
	wire [width_preadder_adder_input_wire_msb : 0] preadder_input_wire_b0, preadder_input_wire_b1, preadder_input_wire_b2, preadder_input_wire_b3;
	
	// Determine bits to be extend
	wire preadder_ext_a0 = (representation_preadder_adder === "UNSIGNED") ? 1'b0 : dataa_in_0[width_in_a_msb];
	wire preadder_ext_a1 = (representation_preadder_adder === "UNSIGNED") ? 1'b0 : dataa_in_1[width_in_a_msb];
	wire preadder_ext_a2 = (representation_preadder_adder === "UNSIGNED") ? 1'b0 : dataa_in_2[width_in_a_msb];
	wire preadder_ext_a3 = (representation_preadder_adder === "UNSIGNED") ? 1'b0 : dataa_in_3[width_in_a_msb];
	
	wire preadder_ext_b0 = (representation_preadder_adder === "UNSIGNED") ? 1'b0 : datab_in_0[width_in_b_msb];
	wire preadder_ext_b1 = (representation_preadder_adder === "UNSIGNED") ? 1'b0 : datab_in_1[width_in_b_msb];
	wire preadder_ext_b2 = (representation_preadder_adder === "UNSIGNED") ? 1'b0 : datab_in_2[width_in_b_msb];
	wire preadder_ext_b3 = (representation_preadder_adder === "UNSIGNED") ? 1'b0 : datab_in_3[width_in_b_msb];
	
	// Pre-adder result wire
	wire [width_preadder_adder_result_msb : 0] preadder_adder_result_0, preadder_adder_result_1, preadder_adder_result_2, preadder_adder_result_3;
	
	
	//==========================================================
	// Preadder adder (sum of 2)
	//==========================================================
	ama_adder_function #(.width_data_in(width_preadder_adder_input), .width_data_out(width_preadder_adder_result), .number_of_adder_input(2), .adder1_direction(preadder_direction_0), .representation(representation_preadder_adder))
	preadder_adder_0(.data_in_0(preadder_input_a0), .data_in_1(preadder_input_b0), .data_in_2(), .data_in_3(), .data_out(preadder_adder_result_0), .clock(), .aclr(), .ena(), .addnsub1(), .addnsub3());
	
	ama_adder_function #(.width_data_in(width_preadder_adder_input), .width_data_out(width_preadder_adder_result), .number_of_adder_input(2), .adder1_direction(preadder_direction_1), .representation(representation_preadder_adder))
	preadder_adder_1(.data_in_0(preadder_input_a1), .data_in_1(preadder_input_b1), .data_in_2(), .data_in_3(), .data_out(preadder_adder_result_1), .clock(), .aclr(), .ena(), .addnsub1(), .addnsub3());
	
	ama_adder_function #(.width_data_in(width_preadder_adder_input), .width_data_out(width_preadder_adder_result), .number_of_adder_input(2), .adder1_direction(preadder_direction_2), .representation(representation_preadder_adder))
	preadder_adder_2(.data_in_0(preadder_input_a2), .data_in_1(preadder_input_b2), .data_in_2(), .data_in_3(), .data_out(preadder_adder_result_2), .clock(), .aclr(), .ena(), .addnsub1(), .addnsub3());
	
	ama_adder_function #(.width_data_in(width_preadder_adder_input), .width_data_out(width_preadder_adder_result), .number_of_adder_input(2), .adder1_direction(preadder_direction_3), .representation(representation_preadder_adder))
	preadder_adder_3(.data_in_0(preadder_input_a3), .data_in_1(preadder_input_b3), .data_in_2(), .data_in_3(), .data_out(preadder_adder_result_3), .clock(), .aclr(), .ena(), .addnsub1(), .addnsub3());
	
	
	//==========================================================
	// Assignment
	//==========================================================
	// Preadder input extend (extra one bit, prevent zero concatenate issue)
	assign preadder_input_wire_a0 = {{width_in_a_ext{preadder_ext_a0}},dataa_in_0};
	assign preadder_input_wire_a1 = {{width_in_a_ext{preadder_ext_a1}},dataa_in_1};
	assign preadder_input_wire_a2 = {{width_in_a_ext{preadder_ext_a2}},dataa_in_2};
	assign preadder_input_wire_a3 = {{width_in_a_ext{preadder_ext_a3}},dataa_in_3};
	
	assign preadder_input_wire_b0 = {{width_in_b_ext{preadder_ext_b0}},datab_in_0};
	assign preadder_input_wire_b1 = {{width_in_b_ext{preadder_ext_b1}},datab_in_1};
	assign preadder_input_wire_b2 = {{width_in_b_ext{preadder_ext_b2}},datab_in_2};
	assign preadder_input_wire_b3 = {{width_in_b_ext{preadder_ext_b3}},datab_in_3};
	
	// Preadder input
	assign preadder_input_a0 = preadder_input_wire_a0[width_preadder_adder_input_msb : 0];
	assign preadder_input_a1 = preadder_input_wire_a1[width_preadder_adder_input_msb : 0];
	assign preadder_input_a2 = preadder_input_wire_a2[width_preadder_adder_input_msb : 0];
	assign preadder_input_a3 = preadder_input_wire_a3[width_preadder_adder_input_msb : 0];
	
	assign preadder_input_b0 = preadder_input_wire_b0[width_preadder_adder_input_msb : 0];
	assign preadder_input_b1 = preadder_input_wire_b1[width_preadder_adder_input_msb : 0];
	assign preadder_input_b2 = preadder_input_wire_b2[width_preadder_adder_input_msb : 0];
	assign preadder_input_b3 = preadder_input_wire_b3[width_preadder_adder_input_msb : 0];
	
	// Preadder output selection
	assign result_a0 = (preadder_mode != "SIMPLE" && preadder_mode != "CONSTANT") ? preadder_adder_result_0[width_result_a_msb : 0] :
	                                                                                dataa_in_0;
	assign result_a1 = (preadder_mode != "SIMPLE" && preadder_mode != "CONSTANT") ? preadder_adder_result_1[width_result_a_msb : 0] :
	                                                                                dataa_in_1;
	assign result_a2 = (preadder_mode != "SIMPLE" && preadder_mode != "CONSTANT") ? preadder_adder_result_2[width_result_a_msb : 0] :
	                                                                                dataa_in_2;
	assign result_a3 = (preadder_mode != "SIMPLE" && preadder_mode != "CONSTANT") ? preadder_adder_result_3[width_result_a_msb : 0] :
	                                                                                dataa_in_3;
	
	assign result_b0 = (preadder_mode === "INPUT")? datac_in_0[width_output_datac_msb : 0] :
		                (preadder_mode === "SQUARE")? preadder_adder_result_0[width_output_preadder_msb : 0] :
                      (preadder_mode === "COEF" || preadder_mode === "CONSTANT")? coef0[width_output_coef_msb : 0] : 
                       datab_in_0[width_output_datab_msb : 0];
									
	assign result_b1 = (preadder_mode === "INPUT")? datac_in_1[width_output_datac_msb : 0] :
		                (preadder_mode === "SQUARE")? preadder_adder_result_1[width_output_preadder_msb : 0] :
                      (preadder_mode === "COEF" || preadder_mode === "CONSTANT")? coef1[width_output_coef_msb : 0] : 
                       datab_in_1[width_output_datab_msb : 0];
									
	assign result_b2 = (preadder_mode === "INPUT")? datac_in_2[width_output_datac_msb : 0] :
		                (preadder_mode === "SQUARE")? preadder_adder_result_2[width_output_preadder_msb : 0] :
                      (preadder_mode === "COEF" || preadder_mode === "CONSTANT")? coef2[width_output_coef_msb : 0] : 
                       datab_in_2[width_output_datab_msb : 0];
									
	assign result_b3 = (preadder_mode === "INPUT")? datac_in_3[width_output_datac_msb : 0] :
		                (preadder_mode === "SQUARE")? preadder_adder_result_3[width_output_preadder_msb : 0] :
                      (preadder_mode === "COEF" || preadder_mode === "CONSTANT")? coef3[width_output_coef_msb : 0] : 
                       datab_in_3[width_output_datab_msb : 0];
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_accumulator_function
// Use in          : altera_mult_add_rtl
//
// Description     : Accumulate the result according to setting or direct
//                     output the current input result (when accumulator 
//                     equal to no)
//--------------------------------------------------------------------------
module ama_accumulator_function (
	clock,
	aclr,
	ena,
	accum_sload,
	sload_accum,
	data_result,
	prev_result,
	result
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_result = 1;            // Result bus width
	
	parameter accumulator = "NO";          // Allow result to be accumulated
	parameter accum_direction = "ADD";     // Accumulated by adding or substracting current result
	parameter loadconst_value = 0;         // Constant value to be add with current result
	
	parameter accum_sload_register = "UNREGISTERED";   // Clock for accum_sload signal register
	parameter accum_sload_aclr = "NONE";               // Aclr for accum_sload signal register
	
	parameter double_accum = "NO";         // Allow feedback result to be registered and form double channel (or double accumulator)
	parameter use_sload_accum_port = "NO";	// Use sload_accum port allow accumulator behavior to match the sv serries hardware architecture
	
	parameter output_register = "UNREGISTERED";   // Clock for output signal register
	parameter output_aclr = "NONE";               // Aclr for output signal register
	
	// Internal used parameters
	parameter width_result_msb = width_result - 1;   // MSB for  data
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Signal that select between loadconstant value or previous result for accumulate
	input accum_sload;
	input sload_accum;
	
	// Input data port define
	input [width_result_msb : 0] data_result;    // Current result
	input [width_result_msb : 0] prev_result;    // Previous result
	
	// Data output port define
	output [width_result_msb : 0] result;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Loadconst value that prepare to be added
	wire [width_result_msb : 0]loadconst_reg = {{width_result_msb{1'b0}},1'b1} << loadconst_value;
	
	// Contain the selection of previous result, between registered and unregistered value (for double accumulator)
	wire [width_result_msb : 0] prev_result_wire;
	
	// Registered accum_sload signal 
	wire accum_sload_wire;
	
	// Contain the value that need to accumulated with current result
	wire [width_result_msb : 0] accum_add_source;
	
	// Contain the accumulated result
	wire [width_result_msb : 0] accum_result;
	
	
	//==========================================================
	// Assignment
	//==========================================================
	// Accumulator (Double accumulator)
	
	// Accumulator source assignment
	generate if(use_sload_accum_port == "YES")
		begin
			assign accum_add_source = (accum_sload_wire == 1 && accum_sload_register !== "UNREGISTERED") ? prev_result_wire : loadconst_reg;
		end
	else
		begin
			assign accum_add_source = (accum_sload_wire == 1 && accum_sload_register !== "UNREGISTERED") ? loadconst_reg : prev_result_wire;
		end
	endgenerate
	
	// Accumulator result 
	assign accum_result = (accum_direction === "SUB") ? accum_add_source - data_result :
	                       accum_add_source + data_result;
	
	// Result assignment
	assign result = (accumulator === "NO") ? data_result : accum_result;
	
	
	//==========================================================
	// Register (clock and aclr) part
	//==========================================================

	generate if(use_sload_accum_port == "YES")
		begin
			// sload_accum signal register
			ama_register_function #(.width_data_in(1), .width_data_out(1), .register_clock(accum_sload_register), .register_aclr(accum_sload_aclr))
			accum_sload_register_block(.clock(clock), .aclr(aclr), .ena(ena), .data_in(sload_accum), .data_out(accum_sload_wire));
		end 
	else
		begin
			// Accum_sload signal register
			ama_register_function #(.width_data_in(1), .width_data_out(1), .register_clock(accum_sload_register), .register_aclr(accum_sload_aclr))
			accum_sload_register_block(.clock(clock), .aclr(aclr), .ena(ena), .data_in(accum_sload), .data_out(accum_sload_wire));
		end
	endgenerate
	
	generate
		if (double_accum == "YES")
		begin
			ama_register_function #(.width_data_in(width_result), .width_data_out(width_result), .register_clock(output_register), .register_aclr(output_aclr))
			accum_sload_register_block(.clock(clock), .aclr(aclr), .ena(ena), .data_in(prev_result), .data_out(prev_result_wire));
		end
		else
		begin
			assign prev_result_wire = prev_result;
		end
	endgenerate
	
endmodule


//--------------------------------------------------------------------------
// Module Name     : ama_systolic_adder_function
// Use in          : altera_mult_add_rtl
//
// Description     : Contain systolic function 
//                   (((chainin + mult result 1)<reg> + mult result 2)<reg>
//                     + mult result 3)<reg> + mult result 4
//--------------------------------------------------------------------------
module ama_systolic_adder_function (
	data_in_0,
	data_in_1,
	data_in_2,
	data_in_3,
	chainin,
	clock,
	aclr,
	ena,
	data_out,
	addnsub1,
	addnsub3
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_data_in = 1;                   // Input data bus width
	parameter width_chainin  = 1;                  // Chainin data bus width
	parameter width_data_out = 1;                  // Output data bus width
	parameter number_of_adder_input = 1;           // Total of data input to be add
	
	parameter systolic_delay1 = "UNREGISTERED";    // Clock for first and second systolic register
	parameter systolic_aclr1 = "NONE";           // Aclr for first and second systolic register
	parameter systolic_delay3 = "UNREGISTERED";    // Clock for third systolic register
	parameter systolic_aclr3 = "NONE";           // Aclr for third systolic register
	
	parameter adder1_direction = "NONE";         // Second adder direction 
	parameter adder3_direction = "NONE";         // Forth adder direction
	
	parameter port_addnsub1 = "PORT_CONNECTIVITY";       // Input port addnsub1 parameter
	parameter addnsub_multiplier_register1 = "CLOCK0";   // Clock for addnsub1 signal register
	parameter addnsub_multiplier_aclr1 = "ACLR3";        // Aclr for addnsub1 signal register
	
	parameter port_addnsub3 = "PORT_CONNECTIVITY";       // Input port addnsub3 parameter
	parameter addnsub_multiplier_register3  = "CLOCK0";  // Clock for addnsub3 signal register
	parameter addnsub_multiplier_aclr3 = "ACLR3";        // Aclr for addnsub3 signal register
	
	
	// Internal used parameters
	parameter width_data_in_msb = width_data_in - 1;     // MSB for input data
	parameter width_data_out_msb = width_data_out -1;    // MSB for output data
	parameter width_chainin_msb = width_chainin -1;      // MSB for chainin data

	parameter width_systolic = (width_chainin > width_data_in) ? width_chainin : width_data_in;   // Width of adder data input and result
	parameter width_systolic_msb = width_systolic - 1;    // MSB for systolic ext

	parameter input_ext_width = (width_chainin > width_data_in) ? width_chainin - width_data_in : 1;   // Extend input data to be same as chainin width
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Data input port define
	input [width_data_in_msb : 0] data_in_0, data_in_1, data_in_2, data_in_3;
	
	// Chainin input port define
	input [width_chainin_msb : 0] chainin;   
	
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Dynamic addnsub port define
	input addnsub1, addnsub3;
	
	// Data output port define
	output [width_data_out_msb : 0] data_out;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Input data extension wire
	wire signed [width_systolic_msb : 0] data_in_ext_0, data_in_ext_1, data_in_ext_2, data_in_ext_3;
	
	// Adder registered result wire
	wire signed [width_systolic_msb : 0] adder_result_reg_0, adder_result_reg_1, adder_result_reg_2;
	
	// Adder result wire
	wire signed [width_systolic_msb : 0] adder_result_0, adder_result_1, adder_result_2, adder_result_3;
	
	// Register addnsub wire
	wire addnsub1_wire, addnsub3_wire;
	
	
	//==========================================================
	// Assignment
	//==========================================================
	// Input data extension
	assign data_in_ext_0 = {{input_ext_width{data_in_0[width_data_in_msb]}},data_in_0};
	assign data_in_ext_1 = {{input_ext_width{data_in_1[width_data_in_msb]}},data_in_1};
	assign data_in_ext_2 = {{input_ext_width{data_in_2[width_data_in_msb]}},data_in_2};
	assign data_in_ext_3 = {{input_ext_width{data_in_3[width_data_in_msb]}},data_in_3};
	
	// Adder assignment
	assign adder_result_0 = chainin + data_in_ext_0;
	assign adder_result_1 = (port_addnsub1 == "PORT_USED") ? (addnsub1_wire == 0) ? adder_result_reg_0 - data_in_ext_1 : adder_result_reg_0 + data_in_ext_1:
	                                                         (adder1_direction === "SUB") ? adder_result_reg_0 - data_in_ext_1 : adder_result_reg_0 + data_in_ext_1;
	assign adder_result_2 = adder_result_reg_1 + data_in_ext_2;
	assign adder_result_3 = (port_addnsub3 == "PORT_USED") ? (addnsub3_wire == 0) ? adder_result_reg_2 - data_in_ext_3 : adder_result_reg_2 + data_in_ext_3:
	                                                         (adder3_direction === "SUB") ? adder_result_reg_2 - data_in_ext_3 : adder_result_reg_2 + data_in_ext_3;
	
	// Ouptut result selection
	assign data_out = (number_of_adder_input == 1) ? adder_result_0[width_data_out_msb : 0] : 
	                  (number_of_adder_input == 2) ? adder_result_1[width_data_out_msb : 0] : 
							(number_of_adder_input == 3) ? adder_result_2[width_data_out_msb : 0] : 
							(number_of_adder_input == 4) ? adder_result_3[width_data_out_msb : 0] : {width_data_out{1'bx}};
	
	
	//==========================================================
	// Register (clock and aclr) part
	//==========================================================
	// First register (adder result for chainin and first input data) 
	ama_register_function #(.width_data_in(width_systolic), .width_data_out(width_systolic), .register_clock(systolic_delay1), .register_aclr(systolic_aclr1))
	systolic_reg_block_0(.clock(clock), .aclr(aclr), .ena(ena), .data_in(adder_result_0), .data_out(adder_result_reg_0));
	
	// Second register (for first adder result and second input data) 
	ama_register_function #(.width_data_in(width_systolic), .width_data_out(width_systolic), .register_clock(systolic_delay1), .register_aclr(systolic_aclr1))
	systolic_reg_block_1(.clock(clock), .aclr(aclr), .ena(ena), .data_in(adder_result_1), .data_out(adder_result_reg_1));
	
	// Third register (for second adder result and third input data) 
	ama_register_function #(.width_data_in(width_systolic), .width_data_out(width_systolic), .register_clock(systolic_delay3), .register_aclr(systolic_aclr3))
	systolic_reg_block_2(.clock(clock), .aclr(aclr), .ena(ena), .data_in(adder_result_2), .data_out(adder_result_reg_2));
	
	
	//==========================================================
	// Addnsub register part
	//==========================================================
	generate
		if (port_addnsub1 == "PORT_USED")
		begin
			ama_register_function #(.width_data_in(1), .width_data_out(1), .register_clock(addnsub_multiplier_register1), .register_aclr(addnsub_multiplier_aclr1))
			addnsub_reg_block(.clock(clock),.aclr(aclr),.ena(ena), .data_in(addnsub1), .data_out(addnsub1_wire));
		end
		else
		begin
			assign addnsub1_wire = 1'b0;
		end
	endgenerate
	
	generate
		if (port_addnsub3 == "PORT_USED")
		begin
			ama_register_function #(.width_data_in(1), .width_data_out(1), .register_clock(addnsub_multiplier_register3), .register_aclr(addnsub_multiplier_aclr3))
			addnsub_reg_block(.clock(clock),.aclr(aclr),.ena(ena), .data_in(addnsub3), .data_out(addnsub3_wire) );
		end
		else
		begin
			assign addnsub3_wire = 1'b0;
		end
	endgenerate
	
endmodule

//--------------------------------------------------------------------------
// Module Name     : ama_data_split_reg_ext_function
// Use in          : altera_mult_add_rtl
//
// Description     : Split data evenly according to the number of multiplier
//--------------------------------------------------------------------------
module ama_scanchain (
	clock,
	aclr,
	ena,
	sign,
	scanin,
	data_out_0,
	data_out_1,
	data_out_2,
	data_out_3,
	scanout
	);
	
	//==========================================================
	// Parameters declaration
	//==========================================================
	// Inherite parameters
	parameter width_scanin = 1;                    // Scanin data bus width
	parameter width_scanchain = 1;                 // Scanchain data bus width
	
	parameter input_register_clock_0 = "UNREGISTERED";    // Clock for first data output register
	parameter input_register_aclr_0  = "NONE";          // Aclr for first data output register
	parameter input_register_clock_1 = "UNREGISTERED";    // Clock for second data output register
	parameter input_register_aclr_1  = "NONE";          // Aclr for second data output register
	parameter input_register_clock_2 = "UNREGISTERED";    // Clock for third data output register
	parameter input_register_aclr_2  = "NONE";          // Aclr for third data output register
	parameter input_register_clock_3 = "UNREGISTERED";    // Clock for fourth data output register
	parameter input_register_aclr_3  = "NONE";          // Aclr for fourth data output register
	
	parameter scanchain_register_clock = "UNREGISTERED";    // Clock for scanchain data register
	parameter scanchain_register_aclr = "NONE";           // Aclr for scanchain data register
	
	parameter port_sign = "PORT_CONNECTIVITY";      // Dynamic sign extension port condition
	parameter number_of_multipliers = 1;            // Total number of data going to be splited 
	
	// Internal used parameters
	parameter width_scanin_msb = width_scanin - 1;         // MSB of input data
	parameter width_scanchain_msb = width_scanchain -1;    // MSB of output data
	
	
	//==========================================================
	// Port declaration
	//==========================================================
	// Clock, aclr and ena signal port define
	input [3:0] clock, aclr, ena;
	
	// Dynamic sign port define
	input sign;
	
	// Data input port define
	input [width_scanin_msb : 0] scanin;
	
	// Data output port define
	output [width_scanchain_msb : 0] data_out_0, data_out_1, data_out_2, data_out_3, scanout;
	
	
	//==========================================================
	// Wire and register defined
	//==========================================================
	// Split data after registered and dynamic extension
	wire [width_scanchain_msb : 0] scanchain_wire_0, scanchain_wire_1, scanchain_wire_2, scanchain_wire_3;
	wire [width_scanchain_msb : 0] scanchain_reg_wire_0, scanchain_reg_wire_1, scanchain_reg_wire_2, scanchain_reg_wire_3;
	wire [width_scanchain_msb : 0] scanout_reg_wire;
	
	//==========================================================
	// Assignment
	//==========================================================
	// Data output assignment
	assign data_out_0 = scanchain_reg_wire_0;
	assign data_out_1 = (number_of_multipliers >= 2)? scanchain_reg_wire_1 : {(width_scanchain ){1'bx}};
	assign data_out_2 = (number_of_multipliers >= 3)? scanchain_reg_wire_2 : {(width_scanchain ){1'bx}};
	assign data_out_3 = (number_of_multipliers == 4)? scanchain_reg_wire_3 : {(width_scanchain ){1'bx}};
	
	assign scanout_reg_wire = (number_of_multipliers == 2)? scanchain_reg_wire_1 :
	                          (number_of_multipliers == 3)? scanchain_reg_wire_2 :
	                          (number_of_multipliers == 4)? scanchain_reg_wire_3 :
	                          scanchain_reg_wire_0;
	
	
	//==========================================================
	// Register (clock and aclr) part
	//==========================================================
	// Scanchain register part
	// Only extend one time for dynamic sign extension
	ama_register_with_ext_function #(.width_data_in(width_scanin), .width_data_out(width_scanchain), .register_clock(scanchain_register_clock), .register_aclr(scanchain_register_aclr), .port_sign(port_sign))
	scanchain_register_block_0(.clock(clock), .aclr(aclr),.ena(ena), .sign(sign), .data_in(scanin), .data_out(scanchain_wire_0));
	
	ama_register_function #(.width_data_in(width_scanchain), .width_data_out(width_scanchain), .register_clock(scanchain_register_clock), .register_aclr(scanchain_register_aclr))
	scanchain_register_block_1(.clock(clock), .aclr(aclr), .ena(ena), .data_in(scanchain_reg_wire_0), .data_out(scanchain_wire_1));
	
	ama_register_function #(.width_data_in(width_scanchain), .width_data_out(width_scanchain), .register_clock(scanchain_register_clock), .register_aclr(scanchain_register_aclr))
	scanchain_register_block_2(.clock(clock), .aclr(aclr), .ena(ena), .data_in(scanchain_reg_wire_1), .data_out(scanchain_wire_2));
	
	ama_register_function #(.width_data_in(width_scanchain), .width_data_out(width_scanchain), .register_clock(scanchain_register_clock), .register_aclr(scanchain_register_aclr))
	scanchain_register_block_3(.clock(clock), .aclr(aclr), .ena(ena), .data_in(scanchain_reg_wire_2), .data_out(scanchain_wire_3));
	
	
	// Input register part
	ama_register_function #(.width_data_in(width_scanchain), .width_data_out(width_scanchain), .register_clock(input_register_clock_0), .register_aclr(input_register_aclr_0))
	input_register_block_0(.clock(clock), .aclr(aclr), .ena(ena), .data_in(scanchain_wire_0), .data_out(scanchain_reg_wire_0));
	
	ama_register_function #(.width_data_in(width_scanchain), .width_data_out(width_scanchain), .register_clock(input_register_clock_1), .register_aclr(input_register_aclr_1))
	input_register_block_1(.clock(clock), .aclr(aclr), .ena(ena), .data_in(scanchain_wire_1), .data_out(scanchain_reg_wire_1));
	
	ama_register_function #(.width_data_in(width_scanchain), .width_data_out(width_scanchain), .register_clock(input_register_clock_2), .register_aclr(input_register_aclr_2))
	input_register_block_2(.clock(clock), .aclr(aclr), .ena(ena), .data_in(scanchain_wire_2), .data_out(scanchain_reg_wire_2));
	
	ama_register_function #(.width_data_in(width_scanchain), .width_data_out(width_scanchain), .register_clock(input_register_clock_3), .register_aclr(input_register_aclr_3))
	input_register_block_3(.clock(clock), .aclr(aclr), .ena(ena), .data_in(scanchain_wire_3), .data_out(scanchain_reg_wire_3));
	
	
	// Scanout register part
	ama_register_function #(.width_data_in(width_scanchain), .width_data_out(width_scanchain), .register_clock(scanchain_register_clock), .register_aclr(scanchain_register_aclr))
	scanout_register_block(.clock(clock), .aclr(aclr), .ena(ena), .data_in(scanout_reg_wire), .data_out(scanout));
	
endmodule
