//********************************************************************************
// This module contains the logic for the Avalon MM master interface
//
// Instantiations: none
//
//********************************************************************************


module alt_eyemon_avmm_master (
  i_resetn,
  i_avmm_clk,
  i_avmm_mreaddata,
  i_avmm_mwaitrequest,
  o_avmm_maddress,
  o_avmm_mread,
  o_avmm_mwrite,
  o_avmm_mwritedata,
  o_avmm_marbiterlock,

  i_remap,
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
  
  parameter ST_IDLE  = 2'd0;
  parameter ST_WRITE = 2'd1;
  parameter ST_READ  = 2'd2;
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

  input                            i_remap;
  input                            i_ir_trigger; // this will be a single clock pulse wide (synchronous)
  input  [IREG_CHADDR_WIDTH-1:0]   i_ir_chaddress;
  input  [IREG_WDADDR_WIDTH-1:0]   i_ir_wdaddress;
  input  [IREG_DATA_WIDTH-1:0]     i_ir_writedata;
  input                            i_ir_rwn; // this should be a level for the duration of an operation
  output reg                       o_ir_done;
  output reg [IREG_DATA_WIDTH-1:0] o_ir_readdata;

(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [1:0] state;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [1:0] state0q;
  reg [15:0] dprio_address;

// synopsys translate_off
  initial begin
    state         = 'b0;
    state0q       = 'b0;
  end
// synopsys translate_on  

  wire [5:0] rom_data;
  wire [5:0] invrom_data;
    
  alt_eyemon_rom alt_eyemon_rom_inst0 (
    .i_addr (i_ir_writedata[5:0]),
    .o_data (rom_data)
  );

alt_eyemon_invrom alt_eyemon_invrom_inst0 (
    .i_addr (i_avmm_mreaddata[5:0]),
    .o_data (invrom_data)
  );

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
// address conversion logic - convert avalon MM addresses to dprio address space
// addresses are guaranteed to be correct - slave checks for a valid channel address, and 
//  will not issue an operation to the master if an invalid channel address is provided.

//********************************************************************************
// Register Map
// Avalon Address | DPRIO Address | Avalon bitmap | DPRIO bitmap
//            0x0 |         0xC08 |  bit      [0] | bit     [14]
//                |               |  bits  [15:1] |     reserved
// -------------------------------------------------------------
//            0x1 |         0xC07 |  bits   [5:0] | bits   [5:0]
//                |               |  bits  [15:6] |     reserved
//********************************************************************************
  always @ (*) begin
    dprio_address = {2'b0, i_ir_chaddress[1:0], 12'h0};
    o_ir_readdata       = 16'h0;
    o_avmm_mwritedata   = 16'h0;
    if (i_ir_wdaddress == 'h0) begin
      dprio_address[11:0] = 12'hC08;
      o_ir_readdata       = {15'b0, i_avmm_mreaddata[14]};
      o_avmm_mwritedata   = {i_avmm_mreaddata[15], i_ir_writedata[0], i_avmm_mreaddata[13:0]};
    end else if (i_ir_wdaddress == 'h1) begin
      dprio_address[11:0] = 12'hC07;
      o_ir_readdata[15:6] = 10'b0;
      o_ir_readdata[5:0]  = i_remap ? invrom_data : i_avmm_mreaddata[5:0];
      o_avmm_mwritedata[15:6] = i_avmm_mreaddata[15:6];
      o_avmm_mwritedata[5:0]  = i_remap ? rom_data : i_ir_writedata[5:0];
    end
  end

  always @ (*) begin
    o_ir_done       = 1'b0;
    o_avmm_maddress = dprio_address; // address should be static from slave during an operation
    case (state0q)
      ST_READ: begin // read operation, or read portion of read-modify-write operation
        o_avmm_marbiterlock = 1'b1;
        o_avmm_mread  = 1'b1;
        o_avmm_mwrite = 1'b0;
        if (i_avmm_mwaitrequest) begin // waitrequest asserted - slave is busy
          state = ST_READ;
        end else begin // waitrequest not asserted or deasserted - slave is done, data is ready
          if (i_ir_rwn) begin // read operation
            o_avmm_marbiterlock = 1'b0;
            o_ir_done = 1'b1; // done signals to slave that data is committed (write) or is ready for reading (read)
            state = ST_IDLE;
          end else begin // write operation - proceed to ST_WRITE
            state = ST_WRITE;
          end
        end
      end
      ST_WRITE: begin // write portion of read-modify-write operation
        o_avmm_marbiterlock = 1'b1;
        o_avmm_mread = 1'b0;
        o_avmm_mwrite = 1'b1;
        if (i_avmm_mwaitrequest) begin
          state = ST_WRITE;
        end else begin
          o_avmm_marbiterlock = 1'b0;
          o_ir_done = 1'b1;
          state = ST_IDLE;
        end
      end
      default: begin //ST_IDLE: begin
        if (i_ir_trigger) begin
          o_avmm_marbiterlock = 1'b1;
          o_avmm_mread = 1'b1;
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
