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
