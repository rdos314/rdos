create_clock -name sys_clk -period 10 [get_ports sys_clk_p]

set_property IOSTANDARD LVCMOS25 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property LOC G25 [get_ports sys_rst_n]

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

set_property LOC AB8 [get_ports led_0]
set_property LOC AA8 [get_ports led_1]
set_property LOC AC9 [get_ports led_2]
set_property LOC AB9 [get_ports led_3]
set_property LOC AE26 [get_ports led_4]
set_property LOC G19 [get_ports led_5]
set_property LOC E18 [get_ports led_6]
set_property LOC F16 [get_ports led_7]

set_property LOC IBUFDS_GTE2_X0Y1 [get_cells refclk_ibuf]

set_false_path -to [get_ports -filter {NAME=~led_*}]
set_false_path -from [get_ports sys_rst_n]
