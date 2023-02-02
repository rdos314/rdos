////////////////////////////////////////////////////////////////////////////////
// RDOS operating system
// Copyright (C) 1988-2020, Leif Ekblad
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version. The only exception to this rule
// is for commercial usage in embedded systems. For information on
// usage in commercial embedded systems, contact embedded@rdos.net
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// The author of this program may be contacted at leif@rdos.net
//
// adc_ana.v
// ADC analyser 
//
////////////////////////////////////////////////////////////////////////////////

module adc_ana (
  input wire              clk,
  input wire              reset,

  input wire              conf,
  input wire [29:0]       incr,
  input wire [13:0]       count,
  input wire              stop,

  input wire [13:0]       in_A0,
  input wire [13:0]       in_A1,
  input wire [13:0]       in_A2,
  input wire [13:0]       in_A3,
  input wire [13:0]       in_B0,
  input wire [13:0]       in_B1,
  input wire [13:0]       in_B2,
  input wire [13:0]       in_B3,
  
  input wire              pci_clk,
  input wire              pci_reset,
  input wire              pci_init,
  input wire [47:0]       phys_adr,
  input wire [20:0]       ack_pos,
  input wire              pci_on,
  output reg              pci_stop,

  output reg              report,
  input wire              clear,
  output reg [47:0]       adr,  
  output reg  [127:0]     d_0,
  output reg  [127:0]     d_1,
  output reg  [127:0]     d_2,
  output reg  [127:0]     d_3,

  input wire              msix_mask,
  output reg              msix_issue,
  input wire              msix_clear
);

  reg                     config_div_wnd;
  reg                     config_init;
  reg                     config_start;
  reg                     config_validate;
  reg  [12:0]             config_count;
  reg  [13:0]             config_adr;
  reg  [3:0]              config_last_en;
  reg  [10:0]             config_last;
  reg  [10:0]             config_last_1;
  reg  [10:0]             config_delay_last;
  reg  [10:0]             config_delay_last_1;
  reg                     config_raw_coeff;
  reg                     config_coeff_done;
  reg                     config_has_coeff;
  reg  [16:0]             config_last_phase;
  reg  [16:0]             config_delay_phase;

  reg                     config_pend_coeff;
  reg                     config_pend_wnd;

  reg  [23:0]             config_l_sin;
  reg  [23:0]             config_l_cos;
  reg  [15:0]             config_sin;
  reg  [15:0]             config_cos;
  reg  [11:0]             config_wnd;

  reg  [63:0]             coeff_sin;
  reg  [15:0]             coeff_sin_0;
  reg  [15:0]             coeff_sin_1;
  reg  [15:0]             coeff_sin_2;
  reg  [15:0]             coeff_sin_3;

  reg  [63:0]             coeff_cos;
  reg  [15:0]             coeff_cos_0;
  reg  [15:0]             coeff_cos_1;
  reg  [15:0]             coeff_cos_2;
  reg  [15:0]             coeff_cos_3;

  reg  [47:0]             coeff_wnd;
  reg  [11:0]             coeff_wnd_0;
  reg  [11:0]             coeff_wnd_1;
  reg  [11:0]             coeff_wnd_2;
  reg  [11:0]             coeff_wnd_3;

  reg                     p1;
  reg                     p2;
  reg                     p3;
  reg                     p4;

  reg                     s1;
  reg                     s2;
  reg                     s3;
  reg                     synt_start;
  wire                    synt_done;
  reg                     synt_prev;
  wire [23:0]             synt_comp_sin;
  wire [23:0]             synt_comp_cos;
  wire [47:0]             synt_data;
  reg  [29:0]             synt_phase;
  wire [23:0]             synt_raw_sin;
  wire [23:0]             synt_raw_cos;

  assign synt_raw_cos       = synt_data[23:0];
  assign synt_raw_sin       = synt_data[47:24];

  wire [31:0]             synt_cordic_phase;

  assign synt_cordic_phase[29:0] = synt_phase[29:0];
  assign synt_cordic_phase[30]   = synt_phase[29];
  assign synt_cordic_phase[31]   = synt_phase[29];

  assign synt_comp_cos[23]  = synt_raw_cos[23];
  assign synt_comp_cos[22]  = synt_raw_cos[23];
  assign synt_comp_cos[21]  = synt_raw_cos[23];
  assign synt_comp_cos[20]  = synt_raw_cos[23];
  assign synt_comp_cos[19]  = synt_raw_cos[23];
  assign synt_comp_cos[18]  = synt_raw_cos[23];
  assign synt_comp_cos[17]  = synt_raw_cos[23];
  assign synt_comp_cos[16]  = synt_raw_cos[23];
  assign synt_comp_cos[15]  = synt_raw_cos[23];
  assign synt_comp_cos[14]  = synt_raw_cos[23];
  assign synt_comp_cos[13]  = synt_raw_cos[23];
  assign synt_comp_cos[12]  = synt_raw_cos[23];
  assign synt_comp_cos[11]  = synt_raw_cos[23];
  assign synt_comp_cos[10]  = synt_raw_cos[23];
  assign synt_comp_cos[9]   = synt_raw_cos[23];
  assign synt_comp_cos[8]   = synt_raw_cos[23];
  assign synt_comp_cos[7]   = synt_raw_cos[22];
  assign synt_comp_cos[6]   = synt_raw_cos[21];
  assign synt_comp_cos[5]   = synt_raw_cos[20];
  assign synt_comp_cos[4]   = synt_raw_cos[19];
  assign synt_comp_cos[3]   = synt_raw_cos[18];
  assign synt_comp_cos[2]   = synt_raw_cos[17];
  assign synt_comp_cos[1]   = synt_raw_cos[16];
  assign synt_comp_cos[0]   = synt_raw_cos[15];

  assign synt_comp_sin[23]  = synt_raw_sin[23];
  assign synt_comp_sin[22]  = synt_raw_sin[23];
  assign synt_comp_sin[21]  = synt_raw_sin[23];
  assign synt_comp_sin[20]  = synt_raw_sin[23];
  assign synt_comp_sin[19]  = synt_raw_sin[23];
  assign synt_comp_sin[18]  = synt_raw_sin[23];
  assign synt_comp_sin[17]  = synt_raw_sin[23];
  assign synt_comp_sin[16]  = synt_raw_sin[23];
  assign synt_comp_sin[15]  = synt_raw_sin[23];
  assign synt_comp_sin[14]  = synt_raw_sin[23];
  assign synt_comp_sin[13]  = synt_raw_sin[23];
  assign synt_comp_sin[12]  = synt_raw_sin[23];
  assign synt_comp_sin[11]  = synt_raw_sin[23];
  assign synt_comp_sin[10]  = synt_raw_sin[23];
  assign synt_comp_sin[9]   = synt_raw_sin[23];
  assign synt_comp_sin[8]   = synt_raw_sin[23];
  assign synt_comp_sin[7]   = synt_raw_sin[22];
  assign synt_comp_sin[6]   = synt_raw_sin[21];
  assign synt_comp_sin[5]   = synt_raw_sin[20];
  assign synt_comp_sin[4]   = synt_raw_sin[19];
  assign synt_comp_sin[3]   = synt_raw_sin[18];
  assign synt_comp_sin[2]   = synt_raw_sin[17];
  assign synt_comp_sin[1]   = synt_raw_sin[16];
  assign synt_comp_sin[0]   = synt_raw_sin[15];

  reg  [13:0]             wnd_mask;
  reg  [25:0]             wnd_curr;
  reg  [25:0]             wnd_divend;
  reg  [13:0]             wnd_incr;
  reg  [13:0]             wnd_phase;

  wire [15:0]             wnd_cordic_phase;
  wire                    wnd_done;
  reg                     wnd_prev;
  wire [31:0]             wnd_data;
  wire [15:0]             wnd_raw_coeff;
  wire [15:0]             wnd_comp_coeff;

  assign wnd_cordic_phase[13:0]  = wnd_phase;
  assign wnd_cordic_phase[14]    = wnd_phase[13];
  assign wnd_cordic_phase[15]    = wnd_phase[13];

  assign wnd_raw_coeff        = wnd_data[31:16];

  assign wnd_comp_coeff[15]   = wnd_data[31];
  assign wnd_comp_coeff[14]   = wnd_data[31];
  assign wnd_comp_coeff[13]   = wnd_data[31];
  assign wnd_comp_coeff[12]   = wnd_data[31];
  assign wnd_comp_coeff[11]   = wnd_data[31];
  assign wnd_comp_coeff[10]   = wnd_data[31];
  assign wnd_comp_coeff[9]   = wnd_data[31];
  assign wnd_comp_coeff[8]   = wnd_data[31];
  assign wnd_comp_coeff[7]   = wnd_data[31];
  assign wnd_comp_coeff[6]   = wnd_data[31];
  assign wnd_comp_coeff[5]   = wnd_data[31];
  assign wnd_comp_coeff[4]   = wnd_data[31];
  assign wnd_comp_coeff[3]   = wnd_data[31];
  assign wnd_comp_coeff[2]   = wnd_data[31];
  assign wnd_comp_coeff[1]   = wnd_data[31];
  assign wnd_comp_coeff[0]   = wnd_data[30];

  reg  [15:0]             wnd_raw;
  wire [31:0]             wnd_2;
  reg                     w1;
  reg                     w2;
  reg                     w3;
  reg                     w4;
  reg                     w5;
  

  reg                     sample_en;
  reg                     sample_req;
  reg  [13:0]             sample_in_0;
  reg  [13:0]             sample_in_1;
  reg  [13:0]             sample_in_2;
  reg  [13:0]             sample_in_3;
  reg  [55:0]             sample_in;
  wire [55:0]             sample_out;
  reg                     sample_wr;
  reg  [11:0]             sample_adr;

  reg                     coeff_done;
  reg                     coeff_req;
  reg                     coeff_wr;
  reg  [63:0]             coeff_sin;
  reg  [63:0]             coeff_cos;
  reg  [10:0]             coeff_adr;

  reg                     start;
  reg  [15:0]             phase_incr;
  reg  [9:0]              delay_count;
  reg  [15:0]             delay_phase;

  reg  [1:0]              adc_delay;
  reg                     adc_on;
  reg                     pend_run;
  reg                     adc_run;
  reg                     adc_active;

  reg  [13:0]             out_A0;
  reg  [13:0]             out_A1;
  reg  [13:0]             out_A2;
  reg  [13:0]             out_A3;
  reg  [13:0]             out_B0;
  reg  [13:0]             out_B1;
  reg  [13:0]             out_B2;
  reg  [13:0]             out_B3;

  wire                    b_report;
  wire [15:0]             b_amp_sin_A;
  wire [15:0]             b_amp_cos_A;
  wire [15:0]             b_amp_sin_B;
  wire [15:0]             b_amp_cos_B;
  wire [15:0]             b_amp_A;
  wire [15:0]             b_amp_B;
  wire [15:0]             b_phase_A;
  wire [15:0]             b_phase_B;

  wire                    d_report;
  wire [15:0]             d_amp_sin_A;
  wire [15:0]             d_amp_cos_A;
  wire [15:0]             d_amp_sin_B;
  wire [15:0]             d_amp_cos_B;
  wire [15:0]             d_amp_A;
  wire [15:0]             d_amp_B;
  wire [15:0]             d_phase_A;
  wire [15:0]             d_phase_B;

  reg                     base_start;
  reg  [9:0]              curr_count;
  reg                     delay_start;
  wire                    base_run;

  reg                     base_update;
  reg  [15:0]             base_curr_phase;

  reg                     delay_update;
  reg  [15:0]             delay_curr_phase;
  wire                    delay_run;

  reg                     fifo_wr;
  reg  [127:0]            fifo_in;

// pci domain

  wire [127:0]            fifo_out;
  wire                    fifo_empty;
  reg                     fifo_rd;

  reg                     d_pend;
  reg  [1:0]              d_adr;

  reg                     update_adr;

  reg                     msix_start;
  reg                     msix_sig;

// clock domain crossings

 (* ASYNC_REG="TRUE" *)  reg                  adc_on_1;

ana_synt ana_synt_inst (
  .aclk(clk),                             // input wire aclk
  .s_axis_phase_tvalid(synt_start),       // input wire s_axis_phase_tvalid
  .s_axis_phase_tready(),                 // output wire s_axis_phase_tready
  .s_axis_phase_tdata(synt_cordic_phase), // input wire [31 : 0] s_axis_phase_tdata
  .m_axis_dout_tvalid(synt_done),         // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(synt_data)           // output wire [47 : 0] m_axis_dout_tdata
);

wnd_synt wnd_synt_inst (
  .aclk(clk),                             // input wire aclk
  .s_axis_phase_tvalid(synt_start),       // input wire s_axis_phase_tvalid
  .s_axis_phase_tready(),                 // output wire s_axis_phase_tready
  .s_axis_phase_tdata(wnd_cordic_phase),  // input wire [15 : 0] s_axis_phase_tdata
  .m_axis_dout_tvalid(wnd_done),          // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(wnd_data)            // output wire [31 : 0] m_axis_dout_tdata
);

mult_16_16 m_wnd (
  .CLK(clk),            // input wire CLK
  .A(wnd_raw),          // input wire [15 : 0] A
  .B(wnd_raw),          // input wire [15 : 0] B
  .P(wnd_2)             // output wire [31 : 0] P
);

bram_sample sample (
  .clka(clk),                 // input wire clka
  .ena(sample_en),            // input wire ena
  .wea(sample_wr),            // input wire [0 : 0] wea
  .addra(sample_adr),         // input wire [11 : 0] addra
  .dina(sample_in),           // input wire [55 : 0] dina
  .douta(sample_out)          // output wire [55 : 0] douta
);

fifo_signal signal_inst (
  .rst(pci_reset),          // input wire rst
  .wr_clk(clk),             // input wire wr_clk
  .rd_clk(pci_clk),         // input wire rd_clk
  .din(fifo_in),            // input wire [127 : 0] din
  .wr_en(fifo_wr),          // input wire wr_en
  .rd_en(fifo_rd),          // input wire rd_en
  .dout(fifo_out),          // output wire [127 : 0] dout
  .full(),                  // output wire full
  .empty(fifo_empty)        // output wire empty
);

ana_freq base (
  .clk(clk),              // input wire clk
  .reset(reset),          // input wire clk
  .init(config_init),     // input wire init
  .count(config_count),   // input wire [12:0] count
  .last(config_last),     // input wire [10:0] last
  .start(base_start),     // input wire start
  .stop(stop),            // input wire stop
  .run(base_run),         // output wire run
  .validate(config_validate),  // input wire validate
  .wr(coeff_wr),          // input wire coeff_wr
  .wr_adr(coeff_adr),     // input wire [10:0] coeff_adr
  .wr_sin(coeff_sin),     // input wire [63:0] coeff_sin
  .wr_cos(coeff_cos),     // input wire [63:0] coeff_cos
  .wr_wnd(coeff_wnd),     // input wire [47:0] coeff_cos
  .in_A0(out_A0),         // input wire [13:0] in_A0
  .in_A1(out_A1),         // input wire [13:0] in_A1
  .in_A2(out_A2),         // input wire [13:0] in_A2
  .in_A3(out_A3),         // input wire [13:0] in_A3
  .in_B0(out_B0),         // input wire [13:0] in_B0
  .in_B1(out_B1),         // input wire [13:0] in_B1
  .in_B2(out_B2),         // input wire [13:0] in_B2
  .in_B3(out_B3),         // input wire [13:0] in_B3
  .report(b_report),      // output wire report
  .amp_sin_A(b_amp_sin_A),// output wire [15:0] amp_sin_A
  .amp_cos_A(b_amp_cos_A),// output wire [15:0] amp_cos_A
  .amp_sin_B(b_amp_sin_B),// output wire [15:0] amp_sin_B
  .amp_cos_B(b_amp_cos_B),// output wire [15:0] amp_cos_B
  .amp_A(b_amp_A),        // output wire [15:0] amp_A
  .amp_B(b_amp_B),        // output wire [15:0] amp_B
  .phase_A(b_phase_A),    // output wire [15:0] phase_A
  .phase_B(b_phase_B)     // output wire [15:0] phase_B
);

ana_freq delayed (
  .clk(clk),              // input wire clk
  .reset(reset),          // input wire clk
  .init(config_init),     // input wire init
  .count(config_count),   // input wire [12:0] count
  .last(config_last),     // input wire [10:0] last
  .start(delay_start),    // input wire start
  .stop(stop),            // input wire stop
  .run(delay_run),        // output wire run
  .validate(config_validate),  // input wire validate
  .wr(coeff_wr),          // input wire coeff_wr
  .wr_adr(coeff_adr),     // input wire [10:0] coeff_adr
  .wr_sin(coeff_sin),     // input wire [63:0] coeff_sin
  .wr_cos(coeff_cos),     // input wire [63:0] coeff_cos
  .wr_wnd(coeff_wnd),     // input wire [47:0] coeff_cos
  .in_A0(out_A0),         // input wire [13:0] in_A0
  .in_A1(out_A1),         // input wire [13:0] in_A1
  .in_A2(out_A2),         // input wire [13:0] in_A2
  .in_A3(out_A3),         // input wire [13:0] in_A3
  .in_B0(out_B0),         // input wire [13:0] in_B0
  .in_B1(out_B1),         // input wire [13:0] in_B1
  .in_B2(out_B2),         // input wire [13:0] in_B2
  .in_B3(out_B3),         // input wire [13:0] in_B3
  .report(d_report),      // output wire report
  .amp_sin_A(d_amp_sin_A),// output wire [15:0] amp_sin_A
  .amp_cos_A(d_amp_cos_A),// output wire [15:0] amp_cos_A
  .amp_sin_B(d_amp_sin_B),// output wire [15:0] amp_sin_B
  .amp_cos_B(d_amp_cos_B),// output wire [15:0] amp_cos_B
  .amp_A(d_amp_A),        // output wire [15:0] amp_A
  .amp_B(d_amp_B),        // output wire [15:0] amp_B
  .phase_A(d_phase_A),    // output wire [15:0] phase_A
  .phase_B(d_phase_B)     // output wire [15:0] phase_B
);

/*
ila_1 ila_1_inst (
  .clk(clk),                 // input wire clk
  .probe0(config_div_wnd),   // input wire [0:0]  probe3
  .probe1(incr),             // input wire [29:0]  probe3
  .probe2(count),            // input wire [13:0]  probe3
  .probe3(wnd_incr),         // input wire [13:0]  probe3
  .probe4(synt_start),       // input wire [0:0]  probe3
  .probe5(synt_phase),       // input wire [29:0]  probe3
  .probe6(synt_cordic_phase), // input wire [31:0]  probe3
  .probe7(synt_done),         // input wire [0:0]  probe3
  .probe8(synt_raw_sin),      // input wire [23:0]  probe3
  .probe9(synt_raw_cos),      // input wire [23:0]  probe3
  .probe10(wnd_phase),        // input wire [13:0]  probe3
  .probe11(wnd_cordic_phase), // input wire [15:0]  probe3
  .probe12(wnd_done),         // input wire [0:0]  probe3
  .probe13(wnd_raw_coeff),    // input wire [11:0]  probe3
  .probe14(coeff_wr),         // input wire [0:0]  probe3
  .probe15(coeff_adr),        // input wire [10:0]  probe3
  .probe16(config_wnd),       // input wire [11:0]  probe3
  .probe17(w1),               // input wire [0:0]  probe3
  .probe18(w2),               // input wire [0:0]  probe3
  .probe19(w3),               // input wire [0:0]  probe3
  .probe20(w4),               // input wire [0:0]  probe3
  .probe21(w5),               // input wire [0:0]  probe3
  .probe22(wnd_raw),          // input wire [15:0]  probe3
  .probe23(wnd_2),            // input wire [31:0]  probe3
  .probe24(coeff_wnd),        // input wire [47:0]  probe3
  .probe25(coeff_wnd_0),      // input wire [11:0]  probe3
  .probe26(coeff_wnd_1),      // input wire [11:0]  probe3
  .probe27(coeff_wnd_2),      // input wire [11:0]  probe3
  .probe28(coeff_wnd_3)       // input wire [11:0]  probe3
);
*/

generate
begin : adc_ana_gen


  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      config_div_wnd <= 0;
      config_init <= 0;
      sample_en <= 0;
      pend_run <= 0;
    end
    else
    begin
      if (conf)
      begin
        config_count <= count[12:0];

        config_div_wnd <= 1;
        config_init <= 0;
        sample_en <= 0;
        pend_run <= 0;

        wnd_mask[13] <= 0;
        wnd_mask[12] <= 1;
        wnd_mask[11:0] <= 0;
        wnd_divend[25:15] <= 0;
        wnd_divend[14] <= 1;
        wnd_divend[13:0] <= 0;

        wnd_curr[25:13] <= count[12:0] - 1;
        wnd_curr[12:0] <= 0;

        wnd_incr  <= 0;
      end
      else
      begin
        if (config_div_wnd)
        begin
          pend_run <= 0;
          if (wnd_mask)
          begin
            if (wnd_divend >= wnd_curr)
            begin
              wnd_divend <= wnd_divend - wnd_curr;
              wnd_incr <= wnd_incr | wnd_mask;
            end

            wnd_curr <= wnd_curr >> 1;
            wnd_mask <= wnd_mask >> 1;

            config_init <= 0;
            sample_en <= 0;
          end
          else
          begin
            config_div_wnd <= 0;
            config_init <= 1;
            sample_en <= 1;
          end
        end
        else
        begin
          config_init <= 0;
          if (config_coeff_done)
          begin
            sample_en <= 0;
            pend_run <= 1;
          end
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (config_init)
    begin
      case (count[1:0])
        2'b00 : config_last_en <= 4'b1111;
        2'b01 : config_last_en <= 4'b0001;
        2'b10 : config_last_en <= 4'b0011;
        2'b11 : config_last_en <= 4'b0111;
      endcase

      if (count[1])
        config_last <= count[12:2];
      else
        config_last <= count[12:2] - 1;

      if (count[1])
        config_last_1 <= count[12:2] + 1;
      else
        config_last_1 <= count[12:2];

      config_delay_last[10] <= 0;
      if (count[2])
        config_delay_last[9:0] <= count[12:3];
      else
        config_delay_last[9:0] <= count[12:3] - 1;          

      config_delay_last_1[10] <= 0;
      if (count[2])
        config_delay_last_1[9:0] <= count[12:3] + 1;
      else
        config_delay_last_1[9:0] <= count[12:3];          

    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      config_raw_coeff <= 0;
    else
    begin
      if (config_init)
      begin
        config_raw_coeff <= 0;
        synt_prev <= synt_done;
      end
      else
      begin
        if (sample_en)
        begin
          if (synt_prev != synt_done)
          begin
            synt_prev <= synt_done;

            if (synt_done)
            begin
              config_l_sin <= synt_raw_sin - synt_comp_sin;
              config_l_cos <= synt_raw_cos - synt_comp_cos;
              config_raw_coeff <= 1;
            end
            else
              config_raw_coeff <= 0;
          end
          else
            config_raw_coeff <= 0;
        end
        else
          config_raw_coeff <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      w1 <= 0;
    else
    begin
      if (config_init)
      begin
        w1 <= 0;
        wnd_prev <= wnd_done;
      end
      else
      begin
        if (sample_en)
        begin
          if (wnd_prev != wnd_done)
          begin
            wnd_prev <= wnd_done;

            if (wnd_done)
            begin
              wnd_raw <= wnd_raw_coeff - wnd_comp_coeff;
              w1 <= 1;
            end
            else
              w1 <= 0;
          end
          else
            w1 <= 0;
        end
        else
          w1 <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      w2 <= 0;
      w3 <= 0;
      w4 <= 0;
      w5 <= 0;
    end
    else
    begin
      w2 <= w1;
      w3 <= w2;
      w4 <= w3;
      w5 <= w4;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
       config_pend_wnd <= 0;
    else
    begin
      if (w5)
      begin
        config_wnd <= wnd_2[27:16];
        config_pend_wnd <= 1;
      end
      else
        if (config_pend_wnd & config_pend_coeff)
          config_pend_wnd <= 0;
    end 
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      config_pend_coeff <= 0;
    else
    begin
      if (config_raw_coeff)
      begin
        if (config_l_sin[6])
          config_sin <= config_l_sin[22:7] + 1;
        else
          config_sin <= config_l_sin[22:7];

        if (config_l_cos[6])
          config_cos <= config_l_cos[22:7] + 1;
        else
          config_cos <= config_l_cos[22:7];

        config_pend_coeff <= 1;
      end
      else
        if (config_pend_wnd & config_pend_coeff)
          config_pend_coeff <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      config_has_coeff <= 0;
    else
    begin
      if (config_pend_wnd & config_pend_coeff)
        config_has_coeff <= 1;
      else
        config_has_coeff <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      sample_req <= 0;
    else
    begin
      if (config_has_coeff)
      begin
        case (config_adr[1:0])
          2'b00 :
            begin
              sample_in_0 <= config_sin[15:2];
              coeff_sin_0 <= config_sin;
              coeff_cos_0 <= config_cos;
              coeff_wnd_0 <= config_wnd;
              sample_req <= 0;
            end
          2'b01 : 
            begin
              sample_in_1 <= config_sin[15:2];
              coeff_sin_1 <= config_sin;
              coeff_cos_1 <= config_cos;
              coeff_wnd_1 <= config_wnd;
              sample_req <= 0;
            end
          2'b10 : 
            begin
              sample_in_2 <= config_sin[15:2];
              coeff_sin_2 <= config_sin;
              coeff_cos_2 <= config_cos;
              coeff_wnd_2 <= config_wnd;
              sample_req <= 0;
            end
          2'b11 :
            begin
              sample_in_3 <= config_sin[15:2];
              coeff_sin_3 <= config_sin;
              coeff_cos_3 <= config_cos;
              coeff_wnd_3 <= config_wnd;
              sample_req <= 1;
            end
        endcase
      end
      else
        sample_req <= 0;
    end
  end              

  always @ ( posedge clk ) 
  begin
    if (sample_req)
    begin
      sample_in[13:0] <= sample_in_0;      
      sample_in[27:14] <= sample_in_1;      
      sample_in[41:28] <= sample_in_2;      
      sample_in[55:42] <= sample_in_3;      
      sample_wr <= 1;
    end
    else
      sample_wr <= 0;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      sample_adr <= 0;
      config_start <= 0;
      config_validate <= 0;
      config_coeff_done <= 0;
    end
    else
    begin
      if (config_init)
      begin
        sample_adr <= 0;
        config_start <= 0;
        config_validate <= 0;
        config_coeff_done <= 0;
      end
      else
      begin
        if (config_start)
        begin
          sample_adr <= 0;
          config_start <= 0;
          config_coeff_done <= 0;
        end
        else
        begin
          if (config_validate)
          begin
            if (sample_adr == 12'hFFF)
            begin
              config_validate <= 0;
              config_coeff_done <= 1;
            end
            else
            begin
              config_coeff_done <= 0;
              sample_adr <= sample_adr + 1;
            end
          end
          else
          begin
            if (sample_req)
            begin
              if (sample_adr == 12'hFFF)
              begin
                config_coeff_done <= 0;
                config_start <= 1;
                config_validate <= 1;
              end
              else
              begin
                config_coeff_done <= 0;
                config_start <= 0;
              end
            end
            else
            begin
              if (sample_wr)
                sample_adr <= sample_adr + 1;
  
              config_coeff_done <= 0;
              config_start <= 0;
            end
          end
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (config_has_coeff)
    begin
      if ((config_adr[1:0] == 0) && (config_adr[13] == 0))
      begin
        if (config_adr[12:2] == config_last_1)
          config_last_phase <= synt_phase[29:13];
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (config_has_coeff)
    begin
      if ((config_adr[1:0] == 0) && (config_adr[13] == 0))
      begin
        if (config_adr[12:2] == config_delay_last_1)
          config_delay_phase <= synt_phase[29:13];
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      s1 <= 0;
      config_adr <= 0;
      synt_phase <= 0;
      wnd_phase <= 0;
    end
    else
    begin
      if (config_has_coeff)
      begin
        config_adr <= config_adr + 1;
        synt_phase <= synt_phase + incr;
        wnd_phase <= wnd_phase + wnd_incr;

        if (config_adr == 14'h3FFF)
          s1 <= 0;
        else
          s1 <= 1;
      end
      else
      begin
        if (config_init)
        begin
          s1 <= 1;
          config_adr <= 0;
          synt_phase <= 0;
          wnd_phase <= 0;
        end
        else
          s1 <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      s2 <= 0;
      s3 <= 0;
      synt_start <= 0;
    end
    else
    begin
      s2 <= s1;
      s3 <= s2;
      synt_start <= s3;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      coeff_req <= 0;
      coeff_done <= 0;
    end
    else
    begin
      if (sample_req)    
      begin        
        if (sample_adr[10:0] == config_last)
        begin
          coeff_done <= 1;
          coeff_req <= 1;

          if (config_last_en[0])
          begin
            coeff_sin[15:0] <= coeff_sin_0;
            coeff_cos[15:0] <= coeff_cos_0;
            coeff_wnd[11:0] <= coeff_wnd_0;
          end
          else            
          begin
            coeff_sin[15:0] <= 0;
            coeff_cos[15:0] <= 0;
            coeff_wnd[11:0] <= 0;
          end

          if (config_last_en[1])
          begin
            coeff_sin[31:16] <= coeff_sin_1;
            coeff_cos[31:16] <= coeff_cos_1;
            coeff_wnd[23:12] <= coeff_wnd_1;
          end
          else            
          begin
            coeff_sin[31:16] <= 0;
            coeff_cos[31:16] <= 0;
            coeff_wnd[23:12] <= 0;
          end

          if (config_last_en[2])
          begin
            coeff_sin[47:32] <= coeff_sin_2;
            coeff_cos[47:32] <= coeff_cos_2;
            coeff_wnd[35:24] <= coeff_wnd_2;
          end
          else            
          begin
            coeff_sin[47:32] <= 0;
            coeff_cos[47:32] <= 0;
            coeff_wnd[35:24] <= 0;
          end

          if (config_last_en[3])
          begin
            coeff_sin[63:48] <= coeff_sin_3;
            coeff_cos[63:48] <= coeff_cos_3;
            coeff_wnd[47:36] <= coeff_wnd_3;
          end
          else            
          begin
            coeff_sin[63:48] <= 0;
            coeff_cos[63:48] <= 0;
            coeff_wnd[47:36] <= 0;
          end
        end
        else     
        begin
          if (coeff_done)
            coeff_req <= 0;
          else
          begin
            coeff_req <= 1;
            coeff_sin[15:0] <= coeff_sin_0;
            coeff_cos[15:0] <= coeff_cos_0;
            coeff_wnd[11:0] <= coeff_wnd_0;

            coeff_sin[31:16] <= coeff_sin_1;
            coeff_cos[31:16] <= coeff_cos_1;
            coeff_wnd[23:12] <= coeff_wnd_1;

            coeff_sin[47:32] <= coeff_sin_2;
            coeff_cos[47:32] <= coeff_cos_2;
            coeff_wnd[35:24] <= coeff_wnd_2;

            coeff_sin[63:48] <= coeff_sin_3;
            coeff_cos[63:48] <= coeff_cos_3;
            coeff_wnd[47:36] <= coeff_wnd_3;
          end
        end
      end
      else
      begin
        coeff_req <= 0;
        if (config_init)
          coeff_done <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      p1 <= 0;
      p2 <= 0;
      p3 <= 0;
      p4 <= 0;
    end
    else
    begin
      p1 <= coeff_req;
      p2 <= p1;
      p3 <= p2;
      p4 <= p3;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset | config_init)
      coeff_adr <= 0;
    else
      if (p4)
        coeff_adr <= sample_adr[10:0];
  end

  always @ ( posedge clk ) 
  begin
    if (config_start)
    begin
      delay_count <= config_delay_last[9:0] + 1;

      if (config_last_phase[0])
        phase_incr <= config_last_phase[16:1] + 1;
      else
        phase_incr <= config_last_phase[16:1];

      if (config_delay_phase[0])
        delay_phase <= config_delay_phase[16:1] + 1;
      else
        delay_phase <= config_delay_phase[16:1];

      start <= 1;
    end
    else
      start <= 0;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      coeff_wr <= 0;
    else
    begin
      if (p1)
        coeff_wr <= 1;
      else
        coeff_wr <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (config_validate)
    begin
      out_A0 <= sample_out[13:0];      
      out_A1 <= sample_out[27:14];      
      out_A2 <= sample_out[41:28];      
      out_A3 <= sample_out[55:42];      
      out_B0 <= ~sample_out[13:0];      
      out_B1 <= ~sample_out[27:14];      
      out_B2 <= ~sample_out[41:28];      
      out_B3 <= ~sample_out[55:42];      
    end
    else
    begin
      out_A0 <= in_A0;
      out_A1 <= in_A1;
      out_A2 <= in_A2;
      out_A3 <= in_A3;
      out_B0 <= in_B0;
      out_B1 <= in_B1;
      out_B2 <= in_B2;
      out_B3 <= in_B3;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      base_curr_phase <= 0;
    else
    begin
      if (base_update)
        base_curr_phase <= base_curr_phase + phase_incr;
      else
      begin
        if (start)
          base_curr_phase <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      delay_curr_phase <= 0;      
    else
    begin
      if (delay_update)
        delay_curr_phase <= delay_curr_phase + phase_incr;
      else
      begin
        if (start)
          delay_curr_phase <= delay_phase;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    adc_on_1 <= pci_on;
    adc_on <= adc_on_1;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      adc_run <= 0;
    else
    begin
      if (conf)
        adc_run <= 0;
      else
      begin
        if (adc_on)
        begin        
          if (pend_run)
            adc_run <= 1;
        end
        else
          adc_run <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      msix_start <= 0;
    else
    begin
      if (msix_clear)
        msix_start <= 0;
      else
      begin    
        if (adc_on & pend_run)
          if (!adc_run)
            msix_start <= 1;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      fifo_wr <= 0;
      base_update <= 0;
      delay_update <= 0;
      adc_active <= 0;
    end
    else
    begin
      if (config_init)
      begin
        adc_active <= 0;
        adc_delay <= 0;
      end
      else
      begin
        if (b_report)
        begin
          base_update <= 1;
          delay_update <= 0;

          if (adc_active)
          begin
            fifo_wr <= 1;
            fifo_in[15:0] <= b_amp_A;        
            fifo_in[31:16] <= b_amp_B;        
            fifo_in[47:32] <= b_phase_A - base_curr_phase;
            fifo_in[63:48] <= b_phase_B - base_curr_phase;
            fifo_in[79:64] <= b_amp_sin_A;        
            fifo_in[95:80] <= b_amp_cos_A;        
            fifo_in[111:96] <= b_amp_sin_B;        
            fifo_in[127:112] <= b_amp_cos_B;        
          end
          else
          begin
            if (adc_run)
            begin
              if (adc_delay == 3)
                adc_active <= 1;
              else
              begin
                adc_delay <= adc_delay + 1;
                adc_active <= 0;
              end
            end
            else
              adc_active <= 0;          
          end
        end
        else
        begin
          if (d_report)
          begin
            base_update <= 0;
            delay_update <= 1;
 
            if (adc_active)
            begin
              fifo_wr <= 1;
              fifo_in[15:0] <= d_amp_A;        
              fifo_in[31:16] <= d_amp_B;        
              fifo_in[47:32] <= d_phase_A - delay_curr_phase;
              fifo_in[63:48] <= d_phase_B - delay_curr_phase;
              fifo_in[79:64] <= d_amp_sin_A;        
              fifo_in[95:80] <= d_amp_cos_A;        
              fifo_in[111:96] <= d_amp_sin_B;        
              fifo_in[127:112] <= d_amp_cos_B;        
            end
            else
            begin
              if (adc_run)
              begin
                if (adc_delay == 3)
                  adc_active <= 1;
                else
                begin
                  adc_delay <= adc_delay + 1;
                  adc_active <= 0;
                end
              end
              else
                adc_active <= 0;          
            end
          end
          else
          begin
            fifo_wr <= 0;
            base_update <= 0;
            delay_update <= 0;

            if (!adc_run)
            begin
              adc_active <= 0;
              adc_delay <= 0;
            end
          end
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      delay_start <= 0;
      curr_count <= 0;
    end
    else
    begin
      if (start)
      begin
        curr_count <= delay_count;
        delay_start <= 0;
      end
      else
      begin
        if (curr_count)
        begin
          curr_count <= curr_count - 1;
          if (curr_count == 1)
            delay_start <= 1;
          else
            delay_start <= 0;
        end
        else
          delay_start <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (start)
      base_start <= 1;
    else
      base_start <= 0;
  end

  always @ ( posedge pci_clk ) 
  begin
    if (fifo_empty)
      fifo_rd <= 0;
    else
    begin
      if (report)
        fifo_rd <= 0;
      else
      begin
        if (fifo_rd)
          fifo_rd <= 0;
        else
          fifo_rd <= 1;
      end
    end
  end

  always @ ( posedge pci_clk ) 
  begin
    if (fifo_rd)
      d_pend <= 1;
    else
      d_pend <= 0;
  end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
    begin
      adr <= 0;
      d_adr <= 0;
      report <= 0;
      update_adr <= 0;
      msix_sig <= 0;
    end
    else
    begin
      if (pci_init)
      begin
        adr <= phys_adr;
        d_adr <= 0;
        report <= 0;
        update_adr <= 0;
        msix_sig <= 0;
      end
      else
      begin
        if (d_pend)
        begin
          update_adr <= 0;

          if (d_adr == 2'b11)
            report <= 1;
          else
            report <= 0;
          
          d_adr <= d_adr + 1;
          case (d_adr)
            0: d_0 <= fifo_out;
            1: d_1 <= fifo_out;
            2: d_2 <= fifo_out;
            3: d_3 <= fifo_out;
          endcase
        end
        else
        begin
          if (clear)
          begin
            report <= 0;
            adr[20:6] <= adr[20:6] + 1;
            update_adr <= 1;
              
            if (adr[9:0] == 0)
              msix_sig <= 1;
          end          
          else
          begin
            update_adr <= 0;
            msix_sig <= 0;
          end
        end
      end
    end
  end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
      pci_stop <= 0;
    else
    begin
      if (pci_init)
        pci_stop <= 0;
      else
      begin
        if (update_adr)
        begin
          if (adr[20:5] == ack_pos[20:5])
              pci_stop <= 1;
          else
            pci_stop <= 0;
        end
        else
          pci_stop <= 0;
      end
    end
  end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
    begin
      msix_issue <= 0;
    end
    else
    begin
      if (msix_clear)
        msix_issue <= 0;
      else
      begin
        if (pci_stop | msix_start | msix_sig)
          if (!msix_mask)
            msix_issue <= 1;
      end
    end
  end

end

endgenerate

endmodule
