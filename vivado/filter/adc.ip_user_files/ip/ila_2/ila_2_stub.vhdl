-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Sat Jan 21 18:16:28 2023
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
    probe0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe1 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe2 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe4 : in STD_LOGIC_VECTOR ( 8 downto 0 );
    probe5 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe6 : in STD_LOGIC_VECTOR ( 29 downto 0 );
    probe7 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    probe8 : in STD_LOGIC_VECTOR ( 29 downto 0 );
    probe9 : in STD_LOGIC_VECTOR ( 13 downto 0 )
  );

end ila_2;

architecture stub of ila_2 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[15:0],probe1[15:0],probe2[15:0],probe3[0:0],probe4[8:0],probe5[31:0],probe6[29:0],probe7[13:0],probe8[29:0],probe9[13:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ila,Vivado 2019.2";
begin
end;
