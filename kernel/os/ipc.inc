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
; IPC.INC
; IPC common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ipc_data	SEGMENT AT 0

ipc_section			section_typ <>
ipc_mailslot_list	DW ?
ipc_cache_offset	DW ?
smp_thread			DW ?
smp_host_section	section_typ <>
smp_host_list		DW ?
super_response_list	DW ?
super_host_list		DW ?
super_mailslot_list	DW ?

ipc_data	ENDS

ipc_thread_data	SEGMENT AT 0

ipc_mailslot_sel	DW ?

ipc_thread_data	ENDS

mailslot_data	STRUC

m_link				DW ?
m_section			section_typ <>
m_usage				DW ?
m_send_callb		DW ?

mailslot_data	ENDS

ipc_mailslot_data	STRUC

m_common			mailslot_data <>
m_current			DW ?
m_rec_callb			DW ?
m_rec_max_size		DD ?
m_rec_base			DD ?
m_rec_size			DD ?
m_rec_glob_base		DD ?
m_rec_glob_size		DD ?
m_rec_glob_sel		DW ?
m_rec_thread		DW ?
m_send_max_size		DD ?
m_send_base			DD ?
m_send_size			DD ?
m_send_glob_base	DD ?
m_send_glob_size	DD ?
m_send_glob_sel		DW ?
m_send_thread		DW ?
m_reply_callb		DW ?
m_req_list			DW ?
m_host_section		section_typ <>
m_host_list			DW ?
m_name				DB ?

ipc_mailslot_data	ENDS

mailslot_list_data	STRUC

ml_prev				DW ?
ml_next				DW ?
ml_rec_callb		DW ?
ml_reply_callb		DW ?

mailslot_list_data	ENDS
