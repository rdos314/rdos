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
  bram_be,
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
  input  wire [127:0]             bram_be;
  output  reg [3:0]               bram_rd_ptr;
  input  wire [3:0]               bram_wr_ptr;

// FF
  reg [3:0]    q_pos;
  reg [9:0]    q_remain_size;
  reg [3:0]    q_first_be;
  reg [3:0]    q_last_be;


// local

  reg          is_first;
  reg [3:0]    calc_pos;
  reg [9:0]    calc_blk_size;
  reg [9:0]    calc_remain_size;
  reg [3:0]    calc_first_be;
  reg [3:0]    calc_last_be;

  reg          has_data;

  reg [7:0]    req_type;
  reg [9:0]    req_len;
  reg [191:0]  req_header;
  reg [1023:0] req_data;


ila_2 ila_2_inst (
	.clk(clk),                         // input wire clk
	.probe0(s_axis_tx_tvalid),         // input wire [0:0]  probe0  
	.probe1(s_axis_tx_tready),         // input wire [0:0]  probe0  
	.probe2(s_axis_tx_tlast),          // input wire [0:0]  probe0  
	.probe3(s_axis_tx_tkeep),          // input wire [15:0]  probe0  
	.probe4(s_axis_tx_tdata[63:0]),    // input wire [63:0]  probe0  
	.probe5(s_axis_tx_tdata[127:64]),  // input wire [63:0]  probe0  
	.probe6(is_first),                 // input wire [0:0]  probe0  
	.probe7(calc_pos),                 // input wire [3:0]  probe0  
	.probe8(calc_blk_size),            // input wire [9:0]  probe0  
	.probe9(calc_remain_size),         // input wire [9:0]  probe0  
	.probe10(req_type),                 // input wire [7:0]  probe0  
	.probe11(req_len),                  // input wire [0:0]  probe0  
	.probe12(req_header[0]),           // input wire [31:0]  probe0  
	.probe13(req_header[1]),           // input wire [31:0]  probe0  
	.probe14(req_header[2]),           // input wire [31:0]  probe0  
	.probe15(req_header[3])            // input wire [31:0]  probe0  
);

generate
  begin : gen_cpl_128

    always @ ( posedge clk ) 
    begin
      has_data = 0;

      if (reset) 
        calc_remain_size = 0;
      else
      begin
        if (s_axis_tx_tready)
        begin
          if (q_remain_size)
          begin
            is_first = 0;
            has_data = 1;
          end
          else
          begin
            is_first = 1;

             if (bram_wr_ptr == bram_rd_ptr)
               has_data = 0;
             else
               has_data = 1;                
          end
        end
      end 

      if (has_data)
      begin
        if (is_first)
        begin
          calc_pos = 0;

          req_type = bram_header[31:24];
          req_len = bram_header[9:0];

          if (req_type[5] == 0)  // 3 DW header
            calc_blk_size = 1;

          if (req_type[6])
            calc_remain_size = 0;
          else
            calc_remain_size = req_len;

          calc_first_be = 4'b1111;
          calc_last_be = 4'b1111;
        end
        else
        begin
          calc_blk_size = 4;

          calc_pos = q_pos;
          calc_remain_size = q_remain_size;

          calc_first_be = q_first_be;
          calc_last_be = q_last_be;
        end
      end
      else
        calc_blk_size = 0;

// FF part

      if (reset)
        bram_rd_ptr <= 0;

      if (has_data)
      begin
        if (is_first)
        begin
          q_first_be <= calc_first_be;
          q_last_be <= calc_last_be;

          if (req_type[5] == 0)  // 3 DW header
          begin
            s_axis_tx_tdata[95:0] <= bram_header[95:0];
            s_axis_tx_tkeep[11:0] <= 12'hfff;

            if (calc_blk_size)
            begin
              s_axis_tx_tdata[127:120] <= bram_data[7:0];
              s_axis_tx_tdata[119:112] <= bram_data[15:8];
              s_axis_tx_tdata[111:104] <= bram_data[23:16];
              s_axis_tx_tdata[103:96] <= bram_data[31:24];
              s_axis_tx_tkeep[15:12] <= calc_first_be;
            end
            else
              s_axis_tx_tkeep[15:12] <= 4'b0000;
          end
          else
          begin
            s_axis_tx_tdata[127:0] <= bram_header[127:0];
            s_axis_tx_tkeep[15:0] <= 16'hffff;
          end
        end
        else
        begin
          if (calc_blk_size)
          begin
            s_axis_tx_tdata[31:24] <= bram_data[(32*calc_pos) +: 8];
            s_axis_tx_tdata[23:16] <= bram_data[(32*calc_pos+8) +: 8];
            s_axis_tx_tdata[15:8] <= bram_data[(32*calc_pos+16) +: 8];
            s_axis_tx_tdata[7:0] <= bram_data[(32*calc_pos+24) +: 8];

            if (calc_pos)
            begin
              if ((calc_remain_size == calc_blk_size) && (calc_blk_size == 1))
                s_axis_tx_tkeep[3:0] <= calc_last_be;
              else
                s_axis_tx_tkeep[3:0] <= 4'b1111;
            end
            else
              s_axis_tx_tkeep[3:0] <= calc_first_be;
          end
          else
            s_axis_tx_tkeep[3:0] <= 4'b0000;
               
          if (calc_blk_size > 1)
          begin
            s_axis_tx_tdata[63:56] <= bram_data[(32*(calc_pos+1)) +: 8];
            s_axis_tx_tdata[55:48] <= bram_data[(32*(calc_pos+1)+8) +: 8];
            s_axis_tx_tdata[47:40] <= bram_data[(32*(calc_pos+1)+16) +: 8];
            s_axis_tx_tdata[39:32] <= bram_data[(32*(calc_pos+1)+24) +: 8];
 
            if ((calc_remain_size == calc_blk_size) && (calc_blk_size == 2))
              s_axis_tx_tkeep[7:4] <= calc_last_be;
            else
              s_axis_tx_tkeep[7:4] <= 4'b1111;
          end
          else
            s_axis_tx_tkeep[7:4] <= 4'b0000;

          if (calc_blk_size > 2)
          begin
            s_axis_tx_tdata[95:88] <= bram_data[(32*(calc_pos+2)) +: 8];
            s_axis_tx_tdata[87:80] <= bram_data[(32*(calc_pos+2)+8) +: 8];
            s_axis_tx_tdata[79:72] <= bram_data[(32*(calc_pos+2)+16) +: 8];
            s_axis_tx_tdata[71:64] <= bram_data[(32*(calc_pos+2)+24) +: 8];

            if ((calc_remain_size == calc_blk_size) && (calc_blk_size == 3))
              s_axis_tx_tkeep[11:8] <= calc_last_be;
            else
              s_axis_tx_tkeep[11:8] <= 4'b1111;
          end
          else
            s_axis_tx_tkeep[11:8] <= 4'b0000;

          if (calc_blk_size > 3)
          begin
            s_axis_tx_tdata[127:120] <= bram_data[(32*(calc_pos+3)) +: 8];
            s_axis_tx_tdata[119:112] <= bram_data[(32*(calc_pos+3)+8) +: 8];
            s_axis_tx_tdata[111:104] <= bram_data[(32*(calc_pos+3)+16) +: 8];
            s_axis_tx_tdata[103:96] <= bram_data[(32*(calc_pos+3)+24) +: 8];
 
            if ((calc_remain_size == calc_blk_size) && (calc_blk_size == 4))
              s_axis_tx_tkeep[15:12] <= calc_last_be;
            else
             s_axis_tx_tkeep[15:12] <= 4'b1111;
          end
          else
            s_axis_tx_tkeep[15:12] <= 4'b0000;
        end

        q_remain_size <= calc_remain_size - calc_blk_size;
        q_pos <= calc_pos + calc_blk_size;

        s_axis_tx_tvalid  <= 1;

        if (calc_remain_size == calc_blk_size)
        begin
          bram_rd_ptr <= bram_rd_ptr + 1;
          s_axis_tx_tlast <= 1;
        end
        else
          s_axis_tx_tlast <= 0;
      end
      else
        s_axis_tx_tvalid  <= 0;
    end

  end
endgenerate

endmodule
