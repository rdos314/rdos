;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; kdebug.INC
; External declarations kernel debugger module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lfb_linear  = 0C0000000h

STATE_RESET		EQU	0
STATE_IDLE		EQU 1
STATE_BUSY		EQU 2

EFLAGS_ID		EQU 200000h
EFLAGS_VIP		EQU 100000h
EFLAGS_VIF		EQU 080000h
EFLAGS_AC		EQU 040000h
EFLAGS_VM		EQU 020000h
EFLAGS_RF		EQU 010000h
EFLAGS_NT		EQU 004000h
EFLAGS_IOPL		EQU 003000h
EFLAGS_OF		EQU 000800h
EFLAGS_DF		EQU 000400h
EFLAGS_IF		EQU 000200h
EFLAGS_TF		EQU 000100h
EFLAGS_SF		EQU 000080h
EFLAGS_ZF		EQU 000040h
EFLAGS_AF		EQU 000010h
EFLAGS_PF		EQU 000004h
EFLAGS_CF		EQU 000001h

CR0_PG			EQU 80000000h
CR0_CD			EQU 40000000h
CR0_NW			EQU 20000000h
CR0_AM			EQU 00040000h
CR0_WP			EQU 00010000h
CR0_NE			EQU 00000020h
CR0_TS			EQU 00000008h
CR0_EM			EQU 00000004h
CR0_MP			EQU 00000002h
CR0_PE			EQU 00000001h

EFER_LME        EQU 100h

ACCESS_RPL		EQU 03h
ACCESS_VALID		EQU 8h
ACCESS_DIR		EQU 10h
ACCESS_READ		EQU 20h
ACCESS_WRITE	        EQU 40h
ACCESS_32		EQU 80h
ACCESS_64               EQU 100h

TRANSFER_CPL	EQU 3
TRANSFER_32		EQU 4
TRANSFER_FLAGS	EQU 8
TRANSFER_SWITCH	EQU 10h
TRANSFER_CODE	EQU 20h

DEBUG_FLAG_VALID  = 1
DEBUG_FLAG_DESCR  = 2

a32				EQU 1
d32				EQU 2
rep_z			EQU 4
rep_nz			EQU 8
single_faulted	EQU 10h
double_faulted	EQU 20h
triple_faulted	EQU 40h
trap_fault		EQU 80h
l64             EQU 100h

seg_es = 0
seg_cs = 1
seg_ss = 2
seg_ds = 3
seg_fs = 4
seg_gs = 5
seg_def = 7

descriptor_struc STRUC

d_base		DD ?
d_limit		DD ?
d_selector	DW ?
d_access	DW ?

descriptor_struc	ENDS

cpu_struc	STRUC

reg_cr0			DD ?,?
reg_cr2			DD ?,?
reg_cr3			DD ?,?
reg_cr4			DD ?,?
reg_dr0			DD ?,?
reg_dr1			DD ?,?
reg_dr2			DD ?,?
reg_dr3			DD ?,?
reg_dr6			DD ?,?
reg_dr7			DD ?,?
reg_eip			DD ?,?
reg_eflags		DD ?,?
reg_eax			DD ?,?
reg_ebx			DD ?,?
reg_ecx			DD ?,?
reg_edx			DD ?,?
reg_esp			DD ?,?
reg_ebp			DD ?,?
reg_esi			DD ?,?
reg_edi			DD ?,?
reg_r8          DD ?,?
reg_r9          DD ?,?
reg_r10         DD ?,?
reg_r11         DD ?,?
reg_r12         DD ?,?
reg_r13         DD ?,?
reg_r14         DD ?,?
reg_r15         DD ?,?
reg_uoffs       DD ?,?
reg_gdt		descriptor_struc <>
reg_idt		descriptor_struc <>
reg_tr		descriptor_struc <>
reg_ldt		descriptor_struc <>
reg_es		descriptor_struc <>
reg_cs		descriptor_struc <>
reg_ss		descriptor_struc <>
reg_ds		descriptor_struc <>
reg_fs		descriptor_struc <>
reg_gs		descriptor_struc <>
reg_usel    descriptor_struc <>

reg_efer        DD ?,?

math_op			DB ?,?
math_prev_op	DB ?,?
math_control	DW ?
math_status		DW ?
math_tag		DW ?
math_eip		DD ?
math_cs			DW ?
math_data_offs	DD ?
math_data_sel	DW ?
math_st0		DT ?
math_st1		DT ?
math_st2		DT ?
math_st3		DT ?
math_st4		DT ?
math_st5		DT ?
math_st6		DT ?
math_st7		DT ?

op_syntax       DD ?
op_codes        DD 100 DUP(?)
data_mode       DB ?
edata_mode      DB ?
override        DD ?
ignore_ptr      DB ?
op_rex          DB ?
root_tab        DD ?

core_sel        DW ?
curr_irq        DD ?
fault_vect      DB ?
fault_error     DD ?

cpu_read_mem    DD ?
cpu_write_mem   DD ?

cpu_read_phys   DD ?
cpu_write_phys  DD ?

org_eip			DD ?,?
org_esp			DD ?,?
org_stack		DD ?

temp_size       DW ?
temp_base       DD ?

debug_core_id         DW ?
debug_core_sel        DW ?
debug_flags           DW ?

code_start      DD ?,?
code_cache      DB 32 DUP(?)

req_buf			DB 32 DUP(?)

em_flags		DW ?
em_debug		DB ?
em_sreg			DB ?
em_pl			DB ?
em_transfer		DB ?
em_params		DB ?
em_ist                  DB ?
em_rex                  DB ?
em_modrm                DB ?
em_extra_bytes          DB ?
em_errorcode	        DW ?

dis_sel			DW ?

opcode_text		DB 80 DUP(?)
data_offset		DD ?,?
data_sel		DD ?
data_valid		DB ?

cpu_struc	ENDS

mon_code_sel            = 8h
mon_gdt_sel             = 10h
mon_data_sel            = 18h
mon_flat_sel            = 20h
mon_system_data_sel     = 28h
mon_shutdown_code_sel	= 38h
mon_process_page_sel    = 40h
mon_deb_sel             = 48h
mon_shutdown_gate_sel   = 68h
mon_text_sel            = 0D0h

mon_core_struc     STRUC

mc_sys_linear          DD ?
mc_mon_linear          DD ?

mon_core_struc     ENDS

monitor_data_sel        STRUC

mon_map_linear      DD ?
mon_usb_func_linear DD ?
mon_usb_linear      DD ?

mon_core_count      DW ?

mon_curr_core       DW ?
mon_curr_row        DW ?
mon_curr_col        DW ?

mon_key_status      DB ?
mon_key_command     DB ?
mon_shift_states    DW ?
mon_key_code        DW ?
mon_c_vk_code       DB ?
mon_scan_code       DB ?

mon_context_size    DW ?
mon_cmd_pcs         DW ?
mon_cmd_enque       DD ?
mon_event_deque     DD ?
mon_event_ccs       DW ?

mon_control_enque   DD ?
mon_control_deque   DD ?
mon_control_pcs     DW ?

mon_data_enque      DD ?
mon_data_deque      DD ?
mon_data_pcs        DW ?
mon_data_ep         DB ?

mon_usb_oper        DD ?
mon_usb_root_port   DD ?
mon_usb_port        DB ? 
mon_usb_adr         DB ? 
mon_usb_ports       DB ?
mon_hub_power       DB ?

mon_usb_shift       DB ?
mon_usb_keys        DD ?

mon_ohci_count      DB ?
mon_ohci_arr        DD 10 DUP(?)

mon_ehci_count      DB ?
mon_ehci_arr        DD 10 DUP(?)

mon_xhci_param      DD ?
mon_xhci_door_bell  DD ?
mon_xhci_runtime    DD ?
mon_xhci_count      DB ?
mon_xhci_arr        DD 10 DUP(?,?)

mon_dis_buf         DB 40 DUP(?)
mon_com_buf         DB 14 DUP(?)

; should be last!

mon_core_regs       DB ?

monitor_data_sel        ENDS

monitor_deb_sel        STRUC

int_fault_regs      cpu_struc <>

int_started         DB ?
int_count           DB ?
int_deb_row         DW ?
int_deb_col         DW ?

int_curr_row        DW ?
int_curr_col        DW ?

int_key_code        DW ?
int_c_vk_code       DB ?
int_scan_code       DB ?

int_dis_buf         DB 40 DUP(?)

monitor_deb_sel        ENDS
