-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Sun Apr 19 22:45:55 2020
-- Host        : Leif-I7 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim
--               C:/rdos/vivado/adc/adc.runs/jesd204_rx_0_synth_1/jesd204_rx_0_sim_netlist.vhdl
-- Design      : jesd204_rx_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xc7k325tffg900-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_align_mux is
  port (
    data_scrambled_s : out STD_LOGIC_VECTOR ( 17 downto 0 );
    data_aligned_s : out STD_LOGIC_VECTOR ( 23 downto 0 );
    Q : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_charisk_d1_reg[3]_0\ : out STD_LOGIC_VECTOR ( 0 to 0 );
    SS : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_valid_reg : out STD_LOGIC;
    ifs_ready_reg : out STD_LOGIC;
    WEBWE : out STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    \ilas_config_data_reg[5]\ : in STD_LOGIC;
    \ilas_config_data_reg[5]_0\ : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_data_d1_reg[31]_0\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    mem_reg : in STD_LOGIC_VECTOR ( 0 to 0 );
    state : in STD_LOGIC;
    \in_charisk_d1_reg[3]_1\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    \wr_addr_reg[0]\ : in STD_LOGIC;
    ilas_config_valid_reg_0 : in STD_LOGIC;
    ilas_config_valid_reg_1 : in STD_LOGIC;
    state_reg : in STD_LOGIC;
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_align_mux : entity is "align_mux";
end jesd204_rx_0_align_mux;

architecture STRUCTURE of jesd204_rx_0_align_mux is
  signal \^q\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \^ss\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal charisk28_aligned_s : STD_LOGIC_VECTOR ( 1 to 1 );
  signal \^data_aligned_s\ : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal \ilas_config_valid_i_3__2_n_0\ : STD_LOGIC;
  signal \ilas_config_valid_i_5__2_n_0\ : STD_LOGIC;
  signal in_charisk_d1 : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal \^in_charisk_d1_reg[3]_0\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal in_data_d1 : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal \state[14]_i_3__1_n_0\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \ilas_config_valid_i_3__2\ : label is "soft_lutpair69";
  attribute SOFT_HLUTNM of \ilas_config_valid_i_5__2\ : label is "soft_lutpair69";
begin
  Q(7 downto 0) <= \^q\(7 downto 0);
  SS(0) <= \^ss\(0);
  data_aligned_s(23 downto 0) <= \^data_aligned_s\(23 downto 0);
  \in_charisk_d1_reg[3]_0\(0) <= \^in_charisk_d1_reg[3]_0\(0);
\ilas_config_data[0]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(16),
      I1 => \^q\(0),
      I2 => in_data_d1(0),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(8),
      O => \^data_aligned_s\(0)
    );
\ilas_config_data[10]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(2),
      I1 => \in_data_d1_reg[31]_0\(2),
      I2 => in_data_d1(10),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(18),
      O => \^data_aligned_s\(10)
    );
\ilas_config_data[11]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(3),
      I1 => \in_data_d1_reg[31]_0\(3),
      I2 => in_data_d1(11),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(19),
      O => \^data_aligned_s\(11)
    );
\ilas_config_data[12]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(4),
      I1 => \in_data_d1_reg[31]_0\(4),
      I2 => in_data_d1(12),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(20),
      O => \^data_aligned_s\(12)
    );
\ilas_config_data[13]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(5),
      I1 => \in_data_d1_reg[31]_0\(5),
      I2 => in_data_d1(13),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(21),
      O => \^data_aligned_s\(13)
    );
\ilas_config_data[14]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(6),
      I1 => \in_data_d1_reg[31]_0\(6),
      I2 => in_data_d1(14),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(22),
      O => \^data_aligned_s\(14)
    );
\ilas_config_data[15]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(7),
      I1 => \in_data_d1_reg[31]_0\(7),
      I2 => in_data_d1(15),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(23),
      O => \^data_aligned_s\(15)
    );
\ilas_config_data[16]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(0),
      I1 => \in_data_d1_reg[31]_0\(8),
      I2 => in_data_d1(16),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(0),
      O => \^data_aligned_s\(16)
    );
\ilas_config_data[17]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(1),
      I1 => \in_data_d1_reg[31]_0\(9),
      I2 => in_data_d1(17),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(1),
      O => \^data_aligned_s\(17)
    );
\ilas_config_data[18]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(2),
      I1 => \in_data_d1_reg[31]_0\(10),
      I2 => in_data_d1(18),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(2),
      O => \^data_aligned_s\(18)
    );
\ilas_config_data[19]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(3),
      I1 => \in_data_d1_reg[31]_0\(11),
      I2 => in_data_d1(19),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(3),
      O => \^data_aligned_s\(19)
    );
\ilas_config_data[1]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(17),
      I1 => \^q\(1),
      I2 => in_data_d1(1),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(9),
      O => \^data_aligned_s\(1)
    );
\ilas_config_data[20]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(4),
      I1 => \in_data_d1_reg[31]_0\(12),
      I2 => in_data_d1(20),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(4),
      O => \^data_aligned_s\(20)
    );
\ilas_config_data[21]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(5),
      I1 => \in_data_d1_reg[31]_0\(13),
      I2 => in_data_d1(21),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(5),
      O => \^data_aligned_s\(21)
    );
\ilas_config_data[22]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(6),
      I1 => \in_data_d1_reg[31]_0\(14),
      I2 => in_data_d1(22),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(6),
      O => \^data_aligned_s\(22)
    );
\ilas_config_data[23]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(7),
      I1 => \in_data_d1_reg[31]_0\(15),
      I2 => in_data_d1(23),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(7),
      O => \^data_aligned_s\(23)
    );
\ilas_config_data[2]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(18),
      I1 => \^q\(2),
      I2 => in_data_d1(2),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(10),
      O => \^data_aligned_s\(2)
    );
\ilas_config_data[3]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(19),
      I1 => \^q\(3),
      I2 => in_data_d1(3),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(11),
      O => \^data_aligned_s\(3)
    );
\ilas_config_data[4]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(20),
      I1 => \^q\(4),
      I2 => in_data_d1(4),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(12),
      O => \^data_aligned_s\(4)
    );
\ilas_config_data[5]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(21),
      I1 => \^q\(5),
      I2 => in_data_d1(5),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(13),
      O => \^data_aligned_s\(5)
    );
\ilas_config_data[6]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(22),
      I1 => \^q\(6),
      I2 => in_data_d1(6),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(14),
      O => \^data_aligned_s\(6)
    );
\ilas_config_data[7]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(23),
      I1 => \^q\(7),
      I2 => in_data_d1(7),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(15),
      O => \^data_aligned_s\(7)
    );
\ilas_config_data[8]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(0),
      I1 => \in_data_d1_reg[31]_0\(0),
      I2 => in_data_d1(8),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(16),
      O => \^data_aligned_s\(8)
    );
\ilas_config_data[9]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(1),
      I1 => \in_data_d1_reg[31]_0\(1),
      I2 => in_data_d1(9),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(17),
      O => \^data_aligned_s\(9)
    );
\ilas_config_valid_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FE22022200000000"
    )
        port map (
      I0 => ilas_config_valid_reg_0,
      I1 => ilas_config_valid_reg_1,
      I2 => \ilas_config_valid_i_3__2_n_0\,
      I3 => charisk28_aligned_s(1),
      I4 => \ilas_config_valid_i_5__2_n_0\,
      I5 => state_reg,
      O => ilas_config_valid_reg
    );
\ilas_config_valid_i_3__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0400"
    )
        port map (
      I0 => \^data_aligned_s\(14),
      I1 => \^data_aligned_s\(15),
      I2 => \^data_aligned_s\(13),
      I3 => state,
      O => \ilas_config_valid_i_3__2_n_0\
    );
\ilas_config_valid_i_4__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFAACCF000AACCF0"
    )
        port map (
      I0 => \^in_charisk_d1_reg[3]_0\(0),
      I1 => in_charisk_d1(2),
      I2 => in_charisk_d1(1),
      I3 => \ilas_config_data_reg[5]_0\,
      I4 => \ilas_config_data_reg[5]\,
      I5 => \in_charisk_d1_reg[3]_1\(0),
      O => charisk28_aligned_s(1)
    );
\ilas_config_valid_i_5__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"10"
    )
        port map (
      I0 => \^data_aligned_s\(13),
      I1 => \^data_aligned_s\(14),
      I2 => \^data_aligned_s\(15),
      O => \ilas_config_valid_i_5__2_n_0\
    );
\in_charisk_d1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(0),
      Q => in_charisk_d1(0),
      R => '0'
    );
\in_charisk_d1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(1),
      Q => in_charisk_d1(1),
      R => '0'
    );
\in_charisk_d1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(2),
      Q => in_charisk_d1(2),
      R => '0'
    );
\in_charisk_d1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(3),
      Q => \^in_charisk_d1_reg[3]_0\(0),
      R => '0'
    );
\in_data_d1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(0),
      Q => in_data_d1(0),
      R => '0'
    );
\in_data_d1_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(10),
      Q => in_data_d1(10),
      R => '0'
    );
\in_data_d1_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(11),
      Q => in_data_d1(11),
      R => '0'
    );
\in_data_d1_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(12),
      Q => in_data_d1(12),
      R => '0'
    );
\in_data_d1_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(13),
      Q => in_data_d1(13),
      R => '0'
    );
\in_data_d1_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(14),
      Q => in_data_d1(14),
      R => '0'
    );
\in_data_d1_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(15),
      Q => in_data_d1(15),
      R => '0'
    );
\in_data_d1_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(16),
      Q => in_data_d1(16),
      R => '0'
    );
\in_data_d1_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(17),
      Q => in_data_d1(17),
      R => '0'
    );
\in_data_d1_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(18),
      Q => in_data_d1(18),
      R => '0'
    );
\in_data_d1_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(19),
      Q => in_data_d1(19),
      R => '0'
    );
\in_data_d1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(1),
      Q => in_data_d1(1),
      R => '0'
    );
\in_data_d1_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(20),
      Q => in_data_d1(20),
      R => '0'
    );
\in_data_d1_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(21),
      Q => in_data_d1(21),
      R => '0'
    );
\in_data_d1_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(22),
      Q => in_data_d1(22),
      R => '0'
    );
\in_data_d1_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(23),
      Q => in_data_d1(23),
      R => '0'
    );
\in_data_d1_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(24),
      Q => \^q\(0),
      R => '0'
    );
\in_data_d1_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(25),
      Q => \^q\(1),
      R => '0'
    );
\in_data_d1_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(26),
      Q => \^q\(2),
      R => '0'
    );
\in_data_d1_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(27),
      Q => \^q\(3),
      R => '0'
    );
\in_data_d1_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(28),
      Q => \^q\(4),
      R => '0'
    );
\in_data_d1_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(29),
      Q => \^q\(5),
      R => '0'
    );
\in_data_d1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(2),
      Q => in_data_d1(2),
      R => '0'
    );
\in_data_d1_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(30),
      Q => \^q\(6),
      R => '0'
    );
\in_data_d1_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(31),
      Q => \^q\(7),
      R => '0'
    );
\in_data_d1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(3),
      Q => in_data_d1(3),
      R => '0'
    );
\in_data_d1_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(4),
      Q => in_data_d1(4),
      R => '0'
    );
\in_data_d1_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(5),
      Q => in_data_d1(5),
      R => '0'
    );
\in_data_d1_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(6),
      Q => in_data_d1(6),
      R => '0'
    );
\in_data_d1_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(7),
      Q => in_data_d1(7),
      R => '0'
    );
\in_data_d1_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(8),
      Q => in_data_d1(8),
      R => '0'
    );
\in_data_d1_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(9),
      Q => in_data_d1(9),
      R => '0'
    );
\mem_reg_i_18__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(13),
      I2 => \^data_aligned_s\(14),
      I3 => D(7),
      O => data_scrambled_s(17)
    );
\mem_reg_i_19__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(13),
      I2 => \^data_aligned_s\(12),
      I3 => D(6),
      O => data_scrambled_s(16)
    );
\mem_reg_i_20__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(12),
      I2 => \^data_aligned_s\(11),
      I3 => D(5),
      O => data_scrambled_s(15)
    );
\mem_reg_i_21__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(11),
      I2 => \^data_aligned_s\(10),
      I3 => D(4),
      O => data_scrambled_s(14)
    );
\mem_reg_i_22__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(10),
      I2 => \^data_aligned_s\(9),
      I3 => D(3),
      O => data_scrambled_s(13)
    );
\mem_reg_i_23__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(9),
      I2 => \^data_aligned_s\(8),
      I3 => D(2),
      O => data_scrambled_s(12)
    );
\mem_reg_i_24__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(23),
      I2 => \^data_aligned_s\(8),
      I3 => D(1),
      O => data_scrambled_s(11)
    );
\mem_reg_i_25__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(23),
      I2 => \^data_aligned_s\(22),
      I3 => D(0),
      O => data_scrambled_s(10)
    );
\mem_reg_i_26__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(5),
      I2 => \^data_aligned_s\(23),
      I3 => \^data_aligned_s\(6),
      O => data_scrambled_s(9)
    );
\mem_reg_i_27__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(4),
      I2 => \^data_aligned_s\(5),
      I3 => \^data_aligned_s\(22),
      O => data_scrambled_s(8)
    );
\mem_reg_i_28__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(4),
      I2 => \^data_aligned_s\(3),
      I3 => \^data_aligned_s\(21),
      O => data_scrambled_s(7)
    );
\mem_reg_i_29__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(3),
      I2 => \^data_aligned_s\(2),
      I3 => \^data_aligned_s\(20),
      O => data_scrambled_s(6)
    );
\mem_reg_i_30__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(2),
      I2 => \^data_aligned_s\(1),
      I3 => \^data_aligned_s\(19),
      O => data_scrambled_s(5)
    );
\mem_reg_i_31__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(1),
      I2 => \^data_aligned_s\(0),
      I3 => \^data_aligned_s\(18),
      O => data_scrambled_s(4)
    );
\mem_reg_i_32__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(15),
      I2 => \^data_aligned_s\(0),
      I3 => \^data_aligned_s\(17),
      O => data_scrambled_s(3)
    );
\mem_reg_i_33__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(14),
      I2 => \^data_aligned_s\(15),
      I3 => \^data_aligned_s\(16),
      O => data_scrambled_s(2)
    );
mem_reg_i_34: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \^ss\(0),
      O => WEBWE(0)
    );
\mem_reg_i_8__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => mem_reg(0),
      I2 => \^data_aligned_s\(9),
      I3 => \^data_aligned_s\(7),
      O => data_scrambled_s(1)
    );
\mem_reg_i_9__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(7),
      I2 => \^data_aligned_s\(8),
      I3 => \^data_aligned_s\(6),
      O => data_scrambled_s(0)
    );
\state[14]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAAAAAAAAEA"
    )
        port map (
      I0 => \wr_addr_reg[0]\,
      I1 => state,
      I2 => \state[14]_i_3__1_n_0\,
      I3 => \^data_aligned_s\(5),
      I4 => \^data_aligned_s\(6),
      I5 => \^data_aligned_s\(7),
      O => \^ss\(0)
    );
\state[14]_i_3__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_charisk_d1(2),
      I1 => \^in_charisk_d1_reg[3]_0\(0),
      I2 => in_charisk_d1(0),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_charisk_d1(1),
      O => \state[14]_i_3__1_n_0\
    );
\state_i_1__1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"B"
    )
        port map (
      I0 => \^ss\(0),
      I1 => state_reg,
      O => ifs_ready_reg
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_align_mux_13 is
  port (
    data_scrambled_s : out STD_LOGIC_VECTOR ( 17 downto 0 );
    data_aligned_s : out STD_LOGIC_VECTOR ( 23 downto 0 );
    Q : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_charisk_d1_reg[3]_0\ : out STD_LOGIC_VECTOR ( 0 to 0 );
    SR : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_valid_reg : out STD_LOGIC;
    buffer_release_opportunity_reg : out STD_LOGIC;
    state_reg : out STD_LOGIC;
    WEBWE : out STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    \ilas_config_data_reg[5]\ : in STD_LOGIC;
    \ilas_config_data_reg[5]_0\ : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_data_d1_reg[31]_0\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    mem_reg : in STD_LOGIC_VECTOR ( 0 to 0 );
    state : in STD_LOGIC;
    \in_charisk_d1_reg[3]_1\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    cfg_lanes_disable : in STD_LOGIC_VECTOR ( 1 downto 0 );
    p_7_out : in STD_LOGIC;
    state_reg_0 : in STD_LOGIC;
    prev_was_last : in STD_LOGIC;
    ilas_config_valid_reg_0 : in STD_LOGIC;
    ilas_config_valid_reg_1 : in STD_LOGIC;
    buffer_release_n_reg : in STD_LOGIC;
    buffer_release_opportunity : in STD_LOGIC;
    buffer_release_n : in STD_LOGIC;
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_align_mux_13 : entity is "align_mux";
end jesd204_rx_0_align_mux_13;

architecture STRUCTURE of jesd204_rx_0_align_mux_13 is
  signal \^q\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal buffer_release_n_i_2_n_0 : STD_LOGIC;
  signal charisk28_aligned_s : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \^data_aligned_s\ : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal ilas_config_valid_i_3_n_0 : STD_LOGIC;
  signal ilas_config_valid_i_5_n_0 : STD_LOGIC;
  signal in_charisk_d1 : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal \^in_charisk_d1_reg[3]_0\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal in_data_d1 : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal \mem_reg_i_34__0_n_0\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of buffer_release_n_i_2 : label is "soft_lutpair32";
  attribute SOFT_HLUTNM of ilas_config_valid_i_3 : label is "soft_lutpair33";
  attribute SOFT_HLUTNM of ilas_config_valid_i_5 : label is "soft_lutpair33";
  attribute SOFT_HLUTNM of \state[14]_i_1\ : label is "soft_lutpair32";
begin
  Q(7 downto 0) <= \^q\(7 downto 0);
  data_aligned_s(23 downto 0) <= \^data_aligned_s\(23 downto 0);
  \in_charisk_d1_reg[3]_0\(0) <= \^in_charisk_d1_reg[3]_0\(0);
buffer_release_n_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EFE0"
    )
        port map (
      I0 => buffer_release_n_i_2_n_0,
      I1 => buffer_release_n_reg,
      I2 => buffer_release_opportunity,
      I3 => buffer_release_n,
      O => buffer_release_opportunity_reg
    );
buffer_release_n_i_2: unisim.vcomponents.LUT5
    generic map(
      INIT => X"08FF0808"
    )
        port map (
      I0 => \mem_reg_i_34__0_n_0\,
      I1 => state,
      I2 => cfg_lanes_disable(0),
      I3 => cfg_lanes_disable(1),
      I4 => p_7_out,
      O => buffer_release_n_i_2_n_0
    );
\ilas_config_data[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(16),
      I1 => \^q\(0),
      I2 => in_data_d1(0),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(8),
      O => \^data_aligned_s\(0)
    );
\ilas_config_data[10]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(2),
      I1 => \in_data_d1_reg[31]_0\(2),
      I2 => in_data_d1(10),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(18),
      O => \^data_aligned_s\(10)
    );
\ilas_config_data[11]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(3),
      I1 => \in_data_d1_reg[31]_0\(3),
      I2 => in_data_d1(11),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(19),
      O => \^data_aligned_s\(11)
    );
\ilas_config_data[12]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(4),
      I1 => \in_data_d1_reg[31]_0\(4),
      I2 => in_data_d1(12),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(20),
      O => \^data_aligned_s\(12)
    );
\ilas_config_data[13]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(5),
      I1 => \in_data_d1_reg[31]_0\(5),
      I2 => in_data_d1(13),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(21),
      O => \^data_aligned_s\(13)
    );
\ilas_config_data[14]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(6),
      I1 => \in_data_d1_reg[31]_0\(6),
      I2 => in_data_d1(14),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(22),
      O => \^data_aligned_s\(14)
    );
\ilas_config_data[15]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(7),
      I1 => \in_data_d1_reg[31]_0\(7),
      I2 => in_data_d1(15),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(23),
      O => \^data_aligned_s\(15)
    );
\ilas_config_data[16]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(0),
      I1 => \in_data_d1_reg[31]_0\(8),
      I2 => in_data_d1(16),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(0),
      O => \^data_aligned_s\(16)
    );
\ilas_config_data[17]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(1),
      I1 => \in_data_d1_reg[31]_0\(9),
      I2 => in_data_d1(17),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(1),
      O => \^data_aligned_s\(17)
    );
\ilas_config_data[18]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(2),
      I1 => \in_data_d1_reg[31]_0\(10),
      I2 => in_data_d1(18),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(2),
      O => \^data_aligned_s\(18)
    );
\ilas_config_data[19]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(3),
      I1 => \in_data_d1_reg[31]_0\(11),
      I2 => in_data_d1(19),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(3),
      O => \^data_aligned_s\(19)
    );
\ilas_config_data[1]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(17),
      I1 => \^q\(1),
      I2 => in_data_d1(1),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(9),
      O => \^data_aligned_s\(1)
    );
\ilas_config_data[20]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(4),
      I1 => \in_data_d1_reg[31]_0\(12),
      I2 => in_data_d1(20),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(4),
      O => \^data_aligned_s\(20)
    );
\ilas_config_data[21]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(5),
      I1 => \in_data_d1_reg[31]_0\(13),
      I2 => in_data_d1(21),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(5),
      O => \^data_aligned_s\(21)
    );
\ilas_config_data[22]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(6),
      I1 => \in_data_d1_reg[31]_0\(14),
      I2 => in_data_d1(22),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(6),
      O => \^data_aligned_s\(22)
    );
\ilas_config_data[23]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(7),
      I1 => \in_data_d1_reg[31]_0\(15),
      I2 => in_data_d1(23),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(7),
      O => \^data_aligned_s\(23)
    );
\ilas_config_data[2]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(18),
      I1 => \^q\(2),
      I2 => in_data_d1(2),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(10),
      O => \^data_aligned_s\(2)
    );
\ilas_config_data[3]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(19),
      I1 => \^q\(3),
      I2 => in_data_d1(3),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(11),
      O => \^data_aligned_s\(3)
    );
\ilas_config_data[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(20),
      I1 => \^q\(4),
      I2 => in_data_d1(4),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(12),
      O => \^data_aligned_s\(4)
    );
\ilas_config_data[5]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(21),
      I1 => \^q\(5),
      I2 => in_data_d1(5),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(13),
      O => \^data_aligned_s\(5)
    );
\ilas_config_data[6]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(22),
      I1 => \^q\(6),
      I2 => in_data_d1(6),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(14),
      O => \^data_aligned_s\(6)
    );
\ilas_config_data[7]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(23),
      I1 => \^q\(7),
      I2 => in_data_d1(7),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(15),
      O => \^data_aligned_s\(7)
    );
\ilas_config_data[8]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(0),
      I1 => \in_data_d1_reg[31]_0\(0),
      I2 => in_data_d1(8),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(16),
      O => \^data_aligned_s\(8)
    );
\ilas_config_data[9]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(1),
      I1 => \in_data_d1_reg[31]_0\(1),
      I2 => in_data_d1(9),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(17),
      O => \^data_aligned_s\(9)
    );
ilas_config_valid_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FE22022200000000"
    )
        port map (
      I0 => ilas_config_valid_reg_0,
      I1 => ilas_config_valid_reg_1,
      I2 => ilas_config_valid_i_3_n_0,
      I3 => charisk28_aligned_s(1),
      I4 => ilas_config_valid_i_5_n_0,
      I5 => state_reg_0,
      O => ilas_config_valid_reg
    );
ilas_config_valid_i_3: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0400"
    )
        port map (
      I0 => \^data_aligned_s\(14),
      I1 => \^data_aligned_s\(15),
      I2 => \^data_aligned_s\(13),
      I3 => state,
      O => ilas_config_valid_i_3_n_0
    );
ilas_config_valid_i_4: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFAACCF000AACCF0"
    )
        port map (
      I0 => \^in_charisk_d1_reg[3]_0\(0),
      I1 => in_charisk_d1(2),
      I2 => in_charisk_d1(1),
      I3 => \ilas_config_data_reg[5]_0\,
      I4 => \ilas_config_data_reg[5]\,
      I5 => \in_charisk_d1_reg[3]_1\(0),
      O => charisk28_aligned_s(1)
    );
ilas_config_valid_i_5: unisim.vcomponents.LUT3
    generic map(
      INIT => X"10"
    )
        port map (
      I0 => \^data_aligned_s\(13),
      I1 => \^data_aligned_s\(14),
      I2 => \^data_aligned_s\(15),
      O => ilas_config_valid_i_5_n_0
    );
\in_charisk_d1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(0),
      Q => in_charisk_d1(0),
      R => '0'
    );
\in_charisk_d1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(1),
      Q => in_charisk_d1(1),
      R => '0'
    );
\in_charisk_d1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(2),
      Q => in_charisk_d1(2),
      R => '0'
    );
\in_charisk_d1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(3),
      Q => \^in_charisk_d1_reg[3]_0\(0),
      R => '0'
    );
\in_data_d1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(0),
      Q => in_data_d1(0),
      R => '0'
    );
\in_data_d1_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(10),
      Q => in_data_d1(10),
      R => '0'
    );
\in_data_d1_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(11),
      Q => in_data_d1(11),
      R => '0'
    );
\in_data_d1_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(12),
      Q => in_data_d1(12),
      R => '0'
    );
\in_data_d1_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(13),
      Q => in_data_d1(13),
      R => '0'
    );
\in_data_d1_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(14),
      Q => in_data_d1(14),
      R => '0'
    );
\in_data_d1_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(15),
      Q => in_data_d1(15),
      R => '0'
    );
\in_data_d1_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(16),
      Q => in_data_d1(16),
      R => '0'
    );
\in_data_d1_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(17),
      Q => in_data_d1(17),
      R => '0'
    );
\in_data_d1_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(18),
      Q => in_data_d1(18),
      R => '0'
    );
\in_data_d1_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(19),
      Q => in_data_d1(19),
      R => '0'
    );
\in_data_d1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(1),
      Q => in_data_d1(1),
      R => '0'
    );
\in_data_d1_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(20),
      Q => in_data_d1(20),
      R => '0'
    );
\in_data_d1_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(21),
      Q => in_data_d1(21),
      R => '0'
    );
\in_data_d1_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(22),
      Q => in_data_d1(22),
      R => '0'
    );
\in_data_d1_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(23),
      Q => in_data_d1(23),
      R => '0'
    );
\in_data_d1_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(24),
      Q => \^q\(0),
      R => '0'
    );
\in_data_d1_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(25),
      Q => \^q\(1),
      R => '0'
    );
\in_data_d1_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(26),
      Q => \^q\(2),
      R => '0'
    );
\in_data_d1_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(27),
      Q => \^q\(3),
      R => '0'
    );
\in_data_d1_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(28),
      Q => \^q\(4),
      R => '0'
    );
\in_data_d1_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(29),
      Q => \^q\(5),
      R => '0'
    );
\in_data_d1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(2),
      Q => in_data_d1(2),
      R => '0'
    );
\in_data_d1_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(30),
      Q => \^q\(6),
      R => '0'
    );
\in_data_d1_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(31),
      Q => \^q\(7),
      R => '0'
    );
\in_data_d1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(3),
      Q => in_data_d1(3),
      R => '0'
    );
\in_data_d1_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(4),
      Q => in_data_d1(4),
      R => '0'
    );
\in_data_d1_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(5),
      Q => in_data_d1(5),
      R => '0'
    );
\in_data_d1_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(6),
      Q => in_data_d1(6),
      R => '0'
    );
\in_data_d1_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(7),
      Q => in_data_d1(7),
      R => '0'
    );
\in_data_d1_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(8),
      Q => in_data_d1(8),
      R => '0'
    );
\in_data_d1_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(9),
      Q => in_data_d1(9),
      R => '0'
    );
mem_reg_i_17: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(13),
      I2 => \^data_aligned_s\(14),
      I3 => D(7),
      O => data_scrambled_s(17)
    );
mem_reg_i_18: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(13),
      I2 => \^data_aligned_s\(12),
      I3 => D(6),
      O => data_scrambled_s(16)
    );
mem_reg_i_19: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(12),
      I2 => \^data_aligned_s\(11),
      I3 => D(5),
      O => data_scrambled_s(15)
    );
mem_reg_i_20: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(11),
      I2 => \^data_aligned_s\(10),
      I3 => D(4),
      O => data_scrambled_s(14)
    );
mem_reg_i_21: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(10),
      I2 => \^data_aligned_s\(9),
      I3 => D(3),
      O => data_scrambled_s(13)
    );
mem_reg_i_22: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(9),
      I2 => \^data_aligned_s\(8),
      I3 => D(2),
      O => data_scrambled_s(12)
    );
mem_reg_i_23: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(23),
      I2 => \^data_aligned_s\(8),
      I3 => D(1),
      O => data_scrambled_s(11)
    );
mem_reg_i_24: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(23),
      I2 => \^data_aligned_s\(22),
      I3 => D(0),
      O => data_scrambled_s(10)
    );
mem_reg_i_25: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(5),
      I2 => \^data_aligned_s\(23),
      I3 => \^data_aligned_s\(6),
      O => data_scrambled_s(9)
    );
mem_reg_i_26: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(4),
      I2 => \^data_aligned_s\(5),
      I3 => \^data_aligned_s\(22),
      O => data_scrambled_s(8)
    );
mem_reg_i_27: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(4),
      I2 => \^data_aligned_s\(3),
      I3 => \^data_aligned_s\(21),
      O => data_scrambled_s(7)
    );
mem_reg_i_28: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(3),
      I2 => \^data_aligned_s\(2),
      I3 => \^data_aligned_s\(20),
      O => data_scrambled_s(6)
    );
mem_reg_i_29: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(2),
      I2 => \^data_aligned_s\(1),
      I3 => \^data_aligned_s\(19),
      O => data_scrambled_s(5)
    );
mem_reg_i_30: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(1),
      I2 => \^data_aligned_s\(0),
      I3 => \^data_aligned_s\(18),
      O => data_scrambled_s(4)
    );
mem_reg_i_31: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(15),
      I2 => \^data_aligned_s\(0),
      I3 => \^data_aligned_s\(17),
      O => data_scrambled_s(3)
    );
mem_reg_i_32: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(14),
      I2 => \^data_aligned_s\(15),
      I3 => \^data_aligned_s\(16),
      O => data_scrambled_s(2)
    );
\mem_reg_i_33__2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"7"
    )
        port map (
      I0 => \mem_reg_i_34__0_n_0\,
      I1 => state,
      O => WEBWE(0)
    );
\mem_reg_i_34__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"55555575FFFFFFFF"
    )
        port map (
      I0 => state_reg_0,
      I1 => \^data_aligned_s\(6),
      I2 => charisk28_aligned_s(0),
      I3 => \^data_aligned_s\(5),
      I4 => \^data_aligned_s\(7),
      I5 => prev_was_last,
      O => \mem_reg_i_34__0_n_0\
    );
mem_reg_i_35: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_charisk_d1(2),
      I1 => \^in_charisk_d1_reg[3]_0\(0),
      I2 => in_charisk_d1(0),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_charisk_d1(1),
      O => charisk28_aligned_s(0)
    );
mem_reg_i_7: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => mem_reg(0),
      I2 => \^data_aligned_s\(9),
      I3 => \^data_aligned_s\(7),
      O => data_scrambled_s(1)
    );
mem_reg_i_8: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(7),
      I2 => \^data_aligned_s\(8),
      I3 => \^data_aligned_s\(6),
      O => data_scrambled_s(0)
    );
\state[14]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \mem_reg_i_34__0_n_0\,
      I1 => state,
      O => SR(0)
    );
\state_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"8F"
    )
        port map (
      I0 => \mem_reg_i_34__0_n_0\,
      I1 => state,
      I2 => state_reg_0,
      O => state_reg
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_align_mux_3 is
  port (
    \cfg_lanes_disable[2]\ : out STD_LOGIC;
    p_17_out : out STD_LOGIC;
    data_scrambled_s : out STD_LOGIC_VECTOR ( 17 downto 0 );
    data_aligned_s : out STD_LOGIC_VECTOR ( 23 downto 0 );
    Q : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_charisk_d1_reg[3]_0\ : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_valid_reg : out STD_LOGIC;
    ifs_ready_reg : out STD_LOGIC;
    WEBWE : out STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_lanes_disable : in STD_LOGIC_VECTOR ( 1 downto 0 );
    p_27_out : in STD_LOGIC;
    cfg_disable_scrambler : in STD_LOGIC;
    \ilas_config_data_reg[5]\ : in STD_LOGIC;
    \ilas_config_data_reg[5]_0\ : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_data_d1_reg[31]_0\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    mem_reg : in STD_LOGIC_VECTOR ( 0 to 0 );
    state : in STD_LOGIC;
    \in_charisk_d1_reg[3]_1\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    \wr_addr_reg[6]\ : in STD_LOGIC;
    ilas_config_valid_reg_0 : in STD_LOGIC;
    ilas_config_valid_reg_1 : in STD_LOGIC;
    state_reg : in STD_LOGIC;
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_align_mux_3 : entity is "align_mux";
end jesd204_rx_0_align_mux_3;

architecture STRUCTURE of jesd204_rx_0_align_mux_3 is
  signal \^q\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal charisk28_aligned_s : STD_LOGIC_VECTOR ( 1 to 1 );
  signal \^data_aligned_s\ : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal \ilas_config_valid_i_3__1_n_0\ : STD_LOGIC;
  signal \ilas_config_valid_i_5__1_n_0\ : STD_LOGIC;
  signal in_charisk_d1 : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal \^in_charisk_d1_reg[3]_0\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal in_data_d1 : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal \^p_17_out\ : STD_LOGIC;
  signal \state[14]_i_3__0_n_0\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of buffer_release_n_i_3 : label is "soft_lutpair57";
  attribute SOFT_HLUTNM of \ilas_config_valid_i_3__1\ : label is "soft_lutpair56";
  attribute SOFT_HLUTNM of \ilas_config_valid_i_5__1\ : label is "soft_lutpair56";
  attribute SOFT_HLUTNM of \state_i_1__0\ : label is "soft_lutpair57";
begin
  Q(7 downto 0) <= \^q\(7 downto 0);
  data_aligned_s(23 downto 0) <= \^data_aligned_s\(23 downto 0);
  \in_charisk_d1_reg[3]_0\(0) <= \^in_charisk_d1_reg[3]_0\(0);
  p_17_out <= \^p_17_out\;
buffer_release_n_i_3: unisim.vcomponents.LUT4
    generic map(
      INIT => X"4F44"
    )
        port map (
      I0 => cfg_lanes_disable(1),
      I1 => \^p_17_out\,
      I2 => cfg_lanes_disable(0),
      I3 => p_27_out,
      O => \cfg_lanes_disable[2]\
    );
\ilas_config_data[0]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(16),
      I1 => \^q\(0),
      I2 => in_data_d1(0),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(8),
      O => \^data_aligned_s\(0)
    );
\ilas_config_data[10]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(2),
      I1 => \in_data_d1_reg[31]_0\(2),
      I2 => in_data_d1(10),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(18),
      O => \^data_aligned_s\(10)
    );
\ilas_config_data[11]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(3),
      I1 => \in_data_d1_reg[31]_0\(3),
      I2 => in_data_d1(11),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(19),
      O => \^data_aligned_s\(11)
    );
\ilas_config_data[12]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(4),
      I1 => \in_data_d1_reg[31]_0\(4),
      I2 => in_data_d1(12),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(20),
      O => \^data_aligned_s\(12)
    );
\ilas_config_data[13]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(5),
      I1 => \in_data_d1_reg[31]_0\(5),
      I2 => in_data_d1(13),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(21),
      O => \^data_aligned_s\(13)
    );
\ilas_config_data[14]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(6),
      I1 => \in_data_d1_reg[31]_0\(6),
      I2 => in_data_d1(14),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(22),
      O => \^data_aligned_s\(14)
    );
\ilas_config_data[15]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(7),
      I1 => \in_data_d1_reg[31]_0\(7),
      I2 => in_data_d1(15),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(23),
      O => \^data_aligned_s\(15)
    );
\ilas_config_data[16]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(0),
      I1 => \in_data_d1_reg[31]_0\(8),
      I2 => in_data_d1(16),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(0),
      O => \^data_aligned_s\(16)
    );
\ilas_config_data[17]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(1),
      I1 => \in_data_d1_reg[31]_0\(9),
      I2 => in_data_d1(17),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(1),
      O => \^data_aligned_s\(17)
    );
\ilas_config_data[18]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(2),
      I1 => \in_data_d1_reg[31]_0\(10),
      I2 => in_data_d1(18),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(2),
      O => \^data_aligned_s\(18)
    );
\ilas_config_data[19]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(3),
      I1 => \in_data_d1_reg[31]_0\(11),
      I2 => in_data_d1(19),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(3),
      O => \^data_aligned_s\(19)
    );
\ilas_config_data[1]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(17),
      I1 => \^q\(1),
      I2 => in_data_d1(1),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(9),
      O => \^data_aligned_s\(1)
    );
\ilas_config_data[20]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(4),
      I1 => \in_data_d1_reg[31]_0\(12),
      I2 => in_data_d1(20),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(4),
      O => \^data_aligned_s\(20)
    );
\ilas_config_data[21]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(5),
      I1 => \in_data_d1_reg[31]_0\(13),
      I2 => in_data_d1(21),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(5),
      O => \^data_aligned_s\(21)
    );
\ilas_config_data[22]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(6),
      I1 => \in_data_d1_reg[31]_0\(14),
      I2 => in_data_d1(22),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(6),
      O => \^data_aligned_s\(22)
    );
\ilas_config_data[23]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(7),
      I1 => \in_data_d1_reg[31]_0\(15),
      I2 => in_data_d1(23),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(7),
      O => \^data_aligned_s\(23)
    );
\ilas_config_data[2]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(18),
      I1 => \^q\(2),
      I2 => in_data_d1(2),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(10),
      O => \^data_aligned_s\(2)
    );
\ilas_config_data[3]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(19),
      I1 => \^q\(3),
      I2 => in_data_d1(3),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(11),
      O => \^data_aligned_s\(3)
    );
\ilas_config_data[4]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(20),
      I1 => \^q\(4),
      I2 => in_data_d1(4),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(12),
      O => \^data_aligned_s\(4)
    );
\ilas_config_data[5]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(21),
      I1 => \^q\(5),
      I2 => in_data_d1(5),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(13),
      O => \^data_aligned_s\(5)
    );
\ilas_config_data[6]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(22),
      I1 => \^q\(6),
      I2 => in_data_d1(6),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(14),
      O => \^data_aligned_s\(6)
    );
\ilas_config_data[7]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(23),
      I1 => \^q\(7),
      I2 => in_data_d1(7),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(15),
      O => \^data_aligned_s\(7)
    );
\ilas_config_data[8]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(0),
      I1 => \in_data_d1_reg[31]_0\(0),
      I2 => in_data_d1(8),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(16),
      O => \^data_aligned_s\(8)
    );
\ilas_config_data[9]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(1),
      I1 => \in_data_d1_reg[31]_0\(1),
      I2 => in_data_d1(9),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(17),
      O => \^data_aligned_s\(9)
    );
\ilas_config_valid_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FE22022200000000"
    )
        port map (
      I0 => ilas_config_valid_reg_0,
      I1 => ilas_config_valid_reg_1,
      I2 => \ilas_config_valid_i_3__1_n_0\,
      I3 => charisk28_aligned_s(1),
      I4 => \ilas_config_valid_i_5__1_n_0\,
      I5 => state_reg,
      O => ilas_config_valid_reg
    );
\ilas_config_valid_i_3__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0400"
    )
        port map (
      I0 => \^data_aligned_s\(14),
      I1 => \^data_aligned_s\(15),
      I2 => \^data_aligned_s\(13),
      I3 => state,
      O => \ilas_config_valid_i_3__1_n_0\
    );
\ilas_config_valid_i_4__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFAACCF000AACCF0"
    )
        port map (
      I0 => \^in_charisk_d1_reg[3]_0\(0),
      I1 => in_charisk_d1(2),
      I2 => in_charisk_d1(1),
      I3 => \ilas_config_data_reg[5]_0\,
      I4 => \ilas_config_data_reg[5]\,
      I5 => \in_charisk_d1_reg[3]_1\(0),
      O => charisk28_aligned_s(1)
    );
\ilas_config_valid_i_5__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"10"
    )
        port map (
      I0 => \^data_aligned_s\(13),
      I1 => \^data_aligned_s\(14),
      I2 => \^data_aligned_s\(15),
      O => \ilas_config_valid_i_5__1_n_0\
    );
\in_charisk_d1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(0),
      Q => in_charisk_d1(0),
      R => '0'
    );
\in_charisk_d1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(1),
      Q => in_charisk_d1(1),
      R => '0'
    );
\in_charisk_d1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(2),
      Q => in_charisk_d1(2),
      R => '0'
    );
\in_charisk_d1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(3),
      Q => \^in_charisk_d1_reg[3]_0\(0),
      R => '0'
    );
\in_data_d1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(0),
      Q => in_data_d1(0),
      R => '0'
    );
\in_data_d1_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(10),
      Q => in_data_d1(10),
      R => '0'
    );
\in_data_d1_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(11),
      Q => in_data_d1(11),
      R => '0'
    );
\in_data_d1_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(12),
      Q => in_data_d1(12),
      R => '0'
    );
\in_data_d1_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(13),
      Q => in_data_d1(13),
      R => '0'
    );
\in_data_d1_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(14),
      Q => in_data_d1(14),
      R => '0'
    );
\in_data_d1_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(15),
      Q => in_data_d1(15),
      R => '0'
    );
\in_data_d1_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(16),
      Q => in_data_d1(16),
      R => '0'
    );
\in_data_d1_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(17),
      Q => in_data_d1(17),
      R => '0'
    );
\in_data_d1_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(18),
      Q => in_data_d1(18),
      R => '0'
    );
\in_data_d1_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(19),
      Q => in_data_d1(19),
      R => '0'
    );
\in_data_d1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(1),
      Q => in_data_d1(1),
      R => '0'
    );
\in_data_d1_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(20),
      Q => in_data_d1(20),
      R => '0'
    );
\in_data_d1_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(21),
      Q => in_data_d1(21),
      R => '0'
    );
\in_data_d1_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(22),
      Q => in_data_d1(22),
      R => '0'
    );
\in_data_d1_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(23),
      Q => in_data_d1(23),
      R => '0'
    );
\in_data_d1_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(24),
      Q => \^q\(0),
      R => '0'
    );
\in_data_d1_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(25),
      Q => \^q\(1),
      R => '0'
    );
\in_data_d1_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(26),
      Q => \^q\(2),
      R => '0'
    );
\in_data_d1_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(27),
      Q => \^q\(3),
      R => '0'
    );
\in_data_d1_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(28),
      Q => \^q\(4),
      R => '0'
    );
\in_data_d1_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(29),
      Q => \^q\(5),
      R => '0'
    );
\in_data_d1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(2),
      Q => in_data_d1(2),
      R => '0'
    );
\in_data_d1_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(30),
      Q => \^q\(6),
      R => '0'
    );
\in_data_d1_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(31),
      Q => \^q\(7),
      R => '0'
    );
\in_data_d1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(3),
      Q => in_data_d1(3),
      R => '0'
    );
\in_data_d1_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(4),
      Q => in_data_d1(4),
      R => '0'
    );
\in_data_d1_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(5),
      Q => in_data_d1(5),
      R => '0'
    );
\in_data_d1_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(6),
      Q => in_data_d1(6),
      R => '0'
    );
\in_data_d1_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(7),
      Q => in_data_d1(7),
      R => '0'
    );
\in_data_d1_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(8),
      Q => in_data_d1(8),
      R => '0'
    );
\in_data_d1_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(9),
      Q => in_data_d1(9),
      R => '0'
    );
\mem_reg_i_17__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(13),
      I2 => \^data_aligned_s\(14),
      I3 => D(7),
      O => data_scrambled_s(17)
    );
\mem_reg_i_18__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(13),
      I2 => \^data_aligned_s\(12),
      I3 => D(6),
      O => data_scrambled_s(16)
    );
\mem_reg_i_19__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(12),
      I2 => \^data_aligned_s\(11),
      I3 => D(5),
      O => data_scrambled_s(15)
    );
\mem_reg_i_20__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(11),
      I2 => \^data_aligned_s\(10),
      I3 => D(4),
      O => data_scrambled_s(14)
    );
\mem_reg_i_21__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(10),
      I2 => \^data_aligned_s\(9),
      I3 => D(3),
      O => data_scrambled_s(13)
    );
\mem_reg_i_22__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(9),
      I2 => \^data_aligned_s\(8),
      I3 => D(2),
      O => data_scrambled_s(12)
    );
\mem_reg_i_23__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(23),
      I2 => \^data_aligned_s\(8),
      I3 => D(1),
      O => data_scrambled_s(11)
    );
\mem_reg_i_24__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(23),
      I2 => \^data_aligned_s\(22),
      I3 => D(0),
      O => data_scrambled_s(10)
    );
\mem_reg_i_25__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(5),
      I2 => \^data_aligned_s\(23),
      I3 => \^data_aligned_s\(6),
      O => data_scrambled_s(9)
    );
\mem_reg_i_26__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(4),
      I2 => \^data_aligned_s\(5),
      I3 => \^data_aligned_s\(22),
      O => data_scrambled_s(8)
    );
\mem_reg_i_27__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(4),
      I2 => \^data_aligned_s\(3),
      I3 => \^data_aligned_s\(21),
      O => data_scrambled_s(7)
    );
\mem_reg_i_28__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(3),
      I2 => \^data_aligned_s\(2),
      I3 => \^data_aligned_s\(20),
      O => data_scrambled_s(6)
    );
\mem_reg_i_29__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(2),
      I2 => \^data_aligned_s\(1),
      I3 => \^data_aligned_s\(19),
      O => data_scrambled_s(5)
    );
\mem_reg_i_30__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(1),
      I2 => \^data_aligned_s\(0),
      I3 => \^data_aligned_s\(18),
      O => data_scrambled_s(4)
    );
\mem_reg_i_31__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(15),
      I2 => \^data_aligned_s\(0),
      I3 => \^data_aligned_s\(17),
      O => data_scrambled_s(3)
    );
\mem_reg_i_32__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(14),
      I2 => \^data_aligned_s\(15),
      I3 => \^data_aligned_s\(16),
      O => data_scrambled_s(2)
    );
\mem_reg_i_33__0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \^p_17_out\,
      O => WEBWE(0)
    );
\mem_reg_i_7__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => mem_reg(0),
      I2 => \^data_aligned_s\(9),
      I3 => \^data_aligned_s\(7),
      O => data_scrambled_s(1)
    );
\mem_reg_i_8__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(7),
      I2 => \^data_aligned_s\(8),
      I3 => \^data_aligned_s\(6),
      O => data_scrambled_s(0)
    );
\state[14]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAAAAAAAAEA"
    )
        port map (
      I0 => \wr_addr_reg[6]\,
      I1 => state,
      I2 => \state[14]_i_3__0_n_0\,
      I3 => \^data_aligned_s\(5),
      I4 => \^data_aligned_s\(6),
      I5 => \^data_aligned_s\(7),
      O => \^p_17_out\
    );
\state[14]_i_3__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_charisk_d1(2),
      I1 => \^in_charisk_d1_reg[3]_0\(0),
      I2 => in_charisk_d1(0),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_charisk_d1(1),
      O => \state[14]_i_3__0_n_0\
    );
\state_i_1__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"B"
    )
        port map (
      I0 => \^p_17_out\,
      I1 => state_reg,
      O => ifs_ready_reg
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_align_mux_8 is
  port (
    data_scrambled_s : out STD_LOGIC_VECTOR ( 17 downto 0 );
    data_aligned_s : out STD_LOGIC_VECTOR ( 23 downto 0 );
    Q : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_charisk_d1_reg[3]_0\ : out STD_LOGIC_VECTOR ( 0 to 0 );
    SS : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_valid_reg : out STD_LOGIC;
    ifs_ready_reg : out STD_LOGIC;
    WEBWE : out STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    \ilas_config_data_reg[5]\ : in STD_LOGIC;
    \ilas_config_data_reg[5]_0\ : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_data_d1_reg[31]_0\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    mem_reg : in STD_LOGIC_VECTOR ( 0 to 0 );
    state : in STD_LOGIC;
    \in_charisk_d1_reg[3]_1\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    \wr_addr_reg[0]\ : in STD_LOGIC;
    ilas_config_valid_reg_0 : in STD_LOGIC;
    ilas_config_valid_reg_1 : in STD_LOGIC;
    state_reg : in STD_LOGIC;
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_align_mux_8 : entity is "align_mux";
end jesd204_rx_0_align_mux_8;

architecture STRUCTURE of jesd204_rx_0_align_mux_8 is
  signal \^q\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \^ss\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal charisk28_aligned_s : STD_LOGIC_VECTOR ( 1 to 1 );
  signal \^data_aligned_s\ : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal \ilas_config_valid_i_3__0_n_0\ : STD_LOGIC;
  signal \ilas_config_valid_i_5__0_n_0\ : STD_LOGIC;
  signal in_charisk_d1 : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal \^in_charisk_d1_reg[3]_0\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal in_data_d1 : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal \state[14]_i_3_n_0\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \ilas_config_valid_i_3__0\ : label is "soft_lutpair44";
  attribute SOFT_HLUTNM of \ilas_config_valid_i_5__0\ : label is "soft_lutpair44";
begin
  Q(7 downto 0) <= \^q\(7 downto 0);
  SS(0) <= \^ss\(0);
  data_aligned_s(23 downto 0) <= \^data_aligned_s\(23 downto 0);
  \in_charisk_d1_reg[3]_0\(0) <= \^in_charisk_d1_reg[3]_0\(0);
\ilas_config_data[0]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(16),
      I1 => \^q\(0),
      I2 => in_data_d1(0),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(8),
      O => \^data_aligned_s\(0)
    );
\ilas_config_data[10]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(2),
      I1 => \in_data_d1_reg[31]_0\(2),
      I2 => in_data_d1(10),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(18),
      O => \^data_aligned_s\(10)
    );
\ilas_config_data[11]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(3),
      I1 => \in_data_d1_reg[31]_0\(3),
      I2 => in_data_d1(11),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(19),
      O => \^data_aligned_s\(11)
    );
\ilas_config_data[12]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(4),
      I1 => \in_data_d1_reg[31]_0\(4),
      I2 => in_data_d1(12),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(20),
      O => \^data_aligned_s\(12)
    );
\ilas_config_data[13]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(5),
      I1 => \in_data_d1_reg[31]_0\(5),
      I2 => in_data_d1(13),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(21),
      O => \^data_aligned_s\(13)
    );
\ilas_config_data[14]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(6),
      I1 => \in_data_d1_reg[31]_0\(6),
      I2 => in_data_d1(14),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(22),
      O => \^data_aligned_s\(14)
    );
\ilas_config_data[15]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(7),
      I1 => \in_data_d1_reg[31]_0\(7),
      I2 => in_data_d1(15),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(23),
      O => \^data_aligned_s\(15)
    );
\ilas_config_data[16]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(0),
      I1 => \in_data_d1_reg[31]_0\(8),
      I2 => in_data_d1(16),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(0),
      O => \^data_aligned_s\(16)
    );
\ilas_config_data[17]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(1),
      I1 => \in_data_d1_reg[31]_0\(9),
      I2 => in_data_d1(17),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(1),
      O => \^data_aligned_s\(17)
    );
\ilas_config_data[18]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(2),
      I1 => \in_data_d1_reg[31]_0\(10),
      I2 => in_data_d1(18),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(2),
      O => \^data_aligned_s\(18)
    );
\ilas_config_data[19]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(3),
      I1 => \in_data_d1_reg[31]_0\(11),
      I2 => in_data_d1(19),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(3),
      O => \^data_aligned_s\(19)
    );
\ilas_config_data[1]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(17),
      I1 => \^q\(1),
      I2 => in_data_d1(1),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(9),
      O => \^data_aligned_s\(1)
    );
\ilas_config_data[20]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(4),
      I1 => \in_data_d1_reg[31]_0\(12),
      I2 => in_data_d1(20),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(4),
      O => \^data_aligned_s\(20)
    );
\ilas_config_data[21]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(5),
      I1 => \in_data_d1_reg[31]_0\(13),
      I2 => in_data_d1(21),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(5),
      O => \^data_aligned_s\(21)
    );
\ilas_config_data[22]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(6),
      I1 => \in_data_d1_reg[31]_0\(14),
      I2 => in_data_d1(22),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(6),
      O => \^data_aligned_s\(22)
    );
\ilas_config_data[23]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \in_data_d1_reg[31]_0\(7),
      I1 => \in_data_d1_reg[31]_0\(15),
      I2 => in_data_d1(23),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => \^q\(7),
      O => \^data_aligned_s\(23)
    );
\ilas_config_data[2]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(18),
      I1 => \^q\(2),
      I2 => in_data_d1(2),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(10),
      O => \^data_aligned_s\(2)
    );
\ilas_config_data[3]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(19),
      I1 => \^q\(3),
      I2 => in_data_d1(3),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(11),
      O => \^data_aligned_s\(3)
    );
\ilas_config_data[4]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(20),
      I1 => \^q\(4),
      I2 => in_data_d1(4),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(12),
      O => \^data_aligned_s\(4)
    );
\ilas_config_data[5]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(21),
      I1 => \^q\(5),
      I2 => in_data_d1(5),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(13),
      O => \^data_aligned_s\(5)
    );
\ilas_config_data[6]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(22),
      I1 => \^q\(6),
      I2 => in_data_d1(6),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(14),
      O => \^data_aligned_s\(6)
    );
\ilas_config_data[7]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_data_d1(23),
      I1 => \^q\(7),
      I2 => in_data_d1(7),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(15),
      O => \^data_aligned_s\(7)
    );
\ilas_config_data[8]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(0),
      I1 => \in_data_d1_reg[31]_0\(0),
      I2 => in_data_d1(8),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(16),
      O => \^data_aligned_s\(8)
    );
\ilas_config_data[9]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^q\(1),
      I1 => \in_data_d1_reg[31]_0\(1),
      I2 => in_data_d1(9),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_data_d1(17),
      O => \^data_aligned_s\(9)
    );
\ilas_config_valid_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FE22022200000000"
    )
        port map (
      I0 => ilas_config_valid_reg_0,
      I1 => ilas_config_valid_reg_1,
      I2 => \ilas_config_valid_i_3__0_n_0\,
      I3 => charisk28_aligned_s(1),
      I4 => \ilas_config_valid_i_5__0_n_0\,
      I5 => state_reg,
      O => ilas_config_valid_reg
    );
\ilas_config_valid_i_3__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0400"
    )
        port map (
      I0 => \^data_aligned_s\(14),
      I1 => \^data_aligned_s\(15),
      I2 => \^data_aligned_s\(13),
      I3 => state,
      O => \ilas_config_valid_i_3__0_n_0\
    );
\ilas_config_valid_i_4__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFAACCF000AACCF0"
    )
        port map (
      I0 => \^in_charisk_d1_reg[3]_0\(0),
      I1 => in_charisk_d1(2),
      I2 => in_charisk_d1(1),
      I3 => \ilas_config_data_reg[5]_0\,
      I4 => \ilas_config_data_reg[5]\,
      I5 => \in_charisk_d1_reg[3]_1\(0),
      O => charisk28_aligned_s(1)
    );
\ilas_config_valid_i_5__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"10"
    )
        port map (
      I0 => \^data_aligned_s\(13),
      I1 => \^data_aligned_s\(14),
      I2 => \^data_aligned_s\(15),
      O => \ilas_config_valid_i_5__0_n_0\
    );
\in_charisk_d1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(0),
      Q => in_charisk_d1(0),
      R => '0'
    );
\in_charisk_d1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(1),
      Q => in_charisk_d1(1),
      R => '0'
    );
\in_charisk_d1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(2),
      Q => in_charisk_d1(2),
      R => '0'
    );
\in_charisk_d1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_charisk_d1_reg[3]_1\(3),
      Q => \^in_charisk_d1_reg[3]_0\(0),
      R => '0'
    );
\in_data_d1_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(0),
      Q => in_data_d1(0),
      R => '0'
    );
\in_data_d1_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(10),
      Q => in_data_d1(10),
      R => '0'
    );
\in_data_d1_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(11),
      Q => in_data_d1(11),
      R => '0'
    );
\in_data_d1_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(12),
      Q => in_data_d1(12),
      R => '0'
    );
\in_data_d1_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(13),
      Q => in_data_d1(13),
      R => '0'
    );
\in_data_d1_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(14),
      Q => in_data_d1(14),
      R => '0'
    );
\in_data_d1_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(15),
      Q => in_data_d1(15),
      R => '0'
    );
\in_data_d1_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(16),
      Q => in_data_d1(16),
      R => '0'
    );
\in_data_d1_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(17),
      Q => in_data_d1(17),
      R => '0'
    );
\in_data_d1_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(18),
      Q => in_data_d1(18),
      R => '0'
    );
\in_data_d1_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(19),
      Q => in_data_d1(19),
      R => '0'
    );
\in_data_d1_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(1),
      Q => in_data_d1(1),
      R => '0'
    );
\in_data_d1_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(20),
      Q => in_data_d1(20),
      R => '0'
    );
\in_data_d1_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(21),
      Q => in_data_d1(21),
      R => '0'
    );
\in_data_d1_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(22),
      Q => in_data_d1(22),
      R => '0'
    );
\in_data_d1_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(23),
      Q => in_data_d1(23),
      R => '0'
    );
\in_data_d1_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(24),
      Q => \^q\(0),
      R => '0'
    );
\in_data_d1_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(25),
      Q => \^q\(1),
      R => '0'
    );
\in_data_d1_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(26),
      Q => \^q\(2),
      R => '0'
    );
\in_data_d1_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(27),
      Q => \^q\(3),
      R => '0'
    );
\in_data_d1_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(28),
      Q => \^q\(4),
      R => '0'
    );
\in_data_d1_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(29),
      Q => \^q\(5),
      R => '0'
    );
\in_data_d1_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(2),
      Q => in_data_d1(2),
      R => '0'
    );
\in_data_d1_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(30),
      Q => \^q\(6),
      R => '0'
    );
\in_data_d1_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(31),
      Q => \^q\(7),
      R => '0'
    );
\in_data_d1_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(3),
      Q => in_data_d1(3),
      R => '0'
    );
\in_data_d1_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(4),
      Q => in_data_d1(4),
      R => '0'
    );
\in_data_d1_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(5),
      Q => in_data_d1(5),
      R => '0'
    );
\in_data_d1_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(6),
      Q => in_data_d1(6),
      R => '0'
    );
\in_data_d1_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(7),
      Q => in_data_d1(7),
      R => '0'
    );
\in_data_d1_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(8),
      Q => in_data_d1(8),
      R => '0'
    );
\in_data_d1_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_data_d1_reg[31]_0\(9),
      Q => in_data_d1(9),
      R => '0'
    );
\mem_reg_i_17__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(13),
      I2 => \^data_aligned_s\(14),
      I3 => D(7),
      O => data_scrambled_s(17)
    );
\mem_reg_i_18__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(13),
      I2 => \^data_aligned_s\(12),
      I3 => D(6),
      O => data_scrambled_s(16)
    );
\mem_reg_i_19__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(12),
      I2 => \^data_aligned_s\(11),
      I3 => D(5),
      O => data_scrambled_s(15)
    );
\mem_reg_i_20__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(11),
      I2 => \^data_aligned_s\(10),
      I3 => D(4),
      O => data_scrambled_s(14)
    );
\mem_reg_i_21__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(10),
      I2 => \^data_aligned_s\(9),
      I3 => D(3),
      O => data_scrambled_s(13)
    );
\mem_reg_i_22__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(9),
      I2 => \^data_aligned_s\(8),
      I3 => D(2),
      O => data_scrambled_s(12)
    );
\mem_reg_i_23__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(23),
      I2 => \^data_aligned_s\(8),
      I3 => D(1),
      O => data_scrambled_s(11)
    );
\mem_reg_i_24__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(23),
      I2 => \^data_aligned_s\(22),
      I3 => D(0),
      O => data_scrambled_s(10)
    );
\mem_reg_i_25__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(5),
      I2 => \^data_aligned_s\(23),
      I3 => \^data_aligned_s\(6),
      O => data_scrambled_s(9)
    );
\mem_reg_i_26__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(4),
      I2 => \^data_aligned_s\(5),
      I3 => \^data_aligned_s\(22),
      O => data_scrambled_s(8)
    );
\mem_reg_i_27__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(4),
      I2 => \^data_aligned_s\(3),
      I3 => \^data_aligned_s\(21),
      O => data_scrambled_s(7)
    );
\mem_reg_i_28__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(3),
      I2 => \^data_aligned_s\(2),
      I3 => \^data_aligned_s\(20),
      O => data_scrambled_s(6)
    );
\mem_reg_i_29__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(2),
      I2 => \^data_aligned_s\(1),
      I3 => \^data_aligned_s\(19),
      O => data_scrambled_s(5)
    );
\mem_reg_i_30__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(1),
      I2 => \^data_aligned_s\(0),
      I3 => \^data_aligned_s\(18),
      O => data_scrambled_s(4)
    );
\mem_reg_i_31__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(15),
      I2 => \^data_aligned_s\(0),
      I3 => \^data_aligned_s\(17),
      O => data_scrambled_s(3)
    );
\mem_reg_i_32__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(14),
      I2 => \^data_aligned_s\(15),
      I3 => \^data_aligned_s\(16),
      O => data_scrambled_s(2)
    );
mem_reg_i_33: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \^ss\(0),
      O => WEBWE(0)
    );
\mem_reg_i_7__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => mem_reg(0),
      I2 => \^data_aligned_s\(9),
      I3 => \^data_aligned_s\(7),
      O => data_scrambled_s(1)
    );
\mem_reg_i_8__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"E1B4"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => \^data_aligned_s\(7),
      I2 => \^data_aligned_s\(8),
      I3 => \^data_aligned_s\(6),
      O => data_scrambled_s(0)
    );
\state[14]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAAAAAAAAEA"
    )
        port map (
      I0 => \wr_addr_reg[0]\,
      I1 => state,
      I2 => \state[14]_i_3_n_0\,
      I3 => \^data_aligned_s\(5),
      I4 => \^data_aligned_s\(6),
      I5 => \^data_aligned_s\(7),
      O => \^ss\(0)
    );
\state[14]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => in_charisk_d1(2),
      I1 => \^in_charisk_d1_reg[3]_0\(0),
      I2 => in_charisk_d1(0),
      I3 => \ilas_config_data_reg[5]\,
      I4 => \ilas_config_data_reg[5]_0\,
      I5 => in_charisk_d1(1),
      O => \state[14]_i_3_n_0\
    );
state_i_1: unisim.vcomponents.LUT2
    generic map(
      INIT => X"B"
    )
        port map (
      I0 => \^ss\(0),
      I1 => state_reg,
      O => ifs_ready_reg
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_elastic_buffer is
  port (
    rx_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    buffer_release_n_reg : out STD_LOGIC;
    buffer_release_n : in STD_LOGIC;
    clk : in STD_LOGIC;
    data_scrambled_s : in STD_LOGIC_VECTOR ( 31 downto 0 );
    WEBWE : in STD_LOGIC_VECTOR ( 0 to 0 );
    SR : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_elastic_buffer : entity is "elastic_buffer";
end jesd204_rx_0_elastic_buffer;

architecture STRUCTURE of jesd204_rx_0_elastic_buffer is
  signal \^buffer_release_n_reg\ : STD_LOGIC;
  signal p_0_in : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal rd_addr : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal \rd_addr[0]_i_1_n_0\ : STD_LOGIC;
  signal \rd_addr[1]_i_1_n_0\ : STD_LOGIC;
  signal \rd_addr[2]_i_1_n_0\ : STD_LOGIC;
  signal \rd_addr[3]_i_1_n_0\ : STD_LOGIC;
  signal \rd_addr[4]_i_1_n_0\ : STD_LOGIC;
  signal \rd_addr[5]_i_1_n_0\ : STD_LOGIC;
  signal \rd_addr[6]_i_1_n_0\ : STD_LOGIC;
  signal \rd_addr[6]_i_2_n_0\ : STD_LOGIC;
  signal \wr_addr[6]_i_2__2_n_0\ : STD_LOGIC;
  signal wr_addr_reg : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal NLW_mem_reg_DOPADOP_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_mem_reg_DOPBDOP_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  attribute \MEM.PORTA.DATA_BIT_LAYOUT\ : string;
  attribute \MEM.PORTA.DATA_BIT_LAYOUT\ of mem_reg : label is "p0_d32";
  attribute \MEM.PORTB.DATA_BIT_LAYOUT\ : string;
  attribute \MEM.PORTB.DATA_BIT_LAYOUT\ of mem_reg : label is "p0_d32";
  attribute METHODOLOGY_DRC_VIOS : string;
  attribute METHODOLOGY_DRC_VIOS of mem_reg : label is "";
  attribute RTL_RAM_BITS : integer;
  attribute RTL_RAM_BITS of mem_reg : label is 4096;
  attribute RTL_RAM_NAME : string;
  attribute RTL_RAM_NAME of mem_reg : label is "mode_8b10b.gen_lane[3].i_lane/i_elastic_buffer/mem";
  attribute bram_addr_begin : integer;
  attribute bram_addr_begin of mem_reg : label is 0;
  attribute bram_addr_end : integer;
  attribute bram_addr_end of mem_reg : label is 511;
  attribute bram_slice_begin : integer;
  attribute bram_slice_begin of mem_reg : label is 0;
  attribute bram_slice_end : integer;
  attribute bram_slice_end of mem_reg : label is 31;
  attribute ram_addr_begin : integer;
  attribute ram_addr_begin of mem_reg : label is 0;
  attribute ram_addr_end : integer;
  attribute ram_addr_end of mem_reg : label is 511;
  attribute ram_offset : integer;
  attribute ram_offset of mem_reg : label is 384;
  attribute ram_slice_begin : integer;
  attribute ram_slice_begin of mem_reg : label is 0;
  attribute ram_slice_end : integer;
  attribute ram_slice_end of mem_reg : label is 31;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \rd_addr[0]_i_1\ : label is "soft_lutpair77";
  attribute SOFT_HLUTNM of \rd_addr[1]_i_1\ : label is "soft_lutpair77";
  attribute SOFT_HLUTNM of \rd_addr[2]_i_1\ : label is "soft_lutpair75";
  attribute SOFT_HLUTNM of \rd_addr[3]_i_1\ : label is "soft_lutpair75";
  attribute SOFT_HLUTNM of \rd_addr[4]_i_1\ : label is "soft_lutpair73";
  attribute SOFT_HLUTNM of \rd_addr[6]_i_2\ : label is "soft_lutpair73";
  attribute SOFT_HLUTNM of \wr_addr[0]_i_1__2\ : label is "soft_lutpair76";
  attribute SOFT_HLUTNM of \wr_addr[1]_i_1__2\ : label is "soft_lutpair76";
  attribute SOFT_HLUTNM of \wr_addr[2]_i_1__2\ : label is "soft_lutpair74";
  attribute SOFT_HLUTNM of \wr_addr[3]_i_1__2\ : label is "soft_lutpair74";
  attribute SOFT_HLUTNM of \wr_addr[4]_i_1__2\ : label is "soft_lutpair72";
  attribute SOFT_HLUTNM of \wr_addr[6]_i_2__2\ : label is "soft_lutpair72";
begin
  buffer_release_n_reg <= \^buffer_release_n_reg\;
mem_reg: unisim.vcomponents.RAMB18E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
      INIT_A => X"00000",
      INIT_B => X"00000",
      RAM_MODE => "SDP",
      RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
      READ_WIDTH_A => 36,
      READ_WIDTH_B => 0,
      RSTREG_PRIORITY_A => "RSTREG",
      RSTREG_PRIORITY_B => "RSTREG",
      SIM_COLLISION_CHECK => "ALL",
      SIM_DEVICE => "7SERIES",
      SRVAL_A => X"00000",
      SRVAL_B => X"00000",
      WRITE_MODE_A => "READ_FIRST",
      WRITE_MODE_B => "READ_FIRST",
      WRITE_WIDTH_A => 0,
      WRITE_WIDTH_B => 36
    )
        port map (
      ADDRARDADDR(13 downto 12) => B"11",
      ADDRARDADDR(11 downto 5) => rd_addr(6 downto 0),
      ADDRARDADDR(4 downto 0) => B"11111",
      ADDRBWRADDR(13 downto 12) => B"11",
      ADDRBWRADDR(11 downto 5) => wr_addr_reg(6 downto 0),
      ADDRBWRADDR(4 downto 0) => B"11111",
      CLKARDCLK => clk,
      CLKBWRCLK => clk,
      DIADI(15 downto 0) => data_scrambled_s(15 downto 0),
      DIBDI(15 downto 0) => data_scrambled_s(31 downto 16),
      DIPADIP(1 downto 0) => B"11",
      DIPBDIP(1 downto 0) => B"11",
      DOADO(15 downto 0) => rx_data(15 downto 0),
      DOBDO(15 downto 0) => rx_data(31 downto 16),
      DOPADOP(1 downto 0) => NLW_mem_reg_DOPADOP_UNCONNECTED(1 downto 0),
      DOPBDOP(1 downto 0) => NLW_mem_reg_DOPBDOP_UNCONNECTED(1 downto 0),
      ENARDEN => \^buffer_release_n_reg\,
      ENBWREN => '1',
      REGCEAREGCE => '1',
      REGCEB => '0',
      RSTRAMARSTRAM => '0',
      RSTRAMB => '0',
      RSTREGARSTREG => '0',
      RSTREGB => '0',
      WEA(1 downto 0) => B"00",
      WEBWE(3) => WEBWE(0),
      WEBWE(2) => WEBWE(0),
      WEBWE(1) => WEBWE(0),
      WEBWE(0) => WEBWE(0)
    );
\mem_reg_i_1__2\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => buffer_release_n,
      O => \^buffer_release_n_reg\
    );
\rd_addr[0]_i_1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => rd_addr(0),
      O => \rd_addr[0]_i_1_n_0\
    );
\rd_addr[1]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => rd_addr(0),
      I1 => rd_addr(1),
      O => \rd_addr[1]_i_1_n_0\
    );
\rd_addr[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"78"
    )
        port map (
      I0 => rd_addr(0),
      I1 => rd_addr(1),
      I2 => rd_addr(2),
      O => \rd_addr[2]_i_1_n_0\
    );
\rd_addr[3]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7F80"
    )
        port map (
      I0 => rd_addr(1),
      I1 => rd_addr(0),
      I2 => rd_addr(2),
      I3 => rd_addr(3),
      O => \rd_addr[3]_i_1_n_0\
    );
\rd_addr[4]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFF8000"
    )
        port map (
      I0 => rd_addr(2),
      I1 => rd_addr(0),
      I2 => rd_addr(1),
      I3 => rd_addr(3),
      I4 => rd_addr(4),
      O => \rd_addr[4]_i_1_n_0\
    );
\rd_addr[5]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF80000000"
    )
        port map (
      I0 => rd_addr(4),
      I1 => rd_addr(3),
      I2 => rd_addr(1),
      I3 => rd_addr(0),
      I4 => rd_addr(2),
      I5 => rd_addr(5),
      O => \rd_addr[5]_i_1_n_0\
    );
\rd_addr[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"D2"
    )
        port map (
      I0 => rd_addr(5),
      I1 => \rd_addr[6]_i_2_n_0\,
      I2 => rd_addr(6),
      O => \rd_addr[6]_i_1_n_0\
    );
\rd_addr[6]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFFFFFF"
    )
        port map (
      I0 => rd_addr(2),
      I1 => rd_addr(0),
      I2 => rd_addr(1),
      I3 => rd_addr(3),
      I4 => rd_addr(4),
      O => \rd_addr[6]_i_2_n_0\
    );
\rd_addr_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[0]_i_1_n_0\,
      Q => rd_addr(0),
      R => buffer_release_n
    );
\rd_addr_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[1]_i_1_n_0\,
      Q => rd_addr(1),
      R => buffer_release_n
    );
\rd_addr_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[2]_i_1_n_0\,
      Q => rd_addr(2),
      R => buffer_release_n
    );
\rd_addr_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[3]_i_1_n_0\,
      Q => rd_addr(3),
      R => buffer_release_n
    );
\rd_addr_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[4]_i_1_n_0\,
      Q => rd_addr(4),
      R => buffer_release_n
    );
\rd_addr_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[5]_i_1_n_0\,
      Q => rd_addr(5),
      R => buffer_release_n
    );
\rd_addr_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[6]_i_1_n_0\,
      Q => rd_addr(6),
      R => buffer_release_n
    );
\wr_addr[0]_i_1__2\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => wr_addr_reg(0),
      O => p_0_in(0)
    );
\wr_addr[1]_i_1__2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => wr_addr_reg(0),
      I1 => wr_addr_reg(1),
      O => p_0_in(1)
    );
\wr_addr[2]_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"78"
    )
        port map (
      I0 => wr_addr_reg(0),
      I1 => wr_addr_reg(1),
      I2 => wr_addr_reg(2),
      O => p_0_in(2)
    );
\wr_addr[3]_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7F80"
    )
        port map (
      I0 => wr_addr_reg(1),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(2),
      I3 => wr_addr_reg(3),
      O => p_0_in(3)
    );
\wr_addr[4]_i_1__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFF8000"
    )
        port map (
      I0 => wr_addr_reg(2),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(3),
      I4 => wr_addr_reg(4),
      O => p_0_in(4)
    );
\wr_addr[5]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF80000000"
    )
        port map (
      I0 => wr_addr_reg(4),
      I1 => wr_addr_reg(3),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(0),
      I4 => wr_addr_reg(2),
      I5 => wr_addr_reg(5),
      O => p_0_in(5)
    );
\wr_addr[6]_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"D2"
    )
        port map (
      I0 => wr_addr_reg(5),
      I1 => \wr_addr[6]_i_2__2_n_0\,
      I2 => wr_addr_reg(6),
      O => p_0_in(6)
    );
\wr_addr[6]_i_2__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFFFFFF"
    )
        port map (
      I0 => wr_addr_reg(2),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(3),
      I4 => wr_addr_reg(4),
      O => \wr_addr[6]_i_2__2_n_0\
    );
\wr_addr_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(0),
      Q => wr_addr_reg(0),
      R => SR(0)
    );
\wr_addr_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(1),
      Q => wr_addr_reg(1),
      R => SR(0)
    );
\wr_addr_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(2),
      Q => wr_addr_reg(2),
      R => SR(0)
    );
\wr_addr_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(3),
      Q => wr_addr_reg(3),
      R => SR(0)
    );
\wr_addr_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(4),
      Q => wr_addr_reg(4),
      R => SR(0)
    );
\wr_addr_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(5),
      Q => wr_addr_reg(5),
      R => SR(0)
    );
\wr_addr_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(6),
      Q => wr_addr_reg(6),
      R => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_elastic_buffer_11 is
  port (
    rx_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    buffer_release_n : in STD_LOGIC;
    clk : in STD_LOGIC;
    mem_reg_0 : in STD_LOGIC;
    data_scrambled_s : in STD_LOGIC_VECTOR ( 31 downto 0 );
    WEBWE : in STD_LOGIC_VECTOR ( 0 to 0 );
    SR : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_elastic_buffer_11 : entity is "elastic_buffer";
end jesd204_rx_0_elastic_buffer_11;

architecture STRUCTURE of jesd204_rx_0_elastic_buffer_11 is
  signal p_0_in : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal rd_addr : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal \rd_addr[0]_i_1__1_n_0\ : STD_LOGIC;
  signal \rd_addr[1]_i_1__1_n_0\ : STD_LOGIC;
  signal \rd_addr[2]_i_1__1_n_0\ : STD_LOGIC;
  signal \rd_addr[3]_i_1__1_n_0\ : STD_LOGIC;
  signal \rd_addr[4]_i_1__1_n_0\ : STD_LOGIC;
  signal \rd_addr[5]_i_1__1_n_0\ : STD_LOGIC;
  signal \rd_addr[6]_i_1__1_n_0\ : STD_LOGIC;
  signal \rd_addr[6]_i_2__1_n_0\ : STD_LOGIC;
  signal \wr_addr[6]_i_2__0_n_0\ : STD_LOGIC;
  signal wr_addr_reg : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal NLW_mem_reg_DOPADOP_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_mem_reg_DOPBDOP_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  attribute \MEM.PORTA.DATA_BIT_LAYOUT\ : string;
  attribute \MEM.PORTA.DATA_BIT_LAYOUT\ of mem_reg : label is "p0_d32";
  attribute \MEM.PORTB.DATA_BIT_LAYOUT\ : string;
  attribute \MEM.PORTB.DATA_BIT_LAYOUT\ of mem_reg : label is "p0_d32";
  attribute METHODOLOGY_DRC_VIOS : string;
  attribute METHODOLOGY_DRC_VIOS of mem_reg : label is "";
  attribute RTL_RAM_BITS : integer;
  attribute RTL_RAM_BITS of mem_reg : label is 4096;
  attribute RTL_RAM_NAME : string;
  attribute RTL_RAM_NAME of mem_reg : label is "mode_8b10b.gen_lane[1].i_lane/i_elastic_buffer/mem";
  attribute bram_addr_begin : integer;
  attribute bram_addr_begin of mem_reg : label is 0;
  attribute bram_addr_end : integer;
  attribute bram_addr_end of mem_reg : label is 511;
  attribute bram_slice_begin : integer;
  attribute bram_slice_begin of mem_reg : label is 0;
  attribute bram_slice_end : integer;
  attribute bram_slice_end of mem_reg : label is 31;
  attribute ram_addr_begin : integer;
  attribute ram_addr_begin of mem_reg : label is 0;
  attribute ram_addr_end : integer;
  attribute ram_addr_end of mem_reg : label is 511;
  attribute ram_offset : integer;
  attribute ram_offset of mem_reg : label is 384;
  attribute ram_slice_begin : integer;
  attribute ram_slice_begin of mem_reg : label is 0;
  attribute ram_slice_end : integer;
  attribute ram_slice_end of mem_reg : label is 31;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \rd_addr[0]_i_1__1\ : label is "soft_lutpair52";
  attribute SOFT_HLUTNM of \rd_addr[1]_i_1__1\ : label is "soft_lutpair52";
  attribute SOFT_HLUTNM of \rd_addr[2]_i_1__1\ : label is "soft_lutpair50";
  attribute SOFT_HLUTNM of \rd_addr[3]_i_1__1\ : label is "soft_lutpair50";
  attribute SOFT_HLUTNM of \rd_addr[4]_i_1__1\ : label is "soft_lutpair48";
  attribute SOFT_HLUTNM of \rd_addr[6]_i_2__1\ : label is "soft_lutpair48";
  attribute SOFT_HLUTNM of \wr_addr[0]_i_1__0\ : label is "soft_lutpair51";
  attribute SOFT_HLUTNM of \wr_addr[1]_i_1__0\ : label is "soft_lutpair51";
  attribute SOFT_HLUTNM of \wr_addr[2]_i_1__0\ : label is "soft_lutpair49";
  attribute SOFT_HLUTNM of \wr_addr[3]_i_1__0\ : label is "soft_lutpair49";
  attribute SOFT_HLUTNM of \wr_addr[4]_i_1__0\ : label is "soft_lutpair47";
  attribute SOFT_HLUTNM of \wr_addr[6]_i_2__0\ : label is "soft_lutpair47";
begin
mem_reg: unisim.vcomponents.RAMB18E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
      INIT_A => X"00000",
      INIT_B => X"00000",
      RAM_MODE => "SDP",
      RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
      READ_WIDTH_A => 36,
      READ_WIDTH_B => 0,
      RSTREG_PRIORITY_A => "RSTREG",
      RSTREG_PRIORITY_B => "RSTREG",
      SIM_COLLISION_CHECK => "ALL",
      SIM_DEVICE => "7SERIES",
      SRVAL_A => X"00000",
      SRVAL_B => X"00000",
      WRITE_MODE_A => "READ_FIRST",
      WRITE_MODE_B => "READ_FIRST",
      WRITE_WIDTH_A => 0,
      WRITE_WIDTH_B => 36
    )
        port map (
      ADDRARDADDR(13 downto 12) => B"11",
      ADDRARDADDR(11 downto 5) => rd_addr(6 downto 0),
      ADDRARDADDR(4 downto 0) => B"11111",
      ADDRBWRADDR(13 downto 12) => B"11",
      ADDRBWRADDR(11 downto 5) => wr_addr_reg(6 downto 0),
      ADDRBWRADDR(4 downto 0) => B"11111",
      CLKARDCLK => clk,
      CLKBWRCLK => clk,
      DIADI(15 downto 0) => data_scrambled_s(15 downto 0),
      DIBDI(15 downto 0) => data_scrambled_s(31 downto 16),
      DIPADIP(1 downto 0) => B"11",
      DIPBDIP(1 downto 0) => B"11",
      DOADO(15 downto 0) => rx_data(15 downto 0),
      DOBDO(15 downto 0) => rx_data(31 downto 16),
      DOPADOP(1 downto 0) => NLW_mem_reg_DOPADOP_UNCONNECTED(1 downto 0),
      DOPBDOP(1 downto 0) => NLW_mem_reg_DOPBDOP_UNCONNECTED(1 downto 0),
      ENARDEN => mem_reg_0,
      ENBWREN => '1',
      REGCEAREGCE => '1',
      REGCEB => '0',
      RSTRAMARSTRAM => '0',
      RSTRAMB => '0',
      RSTREGARSTREG => '0',
      RSTREGB => '0',
      WEA(1 downto 0) => B"00",
      WEBWE(3) => WEBWE(0),
      WEBWE(2) => WEBWE(0),
      WEBWE(1) => WEBWE(0),
      WEBWE(0) => WEBWE(0)
    );
\rd_addr[0]_i_1__1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => rd_addr(0),
      O => \rd_addr[0]_i_1__1_n_0\
    );
\rd_addr[1]_i_1__1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => rd_addr(0),
      I1 => rd_addr(1),
      O => \rd_addr[1]_i_1__1_n_0\
    );
\rd_addr[2]_i_1__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"78"
    )
        port map (
      I0 => rd_addr(0),
      I1 => rd_addr(1),
      I2 => rd_addr(2),
      O => \rd_addr[2]_i_1__1_n_0\
    );
\rd_addr[3]_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7F80"
    )
        port map (
      I0 => rd_addr(1),
      I1 => rd_addr(0),
      I2 => rd_addr(2),
      I3 => rd_addr(3),
      O => \rd_addr[3]_i_1__1_n_0\
    );
\rd_addr[4]_i_1__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFF8000"
    )
        port map (
      I0 => rd_addr(2),
      I1 => rd_addr(0),
      I2 => rd_addr(1),
      I3 => rd_addr(3),
      I4 => rd_addr(4),
      O => \rd_addr[4]_i_1__1_n_0\
    );
\rd_addr[5]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF80000000"
    )
        port map (
      I0 => rd_addr(4),
      I1 => rd_addr(3),
      I2 => rd_addr(1),
      I3 => rd_addr(0),
      I4 => rd_addr(2),
      I5 => rd_addr(5),
      O => \rd_addr[5]_i_1__1_n_0\
    );
\rd_addr[6]_i_1__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"D2"
    )
        port map (
      I0 => rd_addr(5),
      I1 => \rd_addr[6]_i_2__1_n_0\,
      I2 => rd_addr(6),
      O => \rd_addr[6]_i_1__1_n_0\
    );
\rd_addr[6]_i_2__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFFFFFF"
    )
        port map (
      I0 => rd_addr(2),
      I1 => rd_addr(0),
      I2 => rd_addr(1),
      I3 => rd_addr(3),
      I4 => rd_addr(4),
      O => \rd_addr[6]_i_2__1_n_0\
    );
\rd_addr_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[0]_i_1__1_n_0\,
      Q => rd_addr(0),
      R => buffer_release_n
    );
\rd_addr_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[1]_i_1__1_n_0\,
      Q => rd_addr(1),
      R => buffer_release_n
    );
\rd_addr_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[2]_i_1__1_n_0\,
      Q => rd_addr(2),
      R => buffer_release_n
    );
\rd_addr_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[3]_i_1__1_n_0\,
      Q => rd_addr(3),
      R => buffer_release_n
    );
\rd_addr_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[4]_i_1__1_n_0\,
      Q => rd_addr(4),
      R => buffer_release_n
    );
\rd_addr_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[5]_i_1__1_n_0\,
      Q => rd_addr(5),
      R => buffer_release_n
    );
\rd_addr_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[6]_i_1__1_n_0\,
      Q => rd_addr(6),
      R => buffer_release_n
    );
\wr_addr[0]_i_1__0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => wr_addr_reg(0),
      O => p_0_in(0)
    );
\wr_addr[1]_i_1__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => wr_addr_reg(0),
      I1 => wr_addr_reg(1),
      O => p_0_in(1)
    );
\wr_addr[2]_i_1__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"78"
    )
        port map (
      I0 => wr_addr_reg(0),
      I1 => wr_addr_reg(1),
      I2 => wr_addr_reg(2),
      O => p_0_in(2)
    );
\wr_addr[3]_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7F80"
    )
        port map (
      I0 => wr_addr_reg(1),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(2),
      I3 => wr_addr_reg(3),
      O => p_0_in(3)
    );
\wr_addr[4]_i_1__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFF8000"
    )
        port map (
      I0 => wr_addr_reg(2),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(3),
      I4 => wr_addr_reg(4),
      O => p_0_in(4)
    );
\wr_addr[5]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF80000000"
    )
        port map (
      I0 => wr_addr_reg(4),
      I1 => wr_addr_reg(3),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(0),
      I4 => wr_addr_reg(2),
      I5 => wr_addr_reg(5),
      O => p_0_in(5)
    );
\wr_addr[6]_i_1__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"D2"
    )
        port map (
      I0 => wr_addr_reg(5),
      I1 => \wr_addr[6]_i_2__0_n_0\,
      I2 => wr_addr_reg(6),
      O => p_0_in(6)
    );
\wr_addr[6]_i_2__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFFFFFF"
    )
        port map (
      I0 => wr_addr_reg(2),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(3),
      I4 => wr_addr_reg(4),
      O => \wr_addr[6]_i_2__0_n_0\
    );
\wr_addr_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(0),
      Q => wr_addr_reg(0),
      R => SR(0)
    );
\wr_addr_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(1),
      Q => wr_addr_reg(1),
      R => SR(0)
    );
\wr_addr_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(2),
      Q => wr_addr_reg(2),
      R => SR(0)
    );
\wr_addr_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(3),
      Q => wr_addr_reg(3),
      R => SR(0)
    );
\wr_addr_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(4),
      Q => wr_addr_reg(4),
      R => SR(0)
    );
\wr_addr_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(5),
      Q => wr_addr_reg(5),
      R => SR(0)
    );
\wr_addr_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(6),
      Q => wr_addr_reg(6),
      R => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_elastic_buffer_16 is
  port (
    rx_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clk : in STD_LOGIC;
    mem_reg_0 : in STD_LOGIC;
    data_scrambled_s : in STD_LOGIC_VECTOR ( 31 downto 0 );
    WEBWE : in STD_LOGIC_VECTOR ( 0 to 0 );
    buffer_release_n : in STD_LOGIC;
    SR : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_elastic_buffer_16 : entity is "elastic_buffer";
end jesd204_rx_0_elastic_buffer_16;

architecture STRUCTURE of jesd204_rx_0_elastic_buffer_16 is
  signal p_0_in : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal rd_addr : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal \rd_addr[0]_i_1__2_n_0\ : STD_LOGIC;
  signal \rd_addr[1]_i_1__2_n_0\ : STD_LOGIC;
  signal \rd_addr[2]_i_1__2_n_0\ : STD_LOGIC;
  signal \rd_addr[3]_i_1__2_n_0\ : STD_LOGIC;
  signal \rd_addr[4]_i_1__2_n_0\ : STD_LOGIC;
  signal \rd_addr[5]_i_1__2_n_0\ : STD_LOGIC;
  signal \rd_addr[6]_i_1__2_n_0\ : STD_LOGIC;
  signal \rd_addr[6]_i_2__2_n_0\ : STD_LOGIC;
  signal \wr_addr[6]_i_2_n_0\ : STD_LOGIC;
  signal wr_addr_reg : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal NLW_mem_reg_DOPADOP_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_mem_reg_DOPBDOP_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  attribute \MEM.PORTA.DATA_BIT_LAYOUT\ : string;
  attribute \MEM.PORTA.DATA_BIT_LAYOUT\ of mem_reg : label is "p0_d32";
  attribute \MEM.PORTB.DATA_BIT_LAYOUT\ : string;
  attribute \MEM.PORTB.DATA_BIT_LAYOUT\ of mem_reg : label is "p0_d32";
  attribute METHODOLOGY_DRC_VIOS : string;
  attribute METHODOLOGY_DRC_VIOS of mem_reg : label is "";
  attribute RTL_RAM_BITS : integer;
  attribute RTL_RAM_BITS of mem_reg : label is 4096;
  attribute RTL_RAM_NAME : string;
  attribute RTL_RAM_NAME of mem_reg : label is "mode_8b10b.gen_lane[0].i_lane/i_elastic_buffer/mem";
  attribute bram_addr_begin : integer;
  attribute bram_addr_begin of mem_reg : label is 0;
  attribute bram_addr_end : integer;
  attribute bram_addr_end of mem_reg : label is 511;
  attribute bram_slice_begin : integer;
  attribute bram_slice_begin of mem_reg : label is 0;
  attribute bram_slice_end : integer;
  attribute bram_slice_end of mem_reg : label is 31;
  attribute ram_addr_begin : integer;
  attribute ram_addr_begin of mem_reg : label is 0;
  attribute ram_addr_end : integer;
  attribute ram_addr_end of mem_reg : label is 511;
  attribute ram_offset : integer;
  attribute ram_offset of mem_reg : label is 384;
  attribute ram_slice_begin : integer;
  attribute ram_slice_begin of mem_reg : label is 0;
  attribute ram_slice_end : integer;
  attribute ram_slice_end of mem_reg : label is 31;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \rd_addr[0]_i_1__2\ : label is "soft_lutpair41";
  attribute SOFT_HLUTNM of \rd_addr[1]_i_1__2\ : label is "soft_lutpair41";
  attribute SOFT_HLUTNM of \rd_addr[2]_i_1__2\ : label is "soft_lutpair39";
  attribute SOFT_HLUTNM of \rd_addr[3]_i_1__2\ : label is "soft_lutpair39";
  attribute SOFT_HLUTNM of \rd_addr[4]_i_1__2\ : label is "soft_lutpair37";
  attribute SOFT_HLUTNM of \rd_addr[6]_i_2__2\ : label is "soft_lutpair37";
  attribute SOFT_HLUTNM of \wr_addr[0]_i_1\ : label is "soft_lutpair40";
  attribute SOFT_HLUTNM of \wr_addr[1]_i_1\ : label is "soft_lutpair40";
  attribute SOFT_HLUTNM of \wr_addr[2]_i_1\ : label is "soft_lutpair38";
  attribute SOFT_HLUTNM of \wr_addr[3]_i_1\ : label is "soft_lutpair38";
  attribute SOFT_HLUTNM of \wr_addr[4]_i_1\ : label is "soft_lutpair36";
  attribute SOFT_HLUTNM of \wr_addr[6]_i_2\ : label is "soft_lutpair36";
begin
mem_reg: unisim.vcomponents.RAMB18E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
      INIT_A => X"00000",
      INIT_B => X"00000",
      RAM_MODE => "SDP",
      RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
      READ_WIDTH_A => 36,
      READ_WIDTH_B => 0,
      RSTREG_PRIORITY_A => "RSTREG",
      RSTREG_PRIORITY_B => "RSTREG",
      SIM_COLLISION_CHECK => "ALL",
      SIM_DEVICE => "7SERIES",
      SRVAL_A => X"00000",
      SRVAL_B => X"00000",
      WRITE_MODE_A => "READ_FIRST",
      WRITE_MODE_B => "READ_FIRST",
      WRITE_WIDTH_A => 0,
      WRITE_WIDTH_B => 36
    )
        port map (
      ADDRARDADDR(13 downto 12) => B"11",
      ADDRARDADDR(11 downto 5) => rd_addr(6 downto 0),
      ADDRARDADDR(4 downto 0) => B"11111",
      ADDRBWRADDR(13 downto 12) => B"11",
      ADDRBWRADDR(11 downto 5) => wr_addr_reg(6 downto 0),
      ADDRBWRADDR(4 downto 0) => B"11111",
      CLKARDCLK => clk,
      CLKBWRCLK => clk,
      DIADI(15 downto 0) => data_scrambled_s(15 downto 0),
      DIBDI(15 downto 0) => data_scrambled_s(31 downto 16),
      DIPADIP(1 downto 0) => B"11",
      DIPBDIP(1 downto 0) => B"11",
      DOADO(15 downto 0) => rx_data(15 downto 0),
      DOBDO(15 downto 0) => rx_data(31 downto 16),
      DOPADOP(1 downto 0) => NLW_mem_reg_DOPADOP_UNCONNECTED(1 downto 0),
      DOPBDOP(1 downto 0) => NLW_mem_reg_DOPBDOP_UNCONNECTED(1 downto 0),
      ENARDEN => mem_reg_0,
      ENBWREN => '1',
      REGCEAREGCE => '1',
      REGCEB => '0',
      RSTRAMARSTRAM => '0',
      RSTRAMB => '0',
      RSTREGARSTREG => '0',
      RSTREGB => '0',
      WEA(1 downto 0) => B"00",
      WEBWE(3) => WEBWE(0),
      WEBWE(2) => WEBWE(0),
      WEBWE(1) => WEBWE(0),
      WEBWE(0) => WEBWE(0)
    );
\rd_addr[0]_i_1__2\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => rd_addr(0),
      O => \rd_addr[0]_i_1__2_n_0\
    );
\rd_addr[1]_i_1__2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => rd_addr(0),
      I1 => rd_addr(1),
      O => \rd_addr[1]_i_1__2_n_0\
    );
\rd_addr[2]_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"78"
    )
        port map (
      I0 => rd_addr(0),
      I1 => rd_addr(1),
      I2 => rd_addr(2),
      O => \rd_addr[2]_i_1__2_n_0\
    );
\rd_addr[3]_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7F80"
    )
        port map (
      I0 => rd_addr(1),
      I1 => rd_addr(0),
      I2 => rd_addr(2),
      I3 => rd_addr(3),
      O => \rd_addr[3]_i_1__2_n_0\
    );
\rd_addr[4]_i_1__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFF8000"
    )
        port map (
      I0 => rd_addr(2),
      I1 => rd_addr(0),
      I2 => rd_addr(1),
      I3 => rd_addr(3),
      I4 => rd_addr(4),
      O => \rd_addr[4]_i_1__2_n_0\
    );
\rd_addr[5]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF80000000"
    )
        port map (
      I0 => rd_addr(4),
      I1 => rd_addr(3),
      I2 => rd_addr(1),
      I3 => rd_addr(0),
      I4 => rd_addr(2),
      I5 => rd_addr(5),
      O => \rd_addr[5]_i_1__2_n_0\
    );
\rd_addr[6]_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"D2"
    )
        port map (
      I0 => rd_addr(5),
      I1 => \rd_addr[6]_i_2__2_n_0\,
      I2 => rd_addr(6),
      O => \rd_addr[6]_i_1__2_n_0\
    );
\rd_addr[6]_i_2__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFFFFFF"
    )
        port map (
      I0 => rd_addr(2),
      I1 => rd_addr(0),
      I2 => rd_addr(1),
      I3 => rd_addr(3),
      I4 => rd_addr(4),
      O => \rd_addr[6]_i_2__2_n_0\
    );
\rd_addr_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[0]_i_1__2_n_0\,
      Q => rd_addr(0),
      R => buffer_release_n
    );
\rd_addr_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[1]_i_1__2_n_0\,
      Q => rd_addr(1),
      R => buffer_release_n
    );
\rd_addr_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[2]_i_1__2_n_0\,
      Q => rd_addr(2),
      R => buffer_release_n
    );
\rd_addr_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[3]_i_1__2_n_0\,
      Q => rd_addr(3),
      R => buffer_release_n
    );
\rd_addr_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[4]_i_1__2_n_0\,
      Q => rd_addr(4),
      R => buffer_release_n
    );
\rd_addr_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[5]_i_1__2_n_0\,
      Q => rd_addr(5),
      R => buffer_release_n
    );
\rd_addr_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[6]_i_1__2_n_0\,
      Q => rd_addr(6),
      R => buffer_release_n
    );
\wr_addr[0]_i_1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => wr_addr_reg(0),
      O => p_0_in(0)
    );
\wr_addr[1]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => wr_addr_reg(0),
      I1 => wr_addr_reg(1),
      O => p_0_in(1)
    );
\wr_addr[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"78"
    )
        port map (
      I0 => wr_addr_reg(0),
      I1 => wr_addr_reg(1),
      I2 => wr_addr_reg(2),
      O => p_0_in(2)
    );
\wr_addr[3]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7F80"
    )
        port map (
      I0 => wr_addr_reg(1),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(2),
      I3 => wr_addr_reg(3),
      O => p_0_in(3)
    );
\wr_addr[4]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFF8000"
    )
        port map (
      I0 => wr_addr_reg(2),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(3),
      I4 => wr_addr_reg(4),
      O => p_0_in(4)
    );
\wr_addr[5]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF80000000"
    )
        port map (
      I0 => wr_addr_reg(4),
      I1 => wr_addr_reg(3),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(0),
      I4 => wr_addr_reg(2),
      I5 => wr_addr_reg(5),
      O => p_0_in(5)
    );
\wr_addr[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"D2"
    )
        port map (
      I0 => wr_addr_reg(5),
      I1 => \wr_addr[6]_i_2_n_0\,
      I2 => wr_addr_reg(6),
      O => p_0_in(6)
    );
\wr_addr[6]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFFFFFF"
    )
        port map (
      I0 => wr_addr_reg(2),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(3),
      I4 => wr_addr_reg(4),
      O => \wr_addr[6]_i_2_n_0\
    );
\wr_addr_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(0),
      Q => wr_addr_reg(0),
      R => SR(0)
    );
\wr_addr_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(1),
      Q => wr_addr_reg(1),
      R => SR(0)
    );
\wr_addr_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(2),
      Q => wr_addr_reg(2),
      R => SR(0)
    );
\wr_addr_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(3),
      Q => wr_addr_reg(3),
      R => SR(0)
    );
\wr_addr_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(4),
      Q => wr_addr_reg(4),
      R => SR(0)
    );
\wr_addr_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(5),
      Q => wr_addr_reg(5),
      R => SR(0)
    );
\wr_addr_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(6),
      Q => wr_addr_reg(6),
      R => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_elastic_buffer_6 is
  port (
    rx_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    buffer_release_n : in STD_LOGIC;
    clk : in STD_LOGIC;
    mem_reg_0 : in STD_LOGIC;
    data_scrambled_s : in STD_LOGIC_VECTOR ( 31 downto 0 );
    WEBWE : in STD_LOGIC_VECTOR ( 0 to 0 );
    SR : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_elastic_buffer_6 : entity is "elastic_buffer";
end jesd204_rx_0_elastic_buffer_6;

architecture STRUCTURE of jesd204_rx_0_elastic_buffer_6 is
  signal p_0_in : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal rd_addr : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal \rd_addr[0]_i_1__0_n_0\ : STD_LOGIC;
  signal \rd_addr[1]_i_1__0_n_0\ : STD_LOGIC;
  signal \rd_addr[2]_i_1__0_n_0\ : STD_LOGIC;
  signal \rd_addr[3]_i_1__0_n_0\ : STD_LOGIC;
  signal \rd_addr[4]_i_1__0_n_0\ : STD_LOGIC;
  signal \rd_addr[5]_i_1__0_n_0\ : STD_LOGIC;
  signal \rd_addr[6]_i_1__0_n_0\ : STD_LOGIC;
  signal \rd_addr[6]_i_2__0_n_0\ : STD_LOGIC;
  signal \wr_addr[6]_i_2__1_n_0\ : STD_LOGIC;
  signal wr_addr_reg : STD_LOGIC_VECTOR ( 6 downto 0 );
  signal NLW_mem_reg_DOPADOP_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_mem_reg_DOPBDOP_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  attribute \MEM.PORTA.DATA_BIT_LAYOUT\ : string;
  attribute \MEM.PORTA.DATA_BIT_LAYOUT\ of mem_reg : label is "p0_d32";
  attribute \MEM.PORTB.DATA_BIT_LAYOUT\ : string;
  attribute \MEM.PORTB.DATA_BIT_LAYOUT\ of mem_reg : label is "p0_d32";
  attribute METHODOLOGY_DRC_VIOS : string;
  attribute METHODOLOGY_DRC_VIOS of mem_reg : label is "";
  attribute RTL_RAM_BITS : integer;
  attribute RTL_RAM_BITS of mem_reg : label is 4096;
  attribute RTL_RAM_NAME : string;
  attribute RTL_RAM_NAME of mem_reg : label is "mode_8b10b.gen_lane[2].i_lane/i_elastic_buffer/mem";
  attribute bram_addr_begin : integer;
  attribute bram_addr_begin of mem_reg : label is 0;
  attribute bram_addr_end : integer;
  attribute bram_addr_end of mem_reg : label is 511;
  attribute bram_slice_begin : integer;
  attribute bram_slice_begin of mem_reg : label is 0;
  attribute bram_slice_end : integer;
  attribute bram_slice_end of mem_reg : label is 31;
  attribute ram_addr_begin : integer;
  attribute ram_addr_begin of mem_reg : label is 0;
  attribute ram_addr_end : integer;
  attribute ram_addr_end of mem_reg : label is 511;
  attribute ram_offset : integer;
  attribute ram_offset of mem_reg : label is 384;
  attribute ram_slice_begin : integer;
  attribute ram_slice_begin of mem_reg : label is 0;
  attribute ram_slice_end : integer;
  attribute ram_slice_end of mem_reg : label is 31;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \rd_addr[0]_i_1__0\ : label is "soft_lutpair65";
  attribute SOFT_HLUTNM of \rd_addr[1]_i_1__0\ : label is "soft_lutpair65";
  attribute SOFT_HLUTNM of \rd_addr[2]_i_1__0\ : label is "soft_lutpair63";
  attribute SOFT_HLUTNM of \rd_addr[3]_i_1__0\ : label is "soft_lutpair63";
  attribute SOFT_HLUTNM of \rd_addr[4]_i_1__0\ : label is "soft_lutpair61";
  attribute SOFT_HLUTNM of \rd_addr[6]_i_2__0\ : label is "soft_lutpair61";
  attribute SOFT_HLUTNM of \wr_addr[0]_i_1__1\ : label is "soft_lutpair64";
  attribute SOFT_HLUTNM of \wr_addr[1]_i_1__1\ : label is "soft_lutpair64";
  attribute SOFT_HLUTNM of \wr_addr[2]_i_1__1\ : label is "soft_lutpair62";
  attribute SOFT_HLUTNM of \wr_addr[3]_i_1__1\ : label is "soft_lutpair62";
  attribute SOFT_HLUTNM of \wr_addr[4]_i_1__1\ : label is "soft_lutpair60";
  attribute SOFT_HLUTNM of \wr_addr[6]_i_2__1\ : label is "soft_lutpair60";
begin
mem_reg: unisim.vcomponents.RAMB18E1
    generic map(
      DOA_REG => 1,
      DOB_REG => 1,
      INIT_A => X"00000",
      INIT_B => X"00000",
      RAM_MODE => "SDP",
      RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
      READ_WIDTH_A => 36,
      READ_WIDTH_B => 0,
      RSTREG_PRIORITY_A => "RSTREG",
      RSTREG_PRIORITY_B => "RSTREG",
      SIM_COLLISION_CHECK => "ALL",
      SIM_DEVICE => "7SERIES",
      SRVAL_A => X"00000",
      SRVAL_B => X"00000",
      WRITE_MODE_A => "READ_FIRST",
      WRITE_MODE_B => "READ_FIRST",
      WRITE_WIDTH_A => 0,
      WRITE_WIDTH_B => 36
    )
        port map (
      ADDRARDADDR(13 downto 12) => B"11",
      ADDRARDADDR(11 downto 5) => rd_addr(6 downto 0),
      ADDRARDADDR(4 downto 0) => B"11111",
      ADDRBWRADDR(13 downto 12) => B"11",
      ADDRBWRADDR(11 downto 5) => wr_addr_reg(6 downto 0),
      ADDRBWRADDR(4 downto 0) => B"11111",
      CLKARDCLK => clk,
      CLKBWRCLK => clk,
      DIADI(15 downto 0) => data_scrambled_s(15 downto 0),
      DIBDI(15 downto 0) => data_scrambled_s(31 downto 16),
      DIPADIP(1 downto 0) => B"11",
      DIPBDIP(1 downto 0) => B"11",
      DOADO(15 downto 0) => rx_data(15 downto 0),
      DOBDO(15 downto 0) => rx_data(31 downto 16),
      DOPADOP(1 downto 0) => NLW_mem_reg_DOPADOP_UNCONNECTED(1 downto 0),
      DOPBDOP(1 downto 0) => NLW_mem_reg_DOPBDOP_UNCONNECTED(1 downto 0),
      ENARDEN => mem_reg_0,
      ENBWREN => '1',
      REGCEAREGCE => '1',
      REGCEB => '0',
      RSTRAMARSTRAM => '0',
      RSTRAMB => '0',
      RSTREGARSTREG => '0',
      RSTREGB => '0',
      WEA(1 downto 0) => B"00",
      WEBWE(3) => WEBWE(0),
      WEBWE(2) => WEBWE(0),
      WEBWE(1) => WEBWE(0),
      WEBWE(0) => WEBWE(0)
    );
\rd_addr[0]_i_1__0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => rd_addr(0),
      O => \rd_addr[0]_i_1__0_n_0\
    );
\rd_addr[1]_i_1__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => rd_addr(0),
      I1 => rd_addr(1),
      O => \rd_addr[1]_i_1__0_n_0\
    );
\rd_addr[2]_i_1__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"78"
    )
        port map (
      I0 => rd_addr(0),
      I1 => rd_addr(1),
      I2 => rd_addr(2),
      O => \rd_addr[2]_i_1__0_n_0\
    );
\rd_addr[3]_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7F80"
    )
        port map (
      I0 => rd_addr(1),
      I1 => rd_addr(0),
      I2 => rd_addr(2),
      I3 => rd_addr(3),
      O => \rd_addr[3]_i_1__0_n_0\
    );
\rd_addr[4]_i_1__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFF8000"
    )
        port map (
      I0 => rd_addr(2),
      I1 => rd_addr(0),
      I2 => rd_addr(1),
      I3 => rd_addr(3),
      I4 => rd_addr(4),
      O => \rd_addr[4]_i_1__0_n_0\
    );
\rd_addr[5]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF80000000"
    )
        port map (
      I0 => rd_addr(4),
      I1 => rd_addr(3),
      I2 => rd_addr(1),
      I3 => rd_addr(0),
      I4 => rd_addr(2),
      I5 => rd_addr(5),
      O => \rd_addr[5]_i_1__0_n_0\
    );
\rd_addr[6]_i_1__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"D2"
    )
        port map (
      I0 => rd_addr(5),
      I1 => \rd_addr[6]_i_2__0_n_0\,
      I2 => rd_addr(6),
      O => \rd_addr[6]_i_1__0_n_0\
    );
\rd_addr[6]_i_2__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFFFFFF"
    )
        port map (
      I0 => rd_addr(2),
      I1 => rd_addr(0),
      I2 => rd_addr(1),
      I3 => rd_addr(3),
      I4 => rd_addr(4),
      O => \rd_addr[6]_i_2__0_n_0\
    );
\rd_addr_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[0]_i_1__0_n_0\,
      Q => rd_addr(0),
      R => buffer_release_n
    );
\rd_addr_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[1]_i_1__0_n_0\,
      Q => rd_addr(1),
      R => buffer_release_n
    );
\rd_addr_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[2]_i_1__0_n_0\,
      Q => rd_addr(2),
      R => buffer_release_n
    );
\rd_addr_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[3]_i_1__0_n_0\,
      Q => rd_addr(3),
      R => buffer_release_n
    );
\rd_addr_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[4]_i_1__0_n_0\,
      Q => rd_addr(4),
      R => buffer_release_n
    );
\rd_addr_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[5]_i_1__0_n_0\,
      Q => rd_addr(5),
      R => buffer_release_n
    );
\rd_addr_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rd_addr[6]_i_1__0_n_0\,
      Q => rd_addr(6),
      R => buffer_release_n
    );
\wr_addr[0]_i_1__1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => wr_addr_reg(0),
      O => p_0_in(0)
    );
\wr_addr[1]_i_1__1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => wr_addr_reg(0),
      I1 => wr_addr_reg(1),
      O => p_0_in(1)
    );
\wr_addr[2]_i_1__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"78"
    )
        port map (
      I0 => wr_addr_reg(0),
      I1 => wr_addr_reg(1),
      I2 => wr_addr_reg(2),
      O => p_0_in(2)
    );
\wr_addr[3]_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7F80"
    )
        port map (
      I0 => wr_addr_reg(1),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(2),
      I3 => wr_addr_reg(3),
      O => p_0_in(3)
    );
\wr_addr[4]_i_1__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFF8000"
    )
        port map (
      I0 => wr_addr_reg(2),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(3),
      I4 => wr_addr_reg(4),
      O => p_0_in(4)
    );
\wr_addr[5]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFF80000000"
    )
        port map (
      I0 => wr_addr_reg(4),
      I1 => wr_addr_reg(3),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(0),
      I4 => wr_addr_reg(2),
      I5 => wr_addr_reg(5),
      O => p_0_in(5)
    );
\wr_addr[6]_i_1__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"D2"
    )
        port map (
      I0 => wr_addr_reg(5),
      I1 => \wr_addr[6]_i_2__1_n_0\,
      I2 => wr_addr_reg(6),
      O => p_0_in(6)
    );
\wr_addr[6]_i_2__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7FFFFFFF"
    )
        port map (
      I0 => wr_addr_reg(2),
      I1 => wr_addr_reg(0),
      I2 => wr_addr_reg(1),
      I3 => wr_addr_reg(3),
      I4 => wr_addr_reg(4),
      O => \wr_addr[6]_i_2__1_n_0\
    );
\wr_addr_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(0),
      Q => wr_addr_reg(0),
      R => SR(0)
    );
\wr_addr_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(1),
      Q => wr_addr_reg(1),
      R => SR(0)
    );
\wr_addr_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(2),
      Q => wr_addr_reg(2),
      R => SR(0)
    );
\wr_addr_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(3),
      Q => wr_addr_reg(3),
      R => SR(0)
    );
\wr_addr_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(4),
      Q => wr_addr_reg(4),
      R => SR(0)
    );
\wr_addr_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(5),
      Q => wr_addr_reg(5),
      R => SR(0)
    );
\wr_addr_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => p_0_in(6),
      Q => wr_addr_reg(6),
      R => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_eof_generator is
  port (
    rx_sof : out STD_LOGIC_VECTOR ( 2 downto 0 );
    rx_eof : out STD_LOGIC_VECTOR ( 0 to 0 );
    eof_reset : in STD_LOGIC;
    clk : in STD_LOGIC;
    cfg_octets_per_frame : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_eof_generator : entity is "jesd204_eof_generator";
end jesd204_rx_0_jesd204_eof_generator;

architecture STRUCTURE of jesd204_rx_0_jesd204_eof_generator is
  signal beat_counter : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \beat_counter[0]_i_1_n_0\ : STD_LOGIC;
  signal \beat_counter[1]_i_1_n_0\ : STD_LOGIC;
  signal \eof[1]_i_1_n_0\ : STD_LOGIC;
  signal \eof[2]_i_1_n_0\ : STD_LOGIC;
  signal p_0_in : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \sof[0]_i_1_n_0\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \beat_counter[0]_i_1\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of \beat_counter[1]_i_1\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of beat_counter_eof : label is "soft_lutpair1";
  attribute SOFT_HLUTNM of \eof[1]_i_1\ : label is "soft_lutpair2";
  attribute SOFT_HLUTNM of \eof[2]_i_1\ : label is "soft_lutpair2";
  attribute SOFT_HLUTNM of \sof[0]_i_1\ : label is "soft_lutpair1";
begin
\beat_counter[0]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00004554"
    )
        port map (
      I0 => beat_counter(0),
      I1 => cfg_octets_per_frame(2),
      I2 => beat_counter(1),
      I3 => cfg_octets_per_frame(3),
      I4 => eof_reset,
      O => \beat_counter[0]_i_1_n_0\
    );
\beat_counter[1]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00004A52"
    )
        port map (
      I0 => beat_counter(0),
      I1 => cfg_octets_per_frame(2),
      I2 => beat_counter(1),
      I3 => cfg_octets_per_frame(3),
      I4 => eof_reset,
      O => \beat_counter[1]_i_1_n_0\
    );
beat_counter_eof: unisim.vcomponents.LUT4
    generic map(
      INIT => X"9009"
    )
        port map (
      I0 => beat_counter(0),
      I1 => cfg_octets_per_frame(2),
      I2 => beat_counter(1),
      I3 => cfg_octets_per_frame(3),
      O => p_0_in(3)
    );
\beat_counter_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_counter[0]_i_1_n_0\,
      Q => beat_counter(0),
      R => '0'
    );
\beat_counter_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_counter[1]_i_1_n_0\,
      Q => beat_counter(1),
      R => '0'
    );
\eof[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"01"
    )
        port map (
      I0 => cfg_octets_per_frame(2),
      I1 => cfg_octets_per_frame(3),
      I2 => cfg_octets_per_frame(1),
      O => \eof[1]_i_1_n_0\
    );
\eof[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"01"
    )
        port map (
      I0 => cfg_octets_per_frame(2),
      I1 => cfg_octets_per_frame(3),
      I2 => cfg_octets_per_frame(0),
      O => \eof[2]_i_1_n_0\
    );
\eof_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \eof[1]_i_1_n_0\,
      Q => rx_sof(1),
      R => eof_reset
    );
\eof_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \eof[2]_i_1_n_0\,
      Q => rx_sof(2),
      R => eof_reset
    );
\eof_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(3),
      Q => rx_eof(0),
      R => eof_reset
    );
\sof[0]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => beat_counter(1),
      I1 => beat_counter(0),
      O => \sof[0]_i_1_n_0\
    );
\sof_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \sof[0]_i_1_n_0\,
      Q => rx_sof(0),
      R => eof_reset
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_ilas_monitor is
  port (
    ilas_config_valid_reg_0 : out STD_LOGIC;
    state : out STD_LOGIC;
    prev_was_last_reg_0 : out STD_LOGIC;
    \ilas_config_addr_reg[1]_0\ : out STD_LOGIC;
    ilas_config_addr : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    prev_was_last0 : in STD_LOGIC;
    clk : in STD_LOGIC;
    ilas_config_valid_reg_1 : in STD_LOGIC;
    state_reg_0 : in STD_LOGIC;
    \wr_addr_reg[0]\ : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_ilas_monitor : entity is "jesd204_ilas_monitor";
end jesd204_rx_0_jesd204_ilas_monitor;

architecture STRUCTURE of jesd204_rx_0_jesd204_ilas_monitor is
  signal \^ilas_config_addr\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \ilas_config_addr[0]_i_1__2_n_0\ : STD_LOGIC;
  signal \ilas_config_addr[1]_i_1__2_n_0\ : STD_LOGIC;
  signal \^ilas_config_valid_reg_0\ : STD_LOGIC;
  signal prev_was_last : STD_LOGIC;
  signal \^state\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \ilas_config_addr[0]_i_1__2\ : label is "soft_lutpair79";
  attribute SOFT_HLUTNM of \ilas_config_addr[1]_i_1__2\ : label is "soft_lutpair79";
  attribute SOFT_HLUTNM of \ilas_config_valid_i_2__2\ : label is "soft_lutpair78";
  attribute SOFT_HLUTNM of \state[14]_i_2__1\ : label is "soft_lutpair78";
begin
  ilas_config_addr(1 downto 0) <= \^ilas_config_addr\(1 downto 0);
  ilas_config_valid_reg_0 <= \^ilas_config_valid_reg_0\;
  state <= \^state\;
\ilas_config_addr[0]_i_1__2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"4"
    )
        port map (
      I0 => \^ilas_config_addr\(0),
      I1 => \^ilas_config_valid_reg_0\,
      O => \ilas_config_addr[0]_i_1__2_n_0\
    );
\ilas_config_addr[1]_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"60"
    )
        port map (
      I0 => \^ilas_config_addr\(1),
      I1 => \^ilas_config_addr\(0),
      I2 => \^ilas_config_valid_reg_0\,
      O => \ilas_config_addr[1]_i_1__2_n_0\
    );
\ilas_config_addr_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \ilas_config_addr[0]_i_1__2_n_0\,
      Q => \^ilas_config_addr\(0),
      R => '0'
    );
\ilas_config_addr_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \ilas_config_addr[1]_i_1__2_n_0\,
      Q => \^ilas_config_addr\(1),
      R => '0'
    );
\ilas_config_data_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(0),
      Q => ilas_config_data(0),
      R => '0'
    );
\ilas_config_data_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(10),
      Q => ilas_config_data(10),
      R => '0'
    );
\ilas_config_data_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(11),
      Q => ilas_config_data(11),
      R => '0'
    );
\ilas_config_data_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(12),
      Q => ilas_config_data(12),
      R => '0'
    );
\ilas_config_data_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(13),
      Q => ilas_config_data(13),
      R => '0'
    );
\ilas_config_data_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(14),
      Q => ilas_config_data(14),
      R => '0'
    );
\ilas_config_data_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(15),
      Q => ilas_config_data(15),
      R => '0'
    );
\ilas_config_data_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(16),
      Q => ilas_config_data(16),
      R => '0'
    );
\ilas_config_data_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(17),
      Q => ilas_config_data(17),
      R => '0'
    );
\ilas_config_data_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(18),
      Q => ilas_config_data(18),
      R => '0'
    );
\ilas_config_data_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(19),
      Q => ilas_config_data(19),
      R => '0'
    );
\ilas_config_data_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(1),
      Q => ilas_config_data(1),
      R => '0'
    );
\ilas_config_data_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(20),
      Q => ilas_config_data(20),
      R => '0'
    );
\ilas_config_data_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(21),
      Q => ilas_config_data(21),
      R => '0'
    );
\ilas_config_data_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(22),
      Q => ilas_config_data(22),
      R => '0'
    );
\ilas_config_data_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(23),
      Q => ilas_config_data(23),
      R => '0'
    );
\ilas_config_data_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(24),
      Q => ilas_config_data(24),
      R => '0'
    );
\ilas_config_data_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(25),
      Q => ilas_config_data(25),
      R => '0'
    );
\ilas_config_data_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(26),
      Q => ilas_config_data(26),
      R => '0'
    );
\ilas_config_data_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(27),
      Q => ilas_config_data(27),
      R => '0'
    );
\ilas_config_data_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(28),
      Q => ilas_config_data(28),
      R => '0'
    );
\ilas_config_data_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(29),
      Q => ilas_config_data(29),
      R => '0'
    );
\ilas_config_data_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(2),
      Q => ilas_config_data(2),
      R => '0'
    );
\ilas_config_data_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(30),
      Q => ilas_config_data(30),
      R => '0'
    );
\ilas_config_data_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(31),
      Q => ilas_config_data(31),
      R => '0'
    );
\ilas_config_data_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(3),
      Q => ilas_config_data(3),
      R => '0'
    );
\ilas_config_data_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(4),
      Q => ilas_config_data(4),
      R => '0'
    );
\ilas_config_data_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(5),
      Q => ilas_config_data(5),
      R => '0'
    );
\ilas_config_data_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(6),
      Q => ilas_config_data(6),
      R => '0'
    );
\ilas_config_data_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(7),
      Q => ilas_config_data(7),
      R => '0'
    );
\ilas_config_data_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(8),
      Q => ilas_config_data(8),
      R => '0'
    );
\ilas_config_data_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(9),
      Q => ilas_config_data(9),
      R => '0'
    );
\ilas_config_valid_i_2__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \^ilas_config_addr\(1),
      I1 => \^ilas_config_addr\(0),
      I2 => \^state\,
      O => \ilas_config_addr_reg[1]_0\
    );
ilas_config_valid_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => ilas_config_valid_reg_1,
      Q => \^ilas_config_valid_reg_0\,
      R => '0'
    );
prev_was_last_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => prev_was_last0,
      Q => prev_was_last,
      R => '0'
    );
\state[14]_i_2__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"70"
    )
        port map (
      I0 => prev_was_last,
      I1 => \wr_addr_reg[0]\,
      I2 => \^state\,
      O => prev_was_last_reg_0
    );
state_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => state_reg_0,
      Q => \^state\,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_ilas_monitor_12 is
  port (
    ilas_config_valid_reg_0 : out STD_LOGIC;
    state : out STD_LOGIC;
    prev_was_last_reg_0 : out STD_LOGIC;
    \ilas_config_addr_reg[1]_0\ : out STD_LOGIC;
    ilas_config_addr : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    prev_was_last0 : in STD_LOGIC;
    clk : in STD_LOGIC;
    ilas_config_valid_reg_1 : in STD_LOGIC;
    state_reg_0 : in STD_LOGIC;
    \wr_addr_reg[0]\ : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_ilas_monitor_12 : entity is "jesd204_ilas_monitor";
end jesd204_rx_0_jesd204_ilas_monitor_12;

architecture STRUCTURE of jesd204_rx_0_jesd204_ilas_monitor_12 is
  signal \^ilas_config_addr\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \ilas_config_addr[0]_i_1__0_n_0\ : STD_LOGIC;
  signal \ilas_config_addr[1]_i_1__0_n_0\ : STD_LOGIC;
  signal \^ilas_config_valid_reg_0\ : STD_LOGIC;
  signal prev_was_last : STD_LOGIC;
  signal \^state\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \ilas_config_addr[0]_i_1__0\ : label is "soft_lutpair54";
  attribute SOFT_HLUTNM of \ilas_config_addr[1]_i_1__0\ : label is "soft_lutpair54";
  attribute SOFT_HLUTNM of \ilas_config_valid_i_2__0\ : label is "soft_lutpair53";
  attribute SOFT_HLUTNM of \state[14]_i_2\ : label is "soft_lutpair53";
begin
  ilas_config_addr(1 downto 0) <= \^ilas_config_addr\(1 downto 0);
  ilas_config_valid_reg_0 <= \^ilas_config_valid_reg_0\;
  state <= \^state\;
\ilas_config_addr[0]_i_1__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"4"
    )
        port map (
      I0 => \^ilas_config_addr\(0),
      I1 => \^ilas_config_valid_reg_0\,
      O => \ilas_config_addr[0]_i_1__0_n_0\
    );
\ilas_config_addr[1]_i_1__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"60"
    )
        port map (
      I0 => \^ilas_config_addr\(1),
      I1 => \^ilas_config_addr\(0),
      I2 => \^ilas_config_valid_reg_0\,
      O => \ilas_config_addr[1]_i_1__0_n_0\
    );
\ilas_config_addr_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \ilas_config_addr[0]_i_1__0_n_0\,
      Q => \^ilas_config_addr\(0),
      R => '0'
    );
\ilas_config_addr_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \ilas_config_addr[1]_i_1__0_n_0\,
      Q => \^ilas_config_addr\(1),
      R => '0'
    );
\ilas_config_data_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(0),
      Q => ilas_config_data(0),
      R => '0'
    );
\ilas_config_data_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(10),
      Q => ilas_config_data(10),
      R => '0'
    );
\ilas_config_data_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(11),
      Q => ilas_config_data(11),
      R => '0'
    );
\ilas_config_data_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(12),
      Q => ilas_config_data(12),
      R => '0'
    );
\ilas_config_data_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(13),
      Q => ilas_config_data(13),
      R => '0'
    );
\ilas_config_data_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(14),
      Q => ilas_config_data(14),
      R => '0'
    );
\ilas_config_data_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(15),
      Q => ilas_config_data(15),
      R => '0'
    );
\ilas_config_data_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(16),
      Q => ilas_config_data(16),
      R => '0'
    );
\ilas_config_data_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(17),
      Q => ilas_config_data(17),
      R => '0'
    );
\ilas_config_data_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(18),
      Q => ilas_config_data(18),
      R => '0'
    );
\ilas_config_data_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(19),
      Q => ilas_config_data(19),
      R => '0'
    );
\ilas_config_data_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(1),
      Q => ilas_config_data(1),
      R => '0'
    );
\ilas_config_data_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(20),
      Q => ilas_config_data(20),
      R => '0'
    );
\ilas_config_data_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(21),
      Q => ilas_config_data(21),
      R => '0'
    );
\ilas_config_data_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(22),
      Q => ilas_config_data(22),
      R => '0'
    );
\ilas_config_data_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(23),
      Q => ilas_config_data(23),
      R => '0'
    );
\ilas_config_data_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(24),
      Q => ilas_config_data(24),
      R => '0'
    );
\ilas_config_data_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(25),
      Q => ilas_config_data(25),
      R => '0'
    );
\ilas_config_data_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(26),
      Q => ilas_config_data(26),
      R => '0'
    );
\ilas_config_data_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(27),
      Q => ilas_config_data(27),
      R => '0'
    );
\ilas_config_data_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(28),
      Q => ilas_config_data(28),
      R => '0'
    );
\ilas_config_data_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(29),
      Q => ilas_config_data(29),
      R => '0'
    );
\ilas_config_data_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(2),
      Q => ilas_config_data(2),
      R => '0'
    );
\ilas_config_data_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(30),
      Q => ilas_config_data(30),
      R => '0'
    );
\ilas_config_data_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(31),
      Q => ilas_config_data(31),
      R => '0'
    );
\ilas_config_data_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(3),
      Q => ilas_config_data(3),
      R => '0'
    );
\ilas_config_data_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(4),
      Q => ilas_config_data(4),
      R => '0'
    );
\ilas_config_data_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(5),
      Q => ilas_config_data(5),
      R => '0'
    );
\ilas_config_data_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(6),
      Q => ilas_config_data(6),
      R => '0'
    );
\ilas_config_data_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(7),
      Q => ilas_config_data(7),
      R => '0'
    );
\ilas_config_data_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(8),
      Q => ilas_config_data(8),
      R => '0'
    );
\ilas_config_data_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(9),
      Q => ilas_config_data(9),
      R => '0'
    );
\ilas_config_valid_i_2__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \^ilas_config_addr\(1),
      I1 => \^ilas_config_addr\(0),
      I2 => \^state\,
      O => \ilas_config_addr_reg[1]_0\
    );
ilas_config_valid_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => ilas_config_valid_reg_1,
      Q => \^ilas_config_valid_reg_0\,
      R => '0'
    );
prev_was_last_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => prev_was_last0,
      Q => prev_was_last,
      R => '0'
    );
\state[14]_i_2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"70"
    )
        port map (
      I0 => prev_was_last,
      I1 => \wr_addr_reg[0]\,
      I2 => \^state\,
      O => prev_was_last_reg_0
    );
state_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => state_reg_0,
      Q => \^state\,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_ilas_monitor_17 is
  port (
    prev_was_last : out STD_LOGIC;
    ilas_config_valid_reg_0 : out STD_LOGIC;
    state : out STD_LOGIC;
    \ilas_config_addr_reg[1]_0\ : out STD_LOGIC;
    ilas_config_addr : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    prev_was_last0 : in STD_LOGIC;
    clk : in STD_LOGIC;
    ilas_config_valid_reg_1 : in STD_LOGIC;
    state_reg_0 : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_ilas_monitor_17 : entity is "jesd204_ilas_monitor";
end jesd204_rx_0_jesd204_ilas_monitor_17;

architecture STRUCTURE of jesd204_rx_0_jesd204_ilas_monitor_17 is
  signal \^ilas_config_addr\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \ilas_config_addr[0]_i_1_n_0\ : STD_LOGIC;
  signal \ilas_config_addr[1]_i_1_n_0\ : STD_LOGIC;
  signal \^ilas_config_valid_reg_0\ : STD_LOGIC;
  signal \^state\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \ilas_config_addr[1]_i_1\ : label is "soft_lutpair42";
  attribute SOFT_HLUTNM of ilas_config_valid_i_2 : label is "soft_lutpair42";
begin
  ilas_config_addr(1 downto 0) <= \^ilas_config_addr\(1 downto 0);
  ilas_config_valid_reg_0 <= \^ilas_config_valid_reg_0\;
  state <= \^state\;
\ilas_config_addr[0]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"4"
    )
        port map (
      I0 => \^ilas_config_addr\(0),
      I1 => \^ilas_config_valid_reg_0\,
      O => \ilas_config_addr[0]_i_1_n_0\
    );
\ilas_config_addr[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"60"
    )
        port map (
      I0 => \^ilas_config_addr\(1),
      I1 => \^ilas_config_addr\(0),
      I2 => \^ilas_config_valid_reg_0\,
      O => \ilas_config_addr[1]_i_1_n_0\
    );
\ilas_config_addr_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \ilas_config_addr[0]_i_1_n_0\,
      Q => \^ilas_config_addr\(0),
      R => '0'
    );
\ilas_config_addr_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \ilas_config_addr[1]_i_1_n_0\,
      Q => \^ilas_config_addr\(1),
      R => '0'
    );
\ilas_config_data_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(0),
      Q => ilas_config_data(0),
      R => '0'
    );
\ilas_config_data_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(10),
      Q => ilas_config_data(10),
      R => '0'
    );
\ilas_config_data_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(11),
      Q => ilas_config_data(11),
      R => '0'
    );
\ilas_config_data_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(12),
      Q => ilas_config_data(12),
      R => '0'
    );
\ilas_config_data_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(13),
      Q => ilas_config_data(13),
      R => '0'
    );
\ilas_config_data_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(14),
      Q => ilas_config_data(14),
      R => '0'
    );
\ilas_config_data_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(15),
      Q => ilas_config_data(15),
      R => '0'
    );
\ilas_config_data_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(16),
      Q => ilas_config_data(16),
      R => '0'
    );
\ilas_config_data_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(17),
      Q => ilas_config_data(17),
      R => '0'
    );
\ilas_config_data_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(18),
      Q => ilas_config_data(18),
      R => '0'
    );
\ilas_config_data_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(19),
      Q => ilas_config_data(19),
      R => '0'
    );
\ilas_config_data_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(1),
      Q => ilas_config_data(1),
      R => '0'
    );
\ilas_config_data_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(20),
      Q => ilas_config_data(20),
      R => '0'
    );
\ilas_config_data_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(21),
      Q => ilas_config_data(21),
      R => '0'
    );
\ilas_config_data_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(22),
      Q => ilas_config_data(22),
      R => '0'
    );
\ilas_config_data_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(23),
      Q => ilas_config_data(23),
      R => '0'
    );
\ilas_config_data_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(24),
      Q => ilas_config_data(24),
      R => '0'
    );
\ilas_config_data_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(25),
      Q => ilas_config_data(25),
      R => '0'
    );
\ilas_config_data_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(26),
      Q => ilas_config_data(26),
      R => '0'
    );
\ilas_config_data_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(27),
      Q => ilas_config_data(27),
      R => '0'
    );
\ilas_config_data_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(28),
      Q => ilas_config_data(28),
      R => '0'
    );
\ilas_config_data_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(29),
      Q => ilas_config_data(29),
      R => '0'
    );
\ilas_config_data_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(2),
      Q => ilas_config_data(2),
      R => '0'
    );
\ilas_config_data_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(30),
      Q => ilas_config_data(30),
      R => '0'
    );
\ilas_config_data_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(31),
      Q => ilas_config_data(31),
      R => '0'
    );
\ilas_config_data_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(3),
      Q => ilas_config_data(3),
      R => '0'
    );
\ilas_config_data_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(4),
      Q => ilas_config_data(4),
      R => '0'
    );
\ilas_config_data_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(5),
      Q => ilas_config_data(5),
      R => '0'
    );
\ilas_config_data_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(6),
      Q => ilas_config_data(6),
      R => '0'
    );
\ilas_config_data_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(7),
      Q => ilas_config_data(7),
      R => '0'
    );
\ilas_config_data_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(8),
      Q => ilas_config_data(8),
      R => '0'
    );
\ilas_config_data_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(9),
      Q => ilas_config_data(9),
      R => '0'
    );
ilas_config_valid_i_2: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \^ilas_config_addr\(1),
      I1 => \^ilas_config_addr\(0),
      I2 => \^state\,
      O => \ilas_config_addr_reg[1]_0\
    );
ilas_config_valid_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => ilas_config_valid_reg_1,
      Q => \^ilas_config_valid_reg_0\,
      R => '0'
    );
prev_was_last_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => prev_was_last0,
      Q => prev_was_last,
      R => '0'
    );
state_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => state_reg_0,
      Q => \^state\,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_ilas_monitor_7 is
  port (
    ilas_config_valid_reg_0 : out STD_LOGIC;
    state : out STD_LOGIC;
    prev_was_last_reg_0 : out STD_LOGIC;
    \ilas_config_addr_reg[1]_0\ : out STD_LOGIC;
    ilas_config_addr : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    prev_was_last0 : in STD_LOGIC;
    clk : in STD_LOGIC;
    ilas_config_valid_reg_1 : in STD_LOGIC;
    state_reg_0 : in STD_LOGIC;
    \wr_addr_reg[6]\ : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_ilas_monitor_7 : entity is "jesd204_ilas_monitor";
end jesd204_rx_0_jesd204_ilas_monitor_7;

architecture STRUCTURE of jesd204_rx_0_jesd204_ilas_monitor_7 is
  signal \^ilas_config_addr\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \ilas_config_addr[0]_i_1__1_n_0\ : STD_LOGIC;
  signal \ilas_config_addr[1]_i_1__1_n_0\ : STD_LOGIC;
  signal \^ilas_config_valid_reg_0\ : STD_LOGIC;
  signal prev_was_last : STD_LOGIC;
  signal \^state\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \ilas_config_addr[0]_i_1__1\ : label is "soft_lutpair67";
  attribute SOFT_HLUTNM of \ilas_config_addr[1]_i_1__1\ : label is "soft_lutpair67";
  attribute SOFT_HLUTNM of \ilas_config_valid_i_2__1\ : label is "soft_lutpair66";
  attribute SOFT_HLUTNM of \state[14]_i_2__0\ : label is "soft_lutpair66";
begin
  ilas_config_addr(1 downto 0) <= \^ilas_config_addr\(1 downto 0);
  ilas_config_valid_reg_0 <= \^ilas_config_valid_reg_0\;
  state <= \^state\;
\ilas_config_addr[0]_i_1__1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"4"
    )
        port map (
      I0 => \^ilas_config_addr\(0),
      I1 => \^ilas_config_valid_reg_0\,
      O => \ilas_config_addr[0]_i_1__1_n_0\
    );
\ilas_config_addr[1]_i_1__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"60"
    )
        port map (
      I0 => \^ilas_config_addr\(1),
      I1 => \^ilas_config_addr\(0),
      I2 => \^ilas_config_valid_reg_0\,
      O => \ilas_config_addr[1]_i_1__1_n_0\
    );
\ilas_config_addr_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \ilas_config_addr[0]_i_1__1_n_0\,
      Q => \^ilas_config_addr\(0),
      R => '0'
    );
\ilas_config_addr_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \ilas_config_addr[1]_i_1__1_n_0\,
      Q => \^ilas_config_addr\(1),
      R => '0'
    );
\ilas_config_data_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(0),
      Q => ilas_config_data(0),
      R => '0'
    );
\ilas_config_data_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(10),
      Q => ilas_config_data(10),
      R => '0'
    );
\ilas_config_data_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(11),
      Q => ilas_config_data(11),
      R => '0'
    );
\ilas_config_data_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(12),
      Q => ilas_config_data(12),
      R => '0'
    );
\ilas_config_data_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(13),
      Q => ilas_config_data(13),
      R => '0'
    );
\ilas_config_data_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(14),
      Q => ilas_config_data(14),
      R => '0'
    );
\ilas_config_data_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(15),
      Q => ilas_config_data(15),
      R => '0'
    );
\ilas_config_data_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(16),
      Q => ilas_config_data(16),
      R => '0'
    );
\ilas_config_data_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(17),
      Q => ilas_config_data(17),
      R => '0'
    );
\ilas_config_data_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(18),
      Q => ilas_config_data(18),
      R => '0'
    );
\ilas_config_data_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(19),
      Q => ilas_config_data(19),
      R => '0'
    );
\ilas_config_data_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(1),
      Q => ilas_config_data(1),
      R => '0'
    );
\ilas_config_data_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(20),
      Q => ilas_config_data(20),
      R => '0'
    );
\ilas_config_data_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(21),
      Q => ilas_config_data(21),
      R => '0'
    );
\ilas_config_data_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(22),
      Q => ilas_config_data(22),
      R => '0'
    );
\ilas_config_data_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(23),
      Q => ilas_config_data(23),
      R => '0'
    );
\ilas_config_data_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(24),
      Q => ilas_config_data(24),
      R => '0'
    );
\ilas_config_data_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(25),
      Q => ilas_config_data(25),
      R => '0'
    );
\ilas_config_data_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(26),
      Q => ilas_config_data(26),
      R => '0'
    );
\ilas_config_data_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(27),
      Q => ilas_config_data(27),
      R => '0'
    );
\ilas_config_data_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(28),
      Q => ilas_config_data(28),
      R => '0'
    );
\ilas_config_data_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(29),
      Q => ilas_config_data(29),
      R => '0'
    );
\ilas_config_data_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(2),
      Q => ilas_config_data(2),
      R => '0'
    );
\ilas_config_data_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(30),
      Q => ilas_config_data(30),
      R => '0'
    );
\ilas_config_data_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(31),
      Q => ilas_config_data(31),
      R => '0'
    );
\ilas_config_data_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(3),
      Q => ilas_config_data(3),
      R => '0'
    );
\ilas_config_data_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(4),
      Q => ilas_config_data(4),
      R => '0'
    );
\ilas_config_data_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(5),
      Q => ilas_config_data(5),
      R => '0'
    );
\ilas_config_data_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(6),
      Q => ilas_config_data(6),
      R => '0'
    );
\ilas_config_data_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(7),
      Q => ilas_config_data(7),
      R => '0'
    );
\ilas_config_data_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(8),
      Q => ilas_config_data(8),
      R => '0'
    );
\ilas_config_data_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => D(9),
      Q => ilas_config_data(9),
      R => '0'
    );
\ilas_config_valid_i_2__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \^ilas_config_addr\(1),
      I1 => \^ilas_config_addr\(0),
      I2 => \^state\,
      O => \ilas_config_addr_reg[1]_0\
    );
ilas_config_valid_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => ilas_config_valid_reg_1,
      Q => \^ilas_config_valid_reg_0\,
      R => '0'
    );
prev_was_last_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => prev_was_last0,
      Q => prev_was_last,
      R => '0'
    );
\state[14]_i_2__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"70"
    )
        port map (
      I0 => prev_was_last,
      I1 => \wr_addr_reg[6]\,
      I2 => \^state\,
      O => prev_was_last_reg_0
    );
state_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => state_reg_0,
      Q => \^state\,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_lane_latency_monitor is
  port (
    status_lane_ifs_ready : out STD_LOGIC_VECTOR ( 3 downto 0 );
    status_lane_latency : out STD_LOGIC_VECTOR ( 47 downto 0 );
    latency_monitor_reset : in STD_LOGIC;
    E : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk : in STD_LOGIC;
    \gen_lane[1].lane_latency_mem_reg[1][11]_0\ : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_lane[2].lane_latency_mem_reg[2][11]_0\ : in STD_LOGIC_VECTOR ( 0 to 0 );
    \gen_lane[3].lane_latency_mem_reg[3][11]_0\ : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_lane_latency_monitor : entity is "jesd204_lane_latency_monitor";
end jesd204_rx_0_jesd204_lane_latency_monitor;

architecture STRUCTURE of jesd204_rx_0_jesd204_lane_latency_monitor is
  signal \beat_counter[0]_i_3_n_0\ : STD_LOGIC;
  signal \beat_counter[0]_i_4_n_0\ : STD_LOGIC;
  signal \beat_counter[0]_i_5_n_0\ : STD_LOGIC;
  signal beat_counter_reg : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal \beat_counter_reg[0]_i_2_n_0\ : STD_LOGIC;
  signal \beat_counter_reg[0]_i_2_n_1\ : STD_LOGIC;
  signal \beat_counter_reg[0]_i_2_n_2\ : STD_LOGIC;
  signal \beat_counter_reg[0]_i_2_n_3\ : STD_LOGIC;
  signal \beat_counter_reg[0]_i_2_n_4\ : STD_LOGIC;
  signal \beat_counter_reg[0]_i_2_n_5\ : STD_LOGIC;
  signal \beat_counter_reg[0]_i_2_n_6\ : STD_LOGIC;
  signal \beat_counter_reg[0]_i_2_n_7\ : STD_LOGIC;
  signal \beat_counter_reg[4]_i_1_n_0\ : STD_LOGIC;
  signal \beat_counter_reg[4]_i_1_n_1\ : STD_LOGIC;
  signal \beat_counter_reg[4]_i_1_n_2\ : STD_LOGIC;
  signal \beat_counter_reg[4]_i_1_n_3\ : STD_LOGIC;
  signal \beat_counter_reg[4]_i_1_n_4\ : STD_LOGIC;
  signal \beat_counter_reg[4]_i_1_n_5\ : STD_LOGIC;
  signal \beat_counter_reg[4]_i_1_n_6\ : STD_LOGIC;
  signal \beat_counter_reg[4]_i_1_n_7\ : STD_LOGIC;
  signal \beat_counter_reg[8]_i_1_n_1\ : STD_LOGIC;
  signal \beat_counter_reg[8]_i_1_n_2\ : STD_LOGIC;
  signal \beat_counter_reg[8]_i_1_n_3\ : STD_LOGIC;
  signal \beat_counter_reg[8]_i_1_n_4\ : STD_LOGIC;
  signal \beat_counter_reg[8]_i_1_n_5\ : STD_LOGIC;
  signal \beat_counter_reg[8]_i_1_n_6\ : STD_LOGIC;
  signal \beat_counter_reg[8]_i_1_n_7\ : STD_LOGIC;
  signal sel : STD_LOGIC;
  signal \NLW_beat_counter_reg[8]_i_1_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
begin
\beat_counter[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFBFFFFFFF"
    )
        port map (
      I0 => \beat_counter[0]_i_3_n_0\,
      I1 => beat_counter_reg(11),
      I2 => beat_counter_reg(9),
      I3 => beat_counter_reg(0),
      I4 => beat_counter_reg(2),
      I5 => \beat_counter[0]_i_4_n_0\,
      O => sel
    );
\beat_counter[0]_i_3\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7FFF"
    )
        port map (
      I0 => beat_counter_reg(5),
      I1 => beat_counter_reg(1),
      I2 => beat_counter_reg(4),
      I3 => beat_counter_reg(3),
      O => \beat_counter[0]_i_3_n_0\
    );
\beat_counter[0]_i_4\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7FFF"
    )
        port map (
      I0 => beat_counter_reg(6),
      I1 => beat_counter_reg(8),
      I2 => beat_counter_reg(10),
      I3 => beat_counter_reg(7),
      O => \beat_counter[0]_i_4_n_0\
    );
\beat_counter[0]_i_5\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => beat_counter_reg(0),
      O => \beat_counter[0]_i_5_n_0\
    );
\beat_counter_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[0]_i_2_n_7\,
      Q => beat_counter_reg(0),
      R => latency_monitor_reset
    );
\beat_counter_reg[0]_i_2\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \beat_counter_reg[0]_i_2_n_0\,
      CO(2) => \beat_counter_reg[0]_i_2_n_1\,
      CO(1) => \beat_counter_reg[0]_i_2_n_2\,
      CO(0) => \beat_counter_reg[0]_i_2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0001",
      O(3) => \beat_counter_reg[0]_i_2_n_4\,
      O(2) => \beat_counter_reg[0]_i_2_n_5\,
      O(1) => \beat_counter_reg[0]_i_2_n_6\,
      O(0) => \beat_counter_reg[0]_i_2_n_7\,
      S(3 downto 1) => beat_counter_reg(3 downto 1),
      S(0) => \beat_counter[0]_i_5_n_0\
    );
\beat_counter_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[8]_i_1_n_5\,
      Q => beat_counter_reg(10),
      R => latency_monitor_reset
    );
\beat_counter_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[8]_i_1_n_4\,
      Q => beat_counter_reg(11),
      R => latency_monitor_reset
    );
\beat_counter_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[0]_i_2_n_6\,
      Q => beat_counter_reg(1),
      R => latency_monitor_reset
    );
\beat_counter_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[0]_i_2_n_5\,
      Q => beat_counter_reg(2),
      R => latency_monitor_reset
    );
\beat_counter_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[0]_i_2_n_4\,
      Q => beat_counter_reg(3),
      R => latency_monitor_reset
    );
\beat_counter_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[4]_i_1_n_7\,
      Q => beat_counter_reg(4),
      R => latency_monitor_reset
    );
\beat_counter_reg[4]_i_1\: unisim.vcomponents.CARRY4
     port map (
      CI => \beat_counter_reg[0]_i_2_n_0\,
      CO(3) => \beat_counter_reg[4]_i_1_n_0\,
      CO(2) => \beat_counter_reg[4]_i_1_n_1\,
      CO(1) => \beat_counter_reg[4]_i_1_n_2\,
      CO(0) => \beat_counter_reg[4]_i_1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \beat_counter_reg[4]_i_1_n_4\,
      O(2) => \beat_counter_reg[4]_i_1_n_5\,
      O(1) => \beat_counter_reg[4]_i_1_n_6\,
      O(0) => \beat_counter_reg[4]_i_1_n_7\,
      S(3 downto 0) => beat_counter_reg(7 downto 4)
    );
\beat_counter_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[4]_i_1_n_6\,
      Q => beat_counter_reg(5),
      R => latency_monitor_reset
    );
\beat_counter_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[4]_i_1_n_5\,
      Q => beat_counter_reg(6),
      R => latency_monitor_reset
    );
\beat_counter_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[4]_i_1_n_4\,
      Q => beat_counter_reg(7),
      R => latency_monitor_reset
    );
\beat_counter_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[8]_i_1_n_7\,
      Q => beat_counter_reg(8),
      R => latency_monitor_reset
    );
\beat_counter_reg[8]_i_1\: unisim.vcomponents.CARRY4
     port map (
      CI => \beat_counter_reg[4]_i_1_n_0\,
      CO(3) => \NLW_beat_counter_reg[8]_i_1_CO_UNCONNECTED\(3),
      CO(2) => \beat_counter_reg[8]_i_1_n_1\,
      CO(1) => \beat_counter_reg[8]_i_1_n_2\,
      CO(0) => \beat_counter_reg[8]_i_1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \beat_counter_reg[8]_i_1_n_4\,
      O(2) => \beat_counter_reg[8]_i_1_n_5\,
      O(1) => \beat_counter_reg[8]_i_1_n_6\,
      O(0) => \beat_counter_reg[8]_i_1_n_7\,
      S(3 downto 0) => beat_counter_reg(11 downto 8)
    );
\beat_counter_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => sel,
      D => \beat_counter_reg[8]_i_1_n_6\,
      Q => beat_counter_reg(9),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_captured_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => E(0),
      D => '1',
      Q => status_lane_ifs_ready(0),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(0),
      Q => status_lane_latency(0),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(10),
      Q => status_lane_latency(10),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(11),
      Q => status_lane_latency(11),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(1),
      Q => status_lane_latency(1),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(2),
      Q => status_lane_latency(2),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(3),
      Q => status_lane_latency(3),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(4),
      Q => status_lane_latency(4),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(5),
      Q => status_lane_latency(5),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(6),
      Q => status_lane_latency(6),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(7),
      Q => status_lane_latency(7),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(8),
      Q => status_lane_latency(8),
      R => latency_monitor_reset
    );
\gen_lane[0].lane_latency_mem_reg[0][9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => E(0),
      D => beat_counter_reg(9),
      Q => status_lane_latency(9),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_captured_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => '1',
      Q => status_lane_ifs_ready(1),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(0),
      Q => status_lane_latency(12),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(10),
      Q => status_lane_latency(22),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(11),
      Q => status_lane_latency(23),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(1),
      Q => status_lane_latency(13),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(2),
      Q => status_lane_latency(14),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(3),
      Q => status_lane_latency(15),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(4),
      Q => status_lane_latency(16),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(5),
      Q => status_lane_latency(17),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(6),
      Q => status_lane_latency(18),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(7),
      Q => status_lane_latency(19),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(8),
      Q => status_lane_latency(20),
      R => latency_monitor_reset
    );
\gen_lane[1].lane_latency_mem_reg[1][9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0),
      D => beat_counter_reg(9),
      Q => status_lane_latency(21),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_captured_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => '1',
      Q => status_lane_ifs_ready(2),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(0),
      Q => status_lane_latency(24),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(10),
      Q => status_lane_latency(34),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(11),
      Q => status_lane_latency(35),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(1),
      Q => status_lane_latency(25),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(2),
      Q => status_lane_latency(26),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(3),
      Q => status_lane_latency(27),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(4),
      Q => status_lane_latency(28),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(5),
      Q => status_lane_latency(29),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(6),
      Q => status_lane_latency(30),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(7),
      Q => status_lane_latency(31),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(8),
      Q => status_lane_latency(32),
      R => latency_monitor_reset
    );
\gen_lane[2].lane_latency_mem_reg[2][9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0),
      D => beat_counter_reg(9),
      Q => status_lane_latency(33),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_captured_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => '1',
      Q => status_lane_ifs_ready(3),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(0),
      Q => status_lane_latency(36),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(10),
      Q => status_lane_latency(46),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(11),
      Q => status_lane_latency(47),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(1),
      Q => status_lane_latency(37),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(2),
      Q => status_lane_latency(38),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(3),
      Q => status_lane_latency(39),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(4),
      Q => status_lane_latency(40),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(5),
      Q => status_lane_latency(41),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(6),
      Q => status_lane_latency(42),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(7),
      Q => status_lane_latency(43),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(8),
      Q => status_lane_latency(44),
      R => latency_monitor_reset
    );
\gen_lane[3].lane_latency_mem_reg[3][9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0),
      D => beat_counter_reg(9),
      Q => status_lane_latency(45),
      R => latency_monitor_reset
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_lmfc is
  port (
    sysref_edge_reg_0 : out STD_LOGIC;
    lmfc_edge_reg_0 : out STD_LOGIC;
    lmfc_clk : out STD_LOGIC;
    event_sysref_alignment_error : out STD_LOGIC;
    cfg_buffer_early_release_0 : out STD_LOGIC;
    sysref : in STD_LOGIC;
    clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    cfg_buffer_early_release : in STD_LOGIC;
    cfg_sysref_disable : in STD_LOGIC;
    cfg_lmfc_offset : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_sysref_oneshot : in STD_LOGIC;
    cfg_beats_per_multiframe : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_buffer_delay : in STD_LOGIC_VECTOR ( 7 downto 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_lmfc : entity is "jesd204_lmfc";
end jesd204_rx_0_jesd204_lmfc;

architecture STRUCTURE of jesd204_rx_0_jesd204_lmfc is
  signal buffer_release_opportunity_i_2_n_0 : STD_LOGIC;
  signal buffer_release_opportunity_i_3_n_0 : STD_LOGIC;
  signal buffer_release_opportunity_i_4_n_0 : STD_LOGIC;
  signal lmfc_active : STD_LOGIC;
  signal lmfc_active_i_1_n_0 : STD_LOGIC;
  signal lmfc_clk_p1 : STD_LOGIC;
  signal \lmfc_clk_p10__14\ : STD_LOGIC;
  signal lmfc_clk_p1_i_1_n_0 : STD_LOGIC;
  signal lmfc_clk_p1_i_3_n_0 : STD_LOGIC;
  signal lmfc_clk_p1_i_4_n_0 : STD_LOGIC;
  signal lmfc_counter : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \lmfc_counter1__1\ : STD_LOGIC;
  signal \lmfc_counter[5]_i_2_n_0\ : STD_LOGIC;
  signal \lmfc_counter[7]_i_2_n_0\ : STD_LOGIC;
  signal \lmfc_counter[7]_i_5_n_0\ : STD_LOGIC;
  signal \lmfc_counter[7]_i_6_n_0\ : STD_LOGIC;
  signal lmfc_counter_next1 : STD_LOGIC;
  signal \lmfc_counter_next__7\ : STD_LOGIC_VECTOR ( 4 downto 3 );
  signal lmfc_edge0 : STD_LOGIC;
  signal lmfc_edge_i_2_n_0 : STD_LOGIC;
  signal p_0_in : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal sysref_alignment_error0 : STD_LOGIC;
  signal sysref_alignment_error_i_2_n_0 : STD_LOGIC;
  signal sysref_alignment_error_i_3_n_0 : STD_LOGIC;
  signal sysref_alignment_error_i_4_n_0 : STD_LOGIC;
  signal sysref_alignment_error_i_5_n_0 : STD_LOGIC;
  signal sysref_alignment_error_i_6_n_0 : STD_LOGIC;
  signal sysref_alignment_error_i_7_n_0 : STD_LOGIC;
  signal sysref_alignment_error_i_8_n_0 : STD_LOGIC;
  signal sysref_alignment_error_i_9_n_0 : STD_LOGIC;
  signal sysref_captured : STD_LOGIC;
  signal sysref_captured_i_1_n_0 : STD_LOGIC;
  signal sysref_d1 : STD_LOGIC;
  signal sysref_d2 : STD_LOGIC;
  signal sysref_d3 : STD_LOGIC;
  signal sysref_edge0 : STD_LOGIC;
  signal \^sysref_edge_reg_0\ : STD_LOGIC;
  signal sysref_r : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \lmfc_counter[1]_i_1\ : label is "soft_lutpair27";
  attribute SOFT_HLUTNM of \lmfc_counter[3]_i_1\ : label is "soft_lutpair30";
  attribute SOFT_HLUTNM of \lmfc_counter[3]_i_2\ : label is "soft_lutpair29";
  attribute SOFT_HLUTNM of \lmfc_counter[4]_i_1\ : label is "soft_lutpair31";
  attribute SOFT_HLUTNM of \lmfc_counter[5]_i_2\ : label is "soft_lutpair28";
  attribute SOFT_HLUTNM of \lmfc_counter[7]_i_4\ : label is "soft_lutpair30";
  attribute SOFT_HLUTNM of lmfc_edge_i_2 : label is "soft_lutpair28";
  attribute SOFT_HLUTNM of sysref_alignment_error_i_6 : label is "soft_lutpair29";
  attribute SOFT_HLUTNM of sysref_alignment_error_i_9 : label is "soft_lutpair27";
  attribute SOFT_HLUTNM of sysref_captured_i_1 : label is "soft_lutpair31";
  attribute ASYNC_REG : boolean;
  attribute ASYNC_REG of sysref_d1_reg : label is std.standard.true;
  attribute ASYNC_REG of sysref_d2_reg : label is std.standard.true;
  attribute IOB : string;
  attribute IOB of sysref_r_reg : label is "TRUE";
begin
  sysref_edge_reg_0 <= \^sysref_edge_reg_0\;
buffer_release_opportunity_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FF08"
    )
        port map (
      I0 => buffer_release_opportunity_i_2_n_0,
      I1 => buffer_release_opportunity_i_3_n_0,
      I2 => buffer_release_opportunity_i_4_n_0,
      I3 => cfg_buffer_early_release,
      O => cfg_buffer_early_release_0
    );
buffer_release_opportunity_i_2: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => lmfc_counter(0),
      I1 => cfg_buffer_delay(0),
      I2 => cfg_buffer_delay(2),
      I3 => lmfc_counter(2),
      I4 => cfg_buffer_delay(1),
      I5 => lmfc_counter(1),
      O => buffer_release_opportunity_i_2_n_0
    );
buffer_release_opportunity_i_3: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => lmfc_counter(3),
      I1 => cfg_buffer_delay(3),
      I2 => cfg_buffer_delay(5),
      I3 => lmfc_counter(5),
      I4 => cfg_buffer_delay(4),
      I5 => lmfc_counter(4),
      O => buffer_release_opportunity_i_3_n_0
    );
buffer_release_opportunity_i_4: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6FF6"
    )
        port map (
      I0 => lmfc_counter(6),
      I1 => cfg_buffer_delay(6),
      I2 => lmfc_counter(7),
      I3 => cfg_buffer_delay(7),
      O => buffer_release_opportunity_i_4_n_0
    );
lmfc_active_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"BBBBBBBB8BBB8888"
    )
        port map (
      I0 => cfg_sysref_disable,
      I1 => reset,
      I2 => cfg_sysref_oneshot,
      I3 => sysref_captured,
      I4 => \^sysref_edge_reg_0\,
      I5 => lmfc_active,
      O => lmfc_active_i_1_n_0
    );
lmfc_active_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => lmfc_active_i_1_n_0,
      Q => lmfc_active,
      R => '0'
    );
lmfc_clk_p1_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"F7A0"
    )
        port map (
      I0 => lmfc_active,
      I1 => \lmfc_clk_p10__14\,
      I2 => lmfc_counter_next1,
      I3 => lmfc_clk_p1,
      O => lmfc_clk_p1_i_1_n_0
    );
lmfc_clk_p1_i_2: unisim.vcomponents.LUT5
    generic map(
      INIT => X"09000000"
    )
        port map (
      I0 => cfg_beats_per_multiframe(7),
      I1 => lmfc_counter(6),
      I2 => lmfc_counter(7),
      I3 => lmfc_clk_p1_i_3_n_0,
      I4 => lmfc_clk_p1_i_4_n_0,
      O => \lmfc_clk_p10__14\
    );
lmfc_clk_p1_i_3: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => lmfc_counter(3),
      I1 => cfg_beats_per_multiframe(4),
      I2 => cfg_beats_per_multiframe(6),
      I3 => lmfc_counter(5),
      I4 => cfg_beats_per_multiframe(5),
      I5 => lmfc_counter(4),
      O => lmfc_clk_p1_i_3_n_0
    );
lmfc_clk_p1_i_4: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => lmfc_counter(0),
      I1 => cfg_beats_per_multiframe(1),
      I2 => cfg_beats_per_multiframe(3),
      I3 => lmfc_counter(2),
      I4 => cfg_beats_per_multiframe(2),
      I5 => lmfc_counter(1),
      O => lmfc_clk_p1_i_4_n_0
    );
lmfc_clk_p1_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => lmfc_clk_p1_i_1_n_0,
      Q => lmfc_clk_p1,
      R => reset
    );
lmfc_clk_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => lmfc_clk_p1,
      Q => lmfc_clk,
      R => '0'
    );
\lmfc_counter[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0303AA03AA03AA03"
    )
        port map (
      I0 => cfg_lmfc_offset(0),
      I1 => lmfc_counter(0),
      I2 => lmfc_counter_next1,
      I3 => \^sysref_edge_reg_0\,
      I4 => sysref_captured,
      I5 => cfg_sysref_oneshot,
      O => p_0_in(0)
    );
\lmfc_counter[1]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAA003C"
    )
        port map (
      I0 => cfg_lmfc_offset(1),
      I1 => lmfc_counter(1),
      I2 => lmfc_counter(0),
      I3 => lmfc_counter_next1,
      I4 => \lmfc_counter1__1\,
      O => p_0_in(1)
    );
\lmfc_counter[2]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAA00003CCC"
    )
        port map (
      I0 => cfg_lmfc_offset(2),
      I1 => lmfc_counter(2),
      I2 => lmfc_counter(1),
      I3 => lmfc_counter(0),
      I4 => lmfc_counter_next1,
      I5 => \lmfc_counter1__1\,
      O => p_0_in(2)
    );
\lmfc_counter[3]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"CCACACAC"
    )
        port map (
      I0 => cfg_lmfc_offset(3),
      I1 => \lmfc_counter_next__7\(3),
      I2 => \^sysref_edge_reg_0\,
      I3 => sysref_captured,
      I4 => cfg_sysref_oneshot,
      O => p_0_in(3)
    );
\lmfc_counter[3]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00006AAA"
    )
        port map (
      I0 => lmfc_counter(3),
      I1 => lmfc_counter(2),
      I2 => lmfc_counter(0),
      I3 => lmfc_counter(1),
      I4 => lmfc_counter_next1,
      O => \lmfc_counter_next__7\(3)
    );
\lmfc_counter[4]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"CCACACAC"
    )
        port map (
      I0 => cfg_lmfc_offset(4),
      I1 => \lmfc_counter_next__7\(4),
      I2 => \^sysref_edge_reg_0\,
      I3 => sysref_captured,
      I4 => cfg_sysref_oneshot,
      O => p_0_in(4)
    );
\lmfc_counter[4]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000000006AAAAAAA"
    )
        port map (
      I0 => lmfc_counter(4),
      I1 => lmfc_counter(3),
      I2 => lmfc_counter(1),
      I3 => lmfc_counter(0),
      I4 => lmfc_counter(2),
      I5 => lmfc_counter_next1,
      O => \lmfc_counter_next__7\(4)
    );
\lmfc_counter[5]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAA003C"
    )
        port map (
      I0 => cfg_lmfc_offset(5),
      I1 => lmfc_counter(5),
      I2 => \lmfc_counter[5]_i_2_n_0\,
      I3 => lmfc_counter_next1,
      I4 => \lmfc_counter1__1\,
      O => p_0_in(5)
    );
\lmfc_counter[5]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => lmfc_counter(4),
      I1 => lmfc_counter(2),
      I2 => lmfc_counter(0),
      I3 => lmfc_counter(1),
      I4 => lmfc_counter(3),
      O => \lmfc_counter[5]_i_2_n_0\
    );
\lmfc_counter[6]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAA003C"
    )
        port map (
      I0 => cfg_lmfc_offset(6),
      I1 => lmfc_counter(6),
      I2 => \lmfc_counter[7]_i_2_n_0\,
      I3 => lmfc_counter_next1,
      I4 => \lmfc_counter1__1\,
      O => p_0_in(6)
    );
\lmfc_counter[7]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAA00003CCC"
    )
        port map (
      I0 => cfg_lmfc_offset(7),
      I1 => lmfc_counter(7),
      I2 => lmfc_counter(6),
      I3 => \lmfc_counter[7]_i_2_n_0\,
      I4 => lmfc_counter_next1,
      I5 => \lmfc_counter1__1\,
      O => p_0_in(7)
    );
\lmfc_counter[7]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8000000000000000"
    )
        port map (
      I0 => lmfc_counter(5),
      I1 => lmfc_counter(3),
      I2 => lmfc_counter(1),
      I3 => lmfc_counter(0),
      I4 => lmfc_counter(2),
      I5 => lmfc_counter(4),
      O => \lmfc_counter[7]_i_2_n_0\
    );
\lmfc_counter[7]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000000000"
    )
        port map (
      I0 => cfg_beats_per_multiframe(7),
      I1 => lmfc_counter(7),
      I2 => cfg_beats_per_multiframe(6),
      I3 => lmfc_counter(6),
      I4 => \lmfc_counter[7]_i_5_n_0\,
      I5 => \lmfc_counter[7]_i_6_n_0\,
      O => lmfc_counter_next1
    );
\lmfc_counter[7]_i_4\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"2A"
    )
        port map (
      I0 => \^sysref_edge_reg_0\,
      I1 => sysref_captured,
      I2 => cfg_sysref_oneshot,
      O => \lmfc_counter1__1\
    );
\lmfc_counter[7]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => lmfc_counter(3),
      I1 => cfg_beats_per_multiframe(3),
      I2 => cfg_beats_per_multiframe(5),
      I3 => lmfc_counter(5),
      I4 => cfg_beats_per_multiframe(4),
      I5 => lmfc_counter(4),
      O => \lmfc_counter[7]_i_5_n_0\
    );
\lmfc_counter[7]_i_6\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => lmfc_counter(0),
      I1 => cfg_beats_per_multiframe(0),
      I2 => cfg_beats_per_multiframe(2),
      I3 => lmfc_counter(2),
      I4 => cfg_beats_per_multiframe(1),
      I5 => lmfc_counter(1),
      O => \lmfc_counter[7]_i_6_n_0\
    );
\lmfc_counter_reg[0]\: unisim.vcomponents.FDSE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(0),
      Q => lmfc_counter(0),
      S => reset
    );
\lmfc_counter_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(1),
      Q => lmfc_counter(1),
      R => reset
    );
\lmfc_counter_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(2),
      Q => lmfc_counter(2),
      R => reset
    );
\lmfc_counter_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(3),
      Q => lmfc_counter(3),
      R => reset
    );
\lmfc_counter_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(4),
      Q => lmfc_counter(4),
      R => reset
    );
\lmfc_counter_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(5),
      Q => lmfc_counter(5),
      R => reset
    );
\lmfc_counter_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(6),
      Q => lmfc_counter(6),
      R => reset
    );
\lmfc_counter_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => p_0_in(7),
      Q => lmfc_counter(7),
      R => reset
    );
lmfc_edge_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000100000000"
    )
        port map (
      I0 => lmfc_edge_i_2_n_0,
      I1 => lmfc_counter(7),
      I2 => lmfc_counter(6),
      I3 => lmfc_counter(4),
      I4 => lmfc_counter(5),
      I5 => lmfc_active,
      O => lmfc_edge0
    );
lmfc_edge_i_2: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FFFE"
    )
        port map (
      I0 => lmfc_counter(2),
      I1 => lmfc_counter(3),
      I2 => lmfc_counter(0),
      I3 => lmfc_counter(1),
      O => lmfc_edge_i_2_n_0
    );
lmfc_edge_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => lmfc_edge0,
      Q => lmfc_edge_reg_0,
      R => '0'
    );
sysref_alignment_error_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8888888888888880"
    )
        port map (
      I0 => \^sysref_edge_reg_0\,
      I1 => lmfc_active,
      I2 => sysref_alignment_error_i_2_n_0,
      I3 => sysref_alignment_error_i_3_n_0,
      I4 => sysref_alignment_error_i_4_n_0,
      I5 => sysref_alignment_error_i_5_n_0,
      O => sysref_alignment_error0
    );
sysref_alignment_error_i_2: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFE77BAAAABDDE"
    )
        port map (
      I0 => cfg_lmfc_offset(6),
      I1 => lmfc_counter(7),
      I2 => lmfc_counter(6),
      I3 => \lmfc_counter[7]_i_2_n_0\,
      I4 => lmfc_counter_next1,
      I5 => cfg_lmfc_offset(7),
      O => sysref_alignment_error_i_2_n_0
    );
sysref_alignment_error_i_3: unisim.vcomponents.LUT6
    generic map(
      INIT => X"A99999999AAAAAAA"
    )
        port map (
      I0 => cfg_lmfc_offset(3),
      I1 => lmfc_counter_next1,
      I2 => lmfc_counter(1),
      I3 => lmfc_counter(0),
      I4 => lmfc_counter(2),
      I5 => lmfc_counter(3),
      O => sysref_alignment_error_i_3_n_0
    );
sysref_alignment_error_i_4: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFE77BAAAABDDE"
    )
        port map (
      I0 => cfg_lmfc_offset(4),
      I1 => lmfc_counter(5),
      I2 => lmfc_counter(4),
      I3 => sysref_alignment_error_i_6_n_0,
      I4 => lmfc_counter_next1,
      I5 => cfg_lmfc_offset(5),
      O => sysref_alignment_error_i_4_n_0
    );
sysref_alignment_error_i_5: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FEFEFEDFFEEFFEFD"
    )
        port map (
      I0 => cfg_lmfc_offset(0),
      I1 => sysref_alignment_error_i_7_n_0,
      I2 => cfg_lmfc_offset(1),
      I3 => lmfc_counter_next1,
      I4 => lmfc_counter(0),
      I5 => lmfc_counter(1),
      O => sysref_alignment_error_i_5_n_0
    );
sysref_alignment_error_i_6: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8000"
    )
        port map (
      I0 => lmfc_counter(3),
      I1 => lmfc_counter(1),
      I2 => lmfc_counter(0),
      I3 => lmfc_counter(2),
      O => sysref_alignment_error_i_6_n_0
    );
sysref_alignment_error_i_7: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAA65556555AAAA"
    )
        port map (
      I0 => cfg_lmfc_offset(2),
      I1 => sysref_alignment_error_i_8_n_0,
      I2 => \lmfc_counter[7]_i_5_n_0\,
      I3 => \lmfc_counter[7]_i_6_n_0\,
      I4 => sysref_alignment_error_i_9_n_0,
      I5 => lmfc_counter(2),
      O => sysref_alignment_error_i_7_n_0
    );
sysref_alignment_error_i_8: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6FF6"
    )
        port map (
      I0 => lmfc_counter(6),
      I1 => cfg_beats_per_multiframe(6),
      I2 => lmfc_counter(7),
      I3 => cfg_beats_per_multiframe(7),
      O => sysref_alignment_error_i_8_n_0
    );
sysref_alignment_error_i_9: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => lmfc_counter(1),
      I1 => lmfc_counter(0),
      O => sysref_alignment_error_i_9_n_0
    );
sysref_alignment_error_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => sysref_alignment_error0,
      Q => event_sysref_alignment_error,
      R => reset
    );
sysref_captured_i_1: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => \^sysref_edge_reg_0\,
      I1 => sysref_captured,
      O => sysref_captured_i_1_n_0
    );
sysref_captured_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => sysref_captured_i_1_n_0,
      Q => sysref_captured,
      R => reset
    );
sysref_d1_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => sysref_r,
      Q => sysref_d1,
      R => '0'
    );
sysref_d2_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => sysref_d1,
      Q => sysref_d2,
      R => '0'
    );
sysref_d3_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => sysref_d2,
      Q => sysref_d3,
      R => '0'
    );
sysref_edge_i_1: unisim.vcomponents.LUT3
    generic map(
      INIT => X"04"
    )
        port map (
      I0 => cfg_sysref_disable,
      I1 => sysref_d2,
      I2 => sysref_d3,
      O => sysref_edge0
    );
sysref_edge_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => sysref_edge0,
      Q => \^sysref_edge_reg_0\,
      R => '0'
    );
sysref_r_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => sysref,
      Q => sysref_r,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_cgs is
  port (
    cgs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    SR : out STD_LOGIC_VECTOR ( 0 to 0 );
    \beat_error_count_reg[1]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[1]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[0]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[2]_0\ : out STD_LOGIC;
    clk : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_1\ : in STD_LOGIC;
    cgs_beat_has_error : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_2\ : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_cgs : entity is "jesd204_rx_cgs";
end jesd204_rx_0_jesd204_rx_cgs;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_cgs is
  signal \FSM_onehot_state[0]_i_1__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[1]_i_1__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_1__2_n_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[0]_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[1]_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[2]_0\ : STD_LOGIC;
  signal \beat_error_count[0]_i_1__2_n_0\ : STD_LOGIC;
  signal \beat_error_count[1]_i_1__2_n_0\ : STD_LOGIC;
  signal \beat_error_count_reg_n_0_[0]\ : STD_LOGIC;
  signal \beat_error_count_reg_n_0_[1]\ : STD_LOGIC;
  signal \^cgs_ready\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \rdy_i_1__2_n_0\ : STD_LOGIC;
  attribute FSM_ENCODED_STATES : string;
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[0]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[1]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[2]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \beat_error_count[0]_i_1__2\ : label is "soft_lutpair70";
  attribute SOFT_HLUTNM of \beat_error_count[1]_i_1__2\ : label is "soft_lutpair70";
  attribute SOFT_HLUTNM of \phy_char_err[3]_i_1__2\ : label is "soft_lutpair71";
  attribute SOFT_HLUTNM of \rdy_i_1__2\ : label is "soft_lutpair71";
begin
  \FSM_onehot_state_reg[0]_0\ <= \^fsm_onehot_state_reg[0]_0\;
  \FSM_onehot_state_reg[1]_0\ <= \^fsm_onehot_state_reg[1]_0\;
  \FSM_onehot_state_reg[2]_0\ <= \^fsm_onehot_state_reg[2]_0\;
  cgs_ready(0) <= \^cgs_ready\(0);
\FSM_onehot_state[0]_i_1__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFE222"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[0]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[1]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[0]_i_1__2_n_0\
    );
\FSM_onehot_state[1]_i_1__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0000EEE2"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[1]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => \^fsm_onehot_state_reg[2]_0\,
      I3 => \^fsm_onehot_state_reg[0]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[1]_i_1__2_n_0\
    );
\FSM_onehot_state[2]_i_1__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00002E22"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[2]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[1]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[2]_i_1__2_n_0\
    );
\FSM_onehot_state[2]_i_6__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[1]\,
      I1 => \beat_error_count_reg_n_0_[0]\,
      I2 => \^fsm_onehot_state_reg[1]_0\,
      O => \beat_error_count_reg[1]_0\
    );
\FSM_onehot_state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[0]_i_1__2_n_0\,
      Q => \^fsm_onehot_state_reg[0]_0\,
      R => '0'
    );
\FSM_onehot_state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[1]_i_1__2_n_0\,
      Q => \^fsm_onehot_state_reg[1]_0\,
      R => '0'
    );
\FSM_onehot_state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[2]_i_1__2_n_0\,
      Q => \^fsm_onehot_state_reg[2]_0\,
      R => '0'
    );
\beat_error_count[0]_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"04"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[0]\,
      I1 => cgs_beat_has_error,
      I2 => \^fsm_onehot_state_reg[0]_0\,
      O => \beat_error_count[0]_i_1__2_n_0\
    );
\beat_error_count[1]_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0060"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[1]\,
      I1 => \beat_error_count_reg_n_0_[0]\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[0]_0\,
      O => \beat_error_count[1]_i_1__2_n_0\
    );
\beat_error_count_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_error_count[0]_i_1__2_n_0\,
      Q => \beat_error_count_reg_n_0_[0]\,
      R => '0'
    );
\beat_error_count_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_error_count[1]_i_1__2_n_0\,
      Q => \beat_error_count_reg_n_0_[1]\,
      R => '0'
    );
\phy_char_err[3]_i_1__2\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \^cgs_ready\(0),
      O => SR(0)
    );
\rdy_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"DC"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[0]_0\,
      I1 => \^fsm_onehot_state_reg[2]_0\,
      I2 => \^cgs_ready\(0),
      O => \rdy_i_1__2_n_0\
    );
rdy_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rdy_i_1__2_n_0\,
      Q => \^cgs_ready\(0),
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_cgs_14 is
  port (
    cgs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    SR : out STD_LOGIC_VECTOR ( 0 to 0 );
    \beat_error_count_reg[1]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[1]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[0]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[2]_0\ : out STD_LOGIC;
    clk : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_1\ : in STD_LOGIC;
    cgs_beat_has_error : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_2\ : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_cgs_14 : entity is "jesd204_rx_cgs";
end jesd204_rx_0_jesd204_rx_cgs_14;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_cgs_14 is
  signal \FSM_onehot_state[0]_i_1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[1]_i_1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_1_n_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[0]_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[1]_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[2]_0\ : STD_LOGIC;
  signal \beat_error_count[0]_i_1_n_0\ : STD_LOGIC;
  signal \beat_error_count[1]_i_1_n_0\ : STD_LOGIC;
  signal \beat_error_count_reg_n_0_[0]\ : STD_LOGIC;
  signal \beat_error_count_reg_n_0_[1]\ : STD_LOGIC;
  signal \^cgs_ready\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal rdy_i_1_n_0 : STD_LOGIC;
  attribute FSM_ENCODED_STATES : string;
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[0]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[1]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[2]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \beat_error_count[0]_i_1\ : label is "soft_lutpair34";
  attribute SOFT_HLUTNM of \beat_error_count[1]_i_1\ : label is "soft_lutpair34";
  attribute SOFT_HLUTNM of \phy_char_err[3]_i_1\ : label is "soft_lutpair35";
  attribute SOFT_HLUTNM of rdy_i_1 : label is "soft_lutpair35";
begin
  \FSM_onehot_state_reg[0]_0\ <= \^fsm_onehot_state_reg[0]_0\;
  \FSM_onehot_state_reg[1]_0\ <= \^fsm_onehot_state_reg[1]_0\;
  \FSM_onehot_state_reg[2]_0\ <= \^fsm_onehot_state_reg[2]_0\;
  cgs_ready(0) <= \^cgs_ready\(0);
\FSM_onehot_state[0]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFE222"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[0]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[1]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[0]_i_1_n_0\
    );
\FSM_onehot_state[1]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0000EEE2"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[1]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => \^fsm_onehot_state_reg[2]_0\,
      I3 => \^fsm_onehot_state_reg[0]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[1]_i_1_n_0\
    );
\FSM_onehot_state[2]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00002E22"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[2]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[1]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[2]_i_1_n_0\
    );
\FSM_onehot_state[2]_i_6\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[1]\,
      I1 => \beat_error_count_reg_n_0_[0]\,
      I2 => \^fsm_onehot_state_reg[1]_0\,
      O => \beat_error_count_reg[1]_0\
    );
\FSM_onehot_state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[0]_i_1_n_0\,
      Q => \^fsm_onehot_state_reg[0]_0\,
      R => '0'
    );
\FSM_onehot_state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[1]_i_1_n_0\,
      Q => \^fsm_onehot_state_reg[1]_0\,
      R => '0'
    );
\FSM_onehot_state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[2]_i_1_n_0\,
      Q => \^fsm_onehot_state_reg[2]_0\,
      R => '0'
    );
\beat_error_count[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"04"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[0]\,
      I1 => cgs_beat_has_error,
      I2 => \^fsm_onehot_state_reg[0]_0\,
      O => \beat_error_count[0]_i_1_n_0\
    );
\beat_error_count[1]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0060"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[1]\,
      I1 => \beat_error_count_reg_n_0_[0]\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[0]_0\,
      O => \beat_error_count[1]_i_1_n_0\
    );
\beat_error_count_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_error_count[0]_i_1_n_0\,
      Q => \beat_error_count_reg_n_0_[0]\,
      R => '0'
    );
\beat_error_count_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_error_count[1]_i_1_n_0\,
      Q => \beat_error_count_reg_n_0_[1]\,
      R => '0'
    );
\phy_char_err[3]_i_1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \^cgs_ready\(0),
      O => SR(0)
    );
rdy_i_1: unisim.vcomponents.LUT3
    generic map(
      INIT => X"DC"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[0]_0\,
      I1 => \^fsm_onehot_state_reg[2]_0\,
      I2 => \^cgs_ready\(0),
      O => rdy_i_1_n_0
    );
rdy_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => rdy_i_1_n_0,
      Q => \^cgs_ready\(0),
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_cgs_4 is
  port (
    cgs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    SR : out STD_LOGIC_VECTOR ( 0 to 0 );
    \beat_error_count_reg[1]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[1]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[0]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[2]_0\ : out STD_LOGIC;
    clk : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_1\ : in STD_LOGIC;
    cgs_beat_has_error : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_2\ : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_cgs_4 : entity is "jesd204_rx_cgs";
end jesd204_rx_0_jesd204_rx_cgs_4;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_cgs_4 is
  signal \FSM_onehot_state[0]_i_1__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[1]_i_1__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_1__1_n_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[0]_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[1]_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[2]_0\ : STD_LOGIC;
  signal \beat_error_count[0]_i_1__1_n_0\ : STD_LOGIC;
  signal \beat_error_count[1]_i_1__1_n_0\ : STD_LOGIC;
  signal \beat_error_count_reg_n_0_[0]\ : STD_LOGIC;
  signal \beat_error_count_reg_n_0_[1]\ : STD_LOGIC;
  signal \^cgs_ready\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \rdy_i_1__1_n_0\ : STD_LOGIC;
  attribute FSM_ENCODED_STATES : string;
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[0]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[1]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[2]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \beat_error_count[0]_i_1__1\ : label is "soft_lutpair58";
  attribute SOFT_HLUTNM of \beat_error_count[1]_i_1__1\ : label is "soft_lutpair58";
  attribute SOFT_HLUTNM of \phy_char_err[3]_i_1__1\ : label is "soft_lutpair59";
  attribute SOFT_HLUTNM of \rdy_i_1__1\ : label is "soft_lutpair59";
begin
  \FSM_onehot_state_reg[0]_0\ <= \^fsm_onehot_state_reg[0]_0\;
  \FSM_onehot_state_reg[1]_0\ <= \^fsm_onehot_state_reg[1]_0\;
  \FSM_onehot_state_reg[2]_0\ <= \^fsm_onehot_state_reg[2]_0\;
  cgs_ready(0) <= \^cgs_ready\(0);
\FSM_onehot_state[0]_i_1__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFE222"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[0]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[1]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[0]_i_1__1_n_0\
    );
\FSM_onehot_state[1]_i_1__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0000EEE2"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[1]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => \^fsm_onehot_state_reg[2]_0\,
      I3 => \^fsm_onehot_state_reg[0]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[1]_i_1__1_n_0\
    );
\FSM_onehot_state[2]_i_1__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00002E22"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[2]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[1]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[2]_i_1__1_n_0\
    );
\FSM_onehot_state[2]_i_6__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[1]\,
      I1 => \beat_error_count_reg_n_0_[0]\,
      I2 => \^fsm_onehot_state_reg[1]_0\,
      O => \beat_error_count_reg[1]_0\
    );
\FSM_onehot_state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[0]_i_1__1_n_0\,
      Q => \^fsm_onehot_state_reg[0]_0\,
      R => '0'
    );
\FSM_onehot_state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[1]_i_1__1_n_0\,
      Q => \^fsm_onehot_state_reg[1]_0\,
      R => '0'
    );
\FSM_onehot_state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[2]_i_1__1_n_0\,
      Q => \^fsm_onehot_state_reg[2]_0\,
      R => '0'
    );
\beat_error_count[0]_i_1__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"04"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[0]\,
      I1 => cgs_beat_has_error,
      I2 => \^fsm_onehot_state_reg[0]_0\,
      O => \beat_error_count[0]_i_1__1_n_0\
    );
\beat_error_count[1]_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0060"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[1]\,
      I1 => \beat_error_count_reg_n_0_[0]\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[0]_0\,
      O => \beat_error_count[1]_i_1__1_n_0\
    );
\beat_error_count_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_error_count[0]_i_1__1_n_0\,
      Q => \beat_error_count_reg_n_0_[0]\,
      R => '0'
    );
\beat_error_count_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_error_count[1]_i_1__1_n_0\,
      Q => \beat_error_count_reg_n_0_[1]\,
      R => '0'
    );
\phy_char_err[3]_i_1__1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \^cgs_ready\(0),
      O => SR(0)
    );
\rdy_i_1__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"DC"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[0]_0\,
      I1 => \^fsm_onehot_state_reg[2]_0\,
      I2 => \^cgs_ready\(0),
      O => \rdy_i_1__1_n_0\
    );
rdy_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rdy_i_1__1_n_0\,
      Q => \^cgs_ready\(0),
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_cgs_9 is
  port (
    cgs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    SR : out STD_LOGIC_VECTOR ( 0 to 0 );
    \beat_error_count_reg[1]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[1]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[0]_0\ : out STD_LOGIC;
    \FSM_onehot_state_reg[2]_0\ : out STD_LOGIC;
    clk : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_1\ : in STD_LOGIC;
    cgs_beat_has_error : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_2\ : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_cgs_9 : entity is "jesd204_rx_cgs";
end jesd204_rx_0_jesd204_rx_cgs_9;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_cgs_9 is
  signal \FSM_onehot_state[0]_i_1__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[1]_i_1__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_1__0_n_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[0]_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[1]_0\ : STD_LOGIC;
  signal \^fsm_onehot_state_reg[2]_0\ : STD_LOGIC;
  signal \beat_error_count[0]_i_1__0_n_0\ : STD_LOGIC;
  signal \beat_error_count[1]_i_1__0_n_0\ : STD_LOGIC;
  signal \beat_error_count_reg_n_0_[0]\ : STD_LOGIC;
  signal \beat_error_count_reg_n_0_[1]\ : STD_LOGIC;
  signal \^cgs_ready\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \rdy_i_1__0_n_0\ : STD_LOGIC;
  attribute FSM_ENCODED_STATES : string;
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[0]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[1]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute FSM_ENCODED_STATES of \FSM_onehot_state_reg[2]\ : label is "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001";
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \beat_error_count[0]_i_1__0\ : label is "soft_lutpair45";
  attribute SOFT_HLUTNM of \beat_error_count[1]_i_1__0\ : label is "soft_lutpair45";
  attribute SOFT_HLUTNM of \phy_char_err[3]_i_1__0\ : label is "soft_lutpair46";
  attribute SOFT_HLUTNM of \rdy_i_1__0\ : label is "soft_lutpair46";
begin
  \FSM_onehot_state_reg[0]_0\ <= \^fsm_onehot_state_reg[0]_0\;
  \FSM_onehot_state_reg[1]_0\ <= \^fsm_onehot_state_reg[1]_0\;
  \FSM_onehot_state_reg[2]_0\ <= \^fsm_onehot_state_reg[2]_0\;
  cgs_ready(0) <= \^cgs_ready\(0);
\FSM_onehot_state[0]_i_1__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFE222"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[0]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[1]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[0]_i_1__0_n_0\
    );
\FSM_onehot_state[1]_i_1__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0000EEE2"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[1]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => \^fsm_onehot_state_reg[2]_0\,
      I3 => \^fsm_onehot_state_reg[0]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[1]_i_1__0_n_0\
    );
\FSM_onehot_state[2]_i_1__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00002E22"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[2]_0\,
      I1 => \FSM_onehot_state_reg[0]_1\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[1]_0\,
      I4 => \FSM_onehot_state_reg[0]_2\(0),
      O => \FSM_onehot_state[2]_i_1__0_n_0\
    );
\FSM_onehot_state[2]_i_6__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[1]\,
      I1 => \beat_error_count_reg_n_0_[0]\,
      I2 => \^fsm_onehot_state_reg[1]_0\,
      O => \beat_error_count_reg[1]_0\
    );
\FSM_onehot_state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[0]_i_1__0_n_0\,
      Q => \^fsm_onehot_state_reg[0]_0\,
      R => '0'
    );
\FSM_onehot_state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[1]_i_1__0_n_0\,
      Q => \^fsm_onehot_state_reg[1]_0\,
      R => '0'
    );
\FSM_onehot_state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_onehot_state[2]_i_1__0_n_0\,
      Q => \^fsm_onehot_state_reg[2]_0\,
      R => '0'
    );
\beat_error_count[0]_i_1__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"04"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[0]\,
      I1 => cgs_beat_has_error,
      I2 => \^fsm_onehot_state_reg[0]_0\,
      O => \beat_error_count[0]_i_1__0_n_0\
    );
\beat_error_count[1]_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0060"
    )
        port map (
      I0 => \beat_error_count_reg_n_0_[1]\,
      I1 => \beat_error_count_reg_n_0_[0]\,
      I2 => cgs_beat_has_error,
      I3 => \^fsm_onehot_state_reg[0]_0\,
      O => \beat_error_count[1]_i_1__0_n_0\
    );
\beat_error_count_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_error_count[0]_i_1__0_n_0\,
      Q => \beat_error_count_reg_n_0_[0]\,
      R => '0'
    );
\beat_error_count_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \beat_error_count[1]_i_1__0_n_0\,
      Q => \beat_error_count_reg_n_0_[1]\,
      R => '0'
    );
\phy_char_err[3]_i_1__0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \^cgs_ready\(0),
      O => SR(0)
    );
\rdy_i_1__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"DC"
    )
        port map (
      I0 => \^fsm_onehot_state_reg[0]_0\,
      I1 => \^fsm_onehot_state_reg[2]_0\,
      I2 => \^cgs_ready\(0),
      O => \rdy_i_1__0_n_0\
    );
rdy_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \rdy_i_1__0_n_0\,
      Q => \^cgs_ready\(0),
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_ctrl is
  port (
    phy_en_char_align : out STD_LOGIC;
    sync : out STD_LOGIC_VECTOR ( 0 to 0 );
    latency_monitor_reset : out STD_LOGIC;
    Q : out STD_LOGIC_VECTOR ( 3 downto 0 );
    \ifs_rst_reg[3]_0\ : out STD_LOGIC_VECTOR ( 3 downto 0 );
    status_ctrl_state : out STD_LOGIC_VECTOR ( 1 downto 0 );
    clk : in STD_LOGIC;
    cgs_ready : in STD_LOGIC_VECTOR ( 3 downto 0 );
    cfg_lanes_disable : in STD_LOGIC_VECTOR ( 3 downto 0 );
    \sync_n_reg[0]_0\ : in STD_LOGIC;
    cfg_links_disable : in STD_LOGIC_VECTOR ( 0 to 0 );
    reset : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_ctrl : entity is "jesd204_rx_ctrl";
end jesd204_rx_0_jesd204_rx_ctrl;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_ctrl is
  signal \FSM_sequential_state[0]_i_1_n_0\ : STD_LOGIC;
  signal \FSM_sequential_state[1]_i_1_n_0\ : STD_LOGIC;
  signal \FSM_sequential_state[2]_i_1_n_0\ : STD_LOGIC;
  signal \FSM_sequential_state[2]_i_2_n_0\ : STD_LOGIC;
  signal \FSM_sequential_state[2]_i_4_n_0\ : STD_LOGIC;
  signal \FSM_sequential_state[2]_i_5_n_0\ : STD_LOGIC;
  signal \FSM_sequential_state[2]_i_6_n_0\ : STD_LOGIC;
  signal \FSM_sequential_state[2]_i_7_n_0\ : STD_LOGIC;
  signal cgs_rst0 : STD_LOGIC;
  signal deglitch_counter0 : STD_LOGIC_VECTOR ( 9 downto 0 );
  signal \deglitch_counter[9]_i_1_n_0\ : STD_LOGIC;
  signal \deglitch_counter[9]_i_4_n_0\ : STD_LOGIC;
  signal deglitch_counter_reg : STD_LOGIC_VECTOR ( 9 downto 0 );
  signal en_align_i_1_n_0 : STD_LOGIC;
  signal good_counter : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal \good_counter[0]_i_1_n_0\ : STD_LOGIC;
  signal \good_counter[1]_i_1_n_0\ : STD_LOGIC;
  signal \good_counter[2]_i_1_n_0\ : STD_LOGIC;
  signal \good_counter[2]_i_2_n_0\ : STD_LOGIC;
  signal \ifs_rst[3]_i_1_n_0\ : STD_LOGIC;
  signal \^latency_monitor_reset\ : STD_LOGIC;
  signal latency_monitor_reset_i_1_n_0 : STD_LOGIC;
  signal sel : STD_LOGIC;
  signal state : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal \state_good__4\ : STD_LOGIC;
  signal \status_state[0]_i_1_n_0\ : STD_LOGIC;
  signal \status_state[1]_i_1_n_0\ : STD_LOGIC;
  signal \^sync\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \sync_n[0]_i_1_n_0\ : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \FSM_sequential_state[2]_i_2\ : label is "soft_lutpair86";
  attribute FSM_ENCODED_STATES : string;
  attribute FSM_ENCODED_STATES of \FSM_sequential_state_reg[0]\ : label is "iSTATE:100,STATE_RESET:000,STATE_WAIT_FOR_PHY:001,STATE_CGS:010,STATE_DEGLITCH:011,";
  attribute FSM_ENCODED_STATES of \FSM_sequential_state_reg[1]\ : label is "iSTATE:100,STATE_RESET:000,STATE_WAIT_FOR_PHY:001,STATE_CGS:010,STATE_DEGLITCH:011,";
  attribute FSM_ENCODED_STATES of \FSM_sequential_state_reg[2]\ : label is "iSTATE:100,STATE_RESET:000,STATE_WAIT_FOR_PHY:001,STATE_CGS:010,STATE_DEGLITCH:011,";
  attribute SOFT_HLUTNM of \deglitch_counter[0]_i_1\ : label is "soft_lutpair87";
  attribute SOFT_HLUTNM of \deglitch_counter[1]_i_1\ : label is "soft_lutpair87";
  attribute SOFT_HLUTNM of \deglitch_counter[2]_i_1\ : label is "soft_lutpair85";
  attribute SOFT_HLUTNM of \deglitch_counter[3]_i_1\ : label is "soft_lutpair85";
  attribute SOFT_HLUTNM of \deglitch_counter[4]_i_1\ : label is "soft_lutpair82";
  attribute SOFT_HLUTNM of \deglitch_counter[7]_i_1\ : label is "soft_lutpair81";
  attribute SOFT_HLUTNM of \deglitch_counter[8]_i_1\ : label is "soft_lutpair81";
  attribute SOFT_HLUTNM of \deglitch_counter[9]_i_4\ : label is "soft_lutpair82";
  attribute SOFT_HLUTNM of \good_counter[0]_i_1\ : label is "soft_lutpair86";
  attribute SOFT_HLUTNM of \good_counter[1]_i_1\ : label is "soft_lutpair84";
  attribute SOFT_HLUTNM of \good_counter[2]_i_1\ : label is "soft_lutpair84";
  attribute SOFT_HLUTNM of latency_monitor_reset_i_1 : label is "soft_lutpair83";
  attribute SOFT_HLUTNM of \status_state[1]_i_1\ : label is "soft_lutpair83";
begin
  latency_monitor_reset <= \^latency_monitor_reset\;
  sync(0) <= \^sync\(0);
\FSM_sequential_state[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FF7F7F7F00800080"
    )
        port map (
      I0 => good_counter(0),
      I1 => good_counter(1),
      I2 => good_counter(2),
      I3 => state(2),
      I4 => \state_good__4\,
      I5 => state(0),
      O => \FSM_sequential_state[0]_i_1_n_0\
    );
\FSM_sequential_state[1]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFDFCFDF00200020"
    )
        port map (
      I0 => state(0),
      I1 => \FSM_sequential_state[2]_i_2_n_0\,
      I2 => good_counter(2),
      I3 => state(2),
      I4 => \state_good__4\,
      I5 => state(1),
      O => \FSM_sequential_state[1]_i_1_n_0\
    );
\FSM_sequential_state[2]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFF0800F0FF0800"
    )
        port map (
      I0 => state(0),
      I1 => state(1),
      I2 => \FSM_sequential_state[2]_i_2_n_0\,
      I3 => good_counter(2),
      I4 => state(2),
      I5 => \state_good__4\,
      O => \FSM_sequential_state[2]_i_1_n_0\
    );
\FSM_sequential_state[2]_i_2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"7"
    )
        port map (
      I0 => good_counter(0),
      I1 => good_counter(1),
      O => \FSM_sequential_state[2]_i_2_n_0\
    );
\FSM_sequential_state[2]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"ABAFFFFFABAFABAF"
    )
        port map (
      I0 => \FSM_sequential_state[2]_i_4_n_0\,
      I1 => state(2),
      I2 => state(1),
      I3 => state(0),
      I4 => \deglitch_counter[9]_i_4_n_0\,
      I5 => \FSM_sequential_state[2]_i_5_n_0\,
      O => \state_good__4\
    );
\FSM_sequential_state[2]_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"A8A8A800"
    )
        port map (
      I0 => \FSM_sequential_state[2]_i_6_n_0\,
      I1 => cgs_ready(0),
      I2 => cfg_lanes_disable(0),
      I3 => cgs_ready(1),
      I4 => cfg_lanes_disable(1),
      O => \FSM_sequential_state[2]_i_4_n_0\
    );
\FSM_sequential_state[2]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000100000"
    )
        port map (
      I0 => deglitch_counter_reg(6),
      I1 => deglitch_counter_reg(7),
      I2 => \FSM_sequential_state[2]_i_7_n_0\,
      I3 => state(2),
      I4 => state(0),
      I5 => deglitch_counter_reg(5),
      O => \FSM_sequential_state[2]_i_5_n_0\
    );
\FSM_sequential_state[2]_i_6\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000E000E000E0000"
    )
        port map (
      I0 => cgs_ready(2),
      I1 => cfg_lanes_disable(2),
      I2 => state(2),
      I3 => state(0),
      I4 => cfg_lanes_disable(3),
      I5 => cgs_ready(3),
      O => \FSM_sequential_state[2]_i_6_n_0\
    );
\FSM_sequential_state[2]_i_7\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => deglitch_counter_reg(8),
      I1 => deglitch_counter_reg(9),
      O => \FSM_sequential_state[2]_i_7_n_0\
    );
\FSM_sequential_state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_sequential_state[0]_i_1_n_0\,
      Q => state(0),
      R => reset
    );
\FSM_sequential_state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_sequential_state[1]_i_1_n_0\,
      Q => state(1),
      R => reset
    );
\FSM_sequential_state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \FSM_sequential_state[2]_i_1_n_0\,
      Q => state(2),
      R => reset
    );
\cgs_rst[3]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"01"
    )
        port map (
      I0 => state(1),
      I1 => state(0),
      I2 => state(2),
      O => cgs_rst0
    );
\cgs_rst_reg[0]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => en_align_i_1_n_0,
      D => cfg_lanes_disable(0),
      Q => Q(0),
      S => cgs_rst0
    );
\cgs_rst_reg[1]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => en_align_i_1_n_0,
      D => cfg_lanes_disable(1),
      Q => Q(1),
      S => cgs_rst0
    );
\cgs_rst_reg[2]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => en_align_i_1_n_0,
      D => cfg_lanes_disable(2),
      Q => Q(2),
      S => cgs_rst0
    );
\cgs_rst_reg[3]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => en_align_i_1_n_0,
      D => cfg_lanes_disable(3),
      Q => Q(3),
      S => cgs_rst0
    );
\deglitch_counter[0]_i_1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => deglitch_counter_reg(0),
      O => deglitch_counter0(0)
    );
\deglitch_counter[1]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => deglitch_counter_reg(1),
      I1 => deglitch_counter_reg(0),
      O => deglitch_counter0(1)
    );
\deglitch_counter[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"A9"
    )
        port map (
      I0 => deglitch_counter_reg(2),
      I1 => deglitch_counter_reg(0),
      I2 => deglitch_counter_reg(1),
      O => deglitch_counter0(2)
    );
\deglitch_counter[3]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AAA9"
    )
        port map (
      I0 => deglitch_counter_reg(3),
      I1 => deglitch_counter_reg(1),
      I2 => deglitch_counter_reg(0),
      I3 => deglitch_counter_reg(2),
      O => deglitch_counter0(3)
    );
\deglitch_counter[4]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAAAAA9"
    )
        port map (
      I0 => deglitch_counter_reg(4),
      I1 => deglitch_counter_reg(2),
      I2 => deglitch_counter_reg(0),
      I3 => deglitch_counter_reg(1),
      I4 => deglitch_counter_reg(3),
      O => deglitch_counter0(4)
    );
\deglitch_counter[5]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAAAAAAAAA9"
    )
        port map (
      I0 => deglitch_counter_reg(5),
      I1 => deglitch_counter_reg(3),
      I2 => deglitch_counter_reg(1),
      I3 => deglitch_counter_reg(0),
      I4 => deglitch_counter_reg(2),
      I5 => deglitch_counter_reg(4),
      O => deglitch_counter0(5)
    );
\deglitch_counter[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"A9"
    )
        port map (
      I0 => deglitch_counter_reg(6),
      I1 => \deglitch_counter[9]_i_4_n_0\,
      I2 => deglitch_counter_reg(5),
      O => deglitch_counter0(6)
    );
\deglitch_counter[7]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AAA9"
    )
        port map (
      I0 => deglitch_counter_reg(7),
      I1 => deglitch_counter_reg(5),
      I2 => \deglitch_counter[9]_i_4_n_0\,
      I3 => deglitch_counter_reg(6),
      O => deglitch_counter0(7)
    );
\deglitch_counter[8]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAAAAA9"
    )
        port map (
      I0 => deglitch_counter_reg(8),
      I1 => deglitch_counter_reg(6),
      I2 => \deglitch_counter[9]_i_4_n_0\,
      I3 => deglitch_counter_reg(5),
      I4 => deglitch_counter_reg(7),
      O => deglitch_counter0(8)
    );
\deglitch_counter[9]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"BF"
    )
        port map (
      I0 => state(2),
      I1 => state(1),
      I2 => state(0),
      O => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter[9]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => \deglitch_counter[9]_i_4_n_0\,
      I1 => deglitch_counter_reg(5),
      I2 => deglitch_counter_reg(6),
      I3 => deglitch_counter_reg(8),
      I4 => deglitch_counter_reg(9),
      I5 => deglitch_counter_reg(7),
      O => sel
    );
\deglitch_counter[9]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFE00000001"
    )
        port map (
      I0 => deglitch_counter_reg(8),
      I1 => deglitch_counter_reg(6),
      I2 => \deglitch_counter[9]_i_4_n_0\,
      I3 => deglitch_counter_reg(5),
      I4 => deglitch_counter_reg(7),
      I5 => deglitch_counter_reg(9),
      O => deglitch_counter0(9)
    );
\deglitch_counter[9]_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFFFFE"
    )
        port map (
      I0 => deglitch_counter_reg(3),
      I1 => deglitch_counter_reg(1),
      I2 => deglitch_counter_reg(0),
      I3 => deglitch_counter_reg(2),
      I4 => deglitch_counter_reg(4),
      O => \deglitch_counter[9]_i_4_n_0\
    );
\deglitch_counter_reg[0]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(0),
      Q => deglitch_counter_reg(0),
      S => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[1]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(1),
      Q => deglitch_counter_reg(1),
      S => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[2]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(2),
      Q => deglitch_counter_reg(2),
      S => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[3]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(3),
      Q => deglitch_counter_reg(3),
      S => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[4]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(4),
      Q => deglitch_counter_reg(4),
      S => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[5]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(5),
      Q => deglitch_counter_reg(5),
      S => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(6),
      Q => deglitch_counter_reg(6),
      R => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[7]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(7),
      Q => deglitch_counter_reg(7),
      R => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[8]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(8),
      Q => deglitch_counter_reg(8),
      R => \deglitch_counter[9]_i_1_n_0\
    );
\deglitch_counter_reg[9]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => sel,
      D => deglitch_counter0(9),
      Q => deglitch_counter_reg(9),
      R => \deglitch_counter[9]_i_1_n_0\
    );
en_align_i_1: unisim.vcomponents.LUT3
    generic map(
      INIT => X"02"
    )
        port map (
      I0 => state(1),
      I1 => state(2),
      I2 => state(0),
      O => en_align_i_1_n_0
    );
en_align_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => en_align_i_1_n_0,
      Q => phy_en_char_align,
      R => '0'
    );
\good_counter[0]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => good_counter(0),
      I1 => \good_counter[2]_i_2_n_0\,
      O => \good_counter[0]_i_1_n_0\
    );
\good_counter[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"06"
    )
        port map (
      I0 => good_counter(1),
      I1 => good_counter(0),
      I2 => \good_counter[2]_i_2_n_0\,
      O => \good_counter[1]_i_1_n_0\
    );
\good_counter[2]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"006A"
    )
        port map (
      I0 => good_counter(2),
      I1 => good_counter(0),
      I2 => good_counter(1),
      I3 => \good_counter[2]_i_2_n_0\,
      O => \good_counter[2]_i_1_n_0\
    );
\good_counter[2]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000000DDD0DD00"
    )
        port map (
      I0 => \FSM_sequential_state[2]_i_5_n_0\,
      I1 => \deglitch_counter[9]_i_4_n_0\,
      I2 => state(0),
      I3 => state(1),
      I4 => state(2),
      I5 => \FSM_sequential_state[2]_i_4_n_0\,
      O => \good_counter[2]_i_2_n_0\
    );
\good_counter_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \good_counter[0]_i_1_n_0\,
      Q => good_counter(0),
      R => '0'
    );
\good_counter_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \good_counter[1]_i_1_n_0\,
      Q => good_counter(1),
      R => '0'
    );
\good_counter_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \good_counter[2]_i_1_n_0\,
      Q => good_counter(2),
      R => '0'
    );
\ifs_rst[3]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0008"
    )
        port map (
      I0 => state(2),
      I1 => \sync_n_reg[0]_0\,
      I2 => state(1),
      I3 => state(0),
      O => \ifs_rst[3]_i_1_n_0\
    );
\ifs_rst_reg[0]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => \ifs_rst[3]_i_1_n_0\,
      D => cfg_lanes_disable(0),
      Q => \ifs_rst_reg[3]_0\(0),
      S => cgs_rst0
    );
\ifs_rst_reg[1]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => \ifs_rst[3]_i_1_n_0\,
      D => cfg_lanes_disable(1),
      Q => \ifs_rst_reg[3]_0\(1),
      S => cgs_rst0
    );
\ifs_rst_reg[2]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => \ifs_rst[3]_i_1_n_0\,
      D => cfg_lanes_disable(2),
      Q => \ifs_rst_reg[3]_0\(2),
      S => cgs_rst0
    );
\ifs_rst_reg[3]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => \ifs_rst[3]_i_1_n_0\,
      D => cfg_lanes_disable(3),
      Q => \ifs_rst_reg[3]_0\(3),
      S => cgs_rst0
    );
latency_monitor_reset_i_1: unisim.vcomponents.LUT5
    generic map(
      INIT => X"CCCCCC4F"
    )
        port map (
      I0 => \sync_n_reg[0]_0\,
      I1 => \^latency_monitor_reset\,
      I2 => state(2),
      I3 => state(0),
      I4 => state(1),
      O => latency_monitor_reset_i_1_n_0
    );
latency_monitor_reset_reg: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => latency_monitor_reset_i_1_n_0,
      Q => \^latency_monitor_reset\,
      R => '0'
    );
\status_state[0]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"B"
    )
        port map (
      I0 => state(2),
      I1 => state(1),
      O => \status_state[0]_i_1_n_0\
    );
\status_state[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"1C"
    )
        port map (
      I0 => state(0),
      I1 => state(1),
      I2 => state(2),
      O => \status_state[1]_i_1_n_0\
    );
\status_state_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \status_state[0]_i_1_n_0\,
      Q => status_ctrl_state(0),
      R => '0'
    );
\status_state_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \status_state[1]_i_1_n_0\,
      Q => status_ctrl_state(1),
      R => '0'
    );
\sync_n[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAF0AAAAEEFF"
    )
        port map (
      I0 => \^sync\(0),
      I1 => \sync_n_reg[0]_0\,
      I2 => cfg_links_disable(0),
      I3 => state(2),
      I4 => state(0),
      I5 => state(1),
      O => \sync_n[0]_i_1_n_0\
    );
\sync_n_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => \sync_n[0]_i_1_n_0\,
      Q => \^sync\(0),
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_scrambler is
  port (
    DIADI : out STD_LOGIC_VECTOR ( 13 downto 0 );
    Q : out STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 28 downto 0 );
    SS : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_scrambler : entity is "jesd204_scrambler";
end jesd204_rx_0_jesd204_scrambler;

architecture STRUCTURE of jesd204_rx_0_jesd204_scrambler is
  signal \^q\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal full_state : STD_LOGIC_VECTOR ( 46 downto 33 );
begin
  Q(0) <= \^q\(0);
\mem_reg_i_10__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(45),
      I2 => full_state(46),
      I3 => D(7),
      O => DIADI(7)
    );
\mem_reg_i_11__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(44),
      I2 => full_state(45),
      I3 => D(6),
      O => DIADI(6)
    );
\mem_reg_i_12__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(43),
      I2 => full_state(44),
      I3 => D(5),
      O => DIADI(5)
    );
\mem_reg_i_13__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(43),
      I2 => full_state(42),
      I3 => D(4),
      O => DIADI(4)
    );
\mem_reg_i_14__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(42),
      I2 => full_state(41),
      I3 => D(3),
      O => DIADI(3)
    );
\mem_reg_i_15__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(41),
      I2 => full_state(40),
      I3 => D(2),
      O => DIADI(2)
    );
\mem_reg_i_16__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(40),
      I2 => full_state(39),
      I3 => D(1),
      O => DIADI(1)
    );
\mem_reg_i_17__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(39),
      I2 => full_state(38),
      I3 => D(0),
      O => DIADI(0)
    );
\mem_reg_i_2__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(38),
      I2 => full_state(37),
      I3 => D(13),
      O => DIADI(13)
    );
\mem_reg_i_3__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(37),
      I2 => full_state(36),
      I3 => D(12),
      O => DIADI(12)
    );
\mem_reg_i_4__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(36),
      I2 => full_state(35),
      I3 => D(11),
      O => DIADI(11)
    );
\mem_reg_i_5__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(35),
      I2 => full_state(34),
      I3 => D(10),
      O => DIADI(10)
    );
\mem_reg_i_6__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(34),
      I2 => full_state(33),
      I3 => D(9),
      O => DIADI(9)
    );
\mem_reg_i_7__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(33),
      I2 => \^q\(0),
      I3 => D(8),
      O => DIADI(8)
    );
\state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(21),
      Q => \^q\(0),
      R => SS(0)
    );
\state_reg[10]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(16),
      Q => full_state(42),
      S => SS(0)
    );
\state_reg[11]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(17),
      Q => full_state(43),
      S => SS(0)
    );
\state_reg[12]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(18),
      Q => full_state(44),
      S => SS(0)
    );
\state_reg[13]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(19),
      Q => full_state(45),
      S => SS(0)
    );
\state_reg[14]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(20),
      Q => full_state(46),
      S => SS(0)
    );
\state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(22),
      Q => full_state(33),
      R => SS(0)
    );
\state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(23),
      Q => full_state(34),
      R => SS(0)
    );
\state_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(24),
      Q => full_state(35),
      R => SS(0)
    );
\state_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(25),
      Q => full_state(36),
      R => SS(0)
    );
\state_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(26),
      Q => full_state(37),
      R => SS(0)
    );
\state_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(27),
      Q => full_state(38),
      R => SS(0)
    );
\state_reg[7]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(28),
      Q => full_state(39),
      S => SS(0)
    );
\state_reg[8]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(14),
      Q => full_state(40),
      S => SS(0)
    );
\state_reg[9]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(15),
      Q => full_state(41),
      S => SS(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_scrambler_10 is
  port (
    DIADI : out STD_LOGIC_VECTOR ( 13 downto 0 );
    Q : out STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 28 downto 0 );
    SS : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_scrambler_10 : entity is "jesd204_scrambler";
end jesd204_rx_0_jesd204_scrambler_10;

architecture STRUCTURE of jesd204_rx_0_jesd204_scrambler_10 is
  signal \^q\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal full_state : STD_LOGIC_VECTOR ( 46 downto 33 );
begin
  Q(0) <= \^q\(0);
\mem_reg_i_10__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(44),
      I2 => full_state(45),
      I3 => D(6),
      O => DIADI(6)
    );
\mem_reg_i_11__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(43),
      I2 => full_state(44),
      I3 => D(5),
      O => DIADI(5)
    );
\mem_reg_i_12__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(43),
      I2 => full_state(42),
      I3 => D(4),
      O => DIADI(4)
    );
\mem_reg_i_13__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(42),
      I2 => full_state(41),
      I3 => D(3),
      O => DIADI(3)
    );
\mem_reg_i_14__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(41),
      I2 => full_state(40),
      I3 => D(2),
      O => DIADI(2)
    );
\mem_reg_i_15__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(40),
      I2 => full_state(39),
      I3 => D(1),
      O => DIADI(1)
    );
\mem_reg_i_16__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(39),
      I2 => full_state(38),
      I3 => D(0),
      O => DIADI(0)
    );
\mem_reg_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(38),
      I2 => full_state(37),
      I3 => D(13),
      O => DIADI(13)
    );
\mem_reg_i_2__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(37),
      I2 => full_state(36),
      I3 => D(12),
      O => DIADI(12)
    );
\mem_reg_i_3__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(36),
      I2 => full_state(35),
      I3 => D(11),
      O => DIADI(11)
    );
\mem_reg_i_4__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(35),
      I2 => full_state(34),
      I3 => D(10),
      O => DIADI(10)
    );
\mem_reg_i_5__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(34),
      I2 => full_state(33),
      I3 => D(9),
      O => DIADI(9)
    );
\mem_reg_i_6__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(33),
      I2 => \^q\(0),
      I3 => D(8),
      O => DIADI(8)
    );
\mem_reg_i_9__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(45),
      I2 => full_state(46),
      I3 => D(7),
      O => DIADI(7)
    );
\state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(21),
      Q => \^q\(0),
      R => SS(0)
    );
\state_reg[10]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(16),
      Q => full_state(42),
      S => SS(0)
    );
\state_reg[11]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(17),
      Q => full_state(43),
      S => SS(0)
    );
\state_reg[12]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(18),
      Q => full_state(44),
      S => SS(0)
    );
\state_reg[13]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(19),
      Q => full_state(45),
      S => SS(0)
    );
\state_reg[14]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(20),
      Q => full_state(46),
      S => SS(0)
    );
\state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(22),
      Q => full_state(33),
      R => SS(0)
    );
\state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(23),
      Q => full_state(34),
      R => SS(0)
    );
\state_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(24),
      Q => full_state(35),
      R => SS(0)
    );
\state_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(25),
      Q => full_state(36),
      R => SS(0)
    );
\state_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(26),
      Q => full_state(37),
      R => SS(0)
    );
\state_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(27),
      Q => full_state(38),
      R => SS(0)
    );
\state_reg[7]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(28),
      Q => full_state(39),
      S => SS(0)
    );
\state_reg[8]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(14),
      Q => full_state(40),
      S => SS(0)
    );
\state_reg[9]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(15),
      Q => full_state(41),
      S => SS(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_scrambler_15 is
  port (
    DIADI : out STD_LOGIC_VECTOR ( 13 downto 0 );
    Q : out STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 28 downto 0 );
    SR : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_scrambler_15 : entity is "jesd204_scrambler";
end jesd204_rx_0_jesd204_scrambler_15;

architecture STRUCTURE of jesd204_rx_0_jesd204_scrambler_15 is
  signal \^q\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal full_state : STD_LOGIC_VECTOR ( 46 downto 33 );
begin
  Q(0) <= \^q\(0);
mem_reg_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(38),
      I2 => full_state(37),
      I3 => D(13),
      O => DIADI(13)
    );
mem_reg_i_10: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(44),
      I2 => full_state(45),
      I3 => D(6),
      O => DIADI(6)
    );
mem_reg_i_11: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(43),
      I2 => full_state(44),
      I3 => D(5),
      O => DIADI(5)
    );
mem_reg_i_12: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(43),
      I2 => full_state(42),
      I3 => D(4),
      O => DIADI(4)
    );
mem_reg_i_13: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(42),
      I2 => full_state(41),
      I3 => D(3),
      O => DIADI(3)
    );
mem_reg_i_14: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(41),
      I2 => full_state(40),
      I3 => D(2),
      O => DIADI(2)
    );
mem_reg_i_15: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(40),
      I2 => full_state(39),
      I3 => D(1),
      O => DIADI(1)
    );
mem_reg_i_16: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(39),
      I2 => full_state(38),
      I3 => D(0),
      O => DIADI(0)
    );
mem_reg_i_2: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(37),
      I2 => full_state(36),
      I3 => D(12),
      O => DIADI(12)
    );
mem_reg_i_3: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(36),
      I2 => full_state(35),
      I3 => D(11),
      O => DIADI(11)
    );
mem_reg_i_4: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(35),
      I2 => full_state(34),
      I3 => D(10),
      O => DIADI(10)
    );
mem_reg_i_5: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(34),
      I2 => full_state(33),
      I3 => D(9),
      O => DIADI(9)
    );
mem_reg_i_6: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(33),
      I2 => \^q\(0),
      I3 => D(8),
      O => DIADI(8)
    );
mem_reg_i_9: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(45),
      I2 => full_state(46),
      I3 => D(7),
      O => DIADI(7)
    );
\state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(21),
      Q => \^q\(0),
      R => SR(0)
    );
\state_reg[10]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(16),
      Q => full_state(42),
      S => SR(0)
    );
\state_reg[11]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(17),
      Q => full_state(43),
      S => SR(0)
    );
\state_reg[12]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(18),
      Q => full_state(44),
      S => SR(0)
    );
\state_reg[13]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(19),
      Q => full_state(45),
      S => SR(0)
    );
\state_reg[14]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(20),
      Q => full_state(46),
      S => SR(0)
    );
\state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(22),
      Q => full_state(33),
      R => SR(0)
    );
\state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(23),
      Q => full_state(34),
      R => SR(0)
    );
\state_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(24),
      Q => full_state(35),
      R => SR(0)
    );
\state_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(25),
      Q => full_state(36),
      R => SR(0)
    );
\state_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(26),
      Q => full_state(37),
      R => SR(0)
    );
\state_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(27),
      Q => full_state(38),
      R => SR(0)
    );
\state_reg[7]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(28),
      Q => full_state(39),
      S => SR(0)
    );
\state_reg[8]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(14),
      Q => full_state(40),
      S => SR(0)
    );
\state_reg[9]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(15),
      Q => full_state(41),
      S => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_scrambler_5 is
  port (
    DIADI : out STD_LOGIC_VECTOR ( 13 downto 0 );
    Q : out STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 28 downto 0 );
    SR : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_scrambler_5 : entity is "jesd204_scrambler";
end jesd204_rx_0_jesd204_scrambler_5;

architecture STRUCTURE of jesd204_rx_0_jesd204_scrambler_5 is
  signal \^q\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal full_state : STD_LOGIC_VECTOR ( 46 downto 33 );
begin
  Q(0) <= \^q\(0);
\mem_reg_i_10__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(44),
      I2 => full_state(45),
      I3 => D(6),
      O => DIADI(6)
    );
\mem_reg_i_11__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(43),
      I2 => full_state(44),
      I3 => D(5),
      O => DIADI(5)
    );
\mem_reg_i_12__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(43),
      I2 => full_state(42),
      I3 => D(4),
      O => DIADI(4)
    );
\mem_reg_i_13__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(42),
      I2 => full_state(41),
      I3 => D(3),
      O => DIADI(3)
    );
\mem_reg_i_14__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(41),
      I2 => full_state(40),
      I3 => D(2),
      O => DIADI(2)
    );
\mem_reg_i_15__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(40),
      I2 => full_state(39),
      I3 => D(1),
      O => DIADI(1)
    );
\mem_reg_i_16__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(39),
      I2 => full_state(38),
      I3 => D(0),
      O => DIADI(0)
    );
\mem_reg_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(38),
      I2 => full_state(37),
      I3 => D(13),
      O => DIADI(13)
    );
\mem_reg_i_2__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(37),
      I2 => full_state(36),
      I3 => D(12),
      O => DIADI(12)
    );
\mem_reg_i_3__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(36),
      I2 => full_state(35),
      I3 => D(11),
      O => DIADI(11)
    );
\mem_reg_i_4__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(35),
      I2 => full_state(34),
      I3 => D(10),
      O => DIADI(10)
    );
\mem_reg_i_5__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(34),
      I2 => full_state(33),
      I3 => D(9),
      O => DIADI(9)
    );
\mem_reg_i_6__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(33),
      I2 => \^q\(0),
      I3 => D(8),
      O => DIADI(8)
    );
\mem_reg_i_9__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"EB14"
    )
        port map (
      I0 => cfg_disable_scrambler,
      I1 => full_state(45),
      I2 => full_state(46),
      I3 => D(7),
      O => DIADI(7)
    );
\state_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(21),
      Q => \^q\(0),
      R => SR(0)
    );
\state_reg[10]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(16),
      Q => full_state(42),
      S => SR(0)
    );
\state_reg[11]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(17),
      Q => full_state(43),
      S => SR(0)
    );
\state_reg[12]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(18),
      Q => full_state(44),
      S => SR(0)
    );
\state_reg[13]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(19),
      Q => full_state(45),
      S => SR(0)
    );
\state_reg[14]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(20),
      Q => full_state(46),
      S => SR(0)
    );
\state_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(22),
      Q => full_state(33),
      R => SR(0)
    );
\state_reg[2]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(23),
      Q => full_state(34),
      R => SR(0)
    );
\state_reg[3]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(24),
      Q => full_state(35),
      R => SR(0)
    );
\state_reg[4]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(25),
      Q => full_state(36),
      R => SR(0)
    );
\state_reg[5]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(26),
      Q => full_state(37),
      R => SR(0)
    );
\state_reg[6]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(27),
      Q => full_state(38),
      R => SR(0)
    );
\state_reg[7]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(28),
      Q => full_state(39),
      S => SR(0)
    );
\state_reg[8]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(14),
      Q => full_state(40),
      S => SR(0)
    );
\state_reg[9]\: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => D(15),
      Q => full_state(41),
      S => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity \jesd204_rx_0_pipeline_stage__parameterized2\ is
  port (
    ifs_ready_reg : out STD_LOGIC;
    charisk28 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ifs_ready_reg_0 : out STD_LOGIC;
    charisk28_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ifs_ready_reg_1 : out STD_LOGIC;
    charisk28_1 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ifs_ready_reg_2 : out STD_LOGIC;
    charisk28_2 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    prev_was_last0 : out STD_LOGIC;
    D : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_dly_reg[187]_0\ : out STD_LOGIC_VECTOR ( 127 downto 0 );
    \in_dly_reg[23]_0\ : out STD_LOGIC_VECTOR ( 3 downto 0 );
    \FSM_onehot_state_reg[0]\ : out STD_LOGIC;
    frame_align : out STD_LOGIC_VECTOR ( 0 to 0 );
    cgs_beat_has_error : out STD_LOGIC;
    prev_was_last0_3 : out STD_LOGIC;
    \in_dly_reg[107]_0\ : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_dly_reg[27]_0\ : out STD_LOGIC_VECTOR ( 3 downto 0 );
    \FSM_onehot_state_reg[0]_0\ : out STD_LOGIC;
    frame_align_4 : out STD_LOGIC_VECTOR ( 0 to 0 );
    cgs_beat_has_error_5 : out STD_LOGIC;
    prev_was_last0_6 : out STD_LOGIC;
    \in_dly_reg[139]_0\ : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_dly_reg[31]_0\ : out STD_LOGIC_VECTOR ( 3 downto 0 );
    \FSM_onehot_state_reg[0]_1\ : out STD_LOGIC;
    frame_align_7 : out STD_LOGIC_VECTOR ( 0 to 0 );
    cgs_beat_has_error_8 : out STD_LOGIC;
    prev_was_last0_9 : out STD_LOGIC;
    \in_dly_reg[171]_0\ : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_dly_reg[35]_0\ : out STD_LOGIC_VECTOR ( 3 downto 0 );
    \FSM_onehot_state_reg[0]_2\ : out STD_LOGIC;
    frame_align_10 : out STD_LOGIC_VECTOR ( 0 to 0 );
    cgs_beat_has_error_11 : out STD_LOGIC;
    ifs_ready_reg_3 : out STD_LOGIC;
    ifs_ready_reg_4 : out STD_LOGIC;
    ifs_ready_reg_5 : out STD_LOGIC;
    ifs_ready_reg_6 : out STD_LOGIC;
    ifs_ready : in STD_LOGIC_VECTOR ( 3 downto 0 );
    \frame_align_reg[0]\ : in STD_LOGIC;
    \frame_align_reg[0]_0\ : in STD_LOGIC;
    \frame_align_reg[0]_1\ : in STD_LOGIC;
    \frame_align_reg[0]_2\ : in STD_LOGIC;
    Q : in STD_LOGIC_VECTOR ( 0 to 0 );
    \ilas_config_data_reg[24]\ : in STD_LOGIC;
    \ilas_config_data_reg[31]\ : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ctrl_err_statistics_mask : in STD_LOGIC_VECTOR ( 2 downto 0 );
    \FSM_onehot_state_reg[0]_3\ : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_4\ : in STD_LOGIC;
    \FSM_onehot_state[2]_i_2_0\ : in STD_LOGIC;
    \FSM_onehot_state[2]_i_2_1\ : in STD_LOGIC;
    prev_was_last_reg : in STD_LOGIC_VECTOR ( 0 to 0 );
    \ilas_config_data_reg[24]_0\ : in STD_LOGIC;
    \ilas_config_data_reg[31]_0\ : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \FSM_onehot_state_reg[0]_5\ : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_6\ : in STD_LOGIC;
    \FSM_onehot_state[2]_i_2__0_0\ : in STD_LOGIC;
    \FSM_onehot_state[2]_i_2__0_1\ : in STD_LOGIC;
    prev_was_last_reg_0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    \ilas_config_data_reg[24]_1\ : in STD_LOGIC;
    \ilas_config_data_reg[31]_1\ : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \FSM_onehot_state_reg[0]_7\ : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_8\ : in STD_LOGIC;
    \FSM_onehot_state[2]_i_2__1_0\ : in STD_LOGIC;
    \FSM_onehot_state[2]_i_2__1_1\ : in STD_LOGIC;
    prev_was_last_reg_1 : in STD_LOGIC_VECTOR ( 0 to 0 );
    \ilas_config_data_reg[24]_2\ : in STD_LOGIC;
    \ilas_config_data_reg[31]_2\ : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \FSM_onehot_state_reg[0]_9\ : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_10\ : in STD_LOGIC;
    \FSM_onehot_state[2]_i_2__2_0\ : in STD_LOGIC;
    \FSM_onehot_state[2]_i_2__2_1\ : in STD_LOGIC;
    ifs_ready_reg_7 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    \in_dly_reg[187]_1\ : in STD_LOGIC_VECTOR ( 175 downto 0 );
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of \jesd204_rx_0_pipeline_stage__parameterized2\ : entity is "pipeline_stage";
end \jesd204_rx_0_pipeline_stage__parameterized2\;

architecture STRUCTURE of \jesd204_rx_0_pipeline_stage__parameterized2\ is
  signal \^d\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \FSM_onehot_state[2]_i_10__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_10__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_10__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_10_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_11__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_11__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_11__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_11_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_12__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_12__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_12__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_12_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_4__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_4__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_4__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_4_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_5__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_5__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_5__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_5_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_7__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_7__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_7__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_7_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_8__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_8__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_8__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_8_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_9__0_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_9__1_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_9__2_n_0\ : STD_LOGIC;
  signal \FSM_onehot_state[2]_i_9_n_0\ : STD_LOGIC;
  signal \^cgs_beat_has_error\ : STD_LOGIC;
  signal \^cgs_beat_has_error_11\ : STD_LOGIC;
  signal \^cgs_beat_has_error_5\ : STD_LOGIC;
  signal \^cgs_beat_has_error_8\ : STD_LOGIC;
  signal \^charisk28\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \^charisk28_0\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \^charisk28_1\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \^charisk28_2\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \frame_align[0]_i_2__0_n_0\ : STD_LOGIC;
  signal \frame_align[0]_i_2__1_n_0\ : STD_LOGIC;
  signal \frame_align[0]_i_2__2_n_0\ : STD_LOGIC;
  signal \frame_align[0]_i_2_n_0\ : STD_LOGIC;
  signal \frame_align[1]_i_3__0_n_0\ : STD_LOGIC;
  signal \frame_align[1]_i_3__1_n_0\ : STD_LOGIC;
  signal \frame_align[1]_i_3__2_n_0\ : STD_LOGIC;
  signal \frame_align[1]_i_3_n_0\ : STD_LOGIC;
  signal \ifs_ready_i_3__0_n_0\ : STD_LOGIC;
  signal \ifs_ready_i_3__1_n_0\ : STD_LOGIC;
  signal \ifs_ready_i_3__2_n_0\ : STD_LOGIC;
  signal ifs_ready_i_3_n_0 : STD_LOGIC;
  signal \in_charisk_d1[0]_i_2__0_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[0]_i_2__1_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[0]_i_2__2_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[0]_i_2_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[1]_i_2__0_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[1]_i_2__1_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[1]_i_2__2_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[1]_i_2_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[2]_i_2__0_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[2]_i_2__1_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[2]_i_2__2_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[2]_i_2_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[3]_i_2__0_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[3]_i_2__1_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[3]_i_2__2_n_0\ : STD_LOGIC;
  signal \in_charisk_d1[3]_i_2_n_0\ : STD_LOGIC;
  signal \^in_dly_reg[107]_0\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \^in_dly_reg[139]_0\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \^in_dly_reg[171]_0\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \^in_dly_reg[187]_0\ : STD_LOGIC_VECTOR ( 127 downto 0 );
  signal \mode_8b10b.gen_lane[0].i_lane/cgs_beat_is_cgs\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \mode_8b10b.gen_lane[0].i_lane/charisk28_aligned_s\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \mode_8b10b.gen_lane[1].i_lane/cgs_beat_is_cgs\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \mode_8b10b.gen_lane[1].i_lane/charisk28_aligned_s\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \mode_8b10b.gen_lane[2].i_lane/cgs_beat_is_cgs\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \mode_8b10b.gen_lane[2].i_lane/charisk28_aligned_s\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \mode_8b10b.gen_lane[3].i_lane/cgs_beat_is_cgs\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \mode_8b10b.gen_lane[3].i_lane/charisk28_aligned_s\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \phy_char_err[0]_i_2__0_n_0\ : STD_LOGIC;
  signal \phy_char_err[0]_i_2__1_n_0\ : STD_LOGIC;
  signal \phy_char_err[0]_i_2__2_n_0\ : STD_LOGIC;
  signal \phy_char_err[0]_i_2_n_0\ : STD_LOGIC;
  signal \phy_char_err[1]_i_2__0_n_0\ : STD_LOGIC;
  signal \phy_char_err[1]_i_2__1_n_0\ : STD_LOGIC;
  signal \phy_char_err[1]_i_2__2_n_0\ : STD_LOGIC;
  signal \phy_char_err[1]_i_2_n_0\ : STD_LOGIC;
  signal \phy_char_err[2]_i_2__0_n_0\ : STD_LOGIC;
  signal \phy_char_err[2]_i_2__1_n_0\ : STD_LOGIC;
  signal \phy_char_err[2]_i_2__2_n_0\ : STD_LOGIC;
  signal \phy_char_err[2]_i_2_n_0\ : STD_LOGIC;
  signal \phy_char_err[3]_i_3__0_n_0\ : STD_LOGIC;
  signal \phy_char_err[3]_i_3__1_n_0\ : STD_LOGIC;
  signal \phy_char_err[3]_i_3__2_n_0\ : STD_LOGIC;
  signal \phy_char_err[3]_i_3_n_0\ : STD_LOGIC;
  signal phy_charisk_r : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal phy_disperr_r : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal phy_notintable_r : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal \prev_was_last_i_3__0_n_0\ : STD_LOGIC;
  signal \prev_was_last_i_3__1_n_0\ : STD_LOGIC;
  signal \prev_was_last_i_3__2_n_0\ : STD_LOGIC;
  signal prev_was_last_i_3_n_0 : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \FSM_onehot_state[2]_i_11\ : label is "soft_lutpair12";
  attribute SOFT_HLUTNM of \FSM_onehot_state[2]_i_11__0\ : label is "soft_lutpair11";
  attribute SOFT_HLUTNM of \FSM_onehot_state[2]_i_11__1\ : label is "soft_lutpair9";
  attribute SOFT_HLUTNM of \FSM_onehot_state[2]_i_11__2\ : label is "soft_lutpair13";
  attribute SOFT_HLUTNM of \FSM_onehot_state[2]_i_9\ : label is "soft_lutpair24";
  attribute SOFT_HLUTNM of \FSM_onehot_state[2]_i_9__0\ : label is "soft_lutpair25";
  attribute SOFT_HLUTNM of \FSM_onehot_state[2]_i_9__1\ : label is "soft_lutpair23";
  attribute SOFT_HLUTNM of \FSM_onehot_state[2]_i_9__2\ : label is "soft_lutpair26";
  attribute SOFT_HLUTNM of \frame_align[1]_i_3\ : label is "soft_lutpair24";
  attribute SOFT_HLUTNM of \frame_align[1]_i_3__0\ : label is "soft_lutpair25";
  attribute SOFT_HLUTNM of \frame_align[1]_i_3__1\ : label is "soft_lutpair23";
  attribute SOFT_HLUTNM of \frame_align[1]_i_3__2\ : label is "soft_lutpair26";
  attribute SOFT_HLUTNM of ifs_ready_i_3 : label is "soft_lutpair12";
  attribute SOFT_HLUTNM of \ifs_ready_i_3__0\ : label is "soft_lutpair11";
  attribute SOFT_HLUTNM of \ifs_ready_i_3__1\ : label is "soft_lutpair9";
  attribute SOFT_HLUTNM of \ifs_ready_i_3__2\ : label is "soft_lutpair13";
  attribute SOFT_HLUTNM of \in_charisk_d1[0]_i_1\ : label is "soft_lutpair5";
  attribute SOFT_HLUTNM of \in_charisk_d1[0]_i_1__0\ : label is "soft_lutpair16";
  attribute SOFT_HLUTNM of \in_charisk_d1[0]_i_1__1\ : label is "soft_lutpair10";
  attribute SOFT_HLUTNM of \in_charisk_d1[0]_i_1__2\ : label is "soft_lutpair20";
  attribute SOFT_HLUTNM of \in_charisk_d1[1]_i_1\ : label is "soft_lutpair19";
  attribute SOFT_HLUTNM of \in_charisk_d1[1]_i_1__0\ : label is "soft_lutpair15";
  attribute SOFT_HLUTNM of \in_charisk_d1[1]_i_1__1\ : label is "soft_lutpair3";
  attribute SOFT_HLUTNM of \in_charisk_d1[1]_i_1__2\ : label is "soft_lutpair22";
  attribute SOFT_HLUTNM of \in_charisk_d1[2]_i_1\ : label is "soft_lutpair17";
  attribute SOFT_HLUTNM of \in_charisk_d1[2]_i_1__0\ : label is "soft_lutpair7";
  attribute SOFT_HLUTNM of \in_charisk_d1[2]_i_1__1\ : label is "soft_lutpair6";
  attribute SOFT_HLUTNM of \in_charisk_d1[2]_i_1__2\ : label is "soft_lutpair21";
  attribute SOFT_HLUTNM of \in_charisk_d1[3]_i_1\ : label is "soft_lutpair18";
  attribute SOFT_HLUTNM of \in_charisk_d1[3]_i_1__0\ : label is "soft_lutpair4";
  attribute SOFT_HLUTNM of \in_charisk_d1[3]_i_1__1\ : label is "soft_lutpair8";
  attribute SOFT_HLUTNM of \in_charisk_d1[3]_i_1__2\ : label is "soft_lutpair14";
  attribute SHREG_EXTRACT : string;
  attribute SHREG_EXTRACT of \in_dly_reg[100]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[101]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[102]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[103]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[104]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[105]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[106]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[107]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[108]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[109]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[10]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[110]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[111]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[112]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[113]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[114]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[115]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[116]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[117]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[118]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[119]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[11]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[120]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[121]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[122]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[123]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[124]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[125]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[126]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[127]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[128]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[129]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[12]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[130]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[131]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[132]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[133]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[134]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[135]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[136]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[137]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[138]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[139]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[13]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[140]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[141]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[142]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[143]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[144]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[145]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[146]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[147]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[148]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[149]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[14]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[150]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[151]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[152]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[153]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[154]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[155]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[156]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[157]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[158]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[159]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[15]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[160]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[161]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[162]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[163]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[164]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[165]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[166]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[167]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[168]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[169]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[16]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[170]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[171]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[172]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[173]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[174]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[175]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[176]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[177]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[178]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[179]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[17]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[180]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[181]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[182]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[183]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[184]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[185]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[186]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[187]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[18]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[19]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[20]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[21]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[22]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[23]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[24]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[25]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[26]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[27]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[28]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[29]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[30]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[31]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[32]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[33]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[34]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[35]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[36]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[37]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[38]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[39]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[40]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[41]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[42]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[43]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[44]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[45]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[46]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[47]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[48]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[49]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[4]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[50]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[51]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[5]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[60]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[61]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[62]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[63]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[64]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[65]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[66]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[67]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[68]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[69]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[6]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[70]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[71]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[72]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[73]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[74]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[75]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[76]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[77]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[78]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[79]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[7]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[80]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[81]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[82]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[83]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[84]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[85]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[86]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[87]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[88]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[89]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[8]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[90]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[91]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[92]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[93]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[94]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[95]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[96]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[97]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[98]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[99]\ : label is "no";
  attribute SHREG_EXTRACT of \in_dly_reg[9]\ : label is "no";
  attribute SOFT_HLUTNM of \phy_char_err[0]_i_2\ : label is "soft_lutpair5";
  attribute SOFT_HLUTNM of \phy_char_err[0]_i_2__0\ : label is "soft_lutpair16";
  attribute SOFT_HLUTNM of \phy_char_err[0]_i_2__1\ : label is "soft_lutpair10";
  attribute SOFT_HLUTNM of \phy_char_err[0]_i_2__2\ : label is "soft_lutpair20";
  attribute SOFT_HLUTNM of \phy_char_err[1]_i_2\ : label is "soft_lutpair19";
  attribute SOFT_HLUTNM of \phy_char_err[1]_i_2__0\ : label is "soft_lutpair15";
  attribute SOFT_HLUTNM of \phy_char_err[1]_i_2__1\ : label is "soft_lutpair3";
  attribute SOFT_HLUTNM of \phy_char_err[1]_i_2__2\ : label is "soft_lutpair22";
  attribute SOFT_HLUTNM of \phy_char_err[2]_i_2\ : label is "soft_lutpair17";
  attribute SOFT_HLUTNM of \phy_char_err[2]_i_2__0\ : label is "soft_lutpair7";
  attribute SOFT_HLUTNM of \phy_char_err[2]_i_2__1\ : label is "soft_lutpair6";
  attribute SOFT_HLUTNM of \phy_char_err[2]_i_2__2\ : label is "soft_lutpair21";
  attribute SOFT_HLUTNM of \phy_char_err[3]_i_3\ : label is "soft_lutpair18";
  attribute SOFT_HLUTNM of \phy_char_err[3]_i_3__0\ : label is "soft_lutpair4";
  attribute SOFT_HLUTNM of \phy_char_err[3]_i_3__1\ : label is "soft_lutpair8";
  attribute SOFT_HLUTNM of \phy_char_err[3]_i_3__2\ : label is "soft_lutpair14";
begin
  D(7 downto 0) <= \^d\(7 downto 0);
  cgs_beat_has_error <= \^cgs_beat_has_error\;
  cgs_beat_has_error_11 <= \^cgs_beat_has_error_11\;
  cgs_beat_has_error_5 <= \^cgs_beat_has_error_5\;
  cgs_beat_has_error_8 <= \^cgs_beat_has_error_8\;
  charisk28(3 downto 0) <= \^charisk28\(3 downto 0);
  charisk28_0(3 downto 0) <= \^charisk28_0\(3 downto 0);
  charisk28_1(3 downto 0) <= \^charisk28_1\(3 downto 0);
  charisk28_2(3 downto 0) <= \^charisk28_2\(3 downto 0);
  \in_dly_reg[107]_0\(7 downto 0) <= \^in_dly_reg[107]_0\(7 downto 0);
  \in_dly_reg[139]_0\(7 downto 0) <= \^in_dly_reg[139]_0\(7 downto 0);
  \in_dly_reg[171]_0\(7 downto 0) <= \^in_dly_reg[171]_0\(7 downto 0);
  \in_dly_reg[187]_0\(127 downto 0) <= \^in_dly_reg[187]_0\(127 downto 0);
\FSM_onehot_state[2]_i_10\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(2),
      I1 => phy_disperr_r(2),
      O => \FSM_onehot_state[2]_i_10_n_0\
    );
\FSM_onehot_state[2]_i_10__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(6),
      I1 => phy_disperr_r(6),
      O => \FSM_onehot_state[2]_i_10__0_n_0\
    );
\FSM_onehot_state[2]_i_10__1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(10),
      I1 => phy_disperr_r(10),
      O => \FSM_onehot_state[2]_i_10__1_n_0\
    );
\FSM_onehot_state[2]_i_10__2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(14),
      I1 => phy_disperr_r(14),
      O => \FSM_onehot_state[2]_i_10__2_n_0\
    );
\FSM_onehot_state[2]_i_11\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(22),
      I1 => \^in_dly_reg[187]_0\(21),
      I2 => phy_charisk_r(3),
      O => \FSM_onehot_state[2]_i_11_n_0\
    );
\FSM_onehot_state[2]_i_11__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(54),
      I1 => \^in_dly_reg[187]_0\(53),
      I2 => phy_charisk_r(7),
      O => \FSM_onehot_state[2]_i_11__0_n_0\
    );
\FSM_onehot_state[2]_i_11__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(86),
      I1 => \^in_dly_reg[187]_0\(85),
      I2 => phy_charisk_r(11),
      O => \FSM_onehot_state[2]_i_11__1_n_0\
    );
\FSM_onehot_state[2]_i_11__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(118),
      I1 => \^in_dly_reg[187]_0\(117),
      I2 => phy_charisk_r(15),
      O => \FSM_onehot_state[2]_i_11__2_n_0\
    );
\FSM_onehot_state[2]_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000080"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(23),
      I1 => \^in_dly_reg[187]_0\(29),
      I2 => \^in_dly_reg[187]_0\(31),
      I3 => \^in_dly_reg[187]_0\(30),
      I4 => phy_disperr_r(3),
      I5 => phy_notintable_r(3),
      O => \FSM_onehot_state[2]_i_12_n_0\
    );
\FSM_onehot_state[2]_i_12__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000080"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(55),
      I1 => \^in_dly_reg[187]_0\(61),
      I2 => \^in_dly_reg[187]_0\(63),
      I3 => \^in_dly_reg[187]_0\(62),
      I4 => phy_disperr_r(7),
      I5 => phy_notintable_r(7),
      O => \FSM_onehot_state[2]_i_12__0_n_0\
    );
\FSM_onehot_state[2]_i_12__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000080"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(87),
      I1 => \^in_dly_reg[187]_0\(93),
      I2 => \^in_dly_reg[187]_0\(95),
      I3 => \^in_dly_reg[187]_0\(94),
      I4 => phy_disperr_r(11),
      I5 => phy_notintable_r(11),
      O => \FSM_onehot_state[2]_i_12__1_n_0\
    );
\FSM_onehot_state[2]_i_12__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000080"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(119),
      I1 => \^in_dly_reg[187]_0\(125),
      I2 => \^in_dly_reg[187]_0\(127),
      I3 => \^in_dly_reg[187]_0\(126),
      I4 => phy_disperr_r(15),
      I5 => phy_notintable_r(15),
      O => \FSM_onehot_state[2]_i_12__2_n_0\
    );
\FSM_onehot_state[2]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFEAAAAAAA"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_4_n_0\,
      I1 => \FSM_onehot_state[2]_i_5_n_0\,
      I2 => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(0),
      I3 => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(1),
      I4 => \FSM_onehot_state_reg[0]_3\,
      I5 => \FSM_onehot_state_reg[0]_4\,
      O => \FSM_onehot_state_reg[0]\
    );
\FSM_onehot_state[2]_i_2__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFEAAAAAAA"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_4__0_n_0\,
      I1 => \FSM_onehot_state[2]_i_5__0_n_0\,
      I2 => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(0),
      I3 => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(1),
      I4 => \FSM_onehot_state_reg[0]_5\,
      I5 => \FSM_onehot_state_reg[0]_6\,
      O => \FSM_onehot_state_reg[0]_0\
    );
\FSM_onehot_state[2]_i_2__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFEAAAAAAA"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_4__1_n_0\,
      I1 => \FSM_onehot_state[2]_i_5__1_n_0\,
      I2 => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(0),
      I3 => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(1),
      I4 => \FSM_onehot_state_reg[0]_7\,
      I5 => \FSM_onehot_state_reg[0]_8\,
      O => \FSM_onehot_state_reg[0]_1\
    );
\FSM_onehot_state[2]_i_2__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFEAAAAAAA"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_4__2_n_0\,
      I1 => \FSM_onehot_state[2]_i_5__2_n_0\,
      I2 => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(0),
      I3 => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(1),
      I4 => \FSM_onehot_state_reg[0]_9\,
      I5 => \FSM_onehot_state_reg[0]_10\,
      O => \FSM_onehot_state_reg[0]_2\
    );
\FSM_onehot_state[2]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => phy_notintable_r(2),
      I1 => phy_disperr_r(2),
      I2 => \FSM_onehot_state[2]_i_7_n_0\,
      I3 => \FSM_onehot_state[2]_i_8_n_0\,
      I4 => phy_notintable_r(1),
      I5 => phy_disperr_r(1),
      O => \^cgs_beat_has_error\
    );
\FSM_onehot_state[2]_i_3__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => phy_notintable_r(6),
      I1 => phy_disperr_r(6),
      I2 => \FSM_onehot_state[2]_i_7__0_n_0\,
      I3 => \FSM_onehot_state[2]_i_8__0_n_0\,
      I4 => phy_notintable_r(5),
      I5 => phy_disperr_r(5),
      O => \^cgs_beat_has_error_5\
    );
\FSM_onehot_state[2]_i_3__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => phy_notintable_r(10),
      I1 => phy_disperr_r(10),
      I2 => \FSM_onehot_state[2]_i_7__1_n_0\,
      I3 => \FSM_onehot_state[2]_i_8__1_n_0\,
      I4 => phy_notintable_r(9),
      I5 => phy_disperr_r(9),
      O => \^cgs_beat_has_error_8\
    );
\FSM_onehot_state[2]_i_3__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => phy_notintable_r(14),
      I1 => phy_disperr_r(14),
      I2 => \FSM_onehot_state[2]_i_7__2_n_0\,
      I3 => \FSM_onehot_state[2]_i_8__2_n_0\,
      I4 => phy_notintable_r(13),
      I5 => phy_disperr_r(13),
      O => \^cgs_beat_has_error_11\
    );
\FSM_onehot_state[2]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"EAAAAAAAAAAAABA8"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_2_0\,
      I1 => \FSM_onehot_state[2]_i_9_n_0\,
      I2 => \FSM_onehot_state[2]_i_8_n_0\,
      I3 => \FSM_onehot_state[2]_i_2_1\,
      I4 => \FSM_onehot_state[2]_i_10_n_0\,
      I5 => \FSM_onehot_state[2]_i_7_n_0\,
      O => \FSM_onehot_state[2]_i_4_n_0\
    );
\FSM_onehot_state[2]_i_4__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"EAAAAAAAAAAAABA8"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_2__0_0\,
      I1 => \FSM_onehot_state[2]_i_9__0_n_0\,
      I2 => \FSM_onehot_state[2]_i_8__0_n_0\,
      I3 => \FSM_onehot_state[2]_i_2__0_1\,
      I4 => \FSM_onehot_state[2]_i_10__0_n_0\,
      I5 => \FSM_onehot_state[2]_i_7__0_n_0\,
      O => \FSM_onehot_state[2]_i_4__0_n_0\
    );
\FSM_onehot_state[2]_i_4__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"EAAAAAAAAAAAABA8"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_2__1_0\,
      I1 => \FSM_onehot_state[2]_i_9__1_n_0\,
      I2 => \FSM_onehot_state[2]_i_8__1_n_0\,
      I3 => \FSM_onehot_state[2]_i_2__1_1\,
      I4 => \FSM_onehot_state[2]_i_10__1_n_0\,
      I5 => \FSM_onehot_state[2]_i_7__1_n_0\,
      O => \FSM_onehot_state[2]_i_4__1_n_0\
    );
\FSM_onehot_state[2]_i_4__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"EAAAAAAAAAAAABA8"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_2__2_0\,
      I1 => \FSM_onehot_state[2]_i_9__2_n_0\,
      I2 => \FSM_onehot_state[2]_i_8__2_n_0\,
      I3 => \FSM_onehot_state[2]_i_2__2_1\,
      I4 => \FSM_onehot_state[2]_i_10__2_n_0\,
      I5 => \FSM_onehot_state[2]_i_7__2_n_0\,
      O => \FSM_onehot_state[2]_i_4__2_n_0\
    );
\FSM_onehot_state[2]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"2000000000000000"
    )
        port map (
      I0 => \in_charisk_d1[3]_i_2_n_0\,
      I1 => \FSM_onehot_state[2]_i_10_n_0\,
      I2 => phy_charisk_r(2),
      I3 => \in_charisk_d1[2]_i_2_n_0\,
      I4 => \FSM_onehot_state[2]_i_11_n_0\,
      I5 => \FSM_onehot_state[2]_i_12_n_0\,
      O => \FSM_onehot_state[2]_i_5_n_0\
    );
\FSM_onehot_state[2]_i_5__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"2000000000000000"
    )
        port map (
      I0 => \in_charisk_d1[3]_i_2__0_n_0\,
      I1 => \FSM_onehot_state[2]_i_10__0_n_0\,
      I2 => phy_charisk_r(6),
      I3 => \in_charisk_d1[2]_i_2__0_n_0\,
      I4 => \FSM_onehot_state[2]_i_11__0_n_0\,
      I5 => \FSM_onehot_state[2]_i_12__0_n_0\,
      O => \FSM_onehot_state[2]_i_5__0_n_0\
    );
\FSM_onehot_state[2]_i_5__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"2000000000000000"
    )
        port map (
      I0 => \in_charisk_d1[3]_i_2__1_n_0\,
      I1 => \FSM_onehot_state[2]_i_10__1_n_0\,
      I2 => phy_charisk_r(10),
      I3 => \in_charisk_d1[2]_i_2__1_n_0\,
      I4 => \FSM_onehot_state[2]_i_11__1_n_0\,
      I5 => \FSM_onehot_state[2]_i_12__1_n_0\,
      O => \FSM_onehot_state[2]_i_5__1_n_0\
    );
\FSM_onehot_state[2]_i_5__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"2000000000000000"
    )
        port map (
      I0 => \in_charisk_d1[3]_i_2__2_n_0\,
      I1 => \FSM_onehot_state[2]_i_10__2_n_0\,
      I2 => phy_charisk_r(14),
      I3 => \in_charisk_d1[2]_i_2__2_n_0\,
      I4 => \FSM_onehot_state[2]_i_11__2_n_0\,
      I5 => \FSM_onehot_state[2]_i_12__2_n_0\,
      O => \FSM_onehot_state[2]_i_5__2_n_0\
    );
\FSM_onehot_state[2]_i_7\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(3),
      I1 => phy_disperr_r(3),
      O => \FSM_onehot_state[2]_i_7_n_0\
    );
\FSM_onehot_state[2]_i_7__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(7),
      I1 => phy_disperr_r(7),
      O => \FSM_onehot_state[2]_i_7__0_n_0\
    );
\FSM_onehot_state[2]_i_7__1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(11),
      I1 => phy_disperr_r(11),
      O => \FSM_onehot_state[2]_i_7__1_n_0\
    );
\FSM_onehot_state[2]_i_7__2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(15),
      I1 => phy_disperr_r(15),
      O => \FSM_onehot_state[2]_i_7__2_n_0\
    );
\FSM_onehot_state[2]_i_8\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(0),
      I1 => phy_disperr_r(0),
      O => \FSM_onehot_state[2]_i_8_n_0\
    );
\FSM_onehot_state[2]_i_8__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(4),
      I1 => phy_disperr_r(4),
      O => \FSM_onehot_state[2]_i_8__0_n_0\
    );
\FSM_onehot_state[2]_i_8__1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(8),
      I1 => phy_disperr_r(8),
      O => \FSM_onehot_state[2]_i_8__1_n_0\
    );
\FSM_onehot_state[2]_i_8__2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(12),
      I1 => phy_disperr_r(12),
      O => \FSM_onehot_state[2]_i_8__2_n_0\
    );
\FSM_onehot_state[2]_i_9\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(1),
      I1 => phy_disperr_r(1),
      O => \FSM_onehot_state[2]_i_9_n_0\
    );
\FSM_onehot_state[2]_i_9__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(5),
      I1 => phy_disperr_r(5),
      O => \FSM_onehot_state[2]_i_9__0_n_0\
    );
\FSM_onehot_state[2]_i_9__1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(9),
      I1 => phy_disperr_r(9),
      O => \FSM_onehot_state[2]_i_9__1_n_0\
    );
\FSM_onehot_state[2]_i_9__2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => phy_notintable_r(13),
      I1 => phy_disperr_r(13),
      O => \FSM_onehot_state[2]_i_9__2_n_0\
    );
\frame_align[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFF8F0000008F00"
    )
        port map (
      I0 => \frame_align[0]_i_2__2_n_0\,
      I1 => \^charisk28\(2),
      I2 => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(1),
      I3 => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(0),
      I4 => ifs_ready(0),
      I5 => \frame_align_reg[0]\,
      O => ifs_ready_reg
    );
\frame_align[0]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFF8F0000008F00"
    )
        port map (
      I0 => \frame_align[0]_i_2__1_n_0\,
      I1 => \^charisk28_0\(2),
      I2 => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(1),
      I3 => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(0),
      I4 => ifs_ready(1),
      I5 => \frame_align_reg[0]_0\,
      O => ifs_ready_reg_0
    );
\frame_align[0]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFF8F0000008F00"
    )
        port map (
      I0 => \frame_align[0]_i_2__0_n_0\,
      I1 => \^charisk28_1\(2),
      I2 => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(1),
      I3 => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(0),
      I4 => ifs_ready(2),
      I5 => \frame_align_reg[0]_1\,
      O => ifs_ready_reg_1
    );
\frame_align[0]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFF8F0000008F00"
    )
        port map (
      I0 => \frame_align[0]_i_2_n_0\,
      I1 => \^charisk28_2\(2),
      I2 => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(1),
      I3 => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(0),
      I4 => ifs_ready(3),
      I5 => \frame_align_reg[0]_2\,
      O => ifs_ready_reg_2
    );
\frame_align[0]_i_2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(118),
      I1 => \^in_dly_reg[187]_0\(119),
      I2 => \^in_dly_reg[187]_0\(117),
      O => \frame_align[0]_i_2_n_0\
    );
\frame_align[0]_i_2__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(86),
      I1 => \^in_dly_reg[187]_0\(87),
      I2 => \^in_dly_reg[187]_0\(85),
      O => \frame_align[0]_i_2__0_n_0\
    );
\frame_align[0]_i_2__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(54),
      I1 => \^in_dly_reg[187]_0\(55),
      I2 => \^in_dly_reg[187]_0\(53),
      O => \frame_align[0]_i_2__1_n_0\
    );
\frame_align[0]_i_2__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(22),
      I1 => \^in_dly_reg[187]_0\(23),
      I2 => \^in_dly_reg[187]_0\(21),
      O => \frame_align[0]_i_2__2_n_0\
    );
\frame_align[0]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \frame_align[1]_i_3_n_0\,
      I1 => \^in_dly_reg[187]_0\(14),
      I2 => \^in_dly_reg[187]_0\(15),
      I3 => \^in_dly_reg[187]_0\(13),
      I4 => \in_charisk_d1[1]_i_2_n_0\,
      O => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(1)
    );
\frame_align[0]_i_3__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \frame_align[1]_i_3__0_n_0\,
      I1 => \^in_dly_reg[187]_0\(46),
      I2 => \^in_dly_reg[187]_0\(47),
      I3 => \^in_dly_reg[187]_0\(45),
      I4 => \in_charisk_d1[1]_i_2__0_n_0\,
      O => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(1)
    );
\frame_align[0]_i_3__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \frame_align[1]_i_3__1_n_0\,
      I1 => \^in_dly_reg[187]_0\(78),
      I2 => \^in_dly_reg[187]_0\(79),
      I3 => \^in_dly_reg[187]_0\(77),
      I4 => \in_charisk_d1[1]_i_2__1_n_0\,
      O => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(1)
    );
\frame_align[0]_i_3__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => \frame_align[1]_i_3__2_n_0\,
      I1 => \^in_dly_reg[187]_0\(110),
      I2 => \^in_dly_reg[187]_0\(111),
      I3 => \^in_dly_reg[187]_0\(109),
      I4 => \in_charisk_d1[1]_i_2__2_n_0\,
      O => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(1)
    );
\frame_align[0]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000008000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(5),
      I1 => \^in_dly_reg[187]_0\(7),
      I2 => \^in_dly_reg[187]_0\(6),
      I3 => \in_charisk_d1[0]_i_2_n_0\,
      I4 => phy_charisk_r(0),
      I5 => \FSM_onehot_state[2]_i_8_n_0\,
      O => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(0)
    );
\frame_align[0]_i_4__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000008000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(37),
      I1 => \^in_dly_reg[187]_0\(39),
      I2 => \^in_dly_reg[187]_0\(38),
      I3 => \in_charisk_d1[0]_i_2__0_n_0\,
      I4 => phy_charisk_r(4),
      I5 => \FSM_onehot_state[2]_i_8__0_n_0\,
      O => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(0)
    );
\frame_align[0]_i_4__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000008000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(69),
      I1 => \^in_dly_reg[187]_0\(71),
      I2 => \^in_dly_reg[187]_0\(70),
      I3 => \in_charisk_d1[0]_i_2__1_n_0\,
      I4 => phy_charisk_r(8),
      I5 => \FSM_onehot_state[2]_i_8__1_n_0\,
      O => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(0)
    );
\frame_align[0]_i_4__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000008000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(101),
      I1 => \^in_dly_reg[187]_0\(103),
      I2 => \^in_dly_reg[187]_0\(102),
      I3 => \in_charisk_d1[0]_i_2__2_n_0\,
      I4 => phy_charisk_r(12),
      I5 => \FSM_onehot_state[2]_i_8__2_n_0\,
      O => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(0)
    );
\frame_align[1]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000800000000000"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(0),
      I1 => \in_charisk_d1[1]_i_2_n_0\,
      I2 => \^in_dly_reg[187]_0\(13),
      I3 => \^in_dly_reg[187]_0\(15),
      I4 => \^in_dly_reg[187]_0\(14),
      I5 => \frame_align[1]_i_3_n_0\,
      O => frame_align(0)
    );
\frame_align[1]_i_2__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000800000000000"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(0),
      I1 => \in_charisk_d1[1]_i_2__0_n_0\,
      I2 => \^in_dly_reg[187]_0\(45),
      I3 => \^in_dly_reg[187]_0\(47),
      I4 => \^in_dly_reg[187]_0\(46),
      I5 => \frame_align[1]_i_3__0_n_0\,
      O => frame_align_4(0)
    );
\frame_align[1]_i_2__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000800000000000"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(0),
      I1 => \in_charisk_d1[1]_i_2__1_n_0\,
      I2 => \^in_dly_reg[187]_0\(77),
      I3 => \^in_dly_reg[187]_0\(79),
      I4 => \^in_dly_reg[187]_0\(78),
      I5 => \frame_align[1]_i_3__1_n_0\,
      O => frame_align_7(0)
    );
\frame_align[1]_i_2__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000800000000000"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(0),
      I1 => \in_charisk_d1[1]_i_2__2_n_0\,
      I2 => \^in_dly_reg[187]_0\(109),
      I3 => \^in_dly_reg[187]_0\(111),
      I4 => \^in_dly_reg[187]_0\(110),
      I5 => \frame_align[1]_i_3__2_n_0\,
      O => frame_align_10(0)
    );
\frame_align[1]_i_3\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"02"
    )
        port map (
      I0 => phy_charisk_r(1),
      I1 => phy_disperr_r(1),
      I2 => phy_notintable_r(1),
      O => \frame_align[1]_i_3_n_0\
    );
\frame_align[1]_i_3__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"02"
    )
        port map (
      I0 => phy_charisk_r(5),
      I1 => phy_disperr_r(5),
      I2 => phy_notintable_r(5),
      O => \frame_align[1]_i_3__0_n_0\
    );
\frame_align[1]_i_3__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"02"
    )
        port map (
      I0 => phy_charisk_r(9),
      I1 => phy_disperr_r(9),
      I2 => phy_notintable_r(9),
      O => \frame_align[1]_i_3__1_n_0\
    );
\frame_align[1]_i_3__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"02"
    )
        port map (
      I0 => phy_charisk_r(13),
      I1 => phy_disperr_r(13),
      I2 => phy_notintable_r(13),
      O => \frame_align[1]_i_3__2_n_0\
    );
ifs_ready_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"00AB"
    )
        port map (
      I0 => ifs_ready(0),
      I1 => \mode_8b10b.gen_lane[0].i_lane/cgs_beat_is_cgs\,
      I2 => \^cgs_beat_has_error\,
      I3 => ifs_ready_reg_7(0),
      O => ifs_ready_reg_3
    );
\ifs_ready_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"00AB"
    )
        port map (
      I0 => ifs_ready(1),
      I1 => \mode_8b10b.gen_lane[1].i_lane/cgs_beat_is_cgs\,
      I2 => \^cgs_beat_has_error_5\,
      I3 => ifs_ready_reg_7(1),
      O => ifs_ready_reg_4
    );
\ifs_ready_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"00AB"
    )
        port map (
      I0 => ifs_ready(2),
      I1 => \mode_8b10b.gen_lane[2].i_lane/cgs_beat_is_cgs\,
      I2 => \^cgs_beat_has_error_8\,
      I3 => ifs_ready_reg_7(2),
      O => ifs_ready_reg_5
    );
\ifs_ready_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"00AB"
    )
        port map (
      I0 => ifs_ready(3),
      I1 => \mode_8b10b.gen_lane[3].i_lane/cgs_beat_is_cgs\,
      I2 => \^cgs_beat_has_error_11\,
      I3 => ifs_ready_reg_7(3),
      O => ifs_ready_reg_6
    );
ifs_ready_i_2: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(1),
      I1 => \mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1\(0),
      I2 => ifs_ready_i_3_n_0,
      I3 => \^charisk28\(2),
      I4 => \in_charisk_d1[3]_i_2_n_0\,
      O => \mode_8b10b.gen_lane[0].i_lane/cgs_beat_is_cgs\
    );
\ifs_ready_i_2__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(1),
      I1 => \mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1\(0),
      I2 => \ifs_ready_i_3__0_n_0\,
      I3 => \^charisk28_0\(2),
      I4 => \in_charisk_d1[3]_i_2__0_n_0\,
      O => \mode_8b10b.gen_lane[1].i_lane/cgs_beat_is_cgs\
    );
\ifs_ready_i_2__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(1),
      I1 => \mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1\(0),
      I2 => \ifs_ready_i_3__1_n_0\,
      I3 => \^charisk28_1\(2),
      I4 => \in_charisk_d1[3]_i_2__1_n_0\,
      O => \mode_8b10b.gen_lane[2].i_lane/cgs_beat_is_cgs\
    );
\ifs_ready_i_2__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(1),
      I1 => \mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1\(0),
      I2 => \ifs_ready_i_3__2_n_0\,
      I3 => \^charisk28_2\(2),
      I4 => \in_charisk_d1[3]_i_2__2_n_0\,
      O => \mode_8b10b.gen_lane[3].i_lane/cgs_beat_is_cgs\
    );
ifs_ready_i_3: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0080"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_12_n_0\,
      I1 => phy_charisk_r(3),
      I2 => \^in_dly_reg[187]_0\(21),
      I3 => \^in_dly_reg[187]_0\(22),
      O => ifs_ready_i_3_n_0
    );
\ifs_ready_i_3__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0080"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_12__0_n_0\,
      I1 => phy_charisk_r(7),
      I2 => \^in_dly_reg[187]_0\(53),
      I3 => \^in_dly_reg[187]_0\(54),
      O => \ifs_ready_i_3__0_n_0\
    );
\ifs_ready_i_3__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0080"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_12__1_n_0\,
      I1 => phy_charisk_r(11),
      I2 => \^in_dly_reg[187]_0\(85),
      I3 => \^in_dly_reg[187]_0\(86),
      O => \ifs_ready_i_3__1_n_0\
    );
\ifs_ready_i_3__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0080"
    )
        port map (
      I0 => \FSM_onehot_state[2]_i_12__2_n_0\,
      I1 => phy_charisk_r(15),
      I2 => \^in_dly_reg[187]_0\(117),
      I3 => \^in_dly_reg[187]_0\(118),
      O => \ifs_ready_i_3__2_n_0\
    );
\ilas_config_data[24]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(8),
      I1 => \^in_dly_reg[187]_0\(16),
      I2 => \ilas_config_data_reg[31]\(0),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^in_dly_reg[187]_0\(0),
      O => \^d\(0)
    );
\ilas_config_data[24]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(40),
      I1 => \^in_dly_reg[187]_0\(48),
      I2 => \ilas_config_data_reg[31]_0\(0),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^in_dly_reg[187]_0\(32),
      O => \^in_dly_reg[107]_0\(0)
    );
\ilas_config_data[24]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(72),
      I1 => \^in_dly_reg[187]_0\(80),
      I2 => \ilas_config_data_reg[31]_1\(0),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^in_dly_reg[187]_0\(64),
      O => \^in_dly_reg[139]_0\(0)
    );
\ilas_config_data[24]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(104),
      I1 => \^in_dly_reg[187]_0\(112),
      I2 => \ilas_config_data_reg[31]_2\(0),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^in_dly_reg[187]_0\(96),
      O => \^in_dly_reg[171]_0\(0)
    );
\ilas_config_data[25]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(9),
      I1 => \^in_dly_reg[187]_0\(17),
      I2 => \ilas_config_data_reg[31]\(1),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^in_dly_reg[187]_0\(1),
      O => \^d\(1)
    );
\ilas_config_data[25]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(41),
      I1 => \^in_dly_reg[187]_0\(49),
      I2 => \ilas_config_data_reg[31]_0\(1),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^in_dly_reg[187]_0\(33),
      O => \^in_dly_reg[107]_0\(1)
    );
\ilas_config_data[25]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(73),
      I1 => \^in_dly_reg[187]_0\(81),
      I2 => \ilas_config_data_reg[31]_1\(1),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^in_dly_reg[187]_0\(65),
      O => \^in_dly_reg[139]_0\(1)
    );
\ilas_config_data[25]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(105),
      I1 => \^in_dly_reg[187]_0\(113),
      I2 => \ilas_config_data_reg[31]_2\(1),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^in_dly_reg[187]_0\(97),
      O => \^in_dly_reg[171]_0\(1)
    );
\ilas_config_data[26]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(10),
      I1 => \^in_dly_reg[187]_0\(18),
      I2 => \ilas_config_data_reg[31]\(2),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^in_dly_reg[187]_0\(2),
      O => \^d\(2)
    );
\ilas_config_data[26]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(42),
      I1 => \^in_dly_reg[187]_0\(50),
      I2 => \ilas_config_data_reg[31]_0\(2),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^in_dly_reg[187]_0\(34),
      O => \^in_dly_reg[107]_0\(2)
    );
\ilas_config_data[26]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(74),
      I1 => \^in_dly_reg[187]_0\(82),
      I2 => \ilas_config_data_reg[31]_1\(2),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^in_dly_reg[187]_0\(66),
      O => \^in_dly_reg[139]_0\(2)
    );
\ilas_config_data[26]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(106),
      I1 => \^in_dly_reg[187]_0\(114),
      I2 => \ilas_config_data_reg[31]_2\(2),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^in_dly_reg[187]_0\(98),
      O => \^in_dly_reg[171]_0\(2)
    );
\ilas_config_data[27]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(11),
      I1 => \^in_dly_reg[187]_0\(19),
      I2 => \ilas_config_data_reg[31]\(3),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^in_dly_reg[187]_0\(3),
      O => \^d\(3)
    );
\ilas_config_data[27]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(43),
      I1 => \^in_dly_reg[187]_0\(51),
      I2 => \ilas_config_data_reg[31]_0\(3),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^in_dly_reg[187]_0\(35),
      O => \^in_dly_reg[107]_0\(3)
    );
\ilas_config_data[27]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(75),
      I1 => \^in_dly_reg[187]_0\(83),
      I2 => \ilas_config_data_reg[31]_1\(3),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^in_dly_reg[187]_0\(67),
      O => \^in_dly_reg[139]_0\(3)
    );
\ilas_config_data[27]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(107),
      I1 => \^in_dly_reg[187]_0\(115),
      I2 => \ilas_config_data_reg[31]_2\(3),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^in_dly_reg[187]_0\(99),
      O => \^in_dly_reg[171]_0\(3)
    );
\ilas_config_data[28]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(12),
      I1 => \^in_dly_reg[187]_0\(20),
      I2 => \ilas_config_data_reg[31]\(4),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^in_dly_reg[187]_0\(4),
      O => \^d\(4)
    );
\ilas_config_data[28]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(44),
      I1 => \^in_dly_reg[187]_0\(52),
      I2 => \ilas_config_data_reg[31]_0\(4),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^in_dly_reg[187]_0\(36),
      O => \^in_dly_reg[107]_0\(4)
    );
\ilas_config_data[28]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(76),
      I1 => \^in_dly_reg[187]_0\(84),
      I2 => \ilas_config_data_reg[31]_1\(4),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^in_dly_reg[187]_0\(68),
      O => \^in_dly_reg[139]_0\(4)
    );
\ilas_config_data[28]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(108),
      I1 => \^in_dly_reg[187]_0\(116),
      I2 => \ilas_config_data_reg[31]_2\(4),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^in_dly_reg[187]_0\(100),
      O => \^in_dly_reg[171]_0\(4)
    );
\ilas_config_data[29]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(13),
      I1 => \^in_dly_reg[187]_0\(21),
      I2 => \ilas_config_data_reg[31]\(5),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^in_dly_reg[187]_0\(5),
      O => \^d\(5)
    );
\ilas_config_data[29]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(45),
      I1 => \^in_dly_reg[187]_0\(53),
      I2 => \ilas_config_data_reg[31]_0\(5),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^in_dly_reg[187]_0\(37),
      O => \^in_dly_reg[107]_0\(5)
    );
\ilas_config_data[29]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(77),
      I1 => \^in_dly_reg[187]_0\(85),
      I2 => \ilas_config_data_reg[31]_1\(5),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^in_dly_reg[187]_0\(69),
      O => \^in_dly_reg[139]_0\(5)
    );
\ilas_config_data[29]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(109),
      I1 => \^in_dly_reg[187]_0\(117),
      I2 => \ilas_config_data_reg[31]_2\(5),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^in_dly_reg[187]_0\(101),
      O => \^in_dly_reg[171]_0\(5)
    );
\ilas_config_data[30]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(14),
      I1 => \^in_dly_reg[187]_0\(22),
      I2 => \ilas_config_data_reg[31]\(6),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^in_dly_reg[187]_0\(6),
      O => \^d\(6)
    );
\ilas_config_data[30]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(46),
      I1 => \^in_dly_reg[187]_0\(54),
      I2 => \ilas_config_data_reg[31]_0\(6),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^in_dly_reg[187]_0\(38),
      O => \^in_dly_reg[107]_0\(6)
    );
\ilas_config_data[30]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(78),
      I1 => \^in_dly_reg[187]_0\(86),
      I2 => \ilas_config_data_reg[31]_1\(6),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^in_dly_reg[187]_0\(70),
      O => \^in_dly_reg[139]_0\(6)
    );
\ilas_config_data[30]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(110),
      I1 => \^in_dly_reg[187]_0\(118),
      I2 => \ilas_config_data_reg[31]_2\(6),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^in_dly_reg[187]_0\(102),
      O => \^in_dly_reg[171]_0\(6)
    );
\ilas_config_data[31]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(15),
      I1 => \^in_dly_reg[187]_0\(23),
      I2 => \ilas_config_data_reg[31]\(7),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^in_dly_reg[187]_0\(7),
      O => \^d\(7)
    );
\ilas_config_data[31]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(47),
      I1 => \^in_dly_reg[187]_0\(55),
      I2 => \ilas_config_data_reg[31]_0\(7),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^in_dly_reg[187]_0\(39),
      O => \^in_dly_reg[107]_0\(7)
    );
\ilas_config_data[31]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(79),
      I1 => \^in_dly_reg[187]_0\(87),
      I2 => \ilas_config_data_reg[31]_1\(7),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^in_dly_reg[187]_0\(71),
      O => \^in_dly_reg[139]_0\(7)
    );
\ilas_config_data[31]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CCFFAAF0CC00AAF0"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(111),
      I1 => \^in_dly_reg[187]_0\(119),
      I2 => \ilas_config_data_reg[31]_2\(7),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^in_dly_reg[187]_0\(103),
      O => \^in_dly_reg[171]_0\(7)
    );
\in_charisk_d1[0]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(0),
      I1 => phy_disperr_r(0),
      I2 => phy_charisk_r(0),
      I3 => \in_charisk_d1[0]_i_2_n_0\,
      O => \^charisk28\(0)
    );
\in_charisk_d1[0]_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(4),
      I1 => phy_disperr_r(4),
      I2 => phy_charisk_r(4),
      I3 => \in_charisk_d1[0]_i_2__0_n_0\,
      O => \^charisk28_0\(0)
    );
\in_charisk_d1[0]_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(8),
      I1 => phy_disperr_r(8),
      I2 => phy_charisk_r(8),
      I3 => \in_charisk_d1[0]_i_2__1_n_0\,
      O => \^charisk28_1\(0)
    );
\in_charisk_d1[0]_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(12),
      I1 => phy_disperr_r(12),
      I2 => phy_charisk_r(12),
      I3 => \in_charisk_d1[0]_i_2__2_n_0\,
      O => \^charisk28_2\(0)
    );
\in_charisk_d1[0]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(0),
      I1 => \^in_dly_reg[187]_0\(2),
      I2 => \^in_dly_reg[187]_0\(1),
      I3 => \^in_dly_reg[187]_0\(4),
      I4 => \^in_dly_reg[187]_0\(3),
      O => \in_charisk_d1[0]_i_2_n_0\
    );
\in_charisk_d1[0]_i_2__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(32),
      I1 => \^in_dly_reg[187]_0\(34),
      I2 => \^in_dly_reg[187]_0\(33),
      I3 => \^in_dly_reg[187]_0\(36),
      I4 => \^in_dly_reg[187]_0\(35),
      O => \in_charisk_d1[0]_i_2__0_n_0\
    );
\in_charisk_d1[0]_i_2__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(64),
      I1 => \^in_dly_reg[187]_0\(66),
      I2 => \^in_dly_reg[187]_0\(65),
      I3 => \^in_dly_reg[187]_0\(68),
      I4 => \^in_dly_reg[187]_0\(67),
      O => \in_charisk_d1[0]_i_2__1_n_0\
    );
\in_charisk_d1[0]_i_2__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(96),
      I1 => \^in_dly_reg[187]_0\(98),
      I2 => \^in_dly_reg[187]_0\(97),
      I3 => \^in_dly_reg[187]_0\(100),
      I4 => \^in_dly_reg[187]_0\(99),
      O => \in_charisk_d1[0]_i_2__2_n_0\
    );
\in_charisk_d1[1]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(1),
      I1 => phy_disperr_r(1),
      I2 => phy_charisk_r(1),
      I3 => \in_charisk_d1[1]_i_2_n_0\,
      O => \^charisk28\(1)
    );
\in_charisk_d1[1]_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(5),
      I1 => phy_disperr_r(5),
      I2 => phy_charisk_r(5),
      I3 => \in_charisk_d1[1]_i_2__0_n_0\,
      O => \^charisk28_0\(1)
    );
\in_charisk_d1[1]_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(9),
      I1 => phy_disperr_r(9),
      I2 => phy_charisk_r(9),
      I3 => \in_charisk_d1[1]_i_2__1_n_0\,
      O => \^charisk28_1\(1)
    );
\in_charisk_d1[1]_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(13),
      I1 => phy_disperr_r(13),
      I2 => phy_charisk_r(13),
      I3 => \in_charisk_d1[1]_i_2__2_n_0\,
      O => \^charisk28_2\(1)
    );
\in_charisk_d1[1]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(8),
      I1 => \^in_dly_reg[187]_0\(10),
      I2 => \^in_dly_reg[187]_0\(9),
      I3 => \^in_dly_reg[187]_0\(12),
      I4 => \^in_dly_reg[187]_0\(11),
      O => \in_charisk_d1[1]_i_2_n_0\
    );
\in_charisk_d1[1]_i_2__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(40),
      I1 => \^in_dly_reg[187]_0\(42),
      I2 => \^in_dly_reg[187]_0\(41),
      I3 => \^in_dly_reg[187]_0\(44),
      I4 => \^in_dly_reg[187]_0\(43),
      O => \in_charisk_d1[1]_i_2__0_n_0\
    );
\in_charisk_d1[1]_i_2__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(72),
      I1 => \^in_dly_reg[187]_0\(74),
      I2 => \^in_dly_reg[187]_0\(73),
      I3 => \^in_dly_reg[187]_0\(76),
      I4 => \^in_dly_reg[187]_0\(75),
      O => \in_charisk_d1[1]_i_2__1_n_0\
    );
\in_charisk_d1[1]_i_2__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(104),
      I1 => \^in_dly_reg[187]_0\(106),
      I2 => \^in_dly_reg[187]_0\(105),
      I3 => \^in_dly_reg[187]_0\(108),
      I4 => \^in_dly_reg[187]_0\(107),
      O => \in_charisk_d1[1]_i_2__2_n_0\
    );
\in_charisk_d1[2]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(2),
      I1 => phy_disperr_r(2),
      I2 => phy_charisk_r(2),
      I3 => \in_charisk_d1[2]_i_2_n_0\,
      O => \^charisk28\(2)
    );
\in_charisk_d1[2]_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(6),
      I1 => phy_disperr_r(6),
      I2 => phy_charisk_r(6),
      I3 => \in_charisk_d1[2]_i_2__0_n_0\,
      O => \^charisk28_0\(2)
    );
\in_charisk_d1[2]_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(10),
      I1 => phy_disperr_r(10),
      I2 => phy_charisk_r(10),
      I3 => \in_charisk_d1[2]_i_2__1_n_0\,
      O => \^charisk28_1\(2)
    );
\in_charisk_d1[2]_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(14),
      I1 => phy_disperr_r(14),
      I2 => phy_charisk_r(14),
      I3 => \in_charisk_d1[2]_i_2__2_n_0\,
      O => \^charisk28_2\(2)
    );
\in_charisk_d1[2]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(16),
      I1 => \^in_dly_reg[187]_0\(18),
      I2 => \^in_dly_reg[187]_0\(17),
      I3 => \^in_dly_reg[187]_0\(20),
      I4 => \^in_dly_reg[187]_0\(19),
      O => \in_charisk_d1[2]_i_2_n_0\
    );
\in_charisk_d1[2]_i_2__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(48),
      I1 => \^in_dly_reg[187]_0\(50),
      I2 => \^in_dly_reg[187]_0\(49),
      I3 => \^in_dly_reg[187]_0\(52),
      I4 => \^in_dly_reg[187]_0\(51),
      O => \in_charisk_d1[2]_i_2__0_n_0\
    );
\in_charisk_d1[2]_i_2__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(80),
      I1 => \^in_dly_reg[187]_0\(82),
      I2 => \^in_dly_reg[187]_0\(81),
      I3 => \^in_dly_reg[187]_0\(84),
      I4 => \^in_dly_reg[187]_0\(83),
      O => \in_charisk_d1[2]_i_2__1_n_0\
    );
\in_charisk_d1[2]_i_2__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(112),
      I1 => \^in_dly_reg[187]_0\(114),
      I2 => \^in_dly_reg[187]_0\(113),
      I3 => \^in_dly_reg[187]_0\(116),
      I4 => \^in_dly_reg[187]_0\(115),
      O => \in_charisk_d1[2]_i_2__2_n_0\
    );
\in_charisk_d1[3]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(3),
      I1 => phy_disperr_r(3),
      I2 => phy_charisk_r(3),
      I3 => \in_charisk_d1[3]_i_2_n_0\,
      O => \^charisk28\(3)
    );
\in_charisk_d1[3]_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(7),
      I1 => phy_disperr_r(7),
      I2 => phy_charisk_r(7),
      I3 => \in_charisk_d1[3]_i_2__0_n_0\,
      O => \^charisk28_0\(3)
    );
\in_charisk_d1[3]_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(11),
      I1 => phy_disperr_r(11),
      I2 => phy_charisk_r(11),
      I3 => \in_charisk_d1[3]_i_2__1_n_0\,
      O => \^charisk28_1\(3)
    );
\in_charisk_d1[3]_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"1000"
    )
        port map (
      I0 => phy_notintable_r(15),
      I1 => phy_disperr_r(15),
      I2 => phy_charisk_r(15),
      I3 => \in_charisk_d1[3]_i_2__2_n_0\,
      O => \^charisk28_2\(3)
    );
\in_charisk_d1[3]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(24),
      I1 => \^in_dly_reg[187]_0\(26),
      I2 => \^in_dly_reg[187]_0\(25),
      I3 => \^in_dly_reg[187]_0\(28),
      I4 => \^in_dly_reg[187]_0\(27),
      O => \in_charisk_d1[3]_i_2_n_0\
    );
\in_charisk_d1[3]_i_2__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(56),
      I1 => \^in_dly_reg[187]_0\(58),
      I2 => \^in_dly_reg[187]_0\(57),
      I3 => \^in_dly_reg[187]_0\(60),
      I4 => \^in_dly_reg[187]_0\(59),
      O => \in_charisk_d1[3]_i_2__0_n_0\
    );
\in_charisk_d1[3]_i_2__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(88),
      I1 => \^in_dly_reg[187]_0\(90),
      I2 => \^in_dly_reg[187]_0\(89),
      I3 => \^in_dly_reg[187]_0\(92),
      I4 => \^in_dly_reg[187]_0\(91),
      O => \in_charisk_d1[3]_i_2__1_n_0\
    );
\in_charisk_d1[3]_i_2__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"04000000"
    )
        port map (
      I0 => \^in_dly_reg[187]_0\(120),
      I1 => \^in_dly_reg[187]_0\(122),
      I2 => \^in_dly_reg[187]_0\(121),
      I3 => \^in_dly_reg[187]_0\(124),
      I4 => \^in_dly_reg[187]_0\(123),
      O => \in_charisk_d1[3]_i_2__2_n_0\
    );
\in_dly_reg[100]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(88),
      Q => \^in_dly_reg[187]_0\(40),
      R => '0'
    );
\in_dly_reg[101]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(89),
      Q => \^in_dly_reg[187]_0\(41),
      R => '0'
    );
\in_dly_reg[102]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(90),
      Q => \^in_dly_reg[187]_0\(42),
      R => '0'
    );
\in_dly_reg[103]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(91),
      Q => \^in_dly_reg[187]_0\(43),
      R => '0'
    );
\in_dly_reg[104]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(92),
      Q => \^in_dly_reg[187]_0\(44),
      R => '0'
    );
\in_dly_reg[105]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(93),
      Q => \^in_dly_reg[187]_0\(45),
      R => '0'
    );
\in_dly_reg[106]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(94),
      Q => \^in_dly_reg[187]_0\(46),
      R => '0'
    );
\in_dly_reg[107]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(95),
      Q => \^in_dly_reg[187]_0\(47),
      R => '0'
    );
\in_dly_reg[108]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(96),
      Q => \^in_dly_reg[187]_0\(48),
      R => '0'
    );
\in_dly_reg[109]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(97),
      Q => \^in_dly_reg[187]_0\(49),
      R => '0'
    );
\in_dly_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(6),
      Q => phy_disperr_r(6),
      R => '0'
    );
\in_dly_reg[110]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(98),
      Q => \^in_dly_reg[187]_0\(50),
      R => '0'
    );
\in_dly_reg[111]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(99),
      Q => \^in_dly_reg[187]_0\(51),
      R => '0'
    );
\in_dly_reg[112]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(100),
      Q => \^in_dly_reg[187]_0\(52),
      R => '0'
    );
\in_dly_reg[113]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(101),
      Q => \^in_dly_reg[187]_0\(53),
      R => '0'
    );
\in_dly_reg[114]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(102),
      Q => \^in_dly_reg[187]_0\(54),
      R => '0'
    );
\in_dly_reg[115]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(103),
      Q => \^in_dly_reg[187]_0\(55),
      R => '0'
    );
\in_dly_reg[116]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(104),
      Q => \^in_dly_reg[187]_0\(56),
      R => '0'
    );
\in_dly_reg[117]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(105),
      Q => \^in_dly_reg[187]_0\(57),
      R => '0'
    );
\in_dly_reg[118]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(106),
      Q => \^in_dly_reg[187]_0\(58),
      R => '0'
    );
\in_dly_reg[119]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(107),
      Q => \^in_dly_reg[187]_0\(59),
      R => '0'
    );
\in_dly_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(7),
      Q => phy_disperr_r(7),
      R => '0'
    );
\in_dly_reg[120]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(108),
      Q => \^in_dly_reg[187]_0\(60),
      R => '0'
    );
\in_dly_reg[121]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(109),
      Q => \^in_dly_reg[187]_0\(61),
      R => '0'
    );
\in_dly_reg[122]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(110),
      Q => \^in_dly_reg[187]_0\(62),
      R => '0'
    );
\in_dly_reg[123]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(111),
      Q => \^in_dly_reg[187]_0\(63),
      R => '0'
    );
\in_dly_reg[124]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(112),
      Q => \^in_dly_reg[187]_0\(64),
      R => '0'
    );
\in_dly_reg[125]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(113),
      Q => \^in_dly_reg[187]_0\(65),
      R => '0'
    );
\in_dly_reg[126]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(114),
      Q => \^in_dly_reg[187]_0\(66),
      R => '0'
    );
\in_dly_reg[127]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(115),
      Q => \^in_dly_reg[187]_0\(67),
      R => '0'
    );
\in_dly_reg[128]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(116),
      Q => \^in_dly_reg[187]_0\(68),
      R => '0'
    );
\in_dly_reg[129]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(117),
      Q => \^in_dly_reg[187]_0\(69),
      R => '0'
    );
\in_dly_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(8),
      Q => phy_disperr_r(8),
      R => '0'
    );
\in_dly_reg[130]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(118),
      Q => \^in_dly_reg[187]_0\(70),
      R => '0'
    );
\in_dly_reg[131]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(119),
      Q => \^in_dly_reg[187]_0\(71),
      R => '0'
    );
\in_dly_reg[132]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(120),
      Q => \^in_dly_reg[187]_0\(72),
      R => '0'
    );
\in_dly_reg[133]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(121),
      Q => \^in_dly_reg[187]_0\(73),
      R => '0'
    );
\in_dly_reg[134]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(122),
      Q => \^in_dly_reg[187]_0\(74),
      R => '0'
    );
\in_dly_reg[135]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(123),
      Q => \^in_dly_reg[187]_0\(75),
      R => '0'
    );
\in_dly_reg[136]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(124),
      Q => \^in_dly_reg[187]_0\(76),
      R => '0'
    );
\in_dly_reg[137]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(125),
      Q => \^in_dly_reg[187]_0\(77),
      R => '0'
    );
\in_dly_reg[138]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(126),
      Q => \^in_dly_reg[187]_0\(78),
      R => '0'
    );
\in_dly_reg[139]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(127),
      Q => \^in_dly_reg[187]_0\(79),
      R => '0'
    );
\in_dly_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(9),
      Q => phy_disperr_r(9),
      R => '0'
    );
\in_dly_reg[140]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(128),
      Q => \^in_dly_reg[187]_0\(80),
      R => '0'
    );
\in_dly_reg[141]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(129),
      Q => \^in_dly_reg[187]_0\(81),
      R => '0'
    );
\in_dly_reg[142]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(130),
      Q => \^in_dly_reg[187]_0\(82),
      R => '0'
    );
\in_dly_reg[143]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(131),
      Q => \^in_dly_reg[187]_0\(83),
      R => '0'
    );
\in_dly_reg[144]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(132),
      Q => \^in_dly_reg[187]_0\(84),
      R => '0'
    );
\in_dly_reg[145]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(133),
      Q => \^in_dly_reg[187]_0\(85),
      R => '0'
    );
\in_dly_reg[146]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(134),
      Q => \^in_dly_reg[187]_0\(86),
      R => '0'
    );
\in_dly_reg[147]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(135),
      Q => \^in_dly_reg[187]_0\(87),
      R => '0'
    );
\in_dly_reg[148]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(136),
      Q => \^in_dly_reg[187]_0\(88),
      R => '0'
    );
\in_dly_reg[149]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(137),
      Q => \^in_dly_reg[187]_0\(89),
      R => '0'
    );
\in_dly_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(10),
      Q => phy_disperr_r(10),
      R => '0'
    );
\in_dly_reg[150]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(138),
      Q => \^in_dly_reg[187]_0\(90),
      R => '0'
    );
\in_dly_reg[151]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(139),
      Q => \^in_dly_reg[187]_0\(91),
      R => '0'
    );
\in_dly_reg[152]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(140),
      Q => \^in_dly_reg[187]_0\(92),
      R => '0'
    );
\in_dly_reg[153]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(141),
      Q => \^in_dly_reg[187]_0\(93),
      R => '0'
    );
\in_dly_reg[154]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(142),
      Q => \^in_dly_reg[187]_0\(94),
      R => '0'
    );
\in_dly_reg[155]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(143),
      Q => \^in_dly_reg[187]_0\(95),
      R => '0'
    );
\in_dly_reg[156]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(144),
      Q => \^in_dly_reg[187]_0\(96),
      R => '0'
    );
\in_dly_reg[157]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(145),
      Q => \^in_dly_reg[187]_0\(97),
      R => '0'
    );
\in_dly_reg[158]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(146),
      Q => \^in_dly_reg[187]_0\(98),
      R => '0'
    );
\in_dly_reg[159]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(147),
      Q => \^in_dly_reg[187]_0\(99),
      R => '0'
    );
\in_dly_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(11),
      Q => phy_disperr_r(11),
      R => '0'
    );
\in_dly_reg[160]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(148),
      Q => \^in_dly_reg[187]_0\(100),
      R => '0'
    );
\in_dly_reg[161]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(149),
      Q => \^in_dly_reg[187]_0\(101),
      R => '0'
    );
\in_dly_reg[162]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(150),
      Q => \^in_dly_reg[187]_0\(102),
      R => '0'
    );
\in_dly_reg[163]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(151),
      Q => \^in_dly_reg[187]_0\(103),
      R => '0'
    );
\in_dly_reg[164]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(152),
      Q => \^in_dly_reg[187]_0\(104),
      R => '0'
    );
\in_dly_reg[165]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(153),
      Q => \^in_dly_reg[187]_0\(105),
      R => '0'
    );
\in_dly_reg[166]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(154),
      Q => \^in_dly_reg[187]_0\(106),
      R => '0'
    );
\in_dly_reg[167]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(155),
      Q => \^in_dly_reg[187]_0\(107),
      R => '0'
    );
\in_dly_reg[168]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(156),
      Q => \^in_dly_reg[187]_0\(108),
      R => '0'
    );
\in_dly_reg[169]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(157),
      Q => \^in_dly_reg[187]_0\(109),
      R => '0'
    );
\in_dly_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(12),
      Q => phy_disperr_r(12),
      R => '0'
    );
\in_dly_reg[170]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(158),
      Q => \^in_dly_reg[187]_0\(110),
      R => '0'
    );
\in_dly_reg[171]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(159),
      Q => \^in_dly_reg[187]_0\(111),
      R => '0'
    );
\in_dly_reg[172]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(160),
      Q => \^in_dly_reg[187]_0\(112),
      R => '0'
    );
\in_dly_reg[173]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(161),
      Q => \^in_dly_reg[187]_0\(113),
      R => '0'
    );
\in_dly_reg[174]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(162),
      Q => \^in_dly_reg[187]_0\(114),
      R => '0'
    );
\in_dly_reg[175]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(163),
      Q => \^in_dly_reg[187]_0\(115),
      R => '0'
    );
\in_dly_reg[176]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(164),
      Q => \^in_dly_reg[187]_0\(116),
      R => '0'
    );
\in_dly_reg[177]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(165),
      Q => \^in_dly_reg[187]_0\(117),
      R => '0'
    );
\in_dly_reg[178]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(166),
      Q => \^in_dly_reg[187]_0\(118),
      R => '0'
    );
\in_dly_reg[179]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(167),
      Q => \^in_dly_reg[187]_0\(119),
      R => '0'
    );
\in_dly_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(13),
      Q => phy_disperr_r(13),
      R => '0'
    );
\in_dly_reg[180]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(168),
      Q => \^in_dly_reg[187]_0\(120),
      R => '0'
    );
\in_dly_reg[181]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(169),
      Q => \^in_dly_reg[187]_0\(121),
      R => '0'
    );
\in_dly_reg[182]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(170),
      Q => \^in_dly_reg[187]_0\(122),
      R => '0'
    );
\in_dly_reg[183]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(171),
      Q => \^in_dly_reg[187]_0\(123),
      R => '0'
    );
\in_dly_reg[184]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(172),
      Q => \^in_dly_reg[187]_0\(124),
      R => '0'
    );
\in_dly_reg[185]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(173),
      Q => \^in_dly_reg[187]_0\(125),
      R => '0'
    );
\in_dly_reg[186]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(174),
      Q => \^in_dly_reg[187]_0\(126),
      R => '0'
    );
\in_dly_reg[187]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(175),
      Q => \^in_dly_reg[187]_0\(127),
      R => '0'
    );
\in_dly_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(14),
      Q => phy_disperr_r(14),
      R => '0'
    );
\in_dly_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(15),
      Q => phy_disperr_r(15),
      R => '0'
    );
\in_dly_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(16),
      Q => phy_notintable_r(0),
      R => '0'
    );
\in_dly_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(17),
      Q => phy_notintable_r(1),
      R => '0'
    );
\in_dly_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(18),
      Q => phy_notintable_r(2),
      R => '0'
    );
\in_dly_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(19),
      Q => phy_notintable_r(3),
      R => '0'
    );
\in_dly_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(20),
      Q => phy_notintable_r(4),
      R => '0'
    );
\in_dly_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(21),
      Q => phy_notintable_r(5),
      R => '0'
    );
\in_dly_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(22),
      Q => phy_notintable_r(6),
      R => '0'
    );
\in_dly_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(23),
      Q => phy_notintable_r(7),
      R => '0'
    );
\in_dly_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(24),
      Q => phy_notintable_r(8),
      R => '0'
    );
\in_dly_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(25),
      Q => phy_notintable_r(9),
      R => '0'
    );
\in_dly_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(26),
      Q => phy_notintable_r(10),
      R => '0'
    );
\in_dly_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(27),
      Q => phy_notintable_r(11),
      R => '0'
    );
\in_dly_reg[32]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(28),
      Q => phy_notintable_r(12),
      R => '0'
    );
\in_dly_reg[33]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(29),
      Q => phy_notintable_r(13),
      R => '0'
    );
\in_dly_reg[34]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(30),
      Q => phy_notintable_r(14),
      R => '0'
    );
\in_dly_reg[35]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(31),
      Q => phy_notintable_r(15),
      R => '0'
    );
\in_dly_reg[36]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(32),
      Q => phy_charisk_r(0),
      R => '0'
    );
\in_dly_reg[37]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(33),
      Q => phy_charisk_r(1),
      R => '0'
    );
\in_dly_reg[38]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(34),
      Q => phy_charisk_r(2),
      R => '0'
    );
\in_dly_reg[39]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(35),
      Q => phy_charisk_r(3),
      R => '0'
    );
\in_dly_reg[40]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(36),
      Q => phy_charisk_r(4),
      R => '0'
    );
\in_dly_reg[41]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(37),
      Q => phy_charisk_r(5),
      R => '0'
    );
\in_dly_reg[42]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(38),
      Q => phy_charisk_r(6),
      R => '0'
    );
\in_dly_reg[43]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(39),
      Q => phy_charisk_r(7),
      R => '0'
    );
\in_dly_reg[44]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(40),
      Q => phy_charisk_r(8),
      R => '0'
    );
\in_dly_reg[45]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(41),
      Q => phy_charisk_r(9),
      R => '0'
    );
\in_dly_reg[46]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(42),
      Q => phy_charisk_r(10),
      R => '0'
    );
\in_dly_reg[47]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(43),
      Q => phy_charisk_r(11),
      R => '0'
    );
\in_dly_reg[48]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(44),
      Q => phy_charisk_r(12),
      R => '0'
    );
\in_dly_reg[49]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(45),
      Q => phy_charisk_r(13),
      R => '0'
    );
\in_dly_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(0),
      Q => phy_disperr_r(0),
      R => '0'
    );
\in_dly_reg[50]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(46),
      Q => phy_charisk_r(14),
      R => '0'
    );
\in_dly_reg[51]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(47),
      Q => phy_charisk_r(15),
      R => '0'
    );
\in_dly_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(1),
      Q => phy_disperr_r(1),
      R => '0'
    );
\in_dly_reg[60]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(48),
      Q => \^in_dly_reg[187]_0\(0),
      R => '0'
    );
\in_dly_reg[61]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(49),
      Q => \^in_dly_reg[187]_0\(1),
      R => '0'
    );
\in_dly_reg[62]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(50),
      Q => \^in_dly_reg[187]_0\(2),
      R => '0'
    );
\in_dly_reg[63]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(51),
      Q => \^in_dly_reg[187]_0\(3),
      R => '0'
    );
\in_dly_reg[64]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(52),
      Q => \^in_dly_reg[187]_0\(4),
      R => '0'
    );
\in_dly_reg[65]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(53),
      Q => \^in_dly_reg[187]_0\(5),
      R => '0'
    );
\in_dly_reg[66]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(54),
      Q => \^in_dly_reg[187]_0\(6),
      R => '0'
    );
\in_dly_reg[67]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(55),
      Q => \^in_dly_reg[187]_0\(7),
      R => '0'
    );
\in_dly_reg[68]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(56),
      Q => \^in_dly_reg[187]_0\(8),
      R => '0'
    );
\in_dly_reg[69]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(57),
      Q => \^in_dly_reg[187]_0\(9),
      R => '0'
    );
\in_dly_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(2),
      Q => phy_disperr_r(2),
      R => '0'
    );
\in_dly_reg[70]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(58),
      Q => \^in_dly_reg[187]_0\(10),
      R => '0'
    );
\in_dly_reg[71]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(59),
      Q => \^in_dly_reg[187]_0\(11),
      R => '0'
    );
\in_dly_reg[72]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(60),
      Q => \^in_dly_reg[187]_0\(12),
      R => '0'
    );
\in_dly_reg[73]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(61),
      Q => \^in_dly_reg[187]_0\(13),
      R => '0'
    );
\in_dly_reg[74]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(62),
      Q => \^in_dly_reg[187]_0\(14),
      R => '0'
    );
\in_dly_reg[75]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(63),
      Q => \^in_dly_reg[187]_0\(15),
      R => '0'
    );
\in_dly_reg[76]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(64),
      Q => \^in_dly_reg[187]_0\(16),
      R => '0'
    );
\in_dly_reg[77]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(65),
      Q => \^in_dly_reg[187]_0\(17),
      R => '0'
    );
\in_dly_reg[78]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(66),
      Q => \^in_dly_reg[187]_0\(18),
      R => '0'
    );
\in_dly_reg[79]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(67),
      Q => \^in_dly_reg[187]_0\(19),
      R => '0'
    );
\in_dly_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(3),
      Q => phy_disperr_r(3),
      R => '0'
    );
\in_dly_reg[80]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(68),
      Q => \^in_dly_reg[187]_0\(20),
      R => '0'
    );
\in_dly_reg[81]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(69),
      Q => \^in_dly_reg[187]_0\(21),
      R => '0'
    );
\in_dly_reg[82]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(70),
      Q => \^in_dly_reg[187]_0\(22),
      R => '0'
    );
\in_dly_reg[83]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(71),
      Q => \^in_dly_reg[187]_0\(23),
      R => '0'
    );
\in_dly_reg[84]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(72),
      Q => \^in_dly_reg[187]_0\(24),
      R => '0'
    );
\in_dly_reg[85]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(73),
      Q => \^in_dly_reg[187]_0\(25),
      R => '0'
    );
\in_dly_reg[86]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(74),
      Q => \^in_dly_reg[187]_0\(26),
      R => '0'
    );
\in_dly_reg[87]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(75),
      Q => \^in_dly_reg[187]_0\(27),
      R => '0'
    );
\in_dly_reg[88]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(76),
      Q => \^in_dly_reg[187]_0\(28),
      R => '0'
    );
\in_dly_reg[89]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(77),
      Q => \^in_dly_reg[187]_0\(29),
      R => '0'
    );
\in_dly_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(4),
      Q => phy_disperr_r(4),
      R => '0'
    );
\in_dly_reg[90]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(78),
      Q => \^in_dly_reg[187]_0\(30),
      R => '0'
    );
\in_dly_reg[91]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(79),
      Q => \^in_dly_reg[187]_0\(31),
      R => '0'
    );
\in_dly_reg[92]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(80),
      Q => \^in_dly_reg[187]_0\(32),
      R => '0'
    );
\in_dly_reg[93]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(81),
      Q => \^in_dly_reg[187]_0\(33),
      R => '0'
    );
\in_dly_reg[94]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(82),
      Q => \^in_dly_reg[187]_0\(34),
      R => '0'
    );
\in_dly_reg[95]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(83),
      Q => \^in_dly_reg[187]_0\(35),
      R => '0'
    );
\in_dly_reg[96]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(84),
      Q => \^in_dly_reg[187]_0\(36),
      R => '0'
    );
\in_dly_reg[97]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(85),
      Q => \^in_dly_reg[187]_0\(37),
      R => '0'
    );
\in_dly_reg[98]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(86),
      Q => \^in_dly_reg[187]_0\(38),
      R => '0'
    );
\in_dly_reg[99]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(87),
      Q => \^in_dly_reg[187]_0\(39),
      R => '0'
    );
\in_dly_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \in_dly_reg[187]_1\(5),
      Q => phy_disperr_r(5),
      R => '0'
    );
\phy_char_err[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[0]_i_2_n_0\,
      I1 => \in_charisk_d1[0]_i_2_n_0\,
      I2 => phy_notintable_r(0),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(0),
      O => \in_dly_reg[23]_0\(0)
    );
\phy_char_err[0]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[0]_i_2__0_n_0\,
      I1 => \in_charisk_d1[0]_i_2__0_n_0\,
      I2 => phy_notintable_r(4),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(4),
      O => \in_dly_reg[27]_0\(0)
    );
\phy_char_err[0]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[0]_i_2__1_n_0\,
      I1 => \in_charisk_d1[0]_i_2__1_n_0\,
      I2 => phy_notintable_r(8),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(8),
      O => \in_dly_reg[31]_0\(0)
    );
\phy_char_err[0]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[0]_i_2__2_n_0\,
      I1 => \in_charisk_d1[0]_i_2__2_n_0\,
      I2 => phy_notintable_r(12),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(12),
      O => \in_dly_reg[35]_0\(0)
    );
\phy_char_err[0]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(0),
      I1 => phy_disperr_r(0),
      I2 => phy_charisk_r(0),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[0]_i_2_n_0\
    );
\phy_char_err[0]_i_2__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(4),
      I1 => phy_disperr_r(4),
      I2 => phy_charisk_r(4),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[0]_i_2__0_n_0\
    );
\phy_char_err[0]_i_2__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(8),
      I1 => phy_disperr_r(8),
      I2 => phy_charisk_r(8),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[0]_i_2__1_n_0\
    );
\phy_char_err[0]_i_2__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(12),
      I1 => phy_disperr_r(12),
      I2 => phy_charisk_r(12),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[0]_i_2__2_n_0\
    );
\phy_char_err[1]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[1]_i_2_n_0\,
      I1 => \in_charisk_d1[1]_i_2_n_0\,
      I2 => phy_notintable_r(1),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(1),
      O => \in_dly_reg[23]_0\(1)
    );
\phy_char_err[1]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[1]_i_2__0_n_0\,
      I1 => \in_charisk_d1[1]_i_2__0_n_0\,
      I2 => phy_notintable_r(5),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(5),
      O => \in_dly_reg[27]_0\(1)
    );
\phy_char_err[1]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[1]_i_2__1_n_0\,
      I1 => \in_charisk_d1[1]_i_2__1_n_0\,
      I2 => phy_notintable_r(9),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(9),
      O => \in_dly_reg[31]_0\(1)
    );
\phy_char_err[1]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[1]_i_2__2_n_0\,
      I1 => \in_charisk_d1[1]_i_2__2_n_0\,
      I2 => phy_notintable_r(13),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(13),
      O => \in_dly_reg[35]_0\(1)
    );
\phy_char_err[1]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(1),
      I1 => phy_disperr_r(1),
      I2 => phy_charisk_r(1),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[1]_i_2_n_0\
    );
\phy_char_err[1]_i_2__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(5),
      I1 => phy_disperr_r(5),
      I2 => phy_charisk_r(5),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[1]_i_2__0_n_0\
    );
\phy_char_err[1]_i_2__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(9),
      I1 => phy_disperr_r(9),
      I2 => phy_charisk_r(9),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[1]_i_2__1_n_0\
    );
\phy_char_err[1]_i_2__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(13),
      I1 => phy_disperr_r(13),
      I2 => phy_charisk_r(13),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[1]_i_2__2_n_0\
    );
\phy_char_err[2]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[2]_i_2_n_0\,
      I1 => \in_charisk_d1[2]_i_2_n_0\,
      I2 => phy_notintable_r(2),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(2),
      O => \in_dly_reg[23]_0\(2)
    );
\phy_char_err[2]_i_1__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[2]_i_2__0_n_0\,
      I1 => \in_charisk_d1[2]_i_2__0_n_0\,
      I2 => phy_notintable_r(6),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(6),
      O => \in_dly_reg[27]_0\(2)
    );
\phy_char_err[2]_i_1__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[2]_i_2__1_n_0\,
      I1 => \in_charisk_d1[2]_i_2__1_n_0\,
      I2 => phy_notintable_r(10),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(10),
      O => \in_dly_reg[31]_0\(2)
    );
\phy_char_err[2]_i_1__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[2]_i_2__2_n_0\,
      I1 => \in_charisk_d1[2]_i_2__2_n_0\,
      I2 => phy_notintable_r(14),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(14),
      O => \in_dly_reg[35]_0\(2)
    );
\phy_char_err[2]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(2),
      I1 => phy_disperr_r(2),
      I2 => phy_charisk_r(2),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[2]_i_2_n_0\
    );
\phy_char_err[2]_i_2__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(6),
      I1 => phy_disperr_r(6),
      I2 => phy_charisk_r(6),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[2]_i_2__0_n_0\
    );
\phy_char_err[2]_i_2__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(10),
      I1 => phy_disperr_r(10),
      I2 => phy_charisk_r(10),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[2]_i_2__1_n_0\
    );
\phy_char_err[2]_i_2__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0010"
    )
        port map (
      I0 => phy_notintable_r(14),
      I1 => phy_disperr_r(14),
      I2 => phy_charisk_r(14),
      I3 => ctrl_err_statistics_mask(2),
      O => \phy_char_err[2]_i_2__2_n_0\
    );
\phy_char_err[3]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[3]_i_3_n_0\,
      I1 => \in_charisk_d1[3]_i_2_n_0\,
      I2 => phy_notintable_r(3),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(3),
      O => \in_dly_reg[23]_0\(3)
    );
\phy_char_err[3]_i_2__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[3]_i_3__0_n_0\,
      I1 => \in_charisk_d1[3]_i_2__0_n_0\,
      I2 => phy_notintable_r(7),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(7),
      O => \in_dly_reg[27]_0\(3)
    );
\phy_char_err[3]_i_2__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[3]_i_3__1_n_0\,
      I1 => \in_charisk_d1[3]_i_2__1_n_0\,
      I2 => phy_notintable_r(11),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(11),
      O => \in_dly_reg[31]_0\(3)
    );
\phy_char_err[3]_i_2__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"22F2FFFF22F222F2"
    )
        port map (
      I0 => \phy_char_err[3]_i_3__2_n_0\,
      I1 => \in_charisk_d1[3]_i_2__2_n_0\,
      I2 => phy_notintable_r(15),
      I3 => ctrl_err_statistics_mask(1),
      I4 => ctrl_err_statistics_mask(0),
      I5 => phy_disperr_r(15),
      O => \in_dly_reg[35]_0\(3)
    );
\phy_char_err[3]_i_3\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0004"
    )
        port map (
      I0 => ctrl_err_statistics_mask(2),
      I1 => phy_charisk_r(3),
      I2 => phy_disperr_r(3),
      I3 => phy_notintable_r(3),
      O => \phy_char_err[3]_i_3_n_0\
    );
\phy_char_err[3]_i_3__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0004"
    )
        port map (
      I0 => ctrl_err_statistics_mask(2),
      I1 => phy_charisk_r(7),
      I2 => phy_disperr_r(7),
      I3 => phy_notintable_r(7),
      O => \phy_char_err[3]_i_3__0_n_0\
    );
\phy_char_err[3]_i_3__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0004"
    )
        port map (
      I0 => ctrl_err_statistics_mask(2),
      I1 => phy_charisk_r(11),
      I2 => phy_disperr_r(11),
      I3 => phy_notintable_r(11),
      O => \phy_char_err[3]_i_3__1_n_0\
    );
\phy_char_err[3]_i_3__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0004"
    )
        port map (
      I0 => ctrl_err_statistics_mask(2),
      I1 => phy_charisk_r(15),
      I2 => phy_disperr_r(15),
      I3 => phy_notintable_r(15),
      O => \phy_char_err[3]_i_3__2_n_0\
    );
prev_was_last_i_1: unisim.vcomponents.LUT5
    generic map(
      INIT => X"2000FFFF"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[0].i_lane/charisk28_aligned_s\(3),
      I1 => \^d\(7),
      I2 => \^d\(6),
      I3 => \^d\(5),
      I4 => ifs_ready(0),
      O => prev_was_last0
    );
\prev_was_last_i_1__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"2000FFFF"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[1].i_lane/charisk28_aligned_s\(3),
      I1 => \^in_dly_reg[107]_0\(7),
      I2 => \^in_dly_reg[107]_0\(6),
      I3 => \^in_dly_reg[107]_0\(5),
      I4 => ifs_ready(1),
      O => prev_was_last0_3
    );
\prev_was_last_i_1__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"2000FFFF"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[2].i_lane/charisk28_aligned_s\(3),
      I1 => \^in_dly_reg[139]_0\(7),
      I2 => \^in_dly_reg[139]_0\(6),
      I3 => \^in_dly_reg[139]_0\(5),
      I4 => ifs_ready(2),
      O => prev_was_last0_6
    );
\prev_was_last_i_1__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"2000FFFF"
    )
        port map (
      I0 => \mode_8b10b.gen_lane[3].i_lane/charisk28_aligned_s\(3),
      I1 => \^in_dly_reg[171]_0\(7),
      I2 => \^in_dly_reg[171]_0\(6),
      I3 => \^in_dly_reg[171]_0\(5),
      I4 => ifs_ready(3),
      O => prev_was_last0_9
    );
prev_was_last_i_2: unisim.vcomponents.LUT6
    generic map(
      INIT => X"EEFFAAFAEEAAAAFA"
    )
        port map (
      I0 => prev_was_last_i_3_n_0,
      I1 => \^charisk28\(2),
      I2 => Q(0),
      I3 => \ilas_config_data_reg[24]\,
      I4 => \frame_align_reg[0]\,
      I5 => \^charisk28\(0),
      O => \mode_8b10b.gen_lane[0].i_lane/charisk28_aligned_s\(3)
    );
\prev_was_last_i_2__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"EEFFAAFAEEAAAAFA"
    )
        port map (
      I0 => \prev_was_last_i_3__0_n_0\,
      I1 => \^charisk28_0\(2),
      I2 => prev_was_last_reg(0),
      I3 => \ilas_config_data_reg[24]_0\,
      I4 => \frame_align_reg[0]_0\,
      I5 => \^charisk28_0\(0),
      O => \mode_8b10b.gen_lane[1].i_lane/charisk28_aligned_s\(3)
    );
\prev_was_last_i_2__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"EEFFAAFAEEAAAAFA"
    )
        port map (
      I0 => \prev_was_last_i_3__1_n_0\,
      I1 => \^charisk28_1\(2),
      I2 => prev_was_last_reg_0(0),
      I3 => \ilas_config_data_reg[24]_1\,
      I4 => \frame_align_reg[0]_1\,
      I5 => \^charisk28_1\(0),
      O => \mode_8b10b.gen_lane[2].i_lane/charisk28_aligned_s\(3)
    );
\prev_was_last_i_2__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"EEFFAAFAEEAAAAFA"
    )
        port map (
      I0 => \prev_was_last_i_3__2_n_0\,
      I1 => \^charisk28_2\(2),
      I2 => prev_was_last_reg_1(0),
      I3 => \ilas_config_data_reg[24]_2\,
      I4 => \frame_align_reg[0]_2\,
      I5 => \^charisk28_2\(0),
      O => \mode_8b10b.gen_lane[3].i_lane/charisk28_aligned_s\(3)
    );
prev_was_last_i_3: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000002000000000"
    )
        port map (
      I0 => \ilas_config_data_reg[24]\,
      I1 => \frame_align_reg[0]\,
      I2 => phy_charisk_r(1),
      I3 => phy_disperr_r(1),
      I4 => phy_notintable_r(1),
      I5 => \in_charisk_d1[1]_i_2_n_0\,
      O => prev_was_last_i_3_n_0
    );
\prev_was_last_i_3__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000002000000000"
    )
        port map (
      I0 => \ilas_config_data_reg[24]_0\,
      I1 => \frame_align_reg[0]_0\,
      I2 => phy_charisk_r(5),
      I3 => phy_disperr_r(5),
      I4 => phy_notintable_r(5),
      I5 => \in_charisk_d1[1]_i_2__0_n_0\,
      O => \prev_was_last_i_3__0_n_0\
    );
\prev_was_last_i_3__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000002000000000"
    )
        port map (
      I0 => \ilas_config_data_reg[24]_1\,
      I1 => \frame_align_reg[0]_1\,
      I2 => phy_charisk_r(9),
      I3 => phy_disperr_r(9),
      I4 => phy_notintable_r(9),
      I5 => \in_charisk_d1[1]_i_2__1_n_0\,
      O => \prev_was_last_i_3__1_n_0\
    );
\prev_was_last_i_3__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000002000000000"
    )
        port map (
      I0 => \ilas_config_data_reg[24]_2\,
      I1 => \frame_align_reg[0]_2\,
      I2 => phy_charisk_r(13),
      I3 => phy_disperr_r(13),
      I4 => phy_notintable_r(13),
      I5 => \in_charisk_d1[1]_i_2__2_n_0\,
      O => \prev_was_last_i_3__2_n_0\
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity \jesd204_rx_0_pipeline_stage__parameterized3\ is
  port (
    rx_valid : out STD_LOGIC;
    buffer_release_d1 : in STD_LOGIC;
    clk : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of \jesd204_rx_0_pipeline_stage__parameterized3\ : entity is "pipeline_stage";
end \jesd204_rx_0_pipeline_stage__parameterized3\;

architecture STRUCTURE of \jesd204_rx_0_pipeline_stage__parameterized3\ is
  attribute SHREG_EXTRACT : string;
  attribute SHREG_EXTRACT of \in_dly_reg[0]\ : label is "no";
begin
\in_dly_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => buffer_release_d1,
      Q => rx_valid,
      R => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_lane is
  port (
    rx_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    \frame_align_reg[1]_0\ : out STD_LOGIC;
    \frame_align_reg[0]_0\ : out STD_LOGIC;
    ifs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_valid_reg : out STD_LOGIC;
    cgs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    E : out STD_LOGIC_VECTOR ( 0 to 0 );
    Q : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_charisk_d1_reg[3]\ : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_addr : out STD_LOGIC_VECTOR ( 1 downto 0 );
    \beat_error_count_reg[1]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[1]\ : out STD_LOGIC;
    SR : out STD_LOGIC_VECTOR ( 0 to 0 );
    \FSM_onehot_state_reg[0]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[2]\ : out STD_LOGIC;
    buffer_release_opportunity_reg : out STD_LOGIC;
    ilas_config_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    status_err_statistics_cnt : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clk : in STD_LOGIC;
    mem_reg : in STD_LOGIC;
    \frame_align_reg[0]_1\ : in STD_LOGIC;
    prev_was_last0 : in STD_LOGIC;
    buffer_release_n : in STD_LOGIC;
    ifs_ready_reg_0 : in STD_LOGIC;
    frame_align : in STD_LOGIC_VECTOR ( 0 to 0 );
    status_lane_ifs_ready : in STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_data_d1_reg[31]\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \in_charisk_d1_reg[3]_0\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    cfg_lanes_disable : in STD_LOGIC_VECTOR ( 1 downto 0 );
    p_7_out : in STD_LOGIC;
    reset : in STD_LOGIC;
    ctrl_err_statistics_reset : in STD_LOGIC;
    buffer_release_n_reg : in STD_LOGIC;
    buffer_release_opportunity : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_0\ : in STD_LOGIC;
    cgs_beat_has_error : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_1\ : in STD_LOGIC_VECTOR ( 0 to 0 );
    \phy_char_err_reg[3]_0\ : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_lane : entity is "jesd204_rx_lane";
end jesd204_rx_0_jesd204_rx_lane;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_lane is
  signal \^sr\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal data_aligned_s : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal data_scrambled_s : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \frame_align[1]_i_1_n_0\ : STD_LOGIC;
  signal \^frame_align_reg[0]_0\ : STD_LOGIC;
  signal \^frame_align_reg[1]_0\ : STD_LOGIC;
  signal full_state : STD_LOGIC_VECTOR ( 32 to 32 );
  signal \i___0_carry_i_1_n_0\ : STD_LOGIC;
  signal \i___0_carry_i_2_n_0\ : STD_LOGIC;
  signal \i___65_carry_i_1_n_0\ : STD_LOGIC;
  signal \i___65_carry_i_2_n_0\ : STD_LOGIC;
  signal i_align_mux_n_52 : STD_LOGIC;
  signal i_align_mux_n_54 : STD_LOGIC;
  signal i_align_mux_n_55 : STD_LOGIC;
  signal i_cgs_n_1 : STD_LOGIC;
  signal i_ilas_monitor_n_3 : STD_LOGIC;
  signal \^ifs_ready\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^ilas_config_valid_reg\ : STD_LOGIC;
  signal p_0_in0_in : STD_LOGIC;
  signal p_0_in1_in : STD_LOGIC;
  signal p_0_in_0 : STD_LOGIC;
  signal p_37_out : STD_LOGIC;
  signal \phy_char_err_reg_n_0_[0]\ : STD_LOGIC;
  signal prev_was_last : STD_LOGIC;
  signal state : STD_LOGIC;
  signal \^status_err_statistics_cnt\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_1__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_6_n_0\ : STD_LOGIC;
  signal \NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \frame_align[1]_i_1\ : label is "soft_lutpair43";
  attribute SOFT_HLUTNM of \gen_lane[0].lane_captured[0]_i_1\ : label is "soft_lutpair43";
begin
  SR(0) <= \^sr\(0);
  \frame_align_reg[0]_0\ <= \^frame_align_reg[0]_0\;
  \frame_align_reg[1]_0\ <= \^frame_align_reg[1]_0\;
  ifs_ready(0) <= \^ifs_ready\(0);
  ilas_config_valid_reg <= \^ilas_config_valid_reg\;
  status_err_statistics_cnt(31 downto 0) <= \^status_err_statistics_cnt\(31 downto 0);
\frame_align[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"E2"
    )
        port map (
      I0 => frame_align(0),
      I1 => \^ifs_ready\(0),
      I2 => \^frame_align_reg[1]_0\,
      O => \frame_align[1]_i_1_n_0\
    );
\frame_align_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \frame_align_reg[0]_1\,
      Q => \^frame_align_reg[0]_0\,
      R => '0'
    );
\frame_align_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \frame_align[1]_i_1_n_0\,
      Q => \^frame_align_reg[1]_0\,
      R => '0'
    );
\gen_lane[0].lane_captured[0]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \^ifs_ready\(0),
      I1 => status_lane_ifs_ready(0),
      O => E(0)
    );
\i___0_carry_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"17E8"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(0),
      I1 => \phy_char_err_reg_n_0_[0]\,
      I2 => p_0_in1_in,
      I3 => \^status_err_statistics_cnt\(1),
      O => \i___0_carry_i_1_n_0\
    );
\i___0_carry_i_2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(0),
      I1 => p_0_in1_in,
      I2 => \phy_char_err_reg_n_0_[0]\,
      O => \i___0_carry_i_2_n_0\
    );
\i___65_carry_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"17E8"
    )
        port map (
      I0 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      I1 => p_0_in_0,
      I2 => p_0_in0_in,
      I3 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      O => \i___65_carry_i_1_n_0\
    );
\i___65_carry_i_2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
        port map (
      I0 => p_0_in0_in,
      I1 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      I2 => p_0_in_0,
      O => \i___65_carry_i_2_n_0\
    );
i_align_mux: entity work.jesd204_rx_0_align_mux_13
     port map (
      D(7 downto 0) => D(7 downto 0),
      Q(7 downto 0) => Q(7 downto 0),
      SR(0) => p_37_out,
      WEBWE(0) => i_align_mux_n_55,
      buffer_release_n => buffer_release_n,
      buffer_release_n_reg => buffer_release_n_reg,
      buffer_release_opportunity => buffer_release_opportunity,
      buffer_release_opportunity_reg => buffer_release_opportunity_reg,
      cfg_disable_scrambler => cfg_disable_scrambler,
      cfg_lanes_disable(1 downto 0) => cfg_lanes_disable(1 downto 0),
      clk => clk,
      data_aligned_s(23 downto 0) => data_aligned_s(23 downto 0),
      data_scrambled_s(17 downto 2) => data_scrambled_s(31 downto 16),
      data_scrambled_s(1 downto 0) => data_scrambled_s(9 downto 8),
      \ilas_config_data_reg[5]\ => \^frame_align_reg[1]_0\,
      \ilas_config_data_reg[5]_0\ => \^frame_align_reg[0]_0\,
      ilas_config_valid_reg => i_align_mux_n_52,
      ilas_config_valid_reg_0 => \^ilas_config_valid_reg\,
      ilas_config_valid_reg_1 => i_ilas_monitor_n_3,
      \in_charisk_d1_reg[3]_0\(0) => \in_charisk_d1_reg[3]\(0),
      \in_charisk_d1_reg[3]_1\(3 downto 0) => \in_charisk_d1_reg[3]_0\(3 downto 0),
      \in_data_d1_reg[31]_0\(31 downto 0) => \in_data_d1_reg[31]\(31 downto 0),
      mem_reg(0) => full_state(32),
      p_7_out => p_7_out,
      prev_was_last => prev_was_last,
      state => state,
      state_reg => i_align_mux_n_54,
      state_reg_0 => \^ifs_ready\(0)
    );
i_cgs: entity work.jesd204_rx_0_jesd204_rx_cgs_14
     port map (
      \FSM_onehot_state_reg[0]_0\ => \FSM_onehot_state_reg[0]\,
      \FSM_onehot_state_reg[0]_1\ => \FSM_onehot_state_reg[0]_0\,
      \FSM_onehot_state_reg[0]_2\(0) => \FSM_onehot_state_reg[0]_1\(0),
      \FSM_onehot_state_reg[1]_0\ => \FSM_onehot_state_reg[1]\,
      \FSM_onehot_state_reg[2]_0\ => \FSM_onehot_state_reg[2]\,
      SR(0) => i_cgs_n_1,
      \beat_error_count_reg[1]_0\ => \beat_error_count_reg[1]\,
      cgs_beat_has_error => cgs_beat_has_error,
      cgs_ready(0) => cgs_ready(0),
      clk => clk
    );
i_descrambler: entity work.jesd204_rx_0_jesd204_scrambler_15
     port map (
      D(28 downto 21) => D(7 downto 0),
      D(20 downto 8) => data_aligned_s(22 downto 10),
      D(7 downto 0) => data_aligned_s(7 downto 0),
      DIADI(13 downto 8) => data_scrambled_s(15 downto 10),
      DIADI(7 downto 0) => data_scrambled_s(7 downto 0),
      Q(0) => full_state(32),
      SR(0) => p_37_out,
      cfg_disable_scrambler => cfg_disable_scrambler,
      clk => clk
    );
i_elastic_buffer: entity work.jesd204_rx_0_elastic_buffer_16
     port map (
      SR(0) => p_37_out,
      WEBWE(0) => i_align_mux_n_55,
      buffer_release_n => buffer_release_n,
      clk => clk,
      data_scrambled_s(31 downto 0) => data_scrambled_s(31 downto 0),
      mem_reg_0 => mem_reg,
      rx_data(31 downto 0) => rx_data(31 downto 0)
    );
i_ilas_monitor: entity work.jesd204_rx_0_jesd204_ilas_monitor_17
     port map (
      D(31 downto 24) => D(7 downto 0),
      D(23 downto 0) => data_aligned_s(23 downto 0),
      clk => clk,
      ilas_config_addr(1 downto 0) => ilas_config_addr(1 downto 0),
      \ilas_config_addr_reg[1]_0\ => i_ilas_monitor_n_3,
      ilas_config_data(31 downto 0) => ilas_config_data(31 downto 0),
      ilas_config_valid_reg_0 => \^ilas_config_valid_reg\,
      ilas_config_valid_reg_1 => i_align_mux_n_52,
      prev_was_last => prev_was_last,
      prev_was_last0 => prev_was_last0,
      state => state,
      state_reg_0 => i_align_mux_n_54
    );
ifs_ready_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => ifs_ready_reg_0,
      Q => \^ifs_ready\(0),
      R => '0'
    );
\phy_char_err_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(0),
      Q => \phy_char_err_reg_n_0_[0]\,
      R => i_cgs_n_1
    );
\phy_char_err_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(1),
      Q => p_0_in_0,
      R => i_cgs_n_1
    );
\phy_char_err_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(2),
      Q => p_0_in0_in,
      R => i_cgs_n_1
    );
\phy_char_err_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(3),
      Q => p_0_in1_in,
      R => i_cgs_n_1
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3\,
      CYINIT => '0',
      DI(3 downto 2) => B"00",
      DI(1) => \^status_err_statistics_cnt\(1),
      DI(0) => '0',
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      S(3 downto 2) => \^status_err_statistics_cnt\(3 downto 2),
      S(1) => \i___0_carry_i_1_n_0\,
      S(0) => \i___0_carry_i_2_n_0\
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__0\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(7 downto 4)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__1\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(11 downto 8)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__2\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(15 downto 12)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__3\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(19 downto 16)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__4\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(23 downto 20)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__5\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(27 downto 24)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__6\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\,
      CO(3) => \NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED\(3),
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(31 downto 28)
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3\,
      CYINIT => '0',
      DI(3 downto 2) => B"00",
      DI(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      DI(0) => '0',
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\,
      S(1) => \i___65_carry_i_1_n_0\,
      S(0) => \i___65_carry_i_2_n_0\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__0\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__1\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__2\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__3\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__4\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__5\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__6\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\,
      CO(3) => \NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED\(3),
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\
    );
\status_err_statistics_cnt[31]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => reset,
      I1 => ctrl_err_statistics_reset,
      O => \^sr\(0)
    );
\status_err_statistics_cnt[31]_i_1__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFFFFE"
    )
        port map (
      I0 => \status_err_statistics_cnt[31]_i_2_n_0\,
      I1 => \status_err_statistics_cnt[31]_i_3_n_0\,
      I2 => \status_err_statistics_cnt[31]_i_4_n_0\,
      I3 => \status_err_statistics_cnt[31]_i_5_n_0\,
      I4 => \status_err_statistics_cnt[31]_i_6_n_0\,
      O => \status_err_statistics_cnt[31]_i_1__0_n_0\
    );
\status_err_statistics_cnt[31]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(24),
      I1 => \^status_err_statistics_cnt\(25),
      I2 => \^status_err_statistics_cnt\(22),
      I3 => \^status_err_statistics_cnt\(23),
      I4 => \^status_err_statistics_cnt\(21),
      I5 => \^status_err_statistics_cnt\(20),
      O => \status_err_statistics_cnt[31]_i_2_n_0\
    );
\status_err_statistics_cnt[31]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(30),
      I1 => \^status_err_statistics_cnt\(31),
      I2 => \^status_err_statistics_cnt\(28),
      I3 => \^status_err_statistics_cnt\(29),
      I4 => \^status_err_statistics_cnt\(27),
      I5 => \^status_err_statistics_cnt\(26),
      O => \status_err_statistics_cnt[31]_i_3_n_0\
    );
\status_err_statistics_cnt[31]_i_4\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"7F"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(7),
      I1 => \^status_err_statistics_cnt\(6),
      I2 => \^status_err_statistics_cnt\(5),
      O => \status_err_statistics_cnt[31]_i_4_n_0\
    );
\status_err_statistics_cnt[31]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(18),
      I1 => \^status_err_statistics_cnt\(19),
      I2 => \^status_err_statistics_cnt\(16),
      I3 => \^status_err_statistics_cnt\(17),
      I4 => \^status_err_statistics_cnt\(15),
      I5 => \^status_err_statistics_cnt\(14),
      O => \status_err_statistics_cnt[31]_i_5_n_0\
    );
\status_err_statistics_cnt[31]_i_6\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(12),
      I1 => \^status_err_statistics_cnt\(13),
      I2 => \^status_err_statistics_cnt\(10),
      I3 => \^status_err_statistics_cnt\(11),
      I4 => \^status_err_statistics_cnt\(9),
      I5 => \^status_err_statistics_cnt\(8),
      O => \status_err_statistics_cnt[31]_i_6_n_0\
    );
\status_err_statistics_cnt_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\,
      Q => \^status_err_statistics_cnt\(0),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\,
      Q => \^status_err_statistics_cnt\(10),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\,
      Q => \^status_err_statistics_cnt\(11),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\,
      Q => \^status_err_statistics_cnt\(12),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\,
      Q => \^status_err_statistics_cnt\(13),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\,
      Q => \^status_err_statistics_cnt\(14),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\,
      Q => \^status_err_statistics_cnt\(15),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\,
      Q => \^status_err_statistics_cnt\(16),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\,
      Q => \^status_err_statistics_cnt\(17),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\,
      Q => \^status_err_statistics_cnt\(18),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\,
      Q => \^status_err_statistics_cnt\(19),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\,
      Q => \^status_err_statistics_cnt\(1),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\,
      Q => \^status_err_statistics_cnt\(20),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\,
      Q => \^status_err_statistics_cnt\(21),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\,
      Q => \^status_err_statistics_cnt\(22),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\,
      Q => \^status_err_statistics_cnt\(23),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\,
      Q => \^status_err_statistics_cnt\(24),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\,
      Q => \^status_err_statistics_cnt\(25),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\,
      Q => \^status_err_statistics_cnt\(26),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\,
      Q => \^status_err_statistics_cnt\(27),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\,
      Q => \^status_err_statistics_cnt\(28),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\,
      Q => \^status_err_statistics_cnt\(29),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\,
      Q => \^status_err_statistics_cnt\(2),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\,
      Q => \^status_err_statistics_cnt\(30),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\,
      Q => \^status_err_statistics_cnt\(31),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\,
      Q => \^status_err_statistics_cnt\(3),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\,
      Q => \^status_err_statistics_cnt\(4),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\,
      Q => \^status_err_statistics_cnt\(5),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\,
      Q => \^status_err_statistics_cnt\(6),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\,
      Q => \^status_err_statistics_cnt\(7),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\,
      Q => \^status_err_statistics_cnt\(8),
      R => \^sr\(0)
    );
\status_err_statistics_cnt_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__0_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\,
      Q => \^status_err_statistics_cnt\(9),
      R => \^sr\(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_lane_0 is
  port (
    \frame_align_reg[1]_0\ : out STD_LOGIC;
    \frame_align_reg[0]_0\ : out STD_LOGIC;
    ifs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_valid_reg : out STD_LOGIC;
    cgs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    E : out STD_LOGIC_VECTOR ( 0 to 0 );
    Q : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_charisk_d1_reg[3]\ : out STD_LOGIC_VECTOR ( 0 to 0 );
    p_27_out : out STD_LOGIC;
    ilas_config_addr : out STD_LOGIC_VECTOR ( 1 downto 0 );
    \beat_error_count_reg[1]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[1]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[0]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[2]\ : out STD_LOGIC;
    rx_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    status_err_statistics_cnt : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clk : in STD_LOGIC;
    \frame_align_reg[0]_1\ : in STD_LOGIC;
    prev_was_last0 : in STD_LOGIC;
    buffer_release_n : in STD_LOGIC;
    ifs_ready_reg_0 : in STD_LOGIC;
    frame_align : in STD_LOGIC_VECTOR ( 0 to 0 );
    status_lane_ifs_ready : in STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_data_d1_reg[31]\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \in_charisk_d1_reg[3]_0\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    mem_reg : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_0\ : in STD_LOGIC;
    cgs_beat_has_error : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_1\ : in STD_LOGIC_VECTOR ( 0 to 0 );
    \phy_char_err_reg[3]_0\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    SR : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_lane_0 : entity is "jesd204_rx_lane";
end jesd204_rx_0_jesd204_rx_lane_0;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_lane_0 is
  signal data_aligned_s : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal data_scrambled_s : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \frame_align[1]_i_1__0_n_0\ : STD_LOGIC;
  signal \^frame_align_reg[0]_0\ : STD_LOGIC;
  signal \^frame_align_reg[1]_0\ : STD_LOGIC;
  signal full_state : STD_LOGIC_VECTOR ( 32 to 32 );
  signal \i___0_carry_i_1__0_n_0\ : STD_LOGIC;
  signal \i___0_carry_i_2__0_n_0\ : STD_LOGIC;
  signal \i___65_carry_i_1__0_n_0\ : STD_LOGIC;
  signal \i___65_carry_i_2__0_n_0\ : STD_LOGIC;
  signal i_align_mux_n_52 : STD_LOGIC;
  signal i_align_mux_n_53 : STD_LOGIC;
  signal i_align_mux_n_54 : STD_LOGIC;
  signal i_cgs_n_1 : STD_LOGIC;
  signal i_ilas_monitor_n_2 : STD_LOGIC;
  signal i_ilas_monitor_n_3 : STD_LOGIC;
  signal \^ifs_ready\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^ilas_config_valid_reg\ : STD_LOGIC;
  signal p_0_in0_in : STD_LOGIC;
  signal p_0_in1_in : STD_LOGIC;
  signal p_0_in_0 : STD_LOGIC;
  signal \^p_27_out\ : STD_LOGIC;
  signal \phy_char_err_reg_n_0_[0]\ : STD_LOGIC;
  signal state : STD_LOGIC;
  signal \^status_err_statistics_cnt\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_1__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_2__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_3__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_4__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_5__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_6__0_n_0\ : STD_LOGIC;
  signal \NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \frame_align[1]_i_1__0\ : label is "soft_lutpair55";
  attribute SOFT_HLUTNM of \gen_lane[1].lane_captured[1]_i_1\ : label is "soft_lutpair55";
begin
  \frame_align_reg[0]_0\ <= \^frame_align_reg[0]_0\;
  \frame_align_reg[1]_0\ <= \^frame_align_reg[1]_0\;
  ifs_ready(0) <= \^ifs_ready\(0);
  ilas_config_valid_reg <= \^ilas_config_valid_reg\;
  p_27_out <= \^p_27_out\;
  status_err_statistics_cnt(31 downto 0) <= \^status_err_statistics_cnt\(31 downto 0);
\frame_align[1]_i_1__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"E2"
    )
        port map (
      I0 => frame_align(0),
      I1 => \^ifs_ready\(0),
      I2 => \^frame_align_reg[1]_0\,
      O => \frame_align[1]_i_1__0_n_0\
    );
\frame_align_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \frame_align_reg[0]_1\,
      Q => \^frame_align_reg[0]_0\,
      R => '0'
    );
\frame_align_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \frame_align[1]_i_1__0_n_0\,
      Q => \^frame_align_reg[1]_0\,
      R => '0'
    );
\gen_lane[1].lane_captured[1]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \^ifs_ready\(0),
      I1 => status_lane_ifs_ready(0),
      O => E(0)
    );
\i___0_carry_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"17E8"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(0),
      I1 => \phy_char_err_reg_n_0_[0]\,
      I2 => p_0_in1_in,
      I3 => \^status_err_statistics_cnt\(1),
      O => \i___0_carry_i_1__0_n_0\
    );
\i___0_carry_i_2__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(0),
      I1 => p_0_in1_in,
      I2 => \phy_char_err_reg_n_0_[0]\,
      O => \i___0_carry_i_2__0_n_0\
    );
\i___65_carry_i_1__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"17E8"
    )
        port map (
      I0 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      I1 => p_0_in_0,
      I2 => p_0_in0_in,
      I3 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      O => \i___65_carry_i_1__0_n_0\
    );
\i___65_carry_i_2__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
        port map (
      I0 => p_0_in0_in,
      I1 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      I2 => p_0_in_0,
      O => \i___65_carry_i_2__0_n_0\
    );
i_align_mux: entity work.jesd204_rx_0_align_mux_8
     port map (
      D(7 downto 0) => D(7 downto 0),
      Q(7 downto 0) => Q(7 downto 0),
      SS(0) => \^p_27_out\,
      WEBWE(0) => i_align_mux_n_54,
      cfg_disable_scrambler => cfg_disable_scrambler,
      clk => clk,
      data_aligned_s(23 downto 0) => data_aligned_s(23 downto 0),
      data_scrambled_s(17 downto 2) => data_scrambled_s(31 downto 16),
      data_scrambled_s(1 downto 0) => data_scrambled_s(9 downto 8),
      ifs_ready_reg => i_align_mux_n_53,
      \ilas_config_data_reg[5]\ => \^frame_align_reg[1]_0\,
      \ilas_config_data_reg[5]_0\ => \^frame_align_reg[0]_0\,
      ilas_config_valid_reg => i_align_mux_n_52,
      ilas_config_valid_reg_0 => \^ilas_config_valid_reg\,
      ilas_config_valid_reg_1 => i_ilas_monitor_n_3,
      \in_charisk_d1_reg[3]_0\(0) => \in_charisk_d1_reg[3]\(0),
      \in_charisk_d1_reg[3]_1\(3 downto 0) => \in_charisk_d1_reg[3]_0\(3 downto 0),
      \in_data_d1_reg[31]_0\(31 downto 0) => \in_data_d1_reg[31]\(31 downto 0),
      mem_reg(0) => full_state(32),
      state => state,
      state_reg => \^ifs_ready\(0),
      \wr_addr_reg[0]\ => i_ilas_monitor_n_2
    );
i_cgs: entity work.jesd204_rx_0_jesd204_rx_cgs_9
     port map (
      \FSM_onehot_state_reg[0]_0\ => \FSM_onehot_state_reg[0]\,
      \FSM_onehot_state_reg[0]_1\ => \FSM_onehot_state_reg[0]_0\,
      \FSM_onehot_state_reg[0]_2\(0) => \FSM_onehot_state_reg[0]_1\(0),
      \FSM_onehot_state_reg[1]_0\ => \FSM_onehot_state_reg[1]\,
      \FSM_onehot_state_reg[2]_0\ => \FSM_onehot_state_reg[2]\,
      SR(0) => i_cgs_n_1,
      \beat_error_count_reg[1]_0\ => \beat_error_count_reg[1]\,
      cgs_beat_has_error => cgs_beat_has_error,
      cgs_ready(0) => cgs_ready(0),
      clk => clk
    );
i_descrambler: entity work.jesd204_rx_0_jesd204_scrambler_10
     port map (
      D(28 downto 21) => D(7 downto 0),
      D(20 downto 8) => data_aligned_s(22 downto 10),
      D(7 downto 0) => data_aligned_s(7 downto 0),
      DIADI(13 downto 8) => data_scrambled_s(15 downto 10),
      DIADI(7 downto 0) => data_scrambled_s(7 downto 0),
      Q(0) => full_state(32),
      SS(0) => \^p_27_out\,
      cfg_disable_scrambler => cfg_disable_scrambler,
      clk => clk
    );
i_elastic_buffer: entity work.jesd204_rx_0_elastic_buffer_11
     port map (
      SR(0) => \^p_27_out\,
      WEBWE(0) => i_align_mux_n_54,
      buffer_release_n => buffer_release_n,
      clk => clk,
      data_scrambled_s(31 downto 0) => data_scrambled_s(31 downto 0),
      mem_reg_0 => mem_reg,
      rx_data(31 downto 0) => rx_data(31 downto 0)
    );
i_ilas_monitor: entity work.jesd204_rx_0_jesd204_ilas_monitor_12
     port map (
      D(31 downto 24) => D(7 downto 0),
      D(23 downto 0) => data_aligned_s(23 downto 0),
      clk => clk,
      ilas_config_addr(1 downto 0) => ilas_config_addr(1 downto 0),
      \ilas_config_addr_reg[1]_0\ => i_ilas_monitor_n_3,
      ilas_config_data(31 downto 0) => ilas_config_data(31 downto 0),
      ilas_config_valid_reg_0 => \^ilas_config_valid_reg\,
      ilas_config_valid_reg_1 => i_align_mux_n_52,
      prev_was_last0 => prev_was_last0,
      prev_was_last_reg_0 => i_ilas_monitor_n_2,
      state => state,
      state_reg_0 => i_align_mux_n_53,
      \wr_addr_reg[0]\ => \^ifs_ready\(0)
    );
ifs_ready_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => ifs_ready_reg_0,
      Q => \^ifs_ready\(0),
      R => '0'
    );
\phy_char_err_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(0),
      Q => \phy_char_err_reg_n_0_[0]\,
      R => i_cgs_n_1
    );
\phy_char_err_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(1),
      Q => p_0_in_0,
      R => i_cgs_n_1
    );
\phy_char_err_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(2),
      Q => p_0_in0_in,
      R => i_cgs_n_1
    );
\phy_char_err_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(3),
      Q => p_0_in1_in,
      R => i_cgs_n_1
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3\,
      CYINIT => '0',
      DI(3 downto 2) => B"00",
      DI(1) => \^status_err_statistics_cnt\(1),
      DI(0) => '0',
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      S(3 downto 2) => \^status_err_statistics_cnt\(3 downto 2),
      S(1) => \i___0_carry_i_1__0_n_0\,
      S(0) => \i___0_carry_i_2__0_n_0\
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__0\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(7 downto 4)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__1\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(11 downto 8)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__2\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(15 downto 12)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__3\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(19 downto 16)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__4\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(23 downto 20)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__5\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(27 downto 24)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__6\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\,
      CO(3) => \NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED\(3),
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(31 downto 28)
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3\,
      CYINIT => '0',
      DI(3 downto 2) => B"00",
      DI(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      DI(0) => '0',
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\,
      S(1) => \i___65_carry_i_1__0_n_0\,
      S(0) => \i___65_carry_i_2__0_n_0\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__0\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__1\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__2\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__3\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__4\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__5\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__6\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\,
      CO(3) => \NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED\(3),
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\
    );
\status_err_statistics_cnt[31]_i_1__1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFFFFE"
    )
        port map (
      I0 => \status_err_statistics_cnt[31]_i_2__0_n_0\,
      I1 => \status_err_statistics_cnt[31]_i_3__0_n_0\,
      I2 => \status_err_statistics_cnt[31]_i_4__0_n_0\,
      I3 => \status_err_statistics_cnt[31]_i_5__0_n_0\,
      I4 => \status_err_statistics_cnt[31]_i_6__0_n_0\,
      O => \status_err_statistics_cnt[31]_i_1__1_n_0\
    );
\status_err_statistics_cnt[31]_i_2__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(24),
      I1 => \^status_err_statistics_cnt\(25),
      I2 => \^status_err_statistics_cnt\(22),
      I3 => \^status_err_statistics_cnt\(23),
      I4 => \^status_err_statistics_cnt\(21),
      I5 => \^status_err_statistics_cnt\(20),
      O => \status_err_statistics_cnt[31]_i_2__0_n_0\
    );
\status_err_statistics_cnt[31]_i_3__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(30),
      I1 => \^status_err_statistics_cnt\(31),
      I2 => \^status_err_statistics_cnt\(28),
      I3 => \^status_err_statistics_cnt\(29),
      I4 => \^status_err_statistics_cnt\(27),
      I5 => \^status_err_statistics_cnt\(26),
      O => \status_err_statistics_cnt[31]_i_3__0_n_0\
    );
\status_err_statistics_cnt[31]_i_4__0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"7F"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(7),
      I1 => \^status_err_statistics_cnt\(6),
      I2 => \^status_err_statistics_cnt\(5),
      O => \status_err_statistics_cnt[31]_i_4__0_n_0\
    );
\status_err_statistics_cnt[31]_i_5__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(18),
      I1 => \^status_err_statistics_cnt\(19),
      I2 => \^status_err_statistics_cnt\(16),
      I3 => \^status_err_statistics_cnt\(17),
      I4 => \^status_err_statistics_cnt\(15),
      I5 => \^status_err_statistics_cnt\(14),
      O => \status_err_statistics_cnt[31]_i_5__0_n_0\
    );
\status_err_statistics_cnt[31]_i_6__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(12),
      I1 => \^status_err_statistics_cnt\(13),
      I2 => \^status_err_statistics_cnt\(10),
      I3 => \^status_err_statistics_cnt\(11),
      I4 => \^status_err_statistics_cnt\(9),
      I5 => \^status_err_statistics_cnt\(8),
      O => \status_err_statistics_cnt[31]_i_6__0_n_0\
    );
\status_err_statistics_cnt_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\,
      Q => \^status_err_statistics_cnt\(0),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\,
      Q => \^status_err_statistics_cnt\(10),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\,
      Q => \^status_err_statistics_cnt\(11),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\,
      Q => \^status_err_statistics_cnt\(12),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\,
      Q => \^status_err_statistics_cnt\(13),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\,
      Q => \^status_err_statistics_cnt\(14),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\,
      Q => \^status_err_statistics_cnt\(15),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\,
      Q => \^status_err_statistics_cnt\(16),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\,
      Q => \^status_err_statistics_cnt\(17),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\,
      Q => \^status_err_statistics_cnt\(18),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\,
      Q => \^status_err_statistics_cnt\(19),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\,
      Q => \^status_err_statistics_cnt\(1),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\,
      Q => \^status_err_statistics_cnt\(20),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\,
      Q => \^status_err_statistics_cnt\(21),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\,
      Q => \^status_err_statistics_cnt\(22),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\,
      Q => \^status_err_statistics_cnt\(23),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\,
      Q => \^status_err_statistics_cnt\(24),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\,
      Q => \^status_err_statistics_cnt\(25),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\,
      Q => \^status_err_statistics_cnt\(26),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\,
      Q => \^status_err_statistics_cnt\(27),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\,
      Q => \^status_err_statistics_cnt\(28),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\,
      Q => \^status_err_statistics_cnt\(29),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\,
      Q => \^status_err_statistics_cnt\(2),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\,
      Q => \^status_err_statistics_cnt\(30),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\,
      Q => \^status_err_statistics_cnt\(31),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\,
      Q => \^status_err_statistics_cnt\(3),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\,
      Q => \^status_err_statistics_cnt\(4),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\,
      Q => \^status_err_statistics_cnt\(5),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\,
      Q => \^status_err_statistics_cnt\(6),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\,
      Q => \^status_err_statistics_cnt\(7),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\,
      Q => \^status_err_statistics_cnt\(8),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__1_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\,
      Q => \^status_err_statistics_cnt\(9),
      R => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_lane_1 is
  port (
    \frame_align_reg[1]_0\ : out STD_LOGIC;
    \frame_align_reg[0]_0\ : out STD_LOGIC;
    ifs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_valid_reg : out STD_LOGIC;
    cgs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    E : out STD_LOGIC_VECTOR ( 0 to 0 );
    \cfg_lanes_disable[2]\ : out STD_LOGIC;
    Q : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_charisk_d1_reg[3]\ : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_addr : out STD_LOGIC_VECTOR ( 1 downto 0 );
    \beat_error_count_reg[1]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[1]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[0]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[2]\ : out STD_LOGIC;
    rx_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    status_err_statistics_cnt : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clk : in STD_LOGIC;
    \frame_align_reg[0]_1\ : in STD_LOGIC;
    prev_was_last0 : in STD_LOGIC;
    buffer_release_n : in STD_LOGIC;
    ifs_ready_reg_0 : in STD_LOGIC;
    frame_align : in STD_LOGIC_VECTOR ( 0 to 0 );
    status_lane_ifs_ready : in STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_lanes_disable : in STD_LOGIC_VECTOR ( 1 downto 0 );
    p_27_out : in STD_LOGIC;
    cfg_disable_scrambler : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_data_d1_reg[31]\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \in_charisk_d1_reg[3]_0\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    mem_reg : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_0\ : in STD_LOGIC;
    cgs_beat_has_error : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_1\ : in STD_LOGIC_VECTOR ( 0 to 0 );
    \phy_char_err_reg[3]_0\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    SR : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_lane_1 : entity is "jesd204_rx_lane";
end jesd204_rx_0_jesd204_rx_lane_1;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_lane_1 is
  signal data_aligned_s : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal data_scrambled_s : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \frame_align[1]_i_1__1_n_0\ : STD_LOGIC;
  signal \^frame_align_reg[0]_0\ : STD_LOGIC;
  signal \^frame_align_reg[1]_0\ : STD_LOGIC;
  signal full_state : STD_LOGIC_VECTOR ( 32 to 32 );
  signal \i___0_carry_i_1__1_n_0\ : STD_LOGIC;
  signal \i___0_carry_i_2__1_n_0\ : STD_LOGIC;
  signal \i___65_carry_i_1__1_n_0\ : STD_LOGIC;
  signal \i___65_carry_i_2__1_n_0\ : STD_LOGIC;
  signal i_align_mux_n_53 : STD_LOGIC;
  signal i_align_mux_n_54 : STD_LOGIC;
  signal i_align_mux_n_55 : STD_LOGIC;
  signal i_cgs_n_1 : STD_LOGIC;
  signal i_ilas_monitor_n_2 : STD_LOGIC;
  signal i_ilas_monitor_n_3 : STD_LOGIC;
  signal \^ifs_ready\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^ilas_config_valid_reg\ : STD_LOGIC;
  signal p_0_in0_in : STD_LOGIC;
  signal p_0_in1_in : STD_LOGIC;
  signal p_0_in_0 : STD_LOGIC;
  signal p_17_out : STD_LOGIC;
  signal \phy_char_err_reg_n_0_[0]\ : STD_LOGIC;
  signal state : STD_LOGIC;
  signal \^status_err_statistics_cnt\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_1__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_2__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_3__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_4__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_5__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_6__1_n_0\ : STD_LOGIC;
  signal \NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \frame_align[1]_i_1__1\ : label is "soft_lutpair68";
  attribute SOFT_HLUTNM of \gen_lane[2].lane_captured[2]_i_1\ : label is "soft_lutpair68";
begin
  \frame_align_reg[0]_0\ <= \^frame_align_reg[0]_0\;
  \frame_align_reg[1]_0\ <= \^frame_align_reg[1]_0\;
  ifs_ready(0) <= \^ifs_ready\(0);
  ilas_config_valid_reg <= \^ilas_config_valid_reg\;
  status_err_statistics_cnt(31 downto 0) <= \^status_err_statistics_cnt\(31 downto 0);
\frame_align[1]_i_1__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"E2"
    )
        port map (
      I0 => frame_align(0),
      I1 => \^ifs_ready\(0),
      I2 => \^frame_align_reg[1]_0\,
      O => \frame_align[1]_i_1__1_n_0\
    );
\frame_align_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \frame_align_reg[0]_1\,
      Q => \^frame_align_reg[0]_0\,
      R => '0'
    );
\frame_align_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \frame_align[1]_i_1__1_n_0\,
      Q => \^frame_align_reg[1]_0\,
      R => '0'
    );
\gen_lane[2].lane_captured[2]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \^ifs_ready\(0),
      I1 => status_lane_ifs_ready(0),
      O => E(0)
    );
\i___0_carry_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"17E8"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(0),
      I1 => \phy_char_err_reg_n_0_[0]\,
      I2 => p_0_in1_in,
      I3 => \^status_err_statistics_cnt\(1),
      O => \i___0_carry_i_1__1_n_0\
    );
\i___0_carry_i_2__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(0),
      I1 => p_0_in1_in,
      I2 => \phy_char_err_reg_n_0_[0]\,
      O => \i___0_carry_i_2__1_n_0\
    );
\i___65_carry_i_1__1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"17E8"
    )
        port map (
      I0 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      I1 => p_0_in_0,
      I2 => p_0_in0_in,
      I3 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      O => \i___65_carry_i_1__1_n_0\
    );
\i___65_carry_i_2__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
        port map (
      I0 => p_0_in0_in,
      I1 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      I2 => p_0_in_0,
      O => \i___65_carry_i_2__1_n_0\
    );
i_align_mux: entity work.jesd204_rx_0_align_mux_3
     port map (
      D(7 downto 0) => D(7 downto 0),
      Q(7 downto 0) => Q(7 downto 0),
      WEBWE(0) => i_align_mux_n_55,
      cfg_disable_scrambler => cfg_disable_scrambler,
      cfg_lanes_disable(1 downto 0) => cfg_lanes_disable(1 downto 0),
      \cfg_lanes_disable[2]\ => \cfg_lanes_disable[2]\,
      clk => clk,
      data_aligned_s(23 downto 0) => data_aligned_s(23 downto 0),
      data_scrambled_s(17 downto 2) => data_scrambled_s(31 downto 16),
      data_scrambled_s(1 downto 0) => data_scrambled_s(9 downto 8),
      ifs_ready_reg => i_align_mux_n_54,
      \ilas_config_data_reg[5]\ => \^frame_align_reg[1]_0\,
      \ilas_config_data_reg[5]_0\ => \^frame_align_reg[0]_0\,
      ilas_config_valid_reg => i_align_mux_n_53,
      ilas_config_valid_reg_0 => \^ilas_config_valid_reg\,
      ilas_config_valid_reg_1 => i_ilas_monitor_n_3,
      \in_charisk_d1_reg[3]_0\(0) => \in_charisk_d1_reg[3]\(0),
      \in_charisk_d1_reg[3]_1\(3 downto 0) => \in_charisk_d1_reg[3]_0\(3 downto 0),
      \in_data_d1_reg[31]_0\(31 downto 0) => \in_data_d1_reg[31]\(31 downto 0),
      mem_reg(0) => full_state(32),
      p_17_out => p_17_out,
      p_27_out => p_27_out,
      state => state,
      state_reg => \^ifs_ready\(0),
      \wr_addr_reg[6]\ => i_ilas_monitor_n_2
    );
i_cgs: entity work.jesd204_rx_0_jesd204_rx_cgs_4
     port map (
      \FSM_onehot_state_reg[0]_0\ => \FSM_onehot_state_reg[0]\,
      \FSM_onehot_state_reg[0]_1\ => \FSM_onehot_state_reg[0]_0\,
      \FSM_onehot_state_reg[0]_2\(0) => \FSM_onehot_state_reg[0]_1\(0),
      \FSM_onehot_state_reg[1]_0\ => \FSM_onehot_state_reg[1]\,
      \FSM_onehot_state_reg[2]_0\ => \FSM_onehot_state_reg[2]\,
      SR(0) => i_cgs_n_1,
      \beat_error_count_reg[1]_0\ => \beat_error_count_reg[1]\,
      cgs_beat_has_error => cgs_beat_has_error,
      cgs_ready(0) => cgs_ready(0),
      clk => clk
    );
i_descrambler: entity work.jesd204_rx_0_jesd204_scrambler_5
     port map (
      D(28 downto 21) => D(7 downto 0),
      D(20 downto 8) => data_aligned_s(22 downto 10),
      D(7 downto 0) => data_aligned_s(7 downto 0),
      DIADI(13 downto 8) => data_scrambled_s(15 downto 10),
      DIADI(7 downto 0) => data_scrambled_s(7 downto 0),
      Q(0) => full_state(32),
      SR(0) => p_17_out,
      cfg_disable_scrambler => cfg_disable_scrambler,
      clk => clk
    );
i_elastic_buffer: entity work.jesd204_rx_0_elastic_buffer_6
     port map (
      SR(0) => p_17_out,
      WEBWE(0) => i_align_mux_n_55,
      buffer_release_n => buffer_release_n,
      clk => clk,
      data_scrambled_s(31 downto 0) => data_scrambled_s(31 downto 0),
      mem_reg_0 => mem_reg,
      rx_data(31 downto 0) => rx_data(31 downto 0)
    );
i_ilas_monitor: entity work.jesd204_rx_0_jesd204_ilas_monitor_7
     port map (
      D(31 downto 24) => D(7 downto 0),
      D(23 downto 0) => data_aligned_s(23 downto 0),
      clk => clk,
      ilas_config_addr(1 downto 0) => ilas_config_addr(1 downto 0),
      \ilas_config_addr_reg[1]_0\ => i_ilas_monitor_n_3,
      ilas_config_data(31 downto 0) => ilas_config_data(31 downto 0),
      ilas_config_valid_reg_0 => \^ilas_config_valid_reg\,
      ilas_config_valid_reg_1 => i_align_mux_n_53,
      prev_was_last0 => prev_was_last0,
      prev_was_last_reg_0 => i_ilas_monitor_n_2,
      state => state,
      state_reg_0 => i_align_mux_n_54,
      \wr_addr_reg[6]\ => \^ifs_ready\(0)
    );
ifs_ready_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => ifs_ready_reg_0,
      Q => \^ifs_ready\(0),
      R => '0'
    );
\phy_char_err_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(0),
      Q => \phy_char_err_reg_n_0_[0]\,
      R => i_cgs_n_1
    );
\phy_char_err_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(1),
      Q => p_0_in_0,
      R => i_cgs_n_1
    );
\phy_char_err_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(2),
      Q => p_0_in0_in,
      R => i_cgs_n_1
    );
\phy_char_err_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(3),
      Q => p_0_in1_in,
      R => i_cgs_n_1
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3\,
      CYINIT => '0',
      DI(3 downto 2) => B"00",
      DI(1) => \^status_err_statistics_cnt\(1),
      DI(0) => '0',
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      S(3 downto 2) => \^status_err_statistics_cnt\(3 downto 2),
      S(1) => \i___0_carry_i_1__1_n_0\,
      S(0) => \i___0_carry_i_2__1_n_0\
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__0\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(7 downto 4)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__1\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(11 downto 8)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__2\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(15 downto 12)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__3\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(19 downto 16)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__4\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(23 downto 20)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__5\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(27 downto 24)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__6\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\,
      CO(3) => \NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED\(3),
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(31 downto 28)
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3\,
      CYINIT => '0',
      DI(3 downto 2) => B"00",
      DI(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      DI(0) => '0',
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\,
      S(1) => \i___65_carry_i_1__1_n_0\,
      S(0) => \i___65_carry_i_2__1_n_0\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__0\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__1\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__2\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__3\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__4\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__5\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__6\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\,
      CO(3) => \NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED\(3),
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\
    );
\status_err_statistics_cnt[31]_i_1__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFFFFE"
    )
        port map (
      I0 => \status_err_statistics_cnt[31]_i_2__1_n_0\,
      I1 => \status_err_statistics_cnt[31]_i_3__1_n_0\,
      I2 => \status_err_statistics_cnt[31]_i_4__1_n_0\,
      I3 => \status_err_statistics_cnt[31]_i_5__1_n_0\,
      I4 => \status_err_statistics_cnt[31]_i_6__1_n_0\,
      O => \status_err_statistics_cnt[31]_i_1__2_n_0\
    );
\status_err_statistics_cnt[31]_i_2__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(24),
      I1 => \^status_err_statistics_cnt\(25),
      I2 => \^status_err_statistics_cnt\(22),
      I3 => \^status_err_statistics_cnt\(23),
      I4 => \^status_err_statistics_cnt\(21),
      I5 => \^status_err_statistics_cnt\(20),
      O => \status_err_statistics_cnt[31]_i_2__1_n_0\
    );
\status_err_statistics_cnt[31]_i_3__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(30),
      I1 => \^status_err_statistics_cnt\(31),
      I2 => \^status_err_statistics_cnt\(28),
      I3 => \^status_err_statistics_cnt\(29),
      I4 => \^status_err_statistics_cnt\(27),
      I5 => \^status_err_statistics_cnt\(26),
      O => \status_err_statistics_cnt[31]_i_3__1_n_0\
    );
\status_err_statistics_cnt[31]_i_4__1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"7F"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(7),
      I1 => \^status_err_statistics_cnt\(6),
      I2 => \^status_err_statistics_cnt\(5),
      O => \status_err_statistics_cnt[31]_i_4__1_n_0\
    );
\status_err_statistics_cnt[31]_i_5__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(18),
      I1 => \^status_err_statistics_cnt\(19),
      I2 => \^status_err_statistics_cnt\(16),
      I3 => \^status_err_statistics_cnt\(17),
      I4 => \^status_err_statistics_cnt\(15),
      I5 => \^status_err_statistics_cnt\(14),
      O => \status_err_statistics_cnt[31]_i_5__1_n_0\
    );
\status_err_statistics_cnt[31]_i_6__1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(12),
      I1 => \^status_err_statistics_cnt\(13),
      I2 => \^status_err_statistics_cnt\(10),
      I3 => \^status_err_statistics_cnt\(11),
      I4 => \^status_err_statistics_cnt\(9),
      I5 => \^status_err_statistics_cnt\(8),
      O => \status_err_statistics_cnt[31]_i_6__1_n_0\
    );
\status_err_statistics_cnt_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\,
      Q => \^status_err_statistics_cnt\(0),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\,
      Q => \^status_err_statistics_cnt\(10),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\,
      Q => \^status_err_statistics_cnt\(11),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\,
      Q => \^status_err_statistics_cnt\(12),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\,
      Q => \^status_err_statistics_cnt\(13),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\,
      Q => \^status_err_statistics_cnt\(14),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\,
      Q => \^status_err_statistics_cnt\(15),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\,
      Q => \^status_err_statistics_cnt\(16),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\,
      Q => \^status_err_statistics_cnt\(17),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\,
      Q => \^status_err_statistics_cnt\(18),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\,
      Q => \^status_err_statistics_cnt\(19),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\,
      Q => \^status_err_statistics_cnt\(1),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\,
      Q => \^status_err_statistics_cnt\(20),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\,
      Q => \^status_err_statistics_cnt\(21),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\,
      Q => \^status_err_statistics_cnt\(22),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\,
      Q => \^status_err_statistics_cnt\(23),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\,
      Q => \^status_err_statistics_cnt\(24),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\,
      Q => \^status_err_statistics_cnt\(25),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\,
      Q => \^status_err_statistics_cnt\(26),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\,
      Q => \^status_err_statistics_cnt\(27),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\,
      Q => \^status_err_statistics_cnt\(28),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\,
      Q => \^status_err_statistics_cnt\(29),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\,
      Q => \^status_err_statistics_cnt\(2),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\,
      Q => \^status_err_statistics_cnt\(30),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\,
      Q => \^status_err_statistics_cnt\(31),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\,
      Q => \^status_err_statistics_cnt\(3),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\,
      Q => \^status_err_statistics_cnt\(4),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\,
      Q => \^status_err_statistics_cnt\(5),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\,
      Q => \^status_err_statistics_cnt\(6),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\,
      Q => \^status_err_statistics_cnt\(7),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\,
      Q => \^status_err_statistics_cnt\(8),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_1__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\,
      Q => \^status_err_statistics_cnt\(9),
      R => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx_lane_2 is
  port (
    \frame_align_reg[1]_0\ : out STD_LOGIC;
    \frame_align_reg[0]_0\ : out STD_LOGIC;
    ifs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    ilas_config_valid_reg : out STD_LOGIC;
    cgs_ready : out STD_LOGIC_VECTOR ( 0 to 0 );
    E : out STD_LOGIC_VECTOR ( 0 to 0 );
    Q : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_charisk_d1_reg[3]\ : out STD_LOGIC_VECTOR ( 0 to 0 );
    p_7_out : out STD_LOGIC;
    ilas_config_addr : out STD_LOGIC_VECTOR ( 1 downto 0 );
    buffer_release_n_reg : out STD_LOGIC;
    \beat_error_count_reg[1]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[1]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[0]\ : out STD_LOGIC;
    \FSM_onehot_state_reg[2]\ : out STD_LOGIC;
    rx_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    status_err_statistics_cnt : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clk : in STD_LOGIC;
    \frame_align_reg[0]_1\ : in STD_LOGIC;
    prev_was_last0 : in STD_LOGIC;
    buffer_release_n : in STD_LOGIC;
    ifs_ready_reg_0 : in STD_LOGIC;
    frame_align : in STD_LOGIC_VECTOR ( 0 to 0 );
    status_lane_ifs_ready : in STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_disable_scrambler : in STD_LOGIC;
    D : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \in_data_d1_reg[31]\ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    \in_charisk_d1_reg[3]_0\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    \FSM_onehot_state_reg[0]_0\ : in STD_LOGIC;
    cgs_beat_has_error : in STD_LOGIC;
    \FSM_onehot_state_reg[0]_1\ : in STD_LOGIC_VECTOR ( 0 to 0 );
    \phy_char_err_reg[3]_0\ : in STD_LOGIC_VECTOR ( 3 downto 0 );
    SR : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx_lane_2 : entity is "jesd204_rx_lane";
end jesd204_rx_0_jesd204_rx_lane_2;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx_lane_2 is
  signal data_aligned_s : STD_LOGIC_VECTOR ( 23 downto 0 );
  signal data_scrambled_s : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \frame_align[1]_i_1__2_n_0\ : STD_LOGIC;
  signal \^frame_align_reg[0]_0\ : STD_LOGIC;
  signal \^frame_align_reg[1]_0\ : STD_LOGIC;
  signal full_state : STD_LOGIC_VECTOR ( 32 to 32 );
  signal \i___0_carry_i_1__2_n_0\ : STD_LOGIC;
  signal \i___0_carry_i_2__2_n_0\ : STD_LOGIC;
  signal \i___65_carry_i_1__2_n_0\ : STD_LOGIC;
  signal \i___65_carry_i_2__2_n_0\ : STD_LOGIC;
  signal i_align_mux_n_52 : STD_LOGIC;
  signal i_align_mux_n_53 : STD_LOGIC;
  signal i_align_mux_n_54 : STD_LOGIC;
  signal i_cgs_n_1 : STD_LOGIC;
  signal i_ilas_monitor_n_2 : STD_LOGIC;
  signal i_ilas_monitor_n_3 : STD_LOGIC;
  signal \^ifs_ready\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \^ilas_config_valid_reg\ : STD_LOGIC;
  signal p_0_in0_in : STD_LOGIC;
  signal p_0_in1_in : STD_LOGIC;
  signal p_0_in_0 : STD_LOGIC;
  signal \^p_7_out\ : STD_LOGIC;
  signal \phy_char_err_reg_n_0_[0]\ : STD_LOGIC;
  signal state : STD_LOGIC;
  signal \^status_err_statistics_cnt\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\ : STD_LOGIC;
  signal \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_2__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_3__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_4__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_5__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_6__2_n_0\ : STD_LOGIC;
  signal \status_err_statistics_cnt[31]_i_7_n_0\ : STD_LOGIC;
  signal \NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 3 to 3 );
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \frame_align[1]_i_1__2\ : label is "soft_lutpair80";
  attribute SOFT_HLUTNM of \gen_lane[3].lane_captured[3]_i_1\ : label is "soft_lutpair80";
begin
  \frame_align_reg[0]_0\ <= \^frame_align_reg[0]_0\;
  \frame_align_reg[1]_0\ <= \^frame_align_reg[1]_0\;
  ifs_ready(0) <= \^ifs_ready\(0);
  ilas_config_valid_reg <= \^ilas_config_valid_reg\;
  p_7_out <= \^p_7_out\;
  status_err_statistics_cnt(31 downto 0) <= \^status_err_statistics_cnt\(31 downto 0);
\frame_align[1]_i_1__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"E2"
    )
        port map (
      I0 => frame_align(0),
      I1 => \^ifs_ready\(0),
      I2 => \^frame_align_reg[1]_0\,
      O => \frame_align[1]_i_1__2_n_0\
    );
\frame_align_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \frame_align_reg[0]_1\,
      Q => \^frame_align_reg[0]_0\,
      R => '0'
    );
\frame_align_reg[1]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \frame_align[1]_i_1__2_n_0\,
      Q => \^frame_align_reg[1]_0\,
      R => '0'
    );
\gen_lane[3].lane_captured[3]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \^ifs_ready\(0),
      I1 => status_lane_ifs_ready(0),
      O => E(0)
    );
\i___0_carry_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"17E8"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(0),
      I1 => \phy_char_err_reg_n_0_[0]\,
      I2 => p_0_in1_in,
      I3 => \^status_err_statistics_cnt\(1),
      O => \i___0_carry_i_1__2_n_0\
    );
\i___0_carry_i_2__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(0),
      I1 => p_0_in1_in,
      I2 => \phy_char_err_reg_n_0_[0]\,
      O => \i___0_carry_i_2__2_n_0\
    );
\i___65_carry_i_1__2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"17E8"
    )
        port map (
      I0 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      I1 => p_0_in_0,
      I2 => p_0_in0_in,
      I3 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      O => \i___65_carry_i_1__2_n_0\
    );
\i___65_carry_i_2__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"96"
    )
        port map (
      I0 => p_0_in0_in,
      I1 => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      I2 => p_0_in_0,
      O => \i___65_carry_i_2__2_n_0\
    );
i_align_mux: entity work.jesd204_rx_0_align_mux
     port map (
      D(7 downto 0) => D(7 downto 0),
      Q(7 downto 0) => Q(7 downto 0),
      SS(0) => \^p_7_out\,
      WEBWE(0) => i_align_mux_n_54,
      cfg_disable_scrambler => cfg_disable_scrambler,
      clk => clk,
      data_aligned_s(23 downto 0) => data_aligned_s(23 downto 0),
      data_scrambled_s(17 downto 2) => data_scrambled_s(31 downto 16),
      data_scrambled_s(1 downto 0) => data_scrambled_s(9 downto 8),
      ifs_ready_reg => i_align_mux_n_53,
      \ilas_config_data_reg[5]\ => \^frame_align_reg[1]_0\,
      \ilas_config_data_reg[5]_0\ => \^frame_align_reg[0]_0\,
      ilas_config_valid_reg => i_align_mux_n_52,
      ilas_config_valid_reg_0 => \^ilas_config_valid_reg\,
      ilas_config_valid_reg_1 => i_ilas_monitor_n_3,
      \in_charisk_d1_reg[3]_0\(0) => \in_charisk_d1_reg[3]\(0),
      \in_charisk_d1_reg[3]_1\(3 downto 0) => \in_charisk_d1_reg[3]_0\(3 downto 0),
      \in_data_d1_reg[31]_0\(31 downto 0) => \in_data_d1_reg[31]\(31 downto 0),
      mem_reg(0) => full_state(32),
      state => state,
      state_reg => \^ifs_ready\(0),
      \wr_addr_reg[0]\ => i_ilas_monitor_n_2
    );
i_cgs: entity work.jesd204_rx_0_jesd204_rx_cgs
     port map (
      \FSM_onehot_state_reg[0]_0\ => \FSM_onehot_state_reg[0]\,
      \FSM_onehot_state_reg[0]_1\ => \FSM_onehot_state_reg[0]_0\,
      \FSM_onehot_state_reg[0]_2\(0) => \FSM_onehot_state_reg[0]_1\(0),
      \FSM_onehot_state_reg[1]_0\ => \FSM_onehot_state_reg[1]\,
      \FSM_onehot_state_reg[2]_0\ => \FSM_onehot_state_reg[2]\,
      SR(0) => i_cgs_n_1,
      \beat_error_count_reg[1]_0\ => \beat_error_count_reg[1]\,
      cgs_beat_has_error => cgs_beat_has_error,
      cgs_ready(0) => cgs_ready(0),
      clk => clk
    );
i_descrambler: entity work.jesd204_rx_0_jesd204_scrambler
     port map (
      D(28 downto 21) => D(7 downto 0),
      D(20 downto 8) => data_aligned_s(22 downto 10),
      D(7 downto 0) => data_aligned_s(7 downto 0),
      DIADI(13 downto 8) => data_scrambled_s(15 downto 10),
      DIADI(7 downto 0) => data_scrambled_s(7 downto 0),
      Q(0) => full_state(32),
      SS(0) => \^p_7_out\,
      cfg_disable_scrambler => cfg_disable_scrambler,
      clk => clk
    );
i_elastic_buffer: entity work.jesd204_rx_0_elastic_buffer
     port map (
      SR(0) => \^p_7_out\,
      WEBWE(0) => i_align_mux_n_54,
      buffer_release_n => buffer_release_n,
      buffer_release_n_reg => buffer_release_n_reg,
      clk => clk,
      data_scrambled_s(31 downto 0) => data_scrambled_s(31 downto 0),
      rx_data(31 downto 0) => rx_data(31 downto 0)
    );
i_ilas_monitor: entity work.jesd204_rx_0_jesd204_ilas_monitor
     port map (
      D(31 downto 24) => D(7 downto 0),
      D(23 downto 0) => data_aligned_s(23 downto 0),
      clk => clk,
      ilas_config_addr(1 downto 0) => ilas_config_addr(1 downto 0),
      \ilas_config_addr_reg[1]_0\ => i_ilas_monitor_n_3,
      ilas_config_data(31 downto 0) => ilas_config_data(31 downto 0),
      ilas_config_valid_reg_0 => \^ilas_config_valid_reg\,
      ilas_config_valid_reg_1 => i_align_mux_n_52,
      prev_was_last0 => prev_was_last0,
      prev_was_last_reg_0 => i_ilas_monitor_n_2,
      state => state,
      state_reg_0 => i_align_mux_n_53,
      \wr_addr_reg[0]\ => \^ifs_ready\(0)
    );
ifs_ready_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => ifs_ready_reg_0,
      Q => \^ifs_ready\(0),
      R => '0'
    );
\phy_char_err_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(0),
      Q => \phy_char_err_reg_n_0_[0]\,
      R => i_cgs_n_1
    );
\phy_char_err_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(1),
      Q => p_0_in_0,
      R => i_cgs_n_1
    );
\phy_char_err_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(2),
      Q => p_0_in0_in,
      R => i_cgs_n_1
    );
\phy_char_err_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => '1',
      D => \phy_char_err_reg[3]_0\(3),
      Q => p_0_in1_in,
      R => i_cgs_n_1
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3\,
      CYINIT => '0',
      DI(3 downto 2) => B"00",
      DI(1) => \^status_err_statistics_cnt\(1),
      DI(0) => '0',
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7\,
      S(3 downto 2) => \^status_err_statistics_cnt\(3 downto 2),
      S(1) => \i___0_carry_i_1__2_n_0\,
      S(0) => \i___0_carry_i_2__2_n_0\
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__0\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(7 downto 4)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__1\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(11 downto 8)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__2\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(15 downto 12)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__3\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(19 downto 16)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__4\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(23 downto 20)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__5\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(27 downto 24)
    );
\status_err_statistics_cnt0_inferred__1/i___0_carry__6\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0\,
      CO(3) => \NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED\(3),
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\,
      S(3 downto 0) => \^status_err_statistics_cnt\(31 downto 28)
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry\: unisim.vcomponents.CARRY4
     port map (
      CI => '0',
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3\,
      CYINIT => '0',
      DI(3 downto 2) => B"00",
      DI(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6\,
      DI(0) => '0',
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5\,
      S(1) => \i___65_carry_i_1__2_n_0\,
      S(0) => \i___65_carry_i_2__2_n_0\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__0\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__1\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__2\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__3\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__4\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__5\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0\,
      CO(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\,
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7\
    );
\status_err_statistics_cnt0_inferred__1/i___65_carry__6\: unisim.vcomponents.CARRY4
     port map (
      CI => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0\,
      CO(3) => \NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED\(3),
      CO(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1\,
      CO(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2\,
      CO(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3\,
      CYINIT => '0',
      DI(3 downto 0) => B"0000",
      O(3) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\,
      O(2) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\,
      O(1) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\,
      O(0) => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\,
      S(3) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4\,
      S(2) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5\,
      S(1) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6\,
      S(0) => \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7\
    );
\status_err_statistics_cnt[31]_i_2__2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFFFFE"
    )
        port map (
      I0 => \status_err_statistics_cnt[31]_i_3__2_n_0\,
      I1 => \status_err_statistics_cnt[31]_i_4__2_n_0\,
      I2 => \status_err_statistics_cnt[31]_i_5__2_n_0\,
      I3 => \status_err_statistics_cnt[31]_i_6__2_n_0\,
      I4 => \status_err_statistics_cnt[31]_i_7_n_0\,
      O => \status_err_statistics_cnt[31]_i_2__2_n_0\
    );
\status_err_statistics_cnt[31]_i_3__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(24),
      I1 => \^status_err_statistics_cnt\(25),
      I2 => \^status_err_statistics_cnt\(22),
      I3 => \^status_err_statistics_cnt\(23),
      I4 => \^status_err_statistics_cnt\(21),
      I5 => \^status_err_statistics_cnt\(20),
      O => \status_err_statistics_cnt[31]_i_3__2_n_0\
    );
\status_err_statistics_cnt[31]_i_4__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(30),
      I1 => \^status_err_statistics_cnt\(31),
      I2 => \^status_err_statistics_cnt\(28),
      I3 => \^status_err_statistics_cnt\(29),
      I4 => \^status_err_statistics_cnt\(27),
      I5 => \^status_err_statistics_cnt\(26),
      O => \status_err_statistics_cnt[31]_i_4__2_n_0\
    );
\status_err_statistics_cnt[31]_i_5__2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"7F"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(7),
      I1 => \^status_err_statistics_cnt\(6),
      I2 => \^status_err_statistics_cnt\(5),
      O => \status_err_statistics_cnt[31]_i_5__2_n_0\
    );
\status_err_statistics_cnt[31]_i_6__2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(18),
      I1 => \^status_err_statistics_cnt\(19),
      I2 => \^status_err_statistics_cnt\(16),
      I3 => \^status_err_statistics_cnt\(17),
      I4 => \^status_err_statistics_cnt\(15),
      I5 => \^status_err_statistics_cnt\(14),
      O => \status_err_statistics_cnt[31]_i_6__2_n_0\
    );
\status_err_statistics_cnt[31]_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \^status_err_statistics_cnt\(12),
      I1 => \^status_err_statistics_cnt\(13),
      I2 => \^status_err_statistics_cnt\(10),
      I3 => \^status_err_statistics_cnt\(11),
      I4 => \^status_err_statistics_cnt\(9),
      I5 => \^status_err_statistics_cnt\(8),
      O => \status_err_statistics_cnt[31]_i_7_n_0\
    );
\status_err_statistics_cnt_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7\,
      Q => \^status_err_statistics_cnt\(0),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5\,
      Q => \^status_err_statistics_cnt\(10),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4\,
      Q => \^status_err_statistics_cnt\(11),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7\,
      Q => \^status_err_statistics_cnt\(12),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6\,
      Q => \^status_err_statistics_cnt\(13),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5\,
      Q => \^status_err_statistics_cnt\(14),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4\,
      Q => \^status_err_statistics_cnt\(15),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7\,
      Q => \^status_err_statistics_cnt\(16),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6\,
      Q => \^status_err_statistics_cnt\(17),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5\,
      Q => \^status_err_statistics_cnt\(18),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4\,
      Q => \^status_err_statistics_cnt\(19),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6\,
      Q => \^status_err_statistics_cnt\(1),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7\,
      Q => \^status_err_statistics_cnt\(20),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6\,
      Q => \^status_err_statistics_cnt\(21),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5\,
      Q => \^status_err_statistics_cnt\(22),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4\,
      Q => \^status_err_statistics_cnt\(23),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7\,
      Q => \^status_err_statistics_cnt\(24),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6\,
      Q => \^status_err_statistics_cnt\(25),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5\,
      Q => \^status_err_statistics_cnt\(26),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4\,
      Q => \^status_err_statistics_cnt\(27),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7\,
      Q => \^status_err_statistics_cnt\(28),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6\,
      Q => \^status_err_statistics_cnt\(29),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5\,
      Q => \^status_err_statistics_cnt\(2),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5\,
      Q => \^status_err_statistics_cnt\(30),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4\,
      Q => \^status_err_statistics_cnt\(31),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4\,
      Q => \^status_err_statistics_cnt\(3),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7\,
      Q => \^status_err_statistics_cnt\(4),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6\,
      Q => \^status_err_statistics_cnt\(5),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5\,
      Q => \^status_err_statistics_cnt\(6),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4\,
      Q => \^status_err_statistics_cnt\(7),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7\,
      Q => \^status_err_statistics_cnt\(8),
      R => SR(0)
    );
\status_err_statistics_cnt_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => clk,
      CE => \status_err_statistics_cnt[31]_i_2__2_n_0\,
      D => \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6\,
      Q => \^status_err_statistics_cnt\(9),
      R => SR(0)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0_jesd204_rx is
  port (
    clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    phy_data : in STD_LOGIC_VECTOR ( 127 downto 0 );
    phy_header : in STD_LOGIC_VECTOR ( 7 downto 0 );
    phy_charisk : in STD_LOGIC_VECTOR ( 15 downto 0 );
    phy_notintable : in STD_LOGIC_VECTOR ( 15 downto 0 );
    phy_disperr : in STD_LOGIC_VECTOR ( 15 downto 0 );
    phy_block_sync : in STD_LOGIC_VECTOR ( 3 downto 0 );
    sysref : in STD_LOGIC;
    lmfc_edge : out STD_LOGIC;
    lmfc_clk : out STD_LOGIC;
    event_sysref_alignment_error : out STD_LOGIC;
    event_sysref_edge : out STD_LOGIC;
    sync : out STD_LOGIC_VECTOR ( 0 to 0 );
    phy_en_char_align : out STD_LOGIC;
    rx_data : out STD_LOGIC_VECTOR ( 127 downto 0 );
    rx_valid : out STD_LOGIC;
    rx_eof : out STD_LOGIC_VECTOR ( 3 downto 0 );
    rx_sof : out STD_LOGIC_VECTOR ( 3 downto 0 );
    cfg_lanes_disable : in STD_LOGIC_VECTOR ( 3 downto 0 );
    cfg_links_disable : in STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_beats_per_multiframe : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_octets_per_frame : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_lmfc_offset : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_sysref_disable : in STD_LOGIC;
    cfg_sysref_oneshot : in STD_LOGIC;
    cfg_buffer_early_release : in STD_LOGIC;
    cfg_buffer_delay : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_disable_char_replacement : in STD_LOGIC;
    cfg_disable_scrambler : in STD_LOGIC;
    ctrl_err_statistics_reset : in STD_LOGIC;
    ctrl_err_statistics_mask : in STD_LOGIC_VECTOR ( 6 downto 0 );
    status_err_statistics_cnt : out STD_LOGIC_VECTOR ( 127 downto 0 );
    ilas_config_valid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ilas_config_addr : out STD_LOGIC_VECTOR ( 7 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 127 downto 0 );
    status_ctrl_state : out STD_LOGIC_VECTOR ( 1 downto 0 );
    status_lane_cgs_state : out STD_LOGIC_VECTOR ( 7 downto 0 );
    status_lane_ifs_ready : out STD_LOGIC_VECTOR ( 3 downto 0 );
    status_lane_latency : out STD_LOGIC_VECTOR ( 55 downto 0 );
    status_lane_emb_state : out STD_LOGIC_VECTOR ( 11 downto 0 )
  );
  attribute ALIGN_MUX_REGISTERED : integer;
  attribute ALIGN_MUX_REGISTERED of jesd204_rx_0_jesd204_rx : entity is 0;
  attribute CHAR_INFO_REGISTERED : integer;
  attribute CHAR_INFO_REGISTERED of jesd204_rx_0_jesd204_rx : entity is 0;
  attribute CW : integer;
  attribute CW of jesd204_rx_0_jesd204_rx : entity is 16;
  attribute DATA_PATH_WIDTH : integer;
  attribute DATA_PATH_WIDTH of jesd204_rx_0_jesd204_rx : entity is 4;
  attribute DW : integer;
  attribute DW of jesd204_rx_0_jesd204_rx : entity is 128;
  attribute ELASTIC_BUFFER_SIZE : integer;
  attribute ELASTIC_BUFFER_SIZE of jesd204_rx_0_jesd204_rx : entity is 128;
  attribute HW : integer;
  attribute HW of jesd204_rx_0_jesd204_rx : entity is 8;
  attribute LINK_MODE : integer;
  attribute LINK_MODE of jesd204_rx_0_jesd204_rx : entity is 1;
  attribute LMFC_COUNTER_WIDTH : integer;
  attribute LMFC_COUNTER_WIDTH of jesd204_rx_0_jesd204_rx : entity is 7;
  attribute MAX_BEATS_PER_MULTIFRAME : integer;
  attribute MAX_BEATS_PER_MULTIFRAME of jesd204_rx_0_jesd204_rx : entity is 128;
  attribute MAX_OCTETS_PER_FRAME : integer;
  attribute MAX_OCTETS_PER_FRAME of jesd204_rx_0_jesd204_rx : entity is 16;
  attribute MAX_OCTETS_PER_MULTIFRAME : integer;
  attribute MAX_OCTETS_PER_MULTIFRAME of jesd204_rx_0_jesd204_rx : entity is 512;
  attribute NUM_INPUT_PIPELINE : integer;
  attribute NUM_INPUT_PIPELINE of jesd204_rx_0_jesd204_rx : entity is 1;
  attribute NUM_LANES : integer;
  attribute NUM_LANES of jesd204_rx_0_jesd204_rx : entity is 4;
  attribute NUM_LINKS : integer;
  attribute NUM_LINKS of jesd204_rx_0_jesd204_rx : entity is 1;
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of jesd204_rx_0_jesd204_rx : entity is "jesd204_rx";
  attribute SCRAMBLER_REGISTERED : integer;
  attribute SCRAMBLER_REGISTERED of jesd204_rx_0_jesd204_rx : entity is 0;
end jesd204_rx_0_jesd204_rx;

architecture STRUCTURE of jesd204_rx_0_jesd204_rx is
  signal \<const0>\ : STD_LOGIC;
  signal buffer_release_d1 : STD_LOGIC;
  signal buffer_release_n : STD_LOGIC;
  signal buffer_release_opportunity : STD_LOGIC;
  signal cgs_beat_has_error : STD_LOGIC;
  signal cgs_beat_has_error_0 : STD_LOGIC;
  signal cgs_beat_has_error_4 : STD_LOGIC;
  signal cgs_beat_has_error_8 : STD_LOGIC;
  signal cgs_ready : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cgs_reset : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal charisk28 : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal charisk28_12 : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal charisk28_13 : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal charisk28_14 : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal data_aligned_s : STD_LOGIC_VECTOR ( 31 downto 24 );
  signal data_aligned_s_10 : STD_LOGIC_VECTOR ( 31 downto 24 );
  signal data_aligned_s_2 : STD_LOGIC_VECTOR ( 31 downto 24 );
  signal data_aligned_s_6 : STD_LOGIC_VECTOR ( 31 downto 24 );
  signal eof_reset : STD_LOGIC;
  signal frame_align : STD_LOGIC_VECTOR ( 1 to 1 );
  signal frame_align_1 : STD_LOGIC_VECTOR ( 1 to 1 );
  signal frame_align_5 : STD_LOGIC_VECTOR ( 1 to 1 );
  signal frame_align_9 : STD_LOGIC_VECTOR ( 1 to 1 );
  signal \i_align_mux/in_charisk_d1\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \i_align_mux/in_charisk_d1_15\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \i_align_mux/in_charisk_d1_18\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \i_align_mux/in_charisk_d1_20\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \i_ilas_monitor/prev_was_last0\ : STD_LOGIC;
  signal \i_ilas_monitor/prev_was_last0_11\ : STD_LOGIC;
  signal \i_ilas_monitor/prev_was_last0_3\ : STD_LOGIC;
  signal \i_ilas_monitor/prev_was_last0_7\ : STD_LOGIC;
  signal i_input_pipeline_stage_n_0 : STD_LOGIC;
  signal i_input_pipeline_stage_n_10 : STD_LOGIC;
  signal i_input_pipeline_stage_n_15 : STD_LOGIC;
  signal i_input_pipeline_stage_n_157 : STD_LOGIC;
  signal i_input_pipeline_stage_n_158 : STD_LOGIC;
  signal i_input_pipeline_stage_n_159 : STD_LOGIC;
  signal i_input_pipeline_stage_n_160 : STD_LOGIC;
  signal i_input_pipeline_stage_n_161 : STD_LOGIC;
  signal i_input_pipeline_stage_n_173 : STD_LOGIC;
  signal i_input_pipeline_stage_n_174 : STD_LOGIC;
  signal i_input_pipeline_stage_n_175 : STD_LOGIC;
  signal i_input_pipeline_stage_n_176 : STD_LOGIC;
  signal i_input_pipeline_stage_n_177 : STD_LOGIC;
  signal i_input_pipeline_stage_n_189 : STD_LOGIC;
  signal i_input_pipeline_stage_n_190 : STD_LOGIC;
  signal i_input_pipeline_stage_n_191 : STD_LOGIC;
  signal i_input_pipeline_stage_n_192 : STD_LOGIC;
  signal i_input_pipeline_stage_n_193 : STD_LOGIC;
  signal i_input_pipeline_stage_n_205 : STD_LOGIC;
  signal i_input_pipeline_stage_n_206 : STD_LOGIC;
  signal i_input_pipeline_stage_n_207 : STD_LOGIC;
  signal i_input_pipeline_stage_n_208 : STD_LOGIC;
  signal i_input_pipeline_stage_n_209 : STD_LOGIC;
  signal i_input_pipeline_stage_n_212 : STD_LOGIC;
  signal i_input_pipeline_stage_n_213 : STD_LOGIC;
  signal i_input_pipeline_stage_n_214 : STD_LOGIC;
  signal i_input_pipeline_stage_n_215 : STD_LOGIC;
  signal i_input_pipeline_stage_n_5 : STD_LOGIC;
  signal i_lmfc_n_4 : STD_LOGIC;
  signal ifs_ready : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal ifs_reset : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal in_data_d1 : STD_LOGIC_VECTOR ( 31 downto 24 );
  signal in_data_d1_16 : STD_LOGIC_VECTOR ( 31 downto 24 );
  signal in_data_d1_19 : STD_LOGIC_VECTOR ( 31 downto 24 );
  signal in_data_d1_21 : STD_LOGIC_VECTOR ( 31 downto 24 );
  signal latency_monitor_reset : STD_LOGIC;
  signal \^lmfc_edge\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[0].i_lane_n_49\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[0].i_lane_n_52\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[0].i_lane_n_54\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[1].i_lane_n_18\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[1].i_lane_n_20\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[2].i_lane_n_18\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[2].i_lane_n_20\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[2].i_lane_n_6\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[3].i_lane_n_18\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[3].i_lane_n_19\ : STD_LOGIC;
  signal \mode_8b10b.gen_lane[3].i_lane_n_21\ : STD_LOGIC;
  signal p_1_out : STD_LOGIC;
  signal p_27_out : STD_LOGIC;
  signal p_4_out : STD_LOGIC;
  signal p_7_out : STD_LOGIC;
  signal p_7_out_17 : STD_LOGIC;
  signal p_9_out : STD_LOGIC;
  signal phy_data_r : STD_LOGIC_VECTOR ( 127 downto 0 );
  signal \^rx_eof\ : STD_LOGIC_VECTOR ( 3 to 3 );
  signal \^rx_sof\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal status_err_statistics_cnt0 : STD_LOGIC;
  signal \^status_lane_cgs_state\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \^status_lane_ifs_ready\ : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal \^status_lane_latency\ : STD_LOGIC_VECTOR ( 55 downto 0 );
begin
  lmfc_edge <= \^lmfc_edge\;
  rx_eof(3) <= \^rx_eof\(3);
  rx_eof(2 downto 1) <= \^rx_sof\(3 downto 2);
  rx_eof(0) <= \^rx_sof\(3);
  rx_sof(3 downto 2) <= \^rx_sof\(3 downto 2);
  rx_sof(1) <= \^rx_sof\(3);
  rx_sof(0) <= \^rx_sof\(0);
  status_lane_cgs_state(7 downto 0) <= \^status_lane_cgs_state\(7 downto 0);
  status_lane_emb_state(11) <= \<const0>\;
  status_lane_emb_state(10) <= \<const0>\;
  status_lane_emb_state(9) <= \<const0>\;
  status_lane_emb_state(8) <= \<const0>\;
  status_lane_emb_state(7) <= \<const0>\;
  status_lane_emb_state(6) <= \<const0>\;
  status_lane_emb_state(5) <= \<const0>\;
  status_lane_emb_state(4) <= \<const0>\;
  status_lane_emb_state(3) <= \<const0>\;
  status_lane_emb_state(2) <= \<const0>\;
  status_lane_emb_state(1) <= \<const0>\;
  status_lane_emb_state(0) <= \<const0>\;
  status_lane_ifs_ready(3 downto 0) <= \^status_lane_ifs_ready\(3 downto 0);
  status_lane_latency(55 downto 0) <= \^status_lane_latency\(55 downto 0);
GND: unisim.vcomponents.GND
     port map (
      G => \<const0>\
    );
buffer_release_d1_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \mode_8b10b.gen_lane[3].i_lane_n_18\,
      Q => buffer_release_d1,
      R => '0'
    );
buffer_release_n_reg: unisim.vcomponents.FDSE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => \mode_8b10b.gen_lane[0].i_lane_n_54\,
      Q => buffer_release_n,
      S => reset
    );
buffer_release_opportunity_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => i_lmfc_n_4,
      Q => buffer_release_opportunity,
      R => '0'
    );
eof_reset_reg: unisim.vcomponents.FDRE
    generic map(
      INIT => '1'
    )
        port map (
      C => clk,
      CE => '1',
      D => buffer_release_n,
      Q => eof_reset,
      R => '0'
    );
i_eof_gen: entity work.jesd204_rx_0_jesd204_eof_generator
     port map (
      cfg_octets_per_frame(3 downto 0) => cfg_octets_per_frame(3 downto 0),
      clk => clk,
      eof_reset => eof_reset,
      rx_eof(0) => \^rx_eof\(3),
      rx_sof(2 downto 1) => \^rx_sof\(3 downto 2),
      rx_sof(0) => \^rx_sof\(0)
    );
i_input_pipeline_stage: entity work.\jesd204_rx_0_pipeline_stage__parameterized2\
     port map (
      D(7 downto 0) => data_aligned_s_10(31 downto 24),
      \FSM_onehot_state[2]_i_2_0\ => \^status_lane_cgs_state\(1),
      \FSM_onehot_state[2]_i_2_1\ => \^status_lane_cgs_state\(0),
      \FSM_onehot_state[2]_i_2__0_0\ => \^status_lane_cgs_state\(3),
      \FSM_onehot_state[2]_i_2__0_1\ => \^status_lane_cgs_state\(2),
      \FSM_onehot_state[2]_i_2__1_0\ => \^status_lane_cgs_state\(5),
      \FSM_onehot_state[2]_i_2__1_1\ => \^status_lane_cgs_state\(4),
      \FSM_onehot_state[2]_i_2__2_0\ => \^status_lane_cgs_state\(7),
      \FSM_onehot_state[2]_i_2__2_1\ => \^status_lane_cgs_state\(6),
      \FSM_onehot_state_reg[0]\ => i_input_pipeline_stage_n_161,
      \FSM_onehot_state_reg[0]_0\ => i_input_pipeline_stage_n_177,
      \FSM_onehot_state_reg[0]_1\ => i_input_pipeline_stage_n_193,
      \FSM_onehot_state_reg[0]_10\ => \mode_8b10b.gen_lane[3].i_lane_n_19\,
      \FSM_onehot_state_reg[0]_2\ => i_input_pipeline_stage_n_209,
      \FSM_onehot_state_reg[0]_3\ => \mode_8b10b.gen_lane[0].i_lane_n_52\,
      \FSM_onehot_state_reg[0]_4\ => \mode_8b10b.gen_lane[0].i_lane_n_49\,
      \FSM_onehot_state_reg[0]_5\ => \mode_8b10b.gen_lane[1].i_lane_n_20\,
      \FSM_onehot_state_reg[0]_6\ => \mode_8b10b.gen_lane[1].i_lane_n_18\,
      \FSM_onehot_state_reg[0]_7\ => \mode_8b10b.gen_lane[2].i_lane_n_20\,
      \FSM_onehot_state_reg[0]_8\ => \mode_8b10b.gen_lane[2].i_lane_n_18\,
      \FSM_onehot_state_reg[0]_9\ => \mode_8b10b.gen_lane[3].i_lane_n_21\,
      Q(0) => \i_align_mux/in_charisk_d1\(3),
      cgs_beat_has_error => cgs_beat_has_error_8,
      cgs_beat_has_error_11 => cgs_beat_has_error,
      cgs_beat_has_error_5 => cgs_beat_has_error_4,
      cgs_beat_has_error_8 => cgs_beat_has_error_0,
      charisk28(3 downto 0) => charisk28_14(3 downto 0),
      charisk28_0(3 downto 0) => charisk28_13(3 downto 0),
      charisk28_1(3 downto 0) => charisk28_12(3 downto 0),
      charisk28_2(3 downto 0) => charisk28(3 downto 0),
      clk => clk,
      ctrl_err_statistics_mask(2 downto 0) => ctrl_err_statistics_mask(2 downto 0),
      frame_align(0) => frame_align_9(1),
      frame_align_10(0) => frame_align(1),
      frame_align_4(0) => frame_align_5(1),
      frame_align_7(0) => frame_align_1(1),
      \frame_align_reg[0]\ => \^status_lane_latency\(0),
      \frame_align_reg[0]_0\ => \^status_lane_latency\(14),
      \frame_align_reg[0]_1\ => \^status_lane_latency\(28),
      \frame_align_reg[0]_2\ => \^status_lane_latency\(42),
      ifs_ready(3 downto 0) => ifs_ready(3 downto 0),
      ifs_ready_reg => i_input_pipeline_stage_n_0,
      ifs_ready_reg_0 => i_input_pipeline_stage_n_5,
      ifs_ready_reg_1 => i_input_pipeline_stage_n_10,
      ifs_ready_reg_2 => i_input_pipeline_stage_n_15,
      ifs_ready_reg_3 => i_input_pipeline_stage_n_212,
      ifs_ready_reg_4 => i_input_pipeline_stage_n_213,
      ifs_ready_reg_5 => i_input_pipeline_stage_n_214,
      ifs_ready_reg_6 => i_input_pipeline_stage_n_215,
      ifs_ready_reg_7(3 downto 0) => ifs_reset(3 downto 0),
      \ilas_config_data_reg[24]\ => \^status_lane_latency\(1),
      \ilas_config_data_reg[24]_0\ => \^status_lane_latency\(15),
      \ilas_config_data_reg[24]_1\ => \^status_lane_latency\(29),
      \ilas_config_data_reg[24]_2\ => \^status_lane_latency\(43),
      \ilas_config_data_reg[31]\(7 downto 0) => in_data_d1(31 downto 24),
      \ilas_config_data_reg[31]_0\(7 downto 0) => in_data_d1_16(31 downto 24),
      \ilas_config_data_reg[31]_1\(7 downto 0) => in_data_d1_19(31 downto 24),
      \ilas_config_data_reg[31]_2\(7 downto 0) => in_data_d1_21(31 downto 24),
      \in_dly_reg[107]_0\(7 downto 0) => data_aligned_s_6(31 downto 24),
      \in_dly_reg[139]_0\(7 downto 0) => data_aligned_s_2(31 downto 24),
      \in_dly_reg[171]_0\(7 downto 0) => data_aligned_s(31 downto 24),
      \in_dly_reg[187]_0\(127 downto 0) => phy_data_r(127 downto 0),
      \in_dly_reg[187]_1\(175 downto 48) => phy_data(127 downto 0),
      \in_dly_reg[187]_1\(47 downto 32) => phy_charisk(15 downto 0),
      \in_dly_reg[187]_1\(31 downto 16) => phy_notintable(15 downto 0),
      \in_dly_reg[187]_1\(15 downto 0) => phy_disperr(15 downto 0),
      \in_dly_reg[23]_0\(3) => i_input_pipeline_stage_n_157,
      \in_dly_reg[23]_0\(2) => i_input_pipeline_stage_n_158,
      \in_dly_reg[23]_0\(1) => i_input_pipeline_stage_n_159,
      \in_dly_reg[23]_0\(0) => i_input_pipeline_stage_n_160,
      \in_dly_reg[27]_0\(3) => i_input_pipeline_stage_n_173,
      \in_dly_reg[27]_0\(2) => i_input_pipeline_stage_n_174,
      \in_dly_reg[27]_0\(1) => i_input_pipeline_stage_n_175,
      \in_dly_reg[27]_0\(0) => i_input_pipeline_stage_n_176,
      \in_dly_reg[31]_0\(3) => i_input_pipeline_stage_n_189,
      \in_dly_reg[31]_0\(2) => i_input_pipeline_stage_n_190,
      \in_dly_reg[31]_0\(1) => i_input_pipeline_stage_n_191,
      \in_dly_reg[31]_0\(0) => i_input_pipeline_stage_n_192,
      \in_dly_reg[35]_0\(3) => i_input_pipeline_stage_n_205,
      \in_dly_reg[35]_0\(2) => i_input_pipeline_stage_n_206,
      \in_dly_reg[35]_0\(1) => i_input_pipeline_stage_n_207,
      \in_dly_reg[35]_0\(0) => i_input_pipeline_stage_n_208,
      prev_was_last0 => \i_ilas_monitor/prev_was_last0_11\,
      prev_was_last0_3 => \i_ilas_monitor/prev_was_last0_7\,
      prev_was_last0_6 => \i_ilas_monitor/prev_was_last0_3\,
      prev_was_last0_9 => \i_ilas_monitor/prev_was_last0\,
      prev_was_last_reg(0) => \i_align_mux/in_charisk_d1_15\(3),
      prev_was_last_reg_0(0) => \i_align_mux/in_charisk_d1_18\(3),
      prev_was_last_reg_1(0) => \i_align_mux/in_charisk_d1_20\(3)
    );
i_lmfc: entity work.jesd204_rx_0_jesd204_lmfc
     port map (
      cfg_beats_per_multiframe(7 downto 0) => cfg_beats_per_multiframe(7 downto 0),
      cfg_buffer_delay(7 downto 0) => cfg_buffer_delay(7 downto 0),
      cfg_buffer_early_release => cfg_buffer_early_release,
      cfg_buffer_early_release_0 => i_lmfc_n_4,
      cfg_lmfc_offset(7 downto 0) => cfg_lmfc_offset(7 downto 0),
      cfg_sysref_disable => cfg_sysref_disable,
      cfg_sysref_oneshot => cfg_sysref_oneshot,
      clk => clk,
      event_sysref_alignment_error => event_sysref_alignment_error,
      lmfc_clk => lmfc_clk,
      lmfc_edge_reg_0 => \^lmfc_edge\,
      reset => reset,
      sysref => sysref,
      sysref_edge_reg_0 => event_sysref_edge
    );
i_output_pipeline_stage: entity work.\jesd204_rx_0_pipeline_stage__parameterized3\
     port map (
      buffer_release_d1 => buffer_release_d1,
      clk => clk,
      rx_valid => rx_valid
    );
\mode_8b10b.gen_lane[0].i_lane\: entity work.jesd204_rx_0_jesd204_rx_lane
     port map (
      D(7 downto 0) => data_aligned_s_10(31 downto 24),
      E(0) => p_9_out,
      \FSM_onehot_state_reg[0]\ => \mode_8b10b.gen_lane[0].i_lane_n_52\,
      \FSM_onehot_state_reg[0]_0\ => i_input_pipeline_stage_n_161,
      \FSM_onehot_state_reg[0]_1\(0) => cgs_reset(0),
      \FSM_onehot_state_reg[1]\ => \^status_lane_cgs_state\(0),
      \FSM_onehot_state_reg[2]\ => \^status_lane_cgs_state\(1),
      Q(7 downto 0) => in_data_d1(31 downto 24),
      SR(0) => status_err_statistics_cnt0,
      \beat_error_count_reg[1]\ => \mode_8b10b.gen_lane[0].i_lane_n_49\,
      buffer_release_n => buffer_release_n,
      buffer_release_n_reg => \mode_8b10b.gen_lane[2].i_lane_n_6\,
      buffer_release_opportunity => buffer_release_opportunity,
      buffer_release_opportunity_reg => \mode_8b10b.gen_lane[0].i_lane_n_54\,
      cfg_disable_scrambler => cfg_disable_scrambler,
      cfg_lanes_disable(1) => cfg_lanes_disable(3),
      cfg_lanes_disable(0) => cfg_lanes_disable(0),
      cgs_beat_has_error => cgs_beat_has_error_8,
      cgs_ready(0) => cgs_ready(0),
      clk => clk,
      ctrl_err_statistics_reset => ctrl_err_statistics_reset,
      frame_align(0) => frame_align_9(1),
      \frame_align_reg[0]_0\ => \^status_lane_latency\(0),
      \frame_align_reg[0]_1\ => i_input_pipeline_stage_n_0,
      \frame_align_reg[1]_0\ => \^status_lane_latency\(1),
      ifs_ready(0) => ifs_ready(0),
      ifs_ready_reg_0 => i_input_pipeline_stage_n_212,
      ilas_config_addr(1 downto 0) => ilas_config_addr(1 downto 0),
      ilas_config_data(31 downto 0) => ilas_config_data(31 downto 0),
      ilas_config_valid_reg => ilas_config_valid(0),
      \in_charisk_d1_reg[3]\(0) => \i_align_mux/in_charisk_d1\(3),
      \in_charisk_d1_reg[3]_0\(3 downto 0) => charisk28_14(3 downto 0),
      \in_data_d1_reg[31]\(31 downto 0) => phy_data_r(31 downto 0),
      mem_reg => \mode_8b10b.gen_lane[3].i_lane_n_18\,
      p_7_out => p_7_out,
      \phy_char_err_reg[3]_0\(3) => i_input_pipeline_stage_n_157,
      \phy_char_err_reg[3]_0\(2) => i_input_pipeline_stage_n_158,
      \phy_char_err_reg[3]_0\(1) => i_input_pipeline_stage_n_159,
      \phy_char_err_reg[3]_0\(0) => i_input_pipeline_stage_n_160,
      prev_was_last0 => \i_ilas_monitor/prev_was_last0_11\,
      reset => reset,
      rx_data(31 downto 0) => rx_data(31 downto 0),
      status_err_statistics_cnt(31 downto 0) => status_err_statistics_cnt(31 downto 0),
      status_lane_ifs_ready(0) => \^status_lane_ifs_ready\(0)
    );
\mode_8b10b.gen_lane[1].i_lane\: entity work.jesd204_rx_0_jesd204_rx_lane_0
     port map (
      D(7 downto 0) => data_aligned_s_6(31 downto 24),
      E(0) => p_7_out_17,
      \FSM_onehot_state_reg[0]\ => \mode_8b10b.gen_lane[1].i_lane_n_20\,
      \FSM_onehot_state_reg[0]_0\ => i_input_pipeline_stage_n_177,
      \FSM_onehot_state_reg[0]_1\(0) => cgs_reset(1),
      \FSM_onehot_state_reg[1]\ => \^status_lane_cgs_state\(2),
      \FSM_onehot_state_reg[2]\ => \^status_lane_cgs_state\(3),
      Q(7 downto 0) => in_data_d1_16(31 downto 24),
      SR(0) => status_err_statistics_cnt0,
      \beat_error_count_reg[1]\ => \mode_8b10b.gen_lane[1].i_lane_n_18\,
      buffer_release_n => buffer_release_n,
      cfg_disable_scrambler => cfg_disable_scrambler,
      cgs_beat_has_error => cgs_beat_has_error_4,
      cgs_ready(0) => cgs_ready(1),
      clk => clk,
      frame_align(0) => frame_align_5(1),
      \frame_align_reg[0]_0\ => \^status_lane_latency\(14),
      \frame_align_reg[0]_1\ => i_input_pipeline_stage_n_5,
      \frame_align_reg[1]_0\ => \^status_lane_latency\(15),
      ifs_ready(0) => ifs_ready(1),
      ifs_ready_reg_0 => i_input_pipeline_stage_n_213,
      ilas_config_addr(1 downto 0) => ilas_config_addr(3 downto 2),
      ilas_config_data(31 downto 0) => ilas_config_data(63 downto 32),
      ilas_config_valid_reg => ilas_config_valid(1),
      \in_charisk_d1_reg[3]\(0) => \i_align_mux/in_charisk_d1_15\(3),
      \in_charisk_d1_reg[3]_0\(3 downto 0) => charisk28_13(3 downto 0),
      \in_data_d1_reg[31]\(31 downto 0) => phy_data_r(63 downto 32),
      mem_reg => \mode_8b10b.gen_lane[3].i_lane_n_18\,
      p_27_out => p_27_out,
      \phy_char_err_reg[3]_0\(3) => i_input_pipeline_stage_n_173,
      \phy_char_err_reg[3]_0\(2) => i_input_pipeline_stage_n_174,
      \phy_char_err_reg[3]_0\(1) => i_input_pipeline_stage_n_175,
      \phy_char_err_reg[3]_0\(0) => i_input_pipeline_stage_n_176,
      prev_was_last0 => \i_ilas_monitor/prev_was_last0_7\,
      rx_data(31 downto 0) => rx_data(63 downto 32),
      status_err_statistics_cnt(31 downto 0) => status_err_statistics_cnt(63 downto 32),
      status_lane_ifs_ready(0) => \^status_lane_ifs_ready\(1)
    );
\mode_8b10b.gen_lane[2].i_lane\: entity work.jesd204_rx_0_jesd204_rx_lane_1
     port map (
      D(7 downto 0) => data_aligned_s_2(31 downto 24),
      E(0) => p_4_out,
      \FSM_onehot_state_reg[0]\ => \mode_8b10b.gen_lane[2].i_lane_n_20\,
      \FSM_onehot_state_reg[0]_0\ => i_input_pipeline_stage_n_193,
      \FSM_onehot_state_reg[0]_1\(0) => cgs_reset(2),
      \FSM_onehot_state_reg[1]\ => \^status_lane_cgs_state\(4),
      \FSM_onehot_state_reg[2]\ => \^status_lane_cgs_state\(5),
      Q(7 downto 0) => in_data_d1_19(31 downto 24),
      SR(0) => status_err_statistics_cnt0,
      \beat_error_count_reg[1]\ => \mode_8b10b.gen_lane[2].i_lane_n_18\,
      buffer_release_n => buffer_release_n,
      cfg_disable_scrambler => cfg_disable_scrambler,
      cfg_lanes_disable(1 downto 0) => cfg_lanes_disable(2 downto 1),
      \cfg_lanes_disable[2]\ => \mode_8b10b.gen_lane[2].i_lane_n_6\,
      cgs_beat_has_error => cgs_beat_has_error_0,
      cgs_ready(0) => cgs_ready(2),
      clk => clk,
      frame_align(0) => frame_align_1(1),
      \frame_align_reg[0]_0\ => \^status_lane_latency\(28),
      \frame_align_reg[0]_1\ => i_input_pipeline_stage_n_10,
      \frame_align_reg[1]_0\ => \^status_lane_latency\(29),
      ifs_ready(0) => ifs_ready(2),
      ifs_ready_reg_0 => i_input_pipeline_stage_n_214,
      ilas_config_addr(1 downto 0) => ilas_config_addr(5 downto 4),
      ilas_config_data(31 downto 0) => ilas_config_data(95 downto 64),
      ilas_config_valid_reg => ilas_config_valid(2),
      \in_charisk_d1_reg[3]\(0) => \i_align_mux/in_charisk_d1_18\(3),
      \in_charisk_d1_reg[3]_0\(3 downto 0) => charisk28_12(3 downto 0),
      \in_data_d1_reg[31]\(31 downto 0) => phy_data_r(95 downto 64),
      mem_reg => \mode_8b10b.gen_lane[3].i_lane_n_18\,
      p_27_out => p_27_out,
      \phy_char_err_reg[3]_0\(3) => i_input_pipeline_stage_n_189,
      \phy_char_err_reg[3]_0\(2) => i_input_pipeline_stage_n_190,
      \phy_char_err_reg[3]_0\(1) => i_input_pipeline_stage_n_191,
      \phy_char_err_reg[3]_0\(0) => i_input_pipeline_stage_n_192,
      prev_was_last0 => \i_ilas_monitor/prev_was_last0_3\,
      rx_data(31 downto 0) => rx_data(95 downto 64),
      status_err_statistics_cnt(31 downto 0) => status_err_statistics_cnt(95 downto 64),
      status_lane_ifs_ready(0) => \^status_lane_ifs_ready\(2)
    );
\mode_8b10b.gen_lane[3].i_lane\: entity work.jesd204_rx_0_jesd204_rx_lane_2
     port map (
      D(7 downto 0) => data_aligned_s(31 downto 24),
      E(0) => p_1_out,
      \FSM_onehot_state_reg[0]\ => \mode_8b10b.gen_lane[3].i_lane_n_21\,
      \FSM_onehot_state_reg[0]_0\ => i_input_pipeline_stage_n_209,
      \FSM_onehot_state_reg[0]_1\(0) => cgs_reset(3),
      \FSM_onehot_state_reg[1]\ => \^status_lane_cgs_state\(6),
      \FSM_onehot_state_reg[2]\ => \^status_lane_cgs_state\(7),
      Q(7 downto 0) => in_data_d1_21(31 downto 24),
      SR(0) => status_err_statistics_cnt0,
      \beat_error_count_reg[1]\ => \mode_8b10b.gen_lane[3].i_lane_n_19\,
      buffer_release_n => buffer_release_n,
      buffer_release_n_reg => \mode_8b10b.gen_lane[3].i_lane_n_18\,
      cfg_disable_scrambler => cfg_disable_scrambler,
      cgs_beat_has_error => cgs_beat_has_error,
      cgs_ready(0) => cgs_ready(3),
      clk => clk,
      frame_align(0) => frame_align(1),
      \frame_align_reg[0]_0\ => \^status_lane_latency\(42),
      \frame_align_reg[0]_1\ => i_input_pipeline_stage_n_15,
      \frame_align_reg[1]_0\ => \^status_lane_latency\(43),
      ifs_ready(0) => ifs_ready(3),
      ifs_ready_reg_0 => i_input_pipeline_stage_n_215,
      ilas_config_addr(1 downto 0) => ilas_config_addr(7 downto 6),
      ilas_config_data(31 downto 0) => ilas_config_data(127 downto 96),
      ilas_config_valid_reg => ilas_config_valid(3),
      \in_charisk_d1_reg[3]\(0) => \i_align_mux/in_charisk_d1_20\(3),
      \in_charisk_d1_reg[3]_0\(3 downto 0) => charisk28(3 downto 0),
      \in_data_d1_reg[31]\(31 downto 0) => phy_data_r(127 downto 96),
      p_7_out => p_7_out,
      \phy_char_err_reg[3]_0\(3) => i_input_pipeline_stage_n_205,
      \phy_char_err_reg[3]_0\(2) => i_input_pipeline_stage_n_206,
      \phy_char_err_reg[3]_0\(1) => i_input_pipeline_stage_n_207,
      \phy_char_err_reg[3]_0\(0) => i_input_pipeline_stage_n_208,
      prev_was_last0 => \i_ilas_monitor/prev_was_last0\,
      rx_data(31 downto 0) => rx_data(127 downto 96),
      status_err_statistics_cnt(31 downto 0) => status_err_statistics_cnt(127 downto 96),
      status_lane_ifs_ready(0) => \^status_lane_ifs_ready\(3)
    );
\mode_8b10b.i_lane_latency_monitor\: entity work.jesd204_rx_0_jesd204_lane_latency_monitor
     port map (
      E(0) => p_9_out,
      clk => clk,
      \gen_lane[1].lane_latency_mem_reg[1][11]_0\(0) => p_7_out_17,
      \gen_lane[2].lane_latency_mem_reg[2][11]_0\(0) => p_4_out,
      \gen_lane[3].lane_latency_mem_reg[3][11]_0\(0) => p_1_out,
      latency_monitor_reset => latency_monitor_reset,
      status_lane_ifs_ready(3 downto 0) => \^status_lane_ifs_ready\(3 downto 0),
      status_lane_latency(47 downto 36) => \^status_lane_latency\(55 downto 44),
      status_lane_latency(35 downto 24) => \^status_lane_latency\(41 downto 30),
      status_lane_latency(23 downto 12) => \^status_lane_latency\(27 downto 16),
      status_lane_latency(11 downto 0) => \^status_lane_latency\(13 downto 2)
    );
\mode_8b10b.i_rx_ctrl\: entity work.jesd204_rx_0_jesd204_rx_ctrl
     port map (
      Q(3 downto 0) => cgs_reset(3 downto 0),
      cfg_lanes_disable(3 downto 0) => cfg_lanes_disable(3 downto 0),
      cfg_links_disable(0) => cfg_links_disable(0),
      cgs_ready(3 downto 0) => cgs_ready(3 downto 0),
      clk => clk,
      \ifs_rst_reg[3]_0\(3 downto 0) => ifs_reset(3 downto 0),
      latency_monitor_reset => latency_monitor_reset,
      phy_en_char_align => phy_en_char_align,
      reset => reset,
      status_ctrl_state(1 downto 0) => status_ctrl_state(1 downto 0),
      sync(0) => sync(0),
      \sync_n_reg[0]_0\ => \^lmfc_edge\
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity jesd204_rx_0 is
  port (
    clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    phy_data : in STD_LOGIC_VECTOR ( 127 downto 0 );
    phy_header : in STD_LOGIC_VECTOR ( 7 downto 0 );
    phy_charisk : in STD_LOGIC_VECTOR ( 15 downto 0 );
    phy_notintable : in STD_LOGIC_VECTOR ( 15 downto 0 );
    phy_disperr : in STD_LOGIC_VECTOR ( 15 downto 0 );
    phy_block_sync : in STD_LOGIC_VECTOR ( 3 downto 0 );
    sysref : in STD_LOGIC;
    lmfc_edge : out STD_LOGIC;
    lmfc_clk : out STD_LOGIC;
    event_sysref_alignment_error : out STD_LOGIC;
    event_sysref_edge : out STD_LOGIC;
    sync : out STD_LOGIC_VECTOR ( 0 to 0 );
    phy_en_char_align : out STD_LOGIC;
    rx_data : out STD_LOGIC_VECTOR ( 127 downto 0 );
    rx_valid : out STD_LOGIC;
    rx_eof : out STD_LOGIC_VECTOR ( 3 downto 0 );
    rx_sof : out STD_LOGIC_VECTOR ( 3 downto 0 );
    cfg_lanes_disable : in STD_LOGIC_VECTOR ( 3 downto 0 );
    cfg_links_disable : in STD_LOGIC_VECTOR ( 0 to 0 );
    cfg_beats_per_multiframe : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_octets_per_frame : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_lmfc_offset : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_sysref_disable : in STD_LOGIC;
    cfg_sysref_oneshot : in STD_LOGIC;
    cfg_buffer_early_release : in STD_LOGIC;
    cfg_buffer_delay : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_disable_char_replacement : in STD_LOGIC;
    cfg_disable_scrambler : in STD_LOGIC;
    ctrl_err_statistics_reset : in STD_LOGIC;
    ctrl_err_statistics_mask : in STD_LOGIC_VECTOR ( 6 downto 0 );
    status_err_statistics_cnt : out STD_LOGIC_VECTOR ( 127 downto 0 );
    ilas_config_valid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    ilas_config_addr : out STD_LOGIC_VECTOR ( 7 downto 0 );
    ilas_config_data : out STD_LOGIC_VECTOR ( 127 downto 0 );
    status_ctrl_state : out STD_LOGIC_VECTOR ( 1 downto 0 );
    status_lane_cgs_state : out STD_LOGIC_VECTOR ( 7 downto 0 );
    status_lane_ifs_ready : out STD_LOGIC_VECTOR ( 3 downto 0 );
    status_lane_latency : out STD_LOGIC_VECTOR ( 55 downto 0 );
    status_lane_emb_state : out STD_LOGIC_VECTOR ( 11 downto 0 )
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of jesd204_rx_0 : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of jesd204_rx_0 : entity is "jesd204_rx_0,jesd204_rx,{}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of jesd204_rx_0 : entity is "yes";
  attribute IP_DEFINITION_SOURCE : string;
  attribute IP_DEFINITION_SOURCE of jesd204_rx_0 : entity is "package_project";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of jesd204_rx_0 : entity is "jesd204_rx,Vivado 2019.2";
end jesd204_rx_0;

architecture STRUCTURE of jesd204_rx_0 is
  attribute ALIGN_MUX_REGISTERED : integer;
  attribute ALIGN_MUX_REGISTERED of inst : label is 0;
  attribute CHAR_INFO_REGISTERED : integer;
  attribute CHAR_INFO_REGISTERED of inst : label is 0;
  attribute CW : integer;
  attribute CW of inst : label is 16;
  attribute DATA_PATH_WIDTH : integer;
  attribute DATA_PATH_WIDTH of inst : label is 4;
  attribute DW : integer;
  attribute DW of inst : label is 128;
  attribute ELASTIC_BUFFER_SIZE : integer;
  attribute ELASTIC_BUFFER_SIZE of inst : label is 128;
  attribute HW : integer;
  attribute HW of inst : label is 8;
  attribute LINK_MODE : integer;
  attribute LINK_MODE of inst : label is 1;
  attribute LMFC_COUNTER_WIDTH : integer;
  attribute LMFC_COUNTER_WIDTH of inst : label is 7;
  attribute MAX_BEATS_PER_MULTIFRAME : integer;
  attribute MAX_BEATS_PER_MULTIFRAME of inst : label is 128;
  attribute MAX_OCTETS_PER_FRAME : integer;
  attribute MAX_OCTETS_PER_FRAME of inst : label is 16;
  attribute MAX_OCTETS_PER_MULTIFRAME : integer;
  attribute MAX_OCTETS_PER_MULTIFRAME of inst : label is 512;
  attribute NUM_INPUT_PIPELINE : integer;
  attribute NUM_INPUT_PIPELINE of inst : label is 1;
  attribute NUM_LANES : integer;
  attribute NUM_LANES of inst : label is 4;
  attribute NUM_LINKS : integer;
  attribute NUM_LINKS of inst : label is 1;
  attribute SCRAMBLER_REGISTERED : integer;
  attribute SCRAMBLER_REGISTERED of inst : label is 0;
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of cfg_buffer_early_release : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg buffer_early_release";
  attribute X_INTERFACE_INFO of cfg_disable_char_replacement : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg disable_char_replacement";
  attribute X_INTERFACE_INFO of cfg_disable_scrambler : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg disable_scrambler";
  attribute X_INTERFACE_INFO of cfg_sysref_disable : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg sysref_disable";
  attribute X_INTERFACE_INFO of cfg_sysref_oneshot : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg sysref_oneshot";
  attribute X_INTERFACE_INFO of clk : signal is "xilinx.com:signal:clock:1.0 rx_cfg_rx_ilas_config_rx_event_rx_status_rx_data_signal_clock CLK";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of clk : signal is "XIL_INTERFACENAME rx_cfg_rx_ilas_config_rx_event_rx_status_rx_data_signal_clock, ASSOCIATED_BUSIF rx_cfg:rx_ilas_config:rx_event:rx_status:rx_data, ASSOCIATED_RESET reset, FREQ_HZ 100000000, PHASE 0.000, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of ctrl_err_statistics_reset : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg err_statistics_reset";
  attribute X_INTERFACE_INFO of event_sysref_alignment_error : signal is "analog.com:interface:jesd204_rx_event:1.0 rx_event sysref_alignment_error";
  attribute X_INTERFACE_INFO of event_sysref_edge : signal is "analog.com:interface:jesd204_rx_event:1.0 rx_event sysref_edge";
  attribute X_INTERFACE_INFO of reset : signal is "xilinx.com:signal:reset:1.0 rx_cfg_rx_ilas_config_rx_event_rx_status_rx_data_signal_reset RST";
  attribute X_INTERFACE_PARAMETER of reset : signal is "XIL_INTERFACENAME rx_cfg_rx_ilas_config_rx_event_rx_status_rx_data_signal_reset, POLARITY ACTIVE_HIGH, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of cfg_beats_per_multiframe : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg beats_per_multiframe";
  attribute X_INTERFACE_INFO of cfg_buffer_delay : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg buffer_delay";
  attribute X_INTERFACE_INFO of cfg_lanes_disable : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg lanes_disable";
  attribute X_INTERFACE_INFO of cfg_links_disable : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg links_disable";
  attribute X_INTERFACE_INFO of cfg_lmfc_offset : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg lmfc_offset";
  attribute X_INTERFACE_INFO of cfg_octets_per_frame : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg octets_per_frame";
  attribute X_INTERFACE_INFO of ctrl_err_statistics_mask : signal is "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg err_statistics_mask";
  attribute X_INTERFACE_INFO of ilas_config_addr : signal is "analog.com:interface:jesd204_rx_ilas_config:1.0 rx_ilas_config addr";
  attribute X_INTERFACE_INFO of ilas_config_data : signal is "analog.com:interface:jesd204_rx_ilas_config:1.0 rx_ilas_config data";
  attribute X_INTERFACE_INFO of ilas_config_valid : signal is "analog.com:interface:jesd204_rx_ilas_config:1.0 rx_ilas_config valid";
  attribute X_INTERFACE_INFO of phy_block_sync : signal is "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxblock_sync [0:0] [0:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxblock_sync [0:0] [1:1], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxblock_sync [0:0] [2:2], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxblock_sync [0:0] [3:3]";
  attribute X_INTERFACE_INFO of phy_charisk : signal is "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxcharisk [3:0] [3:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxcharisk [3:0] [7:4], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxcharisk [3:0] [11:8], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxcharisk [3:0] [15:12]";
  attribute X_INTERFACE_INFO of phy_data : signal is "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxdata [31:0] [31:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxdata [31:0] [63:32], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxdata [31:0] [95:64], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxdata [31:0] [127:96]";
  attribute X_INTERFACE_INFO of phy_disperr : signal is "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxdisperr [3:0] [3:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxdisperr [3:0] [7:4], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxdisperr [3:0] [11:8], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxdisperr [3:0] [15:12]";
  attribute X_INTERFACE_INFO of phy_header : signal is "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxheader [1:0] [1:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxheader [1:0] [3:2], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxheader [1:0] [5:4], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxheader [1:0] [7:6]";
  attribute X_INTERFACE_INFO of phy_notintable : signal is "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxnotintable [3:0] [3:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxnotintable [3:0] [7:4], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxnotintable [3:0] [11:8], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxnotintable [3:0] [15:12]";
  attribute X_INTERFACE_INFO of status_ctrl_state : signal is "analog.com:interface:jesd204_rx_status:1.0 rx_status ctrl_state";
  attribute X_INTERFACE_INFO of status_err_statistics_cnt : signal is "analog.com:interface:jesd204_rx_status:1.0 rx_status err_statistics_cnt";
  attribute X_INTERFACE_INFO of status_lane_cgs_state : signal is "analog.com:interface:jesd204_rx_status:1.0 rx_status lane_cgs_state";
  attribute X_INTERFACE_INFO of status_lane_emb_state : signal is "analog.com:interface:jesd204_rx_status:1.0 rx_status lane_emb_state";
  attribute X_INTERFACE_INFO of status_lane_ifs_ready : signal is "analog.com:interface:jesd204_rx_status:1.0 rx_status lane_ifs_ready";
  attribute X_INTERFACE_INFO of status_lane_latency : signal is "analog.com:interface:jesd204_rx_status:1.0 rx_status lane_latency";
begin
inst: entity work.jesd204_rx_0_jesd204_rx
     port map (
      cfg_beats_per_multiframe(7 downto 0) => cfg_beats_per_multiframe(7 downto 0),
      cfg_buffer_delay(7 downto 0) => cfg_buffer_delay(7 downto 0),
      cfg_buffer_early_release => cfg_buffer_early_release,
      cfg_disable_char_replacement => cfg_disable_char_replacement,
      cfg_disable_scrambler => cfg_disable_scrambler,
      cfg_lanes_disable(3 downto 0) => cfg_lanes_disable(3 downto 0),
      cfg_links_disable(0) => cfg_links_disable(0),
      cfg_lmfc_offset(7 downto 0) => cfg_lmfc_offset(7 downto 0),
      cfg_octets_per_frame(7 downto 0) => cfg_octets_per_frame(7 downto 0),
      cfg_sysref_disable => cfg_sysref_disable,
      cfg_sysref_oneshot => cfg_sysref_oneshot,
      clk => clk,
      ctrl_err_statistics_mask(6 downto 0) => ctrl_err_statistics_mask(6 downto 0),
      ctrl_err_statistics_reset => ctrl_err_statistics_reset,
      event_sysref_alignment_error => event_sysref_alignment_error,
      event_sysref_edge => event_sysref_edge,
      ilas_config_addr(7 downto 0) => ilas_config_addr(7 downto 0),
      ilas_config_data(127 downto 0) => ilas_config_data(127 downto 0),
      ilas_config_valid(3 downto 0) => ilas_config_valid(3 downto 0),
      lmfc_clk => lmfc_clk,
      lmfc_edge => lmfc_edge,
      phy_block_sync(3 downto 0) => phy_block_sync(3 downto 0),
      phy_charisk(15 downto 0) => phy_charisk(15 downto 0),
      phy_data(127 downto 0) => phy_data(127 downto 0),
      phy_disperr(15 downto 0) => phy_disperr(15 downto 0),
      phy_en_char_align => phy_en_char_align,
      phy_header(7 downto 0) => phy_header(7 downto 0),
      phy_notintable(15 downto 0) => phy_notintable(15 downto 0),
      reset => reset,
      rx_data(127 downto 0) => rx_data(127 downto 0),
      rx_eof(3 downto 0) => rx_eof(3 downto 0),
      rx_sof(3 downto 0) => rx_sof(3 downto 0),
      rx_valid => rx_valid,
      status_ctrl_state(1 downto 0) => status_ctrl_state(1 downto 0),
      status_err_statistics_cnt(127 downto 0) => status_err_statistics_cnt(127 downto 0),
      status_lane_cgs_state(7 downto 0) => status_lane_cgs_state(7 downto 0),
      status_lane_emb_state(11 downto 0) => status_lane_emb_state(11 downto 0),
      status_lane_ifs_ready(3 downto 0) => status_lane_ifs_ready(3 downto 0),
      status_lane_latency(55 downto 0) => status_lane_latency(55 downto 0),
      sync(0) => sync(0),
      sysref => sysref
    );
end STRUCTURE;
