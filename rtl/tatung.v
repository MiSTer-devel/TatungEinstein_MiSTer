
module tatung(
  input clk_sys,
  input clk_cpu, // 4
  input clk_vdp, // 10.6875
  input reset,

  output [7:0] vga_red,
  output [7:0] vga_green,
  output [7:0] vga_blue,
  output vga_hsync,
  output vga_vsync,
  output vga_hblank,
  output vga_vblank,

  output [9:0] sound,

  output [7:0] kb_row,
  input  [7:0] kb_col,
  input        kb_shift,
  input        kb_ctrl,
  input        kb_graph
);

wire [15:0] cpu_addr;
wire [7:0] cpu_dout;
wire iorq_n;
wire m1_n;
wire mreq_n;
wire rd_n;
wire wr_n;

wire io_en = ~iorq_n & m1_n;
wire rom_en = ~io_en && cpu_addr < 16'h8000 && ~I025a;
wire ram_en = ~io_en && (cpu_addr >= 16'h8000 || I025a);

// CPU data bus

wire [7:0] cpu_din =
  // ~KB_MSK_n & ~rd_n ? { kb_shift, kb_ctrl, kb_graph, 1'd1, 4'd0 } : // todo: add I036 (printer/fire)
  ~PSG_n & ~rd_n ? I030_dout :
  ~VDP_n & ~rd_n ? vdp_dout :
  ctc_doe ? ctc_dout :
  rom_en ? rom_dout :
  ram_en ? ram_dout : 8'hff;

  
// interrupt vectors
reg [7:0] nz80v;
always @*
  if (~kb_int_n) begin
    nz80v = 8'h0e;
  end
  else if (~ctc_int_n) begin
    nz80v = ctc_dout;
  end
  /*else if (~adc_int_n) begin
    nz80v = 8'h0a;
  end
  else if (~fire_int_n) begin
    nz80v = 8'h0c;
  end*/

// keyboard interrupt & mask
reg kb_int_n, kb_int_mask;
reg old_kb_en;
wire kb_en = ~&kb_col;
always @(posedge clk_sys) begin
  old_kb_en <= kb_en;
  if (reset) begin
    kb_int_mask <= 1'b1;
  end
  else if (~wr_n & ~KB_MSK_n) begin
    kb_int_mask <= cpu_dout[0];
  end
  // keyboard interrupt
  if (reset || (~KB_MSK_n & ~rd_n)) begin
    kb_int_n <= 1'b1;
  end
  else if (~kb_int_mask && ~old_kb_en && kb_en) begin
    //if (kb_col) kb_int_n <= 1'b0;
    kb_int_n <= 1'b0;
  end
end

wire int_n = ctc_int_n & kb_int_n;// 1'b1;//kb_int_n & ctc_int_n;


// clocks & enables

reg [3:0] clk_cnt;
reg clk_2, cen_2;
always @(posedge clk_cpu)
	clk_2 <= ~clk_2;

always @(posedge clk_sys)
  if (clk_cnt == 4'd9) begin
    cen_2 <= 1'b1;
    clk_cnt <= 4'd0;
  end
  else begin
    cen_2 <= 1'b0;
    clk_cnt <= clk_cnt + 4'd1;
  end

// CPU

// tv80s tv80s(
//   .reset_n(~reset),
//   .clk(clk_sys),
//   .wait_n(1'b1),
//   .int_n(1'b1),
//   .nmi_n(1'b1),
//   .busrq_n(1'b1),
//   .m1_n(m1_n),
//   .mreq_n(mreq_n),
//   .iorq_n(iorq_n),
//   .rd_n(rd_n),
//   .wr_n(wr_n),
//   .rfsh_n(),
//   .halt_n(),
//   .busak_n(),
//   .A(cpu_addr),
//   .di(cpu_din),
//   .dout(cpu_dout)
// );


t80s t80s(
  .RESET_n(~reset),
  .CLK(clk_cpu),
  .CEN(1'b1),
  .WAIT_n(1'b1),
  .INT_n(int_n),
  .NMI_n(1'b1),
  .BUSRQ_n(1'b1),
  .M1_n(m1_n),
  .MREQ_n(mreq_n),
  .IORQ_n(iorq_n),
  .RD_n(rd_n),
  .WR_n(wr_n),
  .RFSH_n(),
  .HALT_n(),
  .BUSAK_n(),
  .A(cpu_addr),
  .DI(cpu_din),
  .DO(cpu_dout)
);


// I/O enables

wire ADC, PIO, CTC_n, I026_Y4, FDC, PCI, VDP_n, PSG_n;
wire JR, MB, FIREINT_MSK, ROM_n, DR_SEL, APH, ADC_MSK, KB_MSK_n;

x74138 I026(
  .G1(~(iorq_n|~m1_n)),
  .G2A(cpu_addr[6]),
  .G2B(cpu_addr[7]),
  .A(cpu_addr[5:3]),
  .Y({ ADC, PIO, CTC_n, I026_Y4, FDC, PCI, VDP_n, PSG_n })
);

x74138 I027(
  .G1(1'b1),
  .G2A(I026_Y4),
  .G2B(1'b0),
  .A(cpu_addr[2:0]),
  .Y({ JR, MB, FIREINT_MSK, ROM_n, DR_SEL, APH, ADC_MSK, KB_MSK_n })
);

// ROM status toggler

reg I025a;
always @(posedge ROM_n, posedge reset)
  if (reset)
    I025a <= 1'b0;
  else
    I025a <= ~I025a;


// Memories

	 
wire [7:0] rom_dout;

rom16 I023(
  .clk(clk_sys),
  .oe_n(~rom_en),
  .cs_n(I025a),
  .addr(cpu_addr[13:0]),
  .q(rom_dout)
);

wire [7:0] ram_dout;

ram #(.ADDRWIDTH(16), .DATAWIDTH(8)) ram(
  .clk(clk_sys),
  .addr(cpu_addr),
  .din(cpu_dout),
  .q(ram_dout),
  .wr_n(wr_n),
  .ce_n(~ram_en)
);

wire vram_we;
wire [13:0] vram_addr;
wire [7:0] vram_din, vram_dout;

// 16k
ram #(.ADDRWIDTH(14), .DATAWIDTH(8)) vram(
  .clk(clk_sys),
  .addr(vram_addr),
  .din(vram_din),
  .q(vram_dout),
  .wr_n(~vram_we),
  .ce_n(1'b0)
);


// VDP

wire [7:0] vdp_dout;

vdp18_core vdp18(
  .clk_i(clk_vdp),
  .clk_en_10m7_i(1'b1),
  .reset_n_i(~reset),

  .csr_n_i(VDP_n|rd_n),
  .csw_n_i(VDP_n|wr_n),
  .mode_i(cpu_addr[0]),
  .int_n_o(),
  .cd_i(cpu_dout),
  .cd_o(vdp_dout),

  .vram_we_o(vram_we),
  .vram_a_o(vram_addr),
  .vram_d_o(vram_din),
  .vram_d_i(vram_dout),

  .border_i(),
  .col_o(),
  .rgb_r_o(vga_red),
  .rgb_g_o(vga_green),
  .rgb_b_o(vga_blue),
  .hsync_n_o(vga_hsync),
  .vsync_n_o(vga_vsync),
  .blank_n_o(),
  .hblank_o(vga_hblank),
  .vblank_o(vga_vblank),
  .comp_sync_n_o()
);


// AUDIO

wire [7:0] I030_dout;

jt49_bus I030(
  .rst_n(~reset),
  .clk(clk_sys),
  .clk_en(cen_2),
  .bdir(~(PSG_n|wr_n)),
  .bc1(~(PSG_n|cpu_addr[0])),
  .din(cpu_dout),
  .sel(1'b1),
  .dout(I030_dout),
  .sound(sound),
  .A(),
  .B(),
  .C(),
  .sample(),
  .IOA_in(),
  .IOA_out(kb_row),
  .IOB_in(kb_col),
  .IOB_out()
);

// CTC

wire [3:0] zc_to;
wire ctc_int_n;
wire ctc_doe;
wire [7:0] ctc_dout;
wire clk_ctc = clk_cpu;
wire ctc_ieo;

wire zreti;
wire zspm1;

z80reti z80reti(
  .I_RESET(reset),
  .I_CLK(clk_ctc),
  .I_CLKEN(1'b1),
  .I_M1_n(m1_n),
  .I_MREQ_n(mreq_n),
  .I_IORQ_n(iorq_n),
  .O_RETI(zreti),
  .O_SPM1(zspm1)
);

z80ctc ctc(
  .I_RESET(reset),
  .I_CLK(clk_ctc),
  .I_CLKEN(1'b1),
  .I_A(cpu_addr[1:0]),
  .I_D(cpu_dout),
  .O_D(ctc_dout),
  .O_DOE(ctc_doe),
  .I_M1_n(m1_n),
  .I_CS_n(CTC_n),
  .I_WR_n(wr_n),
  .I_RD_n(rd_n),
  .I_SPM1(zspm1),
  .I_RETI(zreti),
  .O_INT_n(ctc_int_n),
  .I_IEI(kb_int_n),
  .O_IEO(ctc_ieo),
  .I_TI({ zc_to[2], {3{clk_2}} }),
  .O_TO(zc_to)
);

endmodule