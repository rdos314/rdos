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
;		NAME:           CheckSprite
;
;		DESCRIPTION:	Check if sprite structures are valid 
;
;		PARAMETERS:		FS		sprite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckSprite	Proc near
	push ds
	push es
	push fs
	push gs
	pushad
;
	mov ds,fs:sp_dest_sel
    mov si,ds:v_sprite_lines
    mov cx,ds:v_sprite_count
    mov es,ds:v_sprite_sel
	xor di,di
	or cx,cx
	jz check_sprite_done
;

check_sprite_loop:
	mov fs,es:[di].spi_sel
	mov ax,fs:sp_x
	cmp ax,es:[di].spi_x_min
	je check_sprite_x_min_ok
;
	int 3

check_sprite_x_min_ok:
	add ax,fs:sp_w
	dec ax
	cmp ax,es:[di].spi_x_max
	je check_sprite_x_max_ok
;
	int 3

check_sprite_x_max_ok:
	mov ax,fs:sp_y
	cmp ax,es:[di].spi_y_min
	je check_sprite_y_min_ok
;
	int 3

check_sprite_y_min_ok:
	add ax,fs:sp_h
	dec ax
	cmp ax,es:[di].spi_y_max
	je check_sprite_y_max_ok
;
	int 3

check_sprite_y_max_ok:
	test fs:sp_flags,SP_FLAG_VISIBLE
	jz check_sprite_next
;
	test es:[di].spi_flags,SP_FLAG_VISIBLE
	jnz check_sprite_limits
;
	int 3

check_sprite_limits:
	mov ax,fs:sp_index
	mov bx,fs:sp_y
	mov bp,fs:sp_h
	shl bx,2
	or bp,bp
	jz check_sprite_next

check_sprite_line_loop:
	mov dx,ds:[bx+si].spl_lower_ind
	cmp dx,-1
	jne check_sprite_lower_not_free
;
	int 3

check_sprite_lower_not_free:
	cmp ax,dx
	jae check_sprite_lower_ok
;
	int 3

check_sprite_lower_ok:
	mov dx,ds:[bx+si].spl_upper_ind
	cmp dx,-1
	jne check_sprite_upper_not_free
;
	int 3

check_sprite_upper_not_free:
	cmp ax,dx
	jbe check_sprite_upper_ok
;
	int 3

check_sprite_upper_ok:
	add bx,4
	sub bp,1
	jnz check_sprite_line_loop

check_sprite_next:
	add di,16
	loop check_sprite_loop

check_sprite_done:
	popad
	pop gs
	pop fs
	pop es
	pop ds
	ret
CheckSprite	Endp

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
    mov ax,ds:v_sprite_sel
    or ax,ax
    jnz create_sprite_sel_ok
;
    push es
    mov eax,4 * 16
    AllocateSmallKernelMem
    mov ds:v_sprite_sel,es
    mov ds:v_sprite_count,0
    mov ds:v_sprite_size,4
    pop es

create_sprite_sel_ok:
    mov ax,ds:v_sprite_count
    cmp ax,ds:v_sprite_size
    jne create_sprite_room
;
    cmp ax,1000h
    je create_sprite_fail
;
    mov ax,ds:v_sprite_size
    add ax,ax
    mov ds:v_sprite_size,ax
    movzx eax,ax
    shl eax,4
    push ds
    push es
    push cx
    push si
    push di
    mov cx,ds:v_sprite_size
    add cx,cx
    mov ds,ds:v_sprite_sel
    AllocateSmallKernelMem
    xor si,si
    xor di,di             
    rep movsd
    mov ax,es
    mov cx,ds
    mov es,cx
    xor cx,cx
    mov ds,cx
    FreeMem
    pop di
    pop si
    pop cx
    pop es
    pop ds
    mov ds:v_sprite_sel,ax

create_sprite_room:
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
    mov ds,es:sp_dest_sel
    mov bx,ds:v_sprite_count
    mov es:sp_index,bx
    shl bx,4
    inc ds:v_sprite_count
    mov ds,ds:v_sprite_sel
    mov ds:[bx].spi_sel,es
    mov ax,es:sp_w
    mov ds:[bx].spi_width,ax
    mov ax,es:sp_h
    mov ds:[bx].spi_height,ax
    mov ds:[bx].spi_flags,0
    mov ds:[bx].spi_x_min,0
    mov ds:[bx].spi_y_min,0
    mov ax,es:sp_w
    dec ax
    mov ds:[bx].spi_x_max,ax
    mov ax,es:sp_h
    dec ax
    mov ds:[bx].spi_y_max,ax
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
;                       DS:BX   Hiding sprite info
;                       FS		Current sprite
;                       CX      X relative position
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HideLine    MACRO x, y
    local hide_line_done
    local hide_line_pos
    local hide_line_do

	add dx,fs:&y
	sub dx,ds:[bx].spi_y_min
	jc hide_line_done
;
	cmp dx,ds:[bx].spi_height
	jae hide_line_done
;
    mov cx,fs:&x
    sub cx,ds:[bx].spi_x_min
    jge hide_line_pos
;
    mov ax,fs:sp_w
    add ax,cx
    jle hide_line_done
;
    xor cx,cx
	cmp ax,ds:[bx].spi_width
	jc hide_line_do
;
	mov ax,ds:[bx].spi_width
    jmp hide_line_do

hide_line_pos:
    cmp cx,ds:[bx].spi_width
    jae hide_line_done
;
    mov ax,ds:[bx].spi_width
    sub ax,cx

hide_line_do:
    push ds
	push gs
    mov gs,ds:[bx].spi_sel
    mov ds,gs:sp_back_sel
    call ds:get_line_proc
;
    mov ds,gs:sp_dest_sel
    add cx,gs:sp_x
    add dx,gs:sp_y
    call ds:set_native_row_proc
	pop gs
    pop ds

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
;                       DS:BX   Hiding sprite info
;                       FS      Current sprite
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SaveLine    MACRO x, y
    local save_line_done
    local save_line_pos
    local save_line_do

	add dx,fs:&y
	sub dx,ds:[bx].spi_y_min
	jc save_line_done
;
	cmp dx,ds:[bx].spi_height
	jae save_line_done
;
    mov cx,fs:&x
    sub cx,ds:[bx].spi_x_min
    jge save_line_pos
;
    mov ax,fs:sp_w
    add ax,cx
    jle save_line_done
;
    xor cx,cx
	cmp ax,ds:[bx].spi_width
	jc save_line_do
;
	mov ax,ds:[bx].spi_width
    jmp save_line_do

save_line_pos:
    cmp cx,ds:[bx].spi_width
    jae save_line_done
;
    mov ax,ds:[bx].spi_width
    sub ax,cx

save_line_do:
    push ds
	push gs
    mov gs,ds:[bx].spi_sel
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
	pop gs
    pop ds

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
;                       DS:BX   Hiding sprite info
;                       FS      Current sprite
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ShowLine    MACRO x, y
    local show_line_done
    local show_line_pos
    local show_line_do

	add dx,fs:&y
	sub dx,ds:[bx].spi_y_min
	jc show_line_done
;
	cmp dx,ds:[bx].spi_height
	jae show_line_done
;
    mov cx,fs:&x
    sub cx,ds:[bx].spi_x_min
    jge show_line_pos
;
    mov ax,fs:sp_w
    add ax,cx
    jle show_line_done
;
    xor cx,cx
	cmp ax,ds:[bx].spi_width
	jc show_line_do
;
	mov ax,ds:[bx].spi_width
    jmp show_line_do

show_line_pos:
    cmp cx,ds:[bx].spi_width
    jae show_line_done
;
    mov ax,ds:[bx].spi_width
    sub ax,cx

show_line_do:
    push ds
	push gs
    push bx
    push bp
    mov bp,ax
;
    mov gs,ds:[bx].spi_sel
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
    pop bp
    pop bx
	pop gs
    pop ds

show_line_done:
            ENDM

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HideLineBuffer
;
;		DESCRIPTION:	Hide in line buffer
;
;		PARAMETERS:		Y       y in current sprite
;                       DS:BX   Hiding sprite info
;                       FS      Current sprite
;                       GS      Dest sel
;                       DX      Y relative
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


HideLineBuffer  MACRO y
    local not_upper
    local empty
    local upper_loop
    local lower_loop
    local done

    add dx,fs:&y
    mov si,dx
    shl si,2
    add si,gs:v_sprite_lines
    mov ax,fs:sp_index
    cmp ax,gs:[si].spl_upper_ind
    jne not_upper
;
    cmp ax,gs:[si].spl_lower_ind
    je empty
;
    push bx

upper_loop:
    sub bx,16
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
	jz upper_loop
;
    cmp dx,ds:[bx].spi_y_min
    jb upper_loop
;
    cmp dx,ds:[bx].spi_y_max
    ja upper_loop
;
    shr bx,4
    mov gs:[si].spl_upper_ind,bx
    pop bx
    jmp done

empty:
    mov gs:[si].spl_lower_ind,-1
    mov gs:[si].spl_upper_ind,-1
    jmp done

not_upper:
    cmp ax,gs:[si].spl_lower_ind
    jne done
;
    push bx

lower_loop:
    add bx,16
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
	jz lower_loop
;
    cmp dx,ds:[bx].spi_y_min
    jb lower_loop
;
    cmp dx,ds:[bx].spi_y_max
    ja lower_loop
;
    shr bx,4
    mov gs:[si].spl_lower_ind,bx
    pop bx

done:
        ENDM

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ShowLineBuffer
;
;		DESCRIPTION:	Show in line buffer
;
;		PARAMETERS:		Y       y in current sprite
;                       FS      Current sprite
;                       GS      Dest sel
;                       DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowLineBuffer  MACRO y
    local empty
    local not_upper
    local done

    add dx,fs:&y
    mov si,dx
    shl si,2
    add si,gs:v_sprite_lines
    mov ax,fs:sp_index
    mov dx,gs:[si].spl_upper_ind
    cmp dx,-1
    je empty
;
    cmp ax,dx
    jb not_upper
;
    mov gs:[si].spl_upper_ind,ax
    jmp done

not_upper:
    cmp ax,gs:[si].spl_lower_ind
    ja done
;
    mov gs:[si].spl_lower_ind,ax
    jmp done

empty:
    mov gs:[si].spl_lower_ind,ax
    mov gs:[si].spl_upper_ind,ax

done:
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
    mov gs,fs:sp_dest_sel
    mov ds,gs:v_sprite_sel
    mov si,fs:sp_y
    shl si,2
    add si,gs:v_sprite_lines

hide_sprite_loop:
	mov bx,gs:[si].spl_upper_ind
	shl bx,4
	push bx
	push si

hide_sprite_ovl_loop:
    mov dx,fs
	cmp dx,ds:[bx].spi_sel
	je hide_sprite_curr
;
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
	jz hide_sprite_ovl_next
;
    mov dx,bp
    HideLine sp_x, sp_y

hide_sprite_ovl_next:
    sub bx,16
	jmp hide_sprite_ovl_loop

hide_sprite_curr:
    mov dx,bp
    HideLineBuffer sp_y
;
	push ds
	push bx
    mov dx,bp
    HideWholeLine
    pop bx
    pop ds
;
    and ds:[bx].spi_flags,NOT SP_FLAG_VISIBLE    
    pop si
	pop cx
;
	push si
	cmp bx,cx
	je hide_sprite_line_done
;
    add bx,16

hide_sprite_ovl_show_loop:
    cmp bx,cx
	ja hide_sprite_line_done
;
	push cx
	test ds:[bx].spi_flags,SP_FLAG_VISIBLE
	jz hide_sprite_ovl_show_next
;
    mov dx,bp
    SaveLine sp_x, sp_y
;
    mov dx,bp
    ShowLine sp_x, sp_y

hide_sprite_ovl_show_next:
	add bx,16
	pop cx
	jmp hide_sprite_ovl_show_loop

hide_sprite_line_done:
	pop si
	add si,4
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
    mov gs,fs:sp_dest_sel
    mov ds,gs:v_sprite_sel
    mov si,fs:sp_y
    shl si,2
    add si,gs:v_sprite_lines

show_sprite_loop:
	mov bx,gs:[si].spl_upper_ind
	push bx
	push si
	cmp bx,-1
	je show_sprite_curr
;
	shl bx,4

show_sprite_ovl_hide_loop:
	mov dx,fs
	cmp dx,ds:[bx].spi_sel
	je show_sprite_curr
;
	test ds:[bx].spi_flags,SP_FLAG_VISIBLE
	jz show_sprite_ovl_hide_next
;
    mov dx,bp
    HideLine sp_x, sp_y

show_sprite_ovl_hide_next:
    sub bx,16
	jnc show_sprite_ovl_hide_loop

show_sprite_curr:
    mov dx,bp
    ShowLineBuffer sp_y
;
    push ds
    mov dx,bp
    SaveAndShowWholeLine
    pop ds
;
	mov bx,fs:sp_index
	shl bx,4
    or ds:[bx].spi_flags,SP_FLAG_VISIBLE
    pop si
    pop cx
;
	push si
	cmp cx,-1
	je show_sprite_line_done
;
	shl cx,4
	cmp bx,cx
	je show_sprite_line_done
;
    add bx,16

show_sprite_ovl_show_loop:
    cmp bx,cx
	ja show_sprite_line_done
;
	push cx
	test ds:[bx].spi_flags,SP_FLAG_VISIBLE
	jz show_sprite_ovl_show_next
;
    mov dx,bp
    SaveLine sp_x, sp_y
;
    mov dx,bp
    ShowLine sp_x, sp_y

show_sprite_ovl_show_next:
	add bx,16
	pop cx
	jmp show_sprite_ovl_show_loop

show_sprite_line_done:
	pop si
	add si,4
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

MoveSpriteLine	Proc near
    mov bx,fs:sp_index
	mov ax,gs:[si].spl_upper_ind
	cmp ax,-1
	je move_sprite_new_ind
;
    cmp ax,bx
    jc move_sprite_new_ind
;
    mov bx,ax

move_sprite_new_ind:
    mov ax,gs:[di].spl_upper_ind
    cmp ax,-1
    je move_sprite_ind_ok
;
    cmp ax,bx
    jc move_sprite_ind_ok
;
    mov bx,ax

move_sprite_ind_ok:
    mov bx,cx
    dec bx
	shl bx,4
	push bx

move_sprite_hide_loop:
	mov dx,fs
	cmp dx,ds:[bx].spi_sel
	je move_sprite_curr
;
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
	jz move_sprite_hide_next
;
    mov dx,bp
    HideLine sp_x, sp_y
;
    mov dx,bp
    HideLine sp_new_x, sp_new_y

move_sprite_hide_next:
    sub bx,16
	jnc move_sprite_hide_loop

move_sprite_curr:
	mov bx,fs:sp_index
	shl bx,4
;
    mov dx,bp
    HideLineBuffer sp_y
;
    mov dx,bp
    ShowLineBuffer sp_new_y
;
    push ds
    mov dx,bp
    HideWholeLine
    mov dx,bp
    SaveAndShowWholeLine
    pop ds
;
    pop cx
	mov bx,fs:sp_index
	shl bx,4
	cmp bx,cx
	je move_sprite_line_done
;
    add bx,16

move_sprite_show_loop:
    cmp bx,cx
	ja move_sprite_line_done
;
	push cx
	test ds:[bx].spi_flags,SP_FLAG_VISIBLE
	jz move_sprite_show_next
;
    mov dx,bp
    SaveLine sp_x, sp_y
;
    mov dx,bp
    SaveLine sp_new_x, sp_new_y
;
    mov dx,bp
    ShowLine sp_x, sp_y
;
    mov dx,bp
    ShowLine sp_new_x, sp_new_y

move_sprite_show_next:
	add bx,16
	pop cx
	jnc move_sprite_show_loop

move_sprite_line_done:
	ret
MoveSpriteLine	Endp

move_sprite	Proc far
	push ds
	push es
	push fs
	push gs
	pushad
;
	mov ax,SPRITE_HANDLE
	DerefHandle
	jc move_sprite_done
;
    mov fs,ds:[bx].sp_sel
    mov fs:sp_new_x,cx
    mov fs:sp_new_y,dx
;
    test fs:sp_flags,SP_FLAG_VISIBLE
    jz move_sprite_coord
;
    cmp cx,fs:sp_x
    jne move_sprite_move
;
    cmp dx,fs:sp_y
    je move_sprite_coord

move_sprite_move:
	call CheckSprite
    mov gs,fs:sp_dest_sel
    mov cx,gs:v_sprite_count
    mov ds,gs:v_sprite_sel
    mov si,fs:sp_y
    shl si,2
    add si,gs:v_sprite_lines
	mov di,fs:sp_new_y
	shl di,2
	add di,gs:v_sprite_lines
;
	mov dx,fs:sp_new_y
	cmp dx,fs:sp_y
	ja move_sprite_up

move_sprite_down:
    xor bp,bp

move_sprite_down_loop:
    push cx
    push si
    push di
	call MoveSpriteLine
	pop di
	pop si
	pop cx
	add si,4
	add di,4
    inc bp
    cmp bp,fs:sp_h
    jnz move_sprite_down_loop
	jmp move_sprite_coord

move_sprite_up:
	mov bp,fs:sp_h
	dec bp

move_sprite_up_loop:
    push cx
    push si
    push di
	call MoveSpriteLine
	pop di
	pop si
	pop cx
	add si,4
	add di,4
	sub bp,1
	jnc move_sprite_up_loop

move_sprite_coord:
	mov ax,fs:sp_new_x
	mov fs:sp_x,ax
	mov ax,fs:sp_new_y
	mov fs:sp_y,ax
;
    mov ds,fs:sp_dest_sel
    mov bx,fs:sp_index
    mov ds,ds:v_sprite_sel
    shl bx,4
    mov ax,fs:sp_x
    mov ds:[bx].spi_x_min,ax
    add ax,fs:sp_w
    dec ax
    mov ds:[bx].spi_x_max,ax
    mov ax,fs:sp_y
    mov ds:[bx].spi_y_min,ax
    add ax,fs:sp_h
    dec ax
    mov ds:[bx].spi_y_max,ax
    clc

move_sprite_done:
	popad
	pop gs
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
	push es
    push fs
    push gs
	pushad
;
    mov fs,[bx].sp_sel
    push ds
    push bx
;
	test fs:sp_flags,SP_FLAG_VISIBLE
    jz delete_sprite_hidden
;
	call hide

delete_sprite_hidden:
	mov ds,fs:sp_dest_sel
    mov cx,ds:v_sprite_count
    sub ds:v_sprite_count,1
    jnz delete_sprite_ind_shift
;
    mov es,ds:v_sprite_sel
    FreeMem
    mov ds:v_sprite_sel,0
    mov ds:v_sprite_size,0
    jmp delete_sprite_ind_done

delete_sprite_ind_shift:
    mov ds,ds:v_sprite_sel
    shl cx,4
    mov si,fs:sp_index
    shl si,4
    mov di,si
    add si,16

delete_sprite_ind_loop:
    cmp si,cx
    je delete_sprite_ind_done
;
    mov es,ds:[si].spi_sel
    dec es:sp_index
;
    mov eax,[si]
    mov [di],eax
    add si,4
    add di,4
;
    mov eax,[si]
    mov [di],eax
    add si,4
    add di,4
;
    mov eax,[si]
    mov [di],eax
    add si,4
    add di,4
;
    mov eax,[si]
    mov [di],eax
    add si,4
    add di,4
    jmp delete_sprite_ind_loop

delete_sprite_ind_done:
    mov ds,fs:sp_dest_sel
    mov cx,ds:v_height
    mov si,ds:v_sprite_lines
    mov ax,fs:sp_index

delete_sprite_spl_loop:
    mov dx,ds:[si].spl_lower_ind
    cmp dx,-1
    je delete_sprite_spl_next
;
    cmp ax,dx
    jae delete_sprite_check_upper
;
    dec dx
    mov ds:[si].spl_lower_ind,dx

delete_sprite_check_upper:
    cmp ax,ds:[si].spl_upper_ind
    jae delete_sprite_spl_next
;
    dec ds:[si].spl_upper_ind

delete_sprite_spl_next:
    add si,4
    loop delete_sprite_spl_loop
;
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
;
    mov bx,es:sp_back_handle
    CloseBitmap
    mov bx,es:sp_bitmap_handle
    or bx,bx
    jz delete_sprite_free
;
    CloseBitmap

delete_sprite_free:
    pop bx
    pop ds
    FreeMem
	FreeHandle
;
	popad
	pop gs
	pop fs
	pop es
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
