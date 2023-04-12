// Author: Michiel Sandra, Lund University
`default_nettype none

module sounder_rx #(
  parameter WIDTH = 32,
  parameter NIPC = 2
)(
  input  wire                       clk,
  input  wire                       rst,
  input  wire [NIPC*WIDTH-1:0]      i_axis_tdata,
  input  wire [NIPC-1:0]            i_axis_tkeep,
  input  wire                       i_axis_tlast,
  input  wire                       i_axis_tvalid,
  output wire                       i_axis_tready,
  input  wire [63:0]                i_axis_ttimestamp,
  input  wire                       i_axis_thas_time,
  input  wire [15:0]                i_axis_tlength,
  input  wire                       i_axis_teov,
  input  wire                       i_axis_teob,
  output wire [NIPC*WIDTH-1:0]      o_axis_tdata,
  output wire [NIPC-1:0]            o_axis_tkeep,
  output wire                       o_axis_tlast,
  output wire                       o_axis_tvalid,
  input  wire                       o_axis_tready,
  output wire [63:0]                o_axis_ttimestamp,
  output wire                       o_axis_thas_time,
  output wire                       o_axis_teov,
  output wire                       o_axis_teob,
  input  wire [15:0]                l,
  input  wire [7:0]                 m,
  input  wire [3:0]                 k,
  input  wire [31:0]                p,
  input  wire [31:0]                r,
  input  wire [31:0]                ml,
  input  wire [7:0]                 nant,
  input  wire [15:0]                spp
);
  
  assign i_axis_tready = o_axis_tready;

  // not used signals
  assign o_axis_ttimestamp = 64'd0; 
  assign o_axis_thas_time  = 1'b0; 
  assign o_axis_teov       = 1'b0; 
  assign o_axis_teob       = 1'b0; 
  
  // state machine
  reg [1:0] state;
  localparam S_SKIP_P = 2'd0;
  localparam S_ACTIVE = 2'd1;
  localparam S_SKIP_R = 2'd2;

  reg [31:0] cnt;
  reg [7:0] ant_cnt;
  
  reg [31:0] ml_reg;
  reg [31:0] p_reg;
  reg [31:0] r_reg;
  reg [7:0] nant_reg;
  reg [15:0] spp_reg;

  always @(posedge clk) begin
    ml_reg <= ml;
    p_reg <= p;
    r_reg <= r;
    nant_reg <= nant;
    spp_reg <= spp;
  end

  always @(posedge clk) begin
    if (rst) begin
      cnt <= 32'd1;
      ant_cnt <= 8'd1;
      state <= S_SKIP_P;
    end else begin
      if (i_axis_tvalid & i_axis_tready) begin
        case (state)
          S_SKIP_P:
            if (cnt == p_reg) begin
              state <= S_ACTIVE;
              cnt <= 32'd1;
            end else begin
              cnt <= cnt + 1;
            end
          S_ACTIVE:
            if (cnt == ml_reg) begin
              if (ant_cnt == nant_reg) begin
                state <= S_SKIP_R;
                ant_cnt <= 8'd1;
                cnt <= 32'd1;
              end else begin
                state <= S_SKIP_P;
                ant_cnt <= ant_cnt + 1;
                cnt <= 32'd1;
              end
            end else begin
              cnt <= cnt + 1;
            end
          S_SKIP_R:
            if (cnt == r_reg) begin
              cnt <= 32'd1;
              state <= S_ACTIVE;
            end else begin
              cnt <= cnt + 1;
            end
        endcase
      end
    end
  end

  wire active = (state == S_ACTIVE) ? 1'b1 : 1'b0;

  // block averager
  blk_avg #(
    .DWIDTH (WIDTH),
    .AWIDTH (10),
    .NIPC   (NIPC)
  ) blk_avg_inst (
    .clk   (clk),
    .rst   (rst),
    .en    (i_axis_tready),
    .din   (i_axis_tdata),
    .vin   (i_axis_tvalid & active),
    .dout  (o_axis_tdata),
    .vout  (o_axis_tvalid),
    .l     (l[9:0]),
    .m     (m),
    .k     (k)
    );


  // tlast generation packet
  reg [15:0] last_cnt = 16'd0;
  always @(posedge clk) begin
    if (rst) begin
      last_cnt <= 16'd1; 
    end else begin
      if (o_axis_tvalid & o_axis_tready) begin
        if (last_cnt == spp) begin
          last_cnt <= 16'd1;
        end else begin
          last_cnt <= last_cnt + 1;
        end
      end
    end
  end
  
  assign o_axis_tlast = (last_cnt == spp[15:0]) ? 1'b1 : 1'b0;
  assign o_axis_tkeep = o_axis_tvalid ? {(NIPC){1'b1}} : {(NIPC){1'b0}};

endmodule // sounder_rx

`default_nettype wire
