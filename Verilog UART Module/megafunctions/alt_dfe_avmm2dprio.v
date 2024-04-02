//********************************************************************************
// This module contains the gasket logic for bridging the Avalon MM master 
//  interface to the alt_dprio interface
//
// Instantiations: none
//
//********************************************************************************


module alt_dfe_avmm2dprio (
  i_resetn,
  i_avmm_clk,
  i_avmm_address,
  i_avmm_read,
  i_avmm_write,
  i_avmm_writedata,
  o_avmm_readdata,
  o_avmm_waitrequest,
  i_remap_address,
  
  i_dprio_busy,
  i_dprio_in,
  o_dprio_wren,
  o_dprio_rden,
  o_dprio_addr,
  o_dprio_data
);



//********************************************************************************
// PARAMETERS
//********************************************************************************
  parameter AVMM_ADDR_WIDTH = 16;
  parameter AVMM_RDAT_WIDTH = 16;
  parameter AVMM_WDAT_WIDTH = 16;

  parameter DPRIO_ADDR_WIDTH = 16;
  parameter DPRIO_DATA_WIDTH = 16;

  parameter ST_IDLE  = 2'd0;
  parameter ST_BEGIN = 2'd1;
  parameter ST_WAIT  = 2'd2;
 
//********************************************************************************
// DECLARATIONS
//********************************************************************************
  input                        i_resetn;
  input                        i_avmm_clk;
  input  [AVMM_ADDR_WIDTH-1:0] i_avmm_address;
  input                        i_avmm_read;
  input                        i_avmm_write;
  input  [AVMM_WDAT_WIDTH-1:0] i_avmm_writedata;
  output [AVMM_RDAT_WIDTH-1:0] o_avmm_readdata;
  output reg                   o_avmm_waitrequest;
  input  [11:0]                i_remap_address;
  
  input                         i_dprio_busy;
  input  [DPRIO_DATA_WIDTH-1:0] i_dprio_in;
  output reg                    o_dprio_wren;
  output reg                    o_dprio_rden;
  output [DPRIO_ADDR_WIDTH-1:0] o_dprio_addr;
  output [DPRIO_DATA_WIDTH-1:0] o_dprio_data;

(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [1:0] state;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [1:0] state0q;

// synopsys translate_off
  initial begin
    state            = 'b0;
    state0q          = 'b0;
  end
// synopsys translate_on  


//********************************************************************************
// Sequential Logic
//********************************************************************************
  always @ (posedge i_avmm_clk) begin
    if (~i_resetn) begin
      state0q <= ST_IDLE;
    end else begin
      state0q <= state;
    end
  end

//********************************************************************************
// Combinational Logic
//********************************************************************************
  assign o_dprio_addr    = i_avmm_address;
  assign o_dprio_data    = i_avmm_writedata;
  assign o_avmm_readdata = i_dprio_in;

  always @ (*) begin
    // avoid latches
    o_dprio_wren = 1'b0;
    o_dprio_rden = 1'b0;
    case (state0q)
      ST_BEGIN: begin // start the dprio operation
        o_avmm_waitrequest = 1'b1;
        o_dprio_wren = i_avmm_write;
        o_dprio_rden = i_avmm_read;
        // don't leave this state until alt_dprio becomes busy - ensures that the request is accepted
        // -add special case for MM component -> if remap_address reports an invalid channel, move out of this state
        state = (i_dprio_busy || i_remap_address == 12'hfff) ? ST_WAIT : ST_BEGIN;
      end
      ST_WAIT: begin
        // deassert o_dprio_wr/rden once alt_dprio becomes busy
        // deassert waitrequest once alt_dprio is no longer busy - this causes the slave to latch the data
        // -for the case of remap_address reporting an invalid channel, we will fall through back to IDLE
        o_avmm_waitrequest = i_dprio_busy; 
        state = i_dprio_busy ? ST_WAIT : ST_IDLE;
      end
      default: begin //ST_IDLE: begin
        if (i_avmm_read || i_avmm_write) begin
          o_avmm_waitrequest = 1'b1;
          state = i_dprio_busy ? ST_IDLE : ST_BEGIN; // stay here until alt_dprio is available
        end else begin
          o_avmm_waitrequest = 1'b0;
          state = ST_IDLE;
        end
      end
    endcase
  end


endmodule
