module adc_mem (
  clk,
  reset,

  pci_rx_data,
  pci_rx_header,
  pci_rx_be,
  pci_rx_rd_ptr,
  pci_rx_wr_ptr,

  bram_data,
  bram_header,
  bram_be,
  bram_rd_ptr,
  bram_wr_ptr
);

  input                          clk;
  input                          reset;

  input  wire [1023:0]           pci_rx_data;
  input  wire [191:0]            pci_rx_header;
  input  wire [127:0]            pci_rx_be;
  output reg  [3:0]              pci_rx_rd_ptr;
  input  wire [3:0]              pci_rx_wr_ptr;

  output wire [1023:0]           bram_data;
  output wire [191:0]            bram_header;
  output wire [127:0]            bram_be;
  input  wire [3:0]              bram_rd_ptr;
  output reg  [3:0]              bram_wr_ptr;


// FF

  reg  [1023:0]    q_data;
  reg  [191:0]     q_header;
  reg  [127:0]     q_be;
  reg              bram_wr;
  reg  [3:0]       q_pci_rx_rd_ptr;


// local

  reg  [63:0]      req_address;
  reg  [9:0]       req_len;
  reg  [7:0]       req_type;

bram_data pci_tx_data_inst (
  .clka(clk),                     // input wire clka
  .wea(bram_wr),                  // input wire [0 : 0] wea
  .addra(bram_wr_ptr),            // input wire [3 : 0] addra
  .dina(q_data),               // input wire [1023 : 0] dina
  .clkb(clk),                     // input wire clkb
  .addrb(bram_rd_ptr),            // input wire [3 : 0] addrb
  .doutb(bram_data)                  // output wire [1023 : 0] doutb
);

bram_header pci_tx_header_inst (
  .clka(clk),                     // input wire clka
  .wea(bram_wr),                  // input wire [0 : 0] wea
  .addra(bram_wr_ptr),            // input wire [3 : 0] addra
  .dina(q_header),             // input wire [191 : 0] dina
  .clkb(clk),                     // input wire clkb
  .addrb(bram_rd_ptr),            // input wire [3 : 0] addrb
  .doutb(bram_header)                // output wire [191 : 0] doutb
);

bram_be pci_tx_be_inst (
  .clka(clk),                     // input wire clka
  .wea(bram_wr),                  // input wire [0 : 0] wea
  .addra(bram_wr_ptr),            // input wire [3 : 0] addra
  .dina(q_be),                    // input wire [191 : 0] dina
  .clkb(clk),                     // input wire clkb
  .addrb(bram_rd_ptr),            // input wire [3 : 0] addrb
  .doutb(bram_be)                 // output wire [191 : 0] doutb
);


ila_1 ila_1_inst (
	.clk(clk),                              // input wire clk
	.probe0(q_header[127:64]),            // input wire [63:0]  probe0  
	.probe1(q_header[63:0]),              // input wire [63:0]  probe0  
	.probe2(q_data[31:0]),                // input wire [31:0]  probe1 
	.probe3(req_len),                       // input wire [9:0]  probe1 
	.probe4(bram_header[127:64]),           // input wire [63:0]  probe0
	.probe5(bram_header[63:0]),             // input wire [63:0]  probe0  
	.probe6(bram_data[31:0]),               // input wire [31:0]  probe0  
	.probe7(q_be[31:0]),                  // input wire [31:0]  probe0  
	.probe8(pci_rx_rd_ptr),                 // input wire [3:0]  probe1 
	.probe9(pci_rx_wr_ptr),                 // input wire [3:0]  probe1 
	.probe10(bram_rd_ptr),                  // input wire [3:0]  probe1 
	.probe11(bram_wr_ptr),                  // input wire [3:0]  probe1 
	.probe12(bram_wr)                       // input wire [0:0]  probe2
);


generate
  begin : mem

    always @ ( posedge clk ) 
    begin
      pci_rx_rd_ptr = q_pci_rx_rd_ptr;

      if (reset)
      begin
        q_pci_rx_rd_ptr <= 0;
        bram_wr_ptr <= 0;
        bram_wr <= 0;
      end
      else
      begin
        if (pci_rx_wr_ptr == pci_rx_rd_ptr)
          bram_wr <= 0;
        else
        begin
          req_len = pci_rx_header[9:0];
          req_type = pci_rx_header[31:24];
          req_address = pci_rx_header[95:64];

          pci_rx_rd_ptr = pci_rx_rd_ptr + 1;

          if (req_type[6] == 0)
          begin
            q_header[63:48] <= 16'b0;                  // completer ID
            q_header[47:45] <= 3'b0;                   // completion code = 000
            q_header[44] <= 1'b0;                      // BCM
            q_header[43:34] <= req_len;                // byte count
            q_header[33:32] <= 2'b0;                   // dword aligned

            if (req_len)
              q_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
            else
              q_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

            q_header[24] <= pci_rx_header[24];
            q_header[23] <= 1'b0;                      // R
            q_header[22:20] <= pci_rx_header[22:20];
            q_header[19:16] <= 4'b0;                   // TH, AttrH, R
            q_header[15:12] <= pci_rx_header[15:12];
            q_header[11:10] <= 2'b0;                   // AT
            q_header[9:0] <= pci_rx_header[9:0];
              
            q_data[1:0] <= 0;
            q_data[18:2] <= req_address[18:2];
            q_data[1023:19] <= 0;

            q_be <= pci_rx_be;

            bram_wr_ptr <= bram_wr_ptr + 1;
            bram_wr <= 1;
          end
          else
            bram_wr <= 0;

          q_pci_rx_rd_ptr <= pci_rx_rd_ptr;
      end
    end

  end
endgenerate

endmodule
