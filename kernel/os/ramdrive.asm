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
; RAMDRIVE.ASM
; Preloadable in-system drive (z:) support.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ramdrive

GateSize = 16

INCLUDE driver.def
INCLUDE protseg.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE system.def
INCLUDE system.inc

attr_read_only		EQU 1
attr_hidden			EQU 2
attr_system			EQU 4
attr_volume			EQU 8
attr_dir			EQU 10h
attr_arcive			EQU 20h

MAX_DRIVES		EQU 4

dev_name		EQU 8
dev_param		EQU 90h
dev_next		EQU 0E0h
dev_type		EQU 0E4h
dev_ip			EQU 0FAh

dir_entry_struc	STRUC

entry_ptr		DD ?
entry_size		DW ?
entry_sel		DW ?
entry_data		DD ?
entry_type		DB ?
entry_attrib	DB ?
entry_data_size	DD ?
entry_time		DD ?,?
entry_name_size	DB ?
entry_name		DB ?

dir_entry_struc	ENDS

handle_seg	STRUC

handle_usage	DW ?
handle_ptr		DD ?

handle_seg	ENDS

dir_data_struc	STRUC

dir_dir_ptr		DD ?
dir_file_ptr	DD ?
dir_sel			DW ?

dir_data_struc	ENDS

fs_data_seg	STRUC

drive_count		DW ?
drive_arr		DW 26 DUP(?)
drive_sel_arr	DW MAX_DRIVES DUP(?)
 
fs_data_seg	ENDS

drive_data_seg	STRUC

drive_list_ptr	DD ?
drive_root_ptr	DD ?
drive_free_ptr	DD ?
drive_nr		DB ?

drive_data_seg	ENDS



	.386p

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

prev_dir	DB '..',0
curr_dir	DB '.',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_LIST_BLOCK
;
;		DESCRIPTION:	Allocate list block
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_list_block	PROC near
	push eax
	push ecx
	push edx
	mov eax,1000h
	AllocateBigLinear
	mov ds:drive_list_ptr,edx
	pop edx
	pop ecx
	pop eax
	ret
allocate_list_block	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_INDEX_BLOCK
;
;		DESCRIPTION:	Allocate index block
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES		FLAT SEL
;
;		RETURNS:		EAX		INDEX BLOCK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_index_block	PROC near
	push edx
	mov eax,ds:drive_free_ptr
	or eax,eax
	jnz allocate_index_block_done
	mov edx,ds:drive_list_ptr
	test dx,0FFFh
	jnz allocate_index_list_not_full
	call allocate_list_block
allocate_index_list_not_full:
	push ecx
	mov eax,1000h
	AllocateBigLinear
	pop ecx
	mov eax,ds:drive_list_ptr
allocate_index_init_loop:
	mov es:[eax+4],edx
	add edx,200h
	add eax,8
	mov es:[eax-8],eax
	test dx,0FFFh
	jnz allocate_index_init_loop
	mov edx,ds:drive_free_ptr
	mov es:[eax-8],edx
	xchg eax,ds:drive_list_ptr
allocate_index_block_done:
	mov edx,es:[eax]
	mov ds:drive_free_ptr,edx
	pop edx
	ret
allocate_index_block	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_INDEX_BLOCK
;
;		DESCRIPTION:	Free index block
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES		FLAT SEL
;						EAX		INDEX BLOCK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_index_block	PROC near
	push edx
	mov edx,ds:drive_free_ptr
	mov es:[eax],edx
	mov ds:drive_free_ptr,eax
	pop edx
	ret
free_index_block	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_DIR_ENTRY
;
;		DESCRIPTION:	Create empty directory entry
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES:EDI	NAME OF ENTRY
;
;		RETURNS:		EDX		LOGICAL ADDRESS OF DIR ENTRY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_dir_entry	PROC near
	push ds
	push es
	push eax
	push bx
	push ecx
	push esi
	push edi
;
	mov bx,OFFSET char_tab
	mov esi,edi
	mov ax,es
	mov ds,ax
	xor ecx,ecx
create_dir_entry_size_loop:
	lods byte ptr [esi]
	xlat byte ptr cs:char_tab
	or al,al
	jz create_dir_entry_size_ok
	add al,1
	jc create_dir_entry_done
	inc ecx
	jmp create_dir_entry_size_loop
create_dir_entry_size_ok:
	mov esi,edi
	mov ax,flat_sel
	mov es,ax
	mov eax,ecx
	add eax,OFFSET entry_name
	AllocateSmallLinear
	mov edi,edx
	mov es:[edi].entry_ptr,0
	mov es:[edi].entry_sel,0
	mov es:[edi].entry_size,ax
	mov es:[edi].entry_name_size,cl
	add edi,OFFSET entry_name
	rep movs byte ptr es:[edi],[esi]
	clc
create_dir_entry_done:
;
	pop edi
	pop esi
	pop ecx
	pop bx
	pop eax
	pop es
	pop ds
	ret
create_dir_entry	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSERT_DIR_NODE
;
;		DESCRIPTION:	Insert a directory node
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES:EDI	DIRECTORY NAME
;						EDX		DIRECTORY TO INSERT INTO
;
;		RETURNS:		EAX		LOGICAL ADDRESS OF DIR NODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_dir_node	PROC near
	push es
	push ecx
;
	push es
	mov ax,flat_sel
	mov es,ax
	mov eax,es:[edx].dir_dir_ptr
	or eax,eax
	jz insert_dir_node_empty
insert_dir_node_loop:
	mov ecx,eax
	mov eax,es:[eax].entry_ptr
	or eax,eax	
	jnz insert_dir_node_loop
	pop es
	push edx
	call create_dir_entry
	jc insert_dir_node_done
	mov ax,flat_sel
	mov es,ax
	mov eax,edx
	pop edx
	mov es:[ecx].entry_ptr,eax
	jmp insert_dir_node_init
insert_dir_node_empty:
	pop es
	push edx
	call create_dir_entry
	jc insert_dir_node_done
	mov ax,flat_sel
	mov es,ax
	mov eax,edx
	pop edx
	mov es:[edx].dir_dir_ptr,eax
insert_dir_node_init:
	push edx
	mov ecx,eax
	GetTime
	mov es:[ecx].entry_ptr,0
	mov es:[ecx].entry_type,0
	mov es:[ecx].entry_attrib,attr_dir
	mov es:[ecx].entry_time,eax
	mov es:[ecx+4].entry_time,edx
	mov es:[ecx].entry_data_size,0
	mov eax,ecx
	clc
insert_dir_node_done:
	pop edx
;
	pop ecx
	pop es
	ret
insert_dir_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSERT_FILE_NODE
;
;		DESCRIPTION:	Insert a file node
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES:EDI	FILE NAME
;						EDX		DIRECTORY TO INSERT INTO
;
;		RETURNS:		EAX		LOGICAL ADDRESS OF FILE NODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_file_node	PROC near
	push es
	push ecx
;
	push es
	mov ax,flat_sel
	mov es,ax
	mov eax,es:[edx].dir_file_ptr
	or eax,eax
	jz insert_file_node_empty
insert_file_node_loop:
	mov ecx,eax
	mov eax,es:[eax].entry_ptr
	or eax,eax	
	jnz insert_file_node_loop
	pop es
	push edx
	call create_dir_entry
	jc insert_file_node_done
	mov ax,flat_sel
	mov es,ax
	mov eax,edx
	pop edx
	mov es:[ecx].entry_ptr,eax
	jmp insert_file_node_init
insert_file_node_empty:
	pop es
	push edx
	call create_dir_entry
	jc insert_file_node_done
	mov ax,flat_sel
	mov es,ax
	mov eax,edx
	pop edx
	mov es:[edx].dir_file_ptr,eax
insert_file_node_init:
	push edx
	mov ecx,eax
	GetTime
	mov es:[ecx].entry_ptr,0
	mov es:[ecx].entry_type,0
	mov es:[ecx].entry_attrib,0
	mov es:[ecx].entry_time,eax
	mov es:[ecx+4].entry_time,edx
	mov es:[ecx].entry_data_size,0
	mov eax,ecx
	clc
insert_file_node_done:
	pop edx
;
	pop ecx
	pop es
	ret
insert_file_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE_DIR_NODE
;
;		DESCRIPTION:	Remove a directory node
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						EDX		DIRECTORY TO REMOVE FROM
;						EAX		LOGICAL ADDRESS OF DIR NODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_dir_node	PROC near
	push ds
	push eax
	push ecx
	push edx
	push esi
;
	mov esi,eax
	mov ax,flat_sel
	mov ds,ax
	mov eax,ds:[edx].dir_dir_ptr
	cmp eax,esi
	jne remove_dir_node_loop
	mov ecx,ds:[eax].entry_ptr
	mov ds:[edx].dir_dir_ptr,ecx	
	jmp remove_dir_node_destroy
remove_dir_node_loop:
	mov ecx,eax
	mov eax,ds:[eax].entry_ptr
	cmp eax,esi
	jnz remove_dir_node_loop
	mov edx,ds:[eax].entry_ptr
	mov ds:[ecx].entry_ptr,edx
remove_dir_node_destroy:
	mov edx,eax
	movzx ecx,ds:[edx].entry_size
	FreeLinear
	clc
remove_dir_node_done:
;
	pop esi
	pop edx
	pop ecx
	pop eax
	pop ds
	ret
remove_dir_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE_FILE_NODE
;
;		DESCRIPTION:	Remove a file node
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						EDX		DIRECTORY TO REMOVE FROM
;						EAX		LOGICAL ADDRESS OF FILE NODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_file_node	PROC near
	push ds
	push eax
	push ecx
	push edx
	push esi
;
	mov esi,eax
	mov ax,flat_sel
	mov ds,ax
	mov eax,ds:[edx].dir_file_ptr
	cmp eax,esi
	jne remove_file_node_loop
	mov ecx,ds:[eax].entry_ptr
	mov ds:[edx].dir_file_ptr,ecx	
	jmp remove_file_node_destroy
remove_file_node_loop:
	mov ecx,eax
	mov eax,ds:[eax].entry_ptr
	cmp eax,esi
	jnz remove_file_node_loop
	mov edx,ds:[eax].entry_ptr
	mov ds:[ecx].entry_ptr,edx
remove_file_node_destroy:
	mov edx,eax
	movzx ecx,ds:[edx].entry_size
	FreeLinear
	clc
remove_file_node_done:
;
	pop esi
	pop edx
	pop ecx
	pop eax
	pop ds
	ret
remove_file_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_DIR_NODE
;
;		DESCRIPTION:	Create a directory node
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						EBX		PARENT DIRECTORY
;
;		RETURNS:		EDX		LOGICAL ADDRESS OF DIR NODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_dir_node	PROC near
	push es
	push eax
	push edi
;
	mov eax,SIZE dir_data_struc
	AllocateSmallLinear
	mov ax,flat_sel
	mov es,ax
	mov es:[edx].dir_file_ptr,0
	mov es:[edx].dir_dir_ptr,0
	mov es:[edx].dir_sel,0
;
	push es
	mov ax,cs
	mov es,ax
	mov edi,OFFSET curr_dir
	call insert_dir_node
	pop es
	jc create_dir_curr_ok
	mov es:[eax].entry_data,edx
create_dir_curr_ok:
;
	or ebx,ebx
	je create_dir_prev_ok
	push es
	mov ax,cs
	mov es,ax
	mov edi,OFFSET prev_dir
	call insert_dir_node
	pop es
	jc create_dir_prev_ok
	mov es:[eax].entry_data,ebx
create_dir_prev_ok:
;
	pop edi
	pop eax
	pop es
	ret
create_dir_node	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PARSE_DIR
;
;		DESCRIPTION:	Parse pathname
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES:EDI	PATH NAME TO PARSE
;
;		RETURNS:		EDX		LOGICAL ADDRESS OF DIR NODE
;						ES:EDI	REMAINING PART OF PATH NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

parse_dir	Proc near
	push fs
	push ax
	push bx
	push cx
	push esi
	mov al,ds:drive_nr
	GetCurDirPtr
	or edx,edx
	jnz parse_curr_dir_ok
	mov edx,ds:drive_root_ptr
	SetCurDirPtr
parse_curr_dir_ok:
	mov bx,OFFSET char_tab
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	or al,al
	jnz parse_dir_start
	mov al,es:[edi]
	or al,al
	je parse_dir_done
	mov edx,ds:drive_root_ptr
	inc edi
parse_dir_start:
	push ds
	mov ax,flat_sel
	mov ds,ax
parse_dir_tree_loop:
	mov esi,ds:[edx].dir_dir_ptr
parse_dir_entry_loop:
	or esi,esi
	jz parse_dir_complete
	movzx cx,ds:[esi].entry_name_size	
	push esi
	push edi
	add esi,OFFSET entry_name
parse_dir_name_loop:
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	mov ah,al
	mov al,[esi]
	xlat byte ptr cs:char_tab
	cmp al,ah
	jne parse_dir_next
	inc esi
	inc edi
	loop parse_dir_name_loop
	pop esi
	pop esi
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	or al,al
	jnz parse_dir_next
	mov edx,ds:[esi].entry_data
	mov al,es:[edi]
	cmp al,'\'
	jne parse_dir_tree_loop
	inc edi
	jmp parse_dir_tree_loop
parse_dir_next:
	pop edi
	pop esi
	mov esi,ds:[esi].entry_ptr
	jmp parse_dir_entry_loop
parse_dir_complete:
	pop ds
parse_dir_done:
	pop esi
	pop cx
	pop bx
	pop ax
	pop fs
	ret
parse_dir	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PARSE_FILE
;
;		DESCRIPTION:	Parse pathname for a valid file
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						ES:EDI	PATH NAME TO PARSE
;						EDX		LOGICAL ADDRESS OF DIRECTORY
;
;		RETURNS:		EAX		LOGICAL ADDRESS OF FILE NODE
;						ES:EDI	REMAINING PART OF PATH NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

parse_file	Proc near
	push ds
	push bx
	push cx
	push edx
	push esi
	mov ax,flat_sel
	mov ds,ax
	mov bx,OFFSET char_tab
	mov esi,ds:[edx].dir_file_ptr
parse_file_entry_loop:
	or esi,esi
	stc
	jz parse_file_complete
	movzx cx,ds:[esi].entry_name_size	
	push esi
	push edi
	add esi,OFFSET entry_name
parse_file_name_loop:
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	mov ah,al
	mov al,[esi]
	xlat byte ptr cs:char_tab
	cmp al,ah
	jne parse_file_next
	inc esi
	inc edi
	loop parse_file_name_loop
	pop esi
	pop esi
	mov al,es:[edi]
	or al,al
	stc
	jnz parse_file_complete
	mov eax,esi
	clc
	jmp parse_file_complete
parse_file_next:
	pop edi
	pop esi
	mov esi,ds:[esi].entry_ptr
	jmp parse_file_entry_loop
parse_file_complete:
	pop esi
	pop edx
	pop cx
	pop bx
	pop ds
	ret
parse_file	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_FILE_HANDLE
;
;		DESCRIPTION:	Open file
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						EDX		LOGICAL ADDRESS OF DIR ENTRY
;
;		RETURNS:		BX		HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file_handle	Proc near
	push ds
	push es
	mov bx,flat_sel
	mov ds,bx
	mov bx,[edx].entry_sel
	or bx,bx
	jne open_file_handle_inc_usage
	push eax
	mov eax,SIZE handle_seg
	AllocateSmallGlobalMem
	pop eax
	mov es:handle_ptr,edx
	mov es:handle_usage,0
	mov bx,es
	mov [edx].entry_sel,bx
open_file_handle_inc_usage:
	mov es,bx
	inc es:handle_usage
	pop es
	pop ds
	ret
open_file_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_FILE_HANDLE
;
;		DESCRIPTION:	Close file
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						BX		HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_file_handle	Proc near
	push es
	mov es,bx
	sub es:handle_usage,1
	jnz close_file_handle_done
	push eax
	push dx
	mov eax,es:handle_ptr
	FreeMem
	mov dx,flat_sel
	mov es,dx
	mov es:[eax].entry_sel,0
	pop dx
	pop eax
close_file_handle_done:
	pop es
	ret
close_file_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_DIR_HANDLE
;
;		DESCRIPTION:	Open directory
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						EDX		LOGICAL ADDRESS OF DIRECTORY
;
;		RETURNS:		BX		HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_dir_handle	Proc near
	push ds
	push es
	mov bx,flat_sel
	mov ds,bx
	mov bx,[edx].dir_sel
	or bx,bx
	jne open_dir_handle_inc_usage
	push eax
	mov eax,SIZE handle_seg
	AllocateSmallGlobalMem
	pop eax
	mov es:handle_ptr,edx
	mov es:handle_usage,0
	mov bx,es
	mov [edx].dir_sel,bx
open_dir_handle_inc_usage:
	mov es,bx
	inc es:handle_usage
	pop es
	pop ds
	ret
open_dir_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_DIR_HANDLE
;
;		DESCRIPTION:	Close directory
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						BX		HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_dir_handle	Proc near
	push es
	mov es,bx
	sub es:handle_usage,1
	jnz close_dir_handle_done
	push eax
	push dx
	mov eax,es:handle_ptr
	FreeMem
	mov dx,flat_sel
	mov es,dx
	mov es:[eax].dir_sel,0
	pop dx
	pop eax
close_dir_handle_done:
	pop es
	ret
close_dir_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_SIZE
;
;		DESCRIPTION:	Set file size
;
;		PARAMETERS:		DS		DRIVE_DATA_SEG
;						EAX		FILE ENTRY
;						ECX		NEW FILE SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_size	PROC near
	push es
	push eax
	push ecx
	push edx
	push esi
	mov dx,flat_sel
	mov es,dx
	dec ecx
	and cx,NOT 1FFh
	add ecx,200h
	mov edx,es:[eax].entry_data_size
	dec edx
	and dx,NOT 1FFh
	add edx,200h
	cmp ecx,edx
	clc
	je set_size_done
	mov esi,eax
	cmp ecx,edx
	jc set_size_shrink
set_size_grow:
	or edx,edx
	jne set_size_grow_do
set_size_grow_empty:
	call allocate_index_block
	mov es:[esi].entry_data,eax
	jmp set_size_grow_next
set_size_grow_do:	
	mov esi,es:[esi].entry_data
	sub ecx,200h
	sub edx,200h
	jz set_size_grow_loop
set_size_grow_skip:
	mov esi,es:[esi]
	sub ecx,200h
	sub edx,200h
	jnz set_size_grow_skip
set_size_grow_loop:
	call allocate_index_block
	mov es:[esi],eax
set_size_grow_next:
	mov esi,eax
	sub ecx,200h
	jnz set_size_grow_loop
	mov dword ptr es:[esi],0
	clc
	jmp set_size_done
set_size_shrink:
	or ecx,ecx
	je set_size_shrink_empty
	mov esi,es:[esi].entry_data
	jmp set_size_shrink_link
set_size_shrink_empty:
	xor eax,eax
	xchg eax,es:[esi].entry_data
	mov esi,eax
	jmp set_size_shrink_loop
set_size_shrink_link:
	mov eax,esi
	mov esi,es:[esi]
	sub ecx,200h
	jnz set_size_shrink_link
	mov dword ptr es:[eax],0
set_size_shrink_loop:
	mov eax,esi
	or eax,eax
	je set_size_shrink_done
	mov esi,es:[esi]
	call free_index_block
	jmp set_size_shrink_loop
set_size_shrink_done:		
	clc
set_size_done:
	pop esi
	pop edx
	pop ecx
	pop eax
	mov es:[eax].entry_data_size,ecx
	pop es
	ret
set_size	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MOUNT
;
;		DESCRIPTION:	Mount filesystem on drive
;
;		RETRUNS:		DS:SI		ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount	PROC far
	push es
	push bx
	push eax
	mov eax,SIZE drive_data_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	mov ax,ramdrive_data_sel
	mov es,ax
	pop eax
	mov ds:drive_list_ptr,0
	mov ds:drive_free_ptr,0
	movzx si,al
	shl si,1
	mov ds:drive_nr,al
	mov bx,es:drive_count
	mov es:[si].drive_arr,bx
	mov si,bx
	shl si,1
	mov es:[si].drive_sel_arr,ds
	inc bx
	mov es:drive_count,bx	
;
	xor ebx,ebx
	call create_dir_node
	mov ds:drive_root_ptr,edx
;
	pop bx
	pop es
	ret
mount	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISMOUNT
;
;		DESCRIPTION:	Unmount filesystem
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
;		DESCRIPTION:	Get drive info
;
;		RETURNS:		EAX		FREE UNITS
;						CX		BYTES / UNIT
;						EDX		TOTAL UNITS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_info	PROC far
	AvailableBigLinear
	mov edx,eax
	GetFreePhysical
	shr edx,12
	shr eax,12
	mov cx,1000h
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
	push edi
	call parse_dir
	mov al,es:[edi]
	or al,al
	stc
	jne set_cur_dir_done
	mov al,ds:drive_nr
	SetCurDirPtr
	clc
set_cur_dir_done:
	pop edi
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
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	xor ecx,ecx
	mov byte ptr es:[edi],0
;
	mov ebx,ds:drive_root_ptr
	mov al,ds:drive_nr
	GetCurDirPtr
	mov ax,flat_sel
	mov ds,ax
get_cur_dir_loop:
	cmp edx,ebx
	je get_cur_dir_done
	mov eax,ds:[edx].dir_dir_ptr
	mov eax,ds:[eax].entry_ptr
	mov esi,ds:[eax].entry_data
	mov eax,ds:[esi].dir_dir_ptr
get_cur_dir_node_loop:
	cmp edx,ds:[eax].entry_data
	je get_cur_dir_node_found
	mov eax,ds:[eax].entry_ptr
	jmp get_cur_dir_node_loop	
get_cur_dir_node_found:
	mov edx,esi
;
	push eax
	push ecx
	push edi
	movzx eax,ds:[eax].entry_name_size
	inc eax
	mov esi,edi
	add edi,eax
	add esi,ecx
	add edi,ecx
	dec esi
	dec edi
	std
	rep movs byte ptr es:[edi],es:[esi]
	cld
	pop edi
	pop ecx
	pop esi
	movzx eax,ds:[esi].entry_name_size
	add ecx,eax
	inc ecx
;
	push ecx
	push edi
	add esi,OFFSET entry_name
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
	jmp get_cur_dir_loop
get_cur_dir_done:
	clc
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
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
	push eax
	push ebx
	push edx
	push edi
	call parse_dir
	mov al,es:[edi]
	or al,al
	stc
	je make_dir_done
	call insert_dir_node
	jc make_dir_done
	mov bx,flat_sel
	mov ds,bx
	mov ebx,edx
	call create_dir_node
	mov ds:[eax].entry_data,edx
	clc
make_dir_done:
	pop edi
	pop edx
	pop ebx
	pop eax
	ret
make_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE_DIR
;
;		DESCRIPTION:	Remove empty directory
;
;		PARAMETERS:		ES:EDI		DIRECTORY NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_dir	PROC far
	int 3
	push es
	push eax
	push edx
	push edi
	call parse_dir
	mov al,es:[edi]
	or al,al
	jnz remove_dir_fail
	mov ax,flat_sel
	mov es,ax
	mov eax,es:[edx].dir_file_ptr
	or eax,eax
	stc
	jnz remove_dir_done
	mov eax,es:[edx].dir_dir_ptr
	or eax,eax
	jz remove_dir_fail
	mov eax,es:[eax].entry_ptr
	or eax,eax
	jz remove_dir_fail
	mov eax,es:[eax].entry_ptr
	or eax,eax
	jnz remove_dir_fail
	int 3
	clc
	jmp remove_dir_done
remove_dir_fail:
	stc
remove_dir_done:
	pop edi
	pop edx
	pop eax
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
	push eax
	push ecx
	push edx
	push edi
	call parse_dir
	call parse_file
	pop edi
	jc delete_file_done
	mov cx,flat_sel
	mov es,cx
	mov cl,es:[eax].entry_type
	or cl,cl
	stc
	jnz delete_file_done
	xor ecx,ecx
	call set_size
	call remove_file_node
	clc
delete_file_done:
	pop edx
	pop ecx
	pop eax
	pop es
	ret
delete_file	ENDP

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
	push eax
	push edx
	push edi
	call parse_dir
	mov al,es:[edi]
	or al,al
	jne get_file_attrib_not_dir
	pop edi
	mov cx,10h
	clc
	jmp get_file_attrib_done	
get_file_attrib_not_dir:
	call parse_file
	pop edi
	jc get_file_attrib_done
	push ds
	mov dx,flat_sel
	mov ds,dx
	movzx cx,ds:[eax].entry_attrib
	pop ds
	clc
get_file_attrib_done:
	pop edx
	pop eax
	ret
get_file_attrib	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FILE_ATTRIB
;
;		DESCRIPTION:	Set file attributes
;
;		PARAMETERS:		ES:EDI		FILENAME
;						NC			SUCCESS
;						CX			FILE ATTRIBUTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_file_attrib	PROC far
	push eax
	push edx
	push edi
	call parse_dir
	mov al,es:[edi]
	or al,al
	jne set_file_attrib_not_dir
	pop edi
	test cl,10h
	clc
	jnz set_file_attrib_done
	stc
	jmp set_file_attrib_done	
set_file_attrib_not_dir:
	call parse_file
	pop edi
	jc set_file_attrib_done
	test cl,10h
	stc
	jnz set_file_attrib_done
	push ds
	mov dx,flat_sel
	mov ds,dx
	mov ds:[eax].entry_attrib,cl
	pop ds
	clc
set_file_attrib_done:
	pop edx
	pop eax
	ret
set_file_attrib	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_DIR
;
;		DESCRIPTION:	Open directory
;
;		PARAMETERS:		ES:EDI		PATH NAME
;						NC			SUCCESS
;
;		RETURNS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_dir	PROC far
	push ds
	push eax
	push edx
	push edi
	call parse_dir
	mov al,es:[edi]
	or al,al
	stc
	jne open_dir_done
	call open_dir_handle
	clc
open_dir_done:
	pop edi
	pop edx
	pop eax
	pop ds
	ret
open_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_DIR
;
;		DESCRIPTION:	Close directory
;
;		PARAMETERS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_dir	PROC far
	call close_dir_handle
	ret
close_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			READ_DIR
;
;		DESCRIPTION:	Read a directory entry
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
	push ds
	push esi
	push edi
	mov ds,bx
	mov ebx,ds:handle_ptr
	mov ax,flat_sel
	mov ds,ax
	mov esi,ds:[ebx].dir_dir_ptr
read_dir_entries:
	or esi,esi
	jz read_file_start
	or dx,dx
	jz read_dir_ok
	dec dx
	mov esi,ds:[esi].entry_ptr
	jmp read_dir_entries
read_file_start:
	mov esi,ds:[ebx].dir_file_ptr
read_file_entries:
	or esi,esi
	jz read_dir_fail
	or dx,dx
	jz read_dir_ok
	dec dx
	mov esi,ds:[esi].entry_ptr
	jmp read_file_entries
read_dir_ok:
	movzx ax,ds:[esi].entry_name_size
	cmp ax,cx
	jnc read_dir_size_ok
	mov cx,ax
read_dir_size_ok:
	movzx ecx,cx
	push esi
	add esi,OFFSET entry_name
	rep movs byte ptr es:[edi],[esi]
	xor al,al
	stos byte ptr es:[edi]
	pop esi
	mov ecx,ds:[esi].entry_data_size
	movzx bx,ds:[esi].entry_attrib
	mov edx,ds:[esi].entry_time+4
	mov eax,ds:[esi].entry_time
	clc	
	jmp read_dir_done
read_dir_fail:
	stc
read_dir_done:	
	pop edi
	pop esi
	pop ds
	ret
read_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_FILE
;
;		DESCRIPTION:	Open file
;
;		PARAMETERS:		ES:EDI		FILENAME
;						CL			ACCESS MODE
;
;		RETURNS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file	PROC far
	push eax
	push edx
	push edi
	call parse_dir
	call parse_file
	pop edi
	jc open_file_fail
	mov edx,eax
	call open_file_handle
	clc
open_file_fail:
	pop edx
	pop eax
	ret
open_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_FILE
;
;		DESCRIPTION:	Create file
;
;		PARAMETERS:		ES:EDI		FILENAME
;						CX			FILE ATTRIBUTE
;
;		RETURNS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_file	PROC far
	push eax
	push edx
	push edi
	call parse_dir
	push edi
	call parse_file
	pop edi
	jc create_file_non_exist
	push ds
	mov bx,flat_sel
	mov ds,bx
	mov al,ds:[eax].entry_type
	pop ds
	or al,al
	stc
	jne create_file_done
	push ecx
	xor ecx,ecx
	call set_size
	pop ecx
	jmp create_file_handle
create_file_non_exist:
	call insert_file_node
	jc create_file_done
	push ds
	mov bx,flat_sel
	mov ds,bx
	mov ds:[eax].entry_attrib,cl
	pop ds
create_file_handle:
	mov edx,eax
	call open_file_handle
	clc
create_file_done:
	pop edi
	pop edx
	pop eax
	ret
create_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_FILE
;
;		DESCRIPTION:	Close file
;
;		PARAMETERS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_file	PROC far
	call close_file_handle
	clc
	ret
close_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DUPL_FILE
;
;		DESCRIPTION:	Duplicate handle
;
;		PARAMETERS:		BX			HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_file	PROC far
	push ds
	mov ds,bx
	inc ds:handle_usage
	pop ds
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
;		PARAMETERS:		BX			HANDLE
;
;		RETURNS:		EDX			FILE SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_size	PROC far
	push ds
	push ax
	mov ds,bx
	mov edx,ds:handle_ptr
	mov ax,flat_sel
	mov ds,ax
	mov edx,ds:[edx].entry_data_size
	clc
	pop ax
	pop ds
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
	push ds
	push eax
	push ecx
	mov ds,bx
	mov eax,ds:handle_ptr
	mov ecx,edx
	call set_size
	pop ecx
	pop eax
	pop ds
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
	push ds
	push ax
	mov ds,bx
	mov edx,ds:handle_ptr
	mov ax,flat_sel
	mov ds,ax
	mov ecx,ds:[edx].entry_time
	mov edx,ds:[edx].entry_time+4
	clc
	pop ax
	pop ds
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
	push ds
	push ax
	push esi
	mov ds,bx
	mov esi,ds:handle_ptr
	mov ax,flat_sel
	mov ds,ax
	mov ds:[esi].entry_time,ecx
	mov ds:[esi].entry_time+4,edx
	clc
	pop esi
	pop ax
	pop ds
	ret
set_file_time	ENDP
	
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
	push ds
	push ecx
	push edx
	push esi
	push edi
;
	mov ds,bx
	mov esi,ds:handle_ptr
	mov ax,flat_sel
	mov ds,ax
	mov eax,[esi].entry_data_size
	sub eax,edx
	jc read_file_fail
;
	or eax,eax
	jnz read_file_not_zero
;
	xor eax,eax
	clc
	jmp read_file_done

read_file_not_zero:
	cmp eax,ecx
	jnc read_file_do
	mov ecx,eax
read_file_do:
	mov al,[esi].entry_type
	or al,al
	jz read_file_norm
	mov esi,[esi].entry_data
	add esi,edx
	mov eax,ecx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	movzx ecx,al
	and cl,3
	rep movs byte ptr es:[edi],[esi]
	clc
	jmp read_file_done	
read_file_norm:
	mov eax,ds:[esi].entry_data_size
	cmp ecx,eax
	jc read_file_size_fixed
	mov ecx,eax
read_file_size_fixed:
	push ecx
	mov esi,ds:[esi].entry_data
read_file_first_loop:
	sub edx,200h
	jc read_file_partial_first
	mov esi,[esi]
	jmp read_file_first_loop
read_file_partial_first:
	add edx,200h
	mov eax,200h
	sub eax,edx
	cmp eax,ecx
	jc read_file_first_do
	mov eax,ecx
read_file_first_do:
	push ecx
	push esi
	mov ecx,eax
	mov esi,[esi+4]
	add esi,edx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	movzx ecx,al
	and cl,3
	rep movs byte ptr es:[edi],[esi]
	pop esi
	pop ecx	
	sub ecx,eax
	jz read_file_ok
	push ecx
	shr ecx,9	
	or ecx,ecx
	jz read_file_partial_last
read_file_loop:
	mov esi,[esi]
	push ecx
	push esi
	mov esi,[esi+4]
	mov ecx,80h
	rep movs dword ptr es:[edi],[esi]
	pop esi
	pop ecx
	sub ecx,1
	jnz read_file_loop
read_file_partial_last:
	pop ecx 
	and ecx,1FFh
	mov esi,[esi]
	mov esi,[esi+4]
	push ecx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	pop ecx
	movzx ecx,cl
	and cl,3
	rep movs byte ptr es:[edi],[esi]
read_file_ok:
	pop ecx
	mov eax,ecx
	clc
	jmp read_file_done
read_file_fail:
	xor eax,eax
	stc
read_file_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ds
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
	push ds
	push ecx
	push edx
	push esi
	push edi
;
	push ds
	mov ds,bx
	mov esi,ds:handle_ptr
	mov ax,flat_sel
	mov ds,ax
	mov al,ds:[esi].entry_type
	or al,al
	mov eax,ds:[esi].entry_data_size
	pop ds
	jne write_file_fail
	push ecx
	push edx
	add ecx,edx
	cmp eax,ecx
	jnc write_file_size_ok
	mov eax,esi
	call set_size
write_file_size_ok:
	pop edx
	pop ecx
	jc write_file_fail
	push es
	push ecx
;
	mov ax,es
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
	xchg esi,edi
	mov edi,es:[edi].entry_data
write_file_first_loop:
	sub edx,200h
	jc write_file_partial_first
	mov edi,es:[edi]
	jmp write_file_first_loop
write_file_partial_first:
	add edx,200h
	mov eax,200h
	sub eax,edx
	cmp eax,ecx
	jc write_file_first_do
	mov eax,ecx
write_file_first_do:
	push ecx
	push edi
	mov ecx,eax
	mov edi,es:[edi+4]
	add edi,edx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	movzx ecx,al
	and cl,3
	rep movs byte ptr es:[edi],[esi]
	pop edi
	pop ecx	
	sub ecx,eax
	jz write_file_ok
	push ecx
	shr ecx,9	
	or ecx,ecx
	jz write_file_partial_last
write_file_loop:
	mov edi,es:[edi]
	push ecx
	push edi
	mov edi,es:[edi+4]
	mov ecx,80h
	rep movs dword ptr es:[edi],[esi]
	pop edi
	pop ecx
	sub ecx,1
	jnz write_file_loop
write_file_partial_last:
	pop ecx 
	and ecx,1FFh
	mov edi,es:[edi]
	mov edi,es:[edi+4]
	push ecx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	pop ecx
	movzx ecx,cl
	and cl,3
	rep movs byte ptr es:[edi],[esi]
write_file_ok:
	pop ecx
	pop es
	clc
	mov eax,ecx
	jmp write_file_done
write_file_fail:
	xor eax,eax
	stc
write_file_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ds
 	ret
write_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			install_file
;
;		DESCRIPTION:	install file
;
;		PARAMETERS:		DS:EDX	device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_file	PROC near
	push eax
	push ecx
	push edx
;
	push edx
	xor di,di
	mov esi,edx
	add esi,SIZE rdos_header
	mov ecx,8
install_file_base_loop:
	lods byte ptr [esi]
	cmp al,' '
	je install_file_base_end
	stosb
	loop install_file_base_loop
	inc ecx
install_file_base_end:
	dec ecx
	add esi,ecx
	mov cx,3
	lods byte ptr [esi]
	cmp al,' '
	je install_file_move_it
	mov ah,al
	mov al,'.'
	stosw
	dec cx
install_file_ext_loop:
	lods byte ptr [esi]
	cmp al,' '
	je install_file_move_it
	stosb
	loop install_file_ext_loop
	inc ecx
install_file_move_it:
	dec ecx
	add esi,ecx
	xor al,al
	stosb
;
	push ds
	mov ax,ramdrive_data_sel
	mov ds,ax
	mov di,2*2
	mov di,ds:[di].drive_arr
	shl di,1
	mov ds,ds:[di].drive_sel_arr
	mov edx,ds:drive_root_ptr
	call insert_file_node
	pop ds
	pop edx
	jc install_file_done
;
	push es
	mov cx,flat_sel
	mov es,cx
	mov cl,[esi]
	mov es:[eax].entry_attrib,cl
	add esi,11
	push eax
	lods word ptr [esi]
	push ax
	lods word ptr [esi]
	mov dx,ax
	shr dx,9
	add dx,1980
	mov cx,ax
	shr cx,5
	mov ch,cl
	and ch,0Fh
	mov cl,al
	and cl,1Fh
	pop di
	mov bx,di
	shr bx,11
	mov bh,bl
	mov ax,di
	shr ax,5
	and al,3Fh
	mov bl,al
	mov ax,di
	mov ah,al
	add ah,ah
	and ah,3Fh
	TimeToBinary
	mov ecx,eax
	pop eax
	add esi,2
	mov es:[eax].entry_time,ecx
	mov es:[eax+4].entry_time,edx
	mov ecx,[esi]
	add esi,4
	mov es:[eax].entry_data_size,ecx
	mov es:[eax].entry_data,esi
	mov es:[eax].entry_type,1
	pop es
install_file_done:
;
	pop edx
	pop ecx
	pop eax
	ret
install_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			install_adapter_files
;
;		DESCRIPTION:	install all files in adapter
;
;		PARAMETERS:		edx		base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_adapter_files	Proc near
	push ds
	push ax
	push bx
	push edx
	mov ax,flat_sel
	mov ds,ax
install_adapter_files_loop:
	mov ax,[edx].typ
	cmp ax,RdosFile
	jne not_install_file
	call install_file
	jmp install_adapter_files_next
not_install_file:
	cmp ax,RdosEnd
	je install_adapter_files_done
install_adapter_files_next:
	add edx,[edx].len
	jmp install_adapter_files_loop
install_adapter_files_done:
	pop edx
	pop bx
	pop ax
	pop ds
	ret
install_adapter_files	Endp

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

fs_name	DB 'MEMORY',0

fs_ctrl:
fs00	DW OFFSET mount,			ramdrive_code_sel
fs01	DW OFFSET dismount,			ramdrive_code_sel
fs02	DW OFFSET get_drive_info,	ramdrive_code_sel
fs03	DW OFFSET set_cur_dir,		ramdrive_code_sel
fs04	DW OFFSET get_cur_dir,		ramdrive_code_sel
fs05	DW OFFSET make_dir,			ramdrive_code_sel
fs06	DW OFFSET remove_dir,		ramdrive_code_sel
fs07	DW OFFSET delete_file,		ramdrive_code_sel
fs08	DW OFFSET rename_file,		ramdrive_code_sel
fs09	DW OFFSET get_file_attrib,	ramdrive_code_sel
fs10	DW OFFSET set_file_attrib,	ramdrive_code_sel
fs11	DW OFFSET open_dir,			ramdrive_code_sel
fs12	DW OFFSET close_dir,		ramdrive_code_sel
fs13	DW OFFSET read_dir,			ramdrive_code_sel
fs14	DW OFFSET open_file,		ramdrive_code_sel
fs15	DW OFFSET create_file,		ramdrive_code_sel
fs16	DW OFFSET close_file,		ramdrive_code_sel
fs17	DW OFFSET dupl_file,		ramdrive_code_sel
fs18	DW OFFSET get_ioctl_data,	ramdrive_code_sel
fs19	DW OFFSET get_file_size,	ramdrive_code_sel
fs20	DW OFFSET set_file_size,	ramdrive_code_sel
fs21	DW OFFSET get_file_time,	ramdrive_code_sel
fs22	DW OFFSET set_file_time,	ramdrive_code_sel
fs23	DW OFFSET read_file,		ramdrive_code_sel
fs24	DW OFFSET write_file,		ramdrive_code_sel

init	PROC far
	push ds
	push es
	push fs
	push gs
	pushad
	mov bx,ramdrive_code_sel
	InitDevice
;
	mov eax,SIZE fs_data_seg
	mov bx,ramdrive_data_sel
	AllocateFixedSystemMem
;
	mov cx,ax
	xor di,di
	xor al,al
	rep stosb
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET fs_name
	mov di,OFFSET fs_ctrl
	RegisterFileSystem
;
	AllocateDynamicDrive
	mov di,OFFSET fs_name
	InstallFileSystem
	InitFileSystem
;
	mov eax,10h
	AllocateSmallGlobalMem
	mov ax,system_data_sel
	mov ds,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
	mov esi,2
	xor edi,edi
init_file_loop:
	mov edx,[bx].adapter_base
	call install_adapter_files
	add bx,SIZE adapter_typ
	loop init_file_loop	
	FreeMem
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

