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
; BIT24.ASM
; Linear 24-bit graphics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME bit24

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\driver.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\user.inc
INCLUDE ..\os\os.inc
INCLUDE video.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;			Global parameter usage
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


curr_x  EQU -4
curr_y  EQU -2

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopNull
;
;		DESCRIPTION:	Null draw
;
;		PARAMETERS:		EAX			Color
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
;		DESCRIPTION:	Copy draw
;
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopNone	Proc near
	mov es:[edi],al
	ror eax,8
	mov es:[edi+1],ax
	rol eax,8
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopOr	Proc near
	push eax
	push edx
	and eax,0FFFFFFh
	mov edx,es:[edi]
	or edx,eax
	mov es:[edi],edx
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAnd	Proc near
	push eax
	push edx
	or eax,0FF000000h
	mov edx,es:[edi]
	and edx,eax
	mov es:[edi],edx
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopXor	Proc near
	push eax
	push edx
	and eax,0FFFFFFh
	mov edx,es:[edi]
	xor edx,eax
	mov es:[edi],edx
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvert	Proc near
	push eax
	push edx
	not eax
	mov es:[edi],al
	ror eax,8
	mov es:[edi+1],ax
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertOr	Proc near
	push eax
	push edx
	not eax
	and eax,0FFFFFFh
	mov edx,es:[edi]
	or edx,eax
	mov es:[edi],edx
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertAnd	Proc near
	push eax
	push edx
	not eax
	or eax,0FF000000h
	mov edx,es:[edi]
	and edx,eax
	mov es:[edi],edx
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopInvertXor	Proc near
	push eax
	push edx
	not eax
	and eax,0FFFFFFh
	mov edx,es:[edi]
	xor edx,eax
	mov es:[edi],edx
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAdd	Proc near
	push eax
	push edx
	mov edx,es:[edi]
;
	add dl,al
	jnc lgop_add_ok1
	mov dl,0FFh
lgop_add_ok1:
	ror eax,8
	ror edx,8
;
	add dl,al
	jnc lgop_add_ok2
	mov dl,0FFh
lgop_add_ok2:
	ror eax,8
	ror edx,8
;
	add dl,al
	jnc lgop_add_ok3
	mov dl,0FFh
lgop_add_ok3:
	rol edx,16
	mov es:[edi],edx
;
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopSub	Proc near
	push eax
	push edx
	mov edx,es:[edi]
;
	sub dl,al
	jnc lgop_sub_ok1
	xor dl,dl
lgop_sub_ok1:
	ror eax,8
	ror edx,8
;
	sub dl,al
	jnc lgop_sub_ok2
	xor dl,dl
lgop_sub_ok2:
	ror eax,8
	ror edx,8
;
	sub dl,al
	jnc lgop_sub_ok3
	xor dl,dl
lgop_sub_ok3:
	rol edx,16
	mov es:[edi],edx
;
	pop edx
	pop eax
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
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopMul	Proc near
	push eax
	push ebx
	push ecx
	mov ebx,eax
	mov ecx,es:[edi]
;
	mul cl
	mov cl,ah
	ror ebx,8
	ror ecx,8
;
	mov al,bl
	mul cl
	mov cl,ah
	ror ebx,8
	ror ecx,8
;
	mov al,bl
	mul cl
	mov cl,ah
	rol ecx,16
;
	mov es:[edi],ecx
	pop ecx
	pop ebx
	pop eax
	ret
LgopMul	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopStipple
;
;		DESCRIPTION:	Stipple draw
;
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopStipple	Proc near
	ret
LgopStipple	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopAlpha
;
;		DESCRIPTION:	Alpha draw
;
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopAlpha	Proc near
	push eax
	push ebx
	push ecx
	push edx
;
	mov ebx,eax
	mov ecx,es:[edi]
	mov edx,eax
	rol edx,8
	sub dl,80h
	neg dl
;
	mov al,cl
	mul dl
	ror ax,7
	add al,bl
	mov cl,al
	ror ebx,8
	ror ecx,8
;
	mov al,cl
	mul dl
	ror ax,7
	add al,bl
	mov cl,al
	ror ebx,8
	ror ecx,8
;
	mov al,cl
	mul dl
	ror ax,7
	add al,bl
	mov cl,al
	rol ecx,16
;
	mov es:[edi],ecx
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
LgopAlpha	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopTap
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
lgt0C	DW OFFSET LgopStipple
lgt0D	DW OFFSET LgopAlpha

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
	mov ds:v_color,eax
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
	push edx
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	imul edx
	mov edx,ecx
	add edx,edx
	add edx,ecx
	add eax,edx
	add eax,ds:v_app_base
	mov dx,flat_sel
	mov ds,dx
	mov eax,[eax]
	and eax,0FFFFFFh
	pop edx	
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
	push bp
	mov bp,sp
	sub sp,4
	mov [bp].curr_x,cx
	mov [bp].curr_y,dx	
;
    cmp cx,ds:v_x_min
    jl set_pixel_done
;
    cmp dx,ds:v_y_min
    jl set_pixel_done
;
    cmp cx,ds:v_x_max
    jg set_pixel_done
;
    cmp dx,ds:v_y_max
    jg set_pixel_done
;
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	imul edx
	mov edi,ecx
	add edi,edi
	add edi,ecx
	add edi,eax
	add edi,ds:v_app_base
	mov ax,flat_sel
	mov es,ax
	mov eax,ds:v_color
	mov bx,ds:v_lgop
	add bx,bx
	call word ptr cs:[bx].LgopTab

set_pixel_done:
    add sp,4
    pop bp
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
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	imul edx
	mov edx,ecx
	add edx,edx
	add edx,ecx
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
	movzx ecx,cx
	mov eax,ecx
	add ecx,ecx
	add ecx,eax
;
	test si,1
	jz get_native_even
;
	movs byte ptr es:[edi],[esi]
	sub ecx,1
	jz get_native_done

get_native_even:
	cmp ecx,2
	jb get_native_last
;
	test si,2
	jz get_native_double
;
	movs word ptr es:[edi],[esi]
	sub ecx,2

get_native_double:
	push cx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	pop cx
	and ecx,3

get_native_last:
	rep movs byte ptr es:[edi],[esi]

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
	push ecx
	push edx
	push esi
	push edi
;
	push ax
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	imul edx
	mov edx,ecx
	add edx,edx
	add edx,ecx
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
	movzx ax,byte ptr [esi+2]
	shl eax,16
	mov ax,[esi]
	add esi,3
	stos dword ptr es:[edi]
	loop get_rgb_loop

get_rgb_done:
	pop edi
	pop esi
	pop edx
	pop ecx
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
	pushad
	mov bp,sp
	sub sp,4
	mov [bp].curr_x,cx
	mov [bp].curr_y,dx
;
    cmp dx,ds:v_y_min
    jl set_native_done
;
    cmp dx,ds:v_y_max
    jg set_native_done

set_native_buf_loop:
    cmp cx,ds:v_x_min
    jge set_native_start_ok

set_native_adv_buf:
    inc cx
    add edi,3
    sub ax,1
    jnz set_native_buf_loop
    jmp set_native_done

set_native_start_ok:
    mov bx,ds:v_x_max
    sub bx,cx
    inc bx
    cmp ax,bx
    jc set_native_do
;
    mov ax,bx
    
set_native_do:
    or ax,ax
    jz set_native_done
;
	push ax
	mov esi,edi
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	imul edx
	mov edx,ecx
	add edx,edx
	add edx,ecx
	add eax,edx
	add eax,ds:v_app_base
	mov edi,eax
	mov bx,ds:v_lgop
	mov ax,es
	mov ds,ax
	mov dx,flat_sel
	mov es,dx
	pop cx
;
	or cx,cx
	jz set_native_done
;
	cmp bx,LGOP_NONE
	je set_native_none
;
	add bx,bx

set_native_loop:
	movzx ax,byte ptr [esi+2]
	shl eax,16
	mov ax,[esi]
	add esi,3
	call word ptr cs:[bx].LgopTab
	add edi,3
	inc word ptr [bp].curr_x
	loop set_native_loop
	jmp set_native_done

set_native_none:
	movzx ecx,cx
	mov eax,ecx
	add ecx,ecx
	add ecx,eax
;
	test di,1
	jz set_native_even
;
	movs byte ptr es:[edi],[esi]
	sub ecx,1
	jz set_native_done

set_native_even:
	cmp ecx,2
	jb set_native_last
;
	test di,2
	jz set_native_double
;
	movs word ptr es:[edi],[esi]
	sub ecx,2

set_native_double:
	push cx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	pop cx
	and ecx,3

set_native_last:
	rep movs byte ptr es:[edi],[esi]

set_native_done:
    add sp,4
	popad
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
	pushad
	mov bp,sp
	sub sp,4
	mov [bp].curr_x,cx
	mov [bp].curr_y,dx
;
    cmp dx,ds:v_y_min
    jl set_rgb_done
;
    cmp dx,ds:v_y_max
    jg set_rgb_done

set_rgb_buf_loop:
    cmp cx,ds:v_x_min
    jge set_rgb_start_ok

set_rgb_adv_buf:
    inc cx
    add edi,3
    sub ax,1
    jnz set_rgb_buf_loop
    jmp set_rgb_done

set_rgb_start_ok:
    mov bx,ds:v_x_max
    sub bx,cx
    inc bx
    cmp ax,bx
    jc set_rgb_do
;
    mov ax,bx
    
set_rgb_do:
    or ax,ax
    jz set_rgb_done
;
	push ax
	mov esi,edi
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	imul edx
	mov edx,ecx
	add edx,edx
	add edx,ecx
	add eax,edx
	add eax,ds:v_app_base
	mov edi,eax
	mov bx,ds:v_lgop
	mov ax,es
	mov ds,ax
	mov dx,flat_sel
	mov es,dx
	pop cx
;
	or cx,cx
	jz set_rgb_done
;
	add bx,bx

set_rgb_loop:
	lods dword ptr [esi]
	call word ptr cs:[bx].LgopTab
	add edi,3
	inc word ptr [bp].curr_x
	loop set_rgb_loop

set_rgb_done:
    add sp,4
	popad
	pop es
	pop ds
	ret
set_rgb	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetLine
;
;		DESCRIPTION:	Get line buffer ptr
;
;		PARAMETER:		CX			x
;						DX			y
;
;		RETURNS:		ES:EDI		line buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_line	Proc far
	push ds
	push eax
	push ecx
	push edx
;
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	imul edx
	mov edx,ecx
	add edx,edx
	add edx,ecx
	add eax,edx
	add eax,ds:v_app_base
	mov edi,eax
	mov ax,flat_sel
	mov es,ax
;
	pop edx
	pop ecx
	pop eax
	pop ds
	ret
get_line	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SlabLgopNone
;
;		DESCRIPTION:	Copy line
;
;		PARAMETERS:		EAX			Color
;						ES:EDI		Dest buffer (LFB)
;						CX			number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabLgopNone	Proc near
	push edx
	test di,1
	jz slab_lgop_none_even

slab_lgop_none_odd:
	stos byte ptr es:[edi]
	mov dl,al
	rol eax,8
	mov al,dl
	ror eax,16
	stos word ptr es:[edi]
	rol eax,8
	sub cx,1
	jz slab_lgop_none_done

slab_lgop_none_even:
	test di,2
	jz slab_lgop_none_double

slab_lgop_none_word:
	cmp cx,1
	jbe slab_lgop_none_last
;
	stos word ptr es:[edi]
	mov dx,ax
	ror eax,16
	rol edx,16
	mov dl,al
	mov dh,al
	ror edx,8
	mov eax,edx
	stos dword ptr es:[edi]
	ror eax,8
	sub cx,2

slab_lgop_none_double:
	cmp cx,3
	jbe slab_lgop_none_word
;
	mov dl,al
	rol eax,8
	mov al,dl
	ror eax,8
	stos dword ptr es:[edi]
	ror eax,8
	mov dl,al
	rol eax,8
	mov al,dl
	ror eax,8
	stos dword ptr es:[edi]
	ror eax,8
	mov dl,al
	rol eax,8
	mov al,dl
	ror eax,8
	stos dword ptr es:[edi]
	ror eax,8
	sub cx,4
	jnc slab_lgop_none_double

slab_lgop_none_last:
	or cx,cx
	jz slab_lgop_none_done
;
	stos word ptr es:[edi]
	ror eax,16
	stos byte ptr es:[edi]

slab_lgop_none_done:
	pop edx
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
	push word ptr [bp].curr_x
	push cx
	push edi
;
    mov ax,[bp].curr_y
    cmp ax,ds:v_y_min
    jl hollow_line_done
;
    cmp ax,ds:v_y_max
    jg hollow_line_done
;
    mov ax,[bp].curr_x
	cmp ax,ds:v_x_max
	jg hollow_line_done
;
    cmp ax,ds:v_x_min
    jl hollow_line_first_done
;
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab

hollow_line_first_done:
	mov ax,cx
	dec ax
	mov bx,ax
	add ax,ax
	add ax,bx
	movzx eax,ax
	add edi,eax
;
    mov ax,[bp].curr_x
    add ax,cx
    dec ax
    cmp ax,ds:v_x_min
    jl hollow_line_done
;
    cmp ax,ds:v_x_max
    jg hollow_line_done
;
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab

hollow_line_done:
	pop edi
	pop cx
	pop word ptr [bp].curr_x
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
	push word ptr [bp].curr_x
	push cx
	push edi
;
    mov ax,[bp].curr_y
    cmp ax,ds:v_y_min
    jl filled_line_done
;
    cmp ax,ds:v_y_max
    jg filled_line_done
;
    mov ax,[bp].curr_x
	cmp ax,ds:v_x_max
	jg filled_line_done
    
filled_line_buf_loop:
    cmp ax,ds:v_x_min
    jge filled_line_start_ok

filled_line_adv_buf:
    inc ax
    add edi,3
    sub cx,1
    jnz filled_line_buf_loop
    jmp filled_line_done

filled_line_start_ok:
    mov bx,ds:v_x_max
    sub bx,ax
    inc bx
    cmp cx,bx
    jc filled_line_do
;
    mov cx,bx
    
filled_line_do:
	or cx,cx
	jz filled_line_done
;
    mov [bp].curr_x,ax
;
	mov bx,ds:v_lgop
	cmp bx,LGOP_NONE
	je filled_line_lgop
;
	add bx,bx
	mov eax,ds:v_color

filled_line_loop:
	call word ptr cs:[bx].LgopTab
	inc word ptr [bp].curr_x
	add edi,3
	loop filled_line_loop
	jmp filled_line_done

filled_line_lgop:
	mov eax,ds:v_color
	call SlabLgopNone

filled_line_done:
	pop edi
	pop cx
	pop word ptr [bp].curr_x
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
	push word ptr [bp].curr_x
	push cx
	push dx
	push edi
;
    mov bx,[bp].curr_y
    cmp bx,ds:v_y_min
    jl split_line_done
;
    cmp bx,ds:v_y_max
    jg split_line_done
;
    mov bx,[bp].curr_x
    cmp bx,ds:v_x_max
    jg split_line_done
;
	sub cx,ax
	sub cx,ax
	mov dx,ax
;
	push cx
	mov cx,dx

split_left_loop:
    mov bx,[bp].curr_x
    cmp bx,ds:v_x_min
    jl split_left_next
;
    cmp bx,ds:v_x_max
    jg split_left_next
;
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab

split_left_next:
	inc word ptr [bp].curr_x
	add edi,3
	loop split_left_loop
;
	pop cx
    add [bp].curr_x,cx
;
	mov ax,cx
	add ax,ax
	add ax,cx
	movzx eax,ax
	add edi,eax
;
	mov cx,dx

split_right_loop:
    mov bx,[bp].curr_x
    cmp bx,ds:v_x_min
    jl split_right_next
;
    cmp bx,ds:v_x_max
    jg split_right_next
;
	mov bx,ds:v_lgop
	add bx,bx
	mov eax,ds:v_color
	call word ptr cs:[bx].LgopTab

split_right_next:
	inc word ptr [bp].curr_x
	add edi,3
	loop split_right_loop

split_line_done:
	pop edi
	pop dx
	pop cx
	pop word ptr [bp].curr_x
	ret
SplitLine	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawMask
;
;		DESCRIPTION:	Draw a mask
; 
;		PARAMETER:		AX			source row size
;						EBX			color
;						ECX			source x + y << 16
;						EDX			dest x + y << 16
;						SI			width
;						ES:EDI		1-bit mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_mask_line	Proc far
	push es
	push fs
	pushad
	mov bp,sp
	sub sp,4	
	mov [bp].curr_x,edx
;
    push ax
    mov ax,[bp].curr_y
    cmp ax,ds:v_y_min
    jl draw_mask_pop_done
;
    cmp ax,ds:v_y_max
    jg draw_mask_pop_done

draw_mask_buf_loop:
    cmp dx,ds:v_x_min
    jge draw_mask_start_ok

draw_mask_adv_buf:
    inc cx
    inc dx
    sub si,1
    jnz draw_mask_buf_loop
    jmp draw_mask_pop_done

draw_mask_start_ok:
    mov ax,ds:v_x_max
    sub ax,dx
    inc ax
    cmp si,ax
    jc draw_mask_do
;
    mov ax,bx
    jmp draw_mask_do

draw_mask_pop_done:
    pop ax
    jmp draw_mask_line_done
    
draw_mask_do:
    pop ax
    or si,si
    jz draw_mask_line_done
;
    push bp
	push ebx
	xchg ecx,edx
	movsx ebx,dx
	ror edx,16
	movsx edx,dx
	movzx eax,ax
	imul edx
	shl eax,3
	add eax,ebx
	push eax
;
	movsx ebp,cx
	ror ecx,16
	movsx edx,cx
	movzx eax,ds:v_row_size
	imul edx
	mov edx,ebp
	add edx,edx
	add edx,ebp
	add eax,edx
	add eax,ds:v_app_base
;
	pop ebp
	mov cl,bl
	and cl,7
	shr ebp,3
	add ebp,edi
;
	xchg esi,ebp
	mov edi,eax
;
	mov ax,es
	mov fs,ax
	mov ax,flat_sel
	mov es,ax
	pop eax
	mov bx,bp
	pop bp

draw_mask_line_loop:
	mov ch,8
	mov dx,fs:[esi]
	ror dx,cl

draw_mask_bit_loop:
	rcr dl,1
	jnc draw_mask_line_next
;
    push bx
	mov bx,ds:v_lgop
	add bx,bx
	call word ptr cs:[bx].LgopTab
	pop bx

draw_mask_line_next:
	add edi,3
    inc word ptr [bp].curr_x
	sub bx,1
	jz draw_mask_line_done
;
	sub ch,1
	jnz draw_mask_bit_loop
;
	inc esi
	jmp draw_mask_line_loop

draw_mask_line_done:
    add sp,4
	popad
	pop fs
	pop es
	ret
draw_mask_line	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawSprite
;
;		DESCRIPTION:	Draw a sprite
; 
;		PARAMETER:		ECX			x + y << 16
;						DX			width
;						ES:ESI		sprite data
;						ES:EDI		1-bit mask bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_sprite_line    Proc far
	pushad
	mov bp,sp
	sub sp,4
	mov [bp].curr_x,ecx
;
    mov bx,[bp].curr_y
    cmp bx,ds:v_y_min
    jl draw_sprite_done
;
    cmp bx,ds:v_y_max
    jg draw_sprite_done
;
    push ax
	push dx
	movsx ebx,cx
	ror ecx,16
	movsx edx,cx
	movzx eax,ds:v_row_size
	imul edx
	mov edx,ebx
	add edx,edx
	add edx,ebx
	add eax,edx
	add eax,ds:v_app_base
	mov ebx,eax
	xchg ebx,edi
	pop cx
	pop dx
    and dl,7
;
	mov ax,ds:v_lgop
	cmp ax,LGOP_NONE
	je draw_sprite_none
;
    or dl,dl
    jz draw_sprite_lgop_prep
;
    push cx
    mov cl,dl
    mov dl,es:[ebx]
    rcr dl,cl
    mov dh,8
    sub dh,cl
    pop cx
    jmp draw_sprite_lgop_loop

draw_sprite_lgop_prep:
    mov dh,8
	mov dl,es:[ebx]

draw_sprite_lgop_loop:
	rcr dl,1
	jnc draw_sprite_lgop_next
;
    mov ax,[bp].curr_x
    cmp ax,ds:v_x_min
    jl draw_sprite_lgop_next
;
    cmp ax,ds:v_x_max
    jg draw_sprite_lgop_next
;
	mov eax,es:[esi]
    push bx
	mov bx,ds:v_lgop
	add bx,bx
	call word ptr cs:[bx].LgopTab
	pop bx

draw_sprite_lgop_next:
	add esi,3
	add edi,3
	inc word ptr [bp].curr_x
	sub cx,1
	jz draw_sprite_done
;
	sub dh,1
	jnz draw_sprite_lgop_loop
;
	inc ebx
	mov dh,8
	mov dl,es:[ebx]	
	jmp draw_sprite_lgop_loop

draw_sprite_none:
    or dl,dl
    jz draw_sprite_none_prep
;
    push cx
    mov cl,dl
    mov dl,es:[ebx]
    rcr dl,cl
    mov dh,8
    sub dh,cl
    pop cx
    jmp draw_sprite_none_loop

draw_sprite_none_prep:
	mov dl,es:[ebx]
	mov dh,8

draw_sprite_none_loop:
	rcr dl,1
	jnc draw_sprite_none_next
;
    mov ax,[bp].curr_x
    cmp ax,ds:v_x_min
    jl draw_sprite_none_next
;
    cmp ax,ds:v_x_max
    jg draw_sprite_none_next
;
	mov al,es:[esi]
	mov es:[edi],al
	mov ax,es:[esi+1]
	mov es:[edi+1],ax

draw_sprite_none_next:
	add esi,3
	add edi,3
	inc word ptr [bp].curr_x
	sub cx,1
	jz draw_sprite_done
;
	sub dh,1
	jnz draw_sprite_none_loop
;
	inc ebx
	mov dh,8
	mov dl,es:[ebx]	
	jmp draw_sprite_none_loop

draw_sprite_done:
    add sp,4
	popad
    ret
draw_sprite_line    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawString
;
;		DESCRIPTION:	Draw a string
; 
;		PARAMETER:		CX			x
;						DX			y
;						ES:EDI		string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ds_dest_y		EQU -6
ds_dest_x		EQU -8
ds_cnt			EQU -10
ds_src_x		EQU -12
ds_row_size		EQU -14
ds_width		EQU -16

draw_string	Proc far
	push es
	push fs
	push gs
	pushad
	mov bp,sp
	sub sp,16
;
	mov ax,es
	mov fs,ax
	mov ax,flat_sel
	mov es,ax
;
	mov [bp].curr_x,cx
	mov [bp].curr_y,dx
	mov [bp].ds_dest_x,cx
	mov [bp].ds_dest_y,dx

draw_string_loop:
	mov al,fs:[edi]
	or al,al
	jz draw_string_ok
;
	inc edi
	push edi
;
	mov bx,ds:v_font
	GetCharMask
	jc draw_string_char_next
;
	mov ax,es
	mov gs,ax
	mov ax,flat_sel
	mov es,ax
	mov [bp].ds_row_size,si
	mov word ptr [bp].ds_src_x,0
	mov [bp].ds_width,cx
	mov cx,dx
	or cx,cx
	jz draw_string_char_next
;
	movsx esi,word ptr [bp].ds_src_x
	sar esi,3
	add esi,edi
;
	movsx ebx,word ptr [bp].ds_dest_x
	mov [bp].curr_x,bx
	movsx edx,word ptr [bp].ds_dest_y
	mov [bp].curr_y,dx
	movzx eax,word ptr ds:v_row_size
	imul edx
	mov edx,ebx
	add edx,edx
	add edx,ebx
	add eax,edx
	add eax,ds:v_app_base
	mov edi,eax
;
	mov bx,ds:v_lgop
	cmp bx,LGOP_NONE
	je draw_string_none

draw_string_char_loop:
	push cx
	push esi
	push edi
;
    mov cx,[bp].curr_y
    cmp cx,ds:v_y_min
    jl draw_string_line_next
;
    cmp cx,ds:v_y_max
    jg draw_string_line_next
;
	mov cx,[bp].ds_width
	mov eax,ds:v_color

draw_string_line_loop:
	mov dh,8
	mov dl,gs:[esi]

draw_string_bit_loop:
	rcr dl,1
	jnc draw_string_bit_next
;
    mov bx,[bp].curr_x
    cmp bx,ds:v_x_min
    jl draw_string_bit_next
;
    cmp bx,ds:v_x_max
    jg draw_string_bit_next
;
	mov bx,ds:v_lgop
	add bx,bx
	call word ptr cs:[bx].LgopTab

draw_string_bit_next:
	add edi,3
	inc word ptr [bp].curr_x
	sub cx,1
	jz draw_string_line_next
;
	sub dh,1
	jnz draw_string_bit_loop
;
	inc esi
	jmp draw_string_line_loop

draw_string_line_next:
    mov ax,[bp].ds_dest_x
    mov [bp].curr_x,ax
    inc word ptr [bp].curr_y
	pop edi
	pop esi
	pop cx
	movzx eax,ds:v_row_size
	add edi,eax
	movzx eax,word ptr [bp].ds_row_size
	add esi,eax
	sub cx,1
	jnz draw_string_char_loop

draw_string_char_done:
	mov ax,[bp].ds_width
	add [bp].ds_dest_x,ax

draw_string_char_next:
	pop edi
	jmp draw_string_loop

draw_string_none:

draw_string_none_char_loop:
	push cx
	push esi
	push edi
;
    mov cx,[bp].curr_y
    cmp cx,ds:v_y_min
    jl draw_string_none_line_next
;
    cmp cx,ds:v_y_max
    jg draw_string_none_line_next
;
	mov cx,[bp].ds_width
	mov eax,ds:v_color

draw_string_none_line_loop:
	mov dh,8
	mov dl,gs:[esi]

draw_string_none_bit_loop:
	rcr dl,1
	jnc draw_string_none_bit_next
;
    mov bx,[bp].curr_x
    cmp bx,ds:v_x_min
    jl draw_string_none_bit_next
;
    cmp bx,ds:v_x_max
    jg draw_string_none_bit_next
;
	mov es:[edi],al
	ror eax,8
	mov es:[edi+1],ax
	rol eax,8

draw_string_none_bit_next:
	add edi,3
	inc word ptr [bp].curr_x
	sub cx,1
	jz draw_string_none_line_next
;
	sub dh,1
	jnz draw_string_none_bit_loop
;
	inc esi
	jmp draw_string_none_line_loop

draw_string_none_line_next:
    mov ax,[bp].ds_dest_x
    mov [bp].curr_x,ax
    inc word ptr [bp].curr_y
	pop edi
	pop esi
	pop cx
	movzx eax,ds:v_row_size
	add edi,eax
	movzx eax,word ptr [bp].ds_row_size
	add esi,eax
	sub cx,1
	jnz draw_string_none_char_loop

draw_string_none_char_done:
	mov ax,[bp].ds_width
	add [bp].ds_dest_x,ax

draw_string_none_char_next:
	pop edi
	jmp draw_string_loop

draw_string_ok:
	clc

draw_string_done:
	add sp,16
	popad
	pop gs
	pop fs
	pop es
	ret
draw_string	Endp

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

dl_pos EQU -8

draw_line	Proc far
	push ds
	push es
	pushad
	mov bp,sp
	sub sp,8
;
	cmp si,cx
	je line_vert
;
	cmp di,dx
	je line_horiz

line_bresen:
	cmp di,dx
	jae line_bresen_magn_ok
;
	xchg cx,si
	xchg dx,di

line_bresen_magn_ok:
	mov [bp].curr_x,cx
	mov [bp].curr_y,dx
	push si
	push di
	push dx
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	imul edx
	mov ebx,ecx
	add ebx,ebx
	add ebx,ecx
	add ebx,eax
	add ebx,ds:v_app_base
	mov [bp].dl_pos,ebx
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
	mov esi,-3
	jmp line_bresen_dy

line_bresen_dx_pos:
	add cx,cx
	mov esi,3

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
	movsx ecx,ax
	movsx edx,bx
	movzx eax,ds:v_row_size
	imul edx
	mov ebx,ecx
	add ebx,ebx
	add ebx,ecx
	add ebx,eax
	add ebx,ds:v_app_base
	pop dx
	pop cx
;
	push dword ptr [bp].dl_pos
	mov [bp].dl_pos,edi
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
	add edi,[bp].dl_pos
	add ax,cx

line_bresen_dx_plot:
	cmp edi,ds:v_app_base
	jb line_done
;
	sub esi,[bp].dl_pos
	cmp esi,edi
	jae line_done
;
	add esi,[bp].dl_pos
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
	add edi,[bp].dl_pos
	sub ax,cx
	jmp line_bresen_dy_plot

line_bresen_dy_fract_neg:
	add edi,ebx
	add ax,dx

line_bresen_dy_plot:
	cmp edi,ds:v_app_base
	jb line_done
;
	sub esi,[bp].dl_pos
	cmp esi,edi
	jae line_done
;
	add esi,[bp].dl_pos
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
	mov [bp].curr_x,cx
	mov [bp].curr_y,dx
;
	cmp cx,ds:v_x_max
	jg line_done
;
    cmp cx,ds:v_x_min
    jl line_done
;
	movsx ecx,cx
	movsx edx,dx
	sub bx,dx
	movzx eax,ds:v_row_size
	mov esi,eax
	imul edx
	mov edi,ecx
	add edi,edi
	add edi,ecx
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
	mov dx,[bp].curr_y
    cmp dx,ds:v_y_min
    jl line_vert_next
;
    cmp dx,ds:v_y_max
    jg line_vert_next
;
	call word ptr cs:[bx].LgopTab

line_vert_next:
	add edi,esi
	inc word ptr [bp].curr_y
	loop line_vert_loop
	jmp line_done

line_horiz:
	mov ax,si
	cmp ax,cx
	jae line_horiz_do
;
	xchg ax,cx

line_horiz_do:
	mov [bp].curr_x,cx
	mov [bp].curr_y,dx
	movsx ecx,cx
	movsx edx,dx
	movzx ebx,ax
	movzx eax,ds:v_row_size
	imul edx
	mov edi,ecx
	add edi,edi
	add edi,ecx
	add edi,eax
	add edi,ds:v_app_base
	sub cx,bx
	neg cx
	inc cx
	mov dx,flat_sel
	mov es,dx
	call FilledLine

line_done:
    add sp,8
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
	mov bp,sp
	sub sp,4
	mov [bp].curr_x,cx
	mov [bp].curr_y,dx
;
	or si,si
	jz rect_done
;
	or di,di
	jz rect_done
;
	push si
	push di
	movsx ecx,cx
	movsx edx,dx
	movzx eax,ds:v_row_size
	mov esi,eax
	imul edx
	mov edi,ecx
	add edi,edi
	add edi,ecx
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
	inc word ptr [bp].curr_y
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
	inc word ptr [bp].curr_y
	add edi,esi
	dec dx
	jmp rect_mid_loop

rect_bottom:
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].rect_border_style_tab

rect_done:
    add sp,4
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

de_h2		EQU -8
de_w2		EQU -12
de_m		EQU -18
de_S		EQU -24
de_T		EQU -30
de_dSx		EQU -36
de_dTx		EQU -42
de_dSy		EQU -48
de_dTy		EQU -54
de_ddx		EQU -60
de_ddy		EQU -66
de_cnt		EQU -68
de_w		EQU -70
de_h		EQU -72
de_p0		EQU -76
de_p1		EQU -80
de_width	EQU -82
de_size		EQU -84
de_y0		EQU -86
de_y1		EQU -88

draw_mid_ellipse_hollow	Proc near
    mov ax,[bp].de_y0
    mov [bp].curr_y,ax
	mov edi,[bp].de_p0
	mov ax,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
;
    mov ax,[bp].de_y1
    mov [bp].curr_y,ax
	mov edi,[bp].de_p1
	mov ax,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
;
	mov word ptr [bp].de_width,1
	ret
draw_mid_ellipse_hollow	Endp

draw_mid_ellipse_filled	Proc near
    mov ax,[bp].de_y0
    mov [bp].curr_y,ax
	mov edi,[bp].de_p0
	mov cx,[bp].de_size
	call FilledLine
;
    mov ax,[bp].de_y1
    mov [bp].curr_y,ax
	mov edi,[bp].de_p1
	mov cx,[bp].de_size
	call FilledLine
;
	mov word ptr [bp].de_width,1
	ret
draw_mid_ellipse_filled	Endp

draw_last_ellipse_hollow	Proc near
    mov ax,[bp].de_y0
    mov [bp].curr_y,ax
	mov edi,[bp].de_p0
	mov ax,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
	ret
draw_last_ellipse_hollow	Endp

draw_last_ellipse_filled	Proc near
    mov ax,[bp].de_y0
    mov [bp].curr_y,ax
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
	sub sp,88
;
	cmp si,2
	jbe ellipse_end
;
	cmp di,2
	jbe ellipse_end
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
	mov [bp].curr_x,cx
	mov [bp].de_y0,dx
	add dx,di
	add dx,di
	mov [bp].de_y1,dx
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
	movsx ecx,word ptr [bp].curr_x
	movsx edx,word ptr [bp].de_y0
	mov eax,esi
	imul edx
	mov edi,ecx
	add edi,edi
	add edi,ecx
	add edi,eax
	add edi,ds:v_app_base
	mov [bp].de_p0,edi
;
	movsx ecx,word ptr [bp].curr_x
	movsx edx,word ptr [bp].de_y1
	mov eax,esi
	imul edx
	mov edi,ecx
	add edi,edi
	add edi,ecx
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
    dec word ptr [bp].curr_x
	sub dword ptr [bp].de_p0,3
	sub dword ptr [bp].de_p1,3
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
    dec word ptr [bp].curr_x
	sub dword ptr [bp].de_p0,3
	sub dword ptr [bp].de_p1,3
	inc word ptr [bp].de_width
	add word ptr [bp].de_size,2
;
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].ellipse_mid_style_tab
    inc word ptr [bp].de_y0
    dec word ptr [bp].de_y1
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
	inc word ptr [bp].de_y0
	dec word ptr [bp].de_y1
	add [bp].de_p0,esi
	sub [bp].de_p1,esi
;
	sub word ptr [bp].de_cnt,1
	jnz ellipse_loop

ellipse_done:
	movzx bx,ds:v_style
	add bx,bx
	call word ptr cs:[bx].ellipse_last_style_tab

ellipse_end:
	add sp,88
	popad
	pop es
	pop ds
	ret
draw_ellipse	Endp

error	Proc far
	stc
	ret
error	Endp

	public BitmapTab24

BitmapTab24:
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
mt0F DW OFFSET set_color,			video_code_sel
mt10 DW OFFSET get_pixel,			video_code_sel
mt11 DW OFFSET set_pixel,			video_code_sel
mt12 DW OFFSET get_native,			video_code_sel
mt13 DW OFFSET get_rgb,				video_code_sel
mt14 DW OFFSET set_native,			video_code_sel
mt15 DW OFFSET set_rgb,				video_code_sel
mt16 DW OFFSET get_line,			video_code_sel
mt17 DW OFFSET draw_mask_line,		video_code_sel
mt18 DW OFFSET draw_sprite_line,	video_code_sel
mt19 DW OFFSET draw_string,			video_code_sel
mt1A DW OFFSET draw_line,			video_code_sel
mt1B DW OFFSET draw_rect,			video_code_sel
mt1C DW OFFSET draw_ellipse,		video_code_sel

code	ENDS

	END

