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

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartKeyboard
;
;		DESCRIPTION:	start keyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_keyboard_name	DB 'Start Keyboard', 0

start_keyboard	Proc far
    WriteSIO 7, 6
    WriteSIO 30h, 1
    WriteSIO 60h, 0
    WriteSIO 61h, 60h
    WriteSIO 62h, 0
    WriteSIO 63h, 64h
    WriteSIO 70h, 1
    WriteSIO 71h, 2
;
	cli
	mov al,0EDh
	out 60h,al

send_wait1:
	in al,64h
	test al,2
	jnz send_wait1
;
	mov al,6
	out 60h,al

send_wait2:
	in al,64h
	test al,2
	jnz send_wait2

wait_key:
	in al,64h
	test al,1
	jz wait_key
;
	in al,60h
	mov ah,al
	in al,64h
	mov si,ax
;
	in al,21h
	mov ah,al
	in al,20h
	mov di,ax
;	
	int 3
	ret
start_keyboard	Endp


PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopKeyboard
;
;		DESCRIPTION:	stop keyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_keyboard_name	DB 'Stop Keyboard', 0

stop_keyboard	Proc far
    WriteSIO 7, 6
    WriteSIO 30h, 0
	ret
stop_keyboard	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartFloppy
;
;		DESCRIPTION:	start floppy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_floppy_name	DB 'Start Floppy', 0

start_floppy	Proc far
    WriteSIO 7, 0
    WriteSIO 30h, 1
    WriteSIO 60h, 3
    WriteSIO 61h, 0F0h
    WriteSIO 70h, 6
    WriteSIO 71h, 3
	WriteSIO 74h, 2
	WriteSIO 75h, 4
	WriteSIO 0F0h, 24h
	WriteSIO 0F1h, 0
	ret
start_floppy	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopFloppy
;
;		DESCRIPTION:	stop floppy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_floppy_name	DB 'Stop Floppy', 0

stop_floppy	Proc far
    WriteSIO 7, 0
    WriteSIO 30h, 0
	ret
stop_floppy	Endp

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
	mov si,OFFSET start_keyboard
	mov di,OFFSET start_keyboard_name
	mov ax,start_keyboard_nr
	RegisterOsGate
;
	mov si,OFFSET stop_keyboard
	mov di,OFFSET stop_keyboard_name
	mov ax,stop_keyboard_nr
	RegisterOsGate
;
	mov si,OFFSET start_floppy
	mov di,OFFSET start_floppy_name
	mov ax,start_floppy_nr
	RegisterOsGate
;
	mov si,OFFSET stop_floppy
	mov di,OFFSET stop_floppy_name
	mov ax,stop_floppy_nr
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
