// Author: Michiel Sandra, Lund University
`default_nettype none


module rfnoc_block_sounder_rx #(
  parameter [9:0] THIS_PORTID     = 10'd0,
  parameter       CHDR_W          = 128,
  parameter [5:0] MTU             = 10,
  parameter       NUM_PORTS       = 4,
  parameter       NIPC            = 2
)(
  // RFNoC Framework Clocks and Resets
  input  wire                   rfnoc_chdr_clk,
  input  wire                   rfnoc_ctrl_clk,
  input  wire                   ce_clk,
  // RFNoC Backend Interface
  input  wire [511:0]           rfnoc_core_config,
  output wire [511:0]           rfnoc_core_status,
  // AXIS-CHDR Input Ports (from framework)
  input  wire [(0+NUM_PORTS)*CHDR_W-1:0] s_rfnoc_chdr_tdata,
  input  wire [(0+NUM_PORTS)-1:0]        s_rfnoc_chdr_tlast,
  input  wire [(0+NUM_PORTS)-1:0]        s_rfnoc_chdr_tvalid,
  output wire [(0+NUM_PORTS)-1:0]        s_rfnoc_chdr_tready,
  // AXIS-CHDR Output Ports (to framework)
  output wire [(0+NUM_PORTS)*CHDR_W-1:0] m_rfnoc_chdr_tdata,
  output wire [(0+NUM_PORTS)-1:0]        m_rfnoc_chdr_tlast,
  output wire [(0+NUM_PORTS)-1:0]        m_rfnoc_chdr_tvalid,
  input  wire [(0+NUM_PORTS)-1:0]        m_rfnoc_chdr_tready,
  // AXIS-Ctrl Input Port (from framework)
  input  wire [31:0]            s_rfnoc_ctrl_tdata,
  input  wire                   s_rfnoc_ctrl_tlast,
  input  wire                   s_rfnoc_ctrl_tvalid,
  output wire                   s_rfnoc_ctrl_tready,
  // AXIS-Ctrl Output Port (to framework)
  output wire [31:0]            m_rfnoc_ctrl_tdata,
  output wire                   m_rfnoc_ctrl_tlast,
  output wire                   m_rfnoc_ctrl_tvalid,
  input  wire                   m_rfnoc_ctrl_tready
);

  //---------------------------------------------------------------------------
  // Signal Declarations
  //---------------------------------------------------------------------------

  // Clocks and Resets
  wire               ctrlport_clk;
  wire               ctrlport_rst;
  wire               axis_data_clk;
  wire               axis_data_rst;
  // CtrlPort Master
  wire               m_ctrlport_req_wr;
  wire               m_ctrlport_req_rd;
  wire [19:0]        m_ctrlport_req_addr;
  wire [31:0]        m_ctrlport_req_data;
  reg                m_ctrlport_resp_ack;
  reg  [31:0]        m_ctrlport_resp_data;
  // Data Stream to User Logic: in
  wire [NUM_PORTS*32*NIPC-1:0]   m_in_axis_tdata;
  wire [NUM_PORTS*NIPC-1:0]      m_in_axis_tkeep;
  wire [NUM_PORTS-1:0]        m_in_axis_tlast;
  wire [NUM_PORTS-1:0]        m_in_axis_tvalid;
  wire [NUM_PORTS-1:0]        m_in_axis_tready;
  wire [NUM_PORTS*64-1:0]     m_in_axis_ttimestamp;
  wire [NUM_PORTS-1:0]        m_in_axis_thas_time;
  wire [NUM_PORTS*16-1:0]     m_in_axis_tlength;
  wire [NUM_PORTS-1:0]        m_in_axis_teov;
  wire [NUM_PORTS-1:0]        m_in_axis_teob;
  // Data Stream from User Logic: out
  wire [NUM_PORTS*32*NIPC-1:0]   s_out_axis_tdata;
  wire [NUM_PORTS*NIPC-1:0]      s_out_axis_tkeep;
  wire [NUM_PORTS-1:0]        s_out_axis_tlast;
  wire [NUM_PORTS-1:0]        s_out_axis_tvalid;
  wire [NUM_PORTS-1:0]        s_out_axis_tready;
  wire [NUM_PORTS*64-1:0]     s_out_axis_ttimestamp;
  wire [NUM_PORTS-1:0]        s_out_axis_thas_time;
  wire [NUM_PORTS*16-1:0]     s_out_axis_tlength;
  wire [NUM_PORTS-1:0]        s_out_axis_teov;
  wire [NUM_PORTS-1:0]        s_out_axis_teob;
  
  wire                        ce_rst;

  //---------------------------------------------------------------------------
  // NoC Shell
  //---------------------------------------------------------------------------

  noc_shell_sounder_rx #(
    .CHDR_W              (CHDR_W),
    .THIS_PORTID         (THIS_PORTID),
    .MTU                 (MTU),
    .NUM_PORTS           (NUM_PORTS),
    .NIPC                (NIPC)
  ) noc_shell_sounder_rx_i (
    //---------------------
    // Framework Interface
    //---------------------

    // Clock Inputs
    .rfnoc_chdr_clk      (rfnoc_chdr_clk),
    .rfnoc_ctrl_clk      (rfnoc_ctrl_clk),
    .ce_clk              (ce_clk),
    // Reset Outputs
    .rfnoc_chdr_rst      (),
    .rfnoc_ctrl_rst      (),
    .ce_rst              (ce_rst),
    // RFNoC Backend Interface
    .rfnoc_core_config   (rfnoc_core_config),
    .rfnoc_core_status   (rfnoc_core_status),
    // CHDR Input Ports  (from framework)
    .s_rfnoc_chdr_tdata  (s_rfnoc_chdr_tdata),
    .s_rfnoc_chdr_tlast  (s_rfnoc_chdr_tlast),
    .s_rfnoc_chdr_tvalid (s_rfnoc_chdr_tvalid),
    .s_rfnoc_chdr_tready (s_rfnoc_chdr_tready),
    // CHDR Output Ports (to framework)
    .m_rfnoc_chdr_tdata  (m_rfnoc_chdr_tdata),
    .m_rfnoc_chdr_tlast  (m_rfnoc_chdr_tlast),
    .m_rfnoc_chdr_tvalid (m_rfnoc_chdr_tvalid),
    .m_rfnoc_chdr_tready (m_rfnoc_chdr_tready),
    // AXIS-Ctrl Input Port (from framework)
    .s_rfnoc_ctrl_tdata  (s_rfnoc_ctrl_tdata),
    .s_rfnoc_ctrl_tlast  (s_rfnoc_ctrl_tlast),
    .s_rfnoc_ctrl_tvalid (s_rfnoc_ctrl_tvalid),
    .s_rfnoc_ctrl_tready (s_rfnoc_ctrl_tready),
    // AXIS-Ctrl Output Port (to framework)
    .m_rfnoc_ctrl_tdata  (m_rfnoc_ctrl_tdata),
    .m_rfnoc_ctrl_tlast  (m_rfnoc_ctrl_tlast),
    .m_rfnoc_ctrl_tvalid (m_rfnoc_ctrl_tvalid),
    .m_rfnoc_ctrl_tready (m_rfnoc_ctrl_tready),

    //---------------------
    // Client Interface
    //---------------------

    // CtrlPort Clock and Reset
    .ctrlport_clk              (ctrlport_clk),
    .ctrlport_rst              (ctrlport_rst),
    // CtrlPort Master
    .m_ctrlport_req_wr         (m_ctrlport_req_wr),
    .m_ctrlport_req_rd         (m_ctrlport_req_rd),
    .m_ctrlport_req_addr       (m_ctrlport_req_addr),
    .m_ctrlport_req_data       (m_ctrlport_req_data),
    .m_ctrlport_resp_ack       (m_ctrlport_resp_ack),
    .m_ctrlport_resp_data      (m_ctrlport_resp_data),

    // AXI-Stream Clock and Reset
    .axis_data_clk (axis_data_clk),
    .axis_data_rst (axis_data_rst),
    // Data Stream to User Logic: in
    .m_in_axis_tdata      (m_in_axis_tdata),
    .m_in_axis_tkeep      (m_in_axis_tkeep),
    .m_in_axis_tlast      (m_in_axis_tlast),
    .m_in_axis_tvalid     (m_in_axis_tvalid),
    .m_in_axis_tready     (m_in_axis_tready),
    .m_in_axis_ttimestamp (m_in_axis_ttimestamp),
    .m_in_axis_thas_time  (m_in_axis_thas_time),
    .m_in_axis_tlength    (m_in_axis_tlength),
    .m_in_axis_teov       (m_in_axis_teov),
    .m_in_axis_teob       (m_in_axis_teob),
    // Data Stream from User Logic: out
    .s_out_axis_tdata      (s_out_axis_tdata),
    .s_out_axis_tkeep      (s_out_axis_tkeep),
    .s_out_axis_tlast      (s_out_axis_tlast),
    .s_out_axis_tvalid     (s_out_axis_tvalid),
    .s_out_axis_tready     (s_out_axis_tready),
    .s_out_axis_ttimestamp (s_out_axis_ttimestamp),
    .s_out_axis_thas_time  (s_out_axis_thas_time),
    .s_out_axis_tlength    (s_out_axis_tlength),
    .s_out_axis_teov       (s_out_axis_teov),
    .s_out_axis_teob       (s_out_axis_teob)
  );

  //---------------------------------------------------------------------------
  // User Logic
  //---------------------------------------------------------------------------

  localparam REG_ML_ADDR    = 0;    // Address for gain value
  localparam REG_ML_DEFAULT = 0;    // Default gain value

  localparam REG_K_ADDR = 1;
  localparam REG_K_DEFAULT = 0;

  localparam REG_L_ADDR = 2;
  localparam REG_L_DEFAULT = 1024;

  localparam REG_R_ADDR = 3;
  localparam REG_R_DEFAULT = 0;
  
  localparam REG_P_ADDR = 4;
  localparam REG_P_DEFAULT = 0;
  
  localparam REG_A_ADDR = 5;
  localparam REG_A_DEFAULT = 0;
  
  localparam REG_M_ADDR = 6;
  localparam REG_M_DEFAULT = 0;
  
  localparam REG_PA_ADDR = 7;
  localparam REG_PA_DEFAULT = 0;

  // for register
  reg [31:0] reg_ml = REG_ML_DEFAULT;
  reg [3:0] reg_k = REG_K_DEFAULT;
  reg [31:0] reg_r = REG_R_DEFAULT;
  reg [31:0] reg_l = REG_L_DEFAULT;
  reg [31:0] reg_p = REG_P_DEFAULT;
  reg [7:0] reg_a = REG_A_DEFAULT;
  reg [7:0] reg_m = REG_M_DEFAULT;
  reg [31:0] reg_pa = REG_PA_DEFAULT;

  always @(posedge ctrlport_clk) begin
    if (ctrlport_rst) begin
      reg_ml = REG_ML_DEFAULT;
      reg_k = REG_K_DEFAULT;
      reg_r = REG_R_DEFAULT;
      reg_l = REG_L_DEFAULT;
      reg_p = REG_P_DEFAULT;
      reg_a = REG_A_DEFAULT;
      reg_m = REG_M_DEFAULT;
      reg_pa = REG_PA_DEFAULT;
    end else begin
      // Default assignment
      m_ctrlport_resp_ack <= 0;

      // Handle read requests
      if (m_ctrlport_req_rd) begin
        case (m_ctrlport_req_addr)
          REG_ML_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= reg_ml;
          end
          REG_K_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= { 28'b0, reg_k};
          end
          REG_R_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= reg_r;
          end
          REG_L_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= { 16'b0, reg_l};
          end
          REG_P_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= reg_p;
          end
          REG_A_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= { 24'b0, reg_a};
          end
          REG_M_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= { 24'b0, reg_m};
          end
          REG_PA_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= reg_pa;
          end
        endcase
      end

      // Handle write requests
      if (m_ctrlport_req_wr) begin
        case (m_ctrlport_req_addr)
          REG_ML_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_ml            <= m_ctrlport_req_data;
          end
          REG_K_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_k            <= m_ctrlport_req_data;
          end
          REG_R_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_r            <= m_ctrlport_req_data;
          end
          REG_L_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_l            <= m_ctrlport_req_data;
          end
          REG_P_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_p            <= m_ctrlport_req_data;
          end
          REG_A_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_a            <= m_ctrlport_req_data;
          end
          REG_M_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_m            <= m_ctrlport_req_data;
          end
          REG_PA_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_pa            <= m_ctrlport_req_data;
          end
        endcase
      end
    end
  end
  
  genvar i;
  for (i = 0; i < NUM_PORTS; i = i+1) begin
    sounder_rx #(
      .WIDTH    (32),
      .NIPC     (NIPC)
    ) inst_sounder_rx (
      .clk               (ce_clk),
      .rst               (ce_rst),
      .i_axis_tdata      (m_in_axis_tdata[32*NIPC*(i+1)-1:32*NIPC*i]),
      .i_axis_tkeep      (m_in_axis_tkeep[NIPC*(i+1)-1:NIPC*i]),
      .i_axis_tlast      (m_in_axis_tlast[i]),
      .i_axis_tvalid     (m_in_axis_tvalid[i]),
      .i_axis_tready     (m_in_axis_tready[i]),
      .i_axis_ttimestamp (m_in_axis_ttimestamp[64*(i+1)-1:64*i]),
      .i_axis_thas_time  (m_in_axis_thas_time[i]),
      .i_axis_tlength    (m_in_axis_tlength[16*(i+1)-1:16*i]),
      .i_axis_teov       (m_in_axis_teov[i]),
      .i_axis_teob       (m_in_axis_teob[i]),
      .o_axis_tdata      (s_out_axis_tdata[32*NIPC*(i+1)-1:32*NIPC*i]),
      .o_axis_tkeep      (s_out_axis_tkeep[NIPC*(i+1)-1:NIPC*i]),
      .o_axis_tlast      (s_out_axis_tlast[i]),
      .o_axis_tvalid     (s_out_axis_tvalid[i]),
      .o_axis_tready     (s_out_axis_tready[i]),
      .o_axis_ttimestamp (s_out_axis_ttimestamp[64*(i+1)-1:64*i]),
      .o_axis_thas_time  (s_out_axis_thas_time[i]),
      .o_axis_teov       (s_out_axis_teov[i]),
      .o_axis_teob       (s_out_axis_teob[i]),
      .l                 (reg_l[15:0]),
      .m                 (reg_m),
      .k                 (reg_k),
      .p                 (reg_p),
      .r                 (reg_r),
      .ml                (reg_ml),
      .nant              (reg_a),
      .spp               (reg_pa[15:0])
      );
  end


  

endmodule // rfnoc_block_sounder_rx


`default_nettype wire
