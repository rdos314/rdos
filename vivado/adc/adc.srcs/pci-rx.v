module pci_rx (
  clk,
  reset,
  m_axis_rx_tdata,
  m_axis_rx_tkeep,
  m_axis_rx_tlast,
  m_axis_rx_tvalid,
  m_axis_rx_tready,
  m_axis_rx_tuser,
  
  pci_rx_data,
  pci_rx_header,
  pci_rx_be,
  pci_rx_rd,
  pci_rx_empty
);

  input                          clk;
  input                          reset;

  input       [127:0]            m_axis_rx_tdata;
  input       [15:0]             m_axis_rx_tkeep;
  input                          m_axis_rx_tlast;
  input                          m_axis_rx_tvalid;
  output reg                     m_axis_rx_tready;
  input       [21:0]             m_axis_rx_tuser;

  output wire [1023:0]           pci_rx_data;
  output wire [191:0]            pci_rx_header;
  output wire [127:0]            pci_rx_be;
  input  wire                    pci_rx_rd;
  output wire                    pci_rx_empty;

  wire                           pci_rx_full;

// FF
  reg            pci_rx_wr;
  
  reg [3:0]      q_pos;
  reg [9:0]      q_remain_size;
  reg            q_header_done;
  reg [3:0]      q_first_be;
  reg [3:0]      q_last_be;
  reg            q_pend_strad;
  reg [63:0]     q_strad_header;

  reg  [1023:0]  q_data;
  reg  [191:0]   q_header;
  reg  [127:0]   q_be;

// local variables

  reg          active;  
  reg          is_first;
  reg [7:0]    req_type;
  reg [9:0]    req_len;
  reg [1:0]    low_adr;
  reg [11:0]   byte_count;

  reg          has_strad;
  reg          has_header_low;
  reg          has_header_high;

  reg [3:0]    calc_pos;
  reg [1:0]    calc_blk_pos;
  reg [9:0]    calc_blk_size;
  reg [9:0]    calc_remain_size;
  reg [3:0]    calc_first_be;
  reg [3:0]    calc_last_be;
  reg          calc_header_done;

  reg [127:0]  loaded_header;


fifo_data pci_rx_data_inst (
  .clk(clk),             // input wire clk
  .din(q_data),          // input wire [1023 : 0] din
  .wr_en(pci_rx_wr),     // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_data),    // output wire [1023 : 0] dout
  .full(pci_rx_full),    // output wire full
  .empty(pci_rx_empty)   // output wire empty
);

fifo_header pci_rx_header_inst (
  .clk(clk),             // input wire clk
  .din(q_header),        // input wire [191 : 0] din
  .wr_en(pci_rx_wr),     // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_header),  // output wire [191 : 0] dout
  .full(),               // output wire full
  .empty()               // output wire empty
);

fifo_be pci_rx_be_inst (
  .clk(clk),             // input wire clk
  .din(q_be),            // input wire [127 : 0] din
  .wr_en(pci_rx_wr),     // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_be),      // output wire [127 : 0] dout
  .full(),               // output wire full
  .empty()               // output wire empty
);

ila_0 ila_0_inst (
	.clk(clk),                         // input wire clk
	.probe0(m_axis_rx_tvalid),         // input wire [0:0]  probe0  
	.probe1(m_axis_rx_tready),         // input wire [0:0]  probe0  
	.probe2(m_axis_rx_tuser[13]),      // input wire [0:0]  probe0  
	.probe3(m_axis_rx_tuser[14]),      // input wire [0:0]  probe0  
	.probe4(m_axis_rx_tuser[21]),      // input wire [0:0]  probe0  
	.probe5(pci_rx_rd),                // input wire [0:0]  probe0  
	.probe6(pci_rx_wr),                // input wire [0:0]  probe0  
	.probe7(pci_rx_empty),             // input wire [0:0]  probe0  
	.probe8(has_header_low),           // input wire [0:0]  probe0  
	.probe9(has_header_high),          // input wire [0:0]  probe0  
	.probe10(calc_pos),                // input wire [3:0]  probe0  
	.probe11(calc_blk_pos),            // input wire [1:0]  probe0  
	.probe12(calc_remain_size),        // input wire [9:0]  probe0  
	.probe13(calc_blk_size),           // input wire [9:0]  probe0  
	.probe14(q_header[63:0]),          // input wire [63:0]  probe0  
	.probe15(q_header[127:64]),        // input wire [63:0]  probe0  
	.probe16(q_data[31:0]),            // input wire [31:0]  probe0  
	.probe17(q_be[31:0])               // input wire [31:0]  probe0  
);

generate
  begin : pci_rx_128

    always @ ( posedge clk ) 
    begin
      if (reset)
        active = 0;
      else
      begin
        if (m_axis_rx_tvalid && m_axis_rx_tready)
          active = 1;
        else
          active = 0;
      end

      has_header_low = 0;
      has_header_high = 0;
      is_first = 0;

      if (active )
      begin
        if (m_axis_rx_tuser[13] && m_axis_rx_tuser[21])
          has_strad = 1;
        else
          has_strad = 0;

        if (m_axis_rx_tuser[14])
        begin
          is_first = 1;
          has_header_low = 1;

          if (m_axis_rx_tuser[13])  // header in high part of data
            loaded_header[63:0] =  m_axis_rx_tdata[127:64];
          else
            loaded_header[63:0] =  m_axis_rx_tdata[63:0];

          req_type = loaded_header[31:24];
          req_len = loaded_header[9:0];

          if (m_axis_rx_tuser[13])
          begin
            calc_blk_size = 0;
            calc_header_done = 0;
          end
          else
          begin
            has_header_high = 1;
            calc_header_done = 1;

            if (req_type[5] == 0)  // 3 DW header
            begin
              loaded_header[95:64] =  m_axis_rx_tdata[95:64];
              loaded_header[127:96] =  32'b0;
              calc_blk_size = 1;
              calc_blk_pos = 2'b11;
            end
            else
            begin
              loaded_header[127:64] = m_axis_rx_tdata[127:64];
              calc_blk_size = 0;
              calc_blk_pos = 2'b00;
            end
          end
        end
        else
        begin
          calc_header_done = 1;

          if (q_pend_strad)
          begin
            loaded_header[63:0] = q_strad_header;
            has_header_low = 1;
            req_type = loaded_header[31:24];
            req_len = loaded_header[9:0];
          end
          else
          begin
            req_type = q_header[31:24];
            req_len = q_header[9:0];
          end

          if (q_header_done)
          begin
            calc_blk_size = 4;
            calc_blk_pos = 2'b00;
          end
          else
          begin
            is_first = 1;
            has_header_high = 1;

            if (req_type[5] == 0)
            begin
              loaded_header[95:64] =  m_axis_rx_tdata[31:0];
              loaded_header[127:96] =  32'b0;
              calc_blk_size = 3;
              calc_blk_pos = 2'b01;
            end
            else
            begin
              loaded_header[127:64] =  m_axis_rx_tdata[63:0];
              calc_blk_size = 2;
              calc_blk_pos = 2'b10;
            end
          end
        end

        if (is_first)
        begin
          calc_pos = 0;

          if (req_type[6])
            calc_remain_size = req_len;
          else
            calc_remain_size = 0;
        end
        else
        begin
          calc_pos = q_pos;
          calc_remain_size = q_remain_size;
        end

        if (calc_blk_size > calc_remain_size)
          calc_blk_size = calc_remain_size;

        if (req_type[3])
        begin
          if (has_header_high)
          begin
            if (has_header_low)
              byte_count = loaded_header[43:32];
            else
              byte_count = q_header[43:32];

            low_adr = loaded_header[65:64];

            case (low_adr)
              2'b00: 
              begin
                case (byte_count)
                  1: calc_first_be = 4'b0001;
                  2: calc_first_be = 4'b0011;
                  3: calc_first_be = 4'b0111;
                  default: calc_first_be = 4'b1111;
                endcase
              end

              2'b01:
              begin
                case (byte_count)
                  1: calc_first_be = 4'b010;
                  2: calc_first_be = 4'b0110;
                  default: calc_first_be = 4'b1110;
                endcase
              end

              2'b10:
              begin
                if (byte_count == 1)
                  calc_first_be = 4'b0100;
                else
                  calc_first_be = 4'b1100;
              end

              2'b11:
              begin
                calc_first_be = 4'b1000;
              end
            endcase

            low_adr = low_adr + byte_count[1:0];
            case (low_adr)
              2'b00: calc_last_be = 4'b1111;
              2'b01: calc_last_be = 4'b0001;
              2'b10: calc_last_be = 4'b0011;
              2'b11: calc_last_be = 4'b0111;
            endcase
          end
          else
          begin
            calc_first_be = q_first_be;
            calc_last_be = q_last_be;
          end
        end
        else
        begin
          if (has_header_low)
          begin
            calc_first_be = loaded_header[39:32];
            calc_last_be = loaded_header[47:40];
          end
          else
          begin
            calc_first_be = q_first_be;
            calc_last_be = q_last_be;
          end
        end
      end

// FF part

      if (reset )
      begin
        m_axis_rx_tready <= 0;
        pci_rx_wr <= 0;
      end
      else
      begin      
        if (has_header_low)
        begin
          q_header[63:0] <= loaded_header[63:0];
          q_first_be <= calc_first_be;
          q_last_be <= calc_last_be;
        end

        if (has_header_high)
          q_header[127:64] <= loaded_header[127:64];

        if (has_strad)
        begin
          q_strad_header <=  m_axis_rx_tdata[127:64];
          q_pend_strad <= 1;
        end
        else
          q_pend_strad <= 0;

        if (active)
          q_header_done <= calc_header_done;

        if (calc_blk_size)
        begin
          q_data[(32*calc_pos) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+24) +: 8];
          q_data[(32*calc_pos+8) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+16) +: 8];
          q_data[(32*calc_pos+16) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+8) +: 8];
          q_data[(32*calc_pos+24) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos) +: 8];

          if (calc_pos)
          begin
            if ((calc_remain_size == calc_blk_size) && (calc_blk_size == 1))
              q_be[4*(calc_pos) +: 4] <= calc_last_be;
            else
              q_be[4*(calc_pos) +: 4] <= 4'b1111;
          end
          else
            q_be[3:0] <= calc_first_be;
        end
               
        if (calc_blk_size > 1)
        begin
          q_data[(32*(calc_pos+1)) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+56) +: 8];
          q_data[(32*(calc_pos+1)+8) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+48) +: 8];
          q_data[(32*(calc_pos+1)+16) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+40) +: 8];
          q_data[(32*(calc_pos+1)+24) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+32) +: 8];

          if ((calc_remain_size == calc_blk_size) && (calc_blk_size == 2))
            q_be[4*(calc_pos+1) +: 4] <= calc_last_be;
          else
            q_be[4*(calc_pos+1) +: 4] <= 4'b1111;
        end

        if (calc_blk_size > 2)
        begin
          q_data[(32*(calc_pos+2)) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+88) +: 8];
          q_data[(32*(calc_pos+2)+8) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+80) +: 8];
          q_data[(32*(calc_pos+2)+16) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+72) +: 8];
          q_data[(32*(calc_pos+2)+24) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+64) +: 8];

          if ((calc_remain_size == calc_blk_size) && (calc_blk_size == 3))
            q_be[4*(calc_pos+2) +: 4] <= calc_last_be;
          else
            q_be[4*(calc_pos+2) +: 4] <= 4'b1111;
        end

        if (calc_blk_size > 3)
        begin
          q_data[(32*(calc_pos+3)) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+120) +: 8];
          q_data[(32*(calc_pos+3)+8) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+112) +: 8];
          q_data[(32*(calc_pos+3)+16) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+104) +: 8];
          q_data[(32*(calc_pos+3)+24) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+96) +: 8];
  
          if ((calc_remain_size == calc_blk_size) && (calc_blk_size == 4))
            q_be[4*(calc_pos+3) +: 4] <= calc_last_be;
          else
            q_be[4*(calc_pos+3) +: 4] <= 4'b1111;
        end

        q_remain_size <= calc_remain_size - calc_blk_size;
        q_pos <= calc_pos + calc_blk_size;

        if (m_axis_rx_tuser[21])
          pci_rx_wr <= 1;             
        else
          pci_rx_wr <= 0;

        if (pci_rx_full)
          m_axis_rx_tready <= 0;
        else
          m_axis_rx_tready <= 1;
      end
    end

  end    
endgenerate

endmodule
