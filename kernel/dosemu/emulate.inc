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

reg_old_ebp	DD ?
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

