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

	extrn init_text_mode:near
	extrn init_bit_mode:near

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

vesa_id	DB 'VESA'

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

init_pm_leave:
	pop bp
	mov ax,thread_ss0_sel
	mov ss,ax
	mov sp,bp
;
	FreeMem
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
	mov eax,10000h
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
	mov ax,4F0Ah
	xor bl,bl
	push 10h
	V86BiosInt
	cmp ax,4Fh
	jne init_v86_calls
;
	mov bx,es:[di].vpm_table

init_v86_io_loop:
	mov ax,[bx]
	add bx,2
	cmp ax,-1
	jne init_v86_io_loop
;
	mov ax,[bx]
	cmp ax,-1
	je init_v86_memory_done
;
	mov edx,[bx]
	movzx ecx,word ptr [bx+4]

init_v86_memory_done:

init_v86_calls:
	jmp init_v86_check_done

init_v86_check_failed:
	mov ds:v_major_ver,0
	mov ds:v_minor_ver,0

init_v86_check_done:
	FreeMem
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
	int 3
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
	int 3
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
	mov word ptr ds:v_pm16_entry+2,es
	mov ax,es:[si].pmi_entry_point
	mov word ptr ds:v_pm16_entry,ax
	mov ds:v_init_proc,OFFSET InitPm
;
	mov eax,1024
	AllocateSmallGlobalMem
	mov ds:v_pm16_stack,es
;
	mov ax,es
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
	int 3
	mov ax,pc_video_data_sel
	mov ds,ax
	call SetupPmEntry
	call ds:v_init_proc
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

