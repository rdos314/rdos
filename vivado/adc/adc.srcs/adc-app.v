module adc_app (
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
  wr_data,
  ack
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


// local
  reg                    adc_wr;
  reg  [15:0]            adc_wr_adr;
  reg  [19:0]            adc_rd_data;
  reg  [15:0]            adc_rd_adr;
  wire [19:0]            adc_rd_data;

  reg  [63:0]            curr_data;

bram_adc bram_adc_inst (
  .clka(clk),          // input wire clka
  .wea(adc_wr),        // input wire [0 : 0] wea
  .addra(adc_wr_adr),  // input wire [15 : 0] addra
  .dina(adc_rd_data),  // input wire [19 : 0] dina
  .clkb(clk),          // input wire clkb
  .addrb(adc_rd_adr),  // input wire [15 : 0] addrb
  .doutb(adc_rd_data)  // output wire [19 : 0] doutb
);


ila_3 ila3_inst (
    .clk ( clk ),                         // I
);


generate
  begin : adc_app

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      ack <= 0;
      rp <= 0;
      adc_wr <= 0;
    end
    else
    begin
      if (wr)
      begin
        if (adc_rd_adr == address[16:1])
        begin
          curr_data[20:0] = 0;
          curr_data[40:21] = adc_rd_data;
          curr_data[63:41] = 0;

          if (wr_be[0])
            curr_data[7:0] = wr_data[7:0];

          if (wr_be[1])
            curr_data[15:8] = wr_data[15:8];
 
          if (wr_be[2])
            curr_data[23:16] = wr_data[23:16];

          if (wr_be[3])
            curr_data[31:24] = wr_data[31:24];
        end
      end

      if (rd)
      begin
        if (adc_rd_adr == address[16:1])
        begin
          rp_adr <= address[4:0];
          rp <= 1;

          if (address[0])
          begin
            rp_data[8:0] <= adc_rd_data[19:11];
            rp_data[31:9] <= 0;
          end
          else
          begin
            rp_data[20:0] <= 0;
            rp_data[31:21] <= adc_rd_data[10:0];
          end
        end
        else
        begin
          rp <= 0;
          adc_rd_adr <= address[16:1];
        end
      end
      else
        rp <= 0;

      if (wr)
      begin
        if (adc_rd_adr == address[16:1])
        begin
          adc_wr_adr = address[16:1];
          adc_wr <= 1;
          ack <= 1;
        end
        else
        begin
          adc_wr <= 0;
          ack <= 0;
          adc_rd_adr <= address[16:1];
        end
      end
      else
      begin
        ack <= 0;
        adc_wr <= 0;
      end
    end
  end
endgenerate

endmodule
