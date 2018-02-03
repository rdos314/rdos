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
; HOOKS.ASM
; Hook manager
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386p

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def

code    SEGMENT byte use16 public 'CODE'

    assume cs:code

    
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
    mov ax,hook_sel
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
    mov ax,hook_sel
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
    mov ax,hook_sel
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
    mov ax,hook_sel
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
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HookAppActivity
;
;           DESCRIPTION:    Add hook for app activity
;
;           PARAMETERS:     ES:EDI       Activity table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_app_activity_name      DB 'Hook Open App',0

hook_app_activity   PROC far
    push ds
    push ax
    push bx
    mov ax,app_activity_sel
    mov ds,ax
    mov al,ds:app_activity_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET app_activity_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:app_activity_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_app_activity   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_app_activity
;
;           DESCRIPTION:    Init app activity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_hooks

init_hooks       Proc near
    push ds
    push es
    pushad
;
    mov bx,hook_sel
    mov eax,SIZE hook_data_struc
    AllocateFixedSystemMem
    mov ds,bx
    mov ds:create_thread_hooks,0
    mov ds:terminate_thread_hooks,0
    mov ds:create_process_hooks,0
    mov ds:init_tasking_hooks,0
;
    mov bx,app_activity_sel
    mov eax,SIZE app_activity_struc
    AllocateFixedSystemMem
    mov ds,bx
    mov ds:app_activity_hooks,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET hook_create_thread
    mov edi,OFFSET hook_create_thread_name
    xor cl,cl
    mov ax,hook_create_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_terminate_thread
    mov edi,OFFSET hook_terminate_thread_name
    xor cl,cl
    mov ax,hook_terminate_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_create_process
    mov edi,OFFSET hook_create_process_name
    xor cl,cl
    mov ax,hook_create_process_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_init_tasking
    mov edi,OFFSET hook_init_tasking_name
    xor cl,cl
    mov ax,hook_init_tasking_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_app_activity
    mov edi,OFFSET hook_app_activity_name
    xor cl,cl
    mov ax,hook_app_activity_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
init_hooks       Endp

code    ENDS

    END
