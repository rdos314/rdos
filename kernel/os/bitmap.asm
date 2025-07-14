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
; BITMAP.ASM
; Bitmap module
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
INCLUDE video.inc
INCLUDE ..\apicheck.inc

code    SEGMENT byte public 'CODE'

    .386

    assume cs:code

    extrn BitmapTab1:near
    extrn BitmapTab8:near
    extrn BitmapTab16:near
    extrn BitmapTab24:near
    extrn BitmapTab32:near
    extrn TextModeTab:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateBitmap
;
;           DESCRIPTION:    Create bitmap
;
;           PARAMETERS:         AL          Bits per pixel
;                           CX          Width
;                           DX          Height
;
;           RETURNS:        BX          Bitmap handle
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
    mov es:v_alpha,0
    mov es:v_lgop,1
    mov es:v_font,0
    mov es:v_text_font,0
    mov es:v_style,0
    mov es:v_phys_base,0
    mov es:v_has_focus,0
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
    cmp al,8
    je cr_bitmap8
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
    mov esi,OFFSET BitmapTab1
    mov ax,es:v_width
    dec ax
    shr ax,3
    inc ax
    mov es:v_row_size,ax
    jmp cr_bitmap_copy

cr_bitmap8:
    mov esi,OFFSET BitmapTab8
    mov ax,es:v_width
    mov es:v_row_size,ax
    jmp cr_bitmap_copy

cr_bitmap16:
    mov esi,OFFSET BitmapTab16
    mov ax,es:v_width
    add ax,ax
    mov es:v_row_size,ax
    jmp cr_bitmap_copy

cr_bitmap24:
    mov esi,OFFSET BitmapTab24
    mov ax,es:v_width
    add ax,ax
    add ax,es:v_width
    dec ax
    add ax,4
    mov es:v_row_size,ax
    jmp cr_bitmap_copy

cr_bitmap32:
    mov esi,OFFSET BitmapTab32
    mov ax,es:v_width
    add ax,ax
    add ax,ax
    mov es:v_row_size,ax
    jmp cr_bitmap_copy

cr_bitmap_copy:
    mov ecx,2 * VIDEO_ENTRIES
    xor edi,edi
    rep movsd
;
    mov edi,SIZE video_api_struc
    mov es:v_sprite_lines,di
    movzx ecx,es:v_height
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
    mov ds:[ebx].bm_sel,es
    mov ds:[ebx].bm_flag,BM_FLAG_BITMAP
    mov ds:[ebx].hh_sign,BITMAP_HANDLE
    mov eax,es:v_color
    mov ds:[ebx].bm_color,eax
    mov ds:[ebx].bm_lgop,1
    mov ds:[ebx].bm_font,0
    mov ds:[ebx].bm_style,0
    mov ds:[ebx].bm_x_min,0
    mov ds:[ebx].bm_y_min,0
    mov ax,es:v_width
    dec ax
    mov ds:[ebx].bm_x_max,ax
    mov ax,es:v_height
    dec ax
    mov ds:[ebx].bm_y_max,ax
    mov bx,[ebx].hh_handle
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
    ret
create_bitmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreatePhysBitmap
;
;           DESCRIPTION:    Create physical device bitmap
;
;           PARAMETERS:     AL          Bits per pixel
;                           CX          Width
;                           DX          Height
;                           ES:EDI      Phys update proc
;
;           RETURNS:        BX          Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_phys_bitmap_name      DB 'Create Phys Bitmap', 0

create_phys_bitmap   Proc far
    push ds
    push es
    push fs
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push eax
    mov ax,es
    mov fs,ax
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
    mov es:v_alpha,0
    mov es:v_lgop,1
    mov es:v_font,0
    mov es:v_text_font,0
    mov es:v_style,0
    mov es:v_phys_base,0
    mov es:v_has_focus,1
    mov es:v_bpp,al
    cmp al,1
    jne create_phys_bitmap_no_pad
;
    dec cx
    and cx,0FFF8h
    add cx,8

create_phys_bitmap_no_pad:
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
    je cr_phys_bitmap1
;
    cmp al,8
    je cr_phys_bitmap8
;
    cmp al,16
    je cr_phys_bitmap16
;
    cmp al,24
    je cr_phys_bitmap24
;
    cmp al,32
    je cr_phys_bitmap32
;
    FreeMem
    stc
    jmp cr_phys_bitmap_end

cr_phys_bitmap1:
    mov es:v_color,1
    mov esi,OFFSET BitmapTab1
    mov ax,es:v_width
    dec ax
    shr ax,3
    inc ax
    mov es:v_row_size,ax
    jmp cr_phys_bitmap_copy

cr_phys_bitmap8:
    mov esi,OFFSET BitmapTab8
    mov ax,es:v_width
    mov es:v_row_size,ax
    jmp cr_phys_bitmap_copy

cr_phys_bitmap16:
    mov esi,OFFSET BitmapTab16
    mov ax,es:v_width
    add ax,ax
    mov es:v_row_size,ax
    jmp cr_phys_bitmap_copy

cr_phys_bitmap24:
    mov esi,OFFSET BitmapTab24
    mov ax,es:v_width
    add ax,ax
    add ax,es:v_width
    dec ax
    add ax,4
    mov es:v_row_size,ax
    jmp cr_phys_bitmap_copy

cr_phys_bitmap32:
    mov esi,OFFSET BitmapTab32
    mov ax,es:v_width
    add ax,ax
    add ax,ax
    mov es:v_row_size,ax
    jmp cr_phys_bitmap_copy

cr_phys_bitmap_copy:
    push edi
    mov ecx,2 * VIDEO_ENTRIES
    xor edi,edi
    rep movsd
    pop edi
;
    mov es:v_phys_update_proc,edi
    mov es:v_phys_update_proc+4,fs
;
    mov edi,SIZE video_api_struc
    mov es:v_sprite_lines,di
    movzx ecx,es:v_height
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
    mov edi,es:v_app_base
    mov ax,flat_sel
    mov es,ax
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop es
;
    mov eax,es:v_app_size
    AllocateBigLinear
    mov es:v_phys_base,edx
;
    mov esi,es:v_app_base
    mov edi,es:v_phys_base
    mov ecx,es:v_app_size
    shr ecx,12

cr_phys_copy_pages:
    mov edx,esi
    GetPageEntry
    mov edx,edi
    SetPageEntry
;
    add esi,1000h
    add edi,1000h
    loop cr_phys_copy_pages
;
    mov cx,SIZE bitmap_struc
    AllocateHandle
    mov ds:[ebx].bm_sel,es
    mov ds:[ebx].bm_flag,BM_FLAG_BITMAP
    mov ds:[ebx].hh_sign,BITMAP_HANDLE
    mov eax,es:v_color
    mov ds:[ebx].bm_color,eax
    mov ds:[ebx].bm_lgop,1
    mov ds:[ebx].bm_font,0
    mov ds:[ebx].bm_style,0
    mov ds:[ebx].bm_x_min,0
    mov ds:[ebx].bm_y_min,0
    mov ax,es:v_width
    dec ax
    mov ds:[ebx].bm_x_max,ax
    mov ax,es:v_height
    dec ax
    mov ds:[ebx].bm_y_max,ax
    mov bx,[ebx].hh_handle
    mov es:v_bitmap,bx
    clc

cr_phys_bitmap_end:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop fs
    pop es
    pop ds
    ret
create_phys_bitmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateVideoBitmap
;
;           DESCRIPTION:    Create video bitmap
;
;           PARAMETERS:     AL          Bits per pixel
;                           CX          Width
;                           DX          Height
;                           EBP         Line size
;                           EDI         LFB
;
;           RETURNS:        BX          Bitmap handle
;                           ES          Video object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateVideoBitmap
    
CreateVideoBitmap   Proc near
    push ds
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;    
    push eax
    mov ax,dx
    shl ax,2    
    add ax,SIZE video_api_struc
    movzx eax,ax
    AllocateSmallGlobalMem
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
    mov es:v_alpha,0
    mov es:v_lgop,1
    mov es:v_font,0
    mov es:v_text_font,0
    mov es:v_style,0
    mov es:v_phys_base,edi
    mov es:v_has_focus,0
    mov es:v_bpp,al
    cmp al,1
    jne cvbNoPad
;
    dec cx
    and cx,0FFF8h
    add cx,8

cvbNoPad:
    mov es:v_width,cx
    mov es:v_height,dx
    mov es:v_sprite_count,0
    mov es:v_sprite_size,0
    mov es:v_sprite_sel,0
    mov es:v_x_min,0
    mov es:v_y_min,0
    mov es:v_text,0
    mov es:v_row_size,bp
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
    je cvbBitmap1
;
    cmp al,8
    je cvbBitmap8
;
    cmp al,16
    je cvbBitmap16
;
    cmp al,24
    je cvbBitmap24
;
    cmp al,32
    je cvbBitmap32
;
    FreeMem
    stc
    jmp cvbBitmapEnd

cvbBitmap1:
    mov es:v_color,1
    mov esi,OFFSET BitmapTab1
    jmp cvbBitmapCopy

cvbBitmap8:
    mov esi,OFFSET BitmapTab8
    jmp cvbBitmapCopy

cvbBitmap16:
    mov esi,OFFSET BitmapTab16
    jmp cvbBitmapCopy

cvbBitmap24:
    mov esi,OFFSET BitmapTab24
    jmp cvbBitmapCopy

cvbBitmap32:
    mov esi,OFFSET BitmapTab32
    jmp cvbBitmapCopy

cvbBitmapCopy:
    mov ecx,2 * VIDEO_ENTRIES
    xor edi,edi
    rep movsd
;
    mov edi,SIZE video_api_struc
    mov es:v_sprite_lines,di
    movzx ecx,es:v_height
    mov eax,-1
    rep stosd
    mov es:v_sprite_max_pos,di
    mov es:v_app_base,0
;
    mov cx,SIZE bitmap_struc
    AllocateHandle
    mov ds:[ebx].bm_sel,es
    mov ds:[ebx].bm_flag,BM_FLAG_BITMAP
    mov ds:[ebx].hh_sign,BITMAP_HANDLE
    mov eax,es:v_color
    mov ds:[ebx].bm_color,eax
    mov ds:[ebx].bm_lgop,1
    mov ds:[ebx].bm_font,0
    mov ds:[ebx].bm_style,0
    mov ds:[ebx].bm_x_min,0
    mov ds:[ebx].bm_y_min,0
    mov ax,es:v_width
    dec ax
    mov ds:[ebx].bm_x_max,ax
    mov ax,es:v_height
    dec ax
    mov ds:[ebx].bm_y_max,ax
    mov bx,[ebx].hh_handle
    mov es:v_bitmap,bx
    clc

cvbBitmapEnd:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
CreateVideoBitmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateTextBitmap
;
;           DESCRIPTION:    Create text-mode bitmap
;
;           PARAMETERS:     CX          Width
;                           DX          Height
;                           EDI         Buffer
;
;           RETURNS:        BX          Bitmap handle
;                           ES          Video object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateTextBitmap
    
CreateTextBitmap   Proc near
    push ds
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;    
    mov eax,SIZE video_api_struc
    AllocateSmallGlobalMem
    mov si,es
    mov ds,si
    InitSection ds:v_section
    InitSection ds:v_sprite_section
;    
    mov es:v_usage_count,1
    mov es:v_color,0
    mov es:v_alpha,0
    mov es:v_lgop,1
    mov es:v_font,0
    mov es:v_text_font,0
    mov es:v_style,0
    mov es:v_phys_base,edi
    mov es:v_has_focus,0
    mov es:v_bpp,0
;    
    mov es:v_width,cx
    mov es:v_height,dx
    mov es:v_sprite_count,0
    mov es:v_sprite_size,0
    mov es:v_sprite_sel,0
    mov es:v_x_min,0
    mov es:v_y_min,0
    mov es:v_text,0
    mov es:v_row_size,0
    mov es:v_x_max,0
    mov es:v_y_max,0
;
    mov si,cs
    mov ds,si
;
    mov es:v_color,0
    mov ecx,2 * VIDEO_ENTRIES
    mov esi,OFFSET TextModeTab
    xor edi,edi
    rep movsd
;
    mov es:v_sprite_max_pos,0
    mov es:v_app_base,0
    xor bx,bx
    clc
;    
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
CreateTextBitmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateVideoBuffer
;
;           DESCRIPTION:    Allocate video buffer
;
;           PARAMETERS:     ES          Video object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateVideoBuffer
    
AllocateVideoBuffer   Proc near
    push es
    pushad
;    
    movzx eax,es:v_row_size
    movzx edx,es:v_height
    mul edx
    dec eax
    and ax,0F000h
    add eax,1000h
    mov es:v_app_size,eax
    AllocateBigLinear
    mov es:v_app_base,edx
;
    mov ecx,eax
    shr ecx,2
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    popad
    pop es
    ret
AllocateVideoBuffer Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeVideoBuffer
;
;           DESCRIPTION:    Free video buffer
;
;           PARAMETERS:     ES          Video object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeVideoBuffer
    
FreeVideoBuffer   Proc near
    push es
    pushad
;    
    mov ecx,es:v_app_size
    mov edx,es:v_app_base
    FreeLinear
;
    popad
    pop es
    ret
FreeVideoBuffer Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateAlphaBitmap
;
;           DESCRIPTION:    Create alpha bitmap
;
;           PARAMETERS:     CX          Width
;                           DX          Height
;
;           RETURNS:        BX          Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_alpha_bitmap_name      DB 'Create Alpha Bitmap', 0

create_alpha_bitmap   Proc far
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
    mov es:v_alpha,1
    mov es:v_lgop,1
    mov es:v_font,0
    mov es:v_text_font,0
    mov es:v_style,0
    mov es:v_phys_base,0
    mov es:v_has_focus,0
    mov es:v_bpp,32
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
    mov esi,OFFSET BitmapTab32
    mov ax,es:v_width
    add ax,ax
    add ax,ax
    mov es:v_row_size,ax
;
    mov ecx,2 * VIDEO_ENTRIES
    xor edi,edi
    rep movsd
;
    mov edi,SIZE video_api_struc
    mov es:v_sprite_lines,di
    movzx ecx,es:v_height
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
    mov ds:[ebx].bm_sel,es
    mov ds:[ebx].bm_flag,BM_FLAG_BITMAP
    mov ds:[ebx].hh_sign,BITMAP_HANDLE
    mov eax,es:v_color
    mov ds:[ebx].bm_color,eax
    mov ds:[ebx].bm_lgop,1
    mov ds:[ebx].bm_font,0
    mov ds:[ebx].bm_style,0
    mov ds:[ebx].bm_x_min,0
    mov ds:[ebx].bm_y_min,0
    mov ax,es:v_width
    dec ax
    mov ds:[ebx].bm_x_max,ax
    mov ax,es:v_height
    dec ax
    mov ds:[ebx].bm_y_max,ax
    mov bx,[ebx].hh_handle
    mov es:v_bitmap,bx
    clc
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_alpha_bitmap   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DuplicateBitmapHandle
;
;           DESCRIPTION:    Duplicate bitmap handle
;
;           PARAMETERS:         BX      Bitmap handle
;
;           RETURNS:        BX          Duplicated bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dup_bitmap_handle_name  DB 'Duplicate Bitmap Handle', 0

dup_bitmap_handle       Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push es
    push ax
    push cx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc dph_done
;
    mov es,[ebx].bm_sel
    mov ax,[ebx].bm_flag
    mov cx,SIZE bitmap_struc
    AllocateHandle
    mov ds:[ebx].bm_sel,es
    mov ds:[ebx].bm_flag,ax
    mov ds:[ebx].hh_sign,BITMAP_HANDLE
    mov ds:[ebx].bm_color,0
    mov ds:[ebx].bm_lgop,1
    mov ds:[ebx].bm_font,0
    mov ds:[ebx].bm_style,0
    mov ds:[ebx].bm_x_min,0
    mov ds:[ebx].bm_y_min,0
    mov ax,es:v_width
    dec ax
    mov ds:[ebx].bm_x_max,ax
    mov ax,es:v_height
    dec ax
    mov ds:[ebx].bm_y_max,ax
    mov bx,[ebx].hh_handle
    inc es:v_usage_count
    clc

dph_done:
    pop cx
    pop ax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    ret
dup_bitmap_handle       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetStringBitmap
;
;           DESCRIPTION:    Create string bitmap
;
;           PARAMETERS:         ES:(E)DI    String
;                           BX              Font handle
;
;           RETURNS:        BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_string_bitmap_name       DB 'Create String Bitmap', 0

csb_font_handle     EQU -4
csb_bitmap_handle   EQU -6
csb_width           EQU -8
csb_height          EQU -10
csb_y               EQU -12
csb_x               EQU -14

create_string_bitmap    Proc near
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ebp
    mov ebp,esp
    sub esp,16
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
    mov [ebp].csb_font_handle,bx
    UserGateForce32 get_string_metrics_nr
    mov [ebp].csb_width,cx
    mov [ebp].csb_height,dx
;
    mov ax,1
    CreateBitmap
    mov [ebp].csb_bitmap_handle,bx
;
    mov ax,LGOP_OR
    SetLgop
    mov word ptr [ebp].csb_x,0
    mov word ptr [ebp].csb_y,0

crs_bitmap_loop:
    mov al,fs:[edi]
    or al,al
    jz crs_bitmap_ok
;
    inc edi
    push edi
;
    mov bx,[ebp].csb_font_handle
    stc
;    GetCharMask
    jc crs_bitmap_next
;
    mov ax,si
    mov bx,[ebp].csb_bitmap_handle
    push dx
    push cx
    pop esi
    xor ecx,ecx
    mov edx,[ebp].csb_x
    DrawMask
    add [ebp].csb_x,si

crs_bitmap_next:
    pop edi
    jmp crs_bitmap_loop

crs_bitmap_ok:
    mov bx,[ebp].csb_bitmap_handle
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
    add esp,16
    pop ebp

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    ret
create_string_bitmap    Endp

create_string_bitmap32  Proc far
    call create_string_bitmap
    ret
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
;           NAME:           GetBitmapInfo
;
;           DESCRIPTION:    Get bitmap info
;
;           PARAMETERS:         BX          Bitmap handle
;
;           RETURNS:        AL          Bits / pixel
;                           CX          Width
;                           DX          Height
;                           SI          Line size in bytes
;                           ES:EDI  Buffer data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_bitmap_info_name    DB 'Get Bitmap Info', 0

get_bitmap_info Proc far
    push ds
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc gbi_done
;
    mov ds,[ebx].bm_sel
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
    pop ebx
    pop ds
    ret
get_bitmap_info Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_bitmap
;
;           DESCRIPTION:    Delete bitmap
;
;           PARAMETERS:         DS:EBX       Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_bitmap   Proc near
    test ds:[ebx].bm_flag,BM_FLAG_BITMAP
    jz delete_bitmap_free
;
    push es
    push ecx
    push edx
    mov es,[ebx].bm_sel
    sub es:v_usage_count,1
    jnz delete_bitmap_freed
;
    push ebx
    mov bx,es:v_text_font
    or bx,bx
    jz delete_bitmap_font_ok
;
    CloseFont

delete_bitmap_font_ok:
    pop ebx
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
;           NAME:           CloseBitmap
;
;           DESCRIPTION:    Close bitmap
;
;           PARAMETERS:         BX          Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_bitmap_name       DB 'Close Bitmap', 0

close_bitmap    Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc cl_bitmap_done
;
    call delete_bitmap

cl_bitmap_done:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    ret
close_bitmap    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc delete_handle_done
;
    call delete_bitmap

delete_handle_done:
    pop ebx
    pop ax
    pop ds
    ret
delete_handle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_bitmap

init_bitmap     PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ax,BITMAP_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov esi,OFFSET create_phys_bitmap
    mov edi,OFFSET create_phys_bitmap_name
    mov ax,create_phys_bitmap_nr
    RegisterOsGate
;
    mov esi,OFFSET create_bitmap
    mov edi,OFFSET create_bitmap_name
    xor dx,dx
    mov ax,create_bitmap_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_alpha_bitmap
    mov edi,OFFSET create_alpha_bitmap_name
    xor dx,dx
    mov ax,create_alpha_bitmap_nr
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
