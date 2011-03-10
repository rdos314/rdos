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

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE protseg.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE ..\handle.inc
INCLUDE bitmap.inc
INCLUDE ..\video.inc

code    SEGMENT byte public use16 'CODE'

        .386

        assume cs:code

        extrn BitmapTab1:near
        extrn BitmapTab16:near
        extrn BitmapTab24:near
        extrn BitmapTab32:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   InitVideoBitmap
;
;               DESCRIPTION:    Init video bitmap
;
;               PARAMETERS:             AL              Bits per pixel
;                                               CX              Width
;                                               DX              Height
;                                               ES              Video / bitmap selector
;
;               RETURNS:                BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_video_bitmap_name  DB 'Init Video Bitmap', 0

init_video_bitmap       Proc far
        push ds
        push cx
        push si
        push di
;
    push si
    mov si,es
    mov ds,si
    InitSection ds:v_section
    InitSection ds:v_sprite_section
    pop si
;    
        mov es:v_usage_count,1
        mov es:v_color,0
        mov es:v_lgop,1
        mov es:v_font,0
        mov es:v_style,0
        mov es:v_bpp,al
        cmp al,1
        jne init_video_no_pad
;
    dec cx
    and cx,0FFF8h
    add cx,8

init_video_no_pad:
        mov es:v_width,cx
        mov es:v_height,dx
        mov es:v_sprite_count,0
        mov es:v_sprite_size,0
        mov es:v_sprite_sel,0
        mov es:v_x_min,0
        mov es:v_y_min,0
        mov si,cx
        dec si
        mov es:v_x_max,si
        mov si,dx
        dec si
        mov es:v_y_max,si
;
        push ax
        push cx
        push dx
;
        mov ax,1
        OpenFont
        jnc init_video_font_found
;
        mov es:v_text_font,0
        mov es:v_pixels_per_row,0
        mov es:v_pixels_per_col,0
        jmp init_video_font_done

init_video_font_found:
        mov es:v_text_font,bx
        mov al,'M'
        push es
        push edi
        GetCharMask
        pop edi
        pop es
        mov es:v_pixels_per_row,dx
        mov es:v_pixels_per_col,cx
;
        mov ax,es:v_width
        xor dx,dx
        div es:v_pixels_per_col
        mov es:v_col_count,ax
;
        mov ax,es:v_height
        xor dx,dx
        div es:v_pixels_per_row
        mov es:v_row_count,ax
;
        movzx eax,es:v_row_count
        movzx edx,es:v_col_count
        mul edx
        add eax,eax
;
        push es
        AllocateSmallGlobalMem
        xor edi,edi
        mov ecx,eax
        shr ecx,1
        mov ax,720h
        rep stos word ptr es:[edi]
        mov ax,es
        pop es
        mov es:v_text,ax

init_video_font_done:
        pop dx
        pop cx
        pop ax
;
        mov si,cs
        mov ds,si
;
    cmp al,1
    je init_video1
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

init_video1:
        mov es:v_color,1
    mov si,OFFSET BitmapTab1
    jmp init_video_copy
    
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
        mov cx,35
        xor di,di
        rep movsd
;
    mov di,es:v_sprite_lines
        mov cx,dx
        mov eax,-1
        rep stosd
        mov es:v_sprite_max_pos,di

init_video_done:
        mov cx,SIZE bitmap_struc
        AllocateHandle
        mov ds:[bx].bm_sel,es
        mov ds:[bx].bm_flag,BM_FLAG_VIDEO
        mov ds:[bx].hh_sign,BITMAP_HANDLE
        mov eax,es:v_color
        mov ds:[bx].bm_color,eax
        mov ds:[bx].bm_lgop,1
        mov ds:[bx].bm_font,0
        mov ds:[bx].bm_style,0
        mov ds:[bx].bm_x_min,0
        mov ds:[bx].bm_y_min,0
        mov ax,es:v_width
        dec ax
        mov ds:[bx].bm_x_max,ax
        mov ax,es:v_height
        dec ax
        mov ds:[bx].bm_y_max,ax
        mov bx,[bx].hh_handle
        mov es:v_bitmap,bx
;
        pop di
        pop si
        pop cx
        pop ds
        ret
init_video_bitmap       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CreateBitmap
;
;               DESCRIPTION:    Create bitmap
;
;               PARAMETERS:             AL              Bits per pixel
;                                               CX              Width
;                                               DX              Height
;
;               RETURNS:                BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_bitmap_name      DB 'Create Bitmap', 0

create_bitmap   Proc far
        push ds
        push es
        push eax
        push ecx
        push edx
        push esi
        push edi
;
        push eax
        mov ax,dx
    shl ax,2    
        add ax,SIZE video_api_struc
        movzx eax,ax
        AllocateSmallKernelMem
        pop eax
;
    push si
    mov si,es
    mov ds,si
    InitSection ds:v_section
    InitSection ds:v_sprite_section
    pop si
;        
        mov es:v_usage_count,1
        mov es:v_color,0
        mov es:v_lgop,1
        mov es:v_font,0
        mov es:v_text_font,0
        mov es:v_style,0
        mov es:v_bpp,al
        cmp al,1
        jne create_bitmap_no_pad
;
    dec cx
    and cx,0FFF8h
    add cx,8

create_bitmap_no_pad:
        mov es:v_width,cx
        mov es:v_height,dx
    mov es:v_sprite_count,0
        mov es:v_sprite_size,0
        mov es:v_sprite_sel,0
        mov es:v_x_min,0
        mov es:v_y_min,0
        mov es:v_text,0
        mov si,cx
        dec si
        mov es:v_x_max,si
        mov si,dx
        dec si
        mov es:v_y_max,si
;
        mov si,cs
        mov ds,si
;
        cmp al,1
        je cr_bitmap1
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

cr_bitmap1:
        mov es:v_color,1
        mov si,OFFSET BitmapTab1
        mov ax,es:v_width
        dec ax
        shr ax,3
        inc ax
        mov es:v_row_size,ax
        jmp cr_bitmap_copy

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
        mov cx,35
        xor di,di
        rep movsd
;
    mov di,SIZE video_api_struc
    mov es:v_sprite_lines,di
        mov cx,es:v_height
        mov eax,-1
        rep stosd
        mov es:v_sprite_max_pos,di
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
        mov ds:[bx].hh_sign,BITMAP_HANDLE
        mov eax,es:v_color
        mov ds:[bx].bm_color,eax
        mov ds:[bx].bm_lgop,1
        mov ds:[bx].bm_font,0
        mov ds:[bx].bm_style,0
        mov ds:[bx].bm_x_min,0
        mov ds:[bx].bm_y_min,0
        mov ax,es:v_width
        dec ax
        mov ds:[bx].bm_x_max,ax
        mov ax,es:v_height
        dec ax
        mov ds:[bx].bm_y_max,ax
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
create_bitmap   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   DuplicateBitmapHandle
;
;               DESCRIPTION:    Duplicate bitmap handle
;
;               PARAMETERS:             BX      Bitmap handle
;
;               RETURNS:                BX              Duplicated bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dup_bitmap_handle_name  DB 'Duplicate Bitmap Handle', 0

dup_bitmap_handle       Proc far
        push ds
        push es
        push ax
        push cx
;
        mov ax,BITMAP_HANDLE
        DerefHandle
        jc dph_done
;
        mov es,[bx].bm_sel
        mov ax,[bx].bm_flag
        mov cx,SIZE bitmap_struc
        AllocateHandle
        mov ds:[bx].bm_sel,es
        mov ds:[bx].bm_flag,ax
        mov ds:[bx].hh_sign,BITMAP_HANDLE
        mov ds:[bx].bm_color,0
        mov ds:[bx].bm_lgop,1
        mov ds:[bx].bm_font,0
        mov ds:[bx].bm_style,0
        mov ds:[bx].bm_x_min,0
        mov ds:[bx].bm_y_min,0
        mov ax,es:v_width
        dec ax
        mov ds:[bx].bm_x_max,ax
        mov ax,es:v_height
        dec ax
        mov ds:[bx].bm_y_max,ax
        mov bx,[bx].hh_handle
        inc es:v_usage_count
        clc

dph_done:
    pop cx
    pop ax
        pop es
        pop ds
        retf32
dup_bitmap_handle       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetStringBitmap
;
;               DESCRIPTION:    Create string bitmap
;
;               PARAMETERS:             ES:(E)DI        String
;                                               BX                      Font handle
;
;               RETURNS:                BX                      Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_string_bitmap_name       DB 'Create String Bitmap', 0

csb_font_handle         EQU -2
csb_bitmap_handle       EQU -4
csb_width                       EQU -6
csb_height                      EQU -8
csb_y                           EQU -10
csb_x                           EQU -12

create_string_bitmap    Proc near
        push bp
        mov bp,sp
        sub sp,12
;
        push ds
        push es
        push fs
        push eax
        push cx
        push dx
        push esi
        push edi
;
        mov ax,es
        mov fs,ax
        mov [bp].csb_font_handle,bx
        UserGateForce32 get_string_metrics_nr
        mov [bp].csb_width,cx
        mov [bp].csb_height,dx
;
        mov ax,1
        CreateBitmap
        mov [bp].csb_bitmap_handle,bx
;
        mov ax,LGOP_OR
        SetLgop
        mov word ptr [bp].csb_x,0
        mov word ptr [bp].csb_y,0

crs_bitmap_loop:
        mov al,fs:[edi]
        or al,al
        jz crs_bitmap_ok
;
        inc edi
        push edi
;
        mov bx,[bp].csb_font_handle
        GetCharMask
        jc crs_bitmap_next
;
        mov ax,si
        mov bx,[bp].csb_bitmap_handle
        push dx
        push cx
        pop esi
        xor ecx,ecx
        mov edx,[bp].csb_x
        DrawMask
        add [bp].csb_x,si

crs_bitmap_next:
        pop edi
        jmp crs_bitmap_loop

crs_bitmap_ok:
        mov bx,[bp].csb_bitmap_handle
        clc

crs_bitmap_done:
        pop edi
        pop esi
        pop dx
        pop cx
        pop eax
        pop fs
        pop es
        pop ds
        add sp,12
        pop bp
        ret
create_string_bitmap    Endp

create_string_bitmap32  Proc far
        call create_string_bitmap
        retf32
create_string_bitmap32  Endp

create_string_bitmap16  Proc far
        push edi
        movzx edi,di
        call create_string_bitmap
        pop edi
        ret
create_string_bitmap16  Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetBitmapInfo
;
;               DESCRIPTION:    Get bitmap info
;
;               PARAMETERS:             BX              Bitmap handle
;
;               RETURNS:                AL              Bits / pixel
;                                               CX              Width
;                                               DX              Height
;                                               SI              Line size in bytes
;                                               ES:EDI  Buffer data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_bitmap_info_name    DB 'Get Bitmap Info', 0

get_bitmap_info Proc near
        push ds
        push bx
;
        mov ax,BITMAP_HANDLE
        DerefHandle
        jc gbi_done
;
        mov ds,[bx].bm_sel
        mov al,ds:v_bpp
        mov cx,ds:v_width
        mov dx,ds:v_height
        mov si,ds:v_row_size
        mov edi,ds:v_app_base
        mov bx,system_data_sel
        mov ds,bx
        sub edi,ds:flat_base
        mov bx,flat_data_sel
        mov es,bx
        clc

gbi_done:
        pop bx
        pop ds
        retf32
get_bitmap_info Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   delete_bitmap
;
;               DESCRIPTION:    Delete bitmap
;
;               PARAMETERS:             DS:BX           Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_bitmap   Proc near
        test ds:[bx].bm_flag,BM_FLAG_BITMAP
        jz delete_bitmap_free
;
        push es
        push ecx
        push edx
        mov es,[bx].bm_sel
        sub es:v_usage_count,1
        jnz delete_bitmap_freed
;
        push bx
        mov bx,es:v_text_font
        or bx,bx
        jz delete_bitmap_font_ok
;
        CloseFont

delete_bitmap_font_ok:
        pop bx
;
        mov ax,es:v_text
        or ax,ax
        jz delete_bitmap_text_ok
;
        push es
        mov es,ax
        FreeMem
        pop es

delete_bitmap_text_ok:
        mov ecx,es:v_app_size
        mov edx,es:v_app_base
        FreeLinear
        FreeMem

delete_bitmap_freed:
        pop edx
        pop ecx
        pop es

delete_bitmap_free:
        FreeHandle

        clc
        ret
delete_bitmap   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CloseBitmap
;
;               DESCRIPTION:    Close bitmap
;
;               PARAMETERS:             BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_bitmap_name       DB 'Close Bitmap', 0

close_bitmap    Proc far
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
close_bitmap    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   delete_handle
;
;               DESCRIPTION:    BX                      Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
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
delete_handle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Init
;
;               DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_bitmap

init_bitmap     PROC near
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov ax,BITMAP_HANDLE
        mov di,OFFSET delete_handle
        RegisterHandle
;
        mov esi,OFFSET init_video_bitmap
        mov edi,OFFSET init_video_bitmap_name
        xor cl,cl
        mov ax,init_video_bitmap_nr
        RegisterOldOsGate
;
        mov esi,OFFSET create_bitmap
        mov edi,OFFSET create_bitmap_name
        xor dx,dx
        mov ax,create_bitmap_nr
        RegisterBimodalUserGate
;
        mov esi,OFFSET dup_bitmap_handle
        mov edi,OFFSET dup_bitmap_handle_name
        xor dx,dx
        mov ax,dup_bitmap_handle_nr
        RegisterBimodalUserGate
;
        mov esi,OFFSET close_bitmap
        mov edi,OFFSET close_bitmap_name
        xor dx,dx
        mov ax,close_bitmap_nr
        RegisterBimodalUserGate
;
        mov ebx,OFFSET create_string_bitmap16
        mov esi,OFFSET create_string_bitmap32
        mov edi,OFFSET create_string_bitmap_name
        mov dx,virt_es_in
        mov ax,create_string_bitmap_nr
        RegisterUserGate
;
        mov esi,OFFSET get_bitmap_info
        mov edi,OFFSET get_bitmap_info_name
        xor dx,dx
        mov ax,get_bitmap_info_nr
        RegisterBimodalUserGate
;
        ret
init_bitmap     ENDP

code    ENDS

        END
