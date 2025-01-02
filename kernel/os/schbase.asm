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

state_hooks         DW ?
state_arr           DD 2*32 DUP(?)

data    ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn IdToHandle:near
    extrn IndexToHandle:near
    extrn MoveThread:near
    extrn ImplMoveToNewCore:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetThreadCount
;
;           DESCRIPTION:    Get thread count
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn GetActiveThreads:near

get_thread_count_name DB 'Get Thread Count',0

get_thread_count    Proc far
    call GetActiveThreads
    ret
get_thread_count    Endp

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
;           NAME:           DEFAULT_STATE
;
;           DESCRIPTION:    Default (unknown) state
;
;           PARAMETERS:         BX      Thread selector
;               ES:EDI      Buffer
;
;       RETURNS:        NC          processed
;               CX:EDX      List
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unknown_state   DB 'Unknown State',0

default_state   Proc far
    push ds
    push eax
    push esi
;    
    mov esi,OFFSET unknown_state

default_copy:
    mov al,cs:[esi]
    or al,al
    jz default_copy_done
;
    inc esi
    stos byte ptr es:[edi]
    jmp default_copy

default_copy_done:
    xor al,al
    stos byte ptr es:[edi]
;
    mov ds,ebx
    mov cx,ds:p_cs
    mov edx,dword ptr ds:p_rip
    clc
;
    pop esi
    pop eax
    pop ds
    ret
default_state   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_STATE
;
;           DESCRIPTION:    Add a state hook
;
;           PARAMETERS:     ES:EDI       Callback
;
;           CALLED WITH:        BX      Thread selector
;                               ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_state_name DB 'Hook State',0

hook_state      Proc far
    push ds
    push ebx
;    
    mov bx,SEG data
    mov ds,ebx
    movzx ebx,ds:state_hooks
    shl ebx,3
    mov ds:[ebx].state_arr,edi
    mov ds:[ebx+4].state_arr,es
    inc ds:state_hooks
;
    pop ebx
    pop ds
    ret
hook_state      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ThreadToSel
;
;           DESCRIPTION:    Convert thread # (p_id) to selector
;
;           PARAMETERS:     BX      Thread #
;
;       RETURNS:    BX      Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

thread_to_sel_name DB 'Thread To Sel',0

thread_to_sel   Proc far
    push eax
    push ecx
    push edx
    push esi
    push edi
;    
    movzx eax,bx
    call IdToHandle
    or eax,eax
    stc
    jz thread_to_sel_done
;
    mov bx,ax
    clc

thread_to_sel_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax    
    ret
thread_to_sel   Endp

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
;           NAME:           GetThreadState
;
;           DESCRIPTION:    Get state of a thread
;
;           PARAMETERS:         ES:(E)DI        BUFFER TO PUT STATE IN
;                           AX                  THREAD #
;                           NC                  THREAD EXISTS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_state_name DB 'Get Thread State',0

get_thread_state    Proc near
    push ds
    pushad
;    
    movzx eax,ax
    call IndexToHandle
    or eax,eax
    stc
    jz get_state_done
;    
    mov ds,ax
    mov ax,ds:p_id
    mov es:[edi].st_id,ax
    mov esi,OFFSET thread_name
    mov ecx,32
    push edi
    add edi,OFFSET st_name
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
;       
    mov eax,ds:p_msb_tics
    mov es:[edi].st_time,eax
    mov eax,ds:p_lsb_tics
    mov es:[edi].st_time+4,eax
;
    push edi
    add edi,OFFSET st_list
    mov bx,ds
;    
    mov ax,SEG data
    mov ds,ax
    mov esi,OFFSET state_arr
    
get_state_loop:
    call fword ptr [esi]
    jnc get_state_found
;
    add esi,8
    jmp get_state_loop

get_state_found:
    pop edi
;
    mov es:[edi].st_sel,cx
    mov es:[edi].st_offs,edx
    clc

get_state_done:
    popad
    pop ds
    ret
get_thread_state    Endp

get_thread_state16      Proc far
    push edi
    movzx edi,di
    call get_thread_state
    pop edi
    ret
get_thread_state16      Endp

get_thread_state32      Proc far
    call get_thread_state
    ret
get_thread_state32      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ReadFlatAppDword
;
;   DESCRIPTION:    Read flat app dword
;
;   PARAMETERS:     DS  Thread
;                   ESI Offset
;
;   RETURNS:        NC
;                       EAX Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadFlatAppDword    Proc near
    push ebx
    push ecx
    push edx
    push esi
;
    add esi,3
    xor ecx,ecx
    mov edx,flat_data_sel
    mov bx,ds
    ReadThreadSelector
    jc rfadDone
;
    dec esi
    mov cl,al
    ReadThreadSelector
    jc rfadDone
;
    shl ecx,8
    mov cl,al
;
    dec esi
    mov cl,al
    ReadThreadSelector
    jc rfadDone
;
    shl ecx,8
    mov cl,al
;
    dec esi
    mov cl,al
    ReadThreadSelector
    jc rfadDone
;
    shl ecx,8
    mov cl,al
    mov eax,ecx
    clc

rfadDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ReadFlatAppDword    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ProbeFlatAppCode
;
;   DESCRIPTION:    Proble flat app code
;
;   PARAMETERS:     DS  Thread
;                   ESI Offset
;
;   RETURNS:        NC   OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProbeFlatAppCode    Proc near
    push eax
    push ebx
    push edx
;
    mov edx,flat_data_sel
    mov bx,ds
    ReadThreadSelector
    jc pfacDone
;    
    GetThreadSelectorPage
    jc pfacDone
;
    test al,2
    jz pfacDone
;
    stc

pfacDone:
    pop edx
    pop ebx
    pop eax
    ret
ProbeFlatAppCode    Endp

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
;           NAME:           GetThreadActionState
;
;           DESCRIPTION:    Get action state of a thread
;
;           PARAMETERS:     ES:(E)DI        BUFFER TO PUT STATE IN
;                           AX                  THREAD #
;                           NC                  THREAD EXISTS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_action_state_name DB 'Get Thread Action State',0

get_thread_action_state    Proc near
    push ds
    push fs
    pushad
;    
    movzx eax,ax
    call IndexToHandle
    or eax,eax
    stc
    jz get_action_state_done
;    
    mov ds,ax
    mov ax,ds:p_id
    mov es:[edi].ast_id,ax
    mov esi,OFFSET thread_name
    mov ecx,32
    push edi
    add edi,OFFSET ast_name
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
;    
    mov esi,OFFSET p_action_text
    mov ecx,32
    push edi
    add edi,OFFSET ast_action
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
;       
    mov eax,ds:p_msb_tics
    mov es:[edi].ast_time,eax
    mov eax,ds:p_lsb_tics
    mov es:[edi].ast_time+4,eax
;
    push edi
    add edi,OFFSET ast_list
    mov bx,ds
;    
    mov ax,SEG data
    mov ds,ax
    mov esi,OFFSET state_arr
    
get_action_state_loop:
    call fword ptr [esi]
    jnc get_action_state_found
;
    add esi,8
    jmp get_action_state_loop

get_action_state_found:
    pop edi
;
    mov es:[edi].ast_pos.sep_sel,cx
    mov dword ptr es:[edi].ast_pos.sep_offs,edx
    mov dword ptr es:[edi].ast_pos.sep_offs+4,0
    mov es:[edi].ast_count,0
;
    mov ds,ebx
    test word ptr ds:p_rflags+2,2
    jnz get_action_user_done
;
    mov ax,ds:p_cs
    cmp ax,flat_code_sel
    je get_action_app
;
    cmp ax,serv_code_sel
    jne get_action_not_app

get_action_app:   
    mov edx,edi
    add edx,OFFSET ast_user
    mov eax,dword ptr ds:p_rbp    
    jmp get_action_user_loop

get_action_not_app:    
    test ax,7
    jnz get_action_user_done
;
    mov ax,ds:p_ss
    mov fs,ax
    mov ecx,dword ptr ds:p_rsp
    cmp ecx,stack0_size
    jae get_action_user_done
;
    mov ecx,stack0_size
    mov eax,fs:[ecx-4]
    cmp eax,flat_data_sel    
    je get_action_user_cs
;
    cmp eax,serv_data_sel
    jne get_action_user_done

get_action_user_cs:    
    mov eax,fs:[ecx-12]
    cmp eax,flat_code_sel
    je get_action_user
;
    cmp eax,serv_code_sel
    jne get_action_user_done

get_action_user:
    mov edx,edi
    add edx,OFFSET ast_user
    mov eax,fs:[ecx-12]
    mov es:[edx].sep_sel,ax
    mov eax,fs:[ecx-16]
    mov dword ptr es:[edx].sep_offs,eax
    mov dword ptr es:[edx].sep_offs+4,0
    add edx,SIZE state_ep
    inc es:[edi].ast_count
;
    mov esi,fs:[ecx-8]
    call ReadFlatAppDword
    jc get_action_user_done

get_action_user_loop:
    mov esi,eax
    push esi
    add esi,24
    call ReadFlatAppDword
    pop esi
    jc get_action_user_done
;
    push esi
    mov esi,eax
    call ProbeFlatAppCode
    pop esi
    jnc get_action_user_save
;    
    push esi
    add esi,20
    call ReadFlatAppDword
    pop esi
    jc get_action_user_done
;
    push esi
    mov esi,eax
    call ProbeFlatAppCode
    pop esi
    jnc get_action_user_save
;
    xor eax,eax
    
get_action_user_save:    
    mov es:[edx].sep_sel,flat_code_sel
    mov dword ptr es:[edx].sep_offs,eax
    mov dword ptr es:[edx].sep_offs+4,0
    add edx,SIZE state_ep
    mov ax,es:[edi].ast_count
    inc ax
    mov es:[edi].ast_count,ax
    cmp ax,64
    jae get_action_user_done
;
    call ReadFlatAppDword
    or eax,eax
    jnz get_action_user_loop
        
get_action_user_done:    
    mov ax,es:[edi].ast_count
    cmp ax,2
    jb get_action_user_ok
;
    sub edx,SIZE state_ep
    mov eax,dword ptr es:[edx].sep_offs
    or eax,dword ptr es:[edx].sep_offs+4
    jnz get_action_user_ok
;
    dec es:[edi].ast_count        

get_action_user_ok:    
    clc

get_action_state_done:
    popad
    pop fs
    pop ds
    ret
get_thread_action_state    Endp

get_thread_action_state16      Proc far
    push edi
    movzx edi,di
    call get_thread_action_state
    pop edi
    ret
get_thread_action_state16      Endp

get_thread_action_state32      Proc far
    call get_thread_action_state
    ret
get_thread_action_state32      Endp

    
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
    GetPciMsiInfo
    jc gpmbFail
;
    movzx eax,al
    jmp gpmbDone

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
    GetCoreNumber
    mov al,dl
    MovePciMsi
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
    mov bx,SEG data
    mov es,ebx
    mov es:state_hooks,0
;
    mov ecx,32
    mov edi,OFFSET state_arr
    
init_state_hooks:
    mov dword ptr es:[edi],OFFSET default_state
    mov es:[edi+4],cs
    add edi,8
    loop init_state_hooks
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
    mov esi,OFFSET hook_state
    mov edi,OFFSET hook_state_name
    xor cl,cl
    mov ax,hook_state_nr
    RegisterOsGate
;
    mov esi,OFFSET thread_to_sel
    mov edi,OFFSET thread_to_sel_name
    xor cl,cl
    mov ax,thread_to_sel_nr
    RegisterOsGate
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
    mov ebx,OFFSET get_thread_state16
    mov esi,OFFSET get_thread_state32
    mov edi,OFFSET get_thread_state_name
    mov dx,virt_es_in
    mov ax,get_thread_state_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_thread_action_state16
    mov esi,OFFSET get_thread_action_state32
    mov edi,OFFSET get_thread_action_state_name
    mov dx,virt_es_in
    mov ax,get_thread_action_state_nr
    RegisterUserGate
;
    mov esi,OFFSET get_thread_count
    mov edi,OFFSET get_thread_count_name
    xor dx,dx
    mov ax,get_thread_count_nr
    RegisterBimodalUserGate
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
