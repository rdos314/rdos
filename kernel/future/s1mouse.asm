;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; S1MOUSE.ASM
; Support for serial mouse on COM1:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IRQ = 4
IO_BASE = 3F8h

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc

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

