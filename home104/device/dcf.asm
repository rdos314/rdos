;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; DCF.ASM
; DCF77 device driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME dcf

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\os.inc
INCLUDE ..\os\user.inc
INCLUDE ..\os\driver.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\wait.inc
INCLUDE ..\os\handle.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexByte
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AL		Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte	PROC near
	push ax
	mov ah,al
	and al,0F0h
	rol al,4
	cmp al,0Ah
	jb write_byte_low1
	add al,7
write_byte_low1:
	add al,'0'
	WriteChar
	mov al,ah
	and al,0Fh
	cmp al,0Ah
	jb write_byte_high1
	add al,7
write_byte_high1:
	add al,'0'
	WriteChar
	pop ax
	ret
WriteHexByte	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexWord
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AX		Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord	PROC near
	xchg al,ah
	call WriteHexByte
	xchg al,ah
	call WriteHexByte
	ret
WriteHexWord	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexDword
;
;		DESCRIPTION:	
;
;		PARAMETERS:		EAX		Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword	PROC near
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	ret
WriteHexDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IntToStr
;
;		DESCRIPTION:	Convert long to asciiz string
;
;		PARAMETERS:		EAX			Value
;						CX			Number of position
;						ES:DI		String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_tab:
	DD 1
	DD 10
	DD 100
	DD 1000
	DD 10000
	DD 100000
	DD 1000000
	DD 10000000
	DD 100000000
	DD 1000000000

IntToStr	PROC near
	push ax
	push bx
	push ecx
	push edx
	push di
	mov edx,eax
	mov ah,cl
	mov bx,cx
	dec bx
	shl bx,2
loop_omv_dec:
	mov ecx,dword ptr cs:[bx].dec_tab
	xor al,al
loop_dec_dig:
	inc al
	sub edx,ecx
	jnc loop_dec_dig
	add edx,ecx
	dec al
	sub bx,4
	add al,'0'
	stosb
	dec ah
	jne loop_omv_dec
	xor al,al
	stosb
	pop di
	pop edx
	pop ecx
	pop bx
	pop ax
	ret
IntToStr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemoveLeading
;
;		DESCRIPTION:	Remove leading zeros
;
;		PARAMETERS:		ES:DI		STRING
;
;		RETURNS:		CY		Significant digits found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveLeading	Proc near
	push ax
	push di
RemoveLeadingLoop:
	mov al,es:[di]
	or al,al
	clc
	jz RemoveLeadingDone
	cmp al,'0'
	stc
	jnz RemoveLeadingDone
	mov byte ptr es:[di],' '
	inc di
	jmp RemoveLeadingLoop
RemoveLeadingDone:
	pop di
	pop ax
	ret
RemoveLeading	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteTime
;
;		DESCRIPTION:	Write time
;
;		PARAMETERS:		EDX:EAX		Binary time
;						ES			Temp storage
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTime	Proc near
	pushad
	xor di,di
	push eax
	mov eax,edx
	xor edx,edx
	mov ecx,24
	div ecx
	mov cx,8
	call IntToStr
	call RemoveLeading
	pushf
	WriteAsciiz
	mov al,' '
	WriteChar
	mov eax,edx
	mov cx,2
	call IntToStr
	mov al,'.'
	popf
	jc SignHour
	call RemoveLeading
	jc SignHour
	mov al,' '
SignHour:
	pushf
	WriteAsciiz
	WriteChar
	popf
	pop eax
;
	pushf
	mov edx,60
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov cx,2
	call IntToStr
	mov al,'.'
	popf
	jc MinSign
	call RemoveLeading
	jc MinSign
	mov al,' '
MinSign:
	pushf
	WriteAsciiz
	WriteChar
	popf
	pop eax
;
	pushf
	mov edx,60
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov cx,2
	call IntToStr
	mov al,','
	popf
	jc SecSign
	call RemoveLeading
	jc SecSign
	mov al,' '
SecSign:
	pushf
	WriteAsciiz
	WriteChar
	popf
	pop eax
;
	pushf
	mov edx,1000
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov cx,3
	call IntToStr
	mov al,' '
	popf
	jc MilliSign
	call RemoveLeading
MilliSign:
	pushf
	WriteAsciiz
	WriteChar
	popf
	pop eax
;
	pushf
	mov edx,1000
	mul edx
	mov eax,edx
	mov cx,3
	call IntToStr
	popf
	jc MikroSign
	call RemoveLeading
MikroSign:
	WriteAsciiz
	popad
	ret
WriteTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			start_timer
;
;		DESCRIPTION:	Start timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_timer   Proc near
    mov dx,28Fh
    mov al,8
    out dx,al
;
    mov dx,28Ch
    mov al,80h
    out dx,al
;
    inc dx
    mov al,96h
    out dx,al
;
    inc dx
    mov al,98h
    out dx,al
    inc dx
;
	mov al,2
	out dx,al
;
	mov al,10h
	out dx,al
;
	mov al,4
	out dx,al	
;
    ret
start_timer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_timer
;
;		DESCRIPTION:	Read timer
;
;		RETURNS:		EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_timer   Proc near
	push ecx
	push dx
;
    mov dx,28Fh
    mov al,40h
    out dx,al
;
    xor ecx,ecx
;
    dec dx
    in al,dx
    mov cl,al
;
    shl ecx,8
    dec dx
    in al,dx
    mov cl,al
;
    shl ecx,8
    dec dx
    in al,dx
    mov cl,al
;
    mov eax,ecx
	pop dx
	pop ecx
    ret
read_timer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			dcf_thread
;
;		DESCRIPTION:	DCF thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dcf_thread_name		DB 'DCF',0

dcf_thread:
	sti
	mov ax,43h
	EnableFocus
;
    mov eax,16
    AllocateSmallMem

dcf_thread_loop:
	mov ax,50
	WaitMilliSec
;
	mov dx,28Ah
	in al,dx
	and al,10h
	jz dcf_thread_loop
;
	call start_timer
	call read_timer
	mov esi,eax

dcf_wait_loop:
	mov ax,50
	WaitMilliSec
;
	mov dx,28Ah
	in al,dx
	and al,10h
	jnz dcf_wait_loop	
;
    cli	
	call read_timer
	mov edi,989680h
	sub edi,eax
	GetSystemTime
    sti
;
    push edx
    push eax
;
    mov eax,edi
    mov ecx,1193046
    mul ecx
    mov ecx,10000000
    div ecx
    mov ecx,eax
;
    pop eax
    add eax,ecx
    pop edx
    adc edx,0
;
    push eax
    push edx
;
	xor cx,cx
	xor dx,dx
	SetCursorPosition
;
	pop edx
	pop eax
	call WriteTime
	
dcf_meassure_loop:
	mov ax,50
	WaitMilliSec
;
	mov dx,28Ah
	in al,dx
	and al,10h
	jz dcf_meassure_loop
;
	call read_timer	
	mov esi,eax
;
	xor cx,cx
	mov dx,1
	SetCursorPosition
;
	mov eax,esi
	push eax
	call WriteHexDword
	pop eax
;
    xor di,di
    push eax
    mov cx,10
    call IntToStr
    call RemoveLeading
    pop eax
;
	xor cx,cx
	mov dx,2
	SetCursorPosition
;
	WriteAsciiz
;
    mov ecx,1193046
    mul ecx
    mov ecx,10000000
    div ecx
;
    xor di,di
    push eax
    mov cx,10
    call IntToStr
    call RemoveLeading
    pop eax
;
	xor cx,cx
	mov dx,3
	SetCursorPosition
;
	WriteAsciiz
	jmp dcf_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_dcf_thread
;
;		DESCRIPTION:	Init DCF thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dcf_thread	PROC far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET dcf_thread
	mov di,OFFSET dcf_thread_name
	mov ecx,512
	mov ax,25
	CreateProcess
;
	popa
	pop es
	pop ds
	ret
init_dcf_thread	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			dcf_int
;
;		DESCRIPTION:	DCF interrupt
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dcf_int	Proc far
	mov dx,280h
	mov al,2
	out dx,al
	ret
dcf_int	Endp

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
	mov bx,dcf_code_sel
	InitDevice
;
    mov dx,284h
    mov al,2
    out dx,al
;
    mov dx,28Bh
    mov al,9Bh
    out dx,al
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov al,5
	mov cx,cs
	mov es,cx
	mov di,OFFSET dcf_int
	RequestPrivateIrqHandler
;
	mov di,OFFSET init_dcf_thread
	HookInitTasking
;
	popa
	pop es
	pop ds
	ret
init	Endp

code    ENDS

	END init
