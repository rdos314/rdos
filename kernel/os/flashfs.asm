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
; FLASHFS.ASM
; FLASHFS (Flash File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME flashfs

GateSize = 16

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\fs.inc
INCLUDE flashfs.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	extrn cache_dir:far
	extrn create_file:far
	extrn delete_file:far

	extrn CacheBlock:near
	extrn GetFreeBlockSectors:near

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Format
;
;		DESCRIPTION:	Format filesystem
;
;		PARAMETERS:		AL			Drive
;						ES:DI		FS name
;						ECX			Number of sectors
;                       FS:EDX      Format data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format	PROC far
    push ds
	push es
    pushad
;
	mov dx,flat_sel
	mov es,dx
;
    xor edx,edx

format_loop:
	NewSector
	push eax
	push ecx
;
	mov edi,esi
	mov ecx,80h
	mov eax,-1
	rep stos dword ptr es:[edi]
;
	pop ecx
	pop eax	
;
	ModifySector
	UnlockSector
;
    inc edx
    loop format_loop
;    
    clc
    popad
    pop es
    pop ds
	ret
format	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MOUNT
;
;		DESCRIPTION:	Mount filesystem
;
;       PARAMETERS:     AL          Drive
;						ECX			Number of sectors
;                       FS:EDX      Mount data
;
;		RETRUNS:		DS:SI		ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount	PROC far
	push es
	push fs
	push eax
	push ebx
	push ecx
	push edx
	push edi
;
	shr ecx,7
	push ax
	mov eax,SIZE drive_data_seg
	add eax,ecx
	add eax,ecx
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
	pop ax
;
	mov ds:block_count,cx
	mov ds:drive_nr,al
;
    xor edx,edx
	mov di,SIZE drive_data_seg

mount_loop:
	call CacheBlock
	mov ds:[di],fs

mount_next:
	add di,2
    add edx,80h
    loop mount_loop
;
	xor si,si
;
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop fs
	pop es
    clc
	ret
mount	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLUSH
;
;		DESCRIPTION:	Flush filesystem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush	PROC far
	clc
	ret
flush	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISMOUNT
;
;		DESCRIPTION:	Unmount file system
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dismount	PROC far
	int 3
	stc
	ret
dismount	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_DRIVE_INFO
;
;		DESCRIPTION:	Get drive info
;
;		RETURNS:		EAX		FREE UNITS
;						CX		BYTES / UNIT
;						EDX		TOTAL UNITS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_info	PROC far
	push fs
	push di
;
	xor edx,edx
	mov cx,ds:block_count
	mov di,SIZE drive_data_seg

get_info_loop:
	mov ax,ds:[di]
	or ax,ax
	jz get_info_full
;	
	push cx
	mov fs,ax
	call GetFreeBlockSectors
	add edx,ecx
	pop cx
	jmp get_info_next

get_info_full:
	add edx,127

get_info_next:
	add di,2
    loop get_info_loop
;
	mov eax,edx
	mov cx,512
	movzx edx,ds:block_count
	shl edx,7
	clc
;
	pop di
	pop fs
	ret
get_drive_info	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_DIR
;
;		DESCRIPTION:	Create new directory
;
;		PARAMETERS:		ES:EDI		DIRECTORY NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_dir	PROC far
    int 3
    stc
	ret
create_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_DIR
;
;		DESCRIPTION:	Delete empty directory
;
;		PARAMETERS:		BX			DIR SELECTOR
;						EDX			DIR ENTRY TO DELETE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_dir	PROC far
    int 3
	stc
	ret
delete_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RENAME_FILE
;
;		DESCRIPTION:	rename file within filesystem
;
;		PARAMETERS:		FS:ESI		CURRENT NAME
;						ES:EDI		NEW NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rename_file	PROC far
	int 3
	stc
	ret
rename_file	ENDP

PAGE 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_IOCTL_DATA
;
;		DESCRIPTION:	Get IOCTL data
;
;		PARAMETERS:		BX			HANDLE
;
;		RETURNS:		DX			IOCTL_DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ioctl_data	PROC far
	movzx dx,al
	or dx,40h
	ret
get_ioctl_data	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FILE_SIZE
;
;		DESCRIPTION:	Set file size
;
;		PARAMETERS:		BX			HANDLE
;						EDX			FILE SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_file_size	PROC far
;	int 3
	stc
	ret
set_file_size	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			update_dir
;
;		DESCRIPTION:	Update dir entry
;
;		PARAMETERS:		EDX			Dir dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_dir	PROC far
    int 3
	stc
	ret
update_dir	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			update_file
;
;		DESCRIPTION:	Update file entry
;
;		PARAMETERS:		EDX			Dir file entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_file	PROC far
	int 3
	stc
	ret
update_file	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			READ_FILE
;
;		DESCRIPTION:	Read file
;
;		PARAMETERS:		BX			HANDLE TO DEVICE
;						ES:EDI		BUFFER
;						ECX			NUMBER OF BYTES TO READ
;						EDX			POSITION
;
;		RETURNS:		EAX			NUMBER OF BYTES READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file	PROC far
    int 3
    stc
	ret
read_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_FILE
;
;		DESCRIPTION:	Write file
;
;		PARAMETERS:		BX			HANDLE TO DEVICE
;						ES:EDI		BUFFER
;						ECX			NUMBER OF BYTES TO READ
;						EDX			POSITION
;
;		RETURNS:		EAX			NUMBER OF BYTES WRITTEN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_file	PROC far
    int 3
	stc
 	ret
write_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			allocate_file_list
;
;		DESCRIPTION:	Allocate file list
;
;		RETURNS:		EDI		Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_file_list	PROC far
    int 3
    stc
	ret
allocate_file_list	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			free_file_list
;
;		DESCRIPTION:	Free file list
;
;		PARAMETERS:		EDI		Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_file_list	PROC far
    int 3
    stc
	ret
free_file_list	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			READ_FILE_BLOCK
;
;		DESCRIPTION:	Read file block
;
;		PARAMETERS:		BX			HANDLE TO DEVICE
;						EDI			LINEAR ADDRESS
;						ECX			NUMBER OF PAGES TO READ
;						EDX			POSITION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file_block	PROC far
	int 3
	stc
	ret
read_file_block	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_FILE_BLOCK
;
;		DESCRIPTION:	Write file block
;
;		PARAMETERS:		BX			HANDLE TO DEVICE
;						EDI			LINEAR ADDRESS
;						ECX			NUMBER OF PAGES TO READ
;						EDX			POSITION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_file_block	PROC far
    int 3
	stc
	ret
write_file_block	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Dummy
;
;		DESCRIPTION:	Unsupported functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy	PROC far
    int 3
	stc
	ret
dummy	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flashfs_name	DB 'FLASHFS',0

flashfs_ctrl:
ffs00	DW OFFSET format,			flashfs_code_sel
ffs01	DW OFFSET mount,			flashfs_code_sel
ffs02	DW OFFSET flush,		    flashfs_code_sel
ffs03	DW OFFSET dismount,			flashfs_code_sel
ffs04	DW OFFSET get_drive_info,	flashfs_code_sel
ffs05	DW OFFSET cache_dir,		flashfs_code_sel
ffs06	DW OFFSET update_dir,		flashfs_code_sel
ffs07	DW OFFSET update_file,		flashfs_code_sel
ffs08	DW OFFSET create_dir,		flashfs_code_sel
ffs09	DW OFFSET delete_dir,		flashfs_code_sel
ffs10	DW OFFSET delete_file,		flashfs_code_sel
ffs11	DW OFFSET rename_file,		flashfs_code_sel
ffs12	DW OFFSET create_file,		flashfs_code_sel
ffs13	DW OFFSET get_ioctl_data,	flashfs_code_sel
ffs14	DW OFFSET set_file_size,	flashfs_code_sel
ffs15	DW OFFSET read_file,		flashfs_code_sel
ffs16	DW OFFSET write_file,		flashfs_code_sel
ffs17	DW OFFSET allocate_file_list,flashfs_code_sel
ffs18	DW OFFSET free_file_list,	flashfs_code_sel
ffs19	DW OFFSET read_file_block,	flashfs_code_sel
ffs20	DW OFFSET write_file_block,	flashfs_code_sel


init	PROC far
	push ds
	push es
	push fs
	push gs
	pushad
	mov bx,flashfs_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET flashfs_name
	mov di,OFFSET flashfs_ctrl
	RegisterFileSystem
;
	popad
	pop gs
	pop fs
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init
