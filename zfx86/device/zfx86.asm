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
; ZFX86.ASM
; ZFX86 power-management module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME zfx86

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\os.inc
INCLUDE ..\os\user.inc
INCLUDE ..\os\driver.def

	.386p

WriteSIO    Macro index, data
    mov al,index
    out 2Eh,al
    mov al,data
    out 2Fh,al
        ENDM

ReadSIO    Macro index
    mov al,index
    out 2Eh,al
    in al,2Fh
        ENDM

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartComPort
;
;		DESCRIPTION:	start serial port
;
;		PARAMETERS:		AX		port #
;						DX		base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_com_port_name	DB 'Start Com Port', 0

start_com_port	Proc far
	push ax
	push dx
;
	cmp dx,3F8h
	je start_com1
;
	cmp dx,2F8h
	je start_com2
;
	jmp start_com_done

start_com1:
    WriteSIO 7, 3
    WriteSIO 30h, 1
    WriteSIO 60h, dh
    WriteSIO 61h, dl
	jmp start_com_done

start_com2:
    WriteSIO 7, 2
    WriteSIO 30h, 1
    WriteSIO 60h, dh
    WriteSIO 61h, dl

start_com_done:
	pop dx
	pop ax
	ret
start_com_port	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopComPort
;
;		DESCRIPTION:	stop serial port
;
;		PARAMETERS:		AX		port #
;						DX		base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_com_port_name	DB 'Stop Com Port', 0

stop_com_port	Proc far
	push ax
	push dx
;
	cmp dx,3F8h
	je stop_com1
;
	cmp dx,2F8h
	je stop_com2
;
	jmp stop_com_done

stop_com1:
    WriteSIO 7, 3
    WriteSIO 30h, 0
	jmp stop_com_done

stop_com2:
    WriteSIO 7, 2
    WriteSIO 30h, 0

stop_com_done:
	pop dx
	pop ax
	ret
stop_com_port	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_test
;
;		DESCRIPTION:    init test
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


thread1_name    DB 'Thread 1',0

thread1:
	int 3
	finit
	fldln2
	fldpi
;
    xor cx,cx
tl1:
    loop tl1
    int 3
	fmul st(1),st(0)
	retf

thread2_name    DB 'Thread 2',0

thread2:
    int 3
    finit
    fldpi
    fld1
;
    xor cx,cx
tl2:
    loop tl2
    int 3
    fadd st(1),st(0)
    retf

init_test	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET thread1
	mov di,OFFSET thread1_name
	mov ax,3
	mov cx,256
	CreateThread
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET thread2
	mov di,OFFSET thread2_name
	mov ax,3
	mov cx,256
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_test	Endp

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
	mov bx,power_code_sel
	InitDevice
;
	mov di,OFFSET init_test
	HookInitTasking
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET start_com_port
	mov di,OFFSET start_com_port_name
	mov ax,start_com_port_nr
	RegisterOsGate
;
	mov si,OFFSET stop_com_port
	mov di,OFFSET stop_com_port_name
	mov ax,stop_com_port_nr
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
