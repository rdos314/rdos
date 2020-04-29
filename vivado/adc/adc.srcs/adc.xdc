set_property IOSTANDARD LVDS_25 [get_ports user_clk_n]
set_property PACKAGE_PIN K28 [get_ports user_clk_p]
set_property PACKAGE_PIN K29 [get_ports user_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports user_clk_p]
create_clock -period 6.400 -name user_clk [get_ports user_clk_p]

set_property IOSTANDARD LVDS [get_ports sys_clk_n]
set_property PACKAGE_PIN AD12 [get_ports sys_clk_p]
set_property PACKAGE_PIN AD11 [get_ports sys_clk_n]
set_property IOSTANDARD LVDS [get_ports sys_clk_p]
create_clock -period 5.000 -name sys_clk [get_ports sys_clk_p]

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

set_property PACKAGE_PIN AB7 [get_ports reset]
set_property IOSTANDARD LVCMOS15 [get_ports reset]

# PCI Express
set_property IOSTANDARD LVCMOS25 [get_ports pci_rst_n]
set_property PULLUP true [get_ports pci_rst_n]
set_property PACKAGE_PIN G25 [get_ports pci_rst_n]

set_property PACKAGE_PIN U8 [get_ports pci_ref_clk_p]
set_property PACKAGE_PIN U7 [get_ports pci_ref_clk_n]
create_clock -period 10.000 -name pci_ref_clk -waveform {0.000 5.000} [get_ports pci_ref_clk_p]

set_property PACKAGE_PIN E8 [get_ports rx_ref_clk_p]
set_property PACKAGE_PIN E7 [get_ports rx_ref_clk_n]

set_property PACKAGE_PIN C8 [get_ports tx_ref_clk_p]
set_property PACKAGE_PIN C7 [get_ports tx_ref_clk_n]
set_property PACKAGE_PIN A7 [get_ports {rx_data_n[0]}]
set_property PACKAGE_PIN A8 [get_ports {rx_data_p[0]}]
set_property PACKAGE_PIN A3 [get_ports {tx_data_n[0]}]
set_property PACKAGE_PIN A4 [get_ports {tx_data_p[0]}]
set_property PACKAGE_PIN E3 [get_ports {rx_data_n[1]}]
set_property PACKAGE_PIN E4 [get_ports {rx_data_p[1]}]
set_property PACKAGE_PIN D1 [get_ports {tx_data_n[1]}]
set_property PACKAGE_PIN D2 [get_ports {tx_data_p[1]}]
set_property PACKAGE_PIN B5 [get_ports {rx_data_n[2]}]
set_property PACKAGE_PIN B6 [get_ports {rx_data_p[2]}]
set_property PACKAGE_PIN B1 [get_ports {tx_data_n[2]}]
set_property PACKAGE_PIN B2 [get_ports {tx_data_p[2]}]
set_property PACKAGE_PIN D5 [get_ports {rx_data_n[3]}]
set_property PACKAGE_PIN D6 [get_ports {rx_data_p[3]}]
set_property PACKAGE_PIN C3 [get_ports {tx_data_n[3]}]
set_property PACKAGE_PIN C4 [get_ports {tx_data_p[3]}]

set_property IOSTANDARD LVDS_25 [get_ports rx_sync_p]
set_property IOSTANDARD LVDS_25 [get_ports rx_sync_n]
set_property IOSTANDARD LVDS_25 [get_ports rx_sysref_p]
set_property IOSTANDARD LVDS_25 [get_ports rx_sysref_n]

set_property PACKAGE_PIN D26 [get_ports rx_sync_p]
set_property PACKAGE_PIN C26 [get_ports rx_sync_n]
set_property PACKAGE_PIN H26 [get_ports rx_sysref_p]
set_property PACKAGE_PIN H27 [get_ports rx_sysref_n]

set_property IOSTANDARD LVDS_25 [get_ports tx_sync_p]
set_property IOSTANDARD LVDS_25 [get_ports tx_sync_n]
set_property IOSTANDARD LVDS_25 [get_ports tx_sysref_p]
set_property IOSTANDARD LVDS_25 [get_ports tx_sysref_n]

set_property PACKAGE_PIN H24 [get_ports tx_sync_p]
set_property PACKAGE_PIN H25 [get_ports tx_sync_n]
set_property PACKAGE_PIN G28 [get_ports tx_sysref_p]
set_property PACKAGE_PIN F28 [get_ports tx_sysref_n]

set_property IOSTANDARD LVCMOS25 [get_ports spi_csn_clk]
set_property IOSTANDARD LVCMOS25 [get_ports spi_csn_dac]
set_property IOSTANDARD LVCMOS25 [get_ports spi_csn_adc]
set_property IOSTANDARD LVCMOS25 [get_ports spi_clk]
set_property IOSTANDARD LVCMOS25 [get_ports spi_sdio]
set_property IOSTANDARD LVCMOS25 [get_ports spi_dir]

set_property PACKAGE_PIN G29 [get_ports spi_csn_clk]
set_property PACKAGE_PIN D29 [get_ports spi_csn_dac]
set_property PACKAGE_PIN A30 [get_ports spi_csn_adc]
set_property PACKAGE_PIN F30 [get_ports spi_clk]
set_property PACKAGE_PIN B30 [get_ports spi_sdio]
set_property PACKAGE_PIN E30 [get_ports spi_dir]

set_property IOSTANDARD LVCMOS25 [get_ports clkd_sync]
set_property IOSTANDARD LVCMOS25 [get_ports dac_reset]
set_property IOSTANDARD LVCMOS25 [get_ports dac_txen]
set_property IOSTANDARD LVCMOS25 [get_ports adc_pd]

set_property PACKAGE_PIN E29 [get_ports clkd_sync]
set_property PACKAGE_PIN C30 [get_ports dac_reset]
set_property PACKAGE_PIN B29 [get_ports dac_txen]
set_property PACKAGE_PIN H30 [get_ports adc_pd]

set_property IOSTANDARD LVCMOS25 [get_ports {clkd_status[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {clkd_status[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports dac_irq]
set_property IOSTANDARD LVCMOS25 [get_ports adc_fda]
set_property IOSTANDARD LVCMOS25 [get_ports adc_fdb]

set_property PACKAGE_PIN A25 [get_ports {clkd_status[0]}]
set_property PACKAGE_PIN A26 [get_ports {clkd_status[1]}]
set_property PACKAGE_PIN C29 [get_ports dac_irq]
set_property PACKAGE_PIN G27 [get_ports adc_fda]
set_property PACKAGE_PIN F27 [get_ports adc_fdb]

set_property IOSTANDARD LVDS_25 [get_ports trig_p]
set_property IOSTANDARD LVDS_25 [get_ports trig_n]

set_property PACKAGE_PIN E28 [get_ports trig_p]
set_property PACKAGE_PIN D28 [get_ports trig_n]

# ADC/DAC clocks
create_clock -period 2.667 -name rx_ref_clk [get_ports rx_ref_clk_p]
create_clock -period 2.667 -name tx_ref_clk [get_ports tx_ref_clk_p]
create_clock -period 170.667 -name rx_sysref [get_ports rx_sysref_p]
create_clock -period 170.667 -name tx_sysref [get_ports tx_sysref_p]

# Synchronization paths

set_false_path -from [get_ports pci_rst_n]
set_false_path -from [get_ports rx_sysref_p]
set_false_path -from [get_ports tx_sysref_p]

set_false_path -from [get_pins adc.q_user_reset_reg/C] -to [get_pins adc.up_reset_1_reg/D]
set_false_path -from [get_pins adc.adc_sync_ok_reg/C] -to [get_pins adc.adc_sync_ok_1_reg/D]
set_false_path -from [get_pins adc.adc_sync_fail_reg/C] -to [get_pins adc.adc_sync_fail_1_reg/D]

set_false_path -from [get_pins control_bar_inst/ctrl_bar_gen.tx_control_msg_reg/C] -to [get_pins adc.rx_up_control_msg_1_reg/D]
set_false_path -from [get_pins {control_bar_inst/ctrl_bar_gen.tx_control_index_reg[*]/C}] -to [get_pins {adc.rx_up_control_index_reg[*]/D}]
set_false_path -from [get_pins {control_bar_inst/ctrl_bar_gen.tx_control_data_reg[*]/C}] -to [get_pins {adc.rx_up_control_data_reg[*]/D}]

set_false_path -from [get_pins adc_app_inst/adc_app.tx_control_msg_reg/C] -to [get_pins adc.rx_pci_control_msg_1_reg/D]
set_false_path -from [get_pins {adc_app_inst/adc_app.tx_control_index_reg[*]/C}] -to [get_pins {adc.rx_pci_control_index_reg[*]/D}]
set_false_path -from [get_pins {adc_app_inst/adc_app.tx_control_data_reg[*]/C}] -to [get_pins {adc.rx_pci_control_data_reg[*]/D}]

set_false_path -from [get_pins adc_app_inst/adc_app.up_adc_started_reg/C] -to [get_pins adc.adc_started_1_reg/D]
set_false_path -from [get_pins adc_app_inst/adc_app.adc_probing_reg/C] -to [get_pins adc.adc_probing_1_reg/D]
set_false_path -from [get_pins adc_app_inst/adc_app.adc_running_reg/C] -to [get_pins adc.adc_running_1_reg/D]
set_false_path -from [get_pins adc.adc_delay_reg/C] -to [get_pins adc.adc_delay_1_reg/D]

set_false_path -from [get_pins adc_app_inst/adc_app.adc_started_reg/C] -to [get_pins adc_app_inst/adc_app.adc_started_1_reg/D]
set_false_path -from [get_pins adc_app_inst/adc_app.adc_probing_reg/C] -to [get_pins adc_app_inst/adc_app.adc_probing_1_reg/D]
set_false_path -from [get_pins adc_app_inst/adc_app.adc_running_reg/C] -to [get_pins adc_app_inst/adc_app.adc_running_1_reg/D]
set_false_path -from [get_pins adc_app_inst/adc_app.q_full_reg/C] -to [get_pins adc_app_inst/adc_app.adc_full_1_reg/D]
set_false_path -from [get_pins adc_app_inst/adc_app.q_almost_full_reg/C] -to [get_pins adc_app_inst/adc_app.adc_almost_full_1_reg/D]

set_false_path -from [get_pins adc_app_inst/adc_app.up_bar_irq_reg/C] -to [get_pins adc_app_inst/adc_app.pci_bar_irq_1_reg/D]
set_false_path -from [get_pins daq2_app_inst/daq2_app.adc_wr_reg/C] -to [get_pins adc_app_inst/adc_app.up_adc_started_1_reg/D]
set_false_path -from [get_pins adc_app_inst/adc_app.adc_stopped_reg/C] -to [get_pins adc_app_inst/adc_app.up_adc_stopped_1_reg/D]



set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk]
