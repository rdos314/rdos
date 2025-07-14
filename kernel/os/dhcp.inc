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

