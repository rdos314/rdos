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
// control_bar.v
// Bar 0 (control) module
//
////////////////////////////////////////////////////////////////////////////////

module control_bar (
  input                   reset,
  input                   clk,

  output reg [31:0]       control_base,

  input [9:0]             rd_address,
  input                   rd,

  output reg [31:0]       rp_data,
  output reg              rp,

  input [9:0]             wr_address,
  input [31:0]            wr_data,
  input [3:0]             wr_be,
  input                   wr,

  output reg              spi_rq,
  output reg [31:0]       spi_rq_data,

  input wire              spi_rp,
  input wire [29:0]       spi_rp_data,
  output reg              spi_rp_ack,

  input wire              rx_control_msg,
  input wire [7:0]        rx_control_index,
  input wire [7:0]        rx_control_data
);

// internal

  reg                     spi_clk_valid;
  reg                     spi_adc_valid;
  reg                     spi_dac_valid;

  reg [31:0]              bar_spi_clk;
  reg [31:0]              bar_spi_adc;
  reg [31:0]              bar_spi_dac;

  reg [1:0]               adc_state;
  reg [7:0]               adc_progr_state;

generate
  begin : ctrl_bar_gen

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        control_base <= 0;
        adc_state <= 0;

        bar_spi_clk <= 0;
        bar_spi_adc <= 0;
        bar_spi_dac <= 0;

        spi_clk_valid <= 0;
        spi_adc_valid <= 0;
        spi_dac_valid <= 0;

        rp <= 0;
      end
      else
      begin
        if (rd)
        begin
          case (rd_address)
            0: rp_data <= {16'hffff, adc_progr_state, 6'b000000, adc_state};
            1: rp_data <= bar_spi_clk;
            2: rp_data <= bar_spi_adc;
            3: rp_data <= bar_spi_dac;
            default: rp_data <= 32'hffffffff;
          endcase     

          rp <= 1;

          spi_clk_valid <= 0;
          spi_adc_valid <= 0;
          spi_dac_valid <= 0;
        end
        else
        begin
          rp <= 0;

          if (wr)
          begin
            case (wr_address)
              0: 
              begin
                spi_clk_valid <= 0;
                spi_adc_valid <= 0;
                spi_dac_valid <= 0;
              end
            
              1:
              begin
                if (wr_be[0])
                  bar_spi_clk[7:0] <= wr_data[7:0];
 
                if (wr_be[1])
                  bar_spi_clk[15:8] <= wr_data[15:8];
 
                if (wr_be[2])
                  bar_spi_clk[23:16] <= wr_data[23:16];

                if (wr_be[3])
                begin
                  bar_spi_clk[27:24] <= wr_data[27:24];

                  case (wr_data[31:28])
                    12:      
                    begin
                      bar_spi_clk[31:28] <= 15;
                      spi_clk_valid <= 1;
                    end

                    1, 2:    
                    begin
                      bar_spi_clk[31:28] <= 0;
                      spi_clk_valid <= 1;
                    end

                    default: 
                    begin
                      bar_spi_clk[31:28] <= 0;
                      spi_clk_valid <= 0;
                    end                    
                  endcase
                end
                else
                  spi_clk_valid <= 0;

                spi_adc_valid <= 0;
                spi_dac_valid <= 0;
              end

              2:
              begin
                if (wr_be[0])
                  bar_spi_adc[7:0] <= wr_data[7:0];
 
                if (wr_be[1])
                  bar_spi_adc[15:8] <= wr_data[15:8];
 
                if (wr_be[2])
                  bar_spi_adc[23:16] <= wr_data[23:16];

                if (wr_be[3])
                begin
                  bar_spi_adc[27:24] <= wr_data[27:24];

                  case (wr_data[31:28])
                    12:      
                    begin
                      bar_spi_adc[31:28] <= 15;
                      spi_adc_valid <= 1;
                    end

                    1, 2:    
                    begin
                      bar_spi_adc[31:28] <= 0;
                      spi_adc_valid <= 1;
                    end

                    default: 
                    begin
                      bar_spi_adc[31:28] <= 0;
                      spi_adc_valid <= 0;
                    end
                  endcase
                end
                else
                  spi_adc_valid <= 0;

                spi_clk_valid <= 0;
                spi_dac_valid <= 0;
              end

              3:
              begin
                if (wr_be[0])
                  bar_spi_dac[7:0] <= wr_data[7:0];
 
                if (wr_be[1])
                  bar_spi_dac[15:8] <= wr_data[15:8];
 
                if (wr_be[2])
                  bar_spi_dac[23:16] <= wr_data[23:16];

                if (wr_be[3])
                begin
                  bar_spi_dac[27:24] <= wr_data[27:24];

                  case (wr_data[31:28])
                    12:      
                    begin
                      bar_spi_dac[31:28] <= 15;
                      spi_dac_valid <= 1;
                    end

                    1, 2:    
                    begin
                      bar_spi_dac[31:28] <= 0;
                      spi_dac_valid <= 1;
                    end

                    default: 
                    begin
                      bar_spi_dac[31:28] <= 0;
                      spi_dac_valid <= 0;
                    end
                  endcase
                end
                else
                  spi_dac_valid <= 0;

                spi_clk_valid <= 0;
                spi_adc_valid <= 0;
              end

            endcase
          end
          else
          begin
            spi_clk_valid <= 0;
            spi_adc_valid <= 0;
            spi_dac_valid <= 0;

            if (spi_rp)
            begin
              spi_rp_ack <= 1;

              case (spi_rp_data[29:28])
                0:
                begin
                  if (bar_spi_clk[31:28] == 15)
                  begin
                    if (bar_spi_clk[27:16] == spi_rp_data[27:16])
                    begin
                      bar_spi_clk[15:0] <= spi_rp_data[15:0];
                      bar_spi_clk[31:28] <= 0;
                    end
                  end
                end
  
                1:
                begin
                  if (bar_spi_adc[31:28] == 15)
                  begin
                    if (bar_spi_adc[27:16] == spi_rp_data[27:16])
                    begin
                      bar_spi_adc[15:0] <= spi_rp_data[15:0];
                      bar_spi_adc[31:28] <= 0;
                    end
                  end
                end

                2:
                begin
                  if (bar_spi_dac[31:28] == 15)
                  begin
                    if (bar_spi_dac[27:16] == spi_rp_data[27:16])
                    begin
                      bar_spi_dac[15:0] <= spi_rp_data[15:0];
                      bar_spi_dac[31:28] <= 0;
                    end
                  end
                end
              endcase
            end
            else
              spi_rp_ack <= 0;
          end
        end
      end
    end


    always @ ( posedge clk ) 
    begin
      if (spi_clk_valid)
      begin
        spi_rq_data[27:0] <= bar_spi_clk[27:0];
        spi_rq_data[30:29] <= 0;

        case (wr_data[31:28])
          12:
          begin
            spi_rq_data[31] <= 1;
            spi_rq_data[28] <= 1;
            spi_rq <= 1;
          end

          2:
          begin
            spi_rq_data[31] <= 0;
            spi_rq_data[28] <= 1;
            spi_rq <= 1;
          end

          1:
          begin
            spi_rq_data[31] <= 0;
            spi_rq_data[28] <= 0;
            spi_rq <= 1;
          end

          default:
          begin
            spi_rq <= 0;
          end
        endcase
      end
      else
      begin
        if (spi_adc_valid)
        begin
          spi_rq_data[27:0] <= bar_spi_adc[27:0];
          spi_rq_data[30:29] <= 1;

          case (wr_data[31:28])
            12:
            begin
              spi_rq_data[31] <= 1;
              spi_rq_data[28] <= 1;
              spi_rq <= 1;
            end

            2:
            begin
              spi_rq_data[31] <= 0;
              spi_rq_data[28] <= 1;
              spi_rq <= 1;
            end

            1:
            begin
              spi_rq_data[31] <= 0;
              spi_rq_data[28] <= 0;
              spi_rq <= 1;
            end

            default:
            begin
              spi_rq <= 0;
            end
          endcase
        end
        else
        begin
          if (spi_dac_valid)
          begin
            spi_rq_data[27:0] <= bar_spi_dac[27:0];
            spi_rq_data[30:29] <= 2;

            case (wr_data[31:28])
              12:
              begin
                spi_rq_data[31] <= 1;
                spi_rq_data[28] <= 1;
                spi_rq <= 1;
              end

              2:
              begin
                spi_rq_data[31] <= 0;
                spi_rq_data[28] <= 1;
                spi_rq <= 1;
              end

              1:
              begin
                spi_rq_data[31] <= 0;
                spi_rq_data[28] <= 0;
                spi_rq <= 1;
              end

              default:
              begin
                spi_rq <= 0;
              end
            endcase
          end
          else
            spi_rq <= 0;
        end
      end
    end


    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        adc_state <= 0;
        adc_progr_state <= 0;
      end
      else
      begin
        if (rx_control_msg)
        begin
          case (rx_control_index)
            0:  adc_state <= rx_control_data[1:0];
            1:  adc_progr_state <= rx_control_data;
          endcase
        end
      end
    end  

  end
endgenerate

endmodule
