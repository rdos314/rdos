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
; VBE.ASM
; VBE based video device driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\video.inc
INCLUDE ..\handle.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE vbe.inc

VIDEO_MODE_FLAGS_PM         EQU 1
VIDEO_MODE_FLAGS_LFB    EQU 2

video_resol_struc       STRUC

vr_next             DW ?

vr_x_size               DW ?
vr_y_size               DW ?

vr_flat16_mode      DW ?
vr_flat24_mode      DW ?
vr_flat32_mode      DW ?

vr_flat16_flags     DB ?
vr_flat24_flags     DB ?
vr_flat32_flags     DB ?

video_resol_struc       ENDS

data    SEGMENT byte public 'DATA'

v_video_mem             DD ?
v_cap               DW ?

v_init_proc             DW ?

v_set_window_proc       DW ?
v_set_start_proc    DW ?
v_set_palette_proc      DW ?

v_major_ver             DB ?
v_minor_ver             DB ?

v_pm16_stack        DW ?
v_pm16_entry        DD ?
v_pm32_io               DW ?
v_pm32_data_sel     DW ?
v_pm32_code_sel     DW ?

v_video_resol_list      DW ?

data    ENDS

    extrn ClearVideoObj:near
    extrn GetVideoObj:near
    extrn SetVideoObj:near

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_flat_mode
;
;           DESCRIPTION:    Init flat video-mode
;
;           PARAMETERS:         AX          Mode #
;
;           RETURNS:        AX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinearTab:
mt00 DW OFFSET delete_linear,       SEG code
mt01 DW OFFSET switch_to_linear,    SEG code
mt02 DW OFFSET switch_from_linear,  SEG code

init_flat_mode  Proc far
    push ds
    push es
    push bx
    push cx
    push dx
    push si
    push di
    push bp
;
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:v_video_resol_list
    or bx,bx
    jz init_flat_fail

init_flat_resol_loop:
    mov es,bx
;
    mov dl,es:vr_flat32_flags
    mov dh,32
    cmp ax,es:vr_flat32_mode
    je init_flat_found
;
    mov dl,es:vr_flat24_flags
    mov dh,24
    cmp ax,es:vr_flat24_mode
    je init_flat_found
;
    mov dl,es:vr_flat16_flags
    mov dh,16
    cmp ax,es:vr_flat16_mode
    je init_flat_found
;
    mov bx,es:vr_next
    or bx,bx
    jnz init_flat_resol_loop
;
    jmp init_flat_fail

init_flat_found:
    mov bx,ax
    mov cx,ax
    mov eax,1000h
    AllocateGlobalMem
    xor di,di
    test dl, VIDEO_MODE_FLAGS_PM
    jnz init_flat_pm

init_flat_v86:
    mov ax,4F01h
    push 10h
    V86BiosInt
    mov si,ax
    jmp init_flat_check

init_flat_pm:
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:v_pm16_stack
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1024
    push ebp
;
    mov ax,4F01h
    call ds:v_pm16_entry
    mov si,ax
;
    pop ebp
    mov ax,bp
    shr ebp,16
    mov ss,ax
    mov sp,bp

init_flat_check:
    cmp si,4Fh
    jne init_flat_free_fail
;
    mov ax,es
    mov ds,ax
    mov ax,ds:vmi_y_pixels
    shl ax,2
    add ax,SIZE vbe_object
    movzx eax,ax
    AllocateSmallGlobalMem
    mov es:v_sprite_lines,SIZE vbe_object
;
    push bx
    mov al,dh
    mov cx,ds:vmi_x_pixels
    mov dx,ds:vmi_y_pixels
    InitVideoBitmap
    pop bx
;
    mov ax,ds:vmi_scan_lines
    mov es:v_row_size,ax
    mov eax,ds:vmi_lfb
    mov es:vo_lfb,eax
    mov es:vo_flags,dl
    mov es:vo_has_focus,0
    mov es:v_mode,bx
;
    mov di,OFFSET vo_mode_info
    xor si,si
    mov cx,SIZE vesa_mode_info
    rep movsb
;
    movzx eax,ds:vmi_scan_lines
    movzx edx,ds:vmi_y_pixels
    mul edx
    dec eax
    and ax,0F000h
    add eax,1000h
    mov es:v_app_size,eax
    AllocateBigLinear
    mov es:vo_lfb_base,edx
    AllocateBigLinear
    mov es:vo_mem_base,edx
    AllocateLocalLinear
    mov es:v_app_base,edx
;
    push es
    mov edi,es:vo_mem_base
    mov ecx,eax
    shr ecx,2
    mov ax,flat_sel
    mov es,ax
    xor eax,eax
;       mov eax,8000h
    rep stos dword ptr es:[edi]
    pop es
;
    push ds
    push es
    mov esi,es:vo_mem_base
    shr esi,10
    mov edi,es:v_app_base
    shr edi,10
    mov ecx,es:v_app_size
    shr ecx,12
    mov bx,process_page_sel
    mov ds,bx
    mov es,bx
    rep movs dword ptr es:[edi],ds:[esi]
    pop es
    pop ds
;
    push ds
    mov edi,es:vo_lfb_base
    shr edi,10
    mov ecx,es:v_app_size
    shr ecx,12
    mov bx,process_page_sel
    mov ds,bx
    mov edx,es:vo_lfb
    or dl,7

init_lfb_map_loop:
    mov ds:[edi],edx
    add edi,4
    add edx,1000h
    sub ecx,1
    jnz init_lfb_map_loop
;
    pop ds
    push ds
    mov cx,3
    mov ax,cs
    mov ds,ax
    mov si,OFFSET LinearTab
    xor di,di
    rep movsd
    mov ax,es
    pop es
    FreeMem
    clc
    jmp init_flat_done

init_flat_free_fail:
    FreeMem

init_flat_fail:
    xor ax,ax
    stc

init_flat_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop es
    pop ds
    retf32
init_flat_mode  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_linear
;
;           DESCRIPTION:    Delete flat video mode
;
;           RETURNS:        DS          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public delete_linear

delete_linear   Proc far
    push ax
    push bx
    push ecx
    push edx
    push edi
;
    call ClearVideoObj
    mov ax,process_page_sel
    mov es,ax
;
    mov edi,ds:vo_lfb_base
    shr edi,10
    mov ecx,ds:v_app_size
    shr ecx,12
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov edi,ds:v_app_base
    shr edi,10
    mov ecx,ds:v_app_size
    shr ecx,12
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov ecx,ds:v_app_size
    mov edx,ds:vo_lfb_base
    FreeLinear
    mov edx,ds:vo_mem_base
    FreeLinear
    mov edx,ds:v_app_base
    FreeLinear
;
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
;
    pop edi
    pop edx
    pop ecx
    pop bx
    pop ax
    ret
delete_linear   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           switch_to_linear
;
;           DESCRIPTION:    Enter focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public switch_to_linear

switch_to_linear    Proc far
    push es
    pushad
;
    call GetVideoObj
    or ax,ax
    jz switch_to_set
;
    cmp ax,-1
    je switch_to_set
;
    mov es,ax
    mov ax,es:v_mode
    cmp ax,ds:v_mode
    je switch_to_active

switch_to_set:
    mov bx,ds:v_mode
    test ds:vo_flags, VIDEO_MODE_FLAGS_PM
    jnz switch_to_pm

switch_to_v86:
    push ds
    xor ax,ax
    mov ds,ax
    mov es,ax
    or bx,4000h
    or bx,8000h
    mov ax,4F02h
    push 10h
    V86BiosInt
    pop ds
    jmp switch_to_active

switch_to_pm:
    mov ax,es:v_pm16_stack
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1024
    push ebp
;
    or bx,4000h
    or bx,8000h
    mov ax,4F02h
    call es:v_pm16_entry
;
    pop ebp
    mov ax,bp
    shr ebp,16
    mov ss,ax
    mov sp,bp

switch_to_active:
    SimCli
    mov ax,ds
    call SetVideoObj
    mov ds:vo_has_focus,1
;
    mov ax,flat_sel
    mov es,ax
    mov esi,ds:vo_mem_base
    mov edi,ds:vo_lfb_base
    mov ecx,ds:v_app_size
    shr ecx,2
    rep movs dword ptr es:[edi],es:[esi]
;
    mov esi,ds:vo_lfb_base
    shr esi,10
    mov edi,ds:v_app_base
    mov ecx,ds:v_app_size
    GetFocusThread
    mov es,ax
    mov bx,alias_linear SHR 20
    mov eax,es:p_cr3
    mov dx,process_dir_sel
    mov es,dx
    or ax,803h
    mov es:[bx],eax
    mov eax,cr3
    mov cr3,eax
;
    mov eax,alias_linear
    shr edi,10
    and di,0FFFCh
    add edi,eax
    shr ecx,12
    push ds
    mov bx,process_page_sel
    mov ds,bx
    mov bx,flat_sel
    mov es,bx
    rep movs dword ptr es:[edi],ds:[esi]
    SimSti
    pop ds
;
    popad
    pop es
    ret
switch_to_linear    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SwitchFrom
;
;           DESCRIPTION:    Leave focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public switch_from_linear

switch_from_linear      Proc far
    push es
    pushad
;
    SimCli
    mov ds:vo_has_focus,1
    mov ax,flat_sel
    mov es,ax
    mov esi,ds:vo_lfb_base
    mov edi,ds:vo_mem_base
    mov ecx,ds:v_app_size
    shr ecx,2
    rep movs dword ptr es:[edi],es:[esi]
;
    mov esi,ds:vo_mem_base
    shr esi,10
    mov edi,ds:v_app_base
    mov ecx,ds:v_app_size
    GetFocusThread
    mov es,ax
    mov bx,alias_linear SHR 20
    mov eax,es:p_cr3
    mov dx,process_dir_sel
    mov es,dx
    or ax,803h
    mov es:[bx],eax
    mov eax,cr3
    mov cr3,eax
;
    mov eax,alias_linear
    shr edi,10
    and di,0FFFCh
    add edi,eax
    shr ecx,12
    push ds
    mov bx,process_page_sel
    mov ds,bx
    mov bx,flat_sel
    mov es,bx
    rep movs dword ptr es:[edi],ds:[esi]
    SimSti
    pop ds
;
    popad
    pop es
    ret
switch_from_linear      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FindResolution
;
;           DESCRIPTION:    Find a resolution
;
;           PARAMETERS:         DS          PC video sel
;                           CX          x-resolution
;                           DX          y-resolution
;
;           RETURNS:        NC          OK
;                           ES          Resolution selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindResolution  Proc near
    push ax
;
    mov ax,ds:v_video_resol_list
    or ax,ax
    stc
    jz find_resol_done

find_resol_loop:
    mov es,ax
    cmp cx,es:vr_x_size
    jne find_resol_next
;
    cmp dx,es:vr_y_size
    clc
    je find_resol_done

find_resol_next:
    mov ax,es:vr_next
    or ax,ax
    jnz find_resol_loop
;
    stc

find_resol_done:
    pop ax
    ret
FindResolution  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddResolution
;
;           DESCRIPTION:    Add a resolution
;
;           PARAMETERS:         DS          PC video sel
;                           CX          x-resolution
;                           DX          y-resolution
;
;           RETURNS:        ES          Resolution selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddResolution   Proc near
    push eax
    mov eax,SIZE video_resol_struc
    AllocateSmallGlobalMem
    mov ax,ds:v_video_resol_list
    mov es:vr_next,ax
    mov ds:v_video_resol_list,es
    mov es:vr_x_size,cx
    mov es:vr_y_size,dx
    mov es:vr_flat16_mode,0
    mov es:vr_flat24_mode,0
    mov es:vr_flat32_mode,0
    mov es:vr_flat16_flags,0
    mov es:vr_flat24_flags,0
    mov es:vr_flat32_flags,0
    pop eax
    ret
AddResolution   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddVideoMode
;
;           DESCRIPTION:    Add a video mode
;
;           PARAMETERS:         DS          PC video sel
;                           AX          0 = V86, 1 = PM
;                           CX          Mode #
;                           ES          Video mode info block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddVideo    MACRO mode
    local add_new
    local add_v86
    local add_do

    mov dx,es:vr_&mode&_mode
    or dx,dx
    jz add_do
;
    mov dl,es:vr_&mode&_flags
    test dl,VIDEO_MODE_FLAGS_PM
    jz add_v86
;
    or ax,ax
    jz add_video_done
;
    test dl,VIDEO_MODE_FLAGS_LFB
    jnz add_video_done

add_do:
    mov es:vr_&mode&_mode,cx
    or es:vr_&mode&_flags, VIDEO_MODE_FLAGS_LFB
    or ax,ax
    jz add_video_done
;
    or es:vr_&mode&_flags, VIDEO_MODE_FLAGS_PM
    jmp add_video_done

add_v86:
    or ax,ax
    jnz add_do
;
    test dl,VIDEO_MODE_FLAGS_LFB
    jz add_do       
    jmp add_video_done
        ENDM

AddVideoMode    Proc near
    push es
    push fs
;
    mov dx,es
    mov fs,dx
    push ax
    push cx
    push di
;
    mov ax,cs
    mov es,ax       
    mov ax,cx
    mov bl,fs:vmi_bits_per_pixel
    mov cx,fs:vmi_x_pixels
    mov dx,fs:vmi_y_pixels
    mov edi,OFFSET init_flat_mode
    RegisterVideoMode
;
    call FindResolution
    jnc add_video_found
;
    call AddResolution

add_video_found:
    pop di
    pop cx
    pop ax
;
    mov dl,fs:vmi_bits_per_pixel
    cmp dl,16
    je add_video16
;
    cmp dl,24
    je add_video24
;
    cmp dl,32
    je add_video32
    jmp add_video_done

add_video16:
    AddVideo flat16

add_video24:
    AddVideo flat24

add_video32:
    AddVideo flat32

add_video_done:
    pop fs
    pop es
    ret
AddVideoMode    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DecodeVideoMode
;
;           DESCRIPTION:    Decode a video mode
;
;           PARAMETERS:         DS          PC video sel
;                           AX          0 = V86, 1 = PM
;                           CX          Mode #
;                           ES          Video mode info block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeVideoMode Proc near
    mov dx,es:vmi_mode_attrib
    and dx,MODE_ATTRIB_REQUIRED
    cmp dx,MODE_ATTRIB_REQUIRED
    stc
    jne decode_video_mode_done
;
    mov dl,es:vmi_memory_model
    cmp dl,MODEL_DIRECT
    clc
    jne decode_video_mode_done
;
    call AddVideoMode
    clc

decode_video_mode_done:
    ret
DecodeVideoMode Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetVideoModesPm
;
;           DESCRIPTION:    Get all video modes, protected mode version
;
;           PARAMETERS:         ES          Info selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetVideoModesPm Proc near
    push ds
    push es
    push fs
    pusha
;
    mov ax,SEG data
    mov ds,ax
    lfs si,es:vesa_modes
    mov eax,1000h
    AllocateGlobalMem
    xor di,di

get_video_modes_pm_loop:
    mov cx,fs:[si]
    add si,2
    cmp cx,-1
    je get_video_modes_pm_done
;
    mov ax,ds:v_pm16_stack
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1024
    push ebp
    mov ax,4F01h
    call ds:v_pm16_entry
    pop ebp
    cmp ax,4Fh
    mov ax,bp
    pushf
    shr ebp,16
    popf
    mov ss,ax
    mov sp,bp
    jne get_video_modes_pm_loop
;
    mov ax,1
    call DecodeVideoMode
    jnc get_video_modes_pm_loop
;
    mov ax,4F01h
    push 10h
    V86BiosInt
    cmp ax,4Fh
    jne get_video_modes_pm_loop
;
    xor ax,ax
    call DecodeVideoMode
;
    jmp get_video_modes_pm_loop

get_video_modes_pm_done:
;       FreeMem
;
    popa
    pop fs
    pop es
    pop ds
    ret
GetVideoModesPm Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetVideoModesV86
;
;           DESCRIPTION:    Get all video modes, V86 mode version
;
;           PARAMETERS:         ES          Info selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetVideoModesV86    Proc near
    push ds
    push es
    push fs
    pusha
;
    mov ax,word ptr es:vesa_modes+2
    cmp ax,2000h
    jne get_video_modes_v86_not_self
;
    mov ax,es
    mov fs,ax
    jmp get_video_modes_v86_do

get_video_modes_v86_not_self:
    cmp ax,0C000h
    jne get_video_modes_v86_done
;
    mov ax,__C000
    mov fs,ax

get_video_modes_v86_do:
    mov si,word ptr es:vesa_modes
    mov eax,1000h
    AllocateGlobalMem
    xor di,di

get_video_modes_v86_loop:
    mov cx,fs:[si]
    add si,2
    cmp cx,-1
    je get_video_modes_v86_free
;
    xor ax,ax
    mov ds,ax
    mov ax,4F01h
    push 10h
    V86BiosInt
    cmp ax,4Fh
    jne get_video_modes_v86_loop
;
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    call DecodeVideoMode
    jmp get_video_modes_v86_loop

get_video_modes_v86_free:
;       FreeMem

get_video_modes_v86_done:
    popa
    pop fs
    pop es
    pop ds
    ret
GetVideoModesV86    Endp

vesa_id DB 'VESA'

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetWindowV86
;
;           DESCRIPTION:    V86 SetWindow
;
;           PARAMETERS:         BL          Window A/B
;                           DX          Window #
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWindowV86    Proc near
    push ds
    push es
;
    xor ax,ax
    mov ds,ax
    mov es,ax
    xor bh,bh
    push 10h
    mov ax,4F05h
    V86BiosInt
;
    pop es
    pop ds
    ret
SetWindowV86    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetStartV86
;
;           DESCRIPTION:    V86 SetStart
;
;           PARAMETERS:         CX          First pixel
;                           DX          First line          
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetStartV86     Proc near
    push ds
    push es
;
    xor ax,ax
    xor bx,bx
    mov ds,ax
    mov es,ax
    push 10h
    mov ax,4F07h
    V86BiosInt
;
    pop es
    pop ds
    ret
SetStartV86     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetPaletteV86
;
;           DESCRIPTION:    V86 SetPalette
;
;           PARAMETERS:         CX          Palette entries
;                           DX          First entry
;                           ES:DI   Palette data
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPaletteV86   Proc near
    push ds
;
    xor bl,bl
    xor ax,ax
    mov ds,ax
    push 10h
    mov ax,4F09h
    V86BiosInt
;
    pop ds
    ret
SetPaletteV86   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetWindowPm16
;
;           DESCRIPTION:    16-bit protected mode SetWindow
;
;           PARAMETERS:         BL          Window A/B
;                           DX          Window #
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWindowPm16   Proc near
    push ds
    push si
    push bp
;
    xor bh,bh
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:v_pm16_stack
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1024
    push ebp
    mov ax,4F05h
    call ds:v_pm16_entry
    pop ebp
    mov si,bp
    shr ebp,16
    mov ss,si
    mov sp,bp
;
    pop bp
    pop si
    pop ds
    ret
SetWindowPm16   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SeStartPm16
;
;           DESCRIPTION:    16-bit protected mode SetStart
;
;           PARAMETERS:         CX          First pixel
;                           DX          First line          
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetStartPm16    Proc near
    push ds
    push bp
;
    xor bx,bx
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:v_pm16_stack
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1024
    push ebp
    mov ax,4F07h
    call ds:v_pm16_entry
    pop ebp
    mov si,bp
    shr ebp,16
    mov ss,si
    mov sp,bp
;
    pop bp
    pop si
    pop ds
    ret
SetStartPm16    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetPalettePm16
;
;           DESCRIPTION:    16-bit protected mode SetPalette
;
;           PARAMETERS:         CX          Palette entries
;                           DX          First entry
;                           ES:DI   Palette data
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPalettePm16  Proc near
    push ds
    push bp
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:v_pm16_stack
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1024
    push ebp
    mov ax,4F09h
    call ds:v_pm16_entry
    pop ebp
    mov si,bp
    shr ebp,16
    mov ss,si
    mov sp,bp
;
    pop bp
    pop si
    pop ds
    ret
SetPalettePm16  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetWindowPm32
;
;           DESCRIPTION:    32-bit protected mode SetWindow
;
;           PARAMETERS:         BL          Window A/B
;                           DX          Window #
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWindowPm32   Proc near
    push ds
    push es
    push gs
    push si
;
    xor bh,bh
    mov ax,SEG data
    mov gs,ax
    mov ax,gs:v_pm32_data_sel
    mov ds,ax
    mov es,gs:v_pm32_io
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1000h
    push ebp
    sub sp,8
    mov bp,sp
    mov dword ptr [bp],100h
    mov ax,gs:v_pm32_code_sel
    mov [bp+4],ax
    mov ax,4F05h
    call fword ptr [bp]
    add sp,8
    pop ebp
;
    mov si,bp
    shr ebp,16
    mov ss,si
    mov sp,bp
;
    pop si
    pop gs
    pop es
    pop ds
    ret
SetWindowPm32   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetStartPm32
;
;           DESCRIPTION:    32-bit protected mode SetStart
;
;           PARAMETERS:         CX          First pixel
;                           DX          First line          
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetStartPm32    Proc near
    push ds
    push es
    push gs
    push si
;
    xor bx,bx
    mov ax,SEG data
    mov gs,ax
    mov ax,gs:v_pm32_data_sel
    mov ds,ax
    mov es,gs:v_pm32_io
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1000h
    push ebp
    sub sp,8
    mov bp,sp
    mov dword ptr [bp],108h
    mov ax,gs:v_pm32_code_sel
    mov [bp+4],ax
    mov ax,4F05h
    call fword ptr [bp]
    add sp,8
    pop ebp
;
    mov si,bp
    shr ebp,16
    mov ss,si
    mov sp,bp
;
    pop si
    pop gs
    pop es
    pop ds
    ret
SetStartPm32    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetPalettePm32
;
;           DESCRIPTION:    32-bit protected mode SetPalette
;
;           PARAMETERS:         CX          Palette entries
;                           DX          First entry
;                           ES:DI   Palette data
;
;           RETURNS:        AX          Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPalettePm32  Proc near
    push ds
    push es
    push gs
    push si
;
    xor bh,bh
    mov ax,SEG data
    mov gs,ax
    mov ds,gs:v_pm32_io
    mov ax,gs:v_pm32_data_sel
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1000h
    push ebp
    sub sp,8
    mov bp,sp
    mov dword ptr [bp],110h
    mov ax,gs:v_pm32_code_sel
    mov [bp+4],ax
    mov ax,4F05h
    call fword ptr [bp]
    add sp,8
    pop ebp
;
    mov si,bp
    shr ebp,16
    mov ss,si
    mov sp,bp
;
    pop si
    pop gs
    pop es
    pop ds
    ret
SetPalettePm32  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitPm
;
;           DESCRIPTION:    Protected mode init
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPm  Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov eax,10000h
    AllocateGlobalMem
    xor di,di
;
    mov ax,ds:v_pm16_stack
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1024
    push ebp
;
    mov ax,4F00h
    call ds:v_pm16_entry
    cmp ax,4Fh
    jne init_pm_leave
;
    mov eax,dword ptr es:vesa_name
    cmp eax,dword ptr cs:vesa_id
    jne init_pm_leave
;
    mov al,es:vesa_major_ver
    mov ds:v_major_ver,al
    mov al,es:vesa_minor_ver
    mov ds:v_minor_ver,al
    mov eax,es:vesa_cap
    mov ds:v_cap,ax
    mov ax,es:vesa_video_mem
    shl eax,16
    mov ds:v_video_mem,eax
    pop ebp
    mov ax,bp
    shr ebp,16
    mov ss,ax
    mov sp,bp
    call GetVideoModesPm
    jmp init_pm_free

init_pm_leave:
    pop ebp
    mov ax,bp
    shr ebp,16
    mov ss,ax
    mov sp,bp

init_pm_free:
;       FreeMem
;
    popad
    pop es
    pop ds
    ret
InitPm  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitV86
;
;           DESCRIPTION:    V86 mode init
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitV86 Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov eax,11000h
    AllocateGlobalMem
    xor di,di
;
    push 10h
    mov ax,4F00h
    V86BiosInt
    cmp ax,4Fh
    jne init_v86_check_failed
;
    mov eax,dword ptr es:vesa_name
    cmp eax,dword ptr cs:vesa_id
    jne init_v86_check_failed
;
    mov al,es:vesa_major_ver
    mov ds:v_major_ver,al
    mov al,es:vesa_minor_ver
    mov ds:v_minor_ver,al
    mov eax,es:vesa_cap
    mov ds:v_cap,ax
    mov ax,es:vesa_video_mem
    shl eax,16
    mov ds:v_video_mem,eax
;
    mov al,ds:v_major_ver
    cmp al,2
;       jc init_v86_calls
;
    mov bx,es
    GetSelectorBaseSize
    add edx,1000h
    sub ecx,1000h
    CreateDataSelector16
    mov es,bx
;
    push ecx
    push edi
;
    xor al,al
    xor edi,edi
    rep stos byte ptr es:[edi]
;
    pop edi
    pop ecx
;
    mov ax,4F0Ah
    xor bl,bl
    push 10h
    V86BiosInt
;
    mov bx,es
    GetSelectorBaseSize
    sub edx,1000h
    add ecx,1000h
    CreateDataSelector16
    mov es,bx
;       
    cmp ax,4Fh
    jne init_v86_calls
;
    movzx edi,di
    add edi,1000h
    mov ebx,100h
;
    movzx eax,es:[edi].vpm_set_window
    add eax,edi
    sub eax,ebx
    sub eax,5
    mov byte ptr es:[bx],0E8h
    mov es:[bx+1],eax
    mov byte ptr es:[bx+5],0CBh
    add bx,8
;
    movzx eax,es:[edi].vpm_set_disp_start
    add eax,edi
    sub eax,ebx
    sub eax,5
    mov byte ptr es:[bx],0E8h
    mov es:[bx+1],eax
    mov byte ptr es:[bx+5],0CBh
    add bx,8
;
    movzx eax,es:[edi].vpm_set_palette
    add eax,edi
    sub eax,ebx
    sub eax,5
    mov byte ptr es:[bx],0E8h
    mov es:[bx+1],eax
    mov byte ptr es:[bx+5],0CBh
;
    mov bx,es
    GetSelectorBaseSize
;
    AllocateGdt
    CreateCodeSelector32
    mov ds:v_pm32_code_sel,bx
;
    AllocateGdt
    CreateDataSelector32
    mov ds:v_pm32_data_sel,bx
;
    movzx ebx,es:[edi].vpm_table
    or bx,bx
    jz init_v86_memory_done
;
    add ebx,edi

init_v86_io_loop:
    mov ax,es:[ebx]
    add ebx,2
    cmp ax,-1
    jne init_v86_io_loop
;
    mov ax,es:[ebx]
    cmp ax,-1
    je init_v86_memory_done
;
    mov edx,es:[ebx]
    movzx eax,word ptr es:[ebx+4]
;
    push ds
    push es
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateGlobalMem
    mov bx,es
    push edx
    GetSelectorBaseSize
    mov ax,process_page_sel
    mov ds,ax
    mov edi,edx
    pop edx
    shr edi,10
    shr ecx,12
    or dl,3

init_v86_memmap_loop:
    mov ds:[edi],edx
    add edi,4
    add edx,1000h
    sub ecx,1
    jnz init_v86_memmap_loop
;
    pop es
    pop ds
    mov ds:v_pm32_io,bx
    jmp init_v86_pm32

init_v86_memory_done:
    mov ds:v_pm32_io,0

init_v86_pm32:
    mov ds:v_set_window_proc,OFFSET SetWindowPm32
    mov ds:v_set_start_proc,OFFSET SetStartPm32
    mov ds:v_set_palette_proc,OFFSET SetPalettePm32
    call GetVideoModesV86
    jmp init_v86_check_done

init_v86_calls:
    mov ds:v_set_window_proc,OFFSET SetWindowV86
    mov ds:v_set_start_proc,OFFSET SetStartV86
    mov ds:v_set_palette_proc,OFFSET SetPaletteV86
    call GetVideoModesV86
;
    mov bx,es
    GetSelectorBaseSize
    add edx,1000h
    sub ecx,1000h
    mov ax,process_page_sel
    mov ds,ax
    mov edi,edx
    shr edi,10
    shr ecx,12
    mov edx,2

init_v86_free_loop:
    mov ds:[edi],edx
    add edi,4
    sub ecx,1
    jnz init_v86_free_loop
;
    FreeMem
    jmp init_v86_check_done

init_v86_check_failed:
    mov ds:v_major_ver,0
    mov ds:v_minor_ver,0
    FreeMem

init_v86_check_done:
    popad
    pop es
    pop ds
    ret
InitV86 Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetupPmEntry
;
;           DESCRIPTION:    Setup Pm entry point
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pm_id   DB 'PMID'

SetupPmEntry    Proc near
    push ds
    push es
    pushad
;
    mov bx,__C000
    mov ds,bx
    mov eax,10000h
    AllocateGlobalMem
    xor si,si
    xor di,di
    mov cx,4000h
    rep movsd
;
    mov eax,dword ptr cs:pm_id
    xor si,si
    mov cx,8000h

ScanPmLoop:
    cmp eax,es:[si]
    jne ScanPmNext
;
    push cx
    push si
    mov cx,SIZE pm_info_block
    xor dl,dl

ChksumPmLoop:
    add dl,es:[si]
    inc si
    loop ChksumPmLoop
;
    pop si
    pop cx
    or dl,dl
    jnz ScanPmNext  
;
    push es
    mov eax,600h
    AllocateSmallGlobalMem
    xor di,di
    mov cx,180h
    xor eax,eax
    rep stosd
    mov bx,es
    pop es
;
    mov es:[si].pmi_bios_data,bx
    mov es:[si].pmi_A000,__A000
    mov es:[si].pmi_B000,__B000
    mov es:[si].pmi_B800,__B800
    mov es:[si].pmi_C000,es
    mov es:[si].pmi_mode,1
    mov bx,es
    GetSelectorBaseSize
    AllocateGdt
    CreateCodeSelector16
;
    mov ax,SEG data
    mov ds,ax
    mov word ptr ds:v_pm16_entry+2,bx
    mov ax,es:[si].pmi_entry_point
    mov word ptr ds:v_pm16_entry,ax
    mov ds:v_init_proc,OFFSET InitPm
    mov ds:v_set_window_proc,OFFSET SetWindowPm16
    mov ds:v_set_start_proc,OFFSET SetStartPm16
    mov ds:v_set_palette_proc,OFFSET SetPalettePm16
;
    mov eax,1024
    AllocateSmallGlobalMem
    mov ds:v_pm16_stack,es
;
    mov ax,es
    mov es,bx
    mov bp,ss
    shl ebp,16
    mov bp,sp
    mov ss,ax
    mov sp,1024
    push ebp
;
    stc
    push cs
    push OFFSET SetupPmInitRet
    push es
    push es:[si].pmi_init
    retf

SetupPmInitRet:
    pop ebp
    mov ax,bp
    pushf
    shr ebp,16
    popf
    mov ss,bp
    mov sp,ax
    jnc SetupPmDone
    jmp SetupVm
    
ScanPmNext:
    inc si
    sub cx,1
    jnz ScanPmLoop

SetupVm:
    FreeMem
    mov ax,SEG data
    mov ds,ax
    mov ds:v_init_proc,OFFSET InitV86

SetupPmDone:
    popad
    pop es
    pop ds
    ret
SetupPmEntry    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           VBE thread
;
;           DESCRIPTION:    Init VBE modes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vbe_thread_name DB 'VBE',0

vbe_thread:
    call SetupPmEntry
    mov ax,SEG data
    mov ds,ax
    call ds:v_init_proc
    retf


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_vbe_thread
;
;           DESCRIPTION:    Create initial VBE thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_vbe_thread PROC far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET vbe_thread
    mov di,OFFSET vbe_thread_name
    mov cx,500
    mov ax,4
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_vbe_thread ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_vbe
;
;           DESCRIPTION:    Init VBE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_vbe
            
init_vbe    PROC near
    mov ax,SEG data
    mov es,ax
    mov es:v_video_resol_list,0
    mov es:v_init_proc,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_vbe_thread
    HookInitTasking
    ret
init_vbe    Endp

code    ENDS

    END

