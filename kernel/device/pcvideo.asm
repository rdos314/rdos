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
; PCVIDEO.ASM
; PC based video device driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME pcvideo

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\driver.def
INCLUDE ..\os\user.def
INCLUDE ..\os\virt.def
INCLUDE ..\os\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\user.inc
INCLUDE ..\os\virt.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\video.inc
INCLUDE pcvideo.inc

pm_info_block	STRUC

pmi_signature	DB 4 DUP(?)
pmi_entry_point	DW ?
pmi_init		DW ?
pmi_bios_data	DW ?
pmi_A000		DW ?
pmi_B000		DW ?
pmi_B800		DW ?
pmi_C000		DW ?
pmi_mode		DB ?
pmi_chksum		DB ?

pm_info_block	ENDS

vesa_info_struc	STRUC

vesa_name		DB 4 DUP(?)
vesa_minor_ver	DB ?
vesa_major_ver	DB ?
vesa_oem_ptr	DD ?
vesa_cap		DD ?
vesa_modes		DD ?
vesa_video_mem	DW ?

vesa_info_struc	ENDS

vesa_pm_struc	STRUC

vpm_set_window		DW ?
vpm_set_disp_start	DW ?
vpm_set_palette		DW ?
vpm_table			DW ?

vesa_pm_struc	ENDS

MODE_ATTRIB_SUPORTED	EQU 1
MODE_ATTRIB_TTY			EQU 4
MODE_ATTRIB_COLOR		EQU 8
MODE_ATTRIB_GRAPHICS	EQU 10h
MODE_ATTRIB_NON_VGA		EQU 20h
MODE_ATTRIB_NO_WINDOW	EQU 40h
MODE_ATTRIB_LFB			EQU 80h
MODE_ATTRIB_DOUBLE_SCAN	EQU 100h
MODE_ATTRIB_INTERLACED	EQU 200h
MODE_ATTRIB_TRIPPLE_BUF	EQU 400h
MODE_ATTRIB_STEREO		EQU 800h
MODE_ATTRIB_DUAL_START	EQU 1000h

MODE_ATTRIB_REQUIRED	EQU 99h

WIN_ATTRIB_RELOC		EQU 1
WIN_ATTRIB_READ			EQU 2
WIN_ATTRIB_WRITE		EQU 4

MODEL_TEXT				EQU 0
MODEL_CGA				EQU 1
MODEL_HERC				EQU 2
MODEL_PLANAR			EQU 3
MODEL_PACKED			EQU 4
MODEL_256				EQU 5
MODEL_DIRECT			EQU 6
MODEL_YUV				EQU 7

vesa_mode_info	STRUC

vmi_mode_attrib		DW ?
vmi_wina_attrib		DB ?
vmi_winb_attrib		DB ?
vmi_granularity		DW ?
vmi_size			DW ?
vmi_wina_seg		DW ?
vmi_winb_seg		DW ?
vmi_win_func		DD ?
vmi_scan_lines		DW ?
vmi_x_pixels		DW ?
vmi_y_pixels		DW ?
vmi_x_chars			DB ?
vmi_y_chars			DB ?
vmi_planes			DB ?
vmi_bits_per_pixel	DB ?
vmi_banks			DB ?
vmi_memory_model	DB ?
vmi_bank_size		DB ?
vmi_pages			DB ?
vmi_resv1			DB ?
vmi_red_mask_size	DB ?
vmi_red_position	DB ?
vmi_green_mask_size	DB ?
vmi_green_position	DB ?
vmi_blue_mask_size	DB ?
vmi_blue_position	DB ?
vmi_rsvd_mask_size	DB ?
vmi_rsvd_position	DB ?
vmi_dir_color_mode	DB ?
vmi_lfb				DD ?

vesa_mode_info	ENDS

	extrn init_text_mode:near
	extrn init_bit_mode:near

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FindResolution
;
;		DESCRIPTION:	Find a resolution
;
;		PARAMETERS:		DS		PC video sel
;						CX		x-resolution
;						DX		y-resolution
;
;		RETURNS:		NC		OK
;						ES		Resolution selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindResolution	Proc near
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
FindResolution	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddResolution
;
;		DESCRIPTION:	Add a resolution
;
;		PARAMETERS:		DS		PC video sel
;						CX		x-resolution
;						DX		y-resolution
;
;		RETURNS:		ES		Resolution selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddResolution	Proc near
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
AddResolution	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddVideoMode
;
;		DESCRIPTION:	Add a video mode
;
;		PARAMETERS:		DS		PC video sel
;						AX		0 = V86, 1 = PM
;						CX		Mode #
;						ES		Video mode info block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddVideo	MACRO mode
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
	or es:vr_&mode&_flags, VIDEO_MODE_FLAGS_PM OR VIDEO_MODE_FLAGS_LFB
	jmp add_video_done

add_v86:
	or ax,ax
	jnz add_do
;
	test dl,VIDEO_MODE_FLAGS_LFB
	jz add_do	
	jmp add_video_done
		ENDM

AddVideoMode	Proc near
	push es
	push fs
;
	int 3
	mov dx,es
	mov fs,dx
	push ax
	push cx
	mov cx,fs:vmi_x_pixels
	mov dx,fs:vmi_y_pixels
	call FindResolution
	jnc add_video_found
;
	call AddResolution

add_video_found:
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
AddVideoMode	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DecodeVideoMode
;
;		DESCRIPTION:	Decode a video mode
;
;		PARAMETERS:		DS		PC video sel
;						AX		0 = V86, 1 = PM
;						CX		Mode #
;						ES		Video mode info block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeVideoMode	Proc near
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
DecodeVideoMode	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetVideoModesPm
;
;		DESCRIPTION:	Get all video modes, protected mode version
;
;		PARAMETERS:		ES		Info selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetVideoModesPm	Proc near
	push ds
	push es
	push fs
	pusha
;
	mov ax,pc_video_data_sel
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
	mov bp,sp
	mov ss,ax
	mov sp,1024
	push bp
	mov ax,4F01h
	call ds:v_pm16_entry
	pop bp
	cmp ax,4Fh
	mov ax,thread_ss0_sel
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
;	FreeMem
;
	popa
	pop fs
	pop es
	pop ds
	ret
GetVideoModesPm	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetVideoModesV86
;
;		DESCRIPTION:	Get all video modes, V86 mode version
;
;		PARAMETERS:		ES		Info selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetVideoModesV86	Proc near
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
	mov ax,pc_video_data_sel
	mov ds,ax
	xor ax,ax
	call DecodeVideoMode
	jmp get_video_modes_v86_loop

get_video_modes_v86_free:
;	FreeMem

get_video_modes_v86_done:
	popa
	pop fs
	pop es
	pop ds
	ret
GetVideoModesV86	Endp

vesa_id	DB 'VESA'

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetWindowV86
;
;		DESCRIPTION:	V86 SetWindow
;
;		PARAMETERS:		BL		Window A/B
;						DX		Window #
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWindowV86	Proc near
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
SetWindowV86	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetStartV86
;
;		DESCRIPTION:	V86 SetStart
;
;		PARAMETERS:		CX		First pixel
;						DX		First line		
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetStartV86	Proc near
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
SetStartV86	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetPaletteV86
;
;		DESCRIPTION:	V86 SetPalette
;
;		PARAMETERS:		CX		Palette entries
;						DX		First entry
;						ES:DI	Palette data
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPaletteV86	Proc near
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
SetPaletteV86	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetWindowPm16
;
;		DESCRIPTION:	16-bit protected mode SetWindow
;
;		PARAMETERS:		BL		Window A/B
;						DX		Window #
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWindowPm16	Proc near
	push ds
	push bp
;
	xor bh,bh
	mov ax,pc_video_data_sel
	mov ds,ax
	mov ax,ds:v_pm16_stack
	mov bp,sp
	mov ss,ax
	mov sp,1024
	push bp
	mov ax,4F05h
	call ds:v_pm16_entry
	pop bp
	mov si,thread_ss0_sel
	mov ss,si
	mov sp,bp
;
	pop bp
	pop si
	pop ds
	ret
SetWindowPm16	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SeStartPm16
;
;		DESCRIPTION:	16-bit protected mode SetStart
;
;		PARAMETERS:		CX		First pixel
;						DX		First line		
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetStartPm16	Proc near
	push ds
	push bp
;
	xor bx,bx
	mov ax,pc_video_data_sel
	mov ds,ax
	mov ax,ds:v_pm16_stack
	mov bp,sp
	mov ss,ax
	mov sp,1024
	push bp
	mov ax,4F07h
	call ds:v_pm16_entry
	pop bp
	mov si,thread_ss0_sel
	mov ss,si
	mov sp,bp
;
	pop bp
	pop si
	pop ds
	ret
SetStartPm16	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetPalettePm16
;
;		DESCRIPTION:	16-bit protected mode SetPalette
;
;		PARAMETERS:		CX		Palette entries
;						DX		First entry
;						ES:DI	Palette data
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPalettePm16	Proc near
	push ds
	push bp
;
	mov ax,pc_video_data_sel
	mov ds,ax
	mov ax,ds:v_pm16_stack
	mov bp,sp
	mov ss,ax
	mov sp,1024
	push bp
	mov ax,4F09h
	call ds:v_pm16_entry
	pop bp
	mov si,thread_ss0_sel
	mov ss,si
	mov sp,bp
;
	pop bp
	pop si
	pop ds
	ret
SetPalettePm16	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetWindowPm32
;
;		DESCRIPTION:	32-bit protected mode SetWindow
;
;		PARAMETERS:		BL		Window A/B
;						DX		Window #
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWindowPm32	Proc near
	push ds
	push es
	push gs
	push si
;
	xor bh,bh
	mov ax,pc_video_data_sel
	mov gs,ax
	mov ax,gs:v_pm32_data_sel
	mov ds,ax
	mov es,gs:v_pm32_io
	mov bp,sp
	mov ss,ax
	mov sp,1000h
	push bp
	sub sp,8
	mov bp,sp
	mov dword ptr [bp],100h
	mov ax,gs:v_pm32_code_sel
	mov [bp+4],ax
	mov ax,4F05h
	call fword ptr [bp]
	add sp,8
	pop bp
;
	mov si,thread_ss0_sel
	mov ss,si
	mov sp,bp
;
	pop si
	pop gs
	pop es
	pop ds
	ret
SetWindowPm32	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetStartPm32
;
;		DESCRIPTION:	32-bit protected mode SetStart
;
;		PARAMETERS:		CX		First pixel
;						DX		First line		
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetStartPm32	Proc near
	push ds
	push es
	push gs
	push si
;
	xor bx,bx
	mov ax,pc_video_data_sel
	mov gs,ax
	mov ax,gs:v_pm32_data_sel
	mov ds,ax
	mov es,gs:v_pm32_io
	mov bp,sp
	mov ss,ax
	mov sp,1000h
	push bp
	sub sp,8
	mov bp,sp
	mov dword ptr [bp],108h
	mov ax,gs:v_pm32_code_sel
	mov [bp+4],ax
	mov ax,4F05h
	call fword ptr [bp]
	add sp,8
	pop bp
;
	mov si,thread_ss0_sel
	mov ss,si
	mov sp,bp
;
	pop si
	pop gs
	pop es
	pop ds
	ret
SetStartPm32	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetPalettePm32
;
;		DESCRIPTION:	32-bit protected mode SetPalette
;
;		PARAMETERS:		CX		Palette entries
;						DX		First entry
;						ES:DI	Palette data
;
;		RETURNS:		AX		Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPalettePm32	Proc near
	push ds
	push es
	push gs
	push si
;
	xor bh,bh
	mov ax,pc_video_data_sel
	mov gs,ax
	mov ds,gs:v_pm32_io
	mov ax,gs:v_pm32_data_sel
	mov bp,sp
	mov ss,ax
	mov sp,1000h
	push bp
	sub sp,8
	mov bp,sp
	mov dword ptr [bp],110h
	mov ax,gs:v_pm32_code_sel
	mov [bp+4],ax
	mov ax,4F05h
	call fword ptr [bp]
	add sp,8
	pop bp
;
	mov si,thread_ss0_sel
	mov ss,si
	mov sp,bp
;
	pop si
	pop gs
	pop es
	pop ds
	ret
SetPalettePm32	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitPm
;
;		DESCRIPTION:	Protected mode init
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPm	Proc near
	push ds
	push es
	pushad
;
	mov ax,pc_video_data_sel
	mov ds,ax
	mov eax,10000h
	AllocateGlobalMem
	xor di,di
;
	mov ax,ds:v_pm16_stack
	mov bp,sp
	mov ss,ax
	mov sp,1024
	push bp
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
	pop bp
	mov ax,thread_ss0_sel
	mov ss,ax
	mov sp,bp
	call GetVideoModesPm
	jmp init_pm_free

init_pm_leave:
	pop bp
	mov ax,thread_ss0_sel
	mov ss,ax
	mov sp,bp

init_pm_free:
;	FreeMem
;
	popad
	pop es
	pop ds
	ret
InitPm	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitV86
;
;		DESCRIPTION:	V86 mode init
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitV86	Proc near
	push ds
	push es
	pushad
;
	mov ax,pc_video_data_sel
	mov ds,ax
	mov eax,11000h
	AllocateGlobalMem
	xor di,di
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
;	jc init_v86_calls
;
	mov bx,es
	GetSelectorBaseSize
	add edx,1000h
	sub ecx,1000h
	CreateDataSelector16
	mov es,bx
;
	mov ax,4F0Ah
	xor bl,bl
	push 10h
	V86BiosInt
	int 3
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
	xor edx,edx

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
InitV86	Endp

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetupPmEntry
;
;		DESCRIPTION:	Setup Pm entry point
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pm_id	DB 'PMID'

SetupPmEntry	Proc near
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
	mov ax,pc_video_data_sel
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
	mov bp,sp
	mov ss,ax
	mov sp,1024
	push bp
;
	push cs
	push OFFSET SetupPmInitRet
	push es
	push es:[si].pmi_init
	retf

SetupPmInitRet:
	pop bp
	mov ax,thread_ss0_sel
	mov ss,ax
	mov sp,bp
	jmp SetupPmDone

ScanPmNext:
	inc si
	sub cx,1
	jnz ScanPmLoop
;
	FreeMem
	mov ax,pc_video_data_sel
	mov ds,ax
	mov ds:v_init_proc,OFFSET InitV86

SetupPmDone:
	popad
	pop es
	pop ds
	ret
SetupPmEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			test_thread
;
;		DESCRIPTION:	Test thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
test_thread_name	DB 'VESA Test',0

test_thread	Proc far
	mov ax,pc_video_data_sel
	mov ds,ax
	call SetupPmEntry
	call ds:v_init_proc
;
	xor bx,bx
	xor dx,dx
	call ds:v_set_window_proc
	ret
test_thread	Endp
		
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_sys
;
;		DESCRIPTION:	Init tasking
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
init_sys	PROC far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET test_thread
	mov di,OFFSET test_thread_name
	mov ax,4
	mov cx,1024
	CreateThread
;
	popa
	pop es
	pop ds

	ret
init_sys	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_focus
;
;		DESCRIPTION:	Init focus
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
init_focus	PROC far
	push ax
	mov ax,3
	SetVideoMode
	pop ax
	ret
init_focus	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
init	PROC far
	push ds
	pusha
;
	mov bx,pc_video_code_sel
	InitDevice
;
	mov eax,SIZE video_data_seg
	mov bx,pc_video_data_sel
	AllocateFixedSystemMem
	mov es:v_curr_object,0
	mov es:v_video_resol_list,0
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_focus
	HookEnableFocus
;
	mov di,OFFSET init_sys
	HookInitTasking
;
	call init_text_mode
	call init_bit_mode
;
	popa
	pop ds
	ret
init	ENDP

code	ENDS

	END init

