;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Em486 CPU emulator
; Copyright (C) 1998-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage. For information on commercial usage,
; contact em486@rdos.net.
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
; EMULATE.INC
; External declarations for emulator module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STATE_RESET		EQU	0
STATE_IDLE		EQU 1
STATE_BUSY		EQU 2

EFLAGS_UNDEF	EQU 0FFF80000h

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

ACCESS_RPL		EQU 03h
ACCESS_DIR		EQU 10h
ACCESS_READ		EQU 20h
ACCESS_WRITE	EQU 40h
ACCESS_SIZE		EQU 80h

TRANSFER_CPL	EQU 3
TRANSFER_32		EQU 4
TRANSFER_FLAGS	EQU 8
TRANSFER_SWITCH	EQU 10h
TRANSFER_CODE	EQU 20h

a32				EQU 1
d32				EQU 2
rep_z			EQU 4
rep_nz			EQU 8
single_faulted	EQU 10h
double_faulted	EQU 20h
triple_faulted	EQU 40h
trap_fault		EQU 80h

DEBUG_BREAK		EQU 1
DEBUG_RESUME	EQU 2

TLB_REGISTER		EQU 00000001h
SYSTEM_REGISTER		EQU 00000010h
DESCRIPTOR_REGISTER	EQU 00000100h
GENERAL_REGISTER	EQU 00001000h
CONTROL_REGISTER	EQU 00010000h
INSTRUCTION_CODE_ONLY	EQU 00100000h
DISTANCE_INSTRUCTION	EQU 35		;ecart entre instruction et code
DATA_LINES_NR		EQU 4           ;nombre de ligne de données à afficher
DISTANCE_DATA		EQU 50		;ecart entre HEX et ASCII
Tprog_position	struc
  p_offset	dd ?
  p_segment	dw ?
Tprog_position	ends

Tprog_position_	EQU 4+2

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
d_access	DB ?
d_spare		DB ?

descriptor_struc	ENDS

cache_line_struc	STRUC

c_tag		DD ?
c_data		DB 16 DUP(?)

cache_line_struc	ENDS

cache_entry_struc	STRUC

c_line		DB 4 * SIZE cache_line_struc DUP(?)
c_lru		DB ?

cache_entry_struc	ENDS

tlb_entry_struc	STRUC

t_tag		DD ?
t_address	DD ?

tlb_entry_struc	ENDS

tlb_struc	STRUC

tlb			DB 32 * SIZE tlb_entry_struc DUP(?)
tlb_lru		DD ?
tlb_lmask	DD ?
tlb_lptr	DD ?

tlb_struc	ENDS

cpu_struc	STRUC

reg_cr0			DD ?
reg_cr2			DD ?
reg_cr3			DD ?
reg_cr4			DD ?
reg_dr0			DD ?
reg_dr1			DD ?
reg_dr2			DD ?
reg_dr3			DD ?
reg_dr6			DD ?
reg_dr7			DD ?
reg_eip			DD ?
reg_eflags		DD ?
reg_eax			DD ?
reg_ebx			DD ?
reg_ecx			DD ?
reg_edx			DD ?
reg_esp			DD ?
reg_ebp			DD ?
reg_esi			DD ?
reg_edi			DD ?
reg_gdt			descriptor_struc <>
reg_idt			descriptor_struc <>
reg_tr			descriptor_struc <>
reg_ldt			descriptor_struc <>
reg_es			descriptor_struc <>
reg_cs			descriptor_struc <>
reg_ss			descriptor_struc <>
reg_ds			descriptor_struc <>
reg_fs			descriptor_struc <>
reg_gs			descriptor_struc <>

bitmap_base		DD ?

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

reg_tlb			tlb_struc <>
reg_cache		DB 128 * SIZE cache_entry_struc DUP(?)

pending_int		DB ?

org_eip			DD ?
org_esp			DD ?
org_stack		DD ?

em_flags		DB ?
em_debug		DB ?
em_sreg			DB ?
em_pl			DB ?
em_transfer		DB ?
em_params		DB ?
em_errorcode	DW ?

req_buf			DB 16 DUP(?)

dis_sel			DW ?

opcode_text		DB 80 DUP(?)
data_offset		DD ?
data_sel		DD ?
data_valid		DB ?

total_cycles	DD ?

running			DB ?

cpu_struc	ENDS
