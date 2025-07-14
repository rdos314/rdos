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
; COM.INC
; Device-independent serial communication
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CTS_LINE    = 1
DSR_LINE    = 2
RI_LINE     = 4
DCD_LINE    = 8

com_device_struc   STRUC

; OUT ES      Com port selector
cd_create_proc              DD ?,?

cd_reserve_line_proc        DD ?,?

cd_set_dtr_proc             DD ?,?

cd_reset_dtr_proc           DD ?,?

cd_wait_for_line_state_proc DD ?,?

; OUT AL Line status
cd_get_line_state_proc      DD ?,?

cd_controller               DW ?
cd_device                   DW ?
cd_open                     DB ?
cd_line_reserved            DB ?

cd_com_port                 DB ?

com_device_struc   ENDS

com_port_struc	STRUC

;   IN  AH		# of data bits
;	IN  BL		# of stop bits
;	IN  BH		parity char
;	IN  ECX		baudrate
;   IN  DS      Com port selector
open_com_proc   DD ?,?

;   IN  DS      Com port selector
close_com_proc   DD ?,?

;   IN  DS      Com port selector
enable_cts_proc   DD ?,?

;   IN  DS      Com port selector
disable_cts_proc   DD ?,?

;   IN  DS      Com port selector
set_dtr_proc   DD ?,?

;   IN  DS      Com port selector
reset_dtr_proc   DD ?,?

;   IN  DS      Com port selector
set_rts_proc   DD ?,?

;   IN  DS      Com port selector
reset_rts_proc   DD ?,?

;   IN  DS      Com port selector
enable_auto_rts_proc   DD ?,?

;   IN  DS      Com port selector
disable_auto_rts_proc   DD ?,?

;   IN  DS      Com port selector
flush_com_proc   DD ?,?

;   IN  DS      Com port selector
start_send_com_proc   DD ?,?

;   IN  DS      Com port selector
reset_com_proc   DD ?,?

;   IN  DS      Com port selector
supports_full_duplex_proc   DD ?,?

;   IN  DS      Com port selector
is_auto_rts_on_proc   DD ?,?

;   IN  DS      Com port selector
;   IN  AL      Break characters
send_com_break_proc   DD ?,?

send_count		DW ?
rec_count	  	DW ?

send_head		DW ?
rec_head		DW ?

send_tail		DW ?
rec_tail		DW ?

send_size		DW ?
rec_size		DW ?

rec_buf			DW ?
send_buf		DW ?

avail_obj   	DW ?

send_wait       DW ?

com_device      DW ?

com_spinlock    spinlock_typ <>

line_reserved   DB ?

com_port_struc	ENDS

