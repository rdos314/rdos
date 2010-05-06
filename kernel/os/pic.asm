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
; PIC.ASM
; Legacy PIC module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME pic

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE int.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE irq.inc
		
	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

irqmac	MACRO nr

irq&nr:
	push bp
	mov bp,sp
	push ds
	push es
	push fs
	pushad
;
    EnterInt
	sti
;	
	mov ax,irq_sys_sel
	mov es,ax
	mov bx,OFFSET irq_arr + nr * SIZE irq_struc
	mov eax,es:[bx].user_handler
	or eax,eax
	jz irq_default_error&nr
;
	mov ds,es:[bx].user_data
	push cs
	push OFFSET irq_handle_done&nr
	push es:[bx].user_handler
	xor ax,ax
	mov es,ax
	retf

irq_default_error&nr:
IF nr GT 7
	in al,INT1_MASK
	or al,1 SHL (nr-8)
	out INT1_MASK,al
ELSE
    in al,INT0_MASK
	or al,1 SHL nr
	out INT0_MASK,al
ENDIF
	or es:bad_irqs, 1 SHL nr

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
    LeaveInt
irq_unmask_done&nr:
	popad
	pop fs
	pop es
	pop ds
	pop bp
	iretd

	ENDM

irq_offs_table:
io00 DW OFFSET irq_arr
io01 DW OFFSET irq_arr + SIZE irq_struc
io02 DW OFFSET irq_arr + 2 * SIZE irq_struc
io03 DW OFFSET irq_arr + 3 * SIZE irq_struc
io04 DW OFFSET irq_arr + 4 * SIZE irq_struc
io05 DW OFFSET irq_arr + 5 * SIZE irq_struc
io06 DW OFFSET irq_arr + 6 * SIZE irq_struc
io07 DW OFFSET irq_arr + 7 * SIZE irq_struc
io08 DW OFFSET irq_arr + 8 * SIZE irq_struc
io09 DW OFFSET irq_arr + 9 * SIZE irq_struc
io0A DW OFFSET irq_arr + 10 * SIZE irq_struc
io0B DW OFFSET irq_arr + 11 * SIZE irq_struc
io0C DW OFFSET irq_arr + 12 * SIZE irq_struc
io0D DW OFFSET irq_arr + 13 * SIZE irq_struc
io0E DW OFFSET irq_arr + 14 * SIZE irq_struc
io0F DW OFFSET irq_arr + 15 * SIZE irq_struc
io10 DW OFFSET irq_arr + 16 * SIZE irq_struc
io11 DW OFFSET irq_arr + 17 * SIZE irq_struc
io12 DW OFFSET irq_arr + 18 * SIZE irq_struc
io13 DW OFFSET irq_arr + 19 * SIZE irq_struc
io14 DW OFFSET irq_arr + 20 * SIZE irq_struc
io15 DW OFFSET irq_arr + 21 * SIZE irq_struc
io16 DW OFFSET irq_arr + 22 * SIZE irq_struc
io17 DW OFFSET irq_arr + 23 * SIZE irq_struc

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

	irqmac 1
	irqmac 3
	irqmac 4
	irqmac 5
	irqmac 6
	irqmac 7
	irqmac 8
	irqmac 9
	irqmac 10
	irqmac 11
	irqmac 12
	irqmac 13
	irqmac 14
	irqmac 15

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EnableIrq
;
;		description:	Enable IRQ in PIC controller
;
;		PARAMETERS:		AL			irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_irq  Proc far
    push ax
    push cx
;    
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
    pop cx
    pop ax
    ret
enable_irq  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DisableIrq
;
;		description:	Disable IRQ in PIC controller
;
;		PARAMETERS:		AL			irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_irq  Proc far
    push ax
    push cx    
;
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
    pop cx
    pop ax
    ret
disable_irq Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EnableIrqDetect
;
;		description:	Enable IRQ detect in PIC controller
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_irq_detect  Proc far
    push ax
;    
	xor al,al
	out 21h,al
	jmp short $+2
;	
    xor al,al
	out 0A1h,al
;
    pop ax
    ret
enable_irq_detect   Endp

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
	push ax
	push bx
	push dx
	push si
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
	call ds:[si].irq_enable_proc
;
	pop si
	pop dx
	pop bx
	pop ax
	pop ds
	ret
request_private_irq_handler	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SharedIrq
;
;		description:	Shared IRQ handler
;
;		PARAMETERS:     DS  Irq share struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shared_irq  Proc far
    mov cx,ds:share_count
    mov bx,OFFSET share_handler
    or cx,cx
    jz shared_irq_done

shared_irq_loop:
    push ds
    push bx
    push cx
;
	mov ax,ds:[bx].sh_user_data
	push cs
	push OFFSET shared_irq_next
	push ds:[bx].sh_user_handler
	mov ds,ax
	retf

shared_irq_next:
    pop cx
    pop bx
    pop ds
;    
    add bx,SIZE share_handle_struc
    loop shared_irq_loop

shared_irq_done:
    ret
shared_irq  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			request_shared_irq_handler
;
;		description:	Request for a shared irq handler
;
;		PARAMETERS:		ds			data for handler
;						al			irq nr
;						es:di		handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_shared_irq_handler_name DB 'Request Shared Irq Handler',0

request_shared_irq_handler	Proc far
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
	mov ax,cs
    cmp ax,word ptr ds:[si].user_handler+2
    jne rsih_req
;    	
    mov ax,word ptr ds:[si].user_handler
    cmp ax,OFFSET shared_irq
    je rsih_add

rsih_req:
    push ds
    push es
    push di
;    
    mov eax,SIZE share_struc
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor ax,ax
    rep stosb
;    
    mov ax,es
    mov ds,ax
    mov ax,cs
    mov es,ax
    mov al,bl
    mov di,OFFSET shared_irq
    RequestPrivateIrqHandler   
;
    pop di
    pop es
    pop ds

rsih_add:
    mov ds,ds:[si].user_data
    mov cx,ds:share_count
    mov ax,cx
    push dx
    mov dx,SIZE share_handle_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET share_handler
    mov word ptr ds:[bx].sh_user_handler,di
    mov word ptr ds:[bx].sh_user_handler+2,es
    mov ds:[bx].sh_user_data,dx
    inc cx
    mov ds:share_count,cx
;
	popa
	pop ds
	ret
request_shared_irq_handler	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			is_irq_free
;
;		description:	Check if IRQ can be reserved
;
;		PARAMETERS:		al			irq nr
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_irq_free_name DB 'Is Irq Free',0

is_irq_free	Proc far
	push ds
	push ax
	push si
;
	movzx si,al
	mov ax,irq_sys_sel
	mov ds,ax
	add si,si
	mov si,word ptr cs:[si].irq_offs_table
    mov ax,ds:[si].usage_section.cs_value
    or ax,ax
    clc
    jz is_irq_free_done
;
    stc

is_irq_free_done:
	pop si
	pop ax
	pop ds
	ret
is_irq_free	Endp

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
	push dx
;	
	movzx bx,al
	mov dx,irq_sys_sel
	mov ds,dx
	add bx,bx
	mov bx,word ptr cs:[bx].irq_offs_table
	call ds:[bx].irq_disable_proc
	LeaveSection ds:[bx].usage_section
;
    pop dx
	pop bx
	pop ax
	pop ds
	ret
release_private_irq_handler	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			setup_irq_detect
;
;		description:	Setup IRQ detect
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_irq_detect_name	DB 'Setup IRQ detect',0

setup_irq_detect	Proc far
	push ds
	push ax
;	
	mov ax,irq_sys_sel
	mov ds,ax
	mov ds:bad_irqs,0
;	
    call enable_irq_detect
;
    Swap
    Swap
;
    mov ds:bad_irqs,0    	
;
	pop ax
	pop ds
	ret
setup_irq_detect	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			poll_irq_detect
;
;		description:	Poll detected IRQs
;
;       RETURNS:        AX      Detected IRQs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_irq_detect_name	DB 'Poll IRQ detect',0

poll_irq_detect	Proc far
	push ds
;	
	mov ax,irq_sys_sel
	mov ds,ax
	mov ax,ds:bad_irqs
;
	pop ds
	ret
poll_irq_detect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PIC init
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
	mov bx,pic_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET is_irq_free
	mov di,OFFSET is_irq_free_name
	xor cl,cl
	mov ax,is_irq_free_nr
	RegisterOsGate
;
	mov si,OFFSET request_private_irq_handler
	mov di,OFFSET request_private_irq_handler_name
	xor cl,cl
	mov ax,request_private_irq_handler_nr
	RegisterOsGate
;
	mov si,OFFSET request_shared_irq_handler
	mov di,OFFSET request_shared_irq_handler_name
	xor cl,cl
	mov ax,request_shared_irq_handler_nr
	RegisterOsGate
;
	mov si,OFFSET release_private_irq_handler
	mov di,OFFSET release_private_irq_handler_name
	xor cl,cl
	mov ax,release_private_irq_handler_nr
	RegisterOsGate
;
	mov si,OFFSET setup_irq_detect
	mov di,OFFSET setup_irq_detect_name
	xor cl,cl
	mov ax,setup_irq_detect_nr
	RegisterOsGate
;
	mov si,OFFSET poll_irq_detect
	mov di,OFFSET poll_irq_detect_name
	xor cl,cl
	mov ax,poll_irq_detect_nr
	RegisterOsGate
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
	mov bx,irq_sys_sel
	mov ds,bx
;	
	mov cx,16
	mov bx,OFFSET irq_arr
	xor eax,eax

init_irq_loop:
	mov word ptr ds:[bx].irq_enable_proc,OFFSET enable_irq
	mov word ptr ds:[bx].irq_enable_proc+2,cs
;
	mov word ptr ds:[bx].irq_disable_proc,OFFSET disable_irq
	mov word ptr ds:[bx].irq_disable_proc+2,cs
;
	add bx,SIZE irq_struc
	loop init_irq_loop
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init

