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
; IP.INC
; IP protocol common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ip_header	STRUC

ip_hdr_ver		DB ?
ip_tos			DB ?
ip_size			DW ?
ip_id			DW ?
ip_frags		DW ?
ip_ttl			DB ?
ip_proto		DB ?
ip_checksum		DW ?
ip_source		DD ?
ip_dest			DD ?

ip_header	ENDS

ip_protocol_data	STRUC

prot_callback		DD ?,?
prot_id				DB ?

ip_protocol_data	ENDS

host_entry	STRUC

host_next		DW ?
host_section 	section_typ <>
host_addr		DD ?
host_rtm		DD ?
host_rtt		DD ?
host_rto		DD ?

host_entry	ENDS
