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
; SYSTEM.ASM
; System gate handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME system

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE os.def
INCLUDE os.inc
INCLUDE system.inc

code	SEGMENT byte public 'CODE'

	extrn create_data_selector:near

	.386p

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_SYSTEMGATE
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_systemgate

init_systemgate	PROC near
	pusha
	push ds
;
; create default_reflect_sel
;
	mov ax,gdt_sel
	mov ds,ax
	mov es,ax
	mov di,default_reflect_sel
	and di,0FFF8h
	mov bx,di
	mov si,kernel_code
	mov cx,8
	rep movsb
	mov edx,[bx+2]
	add dx,OFFSET pm_reflect_begin
	mov [bx+2],edx
	mov al,[bx+5]
	or al,60h
	mov [bx+5],al
	mov ax,OFFSET pm_reflect_end
	sub ax,dx
	dec ax
	mov [bx],ax
;
; init virt idt
;
	mov bx,virt_idt_sel
	mov eax,800h
	AllocateFixedSystemMem
	mov ds,bx
	mov cx,100h
	xor di,di
	mov eax,default_reflect_sel
	xor edx,edx
init_virt_idt:
	mov [di],edx
	mov [di+4],eax
	add di,8
	loop init_virt_idt
;
; init locked stack
;
	mov eax,100h
	AllocateThreadLinear
	mov ecx,eax
	mov bx,locked_stack_sel
	CreateDataSelector16
;
	pop ds
	popa
	ret
init_systemgate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			TRANSLATE_PM_SYSTEM
;
;		DESCRIPTION:	Translate protected mode gate
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pm_reflect_begin:
	int 3
pm_reflect_end:

	public translate_pm_system

translate_pm_system	PROC near
	mov ax,[ebx+3]
	add dword ptr [bp].vm_eip,5
	push ds
	push eax
	mov bx,ax
	mov ax,thread_tss_sel
	mov ds,ax
	mov ax,ds:tss_esp0
	push ax
	mov ax,sp
	mov ds:tss_esp0,ax
	mov ax,virt_idt_sel
	mov ds,ax
	shl bx,2
	push 0
	push locked_stack_sel
	push 0
	push 100h
	pushfd
	pop eax
	or ax,200h
	and ax,NOT 7000h
	push eax
	push dword ptr [bx+4]
	push dword ptr [bx]
	iretd
	ret
translate_pm_system	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			TRANSLATE_VM_SYSTEM
;
;		DESCRIPTION:	Translate V86 gate
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public translate_vm_system

translate_vm_system	PROC near
	int 3
	sub ebx,2
	mov ax,[ebx+3]
	ret
translate_vm_system	ENDP

code	ENDS

	END

