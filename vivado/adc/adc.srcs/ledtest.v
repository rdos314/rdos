module tutorial_led_blink
  (
    SYSCLK_P,
    SYSCLK_N,
    GPIO_SW_E,
    GPIO_LED_7_LS
  );

  input wire SYSCLK_P;
  input wire SYSCLK_N;
  input wire GPIO_SW_E;
  output wire GPIO_LED_7_LS;
  wire SYSCLK;
  wire sample_clk;

  parameter c_CNT = 200000000;
 
  reg [31:0] r_CNT = 0;
  reg r_TOGGLE = 1'b0;

  clk sample_clk_inst(
                 clk_out, 
                 sample_clk);    

  IBUFGDS clk_inst( .I(SYSCLK_P), .IB(SYSCLK_N), .O(clk_out));
  BUFG clk_sys_inst (.I(clk_out), .O(SYSCLK));

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
