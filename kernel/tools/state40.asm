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
; STATE40.ASM
; Thread state display app. Works on 40 column displays
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME stateapp

GateSize = 16

INCLUDE ..\os\state.def
INCLUDE ..\os\user.def
INCLUDE ..\os\user.inc

.model small

.stack
.data

Work	DB 1000h DUP(?)

TempStr	DB 100 DUP(?)

RowId	DW 25 DUP(?)

.code

.386p

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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			single_hex
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AL		Value
;
;		RETURNS:		AX		Hex value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

singel_hex	PROC near
hex_conv_low:
	mov ah,al
	and al,0F0h
	rol al,1
	rol al,1
	rol al,1
	rol al,1
	cmp al,0Ah
	jb ok_low1
	add al,7
ok_low1:
	add al,30h
	and ah,0Fh
	cmp ah,0Ah
	jb ok_high1
	add ah,7
ok_high1:
	add ah,30h
	ret
singel_hex	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexByte
;
;		DESCRIPTION:	Write hex byte
;
;		PARAMETERS:		AL		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_hex_byte	PROC near
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
write_hex_byte	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_hex_word
;
;		DESCRIPTION:	Write hex word
;
;		PARAMETERS:		AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_hex_word	PROC near
	push ax
	rol ax,8
	call write_hex_byte
	rol ax,8
	call write_hex_byte
	pop ax
	ret
write_hex_word	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_hex_dword
;
;		DESCRIPTION:	Write hex dword
;
;		PARAMETERS:		EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_hex_dword	PROC near
	push eax
	rol eax,8
	call write_hex_byte
	rol eax,8
	call write_hex_byte
	rol eax,8
	call write_hex_byte
	rol eax,8
	call write_hex_byte
	pop eax
	ret
write_hex_dword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_hex_address
;
;		DESCRIPTION:	Write hex address
;
;		PARAMETERS:		BX:EAX		Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_hex_address	PROC near
	push ax
	mov ax,bx
	rol ax,8
	call write_hex_byte
	rol ax,8
	call write_hex_byte
	mov al,':'
	WriteChar
	pop ax
	push eax
	rol eax,8
	call write_hex_byte
	rol eax,8
	call write_hex_byte
	rol eax,8
	call write_hex_byte
	rol eax,8
	call write_hex_byte
	pop eax
	ret
write_hex_address	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_time
;
;		DESCRIPTION:	Write time
;
;		PARAMETERS:		EDX:EAX		Binary time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_time	Proc near
	pushad
	mov di,OFFSET TempStr
	push eax
	mov eax,edx
	xor edx,edx
	mov ecx,24
	div ecx
	mov cx,3
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
write_time	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			dump_thread
;
;		DESCRIPTION:	Dump a thread
;
;		PARAMETERS:		ES:DI		Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


unknown_state_str   DB 'Unkn'
debug_state_str     DB 'Debu'

first_part_str  DB ' -- ', 0
last_part_str   DB ' -- ', 0

dump_thread	Proc near
	pusha
;
	push di
	add di,OFFSET st_name
	mov cx,12
	WriteSizeString
	pop di
;
    mov eax,dword ptr es:[di].st_list
    cmp eax,dword ptr cs:unknown_state_str
    je dump_address
;
    cmp eax,dword ptr cs:debug_state_str
    je dump_address
;
	mov edx,es:[di].st_time
	mov eax,es:[di].st_time+4
	call write_time
	mov al,' '
	WriteChar
	jmp dump_state

dump_address:	
    push es
    push di
    mov di,OFFSET first_part_str
    mov ax,cs
    mov es,ax
    WriteAsciiz
    pop di
    pop es
;
	mov eax,es:[di].st_offs
	mov bx,es:[di].st_sel
	call write_hex_address
;
    push es
    push di
    mov di,OFFSET last_part_str
    mov ax,cs
    mov es,ax
    WriteAsciiz
    pop di
    pop es

dump_state:
	push di
	add di,OFFSET st_list
	mov cx,10
	WriteSizeString
	pop di
;
	mov al,13
	WriteChar
	mov al,10
	WriteChar
;
	popa
	ret
dump_thread	Endp

state2_name DB 'State 2',0
state3_name DB 'State 3',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Dump
;
;		DESCRIPTION:	Dump all threads
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

blank_row DB '                                        ',0

Dump	Proc near
	push es
	pusha
	GetCursorPosition
	push cx
	push dx
	xor si,si
	xor dx,dx
	xor cx,cx
	SetCursorPosition
	xor ax,ax
state_thread_loop:
	GetState
	jc state_thread_next
;
	mov [si].RowId,ax
	add si,2
	call dump_thread
	
state_thread_next:
    cmp si,2 * 16
    je state_pad_done
;
	inc ax
	cmp ax,256
	jne state_thread_loop	
;
	shr si,1
state_pad_loop:
	cmp si,16
	je state_pad_done
;
	inc si
	mov ax,cs
	mov es,ax
	mov edi,OFFSET blank_row
	mov ecx,40
	WriteSizeString
;
	mov al,13
	WriteChar
	mov al,10
	WriteChar
;	jmp state_pad_loop

state_pad_done:
	pop dx
	pop cx
	SetCursorPosition
	popa
	pop es
	ret
Dump	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DoFunc
;
;		DESCRIPTION:	Do a function
;
;		PARAMETERS:		AL		key
;						CX		x position
;						DX		y position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoFunc	Proc near
	push cx
	push dx
	shr cx,3
	shr dx,3
	cmp al,0Dh
	jne do_func_end
	mov bx,dx
	shl bx,1
	mov ax,[bx].RowId
	Pause
do_func_end:
	pop dx
	pop cx
	ret
DoFunc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleKeyboard
;
;		DESCRIPTION:	Keyboard
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleKeyboard	Proc near
	mov eax,25
	WaitMilliSec
;
	PollKeyboard
	jc handle_key_end
;
	ReadKeyboard
	or al,al
	jz handle_key_special
	GetMousePosition
	call DoFunc
	jmp handle_key_end

handle_key_special:  
	cmp ah,72
	jnz no_up_arrow

up_arrow:
	GetMousePosition
	sub dx,8
	SetMousePosition
	jmp handle_key_end

no_up_arrow:
	cmp ah,80
	jnz no_down_arrow

down_arrow:
	GetMousePosition
	add dx,8
	SetMousePosition
	jmp handle_key_end

no_down_arrow:
	cmp ah,75
	jnz no_left_arrow

left_arrow:
	GetMousePosition
	sub cx,8
	SetMousePosition
	jmp handle_key_end

no_left_arrow:
	cmp ah,77
	jnz handle_key_end

right_arrow:
	GetMousePosition
	add cx,8
	SetMousePosition

handle_key_end:
	GetMousePosition
	shr cx,3
	shr dx,3
	SetCursorPosition
	ret
HandleKeyboard	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleMouse
;
;		DESCRIPTION:	Mouse handler
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMouse	Proc near
	GetLeftButton
	jc handle_not_left

left_button:
	GetLeftButtonPressPosition
	mov al,'+'
	call DoFunc
left_rel_loop:
	call HandleKeyboard
	GetLeftButton
	jnc left_rel_loop

handle_not_left:
	GetRightButton
	jc handle_mouse_done

right_button:
	GetRightButtonPressPosition
	mov al,'-'
	call DoFunc
right_rel_loop:
	call HandleKeyboard
	GetRightButton
	jnc right_rel_loop
handle_mouse_done:
	ret
HandleMouse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:	Startup procedure
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
	xor ax,ax
	xor bx,bx
	mov cx,239
	mov dx,127
	SetMouseWindow
	mov cx,6
	mov dx,8
	SetMouseMickey
;	
;	ShowMouse
state_start:
	mov ax,_data
	mov ds,ax
	mov es,ax
state_loop:
	mov ax,100
	WaitMilliSec
	call HandleKeyboard
	call HandleMouse
	call Dump
	jmp state_loop

	END init
