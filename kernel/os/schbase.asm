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

    .686p

data    SEGMENT byte public 'DATA'

state_hooks         DW ?
state_arr           DD 2*32 DUP(?)

next_tid            DW ?

thread_arr          DW 256 DUP(?)

data    ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT


test_gate_name db 'TEST', 0

test_gate   Proc far
    GetThread
    movzx eax,ax
    call ThreadTerminated
    ret
test_gate   Endp

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
    push eax
    push ecx
    push edi
;    
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET thread_arr
    xor eax,eax
    mov ecx,256
    repne scasw
    GetThread
    sub edi,2
    stosw
;
    mov cx,es:next_tid
    inc cx
    mov es:next_tid,cx
    mov es,ax
    mov es:p_id,cx
;
    movzx eax,ax
    call ThreadCreated
;
    pop edi
    pop ecx
    pop eax
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
    push es
    push eax
    push ecx
    push edi
;    
    GetThread
    movzx eax,ax
    call ThreadTerminated
;
    GetThread
    mov cx,SEG data
    mov es,ecx
    mov edi,OFFSET thread_arr
    mov ecx,256
    repne scasw
    sub edi,2
    xor eax,eax
    stosw
;
    pop edi
    pop ecx
    pop eax
    pop es   
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
    push ds
    push es
    push eax
    push ecx
    push esi
;    
    mov ecx,256
    mov ax,SEG data
    mov ds,eax
    xor esi,esi

thread_to_sel_loop:
    mov ax,ds:[esi].thread_arr
    or ax,ax
    jz thread_to_sel_next
;
    mov es,eax   
    cmp bx,es:p_id
    je thread_to_sel_found

thread_to_sel_next:
    add esi,2
    loop thread_to_sel_loop
;
    xor bx,bx
    stc    
    jmp thread_to_sel_done    

thread_to_sel_found:
    mov bx,es
    clc

thread_to_sel_done:
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds    
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
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    movzx ebx,ax
    shl ebx,1
    mov ax,SEG data
    mov ds,ax
    cli
    mov ax,ds:[ebx].thread_arr
    or ax,ax
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
    sti
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
    sti
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
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
    push eax
    push ebx
    push ecx
    push esi
;
    mov bx,ax
    mov ecx,256
    mov ax,SEG data
    mov ds,eax
    xor esi,esi

suspend_thread_loop:
    mov ax,ds:[esi].thread_arr
    or ax,ax
    jz suspend_thread_next
;
    mov es,ax   
    cmp bx,es:p_id
    je suspend_thread_found

suspend_thread_next:
    add esi,2
    loop suspend_thread_loop
;
    stc    
    jmp suspend_thread_done    

suspend_thread_found:
    or es:p_flags,THREAD_FLAG_SUSPEND
    clc

suspend_thread_done:
    pop esi
    pop ecx
    pop ebx
    pop eax
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
    push eax
    push ebx
    push ecx
    push esi
;
    mov bx,ax
    mov ecx,256
    mov ax,SEG data
    mov ds,eax
    xor esi,esi

suspend_signal_loop:
    mov ax,ds:[esi].thread_arr
    or ax,ax
    jz suspend_signal_next
;
    mov es,eax   
    cmp bx,es:p_id
    je suspend_signal_found

suspend_signal_next:
    add esi,2
    loop suspend_signal_loop
;
    stc    
    jmp suspend_signal_done    

suspend_signal_found:
    mov bx,es
    or es:p_flags,THREAD_FLAG_SUSPEND
    Signal
    sti
    clc

suspend_signal_done:
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
suspend_and_signal_thread       ENDP


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
    mov ebx,OFFSET get_thread_state16
    mov esi,OFFSET get_thread_state32
    mov edi,OFFSET get_thread_state_name
    mov dx,virt_es_in
    mov ax,get_thread_state_nr
    RegisterUserGate
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
    mov ebx,SEG data
    mov es,ebx
    mov es:state_hooks,0
    mov ecx,32
    mov edi,OFFSET state_arr
    
init_state_hooks:
    mov dword ptr es:[edi],OFFSET default_state
    mov es:[edi+4],cs
    add edi,8
    loop init_state_hooks
;
    mov ax,SEG data
    mov es,ax
    mov es:next_tid,0
    mov di,OFFSET thread_arr
    xor ax,ax
    mov cx,256
    rep stosw
;
    popad
    pop es
    pop ds
    ret
InitScheduler_    Endp

_TEXT    ENDS

    END
