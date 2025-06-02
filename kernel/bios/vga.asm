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
; VGA.ASM
; VGA/VESA based video device driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
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
v_cap                   DW ?

v_init_proc             DW ?

v_set_window_proc       DW ?
v_set_start_proc        DW ?
v_set_palette_proc      DW ?

v_major_ver             DB ?
v_minor_ver             DB ?

v_pm16_stack            DW ?
v_pm16_entry            DD ?
v_pm32_io               DW ?
v_pm32_data_sel         DW ?
v_pm32_code_sel         DW ?

v_video_resol_list      DW ?

data    ENDS

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DecodeVideoMode
;
;           DESCRIPTION:    Decode a video mode
;
;           PARAMETERS:     DS          PC video sel
;                           AX          0 = V86, 1 = PM
;                           CX          Mode #
;                           ES          Video mode info block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeVideoMode Proc near
    mov dx,es:vmi_mode_attrib
    and dx,MODE_ATTRIB_REQUIRED
    cmp dx,MODE_ATTRIB_REQUIRED
    jne decode_video_mode_done
;
    mov dl,es:vmi_memory_model
    cmp dl,MODEL_DIRECT
    jne decode_video_mode_done
;
    pushad
    mov bx,cx
    movzx ax,es:vmi_bits_per_pixel
    mov cx,es:vmi_x_pixels
    mov dx,es:vmi_y_pixels
    mov si,es:vmi_scan_lines
    mov edi,es:vmi_lfb
    AddVideoMode
    popad

decode_video_mode_done:
    ret
DecodeVideoMode Endp

    
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
    push es
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateGlobalMem
    mov bx,es
;    
    push edx
    GetSelectorBaseSize
    pop eax
;
    push ebx    
    xor ebx,ebx
    shr ecx,12
    or al,0Bh

init_v86_memmap_loop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    sub ecx,1
    jnz init_v86_memmap_loop
;
    pop ebx
    pop es
;    
    mov ds:v_pm32_io,bx
    jmp init_v86_pm32

init_v86_memory_done:
    mov ds:v_pm32_io,0

init_v86_pm32:

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
    shr ecx,12
    mov eax,2
    xor ebx,ebx

init_v86_free_loop:
    SetPageEntry
    add edx,1000h
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
;           NAME:           test_thread
;
;           DESCRIPTION:    test thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vbe_thread_name DB 'VBE',0

vbe_thread:
    call InitV86
    EndGetVideoModes
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SwitchVideoMode
;
;           DESCRIPTION:    Switch video mode
;
;           PARAMETERS:     BX  New video mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_video_mode_name DB 'Switch Video Mode',0

switch_video_mode       Proc far
    push ds
    push es
    pushad
;    
    cmp bx,3
    je switch_text_mode

switch_lfb_mode:
    xor ax,ax
    mov ds,ax
    mov es,ax
    or bx,4000h
    or bx,8000h
    mov ax,4F02h
    push 10h
    V86BiosInt
    jmp switch_mode_done

switch_text_mode:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ax,3
    push 10h
    V86BiosInt

switch_mode_done:
    popad
    pop es
    pop ds
    retf32
switch_video_mode       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           NotifyApVideoMode
;
;           DESCRIPTION:    Notify video mode from AP core
;
;           PARAMETERS:     ES:EDI		Mode info
;                           AX                  Mode #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_ap_video_mode_name DB 'Notify AP Video Mode',0

notify_ap_video_mode       Proc far
    int 3
    retf32
notify_ap_video_mode       Endp

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
    mov cx,stack0_size
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
;               NAME:                   INIT
;
;               DESCRIPTION:    Init device
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                        
init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov edi,OFFSET init_vbe_thread
    HookInitAcpi
;
    mov esi,OFFSET switch_video_mode
    mov edi,OFFSET switch_video_mode_name
    xor cl,cl
    mov ax,switch_video_mode_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_ap_video_mode
    mov edi,OFFSET notify_ap_video_mode_name
    xor cl,cl
    mov ax,notify_ap_video_mode_nr
    RegisterOsGate
;    
    BeginGetVideoModes
    clc
    ret
init    ENDP

code    ENDS

    END init

