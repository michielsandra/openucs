// Author: Michiel Sandra, Lund University
`default_nettype none

module blk_avg #(
  parameter DWIDTH = 32,
  parameter AWIDTH = 10,
  parameter NIPC   = 1
)(
  input  wire                   clk,
  input  wire                   rst,
  input  wire                   en,
  input  wire [DWIDTH*NIPC-1:0] din,
  input  wire                   vin,
  output wire [DWIDTH*NIPC-1:0] dout,
  output wire                   vout,
  input  wire [AWIDTH-1:0]      l,
  input  wire [7:0]             m,
  input  wire [3:0]             k
);
  // state params
  localparam S_IN  = 2'd0;
  localparam S_ADD = 2'd1;
  localparam S_OUT = 2'd2;

  // state register
  reg [1:0] state;

  // three data registers
  reg [NIPC*DWIDTH-1:0] data1;
  reg valid1;

  reg [NIPC*DWIDTH-1:0] data2;
  reg valid2;

  reg [NIPC*DWIDTH-1:0] data3;
  reg valid3;

  // param registers
  reg [7:0]  m_reg;
  reg [AWIDTH-1:0] l_reg;

  always @(posedge clk) begin
    m_reg <= m - 1;
    l_reg <= l - 1;
  end

  // STAGE 1
  always @(posedge clk) begin
    if(rst) begin
      valid1 <= 0'b0;
    end else begin
      valid1 <= vin;
    end 
  end

  always @(posedge clk) begin
      data1 <= din;
  end

  wire enable = valid1 & en;

  // STAGE 2
  generate 
    if (NIPC == 1) begin
      always @(posedge clk) begin
        if (enable) begin
          data2[31+0*32:16+0*32] <= $signed(data1[31+0*32:16+0*32]) >>> k; 
          data2[15+0*32:32*0] <= $signed(data1[15+0*32:32*0]) >>> k; 
        end
      end
    end else if (NIPC == 2) begin
      always @(posedge clk) begin
        if (enable) begin
          data2[31+0*32:16+0*32] <= $signed(data1[31+0*32:16+0*32]) >>> k; 
          data2[15+0*32:32*0] <= $signed(data1[15+0*32:32*0]) >>> k; 
          data2[31+1*32:16+1*32] <= $signed(data1[31+1*32:16+1*32]) >>> k; 
          data2[15+1*32:1*32] <= $signed(data1[15+1*32:1*32]) >>> k; 
        end
      end
    end else if (NIPC == 4) begin
      always @(posedge clk) begin
        if (enable) begin
          data2[31+0*32:16+0*32] <= $signed(data1[31+0*32:16+0*32]) >>> k; 
          data2[15+0*32:32*0] <= $signed(data1[15+0*32:32*0]) >>> k; 
          data2[31+1*32:16+1*32] <= $signed(data1[31+1*32:16+1*32]) >>> k; 
          data2[15+1*32:1*32] <= $signed(data1[15+1*32:1*32]) >>> k; 
          data2[31+2*32:16+2*32] <= $signed(data1[31+2*32:16+2*32]) >>> k; 
          data2[15+2*32:2*32] <= $signed(data1[15+2*32:2*32]) >>> k; 
          data2[31+3*32:16+3*32] <= $signed(data1[31+3*32:16+3*32]) >>> k; 
          data2[15+3*32:3*32] <= $signed(data1[15+3*32:3*32]) >>> k; 
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    if(rst) begin
      valid2 <= 0'b0;
    end else begin
      if (enable) begin
        valid2 <= 1'b1;
      end 
    end 
  end


  // STAGE 3
  wire [NIPC*DWIDTH-1:0] mem_out;
  wire add_en;
  generate 
    if (NIPC == 1) begin
      always @(posedge clk) begin
        if (enable) begin
          if (add_en) begin
            data3[31+0*32:16+0*32] <= data2[31+0*32:16+0*32] + mem_out[31+0*32:16+0*32]; 
            data3[15+0*32:32*0] <= data2[15+0*32:32*0] + mem_out[15+0*32:32*0];
          end else begin
            data3 <= data2;
          end
        end
      end
    end 
    else if (NIPC == 2) begin
      always @(posedge clk) begin
        if (enable) begin
          if (add_en) begin
            data3[31+0*32:16+0*32] <= data2[31+0*32:16+0*32] + mem_out[31+0*32:16+0*32];
            data3[15+0*32:32*0] <= data2[15+0*32:32*0] + mem_out[15+0*32:32*0];
            data3[31+1*32:16+1*32] <= data2[31+1*32:16+1*32] + mem_out[31+1*32:16+1*32];
            data3[15+1*32:1*32] <= data2[15+1*32:1*32] + mem_out[15+1*32:1*32];
          end else begin 
            data3 <= data2;
          end
        end
      end
    end
    else if (NIPC == 4) begin
      always @(posedge clk) begin
        if (enable) begin
          if (add_en) begin
            data3[31+0*32:16+0*32] <= data2[31+0*32:16+0*32] + mem_out[31+0*32:16+0*32];
            data3[15+0*32:32*0] <= data2[15+0*32:32*0] + mem_out[15+0*32:32*0];
            data3[31+1*32:16+1*32] <= data2[31+1*32:16+1*32] + mem_out[31+1*32:16+1*32];
            data3[15+1*32:1*32] <= data2[15+1*32:1*32] + mem_out[15+1*32:1*32];
            data3[31+2*32:16+2*32] <= data2[31+2*32:16+2*32] + mem_out[31+2*32:16+2*32];
            data3[15+2*32:32*2] <= data2[15+2*32:32*2] + mem_out[15+2*32:32*2];
            data3[31+3*32:16+3*32] <= data2[31+3*32:16+3*32] + mem_out[31+3*32:16+3*32];
            data3[15+3*32:3*32] <= data2[15+3*32:3*32] + mem_out[15+3*32:3*32];
          end else begin
            data3 <= data2;
          end
        end
      end
    end
  endgenerate
  

  always @(posedge clk) begin
    if(rst) begin
      valid3 <= 0'b0;
    end else begin
      if (enable) begin
        valid3 <= valid2 & out_en;
      end 
    end 
  end

  // MEMORY
  genvar i;
  for (i = 0; i < NIPC; i = i + 1) begin
    bram_mem #(
      .DWIDTH (DWIDTH),
      .AWIDTH (AWIDTH)
    ) inst_bram_mem (
      .r_clk  (clk),
      .w_clk  (clk),
      .en     (enable),
      .r_addr (cnt1),
      .w_addr (cnt3),
      .din    (data3[32*(i+1)-1:32*i]),
      .dout   (mem_out[32*(i+1)-1:32*i])
    );
  end


  // COUNTERS
  reg [AWIDTH-1:0] cnt1;
  reg [AWIDTH-1:0] cnt2;
  reg [AWIDTH-1:0] cnt3;
  

  always @(posedge clk) begin
    if(rst) begin
        cnt1 <= 0;
        cnt2 <= 0;
        cnt3 <= 0;
    end else begin
      if (enable) begin
        cnt2 <= cnt1;
        cnt3 <= cnt2;
        if (cnt1 == l_reg) begin
          cnt1 <= 10'd0;
        end else begin
          cnt1 <= cnt1 + 1;
        end
      end
    end 
  end

  // next state line
  wire next = (cnt2 == l_reg) ? 1'b1 : 1'b0;

  // STATE MACHINE
  reg [7:0] m_cnt;


  always @(posedge clk) begin
    if(rst) begin
      state <= S_IN;
      m_cnt <= 8'd1;
    end else begin
      if (enable & next) begin
        case (state)
          S_IN:
            begin
              if (m_reg == 8'd0) begin
                state <= S_IN;
                m_cnt <= 8'd1;
              end else if (m_reg == 8'd1) begin
                state <= S_OUT;
                m_cnt <= m_cnt + 1;
              end else begin
                state <= S_ADD;
                m_cnt <= m_cnt + 1;
              end
            end
          S_ADD:
            begin
              if (m_cnt == m_reg) begin 
                state <= S_OUT; 
              end
              m_cnt <= m_cnt + 1;
            end
          S_OUT:
            begin
              state <= S_IN;
              m_cnt <= 8'd1;
            end
        endcase
      end
    end
  end


  // some control wires
  assign add_en = (state == S_ADD || state == S_OUT) ? 1'b1 : 1'b0;
  wire out_en = (state == S_OUT || (state == S_IN && m_reg == 8'd0)) ? 1'b1 : 1'b0;

  // output values
  assign dout = data3;
  assign vout = valid3 & valid1;


endmodule // blk_avg

`default_nettype wire
