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
; ACRBOOT.ASM
; Acrosser AR-B1320 flash disk creator for RDOS & RDFS. Uses a .CFG file for settings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  acrboot

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

boot_struc	STRUC

boot_jmp					DB ?,?,?
boot_name					DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_resv1					DB ?
boot_mapping_sectors		DW ?
boot_resv3					DB ?
boot_resv4					DW ?
boot_small_sectors			DW ?
boot_media					DB ?
boot_resv6					DW ?
boot_sectors_per_cyl		DW ?
boot_heads					DW ?
boot_hidden_sectors			DD ?
boot_sectors				DD ?
boot_drive_nr				DB ?,?
boot_signature				DB ?
boot_serial					DD ?
boot_volume					DB 11 DUP(?)
boot_fs						DB 8 DUP(?)

boot_struc		ENDS

.stack

.data

CurrentSector	DW ?
BinHandle		DW ?

BootBuf		DB 512 DUP(?)

BootSector	DB 512 Dup(0)

Buf			DB 1000h DUP(?)

.code

.386c

	extrn BootSectInit:near
	extrn BootLoadOffset:near
	extrn BootLoadInit:near

FormatStart:

read_boot_error	DB 'cannot read bootsector',0Dh,0Ah,24h
write_boot_error	DB 'cannot write bootsector',0Dh,0Ah,24h
write_sector_error	DB 'cannot write sector',0Dh,0Ah,24h
exe_error   DB 'cannot find bootsec.exe',0Dh,0Ah,24h
rdosload_error	DB 'cannot find rdosload.exe',0Dh,0Ah,24h
rdossys_error	DB 'cannot create a:\rdos.sys',0Dh,0Ah,24h
rdosbin_error	DB 'cannot create a:\rdos.bin',0Dh,0Ah,24h
bin_error   DB 'cannot find .bin file',0Dh,0Ah,24h

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
;		NAME:			WriteSector
;
;		DESCRIPTION:	Write sector to disc
;
;		PARAMETERS:		DX		Sector #
;						ES:BX	Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSector	Proc near
	push cx
;
	mov cx,3
write_sector_loop:
	push ax
	push cx
	push dx
;
	mov ax,dx
	xor dx,dx
	div BootSector.boot_sectors_per_cyl
	inc dl
	mov cl,dl
	xor dx,dx
	div BootSector.boot_heads
	mov dh,dl
	mov ch,al
	mov dl,0
	mov ax,0301h
	int 13h
	pop dx
	pop cx
	pop ax
	jnc write_sector_done
	push ax
	push dx
	mov ax,0
	mov dl,0
	int 13h
	pop dx
	pop ax
	loop write_sector_loop
write_sector_done:
	pop cx
	ret
WriteSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitBootRecord
;
;		DESCRIPTION:	Init bootrecord buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rdfs_name	DB 'RDFS', 0, 0Eh, 0ACh, 0

InitBootRecord	Proc near
	mov edx,400h
	mov BootSector.boot_bytes_per_sector,200h
	mov BootSector.boot_sectors_per_cyl,10h
	mov BootSector.boot_heads,4
	mov BootSector.boot_small_sectors,dx
	mov BootSector.boot_media,0F0h
	mov BootSector.boot_sectors,edx
	mov ah,2Ch
	int 21h
	mov word ptr BootSector.boot_serial,cx
	mov word ptr BootSector.boot_serial+2,dx
	mov di,OFFSET BootSector.boot_fs
	mov cx,8
	mov si,OFFSET rdfs_name
	rep movs byte ptr es:[di],cs:[si]
	ret
InitBootRecord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadBoot
;
;		DESCRIPTION:	Load boot.exe into buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadBoot	Proc near
	push ds
	push es
;
	mov ax,cs
	mov ds,ax
	mov ax,OFFSET BootLoadInit
	mov bx,OFFSET BootLoadOffset
	mov [bx],ax
	mov si,OFFSET BootSectInit
	mov ax,SEG @data
	mov es,ax
	mov di,OFFSET BootBuf
	mov cx,80h
	rep movsd
;
	pop es
	pop ds
	ret
LoadBoot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MergeBootRecord
;
;		DESCRIPTION:	Merge boot.exe with boot-record
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MergeBootRecord	Proc near
	mov di,OFFSET BootSector
	mov si,OFFSET BootBuf
	mov cx,11
	rep movsb
	add si,33h
	add di,33h
	mov cx,200h - 3Eh
	rep movsb
;
	mov di,OFFSET BootSector
	movzx edx,CurrentSector
	mov es:[di].boot_hidden_sectors,edx
;
	mov edx,400h
	sub dx,CurrentSector
	shr edx,12
	inc dx
	mov es:[di].boot_mapping_sectors,dx
	ret
MergeBootRecord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveBootRecord
;
;		DESCRIPTION:	Save bootrecord from buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveBootRecord	Proc near
	mov bx,OFFSET BootSector
	mov ax,301h
	mov cx,1
	mov dx,0
	int 13h
	jnc save_boot_record_done
    mov dx,OFFSET write_boot_error
    call Log	
save_boot_record_done:
	ret
SaveBootRecord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CopySys
;
;		DESCRIPTION:	Copy bootload.exe to second sector of floppy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopySys	Proc near
	push ds
	push es
;
	mov ax,cs
	mov ds,ax
	mov si,OFFSET BootSectInit
	mov ax,SEG @data
	mov es,ax
	mov di,OFFSET Buf
	mov cx,400h
	rep movsd
;
	pop es
	pop ds
	mov CurrentSector,1
;
	mov bx,OFFSET Buf
	mov dx,1
	mov cx,8
copy_sys_loop:
	mov dx,CurrentSector
	call WriteSector
	inc CurrentSector
	add bx,200h
	loop copy_sys_loop
	clc
copy_sys_done:
	ret
CopySys	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllignSector
;
;		DESCRIPTION:	Allign sector to 4K boundary
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllignSector	Proc near
	mov dx,CurrentSector
	sub dx,9
	test dx,1Fh
	jz AllignSectorDone
	push di
	mov cx,100h
	mov di,OFFSET Buf
	xor ax,ax
	rep stosw	
	mov bx,OFFSET Buf
	mov dx,CurrentSector
	call WriteSector
	inc CurrentSector
	pop di
	jmp AllignSector
AllignSectorDone:
	ret
AllignSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenBin
;
;		DESCRIPTION:	Open binary file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

opn_name    EQU -128
opn_pos     EQU -130

OpenBin   Proc near
    push bp
    mov bp,sp
    sub sp,130
    push ds
    push es
    push di
;
	mov ax,ss
	mov es,ax
    lea di,[bp].opn_name
init_file_next:
	lodsb
	cmp al,0Dh
	je init_file_done
	cmp al,' '
	je init_file_next
	cmp al,'	'
	je init_file_next
init_file_save_next:
	stosb
	lodsb
	cmp al,0Dh
	je init_file_done
	cmp al,' '
	je init_file_done
	cmp al,'	'
	je init_file_done
	jmp init_file_save_next
init_file_done:
	dec si
	mov [bp].opn_pos,di
	mov ax,'B.'
	stosw
	mov ax,'NI'
	stosw
	xor ax,ax
	stosw
;
	mov ax,ss
	mov ds,ax
	lea dx,[bp].opn_name
	mov ax,3D00h
	int 21h
    mov dx,SEG _data
    mov ds,dx
    mov BinHandle,ax
    jnc OpenBinOk
    mov dx,OFFSET bin_error
    call Log
    stc
OpenBinOk:
    pop di
    pop es
    pop ds
    lahf
    add sp,130
    sahf
    pop bp
    ret
OpenBin   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadBin
;
;		DESCRIPTION:	Load binary file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadBin	Proc near
	mov bx,BinHandle
	mov cx,200h
	mov dx,OFFSET Buf
	mov ah,3Fh
	int 21h
;
	push ax
	mov bx,dx
	mov dx,CurrentSector
	call WriteSector
	inc CurrentSector
	pop ax
	cmp ax,200h
	je LoadBin
	ret
LoadBin	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseBin
;
;		DESCRIPTION:	Close binary file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseBin  Proc near
    mov bx,BinHandle
	mov ah,3Eh
	int 21h
    ret
CloseBin   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateBin
;
;		DESCRIPTION:	Create rdos.bin on the floppy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBin	Proc near
	push ds
	mov si,81h
bin_load_loop:
	mov ah,62h
	int 21h
	mov ds,bx
	mov al,[si]
	cmp al,0Dh
	je create_bin_done
    call OpenBin
    jc create_bin_done
	mov ax,SEG _data
	mov ds,ax
	call AllignSector
    call LoadBin
    call CloseBin
	jmp bin_load_loop
	clc
create_bin_done:
	pop ds
	ret
CreateBin	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateMapping
;
;		DESCRIPTION:	Create disc mapping section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMapping	Proc near
	mov bx,OFFSET buf
	mov di,bx
	mov cx,128
	xor eax,eax
	rep stosd
;
	mov byte ptr es:[bx],1
	mov di,OFFSET BootSector
	mov cx,es:[di].boot_mapping_sectors
create_mapping_loop:
	mov dx,CurrentSector
	call WriteSector
	mov byte ptr es:[bx],0
	inc CurrentSector
	loop create_mapping_loop
;
	ret
CreateMapping	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateRoot
;
;		DESCRIPTION:	Create root dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRoot	Proc near
	mov bx,OFFSET buf
	mov di,bx
	mov cx,128
	xor eax,eax
	rep stosd
;
	mov dx,CurrentSector
	call WriteSector
;
	ret
CreateRoot	Endp

init:
	mov ax,_data
	mov ds,ax
	mov es,ax
	call InitBootRecord
	call LoadBoot
	call CopySys
	call CreateBin
	call MergeBootRecord
	call SaveBootRecord
	call CreateMapping
	call CreateRoot
;
	mov ah,4Ch
	int 21h

	END init

