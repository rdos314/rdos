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

