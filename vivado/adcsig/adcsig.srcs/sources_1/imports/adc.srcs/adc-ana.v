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

  output reg              run,
  output reg              report,
  output reg [15:0]       amp_A,
  output reg [15:0]       amp_B,
  output reg [15:0]       phase_A,
  output reg [15:0]       phase_B
);

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

  reg  [23:0]             config_l_sin;
  reg  [23:0]             config_l_cos;
  reg  [15:0]             config_sin;
  reg  [15:0]             config_cos;

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

  reg                     p1;
  reg                     p2;
  reg                     p3;
  reg                     p4;

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

  reg  [13:0]             out_A0;
  reg  [13:0]             out_A1;
  reg  [13:0]             out_A2;
  reg  [13:0]             out_A3;
  reg  [13:0]             out_B0;
  reg  [13:0]             out_B1;
  reg  [13:0]             out_B2;
  reg  [13:0]             out_B3;

  wire                    b_report;
  wire [15:0]             b_amp_A;
  wire [15:0]             b_amp_B;
  wire [15:0]             b_phase_A;
  wire [15:0]             b_phase_B;

  wire                    d_report;
  wire [15:0]             d_amp_A;
  wire [15:0]             d_amp_B;
  wire [15:0]             d_phase_A;
  wire [15:0]             d_phase_B;

  reg                     base_start;
  reg  [9:0]              curr_count;
  reg                     delay_start;

  reg                     base_update;
  reg  [15:0]             base_curr_phase;

  reg                     delay_update;
  reg  [15:0]             delay_curr_phase;


ana_synt synt (
  .aclk(clk),                             // input wire aclk
  .s_axis_phase_tvalid(synt_start),       // input wire s_axis_phase_tvalid
  .s_axis_phase_tready(),                 // output wire s_axis_phase_tready
  .s_axis_phase_tdata(synt_cordic_phase), // input wire [31 : 0] s_axis_phase_tdata
  .m_axis_dout_tvalid(synt_done),         // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(synt_data)           // output wire [47 : 0] m_axis_dout_tdata
);

bram_sample sample (
  .clka(clk),                 // input wire clka
  .ena(sample_en),            // input wire ena
  .wea(sample_wr),            // input wire [0 : 0] wea
  .addra(sample_adr),         // input wire [11 : 0] addra
  .dina(sample_in),           // input wire [55 : 0] dina
  .douta(sample_out)          // output wire [55 : 0] douta
);

ana_freq base (
  .clk(clk),              // input wire clk
  .reset(reset),          // input wire clk
  .init(config_init),     // input wire init
  .count(config_count),   // input wire [12:0] count
  .last(config_last),     // input wire [10:0] last
  .start(base_start),     // input wire start
  .stop(0),               // input wire stop
  .wr(coeff_wr),          // input wire coeff_wr
  .wr_adr(coeff_adr),     // input wire [10:0] coeff_adr
  .wr_sin(coeff_sin),     // input wire [63:0] coeff_sin
  .wr_cos(coeff_cos),     // input wire [63:0] coeff_cos
  .in_A0(out_A0),         // input wire [13:0] in_A0
  .in_A1(out_A1),         // input wire [13:0] in_A1
  .in_A2(out_A2),         // input wire [13:0] in_A2
  .in_A3(out_A3),         // input wire [13:0] in_A3
  .in_B0(out_B0),         // input wire [13:0] in_B0
  .in_B1(out_B1),         // input wire [13:0] in_B1
  .in_B2(out_B2),         // input wire [13:0] in_B2
  .in_B3(out_B3),         // input wire [13:0] in_B3
  .report(b_report),      // output wire report
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
  .stop(0),               // input wire stop
  .wr(coeff_wr),          // input wire coeff_wr
  .wr_adr(coeff_adr),     // input wire [10:0] coeff_adr
  .wr_sin(coeff_sin),     // input wire [63:0] coeff_sin
  .wr_cos(coeff_cos),     // input wire [63:0] coeff_cos
  .in_A0(out_A0),         // input wire [13:0] in_A0
  .in_A1(out_A1),         // input wire [13:0] in_A1
  .in_A2(out_A2),         // input wire [13:0] in_A2
  .in_A3(out_A3),         // input wire [13:0] in_A3
  .in_B0(out_B0),         // input wire [13:0] in_B0
  .in_B1(out_B1),         // input wire [13:0] in_B1
  .in_B2(out_B2),         // input wire [13:0] in_B2
  .in_B3(out_B3),         // input wire [13:0] in_B3
  .report(d_report),      // output wire report
  .amp_A(d_amp_A),        // output wire [15:0] amp_A
  .amp_B(d_amp_B),        // output wire [15:0] amp_B
  .phase_A(d_phase_A),    // output wire [15:0] phase_A
  .phase_B(d_phase_B)     // output wire [15:0] phase_B
);

ila_0 ila_0_inst (
  .clk(clk),                 // input wire clk
  .probe0(conf),             // input wire [0:0]  probe3
  .probe1(incr),             // input wire [29:0]  probe3
  .probe2(count),            // input wire [13:0]  probe3
  .probe3(config_init),      // input wire [0:0]  probe3
  .probe4(config_start),     // input wire [0:0]  probe3
  .probe5(config_validate),  // input wire [0:0]  probe3
  .probe6(config_count),     // input wire [12:0]  probe3
  .probe7(config_adr),       // input wire [13:0]  probe3
  .probe8(config_last_en),   // input wire [3:0]  probe3
  .probe9(config_last),      // input wire [10:0]  probe3
  .probe10(config_delay_last), // input wire [10:0]  probe3
  .probe11(config_raw_coeff), // input wire [0:0]  probe3
  .probe12(config_coeff_done), // input wire [0:0]  probe3
  .probe13(config_has_coeff), // input wire [0:0]  probe3
  .probe14(coeff_wr),        // input wire [0:0]  probe3
  .probe15(coeff_adr),        // input wire [10:0]  probe3
  .probe16(coeff_sin),        // input wire [63:0]  probe3
  .probe17(coeff_cos),        // input wire [63:0]  probe3
  .probe18(coeff_sin_0),      // input wire [15:0]  probe3
  .probe19(coeff_sin_1),      // input wire [15:0]  probe3
  .probe20(coeff_sin_2),      // input wire [15:0]  probe3
  .probe21(coeff_sin_3),      // input wire [15:0]  probe3
  .probe22(coeff_cos_0),      // input wire [15:0]  probe3
  .probe23(coeff_cos_1),      // input wire [15:0]  probe3
  .probe24(coeff_cos_2),      // input wire [15:0]  probe3
  .probe25(coeff_cos_3),      // input wire [15:0]  probe3
  .probe26(base_start),      // input wire [0:0]  probe3
  .probe27(delay_start),     // input wire [0:0]  probe3
  .probe28(base_curr_phase), // input wire [15:0]  probe3
  .probe29(delay_update),    // input wire [0:0]  probe3
  .probe30(delay_curr_phase),// input wire [15:0]  probe3
  .probe31(report),          // input wire [0:0]  probe3
  .probe32(amp_A),           // input wire [15:0]  probe3
  .probe33(amp_B),           // input wire [15:0]  probe3
  .probe34(phase_A),         // input wire [15:0]  probe3
  .probe35(phase_B)         // input wire [15:0]  probe3
);

  reg  [15:0]             coeff_sin_0;
  reg  [15:0]             coeff_sin_1;
  reg  [15:0]             coeff_sin_2;
  reg  [15:0]             coeff_sin_3;

generate
begin : adc_ana_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      config_init <= 0;
      sample_en <= 0;
    end
    else
    begin
      if (conf)
      begin
        config_init <= 1;
        sample_en <= 1;
      end
      else
      begin
        if (config_coeff_done)
          sample_en <= 0;
        config_init <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (config_init)
    begin
      config_count <= count[12:0];

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

      config_has_coeff <= 1;
    end
    else
      config_has_coeff <= 0;
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
              sample_req <= 0;
            end
          2'b01 : 
            begin
              sample_in_1 <= config_sin[15:2];
              coeff_sin_1 <= config_sin;
              coeff_cos_1 <= config_cos;
              sample_req <= 0;
            end
          2'b10 : 
            begin
              sample_in_2 <= config_sin[15:2];
              coeff_sin_2 <= config_sin;
              coeff_cos_2 <= config_cos;
              sample_req <= 0;
            end
          2'b11 :
            begin
              sample_in_3 <= config_sin[15:2];
              coeff_sin_3 <= config_sin;
              coeff_cos_3 <= config_cos;
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
      synt_start <= 0;
      config_adr <= 0;
      synt_phase <= 0;
    end
    else
    begin
      if (config_has_coeff)
      begin
        config_adr <= config_adr + 1;
        synt_phase <= synt_phase + incr;

        if (config_adr == 14'h3FFF)
          synt_start <= 0;
        else
          synt_start <= 1;
      end
      else
      begin
        if (config_init)
        begin
          synt_start <= 1;
          config_adr <= 0;
          synt_phase <= 0;
        end
        else
          synt_start <= 0;
      end
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
          end
          else            
          begin
            coeff_sin[15:0] <= 0;
            coeff_cos[15:0] <= 0;
          end

          if (config_last_en[1])
          begin
            coeff_sin[31:16] <= coeff_sin_1;
            coeff_cos[31:16] <= coeff_cos_1;
          end
          else            
          begin
            coeff_sin[31:16] <= 0;
            coeff_cos[31:16] <= 0;
          end

          if (config_last_en[2])
          begin
            coeff_sin[47:32] <= coeff_sin_2;
            coeff_cos[47:32] <= coeff_cos_2;
          end
          else            
          begin
            coeff_sin[47:32] <= 0;
            coeff_cos[47:32] <= 0;
          end

          if (config_last_en[3])
          begin
            coeff_sin[63:48] <= coeff_sin_3;
            coeff_cos[63:48] <= coeff_cos_3;
          end
          else            
          begin
            coeff_sin[63:48] <= 0;
            coeff_cos[63:48] <= 0;
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
            coeff_sin[31:16] <= coeff_sin_1;
            coeff_cos[31:16] <= coeff_cos_1;
            coeff_sin[47:32] <= coeff_sin_2;
            coeff_cos[47:32] <= coeff_cos_2;
            coeff_sin[63:48] <= coeff_sin_3;
            coeff_cos[63:48] <= coeff_cos_3;
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
    if (reset)
    begin
      report <= 0;
      base_update <= 0;
      delay_update <= 0;
    end
    else
    begin
      if (b_report)
      begin
        base_update <= 1;
        delay_update <= 0;
        report <= 1;

        amp_A <= b_amp_A;
        amp_B <= b_amp_B;

        phase_A <= b_phase_A - base_curr_phase;
        phase_B <= b_phase_B - base_curr_phase;
      end
      else
      begin
        if (d_report)
        begin
          base_update <= 0;
          delay_update <= 1;
          report <= 1;

          amp_A <= d_amp_A;
          amp_B <= d_amp_B;
        
          phase_A <= d_phase_A - delay_curr_phase;
          phase_B <= d_phase_B - delay_curr_phase;
        end
        else
        begin
          base_update <= 0;
          delay_update <= 0;
          report <= 0;
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

end

endgenerate

endmodule
