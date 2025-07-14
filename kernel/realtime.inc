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
    lock or [rbx].rds_notify_flags,RDS_NOTIFY_FLAG_SIGNAL
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
