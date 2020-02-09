module pci_rx (
  clk,
  reset,
  m_axis_rx_tdata,
  m_axis_rx_tkeep,
  m_axis_rx_tlast,
  m_axis_rx_tvalid,
  m_axis_rx_tready,
  m_axis_rx_tuser,
  
  bram_data,
  bram_header,
  bram_be,
  bram_rd_ptr,
  curr_data,
  curr_header,
  curr_be,
  bram_wr_ptr,
  bram_wr
);

  input                          clk;
  input                          reset;

  input       [127:0]            m_axis_rx_tdata;
  input       [15:0]             m_axis_rx_tkeep;
  input                          m_axis_rx_tlast;
  input                          m_axis_rx_tvalid;
  output reg                     m_axis_rx_tready;
  input       [21:0]             m_axis_rx_tuser;

  output wire [1023:0]           bram_data;
  output wire [191:0]            bram_header;
  output wire [127:0]            bram_be;
  input  wire [3:0]              bram_rd_ptr;
  output reg  [1023:0]           curr_data;
  output reg  [191:0]            curr_header;
  output reg  [127:0]            curr_be;
  output reg  [3:0]              bram_wr_ptr;
  output reg                     bram_wr;

// FF
  reg [3:0]    sel;
  reg [3:0]    data_size;
  reg          header_done;
  reg          pend_strad;
  reg [3:0]    curr_first_be;
  reg [3:0]    curr_last_be;
  reg [1:0]    curr_low_adr;
  reg [11:0]   curr_byte_count;
  reg [63:0]   strad_header;

// local variables

  reg          active;  
  reg          load_header_low;
  reg          load_header_high;
  reg          new_strad;
  reg          is_first;
  reg [1:0]    start_pos;
  reg [3:0]    curr_pos;
  reg [9:0]    new_size;
  reg [9:0]    max_size;
  reg [9:0]    curr_size;
  reg [7:0]    req_type;
  reg [9:0]    req_len;
  reg [3:0]    first_be;
  reg [3:0]    last_be;
  reg [1:0]    low_adr;
  reg [11:0]   byte_count;
  reg [3:0]    new_first_be;
  reg [3:0]    new_last_be;
  reg [11:0]   temp_byte_count;
  reg [1:0]    temp_low_adr;
  reg [127:0]  new_header;


bram_data pci_rx_data_inst (
  .clka(clk),                 // input wire clka
  .wea(bram_wr),              // input wire [0 : 0] wea
  .addra(bram_wr_ptr),        // input wire [3 : 0] addra
  .dina(curr_data),           // input wire [1023 : 0] dina
  .clkb(clk),                 // input wire clkb
  .addrb(bram_rd_ptr),        // input wire [3 : 0] addrb
  .doutb(bram_data)           // output wire [1023 : 0] doutb
);

bram_header pci_rx_header_inst (
  .clka(clk),                 // input wire clka
  .wea(bram_wr),              // input wire [0 : 0] wea
  .addra(bram_wr_ptr),        // input wire [3 : 0] addra
  .dina(curr_header),         // input wire [191 : 0] dina
  .clkb(clk),                 // input wire clkb
  .addrb(bram_rd_ptr),        // input wire [3 : 0] addrb
  .doutb(bram_header)         // output wire [191 : 0] doutb
);

bram_be pci_rx_be_inst (
  .clka(clk),                 // input wire clka
  .wea(bram_wr),              // input wire [0 : 0] wea
  .addra(bram_wr_ptr),        // input wire [3 : 0] addra
  .dina(curr_be),             // input wire [127 : 0] dina
  .clkb(clk),                 // input wire clkb
  .addrb(bram_rd_ptr),        // input wire [3 : 0] addrb
  .doutb(bram_be)             // output wire [127 : 0] doutb
);

ila_0 ila_0_inst (
	.clk(clk),                        // input wire clk
	.probe0(m_axis_rx_tvalid),        // input wire [0:0]  probe0  
	.probe1(m_axis_rx_tready),        // input wire [0:0]  probe0  
	.probe2(header_done),              // input wire [0:0]  probe0  
	.probe3(pend_strad),              // input wire [0:0]  probe0  
	.probe4(m_axis_rx_tuser[13]),              // input wire [0:0]  probe0  
	.probe5(m_axis_rx_tuser[14]),              // input wire [0:0]  probe0  
	.probe6(m_axis_rx_tuser[21]),              // input wire [0:0]  probe0  
	.probe7(req_type),                      // input wire [7:0]  probe0  
	.probe8(is_first),                      // input wire [0:0]  probe0  
	.probe9(new_header[31:0]),              // input wire [31:0]  probe0  
	.probe10(new_header[63:32]),              // input wire [31:0]  probe0  
	.probe11(new_header[95:64]),              // input wire [31:0]  probe0  
	.probe12(new_header[127:96])              // input wire [31:0]  probe0  
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
    end

    always @ ( posedge clk ) 
    begin
      load_header_low = 0;
      load_header_high = 0;
      is_first = 0;
      new_header = 0;

      if (active )
      begin
        if (m_axis_rx_tuser[13] && m_axis_rx_tuser[21])
          new_strad = 1;
        else
          new_strad = 0;

        if (m_axis_rx_tuser[14])
        begin
          is_first = 1;
          load_header_low = 1;

          if (m_axis_rx_tuser[13])  // header in high part of data
          begin
            new_header[63:0] =  m_axis_rx_tdata[127:64];
            new_header = 1;
          end
          else
            new_header[63:0] =  m_axis_rx_tdata[63:32];

          req_type = new_header[31:24];
          req_len = new_header[9:0];

          if (m_axis_rx_tuser[13])
            max_size = 0;
          else
          begin
            load_header_high = 1;

            if (req_type[5] == 0)  // 3 DW header
            begin
              new_header[95:64] =  m_axis_rx_tdata[95:64];
              new_header[127:96] =  32'b0;
              max_size = 1;
              start_pos = 2'b11;
            end
            else
            begin
              new_header[127:64] = m_axis_rx_tdata[127:64];
              max_size = 0;
            end
          end
        end
        else
        begin
          if (pend_strad)
          begin
            new_header[63:0] = strad_header;
            load_header_low = 1;
            req_type = new_header[31:24];
            req_len = new_header[9:0];
          end
          else
          begin
            req_type = curr_header[31:24];
            req_len = curr_header[9:0];
          end

          if (header_done)
          begin
            max_size = 4;
            start_pos = 2'b00;
          end
          else
          begin
            is_first = 1;
            load_header_high = 1;

            if (req_type[5] == 0)
            begin
              new_header[95:64] =  m_axis_rx_tdata[31:0];
              new_header[127:96] =  32'b0;
              max_size = 3;
              start_pos = 2'b01;
            end
            else
            begin
              new_header[127:64] =  m_axis_rx_tdata[63:0];
              max_size = 2;
              start_pos = 2'b10;
            end
          end
        end

        if (load_header_low)
        begin
          first_be = new_header[39:32];
          last_be = new_header[47:40];
          byte_count = new_header[43:32];
        end

        if (load_header_high)
          low_adr = new_header[65:64];
      end
    end

    always @ ( posedge clk ) 
    begin
      if (active)
      begin
        if (is_first)
        begin
          curr_pos = 0;

          if (req_type[6])
            new_size = req_len;
          else
            new_size = 0;
        end
        else
        begin
          curr_pos = sel;
          new_size = data_size;
        end

        if (max_size > new_size)
          curr_size = new_size;
        else
          curr_size = max_size;
      end
    end

    always @ ( posedge clk ) 
    begin
      if (active)
      begin
        if (req_type[3])
        begin
          if (load_header_low)
            temp_byte_count = byte_count;
          else
            temp_byte_count = curr_byte_count;

          if (load_header_high)
            temp_low_adr = low_adr;
          else
            temp_low_adr = curr_low_adr;

          case (temp_low_adr)
            2'b00: 
            begin
              case (temp_byte_count)
                1: new_first_be = 4'b0001;
                2: new_first_be = 4'b0011;
                3: new_first_be = 4'b0111;
                default: new_first_be = 4'b1111;
              endcase
            end

            2'b01:
            begin
              case (temp_byte_count)
                1: new_first_be = 4'b010;
                2: new_first_be = 4'b0110;
                default: new_first_be = 4'b1110;
              endcase
            end

            2'b10:
            begin
              if (temp_byte_count == 1)
                new_first_be = 4'b0100;
              else
                new_first_be = 4'b1100;
            end

            2'b11:
            begin
              new_first_be = 4'b1000;
            end
          endcase

          temp_low_adr = temp_low_adr + temp_byte_count[1:0];
          case (temp_low_adr)
            2'b00: new_last_be = 4'b1111;
            2'b01: new_last_be = 4'b0001;
            2'b10: new_last_be = 4'b0011;
            2'b11: new_last_be = 4'b0111;
          endcase
        end
        else
        begin
          if (load_header_low)
          begin
            new_first_be = first_be;
            new_last_be = last_be;
          end
          else
          begin
            new_first_be = curr_first_be;
            new_last_be = curr_last_be;
          end
        end
      end
    end

    always @ ( posedge clk ) 
    begin
      if (load_header_low)
      begin
        curr_header[63:0] <= new_header[63:0];
        curr_first_be <= first_be;
        curr_last_be <= last_be;
        curr_byte_count <= byte_count;
      end

      if (load_header_high)
      begin
        curr_header[127:64] <= new_header[127:64];
        curr_low_adr <= low_adr;
      end

      if (new_strad)
      begin
        strad_header <=  m_axis_rx_tdata[127:64];
        pend_strad <= 1;
      end
      else
        pend_strad <= 0;

      if (new_header || reset || new_strad)
        header_done <= 0;
      else
        header_done <= 1;
    end

    always @ ( posedge clk ) 
    begin
      if (curr_size)
      begin
        curr_data[(32*curr_pos) +: 8] <= m_axis_rx_tdata[(32*start_pos+24) +: 8];
        curr_data[(32*curr_pos+8) +: 8] <= m_axis_rx_tdata[(32*start_pos+16) +: 8];
        curr_data[(32*curr_pos+16) +: 8] <= m_axis_rx_tdata[(32*start_pos+8) +: 8];
        curr_data[(32*curr_pos+24) +: 8] <= m_axis_rx_tdata[(32*start_pos) +: 8];

        if (curr_pos)
          curr_be[4*curr_pos +: 4] <= 4'b1111;
        else
        begin
          if ((new_size == curr_size) && (curr_size == 1))
            curr_be[4*(curr_pos) +: 4] <= new_last_be;
          else
            curr_be[4*(curr_pos) +: 4] <= 4'b1111;
        end
      end
               
      if (curr_size > 1)
      begin
        curr_data[(32*(curr_pos+1)) +: 8] <= m_axis_rx_tdata[(32*start_pos+56) +: 8];
        curr_data[(32*(curr_pos+1)+8) +: 8] <= m_axis_rx_tdata[(32*start_pos+48) +: 8];
        curr_data[(32*(curr_pos+1)+16) +: 8] <= m_axis_rx_tdata[(32*start_pos+40) +: 8];
        curr_data[(32*(curr_pos+1)+24) +: 8] <= m_axis_rx_tdata[(32*start_pos+32) +: 8];

        if ((new_size == curr_size) && (curr_size == 2))
          curr_be[4*(curr_pos+1) +: 4] <= new_last_be;
        else
          curr_be[4*(curr_pos+1) +: 4] <= 4'b1111;
      end

      if (curr_size > 2)
      begin
        curr_data[(32*(curr_pos+2)) +: 8] <= m_axis_rx_tdata[(32*start_pos+88) +: 8];
        curr_data[(32*(curr_pos+2)+8) +: 8] <= m_axis_rx_tdata[(32*start_pos+80) +: 8];
        curr_data[(32*(curr_pos+2)+16) +: 8] <= m_axis_rx_tdata[(32*start_pos+72) +: 8];
        curr_data[(32*(curr_pos+2)+24) +: 8] <= m_axis_rx_tdata[(32*start_pos+64) +: 8];

        if ((new_size == curr_size) && (curr_size == 3))
          curr_be[4*(curr_pos+2) +: 4] <= new_last_be;
        else
          curr_be[4*(curr_pos+2) +: 4] <= 4'b1111;
      end

      if (curr_size > 3)
      begin
        curr_data[(32*(curr_pos+3)) +: 8] <= m_axis_rx_tdata[(32*start_pos+120) +: 8];
        curr_data[(32*(curr_pos+3)+8) +: 8] <= m_axis_rx_tdata[(32*start_pos+112) +: 8];
        curr_data[(32*(curr_pos+3)+16) +: 8] <= m_axis_rx_tdata[(32*start_pos+104) +: 8];
        curr_data[(32*(curr_pos+3)+24) +: 8] <= m_axis_rx_tdata[(32*start_pos+96) +: 8];

        if ((new_size == curr_size) && (curr_size == 4))
          curr_be[4*(curr_pos+3) +: 4] <= new_last_be;
        else
          curr_be[4*(curr_pos+3) +: 4] <= 4'b1111;
      end

      data_size <= new_size - curr_size;
      sel <= curr_pos + curr_size;
    end

    always @ ( posedge clk ) 
    begin
      if (reset )
      begin
        m_axis_rx_tready <= 0;
        bram_wr <= 0;
        bram_wr_ptr <= 0;
      end
      else
      begin
        if (active)
        begin
          if (m_axis_rx_tuser[21])
          begin
            bram_wr <= 1;             
            bram_wr_ptr <= bram_wr_ptr + 1;
          end
          else
            bram_wr <= 0;
        end
        else
          bram_wr <= 0;

        if (bram_wr_ptr + 1 == bram_rd_ptr)
          m_axis_rx_tready <= 0;
        else
        begin
          if (bram_wr_ptr + 2 == bram_rd_ptr)
            m_axis_rx_tready <= 0;
          else
            m_axis_rx_tready <= 1;
        end
      end
    end

  end    
endgenerate

endmodule
