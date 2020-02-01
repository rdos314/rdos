module pci_rx (
  clk,
  sys_rst_n,
  m_axis_rx_tdata,
  m_axis_rx_tkeep,
  m_axis_rx_tlast,
  m_axis_rx_tvalid,
  m_axis_rx_tready,
  m_axis_rx_tuser
);

  input                         clk;
  input                         sys_rst_n;

  // AXI-S
  input  [128:0]                m_axis_rx_tdata;
  input  [15:0]                 m_axis_rx_tkeep;
  input                         m_axis_rx_tlast;
  input                         m_axis_rx_tvalid;
  output reg                    m_axis_rx_tready;
  input    [21:0]               m_axis_rx_tuser;

  localparam RX_MEM_RD32_FMT_TYPE = 7'b00_00000;
  localparam RX_MEM_WR32_FMT_TYPE = 7'b10_00000;
  localparam RX_MEM_RD64_FMT_TYPE = 7'b01_00000;
  localparam RX_MEM_WR64_FMT_TYPE = 7'b11_00000;
  localparam RX_IO_RD32_FMT_TYPE  = 7'b00_00010;
  localparam RX_IO_WR32_FMT_TYPE  = 7'b10_00010;

  // Local Registers

  wire               mem32_bar_hit_n;
  reg [1:0]          region_select;

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
        if (!sys_rst_n )
        begin
          m_axis_rx_tready <= 1'b0;
        end // if (!rst_n )
        else
        begin
          m_axis_rx_tready  <= 1'b1;
        end // if rst_n
      end // always

    end // pio_rx_sm_128
  endgenerate

  assign    mem32_bar_hit_n = ~(m_axis_rx_tuser[2]);

endmodule
