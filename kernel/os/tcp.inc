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
FLAG_DELETE			EQU 40h
FLAG_DELAY_ACK		EQU 80h
FLAG_RESENT			EQU 100h
FLAG_CLOSED			EQU 200h

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
tcp_listen_thread		DW ?

tcp_listen	ENDS

tcp_connection	STRUC

tcp_section			section_typ <>
tcp_next			DW ?
tcp_listen_link		DW ?
tcp_owner			DW ?
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
tcp_rto				DD ?
tcp_rts				DD ?
tcp_rtm				DD ?
tcp_fin_seq			DD ?
tcp_time_val		DD ?
tcp_time_seq		DD ?
tcp_delete_ok		DB ?
tcp_ack_timeout		DB ?
tcp_push_timeout	DB ?
tcp_user_timeout	DW ?
tcp_resend_timeout	DW ?
tcp_zero_timeout	DW ?
tcp_options			DB ?

tcp_connection	ENDS

tcp_data	STRUC

ListSection			section_typ <>
Handle				DW ?
ConnectionList		DW ?
ListenList			DW ?
TcpThread			DW ?
LastPort			DW ?
PortMap				DB 1F00h DUP(?)

tcp_data	ENDS

