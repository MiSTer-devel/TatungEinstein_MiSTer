
module T7475(
  input [3:0] d,
  input en,
  output [3:0] q,
  output [3:0] qn
);

assign q = data;
assign qn = ~data;

reg [3:0] data;

always @* if (en) data = d;

endmodule
