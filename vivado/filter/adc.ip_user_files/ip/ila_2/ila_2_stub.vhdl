-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Sun Feb  5 16:43:56 2023
-- Host        : Leif-I7 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub C:/rdos/vivado/filter/adc.runs/ila_2_synth_1/ila_2_stub.vhdl
-- Design      : ila_2
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg900-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_2 is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe1 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe2 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 1 downto 0 );
    probe4 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe5 : in STD_LOGIC_VECTOR ( 47 downto 0 );
    probe6 : in STD_LOGIC_VECTOR ( 47 downto 0 );
    probe7 : in STD_LOGIC_VECTOR ( 20 downto 0 );
    probe8 : in STD_LOGIC_VECTOR ( 47 downto 0 );
    probe9 : in STD_LOGIC_VECTOR ( 47 downto 0 );
    probe10 : in STD_LOGIC_VECTOR ( 20 downto 0 );
    probe11 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe12 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe13 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe14 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe15 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe16 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe17 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe18 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe19 : in STD_LOGIC_VECTOR ( 47 downto 0 );
    probe20 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    probe21 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    probe22 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    probe23 : in STD_LOGIC_VECTOR ( 127 downto 0 )
  );

end ila_2;

architecture stub of ila_2 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[0:0],probe1[3:0],probe2[15:0],probe3[1:0],probe4[15:0],probe5[47:0],probe6[47:0],probe7[20:0],probe8[47:0],probe9[47:0],probe10[20:0],probe11[15:0],probe12[15:0],probe13[15:0],probe14[15:0],probe15[15:0],probe16[15:0],probe17[0:0],probe18[0:0],probe19[47:0],probe20[127:0],probe21[127:0],probe22[127:0],probe23[127:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ila,Vivado 2019.2";
begin
end;
