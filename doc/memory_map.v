`timescale 1ns/1ns

// $ iverilog -o memory_map -g2012 memory_map.v
// $ vvp memory_map

module memory_map();

reg [15:0] A;
reg MREQ, RD;
reg nROM; // from I025a

wire I017a = A[15] | nROM;
wire I017c = MREQ | RD;
wire I017b = I017c | I017a;
wire I017d = I017b | A[14];
wire I022a = ~(A[14] & ~I017b);
wire I023_OE = I017d;
wire I024_OE = I022a;

reg [1:0] prev;
reg test;
initial begin

  #20
  $display("1. testing with: MREQ=1 RD=0 nROM=0");
  test = 0;
  prev = 2'b11;
  MREQ = 1;
  RD = 0;
  nROM = 0;
  for (int i=0; i<=65535; i=i+1) begin
    A = i;
    #20;
    if (prev != { I023_OE, I024_OE }) begin
      test = 1;
      prev = { I023_OE, I024_OE };
    end
  end
  if (test == 0) $display("ROMs disabled");

  #20
  $display("2. testing with: MREQ=0 RD=1 nROM=0");
  test = 0;
  prev = 2'b11;
  MREQ = 0;
  RD = 1;
  nROM = 0;
  for (int i=0; i<=65535; i=i+1) begin
    A = i;
    #20;
    if (prev != { I023_OE, I024_OE }) begin
      test = 1;
      prev = { I023_OE, I024_OE };
    end
  end
  if (test == 0) $display("ROMs disabled");

  #20
  $display("3. testing with: MREQ=0 RD=0 nROM=1");
  test = 0;
  prev = 2'b11;
  MREQ = 0;
  RD = 0;
  nROM = 1;
  for (int i=0; i<=65535; i=i+1) begin
    A = i;
    #20;
    if (prev != { I023_OE, I024_OE }) begin
      test = 1;
      prev = { I023_OE, I024_OE };
    end
  end
  if (test == 0) $display("ROMs disabled");

  #20
  $display("4. testing with: MREQ=0 RD=0 nROM=0 (all enabled)");
  prev = 2'b11;
  MREQ = 0;
  RD = 0;
  nROM = 0;
  for (int i=0; i<=65535; i=i+1) begin
    A = i;
    #20;
    if (prev != { I023_OE, I024_OE }) begin
      if (~I023_OE) $display("$%x: ROM1 ", A);
      if (~I024_OE) $display("$%x: ROM2 ", A);
      prev = { I023_OE, I024_OE };
    end
  end

  $finish;

end


endmodule