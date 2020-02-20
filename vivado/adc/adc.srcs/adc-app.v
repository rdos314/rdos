module adc_app (
  clk,
  reset,
  sample_clk,

  adc_start,
  adc_stop,
  adc_running,

  address,
  rd,
  rp,
  rp_address,
  rp_data,
  wr,
  wr_be,
  wr_data,
  ack
);

  input wire             clk;
  input wire             reset;
  input wire             sample_clk;

  input wire             adc_start;
  input wire             adc_stop;
  output reg             adc_running;

  input wire [16:0]      address;
  input wire             rd;
  output reg             rp;
  output reg [4:0]       rp_address;
  output reg [31:0]      rp_data;
  input wire             wr;
  input wire [3:0]       wr_be;
  input wire [31:0]      wr_data;
  output reg             ack;

// local BAR
  reg                    adc_wr;
  reg  [15:0]            adc_wr_adr;
  reg  [19:0]            adc_wr_data;
  reg  [15:0]            adc_rd_adr;
  wire [19:0]            adc_rd_data;
  reg  [63:0]            curr_data;

// sampling

// sample domain
  reg                    running;
  reg                    first;
  reg  [3:0]             sample_counter;
  reg  [13:0]            curr_ch0;
  reg  [13:0]            curr_ch1;
  reg  [223:0]           sample_buffer0;
  reg  [223:0]           sample_buffer1;

// domain sync
  reg                    req_start;
  reg                    req_stop;
  reg                    notify_sample_data;
  reg                    ack_sample_data;
  reg                    sample_sync;
  reg  [223:0]           sync_buffer0;
  reg  [223:0]           sync_buffer1;

// PCIe domain
  reg                    pend_start;
  reg  [511:0]           synced_buffer;
  reg  [1023:0]          sample_data;
  reg                    sample_load;
  reg                    sample_low;
  reg                    has_sample_data;


bram_adc bram_adc_inst (
  .clka(clk),          // input wire clka
  .wea(adc_wr),        // input wire [0 : 0] wea
  .addra(adc_wr_adr),  // input wire [15 : 0] addra
  .dina(adc_wr_data),  // input wire [19 : 0] dina
  .clkb(clk),          // input wire clkb
  .addrb(adc_rd_adr),  // input wire [15 : 0] addrb
  .doutb(adc_rd_data)  // output wire [19 : 0] doutb
);

ila_3 ila3_inst (
   .clk ( clk ),                       // I
   .probe0(address),                   // input wire [16:0]  probe1 
   .probe1(rd),                        // input wire [0:0]  probe1 
   .probe2(rp),                        // input wire [0:0]  probe1 
   .probe3(rp_address),                // input wire [4:0]  probe1 
   .probe4(rp_data),                   // input wire [31:0]  probe1 
   .probe5(wr),                        // input wire [0:0]  probe1 
   .probe6(wr_be),                     // input wire [3:0]  probe1 
   .probe7(wr_data),                   // input wire [31:0]  probe1 
   .probe8(ack),                       // input wire [0:0]  probe1 
   .probe9(adc_wr),                    // input wire [0:0]  probe1 
   .probe10(adc_wr_adr),               // input wire [15:0]  probe1 
   .probe11(adc_wr_data),              // input wire [19:0]  probe1 
   .probe12(adc_rd_adr),               // input wire [15:0]  probe1 
   .probe13(adc_rd_data),              // input wire [19:0]  probe1 
   .probe14(curr_data)                 // input wire [63:0]  probe1 
);

ila_4 ila4_inst (
   .clk ( clk ),                       // I
   .probe0(pend_start),                // input wire [0:0]  probe1 
   .probe1(req_start),                 // input wire [0:0]  probe1 
   .probe2(req_stop),                  // input wire [0:0]  probe1 
   .probe3(adc_start),                 // input wire [0:0]  probe1 
   .probe4(adc_stop),                  // input wire [0:0]  probe1 
   .probe5(adc_running),               // input wire [0:0]  probe1 
   .probe6(ack_sample_data),           // input wire [0:0]  probe1 
   .probe7(sample_sync),               // input wire [0:0]  probe1 
   .probe8(sample_load),               // input wire [0:0]  probe1 
   .probe9(sample_low),                // input wire [0:0]  probe1 
   .probe10(has_sample_data),          // input wire [0:0]  probe1 
   .probe11(synced_buffer[31:0]),      // input wire [31:0]  probe1 
   .probe12(synced_buffer[63:32]),     // input wire [31:0]  probe1 
   .probe13(synced_buffer[95:64]),     // input wire [31:0]  probe1 
   .probe14(synced_buffer[127:96]),    // input wire [31:0]  probe1 
   .probe15(synced_buffer[159:128]),   // input wire [31:0]  probe1 
   .probe16(synced_buffer[191:160]),   // input wire [31:0]  probe1 
   .probe17(synced_buffer[223:192]),   // input wire [31:0]  probe1 
   .probe18(synced_buffer[255:224]),   // input wire [31:0]  probe1 
   .probe19(synced_buffer[287:256]),   // input wire [31:0]  probe1 
   .probe20(synced_buffer[319:288]),   // input wire [31:0]  probe1 
   .probe21(synced_buffer[351:320]),   // input wire [31:0]  probe1 
   .probe22(synced_buffer[383:352]),   // input wire [31:0]  probe1 
   .probe23(synced_buffer[415:384]),   // input wire [31:0]  probe1 
   .probe24(synced_buffer[447:416]),   // input wire [31:0]  probe1 
   .probe25(synced_buffer[479:448]),   // input wire [31:0]  probe1 
   .probe26(synced_buffer[511:480])    // input wire [31:0]  probe1 
);

generate
begin : adc_app

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      ack <= 0;
      rp <= 0;
      adc_wr <= 0;
    end
    else
    begin
      if (wr)
      begin
        if (adc_rd_adr == address[16:1])
        begin
          curr_data[20:0] = 0;
          curr_data[40:21] = adc_rd_data;
          curr_data[63:41] = 0;

          if (address[0])
          begin
            if (wr_be[0])
              curr_data[39:32] = wr_data[7:0];

            if (wr_be[1])
              curr_data[47:40] = wr_data[15:8];
 
            if (wr_be[2])
              curr_data[55:48] = wr_data[23:16];

            if (wr_be[3])
              curr_data[63:56] = wr_data[31:24];
          end
          else
          begin
            if (wr_be[0])
              curr_data[7:0] = wr_data[7:0];

            if (wr_be[1])
              curr_data[15:8] = wr_data[15:8];
 
            if (wr_be[2])
              curr_data[23:16] = wr_data[23:16];

            if (wr_be[3])
              curr_data[31:24] = wr_data[31:24];
          end
        end
      end
    
      if (rd)
      begin
        if (adc_rd_adr == address[16:1])
        begin
          rp_address <= address[4:0];
          rp <= 1;

          if (address[0])
          begin
            rp_data[8:0] <= adc_rd_data[19:11];
            rp_data[31:9] <= 0;
          end
          else
          begin
            rp_data[20:0] <= 0;
            rp_data[31:21] <= adc_rd_data[10:0];
          end
        end
        else
        begin
          rp <= 0;
          adc_rd_adr <= address[16:1];
        end
      end
      else
        rp <= 0;

      if (wr)
      begin
        if (adc_rd_adr == address[16:1])
        begin
          adc_wr_data <= curr_data[40:21];
          adc_wr_adr = address[16:1];
          adc_wr <= 1;
          ack <= 1;
        end
        else
        begin
          adc_wr <= 0;
          ack <= 0;
          adc_rd_adr <= address[16:1];
        end
      end
      else
      begin
        ack <= 0;
        adc_wr <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      pend_start <= 0;
      req_start <= 0;
      req_stop <= 1;
      ack_sample_data <= 0;
      sample_sync <= 0;
      sample_load <= 0;
      sample_low <= 0;
      has_sample_data <= 0;
    end
    else
    begin
      if (adc_running)
        req_start <= 0;
      else
      begin
        req_stop <= 0;
        ack_sample_data <= 0;
        sample_sync <= 0;
        sample_load <= 0;
     end

     if (adc_start && !adc_running)
       pend_start <= 1;

     if (adc_stop && adc_running)
       req_stop <= 1;

      if (notify_sample_data && !ack_sample_data && !sample_sync && !sample_load)
      begin
        ack_sample_data <= 1;
        sample_sync <= 1;
      end

      if (sample_sync)
      begin
        sample_sync <= 0;
        sample_load <= 1;
        ack_sample_data <= 0;

        synced_buffer[13:0] <= sync_buffer0[13:0];
        if (sync_buffer0[13])
          synced_buffer[15:14] <= 2'b11;
        else
          synced_buffer[15:14] <= 2'b00;
        
        synced_buffer[29:16] <= sync_buffer1[13:0];
        if (sync_buffer1[13])
          synced_buffer[31:30] <= 2'b11;
        else
          synced_buffer[31:30] <= 2'b00;

        synced_buffer[45:32] <= sync_buffer0[27:14];
        if (sync_buffer0[27])
          synced_buffer[47:46] <= 2'b11;
        else
          synced_buffer[47:46] <= 2'b00;

        synced_buffer[61:48] <= sync_buffer1[27:14];
        if (sync_buffer1[27])
          synced_buffer[63:62] <= 2'b11;
        else
          synced_buffer[63:62] <= 2'b00;

        synced_buffer[77:64] <= sync_buffer0[41:28];
        if (sync_buffer0[41])
          synced_buffer[79:78] <= 2'b11;
        else
          synced_buffer[79:78] <= 2'b00;

        synced_buffer[93:80] <= sync_buffer1[41:28];
        if (sync_buffer1[41])
          synced_buffer[95:94] <= 2'b11;
        else
          synced_buffer[95:94] <= 2'b00;

        synced_buffer[109:96] <= sync_buffer0[55:42];
        if (sync_buffer0[55])
          synced_buffer[111:110] <= 2'b11;
        else
          synced_buffer[111:110] <= 2'b00;

        synced_buffer[125:112] <= sync_buffer1[55:42];
        if (sync_buffer1[55])
          synced_buffer[127:126] <= 2'b11;
        else
          synced_buffer[127:126] <= 2'b00;

        synced_buffer[141:128] <= sync_buffer0[69:56];
        if (sync_buffer0[69])
          synced_buffer[143:142] <= 2'b11;
        else
          synced_buffer[143:142] <= 2'b00;

        synced_buffer[157:144] <= sync_buffer1[69:56];
        if (sync_buffer1[69])
          synced_buffer[159:158] <= 2'b11;
        else
          synced_buffer[159:158] <= 2'b00;

        synced_buffer[173:160] <= sync_buffer0[83:70];
        if (sync_buffer0[83])
          synced_buffer[175:174] <= 2'b11;
        else
          synced_buffer[175:174] <= 2'b00;

        synced_buffer[189:176] <= sync_buffer1[83:70];
        if (sync_buffer1[83])
          synced_buffer[191:190] <= 2'b11;
        else
          synced_buffer[191:190] <= 2'b00;

        synced_buffer[205:192] <= sync_buffer0[97:84];
        if (sync_buffer0[97])
          synced_buffer[207:206] <= 2'b11;
        else
          synced_buffer[207:206] <= 2'b00;

        synced_buffer[221:208] <= sync_buffer1[97:84];
        if (sync_buffer1[97])
          synced_buffer[223:222] <= 2'b11;
        else
          synced_buffer[223:222] <= 2'b00;

        synced_buffer[237:224] <= sync_buffer0[111:98];
        if (sync_buffer0[111])
          synced_buffer[239:238] <= 2'b11;
        else
          synced_buffer[239:238] <= 2'b00;

        synced_buffer[253:240] <= sync_buffer1[111:98];
        if (sync_buffer1[111])
          synced_buffer[255:254] <= 2'b11;
        else
          synced_buffer[255:254] <= 2'b00;

        synced_buffer[269:256] <= sync_buffer0[125:112];
        if (sync_buffer0[125])
          synced_buffer[271:270] <= 2'b11;
        else
          synced_buffer[271:270] <= 2'b00;

        synced_buffer[285:272] <= sync_buffer1[125:112];
        if (sync_buffer1[125])
          synced_buffer[287:286] <= 2'b11;
        else
          synced_buffer[287:286] <= 2'b00;

        synced_buffer[301:288] <= sync_buffer0[139:126];
        if (sync_buffer0[139])
          synced_buffer[303:302] <= 2'b11;
        else
          synced_buffer[303:302] <= 2'b00;

        synced_buffer[317:304] <= sync_buffer1[139:126];
        if (sync_buffer1[139])
          synced_buffer[319:318] <= 2'b11;
        else
          synced_buffer[319:318] <= 2'b00;

        synced_buffer[333:320] <= sync_buffer0[153:140];
        if (sync_buffer0[153])
          synced_buffer[335:334] <= 2'b11;
        else
          synced_buffer[335:334] <= 2'b00;

        synced_buffer[349:336] <= sync_buffer1[153:140];
        if (sync_buffer1[153])
          synced_buffer[351:350] <= 2'b11;
        else
          synced_buffer[351:350] <= 2'b00;

        synced_buffer[365:352] <= sync_buffer0[167:154];
        if (sync_buffer0[167])
          synced_buffer[367:366] <= 2'b11;
        else
          synced_buffer[367:366] <= 2'b00;

        synced_buffer[381:368] <= sync_buffer1[167:154];
        if (sync_buffer1[167])
          synced_buffer[383:382] <= 2'b11;
        else
          synced_buffer[383:382] <= 2'b00;

        synced_buffer[397:384] <= sync_buffer0[181:168];
        if (sync_buffer0[181])
          synced_buffer[399:398] <= 2'b11;
        else
          synced_buffer[399:398] <= 2'b00;

        synced_buffer[413:400] <= sync_buffer1[181:168];
        if (sync_buffer1[181])
          synced_buffer[415:414] <= 2'b11;
        else
          synced_buffer[415:414] <= 2'b00;

        synced_buffer[429:416] <= sync_buffer0[195:182];
        if (sync_buffer0[195])
          synced_buffer[431:430] <= 2'b11;
        else
          synced_buffer[431:430] <= 2'b00;

        synced_buffer[445:432] <= sync_buffer1[195:182];
        if (sync_buffer1[195])
          synced_buffer[447:446] <= 2'b11;
        else
          synced_buffer[447:446] <= 2'b00;

        synced_buffer[461:448] <= sync_buffer0[209:196];
        if (sync_buffer0[209])
          synced_buffer[463:462] <= 2'b11;
        else
          synced_buffer[463:462] <= 2'b00;

        synced_buffer[477:464] <= sync_buffer1[209:196];
        if (sync_buffer1[209])
          synced_buffer[479:478] <= 2'b11;
        else
          synced_buffer[479:478] <= 2'b00;

        synced_buffer[493:480] <= sync_buffer0[223:210];
        if (sync_buffer0[223])
          synced_buffer[495:494] <= 2'b11;
        else
          synced_buffer[495:494] <= 2'b00;

        synced_buffer[509:496] <= sync_buffer1[223:210];
        if (sync_buffer1[223])
          synced_buffer[511:510] <= 2'b11;
        else
          synced_buffer[511:510] <= 2'b00;
      end

      if (sample_load)
      begin
        sample_load <= 0;

        if (sample_low)
          sample_data[1023:512] <= synced_buffer;
        else
          sample_data[511:0] <= synced_buffer;

        sample_low <= sample_low + 1;

        if (sample_low == 1)
          has_sample_data <= 1;
      end

      if (has_sample_data)
      begin
        has_sample_data <= 0;
        req_stop <= 1;
      end
    end
  end

  always @ ( posedge sample_clk ) 
  begin
    if (adc_running)
    begin
      sample_buffer0[209:0] <= sample_buffer0[223:14];
      sample_buffer0[223:210] <= curr_ch0;

      sample_buffer1[209:0] <= sample_buffer1[223:14];
      sample_buffer1[223:210] <= curr_ch1;

      sample_counter <= sample_counter + 1;

      if (!sample_counter && !first)
      begin
        sync_buffer0 <= sample_buffer0;
        sync_buffer1 <= sample_buffer1;
        notify_sample_data <= 1;
      end
          
      if (curr_ch0)
        curr_ch0 <= curr_ch0 - 1;
      else
        curr_ch0 <= 10000;

      if (curr_ch1 != 9000)
        curr_ch1 <= curr_ch1 + 1;
      else
        curr_ch1 <= 0;

      first <= 0;
    end        

    if (ack_sample_data)
      notify_sample_data <= 0;

    if (req_start && !adc_running)
    begin
      adc_running <= 1;
      sample_counter <= 0;
      first <= 1;
    end

    if (req_stop && adc_running)
      adc_running <= 0;
        
  end

end

endgenerate

endmodule
