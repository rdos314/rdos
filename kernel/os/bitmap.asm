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
INCLUDE handle.inc
INCLUDE bitmap.inc
INCLUDE video.inc

code	SEGMENT byte public use16 'CODE'

	.386

	assume cs:code

	extrn BitmapTab16:near
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
	cmp al,16
	je init_video16
;
	cmp al,24
	je init_video24
;
	cmp al,32
	je init_video32
;
	jmp init_video_done

init_video16:
	mov si,OFFSET BitmapTab16
	jmp init_video_copy

init_video24:
	mov si,OFFSET BitmapTab24
	jmp init_video_copy

init_video32:
	mov si,OFFSET BitmapTab32
	jmp init_video_copy

init_video_copy:
	mov cx,30
	xor di,di
	rep movsd

init_video_done:
	mov cx,SIZE bitmap_struc
	AllocateHandle
	mov ds:[bx].bm_sel,es
	mov ds:[bx].bm_flag,BM_FLAG_VIDEO
	mov [bx].hh_sign,BITMAP_HANDLE
	mov bx,[bx].hh_handle
	mov es:v_bitmap,bx
;
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
;		NAME:			CreateBitmap
;
;		DESCRIPTION:	Create bitmap
;
;		PARAMETERS:		AL		Bits per pixel
;						CX		Width
;						DX		Height
;
;		RETURNS:		BX		Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_bitmap_name	DB 'Create Bitmap', 0

create_bitmap	Proc far
	push ds
	push es
	push eax
	push ecx
	push edx
	push esi
	push edi
;
	push eax
	mov eax,SIZE video_api_struc
	AllocateSmallGlobalMem
	pop eax
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
	cmp al,16
	je cr_bitmap16
;
	cmp al,24
	je cr_bitmap24
;
	cmp al,32
	je cr_bitmap32
;
	FreeMem
	stc
	jmp cr_bitmap_end

cr_bitmap16:
	mov si,OFFSET BitmapTab16
	mov ax,es:v_width
	add ax,ax
	mov es:v_row_size,ax
	jmp cr_bitmap_copy

cr_bitmap24:
	mov si,OFFSET BitmapTab24
	mov ax,es:v_width
	add ax,ax
	add ax,es:v_width
	dec ax
	add ax,4
	mov es:v_row_size,ax
	jmp cr_bitmap_copy

cr_bitmap32:
	mov si,OFFSET BitmapTab32
	mov ax,es:v_width
	add ax,ax
	add ax,ax
	mov es:v_row_size,ax
	jmp cr_bitmap_copy

cr_bitmap_copy:
	mov cx,30
	xor di,di
	rep movsd
;
	movzx eax,es:v_row_size
	movzx edx,es:v_height
	mul edx
	dec eax
	and ax,0F000h
	add eax,1000h
	mov es:v_app_size,eax
	AllocateLocalLinear
	mov es:v_app_base,edx
;
	push es
	mov ecx,eax
	shr ecx,2
	mov edi,edx
	mov ax,flat_sel
	mov es,ax
	xor eax,eax
	rep stos dword ptr es:[edi]
	pop es
;
	mov cx,SIZE bitmap_struc
	AllocateHandle
	mov ds:[bx].bm_sel,es
	mov ds:[bx].bm_flag,BM_FLAG_BITMAP
	mov [bx].hh_sign,BITMAP_HANDLE
	mov bx,[bx].hh_handle
	mov es:v_bitmap,bx
	clc

cr_bitmap_end:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	pop es
	pop ds
	retf32
create_bitmap	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_bitmap
;
;		DESCRIPTION:	Delete bitmap
;
;		PARAMETERS:		DS:BX		Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_bitmap	Proc near
	test ds:[bx].bm_flag,BM_FLAG_BITMAP
	jz delete_bitmap_free
;
	push es
	push ecx
	push edx
	mov es,[bx].bm_sel
	mov ecx,es:v_app_size
	mov edx,es:v_app_base
	FreeLinear
	FreeMem
	pop edx
	pop ecx
	pop es

delete_bitmap_free:
	FreeHandle
	clc
	ret
delete_bitmap	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseBitmap
;
;		DESCRIPTION:	Close bitmap
;
;		PARAMETERS:		BX		Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_bitmap_name	DB 'Close Bitmap', 0

close_bitmap	Proc far
	push ds
	push ax
	push bx
;
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc cl_bitmap_done
;
	call delete_bitmap

cl_bitmap_done:
	pop bx
	pop ax
	pop ds
	retf32
close_bitmap	Endp

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
	push ds
	push ax
	push bx
;
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc delete_handle_done
;
	call delete_bitmap

delete_handle_done:
	pop bx
	pop ax
	pop ds
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
	mov si,OFFSET create_bitmap
	mov di,OFFSET create_bitmap_name
	xor dx,dx
	mov ax,create_bitmap_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_bitmap
	mov di,OFFSET close_bitmap_name
	xor dx,dx
	mov ax,close_bitmap_nr
	RegisterBimodalUserGate
;
	ret
init_bitmap	ENDP

code	ENDS

	END
