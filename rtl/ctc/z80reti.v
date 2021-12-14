// from https://github.com/caramelgate/DE0_ExpansionCard

//
//  Z80 Daisy Chain interrupt handling signal generator 2005.4.13
//
//
module z80reti(
  I_RESET,
  I_CLK,
  I_CLKEN,
  I_M1_n,
  I_MREQ_n,
  I_IORQ_n,
  I_D,
//
  O_RETI,
  O_SPM1
);

input I_RESET;
input I_CLK;
input I_CLKEN;
input I_M1_n;
input I_MREQ_n;
input I_IORQ_n;
input [7:0] I_D;
output O_RETI;
output O_SPM1;

/////////////////////////////////////////////////////////////////////////////
reg ditect_ncb;
reg ditect_ncb_ed;
reg ditect_ncb_ed_4d;
reg m1cycle_r;
reg is_cb,is_ed,is_4d;
wire is_cd_ed_4d;

// CB/ED = 11x0 1xx1
// CB    = 1100 1011
// ED    = 1110 1101
// 4D    = 0100 1101
// ALL   = x1x0 1xx1
assign is_cd_ed_4d = (I_D[6] & ~I_D[4] & I_D[3] & I_D[0]);

wire m1cycle = ~I_M1_n & ~I_MREQ_n;
wire spm1    = ~I_M1_n & ~I_IORQ_n;

always @(posedge I_CLK)
begin
  if(I_RESET)
  begin
    ditect_ncb       <= 1'b0;
    ditect_ncb_ed    <= 1'b0;
    ditect_ncb_ed_4d <= 1'b0;
    m1cycle_r        <= 1'b0;
  end else if(I_CLKEN)
  begin
    m1cycle_r   <= m1cycle;

    // M1 PREFETCH OP-CODE Ditector
    is_cb <= is_cd_ed_4d &  I_D[7] & ~I_D[5] & ~I_D[2] &  I_D[1];
    is_ed <= is_cd_ed_4d &  I_D[7] &  I_D[5] &  I_D[2] & ~I_D[1];
    is_4d <= is_cd_ed_4d & ~I_D[7] & ~I_D[5] &  I_D[2] & ~I_D[1];

    if(m1cycle_r & ~m1cycle)
    begin
      ditect_ncb       <= ~is_cb;
      ditect_ncb_ed    <= ditect_ncb    & is_ed;
      ditect_ncb_ed_4d <= ditect_ncb_ed & is_4d;
    end else begin
      ditect_ncb_ed_4d <= 1'b0;
    end

  end
end

assign O_RETI = ditect_ncb_ed_4d;
assign O_SPM1 = spm1;

endmodule