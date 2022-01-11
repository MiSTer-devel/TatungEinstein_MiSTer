
module ADC0844(

  input clk,

  input [3:0] ma,
  output reg [7:0] db,

  input rd_n,
  input wr_n,
  input cs_n,
  output reg intr_n = 1,

  input [7:0] ch1,
  input [7:0] ch2,
  input [7:0] ch3,
  input [7:0] ch4,

  input analog,
  input [3:0] dj1,
  input [3:0] dj2
);

reg old_wr;
reg old_rd;

reg [3:0] conf;
reg convert = 1'b0;
reg [7:0] dout;
reg adc_wr;

always @(posedge clk) begin

  old_wr <= wr_n;
  old_rd <= rd_n;

  // reset int on the falling edge of wr_n
  if (old_wr & ~wr_n & ~cs_n) begin
    adc_wr <= 1'b1; // mark as a valid write
    intr_n <= 1'b1;
  end

  // valid write rising edge
  if (~old_wr & wr_n & adc_wr) begin

    adc_wr <= 1'b0;

    // latch config if not reading
    if (rd_n) begin
      conf <= ma;
      convert <= 1'b1;
    end

  end

  if (convert) begin

    // prepare output
    if (analog) begin
      casez (conf)
        4'b?000: dout <= ch1 > ch2 ? ch1-ch2 : 8'd0;
        4'b?001: dout <= ch2 > ch1 ? ch2-ch1 : 8'd0;
        4'b?010: dout <= ch3 > ch4 ? ch3-ch4 : 8'd0;
        4'b?011: dout <= ch4 > ch3 ? ch4-ch3 : 8'd0;
        4'b0100: dout <= ch1;
        4'b0101: dout <= ch2;
        4'b0110: dout <= ch3;
        4'b0111: dout <= ch4;
        4'b1100: dout <= ch1 > ch4 ? ch1-ch4 : 8'd0;
        4'b1101: dout <= ch2 > ch4 ? ch2-ch4 : 8'd0;
        4'b1110: dout <= ch3 > ch4 ? ch3-ch4 : 8'd0;
      endcase
    end
    else begin
      case (conf[1:0])
        2'b00: dout <= dj1[0] ? 8'd255 : dj1[1] ? 8'd0 : 8'd128;
        2'b01: dout <= dj1[2] ? 8'd255 : dj1[3] ? 8'd0 : 8'd128;
        2'b10: dout <= dj2[0] ? 8'd255 : dj2[1] ? 8'd0 : 8'd128;
        2'b11: dout <= dj2[2] ? 8'd255 : dj2[3] ? 8'd0 : 8'd128;
      endcase
    end

    // inform we are ready
    intr_n <= 1'b0;

    // output data on the falling edge of rd_n and reset int
    if (old_rd & ~rd_n & ~cs_n) begin
      convert <= 1'b0;
      intr_n <= 1'b1;
      db <= dout;
    end

  end

end

endmodule