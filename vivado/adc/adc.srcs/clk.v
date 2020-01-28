module clk
  (
    clk_in,
    sel,
    clk_out
  );

  input clk_in;
  input sel;
  output clk_out;

sample_700 clk_700_inst
   (
    // Clock out ports
    .clk_out1(clk_700),     // output clk_out1
   // Clock in ports
    .clk_in1(clk_in));      // input clk_in1

  BUFGMUX clk_inst (.I0(clk_700), .I1(clk_in), .S(sel), .O(clk_out));
  
endmodule
