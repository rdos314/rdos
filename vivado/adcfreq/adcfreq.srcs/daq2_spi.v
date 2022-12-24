////////////////////////////////////////////////////////////////////////////////
// RDOS operating system
// Copyright (C) 1988-2020, Leif Ekblad
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version. The only exception to this rule
// is for commercial usage in embedded systems. For information on
// usage in commercial embedded systems, contact embedded@rdos.net
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// The author of this program may be contacted at leif@rdos.net
//
// daq2_spi.v
// SPI interface for DAQ2
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module daq2_spi (
  input                   reset,
  input                   clk,
  input                   pci_clk,

  input                   spi_rq,
  input [31:0]            spi_rq_data,

  output wire             spi_rp,
  output wire [29:0]      spi_rp_data,
  input                   spi_rp_ack,

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


// FIFO

  reg                     spi_rq_ack;
  wire                    spi_rq_empty;

  wire [31:0]             spi_rq_out;
  wire                    spi_rq_rd;
  wire [1:0]              spi_rq_cs;
  wire                    spi_rq_word;
  wire [11:0]             spi_rq_adr;
  wire [15:0]             spi_rq_data_out;

  reg [29:0]              spi_rp_data_in;
  reg                     spi_rp_wr;
  wire                    spi_rp_empty;


spi_fifo_rq spi_fifo_rq_inst (
  .rst(reset),                 // input wire rst
  .wr_clk(pci_clk),            // input wire wr_clk
  .rd_clk(clk),                // input wire rd_clk
  .din(spi_rq_data),           // input wire [31 : 0] din
  .wr_en(spi_rq),              // input wire wr_en
  .rd_en(spi_rq_ack),          // input wire rd_en
  .dout(spi_rq_out),           // output wire [31 : 0] dout
  .full(),                     // output wire full
  .empty(spi_rq_empty)         // output wire empty
);


spi_fifo_rp spi_fifo_rp_inst (
  .rst(reset),                 // input wire rst
  .wr_clk(clk),                // input wire wr_clk
  .rd_clk(pci_clk),            // input wire rd_clk
  .din(spi_rp_data_in),        // input wire [29 : 0] din
  .wr_en(spi_rp_wr),           // input wire wr_en
  .rd_en(spi_rp_ack),          // input wire rd_en
  .dout(spi_rp_data),          // output wire [29 : 0] dout
  .full(),                     // output wire full
  .empty(spi_rp_empty)         // output wire empty
);

  assign spi_rq_rd = spi_rq_out[31];
  assign spi_rq_cs = spi_rq_out[30:29];
  assign spi_rq_word = spi_rq_out[28];
  assign spi_rq_adr = spi_rq_out[27:16];
  assign spi_rq_data_out = spi_rq_out[15:0];

  assign spi_rp = !spi_rp_empty;

  always @(posedge clk) 
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
        spi_rq_ack <= 0;
        spi_rp_wr <= 0;
        
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
                  spi_rp_data_in[7:0] <= spi_in_data[7:0];
                else
                  spi_rp_data_in[15:0] <= spi_in_data[15:0];
                spi_rp_wr <= 1;
              end

              spi_cs_clk <= 1;
              spi_cs_adc <= 1;
              spi_cs_dac <= 1;
 
              spi_clk <= 0;
              spi_started <= 0;
              spi_out <= 0;
              spi_rq_ack <= 1;

              if (adc_running)
                adc_done <= 1;
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

            spi_rp_data_in[29:28] <= spi_rq_cs;
            spi_rp_data_in[27:16] <= spi_rq_adr;

            if (spi_rq_word)
            begin
              spi_size <= 32;
              spi_out_data[15:0] <= spi_rq_data_out;
            end
            else
            begin
              spi_size <= 24;
              spi_out_data[15:8] <= spi_rq_data_out[7:0];
              spi_rp_data_in[15:8] <= 0;
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
