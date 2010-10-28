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
; NOVIDEO.ASM
; Dummy video driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\video.inc

	.386p

DEF_WIDTH = 640
DEF_HEIGHT = 480

video_object	STRUC

v_base		        video_api_struc <>
vl_has_focus        DB ?

video_object	ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			switch_to
;
;		DESCRIPTION:	Enter focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_to	Proc far
    push es
	pushad
;
;	EnterSection ds:v_section
	mov ds:vl_has_focus,1
;	LeaveSection ds:v_section
;
	popad
	pop es
	ret
switch_to	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SwitchFrom
;
;		DESCRIPTION:	Leave focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_from	Proc far
	mov ds:vl_has_focus,0
	ret
switch_from	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_mode
;
;		DESCRIPTION:	Init video-mode
;
;		RETURNS:		AX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mode	Proc far
	push ds
	push es
	push ecx
	push dx
	push si
	push edi
;
	mov ax,es
	mov ds,ax
	mov ax,DEF_HEIGHT
	shl ax,2
	add ax,SIZE video_object
	movzx eax,ax
	AllocateSmallGlobalMem
    mov es:v_sprite_lines,SIZE video_object
;
	mov al,1
	mov cx,DEF_WIDTH
	mov dx,DEF_HEIGHT
	InitVideoBitmap
;
	mov es:v_mode,3
	mov es:vl_has_focus,0
;
	mov eax,DEF_WIDTH / 8
	mov es:v_row_size,ax
;
	mov edx,DEF_HEIGHT
	mul edx
	dec eax
	and ax,0F000h
	add eax,1000h
	mov es:v_app_size,eax
	AllocateSmallLinear
	mov es:v_app_base,edx
;
	push es
	mov edi,edx
	mov ecx,eax
	mov ax,flat_sel
	mov es,ax
	xor al,al
	rep stos byte ptr es:[edi]
	pop es
;
    mov bx,cs
    shl ebx,16
;
    mov bx,OFFSET switch_to
    mov es:switch_to_proc,ebx
;
    mov bx,OFFSET switch_from
    mov es:switch_from_proc,ebx
	mov ax,es
	clc
;
	pop edi
	pop si
	pop dx
	pop ecx
	pop es
	pop ds
	ret
init_mode	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_focus
;
;		DESCRIPTION:	Init focus
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
init_focus	PROC far
    push es
	pusha
;    
	mov ax,3
	SetVideoMode
;
	popa
	pop es
	ret
init_focus	Endp

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
	push ds
	pusha
;
	mov bx,vga_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_focus
	HookEnableFocus
;
	mov ax,cs
	mov es,ax	
	mov ax,3
	mov bl,1
	mov cx,DEF_WIDTH
    mov dx,DEF_HEIGHT
	mov di,OFFSET init_mode
	RegisterVideoMode
;
	popa
	pop ds
	ret
init	ENDP

code	ENDS

	END init

