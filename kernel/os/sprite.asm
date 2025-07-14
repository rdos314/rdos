;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; SPRITE.ASM
; Sprite module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.inc
INCLUDE ..\handle.inc
INCLUDE bitmap.inc
INCLUDE sprite.inc
INCLUDE video.inc
INCLUDE ..\apicheck.inc

code    SEGMENT byte public 'CODE'

    .386

    assume cs:code



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:       CheckSprite
;
;           DESCRIPTION:    Check if sprite structures are valid 
;
;           PARAMETERS:         FS          sprite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckSprite     Proc near
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
    sub cx,1
    jnz check_sprite_loop

check_sprite_done:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
CheckSprite     Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:       CreateSprite
;
;           DESCRIPTION:    Create a new sprite
;
;           PARAMETERS:         AX          LGOP
;               BX      Dest bitmap handle or 0
;               CX      Main bitmap
;               DX      Mask (1-bit bitmap)
;
;           RETURNS:        BX      Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_sprite_name      DB 'Create Sprite', 0

create_sprite   Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

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
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc create_sprite_fail
;
    mov ax,[ebx].bm_x_min
    mov es:sp_x_min,ax
    mov ax,[ebx].bm_y_min
    mov es:sp_y_min,ax
    mov ax,[ebx].bm_x_max
    mov es:sp_x_max,ax
    mov ax,[ebx].bm_y_max
    mov es:sp_y_max,ax
    mov ax,[ebx].bm_sel
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
    push ecx
    push esi
    push edi
    movzx ecx,ds:v_sprite_size
    add ecx,ecx
    mov ds,ds:v_sprite_sel
    AllocateSmallKernelMem
    xor esi,esi
    xor edi,edi         
    rep movsd
    mov ax,es
    mov cx,ds
    mov es,cx
    xor cx,cx
    mov ds,cx
    FreeMem
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    mov ds:v_sprite_sel,ax

create_sprite_room:
    mov bx,cx
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc create_sprite_fail
;
    mov ax,[ebx].bm_sel
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
    mov ax,[ebx].bm_sel
    mov es:sp_bitmap_sel,ax

create_sprite_mask:
    mov bx,dx
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc create_sprite_fail
;
    mov ax,[ebx].bm_sel
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
    mov ax,[ebx].bm_sel
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
    mov ds:[ebx].spi_sel,es
    mov ax,es:sp_w
    mov ds:[ebx].spi_width,ax
    mov ax,es:sp_h
    mov ds:[ebx].spi_height,ax
    mov ds:[ebx].spi_flags,0
    mov ds:[ebx].spi_x_min,0
    mov ds:[ebx].spi_y_min,0
    mov ax,es:sp_w
    dec ax
    mov ds:[ebx].spi_x_max,ax
    mov ax,es:sp_h
    dec ax
    mov ds:[ebx].spi_y_max,ax
;
    mov cx,SIZE sprite_struc
    AllocateHandle
    mov ds:[ebx].sp_sel,es
    mov [ebx].hh_sign,SPRITE_HANDLE
    mov bx,[ebx].hh_handle
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

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    ret
create_sprite   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HideWholeLine
;
;           DESCRIPTION:    Hide a whole line in a sprite macro
;
;           PARAMETERS:         FS          Sprite handle
;               DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HideWholeLine    MACRO
    local hide_whole
    local hide_done

    mov cx,fs:sp_x
    test ch,80h
    jz hide_whole
;
    mov ds,fs:sp_back_sel
    mov ax,fs:sp_w
    neg cx
    sub ax,cx
    jbe hide_done
;
    push ax
    call fword ptr ds:v_get_line_proc
    mov bl,al
    pop ax
;
    mov ds,fs:sp_dest_sel
    xor cx,cx
    add dx,fs:sp_y
    call fword ptr ds:v_set_sprite_row_proc
    jmp hide_done

hide_whole:
    mov ds,fs:sp_back_sel
    xor cx,cx
    call fword ptr ds:v_get_line_proc
    mov bl,al
    mov ax,fs:sp_w
;
    mov ds,fs:sp_dest_sel
    mov cx,fs:sp_x
    add dx,fs:sp_y
    call fword ptr ds:v_set_sprite_row_proc

hide_done:
        ENDM



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SaveAndShowWholeLine
;
;           DESCRIPTION:    Save & show a whole line in a sprite macro
;
;           PARAMETERS:         FS          Sprite handle
;               DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveAndShowWholeLine    MACRO
    local save_whole
    local save_done
    local save_whole_width_ok

    mov ds,fs:sp_dest_sel
    mov cx,fs:sp_new_x
    test ch,80h
    jz save_whole
;
    xor cx,cx
    add dx,fs:sp_new_y
    call fword ptr ds:v_get_line_proc
    mov bl,al
    mov ax,ds:v_x_max
;
    mov ds,fs:sp_back_sel
    mov cx,fs:sp_new_x
    neg cx
    sub dx,fs:sp_new_y
    mov ax,fs:sp_w
    sub ax,cx
    jbe save_done
;
    push cx
    call fword ptr ds:v_set_sprite_row_proc
;
    mov ds,fs:sp_bitmap_sel
    call fword ptr ds:v_get_line_proc
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
    pop cx
    mov ds:v_lgop,LGOP_NONE
    add dx,fs:sp_new_y
    mov ax,cx
    movzx ecx,dx
    shl ecx,16
    mov dx,fs:sp_w
    sub dx,ax
    and al,7
    call fword ptr ds:v_draw_sprite_line_proc
    jmp save_done

save_whole:
    add dx,fs:sp_new_y
    call fword ptr ds:v_get_line_proc
    mov bl,al
    mov ax,ds:v_x_max
    sub ax,cx
    jc save_done
;
    cmp ax,fs:sp_w
    jbe save_whole_width_ok
;
    mov ax,fs:sp_w

save_whole_width_ok:    
    mov ds,fs:sp_back_sel
    xor cx,cx
    sub dx,fs:sp_new_y
    call fword ptr ds:v_set_sprite_row_proc
;
    mov ds,fs:sp_bitmap_sel
    call fword ptr ds:v_get_line_proc
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
    mov ds:v_lgop,LGOP_NONE
    add dx,fs:sp_new_y
    movzx ecx,dx
    shl ecx,16
    mov cx,fs:sp_new_x
    mov dx,fs:sp_w
    xor al,al
    call fword ptr ds:v_draw_sprite_line_proc

save_done:
        ENDM



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HideLine
;
;           DESCRIPTION:    Hide a line in a sprite macro
;
;           PARAMETERS:         X       x in current sprite
;               Y       y in current sprite
;               DS:BX   Hiding sprite info
;               FS          Current sprite
;               CX      X relative position
;               DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HideLine    MACRO x, y
    local hide_line_done
    local hide_line_pos
    local hide_line_do

    add dx,fs:&y
    sub dx,ds:[bx].spi_y_min
    jl hide_line_done
;
    cmp dx,ds:[bx].spi_height
    jge hide_line_done
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
    jl hide_line_do
;
    mov ax,ds:[bx].spi_width
    jmp hide_line_do

hide_line_pos:
    cmp cx,ds:[bx].spi_width
    jge hide_line_done
;
    mov ax,ds:[bx].spi_width
    sub ax,cx

hide_line_do:
    push ds
    push gs
    mov gs,ds:[bx].spi_sel
    mov ds,gs:sp_back_sel
    push bx
    push ax
    call fword ptr ds:v_get_line_proc
    mov bl,al
    pop ax
;
    mov ds,gs:sp_dest_sel
    add cx,gs:sp_x
    add dx,gs:sp_y
    call fword ptr ds:v_set_sprite_row_proc
    pop bx
    pop gs
    pop ds

hide_line_done:
        ENDM



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SaveLine
;
;           DESCRIPTION:    Save a line in a sprite macro
;
;           PARAMETERS:         X       x in current sprite
;               Y       y in current sprite
;               DS:BX   Hiding sprite info
;               FS      Current sprite
;               DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SaveLine    MACRO x, y
    local save_line_done
    local save_line_pos
    local save_line_do
    local save_line_sprite_ok
    local save_line_width_ok
    
    add dx,fs:&y
    sub dx,ds:[bx].spi_y_min
    jl save_line_done
;
    cmp dx,ds:[bx].spi_height
    jge save_line_done
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
    jl save_line_do
;
    mov ax,ds:[bx].spi_width
    jmp save_line_do

save_line_pos:
    cmp cx,ds:[bx].spi_width
    jge save_line_done
;
    mov ax,ds:[bx].spi_width
    sub ax,cx

save_line_do:
    push ds
    push gs
    push si
    mov gs,ds:[bx].spi_sel
    mov ds,gs:sp_dest_sel
    add cx,gs:sp_new_x
    add dx,gs:sp_new_y
    push bx
    push ax
    call fword ptr ds:v_get_line_proc
    mov bl,al
    pop ax
    mov si,ds:v_x_max
    sub si,cx
    jc save_line_sprite_ok
;
    cmp dx,ds:v_y_max
    ja save_line_sprite_ok   
;    
    mov ds,gs:sp_back_sel
    sub cx,gs:sp_new_x
    sub dx,gs:sp_new_y    
    cmp ax,si
    jbe save_line_width_ok
;
    mov ax,si

save_line_width_ok:    
    call fword ptr ds:v_set_sprite_row_proc

save_line_sprite_ok:    
    pop bx
    pop si
    pop gs
    pop ds

save_line_done:
        ENDM



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ShowLine
;
;           DESCRIPTION:    Show a line in a sprite macro
;
;           PARAMETERS:         X       x in current sprite
;               Y       y in current sprite
;               DS:BX   Hiding sprite info
;               FS      Current sprite
;               DX      Y relative position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ShowLine    MACRO x, y
    local show_line_done
    local show_line_pos
    local show_line_do

    add dx,fs:&y
    sub dx,ds:[bx].spi_y_min
    jl show_line_done
;
    cmp dx,ds:[bx].spi_height
    jge show_line_done
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
    jl show_line_do
;
    mov ax,ds:[bx].spi_width
    jmp show_line_do

show_line_pos:
    cmp cx,ds:[bx].spi_width
    jge show_line_done
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
    call fword ptr ds:v_get_line_proc
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
    mov ds:v_lgop,LGOP_NONE
    add dx,gs:sp_new_y
    shl edx,16
    mov al,cl
    and al,7
    add cx,gs:sp_new_x
    movzx ecx,cx
    or ecx,edx
    mov dx,bp
    call fword ptr ds:v_draw_sprite_line_proc
    pop bp
    pop bx
    pop gs
    pop ds

show_line_done:
        ENDM



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HideLineBuffer
;
;           DESCRIPTION:    Hide in line buffer
;
;           PARAMETERS:         Y       y in current sprite
;               DS:BX   Hiding sprite info
;               FS      Current sprite
;               GS      Dest sel
;               DX      Y relative
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


HideLineBuffer  MACRO y
    local not_upper
    local empty
    local upper_loop
    local upper_dec
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
    or bx,bx
    jnz upper_dec
;
    pop bx
    jmp done

upper_dec:
    sub bx,16
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
    jz upper_loop
;
    cmp dx,ds:[bx].spi_y_min
    jl upper_loop
;
    cmp dx,ds:[bx].spi_y_max
    jg upper_loop
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
    jl lower_loop
;
    cmp dx,ds:[bx].spi_y_max
    jg lower_loop
;
    shr bx,4
    mov gs:[si].spl_lower_ind,bx
    pop bx

done:
    ENDM



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ShowLineBuffer
;
;           DESCRIPTION:    Show in line buffer
;
;           PARAMETERS:         Y       y in current sprite
;               FS      Current sprite
;               GS      Dest sel
;               DX      Y relative position
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
    jl not_upper
;
    mov gs:[si].spl_upper_ind,ax
    jmp done

not_upper:
    cmp ax,gs:[si].spl_lower_ind
    jg done
;
    mov gs:[si].spl_lower_ind,ax
    jmp done

empty:
    mov gs:[si].spl_lower_ind,ax
    mov gs:[si].spl_upper_ind,ax

done:
    ENDM



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           hide
;
;           DESCRIPTION:    Hide sprite
;
;           PARAMETERS:         FS          Sprite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide    Proc near
    xor bp,bp
    mov gs,fs:sp_dest_sel
    mov ds,gs:v_sprite_sel
    mov si,fs:sp_y
    shl si,2
    add si,gs:v_sprite_lines

hide_sprite_loop:
    cmp si,gs:v_sprite_lines
    jb hide_sprite_line_next
;
    cmp si,gs:v_sprite_max_pos
    jae hide_donep
;
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

hide_sprite_line_next:
    add si,4
    inc bp
    cmp bp,fs:sp_h
    jnz hide_sprite_loop

hide_donep:
    and fs:sp_flags,NOT SP_FLAG_VISIBLE
    ret
hide    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           show
;
;           DESCRIPTION:    Show sprite
;
;           PARAMETERS:         FS          Sprite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show    Proc near
    or fs:sp_flags,SP_FLAG_VISIBLE
    xor bp,bp
    mov gs,fs:sp_dest_sel
    mov ds,gs:v_sprite_sel
    mov si,fs:sp_y
    shl si,2
    add si,gs:v_sprite_lines

show_sprite_loop:
    cmp si,gs:v_sprite_lines
    jb show_sprite_line_next
;
    cmp si,gs:v_sprite_max_pos
    jae show_done
;
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

show_sprite_line_next:
    add si,4
    inc bp
    cmp bp,fs:sp_h
    jnz show_sprite_loop

show_done:
    ret
show    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HideSprite
;
;           DESCRIPTION:    Hide sprite
;
;           PARAMETERS:         BX          Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_sprite_name    DB 'Hide Sprite', 0

hide_sprite     Proc far
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
    mov fs,ds:[ebx].sp_sel
    mov ds,fs:sp_dest_sel
    EnterSection ds:v_sprite_section
;
    test fs:sp_flags,SP_FLAG_VISIBLE
    jz hide_sprite_leave
;
    push ds:v_x_min
    push ds:v_y_min
    push ds:v_x_max
    push ds:v_y_max
    push ds:v_lgop
;
    mov ax,fs:sp_x_min
    mov ds:v_x_min,ax
    mov ax,fs:sp_y_min
    mov ds:v_y_min,ax
    mov ax,fs:sp_x_max
    mov ds:v_x_max,ax
    mov ax,fs:sp_y_max
    mov ds:v_y_max,ax
    mov ds:v_lgop,LGOP_NONE
    push ds
    call hide
    pop ds
;
    pop ds:v_lgop
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min

hide_sprite_leave:
    mov ds,fs:sp_dest_sel
    LeaveSection ds:v_sprite_section

hide_sprite_done:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
hide_sprite     Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ShowSprite
;
;           DESCRIPTION:    Show sprite
;
;           PARAMETERS:         BX          Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_sprite_name    DB 'Show Sprite', 0

show_sprite     Proc far
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
    mov fs,ds:[ebx].sp_sel
    mov ds,fs:sp_dest_sel
    EnterSection ds:v_sprite_section
;
    test fs:sp_flags,SP_FLAG_VISIBLE
    jnz show_sprite_leave
;
    push ds:v_x_min
    push ds:v_y_min
    push ds:v_x_max
    push ds:v_y_max
    push ds:v_lgop
;
    mov ax,fs:sp_x_min
    mov ds:v_x_min,ax
    mov ax,fs:sp_y_min
    mov ds:v_y_min,ax
    mov ax,fs:sp_x_max
    mov ds:v_x_max,ax
    mov ax,fs:sp_y_max
    mov ds:v_y_max,ax
    mov ds:v_lgop,LGOP_NONE
    push ds
    call show
    pop ds
;
    pop ds:v_lgop
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min

show_sprite_leave:
    mov ds,fs:sp_dest_sel
    LeaveSection ds:v_sprite_section
    clc

show_sprite_done:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
show_sprite     Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MoveSprite
;
;           DESCRIPTION:    Move sprite
;
;           PARAMETERS:         BX          Sprite handle
;               CX      x
;               DX      y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_sprite_name    DB 'Move Sprite', 0

MoveSpriteLine  Proc near
    cmp si,gs:v_sprite_lines
    jb move_sprite_not_first
;
    cmp si,gs:v_sprite_max_pos
    jae move_sprite_not_first
;
    cmp di,gs:v_sprite_lines
    jb move_sprite_only_first
;
    cmp di,gs:v_sprite_max_pos
    jae move_sprite_only_first
;
    mov bx,fs:sp_index
;
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
    jmp move_sprite_line_done

move_sprite_not_first:
    cmp di,gs:v_sprite_lines
    jb move_sprite_line_done
;
    cmp di,gs:v_sprite_max_pos
    jae move_sprite_line_done

move_sprite_only_last:
    mov bx,fs:sp_index
    mov ax,gs:[di].spl_upper_ind
    cmp ax,-1
    je move_sprite_last_ind_ok
;
    cmp ax,bx
    jc move_sprite_last_ind_ok
;
    mov bx,ax

move_sprite_last_ind_ok:
    shl bx,4
    push bx
;
    mov bx,fs:sp_index
    shl bx,4
;
    mov dx,bp
    ShowLineBuffer sp_new_y
;
    push ds
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

move_sprite_last_show_loop:
    cmp bx,cx
    ja move_sprite_line_done
;
    push cx
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
    jz move_sprite_last_show_next
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

move_sprite_last_show_next:
    add bx,16
    pop cx
    jnc move_sprite_last_show_loop
    jmp move_sprite_line_done

move_sprite_only_first:
    mov bx,fs:sp_index
;
    mov ax,gs:[si].spl_upper_ind
    cmp ax,-1
    je move_sprite_first_ind_ok
;
    cmp ax,bx
    jc move_sprite_first_ind_ok
;
    mov bx,ax

move_sprite_first_ind_ok:
    shl bx,4

move_sprite_first_hide_loop:
    mov dx,fs
    cmp dx,ds:[bx].spi_sel
    je move_sprite_first_curr
;
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
    jz move_sprite_first_hide_next
;
    mov dx,bp
    HideLine sp_x, sp_y
;
    mov dx,bp
    HideLine sp_new_x, sp_new_y

move_sprite_first_hide_next:
    sub bx,16
    jnc move_sprite_first_hide_loop

move_sprite_first_curr:
    mov bx,fs:sp_index
    shl bx,4
;
    mov dx,bp
    HideLineBuffer sp_y
;
    push ds
    mov dx,bp
    HideWholeLine
    pop ds

move_sprite_line_done:
    ret
MoveSpriteLine  Endp

move_sprite     Proc far
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
    mov fs,ds:[ebx].sp_sel
    mov ds,fs:sp_dest_sel
    EnterSection ds:v_sprite_section
;
    push ds:v_x_min
    push ds:v_y_min
    push ds:v_x_max
    push ds:v_y_max
    push ds:v_lgop
;
    mov ax,fs:sp_x_min
    mov ds:v_x_min,ax
    mov ax,fs:sp_y_min
    mov ds:v_y_min,ax
    mov ax,fs:sp_x_max
    mov ds:v_x_max,ax
    mov ax,fs:sp_y_max
    mov ds:v_y_max,ax
    mov ds:v_lgop,LGOP_NONE
;    
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
    mov gs,fs:sp_dest_sel
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
    jg move_sprite_up

move_sprite_down:
    xor bp,bp

move_sprite_down_loop:
    push si
    push di
    call MoveSpriteLine
    pop di
    pop si
    add si,4
    add di,4
    inc bp
    cmp bp,fs:sp_h
    jnz move_sprite_down_loop
    jmp move_sprite_coord

move_sprite_up:
    mov ax,fs:sp_h
    dec ax
    mov bp,ax
    shl ax,2
    add si,ax
    add di,ax

move_sprite_up_loop:
    push si
    push di
    call MoveSpriteLine
    pop di
    pop si
    sub si,4
    sub di,4
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
    mov ds,fs:sp_dest_sel
;
    pop ds:v_lgop
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    LeaveSection ds:v_sprite_section
    clc

move_sprite_done:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
move_sprite     Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_sprite
;
;           DESCRIPTION:    Delete sprite
;
;           PARAMETERS:         DS:EBX       Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_sprite   Proc near
    push es
    push fs
    push gs
    pushad
;
    mov fs,[ebx].sp_sel
    push ds
    push ebx
;
    mov ds,fs:sp_dest_sel
    EnterSection ds:v_sprite_section
;
    test fs:sp_flags,SP_FLAG_VISIBLE
    jz delete_sprite_hidden
;
    push ds:v_x_min
    push ds:v_y_min
    push ds:v_x_max
    push ds:v_y_max
    push ds:v_lgop
;
    mov ax,fs:sp_x_min
    mov ds:v_x_min,ax
    mov ax,fs:sp_y_min
    mov ds:v_y_min,ax
    mov ax,fs:sp_x_max
    mov ds:v_x_max,ax
    mov ax,fs:sp_y_max
    mov ds:v_y_max,ax
    mov ds:v_lgop,LGOP_NONE
    push ds
    call hide
    pop ds
;
    pop ds:v_lgop
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min

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
    sub cx,1
    jnz delete_sprite_spl_loop
;
    mov ds,fs:sp_dest_sel
    LeaveSection ds:v_sprite_section
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
    pop ebx
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
delete_sprite   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseSprite
;
;           DESCRIPTION:    Close sprite
;
;           PARAMETERS:         BX          Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_sprite_name       DB 'Close Sprite', 0

close_sprite    Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push ax
    push ebx
;
    mov ax,SPRITE_HANDLE
    DerefHandle
    jc cl_sprite_done
;
    call delete_sprite

cl_sprite_done:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    ret
close_sprite    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    BX              Sprite handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ax
    push ebx
;
    mov ax,SPRITE_HANDLE
    DerefHandle
    jc delete_handle_done
;
    call delete_sprite

delete_handle_done:
    pop ebx
    pop ax
    pop ds
    ret
delete_handle   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           hide_sprite_line
;
;           DESCRIPTION:    Hide a sprite line
;
;       PARAMETERS:     AX      size
;               CX      x
;               DX      y
;               ES:EDI  buffer
;               DS      bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_sprite_line_name   DB 'Hide Sprite Line', 0

hide_sprite_line    Proc far
    push si
    mov ds:v_sprite_show_size,0
    mov ds:v_sprite_show_x,cx
    mov ds:v_sprite_show_y,dx
    mov si,dx
    shl si,2
    add si,ds:v_sprite_lines
;
    cmp si,ds:v_sprite_lines
    jb hide_sprite_l_done
;
    cmp si,ds:v_sprite_max_pos
    jae hide_sprite_l_done
;
    cmp ds:[si].spl_upper_ind,-1
    je hide_sprite_l_done
;
    push ds:v_x_min
    push ds:v_y_min
    push ds:v_x_max
    push ds:v_y_max
    push ds:v_lgop
;
    push ds
    push gs
    pushad
    mov ds:v_lgop,LGOP_NONE
;
    mov ds:v_sprite_show_size,ax
    mov bx,ds
    mov gs,bx
    mov ds,ds:v_sprite_sel
    mov bp,ax
    mov bx,gs:[si].spl_upper_ind
    shl bx,4

hide_sprite_l_loop:
    push cx
    push dx
;
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
    jz hide_sprite_l_next
;
    sub dx,ds:[bx].spi_y_min
    jl hide_sprite_l_next
;
    cmp dx,ds:[bx].spi_height
    jge hide_sprite_l_next
;
    sub cx,ds:[bx].spi_x_min
    jge hide_sprite_l_pos
;
    mov ax,bp
    add ax,cx
    jle hide_sprite_l_next
;
    xor cx,cx
    cmp ax,ds:[bx].spi_width
    jl hide_sprite_l_do
;
    mov ax,ds:[bx].spi_width
    jmp hide_sprite_l_do

hide_sprite_l_pos:
    cmp cx,ds:[bx].spi_width
    jge hide_sprite_l_next
;
    mov ax,ds:[bx].spi_width
    sub ax,cx

hide_sprite_l_do:
    cmp ax,bp
    jc hide_sprite_len_ok
;
    mov ax,bp

hide_sprite_len_ok:
    push ds
    push gs
    mov gs,ds:[bx].spi_sel
    mov ds,gs:sp_back_sel
    push bx
    push ax
    call fword ptr ds:v_get_line_proc
    mov bl,al
    pop ax
;
    mov ds,gs:sp_dest_sel
    add cx,gs:sp_x
    add dx,gs:sp_y
    call fword ptr ds:v_set_sprite_row_proc
    pop bx
    pop gs
    pop ds

hide_sprite_l_next:
    pop dx
    pop cx
    sub bx,16
    jae hide_sprite_l_loop
;    
    popad
    pop gs
    pop ds
;
    pop ds:v_lgop
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min

hide_sprite_l_done:
    pop si
    ret
hide_sprite_line    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           show_sprite_line
;
;           DESCRIPTION:    Show a sprite line
;
;       PARAMETERS:     DS      bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_sprite_line_name   DB 'Show Sprite Line', 0

show_sprite_line    Proc far
    cmp ds:v_sprite_show_size,0
    jz show_sprite_l_done
;
    push ds:v_x_min
    push ds:v_y_min
    push ds:v_x_max
    push ds:v_y_max
    push ds:v_lgop
;
    push ds
    push gs
    pushad
;
    mov ds:v_lgop,LGOP_NONE
    mov cx,ds:v_sprite_show_x
    mov dx,ds:v_sprite_show_y
    mov bp,ds:v_sprite_show_size
    mov si,dx
    shl si,2
    add si,ds:v_sprite_lines
;
    mov bx,ds
    mov gs,bx
    mov ds,ds:v_sprite_sel
    mov bx,gs:[si].spl_lower_ind
    shl bx,4
    mov si,gs:[si].spl_upper_ind
    shl si,4

show_sprite_l_loop:
    push cx
    push dx
    push si
;
    test ds:[bx].spi_flags,SP_FLAG_VISIBLE
    jz show_sprite_l_next
;
    sub dx,ds:[bx].spi_y_min
    jl show_sprite_l_next
;
    cmp dx,ds:[bx].spi_height
    jge show_sprite_l_next
;
    sub cx,ds:[bx].spi_x_min
    jge show_sprite_l_pos
;
    mov ax,bp
    add ax,cx
    jle show_sprite_l_next
;
    xor cx,cx
    cmp ax,ds:[bx].spi_width
    jl show_sprite_l_do
;
    mov ax,ds:[bx].spi_width
    jmp show_sprite_l_do

show_sprite_l_pos:
    cmp cx,ds:[bx].spi_width
    jge show_sprite_l_next
;
    mov ax,ds:[bx].spi_width
    sub ax,cx

show_sprite_l_do:
    cmp ax,bp
    jc show_sprite_len_ok
;
    mov ax,bp

show_sprite_len_ok:
    push ds
    push gs
    push bx
    push bp
;    
    mov bp,ax
    mov gs,ds:[bx].spi_sel
    mov ds,gs:sp_dest_sel
    add cx,gs:sp_x
    add dx,gs:sp_y
    push bx
    call fword ptr ds:v_get_line_proc
    mov bl,al
;
    mov ax,bp
    mov ds,gs:sp_back_sel
    sub cx,gs:sp_x
    sub dx,gs:sp_y
    call fword ptr ds:v_set_sprite_row_proc
    pop bx
;
    mov ds,gs:sp_bitmap_sel
    call fword ptr ds:v_get_line_proc
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
    add dx,gs:sp_y
    shl edx,16
    mov al,cl
    and al,7
    add cx,gs:sp_x
    movzx ecx,cx
    or ecx,edx
    mov dx,bp
    call fword ptr ds:v_draw_sprite_line_proc
    pop bp
    pop bx
    pop gs
    pop ds

show_sprite_l_next:
    pop si
    pop dx
    pop cx
    add bx,16
    cmp bx,si
    jbe show_sprite_l_loop
;    
    popad
    pop gs
    pop ds
;
    pop ds:v_lgop
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min

show_sprite_l_done:
    ret
show_sprite_line    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_sprite

init_sprite     PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ax,SPRITE_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov esi,OFFSET create_sprite
    mov edi,OFFSET create_sprite_name
    xor dx,dx
    mov ax,create_sprite_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET show_sprite
    mov edi,OFFSET show_sprite_name
    xor dx,dx
    mov ax,show_sprite_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET hide_sprite
    mov edi,OFFSET hide_sprite_name
    xor dx,dx
    mov ax,hide_sprite_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET move_sprite
    mov edi,OFFSET move_sprite_name
    xor dx,dx
    mov ax,move_sprite_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_sprite
    mov edi,OFFSET close_sprite_name
    xor dx,dx
    mov ax,close_sprite_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET hide_sprite_line
    mov edi,OFFSET hide_sprite_line_name
    xor cl,cl
    mov ax,hide_sprite_line_nr
    RegisterOsGate
;
    mov esi,OFFSET show_sprite_line
    mov edi,OFFSET show_sprite_line_name
    xor cl,cl
    mov ax,show_sprite_line_nr
    RegisterOsGate
;
    ret
init_sprite     ENDP

code    ENDS

    END
