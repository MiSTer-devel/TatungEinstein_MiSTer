`timescale 1ns/1ns

// $ iverilog -o vectors -g2012 vector.v
// $ vvp vectors
// $ gtkwave dump.vcd

module vectors();

  reg M1, IORQ;
  reg kbint_n, adcint_n, fireint_n;
  wire INA_n = M1 | IORQ;

  wire [3:0] _75_q;
  wire _148_gs;
  wire [2:0] _148_q;
  wire [7:0] data;

  wire I064 = INA_n | _148_gs;

  _74ls75 _74ls75(
    .d({ 1'b1, adcint_n, fireint_n, kbint_n }),
    .en(I064),
    .q(_75_q)
  );

  _74ls148 _74ls148(
    .I({ 4'b1111, _75_q }),
    .EN(1'b0),
    .GS(_148_gs),
    .Q(_148_q)
  );

  _74ls244 _74ls244(
    .A({ 1'b0, _148_q[0], _148_q[1], _148_q[2], 4'b0 }),
    .OE({ I064, I064 }),
    .Y({
      data[0], data[1], data[2], data[3],
      data[4], data[5], data[6], data[7]
    })
  );

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, vectors);

    IORQ = 1'b1;
    M1 = 1'b1;
    kbint_n = 1'b1;
    fireint_n = 1'b1;
    adcint_n = 1'b1;

    #20
    kbint_n = 1'b0;

    #20
    IORQ = 1'b0;
    M1 = 1'b0;

    #20
    kbint_n = 1'b1;
    fireint_n = 1'b0;

    #20
    fireint_n = 1'b1;
    adcint_n = 1'b0;


    #20
    $finish;

  end

endmodule


module _74ls148(
  input [7:0] I,
	input EN,
	output reg [2:0] Q,
	output reg GS,
	output reg EO
);

always @*
  if (EN) {EO, GS, Q} = 5'b11_111;
	else if (I == 8'b1111_1111) {EO, GS, Q} = 5'b01_111;
	else if (!I[7]) {EO, GS, Q} = 5'b10_000;
	else if (!I[6]) {EO, GS, Q} = 5'b10_001;
	else if (!I[5]) {EO, GS, Q} = 5'b10_010;
	else if (!I[4]) {EO, GS, Q} = 5'b10_011;
	else if (!I[3]) {EO, GS, Q} = 5'b10_100;
	else if (!I[2]) {EO, GS, Q} = 5'b10_101;
	else if (!I[1]) {EO, GS, Q} = 5'b10_110;
	else if (!I[0]) {EO, GS, Q} = 5'b10_111;
	else		{EO, GS, Q} = 5'b01_111;


endmodule

module _74ls75(
  input [3:0] d,
  input en,
  output [3:0] q,
  output [3:0] qn
);

assign q = ~en ? d : 4'd0;
assign qn = ~q;

endmodule

module _74ls244(
  input [7:0] A,
  input [1:0] OE,
  output [7:0] Y
);

assign Y = {
  OE[1] ? 4'd0 : A[7:4],
  OE[0] ? 4'd0 : A[3:0]
};

endmodule
