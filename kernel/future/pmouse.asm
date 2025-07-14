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
; PMOUSE.ASM
; Logitech mouse-card device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IRQ = 5
IO_BASE = 238h

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc

	.386p

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
	mov dx,IO_BASE+6
	mov al,80h 
	out dx,al 
	jmp short $+2
;
	mov dx,IO_BASE+4
	in al,dx 
	and al,0Fh 
	mov cl,al 
;
	mov dx,IO_BASE+6
	mov al,0A0h 
	out dx,al 
	jmp short $+2
;
	mov dx,IO_BASE+4
	in al,dx 
	shl al,4
	or cl,al
;
	mov dx,IO_BASE+6
	mov al,0C0h 
	out dx,al 
	jmp short $+2
;
	mov dx,IO_BASE+4
	in al,dx 
	and al,0Fh 
	mov ch,al
;
	mov dx,IO_BASE+6
	mov al,0E0h 
	out dx,al 
	jmp short $+2
;
	mov dx,IO_BASE+4
	in al,dx 
	shl al,4
	or ch,al
;
	mov dx,IO_BASE+6
	xor ax,ax
	out dx,al
	jmp short $+2
;
	or cx,cx
	jz mus_not_moved
;
	xor ax,ax
	movzx dx,ch
	movzx cx,cl
	UpdateMouse

mus_not_moved:
	ret
mus_int	endp

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
	xor bx,bx
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET mus_int
	mov al,IRQ
	int 3
	RequestPrivateIrqHandler
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
;		DESCRIPTION:	Init device
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

