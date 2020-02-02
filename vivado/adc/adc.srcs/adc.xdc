create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]
create_generated_clock -name sample_clk [get_pins sample_inst/inst/CLKOUT0]
set_clock_group -name async1 -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {sample_clk }]

set_property IOSTANDARD LVCMOS25 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property PACKAGE_PIN G25 [get_ports sys_rst_n]

set_property IOSTANDARD LVCMOS15 [get_ports sw_w]
set_property IOSTANDARD LVCMOS15 [get_ports sw_e]

set_property IOSTANDARD LVCMOS15 [get_ports led_0]
set_property IOSTANDARD LVCMOS15 [get_ports led_1]
set_property IOSTANDARD LVCMOS15 [get_ports led_2]
set_property IOSTANDARD LVCMOS15 [get_ports led_3]
set_property IOSTANDARD LVCMOS15 [get_ports led_4]
set_property IOSTANDARD LVCMOS15 [get_ports led_5]
set_property IOSTANDARD LVCMOS15 [get_ports led_6]
set_property IOSTANDARD LVCMOS15 [get_ports led_7]

set_property LOC AC6 [get_ports sw_w]
set_property LOC AG5 [get_ports sw_e]

set_property PACKAGE_PIN AB8 [get_ports led_0]
set_property PACKAGE_PIN AA8 [get_ports led_1]
set_property PACKAGE_PIN AC9 [get_ports led_2]
set_property PACKAGE_PIN AB9 [get_ports led_3]
set_property PACKAGE_PIN AE26 [get_ports led_4]
set_property PACKAGE_PIN G19 [get_ports led_5]
set_property PACKAGE_PIN E18 [get_ports led_6]
set_property PACKAGE_PIN F16 [get_ports led_7]

set_property LOC IBUFDS_GTE2_X0Y1 [get_cells refclk_ibuf]

set_false_path -to [get_ports -filter NAME=~led_*]
set_false_path -from [get_ports sys_rst_n]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets user_clk]
