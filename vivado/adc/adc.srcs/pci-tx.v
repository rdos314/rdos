module pci_tx (
  clk,
  reset,
  s_axis_tx_tready,
  s_axis_tx_tdata,
  s_axis_tx_tkeep,
  s_axis_tx_tlast,
  s_axis_tx_tvalid,
  s_axis_tx_tuser,

  pci_tx_data,
  pci_tx_header,
  pci_tx_wr,
  pci_tx_full
);

  input             clk;
  input             reset;

  // AXIS
  input                           s_axis_tx_tready;
  output  reg [127:0]             s_axis_tx_tdata;
  output  reg [15:0]              s_axis_tx_tkeep;
  output  reg                     s_axis_tx_tlast;
  output  reg                     s_axis_tx_tvalid;
  output  reg [3:0]               s_axis_tx_tuser;

  input  wire [1023:0]            pci_tx_data;
  input  wire [127:0]             pci_tx_header;
  input  wire                     pci_tx_wr;
  output wire                     pci_tx_full;

// FF
  reg  [9:0]     q_pkt_count;
  reg  [1023:0]  q_pkt_data;

  wire [7:0]     pkt_type;
  wire [9:0]     pkt_len;
  wire [127:0]   pkt_data;

  wire [1023:0]  bram_data;
  wire [127:0]   bram_header;

  reg            pci_tx_rd;


fifo_data pci_tx_data_inst (
  .clk(clk),               // input wire clk
  .din(pci_tx_data),       // input wire [1023 : 0] din
  .wr_en(pci_tx_wr),       // input wire wr_en
  .rd_en(pci_tx_rd),       // input wire rd_en
  .dout(bram_data),        // output wire [1023 : 0] dout
  .full(pci_tx_full),      // output wire full
  .empty(pci_tx_empty)     // output wire empty
);

fifo_header pci_tx_header_inst (
  .clk(clk),               // input wire clk
  .din(pci_tx_header),     // input wire [127 : 0] din
  .wr_en(pci_tx_wr),       // input wire wr_en
  .rd_en(pci_tx_rd),       // input wire rd_en
  .dout(bram_header),      // output wire [127 : 0] dout
  .full(),                 // output wire full
  .empty()                 // output wire empty
);

ila_2 ila_2_inst (
	.clk(clk),                         // input wire clk
	.probe0(s_axis_tx_tvalid),         // input wire [0:0]  probe0  
	.probe1(s_axis_tx_tready),         // input wire [0:0]  probe0  
	.probe2(s_axis_tx_tlast),          // input wire [0:0]  probe0  
	.probe3(s_axis_tx_tkeep),          // input wire [15:0]  probe0  
	.probe4(s_axis_tx_tdata[63:0]),    // input wire [63:0]  probe0  
	.probe5(s_axis_tx_tdata[127:64]),  // input wire [63:0]  probe0  
	.probe6(pkt_type),                 // input wire [7:0]  probe0  
	.probe7(pkt_len),                  // input wire [9:0]  probe0  
	.probe8(q_pkt_count),              // input wire [9:0]  probe0  
	.probe9(q_pkt_data[63:0]),         // input wire [63:0]  probe0  
	.probe10(q_pkt_data[127:64]),      // input wire [63:0]  probe0  
	.probe11(pci_tx_rd),               // input wire [0:0]  probe0  
	.probe12(pci_tx_header[31:0]),     // input wire [31:0]  probe0  
	.probe13(pci_tx_header[63:32]),    // input wire [31:0]  probe0  
	.probe14(pci_tx_header[95:64]),    // input wire [31:0]  probe0  
	.probe15(pci_tx_header[127:96]),   // input wire [31:0]  probe0  
	.probe16(pci_tx_wr),               // input wire [0:0]  probe0  
	.probe17(pci_tx_empty)             // input wire [0:0]  probe0  
);

generate
  begin : gen_pci_tx

    assign pkt_type = bram_header[31:24];
    assign pkt_len = bram_header[9:0];

    assign pkt_data[31:24] = q_pkt_data[7:0];
    assign pkt_data[23:16] = q_pkt_data[15:8];
    assign pkt_data[15:8] = q_pkt_data[23:16];
    assign pkt_data[7:0] = q_pkt_data[31:24];

    assign pkt_data[63:56] = q_pkt_data[39:32];
    assign pkt_data[55:48] = q_pkt_data[47:40];
    assign pkt_data[47:40] = q_pkt_data[55:48];
    assign pkt_data[39:32] = q_pkt_data[63:56];

    assign pkt_data[95:88] = q_pkt_data[71:64];
    assign pkt_data[87:80] = q_pkt_data[79:72];
    assign pkt_data[79:72] = q_pkt_data[87:80];
    assign pkt_data[71:64] = q_pkt_data[95:88];

    assign pkt_data[127:120] = q_pkt_data[103:96];
    assign pkt_data[119:112] = q_pkt_data[111:104];
    assign pkt_data[111:104] = q_pkt_data[119:112];
    assign pkt_data[103:96] = q_pkt_data[127:120];

    always @ ( * ) 
    begin
      if (reset)
        pci_tx_rd = 0;
      else
      begin
        if (s_axis_tx_tready)
        begin
          if (s_axis_tx_tvalid && !s_axis_tx_tlast)
          begin
            if (q_pkt_count > 4)
              pci_tx_rd = 0;
            else
              pci_tx_rd = 1;
          end
          else
          begin
            if (pci_tx_empty)
              pci_tx_rd = 0;
            else
            begin
              if (pkt_type[5] == 0)  // 3 DW header
              begin
                if (pkt_type[6] && pkt_len)
                begin
                  if (pkt_len > 1)
                    pci_tx_rd = 0;
                  else
                    pci_tx_rd = 1;
                end
                else
                  pci_tx_rd = 1;
              end
              else
              begin
                if (pkt_type[6])
                begin
                  if (pkt_len)
                    pci_tx_rd = 0;
                  else
                    pci_tx_rd = 1;
                end
                else
                  pci_tx_rd = 1;
              end
            end
          end
        end
        else
          pci_tx_rd = 0;
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        s_axis_tx_tuser <= 0;
        s_axis_tx_tvalid <= 0;
        s_axis_tx_tlast <= 0;
      end
      else
      begin
        if (s_axis_tx_tready)
        begin
          if (s_axis_tx_tvalid && !s_axis_tx_tlast)
          begin
            s_axis_tx_tdata <= pkt_data;
            q_pkt_data[895:0] <= q_pkt_data[1023:128];

            case (q_pkt_count)
              0:
              begin
                s_axis_tx_tkeep[15:0] <= 16'h0000;
                q_pkt_count <= 0;
                s_axis_tx_tlast <= 1;
              end

              1:
              begin
                s_axis_tx_tkeep[15:0] <= 16'h000f;
                q_pkt_count <= 0;
                s_axis_tx_tlast <= 1;
              end

              2:
              begin
                s_axis_tx_tkeep[15:0] <= 16'h00ff;
                q_pkt_count <= 0;
                s_axis_tx_tlast <= 1;
              end
                
              3:
              begin
                s_axis_tx_tkeep[15:0] <= 16'h0fff;
                q_pkt_count <= 0;
                s_axis_tx_tlast <= 1;
              end

              4:
              begin
                s_axis_tx_tkeep[15:0] <= 16'hffff;
                q_pkt_count <= 0;
                s_axis_tx_tlast <= 1;
              end

              default:
              begin
                s_axis_tx_tkeep[15:0] <= 16'hffff;
                q_pkt_count <= q_pkt_count - 4;
                s_axis_tx_tlast <= 0;
              end
            endcase
          end
          else
          begin
            if (pci_tx_empty)
            begin
              s_axis_tx_tuser <= 0;
              s_axis_tx_tvalid <= 0;
              s_axis_tx_tlast <= 0;
            end
            else
            begin
              s_axis_tx_tvalid <= 1;

              if (pkt_type[5] == 0)  // 3 DW header
              begin
                if (pkt_type[6] && pkt_len)
                begin
                  s_axis_tx_tdata[127:120] <= bram_data[7:0];
                  s_axis_tx_tdata[119:112] <= bram_data[15:8];
                  s_axis_tx_tdata[111:104] <= bram_data[23:16];
                  s_axis_tx_tdata[103:96] <= bram_data[31:24];
                  s_axis_tx_tkeep[15:12] <= 4'b1111;
                  s_axis_tx_tdata[95:0] <= bram_header[95:0];
                  s_axis_tx_tkeep[11:0] <= 12'hfff;
                  q_pkt_data[991:0] <= bram_data[1023:32];
                  q_pkt_count <= pkt_len - 1;
                  if (pkt_len > 1)
                    s_axis_tx_tlast <= 0;
                  else
                    s_axis_tx_tlast <= 1;
                end
                else
                begin
                  s_axis_tx_tdata[127:96] <= 0;
                  s_axis_tx_tkeep[15:12] <= 4'b0000;
                  s_axis_tx_tdata[95:0] <= bram_header[95:0];
                  s_axis_tx_tkeep[11:0] <= 12'hfff;
                  q_pkt_count <= 0;
                  s_axis_tx_tlast <= 1;
                end
              end
              else
              begin
                s_axis_tx_tdata[127:0] <= bram_header;
                s_axis_tx_tkeep[15:0] <= 16'hffff;
                q_pkt_data <= bram_data;
  
                if (pkt_type[6])
                begin
                  q_pkt_count = pkt_len;
                  if (pkt_len)
                    s_axis_tx_tlast <= 0;
                  else
                    s_axis_tx_tlast <= 1;
                end
                else
                begin
                  q_pkt_count <= 0;
                  s_axis_tx_tlast <= 1;
                end
              end
            end
          end
        end
      end
    end

  end
endgenerate

endmodule
