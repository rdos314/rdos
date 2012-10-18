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
; PROC.ASM
; Thread & process handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE ..\handle.inc
include proc.inc

thread_data_seg STRUC

create_thread_hooks         DB ?
terminate_thread_hooks  DB ?
create_process_hooks    DB ?
terminate_process_hooks DB ?
init_tasking_hooks          DB ?

create_process_arr      DD 2*32 DUP(?)
terminate_process_arr   DD 2*32 DUP(?)
create_thread_arr       DD 2*8 DUP(?)
terminate_thread_arr    DD 2*8 DUP(?)
init_tasking_arr        DD 2*64 DUP(?)

thread_data_seg ENDS


    .386p

code    SEGMENT byte public use16 'CODE'

    extrn init_process_mem:near

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_THREAD
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_user_start:
    TerminateThread
terminate_user_end:

    public init_thread

init_thread     PROC near
    pusha
    push ds
;
    mov bx,proc_data_sel
    mov eax,SIZE thread_data_seg
    AllocateFixedSystemMem
    mov ds,bx
    xor ax,ax
    mov ds:create_thread_hooks,al
    mov ds:terminate_thread_hooks,al
    mov ds:create_process_hooks,al
    mov ds:terminate_process_hooks,al
    mov ds:init_tasking_hooks,al
;
    mov ax,system_data_sel
    mov ds,ax
    mov es,ax
    mov ds:next_pid,0
    mov di,OFFSET thread_arr
    mov cx,256
    xor ax,ax
    rep stosw
;
    mov eax,OFFSET terminate_user_end - OFFSET terminate_user_start
    AllocateSmallLinear
    mov bx,term_code_sel
    mov ecx,eax
    CreateDataSelector16
;
    mov es,bx
    xor di,di
    mov ax,cs
    mov ds,ax
    mov si,OFFSET terminate_user_start
    mov cx,OFFSET terminate_user_end - OFFSET terminate_user_start
    rep movsb
    and bx,0FFF8h
    mov ax,gdt_sel
    mov ds,ax
    mov byte ptr [bx+5],0FAh
;
    mov edx,fixed_process_linear
    mov ecx,SIZE process_seg
    mov bx,process_sel
    CreateDataSelector16
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov si,OFFSET hook_create_thread
    mov di,OFFSET hook_create_thread_name
    xor cl,cl
    mov ax,hook_create_thread_nr
    RegisterOsGate
;
    mov si,OFFSET hook_terminate_thread
    mov di,OFFSET hook_terminate_thread_name
    xor cl,cl
    mov ax,hook_terminate_thread_nr
    RegisterOsGate
;
    mov si,OFFSET hook_create_process
    mov di,OFFSET hook_create_process_name
    xor cl,cl
    mov ax,hook_create_process_nr
    RegisterOsGate
;
    mov si,OFFSET hook_terminate_process
    mov di,OFFSET hook_terminate_process_name
    xor cl,cl
    mov ax,hook_terminate_process_nr
    RegisterOsGate
;
    mov si,OFFSET hook_init_tasking
    mov di,OFFSET hook_init_tasking_name
    xor cl,cl
    mov ax,hook_init_tasking_nr
    RegisterOsGate
;
    pop ds
    popa
    ret
init_thread     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_CREATE_THREAD
;
;           DESCRIPTION:    Handle CreateThread hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public trap_create_thread

trap_create_thread      PROC near
    sti
    push cx
    mov ax,system_data_sel
    mov es,ax
    mov di,OFFSET thread_arr
    xor ax,ax
    mov cx,256
    repne scasw
    GetThread
    sub di,2
    stosw
;
    mov ax,proc_data_sel
    mov ds,ax
    mov cl,ds:create_thread_hooks
    or cl,cl
    je trap_create_thread_done
    mov bx,OFFSET create_thread_arr
trap_create_thread_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_create_thread_loop
trap_create_thread_done:
    pop cx
    retf
trap_create_thread      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_TERMINATE_THREAD
;
;           DESCRIPTION:    Handle TerminateThread hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public trap_terminate_thread

trap_terminate_thread   PROC near
    push cx
    mov ax,proc_data_sel
    mov ds,ax
    mov cl,ds:terminate_thread_hooks
    or cl,cl
    je trap_terminate_thread_done
    mov bx,OFFSET terminate_thread_arr
trap_terminate_thread_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_terminate_thread_loop
trap_terminate_thread_done:
    mov ax,system_data_sel
    mov ds,ax
    mov es,ax
    mov di,OFFSET thread_arr
    GetThread
    mov cx,256
    repne scasw
    sub di,2
    xor ax,ax
    stosw
    pop cx
    ret
trap_terminate_thread   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_CREATE_PROCESS
;
;           DESCRIPTION:    Handle CreateProcess hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public trap_create_process

trap_create_process     PROC near
    sti
    push cx
    push si
;    
    call init_process_mem
;
    mov ax,proc_data_sel
    mov ds,ax
    mov cl,ds:create_process_hooks
    or cl,cl
    je trap_create_process_done
    mov bx,OFFSET create_process_arr
trap_create_process_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_create_process_loop
trap_create_process_done:
    pop si
    pop cx
;
    xor ebp,ebp
    push cs
    call trap_create_thread
    ret
trap_create_process     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_TERMINATE_PROCESS
;
;           DESCRIPTION:    Handle TerminateProcess hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public trap_terminate_process

trap_terminate_process  PROC near
    push cx
    mov ax,proc_data_sel
    mov ds,ax
    mov cl,ds:terminate_process_hooks
    or cl,cl
    je trap_terminate_process_done
    mov bx,OFFSET terminate_process_arr
trap_terminate_process_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_terminate_process_loop
trap_terminate_process_done:
    pop cx
    ret
trap_terminate_process  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_INIT_TASKING
;
;           DESCRIPTION:    Handle init-tasking hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public trap_init_tasking
    
trap_init_tasking       PROC near
    InitTrapGates
    InitTssGates
    call trap_create_process
    push cx
    mov ax,proc_data_sel
    mov ds,ax
    mov cl,ds:init_tasking_hooks
    or cl,cl
    je trap_init_tasking_done
    mov bx,OFFSET init_tasking_arr
trap_init_tasking_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_init_tasking_loop
trap_init_tasking_done:
    pop cx
    ret
trap_init_tasking       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_CREATE_THREAD
;
;           DESCRIPTION:    Add CreateThread hook
;
;           PARAMETERS:         ES:EDI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_create_thread_name DB 'Hook Create Thread',0

hook_create_thread      PROC far
    push ds
    push ax
    push bx
    mov ax,proc_data_sel
    mov ds,ax
    mov al,ds:create_thread_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET create_thread_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:create_thread_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_create_thread      ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_TERMINATE_THREAD
;
;           DESCRIPTION:    Add TerminateThread hook
;
;           PARAMETERS:     ES:EDI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_terminate_thread_name      DB 'Hook Terminate Thread',0

hook_terminate_thread   PROC far
    push ds
    push ax
    push bx
    mov ax,proc_data_sel
    mov ds,ax
    mov al,ds:terminate_thread_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET terminate_thread_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:terminate_thread_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_terminate_thread   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_CREATE_PROCESS
;
;           DESCRIPTION:    Add CreateProcess hook
;
;           PARAMETERS:     ES:EDI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_create_process_name    DB 'Hook Create Process',0

hook_create_process     PROC far
    push ds
    push ax
    push bx
    mov ax,proc_data_sel
    mov ds,ax
    mov al,ds:create_process_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET create_process_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:create_process_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_create_process     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_TERMINATE_PROCESS
;
;           DESCRIPTION:    Add TerminateProcess hook
;
;           PARAMETERS:         ES:DI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_terminate_process_name     DB 'Hook Terminate Process',0

hook_terminate_process  PROC far
    push ds
    push ax
    push bx
    mov ax,proc_data_sel
    mov ds,ax
    mov al,ds:terminate_process_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET terminate_process_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:terminate_process_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_terminate_process  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_INIT_TASKING
;
;           DESCRIPTION:    Add init-tasking hook
;
;           PARAMETERS:         ES:EDI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_init_tasking_name  DB 'Hook Init Tasking',0

hook_init_tasking       PROC far
    push ds
    push ax
    push bx
    mov ax,proc_data_sel
    mov ds,ax
    mov al,ds:init_tasking_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET init_tasking_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:init_tasking_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_init_tasking       ENDP

    
code    ENDS

    END

