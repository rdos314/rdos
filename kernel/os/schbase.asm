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
INCLUDE proc.inc
INCLUDE module.def
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE exec.def
INCLUDE chandle.inc

    .686p

module_handle_seg           STRUC

mh_base handle_header <>

mh_sel        DW ?

module_handle_seg           ENDS

debug_event_wait_header STRUC

dew_obj         wait_obj_header <>
dew_module_sel         DW ?

debug_event_wait_header ENDS

data    SEGMENT byte public 'DATA'

next_pid            DW ?
state_hooks         DW ?
load_exe_hooks      DW ?
state_arr           DD 2*32 DUP(?)
load_exe_arr        DD 2*16 DUP(?)

data    ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn IdToHandle:near
    extrn IndexToHandle:near
    extrn MoveThread:near

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
    jne get_action_not_app
;   
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
    jne get_action_user_done
;    
    mov eax,fs:[ecx-12]
    cmp eax,flat_code_sel
    jne get_action_user_done
;
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
;           DESCRIPTION:    Move current thread to new core
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
;           NAME:           GetThreadIntCount
;
;           DESCRIPTION:    Get thread int count 
;
;           PARAMETER:      AX          Thread handle
;
;           RETURNS:        EAX         Int count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetThreadIntCount_
    
GetThreadIntCount_ PROC near
    push es
    mov es,ax
    movzx eax,es:p_int_count
    pop es
    ret
GetThreadIntCount_ ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AppNotifyCreate
;
;           DESCRIPTION:    Notify app create process
;
;           PARAMETERS:     ES  App sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_notify_create_name      DB 'App Notify Create',0

app_notify_create   PROC far
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_activity_sel
    mov gs,cx
    mov cl,gs:app_activity_hooks
    or cl,cl
    je app_notify_create_done
;
    mov bx,OFFSET app_activity_arr

app_notify_create_loop:
    push gs
    lgs edi,gs:[bx]
    call fword ptr gs:[edi].aa_create_proc
    pop gs
    add bx,8
    dec cl
    jnz app_notify_create_loop

app_notify_create_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    ret
app_notify_create   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AppNotifyStart
;
;           DESCRIPTION:    Notify start boot program
;
;           PARAMETERS:     ES  App sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_notify_start_name      DB 'App Notify Start',0

app_notify_start   PROC far
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_activity_sel
    mov gs,cx
    mov cl,gs:app_activity_hooks
    or cl,cl
    je app_notify_start_done
;
    mov bx,OFFSET app_activity_arr

app_notify_start_loop:
    push gs
    lgs edi,gs:[bx]
    call fword ptr gs:[edi].aa_start_proc
    pop gs
    add bx,8
    dec cl
    jnz app_notify_start_loop

app_notify_start_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    ret
app_notify_start   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AppNotifyForked
;
;           DESCRIPTION:    Notify forked
;
;           PARAMETERS:     ES  App sel
;                           DS  Source sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_notify_forked_name      DB 'App Notify Forked',0

app_notify_forked   PROC far
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_activity_sel
    mov gs,cx
    mov cl,gs:app_activity_hooks
    or cl,cl
    je app_notify_forked_done
;
    mov bx,OFFSET app_activity_arr

app_notify_forked_loop:
    push gs
    lgs edi,gs:[bx]
    call fword ptr gs:[edi].aa_forked_proc
    pop gs
    add bx,8
    dec cl
    jnz app_notify_forked_loop

app_notify_forked_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    ret
app_notify_forked   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AppNotifyExec
;
;           DESCRIPTION:    Notify exec
;
;           PARAMETERS:     ES  App sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_notify_exec_name      DB 'App Notify Exec',0

app_notify_exec   PROC far
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_activity_sel
    mov gs,cx
    mov cl,gs:app_activity_hooks
    or cl,cl
    je app_notify_exec_done
;
    mov bx,OFFSET app_activity_arr

app_notify_exec_loop:
    push gs
    lgs edi,gs:[bx]
    call fword ptr gs:[edi].aa_exec_proc
    pop gs
    add bx,8
    dec cl
    jnz app_notify_exec_loop

app_notify_exec_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    ret
app_notify_exec   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AppNotifySpawn
;
;           DESCRIPTION:    Notify spawn
;
;           PARAMETERS:     ES  App sel
;                           DS  Source sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_notify_spawn_name      DB 'App Notify Spawn',0

app_notify_spawn   PROC far
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_activity_sel
    mov gs,cx
    mov cl,gs:app_activity_hooks
    or cl,cl
    je app_notify_spawn_done
;
    mov bx,OFFSET app_activity_arr

app_notify_spawn_loop:
    push gs
    lgs edi,gs:[bx]
    call fword ptr gs:[edi].aa_spawn_proc
    pop gs
    add bx,8
    dec cl
    jnz app_notify_spawn_loop

app_notify_spawn_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    ret
app_notify_spawn   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AppNotifyTerminate
;
;           DESCRIPTION:    Notify process terminate
;
;           PARAMETERS:     ES  App sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_notify_terminate_name      DB 'App Notify Terminate',0

app_notify_terminate   PROC far
    push gs
    push eax
    push ebx
    push ecx
    push edi
;
    mov cx,app_activity_sel
    mov gs,cx
    mov cl,gs:app_activity_hooks
    or cl,cl
    je app_notify_terminate_done
;
    mov bx,OFFSET app_activity_arr
    movzx ax,cl
    dec ax
    shl ax,3
    add bx,ax

app_notify_terminate_loop:
    push gs
    lgs edi,gs:[bx]
    call fword ptr gs:[edi].aa_terminate_proc
    pop gs
    sub bx,8
    dec cl
    jnz app_notify_terminate_loop

app_notify_terminate_done:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop gs
    ret
app_notify_terminate   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetExeName
;
;           DESCRIPTION:    Get name of executable file
;
;           RETURNS:        ES:(E)DI        Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exe_name_name       DB 'Get Exe Name',0

get_exe_name    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    stc
    jz get_exe_name_done
;
    call fword ptr ds:loader_get_exe_proc

get_exe_name_done:
    pop ds
    ret
get_exe_name    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCmdLine
;
;           DESCRIPTION:    Get command line
;
;           RETURNS:        ES:(E)DI        Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cmd_line_name       DB 'Get Cmd Line',0

get_cmd_line    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    stc
    jz get_cmd_line_done
;
    call fword ptr ds:loader_get_cmd_line_proc

get_cmd_line_done:
    pop ds
    ret
get_cmd_line    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetEnvironment
;
;           DESCRIPTION:    Get environment
;
;           RETURNS:        ES:(E)DI        Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env_name    DB 'Get Environment',0

get_env PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    stc
    jz get_env_done
;
    call fword ptr ds:loader_get_env_proc

get_env_done:
    pop ds
    ret
get_env ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateAppMem
;
;           DESCRIPTION:    Allocate application memory
;
;           PARAMETERS:         EAX             Size
;
;           RETURNS:        ES / (E)DX      Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_app_mem_name   DB 'Allocate App Mem',0

allocate_app_mem    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    jz allocate_mem_default
;
    call fword ptr ds:loader_allocate_mem_proc
    jmp allocate_mem_done

allocate_mem_default:
    AllocateLocalMem

allocate_mem_done:
    pop ds
    ret
allocate_app_mem    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeAppMem
;
;           DESCRIPTION:    Free application memory
;
;           PARAMETERS:         ES / (E)DX      Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_app_mem_name       DB 'Free App Mem',0

free_app_mem    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    jz free_mem_default
;
    call fword ptr ds:loader_free_mem_proc
    jmp free_mem_done

free_mem_default:
    FreeMem

free_mem_done:
    pop ds
    ret
free_app_mem    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateDebugAppMem
;
;           DESCRIPTION:    Allocate application memory, debug mode
;
;           PARAMETERS:         EAX             Size
;
;           RETURNS:        ES / (E)DX      Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_debug_app_mem_name     DB 'Allocate Debug App Mem',0

allocate_debug_app_mem  PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    jz allocate_debug_mem_norm
;
    call fword ptr ds:loader_debug_allocate_mem_proc
    jmp allocate_debug_mem_done

allocate_debug_mem_norm:
    AllocateLocalMem

allocate_debug_mem_done:
    pop ds
    ret
allocate_debug_app_mem  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeDebugAppMem
;
;           DESCRIPTION:    Free application memory, debug mode
;
;           PARAMETERS:         ES / (E)DX      Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_debug_app_mem_name DB 'Free Debug App Mem',0

free_debug_app_mem      PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    jz free_debug_mem_norm
;
    call fword ptr ds:loader_debug_free_mem_proc
    jmp free_debug_mem_done

free_debug_mem_norm:
    FreeMem

free_debug_mem_done:
    pop ds
    ret
free_debug_app_mem      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetModule
;
;           DESCRIPTION:    Set module for active process
;
;           PARAMETERS:     ES  Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_module_name DB 'Set Module',0

set_module      PROC far
    push ds
    push ax
    push ebx
    push dx
;
    mov dx,es
    mov cx,SIZE module_handle_seg
    AllocateHandle
    mov [ebx].mh_sel,dx
    mov [ebx].hh_sign,MODULE_HANDLE
    mov bx,[ebx].hh_handle
;
    mov ds,dx
    InitSection ds:mod_section
    mov ds:mod_handle,bx
    mov ds:mod_list,0
;    
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds:app_handle,bx
    mov ds:app_mod_sel,dx
    mov al,ds:app_key
    mov es:mod_key,al
;    
    pop dx
    pop ebx
    pop ax
    pop ds
    ret
set_module      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetModule
;
;           DESCRIPTION:    Reset module for active process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_module_name       DB 'Reset Module',0

reset_module    PROC far
    push ds
    push es
    push ax
    push ebx
    push dx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_handle
    mov ax,MODULE_HANDLE
    DerefHandle
    jc reset_mod_handle_ok
;
    mov ax,[ebx].mh_sel
    or ax,ax
    jz reset_mod_free_mod
;
    mov es,ax    

reset_mod_loop:    
    mov ax,es:mod_list
    or ax,ax
    jz reset_mod_free_mod
;
    push es
    mov es,ax
    FreeModule
    pop es
    jmp reset_mod_loop

reset_mod_free_mod:
    FreeHandle

reset_mod_handle_ok:    
    pop dx
    pop ebx
    pop ax
    pop es
    pop ds
    ret
reset_module    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateModule
;
;           DESCRIPTION:    Create new module for active process
;
;       PARAMETERS:     ES  Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_module_name      DB 'Create Module',0

create_module   PROC far
    push ds
    push es
    push ax
    push ebx
    push dx
;
    mov ax,es
    mov ds,ax
    InitSection ds:mod_section
;    
    mov cx,SIZE module_handle_seg
    AllocateHandle
    mov [ebx].mh_sel,es
    mov [ebx].hh_sign,MODULE_HANDLE
    mov bx,[ebx].hh_handle
;
    mov es:mod_handle,bx
    mov es:mod_list,0
;    
    mov dx,es
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_handle
    mov ax,MODULE_HANDLE
    DerefHandle
    jc create_module_done
;
    mov ax,[ebx].mh_sel
    or ax,ax
    jz create_module_done
;
    mov ds,ax    
    EnterSection ds:mod_section
    mov ax,ds:mod_list
    mov ds:mod_list,es
    mov es:mod_next,ax
    LeaveSection ds:mod_section
    
create_module_done:    
    pop dx
    pop ebx
    pop ax
    pop es
    pop ds
    ret
create_module   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeModule
;
;           DESCRIPTION:    Free module for active process
;
;       PARAMETERS:     ES      Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_module_name    DB 'Free Module',0

free_module     PROC far
    push ds
    push es
    push ax
    push ebx
    push dx
    push si
;
    mov dx,es
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_handle
    mov ax,MODULE_HANDLE
    DerefHandle
    jc free_module_done
;
    mov si,[ebx].mh_sel
    or si,si
    jz free_module_done
;
    mov ds,si
    EnterSection ds:mod_section
    mov ax,ds:mod_list
    or ax,ax
    jz free_module_leave
;
    cmp ax,dx
    jne free_mod_not_head
;
    mov es,ax
    mov ax,es:mod_next
    mov ds:mod_list,ax
    mov bx,es:mod_handle
    jmp free_mod_handle
    
free_mod_not_head:    
    mov es,ax
    cmp dx,es:mod_next
    je free_mod_in_list
;
    mov ax,es:mod_next
    or ax,ax
    jnz free_mod_not_head
;
    jmp free_module_leave

free_mod_in_list:
    mov ds,dx
    mov ax,ds:mod_next
    mov es:mod_next,ax
    mov bx,ds:mod_handle

free_mod_handle:
    mov ax,MODULE_HANDLE
    DerefHandle
    jc free_module_leave
;
    FreeHandle

free_module_leave:      
    mov ds,si
    LeaveSection ds:mod_section
        
free_module_done:
    pop si
    pop dx
    pop ebx
    pop ax
    pop es
    pop ds
    ret
free_module     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DerefModuleHandle
;
;           DESCRIPTION:    Dereference module handle
;
;       PARAMETERS:         BX      Module handle
;
;           RETURNS:        BX          Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

deref_module_handle_name    DB 'Deref Module Handle',0

deref_module_handle  Proc far
    push ds
    push ax
;
    mov ax,MODULE_HANDLE
    DerefHandle
    jc deref_module_done
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz deref_module_done
;
    clc

deref_module_done:    
    pop ax
    pop ds    
    ret
deref_module_handle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AliasModuleHandle
;
;           DESCRIPTION:    Create an alias handle for module
;
;       PARAMETERS:         BX      Lib sel
;
;           RETURNS:        BX      Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alias_module_handle_name    DB 'Alias Module Handle',0

alias_module_handle  Proc far
    push ds
    push ax
    push cx
    push dx
;
    mov dx,bx
    mov cx,SIZE module_handle_seg
    AllocateHandle
    mov [ebx].mh_sel,dx
    mov [ebx].hh_sign,MODULE_HANDLE
    mov bx,[ebx].hh_handle
;    
    pop dx
    pop cx
    pop ax
    pop ds
    ret
alias_module_handle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleFocusKey
;
;           DESCRIPTION:    Get module focus key
;
;       PARAMETERS:         BX          Module handle
;
;       RETURNS:    AL      Key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_focus_key_name       DB 'Get Module Focus Key',0

get_module_focus_key  Proc far
    push ds
    push ebx
;    
    mov ax,MODULE_HANDLE
    DerefHandle
    jc get_module_focus_done
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz get_module_focus_done
;
    mov ds,bx
    mov al,ds:mod_key
    clc

get_module_focus_done:
    pop ebx
    pop ds    
    ret
get_module_focus_key  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_dll
;
;           DESCRIPTION:    Load DLL
;
;       PARAMETERS:         ES:(E)DI    Name of dll to load
;
;           RETURNS:        BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dll_name   DB 'Load Dll',0

load_dll32  Proc far
    push ds
    push eax
;    
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    stc
    jz load_dll32_done
;
    call fword ptr ds:loader_load_dll_proc
    jc load_dll32_done
;
    push es
    mov es,bx
    mov bx,es:mod_handle
    pop es      

load_dll32_done:
    pop eax
    pop ds
    ret
load_dll32  Endp

load_dll16  Proc far
    push ds
    push eax
    push edi
;    
    movzx edi,di
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    pop eax
    stc
    jz load_dll16_done
;
    call fword ptr ds:loader_load_dll_proc
    jc load_dll16_done
;
    push es
    mov es,bx
    mov bx,es:mod_handle
    pop es      

load_dll16_done:
    pop edi
    pop eax
    pop ds
    ret
load_dll16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           free_dll
;
;           DESCRIPTION:    Free DLL
;
;       PARAMETERS:         BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll_name   DB 'Free Dll',0

free_dll  Proc far
    push ds
    push eax
    push ebx
;    
    mov ax,MODULE_HANDLE
    DerefHandle
    jc free_dll_done
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz free_dll_done
;
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz free_dll_done
;    
    call fword ptr ds:loader_free_dll_proc    

free_dll_done:
    pop ebx
    pop eax
    pop ds    
    ret
free_dll  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCurrentDll
;
;           DESCRIPTION:    Get current DLL module handle
;
;       PARAMETERS:         ES:EDI      Code position
;
;       RETURNS:            BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_current_dll_name       DB 'Get Current Dll',0

get_current_dll  Proc far
    push ebp
    mov ebp,esp
    push ds
    push es
    push eax
    push edi
;    
    les edi,[ebp+4]    
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_current_dll_done
;
    call fword ptr ds:loader_get_current_dll_proc
    jc get_current_dll_done
;
    mov es,bx
    mov bx,es:mod_handle

get_current_dll_done:
    pop edi
    pop eax
    pop es
    pop ds    
    pop ebp
    ret
get_current_dll  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleProc
;
;           DESCRIPTION:    Get module procedure
;
;       PARAMETERS:         BX          Module handle
;                           ES:(E)DI    Proc name
;
;       RETURNS:    DS:(E)SI    Proc address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_proc_name    DB 'Get Module Proc',0

get_module_proc32  Proc far
    push eax
    push ebx
;    
    mov ax,MODULE_HANDLE
    DerefHandle
    jc get_module_proc_done32
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz get_module_proc_done32
;
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_module_proc_done32
;    
    call fword ptr ds:loader_get_proc_proc

get_module_proc_done32:
    pop ebx
    pop eax
    ret
get_module_proc32  Endp

get_module_proc16  Proc far
    push eax
    push ebx
    push edi
;    
    movzx edi,di
    mov ax,MODULE_HANDLE
    DerefHandle
    jc get_module_proc_done16
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz get_module_proc_done16
;
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_module_proc_done16
;
    call fword ptr ds:loader_get_proc_proc

get_module_proc_done16:
    pop edi
    pop ebx
    pop eax
    ret
get_module_proc16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleResource
;
;           DESCRIPTION:    Get module resource
;
;       PARAMETERS:         BX          Module handle
;               (E)AX       Resource handle
;               (E)DX       Resource type
;
;       RETURNS:    DS:(E)SI    Resource address
;               (E)CX       Resource size   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_resource_name    DB 'Get Module Resource',0

get_module_resource  Proc far
    push ebx
;    
    push ax
    mov ax,MODULE_HANDLE
    DerefHandle
    pop ax
    jc get_resource_done
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz get_resource_done
;
    mov ds,bx
    mov cx,ds:mod_loader
    or cx,cx
    mov ds,cx
    stc
    jz get_resource_done
;    
    call fword ptr ds:loader_get_resource_proc

get_resource_done:
    pop ebx
    ret
get_module_resource  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleName
;
;           DESCRIPTION:    Get module name
;
;       PARAMETERS:         BX          Handle
;                           (E)CX       Max name size
;                           ES:(E)DI    Name buffer
;                           
;           RETURNS:        (E)AX       Bytes copied
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_name_name    DB 'Get Module Name',0

get_module_name32  Proc far
    push ds
    push ebx
;    
    mov ax,MODULE_HANDLE
    DerefHandle
    jc get_module_name_done32
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz get_module_name_done32
;
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_module_name_done32
;    
    call fword ptr ds:loader_get_name_proc

get_module_name_done32:
    pop ebx
    pop ds
    ret
get_module_name32  Endp

get_module_name16  Proc far
    push ds
    push ebx
    push edi
;    
    movzx edi,di
    mov ax,MODULE_HANDLE
    DerefHandle
    jc get_module_name_done16
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz get_module_name_done16
;
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_module_name_done16
;    
    call fword ptr ds:loader_get_name_proc

get_module_name_done16:
    pop edi
    pop ebx
    pop ds
    ret
get_module_name16  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForDebugEvent
;
;           DESCRIPTION:    Start a wait for debug event
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_debug_event      PROC far
    push ds
    push eax
    push bx
;
    mov bx,es:dew_module_sel
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz start_wait_for_done
;    
    call fword ptr ds:loader_start_wait_for_debug_event_proc

start_wait_for_done:
    pop bx
    pop eax
    pop ds
    ret
start_wait_for_debug_event Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForDebugEvent
;
;           DESCRIPTION:    Stop a wait for debug event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_debug_event       PROC far
    push ds
    push eax
    push bx
;
    mov bx,es:dew_module_sel
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz stop_wait_for_done
;    
    call fword ptr ds:loader_stop_wait_for_debug_event_proc

stop_wait_for_done:
    pop bx
    pop eax
    pop ds
    ret
stop_wait_for_debug_event Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DummyClearDebugEvent
;
;           DESCRIPTION:    Clear debug event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_clear_debug_event PROC far
    ret
dummy_clear_debug_event Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsDebugEventIdle
;
;           DESCRIPTION:    Check if debug event is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_debug_event_idle     PROC far
    push ds
    push eax
    push bx
;
    mov bx,es:dew_module_sel
    mov ds,bx
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz is_idle_done
;    
    call fword ptr ds:loader_is_debug_event_idle_proc

is_idle_done:
    pop bx
    pop eax
    pop ds
    ret
is_debug_event_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForDebugEvent
;
;           DESCRIPTION:    Add a wait for debug event
;
;           PARAMETERS:     AX      Process handle
;                           BX      Wait handle
;                           ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_debug_event_name   DB 'Add Wait For Debug Event',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_debug_event,   SEG _text
aw1 DD OFFSET stop_wait_for_debug_event,    SEG _text
aw2 DD OFFSET dummy_clear_debug_event,      SEG _text
aw3 DD OFFSET is_debug_event_idle,          SEG _text

add_wait_for_debug_event    PROC far
    push ds
    push es
    push eax
    push dx
    push edi
;
    push bx
    mov bx,ax
    DerefProcHandle
    pop bx
    jc add_wait_done
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE debug_event_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;    
    mov es:dew_module_sel,ax

add_wait_done:
    pop edi
    pop dx
    pop eax
    pop es
    pop ds
    ret
add_wait_for_debug_event    ENDP
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetDebugEvent
;
;       DESCRIPTION:    Get current debug event
;
;       PARAMETERS:     BX      Process handle
;
;       RETURNS:        AX      Thread ID
;                       BL      Event type  
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event_name    DB 'Get Debug Event',0

get_debug_event  Proc far
    push ds
    push ecx
    push dx
;    
    DerefProcHandle
    jc get_debug_event_done
;
    mov bx,ax
    mov ds,ax
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_debug_event_done
;    
    call fword ptr ds:loader_get_debug_event_proc

get_debug_event_done:
    pop dx
    pop ecx
    pop ds
    ret
get_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDebugEventData
;
;           DESCRIPTION:    Get debug event data
;
;       PARAMETERS:         BX          Handle
;                           ES:(E)DI    Event buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event_data_name       DB 'Get Debug Event Data',0

get_debug_event_data32  Proc far
    push ds
    push eax
    push bx
    push dx
;    
    DerefProcHandle
    jc get_debug_event_data_done32
;
    mov ds,ax
    mov bx,ax
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_debug_event_data_done32
;    
    call fword ptr ds:loader_get_debug_event_data_proc

get_debug_event_data_done32:
    pop dx
    pop bx
    pop eax
    pop ds
    ret
get_debug_event_data32  Endp

get_debug_event_data16  Proc far
    push ds
    push eax
    push bx
    push dx
    push edi
;    
    DerefProcHandle
    jc get_debug_event_data_done16
;
    mov bx,ax
    mov ds,ax
    mov ax,ds:mod_loader
    or ax,ax
    mov ds,ax
    stc
    jz get_debug_event_data_done16
;    
    call fword ptr ds:loader_get_debug_event_data_proc

get_debug_event_data_done16:
    pop edi
    pop dx
    pop bx
    pop eax
    pop ds
    ret
get_debug_event_data16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearDebugEvent
;
;           DESCRIPTION:    Clear debug event
;
;       PARAMETERS:         BX          Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_debug_event_name  DB 'Clear Debug Event',0

clear_debug_event  Proc far
    push ds
    push ax
    push bx
    push ecx
    push dx
;    
    DerefProcHandle
    jc clear_debug_event_done
;
    mov bx,ax
    mov ds,ax
    mov cx,ds:mod_loader
    or cx,cx
    mov ds,cx
    stc
    jz clear_debug_event_done
;    
    call fword ptr ds:loader_clear_debug_event_proc

clear_debug_event_done:
    pop dx
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
clear_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ContinueDebugEvent
;
;           DESCRIPTION:    Continue debug event
;
;       PARAMETERS:         BX          Module handle
;                           EAX     Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

continue_debug_event_name       DB 'Continue Debug Event',0

continue_debug_event  Proc far
    push ds
    push bx
    push ecx
    push dx
    push esi
;    
    mov esi,eax
    DerefProcHandle
    jc continue_debug_event_done
;
    mov bx,ax
    mov ds,ax
    mov eax,esi
    mov cx,ds:mod_loader
    or cx,cx
    mov ds,cx
    stc
    jz continue_debug_event_done
;    
    call fword ptr ds:loader_continue_debug_event_proc

continue_debug_event_done:
    pop esi
    pop dx
    pop ecx
    pop bx
    pop ds
    ret
continue_debug_event  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FatalErrorExit
;
;           DESCRIPTION:    Fatal error exit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fatal_error_exit_name       DB 'Fatal Error Exit',0

fatal_error_exit    PROC far
    push ds
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov eax,ds:app_fatal_error_exit_proc
    or eax,ds:app_fatal_error_exit_proc+4
    pop eax
    stc
    jz fatal_error_exit_done
;
    call fword ptr ds:app_fatal_error_exit_proc

fatal_error_exit_done:
    pop ds
    ret
fatal_error_exit    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Fork
;
;           DESCRIPTION:    Fork process
;
;           RETURNS:        AX = 0 for child
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fork_name   DB 'Fork',0

fork_pr    PROC far
    push ds
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov eax,ds:app_fork_proc
    or eax,ds:app_fork_proc+4
    mov eax,-1
    jz fork_done
;
    call fword ptr ds:app_fork_proc
    
fork_done:
    pop ds
    ret
fork_pr    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsForked
;
;           DESCRIPTION:    Check if thread is forked
;
;           RETURNS:        NC          Forked
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_forked_name   DB 'Is Forked',0

is_forked    PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    test ds:p_flags,THREAD_FLAG_FORKED
    stc
    jz ifDone
;
    clc

ifDone:
    pop ax
    pop ds
    ret
is_forked    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_LOAD_EXE
;
;           DESCRIPTION:    Add hook for LoadExe
;
;           PARAMETERS:     ES:EDI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_load_exe_name      DB 'Hook Load Exe',0

hook_load_exe   PROC far
    push ds
    push ax
    push bx
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:load_exe_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET load_exe_arr
    mov [bx],edi
    mov [bx+4],es
    inc ax
    mov ds:load_exe_hooks,ax
;
    pop bx
    pop ax
    pop ds
    ret
hook_load_exe   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LOAD_EXE
;
;           DESCRIPTION:    Load executable file
;
;           PARAMETERS:     BX      C file handle
;                           DS:ESI  File name
;                           ES:EDI  Command line
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_exe_name      DB 'Load Exe',0

load_exe   PROC far
    push gs
    mov ax,SEG data
    mov fs,ax
    mov cx,fs:load_exe_hooks
    or cx,cx
    stc
    je load_exe_file_done
;
    mov ax,OFFSET load_exe_arr

load_exe_file_loop:
    push fs
    push ax
    push cx
;
    xor ecx,ecx
    mov cx,cs
    push ecx
    mov cx,OFFSET load_exe_file_ret
    push ecx
;    
    push bx
    mov bx,ax
    mov eax,fs:[bx]
    mov ecx,fs:[bx+4]
    pop bx
;
    push ecx
    push eax
    ret

load_exe_file_ret:
    pop cx
    pop ax
    pop fs
    jnc load_exe_file_done
;
    add ax,8
    sub cx,1
    jnz load_exe_file_loop
;
    stc

load_exe_file_done:
    pop gs
    ret
load_exe   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_process
;
;           DESCRIPTION:    Run program as process
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_cmd_line   DB 0, 0Dh

load_process:
    mov es,bx
    xor di,di
    mov al,es:[di+1]
    cmp al,':'
    jne load_process_default_drive
    mov al,es:[di]
    sub al,'a'
    jnc load_process_set_drive
    add al,20h
load_process_set_drive:
    SetCurDrive
load_process_default_drive:
    SaveContext
    xor eax,eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
    push eax
;
    mov ax,es
    mov ds,ax
    mov si,di
;
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    AppNotifyStart
;
    mov ax,3Bh
    EnableFocus
    SetFocus
    mov es:app_key,al
    mov es:app_context,bx
;       
    push si
    mov di,OFFSET app_exe_name
    mov cx,100h
    rep movsb
    pop di
    xor bx,bx
    mov ax,ds
    mov es,ax
    movzx edi,di
;
    mov cx,O_RDONLY OR O_BINARY
    OpenKernelFile
    jc load_process_fail
;
    xor esi,esi
    mov ax,cs
    mov es,ax
    mov edi,OFFSET load_cmd_line
    Exec
    jc load_process_close_fail
;
    test byte ptr [bp+2].load_eflags,2
    jnz load_process_vm
;
    mov ds,[bp].load_ds
    mov es,[bp].load_es
    mov fs,[bp].load_fs
    mov gs,[bp].load_gs

load_process_vm:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

load_process_close_fail:
    CloseFile

load_process_fail:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_process64
;
;           DESCRIPTION:    Run program as 64-bit process
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_process64:
    int 3
    mov es,bx
    xor di,di
    mov al,es:[di+1]
    cmp al,':'
    jne load_process_default_drive64
    mov al,es:[di]
    sub al,'a'
    jnc load_process_set_drive64
;
    add al,20h

load_process_set_drive64:
    SetCurDrive
    
load_process_default_drive64:
    sti
    mov gs,bx
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov ax,3Bh
    EnableFocus
    SetFocus
    mov es:app_key,al
    mov es:app_context,bx
;
    mov ax,10
    WaitMilliSec
;
    StartLongExe

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           run_process
;
;           DESCRIPTION:    Run processes in adapter
;
;           PARAMETERS:         DS:EDX  device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_process     PROC near
    push ds
    push es
    pushad
;
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    mov esi,edx
    mov eax,1000h
    AllocateGlobalMem
    xor edi,edi
    rep movs dword ptr es:[edi],ds:[esi]
    xor edi,edi
;
    xor esi,esi
    mov ax,es
    mov ds,ax
    Is64BitExe
    jnc run_process64
;   
    mov bx,es
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET load_process
    mov ax,2
    mov ecx,stack0_size
    CreateProcess
    jmp run_process_wait

run_process64:
    mov bx,es
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET load_process64
    mov ax,202h
    mov ecx,stack0_size
    CreateProcess

run_process_wait:    
    mov ax,100
    WaitMilliSec
;
    popad
    pop es
    pop ds
    ret
run_process     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_adapter_process
;
;           DESCRIPTION:    Start all processes in adapter
;
;           PARAMETERS:         edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_adapter_process    Proc near
    push ds
    push es
    push ax
    push bx
    push edx
    mov ax,flat_sel
    mov ds,ax
    mov es,ax

init_adapter_process_loop:
    mov ax,[edx].typ
    cmp ax,RdosCommand
    jne not_run_process
    call run_process
    jmp init_adapter_process_next
not_run_process:
    cmp ax,RdosEnd
    je init_adapter_process_done
init_adapter_process_next:
    add edx,[edx].len
    jmp init_adapter_process_loop
init_adapter_process_done:
    pop edx
    pop bx
    pop ax
    pop es
    pop ds
    ret
init_adapter_process    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartPrograms
;
;           DESCRIPTION:    Start all processes
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_programs_name DB 'Start Programs', 0

start_programs    Proc far
    push ds
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    movzx ecx,ds:rom_modules
    mov bx,OFFSET rom_adapters

spLoop:
    mov edx,[bx].adapter_base
    call init_adapter_process
    add bx,SIZE adapter_typ
    loop spLoop
;
    popad
    pop ds
    ret
start_programs    Endp

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
    mov es:next_pid,1
    mov es:load_exe_hooks,0
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
    mov esi,OFFSET start_programs
    mov edi,OFFSET start_programs_name
    xor cl,cl
    mov ax,start_programs_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_load_exe
    mov edi,OFFSET hook_load_exe_name
    xor cl,cl
    mov ax,hook_load_exe_nr
    RegisterOsGate
;
    mov esi,OFFSET load_exe
    mov edi,OFFSET load_exe_name
    xor cl,cl
    mov ax,exec_nr
    RegisterOsGate
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
    mov esi,OFFSET app_notify_create
    mov edi,OFFSET app_notify_create_name
    xor cl,cl
    mov ax,app_notify_create_nr
    RegisterOsGate
;
    mov esi,OFFSET app_notify_start
    mov edi,OFFSET app_notify_start_name
    xor cl,cl
    mov ax,app_notify_start_nr
    RegisterOsGate
;
    mov esi,OFFSET app_notify_forked
    mov edi,OFFSET app_notify_forked_name
    xor cl,cl
    mov ax,app_notify_forked_nr
    RegisterOsGate
;
    mov esi,OFFSET app_notify_exec
    mov edi,OFFSET app_notify_exec_name
    xor cl,cl
    mov ax,app_notify_exec_nr
    RegisterOsGate
;
    mov esi,OFFSET app_notify_spawn
    mov edi,OFFSET app_notify_spawn_name
    xor cl,cl
    mov ax,app_notify_spawn_nr
    RegisterOsGate
;
    mov esi,OFFSET app_notify_terminate
    mov edi,OFFSET app_notify_terminate_name
    xor cl,cl
    mov ax,app_notify_terminate_nr
    RegisterOsGate
;
    mov esi,OFFSET set_module
    mov edi,OFFSET set_module_name
    xor cl,cl
    mov ax,set_module_nr
    RegisterOsGate
;
    mov esi,OFFSET reset_module
    mov edi,OFFSET reset_module_name
    xor cl,cl
    mov ax,reset_module_nr
    RegisterOsGate
;
    mov esi,OFFSET create_module
    mov edi,OFFSET create_module_name
    xor cl,cl
    mov ax,create_module_nr
    RegisterOsGate
;
    mov esi,OFFSET free_module
    mov edi,OFFSET free_module_name
    xor cl,cl
    mov ax,free_module_nr
    RegisterOsGate
;
    mov esi,OFFSET deref_module_handle
    mov edi,OFFSET deref_module_handle_name
    xor cl,cl
    mov ax,deref_module_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET alias_module_handle
    mov edi,OFFSET alias_module_handle_name
    xor cl,cl
    mov ax,alias_module_handle_nr
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
    mov esi,OFFSET fatal_error_exit
    mov edi,OFFSET fatal_error_exit_name
    xor dx,dx
    mov ax,fatal_error_exit_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_exe_name
    mov edi,OFFSET get_exe_name_name
    mov dx,virt_es_in
    mov ax,get_exe_name_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_cmd_line
    mov edi,OFFSET get_cmd_line_name
    mov dx,virt_es_in
    mov ax,get_cmd_line_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_env
    mov edi,OFFSET get_env_name
    mov dx,virt_es_in
    mov ax,get_env_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET fork_pr
    mov edi,OFFSET fork_name
    xor dx,dx
    mov ax,fork_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_forked
    mov edi,OFFSET is_forked_name
    xor dx,dx
    mov ax,is_forked_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET allocate_app_mem
    mov edi,OFFSET allocate_app_mem_name
    mov dx,virt_es_out
    mov ax,allocate_app_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET free_app_mem
    mov edi,OFFSET free_app_mem_name
    mov dx,virt_es_in
    mov ax,free_app_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET allocate_debug_app_mem
    mov edi,OFFSET allocate_debug_app_mem_name
    mov dx,virt_es_out
    mov ax,allocate_debug_app_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET free_debug_app_mem
    mov edi,OFFSET free_debug_app_mem_name
    mov dx,virt_es_in
    mov ax,free_debug_app_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_focus_key
    mov edi,OFFSET get_module_focus_key_name
    xor dx,dx
    mov ax,get_module_focus_key_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET load_dll16
    mov esi,OFFSET load_dll32
    mov edi,OFFSET load_dll_name
    mov dx,virt_es_in
    mov ax,load_dll_nr
    RegisterUserGate
;
    mov esi,OFFSET free_dll
    mov edi,OFFSET free_dll_name
    xor dx,dx
    mov ax,free_dll_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_current_dll
    mov edi,OFFSET get_current_dll_name
    xor dx,dx
    mov ax,get_current_dll_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_module_proc16
    mov esi,OFFSET get_module_proc32
    mov edi,OFFSET get_module_proc_name
    mov dx,virt_ds_out OR virt_es_in
    mov ax,get_module_proc_nr
    RegisterUserGate
;
    mov esi,OFFSET get_module_resource
    mov edi,OFFSET get_module_resource_name
    xor dx,dx
    mov ax,get_module_resource_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_module_name16
    mov esi,OFFSET get_module_name32
    mov edi,OFFSET get_module_name_name
    mov dx,virt_es_in
    mov ax,get_module_name_nr
    RegisterUserGate
;
    mov esi,OFFSET add_wait_for_debug_event
    mov edi,OFFSET add_wait_for_debug_event_name
    xor dx,dx
    mov ax,add_wait_for_debug_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_debug_event
    mov edi,OFFSET get_debug_event_name
    xor dx,dx
    mov ax,get_debug_event_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_debug_event_data16
    mov esi,OFFSET get_debug_event_data32
    mov edi,OFFSET get_debug_event_data_name
    mov dx,virt_es_in
    mov ax,get_debug_event_data_nr
    RegisterUserGate
;
    mov esi,OFFSET clear_debug_event
    mov edi,OFFSET clear_debug_event_name
    xor dx,dx
    mov ax,clear_debug_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET continue_debug_event
    mov edi,OFFSET continue_debug_event_name
    xor dx,dx
    mov ax,continue_debug_event_nr
    RegisterBimodalUserGate
;
    popad
    pop es
    pop ds
    ret
InitScheduler_    Endp

_TEXT    ENDS

    END
