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
; DHCP.INC
; DHCP protocol common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dhcp_header	STRUC

dhcp_op				DB ?
dhcp_hw_type		DB ?
dhcp_hw_len			DB ?
dhcp_hops			DB ?
dhcp_id				DD ?
dhcp_elapsed		DW ?
dhcp_flags			DW ?
dhcp_client_ip		DD ?
dhcp_req_ip			DD ?
dhcp_server_ip		DD ?
dhcp_relay_ip		DD ?
dhcp_hw_addr		DB 10h DUP(?)
dhcp_server_name	DB 40h DUP(?)	
dhcp_file_name		DB 80h DUP(?)
dhcp_magic			DD ?
dhcp_msg_code		DB ?
dhcp_msg_len		DB ?
dhcp_msg_type		DB ?

dhcp_header	ENDS

