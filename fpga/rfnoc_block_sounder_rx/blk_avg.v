// Author: Michiel Sandra, Lund University
`default_nettype none

module blk_avg #(
  parameter DWIDTH = 32,
  parameter AWIDTH = 10,
  parameter MWIDTH = 8,
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
  input  wire [MWIDTH-1:0]      m,
  input  wire [3:0]             k
);
  
  // param registers
  reg [MWIDTH-1:0] m_reg;
  reg [AWIDTH-1:0] l_reg;

  // stage registers
  reg [NIPC*DWIDTH-1:0] data1;
  reg [MWIDTH-1:0] m1;
  reg [AWIDTH-1:0] l1;
  reg v1;

  reg [NIPC*DWIDTH-1:0] data2;
  reg [MWIDTH-1:0] m2;
  reg [AWIDTH-1:0] l2;
  reg v2;
  
  reg [NIPC*DWIDTH-1:0] data3;
  reg [MWIDTH-1:0] m3;
  reg [AWIDTH-1:0] l3;
  reg v3;


  // wires
  wire [NIPC*DWIDTH-1:0] mem_out;
  wire add_en;
  wire out_en;
  
  // update registers
  always @(posedge clk) begin
    m_reg <= m - 1;
    l_reg <= l - 1;
  end
  

  // MEMORY
  genvar i;
  for (i = 0; i < NIPC; i = i + 1) begin
    bram_mem #(
      .DWIDTH (DWIDTH),
      .AWIDTH (AWIDTH)
    ) inst_bram_mem (
      .clk    (clk),
      .ren    (1'b1),
      .wen    (v3),
      .r_addr (l1),
      .w_addr (l3),
      .din    (data3[32*(i+1)-1:32*i]),
      .dout   (mem_out[32*(i+1)-1:32*i])
    );
  end
  
  // STAGE 1
  // data1
  always @(posedge clk) begin
    if(rst) begin
      v1 <= 1'b0;
    end else begin
      if(en) begin
        data1 <= din; 
        v1 <= vin;
      end
    end 
  end

  // base counters
  always @(posedge clk) begin
    if (rst) begin
      l1 <= 0;
      m1 <= 0;
    end else begin
      if (en & v1) begin
        if (l1 == l_reg) begin
          l1 <= 0;
          if (m1 == m_reg) begin
            m1 <= 0;
          end else begin
            m1 <= m1 + 1;
          end
        end else begin
          l1 <= l1 + 1;
        end
      end
    end 
  end

  // STAGE 2
  generate 
    if (NIPC == 1) begin
      always @(posedge clk) begin
        if (en) begin
          data2[31+0*32:16+0*32] <= $signed(data1[31+0*32:16+0*32]) >>> k; 
          data2[15+0*32:32*0] <= $signed(data1[15+0*32:32*0]) >>> k; 
          v2 <= v1;
          l2 <= l1;
          m2 <= m1;
        end
      end
    end else if (NIPC == 2) begin
      always @(posedge clk) begin
        if (en) begin
          data2[31+0*32:16+0*32] <= $signed(data1[31+0*32:16+0*32]) >>> k; 
          data2[15+0*32:32*0] <= $signed(data1[15+0*32:32*0]) >>> k; 
          data2[31+1*32:16+1*32] <= $signed(data1[31+1*32:16+1*32]) >>> k; 
          data2[15+1*32:1*32] <= $signed(data1[15+1*32:1*32]) >>> k; 
          v2 <= v1;
          l2 <= l1;
          m2 <= m1;
        end
      end
    end else if (NIPC == 4) begin
      always @(posedge clk) begin
        if (en) begin
          data2[31+0*32:16+0*32] <= $signed(data1[31+0*32:16+0*32]) >>> k; 
          data2[15+0*32:32*0] <= $signed(data1[15+0*32:32*0]) >>> k; 
          data2[31+1*32:16+1*32] <= $signed(data1[31+1*32:16+1*32]) >>> k; 
          data2[15+1*32:1*32] <= $signed(data1[15+1*32:1*32]) >>> k; 
          data2[31+2*32:16+2*32] <= $signed(data1[31+2*32:16+2*32]) >>> k; 
          data2[15+2*32:2*32] <= $signed(data1[15+2*32:2*32]) >>> k; 
          data2[31+3*32:16+3*32] <= $signed(data1[31+3*32:16+3*32]) >>> k; 
          data2[15+3*32:3*32] <= $signed(data1[15+3*32:3*32]) >>> k; 
          v2 <= v1;
          l2 <= l1;
          m2 <= m1;
        end
      end
    end
  endgenerate

  assign add_en = (m2 == 0) ? 1'b0 : 1'b1;

  // STAGE 3
  generate 
    if (NIPC == 1) begin
      always @(posedge clk) begin
        if (en) begin
          v3 <= v2;
          l3 <= l2;
          m3 <= m2;
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
        if (en) begin
          v3 <= v2;
          l3 <= l2;
          m3 <= m2;
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
        if (en) begin
          v3 <= v2;
          l3 <= l2;
          m3 <= m2;
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

  assign out_en = (m3 == m_reg) ? 1'b1 : 1'b0;

  // output values
  assign dout = data3;
  assign vout = v3 & out_en;


endmodule // blk_avg

`default_nettype wire
