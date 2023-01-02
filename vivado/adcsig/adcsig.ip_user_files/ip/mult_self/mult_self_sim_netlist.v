// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sun Jan  1 21:52:52 2023
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top mult_self -prefix
//               mult_self_ xbip_dsp48_macro_0_sim_netlist.v
// Design      : xbip_dsp48_macro_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "xbip_dsp48_macro_0,xbip_dsp48_macro_v3_0_17,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "xbip_dsp48_macro_v3_0_17,Vivado 2019.2" *) 
(* NotValidForBitStream *)
module mult_self
   (CLK,
    A,
    B,
    P);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF p_intf:pcout_intf:carrycascout_intf:carryout_intf:bcout_intf:acout_intf:concat_intf:d_intf:c_intf:b_intf:a_intf:bcin_intf:acin_intf:pcin_intf:carryin_intf:carrycascin_intf:sel_intf, ASSOCIATED_RESET SCLR:SCLRD:SCLRA:SCLRB:SCLRCONCAT:SCLRC:SCLRM:SCLRP:SCLRSEL, ASSOCIATED_CLKEN CE:CED:CED1:CED2:CED3:CEA:CEA1:CEA2:CEA3:CEA4:CEB:CEB1:CEB2:CEB3:CEB4:CECONCAT:CECONCAT3:CECONCAT4:CECONCAT5:CEC:CEC1:CEC2:CEC3:CEC4:CEC5:CEM:CEP:CESEL:CESEL1:CESEL2:CESEL3:CESEL4:CESEL5, FREQ_HZ 100000000, PHASE 0.000, INSERT_VIP 0" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:data:1.0 a_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME a_intf, LAYERED_METADATA undef" *) input [15:0]A;
  (* x_interface_info = "xilinx.com:signal:data:1.0 b_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME b_intf, LAYERED_METADATA undef" *) input [15:0]B;
  (* x_interface_info = "xilinx.com:signal:data:1.0 p_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME p_intf, LAYERED_METADATA undef" *) output [30:0]P;

  wire [15:0]A;
  wire [15:0]B;
  wire CLK;
  wire [30:0]P;
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
  (* C_P_LSB = "1" *) 
  (* C_P_MSB = "31" *) 
  (* C_REG_CONFIG = "00000000000011000011000001000100" *) 
  (* C_SEL_WIDTH = "0" *) 
  (* C_TEST_CORE = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  mult_self_xbip_dsp48_macro_v3_0_17 U0
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
(* C_MODEL_TYPE = "0" *) (* C_OPMODES = "000100100000010100000000" *) (* C_P_LSB = "1" *) 
(* C_P_MSB = "31" *) (* C_REG_CONFIG = "00000000000011000011000001000100" *) (* C_SEL_WIDTH = "0" *) 
(* C_TEST_CORE = "0" *) (* C_VERBOSITY = "0" *) (* C_XDEVICEFAMILY = "kintex7" *) 
(* downgradeipidentifiedwarnings = "yes" *) 
module mult_self_xbip_dsp48_macro_v3_0_17
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
  output [30:0]P;
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
  wire [30:0]P;
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
  (* C_P_LSB = "1" *) 
  (* C_P_MSB = "31" *) 
  (* C_REG_CONFIG = "00000000000011000011000001000100" *) 
  (* C_SEL_WIDTH = "0" *) 
  (* C_TEST_CORE = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  mult_self_xbip_dsp48_macro_v3_0_17_viv i_synth
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
BAVObA0zMh3SAyaerYj6PcyUz/sXFmq4M0F0etK95LqxqRBz1uQeunDxD2cjCnQwkEB4NvQ0IjSa
wBWtnhYD1JKaxa5BqpqmcHgs7oBFutfoh9y2kA5w51INpdNBaM3O0d8dBLFZLlKe8SV0C9i96FWU
1wR8w/J+72PVr6NbvLKe+YfGcKc8AsiXT7kKj3haWlfYCQvwneN4VbOCoqicmAhr9iPNRiO73DVD
FD6XCNt5K18R1O9RHyr4rMzQ8AItXrjgknN+oldcIpJvzzoEiCFYcAUxRy93l3ALMwMMKsAkxE1r
TH7pweAluyWKxzncPwF6DRHwvO2jpDJt5rmsGA==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
rpkBEJkoKEeks3vfGLOWApkY06BLCN6+9v4FEbBDFTLnbJOcTOOb9TbJsMLjv56BvkRc/FkSjwAw
MbSdWOBkztdfjAbhNjzICxho2qk34ScY5sjCNqCrJhQuNRxMjozzGhnGtQ/QdJj9wyFfab2VXKPa
oPJ21MrXVkWJCMjNC9AnFKhyUSecQN+oygV/eyI+lPzLxLfb6MBlbm2qW6TGmwbySHMi0wKeDVeB
EfQun9E5Nhfa57+/aqF9qGOaDfQQVmLiAi22PsHlXE29AvoWWV3cqElA9COxygJnfNLF/Rkd5OiV
iO53IV78WaR55Pzr62EK/zlhtU+SXCpDCma9jQ==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 30272)
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
