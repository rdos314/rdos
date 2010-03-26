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
						
		NAME proc

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\handle.inc
include ..\wait.inc
include proc.inc

thread_data_seg	STRUC

create_thread_hooks		DB ?
terminate_thread_hooks	DB ?
create_process_hooks	DB ?
terminate_process_hooks	DB ?
init_tasking_hooks		DB ?

create_process_arr		DW 2*32 DUP(?)
terminate_process_arr	DW 2*32 DUP(?)
create_thread_arr		DW 2*8 DUP(?)
terminate_thread_arr	DW 2*8 DUP(?)
init_tasking_arr		DW 2*32 DUP(?)

thread_data_seg	ENDS

proc_handle_seg		STRUC

ph_base	handle_header <>

ph_lib_sel              DW ?
ph_proc_sel             DW ?

proc_handle_seg		ENDS

proc_end_wait_header	STRUC

pew_obj		    	wait_obj_header <>
pew_proc_sel		DW ?

proc_end_wait_header	ENDS

process_callback_seg	STRUC
cm_mode		DW ?
cm_stack	DD ?
cm_process	DW ?
cm_cs		DW ?
cm_eip		DD ?
cm_flags	DW ?
cm_eax		DD ?
cm_ebx		DD ?
cm_ecx		DD ?
cm_edx		DD ?
cm_esi		DD ?
cm_edi		DD ?
cm_ebp		DD ?
process_callback_seg	ENDS

cr_seg		EQU 28
cr_offs		EQU 24
cr_prio		EQU 22
cr_stack	EQU 18
cr_mode		EQU 16
cr_name		EQU 10
cr_cs		EQU 8
cr_eip		EQU 4
cr_ebp		EQU 0
cr_flags	EQU -2
cr_ds		EQU -4
cr_es		EQU -6
cr_fs		EQU -8
cr_gs		EQU -10
cr_eax		EQU -14
cr_ebx		EQU -18
cr_ecx		EQU -22
cr_edx		EQU -26
cr_esi		EQU -30
cr_edi		EQU -34


	.386p

code	SEGMENT byte public use16 'CODE'

    extrn cleanup_thread:near
    extrn cleanup_process:near

	extrn wake_new:near

	extrn init_process_paging:near
	extrn free_process_paging:near
	extrn init_process_mem:near
	extrn init_process_app:near
	extrn init_task_traps:near
	extrn init_task_tasks:near
	extrn trap_single_step:near
	extrn free_handle_process:near

	assume cs:code
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateProcHandle
;
;		DESCRIPTION:	Create a process handle
;
;       PARAMETERS:     AX      Lib selector
;                       DX      Process descriptor
;
;       RETURNS:        BX      Process handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_proc_handle_name	DB 'Create Process Handle',0

create_proc_handle	PROC far
    push ds
    push cx
	mov cx,SIZE proc_handle_seg
	AllocateHandle
	mov [bx].ph_lib_sel,ax
	mov [bx].ph_proc_sel,dx
	mov [bx].hh_sign,PROCESS_HANDLE
	mov bx,[bx].hh_handle
;
    mov ds,dx
    inc ds:pd_ref_count
;    	
    pop cx
    pop ds
    ret
create_proc_handle  Endp    
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DerefProcHandle
;
;		DESCRIPTION:	Deref a process handle
;
;       PARAMETERS:     BX      Process handle
;
;       RETURNS:        AX      Lib selector
;                       DX      Process descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

deref_proc_handle_name	DB 'Deref Process Handle',0

deref_proc_handle	PROC far
    push ds
    push bx
;    
	mov ax,PROCESS_HANDLE
	DerefHandle
	jc deref_proc_handle_done
;
	mov ax,[bx].ph_lib_sel
	mov dx,[bx].ph_proc_sel
	clc

deref_proc_handle_done:
    pop bx
    pop ds
    ret
deref_proc_handle   Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeProcHandle
;
;		DESCRIPTION:	Free a process handle
;
;       PARAMETERS:     BX      Process handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_proc_handle_name	DB 'Free Process Handle',0

free_proc_handle	PROC far
    push ds
    push ax
    push bx
    push dx
;    
	mov ax,PROCESS_HANDLE
	DerefHandle
	jc free_proc_handle_done
;
	mov dx,[bx].ph_proc_sel
	FreeHandle
;	
    mov ds,dx
    sub ds:pd_ref_count,1
    jnz free_proc_handle_done
;
    push es
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem        
    pop es
    clc

free_proc_handle_done:
    pop dx
    pop bx
    pop ax
    pop ds
    retf32
free_proc_handle    Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetProcExitCode
;
;		DESCRIPTION:	Get process exit code
;
;       PARAMETERS:     BX      Process handle
;
;       RETURNS:        AX      Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_proc_exit_code_name	DB 'Get Process Exit Code',0

get_proc_exit_code	PROC far
    push ds
    push bx
;    
	mov ax,PROCESS_HANDLE
	DerefHandle
	mov ax,-1
	jc get_proc_exit_done
;
	mov ds,[bx].ph_proc_sel
	mov ax,ds:pd_exit_code
	clc

get_proc_exit_done:
    pop bx
    pop ds
    retf32
get_proc_exit_code   Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartWaitForProcEnd
;
;		DESCRIPTION:	Start a wait for process end event
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_proc_end	PROC far
    push ds
    push eax
;
	ClearSignal
    mov ax,es:pew_proc_sel
    mov ds,ax
	mov ds:pd_wait,es
;
	mov ax,ds:pd_proc_sel
	or ax,ax
    jnz start_wait_done
;
	mov ds:pd_wait,0
    SignalWait

start_wait_done:    
    pop eax
    pop ds
    ret
start_wait_for_proc_end Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopWaitForProcEnd
;
;		DESCRIPTION:	Stop a wait for process end event
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_proc_end	PROC far
    push ds
    push eax
;
    mov ax,es:pew_proc_sel
    mov ds,ax
	mov ds:pd_wait,0
;    
    pop eax
    pop ds
    ret
stop_wait_for_proc_end Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DummyClearProcEnd
;
;		DESCRIPTION:	Clear process end event
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_clear_proc_end	PROC far
    ret
dummy_clear_proc_end Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsProcEndIdle
;
;		DESCRIPTION:	Check if proc end is idle
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_proc_end_idle	PROC far
    push ds
    push eax
;
    mov ax,es:pew_proc_sel
    mov ds,ax
	mov ax,ds:pd_proc_sel
	or ax,ax
	clc
	jne is_idle_done
;
	stc

is_idle_done:    
    pop eax
    pop ds
    ret
is_proc_end_idle Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddWaitForProcEnd
;
;		DESCRIPTION:	Add a wait for process end
;
;		PARAMETERS:		AX      Process handle
;                       BX      Wait handle
;                       ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_proc_end_name	DB 'Add Wait For Process End',0

add_wait_tab:
aw0	DW OFFSET start_wait_for_proc_end,    	kernel_code
aw1 DW OFFSET stop_wait_for_proc_end,		kernel_code
aw2	DW OFFSET dummy_clear_proc_end,			kernel_code
aw3	DW OFFSET is_proc_end_idle,		    	kernel_code

add_wait_for_proc_end	PROC far
	push ds
	push es
	push eax
	push dx
	push di
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
   	mov ax,SIZE proc_end_wait_header - SIZE wait_obj_header
    mov di,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;    
	mov es:pew_proc_sel,dx

add_wait_done:
    pop di
    pop dx
    pop eax
    pop es
    pop ds
	retf32
add_wait_for_proc_end	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_THREAD
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_user_start:
	TerminateThread
terminate_user_end:

	public init_thread

init_thread	PROC near
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
	mov edx,thread_block_linear
	mov ecx,SIZE thread_seg
	mov bx,thread_sel
	CreateDataSelector16
;
	mov edx,thread_tss_linear
	mov ecx,400h
	mov bx,thread_tss_sel
	CreateDataSelector16
;
;	mov edx,thread_ss0_linear
;	mov ecx,200h
;	mov bx,thread_ss0_sel
;	CreateDataSelector16
;
	mov edx,fixed_process_linear
	mov ecx,SIZE process_seg
	mov bx,process_sel
	CreateDataSelector16
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov bx,OFFSET create_thread16
	mov si,OFFSET create_thread32
	mov di,OFFSET create_thread_name
	mov dx,virt_seg_in
	mov ax,create_thread_nr
	RegisterUserGate
;
	mov si,OFFSET terminate_thread
	mov di,OFFSET terminate_thread_name
	xor dx,dx
	mov ax,terminate_thread_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET create_process
	mov di,OFFSET create_process_name
	xor cl,cl
	mov ax,create_process_nr
	RegisterOsGate
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
	mov si,OFFSET create_proc_handle
	mov di,OFFSET create_proc_handle_name
	xor cl,cl
	mov ax,create_proc_handle_nr
	RegisterOsGate
;
	mov si,OFFSET deref_proc_handle
	mov di,OFFSET deref_proc_handle_name
	xor cl,cl
	mov ax,deref_proc_handle_nr
	RegisterOsGate
;
	mov si,OFFSET free_proc_handle
	mov di,OFFSET free_proc_handle_name
	xor dx,dx
	mov ax,free_proc_handle_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_proc_exit_code
	mov di,OFFSET get_proc_exit_code_name
	xor dx,dx
	mov ax,get_proc_exit_code_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET add_wait_for_proc_end
	mov di,OFFSET add_wait_for_proc_end_name
	xor dx,dx
	mov ax,add_wait_for_proc_end_nr
	RegisterBimodalUserGate
;
	pop ds
	popa
	ret
init_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRAP_CREATE_THREAD
;
;		DESCRIPTION:	Handle CreateThread hooks
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_create_thread	PROC near
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
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz trap_create_thread_loop
trap_create_thread_done:
	pop cx
	retf
trap_create_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRAP_TERMINATE_THREAD
;
;		DESCRIPTION:	Handle TerminateThread hooks
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_terminate_thread	PROC near
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
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
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
trap_terminate_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRAP_CREATE_PROCESS
;
;		DESCRIPTION:	Handle CreateProcess hooks
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_create_process	PROC near
	sti
	push cx
	push si
;    
	call init_process_mem
	call init_process_app
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
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz trap_create_process_loop
trap_create_process_done:
	pop si
	pop cx
;
    xor bp,bp
	push cs
	call trap_create_thread
	ret
trap_create_process	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRAP_TERMINATE_PROCESS
;
;		DESCRIPTION:	Handle TerminateProcess hooks
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_terminate_process	PROC near
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
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz trap_terminate_process_loop
trap_terminate_process_done:
	pop cx
	ret
trap_terminate_process	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRAP_INIT_TASKING
;
;		DESCRIPTION:	Handle init-tasking hooks
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_init_tasking	PROC near
	call init_task_tasks
	call init_task_traps
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
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz trap_init_tasking_loop
trap_init_tasking_done:
	pop cx
	ret
trap_init_tasking	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_CREATE_THREAD
;
;		DESCRIPTION:	Add CreateThread hook
;
;		PARAMETERS:		ES:DI		Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_create_thread_name	DB 'Hook Create Thread',0

hook_create_thread	PROC far
	push ds
	push ax
	push bx
	mov ax,proc_data_sel
	mov ds,ax
	mov al,ds:create_thread_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET create_thread_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:create_thread_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_create_thread	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_TERMINATE_THREAD
;
;		DESCRIPTION:	Add TerminateThread hook
;
;		PARAMETERS:		ES:DI		Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_terminate_thread_name	DB 'Hook Terminate Thread',0

hook_terminate_thread	PROC far
	push ds
	push ax
	push bx
	mov ax,proc_data_sel
	mov ds,ax
	mov al,ds:terminate_thread_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET terminate_thread_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:terminate_thread_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_terminate_thread	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_CREATE_PROCESS
;
;		DESCRIPTION:	Add CreateProcess hook
;
;		PARAMETERS:		ES:DI		Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_create_process_name	DB 'Hook Create Process',0

	public hook_create_process

hook_create_process	PROC far
	push ds
	push ax
	push bx
	mov ax,proc_data_sel
	mov ds,ax
	mov al,ds:create_process_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET create_process_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:create_process_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_create_process	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_TERMINATE_PROCESS
;
;		DESCRIPTION:	Add TerminateProcess hook
;
;		PARAMETERS:		ES:DI		Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_terminate_process_name	DB 'Hook Terminate Process',0

hook_terminate_process	PROC far
	push ds
	push ax
	push bx
	mov ax,proc_data_sel
	mov ds,ax
	mov al,ds:terminate_process_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET terminate_process_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:terminate_process_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_terminate_process	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_INIT_TASKING
;
;		DESCRIPTION:	Add init-tasking hook
;
;		PARAMETERS:		ES:DI		Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_init_tasking_name	DB 'Hook Init Tasking',0

hook_init_tasking	PROC far
	push ds
	push ax
	push bx
	mov ax,proc_data_sel
	mov ds,ax
	mov al,ds:init_tasking_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET init_tasking_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:init_tasking_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_init_tasking	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_THREAD_BLOCK
;
;		DESCRIPTION:	Allocate thread control block
;
;		PARAMETERS:		ES		Thread control block
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_thread_block	PROC near
	mov eax,1000h
	AllocateBigLinear
	AllocateGdt
	mov ecx,eax
	CreateDataSelector16
	mov es,bx
	mov es:p_thread_sel,bx
;
	mov eax,edx
	shr eax,10
	mov bx,sys_page_sel
	mov fs,bx
	mov eax,fs:[eax]
	mov es:p_thread_page,eax
;
	add edx,200h
	AllocateGdt
	mov ecx,400h
	CreateTssSelector
	mov es:p_tss_sel,bx
;
	AllocateGdt
	CreateDataSelector16
	mov es:p_tss_data_sel,bx
	ret
allocate_thread_block	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_THREAD_BLOCK
;
;		DESCRIPTION:	Init thread content
;
;		PARAMETERS:		ES		Thread
;						DX		Priority
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread_block	PROC near
	GetThread
	mov ds,ax
;
	mov si,thread_linear - thread_block_linear
	mov di,si
	mov cx,(1000h - thread_linear + thread_block_linear) SHR 2
	rep movsd
;
	push fs
	mov ax,ds:p_process_sel
	mov fs,ax
	inc fs:ms_thread_count
	mov es:p_process_sel,ax
	pop fs
;
	mov ax,ds:p_app_sel
	mov es:p_app_sel,ax
	mov eax,ds:p_app_page
	mov es:p_app_page,eax
	mov ax,ds:p_ldt_sel
	mov es:p_ldt_sel,ax
	mov ax,ds:p_lib_sel
	mov es:p_lib_sel,ax
	mov es:p_signal,0
	mov es:p_parent_switch,0
	mov es:p_wait_list,0
	mov es:p_kill,0
	mov es:p_ref_count,0
	mov es:p_is_waiting,0
;
	add dx,dx
	mov es:p_prio,dx
	xor eax,eax
	mov es:p_msb_tics,eax
	mov es:p_lsb_tics,eax
	mov es:p_vm_deb_sel,ax
	mov es:p_vm_deb_offs,eax
	mov es:p_pm_deb_sel,ax
	mov es:p_pm_deb_offs,eax
	mov es:p_events,0
;
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,0
	push ds
	mov ax,system_data_sel
	mov ds,ax
	cli
	mov ax,ds:next_pid
	mov es:p_id,ax
	inc ax
	mov ds:next_pid,ax
	sti
	pop ds
	ret
init_thread_block	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROCESS_BLOCK
;
;		DESCRIPTION:	Init process content
;
;		PARAMETERS:		ES		Thread
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


init_process_block	PROC near
	push es
	mov eax,SIZE process_seg
	AllocateSmallGlobalMem
	mov es:ms_virt_flags,7200h
	mov es:ms_wait_sti,0
	mov es:ms_thread_count,1
	mov bx,es
;	
	mov eax,SIZE proc_descr_seg
	AllocateSmallGlobalMem
	mov es:pd_proc_sel,bx
	mov es:pd_exit_code,0
	mov es:pd_ref_count,1
	mov es:pd_wait,0
;	
	push ds
	push esi
	mov si,es
	mov ds,si
	mov esi,OFFSET pd_section
	InitSection
	pop esi
	pop ds
;    
    mov ax,es
    mov es,bx
    mov es:ms_pd_sel,ax
;	
	pop es
	mov es:p_process_sel,bx
;
	push fs
	push es
	mov eax,1000h
	AllocateBigLinear
	AllocateGdt
	mov ecx,eax
	CreateDataSelector16
	mov fs,bx
	mov fs:app_next,0
	mov fs:app_sel,fs
;
	shr edx,10
	mov ax,sys_page_sel
	mov es,ax
	mov eax,es:[edx]
	pop es
	mov es:p_app_sel,bx
	mov es:p_app_page,eax
	mov fs:app_page,eax
	pop fs
;
	mov es:p_ldt_sel,0
;
	xor eax,eax
	mov di,thread_linear - thread_block_linear
	mov cx,(1000h - thread_linear + thread_block_linear) SHR 2
	rep stosd
	ret
init_process_block	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROT_THREAD
;
;		DESCRIPTION:	Init protected mode thread
;
;		PARAMETERS:		ES		Thread
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_prot_thread	PROC near
	push ds
	lds esi,[bp].cr_name
	mov di,OFFSET thread_name
	mov cx,30
pm_move_thread_name:
	lods byte ptr [esi]
	or al,al
	jz pm_move_pad_name
	stosb
	loop pm_move_thread_name
	jmp pm_move_pad_done
pm_move_pad_name:
	mov al,' '
	rep stosb
pm_move_pad_done:
	pop ds
	ret
init_prot_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_VIRT_THREAD
;
;		DESCRIPTION:	Init V86 mode thread
;
;		PARAMETERS:		ES		Thread
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_virt_thread	PROC near
	push ds
	xor eax,eax
	mov ax,[bp].cr_name
	xor edx,edx
	mov dx,[bp+4].cr_name
	shl edx,4
	add edx,eax
	mov ax,flat_sel
	mov ds,ax
	mov di,OFFSET thread_name
	mov cx,30
vm_move_thread_name:
	mov al,[edx]
	or al,al
	jz vm_move_pad_name
	inc edx
	stosb
	loop vm_move_thread_name
	jmp vm_move_pad_done
vm_move_pad_name:
	mov al,' '
	rep stosb
vm_move_pad_done:
	pop ds
	ret
init_virt_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DEFAULT_TSS
;
;		DESCRIPTION:	Setup default TSS contents
;
;		PARAMETERS:		DS		TSS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_default_tss	PROC near
	xor cx,cx
	xor bx,bx
	xor edx,edx
	mov [bx],edx
;
	mov dx,stack0_size
	add bx,4
	mov [bx],edx
;	
	push es
	push eax
	mov eax,stack0_size
	AllocateSmallGlobalMem
	mov dx,es
	pop eax
	pop es
	add bx,4
	mov [bx],edx
;
	xor dx,dx
	add bx,4
	mov [bx],edx
	add bx,4
	mov [bx],edx
;
	add bx,4
	mov [bx],edx
	add bx,4
	mov [bx],edx
	add bx,4
;
	mov edx,cr3
	mov es:p_cr3,edx
	mov [bx],edx
	add bx,4
	mov edx,[bp].cr_offs
	mov [bx],edx
	add bx,8
	mov edx,[bp].cr_eax
	mov [bx],edx
	add bx,4
	mov edx,[bp].cr_ecx
	mov [bx],edx
	add bx,4
	mov edx,[bp].cr_edx
	mov [bx],edx
	add bx,4
	mov edx,[bp].cr_ebx
	mov [bx],edx
	add bx,8
	mov edx,[bp].cr_ebp
	mov [bx],edx
	add bx,4
	mov edx,[bp].cr_esi
	mov [bx],edx
	add bx,4
	mov edx,[bp].cr_edi
	mov [bx],edx
	xor edx,edx
	add bx,8
	mov dx,[bp].cr_seg
	mov [bx],edx
	mov bx,OFFSET tss_ldt
	sldt dx
	mov [bx],edx
	add bx,4
	mov dx,1
	mov [bx],dx
	mov word ptr [bx+2],OFFSET tss_bitmap_space
	add bx,4
;
; dr0 - dr7
;
	xor edx,edx
	mov ds:tss_dr0,edx
	mov ds:tss_dr1,edx
	mov ds:tss_dr2,edx
	mov ds:tss_dr3,edx
	mov ds:tss_dr7,edx
;
; 387 status
;
	mov ds:math_control,37Fh
	mov ds:math_status,0
	mov ds:math_tag,0FFFFh
	mov ds:math_eip,0
	mov ds:math_cs,0
	mov ds:math_data_offs,0
	mov ds:math_data_sel,0
;
; thread control
;
	mov ds:tss_thread,es
	mov ds:tss_error_code,dx
;
	push ds
	push es
	push si
	push di
	mov ax,ds
	mov es,ax
	mov di,OFFSET tss_bitmap_space
	mov cx,40h
	mov ax,io_bitmap_sel
	mov ds,ax
	xor si,si
	rep movsw
	mov bx,di
	pop di
	pop si
	pop es
	pop ds
	mov al,0
	mov cx,tss_size
fill_bm_vm_more:
	mov [bx],al
	inc bx
	cmp bx,cx
	jb fill_bm_vm_more		
	mov byte ptr [bx-1],0FFh
	ret
init_default_tss	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROT_TSS
;
;		DESCRIPTION:	Init protected mode TSS
;
;		PARAMETERS:		DS			TSS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_prot_tss	PROC near
	push fs
;
	mov ax,thread_app_sel
	mov fs,ax
;
	mov dx,[bp].cr_flags
	or dx,200h
	and dx,NOT 7000h
	mov ds:tss_eflags,dx
	mov ds:tss_eflags+2,0
;
	mov es:p_free_proc,0
	mov ax,[bp].cr_seg
	test ax,3
	jz init_kernel_tss
;
	mov eax,fs:app_init_thread_proc
	or eax,eax
	jz init_prot_tss_default
;
	mov eax,fs:app_free_thread_proc
	mov es:p_free_proc,eax
;
	mov eax,[bp].cr_stack
	mov es:p_stack_sel,0
	call fs:app_init_thread_proc
	pop fs
	ret

init_prot_tss_default:
	push es
	mov eax,[bp].cr_stack
	AllocateLocalMem
	sub eax,6
	mov dword ptr ds:tss_esp,eax
	mov ds:tss_ss,es
	mov ds:tss_ss+2,0
	mov es:[eax+4],dx
	mov word ptr es:[eax+2],term_code_sel
	mov word ptr es:[eax],0
	mov bx,es
	pop es
	mov es:p_stack_sel,bx
	jmp init_prot_tss_com

init_kernel_tss:
    push es
    movzx eax,ds:tss_ess0
    mov dword ptr ds:tss_ss,eax
    mov bx,stack0_size - 6
    mov es,ax
    mov es:[bx+4],dx
    mov es:[bx+2],cs
    mov word ptr es:[bx],OFFSET terminate_thread
    pop es
	mov dword ptr ds:tss_esp,stack0_size - 6
	mov es:p_stack_sel,0

init_prot_tss_com:
	mov bx,OFFSET tss_es
	mov ax,[bp].cr_es
	mov [bx],eax
	add bx,0Ch
	mov ax,[bp].cr_ds
	mov [bx],eax
	add bx,4
	mov ax,[bp].cr_fs
	mov [bx],eax
	add bx,4
	mov ax,[bp].cr_gs
	mov [bx],eax
	pop fs
	ret
init_prot_tss	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_VIRT_TSS
;
;		DESCRIPTION:	Init V86 mode TSS
;
;		PARAMETERS:		DS		TSS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_virt_tss	PROC near
	push es
	xor eax,eax
	mov ax,[bp].cr_stack
	AllocateDosMem
	push eax
	mov ax,es
	SelectorToSegment
	mov bx,OFFSET tss_ss
	mov [bx],eax
	pop eax
	sub eax,6
	mov bx,OFFSET tss_esp
	mov [bx],eax
	mov dx,[bp].cr_flags
	or dx,200h
	and dx,NOT 7000h
	mov ds:tss_eflags,dx
	mov ds:tss_eflags+2,2
	mov es:[eax+4],dx
;	mov dx,SEG code
	mov es:[eax+2],dx
;	mov dx,OFFSET terminate_thread_pr
	mov es:[eax],dx
	mov bx,OFFSET tss_es
	mov ax,es
	pop es
	mov es:p_stack_sel,ax
;
	mov ax,[bp].cr_es
	SelectorToSegment
	mov [bx],eax
	add bx,0Ch
;
	mov ax,[bp].cr_ds
	SelectorToSegment
	mov [bx],eax
	add bx,4
;
	mov ax,[bp].cr_fs
	SelectorToSegment
	mov [bx],eax
	add bx,4
;
	mov ax,[bp].cr_gs
	SelectorToSegment
	mov [bx],eax
	ret
init_virt_tss	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CREATE_THREAD
;
;		DESCRIPTION:	Create a thread
;
;		PARAMETERS:		AL			Priority
;						AH			Mode, 0=PM, 1=VM
;						ECX			Stack size
;						DS:(E)SI	Start address
;						ES:(E)DI	Thread name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_thread_name	DB 'Create Thread',0

create_thread	PROC near
	sub sp,30
	push bp
	mov bp,sp
	pushf
	push ds
	push es
	push fs
	push gs
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	mov [bp].cr_seg,ds
	mov [bp].cr_offs,esi
	xor dx,dx
	mov dl,al	
	mov [bp].cr_prio,dx
	mov [bp].cr_stack,ecx
	mov dl,ah
	mov [bp].cr_mode,dx
	mov [bp].cr_name,edi
	mov [bp+4].cr_name,es
	call allocate_thread_block
	mov dx,[bp].cr_prio
	call init_thread_block
	mov ds,es:p_tss_data_sel
	call init_default_tss
	mov ax,[bp].cr_mode
	test ax,1
	jz create_prot
	call init_virt_thread
	call init_virt_tss
	jmp create_tss_done
create_prot:
	call init_prot_thread
	call init_prot_tss
create_tss_done:
;
	mov es:p_trap_ads,OFFSET trap_create_thread
	mov es:p_trap_ads+2,cs
	mov es:p_step_ads,OFFSET trap_single_step
	mov es:p_step_ads+2,cs
	call wake_new
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
;
	pop ax
	verr ax
	jz crp_zero_gs
	xor ax,ax
crp_zero_gs:
	mov gs,ax
;
	pop ax
	verr ax
	jz crp_zero_fs
	xor ax,ax
crp_zero_fs:
	mov fs,ax
;
	pop ax
	verr ax
	jz crp_zero_es
	xor ax,ax
crp_zero_es:
	mov es,ax
;
	pop ax
	verr ax
	jz crp_zero_ds
	xor ax,ax
crp_zero_ds:
	mov ds,ax
	popf
	pop bp
	add sp,30
	ret
create_thread	ENDP

create_thread16	Proc far
	push ecx
	push esi
	push edi
;
	movzx ecx,cx
	movzx esi,si
	movzx edi,di
	call create_thread
;
	pop edi
	pop esi
	pop ecx
	ret
create_thread16	Endp

create_thread32	Proc far
	call create_thread
	retf32
create_thread32	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			TERMINATE_THREAD
;
;		DESCRIPTION:	Terminate thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_thread_name	DB 'Terminate Thread',0

terminate_thread:
	SimSti
	mov ax,thread_sel
	mov ds,ax
	mov bx,ds:p_tss_data_sel
;
	mov ax,system_data_sel
	mov ds,ax
	mov ax,ds:math_tss
	cmp ax,bx
	jne terminate_fpu_ok
;
	mov ds:math_tss,0

terminate_fpu_ok:
	mov ax,thread_sel
	mov ds,ax
	mov al,ds:p_parent_switch
	or al,al
	jz terminate_focus_ok
;
	SetFocus

terminate_focus_ok:
	mov es,ds:p_thread_sel
	mov bx,es:p_stack_sel
	verr bx
	jnz no_free_ss
;
	mov es,bx
	FreeMem

no_free_ss:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_process_sel
	sub ds:ms_thread_count,1
	jz terminate_proc
;
	mov ax,thread_sel
	mov ds,ax
	mov eax,ds:p_free_proc
	or eax,eax
	jz terminate_app_handled
;
	call ds:p_free_proc

terminate_app_handled:
	call trap_terminate_thread
    jmp cleanup_thread

terminate_proc:
	mov bx,thread_sel
	mov ds,bx
	mov ds,ds:p_process_sel
    mov ds,ds:ms_pd_sel
    sub ds:pd_ref_count,1
    jz terminate_free_pd
;
    mov esi,OFFSET pd_section
    EnterSection
;    
    mov ds:pd_proc_sel,0
    mov ax,ds:pd_wait
    or ax,ax
    jz terminate_proc_sig_done
;
	mov es,ax
	SignalWait

terminate_proc_sig_done:   
    mov esi,OFFSET pd_section
    LeaveSection
    xor ax,ax
    mov ds,ax
    jmp terminate_pd_done    

terminate_free_pd:
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem        

terminate_pd_done:
	call trap_terminate_thread
	call free_handle_process
	call trap_terminate_process
	call free_process_paging
    jmp cleanup_process

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROCESS_TSS
;
;		DESCRIPTION:	Init process TSS
;
;		PARAMETERS:		DS		TSS
;						ES		Thread
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_tss	PROC near
	mov ax,OFFSET create_process_callback
	mov ds:tss_eip,ax
	mov ds:tss_eip+2,0
	mov ds:tss_cs,cs
	mov ds:tss_cs+2,0
	mov ax,ds:tss_ess0
	mov ds:tss_ss,ax
	mov ds:tss_ss+2,0
	mov ax,stack0_size
	mov ds:tss_esp,ax
	mov ds:tss_esp+2,0
;
	mov ax,[bp].cr_mode
	test ax,1
	jz init_tss_prot_iopl
	mov ax,[bp].cr_flags
	or dx,200h
	and dx,NOT 7000h
	mov ds:tss_eflags,ax
	mov ds:tss_eflags+2,0
	jmp init_tss_iopl_done
init_tss_prot_iopl:
	mov ax,[bp].cr_flags
	or ax,200h
	and ax,NOT 7000h
	mov ds:tss_eflags,ax
	mov ds:tss_eflags+2,0
init_tss_iopl_done:	
	mov bx,OFFSET tss_es
	xor eax,eax
	mov [bx],eax
	add bx,0Ch
	mov [bx],eax
	add bx,4
	mov [bx],eax
	add bx,4
	mov [bx],eax
	mov ds:tss_t,0
	ret
init_process_tss	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROCESS_CALLBACK
;
;		DESCRIPTION:	Init process data
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_callback	PROC near
	push es
	mov eax,1000h
	AllocateGlobalMem
	mov ds:tss_ds,es
;
	mov ax,[bp].cr_mode
	mov es:cm_mode,ax
	mov eax,[bp].cr_stack
	mov es:cm_stack,eax
	mov es:cm_process,fs
	mov ax,[bp].cr_flags
	mov es:cm_flags,ax
	mov ax,[bp].cr_seg
	mov es:cm_cs,ax
	mov eax,[bp].cr_offs
	mov es:cm_eip,eax
	mov eax,[bp].cr_eax
	mov es:cm_eax,eax
	mov eax,[bp].cr_ebx
	mov es:cm_ebx,eax
	mov eax,[bp].cr_ecx
	mov es:cm_ecx,eax
	mov eax,[bp].cr_edx
	mov es:cm_edx,eax
	mov eax,[bp].cr_esi
	mov es:cm_esi,eax
	mov eax,[bp].cr_edi
	mov es:cm_edi,eax
	mov eax,[bp].cr_ebp
	mov es:cm_ebp,eax
	pop es
	ret
init_process_callback	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_ENVIROMENT
;
;		DESCRIPTION:	Create paging environment
;
;		PARAMETERS:		ES		Thread
;						EAX		CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_enviroment	PROC near
	push ds
	push es
	mov eax,3000h
	AllocateGlobalMem
	mov ax,sys_dir_sel
	mov ds,ax
	xor ax,ax
	mov di,1000h
	mov cx,system_mem_start SHR 22
	rep stosd
	mov si,system_mem_start SHR 20
	mov cx,400h - system_mem_start SHR 22
	rep movsd
;
	mov ax,sys_page_sel
	mov ds,ax
	xor si,si
	mov cx,400h
	xor eax,eax
	rep movsd
;
	mov ax,gdt_sel
	mov ds,ax
	mov bx,es
	mov edx,[bx+2]
	rol edx,8
	mov dl,[bx+7]
	ror edx,8
	shr edx,10
;
	mov ax,sys_page_sel
	mov ds,ax
	mov eax,[edx+8]
	mov di,1000h
	mov es:[di],eax
;
	mov eax,[edx+4]
	mov al,7
	mov bx,process_page_linear SHR 20
	mov es:[bx+di],eax
;
	mov dx,es
	mov fs,dx
	pop es
	pop ds
	mov es:p_cr3,eax
	mov dword ptr ds:tss_cr3,eax
	ret
create_enviroment	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_PROCESS
;
;		DESCRIPTION:	Create process
;
;		PARAMETERS:		AL			Priority
;						AH			Mode, 0=PM, 1=VM
;						ECX			Stack size
;						DS:SI		Start address
;						ES:DI		Thread name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_process_name	DB 'Create Process',0

create_process	PROC far
	sub sp,30
	push bp
	mov bp,sp
	pushf
	push ds
	push es
	push fs
	push gs
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	movzx esi,si
	movzx edi,di
	mov [bp].cr_seg,ds
	mov [bp].cr_offs,esi
	xor dx,dx
	mov dl,al	
	mov [bp].cr_prio,dx
	mov [bp].cr_stack,ecx
	mov dl,ah
	mov [bp].cr_mode,dx
	mov [bp].cr_name,edi
	mov [bp+4].cr_name,es
	xor ax,ax
	mov fs,ax
	mov gs,ax
	call allocate_thread_block
	mov dx,[bp].cr_prio
	call init_thread_block
	call init_process_block
	mov ds,es:p_tss_data_sel
	call init_default_tss
	call create_enviroment
	mov ax,[bp].cr_mode
	test ax,1
	jz create_mod_prot
	call init_virt_thread
	jmp create_mod_tss_done
create_mod_prot:
	call init_prot_thread
create_mod_tss_done:
	call init_process_tss
	call init_process_callback
;
	mov es:p_step_ads,OFFSET trap_single_step
	mov es:p_step_ads+2,cs
	call wake_new
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
;
	pop ax
	verr ax
	jz crm_zero_gs
	xor ax,ax
crm_zero_gs:
	mov gs,ax
;
	pop ax
	verr ax
	jz crm_zero_fs
	xor ax,ax
crm_zero_fs:
	mov fs,ax
;
	pop ax
	verr ax
	jz crm_zero_es
	xor ax,ax
crm_zero_es:
	mov es,ax
;
	pop ax
	verr ax
	jz crm_zero_ds
	xor ax,ax
crm_zero_ds:
	mov ds,ax
	popf
	pop bp
	add sp,30
	ret
create_process	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_VIRT_CALLBACK_FRAME
;
;		DESCRIPTION:	Create V86 mode IRETD stack frame
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_virt_callback_frame	PROC near
	pop bp
	xor eax,eax
	push eax
	push eax
	push eax
	push eax
	mov eax,ds:cm_stack
	AllocateDosMem
	mov ax,es
	SelectorToSegment
	push 0
	push ax
;
	mov eax,ds:cm_stack
	push eax
;
	push 2
	mov ax,ds:cm_flags
	or ax,3200h
	and ax,NOT 4000h
	push ax
;
	mov ax,ds:cm_cs
	push eax
;
	mov eax,ds:cm_eip
	push eax
;
	push bp
	ret
init_virt_callback_frame	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROT_CALLBACK_FRAME
;
;		DESCRIPTION:	Create protected mode IRETD stack frame
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_prot_callback_frame	PROC near
	pop bp
	xor eax,eax
	mov eax,ds:cm_stack
	AllocateLocalMem
;
	push 0
	push es
;
	push eax
;
	push 0
	mov ax,ds:cm_flags
	or ax,200h
	and ax,NOT 7000h
	push ax
;
	mov ax,ds:cm_cs
	push eax
;
	mov eax,ds:cm_eip
	push eax
;
	push bp
	ret
init_prot_callback_frame	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CREATE_PROCESS_CALLBACK
;
;		DESCRIPTION:	Process startup (in new address space)
;
;		PARAMETERS:		DS		Process data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_process_callback:
	mov ax,thread_sel
	mov fs,ax
	push ds
	call trap_create_process
	pop ds
	mov es,ds:cm_process
	mov ax,ds:cm_mode
	test ax,1
	jz create_callback_prot
	call init_virt_callback_frame
	jmp create_callback_frame_done
create_callback_prot:
	call init_prot_callback_frame
create_callback_frame_done:
	mov eax,ds:cm_eax
	mov ebx,ds:cm_ebx
	mov ecx,ds:cm_ecx
	mov edx,ds:cm_edx
	mov esi,ds:cm_esi
	mov edi,ds:cm_edi
	mov ebp,ds:cm_ebp
	push ax
	mov ax,ds
	mov es,ax
	xor ax,ax
	mov ds,ax
	mov fs,ax
	mov gs,ax
	FreeMem
	pop ax
	iretd
;

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_FIRST_THREAD
;
;		DESCRIPTION:	Init first thread control block
;
;		PARAMETERS:		ES		Thread
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

null_name	DB 'Null',0

init_first_thread	PROC near
	xor eax,eax
	mov es:p_prio,ax
	mov es:p_msb_tics,eax
	mov es:p_lsb_tics,eax
	mov es:p_vm_deb_sel,ax
	mov es:p_vm_deb_offs,eax
	mov es:p_pm_deb_sel,ax
	mov es:p_pm_deb_offs,eax
;
	mov ax,cs
	mov ds,ax
	mov si,OFFSET null_name
	mov di,OFFSET thread_name
	mov cx,30
first_move_name:
	lodsb
	or al,al
	jz first_move_pad
	stosb
	loop first_move_name
	jmp first_move_done
first_move_pad:
	mov al,' '
	rep stosb
first_move_done:
;
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,0
	push ds
	mov ax,system_data_sel
	mov ds,ax
	cli
	mov ax,ds:next_pid
	mov es:p_id,ax
	inc ax
	mov ds:next_pid,ax
	sti
	pop ds	
	ret
init_first_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_FIRST_TSS
;
;		DESCRIPTION:	Init first TSS
;
;		PARAMETERS:		DS		TSS
;						ES		Thread
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_first_tss	PROC near
	push es
	mov ax,ds
	mov es,ax
	xor di,di
	xor ax,ax
	mov cx,64h
	rep stosb
	xor ax,ax
	stosw
	mov ax,OFFSET tss_bitmap_space
	stosw
	pop es
;
; dr0 - dr7
;
	xor edx,edx
	mov ds:tss_dr0,edx
	mov ds:tss_dr1,edx
	mov ds:tss_dr2,edx
	mov ds:tss_dr3,edx
	mov ds:tss_dr7,edx
;
; 387 status
;
	mov ds:math_control,37Fh
	mov ds:math_status,0
	mov ds:math_tag,0FFFFh
	mov ds:math_eip,0
	mov ds:math_cs,0
	mov ds:math_data_offs,0
	mov ds:math_data_sel,0
;
; thread control
;
	mov ds:tss_thread,es
	mov ds:tss_error_code,dx
;
	mov bx,OFFSET tss_bitmap_space
	xor al,al
	mov cx,tss_size
fill_bm_mod_more:
	mov [bx],al
	inc bx
	cmp bx,cx
	jb fill_bm_mod_more		
	mov byte ptr [bx-1],0FFh
;
	mov ax,OFFSET init_first_process_callback
	mov ds:tss_eip,ax
	mov ds:tss_cs,cs
;
    push es
    mov eax,stack0_size
    AllocateSmallGlobalMem
    mov ax,es
    pop es    
	mov ds:tss_ss,ax
	mov ax,stack0_size
	mov ds:tss_esp,ax
;
	pushf
	pop ax
	and ax,NOT 7000h
	mov ds:tss_eflags,ax
	ret
init_first_tss	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_FIRST_PROCESS
;
;		DESCRIPTION:	Init first process (system process)
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_first_process

init_first_process	Proc near
	mov ax,0002h
	push ax
	popf	
;
	mov ax,virt_thread_sel
	mov es,ax
	call allocate_thread_block
	call init_first_thread
	call init_process_block
	mov ds,es:p_tss_data_sel
	call init_first_tss
	call create_enviroment
	mov ds:tss_es,fs
	ret
init_first_process	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_FIRST_PROCESS_CALLBACK
;
;		DESCRIPTION:	Startup code of system process
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_first_process_callback:
	call init_process_paging
;
    GetProcessor
    mov eax,cr3
    mov fs:ps_cr3,eax
    GetThread
    mov fs:ps_null,ax
;	
	call trap_init_tasking
	sti
	
null_loop:
	hlt
	jmp null_loop
	
code	ENDS

	END

