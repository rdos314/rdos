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
; BUR2BIN.ASM
; Convert rdosbur.exe to a binary file (rdosbur.bin)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  bur2bin

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

exeh_seg	STRUC
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

.data

hdr	exeh_seg <>
file_size	DW ?
buf			DB 2000h DUP(?)

.code

sdram_exe_error   DB 'cannot find sdram.exe file',0Dh,0Ah,24h
sdram_bin_error   DB 'cannot create sdram.bin file',0Dh,0Ah,24h
flash_exe_error   DB 'cannot find flash.exe file',0Dh,0Ah,24h
flash_bin_error   DB 'cannot create flash.bin file',0Dh,0Ah,24h

crlf        DB 0Dh,0Ah,24h

.386c

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
;		NAME:			InitSdram
;
;		DESCRIPTION:	Create bin file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sdram_exe_name	DB 'sdram.exe', 0
sdram_bin_name	DB 'sdram.bin', 0
flash_exe_name	DB 'flash.exe', 0
flash_bin_name	DB 'flash.bin', 0

Init:
	mov ax,cs
	mov ds,ax
	mov dx,OFFSET sdram_exe_name
	mov ax,3D00h
	int 21h
    jnc SdramOpenOk
;
    mov dx,OFFSET sdram_exe_error
    call Log
    jmp Done

SdramOpenOk:
	mov bx,ax
    mov ax,SEG @data
    mov ds,ax
;
	mov dx,OFFSET hdr
	mov cx,SIZE exeh_seg
	mov ah,3Fh
	int 21h
;
	push bx
	xor eax,eax
	xor ebx,ebx
	mov ax,hdr.exeh_size_msb
	shl eax,5
	mov bx,hdr.exeh_size_lsb
	shr bx,4
	inc bx
	add eax,ebx
	mov bx,hdr.exeh_size_header
	mov dx,bx
	shl dx,4
	sub eax,ebx
	add ax,hdr.exeh_minalloc
	pop bx
	push ax
	xor cx,cx
	mov ax,4200h
	int 21h
	pop cx
	shl cx,4
	cmp cx,2000h
	jc SdramSizeOk
;
	mov cx,2000h

SdramSizeOk:
	mov file_size,cx
	mov dx,OFFSET buf
	mov ah,3Fh
	int 21h
;
	mov ah,3Eh
	int 21h
;
	mov ax,cs
	mov ds,ax
	mov dx,OFFSET sdram_bin_name
	xor cx,cx
	mov ah,3Ch
	int 21h
    jnc SdramCreateOk
;
    mov dx,OFFSET sdram_bin_error
    call Log
    jmp Done

SdramCreateOk:
	mov bx,ax
	mov ax,SEG @data
	mov ds,ax
	mov dx,OFFSET buf
	mov cx,file_size
	mov ah,40h
	int 21h
;
	mov ah,3Eh
	int 21h

InitFlash:
	mov ax,cs
	mov ds,ax
	mov dx,OFFSET flash_exe_name
	mov ax,3D00h
	int 21h
    jnc FlashOpenOk
;
    mov dx,OFFSET flash_exe_error
    call Log
    jmp Done

FlashOpenOk:
	mov bx,ax
    mov ax,SEG @data
    mov ds,ax
;
	mov dx,OFFSET hdr
	mov cx,SIZE exeh_seg
	mov ah,3Fh
	int 21h
;
	push bx
	xor eax,eax
	xor ebx,ebx
	mov ax,hdr.exeh_size_msb
	shl eax,5
	mov bx,hdr.exeh_size_lsb
	shr bx,4
	inc bx
	add eax,ebx
	mov bx,hdr.exeh_size_header
	mov dx,bx
	shl dx,4
	sub eax,ebx
	add ax,hdr.exeh_minalloc
	pop bx
	push ax
	xor cx,cx
	mov ax,4200h
	int 21h
	pop cx
	shl cx,4
	cmp cx,2000h
	jc FlashSizeOk
;
	mov cx,2000h

FlashSizeOk:
	mov file_size,cx
	mov dx,OFFSET buf
	mov ah,3Fh
	int 21h
;
	mov ah,3Eh
	int 21h
;
	mov ax,cs
	mov ds,ax
	mov dx,OFFSET flash_bin_name
	xor cx,cx
	mov ah,3Ch
	int 21h
    jnc FlashCreateOk
;
    mov dx,OFFSET flash_bin_error
    call Log
    jmp Done

FlashCreateOk:
	mov bx,ax
	mov ax,SEG @data
	mov ds,ax
	mov dx,OFFSET buf
	mov cx,file_size
	mov ah,40h
	int 21h
;
	mov ah,3Eh
	int 21h

Done:
	mov ax,4C00h
	int 21h

    END Init

