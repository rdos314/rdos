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
; BITMODE.ASM
; PC based bitplane-mode support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME bitmode

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\driver.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\user.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\video.inc
INCLUDE pcvideo.inc

	.386p

video_object	STRUC

v_base		video_api_struc <>
v_buf_sel	DW ?
v_mem_sel	DW ?
v_mem_base	DD ?
v_has_focus	DB ?

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
	mov ax,pc_video_data_sel
	mov es,ax
	mov ax,es:v_curr_object
	or ax,ax
	jz switch_set_mode
;
	mov es,ax
	mov ax,es:v_mode
	cmp ax,ds:v_mode
	je switch_mode_done

switch_set_mode:
	push ds
	mov ax,ds:v_mode
	xor bx,bx
	mov ds,bx
	mov es,bx
	push 10h
	V86BiosInt
	pop ds

switch_mode_done:
	mov ax,pc_video_data_sel
	mov es,ax
	mov es:v_curr_object,ds
;
	EnterSection ds:v_section
	push ds
	mov ds:v_has_focus,1
	mov es,ds:v_mem_sel
	mov ds,ds:v_buf_sel
	xor edi,edi
	mov eax,77AA55AAh
	mov ecx,1000h
	rep stos dword ptr es:[edi]
	pop ds
	LeaveSection ds:v_section

switch_to_done:
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
	push es
	pushad
;
	EnterSection ds:v_section
	push ds
	mov ds:v_has_focus,0
	mov es,ds:v_buf_sel
	pop ds
	LeaveSection ds:v_section
;
	popad
	pop es
	ret
switch_from	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_mode12
;
;		DESCRIPTION:	Init video-mode 12
;
;		RETURNS:		AX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mode12	Proc far
	push ds
	push es
	push cx
	push si
	push di
;
	mov eax,SIZE video_object
	AllocateSmallGlobalMem
	mov cx,35
	mov ax,cs
	mov ds,ax
	mov si,OFFSET ModeTab
	xor di,di
	rep movsd
	push es
;
	mov eax,40000h
	AllocateGlobalMem
	xor eax,eax
	xor edi,edi
	mov ecx,10000h
	rep stos dword ptr es:[edi]
	int 3
;
	mov eax,10000h
	AllocateBigLinear
	AllocateGdt
	mov ecx,eax
	CreateDataSelector16
;
	pop ds
	mov ds:v_mode,12h
	mov ds:v_buf_sel,es
	mov ds:v_has_focus,0
	InitSection ds:v_section
	mov ds:v_mem_sel,bx
	mov ds:v_mem_base,edx
;
	mov cx,10h
	mov edx,0A0000h
	xor eax,eax

init_org_bit_loop:
	SetPhysicalPage
	add edx,1000h
	loop init_org_bit_loop
;
	mov cx,10h
	mov edx,ds:v_mem_base
	mov eax,0A0003h

init_alias_bit_loop:
	SetPhysicalPage
	add eax,1000h
	add edx,1000h
	loop init_alias_bit_loop
;
	mov eax,cr3
	mov cr3,eax
	mov ax,ds
	clc
;
	pop di
	pop si
	pop cx
	pop es
	pop ds
	ret
init_mode12	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_mode12
;
;		DESCRIPTION:	Delete video-mode 12
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_mode12	Proc far
	push ax
	push bx
	push ecx
	push edx
;
	mov edx,ds:v_mem_base
	xor eax,eax
	mov cx,10h

delete_bit_loop:
	SetPhysicalPage
	add edx,1000h
	loop delete_bit_loop
;
	mov es,ds:v_buf_sel
	FreeMem
	mov bx,ds:v_mem_sel
	FreeGdt
	mov edx,ds:v_mem_base
	mov ecx,10000h
	FreeLinear
	mov ax,ds
	mov es,ax
	xor ax,ax
	mov ds,ax
	FreeMem
;
	pop edx
	pop ecx
	pop bx
	pop ax
	ret
delete_mode12	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ModeTab
;
;		DESCRIPTION:	Dispatch table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error	Proc far
	stc
	ret
error	Endp

ModeTab:
mt00 DW OFFSET delete_mode12,	pc_video_code_sel
mt01 DW OFFSET switch_to,		pc_video_code_sel
mt02 DW OFFSET switch_from,		pc_video_code_sel
mt03 DW OFFSET error,			pc_video_code_sel
mt04 DW OFFSET error,			pc_video_code_sel
mt05 DW OFFSET error,			pc_video_code_sel
mt06 DW OFFSET error,			pc_video_code_sel
mt07 DW OFFSET error,			pc_video_code_sel
mt08 DW OFFSET error,			pc_video_code_sel
mt09 DW OFFSET error,			pc_video_code_sel
mt0A DW OFFSET error,			pc_video_code_sel
mt0B DW OFFSET error,			pc_video_code_sel
mt0C DW OFFSET error,			pc_video_code_sel
mt0D DW OFFSET error,			pc_video_code_sel
mt0E DW OFFSET error,			pc_video_code_sel
mt0F DW OFFSET error,			pc_video_code_sel
mt10 DW OFFSET error,			pc_video_code_sel
mt11 DW OFFSET error,			pc_video_code_sel
mt12 DW OFFSET error,			pc_video_code_sel
mt13 DW OFFSET error,			pc_video_code_sel
mt14 DW OFFSET error,			pc_video_code_sel
mt15 DW OFFSET error,			pc_video_code_sel
mt16 DW OFFSET error,			pc_video_code_sel
mt17 DW OFFSET error,			pc_video_code_sel
mt18 DW OFFSET error,			pc_video_code_sel
mt19 DW OFFSET error,			pc_video_code_sel
mt1A DW OFFSET error,			pc_video_code_sel
mt1B DW OFFSET error,			pc_video_code_sel
mt1C DW OFFSET error,			pc_video_code_sel
mt1D DW OFFSET error,			pc_video_code_sel
mt1E DW OFFSET error,			pc_video_code_sel
mt1F DW OFFSET error,			pc_video_code_sel
mt20 DW OFFSET error,			pc_video_code_sel
mt21 DW OFFSET error,			pc_video_code_sel
mt22 DW OFFSET error,			pc_video_code_sel

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_bit_mode
;
;		DESCRIPTION:	Init bit-mode support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_bit_mode

init_bit_mode	Proc near	
	mov ax,cs
	mov es,ax	
	mov ax,12h
	xor bl,bl
	mov cx,640
	mov dx,480
	mov di,OFFSET init_mode12
;	RegisterVideoMode
	ret
init_bit_mode	Endp

code	ENDS

	END

