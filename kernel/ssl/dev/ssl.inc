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
; ssl.inc
; SSL datatypes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_SSL_REQ_COUNT  = 16

REPLY_DEFAULT      = 0
REPLY_DATA         = 1

ssl_cmd  STRUC

ssl_req_section          section_typ <>
ssl_cmd_thread           DW ?
ssl_cmd_curr             DD ?

ssl_cmd_unused_mask      DD ?
ssl_cmd_free_mask        DD ?
ssl_cmd_arr              DD 4 * 32 DUP(?)
ssl_cmd_ring             DB 34 DUP(?)
ssl_cmd_head             DB ?
ssl_cmd_tail             DB ?

ssl_req_arr              DW MAX_SSL_REQ_COUNT DUP(?)

ssl_cmd  ENDS


; should be 16 bytes!

ssl_server_msg  STRUC

ssls_phys                  DD ?,?
ssls_server_linear         DD ?
ssls_sel                   DW ?
ssls_thread                DW ?

ssl_server_msg  ENDS

ssl_reg      STRUC

reg_op              DD ?
reg_handle          DD ?
reg_buf             DD ?,?
reg_size            DD ?
reg_eflags          DD ?
reg_eax             DD ?
reg_ebx             DD ?
reg_ecx             DD ?
reg_edx             DD ?
reg_esi             DD ?
reg_edi             DD ?

ssl_reg      ENDS


ssl_connection	STRUC

sc_section		section_typ <>
sc_rem_ip               DD ?
sc_rem_port             DW ?
sc_my_port              DW ?
sc_socket_handle        DW ?
sc_buffer_size		DW ?
sc_receive_buffer	DW ?
sc_receive_count	DW ?
sc_receive_head		DW ?
sc_receive_tail		DW ?
sc_send_buffer		DW ?
sc_send_count		DW ?
sc_send_pend            DW ?
sc_send_head		DW ?
sc_send_tail		DW ?

sc_server               DW ?
sc_wait_conn            DW ?
sc_wait_rec             DW ?
sc_active               DB ?
sc_closed               DB ?

ssl_connection	ENDS

ssl_listen   STRUC

sl_section		section_typ <>
sl_port                 DW ?
sl_max_connections      DW ?
sl_wait                 DW ?
sl_pend_count           DW ?

sl_pend_mask            DD ?

ssl_listen   ENDS
