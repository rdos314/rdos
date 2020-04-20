set_property PACKAGE_PIN K29 [get_ports user_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports user_clk_n]
set_property PACKAGE_PIN K28 [get_ports user_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports user_clk_p]
create_clock -period 6.400 -name user_clk [get_ports user_clk_p]

set_property PACKAGE_PIN AD11 [get_ports sys_clk_n]
set_property IOSTANDARD LVDS [get_ports sys_clk_n]
set_property PACKAGE_PIN AD12 [get_ports sys_clk_p]
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

set_property PACKAGE_PIN M5 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN M6 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN P5 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN P6 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN R3 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN R4 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN T5 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN T6 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN V5 [get_ports {pci_exp_rxn[4]}]
set_property PACKAGE_PIN V6 [get_ports {pci_exp_rxp[4]}]
set_property PACKAGE_PIN W3 [get_ports {pci_exp_rxn[5]}]
set_property PACKAGE_PIN W4 [get_ports {pci_exp_rxp[5]}]
set_property PACKAGE_PIN Y5 [get_ports {pci_exp_rxn[6]}]
set_property PACKAGE_PIN Y6 [get_ports {pci_exp_rxp[6]}]
set_property PACKAGE_PIN AA3 [get_ports {pci_exp_rxn[7]}]
set_property PACKAGE_PIN AA4 [get_ports {pci_exp_rxp[7]}]
set_property PACKAGE_PIN L3 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN L4 [get_ports {pci_exp_txp[0]}]
set_property PACKAGE_PIN M1 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN M2 [get_ports {pci_exp_txp[1]}]
set_property PACKAGE_PIN N3 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN N4 [get_ports {pci_exp_txp[2]}]
set_property PACKAGE_PIN P1 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN P2 [get_ports {pci_exp_txp[3]}]
set_property PACKAGE_PIN T1 [get_ports {pci_exp_txn[4]}]
set_property PACKAGE_PIN T2 [get_ports {pci_exp_txp[4]}]
set_property PACKAGE_PIN U3 [get_ports {pci_exp_txn[5]}]
set_property PACKAGE_PIN U4 [get_ports {pci_exp_txp[5]}]
set_property PACKAGE_PIN V1 [get_ports {pci_exp_txn[6]}]
set_property PACKAGE_PIN V2 [get_ports {pci_exp_txp[6]}]
set_property PACKAGE_PIN Y1 [get_ports {pci_exp_txn[7]}]
set_property PACKAGE_PIN Y2 [get_ports {pci_exp_txp[7]}]

set_property IOSTANDARD LVDS_25 [get_ports rx_sync_p]                     ; ## D08  FMC_HPC_LA01_CC_P
set_property IOSTANDARD LVDS_25 [get_ports rx_sync_n]                     ; ## D09  FMC_HPC_LA01_CC_N
set_property IOSTANDARD LVDS_25 [get_ports rx_sysref_p]    ; ## G09  FMC_HPC_LA03_P
set_property IOSTANDARD LVDS_25 [get_ports rx_sysref_n]    ; ## G10  FMC_HPC_LA03_N

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

set_property IOSTANDARD LVDS_25 [get_ports rx_sync_p]                     ; ## D08  FMC_HPC_LA01_CC_P
set_property IOSTANDARD LVDS_25 [get_ports rx_sync_n]                     ; ## D09  FMC_HPC_LA01_CC_N
set_property  IOSTANDARD LVDS_25 [get_ports rx_sysref_p]    ; ## G09  FMC_HPC_LA03_P
set_property  IOSTANDARD LVDS_25 [get_ports rx_sysref_n]    ; ## G10  FMC_HPC_LA03_N

set_property PACKAGE_PIN  D26 [get_ports rx_sync_p]                     ; ## D08  FMC_HPC_LA01_CC_P
set_property PACKAGE_PIN  C26 [get_ports rx_sync_n]                     ; ## D09  FMC_HPC_LA01_CC_N
set_property PACKAGE_PIN  H26 [get_ports rx_sysref_p]    ; ## G09  FMC_HPC_LA03_P
set_property PACKAGE_PIN  H27 [get_ports rx_sysref_n]    ; ## G10  FMC_HPC_LA03_N

set_property IOSTANDARD LVDS_25 [get_ports tx_sync_p]      ; ## H07  FMC_HPC_LA02_P
set_property IOSTANDARD LVDS_25 [get_ports tx_sync_n]      ; ## H08  FMC_HPC_LA02_N
set_property IOSTANDARD LVDS_25 [get_ports tx_sysref_p]    ; ## H10  FMC_HPC_LA04_P
set_property IOSTANDARD LVDS_25 [get_ports tx_sysref_n]    ; ## H11  FMC_HPC_LA04_N

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

set_property IOSTANDARD LVDS_25 [get_ports trig_p]         ; ## H13  FMC_HPC_LA07_P
set_property IOSTANDARD LVDS_25 [get_ports trig_n]         ; ## H14  FMC_HPC_LA07_N

set_property PACKAGE_PIN  E28 [get_ports trig_p]         ; ## H13  FMC_HPC_LA07_P
set_property PACKAGE_PIN  D28 [get_ports trig_n]         ; ## H14  FMC_HPC_LA07_N

# ADC/DAC clocks
create_clock -period 2.667 -name rx_ref_clk [get_ports rx_ref_clk_p]
create_clock -period 2.667 -name tx_ref_clk [get_ports tx_ref_clk_p]
create_clock -period 170.667 -name rx_sysref [get_ports rx_sysref_p]
create_clock -period 170.667 -name tx_sysref [get_ports tx_sysref_p]
 
set_false_path -from [get_ports pci_rst_n]
set_false_path -from [get_ports rx_sysref_p]
set_false_path -from [get_ports tx_sysref_p]
set_clock_groups -name async_group -async -group pci_ref_clk -group rx_ref_clk -group rx_sysref  -group user_clk -group sys_clk -group [get_clocks -of_objects [get_pins clk_up_inst/clk_out1]] -group [get_clocks -of_objects [get_pins pci_app_inst/pcie_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk sys_clk
