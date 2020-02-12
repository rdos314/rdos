module adc_mem (
  clk,
  reset,

  pci_rx_data,
  pci_rx_header,
  pci_rx_be,
  pci_rx_rd,
  pci_rx_empty,

  pci_tx_data,
  pci_tx_header,
  pci_tx_wr,
  pci_tx_full,

  sdram_address,

  sdram_rd,
  sdram_rp,
  sdram_rp_address,
  sdram_rp_data,

  sdram_wr,
  sdram_wr_be,
  sdram_wr_data,

  local_address,

  local_rd,
  local_rp,
  local_rp_address,
  local_rp_data,

  local_wr,
  local_wr_be,
  local_wr_data
);

  input                          clk;
  input                          reset;

  input  wire [1023:0]           pci_rx_data;
  input  wire [191:0]            pci_rx_header;
  input  wire [127:0]            pci_rx_be;
  output reg                     pci_rx_rd;
  input  wire                    pci_rx_empty;

  output reg  [1023:0]           pci_tx_data;
  output reg  [191:0]            pci_tx_header;
  output reg                     pci_tx_wr;
  input  wire                    pci_tx_full;

  output reg  [15:0]             sdram_address;

  output reg                     sdram_rd;
  input  wire                    sdram_rp;
  input  wire [3:0]              sdram_rp_address;
  input  wire [63:0]             sdram_rp_data;

  output reg                     sdram_wr;
  output reg  [7:0]              sdram_wr_be;
  output reg  [63:0]             sdram_wr_data;

  output reg  [4:0]              local_address;

  output reg                     local_rd;
  input  wire                    local_rp;
  input  wire [4:0]              local_rp_address;
  input  wire [31:0]             local_rp_data;

  output reg                     local_wr;
  output reg  [3:0]              local_wr_be;
  output reg  [31:0]             local_wr_data;


// FF

  reg              q_busy;
  reg  [18:0]      q_address;
  reg  [9:0]       q_len;
  reg  [4:0]       q_pos;


// local

  reg  [18:0]      calc_address;
  reg  [9:0]       calc_len;
  reg  [4:0]       calc_pos;

  reg              is_local;
  reg              is_last_data;
  reg              is_last_reply;
  reg              has_reply;
  reg  [4:0]       reply_pos;

  wire [9:0]       req_len = pci_rx_header[9:0];
  wire [7:0]       req_type = pci_rx_header[31:24];
  wire [63:0]      req_address = pci_rx_header[95:64];

ila_1 ila_1_inst (
  .clk(clk),                              // input wire clk
  .probe0(pci_rx_empty),                  // input wire [0:0]  probe1 
  .probe1(pci_tx_full),                   // input wire [0:0]  probe1 
  .probe2(req_address),                   // input wire [63:0]  probe1 
  .probe3(req_len),                       // input wire [9:0]  probe1 
  .probe4(pci_rx_header[63:0]),           // input wire [63:0]  probe1 
  .probe5(pci_rx_header[127:64]),         // input wire [63:0]  probe1 
  .probe6(pci_tx_header[63:0]),           // input wire [63:0]  probe1 
  .probe7(pci_tx_header[127:64]),         // input wire [63:0]  probe1 
  .probe8(pci_tx_data[31:0]),             // input wire [31:0]  probe2
  .probe9(q_busy),                        // input wire [0:0]  probe2
  .probe10(q_address),                    // input wire [18:0]  probe2
  .probe11(q_len),                        // input wire [9:0]  probe2
  .probe12(q_pos),                        // input wire [4:0]  probe2
  .probe13(calc_address),                 // input wire [18:0]  probe2
  .probe14(calc_len),                     // input wire [9:0]  probe2
  .probe15(calc_pos),                     // input wire [4:0]  probe2
  .probe16(is_local),                     // input wire [0:0]  probe2
  .probe17(is_last_data),                 // input wire [0:0]  probe2
  .probe18(is_last_reply),                // input wire [0:0]  probe2
  .probe19(has_reply),                    // input wire [0:0]  probe2
  .probe20(reply_pos)                     // input wire [4:0]  probe2
);

generate
  begin : mem

    always @ (*) 
    begin
      calc_address = 0;
      calc_len = 0;
      calc_pos = 0;

      is_local = 0;
      has_reply = 0;
      is_last_reply = 0;
      is_last_data = 0;
      reply_pos = 0;

      if (!pci_rx_empty)
      begin
        if (q_busy)
        begin
          calc_address = q_address;
          calc_len = q_len;
          calc_pos = q_pos;
        end
        else
        begin
          calc_address = req_address[18:0];
          calc_len = req_len;
          calc_pos = 0;
        end

        if (calc_address < 128)
        begin
          is_local = 1;
          has_reply = local_rp;

          if (has_reply)            
          begin
            reply_pos = local_rp_address - req_address[6:2];
            if (reply_pos + 1 == req_len)
              is_last_reply = 1;
          end

          if (calc_len <= 1)
            is_last_data = 1;

        end
        else
        begin
          has_reply = sdram_rp;

          if (has_reply)
          begin
            reply_pos[4:1] = sdram_rp_address - req_address[6:3];
            reply_pos[0] = 0;

            if (reply_pos + 2 >= req_len)
              is_last_reply = 1;
          end

          if (calc_len <= 2)
            is_last_data = 1;

        end
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset || pci_rx_empty)
      begin
        pci_rx_rd <= 0;
        pci_tx_wr <= 0;
        q_busy <= 0;
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
              if (is_local)
                pci_tx_data[32 * reply_pos +: 32] <= local_rp_data;
              else
              begin
                if ((reply_pos == 0) && req_address[2])
                  pci_tx_data[31:0] <= sdram_rp_data[63:32];
                else
                  pci_tx_data[32 * reply_pos +: 64] <= sdram_rp_data;
              end

              if (is_last_reply)
              begin
                pci_tx_header[63:48] <= 16'b0;                  // completer ID
                pci_tx_header[47:45] <= 3'b0;                   // completion code = 000
                pci_tx_header[44] <= 1'b0;                      // BCM
                pci_tx_header[43:34] <= req_len;                // byte count
                pci_tx_header[33:32] <= 2'b0;                   // dword aligned

                if (req_len)
                  pci_tx_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
                else
                  pci_tx_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

                pci_tx_header[24] <= pci_rx_header[24];
                pci_tx_header[23] <= 1'b0;                      // R
                pci_tx_header[22:20] <= pci_rx_header[22:20];
                pci_tx_header[19:16] <= 4'b0;                   // TH, AttrH, R
                pci_tx_header[15:12] <= pci_rx_header[15:12];
                pci_tx_header[11:10] <= 2'b0;                   // AT
                pci_tx_header[9:0] <= pci_rx_header[9:0];
                pci_tx_wr <= 1;
                pci_rx_rd <= 1;
                q_busy <= 0;
              end
              else
              begin
                pci_tx_wr <= 0;
                pci_rx_rd <= 0;
                q_busy <= 1;
              end
            end
            else
            begin
              pci_tx_wr <= 0;
              pci_rx_rd <= 0;
              q_busy <= 1;
            end
          end

          8'b010_00000,
          8'b011_00000:
          begin
            if (is_last_data)
            begin
              q_busy <= 0;
              pci_rx_rd <= 1;
            end
            else
            begin
              q_busy <= 1;
              pci_rx_rd <= 0;
            end
            pci_tx_wr <= 0;
          end

          default:
          begin  // not supported
            pci_rx_rd <= 1;
            pci_tx_wr <= 0;
            q_busy <= 0;
          end
        endcase
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset || pci_rx_empty)
      begin
        sdram_rd <= 0;
        sdram_wr <= 0;
        local_rd <= 0;
        local_wr <= 0;
      end
      else
      begin
        case (req_type)
          8'b000_00000, 
          8'b001_00000,
          8'b000_00001,
          8'b001_00001: 
          begin  // read
            if (calc_len && !is_last_reply)
            begin
              if (is_local)
              begin
                q_address <= calc_address + 4;
                q_len <= calc_len - 1;
                q_pos <= calc_pos + 1;
                local_address <= calc_address[6:2];

                sdram_rd <= 0;
                sdram_wr <= 0;
                local_rd <= 1;
                local_wr <= 0;
              end
              else
              begin
                if (calc_address[2])
                begin
                  q_address <= calc_address + 4;
                  q_len <= calc_len - 1;
                  q_pos <= calc_pos + 1;
                  sdram_address <= calc_address[18:3];
                end
                else
                begin
                  q_address <= calc_address + 8;
                  if (calc_len > 1)
                    q_len <= calc_len - 2;
                  else
                    q_len <= calc_len - 1;
 
                  q_pos <= calc_pos + 2;

                  sdram_address <= calc_address[18:3];
                end

                sdram_rd <= 1;
                sdram_wr <= 0;
                local_rd <= 0;
                local_wr <= 0;
              end
            end
            else
            begin
              sdram_rd <= 0;
              sdram_wr <= 0;
              local_rd <= 0;
              local_wr <= 0;
            end             
          end

          8'b010_00000,
          8'b011_00000:
          begin  // write
            if (is_local)
            begin
              q_address <= calc_address + 4;
              q_len <= calc_len - 1;
              q_pos <= calc_pos + 1;
              local_address <= calc_address[6:2];
              local_wr_be <= pci_rx_be[4 * calc_pos +: 4];
              local_wr_data <= pci_rx_data[32 * calc_pos +: 32];

              sdram_rd <= 0;
              sdram_wr <= 0;
              local_rd <= 0;
              local_wr <= 1;
            end
            else
            begin
              if (calc_address[2])
              begin
                q_address <= calc_address + 4;
                q_len <= calc_len - 1;
                q_pos <= calc_pos + 1;

                sdram_address <= calc_address[18:3];
                sdram_wr_be[7:4] <= pci_rx_be[3:0];
                sdram_wr_be[3:0] <= 0;
                sdram_wr_data[63:32] <= pci_rx_data[31:0];
              end
              else
              begin
                q_address <= calc_address + 8;
                if (calc_len > 1)
                  q_len <= calc_len - 2;
                else
                  q_len <= calc_len - 1;
 
                q_pos <= calc_pos + 2;

                sdram_address <= calc_address[18:3];
                sdram_wr_be <= pci_rx_be[4 * calc_pos +: 4];
                sdram_wr_data <= pci_rx_data[32 * calc_pos +: 64];
              end

              sdram_rd <= 0;
              sdram_wr <= 1;
              local_rd <= 0;
              local_wr <= 0;
            end
          end

          default:
          begin  // not supported
            sdram_rd <= 0;
            sdram_wr <= 0;
            local_rd <= 0;
            local_wr <= 0;
          end
        endcase
      end
    end

  end
endgenerate

endmodule
