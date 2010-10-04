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
; DEBUGIO.ASM
; User interface for kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME debugio

GateSize = 16

INCLUDE kdebug.def
INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc

code	SEGMENT byte public 'CODE'

.386p

	extrn debug_call_pr:near

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DoFunc
;
;		DESCRIPTION:	Do function
;
;		PARAMETERS:		CX		X
;						DX		Y
;						AL		CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoFunc	PROC near
	HideMouse
	push ax
	mov ax,cx
	mov cl,6
	div cl
	movzx cx,al
	pop ax
	shr dx,3
	mov dh,dl
	mov dl,cl
	call debug_call_pr
	mov al,'r'
	call debug_call_pr
	mov al,dl
	movzx dx,dh
	mov ah,6
	mul ah
	mov cx,ax
	shl dx,3
	SetMousePosition
	ShowMouse
	ret
DoFunc	ENDP

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
	sub cx,6
	SetMousePosition
	jmp handle_key_end

no_left_arrow:
	cmp ah,77
	jnz handle_key_end

right_arrow:
	GetMousePosition
	add cx,6
	SetMousePosition

handle_key_end:
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
;		NAME:			MARKER
;
;		DESCRIPTION:	ANROP AV MARK™R
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


debug_name		DB 'Debug',0

debug_process:
	sti
	mov ax,42h
	EnableFocus
	mov ax,250
	WaitMilliSec
	xor ax,ax
	xor bx,bx
	mov cx,239
	mov dx,127
	SetMouseWindow
	mov cx,6
	mov dx,8
	SetMouseMickey
;	
	ShowMouse
marker_loop:
	call HandleKeyboard
	call HandleMouse
	jmp marker_loop

init_debug_process	PROC far
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET debug_process
	mov di,OFFSET debug_name
	mov ecx,512
	mov ax,26
	CreateProcess
	popa
	pop es
	pop ds
	ret
init_debug_process	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			free_thread
;
;		DESCRIPTION:	Free thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread	Proc far
	GetThread
	mov bx,ax
	mov ax,kdebug_sys_sel
	mov ds,ax
	mov ax,ds:debug_thread
	cmp ax,bx
	jne free_thread_done
;
	mov ax,system_data_sel
	mov ds,ax
	mov si,OFFSET debug_list
	mov bx,[si]
	mov ax,kdebug_sys_sel
	mov ds,ax
	mov ds:debug_thread,bx

free_thread_done:
	ret
free_thread	Endp

init	PROC far
	push ds
	push es
	pusha
	mov bx,kdebug_code_sel
	InitDevice
;
	mov ax,cs
	mov es,ax
;
	mov di,OFFSET init_debug_process
	HookInitTasking
;
	mov di,OFFSET free_thread
	HookTerminateThread
;
	mov bx,kdebug_sys_sel
	mov eax,OFFSET debug_data_size
	AllocateFixedSystemMem
	mov es:data_good,0
	mov es:debug_thread,0
	mov es:mouse_pos,0
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init
