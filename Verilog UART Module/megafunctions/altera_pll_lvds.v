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
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


module altera_pll_lvds
(
    //input
    refclk,
    rst,
    //output
    outclk0,
    outclk1,
    outclk2,
    locked
);

//input
input refclk;
input rst;

//output
output outclk0;
output outclk1;
output outclk2;
output locked;


//parameter
parameter reference_clock_frequency = "0 ps";
parameter data_rate = 0;
parameter deserialization_factor = 4;

parameter output_clock_frequency0 = "0 ps";
parameter phase_shift0 = "0 ps";
parameter duty_cycle0 = 50;

parameter output_clock_frequency1 = "0 ps";
parameter phase_shift1 = "0 ps";
parameter duty_cycle1 = 50;

parameter output_clock_frequency2 = "0 ps";
parameter phase_shift2 = "0 ps";
parameter duty_cycle2 = 50;
//wire 
wire fboutclk_wire;

//clk0 as inclk for lvds
generic_pll gpll0 (
                    //input
                    .refclk(refclk),
                    .rst(rst),
                    .fbclk(fboutclk_wire),
                    //output
                    .outclk(outclk0),
                    .fboutclk(fboutclk_wire),
                    .locked(locked)
                 );
        defparam gpll0.reference_clock_frequency = reference_clock_frequency;
        defparam gpll0.output_clock_frequency = output_clock_frequency0;
        defparam gpll0.phase_shift = phase_shift0; 
        defparam gpll0.duty_cycle = duty_cycle0;

//clk1 as tx_enable or rx_enable for lvds
generic_pll gpll1 (
                    //input
                    .refclk(refclk),
                    .rst(rst),
                    .fbclk(fboutclk_wire),
                    //output
                    .outclk(outclk1),
                    .fboutclk(),
                    .locked()
                 );
        defparam gpll1.reference_clock_frequency = reference_clock_frequency;
        defparam gpll1.output_clock_frequency = output_clock_frequency1;
        defparam gpll1.phase_shift = phase_shift1;
        defparam gpll1.duty_cycle = duty_cycle1;

//clk2 as slowclk for lvds
generic_pll gpll2 (
                    //input
                    .refclk(refclk),
                    .rst(rst),
                    .fbclk(fboutclk_wire),
                    //output
                    .outclk(outclk2),
                    .fboutclk(),
                    .locked()
                 );
        defparam gpll2.reference_clock_frequency = reference_clock_frequency;
        defparam gpll2.output_clock_frequency = output_clock_frequency2;
        defparam gpll2.phase_shift = phase_shift2;
        defparam gpll2.duty_cycle = duty_cycle2;
        
endmodule
        