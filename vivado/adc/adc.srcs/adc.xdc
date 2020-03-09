create_clock -period 4.000 -name sys_clk [get_ports sys_clk_p]

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

set_property IOSTANDARD LVDS_25 [get_ports rx_sync_p]                     ; ## D08  FMC_HPC_LA01_CC_P
set_property IOSTANDARD LVDS_25 [get_ports rx_sync_n]                     ; ## D09  FMC_HPC_LA01_CC_N
set_property IOSTANDARD LVDS_25 DIFF_TERM TRUE [get_ports rx_sysref_p]    ; ## G09  FMC_HPC_LA03_P
set_property IOSTANDARD LVDS_25 DIFF_TERM TRUE [get_ports rx_sysref_n]    ; ## G10  FMC_HPC_LA03_N

set_property PACKAGE_PIN  E8 [get_ports rx_ref_clk_p]                                      ; ## B20  FMC_HPC_GBTCLK1_M2C_P
set_property PACKAGE_PIN  E7 [get_ports rx_ref_clk_n]                                      ; ## B21  FMC_HPC_GBTCLK1_M2C_N
set_property  PACKAGE_PIN  A8 [get_ports rx_data_p[0]]                                      ; ## A10  FMC_HPC_DP3_M2C_P
set_property  PACKAGE_PIN  A7 [get_ports rx_data_n[0]]                                      ; ## A11  FMC_HPC_DP3_M2C_N
set_property  PACKAGE_PIN  E4 [get_ports rx_data_p[1]]                                      ; ## C06  FMC_HPC_DP0_M2C_P
set_property  PACKAGE_PIN  E3 [get_ports rx_data_n[1]]                                      ; ## C07  FMC_HPC_DP0_M2C_N
set_property  PACKAGE_PIN  B6 [get_ports rx_data_p[2]]                                      ; ## A06  FMC_HPC_DP2_M2C_P
set_property  PACKAGE_PIN  B5 [get_ports rx_data_n[2]]                                      ; ## A07  FMC_HPC_DP2_M2C_N
set_property  PACKAGE_PIN  D6 [get_ports rx_data_p[3]]                                      ; ## A02  FMC_HPC_DP1_M2C_P
set_property  PACKAGE_PIN  D5 [get_ports rx_data_n[3]]                                      ; ## A03  FMC_HPC_DP1_M2C_N

set_property  PACKAGE_PIN  C8 [get_ports tx_ref_clk_p]                                      ; ## D04  FMC_HPC_GBTCLK0_M2C_P
set_property  PACKAGE_PIN  C7 [get_ports tx_ref_clk_n]                                      ; ## D05  FMC_HPC_GBTCLK0_M2C_N
set_property  PACKAGE_PIN  A4 [get_ports tx_data_p[0]]                                      ; ## A30  FMC_HPC_DP3_C2M_P (tx_data_p[0])
set_property  PACKAGE_PIN  A3 [get_ports tx_data_n[0]]                                      ; ## A31  FMC_HPC_DP3_C2M_N (tx_data_n[0])
set_property  PACKAGE_PIN  D2 [get_ports tx_data_p[1]]                                      ; ## C02  FMC_HPC_DP0_C2M_P (tx_data_p[3])
set_property  PACKAGE_PIN  D1 [get_ports tx_data_n[1]]                                      ; ## C03  FMC_HPC_DP0_C2M_N (tx_data_n[3])
set_property  PACKAGE_PIN  B2 [get_ports tx_data_p[2]]                                      ; ## A26  FMC_HPC_DP2_C2M_P (tx_data_p[1])
set_property  PACKAGE_PIN  B1 [get_ports tx_data_n[2]]                                      ; ## A27  FMC_HPC_DP2_C2M_N (tx_data_n[1])
set_property  PACKAGE_PIN  C4 [get_ports tx_data_p[3]]                                      ; ## A22  FMC_HPC_DP1_C2M_P (tx_data_p[2])
set_property  PACKAGE_PIN  C3 [get_ports tx_data_n[3]]                                      ; ## A23  FMC_HPC_DP1_C2M_N (tx_data_n[2])

set_property PACKAGE_PIN  D26 [get_ports rx_sync_p]                     ; ## D08  FMC_HPC_LA01_CC_P
set_property PACKAGE_PIN  C26 [get_ports rx_sync_n]                     ; ## D09  FMC_HPC_LA01_CC_N
set_property PACKAGE_PIN  H26 [get_ports rx_sysref_p]    ; ## G09  FMC_HPC_LA03_P
set_property PACKAGE_PIN  H27 [get_ports rx_sysref_n]    ; ## G10  FMC_HPC_LA03_N

set_property IOSTANDARD LVDS_25 DIFF_TERM TRUE [get_ports tx_sync_p]      ; ## H07  FMC_HPC_LA02_P
set_property IOSTANDARD LVDS_25 DIFF_TERM TRUE [get_ports tx_sync_n]      ; ## H08  FMC_HPC_LA02_N
set_property IOSTANDARD LVDS_25 DIFF_TERM TRUE [get_ports tx_sysref_p]    ; ## H10  FMC_HPC_LA04_P
set_property IOSTANDARD LVDS_25 DIFF_TERM TRUE [get_ports tx_sysref_n]    ; ## H11  FMC_HPC_LA04_N

set_property PACKAGE_PIN  H24 [get_ports tx_sync_p]      ; ## H07  FMC_HPC_LA02_P
set_property PACKAGE_PIN  H25 [get_ports tx_sync_n]      ; ## H08  FMC_HPC_LA02_N
set_property PACKAGE_PIN  G28 [get_ports tx_sysref_p]    ; ## H10  FMC_HPC_LA04_P
set_property PACKAGE_PIN  F28 [get_ports tx_sysref_n]    ; ## H11  FMC_HPC_LA04_N

set_property IOSTANDARD LVCMOS25 [get_ports spi_csn_clk]                  ; ## D11  FMC_HPC_LA05_P
set_property IOSTANDARD LVCMOS25 [get_ports spi_csn_dac]                  ; ## C14  FMC_HPC_LA10_P
set_property IOSTANDARD LVCMOS25 [get_ports spi_csn_adc]                  ; ## D15  FMC_HPC_LA09_N
set_property IOSTANDARD LVCMOS25 [get_ports spi_clk]                      ; ## D12  FMC_HPC_LA05_N
set_property IOSTANDARD LVCMOS25 [get_ports spi_sdio]                     ; ## D14  FMC_HPC_LA09_P
set_property IOSTANDARD LVCMOS25 [get_ports spi_dir]                      ; ## G13  FMC_HPC_LA08_N

set_property PACKAGE_PIN  G29 [get_ports spi_csn_clk]                  ; ## D11  FMC_HPC_LA05_P
set_property PACKAGE_PIN  D29 [get_ports spi_csn_dac]                  ; ## C14  FMC_HPC_LA10_P
set_property PACKAGE_PIN  A30 [get_ports spi_csn_adc]                  ; ## D15  FMC_HPC_LA09_N
set_property PACKAGE_PIN  F30 [get_ports spi_clk]                      ; ## D12  FMC_HPC_LA05_N
set_property PACKAGE_PIN  B30 [get_ports spi_sdio]                     ; ## D14  FMC_HPC_LA09_P
set_property PACKAGE_PIN  E30 [get_ports spi_dir]                      ; ## G13  FMC_HPC_LA08_N

set_property IOSTANDARD LVCMOS25 [get_ports clkd_sync]                    ; ## G12  FMC_HPC_LA08_P
set_property IOSTANDARD LVCMOS25 [get_ports dac_reset]                    ; ## C15  FMC_HPC_LA10_N
set_property IOSTANDARD LVCMOS25 [get_ports dac_txen]                     ; ## G16  FMC_HPC_LA12_N
set_property IOSTANDARD LVCMOS25 [get_ports adc_pd]                       ; ## C10  FMC_HPC_LA06_P

set_property PACKAGE_PIN  E29 [get_ports clkd_sync]                    ; ## G12  FMC_HPC_LA08_P
set_property PACKAGE_PIN  C30 [get_ports dac_reset]                    ; ## C15  FMC_HPC_LA10_N
set_property PACKAGE_PIN  B29 [get_ports dac_txen]                     ; ## G16  FMC_HPC_LA12_N
set_property PACKAGE_PIN  H30 [get_ports adc_pd]                       ; ## C10  FMC_HPC_LA06_P

set_property IOSTANDARD LVCMOS25 [get_ports clkd_status[0]]               ; ## D17  FMC_HPC_LA13_P
set_property IOSTANDARD LVCMOS25 [get_ports clkd_status[1]]               ; ## D18  FMC_HPC_LA13_N
set_property IOSTANDARD LVCMOS25 [get_ports dac_irq]                      ; ## G15  FMC_HPC_LA12_P
set_property IOSTANDARD LVCMOS25 [get_ports adc_fda]                      ; ## H16  FMC_HPC_LA11_P
set_property IOSTANDARD LVCMOS25 [get_ports adc_fdb]                      ; ## H17  FMC_HPC_LA11_N

set_property PACKAGE_PIN  A25 [get_ports clkd_status[0]]               ; ## D17  FMC_HPC_LA13_P
set_property PACKAGE_PIN  A26 [get_ports clkd_status[1]]               ; ## D18  FMC_HPC_LA13_N
set_property PACKAGE_PIN  C29 [get_ports dac_irq]                      ; ## G15  FMC_HPC_LA12_P
set_property PACKAGE_PIN  G27 [get_ports adc_fda]                      ; ## H16  FMC_HPC_LA11_P
set_property PACKAGE_PIN  F27 [get_ports adc_fdb]                      ; ## H17  FMC_HPC_LA11_N

set_property IOSTANDARD LVDS_25 DIFF_TERM TRUE [get_ports trig_p]         ; ## H13  FMC_HPC_LA07_P
set_property IOSTANDARD LVDS_25 DIFF_TERM TRUE [get_ports trig_n]         ; ## H14  FMC_HPC_LA07_N

set_property PACKAGE_PIN  E28 [get_ports trig_p]         ; ## H13  FMC_HPC_LA07_P
set_property PACKAGE_PIN  D28 [get_ports trig_n]         ; ## H14  FMC_HPC_LA07_N

set_property LOC IBUFDS_GTE2_X0Y1 [get_cells refclk_ibuf]

# ADC/DAC clocks

create_clock -name tx_ref_clk   -period  2.00 [get_ports tx_ref_clk_p]
create_clock -name rx_ref_clk   -period  2.00 [get_ports rx_ref_clk_p]

set_false_path -to [get_ports -filter NAME=~led_*]
set_false_path -from [get_ports sys_rst_n]
set_false_path -from [get_pins -hierarchical *req_start*]
set_false_path -from [get_pins -hierarchical *req_stop*]
set_false_path -from [get_pins -hierarchical *adc_on*]
set_false_path -from [get_pins -hierarchical *notify_sample_data*]
set_false_path -from [get_pins -hierarchical *ack_sample_data*]
set_false_path -from [get_pins -hierarchical *sync_buffer*] 

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets user_clk]
