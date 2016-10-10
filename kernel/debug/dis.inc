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

a32				EQU 1
d32				EQU 2
l64             EQU 100h

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
reg_gdt		descriptor_struc <>
reg_idt		descriptor_struc <>
reg_tr			descriptor_struc <>
reg_ldt			descriptor_struc <>
reg_es			descriptor_struc <>
reg_cs			descriptor_struc <>
reg_ss			descriptor_struc <>
reg_ds			descriptor_struc <>
reg_fs			descriptor_struc <>
reg_gs			descriptor_struc <>

em_flags                DW ?

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

op_syntax               DD ?
op_codes                DD 100 DUP(?)
data_mode               DB ?
edata_mode              DB ?
override                DD ?
ignore_ptr              DB ?
op_rex                  DB ?
root_tab                DD ?
op_in_code              DB 50 DUP(?)

opcode_text		DB 80 DUP(?)
data_offset		DD ?,?
data_sel		DD ?
data_valid		DB ?

code_cache              DB 16 DUP (?)

cpu_struc	ENDS
