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
; APP.ASM
; Application handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE int.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\handle.inc
INCLUDE module.def
include ..\wait.inc


module_handle_seg           STRUC

mh_base handle_header <>

mh_sel        DW ?

module_handle_seg           ENDS


    .386p

code    SEGMENT byte public use16 'CODE'

    extrn create_ldt:near
    extrn destroy_ldt:near

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitApp
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:     
;                           
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_app

init_app    PROC near
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov esi,OFFSET init_system_app
    mov edi,OFFSET init_system_app_name
    xor cl,cl
    mov ax,init_system_app_nr
    RegisterOsGate
;
    mov esi,OFFSET init_process_app
    mov edi,OFFSET init_process_app_name
    xor cl,cl
    mov ax,init_process_app_nr
    RegisterOsGate
;
    mov esi,OFFSET exit_process_app
    mov edi,OFFSET exit_process_app_name
    xor cl,cl
    mov ax,exit_process_app_nr
    RegisterOsGate
;
    mov esi,OFFSET clone_app
    mov edi,OFFSET clone_app_name
    xor cl,cl
    mov ax,clone_app_nr
    RegisterOsGate
;
    mov esi,OFFSET exec_app
    mov edi,OFFSET exec_app_name
    xor cl,cl
    mov ax,exec_app_nr
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
    mov esi,OFFSET app_patch
    mov edi,OFFSET app_patch_name
    xor cl,cl
    mov ax,app_patch_nr
    RegisterOsGate
;
    mov esi,OFFSET get_module_focus_key
    mov edi,OFFSET get_module_focus_key_name
    xor dx,dx
    mov ax,get_module_focus_key_nr
    RegisterBimodalUserGate
;
    popa
    pop es
    pop ds
    ret
init_app    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           run_open_hooks
;
;           DESCRIPTION:    Run open app hooks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_open_hooks  Proc near
    push ds
    push ax
    push cx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
;       
    mov ds:app_fork_id,0
    mov ds:app_handle,0
    mov ds:app_loader,0
    mov ds:app_init_thread_proc,0
    mov ds:app_init_thread_proc+4,0
    mov ds:app_free_thread_proc,0
    mov ds:app_free_thread_proc+4,0
    mov ds:app_spawn_proc,0
    mov ds:app_spawn_proc+4,0
    mov ds:app_fork_proc,0
    mov ds:app_fork_proc+4,0
    mov ds:app_close_proc,0
    mov ds:app_close_proc+4,0
    mov ds:app_patch_proc,0
    mov ds:app_patch_proc+4,0
    mov ds:app_fatal_error_exit_proc,0
    mov ds:app_fatal_error_exit_proc+4,0
;
    InitSection ds:app_lib_section
    mov ds:app_env,0
    mov ds:app_name,0
    mov ds:app_cmd_line,0
    mov ds:app_mem_blocks,0
;
    mov ds:app_vm_psp_seg,0
    mov ds:app_pm_psp_sel,0
    mov ds:app_vm_mem_strat,0
    mov ds:app_vm_dta_seg,0
    mov ds:app_pm_dta_sel,0
    mov ds:app_find_sel,0
    mov ds:app_psp_mode,0
    mov ds:app_dta_mode,0
;
    pop cx
    pop ax
    pop ds
    ret
run_open_hooks  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_system_app
;
;           DESCRIPTION:    Init system app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_system_app_name   DB 'Init System App',0

init_system_app    PROC far
    mov al,16
    SetBitness
    retf32
init_system_app    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_process_app
;
;           DESCRIPTION:    Init per-process data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_app_name   DB 'Init App Process',0

init_process_app    PROC far
    call create_ldt
    call run_open_hooks
    retf32
init_process_app    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           exit_process_app
;
;           DESCRIPTION:    Exit per-process data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exit_process_app_name   DB 'Exit Process App',0

exit_process_app    PROC near
    IsLongThread
    jnc epDone

epRetryApp:    
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov eax,ds:app_close_proc
    or eax,ds:app_close_proc+4
    jz epCloseHandled
;
    call fword ptr ds:app_close_proc

epCloseHandled:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    call destroy_ldt

epDone:
    retf32
exit_process_app    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           OpenApp
;
;           DESCRIPTION:    Open app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_app_name   DB 'Open App',0

open_app    PROC far
    push ds
    push es
    push fs
    pushad
;
    GetThread
    mov ds,ax
;
    mov eax,SIZE app_seg
    AllocateSmallGlobalMem
    xor di,di
    mov cx,SIZE app_seg
    xor al,al
    rep stos byte ptr es:[di]
;    
    mov bx,es
    mov ax,ds:p_app_sel
    mov es:app_next,ax
    mov ds:p_app_sel,bx
;
    call create_ldt
    call run_open_hooks
;
    popad
    pop fs
    pop es
    pop ds
    retf32
open_app    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseApp
;
;           DESCRIPTION:    Close app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_app_name  DB 'Close App',0

close_app       PROC far
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov eax,ds:app_close_proc
    or eax,ds:app_close_proc+4
    jz close_proc_handled
;
    call fword ptr ds:app_close_proc

close_proc_handled:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    call destroy_ldt
;
    GetThread
    mov ds,ax
    mov es,ds:p_app_sel
    movzx eax,es:app_next
    or ax,ax
    jz close_app_last
;
    mov fs,ax
    mov ds:p_app_sel,ax

close_app_last:
    FreeMem
;
    GetThread
    mov es,ax
    cli
    mov bx,fs
    or bx,bx
    jz close_app_ldt_data
;
    mov bx,fs:app_ldt_data_sel

close_app_ldt_data:
    mov ds:p_ldt_sel,bx
;
    mov bx,fs
    or bx,bx
    jz close_app_ldt
;
    mov bx,fs:app_ldt_sel

close_app_ldt:
    mov es:p_ldt,bx
    lldt bx
    sti
    retf32
close_app       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloneApp
;
;           DESCRIPTION:    Clone app
;
;           PARAMETERS:     AX          Source app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_app_name   DB 'Clone App',0

clone_app    PROC far
    push ds
    push es
    push fs
    pushad
;
    mov ds,ax
    GetThread
    mov es,ax
    mov es,es:p_app_sel
;
    mov ax,ds:app_loader
    mov es:app_loader,ax
;
    mov eax,ds:app_init_thread_proc
    mov es:app_init_thread_proc,eax
    mov eax,ds:app_init_thread_proc+4
    mov es:app_init_thread_proc+4,eax
;
    mov eax,ds:app_free_thread_proc
    mov es:app_free_thread_proc,eax
    mov eax,ds:app_free_thread_proc+4
    mov es:app_free_thread_proc+4,eax
;
    mov eax,ds:app_spawn_proc
    mov es:app_spawn_proc,eax
    mov eax,ds:app_spawn_proc+4
    mov es:app_spawn_proc+4,eax
;
    mov eax,ds:app_fork_proc
    mov es:app_fork_proc,eax
    mov eax,ds:app_fork_proc+4
    mov es:app_fork_proc+4,eax
;
    mov eax,ds:app_close_proc
    mov es:app_close_proc,eax
    mov eax,ds:app_close_proc+4
    mov es:app_close_proc+4,eax
;
    mov eax,ds:app_patch_proc
    mov es:app_patch_proc,eax
    mov eax,ds:app_patch_proc+4
    mov es:app_patch_proc+4,eax
;
    mov eax,ds:app_fatal_error_exit_proc
    mov es:app_fatal_error_exit_proc,eax
    mov eax,ds:app_fatal_error_exit_proc+4
    mov es:app_fatal_error_exit_proc+4,eax
;
    mov eax,ds:app_loader_name
    mov es:app_loader_name,eax
;
    mov eax,ds:app_section_base
    mov es:app_section_base,eax
;
    mov eax,ds:app_create_section_proc
    mov es:app_create_section_proc,eax
    mov eax,ds:app_create_section_proc+4
    mov es:app_create_section_proc+4,eax
;
    mov eax,ds:app_create_named_section_proc
    mov es:app_create_named_section_proc,eax
    mov eax,ds:app_create_named_section_proc+4
    mov es:app_create_named_section_proc+4,eax
;
    mov eax,ds:app_delete_section_proc
    mov es:app_delete_section_proc,eax
    mov eax,ds:app_delete_section_proc+4
    mov es:app_delete_section_proc+4,eax
;
    mov eax,ds:app_enter_section_proc
    mov es:app_enter_section_proc,eax
    mov eax,ds:app_enter_section_proc+4
    mov es:app_enter_section_proc+4,eax
;
    mov eax,ds:app_leave_section_proc
    mov es:app_leave_section_proc,eax
    mov eax,ds:app_leave_section_proc+4
    mov es:app_leave_section_proc+4,eax
;
    mov ax,ds:app_unload_proc
    mov es:app_unload_proc,ax
;
    mov ax,ds:app_handle
    mov es:app_handle,ax
;
    mov ax,ds:app_mod_sel
    mov es:app_mod_sel,ax
;
    mov eax,ds:app_env
    mov es:app_env,eax
;
    mov eax,ds:app_name
    mov es:app_name,eax
;
    mov eax,ds:app_cmd_line
    mov es:app_cmd_line,eax
;
    mov eax,ds:app_mem_blocks
    mov es:app_mem_blocks,eax
;
    mov ax,ds:app_context
    mov es:app_context,ax
;
    mov al,ds:app_bitness
    mov es:app_bitness,al
;
    mov al,ds:app_key
    mov es:app_key,al
;
    mov es:app_exit_code,0
    mov es:app_mem_blocks,0
    mov es:app_exe_name,0
;
    popad
    pop fs
    pop es
    pop ds
    retf32
clone_app    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ExecApp
;
;           DESCRIPTION:    Exec app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exec_app_name   DB 'Exec App',0

exec_app    PROC far
    xor ax,ax
    mov es,ax
    mov gs,ax
;
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov eax,es:app_free_thread_proc
    or eax,es:app_free_thread_proc+4
    jz eaAppClosed
;
    call fword ptr es:app_free_thread_proc

eaAppClosed:
    GetThread
    mov es,ax
    lock and es:p_flags,NOT THREAD_FLAG_FORKED
    mov es,es:p_app_sel
;
    mov es:app_loader,0
;
    mov es:app_init_thread_proc,0
    mov es:app_init_thread_proc+4,0
;
    mov es:app_free_thread_proc,0
    mov es:app_free_thread_proc+4,0
;
    mov es:app_spawn_proc,0
    mov es:app_spawn_proc+4,0
;
    mov es:app_fork_proc,0
    mov es:app_fork_proc+4,0
;
    mov es:app_close_proc,0
    mov es:app_close_proc+4,0
;
    mov es:app_fatal_error_exit_proc,0
    mov es:app_fatal_error_exit_proc+4,0
;
    mov es:app_patch_proc,0
    mov es:app_patch_proc+4,0
;
    mov es:app_loader_name,0
    mov es:app_section_base,0
;
    mov es:app_create_section_proc,0
    mov es:app_create_section_proc+4,0
;
    mov es:app_create_named_section_proc,0
    mov es:app_create_named_section_proc+4,0
;
    mov es:app_delete_section_proc,0
    mov es:app_delete_section_proc+4,0
;
    mov es:app_enter_section_proc,0
    mov es:app_enter_section_proc+4,0
;
    mov es:app_leave_section_proc,0
    mov es:app_leave_section_proc+4,0
;
    mov es:app_exit_code,0
    mov es:app_fork_id,0
;
    mov es:app_handle,0
    mov es:app_mod_sel,0
;
    InitSection es:app_lib_section
;
    mov es:app_env,0
    mov es:app_name,0
    mov es:app_cmd_line,0
    mov es:app_mem_blocks,0
;
    mov es:app_context,0
    mov es:app_bitness,0
    mov es:app_key,0
;
    xor ax,ax
    mov es,ax
;
    ResetProcess
    retf32
exec_app    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetModule
;
;           DESCRIPTION:    Set module for active process
;
;       PARAMETERS:     ES  Module sel
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
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
    retf32
get_module_focus_key  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AppPatch
;
;       DESCRIPTION:    App specific usergate patching
;
;       PARAMETERS:     DS:EBX      Instruction to patch
;                       EAX         Gate #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_patch_name DB 'App Patch',0

app_patch      PROC far
    push es
    push eax
;
    GetThread
    mov es,ax
    mov es,es:p_app_sel
    mov eax,es:app_patch_proc
    or eax,es:app_patch_proc+4
    stc
    jz app_patch_done
;    
    call fword ptr es:app_patch_proc

app_patch_done:
    pop eax
    pop es
    retf32
app_patch      ENDP

code    ENDS

END
