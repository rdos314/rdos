module adc_mem (
  clk,
  reset,

  pci_rx_data,
  pci_rx_header,
  pci_rx_be,
  pci_rx_rd,
  pci_rx_empty,

  pci_tx_data,
  pci_tx_header,
  pci_tx_wr,
  pci_tx_full
);

  input                          clk;
  input                          reset;

  input  wire [1023:0]           pci_rx_data;
  input  wire [191:0]            pci_rx_header;
  input  wire [127:0]            pci_rx_be;
  output reg                     pci_rx_rd;
  input  wire                    pci_rx_empty;

  output reg [1023:0]            pci_tx_data;
  output reg [191:0]             pci_tx_header;
  output reg                     pci_tx_wr;
  input  wire                    pci_tx_full;


// FF


// local

  reg  [63:0]      req_address;
  reg  [9:0]       req_len;
  reg  [7:0]       req_type;


ila_1 ila_1_inst (
	.clk(clk),                              // input wire clk
	.probe0(pci_rx_empty),                  // input wire [0:0]  probe1 
	.probe1(pci_tx_full),                   // input wire [0:0]  probe1 
	.probe2(req_address),                   // input wire [63:0]  probe1 
	.probe3(req_len),                       // input wire [9:0]  probe1 
	.probe4(pci_rx_header[63:0]),           // input wire [63:0]  probe1 
	.probe5(pci_rx_header[127:64]),         // input wire [63:0]  probe1 
	.probe6(pci_tx_header[63:0]),           // input wire [63:0]  probe1 
	.probe7(pci_tx_header[127:64]),        // input wire [63:0]  probe1 
	.probe8(pci_tx_data[31:0])             // input wire [31:0]  probe2
);


generate
  begin : mem

    always @ ( posedge clk ) 
    begin
      if (!reset)
      begin
        if (pci_rx_empty)
        begin
          pci_rx_rd <= 0;
          pci_tx_wr <= 0;
        end
        else
        begin
          req_len = pci_rx_header[9:0];
          req_type = pci_rx_header[31:24];
          req_address = pci_rx_header[95:64];

// FF part

          if (req_type[6] == 0)
          begin
            pci_tx_header[63:48] <= 16'b0;                  // completer ID
            pci_tx_header[47:45] <= 3'b0;                   // completion code = 000
            pci_tx_header[44] <= 1'b0;                      // BCM
            pci_tx_header[43:34] <= req_len;                // byte count
            pci_tx_header[33:32] <= 2'b0;                   // dword aligned

            if (req_len)
              pci_tx_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
            else
              pci_tx_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

            pci_tx_header[24] <= pci_rx_header[24];
            pci_tx_header[23] <= 1'b0;                      // R
            pci_tx_header[22:20] <= pci_rx_header[22:20];
            pci_tx_header[19:16] <= 4'b0;                   // TH, AttrH, R
            pci_tx_header[15:12] <= pci_rx_header[15:12];
            pci_tx_header[11:10] <= 2'b0;                   // AT
            pci_tx_header[9:0] <= pci_rx_header[9:0];
              
            pci_tx_data[1:0] <= 0;
            pci_tx_data[18:2] <= req_address[18:2];
            pci_tx_data[1023:19] <= 0;

            pci_tx_wr <= 1;
          end
          else
            pci_tx_wr <= 0;

          pci_rx_rd <= 1;
        end
      end
    end

  end
endgenerate

endmodule
