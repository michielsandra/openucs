// Author: Michiel Sandra, Lund University
`default_nettype none


module rfnoc_block_sounder_rx_tb;

  `include "test_exec.svh"

  import PkgTestExec::*;
  import PkgChdrUtils::*;
  import PkgRfnocBlockCtrlBfm::*;
  import PkgRfnocItemUtils::*;

  //---------------------------------------------------------------------------
  // Testbench Configuration //--------------------------------------------------------------------------- 
  localparam [31:0] NOC_ID          = 32'h0E870000;
  localparam [ 9:0] THIS_PORTID     = 10'h123;
  localparam int    CHDR_W          = 64;    // CHDR size in bits
  localparam int    MTU             = 10;    // Log2 of max transmission unit in CHDR words
  localparam int    NUM_PORTS       = 1;
  localparam int    NIPC            = 1;
  localparam int    NUM_PORTS_I     = 0+NUM_PORTS;
  localparam int    NUM_PORTS_O     = 0+NUM_PORTS;
  localparam int    ITEM_W          = 32;    // Sample size in bits
  localparam int    SPP             = 256;    // Samples per packet
  localparam int    PKT_SIZE_BYTES  = SPP * (ITEM_W/8);
  localparam int    STALL_PROB      = 90;    // Default BFM stall probability
  localparam real   CHDR_CLK_PER    = 5.0;   // 200 MHz
  localparam real   CTRL_CLK_PER    = 8.0;   // 125 MHz
  localparam real   CE_CLK_PER      = 8.0;   // 125 MHz

  //---------------------------------------------------------------------------
  // Clocks and Resets
  //---------------------------------------------------------------------------

  bit rfnoc_chdr_clk;
  bit rfnoc_ctrl_clk;
  bit ce_clk;

  sim_clock_gen #(CHDR_CLK_PER) rfnoc_chdr_clk_gen (.clk(rfnoc_chdr_clk), .rst());
  sim_clock_gen #(CTRL_CLK_PER) rfnoc_ctrl_clk_gen (.clk(rfnoc_ctrl_clk), .rst());
  sim_clock_gen #(CE_CLK_PER) ce_clk_gen (.clk(ce_clk), .rst());

  //---------------------------------------------------------------------------
  // Bus Functional Models
  //---------------------------------------------------------------------------

  // Backend Interface
  RfnocBackendIf backend (rfnoc_chdr_clk, rfnoc_ctrl_clk);

  // AXIS-Ctrl Interface
  AxiStreamIf #(32) m_ctrl (rfnoc_ctrl_clk, 1'b0);
  AxiStreamIf #(32) s_ctrl (rfnoc_ctrl_clk, 1'b0);

  // AXIS-CHDR Interfaces
  AxiStreamIf #(CHDR_W) m_chdr [NUM_PORTS_I] (rfnoc_chdr_clk, 1'b0);
  AxiStreamIf #(CHDR_W) s_chdr [NUM_PORTS_O] (rfnoc_chdr_clk, 1'b0);

  // Block Controller BFM
  RfnocBlockCtrlBfm #(CHDR_W, ITEM_W) blk_ctrl = new(backend, m_ctrl, s_ctrl);

  // CHDR word and item/sample data types
  typedef ChdrData #(CHDR_W, ITEM_W)::chdr_word_t chdr_word_t;
  typedef ChdrData #(CHDR_W, ITEM_W)::item_t      item_t;

  // Connect block controller to BFMs
  for (genvar i = 0; i < NUM_PORTS_I; i++) begin : gen_bfm_input_connections
    initial begin
      blk_ctrl.connect_master_data_port(i, m_chdr[i], PKT_SIZE_BYTES);
      blk_ctrl.set_master_stall_prob(i, STALL_PROB);
    end
  end
  for (genvar i = 0; i < NUM_PORTS_O; i++) begin : gen_bfm_output_connections
    initial begin
      blk_ctrl.connect_slave_data_port(i, s_chdr[i]);
      blk_ctrl.set_slave_stall_prob(i, STALL_PROB);
    end
  end

  //---------------------------------------------------------------------------
  // Device Under Test (DUT)
  //---------------------------------------------------------------------------

  // DUT Slave (Input) Port Signals
  logic [CHDR_W*NUM_PORTS_I-1:0] s_rfnoc_chdr_tdata;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tlast;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tvalid;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tready;

  // DUT Master (Output) Port Signals
  logic [CHDR_W*NUM_PORTS_O-1:0] m_rfnoc_chdr_tdata;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tlast;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tvalid;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tready;

  // Map the array of BFMs to a flat vector for the DUT connections
  for (genvar i = 0; i < NUM_PORTS_I; i++) begin : gen_dut_input_connections
    // Connect BFM master to DUT slave port
    assign s_rfnoc_chdr_tdata[CHDR_W*i+:CHDR_W] = m_chdr[i].tdata;
    assign s_rfnoc_chdr_tlast[i]                = m_chdr[i].tlast;
    assign s_rfnoc_chdr_tvalid[i]               = m_chdr[i].tvalid;
    assign m_chdr[i].tready                     = s_rfnoc_chdr_tready[i];
  end
  for (genvar i = 0; i < NUM_PORTS_O; i++) begin : gen_dut_output_connections
    // Connect BFM slave to DUT master port
    assign s_chdr[i].tdata        = m_rfnoc_chdr_tdata[CHDR_W*i+:CHDR_W];
    assign s_chdr[i].tlast        = m_rfnoc_chdr_tlast[i];
    assign s_chdr[i].tvalid       = m_rfnoc_chdr_tvalid[i];
    assign m_rfnoc_chdr_tready[i] = s_chdr[i].tready;
  end

  rfnoc_block_sounder_rx #(
    .THIS_PORTID         (THIS_PORTID),
    .CHDR_W              (CHDR_W),
    .MTU                 (MTU),
    .NUM_PORTS           (NUM_PORTS),
    .NIPC                (NIPC)
  ) dut (
    .rfnoc_chdr_clk      (rfnoc_chdr_clk),
    .rfnoc_ctrl_clk      (rfnoc_ctrl_clk),
    .ce_clk              (ce_clk),
    .rfnoc_core_config   (backend.cfg),
    .rfnoc_core_status   (backend.sts),
    .s_rfnoc_chdr_tdata  (s_rfnoc_chdr_tdata),
    .s_rfnoc_chdr_tlast  (s_rfnoc_chdr_tlast),
    .s_rfnoc_chdr_tvalid (s_rfnoc_chdr_tvalid),
    .s_rfnoc_chdr_tready (s_rfnoc_chdr_tready),
    .m_rfnoc_chdr_tdata  (m_rfnoc_chdr_tdata),
    .m_rfnoc_chdr_tlast  (m_rfnoc_chdr_tlast),
    .m_rfnoc_chdr_tvalid (m_rfnoc_chdr_tvalid),
    .m_rfnoc_chdr_tready (m_rfnoc_chdr_tready),
    .s_rfnoc_ctrl_tdata  (m_ctrl.tdata),
    .s_rfnoc_ctrl_tlast  (m_ctrl.tlast),
    .s_rfnoc_ctrl_tvalid (m_ctrl.tvalid),
    .s_rfnoc_ctrl_tready (m_ctrl.tready),
    .m_rfnoc_ctrl_tdata  (s_ctrl.tdata),
    .m_rfnoc_ctrl_tlast  (s_ctrl.tlast),
    .m_rfnoc_ctrl_tvalid (s_ctrl.tvalid),
    .m_rfnoc_ctrl_tready (s_ctrl.tready)
  );

  //---------------------------------------------------------------------------
  // Helper Logic
  //---------------------------------------------------------------------------

  typedef struct {
    item_t        samples[$];
    chdr_word_t   mdata[$];
    packet_info_t pkt_info;
  } test_packet_t;

  typedef struct packed {
    shortint i;
    shortint q;
  } sc16_t;

  function automatic void compare_test_packets(const ref test_packet_t a, b);
    string str;

    // Packet payload
    $sformat(str,
      "Packet payload size incorrect! Expected: %4d, Received: %4d",
      a.samples.size(), b.samples.size());
    `ASSERT_ERROR(a.samples.size() == b.samples.size(), str);

    for (int i = 0; i < a.samples.size(); i++) begin
      $sformat(str,
        "Packet payload word %4d incorrect! Expected: 0x%8X, Received: 0x%8X",
        i, a.samples[i], b.samples[i]);
      `ASSERT_ERROR(a.samples[i] == b.samples[i], str);
    end

    // Packet metadata
    $sformat(str,
      "Packet metadata size incorrect! Expected: %4d, Received: %4d",
      a.mdata.size(), b.mdata.size());
    `ASSERT_ERROR(a.mdata.size() == b.mdata.size(), str);

    for (int i = 0; i < a.mdata.size(); i++) begin
      $sformat(str,
        "Packet metadata word %04d incorrect! Expected: 0x%8X, Received: 0x%8X",
        i, a.mdata[i], b.mdata[i]);
      `ASSERT_ERROR(a.mdata[i] == b.mdata[i], str);
    end

    // Packet info
    $sformat(str,
      "Packet info field 'vc' incorrect! Expected: %2d, Received: %2d",
      a.pkt_info.vc, b.pkt_info.vc);
    `ASSERT_ERROR(a.pkt_info.vc == b.pkt_info.vc, str);

    //$sformat(str,
      //"Packet info field 'eob' incorrect! Expected: %1d, Received: %1d",
      //a.pkt_info.eob, b.pkt_info.eob);
    //`ASSERT_ERROR(a.pkt_info.eob == b.pkt_info.eob, str);

    //$sformat(str,
      //"Packet info field 'eov' incorrect! Expected: %1d, Received: %1d",
      //a.pkt_info.eov, b.pkt_info.eov);
    //`ASSERT_ERROR(a.pkt_info.eov == b.pkt_info.eov, str);

    //$sformat(str,
      //"Packet info field 'has_time' incorrect! Expected: %1d, Received: %1d",
      //a.pkt_info.has_time, b.pkt_info.has_time);
    //`ASSERT_ERROR(a.pkt_info.has_time == b.pkt_info.has_time, str);

    //if(a.pkt_info.has_time == 1) begin
    //$sformat(str,
      //"Packet info field 'timestamp' incorrect! Expected: 0x%16X, Received: 0x%16X",
      //a.pkt_info.timestamp, b.pkt_info.timestamp);
    //`ASSERT_ERROR(a.pkt_info.timestamp == b.pkt_info.timestamp, str);
    //end

  endfunction

  localparam int REG_ML_ADDR = dut.REG_ML_ADDR;
  localparam int REG_K_ADDR = dut.REG_K_ADDR;
  localparam int REG_R_ADDR = dut.REG_R_ADDR;
  localparam int REG_L_ADDR = dut.REG_L_ADDR;
  localparam int REG_P_ADDR = dut.REG_P_ADDR;
  localparam int REG_A_ADDR = dut.REG_A_ADDR;
  localparam int REG_M_ADDR = dut.REG_M_ADDR;
  localparam int REG_PA_ADDR = dut.REG_PA_ADDR;

  task automatic test_sounder_rx (
    input int num_packets,
    input int port        = 0,
    input int spp         = SPP,
    input int stall_prob  = STALL_PROB
  );
    // Calculate expected number of receive packets
    //
    int l = 512;
    int m = 1;
    int k = 2;
    int r = 8736;
    int ml = m*l;
    int p = 2048;
    int ant = 1;
    int seq_len = l;
    int log2avg = k; 
    logic [31:0] val32;
    int num_packets_expected = 0;
    int num_avg = 0;
    int offset = 0;
    int ant_cnt = 0;
    mailbox #(test_packet_t) tb_send_packets = new();
    mailbox #(test_packet_t) tb_recv_packets = new();
    mailbox #(test_packet_t) tb_recv_packets_corr = new();
    sc16_t samples[$];
    sc16_t samples_avg[$] = {0};
    
    // simplified calculation, rounded to below
    num_avg = $floor(spp*num_packets/(p+m*l+r)) * ant - 1;
    num_packets_expected = $floor(num_avg*l/spp) - 1;
    

    $display("num_avg: %d", num_packets_expected);
    $display("num_packets_expected: %d", num_packets_expected);

    blk_ctrl.set_master_stall_prob(port, stall_prob);
    blk_ctrl.set_slave_stall_prob(port, stall_prob);
    
    // Write a value wider than the register to verify the width
    blk_ctrl.reg_write(REG_ML_ADDR, ml/NIPC);
    blk_ctrl.reg_read(REG_ML_ADDR, val32);
    `ASSERT_ERROR(
      val32 == ml/NIPC, "Value for ML is not correct");
    
    blk_ctrl.reg_write(REG_K_ADDR, k);
    blk_ctrl.reg_read(REG_K_ADDR, val32);
    `ASSERT_ERROR(
      val32 == k, "Value for K is not correct");
    
    blk_ctrl.reg_write(REG_R_ADDR, r/NIPC);
    blk_ctrl.reg_read(REG_R_ADDR, val32);
    `ASSERT_ERROR(
      val32 == r/NIPC, "Value for R is not correct");
    
    blk_ctrl.reg_write(REG_L_ADDR, l/NIPC);
    blk_ctrl.reg_read(REG_L_ADDR, val32);
    `ASSERT_ERROR(
      val32 == l/NIPC, "Value for L is not correct");

    blk_ctrl.reg_write(REG_P_ADDR, p/NIPC);
    blk_ctrl.reg_read(REG_P_ADDR, val32);
    `ASSERT_ERROR(
      val32 == p/NIPC, "Value for P is not correct");

    blk_ctrl.reg_write(REG_A_ADDR, ant);
    blk_ctrl.reg_read(REG_A_ADDR, val32);
    `ASSERT_ERROR(
      val32 == ant, "Value for A is not correct");
    
    blk_ctrl.reg_write(REG_PA_ADDR, SPP/NIPC);
    blk_ctrl.reg_read(REG_PA_ADDR, val32);
    `ASSERT_ERROR(
      val32 == SPP/NIPC, "Value for A is not correct");
    
    blk_ctrl.reg_write(REG_M_ADDR, m);
    blk_ctrl.reg_read(REG_M_ADDR, val32);
    `ASSERT_ERROR(
      val32 == m, "Value for M is not correct");
    
    // Generate packets
    for (int i = 0; i < num_packets; i++) begin
      test_packet_t tb_send_pkt;

      for (int k = 0; k < spp; k++) begin
        tb_send_pkt.samples.push_back($urandom());
      end
      tb_send_pkt.mdata = {};
      tb_send_pkt.pkt_info = '{
        vc:        0,
        eob:       0,//(i == num_packets-1),
        eov:       0,
        has_time:  1'b0,
        timestamp: {$urandom(),$urandom()}};

      blk_ctrl.send_items(port, tb_send_pkt.samples, tb_send_pkt.mdata, tb_send_pkt.pkt_info);

      tb_send_packets.put(tb_send_pkt);
      //$display("sample 0x%8X", tb_send_pkt.samples[0]);
    end

    // Generate correct receive packetk
    // Depacketize
    for (int i = 0; i < num_packets; i++) begin
      test_packet_t pkt; 
      tb_send_packets.get(pkt); 
      for (int j = 0; j < spp; j++) begin 
        samples.push_back(pkt.samples[j]);
      end
    end
    //$display("sample depack 0x%8X", samples[0]);

    // Average 
    //num_avg = int'($floor(num_packets_expected*spp/real'(l)));
    offset = p;
    ant_cnt = 1;
    
    $display("sample 0x%8X at index 1024", samples[1024].i >>> k);
    $display("sample 0x%8X at index 2048", samples[2048].i >>> k);
    $display("sample 0x%8X at index 3072", samples[3072].i >>> k);
    $display("sample 0x%8X at index 4096", samples[4096].i >>> k);

    for (int j = 0; j < num_avg; j++) begin
      //offset = p+j*(m*l+p);
      for (int kk = 0; kk < m; kk++) begin
        for (int i = 0; i < seq_len; i++) begin
          samples_avg[seq_len*j+i].i = samples_avg[seq_len*j+i].i + (samples[seq_len*kk+offset+i].i >>> k);
          samples_avg[seq_len*j+i].q = samples_avg[seq_len*j+i].q + (samples[seq_len*kk+offset+i].q >>> k);
        end
      //$display("sample avg in loop 0x%8X", samples_avg[seq_len*j]);
      end
      if (ant_cnt == ant) begin 
        offset = offset + m*l+r;
        ant_cnt = 1;
      end else begin 
        offset = offset + m*l+p;
        ant_cnt = ant_cnt + 1;
      end
      //$display("offset",offset );
    end
    // Packetize
    for (int i = 0; i < num_avg; i++) begin
      int fl = $floor(real'(l)/spp);
      int spp_last = l - fl*spp;
      test_packet_t pkt2; 
      for (int ii = 0; ii < fl; ii++) begin
        test_packet_t pkt; 
        for (int j = 0; j < spp ; j++) begin
          pkt.samples[j] = samples_avg[i*l+ii*spp+j]; 
        end
        tb_recv_packets_corr.put(pkt);
      end
      $display("spp_last ", spp_last);
      if (spp_last > 1) begin
        for (int j = 0; j < spp_last ; j++) begin
          pkt2.samples[j] = samples_avg[i*l+fl*spp+j]; 
        end
        tb_recv_packets_corr.put(pkt2);
      end
    end
    // Rx packets
    // TO DO: until TEOB
    $display("I was here");
    for (int i = 0; i < num_packets_expected; i++) begin
      test_packet_t tb_recv_pkt;
      blk_ctrl.recv_items_adv(port, tb_recv_pkt.samples, tb_recv_pkt.mdata, tb_recv_pkt.pkt_info);
      tb_recv_packets.put(tb_recv_pkt);
      $display("%d OK", i);
    end
    
    
    // Compare packets
    for (int i = 0; i < num_packets_expected; i++) begin
      test_packet_t a;
      test_packet_t b;
      tb_recv_packets.get(b);
      tb_recv_packets_corr.get(a);
      //$display("Packet numer: %d", i);
      compare_test_packets(a, b);
      $display("%d OK", i);
    end

      
  
  endtask;

  //---------------------------------------------------------------------------
  // Main Test Process
  //---------------------------------------------------------------------------

  initial begin : tb_main

    // Initialize the test exec object for this testbench
    test.start_tb("rfnoc_block_sounder_rx_tb");
    

    // Start the BFMs running
    blk_ctrl.run();

    //--------------------------------
    // Reset
    //--------------------------------

    test.start_test("Flush block then reset it", 10us);
    blk_ctrl.flush_and_reset();
    test.end_test();

    //--------------------------------
    // Verify Block Info
    //--------------------------------

    test.start_test("Verify Block Info", 2us);
    `ASSERT_ERROR(blk_ctrl.get_noc_id() == NOC_ID, "Incorrect NOC_ID Value");
    `ASSERT_ERROR(blk_ctrl.get_num_data_i() == NUM_PORTS_I, "Incorrect NUM_DATA_I Value");
    `ASSERT_ERROR(blk_ctrl.get_num_data_o() == NUM_PORTS_O, "Incorrect NUM_DATA_O Value");
    `ASSERT_ERROR(blk_ctrl.get_mtu() == MTU, "Incorrect MTU Value");
    test.end_test();

    //--------------------------------
    // Test Sequences
    //--------------------------------

    // <Add your test code here>
    test.start_test("Average test", NUM_PORTS*100000us);
    //test_sounder_rx(3, 40, 0);
    //test_sounder_rx(1, 6, 0);
    //test_sounder_rx(1, 3000, 0);
    
    test_sounder_rx(1000, 0); // 40 packets on port 0 
    //test_sounder_rx(10, 10, 2);
    //test_sounder_rx(10, 10, 3);
    test.end_test();

    //--------------------------------
    // Finish Up
    //--------------------------------

    // Display final statistics and results
    //test.end_tb();
    test.end_tb(0);
    rfnoc_chdr_clk_gen.kill();
    rfnoc_ctrl_clk_gen.kill();
    ce_clk_gen.kill();
  end : tb_main

endmodule : rfnoc_block_sounder_rx_tb


`default_nettype wire
