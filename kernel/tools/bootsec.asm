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
; BOOTSEC.ASM
; Bootsector for disk / diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  bootsec

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

boot_struc	STRUC

boot_bytes_per_sector		DW 512
boot_default_entry			DB 0
boot_mapping_sectors		DW 1
boot_resv3					DB ?
boot_resv4					DW ?
boot_small_sectors			DW 2884
boot_media					DB ?
boot_resv6					DW ?
boot_sectors_per_cyl		DW 15
boot_heads					DW 2
boot_hidden_sectors			DD 16
boot_sectors				DD 2884
boot_drive_nr				DB 80h,0
boot_signature				DB ?
boot_serial					DD ?
boot_volume					DB 11 DUP(?)
boot_fs						DB 8 DUP(?)

boot_struc		ENDS

.code

	.386c

	public BootSectInit

BootSectInit:
	jmp StartBoot
	nop

	db 'Rdos    '

BootMedia	boot_struc	<>

StartBoot:
	db 0EAh
	dw OFFSET JmpBootCode
	dw 07C0h
JmpBootCode:
	cli
	mov bx,5000h
	mov ss,bx
	mov sp,100h
	sti
	mov bx,7000h
	mov es,bx
	xor bx,bx
	mov ecx,cs:BootMedia.boot_hidden_sectors
	xor dx,dx
	mov ax,1
LoadBootNext:
	push cx
	mov cx,3
LoadBootRetry:
	call ReadSector
	jnc BootSectorOk
	push ax
	mov ax,0
	int 13h
	pop ax
	loop LoadBootRetry	
	stc
BootSectorOk:
	pop cx
	jc BootFail
	add ax,1
	adc dx,0
	add bx,512
	loop LoadBootNext
;
    mov dl,cs:BootMedia.boot_drive_nr
	mov ax,cs
	mov es,ax
    mov al,cs:BootMedia.boot_default_entry
    
	db 0EAh

	public BootLoadOffset

BootLoadOffset:

	dw 0
	dw 7000h

BootFail:
	mov si,OFFSET DiskError
	call WriteAsciiz
BootStop:
	jmp BootStop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteAsciiz
;
;		DESCRIPTION:	Write a message
;
;		PARAMETERS:		CS:SI	Message to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteAsciiz	Proc near
	lods byte ptr cs:[si]
	or al,al
	jz WriteAsciizDone
	mov ah,0Eh
	mov bx,7
	int 10h
	jmp WriteAsciiz
WriteAsciizDone:
	ret
WriteAsciiz	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadSector
;
;		DESCRIPTION:	Read a sector
;
;		PARAMETERS:		DX:AX	Sector #
;						ES:BX	Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector	Proc near
	push ax
	push cx
	push dx
	push bx
	div cs:BootMedia.boot_sectors_per_cyl
	inc dl
	mov bl,dl
	xor dx,dx
	div cs:BootMedia.boot_heads
	mov bh,dl
	mov dx,ax
	mov ax,201h
	mov cl,6
	shl dh,cl
	or dh,bl
	mov cx,dx
	xchg ch,cl
	mov dl,cs:BootMedia.boot_drive_nr
	mov dh,bh
	pop bx
	int 13h
	pop dx
	pop cx
	pop ax
	ret
ReadSector	Endp

DiskError:
		db 'Diskette error',0Dh,0Ah,0

	END
