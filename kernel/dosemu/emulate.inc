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
; EMULATE.INC
; Common instruction emulation related types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

a32				EQU 1
d32				EQU 2
rep_z			EQU 4
rep_nz			EQU 8
cs32			EQU 10h
ss32			EQU 20h

seg_es = 0
seg_cs = 1
seg_ss = 2
seg_ds = 3
seg_fs = 4
seg_gs = 5
seg_def = 7

em_struc	STRUC

reg_old_bp	DW ?
reg_ebp		DD ?
reg_edi		DD ?
reg_esi		DD ?
reg_edx		DD ?
reg_ecx		DD ?
reg_ebx		DD ?
reg_eax		DD ?
reg_eip		DD ?
reg_cs		DW ?
reg_eflags	DD ?
reg_esp		DD ?
reg_ss		DW ?
reg_es		DW ?
reg_ds		DW ?
reg_fs		DW ?
reg_gs		DW ?

em_struc	ENDS

em_sreg		EQU -1
em_flags	EQU -2

