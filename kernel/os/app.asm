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

app_data_seg    STRUC

open_app_hooks      DB ?
close_app_hooks     DB ?
app_activity_hooks  DB ?

open_app_arr        DD 2*8 DUP(?)
close_app_arr       DD 2*8 DUP(?)
app_activity_arr    DD 2*16 DUP(?)

app_data_seg    ENDS


module_handle_seg           STRUC

mh_base handle_header <>

mh_sel        DW ?

module_handle_seg           ENDS

debug_event_wait_header STRUC

dew_obj         wait_obj_header <>
dew_lib_sel         DW ?

debug_event_wait_header ENDS


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
    mov esi,OFFSET hook_app_activity
    mov edi,OFFSET hook_app_activity_name
    xor cl,cl
    mov ax,hook_app_activity_nr
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
    mov esi,OFFSET open_app
    mov edi,OFFSET open_app_name
    xor cl,cl
    mov ax,open_app_nr
    RegisterOsGate
;
    mov esi,OFFSET close_app
    mov edi,OFFSET close_app_name
    xor cl,cl
    mov ax,close_app_nr
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
    mov esi,OFFSET hook_open_app
    mov edi,OFFSET hook_open_app_name
    xor cl,cl
    mov ax,hook_open_app_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_close_app
    mov edi,OFFSET hook_close_app_name
    xor cl,cl
    mov ax,hook_close_app_nr
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
    mov esi,OFFSET dupl_module_file_handle
    mov edi,OFFSET dupl_module_file_handle_name
    xor dx,dx
    mov ax,dupl_module_file_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_module_focus_key
    mov edi,OFFSET get_module_focus_key_name
    xor dx,dx
    mov ax,get_module_focus_key_nr
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
    mov bx,app_data_sel
    mov eax,SIZE app_data_seg
    AllocateFixedSystemMem
    mov ds,bx
    xor ax,ax
    mov ds:open_app_hooks,al
    mov ds:close_app_hooks,al
    mov ds:app_activity_hooks,al
;
    popa
    pop es
    pop ds
    ret
init_app    ENDP

    
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
    mov ax,app_data_sel
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
;           NAME:           AppNotifyCreate
;
;           DESCRIPTION:    Notify app create process
;
;           PARAMETERS:     ES  App sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_notify_create_name      DB 'App Notify Create',0

app_notify_create   PROC far
    push fs
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_data_sel
    mov fs,cx
    mov cl,fs:app_activity_hooks
    or cl,cl
    je app_notify_create_done
;
    mov bx,OFFSET app_activity_arr

app_notify_create_loop:
    lgs edi,fs:[bx]
    call fword ptr gs:[edi].aa_create_proc
    add bx,8
    dec cl
    jnz app_notify_create_loop

app_notify_create_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    pop fs
    retf32
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
    push fs
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_data_sel
    mov fs,cx
    mov cl,fs:app_activity_hooks
    or cl,cl
    je app_notify_start_done
;
    mov bx,OFFSET app_activity_arr

app_notify_start_loop:
    lgs edi,fs:[bx]
    call fword ptr gs:[edi].aa_start_proc
    add bx,8
    dec cl
    jnz app_notify_start_loop

app_notify_start_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    pop fs
    retf32
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
    push fs
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_data_sel
    mov fs,cx
    mov cl,fs:app_activity_hooks
    or cl,cl
    je app_notify_forked_done
;
    mov bx,OFFSET app_activity_arr

app_notify_forked_loop:
    lgs edi,fs:[bx]
    call fword ptr gs:[edi].aa_forked_proc
    add bx,8
    dec cl
    jnz app_notify_forked_loop

app_notify_forked_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    pop fs
    retf32
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
    push fs
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_data_sel
    mov fs,cx
    mov cl,fs:app_activity_hooks
    or cl,cl
    je app_notify_exec_done
;
    mov bx,OFFSET app_activity_arr

app_notify_exec_loop:
    lgs edi,fs:[bx]
    call fword ptr gs:[edi].aa_exec_proc
    add bx,8
    dec cl
    jnz app_notify_exec_loop

app_notify_exec_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    pop fs
    retf32
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
    push fs
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_data_sel
    mov fs,cx
    mov cl,fs:app_activity_hooks
    or cl,cl
    je app_notify_spawn_done
;
    mov bx,OFFSET app_activity_arr

app_notify_spawn_loop:
    lgs edi,fs:[bx]
    call fword ptr gs:[edi].aa_spawn_proc
    add bx,8
    dec cl
    jnz app_notify_spawn_loop

app_notify_spawn_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    pop fs
    retf32
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
    push fs
    push gs
    push ebx
    push ecx
    push edi
;
    mov cx,app_data_sel
    mov fs,cx
    mov cl,fs:app_activity_hooks
    or cl,cl
    je app_notify_terminate_done
;
    mov bx,OFFSET app_activity_arr

app_notify_terminate_loop:
    lgs edi,fs:[bx]
    call fword ptr gs:[edi].aa_terminate_proc
    add bx,8
    dec cl
    jnz app_notify_terminate_loop

app_notify_terminate_done:
    pop edi
    pop ecx
    pop ebx
    pop gs
    pop fs
    retf32
app_notify_terminate   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HookOpenApp
;
;           DESCRIPTION:    Register callback for open app
;
;           PARAMETERS:     ES:EDI       CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_open_app_name      DB 'Hook Open App',0

hook_open_app   PROC far
    push ds
    push ax
    push bx
    mov ax,app_data_sel
    mov ds,ax
    mov al,ds:open_app_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET open_app_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:open_app_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_open_app   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HookCloseApp
;
;           DESCRIPTION:    Register callback for close app
;
;           PARAMETERS:     ES:EDI       CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_close_app_name     DB 'Hook Close App',0

hook_close_app  PROC far
    push ds
    push ax
    push bx
    mov ax,app_data_sel
    mov ds,ax
    mov al,ds:close_app_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET close_app_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:close_app_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_close_app  ENDP

    
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
    mov ds:app_get_exe_proc,0
    mov ds:app_get_exe_proc+4,0
    mov ds:app_get_cmd_line_proc,0
    mov ds:app_get_cmd_line_proc+4,0
    mov ds:app_get_env_proc,0
    mov ds:app_get_env_proc+4,0
    mov ds:app_allocate_mem_proc,0
    mov ds:app_allocate_mem_proc+4,0
    mov ds:app_free_mem_proc,0
    mov ds:app_free_mem_proc+4,0
    mov ds:app_debug_allocate_mem_proc,0
    mov ds:app_debug_allocate_mem_proc+4,0
    mov ds:app_debug_free_mem_proc,0
    mov ds:app_debug_free_mem_proc+4,0
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
    mov ds:app_load_dll_proc,0
    mov ds:app_load_dll_proc+4,0
    mov ds:app_patch_proc,0
    mov ds:app_patch_proc+4,0
    mov ds:app_get_current_dll_proc,0
    mov ds:app_get_current_dll_proc+4,0
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
    mov ax,app_data_sel
    mov ds,ax
    mov cl,ds:open_app_hooks
    or cl,cl
    je trap_open_app_done
;
    mov bx,OFFSET open_app_arr

trap_open_app_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_open_app_loop

trap_open_app_done:
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
    mov ax,ds:app_next
    or ax,ax
    jz epCleanRootApp
;
    CloseApp
    jmp epRetryApp

epCleanRootApp:    
    mov eax,ds:app_close_proc
    or eax,ds:app_close_proc+4
    jz epCloseHandled
;
    call fword ptr ds:app_close_proc

epCloseHandled:
    mov ax,app_data_sel
    mov ds,ax
    mov cl,ds:close_app_hooks
    or cl,cl
    je epTrapCloseDone
;
    mov bx,OFFSET close_app_arr

epTrapCloseLoop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz epTrapCloseLoop

epTrapCloseDone:
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
    mov ax,app_data_sel
    mov ds,ax
    mov cl,ds:close_app_hooks
    or cl,cl
    je trap_close_app_done
;
    mov bx,OFFSET close_app_arr

trap_close_app_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_close_app_loop

trap_close_app_done:
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
    mov eax,ds:app_get_cmd_line_proc
    mov es:app_get_cmd_line_proc,eax
    mov eax,ds:app_get_cmd_line_proc+4
    mov es:app_get_cmd_line_proc+4,eax
;
    mov eax,ds:app_get_exe_proc
    mov es:app_get_exe_proc,eax
    mov eax,ds:app_get_exe_proc+4
    mov es:app_get_exe_proc+4,eax
;
    mov eax,ds:app_get_env_proc
    mov es:app_get_env_proc,eax
    mov eax,ds:app_get_env_proc+4
    mov es:app_get_env_proc+4,eax
;
    mov eax,ds:app_allocate_mem_proc
    mov es:app_allocate_mem_proc,eax
    mov eax,ds:app_allocate_mem_proc+4
    mov es:app_allocate_mem_proc+4,eax
;
    mov eax,ds:app_free_mem_proc
    mov es:app_free_mem_proc,eax
    mov eax,ds:app_free_mem_proc+4
    mov es:app_free_mem_proc+4,eax
;
    mov eax,ds:app_debug_allocate_mem_proc
    mov es:app_debug_allocate_mem_proc,eax
    mov eax,ds:app_debug_allocate_mem_proc+4
    mov es:app_debug_allocate_mem_proc+4,eax
;
    mov eax,ds:app_debug_free_mem_proc
    mov es:app_debug_free_mem_proc,eax
    mov eax,ds:app_debug_free_mem_proc+4
    mov es:app_debug_free_mem_proc+4,eax
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
    mov eax,ds:app_load_dll_proc
    mov es:app_load_dll_proc,eax
    mov eax,ds:app_load_dll_proc+4
    mov es:app_load_dll_proc+4,eax
;
    mov eax,ds:app_patch_proc
    mov es:app_patch_proc,eax
    mov eax,ds:app_patch_proc+4
    mov es:app_patch_proc+4,eax
;
    mov eax,ds:app_get_current_dll_proc
    mov es:app_get_current_dll_proc,eax
    mov eax,ds:app_get_current_dll_proc+4
    mov es:app_get_current_dll_proc+4,eax
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
    mov ax,ds:app_handle_sel
    mov es:app_handle_sel,ax
;
    mov ax,ds:app_handle_mem_sel
    mov es:app_handle_mem_sel,ax
;
    CloneConsole
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
    mov es:app_get_cmd_line_proc,0
    mov es:app_get_cmd_line_proc+4,0
;
    mov es:app_get_exe_proc,0
    mov es:app_get_exe_proc+4,0
;
    mov es:app_get_env_proc,0
    mov es:app_get_env_proc+4,0
;
    mov es:app_allocate_mem_proc,0
    mov es:app_allocate_mem_proc+4,0
;
    mov es:app_free_mem_proc,0
    mov es:app_free_mem_proc+4,0
;
    mov es:app_debug_allocate_mem_proc,0
    mov es:app_debug_allocate_mem_proc+4,0
;
    mov es:app_debug_free_mem_proc,0
    mov es:app_debug_free_mem_proc+4,0
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
    mov es:app_load_dll_proc,0
    mov es:app_load_dll_proc+4,0
;
    mov es:app_patch_proc,0
    mov es:app_patch_proc+4,0
;
    mov es:app_get_current_dll_proc,0
    mov es:app_get_current_dll_proc+4,0
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
    CreateAppHandle
    mov es:app_handle_sel,ax
    mov es:app_handle_mem_sel,dx    
;
    xor ax,ax
    mov es,ax
;
    ResetProcess
    NotifyStartProgram
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
    mov eax,ds:app_get_exe_proc
    or eax,ds:app_get_exe_proc+4
    pop eax
    stc
    jz get_exe_name_done
;
    call fword ptr ds:app_get_exe_proc

get_exe_name_done:
    pop ds
    retf32
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
    mov eax,ds:app_get_cmd_line_proc
    or eax,ds:app_get_cmd_line_proc+4
    pop eax
    stc
    jz get_cmd_line_done
;
    call fword ptr ds:app_get_cmd_line_proc

get_cmd_line_done:
    pop ds
    retf32
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
    mov eax,ds:app_get_env_proc
    or eax,ds:app_get_env_proc+4
    pop eax
    stc
    jz get_env_done
;
    call fword ptr ds:app_get_env_proc

get_env_done:
    pop ds
    retf32
get_env ENDP


    
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
    retf32
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
    retf32
is_forked    ENDP
    
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
    mov eax,ds:app_allocate_mem_proc
    or eax,ds:app_allocate_mem_proc+4
    pop eax
    jz allocate_mem_default
;
    call fword ptr ds:app_allocate_mem_proc
    jmp allocate_mem_done

allocate_mem_default:
    AllocateLocalMem

allocate_mem_done:
    pop ds
    retf32
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
    mov eax,ds:app_free_mem_proc
    or eax,ds:app_free_mem_proc+4
    pop eax
    jz free_mem_default
;
    call fword ptr ds:app_free_mem_proc
    jmp free_mem_done

free_mem_default:
    FreeMem

free_mem_done:
    pop ds
    retf32
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
    mov eax,ds:app_debug_allocate_mem_proc
    or eax,ds:app_debug_allocate_mem_proc+4
    pop eax
    jz allocate_debug_mem_norm
;
    call fword ptr ds:app_debug_allocate_mem_proc
    jmp allocate_debug_mem_done

allocate_debug_mem_norm:
    push eax
    mov eax,ds:app_allocate_mem_proc
    or eax,ds:app_allocate_mem_proc+4
    pop eax
    jz allocate_debug_mem_default
;
    call fword ptr ds:app_allocate_mem_proc
    jmp allocate_debug_mem_done

allocate_debug_mem_default:
    AllocateLocalMem

allocate_debug_mem_done:
    pop ds
    retf32
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
    mov eax,ds:app_debug_free_mem_proc
    or eax,ds:app_debug_free_mem_proc+4
    pop eax
    jz free_debug_mem_norm
;
    call fword ptr ds:app_debug_free_mem_proc
    jmp free_debug_mem_done

free_debug_mem_norm:
    push eax
    mov eax,ds:app_free_mem_proc
    or eax,ds:app_free_mem_proc+4
    pop eax
    jz free_debug_mem_default
;
    call fword ptr ds:app_free_mem_proc
    jmp free_debug_mem_done

free_debug_mem_default:
    FreeMem

free_debug_mem_done:
    pop ds
    retf32
free_debug_app_mem      ENDP


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
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov eax,ds:app_load_dll_proc
    or eax,ds:app_load_dll_proc+4
    stc
    jz load_dll32_done
;
    call fword ptr ds:app_load_dll_proc
    jc load_dll32_done
;
    push es
    mov es,bx
    mov bx,es:mod_handle
    pop es      

load_dll32_done:
    pop eax
    pop ds
    retf32
load_dll32  Endp

load_dll16  Proc far
    push ds
    push eax
    push edi
;    
    movzx edi,di
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov eax,ds:app_load_dll_proc
    or eax,ds:app_load_dll_proc+4
    stc
    jz load_dll16_done
;
    call fword ptr ds:app_load_dll_proc
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
    retf32
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
    push es
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
    mov es,bx
    mov eax,es:mod_free_dll_proc
    or eax,es:mod_free_dll_proc+4
    stc
    jz free_dll_done
;    
    call fword ptr es:mod_free_dll_proc    

free_dll_done:
    pop ebx
    pop eax
    pop es
    pop ds    
    retf32
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
    mov eax,ds:app_get_current_dll_proc
    or eax,ds:app_get_current_dll_proc+4
    stc
    jz get_current_dll_done
;
    call fword ptr ds:app_get_current_dll_proc
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
    retf32
get_current_dll  Endp

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
;           NAME:           DuplModuleFileHandle
;
;           DESCRIPTION:    Dupl module file handle
;
;       PARAMETERS:         BX          Module handle
;
;       RETURNS:            BX          Duplicated file handle
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
    mov eax,ds:mod_dupl_file_handle_proc
    or eax,ds:mod_dupl_file_handle_proc+4
    stc
    jz dupl_module_file_handle_done
;    
    call fword ptr ds:mod_dupl_file_handle_proc

dupl_module_file_handle_done:
    pop eax
    pop ds    
    retf32
dupl_module_file_handle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleProc
;
;           DESCRIPTION:    Get module procedure
;
;       PARAMETERS:         BX          Module handle
;               ES:(E)DI    Proc name
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
    mov eax,ds:mod_get_proc_proc
    or eax,ds:mod_get_proc_proc+4
    stc
    jz get_module_proc_done32
;    
    call fword ptr ds:mod_get_proc_proc

get_module_proc_done32:
    pop ebx
    pop eax
    retf32
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
    mov eax,ds:mod_get_proc_proc
    or eax,ds:mod_get_proc_proc+4
    stc
    jz get_module_proc_done16
;
    call fword ptr ds:mod_get_proc_proc

get_module_proc_done16:
    pop edi
    pop ebx
    pop eax
    retf32
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
    mov ecx,ds:mod_get_resource_proc
    or ecx,ds:mod_get_resource_proc+4
    stc
    jz get_resource_done
;    
    call fword ptr ds:mod_get_resource_proc

get_resource_done:
    pop ebx
    retf32
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
    mov eax,ds:mod_get_name_proc
    or eax,ds:mod_get_name_proc+4
    stc
    jz get_module_name_done32
;    
    call fword ptr ds:mod_get_name_proc

get_module_name_done32:
    pop ebx
    pop ds
    retf32
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
    mov eax,ds:mod_get_name_proc
    or eax,ds:mod_get_name_proc+4
    stc
    jz get_module_name_done16
;    
    call fword ptr ds:mod_get_name_proc

get_module_name_done16:
    pop edi
    pop ebx
    pop ds
    retf32
get_module_name16  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForDebugEvent
;
;           DESCRIPTION:    Start a wait for debug event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_debug_event      PROC far
    push ds
    push eax
    push bx
;
    mov bx,es:dew_lib_sel
    mov ds,bx
    mov eax,ds:mod_start_wait_for_debug_event_proc
    or eax,ds:mod_start_wait_for_debug_event_proc
    stc
    jz start_wait_for_done
;    
    call fword ptr ds:mod_start_wait_for_debug_event_proc

start_wait_for_done:
    pop bx
    pop eax
    pop ds
    retf32
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
    mov bx,es:dew_lib_sel
    mov ds,bx
    mov eax,ds:mod_stop_wait_for_debug_event_proc
    or eax,ds:mod_stop_wait_for_debug_event_proc
    stc
    jz stop_wait_for_done
;    
    call fword ptr ds:mod_stop_wait_for_debug_event_proc

stop_wait_for_done:
    pop bx
    pop eax
    pop ds
    retf32
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
    retf32
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
    mov bx,es:dew_lib_sel
    mov ds,bx
    mov eax,ds:mod_is_debug_event_idle_proc
    or eax,ds:mod_is_debug_event_idle_proc+4
    stc
    jz is_idle_done
;    
    call fword ptr ds:mod_is_debug_event_idle_proc

is_idle_done:
    pop bx
    pop eax
    pop ds
    retf32
is_debug_event_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForDebugEvent
;
;           DESCRIPTION:    Add a wait for debug event
;
;           PARAMETERS:         AX      Process handle
;               BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_debug_event_name   DB 'Add Wait For Debug Event',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_debug_event,   util_code_sel
aw1 DD OFFSET stop_wait_for_debug_event,    util_code_sel
aw2 DD OFFSET dummy_clear_debug_event,      util_code_sel
aw3 DD OFFSET is_debug_event_idle,          util_code_sel

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
    mov es:dew_lib_sel,ax

add_wait_done:
    pop edi
    pop dx
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_debug_event    ENDP

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDebugEvent
;
;           DESCRIPTION:    Get current debug event
;
;           PARAMETERS:         BX      Process handle
;
;       RETURNS:    AX      Thread ID
;               BL      Event type  
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
    mov ecx,ds:mod_get_debug_event_proc
    or ecx,ds:mod_get_debug_event_proc+4
    stc
    jz get_debug_event_done
;    
    call fword ptr ds:mod_get_debug_event_proc

get_debug_event_done:
    pop dx
    pop ecx
    pop ds
    retf32
get_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDebugEventData
;
;           DESCRIPTION:    Get debug event data
;
;       PARAMETERS:         BX          Handle
;               ES:(E)DI    Event buffer
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
    mov eax,ds:mod_get_debug_event_data_proc
    or eax,ds:mod_get_debug_event_data_proc+4
    stc
    jz get_debug_event_data_done32
;    
    call fword ptr ds:mod_get_debug_event_data_proc

get_debug_event_data_done32:
    pop dx
    pop bx
    pop eax
    pop ds
    retf32
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
    mov eax,ds:mod_get_debug_event_data_proc
    or eax,ds:mod_get_debug_event_data_proc+4
    stc
    jz get_debug_event_data_done16
;    
    call fword ptr ds:mod_get_debug_event_data_proc

get_debug_event_data_done16:
    pop edi
    pop dx
    pop bx
    pop eax
    pop ds
    retf32
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
    mov ecx,ds:mod_clear_debug_event_proc
    or ecx,ds:mod_clear_debug_event_proc+4
    stc
    jz clear_debug_event_done
;    
    call fword ptr ds:mod_clear_debug_event_proc

clear_debug_event_done:
    pop dx
    pop ecx
    pop bx
    pop ax
    pop ds
    retf32
clear_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ContinueDebugEvent
;
;           DESCRIPTION:    Continue debug event
;
;       PARAMETERS:         BX          Module handle
;               EAX     Thread ID
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
    mov ecx,ds:mod_continue_debug_event_proc
    or ecx,ds:mod_continue_debug_event_proc+4
    stc
    jz continue_debug_event_done
;    
    call fword ptr ds:mod_continue_debug_event_proc

continue_debug_event_done:
    pop esi
    pop dx
    pop ecx
    pop bx
    pop ds
    retf32
continue_debug_event  Endp

    
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
