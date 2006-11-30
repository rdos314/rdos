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
; COM.INC
; Device-independent serial communication
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

com_device_struc   STRUC

;   OUT ES      Com port selector
cd_create_proc   DD ?

cd_controller    DW ?
cd_device        DW ?

com_device_struc   ENDS

com_port_struc	STRUC

;   IN  AH		# of data bits
;	IN  BL		# of stop bits
;	IN  BH		parity char
;	IN  ECX		baudrate
;   IN  DS      Com port selector
open_com_proc   DD ?

;   IN  DS      Com port selector
close_com_proc   DD ?

;   IN  DS      Com port selector
enable_cts_proc   DD ?

;   IN  DS      Com port selector
disable_cts_proc   DD ?

;   IN  DS      Com port selector
set_dtr_proc   DD ?

;   IN  DS      Com port selector
reset_dtr_proc   DD ?

;   IN  DS      Com port selector
set_rts_proc   DD ?

;   IN  DS      Com port selector
reset_rts_proc   DD ?

;   IN  DS      Com port selector
enable_auto_rts_proc   DD ?

;   IN  DS      Com port selector
disable_auto_rts_proc   DD ?

;   IN  DS      Com port selector
flush_com_proc   DD ?

;   IN  DS      Com port selector
start_send_com_proc   DD ?

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

com_port_struc	ENDS

