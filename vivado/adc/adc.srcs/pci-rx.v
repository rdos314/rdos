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
  bram_last_data,
  bram_last_header,
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

  output wire [1023:0]           bram_data;
  output wire [191:0]            bram_header;
  input  wire [3:0]              bram_rd_ptr;
  output reg  [1023:0]           bram_last_data;
  output reg  [191:0]            bram_last_header;
  output reg  [3:0]              bram_wr_ptr;
  output reg                     bram_wr;

// local variables

  reg [1023:0]    local_data;
  reg [191:0]     local_header;
  reg [3:0]       local_wr_ptr;
  reg             local_wr;


  reg [3:0]    sel;
  reg [3:0]    data_size;
  reg          header_done;
  reg          pend_strad;
  
  reg [7:0]    rq_type;
  reg          rq_wr;
  reg [9:0]    rq_len;
  reg [31:0]   rq_header   [1:0];
  reg [31:0]   rq_address  [1:0];
  reg [31:0]   strad_header [1:0];


bram_data pci_rx_data_inst (
  .clka(clk),                 // input wire clka
  .wea(local_wr),             // input wire [0 : 0] wea
  .addra(local_wr_ptr),       // input wire [3 : 0] addra
  .dina(local_data),          // input wire [1023 : 0] dina
  .clkb(clk),                 // input wire clkb
  .addrb(bram_rd_ptr),        // input wire [3 : 0] addrb
  .doutb(bram_data)           // output wire [1023 : 0] doutb
);

bram_header pci_rx_header_inst (
  .clka(clk),                 // input wire clka
  .wea(local_wr),             // input wire [0 : 0] wea
  .addra(local_wr_ptr),       // input wire [3 : 0] addra
  .dina(local_header),        // input wire [191 : 0] dina
  .clkb(clk),                 // input wire clkb
  .addrb(bram_rd_ptr),        // input wire [3 : 0] addrb
  .doutb(bram_header)         // output wire [191 : 0] doutb
);

ila_0 ila_0_inst (
	.clk(clk),                        // input wire clk
	.probe0(m_axis_rx_tvalid),        // input wire [0:0]  probe0  
	.probe1(m_axis_rx_tready),        // input wire [0:0]  probe0  
	.probe2(header_done),              // input wire [0:0]  probe0  
	.probe3(pend_strad),              // input wire [0:0]  probe0  
	.probe4(m_axis_rx_tuser[13]),              // input wire [0:0]  probe0  
	.probe5(m_axis_rx_tuser[14]),              // input wire [0:0]  probe0  
	.probe6(m_axis_rx_tuser[21]),              // input wire [0:0]  probe0  
	.probe7(rq_type),              // input wire [7:0]  probe0  
	.probe8(rq_wr),              // input wire [0:0]  probe0  
	.probe9(rq_header[0]),              // input wire [31:0]  probe0  
	.probe10(rq_header[1]),              // input wire [31:0]  probe0  
	.probe11(rq_address[0]),              // input wire [31:0]  probe0  
	.probe12(rq_address[1])              // input wire [31:0]  probe0  
);

  generate
    begin : pci_rx_128

      always @ ( posedge clk ) 
      begin
        if (local_wr)
        begin
          local_wr_ptr = local_wr_ptr + 1;
          local_wr = 0;
        end

        if (reset )
        begin
          m_axis_rx_tready = 0;
          pend_strad = 0;
          local_wr = 0;
        end
        else
        begin
          if (m_axis_rx_tvalid && m_axis_rx_tready)
          begin
            if (pend_strad)
            begin
              rq_header[1] =  strad_header[1];
              rq_header[0] =  strad_header[0];

              rq_type = rq_header[0][31:24];
              rq_len = rq_header[0][9:0];
              rq_wr = rq_type[6];

              if (rq_wr)
                data_size = rq_len;
              else
                data_size = 0;
              header_done = 1'b0;
            end

            if (m_axis_rx_tuser[13] && m_axis_rx_tuser[21])  // straddled
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
                rq_header[1] =  m_axis_rx_tdata[127:96];
                rq_header[0] =  m_axis_rx_tdata[95:64];
                header_done = 1'b0;
              end
              else
              begin
                rq_header[1] =  m_axis_rx_tdata[63:32];
                rq_header[0] =  m_axis_rx_tdata[31:0];
                header_done = 1'b1;
              end

              rq_type = rq_header[0][31:24];
              rq_len = rq_header[0][9:0];
              rq_wr = rq_type[6];

              if (rq_wr)
                data_size = rq_len;
              else
                data_size = 0;

              sel = 0;

              if (!m_axis_rx_tuser[13])  // header in low part of data
              begin
                if (rq_type[5] == 1'b0)  // 3 DW header
                begin
                  if (data_size)
                  begin
                    local_data[7:0] = m_axis_rx_tdata[127:120];
                    local_data[15:8] = m_axis_rx_tdata[119:112];
                    local_data[23:16] = m_axis_rx_tdata[111:104];
                    local_data[31:24] = m_axis_rx_tdata[103:96];
                    sel = 1;
                    data_size = data_size - 1;
                  end

                  rq_address[0] =  m_axis_rx_tdata[95:64];
                  rq_address[1] =  32'b0;
                end
                else
                begin
                  rq_address[0] =  m_axis_rx_tdata[127:96];
                  rq_address[1] =  m_axis_rx_tdata[95:64];
                end
              end
            end
            else
            begin
              if (header_done)
              begin
                if (data_size)
                begin
                  local_data[(32*sel) +: 8] = m_axis_rx_tdata[31:24];
                  local_data[(32*sel+8) +: 8] = m_axis_rx_tdata[23:16];
                  local_data[(32*sel+16) +: 8] = m_axis_rx_tdata[15:8];
                  local_data[(32*sel+24) +: 8] = m_axis_rx_tdata[7:0];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end
 
                if (data_size)
                begin
                  local_data[(32*sel) +: 8] = m_axis_rx_tdata[63:56];
                  local_data[(32*sel+8) +: 8] = m_axis_rx_tdata[55:48];
                  local_data[(32*sel+16) +: 8] = m_axis_rx_tdata[47:40];
                  local_data[(32*sel+24) +: 8] = m_axis_rx_tdata[39:32];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  local_data[(32*sel) +: 8] = m_axis_rx_tdata[95:88];
                  local_data[(32*sel+8) +: 8] = m_axis_rx_tdata[87:80];
                  local_data[(32*sel+16) +: 8] = m_axis_rx_tdata[79:72];
                  local_data[(32*sel+24) +: 8] = m_axis_rx_tdata[71:64];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  local_data[(32*sel) +: 8] = m_axis_rx_tdata[127:120];
                  local_data[(32*sel+8) +: 8] = m_axis_rx_tdata[119:112];
                  local_data[(32*sel+16) +: 8] = m_axis_rx_tdata[111:104];
                  local_data[(32*sel+24) +: 8] = m_axis_rx_tdata[103:96];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end
              end
              else
              begin
                sel = 0;

                if (rq_type[5] == 0)  // 3 DW header
                begin
                  if (data_size)
                  begin
                    local_data[7:0] = m_axis_rx_tdata[63:56];
                    local_data[15:8] = m_axis_rx_tdata[55:48];
                    local_data[23:16] = m_axis_rx_tdata[47:40];
                    local_data[31:24] = m_axis_rx_tdata[39:32];
                    sel = 1;
                    data_size = data_size - 1;
                  end                    

                  rq_address[0] =  m_axis_rx_tdata[31:0];
                  rq_address[1] =  32'b0;
                end
                else
                begin
                  rq_address[0] =  m_axis_rx_tdata[63:32];
                  rq_address[1] =  m_axis_rx_tdata[31:0];
                end

                if (data_size)
                begin
                  local_data[(32*sel) +: 8] = m_axis_rx_tdata[95:88];
                  local_data[(32*sel+8) +: 8] = m_axis_rx_tdata[87:80];
                  local_data[(32*sel+16) +: 8] = m_axis_rx_tdata[79:72];
                  local_data[(32*sel+24) +: 8] = m_axis_rx_tdata[71:64];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end

                if (data_size)
                begin
                  local_data[(32*sel) +: 8] = m_axis_rx_tdata[127:120];                  
                  local_data[(32*sel+8) +: 8] = m_axis_rx_tdata[119:112];
                  local_data[(32*sel+16) +: 8] = m_axis_rx_tdata[111:104];
                  local_data[(32*sel+24) +: 8] = m_axis_rx_tdata[103:96];
                  sel = sel + 1;
                  data_size = data_size - 1;
                end

                header_done = 1'b1;
              end
            end
                       
            if (m_axis_rx_tuser[21]) // is final part of TLP
            begin
              local_header[31:0] = rq_header[0];        // header 0 
              local_header[63:32] = rq_header[1];       // header 1
              local_header[95:64] = rq_address[0];      // low address
              local_header[127:96] = rq_address[1];     // high address
              local_header[128] = m_axis_rx_tuser[2];    // BAR0 hit

              local_wr = 1;             
            end
          end

          if (local_wr_ptr + 1 == bram_rd_ptr)
            m_axis_rx_tready = 0;
          else
            m_axis_rx_tready = 1;

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
