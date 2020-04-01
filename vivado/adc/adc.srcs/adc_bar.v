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

  reg                    bar_wr;
  reg                    bar_wr_valid;
  reg  [15:0]            bar_wr_adr;
  reg  [19:0]            bar_wr_data;

  reg                    bar_rd;
  reg                    bar_msb;
  wire [15:0]            bar_rd_adr;
  wire [19:0]            bar_rd_data;

  reg  [15:0]            q_rd_adr;

  reg  [16:0]            adc_curr_index;


bram_adc bram_adc_inst (
  .clka(up_clk),       // input wire clka
  .wea(wr),            // input wire [0 : 0] wea
  .addra(bar_wr_adr),  // input wire [15 : 0] addra
  .dina(bar_wr_data),  // input wire [19 : 0] dina
  .clkb(up_clk),       // input wire clkb
  .addrb(bar_rd_adr),  // input wire [15 : 0] addrb
  .doutb(bar_rd_data)  // output wire [19 : 0] doutb
);

generate
begin : adc_app

  assign bar_rd_adr = rd ? rd_address[16:1] : adc_index;

  always @ ( posedge up_clk ) 
  begin
    if (bar_rd)
    begin
      if (bar_msb)
      begin
        rp_data[8:0] <= bar_rd_data[19:11];
        rp_data[31:9] <= 0;
      end
      else
      begin
        rp_data[20:0] <= 0;
        rp_data[31:21] <= bar_rd_data[10:0];
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
      bar_rd <= 0;
      q_rd_adr <= 0;
    end
    else
    begin
      q_rd_adr <= bar_rd_adr;

      if (wr)
      begin
        bar_wr_adr <= wr_address[16:1];
        if (wr_address[0])
          bar_wr_data[19:11] <= wr_data[8:0];
        else
          bar_wr_data[10:0] = wr_data[31:21];

        bar_rd <= 0;
      end
      else
      begin
        if (rd)
        begin
          bar_msb <= rd_address[0];
          bar_rd <= 1;
        end
        else
          bar_rd <= 0;
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
          adc_address[40:21] <= bar_rd_data;
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

end
endgenerate

endmodule
