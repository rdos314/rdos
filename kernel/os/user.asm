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

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def

gate_entry	STRUC
gate_name_sel			DW ?
gate_name_offset		DW ?
gate_entry_offset16		DW ?
gate_entry_sel16		DW ?
gate_entry_offset32		DW ?
gate_entry_sel32		DW ?
gate_entry_offset_v86	DW ?	
gate_entry_sel_v86		DW ?
gate_sel16				DW ?
gate_sel32				DW ?
gate_transfer			DW ?
gate_entry	ENDS

code	SEGMENT byte public 'CODE'

	.386p

	extrn get_selector_base_size:near
	extrn create_data_sel16:near
	extrn create_call_gate_sel16:near
	extrn create_int_gate_sel:near
	extrn create_tss_sel:near

	extrn allocate_fixed_system_mem:near
	extrn allocate_gdt:near

	extrn translate_segment:near
	extrn translate_selector:near

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
	mov eax,usergate_entries SHL 5
	push cs
	call allocate_fixed_system_mem
	xor al,al
	xor di,di
	mov cx,usergate_entries SHL 5
	rep stosb
	xor di,di
	mov cx,usergate_entries
init_usergate_loop:
	mov es:[di].gate_name_offset,OFFSET illegal_gate_name
	mov es:[di].gate_name_sel,cs
	add di,32
	loop init_usergate_loop
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET register_usergate
	mov di,OFFSET register_usergate_name
	xor cl,cl
	mov ax,register_usergate_nr
	RegisterOsGate
;
	mov si,OFFSET register_bimodal_usergate
	mov di,OFFSET register_bimodal_usergate_name
	xor cl,cl
	mov ax,register_bimodal_usergate_nr
	RegisterOsGate
;
	mov si,OFFSET register_usergate16
	mov di,OFFSET register_usergate16_name
	xor cl,cl
	mov ax,register_usergate16_nr
	RegisterOsGate
;
	mov si,OFFSET register_usergate32
	mov di,OFFSET register_usergate32_name
	xor cl,cl
	mov ax,register_usergate32_nr
	RegisterOsGate
;
	mov si,OFFSET register_usergate_v86
	mov di,OFFSET register_usergate_v86_name
	xor cl,cl
	mov ax,register_usergate_v86_nr
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init_usergate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ILLEGAL_GATE
;
;		DESCRIPTION:	Illegal gate
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

illegal_gate_name	DB 'Undefined Gate',0

illegal_gate	PROC far
	int 3
	ret
illegal_gate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_USERGATE
;
;		DESCRIPTION:	Register 16- & 32-bit gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						DX		SEGMENT TRANSFER
;						DS:BX	16-BIT GATE CALL ADDRESS
;						DS:SI	32-BIT GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_usergate_name	DB 'Register User Gate',0

register_usergate	PROC far
	push fs
	push bx
	push cx
	push dx
;
	mov cx,bx
	mov bx,usergate_sel
	mov fs,bx
	mov bx,ax
	shl bx,5
	mov fs:[bx].gate_name_offset,di
	mov fs:[bx].gate_name_sel,es
	mov fs:[bx].gate_entry_offset16,cx
	mov fs:[bx].gate_entry_sel16,ds
	mov fs:[bx].gate_entry_offset32,si
	mov fs:[bx].gate_entry_sel32,ds
	xchg dx,fs:[bx].gate_transfer
	or dx,dx
	jnz register_user_nov86
;
	mov fs:[bx].gate_entry_offset_v86,cx
	mov fs:[bx].gate_entry_sel_v86,ds
	jmp register_user_done

register_user_nov86:
	xchg dx,fs:[bx].gate_transfer
	
register_user_done:
	pop dx
	pop cx
	pop bx
	pop fs
	ret
register_usergate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_BIMODAL_USERGATE
;
;		DESCRIPTION:	Register bimodal 16- & 32-bit gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						DX		SEGMENT TRANSFER
;						DS:SI	16- AND 32-BIT GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_bimodal_usergate_name	DB 'Register Bimodal User Gate',0

register_bimodal_usergate	PROC far
	push fs
	push bx
	push dx
;
	mov bx,usergate_sel
	mov fs,bx
	mov bx,ax
	shl bx,5
	mov fs:[bx].gate_name_offset,di
	mov fs:[bx].gate_name_sel,es
	mov fs:[bx].gate_entry_offset16,si
	mov fs:[bx].gate_entry_sel16,ds
	mov fs:[bx].gate_entry_offset32,si
	mov fs:[bx].gate_entry_sel32,ds
	xchg dx,fs:[bx].gate_transfer
	or dx,dx
	jnz register_bimodal_user_nov86
;
	mov fs:[bx].gate_entry_offset_v86,si
	mov fs:[bx].gate_entry_sel_v86,ds
	jmp register_bimodal_user_done

register_bimodal_user_nov86:
	xchg dx,fs:[bx].gate_transfer
	
register_bimodal_user_done:
	or fs:[bx].gate_transfer,gate16_override
;
	pop dx
	pop bx
	pop fs
	ret
register_bimodal_usergate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_USERGATE16
;
;		DESCRIPTION:	Register 16-bit gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						DX		SEGMENT TRANSFER
;						DS:SI	16-BIT GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_usergate16_name	DB 'Register 16-bit User Gate',0

register_usergate16	PROC far
	push fs
	push bx
	push dx
;
	mov bx,usergate_sel
	mov fs,bx
	mov bx,ax
	shl bx,5
	mov fs:[bx].gate_name_offset,di
	mov fs:[bx].gate_name_sel,es
	mov fs:[bx].gate_entry_offset16,si
	mov fs:[bx].gate_entry_sel16,ds
	xchg dx,fs:[bx].gate_transfer
	or dx,dx
	jnz register_user16_nov86
;
	mov fs:[bx].gate_entry_offset_v86,si
	mov fs:[bx].gate_entry_sel_v86,ds
	jmp register_user16_done

register_user16_nov86:
	xchg dx,fs:[bx].gate_transfer
	
register_user16_done:
	pop dx
	pop bx
	pop fs
	ret
register_usergate16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_USERGATE32
;
;		DESCRIPTION:	Register 32-bit gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						DS:SI	32-BIT GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_usergate32_name	DB 'Register 32-bit User Gate',0

register_usergate32	PROC far
	push fs
	push bx
;
	mov bx,usergate_sel
	mov fs,bx
	mov bx,ax
	shl bx,5
	mov fs:[bx].gate_name_offset,di
	mov fs:[bx].gate_name_sel,es
	mov fs:[bx].gate_entry_offset32,si
	mov fs:[bx].gate_entry_sel32,ds
;
	pop bx
	pop fs
	ret
register_usergate32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_USERGATE_V86
;
;		DESCRIPTION:	Register V86 gate
;
;		PARAMETERS:		AX		GATE NUMBER
;						DX		SEGMENT TRANSFER
;						DS:SI	V86 GATE CALL ADDRESS
;						ES:DI	GATE NAME ADDRESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_usergate_v86_name	DB 'Register V86 User Gate',0

register_usergate_v86	PROC far
	push fs
	push bx
;
	mov bx,usergate_sel
	mov fs,bx
	mov bx,ax
	shl bx,5
	mov fs:[bx].gate_name_offset,di
	mov fs:[bx].gate_name_sel,es
	mov fs:[bx].gate_entry_offset_v86,si
	mov fs:[bx].gate_entry_sel_v86,ds
	mov fs:[bx].gate_transfer,dx
;
	pop bx
	pop fs
	ret
register_usergate_v86	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRANSLATE_SEGMENTS
;
;		DESCRIPTION:	AL		Segment transfer
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

translate_segments	PROC near
	test al,virt_es_in
	jz translate_not_es_in
	mov bx,[bp].vm_es
	call translate_segment
	mov es,bx
translate_not_es_in:
	test al,virt_fs_in
	jz translate_not_fs_in
	mov bx,[bp].vm_fs
	call translate_segment
	mov fs,bx
translate_not_fs_in:
	test al,virt_gs_in
	jz translate_not_gs_in
	mov bx,[bp].vm_gs
	call translate_segment
	mov gs,bx
translate_not_gs_in:
	test al,virt_ds_in
	jz translate_not_ds_in
	mov bx,[bp].vm_ds
	call translate_segment
	mov ds,bx
	jmp translate_seg_end
translate_not_ds_in:
	xor bx,bx
	mov ds,bx
translate_seg_end:
	ret
translate_segments	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRANSLATE_SELECTORS
;
;		DESCRIPTION:	AL		Segment transfer
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

translate_selectors	PROC near
	mov bx,ds
	or bx,bx
	jz translate_out_ds_done
	xor ax,ax
	mov ds,ax
	call translate_selector
	jc translate_out_ds_done
	mov [bp].vm_ds,bx
translate_out_ds_done:
	mov bx,es
	or bx,bx
	jz translate_out_es_done
	xor ax,ax
	mov es,ax
	call translate_selector
	jc translate_out_es_done
	mov [bp].vm_es,bx
translate_out_es_done:
	mov bx,fs
	or bx,bx
	jz translate_out_fs_done
	xor ax,ax
	mov fs,ax
	call translate_selector
	jc translate_out_fs_done
	mov [bp].vm_fs,bx
translate_out_fs_done:
	mov bx,gs
	or bx,bx
	jz translate_out_gs_done
	xor ax,ax
	mov gs,ax
	call translate_selector
	jc translate_out_gs_done
	mov [bp].vm_gs,bx
translate_out_gs_done:
	ret
translate_selectors	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DO_USERGATE_VM
;
;		DESCRIPTION:	Translate a V86 mode usergate
;
;		PARAMETERS:		DS:EBX		Fault address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public do_usergate_vm

do_usergate_vm	PROC near
	mov bx,ds:[ebx+1]
	shl bx,5
	mov ax,usergate_sel
	mov ds,ax
;
	add word ptr [bp].vm_eip,8
	mov ax,[bp+2].vm_eflags
	and ax,NOT 1
	mov [bp+2].vm_eflags,ax
	mov ax,ds:[bx].gate_transfer
;
	push ax
	push bp
;
	test ds:[bx].gate_transfer, gate16_override
	jnz do_virtgate32
;
	push cs
	push OFFSET gate_return
	mov ax,[bp].vm_eflags
	and ax,03FFFh
	push ax
	push ds:[bx].gate_entry_sel_v86
	push ds:[bx].gate_entry_offset_v86
	jmp do_virtgate_translate

do_virtgate32:
	push 0
	push cs
	push 0
	push OFFSET gate_return
	mov ax,[bp].vm_eflags
	and ax,03FFFh
	push ax
	push ds:[bx].gate_entry_sel_v86
	push ds:[bx].gate_entry_offset_v86

do_virtgate_translate:
	mov ax,ds:[bx].gate_transfer
	and al,virt_seg_in
	jz do_no_translate_seg
;
	call translate_segments
	jmp do_virt_func

do_no_translate_seg:
	xor ax,ax
	mov ds,ax

do_virt_func:
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov bp,[bp].vm_bp
	iret

gate_return:
	pop bp
	mov [bp].vm_eax,eax
	mov [bp].vm_ebx,ebx
	pushf
	pop ax
	and ax,NOT 7000h
	mov [bp].vm_eflags,ax
	pop ax
	or al,al
	jz gate_exit
;
	call translate_selectors

gate_exit:
	ret
do_usergate_vm	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DO_USERGATE16
;
;		DESCRIPTION:	Translate a 16-bit protected mode usergate
;
;		PARAMETERS:		DS:EBX		Fault address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public do_usergate16

do_usergate16	PROC near
	mov ax,ds
	test ax,3
	jnz do_usergate16_gate
;
	push es
	push ecx
	push edx
	push edi
;
	mov edi,ds:[ebx+3]
	shl edi,5
	mov ax,usergate_sel
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
	test es:[edi].gate_transfer, gate16_override
	jnz do16_direct_to32
;
	mov ax,[bp].vm_eflags
	mov [bp+12],ax
	mov ax,[bp].vm_cs
	mov [bp+16],ax
	mov ax,[bp].vm_eip
	add ax,8
	mov [bp+14],ax	
;
	mov ax,es:[edi].gate_entry_sel16
	cmp ax,[bp+16]
	je do16_direct_cs16
;
	mov ds:[ebx+3],ax
	mov [bp+10],ax
	mov ax,es:[edi].gate_entry_offset16
	mov ds:[ebx+1],ax
	mov [bp+8],ax
	mov byte ptr ds:[ebx],9Ah
	mov word ptr ds:[ebx+5],9090h
	jmp do16_direct_do16

do16_direct_cs16:
	int 3
	mov [bp+10],ax
	mov ax,es:[edi].gate_entry_offset16
	mov [bp+8],ax
	sub ax,[bp+14]
	mov ds:[ebx+2],ax
	mov word ptr ds:[ebx],0E80Eh
	mov word ptr ds:[ebx+4],9090h
	mov byte ptr ds:[ebx+6],90h

do16_direct_do16:
	pop edi
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

do16_direct_to32:
	mov ax,[bp].vm_eflags
	mov [bp+8],ax
	movzx eax,word ptr [bp].vm_cs
	mov [bp+14],eax
	movzx eax,word ptr [bp].vm_eip
	add eax,8
	mov [bp+10],eax	
;
	mov ax,es:[edi].gate_entry_sel32
	cmp ax,[bp+14]
	je do16_direct_cs32
;
	mov ds:[ebx+6],ax
	mov [bp+6],ax
	movzx eax,es:[edi].gate_entry_offset32
	mov ds:[ebx+2],eax
	mov [bp+4],ax
	mov word ptr ds:[ebx],9A66h
	jmp do16_direct_do32

do16_direct_cs32:
	mov [bp+6],ax
	movzx eax,es:[edi].gate_entry_offset32
	mov [bp+4],ax
	sub eax,[bp+10]
	mov ds:[ebx+4],eax
	mov dword ptr ds:[ebx],0E8660E66h

do16_direct_do32:
	pop edi
	pop edx
	pop ecx
	pop es
;
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov sp,bp
	pop bp
	add sp,2
	iret

do_usergate16_gate:
	push es
	push ecx
	push edx
	push edi
;
	mov edi,ds:[ebx+3]
	shl edi,5
	mov ax,usergate_sel
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
	test es:[edi].gate_transfer, gate16_override
	jnz do16_gate_to32
;
	mov ax,[bp].vm_ss
	mov [bp+24],ax
	mov ax,[bp].vm_esp
	mov [bp+22],ax
	mov ax,[bp].vm_eflags
	mov [bp+16],ax
	mov ax,[bp].vm_cs
	mov [bp+20],ax
	mov ax,[bp].vm_eip
	add ax,7
	mov [bp+18],ax	
;
	mov ax,es:[edi].gate_sel16
	or ax,ax
	jnz do16_gate16_defined
;
	push ds
	push bx
	push si
	AllocateGdt
	or bx,3
	mov es:[edi].gate_sel16,bx
	mov si,es:[edi].gate_entry_offset16
	mov ds,es:[edi].gate_entry_sel16
	xor cl,cl
	CreateCallGateSelector16
	mov ax,bx
	pop si
	pop bx
	pop ds

do16_gate16_defined:
	shl eax,16
	mov ds:[ebx+2],eax
	mov word ptr ds:[ebx],9A90h
	mov byte ptr ds:[ebx+6],90h
;
	mov ax,es:[edi].gate_entry_sel16
	mov [bp+14],ax
	mov ax,es:[edi].gate_entry_offset16
	mov [bp+12],ax
;
	pop edi
	pop edx
	pop ecx
	pop es
;
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov sp,bp
	pop bp
	add sp,10
	iret

do16_gate_to32:
	mov ax,[bp].vm_eflags
	mov [bp+8],ax
	movzx eax,word ptr [bp].vm_cs
	mov [bp+14],eax
	movzx eax,word ptr [bp].vm_eip
	add eax,7
	mov [bp+10],eax	
;
	mov ax,es:[edi].gate_sel32
	or ax,ax
	jnz do16_gate32_defined
;
	push ds
	push bx
	push esi
	AllocateGdt
	or bx,3
	mov es:[edi].gate_sel32,bx
	movzx esi,es:[edi].gate_entry_offset32
	mov ds,es:[edi].gate_entry_sel32
	xor cl,cl
	CreateCallGateSelector32
	mov ax,bx
	pop esi
	pop bx
	pop ds

do16_gate32_defined:
	shl eax,16
	mov ds:[ebx+2],eax
	mov word ptr ds:[ebx],9A90h
	mov byte ptr ds:[ebx+6],90h
;
	mov ax,es:[edi].gate_entry_sel32
	mov [bp+6],ax
	movzx eax,es:[edi].gate_entry_offset32
	mov [bp+4],ax
;
	pop edi
	pop edx
	pop ecx
	pop es
;
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov sp,bp
	pop bp
	add sp,2
	iret
do_usergate16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DO_USERGATE32
;
;		DESCRIPTION:	Translate a 32-bit protected mode usergate
;
;		PARAMETERS:		DS:EBX		Fault address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public do_usergate32

do_usergate32	PROC near
	mov ax,ds
	test ax,3
	jnz do_usergate32_gate
;
	push es
	push ecx
	push edx
	push edi
;
	mov edi,ds:[ebx+3]
	shl edi,5
	mov ax,usergate_sel
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
	push ax
	movzx eax,word ptr [bp].vm_cs
	mov [bp+14],eax
	mov eax,[bp].vm_eip
	add eax,7
	mov [bp+10],eax	
	pop word ptr [bp+8]
;
	mov ax,es:[edi].gate_entry_sel32
	cmp ax,[bp+14]
	je do32_direct_cs32
;
	mov ds:[ebx+5],ax
	mov [bp+6],ax
	movzx eax,es:[edi].gate_entry_offset32
	mov ds:[ebx+1],eax
	mov [bp+4],ax
	mov byte ptr ds:[ebx],9Ah
	jmp do32_direct_do32

do32_direct_cs32:
	int 3
	mov [bp+6],ax
	movzx eax,es:[edi].gate_entry_offset32
	mov [bp+4],ax
	sub eax,[bp+10]
	dec eax
	mov ds:[ebx+2],eax
	mov word ptr ds:[ebx],0E80Eh
	mov byte ptr ds:[ebx+6],90h

do32_direct_do32:
	pop edi
	pop edx
	pop ecx
	pop es
;
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov sp,bp
	pop bp
	add sp,2
	iret

do_usergate32_gate:
	push es
	push ecx
	push edx
	push edi
;
	mov edi,ds:[ebx+3]
	shl edi,5
	mov ax,usergate_sel
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
	mov ax,[bp].vm_eflags
	push ax
	movzx eax,word ptr [bp].vm_cs
	mov [bp+14],eax
	mov eax,[bp].vm_eip
	add eax,7
	mov [bp+10],eax	
	pop word ptr [bp+8]
;
	mov ax,es:[edi].gate_sel32
	or ax,ax
	jnz do32_gate32_defined
;
	push ds
	push bx
	push esi
	AllocateGdt
	or bx,3
	mov es:[edi].gate_sel32,bx
	movzx esi,es:[edi].gate_entry_offset32
	mov ds,es:[edi].gate_entry_sel32
	xor cl,cl
	CreateCallGateSelector32
	mov ax,bx
	pop esi
	pop bx
	pop ds

do32_gate32_defined:
	mov byte ptr ds:[ebx],9Ah
	mov dword ptr ds:[ebx+1],0
	mov ds:[ebx+5],ax
;
	mov ax,es:[edi].gate_entry_sel32
	mov [bp+6],ax
	movzx eax,es:[edi].gate_entry_offset32
	mov [bp+4],ax
;
	pop edi
	pop edx
	pop ecx
	pop es
;
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov sp,bp
	pop bp
	add sp,2
	iret
do_usergate32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DO_USERGATE_FORCE32
;
;		DESCRIPTION:	Translate a 32-bit protected mode usergate from 16-bit
;
;		PARAMETERS:		DS:EBX		Fault address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public do_usergate_force32

do_usergate_force32	PROC near
	push es
	push ecx
	push edx
	push edi
;
	mov edi,ds:[ebx+3]
	shl edi,5
	mov ax,usergate_sel
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
	mov ax,[bp].vm_eflags
	mov [bp+8],ax
	movzx eax,word ptr [bp].vm_cs
	mov [bp+14],eax
	movzx eax,word ptr [bp].vm_eip
	add eax,8
	mov [bp+10],eax	
;
	mov ax,es:[edi].gate_entry_sel32
	cmp ax,[bp+14]
	je do32_force_cs32
;
	mov ds:[ebx+6],ax
	mov [bp+6],ax
	movzx eax,es:[edi].gate_entry_offset32
	mov ds:[ebx+2],eax
	mov [bp+4],ax
	mov word ptr ds:[ebx],9A66h
	jmp do32_force_do32

do32_force_cs32:
	mov [bp+6],ax
	movzx eax,es:[edi].gate_entry_offset32
	mov [bp+4],ax
	sub eax,[bp+10]
	mov ds:[ebx+4],eax
	mov dword ptr ds:[ebx],0E8660E66h

do32_force_do32:
	pop edi
	pop edx
	pop ecx
	pop es
;
	mov ds,[bp].pm_ds
	mov eax,[bp].vm_eax
	mov ebx,[bp].vm_ebx
	mov sp,bp
	pop bp
	add sp,2
	iret
do_usergate_force32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DO_USERCALL16
;
;		DESCRIPTION:	Translate a 16-bit protected mode user call
;
;		PARAMETERS:		DS:EBX		Fault address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public do_usercall16

do_usercall16	PROC near
	push es
	push ecx
	push edx
	push edi
;
	movzx edi,word ptr ds:[ebx+1]
	shl edi,5
	mov ax,usergate_sel
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
	test es:[edi].gate_transfer, gate16_override
	jnz do16_call_to32

do16_call_to16:
	mov ax,es:[edi].gate_sel16
	or ax,ax
	jnz do16_call_defined
;
	push ds
	push bx
	push esi
	AllocateGdt
	or bx,3
	mov es:[edi].gate_sel16,bx
	movzx esi,es:[edi].gate_entry_offset16
	mov ds,es:[edi].gate_entry_sel16
	xor cl,cl
	CreateCallGateSelector16
	mov ax,bx
	pop esi
	pop bx
	pop ds
	jmp do16_call_defined

do16_call_to32:
	mov ax,es:[edi].gate_sel32
	or ax,ax
	jnz do16_call_defined
;
	push ds
	push bx
	push esi
	AllocateGdt
	or bx,3
	mov es:[edi].gate_sel32,bx
	movzx esi,es:[edi].gate_entry_offset32
	mov ds,es:[edi].gate_entry_sel32
	xor cl,cl
	CreateCallGateSelector32
	mov ax,bx
	pop esi
	pop bx
	pop ds

do16_call_defined:
	mov word ptr ds:[ebx+1],0
	mov ds:[ebx+3],ax
;
	pop edi
	pop edx
	pop ecx
	pop es
	clc
	ret
do_usercall16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DO_USERCALL32
;
;		DESCRIPTION:	Translate a 32-bit protected mode user call
;
;		PARAMETERS:		DS:EBX		Fault address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public do_usercall32

do_usercall32	PROC near
	push es
	push ecx
	push edx
	push edi
;
	mov edi,ds:[ebx+1]
	shl edi,5
	mov ax,usergate_sel
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
	mov ax,es:[edi].gate_sel32
	or ax,ax
	jnz do32_call_defined
;
	push ds
	push bx
	push esi
	AllocateGdt
	or bx,3
	mov es:[edi].gate_sel32,bx
	movzx esi,es:[edi].gate_entry_offset32
	mov ds,es:[edi].gate_entry_sel32
	xor cl,cl
	CreateCallGateSelector32
	mov ax,bx
	pop esi
	pop bx
	pop ds

do32_call_defined:
	mov dword ptr ds:[ebx+1],0
	mov ds:[ebx+5],ax
;
	pop edi
	pop edx
	pop ecx
	pop es
	clc
	ret
do_usercall32	ENDP

code	ENDS

	END

