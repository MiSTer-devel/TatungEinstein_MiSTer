
module ram
#(
  parameter ADDRWIDTH=12,
  parameter DATAWIDTH=8
)
(
  input clk,
  input [ADDRWIDTH-1:0] addr,
  input [DATAWIDTH-1:0] din,
  output [DATAWIDTH-1:0] q,
  input wr_n,
  input ce_n
);

reg [DATAWIDTH-1:0] data;
reg [DATAWIDTH-1:0] mem[(1<<ADDRWIDTH)-1:0];

assign q = ~ce_n ? data : 8'h0;

always @(posedge clk) begin
  data <= mem[addr];
  if (~ce_n & ~wr_n) mem[addr] <= din;
end


endmodule
