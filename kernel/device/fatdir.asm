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
; FATDIR.ASM
; Directory handling for FAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME fatdir

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
INCLUDE ..\os\int.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\fs.inc
INCLUDE fat.inc

	.386p


fat_dir_struc	STRUC

fat_base		DB 8 DUP(?)
fat_ext			DB 3 DUP(?)
fat_attrib		DB ?
fat_case		DB ?
fat_cr_time_ms	DB ?
fat_cr_time		DW ?
fat_cr_date		DW ?
fat_acc_date	DW ?
fat_cluster_hi	DW ?
fat_time		DW ?
fat_date		DW ?
fat_cluster		DW ?
fat_file_size	DD ?

fat_dir_struc	ENDS

	extrn lock_sector:near
	extrn next_sector:near
	extrn allocate_cluster:near
	extrn free_cluster:near
	extrn next_cluster:near
	extrn link_cluster:near

InsertFirst	MACRO list
	local insert_empty
	local insert_used
	local insert_done

	push eax
	push ebx
;
	mov eax,fs:list
	or eax,eax
	je insert_empty

insert_used:
	mov ebx,es:[eax].dir_prev
	mov es:[eax].dir_prev,edi
	mov es:[ebx].dir_next,edi
	mov es:[edi].dir_prev,ebx
	mov es:[edi].dir_next,eax	
	jmp insert_done

insert_empty:
	mov es:[edi].dir_prev,edi
	mov es:[edi].dir_next,edi

insert_done:
	mov fs:list,edi
;
	pop ebx
	pop eax
			ENDM

InsertLast	MACRO list
	local insert_empty
	local insert_used
	local insert_done

	push eax
	push ebx
;
	mov eax,fs:list
	or eax,eax
	je insert_empty

insert_used:
	mov ebx,es:[eax].dir_prev
	mov es:[eax].dir_prev,edi
	mov es:[ebx].dir_next,edi
	mov es:[edi].dir_prev,ebx
	mov es:[edi].dir_next,eax	
	jmp insert_done

insert_empty:
	mov es:[edi].dir_prev,edi
	mov es:[edi].dir_next,edi
	mov fs:list,edi

insert_done:
;
	pop ebx
	pop eax
			ENDM

Remove MACRO list
	local remove_used
	local remove_empty
	local remove_done

	push eax
	push ebx
;
	mov eax,es:[edi].dir_next
	mov ebx,es:[edi].dir_prev
	mov es:[ebx].dir_next,eax
	mov es:[eax].dir_prev,ebx
	cmp eax,edi
	jne remove_used

remove_empty:
	mov fs:list,0
	jmp remove_done

remove_used:
	cmp edi,fs:list
	jne remove_done
	mov fs:list,eax

remove_done:
	pop ebx
	pop eax
			ENDM

code	SEGMENT byte public use16 'CODE'

	assume cs:code

char_tab:
ct00 DB	0,		0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct08 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct10 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct18 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct20 DB ' ',	'!',	0FFh,	'#',	'$',	'%',	'&',	27h
ct28 DB '(',	')',	0FFh,	0FFh,	0FFh,	'-',	'.',	0
ct30 DB '0',	'1',	'2',	'3',	'4',	'5',	'6',	'7'
ct38 DB '8',	'9',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct40 DB '@',	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct48 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct50 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct58 DB	'X',	'Y',	'Z',	0FFh,	0,		0FFh,	'^',	'_'
ct60 DB 60h,	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct68 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct70 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct78 DB 'X',	'Y',	'Z',	'{',	0FFh,	'}',	'~',	0FFh
ct80 DB	0FFh,	0FFh,	0FFh,	0FFh,	'é',	0FFh,	'è',	0FFh
ct88 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	'é',	'è'
ct90 DB	0FFh,	0FFh,	0FFh,	0FFh,	'ô',	0FFh,	0FFh,	0FFh
ct98 DB	0FFh,	'ô',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctA0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctA8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctB0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctB8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctC0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctC8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctD0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctD8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctE0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctE8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctF0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctF8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLLOCATE_DIR_HANDLE
;
;		DESCRIPTION:	Allocate a directory handle and initialize
;
;		PARAMETERS:		FS			Parent dir
;						EDI			Linear address of dir
;
;		RETURNS:		FS			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dir_handle	Proc near
	push bx
	push es
	push eax
	mov bx,fs
	mov eax,SIZE dir_data_struc
	AllocateSmallGlobalMem
	mov ax,es
	mov fs,ax
	pop eax
	pop es
;
	InitReadWriteSection fs:dir_section
	mov fs:dir_dir_ptr,0
	mov fs:dir_file_ptr,0
	mov fs:dir_deleted_ptr,0
	mov fs:dir_free_ptr,0
	mov fs:dir_usage,0
	mov fs:dir_parent,bx
	mov fs:dir_parent_entry,edi
	pop bx
	ret
allocate_dir_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DIR_NAME
;
;		DESCRIPTION:	Init directory entry name
;
;		PARAMETERS:		ESI			Linear address of disk data
;						EDI			Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dir_name	Proc near
	push dx
	push esi
	push edi
;
	xor dl,dl
	mov ecx,8
	add esi,OFFSET fat_base
	add edi,OFFSET dir_name
init_name_base_loop:
	lods byte ptr es:[esi]
	cmp al,' '
	je init_name_base_ok
	inc dl
	stos byte ptr es:[edi]
	loop init_name_base_loop
	inc esi
init_name_base_ok:
	dec esi
	add esi,ecx
	mov al,'.'
	inc dl
	stos byte ptr es:[edi]
	mov ecx,3
init_name_ext_loop:
	lods byte ptr es:[esi]
	cmp al,' '
	je init_name_ext_ok
	inc dl
	stos byte ptr es:[edi]
	loop init_name_ext_loop
init_name_ext_ok:
	mov al,es:[edi-1]
	cmp al,'.'
	jne init_name_add_zero
	dec dl
	dec edi
init_name_add_zero:
	xor al,al
	stos byte ptr es:[edi]
	pop edi
	mov es:[edi].dir_name_size,dl
	pop esi
	pop dx
	ret
init_dir_name	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DIR_TIME
;
;		DESCRIPTION:	Init directory time & data
;
;		PARAMETERS:		ESI			Linear address of disk data
;						EDI			Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dir_time	Proc near
	mov dx,es:[esi].fat_date
	mov ax,dx
	shr dx,9
	add dx,1980
	mov cx,ax
	shr cx,5
	mov ch,cl
	and ch,0Fh
	mov cl,al
	and cl,1Fh
	mov bx,es:[esi].fat_time
	mov ax,bx
	shr bx,11
	mov bh,bl
	shr ax,5
	and al,3Fh
	mov bl,al
	mov ax,es:[esi].fat_time
	mov ah,al
	add ah,ah
	and ah,3Fh
	TimeToBinary
	mov es:[edi].dir_time,eax
	mov es:[edi].dir_time+4,edx
	ret
init_dir_time	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_DIR_ENTRY
;
;		DESCRIPTION:	Allocate dir entry
;
;		RETURNS:		EDI			Linear address of dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dir_entry	Proc near
	push ax
	push edx
	mov eax,SIZE dir_entry_struc
	AllocateSmallLinear
	mov edi,edx
	pop edx
	pop ax
	ret
allocate_dir_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_DIR_ENTRY
;
;		DESCRIPTION:	Free dir entry
;
;		PARAMETERS:		EDI			Linear address of dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dir_entry	Proc near
	push ecx
	push edx
	mov ecx,SIZE dir_entry_struc
	mov edx,edi
	FreeLinear
	pop edx
	pop ecx
	ret
free_dir_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DIR_ENTRY
;
;		DESCRIPTION:	Allocate & init a dir entry
;
;		PARAMETERS:		AL			Drive #
;						EDX			Sector
;						ESI			Linear address of disk-data
;						FS			Dir data
;
;		RETURNS:		EDI			Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dir_entry	Proc near
	push eax
	push bx
	push ecx
	push edx
;
	call allocate_dir_entry
	mov es:[edi].dir_drive,al
	mov es:[edi].dir_sector,edx
	mov ax,si
	and ax,01FFh
	mov es:[edi].dir_offset,ax
	mov es:[edi].dir_handle,0
	mov al,es:[esi].fat_attrib
	mov es:[edi].dir_attrib,al
	cmp ds:fat_type,fat32
	je init_dir_entry_cluster32
;
	movzx eax,es:[esi].fat_cluster
	jmp init_dir_entry_cluster_ok

init_dir_entry_cluster32:
	mov ax,es:[esi].fat_cluster_hi
	shl eax,16
	mov ax,es:[esi].fat_cluster

init_dir_entry_cluster_ok:	
	mov es:[edi].dir_cluster,eax
	mov eax,es:[esi].fat_file_size
	mov es:[edi].dir_file_size,eax
;
	call init_dir_name
	call init_dir_time
;
	pop edx
	pop ecx
	pop bx
	pop eax
	ret
init_dir_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LOCK_DIR_ENTRY
;
;		DESCRIPTION:	Lock dir entry
;
;		PARAMETERS:		EDI			Linear address of disk-data
;
;		RETURNS:		ESI			Linear address of dir
;						EBX			Sector handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lock_dir_entry

lock_dir_entry	Proc near
	push ax
	push edx
	mov al,es:[edi].dir_drive
	mov edx,es:[edi].dir_sector
	call lock_sector
	jc lock_dir_done	
	or si,es:[edi].dir_offset
	clc
lock_dir_done:
	pop edx
	pop ax
	ret
lock_dir_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_DIR_NAME
;
;		DESCRIPTION:	Update name on disk
;
;		PARAMETERS:		ESI			Linear address of disk-data
;						EDI			Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public update_dir_name

update_dir_name	Proc near
	push ax
	push ecx
	push esi
	push edi
;
	xchg esi,edi
	add esi,OFFSET dir_name
	add edi,OFFSET fat_base
	mov al,es:[esi]
	cmp al,'.'
	jne update_name_base

update_name_spec:
	inc esi
	mov ecx,10
	stos byte ptr es:[edi]
	lods byte ptr es:[esi]
	or al,al
	je update_name_pad
	cmp al,'.'
	stc
	jne update_name_done
	dec cx
	stos byte ptr es:[edi]
	lods byte ptr es:[esi]
	or al,al	
	je update_name_pad
	stc
	jmp update_name_done
	
update_name_base:
	mov ecx,8
update_name_base_loop:
	lods byte ptr es:[esi]
	or al,al
	je update_name_ext
	cmp al,'.'
	je update_name_ext
	stos byte ptr es:[edi]
	loop update_name_base_loop
	lods byte ptr es:[esi]
	or al,al
	je update_name_ext
	cmp al,'.'
	je update_name_ext
	stc
	jmp update_name_done

update_name_ext:
	mov ah,al
	mov al,' '
	rep stos byte ptr es:[edi]
	mov ecx,3
	mov al,ah
	or al,al
	je update_name_pad
update_name_ext_loop:
	lods byte ptr es:[esi]
	or al,al
	je update_name_pad
	stos byte ptr es:[edi]
	loop update_name_ext_loop
	lods byte ptr es:[esi]
	or al,al
	clc
	je update_name_done

update_name_pad:
	mov al,' '
	rep stos byte ptr es:[edi]
	clc

update_name_done:
	pop edi
	pop esi
	pop ecx
	pop ax
	ret
update_dir_name	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_DIR_TIME
;
;		DESCRIPTION:	Update time on disk
;
;		PARAMETERS:		ESI			Linear address of disk data
;						EDI			Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public update_dir_time

update_dir_time	Proc near
	push eax
	push bx
	push cx
	push edx
;
	mov eax,es:[edi].dir_time
	mov edx,es:[edi].dir_time+4
	BinaryToTime
	shl cl,3
	shr cx,3
	sub dx,1980
	mov dh,dl
	shl dh,1
	xor dl,dl
	or dx,cx
	mov al,ah
	shr al,1
	shl bl,2
	shl bx,3
	or bl,al
	mov es:[esi].fat_time,bx
	mov es:[esi].fat_date,dx
;
	pop edx
	pop cx
	pop bx
	pop eax
	ret
update_dir_time	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_DIR_ENTRY
;
;		DESCRIPTION:	Update dir entry on disk
;
;		PARAMETERS:		ESI			Linear address of disk data
;						EDI			Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public update_dir_entry

update_dir_entry	Proc near
	push eax
	mov al,es:[edi].dir_attrib
	mov es:[esi].fat_attrib,al
	mov eax,es:[edi].dir_cluster
	mov es:[esi].fat_cluster,ax
	shr eax,16
	mov es:[esi].fat_cluster_hi,ax
	mov eax,es:[edi].dir_file_size
	mov es:[esi].fat_file_size,eax
	pop eax
	ret
update_dir_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_DIR_NAME
;
;		DESCRIPTION:	Set name of dir entry
;
;		PARAMETERS:		GS:EDX	Name of entry
;						ESI		Linear address of disk data
;						EDI		Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public set_dir_name

set_dir_name	PROC near
	push ax
	push bx
	push ecx
;
	push edx
	mov bx,OFFSET char_tab
	xor ecx,ecx
set_dir_name_size_loop:
	mov al,gs:[edx]
	inc edx
	xlat byte ptr cs:char_tab
	or al,al
	jz set_dir_name_size_ok
	add al,1
	jc set_dir_name_done
	inc ecx
	jmp set_dir_name_size_loop

set_dir_name_size_ok:
	pop edx
	push edx
	or ecx,ecx
	stc
	jz set_dir_name_done
	cmp ecx,15
	cmc
	jc set_dir_name_done
	push edi
	mov es:[edi].dir_name_size,cl
	add edi,OFFSET dir_name
set_dir_name_loop:
	mov al,gs:[edx]
	inc edx
	xlat byte ptr cs:char_tab
	stos byte ptr es:[edi]
	loop set_dir_name_loop
	xor al,al
	stos byte ptr es:[edi]
	pop edi
	call update_dir_name
set_dir_name_done:
	pop edx
;
	pop ecx
	pop bx
	pop ax
	ret
set_dir_name	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_DIR_TIME
;
;		DESCRIPTION:	Set time & date of dir entry
;
;		PARAMETERS:		EDX:EAX	Time
;						ESI		Linear address of disk data
;						EDI		Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dir_time	PROC near
	mov es:[edi].dir_time,eax
	mov es:[edi].dir_time+4,edx
	call update_dir_time
	ret
set_dir_time	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MODIFY_FILE_ENTRY
;
;		DESCRIPTION:	Update file size and update on disk
;
;		PARAMETERS:		EDI		Linear address of dir
;						ECX		File size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public modify_file_entry

modify_file_entry	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push esi
;
	GetTime
	mov es:[edi].dir_time,eax
	mov es:[edi].dir_time+4,edx
	mov es:[edi].dir_file_size,ecx
	call lock_dir_entry
	jc modify_file_entry_done
	call update_dir_entry
	ModifySector
	UnlockSector
	clc
modify_file_entry_done:
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
modify_file_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_DIR_ENTRY
;
;		DESCRIPTION:	Allocate and init an empty directory node
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						GS:EDX	Name of entry
;
;		RETURNS:		EBX		Sector handle
;						ESI		Linear address of disk data
;						EDI		Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_dir_entry	PROC near
	mov edi,fs:dir_deleted_ptr
	or edi,edi
	jz create_dir_try_free
	Remove dir_deleted_ptr
	jmp create_dir_init

create_dir_try_free:
	mov edi,fs:dir_free_ptr
	or edi,edi
	jz create_dir_new_block
	Remove dir_free_ptr
	jmp create_dir_init

create_dir_new_block:
	call extend_dir
	jnc create_dir_try_free
	jmp create_dir_done

create_dir_init:
	call lock_dir_entry
	jc create_dir_fail
	call set_dir_name
	jc create_dir_unlock
	push eax
	push edx
	GetTime
	call set_dir_time
	pop edx
	pop eax
	clc
	jmp create_dir_done

create_dir_unlock:
	UnlockSector

create_dir_fail:
	mov al,es:[edi]
	or al,al
	je create_dir_fail_free

create_dir_fail_deleted:
	InsertFirst dir_deleted_ptr
	xor edi,edi
	stc
	jmp create_dir_done

create_dir_fail_free:
	InsertFirst dir_free_ptr
	xor edi,edi
	stc

create_dir_done:
	ret
create_dir_entry	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_DIR_ENTRY
;
;		DESCRIPTION:	Process one dir entry, add if used
;
;		PARAMETERS:		AL			Drive #
;						ESI			Linear address of disk data
;						FS			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_dir_entry	Proc near
	push edi
	push eax
;
	call init_dir_entry
	mov al,es:[esi].fat_base
	or al,al
	je add_free_entry
	cmp al,0E5h
	je add_deleted_entry
;
	mov al,es:[esi].fat_attrib
	cmp al,0Fh
	je add_entry_done
;
	test al,10h
	jz add_file_entry

	InsertLast dir_dir_ptr
	jmp add_entry_done

add_file_entry:
	InsertLast dir_file_ptr
	jmp add_entry_done

add_deleted_entry:
	InsertLast dir_deleted_ptr
	jmp add_entry_done

add_free_entry:
	InsertLast dir_free_ptr

add_entry_done:
	pop eax
	pop edi
	ret
add_dir_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			READ_ROOT_DIR
;
;		DESCRIPTION:	Buffer root directory
;
;		PARAMETERS:		AL			Drive
;						FS			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_root_dir	Proc near
	push ebx
	push cx
	push edx
	push esi
;
	mov cx,ds:root_entries
	shr cx,4
	mov edx,ds:root_sector
read_root_sector_loop:
	call lock_sector
	jc read_root_dir_next

read_root_entry_loop:
	call add_dir_entry
	add si,20h
	test si,1FFh
	jnz read_root_entry_loop

read_root_dir_next:
	UnlockSector			
	inc edx
	loop read_root_sector_loop
;
	pop esi
	pop edx
	pop cx
	pop ebx
	ret
read_root_dir	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			READ_DIR
;
;		DESCRIPTION:	Buffer a sub-directory
;
;		PARAMETERS:		AL			Drive
;						EDX			Start sector
;						FS			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_dir	Proc near
	push ebx
	push cx
	push edx
	push esi
;
read_dir_sector_loop:
	call lock_sector
	jc read_dir_next

read_dir_entry_loop:
	call add_dir_entry
	add si,20h
	test si,1FFh
	jnz read_dir_entry_loop

read_dir_next:
	UnlockSector			
	call next_sector
	jnc read_dir_sector_loop
;
	mov edx,fs:dir_dir_ptr
	mov es:[edx].dir_handle,fs
	mov edx,es:[edx].dir_next
	mov cx,fs:dir_parent
	mov es:[edx].dir_handle,cx
;
	pop esi
	pop edx
	pop cx
	pop ebx
	ret
read_dir	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EXTEND_DIR
;
;		DESCRIPTION:	Extern dir
;
;		PARAMETERS:		FS			Dir selector
;
;		RETURNS:		EDX			Cluster
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extend_dir	Proc near
	push eax
	push ebx
	push ecx
	push esi
	push edi
;
	mov al,ds:drive_nr
	mov edi,fs:dir_parent_entry
	mov edx,es:[edi].dir_cluster
	or edx,edx
	jnz extend_dir_find_loop
	call allocate_cluster
	jc extend_dir_done
	mov es:[edi].dir_cluster,edx
	jmp extend_dir_init

extend_dir_find_loop:
	mov ecx,edx
	call next_cluster
	jnc extend_dir_find_loop
;
	call allocate_cluster
	jc extend_dir_done
	xchg ecx,edx
	call link_cluster
	xchg ecx,edx
	
extend_dir_init:
	mov edi,edx
	sub edx,2
	mov cl,ds:fat_cluster_shift
	shl edx,cl
	add edx,ds:start_sector
	mov bx,1
	shl bx,cl
	mov cx,bx
	push edi

extend_dir_loop:
	push ax
	push cx
	push edx
	call lock_sector
	jc extend_dir_try_next
;
	mov edi,esi
	mov ecx,80h
	xor eax,eax
	rep stos dword ptr es:[edi]
;
	mov al,ds:drive_nr
extend_dir_entry_loop:
	call add_dir_entry
	add si,20h
	test si,1FFh
	jnz extend_dir_entry_loop
;
	ModifySector
	UnlockSector

extend_dir_try_next:
	pop edx
	pop cx
	pop ax
	inc edx
	loop extend_dir_loop
	pop edx

extend_dir_done:
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop eax
	ret
extend_dir	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_DIR_HANDLE
;
;		DESCRIPTION:	Create dir handle
;
;		PARAMETERS:		AL			Drive
;						FS			Parent dir selector
;						EDI			Linear address of dir
;						EBX			Sector handle
;						ESI			Linear address of disk data
;
;		RETURNS:		FS			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public create_dir_handle

prev_dir	DB '..',0
curr_dir	DB '.',0

create_dir_handle	PROC near
	push ax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	push fs
	push ebx
	push esi
	push edi
	mov ecx,fs:dir_parent_entry
	or ecx,ecx
	jz create_dir_handle_parent_ok
	mov ecx,es:[ecx].dir_cluster
create_dir_handle_parent_ok:
	push ecx
	call allocate_dir_handle
	call extend_dir
	jc create_dir_handle_unlock
;
	push edx	
	mov ax,cs
	mov gs,ax
;
	mov edx,OFFSET curr_dir
	call insert_dir_node
	pop edx
	mov es:[edi].dir_cluster,edx
	call update_dir_entry
	ModifySector
	UnlockSector
;
	mov edx,OFFSET prev_dir
	call insert_dir_node
	pop edx
	mov es:[edi].dir_cluster,edx
	call update_dir_entry
	ModifySector
	UnlockSector
;
	mov edi,fs:dir_dir_ptr
	mov es:[edi].dir_handle,fs
	mov edi,es:[edi].dir_next
	mov dx,fs:dir_parent
	mov es:[edi].dir_handle,dx
;
	pop edi
	pop esi
	pop ebx
	mov es:[edi].dir_handle,fs
	pop fs
	call update_dir_entry
	ModifySector
	UnlockSector
	clc
	jmp create_dir_handle_done

create_dir_handle_unlock:
	pop edx
	pop edi
	pop esi
	pop ebx
	pop fs
	ModifySector
	UnlockSector
	stc

create_dir_handle_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ax
	ret
create_dir_handle	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_DIR_HANDLE
;
;		DESCRIPTION:	Delete dir handle
;
;		PARAMETERS:		AL			Drive
;						FS			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public delete_dir_handle

delete_dir_handle	PROC near
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov edi,fs:dir_file_ptr
	or edi,edi
	stc
	jnz delete_dir_done
	mov edi,fs:dir_dir_ptr
	mov edi,es:[edi].dir_next
	mov edi,es:[edi].dir_next
	cmp edi,fs:dir_dir_ptr
	stc
	jnz delete_dir_done
;
	mov edi,fs:dir_dir_ptr
	Remove dir_dir_ptr
	call free_dir_entry
;
	mov edi,fs:dir_dir_ptr
	Remove dir_dir_ptr
	call free_dir_entry

delete_dir_deleted_loop:
	mov edi,fs:dir_deleted_ptr
	or edi,edi
	jz delete_dir_free_loop
	Remove dir_deleted_ptr
	call free_dir_entry
	jmp delete_dir_deleted_loop

delete_dir_free_loop:
	mov edi,fs:dir_free_ptr
	or edi,edi
	jz delete_dir_free_handle
	Remove dir_free_ptr
	call free_dir_entry
	jmp delete_dir_free_loop

delete_dir_free_handle:
	push es
	mov ax,fs
	mov es,ax
	mov edi,fs:dir_parent_entry
	mov fs,fs:dir_parent
	FreeMem
	pop es
;
	xor edx,edx
	xchg edx,es:[edi].dir_cluster
	call remove_dir_node
;
	mov ecx,edx
	mov al,ds:drive_nr
delete_dir_cluster_loop:
	call next_cluster
	jc delete_dir_chain_done
	xchg ecx,edx
	call free_cluster
	mov edx,ecx
	jmp delete_dir_cluster_loop

delete_dir_chain_done:
	mov edx,ecx
	call free_cluster
	clc
		
delete_dir_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
delete_dir_handle	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_DIR
;
;		DESCRIPTION:	Read and buffer dir
;
;		PARAMETERS:		AL			Drive
;						EDX			Start cluster (0 for root dir)
;						FS			Parent dir selector
;						EDI			Linear address of dir
;
;		RETURNS:		FS			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_dir	PROC near
	call allocate_dir_handle
;
	or edx,edx
	jnz open_subdir
;
	cmp ds:fat_type,fat32
	jne open_root

open_root32:
	push ecx
	push edx
;
	mov edx,ds:root_sector
	call read_dir
;
	pop ecx
	pop edx
	jmp open_dir_done

open_subdir:
	push ecx
	push edx
;
	sub edx,2
	mov cl,ds:fat_cluster_shift
	shl edx,cl
	add edx,ds:start_sector
	call read_dir
	pop ecx
	pop edx
	jmp open_dir_done

open_root:
	mov fs:dir_parent,0
	mov fs:dir_parent_entry,0
	call read_root_dir

open_dir_done:
	ret
open_dir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSERT_DIR_NODE
;
;		DESCRIPTION:	Insert a directory node into directory
;
;		PARAMETERS:		GS:EDX	Directory name
;						FS		Dir selector to insert into
;
;		RETURNS:		EDI		Linear address of dir
;						EBX		Sector handle
;						ESI		Linear address of disk data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public insert_dir_node

insert_dir_node	PROC near
	call create_dir_entry
	jc insert_dir_node_done
	InsertLast dir_dir_ptr
	mov es:[edi].dir_attrib,10h
	mov es:[edi].dir_cluster,0
	mov es:[edi].dir_file_size,0
	clc
insert_dir_node_done:
	ret
insert_dir_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSERT_FILE_NODE
;
;		DESCRIPTION:	Insert a file node into directory
;
;		PARAMETERS:		GS:EDX	File name
;						FS		Dir selector to insert into
;
;		RETURNS:		EDI		Linear address of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public insert_file_node

insert_file_node	PROC near
	push ebx
	push esi
;
	call create_dir_entry
	jc insert_file_node_done
	InsertLast dir_file_ptr
	mov es:[edi].dir_attrib,20h
	mov es:[edi].dir_cluster,0
	mov es:[edi].dir_file_size,0
	call update_dir_entry
	ModifySector
	UnlockSector
	clc
insert_file_node_done:
	pop esi
	pop ebx
	ret
insert_file_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE_DIR_NODE
;
;		DESCRIPTION:	Remove a directory node.
;
;		PARAMETERS:		FS		Dir selector of directory
;						EDI		Linear address of dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_dir_node	PROC near
	push ebx
	push esi
;
	Remove dir_dir_ptr
	call lock_dir_entry
	jc remove_dir_insert
	mov es:[esi].fat_base,0E5h
	ModifySector
	UnlockSector
remove_dir_insert:
	InsertLast dir_deleted_ptr
;
	pop esi
	pop ebx
	ret
remove_dir_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE_FILE_NODE
;
;		DESCRIPTION:	Remove a file
;
;		PARAMETERS:		FS		Dir selector of directory
;						EDI		Linear address of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public remove_file_node

remove_file_node	PROC near
	push ebx
	push esi
;
	Remove dir_file_ptr
	call lock_dir_entry
	jc remove_file_insert
	mov es:[esi].fat_base,0E5h
	ModifySector
	UnlockSector
remove_file_insert:
	InsertLast dir_deleted_ptr
;
	pop esi
	pop ebx
	ret
remove_file_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_DIR_HANDLE
;
;		DESCRIPTION:	Go down into directory.
;
;		PARAMETERS:		EDI		Linear address of dir to load
;						FS		Current dir selector
;
;		RETURNS:		FS		Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_dir_handle	Proc near
	push ax
	push edx
;
	mov dx,es:[edi].dir_handle
	or dx,dx
	jnz open_dir_handle_done
	mov al,ds:drive_nr
	mov edx,es:[edi].dir_cluster
	call open_dir
	mov es:[edi].dir_handle,fs	
	mov dx,fs
open_dir_handle_done:
	mov fs,dx
	pop edx
	pop ax
	ret
open_dir_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PARSE_DIR
;
;		DESCRIPTION:	Parse a dir path
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						GS:EDX	Pathname to parse
;
;		RETURNS:		GS:EDX	Remaining part of path
;						FS		Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public parse_dir

parse_dir	Proc near
	push ax
	push bx
	push cx
	push edi
;
	push edx
	mov ax,flat_sel
	mov es,ax
	mov al,ds:drive_nr
	GetCurDirPtr
	or dx,dx
	jnz parse_curr_dir_ok
	mov dx,ds:drive_root_handle
	or dx,dx
	jnz parse_root_open
	xor dx,dx
	call open_dir
	mov dx,fs
	mov ds:drive_root_handle,dx
parse_root_open:
	SetCurDirPtr
parse_curr_dir_ok:
	mov fs,dx
	pop edx
	mov bx,OFFSET char_tab
	mov al,gs:[edx]
	xlat byte ptr cs:char_tab
	or al,al
	jnz parse_dir_tree_loop
	mov al,gs:[edx]
	or al,al
	je parse_dir_done
	mov fs,ds:drive_root_handle
	inc edx
parse_dir_tree_loop:
	mov edi,fs:dir_dir_ptr
	or edi,edi
	jz parse_dir_done
parse_dir_entry_loop:
	movzx cx,es:[edi].dir_name_size
	push edi
	push edx
	add edi,OFFSET dir_name
parse_dir_name_loop:
	mov al,gs:[edx]
	xlat byte ptr cs:char_tab
	mov ah,al
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	cmp al,ah
	jne parse_dir_next
	inc edi
	inc edx
	loop parse_dir_name_loop
	mov al,gs:[edx]
	xlat byte ptr cs:char_tab
	or al,al
	jnz parse_dir_next
	pop edi
	pop edi
	call open_dir_handle
	mov al,gs:[edx]
	cmp al,'\'
	je parse_dir_slash_found
;
	cmp al,'/'
	jne parse_dir_tree_loop

parse_dir_slash_found:
	inc edx
	jmp parse_dir_tree_loop
parse_dir_next:
	pop edx
	pop edi
	mov edi,es:[edi].dir_next
	cmp edi,fs:dir_dir_ptr
	jne parse_dir_entry_loop
parse_dir_done:
	pop edi
	pop cx
	pop bx
	pop ax
	ret
parse_dir	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PARSE_FILE
;
;		DESCRIPTION:	Parse a file path
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						GS:EDX	Pathname to parse
;						FS		Dir selector
;
;		RETURNS:		GS:EDX	Remaining part of pathname 
;						EDI		Linear address of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public parse_file

parse_file	Proc near
	push ax
	push bx
	push cx
	push edx
;
	mov bx,OFFSET char_tab
	mov edi,fs:dir_file_ptr
	or edi,edi
	stc
	jz parse_file_complete
parse_file_entry_loop:
	movzx cx,es:[edi].dir_name_size	
	push edi
	push edx
	add edi,OFFSET dir_name
parse_file_name_loop:
	mov al,gs:[edx]
	xlat byte ptr cs:char_tab
	mov ah,al
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	cmp al,ah
	jne parse_file_next
	inc edi
	inc edx
	loop parse_file_name_loop
;
	mov al,gs:[edx]
	or al,al
	jnz parse_file_next
;
	pop edi
	pop edi
	clc
	jmp parse_file_complete

parse_file_next:
	pop edx
	pop edi
	mov edi,es:[edi].dir_next
	cmp edi,fs:dir_file_ptr
	jne parse_file_entry_loop
	stc

parse_file_complete:
	pop edx
	pop cx
	pop bx
	pop ax
	ret
parse_file	Endp

code	ENDS

	END

