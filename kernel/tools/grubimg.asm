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
; GRUBIMG.ASM
; GRUB faked kernel image creator for RDOS. Creates grubload.bin from 
; grubload.exe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  grubimg

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

multiboot_struc	STRUC

mb_magic			DD ?
mb_flags			DD ?
mb_checksum			DD ?			; calculated by grubimg
mb_header_addr		DD ?
mb_load_addr		DD ?			; calculated by grubimg
mb_load_end_addr	DD ?			; calculated by grubimg
mb_bss_end_addr		DD ?			; calculated by grubimg
mb_entry_addr		DD ?			; calculated by grubimg

multiboot_struc		ENDS

.stack

.data

InitIp			DW ?
BinSize			DW ?
Buf				DB 8000h DUP(?)

.code

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
;		NAME:			init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exe_name	DB 'grubload.exe',0
bin_name	DB 'grubload.bin',0
exe_error DB 'cannot find grubload.exe ', 0Dh, 0Ah, 24h
bin_error DB 'cannot create grubload.bin ', 0Dh, 0Ah, 24h

init:
	mov ax,SEG @data
	mov ds,ax
	push ds
	mov ax,cs
	mov ds,ax
	mov dx,OFFSET exe_name
	mov ax,3D00h
	int 21h
	pop ds
    jnc load_ok
;
    mov dx,OFFSET exe_error
    call Log
    jmp init_done

load_ok:
	mov bx,ax
	xor dx,dx
	mov cx,1Ch
	mov ah,3Fh
	int 21h
	push bx
    mov ax,ds:exeh_ip
	mov ds:InitIp,ax
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
	mov ds:BinSize,ax
    movzx ecx,ax
	mov edx,ds:Buf.mb_header_addr
	mov ds:Buf.mb_load_addr,edx
	add ecx,edx
	mov ds:Buf.mb_load_end_addr,ecx
	mov ds:Buf.mb_bss_end_addr,ecx
	movzx ecx,ds:InitIp
	add ecx,edx
	mov ds:Buf.mb_entry_addr,ecx
;
	mov ah,3Eh
	int 21h
;
	mov eax,Buf.mb_magic
	add eax,Buf.mb_flags
	neg eax
	mov ds:Buf.mb_checksum,eax
;
	push ds
	mov ax,cs
	mov ds,ax
	mov dx,OFFSET bin_name
	xor cx,cx
	mov ah,3Ch
	int 21h
	pop ds
    jnc create_ok
;
    mov dx,OFFSET bin_error
    call Log
    jmp init_done

create_ok:
	mov bx,ax
	mov cx,ds:BinSize
    mov dx,OFFSET Buf
    mov ah,40h
    int 21h
;
	mov ah,3Eh
	int 21h

init_done:
	mov ax,4C00h
	int 21h

	END init
