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
; DIGIO.ASM
; Digital IO module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME digio

GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\wait.inc
INCLUDE ..\..\kernel\handle.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Delay
;
;		DESCRIPTION:	Delay until line settles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delay	Proc near
	push ax
	mov ax,10
	WaitMilliSec
	pop ax
	ret
Delay	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadDigitalLine
;
;		DESCRIPTION:	Read digital input line
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;
;		RETURNS:		AL		State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_digital_line_name	DB 'Read Digital Line', 0

read_digital_line	Proc far
	push dx
;
	and dl,7
	and dh,0Fh
	mov al,dl
	shl dh,3
	or al,dh
	mov dx,288h
	out dx,al
;
	call Delay
;
	or al,80h
	out dx,al
;
	call Delay
;
	mov dx,28Ah
	in al,dx
	and al,1
;
	call Delay
;
	push ax
	mov dx,288h
	xor al,al
	out dx,al
	pop ax
;
	call Delay
;
	pop dx
	retf32
read_digital_line	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ToggleDigitalLine
;
;		DESCRIPTION:	Toggle digital input line
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_digital_line_name	DB 'Toggle Digital Line', 0

toggle_tab:
	db 010b
	db 100b
	db 001b
	db 100b
	db 001b
	db 010b

toggle_digital_line	Proc far
	push bx
	push dx
;
	and dl,7
	and dh,0Fh
	mov al,dl
	shl dh,3
	or al,dh
	mov dx,288h
	out dx,al
;
	call Delay
;
	or al,80h
	out dx,al
;
	call Delay
;
	mov cx,6
	mov bx,OFFSET toggle_tab

toggle_loop:
	xor al,cs:[bx]
	out dx,al
;
	call Delay
;
	inc bx
	loop toggle_loop
;
	xor al,al
	out dx,al
	call Delay
;
	pop dx
	pop bx
	retf32
toggle_digital_line	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:	Initialize module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
;
	mov bx,digio_code_sel
	InitDevice
;
    mov dx,28Bh
    mov al,8Bh
    out dx,al
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET read_digital_line
	mov di,OFFSET read_digital_line_name
	mov ax,read_digital_line_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET toggle_digital_line
	mov di,OFFSET toggle_digital_line_name
	mov ax,toggle_digital_line_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
