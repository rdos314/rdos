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
; S1MOUSE.ASM
; Support for serial mouse on COM1:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME s1mouse

IRQ = 4
IO_BASE = 3F8h

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\driver.def
INCLUDE ..\os\user.def
INCLUDE ..\os\virt.def
INCLUDE ..\os\os.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\virt.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\system.inc

	.386p

mouse_data_seg	SEGMENT AT 0

md_buttons		DB ?
md_dx			DB ?
md_dy			DB ?
md_pos			DW ?

mouse_data_seg	ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			mus_int
;
;		DESCRIPTION:	int handler
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mus_int	proc far
	mov dx,IO_BASE
	in al,dx
	mov bx,ds:md_pos
	test al,40h
	jz mus_int_coord
	xor bx,bx
mus_int_coord:
	mov [bx],al
	inc bx
	mov ds:md_pos,bx
	cmp bx,3
	jne mus_not_moved
	mov cl,ds:md_dx
	and cl,3Fh
	test cl,20h
	jz mus_x_pos
	or cl,0C0h
mus_x_pos:
	mov ch,ds:md_dy	
	and ch,3Fh
	test ch,20h
	jz mus_y_pos
	or ch,0C0h
mus_y_pos:
	or cx,cx
	jz mus_not_moved
;
	movzx ax,ds:md_buttons
	movzx cx,cl
	movzx dx,ch
	UpdateMouse

mus_not_moved:
	ret
mus_int	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_MOUSE
;
;		DESCRIPTION:	Init mouse
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mouse_name	DB 'Init Mouse', 0

init_mouse	Proc far
	push ds
	push es
;
	mov al,IRQ
	mov bx,mousedev_data_sel
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET mus_int
	RequestPrivateIrqHandler
;
	mov dx,IO_BASE+3
	mov al,83h
	out dx,al				; set line control to divisor access
;
	mov dx,IO_BASE
	mov al,96
	out dx,al				; output LSB divisor latch
;
	mov dx,IO_BASE+1
	mov al,0
	out dx,al				; output MSB divisor latch
;
	mov dx,IO_BASE+3
	mov al,2
	out dx,al				; set line control to 7 bits, 1 stop and no parity
;
	mov dx,IO_BASE+1
	mov al,1
	out dx,al				; enable rx ints, disable tx, line and modem ints
;
	mov dx,IO_BASE+4
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
;
	pop es
	pop ds
	ret
init_mouse	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init mouse device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	pusha
	push ds
;
	mov bx,mousedev_code_sel
	InitDevice
;
	mov eax,SIZE mouse_data_seg
	mov bx,mousedev_data_sel
	AllocateFixedSystemMem
	mov es:md_pos,0
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET init_mouse
	mov di,OFFSET init_mouse_name
	xor cl,cl
	mov ax,init_mouse_nr
	RegisterOsGate
;
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init

