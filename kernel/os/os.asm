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
; OS.ASM
; OS (kernel level) gate handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME os

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def

gate_entry	STRUC
gate_sel			DW ?
gate_offset			DW ?
gate_name_sel		DW ?
gate_name_offset	DW ?
gate_entry	ENDS

code	SEGMENT byte public 'CODE'

	.386p

	extrn get_selector_base_size:near
	extrn create_data_sel16:near
	extrn create_call_gate_sel16:near
	extrn create_int_gate_sel:near
	extrn create_tss_sel:near

	extrn allocate_fixed_system_mem:near

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_OSGATE
;
;		DESCRIPTION:	Init module
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_osgate

init_osgate	PROC near
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
;	mov si,OFFSET register_gate
;	mov bx,os_begin_sel
;	xor cl,cl
;	push cs
;	call create_call_gate_sel16
;
	mov bx,osgate_sel
	mov eax,osgate_entries SHL 3
	push cs
	call allocate_fixed_system_mem
	mov cx,osgate_entries SHL 3
	xor al,al
	xor di,di
	rep stosb
	xor di,di
	mov es:[di].gate_offset,OFFSET register_gate
	mov es:[di].gate_sel,cs
	mov es:[di].gate_name_offset,OFFSET register_gate_name
	mov es:[di].gate_name_sel,cs
	mov cx,osgate_entries-1
	mov di,8
init_osgate_loop:
	mov es:[di].gate_sel,0
	mov es:[di].gate_offset,0
	mov es:[di].gate_name_offset,OFFSET illegal_gate_name
	mov es:[di].gate_name_sel,cs
	add di,8
	loop init_osgate_loop
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET is_valid_osgate
	mov di,OFFSET is_valid_osgate_name
	mov ax,is_valid_osgate_nr
	xor cl,cl
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init_osgate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_GATE
;
;		DESCRIPTION:	Register an OS gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						CL		NUMBER OF 16-BIT PARAMETERS
;						DS:SI	GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

illegal_gate_name	DB 'Undefined Gate',0

illegal_gate	PROC far
	mov ax,1231h
	mov es,ax
	int 3
	ret
illegal_gate	ENDP

register_gate_name	DB 'Register Kernel Gate',0

register_gate	PROC far
	push ds
	push fs
	push gs
	push bx
;
	push ds
	mov bx,ax
	mov ax,osgate_sel
	mov ds,ax
	pop ax
	shl bx,3
	mov [bx].gate_sel,ax
	mov [bx].gate_offset,si
	mov [bx].gate_name_sel,es
	mov [bx].gate_name_offset,di
;
	pop bx
	pop gs
	pop fs
	pop ds
	ret
register_gate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IS_VALID_OSGATE
;
;		DESCRIPTION:	Check if a gate number is registered
;
;		PARAMETERS:		AX		GATE NUMBER
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_valid_osgate_name	DB 'Is Valid Kernel Gate',0

is_valid_osgate	PROC far
	push ds
	push ax
	push bx
;
	mov bx,ax
	mov ax,osgate_sel
	mov ds,ax
	shl bx,3
	mov ax,[bx].gate_sel
	or ax,ax
	clc
	jnz is_valid_gate_done
;
	stc

is_valid_gate_done:
	pop bx
	pop ax
	pop ds
	ret
is_valid_osgate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DO_OSGATE16
;
;		DESCRIPTION:	Translate a 16-bit gate
;
;		PARAMETERS:		DS:EBX		Fault address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public do_osgate16

do_osgate16	PROC near
	push es
	push ecx
	push edx
	push di
;
	mov di,ds:[ebx+3]
	shl di,3
	mov ax,osgate_sel
	mov es,ax
;
	push ebx
	mov bx,ds
	push cs
	call get_selector_base_size
	pop ebx
	add	ebx,edx
	mov ax,flat_sel
	mov ds,ax
;
	mov ax,[bp].vm_eflags
	mov [bp+12],ax
	mov ax,[bp].vm_cs
	mov [bp+16],ax
	mov ax,[bp].vm_eip
	add ax,5
	mov [bp+14],ax	
;
	mov ax,es:[di].gate_sel
	cmp ax,[bp+16]
	je do_direct
;
	mov ds:[ebx+3],ax
	mov [bp+10],ax
	mov ax,es:[di].gate_offset
	mov ds:[ebx+1],ax
	mov [bp+8],ax
	mov byte ptr ds:[ebx],9Ah
	jmp do_direct_do

do_direct:
	mov [bp+10],ax
	mov ax,es:[di].gate_offset
	mov [bp+8],ax
	sub ax,[bp+14]
	inc ax
	mov ds:[ebx+2],ax
	mov word ptr ds:[ebx],0E80Eh
	mov byte ptr ds:[ebx+4],90h

do_direct_do:
	pop di
	pop edx
	pop ecx
	pop es
;
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov sp,bp
	pop bp
	add sp,6
	iret
do_osgate16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DO_OSGATE32
;
;		DESCRIPTION:	Translate a 32-bit gate
;
;		PARAMETERS:		DS:EBX		Fault address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public do_osgate32

do_osgate32	PROC near
	push es
	push ecx
	push edx
	push di
;
	mov al,ds:[ebx+5]
	mov di,ds:[ebx+3]
	shl di,3
	mov ax,osgate_sel
	mov es,ax
;
	push ebx
	mov bx,ds
	push cs
	call get_selector_base_size
	pop ebx
	add	ebx,edx
	mov ax,flat_sel
	mov ds,ax
;
	mov ax,[bp].vm_eflags
	mov [bp+12],ax
	mov ax,[bp].vm_cs
	mov [bp+16],ax
	mov ax,[bp].vm_eip
	add ax,6
	mov [bp+14],ax	
;
	mov ax,es:[di].gate_sel
	mov ds:[ebx+4],ax
	mov [bp+10],ax
	mov ax,es:[di].gate_offset
	mov ds:[ebx+2],ax
	mov [bp+8],ax
	mov byte ptr ds:[ebx],66h
	mov byte ptr ds:[ebx+1],9Ah
;
	pop di
	pop edx
	pop ecx
	pop es
;
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov sp,bp
	pop bp
	add sp,6
	iret
do_osgate32	ENDP

code	ENDS

	END

