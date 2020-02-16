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
  pci_rx_control,
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
  output wire [15:0]             pci_rx_control;
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
  reg  [15:0]    q_control;

  reg            pci_rx_wr;
  
// local variables

  wire         active = m_axis_rx_tvalid && m_axis_rx_tready && !reset;  
  wire         has_strad = m_axis_rx_tuser[13] && m_axis_rx_tuser[21];

  reg          is_first;
  reg [7:0]    req_type;
  reg [9:0]    req_len;

  reg          has_header_low;
  reg          has_header_high;
  reg          calc_header_done;

  reg [3:0]    calc_pos;
  reg [1:0]    calc_blk_pos;
  reg [9:0]    calc_blk_size;
  reg [9:0]    calc_remain_size;
  reg [127:0]  calc_be;
  reg [7:0]    calc_count;

  reg [3:0]    use_first_be;
  reg [3:0]    use_last_be;

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

fifo_control pci_rx_control_inst (
  .clk(clk),             // input wire clk
  .din(q_control),       // input wire [15 : 0] din
  .wr_en(pci_rx_wr),     // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_control), // output wire [15 : 0] dout
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
	.probe5(m_axis_rx_tdata[63:0]),    // input wire [63:0]  probe0  
	.probe6(m_axis_rx_tdata[127:64]),  // input wire [63:0]  probe0  
	.probe7(pci_rx_rd),                // input wire [0:0]  probe0  
	.probe8(pci_rx_wr),                // input wire [0:0]  probe0  
	.probe9(pci_rx_empty),             // input wire [0:0]  probe0  
	.probe10(has_header_low),           // input wire [0:0]  probe0  
	.probe11(has_header_high),          // input wire [0:0]  probe0  
	.probe12(calc_pos),                // input wire [3:0]  probe0  
	.probe13(calc_blk_pos),            // input wire [1:0]  probe0  
	.probe14(calc_remain_size),        // input wire [9:0]  probe0  
	.probe15(calc_blk_size),           // input wire [9:0]  probe0  
	.probe16(q_data[63:0]),            // input wire [63:0]  probe0  
	.probe17(q_be[31:0]),              // input wire [31:0]  probe0  
	.probe18(q_control),               // input wire [15:0]  probe0  
	.probe19(use_first_be),            // input wire [3:0]  probe0  
	.probe20(use_last_be),             // input wire [3:0]  probe0  
	.probe21(calc_be),                 // input wire [127:0]  probe0  
	.probe22(calc_count)               // input wire [7:0]  probe0  
);


function [127:0] first_and_last_to_be;
  input [3:0] first_be;
  input [3:0] last_be;
  input [9:0] dw_count;
  reg [4:0] count;
  reg [127:0] res;
  begin
    case (dw_count)
      0: 
      begin
        res = 0;
      end

      1:
      begin
        res[3:0] = first_be;
        res[127:4] = 0;
      end

      2:
      begin
        res[3:0] = first_be;
        res[7:4] = last_be;
        res[127:8] = 0;
      end

      3:
      begin
        res[3:0] = first_be;
        res[7:4] = {4{1'b1}};
        res[11:8] = last_be;
        res[127:12] = 0;
      end

      4:
      begin
        res[3:0] = first_be;
        res[11:4] = {8{1'b1}};
        res[15:8] = last_be;
        res[127:16] = 0;
      end

      5:
      begin
        res[3:0] = first_be;
        res[15:4] = {12{1'b1}};
        res[19:16] = last_be;
        res[127:20] = 0;
      end

      6:
      begin
        res[3:0] = first_be;
        res[20:4] = {16{1'b1}};
        res[23:20] = last_be;
        res[127:24] = 0;
      end

      7:
      begin
        res[3:0] = first_be;
        res[23:4] = {20{1'b1}};
        res[27:24] = last_be;
        res[127:28] = 0;
      end

      8:
      begin
        res[3:0] = first_be;
        res[27:4] = {24{1'b1}};
        res[31:28] = last_be;
        res[127:32] = 0;
      end

      9:
      begin
        res[3:0] = first_be;
        res[31:4] = {28{1'b1}};
        res[35:32] = last_be;
        res[127:36] = 0;
      end

      10:
      begin
        res[3:0] = first_be;
        res[35:4] = {32{1'b1}};
        res[39:36] = last_be;
        res[127:40] = 0;
      end

      11:
      begin
        res[3:0] = first_be;
        res[39:4] = {36{1'b1}};
        res[43:40] = last_be;
        res[127:44] = 0;
      end

      12:
      begin
        res[3:0] = first_be;
        res[43:4] = {40{1'b1}};
        res[47:44] = last_be;
        res[127:48] = 0;
      end

      13:
      begin
        res[3:0] = first_be;
        res[47:4] = {44{1'b1}};
        res[51:48] = last_be;
        res[127:52] = 0;
      end

      14:
      begin
        res[3:0] = first_be;
        res[51:4] = {48{1'b1}};
        res[55:52] = last_be;
        res[127:56] = 0;
      end

      15:
      begin
        res[3:0] = first_be;
        res[55:4] = {52{1'b1}};
        res[59:56] = last_be;
        res[127:60] = 0;
      end

      16:
      begin
        res[3:0] = first_be;
        res[59:4] = {56{1'b1}};
        res[63:60] = last_be;
        res[127:64] = 0;
      end

      17:
      begin
        res[3:0] = first_be;
        res[63:4] = {60{1'b1}};
        res[67:64] = last_be;
        res[127:68] = 0;
      end

      18:
      begin
        res[3:0] = first_be;
        res[67:4] = {64{1'b1}};
        res[71:68] = last_be;
        res[127:72] = 0;
      end

      19:
      begin
        res[3:0] = first_be;
        res[71:4] = {68{1'b1}};
        res[75:72] = last_be;
        res[127:76] = 0;
      end

      20:
      begin
        res[3:0] = first_be;
        res[75:4] = {72{1'b1}};
        res[79:76] = last_be;
        res[127:80] = 0;
      end

      21:
      begin
        res[3:0] = first_be;
        res[79:4] = {76{1'b1}};
        res[83:80] = last_be;
        res[127:84] = 0;
      end
      
      22:
      begin
        res[3:0] = first_be;
        res[83:4] = {80{1'b1}};
        res[87:84] = last_be;
        res[127:88] = 0;
      end
      
      23:
      begin
        res[3:0] = first_be;
        res[87:4] = {84{1'b1}};
        res[91:88] = last_be;
        res[127:92] = 0;
      end
      
      24:
      begin
        res[3:0] = first_be;
        res[91:4] = {88{1'b1}};
        res[95:92] = last_be;
        res[127:96] = 0;
      end
      
      25:
      begin
        res[3:0] = first_be;
        res[95:4] = {92{1'b1}};
        res[99:96] = last_be;
        res[127:100] = 0;
      end
      
      26:
      begin
        res[3:0] = first_be;
        res[99:4] = {96{1'b1}};
        res[103:100] = last_be;
        res[127:104] = 0;
      end
      
      27:
      begin
        res[3:0] = first_be;
        res[103:4] = {100{1'b1}};
        res[107:104] = last_be;
        res[127:108] = 0;
      end
      
      28:
      begin
        res[3:0] = first_be;
        res[107:4] = {104{1'b1}};
        res[111:108] = last_be;
        res[127:112] = 0;
      end
      
      29:
      begin
        res[3:0] = first_be;
        res[111:4] = {108{1'b1}};
        res[115:112] = last_be;
        res[127:116] = 0;
      end
      
      30:
      begin
        res[3:0] = first_be;
        res[115:4] = {112{1'b1}};
        res[119:116] = last_be;
        res[127:120] = 0;
      end
      
      31:
      begin
        res[3:0] = first_be;
        res[119:4] = {116{1'b1}};
        res[123:120] = last_be;
        res[127:124] = 0;
      end
      
      32:
      begin
        res[3:0] = first_be;
        res[123:4] = {120{1'b1}};
        res[127:124] = last_be;
      end

      default:
      begin
        res[3:0] = first_be;
        res[127:4] = {124{1'b1}};
      end
    endcase

    first_and_last_to_be = res;
  end
endfunction

function [3:0] count_to_first_be;
  input [1:0] base;
  input [11:0] count;
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

function [3:0] count_to_last_be;
  input [1:0] base;
  input [11:0] count;
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

function [127:0] count_to_be;
  input [1:0] base;
  input [11:0] count;
  input [9:0] dw_count;
  reg [3:0] first_be;
  reg [3:0] last_be;
  begin
    first_be = count_to_first_be(base, count);
    last_be = count_to_last_be(base, count);
    count_to_be = first_and_last_to_be(first_be, last_be, dw_count);
  end
endfunction

function [7:0] first_be_to_count;
  input [3:0] be;
  reg [7:0] res;
  begin
    casex (be)
      4'b1xx1 : res = 4;
      4'b01x1 : res = 3;
      4'b1x10 : res = 3;
      4'b0011 : res = 2;
      4'b0110 : res = 2;
      4'b1100 : res = 2;
      4'b0001 : res = 1;
      4'b0010 : res = 1;
      4'b0100 : res = 1;
      4'b1000 : res = 1;
      4'b0000 : res = 1;
    endcase

    first_be_to_count = res;
  end
endfunction

function [7:0] last_be_to_count;
  input [3:0] be;
  reg [7:0] res;
  begin
    case (be)
      4'b1111 : res = 4;
      4'b0111 : res = 3;
      4'b0011 : res = 2;
      4'b0001 : res = 1;
      4'b0000 : res = 0;
      default: res = 4;
    endcase

    last_be_to_count = res;
  end
endfunction

function [7:0] first_and_last_to_count;
  input [3:0] first_be;
  input [3:0] last_be;
  input [9:0] dw_count;
  reg [7:0] res;
  begin
    case (dw_count)
      0: res = 0;
      1: res = first_be_to_count(first_be);
      default:
      begin
        if (dw_count < 32)
          res = first_be_to_count(first_be) + last_be_to_count(last_be) + 4 * (dw_count[5:0] - 2);
        else
          res = first_be_to_count(first_be) + 4 * (dw_count[5:0] - 1);
      end
    endcase

    first_and_last_to_count = res;
  end
endfunction

generate
  begin : pci_rx_128

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
      has_header_low = 0;
      has_header_high = 0;
      is_first = 0;
      calc_be = 0;
      calc_count = 0;

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

        if (req_type[3])
        begin
          if (has_header_high)
          begin
            if (has_header_low)
              calc_count = loaded_header[43:32];
            else
              calc_count = q_header[43:32];

            calc_be = count_to_be(loaded_header[65:64], calc_count, req_len);
          end
        end
        else
        begin
          if (has_header_low)
          begin
            use_first_be = loaded_header[39:32];
            use_last_be = loaded_header[47:40];
            calc_be = first_and_last_to_be(use_first_be, use_last_be, req_len);
            calc_count = first_and_last_to_count(use_first_be, use_last_be, req_len);
          end
        end
      end

      if (!reset )
      begin      
        if (has_header_low)
        begin
          q_header[63:0] <= loaded_header[63:0];

          if (!req_type[3])
          begin
            q_be <= calc_be;
            q_control[7:0] <= calc_count;
            q_control[15:8] <= m_axis_rx_tuser[9:2];
          end
        end

        if (has_header_high)
        begin
          q_header[127:64] <= loaded_header[127:64];

          if (req_type[3])
          begin
            q_be <= calc_be;
            q_control[7:0] <= calc_count;
            q_control[15:8] <= m_axis_rx_tuser[9:2];
          end
        end

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
        end
               
        if (calc_blk_size > 1)
        begin
          q_data[(32*(calc_pos+1)) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+56) +: 8];
          q_data[(32*(calc_pos+1)+8) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+48) +: 8];
          q_data[(32*(calc_pos+1)+16) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+40) +: 8];
          q_data[(32*(calc_pos+1)+24) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+32) +: 8];
        end

        if (calc_blk_size > 2)
        begin
          q_data[(32*(calc_pos+2)) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+88) +: 8];
          q_data[(32*(calc_pos+2)+8) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+80) +: 8];
          q_data[(32*(calc_pos+2)+16) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+72) +: 8];
          q_data[(32*(calc_pos+2)+24) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+64) +: 8];
        end

        if (calc_blk_size > 3)
        begin
          q_data[(32*(calc_pos+3)) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+120) +: 8];
          q_data[(32*(calc_pos+3)+8) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+112) +: 8];
          q_data[(32*(calc_pos+3)+16) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+104) +: 8];
          q_data[(32*(calc_pos+3)+24) +: 8] <= m_axis_rx_tdata[(32*calc_blk_pos+96) +: 8];
        end

        q_remain_size <= calc_remain_size - calc_blk_size;
        q_pos <= calc_pos + calc_blk_size;

      end
    end

  end    
endgenerate

endmodule
