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
; TSSINT.ASM
; TSS gate handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  tssint

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE user.def
INCLUDE user.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE os.def
INCLUDE os.inc
INCLUDE protseg.def

vm_gs		EQU 38
vm_fs		EQU 34
vm_ds		EQU 30
vm_es		EQU 26
vm_ss		EQU 22
vm_esp		EQU 18
vm_eflags	EQU 14
vm_cs		EQU 10
vm_eip		EQU 6
vm_err		EQU 2
vm_bp		EQU 0
vm_eax		EQU -4
vm_ebx		EQU -8
pm_ds		EQU -10


.386p


pm_ss		EQU 22
pm_esp		EQU 18
pm_eflags	EQU 14
pm_cs		EQU 10
pm_eip		EQU 6
pm_err		EQU 2

	extrn get_thread:near

	extrn prot_exception:near

	extrn boot_ram:near

code	SEGMENT byte use16 public 'CODE'

	assume cs:code


	public init_task_tasks

init_task_tasks	Proc near
	mov ax,idt_sel
	mov fs,ax
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov al,20
	mov bx,8 * 8
	mov si,OFFSET double_fault
	mov di,OFFSET double_fault_name
	CreateTask
;
	mov al,20
	mov bx,10 * 8
	mov si,OFFSET tss_fault
	mov di,OFFSET tss_fault_name
	CreateTask
;
	mov al,20
	mov bx,12 * 8
	mov si,OFFSET stack_fault
	mov di,OFFSET stack_fault_name
	CreateTask
;
	mov al,20
	mov bx,45h * 8
	mov si,OFFSET prot_debug
	mov di,OFFSET prot_debug_name
	CreateTask
;
	mov al,20
	mov bx,46h * 8
	mov si,OFFSET virt_debug
	mov di,OFFSET virt_debug_name
	CreateTask
;
	mov al,20
	mov bx,47h * 8
	mov si,OFFSET terminate_thread
	mov di,OFFSET terminate_thread_name
	CreateTask
;
	mov al,20
	mov bx,48h * 8
	mov si,OFFSET terminate_process
	mov di,OFFSET terminate_process_name
	CreateTask
;
	ret
init_task_tasks	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DOUBLE_FAULT
;
;		DESCRIPTION:	Double fault handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

double_fault_name	DB 'Double Fault',0

double_fault:
	mov ax,system_data_sel
	mov ds,ax
	mov di,OFFSET debug_list	
	InitTask
double_fault_loop:
	push es
	mov es,ax
	mov es:p_error_code,8
	mov es,es:p_tss_data_sel
	mov es:tss_error_code,dx
	pop es
	WaitSleepTask
	jmp double_fault_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TSS_FAULT
;
;		DESCRIPTION:	Invalid TSS handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tss_fault_name	DB 'Tss Fault',0

tss_fault:
	mov ax,system_data_sel
	mov ds,ax
	mov di,OFFSET debug_list	
	InitTask
tss_fault_loop:
	push es
	mov es,ax
	mov es:p_error_code,10
	mov es,es:p_tss_data_sel
	mov es:tss_error_code,dx
	pop es
	WaitSleepTask
	jmp tss_fault_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			STACK_FAULT
;
;		DESCRIPTION:	Stack fault handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stack_fault_name	DB 'Stack Fault',0

stack_fault_user:
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4
	iretd

stack_fault:
	mov eax,200h
	AllocateSmallGlobalMem
	mov dx,es
	mov ax,ss
	mov ss,dx
	mov sp,200h
	mov es,ax
	FreeMem
	mov ax,system_data_sel
	mov ds,ax
	mov di,OFFSET debug_list	
	InitTask
stack_fault_loop:
	push es
	push ax
	mov es,ax
	mov es:p_error_code,12
	mov es,es:p_tss_data_sel
	mov cx,es:tss_cs
	and cl,3
	cmp cl,3
	jne stack_fault_kernel
	cli
	ChangeEnviroment
	mov ds,es:tss_ess0
	mov bx,es:tss_esp0
	sub bx,26
	xor eax,eax
	mov ax,es:tss_ss
	mov [bx].vm_ss,eax
	mov eax,dword ptr es:tss_esp
	mov [bx].vm_esp,eax
	mov eax,dword ptr es:tss_eflags
	mov [bx].vm_eflags,eax
	and ax,NOT 100h
	mov es:tss_eflags,ax
	mov ax,es:tss_cs
	mov [bx].vm_cs,eax
	mov eax,dword ptr es:tss_eip
	mov [bx].vm_eip,eax
	mov [bx].vm_err,edx
	mov ax,es:tss_ebp
	mov [bx].vm_bp,ax
	mov eax,dword ptr es:tss_eax
	mov [bx].vm_eax,eax
	mov eax,dword ptr es:tss_ebx
	mov [bx].vm_ebx,eax
	mov ax,es:tss_ds
	mov [bx].pm_ds,ax
	mov word ptr [bx].pm_call,OFFSET stack_fault_user
	mov es:tss_cs,cs
	mov es:tss_eip,OFFSET prot_exception
	mov es:tss_ss,ds
	mov es:tss_ebp,bx
	sub bx,12
	mov es:tss_esp,bx
	mov es:tss_eax,12
	GetThread
	ChangeEnviroment
	sti
	pop ax
	pop es
	WaitRunTask
	jmp stack_fault_loop
stack_fault_kernel:
	mov es:tss_error_code,dx
	pop ax
	pop es
	WaitSleepTask
	jmp stack_fault_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PROT_DEBUG
;
;		DESCRIPTION:	Protected mode debug handler
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

prot_debug_name	DB 'Prot Debug',0

prot_debug:
	mov eax,200h
	AllocateSmallGlobalMem
	mov dx,es
	mov ax,ss
	mov ss,dx
	mov sp,200h
	mov es,ax
	FreeMem
	mov ax,system_data_sel
	mov ds,ax
	mov di,OFFSET debug_list	
	InitTask
prot_debug_loop:
	push ds
	push es
	push ax
	cli
	ChangeEnviroment
	mov es,ax
	mov es,es:p_tss_data_sel
	mov ax,es:tss_ss
	mov ds,ax
	mov bx,es:tss_ebp
	mov ax,[bx].pm_cs
	and ax,3
	mov dx,es:tss_cs
	and dx,3
	cmp ax,dx
	je pm_same_level
	mov ax,[bx].pm_ss
	mov es:tss_ss,ax
	mov ax,[bx].pm_esp
	mov es:tss_esp,ax
	mov ax,[bx+2].pm_esp
	mov es:tss_esp+2,ax
	jmp pm_level_j
pm_same_level:
	add es:tss_esp,30
pm_level_j:
	mov ax,[bx].pm_eflags
	mov es:tss_eflags,ax
	mov ax,[bx].pm_eflags+2
	mov es:tss_eflags+2,ax
	mov ax,[bx].pm_cs
	mov es:tss_cs,ax
	mov ax,[bx].pm_eip
	mov es:tss_eip,ax
	mov ax,[bx+2].pm_eip
	mov es:tss_eip+2,ax
	mov ax,[bx]
	mov es:tss_ebp,ax
	mov dx,es:tss_eax
	mov ax,[bx].vm_eax
	mov es:tss_eax,ax
	mov ax,[bx+2].vm_eax
	mov es:tss_eax+2,ax
	mov ax,[bx].vm_ebx
	mov es:tss_ebx,ax
	mov ax,[bx+2].vm_ebx
	mov es:tss_ebx+2,ax
	mov ax,[bx].pm_ds
	mov es:tss_ds,ax
	GetThread
	ChangeEnviroment
	sti
	pop ax
	mov es,ax
	mov es:p_error_code,dx
	pop es
	pop ds
	WaitSleepTask
	jmp prot_debug_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			VIRT_DEBUG
;
;		DESCRIPTION:	V86 mode debug handler
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

virt_debug_name	DB 'Virt Debug',0

virt_debug:
	mov eax,200h
	AllocateSmallGlobalMem
	mov dx,es
	mov ax,ss
	mov ss,dx
	mov sp,200h
	mov es,ax
	FreeMem
	mov ax,system_data_sel
	mov ds,ax
	mov di,OFFSET debug_list	
	InitTask
virt_debug_loop:
	push ds
	push es
	push ax
	cli
	ChangeEnviroment
	mov es,ax
	mov es,es:p_tss_data_sel
	mov ax,es:tss_ss
	mov ds,ax
	mov bx,es:tss_ebp
	mov ax,[bx].vm_gs
	mov es:tss_gs,ax
	mov ax,[bx].vm_fs
	mov es:tss_fs,ax
	mov ax,[bx].vm_ds
	mov es:tss_ds,ax
	mov ax,[bx].vm_es
	mov es:tss_es,ax
	mov ax,[bx].vm_ss
	mov es:tss_ss,ax
	mov ax,[bx].vm_esp
	mov es:tss_esp,ax
	mov ax,[bx].vm_eflags
	mov es:tss_eflags,ax
	mov ax,[bx].vm_eflags+2
	mov es:tss_eflags+2,ax
	mov ax,[bx].vm_cs
	mov es:tss_cs,ax
	mov ax,[bx].vm_eip
	mov es:tss_eip,ax
	mov ax,[bx]
	mov es:tss_ebp,ax
	mov dx,es:tss_eax
	mov ax,[bx].vm_eax
	mov es:tss_eax,ax
	mov ax,[bx+2].vm_eax
	mov es:tss_eax+2,ax
	mov ax,[bx].vm_ebx
	mov es:tss_ebx,ax
	mov ax,[bx+2].vm_ebx
	mov es:tss_ebx+2,ax
	GetThread
	ChangeEnviroment
	sti
	pop ax
	mov es,ax
	mov es:p_error_code,dx
	pop es
	pop ds
	WaitSleepTask
	jmp virt_debug_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TERMINATE THREAD
;
;		DESCRIPTION:	Terminate thread handler
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_thread_name	DB 'Terminate Thread',0

terminate_thread:
	InitTask
terminate_thread_loop:
	mov es,ax
	mov bx,es:p_tss_data_sel
	FreeGdt
	mov bx,es:p_tss_sel
	FreeGdt
	FreeMem
	InitTask
	jmp terminate_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TERMINATE PROCESS
;
;		DESCRIPTION:	Terminate process handler
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_process_name	DB 'Terminate Process',0

terminate_process:
	InitTask
terminate_process_loop:
	mov es,ax
	mov bx,es:p_tss_data_sel
	FreeGdt
	mov bx,es:p_tss_sel
	FreeGdt
	FreeMem
	InitTask
	jmp terminate_process_loop
	
code	ENDS

	END
