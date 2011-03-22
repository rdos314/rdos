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
; NET.INC
; Network interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class_data	STRUC

class_id		DB ?
addr_len		DB ?
driver_count	DW ?
driver_arr		DW 20h DUP(?)
broadcast_addr	DB ?				; variable size

class_data	ENDS

driver_data	STRUC

d_handle_list	DW ?
d_thread		DW ?
d_packet_size	DD ?
d_class			DW ?

; OUT NC		Data available
; OUT ECX		Size (0 means do not preallocate)
; OUT EDX		Packet type
d_preview		DD ?,?

; IN      ECX		Size
; IN/OUT  ES:EDI	Data buffer
d_receive		DD ?,?

; IN  ECX		Size
d_remove		DD ?,?

; IN  ECX		Size
; OUT ES:EDI	Data buffer. EDI must be >= 2!
d_get_buffer	DD ?,?

; IN  ECX		Size of data
; IN  DX		Packet type
; IN  DS:ESI	Dest address
; IN  ES		Data buffer selector
d_send			DD ?,?

; OUT  DS:ESI	Node address buffer
d_address		DD ?,?

; IN  ES		Data buffer selector
; OUT ES:ESI	Source address
; OUT ES:EDI	Dest address
d_get_address	DD ?,?

driver_data	ENDS

protocol_data	STRUC

p_callback			DD ?,?
p_packet_type		DW ?
p_logical_addr_len	DB ?
p_entry_list		DW ?
p_logical_my_addr	DB ?		; variable size

protocol_data	ENDS

protocol_entry	STRUC

prot_next				DW ?
prot_class				DW ?
prot_driver				DW ?
prot_logical_addr_len	DB ?
prot_hardware_addr_len	DB ?
prot_logical_addr		DB ?		; variable size
prot_hardware_addr		DB ?		; variable size

protocol_entry	ENDS

LS_TYPE_RECEIVED = 1
LS_TYPE_SENT = 2

log_struc	STRUC

ls_size		DW ?
ls_type		DB ?
ls_time		DD ?,?

log_struc	ENDS
