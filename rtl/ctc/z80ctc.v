/****************************************************************************
		Z80 CTC compatible 2008.12.05

histry:

2008.12. 5 bugfix RETI handling

2005. 4.14 bugfix IEI keep cycle and daisy chain handling
2005. 4.13 1st release

note:

O_TO pulse width are 1.0 clock (Z80CTC == 1.5clk)

****************************************************************************/
//-----------------------
// channel choice
//-----------------------
`define ENABLE_CH0
`define ENABLE_CH1
`define ENABLE_CH2
`define ENABLE_CH3

module z80ctc(
	I_RESET,
	I_CLK,
	I_CLKEN,
	I_A,
	I_D,
	O_D,
	O_DOE,
	I_M1_n,
	I_CS_n,
	I_WR_n,
	I_RD_n,
// IRQ signals from z80_reti module
	I_SPM1, 
	I_RETI, // enter RETI
// Interrupt
	O_INT_n,
	I_IEI,
	O_IEO,
// Timer I/O
	I_TI,
	O_TO
);

input I_RESET;
input I_CLK;
input I_CLKEN;
input [1:0] I_A;
input [7:0] I_D;
output [7:0] O_D;
output O_DOE;
input I_WR_n;
input I_RD_n;
input I_CS_n;
input I_M1_n;
//
input I_SPM1;
input I_RETI;
//
output O_INT_n;
input I_IEI;
output O_IEO;

output [3:0] O_TO;
input [3:0] I_TI;

/////////////////////////////////////////////////////////////////////////////
// wire / reg
/////////////////////////////////////////////////////////////////////////////
wire cs0,cs1,cs2,cs3;
wire wrcs , we;
wire [7:0] cnt0,cnt1,cnt2,cnt3;
wire iei0,iei1,iei2,iei3;
wire ieo0,ieo1,ieo2,ieo3;
wire int0,int1,int2,int3;
wire tcm;

wire [1:0] vec_sel;

wire clk_en_16;
wire clk_en_256;

reg wrcs_r;
reg [4:0] vector;
reg [7:0] pres256;

/////////////////////////////////////////////////////////////////////////////
// 1/16 , 1/256 prescaler
/////////////////////////////////////////////////////////////////////////////
assign clk_en_16	= (pres256[3:0]==4'b1111);
assign clk_en_256 = (pres256[7:4]==4'b1111) & clk_en_16;

always @(posedge I_CLK)
begin
	if(I_RESET)
		pres256 <= 8'h00;
	else if(I_CLKEN)
		pres256 <= pres256 + 1;
end

/////////////////////////////////////////////////////////////////////////////
// generic
/////////////////////////////////////////////////////////////////////////////

// chip select
assign cs0 = (I_A==2'b00);
assign cs1 = (I_A==2'b01);
assign cs2 = (I_A==2'b10);
assign cs3 = (I_A==2'b11);
assign wrcs = ~I_CS_n & ~I_WR_n; // write signal

// event's
assign we 	= ~wrcs_r & wrcs;

// Daisy Chain Signal
assign iei0  = I_IEI;
assign iei1  = ieo0;
assign iei2  = ieo1;
assign iei3  = ieo2;
assign O_IEO = ieo3;
assign O_INT_n = ~(int0|int1|int2|int3);

// interrupt vector selector
assign vec_sel = int0?2'b00 : int1?2'b01 : int2?2'b10 : 2'b11;

always @(posedge I_CLK)
begin
	if(I_RESET)
	begin
		vector	<= 0;
		wrcs_r	<= 1'b0;
	end else begin
		// sampliing Z80 signals
		wrcs_r <= wrcs;

		// vector write
		if(cs0 & we & ~I_D[0] & ~tcm)
			vector <= I_D[7:3];
	end
end

/////////////////////////////////////////////////////////////////////////////
// mux
/////////////////////////////////////////////////////////////////////////////
assign O_D = I_SPM1 ? {vector,vec_sel,1'b0} :
						 cs0 ? cnt0 : cs1 ? cnt1 : cs2 ? cnt2 : cnt3;
assign O_DOE = (I_SPM1&(~O_INT_n)) | (~I_CS_n & ~I_RD_n);

/////////////////////////////////////////////////////////////////////////////
// channels
/////////////////////////////////////////////////////////////////////////////

`ifdef ENABLE_CH0
z80ctc_ch ch0(
	.I_CS(cs0),.O_D(cnt0),
	.I_TI(I_TI[0]),.O_TO(O_TO[0]),
	.I_IEI(iei0),.O_IEO(ieo0),.O_INT(int0),.O_TCM(tcm),
//
	.I_RESET(I_RESET),
	.I_CLK(I_CLK),.I_CLKEN(I_CLKEN),
	.I_CLKEN_16(clk_en_16),.I_CLKEN_256(clk_en_256),
	.I_D(I_D),.I_WE(we),.I_M1_n(I_M1_n),
	.I_SPM1(I_SPM1),.I_RETI(I_RETI)
);
`else
assign ieo0 	 = iei0;
assign O_TO[0] = 1'b0;
assign cnt0 	 = 8'h00;
assign int0 	 = 1'b0;
`endif

`ifdef ENABLE_CH1
z80ctc_ch ch1(
	.I_CS(cs1),.O_D(cnt1),
	.I_TI(I_TI[1]),.O_TO(O_TO[1]),
	.I_IEI(iei1),.O_IEO(ieo1),.O_INT(int1),.O_TCM(),
//
	.I_RESET(I_RESET),
	.I_CLK(I_CLK),.I_CLKEN(I_CLKEN),
	.I_CLKEN_16(clk_en_16),.I_CLKEN_256(clk_en_256),
	.I_D(I_D),.I_WE(we),.I_M1_n(I_M1_n),
	.I_SPM1(I_SPM1),.I_RETI(I_RETI)
);
`else
assign ieo1 	 = iei1;
assign O_TO[1] = 1'b0;
assign cnt1 	 = 8'h00;
assign int1 	 = 1'b0;
`endif

`ifdef ENABLE_CH2
z80ctc_ch ch2(
	.I_CS(cs2),.O_D(cnt2),
	.I_TI(I_TI[2]),.O_TO(O_TO[2]),
	.I_IEI(iei2),.O_IEO(ieo2),.O_INT(int2),.O_TCM(),
//
	.I_RESET(I_RESET),
	.I_CLK(I_CLK),.I_CLKEN(I_CLKEN),
	.I_CLKEN_16(clk_en_16),.I_CLKEN_256(clk_en_256),
	.I_D(I_D),.I_WE(we),.I_M1_n(I_M1_n),
	.I_SPM1(I_SPM1),.I_RETI(I_RETI)
);
`else
assign ieo2 	 = iei2;
assign O_TO[2] = 1'b0;
assign cnt2 	 = 8'h00;
assign int2 	 = 1'b0;
`endif

`ifdef ENABLE_CH3
z80ctc_ch ch3(
	.I_CS(cs3),.O_D(cnt3),
	.I_TI(I_TI[3]),.O_TO(O_TO[3]),
	.I_IEI(iei3),.O_IEO(ieo3),.O_INT(int3),.O_TCM(),
//
	.I_RESET(I_RESET),
	.I_CLK(I_CLK),.I_CLKEN(I_CLKEN),
	.I_CLKEN_16(clk_en_16),.I_CLKEN_256(clk_en_256),
	.I_D(I_D),.I_WE(we),.I_M1_n(I_M1_n),
	.I_SPM1(I_SPM1),.I_RETI(I_RETI)
);
`else
assign ieo3 	 = iei3;
assign O_TO[3] = 1'b0;
assign cnt3 	 = 8'h00;
assign int3 	 = 1'b0;
`endif

endmodule

/////////////////////////////////////////////////////////////////////////////
// timer module
/////////////////////////////////////////////////////////////////////////////
module z80ctc_ch(
	I_RESET,
	I_CLK,
	I_CLKEN,
	I_CLKEN_16,
	I_CLKEN_256,
	I_D,O_D,I_CS,I_WE,I_M1_n,
//
	I_IEI,O_IEO,O_INT,
	I_SPM1,I_RETI,
//
	I_TI,O_TO,O_TCM
);

input I_RESET;
input I_CLK;
input I_CLKEN;
input I_CLKEN_16;
input I_CLKEN_256;
input [7:0] I_D;
output [7:0] O_D;
input I_CS;
input I_WE;
input I_M1_n;

input  I_IEI;
output O_IEO;
output O_INT;
input I_SPM1;
input I_RETI;

input I_TI;
output O_TO;
output O_TCM;

/////////////////////////////////////////////////////////////////////////////
reg [7:0] tc_cnt;
reg [7:0] tc_val;

// Mode Register
reg int_en;
reg cnt_mode;
reg pris256;
reg pos_edge;
reg trg;
reg next_tc;
reg reset_cnt;

reg trg_r1;
reg trg_r2;

reg int_req;
reg int_srv;
reg int_sync;

wire to = (tc_cnt==1);
wire cnt_en = ( cnt_mode ? (~trg_r1 & trg_r2) :
							 pris256 ? I_CLKEN_256 : I_CLKEN_16 ) & ~reset_cnt;

always @(posedge I_CLK)
begin
	if(I_RESET)
	begin
		tc_cnt		<= 8'h00;
		tc_val		<= 8'h00;
		int_en		<= 1'b0;
		cnt_mode	<= 1'b0;
		pris256 	<= 1'b0;
		pos_edge	<= 1'b0;
		trg 			<= 1'b0;
		next_tc 	<= 1'b0;
		reset_cnt <= 1'b1;

		trg_r1		<= 1'b0;
		trg_r2		<= 1'b0;

		int_req 	<= 1'b0;
		int_srv 	<= 1'b0;
		int_sync <= 1'b0;

	end else if(I_CLKEN) begin

		// keep interrupt request in M1 cycle
		if(I_M1_n)
			int_sync <= int_req & ~reset_cnt & I_IEI;

		// trigger sampling
		trg_r1 <= I_TI^pos_edge;
		trg_r2 <= trg_r1;

		// start trigger
		if(trg & trg_r1 & ~trg_r2)
		begin
			trg <= 1'b0;
			// reset_cnt <= 1'b1;
		end

		// countup / preload
		if(cnt_en)
		begin
			if(to)
			begin
				tc_cnt	<= tc_val;
				// IRQ set
				int_req <= int_en & ~reset_cnt;
			end else begin
				tc_cnt	<= tc_cnt-1;
			end
		end

		// IRQ clear , service mode set
		if(I_IEI & I_SPM1 & int_sync)
		begin
			int_srv <= 1'b1;
			int_req <= 1'b0;
		end

		// service mode clear
		if(I_IEI & I_RETI)
		begin
			int_srv <= 1'b0;
		end

		// CPU write
		if(I_CS & I_WE)
		begin
			if(next_tc)
			begin
				// load time constant
				tc_cnt		<= I_D;
				tc_val		<= I_D;
				next_tc 	<= 1'b0;
				reset_cnt <= 1'b0;
			end else if(I_D[0]) begin
				// mode write
				int_en		<= I_D[7];
				cnt_mode	<= I_D[6];
				pris256 	<= I_D[5];
				pos_edge	<= I_D[4];
				trg 			<= I_D[3];
				next_tc 	<= I_D[2];
				reset_cnt <= I_D[1];
				if(~int_en)
					int_req <= 1'b0;
			end
		end
	end
end

assign O_INT = int_sync;
assign O_IEO = I_IEI & ~int_sync & ~int_srv;
assign O_D	 = tc_cnt;
assign O_TO  = to;
assign O_TCM = next_tc;

endmodule
