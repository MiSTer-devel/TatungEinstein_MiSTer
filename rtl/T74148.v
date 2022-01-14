
module T74148(
  input [7:0] I,
  input EN,
  output reg [2:0] Q,
  output reg GS,
  output reg EO
);

always @*
  if (EN)
    {EO, GS, Q} = 5'b1_1_111;
  else
    casex (I)
      8'b11111111: {EO, GS, Q} = 5'b0_1_111;
      8'b0???????: {EO, GS, Q} = 5'b1_0_000;
      8'b10??????: {EO, GS, Q} = 5'b1_0_001;
      8'b110?????: {EO, GS, Q} = 5'b1_0_010;
      8'b1110????: {EO, GS, Q} = 5'b1_0_011;
      8'b11110???: {EO, GS, Q} = 5'b1_0_100;
      8'b111110??: {EO, GS, Q} = 5'b1_0_101;
      8'b1111110?: {EO, GS, Q} = 5'b1_0_110;
      8'b11111110: {EO, GS, Q} = 5'b1_0_111;
      default:     {EO, GS, Q} = 5'b0_1_111;
    endcase


endmodule
