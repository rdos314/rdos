module clk
  (
    clk_in,
    clk_out
  );

  input clk_in;
  output clk_out;

sample_700 clk_700_inst
   (
    // Clock out ports
    .clk_out1(clk_out),     // output clk_out1
   // Clock in ports
    .clk_in1(clk_in));      // input clk_in1

endmodule
