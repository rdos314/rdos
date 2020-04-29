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
// phys_bar.v
// Physical address list bar (1 & 2)
//
////////////////////////////////////////////////////////////////////////////////

module phys_bar (
  input wire              reset,
  input wire              clk,

  input wire [16:0]       rd_address,
  input wire              rd,

  output reg [31:0]       rp_data,
  output reg              rp,

  input wire [16:0]       wr_address,
  input wire [31:0]       wr_data,
  input wire [3:0]        wr_be,
  input wire              wr,

  input wire [15:0]       index,
  output reg [19:0]       page,
  output reg              valid
);

// local bar

  wire [15:0]            rd_only_adr;
  wire [15:0]            rd_adr;
  reg  [15:0]            q_curr_index;

  reg                    q_rd;
  reg                    q_rd_msb;
  reg  [15:0]            q_rd_adr;
  wire [19:0]            q_rd_data;

  reg                    q_pend_wr;
  reg  [31:0]            q_pend_data;
  reg  [3:0]             q_pend_be;
  reg                    q_wr_msb;
  reg                    q_wr;
  reg  [15:0]            q_wr_adr;
  reg  [19:0]            q_wr_data;

  reg  [1:0]             q_we;
  reg  [15:0]            q_adr;
  reg  [19:0]            q_data;

bram_phys bram_phys_inst (
  .clka(clk),         // input wire clka
  .wea(q_wr),         // input wire [0 : 0] wea
  .addra(q_wr_adr),   // input wire [15 : 0] addra
  .dina(q_wr_data),   // input wire [19 : 0] dina
  .clkb(clk),         // input wire clkb
  .addrb(rd_adr),     // input wire [15 : 0] addrb
  .doutb(q_rd_data)   // output wire [19 : 0] doutb
);

ila_1 ila_1_inst (
    .clk(clk),                           // input wire clk
    .probe0(wr),                        // input wire [0:0]  probe0  
    .probe1(wr_be),                     // input wire [3:0]  probe0  
    .probe2(wr_data),                   // input wire [31:0]  probe0  
    .probe3(wr_adr),                    // input wire [16:0]  probe0  
    .probe4(q_we),                      // input wire [1:0]  probe0  
    .probe5(q_adr),                     // input wire [15:0]  probe0  
    .probe6(q_data),                    // input wire [19:0]  probe0  
    .probe7(q_wr),                      // input wire [0:0]  probe0  
    .probe8(q_wr_adr),                  // input wire [15:0]  probe0  
    .probe9(q_wr_data),                 // input wire [19:0]  probe0  
    .probe10(rd_adr),                   // input wire [15:0]  probe0  
    .probe11(q_rd_data)                 // input wire [19:0]  probe0  
 );

generate
begin : phys_bar_gen

  assign rd_only_adr = rd ? rd_address[16:1] : index;
  assign rd_adr = wr ? wr_address[16:1] : rd_only_adr;

  always @ ( posedge clk ) 
  begin
    if (q_rd)
    begin
      if (q_rd_msb)
      begin
        rp_data[8:0] <= q_rd_data[19:11];
        rp_data[31:9] <= 0;
      end
      else
      begin
        rp_data[20:0] <= 0;
        rp_data[31:21] <= q_rd_data[10:0];
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
      q_rd <= 0;
      q_wr <= 0;
      q_rd_adr <= 0;
      q_pend_wr <= 0;
      q_we <= 0;
    end
    else
    begin
      q_rd_adr <= rd_adr;

      if (wr)
      begin
        if (wr_be == 4'b1111)
        begin
          q_adr <= wr_address[16:1];
          if (wr_address[0])
          begin
            q_data[19:11] <= wr_data[8:0];
            q_we[1] <= 1;
            if (q_adr != wr_address[16:1])
              q_we[0] <= 0;
          end
          else
          begin
            q_data[10:0] <= wr_data[31:21];
            q_we[0] <= 1;
            if (q_adr != wr_address[16:1])
              q_we[1] <= 0;
          end
        end
        else
        begin
          q_wr_adr <= wr_address[16:1];
          q_wr_msb <= wr_address[0];
          q_pend_data <= wr_data;
          q_pend_be <= wr_be;
          q_rd <= 0;
          q_wr <= 0;
          q_pend_wr <= 1;
        end
      end
      else
      begin
        if (rd)
        begin
          q_rd_msb <= rd_address[0];
          q_rd <= 1;
        end
        else
          q_rd <= 0;

        if (q_we == 2'b11)
        begin
          q_we <= 0;
          q_wr_adr <= q_adr;
          q_wr_data <= q_data;
          q_wr <= 1;
        end
        else
        begin
          if (q_pend_wr)
          begin
            if (q_wr_msb)
            begin
              if (q_pend_be[1])
                q_wr_data[19] <= q_pend_data[8];
              else
                q_wr_data[19] <= q_rd_data[19];

              if (q_pend_be[0])
                q_wr_data[18:11] <= q_pend_data[7:0];
              else
                q_wr_data[18:11] <= q_rd_data[18:11];
            
              q_wr_data[10:0] <= q_rd_data[10:0];
            end
            else
            begin
              if (q_pend_be[3])
                q_wr_data[10:3] <= q_pend_data[31:24];
              else
                q_wr_data[10:3] <= q_rd_data[10:3];
  
              if (q_pend_be[2])
                q_wr_data[2:0] <= q_pend_data[23:21];
              else
                q_wr_data[2:0] <= q_rd_data[2:0];

              q_wr_data[19:11] <= q_rd_data[19:11];
            end

            q_wr <= 1;
            q_pend_wr <= 0;
          end
          else
            q_wr <= 0;
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      valid <= 0;
      page <= 0;
    end
    else
    begin
      q_curr_index <= index;

      if (q_wr && q_wr_adr == index)
      begin
        page <= q_wr_data;
        valid <= 1;
      end
      else
      begin
        if (q_rd_adr == index)
        begin
          page <= q_rd_data;
          valid <= 1;
        end
        else
          if (q_curr_index != index)
            valid <= 0;
      end
    end
  end

end

endgenerate

endmodule
