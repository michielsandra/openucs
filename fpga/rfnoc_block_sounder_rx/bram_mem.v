`default_nettype none

module bram_mem #(
  parameter DWIDTH = 32,
  parameter AWIDTH = 10
)(
  input  wire               r_clk,
  input  wire               w_clk,
  input  wire               en,
  input  wire [AWIDTH-1:0]  r_addr,
  input  wire [AWIDTH-1:0]  w_addr,
  input  wire [DWIDTH-1:0]  din,
  output reg  [DWIDTH-1:0]  dout
);

  
  (* ram_style= "block" *) reg [DWIDTH-1:0] mem [(2**AWIDTH)-1:0];

  always @(posedge w_clk) begin
    if (en) begin
      mem[w_addr] <= din; 
    end
  end
  
  always @(posedge r_clk) begin
    if (en) begin
      dout <= mem[r_addr];
    end
  end

endmodule

`default_nettype wire
