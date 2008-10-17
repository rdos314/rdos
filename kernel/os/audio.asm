;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2002, Leif Ekblad
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
; AUDIO.ASM
; Audio module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME audio

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.def
INCLUDE protseg.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE ..\handle.inc

audio_out_sel   STRUC

aos_sample_rate DW ?

audio_out_sel   ENDS

audio_out_struc	STRUC

ao_base		handle_header <>
ao_sel		DW ?

audio_out_struc	ENDS

code	SEGMENT byte public use16 'CODE'

	.386

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateAudioOutChannel
;
;		DESCRIPTION:	Create audio out channel
;
;		PARAMETERS:	    AX      Sample rate
;
;		RETURNS:		BX		Audio out handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_audio_out_channel_name	DB 'Create Audio Out Channel', 0

create_audio_out_channel	Proc far
    push es
    push cx
	mov cx,SIZE audio_out_struc
	AllocateHandle
	mov ds:[bx].hh_sign,BITMAP_HANDLE
;
    push eax
    mov eax,SIZE audio_out_sel
    AllocateSmallGlobalMem
    pop eax
    mov es:aos_sample_rate,ax	
    mov [bx].ao_sel,es
;	
	mov bx,[bx].hh_handle
	pop cx
	pop es
	clc
	retf32
create_audio_out_channel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_out_channel
;
;		DESCRIPTION:	Delete out channel
;
;		PARAMETERS:		DS:BX		Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_out_channel	Proc near
    push es
    mov es,[bx].ao_sel
    FreeMem
	FreeHandle
	clc
    pop es
	ret
delete_out_channel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseAudioOutChannel
;
;		DESCRIPTION:	Close audio out channel
;
;		PARAMETERS:		BX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_audio_out_channel_name	DB 'Close Audio Out Channel', 0

close_audio_out_channel	Proc far
	push ds
	push ax
	push bx
;
	mov ax,AUDIO_OUT_HANDLE
	DerefHandle
	jc caicDone
;
	call delete_out_channel

caicDone:
	pop bx
	pop ax
	pop ds
	retf32
close_audio_out_channel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_out_handle
;
;		DESCRIPTION:	BX			Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_out_handle	Proc far
	push ds
	push ax
	push bx
;
	mov ax,AUDIO_OUT_HANDLE
	DerefHandle
	jc delete_out_handle_done
;
	call delete_out_channel

delete_out_handle_done:
	pop bx
	pop ax
	pop ds
	ret
delete_out_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Init
;
;		DESCRIPTION:	Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	mov bx,ac97_code_sel
	InitDevice
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov ax,AUDIO_OUT_HANDLE
	mov di,OFFSET delete_out_handle
	RegisterHandle
;
	mov si,OFFSET create_audio_out_channel
	mov di,OFFSET create_audio_out_channel_name
	xor dx,dx
	mov ax,create_audio_out_channel_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_audio_out_channel
	mov di,OFFSET close_audio_out_channel_name
	xor dx,dx
	mov ax,close_audio_out_channel_nr
	RegisterBimodalUserGate
;
	ret
init	ENDP

code	ENDS

	END
