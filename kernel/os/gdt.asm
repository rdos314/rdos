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
; GDT.ASM
; GDT handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME gdt

GateSize = 16

INCLUDE protseg.def
INCLUDE system.def
INCLUDE user.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE os.inc


	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn create_data_sel16:near

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CREATE_GDT
;
;		DESCRIPTION:	Create GDT descriptor
;
;		PARAMETERS:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public create_gdt

create_gdt	PROC near
	push ds
	push es
	pusha
;
	mov bx,gdt_sel
	mov ds,bx
	mov bx,temp_sel
	mov ecx,10000h
	mov edx,gdt_linear
	push cs
	call create_data_sel16
	mov es,bx
;
	xor si,si
	xor di,di
	mov cx,1000h
	rep movsb
	xor al,al
	mov cx,2000h
	rep stosb
	mov ds,bx
	mov word ptr [bx],2FFFh ; initial size = 3000, fixed = 2000
	mov si,bx
	mov di,gdt_sel
	movsd
	movsd
;
	mov dword ptr [bx+4],gdt_linear
	mov ax,[bx]
	mov [bx+2],ax
	db 66h
	lgdt [bx+2]
;
	mov ax,gdt_sel
	mov ds,ax
	mov cx,1000h SHR 3
	mov si,2000h
	xor bx,bx

init_free_dt_loop:
	mov [si],bx
	mov bx,si
	add si,8
	loop init_free_dt_loop
;
	mov si,bx
	xor bx,bx
	mov [bx],si
;
	mov ax,system_data_sel
	mov ds,ax
	InitSection ds:gdt_section
;
	popa
	pop es
	pop ds
	ret
create_gdt	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_GDT
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;						
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_gdt

init_gdt	PROC near
	pusha
	push ds
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET allocate_gdt
	mov di,OFFSET allocate_name
	xor cl,cl
	mov ax,allocate_gdt_nr
	RegisterOsGate
	mov si,OFFSET free_gdt
	mov di,OFFSET free_name
	xor cl,cl
	mov ax,free_gdt_nr
	RegisterOsGate
;
	xor edx,edx
	mov bx,__0000
	mov ecx,1000h
	CreateDataSelector16
;
	mov edx,400h
	mov bx,__0040
	mov ecx,300h
	CreateDataSelector16
;
	mov edx,0A0000h
	mov bx,__A000
	mov ecx,10000h
	CreateDataSelector16
;
	mov edx,0B0000h
	mov bx,__B000
	mov ecx,8000h
	CreateDataSelector16
;
	mov edx,0B8000h
	mov bx,__B800
	mov ecx,8000h
	CreateDataSelector16
;
	mov edx,0C0000h
	mov bx,__C000
	mov ecx,10000h
	CreateDataSelector16
;
	mov edx,0F0000h
	mov bx,__F000
	mov ecx,10000h
	CreateDataSelector16
;
	pop ds
	popa
	ret
init_gdt	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_GDT
;
;		DESCRIPTION:	Allocate GDT selector
;
;		RETURNS:		BX		GDT entry / selector
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_name	DB 'Allocate Gdt',0

	public allocate_gdt

allocate_gdt	PROC far
	push ds
	push es
	push si
	push di
;
	mov si,system_data_sel
	mov ds,si
	EnterSection ds:gdt_section
;
	mov si,gdt_sel
	mov es,si
	xor di,di
	mov si,es:[di]
	or si,si
	jnz alloc_gdt_room
;
	push ax
	push cx
	mov si,gdt_sel
	mov cx,es:[si]
	inc cx
	or cx,cx
	jnz alloc_gdt_not_full
;
	int 3

alloc_gdt_not_full:
	add word ptr es:[si],1000h
;
	xor bx,bx
	mov dword ptr es:[bx+4],gdt_linear
	mov ax,es:[si]
	mov es:[bx+2],ax
	db 66h
	lgdt es:[bx+2]
	mov bx,gdt_sel
	mov es,bx
;
	mov di,es:[bx]
	and di,0F000h
	mov cx,1000h SHR 3
	xor bx,bx

extend_gdt_loop:
	mov ax,bx
	mov bx,di
	stosw
	xor ax,ax
	stosw
	stosw
	stosw
	loop extend_gdt_loop
;
	mov si,bx
	xor bx,bx
	mov es:[bx],si
	pop cx
	pop ax
	xor di,di

alloc_gdt_room:
	mov bx,si
	mov si,es:[si]
	mov es:[di],si
	LeaveSection ds:gdt_section
;
	pop di
	pop si
	pop es
	pop ds
	ret
allocate_gdt	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_GDT
;
;		DESCRIPTION:	Free GDT selector
;
;		PARAMETERS:		BX		GDT entry / selector
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_name	DB 'Free Gdt',0

free_gdt	PROC far
	push ds
	push es
	push si
;
	mov si,system_data_sel
	mov ds,si
	EnterSection ds:gdt_section
	mov si,gdt_sel
	mov es,si
	mov byte ptr es:[bx+5],0
	xor si,si
	mov si,es:[si]
	mov es:[bx],si
	xor si,si
	mov es:[si],bx
	LeaveSection ds:gdt_section
;
	pop si
	pop es
	pop ds
	ret
free_gdt	ENDP

code	ENDS

.186

END
