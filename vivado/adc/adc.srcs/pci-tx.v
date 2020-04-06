module pci_tx (
  clk,
  reset,
  s_axis_tx_tready,
  s_axis_tx_tdata,
  s_axis_tx_tkeep,
  s_axis_tx_tlast,
  s_axis_tx_tvalid,
  s_axis_tx_tuser,

  bar_data,
  bar_header,
  bar_wr,
  bar_busy,

  adc_data,
  adc_address,
  adc_wr,
  adc_busy
);

  input                     clk;
  input                     reset;

  input                     s_axis_tx_tready;
  output reg  [127:0]       s_axis_tx_tdata;
  output reg  [15:0]        s_axis_tx_tkeep;
  output reg                s_axis_tx_tlast;
  output reg                s_axis_tx_tvalid;
  output reg  [3:0]         s_axis_tx_tuser;

  input  wire [127:0]       bar_data;
  input  wire [127:0]       bar_header;
  input  wire               bar_wr;
  output reg                bar_busy;

  input  wire [1023:0]      adc_data;
  input  wire [127:0]       adc_header;
  input  wire               adc_wr;
  output reg                adc_busy;


// local

  reg                       bar_is_active;
  reg                       start;
  reg [9:0]                 count;

  reg [127:0]               q_bar_header;
  reg [127:0]               q_bar_data;
  reg [127:0]               pend_bar_data;
  reg [127:0]               q_adc_header;
  reg [1023:0]              q_adc_data;
  reg [1023:0]              pend_adc_data;

  wire [7:0]                pkt_type;
  wire [9:0]                pkt_len;
  wire [127:0]              pkt_header;
  wire [127:0]              raw_pkt_data;
  wire [127:0]              pkt_data;


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

    assign raw_pkt_data = bar_is_active ? q_bar_data : q_adc_data[127:0];
    assign pkt_header = bar_is_active ? q_bar_header : q_adc_header;

    assign pkt_type = pkt_header[31:24];
    assign pkt_len = pkt_header[9:0];

    assign pkt_data[31:24] = raw_pkt_data[7:0];
    assign pkt_data[23:16] = raw_pkt_data[15:8];
    assign pkt_data[15:8] = raw_pkt_data[23:16];
    assign pkt_data[7:0] = raw_pkt_data[31:24];

    assign pkt_data[63:56] = raw_pkt_data[39:32];
    assign pkt_data[55:48] = raw_pkt_data[47:40];
    assign pkt_data[47:40] = raw_pkt_data[55:48];
    assign pkt_data[39:32] = raw_pkt_data[63:56];

    assign pkt_data[95:88] = raw_pkt_data[71:64];
    assign pkt_data[87:80] = raw_pkt_data[79:72];
    assign pkt_data[79:72] = raw_pkt_data[87:80];
    assign pkt_data[71:64] = raw_pkt_data[95:88];

    assign pkt_data[127:120] = raw_pkt_data[103:96];
    assign pkt_data[119:112] = raw_pkt_data[111:104];
    assign pkt_data[111:104] = raw_pkt_data[119:112];
    assign pkt_data[103:96] = raw_pkt_data[127:120];


    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        bar_busy <= 0;
        adc_busy <= 0;        
      end
      else
      begin
        if (bar_wr)
        begin
          q_bar_header <= bar_header;
          pend_bar_data <= bar_data;
        end
            
        if (adc_wr)
        begin
          q_adc_header <= adc_header;
          pend_adc_data <= adc_data;
        end

        if (start)
        begin
          if (adc_wr)
            adc_busy <= 1;
          else
            if (!bar_is_active)    
              adc_busy <= 0;              

          if (bar_wr)
            bar_busy <= 1;
          else
            if (bar_is_active)    
              bar_busy <= 0;              
        end
        else
        begin
          if (adc_wr)
            adc_busy <= 1;

          if (bar_wr)
            bar_busy <= 1;
        end
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        s_axis_tx_tuser <= 0;
        s_axis_tx_tvalid <= 0;
        s_axis_tx_tlast <= 0;
        count <= 0;
        start <= 0;
      end
      else
      begin
        if (s_axis_tx_tready)
        begin
          if (s_axis_tx_tvalid && !s_axis_tx_tlast)
          begin
            s_axis_tx_tdata <= pkt_data;

            if (count > 4)
            begin
              s_axis_tx_tlast <= 0;
              count <= count - 4;
              q_adc_data[895:0] <= q_adc_data[1023:128];
            end
            else
            begin
              s_axis_tx_tlast <= 1;

              if (adc_busy || bar_busy))
              begin
                start <= 1;

                if (adc_busy)
                begin
                  bar_is_active <= 0;
                  q_adc_data <= pend_adc_data;
                end
                else
                begin
                  bar_is_active <= 1;
                  q_bar_data <= pend_bar_data;
                end
              end
            end

            case (count)
              0: s_axis_tx_tkeep[15:0] <= 16'h0000;
              1: s_axis_tx_tkeep[15:0] <= 16'h000f;
              2: s_axis_tx_tkeep[15:0] <= 16'h00ff;
              3: s_axis_tx_tkeep[15:0] <= 16'h0fff;
              default: s_axis_tx_tkeep[15:0] <= 16'hffff;
            endcase
          end
          else
          begin
            if (start)
            begin
              s_axis_tx_tvalid <= 1;

              if (pkt_type[5] == 0)  // 3 DW header
              begin
                if (pkt_type[6] && pkt_len)
                begin
                  s_axis_tx_tdata[127:96] <= pkt_data[31:0];
                  s_axis_tx_tkeep[15:12] <= 4'b1111;
                  s_axis_tx_tdata[95:0] <= pkt_header[95:0];
                  s_axis_tx_tkeep[11:0] <= 12'hfff;

                  if (pkt_len > 1)
                  begin
                    start <= 0;
                    s_axis_tx_tlast <= 0;
                    count <= pkt_len - 1;

                    if (bar_is_active)
                      q_bar_data[95:0] <= q_bar_data[127:32];
                    else
                      q_adc_data[991:0] <= q_adc_data[1023:32];
                  end
                  else
                  begin
                    s_axis_tx_tlast <= 1;

                    if (adc_busy || bar_busy))
                    begin
                      start <= 1;

                      if (adc_busy)
                      begin
                        bar_is_active <= 0;
                        q_adc_data <= pend_adc_data;
                      end
                      else
                      begin
                        bar_is_active <= 1;
                        q_bar_data <= pend_bar_data;
                      end
                    end
                    else
                      start <= 0;
                  end
                end
                else
                begin
                  s_axis_tx_tdata[127:96] <= 0;
                  s_axis_tx_tkeep[15:12] <= 4'b0000;
                  s_axis_tx_tdata[95:0] <= pkt_header[95:0];
                  s_axis_tx_tkeep[11:0] <= 12'hfff;
                  s_axis_tx_tlast <= 1;

                  if (adc_busy || bar_busy))
                  begin
                    start <= 1;

                    if (adc_busy)
                    begin
                      bar_is_active <= 0;
                      q_adc_data <= pend_adc_data;
                    end
                    else
                    begin
                      bar_is_active <= 1;
                      q_bar_data <= pend_bar_data;
                    end
                  end
                  else
                    start <= 0;
                end
              end
              else
              begin
                s_axis_tx_tdata[127:0] <= pkt_header;
                s_axis_tx_tkeep[15:0] <= 16'hffff;
    
                if (pkt_type[6])
                begin
                  count <= pkt_len;
                  if (pkt_len)
                  begin
                    s_axis_tx_tlast <= 0;
                    start <= 0;
                  end
                  else
                  begin
                    s_axis_tx_tlast <= 1;

                    if (adc_busy || bar_busy))
                    begin
                     start <= 1;

                      if (adc_busy)
                      begin
                        bar_is_active <= 0;
                        q_adc_data <= pend_adc_data;
                      end
                      else
                      begin
                        bar_is_active <= 1;
                        q_bar_data <= pend_bar_data;
                      end
                    end
                    else
                      start <= 0;
                  end
                end
                else
                begin
                  s_axis_tx_tlast <= 1;

                  if (adc_busy || bar_busy))
                  begin
                   start <= 1;

                    if (adc_busy)
                    begin
                      bar_is_active <= 0;
                      q_adc_data <= pend_adc_data;
                    end
                    else
                    begin
                      bar_is_active <= 1;
                      q_bar_data <= pend_bar_data;
                    end
                  end
                  else
                    start <= 0;
                end
              end
            end
            else
            begin
              s_axis_tx_tvalid <= 0;
              
              if (adc_busy || bar_busy))
              begin
                start <= 1;

                if (adc_busy)
                begin
                  bar_is_active <= 0;
                  q_adc_data <= pend_adc_data;
                end
                else
                begin
                  bar_is_active <= 1;
                  q_bar_data <= pend_bar_data;
                end
              end
              else
                start <= 0;
            end
          end                
        end
      end
    end

  end
endgenerate

endmodule
