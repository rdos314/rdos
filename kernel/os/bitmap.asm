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
; BITMAP.ASM
; Bitmap module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME bitmap

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE user.def
INCLUDE os.def
INCLUDE system.def
INCLUDE protseg.def
INCLUDE user.inc
INCLUDE os.inc
INCLUDE user.inc
INCLUDE driver.def
INCLUDE system.inc
INCLUDE video.inc
INCLUDE handle.inc

code	SEGMENT byte public use16 'CODE'

	.386

	assume cs:code

	extrn BitmapTab24:near
	extrn BitmapTab32:near

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitVideoBitmap
;
;		DESCRIPTION:	Init video bitmap
;
;		PARAMETERS:		AL		Bits per pixel
;						CX		Width
;						DX		Height
;						ES		Video / bitmap selector
;
;		RETURNS:		BX		Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_video_bitmap_name	DB 'Init Video Bitmap', 0

init_video_bitmap	Proc far
	push ds
	push cx
	push si
	push di
;
	InitSection es:v_section
	mov es:v_color,0
	mov es:v_lgop,1
	mov es:v_style,0
	mov es:v_bpp,al
	mov es:v_width,cx
	mov es:v_height,dx
;
	mov si,cs
	mov ds,si
;
	cmp al,24
	je init_video24
;
	cmp al,32
	je init_video32
;
	jmp init_video_done

init_video24:
	mov si,OFFSET BitmapTab24
	jmp init_video_copy

init_video32:
	mov si,OFFSET BitmapTab32
	jmp init_video_copy

init_video_copy:
	mov cx,24
	xor di,di
	rep movsd

init_video_done:
	pop di
	pop si
	pop cx
	pop ds
	ret
init_video_bitmap	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_handle
;
;		DESCRIPTION:	BX			Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	ret
delete_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Init
;
;		DESCRIPTION:	Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_bitmap

init_bitmap	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov ax,BITMAP_HANDLE
	mov di,OFFSET delete_handle
	RegisterHandle
;
	mov si,OFFSET init_video_bitmap
	mov di,OFFSET init_video_bitmap_name
	xor cl,cl
	mov ax,init_video_bitmap_nr
	RegisterOsGate
;
	ret
init_bitmap	ENDP

code	ENDS

	END
