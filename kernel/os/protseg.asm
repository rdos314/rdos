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
; PROTSEG.ASM
; Selector management module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  protseg

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.386p

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE os.def
INCLUDE os.inc

code	SEGMENT byte use16 public 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetSelectorBaseSize
;
;		DESCRIPTION:	Get selector base + size
;
;		PARAMETERS:		BX			Selector
;
;		RETURNS:		EDX			Base
;						ECX			Limit
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_selector_base_size_name DB 'Get selector base & size',0

get_selector_base_size	PROC far
	push ds
	push ax
;
	test bx,4
	jz get_selector_gdt

get_selector_ldt:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	jmp get_selector_check

get_selector_gdt:
	mov ax,gdt_sel
	mov ds,ax

get_selector_check:
	and bx,0FFF8h
	jz get_selector_error
;
	mov al,[bx+5]
	test al,80h
	jz get_selector_error
;
	test al,10h
	jz get_selector_error
;
	xor ecx,ecx
	mov cl,[bx+6]
	and cl,0Fh
	shl ecx,16
	mov cx,[bx]
	test byte ptr [bx+6],80h
	jz get_selector_small
;
	shl ecx,12
	or cx,0FFFh

get_selector_small:
	inc ecx
	mov edx,[bx+2]
	rol edx,8
	mov dl,[bx+7]
	ror edx,8
	clc
	jmp get_selector_done

get_selector_error:
	stc

get_selector_done:
	pop ax
	pop ds
	ret
get_selector_base_size	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDataSelector16
;
;		DESCRIPTION:	Create 16-bit data selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						EDX			BASE
;						ECX			LIMIT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_data_sel16_name DB 'Create 16-bit Data Selector',0

	public create_data_sel16

create_data_sel16	PROC far
	push ds
	push ax
	push bx
	push ecx
;
	test bx,4
	jz create_data16_gdt

create_data16_ldt:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	jmp create_data16_dt_ok

create_data16_gdt:
	mov ax,gdt_sel
	mov ds,ax

create_data16_dt_ok:
	mov al,bl
	and bx,0FFF8h
	dec ecx
	cmp ecx,100000h
	jae create_data16_big
;
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,92h
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	mov [bx+6],cx
	jmp create_data16_done

create_data16_big:
	shr ecx,12
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,92h
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,80h
	mov [bx+6],cx

create_data16_done:
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
create_data_sel16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDataSelector32
;
;		DESCRIPTION:	Create 32-bit data selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						EDX			BASE
;						ECX			LIMIT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_data_sel32_name DB 'Create 32-bit Data Selector',0

create_data_sel32	PROC far
	push ds
	push ax
	push bx
	push ecx
;
	test bx,4
	jz create_data32_gdt

create_data32_ldt:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	jmp create_data32_dt_ok

create_data32_gdt:
	mov ax,gdt_sel
	mov ds,ax

create_data32_dt_ok:
	mov al,bl
	and bx,0FFF8h
	dec ecx
	cmp ecx,100000h
	jae create_data32_big
;
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,92h
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,40h
	mov [bx+6],cx
	jmp create_data32_done

create_data32_big:
	shr ecx,12
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,92h
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,0C0h
	mov [bx+6],cx

create_data32_done:
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
create_data_sel32	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateCodeSelector16
;
;		DESCRIPTION:	Create 16-bit code selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						EDX			BASE
;						ECX			LIMIT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_code_sel16_name DB 'Create 16-bit Code Selector',0

create_code_sel16	PROC far
	push ds
	push ax
	push bx
	push ecx
;
	test bx,4
	jz create_code16_gdt

create_code16_ldt:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	jmp create_code16_dt_ok

create_code16_gdt:
	mov ax,gdt_sel
	mov ds,ax

create_code16_dt_ok:
	mov al,bl
	and bx,0FFF8h
	dec ecx
	cmp ecx,100000h
	jae create_code16_big
;
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,9Ah
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	mov [bx+6],cx
	jmp create_code16_done

create_code16_big:
	shr ecx,12
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,9Ah
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,80h
	mov [bx+6],cx

create_code16_done:
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
create_code_sel16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateCodeSelector32
;
;		DESCRIPTION:	Create 32-bit code selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						EDX			BASE
;						ECX			LIMIT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_code_sel32_name DB 'Create 32-bit Code Selector',0

create_code_sel32	PROC far
	push ds
	push ax
	push bx
	push ecx
;
	test bx,4
	jz create_code32_gdt

create_code32_ldt:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	jmp create_code32_dt_ok

create_code32_gdt:
	mov ax,gdt_sel
	mov ds,ax

create_code32_dt_ok:
	mov al,bl
	and bx,0FFF8h
	dec ecx
	cmp ecx,100000h
	jae create_code32_big
;
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,9Ah
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,40h
	mov [bx+6],cx
	jmp create_code32_done

create_code32_big:
	shr ecx,12
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,9Ah
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,0C0h
	mov [bx+6],cx

create_code32_done:
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
create_code_sel32	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateConformSelector16
;
;		DESCRIPTION:	Create 16-bit conforming code selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						EDX			BASE
;						ECX			LIMIT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_conform_sel16_name DB 'Create 16-bit Conforming Selector',0

create_conform_sel16	PROC far
	push ds
	push ax
	push bx
	push ecx
;
	test bx,4
	jz create_conform16_gdt

create_conform16_ldt:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	jmp create_conform16_dt_ok

create_conform16_gdt:
	mov ax,gdt_sel
	mov ds,ax

create_conform16_dt_ok:
	mov al,bl
	and bx,0FFF8h
	dec ecx
	cmp ecx,100000h
	jae create_conform16_big
;
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,9Eh
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	mov [bx+6],cx
	jmp create_conform16_done

create_conform16_big:
	shr ecx,12
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,9Eh
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,80h
	mov [bx+6],cx

create_conform16_done:
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
create_conform_sel16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateConformSelector32
;
;		DESCRIPTION:	Create 32-bit conforming code selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						EDX			BASE
;						ECX			LIMIT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_conform_sel32_name DB 'Create 32-bit Conforming Selector',0

create_conform_sel32	PROC far
	push ds
	push ax
	push bx
	push ecx
;
	test bx,4
	jz create_conform32_gdt

create_conform32_ldt:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	jmp create_conform32_dt_ok

create_conform32_gdt:
	mov ax,gdt_sel
	mov ds,ax

create_conform32_dt_ok:
	mov al,bl
	and bx,0FFF8h
	dec ecx
	cmp ecx,100000h
	jae create_conform32_big
;
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,9Eh
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,40h
	mov [bx+6],cx
	jmp create_conform32_done

create_conform32_big:
	shr ecx,12
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,9Eh
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,0C0h
	mov [bx+6],cx

create_conform32_done:
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
create_conform_sel32	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateLdtSelector
;
;		DESCRIPTION:	Create LDT selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						EDX			BASE
;						CX			LIMIT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_ldt_sel_name DB 'Create LDT Selector',0

create_ldt_sel	PROC far
	push ds
	push ax
	push bx
	push cx
;
	test bx,4
	jnz create_ldt_done
;
	mov ax,gdt_sel
	mov ds,ax
;
	mov ah,bl
	and bx,0FFF8h
	dec cx
;
	mov [bx],cx
	mov [bx+2],edx
	shl ah,5
	or ah,82h
	xchg ah,[bx+5]
	xor al,al
	mov [bx+6],ax

create_ldt_done:
	pop cx
	pop bx
	pop ax
	pop ds
	ret
create_ldt_sel	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateTssSelector
;
;		DESCRIPTION:	Create TSS selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						EDX			BASE
;						ECX			LIMIT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_tss_sel_name DB 'Create TSS Selector',0

	public create_tss_sel

create_tss_sel	PROC far
	push ds
	push ax
	push bx
	push ecx
;
	test bx,4
	jnz create_tss_done
;
	mov ax,gdt_sel
	mov ds,ax
;
	mov al,bl
	and bx,0FFF8h
	dec ecx
	cmp ecx,100000h
	jae create_tss_big
;
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,89h
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	mov [bx+6],cx
	jmp create_tss_done

create_tss_big:
	shr ecx,12
	mov [bx],cx
	mov [bx+2],edx
	shl al,5
	or al,89h
	xchg al,[bx+5]
	shr ecx,16
	and cx,0Fh
	or ch,al
	or cl,80h
	mov [bx+6],cx

create_tss_done:
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
create_tss_sel	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateCallGateSelector16
;
;		DESCRIPTION:	Create 16-bit call gate selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						DS:SI		ENTRY POINT
;						CL			16-BIT WORDS TO MOVE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_call_gate_sel16_name DB 'Create 16-bit Call Gate Selector',0

	public create_call_gate_sel16

create_call_gate_sel16	PROC far
	push es
	push ax
	push bx
;
	test bx,4
	jz create_call_gate16_gdt

create_call_gate16_ldt:
	mov ax,thread_sel
	mov es,ax
	mov es,es:p_ldt_sel
	jmp create_call_gate16_dt_ok

create_call_gate16_gdt:
	mov ax,gdt_sel
	mov es,ax

create_call_gate16_dt_ok:
	mov ah,bl
	and bx,0FFF8h
	mov es:[bx],si
	mov es:[bx+2],ds
	mov al,cl
	and al,0Fh
	shl ah,5
	or ah,84h
	mov es:[bx+4],ax
	xor ax,ax
	mov es:[bx+6],ax	
;
	pop bx
	pop ax
	pop es
	ret
create_call_gate_sel16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateCallGateSelector32
;
;		DESCRIPTION:	Create 32-bit call gate selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						DS:ESI		ENTRY POINT
;						CL			32-BIT WORDS TO MOVE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_call_gate_sel32_name DB 'Create 32-bit Call Gate Selector',0

create_call_gate_sel32	PROC far
	push es
	push ax
	push bx
;
	test bx,4
	jz create_call_gate32_gdt

create_call_gate32_ldt:
	mov ax,thread_sel
	mov es,ax
	mov es,es:p_ldt_sel
	jmp create_call_gate32_dt_ok

create_call_gate32_gdt:
	mov ax,gdt_sel
	mov es,ax

create_call_gate32_dt_ok:
	mov ah,bl
	and bx,0FFF8h
	mov al,cl
	and al,0Fh
	shl ah,5
	or ah,8Ch
	mov es:[bx+4],ax
	mov es:[bx],esi
	mov ax,ds
	xchg ax,es:[bx+2]
	mov es:[bx+6],ax
;
	pop bx
	pop ax
	pop es
	ret
create_call_gate_sel32	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateTaskGateSelector
;
;		DESCRIPTION:	Create task gate selector
;
;		PARAMETERS:		BX			DESCRIPTOR
;						DX			TSS SELECTOR
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_task_gate_sel_name DB 'Create Task Gate Selector',0

create_task_gate_sel	PROC far
	push ds
	push ax
	push bx
;
	test bx,4
	jz create_task_gate_gdt

create_task_gate_ldt:
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	jmp create_task_gate_dt_ok

create_task_gate_gdt:
	mov ax,gdt_sel
	mov ds,ax

create_task_gate_dt_ok:
	mov ah,bl
	and bx,0FFF8h
	mov [bx+2],dx
	xor al,al
	shl ah,5
	or ah,85h
	mov [bx+4],ax
	xor ax,ax
	mov [bx+6],ax	
	mov [bx],ax
;
	pop bx
	pop ax
	pop ds
	ret
create_task_gate_sel	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateIntGate
;
;		DESCRIPTION:	Create int gate selector
;
;		PARAMETERS:		AL			INT #
;						BL			DPL
;						DS:ESI		ENTRY POINT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_int_gate_sel_name DB 'Create Interrupt Gate Selector',0

	public create_int_gate_sel

create_int_gate_sel	PROC far
	push es
	push ax
	push bx
	push dx
;
	mov dx,idt_sel
	mov es,dx
;
	mov ah,bl
	movzx bx,al
	shl bx,3
	xor al,al
	shl ah,5
	or ah,8Eh
	mov es:[bx+4],ax
	mov es:[bx],esi
	mov ax,ds
	xchg ax,es:[bx+2]
	mov es:[bx+6],ax
;
	pop dx
	pop bx
	pop ax
	pop es
	ret
create_int_gate_sel	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateTrapGate
;
;		DESCRIPTION:	Create trap gate selector
;
;		PARAMETERS:		AL			INTERRUPT #
;						BL			DPL
;						DS:ESI		ENTRY POINT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_trap_gate_sel_name DB 'Create Trap Gate Selector',0

create_trap_gate_sel	PROC far
	push es
	push ax
	push bx
	push dx
;
	mov dx,idt_sel
	mov es,dx
;
	mov ah,bl
	movzx bx,al
	shl bx,3
	xor al,al
	shl ah,5
	or ah,8Fh
	mov es:[bx+4],ax
	mov es:[bx],esi
	mov ax,ds
	xchg ax,es:[bx+2]
	mov es:[bx+6],ax
;
	pop dx
	pop bx
	pop ax
	pop es
	ret
create_trap_gate_sel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_protseg
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_protseg

init_protseg	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET get_selector_base_size
	mov di,OFFSET get_selector_base_size_name
	xor cl,cl
	mov ax,get_selector_base_size_nr
	RegisterOsGate
;
	mov si,OFFSET create_data_sel16
	mov di,OFFSET create_data_sel16_name
	xor cl,cl
	mov ax,create_data_sel16_nr
	RegisterOsGate
;
	mov si,OFFSET create_data_sel32
	mov di,OFFSET create_data_sel32_name
	xor cl,cl
	mov ax,create_data_sel32_nr
	RegisterOsGate
;
	mov si,OFFSET create_code_sel16
	mov di,OFFSET create_code_sel16_name
	xor cl,cl
	mov ax,create_code_sel16_nr
	RegisterOsGate
;
	mov si,OFFSET create_code_sel32
	mov di,OFFSET create_code_sel32_name
	xor cl,cl
	mov ax,create_code_sel32_nr
	RegisterOsGate
;
	mov si,OFFSET create_conform_sel16
	mov di,OFFSET create_conform_sel16_name
	xor cl,cl
	mov ax,create_conform_sel16_nr
	RegisterOsGate
;
	mov si,OFFSET create_conform_sel32
	mov di,OFFSET create_conform_sel32_name
	xor cl,cl
	mov ax,create_conform_sel32_nr
	RegisterOsGate
;
	mov si,OFFSET create_ldt_sel
	mov di,OFFSET create_ldt_sel_name
	xor cl,cl
	mov ax,create_ldt_sel_nr
	RegisterOsGate
;
	mov si,OFFSET create_tss_sel
	mov di,OFFSET create_tss_sel_name
	xor cl,cl
	mov ax,create_tss_sel_nr
	RegisterOsGate
;
	mov si,OFFSET create_call_gate_sel16
	mov di,OFFSET create_call_gate_sel16_name
	xor cl,cl
	mov ax,create_call_gate_sel16_nr
	RegisterOsGate
;
	mov si,OFFSET create_call_gate_sel32
	mov di,OFFSET create_call_gate_sel32_name
	xor cl,cl
	mov ax,create_call_gate_sel32_nr
	RegisterOsGate
;
	mov si,OFFSET create_task_gate_sel
	mov di,OFFSET create_task_gate_sel_name
	xor cl,cl
	mov ax,create_task_gate_sel_nr
	RegisterOsGate
;
	mov si,OFFSET create_int_gate_sel
	mov di,OFFSET create_int_gate_sel_name
	xor cl,cl
	mov ax,create_int_gate_sel_nr
	RegisterOsGate
;
	mov si,OFFSET create_trap_gate_sel
	mov di,OFFSET create_trap_gate_sel_name
	xor cl,cl
	mov ax,create_trap_gate_sel_nr
	RegisterOsGate
;
	ret
init_protseg	ENDP

code	ENDS

	END
