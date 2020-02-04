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

  // AXI-S
  input  [127:0]                m_axis_rx_tdata;
  input  [15:0]                 m_axis_rx_tkeep;
  input                         m_axis_rx_tlast;
  input                         m_axis_rx_tvalid;
  output reg                    m_axis_rx_tready;
  input    [21:0]               m_axis_rx_tuser;

  output reg [23:0]   sdram_fifo;
  output reg          sdram_wr;
  input  wire         sdram_full;

  output reg          rd_par_active;
  output reg [3:0]    rd_par_index;
  output reg [31:0]   rd_par_data;
  
  reg [7:0]   tlp_type;                      // TLP
  reg [2:0]   req_tc;                        // TC
  reg         req_td;                        // TD
  reg         req_ep;                        // EP
  reg [1:0]   req_attr;                      // Attribute
  reg [9:0]   req_len;                       // Length (1DW)
  reg [15:0]  req_rid;                       // Requestor ID
  reg [7:0]   req_tag;                       // Tag

  reg [7:0]   req_be;                        // Byte Enables

  reg [3:0]   header_size;
  reg [3:0]   header_pos;
  reg [9:0]   data_size;
  reg         wr_op;
 
  reg [31:0]  header [3:0]; 
  
  localparam PIO_RX_MEM_RD32_FMT_TYPE = 7'b00_00000;
  localparam PIO_RX_MEM_WR32_FMT_TYPE = 7'b10_00000;
  localparam PIO_RX_MEM_RD64_FMT_TYPE = 7'b01_00000;
  localparam PIO_RX_MEM_WR64_FMT_TYPE = 7'b11_00000;
  localparam PIO_RX_IO_RD32_FMT_TYPE  = 7'b00_00010;
  localparam PIO_RX_IO_WR32_FMT_TYPE  = 7'b10_00010;

  generate
    begin : pio_rx_sm_128

      always @ ( posedge clk ) 
      begin
        if (reset )
        begin
          m_axis_rx_tready = 1'b0;
          req_tc = 0;
          req_td = 0;
          req_ep = 0;
          req_attr = 0;
          req_len = 0;
          req_rid = 0;
          req_tag = 0;
          req_be = 0;
          sdram_wr = 0;
          rd_par_active = 0;
          rd_par_index = 4'b1111;
        end // if (!rst_n )
        else
        begin
          m_axis_rx_tready = !sdram_full;
         sdram_wr = 0;              
         rd_par_active = 0;

          if ((m_axis_rx_tvalid) && (m_axis_rx_tready))
          begin
            if (m_axis_rx_tuser[14])
            begin
              if (m_axis_rx_tuser[13])
              begin
                if (m_axis_rx_tdata[73:64] == 10'b1)
                begin
                  header[1] =  m_axis_rx_tdata[127:96];
                  header[0] =  m_axis_rx_tdata[95:64];
                  header_pos = 2;
                end
              end
              else
              begin
                if (m_axis_rx_tdata[9:0] == 10'b1)
                begin
                  header[3] =  m_axis_rx_tdata[127:96];
                  header[2] =  m_axis_rx_tdata[95:64];
                  header[1] =  m_axis_rx_tdata[63:32];
                  header[0] =  m_axis_rx_tdata[31:0];
                  header_pos = 4;
                end
              end
            end
            else
            begin
              if (header_pos != 4)
              begin
                case (header_size)
                  3 : 
                  begin
                    header[2] =  m_axis_rx_tdata[31:0];
                  end
                  4 :
                  begin
                    header[3] =  m_axis_rx_tdata[63:32];
                    header[2] =  m_axis_rx_tdata[31:0];
                  end
                endcase
                header_pos = 4;
              end
            end
                       
            if (m_axis_rx_tuser[21])
            begin
              tlp_type = header[0][31:24];
              req_len = header[0][9:0];
              if (req_len)
                data_size = 1 + (req_len - 1) >> 2;
              else
                data_size = 0;

              req_tc = header[0][22:20];
              req_td = header[0][15];
              req_ep = header[0][14];
              req_attr = header[0][13:12];
              req_rid = header[1][31:16];
              req_tag = header[1][15:8];
              req_be = header[1][7:0];
                
              case (tlp_type)
                PIO_RX_MEM_RD32_FMT_TYPE : 
                begin
                  header_size = 3;
                  data_size = 0;
                  wr_op = 0;
                end
                  
                PIO_RX_MEM_WR32_FMT_TYPE : 
                begin
                  header_size = 3;
                  wr_op = 1;
                end

                PIO_RX_MEM_RD64_FMT_TYPE : 
                begin
                  header_size = 4;
                  data_size = 0;
                  wr_op = 0;
                end
                  
                PIO_RX_MEM_WR64_FMT_TYPE : 
                begin
                  header_size = 4;
                  wr_op = 1;
                end
                  
                PIO_RX_IO_RD32_FMT_TYPE : 
                begin
                  header_size = 3;
                  data_size = 0;
                  wr_op = 0;
                end

                PIO_RX_IO_WR32_FMT_TYPE : 
                begin
                  header_size = 3;
                  wr_op = 1;
                end
              endcase

              sdram_fifo[0] = wr_op;
              sdram_fifo[1] = m_axis_rx_tuser[2];
              sdram_fifo[2] = 1;
              sdram_fifo[6:3] = 0;
              sdram_fifo[23:7] = header[2][18:2];
              sdram_wr = 1;             

              rd_par_data[9:0] = req_len;
              rd_par_data[11:10] = 0;
              rd_par_data[13:12] = req_attr;
              rd_par_data[14] = req_ep;
              rd_par_data[15] = req_td;
              rd_par_data[19:16] = 0;
              rd_par_data[22:20] = req_tc;
              rd_par_data[31:23] = 0;
              rd_par_index = rd_par_index + 1;
              rd_par_active = 1;
            end
          end
        end // if rst_n
      end // always
    end // pio_rx_sm_128
  endgenerate

endmodule
