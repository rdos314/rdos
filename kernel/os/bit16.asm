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
; BIT16.ASM
; Linear 16-bit graphics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME bit16

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

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopNull
;
;		DESCRIPTION:	Null draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopNull	Proc near
	ret
LgopNull	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopNone
;
;		DESCRIPTION:	Set drawing color
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopNone	Proc near
	mov es:[edi],ax
	ret
LgopNone	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopOr
;
;		DESCRIPTION:	Or draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopOr	Proc near
	push dx
	mov dx,es:[edi]
	or dx,ax
	mov es:[edi],dx
	pop dx
	ret
LgopOr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopAnd
;
;		DESCRIPTION:	And draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAnd	Proc near
	push dx
	mov dx,es:[edi]
	and dx,ax
	mov es:[edi],dx
	pop dx
	ret
LgopAnd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopXor
;
;		DESCRIPTION:	Xor draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopXor	Proc near
	push dx
	mov dx,es:[edi]
	xor dx,ax
	mov es:[edi],dx
	pop dx
	ret
LgopXor	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopInvert
;
;		DESCRIPTION:	Invert draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvert	Proc near
	push ax
	not ax
	mov es:[edi],ax
	pop ax
	ret
LgopInvert	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopInvertOr
;
;		DESCRIPTION:	Invert or draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertOr	Proc near
	push ax
	push dx
	not ax
	mov dx,es:[edi]
	or dx,ax
	mov es:[edi],dx
	pop dx
	pop ax
	ret
LgopInvertOr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopInvertAnd
;
;		DESCRIPTION:	Invert and draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertAnd	Proc near
	push ax
	push dx
	not ax
	mov dx,es:[edi]
	and dx,ax
	mov es:[edi],dx
	pop dx
	pop ax
	ret
LgopInvertAnd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopInvertXor
;
;		DESCRIPTION:	Invert xor draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertXor	Proc near
	push ax
	push dx
	not ax
	mov dx,es:[edi]
	xor dx,ax
	mov es:[edi],dx
	pop dx
	pop ax
	ret
LgopInvertXor	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopAdd
;
;		DESCRIPTION:	Add draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAdd	Proc near
	push ax
	push bx
	push cx
	push dx
;
	mov dx,es:[edi]
;
	mov bh,ah
	mov bl,dh
	and bx,0F8F8h
	add bl,bh
	jnc lgop_add_ok1
;
	mov bl,0F8h

lgop_add_ok1:
	and dh,NOT 0F8h
	or dh,bl
	rol ax,5
	rol dx,5
;
	mov bh,ah
	mov bl,dh
	and bx,0FCFCh
	add bl,bh
	jnc lgop_add_ok2
;
	mov bl,0FCh

lgop_add_ok2:
	and dh,NOT 0FCh
	or dh,bl
	rol ax,6
	rol dx,6
;
	mov bh,ah
	mov bl,dh
	and bx,0F8F8h
	add bl,bh
	jnc lgop_add_ok3
;
	mov bl,0F8h

lgop_add_ok3:
	and dh,NOT 0F8h
	or dh,bl
	rol dx,5
	mov es:[edi],dx
;
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LgopAdd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopSub
;
;		DESCRIPTION:	Sub draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopSub	Proc near
	push ax
	push bx
	push cx
	push dx
;
	mov dx,es:[edi]
;
	mov bh,ah
	mov bl,dh
	and bx,0F8F8h
	sub bl,bh
	jnc lgop_sub_ok1
;
	xor bl,bl

lgop_sub_ok1:
	and dh,NOT 0F8h
	or dh,bl
	rol ax,5
	rol dx,5
;
	mov bh,ah
	mov bl,dh
	and bx,0FCFCh
	sub bl,bh
	jnc lgop_sub_ok2
;
	xor bl,bl

lgop_sub_ok2:
	and dh,NOT 0FCh
	or dh,bl
	rol ax,6
	rol dx,6
;
	mov bh,ah
	mov bl,dh
	and bx,0F8F8h
	sub bl,bh
	jnc lgop_sub_ok3
;
	xor bl,bl

lgop_sub_ok3:
	and dh,NOT 0F8h
	or dh,bl
	rol dx,5
	mov es:[edi],dx
;
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LgopSub	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopMul
;
;		DESCRIPTION:	Mul draw
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopMul	Proc near
	push ax
	push dx
	push si
	push di
;
	mov si,ax
	mov di,es:[edi]
;
	mov ax,si
	mov dx,di
	and ax,0F800h
	shr ax,11
	and dx,0F800h
	shr dx,11
	mul dl
	mov al,ah
	shl ax,11
	and di,NOT 0F800h
	or di,ax
;
	mov ax,si
	mov dx,di
	and ax,7E0h
	shr ax,5
	and dx,7E0h
	shr dx,5
	mul dl
	mov al,ah
	shl ax,5
	and di,NOT 7E0h
	or di,ax
;
	mov ax,si
	mov dx,di
	and ax,1Fh
	and dx,1Fh
	mul dl
	mov al,ah
	and di,NOT 1Fh
	or di,ax
;
	mov es:[edi],dx
;
	pop di
	pop si
	pop dx
	pop ax
	ret
LgopMul	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopTab
;
;		DESCRIPTION:	LGOP table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopTab:
lgt00	DW OFFSET LgopNull
lgt01	DW OFFSET LgopNone
lgt02	DW OFFSET LgopOr
lgt03	DW OFFSET LgopAnd
lgt04	DW OFFSET LgopXor
lgt05	DW OFFSET LgopInvert
lgt06	DW OFFSET LgopInvertOr
lgt07	DW OFFSET LgopInvertAnd
lgt08	DW OFFSET LgopInvertXor
lgt09	DW OFFSET LgopAdd
lgt0A	DW OFFSET LgopSub
lgt0B	DW OFFSET LgopMul
lgt0C	DW OFFSET LgopNull
lgt0D	DW OFFSET LgopNull

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetColor
;
;		DESCRIPTION:	Set color
;
;		PARAMETER:		EAX			RGB color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_color	Proc far
	push bx
	push edx
;
	mov edx,eax
	shr edx,8
	and dx,0F800h
	mov bx,dx
;
	mov dx,ax
	shr dx,5
	and dx,7E0h
	or bx,dx
;
	mov dx,ax
	shr dx,3
	and dx,1Fh
	or bx,dx
	mov ds:v_color,ebx
;
	pop edx
	pop bx
	ret
set_color	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetPixel
;
;		DESCRIPTION:	Get pixel
;
;		PARAMETER:		CX			x
;						DX			y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pixel	Proc far
	push ds
	push bx
	push edx
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	mov edx,ecx
	add edx,edx
	add eax,edx
	add eax,ds:v_app_base
	mov dx,flat_sel
	mov ds,dx
	mov ax,[eax]
	mov bx,ax
	movzx eax,bx
	and ax,0F800h
	shl eax,8
	mov dx,bx
	and dx,7E0h
	shl dx,5
	or ax,dx
	and bx,1Fh
	shl bx,3
	or ax,bx
;
	pop edx
	pop bx	
	pop ds
	ret
get_pixel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetPixel
;
;		DESCRIPTION:	Set pixel
;
;		PARAMETER:		CX			x
;						DX			y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_pixel	Proc far
	push ds
	push es
	push eax
	push bx
	push edx
	push edi
;
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	mov edi,ecx
	add edi,edi
	add edi,eax
	add edi,ds:v_app_base
	mov ax,flat_sel
	mov es,ax
	mov eax,ds:v_color
	mov bx,ds:v_lgop
	add bx,bx
	call word ptr cs:[bx].LgopTab
;
	pop edi
	pop edx
	pop bx
	pop eax
	pop es
	pop ds
	ret
set_pixel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetNative
;
;		DESCRIPTION:	Get pixels in internal format
;
;		PARAMETER:		AX			number of pixels
;						CX			x
;						DX			y
;						ES:EDI		line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_native	Proc far
	push ds
	push eax
	push bx
	push ecx
	push edx
	push esi
	push edi
;
	push ax
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	mov edx,ecx
	add edx,edx
	add eax,edx
	add eax,ds:v_app_base
	mov esi,eax
	mov dx,flat_sel
	mov ds,dx
	pop cx
;
	or cx,cx
	jz get_native_done
;
	test si,2
	jz get_native_double
;
	movs word ptr es:[edi],[esi]
	sub cx,1
	jz get_native_done

get_native_double:
	push cx
	movzx ecx,cx
	shr ecx,1
	rep movs dword ptr es:[edi],[esi]
	pop cx
	test cx,1
	jz get_native_done
;	
	movs word ptr es:[edi],[esi]

get_native_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop bx	
	pop eax
	pop ds
	ret
get_native	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetRGB
;
;		DESCRIPTION:	Get pixels in RGB format
;
;		PARAMETER:		AX			number of pixels
;						CX			x
;						DX			y
;						ES:EDI		line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_rgb	Proc far
	push ds
	push eax
	push bx
	push ecx
	push edx
	push esi
	push edi
;
	push ax
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	mov edx,ecx
	add edx,edx
	add eax,edx
	add eax,ds:v_app_base
	mov esi,eax
	mov dx,flat_sel
	mov ds,dx
	pop cx
;
	or cx,cx
	jz get_rgb_done

get_rgb_loop:
	lods word ptr [esi]
	mov bx,ax
	movzx eax,ax
	and ax,0F800h
	shl eax,8
	mov dx,bx
	and dx,7E0h
	shl dx,5
	or ax,dx
	and bx,1Fh
	shl bx,3
	or ax,bx
	stos dword ptr es:[edi]
	loop get_rgb_loop	

get_rgb_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop bx	
	pop eax
	pop ds
	ret
get_rgb	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetNative
;
;		DESCRIPTION:	Set pixels in internal format
;
;		PARAMETER:		AX			number of pixels
;						CX			x
;						DX			y
;						ES:EDI		line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_native	Proc far
	push ds
	push es
	push eax
	push bx
	push ecx
	push edx
	push esi
	push edi
;
	push ax
	mov esi,edi
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	mov edx,ecx
	add edx,edx
	add eax,edx
	add eax,ds:v_app_base
	mov edi,eax
	mov ax,es
	mov ds,ax
	mov dx,flat_sel
	mov es,dx
	pop cx
;
	or cx,cx
	jz set_native_done
;
	mov bx,ds:v_lgop
	cmp bx,LGOP_NONE
	je set_native_none
;
	add bx,bx

set_native_loop:
	lods word ptr [esi]
	call word ptr cs:[bx].LgopTab
	add edi,2
	loop set_native_loop
	jmp set_native_done

set_native_none:
	test di,2
	jz set_native_double
;
	movs word ptr es:[edi],[esi]
	sub cx,1
	jz set_native_done

set_native_double:
	push cx
	movzx ecx,cx
	shr ecx,1
	rep movs dword ptr es:[edi],[esi]
	pop cx
	test cx,1
	jz set_native_done
;	
	movs word ptr es:[edi],[esi]

set_native_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop bx	
	pop eax
	pop es
	pop ds
	ret
set_native	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetRGB
;
;		DESCRIPTION:	Set pixels in RGB format
;
;		PARAMETER:		AX			number of pixels
;						CX			x
;						DX			y
;						ES:EDI		line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rgb	Proc far
	push ds
	push es
	push eax
	push bx
	push ecx
	push edx
	push esi
	push edi
	push bp
;
	push ax
	mov esi,edi
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	mov edx,ecx
	add edx,edx
	add eax,edx
	add eax,ds:v_app_base
	mov edi,eax
	mov ax,es
	mov ds,ax
	mov dx,flat_sel
	mov es,dx
	pop cx
;
	or cx,cx
	jz set_rgb_done
;
	mov bx,ds:v_lgop
	add bx,bx

set_rgb_loop:
	lods dword ptr [esi]
	mov edx,eax
	shr edx,8
	and dx,0F800h
	mov bp,dx
	mov dx,ax
	shr dx,5
	and dx,7E0h
	or bp,dx
	mov dx,ax
	shr dx,3
	and dx,1Fh
	or bp,dx
	mov ax,bp
	call word ptr cs:[bx].LgopTab
	add edi,2
	loop set_rgb_loop

set_rgb_done:
	pop bp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop bx	
	pop eax
	pop es
	pop ds
	ret
set_rgb	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Copy
;
;		DESCRIPTION:	Copy pixels within bitmap
;
;		PARAMETER:		AX			number of pixels
;						CX			source x
;						DX			source y
;						SI			dest x
;						DI			dest y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy	Proc far
	push ds
	push es
	push eax
	push bx
	push ecx
	push edx
	push esi
	push edi
;
	push ax
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	mov edx,ecx
	add edx,edx
	add eax,edx
	add eax,ds:v_app_base
	push eax
	movzx ecx,si
	movzx edx,di
	movzx eax,ds:v_row_size
	mul edx
	mov edx,ecx
	add edx,edx
	add eax,edx
	add eax,ds:v_app_base
	pop esi
	mov edi,eax
	mov dx,flat_sel
	mov ds,dx
	mov es,dx
	pop cx
;
	or cx,cx
	jz copy_done
;
	mov bx,ds:v_lgop
	cmp bx,LGOP_NONE
	je copy_none
;
	add bx,bx

copy_loop:
	lods word ptr [esi]
	call word ptr cs:[bx].LgopTab
	add edi,2
	loop copy_loop
	jmp copy_done

copy_none:
	test di,2
	jz copy_double
;
	movs word ptr es:[edi],[esi]
	sub cx,1
	jz copy_done

copy_double:
	push cx
	movzx ecx,cx
	shr ecx,1
	rep movs dword ptr es:[edi],[esi]
	pop cx
	test cx,1
	jz copy_done
;	
	movs word ptr es:[edi],[esi]

copy_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop bx	
	pop eax
	pop es
	pop ds
	ret
copy	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SlabLgopNone
;
;		DESCRIPTION:	Copy line
;
;		PARAMETERS:		AX			Color
;						ES:EDI		Dest buffer (LFB)
;						CX			number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabLgopNone	Proc near
	push dx
	mov dx,ax
	shl eax,16
	mov ax,dx
;
	test di,2
	jz slab_lgop_none_double

slab_lgop_none_word:
	stos word ptr es:[edi]
	sub cx,1
	jz slab_lgop_none_done

slab_lgop_none_double:
	cmp cx,1
	je slab_lgop_none_word
;
	stos dword ptr es:[edi]
	sub cx,2
	jnz slab_lgop_none_double

slab_lgop_none_done:
	pop dx
	ret
SlabLgopNone	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HollowLine
;
;		DESCRIPTION:	Draw a hollow line
; 
;		PARAMETER:		CX			width
;						EDI			position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HollowLine	Proc near
	push cx
	push edi
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab
;
	mov ax,cx
	dec ax
	movzx eax,ax
	add eax,eax
	add edi,eax
;
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab
	pop edi
	pop cx
	ret
HollowLine	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FilledLine
;
;		DESCRIPTION:	Draw a filled line
; 
;		PARAMETER:		CX			width
;						EDI			position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FilledLine	Proc near
	mov bx,ds:v_lgop
	cmp bx,LGOP_NONE
	je filled_line_lgop
;
	add bx,bx
	mov eax,ds:v_color
;
	push cx
	push edi

filled_line_loop:
	call word ptr cs:[bx].LgopTab
	add edi,2
	loop filled_line_loop
;
	pop edi
	pop cx
	ret

filled_line_lgop:
	mov eax,ds:v_color
	push cx
	push edi
	call SlabLgopNone
	pop edi
	pop cx
	ret
FilledLine	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SplitLine
;
;		DESCRIPTION:	Draw a split line
; 
;		PARAMETER:		AX			line width
;						CX			gap
;						EDI			position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SplitLine	Proc near
	push cx
	push dx
	push edi
;
	sub cx,ax
	sub cx,ax
	mov dx,ax
;
	push cx
	mov cx,dx

split_left_loop:
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab
	add edi,2
	loop split_left_loop
;
	pop cx
;
	movzx eax,cx
	add eax,eax
	add edi,eax
;
	mov cx,dx

split_right_loop:
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab
	add edi,2
	loop split_right_loop
;
	pop edi
	pop dx
	pop cx
	ret
SplitLine	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Drawline
;
;		DESCRIPTION:	Draw a line
; 
;		PARAMETER:		CX			x1
;						DX			y1
;						SI			x2
;						DI			y2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_line	Proc far
	push ds
	push es
	pushad
;
	cmp si,cx
	je line_vert
;
	cmp di,dx
	je line_horiz

line_bresen:
	push si
	push di
	push dx
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	mov ebx,ecx
	add ebx,ebx
	add ebx,eax
	add ebx,ds:v_app_base
	mov ebp,ebx
	pop dx
	pop bx
	pop ax
;
	sub cx,ax
	sub dx,bx
;
	test ch,80h
	jz line_bresen_dx_pos

line_bresen_dx_neg:
	add cx,cx
	neg cx
	mov esi,-2
	jmp line_bresen_dy

line_bresen_dx_pos:
	add cx,cx
	mov esi,2

line_bresen_dy:
	test dh,80h
	jz line_bresen_dy_pos

line_bresen_dy_neg:
	add dx,dx
	neg dx
	movzx edi,ds:v_row_size
	neg edi
	jmp line_bresen_do

line_bresen_dy_pos:
	add dx,dx
	movzx edi,ds:v_row_size

line_bresen_do:
	push cx
	push dx
	movzx ecx,ax
	movzx edx,bx
	movzx eax,ds:v_row_size
	mul edx
	mov ebx,ecx
	add ebx,ebx
	add ebx,eax
	add ebx,ds:v_app_base
	pop dx
	pop cx
;
	push ebp
	mov ebp,edi
	mov edi,ebx
	mov ebx,esi
;
	push bx
	mov ax,flat_sel
	mov es,ax
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab
	pop bx
	pop esi
;
	cmp cx,dx
	jb line_bresen_dx_bigger

line_bresen_dx_bigger:
	mov ax,cx
	shr ax,1
	sub ax,dx
	neg ax

line_bresen_dx_loop:
	cmp esi,edi
	je line_done
;
	test ah,80h
	jnz line_bresen_dx_fract_neg

line_bresen_dx_fract_pos:
	add edi,ebx
	sub ax,dx
	jmp line_bresen_dx_plot

line_bresen_dx_fract_neg:
	add edi,ebp
	add ax,cx

line_bresen_dx_plot:
	push ax
	push bx
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab
	pop bx
	pop ax
	jmp line_bresen_dx_loop

line_bresen_dy_bigger:
	mov ax,dx
	shr ax,1
	sub ax,cx
	neg ax

line_bresen_dy_loop:
	cmp esi,edi
	je line_done
;
	test ah,80h
	jnz line_bresen_dy_fract_neg

line_bresen_dy_fract_pos:
	add edi,ebp
	sub ax,cx
	jmp line_bresen_dy_plot

line_bresen_dy_fract_neg:
	add edi,ebx
	add ax,dx

line_bresen_dy_plot:
	push ax
	push bx
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab
	pop bx
	pop ax
	jmp line_bresen_dy_loop

line_vert:
	mov bx,di
	cmp bx,dx
	jae line_vert_do
;
	xchg bx,dx

line_vert_do:
	movzx ecx,cx
	movzx edx,dx
	sub bx,dx
	movzx eax,ds:v_row_size
	mov esi,eax
	mul edx
	mov edi,ecx
	add edi,edi
	add edi,eax
	add edi,ds:v_app_base
	mov cx,bx
	inc cx
	mov dx,flat_sel
	mov es,dx
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color

line_vert_loop:
	call word ptr cs:[bx].LgopTab
	add edi,esi
	loop line_vert_loop
	jmp line_done

line_horiz:
	mov ax,si
	cmp ax,cx
	jae line_horiz_do
;
	xchg ax,cx

line_horiz_do:
	movzx ecx,cx
	movzx edx,dx
	movzx ebx,ax
	movzx eax,ds:v_row_size
	mul edx
	mov edi,ecx
	add edi,edi
	add edi,eax
	add edi,ds:v_app_base
	sub cx,bx
	neg cx
	inc cx
	mov dx,flat_sel
	mov es,dx
	call FilledLine

line_done:
	popad
	pop es
	pop ds
	ret
draw_line	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawRect
;
;		DESCRIPTION:	Draw a rect
; 
;		PARAMETER:		CX			x
;						DX			y
;						SI			w
;						DI			h
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rect_border_style_tab:
rb00 DW OFFSET FilledLine
rb01 DW OFFSET FilledLine

rect_mid_style_tab:
rm00 DW OFFSET HollowLine
rm01 DW OFFSET FilledLine

draw_rect	Proc far
	push ds
	push es
	pushad
;
	or si,si
	jz rect_done
;
	or di,di
	jz rect_done
;
	push si
	push di
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mov esi,eax
	mul edx
	mov edi,ecx
	add edi,edi
	add edi,eax
	add edi,ds:v_app_base
	pop dx
	pop cx
;
	mov ax,flat_sel
	mov es,ax
;
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].rect_border_style_tab
	add edi,esi
	sub dx,1
	jz rect_done

rect_mid_loop:
	cmp dx,1
	je rect_bottom
;
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].rect_mid_style_tab
	add edi,esi
	dec dx
	jmp rect_mid_loop

rect_bottom:
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].rect_border_style_tab

rect_done:
	popad
	pop es
	pop ds
	ret
draw_rect	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawEllipse
;
;		DESCRIPTION:	Draw a ellipse
; 
;		PARAMETER:		CX			x
;						DX			y
;						SI			w
;						DI			h
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

de_h2		EQU -4
de_w2		EQU -8
de_m		EQU -14
de_S		EQU -20
de_T		EQU -26
de_dSx		EQU -32
de_dTx		EQU -38
de_dSy		EQU -44
de_dTy		EQU -50
de_ddx		EQU -56
de_ddy		EQU -62
de_cnt		EQU -64
de_w		EQU -66
de_h		EQU -68
de_p0		EQU -72
de_p1		EQU -76
de_width	EQU -78
de_size		EQU -80
de_xoff		EQU -82
de_yoff		EQU -84

draw_mid_ellipse_hollow	Proc near
	mov edi,[bp].de_p0
	mov ax,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
;
	mov edi,[bp].de_p1
	mov ax,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
;
	mov word ptr [bp].de_width,1
	ret
draw_mid_ellipse_hollow	Endp

draw_mid_ellipse_filled	Proc near
	mov edi,[bp].de_p0
	mov cx,[bp].de_size
	call FilledLine
;
	mov edi,[bp].de_p1
	mov cx,[bp].de_size
	call FilledLine
;
	mov word ptr [bp].de_width,1
	ret
draw_mid_ellipse_filled	Endp

draw_last_ellipse_hollow	Proc near
	mov edi,[bp].de_p0
	mov ax,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
	ret
draw_last_ellipse_hollow	Endp

draw_last_ellipse_filled	Proc near
	mov edi,[bp].de_p0
	mov cx,[bp].de_size
	call FilledLine
	ret
draw_last_ellipse_filled	Endp

ellipse_mid_style_tab:
em00 DW OFFSET draw_mid_ellipse_hollow
em01 DW OFFSET draw_mid_ellipse_filled

ellipse_last_style_tab:
el00 DW OFFSET draw_last_ellipse_hollow
el01 DW OFFSET draw_last_ellipse_filled

draw_ellipse	Proc far
	push ds
	push es
	pushad
	mov bp,sp
	sub sp,84
;
	dec si
	shr si,1
	mov [bp].de_w,si
	mov word ptr [bp].de_width,1
	mov word ptr [bp].de_size,2
;
	dec di
	shr di,1
	mov [bp].de_h,di
	mov [bp].de_cnt,di
;
	add cx,si
	mov [bp].de_xoff,cx
	add dx,di
	mov [bp].de_yoff,dx
;
	mov ax,di
	mul di
	mov [bp].de_h2,ax
	mov [bp+2].de_h2,dx
;
	mov ax,si
	mul si
	mov [bp].de_w2,ax
	mov [bp+2].de_w2,dx
;
	movzx eax,word ptr [bp].de_h
	shl eax,1
	neg eax
	inc eax
	imul dword ptr [bp].de_w2
	mov [bp].de_m,eax
	mov [bp+4].de_m,dx
;
	mov eax,[bp].de_h2
	xor dx,dx
	add eax,eax
	adc dx,dx
	mov esi,eax
	mov di,dx
	add eax,eax
	adc dx,dx
	mov [bp].de_dTx,eax
	mov [bp+4].de_dTx,dx 
;
	add eax,esi
	adc dx,di
	mov [bp].de_dSx,eax
	mov [bp+4].de_dSx,dx
;
	mov eax,[bp].de_m
	mov dx,[bp+4].de_m
	add eax,[bp].de_w2
	adc dx,0
	add eax,eax
	adc dx,dx
	mov [bp].de_dSy,eax
	mov [bp+4].de_dSy,dx
;
	mov eax,[bp].de_w2
	xor dx,dx
	add eax,eax
	adc dx,dx
	add eax,[bp].de_dSy
	adc dx,[bp+4].de_dSy
	mov [bp].de_dTy,eax
	mov [bp+4].de_dTy,dx
;
	mov eax,[bp].de_h2
	xor dx,dx
	add eax,eax
	adc dx,dx
	add eax,[bp].de_m
	adc dx,[bp+4].de_m
	mov [bp].de_S,eax
	mov [bp+4].de_S,dx
;
	mov eax,[bp].de_m
	mov dx,[bp+4].de_m
	add eax,eax
	adc dx,dx
	add eax,[bp].de_h2
	adc dx,0
	mov [bp].de_T,eax
	mov [bp+4].de_T,dx
;
	mov eax,[bp].de_h2
	xor dx,dx
	add eax,eax
	adc dx,dx
	add eax,eax
	adc dx,dx
	mov [bp].de_ddx,eax
	mov [bp+4].de_ddx,dx
;
	mov eax,[bp].de_w2
	xor dx,dx
	add eax,eax
	adc dx,dx
	add eax,eax
	adc dx,dx
	mov [bp].de_ddy,eax
	mov [bp+4].de_ddy,dx
;
	movzx esi,ds:v_row_size
;
	movzx ecx,word ptr [bp].de_xoff
	movzx edx,word ptr [bp].de_yoff
	sub dx,[bp].de_h
	mov eax,esi
	mul edx
	mov edi,ecx
	add edi,edi
	add edi,eax
	add edi,ds:v_app_base
	mov [bp].de_p0,edi
;
	movzx ecx,word ptr [bp].de_xoff
	movzx edx,word ptr [bp].de_yoff
	add dx,[bp].de_h
	mov eax,esi
	mul edx
	mov edi,ecx
	add edi,edi
	add edi,eax
	add edi,ds:v_app_base
	mov [bp].de_p1,edi
;
	mov ax,flat_sel
	mov es,ax

ellipse_loop:
	mov eax,[bp].de_S
	mov bx,[bp+4].de_S
	mov ecx,[bp].de_T
	mov dx,[bp+4].de_T
	test bh,80h
	jz ellipse_s_pos

ellipse_s_neg:
	add eax,[bp].de_dSx
	adc bx,[bp+4].de_dSx
	mov [bp].de_S,eax
	mov [bp+4].de_S,bx
;
	add ecx,[bp].de_dTx
	adc dx,[bp+4].de_dTx
	mov [bp].de_T,ecx
	mov [bp+4].de_T,dx
;
	mov eax,[bp].de_ddx
	mov dx,[bp+4].de_ddx
	add [bp].de_dSx,eax
	adc [bp+4].de_dSx,dx
	add [bp].de_dTx,eax
	adc [bp+4].de_dTx,dx
;
	sub dword ptr [bp].de_p0,2
	sub dword ptr [bp].de_p1,2
	inc word ptr [bp].de_width
	add word ptr [bp].de_size,2
	jmp ellipse_loop

ellipse_s_pos:
	test dh,80h
	jz ellipse_t_pos

ellipse_t_neg:
	add eax,[bp].de_dSx
	adc bx,[bp+4].de_dSx
	add eax,[bp].de_dSy
	adc bx,[bp+4].de_dSy
	mov [bp].de_S,eax
	mov [bp+4].de_S,bx
;
	add ecx,[bp].de_dTx
	adc dx,[bp+4].de_dTx
	add ecx,[bp].de_dTy
	adc dx,[bp+4].de_dTy
	mov [bp].de_T,ecx
	mov [bp+4].de_T,dx
;
	mov eax,[bp].de_ddx
	mov dx,[bp+4].de_ddx
	add [bp].de_dSx,eax
	adc [bp+4].de_dSx,dx
	add [bp].de_dTx,eax
	adc [bp+4].de_dTx,dx
;
	mov eax,[bp].de_ddy
	mov dx,[bp+4].de_ddy
	add [bp].de_dSy,eax
	adc [bp+4].de_dSy,dx
	add [bp].de_dTy,eax
	adc [bp+4].de_dTy,dx
;
	sub dword ptr [bp].de_p0,2
	sub dword ptr [bp].de_p1,2
	inc word ptr [bp].de_width
	add word ptr [bp].de_size,2
;
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].ellipse_mid_style_tab
	add [bp].de_p0,esi
	sub [bp].de_p1,esi
;
	sub word ptr [bp].de_cnt,1
	jz ellipse_done
	jmp ellipse_loop

ellipse_t_pos:
	add eax,[bp].de_dSy
	adc bx,[bp+4].de_dSy
	mov [bp].de_S,eax
	mov [bp+4].de_S,bx
;
	add ecx,[bp].de_dTy
	adc dx,[bp+4].de_dTy
	mov [bp].de_T,ecx
	mov [bp+4].de_T,dx
;
	mov eax,[bp].de_ddy
	mov dx,[bp+4].de_ddy
	add [bp].de_dSy,eax
	adc [bp+4].de_dSy,dx
	add [bp].de_dTy,eax
	adc [bp+4].de_dTy,dx
;
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].ellipse_mid_style_tab
	add [bp].de_p0,esi
	sub [bp].de_p1,esi
;
	sub word ptr [bp].de_cnt,1
	jnz ellipse_loop

ellipse_done:
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].ellipse_last_style_tab
;
	add sp,84
	popad
	pop es
	pop ds
	ret
draw_ellipse	Endp

error	Proc far
	stc
	ret
error	Endp

	public BitmapTab16

BitmapTab16:
mt00 DW OFFSET error,				video_code_sel
mt01 DW OFFSET error,				video_code_sel
mt02 DW OFFSET error,				video_code_sel
mt03 DW OFFSET error,				video_code_sel
mt04 DW OFFSET error,				video_code_sel
mt05 DW OFFSET error,				video_code_sel
mt06 DW OFFSET error,				video_code_sel
mt07 DW OFFSET error,				video_code_sel
mt08 DW OFFSET error,				video_code_sel
mt09 DW OFFSET error,				video_code_sel
mt0A DW OFFSET error,				video_code_sel
mt0B DW OFFSET error,				video_code_sel
mt0C DW OFFSET error,				video_code_sel
mt0D DW OFFSET error,				video_code_sel
mt0E DW OFFSET error,				video_code_sel
mt0F DW OFFSET error,				video_code_sel
mt10 DW OFFSET error,				video_code_sel
mt11 DW OFFSET error,				video_code_sel
mt12 DW OFFSET error,				video_code_sel
mt13 DW OFFSET set_color,			video_code_sel
mt14 DW OFFSET get_pixel,			video_code_sel
mt15 DW OFFSET set_pixel,			video_code_sel
mt16 DW OFFSET get_native,			video_code_sel
mt17 DW OFFSET get_rgb,				video_code_sel
mt18 DW OFFSET set_native,			video_code_sel
mt19 DW OFFSET set_rgb,				video_code_sel
mt1A DW OFFSET copy,				video_code_sel
mt1B DW OFFSET draw_line,			video_code_sel
mt1C DW OFFSET draw_rect,			video_code_sel
mt1D DW OFFSET draw_ellipse,		video_code_sel

code	ENDS

	END

