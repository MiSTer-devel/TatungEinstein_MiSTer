//
// HT1080Z for MiSTer Keyboard module
//
// Copyright (c) 2009-2011 Mike Stirling
// Copyright (c) 2015-2017 Sorgelig
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Redistributions in synthesized form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
//
// * Neither the name of the author nor the names of other contributors may
//   be used to endorse or promote products derived from this software without
//   specific prior written agreement from the author.
//
// * License is granted for non-commercial use only.  A fee may not be charged
//   for redistributions as source code or in synthesized/hardware form without
//   specific prior written agreement from the author.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
//
// PS/2 scancode to TRS-80 matrix conversion
//




module keyboard
(
	input             reset,		// reset when driven high
	input             clk_sys,		// should be same clock as clk_sys from HPS_IO

	input      [10:0] ps2_key,		// [7:0] - scancode,
											// [8] - extended (i.e. preceded by scan 0xE0),
											// [9] - pressed
											// [10] - toggles with every press/release

	input       [7:0] addr,			// bottom 7 address lines from CPU for memory-mapped access
	output   reg [7:0] kb_cols,	// data lines returned from scanning

	input					kblayout,	// 0 = TRS-80 keyboard arrangement; 1 = PS/2 key assignment

	output reg [11:1] Fn = 0,
	output reg  [2:0] modif
);

reg  [7:0] keys[7:0];
reg        press_btn = 0;
reg  [7:0] code;
reg		  shiftstate = 0;

always @* begin
	kb_cols = (~addr[0] ? keys[0] : 8'b11111111)
          & (~addr[1] ? keys[1] : 8'b11111111)
          & (~addr[2] ? keys[2] : 8'b11111111)
          & (~addr[3] ? keys[3] : 8'b11111111)
          & (~addr[4] ? keys[4] : 8'b11111111)
          & (~addr[5] ? keys[5] : 8'b11111111)
          & (~addr[6] ? keys[6] : 8'b11111111)
          & (~addr[7] ? keys[7] : 8'b11111111);
end

reg  input_strobe = 0;

always @(posedge clk_sys) begin
	reg old_reset;
	old_reset <= reset;

	if(~old_reset & reset) begin
		keys[0] <= 8'b11111111;
		keys[1] <= 8'b11111111;
		keys[2] <= 8'b11111111;
		keys[3] <= 8'b11111111;
		keys[4] <= 8'b11111111;
		keys[5] <= 8'b11111111;
		keys[6] <= 8'b11111111;
		keys[7] <= 8'b11111111;
		
		modif[0] <= 1'b1;
		modif[1] <= 1'b1;
		modif[2] <= 1'b1;
	end

	if(input_strobe) begin
		case(code)
			8'h59: modif[0] <= ~press_btn; // right shift
			8'h12: modif[0] <= ~press_btn; // left shift
			8'h11: modif[1] <= ~press_btn; // alt
			8'h14: modif[2] <= ~press_btn; // ctrl
		endcase

		case(code)

            8'h7E : keys[0][0] <= ~press_btn; // Scroll lock mapped to Break key
            8'h0D : keys[0][0] <= ~press_btn; // Tab also mapped to Break key
            8'h01 : keys[0][2] <= ~press_btn; // F9 -> F0
            8'h83 : keys[0][3] <= ~press_btn; // F7 -> F7
            8'h77 : keys[0][4] <= ~press_btn; // Num Lock -> Alpha Lock (Caps lock is 0x58)
            8'h5a : keys[0][5] <= ~press_btn; // Enter 0x5a 90
            8'h29 : keys[0][6] <= ~press_btn; // Space
            8'h76 : keys[0][6] <= ~press_btn; // Escape

            8'h43 : keys[1][0] <= ~press_btn; // I
            8'h44 : keys[1][1] <= ~press_btn; // O
            8'h4d : keys[1][2] <= ~press_btn; // P
            8'h5b : keys[1][3] <= ~press_btn; // ] -> 1/4
            8'h54 : keys[1][4] <= ~press_btn; // [ -> £
            8'h72 : keys[1][5] <= ~press_btn; // DN Arrow -> VT/LF
            8'h75 : begin
					keys[1][5] <= ~press_btn; // UP Arrow -> VT/LF
					modif[0] <= ~press_btn;
				end
            8'h0a : keys[1][6] <= ~press_btn; // F8 -> 1/2
            8'h45 : keys[1][7] <= ~press_btn; // 0

            8'h42 : keys[2][0] <= ~press_btn; // K
            8'h4b : keys[2][1] <= ~press_btn; // L 0x4b 75
            8'h4c : keys[2][2] <= ~press_btn; // ; -> +
            8'h52 : keys[2][3] <= ~press_btn; // ' -> *
            8'h5d : keys[2][4] <= ~press_btn; // \ -> 3/4
            8'h6B : begin
					keys[2][5] <= ~press_btn; // LF Arrow -> BS/HT
					modif[0] <= ~press_btn;
				end
            8'h74 : keys[2][5] <= ~press_btn; // RT Arrow -> BS/HT
            8'h29 : keys[2][6] <= ~press_btn; // )
            8'h03 : keys[2][7] <= ~press_btn; // F6 -> F6

            8'h41 : keys[3][0] <= ~press_btn; // , -> <
            8'h49 : keys[3][1] <= ~press_btn; // . -> >
            8'h4a : keys[3][2] <= ~press_btn; // / -> ?
            8'h3e : keys[3][3] <= ~press_btn; // 8 0x3e 62
            8'h66 : keys[3][4] <= ~press_btn; // Backspace -> INS/DEL
            8'h4e : keys[3][5] <= ~press_btn; // -=
            8'h79 : keys[3][6] <= ~press_btn; // + -> ÷
            8'h0c : keys[3][7] <= ~press_btn; // F5 -> F5

            8'h3d : keys[4][0] <= ~press_btn; // 7
            8'h36 : keys[4][1] <= ~press_btn; // 6
            8'h2e : keys[4][2] <= ~press_btn; // 5 0x2e 46
            8'h25 : keys[4][3] <= ~press_btn; // 4
            8'h26 : keys[4][4] <= ~press_btn; // 3
            8'h1e : keys[4][5] <= ~press_btn; // 2
            8'h16 : keys[4][6] <= ~press_btn; // ! 0x16 22
            8'h04 : keys[4][7] <= ~press_btn; // F4 -> F4

            8'h3c : keys[5][0] <= ~press_btn; // U
            8'h35 : keys[5][1] <= ~press_btn; // Y
            8'h2c : keys[5][2] <= ~press_btn; // T
            8'h2d : keys[5][3] <= ~press_btn; // R
            8'h24 : keys[5][4] <= ~press_btn; // E 0x24 36
            8'h1d : keys[5][5] <= ~press_btn; // W
            8'h15 : keys[5][6] <= ~press_btn; // Q
            8'h06 : keys[5][7] <= ~press_btn; // F3 -> F3

            8'h3b : keys[6][0] <= ~press_btn; // J
            8'h33 : keys[6][1] <= ~press_btn; // H
            8'h34 : keys[6][2] <= ~press_btn; // G
            8'h2b : keys[6][3] <= ~press_btn; // F
            8'h23 : keys[6][4] <= ~press_btn; // D
            8'h1b : keys[6][5] <= ~press_btn; // S
            8'h1c : keys[6][6] <= ~press_btn; // A 0x1c 28
            8'h05 : keys[6][7] <= ~press_btn; // F2 -> F2

            8'h3a : keys[7][0] <= ~press_btn; // M
            8'h31 : keys[7][1] <= ~press_btn; // N
            8'h32 : keys[7][2] <= ~press_btn; // B
            8'h2a : keys[7][3] <= ~press_btn; // V
            8'h21 : keys[7][4] <= ~press_btn; // C
            8'h22 : keys[7][5] <= ~press_btn; // X
            8'h1a : keys[7][6] <= ~press_btn; // Z
            8'h0b : keys[7][7] <= ~press_btn; // F7 -> F7 0x83 131

			default: ;
		endcase
	end
end

always @(posedge clk_sys) begin
	reg old_state;

	input_strobe <= 0;
	old_state <= ps2_key[10];

	if(old_state != ps2_key[10]) begin
		press_btn <= ps2_key[9];
		code <= ps2_key[7:0];
		input_strobe <= 1;
	end
end

endmodule