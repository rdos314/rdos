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

