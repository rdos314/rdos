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
d_link_up       DW ?

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

; OUT NC        Link ok
d_get_link_state	DD ?,?

; OUT ES:EDI    MAC
d_get_mac               DD ?,?

driver_data	ENDS

protocol_data	STRUC

p_callback		DD ?,?
p_is_cachable           DD ?,?
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
