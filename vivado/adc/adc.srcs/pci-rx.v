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
  bram_rd_ptr,
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

  output reg  [1023:0]           bram_data;
  output reg  [191:0]            bram_header;
  input  wire [3:0]              bram_rd_ptr;
  output reg  [3:0]              bram_wr_ptr;
  output reg                     bram_wr;


// local variables

  reg [3:0]    sel;
  reg [3:0]    data_size;
  reg          header_done;
  reg          pend_strad;
  
  reg [7:0]    req_type;
  reg          req_wr;
  reg [9:0]    req_len;
  reg [31:0]   req_header   [1:0];
  reg [31:0]   req_address  [1:0];
  reg [31:0]   strad_header [1:0];

  generate
    begin : pci_rx_128

      always @ ( posedge clk ) 
      begin
        if (bram_wr)
        begin
          bram_wr_ptr = bram_wr_ptr + 1;
          bram_wr = 0;
        end

        if (reset )
        begin
          m_axis_rx_tready = 0;
          pend_strad = 0;
          bram_wr = 0;
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

              sel = 0;

              if (!m_axis_rx_tuser[13])  // header in low part of data
              begin
                if (req_type[5] == 1'b0)  // 3 DW header
                begin
                  if (data_size)
                  begin
                    bram_data[7:0] = m_axis_rx_tdata[127:120];
                    bram_data[15:8] = m_axis_rx_tdata[119:112];
                    bram_data[23:16] = m_axis_rx_tdata[111:104];
                    bram_data[31:24] = m_axis_rx_tdata[103:96];
                    sel = 1;
                    data_size = data_size - 1;
                  end

                  req_address[0] =  m_axis_rx_tdata[95:64];
                  req_address[1] =  32'b0;
                end
                else
                begin
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
                  bram_data[(32*sel) +: 8] = m_axis_rx_tdata[31:24];
                  bram_data[(32*sel+8) +: 8] = m_axis_rx_tdata[23:16];
                  bram_data[(32*sel+16) +: 8] = m_axis_rx_tdata[15:8];
                  bram_data[(32*sel+24) +: 8] = m_axis_rx_tdata[7:0];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end
 
                if (data_size)
                begin
                  bram_data[(32*sel) +: 8] = m_axis_rx_tdata[63:56];
                  bram_data[(32*sel+8) +: 8] = m_axis_rx_tdata[55:48];
                  bram_data[(32*sel+16) +: 8] = m_axis_rx_tdata[47:40];
                  bram_data[(32*sel+24) +: 8] = m_axis_rx_tdata[39:32];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  bram_data[(32*sel) +: 8] = m_axis_rx_tdata[95:88];
                  bram_data[(32*sel+8) +: 8] = m_axis_rx_tdata[87:80];
                  bram_data[(32*sel+16) +: 8] = m_axis_rx_tdata[79:72];
                  bram_data[(32*sel+24) +: 8] = m_axis_rx_tdata[71:64];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  bram_data[(32*sel) +: 8] = m_axis_rx_tdata[127:120];
                  bram_data[(32*sel+8) +: 8] = m_axis_rx_tdata[119:112];
                  bram_data[(32*sel+16) +: 8] = m_axis_rx_tdata[111:104];
                  bram_data[(32*sel+24) +: 8] = m_axis_rx_tdata[103:96];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end
              end
              else
              begin
                sel = 0;

                if (req_type[5] == 0)  // 3 DW header
                begin
                  if (data_size)
                  begin
                    bram_data[7:0] = m_axis_rx_tdata[63:56];
                    bram_data[15:8] = m_axis_rx_tdata[55:48];
                    bram_data[23:16] = m_axis_rx_tdata[47:40];
                    bram_data[31:24] = m_axis_rx_tdata[39:32];
                    sel = 1;
                    data_size = data_size - 1;
                  end                    

                  req_address[0] =  m_axis_rx_tdata[31:0];
                  req_address[1] =  32'b0;
                end
                else
                begin
                  req_address[0] =  m_axis_rx_tdata[63:32];
                  req_address[1] =  m_axis_rx_tdata[31:0];
                end

                if (data_size)
                begin
                  bram_data[(32*sel) +: 8] = m_axis_rx_tdata[95:88];
                  bram_data[(32*sel+8) +: 8] = m_axis_rx_tdata[87:80];
                  bram_data[(32*sel+16) +: 8] = m_axis_rx_tdata[79:72];
                  bram_data[(32*sel+24) +: 8] = m_axis_rx_tdata[71:64];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  bram_data[(32*sel) +: 8] = m_axis_rx_tdata[127:120];                  
                  bram_data[(32*sel+8) +: 8] = m_axis_rx_tdata[119:112];
                  bram_data[(32*sel+16) +: 8] = m_axis_rx_tdata[111:104];
                  bram_data[(32*sel+24) +: 8] = m_axis_rx_tdata[103:96];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end

                header_done = 1'b1;
              end
            end
                       
            if (m_axis_rx_tuser[21]) // is final part of TLP
            begin
              bram_header[31:0] = req_header[0];        // header 0 
              bram_header[63:32] = req_header[1];       // header 1
              bram_header[95:64] = req_address[0];      // low address
              bram_header[127:96] = req_address[1];     // high address
              bram_header[128] = m_axis_rx_tuser[2];    // BAR0 hit

              bram_wr = 1;             
            end
          end

          if (bram_wr_ptr + 1 == bram_rd_ptr)
            m_axis_rx_tready = 0;
          else
            m_axis_rx_tready = 1;

        end
      end
    end
  endgenerate

endmodule
