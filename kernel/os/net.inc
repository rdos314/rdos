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

net_data	STRUC

arp_section			section_typ <>
arp_rec_list		DW ?
arp_send_list		DW ?
arp_answ_list		DW ?
arp_thread			DW ?
ppp_handle			DW ?
class_count			DW ?
class_arr			DW 20h DUP(?)
protocol_count		DW ?
protocol_arr		DW 20h DUP(?)

net_data	ENDS

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

;	NC		Data available
;	ECX		Size
;	EDX		Packet type
;	DS:ESI	Source address
d_preview			DD ?

;	ECX		Size
;	DS:ESI	Source address
;	ES:EDI	Data buffer
d_receive		DD ?

;	ECX		Size
;	DS:ESI	Source address
d_remove		DD ?

;	ECX		Size of data
;	DX		Packet type
;	DS:ESI	Dest address
;	ES:EDI	Data buffer
d_send			DD ?

;	DS:ESI	Node address
d_address		DD ?

driver_data	ENDS

protocol_data	STRUC

p_callback			DD ?
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
