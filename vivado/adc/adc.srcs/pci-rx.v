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
  reg         header_done;
  
  reg [7:0]   tlp_type;                      // TLP
  reg [9:0]   req_len;                       // Length (1DW)
  reg         req_wr;
 
  reg [31:0]  tlp_header  [1:0];
  reg [31:0]  tlp_address [1:0];
  reg [31:0]  tlp_data   [31:0];

  generate
    begin : pci_rx_128

      always @ ( posedge clk ) 
      begin
        if (reset )
        begin
          m_axis_rx_tready = 1'b0;
          rd_par_active = 1'b0;
          rd_par_index = 4'b1111;
          sdram_wr = 1'b0;
        end
        else
        begin
          m_axis_rx_tready = !sdram_full;
          rd_par_active = 1'b0;
          sdram_wr = 1'b0;

          if ((m_axis_rx_tvalid) && (m_axis_rx_tready))
          begin
            if (m_axis_rx_tuser[14])  // is first part of TLP
            begin
              if (m_axis_rx_tuser[13])  // header in high part of data
              begin
                tlp_header[1] =  m_axis_rx_tdata[127:96];
                tlp_header[0] =  m_axis_rx_tdata[95:64];

                tlp_type = tlp_header[0][31:24];
                header_done = 1'b0;
              end
              else
              begin
                tlp_header[1] =  m_axis_rx_tdata[63:32];
                tlp_header[0] =  m_axis_rx_tdata[31:0];

                tlp_type = tlp_header[0][31:24];
                header_done = 1'b1;

                if (tlp_type[5] == 1'b0)  // 3 DW header
                begin
                  tlp_data[0][7:0] = m_axis_rx_tdata[127:120];
                  tlp_data[0][15:8] = m_axis_rx_tdata[119:112];
                  tlp_data[0][23:16] = m_axis_rx_tdata[111:104];
                  tlp_data[0][31:24] = m_axis_rx_tdata[103:96];
                  data_pos = 1;

                  tlp_address[0] =  m_axis_rx_tdata[95:64];
                  tlp_address[1] =  32'b0;
                end
                else
                begin
                  data_pos = 0;

                  tlp_address[0] =  m_axis_rx_tdata[127:96];
                  tlp_address[1] =  m_axis_rx_tdata[95:64];
                end
              end

              req_len = tlp_header[0][9:0];
              req_wr = tlp_type[6];

            end
            else
            begin
              if (header_done)
              begin              
                tlp_data[data_pos][7:0] = m_axis_rx_tdata[31:24];
                tlp_data[data_pos][15:8] = m_axis_rx_tdata[23:16];
                tlp_data[data_pos][23:16] = m_axis_rx_tdata[15:8];
                tlp_data[data_pos][31:24] = m_axis_rx_tdata[7:0];
                data_pos = data_pos + 1;
 
                if (data_pos)
                begin
                  tlp_data[data_pos][7:0] = m_axis_rx_tdata[63:56];
                  tlp_data[data_pos][15:8] = m_axis_rx_tdata[55:48];
                  tlp_data[data_pos][23:16] = m_axis_rx_tdata[47:40];
                  tlp_data[data_pos][31:24] = m_axis_rx_tdata[39:32];
                  data_pos = data_pos + 1;
                end

                if (data_pos)
                begin
                  tlp_data[data_pos][7:0] = m_axis_rx_tdata[95:88];
                  tlp_data[data_pos][15:8] = m_axis_rx_tdata[87:80];
                  tlp_data[data_pos][23:16] = m_axis_rx_tdata[79:72];
                  tlp_data[data_pos][31:24] = m_axis_rx_tdata[71:64];
                  data_pos = data_pos + 1;
                end

                if (data_pos)
                begin
                  tlp_data[data_pos][7:0] = m_axis_rx_tdata[127:120];
                  tlp_data[data_pos][15:8] = m_axis_rx_tdata[119:112];
                  tlp_data[data_pos][23:16] = m_axis_rx_tdata[111:104];
                  tlp_data[data_pos][31:24] = m_axis_rx_tdata[103:96];
                  data_pos = data_pos + 1;
                end
              end
              else
              begin
                if (tlp_type[5] == 0)  // 3 DW header
                begin
                  tlp_data[0][7:0] = m_axis_rx_tdata[63:56];
                  tlp_data[0][15:8] = m_axis_rx_tdata[55:48];
                  tlp_data[0][23:16] = m_axis_rx_tdata[47:40];
                  tlp_data[0][31:24] = m_axis_rx_tdata[39:32];
                  data_pos = 1;

                  tlp_address[0] =  m_axis_rx_tdata[31:0];
                  tlp_address[1] =  32'b0;
                end
                else
                begin
                  data_pos = 0;

                  tlp_address[0] =  m_axis_rx_tdata[63:32];
                  tlp_address[1] =  m_axis_rx_tdata[31:0];
                end

                tlp_data[data_pos][7:0] = m_axis_rx_tdata[95:88];
                tlp_data[data_pos][15:8] = m_axis_rx_tdata[87:80];
                tlp_data[data_pos][23:16] = m_axis_rx_tdata[79:72];
                tlp_data[data_pos][31:24] = m_axis_rx_tdata[71:64];
                data_pos = data_pos + 1;

                tlp_data[data_pos][7:0] = m_axis_rx_tdata[127:120];
                tlp_data[data_pos][15:8] = m_axis_rx_tdata[119:112];
                tlp_data[data_pos][23:16] = m_axis_rx_tdata[111:104];
                tlp_data[data_pos][31:24] = m_axis_rx_tdata[103:96];
                data_pos = data_pos + 1;

                header_done = 1'b1;
              end
            end
                       
            if (m_axis_rx_tuser[21]) // is final part of TLP
            begin
              sdram_fifo[16:0] = tlp_header[2][18:2];        // SDRAM dword address
              sdram_fifo[17] = req_wr;
              sdram_fifo[18] = m_axis_rx_tuser[2];           // BAR0 hit
              sdram_fifo[23:19] = 5'b0;                      // spare bits
              sdram_wr = 1;             

              if (!req_wr)
              {
                rd_par_data[9:0] = tlp_header[0][9:0];       // len
                rd_par_data[11:10] = 2'b0;                   // AT
                rd_par_data[13:12] = tlp_header[0][13:12];   // Attr
                rd_par_data[14] = tlp_header[0][14];         // EP
                rd_par_data[15] = tlp_header[0][15];         // TD
                rd_par_data[19:16] = 4'b0;                   // TH, AttrH, R
                rd_par_data[22:20] = tlp_header[0][22:20];   // TC
                rd_par_data[23] = 1'b0;                      // R
                rd_par_data[24] = tlp_type[0];               // Copy locked bit

                if (req_len)
                    rd_par_data[31:25] = 6'b10_0101;         // Type + Fmt (data)
                else
                    rd_par_data[31:25] = 6'b00_0101;         // Type + Fmt (no data)

                rd_par_data[38:32] = tlp_header[2][6:0];     // Lower address
                rd_par_data[39] = 1'b0;                      // R
                rd_par_data[47:40] = tlp_header[1][15:8];    // Tag
                rd_par_data[63:48] = tlp_header[1][31:16];   // Requester ID
                rd_par_index = rd_par_index + 1;
                rd_par_active = 1'b1;
              end

            end
          end
        end
      end
    end
  endgenerate

endmodule
