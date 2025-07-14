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
; IPCDEBUG.INC
; Common types for IPC-based kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_req_struc	STRUC

db_op		DB ?
db_x		DB ?
db_y		DB ?

debug_req_struc	ENDS

debug_req_data_struc	STRUC

dd_op		DB ?
dd_vm		DB ?
dd_offset	DD ?
dd_sel		DW ?
dd_count	DW ?

debug_req_data_struc	ENDS

debug_req_info_struc	STRUC

di_op				DB ?
di_free_physical	DD ?
di_used_small		DD ?
di_used_big			DD ?
di_used_local		DD ?
di_mode             DW ?

debug_req_info_struc	ENDS

debug_req_instr_struc	STRUC

ddi_op				DB ?
ddi_code			DB 16 DUP(?)
ddi_data_good		DB ?
ddi_data_offset		DD ?
ddi_data_sel		DW ?
ddi_mne				DB 40 DUP(?)

debug_req_instr_struc	ENDS

DEBUG_REQ_THREAD	EQU 1
DEBUG_REQ_DATA		EQU 2
DEBUG_REQ_INFO		EQU 3
DEBUG_REQ_INSTR		EQU 4

