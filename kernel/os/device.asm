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
; DEVICE.ASM
; Device driver handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  device

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
	
code	SEGMENT byte public 'CODE'

.386

	assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			move_kernel_code
;
;		DESCRIPTION:	Move kernel code descriptor high
;
;		PARAMETERS:		EDX		NEW BASE ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_kernel_code	Proc near
	push bx
	push edx
	mov bx,cs
	mov es:[bx+2],edx
	mov byte ptr es:[bx+5],9Ah
	shr edx,16
	xor dl,dl
	mov es:[bx+6],dx
	db 0EAh
	dw OFFSET move_kernel_done
	dw kernel_code
move_kernel_done:
	pop edx
	pop bx
	ret
move_kernel_code	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			move_shutdown_code
;
;		DESCRIPTION:	Move shutdown code high
;
;		PARAMETERS:		EDX		NEW BASE ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_shutdown_code	Proc near
	push bx
	push edx
	mov bx,shutdown_code_sel
	mov es:[bx+2],edx
	mov byte ptr es:[bx+5],9Ah
	shr edx,16
	xor dl,dl
	mov es:[bx+6],dx
	pop edx
	pop bx
	ret
move_shutdown_code	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			move_adapters
;
;		DESCRIPTION:	Move adapters to private address space
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public move_adapters

move_adapters	PROC near
	push ds
	push es
	push fs
	pushad
;
	mov ax,gdt_sel
	mov es,ax
	mov ax,system_data_sel
	mov fs,ax
;
	mov bx,cs
	mov eax,es:[bx+2]
	rol eax,8
	mov al,es:[bx+7]
	ror eax,8
	mov esi,eax
;
	mov bx,shutdown_code_sel
	mov eax,es:[bx+2]
	rol eax,8
	mov al,es:[bx+7]
	ror eax,8
	mov edi,eax
;
	mov cx,fs:rom_modules
	mov bx,OFFSET rom_adapters
move_adapter_loop:
	push cx
	push esi
	push edi
;
	cmp fs:rom_shadow,0
	je move_adapter_shadow_ok
;
	push es
	mov ax,flat_sel
	mov ds,ax
	mov es,ax
;
	mov edx,kernel_linear
	mov edi,edx
	mov esi,fs:[bx].adapter_base
	mov ecx,fs:[bx].adapter_size
	dec ecx
	shr ecx,2
	inc ecx
	rep movs dword ptr es:[edi],ds:[esi]
;
	pop es
	jmp move_page_done

move_adapter_shadow_ok:
	mov ax,sys_page_sel
	mov ds,ax
	mov ecx,fs:[bx].adapter_size
	mov esi,fs:[bx].adapter_base
	mov eax,esi
	and si,0F000h
	sub eax,esi
	add ecx,eax
	mov edi,esi
;
	sub edi,fs:rom1_base
	jc move_adapter_try2
;
	cmp edi,fs:rom1_size
	jc move_adapter_bias

move_adapter_try2:
	add edi,fs:rom1_base
	sub edi,fs:rom2_base

move_adapter_bias:
	add edi,kernel_linear
	mov edx,edi
	shr esi,12
	shl esi,2
	shr edi,12
	shl edi,2
	dec ecx
	add ecx,1000h
	shr ecx,12

move_page_loop:
	mov eax,[esi]
	mov al,5
	mov [edi],eax
	add esi,4
	add edi,4
	loop move_page_loop

move_page_done:
	pop edi
	pop esi
	mov eax,esi
	sub eax,fs:[bx].adapter_base
	jc move_not_current_adapter
	cmp eax,fs:[bx].adapter_size
	jnc move_not_current_adapter
;
	push edx
;	mov cx,word ptr fs:[bx].adapter_base
;	and cx,0FFFh
;	or dx,cx
	add edx,eax
	call move_kernel_code
	pop edx
move_not_current_adapter:
	mov eax,edi
	sub eax,fs:[bx].adapter_base
	jc move_not_shutdown_adapter
	cmp eax,fs:[bx].adapter_size
	jnc move_not_shutdown_adapter
	push edx
;	mov cx,word ptr fs:[bx].adapter_base
;	and cx,0FFFh
;	or dx,cx
	add edx,eax
	call move_shutdown_code
	pop edx
move_not_shutdown_adapter:
;	mov ax,word ptr fs:[bx].adapter_base
;	and ax,0FFFh
;	or dx,ax
	mov fs:[bx].adapter_base,edx
	add bx,SIZE adapter_typ
	pop cx
	sub cx,1
	jnz move_adapter_loop	
;
	popad
	pop fs
	pop es
	pop ds
	ret
move_adapters	ENDP

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_DEVICE_PR
;
;		DESCRIPTION:	Init device code selector
;
;		PARAMETERS:		BX				CODE SELECTOR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_device_name	DB 'Init Device',0

init_device_pr	PROC far
	push bp
	mov bp,sp
	push ds
	push eax
	push si
	mov ax,gdt_sel
	mov ds,ax
	mov si,[bp+4]
	mov eax,[si]
	mov [bx],eax
	mov eax,[si+4]
	mov [bx+4],eax
	mov [bp+4],bx
	pop si
	pop eax
	pop ds
	pop bp
	ret
init_device_pr	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			install_simple_device
;
;		DESCRIPTION:	install simple device
;
;		PARAMETERS:		DS:EDX	device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_simple_device	PROC near
	push ds
	push es
	pushad
	mov ecx,[edx].len
	sub ecx,SIZE rdos_header
	add edx,SIZE rdos_header
	mov ax,[edx].init_ip
	sub ecx,SIZE simple_device_header
	add edx,SIZE simple_device_header
	mov bx,device_code_sel
	CreateCodeSelector16
;
	push cs
	push OFFSET install_simple_device_end
	push bx
	push ax
	retf
install_simple_device_end:
	popad
	pop es
	pop ds
	ret
install_simple_device	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			install_device
;
;		DESCRIPTION:	install device
;
;		PARAMETERS:		DS:EDX	device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_device	PROC near
	push ds
	push es
	pushad
	mov ecx,[edx].len
	sub ecx,SIZE rdos_header
	add edx,SIZE rdos_header
	mov ax,[edx].dev_init_ip
	movzx ebx,[edx].dev_size
	sub ecx,ebx
	add edx,ebx
	mov bx,device_code_sel
	CreateCodeSelector16
;
	push cs
	push OFFSET install_device_end
	push bx
	push ax
	retf

install_device_end:
	popad
	pop es
	pop ds
	ret
install_device	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			install_adapter
;
;		DESCRIPTION:	install devices in adapter
;
;		PARAMETERS:		edx		base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_adapter	Proc near
	push ds
	push ax
	push bx
	push edx
	mov ax,flat_sel
	mov ds,ax
install_adapter_loop:
	mov ax,[edx].typ
	cmp ax,RdosSimpleDevice
	jne not_install_simple_device
;	
	call install_simple_device
	jmp install_adapter_next

not_install_simple_device:
	cmp ax,RdosDevice
	jne not_install_device
;	
	call install_device
	jmp install_adapter_next
	
not_install_device:
	cmp ax,RdosEnd
	je install_adapter_done
install_adapter_next:
	add edx,[edx].len
	jmp install_adapter_loop
install_adapter_done:
	pop edx
	pop bx
	pop ax
	pop ds
	ret
install_adapter	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_device
;
;		DESCRIPTION:	Init module (devices)
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_device

init_device	PROC near
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET init_device_pr
	mov di,OFFSET init_device_name
	xor cl,cl
	mov ax,init_device_nr
	RegisterOsGate
;
	mov ax,system_data_sel
	mov ds,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
init_device_loop:
	mov edx,[bx].adapter_base
	call install_adapter
	add bx,SIZE adapter_typ
	loop init_device_loop	
;
	popa
	pop es
	pop ds
	ret
init_device	ENDP
	
code	ENDS

	END
