//********************************************************************************
// This module acts as the top level wrapper for all the eye monitor logic.
//
// Instantiations: alt_eyemon_avmm_slave, alt_eyemon_avmm_master, 
//                 alt_eyemon_avmm2dprio
//********************************************************************************

module alt_eyemon (
  i_resetn, 
  i_avmm_clk,
  i_avmm_saddress,
  i_avmm_sread,
  i_avmm_swrite,
  i_avmm_swritedata,
//  i_avmm_sbegintransfer,
  o_avmm_sreaddata,
  o_avmm_swaitrequest,

  i_remap_phase, // remap setting for phase steps
  i_remap_address,
  o_quad_address,
  o_reconfig_busy,

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
// do we want the avalon port widths to be paramaters?
//  parameter number_of_channels = 5; // we don't need this
  parameter channel_address_width = 3;
  parameter lpm_type = "alt_eyemon";
  parameter lpm_hint = "UNUSED";

  parameter avmm_slave_addr_width = 16; // tbd
  parameter avmm_slave_rdata_width = 16;
  parameter avmm_slave_wdata_width = 16;

  parameter avmm_master_addr_width = 16;
  parameter avmm_master_rdata_width = 16;
  parameter avmm_master_wdata_width = 16;

  parameter dprio_addr_width = 16;
  parameter dprio_data_width = 16;
  parameter ireg_chaddr_width = channel_address_width;
  parameter ireg_wdaddr_width = 2; // width of 2 - only need to address 4 registers
  parameter ireg_data_width   = 16;
  
//********************************************************************************
// DECLARATIONS
//********************************************************************************

  input                               i_resetn;
  input                               i_avmm_clk;

  // avalon slave ports
  input  [avmm_slave_addr_width-1:0]  i_avmm_saddress;
  input                               i_avmm_sread;
  input                               i_avmm_swrite;
  input  [avmm_slave_wdata_width-1:0] i_avmm_swritedata;
//  input                               i_avmm_sbegintransfer;
  output [avmm_slave_rdata_width-1:0] o_avmm_sreaddata;
  output                              o_avmm_swaitrequest;

  input         i_remap_phase;
  input  [11:0] i_remap_address; // from address_pres_reg
  output [8:0]  o_quad_address; // output to altgx_reconfig
  output        o_reconfig_busy; // output to altgx_reconfig - 'or' into busy signal

  // alt_dprio interface
  input                         i_dprio_busy;
  input  [dprio_data_width-1:0] i_dprio_in;
  output                        o_dprio_wren;
  output                        o_dprio_rden;
  output [dprio_addr_width-1:0] o_dprio_addr;
  output [dprio_data_width-1:0] o_dprio_data;

  // avalon master ports - not for 9.1
//  input  [avmm_master_addr_width-1:0]  i_avmm_maddress;
//  input                                i_avmm_mread;
//  input                                i_avmm_mwrite;
//  input  [avmm_master_wdata_width-1:0] i_avmm_mwritedata;
//  input                                i_avmm_mbegintransfer;
//  output [avmm_master_rdata_width-1:0] o_avmm_mreaddata;
//  output                               o_avmm_mwaitrequest;
//  output                               o_avmm_marbiterlock; // needed to do read-modify-write

  // add wires for connectivity
  // shadow register <-> master wires
  wire                       m2ir_done;
  wire [ireg_data_width-1:0] m2ir_readdata;
  wire                       ir2m_trigger;
  wire [ireg_chaddr_width-1:0] ir2m_chaddress;
  wire [ireg_wdaddr_width-1:0] ir2m_wdaddress;
  wire [ireg_data_width-1:0] ir2m_writedata;
  wire                       ir2m_rwn;

  // avmm2dprio <-> master wires
  wire [avmm_master_addr_width-1:0]  av2dprio_address;
  wire                               av2dprio_read;
  wire                               av2dprio_write;
  wire [avmm_master_wdata_width-1:0] av2dprio_writedata;
  wire                               av2dprio_begintransfer;
  wire [avmm_master_rdata_width-1:0] dprio2av_readdata;
  wire                               dprio2av_waitrequest;


//********************************************************************************
// Combinational Logic
//********************************************************************************
//  assign o_quad_address = i_remap_address[11:3];

  wire [10:0] temp_quad_address = {{11 - ireg_chaddr_width{1'b0}}, ir2m_chaddress};
  assign o_quad_address = {1'b0, temp_quad_address[9:2]};

//********************************************************************************
// Instantiations
//********************************************************************************

  // Avalon MM slave interface logic
generate
  if (ireg_chaddr_width < 3) begin
  alt_eyemon_avmm_slave alt_eyemon_avmm_slave_inst0 (
    .i_resetn               (i_resetn),
    .i_avmm_clk             (i_avmm_clk),
    .i_avmm_saddress        (i_avmm_saddress),
    .i_avmm_sread           (i_avmm_sread),
    .i_avmm_swrite          (i_avmm_swrite),
    .i_avmm_swritedata      (i_avmm_swritedata),
//    .i_avmm_sbegintransfer  (i_avmm_sbegintransfer),
    .o_avmm_sreaddata       (o_avmm_sreaddata),
    .o_avmm_swaitrequest    (o_avmm_swaitrequest),

    .i_remap_address        (i_remap_address),
    .o_reconfig_busy        (o_reconfig_busy),

    .i_ir_mdone             (m2ir_done),
    .i_ir_mreaddata         (m2ir_readdata),
    .o_ir_mtrigger          (ir2m_trigger),
    .o_ir_mchaddress        (ir2m_chaddress),
    .o_ir_mwdaddress        (ir2m_wdaddress),
    .o_ir_mwritedata        (ir2m_writedata),
    .o_ir_mrwn              (ir2m_rwn)
  );
    defparam
      alt_eyemon_avmm_slave_inst0.ADDR_WIDTH  = avmm_slave_addr_width,
      alt_eyemon_avmm_slave_inst0.RDATA_WIDTH = avmm_slave_rdata_width,
      alt_eyemon_avmm_slave_inst0.WDATA_WIDTH = avmm_slave_wdata_width,
      alt_eyemon_avmm_slave_inst0.IREG_DATA_WIDTH = ireg_data_width,
      alt_eyemon_avmm_slave_inst0.IREG_CHADDR_WIDTH = 3,
      alt_eyemon_avmm_slave_inst0.IREG_WDADDR_WIDTH = ireg_wdaddr_width;
  end else begin
  alt_eyemon_avmm_slave alt_eyemon_avmm_slave_inst0 (
    .i_resetn               (i_resetn),
    .i_avmm_clk             (i_avmm_clk),
    .i_avmm_saddress        (i_avmm_saddress),
    .i_avmm_sread           (i_avmm_sread),
    .i_avmm_swrite          (i_avmm_swrite),
    .i_avmm_swritedata      (i_avmm_swritedata),
//    .i_avmm_sbegintransfer  (i_avmm_sbegintransfer),
    .o_avmm_sreaddata       (o_avmm_sreaddata),
    .o_avmm_swaitrequest    (o_avmm_swaitrequest),

    .i_remap_address        (i_remap_address),
    .o_reconfig_busy        (o_reconfig_busy),

    .i_ir_mdone             (m2ir_done),
    .i_ir_mreaddata         (m2ir_readdata),
    .o_ir_mtrigger          (ir2m_trigger),
    .o_ir_mchaddress        (ir2m_chaddress),
    .o_ir_mwdaddress        (ir2m_wdaddress),
    .o_ir_mwritedata        (ir2m_writedata),
    .o_ir_mrwn              (ir2m_rwn)
  );
    defparam
      alt_eyemon_avmm_slave_inst0.ADDR_WIDTH  = avmm_slave_addr_width,
      alt_eyemon_avmm_slave_inst0.RDATA_WIDTH = avmm_slave_rdata_width,
      alt_eyemon_avmm_slave_inst0.WDATA_WIDTH = avmm_slave_wdata_width,
      alt_eyemon_avmm_slave_inst0.IREG_DATA_WIDTH = ireg_data_width,
      alt_eyemon_avmm_slave_inst0.IREG_CHADDR_WIDTH = ireg_chaddr_width,
      alt_eyemon_avmm_slave_inst0.IREG_WDADDR_WIDTH = ireg_wdaddr_width;
  end
endgenerate

  // Avalon MM master interface logic
generate
  if (ireg_chaddr_width < 3) begin
  alt_eyemon_avmm_master alt_eyemon_avmm_master_inst0 (
    .i_resetn             (i_resetn),
    .i_avmm_clk           (i_avmm_clk),
    .i_avmm_mreaddata     (dprio2av_readdata),
    .i_avmm_mwaitrequest  (dprio2av_waitrequest),
    .o_avmm_maddress      (av2dprio_address),
    .o_avmm_mread         (av2dprio_read),
    .o_avmm_mwrite        (av2dprio_write),
    .o_avmm_mwritedata    (av2dprio_writedata),
//    .o_avmm_marbiterlock  (o_avmm_marbiterlock),
    .o_avmm_marbiterlock  (), // not connected for 9.1 legacy fabric

    .i_remap              (i_remap_phase),
    .i_ir_trigger         (ir2m_trigger),
    .i_ir_chaddress       (ir2m_chaddress), // channel address - do we instead output to address_pres_reg?
    .i_ir_wdaddress       (ir2m_wdaddress), // word address - from memory map
    .i_ir_writedata       (ir2m_writedata),
    .i_ir_rwn             (ir2m_rwn),
    .o_ir_done            (m2ir_done),
    .o_ir_readdata        (m2ir_readdata)
  );
  defparam
      alt_eyemon_avmm_master_inst0.ADDR_WIDTH = avmm_master_addr_width,
      alt_eyemon_avmm_master_inst0.RDAT_WIDTH = avmm_master_rdata_width,
      alt_eyemon_avmm_master_inst0.WDAT_WIDTH = avmm_master_wdata_width,
      alt_eyemon_avmm_master_inst0.IREG_DATA_WIDTH = ireg_data_width,
      alt_eyemon_avmm_master_inst0.IREG_CHADDR_WIDTH = 3,
      alt_eyemon_avmm_master_inst0.IREG_WDADDR_WIDTH = ireg_wdaddr_width;
  end else begin
  alt_eyemon_avmm_master alt_eyemon_avmm_master_inst0 (
    .i_resetn             (i_resetn),
    .i_avmm_clk           (i_avmm_clk),
    .i_avmm_mreaddata     (dprio2av_readdata),
    .i_avmm_mwaitrequest  (dprio2av_waitrequest),
    .o_avmm_maddress      (av2dprio_address),
    .o_avmm_mread         (av2dprio_read),
    .o_avmm_mwrite        (av2dprio_write),
    .o_avmm_mwritedata    (av2dprio_writedata),
//    .o_avmm_marbiterlock  (o_avmm_marbiterlock),
    .o_avmm_marbiterlock  (), // not connected for 9.1 legacy fabric

    .i_remap              (i_remap_phase),
    .i_ir_trigger         (ir2m_trigger),
    .i_ir_chaddress       (ir2m_chaddress), // channel address - do we instead output to address_pres_reg?
    .i_ir_wdaddress       (ir2m_wdaddress), // word address - from memory map
    .i_ir_writedata       (ir2m_writedata),
    .i_ir_rwn             (ir2m_rwn),
    .o_ir_done            (m2ir_done),
    .o_ir_readdata        (m2ir_readdata)
  );
  defparam
      alt_eyemon_avmm_master_inst0.ADDR_WIDTH = avmm_master_addr_width,
      alt_eyemon_avmm_master_inst0.RDAT_WIDTH = avmm_master_rdata_width,
      alt_eyemon_avmm_master_inst0.WDAT_WIDTH = avmm_master_wdata_width,
      alt_eyemon_avmm_master_inst0.IREG_DATA_WIDTH = ireg_data_width,
      alt_eyemon_avmm_master_inst0.IREG_CHADDR_WIDTH = ireg_chaddr_width,
      alt_eyemon_avmm_master_inst0.IREG_WDADDR_WIDTH = ireg_wdaddr_width;
  end
endgenerate



  // Avalon MM to alt_dprio gasket logic
  alt_eyemon_avmm2dprio alt_eyemon_avmm2dprio_inst0 (
    .i_resetn            (i_resetn),
    .i_avmm_clk          (i_avmm_clk),
    .i_avmm_address      (av2dprio_address),
    .i_avmm_read         (av2dprio_read),
    .i_avmm_write        (av2dprio_write),
    .i_avmm_writedata    (av2dprio_writedata),
    .o_avmm_readdata     (dprio2av_readdata),
    .o_avmm_waitrequest  (dprio2av_waitrequest),
    .i_remap_address     (i_remap_address),
  
    .i_dprio_busy        (i_dprio_busy),
    .i_dprio_in          (i_dprio_in),
    .o_dprio_wren        (o_dprio_wren),
    .o_dprio_rden        (o_dprio_rden),
    .o_dprio_addr        (o_dprio_addr),
    .o_dprio_data        (o_dprio_data)
  );
  defparam
    alt_eyemon_avmm2dprio_inst0.AVMM_ADDR_WIDTH = avmm_master_addr_width,
    alt_eyemon_avmm2dprio_inst0.AVMM_RDAT_WIDTH = avmm_master_rdata_width,
    alt_eyemon_avmm2dprio_inst0.AVMM_WDAT_WIDTH = avmm_master_wdata_width,
    alt_eyemon_avmm2dprio_inst0.DPRIO_ADDR_WIDTH = dprio_addr_width,
    alt_eyemon_avmm2dprio_inst0.DPRIO_DATA_WIDTH = dprio_data_width;
    


endmodule
