`timescale 1ns / 1ps

// import axi4stream_vip_pkg::*;


// parameter axi4stream_vip_mst_0_VIP_INTERFACE_MODE     = 0;
// parameter axi4stream_vip_mst_0_VIP_SIGNAL_SET         = 8'B00000011;
// parameter axi4stream_vip_mst_0_VIP_DATA_WIDTH         = 8;
// parameter axi4stream_vip_mst_0_VIP_ID_WIDTH           = 0;
// parameter axi4stream_vip_mst_0_VIP_DEST_WIDTH         = 0;
// parameter axi4stream_vip_mst_0_VIP_USER_WIDTH         = 0;
// parameter axi4stream_vip_mst_0_VIP_USER_BITS_PER_BYTE = 0;
// parameter axi4stream_vip_mst_0_VIP_HAS_TREADY         = 1;
// parameter axi4stream_vip_mst_0_VIP_HAS_TSTRB          = 0;
// parameter axi4stream_vip_mst_0_VIP_HAS_TKEEP          = 0;
// parameter axi4stream_vip_mst_0_VIP_HAS_TLAST          = 0;
// parameter axi4stream_vip_mst_0_VIP_HAS_ACLKEN         = 0;
// parameter axi4stream_vip_mst_0_VIP_HAS_ARESETN        = 1;

// typedef axi4stream_mst_agent #(
//   axi4stream_vip_mst_0_VIP_SIGNAL_SET, 
//   axi4stream_vip_mst_0_VIP_DEST_WIDTH,
//   axi4stream_vip_mst_0_VIP_DATA_WIDTH,
//   axi4stream_vip_mst_0_VIP_ID_WIDTH,
//   axi4stream_vip_mst_0_VIP_USER_WIDTH, 
//   axi4stream_vip_mst_0_VIP_USER_BITS_PER_BYTE,
//   axi4stream_vip_mst_0_VIP_HAS_ARESETN
// ) axi4stream_vip_mst_0_mst_t;
 








module frequency_change_DMA_tb;



//  axi4stream_vip_mst_0_mst_t  mst_agent;
//  axi4stream_transaction      wr_transaction; 


  // Master VIP agent verbosity level
  //  xil_axi4stream_uint mst_agent_verbosity = 1;


  bit aclk;
  bit aresetn;
  
  reg [47:0]dac0_nco_freq;
  bit dac0_nco_phase;
  bit dac0_nco_phase_rst;
  bit dac0_nco_update_en;
  bit dac0_nco_update_busy;
  bit dac0_nco_update_req;
  
  reg [63:0] TDATA = 87263447;
  reg TLAST;
  reg TVALID = 0;
  reg TRIGGER=1;
  wire TREADY;
  
  

  initial begin
    aresetn <= 1'b1;
  end
  
  always #10ns aclk <= ~aclk;


  //axi4_stream_if #(.DN (1), .DT (logic signed [63:0])) str (.ACLK (aclk), .ARESETn (aresetn));

  //axi4stream_vip_mst_0  axi4stream_vip_mst (.m_axis (str));


  
  // always @(posedge aclk)
  // begin
  //       if (TREADY == 1) TDATA <= ~ TDATA;
  // end
  
  
  
  initial
  begin
  
  
  #1000 TVALID = 1;
    #1200 TRIGGER = 0;
      #1210 TRIGGER = 1;
    #2000 dac0_nco_update_busy=1;
    #3000 TDATA = 87263447 + 2**63;  
    #3100 TDATA = 87263447;
    #3150 dac0_nco_update_busy=0;
    #3200 TRIGGER = 0;
      #3210 TRIGGER = 1;
  #4000 TVALID = 0;

  
//    mst_agent = new("master vip agent", axi4stream_vip_mst.inst.IF);
//    mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);

//    mst_agent.set_agent_tag("Master VIP");
//    mst_agent.set_verbosity(mst_agent_verbosity);


//    mst_agent.start_master();


//    mtestWData = 64'h767776755;

//    wr_transaction = mst_agent.driver.create_transaction("write transaction");

//    #1000 wr_transaction.set_data({mtestWData});

//    mst_agent.driver.send(wr_transaction);

 

  end


frequency_change_DMA dut (
    // AXI4Stream sink: Clock
		.S_AXIS_ACLK(aclk),
		// AXI4Stream sink: Reset
		.S_AXIS_ARESETN(aresetn),
		// Ready to accept data in
		.S_AXIS_TREADY(TREADY),
		// Data in
		.S_AXIS_TDATA(TDATA),
		// Byte qualifier
		//.S_AXIS_TSTRB(),
		// Indicates boundary of last packet
		.S_AXIS_TLAST(TLAST),
		// Data is in valid
		.S_AXIS_TVALID(TVALID),
    .EX_TRIGGER(TRIGGER),

        .dac0_nco_freq(dac0_nco_freq),
        .dac0_nco_phase(dac0_nco_phase),
        .dac0_nco_phase_rst(dac0_nco_phase_rst),
        .dac0_nco_update_en(dac0_nco_update_en),
        .dac0_nco_update_busy(dac0_nco_update_busy),
        .dac0_nco_update_req(dac0_nco_update_req)
);







endmodule