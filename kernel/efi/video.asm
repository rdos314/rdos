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
; VIDEO.ASM
; Standard video interface. Hardware independent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\handle.inc
INCLUDE bitmap.inc
INCLUDE video.inc
INCLUDE ..\apicheck.inc

video_mode_entry    STRUC

mode_link           DW ?
mode_nr             DW ?
mode_create         DD ?,?
mode_x_resol        DW ?
mode_y_resol        DW ?
mode_bpp            DB ?
mode_resv           DB ?

video_mode_entry    ENDS

CallVideo       MACRO   call_proc
    push ds
    push ax
    mov ax,video_local_sel
    mov ds,ax
    pop ax
    mov ds,ds:v_handle
    call fword ptr ds:&call_proc
    pop ds
                ENDM

video_focus_seg STRUC

v_handle        DW ?

video_focus_seg ENDS


data    SEGMENT byte public 'DATA'

v_list          DW ?

data    ENDS

    .386p

code    SEGMENT byte public 'CODE'

    assume cs:code

    extrn init_bitmap:near
    extrn init_sprite:near
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           QueryVideoMode
;
;           DESCRIPTION:    Query video mode
;
;           PARAMETERS:     AX      mode # or 0    
;
;           RETURNS:        AX          bits / pixel
;                           CX          x-resolution
;                           DX          y-resolution
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

query_video_mode_name     DB 'Query Video Mode',0

query_video_mode  PROC far
    ret
query_video_mode    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetVideoMode
;
;           DESCRIPTION:    Get video mode
;
;           PARAMETERS:         AX          bits / pixel
;                           CX          x-resolution
;                           DX          y-resolution
;
;       RETURNS:    AX      mode # or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_video_mode_name     DB 'Get Video Mode',0

get_video_mode  PROC far
    ret
get_video_mode  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetVideoMode
;
;           DESCRIPTION:    Set video mode
;
;           PARAMETERS:         AX          Mode
;
;           RETURNS:        AX          bits / pixel
;                           BX          bitmap handle
;                           CX          x-resolution
;                           DX          y-resolution
;                           SI          line size
;                           ES:EDI  user buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_video_mode_name     DB 'Set Video Mode',0

set_video_mode  PROC far
    ret
set_video_mode  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InvertMouse
;
;           DESCRIPTION:    Invert colors for mouse-pointer
;
;           PARAMETERS:     CX          COL (x)
;                           DX          ROW (y)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

invert_mouse_name       DB 'InvertMouse',0

invert_mouse    PROC far
    ret
invert_mouse    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCursorPosition
;
;           DESCRIPTION:    Set cursor position
;
;           PARAMETERS:         CX          COL (x)
;                           DX          ROW (y)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cursor_pos_name     DB 'Set Cursor Position',0

set_cursor_position     PROC far
    ret
set_cursor_position     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCursorPosition
;
;           DESCRIPTION:    Get cursor position
;
;           RETURNS:        CX          COL (x)
;                           DX          Row (y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cursor_pos_name     DB 'Get Cursor Position',0

get_cursor_position     PROC far
    ret
get_cursor_position     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetForeColor
;
;           DESCRIPTION:    Set text mode fore color
;
;           PARAMETERS:         AL          Color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_forecolor_name      DB 'Set Fore Color',0

set_forecolor   PROC far
    ret
set_forecolor   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetBackColor
;
;           DESCRIPTION:    Set text mode back color
;
;           PARAMETERS:         AL          Color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_backcolor_name      DB 'Set Back Color',0

set_backcolor   PROC far
    ret
set_backcolor   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCharAttrib
;
;           DESCRIPTION:    Get char & attribute
;
;           PARAMETERS:         AL          Character
;                           BL          Back color
;                           BH          Fore color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_char_attrib_name    DB 'Get Character & Attribute',0

get_char_attrib PROC far
    ret
get_char_attrib ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteChar
;
;           DESCRIPTION:    Write one character to screen
;
;           PARAMETERS:         AL          Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_char_name DB 'Write Char',0

write_char      PROC far
    ret
write_char      ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteAsciiz
;
;           DESCRIPTION:    Write NULL terminated string
;
;           PARAMETERS:         ES:(E)DI    Null terminated string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_asciiz_name       DB 'Write Asciiz String',0

write_asciiz16  PROC far
    ret
write_asciiz16  ENDP

write_asciiz32  PROC far
    ret
write_asciiz32  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteDosString
;
;           DESCRIPTION:    Write '$'-terminated string
;
;           PARAMETERS:         ES:EDI  Adress to string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_dos_string_name   DB 'Write Dos String',0

write_dos_string    PROC far
    ret
write_dos_string    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteSizeString
;
;           DESCRIPTION:    Write a number of characters
;
;           PARAMETERS:         ES:(E)DI    String
;                           (E)CX       Number of characters            
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_size_string_name  DB 'Write Size String',0

write_size_string16     PROC far
    ret
write_size_string16     ENDP

write_size_string32     PROC far
    ret
write_size_string32     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteAttributeString
;
;           DESCRIPTION:    Write a number of characters & attributes
;
;           PARAMETERS:     AX          Col
;                           DX          Row
;                           ES:(E)DI    String
;                           (E)CX       Number of characters            
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_attr_string_name  DB 'Write Attribute String',0

write_attr_string16     PROC far
    ret
write_attr_string16     ENDP

write_attr_string32     PROC far
    ret
write_attr_string32     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetClipRect
;
;           DESCRIPTION:    Set clipping rectangle
;
;           PARAMETERS:         BX              Bitmap handle
;               CX      X min
;               DX      Y min
;               SI      X max
;               DI      Y max
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_clip_rect_name      DB 'Set Clip Rect',0

set_clip_rect   PROC far
    push ds
    push es
    push ebx
    push cx
    push dx
    push si
    push di
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_clip_rect_done
;
    mov es,[ebx].bm_sel
;
    test ch,80h
    jz set_clip_xmin_pos
;
    xor cx,cx

set_clip_xmin_pos:
    test dh,80h
    jz set_clip_ymin_pos
;
    xor dx,dx

set_clip_ymin_pos:
    test si,8000h
    jz set_clip_xmax_pos
;
    xor si,si

set_clip_xmax_pos:
    test di,8000h
    jz set_clip_ymax_pos
;
    xor di,di

set_clip_ymax_pos:
    cmp cx,si
    jc set_clip_x_ok
;
    xchg cx,si

set_clip_x_ok:
    cmp dx,di
    jc set_clip_y_ok
;
    xchg dx,di

set_clip_y_ok:
    cmp cx,es:v_width
    jc set_clip_xmin_noov
;
    mov cx,es:v_width
    dec cx

set_clip_xmin_noov:
    cmp dx,es:v_height
    jc set_clip_ymin_noov
;
    mov dx,es:v_height
    dec dx

set_clip_ymin_noov:
    cmp si,es:v_width
    jc set_clip_xmax_noov
;
    mov si,es:v_width
    dec si

set_clip_xmax_noov:
    cmp di,es:v_height
    jc set_clip_ymax_noov
;
    mov di,es:v_height
    dec di

set_clip_ymax_noov:
    mov [ebx].bm_x_min,cx
    mov [ebx].bm_y_min,dx
    mov [ebx].bm_x_max,si
    mov [ebx].bm_y_max,di
    
set_clip_rect_done:
    pop di
    pop si
    pop dx
    pop cx
    pop ebx
    pop es
    pop ds
    ret
set_clip_rect   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearClipRect
;
;           DESCRIPTION:    Clear clipping rectangle
;
;           PARAMETERS:         BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_clip_rect_name    DB 'Clear Clip Rect',0

clear_clip_rect PROC far
    push ds
    push es
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc clear_clip_rect_done
;
    mov es,[ebx].bm_sel
    mov [ebx].bm_x_min,0
    mov [ebx].bm_y_min,0
    mov ax,es:v_width
    dec ax
    mov [ebx].bm_x_max,ax
    mov ax,es:v_height
    dec ax
    mov [ebx].bm_y_max,ax
    clc
    
clear_clip_rect_done:
    pop ebx
    pop ax
    pop es
    pop ds
    ret
clear_clip_rect ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetDrawColor
;
;           DESCRIPTION:    Set draw color
;
;           PARAMETERS:         EAX             RGB color
;                           BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_draw_color_name     DB 'Set Draw Color',0

set_draw_color  PROC far
    push ds
    push eax
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_draw_color_done
;
    push ds
    mov ds,[ebx].bm_sel
    call fword ptr ds:v_translate_color_proc
    pop ds
    mov [ebx].bm_color,eax
    
set_draw_color_done:
    pop ebx
    pop eax
    pop ds
    ret
set_draw_color  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetLgop
;
;           DESCRIPTION:    Set LGOP
;
;           PARAMETERS:         AX              LGOP
;                           BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_lgop_name   DB 'Set LGOP',0

set_lgop    PROC far
    cmp ax,13
    jbe set_lgop_ok
    mov ax,1

set_lgop_ok:
    push ds
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_lgop_done
;
    mov [ebx].bm_lgop,ax
    
set_lgop_done:
    pop ebx
    pop ds
    ret
set_lgop    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetHollowStyle
;
;           DESCRIPTION:    Set hollow style
;
;           PARAMETERS:         BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_hollow_style_name   DB 'Set Hollow Style',0

set_hollow_style    PROC far
    push ds
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_hollow_done
;
    mov [ebx].bm_style,STYLE_HOLLOW
    
set_hollow_done:
    pop ebx
    pop ds
    ret
set_hollow_style    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetFilledStyle
;
;           DESCRIPTION:    Set filled style
;
;           PARAMETERS:         BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_filled_style_name   DB 'Set Filled Style',0

set_filled_style    PROC far
    push ds
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_filled_done
;
    mov [ebx].bm_style,STYLE_FILLED
    
set_filled_done:
    pop ebx
    pop ds
    ret
set_filled_style    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetFont
;
;           DESCRIPTION:    Set font
;
;           PARAMETERS:         BX              Bitmap handle
;                           AX              Font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_font_name   DB 'Set Font',0

set_font    PROC far
    push ds
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_font_done
;
    mov [ebx].bm_font,ax
    
set_font_done:
    pop ebx
    pop ds
    ret
set_font    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetPixel
;
;           DESCRIPTION:    Get pixel
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;
;           RETURNS:        EAX         RGB color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pixel_name  DB 'Get Pixel',0

get_pixel       PROC far
    push ds
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc get_pixel_fail
;
    mov ds,[ebx].bm_sel
    pop bx
    pop ax
    EnterSection ds:v_section
    call fword ptr ds:v_get_pixel_proc
    LeaveSection ds:v_section
    pop ds  
    ret

get_pixel_fail:
    pop ebx
    pop ax
    pop ds
    ret
get_pixel       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetPixel
;
;           DESCRIPTION:    Set pixel
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_pixel_name  DB 'Set Pixel',0

set_pixel       PROC far
    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc set_pixel_fail
;
    mov eax,[bx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax
    call fword ptr ds:v_set_pixel_proc
    LeaveSection ds:v_section
    pop ds
    ret  

set_pixel_fail:
    pop ebx
    pop eax
    pop ds
    ret
set_pixel       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Blit
;
;           DESCRIPTION:    Blit
;
;           PARAMETERS:     AX          Source bitmap handle
;                           BX          Dest bitmap handle
;                           CX          Width
;                           DX          Height
;                           ESI         Source x + y << 16
;                           EDI         Dest x + y << 16
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

blit_name       DB 'Blit',0

blit_src_y          EQU -4
blit_src_x          EQU -6
blit_dest_y         EQU -8
blit_dest_x         EQU -10
blit_width          EQU -12
blit_height         EQU -14
blit_src_sel        EQU -16
blit_dest_sel       EQU -18

blit_pr PROC far
    push ebp
    mov ebp,esp
    sub esp,20
    push ds
    push es
    pushad
;
    mov [ebp].blit_src_x,esi
    mov [ebp].blit_dest_x,edi
;
    or cx,cx
    jz blit_done
;
    or dx,dx
    jz blit_done
;
    mov [ebp].blit_width,cx
    mov [ebp].blit_height,dx
;
    mov cx,bx
    push ax
    mov bx,ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc blit_failed
;
    mov dx,[ebx].bm_sel
    mov [ebp].blit_src_sel,dx
;
    push ax
    mov bx,cx
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc blit_failed
;
    mov dx,[ebx].bm_sel
    mov [ebp].blit_dest_sel,dx
;
    push [ebx].bm_lgop
    push [ebx].bm_color
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
;
    mov ax,[ebp].blit_src_sel
    cmp ax,[ebp].blit_dest_sel
    je blit_same_bitmap
;
    jae blit_take_dest_first

blit_take_src_first:
    mov ds,[ebp].blit_src_sel
    EnterSection ds:v_section
;
    mov ds,[ebp].blit_dest_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_color
    pop ds:v_lgop
    jmp blit_entered

blit_take_dest_first:
    mov ds,[ebp].blit_dest_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_color
    pop ds:v_lgop
;
    mov ds,[ebp].blit_src_sel
    EnterSection ds:v_section
    
blit_entered:
    mov ds,[ebp].blit_src_sel
    mov al,ds:v_alpha
    cmp al,1
    je blit_alpha
;    
    mov al,ds:v_bpp
    cmp al,1
    je blit_check1
;
    mov ds,[ebp].blit_dest_sel
    cmp al,ds:v_bpp
    je blit_same_bpp
    jmp blit_diff_bpp

blit_check1:
    mov ds,[ebp].blit_dest_sel
    cmp al,ds:v_bpp
    jne blit1

blit_diff_bpp:
    movzx eax,word ptr [ebp].blit_width
    shl eax,2
    AllocateGlobalMem

blit_diff_loop:
    mov ds,[ebp].blit_src_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    cmp dx,0
    jl blit_diff_next
;
    cmp dx,ds:v_height
    jge blit_diff_next
;
    mov di,cx
    add di,ax
    cmp di,ds:v_width
    jle blit_diff_get
;
    mov ax,ds:v_width
    sub ax,cx

blit_diff_get:
    xor edi,edi
    call fword ptr ds:v_get_rgb_row_proc
;
    mov ds,[ebp].blit_dest_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    xor edi,edi
    call fword ptr ds:v_set_rgb_row_proc

blit_diff_next:
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_diff_loop
;
    FreeMem 
    mov ds,[ebp].blit_dest_sel
    LeaveSection ds:v_section
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_same_bpp:
    mov ds,[ebp].blit_src_sel
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    call fword ptr ds:v_get_line_proc
;
    mov ds,[ebp].blit_dest_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    call fword ptr ds:v_set_native_row_proc
;
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_same_bpp
;
    mov ds,[ebp].blit_dest_sel
    LeaveSection ds:v_section
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_same_bitmap:
    mov ds,[ebp].blit_src_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_color
    pop ds:v_lgop
;
    mov dx,[ebp].blit_src_y
    cmp dx,[ebp].blit_dest_y
    je blit_same_line
    ja blit_forward

blit_reverse:
    mov ax,[ebp].blit_height
    dec ax
    add [ebp].blit_src_y,ax
    add [ebp].blit_dest_y,ax

blit_reverse_loop:
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    call fword ptr ds:v_get_line_proc
;
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    call fword ptr ds:v_set_native_row_proc
;
    dec word ptr [ebp].blit_src_y
    dec word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_reverse_loop
;
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_forward:
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    call fword ptr ds:v_get_line_proc
;
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    call fword ptr ds:v_set_native_row_proc
;
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_forward
;
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_same_line:
    movzx eax,word ptr [ebp].blit_width
    shl eax,2
    AllocateGlobalMem

blit_same_line_loop:
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    xor edi,edi
    call fword ptr ds:v_get_native_row_proc
;
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    xor edi,edi
    call fword ptr ds:v_set_native_row_proc
;
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_same_line_loop
;
    FreeMem
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_alpha:
    movzx eax,word ptr [ebp].blit_width
    shl eax,2
    AllocateGlobalMem

blit_alpha_loop:
    mov ds,[ebp].blit_src_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    cmp dx,0
    jl blit_alpha_next
;
    cmp dx,ds:v_height
    jge blit_alpha_next
;
    mov di,cx
    add di,ax
    cmp di,ds:v_width
    jle blit_alpha_get
;
    mov ax,ds:v_width
    sub ax,cx

blit_alpha_get:
    xor edi,edi
    call fword ptr ds:v_get_rgba_row_proc
;
    mov ds,[ebp].blit_dest_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    xor edi,edi
    call fword ptr ds:v_set_rgba_row_proc

blit_alpha_next:
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_alpha_loop
;
    FreeMem 
    mov ds,[ebp].blit_dest_sel
    LeaveSection ds:v_section
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done



blit1:
    mov ds,[ebp].blit_src_sel
    mov ax,flat_sel
    mov es,ax
    mov edi,ds:v_app_base
    mov ax,ds:v_row_size
    mov ecx,[ebp].blit_src_x
    mov edx,[ebp].blit_dest_x
    mov si,[ebp].blit_width
    mov ds,[ebp].blit_dest_sel
    mov ebx,ds:v_color

blit1_line_loop:
    call fword ptr ds:v_draw_mask_line_proc
    add ecx,10000h
    add edx,10000h
    sub word ptr [ebp].blit_height,1
    jnz blit1_line_loop
;
    mov ds,[ebp].blit_dest_sel
    LeaveSection ds:v_section
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_failed:
    stc

blit_done:
    popad
    pop es
    pop ds
    add esp,20
    pop ebp
    ret
blit_pr ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawMask
;
;           DESCRIPTION:    Draw a mask line
;
;           PARAMETERS:         AX          row size
;                           BX          Bitmap handle
;                           ECX         source x + y << 16
;                           EDX         dest x + y << 16
;                           ESI         width + height << 16
;                           ES:EDI  1-bit mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_mask_name  DB 'Draw Mask',0

draw_mask       PROC far
    push ecx
    push edx
    push esi
    push edi
;
    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_mask_fail
;
    mov eax,[ebx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax

    movzx eax,ax

draw_mask_loop:
    ror esi,16
    or si,si
    jz draw_mask_leave
;
    ror esi,16
    call fword ptr ds:v_draw_mask_line_proc
    add ecx,10000h
    add edx,10000h
    sub esi,10000h
    jmp draw_mask_loop

draw_mask_leave:
    LeaveSection ds:v_section
    pop ds  
    jmp draw_mask_done

draw_mask_fail:
    pop ebx
    pop eax
    pop ds

draw_mask_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    ret
draw_mask       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawString
;
;           DESCRIPTION:    Draw a string
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;                           ES:EDI  string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_string_name    DB 'Draw String',0

draw_string16   PROC far
    push edi
    movzx edi,di
;
    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_string16_fail
;
    mov eax,[ebx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_font
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_font
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax
    call fword ptr ds:v_draw_string_proc
    LeaveSection ds:v_section
    pop ds  
    jmp draw_string16_done

draw_string16_fail:
    pop ebx
    pop eax
    pop ds

draw_string16_done:
    pop edi
    ret
draw_string16   ENDP

draw_string32   PROC far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_string32_fail
;
    mov eax,[bx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_font
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_font
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax
    call fword ptr ds:v_draw_string_proc
    LeaveSection ds:v_section
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret

draw_string32_fail:
    pop ebx
    pop eax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret
draw_string32   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawLine
;
;           DESCRIPTION:    Draw a line
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x1
;                           DX          y1
;                           SI          x2
;                           DI          y2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_line_name  DB 'Draw Line',0

draw_line       PROC far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_line_fail
;
    mov eax,[bx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax
    call fword ptr ds:v_draw_line_proc
    LeaveSection ds:v_section
    pop ds  

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret

draw_line_fail:
    pop ebx
    pop eax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret
draw_line       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawRect
;
;           DESCRIPTION:    Draw a rectangle
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;                           SI          w
;                           DI          b
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_rect_name  DB 'Draw Rect',0

draw_rect       PROC far
    push ds
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_rect_fail
;
    push [ebx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov al,[ebx].bm_style
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    mov ds:v_style,al
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    pop ds:v_color
    pop ebx
    pop ax
    call fword ptr ds:v_draw_rect_proc
    LeaveSection ds:v_section
    pop ds  
    ret

draw_rect_fail:
    pop ebx
    pop ax
    pop ds
    ret
draw_rect       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawEllipse
;
;           DESCRIPTION:    Draw a ellipse
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;                           SI          w
;                           DI          b
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_ellipse_name       DB 'Draw Ellipse',0

draw_ellipse    PROC far
    push ds
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_ellipse_fail
;
    push [ebx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov al,[ebx].bm_style
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    mov ds:v_style,al
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    pop ds:v_color
    pop ebx
    pop ax
    call fword ptr ds:v_draw_ellipse_proc
    LeaveSection ds:v_section
    pop ds  
    ret

draw_ellipse_fail:
    pop ebx
    pop ax
    pop ds
    ret
draw_ellipse    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ExtractValidBitmapMask
;
;           DESCRIPTION:    Extract valid mask from bitmap
;
;           PARAMETERS:     BX          Bitmap handle
;
;           RETURNS:        AX          Mask bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extract_valid_bitmap_mask_name  DB 'Extract Valid Bitmap Mask',0

emask_width          EQU -4
emask_height         EQU -6
emask_src_sel        EQU -8
emask_dest_sel       EQU -10
emask_bitmap         EQU -12

extract_valid_bitmap_mask       PROC far
    push ebp
    mov ebp,esp
    sub esp,12
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_vmask_fail
;
    mov ds,[ebx].bm_sel
    call fword ptr ds:v_has_alpha_proc
    jc extract_vmask_fail
;
    mov [ebp].emask_src_sel,ds
;
    mov al,1
    mov cx,ds:v_width
    mov dx,ds:v_height
    CreateBitmap
    jc extract_vmask_fail
;
    mov [ebp].emask_bitmap,bx
    mov [ebp].emask_width,cx
    mov [ebp].emask_height,dx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_vmask_fail
;
    mov ax,[ebx].bm_sel
    mov [ebp].emask_dest_sel,ax
;    
    xor dx,dx

extract_vy_loop:
    xor cx,cx

extract_vx_loop:
    mov ds,[ebp].emask_src_sel
    call fword ptr ds:v_get_alpha_proc
    mov ds,[ebp].emask_dest_sel
    cmp al,80h
    ja extract_vset
;
    mov ds:v_color,0
    jmp extract_vdo

extract_vset:
    mov ds:v_color,1

extract_vdo:    
    call fword ptr ds:v_set_pixel_proc    
;
    inc cx
    cmp cx,[ebp].emask_width
    jb extract_vx_loop
;
    inc dx
    cmp dx,[ebp].emask_height
    jb extract_vy_loop    
;        
    mov ax,[ebp].emask_bitmap
    clc

extract_vmask_fail:
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    add esp,12
    pop ebp
    ret
extract_valid_bitmap_mask       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ExtractInvalidBitmapMask
;
;           DESCRIPTION:    Extract invalid mask from bitmap
;
;           PARAMETERS:     BX          Bitmap handle
;
;           RETURNS:        AX          Mask bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extract_invalid_bitmap_mask_name  DB 'Extract Invalid Bitmap Mask',0

extract_invalid_bitmap_mask       PROC far
    push ebp
    mov ebp,esp
    sub esp,12
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_ivmask_fail
;
    mov ds,[ebx].bm_sel
    call fword ptr ds:v_has_alpha_proc
    jc extract_ivmask_fail
;
    mov [ebp].emask_src_sel,ds
;
    mov al,1
    mov cx,ds:v_width
    mov dx,ds:v_height
    CreateBitmap
    jc extract_ivmask_fail
;
    mov [ebp].emask_bitmap,bx
    mov [ebp].emask_width,cx
    mov [ebp].emask_height,dx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_ivmask_fail
;
    mov ax,[ebx].bm_sel
    mov [ebp].emask_dest_sel,ax
;    
    xor dx,dx

extract_ivy_loop:
    xor cx,cx

extract_ivx_loop:
    mov ds,[ebp].emask_src_sel
    call fword ptr ds:v_get_alpha_proc
    mov ds,[ebp].emask_dest_sel
    cmp al,80h
    ja extract_ivreset
;
    mov ds:v_color,1
    jmp extract_ivdo

extract_ivreset:
    mov ds:v_color,0

extract_ivdo:    
    call fword ptr ds:v_set_pixel_proc    
;
    inc cx
    cmp cx,[ebp].emask_width
    jb extract_ivx_loop
;
    inc dx
    cmp dx,[ebp].emask_height
    jb extract_ivy_loop    
;        
    mov ax,[ebp].emask_bitmap
    clc

extract_ivmask_fail:
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    add esp,12
    pop ebp
    ret
extract_invalid_bitmap_mask       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ExtractAlphaBitmap
;
;           DESCRIPTION:    Extract alpha channel from bitmap
;
;           PARAMETERS:     BX          Bitmap handle
;
;           RETURNS:        AX          Alpha bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extract_alpha_bitmap_name  DB 'Extract Alpha Bitmap',0

extract_alpha_bitmap       PROC far
    push ds
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_alpha_fail
;
    mov al,[ebx].bm_style
    mov ds,[ebx].bm_sel
    mov ds:v_style,al
    call fword ptr ds:v_has_alpha_proc
    jc extract_alpha_fail
;
    stc

extract_alpha_fail:
    pop ebx
    pop ds
    ret
extract_alpha_bitmap       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           lost_focus_hook
;
;           DESCRIPTION:    Lost focus hook
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
lost_focus_hook PROC far
    push ds
    push ax
    mov ax,video_focus_sel
    mov ds,ax
    mov ax,ds:v_handle
    or ax,ax
    pop ax
    jz lost_focus_hook_switched
;
    mov ds,ds:v_handle
    call fword ptr ds:v_switch_from_proc

lost_focus_hook_switched:
    pop ds
    ret
lost_focus_hook Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           got_focus_hook
;
;           DESCRIPTION:    Got focus hook
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
got_focus_hook  PROC far
    push ds
    push ax
    mov ax,video_focus_sel
    mov ds,ax
    mov ax,ds:v_handle
    or ax,ax
    pop ax
    jz got_focus_hook_switched
;
    mov ds,ds:v_handle
    call fword ptr ds:v_switch_to_proc

got_focus_hook_switched:
    pop ds
    ret
got_focus_hook  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_THREAD
;
;           DESCRIPTION:    init thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
init_thread     PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds:p_forecolor,7
    mov ds:p_backcolor,0
    mov ds:p_row,0
    mov ds:p_col,0
;
    pop ax
    pop ds
    ret
init_thread     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Free_process
;
;           DESCRIPTION:    free process
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_process    Proc far
    push ds
    push bx
;
    mov bx,video_local_sel
    mov ds,bx
    mov bx,ds:v_handle
    or bx,bx
    jz free_process_done
;
    mov ds,bx
    call fword ptr ds:v_destruct_proc

free_process_done:
    pop bx
    pop ds
    ret
free_process    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_focus
;
;           DESCRIPTION:    Init focus
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
init_focus      PROC far
    mov ax,video_local_sel
    mov ds,ax
    mov ds:v_handle,0
    ret
init_focus      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init driver
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_video
            
init_video      PROC near
    mov bx,SEG data
    mov es,bx
    mov es:v_list,0
;
    mov eax,SIZE video_focus_seg
    mov bx,video_local_sel
    mov dx,video_focus_sel
    AllocateFixedFocusMem
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_thread
    HookCreateThread
;
    mov edi,OFFSET init_thread
    HookTerminateProcess
;
    mov edi,OFFSET init_focus
    HookEnableFocus
;
    mov edi,OFFSET lost_focus_hook
    HookLostFocus
;
    mov edi,OFFSET got_focus_hook
    HookGotFocus
;
    mov esi,OFFSET invert_mouse
    mov edi,OFFSET invert_mouse_name
    xor cl,cl
    mov ax,invert_mouse_nr
    RegisterOsGate
;
    mov esi,OFFSET query_video_mode
    mov edi,OFFSET query_video_mode_name
    xor dx,dx
    mov ax,query_video_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_video_mode
    mov edi,OFFSET get_video_mode_name
    xor dx,dx
    mov ax,get_video_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_video_mode
    mov edi,OFFSET set_video_mode_name
    xor dx,dx
    mov ax,set_video_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_cursor_position
    mov edi,OFFSET set_cursor_pos_name
    xor dx,dx
    mov ax,set_cursor_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_cursor_position
    mov edi,OFFSET get_cursor_pos_name
    xor dx,dx
    mov ax,get_cursor_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_forecolor
    mov edi,OFFSET set_forecolor_name
    xor dx,dx
    mov ax,set_forecolor_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_backcolor
    mov edi,OFFSET set_backcolor_name
    xor dx,dx
    mov ax,set_backcolor_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_char_attrib
    mov edi,OFFSET get_char_attrib_name
    xor dx,dx
    mov ax,get_char_attrib_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_char
    mov edi,OFFSET write_char_name
    xor dx,dx
    mov ax,write_char_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET write_asciiz16
    mov esi,OFFSET write_asciiz32
    mov edi,OFFSET write_asciiz_name
    mov dx,virt_es_in
    mov ax,write_asciiz_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_size_string16
    mov esi,OFFSET write_size_string32
    mov edi,OFFSET write_size_string_name
    mov dx,virt_es_in
    mov ax,write_size_string_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_attr_string16
    mov esi,OFFSET write_attr_string32
    mov edi,OFFSET write_attr_string_name
    mov dx,virt_es_in
    mov ax,write_attrib_string_nr
    RegisterUserGate
;
    mov esi,OFFSET set_clip_rect
    mov edi,OFFSET set_clip_rect_name
    xor dx,dx
    mov ax,set_clip_rect_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET clear_clip_rect
    mov edi,OFFSET clear_clip_rect_name
    xor dx,dx
    mov ax,clear_clip_rect_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_draw_color
    mov edi,OFFSET set_draw_color_name
    xor dx,dx
    mov ax,set_drawcolor_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_lgop
    mov edi,OFFSET set_lgop_name
    xor dx,dx
    mov ax,set_lgop_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_hollow_style
    mov edi,OFFSET set_hollow_style_name
    xor dx,dx
    mov ax,set_hollow_style_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_filled_style
    mov edi,OFFSET set_filled_style_name
    xor dx,dx
    mov ax,set_filled_style_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_font
    mov edi,OFFSET set_font_name
    xor dx,dx
    mov ax,set_font_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pixel
    mov edi,OFFSET get_pixel_name
    xor dx,dx
    mov ax,get_pixel_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_pixel
    mov edi,OFFSET set_pixel_name
    xor dx,dx
    mov ax,set_pixel_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET blit_pr
    mov edi,OFFSET blit_name
    xor dx,dx
    mov ax,blit_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET draw_mask
    mov edi,OFFSET draw_mask_name
    xor dx,dx
    mov ax,draw_mask_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET draw_string16
    mov esi,OFFSET draw_string32
    mov edi,OFFSET draw_string_name
    mov dx,virt_es_in
    mov ax,draw_string_nr
    RegisterUserGate
;
    mov esi,OFFSET draw_line
    mov edi,OFFSET draw_line_name
    xor dx,dx
    mov ax,draw_line_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET draw_rect
    mov edi,OFFSET draw_rect_name
    xor dx,dx
    mov ax,draw_rect_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET draw_ellipse
    mov edi,OFFSET draw_ellipse_name
    xor dx,dx
    mov ax,draw_ellipse_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET extract_valid_bitmap_mask
    mov edi,OFFSET extract_valid_bitmap_mask_name
    xor dx,dx
    mov ax,extract_valid_bitmap_mask_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET extract_invalid_bitmap_mask
    mov edi,OFFSET extract_invalid_bitmap_mask_name
    xor dx,dx
    mov ax,extract_invalid_bitmap_mask_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET extract_alpha_bitmap
    mov edi,OFFSET extract_alpha_bitmap_name
    xor dx,dx
    mov ax,extract_alpha_bitmap_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_dos_string
    mov edi,OFFSET write_dos_string_name
    xor cl,cl
    mov ax,write_dos_string_nr
    RegisterOsGate
;
    call init_bitmap
    call init_sprite
    ret
init_video      ENDP

code    ENDS

    END
