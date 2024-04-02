//********************************************************************************
// This module contains the logic for the Avalon MM master interface
//
// Instantiations: none
//
//********************************************************************************


module alt_dfe_avmm_master (
  i_resetn,
  i_avmm_clk,
  i_avmm_mreaddata,
  i_avmm_mwaitrequest,
  o_avmm_maddress,
  o_avmm_mread,
  o_avmm_mwrite,
  o_avmm_mwritedata,
  o_avmm_marbiterlock,

  i_ir_trigger,
  i_ir_chaddress,
  i_ir_wdaddress,
  i_ir_writedata,
  i_ir_rwn,
  o_ir_done,
  o_ir_readdata

);


//********************************************************************************
// PARAMETERS
//********************************************************************************
  parameter ADDR_WIDTH = 16;
  parameter RDAT_WIDTH = 16;
  parameter WDAT_WIDTH = 16;

  parameter IREG_CHADDR_WIDTH = 16;
  parameter IREG_WDADDR_WIDTH = 16;
  parameter IREG_DATA_WIDTH   = 16;
  
  parameter ST_IDLE  = 3'd0;
  parameter ST_WRITE = 3'd1;
  parameter ST_READ  = 3'd2;
  parameter ST_ADAPT_READ  = 3'd3;
  parameter ST_ADAPT_WRITE = 3'd4;
  parameter ST_RESET_READ  = 3'd5;
  parameter ST_RESET_WRITE = 3'd6;
//********************************************************************************
// DECLARATIONS
//********************************************************************************
  input                       i_resetn;
  input                       i_avmm_clk;
  input  [RDAT_WIDTH-1:0]     i_avmm_mreaddata;
  input                       i_avmm_mwaitrequest;
  output reg [ADDR_WIDTH-1:0] o_avmm_maddress;
  output reg                  o_avmm_mread;
  output reg                  o_avmm_mwrite;
  output reg [WDAT_WIDTH-1:0] o_avmm_mwritedata;
  output reg                  o_avmm_marbiterlock;

  input                            i_ir_trigger; // this will be a single clock pulse wide (synchronous)
  input  [IREG_CHADDR_WIDTH-1:0]   i_ir_chaddress;
  input  [IREG_WDADDR_WIDTH-1:0]   i_ir_wdaddress;
  input  [IREG_DATA_WIDTH-1:0]     i_ir_writedata;
  input                            i_ir_rwn; // this should be a level for the duration of an operation
  output reg                       o_ir_done;
  output reg [IREG_DATA_WIDTH-1:0] o_ir_readdata;

(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [2:0] state;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [2:0] state0q;
  reg [15:0] dprio_address;
  reg avmm_mwaitrequest0q;

  wire set_adce_adapt = (state == ST_ADAPT_WRITE) || (state == ST_ADAPT_READ);
  wire set_adce_reset = (state == ST_RESET_WRITE) || (state == ST_RESET_READ);
  // use 'state', not 'state0q', or data might not be set at start of dprio read/write operation
  
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
      avmm_mwaitrequest0q <= 1'b0;
    end else begin
      state0q <= state;
      avmm_mwaitrequest0q <= i_avmm_mwaitrequest;
    end
  end

//********************************************************************************
// Combinational Logic
//********************************************************************************
// address conversion logic - convert avalon MM addresses to dprio address space
// addresses are guaranteed to be correct - slave checks for a valid channel address, and 
//  will not issue an operation to the master if an invalid channel address is provided.

//********************************************************************************
// Register Map
// Avalon Address | DPRIO Address | Avalon bitmap | DPRIO bitmap
//            0x0 |         0x807 |  bit      [0] | bit      [6]
//                |               |  bit      [1] | bit      [7]
//                |               |  bit      [2] | bit     [10]
//                |               |  bits  [15:2] |     reserved
// -------------------------------------------------------------
//            0x1 |         0xC08 |  bit      [0] | bit      [4]
//                |               |  bits   [3:1] | bits  [11:9]
//                |               |  bits  [15:4] |     reserved
// -------------------------------------------------------------
//            0x2 |         0xC0A |  bits   [2:0] | bits [15:13]
//                |               |  bits   [5:3] | bits [12:10]
//                |               |  bits  [15:6] |     reserved
//********************************************************************************
  always @ (*) begin
    dprio_address = {2'b0, i_ir_chaddress[1:0], 12'h0};
    o_ir_readdata       = 16'h0;
    o_avmm_mwritedata   = 16'h0;
    if (set_adce_adapt) begin // write RADCE_ADAPT = 1'b1
      dprio_address[11:0] = 12'hC0C;
      o_avmm_mwritedata   = {i_avmm_mreaddata[15:13], 1'b1, i_avmm_mreaddata[11:0]};
    end else if (set_adce_reset) begin // write RADCE_RST = 1'b1 (put ADCE engine in reset)
      dprio_address[11:0] = 12'hC0E;
      o_avmm_mwritedata   = {i_avmm_mreaddata[15:2], 1'b1, i_avmm_mreaddata[0]};
    end else begin
      if (i_ir_wdaddress == 'h0) begin
        dprio_address[11:0] = 12'h807;
        o_ir_readdata       = {13'b0, i_avmm_mreaddata[10], i_avmm_mreaddata[7:6]}; // direct assignment - only works with the mutex, otherwise we might get corrupted data
        o_avmm_mwritedata   = {i_avmm_mreaddata[15:11], i_ir_writedata[2], i_avmm_mreaddata[9:8], i_ir_writedata[1:0], i_avmm_mreaddata[5:0]};
      end else if (i_ir_wdaddress == 'h1) begin
        dprio_address[11:0] = 12'hC08;
        o_ir_readdata       = {12'b0, i_avmm_mreaddata[11:9], i_avmm_mreaddata[4]};
        o_avmm_mwritedata   = {i_avmm_mreaddata[15:12], i_ir_writedata[3:1], i_avmm_mreaddata[8:5], i_ir_writedata[0], i_avmm_mreaddata[3:0]};
      end else if (i_ir_wdaddress == 'h2) begin
        dprio_address[11:0] = 12'hC0A;
        o_ir_readdata       = {10'b0, i_avmm_mreaddata[12:10], i_avmm_mreaddata[15:13]};
        o_avmm_mwritedata   = {i_ir_writedata[2:0], i_ir_writedata[5:3], i_avmm_mreaddata[9:0]};
      end
    end
  end

  
  // When reading and writing to the DFE_EN bit, we must also do a read and write to the 
  //  ADCE register to enable/disable the ADCE_ADAPT bit
  always @ (*) begin
    o_ir_done       = 1'b0;
    o_avmm_maddress = dprio_address; // address should be static from slave during an operation
    case (state0q)
      ST_READ: begin // read operation, or read portion of read-modify-write operation
        o_avmm_marbiterlock = 1'b1;
        o_avmm_mread  = 1'b1;
        o_avmm_mwrite = 1'b0;
        if (avmm_mwaitrequest0q) begin // waitrequest asserted - slave is busy
          state = ST_READ;
        end else begin // waitrequest not asserted or deasserted - slave is done, data is ready
          if (i_ir_rwn) begin // read operation
            o_avmm_mread  = 1'b0;
            o_avmm_mwrite = 1'b0;
            o_avmm_marbiterlock = 1'b0;
            o_ir_done           = 1'b1; // done signals to slave that data is committed (write) or is ready for reading (read)
            state = ST_IDLE;
          end else begin // write operation - proceed to ST_WRITE
            o_avmm_mread  = 1'b0;
            o_avmm_mwrite = 1'b1;
            state = ST_WRITE;
          end
        end
      end
      ST_WRITE: begin // write portion of read-modify-write operation
        o_avmm_marbiterlock = 1'b1;
        o_avmm_mread  = 1'b0;
        o_avmm_mwrite = 1'b1;
        if (avmm_mwaitrequest0q) begin
          state = ST_WRITE;
        end else begin
          // If setting the enable bit, then we make sure the RADCE_ADAPT bit is set, and set it if it is not.
          // We don't unset the ADAPT bit, since ADCE might be running.  
          // Even in one-time mode, ADCE sets the RADCE_PDB bit to 0, so if DFE sets the RADCE_ADAPT bit to 0, 
          //  then the Equalizer will completely shut off, which is undesired.
          // We also need to place the ADCE adaptive engine into reset.  This is not a problem for
          //  one-time mode, since the adaptive engine shouldn't be running after one-time mode anyways
          // This will need to change if continuous mode is ever supported.
          if (i_ir_wdaddress == 1'b1 && i_ir_writedata[0]) begin
            state = ST_ADAPT_READ;
            o_avmm_mread  = 1'b1;
            o_avmm_mwrite = 1'b0;
          end else begin
            o_avmm_mread  = 1'b0;
            o_avmm_mwrite = 1'b0;
            o_avmm_marbiterlock = 1'b0;
            o_ir_done = 1'b1;
            state     = ST_IDLE;
          end
        end
      end
      ST_ADAPT_READ: begin
        o_avmm_marbiterlock = 1'b1;
        o_avmm_mread  = 1'b1;
        o_avmm_mwrite = 1'b0;
        if (avmm_mwaitrequest0q) begin // waitrequest asserted - slave is busy
          state = ST_ADAPT_READ;
        end else begin // waitrequest not asserted or deasserted - slave is done, data is ready
          o_avmm_mread  = 1'b0;
          o_avmm_mwrite = 1'b1;
          state = ST_ADAPT_WRITE;
        end
      end
      ST_ADAPT_WRITE: begin
        o_avmm_marbiterlock = 1'b1;
        o_avmm_mread  = 1'b0;
        o_avmm_mwrite = 1'b1;
        if (avmm_mwaitrequest0q) begin
          state = ST_ADAPT_WRITE;
        end else begin
          o_avmm_mread  = 1'b1;
          o_avmm_mwrite = 1'b0;
          state = ST_RESET_READ; // ADCE engine is guaranteed to not be running because of mutex, and the fact that we only support one-time mode
        end
      end
      ST_RESET_READ: begin
        o_avmm_marbiterlock = 1'b1;
        o_avmm_mread  = 1'b1;
        o_avmm_mwrite = 1'b0;
        if (avmm_mwaitrequest0q) begin // waitrequest asserted - slave is busy
          state = ST_RESET_READ;
        end else begin // waitrequest not asserted or deasserted - slave is done, data is ready
          o_avmm_mread  = 1'b0;
          o_avmm_mwrite = 1'b1;
          state = ST_RESET_WRITE;
        end
      end
      ST_RESET_WRITE: begin
        o_avmm_marbiterlock = 1'b1;
        o_avmm_mread  = 1'b0;
        o_avmm_mwrite = 1'b1;
        if (avmm_mwaitrequest0q) begin
          state = ST_RESET_WRITE;
        end else begin
          o_avmm_mread  = 1'b0;
          o_avmm_mwrite = 1'b0;
          o_avmm_marbiterlock = 1'b0;
          o_ir_done = 1'b1;
          state     = ST_IDLE;
        end
      end
      default: begin //ST_IDLE: begin
        if (i_ir_trigger) begin
          o_avmm_marbiterlock = 1'b1;
          o_avmm_mread  = 1'b1;
          o_avmm_mwrite = 1'b0;
          state = ST_READ;
        end else begin
          o_avmm_marbiterlock = 1'b0;
          o_avmm_mread  = 1'b0;
          o_avmm_mwrite = 1'b0;
          state = ST_IDLE;
        end
      end
    endcase
  end


endmodule
