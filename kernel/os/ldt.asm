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
; LDT.ASM
; LDT handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ldt

GateSize = 16

INCLUDE system.def
INCLUDE int.def
INCLUDE protseg.def
INCLUDE os.def
INCLUDE os.inc
INCLUDE user.def
INCLUDE user.inc

ldt_start	EQU 80h

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_LDT
;
;		DESCRIPTION:	Init module
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_ldt

init_ldt	PROC near
	pusha
	push ds
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET allocate_ldt
	mov di,OFFSET allocate_name
	xor cl,cl
	mov ax,allocate_ldt_nr
	RegisterOsGate
	mov si,OFFSET free_ldt
	mov di,OFFSET free_name
	xor cl,cl
	mov ax,free_ldt_nr
	RegisterOsGate
	mov si,OFFSET allocate_multiple_ldt
	mov di,OFFSET allocate_multiple_name
	xor cl,cl
	mov ax,allocate_multiple_ldt_nr
	RegisterOsGate
	pop ds
	popa
	ret
init_ldt	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_LDT
;
;		DESCRIPTION:	Create LDT for process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public create_ldt

create_ldt	PROC near
	push ds
	push es
	pusha
;
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,10000h
	AllocateBigLinear
	AllocateGdt
	mov cx,1000h
	CreateLdtSelector
;
	mov ax,thread_tss_sel
	mov es,ax
	mov es:tss_ldt,bx
	mov ds:app_ldt_sel,bx
	lldt bx
	AllocateGdt
	CreateDataSelector16
	mov ax,thread_sel
	mov es,ax
	mov es:p_ldt_sel,bx
	mov ds:app_ldt_data_sel,bx
	mov es,bx
	xor di,di
	mov dx,8
	mov cx,200h
init_ldt_loop:
	mov ax,dx
	stosw
	xor ax,ax
	stosw
	stosw
	stosw
	add dx,8
	loop init_ldt_loop
	sub di,8
	stosw
;
	InitSection ds:app_ldt_section
	mov ds:app_ldt_free,ldt_start
;	
	popa
	pop es
	pop ds
	ret
create_ldt	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DESTROY_LDT
;
;		DESCRIPTION:	Destroy LDT
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public destroy_ldt

destroy_ldt	PROC near
	push ds
	push es
	push ax
	push bx
;
	mov ax,thread_tss_sel
	mov ds,ax
	xor bx,bx
	xchg bx,ds:tss_ldt
	xor ax,ax
	lldt ax
	FreeGdt
;
	mov ax,thread_sel
	mov ds,ax
	xor ax,ax
	xchg ax,ds:p_ldt_sel
	mov es,ax
	FreeMem
	pop bx
	pop ax
	pop es
	pop ds
	ret
destroy_ldt	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_LDT
;
;		DESCRIPTION:	Allocate LDT descriptor entry
;
;		RETURNS:		BX		Selector
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_name	DB 'Allocate Ldt',0

allocate_ldt	PROC far
	push es
	push di
	mov bx,thread_app_sel
	mov ds,bx
	push bx
	mov ds,bx
	mov es,bx
	EnterSection ds:app_ldt_section
	mov ds,ds:app_ldt_data_sel
allocate_ldt_again:
	mov bx,es:app_ldt_free
	or bx,bx
	jnz allocate_ldt_ok
	push ds
	push ax
	push cx
	push dx
	push es
	mov ax,ds
	mov es,ax
	mov ax,thread_tss_sel
	mov ds,ax
	mov bx,ds:tss_ldt
	mov ax,gdt_sel
	mov ds,ax
	mov ax,[bx]
	add ax,1000h
	mov [bx],ax
	mov bx,es
	mov [bx],ax
	mov es,bx
	sub ax,0FFFh
	mov di,ax
	mov dx,ax
	add dx,8
	mov cx,200h
extend_ldt_loop:
	mov ax,dx
	stosw
	xor ax,ax
	stosw
	stosw
	stosw
	add dx,8
	loop extend_ldt_loop
	sub di,8
	stosw
	sub dx,1008h
	pop es
	mov es:app_ldt_free,dx
	sldt ax
	lldt ax
	pop dx
	pop cx
	pop ax
	pop ds
	jmp allocate_ldt_again
allocate_ldt_ok:
	mov di,[bx]
	cmp di,0FFFFh
	jne al1
	int 3
al1:
	mov es:app_ldt_free,di
	mov di,ds
	pop ds
	LeaveSection ds:app_ldt_section
	mov ds,di
;
	pop di
	pop es
	ret
allocate_ldt	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_MULTIPLE_LDT
;
;		DESCRIPTION:	Allocate multiple continous LDT descriptors
;
;		PARAMETERS:		CX		Number of descriptor
;						
;		RETURNS:		BX		Base selector
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_multiple_name	DB 'Allocate Multiple Ldt',0

allocate_mldt_extend	PROC near
	push ax
	push cx
	push dx
	push es
	mov ax,ds
	mov es,ax
	mov ax,thread_tss_sel
	mov ds,ax
	mov bx,ds:tss_ldt
	mov ax,gdt_sel
	mov ds,ax
	mov ax,[bx]
	add ax,1000h
	mov [bx],ax
	mov bx,es
	mov [bx],ax
	mov es,bx
	sub ax,0FFFh
	mov di,ax
	mov dx,ax
	add dx,8
	mov cx,200h
extend_mldt_loop:
	mov ax,dx
	stosw
	xor ax,ax
	stosw
	stosw
	stosw
	add dx,8
	loop extend_mldt_loop
	sub di,8
	stosw
	pop es
	sub dx,1008h
	mov es:app_ldt_free,dx
	pop dx
	add dx,1000h
	pop cx
	pop ax
	ret
allocate_mldt_extend	ENDP

allocate_multiple_ldt	PROC far
	push ds
	push es
	push ax
	push dx
	push si
	push di
	mov ax,thread_tss_sel
	mov ds,ax
	mov bx,ds:tss_ldt
	mov ax,gdt_sel
	mov ds,ax
	mov dx,[bx]
	inc dx
	mov bx,thread_app_sel
	mov ds,bx
	mov es,bx
	push ds
	EnterSection ds:app_ldt_section
	mov ds,ds:app_ldt_data_sel
	mov bx,ldt_start
allocate_mldt_retry_loop:
	push cx
allocate_mldt_loop:
	mov al,[bx+5]
	add bx,8
	or al,al
	jz allocate_mldt_free
	pop cx
	jmp allocate_mldt_retry_loop
allocate_mldt_free:
	cmp bx,dx
	jne allocate_mldt_next
	call allocate_mldt_extend
allocate_mldt_next:
	loop allocate_mldt_loop
	pop cx
	push cx
	mov dx,cx
	shl dx,3
	sub bx,dx
	mov ax,es:app_ldt_free
allocate_mldt_head_first_loop:
	sub ax,bx
	jc allocate_mldt_head_unalloc
	cmp ax,dx
	jnc allocate_mldt_head_unalloc
	add ax,bx
	mov si,ax
	mov ax,[si]
	mov es:app_ldt_free,ax
	loop allocate_mldt_head_first_loop
	jmp allocate_mldt_end
allocate_mldt_head_unalloc:
	add ax,bx
	mov si,ax
	mov di,ax
allocate_mldt_selector_head_loop:
	mov ax,[si]
	sub ax,bx
	jc allocate_mldt_save_head
	cmp ax,dx
	jnc allocate_mldt_save_head
	mov si,[si]
	loop allocate_mldt_selector_head_loop
allocate_mldt_save_head:
	mov si,[si]
	mov [di],si
	mov di,si
	or cx,cx
	jnz allocate_mldt_selector_head_loop
allocate_mldt_end:
	pop cx
	pop ds
	LeaveSection ds:app_ldt_section
;
	pop di
	pop si
	pop dx
	pop ax
	pop es
	pop ds
	ret
allocate_multiple_ldt	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_LDT
;
;		DESCRIPTION:	Free a LDT descriptor
;
;		PARAMETERS:		BX		Selector
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_name	DB 'Free Ldt',0

free_ldt	PROC far
	push ds
	push es
	push si
	mov si,thread_app_sel
	mov ds,si
	push ds
	EnterSection ds:app_ldt_section
	mov si,ds
	mov es,si
	mov ds,ds:app_ldt_data_sel
	mov byte ptr [bx+5],0
	mov si,es:app_ldt_free
	mov [bx],si
	mov es:app_ldt_free,bx
	pop ds
	LeaveSection ds:app_ldt_section
	pop si
	pop es
	pop ds
	ret
free_ldt	ENDP

code	ENDS

END
