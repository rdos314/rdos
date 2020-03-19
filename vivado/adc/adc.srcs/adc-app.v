module adc_app (
  clk,
  reset,

  adc_fifo_empty,
  adc_fifo_data,
  adc_send,
  adc_address,
  adc_data,

  address,
  rd,
  rp,
  rp_data,
  wr,
  wr_be,
  wr_data,
  ack
);

  input wire             clk;
  input wire             reset;

  input wire             adc_fifo_empty;
  input wire [111:0]     adc_fifo_data;
  output reg             adc_send;
  output reg [63:0]      adc_address;
  output reg [1023:0]    adc_data;

  input wire [16:0]      address;
  input wire             rd;
  output reg             rp;
  output reg [31:0]      rp_data;
  input wire             wr;
  input wire [3:0]       wr_be;
  input wire [31:0]      wr_data;
  output reg             ack;

// local bar
  reg  [15:0]            adc_wr_adr;
  reg  [19:0]            adc_wr_data;
  reg  [19:0]            next_rd_adr;
  reg  [15:0]            adc_rd_adr;
  wire [19:0]            adc_rd_data;

  reg  [15:0]            curr_adr;
  reg  [19:0]            curr_data;

// PCIe domain
  reg  [1023:0]          adc_curr;  
  reg  [2:0]             adc_cnt;  

  reg  [15:0]            sample_index;
  reg  [63:0]            next_address;


bram_adc bram_adc_inst (
  .clka(clk),          // input wire clka
  .wea(ack),           // input wire [0 : 0] wea
  .addra(adc_wr_adr),  // input wire [15 : 0] addra
  .dina(adc_wr_data),  // input wire [19 : 0] dina
  .clkb(clk),          // input wire clkb
  .addrb(next_rd_adr), // input wire [15 : 0] addrb
  .doutb(adc_rd_data)  // output wire [19 : 0] doutb
);

ila_3 ila3_inst (
   .clk ( clk ),                      // I
   .probe0(adc_fifo_empty),           // input wire [0:0]  probe1 
   .probe1(adc_cnt),                  // input wire [2:0]  probe1 
   .probe2(adc_send),                 // input wire [0:0]  probe1 
   .probe3(adc_curr[927:896]),        // input wire [31:0]  probe1 
   .probe4(adc_curr[961:928]),        // input wire [31:0]  probe1 
   .probe5(adc_curr[991:960]),        // input wire [31:0]  probe1 
   .probe6(adc_curr[1023:992]),       // input wire [31:0]  probe1 
   .probe7(adc_data[31:0]),           // input wire [31:0]  probe1 
   .probe8(adc_data[63:32]),          // input wire [31:0]  probe1 
   .probe9(adc_data[95:64]),          // input wire [31:0]  probe1 
   .probe10(adc_data[127:96])         // input wire [31:0]  probe1 
);

ila_4 ila4_inst (
   .clk ( clk ),                       // I
   .probe0(address),                   // input wire [16:0]  probe1 
   .probe1(rd),                        // input wire [0:0]  probe1 
   .probe2(rp),                        // input wire [0:0]  probe1 
   .probe3(rp_data),                   // input wire [31:0]  probe1 
   .probe4(wr),                        // input wire [0:0]  probe1 
   .probe5(wr_be),                     // input wire [3:0]  probe1 
   .probe6(wr_data),                   // input wire [31:0]  probe1 
   .probe7(ack),                       // input wire [0:0]  probe1 
   .probe8(adc_wr_adr),                // input wire [15:0]  probe1 
   .probe9(adc_wr_data),               // input wire [19:0]  probe1 
   .probe10(adc_rd_adr),               // input wire [15:0]  probe1 
   .probe11(adc_rd_data),              // input wire [19:0]  probe1 
   .probe12(next_rd_adr)               // input wire [19:0]  probe1 
);

generate
begin : adc_app

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      ack <= 0;
      rp <= 0;
      adc_rd_adr <= 0;
    end
    else
    begin
      if (rd || wr)
      begin
        if (adc_wr_adr == address[16:1])
        begin
          curr_adr = adc_wr_adr;
          curr_data = adc_wr_data;
        end
        else
        begin
          curr_adr = adc_rd_adr;
          curr_data = adc_rd_data;
        end

        if (adc_rd_adr == address[16:1])
          next_rd_adr <= sample_index;
        else
          next_rd_adr <= address[16:1]; 
      end
      else
        next_rd_adr <= sample_index;

      adc_rd_adr <= next_rd_adr;

      if (rd || wr)
      begin
        if (curr_adr == address[16:1])
        begin
          if (wr)
          begin
            if (address[0])
            begin
              if (wr_be[0])
                curr_data[18:11] = wr_data[7:0];

              if (wr_be[1])
                curr_data[19] = wr_data[8];
            end
            else
            begin
              if (wr_be[2])
                curr_data[2:0] = wr_data[23:21];

              if (wr_be[3])
                curr_data[10:3] = wr_data[31:24];
            end

            adc_wr_adr <= curr_adr;
            adc_wr_data <= curr_data;
            ack <= 1;
            rp <= 0;
          end
          else
          begin
            if (address[0])
            begin
              rp_data[8:0] <= curr_data[19:11];
              rp_data[31:9] <= 0;
            end
            else
            begin
              rp_data[20:0] <= 0;
              rp_data[31:21] <= curr_data[10:0];
            end

            adc_wr_adr <= curr_adr;
            adc_wr_data <= curr_data;    
            ack <= 0;
            rp <= 1;
          end
        end
        else
        begin
          ack <= 0;
          rp <= 0;
        end
      end
      else
      begin
        ack <= 0;
        rp <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      adc_cnt <= 0;
      adc_send <= 0;
    end
    else
    begin
      if (adc_fifo_empty)
        adc_send <= 0;
      else
      begin
        adc_curr[909:896] <= adc_fifo_data[13:0];
        adc_curr[910] <= adc_fifo_data[13];
        adc_curr[911] <= adc_fifo_data[13];
        adc_curr[925:912] <= adc_fifo_data[27:14];
        adc_curr[926] <= adc_fifo_data[27];
        adc_curr[927] <= adc_fifo_data[27];

        adc_curr[941:928] <= adc_fifo_data[41:28];
        adc_curr[942] <= adc_fifo_data[41];
        adc_curr[943] <= adc_fifo_data[41];
        adc_curr[957:944] <= adc_fifo_data[55:42];
        adc_curr[958] <= adc_fifo_data[55];
        adc_curr[959] <= adc_fifo_data[55];

        adc_curr[973:960] <= adc_fifo_data[69:56];
        adc_curr[974] <= adc_fifo_data[69];
        adc_curr[975] <= adc_fifo_data[69];
        adc_curr[989:976] <= adc_fifo_data[83:70];
        adc_curr[990] <= adc_fifo_data[83];
        adc_curr[991] <= adc_fifo_data[83];

        adc_curr[1005:992] <= adc_fifo_data[97:84];
        adc_curr[1006] <= adc_fifo_data[97];
        adc_curr[1007] <= adc_fifo_data[97];
        adc_curr[1021:1008] <= adc_fifo_data[111:98];
        adc_curr[1022] <= adc_fifo_data[111];
        adc_curr[1023] <= adc_fifo_data[111];

        adc_curr[895:0] <= adc_curr[1023:128];

        adc_cnt <= adc_cnt + 1;

        if (adc_cnt == 7)
        begin
          adc_data <= adc_curr;
          adc_send <= 1;
        end
        else
          adc_send <= 0;
      end
    end
  end

end
endgenerate

endmodule
