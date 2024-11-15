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
    mov eax,2000h
    AllocateLocalLinear
;
    mov edi,edx
    mov ecx,800h
    xor eax,eax
    rep stosd
;
    add edx,1000h
    GetPageEntry
    and ax,0F000h
    or ax,865h
    SetPageEntry
    sub edx,1000h
;
    mov cx,system_data_sel
    mov es,ecx
    sub edx,es:flat_base
    mov ds:pf_timer_linear,edx
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    and ax,0F000h
    or ax,63h
    SetPageEntry
;
    push ds
    AllocateLdt
    pop ds
;
    or bx,4
    mov ecx,1000h
    CreateDataSelector32
    mov ds:pf_active_timer_sel,bx
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
;
    mov edx,es:pf_timer_linear
    mov ecx,2000h
    FreeLinear
;
    mov es,es:pf_active_timer_sel
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
;           NAME:           InitUserTimer
;
;           DESCRIPTION:    Init user timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_user_timer_name DB 'Init User Timer',0
    
init_user_timer   Proc far
    int 3
    ret
init_user_timer   Endp

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
;
    mov esi,OFFSET init_user_timer
    mov edi,OFFSET init_user_timer_name
    xor dx,dx
    mov ax,init_user_timer_nr
    RegisterBimodalUserGate
    ret
InitTimer_    Endp

_TEXT    ENDS

    END
