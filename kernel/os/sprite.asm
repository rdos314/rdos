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
; SPRITE.ASM
; Sprite module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME sprite

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
INCLUDE sprite.inc
INCLUDE video.inc

code	SEGMENT byte public use16 'CODE'

	.386

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:           CreateSprite
;
;		DESCRIPTION:	Create a new sprite
;
;		PARAMETERS:		AX		LGOP
;                       BX      Dest bitmap handle or 0
;                       CX      Main bitmap
;                       DX      Mask (1-bit bitmap)
;
;		RETURNS:		BX      Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_sprite_name	DB 'Create Sprite', 0

create_sprite	Proc far
	push ds
    push es
    push eax
    push cx
    push dx
;
    push ax
    mov eax,SIZE sprite_sel_struc
    AllocateSmallKernelMem
    pop ax
    mov es:sp_lgop,ax
;
	or bx,bx
	jnz create_sprite_bmp
;
	mov ax,video_local_sel
	mov ds,ax
	mov ax,ds:v_handle
	jmp create_sprite_dest_ok

create_sprite_bmp:
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc create_sprite_fail
;
	mov ax,[bx].bm_sel

create_sprite_dest_ok:
    mov es:sp_dest_sel,ax
    mov ds,ax
    mov al,ds:v_bpp
    mov es:sp_bpp,al
    mov ax,ds:v_width
    mov es:sp_dest_w,ax
    mov ax,ds:v_height
    mov es:sp_dest_h,ax
;
	mov ax,ds:v_sprites
	or ax,ax
	je create_sprite_ins_empty
;
	push ds
	push si
	mov ds,ax
	mov si,ds:sp_prev
	mov ds:sp_prev,es
	mov ds,si
	mov ds:sp_next,es
	mov es:sp_next,ax
	mov es:sp_prev,si
	pop si
	pop ds
	jmp create_sprite_ins_done

create_sprite_ins_empty:
	mov es:sp_next,es
	mov es:sp_prev,es
	mov ds:v_sprites,es

create_sprite_ins_done:
    mov bx,cx
	mov ax,BITMAP_HANDLE
    DerefHandle
    jc create_sprite_fail
;
    mov ax,[bx].bm_sel
    mov es:sp_bitmap_sel,ax
    mov ds,ax
    mov ax,ds:v_width
    cmp ax,es:sp_dest_w
    ja create_sprite_fail
    mov es:sp_w,ax
;
    mov ax,ds:v_height
    cmp ax,es:sp_dest_h
    ja create_sprite_fail
    mov es:sp_h,ax
;
    mov es:sp_bitmap_handle,0
    mov al,ds:v_bpp
    cmp al,es:sp_bpp
    je create_sprite_mask
;
    push cx
    push dx
    mov cx,es:sp_w
    mov dx,es:sp_h
    movzx ax,es:sp_bpp
    CreateBitmap
    pop dx
    pop cx
;
    mov ax,LGOP_NONE
    SetLgop
;
    push cx
    push dx
    push esi
    push edi
    mov ax,cx
    mov cx,es:sp_w
    mov dx,es:sp_h
    xor esi,esi
    xor edi,edi
    Blit
    pop edi
    pop esi
    pop dx
    pop cx
;
    mov es:sp_bitmap_handle,bx
	mov ax,BITMAP_HANDLE
    DerefHandle
    jc create_sprite_fail
;
    mov ax,[bx].bm_sel
    mov es:sp_bitmap_sel,ax

create_sprite_mask:
    mov bx,dx
	mov ax,BITMAP_HANDLE
    DerefHandle
    jc create_sprite_fail
;
    mov ax,[bx].bm_sel
    mov es:sp_mask_sel,ax
    mov ds,ax
    cmp ds:v_bpp,1
    jne create_sprite_fail
;
    mov ax,ds:v_width
    cmp ax,es:sp_w
    jb create_sprite_fail
;
    mov ax,ds:v_height
    cmp ax,es:sp_h
    jb create_sprite_fail
;
    movzx ax,es:sp_bpp
    mov cx,es:sp_w
    mov dx,es:sp_h
    CreateBitmap
    jc create_sprite_fail
;
    mov ax,LGOP_NONE
    SetLgop
;
    mov es:sp_back_handle,bx
	mov ax,BITMAP_HANDLE
    DerefHandle
    jc create_sprite_fail
;
    mov ax,[bx].bm_sel
    mov es:sp_back_sel,ax
    mov es:sp_flags,0
    mov es:sp_x,0
    mov es:sp_y,0
    mov es:sp_new_x,0
    mov es:sp_new_y,0
;
	mov cx,SIZE sprite_struc
	AllocateHandle
	mov ds:[bx].sp_sel,es
	mov [bx].hh_sign,SPRITE_HANDLE
	mov bx,[bx].hh_handle
    clc
    jmp create_sprite_done

create_sprite_fail:
    FreeMem
    stc    
   
create_sprite_done:
    pop dx
    pop cx
    pop eax
    pop es
	pop ds
	retf32
create_sprite	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HideWholeLine
;
;		DESCRIPTION:	Hide a whole line in a sprite macro
;
;		PARAMETERS:		FS		Sprite handle
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


HideWholeLine    MACRO
    mov ds,fs:sp_back_sel
    xor cx,cx
    mov ax,fs:sp_w
    call ds:get_line_proc
;
    mov ds,fs:sp_dest_sel
    mov cx,fs:sp_x
    add dx,fs:sp_y
    call ds:set_native_row_proc
            ENDM


PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SaveAndShowWholeLine
;
;		DESCRIPTION:	Save & show a whole line in a sprite macro
;
;		PARAMETERS:		FS		Sprite handle
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveAndShowWholeLine    MACRO
    mov ds,fs:sp_dest_sel
    mov cx,fs:sp_new_x
    add dx,fs:sp_new_y
    call ds:get_line_proc
;
    mov ds,fs:sp_back_sel
    xor cx,cx
    sub dx,fs:sp_new_y
    mov ax,fs:sp_w
    call ds:set_native_row_proc
;
    mov ds,fs:sp_bitmap_sel
    call ds:get_line_proc
    mov esi,edi
;
    push dx
    mov ds,fs:sp_mask_sel
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	add eax,ds:v_app_base
    mov edi,eax
    pop dx
;
	mov ds,fs:sp_dest_sel
    mov ax,fs:sp_lgop
    push ds:v_lgop
    mov ds:v_lgop,ax
    add dx,fs:sp_new_y
    movzx ecx,dx
	shl ecx,16
	mov cx,fs:sp_new_x
    mov dx,fs:sp_w
	xor al,al
    call ds:draw_sprite_line_proc
    pop ds:v_lgop
            ENDM

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HideLine
;
;		DESCRIPTION:	Hide a line in a sprite macro
;
;		PARAMETERS:		X       x in current sprite
;                       Y       y in current sprite
;                       FS		Current sprite
;                       GS      Hiding sprite
;                       CX      X relative position
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HideLine    MACRO x, y
    local hide_line_done
    local hide_line_pos
    local hide_line_do

	add dx,fs:&y
	sub dx,gs:sp_y
	jc hide_line_done
;
	cmp dx,gs:sp_h
	jae hide_line_done
;
    mov cx,fs:&x
    sub cx,gs:sp_x
    jge hide_line_pos
;
    mov ax,fs:sp_w
    add ax,cx
    jle hide_line_done
;
    xor cx,cx
	cmp ax,gs:sp_w
	jc hide_line_do
;
	mov ax,gs:sp_w
    jmp hide_line_do

hide_line_pos:
    cmp cx,gs:sp_w
    jae hide_line_done
;
    mov ax,gs:sp_w
    sub ax,cx

hide_line_do:
    mov ds,gs:sp_back_sel
    call ds:get_line_proc
;
    mov ds,gs:sp_dest_sel
    add cx,gs:sp_x
    add dx,gs:sp_y
    call ds:set_native_row_proc

hide_line_done:
            ENDM

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SaveLine
;
;		DESCRIPTION:	Save a line in a sprite macro
;
;		PARAMETERS:		X       x in current sprite
;                       Y       y in current sprite
;                       FS      Current sprite
;                       GS      Save sprite
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SaveLine    MACRO x, y
    local save_line_done
    local save_line_pos
    local save_line_do

	add dx,fs:&y
	sub dx,gs:sp_y
	jc save_line_done
;
	cmp dx,gs:sp_h
	jae save_line_done
;
    mov cx,fs:&x
    sub cx,gs:sp_x
    jge save_line_pos
;
    mov ax,fs:sp_w
    add ax,cx
    jle save_line_done
;
    xor cx,cx
	cmp ax,gs:sp_w
	jc save_line_do
;
	mov ax,gs:sp_w
    jmp save_line_do

save_line_pos:
    cmp cx,gs:sp_w
    jae save_line_done
;
    mov ax,gs:sp_w
    sub ax,cx

save_line_do:
    mov ds,gs:sp_dest_sel
    add cx,gs:sp_new_x
    add dx,gs:sp_new_y
    push ax
    call ds:get_line_proc
    pop ax
;
    mov ds,gs:sp_back_sel
    sub cx,gs:sp_new_x
    sub dx,gs:sp_new_y
    call ds:set_native_row_proc

save_line_done:
            ENDM

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ShowLine
;
;		DESCRIPTION:	Show a line in a sprite macro
;
;		PARAMETERS:		X       x in current sprite
;                       Y       y in current sprite
;                       FS      Current sprite
;                       GS      Show sprite
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ShowLine    MACRO x, y
    local show_line_done
    local show_line_pos
    local show_line_do

	add dx,fs:&y
	sub dx,gs:sp_y
	jc show_line_done
;
	cmp dx,gs:sp_h
	jae show_line_done
;
    mov cx,fs:&x
    sub cx,gs:sp_x
    jge show_line_pos
;
    mov ax,fs:sp_w
    add ax,cx
    jle show_line_done
;
    xor cx,cx
	cmp ax,gs:sp_w
	jc show_line_do
;
	mov ax,gs:sp_w
    jmp show_line_do

show_line_pos:
    cmp cx,gs:sp_w
    jae show_line_done
;
    mov ax,gs:sp_w
    sub ax,cx

show_line_do:
    push bp
    mov bp,ax
;
    mov ds,gs:sp_bitmap_sel
    call ds:get_line_proc
    mov esi,edi
;
    push dx
    mov ds,gs:sp_mask_sel
	movzx edx,dx
	movzx eax,ds:v_row_size
	mul edx
	add eax,ds:v_app_base
    mov edi,eax
    movzx edx,cx
    shr edx,3
    add edi,edx
    pop dx
;
	mov ds,gs:sp_dest_sel
    mov ax,gs:sp_lgop
    push ds:v_lgop
    mov ds:v_lgop,ax
    add dx,gs:sp_new_y
	shl edx,16
	mov al,cl
	and al,7
	add cx,gs:sp_new_x
	movzx ecx,cx
	or ecx,edx
	mov dx,bp
    call ds:draw_sprite_line_proc
    pop ds:v_lgop
    pop bp

show_line_done:
            ENDM

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			hide
;
;		DESCRIPTION:	Hide sprite
;
;		PARAMETERS:		FS		Sprite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide	Proc near
    xor bp,bp

hide_sprite_loop:
    mov ds,fs:sp_dest_sel
	mov gs,ds:v_sprites
	mov ax,gs:sp_prev

hide_sprite_ovl_loop:
	mov dx,fs
	cmp ax,dx
	je hide_sprite_curr
;
	mov gs,ax
	test gs:sp_flags,SP_FLAG_VISIBLE
	jz hide_sprite_ovl_next
;
    mov dx,bp
    HideLine sp_x, sp_y

hide_sprite_ovl_next:
	mov ax,gs:sp_prev
	jmp hide_sprite_ovl_loop

hide_sprite_curr:
    mov dx,bp
    HideWholeLine
;
    mov ds,fs:sp_dest_sel
	mov ax,fs:sp_next

hide_sprite_ovl_show_loop:
	cmp ax,ds:v_sprites
	je hide_sprite_line_done
;
	mov gs,ax
	push ds
;
	test gs:sp_flags,SP_FLAG_VISIBLE
	jz hide_sprite_ovl_show_next
;
    mov dx,bp
    SaveLine sp_x, sp_y
;
    mov dx,bp
    ShowLine sp_x, sp_y

hide_sprite_ovl_show_next:
	pop ds
	mov ax,gs:sp_next
	jmp hide_sprite_ovl_show_loop

hide_sprite_line_done:
    inc bp
    cmp bp,fs:sp_h
    jnz hide_sprite_loop
;
    and fs:sp_flags,NOT SP_FLAG_VISIBLE
	ret
hide	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			show
;
;		DESCRIPTION:	Show sprite
;
;		PARAMETERS:		FS		Sprite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show	Proc near
    or fs:sp_flags,SP_FLAG_VISIBLE
    xor bp,bp

show_sprite_loop:
    mov ds,fs:sp_dest_sel
	mov gs,ds:v_sprites
	mov ax,gs:sp_prev

show_sprite_ovl_hide_loop:
	mov dx,fs
	cmp ax,dx
	je show_sprite_curr
;
	mov gs,ax
	test gs:sp_flags,SP_FLAG_VISIBLE
	jz show_sprite_ovl_hide_next
;
    mov dx,bp
    HideLine sp_x, sp_y

show_sprite_ovl_hide_next:
	mov ax,gs:sp_prev
	jmp show_sprite_ovl_hide_loop

show_sprite_curr:
    mov dx,bp
    SaveAndShowWholeLine
;
    mov ds,fs:sp_dest_sel
	mov ax,fs:sp_next

show_sprite_ovl_show_loop:
	cmp ax,ds:v_sprites
	je show_sprite_line_done
;
	mov gs,ax
	push ds
;
	test gs:sp_flags,SP_FLAG_VISIBLE
	jz show_sprite_ovl_show_next
;
    mov dx,bp
    SaveLine sp_x, sp_y
;
    mov dx,bp
    ShowLine sp_x, sp_y

show_sprite_ovl_show_next:
	pop ds
	mov ax,gs:sp_next
	jmp show_sprite_ovl_show_loop

show_sprite_line_done:
    inc bp
    cmp bp,fs:sp_h
    jnz show_sprite_loop
;
	ret
show	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HideSprite
;
;		DESCRIPTION:	Hide sprite
;
;		PARAMETERS:		BX		Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_sprite_name	DB 'Hide Sprite', 0

hide_sprite	Proc far
	push ds
	push es
	push fs
	push gs
	pushad
;
	mov ax,SPRITE_HANDLE
	DerefHandle
	jc hide_sprite_done
;
    mov fs,ds:[bx].sp_sel
    test fs:sp_flags,SP_FLAG_VISIBLE
    jz hide_sprite_done
;
	call hide

hide_sprite_done:
	popad
	pop gs
	pop fs
	pop es
	pop ds
	retf32
hide_sprite	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ShowSprite
;
;		DESCRIPTION:	Show sprite
;
;		PARAMETERS:		BX		Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_sprite_name	DB 'Show Sprite', 0

show_sprite	Proc far
	push ds
	push es
	push fs
	push gs
	pushad
;
	mov ax,SPRITE_HANDLE
	DerefHandle
	jc show_sprite_done
;
    mov fs,ds:[bx].sp_sel
    test fs:sp_flags,SP_FLAG_VISIBLE
    jnz show_sprite_done
;
	call show

show_sprite_done:
	popad
	pop gs
	pop fs
	pop es
	pop ds
	retf32
show_sprite	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			MoveSprite
;
;		DESCRIPTION:	Move sprite
;
;		PARAMETERS:		BX		Sprite handle
;                       CX      x
;                       DX      y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_sprite_name	DB 'Move Sprite', 0

MoveSpriteOvlLine	Proc near
    mov ds,fs:sp_dest_sel
	mov gs,ds:v_sprites
	mov ax,gs:sp_prev

move_sprite_ovl_hide_loop:
	mov dx,fs
	cmp ax,dx
	je move_sprite_ovl_hide_curr
;
	mov gs,ax
	test gs:sp_flags,SP_FLAG_OVL_OLD
	jz move_sprite_ovl_hide_new
;
    mov dx,bp
    HideLine sp_x, sp_y

move_sprite_ovl_hide_new:
	test gs:sp_flags,SP_FLAG_OVL_NEW
	jz move_sprite_ovl_hide_next
;
    mov dx,bp
    HideLine sp_new_x, sp_new_y

move_sprite_ovl_hide_next:
	mov ax,gs:sp_prev
	jmp move_sprite_ovl_hide_loop

move_sprite_ovl_hide_curr:
    mov dx,bp
    HideWholeLine
;
    mov dx,bp
    SaveAndShowWholeLine
;
    mov ds,fs:sp_dest_sel
	mov ax,fs:sp_next

move_sprite_ovl_show_loop:
	cmp ax,ds:v_sprites
	je move_sprite_ovl_line_done
;
	mov gs,ax
	push ds
;
	test gs:sp_flags,SP_FLAG_OVL_OLD
	jz move_sprite_ovl_save_new
;
    mov dx,bp
    SaveLine sp_x, sp_y

move_sprite_ovl_save_new:
	test gs:sp_flags,SP_FLAG_OVL_NEW
	jz move_sprite_ovl_save_done
;
    mov dx,bp
    SaveLine sp_new_x, sp_new_y

move_sprite_ovl_save_done:
	test gs:sp_flags,SP_FLAG_OVL_OLD
	jz move_sprite_ovl_show_new
;
    mov dx,bp
    ShowLine sp_x, sp_y

move_sprite_ovl_show_new:
	test gs:sp_flags,SP_FLAG_OVL_NEW
	jz move_sprite_ovl_show_next
;
    mov dx,bp
    ShowLine sp_new_x, sp_new_y

move_sprite_ovl_show_next:
	pop ds
	mov ax,gs:sp_next
	jmp move_sprite_ovl_show_loop

move_sprite_ovl_line_done:
	ret
MoveSpriteOvlLine	Endp

move_sprite	Proc far
	push ds
	push es
	push fs
	pushad
;
	mov ax,SPRITE_HANDLE
	DerefHandle
	jc move_sprite_done
;
    mov fs,ds:[bx].sp_sel
	mov fs:sp_new_x,cx
	mov fs:sp_new_y,dx
    test fs:sp_flags,SP_FLAG_VISIBLE
    jz move_sprite_hidden
;
    cmp cx,fs:sp_x
    jne move_sprite_move
;
    cmp dx,fs:sp_y
    je move_sprite_hidden

move_sprite_move:
    or fs:sp_flags,SP_FLAG_VISIBLE
    and fs:sp_flags,NOT (SP_FLAG_OVL_OLD OR SP_FLAG_OVL_NEW)
    mov ds,fs:sp_dest_sel
    mov dx,fs
    mov cx,ds:v_sprites

move_sprite_check_loop:
    mov es,cx
    cmp cx,dx
    je move_sprite_check_next
;
    and es:sp_flags,NOT (SP_FLAG_OVL_OLD OR SP_FLAG_OVL_NEW)
    test es:sp_flags,SP_FLAG_VISIBLE
    jz move_sprite_check_next
;
    mov ax,es:sp_y
    sub ax,fs:sp_new_y
    jc move_sprite_new_y_above
;
    sub ax,fs:sp_h
	jae move_sprite_check_old
    jmp move_sprite_new_x

move_sprite_new_y_above:
    neg ax
    sub ax,es:sp_h
    jae move_sprite_check_old

move_sprite_new_x:
    mov ax,es:sp_x
    sub ax,fs:sp_new_x
    jc move_sprite_new_x_above
;
    sub ax,fs:sp_w
	jae move_sprite_check_old
;
    or es:sp_flags,SP_FLAG_OVL_NEW
    or fs:sp_flags,SP_FLAG_OVL_NEW
    jmp move_sprite_check_old

move_sprite_new_x_above:
    neg ax
    sub ax,es:sp_w
    jae move_sprite_check_old
;
    or es:sp_flags,SP_FLAG_OVL_NEW
    or fs:sp_flags,SP_FLAG_OVL_NEW

move_sprite_check_old:
    mov ax,es:sp_y
    sub ax,fs:sp_y
    jc move_sprite_old_y_above
;
    sub ax,fs:sp_h
	jae move_sprite_check_next
    jmp move_sprite_old_x

move_sprite_old_y_above:
    neg ax
    sub ax,es:sp_h
    jae move_sprite_check_next

move_sprite_old_x:
    mov ax,es:sp_x
    sub ax,fs:sp_x
    jc move_sprite_old_x_above
;
    sub ax,fs:sp_w
	jae move_sprite_check_next
;
    or es:sp_flags,SP_FLAG_OVL_OLD
    or fs:sp_flags,SP_FLAG_OVL_OLD
    jmp move_sprite_check_next

move_sprite_old_x_above:
    neg ax
    sub ax,es:sp_w
    jae move_sprite_check_next
;
    or es:sp_flags,SP_FLAG_OVL_OLD
    or fs:sp_flags,SP_FLAG_OVL_OLD

move_sprite_check_next:
    mov cx,es:sp_next
    cmp cx,ds:v_sprites
    jne move_sprite_check_loop
;
    test fs:sp_flags,SP_FLAG_OVL_OLD OR SP_FLAG_OVL_NEW
	jnz move_sprite_ovl
;
	mov dx,fs:sp_new_y
	cmp dx,fs:sp_y
	ja move_sprite_up

move_sprite_down:
    xor bp,bp

move_sprite_down_loop:
    mov dx,bp
    HideWholeLine
;
    mov dx,bp
    SaveAndShowWholeLine
;
    inc bp
    cmp bp,fs:sp_h
    jnz move_sprite_down_loop
	jmp move_sprite_coord

move_sprite_up:
	mov bp,fs:sp_h
	dec bp

move_sprite_up_loop:
    mov dx,bp
    HideWholeLine
;
    mov dx,bp
    SaveAndShowWholeLine
;
	sub bp,1
	jnc move_sprite_up_loop
	jmp move_sprite_coord

move_sprite_ovl:
	push gs
;
	mov dx,fs:sp_new_y
	cmp dx,fs:sp_y
	ja move_sprite_ovl_up

move_sprite_ovl_down:
    xor bp,bp

move_sprite_ovl_down_loop:
	call MoveSpriteOvlLine
    inc bp
    cmp bp,fs:sp_h
    jnz move_sprite_ovl_down_loop
	jmp move_sprite_ovl_coord

move_sprite_ovl_up:
	mov bp,fs:sp_h
	dec bp

move_sprite_ovl_up_loop:
	call MoveSpriteOvlLine
	sub bp,1
	jnc move_sprite_ovl_up_loop

move_sprite_ovl_coord:
	pop gs

move_sprite_coord:
	mov ax,fs:sp_new_x
	mov fs:sp_x,ax
	mov ax,fs:sp_new_y
	mov fs:sp_y,ax
	jmp move_sprite_done

move_sprite_hidden:
    mov fs:sp_x,cx
    mov fs:sp_y,dx

move_sprite_done:
	popad
	pop fs
	pop es
	pop ds
	retf32
move_sprite	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_sprite
;
;		DESCRIPTION:	Delete sprite
;
;		PARAMETERS:		DS:BX		Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_sprite	Proc near
	push ds
	push es
    push fs
	push gs
	pushad
;
    mov ax,[bx].sp_sel
	mov es,ax
    mov ds,es:sp_dest_sel
	mov dx,es:sp_next
	cmp ax,ds:v_sprites
	jne delete_sprite_not_head
;
	mov ds:v_sprites,dx
	cmp ax,dx
	jne delete_sprite_not_head
;
	mov ds:v_sprites,0
	jmp delete_sprite_do

delete_sprite_not_head:			
	mov ax,es:sp_prev
	mov ds,dx
	mov ds:sp_prev,ax
	mov ds,ax
	mov ds:sp_next,dx

delete_sprite_do:
    push bx
    mov bx,es:sp_back_handle
    CloseBitmap
    mov bx,es:sp_bitmap_handle
    or bx,bx
    jz delete_sprite_bitmap_closed
;
    CloseBitmap

delete_sprite_bitmap_closed:
    test fs:sp_flags,SP_FLAG_VISIBLE
    jz delete_sprite_free
;
	mov ax,es
	mov fs,ax
	call hide
	xor ax,ax
	mov fs,ax
	mov gs,ax

delete_sprite_free:
    pop bx
    FreeMem
	FreeHandle
;
	popad
	pop gs
	pop fs
	pop es
	pop ds
	clc
	ret
delete_sprite	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseSprite
;
;		DESCRIPTION:	Close sprite
;
;		PARAMETERS:		BX		Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_sprite_name	DB 'Close Sprite', 0

close_sprite	Proc far
	push ds
	push ax
	push bx
;
	mov ax,SPRITE_HANDLE
	DerefHandle
	jc cl_sprite_done
;
	call delete_sprite

cl_sprite_done:
	pop bx
	pop ax
	pop ds
	retf32
close_sprite	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_handle
;
;		DESCRIPTION:	BX			Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push ax
	push bx
;
	mov ax,SPRITE_HANDLE
	DerefHandle
	jc delete_handle_done
;
	call delete_sprite

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

	public init_sprite

init_sprite	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov ax,SPRITE_HANDLE
	mov di,OFFSET delete_handle
	RegisterHandle
;
	mov si,OFFSET create_sprite
	mov di,OFFSET create_sprite_name
	xor dx,dx
	mov ax,create_sprite_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET show_sprite
	mov di,OFFSET show_sprite_name
	xor dx,dx
	mov ax,show_sprite_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET hide_sprite
	mov di,OFFSET hide_sprite_name
	xor dx,dx
	mov ax,hide_sprite_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET move_sprite
	mov di,OFFSET move_sprite_name
	xor dx,dx
	mov ax,move_sprite_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_sprite
	mov di,OFFSET close_sprite_name
	xor dx,dx
	mov ax,close_sprite_nr
	RegisterBimodalUserGate
;
	ret
init_sprite	ENDP

code	ENDS

	END
