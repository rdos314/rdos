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
; ANIO.ASM
; Analog IO power-management module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME anio

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\os.inc
INCLUDE ..\os\user.inc
INCLUDE ..\os\driver.def
INCLUDE ..\os\system.inc

	.386p

WriteZflByte    Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov al,data
    inc dx
    out dx,al
                Endm

ReadZflByte Macro index
    mov al,index
    mov dx,218h
    out dx,al
    inc dx
    in al,dx
            Endm

WriteZflWord    Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov ax,data
    mov dx,21Ah
    out dx,ax
                Endm

ReadZflWord Macro index
    mov al,index
    mov dx,218h
    out dx,al
    mov dx,21Ah
    in ax,dx
            Endm

WriteZflDword   Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov eax,data
    mov dx,21Ah
    out dx,eax
                Endm

ReadZflDword    Macro index
    mov al,index
    mov dx,218h
    out dx,al
    mov dx,21Ah
    in eax,dx
                Endm  

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadAD
;
;		DESCRIPTION:	Do an AD conversion
;
;		PARAMETERS:		AX		Channel #
;
;		RETURNS:		EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_ad_name	DB 'ReadAD', 0

read_ad	Proc far
	push bx
	push dx
;
	mov bx,ax
;
	mov dx,28Fh
	in al,dx
;
	mov dx,282h
	mov al,bl
	shl al,4
	or al,bl
	out dx,al
;
	inc dx
	mov al,0
	out dx,al

read_ad_settle:
	in al,dx
	test al,20h
	jnz read_ad_settle
;
	mov dx,280h
	mov al,80h
	out dx,al
;
	mov dx,283h

read_ad_wait:
	in al,dx
	test al,80h
	jnz read_ad_wait
;
	mov dx,280h
	in al,dx
	mov ah,al
	inc dx
	in al,dx
	xchg al,ah
	movsx eax,ax
;
	pop dx
	pop bx
	retf32
read_ad	Endp

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
	mov bx,anio_code_sel
	InitDevice
;
	WriteZflWord 20h, 280h
	WriteZflByte 22h, 1Fh
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET read_ad
	mov di,OFFSET read_ad_name
	mov ax,read_ad_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
