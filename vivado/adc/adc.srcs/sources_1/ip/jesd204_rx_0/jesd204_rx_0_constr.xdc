
# SYNC~ is a asynchronous interface
set_false_path \
  -from [get_registers *|jesd204_rx_ctrl:i_rx_ctrl|sync_n]

set_property ASYNC_REG TRUE \
  [get_cells {i_lmfc/sysref_d1_reg}] \
  [get_cells {i_lmfc/sysref_d2_reg}]

# Make sure that the device clock to sysref skew is at least somewhat
# predictable
set_property IOB true \
  [get_cells {i_lmfc/sysref_r_reg}]
