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
; DOS.INC
; Common types in DOS emulation driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dos_vm_seg	SEGMENT AT 0

indos_flag			DB ?
critical_flag		DB ?
control_c_flag		DB ?
dos_callback_seg	DW ?
dos_first_dpb		DW ?,?
dos_first_sft		DW ?,?
dos_clock			DW ?,?
dos_con				DW ?,?

dos_vm_size			DB ?

dos_vm_seg	ENDS

dos_data_seg	SEGMENT AT 0

load_dos_exe_hooks	DB ?
load_dos_exe_arr	DW 2*16 DUP(?)

dos_data_seg	ENDS

dos_process_seg	SEGMENT AT 0

dos_mem_section		section_typ <>

dos_process_seg	ENDS

psp_seg		STRUC
psp_int20		DW ?
psp_memend		DW ?
psp_res1		DB ?
psp_dispatch	DB 5 DUP(?)
psp_int22		DW ?,?
psp_int23		DW ?,?
psp_int24		DW ?,?
psp_parent		DW ?
psp_handletab	DB 20 DUP(?)
psp_enviro		DW ?
psp_res2		DW ?,?
psp_handlesize	DW ?
psp_handleads	DW ?,?
psp_parent_sp	DW ?
psp_parent_ss	DW ?
psp_ret_code	DW ?
psp_res3		DB 18 DUP(?)
psp_doscall		DW ?
psp_retf		DB ?
psp_res4		DB 9 DUP(?)
psp_fcb1		DB 16 DUP(?)
psp_fcb2		DB 20 DUP(?)
psp_line		DB 80 DUP(?)
psp_seg		ENDS
