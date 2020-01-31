module pci_tx (
  clk,
  rst_n,
  s_axis_tx_tready,
  s_axis_tx_tdata,
  s_axis_tx_tkeep,
  s_axis_tx_tlast,
  s_axis_tx_tvalid
);

  input             clk;
  input             rst_n;

  // AXIS
  input                           s_axis_tx_tready;
  output  reg [127:0]             s_axis_tx_tdata;
  output  reg [15:0]              s_axis_tx_tkeep;
  output  reg                     s_axis_tx_tlast;
  output  reg                     s_axis_tx_tvalid;

localparam CPLD_FMT_TYPE      = 7'b10_01010;
localparam CPL_FMT_TYPE       = 7'b00_01010;
localparam TX_RST_STATE       = 2'b00;
localparam TX_CPLD_QW1_FIRST  = 2'b01;
localparam TX_CPLD_QW1_TEMP   = 2'b10;
localparam TX_CPLD_QW1        = 2'b11;
    
  generate
    begin : gen_cpl_128

      always @ ( posedge clk ) begin
        if (!rst_n ) 
        begin
          s_axis_tx_tlast   <= 1'b0;
          s_axis_tx_tvalid  <= 1'b0;
          s_axis_tx_tdata   <= {16{8'b01010101}};
          s_axis_tx_tkeep   <= {16{1'b1}};
        end // if !rst_n
        else
        begin
          s_axis_tx_tlast   <= 1'b0;
          s_axis_tx_tvalid  <= 1'b0;
          s_axis_tx_tdata   <= {16{8'b01010101}};
          s_axis_tx_tkeep   <= {16{1'b1}};
        end // if rst_n
      end
    end
  endgenerate

endmodule
