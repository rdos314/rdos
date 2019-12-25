;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2019, Leif Ekblad
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
; realtime.inc
; Realtime 64-bit application API
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

realtime_local_apic        = 0000001F000000000h
realtime_local_data        = 0000001F000002000h

RDS_NOTIFY_FLAG_SIGNAL = 10h

realtime_data_struc     STRUC

rds_notify_flags       DD ?
rds_apic               DD ?

rds_phys_page          DQ ?
rds_linear_page        DQ ?

rds_wait_thread        DW ?
rds_pad                DW ?

rds_signal_bitmap      DD 32 DUP(?) 

realtime_data_struc     ENDS

;  IN  CX	Signal # (0..1023)
RealtimeSignal	Macro
    local rsDone

    push rbx
    push rcx
    push rdx
;
    mov rbx,realtime_local_data
    lock bts word ptr [rbx].rds_signal_bitmap,cx
    jc rsDone
;
    lock or [ebx].rds_notify_flags,RDS_NOTIFY_FLAG_SIGNAL
    mov edx,[rbx].rds_apic
    shl edx,24
;
    mov rbx,realtime_local_apic
    mov ecx,[rbx+300h]
    test cx,1000h
    jnz rsDone
;
    mov ecx,4085h
    mov [rbx+310h],edx
    mov [rbx+300h],ecx

rsDone:
    pop rdx
    pop rcx
    pop rbx
                Endm
