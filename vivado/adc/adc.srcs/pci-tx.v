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

  reg         data_pos;
  reg         header_done;

  reg [7:0]   req_type;
  reg [9:0]   req_len;
  reg [31:0]  req_header   [3:0];
  reg [31:0]  req_data    [31:0];
      
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
                s_axis_tx_tdata[31:24] = req_data[data_pos][7:0];
                s_axis_tx_tdata[23:16] = req_data[data_pos][15:8];
                s_axis_tx_tdata[15:8] = req_data[data_pos][23:16];
                s_axis_tx_tdata[7:0] = req_data[data_pos][31:24];
                s_axis_tx_tkeep[3:0] = 4'b1111;
                data_pos = data_pos + 1;
                req_len = req_len - 1;
              end
 
              if (req_len)
              begin
                s_axis_tx_tdata[63:56] = req_data[data_pos][7:0];
                s_axis_tx_tdata[55:48] = req_data[data_pos][15:8];
                s_axis_tx_tdata[47:40] = req_data[data_pos][23:16];
                s_axis_tx_tdata[39:32] = req_data[data_pos][31:24];
                s_axis_tx_tkeep[7:4] = 4'b1111;
                data_pos = data_pos + 1;
                req_len = req_len - 1;
              end

              if (req_len)
              begin
                s_axis_tx_tdata[95:88] = req_data[data_pos][7:0];
                s_axis_tx_tdata[87:80] = req_data[data_pos][15:8];
                s_axis_tx_tdata[79:72] = req_data[data_pos][23:16];
                s_axis_tx_tdata[71:64] = req_data[data_pos][31:24];
                s_axis_tx_tkeep[11:8] = 4'b1111;
                data_pos = data_pos + 1;
                req_len = req_len - 1;
              end

              if (req_len)
              begin
                s_axis_tx_tdata[127:120] = req_data[data_pos][7:0];
                s_axis_tx_tdata[119:112] = req_data[data_pos][15:8];
                s_axis_tx_tdata[111:104] = req_data[data_pos][23:16];
                s_axis_tx_tdata[103:96] = req_data[data_pos][31:24];
                s_axis_tx_tkeep[15:12] = 4'b1111;
                data_pos = data_pos + 1;
                req_len = req_len - 1;
              end
            end
            else
            begin
              req_data[0][31:0] = wr_data[31:0];
              req_data[1][31:0] = wr_data[63:32];
              req_data[2][31:0] = wr_data[95:64];
              req_data[3][31:0] = wr_data[127:96];
              req_data[4][31:0] = wr_data[159:128];
              req_data[5][31:0] = wr_data[191:160];
              req_data[6][31:0] = wr_data[223:192];
              req_data[7][31:0] = wr_data[255:224];
              req_data[8][31:0] = wr_data[287:256];
              req_data[9][31:0] = wr_data[319:288];
              req_data[10][31:0] = wr_data[351:320];
              req_data[11][31:0] = wr_data[383:352];
              req_data[12][31:0] = wr_data[415:384];
              req_data[13][31:0] = wr_data[447:416];
              req_data[14][31:0] = wr_data[479:448];
              req_data[15][31:0] = wr_data[511:480];
              req_data[16][31:0] = wr_data[543:512];
              req_data[17][31:0] = wr_data[575:544];
              req_data[18][31:0] = wr_data[607:576];
              req_data[19][31:0] = wr_data[639:608];
              req_data[20][31:0] = wr_data[671:640];
              req_data[21][31:0] = wr_data[703:672];
              req_data[22][31:0] = wr_data[735:704];
              req_data[23][31:0] = wr_data[767:736];
              req_data[24][31:0] = wr_data[799:768];
              req_data[25][31:0] = wr_data[831:800];
              req_data[26][31:0] = wr_data[863:832];
              req_data[27][31:0] = wr_data[895:864];
              req_data[28][31:0] = wr_data[927:896];
              req_data[29][31:0] = wr_data[959:928];
              req_data[30][31:0] = wr_data[991:960];
              req_data[31][31:0] = wr_data[1023:992];

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

              if (req_type[5] == 0)  // 3 DW header
              begin
                if (req_len)
                begin
                  s_axis_tx_tdata[127:120] = req_data[0][7:0];
                  s_axis_tx_tdata[119:112] = req_data[0][15:8];
                  s_axis_tx_tdata[111:104] = req_data[0][23:16];
                  s_axis_tx_tdata[103:96] = req_data[0][31:24];
                  s_axis_tx_tkeep[15:12] = 4'b1111;
                  req_len = req_len - 1;
                  data_pos = 1;
                end
              end
              else
              begin
                s_axis_tx_tdata[127:96] = req_header[3];
                s_axis_tx_tkeep[15:12] = 4'b1111;
                data_pos = 0;
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
