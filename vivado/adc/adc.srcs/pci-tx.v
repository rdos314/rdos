module pci_tx (
  clk,
  reset,
  s_axis_tx_tready,
  s_axis_tx_tdata,
  s_axis_tx_tkeep,
  s_axis_tx_tlast,
  s_axis_tx_tvalid,
  s_axis_tx_tuser,

  bram_data,
  bram_header,
  bram_rd_ptr,
  bram_wr_ptr
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

  input  wire [1023:0]            bram_data;
  input  wire [191:0]             bram_header;
  output  reg [3:0]               bram_rd_ptr;
  input  wire [3:0]               bram_wr_ptr;


// local

  reg [3:0]    sel;
  reg          header_done;
  reg          update_ptr;

  reg [7:0]    req_type;
  reg [9:0]    req_len;
  reg [31:0]   req_header   [3:0];

  generate
    begin : gen_cpl_128

      always @ ( posedge clk ) begin
        s_axis_tx_tuser[0] = 1'b0;                // Unused for V6
        s_axis_tx_tuser[1] = 1'b0;                // Error forward packet
        s_axis_tx_tuser[2] = 1'b0;                // Stream packet
        s_axis_tx_tuser[3] = 1'b0;                // tx_src_dsc
        s_axis_tx_tkeep = 16'b0;

        if (update_ptr)
        begin
          bram_rd_ptr = bram_rd_ptr + 1;
          update_ptr = 0;
        end

        if (reset) 
        begin
          s_axis_tx_tlast   = 1'b0;
          s_axis_tx_tvalid  = 1'b0;
          header_done = 0;
          update_ptr = 0;
        end
        else
        begin
          if (s_axis_tx_tready && bram_rd_ptr != bram_wr_ptr)
          begin
            if (header_done)
            begin
              if (req_len)
              begin
                s_axis_tx_tdata[31:24] = bram_data[(32*sel) +: 8];
                s_axis_tx_tdata[23:16] = bram_data[(32*sel+8) +: 8];
                s_axis_tx_tdata[15:8] = bram_data[(32*sel+16) +: 8];
                s_axis_tx_tdata[7:0] = bram_data[(32*sel+24) +: 8];
                s_axis_tx_tkeep[3:0] = 4'b1111;
                sel = sel + 1;
                req_len = req_len - 1;
              end
 
              if (req_len)
              begin
                s_axis_tx_tdata[63:56] = bram_data[(32*sel) +: 8];
                s_axis_tx_tdata[55:48] = bram_data[(32*sel+8) +: 8];
                s_axis_tx_tdata[47:40] = bram_data[(32*sel+16) +: 8];
                s_axis_tx_tdata[39:32] = bram_data[(32*sel+24) +: 8];
                s_axis_tx_tkeep[7:4] = 4'b1111;
                sel = sel + 1;
                req_len = req_len - 1;
              end

              if (req_len)
              begin
                s_axis_tx_tdata[95:88] = bram_data[(32*sel) +: 8];
                s_axis_tx_tdata[87:80] = bram_data[(32*sel+8) +: 8];
                s_axis_tx_tdata[79:72] = bram_data[(32*sel+16) +: 8];
                s_axis_tx_tdata[71:64] = bram_data[(32*sel+24) +: 8];
                s_axis_tx_tkeep[11:8] = 4'b1111;
                sel = sel + 1;
                req_len = req_len - 1;
              end

              if (req_len)
              begin
                s_axis_tx_tdata[127:120] = bram_data[(32*sel) +: 8];
                s_axis_tx_tdata[119:112] = bram_data[(32*sel+8) +: 8];
                s_axis_tx_tdata[111:104] = bram_data[(32*sel+16) +: 8];
                s_axis_tx_tdata[103:96] = bram_data[(32*sel+24) +: 8];                
                s_axis_tx_tkeep[15:12] = 4'b1111;
                sel = sel + 1;
                req_len = req_len - 1;
              end
            end
            else
            begin
              req_header[0][31:0] = bram_header[31:0];
              req_header[1][31:0] = bram_header[63:32];
              req_header[2][31:0] = bram_header[95:64];
              req_header[3][31:0] = bram_header[127:96];

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
                  s_axis_tx_tdata[127:120] = bram_data[7:0];
                  s_axis_tx_tdata[119:112] = bram_data[15:8];
                  s_axis_tx_tdata[111:104] = bram_data[23:16];
                  s_axis_tx_tdata[103:96] = bram_data[31:24];
                  s_axis_tx_tkeep[15:12] = 4'b1111;
                  req_len = req_len - 1;
                  sel = 1;
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
              header_done = 0;
              update_ptr = 1;
            end
          end
        end 
      end
    end
  endgenerate

endmodule
