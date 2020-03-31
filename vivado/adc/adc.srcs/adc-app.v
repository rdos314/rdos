module adc_app (
  clk,
  reset,

  started,
  probing,
  running,
  req_stop,

  adc_wr,
  adc_address,

  rd_address,
  rd,

  rp_data,
  rp,

  wr_address,
  wr_data,
  wr
);

  input wire             clk;
  input wire             reset;

  input wire             started;
  input wire             probing;
  input wire             running;
  output reg             req_stop;

  input wire             adc_wr;
  output reg [63:0]      adc_address;

  input wire [16:0]      rd_address;
  input wire             rd;

  output reg [31:0]      rp_data;
  output reg             rp;

  input wire [16:0]      wr_address;
  input wire [31:0]      wr_data;
  input wire             wr;

// local bar

  reg                    bar_wr;
  reg                    bar_wr_valid;
  reg  [15:0]            bar_wr_adr;
  reg  [19:0]            bar_wr_data;

  reg                    bar_rd;
  reg                    bar_msb;
  wire [15:0]            bar_rd_adr;
  wire [19:0]            bar_rd_data;

// PCIe domain
  reg  [15:0]            q_rd_adr;
  reg  [15:0]            sample_index;
  reg  [63:0]            next_address;


bram_adc bram_adc_inst (
  .clka(clk),          // input wire clka
  .wea(wr),            // input wire [0 : 0] wea
  .addra(bar_wr_adr),  // input wire [15 : 0] addra
  .dina(bar_wr_data),  // input wire [19 : 0] dina
  .clkb(clk),          // input wire clkb
  .addrb(bar_rd_adr),  // input wire [15 : 0] addrb
  .doutb(bar_rd_data)  // output wire [19 : 0] doutb
);

generate
begin : adc_app

  assign bar_rd_adr = rd ? rd_address[16:1] : sample_index;

  always @ ( posedge clk ) 
  begin
    if (bar_rd)
    begin
      if (bar_msb)
      begin
        rp_data[8:0] <= bar_rd_data[19:11];
        rp_data[31:9] <= 0;
      end
      else
      begin
        rp_data[20:0] <= 0;
        rp_data[31:21] <= bar_rd_data[10:0];
      end
      rp <= 1;
    end
    else
      rp <= 0;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      bar_rd <= 0;
      q_rd_adr <= 0;
    end
    else
    begin
      q_rd_adr <= bar_rd_adr;

      if (wr)
      begin
        bar_wr_adr <= wr_address[16:1];
        if (wr_address[0])
          bar_wr_data[19:11] <= wr_data[8:0];
        else
          bar_wr_data[10:0] = wr_data[31:21];

        bar_rd <= 0;
      end
      else
      begin
        if (rd)
        begin
          bar_msb <= rd_address[0];
          bar_rd <= 1;
        end
        else
          bar_rd <= 0;
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
      if (running)
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
          if (q_rd_adr == sample_index)
          begin
            next_address[20:0] <= 0;
            next_address[40:21] <= bar_rd_data;
            next_address[63:41] <= 0;
          end
        end
      end
      else
      begin
        req_stop <= 0;
        sample_index <= 0;

        if (q_rd_adr == 0)
        begin
          adc_address[20:0] <= 0;
          adc_address[40:21] <= bar_rd_data;
          adc_address[63:41] <= 0;
        end
      end
    end
  end

end
endgenerate

endmodule
