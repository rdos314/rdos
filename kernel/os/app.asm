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

INCLUDE system.def
INCLUDE system.inc
INCLUDE int.def
INCLUDE protseg.def
INCLUDE os.def
INCLUDE os.inc
INCLUDE user.def
INCLUDE user.inc

app_data_seg	STRUC

app_alloc_base		DD ?

open_app_hooks		DB ?
close_app_hooks		DB ?

open_app_arr		DW 2*8 DUP(?)
close_app_arr		DW 2*8 DUP(?)

app_data_seg	ENDS

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
	mov ds:app_get_exe_proc,0
	mov ds:app_get_cmd_line_proc,0
	mov ds:app_get_env_proc,0
	mov ds:app_allocate_mem_proc,0
	mov ds:app_free_mem_proc,0
	mov ds:app_init_thread_proc,0
	mov ds:app_free_thread_proc,0
	mov ds:app_spawn_proc,0
	mov ds:app_close_proc,0
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

code	ENDS

END
