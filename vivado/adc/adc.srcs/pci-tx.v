module pci_tx (
  clk,
  reset,
  s_axis_tx_tready,
  s_axis_tx_tdata,
  s_axis_tx_tkeep,
  s_axis_tx_tlast,
  s_axis_tx_tvalid,
  s_axis_tx_tuser,

  fifo_data,
  fifo_rd,
  fifo_empty
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

  input       [127:0]             fifo_data;
  output  reg                     fifo_rd;
  input                           fifo_empty;


// local

  reg [6:0]    sel;
  reg          header_done;

  reg [7:0]    req_type;
  reg [9:0]    req_len;
  reg [31:0]   req_header   [3:0];
  reg [1023:0] req_data;
      
  generate
    begin : gen_cpl_128

      always @ ( posedge clk ) begin
        s_axis_tx_tuser[0] = 1'b0;                // Unused for V6
        s_axis_tx_tuser[1] = 1'b0;                // Error forward packet
        s_axis_tx_tuser[2] = 1'b0;                // Stream packet
        s_axis_tx_tuser[3] = 1'b0;                // tx_src_dsc
        s_axis_tx_tkeep = 16'b0;
        fifo_rd = 1'b0;

        if (reset) 
        begin
          s_axis_tx_tlast   = 1'b0;
          s_axis_tx_tvalid  = 1'b0;
          header_done = 1'b0;
        end
        else
        begin
          if (s_axis_tx_tready && !fifo_empty)
          begin
            if (header_done)
            begin
              if (req_len)
              begin
                s_axis_tx_tdata[31:24] = req_data[(sel) +: 8];
                s_axis_tx_tdata[23:16] = req_data[(sel+8) +: 8];
                s_axis_tx_tdata[15:8] = req_data[(sel+16) +: 8];
                s_axis_tx_tdata[7:0] = req_data[(sel+24) +: 8];
                s_axis_tx_tkeep[3:0] = 4'b1111;
                sel = sel + 32;
                req_len = req_len - 1;
              end
 
              if (req_len)
              begin
                s_axis_tx_tdata[63:56] = req_data[(sel) +: 8];
                s_axis_tx_tdata[55:48] = req_data[(sel+8) +: 8];
                s_axis_tx_tdata[47:40] = req_data[(sel+16) +: 8];
                s_axis_tx_tdata[39:32] = req_data[(sel+24) +: 8];
                s_axis_tx_tkeep[7:4] = 4'b1111;
                sel = sel + 32;
                req_len = req_len - 1;
              end

              if (req_len)
              begin
                s_axis_tx_tdata[95:88] = req_data[(sel) +: 8];
                s_axis_tx_tdata[87:80] = req_data[(sel+8) +: 8];
                s_axis_tx_tdata[79:72] = req_data[(sel+16) +: 8];
                s_axis_tx_tdata[71:64] = req_data[(sel+24) +: 8];
                s_axis_tx_tkeep[11:8] = 4'b1111;
                sel = sel + 32;
                req_len = req_len - 1;
              end

              if (req_len)
              begin
                s_axis_tx_tdata[127:120] = req_data[(sel) +: 8];
                s_axis_tx_tdata[119:112] = req_data[(sel+8) +: 8];
                s_axis_tx_tdata[111:104] = req_data[(sel+16) +: 8];
                s_axis_tx_tdata[103:96] = req_data[(sel+24) +: 8];
                s_axis_tx_tkeep[15:12] = 4'b1111;
                sel = sel + 32;
                req_len = req_len - 1;
              end
            end
            else
            begin
              req_data = wr_data;

              req_header[0][31:0] = fifo_out[31:0];
              req_header[1][31:0] = fifo_out[63:32];
              req_header[2][31:0] = fifo_out[95:64];
              req_header[3][31:0] = fifo_out[127:96];

              req_type = req_header[0][31:24];
              req_len = req_header[0][9:0];

              s_axis_tx_tdata[31:0] = req_header[0];
              s_axis_tx_tkeep[3:0] = 4'b1111;

              s_axis_tx_tdata[63:32] = req_header[1];
              s_axis_tx_tkeep[7:4] = 4'b1111;

              s_axis_tx_tdata[95:64] = req_header[2];
              s_axis_tx_tkeep[11:8] = 4'b1111;

              sel = 0;
              if (req_type[5] == 0)  // 3 DW header
              begin
                if (req_len)
                begin
                  s_axis_tx_tdata[127:120] = req_data[7:0];
                  s_axis_tx_tdata[119:112] = req_data[15:8];
                  s_axis_tx_tdata[111:104] = req_data[23:16];
                  s_axis_tx_tdata[103:96] = req_data[31:24];
                  s_axis_tx_tkeep[15:12] = 4'b1111;
                  req_len = req_len - 1;
                  sel = 32;
                end
              end
              else
              begin
                s_axis_tx_tdata[127:96] = req_header[3];
                s_axis_tx_tkeep[15:12] = 4'b1111;
              end  
              header_done = 1'b1;
            end

            s_axis_tx_tvalid  = 1'b1;

            if (req_len)
              s_axis_tx_tlast = 1'b0;
            else
            begin
              s_axis_tx_tlast = 1'b1;
              fifo_rd = 1'b1;
              header_done = 1'b0;
            end
          end
        end 
      end
    end
  endgenerate

endmodule
