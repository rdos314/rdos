// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Wed Jan 18 22:34:17 2023
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim C:/rdos/vivado/filter/adc.runs/square_synth_1/square_sim_netlist.v
// Design      : square
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "square,xbip_dsp48_macro_v3_0_17,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "xbip_dsp48_macro_v3_0_17,Vivado 2019.2" *) 
(* NotValidForBitStream *)
module square
   (CLK,
    A,
    B,
    P);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF p_intf:pcout_intf:carrycascout_intf:carryout_intf:bcout_intf:acout_intf:concat_intf:d_intf:c_intf:b_intf:a_intf:bcin_intf:acin_intf:pcin_intf:carryin_intf:carrycascin_intf:sel_intf, ASSOCIATED_RESET SCLR:SCLRD:SCLRA:SCLRB:SCLRCONCAT:SCLRC:SCLRM:SCLRP:SCLRSEL, ASSOCIATED_CLKEN CE:CED:CED1:CED2:CED3:CEA:CEA1:CEA2:CEA3:CEA4:CEB:CEB1:CEB2:CEB3:CEB4:CECONCAT:CECONCAT3:CECONCAT4:CECONCAT5:CEC:CEC1:CEC2:CEC3:CEC4:CEC5:CEM:CEP:CESEL:CESEL1:CESEL2:CESEL3:CESEL4:CESEL5, FREQ_HZ 100000000, PHASE 0.000, INSERT_VIP 0" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:data:1.0 a_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME a_intf, LAYERED_METADATA undef" *) input [15:0]A;
  (* x_interface_info = "xilinx.com:signal:data:1.0 b_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME b_intf, LAYERED_METADATA undef" *) input [15:0]B;
  (* x_interface_info = "xilinx.com:signal:data:1.0 p_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME p_intf, LAYERED_METADATA undef" *) output [31:0]P;

  wire [15:0]A;
  wire [15:0]B;
  wire CLK;
  wire [31:0]P;
  wire NLW_U0_CARRYCASCOUT_UNCONNECTED;
  wire NLW_U0_CARRYOUT_UNCONNECTED;
  wire [29:0]NLW_U0_ACOUT_UNCONNECTED;
  wire [17:0]NLW_U0_BCOUT_UNCONNECTED;
  wire [47:0]NLW_U0_PCOUT_UNCONNECTED;

  (* C_A_WIDTH = "16" *) 
  (* C_B_WIDTH = "16" *) 
  (* C_CONCAT_WIDTH = "48" *) 
  (* C_CONSTANT_1 = "1" *) 
  (* C_C_WIDTH = "48" *) 
  (* C_D_WIDTH = "18" *) 
  (* C_HAS_A = "1" *) 
  (* C_HAS_ACIN = "0" *) 
  (* C_HAS_ACOUT = "0" *) 
  (* C_HAS_B = "1" *) 
  (* C_HAS_BCIN = "0" *) 
  (* C_HAS_BCOUT = "0" *) 
  (* C_HAS_C = "0" *) 
  (* C_HAS_CARRYCASCIN = "0" *) 
  (* C_HAS_CARRYCASCOUT = "0" *) 
  (* C_HAS_CARRYIN = "0" *) 
  (* C_HAS_CARRYOUT = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_CEA = "0" *) 
  (* C_HAS_CEB = "0" *) 
  (* C_HAS_CEC = "0" *) 
  (* C_HAS_CECONCAT = "0" *) 
  (* C_HAS_CED = "0" *) 
  (* C_HAS_CEM = "0" *) 
  (* C_HAS_CEP = "0" *) 
  (* C_HAS_CESEL = "0" *) 
  (* C_HAS_CONCAT = "0" *) 
  (* C_HAS_D = "0" *) 
  (* C_HAS_INDEP_CE = "0" *) 
  (* C_HAS_INDEP_SCLR = "0" *) 
  (* C_HAS_PCIN = "0" *) 
  (* C_HAS_PCOUT = "0" *) 
  (* C_HAS_SCLR = "0" *) 
  (* C_HAS_SCLRA = "0" *) 
  (* C_HAS_SCLRB = "0" *) 
  (* C_HAS_SCLRC = "0" *) 
  (* C_HAS_SCLRCONCAT = "0" *) 
  (* C_HAS_SCLRD = "0" *) 
  (* C_HAS_SCLRM = "0" *) 
  (* C_HAS_SCLRP = "0" *) 
  (* C_HAS_SCLRSEL = "0" *) 
  (* C_LATENCY = "-1" *) 
  (* C_MODEL_TYPE = "0" *) 
  (* C_OPMODES = "000100100000010100000000" *) 
  (* C_P_LSB = "0" *) 
  (* C_P_MSB = "31" *) 
  (* C_REG_CONFIG = "00000000000011000011000001000100" *) 
  (* C_SEL_WIDTH = "0" *) 
  (* C_TEST_CORE = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  square_xbip_dsp48_macro_v3_0_17 U0
       (.A(A),
        .ACIN({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .ACOUT(NLW_U0_ACOUT_UNCONNECTED[29:0]),
        .B(B),
        .BCIN({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .BCOUT(NLW_U0_BCOUT_UNCONNECTED[17:0]),
        .C({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .CARRYCASCIN(1'b0),
        .CARRYCASCOUT(NLW_U0_CARRYCASCOUT_UNCONNECTED),
        .CARRYIN(1'b0),
        .CARRYOUT(NLW_U0_CARRYOUT_UNCONNECTED),
        .CE(1'b1),
        .CEA(1'b1),
        .CEA1(1'b1),
        .CEA2(1'b1),
        .CEA3(1'b1),
        .CEA4(1'b1),
        .CEB(1'b1),
        .CEB1(1'b1),
        .CEB2(1'b1),
        .CEB3(1'b1),
        .CEB4(1'b1),
        .CEC(1'b1),
        .CEC1(1'b1),
        .CEC2(1'b1),
        .CEC3(1'b1),
        .CEC4(1'b1),
        .CEC5(1'b1),
        .CECONCAT(1'b1),
        .CECONCAT3(1'b1),
        .CECONCAT4(1'b1),
        .CECONCAT5(1'b1),
        .CED(1'b1),
        .CED1(1'b1),
        .CED2(1'b1),
        .CED3(1'b1),
        .CEM(1'b1),
        .CEP(1'b1),
        .CESEL(1'b1),
        .CESEL1(1'b1),
        .CESEL2(1'b1),
        .CESEL3(1'b1),
        .CESEL4(1'b1),
        .CESEL5(1'b1),
        .CLK(CLK),
        .CONCAT({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .D({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .P(P),
        .PCIN({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .PCOUT(NLW_U0_PCOUT_UNCONNECTED[47:0]),
        .SCLR(1'b0),
        .SCLRA(1'b0),
        .SCLRB(1'b0),
        .SCLRC(1'b0),
        .SCLRCONCAT(1'b0),
        .SCLRD(1'b0),
        .SCLRM(1'b0),
        .SCLRP(1'b0),
        .SCLRSEL(1'b0),
        .SEL(1'b0));
endmodule

(* C_A_WIDTH = "16" *) (* C_B_WIDTH = "16" *) (* C_CONCAT_WIDTH = "48" *) 
(* C_CONSTANT_1 = "1" *) (* C_C_WIDTH = "48" *) (* C_D_WIDTH = "18" *) 
(* C_HAS_A = "1" *) (* C_HAS_ACIN = "0" *) (* C_HAS_ACOUT = "0" *) 
(* C_HAS_B = "1" *) (* C_HAS_BCIN = "0" *) (* C_HAS_BCOUT = "0" *) 
(* C_HAS_C = "0" *) (* C_HAS_CARRYCASCIN = "0" *) (* C_HAS_CARRYCASCOUT = "0" *) 
(* C_HAS_CARRYIN = "0" *) (* C_HAS_CARRYOUT = "0" *) (* C_HAS_CE = "0" *) 
(* C_HAS_CEA = "0" *) (* C_HAS_CEB = "0" *) (* C_HAS_CEC = "0" *) 
(* C_HAS_CECONCAT = "0" *) (* C_HAS_CED = "0" *) (* C_HAS_CEM = "0" *) 
(* C_HAS_CEP = "0" *) (* C_HAS_CESEL = "0" *) (* C_HAS_CONCAT = "0" *) 
(* C_HAS_D = "0" *) (* C_HAS_INDEP_CE = "0" *) (* C_HAS_INDEP_SCLR = "0" *) 
(* C_HAS_PCIN = "0" *) (* C_HAS_PCOUT = "0" *) (* C_HAS_SCLR = "0" *) 
(* C_HAS_SCLRA = "0" *) (* C_HAS_SCLRB = "0" *) (* C_HAS_SCLRC = "0" *) 
(* C_HAS_SCLRCONCAT = "0" *) (* C_HAS_SCLRD = "0" *) (* C_HAS_SCLRM = "0" *) 
(* C_HAS_SCLRP = "0" *) (* C_HAS_SCLRSEL = "0" *) (* C_LATENCY = "-1" *) 
(* C_MODEL_TYPE = "0" *) (* C_OPMODES = "000100100000010100000000" *) (* C_P_LSB = "0" *) 
(* C_P_MSB = "31" *) (* C_REG_CONFIG = "00000000000011000011000001000100" *) (* C_SEL_WIDTH = "0" *) 
(* C_TEST_CORE = "0" *) (* C_VERBOSITY = "0" *) (* C_XDEVICEFAMILY = "kintex7" *) 
(* ORIG_REF_NAME = "xbip_dsp48_macro_v3_0_17" *) (* downgradeipidentifiedwarnings = "yes" *) 
module square_xbip_dsp48_macro_v3_0_17
   (CLK,
    CE,
    SCLR,
    SEL,
    CARRYCASCIN,
    CARRYIN,
    PCIN,
    ACIN,
    BCIN,
    A,
    B,
    C,
    D,
    CONCAT,
    ACOUT,
    BCOUT,
    CARRYOUT,
    CARRYCASCOUT,
    PCOUT,
    P,
    CED,
    CED1,
    CED2,
    CED3,
    CEA,
    CEA1,
    CEA2,
    CEA3,
    CEA4,
    CEB,
    CEB1,
    CEB2,
    CEB3,
    CEB4,
    CECONCAT,
    CECONCAT3,
    CECONCAT4,
    CECONCAT5,
    CEC,
    CEC1,
    CEC2,
    CEC3,
    CEC4,
    CEC5,
    CEM,
    CEP,
    CESEL,
    CESEL1,
    CESEL2,
    CESEL3,
    CESEL4,
    CESEL5,
    SCLRD,
    SCLRA,
    SCLRB,
    SCLRCONCAT,
    SCLRC,
    SCLRM,
    SCLRP,
    SCLRSEL);
  input CLK;
  input CE;
  input SCLR;
  input [0:0]SEL;
  input CARRYCASCIN;
  input CARRYIN;
  input [47:0]PCIN;
  input [29:0]ACIN;
  input [17:0]BCIN;
  input [15:0]A;
  input [15:0]B;
  input [47:0]C;
  input [17:0]D;
  input [47:0]CONCAT;
  output [29:0]ACOUT;
  output [17:0]BCOUT;
  output CARRYOUT;
  output CARRYCASCOUT;
  output [47:0]PCOUT;
  output [31:0]P;
  input CED;
  input CED1;
  input CED2;
  input CED3;
  input CEA;
  input CEA1;
  input CEA2;
  input CEA3;
  input CEA4;
  input CEB;
  input CEB1;
  input CEB2;
  input CEB3;
  input CEB4;
  input CECONCAT;
  input CECONCAT3;
  input CECONCAT4;
  input CECONCAT5;
  input CEC;
  input CEC1;
  input CEC2;
  input CEC3;
  input CEC4;
  input CEC5;
  input CEM;
  input CEP;
  input CESEL;
  input CESEL1;
  input CESEL2;
  input CESEL3;
  input CESEL4;
  input CESEL5;
  input SCLRD;
  input SCLRA;
  input SCLRB;
  input SCLRCONCAT;
  input SCLRC;
  input SCLRM;
  input SCLRP;
  input SCLRSEL;

  wire [15:0]A;
  wire [29:0]ACIN;
  wire [29:0]ACOUT;
  wire [15:0]B;
  wire [17:0]BCIN;
  wire [17:0]BCOUT;
  wire CARRYCASCIN;
  wire CARRYCASCOUT;
  wire CARRYIN;
  wire CARRYOUT;
  wire CLK;
  wire [31:0]P;
  wire [47:0]PCIN;
  wire [47:0]PCOUT;

  (* C_A_WIDTH = "16" *) 
  (* C_B_WIDTH = "16" *) 
  (* C_CONCAT_WIDTH = "48" *) 
  (* C_CONSTANT_1 = "1" *) 
  (* C_C_WIDTH = "48" *) 
  (* C_D_WIDTH = "18" *) 
  (* C_HAS_A = "1" *) 
  (* C_HAS_ACIN = "0" *) 
  (* C_HAS_ACOUT = "0" *) 
  (* C_HAS_B = "1" *) 
  (* C_HAS_BCIN = "0" *) 
  (* C_HAS_BCOUT = "0" *) 
  (* C_HAS_C = "0" *) 
  (* C_HAS_CARRYCASCIN = "0" *) 
  (* C_HAS_CARRYCASCOUT = "0" *) 
  (* C_HAS_CARRYIN = "0" *) 
  (* C_HAS_CARRYOUT = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_CEA = "0" *) 
  (* C_HAS_CEB = "0" *) 
  (* C_HAS_CEC = "0" *) 
  (* C_HAS_CECONCAT = "0" *) 
  (* C_HAS_CED = "0" *) 
  (* C_HAS_CEM = "0" *) 
  (* C_HAS_CEP = "0" *) 
  (* C_HAS_CESEL = "0" *) 
  (* C_HAS_CONCAT = "0" *) 
  (* C_HAS_D = "0" *) 
  (* C_HAS_INDEP_CE = "0" *) 
  (* C_HAS_INDEP_SCLR = "0" *) 
  (* C_HAS_PCIN = "0" *) 
  (* C_HAS_PCOUT = "0" *) 
  (* C_HAS_SCLR = "0" *) 
  (* C_HAS_SCLRA = "0" *) 
  (* C_HAS_SCLRB = "0" *) 
  (* C_HAS_SCLRC = "0" *) 
  (* C_HAS_SCLRCONCAT = "0" *) 
  (* C_HAS_SCLRD = "0" *) 
  (* C_HAS_SCLRM = "0" *) 
  (* C_HAS_SCLRP = "0" *) 
  (* C_HAS_SCLRSEL = "0" *) 
  (* C_LATENCY = "-1" *) 
  (* C_MODEL_TYPE = "0" *) 
  (* C_OPMODES = "000100100000010100000000" *) 
  (* C_P_LSB = "0" *) 
  (* C_P_MSB = "31" *) 
  (* C_REG_CONFIG = "00000000000011000011000001000100" *) 
  (* C_SEL_WIDTH = "0" *) 
  (* C_TEST_CORE = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  square_xbip_dsp48_macro_v3_0_17_viv i_synth
       (.A(A),
        .ACIN(ACIN),
        .ACOUT(ACOUT),
        .B(B),
        .BCIN(BCIN),
        .BCOUT(BCOUT),
        .C({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .CARRYCASCIN(CARRYCASCIN),
        .CARRYCASCOUT(CARRYCASCOUT),
        .CARRYIN(CARRYIN),
        .CARRYOUT(CARRYOUT),
        .CE(1'b0),
        .CEA(1'b0),
        .CEA1(1'b0),
        .CEA2(1'b0),
        .CEA3(1'b0),
        .CEA4(1'b0),
        .CEB(1'b0),
        .CEB1(1'b0),
        .CEB2(1'b0),
        .CEB3(1'b0),
        .CEB4(1'b0),
        .CEC(1'b0),
        .CEC1(1'b0),
        .CEC2(1'b0),
        .CEC3(1'b0),
        .CEC4(1'b0),
        .CEC5(1'b0),
        .CECONCAT(1'b0),
        .CECONCAT3(1'b0),
        .CECONCAT4(1'b0),
        .CECONCAT5(1'b0),
        .CED(1'b0),
        .CED1(1'b0),
        .CED2(1'b0),
        .CED3(1'b0),
        .CEM(1'b0),
        .CEP(1'b0),
        .CESEL(1'b0),
        .CESEL1(1'b0),
        .CESEL2(1'b0),
        .CESEL3(1'b0),
        .CESEL4(1'b0),
        .CESEL5(1'b0),
        .CLK(CLK),
        .CONCAT({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .D({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .P(P),
        .PCIN(PCIN),
        .PCOUT(PCOUT),
        .SCLR(1'b0),
        .SCLRA(1'b0),
        .SCLRB(1'b0),
        .SCLRC(1'b0),
        .SCLRCONCAT(1'b0),
        .SCLRD(1'b0),
        .SCLRM(1'b0),
        .SCLRP(1'b0),
        .SCLRSEL(1'b0),
        .SEL(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2019.1"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
o95kQsykeBnv/6RKTex/4MyOqp3EGnPFH/nv5raMenbKASm/6owCQp4giB3JGq3yU+Peuq4HmH2a
zCDpR2ue0Q==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
VB9GXqz76JcxGkDIhWmf/Tvu6ktxli9qmz3kvoomNuowfSnKyyUf21nolwdhnVr1C2+5yMJGWxPZ
BLZG0iRJeqsy39qwM9osyuU+SIaK3ZNZlXHldcb5bqAcCuJ+kdyh182BY5RLREoDcjBSaH6et2y0
nHwnoYvMurbi5069L7o=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
xRZ06DbUma6Yw1PiSnZUG2PGjSadC3LNKsDhEzPo8eyEaE9nHgZw/3DDvJK29nvTv83gI0iUR83s
DsWaX9kx/1Ncn4XbmSdT8+ji+OZrf49Rig/ID8665qlNZBqow90+wIcAD4bOqRrXrA1K59qrwHvT
HjF7LoHC546/c3M96yI1UmGveOEfoOIgajP6XX7KY7mxUrsrAoYckHW83+iWbeBUCWMWQkQHuGlA
pkJa7gi2QS5qK1xo/K1KptSjNKWEcDFKsQLQ0NrqR8Wc3xWjV9RkH6EV4AAjqgx4aW1aiTi6aDCV
R//ORC0dbwb38TBnvY0dK2NwJ9AndoUpVf0ZFg==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
ctpu7OT3NYFV50M7g3X5OWgzfC+1lvHtpPPrHYvfD4BdZUOZtoWbRVMYSofIc3yuOpx1VVcEmRr/
TnKkV/uYIbG4TaOQ6J02lm6ilU0VHOky/Li1McDu0RZw0Ym3gBtycWQulvxZmJPkYKOdQkolKxS2
jt0O51yRobPY6/N1kQhzEZxou6hMzAUa4xc+wECnWdAy6L4Xa7QaVNQGQYFvi6pXqDdNwgODZGXV
5IthUoYOPE4oo8tmSbvgOpIx9hwhoF2s9j0YUqc9z5WDcrLuIl33wuxjH9d1akOqv6Jbd35TUycY
EQqcSWCRs1KWhT2dlakG8g64BkZHy8Jiv0tc+w==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2019_02", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
KBrCiroMzB0+0nGnzcg92RWUMI8YS6FFqefgILdK30KYEgKgP8lepDeGmJjACZ9cZn7KH7Y56rOZ
3EGE6Ha7toC7ZtEIAJyZd6DO+Tkv/f42zt5Fq4pNzMIbgRDlzMjiEiEnIYrgwku58DE8qUIJ3B9W
2jOTjFiJcu/375a6hszX+ndN4lQcDcn3FIRME2BcbfHSYXv/KeBn/ikpyK99TnHjwjYNKfVU3f1s
8U1dtN43mHPq1V/p7H2k4VgNO66O2TAxqrQLk7ET+p4au9Q8p9kGatxXPKHX45+4TZ+IvLas4jOs
5tUxRs9+HyKayPE8oEuQNe70m5jjSzYyt8AtuQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
ljpgiVbqME/DDt2YubRDsiAaUvvd0luRm1Kyn0zXi5Oi5H+daHLhjdtMKs7UXT4hOyMtBPXvIHzO
r3gvIW1qQXCE9n01v8P7aUKDZWCDsuc8k1+1gf6LDZ6q1vDWNFnrEp12ZZOMWzKLj8BUfqSDayNa
cjbp1Qs1t9jdv8TVPvI=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Df6Zc2J6DGn8PimsfKk8mQ+cpGIR1yrpcw5QseDEQJ4mE8uqo8cLRqffFGcLqTX/B1Vnkh1zy8xG
q2t9DwcdlrbPZvTj6RWyWp3oTBVBqAAriOEphkMP775Jrl1gYe/XFWYC8bce89oTVSt9VI8dqzVe
DMMbb0kX66Rabi08xQhUh9Jpf8v6we/rN6jUKKJDGvZaK3mRBx7yzs6QFFk/kzUVNg0OGyiWqITi
+ku5Dvvn4QhDeP6hu9E6Qjw0Q7i23BjvONLiQ5H9kbefLDIA8CwOsmjZ4gggEIYYgBpAIP0Fbt2j
o+kGZlTAq7P7yrZGTKNPS0BKI+JsCX8NJ0OWHg==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
dq7KDgd134IyGuCX1+RhFxXxAPr9vqLex10Nngq3feVDBCLFxJ/JXYEh7jTmUBXZQOdASytF08EH
SO+w1Is1cxQsti/FmNiauEPgjoRq5wsqNMWbCm4flZRONPn8J2PeWlbgolgFaQQEQVS4CCq7CsKj
/rDM/jgVtgnKCkbabtq/ivobGvVa/xOG7V3VkW7ouxzozBspI437g30tRNux4+AQ+Fn8AnBkcA2y
E06hXTFA/DYA5ZKTk1R7S5JbEOyKubRtpN0R9MTQdnZzwCLnNOO3Ew75HG+cqMmieZYwjdlN4Dwl
VUaDYFkm15DHeBfjYc+2SQhYtTsm2W/5dS4XpA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
KL63hAesulUL1MiU4SDYvscXK7ZEsGT/ghhEwUEFKwWegBrdMRCbB4GVOLgLNakQVan4ch6uEvkZ
BnSc8CA2tdK4t7bjBmO81bPLBSYWDG/Nc6YMdCXAC0CkspEkNvuMamGCD9OIPqqYoyHDCC+mQwju
Aa3zj9q2odHWS+ZdO/SFTL6CK5Ake1VstgHeNnqe30B3abhE82ZMMVnrs6U4y6iff3oqPLQsR+Fv
xL+lDnot8C/zM0X884k0jljLGXBRuDJnTCeC8Poi3T1UvFJzbNapom638zxUTrzFlGWwK1aTH4rP
PiF1UvON+LXZg75uilc7mCuJFUbCpI5QZs+4gQ==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
6HAHTQ/MgSBVG2DdmJCMKO0QyajDsIFUO7K53cGg1Y8EusSYx9UkyqbNTsnPoAIT3tPSKwbYX1Zy
JHAorpO0ZHqsiCcv0KrmS3AVfmO5v0nIxMfEyNcGRFu2PaNmf3/6nMmFMiss6ta68mRDPXVdT/ow
ESpi6ci/B7DSIE7/t4bup0TPXC7jqxGzefweeq9O/tTRmCuiqoC+6iyH0LK7DMIJB2JbJVu6PEpO
BODM/Aqflm+4T7GyAzSoZqqplRX5vMziQ3aQrW3cZ25oQVKS7aKeUIPjLgMlAsS+Sh0Rz8uBrjzx
DJr58vSFMZ3SOWpk5vTpyhaIE5QGcpT1EHDT8Q==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 29856)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif
