module tutorial_led_blink
  (
    SYSCLK_P,
    SYSCLK_N,
    GPIO_SW_W,
    GPIO_SW_E,
    GPIO_LED_7_LS
  );

  input wire SYSCLK_P;
  input wire SYSCLK_N;
  input wire GPIO_SW_W;
  input wire GPIO_SW_E;
  output wire GPIO_LED_7_LS;
  wire SYSCLK;

  parameter c_CNT_100HZ = 2000000;
  parameter c_CNT_50HZ = 4000000;
  parameter c_CNT_10HZ = 20000000;
  parameter c_CNT_1HZ = 200000000;
 
  reg [31:0] r_CNT_100HZ = 0;
  reg [31:0] r_CNT_50HZ = 0;
  reg [31:0] r_CNT_10HZ = 0;
  reg [31:0] r_CNT_1HZ = 0;

  reg r_TOGGLE_100HZ = 1'b0;
  reg r_TOGGLE_50HZ = 1'b0;
  reg r_TOGGLE_10HZ = 1'b0;
  reg r_TOGGLE_1HZ = 1'b0;

  reg r_LED_SELECT;
  wire w_LED_SELECT;

  IBUFGDS clk_inst( .I(SYSCLK_P), .IB(SYSCLK_N), .O(CLK_ibufgout));
  BUFG UBUFG (.I(CLK_ibufgout), .O(SYSCLK));

begin
  always @ (posedge SYSCLK)
    begin
      if (r_CNT_100HZ == c_CNT_100HZ-1)
        begin
          r_TOGGLE_100HZ <= !r_TOGGLE_100HZ;
          r_CNT_100HZ <= 0;
        end
      else
        r_CNT_100HZ <= r_CNT_100HZ + 1;
    end;

  always @ (posedge SYSCLK)
    begin
      if (r_CNT_50HZ == c_CNT_50HZ-1)
        begin
          r_TOGGLE_50HZ <= !r_TOGGLE_50HZ;
          r_CNT_50HZ <= 0;
        end
      else
        r_CNT_50HZ <= r_CNT_50HZ + 1;
    end;

  always @ (posedge SYSCLK)
    begin
      if (r_CNT_10HZ == c_CNT_10HZ-1)
        begin
          r_TOGGLE_10HZ <= !r_TOGGLE_10HZ;
          r_CNT_10HZ <= 0;
        end
      else
        r_CNT_10HZ <= r_CNT_10HZ + 1;
    end;

  always @ (posedge SYSCLK)
    begin
      if (r_CNT_1HZ == c_CNT_1HZ-1)
        begin
          r_TOGGLE_1HZ <= !r_TOGGLE_1HZ;
          r_CNT_1HZ <= 0;
        end
      else
        r_CNT_1HZ <= r_CNT_1HZ + 1;
    end;

  always @ (*)
    begin
      case ({GPIO_SW_W, GPIO_SW_E})
        2'b11 : r_LED_SELECT <= r_TOGGLE_100HZ;
        2'b10 : r_LED_SELECT <= r_TOGGLE_10HZ;
        2'b01 : r_LED_SELECT <= r_TOGGLE_50HZ;
        2'b00 : r_LED_SELECT <= r_TOGGLE_1HZ;
      endcase
    end

  assign GPIO_LED_7_LS = r_LED_SELECT;

end
endmodule
