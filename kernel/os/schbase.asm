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
; SCHBASE.ASM
; Scheduler support functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE state.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE core.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE exec.def

    .686p

data    SEGMENT byte public 'DATA'

locked_irq_bitmap   DB 32 DUP(?)

data    ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn IdToHandle:near
    extrn MoveThread:near
    extrn ImplMoveToNewCore:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreatePid
;
;           DESCRIPTION:    Create new PID for thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn CreateTid:near

create_pid_name DB 'Create PID',0

create_pid    Proc far
    call CreateTid
    ret
create_pid    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateThread
;
;           DESCRIPTION:    Create thread callback
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn ThreadCreated:near

create_thread    Proc far
    push es
    pushad
;    
    GetThread
    movzx eax,ax
    mov es,eax
    movzx edx,es:p_id
    movzx ecx,es:p_prio
    call ThreadCreated
;
    popad
    pop es    
    ret
create_thread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TerminateThread
;
;           DESCRIPTION:    Terminate thread callback
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn ThreadTerminated:near

terminate_thread    Proc far
    pushad
;    
    GetThread
    movzx eax,ax
    mov es,eax
    call ThreadTerminated
;
    popad
    ret
terminate_thread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetThreadIrq
;
;           DESCRIPTION:    Set thread IRQ
;
;           PARAMETERS:     AL                  IRQ
;                           ES                  Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn ImplSetThreadIrq:near

set_thread_irq_name DB 'Get Thread Count',0

set_thread_irq    Proc far
    push eax
    push ebx
;
    movzx eax,al
    movzx ebx,es:p_id
    call ImplSetThreadIrq
;
    pop ebx
    pop eax
    ret
set_thread_irq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCurrentThread
;
;           DESCRIPTION:    Get current thread handle
;
;           RETURNS:        EAX         Thread handle         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetCurrentThread_

GetCurrentThread_    Proc near
    push es
;    
    GetThread
    mov es,eax
    movzx eax,es:p_id
;
    pop es
    ret
GetCurrentThread_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetThreadHandle
;
;           DESCRIPTION:    Get current thread handle
;
;           RETURNS:        EAX         Thread handle         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_handle_name  DB 'Get Thread Handle', 0

get_thread_handle    Proc far
    push es
;    
    GetThread
    mov es,eax
    movzx eax,es:p_id
;
    pop es
    ret
get_thread_handle       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SuspendThread
;
;           DESCRIPTION:    Suspend thread (put it in debugger)
;
;           PARAMETER:          AX          Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

suspend_thread_name     DB 'Suspend Thread',0

suspend_thread  PROC far
    push ds
    push es
    pushad
;
    movzx eax,ax
    call IdToHandle
    or eax,eax
    stc
    jz suspend_thread_done
;    
    mov es,ax
    or es:p_flags,THREAD_FLAG_SUSPEND
    clc

suspend_thread_done:
    popad
    pop es
    pop ds
    ret
suspend_thread  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SuspendAndSignalThread
;
;           DESCRIPTION:    Suspend and signal thread (put it in debugger)
;
;           PARAMETER:          AX          Thread #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

suspend_and_signal_thread_name  DB 'Suspend and Signal Thread',0

suspend_and_signal_thread       PROC far
    push ds
    push es
    pushad
;
    movzx eax,ax
    call IdToHandle
    or eax,eax
    stc
    jz suspend_signal_done
;
    mov bx,ax
    mov es,ax
    or es:p_flags,THREAD_FLAG_SUSPEND
    Signal
    clc

suspend_signal_done:
    popad
    pop es
    pop ds
    ret
suspend_and_signal_thread       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MoveToCore
;
;           DESCRIPTION:    Move current thread to another core
;
;           PARAMETER:      AX          Core #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_to_core_name  DB 'Move To Core',0

move_to_core PROC far
    push es
    push eax
    push ebx
;
    movzx eax,ax
    push eax
    GetThread
    mov es,eax
    movzx ebx,es:p_id
    pop eax
    call MoveThread
;
    pop ebx
    pop eax
    pop es
    ret
move_to_core ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MoveThreadToCore
;
;           DESCRIPTION:    Move thread to new core
;
;           PARAMETER:      AX          Core #
;                           BX          Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_thread_to_core_name  DB 'Move Thread To Core',0

move_thread_to_core PROC far
    push eax
    push ebx
;
    movzx eax,ax
    movzx ebx,bx    
    call MoveThread
;
    pop ebx
    pop eax    
    ret
move_thread_to_core ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MoveToNewCore
;
;           DESCRIPTION:    Move current thread to new core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_to_new_core_name  DB 'Move To New Core',0

move_to_new_core PROC far
    call ImplMoveToNewCore
    ret
move_to_new_core ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetThreadCore
;
;           DESCRIPTION:    Set new core for thread
;
;           PARAMETER:      AX          Core #
;                           DX          Thread handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetThreadCore_
    
SetThreadCore_ PROC near
    push es
    mov es,dx
    SetThreadCore
    pop es
    ret
SetThreadCore_ ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetThreadTics
;
;           DESCRIPTION:    Get thread tics
;
;           PARAMETER:      AX          Thread handle
;
;           RETURNS:        EDX:EAX     Tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetThreadTics_
    
GetThreadTics_ PROC near
    push es
    mov es,ax
    mov edx,es:p_msb_tics
    mov eax,es:p_lsb_tics    
    pop es
    ret
GetThreadTics_ ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearThreadIrqs
;
;           DESCRIPTION:    Clear thread IRQs
;
;           PARAMETER:      AX          Thread handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ClearThreadIrqs_
    
ClearThreadIrqs_ PROC near
    push es
    push ecx
    push edi
;
    mov es,ax
    mov edi,OFFSET p_irq_bitmap
    mov ecx,8
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop edi
    pop ecx
    pop es
    ret
ClearThreadIrqs_ ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasThreadIrq
;
;           DESCRIPTION:    Has thread any IRQ?
;
;           PARAMETER:      AX          Thread handle
;
;           RETURNS:        EAX         0 = no IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HasThreadIrq_
    
HasThreadIrq_ PROC near
    push ds
    push edx
    push esi
;
    mov ds,ax
    mov esi,OFFSET p_irq_bitmap
    xor edx,edx
    lods dword ptr ds:[esi]
    or edx,eax
    lods dword ptr ds:[esi]
    or edx,eax
    lods dword ptr ds:[esi]
    or edx,eax
    lods dword ptr ds:[esi]
    or edx,eax
    lods dword ptr ds:[esi]
    or edx,eax
    lods dword ptr ds:[esi]
    or edx,eax
    lods dword ptr ds:[esi]
    or edx,eax
    lods dword ptr ds:[esi]
    or eax,edx
;
    pop esi
    pop edx
    pop ds
    ret
HasThreadIrq_ ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LockThreadIrq
;
;           DESCRIPTION:    Lock thread IRQ
;
;           PARAMETER:      AX          Thread handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LockThreadIrq_
    
LockThreadIrq_ PROC near
    push ds
    push es
    push ecx
    push esi
    push edi
;
    mov ds,eax
    mov esi,OFFSET p_irq_bitmap
;
    mov eax,SEG data
    mov es,eax
    mov edi,OFFSET locked_irq_bitmap
;
    mov ecx,8

ltiLoop:
    xor eax,eax
    xchg eax,ds:[esi]
    add esi,4
    stos dword ptr es:[edi]
    loop ltiLoop
;
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    ret
LockThreadIrq_ ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetThreadIrq
;
;           DESCRIPTION:    Get thread IRQ
;
;           RETURNS:        EAX         IRQ # or -1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetThreadIrq_
    
GetThreadIrq_ PROC near
    push ecx
    push edx
    push esi
;
    mov ecx,8
    xor edx,edx
    mov esi,OFFSET locked_irq_bitmap

gtiLoop:
    mov eax,ds:[esi]
    or eax,eax
    jz gtiNext
;
    bsf ecx,eax
    btr eax,ecx
    mov ds:[esi],eax
;
    mov eax,ecx
    add eax,edx
    jmp gtiDone

gtiNext:
    add edx,32
    add esi,4
    loop gtiLoop
;
    mov eax,-1

gtiDone:
    pop esi
    pop edx
    pop ecx
    ret
GetThreadIrq_	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetThreadIrq
;
;           DESCRIPTION:    Set thread IRQ
;
;           PARAMETER:      AX          Thread handle
;                           DL          IRQ #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetThreadIrq_
    
SetThreadIrq_ PROC near
    push ds
    mov ds,eax
    mov ds:p_irq,dl
    pop ds
    ret
SetThreadIrq_	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCoreInts
;
;           DESCRIPTION:    Get int count (per core)
;
;           PARAMETER:      AX          Core #
;                           DL          IRQ #
;
;           RETURNS:        EAX		Int count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetCoreInts_
    
GetCoreInts_ PROC near
    push fs
    push ebx
;
    GetCoreNumber
    movzx ebx,dl
    shl ebx,2
    xor eax,eax
    xchg eax,fs:[ebx].cs_irq_arr_counter
;
    pop ebx
    pop fs
    ret
GetCoreInts_	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetPciMsiBase
;
;           DESCRIPTION:    Get PCI MSI info
;
;           PARAMETER:      AL          IRQ #
;
;           RETURNS:        EAX		Base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetPciMsiBase_
    
GetPciMsiBase_ PROC near
    push edx
;
;    GetPciMsiInfo
;    jc gpmbFail
;
;    movzx eax,al
;    jmp gpmbDone

gpmbFail:
    xor eax,eax

gpmbDone:
    pop edx
    ret
GetPciMsiBase_	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MovePciMsi
;
;           DESCRIPTION:    Move PCI MSI
;
;           PARAMETER:      AX          Core #
;                           DL          IRQ #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public MovePciMsi_
    
MovePciMsi_ PROC near
    push fs
    push eax
;
;    GetCoreNumber
;    mov al,dl
;    MovePciMsi
;
    pop eax
    pop fs
    ret
MovePciMsi_	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitScheduler
;
;           DESCRIPTION:    Initialize scheduler
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitScheduler_

InitScheduler_    Proc near
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET create_thread
    HookCreateThread
;
    mov edi,OFFSET terminate_thread
    HookTerminateThread
;
    mov esi,OFFSET create_pid
    mov edi,OFFSET create_pid_name
    xor cl,cl
    mov ax,create_pid_nr
    RegisterOsGate
;
    mov esi,OFFSET set_thread_irq
    mov edi,OFFSET set_thread_irq_name
    xor cl,cl
    mov ax,set_thread_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET get_thread_handle
    mov edi,OFFSET get_thread_handle_name
    xor dx,dx
    mov ax,get_thread_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET suspend_thread
    mov edi,OFFSET suspend_thread_name
    xor dx,dx
    mov ax,suspend_thread_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET suspend_and_signal_thread
    mov edi,OFFSET suspend_and_signal_thread_name
    xor dx,dx
    mov ax,suspend_and_signal_thread_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET move_to_core
    mov edi,OFFSET move_to_core_name
    xor dx,dx
    mov ax,move_to_core_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET move_thread_to_core
    mov edi,OFFSET move_thread_to_core_name
    xor dx,dx
    mov ax,move_thread_to_core_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET move_to_new_core
    mov edi,OFFSET move_to_new_core_name
    xor dx,dx
    mov ax,move_to_new_core_nr
    RegisterBimodalUserGate
;
    popad
    pop es
    pop ds
    ret
InitScheduler_    Endp

_TEXT    ENDS

    END
