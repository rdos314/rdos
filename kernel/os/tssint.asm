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

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE protseg.def


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
	
code	ENDS

	END
