`timescale 1ns/100ps

module daq2_spi (
  input                   spi_rq_rd,
  input      [1:0]        spi_rq_cs,
  input                   spi_rq_word,  
  input      [11:0]       spi_rq_adr,
  input                   spi_rq,
  input      [15:0]       spi_rq_data,
  output reg              spi_ack,

  output reg [1:0]        spi_rp_cs,
  output reg [11:0]       spi_rp_adr,
  output reg              spi_rp,
  output reg [15:0]       spi_rp_data,

  output reg              spi_cs_clk,
  output reg              spi_cs_adc,
  output reg              spi_cs_dac,
  input                   spi_clk,
  inout                   spi_sdio,
  output reg              spi_dir);

  // internal registers

  reg [5:0]               spi_count;
  reg [5:0]               spi_size;
  reg [14:0]              spi_cmd;   
  reg                     spi_rd_wr_n;
  reg                     spi_z;
  reg                     spi_out_bit;

ila_5 ila5_inst (
   .clk ( spi_clk ),                     // I
   .probe0(spi_rq_rd),                   // input wire [0:0]  probe1 
   .probe1(spi_rq_cs),                   // input wire [1:0]  probe1 
   .probe2(spi_rq_word),                 // input wire [0:0]  probe1 
   .probe3(spi_rq_adr),                  // input wire [11:0]  probe1 
   .probe4(spi_rq),                      // input wire [0:0]  probe1 
   .probe5(spi_rq_data),                 // input wire [15:0]  probe1 
   .probe6(spi_ack),                     // input wire [0:0]  probe1 
   .probe7(spi_rp_cs),                   // input wire [1:0]  probe1 
   .probe8(spi_rp_adr),                  // input wire [11:0]  probe1 
   .probe9(spi_rp),                      // input wire [0:0]  probe1 
   .probe10(spi_rp_data),                // input wire [15:0]  probe1 
   .probe11(spi_cs_clk),                 // input wire [0:0]  probe1 
   .probe12(spi_cs_adc),                 // input wire [0:0]  probe1 
   .probe13(spi_cs_dac),                 // input wire [0:0]  probe1 
   .probe14(spi_sdio),                   // input wire [0:0]  probe1 
   .probe15(spi_dir),                    // input wire [0:0]  probe1 
   .probe16(spi_count),                  // input wire [5:0]  probe1 
   .probe17(spi_size),                   // input wire [5:0]  probe1 
   .probe18(spi_rd_wr_n),                // input wire [0:0]  probe1 
   .probe19(spi_z),                      // input wire [0:0]  probe1 
   .probe20(spi_out_bit)                 // input wire [0:0]  probe1 
);

  always @(posedge spi_clk) 
  begin
    if (spi_rq)
    begin
      if (!spi_count || spi_ack)
        spi_out_bit = spi_rq_adr[15];
      else
      begin
        if (spi_count < 16)
          spi_out_bit = spi_cmd[14];
        else
          spi_out_bit = spi_rp_data[15];
      end
    end
    else
      spi_out_bit = 0;
  end
  

  always @(posedge spi_clk) 
  begin
    if (spi_rq)
    begin
      if (!spi_count || spi_ack)
      begin
        spi_cmd[12] <= 0;
        spi_cmd[13] <= spi_rq_word;
        spi_cmd[14] <= 0;
        spi_rd_wr_n <= spi_rq_rd;

        if (spi_rq_word)
          spi_cmd[11:0] <= spi_rq_adr + 1;
        else
          spi_cmd[11:0] <= spi_rq_adr;

        case (spi_rq_cs)
          0:
          begin
            spi_cs_clk <= 0;
            spi_cs_adc <= 1;
            spi_cs_dac <= 1;
          end

          1:
          begin
            spi_cs_clk <= 1;
            spi_cs_adc <= 0;
            spi_cs_dac <= 1;
          end

          2:
          begin
            spi_cs_clk <= 1;
            spi_cs_adc <= 1;
            spi_cs_dac <= 0;
          end
        endcase

        spi_count <= 1;
        spi_ack <= 0;        
      end
      else
      begin
        if (spi_count < spi_size)
        begin
          spi_count <= spi_count + 1;
          spi_ack <= 0;        
        end
        else
        begin
          spi_ack <= 1;        
          spi_cs_clk <= 1;
          spi_cs_adc <= 1;
          spi_cs_dac <= 1;
        end
      end
    end
    else
    begin
      spi_ack <= 0;        
      spi_cs_clk <= 1;
      spi_cs_adc <= 1;
      spi_cs_dac <= 1;
      spi_count <= 0;
    end
  end

  always @(posedge spi_clk) 
  begin
    if (spi_rq)
    begin
      if (!spi_count || spi_ack)
      begin
        spi_rp_adr <= spi_rq_adr;

        if (spi_rq_word)
        begin
          spi_size <= 32;
          spi_rp_data <= spi_rq_data;
        end
        else
        begin
          spi_size <= 24;
          spi_rp_data[15:8] <= spi_rq_data[7:0];
        end
      end
      else
      begin
        if ((spi_count >= 16) && (spi_count < spi_size))
        begin
          spi_rp_data[0] <= spi_sdio;
          spi_rp_data[15:1] <= spi_rp_data[14:0];
        end
      end
    end
  end

  always @(posedge spi_clk) 
  begin
    if (spi_ack)
    begin
      if (spi_rd_wr_n)
        spi_rp <= 1;
      else
        spi_rp <= 0;
    end
    else
      spi_rp <= 0;
  end

  always @(negedge spi_clk) 
  begin
    if (spi_rq)
    begin
      if (spi_ack)
        spi_z <= 0;
      else
        if (spi_count >= 16)
          spi_z <= spi_rd_wr_n;
    end
    else
      spi_z <= 0;
  end

  assign spi_sdio = spi_z ? 1'bz : spi_out_bit;


endmodule
