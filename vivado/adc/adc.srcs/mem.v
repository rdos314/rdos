module adc_mem (
  clk,
  reset,

  pci_rx_data,
  pci_rx_header,
  pci_rx_be,
  pci_rx_control,
  pci_rx_rd,
  pci_rx_empty,

  pci_tx_data,
  pci_tx_header,
  pci_tx_wr,
  pci_tx_full,

  adc_send,
  adc_address,
  adc_data,

  bar0_address,
  bar0_rd,
  bar0_rp,
  bar0_rp_data,
  bar0_wr,
  bar0_wr_be,
  bar0_wr_data,
  bar0_ack,

  bar1_address,
  bar1_rd,
  bar1_rp,
  bar1_rp_data,
  bar1_wr,
  bar1_wr_be,
  bar1_wr_data,
  bar1_ack,

  bar2_address,
  bar2_rd,
  bar2_rp,
  bar2_rp_data,
  bar2_wr,
  bar2_wr_be,
  bar2_wr_data,
  bar2_ack
);

  input                          clk;
  input                          reset;

  input  wire [1023:0]           pci_rx_data;
  input  wire [127:0]            pci_rx_header;
  input  wire [127:0]            pci_rx_be;
  input  wire [15:0]             pci_rx_control;
  output reg                     pci_rx_rd;
  input  wire                    pci_rx_empty;

  output reg  [1023:0]           pci_tx_data;
  output reg  [127:0]            pci_tx_header;
  output reg                     pci_tx_wr;
  input  wire                    pci_tx_full;

  input wire                     adc_send;
  input wire [63:0]              adc_address;
  input wire [1023:0]            adc_data;

  output reg  [9:0]              bar0_address;
  output reg                     bar0_rd;
  input  wire                    bar0_rp;
  input  wire [31:0]             bar0_rp_data;
  output reg                     bar0_wr;
  output reg  [3:0]              bar0_wr_be;
  output reg  [31:0]             bar0_wr_data;
  input  wire                    bar0_ack;

  output reg  [16:0]             bar1_address;
  output reg                     bar1_rd;
  input  wire                    bar1_rp;
  input  wire [31:0]             bar1_rp_data;
  output reg                     bar1_wr;
  output reg  [3:0]              bar1_wr_be;
  output reg  [31:0]             bar1_wr_data;
  input  wire                    bar1_ack;

  output reg  [16:0]             bar2_address;
  output reg                     bar2_rd;
  input  wire                    bar2_rp;
  input  wire [31:0]             bar2_rp_data;
  output reg                     bar2_wr;
  output reg  [3:0]              bar2_wr_be;
  output reg  [31:0]             bar2_wr_data;
  input  wire                    bar2_ack;


// FF

  reg              q_busy;
  reg  [18:0]      q_address;
  reg  [9:0]       q_len;
  reg  [4:0]       q_pos;

  reg              q_adc_send;
  reg  [127:0]     q_adc_header;
  reg  [1023:0]    q_adc_data;

  reg              q_local_send;
  reg  [127:0]     q_local_header;
  reg  [1023:0]    q_local_data;


// local

  reg  [18:0]      calc_address;
  reg  [9:0]       calc_len;
  reg  [4:0]       calc_pos;
  reg  [2:0]       calc_bar;

  reg  [18:0]      curr_address;
  reg  [9:0]       curr_len;

  reg              is_last_data;
  reg              is_last_reply;
  reg              has_reply;
  reg              has_ack;

  wire [9:0]       req_len = pci_rx_header[9:0];
  wire [7:0]       req_type = pci_rx_header[31:24];
  wire [63:0]      req_address = pci_rx_header[95:64];
  wire [7:0]       req_bar = pci_rx_control[15:8];

ila_1 ila_1_inst (
  .clk(clk),                              // input wire clk
  .probe0(pci_rx_empty),                  // input wire [0:0]  probe1 
  .probe1(pci_tx_full),                   // input wire [0:0]  probe1 
  .probe2(req_address),                   // input wire [63:0]  probe1 
  .probe3(req_len),                       // input wire [9:0]  probe1 
  .probe4(pci_rx_header[63:0]),           // input wire [63:0]  probe1 
  .probe5(pci_rx_header[127:64]),         // input wire [63:0]  probe1 
  .probe6(pci_rx_be[31:0]),               // input wire [31:0]  probe1 
  .probe7(pci_rx_control),                // input wire [15:0]  probe1 
  .probe8(pci_tx_header[63:0]),           // input wire [63:0]  probe1 
  .probe9(pci_tx_header[127:64]),         // input wire [63:0]  probe1 
  .probe10(pci_tx_data[31:0]),            // input wire [31:0]  probe2
  .probe11(adc_send),                     // input wire [0:0]  probe2
  .probe12(adc_address),                  // input wire [63:0]  probe2
  .probe13(q_local_send),                 // input wire [0:0]  probe2
  .probe14(q_local_header[63:0]),         // input wire [63:0]  probe2
  .probe15(q_local_header[127:64]),       // input wire [63:0]  probe2
  .probe16(q_adc_send),                   // input wire [0:0]  probe2
  .probe17(q_adc_header[63:0]),           // input wire [63:0]  probe2
  .probe18(q_adc_header[127:64])          // input wire [63:0]  probe2
);

function [2:0] decode_bar;
  input [7:0] bar;
  reg [2:0] res;
  begin
    res = 7;

    if (bar[0])
      res = 0;

    if (bar[1])
      res = 1;

    if (bar[2])
      res = 2;

    decode_bar = res;
  end
endfunction

generate
  begin : mem

    always @ ( * ) 
    begin
      if (reset || pci_rx_empty)
      begin
        pci_rx_rd = 0;
      end
      else
      begin 
        case (req_type)
          8'b000_00000, 
          8'b001_00000,
          8'b000_00001,
          8'b001_00001: 
          begin  // read
            if (q_busy)
            begin
              curr_address = q_address;
              curr_len = q_len;
            end
            else
            begin
              curr_address = req_address[18:0];
              curr_len = req_len;
            end

            case (decode_bar(req_bar))
              0: 
              begin
                if (bar0_rp)            
                begin
                  if (curr_len <= 1)
                    pci_rx_rd = 1;
                  else
                    pci_rx_rd = 0;
                end
                else
                  pci_rx_rd = 0;
              end

              1:
              begin
                if (bar1_rp)            
                begin
                  if (curr_len <= 1)
                    pci_rx_rd = 1;
                  else
                    pci_rx_rd = 0;
                end
                else
                  pci_rx_rd = 0;
              end

              2:
              begin
                if (bar2_rp)            
                begin
                  if (curr_len <= 1)
                    pci_rx_rd = 1;
                  else
                    pci_rx_rd = 0;
                end
                else
                  pci_rx_rd = 0;
              end

              default:
              begin
                pci_rx_rd = 1;
              end
            endcase
          end

          8'b010_00000,
          8'b011_00000:
          begin // write
            if (q_busy)
            begin
              curr_address = q_address;
              curr_len = q_len;
            end
            else
            begin
              curr_address = req_address[18:0];
              curr_len = req_len;
            end

            case (decode_bar(req_bar))
              0: 
              begin
                if (bar0_ack)            
                begin
                  if (curr_len <= 1)
                    pci_rx_rd = 1;
                  else
                    pci_rx_rd = 0;
                end
                else
                  pci_rx_rd = 0;
              end

              1:
              begin
                if (bar1_ack)            
                begin
                  if (curr_len <= 1)
                    pci_rx_rd = 1;
                  else
                    pci_rx_rd = 0;
                end
                else
                  pci_rx_rd = 0;
              end

              2:
              begin
                if (bar2_ack)            
                begin
                  if (curr_len <= 1)
                    pci_rx_rd = 1;
                  else
                    pci_rx_rd = 0;
                end
                else
                  pci_rx_rd = 0;
              end

              default:
              begin
                pci_rx_rd = 1;
              end
            endcase
          end

          default:
          begin  // not supported
            pci_rx_rd = 1;
          end
        endcase
      end
    end

    always @ ( posedge clk ) 
    begin
      calc_address = 0;
      calc_len = 0;
      calc_pos = 0;

      has_reply = 0;
      has_ack = 0;
      is_last_reply = 0;
      is_last_data = 0;

      if (!pci_rx_empty)
      begin
        if (q_busy)
        begin
          calc_address = q_address;
          calc_len = q_len;
          calc_pos = q_pos;

          if (q_len <= 1)
            is_last_data = 1;
        end
        else
        begin
          calc_address = req_address[18:0];
          calc_len = req_len;
          calc_pos = 0;

          if (req_len <= 1)
            is_last_data = 1;
        end

        calc_bar = decode_bar(req_bar);
        case (calc_bar)
          0:
          begin
            has_reply = bar0_rp;
            has_ack = bar0_ack;
          end
 
          1:
          begin
            has_reply = bar1_rp;
            has_ack = bar1_ack;
          end
 
          2:
          begin
            has_reply = bar2_rp;
            has_ack = bar2_ack;
          end
        endcase

        if (has_reply && is_last_data)            
          is_last_reply = 1;
      end

      if (reset || pci_tx_full)
         pci_tx_wr <= 0;
      else
      begin
        if (q_adc_send)
        begin
          pci_tx_data <= q_adc_data;
          pci_tx_header <= q_adc_header;
          pci_tx_wr <= 1;
          q_adc_send <= 0;
        end
        else
        begin
          if (q_local_send)
          begin
            pci_tx_data <= q_local_data;
            pci_tx_header <= q_local_header;
            pci_tx_wr <= 1;
            q_local_send <= 0;
          end
          else
            pci_tx_wr <= 0;
        end
      end

      if (adc_send)
      begin
        q_adc_data <= adc_data;

        q_adc_header[63:48] <= 0;                      // Requester ID
        q_adc_header[47:40] <= 0;                      // tag
        q_adc_header[39:36] <= 4'b1111;                // last be
        q_adc_header[35:32] <= 4'b1111;                // 1st be

        if (adc_address[63:32] == 0)
        begin
          q_adc_header[31:24] <= 8'b010_00000;         // Type + Fmt (32-bit)
          q_adc_header[95:64] <= adc_address[31:0];
        end
        else
        begin
          q_adc_header[31:24] <= 8'b011_00000;         // Type + Fmt (64-bit)
          q_adc_header[95:64] <= adc_address[63:32];
          q_adc_header[127:96] <= adc_address[31:0];
        end

        q_adc_header[23] <= 1'b0;                      // R
        q_adc_header[22:20] <= 3'b000;                 // TC
        q_adc_header[19:16] <= 4'b0000;                // TH, AttrH, R
        q_adc_header[15:12] <= 4'b0000;                // TD, EP, Attr
        q_adc_header[11:10] <= 2'b0;                   // AT
        q_adc_header[9:8] <= 2'b0;                     // len high
        q_adc_header[7:0] <= 8'h20;                    // 128 byte size
        q_adc_send <= 1;
      end

      if (reset || pci_rx_empty)
      begin
        q_busy <= 0;
        q_local_send <= 0;
      end
      else
      begin
        case (req_type)
          8'b000_00000, 
          8'b001_00000,
          8'b000_00001,
          8'b001_00001: 
          begin  // read
            if (has_reply)
            begin
              if (q_busy)
              begin
                if (q_len)
                begin
                  q_address <= q_address + 4;
                  q_len <= q_len - 1;
                  q_pos <= q_pos + 1;
                end
              end
              else
              begin
                if (req_len)
                begin
                  q_address <= req_address[18:0] + 4;
                  q_len <= req_len - 1;
                  q_pos <= 1;
                end
              end
              
              case (calc_bar)
                0: q_local_data[32 * calc_pos +: 32] <= bar0_rp_data;
                1: q_local_data[32 * calc_pos +: 32] <= bar1_rp_data;
                2: q_local_data[32 * calc_pos +: 32] <= bar2_rp_data;
              endcase

              if (is_last_reply && !q_local_send)
              begin
                q_local_header[95:72] <= pci_rx_header[63:40];
                q_local_header[71] <= 0;
                q_local_header[70:66] <= pci_rx_header[70:66];
                casex (pci_rx_be[3:0])
                  4'b0000 : q_local_header[65:64] <= 0;
                  4'bxxx1 : q_local_header[65:64] <= 0;
                  4'bxx10 : q_local_header[65:64] <= 1;
                  4'bx100 : q_local_header[65:64] <= 2;
                  4'b1000 : q_local_header[65:64] <= 3;
                endcase

                q_local_header[63:48] <= 16'b0;                  // completer ID
                q_local_header[47:45] <= 3'b0;                   // completion code = 000
                q_local_header[44] <= 1'b0;                      // BCM
                q_local_header[39:32] <= pci_rx_control[7:0];    // byte count
                q_local_header[43:40] <= 0;                      // high byte count = 0

                if (req_len)
                  q_local_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
                else
                  q_local_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

                q_local_header[24] <= pci_rx_header[24];
                q_local_header[23] <= 1'b0;                      // R
                q_local_header[22:20] <= pci_rx_header[22:20];
                q_local_header[19:16] <= 4'b0;                   // TH, AttrH, R
                q_local_header[15:12] <= pci_rx_header[15:12];
                q_local_header[11:10] <= 2'b0;                   // AT
                q_local_header[9:0] <= pci_rx_header[9:0];
                q_busy <= 0;
                q_local_send <= 1;
              end
              else
                q_busy <= 1;
            end
            else
            begin
              if (!q_busy)
              begin
                q_address <= req_address[18:0];
                q_len <= req_len;
                q_pos <= 0;
                q_busy <= 1;
              end
            end
          end


          8'b010_00000,
          8'b011_00000:
          begin
            if (has_ack)
            begin
              if (q_busy)
              begin
                if (q_len)
                begin
                  q_address <= q_address + 4;
                  q_len <= q_len - 1;
                  q_pos <= q_pos + 1;
                end
              end
              else
              begin
                if (req_len)
                begin
                  q_address <= req_address[18:0] + 4;
                  q_len <= req_len - 1;
                  q_pos <= 1;
                end
              end

              if (is_last_data)
                q_busy <= 0;
              else
                q_busy <= 1;
            end
            else
            begin
              if (!q_busy)
              begin
                q_address <= req_address[18:0];
                q_len <= req_len;
                q_pos <= 0;
                q_busy <= 1;
              end
            end
          end

          default:
          begin  // not supported
            q_busy <= 0;
          end
        endcase
      end

      if (reset || pci_rx_empty)
      begin
        bar0_rd <= 0;
        bar1_rd <= 0;
        bar2_rd <= 0;
        bar0_wr <= 0;
        bar1_wr <= 0;
        bar2_wr <= 0;
      end
      else
      begin
        case (req_type)
          8'b000_00000, 
          8'b001_00000,
          8'b000_00001,
          8'b001_00001: 
          begin  // read
            bar0_wr <= 0;
            bar1_wr <= 0;
            bar2_wr <= 0;

            if (calc_len)
            begin
              case (calc_bar)
                0:
                begin
                  bar0_address <= calc_address[11:2];
                  bar0_rd <= 1;
                  bar1_rd <= 0;
                  bar2_rd <= 0;
                end

                1:
                begin
                  bar1_address <= calc_address[18:2];
                  bar0_rd <= 0;
                  bar1_rd <= 1;
                  bar2_rd <= 0;
                end

                2:
                begin
                  bar2_address <= calc_address[18:2];
                  bar0_rd <= 0;
                  bar1_rd <= 0;
                  bar2_rd <= 1;
                end

                default:
                begin
                  bar0_rd <= 0;
                  bar1_rd <= 0;
                  bar2_rd <= 0;
                end
              endcase
            end             
          end

          8'b010_00000,
          8'b011_00000:
          begin  // write
            bar0_rd <= 0;
            bar1_rd <= 0;
            bar2_rd <= 0;

            if (calc_len)
            begin
              case (calc_bar)
                0:
                begin
                  bar0_address <= calc_address[11:2];
                  bar0_wr_be <= pci_rx_be[4 * calc_pos +: 4];
                  bar0_wr_data <= pci_rx_data[32 * calc_pos +: 32];
                  bar0_wr <= 1;
                  bar1_wr <= 0;
                  bar2_wr <= 0;
                end

                1:
                begin
                  bar1_address <= calc_address[18:2];
                  bar1_wr_be <= pci_rx_be[4 * calc_pos +: 4];
                  bar1_wr_data <= pci_rx_data[32 * calc_pos +: 32];
                  bar0_wr <= 0;
                  bar1_wr <= 1;
                  bar2_wr <= 0;
                end

                2:
                begin
                  bar2_address <= calc_address[18:2];
                  bar2_wr_be <= pci_rx_be[4 * calc_pos +: 4];
                  bar2_wr_data <= pci_rx_data[32 * calc_pos +: 32];
                  bar0_wr <= 0;
                  bar1_wr <= 0;
                  bar2_wr <= 1;
                end

                default:
                begin
                  bar0_wr <= 0;
                  bar1_wr <= 0;
                  bar2_wr <= 0;
                end
              endcase
            end
            else
            begin
              bar0_wr <= 0;
              bar1_wr <= 0;
              bar2_wr <= 0;
            end
          end

          default:
          begin  // not supported
            bar0_rd <= 0;
            bar1_rd <= 0;
            bar2_rd <= 0;
            bar0_wr <= 0;
            bar1_wr <= 0;
            bar2_wr <= 0;
          end
        endcase
      end
    end

  end
endgenerate

endmodule
