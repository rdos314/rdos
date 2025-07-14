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
; IPC.INC
; IPC common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
