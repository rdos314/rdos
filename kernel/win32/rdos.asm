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
; RDOS.ASM
; 32-bit interface for RDOS API for Win32 compilers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  rdos

	.386
	.model flat

include \rdos\os\user.def

tib_data	STRUC

pvFirstExcept		DD ?
pvStackUserTop		DD ?
pvStackUserBottom	DD ?
pvLastError			DD ?
pvStackUserSize		DD ?
pvArbitrary			DD ?
pvTEB				DD ?
pvProcessHandle		DD ?
pvThreadHandle		DD ?
pvModuleHandle		DD ?
pvTLSBitmap			DD ?
pvTLSArray			DD ?

tib_data	ENDS

UserGate	MACRO gate_nr
	db 9Ah
	dd gate_nr
	dw 2
			ENDM

		NAME system

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

	.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TASK_END
;
;		description:	Termination of task
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

task_end:
	UserGate terminate_thread_nr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TASK_START
;
;		description:	Task startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

task_start	proc
	mov ax,ds
	mov es,ax
	push fs:pvArbitrary
	push OFFSET task_end
	push edx
	ret
task_start	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateThread
;
;		description:	Create a new thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateThread

task_callb	EQU 8
task_name	EQU 12
task_data	EQU 16
task_stack	EQU 20

RdosCreateThread	PROC
	push ebp
	mov ebp,esp
	push ds
	pushad
;
	mov edx,[ebp].task_callb
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET task_start
	mov ecx,[ebp].task_stack
	mov edi,[ebp].task_name
	mov eax,[ebp].task_data
	mov fs:pvArbitrary,eax
	mov bx,fs
	mov ax,2
	UserGate create_thread_nr
;
	mov eax,10
	UserGate wait_milli_nr
;
	popad
	pop ds
	pop ebp
	ret 16
RdosCreateThread	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAllocateMem
;
;		description:	Allocate memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAllocateMem

RdosAllocateMem	Proc
	push ebp
	mov ebp,esp
	push edx
;
	mov eax,[ebp+8]
	UserGate allocate_app_mem_nr
	mov eax,edx
;
	pop edx
	pop ebp
	ret 4
RdosAllocateMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosFreeMem
;
;		description:	Free memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosFreeMem

RdosFreeMem	Proc
	push ebp
	mov ebp,esp
	push edx
;
	mov edx,[ebp+8]
	UserGate free_app_mem_nr
;
	pop edx
	pop ebp
	ret 4
RdosFreeMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitMilli
;
;		description:	Wait a number of milliseconds
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitMilli

RdosWaitMilli	Proc
	push ebp
	mov ebp,esp
	push eax
;
	mov eax,[ebp+8]
	UserGate wait_milli_nr
;
	pop eax
	pop ebp
	ret 4
RdosWaitMilli	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateSection
;
;		description:	Create section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateSection

RdosCreateSection	Proc
	push ebx
	UserGate create_user_section_nr
	movzx eax,bx
	pop ebx
	ret
RdosCreateSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDeleteSection
;
;		description:	Delete section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDeleteSection

RdosDeleteSection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate delete_user_section_nr
;
	pop ebx
	pop ebp
	ret 4
RdosDeleteSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosEnterSection
;
;		description:	Enter section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosEnterSection

RdosEnterSection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate enter_user_section_nr
;
	pop ebx
	pop ebp
	ret 4
RdosEnterSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosLeaveSection
;
;		description:	Leave section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosLeaveSection

RdosLeaveSection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate leave_user_section_nr
;
	pop ebx
	pop ebp
	ret 4
RdosLeaveSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetVBEMode
;
;		description:	int RdosSetVBEMode(int *BitsPerPixel, 
;						int *xres, int *yres, int *linesize, void **buffer);
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetVBEMode

RdosSetVBEMode	Proc
	push ebp
	mov ebp,esp
	push bx
	push ecx
	push edx
	push esi
	push edi
;
	mov edi,[ebp+8]
	mov ax,[edi]
	mov edi,[ebp+12]
	mov cx,[edi]
	mov edi,[ebp+16]
	mov dx,[edi]	
	UserGate set_vbe_mode_nr
	jc set_vbe_fail
;
	push edi
	mov edi,[ebp+8]
	movzx eax,ax
	mov [edi],eax
	mov edi,[ebp+12]
	movzx ecx,cx
	mov [edi],ecx
	mov edi,[ebp+16]
	movzx edx,dx
	mov [edi],edx
	mov edi,[ebp+20]
	movzx esi,si
	mov [edi],si
	pop edi
	mov eax,[ebp+24]
	mov [eax],edi
	movzx eax,bx
	jmp set_vbe_done

set_vbe_fail:
	xor eax,eax
	mov edi,[ebp+8]
	mov [edi],eax
	mov edi,[ebp+12]
	mov [edi],eax
	mov edi,[ebp+16]
	mov [edi],eax
	mov edi,[ebp+20]
	mov [edi],eax
	mov edi,[ebp+24]
	mov [edi],eax

set_vbe_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop bx
	pop ebp
	ret 20
RdosSetVBEMode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetClipRect
;
;		description:	RdosSetClipRect(handle, xmin, xmax, ymin, ymax)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetClipRect

RdosSetClipRect	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov si,[ebp+20]
	mov di,[ebp+24]
	UserGate set_clip_rect_nr
;
    pop edi
    pop esi
    pop edx
    pop ecx
	pop ebx
	pop ebp
	ret 20
RdosSetClipRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosClearClipRect
;
;		description:	RdosClearClipRect(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosClearClipRect

RdosClearClipRect	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate clear_clip_rect_nr
;
	pop ebx
	pop ebp
	ret 4
RdosClearClipRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetDrawColor
;
;		description:	RdosSetDrawColor(handle, color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetDrawColor

RdosSetDrawColor	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate set_drawcolor_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetDrawColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetLGOP
;
;		description:	RdosSetLGOP(handle, lgop)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetLGOP

RdosSetLGOP	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	UserGate set_lgop_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetLGOP	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetHollowStyle
;
;		description:	RdosSetHollowStyle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetHollowStyle

RdosSetHollowStyle	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate set_hollow_style_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSetHollowStyle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetFilledStyle
;
;		description:	RdosSetFilledStyle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFilledStyle

RdosSetFilledStyle	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate set_filled_style_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSetFilledStyle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosOpenFont
;
;		description:	RdosOpenFont(height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenFont

RdosOpenFont	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov ax,[ebp+8]
	UserGate open_font_nr
	movzx eax,bx
;
	pop ebx
	pop ebp
	ret 4
RdosOpenFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseFont
;
;		description:	RdosCloseFont(font)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseFont

RdosCloseFont	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_font_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetStringMetrics
;
;		description:	RdosGetStringMetrics(font, str, &width, &height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetStringMetrics

RdosGetStringMetrics	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	UserGate get_string_metrics_nr
;
	mov edi,[ebp+16]
	movzx ecx,cx
	mov [edi],ecx
	mov edi,[ebp+20]
	movzx edx,dx
	mov [edi],edx
;
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosGetStringMetrics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetFont
;
;		description:	RdosSetFont(handle, font)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFont

RdosSetFont	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	UserGate set_font_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetPixel
;
;		description:	RdosGetPixel(handle, x, y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetPixel

RdosGetPixel	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	UserGate get_pixel_nr
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosGetPixel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetPixel
;
;		description:	RdosSetPixel(handle, x, y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetPixel

RdosSetPixel	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	UserGate set_pixel_nr
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosSetPixel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosBlit
;
;		description:	RdosBlit(SrcHandle, DestHandle, width, height,
;								 SrcX, SrcY, DestX, DestY);
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosBlit

RdosBlit	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ax,[ebp+8]
	mov bx,[ebp+12]
	mov cx,[ebp+16]
	mov dx,[ebp+20]
	mov si,[ebp+28]
	shl esi,16
	mov si,[ebp+24]
	mov di,[ebp+36]
	shl edi,16
	mov di,[ebp+32]
	UserGate blit_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 32
RdosBlit	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawMask
;
;		description:	RdosDrawMask(handle, mask, RowSize, width, height,
;					 				 SrcX, SrcY, DestX, DestY); 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawMask

RdosDrawMask	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ax,[ebp+16]
	mov si,[ebp+24]
	shl esi,16
	mov si,[ebp+20]
	mov cx,[ebp+32]
	shl ecx,16
	mov cx,[ebp+28]
	mov dx,[ebp+40]
	shl edx,16
	mov dx,[ebp+36]
	UserGate blit_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 36
RdosDrawMask	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawLine
;
;		description:	RdosDrawLine(handle, x1, y1, x2, y2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawLine

RdosDrawLine	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov si,[ebp+20]
	mov di,[ebp+24]
	UserGate draw_line_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosDrawLine	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawString
;
;		description:	RdosDrawString(handle, x, y, str)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawString

RdosDrawString	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov edi,[ebp+20]
	UserGate draw_string_nr
;
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosDrawString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawRect
;
;		description:	RdosDrawRect(handle, x, y, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawRect

RdosDrawRect	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov si,[ebp+20]
	mov di,[ebp+24]
	UserGate draw_rect_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosDrawRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawEllipse
;
;		description:	RdosDrawEllipse(handle, x, y, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawEllipse

RdosDrawEllipse	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov si,[ebp+20]
	mov di,[ebp+24]
	UserGate draw_ellipse_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosDrawEllipse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateBitmap
;
;		description:	RdosCreateBitmap(BitsPerPixel, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateBitmap

RdosCreateBitmap	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov ax,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	UserGate create_bitmap_nr
	movzx eax,bx
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosCreateBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDuplicateBitmapHandle
;
;		description:	RdosDuplicateBitmapHandle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDuplicateBitmapHandle

RdosDuplicateBitmapHandle	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate dup_bitmap_handle_nr
	movzx eax,bx
;
	pop ebx
	pop ebp
	ret 4
RdosDuplicateBitmapHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseBitmap
;
;		description:	RdosCloseBitmap(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseBitmap

RdosCloseBitmap	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_bitmap_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateStringBitmap
;
;		description:	RdosCreateStringBitmap(font, str)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateStringBitmap

RdosCreateStringBitmap	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	UserGate create_string_bitmap_nr
	movzx eax,bx
;
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosCreateStringBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetBitmapInfo
;
;		description:	RdosGetBitmapInfo(handle, &BitsPerPixel, &width, &height,
;					   						&linesize, &buffer)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetBitmapInfo

RdosGetBitmapInfo	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	UserGate get_bitmap_info_nr
	jc gbiFail
;
	mov edi,[ebp+12]
	movzx eax,al
	mov [edi],eax
	mov edi,[ebp+16]
	movzx ecx,cx
	mov [edi],ecx
	mov edi,[ebp+20]
	movzx edx,dx
	mov [edi],edx
	mov edi,[ebp+24]
	movzx esi,si
	mov [edi],esi
	pop edi
	mov eax,[ebp+28]
	mov [eax],edi
	jmp gbiDone

gbiFail:
	xor eax,eax
	mov edi,[ebp+12]
	mov [edi],eax
	mov edi,[ebp+16]
	mov [edi],eax
	mov edi,[ebp+20]
	mov [edi],eax
	mov edi,[ebp+24]
	mov [edi],eax
	mov edi,[ebp+28]
	mov [edi],eax

gbiDone:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 24
RdosGetBitmapInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateSprite
;
;		description:	RdosCreateSprite(dest, bitmap, mask, lgop)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateSprite

RdosCreateSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov ax,[ebp+20]
	UserGate create_sprite_nr
	movzx eax,bx
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosCreateSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseSprite
;
;		description:	RdosCloseSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseSprite

RdosCloseSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_sprite_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosShowSprite
;
;		description:	RdosShowSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosShowSprite

RdosShowSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate show_sprite_nr
;
	pop ebx
	pop ebp
	ret 4
RdosShowSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosHideSprite
;
;		description:	RdosHideSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosHideSprite

RdosHideSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate hide_sprite_nr
;
	pop ebx
	pop ebp
	ret 4
RdosHideSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosMoveSprite
;
;		description:	RdosMoveSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosMoveSprite

RdosMoveSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	UserGate move_sprite_nr
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosMoveSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetForeColor
;
;		description:	SetForeColor(color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetForeColor

RdosSetForeColor	Proc
	push ebp
	mov ebp,esp
	push eax
;
	mov al,[ebp+8]
	UserGate set_forecolor_nr
;
	pop eax
	pop ebp
	ret 4
RdosSetForeColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetBackColor
;
;		description:	SetBackColor(color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetBackColor

RdosSetBackColor	Proc
	push ebp
	mov ebp,esp
	push eax
;
	mov al,[ebp+8]
	UserGate set_backcolor_nr
;
	pop eax
	pop ebp
	ret 4
RdosSetBackColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetSysTime
;
;		description:	gets system time in record form
;
;		PARAMETERS:		int *year
;						int *month
;						int *day
;						int *hour
;						int *min
;						int *sec
;						int *milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetSysTime

gtrtYear	EQU 8
gtrtMonth	EQU 12
gtrtDay		EQU 16
gtrtHour	EQU 20
gtrtMin		EQU 24
gtrtSec		EQU 28
gtrtMilli	EQU 32

RdosGetSysTime	Proc
	push ebp
	mov ebp,esp
	pushad
;
	UserGate get_system_time_nr
	push eax
	UserGate binary_to_time_nr
	push edx
;
	mov esi,[ebp].gtrtYear
	movzx edx,dx
	mov [esi],edx
;
	mov esi,[ebp].gtrtMonth
	movzx edx,ch
	mov [esi],edx
;
	mov esi,[ebp].gtrtDay
	movzx edx,cl
	mov [esi],edx
;
	mov esi,[ebp].gtrtHour
	movzx edx,bh
	mov [esi],edx
;
	mov esi,[ebp].gtrtMin
	movzx edx,bl
	mov [esi],edx
;
	mov esi,[ebp].gtrtSec
	movzx edx,ah
	mov [esi],edx
;
	pop edx
	UserGate time_to_binary_nr
	mov ebx,eax
	pop eax
	sub eax,ebx
	xor edx,edx
	mov ebx,1192
	div ebx
	mov esi,[ebp].gtrtMilli
	movzx eax,ax
	mov [esi],eax
;
	popad
	pop ebp
	ret 24
RdosGetSysTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetTime
;
;		description:	gets time in record form
;
;		PARAMETERS:		int *year
;						int *month
;						int *day
;						int *hour
;						int *min
;						int *sec
;						int *milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetTime

gttYear	EQU 8
gttMonth	EQU 12
gttDay		EQU 16
gttHour	EQU 20
gttMin		EQU 24
gttSec		EQU 28
gttMilli	EQU 32

RdosGetTime	Proc
	push ebp
	mov ebp,esp
	pushad
;
	UserGate get_time_nr
	push eax
	UserGate binary_to_time_nr
	push edx
;
	mov esi,[ebp].gttYear
	movzx edx,dx
	mov [esi],edx
;
	mov esi,[ebp].gttMonth
	movzx edx,ch
	mov [esi],edx
;
	mov esi,[ebp].gttDay
	movzx edx,cl
	mov [esi],edx
;
	mov esi,[ebp].gttHour
	movzx edx,bh
	mov [esi],edx
;
	mov esi,[ebp].gttMin
	movzx edx,bl
	mov [esi],edx
;
	mov esi,[ebp].gttSec
	movzx edx,ah
	mov [esi],edx
;
	pop edx
	UserGate time_to_binary_nr
	mov ebx,eax
	pop eax
	sub eax,ebx
	xor edx,edx
	mov ebx,1192
	div ebx
	mov esi,[ebp].gttMilli
	movzx eax,ax
	mov [esi],eax
;
	popad
	pop ebp
	ret 24
RdosGetTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosConvertTics
;
;		description:	Convert tics to record form
;
;		PARAMETERS:		int MSB
;						int LSB
;						int *year
;						int *month
;						int *day
;						int *hour
;						int *min
;						int *sec
;						int *milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosConvertTics

ctMSB		EQU 8
ctLSB		EQU 12
ctYear		EQU 16
ctMonth		EQU 20
ctDay		EQU 24
ctHour		EQU 28
ctMin		EQU 32
ctSec		EQU 36
ctMilli		EQU 40

RdosConvertTics	Proc
	push ebp
	mov ebp,esp
	pushad
;
	mov edx,[ebp].ctMSB
	mov eax,[ebp].ctLSB
	UserGate binary_to_time_nr
	push edx
;
	mov esi,[ebp].ctYear
	movzx edx,dx
	mov [esi],edx
;
	mov esi,[ebp].ctMonth
	movzx edx,ch
	mov [esi],edx
;
	mov esi,[ebp].ctDay
	movzx edx,cl
	mov [esi],edx
;
	mov esi,[ebp].ctHour
	movzx edx,bh
	mov [esi],edx
;
	mov esi,[ebp].ctMin
	movzx edx,bl
	mov [esi],edx
;
	mov esi,[ebp].ctSec
	movzx edx,ah
	mov [esi],edx
;
	pop edx
	UserGate time_to_binary_nr
	mov ebx,eax
	mov eax,[ebp].ctLSB
	sub eax,ebx
	xor edx,edx
	mov ebx,1192
	div ebx
	mov esi,[ebp].ctMilli
	movzx eax,ax
	mov [esi],eax
;
	popad
	pop ebp
	ret 32
RdosConvertTics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetTics
;
;		description:	gets system time
;
;		parameters:		MSB of tics
;						LSB of tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetTics

rgtMSB	EQU 8
rgtLSB	EQU 12

RdosGetTics	Proc
	push ebp
	mov ebp,esp
	push edx
	push esi
;
	UserGate get_system_time_nr
	mov esi,[ebp].rgtMSB
	mov [esi],edx
	mov esi,[ebp].rgtLSB
	mov [esi],eax
;
	pop esi
	pop edx
	pop ebp
	ret 8
RdosGetTics	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosOpenCom
;
;		description:	™ppnar comport
;
;		PARAMETERS:		port_base		basadress till com port
;						port_irq		irq till com port
;						baud_divisor	baudrate divisor
;						parity			parity 'N', 'E' or 'O'
;						data_bits		# of data bits
;						stop_bits		# of stop bits
;						send_buf_size	size of transmit buffer
;						rec_buf_size	size of receive buffer
;
;		RETURNS:		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenCom

port_base		EQU 8
port_irq		EQU 12
baud_divisor	EQU 16
parity			EQU 20
data_bits		EQU 24
stop_bits		EQU 28
send_buf_size	EQU 32
rec_buf_size	EQU 36

RdosOpenCom	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov dx,[ebp].port_base
	mov al,[ebp].port_irq
	mov ah,[ebp].data_bits
	mov bl,[ebp].stop_bits
	mov bh,[ebp].parity
	mov cx,[ebp].baud_divisor
	mov si,[ebp].send_buf_size
	mov di,[ebp].rec_buf_size
	UserGate open_com_nr
	mov ax,bx
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 32
RdosOpenCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseCom
;
;		description:	St„nger comport
;
;		PARAMETERS:		port_handle		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseCom

RdosCloseCom	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_com_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosFlushCom
;
;		description:	Rensar rx och tx k”
;
;		PARAMETERS:		port_handler	handle till port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosFlushCom

RdosFlushCom	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate flush_com_nr
;
	pop ebx
	pop ebp
	ret 4
RdosFlushCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosPollCom
;
;		description:	Testa om det finns n†got tecken fr†n serieport
;
;		PARAMETERS:		hport		com handle
;
;		RETURNS:		> 0			antal tecken i buffert
;						FALSE		buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPollCom

RdosPollCom	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate poll_com_nr
;
	pop ebx
	pop ebp
	ret 4
RdosPollCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitForCom
;
;		description:	V„nta p† tecken
;
;		PARAMETERS:		hport		com handle
;						timeout		ms timeout
;
;		RETURNS:		> 0			antal tecken i buffert
;						FALSE		buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitForCom

RdosWaitForCom	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate wait_for_com_nr
	movzx eax,ax
;
	pop ebx
	pop ebp
	ret 8
RdosWaitForCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosReadCom
;
;		description:	L„s tecken fr†n serieport
;
;		PARAMETERS:		hport		com handle
;
;		RETURNS:		ch			received char
;						-1			buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadCom

RdosReadCom	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate read_com_nr
;
	pop ebx
	pop ebp
	ret 4
RdosReadCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWriteCom
;
;		description:	S„nd tecken till serieport
;
;		PARAMETERS:		hport		com handle
;						ch			tecken
;
;		RETURNS:		0			s„ndning ok
;						-1			buffer full
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteCom

RdosWriteCom	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov al,[ebp+12]
	UserGate write_com_nr
	movzx eax,al
;
	pop ebx
	pop ebp
	ret 8
RdosWriteCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetDtr
;
;		description:	S„tt DTR on
;
;		PARAMETERS:		hport		com handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetDtr

RdosSetDtr	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate set_dtr_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSetDtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosResetDtr
;
;		description:	S„tt DTR off
;
;		PARAMETERS:		hport		com handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosResetDtr

RdosResetDtr	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate reset_dtr_nr
;
	pop ebx
	pop ebp
	ret 4
RdosResetDtr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenFile
;
;		DESCRIPTION:	Opens a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenFile

RdosOpenFile	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov edi,[ebp+8]
	mov cl,[ebp+12]
	UserGate open_file_nr
	jc OpenFileFailed
	mov ax,bx
	jmp OpenFileDone

OpenFileFailed:
	xor ax,ax

OpenFileDone:
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 8
RdosOpenFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateFile
;
;		DESCRIPTION:	Creates a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateFile

RdosCreateFile	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov edi,[ebp+8]
	mov cx,[ebp+12]
	UserGate create_file_nr
	jc CreateFileFailed
	mov ax,bx
	jmp CreateFileDone

CreateFileFailed:
	xor ax,ax

CreateFileDone:
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 8
RdosCreateFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseFile
;
;		DESCRIPTION:	Close a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseFile

RdosCloseFile	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_file_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFileSize
;
;		DESCRIPTION:	Get size of a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFileSize

RdosGetFileSize	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_file_size_nr
	jnc GetFileSizeDone

GetFileSizeFail:
	xor eax,eax

GetFileSizeDone:
	pop ebx
	pop ebp
	ret 4
RdosGetFileSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFileSize
;
;		DESCRIPTION:	Set size of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFileSize

RdosSetFileSize	PROC
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate set_file_size_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetFileSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFilePos
;
;		DESCRIPTION:	Get position in a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFilePos

RdosGetFilePos	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_file_pos_nr
	jnc GetFilePosDone

GetFilePosFail:
	xor eax,eax

GetFilePosDone:
	pop ebx
	pop ebp
	ret 4
RdosGetFilePos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFilePos
;
;		DESCRIPTION:	Set position in file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFilePos

RdosSetFilePos	PROC
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate set_file_pos_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetFilePos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadFile
;
;		DESCRIPTION:	Read data from file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadFile

RdosReadFile	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate read_file_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosReadFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteFile
;
;		DESCRIPTION:	Write data to file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteFile

RdosWriteFile	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate write_file_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosWriteFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateMapping
;
;		DESCRIPTION:	Create file mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateMapping

RdosCreateMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+8]
	UserGate create_mapping_nr
	movzx eax,bx
;
	pop ebx
	pop ebp
	ret 4
RdosCreateMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateNamedMapping
;
;		DESCRIPTION:	Create file named mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateNamedMapping

RdosCreateNamedMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	mov eax,[ebp+12]
	UserGate create_named_mapping_nr
	movzx eax,bx
;
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosCreateNamedMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateNamedFileMapping
;
;		DESCRIPTION:	Create file named file mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateNamedFileMapping

RdosCreateNamedFileMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	mov eax,[ebp+12]
	mov bx,[ebp+16]
	UserGate create_named_file_mapping_nr
	movzx eax,bx
;
	pop edi
	pop ebx
	pop ebp
	ret 12
RdosCreateNamedFileMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenNamedMapping
;
;		DESCRIPTION:	Open named mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenNamedMapping

RdosOpenNamedMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	UserGate open_named_mapping_nr
	movzx eax,bx
;
	pop edi
	pop ebx
	pop ebp
	ret 4
RdosOpenNamedMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSyncMapping
;
;		DESCRIPTION:	Sync mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSyncMapping

RdosSyncMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate sync_mapping_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSyncMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseMapping
;
;		DESCRIPTION:	Close mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseMapping

RdosCloseMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_mapping_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosMapView
;
;		DESCRIPTION:	Map view into memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosMapView

RdosMapView	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate map_view_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosMapView	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosUnmapView
;
;		DESCRIPTION:	Unmap view from memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosUnmapView

RdosUnmapView	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate unmap_view_nr
;
	pop ebx
	pop ebp
	ret 4
RdosUnmapView	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetCurDir
;
;		DESCRIPTION:	Set current directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetCurDir

RdosSetCurDir	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate set_cur_dir_nr
;
	pop edi
	pop ebp
	ret 4
RdosSetCurDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFocus
;
;		DESCRIPTION:	Set focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFocus

RdosSetFocus	PROC
	push ebp
	mov ebp,esp
	mov eax,[ebp+8]
	UserGate set_focus_nr
	pop ebp
	ret 4
RdosSetFocus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosClearKeyboard
;
;		DESCRIPTION:	Clear keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosClearKeyboard

RdosClearKeyboard	PROC
	UserGate flush_keyboard_nr
	ret
RdosClearKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPollKeyboard
;
;		DESCRIPTION:	Poll keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPollKeyboard

RdosPollKeyboard	PROC
	UserGate poll_keyboard_nr
	jc rpkEmpty
;
	mov eax,1
	ret

rpkEmpty:
	xor eax,eax
	ret
RdosPollKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadKeyboard
;
;		DESCRIPTION:	Read keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadKeyboard

RdosReadKeyboard	PROC
	UserGate read_keyboard_nr
	movzx eax,ax
	ret
RdosReadKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosHideMouse
;
;		DESCRIPTION:	Hide mouse
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosHideMouse

RdosHideMouse	PROC
	UserGate hide_mouse_nr
	ret
RdosHideMouse	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosShowMouse
;
;		DESCRIPTION:	Show mouse
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosShowMouse

RdosShowMouse	PROC
	UserGate show_mouse_nr
	ret
RdosShowMouse	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetMousePosition
;
;		DESCRIPTION:	Get mouse position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetMousePosition

RdosGetMousePosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_mouse_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetMousePosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetMousePosition
;
;		DESCRIPTION:	Set mouse position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetMousePosition

RdosSetMousePosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	mov cx,[ebp+8]
	mov dx,[ebp+12]
	UserGate set_mouse_position_nr
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosSetMousePosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetMouseWindow
;
;		DESCRIPTION:	Set mouse window
;
;		PARAMETER:		start x
;						start y
;						end x
;						end y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetMouseWindow

RdosSetMouseWindow	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	mov ax,[ebp+8]
	mov bx,[ebp+12]
	mov cx,[ebp+16]
	mov dx,[ebp+20]
	UserGate set_mouse_window_nr
;
	pop edx
	pop ecx
	pop ebp
	ret 16
RdosSetMouseWindow	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetMouseMickey
;
;		DESCRIPTION:	Set mouse mickey
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetMouseMickey

RdosSetMouseMickey	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	mov cx,[ebp+8]
	mov dx,[ebp+12]
	UserGate set_mouse_mickey_nr
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosSetMouseMickey	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetCursorPosition
;
;		DESCRIPTION:	Set cursor position
;
;		PARAMETER:		Row
;						Col
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetCursorPosition

RdosSetCursorPosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	mov dx,[ebp+8]
	mov cx,[ebp+12]
	UserGate set_cursor_position_nr
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosSetCursorPosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLeftButton
;
;		DESCRIPTION:	Check if left button is pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetLeftButton

RdosGetLeftButton	PROC
	UserGate get_left_button_nr
	jc get_left_rel
;
	mov eax,1
	ret

get_left_rel:
	xor eax,eax
	ret
RdosGetLeftButton	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRightButton
;
;		DESCRIPTION:	Check if right button is pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetRightButton

RdosGetRightButton	PROC
	UserGate get_right_button_nr
	jc get_right_rel
;
	mov eax,1
	ret

get_right_rel:
	xor eax,eax
	ret
RdosGetRightButton	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLeftButtonPressPosition
;
;		DESCRIPTION:	Get left button press position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetLeftButtonPressPosition

RdosGetLeftButtonPressPosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_left_button_press_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetLeftButtonPressPosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRightButtonPressPosition
;
;		DESCRIPTION:	Get right button pressed position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetRightButtonPressPosition

RdosGetRightButtonPressPosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_right_button_press_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetRightButtonPressPosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLeftButtonRelesePosition
;
;		DESCRIPTION:	Get left button released position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetLeftButtonReleasePosition

RdosGetLeftButtonReleasePosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_left_button_release_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetLeftButtonReleasePosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRightButtonReleasePosition
;
;		DESCRIPTION:	Get right button release position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetRightButtonReleasePosition

RdosGetRightButtonReleasePosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_right_button_release_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetRightButtonReleasePosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadLine
;
;		DESCRIPTION:	Read a line from keyboard
;
;		PARAMETERS:		Buffer
;						Buffer size
;
;		RETURNS:		Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadLine

RdosReadLine	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edi
;
	mov edi,[ebp+8]
	mov ecx,[ebp+12]
	UserGate read_con_nr
;
	pop edi
	pop ecx
	pop ebp
	ret 8
RdosReadLine	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteString
;
;		DESCRIPTION:	Write a string to screen
;
;		PARAMETER:		String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteString

RdosWriteString	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate write_asciiz_nr
;
	pop edi
	pop ebp
	ret 4
RdosWriteString	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosNameToIp
;
;		DESCRIPTION:	Convert host name to IP address
;
;		PARAMETER:		Pathname
;						IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosNameToIp

RdosNameToIp	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate name_to_ip_nr
	jc rntiFail
;
	mov eax,edx
	jmp rntiDone

rntiFail:
	xor eax,eax

rntiDone:
	pop edi
	pop ebp
	ret 4
RdosNameToIp	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosIpToName
;
;		DESCRIPTION:	Convert IP address to host name
;
;		PARAMETER:		IP address
;						Host name
;						Max size of name
;
;		RETURNS:		Number of bytes returned
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosIpToName

RdosIpToName	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
	push edi
;
	mov edx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate ip_to_name_nr
	jnc ritnDone

ritnFail:
	xor eax,eax

ritnDone:
	pop edi
	pop edx
	pop ecx
	pop ebp
	ret 12
RdosIpToName	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPing
;
;		DESCRIPTION:	Ping node
;
;		PARAMETER:		Node
;						Timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPing

RdosPing	PROC
	push ebp
	mov ebp,esp
	push edx
;
	mov edx,[ebp+8]
	mov eax,[ebp+12]
	UserGate ping_nr
	jc ping_failed
;
	mov eax,1
	jmp ping_done

ping_failed:
	xor eax,eax

ping_done:
	pop edx
	pop ebp
	ret 8
RdosPing	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenConnection
;
;		DESCRIPTION:	Open an active connection over TCP
;
;		PARAMETER:		RemoteIp
;						LocalPort
;						RemotePort
;						Timeout in ms
;						BufferSize
;
;		RETURNS:		Connection handle						
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenTcpConnection

RdosOpenTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov edx,[ebp+8]
	mov si,[ebp+12]
	mov di,[ebp+16]
	mov eax,[ebp+20]
	mov ecx,[ebp+24]
	UserGate open_tcp_connection_nr
	mov eax,0
	jc rotcDone
	mov eax,ebx
rotcDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 20
RdosOpenTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosListenTcpPort
;
;		DESCRIPTION:	Initialize listen on passive port
;
;		PARAMETER:		Port
;						BufferSize
;						Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ListenCallback	Proc
	push ebx
	push OFFSET lcDone
	push eax
	ret
lcDone:
	ret
ListenCallback	Endp

	public RdosListenTcpPort

RdosListenTcpPort	Proc
	push ebp
	mov ebp,esp
	push esi
	push edi
;
	mov edi,OFFSET ListenCallback
	mov si,[ebp+8]
	mov ecx,[ebp+12]
	mov eax,[ebp+16]
	UserGate listen_tcp_port_nr
;
	pop edi
	pop esi
	pop ebp
	ret 12
RdosListenTcpPort	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWaitForTcpConnection
;
;		DESCRIPTION:	Wait for a passive connection to establish
;
;		PARAMETER:		Handle
;						Timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitForTcpConnection

RdosWaitForTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate wait_for_tcp_connection_nr
	mov eax,1
	jnc wftcDone
	xor eax,eax
wftcDone:
	pop ebx
	pop ebp
	ret 8
RdosWaitForTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseTcpConnection
;
;		DESCRIPTION:	Close connection
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseTcpConnection

RdosCloseTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosDeleteTcpConnection
;
;		DESCRIPTION:	Delete connection handle
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDeleteTcpConnection

RdosDeleteTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate delete_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosDeleteTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosAbortTcpConnection
;
;		DESCRIPTION:	Abort connection
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAbortTcpConnection

RdosAbortTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate abort_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosAbortTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPushTcpConnection
;
;		DESCRIPTION:	Push connection
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPushTcpConnection

RdosPushTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate push_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosPushTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosIsTcpConnectionClosed
;
;		DESCRIPTION:	Check if other side closed the connection
;
;		PARAMETER:		Handle
;
;		RETURNS:		FALSE		Connection still alive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosIsTcpConnectionClosed

RdosIsTcpConnectionClosed	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate is_tcp_connection_closed_nr
	jc rptcClosed
;
	xor eax,eax
	jmp rptcDone

rptcClosed:
	mov eax,1
	
rptcDone:
	pop ebx
	pop ebp
	ret 4
RdosIsTcpConnectionClosed	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadTcpConnection
;
;		DESCRIPTION:	Read data from connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadTcpConnection

RdosReadTcpConnection	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate read_tcp_connection_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosReadTcpConnection	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteTcpConnection
;
;		DESCRIPTION:	Write data to connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteTcpConnection

RdosWriteTcpConnection	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate write_tcp_connection_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosWriteTcpConnection	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLocalMailslot
;
;		DESCRIPTION:	Get local mailslot from name
;
;		PARAMETER:		Name
;
;		RETURNS:		Mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetLocalMailslot

RdosGetLocalMailslot	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	UserGate get_local_mailslot_nr
	jc rglmFail
;
	movzx eax,bx
	jmp rglmDone

rglmFail:
	xor eax,eax

rglmDone:
	pop edi
	pop ebx
	pop ebp
	ret 4
RdosGetLocalMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRemoteMailslot
;
;		DESCRIPTION:	Get remote mailslot from name
;
;		PARAMETER:		Ip
;						Name
;
;		RETURNS:		Mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetRemoteMailslot

RdosGetRemoteMailslot	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edx
	push edi
;
	mov edx,[ebp+8]
	mov edi,[ebp+12]
	UserGate get_remote_mailslot_nr
	jc rgrmFail
;
	movzx eax,bx
	jmp rgrmDone

rgrmFail:
	xor eax,eax

rgrmDone:
	pop edi
	pop edx
	pop ebx
	pop ebp
	ret 8
RdosGetRemoteMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosFreeMailslot
;
;		DESCRIPTION:	Free mailslot handle
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosFreeMailslot

RdosFreeMailslot	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	UserGate free_mailslot_nr
;
	pop ebx
	pop ebp
	ret 4
RdosFreeMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSendMailslot
;
;		DESCRIPTION:	Send to mailslot and wait for reply
;
;		PARAMETER:		Handle
;						Msg
;						Size
;						ReplyBuf
;						MaxReplySize
;
;		RETURNS:		Reply size or -1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSendMailslot

RdosSendMailslot	Proc
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov esi,[ebp+12]
	mov ecx,[ebp+16]
	mov edi,[ebp+20]
	mov eax,[ebp+24]
	UserGate send_mailslot_nr
	jc smFail
;
	mov eax,ecx
	jmp smDone

smFail:
	mov eax,-1

smDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 20
RdosSendMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosDefineMailslot
;
;		DESCRIPTION:	Define mailslot for current thread
;
;		PARAMETER:		Name
;						Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDefineMailslot

RdosDefineMailslot	Proc
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	mov ecx,[ebp+12]
	UserGate define_mailslot_nr
;
	pop edi
	pop ebp
	ret 8
RdosDefineMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReceiveMailslot
;
;		DESCRIPTION:	Receive from mailslot
;
;		PARAMETER:		Msg buffer
;
;		RETURNS:		Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReceiveMailslot

RdosReceiveMailslot	Proc
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate receive_mailslot_nr
	mov eax,ecx
;
	pop edi
	pop ebp
	ret 4
RdosReceiveMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReplyMailslot
;
;		DESCRIPTION:	Receive from mailslot
;
;		PARAMETER:		Msg
;						Size
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReplyMailslot

RdosReplyMailslot	Proc
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	mov ecx,[ebp+12]
	UserGate reply_mailslot_nr
;
	pop edi
	pop ebp
	ret 8
RdosReplyMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetDiscInfo
;
;		DESCRIPTION:	Get disc info
;
;		PARAMETER:		Disc #
;						Bytes / sector
;						Total sectors
;						BIOS sectors / cyl
;						BIOS heads
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetDiscInfo

RdosGetDiscInfo	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edx
	push esi
	push edi
;
	mov al,[ebp+8]
	UserGate get_disc_info_nr
	jc get_disc_info_fail
;
	mov ebx,[ebp+12]
	movzx ecx,cx
	mov [ebx],ecx
;
	mov ebx,[ebp+16]
	mov [ebx],edx
;
	mov ebx,[ebp+20]
	movzx esi,si
	mov [ebx],esi
;
	mov ebx,[ebp+24]
	movzx edi,di
	mov [ebx],edi
;
	mov eax,1
	jmp get_disc_info_done

get_disc_info_fail:
	xor eax,eax

get_disc_info_done:
	pop edi
	pop esi
	pop edx
	pop ebx
	pop ebp
	ret 20
RdosGetDiscInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadDisc
;
;		DESCRIPTION:	Read from disc
;
;		PARAMETER:		Disc #
;						Sector #
;						Buffer
;						Size
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadDisc

RdosReadDisc	Proc
	push ebp
	mov ebp,esp
	push edx
	push edi
;
	mov al,[ebp+8]
	mov edx,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate read_disc_nr
	jc read_disc_fail
;
	mov eax,1
	jmp read_disc_done

read_disc_fail:
	xor eax,eax

read_disc_done:
	pop edi
	pop edx
	pop ebp
	ret 16
RdosReadDisc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			WriteReadDisc
;
;		DESCRIPTION:	Write to disc
;
;		PARAMETER:		Disc #
;						Sector #
;						Buffer
;						Size
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteDisc

RdosWriteDisc	Proc
	push ebp
	mov ebp,esp
	push edx
	push edi
;
	mov al,[ebp+8]
	mov edx,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate write_disc_nr
	jc write_disc_fail
;
	mov eax,1
	jmp write_disc_done

write_disc_fail:
	xor eax,eax

write_disc_done:
	pop edi
	pop edx
	pop ebp
	ret 16
RdosWriteDisc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetRdfsInfo
;
;       DESCRIPTION:    Get basic RDFS info
;
;		PARAMETERS:		Crypt tab
;						Key tab
;						Extent size tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetRdfsInfo

RdosGetRdfsInfo	Proc near
	push ebp
	mov ebp,esp
	push gs
	push ebx
	push esi
	push edi
;
	mov esi,[ebp+8]
	mov edi,[ebp+12]
	mov ebx,[ebp+16]
	mov ax,ds
	mov gs,ax
	UserGate get_rdfs_info_nr
;
	pop edi
	pop esi
	pop ebx
	pop gs
	pop ebp
	ret 12
RdosGetRdfsInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosFormatDrive
;
;       DESCRIPTION:    Format drive
;
;		PARAMETERS:		Disc #
;						Start sector
;						Size
;						FS name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosFormatDrive

RdosFormatDrive	Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov al,[ebp+8]
	mov edx,[ebp+12]
	mov ecx,[ebp+16]
	mov edi,[ebp+20]
	UserGate format_drive_nr
;
	pop edi
	pop ebp
	ret 16
RdosFormatDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadResource
;
;       DESCRIPTION:    Read resource
;
;		PARAMETERS:		Handle
;						ID
;						Buf
;						Size
;
;		RETURNS:		Size read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosReadResource

RdosReadResource	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push esi
	push edi
;
	mov ebx,[ebp+8]
	or ebx,ebx
	jnz read_resource_handle_ok
;
	mov ebx,fs:pvModuleHandle

read_resource_handle_ok:
	mov eax,[ebp+12]
	mov edx,10
	UserGate get_dll_resource_nr
	jc read_resource_fail
;
	cmp ecx,[ebp+20]
	jbe read_resource_copy
;
	mov ecx,[ebp+20]

read_resource_copy:
	mov edi,[ebp+16]
	mov eax,ecx
	push ecx
	shr ecx,2
	rep movsd
	pop ecx
	and ecx,3
	rep movsb
	jmp read_resource_done
	
read_resource_fail:
	xor eax,eax

read_resource_done:
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosReadResource	Endp

;	extrn Startup:near

;	public _main

;_main:
;	jmp Startup

	END
