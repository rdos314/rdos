module dac_app (
  clk,
  reset,
  sample_clk,

  address,
  rd,
  rp,
  rp_address,
  rp_data,
  wr,
  wr_be,
  wr_data
);

  input wire             clk;
  input wire             reset;
  input wire             sample_clk;

  input wire [16:0]      address;
  input wire             rd;
  output reg             rp;
  output reg [4:0]       rp_address;
  output reg [31:0]      rp_data;
  input wire             wr;
  input wire [3:0]       wr_be;
  input wire [31:0]      wr_data;
  output reg             ack;

bram_dac bram_adc_inst (
  .clka(clk),          // input wire clka
  .wea(adc_wr),        // input wire [0 : 0] wea
  .addra(adc_wr_adr),  // input wire [15 : 0] addra
  .dina(adc_rd_data),  // input wire [19 : 0] dina
  .clkb(clk),          // input wire clkb
  .addrb(adc_rd_adr),  // input wire [15 : 0] addrb
  .doutb(adc_rd_data)  // output wire [19 : 0] doutb
);

generate
  begin : dac_app
  end
endgenerate

endmodule
