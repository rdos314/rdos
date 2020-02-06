module pci_rx (
  clk,
  reset,
  m_axis_rx_tdata,
  m_axis_rx_tkeep,
  m_axis_rx_tlast,
  m_axis_rx_tvalid,
  m_axis_rx_tready,
  m_axis_rx_tuser,
  
  fifo_data,
  fifo_wr,
  fifo_full,

  wr_active,
  wr_index,
  wr_data
);

  input                         clk;
  input                         reset;

  input      [127:0]            m_axis_rx_tdata;
  input      [15:0]             m_axis_rx_tkeep;
  input                         m_axis_rx_tlast;
  input                         m_axis_rx_tvalid;
  output reg                    m_axis_rx_tready;
  input      [21:0]             m_axis_rx_tuser;

  output reg [131:0]            fifo_data;
  output reg                    fifo_wr;
  input  wire                   fifo_full;

  output reg                    wr_active;
  output reg [3:0]              wr_index;
  output reg [1023:0]           wr_data;

// local variables

  reg [4:0]   data_pos;
  reg [4:0]   data_size;
  reg         header_done;
  reg         pend_strad;
  reg [3:0]   used_index;
  
  reg [7:0]   req_type;
  reg         req_wr;
  reg [9:0]   req_len;
  reg [31:0]  req_header   [1:0];
  reg [31:0]  req_address  [1:0];
  reg [31:0]  req_data    [31:0];
  reg [31:0]  strad_header [1:0];

  generate
    begin : pci_rx_128

      always @ ( posedge clk ) 
      begin
        sdram_wr = 1'b0;
        rd_par_active = 1'b0;
        wr_active = 1'b0;

        if (reset )
        begin
          m_axis_rx_tready = 1'b0;
          rd_par_index = 4'b1111;
          wr_index = 4'b1111;
          pend_strad = 1'b0;
        end
        else
        begin
          if (m_axis_rx_tvalid && m_axis_rx_tready)
          begin
            if (pend_strad)
            begin
              req_header[1] =  strad_header[1];
              req_header[0] =  strad_header[0];

              req_type = req_header[0][31:24];
              req_len = req_header[0][9:0];
              req_wr = req_type[6];

              if (req_wr)
                data_size = req_len;
              else
                data_size = 0;
              header_done = 1'b0;
            end

            if (m_axis_rx_tuser[14] && m_axis_rx_tuser[21])  // straddled
            begin
              strad_header[1] =  m_axis_rx_tdata[127:96];
              strad_header[0] =  m_axis_rx_tdata[95:64];
              pend_strad = 1'b1;
            end
            else
              pend_strad = 1'b0;

            if (m_axis_rx_tuser[14] && !pend_strad)  // is first part of TLP
            begin
              if (m_axis_rx_tuser[13])  // header in high part of data
              begin
                req_header[1] =  m_axis_rx_tdata[127:96];
                req_header[0] =  m_axis_rx_tdata[95:64];
                header_done = 1'b0;
              end
              else
              begin
                req_header[1] =  m_axis_rx_tdata[63:32];
                req_header[0] =  m_axis_rx_tdata[31:0];
                header_done = 1'b1;
              end

              req_type = req_header[0][31:24];
              req_len = req_header[0][9:0];
              req_wr = req_type[6];

              if (req_wr)
                data_size = req_len;
              else
                data_size = 0;

              if (!m_axis_rx_tuser[13])  // header in low part of data
              begin
                if (req_type[5] == 1'b0)  // 3 DW header
                begin
                  if (data_size)
                  begin
                    req_data[0][7:0] = m_axis_rx_tdata[127:120];
                    req_data[0][15:8] = m_axis_rx_tdata[119:112];
                    req_data[0][23:16] = m_axis_rx_tdata[111:104];
                    req_data[0][31:24] = m_axis_rx_tdata[103:96];
                    data_pos = 1;
                    data_size = data_size - 1;
                  end

                  req_address[0] =  m_axis_rx_tdata[95:64];
                  req_address[1] =  32'b0;
                end
                else
                begin
                  data_pos = 0;

                  req_address[0] =  m_axis_rx_tdata[127:96];
                  req_address[1] =  m_axis_rx_tdata[95:64];
                end
              end
            end
            else
            begin
              if (header_done)
              begin
                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[31:24];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[23:16];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[15:8];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[7:0];
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end
 
                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[63:56];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[55:48];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[47:40];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[39:32];
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[95:88];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[87:80];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[79:72];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[71:64];
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[127:120];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[119:112];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[111:104];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[103:96];
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end
              end
              else
              begin
                if (req_type[5] == 0)  // 3 DW header
                begin
                  if (data_size)
                  begin
                    req_data[0][7:0] = m_axis_rx_tdata[63:56];
                    req_data[0][15:8] = m_axis_rx_tdata[55:48];
                    req_data[0][23:16] = m_axis_rx_tdata[47:40];
                    req_data[0][31:24] = m_axis_rx_tdata[39:32];
                    data_pos = 1;
                    data_size = data_size - 1;
                  end                    

                  req_address[0] =  m_axis_rx_tdata[31:0];
                  req_address[1] =  32'b0;
                end
                else
                begin
                  data_pos = 0;

                  req_address[0] =  m_axis_rx_tdata[63:32];
                  req_address[1] =  m_axis_rx_tdata[31:0];
                end

                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[95:88];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[87:80];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[79:72];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[71:64];
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[127:120];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[119:112];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[111:104];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[103:96];
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end

                header_done = 1'b1;
              end
            end
                       
            if (m_axis_rx_tuser[21]) // is final part of TLP
            begin
              fifo_data[0] = req_wr;                        // write req
              fifo_data[1] = m_axis_rx_tuser[2];            // BAR0 hit
              fifo_data[31:2] = req_address[0][31:2];       // low address
              fifo_data[63:32] = req_address[1][31:0];      // high address
              fifo_data[95:64] = req_header[0][31:0];       // header 0 
              fifo_data[127:96] = req_header[1][31:0];      // header 1

              if (req_wr)
              begin
                wr_data[31:0] = req_data[0][31:0];
                wr_data[63:32] = req_data[1][31:0];
                wr_data[95:64] = req_data[2][31:0];
                wr_data[127:96] = req_data[3][31:0];
                wr_data[159:128] = req_data[4][31:0];
                wr_data[191:160] = req_data[5][31:0];
                wr_data[223:192] = req_data[6][31:0];
                wr_data[255:224] = req_data[7][31:0];
                wr_data[287:256] = req_data[8][31:0];
                wr_data[319:288] = req_data[9][31:0];
                wr_data[351:320] = req_data[10][31:0];
                wr_data[383:352] = req_data[11][31:0];
                wr_data[415:384] = req_data[12][31:0];
                wr_data[447:416] = req_data[13][31:0];
                wr_data[479:448] = req_data[14][31:0];
                wr_data[511:480] = req_data[15][31:0];
                wr_data[543:512] = req_data[16][31:0];
                wr_data[575:544] = req_data[17][31:0];
                wr_data[607:576] = req_data[18][31:0];
                wr_data[639:608] = req_data[19][31:0];
                wr_data[671:640] = req_data[20][31:0];
                wr_data[703:672] = req_data[21][31:0];
                wr_data[735:704] = req_data[22][31:0];
                wr_data[767:736] = req_data[23][31:0];
                wr_data[799:768] = req_data[24][31:0];
                wr_data[831:800] = req_data[25][31:0];
                wr_data[863:832] = req_data[26][31:0];
                wr_data[895:864] = req_data[27][31:0];
                wr_data[927:896] = req_data[28][31:0];
                wr_data[959:928] = req_data[29][31:0];
                wr_data[991:960] = req_data[30][31:0];
                wr_data[1023:992] = req_data[31][31:0];

                wr_index = wr_index + 1;
                fifo_data[131:128] = wr_index[3:0];
                wr_active = 1'b1;
              end
              else
                fifo_data[131:128] = 4'b0;

              fifo_wr = 1;             
            end
          end

          m_axis_rx_tready = !fifo_full;
        end
      end
    end
  endgenerate

endmodule
