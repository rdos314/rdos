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
; USER.ASM
; USER (app level) gate handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME user

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE os.def
INCLUDE user.def
INCLUDE os.inc
INCLUDE user.inc

gate_entry	STRUC
gate_name_sel		DW ?
gate_name_offset	DD ?
virt_gate_nr		DW ?
gate_entry	ENDS

code	SEGMENT byte public 'CODE'

	.386p

	extrn allocate_fixed_system_mem:near
	extrn allocate_gdt:near

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_USERGATE
;
;		DESCRIPTION:	Init module
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_usergate

init_usergate	PROC near
	push ds
	push es
	pusha
;
	mov bx,usergate_sel
	mov eax,usergate_entries SHL 3
	push cs
	call allocate_fixed_system_mem
	xor al,al
	xor di,di
	mov cx,usergate_entries SHL 3
	rep stosb
	xor di,di
	mov cx,usergate_entries
init_usergate_loop:
	mov es:[di].gate_name_offset,OFFSET illegal_gate_name
	mov es:[di].gate_name_sel,cs
	mov es:[di].virt_gate_nr,-1
	add di,8
	loop init_usergate_loop
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET register_gate16
	mov di,OFFSET register_gate16_name
	xor cl,cl
	mov ax,register_usergate16_nr
	RegisterOsGate
	mov si,OFFSET register_gate32
	mov di,OFFSET register_gate32_name
	xor cl,cl
	mov ax,register_usergate32_nr
	RegisterOsGate
	mov si,OFFSET register_gate
	mov di,OFFSET register_gate_name
	xor cl,cl
	mov ax,register_usergate_nr
	RegisterOsGate
	popa
	pop es
	pop ds
	ret
init_usergate	ENDP

	public init_virt_pm_usergate

init_virt_pm_usergate	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET register_virt_pm_usergate
	mov di,OFFSET register_virt_pm_gate_name
	xor cl,cl
	mov ax,register_vugate_nr
	RegisterOsGate
	ret
init_virt_pm_usergate	ENDP

illegal_gate_name	DB 'Undefined Gate',0

illegal_gate	PROC far
	int 3
	ret
illegal_gate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_GATE16
;
;		DESCRIPTION:	Register a 16-bit gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						CL		NUMBER OF 16-BIT PARAMETERS
;						DS:SI	GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_gate16_name	DB 'Register User Gate16',0

register_gate16	PROC far
	push fs
	push ax
	push bx
;
	mov bx,usergate_sel
	mov fs,bx
	mov bx,ax
	shl bx,4
	add bx,user_begin_sel
	or bx,3
	CreateCallGateSelector16
;
	mov bx,ax
	shl bx,3
	mov fs:[bx].gate_name_sel,es
	movzx eax,di
	mov fs:[bx].gate_name_offset,eax
	pop bx
	pop ax
	pop fs
	ret
register_gate16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_GATE32
;
;		DESCRIPTION:	Register a 32-bit gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						CL		NUMBER OF 32-BIT PARAMETERS
;						DS:SI	GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_gate32_name	DB 'Register User Gate32',0

register_gate32	PROC far
	push fs
	push ax
	push bx
;
	mov bx,usergate_sel
	mov fs,bx
	mov bx,ax
	shl bx,4
	add bx,user_begin_sel + 8
	or bx,3
	CreateCallGateSelector32
;
	mov bx,ax
	shl bx,3
	mov fs:[bx].gate_name_sel,es
	movzx eax,di
	mov fs:[bx].gate_name_offset,eax
	pop bx
	pop ax
	pop fs
	ret
register_gate32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_GATE
;
;		DESCRIPTION:	Register a bimodal 16- & 32-bit gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						CL		NUMBER OF PARAMETERS (MUST BE 0)
;						DS:SI	GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_gate_name	DB 'Register User Gate',0

register_gate	PROC far
	push fs
	push ax
	push bx
;
	mov bx,usergate_sel
	mov fs,bx
	mov bx,ax
	shl bx,4
	add bx,user_begin_sel
	or bx,3
	CreateCallGateSelector32	
	add bx,8
	CreateCallGateSelector32
;
	mov bx,ax
	shl bx,3
	mov fs:[bx].gate_name_sel,es
	movzx eax,di
	mov fs:[bx].gate_name_offset,eax
	pop bx
	pop ax
	pop fs
	ret
register_gate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_VIRT_PM_USERGATE
;
;		DESCRIPTION:	Register a link between a V86 gate and a user gate
;
;		PARAMETERS:		AX		V86 gate #
;						BX		User gate #
;						DX		Segment transfer flag
;						DS:SI	Gate entry-point
;						DS:DI	Gate name
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_virt_pm_gate_name	DB 'Register Virt User Gate',0

register_virt_pm_usergate	PROC far
	push cx
;
	push ds
	push bx
	push ax
	push usergate_sel
	pop ds
	shl bx,3
	mov [bx].virt_gate_nr,ax
	shl bx,1
	add bx,user_begin_sel
	push gdt_sel
	pop ds
	and bx,0FFF8h
	mov cl,[bx+5]
	and cl,8
	shr cl,2
	add cl,2
	pop ax
	pop bx
	pop ds
	RegisterVirtGate
	pop cx
	ret
register_virt_pm_usergate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRANSLATE_VM_USERGATE
;
;		DESCRIPTION:	Translate a V86 gate?
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public translate_vm_usergate

translate_vm_usergate	PROC near
	push es
	push si
	sub ebx,2
	mov ax,usergate_sel
	mov es,ax
	mov si,[ebx+3]
	shl si,3
	mov ax,es:[si].virt_gate_nr
	mov byte ptr [ebx+2],0F4h
	mov [ebx+3],ax
	pop si
	pop es
	ret
translate_vm_usergate	ENDP

code	ENDS

	END

