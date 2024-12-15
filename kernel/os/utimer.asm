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
; UTIMER.ASM
; User timer support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE exec.def
INCLUDE system.inc
INCLUDE ..\fs.inc
INCLUDE ..\wait.inc
INCLUDE ..\debevent.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateUserTimer
;
;           DESCRIPTION:    Allocate user timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateUserTimer

AllocateUserTimer    Proc near
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov es,eax
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
;
    mov eax,kernel_timer_struc
    AllocateSmallGlobalMem
;
    mov es:kt_kernel_ptr,0
    mov es:kt_user_ptr,0
    InitSection es:kt_section
    mov es:kt_started,0
    mov es:kt_flags,0
    mov es:kt_kernel_head,0
    mov es:kt_user_head,0
;
    mov edi,OFFSET kt_kernel_list
    mov ecx,TIMER_ENTRIES
    xor ax,ax
    rep stosw
;
    mov edi,OFFSET kt_user_list
    mov ecx,TIMER_ENTRIES
    xor ax,ax
    rep stosw
    mov ds:pf_timer_sel,es
;
    popad
    pop es
    pop ds
    ret
AllocateUserTimer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeUserTimer
;
;           DESCRIPTION:    Free user timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeUserTimer

FreeUserTimer    Proc near
    push es
    push eax
    push ecx
    push edx
;
    GetThread
    mov es,eax
    mov es,es:p_proc_sel
    mov es,es:pf_timer_sel
;
    FreeMem
;
    pop edx
    pop ecx
    pop eax
    pop es
    ret
FreeUserTimer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateUserTimer
;
;       DESCRIPTION:    Allocate user timer
;
;       PARAMETERS:     DS      Kernel timer struc
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_user_timer_name  DB 'Init User Timer' ,0

init_user_timer   Proc far
    push es
    push eax
    push ecx
    push edi
;
    mov ax,flat_sel
    mov es,eax
;
    EnterSection ds:kt_section
    mov eax,ds:kt_user_ptr
    or eax,eax
    jnz iutLeave
;
    mov eax,3000h
    AllocateLocalLinear
;
    lea edi,[edx].ut_rw_active.uat_pending_map
    mov eax,0Fh
    stosd
;
    xor eax,eax
    mov ecx,7
    rep stosd
;
    lea edi,[edx].ut_rw_active.uat_completed_map
    mov ecx,8
    rep stosd
;
    lea edi,[edx].ut_rw_active.uat_entries
    mov ecx,4 * TIMER_ENTRIES
    rep stosd
;
    lea edi,[edx].ut_req.urt_req_map
    mov ecx,8
    rep stosd
;
    lea edi,[edx].ut_req.urt_done_map
    mov ecx,8
    rep stosd
;
    lea edi,[edx].ut_req.urt_entries
    mov ecx,4 * TIMER_ENTRIES
    rep stosd
;
    GetPageEntry
    and ax,0F000h
    or ax,863h
    SetPageEntry
;
    add edx,2000h
    and ax,0F000h
    or ax,865h
    SetPageEntry
    sub edx,2000h
;
    mov ax,system_data_sel
    mov es,eax
    sub edx,es:flat_base
;
    mov ds:kt_user_ptr,edx

iutLeave:
    LeaveSection ds:kt_section
;
    pop edi
    pop ecx
    pop eax
    pop es
    ret
init_user_timer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddReq
;
;       DESCRIPTION:    Add request
;
;       PARAMETERS:     DS      Kernel timer struc
;                       ES:ESI  User timer data
;                       EBX     Timer #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReq   Proc near
    ret
AddReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartReq
;
;       DESCRIPTION:    Start request
;
;       PARAMETERS:     DS      Kernel timer struc
;                       ES:EDX  User timer
;                       EBX     Timer #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartReq   Proc near
    pushad
;
    mov ecx,ebx
    shl ecx,4
    lea esi,[edx].ut_req
    lea edi,[edx].ut_rw_active
;
    GetSystemTime
    sub eax,es:[esi+ecx].ute_timeout
    sbb edx,es:[esi+ecx+4].ute_timeout
    jc srActive

srDone:
    bts es:[edi].uat_completed_map,ebx
    lock btc es:[esi].urt_req_map,ebx
;
    add esi,ecx
    add edi,ecx
    jmp srCopy

srActive:    
    bts es:[edi].uat_pending_map,ebx
    lock btc es:[esi].urt_req_map,ebx
;
    add esi,ecx
    add edi,ecx
    call AddReq

srCopy:
    mov ecx,4
    rep movs dword ptr es:[edi],es:[esi]
;
    popad
    ret
StartReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdateReq
;
;       DESCRIPTION:    Update requests
;
;       PARAMETERS:     DS      Kernel timer struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateReq   Proc near
    push es
    pushad
;
    mov ax,flat_data_sel
    mov es,eax
    mov edx,ds:kt_user_ptr
    lea esi,[edx].ut_req.urt_req_map
    mov ecx,8
    xor ebx,ebx

urLoop:
    lods dword ptr es:[esi]
    or eax,eax
    jz urNext
;
    push ecx
    mov ecx,32

urBitLoop:
    test al,1
    jz urBitNext
;
    call StartReq

urBitNext:
    shr eax,1
    inc ebx
    loop urBitLoop
;
    pop ecx
    jmp urNextSkip

urNext:
    add ebx,32

urNextSkip:
    loop urLoop
;
    popad
    pop es
    ret
UpdateReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitTimerEvent
;
;       DESCRIPTION:    Wait for timer event
;
;       RETURN VALUE:   NC          Has event
;                       CY          Terminate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_timer_event_name  DB 'Wait User Timer Event' ,0

wait_timer_event   Proc far
    push ds
    push eax
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_timer_sel

wteLoop:
    call UpdateReq
;
    pop eax
    pop ds
    ret
wait_timer_event   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTimer
;
;           DESCRIPTION:    init module
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitTimer_

InitTimer_    Proc near
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET init_user_timer
    mov edi,OFFSET init_user_timer_name
    mov ax,init_user_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET wait_timer_event
    mov edi,OFFSET wait_timer_event_name
    xor dx,dx
    mov ax,wait_timer_event_nr
    RegisterBimodalUserGate
    ret
InitTimer_    Endp

_TEXT    ENDS

    END
