module tutorial_led_blink
 (
    pci_exp_txp,
    pci_exp_txn,
    pci_exp_rxp,
    pci_exp_rxn,
    sys_rst_n,

    sysclk_p,
    sysclk_n,
    GPIO_SW_E,
    GPIO_LED_7_LS
  );

  output  [7:0]    pci_exp_txp;
  output  [7:0]    pci_exp_txn;
  input   [7:0]    pci_exp_rxp;
  input   [7:0]    pci_exp_rxn;
  input            sys_rst_n;

  input wire sysclk_p;
  input wire sysclk_n;
  input wire GPIO_SW_E;
  output wire GPIO_LED_7_LS;
  wire SYSCLK;
  wire sample_clk;

  parameter c_CNT = 200000000;
 
  reg [31:0] r_CNT = 0;
  reg r_TOGGLE = 1'b0;

sample_700 clk_700_inst
   (
    // Clock out ports
    .clk_out1(sample_clk),     // output clk_out1
   // Clock in ports
    .clk_in1(sys_clk));      // input clk_in1

  pci_app pci_app_inst(
    .pci_exp_txp(pci_exp_txp),
    .pci_exp_txn(pci_exp_txn),
    .pci_exp_rxp(pci_exp_rxp),
    .pci_exp_rxn(pci_exp_rxn),
    .sys_clk(sys_clk),
    .sys_rst(!sys_rst_n)
   );

 IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
 BUFG clk_sys_inst (.I(sys_clk), .O(SYSCLK));

begin

  always @ (posedge sample_clk)
    begin
      if (r_CNT == c_CNT-1)
        begin
          r_TOGGLE <= !r_TOGGLE;
          r_CNT <= 0;
        end
      else
        r_CNT <= r_CNT + 1;
    end;

  assign GPIO_LED_7_LS = r_TOGGLE;

end
endmodule
