// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Wed Jan 18 22:32:13 2023
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim C:/rdos/vivado/filter/adc.runs/multiply_synth_1/multiply_sim_netlist.v
// Design      : multiply
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "multiply,xbip_dsp48_macro_v3_0_17,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "xbip_dsp48_macro_v3_0_17,Vivado 2019.2" *) 
(* NotValidForBitStream *)
module multiply
   (CLK,
    A,
    B,
    P);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF p_intf:pcout_intf:carrycascout_intf:carryout_intf:bcout_intf:acout_intf:concat_intf:d_intf:c_intf:b_intf:a_intf:bcin_intf:acin_intf:pcin_intf:carryin_intf:carrycascin_intf:sel_intf, ASSOCIATED_RESET SCLR:SCLRD:SCLRA:SCLRB:SCLRCONCAT:SCLRC:SCLRM:SCLRP:SCLRSEL, ASSOCIATED_CLKEN CE:CED:CED1:CED2:CED3:CEA:CEA1:CEA2:CEA3:CEA4:CEB:CEB1:CEB2:CEB3:CEB4:CECONCAT:CECONCAT3:CECONCAT4:CECONCAT5:CEC:CEC1:CEC2:CEC3:CEC4:CEC5:CEM:CEP:CESEL:CESEL1:CESEL2:CESEL3:CESEL4:CESEL5, FREQ_HZ 100000000, PHASE 0.000, INSERT_VIP 0" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:data:1.0 a_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME a_intf, LAYERED_METADATA undef" *) input [13:0]A;
  (* x_interface_info = "xilinx.com:signal:data:1.0 b_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME b_intf, LAYERED_METADATA undef" *) input [15:0]B;
  (* x_interface_info = "xilinx.com:signal:data:1.0 p_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME p_intf, LAYERED_METADATA undef" *) output [29:0]P;

  wire [13:0]A;
  wire [15:0]B;
  wire CLK;
  wire [29:0]P;
  wire NLW_U0_CARRYCASCOUT_UNCONNECTED;
  wire NLW_U0_CARRYOUT_UNCONNECTED;
  wire [29:0]NLW_U0_ACOUT_UNCONNECTED;
  wire [17:0]NLW_U0_BCOUT_UNCONNECTED;
  wire [47:0]NLW_U0_PCOUT_UNCONNECTED;

  (* C_A_WIDTH = "14" *) 
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
  (* C_P_MSB = "29" *) 
  (* C_REG_CONFIG = "00000000000011000011000001000100" *) 
  (* C_SEL_WIDTH = "0" *) 
  (* C_TEST_CORE = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  multiply_xbip_dsp48_macro_v3_0_17 U0
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

(* C_A_WIDTH = "14" *) (* C_B_WIDTH = "16" *) (* C_CONCAT_WIDTH = "48" *) 
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
(* C_P_MSB = "29" *) (* C_REG_CONFIG = "00000000000011000011000001000100" *) (* C_SEL_WIDTH = "0" *) 
(* C_TEST_CORE = "0" *) (* C_VERBOSITY = "0" *) (* C_XDEVICEFAMILY = "kintex7" *) 
(* ORIG_REF_NAME = "xbip_dsp48_macro_v3_0_17" *) (* downgradeipidentifiedwarnings = "yes" *) 
module multiply_xbip_dsp48_macro_v3_0_17
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
  input [13:0]A;
  input [15:0]B;
  input [47:0]C;
  input [17:0]D;
  input [47:0]CONCAT;
  output [29:0]ACOUT;
  output [17:0]BCOUT;
  output CARRYOUT;
  output CARRYCASCOUT;
  output [47:0]PCOUT;
  output [29:0]P;
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

  wire [13:0]A;
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
  wire [29:0]P;
  wire [47:0]PCIN;
  wire [47:0]PCOUT;

  (* C_A_WIDTH = "14" *) 
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
  (* C_P_MSB = "29" *) 
  (* C_REG_CONFIG = "00000000000011000011000001000100" *) 
  (* C_SEL_WIDTH = "0" *) 
  (* C_TEST_CORE = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  multiply_xbip_dsp48_macro_v3_0_17_viv i_synth
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
IFKMMLFJnowV7vbb/z3UGXaoWnIz/mWFU80vZuBiMmw+lzOCJVs2LcN6aUwRPmv7NAI+/lEhVDz4
5/I/pjZqKQEFkYO+wpndQJJ8JMKhLxt3kMI5J9ELdPhRnLziAwpYUOqS4uhCbd51Eus9LPade6kV
JqXhp9Ln1NLVi0DNuLUp0K06BrJuXfDxa1nHROwIflHydda6Tr9JBIh33C/IhfWqIzwzS4UcJR+w
uHgiH8J2lPPEpi5cw5IBL9wRS6mdk6m69BJeypfjtL+IIfjmjelV3Yc2Gk24gbs1VHimAN7z9aH3
4s8vx8as+v4U50ubU6lTbL37rCkuTj+3qjvChA==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
4m8QMHc9Y98xGxKUeyZVKoTUVouiWgWFL6xr7a8+pjQ7FsujIprwSiWD+eiTU+7Xf0Tw+fuUa2xW
tB+umdTkr2ZuJYcpJIdGxxmFibyHBCFOvpTHFrMZlTz2d0cXbDQuaYFVY1LjSArpyv6+2ULsaVe2
7QTHk9zsLYESyjyiX+vwgVghi3/0tTWKWezwL8UzhgUr/kPLDRd4pGqoWsdtNdA/HMosL+k06DHX
BXOXdxzl6WyACSEfu5V7rDblONi4XojwksdfeNb7005oE2/IggaQAW1KBw3jm4SLYEkug/n/LMNG
6RciE9FzyFiPb4NFnIQIk05ynW9z3sFl+04Ppw==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 29984)
`pragma protect data_block
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
cP4=
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
