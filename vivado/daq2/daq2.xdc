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


# PCI Express
set_property IOSTANDARD LVCMOS25 [get_ports pci_rst_n]
set_property PULLUP true [get_ports pci_rst_n]
set_property PACKAGE_PIN G25 [get_ports pci_rst_n]

set_property PACKAGE_PIN U8 [get_ports pci_ref_clk_p]
set_property PACKAGE_PIN U7 [get_ports pci_ref_clk_n]
create_clock -period 10.000 -name pci_ref_clk -waveform {0.000 5.000} [get_ports pci_ref_clk_p]
