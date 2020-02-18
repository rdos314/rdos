module adc_app (
  clk,
  reset,
  sample_clk,
  running,

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
  output reg             running;

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
  reg  [4:0]             sample_counter;
  reg  [1023:0]          sample_data;
  reg                    started;
  reg  [13:0]            curr_ch0;
  reg  [13:0]            curr_ch1;



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
   .clk ( clk ),                  // I
   .probe0(address),             // input wire [16:0]  probe1 
   .probe1(rd),                  // input wire [0:0]  probe1 
   .probe2(rp),                  // input wire [0:0]  probe1 
   .probe3(rp_address),          // input wire [4:0]  probe1 
   .probe4(rp_data),             // input wire [31:0]  probe1 
   .probe5(wr),                  // input wire [0:0]  probe1 
   .probe6(wr_be),               // input wire [3:0]  probe1 
   .probe7(wr_data),             // input wire [31:0]  probe1 
   .probe8(ack),                 // input wire [0:0]  probe1 
   .probe9(adc_wr),              // input wire [0:0]  probe1 
   .probe10(adc_wr_adr),         // input wire [15:0]  probe1 
   .probe11(adc_wr_data),        // input wire [19:0]  probe1 
   .probe12(adc_rd_adr),         // input wire [15:0]  probe1 
   .probe13(adc_rd_data),        // input wire [19:0]  probe1 
   .probe14(curr_data)           // input wire [63:0]  probe1 
);


ila_4 ila4_inst (
   .clk ( sample_clk ),          // I
   .probe0(active),              // input wire [0:0]  probe1 
   .probe1(sample_counter),      // input wire [4:0]  probe1 
   .probe2(sample_data[63:0]),   // input wire [63:0]  probe1 
   .probe3(curr_ch0),            // input wire [13:0]  probe1 
   .probe4(curr_ch1)             // input wire [13:0]  probe1 
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
          running <= 1;
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

  always @ ( posedge sample_clk ) 
  begin
    if (reset)
    begin
      sample_counter <= 0;
      curr_ch0 <= 10000;
      curr_ch1 <= 0;
      running <= 0;
    end
    else
    begin
      if (running)
      begin
        sample_data[(32 * sample_counter) +: 14] = curr_ch0; 

        if (curr_ch0[13]) 
          sample_data[(32 * sample_counter + 14) +: 2] = 2'b11;
        else  
          sample_data[(32 * sample_counter + 14) +: 2] = 2'b00;  

        sample_data[(32 * sample_counter + 16) +: 14] = curr_ch1;  

        if (curr_ch1[13]) 
          sample_data[(32 * sample_counter + 30) +: 2] = 2'b11;
        else  
          sample_data[(32 * sample_counter + 30) +: 2] = 2'b00;  

        sample_counter <= sample_counter + 1;

        if (sample_counter == 5'b11111)
          running <= 0;
        else
        begin
          if (curr_ch0)
            curr_ch0 <= curr_ch0 - 1;
          else
            curr_ch0 <= 10000;

          if (curr_ch1 != 9000)
            curr_ch1 <= curr_ch1 + 1;
          else
            curr_ch1 <= 0;
        end        
      end
    end
  end

end

endgenerate

endmodule
