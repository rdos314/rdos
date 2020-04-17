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

  input [127:0]           adc_sysref_cnt,
  input [15:0]            adc_phys_index,

  input wire              rx_control_msg,
  input wire [7:0]        rx_control_index,
  input wire [7:0]        rx_control_data,

  output reg              tx_control_msg,
  output reg [7:0]        tx_control_index,
  output reg [7:0]        tx_control_data
);

// internal

  reg                     spi_clk_valid;
  reg                     spi_adc_valid;
  reg                     spi_dac_valid;

  reg [31:0]              bar_spi_clk;
  reg [31:0]              bar_spi_adc;
  reg [31:0]              bar_spi_dac;

  reg                     req_send_adc_state;
  reg                     ack_send_adc_state;
  reg [7:0]               adc_state;
  reg [1:0]               adc_req_state;
  reg [7:0]               adc_irq_state;
  reg [7:0]               adc_irq_clear;
  reg                     adc_irq_ack;

  reg                     req_send_adc_test_mode;
  reg                     ack_send_adc_test_mode;
  reg [7:0]               adc_test_mode;

  reg [1:0]               tx_control_delay;


generate
  begin : ctrl_bar_gen

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        adc_irq_clear <= 0;
        adc_state[5:0] <= 0;
        adc_req_state <= 0;
        adc_test_mode <= 0;
        req_send_adc_state <= 0;
        req_send_adc_test_mode <= 0;

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
            0: rp_data <= {24'hffffff, adc_state};
            1: rp_data <= bar_spi_clk;
            2: rp_data <= bar_spi_adc;
            3: rp_data <= bar_spi_dac;
            4: rp_data <= {adc_phys_index, adc_test_mode, adc_irq_state};
            5: rp_data <= adc_sysref_cnt[31:0];
            6: rp_data <= adc_sysref_cnt[63:32];
            7: rp_data <= adc_sysref_cnt[95:64];
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
                if (wr_be[0])
                begin
                  adc_state[5:0] <= wr_data[5:0];
                  adc_req_state[1:0] <= wr_data[7:6];
                  req_send_adc_state <= 1;
                end

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

              4:
              begin
                if (wr_be[0])
                  adc_irq_clear <= adc_irq_clear | wr_be[0];

                if (wr_be[1])
                begin
                  adc_test_mode[7:0] <= wr_data[15:8]; 
                  if (adc_test_mode[7:0] != wr_data[15:8])
                    req_send_adc_test_mode <= 1;
                end

                spi_clk_valid <= 0;
                spi_adc_valid <= 0;
                spi_dac_valid <= 0;
              end
            
              default:
              begin
                spi_clk_valid <= 0;
                spi_adc_valid <= 0;
                spi_dac_valid <= 0;
              end
            endcase
          end
          else
          begin
            if (adc_irq_ack)
              adc_irq_clear <= 0;

            if (ack_send_adc_state)
              req_send_adc_state <= 0;
          
            if (ack_send_adc_test_mode)
              req_send_adc_test_mode <= 0;

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
        tx_control_msg <= 0;
        tx_control_delay <= 0;
        tx_control_data <= 0;
        ack_send_adc_state <= 0;
        ack_send_adc_test_mode <= 0;
      end
      else
      begin
        if (tx_control_delay)
          tx_control_delay <= tx_control_delay - 1;
        else
        begin        
          if (req_send_adc_state)
          begin
            if (ack_send_adc_state)
            begin
              ack_send_adc_state <= 0;
              tx_control_msg <= 0;
            end
            else
            begin
              tx_control_index <= 0;
              tx_control_data <= adc_req_state;
              tx_control_msg <= 1;
              tx_control_delay <= 3;
              ack_send_adc_state <= 1;
            end
          end
          else
          begin
            ack_send_adc_state <= 0;

            if (req_send_adc_test_mode)
            begin
              if (ack_send_adc_test_mode)
              begin
                ack_send_adc_test_mode <= 0;
                tx_control_msg <= 0;
              end
              else
              begin
                tx_control_index <= 1;
                tx_control_data <= adc_test_mode;
                tx_control_msg <= 1;
                tx_control_delay <= 3;
                ack_send_adc_test_mode <= 1;
              end
            end            
            else
            begin
              ack_send_adc_test_mode <= 0;
              tx_control_msg <= 0;
            end
          end
        end
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        adc_state[7:6] <= 0;
        adc_irq_state <= 0;
        adc_irq_ack <= 1;
      end
      else
      begin
        if (rx_control_msg)
        begin
          adc_irq__ack <= 0;

          case (rx_control_index)
            0: 
            if (rx_control_data[0])
            begin
              if (rx_control_data[1])
              begin
                adc_state[7] <= 1;
                if (rx_control_data[2])
                  adc_state[6] <= 1;
                else
                  adc_state[6] <= 0;
              end
              else
              begin
                adc_state[6] <= 1;
                adc_state[7] <= 0;
              end
            end
            else
            begin
              adc_state[6] <= 0;
              adc_state[7] <= 0;
            end

            1: 
            begin
              case (rx_control_data[3:0])
                0: adc_irq_state[0] <= 1;
                1: adc_irq_state[1] <= 1;
                2: adc_irq_state[2] <= 1;
                3: adc_irq_state[3] <= 1;
                4: adc_irq_state[4] <= 1;
                5: adc_irq_state[5] <= 1;
                6: adc_irq_state[6] <= 1;
                7: adc_irq_state[7] <= 1;
              endcase
            end
          endcase
        end
        else
        begin
          adc_irq_ack <= 1;
          adc_irq_state <= adc_irq_state & (~adc_irq_clear);
        end
      end
    end  


  end
endgenerate

endmodule
