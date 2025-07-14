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
; UDP.INC
; UDP protocol common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UDP_QUERY_ENTRIES EQU 32

udp_header	STRUC

udp_source		DW ?
udp_dest		DW ?
udp_len			DW ?
udp_checksum	DW ?

udp_header	ENDS

udp_query	STRUC

udp_query_next		DW ?
udp_query_port		DW ?
udp_query_thread	DW ?
udp_query_sel		DW ?
udp_query_offset	DW ?

udp_query	ENDS

udp_listen	STRUC

udp_listen_section		section_typ <>
udp_listen_next			DW ?
udp_listen_port			DW ?
udp_listen_data         DW ?
udp_listen_size         DW ?
udp_listen_wait_obj     DW ?
udp_listen_callback		DD ?,?

udp_listen	ENDS

udp_socket_sel	STRUC

udp_socket_ip		DD ?
udp_socket_port		DW ?

udp_socket_sel  ENDS
