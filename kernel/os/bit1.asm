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
; BIT1.ASM
; Linear 1-bit graphics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME bit1

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
;		PARAMETERS:		EAX			Bit #. Bit 31 = value
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
;		NAME:			LgopSet
;
;		DESCRIPTION:	Set drawing color
;
;		PARAMETERS:		EAX			Bit #.
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopSet	Proc near
	bts es:[edi],eax
	ret
LgopSet	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopCompl
;
;		DESCRIPTION:	Complement
;
;		PARAMETERS:		EAX			Bit #.
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopCompl	Proc near
	btc es:[edi],eax
	ret
LgopCompl	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LgopReset
;
;		DESCRIPTION:	Reset draw
;
;		PARAMETERS:		EAX			Bit #.
;						ES:EDI		Dest buffer (LFB)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LgopReset	Proc near
	btr es:[edi],eax
	ret
LgopReset	Endp

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
lgt01	DW OFFSET LgopSet
lgt02	DW OFFSET LgopSet
lgt03	DW OFFSET LgopNull
lgt04	DW OFFSET LgopCompl
lgt05	DW OFFSET LgopReset
lgt06	DW OFFSET LgopNull
lgt07	DW OFFSET LgopReset
lgt08	DW OFFSET LgopNull
lgt09	DW OFFSET LgopSet
lgt0A	DW OFFSET LgopReset
lgt0B	DW OFFSET LgopNull
lgt0C	DW OFFSET LgopSet
lgt0D	DW OFFSET LgopSet

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			TranslateColor
;
;		DESCRIPTION:	Translate color
;
;		PARAMETER:		EAX			RGB color
;
;       RETURNS:        EAX         Internal color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

translate_color	Proc far
	ret
translate_color	Endp

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
	push es
	push edx
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	add eax,ds:v_app_base
	mov dx,flat_sel
	mov es,dx
	bt es:[eax],ecx
	jc get_pixel_set
;
	xor eax,eax
	jmp get_pixel_done

get_pixel_set:
	mov eax,ds:v_color

get_pixel_done:
	pop edx	
	pop es
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
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	add eax,ds:v_app_base
	mov edi,eax
	mov ax,flat_sel
	mov es,ax
	movzx eax,cx
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
	pushad
;
	push ax
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	add eax,ds:v_app_base
	mov esi,eax
	mov ebp,ds:v_color
	mov ax,flat_sel
	mov ds,ax
	movzx eax,cx
	shr eax,3
	add esi,eax
	and cl,7
	pop dx
;
	or dx,dx
	jz get_rgb_done
;
	lods byte ptr [esi]
	shr al,cl
	mov ch,8
	sub ch,cl

get_rgb_loop:
	rcr al,1
	jc get_rgb_set

get_rgb_reset:
	mov dword ptr es:[edi],0
	jmp get_rgb_next

get_rgb_set:
	mov es:[edi],ebp

get_rgb_next:
	add edi,4
	sub dx,1
	jz get_rgb_done
;
	sub ch,1
	jnz get_rgb_loop
;
	lods byte ptr [esi]
	mov ch,8
	jmp get_rgb_loop

get_rgb_done:
	popad
	pop ds
	ret
get_rgb	Endp

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
;
	push ax
	mov esi,edi
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	add eax,ds:v_app_base
	mov edi,eax
	mov ax,flat_sel
	mov es,ax
	movzx eax,cx
	mov bx,ds:v_lgop
	mov dx,es
	mov ds,dx
	mov dx,flat_sel
	mov es,dx
	pop cx
;
	or cx,cx
	jz set_rgb_done
;
	add bx,bx

set_rgb_loop:
	mov edx,[esi]
	or edx,edx
	je set_rgb_next
;
	call word ptr cs:[bx].LgopTab

set_rgb_next:
	add esi,4
	inc eax
	loop set_rgb_loop

set_rgb_done:
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
;						EAX			bit #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_line	Proc far
	push edx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	add eax,ds:v_app_base
	mov edi,eax
	mov ax,flat_sel
	mov es,ax
	movzx eax,cx
	pop edx
	ret
get_line	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SlabNull
;
;		DESCRIPTION:	Null line
;
;		PARAMETERS:		EAX			Bit #
;						ES:EDI		Dest buffer (LFB)
;						CX			number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabNull	Proc near
	ret
SlabNull	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SlabSet
;
;		DESCRIPTION:	Set line
;
;		PARAMETERS:		EAX			Bit #
;						ES:EDI		Dest buffer (LFB)
;						CX			number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

or_bit_tab:
bt00	DB 0FFh
bt01	DB 0FEh
bt02	DB 0FCh
bt03	DB 0F8h
bt04	DB 0F0h
bt05	DB 0E0h
bt06	DB 0C0h
bt07	DB 80h

SlabSet	Proc near
	push eax
	push ebx
	push cx
	push edi
;
	or cx,cx
	jz slab_set_done
;
	movzx ebx,al
	shr eax,3
	add edi,eax
	and bl,7
	mov ax,cx
	add ax,bx
	cmp ax,8
	jc slab_set_last_loop
;
	mov al,byte ptr cs:[bx].or_bit_tab
	or es:[edi],al
	sub cx,8
	add cx,bx
;
	mov al,-1
	xor bl,bl

slab_set_loop:
	inc edi
	cmp cx,8
	jb slab_set_last_loop
;
	mov es:[edi],al
	sub cx,8
	jnz slab_set_loop
	jmp slab_set_done
	
slab_set_last_loop:
	bts es:[edi],ebx
	inc bl
	loop slab_set_last_loop

slab_set_done:
	pop edi
	pop cx
	pop ebx
	pop eax
	ret
SlabSet	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SlabReset
;
;		DESCRIPTION:	Reset line
;
;		PARAMETERS:		EAX			Bit #
;						ES:EDI		Dest buffer (LFB)
;						CX			number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

and_bit_tab:
br00	DB 0
br01	DB 1
br02	DB 3
br03	DB 7
br04	DB 0Fh
br05	DB 1Fh
br06	DB 3Fh
br07	DB 7Fh

SlabReset	Proc near
	push eax
	push ebx
	push cx
	push edi
;
	or cx,cx
	jz slab_reset_done
;
	movzx ebx,al
	shr eax,3
	add edi,eax
	and bl,7
	mov ax,cx
	add ax,bx
	cmp ax,8
	jc slab_reset_last_loop
;
	mov al,byte ptr cs:[bx].and_bit_tab
	and es:[edi],al
	sub cx,8
	add cx,bx
;
	xor al,al
	xor bl,bl

slab_reset_loop:
	inc edi
	cmp cx,8
	jb slab_reset_last_loop
;
	mov es:[edi],al
	sub cx,8
	jnz slab_reset_loop
	jmp slab_reset_done
	
slab_reset_last_loop:
	btr es:[edi],ebx
	inc bl
	loop slab_reset_last_loop

slab_reset_done:
	pop edi
	pop cx
	pop ebx
	pop eax
	ret
SlabReset	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SlabCompl
;
;		DESCRIPTION:	Compl line
;
;		PARAMETERS:		EAX			Bit #
;						ES:EDI		Dest buffer (LFB)
;						CX			number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabCompl	Proc near
	push eax
	push ebx
	push cx
	push edi
;
	or cx,cx
	jz slab_compl_done
;
	movzx ebx,al
	shr eax,3
	add edi,eax
	and bl,7
	mov ax,cx
	add ax,bx
	cmp ax,8
	jc slab_compl_last_loop
;
	mov al,es:[edi]
	mov ah,al
	and al,byte ptr cs:[bx].or_bit_tab
	not al
	and ah,byte ptr cs:[bp].and_bit_tab
	or al,ah
	mov es:[edi],al
	sub cx,8
	add cx,bx
;
	mov al,-1
	xor bl,bl

slab_compl_loop:
	inc edi
	cmp cx,8
	jb slab_compl_last_loop
;
	xor es:[edi],al
	sub cx,8
	jnz slab_compl_loop
	jmp slab_compl_done
	
slab_compl_last_loop:
	btc es:[edi],ebx
	inc bl
	loop slab_compl_last_loop

slab_compl_done:
	pop edi
	pop cx
	pop ebx
	pop eax
	ret
SlabCompl	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SlabTab
;
;		DESCRIPTION:	Slab LGOP table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlabTab:
st00	DW OFFSET SlabNull
st01	DW OFFSET SlabSet
st02	DW OFFSET SlabSet
st03	DW OFFSET SlabNull
st04	DW OFFSET SlabCompl
st05	DW OFFSET SlabReset
st06	DW OFFSET SlabNull
st07	DW OFFSET SlabReset
st08	DW OFFSET SlabNull
st09	DW OFFSET SlabSet
st0A	DW OFFSET SlabReset
st0B	DW OFFSET SlabNull
st0C	DW OFFSET SlabSet
st0D	DW OFFSET SlabSet

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HollowLine
;
;		DESCRIPTION:	Draw a hollow line
; 
;		PARAMETER:		EAX			bit #
;						CX			width
;						EDI			position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HollowLine	Proc near
	push eax
	mov bx,ds:v_lgop
	add bx,bx
	call word ptr cs:[bx].LgopTab
	movzx ecx,cx
	add eax,ecx
	dec eax
	call word ptr cs:[bx].LgopTab
	pop eax
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
;		PARAMETER:		EAX			bit #
;						CX			width
;						EDI			position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FilledLine	Proc near
	or cx,cx
	jz filled_line_done
;
	mov bx,ds:v_lgop
	add bx,bx
	call word ptr cs:[bx].SlabTab

filled_line_done:
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
;		PARAMETER:		EAX			bit #
;						CX			gap
;						DX			line width
;						EDI			position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SplitLine	Proc near
	push eax
	push cx
;
	sub cx,dx
	sub cx,dx
	mov bx,ds:v_lgop
	add bx,bx
;
	push cx
	mov cx,dx

split_left_loop:
	call word ptr cs:[bx].LgopTab
	inc eax
	loop split_left_loop
;
	pop cx
;
	movzx ecx,cx
	add eax,ecx
;
	mov cx,dx

split_right_loop:
	call word ptr cs:[bx].LgopTab
	inc eax
	loop split_right_loop
;
	pop cx
	pop eax
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
;						ECX			source x + y << 16
;						EDX			dest x + y << 16
;						SI			width
;						ES:EDI		1-bit mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

last_bit_tab:
lbt0	DB 0FFh
lbt1	DB 1
lbt2	DB 3
lbt3	DB 7
lbt4	DB 0Fh
lbt5	DB 1Fh
dlbt6	DB 3Fh
lbt7	DB 7Fh

MaskNull	Proc near
	ret
MaskNull	Endp

MaskNone	Proc near
	push bx
	push dx
;
	mov dx,es:[edi]
	mov bx,0FF00h
	rol bx,cl
	and dx,bx
	xor ah,ah
	rol ax,cl
	or ax,dx
	mov es:[edi],ax
;
	pop dx
	pop bx
	ret
MaskNone	Endp

MaskOr	Proc near
	xor ah,ah
	rol ax,cl
	or es:[edi],ax
	ret
MaskOr	Endp

MaskAnd	Proc near
	mov ah,0FFh
	rol ax,cl
	and es:[edi],ax
	ret
MaskAnd	Endp

MaskXor	Proc near
	xor ah,ah
	rol ax,cl
	xor es:[edi],ax
	ret
MaskXor	Endp

MaskInvert	Proc near
	push bx
	push dx
;
	not al
	mov dx,es:[edi]
	mov bx,0FF00h
	rol bx,cl
	and dx,bx
	xor ah,ah
	rol ax,cl
	or ax,dx
	mov es:[edi],ax
;
	pop dx
	pop bx
	ret
MaskInvert	Endp

MaskInvertOr	Proc near
	not al
	xor ah,ah
	rol ax,cl
	or es:[edi],ax
	ret
MaskInvertOr	Endp

MaskInvertAnd	Proc near
	not al
	mov ah,0FFh
	rol ax,cl
	and es:[edi],ax
	ret
MaskInvertAnd	Endp

MaskInvertXor	Proc near
	not al
	xor ah,ah
	rol ax,cl
	xor es:[edi],ax
	ret
MaskInvertXor	Endp

MaskTab:
mtl00	DW OFFSET MaskNull
mtl01	DW OFFSET MaskNone
mtl02	DW OFFSET MaskOr
mtl03	DW OFFSET MaskAnd
mtl04	DW OFFSET MaskXor
mtl05	DW OFFSET MaskInvert
mtl06	DW OFFSET MaskInvertOr
mtl07	DW OFFSET MaskInvertAnd
mtl08	DW OFFSET MaskInvertXor
mtl09	DW OFFSET MaskOr
mtl0A	DW OFFSET MaskAnd
mtl0B	DW OFFSET MaskAnd

draw_mask_line	Proc far
	push es
	push fs
	pushad
;
	xchg ecx,edx
	movzx ebx,dx
	ror edx,16
	movzx edx,dx
	movzx eax,ax
	mul edx
	shl eax,3
	add eax,ebx
	push eax
;
	movzx ebp,cx
	ror ecx,16
	movzx edx,cx
	movzx eax,ds:v_row_size
	mul edx
	shl eax,3
	add eax,ebp
	mov cl,al
	shr eax,3
	add eax,ds:v_app_base
;
	pop ebp
	mov ch,bl
	and cx,707h
	shr ebp,3
	add ebp,edi
;
	mov di,si
	add di,bx
	and di,7
	mov dl,byte ptr cs:[di].last_bit_tab
;
	add si,bx
	dec si
	shr si,3
	inc si
	shr bx,3
	sub si,bx
;
	xchg esi,ebp
	mov edi,eax
;
	mov ax,es
	mov fs,ax
	mov ax,flat_sel
	mov es,ax
	mov bx,ds:v_lgop
	add bx,bx

draw_mask_line_loop:
	mov ax,fs:[esi]
	xchg cl,ch
	ror ax,cl
	xchg cl,ch
	cmp bp,1
	jnz draw_mask_save
;
	and al,dl

draw_mask_save:
	call word ptr cs:[bx].MaskTab
	inc esi
	inc edi
	sub bp,1
	jnz draw_mask_line_loop
;
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
;						EDX			width + height << 16
;						ESI			sprite data
;						ES:EDI		1-bit mask bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_sprite_line    Proc far
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

ds_dest_y		EQU -2
ds_dest_x		EQU -4
ds_cnt			EQU -6
ds_src_x		EQU -8
ds_row_size		EQU -10
ds_width		EQU -12
ds_height		EQU -14
ds_line_cnt		EQU -16

draw_string	Proc far
	push bp
	mov bp,sp
	sub sp,16
;
	push es
	push fs
	push gs
	pushad
;
	mov ax,es
	mov fs,ax
	mov ax,flat_sel
	mov es,ax
;
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
	mov [bp].ds_height,dx
	movzx eax,word ptr [bp].ds_row_size
	mov cx,[bp].ds_height
	or cx,cx
	jz draw_string_char_next
;
	mov [bp].ds_line_cnt,cx
;
	movzx esi,word ptr [bp].ds_src_x
	shr esi,3
	add esi,edi
;
	movzx ebx,word ptr [bp].ds_dest_x
	movzx edx,word ptr [bp].ds_dest_y
	movzx eax,word ptr ds:v_row_size
	mul edx
	shl eax,3
	add eax,ebx
	mov cl,al
	and cl,7
	shr eax,3
	add eax,ds:v_app_base
	mov edi,eax
;
	mov bx,[bp].ds_width
	add bx,[bp].ds_src_x
	mov ax,bx
	and bx,7
	mov dl,byte ptr cs:[bx].last_bit_tab
	dec ax
	shr ax,3
	inc ax
	mov bx,[bp].ds_src_x
	shr bx,3
	sub ax,bx
	mov [bp].ds_cnt,ax
;
	mov bx,ds:v_lgop
	add bx,bx

draw_string_char_loop:
	push bp
	push edi
	mov bp,[bp].ds_cnt

draw_string_line_loop:
	mov al,gs:[esi]
	cmp bp,1
	jnz draw_string_line_save
;
	and al,dl

draw_string_line_save:
	call word ptr cs:[bx].MaskTab
	inc esi
	inc edi
	sub bp,1
	jnz draw_string_line_loop
;
	pop edi
	pop bp
	movzx eax,ds:v_row_size
	add edi,eax
	sub word ptr [bp].ds_line_cnt,1
	jnz draw_string_char_loop

draw_string_char_done:
	mov ax,[bp].ds_width
	add [bp].ds_dest_x,ax

draw_string_char_next:
	pop edi
	jmp draw_string_loop

draw_string_ok:
	clc

draw_string_done:
	popad
	pop gs
	pop fs
	pop es
	add sp,16
	pop bp
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
	cmp di,dx
	jae line_bresen_magn_ok
;
	xchg cx,si
	xchg dx,di

line_bresen_magn_ok:
	push si
	push di
	push dx
	movzx ecx,cx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	shl eax,3
	add eax,ecx
	mov ebp,eax
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
	mov esi,-1
	jmp line_bresen_dy

line_bresen_dx_pos:
	add cx,cx
	mov esi,1

line_bresen_dy:
	test dh,80h
	jz line_bresen_dy_pos

line_bresen_dy_neg:
	add dx,dx
	neg dx
	movzx edi,ds:v_row_size
	shl edi,3
	neg edi
	jmp line_bresen_do

line_bresen_dy_pos:
	add dx,dx
	movzx edi,ds:v_row_size
	shl edi,3

line_bresen_do:
	push cx
	push dx
	movzx ecx,ax
	movzx edx,bx
	movzx eax,ds:v_row_size
	mul edx
	shl eax,3
	add eax,ecx
	mov ebx,eax
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
	mov eax,edi
	push edi
	mov edi,ds:v_app_base
	call word ptr cs:[bx].LgopTab
	pop edi
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
	cmp edi,ds:v_app_base
	jb line_done
;
	sub esi,ebp
	cmp esi,edi
	jae line_done
;
	add esi,ebp
	push ax
	push bx
	mov bx,ds:v_lgop
	add bx,bx
	push edi
	mov eax,edi
	mov edi,ds:v_app_base
	call word ptr cs:[bx].LgopTab
	pop edi
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
	cmp edi,ds:v_app_base
	jb line_done
;
	sub esi,ebp
	cmp esi,edi
	jae line_done
;
	add esi,ebp
	push ax
	push bx
	mov bx,ds:v_lgop
	add bx,bx
	push edi
	mov eax,edi
	mov edi,ds:v_app_base
	call word ptr cs:[bx].LgopTab
	pop edi
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
	sub bx,dx
	movzx edx,dx
	movzx eax,ds:v_row_size
	mov esi,eax
	mul edx
	add eax,ds:v_app_base
	mov edi,eax
	mov ax,flat_sel
	mov es,ax
	movzx eax,cx
	mov cx,bx
	inc cx
	mov bx,ds:v_lgop
	add bx,bx

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
	shl eax,3
	add eax,ecx
	mov edi,ds:v_app_base
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
	movzx edx,dx
	movzx eax,ds:v_row_size
	mov esi,eax
	mul edx
	add eax,ds:v_app_base
	mov edi,eax
	mov ax,flat_sel
	mov es,ax
	movzx eax,cx
	pop dx
	pop cx
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
	mov edi,ds:v_app_base
	mov eax,[bp].de_p0
	mov dx,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
;
	mov eax,[bp].de_p1
	mov dx,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
;
	mov word ptr [bp].de_width,1
	ret
draw_mid_ellipse_hollow	Endp

draw_mid_ellipse_filled	Proc near
	mov edi,ds:v_app_base
	mov eax,[bp].de_p0
	mov cx,[bp].de_size
	call FilledLine
;
	mov eax,[bp].de_p1
	mov cx,[bp].de_size
	call FilledLine
;
	mov word ptr [bp].de_width,1
	ret
draw_mid_ellipse_filled	Endp

draw_last_ellipse_hollow	Proc near
	mov edi,ds:v_app_base
	mov eax,[bp].de_p0
	mov dx,[bp].de_width
	mov cx,[bp].de_size
	call SplitLine
	ret
draw_last_ellipse_hollow	Endp

draw_last_ellipse_filled	Proc near
	mov edi,ds:v_app_base
	mov eax,[bp].de_p0
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
	shl esi,3
;
	movzx ecx,word ptr [bp].de_xoff
	movzx edx,word ptr [bp].de_yoff
	sub dx,[bp].de_h
	mov eax,esi
	mul edx
	add eax,ecx
	mov [bp].de_p0,eax
;
	movzx ecx,word ptr [bp].de_xoff
	movzx edx,word ptr [bp].de_yoff
	add dx,[bp].de_h
	mov eax,esi
	mul edx
	add eax,ecx
	mov [bp].de_p1,eax
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
	sub dword ptr [bp].de_p0,1
	sub dword ptr [bp].de_p1,1
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
	sub dword ptr [bp].de_p0,1
	sub dword ptr [bp].de_p1,1
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

ellipse_end:
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

	public BitmapTab1

BitmapTab1:
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
mt0F DW OFFSET translate_color,		video_code_sel
mt10 DW OFFSET get_pixel,			video_code_sel
mt11 DW OFFSET set_pixel,			video_code_sel
mt12 DW OFFSET get_rgb,				video_code_sel
mt13 DW OFFSET get_rgb,				video_code_sel
mt14 DW OFFSET set_rgb,				video_code_sel
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

