module adc_bar (
  input wire              up_reset,
  input wire              up_clk,

  input wire [16:0]       rd_address,
  input wire              rd,

  output reg [31:0]       rp_data,
  output reg              rp,

  input wire [16:0]       wr_address,
  input wire [31:0]       wr_data,
  input wire [3:0]        wr_be,
  input wire              wr,

  input wire [16:0]       adc_index,
  output reg [63:0]       adc_address,
  output reg              adc_valid
);

// local bar

  wire [15:0]            rd_only_adr;
  wire [15:0]            rd_adr;

  reg                    q_rd;
  reg                    q_rd_msb;
  reg  [15:0]            q_rd_adr;
  wire [19:0]            q_rd_data;

  reg                    q_pend_wr;
  reg  [31:0]            q_pend_data;
  reg  [3:0]             q_pend_be;
  reg                    q_wr_msb;
  reg                    q_wr;
  reg  [15:0]            q_wr_adr;
  reg  [19:0]            q_wr_data;

  reg  [16:0]            adc_curr_index;


bram_adc bram_adc_inst (
  .clka(up_clk),      // input wire clka
  .wea(q_wr),         // input wire [0 : 0] wea
  .addra(q_wr_adr),   // input wire [15 : 0] addra
  .dina(q_wr_data),   // input wire [19 : 0] dina
  .clkb(up_clk),      // input wire clkb
  .addrb(rd_adr),     // input wire [15 : 0] addrb
  .doutb(q_rd_data)   // output wire [19 : 0] doutb
);


ila_4 ila_4_inst (
	.clk(up_clk),                         // input wire clk
	.probe0(rd_address),       // input wire [16:0]  probe0  
	.probe1(rd),               // input wire [0:0]  probe0  
	.probe2(rp),               // input wire [0:0]  probe0  
	.probe3(rp_data),           // input wire [31:0]  probe0  
	.probe4(wr_address),       // input wire [16:0]  probe0  
	.probe5(wr_data),          // input wire [31:0]  probe0  
	.probe6(wr_be),            // input wire [3:0]  probe0  
	.probe7(wr),               // input wire [0:0]  probe0  
	.probe8(adc_index),        // input wire [16:0]  probe0  
	.probe9(adc_address),      // input wire [63:0]  probe0  
	.probe10(adc_valid),       // input wire [0:0]  probe0  
	.probe11(rd_only_adr),     // input wire [15:0]  probe0  
	.probe12(rd_adr),          // input wire [15:0]  probe0  
	.probe13(q_rd),            // input wire [0:0]  probe0  
	.probe14(q_rd_msb),        // input wire [0:0]  probe0  
	.probe15(q_rd_adr),        // input wire [15:0]  probe0  
	.probe16(q_rd_data),       // input wire [19:0]  probe0  
	.probe17(q_pend_wr),       // input wire [0:0]  probe0  
	.probe18(q_pend_data),     // input wire [31:0]  probe0  
	.probe19(q_wr_msb),        // input wire [0:0]  probe0  
	.probe20(q_wr),            // input wire [0:0]  probe0  
	.probe21(q_wr_data),       // input wire [19:0]  probe0  
	.probe22(adc_curr_index)   // input wire [16:0]  probe0  
); 


generate
begin : adc_app

  assign rd_only_adr = rd ? rd_address[16:1] : adc_index;
  assign rd_adr = wr ? wr_address[16:1] : rd_only_adr;

  always @ ( posedge up_clk ) 
  begin
    if (q_rd)
    begin
      if (q_rd_msb)
      begin
        rp_data[8:0] <= q_rd_data[19:11];
        rp_data[31:9] <= 0;
      end
      else
      begin
        rp_data[20:0] <= 0;
        rp_data[31:21] <= q_rd_data[10:0];
      end
      rp <= 1;
    end
    else
      rp <= 0;
  end

  always @ ( posedge up_clk ) 
  begin
    if (up_reset)
    begin
      q_rd <= 0;
      q_wr <= 0;
      q_rd_adr <= 0;
      q_pend_wr <= 0;
    end
    else
    begin
      q_rd_adr <= rd_adr;

      if (wr)
      begin
        q_wr_adr <= wr_address[16:1];
        q_wr_msb <= wr_address[0];
        q_pend_data <= wr_data;
        q_pend_be <= wr_be;
        q_rd <= 0;
        q_wr <= 0;
        q_pend_wr <= 1;
      end
      else
      begin
        if (rd)
        begin
          q_rd_msb <= rd_address[0];
          q_rd <= 1;
        end
        else
          q_rd <= 0;

        if (q_pend_wr)
        begin
          if (q_wr_msb)
          begin
            if (q_pend_be[1])
              q_wr_data[19] <= q_pend_data[8];
            else
              q_wr_data[19] <= q_rd_data[19];

            if (q_pend_be[0])
              q_wr_data[18:11] <= q_pend_data[7:0];
            else
              q_wr_data[18:11] <= q_rd_data[18:11];
            
            q_wr_data[10:0] <= q_rd_data[10:0];
          end
          else
          begin
            if (q_pend_be[3])
              q_wr_data[10:3] <= q_pend_data[31:24];
            else
              q_wr_data[10:3] <= q_rd_data[10:3];

            if (q_pend_be[2])
              q_wr_data[2:0] <= q_pend_data[23:21];
            else
              q_wr_data[2:0] <= q_rd_data[2:0];

            q_wr_data[19:11] <= q_rd_data[19:11];
          end

          q_wr <= 1;
          q_pend_wr <= 0;
        end
        else
          q_wr <= 0;

        end
      end
    end
  end

  always @ ( posedge up_clk ) 
  begin
    if (up_reset)
    begin
      adc_valid <= 0;
      adc_address[63:0] <= 0;
      adc_curr_index <= 0;
    end
    else
    begin
      if (adc_curr_index == adc_index)
      begin
        if (q_rd_adr == adc_index)
        begin
          adc_address[20:0] <= 0;
          adc_address[40:21] <= q_rd_data;
          adc_address[63:41] <= 0;
          adc_valid <= 1;
        end
      end
      else
      begin
        adc_curr_index <= adc_index;
        adc_valid <= 0;
      end
    end
  end

endgenerate

endmodule
