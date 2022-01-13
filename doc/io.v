`timescale 1ns/1ns

// $ iverilog -o io -g2012 io.v
// $ vvp io

module io();

  reg [7:0] A;
  reg IORQ, M1;
  wire IO = ~(IORQ|~M1); // disabled when IACK
  wire ADC, PIO, CTC, I026_Y4, FDC, PCI, VDP, PSG;
  wire JR, MB, FIREINT_MSK, ROM, DR_SEL, APH, ADC_MSK, KB_MSK;

  x74138 I026(
    .G1(IO),
    .G2A(A[6]),
    .G2B(A[7]),
    .A(A[5:3]),
    .Y({ ADC, PIO, CTC, I026_Y4, FDC, PCI, VDP, PSG })
  );

  x74138 I027(
    .G1(1'b1),
    .G2A(I026_Y4),
    .G2B(1'b0),
    .A(A[2:0]),
    .Y({ JR, MB, FIREINT_MSK, ROM, DR_SEL, APH, ADC_MSK, KB_MSK })
  );

  initial begin

    // the valid configuration for I/O is /IORQ=0 & /M1=1
    IORQ = 1'b0; // active low, I/O request
    M1 = 1'b1; // active low, FETCH or IACK

    #20
    for (int i=0; i<=255; i=i+1) begin
      A = i;

      #20;

      if (~PSG) $display("$%x: PSG", A);
      if (~VDP) $display("$%x: VDP", A);
      if (~PCI) $display("$%x: PCI", A);
      if (~FDC) $display("$%x: FDC", A);
      if (~CTC) $display("$%x: CTC", A);
      if (~PIO) $display("$%x: PIO", A);
      if (~ADC) $display("$%x: ADC", A);
      if (~KB_MSK) $display("$%x: KB_MSK", A);
      if (~ADC_MSK) $display("$%x: ADC_MSK", A);
      if (~APH) $display("$%x: APH", A);
      if (~DR_SEL) $display("$%x: DR_SEL", A);
      if (~ROM) $display("$%x: ROM", A);
      if (~FIREINT_MSK) $display("$%x: FIREINT_MSK", A);
      if (~MB) $display("$%x: MB", A);
      if (~JR) $display("$%x: JR", A);

    end

    $finish;

  end

endmodule


module x74138(
  input G1,
  input G2A,
  input G2B,
  input [2:0] A,
  output reg [7:0] Y
);

always @*
  if (~G2B & ~G2A & G1) Y = ~(1<<A);
  else Y = 8'b11111111;

endmodule
