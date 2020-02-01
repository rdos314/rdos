set_property LVDS [get_ports sysclk_p]
set_property PACKAGE_PIN AD12 [get_ports sysclk_p]
set_property PACKAGE_PIN AD11 [get_ports sysclk_n]
set_property LVDS [get_ports sysclk_n]
set_property PACKAGE_PIN AC6 [get_ports GPIO_SW_W]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_SW_W]
set_property PACKAGE_PIN AG5 [get_ports GPIO_SW_E]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_SW_E]
set_property PACKAGE_PIN F16 [get_ports GPIO_LED_7_LS]
set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_7_LS]
set_property IOSTANDARD LVCMOS25 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property LOC G25 [get_ports sys_rst_n]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]

create_clock -name sys_clk -period 10 [get_ports sys_clk_p]
create_generated_clock -name clk_125mhz_x0y0 [get_pins pipe_clk_inst/mmcm_i/CLKOUT0]
create_generated_clock -name clk_250mhz_x0y0 [get_pins pipe_clk_inst/mmcm_i/CLKOUT1]
create_generated_clock -name clk_125mhz_mux_x0y0 \ 
                        -source [get_pins pipe_clk_inst/pclk_i1_bufgctrl.pclk_i1/I0] \
                        -divide_by 1 \
                        [get_pins pipe_clk_inst/pclk_i1_bufgctrl.pclk_i1/O]
#
create_generated_clock -name clk_250mhz_mux_x0y0 \ 
                        -source [get_pins pipe_clk_inst/pclk_i1_bufgctrl.pclk_i1/I1] \
                        -divide_by 1 -add -master_clock [get_clocks -of [get_pins pipe_clk_inst/pclk_i1_bufgctrl.pclk_i1/I1]] \
                        [get_pins pipe_clk_inst/pclk_i1_bufgctrl.pclk_i1/O]
#
set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y0 -group clk_250mhz_mux_x0y0
set_clock_group -name async1 -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {clk_125mhz_mux_x0y0 }]
set_clock_group -name async2 -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {clk_250mhz_mux_x0y0 }]
