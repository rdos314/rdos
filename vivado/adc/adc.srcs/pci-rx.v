module pci_rx (
  clk,
  reset,
  m_axis_rx_tdata,
  m_axis_rx_tkeep,
  m_axis_rx_tlast,
  m_axis_rx_tvalid,
  m_axis_rx_tready,
  m_axis_rx_tuser,
  
  sdram_fifo,
  sdram_wr,
  sdram_full,
  rd_par_active,
  rd_par_index,
  rd_par_data
);

  input                         clk;
  input                         reset;

  input      [127:0]            m_axis_rx_tdata;
  input      [15:0]             m_axis_rx_tkeep;
  input                         m_axis_rx_tlast;
  input                         m_axis_rx_tvalid;
  output reg                    m_axis_rx_tready;
  input      [21:0]             m_axis_rx_tuser;

  output reg [23:0]             sdram_fifo;
  output reg                    sdram_wr;
  input  wire                   sdram_full;

  output reg                    rd_par_active;
  output reg [3:0]              rd_par_index;
  output reg [63:0]             rd_par_data;

// local variables

  reg [4:0]   data_pos;
  reg [4:0]   data_size;
  reg         header_done;
  
  reg [7:0]   req_type;
  reg         req_wr;
  reg [9:0]   req_len;
  reg [31:0]  req_header  [1:0];
  reg [31:0]  req_address [1:0];
  reg [31:0]  req_data   [31:0];
  reg [3:0]   req_be     [31:0];

  generate
    begin : pci_rx_128

      always @ ( posedge clk ) 
      begin
        rd_par_active = 1'b0;
        sdram_wr = 1'b0;

        if (reset )
        begin
          m_axis_rx_tready = 1'b0;
          rd_par_index = 4'b1111;
        end
        else
        begin
          if (m_axis_rx_tvalid && m_axis_rx_tready)
          begin
            if (m_axis_rx_tuser[14])  // is first part of TLP
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
                  req_be[data_pos] = 4'b1111;       
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end
 
                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[63:56];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[55:48];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[47:40];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[39:32];
                  req_be[data_pos] = 4'b1111;       
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[95:88];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[87:80];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[79:72];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[71:64];
                  req_be[data_pos] = 4'b1111;       
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[127:120];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[119:112];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[111:104];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[103:96];
                  req_be[data_pos] = 4'b1111;       
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
                  req_be[data_pos] = 4'b1111;       
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  req_data[data_pos][7:0] = m_axis_rx_tdata[127:120];
                  req_data[data_pos][15:8] = m_axis_rx_tdata[119:112];
                  req_data[data_pos][23:16] = m_axis_rx_tdata[111:104];
                  req_data[data_pos][31:24] = m_axis_rx_tdata[103:96];
                  req_be[data_pos] = 4'b1111;       
                  data_pos = data_pos + 1;
                  data_size = data_size - 1;
                end

                header_done = 1'b1;
              end
            end
                       
            if (m_axis_rx_tuser[21]) // is final part of TLP
            begin
              req_be[0] = req_header[1][3:0];

              if (req_len > 1)
                req_be[req_len - 1] = req_header[1][7:4];

              sdram_fifo[0] = req_wr;                        // write req
              sdram_fifo[1] = 1'b0;                          // spare
              sdram_fifo[18:2] = req_address[0][18:2];       // SDRAM dword address
              sdram_fifo[22:19] = 4'b0;                      // spare bits
              sdram_fifo[23] = m_axis_rx_tuser[2];           // BAR0 hit
              sdram_wr = 1;             

              if (!req_wr)
              {
                rd_par_data[9:0] = req_header[0][9:0];       // len
                rd_par_data[11:10] = 2'b0;                   // AT
                rd_par_data[13:12] = req_header[0][13:12];   // Attr
                rd_par_data[14] = req_header[0][14];         // EP
                rd_par_data[15] = req_header[0][15];         // TD
                rd_par_data[19:16] = 4'b0;                   // TH, AttrH, R
                rd_par_data[22:20] = req_header[0][22:20];   // TC
                rd_par_data[23] = 1'b0;                      // R
                rd_par_data[24] = req_type[0];               // Copy locked bit

                if (req_len)
                    rd_par_data[31:25] = 6'b10_0101;         // Type + Fmt (data)
                else
                    rd_par_data[31:25] = 6'b00_0101;         // Type + Fmt (no data)

                rd_par_data[38:32] = req_address[0][6:0];    // Lower address
                rd_par_data[39] = 1'b0;                      // R
                rd_par_data[47:40] = req_header[1][15:8];    // Tag
                rd_par_data[63:48] = req_header[1][31:16];   // Requester ID
                rd_par_index = rd_par_index + 1;
                rd_par_active = 1'b1;
              end

            end
          end

          m_axis_rx_tready = !sdram_full;
        end
      end
    end
  endgenerate

endmodule
