module adc_mem (
  clk,
  reset,

  pci_rx_data,
  pci_rx_header,
  pci_rx_rd_ptr,
  pci_rx_last_data,
  pci_rx_last_header,
  pci_rx_wr_ptr,
  pci_rx_wr,

  bram_data,
  bram_header,
  bram_rd_ptr,
  bram_last_data,
  bram_last_header,
  bram_wr_ptr,
  bram_wr
);

  input                          clk;
  input                          reset;

  input  wire [1023:0]           pci_rx_data;
  input  wire [191:0]            pci_rx_header;
  output reg  [3:0]              pci_rx_rd_ptr;
  input  wire [1023:0]           pci_rx_last_data;
  input  wire [191:0]            pci_rx_last_header;
  input  wire [3:0]              pci_rx_wr_ptr;
  input  wire                    pci_rx_wr;

  output wire [1023:0]           bram_data;
  output wire [191:0]            bram_header;
  input  wire [3:0]              bram_rd_ptr;
  output reg  [1023:0]           bram_last_data;
  output reg  [191:0]            bram_last_header;
  output reg  [3:0]              bram_wr_ptr;
  output reg                     bram_wr;

// local

  reg [1023:0]    local_data;
  reg [191:0]     local_header;
  reg [3:0]       local_wr_ptr;
  reg             local_wr;

  reg  [63:0]      req_address;
  reg  [31:0]      req_header   [1:0];
  reg  [1023:0]    req_data;
  reg  [9:0]       req_len;
  reg  [7:0]       req_type;
  reg              use_last;
  reg              has_data;

bram_data pci_tx_data_inst (
  .clka(clk),                      // input wire clka
  .wea(local_wr),                  // input wire [0 : 0] wea
  .addra(local_wr_ptr),            // input wire [3 : 0] addra
  .dina(local_data),               // input wire [1023 : 0] dina
  .clkb(clk),                      // input wire clkb
  .addrb(bram_rd_ptr),             // input wire [3 : 0] addrb
  .doutb(bram_data)                // output wire [1023 : 0] doutb
);

bram_header pci_tx_header_inst (
  .clka(clk),                      // input wire clka
  .wea(local_wr),                  // input wire [0 : 0] wea
  .addra(local_wr_ptr),            // input wire [3 : 0] addra
  .dina(local_header),             // input wire [191 : 0] dina
  .clkb(clk),                      // input wire clkb
  .addrb(bram_rd_ptr),             // input wire [3 : 0] addrb
  .doutb(bram_header)              // output wire [191 : 0] doutb
);


ila_1 ila_1_inst (
	.clk(clk),                              // input wire clk
	.probe0(req_address),                   // input wire [63:0]  probe0  
	.probe1(req_header[0]),                 // input wire [31:0]  probe0  
	.probe2(req_header[1]),                 // input wire [31:0]  probe0  
	.probe3(req_data[31:0]),                // input wire [31:0]  probe1 
	.probe4(req_len),                       // input wire [9:0]  probe1 
	.probe5(local_header[63:0]),            // input wire [63:0]  probe0  
	.probe6(bram_last_header[63:0]),        // input wire [63:0]  probe0  
	.probe7(local_header[127:64]),          // input wire [63:0]  probe0  
	.probe8(bram_last_header[127:64]),      // input wire [63:0]  probe0  
	.probe9(local_data[31:0]),              // input wire [31:0]  probe0  
	.probe10(bram_last_data[31:0]),         // input wire [31:0]  probe0  
	.probe11(bram_rd_ptr),                  // input wire [3:0]  probe1 
	.probe12(bram_wr_ptr),                  // input wire [3:0]  probe1 
	.probe13(bram_wr)                       // input wire [0:0]  probe2
);


  generate
    begin : mem

      always @ ( posedge clk ) 
      begin
        if (local_wr)
        begin
          local_wr_ptr = local_wr_ptr + 1;
          local_wr = 0;
        end

        if (reset)
        begin
          pci_rx_rd_ptr = 0;
          local_wr_ptr = 0;
          local_wr = 0;
        end
        else
        begin
          if (pci_rx_wr)
          begin
            has_data = 1;

            if (pci_rx_wr_ptr == pci_rx_rd_ptr)
              use_last = 1;
            else
              use_last = 0;
          end
          else
          begin
            use_last = 0;

            if (pci_rx_wr_ptr == pci_rx_rd_ptr)
              has_data = 0;
            else
              has_data = 1;                
          end

          if (has_data)
          begin
            if (use_last)
            begin
              req_data = pci_rx_last_data;
              req_header[0] = pci_rx_last_header[31:0];
              req_header[1] = pci_rx_last_header[63:32];
              req_address = pci_rx_last_header[127:64];
            end
            else
            begin
              req_data = pci_rx_data;
              req_header[0] = pci_rx_header[31:0];
              req_header[1] = pci_rx_header[63:32];
              req_address = pci_rx_header[127:64];
            end

            pci_rx_rd_ptr = pci_rx_rd_ptr + 1;

            req_len = req_header[0][9:0];
            req_type = req_header[0][31:24];

            if (req_type[6] == 0)
            begin
              req_header[0][11:10] = 2'b0;                   // AT
              req_header[0][19:16] = 4'b0;                   // TH, AttrH, R
              req_header[0][23] = 1'b0;                      // R
 
              if (req_len)
                  req_header[0][31:25] = 6'b10_0101;         // Type + Fmt (data)
              else
                  req_header[0][31:25] = 6'b00_0101;         // Type + Fmt (no data)
              
              req_header[1][7] = 0;    
              local_header[31:0] = req_header[0];
              local_header[95:64] = req_header[1];
              
              req_header[1][31:16] = 16'b0;                  // completer ID
              req_header[1][15:13] = 3'b0;                   // completion code = 000
              req_header[1][12] = 1'b0;                      // BCM
              req_header[1][11:2] = req_len;                 // byte count
              req_header[1][1:0] = 2'b0;                     // dword aligned
              local_header[63:32] = req_header[1];

              local_data[1:0] = 0;
              local_data[18:2] = req_address[18:2];
              local_data[1023:19] = 0;

              local_wr = 1;
            end
          end
        end
      end

      always @ ( posedge clk ) 
      begin
        bram_last_data <= local_data;
        bram_last_header <= local_header;
        bram_wr_ptr <= local_wr_ptr;
        bram_wr <= local_wr;
      end

    end
  endgenerate

endmodule
