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



    .386p

code    SEGMENT byte public use16 'CODE'

    extrn free_process_proc:word
    extrn init_double_fault:near
    extrn set_page_entry_proc:word

    assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           NotifyEndProgram
;
;           DESCRIPTION:    Notify program end
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_end_program_name  DB 'Notify End Program',0

notify_end_program       PROC far
    ExitProcessApp
    retf32
notify_end_program       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           NotifyInitTasking
;
;           DESCRIPTION:    Notify init tasking
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_init_tasking_name  DB 'Notify Init Tasking',0

notify_init_tasking       PROC far
    call init_double_fault
    retf32
notify_init_tasking       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           sim_sti
;
;           DESCRIPTION:    Simulate STI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_sti_name    DB 'Simulate Sti',0

sim_sti PROC far
    push ds
    push ax
    sti
    GetThread
    mov ds,ax
    mov ds,ds:p_process_sel
    mov ds:ms_virt_flags,7200h
sim_sti_test_wake:
    cmp ds:ms_wait_sti,0
    jz sim_sti_nowake
    push si
    mov si,OFFSET ms_wait_sti
    Wake
    pop si
    jmp sim_sti_test_wake
sim_sti_nowake:
    pop ax
    pop ds
    retf32
sim_sti ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           sim_cli
;
;           DESCRIPTION:    Simulate CLI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_cli_name    DB 'Simulate Cli',0

sim_cli PROC far
    push ds
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_process_sel
    cli
    mov ds:ms_cli_thread,ax
    mov ds:ms_virt_flags,7000h
    sti
    pop ax
    pop ds
    retf32
sim_cli ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           set_flags
;
;           DESCRIPTION:    Simulate set flags
;
;           PARAMETERS:         AX          FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_flags

set_flags       PROC near
    push ax
    GetThread
    mov ds,ax
    mov bx,ax
    pop ax
    mov ds,ds:p_process_sel
    cli
    mov ds:ms_cli_thread,bx
    mov bx,ax
    and bx,200h
    or bx,7000h
    mov ds:ms_virt_flags,bx
    sti
    test bx,200h
    jz set_flags_nowake
set_flags_test_wake:
    cmp ds:ms_wait_sti,0
    jz set_flags_nowake
    push si
    mov si,OFFSET ms_wait_sti
    Wake
    pop si
    jmp set_flags_test_wake
set_flags_nowake:
    and ax,NOT 7000h
;    or ax,ds:ms_iopl
    or ax,200h
    ret
set_flags       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           sim_set_flags
;
;           DESCRIPTION:    Simulate set flags
;
;           PARAMETERS:         AX          FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_set_flags_name      DB 'Set Flags',0

sim_set_flags   PROC far
    push ds
    push bx
    call set_flags
    pop bx
    pop ds
    retf32
sim_set_flags   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_flags
;
;           DESCRIPTION:    Modify int bit in simulated flags
;
;           PARAMETERS:         AX          FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_flags

get_flags       PROC near
    push ax
    GetThread
    mov ds,ax
    pop ax
    mov ds,ds:p_process_sel
    and ax,NOT 200h
    mov bx,ds:ms_virt_flags
    and bx,200h
    or ax,bx
    or ax,7000h
    ret
get_flags       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           sim_get_flags
;
;           DESCRIPTION:    Modify int bit in simulated flags
;
;           PARAMETERS:         AX          FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_get_flags_name      DB 'Get Flags',0

sim_get_flags   PROC far
    push ds
    push bx
    call get_flags
    pop bx
    pop ds
    retf32
sim_get_flags   ENDP


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
    mov esi,OFFSET notify_end_program
    mov edi,OFFSET notify_end_program_name
    xor cl,cl
    mov ax,notify_end_program_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_init_tasking
    mov edi,OFFSET notify_init_tasking_name
    xor cl,cl
    mov ax,notify_init_tasking_nr
    RegisterOsGate
;
    mov esi,OFFSET sim_sti
    mov edi,OFFSET sim_sti_name
    xor cl,cl
    mov ax,sim_sti_nr
    RegisterOsGate
;
    mov esi,OFFSET sim_cli
    mov edi,OFFSET sim_cli_name
    xor cl,cl
    mov ax,sim_cli_nr
    RegisterOsGate
;
    mov esi,OFFSET sim_set_flags
    mov edi,OFFSET sim_set_flags_name
    xor cl,cl
    mov ax,sim_set_flags_nr
    RegisterOsGate
;
    mov esi,OFFSET sim_get_flags
    mov edi,OFFSET sim_get_flags_name
    xor cl,cl
    mov ax,sim_get_flags_nr
    RegisterOsGate
;
    pop ds
    popa
    ret
init_thread     ENDP

    
code    ENDS

    END

