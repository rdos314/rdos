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

MAX_PROCESS_THREADS  = 256
MAX_PROCESS_MODULES  = 256

process_struc    STRUC

pr_loader            DW ?
pr_kernel_file       DW ?
pr_name_sel          DW ?
pr_cmd_sel           DW ?
pr_dir_sel           DW ?
pr_env_sel           DW ?
pr_debug_sel         DW ?
pr_thread            DW ?
pr_parent_thread     DW ?
pr_app_sel           DW ?
pr_parent_app_sel    DW ?
pr_proc_sel          DW ?
pr_loader_name       DD ?
pr_switch            DB ?,?

pr_section           section_typ <>

pr_module_count      DW ?
pr_module_arr        DW MAX_PROCESS_MODULES DUP(?)

pr_thread_count      DW ?
pr_thread_arr        DW MAX_PROCESS_THREADS DUP(?)

process_struc    ENDS

module_handle_seg           STRUC

mh_base handle_header <>

mh_sel        DW ?

module_handle_seg           ENDS

debug_event_wait_header STRUC

dew_obj         wait_obj_header <>
dew_module_sel         DW ?

debug_event_wait_header ENDS

data    SEGMENT byte public 'DATA'

state_hooks         DW ?
loader_count        DW ?
state_arr           DD 2*32 DUP(?)
loader_arr          DW 16 DUP(?)

data    ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn IdToHandle:near
    extrn IndexToHandle:near
    extrn MoveThread:near

    extrn ProcessCreated:near
    extrn ProcessTerminated:near
    extrn GetActiveProcesses:near
    extrn GetProcessSel:near
    extrn GetProcessID:near

    extrn ModuleLoaded:near
    extrn ModuleUnloaded:near
    extrn GetActiveModules:near
    extrn GetModuleSel:near
    extrn GetModuleID:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddProgramThread
;
;           DESCRIPTION:    Add thread to program
;
;           PARAMETERS:     ES      Thread
;                           BX      Program ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddProgramThread    Proc near
    push ds
    push eax
    push ebx
    push ecx
;
    call GetProcessSel
    or eax,eax
    jz aptDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_thread_count
    cmp ecx,MAX_PROCESS_THREADS
    jae aptLeave
;
    mov ebx,ecx
    shl ebx,1
    inc ecx
    mov ds:pr_thread_count,cx
;
    mov ax,es:p_id
    mov ds:[ebx].pr_thread_arr,ax
    
aptLeave:
    LeaveSection ds:pr_section
            
aptDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AddProgramThread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemoveProgramThread
;
;           DESCRIPTION:    Remove thread from program
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveProgramThread    Proc near
    push ds
    push eax
    push ebx
    push ecx
;
    movzx ebx,es:p_prog_id
    or ebx,ebx
    jnz rptStart
;
    mov ebx,1

rptStart:
    call GetProcessSel
    or eax,eax
    jz rptDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    mov ax,es:p_id
    movzx ecx,ds:pr_thread_count
    mov ebx,OFFSET pr_thread_arr
    or ecx,ecx
    jz rptLeave

rptLoop:
    cmp ax,ds:[ebx]
    je rptFound
;
    add bx,2
    loop rptLoop
;
    jmp rptLeave

rptFound:
    dec ds:pr_thread_count
;
    sub ecx,1
    jz rptLeave

rptMove:
    mov ax,ds:[ebx+2]
    mov ds:[ebx],ax
    add ebx,2
    loop rptMove

rptLeave:
    LeaveSection ds:pr_section
            
rptDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
RemoveProgramThread    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddKernelProgramModule
;
;           DESCRIPTION:    Add kernel module to program
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddKernelProgramModule    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    push ebx
    mov ebx,1
    call GetProcessSel
    pop ebx
    or eax,eax
    jz akpmDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_module_count
    cmp ecx,MAX_PROCESS_MODULES
    jae akpmLeave
;
    mov eax,ecx
    shl eax,1
    inc ecx
    mov ds:pr_module_count,cx
;
    mov ds:[eax].pr_module_arr,bx
    
akpmLeave:
    LeaveSection ds:pr_section
            
akpmDone:
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
AddKernelProgramModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddProgramModule
;
;           DESCRIPTION:    Add module to program
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddProgramModule    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    GetThread
    mov es,ax
;
    push ebx
    movzx ebx,es:p_prog_id
    call GetProcessSel
    pop ebx
    or eax,eax
    jz apmDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_module_count
    cmp ecx,MAX_PROCESS_MODULES
    jae apmLeave
;
    mov eax,ecx
    shl eax,1
    inc ecx
    mov ds:pr_module_count,cx
;
    mov ds:[eax].pr_module_arr,bx
    
apmLeave:
    LeaveSection ds:pr_section
            
apmDone:
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
AddProgramModule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemoveProgramModule
;
;           DESCRIPTION:    Remove module from program
;
;           PARAMETERS:     BX      Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveProgramModule    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    GetThread
    mov es,ax
;
    push ebx
    movzx ebx,es:p_prog_id
    call GetProcessSel
    or eax,eax
    pop ebx
    jz rpmDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    mov ax,bx
    movzx ecx,ds:pr_module_count
    mov ebx,OFFSET pr_module_arr
    or ecx,ecx
    jz rpmLeave

rpmLoop:
    cmp ax,ds:[ebx]
    je rpmFound
;
    add bx,2
    loop rpmLoop
;
    jmp rpmLeave

rpmFound:
    dec ds:pr_module_count
;
    sub ecx,1
    jz rpmLeave

rpmMove:
    mov ax,ds:[ebx+2]
    mov ds:[ebx],ax
    add ebx,2
    loop rpmMove

rpmLeave:
    LeaveSection ds:pr_section
            
rpmDone:
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
RemoveProgramModule    Endp

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
    movzx ebx,es:p_prog_id
    or ebx,ebx
    jnz ctAdd
;
    mov ebx,1

ctAdd:
    call AddProgramThread

ctDone:
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
    call RemoveProgramThread
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
;           NAME:           ModuleIdToSel
;
;           DESCRIPTION:    Convert from module ID to selector
;
;       PARAMETERS:         BX          Module ID
;
;           RETURNS:        BX          Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

module_id_to_sel_name    DB 'Module ID to Sel',0

module_id_to_sel  Proc far
    push eax
;
    movzx ebx,bx
    call GetModuleSel
    or eax,eax
    clc
    jnz mitsDone
;
    stc

mitsDone:
    mov ebx,eax
;
    pop eax
    ret
module_id_to_sel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPrimaryModule
;
;           DESCRIPTION:    Get primary module ID from process ID
;
;       PARAMETERS:         BX          Process ID
;
;           RETURNS:        AX          Primary module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPrimaryModule  Proc near
    push ds
;
    movzx ebx,bx
    call GetProcessSel
    or eax,eax
    jz gpmodFail
;
    mov ds,eax
    mov ax,ds:pr_module_count
    or ax,ax
    jz gpmodFail
;
    mov ax,ds:pr_module_arr
    clc
    jmp gpmodDone

gpmodFail:
    stc

gpmodDone:
    pop ds
    ret
GetPrimaryModule  Endp
    
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
    mov ebx,es
    call ModuleLoaded
;
    mov ebx,eax
    call AddProgramModule
;
    mov dx,es
    mov ds,dx
    InitSection ds:mod_section
    mov es:mod_id,bx
    mov ds:mod_list,0
;    
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds:app_mod_id,bx
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
    int 3
    push ds
    push es
    push ax
    push ebx
    push dx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_mod_id
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
    push es
    push ax
    push ebx
;
    mov ebx,es
    call ModuleLoaded
;
    mov ebx,eax
    call AddProgramModule
;
    InitSection es:mod_section
    mov es:mod_id,bx
    
create_module_done:    
    pop ebx
    pop ax
    pop es
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
    int 3
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
    mov bx,ds:app_mod_id
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
    mov bx,es:mod_id
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
    mov bx,ds:mod_id

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
    mov ds,bx
    mov bx,ds:mod_id
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
    ModuleIdToSel
    jc get_module_focus_done
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
    mov bx,es:mod_id
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
    mov bx,es:mod_id
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
    ModuleIdToSel
    jc free_dll_done
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
    mov bx,es:mod_id

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
    ModuleIdToSel
    jc get_module_proc_done32
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
    ModuleIdToSel
    jc get_module_proc_done16
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
    ModuleIdToSel
    jc get_resource_done
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
    ModuleIdToSel
    jc get_module_name_done32
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
    ModuleIdToSel
    jc get_module_name_done16
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
;       NAME:           DuplModuleFileHandle
;
;       DESCRIPTION:    Dupl module file handle
;
;       PARAMETERS:     BX          Module handle
;
;       RETURNS:        BX          Duplicated file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_module_file_handle_name       DB 'Dupl Module File Handle',0

dupl_module_file_handle  Proc far
    push ds
    push eax
;    
    mov ax,MODULE_HANDLE
    DerefHandle
    jc dupl_module_file_handle_done
;
    mov bx,[ebx].mh_sel
    or bx,bx
    stc
    jz dupl_module_file_handle_done
;
    mov ds,bx
;    mov eax,ds:mod_dupl_file_handle_proc
;    or eax,ds:mod_dupl_file_handle_proc+4
    stc
;    jz dupl_module_file_handle_done
;    
;    call fword ptr ds:mod_dupl_file_handle_proc

dupl_module_file_handle_done:
    pop eax
    pop ds    
    ret
dupl_module_file_handle  Endp
    
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
    push ebx
    push edx
    push edi
;
    push bx
    mov bx,ax
    call GetPrimaryModule
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
    movzx ebx,ax
    ModuleIdToSel
    mov es:dew_module_sel,bx

add_wait_done:
    pop edi
    pop edx
    pop ebx
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
    call GetPrimaryModule
    jc get_debug_event_done
;
    movzx ebx,ax
    ModuleIdToSel
    jc get_debug_event_done
;
    mov ax,bx
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
    call GetPrimaryModule
    jc get_debug_event_data_done32
;
    movzx ebx,ax
    ModuleIdToSel
    jc get_debug_event_data_done32
;
    mov ax,bx
    mov ds,ax
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
    call GetPrimaryModule
    jc get_debug_event_data_done16
;
    movzx ebx,ax
    ModuleIdToSel
    jc get_debug_event_data_done16
;
    mov ax,bx
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
    call GetPrimaryModule
    jc clear_debug_event_done
;
    movzx ebx,ax
    ModuleIdToSel
    jc clear_debug_event_done
;
    mov ax,bx
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
    call GetPrimaryModule
    jc continue_debug_event_done
;
    movzx ebx,ax
    ModuleIdToSel
    jc continue_debug_event_done
;
    mov ax,bx
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
;           NAME:           RegisterLoader
;
;           DESCRIPTION:    Register a loader
;
;           PARAMETERS:     BX       Loader table selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_loader_name      DB 'Register Loader',0

register_loader   PROC far
    push ds
    push ax
    push esi
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:loader_count
    movzx esi,ax
    add esi,esi
    mov ds:[esi].loader_arr,bx
    inc ax
    mov ds:loader_count,ax
;
    pop esi
    pop ax
    pop ds
    ret
register_loader   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenProgramFile
;
;       DESCRIPTION:    Open program file
;
;       PARAMETERS:     DS:ESI  File name
;
;       RETURNS:        BX      File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenProgramFile Proc near    
    push es
    push eax
    push ecx
    push edi
;
    mov eax,ds
    mov es,eax
    mov edi,esi
    mov cx,O_RDONLY OR O_BINARY
    OpenKernelFile
    jnc opfDone
;
    int 3

opfDone:
    pop edi
    pop ecx
    pop eax
    pop es
    ret
OpenProgramFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetProgramLoader
;
;       DESCRIPTION:    Get program loader
;
;       PARAMETERS:     DS:ESI  File name
;
;       RETURNS:        AX      Loader
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetProgramLoader Proc near
    push ds
    push es
    push fs
    push ecx
    push esi
    push edi
;
    mov eax,ds
    mov es,eax
    mov edi,esi
;
    mov ax,SEG data
    mov fs,ax
    movzx ecx,fs:loader_count
    or ecx,ecx
    je gplFail
;
    mov esi,OFFSET loader_arr

gplLoop:
    mov ds,fs:[esi]
    call fword ptr ds:loader_is_valid_exe_proc
    jnc gplOk
;
    add esi,2
    loop gplLoop

gplFail:
    stc
    jmp gplDone

gplOk:
    mov ax,fs:[esi]
    clc

gplDone:
    pop edi
    pop esi
    pop ecx
    pop fs
    pop es
    pop ds
    ret
GetProgramLoader Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateProcessBlock
;
;       DESCRIPTION:    Allocate process block
;
;       RETURNS:        GS      Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateProcessBlock Proc near    
    push es
    push eax
; 
    mov eax,SIZE process_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
;  
    mov gs:pr_name_sel,0
    mov gs:pr_cmd_sel,0
    mov gs:pr_dir_sel,0
    mov gs:pr_env_sel,0
    mov gs:pr_cmd_sel,0
    mov gs:pr_debug_sel,0
    mov gs:pr_thread,0
    mov gs:pr_proc_sel,0
    mov gs:pr_switch,0
    mov gs:pr_thread_count,0
    mov gs:pr_module_count,0
    InitSection gs:pr_section
;
    pop eax
    pop es
    ret
AllocateProcessBlock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateProcess
;
;       DESCRIPTION:    Allocate process
;
;       PARAMETERS:     DX      Debug module handle
;
;       RETURNS:        GS      Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateProcess Proc near    
    push ds
    pushad
; 
    call AllocateProcessBlock
;
    mov bx,dx
    ModuleIdToSel
    jc apDebugOk
;    
    mov gs:pr_debug_sel,bx

apDebugOk:
    mov gs:pr_switch,0
;
    GetThread
    mov bx,ax
    GetThreadFocusKey
    jc apFocusDone
;
    mov gs:pr_switch,al

apFocusDone:
    popad
    pop ds
    ret
AllocateProcess  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateProg
;
;       DESCRIPTION:    Make global copy of program name
;
;       PARAMETERS:     DS:ESI      Filename
;                       GS          Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateProg Proc near
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov edi,esi
    xor ecx,ecx

cprLoop:
    lods byte ptr [esi]
    or al,al
    jz cprSizeOk
;
    inc ecx
    jmp cprLoop

cprSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:pr_name_sel,es
;    
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    ret
CreateProg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateNoParam
;
;       DESCRIPTION:    Make global copy of empty parameters
;
;       PARAMETERS:     GS          Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateNoParam Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov eax,1
    AllocateSmallGlobalMem
    xor edi,edi
    xor al,al
    stos byte ptr es:[edi]
    mov gs:pr_cmd_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateNoParam Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateParam
;
;       DESCRIPTION:    Make global copy of parameters
;
;       PARAMETERS:     DS:ESI      Param pointer
;                       GS          Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateParam Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov edi,esi
    xor ecx,ecx

cpaLoop:
    lods byte ptr [esi]
    or al,al
    jz cpaSizeOk
;
    inc ecx
    jmp cpaLoop

cpaSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:pr_cmd_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateParam Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDefaultStartDir
;
;       DESCRIPTION:    Make global copy of default directory
;
;       PARAMETERS:     GS          Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDefaultStartDir Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov eax,256
    AllocateSmallGlobalMem
    xor edi,edi
    GetCurDrive
    mov ah,al
    add al,'A'
    stos byte ptr es:[edi]
;
    mov al,':'
    stos byte ptr es:[edi]
;
    mov al,'\'
    stos byte ptr es:[edi]
;
    mov al,ah
    GetCurDir
;
    mov gs:pr_dir_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateDefaultStartDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateStartDir
;
;       DESCRIPTION:    Make global copy of start dir
;
;       PARAMETERS:     DS:ESI      Startup dir
;                       GS          Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateStartDir Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov edi,esi
    xor ecx,ecx

csdLoop:
    lods byte ptr [esi]
    or al,al
    jz csdSizeOk
;
    inc ecx
    jmp csdLoop

csdSizeOk:
    mov esi,edi
    inc ecx 
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:pr_dir_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateStartDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDefaultEnv
;
;       DESCRIPTION:    Make global copy of default environment variables
;
;       PARAMETERS:     GS      Spawn sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDefaultEnv Proc near
    push es
    push eax
    push ecx
    push edi
;
    OpenProcEnv
    GetEnvSize
    movzx eax,ax
    AllocateSmallGlobalMem
    xor edi,edi
    GetEnvData
    CloseEnv
    mov gs:pr_env_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateDefaultEnv Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateEnv
;
;       DESCRIPTION:    Put environment variables in process structure
;
;       PARAMETERS:     DS:ESI  Environment ptr
;                       GS      Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEnv Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov edi,esi
    xor ecx,ecx

ceLoop:
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz ceLoop
;
    inc ecx
    lods byte ptr [esi]
    or al,al
    jnz ceLoop

ceSizeOk:
    mov esi,edi
    mov eax,ecx
    AllocateSmallGlobalMem
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]     
    mov gs:pr_env_sel,es
;       
    pop edi
    pop ecx
    pop eax
    pop es
    ret
CreateEnv Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupStartDir
;
;           DESCRIPTION:    Setup start directory
;
;           PARAMETERS:     GS      Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupStartDir Proc near
    push es
    push ax
    push edi
;
    mov es,gs:pr_dir_sel
    xor edi,edi
    mov ax,es:[edi]
    cmp ah,':'
    jne sdDirOk
;
    sub al,'A'
    jc sdDirOk
;
    cmp al,26
    jc sdSetDrive
;
    sub al,20h
    jc sdDirOk
;
    cmp al,26
    jnc sdDirOk

sdSetDrive:
    SetCurDrive
    add edi,2
    SetCurDir
    
sdDirOk:
    pop edi
    pop ax
    pop es
    ret
SetupStartDir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupEnv
;
;           DESCRIPTION:    Setup environment
;
;           PARAMETERS:     GS      Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupEnv Proc near
    push es
    push ebx
    push edi
;
    mov es,gs:pr_env_sel
    xor edi,edi
;
    OpenProcEnv
    SetEnvData
    CloseEnv
;
    pop edi
    pop ebx
    pop es
    ret
SetupEnv   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SpawnStartup
;
;           DESCRIPTION:    Spawn startup stub
;
;           PARAMETERS:     BX      Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_startup:
    sti
    GetThread
    mov es,ax
    call RemoveProgramThread
;
    mov es:p_prog_id,bx
    call AddProgramThread
;
    call GetProcessSel
    mov gs,eax
;
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
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov es:app_context,bx
    mov es:app_unload_proc,OFFSET spUnload
;
    mov ax,gs:pr_parent_app_sel
    or ax,ax
    jnz ssSpawn

ssStart:
    AppNotifyStart
    jmp ssNotifyOk

ssSpawn:
    mov ds,gs:pr_parent_app_sel
    AppNotifySpawn

ssNotifyOk:
    mov ax,3Bh
    EnableFocus
    SetFocus
    mov es:app_key,al
;
    xor esi,esi
    mov ds,gs:pr_name_sel    
    mov edi,OFFSET app_exe_name

spCopyExeLoop:
    lodsb
    stosb
    or al,al
    jne spCopyExeLoop
;
    GetThread
    mov es,ax
    mov al,gs:pr_switch
    mov es:p_parent_switch,al
;       
    GetThread
    mov gs:pr_thread,ax
    mov ds,ax
    mov ax,ds:p_app_sel
    mov gs:pr_app_sel,ax
    mov ds,ds:p_process_sel
    mov ax,ds:ms_pd_sel
    mov gs:pr_proc_sel,ax
;
    mov bx,gs:pr_parent_thread
    Signal
;
    call SetupStartDir
    call SetupEnv
;       
    mov bx,gs:pr_kernel_file
    xor esi,esi
    xor edi,edi
    mov ds,gs:pr_name_sel
    mov es,gs:pr_cmd_sel
;
    push gs
    mov gs,gs:pr_loader
    call fword ptr gs:loader_load_exe_proc
    pop gs
    jc spCloseFail
;
    mov dx,gs:pr_debug_sel
    or dx,dx
    jz spDebugDone
;
    push gs
    mov gs,gs:pr_loader
    call fword ptr gs:loader_setup_debug_proc
    pop gs

spDebugDone:
    test byte ptr [bp+2].load_eflags,2
    jnz spVm16
;
    mov ds,[bp].load_ds
    mov es,[bp].load_es
    mov fs,[bp].load_fs
    mov gs,[bp].load_gs

spVm16:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

spCloseFail:
    CloseCFile

spFail:
    int 3

spUnload:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           spawn_program16/32
;
;       DESCRIPTION:    Load & detach executable file
;
;       PARAMETERS:     DS:(E)SI    Filename
;                       ES:(E)DI    Parameters
;                           +0      command line
;                           +8      startdir
;                           +12     env
;                       DX          Debug module handle
;
;       RETURN VALUE:   AX          Thread ID
;                       DX          Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_exe_name  DB 'Spawn Exe',0

spawn_program   Proc near
    push ds
    push es
    push gs
    push ebx
    push ecx
    push esi
    push edi
;
    call OpenProgramFile
    jc spDone
;
    call GetProgramLoader
    jnc spLoaderOk
;
    CloseCFile
    stc
    jmp spDone

spLoaderOk:    
    call AllocateProcess
    mov gs:pr_loader,ax
    mov gs:pr_kernel_file,bx
;
    push ds
    GetThread
    mov gs:pr_parent_thread,ax
    mov ds,ax
    mov ds,ds:p_app_sel
    mov gs:pr_parent_app_sel,ds
    mov eax,ds:app_loader_name
    mov gs:pr_loader_name,eax
    pop ds
;
    call CreateProg
;
    mov eax,es:[edi].lp_param_sel
    or ax,3
    verr ax
    stc
    jnz spNoParam
;
    mov ds,ax
    mov esi,es:[edi].lp_param_offs
    call CreateParam
    jmp spParamDone

spNoParam:
    call CreateNoParam

spParamDone:
    mov eax,es:[edi].lp_startdir_sel
    or ax,3
    verr ax
    stc
    jnz spNoStartDir
;
    mov ds,ax
    mov esi,es:[edi].lp_startdir_offs
    call CreateStartDir
    jmp spStartDirDone

spNoStartDir:
    call CreateDefaultStartDir

spStartDirDone:
    mov eax,es:[edi].lp_env_sel
    or ax,3
    verr ax
    stc
    jnz spNoEnv
;
    mov ds,ax
    mov esi,es:[edi].lp_env_offs
    call CreateEnv
    jmp spEnvDone

spNoEnv:
    call CreateDefaultEnv

spEnvDone:
    mov ebx,gs
    call ProcessCreated
    mov ebx,eax
    ClearSignal
;
    mov es,gs:pr_name_sel
    xor edi,edi
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET spawn_startup
    mov ax,2
    mov ecx,stack0_size
    CreateProcess

spWait:    
    WaitForSignal
    mov ax,gs:pr_thread
    or ax,ax
    jz spWait
;
    mov es,ax
    mov ax,es:p_id
;
    mov ax,gs:pr_debug_sel
    or ax,ax
    jz spLibOk
;
    mov es,gs:pr_app_sel
    mov ax,es:app_mod_sel

spLibOk:
    mov dx,bx
    clc
    jmp spDone

spInvalid:
    stc
    jmp spDone

spOk:
    clc   

spDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop gs
    pop es
    pop ds
    ret
spawn_program   Endp
    
spawn_program16 Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call spawn_program
;
    pop edi
    pop esi
    ret
spawn_program16 Endp
    
spawn_program32 Proc far
    call spawn_program
    ret
spawn_program32 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           load_program16/32
;
;       DESCRIPTION:    Load executable file
;
;       PARAMETERS:     DS:(E)SI    Filename
;                       ES:(E)DI    Parameters
;                           +0  command line
;                           +8  startdir
;                           +12 env
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_program_name   DB 'Load Program',0

load_program   Proc near
    push ds
    push es
    push gs
    push ebx
    push ecx
    push esi
    push edi
;
    call OpenProgramFile
    jc lpFail
;
    call GetProgramLoader
    jnc lpLoaderOk
;
    CloseCFile
    jmp lpFail

lpLoaderOk:    
    call AllocateProcess
    mov gs:pr_loader,ax
    mov gs:pr_kernel_file,bx
;
    call CreateProg
;
    mov eax,es:[edi].lp_param_sel
    or ax,3
    verr ax
    stc
    jnz lpNoParam
;
    mov ds,ax
    mov esi,es:[edi].lp_param_offs
    call CreateParam
    jmp lpParamDone

lpNoParam:
    call CreateNoParam

lpParamDone:
    mov eax,es:[edi].lp_startdir_sel
    or ax,3
    verr ax
    stc
    jnz lpNoStartDir
;
    mov ds,ax
    mov esi,es:[edi].lp_startdir_offs
    call CreateStartDir
    jmp lpStartDirDone

lpNoStartDir:
    call CreateDefaultStartDir

lpStartDirDone:
    mov eax,es:[edi].lp_env_sel
    or ax,3
    verr ax
    stc
    jnz lpNoEnv
;
    mov ds,ax
    mov esi,es:[edi].lp_env_offs
    call CreateEnv
    jmp lpEnvDone

lpNoEnv:
    call CreateDefaultEnv

lpEnvDone:
    mov ebx,gs
    call ProcessCreated
    mov ebx,eax
;
    GetThread
    mov es,ax
    call RemoveProgramThread
;
    mov es:p_prog_id,bx
    call AddProgramThread
;
    push gs
    ExecApp
    pop gs
;
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
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov es:app_context,bx
;    mov es:app_unload_proc,OFFSET lepRet
    AppNotifyExec
;
    GetThread
    mov es,ax
    xor esi,esi
    mov ds,gs:pr_name_sel
    mov edi,OFFSET thread_name
    mov ecx,32

lpThreadNameLoop:
    lodsb
    or al,al
    jz lpThreadNamePad
;
    stosb
    loop lpThreadNameLoop

lpThreadNamePad:
    or ecx,ecx
    jz lpThreadNameDone
;
    mov al,' '
    rep stosb

lpThreadNameDone:
    mov es,es:p_app_sel
    xor esi,esi
    mov ds,gs:pr_name_sel
    mov edi,OFFSET app_exe_name

lpCpExeLoop:
    lodsb
    stosb
    or al,al
    jne lpCpExeLoop
;
    xor bx,bx
;
    call SetupStartDir
    call SetupEnv
;       
    mov bx,gs:pr_kernel_file
    xor esi,esi
    xor edi,edi
    mov ds,gs:pr_name_sel
    mov es,gs:pr_cmd_sel
;
    push gs
    mov gs,gs:pr_loader
    call fword ptr gs:loader_load_exe_proc
    pop gs
    jc lpLoadFail
;
    mov gs:el_ret_code,0
;
    test byte ptr [bp+2].load_eflags,2
    jnz lpVm16
;
    mov ds,[bp].load_ds
    mov es,[bp].load_es
    mov fs,[bp].load_fs
    mov gs,[bp].load_gs

lpVm16:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

lpLoadFail:
    int 3

lpFail:
    stc
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop gs
    pop es
    pop ds
    ret
load_program    Endp
    
load_program16 Proc far
    push ebx
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    movzx ebx,bx
    call load_program
;
    pop edi
    pop esi
    pop ebx
    retf32
load_program16  Endp
    
load_program32 Proc far
    call load_program
    retf32
load_program32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           unload_exe
;
;           DESCRIPTION:    Unload running program
;
;           PARAMETERS:         AX          Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_exe_name DB 'Unload Exe',0
    
unload_exe:
    int 3
    push ax
    GetThread
    mov ds,ax
    pop ax
;       
    mov ds,ds:p_process_sel
    mov ds,ds:ms_pd_sel
    mov ds:pd_exit_code,ax
;
    push ax
    GetThread
    mov ds,ax
    pop ax
    mov ds,ds:p_app_sel
    jmp ds:app_unload_proc    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForExec
;
;           DESCRIPTION:    Wait for exec
;
;           PARAMETERS:     AX          Forked ID
;
;           RETURNS:        AX          Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_exec_name DB 'Wait For Exec',0
    
wait_for_exec   Proc far
    ret
wait_for_exec   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetExitCode
;
;           DESCRIPTION:    Get exit code
;
;           RETURNS:        AX          Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exit_code_name DB 'Get Exit Code',0
    
get_exit_code   Proc far
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ax,ds:app_exit_code
    pop ds
    ret
get_exit_code   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleCount
;
;           DESCRIPTION:    Get number of modules
;
;           RETURNS:        AX          Module count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_count_name DB 'Get Module Count',0
    
get_module_count   Proc far
    call GetActiveModules
    clc
    ret
get_module_count   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleInfo
;
;           DESCRIPTION:    Get module info
;
;           PARAMETERS:     AX          Module #
;                           ES:(E)DI    Name buffer
;                           (E)CX       Size of buffer
;
;           RETURNS:        DX          module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_info_name DB 'Get Module Info',0
    
get_module_info    Proc near
    push ds
    push eax
    push ebx
    push esi
    push edi
;
    call GetModuleID
    or eax,eax
    stc
    jz gmiDone
;
    mov edx,eax
    mov ebx,eax
    call GetModuleSel
    or eax,eax
    stc
    jz gmiDone
;
    mov ds,eax
    movzx esi,ds:mod_name_offs

gmiCopyLoop:
    lodsb
    stosb
    or al,al
    jz gmiCopyDone
;
    loop gmiCopyLoop
;
    xor al,al
    mov es:[edi-1],al

gmiCopyDone:
    clc

gmiDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
get_module_info    Endp

get_module_info16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_module_info
;
    pop edi
    pop ecx
    ret
get_module_info16   Endp

get_module_info32   Proc far
    call get_module_info
    ret
get_module_info32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleSel
;
;           DESCRIPTION:    Get module sel
;
;           PARAMETERS:     BX          Module ID
;
;           RETURNS:        AX          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_sel_name DB 'Get Module Sel',0
    
get_module_sel    Proc far
    push ds
;
    movzx ebx,bx
    call GetModuleSel
    or eax,eax
    stc
    jz gmsDone
;
    mov ds,eax
    mov ax,ds:mod_sel
    clc

gmsDone:
    pop ds
    ret
get_module_sel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleBase
;
;           DESCRIPTION:    Get module base
;
;           PARAMETERS:     BX          Module ID
;
;           RETURNS:        EDX:EAX     Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_base_name DB 'Get Module Base',0
    
get_module_base    Proc far
    push ds
;
    movzx ebx,bx
    call GetModuleSel
    or eax,eax
    stc
    jz gmbDone
;
    mov ds,eax
    mov eax,ds:mod_base
    mov edx,ds:mod_base+4
    clc

gmbDone:
    pop ds
    ret
get_module_base    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleSize
;
;           DESCRIPTION:    Get module size
;
;           PARAMETERS:     BX          Module ID
;
;           RETURNS:        EDX:EAX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_size_name DB 'Get Module Size',0
    
get_module_size    Proc far
    push ds
;
    movzx ebx,bx
    call GetModuleSel
    or eax,eax
    stc
    jz gmszDone
;
    mov ds,eax
    mov eax,ds:mod_size
    mov edx,ds:mod_size+4
    clc

gmszDone:
    pop ds
    ret
get_module_size    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProgramCount
;
;           DESCRIPTION:    Get number of programs
;
;           RETURNS:        AX          Program count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_count_name DB 'Get Program Count',0
    
get_program_count   Proc far
    call GetActiveProcesses
    clc
    ret
get_program_count   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProgramInfo
;
;           DESCRIPTION:    Get program info
;
;           PARAMETERS:     AX          Program #
;                           ES:(E)DI    Name buffer
;                           (E)CX       Size of buffer
;
;           RETURNS:        DX          process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_info_name DB 'Get Program Info',0
    
get_program_info    Proc near
    push ds
    push eax
    push ebx
    push esi
    push edi
;
    call GetProcessID
    or eax,eax
    stc
    jz gpiDone
;
    mov edx,eax
    mov ebx,eax
    call GetProcessSel
    or eax,eax
    stc
    jz gpiDone
;
    mov ds,eax
    mov ds,ds:pr_name_sel
    xor esi,esi

gpiCopy:
    lodsb
    stosb
    or al,al
    jz gpiOk
;
    loop gpiCopy
;
    xor al,al
    mov es:[edi-1],al

gpiOk:
    clc

gpiDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
get_program_info    Endp

get_program_info16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_program_info
;
    pop edi
    pop ecx
    ret
get_program_info16   Endp

get_program_info32   Proc far
    call get_program_info
    ret
get_program_info32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProgramThreads
;
;           DESCRIPTION:    Get program threads
;
;           PARAMETERS:     AX          Program #
;                           ES:(E)DI    Thread ID buffer (2 bytes per entry)
;                           (E)CX       Max thread ids
;
;           RETURNS:        ECX         Actual threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_threads_name DB 'Get Program Threads',0
    
get_program_threads    Proc near
    push ds
    push ebx
    push edx
    push esi
    push edi
;
    call GetProcessID
    or eax,eax
    stc
    jz gptDone
;
    mov edx,eax
    mov ebx,eax
    call GetProcessSel
    or eax,eax
    stc
    jz gptDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx edx,ds:pr_thread_count
    mov esi,OFFSET pr_thread_arr

gptCopy:
    or edx,edx
    jz gptLeave
;
    dec edx
    lodsw
    stosw
    loop gptCopy

gptLeave:
    movzx ecx,ds:pr_thread_count
    LeaveSection ds:pr_section
    clc

gptDone:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
get_program_threads    Endp

get_program_threads16   Proc far
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_program_threads
;
    pop edi
    ret
get_program_threads16   Endp

get_program_threads32   Proc far
    call get_program_threads
    ret
get_program_threads32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProgramModules
;
;           DESCRIPTION:    Get program modules
;
;           PARAMETERS:     AX          Program #
;                           ES:(E)DI    Module ID buffer (2 bytes per entry)
;                           (E)CX       Max module ids
;
;           RETURNS:        ECX         Actual modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_program_modules_name DB 'Get Program Modules',0
    
get_program_modules    Proc near
    push ds
    push ebx
    push edx
    push esi
    push edi
;
    call GetProcessID
    or eax,eax
    stc
    jz gpmDone
;
    mov edx,eax
    mov ebx,eax
    call GetProcessSel
    or eax,eax
    stc
    jz gpmDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx edx,ds:pr_module_count
    mov esi,OFFSET pr_module_arr

gpmCopy:
    or edx,edx
    jz gpmLeave
;
    dec edx
    lodsw
    stosw
    loop gpmCopy

gpmLeave:
    movzx ecx,ds:pr_module_count
    LeaveSection ds:pr_section
    clc

gpmDone:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
get_program_modules    Endp

get_program_modules16   Proc far
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_program_modules
;
    pop edi
    ret
get_program_modules16   Endp

get_program_modules32   Proc far
    call get_program_modules
    ret
get_program_modules32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockProgramModuleList
;
;           DESCRIPTION:    Lock program module list
;
;           PARAMETERS:     BX          Process ID
;
;           RETURNS:        ECX         Actual modules
;                           ES:EDI      Program module arr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_program_module_list_name DB 'Lock Program Module List',0
    
lock_program_module_list    Proc far
    push ds
;
    call GetProcessSel
    or eax,eax
    stc
    jz lpmlDone
;
    mov ds,eax
    mov es,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_module_count
    mov edi,OFFSET pr_module_arr
    clc

lpmlDone:
    pop ds
    ret
lock_program_module_list    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockProgramModuleList
;
;           DESCRIPTION:    Unlock program module list
;
;           PARAMETERS:     ES:EDI      Program module arr                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_program_module_list_name DB 'Unlock Program Module List',0
    
unlock_program_module_list    Proc far
    push ds
;
    mov ax,es
    mov ds,ax
    LeaveSection ds:pr_section
;
    pop ds
    ret
unlock_program_module_list    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddKernelModule
;
;           DESCRIPTION:    Add kernel module
;
;           PARAMETERS:     BX          Selector
;                           EDX         Base
;                           ECX         Size
;                           ES:EDI      Module name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddKernelModule     PROC near
    push ds
    push es
    pushad
;
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    mov ebp,ecx
    xor ecx,ecx

akmSizeLoop:
    inc ecx
    lodsb
    or al,al
    jne akmSizeLoop
;
    mov eax,SIZE module_struc
    add eax,ecx
    AllocateSmallGlobalMem
    mov es:mod_base,edx
    mov es:mod_base+4,0
    mov es:mod_size,ebp
    mov es:mod_size+4,0
    mov es:mod_sel,bx
    mov es:mod_name_offs,SIZE module_struc
    mov es:mod_loader,0
    mov es:mod_id,0
    InitSection es:mod_section
;
    mov esi,edi
    mov edi,SIZE module_struc
    rep movsb
;
    mov ebx,es
    call ModuleLoaded
;
    mov ebx,eax
    call AddKernelProgramModule
;
    popad
    pop es
    pop ds
    ret
AddKernelModule     Endp

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
    push fs
    pushad
;
    mov esi,edx
    add esi,SIZE rdos_header
    call OpenProgramFile
    jc rpFail
;
    call GetProgramLoader
    jnc rpLoaderOk
;
    CloseCFile
    stc
    jmp rpFail

rpLoaderOk:
    call AllocateProcess
    mov gs:pr_kernel_file,bx
    mov gs:pr_loader,ax
;
    GetThread
    mov gs:pr_parent_thread,ax
    mov gs:pr_parent_app_sel,0
;
    call CreateProg
    call CreateNoParam
    call CreateDefaultStartDir
    call CreateDefaultEnv
;
    mov ebx,gs
    call ProcessCreated
    mov ebx,eax
;
    mov es,gs:pr_name_sel
    xor edi,edi
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET spawn_startup
    mov ax,2
    mov ecx,stack0_size
    CreateProcess
;
    WaitForSignal
;
    mov ax,25
    WaitMilliSec

rpFail:
    popad
    pop fs
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

kernel_code_text DB 'kernel.exe', 0

init_adapter_process    Proc near
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov ds,ax
    mov es,ax

init_adapter_process_loop:
    mov ax,[edx].typ
    cmp ax,RdosCommand
    jne not_run_process
;
    call run_process
    jmp init_adapter_process_next

not_run_process:
    cmp ax,RdosKernel
    jne adapter_not_kernel
;
    push es
    push edx
    mov bx,kernel_code
    GetSelectorBaseSize
    mov eax,cs
    mov es,eax
    mov edi,OFFSET kernel_code_text    
    xor edx,edx
    call AddKernelModule
    pop edx
    pop es
    jmp init_adapter_process_next

adapter_not_kernel:
    cmp ax,RdosDevice16
    jne adapter_not_device16
;
    push edx
    mov edi,edx
    add edi,SIZE rdos_header
    mov bx,ds:[edi].dev16_code_sel
    movzx ecx,ds:[edi].dev16_code_size
    add edi,SIZE device16_header
    xor edx,edx
    call AddKernelModule
    pop edx
    jmp init_adapter_process_next

adapter_not_device16:
    cmp ax,RdosDevice32
    jne adapter_not_device32
;
    push edx
    mov edi,edx
    add edi,SIZE rdos_header
    mov bx,ds:[edi].dev32_code_sel
    mov ecx,ds:[edi].dev32_code_size
    add edi,SIZE device32_header
    xor edx,edx
    call AddKernelModule
    pop edx
    jmp init_adapter_process_next

adapter_not_device32:
    cmp ax,RdosLongMode
    jne adapter_not_long
;
    push edx
    mov edi,edx
    add edi,SIZE rdos_header
    xor bx,bx
    mov ecx,ds:[edi].lm_image_size
    mov edx,ds:[edi].lm_image_base
    add edi,SIZE long_mode_header
    call AddKernelModule
    pop edx
    
adapter_not_long:
    cmp ax,RdosEnd
    je init_adapter_process_done

init_adapter_process_next:
    add edx,[edx].len
    jmp init_adapter_process_loop

init_adapter_process_done:
    popad
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

system_process_name DB "System", 0

    public InitScheduler_

InitScheduler_    Proc near
    push ds
    push es
    pushad
;
    mov bx,SEG data
    mov es,ebx
    mov es:state_hooks,0
    mov es:loader_count,0
;
    mov ecx,32
    mov edi,OFFSET state_arr
    
init_state_hooks:
    mov dword ptr es:[edi],OFFSET default_state
    mov es:[edi+4],cs
    add edi,8
    loop init_state_hooks
;
    push es
    push gs
    pushad
;
    call AllocateProcessBlock
    mov eax,7
    mov ecx,eax
    AllocateSmallGlobalMem
    mov esi,OFFSET system_process_name
    xor edi,edi
    rep movs byte ptr es:[edi],cs:[esi]
    mov gs:pr_name_sel,es
;
    mov ebx,gs
    call ProcessCreated
;
    popad
    pop gs
    pop es
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
    mov esi,OFFSET register_loader
    mov edi,OFFSET register_loader_name
    xor cl,cl
    mov ax,register_loader_nr
    RegisterOsGate
;
    mov esi,OFFSET start_programs
    mov edi,OFFSET start_programs_name
    xor cl,cl
    mov ax,start_programs_nr
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
    mov esi,OFFSET lock_program_module_list
    mov edi,OFFSET lock_program_module_list_name
    xor cl,cl
    mov ax,lock_program_module_list_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_program_module_list
    mov edi,OFFSET unlock_program_module_list_name
    xor cl,cl
    mov ax,unlock_program_module_list_nr
    RegisterOsGate
;
    mov esi,OFFSET module_id_to_sel
    mov edi,OFFSET module_id_to_sel_name
    xor cl,cl
    mov ax,module_id_to_sel_nr
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
    mov ebx,OFFSET load_program16
    mov esi,OFFSET load_program32
    mov edi,OFFSET load_program_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,load_exe_nr
    RegisterUserGate
;
    mov ebx,OFFSET spawn_program16
    mov esi,OFFSET spawn_program32
    mov edi,OFFSET spawn_exe_name
    mov dx,virt_es_in OR virt_ds_in
    mov ax,spawn_exe_nr
    RegisterUserGate
;
    mov esi,OFFSET unload_exe
    mov edi,OFFSET unload_exe_name
    xor dx,dx
    mov ax,unload_exe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_for_exec
    mov edi,OFFSET wait_for_exec_name
    xor dx,dx
    mov ax,wait_for_exec_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_exit_code
    mov edi,OFFSET get_exit_code_name
    xor dx,dx
    mov ax,get_exit_code_nr
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
    mov esi,OFFSET dupl_module_file_handle
    mov edi,OFFSET dupl_module_file_handle_name
    xor dx,dx
    mov ax,dupl_module_file_handle_nr
    RegisterBimodalUserGate
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
    mov esi,OFFSET get_module_count
    mov edi,OFFSET get_module_count_name
    xor dx,dx
    mov ax,get_module_count_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_module_info16
    mov esi,OFFSET get_module_info32
    mov edi,OFFSET get_module_info_name
    mov dx,virt_es_in
    mov ax,get_module_info_nr
    RegisterUserGate
;
    mov esi,OFFSET get_module_sel
    mov edi,OFFSET get_module_sel_name
    xor dx,dx
    mov ax,get_module_sel_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_base
    mov edi,OFFSET get_module_base_name
    xor dx,dx
    mov ax,get_module_base_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_size
    mov edi,OFFSET get_module_size_name
    xor dx,dx
    mov ax,get_module_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_program_count
    mov edi,OFFSET get_program_count_name
    xor dx,dx
    mov ax,get_program_count_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_program_info16
    mov esi,OFFSET get_program_info32
    mov edi,OFFSET get_program_info_name
    mov dx,virt_es_in
    mov ax,get_program_info_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_program_threads16
    mov esi,OFFSET get_program_threads32
    mov edi,OFFSET get_program_threads_name
    mov dx,virt_es_in
    mov ax,get_program_threads_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_program_modules16
    mov esi,OFFSET get_program_modules32
    mov edi,OFFSET get_program_modules_name
    mov dx,virt_es_in
    mov ax,get_program_modules_nr
    RegisterUserGate
;
    popad
    pop es
    pop ds
    ret
InitScheduler_    Endp

_TEXT    ENDS

    END
