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
; DNS.INC
; DNS protocol common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dns_header	STRUC

dns_id		DW ?
dns_op		DW ?
dns_qdcount	DW ?
dns_ancount	DW ?
dns_nscount	DW ?
dns_arcount	DW ?

dns_header	ENDS

dns_host_query	STRUC

dns_qtype	DW ?		; = 1
dns_qclass	DW ?		; = 1

dns_host_query	ENDS

dns_host_answer	STRUC

dns_atype	DW ?		; = 1
dns_aclass	DW ?		; = 1
dns_ttl		DD ?		
dns_alen	DW ?		; = 4

dns_host_answer	ENDS
