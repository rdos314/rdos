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

  reg [1023:0]       packet_data;
  reg [127:0]        packet_keep;
  reg [2:0]          byte_counter;

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
        if (reset )
        begin
          m_axis_rx_tready <= 1'b0;
          byte_counter = 0;
        end // if (!rst_n )
        else
        begin
          m_axis_rx_tready  <= 1'b1;
          
          if (m_axis_rx_tvalid)
          begin
            case (byte_counter)
              3'b111: packet_data[1023:896] = m_axis_rx_tdata;
              3'b110: packet_data[897:768] = m_axis_rx_tdata;
              3'b101: packet_data[767:640] = m_axis_rx_tdata;
              3'b100: packet_data[639:512] = m_axis_rx_tdata;
              3'b011: packet_data[511:384] = m_axis_rx_tdata;
              3'b010: packet_data[383:256] = m_axis_rx_tdata;
              3'b001: packet_data[255:128] = m_axis_rx_tdata;
              3'b000: packet_data[127:0] = m_axis_rx_tdata;
            endcase

            case (byte_counter)
              3'b111: packet_keep[127:112] = m_axis_rx_tkeep;
              3'b110: packet_keep[111:96] = m_axis_rx_tkeep;
              3'b101: packet_keep[95:80] = m_axis_rx_tkeep;
              3'b100: packet_keep[79:64] = m_axis_rx_tkeep;
              3'b011: packet_keep[63:48] = m_axis_rx_tkeep;
              3'b010: packet_keep[47:32] = m_axis_rx_tkeep;
              3'b001: packet_keep[31:16] = m_axis_rx_tkeep;
              3'b000: packet_keep[15:0] = m_axis_rx_tkeep;
            endcase
            
            byte_counter = byte_counter + 1;
          end

        end // if rst_n
      end // always

    end // pio_rx_sm_128
  endgenerate

  assign    mem32_bar_hit_n = ~(m_axis_rx_tuser[2]);

endmodule
