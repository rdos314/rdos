;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage in embedded systems. For information on
; usage in commercial embedded systems, contact embedded@rdos.net
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;
; The author of this program may be contacted at leif@rdos.net
;
; PCI.INC
; PCI common types & constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PCI_vendorID = 0
PCI_deviceID = 2
PCI_command_reg = 4
PCI_status_reg = 6
PCI_revisionID = 8
PCI_progIF = 9
PCI_subclass = 10
PCI_classcode = 11
PCI_cacheline_size = 12
PCI_latency = 13
PCI_header_type = 14
PCI_BIST = 15;
PCI_interrupt_line = 60
PCI_interrupt_pin = 61

PCI_header_type_nbr = 0
PCI_header_type_br = 1
PCI_header_type_card = 2

PCI_command_IO = 1
PCI_command_mem = 2
PCI_command_busmstr = 4
PCI_command_spec_cyc = 8
PCI_command_invalidate = 10h
PCI_command_VGAsnoop = 20h
PCI_command_parity_err = 40h
PCI_command_wait_cyc = 80h
PCI_command_sys_err = 100h
PCI_command_fast_trns = 200h

;
; non-bridge registers
;

PCI_nbr_base_address0 = 16
PCI_nbr_base_address1 = 20
PCI_nbr_base_address2 = 24
PCI_nbr_base_address3 = 28
PCI_nbr_base_address4 = 32
PCI_nbr_base_address5 = 36
PCI_nbr_CardBus_CIS = 40
PCI_nbr_subsystem_vendorID = 44
PCI_nbr_subsystem_deviceID = 46
PCI_nbr_expansion_ROM = 48
PCI_nbr_cap_ptr = 52
PCI_nbr_min_grant = 62
PCI_nbr_max_latency = 63

;
; bridge registers
;

PCI_br_base_address0 = 16
PCI_br_base_address1 = 20
PCI_br_primary_bus = 24
PCI_br_secondary_bus = 25
PCI_br_subordinate_bus = 26
PCI_br_secondary_latency = 27
PCI_br_IO_base_low = 28
PCI_br_IO_limit_low = 29
PCI_br_secondary_status = 30
PCI_br_memory_base_low = 32
PCI_br_memory_limit_low = 34
PCI_br_prefetch_base_low = 36
PCI_br_prefetch_limit_low = 38
PCI_br_prefetch_base_high = 40
PCI_br_prefetch_limit_high = 44
PCI_br_IO_base_high = 48
PCI_br_IO_limit_high = 50
PCI_br_expansion_ROM = 56
PCI_br_bridge_control = 62

;
; card bus registers
;

PCI_card_ExCa_base = 16
PCI_card_cap_ptr = 20
PCI_card_secondary_status = 22
PCI_card_PCI_bus = 24
PCI_card_CardBus_bus = 25
PCI_card_subordinate_bus = 26
PCI_card_latency_timer = 27
PCI_card_memory_base0 = 28
PCI_card_memory_limit0 = 32
PCI_card_memory_base1 = 36
PCI_card_memory_limit1 = 40
PCI_card_IObase_0low = 44
PCI_card_IObase_0high = 46
PCI_card_IOlimit_0low = 48
PCI_card_IOlimit_0high = 50
PCI_card_IObase_1low = 52
PCI_card_IObase_1high = 54
PCI_card_IOlimit_1low = 56
PCI_card_IOlimit_1high = 58
PCI_card_bridge_control = 62
PCI_card_subsystem_vendorID = 64
PCI_card_subsystem_deviceID = 66
PCI_card_legacy_baseaddr = 68
PCI_card_vendor = 96
