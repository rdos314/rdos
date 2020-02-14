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
  pci_rx_count,
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
  output wire [127:0]            pci_rx_header;
  output wire [127:0]            pci_rx_be;
  output wire [7:0]              pci_rx_count;
  input  wire                    pci_rx_rd;
  output wire                    pci_rx_empty;

  wire                           pci_rx_full;

// FF
  reg [3:0]      q_pos;
  reg [9:0]      q_remain_size;
  reg            q_header_done;
  reg [3:0]      q_first_be;
  reg [3:0]      q_last_be;
  reg [11:0]     q_byte_count;
  reg            q_pend_strad;
  reg [63:0]     q_strad_header;

  reg  [1023:0]  q_data;
  reg  [127:0]   q_header;
  reg  [127:0]   q_be;
  reg  [7:0]     q_count;

  reg            pci_rx_wr;
  
// local variables

  wire         active = m_axis_rx_tvalid && m_axis_rx_tready && !reset;  
  wire         has_strad = m_axis_rx_tuser[13] && m_axis_rx_tuser[21];

  reg          is_first;
  reg [7:0]    req_type;
  reg [9:0]    req_len;
  reg [1:0]    low_adr;
  reg [11:0]   byte_count;

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
  .din(q_header),        // input wire [127 : 0] din
  .wr_en(pci_rx_wr),     // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_header),  // output wire [127 : 0] dout
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

fifo_count pci_rx_count_inst (
  .clk(clk),             // input wire clk
  .din(q_count),         // input wire [7 : 0] din
  .wr_en(pci_rx_wr),     // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_count),   // output wire [7 : 0] dout
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
	.probe17(q_be[31:0]),              // input wire [31:0]  probe0  
	.probe18(calc_first_be),           // input wire [3:0]  probe0  
	.probe19(calc_last_be),            // input wire [3:0]  probe0  
	.probe20(byte_count),              // input wire [11:0]  probe0  
	.probe21(q_count)                  // input wire [7:0]  probe0  
);

function count_to_first_be;
  input [1:0] base, [11:0] count;
  reg [3:0] res;
  begin
    case (base)
      2'b00: 
      begin
        case (count)
          1: res = 4'b0001;
          2: res = 4'b0011;
          3: res = 4'b0111;
          default: res = 4'b1111;
        endcase
      end

      2'b01:
      begin
        case (count)
          1: res = 4'b010;
          2: res = 4'b0110;
          default: res = 4'b1110;
        endcase
      end

      2'b10:
      begin
        if (count == 1)
          res = 4'b0100;
        else
          res = 4'b1100;
      end

      2'b11:
      begin
        res = 4'b1000;
      end
    endcase

    count_to_first_be = res;
  end
endfunction

function count_to_last_be;
  input [1:0] base, [11:0] count;
  reg [3:0] res;
  reg [1:0] low;
  begin
    low = base + count[1:0];
    case (low)
      2'b00: res = 4'b1111;
      2'b01: res = 4'b0001;
      2'b10: res = 4'b0011;
      2'b11: res = 4'b0111;
    endcase

    count_to_last_be = res;
  end
endfunction

function first_be_to_count;
  input [3:0] be;
  reg [7:0] res;
  begin
    casex (be)
      4'b1xx1 : count = 4;
      4'b01x1 : count = 3;
      4'b1x10 : count = 3;
      4'b0011 : count = 2;
      4'b0110 : count = 2;
      4'b1100 : count = 2;
      4'b0001 : count = 1;
      4'b0010 : count = 1;
      4'b0100 : count = 1;
      4'b1000 : count = 1;
      4'b0000 : count = 1;
    endcase

    first_be_to_count = res;
  end
endfunction

function last_be_to_count;
  input [3:0] be;
  reg [7:0] res;
  begin
    case (be)
      4'b1111 : res = 4;
      4'b1110 : res = 3;
      4'b1100 : res = 2;
      4'b1000 : res = 1;
      4'b0000 : res = 0;
      default: res = 4;
    endcase

    last_be_to_count = res;
  end
endfunction


generate
  begin : pci_rx_128


    always @ (*) 
    begin
      has_header_low = 0;
      has_header_high = 0;
      is_first = 0;

      if (active )
      begin

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
      end
    end

    always @ (*) 
    begin
      byte_count = 0;

      if (active)
      begin
        if (req_type[3])
        begin
          if (has_header_high)
          begin
            if (has_header_low)
              byte_count = loaded_header[43:32];
            else
              byte_count = q_header[43:32];

            low_adr = loaded_header[65:64];

            calc_first_be = count_to_first_be(low_adr, byte_count);
            calc_last_be = count_to_last_be(low_adr, byte_count);
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
            byte_count = q_byte_count;
          end

          if (calc_pos)
          begin
            if (calc_blk_size)
            begin
              if (calc_remain_size == calc_blk_size)
                byte_count = last_be_to_count(calc_last_be) + q_count + 4 * (calc_blk_size - 4);
              else
                byte_count = q_count + 4 * calc_blk_size;
            end
            else
              byte_count = q_count;
          end
          else
          begin
            byte_count = first_be_to_count(calc_last_be);

            if (calc_blk_size)
            begin
              if (calc_remain_size == calc_blk_size)
                byte_count = last_be_to_count(calc_last_be) + byte_count + 4 * (calc_blk_size - 4);
              end
                byte_count = byte_count + 4 * (calc_blk_size - 1);
            end
          end
        end
      end
      else
      begin
        calc_first_be = 4'b0000;
        calc_last_be = 4'b0000;
        byte_count = 0;
      end
    end

    always @ (reset or pci_rx_full ) 
    begin
      if (reset )
        m_axis_rx_tready = 0;
      else
      begin      
        if (pci_rx_full)
          m_axis_rx_tready = 0;
        else
          m_axis_rx_tready = 1;
      end
    end


    always @ ( posedge clk ) 
    begin
      if (reset )
        pci_rx_wr <= 0;
      else
      begin      
        if (m_axis_rx_tuser[21])
          pci_rx_wr <= 1;             
        else
          pci_rx_wr <= 0;
      end
    end

    always @ ( posedge clk ) 
    begin
      if (!reset )
      begin      
        if (has_header_low)
        begin
          q_header[63:0] <= loaded_header[63:0];
          q_first_be <= calc_first_be;
          q_last_be <= calc_last_be;
        end

        q_header[139:128] <= byte_count;

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

      end
    end

  end    
endgenerate

endmodule
