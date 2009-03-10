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
						
		NAME app

GateSize = 16

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

app_data_seg	STRUC

app_alloc_base		DD ?

open_app_hooks		DB ?
close_app_hooks		DB ?

open_app_arr		DW 2*8 DUP(?)
close_app_arr		DW 2*8 DUP(?)

app_data_seg	ENDS


module_handle_seg		STRUC

mh_base	handle_header <>

mh_sel            DW ?

module_handle_seg		ENDS

debug_event_wait_header	STRUC

dew_obj			wait_obj_header <>
dew_handle		DW ?

debug_event_wait_header	ENDS


	.386p

code	SEGMENT byte public use16 'CODE'

	extrn create_ldt:near
	extrn destroy_ldt:near

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitApp
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:	
;						
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_app

init_app	PROC near
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET allocate_fixed_app_mem
	mov di,OFFSET allocate_fixed_app_mem_name
	xor cl,cl
	mov ax,allocate_fixed_app_mem_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_fixed_app_linear
	mov di,OFFSET allocate_fixed_app_linear_name
	xor cl,cl
	mov ax,allocate_fixed_app_linear_nr
	RegisterOsGate
;
	mov si,OFFSET open_app
	mov di,OFFSET open_app_name
	xor cl,cl
	mov ax,open_app_nr
	RegisterOsGate
;
	mov si,OFFSET close_app
	mov di,OFFSET close_app_name
	xor cl,cl
	mov ax,close_app_nr
	RegisterOsGate
;
	mov si,OFFSET hook_open_app
	mov di,OFFSET hook_open_app_name
	xor cl,cl
	mov ax,hook_open_app_nr
	RegisterOsGate
;
	mov si,OFFSET hook_close_app
	mov di,OFFSET hook_close_app_name
	xor cl,cl
	mov ax,hook_close_app_nr
	RegisterOsGate
;
	mov si,OFFSET set_module
	mov di,OFFSET set_module_name
	xor cl,cl
	mov ax,set_module_nr
	RegisterOsGate
;
	mov si,OFFSET reset_module
	mov di,OFFSET reset_module_name
	xor cl,cl
	mov ax,reset_module_nr
	RegisterOsGate
;
	mov si,OFFSET create_module
	mov di,OFFSET create_module_name
	xor cl,cl
	mov ax,create_module_nr
	RegisterOsGate
;
	mov si,OFFSET free_module
	mov di,OFFSET free_module_name
	xor cl,cl
	mov ax,free_module_nr
	RegisterOsGate
;
	mov si,OFFSET deref_module_handle
	mov di,OFFSET deref_module_handle_name
	xor cl,cl
	mov ax,deref_module_handle_nr
	RegisterOsGate
;
	mov si,OFFSET alias_module_handle
	mov di,OFFSET alias_module_handle_name
	xor cl,cl
	mov ax,alias_module_handle_nr
	RegisterOsGate
;
	mov si,OFFSET get_exe_name
	mov di,OFFSET get_exe_name_name
	mov dx,virt_es_in
	mov ax,get_exe_name_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_cmd_line
	mov di,OFFSET get_cmd_line_name
	mov dx,virt_es_in
	mov ax,get_cmd_line_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_env
	mov di,OFFSET get_env_name
	mov dx,virt_es_in
	mov ax,get_env_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET allocate_app_mem
	mov di,OFFSET allocate_app_mem_name
	mov dx,virt_es_out
	mov ax,allocate_app_mem_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET free_app_mem
	mov di,OFFSET free_app_mem_name
	mov dx,virt_es_in
	mov ax,free_app_mem_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET app_debug
	mov di,OFFSET app_debug_name
	xor dx,dx
	mov ax,app_debug_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET load_dll16
	mov si,OFFSET load_dll32
	mov di,OFFSET load_dll_name
	mov dx,virt_es_in
	mov ax,load_dll_nr
	RegisterUserGate
;
	mov si,OFFSET free_dll
	mov di,OFFSET free_dll_name
	xor dx,dx
	mov ax,free_dll_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_module_focus_key
	mov di,OFFSET get_module_focus_key_name
	xor dx,dx
	mov ax,get_module_focus_key_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET get_module_proc16
	mov si,OFFSET get_module_proc32
	mov di,OFFSET get_module_proc_name
	mov dx,virt_ds_out OR virt_es_in
	mov ax,get_module_proc_nr
	RegisterUserGate
;
	mov si,OFFSET get_module_resource
	mov di,OFFSET get_module_resource_name
	xor dx,dx
	mov ax,get_module_resource_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET get_module_name16
	mov si,OFFSET get_module_name32
	mov di,OFFSET get_module_name_name
	mov dx,virt_es_in
	mov ax,get_module_name_nr
	RegisterUserGate
;
	mov si,OFFSET add_wait_for_debug_event
	mov di,OFFSET add_wait_for_debug_event_name
	xor dx,dx
	mov ax,add_wait_for_debug_event_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_debug_event
	mov di,OFFSET get_debug_event_name
	xor dx,dx
	mov ax,get_debug_event_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET get_debug_event_data16
	mov si,OFFSET get_debug_event_data32
	mov di,OFFSET get_debug_event_data_name
	mov dx,virt_es_in
	mov ax,get_debug_event_data_nr
	RegisterUserGate
;
	mov si,OFFSET clear_debug_event
	mov di,OFFSET clear_debug_event_name
	xor dx,dx
	mov ax,clear_debug_event_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET continue_debug_event
	mov di,OFFSET continue_debug_event_name
	xor dx,dx
	mov ax,continue_debug_event_nr
	RegisterBimodalUserGate
;
	mov bx,thread_app_sel
	mov edx,app_linear
	mov ecx,SIZE app_seg
	CreateDataSelector16
;
	mov bx,app_data_sel
	mov eax,SIZE app_data_seg
	AllocateFixedSystemMem
	mov ds,bx
	xor ax,ax
	mov ds:open_app_hooks,al
	mov ds:close_app_hooks,al
	mov ds:app_alloc_base,app_linear + SIZE app_seg
;
	popa
	pop es
	pop ds
	ret
init_app	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateFixedAppLinear
;
;		DESCRIPTION:	Allocate per app linear memory
;
;		PARAMETERS:		EAX		# BYTES
;						EDX		LINEAR BASE ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_app_linear_name	DB 'Allocate Fixed App Linear',0

allocate_fixed_app_linear	PROC far
	push ds
	mov dx,app_data_sel
	mov ds,dx
	mov edx,ds:app_alloc_base
	add ds:app_alloc_base,eax
	pop ds
	ret
allocate_fixed_app_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateFixedAppMem
;
;		DESCRIPTION:	Allocate fixed app memory
;
;		PARAMETERS:		EAX 	# BYTES
;						BX		SELECTOR IN
;						ES		SELECTOR UT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_app_mem_name	DB 'Allocate Fixed App Mem',0

allocate_fixed_app_mem	PROC far
	push ds
	push ecx
	push edx
;
	AllocateFixedAppLinear
	mov ecx,eax
	CreateDataSelector16
	mov es,bx
;
	pop edx
	pop ecx
	pop ds
	ret
allocate_fixed_app_mem	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HookOpenApp
;
;		DESCRIPTION:	Register callback for open app
;
;		PARAMETERS:		ES:DI		CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_open_app_name	DB 'Hook Open App',0

hook_open_app	PROC far
	push ds
	push ax
	push bx
	mov ax,app_data_sel
	mov ds,ax
	mov al,ds:open_app_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET open_app_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:open_app_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_open_app	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HookCloseApp
;
;		DESCRIPTION:	Register callback for close app
;
;		PARAMETERS:		ES:DI		CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_close_app_name	DB 'Hook Close App',0

hook_close_app	PROC far
	push ds
	push ax
	push bx
	mov ax,app_data_sel
	mov ds,ax
	mov al,ds:close_app_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET close_app_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:close_app_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_close_app	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			run_open_hooks
;
;		DESCRIPTION:	Run open app hooks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_open_hooks	Proc near
	push ds
	push ax
	push cx
;
	mov ax,thread_app_sel
	mov ds,ax
;	
    mov ds:app_handle,0
	mov ds:app_get_exe_proc,0
	mov ds:app_get_cmd_line_proc,0
	mov ds:app_get_env_proc,0
	mov ds:app_allocate_mem_proc,0
	mov ds:app_free_mem_proc,0
	mov ds:app_init_thread_proc,0
	mov ds:app_free_thread_proc,0
	mov ds:app_spawn_proc,0
	mov ds:app_close_proc,0
	mov ds:app_load_dll_proc,0
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
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz trap_open_app_loop

trap_open_app_done:
	pop cx
	pop ax
	pop ds
	ret
run_open_hooks	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_process_app
;
;		DESCRIPTION:	Init per-process data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_process_app

init_process_app	PROC near
	call create_ldt
	mov al,16
	SetBitness
	call run_open_hooks
	ret
init_process_app	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			OpenApp
;
;		DESCRIPTION:	Open app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_app_name	DB 'Open App',0

open_app	PROC far
	push ds
	push es
	push fs
	pushad
;
	mov ax,thread_sel
	mov ds,ax
;
	mov eax,1000h
	AllocateBigLinear
	AllocateGdt
	mov ecx,eax
	CreateDataSelector16
	mov fs,bx
	mov ax,ds:p_app_sel
	mov fs:app_next,ax
	mov fs:app_sel,fs
;
	shr edx,10
	mov ax,sys_page_sel
	mov es,ax
	mov eax,es:[edx]
	mov ds:p_app_sel,bx
	mov ds:p_app_page,eax
	mov fs:app_page,eax
;
	mov ax,process_page_sel
	mov es,ax
	mov ebx,app_linear SHR 10
	mov eax,ds:p_app_page
	mov es:[ebx],eax
	mov eax,ds:p_cr3
	mov cr3,eax
	call create_ldt
	call run_open_hooks
;
	popad
	pop fs
	pop es
	pop ds
	ret
open_app	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseApp
;
;		DESCRIPTION:	Close app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_app_name	DB 'Close App',0

close_app	PROC far
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_close_proc
	or eax,eax
	jz close_proc_handled
;
	call ds:app_close_proc

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
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
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
	mov ax,thread_sel
	mov ds,ax
	mov es,ds:p_app_sel
	movzx eax,es:app_next
	or ax,ax
	jz close_app_last
;
	mov fs,ax
	mov ds:p_app_sel,ax
	mov eax,fs:app_page

close_app_last:
	mov ds:p_app_page,eax
	FreeMem
;
	mov ax,process_page_sel
	mov es,ax
	mov ebx,app_linear SHR 10
	mov eax,ds:p_app_page
	mov es:[ebx],eax
	mov eax,ds:p_cr3
	mov cr3,eax
;
	mov ax,thread_tss_sel
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
	mov es:tss_ldt,bx
	lldt bx
	sti
	ret
close_app	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetModule
;
;		DESCRIPTION:	Set module for active process
;
;       PARAMETERS:     ES  Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_module_name	DB 'Set Module',0

set_module	PROC far
    push ds
    push ax
    push bx
    push dx
;
    mov dx,es
	mov cx,SIZE module_handle_seg
	AllocateHandle
	mov [bx].mh_sel,dx
	mov [bx].hh_sign,MODULE_HANDLE
	mov bx,[bx].hh_handle
;
    mov ds,dx
    mov ds:mod_handle,bx
    mov ds:mod_list,0
;    
	mov ax,thread_app_sel
	mov ds,ax
    mov ds:app_handle,bx
    mov ds:app_lib_sel,dx
    mov al,ds:app_key
    mov es:mod_key,al
;    
    pop dx
    pop bx
    pop ax
    pop ds
	ret
set_module	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ResetModule
;
;		DESCRIPTION:	Reset module for active process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_module_name	DB 'Reset Module',0

reset_module	PROC far
    push ds
    push es
    push ax
    push bx
    push dx
;
    mov ax,thread_app_sel
    mov ds,ax
    mov bx,ds:app_handle
	mov ax,MODULE_HANDLE
	DerefHandle
	jc reset_mod_handle_ok
;
    mov ax,[bx].mh_sel
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
    pop bx
    pop ax
    pop es
    pop ds
	ret
reset_module	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateModule
;
;		DESCRIPTION:	Create new module for active process
;
;       PARAMETERS:     ES  Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_module_name	DB 'Create Module',0

create_module	PROC far
    push ds
    push es
    push ax
    push bx
    push dx
;
	mov cx,SIZE module_handle_seg
	AllocateHandle
	mov [bx].mh_sel,es
	mov [bx].hh_sign,MODULE_HANDLE
	mov bx,[bx].hh_handle
;
    mov es:mod_handle,bx
    mov es:mod_list,0
;    
    mov dx,es
	mov ax,thread_app_sel
	mov ds,ax
    mov bx,ds:app_handle
	mov ax,MODULE_HANDLE
	DerefHandle
	jc create_module_done
;
    mov ax,[bx].mh_sel
    or ax,ax
    jz create_module_done
;
    mov ds,ax    
    mov ax,ds:mod_list
    mov ds:mod_list,es
    mov es:mod_next,ax
        
create_module_done:    
    pop dx
    pop bx
    pop ax
    pop es
    pop ds
	ret
create_module	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeModule
;
;		DESCRIPTION:	Free module for active process
;
;       PARAMETERS:     ES      Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_module_name	DB 'Free Module',0

free_module	PROC far
    push ds
    push es
    push ax
    push bx
    push dx
;
    mov dx,es
	mov ax,thread_app_sel
	mov ds,ax
    mov bx,ds:app_handle
	mov ax,MODULE_HANDLE
	DerefHandle
	jc free_module_done
;
    mov ax,[bx].mh_sel
    or ax,ax
    jz free_module_done
;
    mov ds,ax    
    mov ax,ds:mod_list
    or ax,ax
    jz free_module_done
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
    jmp free_module_done

free_mod_in_list:
    mov ds,dx
    mov ax,ds:mod_next
    mov es:mod_next,ax
    mov bx,ds:mod_handle

free_mod_handle:
	mov ax,MODULE_HANDLE
	DerefHandle
	jc free_module_done
;
	FreeHandle
            
free_module_done:
    pop dx
    pop bx
    pop ax
    pop es
    pop ds
	ret
free_module	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetExeName
;
;		DESCRIPTION:	Get name of executable file
;
;		RETURNS:		ES:(E)DI		Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exe_name_name	DB 'Get Exe Name',0

get_exe_name	PROC far
	push ds
;
	push eax
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_get_exe_proc
	or eax,eax
	pop eax
	stc
	jz get_exe_name_done
;
	call ds:app_get_exe_proc

get_exe_name_done:
	pop ds
	retf32
get_exe_name	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetCmdLine
;
;		DESCRIPTION:	Get command line
;
;		RETURNS:		ES:(E)DI		Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cmd_line_name	DB 'Get Cmd Line',0

get_cmd_line	PROC far
	push ds
;
	push eax
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_get_cmd_line_proc
	or eax,eax
	pop eax
	stc
	jz get_cmd_line_done
;
	call ds:app_get_cmd_line_proc

get_cmd_line_done:
	pop ds
	retf32
get_cmd_line	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetEnvironment
;
;		DESCRIPTION:	Get environment
;
;		RETURNS:		ES:(E)DI		Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env_name	DB 'Get Environment',0

get_env	PROC far
	push ds
;
	push eax
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_get_env_proc
	or eax,eax
	pop eax
	stc
	jz get_env_done
;
	call ds:app_get_env_proc

get_env_done:
	pop ds
	retf32
get_env	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateAppMem
;
;		DESCRIPTION:	Allocate application memory
;
;		PARAMETERS:		EAX			Size
;
;		RETURNS:		ES / (E)DX	Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_app_mem_name	DB 'Allocate App Mem',0

allocate_app_mem	PROC far
	push ds
;
	push eax
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_allocate_mem_proc
	or eax,eax
	pop eax
	jz allocate_mem_default
;
	call ds:app_allocate_mem_proc
	jmp allocate_mem_done

allocate_mem_default:
	AllocateLocalMem

allocate_mem_done:
	pop ds
	retf32
allocate_app_mem	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeAppMem
;
;		DESCRIPTION:	Free application memory
;
;		PARAMETERS:		ES / (E)DX	Memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_app_mem_name	DB 'Free App Mem',0

free_app_mem	PROC far
	push ds
;
	push eax
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_free_mem_proc
	or eax,eax
	pop eax
	jz free_mem_default
;
	call ds:app_free_mem_proc
	jmp free_mem_done

free_mem_default:
	FreeMem

free_mem_done:
	pop ds
	retf32
free_app_mem	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AppDebug
;
;		DESCRIPTION:	Debug app selector
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_debug_name	DB 'App Debug',0

app_debug	PROC far
	push ds
;
	mov ax,process_page_sel
	mov ds,ax
	mov eax,app_linear SHR 10
	mov eax,ds:[eax]
;
	pop ds
	retf32
app_debug	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DerefModuleHandle
;
;		DESCRIPTION:    Dereference module handle
;
;       PARAMETERS:		BX      Module handle
;
;		RETURNS:		BX		Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

deref_module_handle_name	DB 'Deref Module Handle',0

deref_module_handle  Proc far
    push ds
    push ax
;
	mov ax,MODULE_HANDLE
	DerefHandle
	jc deref_module_done
;
    mov bx,[bx].mh_sel
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
;		NAME:			AliasModuleHandle
;
;		DESCRIPTION:    Create an alias handle for module
;
;       PARAMETERS:		BX      Lib sel
;
;		RETURNS:		BX	    Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alias_module_handle_name	DB 'Alias Module Handle',0

alias_module_handle  Proc far
    push ds
    push ax
    push cx
    push dx
;
    mov dx,bx
	mov cx,SIZE module_handle_seg
	AllocateHandle
	mov [bx].mh_sel,dx
	mov [bx].hh_sign,MODULE_HANDLE
	mov bx,[bx].hh_handle
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
;		NAME:			load_dll
;
;		DESCRIPTION:    Load DLL
;
;       PARAMETERS:		ES:(E)DI	Name of dll to load
;
;		RETURNS:		BX		    Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dll_name	DB 'Load Dll',0

load_dll32  Proc far
    push ds
    push eax
;    
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_load_dll_proc
	or eax,eax
	stc
	jz load_dll32_done
;
	call ds:app_load_dll_proc
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
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_load_dll_proc
	or eax,eax
	stc
	jz load_dll16_done
;
	call ds:app_load_dll_proc
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
;		NAME:			free_dll
;
;		DESCRIPTION:    Free DLL
;
;       PARAMETERS:		BX		Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll_name	DB 'Free Dll',0

free_dll  Proc far
    push ds
    push es
    push eax
    push bx
;    
	mov ax,MODULE_HANDLE
	DerefHandle
	jc free_dll_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz free_dll_done
;
    mov es,bx
    mov eax,es:mod_free_dll_proc
    or eax,eax
    stc
    jz free_dll_done
;    
    call es:mod_free_dll_proc    

free_dll_done:
    pop bx
    pop eax
    pop es
    pop ds    
    retf32
free_dll  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetModuleFocusKey
;
;		DESCRIPTION:    Get module focus key
;
;       PARAMETERS:		BX		Module handle
;
;       RETURNS:        AL      Key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_focus_key_name	DB 'Get Module Focus Key',0

get_module_focus_key  Proc far
    push ds
    push bx
;    
	mov ax,MODULE_HANDLE
	DerefHandle
	jc get_module_focus_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_module_focus_done
;
    mov ds,bx
    mov al,ds:mod_key
    clc

get_module_focus_done:
    pop bx
    pop ds    
    retf32
get_module_focus_key  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetModuleProc
;
;		DESCRIPTION:    Get module procedure
;
;       PARAMETERS:		BX		Module handle
;                       ES:(E)DI	Proc name
;
;       RETURNS:        DS:(E)SI	Proc address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_proc_name	DB 'Get Module Proc',0

get_module_proc32  Proc far
    push eax
    push bx
;    
	mov ax,MODULE_HANDLE
	DerefHandle
	jc get_module_proc_done32
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_module_proc_done32
;
    mov ds,bx
    mov eax,ds:mod_get_proc_proc
    or eax,eax
    stc
    jz get_module_proc_done32
;    
    call ds:mod_get_proc_proc

get_module_proc_done32:
    pop bx
    pop eax
    retf32
get_module_proc32  Endp

get_module_proc16  Proc far
    push eax
    push bx
    push edi
;    
    movzx edi,di
	mov ax,MODULE_HANDLE
	DerefHandle
	jc get_module_proc_done16
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_module_proc_done16
;
    mov ds,bx
    mov eax,ds:mod_get_proc_proc
    or eax,eax
    stc
    jz get_module_proc_done16
;
    call ds:mod_get_proc_proc

get_module_proc_done16:
    pop edi
    pop bx
    pop eax
    ret
get_module_proc16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetModuleResource
;
;		DESCRIPTION:    Get module resource
;
;       PARAMETERS:		BX		    Module handle
;                       (E)AX		Resource handle
;                       (E)DX		Resource type
;
;       RETURNS:        DS:(E)SI	Resource address
;                       (E)CX       Resource size   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_resource_name	DB 'Get Module Resource',0

get_module_resource  Proc far
    push bx
;    
    push ax
	mov ax,MODULE_HANDLE
	DerefHandle
	pop ax
	jc get_resource_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_resource_done
;
    mov ds,bx
    mov ecx,ds:mod_get_resource_proc
    or ecx,ecx
    stc
    jz get_resource_done
;    
    call ds:mod_get_resource_proc

get_resource_done:
    pop bx
    retf32
get_module_resource  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetModuleName
;
;		DESCRIPTION:    Get module name
;
;       PARAMETERS:		BX		    Handle
;						(E)CX	    Max name size
;						ES:(E)DI	Name buffer
;						
;		RETURNS:		(E)AX	    Bytes copied
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_name_name	DB 'Get Module Name',0

get_module_name32  Proc far
    push ds
    push bx
;    
	mov ax,MODULE_HANDLE
	DerefHandle
	jc get_module_name_done32
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_module_name_done32
;
    mov ds,bx
    mov eax,ds:mod_get_name_proc
    stc
    jz get_module_name_done32
;    
    call ds:mod_get_name_proc

get_module_name_done32:
    pop bx
    pop ds
    retf32
get_module_name32  Endp

get_module_name16  Proc far
    push ds
    push bx
    push edi
;    
    movzx edi,di
	mov ax,MODULE_HANDLE
	DerefHandle
	jc get_module_name_done16
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_module_name_done16
;
    mov ds,bx
    mov eax,ds:mod_get_name_proc
    or eax,eax
    stc
    jz get_module_name_done16
;    
    call ds:mod_get_name_proc

get_module_name_done16:
    pop edi
    pop bx
    pop ds
    ret
get_module_name16  Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartWaitForDebugEvent
;
;		DESCRIPTION:	Start a wait for debug event
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_debug_event	PROC far
    push ds
    push eax
    push bx
;
    mov bx,es:dew_handle
    mov ax,MODULE_HANDLE
    DerefHandle
    jc start_wait_for_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz start_wait_for_done
;
    mov ds,bx
    mov eax,ds:mod_start_wait_for_debug_event_proc
    or eax,eax
    stc
    jz start_wait_for_done
;    
    call ds:mod_start_wait_for_debug_event_proc

start_wait_for_done:
    pop bx
    pop eax
    pop ds
    ret
start_wait_for_debug_event Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopWaitForDebugEvent
;
;		DESCRIPTION:	Stop a wait for debug event
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_debug_event	PROC far
    push ds
    push eax
    push bx
;
    mov bx,es:dew_handle
    mov ax,MODULE_HANDLE
    DerefHandle
    jc stop_wait_for_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz stop_wait_for_done
;
    mov ds,bx
    mov eax,ds:mod_stop_wait_for_debug_event_proc
    or eax,eax
    stc
    jz stop_wait_for_done
;    
    call ds:mod_stop_wait_for_debug_event_proc

stop_wait_for_done:
    pop bx
    pop eax
    pop ds
    ret
stop_wait_for_debug_event Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DummyClearDebugEvent
;
;		DESCRIPTION:	Clear debug event
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_clear_debug_event	PROC far
    ret
dummy_clear_debug_event Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsDebugEventIdle
;
;		DESCRIPTION:	Check if debug event is idle
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_debug_event_idle	PROC far
    push ds
    push eax
    push bx
;
    mov bx,es:dew_handle
    mov ax,MODULE_HANDLE
    DerefHandle
    jc is_idle_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz is_idle_done
;
    mov ds,bx
    mov eax,ds:mod_is_debug_event_idle_proc
    or eax,eax
    stc
    jz is_idle_done
;    
    call ds:mod_is_debug_event_idle_proc

is_idle_done:
    pop bx
    pop eax
    pop ds
    ret
is_debug_event_idle Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddWaitForDebugEvent
;
;		DESCRIPTION:	Add a wait for debug event
;
;		PARAMETERS:		AX      Module handle
;                       BX      Wait handle
;                       ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_debug_event_name	DB 'Add Wait For Debug Event',0

add_wait_tab:
aw0	DW OFFSET start_wait_for_debug_event,    	kernel_code
aw1 DW OFFSET stop_wait_for_debug_event,		kernel_code
aw2	DW OFFSET dummy_clear_debug_event,			kernel_code
aw3	DW OFFSET is_debug_event_idle,		    	kernel_code

add_wait_for_debug_event	PROC far
	push ds
	push es
	push eax
	push di
;
    push ax
    mov ax,cs
    mov es,ax
   	mov ax,SIZE debug_event_wait_header - SIZE wait_obj_header
    mov di,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;
	mov es:dew_handle,ax

add_wait_done:
    pop di
    pop eax
    pop es
    pop ds
	retf32
add_wait_for_debug_event	ENDP

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDebugEvent
;
;		DESCRIPTION:    Get current debug event
;
;		PARAMETERS:		BX      Module handle
;
;       RETURNS:        AX      Thread ID
;                       BL      Event type  
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event_name	DB 'Get Debug Event',0

get_debug_event  Proc far
    push ds
    push ecx
;    
    push ax
	mov ax,MODULE_HANDLE
	DerefHandle
	pop ax
	jc get_debug_event_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_debug_event_done
;
    mov ds,bx
    mov ecx,ds:mod_get_debug_event_proc
    or ecx,ecx
    stc
    jz get_debug_event_done
;    
    call ds:mod_get_debug_event_proc

get_debug_event_done:
    pop ecx
    pop ds
    retf32
get_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDebugEventData
;
;		DESCRIPTION:    Get debug event data
;
;       PARAMETERS:		BX		    Handle
;                       ES:(E)DI	Event buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event_data_name	DB 'Get Debug Event Data',0

get_debug_event_data32  Proc far
    push ds
    push eax
    push bx
;    
	mov ax,MODULE_HANDLE
	DerefHandle
	jc get_debug_event_data_done32
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_debug_event_data_done32
;
    mov ds,bx
    mov eax,ds:mod_get_debug_event_data_proc
    stc
    jz get_debug_event_data_done32
;    
    call ds:mod_get_debug_event_data_proc

get_debug_event_data_done32:
    pop bx
    pop eax
    pop ds
    retf32
get_debug_event_data32  Endp

get_debug_event_data16  Proc far
    push ds
    push eax
    push bx
    push edi
;    
    movzx edi,di
	mov ax,MODULE_HANDLE
	DerefHandle
	jc get_debug_event_data_done16
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz get_debug_event_data_done16
;
    mov ds,bx
    mov eax,ds:mod_get_debug_event_data_proc
    or eax,eax
    stc
    jz get_debug_event_data_done16
;    
    call ds:mod_get_debug_event_data_proc

get_debug_event_data_done16:
    pop edi
    pop bx
    pop eax
    pop ds
    ret
get_debug_event_data16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    ClearDebugEvent
;
;		DESCRIPTION:    Clear debug event
;
;       PARAMETERS:		BX		Module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_debug_event_name	DB 'Clear Debug Event',0

clear_debug_event  Proc far
    push ds
    push bx
    push ecx
;    
    push ax
	mov ax,MODULE_HANDLE
	DerefHandle
	pop ax
	jc clear_debug_event_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz clear_debug_event_done
;
    mov ds,bx
    mov ecx,ds:mod_clear_debug_event_proc
    or ecx,ecx
    stc
    jz clear_debug_event_done
;    
    call ds:mod_clear_debug_event_proc

clear_debug_event_done:
    pop ecx
    pop bx
    pop ds
    retf32
clear_debug_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    ContinueDebugEvent
;
;		DESCRIPTION:    Continue debug event
;
;       PARAMETERS:		BX		Module handle
;                       EAX	    Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

continue_debug_event_name	DB 'Continue Debug Event',0

continue_debug_event  Proc far
    push ds
    push bx
    push ecx
;    
    push ax
	mov ax,MODULE_HANDLE
	DerefHandle
	pop ax
	jc continue_debug_event_done
;
    mov bx,[bx].mh_sel
    or bx,bx
    stc
    jz continue_debug_event_done
;
    mov ds,bx
    mov ecx,ds:mod_continue_debug_event_proc
    or ecx,ecx
    stc
    jz continue_debug_event_done
;    
    call ds:mod_continue_debug_event_proc

continue_debug_event_done:
    pop ecx
    pop bx
    pop ds
    retf32
continue_debug_event  Endp

code	ENDS

END
