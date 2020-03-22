`timescale 1ns/100ps

module daq2_spi (
  input                   reset,
  input                   up_clk,

  input                   spi_rq_rd,
  input      [1:0]        spi_rq_cs,
  input                   spi_rq_word,  
  input      [11:0]       spi_rq_adr,
  input                   spi_rq_empty,
  input      [15:0]       spi_rq_data,
  output reg              spi_rq_ack,

  output reg [29:0]       spi_rp_data,
  output reg              spi_rp_wr,

  input                   adc_read,
  input                   adc_write,
  input      [11:0]       adc_adr,
  output reg [7:0]        adc_in_data,
  input      [7:0]        adc_out_data,
  output reg              adc_running,
  output reg              adc_done,

  output reg              spi_cs_clk,
  output reg              spi_cs_adc,
  output reg              spi_cs_dac,
  output reg              spi_clk,
  inout                   spi_sdio,
  output reg              spi_dir);

  // internal registers
  
  reg [2:0]               spi_delay;
  reg                     spi_started;
  reg [5:0]               spi_count;
  reg [5:0]               spi_size;
  reg [15:0]              spi_cmd;   
  reg                     spi_rd_wr_n;
  reg                     spi_z;
  reg                     spi_out;

  reg [15:0]              spi_out_data;
  reg [15:0]              spi_in_data;

ila_5 ila5_inst (
   .clk ( up_clk ),                      // I
   .probe0(spi_rq_rd),                   // input wire [0:0]  probe1 
   .probe1(spi_rq_cs),                   // input wire [1:0]  probe1 
   .probe2(spi_rq_word),                 // input wire [0:0]  probe1 
   .probe3(spi_rq_adr),                  // input wire [11:0]  probe1 
   .probe4(spi_rq_empty),                // input wire [0:0]  probe1 
   .probe5(spi_rq_data),                 // input wire [15:0]  probe1 
   .probe6(spi_rq_ack),                  // input wire [0:0]  probe1 
   .probe7(spi_rp_cs),                   // input wire [1:0]  probe1 
   .probe8(spi_rp_adr),                  // input wire [11:0]  probe1 
   .probe9(spi_rp),                      // input wire [0:0]  probe1 
   .probe10(spi_rp_data),                // input wire [15:0]  probe1 
   .probe11(spi_started),                // input wire [0:0]  probe1 
   .probe12(spi_cs_clk),                 // input wire [0:0]  probe1 
   .probe13(spi_cs_adc),                 // input wire [0:0]  probe1 
   .probe14(spi_cs_dac),                 // input wire [0:0]  probe1 
   .probe15(spi_sdio),                   // input wire [0:0]  probe1 
   .probe16(spi_dir),                    // input wire [0:0]  probe1 
   .probe17(spi_count),                  // input wire [5:0]  probe1 
   .probe18(spi_size),                   // input wire [5:0]  probe1 
   .probe19(spi_rd_wr_n),                // input wire [0:0]  probe1 
   .probe20(spi_clk),                    // input wire [0:0]  probe1 
   .probe21(spi_z),                      // input wire [0:0]  probe1 
   .probe22(spi_out),                    // input wire [0:0]  probe1 
   .probe23(spi_cmd),                    // input wire [15:0]  probe1 
   .probe24(spi_in_data),                // input wire [15:0]  probe1 
   .probe25(spi_out_data),               // input wire [15:0]  probe1 
   .probe26(spi_rp_data),                // input wire [29:0]  probe1 
   .probe27(spi_rp_wr),                  // input wire [0:0]  probe1 
   .probe28(adc_write),                  // input wire [0:0]  probe1 
   .probe29(adc_read),                   // input wire [0:0]  probe1 
   .probe30(adc_adr),                    // input wire [11:0]  probe1 
   .probe31(adc_out_data),               // input wire [7:0]  probe1 
   .probe32(adc_in_data),                // input wire [7:0]  probe1 
   .probe33(adc_running),                // input wire [0:0]  probe1 
   .probe34(adc_done),                   // input wire [0:0]  probe1 
   .probe35(spi_delay)                   // input wire [0:0]  probe1 
);

  always @(posedge up_clk) 
  begin
    if (spi_rq_empty && !adc_read && !adc_write)
    begin
      spi_cs_clk <= 1;
      spi_cs_adc <= 1;
      spi_cs_dac <= 1;

      spi_rq_ack <= 0;
      spi_rp_wr <= 0;

      spi_size <= 16;
      spi_count <= 0;
      spi_started <= 0;
      spi_clk <= 0;
      spi_dir <= 1;
      spi_z <= 0;
      spi_out <= 0;

      adc_running <= 0;
      adc_done <= 0;
    end
    else
    begin
      if (spi_delay)
      begin
        spi_rp_wr <= 0;
        spi_rq_ack <= 0;
        
        if (spi_delay == 1)
        begin
          if (spi_clk == 0)
          begin
            if (spi_z == 0)
            begin
              if (spi_count < 16)
              begin
                spi_out <= spi_cmd[15];
                spi_cmd[15:1] <= spi_cmd[14:0];
              end
              else
              begin
                spi_out <= spi_out_data[15];
                spi_out_data[15:1] <= spi_out_data[14:0];
              end
            end
          end
        end
        spi_delay <= spi_delay - 1;        
      end
      else
      begin
        if (spi_started)
        begin
          if (spi_clk)
          begin
            if (spi_rd_wr_n)
            begin
              if (spi_count == 16)
              begin
                spi_dir <= 0;
                spi_z <= 1;
              end

              if (spi_count >= 16)
              begin
                if (adc_running)
                begin
                  adc_in_data[0] <= spi_sdio;
                  adc_in_data[7:1] <= adc_in_data[6:0];
                end
                else
                begin
                  spi_in_data[0] <= spi_sdio;
                  spi_in_data[15:1] <= spi_in_data[14:0];
                end
              end
            end
            
            spi_clk <= 0;
          end
          else
          begin
            if (spi_count >= spi_size)
            begin
              if (spi_rd_wr_n && !adc_running)
              begin
                if (spi_size == 24)
                  spi_rp_data[7:0] <= spi_in_data[7:0];
                else
                  spi_rp_data[15:0] <= spi_in_data[15:0];
                spi_rp_wr <= 1;
              end

              spi_cs_clk <= 1;
              spi_cs_adc <= 1;
              spi_cs_dac <= 1;
 
              spi_clk <= 0;
              spi_started <= 0;
              spi_out <= 0;

              if (adc_running)
                adc_done <= 1;
              else
                spi_rq_ack <= 1;
            end
            else
            begin
              spi_count <= spi_count + 1;
              spi_clk <= 1;
            end
          end
        end
        else
        begin
          if (spi_rq_empty)
          begin
            if (!adc_running)
            begin
              spi_cs_clk <= 1;
              spi_cs_adc <= 0;
              spi_cs_dac <= 1;
            
              spi_dir <= 1;
              spi_z <= 0;
              spi_rd_wr_n <= adc_read;

              spi_cmd[15] <= adc_read;
              spi_cmd[14:12] <= 0;
              spi_cmd[11:0] <= adc_adr;

              spi_size <= 24;
              spi_out_data[15:8] <= adc_out_data;

              adc_running <= 1;
              adc_done <= 0;
              spi_started <= 1;
              spi_count <= 0;
            end
          end
          else
          begin
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
            
            spi_dir <= 1;
            spi_z <= 0;
          
            spi_cmd[12] <= 0;

            if (spi_rq_cs == 0)
              spi_cmd[13] <= spi_rq_word;
            else
              spi_cmd[13] <= 0;

            spi_cmd[14] <= 0;
            spi_cmd[15] <= spi_rq_rd;

            spi_rd_wr_n <= spi_rq_rd;
  
            if (spi_rq_word)
              spi_cmd[11:0] <= spi_rq_adr + 1;
            else
              spi_cmd[11:0] <= spi_rq_adr;

            spi_rp_data[29:28] <= spi_rq_cs;
            spi_rp_data[27:16] <= spi_rq_adr;

            if (spi_rq_word)
            begin
              spi_size <= 32;
              spi_out_data[15:0] <= spi_rq_data;
            end
            else
            begin
              spi_size <= 24;
              spi_out_data[15:8] <= spi_rq_data[7:0];
              spi_rp_data[15:8] <= 0;
            end
            adc_done <= 0;
            adc_running <= 0;
            spi_started <= 1;
            spi_count <= 0;
          end
        end
        spi_delay <= 1;
      end
    end
  end
  
  assign spi_sdio = spi_z ? 1'bz : spi_out;

endmodule
