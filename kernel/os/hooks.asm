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
    popad
    pop es
    pop ds
    ret
init_hooks       Endp

code    ENDS

    END
