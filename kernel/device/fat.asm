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
; FAT.ASM
; FAT filesystem driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME fat

GateSize = 16

INCLUDE ..\os\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\user.def
INCLUDE ..\os\virt.def
INCLUDE ..\os\os.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\virt.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE fat.inc

attr_read_only		EQU 1
attr_hidden			EQU 2
attr_system			EQU 4
attr_volume			EQU 8
attr_dir			EQU 10h
attr_arcive			EQU 20h

MAX_DRIVES		EQU 'Z' -'A' + 1

	extrn get_param:near
	extrn parse_dir:near
	extrn parse_file:near
	extrn insert_file_node:near
	extrn insert_dir_node:near
	extrn create_dir_handle:near
	extrn delete_dir_handle:near
	extrn open_file_handle:near
	extrn close_file_handle:near
	extrn remove_file_node:near
	extrn lock_file:near
	extrn update_file:near
	extrn lock_dir_entry:near
	extrn update_dir_name:near
	extrn update_dir_time:near
	extrn update_dir_entry:near
	extrn set_dir_name:near

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MOUNT12
;
;		DESCRIPTION:	Mount FAT12 on a drive
;
;		RETRUNS:		DS:SI		ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount12	PROC far
	push es
;
	push ax
	mov eax,SIZE drive_data_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
	pop ax
	mov ds:fat_type,fat12
	call get_param
;
	pop es
	ret
mount12	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MOUNT16
;
;		DESCRIPTION:	Mount FAT16 on a drive
;
;		RETRUNS:		DS:SI		ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount16	PROC far
	push es
;
	push ax
	mov eax,SIZE drive_data_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
	pop ax
	mov ds:fat_type,fat16
	call get_param
;
	pop es
	ret
mount16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MOUNT32
;
;		DESCRIPTION:	Mount FAT32 on a drive
;
;		RETRUNS:		DS:SI		ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount32	PROC far
	push es
;
	push ax
	mov eax,SIZE drive_data_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
	pop ax
	mov ds:fat_type,fat32
	call get_param
;
	pop es
	ret
mount32	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISMOUNT
;
;		DESCRIPTION:	Dismount filesystem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dismount	PROC far
	ret
dismount	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_DRIVE_INFO
;
;		DESCRIPTION:	Read info from drive
;
;		RETURNS:		EAX		FREE UNITS
;						CX		BYTES / UNIT
;						EDX		TOTAL UNITS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_info	PROC far
	mov eax,ds:clusters
	mov cl,ds:fat_cluster_shift
	shl eax,cl
	mov edx,eax
	mov cx,200h
	clc
	ret
get_drive_info	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_CUR_DIR
;
;		DESCRIPTION:	Set current directory
;
;		PARAMETERS:		ES:EDI		PATH NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cur_dir	PROC far
	push es
	push fs
	push edx
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	mov al,gs:[edx]
	or al,al
	stc
	jne set_cur_dir_done
	mov dx,fs
	mov al,ds:drive_nr
	SetCurDirPtr
	clc
set_cur_dir_done:
	pop edx
	pop fs
	pop es
	ret
set_cur_dir	ENDP

PAGE 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_CUR_DIR
;
;		DESCRIPTION:	Get current directory
;
;		PARAMETERS:		ES:EDI		PATH NAME
;						AL			DRIVE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cur_dir	PROC far
	push es
	push fs
	push ecx
	push edx
	push edi
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	xor ecx,ecx
	mov byte ptr gs:[edx],0
;
	push edx
	GetCurDirPtr
	mov fs,dx
	or dx,dx
	pop edx
	je get_cur_dir_done
get_cur_dir_loop:
	mov ax,fs:dir_parent
	or ax,ax
	je get_cur_dir_done
	mov edi,fs:dir_parent_entry
	mov fs,ax
	push ds
	push es
	mov ax,gs
	mov es,ax
	mov ax,flat_sel
	mov ds,ax
;
	push ecx
	push esi
	push edi
	movzx eax,[edi].dir_name_size
	mov esi,edx
	mov edi,edx
	add edi,eax
	add esi,ecx
	add edi,ecx
	dec esi
	std
	rep movs byte ptr es:[edi],es:[esi]
	cld
	pop edi
	pop esi
	pop ecx
	add ecx,eax
	inc ecx
;
	push ecx
	push edi
	mov esi,edi
	mov edi,edx
	add esi,OFFSET dir_name
	mov ecx,eax
	mov al,es:[edi]
	rep movs byte ptr es:[edi],[esi]
	or al,al
	je get_cur_dir_no_slash
	mov al,'\'
get_cur_dir_no_slash:
	stos byte ptr es:[edi]
	pop edi
	pop ecx
;
	pop es
	pop ds
	jmp get_cur_dir_loop
get_cur_dir_done:
	clc
;
	pop edi
	pop edx
	pop ecx
	pop fs
	pop es
	ret
get_cur_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MAKE_DIR
;
;		DESCRIPTION:	Create directory
;
;		PARAMETERS:		ES:EDI		DIRECTORY NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

make_dir	PROC far
	push es
	push fs
	push ax
	push ebx
	push edx
	push esi
	push edi
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	mov al,gs:[edx]
	or al,al
	stc
	je make_dir_done
	call insert_dir_node
	jc make_dir_done	
	call update_dir_name
	call update_dir_time
	ModifySector
	call create_dir_handle
	clc
make_dir_done:
	pop edi
	pop esi
	pop edx
	pop ebx
	pop ax
	pop fs
	pop es
	ret
make_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE_DIR
;
;		DESCRIPTION:	Remove directory
;
;		PARAMETERS:		ES:EDI		DIRECTORY NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_dir	PROC far
	push es
	push fs
	push edx
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	mov al,gs:[edx]
	or al,al
	stc
	jne remove_dir_done
	call delete_dir_handle
remove_dir_done:
	pop edx
	pop fs
	pop es
	ret
remove_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_FILE
;
;		DESCRIPTION:	Delete file
;
;		PARAMETERS:		ES:EDI		FILE NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_file	PROC far
	push es
	push fs
	push ecx
	push edx
	push edi
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	call parse_file
	jc delete_file_done
	push fs
	call open_file_handle
	xor ecx,ecx
	call update_file
	pop fs
	call remove_file_node
	clc
delete_file_done:
	pop edi
	pop edx
	pop ecx
	pop fs
	pop es
	ret
delete_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RENAME_FILE
;
;		DESCRIPTION:	Rename file
;
;		PARAMETERS:		FS:EBX		CURRENT NAME
;						ES:EDI		NEW NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rename_file	PROC far
	push fs
	push es
	push eax
	push ebx
	push cx
	push edx
	push esi
	push edi
;
	push es
	push edi
	mov dx,fs
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,ebx
;
	call parse_dir
	call parse_file
	mov eax,edi
	pop edi
	pop es
	jc rename_file_done
;
	push eax
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	mov cx,fs
	call parse_dir
	mov al,gs:[edx]
	or al,al
	je rename_dest_fail
	mov ax,fs
	cmp ax,cx
	jne rename_dest_fail
	call parse_file
	jnc rename_dest_fail
	pop edi
	call lock_dir_entry
	call set_dir_name
	ModifySector
	UnlockSector
	clc
	jmp rename_file_done

rename_dest_fail:
	pop edi
	stc
rename_file_done:
	pop edi
	pop esi
	pop edx
	pop cx
	pop ebx
	pop eax
	pop es
	pop fs
	ret
rename_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_FILE_ATTRIB
;
;		DESCRIPTION:	Get file attribute
;
;		PARAMETERS:		ES:EDI		FILENAME
;						NC			SUCCESS
;						CX			FILE ATTRIBUTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_attrib	PROC far
	push es
	push fs
	push ebx
	push edx
	push esi
	push edi
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	mov al,gs:[edx]
	or al,al
	jne get_file_attrib_not_dir
	mov cx,10h
	clc
	jmp set_file_attrib_done	

get_file_attrib_not_dir:
	call parse_file
	jc get_file_attrib_done
	movzx cx,es:[edi].dir_attrib
	clc
get_file_attrib_done:
	pop edi
	pop esi
	pop edx
	pop ebx
	pop fs
	pop es
	ret
get_file_attrib	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FILE_ATTRIB
;
;		DESCRIPTION:	Set file attribute
;
;		PARAMETERS:		ES:EDI		FILENAME
;						NC			SUCCESS
;						CX			FILE ATTRIBUTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_file_attrib	PROC far
	push es
	push fs
	push ebx
	push edx
	push esi
	push edi
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	mov al,gs:[edx]
	or al,al
	jne set_file_attrib_not_dir
	test cl,10h
	clc
	jnz set_file_attrib_done
	stc
	jmp set_file_attrib_done	

set_file_attrib_not_dir:
	call parse_file
	jc set_file_attrib_done
	test cl,10h
	stc
	jnz set_file_attrib_done
	mov es:[edi].dir_attrib,cl
	call lock_dir_entry
	call update_dir_entry
	ModifySector
	UnlockSector
	clc
set_file_attrib_done:
	pop edi
	pop esi
	pop edx
	pop ebx
	pop fs
	pop es
	ret
set_file_attrib	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_DIR
;
;		DESCRIPTION:	Open directory search
;
;		PARAMETERS:		ES:EDI		PATH NAME
;						NC			SUCCESS
;
;		RETURNS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_dir	PROC far
	push es
	push fs
	push ax
	push edx
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	mov al,gs:[edx]
	or al,al
	stc
	jne open_dir_done
	inc fs:dir_usage
	mov bx,fs
	clc
open_dir_done:
;
	pop edx
	pop ax
	pop fs
	pop es
	ret
open_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_DIR
;
;		DESCRIPTION:	Close directory search
;
;		PARAMETERS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_dir	PROC far
	push fs
	mov fs,bx
	dec fs:dir_usage
	clc
	pop fs
	ret
close_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			READ_DIR
;
;		DESCRIPTION:	Read directory entry
;
;		PARAMETERS:		BX			HANDLE
;						DX			ENTRY #
;						CX			MAX SIZE OF FILENAME
;						ES:EDI		FILENAME BUFFER
;		RETURNS:		ECX			FILE SIZE
;						BX			FILE ATTRIBUTE
;						EDX:EAX		FILE TIME/DATE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_dir	PROC far
	push fs
	push esi
	push ebp
;
	push es
	push edi
;
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
;
	mov edi,fs:dir_dir_ptr
	or edi,edi
	jz read_file_start

read_dir_entries:
	or dx,dx
	jz read_dir_ok
	dec dx
	mov edi,es:[edi].dir_next
	cmp edi,fs:dir_dir_ptr
	jne read_dir_entries

read_file_start:
	mov edi,fs:dir_file_ptr
	or edi,edi
	jz read_dir_fail

read_file_entries:
	or dx,dx
	jz read_dir_ok
	dec dx
	mov edi,es:[edi].dir_next
	cmp edi,fs:dir_file_ptr
	jne read_file_entries
	jmp read_dir_fail

read_dir_ok:
	movzx ax,es:[edi].dir_name_size
	cmp ax,cx
	jnc read_dir_size_ok
	mov cx,ax
read_dir_size_ok:
	movzx ecx,cx
	mov esi,edi
	mov ax,flat_sel
	mov ds,ax
	mov ebp,es:[edi].dir_file_size
	movzx bx,es:[edi].dir_attrib
	mov edx,es:[edi].dir_time+4
	mov eax,es:[edi].dir_time
	pop edi
	pop es
;
	add esi,OFFSET dir_name
	rep movs byte ptr es:[edi],[esi]
	push ax
	xor al,al
	stos byte ptr es:[edi]
	pop ax
	mov ecx,ebp
	clc	
	jmp read_dir_done

read_dir_fail:
	stc
	pop edi
	pop es

read_dir_done:	
	pop ebp
	pop esi
	pop fs
	ret
read_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_FILE
;
;		DESCRIPTION:	Open a file
;
;		PARAMETERS:		ES:EDI		FILENAME
;						CL			ACCESS MODE
;
;		RETURNS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file	PROC far
	push es
	push fs
	push edx
	push edi
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	call parse_file
	jc open_file_fail
	call open_file_handle
	mov bx,fs
	clc
open_file_fail:
	pop edi
	pop edx
	pop fs
	pop es
	ret
open_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_FILE
;
;		DESCRIPTION:	Create a file
;
;		PARAMETERS:		ES:EDI		FILENAME
;						CX			FILE ATTRIBUTE
;
;		RETURNS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_file	PROC far
	push es
	push fs
	push edx
	push edi
;
	mov dx,es
	mov gs,dx
	mov dx,flat_sel
	mov es,dx
	mov edx,edi
;
	call parse_dir
	call parse_file
	jc create_file_non_exist
	call open_file_handle
	push ecx
	xor ecx,ecx
	call update_file
	pop ecx
	mov bx,fs
	clc
	jmp create_file_done

create_file_non_exist:
	call insert_file_node
	jc create_file_done
	call open_file_handle
	mov bx,fs
	clc
create_file_done:
	pop edi
	pop edx
	pop fs
	pop es
	ret
create_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_FILE
;
;		DESCRIPTION:	Close a file
;
;		PARAMETERS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_file	PROC far
	push es
	push fs
	push ax
;
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
	call close_file_handle
	clc
;
	pop ax
	pop fs
	pop es
	ret
close_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DUPL_FILE
;
;		DESCRIPTION:	Duplicate file
;
;		PARAMETERS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_file	PROC far
	push fs
	mov fs,bx
	inc fs:file_usage
	pop fs
	clc
	ret
dupl_file	ENDP

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
;		NAME:			GET_FILE_SIZE
;
;		DESCRIPTION:	Get file size
;
;		PARAMETERS:		BX			Handle
;
;		RETURNS:		EDX			FILE SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_size	PROC far
	push es
	push fs
	push ax
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
	mov edx,fs:file_dir_entry
	mov edx,es:[edx].dir_file_size
	clc
	pop ax
	pop fs
	pop es
	ret
get_file_size	ENDP
	
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
	push es
	push fs
	push ecx
;
	mov cx,flat_sel
	mov es,cx
	mov fs,bx
	mov ecx,edx
	call update_file
;
	pop ecx
	pop fs
	pop es
	ret
set_file_size	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_FILE_TIME
;
;		DESCRIPTION:	Get file time
;
;		PARAMETERS:		BX			HANDLE
;
;		RETURNS:		EDX:ECX		FILE TIME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_time	PROC far
	push es
	push fs
	push ax
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
	mov edx,fs:file_dir_entry
	mov ecx,es:[edx].dir_time
	mov edx,es:[edx].dir_time+4
	clc
	pop ax
	pop fs
	pop es
	ret
get_file_time	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FILE_TIME
;
;		DESCRIPTION:	Set file time
;
;		PARAMETERS:		BX			HANDLE
;						EDX:ECX		FILE TIME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_file_time	PROC far
	push es
	push fs
	push ax
	push ebx
	push esi
	push edi
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
	mov edi,fs:file_dir_entry
	mov es:[edi].dir_time,ecx
	mov es:[edi].dir_time+4,edx
	call lock_dir_entry
	call update_dir_time
	ModifySector
	UnlockSector
	clc
	pop edi
	pop esi
	pop ebx
	pop ax
	pop fs
	pop es
	stc
	ret
set_file_time	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			READ_FILE
;
;		DESCRIPTION:	Read from file
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
	push es
	push fs
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov fs,bx
	mov ax,flat_sel
	mov gs,ax
	mov esi,fs:file_dir_entry
	mov eax,gs:[esi].dir_file_size
;
	sub eax,edx
	jc read_file_fail
	cmp eax,ecx
	jnc read_file_do
	mov ecx,eax
read_file_do:
	or ecx,ecx
	jnz read_file_non_zero
;
	xor eax,eax
	clc
	jmp read_file_done

read_file_non_zero:
	push ecx
	push es
	mov ax,flat_sel
	mov es,ax
	call lock_file
	pop es
	jc read_file_pop
	xor eax,eax
	sub eax,edx
	and eax,1FFh
	cmp eax,ecx
	jc read_file_first_do
	mov eax,ecx
read_file_first_do:
	push ecx
	mov ecx,eax
	shr ecx,2
	rep movs dword ptr es:[edi],gs:[esi]
	mov ecx,eax
	and ecx,3
	rep movs byte ptr es:[edi],gs:[esi]
	pop ecx	
	UnlockSector
	sub ecx,eax
	jz read_file_ok
	add edx,eax
	push ecx
	shr ecx,9	
	or ecx,ecx
	jz read_file_partial_last
read_file_loop:
	push es
	mov ax,flat_sel
	mov es,ax
	call lock_file
	pop es
	jc read_file_pop2
	push ecx
	mov ecx,80h
	rep movs dword ptr es:[edi],gs:[esi]
	pop ecx
	UnlockSector
	add edx,200h
	sub ecx,1
	jnz read_file_loop
read_file_partial_last:
	pop ecx 
	and ecx,1FFh
	jz read_file_ok
;
	push es
	mov ax,flat_sel
	mov es,ax
	call lock_file
	pop es
	jc read_file_pop
	push ecx
	mov eax,ecx
	shr ecx,2
	rep movs dword ptr es:[edi],gs:[esi]
	mov ecx,eax
	and ecx,3
	rep movs byte ptr es:[edi],gs:[esi]
	pop ecx
	UnlockSector

read_file_ok:
	pop ecx
	mov eax,ecx
	clc
	jmp read_file_done
read_file_pop2:
	pop ecx
read_file_pop:
	pop ecx
read_file_fail:
	xor eax,eax
	stc
read_file_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop fs
	pop es
	ret
read_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_FILE
;
;		DESCRIPTION:	Write to file
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
	push es
	push fs
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ax,es
	mov gs,ax
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
	mov esi,edi
	mov edi,fs:file_dir_entry
	mov eax,es:[edi].dir_file_size
;
	push ecx
	push edx
	add ecx,edx
	cmp eax,ecx
	jnc write_file_size_ok
	call update_file
	jc write_file_pop2
write_file_size_ok:
	pop edx
	pop ecx
	jc write_file_fail
;
	push ecx
	push esi
	call lock_file
	mov edi,esi
	pop esi
	jc write_file_pop
	xor eax,eax
	sub eax,edx
	and eax,1FFh
	cmp eax,ecx
	jc write_file_first_do
	mov eax,ecx
write_file_first_do:
	push ecx
	mov ecx,eax
	shr ecx,2
	rep movs dword ptr es:[edi],gs:[esi]
	mov ecx,eax
	and ecx,3
	rep movs byte ptr es:[edi],gs:[esi]
	pop ecx	
	ModifySector
	UnlockSector
	sub ecx,eax
	jz write_file_ok
	add edx,eax
	push ecx
	shr ecx,9	
	or ecx,ecx
	jz write_file_partial_last
write_file_loop:
	push esi
	call lock_file
	mov edi,esi
	pop esi
	jc write_file_pop2	
	push ecx
	mov ecx,80h
	rep movs dword ptr es:[edi],gs:[esi]
	pop ecx
	ModifySector
	UnlockSector
	add edx,200h
	sub ecx,1
	jnz write_file_loop
write_file_partial_last:
	pop ecx 
	and ecx,1FFh
	jz write_file_ok
;
	push esi
	call lock_file
	mov edi,esi
	pop esi
	jc write_file_pop
	push ecx
	mov eax,ecx
	shr ecx,2
	rep movs dword ptr es:[edi],gs:[esi]
	mov ecx,eax
	and ecx,3
	rep movs byte ptr es:[edi],gs:[esi]
	pop ecx
	ModifySector
	UnlockSector

write_file_ok:
	pop ecx
	clc
	mov eax,ecx
	jmp write_file_done
write_file_pop2:
	pop ecx
write_file_pop:
	pop ecx
write_file_fail:
	xor eax,eax
	stc
write_file_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop fs
	pop es
 	ret
write_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy	Proc far
	stc
	ret
dummy	Endp

fs12_name	DB 'FAT12',0

fs12_ctrl:
f12s00	DW OFFSET mount12,			fat_code_sel
f12s01	DW OFFSET dismount,			fat_code_sel
f12s02	DW OFFSET get_drive_info,	fat_code_sel
f12s03	DW OFFSET set_cur_dir,		fat_code_sel
f12s04	DW OFFSET get_cur_dir,		fat_code_sel
f12s05	DW OFFSET make_dir,			fat_code_sel
f12s06	DW OFFSET remove_dir,		fat_code_sel
f12s07	DW OFFSET delete_file,		fat_code_sel
f12s08	DW OFFSET rename_file,		fat_code_sel
f12s09	DW OFFSET get_file_attrib,	fat_code_sel
f12s10	DW OFFSET set_file_attrib,	fat_code_sel
f12s11	DW OFFSET open_dir,			fat_code_sel
f12s12	DW OFFSET close_dir,		fat_code_sel
f12s13	DW OFFSET read_dir,			fat_code_sel
f12s14	DW OFFSET open_file,		fat_code_sel
f12s15	DW OFFSET create_file,		fat_code_sel
f12s16	DW OFFSET close_file,		fat_code_sel
f12s17	DW OFFSET dupl_file,		fat_code_sel
f12s18	DW OFFSET get_ioctl_data,	fat_code_sel
f12s19	DW OFFSET get_file_size,	fat_code_sel
f12s20	DW OFFSET set_file_size,	fat_code_sel
f12s21	DW OFFSET get_file_time,	fat_code_sel
f12s22	DW OFFSET set_file_time,	fat_code_sel
f12s23	DW OFFSET read_file,		fat_code_sel
f12s24	DW OFFSET write_file,		fat_code_sel

fs16_name	DB 'FAT16',0

fs16_ctrl:
f16s00	DW OFFSET mount16,			fat_code_sel
f16s01	DW OFFSET dismount,			fat_code_sel
f16s02	DW OFFSET get_drive_info,	fat_code_sel
f16s03	DW OFFSET set_cur_dir,		fat_code_sel
f16s04	DW OFFSET get_cur_dir,		fat_code_sel
f16s05	DW OFFSET make_dir,			fat_code_sel
f16s06	DW OFFSET remove_dir,		fat_code_sel
f16s07	DW OFFSET delete_file,		fat_code_sel
f16s08	DW OFFSET rename_file,		fat_code_sel
f16s09	DW OFFSET get_file_attrib,	fat_code_sel
f16s10	DW OFFSET set_file_attrib,	fat_code_sel
f16s11	DW OFFSET open_dir,			fat_code_sel
f16s12	DW OFFSET close_dir,		fat_code_sel
f16s13	DW OFFSET read_dir,			fat_code_sel
f16s14	DW OFFSET open_file,		fat_code_sel
f16s15	DW OFFSET create_file,		fat_code_sel
f16s16	DW OFFSET close_file,		fat_code_sel
f16s17	DW OFFSET dupl_file,		fat_code_sel
f16s18	DW OFFSET get_ioctl_data,	fat_code_sel
f16s19	DW OFFSET get_file_size,	fat_code_sel
f16s20	DW OFFSET set_file_size,	fat_code_sel
f16s21	DW OFFSET get_file_time,	fat_code_sel
f16s22	DW OFFSET set_file_time,	fat_code_sel
f16s23	DW OFFSET read_file,		fat_code_sel
f16s24	DW OFFSET write_file,		fat_code_sel

fs32_name	DB 'FAT32',0

fs32_ctrl:
f32s00	DW OFFSET mount32,			fat_code_sel
f32s01	DW OFFSET dismount,			fat_code_sel
f32s02	DW OFFSET get_drive_info,	fat_code_sel
f32s03	DW OFFSET set_cur_dir,		fat_code_sel
f32s04	DW OFFSET get_cur_dir,		fat_code_sel
f32s05	DW OFFSET make_dir,			fat_code_sel
f32s06	DW OFFSET remove_dir,		fat_code_sel
f32s07	DW OFFSET delete_file,		fat_code_sel
f32s08	DW OFFSET rename_file,		fat_code_sel
f32s09	DW OFFSET get_file_attrib,	fat_code_sel
f32s10	DW OFFSET set_file_attrib,	fat_code_sel
f32s11	DW OFFSET open_dir,			fat_code_sel
f32s12	DW OFFSET close_dir,		fat_code_sel
f32s13	DW OFFSET read_dir,			fat_code_sel
f32s14	DW OFFSET open_file,		fat_code_sel
f32s15	DW OFFSET create_file,		fat_code_sel
f32s16	DW OFFSET close_file,		fat_code_sel
f32s17	DW OFFSET dupl_file,		fat_code_sel
f32s18	DW OFFSET get_ioctl_data,	fat_code_sel
f32s19	DW OFFSET get_file_size,	fat_code_sel
f32s20	DW OFFSET set_file_size,	fat_code_sel
f32s21	DW OFFSET get_file_time,	fat_code_sel
f32s22	DW OFFSET set_file_time,	fat_code_sel
f32s23	DW OFFSET read_file,		fat_code_sel
f32s24	DW OFFSET write_file,		fat_code_sel

init	PROC far
	push ds
	push es
	push fs
	push gs
	pushad
	mov bx,fat_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET fs12_name
	mov di,OFFSET fs12_ctrl
	RegisterFileSystem
;
	mov si,OFFSET fs16_name
	mov di,OFFSET fs16_ctrl
	RegisterFileSystem
;
	mov si,OFFSET fs32_name
	mov di,OFFSET fs32_ctrl
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
