;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; CFG2BIN.ASM
; Binary file creator for RDOS. Uses a .CFG file for settings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  CFG2BIN

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

ConfigSize = 2000h

GateSize = 16

INCLUDE ..\os.def
INCLUDE ..\os\system.def

exeh_seg	SEGMENT AT 0
exeh_signature		DW ?
exeh_size_lsb		DW ?
exeh_size_msb		DW ?
exeh_reloc_ant		DW ?
exeh_size_header	DW ?
exeh_minalloc		DW ?
exeh_maxalloc		DW ?
exeh_ss				DW ?
exeh_sp				DW ?
exeh_checksum		DW ?
exeh_ip				DW ?
exeh_cs				DW ?
exeh_reloc_offs		DW ?
exeh_ov_nr			DW ?
exeh_seg	ENDS

.stack

.fardata Buffer

buf         DB 0FFF0h DUP(0)

.code

boot1_exe_name  DB 'bootsec.exe',0
boot1_bin_name  DB 'bootsec.bin',0
boot1_exe_err   DB 'cannot find bootsec.exe',0Dh, 0Ah, 24h
boot1_bin_err   DB 'cannot create bootsec.bin',0Dh, 0Ah, 24h

boot2_exe_name  DB 'hdboot.exe',0
boot2_bin_name  DB 'hdboot.bin',0
boot2_exe_err   DB 'cannot find hdboot.exe',24h
boot2_bin_err   DB 'cannot create hdboot.bin',24h

.386c

exe_handle  DW ?
bin_handle  DW ?

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Log
;
;		DESCRIPTION:	Log error
;
;       PARAMETERS:     DX      offset to error message
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Log Proc near
    push ds
    pushf
    push ax
    mov ax,cs
    mov ds,ax
    mov ah,9
	int 21h
    pop ax
    popf
    pop ds
    ret
Log Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ConvBoot1
;
;		DESCRIPTION:	Convert bootsector
;
;		PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvBoot1	PROC near
	push ds
	push es
	push si
	push di
;
    mov ax,cs
    mov ds,ax
	mov dx,OFFSET boot1_exe_name
	mov ax,3D00h
	int 21h
    jnc conv_boot1_exe_ok
;    
    mov dx,OFFSET boot1_exe_err
    call Log
    jmp conv_boot1_done
    
conv_boot1_exe_ok:
    mov cs:exe_handle,ax
;    
	mov dx,OFFSET boot1_bin_name
	xor cx,cx
	mov ah,3Ch
	int 21h
    jnc conv_boot1_bin_ok
;    
    mov dx,OFFSET boot1_bin_err
    call Log
    jmp conv_boot1_done

conv_boot1_bin_ok:
    mov cs:bin_handle,ax
;
	mov bx,cs:exe_handle
	mov ax,SEG Buffer
	mov ds,ax
	xor dx,dx
	mov cx,1Ch
	mov ah,3Fh
	int 21h
	push bx
    mov bx,OFFSET buf
	xor eax,eax
	xor ebx,ebx
	mov ax,ds:exeh_size_msb
	shl eax,5
	mov bx,ds:exeh_size_lsb
	shr bx,4
	inc bx
	add eax,ebx
	mov bx,ds:exeh_size_header
	mov dx,bx
	shl dx,4
	sub eax,ebx
	add ax,ds:exeh_minalloc
	pop bx
	push ax
	xor cx,cx
	mov ax,4200h
	int 21h
	pop cx
	shl cx,4
	mov dx,OFFSET buf
	mov ah,3Fh
	int 21h
    movzx ecx,ax
	mov ah,3Eh
	int 21h
;
    mov bx,cs:bin_handle
    mov dx,OFFSET buf
    mov ah,40h
    int 21h
;    
	mov ah,3Eh
	int 21h
    
conv_boot1_done:
	pop di
	pop si
	pop es
	pop ds
	ret
ConvBoot1	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ConvBoot2
;
;		DESCRIPTION:	Convert second stage loader
;
;		PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvBoot2	PROC near
	push ds
	push es
	push si
	push di
;
    mov ax,cs
    mov ds,ax
	mov dx,OFFSET boot2_exe_name
	mov ax,3D00h
	int 21h
    jnc conv_boot2_exe_ok
;    
    mov dx,OFFSET boot2_exe_err
    call Log
    jmp conv_boot2_done
    
conv_boot2_exe_ok:
    mov cs:exe_handle,ax
;    
	mov dx,OFFSET boot2_bin_name
	xor cx,cx
	mov ah,3Ch
	int 21h
    jnc conv_boot2_bin_ok
;    
    mov dx,OFFSET boot2_bin_err
    call Log
    jmp conv_boot2_done

conv_boot2_bin_ok:
    mov cs:bin_handle,ax
;
	mov bx,cs:exe_handle
	mov ax,SEG Buffer
	mov ds,ax
	xor dx,dx
	mov cx,1Ch
	mov ah,3Fh
	int 21h
	push bx
    mov bx,OFFSET buf
	xor eax,eax
	xor ebx,ebx
	mov ax,ds:exeh_size_msb
	shl eax,5
	mov bx,ds:exeh_size_lsb
	shr bx,4
	inc bx
	add eax,ebx
	mov bx,ds:exeh_size_header
	mov dx,bx
	shl dx,4
	sub eax,ebx
	add ax,ds:exeh_minalloc
	pop bx
	push ax
	xor cx,cx
	mov ax,4200h
	int 21h
	pop cx
	shl cx,4
	mov dx,OFFSET buf
	mov ah,3Fh
	int 21h
    movzx ecx,ax
	mov ah,3Eh
	int 21h
;
    mov bx,cs:bin_handle
    mov dx,OFFSET buf
    mov ah,40h
    int 21h
;
	mov ah,3Eh
	int 21h
    
conv_boot2_done:
	pop di
	pop si
	pop es
	pop ds
	ret
ConvBoot2	ENDP

init:
    mov ax,_data
    mov ds,ax
    mov ax,SEG Buffer
    mov es,ax
;
    call ConvBoot1
    call ConvBoot2    
	mov ax,4C00h
	int 21h

    END init

