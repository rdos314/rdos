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
; ssl.inc
; SSL datatypes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_SSL_REQ_COUNT  = 16


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


ssl_connection	STRUC

sc_section		section_typ <>
sc_socket_handle        DW ?
sc_buffer_size		DW ?
sc_receive_buffer	DW ?
sc_receive_count	DW ?
sc_receive_head		DW ?
sc_receive_tail		DW ?
sc_send_buffer		DW ?
sc_send_count		DW ?
sc_send_head		DW ?
sc_send_tail		DW ?

sc_server               DW ?
sc_wait_conn            DW ?
sc_wait_rec             DW ?
sc_active               DB ?
sc_closed               DB ?

ssl_connection	ENDS
