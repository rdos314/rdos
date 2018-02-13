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
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE exec.def
INCLUDE chandle.inc

    .686p

data    SEGMENT byte public 'DATA'

term_gate_sel       DW ?
state_hooks         DW ?
state_arr           DD 2*32 DUP(?)

data    ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn IdToHandle:near
    extrn IndexToHandle:near
    extrn MoveThread:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Upper case table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UCaseTab:
ct00 DB 0,          0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct08 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct10 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct18 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct20 DB ' ',    '!',    0FFh,   '#',    '$',    '%',    '&',    27h
ct28 DB '(',    ')',    0FFh,   0FFh,   0FFh,   '-',    0,          '/'
ct30 DB '0',    '1',    '2',    '3',    '4',    '5',    '6',    '7'
ct38 DB '8',    '9',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct40 DB '@',    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct48 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct50 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct58 DB 'X',    'Y',    'Z',    0FFh,   '\',    0FFh,   '^',    '_'
ct60 DB 60h,    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct68 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct70 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct78 DB 'X',    'Y',    'Z',    '{',    0FFh,   '}',    '~',    0FFh
ct80 DB 0FFh,   0FFh,   0FFh,   0FFh,   'é',    0FFh,   'è',    0FFh
ct88 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   'é',    'è'
ct90 DB 0FFh,   0FFh,   0FFh,   0FFh,   'ô',    0FFh,   0FFh,   0FFh
ct98 DB 0FFh,   'ô',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctA0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctA8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctB0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctB8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctC0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctC8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctD0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctD8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctE0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctE8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctF0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctF8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh

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
    GetProgramSel
    jc aptDone
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
    GetProgramSel
    jc rptDone
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
;           NAME:           AppThreadStarted
;
;           DESCRIPTION:    Startup of app thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_thread_started:
    push eax
    pushfd
    pop eax
    mov [esp+8],eax
    mov eax,[esp+4]
    xchg eax,[esp]
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    mov dword ptr [ebp].load_cs,flat_code_sel
;
    push ds
    push es
    push fs
    push gs
;
    GetThread
    mov ds,ax
    mov ds,ds:p_loader
    call fword ptr ds:loader_start_thread_proc
;
    pop gs
    pop fs
    pop es
    pop ds
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateAppThread
;
;           DESCRIPTION:    Create application thread
;
;           PARAMETERS:     DS          New thread 
;                           ECX         User stack size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_app_thread_name  DB 'Create App Thread', 0

create_app_thread    Proc far
    push es
    push eax
    push ebx
    push edx
;
    GetThread
    mov es,ax
    mov es,es:p_loader
;
    mov eax,ecx
    call fword ptr es:loader_init_thread_proc
;
    mov ax,ds:p_ss
    test al,3
    jnz catStackOk
; 
    mov eax,ecx
    call fword ptr es:loader_allocate_mem_proc
    mov ds:p_ss,flat_data_sel
    mov dword ptr ds:p_rsp,edx

catStackOk:
    mov ax,ds:p_cs
    cmp ax,flat_code_sel
    je catFlat
;
    int 3

catFlat:
    mov edx,dword ptr ds:p_rsp
;
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov es,eax
    mov ebx,stack0_size
;
    sub ebx,4
    mov eax,flat_data_sel
    mov es:[ebx],eax
;
    sub ebx,4
    mov es:[ebx],edx
;
    sub ebx,4
    movzx eax,ds:p_cs
    mov es:[ebx],eax
;
    sub ebx,4
    mov eax,dword ptr ds:p_rip
    mov es:[ebx],eax
;
    mov dword ptr ds:p_rsp,ebx
;
    mov ax,cs
    mov ds:p_cs,ax
    mov dword ptr ds:p_rip,OFFSET app_thread_started
;
    pop edx
    pop ebx
    pop eax
    pop es
    ret
create_app_thread       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TerminateAppThreadKernel
;
;           DESCRIPTION:    Terminate application thread, callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


terminate_app_thread_kernel:
    GetThread
    mov es,ax
    mov es,es:p_loader
    call fword ptr es:loader_free_thread_kernel_proc
;
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TerminateAppThread
;
;           DESCRIPTION:    Terminate application thread with user stack
;
;           PARAMETERS:     EBP         Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_app_thread_name  DB 'Terminate App Thread', 0

terminate_app_thread:
    add esp,8
    push ds
    push es
    push fs
    push gs
;
    mov ax,SEG data
    mov ds,ax
;
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    sub edi,16
    mov [ebp].load_esp,edi
    mov [ebp].load_eip,edi
;
    mov al,9Ah
    stosb
;
    xor eax,eax
    stosd
;
    mov ax,ds:term_gate_sel
    stosw
;
    GetThread
    mov es,ax
    mov es,es:p_loader
    call fword ptr es:loader_free_thread_user_proc
;
    pop gs
    pop fs
    pop es
    pop ds
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

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
    mov ds,ebx
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
;    
    ModuleIdToSel
    jc dupl_module_file_handle_done
;
    mov ds,ebx
    mov bx,ds:mod_c_file_handle
    DuplCFileToFile
    clc

dupl_module_file_handle_done:
    pop ds    
    ret
dupl_module_file_handle  Endp
    
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
;           NAME:           OpenModuleFile
;
;           DESCRIPTION:    Open module file
;
;           PARAMETERS:     DS:ESI  File name
;
;           RETURNS:        BX          C File handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PathName        DB 'PATH',0

OpenModuleFile Proc near       
    push ds
    push es
    push fs
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,ds
    mov es,eax
    mov edi,esi
;
    mov cx,O_RDONLY OR O_BINARY
    OpenKernelFile
    jnc omfDone
;
    mov eax,ds
    mov fs,eax
;
    LockProcEnv
    mov ds,bx
    mov ebx,esi
    xor esi,esi
    mov ax,cs
    mov es,ax
    mov edi,OFFSET PathName

omfFindLoop:
    cmpsb
    jnz omfFindNext
;
    mov al,es:[edi]
    or al,al
    jnz omfFindLoop
;
    mov al,[esi]
    cmp al,'='
    je omfFindFound

omfFindNext:
    lodsb
    or al,al
    jnz omfFindNext
;
    mov al,[esi]
    or al,al
    mov edi,OFFSET PathName
    jne omfFindLoop
    jmp omfFailed

omfFindFound:
    mov eax,200h
    AllocateSmallGlobalMem
;
    xor edi,edi
    inc esi

omfMoveLoop:
    lodsb
    or al,al
    jz omfMoveOk
;
    cmp al,';'
    je omfMoveOk
;
    stosb
    jmp omfMoveLoop 

omfMoveOk:
    or edi,edi
    jz omfAddFile
;    
    mov al,es:[edi-1]
    cmp al,'\'
    je omfAddFile
;
    cmp al,'/'
    je omfAddFile
;
    cmp al,':'
    je omfAddFile
;
    mov al,'\'
    stosb
    
omfAddFile:    
    push ebx

omfNameLoop:
    mov al,fs:[ebx]
    inc ebx
    stosb
    or al,al
    jnz omfNameLoop
;
    pop ebx
;
    push bx
    xor edi,edi
    mov cx,O_RDONLY OR O_BINARY
    OpenKernelFile
    jnc omfFileOk
;
    pop bx
    mov al,[esi-1]
    or al,al
    jnz omfMoveLoop
;
    FreeMem

omfFailed:
    stc
    jmp omfUnlock

omfFileOk:
    add esp,2
    FreeMem
    clc
    
omfUnlock:
    pushf
    UnlockProcEnv
    popf

omfDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    pop fs
    pop es
    pop ds
    ret
OpenModuleFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AppPatch
;
;       DESCRIPTION:    Patch app
;
;       DESCRIPTION:    App specific usergate patching
;
;       PARAMETERS:     DS:EBX      Instruction to patch
;                       EAX         Gate #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_patch_name DB 'App Patch', 0

app_patch Proc far
    push fs
    push gs
;
    push eax
    GetThread
    mov gs,ax
    mov ax,gs:p_loader
    or ax,ax
    mov fs,ax
    stc
    pop eax
    jz apDone
;
    mov gs,gs:p_prog_sel
    call fword ptr fs:loader_patch_proc

apDone:
    pop gs
    pop fs
    ret
app_patch Endp

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
    GetModuleId
    jc gmiDone
;
    mov edx,eax
    mov ebx,eax
    ModuleIdToSel
    jc gmiDone
;
    mov ds,ebx
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
    push ebx
;
    movzx ebx,bx
    ModuleIdToSel
    jc gmsDone
;
    mov ds,ebx
    mov ax,ds:mod_sel
    clc

gmsDone:
    pop ebx
    pop ds
    ret
get_module_sel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDll
;
;           DESCRIPTION:    Get DLL handle
;
;       PARAMETERS:         ES:(E)DI    DLL name
;                           
;           RETURNS:        EBX         DLL handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dll_handle_name     DB 'Get DLL',0

get_dll_handle  Proc near
    push es
    push fs
    push eax
    push esi
;
    mov eax,es
    mov fs,eax
    mov esi,edi
;
    GetThread
    mov es,eax
    movzx ebx,es:p_prog_id
    FindModuleByName
    jc gdhDone
;
    ModuleIdToSel
    jc gdhDone
;
    mov es,ebx
    movzx ebx,es:mod_id
    clc

gdhDone:
    pop esi
    pop eax
    pop fs
    pop es
    ret
get_dll_handle  Endp

get_dll_handle16   Proc far
    push edi
;
    movzx edi,di
    call get_dll_handle
;
    pop edi
    ret
get_dll_handle16   Endp

get_dll_handle32   Proc far
    call get_dll_handle
    ret
get_dll_handle32   Endp

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
    push ebx
;
    movzx ebx,bx
    ModuleIdToSel
    jc gmbDone
;
    mov ds,ebx
    mov eax,ds:mod_base
    mov edx,ds:mod_base+4
    clc

gmbDone:
    pop ebx
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
    push ebx
;
    movzx ebx,bx
    ModuleIdToSel
    jc gmszDone
;
    mov ds,ebx
    mov eax,ds:mod_size
    mov edx,ds:mod_size+4
    clc

gmszDone:
    pop ebx
    pop ds
    ret
get_module_size    Endp

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
    GetProgramId
    jc gpiDone
;
    mov edx,eax
    mov ebx,eax
    GetProgramSel
    jc gpiDone
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
    GetProgramId
    jc gptDone
;
    mov edx,eax
    mov ebx,eax
    GetProgramSel
    jc gptDone
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
    GetProgramId
    jc gpmDone
;
    mov edx,eax
    mov ebx,eax
    GetProgramSel
    jc gpmDone
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
;           NAME:           GetModuleByIndex
;
;           DESCRIPTION:    Get module for a DLL or app module by index
;
;           PARAMETERS:     BX          Process ID
;                           AX          Entry #
;
;           RETURNS:        BX          Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_by_index_name DB 'Get Module By Index', 0

get_module_by_index Proc far
    push ds
    push eax
    push ecx
    push edx
;
    mov dx,ax
    movzx ebx,bx
    GetProgramSel
    jc gmbiDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    mov cx,ds:pr_module_count
    cmp dx,cx
    jae gmbiFail
;
    mov bx,dx
    add bx,bx
    mov bx,ds:[bx].pr_module_arr
    LeaveSection ds:pr_section
    clc
    jmp gmbiDone

gmbiFail:
    LeaveSection ds:pr_section
    stc

gmbiDone:
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
get_module_by_index Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindModuleByAddress
;
;           DESCRIPTION:    Search for a DLL or app module
;
;           PARAMETERS:     BX          Process ID
;                           EDX         Virtual adress
;
;           RETURNS:        AX          Entry #
;                           BX          Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_module_by_address_name DB 'Find Module By Address', 0

find_module_by_address Proc far
    push ds
    push es
    push ecx
    push esi
;
    movzx ebx,bx
    GetProgramSel
    jc fmbaDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_module_count
    mov esi,OFFSET pr_module_arr
;
    or ecx,ecx
    jz fmbaFail

fmbaLoop:
    movzx ebx,word ptr ds:[esi]
    ModuleIdToSel
    jc fmbaNext
;
    mov es,ebx
    mov eax,edx
    sub eax,es:mod_base
    jc fmbaNext
;       
    cmp eax,es:mod_size
    jc fmbaOk

fmbaNext:
    add esi,2
    loop fmbaLoop

fmbaFail:
    LeaveSection ds:pr_section
    stc
    jmp fmbaDone

fmbaOk:
    LeaveSection ds:pr_section
;
    mov eax,esi
    sub eax,OFFSET pr_module_arr
    shr eax,1
    mov bx,es:mod_id
    clc

fmbaDone:
    pop esi
    pop ecx
    pop es
    pop ds
    ret
find_module_by_address Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindModuleByName
;
;           DESCRIPTION:    Find module by name
;
;           PARAMETERS:     BX          Process ID
;                           FS:ESI      App / DLL NAME
;
;           RETURNS:        AX          Entry #
;                           BX          Module ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_module_by_name_name DB 'Find Module By Name', 0

find_module_by_name Proc far
    push ds
    push es
    push ecx
    push edi
    push ebp
;
    mov ebp,esi

fmbnRefLoop:
    mov al,fs:[ebp]
    or al,al
    jz fmbnRefOk
;
    inc ebp
    jmp fmbnRefLoop

fmbnRefOk:
    movzx ebx,bx
    GetProgramSel
    jc fmbnDone
;
    mov ds,eax
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_module_count
    mov edi,OFFSET pr_module_arr
;
    or ecx,ecx
    jz fmbnFail

fmbnLoop:
    movzx ebx,word ptr ds:[edi]
    ModuleIdToSel
    jc fmbnNext
;
    mov es,ebx
    movzx ebx,es:mod_name_offs
    mov ebp,esi

fmbnCheckName:
    mov al,es:[ebx]
    movzx edx,al
    mov al,byte ptr cs:[edx].UCaseTab
    mov ah,fs:[ebp]
    movzx edx,ah
    mov ah,byte ptr cs:[edx].UCaseTab
    cmp al,ah
    jne fmbnNext
;       
    or al,al
    je fmbnOk
;
    inc ebx
    inc ebp
    jmp fmbnCheckName

fmbnNext:
    add edi,2
    loop fmbnLoop

fmbnFail:
    LeaveSection ds:pr_section
    stc
    jmp fmbnDone

fmbnOk:
    LeaveSection ds:pr_section
;
    mov eax,edi
    sub eax,OFFSET pr_module_arr
    shr eax,1
    mov bx,es:mod_id
    clc

fmbnDone:
    pop ebp
    pop edi
    pop ecx
    pop es
    pop ds
    ret
find_module_by_name Endp

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
    AllocateGdt
    or bl,3
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET terminate_app_thread_kernel
    xor cl,cl
    CreateCallGateSelector32
    mov es:term_gate_sel,bx
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
    mov esi,OFFSET create_app_thread
    mov edi,OFFSET create_app_thread_name
    xor cl,cl
    mov ax,create_app_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET terminate_app_thread
    mov edi,OFFSET terminate_app_thread_name
    xor cl,cl
    mov ax,terminate_app_thread_nr
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
    mov esi,OFFSET get_module_by_index
    mov edi,OFFSET get_module_by_index_name
    xor cl,cl
    mov ax,get_module_by_index_nr
    RegisterOsGate
;
    mov esi,OFFSET find_module_by_address
    mov edi,OFFSET find_module_by_address_name
    xor cl,cl
    mov ax,find_module_by_address_nr
    RegisterOsGate
;
    mov esi,OFFSET find_module_by_name
    mov edi,OFFSET find_module_by_name_name
    xor cl,cl
    mov ax,find_module_by_name_nr
    RegisterOsGate
;
    mov esi,OFFSET alias_module_handle
    mov edi,OFFSET alias_module_handle_name
    xor cl,cl
    mov ax,alias_module_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET app_patch
    mov edi,OFFSET app_patch_name
    xor cl,cl
    mov ax,app_patch_nr
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
    mov esi,OFFSET get_module_focus_key
    mov edi,OFFSET get_module_focus_key_name
    xor dx,dx
    mov ax,get_module_focus_key_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_dll_handle16
    mov esi,OFFSET get_dll_handle32
    mov edi,OFFSET get_dll_handle_name
    mov dx,virt_es_in
    mov ax,get_module_nr
    RegisterUserGate
;
    mov esi,OFFSET dupl_module_file_handle
    mov edi,OFFSET dupl_module_file_handle_name
    xor dx,dx
    mov ax,dupl_module_file_handle_nr
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
