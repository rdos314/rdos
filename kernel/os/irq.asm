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
; IRQ.ASM
; IRQ handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME irq

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE driver.def
INCLUDE port.def
INCLUDE int.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc

irq_struc	STRUC

user_data		DW ?
user_handler	DD ?

owner_cr3		DD ?

vm_offs			DW ?
vm_seg			DW ?

pm16_offs		DW ?
pm16_sel		DW ?

pm32_offs		DD ?
pm32_sel		DW ?

emul_thread		DW ?

usage_section	section_typ <>

irq_struc	ENDS

irq_proc_seg	SEGMENT AT 0

mask0			DB ?
mask1			DB ?

irq_proc_seg	ENDS

irq_sys_seg	SEGMENT AT 0

irq_vm_seg		DW ?
irq_pm16_sel	DW ?
irq_pm32_sel	DW ?

irq_arr			DB 16 * SIZE irq_struc DUP(?)

irq_sys_seg	ENDS

irq_ss		EQU 18
irq_esp		EQU 14
irq_eflags	EQU 10
irq_cs		EQU 6
irq_eip		EQU 2
irq_bp		EQU 0

irq	MACRO nr

irq_thread&nr:
	int 3
	jmp irq_thread&nr

irq&nr:
	push bp
	mov bp,sp
	push ds
	push es
	pushad
;
	call enter_int
	mov al,nr
	sti
irq_mask_done&nr:
	mov bx,OFFSET irq_arr + nr * SIZE irq_struc
	mov eax,ds:[bx].owner_cr3
	or eax,eax
	jz irq_default&nr
	int 3
	mov edx,cr3
	cmp eax,edx
	jne irq_handle_in_thread&nr
	mov ax,irq_proc_sel
	mov es,ax
IF nr LE 7
	test es:mask0,1 SHL nr
ELSE
	test es:mask1,1 SHL (nr-8)
ENDIF
	jnz irq_default&nr
	GetFlags
	test ax,200h
	jz irq_handle_in_thread&nr
	test byte ptr [bp+2].irq_eflags,2
	jz irq_handle_prot&nr
irq_handle_virt&nr:
	mov ax,ds:[bx].vm_seg
	cmp ax,ds:irq_vm_seg
	je irq_save_context&nr
	mov ax,flat_sel
	mov es,ax
	mov edx,[bp].irq_ss
	shl edx,4
	movzx eax,word ptr [bp].irq_esp
	sub ax,6
	mov [bp].irq_esp,ax
	add edx,eax
	mov ax,ds:[bx].vm_offs
	mov es:[edx],ax
	mov ax,ds:[bx].vm_seg
	mov es:[edx+2],ax
	mov ax,[bp].irq_eflags
	mov es:[edx+4],ax
	jmp irq_handle_done&nr
irq_handle_prot&nr:
	int 3
	mov al,[bp].irq_cs
	and al,3
	cmp al,3
	jne irq_save_context&nr
	int 3
irq_save_context&nr:
	mov dx,bx
	SaveContext
	xchg bx,dx
	mov ax,ds:[bx].pm32_sel
	cmp ax,ds:irq_pm32_sel
	je irq_not_context32_&nr
	int 3
irq_not_context32_&nr:
	mov ax,ds:[bx].pm16_sel
	cmp ax,ds:irq_pm16_sel
	je irq_not_context16_&nr
	int 3
irq_not_context16_&nr:
	mov ax,thread_int_sel
	mov es,ax
	mov edx,es:pint_real_stack
	or edx,edx
	jnz irq_real_stack_ok&nr
	mov eax,210h
	AllocateVMLinear
	mov es:pint_real_stack,edx
irq_real_stack_ok&nr:
	mov ax,flat_sel
	mov es,ax
	mov eax,edx
	shr edx,4
	and eax,0Fh
	add eax,200h-6
	mov [bp].vm_ss,dx
	mov [bp].vm_esp,eax
	shl edx,4
	add edx,eax
	mov ax,ds:[bx].vm_offs
	mov es:[edx],ax
	mov ax,ds:[bx].vm_seg
	mov es:[edx+2],ax
	mov ax,[bp].vm_eflags
	mov es:[edx+4],ax
	mov ax,ds:[bx].vm_offs
	mov [bp].vm_eip,ax
	mov ax,ds:[bx].vm_seg
	mov [bp].vm_cs,ax
	mov ax,[bp].irq_eflags
	mov [bp].vm_eflags,ax
	mov byte ptr [bp+2].vm_eflags,2
	iretd	
	jmp irq_handle_done&nr
irq_handle_in_thread&nr:
	int 3
irq_default&nr:
	mov ax,irq_sys_sel
	mov es,ax
	mov bx,OFFSET irq_arr + nr * SIZE irq_struc
	mov eax,es:[bx].user_handler
	or eax,eax
	jz irq_default_error&nr
;
	mov ds,es:[bx].user_data
	push cs
	push OFFSET irq_default_error&nr
	push es:[bx].user_handler
	xor ax,ax
	mov es,ax
	retf

irq_default_error&nr:
irq_handle_done&nr:
	cli
IF nr GT 7
	mov al,62h
	out INT0_CONTROL,al
	jmp short $+2
	mov al,60h + nr - 8
	out INT1_CONTROL,al
ELSE
	mov al,60h + nr
	out INT0_CONTROL,al
ENDIF		
	call leave_int
irq_unmask_done&nr:
	popad
	pop es
	pop ds
	pop bp
	iretd

get_irq&nr	Proc far
	push ds
	push eax
	mov bx,irq_sys_sel
	mov ds,bx
	mov eax,cr3
	mov bx,OFFSET irq_arr + nr * SIZE irq_struc
	cmp eax,ds:[bx].owner_cr3
	jne get_irq_default&nr
	mov bx,ds:[bx].vm_offs
	mov dx,ds:[bx].vm_seg
	jmp get_irq_done&nr
get_irq_default&nr:
	mov bx,nr*4
	mov dx,ds:irq_vm_seg
get_irq_done&nr:
	pop eax
	pop ds
	ret
get_irq&nr	Endp

set_irq&nr	Proc far
	push ds
	push eax
	push cx
	mov cx,irq_sys_sel
	mov ds,cx
	mov cx,bx
	mov bx,OFFSET irq_arr + nr * SIZE irq_struc
set_irq_try&nr:
	mov eax,cr3
	cmp eax,ds:[bx].owner_cr3
	je set_irq_do&nr
	EnterSection ds:[bx].usage_section
	mov ds:[bx].owner_cr3,eax
set_irq_do&nr:
	mov ds:[bx].vm_offs,cx
	mov ds:[bx].vm_seg,dx
	cmp dx,ds:irq_vm_seg
	jne set_irq_not_free&nr
	mov ax,ds:[bx].pm16_sel
	cmp ax,ds:irq_pm16_sel
	jne set_irq_not_free&nr
	mov ax,ds:[bx].pm32_sel
	cmp ax,ds:irq_pm32_sel
	jne set_irq_not_free&nr
	LeaveSection ds:[bx].usage_section
set_irq_not_free&nr:
	pop cx
	pop eax
	pop ds
	ret
set_irq&nr	Endp

	ENDM
		
	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn enter_int:near
	extrn leave_int:near

irq_offs_table:
	DW OFFSET irq_arr
	DW OFFSET irq_arr + SIZE irq_struc
	DW OFFSET irq_arr + 2 * SIZE irq_struc
	DW OFFSET irq_arr + 3 * SIZE irq_struc
	DW OFFSET irq_arr + 4 * SIZE irq_struc
	DW OFFSET irq_arr + 5 * SIZE irq_struc
	DW OFFSET irq_arr + 6 * SIZE irq_struc
	DW OFFSET irq_arr + 7 * SIZE irq_struc
	DW OFFSET irq_arr + 8 * SIZE irq_struc
	DW OFFSET irq_arr + 9 * SIZE irq_struc
	DW OFFSET irq_arr + 10 * SIZE irq_struc
	DW OFFSET irq_arr + 11 * SIZE irq_struc
	DW OFFSET irq_arr + 12 * SIZE irq_struc
	DW OFFSET irq_arr + 13 * SIZE irq_struc
	DW OFFSET irq_arr + 14 * SIZE irq_struc
	DW OFFSET irq_arr + 15 * SIZE irq_struc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IN_CONTROL0
;
;		DESCRIPTION:	Virtualize PIC0 control port
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_control0	PROC far
	in al,20h
	ret
in_control0	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OUT_CONTROL0
;
;		DESCRIPTION:	Virtualize PIC0 control port
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_control0	PROC far
	cmp al,20h
	jne out_control0_done
	out dx,al
out_control0_done:
	ret
out_control0	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IN_MASK0
;
;		DESCRIPTION:	Virtualize PIC0 mask
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_mask0	PROC far
	mov bx,irq_proc_sel
	mov ds,bx
	mov al,ds:mask0
	ret
in_mask0	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OUT_MASK0
;
;		DESCRIPTION:	Virtualize PIC0 mask
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_mask0	PROC far
	mov bx,irq_proc_sel
	mov ds,bx
	push ax
	mov ah,al
	in al,21h
	and al,ah
	out 21h,al
	pop ax
	mov ds:mask0,al
	ret
out_mask0	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IN_CONTROL1
;
;		DESCRIPTION:	Virtualize PIC1 control port
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_control1	PROC far
	in al,0A0h
	ret
in_control1	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OUT_CONTROL1
;
;		DESCRIPTION:	Virtualize PIC1 control port
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_control1	PROC far
	cmp al,20h
	jne out_control1_done
	out dx,al
out_control1_done:
	ret
out_control1	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IN_MASK1
;
;		DESCRIPTION:	Virtualize PIC1 mask
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_mask1	PROC far
	mov bx,irq_proc_sel
	mov ds,bx
	mov al,ds:mask1
	ret
in_mask1	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OUT_MASK1
;
;		DESCRIPTION:	Virtualize PIC1 mask
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_mask1	PROC far
	mov bx,irq_proc_sel
	mov ds,bx
	push ax
	mov ah,al
	in al,0A1h
	and al,ah
	out 0A1h,al
	pop ax
	mov ds:mask1,al
	ret
out_mask1	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROCESS
;
;		DESCRIPTION:	Initialize per-process data
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process	PROC far
	push ds
	push ax
	mov ax,irq_proc_sel
	mov ds,ax
	mov ds:mask0,0FFh
	mov ds:mask1,0FFh
	pop ax
	pop ds
	ret
init_process	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IRQx
;
;		DESCRIPTION:	IRQ handlers
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	irq 1
	irq 3
	irq 4
	irq 5
	irq 6
	irq 7
	irq 8
	irq 9
	irq 10
	irq 11
	irq 12
	irq 13
	irq 14
	irq 15

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			request_private_irq_handler
;
;		description:	Request for a private irq handler (non sharable)
;
;		PARAMETERS:		ds			data for handler
;						al			irq nr
;						es:di		handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_private_irq_handler_name DB 'Request Private Irq Handler',0

request_private_irq_handler	Proc far
	push ds
	pusha
;
	mov dx,ds
	movzx bx,al
	mov ax,irq_sys_sel
	mov ds,ax
	mov si,bx
	add si,si
	mov si,word ptr cs:[si].irq_offs_table
	EnterSection ds:[si].usage_section
	mov ds:[si].user_data,dx
	mov word ptr ds:[si].user_handler,di
	mov word ptr ds:[si].user_handler+2,es
;
	mov al,bl
	test al,8
	jz set_pic1
set_pic2:
	sub al,8
	mov cl,al
	mov ah,1
	rol ah,cl
	not ah
	cli
	in al,0A1h
	jmp short $+2
	and al,ah
	out 0A1h,al
	sti
	jmp set_pic_done
set_pic1:
	mov cl,al
	mov ah,1
	rol ah,cl
	not ah
	cli
	in al,21h
	jmp short $+2
	and al,ah
	out 21h,al
	sti
set_pic_done:
;
	popa
	pop ds
	ret
request_private_irq_handler	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			release_private_irq_handler
;
;		description:	Release a no shareable irq handler
;
;		PARAMETERS:		al			irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

release_private_irq_handler_name	DB 'Release Private Irq Handler',0

release_private_irq_handler	Proc far
	push ds
	push ax
	push bx
;
	movzx bx,al
	mov al,bl
	test al,8
	jz remove_pic1
remove_pic2:
	sub al,8
	mov cl,al
	mov ah,1
	rol ah,cl
	cli
	in al,0A1h
	or al,ah
	out 0A1h,al
	sti
	jmp remove_pic_done
remove_pic1:
	mov cl,al
	mov ah,1
	rol ah,cl
	cli
	in al,21h
	or al,ah
	out 21h,al
	sti
remove_pic_done:
	mov ax,irq_sys_sel
	mov ds,ax
	add bx,bx
	mov bx,word ptr cs:[bx].irq_offs_table
	LeaveSection ds:[bx].usage_section
;
	pop bx
	pop ax
	pop ds
	ret
release_private_irq_handler	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_HARDWARE_INT
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irq_vm_0:
	IrqVm 0

	public irq_vm

irq_vm:
	int 3

irq_pm16_0:
	IrqProt16 0

	public irq_pm16

irq_pm16:
	int 3

irq_pm32_0:
	IrqProt32 0

	public irq_pm32

irq_pm32:
	int 3

	public init_irq

init_irq	PROC near
	pusha
	push ds
	push es
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET request_private_irq_handler
	mov di,OFFSET request_private_irq_handler_name
	xor cl,cl
	mov ax,request_private_irq_handler_nr
	RegisterOsGate
;
	mov si,OFFSET release_private_irq_handler
	mov di,OFFSET release_private_irq_handler_name
	xor cl,cl
	mov ax,release_private_irq_handler_nr
	RegisterOsGate
;
	xor eax,eax
	mov ax,SIZE irq_proc_seg
	mov bx,irq_proc_sel
	AllocateFixedProcessMem
;
	xor eax,eax
	mov ax,SIZE irq_sys_seg
	mov bx,irq_sys_sel
	AllocateFixedSystemMem
	mov ds,bx
;
	mov eax,4*16
	AllocateFixedVmLinear
	shr edx,4
	mov ds:irq_vm_seg,dx
	shl edx,4
	mov cx,16
	mov ax,flat_sel
	mov es,ax
	mov eax,dword ptr cs:irq_vm_0
init_irq_vm_loop:
	mov es:[edx],eax
	add edx,4
	add eax,1000000h
	loop init_irq_vm_loop
;
	mov eax,4*16
	AllocateSmallGlobalMem
	mov bx,es
	or bx,3
	mov ds:irq_pm16_sel,bx
	mov cx,16
	mov eax,dword ptr cs:irq_pm16_0
	xor di,di
init_irq_pm16_loop:
	stosd
	add eax,1000000h
	loop init_irq_pm16_loop
	and bx,0FFF8h
	mov ax,gdt_sel
	mov es,ax
	mov byte ptr es:[bx+5],0FAh
;
	mov eax,4*16
	AllocateSmallGlobalMem
	mov bx,es
	or bx,3
	mov ds:irq_pm32_sel,bx
	mov cx,16
	mov eax,dword ptr cs:irq_pm32_0
	xor di,di
init_irq_pm32_loop:
	stosd
	add eax,1000000h
	loop init_irq_pm32_loop
	and bx,0FFF8h
	mov ax,gdt_sel
	mov es,ax
	mov byte ptr es:[bx+5],0FAh
;
	mov cx,16
	mov bx,OFFSET irq_arr
	xor eax,eax
init_irq_loop:
	mov ds:[bx].owner_cr3,0
	mov ds:[bx].user_handler,0
	mov ds:[bx].vm_offs,ax
	mov dx,ds:irq_vm_seg
	mov ds:[bx].vm_seg,dx
	mov ds:[bx].pm16_offs,ax
	mov dx,ds:irq_pm16_sel
	mov ds:[bx].pm16_sel,dx
	mov ds:[bx].pm32_offs,eax
	mov dx,ds:irq_pm32_sel
	mov ds:[bx].pm32_sel,dx
	add ax,4
	InitSection ds:[bx].usage_section
	add bx,SIZE irq_struc
	loop init_irq_loop
;
	mov bx,OFFSET irq_arr
	mov ds:[bx].owner_cr3,-1
	EnterSection ds:[bx].usage_section
	add bx,2 * SIZE irq_struc
	mov ds:[bx].owner_cr3,-1
	EnterSection ds:[bx].usage_section
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_process
	HookCreateProcess
;
	mov di,OFFSET in_control0
	mov dx,20h
	HookIn
;
	mov di,OFFSET out_control0
	mov dx,20h
	HookOut
;
	mov di,OFFSET in_mask0
	mov dx,21h
	HookIn
;
	mov di,OFFSET out_mask0
	mov dx,21h
	HookOut
;
	mov di,OFFSET in_control1
	mov dx,0A0h
	HookIn
;
	mov di,OFFSET out_control1
	mov dx,0A0h
	HookOut
;
	mov di,OFFSET in_mask1
	mov dx,0A1h
	HookIn
;
	mov di,OFFSET out_mask1
	mov dx,0A1h
	HookOut
;
	mov di,OFFSET get_irq1
	mov al,9
	HookGetVMInt
;
	mov di,OFFSET set_irq1
	mov al,9
	HookSetVMInt
;
	mov di,OFFSET get_irq3
	mov al,0Bh
	HookGetVMInt
;
	mov di,OFFSET set_irq3
	mov al,0Bh
	HookSetVMInt
;
	mov di,OFFSET get_irq4
	mov al,0Ch
	HookGetVMInt
;
	mov di,OFFSET set_irq4
	mov al,0Ch
	HookSetVMInt
;
	mov di,OFFSET get_irq5
	mov al,0Dh
	HookGetVMInt
;
	mov di,OFFSET set_irq5
	mov al,0Dh
	HookSetVMInt
;
	mov di,OFFSET get_irq6
	mov al,0Eh
	HookGetVMInt
;
	mov di,OFFSET set_irq6
	mov al,0Eh
	HookSetVMInt
;
	mov di,OFFSET get_irq7
	mov al,0Fh
	HookGetVMInt
;
	mov di,OFFSET set_irq7
	mov al,0Fh
	HookSetVMInt
;
	mov di,OFFSET get_irq8
	mov al,78h
	HookGetVMInt
;
	mov di,OFFSET set_irq8
	mov al,78h
	HookSetVMInt
;
	mov di,OFFSET get_irq9
	mov al,79h
	HookGetVMInt
;
	mov di,OFFSET set_irq9
	mov al,79h
	HookSetVMInt
;
	mov di,OFFSET get_irq10
	mov al,7Ah
	HookGetVMInt
;
	mov di,OFFSET set_irq10
	mov al,7Ah
	HookSetVMInt
;
	mov di,OFFSET get_irq11
	mov al,7Bh
	HookGetVMInt
;
	mov di,OFFSET set_irq11
	mov al,7Bh
	HookSetVMInt
;
	mov di,OFFSET get_irq12
	mov al,7Ch
	HookGetVMInt
;
	mov di,OFFSET set_irq12
	mov al,7Ch
	HookSetVMInt
;
	mov di,OFFSET get_irq13
	mov al,7Dh
	HookGetVMInt
;
	mov di,OFFSET set_irq13
	mov al,7Dh
	HookSetVMInt
;
	mov di,OFFSET get_irq14
	mov al,7Eh
	HookGetVMInt
;
	mov di,OFFSET set_irq14
	mov al,7Eh
	HookSetVMInt
;
	mov di,OFFSET get_irq15
	mov al,7Fh
	HookGetVMInt
;
	mov di,OFFSET set_irq15
	mov al,7Fh
	HookSetVMInt
;
	mov ax,cs
	mov ds,ax
	xor bl,bl
;
	mov al,29h
	mov esi,OFFSET irq1
	CreateIntGateSelector
;
	mov al,2Bh
	mov esi,OFFSET irq3
	CreateIntGateSelector
;
	mov al,2Ch
	mov esi,OFFSET irq4
	CreateIntGateSelector
;
	mov al,2Dh
	mov esi,OFFSET irq5
	CreateIntGateSelector
;
	mov al,2Eh
	mov esi,OFFSET irq6
	CreateIntGateSelector
;
	mov al,2Fh
	mov esi,OFFSET irq7
	CreateIntGateSelector
;
	mov al,38h
	mov esi,OFFSET irq8
	CreateIntGateSelector
;
	mov al,39h
	mov esi,OFFSET irq9
	CreateIntGateSelector
;
	mov al,3Ah
	mov esi,OFFSET irq10
	CreateIntGateSelector
;
	mov al,3Bh
	mov esi,OFFSET irq11
	CreateIntGateSelector
;
	mov al,3Ch
	mov esi,OFFSET irq12
	CreateIntGateSelector
;
	mov al,3Dh
	mov esi,OFFSET irq13
	CreateIntGateSelector
;
	mov al,3Eh
	mov esi,OFFSET irq14
	CreateIntGateSelector
;
	mov al,3Fh
	mov esi,OFFSET irq15
	CreateIntGateSelector
;
	mov al,11h
	out INT0_CONTROL,al
	jmp short $+2
;
	mov al,28h
	out INT0_MASK,al
	jmp short $+2
;
	mov al,04h
	out INT0_MASK,al
	jmp short $+2
;
	mov al,0C1h
	out INT0_CONTROL,AL
	jmp short $+2
;
	mov al,1
	out INT0_MASK,al
	jmp short $+2
;
	mov al,NOT 4
	out INT0_MASK,al
;
	mov al,11h
	out INT1_CONTROL,al
	jmp short $+2
;
	mov al,38h
	out INT1_MASK,al
	jmp short $+2
;
	mov al,2
	jmp short $+2
	out INT1_MASK,al
	jmp short $+2
;
	mov al,1
	out INT1_MASK,al
	jmp short $+2
;
	mov al,-1
	out INT1_MASK,al
	jmp short $+2
;
	pop es
	pop ds
	popa
	ret
init_irq	ENDP

code	ENDS

	END

