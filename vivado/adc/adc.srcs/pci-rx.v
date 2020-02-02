module pci_rx (
  clk,
  reset,
  m_axis_rx_tdata,
  m_axis_rx_tkeep,
  m_axis_rx_tlast,
  m_axis_rx_tvalid,
  m_axis_rx_tready,
  m_axis_rx_tuser
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

  reg         req_compl;
  reg         req_compl_wd;
  
  reg [7:0]   tlp_type;

  reg [2:0]   req_tc;                        // Memory Read TC
  reg         req_td;                        // Memory Read TD
  reg         req_ep;                        // Memory Read EP
  reg [1:0]   req_attr;                      // Memory Read Attribute
  reg [9:0]   req_len;                       // Memory Read Length (1DW)
  reg [15:0]  req_rid;                       // Memory Read Requestor ID
  reg [7:0]   req_tag;                       // Memory Read Tag
  reg [7:0]   req_be;                        // Memory Read Byte Enables
  reg [11:0]  req_addr;                      // Memory Read Address

  reg [10:0]  wr_addr;                       // Memory Write Address
  reg [7:0]   wr_be;                         // Memory Write Byte Enable
  reg [31:0]  wr_data;                       // Memory Write Data
  reg         wr_en;                         // Memory Write Enable

  localparam PIO_RX_MEM_RD32_FMT_TYPE = 7'b00_00000;
  localparam PIO_RX_MEM_WR32_FMT_TYPE = 7'b10_00000;
  localparam PIO_RX_MEM_RD64_FMT_TYPE = 7'b01_00000;
  localparam PIO_RX_MEM_WR64_FMT_TYPE = 7'b11_00000;
  localparam PIO_RX_IO_RD32_FMT_TYPE  = 7'b00_00010;
  localparam PIO_RX_IO_WR32_FMT_TYPE  = 7'b10_00010;

  // Local Registers

  wire               mem32_bar_hit_n;
  reg [1:0]          region_select;

ila_0 ila_inst (
	.clk(clk), // input wire clk
    .trig_in(m_axis_rx_tuser[14]),
    .probe0(tlp_type),
	.probe1(req_tc),
	.probe2(req_td),
	.probe3(req_ep),
	.probe4(req_attr),
	.probe5(req_len),
	.probe6(req_rid),
	.probe7(req_tag),
	.probe8(req_be),
	.probe9(req_addr)
);

  generate
    begin : pio_rx_sm_128
      // Define where the start of packet happens.  Remember that PCIe dwords
      // start on the right and get filled in to the left of the 128-bit data
      // bus.
      // Start of packet can only happen on byte 0 (right most byte) or on
      // byte 8 (middle byte).
      wire               sof_present = m_axis_rx_tuser[14];
      wire               sof_right = !m_axis_rx_tuser[13] && sof_present;
      wire               sof_mid = m_axis_rx_tuser[13] && sof_present;



      always @ ( posedge clk ) begin
        if (reset )
        begin
          m_axis_rx_tready <= 1'b1;
          req_tc <= 0;
          req_td <= 0;
          req_ep <= 0;
          req_attr <= 0;
          req_len <= 0;
          req_rid <= 0;
          req_tag <= 0;
          req_be <= 0;
          req_addr <= 0;
        end // if (!rst_n )
        else
        begin
              // Packet starts in the middle of the 128-bit bus.
          if ((m_axis_rx_tvalid) && (m_axis_rx_tready))
          begin
            if (sof_mid)
            begin
              tlp_type <= m_axis_rx_tdata[95:88];
              req_len <= m_axis_rx_tdata[73:64];
              m_axis_rx_tready <= 1'b0;

              if (m_axis_rx_tdata[73:64] == 10'b1)
              begin
                case (tlp_type[6:0])
                  PIO_RX_MEM_RD32_FMT_TYPE : 
                  begin
                    req_tc <= m_axis_rx_tdata[86:84];
                    req_td <= m_axis_rx_tdata[79];
                    req_ep <= m_axis_rx_tdata[78];
                    req_attr <= m_axis_rx_tdata[77:76];
                    req_len <= m_axis_rx_tdata[73:64];
                    req_rid <= m_axis_rx_tdata[127:112];
                    req_tag <= m_axis_rx_tdata[111:104];
                    req_be <= m_axis_rx_tdata[103:96];
                  end

                  PIO_RX_MEM_WR32_FMT_TYPE : 
                  begin
                    wr_be <= m_axis_rx_tdata[103:96];
                  end

                  PIO_RX_MEM_RD64_FMT_TYPE : 
                  begin
                    req_tc <= m_axis_rx_tdata[86:84];
                    req_td <= m_axis_rx_tdata[79];
                    req_ep <= m_axis_rx_tdata[78];
                    req_attr <= m_axis_rx_tdata[77:76];
                    req_len <= m_axis_rx_tdata[73:64];
                    req_rid <= m_axis_rx_tdata[127:112];
                    req_tag <= m_axis_rx_tdata[111:104];
                    req_be <= m_axis_rx_tdata[103:96];
                  end

                  PIO_RX_MEM_WR64_FMT_TYPE : 
                  begin
                    wr_be <= m_axis_rx_tdata[103:96];
                  end
                endcase
              end
            end        
            else if (sof_right)
            begin
              tlp_type <= m_axis_rx_tdata[31:24];
              req_len <= m_axis_rx_tdata[9:0];
              m_axis_rx_tready <= 1'b0;
              if (m_axis_rx_tdata[9:0] == 10'b1)
              begin
                case (tlp_type[6:0])
                  PIO_RX_MEM_RD32_FMT_TYPE : 
                  begin
                    req_tc <= m_axis_rx_tdata[22:20];
                    req_td <= m_axis_rx_tdata[15];
                    req_ep <= m_axis_rx_tdata[14];
                    req_attr <= m_axis_rx_tdata[13:12];
                    req_len <= m_axis_rx_tdata[9:0];
                    req_rid <= m_axis_rx_tdata[63:48];
                    req_tag <= m_axis_rx_tdata[47:40];
                    req_be <= m_axis_rx_tdata[39:32];
                    req_addr <= {m_axis_rx_tdata[74:66],2'b00};
                    req_compl <= 1'b1;
                    req_compl_wd <= 1'b1;
                  end

                  PIO_RX_MEM_WR32_FMT_TYPE : 
                  begin
                    wr_be <= m_axis_rx_tdata[39:32];
                    wr_data <= m_axis_rx_tdata[127:96];
                    wr_en <= 1'b1;
                    wr_addr <= {m_axis_rx_tdata[74:66]};
                    wr_en <= 1'b1;
                  end

                  PIO_RX_MEM_RD64_FMT_TYPE : 
                  begin
                    req_tc <= m_axis_rx_tdata[22:20];
                    req_td <= m_axis_rx_tdata[15];
                    req_ep <= m_axis_rx_tdata[14];
                    req_attr <= m_axis_rx_tdata[13:12];
                    req_len <= m_axis_rx_tdata[9:0];
                    req_rid <= m_axis_rx_tdata[63:48];
                    req_tag <= m_axis_rx_tdata[47:40];
                    req_be <= m_axis_rx_tdata[39:32];
                    req_addr <= {m_axis_rx_tdata[74:66],2'b00};
                    req_compl <= 1'b1;
                    req_compl_wd <= 1'b1;
                  end

                  PIO_RX_MEM_WR64_FMT_TYPE : 
                  begin
                    wr_be <= m_axis_rx_tdata[39:32];
                    wr_addr <= {m_axis_rx_tdata[74:66]};
                  end

                  PIO_RX_IO_RD32_FMT_TYPE : 
                  begin
                    req_tc <= m_axis_rx_tdata[22:20];
                    req_td <= m_axis_rx_tdata[15];
                    req_ep <= m_axis_rx_tdata[14];
                    req_attr <= m_axis_rx_tdata[13:12];
                    req_len <= m_axis_rx_tdata[9:0];
                    req_rid <= m_axis_rx_tdata[63:48];
                    req_tag <= m_axis_rx_tdata[47:40];
                    req_be <= m_axis_rx_tdata[39:32];
                    req_addr <= {m_axis_rx_tdata[74:66],2'b00};
                    req_compl <= 1'b1;
                    req_compl_wd <= 1'b1;
                  end
                endcase
              end
            end
          end
        end // if rst_n
      end // always

    end // pio_rx_sm_128
  endgenerate

  assign    mem32_bar_hit_n = ~(m_axis_rx_tuser[2]);

endmodule
