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
; RDFSIMG.ASM
; Floppy disk image creator for RDOS / RDFS. Uses a .CFG file for settings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  rdfsimg

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

FLASH_SIZE	EQU 100000h

exeh_seg	STRUC
exeh_signature		DW ?
exeh_size_lsb		DW ?
exeh_size_msb		DW ?
exeh_reloc_ant		DW ?
exeh_size_header	DW ?
exeh_minalloc		DW ?
exeh_maxalloc		DW ?
exeh_ss			DW ?
exeh_sp			DW ?
exeh_checksum		DW ?
exeh_ip			DW ?
exeh_cs			DW ?
exeh_reloc_offs		DW ?
exeh_ov_nr		DW ?
exeh_seg	ENDS

boot_struc	STRUC

boot_jmp			DB ?,?,?
boot_name			DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_resv1			DB ?
boot_mapping_sectors		DW ?
boot_resv3			DB ?
boot_resv4			DW ?
boot_small_sectors		DW ?
boot_media			DB ?
boot_resv6			DW ?
boot_sectors_per_cyl		DW ?
boot_heads			DW ?
boot_hidden_sectors		DD ?
boot_sectors			DD ?
boot_drive_nr			DB ?,?
boot_signature			DB ?
boot_serial			DD ?
boot_volume			DB 11 DUP(?)
boot_fs				DB 8 DUP(?)

boot_struc		ENDS

.stack

.data

CurrentSector	DW ?
BinHandle	DW ?
RomHandle	DW ?

BootBuf		DB 512 DUP(?)

BootSector	DB 512 Dup(0)

Buf		DB 1000h DUP(?)

.code

.386c

	extrn BootSectInit:near
	extrn BootLoadOffset:near
	extrn BootLoadInit:near

FormatStart:

read_boot_error		DB 'cannot read bootsector',0Dh,0Ah,24h
write_boot_error	DB 'cannot write bootsector',0Dh,0Ah,24h
write_sector_error	DB 'cannot read sector',0Dh,0Ah,24h
exe_error   		DB 'cannot find bootsec.exe',0Dh,0Ah,24h
rdosload_error		DB 'cannot find rdosload.exe',0Dh,0Ah,24h
rdossys_error		DB 'cannot create rdos.sys',0Dh,0Ah,24h
rdosbin_error		DB 'cannot create rdos.bin',0Dh,0Ah,24h
bin_error   		DB 'cannot find .bin file',0Dh,0Ah,24h
rom_error   		DB 'cannot find .rom file',0Dh,0Ah,24h
wait1 db 'Creating floppy [',24h
wait2 db '.',24h
wait3 db '] Done',0Dh,0Ah,24h

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
;		PARAMETERS:		
;						DS:DX	Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSector	Proc near
	push cx
;
	mov cx,3
write_sector_loop:
	push dx
	mov bx,RomHandle
	mov cx,512
	mov ax,CurrentSector
	mul cx
	mov cx,dx
	mov dx,ax
	mov ax,4200h
	int 21h
	pop dx
;
	mov cx,512
	mov ah,40h
	int 21h
;
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

rdfs_name	DB 'RDFS    '

InitBootRecord	Proc near
	mov edx,FLASH_SIZE / 200h
	mov BootSector.boot_bytes_per_sector,200h
	mov BootSector.boot_sectors_per_cyl,12h
	mov BootSector.boot_heads,2
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
	mov edx,FLASH_SIZE / 200h
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
	mov bx,RomHandle
	xor cx,cx
	xor dx,dx
	mov ax,4200h
	int 21h
;
	mov cx,200h
	mov dx,OFFSET BootSector
	mov ah,40h
	int 21h
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
;		NAME:			FloppyImg
;
;		DESCRIPTION:	Create a floppy image
;               PARAMATER  :    ds:dx filename
;               RETURN     :    AX handle
;                               CY error AX = -1
;                               NC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BUFFER_SIZE EQU 2880
SECTOR_SIZE EQU 512

hfile  equ word ptr [bp-2]
count equ word ptr [bp-4]

FloppyImg	proc near
	push bp
	mov bp,sp
	sub sp,4
	push di
	push bx
	push cx
	push dx
	push es
	xor cx,cx
	mov ah,3Ch
	int 21h
	jc fi_end1
;
	mov hfile,ax
;	
	mov count,0
	mov cx,SECTOR_SIZE
	mov dx,offset wait1
	call Log
fi_empty:
	push cx
	push ds
	mov cx,BUFFER_SIZE
	mov bx,hfile
	mov ax,cs
	mov dx,offset fi_buf
	mov ds,ax                                                                                               
	mov ah,40h
	int 21h
	pop ds
	jc short fi_end2
	inc count
	test count,64
	jz short fi_go_on
	mov dx,offset wait2
	call Log
	mov count,0
fi_go_on:
	pop cx
	loop fi_empty
;
	mov bx,hfile
	xor dx,dx
	xor cx,cx
	mov ax,4200h
	int 21h
;	
	mov dx,offset wait3
	call Log
	mov ax,hfile
	clc
	jmp fi_ret
fi_end2:
 	mov bx,hfile
 	mov ah,3Eh
 	int 21h	
fi_end1:
 	mov ax,-1
 	stc
fi_ret:
 	pop es
 	pop dx
 	pop cx
 	pop bx
 	pop di
 	add sp,4
 	mov sp,bp
 	pop bp
 	ret
FloppyImg	endp
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
;		NAME:			OpenFiles
;
;		DESCRIPTION:	Open input & output files
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

opn_name    EQU -128
opn_pos     EQU -130

OpenFiles   Proc near
    push bp
    mov bp,sp
    sub sp,130
    push ds
    push es
    push si
    push di
;
	mov ax,ss
	mov es,ax
	mov ah,62h
	int 21h
	mov ds,bx
	mov si,81h
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
    jnc OpenBinOk
    mov dx,OFFSET bin_error
    call Log
    jmp OpenFilesDone
OpenBinOk:
    mov bx,SEG _data
    mov ds,bx
	mov BinHandle,ax
;
	mov ax,ss
	mov ds,ax
	mov es,ax
	mov di,[bp].opn_pos
	mov ax,'R.'
	stosw
	mov ax,'MO'
	stosw
	xor ax,ax
	stosw
	lea dx,[bp].opn_name
	call FloppyImg
    jnc OpenRomOk
    mov dx,OFFSET rom_error
    call Log
    jmp OpenFilesDone
OpenRomOk:
    mov bx,SEG _data
    mov ds,bx
    mov RomHandle,ax
    clc
OpenFilesDone:
;
    pop di
    pop si
    pop es
    pop ds
    lahf
    add sp,130
    sahf
    pop bp
    ret
OpenFiles   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseFiles
;
;		DESCRIPTION:	Close input & output files
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseFiles  Proc near
    mov bx,BinHandle
	mov ah,3Eh
	int 21h
;
	mov bx,RomHandle
	mov ah,3Eh
	int 21h
    ret
CloseFiles   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateMapping
;
;		DESCRIPTION:	Create disc mapping section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMapping	Proc near
	mov dx,OFFSET buf
	mov di,dx
	mov cx,128
	xor eax,eax
	rep stosd
;
	mov di,OFFSET BootSector
	mov cx,es:[di].boot_mapping_sectors
	mov di,dx
	mov byte ptr es:[di],1
create_mapping_loop:
	call WriteSector
	mov byte ptr es:[di],0
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
	mov dx,OFFSET buf
	mov di,dx
	mov cx,128
	xor eax,eax
	rep stosd
	call WriteSector
	ret
CreateRoot	Endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Signe image
;
;		DESCRIPTION:	put 0x55AA at 0x1FE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sign DW 0AA55h

SignImg	proc near
        
        push bx
        push cx
        push dx
        
	mov bx,RomHandle
	mov dx,1FEh
	xor cx,cx
	mov ax,4200h
	int 21h
;
	push ds
	mov cx,2
	mov bx,RomHandle
	mov ax,cs
	mov dx,offset sign
	mov ds,ax                                                                                               
	mov ah,40h
	int 21h
        pop ds
        
        pop dx
        pop cx
        pop bx        
        ret
SignImg	endp

init:
	mov ax,_data
	mov ds,ax
	mov es,ax
	call OpenFiles
	call InitBootRecord
	call LoadBoot
	call CopySys
    call LoadBin
	call MergeBootRecord
	call SaveBootRecord
	call CreateMapping
	call CreateRoot
	call SignImg
	call CloseFiles
;
	mov ah,4Ch
	int 21h
fi_buf          DB 3000 dup(0F6h)

	END init

