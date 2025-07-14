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
; TCP.INC
; TCP protocol common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STATE_SYN_SENT		EQU 0
STATE_SYN_RCVD		EQU 1
STATE_ESTAB			EQU 2
STATE_FIN_WAIT1		EQU 3
STATE_FIN_WAIT2		EQU 4
STATE_CLOSE_WAIT	EQU 5
STATE_LAST_ACK		EQU 6
STATE_CLOSING		EQU 7
STATE_TIME_WAIT		EQU 8

FIN			EQU 1
SYN			EQU 2
RST			EQU 4
PSH			EQU 8
ACK			EQU 10h
URG			EQU 20h

FLAG_REC_FIN		EQU 1
FLAG_CLOSING		EQU 2
FLAG_SEND_PUSH		EQU 4
FLAG_WAIT			EQU 8
FLAG_REC_PUSH		EQU 10h
FLAG_ACK			EQU 20h
FLAG_DELAY_ACK		EQU 40h
FLAG_RESENT			EQU 80h
FLAG_CLOSED			EQU 100h
FLAG_DELETE_NET		EQU 200h
FLAG_DELETE_USER    EQU 400h
FLAG_UNLINKED       EQU 800h
FLAG_RETRY          EQU 1000h

REORDER_ENTRIES	EQU 8

reorder_entry	STRUC

reorder_seq		DD ?
reorder_size	DD ?

reorder_entry	ENDS

tcp_header	STRUC

tcp_source		DW ?
tcp_dest		DW ?
tcp_seq			DD ?
tcp_ack			DD ?
tcp_header_len	DB ?
tcp_flags		DB ?
tcp_window		DW ?
tcp_checksum	DW ?
tcp_urgent		DW ?

tcp_header	ENDS

tcp_listen	STRUC

tcp_listen_section		section_typ <>
tcp_listen_next			DW ?
tcp_listen_port			DW ?
tcp_listen_buffer_size	DD ?
tcp_listen_list			DW ?
tcp_listen_wait 		DW ?
tcp_listen_max_conn     DW ?
tcp_listen_conn_count   DW ?

tcp_listen	ENDS

tcp_connection	STRUC

tcp_section			section_typ <>
tcp_next			DW ?
tcp_listen_link		DW ?
tcp_owner			DW ?
tcp_writer          DW ?
tcp_signal_change   DW ?
tcp_wait            DW ?
tcp_read_wait       DW ?
tcp_write_wait      DW ?
tcp_exc_wait        DW ?
tcp_port			DW ?
tcp_remote_ip		DD ?
tcp_remote_port		DW ?
tcp_checksum_base	DW ?
tcp_timeout			DD ?
tcp_buffer_size		DW ?
tcp_receive_buffer	DW ?
tcp_receive_count	DW ?
tcp_receive_head	DW ?
tcp_receive_tail	DW ?
tcp_send_buffer		DW ?
tcp_send_count		DW ?
tcp_send_head		DW ?
tcp_send_tail		DW ?
tcp_id				DW ?
tcp_iss				DD ?
tcp_state			DB ?
tcp_has_time            DB ?
tcp_send_una		DD ?
tcp_send_next		DD ?
tcp_send_wnd		DW ?
tcp_send_max_wnd	DW ?
tcp_send_wl1		DD ?
tcp_send_wl2		DD ?
tcp_rcv_wnd			DW ?
tcp_rcv_next		DD ?
tcp_reorder_count	DW ?
tcp_reorder_arr		DD 2 * REORDER_ENTRIES DUP(?)
tcp_mtu				DW ?
tcp_cwnd			DD ?
tcp_ssthresh		DD ?
tcp_dup_acks		DW ?
tcp_pending			DW ?
tcp_rtt             DD ?
tcp_rto				DD ?
tcp_rts				DD ?
tcp_rtm				DD ?
tcp_fin_seq			DD ?
tcp_time_val		DD ?
tcp_time_seq		DD ?
tcp_retries         DW ?
tcp_ack_timeout		DB ?
tcp_push_timeout	DB ?
tcp_user_timeout	DW ?
tcp_resend_timeout	DW ?
tcp_syn_timeout     DW ?
tcp_zero_timeout	DW ?
tcp_send_timeout    DW ?
tcp_delete_timeout  DW ?
tcp_resend_count        DB ?
tcp_options			DB ?

tcp_connection	ENDS

tcp_socket_sel	STRUC

tcp_conn_handle		DW ?

tcp_socket_sel  ENDS
