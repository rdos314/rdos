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
; SMP.INC
; SMP protocol common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SOM		EQU 1
EOM		EQU 2
REQ		EQU 4
RPY		EQU 8
NAM		EQU 10h

ACK_DELAY = 1000

ACTION_RESET		EQU 1
ACTION_ACK			EQU 2
ACTION_TOO_LARGE	EQU 3
ACTION_BUSY			EQU 4

smp_header	STRUC

sh_connection	DD ?
sh_offset_size	DD ?
sh_mailslot		DW ?
sh_size			DW ?
sh_flags		DB ?
sh_responses	DB ?
sh_checksum		DW ?

smp_header	ENDS

smp_response	STRUC

sr_connection	DD ?
sr_mailslot		DW ?
sr_size			DB ?
sr_action		DB ?

smp_response	ENDS

HOST_SIGN EQU 56A753BCh

smp_host_data	STRUC

shd_link			DW ?
shd_id				DW ?
shd_section			section_typ <>
shd_sign			DD ?
shd_ip				DD ?
shd_response_time	DD ?,?
shd_mailslot_list	DW ?
shd_response_list	DW ?
shd_perform_list	DW ?
shd_host			DW ?

smp_host_data	ENDS
