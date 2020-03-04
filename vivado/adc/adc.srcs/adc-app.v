module adc_app (
  clk,
  reset,
  sample_clk,

  adc_start,
  adc_stop,
  adc_running,
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
  input wire             sample_clk;

  input wire             adc_start;
  input wire             adc_stop;
  output reg             adc_running;
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

// sample domain
  reg                    adc_on;
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
  reg  [15:0]            sample_index;
  reg  [63:0]            next_address;
  reg                    pend_start;
  reg  [511:0]           synced_buffer;
  reg                    sample_load;
  reg                    sample_low;


bram_adc bram_adc_inst (
  .clka(clk),          // input wire clka
  .wea(ack),           // input wire [0 : 0] wea
  .addra(adc_wr_adr),  // input wire [15 : 0] addra
  .dina(adc_wr_data),  // input wire [19 : 0] dina
  .clkb(clk),          // input wire clkb
  .addrb(next_rd_adr), // input wire [15 : 0] addrb
  .doutb(adc_rd_data)  // output wire [19 : 0] doutb
);

generate
begin : adc_app

  always @ ( posedge clk ) 
  begin
    adc_running <= 0;
    adc_send <= 0;
    rp <= 0;
    ack <= 0;
  end
end
endgenerate

endmodule
