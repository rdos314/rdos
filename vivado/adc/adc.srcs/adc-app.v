module adc_app (
  clk,
  reset,

  running,
  probing,
  req_stop,

  adc_wr,
  adc_address,

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

  input wire             running;
  input wire             probing;
  output reg             req_stop;

  input wire             adc_wr;
  output reg [63:0]      adc_address;

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
      sample_index <= 0;
      adc_address[63:0] <= 0;
      next_address[63:0] <= 0;
      req_stop <= 0;
    end
    else
    begin
      if (running && !probing)
      begin
        if (adc_wr)
        begin
          if (adc_address[20:7] == 14'b11111111111111)
          begin
            if (next_address[40:21] == 0)
              req_stop <= 1;
            else
            begin
              adc_address <= next_address;
              sample_index <= sample_index + 1;
              next_address <= 0;
            end
          end
          else
            adc_address[20:7] <= adc_address[20:7] + 1;
        end        
        else
        begin
          if (adc_rd_adr == sample_index)
          begin
            next_address[20:0] <= 0;
            next_address[40:21] <= adc_rd_data;
            next_address[63:41] <= 0;
          end
        end
      end
      else
      begin
        req_stop <= 0;

        if (adc_rd_adr == sample_index)
        begin
          adc_address[20:0] <= 0;
          adc_address[40:21] <= adc_rd_data;
          adc_address[63:41] <= 0;
        end
      end
    end
  end

end
endgenerate

endmodule
