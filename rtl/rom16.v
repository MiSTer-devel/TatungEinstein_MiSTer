
module rom16(
  input clk,
  input oe_n,
  input cs_n,
  input [13:0] addr,
  output [7:0] q
);

reg [7:0] data;
reg [7:0] mem[16383:0];

initial $readmemh("rom.mem", mem);

assign q = ~oe_n & ~cs_n ? data : 0;

always @(posedge clk)
  data <= mem[addr];

endmodule
