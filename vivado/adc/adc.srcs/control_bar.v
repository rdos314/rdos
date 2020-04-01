module control_bar (
  input                   up_reset,
  input                   up_clk,

  input [9:0]             rd_address,
  input                   rd,

  output reg [31:0]       rp_data,
  output                  rp,

  input [9:0]             wr_address,
  input [31:0]            wr_data,
  input [3:0]             wr_be,
  input                   wr,

  output reg              spi_rq,
  output reg [31:0]       spi_rq_data,

  input wire              spi_rp,
  input wire [29:0]       spi_rp_data,
  output reg              spi_rp_ack,

  input [63:0]            adc_address,
  input [127:0]           adc_sysref_cnt,
  input [31:0]            adc_sync_fail_cnt,
  input [31:0]            adc_sync_ok_cnt,

  input                   adc_started,
  input                   adc_probing,
  input                   adc_running,

  output reg              adc_start,
  output reg              adc_stop,
  output reg [7:0]        adc_test_mode,

  output reg [7:0]        state
);

// internal

  reg                     spi_clk_valid;
  reg                     spi_adc_valid;
  reg                     spi_dac_valid;

  reg [31:0]              bar_spi_clk;
  reg [31:0]              bar_spi_adc;
  reg [31:0]              bar_spi_dac;

generate
  begin : ctrl_bar_gen

    always @ ( posedge user_clk ) 
    begin
      if (user_reset)
      begin
        state <= 0;
        adc_test_mode <= 7;
        adc_start <= 0;
        adc_stop <= 0;

        spi_clk_valid <= 0;
        spi_adc_valid <= 0;
        spi_dac_valid <= 0;

        rp <= 0;
      end
      else
      begin
        if (adc_started)
        begin
          if (adc_probing)
          begin
            state[7] <= 1;

            if (adc_running)
              state[6] <= 1;
            else
              state[6] <= 0;
          end
          else
          begin
            state[6] <= 1;
            state[7] <= 0;
          end
        end
        else
        begin
          state[6] <= 0;
          state[7] <= 0;
        end

        if (rd)
        begin
          case (rd_address)
            0: rp_data <= {16'h0, adc_test_mode, state};
            1: rp_data <= bar_spi_clk;
            2: rp_data <= bar_spi_adc;
            3: rp_data <= bar_spi_dac;
            4: rp_data <= adc_sysref_cnt[31:0];
            5: rp_data <= adc_sysref_cnt[63:32];
            6: rp_data <= adc_sync_fail_cnt;
            7: rp_data <= adc_sync_ok_cnt;
            default: rp_data <= 32'hffffffff;
          endcase     
          rp <= 1;
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
                  state[6:2] <= wr_data[6:2];
                  if (state[7] != wr_data[7])
                  begin
                    if (wr_data[7])
                    begin
                      if (adc_address != 0)
                        adc_start <= 1;
                    end 
                    else
                      adc_stop <= 1;
                  end      
                end

                if (wr_be[1])
                  adc_test_mode[7:0] <= wr_data[15:8]; 
              end
            
              1:
              begin
                if (wr_be[0])
                  bar_spi_clk[7:0] <= wr_data[7:0];
 
                if (wr_be[1])
                  bar_spi_clk[15:8] <= wr_data[15:8];
 
                if (wr_be[2])
                  bar_spi_clk[23:16] <= wr_data[23:16];

                if (bar0_wr_be[3])
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

                adc_start <= 0;
                adc_stop <= 0;

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

                adc_start <= 0;
                adc_stop <= 0;

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

                adc_start <= 0;
                adc_stop <= 0;

                spi_clk_valid <= 0;
                spi_adc_valid <= 0;
              end
            
              default:
              begin
                adc_start <= 0;
                adc_stop <= 0;

                spi_clk_valid <= 0;
                spi_adc_valid <= 0;
                spi_dac_valid <= 0;
              end
            endcase
          end
          else
          begin
            adc_start <= 0;
            adc_stop <= 0;

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


    always @ ( posedge user_clk ) 
    begin
      if (spi_clk_valid)
      begin
        spi_rq_data[23:0] <= bar0_spi_clk[23:0];
        spi_rq_data[30:29] <= 0;

        case (bar0_spi_clk[31:28])
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
          spi_rq_data[23:0] <= bar_spi_adc[23:0];
          spi_rq_data[30:29] <= 1;

          case (bar0_spi_adc[31:28])
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
            spi_rq_data[23:0] <= bar_spi_dac[23:0];
            spi_rq_data[30:29] <= 2;

            case (bar0_spi_dac[31:28])
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

  end
endgenerate

endmodule
