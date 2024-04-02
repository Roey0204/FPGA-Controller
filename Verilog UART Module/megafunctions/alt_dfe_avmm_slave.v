  //********************************************************************************
// This module contains the logic for the Avalon MM slave interface, as well as 
//  the logic for the shadow registers.
//
// Instantiations: alt_dfe_avmm_slave_sreg
//
//********************************************************************************


module alt_dfe_avmm_slave (
  i_resetn,
  i_avmm_clk,
  i_avmm_saddress,
  i_avmm_sread,
  i_avmm_swrite,
  i_avmm_swritedata,
//  i_avmm_sbegintransfer,
  o_avmm_sreaddata,
  o_avmm_swaitrequest,
 
  i_remap_address,
  o_reconfig_busy,

  i_ir_mdone,  
  i_ir_mreaddata,
  o_ir_mtrigger,
  o_ir_mchaddress,
  o_ir_mwdaddress,
  o_ir_mwritedata,
  o_ir_mrwn
);



//********************************************************************************
// PARAMETERS
//********************************************************************************
  parameter ADDR_WIDTH  = 16;
  parameter RDATA_WIDTH = 16;
  parameter WDATA_WIDTH = 16;

  parameter IREG_CHADDR_WIDTH = 16;
  parameter IREG_WDADDR_WIDTH = 16;
  parameter IREG_DATA_WIDTH   = 16;

  parameter ST_IDLE  = 2'd0;
  parameter ST_WRITE = 2'd1;
  parameter ST_READ  = 2'd2;
  
//********************************************************************************
// DECLARATIONS
//********************************************************************************
  input                        i_resetn;
  input                        i_avmm_clk;
  input  [ADDR_WIDTH-1:0]      i_avmm_saddress;
  input                        i_avmm_sread;
  input                        i_avmm_swrite;
  input  [WDATA_WIDTH-1:0]     i_avmm_swritedata;
//  input                        i_avmm_sbegintransfer;
  output [RDATA_WIDTH-1:0]     o_avmm_sreaddata;
  output reg                   o_avmm_swaitrequest; // combinational assignment - do not flop
  
  input [11:0] i_remap_address; // from address_pres_reg
  output       o_reconfig_busy;
  
  input                          i_ir_mdone;
  input  [IREG_DATA_WIDTH-1:0]   i_ir_mreaddata;
  output                         o_ir_mtrigger;
  output [IREG_CHADDR_WIDTH-1:0] o_ir_mchaddress;
  output [IREG_WDADDR_WIDTH-1:0] o_ir_mwdaddress;
  output [IREG_DATA_WIDTH-1:0]   o_ir_mwritedata;
  output                         o_ir_mrwn;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [1:0]  state;
(* ALTERA_ATTRIBUTE = {"POWER_UP_LEVEL=LOW"} *)
  reg [1:0] state0q;
  reg [15:0] avmm_sreaddata;
  reg        reg_read, reg_write;

// register file regs
//  reg [IREG_DATA_WIDTH-1:0] reg_chaddress, reg_chaddress0q;
  reg [IREG_CHADDR_WIDTH-1:0] reg_chaddress, reg_chaddress0q;
  reg [IREG_DATA_WIDTH-1:0] reg_data, reg_data0q;
  reg [IREG_DATA_WIDTH-1:0] reg_ctrlstatus, reg_ctrlstatus0q;
//  reg [IREG_DATA_WIDTH-1:0] reg_wdaddress, reg_wdaddress0q;
  reg [IREG_WDADDR_WIDTH-1:0] reg_wdaddress, reg_wdaddress0q;

  wire invalid_channel_address, invalid_word_address;
  
// synopsys translate_off
  initial begin
    state            = 'b0;
    state0q          = 'b0;
    reg_chaddress0q  = 'b0;
    reg_data0q       = 'b0;
    reg_ctrlstatus0q = 'b0;
    reg_wdaddress0q  = 'b0;
    reg_chaddress    = 'b0;
    reg_data         = 'b0;
    reg_ctrlstatus   = 'b0;
    reg_wdaddress    = 'b0;
  end
// synopsys translate_on  

  
//********************************************************************************
// Sequential Logic - Avalon Slave
//********************************************************************************
  // state flops
  always @ (posedge i_avmm_clk) begin
    if (~i_resetn) begin
      state0q <= ST_IDLE;
    end else begin
      state0q <= state;
    end
  end

//********************************************************************************
// Combinational Logic - Avalon Slave
//********************************************************************************
  assign o_reconfig_busy = reg_ctrlstatus0q[15];
  
  always @ (*) begin
    // avoid latches
    o_avmm_swaitrequest = 1'b0;
    reg_write           = 1'b0;
    reg_read            = 1'b0;
   
    case (state0q) 
      ST_WRITE: begin
        // check busy and discard the write data if we are busy
        o_avmm_swaitrequest = 1'b0;
        state = ST_IDLE; // single cycle write - always return to idle
      end
      ST_READ: begin
        o_avmm_swaitrequest = 1'b0;
        reg_read = 1'b1;
        state = ST_IDLE; // single cycle read - always return to idle
      end
      default: begin //ST_IDLE: begin
        // effectively priority encoded - if read and write both asserted (error condition), reads will take precedence
        // this ensures non-destructive behaviour
        if (i_avmm_sread) begin 
          o_avmm_swaitrequest = 1'b1;
          reg_read = 1'b1;
          state = ST_READ;
        end else if (i_avmm_swrite) begin
          o_avmm_swaitrequest = 1'b1;
          if (reg_ctrlstatus0q[15]) begin // don't commit the write if we are busy
            reg_write = 1'b0;
          end else begin
            reg_write = 1'b1;
          end
          state = ST_WRITE;
        end else begin
          o_avmm_swaitrequest = 1'b0;
          state = ST_IDLE;
        end
      end
    endcase
  end


//********************************************************************************
// Sequential Logic - Register File
//********************************************************************************
  // register file
  always @ (posedge i_avmm_clk) begin
    if (~i_resetn) begin
      reg_chaddress0q  <= 'b0;
      reg_data0q       <= 'b0;
      reg_ctrlstatus0q <= 'b0;
      reg_wdaddress0q  <= 'b0;
    end else begin
      reg_chaddress0q  <= reg_chaddress;
      reg_data0q       <= reg_data;
      reg_ctrlstatus0q <= reg_ctrlstatus;
      reg_wdaddress0q  <= reg_wdaddress;
    end
  end

//********************************************************************************
// Combinational Logic - Register File
//********************************************************************************

// address_pres_reg?  how do we want to do it?

//  assign reg_busy    = reg_ctrlstatus[15]; 
//  assign reg_busy0q  = reg_ctrlstatus0q[15]; // busy status
//  assign reg_error   = reg_ctrlstatus[14];
//  assign reg_error0q = reg_ctrlstatus0q[14]; // error status

// need to trigger the master state machine
  assign o_ir_mrwn = reg_ctrlstatus0q[1];
  assign o_ir_mchaddress = reg_chaddress0q;
  assign o_ir_mwdaddress = reg_wdaddress0q;
  assign o_ir_mwritedata = reg_data0q;

  // do we want it to be a level, or a single cycle?
  //assign o_ir_mtrigger   = (state0q == ST_WRITE); // one cycle pulse to master state machine
  assign o_ir_mtrigger   = reg_ctrlstatus[15] & ~reg_ctrlstatus0q[15]; // detect rising edge of busy - this is the trigger to the master state machine

  // read mux
  assign o_avmm_sreaddata = reg_read ? (({IREG_DATA_WIDTH{(i_avmm_saddress == 'h0)}} & reg_ctrlstatus0q) |
                                        ({IREG_DATA_WIDTH{(i_avmm_saddress == 'h1)}} & reg_chaddress0q)  |
                                        ({IREG_DATA_WIDTH{(i_avmm_saddress == 'h2)}} & reg_wdaddress0q)  |
                                        ({IREG_DATA_WIDTH{(i_avmm_saddress == 'h3)}} & reg_data0q)) : {RDATA_WIDTH{1'b0}};

  assign invalid_channel_address = (i_remap_address == 12'hfff);
  assign invalid_word_address    = (reg_wdaddress0q > 'h2);

  always @ (*) begin
    reg_chaddress    = reg_chaddress0q;
    reg_data         = reg_data0q;
    reg_ctrlstatus   = reg_ctrlstatus0q;
    reg_wdaddress    = reg_wdaddress0q;
  
  // handle busy condition - if mdone is raised, we clear reg_busy bit
    if (i_ir_mdone) begin
      reg_ctrlstatus[15] = 1'b0; // set busy to 0
      reg_ctrlstatus[0]  = 1'b0; // clear the 'start' bit as well
      if (reg_ctrlstatus0q[1]) begin// read operation
        reg_data = i_ir_mreaddata; // overwrite the data register upon completion
      end
    end

    // added for the MM component -> if we are busy, make sure to report any invalid channel addresses
    if (reg_ctrlstatus0q[15]) begin
      reg_ctrlstatus[13] = invalid_channel_address;
    end

  // write select for register file 
    if (reg_write) begin
      if (i_avmm_saddress == 'h0) begin
        reg_ctrlstatus[1] = i_avmm_swritedata[1];
        if (i_avmm_swritedata[0]) begin // writing to the start command bit
          if (invalid_channel_address || invalid_word_address) begin // invalid channel address
            reg_ctrlstatus[15] = 1'b0; // not busy - don't start the operation due to invalid address
            reg_ctrlstatus[14] = invalid_word_address;
            reg_ctrlstatus[13] = invalid_channel_address;
          end else begin // no error condition, start the operation, auto-clear any existing errors
            reg_ctrlstatus[0]  = 1'b1; // start bit asserted
            reg_ctrlstatus[15] = 1'b1; // assert busy
            reg_ctrlstatus[14] = 1'b0; // clear errors
            reg_ctrlstatus[13] = 1'b0; // clear errors
          end
        end else begin
          reg_ctrlstatus[15] = 1'b0; // do not assert busy
          reg_ctrlstatus[14] = i_avmm_swritedata[14] ? 1'b0 : reg_ctrlstatus0q[14]; // clear error
          reg_ctrlstatus[13] = i_avmm_swritedata[13] ? 1'b0 : reg_ctrlstatus0q[13]; // clear error        
        end
      end else if (i_avmm_saddress == 'h1) begin
        reg_chaddress = i_avmm_swritedata[IREG_CHADDR_WIDTH-1:0];
      end else if (i_avmm_saddress == 'h2) begin
        reg_wdaddress = i_avmm_swritedata[IREG_WDADDR_WIDTH-1:0];
      end else if (i_avmm_saddress == 'h3) begin
        reg_data = i_avmm_swritedata[IREG_DATA_WIDTH-1:0];
      end
      
      // do nothing if not a valid address
    end
  end

endmodule
