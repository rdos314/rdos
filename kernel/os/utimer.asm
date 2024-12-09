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
;           NAME:           CREATE_TIMER_THREAD
;
;           DESCRIPTION:    Create timer thread
;
;           PARAMETERS:     EBX         Passed to thread
;                           EDX         Passed to thread
;                           ES:EDI      Startup of thread
;
;           RETURNS:        NC          Thread started
;                           CY          Thread already running
;                           EAX         Timer object address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_timer_thread_name DB 'Create Timer Thread',0

;    AL              Priority
;                           AH              Mode, 0=PM, 1=VM, 2=long
;                           
;     ECX             Stack size
;                           DS:(E)SI    Start address
;                           ES:(E)DI    Thread name
    
create_timer_thread   Proc far
    push ds
    push fs
    push esi
    int 3
;
    GetThread
    mov ds,eax
    mov fs,ds:p_prog_sel
    mov ds,ds:p_proc_sel
    mov esi,ds:pf_timer_linear
    mov eax,flat_data_sel
    mov ds,eax
    mov al,1
    xchg al,ds:[esi].us_started
    or al,al
    stc
    jnz cttDone
;
    push es
    push esi
    push edi
;
    mov eax,50
    AllocateSmallGlobalMem
;
    push edi
    mov fs,fs:pr_name_sel
    xor esi,esi
    xor edi,edi
    mov ecx,32

cttNameLoop:
    lods byte ptr fs:[esi]
    or al,al
    jz cttNamePad
;
    stosb
    loop cttNameLoop

cttNamePad:
    cmp ecx,1
    jne cttNameTerm
;
    dec edi

cttNameTerm:
    mov al,'@'
    stosb

cttNameDone:
    xor al,al
    stosb
;
    pop esi
;
    mov ax,3
    xor edi,edi
    mov ecx,4000h
    CreateThread
;
    pop edi
    pop esi
    pop es
    clc

cttDone:
    mov eax,esi
;
    pop esi
    pop fs
    pop ds
    ret
create_timer_thread   Endp

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
    mov esi,OFFSET create_timer_thread
    mov edi,OFFSET create_timer_thread_name
    xor dx,dx
    mov ax,create_timer_thread_nr
    RegisterBimodalUserGate
    ret
InitTimer_    Endp

_TEXT    ENDS

    END
