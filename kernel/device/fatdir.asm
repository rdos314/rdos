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

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\fs.inc
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

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn next_cluster:near
	extrn allocate_cluster:near
	extrn link_cluster:near
	extrn next_sector:near
	extrn free_cluster:near

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

lower_tab:
lt00 DB	0,		0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
lt08 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
lt10 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
lt18 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
lt20 DB ' ',	'!',	0FFh,	'#',	'$',	'%',	'&',	27h
lt28 DB '(',	')',	0FFh,	0FFh,	0FFh,	'-',	'.',	0
lt30 DB '0',	'1',	'2',	'3',	'4',	'5',	'6',	'7'
lt38 DB '8',	'9',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
lt40 DB '@',	'a',	'b',	'c',	'd',	'e',	'f',	'g'
lt48 DB 'h',	'i',	'j',	'k',	'l',	'm',	'n',	'o'
lt50 DB 'p',	'q',	'r',	's',	't',	'u',	'v',	'w'
lt58 DB	'x',	'y',	'z',	0FFh,	0,		0FFh,	'^',	'_'
lt60 DB 60h,	'a',	'b',	'c',	'd',	'e',	'f',	'g'
lt68 DB 'h',	'i',	'j',	'k',	'l',	'm',	'n',	'o'
lt70 DB 'p',	'q',	'r',	's',	't',	'u',	'v',	'w'
lt78 DB 'x',	'y',	'z',	'{',	0FFh,	'}',	'~',	0FFh
lt80 DB	0FFh,	0FFh,	0FFh,	0FFh,	'é',	0FFh,	'è',	0FFh
lt88 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	'é',	'è'
lt90 DB	0FFh,	0FFh,	0FFh,	0FFh,	'ô',	0FFh,	0FFh,	0FFh
lt98 DB	0FFh,	'ô',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltA0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltA8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltB0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltB8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltC0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltC8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltD0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltD8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltE0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltE8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltF0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ltF8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateDirSel
;
;		DESCRIPTION:	Allocate dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public allocate_dir_sel

allocate_dir_sel	PROC far
	push es
	push eax
;
	mov eax,SIZE fat_dir_sel_data_struc
	AllocateSmallGlobalMem
	mov es:fds_deleted_ptr,0
	mov es:fds_free_ptr,0
	mov bx,es
;
	pop eax
	pop es
	ret
allocate_dir_sel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeDirSel
;
;		DESCRIPTION:	Free dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public free_dir_sel

free_dir_sel	PROC far
	push ds
	push es
	push eax
	push ecx
	push edx
;
	mov ax,flat_sel
	mov es,ax
	mov ds,bx
	mov edx,ds:fds_deleted_ptr
	or edx,edx
	jz free_dir_free

free_dir_deleted_loop:
	mov eax,es:[edx].de_next
	xor ecx,ecx
	FreeLinear
	mov edx,eax
	cmp edx,ds:fds_deleted_ptr
	jne free_dir_deleted_loop

free_dir_free:
	mov edx,ds:fds_free_ptr
	or edx,edx
	jz free_dir_del

free_dir_free_loop:
	mov eax,es:[edx].de_next
	xor ecx,ecx
	FreeLinear
	mov edx,eax
	cmp edx,ds:fds_free_ptr
	jne free_dir_free_loop

free_dir_del:
	xor ax,ax
	mov ds,ax
	mov es,bx
	FreeMem
;
	pop edx
	pop ecx
	pop eax
	pop es
	pop ds
	ret
free_dir_sel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertFreeEntry
;
;		DESCRIPTION:	Insert free entry structure
;
;		PARAMETERS:		BX			Dir selector
;						EDX			Free entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertFreeEntry	PROC near
	push ds
	push es
	push eax
	push ebx
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov eax,ds:fds_free_ptr
	or eax,eax
	jne insert_free_used

insert_free_empty:
	mov es:[edx].de_prev,edx
	mov es:[edx].de_next,edx
	mov ds:fds_free_ptr,edx
	jmp insert_free_done

insert_free_used:
	mov ebx,es:[eax].de_prev
	mov es:[eax].de_prev,edx
	mov es:[ebx].de_next,edx
	mov es:[edx].de_prev,ebx
	mov es:[edx].de_next,eax	

insert_free_done:
	pop ebx
	pop eax
	pop es
	pop ds
	ret
InsertFreeEntry	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertDeletedEntry
;
;		DESCRIPTION:	Insert deleted entry structure
;
;		PARAMETERS:		BX			Dir selector
;						EDX			Deleted entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertDeletedEntry	PROC near
	push ds
	push es
	push eax
	push ebx
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov eax,ds:fds_deleted_ptr
	or eax,eax
	jne insert_deleted_used

insert_deleted_empty:
	mov es:[edx].de_prev,edx
	mov es:[edx].de_next,edx
	mov ds:fds_deleted_ptr,edx
	jmp insert_deleted_done

insert_deleted_used:
	mov ebx,es:[eax].de_prev
	mov es:[eax].de_prev,edx
	mov es:[ebx].de_next,edx
	mov es:[edx].de_prev,ebx
	mov es:[edx].de_next,eax	

insert_deleted_done:
	pop ebx
	pop eax
	pop es
	pop ds
	ret
InsertDeletedEntry	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetFreeEntry
;
;		DESCRIPTION:	Get free entry structure
;
;		PARAMETERS:		BX			Dir selector
;
;		RETURNS:		EDX			Entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFreeEntry	PROC near
	push ds
	push es
	push eax
	push ebx
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov edx,ds:fds_free_ptr
	or edx,edx
	stc
	jz get_free_done
;
	mov eax,es:[edx].de_next
	mov ebx,es:[edx].de_prev
	mov es:[ebx].de_next,eax
	mov es:[eax].de_prev,ebx
	mov ds:fds_free_ptr,eax
	cmp eax,edx
	jne get_free_list_ok
;
	mov ds:fds_free_ptr,0

get_free_list_ok:
	clc

get_free_done:
	pop ebx
	pop eax
	pop es
	pop ds
	ret
GetFreeEntry	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDeletedEntry
;
;		DESCRIPTION:	Get deleted entry structure
;
;		PARAMETERS:		BX			Dir selector
;
;		RETURNS:		EDX			Entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDeletedEntry	PROC near
	push ds
	push es
	push eax
	push ebx
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov edx,ds:fds_deleted_ptr
	or edx,edx
	stc
	jz get_deleted_done
;
	mov eax,es:[edx].de_next
	mov ebx,es:[edx].de_prev
	mov es:[ebx].de_next,eax
	mov es:[eax].de_prev,ebx
	mov ds:fds_deleted_ptr,eax
	cmp eax,edx
	jne get_deleted_list_ok
;
	mov ds:fds_deleted_ptr,0

get_deleted_list_ok:
	clc

get_deleted_done:
	pop ebx
	pop eax
	pop es
	pop ds
	ret
GetDeletedEntry	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_entry_name_size
;
;		DESCRIPTION:	Get dir entry name size
;
;		PARAMETERS:		ESI		Entry data
;
;		RETURNS:		ECX		Size of entry name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_entry_name_size	Proc near
	push dx
	push esi
;
	xor ecx,ecx
	xor dl,dl
	mov cx,8
	add esi,OFFSET fat_base

get_name_base_loop:
	lods byte ptr es:[esi]
	cmp al,' '
	je get_name_base_ok
;
	inc dl
	loop get_name_base_loop
;
	inc esi

get_name_base_ok:
	dec esi
	add esi,ecx
	inc dl
;
	mov cx,3

get_name_ext_loop:
	lods byte ptr es:[esi]
	cmp al,' '
	je get_name_ext_ok
;
	inc dl
	loop get_name_ext_loop

get_name_ext_ok:
	movzx ecx,dl
	pop esi
	pop dx
	ret
get_entry_name_size	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			copy_entry_name
;
;		DESCRIPTION:	Copy entry name
;
;		PARAMETERS:		ESI		Entry data
;						EDI		Dir entry name offset
;
;       RETURNS:        CX      Size of name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy_entry_name	Proc near
	push dx
	push esi
	push edi
;
	xor ecx,ecx
	xor dx,dx
	mov cx,8
copy_name_base_loop:
	lods byte ptr es:[esi]
	cmp al,' '
	je copy_name_base_ok
;
	inc dx
	stos byte ptr es:[edi]
	loop copy_name_base_loop
;
	inc esi

copy_name_base_ok:
	dec esi
	add esi,ecx
	mov al,'.'
	inc dx
	stos byte ptr es:[edi]
;
	mov cx,3
copy_name_ext_loop:
	lods byte ptr es:[esi]
	cmp al,' '
	je copy_name_ext_ok
;
	inc dx
	stos byte ptr es:[edi]
	loop copy_name_ext_loop

copy_name_ext_ok:
	mov al,es:[edi-1]
	cmp al,'.'
	jne copy_name_add_zero
;
	dec edi
	dec dx

copy_name_add_zero:
	xor al,al
	stos byte ptr es:[edi]
;
	mov cx,dx
	pop edi
	pop esi
	pop dx
	ret
copy_entry_name	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			copy_entry_xlat
;
;		DESCRIPTION:	Copy entry name & translate
;
;		PARAMETERS:		ESI		Entry data
;						EDI		Dir entry name offset
;                       BX      Table
;
;       RETURNS:        CX      Size of name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy_entry_xlat	Proc near
	push dx
	push esi
	push edi
;
	xor ecx,ecx
	xor dx,dx
	mov cx,8
xcopy_name_base_loop:
	lods byte ptr es:[esi]
	xlat byte ptr cs:char_tab
	cmp al,' '
	je xcopy_name_base_ok
;
	inc dx
	stos byte ptr es:[edi]
	loop xcopy_name_base_loop
;
	inc esi

xcopy_name_base_ok:
	dec esi
	add esi,ecx
	mov al,'.'
	inc dx
	stos byte ptr es:[edi]
;
	mov cx,3
xcopy_name_ext_loop:
	lods byte ptr es:[esi]
	xlat cs:byte ptr char_tab
	cmp al,' '
	je xcopy_name_ext_ok
;
	inc dx
	stos byte ptr es:[edi]
	loop xcopy_name_ext_loop

xcopy_name_ext_ok:
	mov al,es:[edi-1]
	cmp al,'.'
	jne xcopy_name_add_zero
;
	dec edi
	dec dx

xcopy_name_add_zero:
	xor al,al
	stos byte ptr es:[edi]
;
	mov cx,dx
	pop edi
	pop esi
	pop dx
	ret
copy_entry_xlat	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_lfn_name_size
;
;		DESCRIPTION:	Get LFN name size
;
;		PARAMETERS:		DI			Cached dir selector
;                       FS          LFN data
;
;		RETURNS:		NC          LFN valid
;                           ECX		Size of LFN name
;                       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_lfn_name_size	Proc near
    push ax
    push bx
    push dx
;
    mov ax,fs
    or ax,ax    
    stc
    jz get_lfn_name_size_done
;
    mov al,fs:lfn_seq
    cmp al,1
    je get_lfn_name_size_start
;
    call delete_lfn_entries
    stc
    jmp get_lfn_name_size_done

get_lfn_name_size_start:
    mov bx,OFFSET lfn_name
    xor cx,cx
    mov dx,255

get_lfn_name_size_loop:
    mov al,fs:[bx]
    or al,al
    jz get_lfn_name_size_ok
;
    cmp al,-1
    je get_lfn_name_size_ok
;
    inc cx
    inc bx
    sub dx,1
    jnz get_lfn_name_size_loop
;
    mov byte ptr fs:[bx],0    

get_lfn_name_size_ok:
    clc

get_lfn_name_size_done:
    pop dx
    pop bx
    pop ax
    ret
get_lfn_name_size   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_entry_time
;
;		DESCRIPTION:	Get entry time
;
;		PARAMETERS:		ESI		Entry data
;
;		RETURNS:		EDX:EAX		Time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_entry_time	Proc near
	push bx
	push cx
;
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
;
	pop cx
	pop bx
	ret
get_entry_time	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			extend_dir
;
;		DESCRIPTION:	Extend directory
;
;		PARAMETERS:		FS		Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extend_dir	Proc near
	pushad
;
	mov ax,fs:ds_parent
	or ax,ax
	jnz extend_dir_do
;
	cmp ds:fat_type,fat32
	stc
	jne extend_dir_done

extend_dir_do:
	mov al,ds:drive_nr
	mov edi,fs:ds_handle
	mov edx,es:[edi].fde_start_cluster

extend_dir_loop:
	mov ecx,edx
	call next_cluster
	jnc extend_dir_loop
;
	call allocate_cluster
	jc extend_dir_done
;
	xchg ecx,edx
	call link_cluster
	xchg ecx,edx
;
	sub edx,2
	mov cl,ds:fat_cluster_shift
	shl edx,cl
	add edx,ds:start_sector
	mov bx,1
	shl bx,cl
	mov cx,bx

extend_dir_sector_loop:
	push cx
	push edx
	mov al,ds:drive_nr
	LockSector
	jc extend_dir_try_next
;
	mov edi,esi
	mov ecx,80h
	xor eax,eax
	rep stos dword ptr es:[edi]

extend_dir_entry_loop:
	mov di,fs
	call cache_free_entry
	add si,20h
	test si,1FFh
	jnz extend_dir_entry_loop
;
	ModifySector
	UnlockSector

extend_dir_try_next:
	pop edx
	pop cx
	inc edx
	loop extend_dir_sector_loop
;
	clc

extend_dir_done:
	popad
	ret
extend_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			allocate_dir_entry
;
;		DESCRIPTION:	Allocate a new directory entry
;
;		PARAMETERS:		FS		Dir selector
;
;		RETURNS:		EDX		Sector
;						AX		Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dir_entry	Proc near
	mov edx,fs:fds_deleted_ptr
	or edx,edx
	jz alloc_dir_try_free
;
	mov bx,fs
	call GetDeletedEntry
	jnc alloc_dir_init

alloc_dir_try_free:
	mov edx,fs:fds_free_ptr
	or edx,edx
	jz alloc_dir_extend
;
	mov bx,fs
	call GetFreeEntry
	jnc alloc_dir_init

alloc_dir_extend:
	call extend_dir
	jnc alloc_dir_try_free
	jmp alloc_dir_done

alloc_dir_init:
	mov ax,es:[edx].fe_entry_offset
	push es:[edx].fe_entry_sector
	push ecx
	xor ecx,ecx
	FreeLinear
	pop ecx
	pop edx
	clc

alloc_dir_done:
	ret
allocate_dir_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			set_dir_name
;
;		DESCRIPTION:	Set name of dir entry
;
;		PARAMETERS:		GS:EDI	Name of entry
;						ESI		Disk data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dir_name	PROC near
	push ax
	push bx
	push ecx
	push esi
	push edi
;
	mov bx,OFFSET char_tab
	xchg esi,edi
	mov al,gs:[esi]
	cmp al,'.'
	jne set_name_base

set_name_spec:
	inc esi
	mov ecx,10
	stos byte ptr es:[edi]
	lods byte ptr gs:[esi]
	or al,al
	je set_name_pad
;
	cmp al,'.'
	stc
	jne set_name_done
;
	dec cx
	stos byte ptr es:[edi]
	lods byte ptr gs:[esi]
	or al,al	
	je set_name_pad
;
	stc
	jmp set_name_done
	
set_name_base:
	mov ecx,8
set_name_base_loop:
	lods byte ptr gs:[esi]
	xlat byte ptr cs:char_tab
	or al,al
	je set_name_ext
;
	cmp al,'.'
	je set_name_ext
;
	stos byte ptr es:[edi]
	loop set_name_base_loop
;
	lods byte ptr gs:[esi]
	xlat byte ptr cs:char_tab
	or al,al
	je set_name_ext
;
	cmp al,'.'
	je set_name_ext
;
	stc
	jmp set_name_done

set_name_ext:
	mov ah,al
	mov al,' '
	rep stos byte ptr es:[edi]
	mov ecx,3
	mov al,ah
	or al,al
	je set_name_pad

set_name_ext_loop:
	lods byte ptr gs:[esi]
	xlat byte ptr cs:char_tab
	or al,al
	je set_name_pad
;
	stos byte ptr es:[edi]
	loop set_name_ext_loop
;
	lods byte ptr gs:[esi]
	or al,al
	clc
	je set_name_done

set_name_pad:
	mov al,' '
	rep stos byte ptr es:[edi]
	clc

set_name_done:
	pop edi
	pop esi
	pop ecx
	pop bx
	pop ax
	ret
set_dir_name	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			set_dir_time
;
;		DESCRIPTION:	Set dir entry time
;
;		PARAMETERS:		EDX:EAX	Time
;						ESI		Disk data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dir_time	Proc near
	push eax
	push bx
	push cx
	push edx
;	
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
set_dir_time	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_FREE_ENTRY
;
;		DESCRIPTION:	Cache free entry
;
;		PARAMETERS:		DI			Cached dir selector
;						EDX			Sector
;						ESI			Entry data
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_free_entry	Proc near
	push eax
	push bx
	push edx
	push edi
;
	mov bx,di
	push edx
	mov eax,SIZE fe_struc
	AllocateSmallLinear
	mov edi,edx
	pop edx
;
	mov es:[edi].fe_entry_sector,edx
	mov ax,si
	and ax,1FFh
	mov es:[edi].fe_entry_offset,ax
;
	mov edx,edi
	call InsertFreeEntry
;
	pop edi
	pop edx
	pop bx
	pop eax
	ret
cache_free_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_DELETED_ENTRY
;
;		DESCRIPTION:	Cache deleted entry
;
;		PARAMETERS:		DI			Cached dir selector
;						EDX			Sector
;						ESI			Entry data
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_deleted_entry	Proc near
	push eax
	push bx
	push edx
	push edi
;
	mov bx,di
	push edx
	mov eax,SIZE fe_struc
	AllocateSmallLinear
	mov edi,edx
	pop edx
;
	mov es:[edi].fe_entry_sector,edx
	mov ax,si
	and ax,1FFh
	mov es:[edi].fe_entry_offset,ax
;
	mov edx,edi
	call InsertDeletedEntry
;
	pop edi
	pop edx
	pop bx
	pop eax
	ret
cache_deleted_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_FILE_ENTRY
;
;		DESCRIPTION:	Cache file entry
;
;		PARAMETERS:		DI			Cached dir selector
;						EDX			Sector
;						ESI			Entry data
;
;		RETURNS:		EDX			Dir file entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_file_entry	Proc near
	push eax
	push bx
	push ecx
	push edi
;
	mov bx,di
    call get_lfn_name_size
    jc cache_file_83
;
	mov eax,SIZE ffe_struc
	add eax,ecx
	push edx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET ffe_name
	mov es:[edi].de_name,edx
	pop edx
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0
	mov al,es:[esi].fat_attrib
	mov es:[edi].de_attrib,al
	mov es:[edi].ffe_entry_sector,edx
	mov ax,si
	and ax,1FFh
	mov es:[edi].ffe_entry_offset,ax
;	
    push cx
    push edi
	lea edi,[edi].ffe_fat_name
	call copy_entry_name
	pop edi
	pop cx
;	
	push ecx
    push esi
    push edi
;    
    movzx ecx,cx
    mov esi,OFFSET lfn_name
	mov edi,es:[edi].de_name
	rep movs byte ptr es:[edi],fs:[esi]
	xor al,al
	stos byte ptr es:[edi]
;	
	pop edi
	pop esi
	pop ecx
	mov es:[edi].de_name_size,cx
    jmp cache_file_time

cache_file_83:	
	call get_entry_name_size
	mov eax,SIZE ffe_struc
	add eax,ecx
	push edx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET ffe_name
	mov es:[edi].de_name,edx
	pop edx
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0
	mov al,es:[esi].fat_attrib
	mov es:[edi].de_attrib,al
	mov es:[edi].ffe_entry_sector,edx
	mov ax,si
	and ax,1FFh
	mov es:[edi].ffe_entry_offset,ax
;	
    push edi
	lea edi,[edi].ffe_fat_name
	call copy_entry_name
	pop edi
;	
    push bx
    push edi
	mov edi,es:[edi].de_name
	mov bx,OFFSET lower_tab
	call copy_entry_xlat
	pop edi
	pop bx
	mov es:[edi].de_name_size,cx

cache_file_time:
	call get_entry_time
	mov es:[edi].de_time,eax
	mov es:[edi+4].de_time,edx
;
	cmp ds:fat_type,fat32
	je cache_file_entry_cluster32
;
	movzx eax,es:[esi].fat_cluster
	jmp cache_file_entry_cluster_ok

cache_file_entry_cluster32:
	mov ax,es:[esi].fat_cluster_hi
	shl eax,16
	mov ax,es:[esi].fat_cluster

cache_file_entry_cluster_ok:	
	mov es:[edi].ffe_start_cluster,eax
	mov eax,es:[esi].fat_file_size
	mov es:[edi].dfe_data_size,eax
	mov es:[edi].dfe_file_sel,0
;
	mov edx,edi
	InsertFileEntry
;
	pop edi
	pop ecx
	pop bx
	pop eax
	ret
cache_file_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_DIR_ENTRY
;
;		DESCRIPTION:	Cache dir entry
;
;		PARAMETERS:		DI			Cached dir selector
;						EDX			Sector
;						ESI			Entry data
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_dir_entry	Proc near
	push eax
	push bx
	push ecx
	push edi
;
	mov bx,di
    call get_lfn_name_size
    jc cache_dir_83
;
	mov eax,SIZE fde_struc
	add eax,ecx
	push edx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET fde_name
	mov es:[edi].de_name,edx
	pop edx
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0
	mov al,es:[esi].fat_attrib
	mov es:[edi].de_attrib,al
	mov es:[edi].fde_entry_sector,edx
	mov ax,si
	and ax,1FFh
	mov es:[edi].fde_entry_offset,ax
;	
    push cx
    push edi
	lea edi,[edi].fde_fat_name
	call copy_entry_name
	pop edi
	pop cx
;	
	push ecx
    push esi
    push edi
;    
    movzx ecx,cx
    mov esi,OFFSET lfn_name
	mov edi,es:[edi].de_name
	rep movs byte ptr es:[edi],fs:[esi]
	xor al,al
	stos byte ptr es:[edi]
;	
	pop edi
	pop esi
	pop ecx
	mov es:[edi].de_name_size,cx
    jmp cache_dir_time

cache_dir_83:	
	call get_entry_name_size
	mov eax,SIZE fde_struc
	add eax,ecx
	push edx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET fde_name
	mov es:[edi].de_name,edx
	pop edx
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0
	mov al,es:[esi].fat_attrib
	mov es:[edi].de_attrib,al
	mov es:[edi].fde_entry_sector,edx
	mov ax,si
	and ax,1FFh
	mov es:[edi].fde_entry_offset,ax
;	
    push edi
	lea edi,[edi].fde_fat_name
	call copy_entry_name
	pop edi
;	
    push bx
    push edi
	mov edi,es:[edi].de_name
	mov bx,OFFSET lower_tab
	call copy_entry_xlat
	pop edi
	pop bx
	mov es:[edi].de_name_size,cx

cache_dir_time:
	call get_entry_time
	mov es:[edi].de_time,eax
	mov es:[edi+4].de_time,edx
;
	cmp ds:fat_type,fat32
	je cache_dir_entry_cluster32
;
	movzx eax,es:[esi].fat_cluster
	jmp cache_dir_entry_cluster_ok

cache_dir_entry_cluster32:
	mov ax,es:[esi].fat_cluster_hi
	shl eax,16
	mov ax,es:[esi].fat_cluster

cache_dir_entry_cluster_ok:	
	mov es:[edi].fde_start_cluster,eax
	sub eax,2
	mov cl,ds:fat_cluster_shift
	shl eax,cl
	add eax,ds:start_sector
	mov es:[edi].fde_start_sector,eax
;
	mov edx,edi
	InsertDirEntry
;
	pop edi
	pop ecx
	pop bx
	pop eax
	ret
cache_dir_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_LFN_ENTRY
;
;		DESCRIPTION:	Cache LFN entry
;
;		PARAMETERS:		DI			Cached dir selector
;						EDX			Sector
;						ESI			Entry data
;                       FS          LFN cache
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_lfn_entry	Proc near
    push es
    push eax
    push bx
    push ecx
;
    mov bx,fs
    mov ax,flat_sel
    mov fs,ax
    mov es,bx
;
    or bx,bx
    jnz cache_lfn_check_seq

cache_lfn_retry:
    test fs:[esi].lfne_seq,40h
    jz cache_lfn_done
;
    mov eax,SIZE lfn_struc
    AllocateSmallGlobalMem
;    
    push di
    mov di,OFFSET lfn_name
    mov cx,40h
    mov eax,-1
    rep stosd
    pop di
;    
    mov es:lfn_entries,0
    mov es:lfn_chksum,0
    mov al,fs:[esi].lfne_seq
    and al,3Fh
    jmp cache_lfn_seq_ok

cache_lfn_check_seq:
    mov es,bx
    mov al,fs:[esi].lfne_seq
    mov ah,es:lfn_seq
    dec ah
    cmp al,ah
    je cache_lfn_seq_ok

cache_lfn_error:
    call delete_lfn_entries    
    jmp cache_lfn_retry
    
cache_lfn_seq_ok:
    mov es:lfn_seq,al
    mov bx,es:lfn_entries
    cmp bx,20
    jae cache_lfn_error
;
    shl bx,3    
    mov es:lfn_entry_arr.[bx].lfnp_sector,edx
    mov eax,esi
    and eax,1FFh
    mov es:lfn_entry_arr.[bx].lfnp_offset,eax    
    inc es:lfn_entries
;
    push di
    push si
    std
    mov si,OFFSET lfn_name + 255 - 13
    mov di,OFFSET lfn_name + 255
    mov cx,256 - 13
    rep movs byte ptr es:[di],es:[si]    
    cld
    mov di,OFFSET lfn_name
    mov al,-1
    mov cx,13
    rep stosb
    pop si
;
    mov di,OFFSET lfn_name
    mov al,fs:[esi].lfne_char1
    stosb
    mov al,fs:[esi].lfne_char2
    stosb
    mov al,fs:[esi].lfne_char3
    stosb
    mov al,fs:[esi].lfne_char4
    stosb
    mov al,fs:[esi].lfne_char5
    stosb
    mov al,fs:[esi].lfne_char6
    stosb
    mov al,fs:[esi].lfne_char7
    stosb
    mov al,fs:[esi].lfne_char8
    stosb
    mov al,fs:[esi].lfne_char9
    stosb
    mov al,fs:[esi].lfne_char10
    stosb
    mov al,fs:[esi].lfne_char11
    stosb
    mov al,fs:[esi].lfne_char12
    stosb
    mov al,fs:[esi].lfne_char13
    stosb        
    pop di

cache_lfn_done:
    mov ax,es
    mov fs,ax
;
    pop ecx
    pop bx
    pop eax
    pop es
    ret
cache_lfn_entry Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_LFN_ENTRIES
;
;		DESCRIPTION:	Delete LFN entries
;
;		PARAMETERS:		DI          Cached dir selector
;                       FS          LFN cache
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_lfn_entries	Proc near
    push es
    pushad
;
    int 3
;
    mov bp,di
    mov cx,fs:lfn_entries
    mov di,OFFSET lfn_entry_arr

delete_lfn_loop:
    mov edx,fs:[di].lfnp_sector
	mov al,ds:drive_nr
	LockSector
	or esi,fs:[di].lfnp_offset
;	
	push ecx
	push edi
	mov edi,esi
	mov ecx,8
	xor eax,eax
    rep stos dword ptr es:[edi]
;    
    mov di,bp
    call cache_free_entry
;
    pop edi
    pop ecx
;
    ModifySector
    UnlockSector
;
    add di,8 
    loop delete_lfn_loop    
;    
    mov ax,fs
    mov es,ax    
    xor ax,ax
    mov fs,ax
    FreeMem
;
    popad
    pop es
    ret
delete_lfn_entries  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_FREE_LFN
;
;		DESCRIPTION:	Free LFN entry
;
;		PARAMETERS:		FS          LFN cache
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_free_lfn	Proc near
    push es
    push ax
;
    mov ax,fs
    or ax,ax
    jz cache_free_lfn_done
;
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem 

cache_free_lfn_done:   
    pop ax
    pop es    
    ret
cache_free_lfn Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_ENTRY
;
;		DESCRIPTION:	Cache an entry
;
;		PARAMETERS:		DI			Cached dir selector
;						EDX			Sector
;						ESI			Entry data
;                       FS          LFN info
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_entry	Proc near
	mov al,es:[esi].fat_base
	or al,al
	je cache_entry_free
;
	cmp al,'.'
	je cache_entry_done
;
	cmp al,0E5h
	je cache_entry_deleted
;
	mov al,es:[esi].fat_attrib
	mov ah,al
	and ah,0Fh
	cmp ah,0Fh
	je cache_entry_lfn
;
	test al,10h
	jz cache_entry_file
;
	push edx
	call cache_dir_entry
	pop edx
	jmp cache_entry_done

cache_entry_file:
	push edx
	call cache_file_entry
	pop edx
	jmp cache_entry_done

cache_entry_lfn:
    call cache_lfn_entry
    jmp cache_entry_done

cache_entry_deleted:
	call cache_deleted_entry
	jmp cache_entry_done

cache_entry_free:
	call cache_free_entry

cache_entry_done:
	ret
cache_entry	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_ROOT_DIR
;
;		DESCRIPTION:	Cache root directory structure
;
;		PARAMETERS:		EDI			Dir entry to cache or 0
;						BX			Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_root_dir	Proc near
    push fs
	push ax
	push ebx
	push cx
	push edx
	push esi
	push di
;
    xor di,di
    mov fs,di
	mov di,bx
	mov cx,ds:root_entries
	shr cx,4
	mov edx,ds:root_sector

cache_root_sector_loop:
	mov al,ds:drive_nr
	LockSector
	jc cache_root_dir_next

cache_root_entry_loop:
	call cache_entry
	add si,20h
	test si,1FFh
	jnz cache_root_entry_loop

cache_root_dir_next:
	UnlockSector			
	inc edx
	loop cache_root_sector_loop
;
    call cache_free_lfn
;    
	pop di
	pop esi
	pop edx
	pop cx
	pop ebx
	pop ax
	pop fs
	clc
	ret
cache_root_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_SUB_DIR
;
;		DESCRIPTION:	Cache subdirectory structure
;
;		PARAMETERS:		EDX			Start sector
;						EDI			Dir entry to cache or 0
;						BX			Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_sub_dir	Proc near
    push fs
	push ax
	push ebx
	push edx
	push esi
	push di
;
    xor di,di
    mov fs,di
	mov di,bx

cache_sub_dir_sector_loop:
	mov al,ds:drive_nr
	LockSector
	jc cache_sub_dir_next

cache_sub_dir_entry_loop:
	call cache_entry
	add si,20h
	test si,1FFh
	jnz cache_sub_dir_entry_loop

cache_sub_dir_next:
	mov al,ds:drive_nr
	UnlockSector			
	call next_sector
	jnc cache_sub_dir_sector_loop
;
    call cache_free_lfn
;
	pop di
	pop esi
	pop edx
	pop ebx
	pop ax
	pop fs
	clc
	ret
cache_sub_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_DIR12_16
;
;		DESCRIPTION:	Cache FAT12 + FAT16 directory structure
;
;		PARAMETERS:		EDX			Dir entry to cache or 0
;						BX			Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public cache_dir12_16

cache_dir12_16	Proc far
	push es
	push ax
	push edx
;
	mov ax,flat_sel
	mov es,ax
;
	or edx,edx
	jz cache_dir12_16_root
;
	mov edx,es:[edx].fde_start_sector
	call cache_sub_dir
	jmp cache_dir12_16_done

cache_dir12_16_root:
	call cache_root_dir

cache_dir12_16_done:
	pop edx
	pop ax
	pop es
	ret
cache_dir12_16	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_DIR32
;
;		DESCRIPTION:	Cache FAT32 directory structure
;
;		PARAMETERS:		EDX			Dir entry to cache or 0
;						BX			Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public cache_dir32

cache_dir32	Proc far
	push es
	push ax
	push edx
;
	mov ax,flat_sel
	mov es,ax
;
	or edx,edx
	jz cache_dir32_root
;
	mov edx,es:[edx].fde_start_sector
	call cache_sub_dir
	jmp cache_dir32_done

cache_dir32_root:
	mov edx,ds:root_sector
	call cache_sub_dir

cache_dir32_done:
	pop edx
	pop ax
	pop es
	ret
cache_dir32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitDir
;
;		DESCRIPTION:	Init a new directory
;
;		PARAMETERS:		FS			DIR SELECTOR
;	
;		RETURNS:		EAX			CLUSTER
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dir	Proc near
	push edx
	mov al,ds:drive_nr
	call allocate_cluster
	jc init_dir_done
;
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	sub edx,2
	mov cl,ds:fat_cluster_shift
	shl edx,cl
	add edx,ds:start_sector
	mov bx,1
	shl bx,cl
	mov cx,bx

init_dir_sector_loop:
	push cx
	mov al,ds:drive_nr
	LockSector
	jc init_dir_try_next
;
	mov edi,esi
	mov ecx,80h
	xor eax,eax
	rep stos dword ptr es:[edi]
;
	ModifySector
	UnlockSector

init_dir_try_next:
	pop cx
	inc edx
	loop init_dir_sector_loop
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	mov eax,edx
	clc

init_dir_done:
	pop edx
	ret
init_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			add_dir
;
;		DESCRIPTION:	Add directory
;
;		PARAMETERS:		BX			DIR SELECTOR
;						GS:EDI		DIR NAME
;						EDX			CLUSTER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_dir	Proc near
	push fs
	push ax
	push ebx
	push cx
	push edx
	push esi
	push ebp
;
	mov fs,bx
	mov ebp,edx
;
	call allocate_dir_entry
	jc add_dir_done
;
	push ax
	mov al,ds:drive_nr
	LockSector
	pop ax
	jc add_dir_done
;
	or si,ax
	call set_dir_name
	jc add_dir_unlock
;
	mov es:[esi].fat_cluster,bp
	shr ebp,16
	mov es:[esi].fat_cluster_hi,bp
	mov es:[esi].fat_attrib,10h
	mov es:[esi].fat_file_size,0
	push edx
	GetTime
	call set_dir_time
	pop edx
;
	ModifySector
	UnlockSector
	clc
	jmp add_dir_done

add_dir_unlock:
	mov di,fs
	call cache_free_entry
	UnlockSector
	stc

add_dir_done:
	pop ebp
	pop esi
	pop edx
	pop cx
	pop ebx
	pop ax
	pop fs
	ret
add_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_DIR
;
;		DESCRIPTION:	Create directory
;
;		PARAMETERS:		ES:EDI		DIRECTORY NAME
;						BX			DIR SELECTOR
;	
;		RETURNS:		EDX			DIR ENTRY
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public create_dir

dot_dir	DB '.', 0
dot_dot_dir	DB '..',0

create_dir	PROC far
	push es
	push fs
	push gs
	push ax
	push ebx
	push cx
	push esi
;
	mov ax,es
	mov gs,ax
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
;
	call allocate_dir_entry
	jc create_dir_done
;
	push ax
	mov al,ds:drive_nr
	LockSector
	pop ax
	jc create_dir_done
;
	or si,ax
	call set_dir_name
	jc create_dir_unlock
;
	call init_dir
	jc create_dir_unlock
;
	mov es:[esi].fat_cluster,ax
	shr eax,16
	mov es:[esi].fat_cluster_hi,ax
	mov es:[esi].fat_attrib,10h
	mov es:[esi].fat_file_size,0
	push edx
	GetTime
	call set_dir_time
	pop edx
;
	ModifySector
	UnlockSector
;
	mov di,fs
	push edx
	call cache_dir_entry
;
	mov bx,fs
	CacheDir
;
	push gs
	push edi
;
	mov ax,cs
	mov gs,ax
;
	mov edi,OFFSET dot_dir
	mov edx,es:[edx].fde_start_cluster
	call add_dir
;
	mov edi,OFFSET dot_dot_dir
	mov edx,fs:ds_handle
	mov edx,es:[edx].fde_start_cluster
	call add_dir
;
	pop edi
	pop gs
;
	pop edx
	clc
	jmp create_dir_done

create_dir_unlock:
	mov di,fs
	call cache_free_entry
	UnlockSector
	stc

create_dir_done:
	pop esi
	pop cx
	pop ebx
	pop ax
	pop gs
	pop fs
	pop es
	ret
create_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_DIR
;
;		DESCRIPTION:	Delete directory
;
;		PARAMETERS:		BX			DIR SELECTOR
;						EDX			DIR ENTRY TO DELETE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public delete_dir

delete_dir	PROC far
	push es
	push fs
	pushad
;
	mov ax,flat_sel
	mov es,ax
	mov eax,es:[edx].fde_entry_sector
	mov cx,es:[edx].fde_entry_offset
	mov edi,es:[edx].fde_start_cluster
	mov es:[edx].fe_entry_sector,eax
	mov es:[edx].fe_entry_offset,cx
	call InsertDeletedEntry
;
	mov fs,bx
	mov edx,eax
	mov al,ds:drive_nr
	LockSector
	or si,cx
	mov byte ptr es:[esi],0E5h
	ModifySector
	UnlockSector
;
	mov edx,edi

delete_dir_cluster_loop:
	mov ebx,edx
	call next_cluster
	jc delete_dir_free_last
;
	xchg ebx,edx
	call free_cluster
	jc delete_dir_done
;
	mov edx,ebx
	jmp delete_dir_cluster_loop

delete_dir_free_last:
	mov edx,ebx
	call free_cluster

delete_dir_done:
	popad
	pop fs
	pop es
	clc
	ret
delete_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_FILE
;
;		DESCRIPTION:	Delete file
;
;		PARAMETERS:		BX			DIR SELECTOR
;						EDX			FILE ENTRY TO DELETE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public delete_file

delete_file	PROC far
	push ds
	push es
	pushad
;
	mov ax,flat_sel
	mov es,ax
	mov eax,es:[edx].ffe_entry_sector
	mov cx,es:[edx].ffe_entry_offset
	mov es:[edx].fe_entry_sector,eax
	mov es:[edx].fe_entry_offset,cx
	call InsertDeletedEntry
;
	mov ds,bx
	mov edx,eax
	mov al,ds:ds_drive
	LockSector
	or si,cx
	mov byte ptr es:[esi],0E5h
	ModifySector
	UnlockSector
;
	popad
	pop es
	pop ds
	clc
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

	public rename_file

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
;	call parse_dir
;	call parse_file
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
;	call parse_dir
	mov al,gs:[edx]
	or al,al
	je rename_dest_fail
	mov ax,fs
	cmp ax,cx
	jne rename_dest_fail
;	call parse_file
	jnc rename_dest_fail
	pop edi
;	call lock_dir_entry
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
;		NAME:			CREATE_FILE
;
;		DESCRIPTION:	Create a file
;
;		PARAMETERS:		ES:EDI		Filename
;						BX			Dir
;						CX			Attribute
;
;		RETURNS:		EDX			Dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public create_file

create_file	PROC far
	push es
	push fs
	push gs
	push ax
	push ebx
	push cx
	push esi
;
	mov ax,es
	mov gs,ax
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
;
	call allocate_dir_entry
	jc create_file_done
;
	push ax
	mov al,ds:drive_nr
	LockSector
	pop ax
	jc create_file_done
;
	or si,ax
	call set_dir_name
	jc create_file_unlock
;
	or cl,20h
	mov es:[esi].fat_attrib,cl
	mov es:[esi].fat_cluster,0
	mov es:[esi].fat_cluster_hi,0
	mov es:[esi].fat_file_size,0
	push eax
	push edx
	GetTime
	call set_dir_time
	pop edx
	pop eax
;
	ModifySector
	UnlockSector
	mov di,fs
	call cache_file_entry
	clc
	jmp create_file_done

create_file_unlock:
	mov di,fs
	call cache_free_entry
	UnlockSector
	stc

create_file_done:
	pop esi
	pop cx
	pop ebx
	pop ax
	pop gs
	pop fs
	pop es
	ret
create_file	ENDP

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

	public update_dir

update_dir	PROC far
	push es
	pushad
;
	mov ax,flat_sel
	mov es,ax
;
	mov edi,edx
	mov edx,es:[edi].fde_entry_sector
	mov al,ds:drive_nr
	LockSector
	jc update_dir_entry_done
;
	or si,es:[edi].fde_entry_offset
	mov cl,es:[edi].de_attrib
	and cl,NOT 10h
	mov ch,es:[esi].fat_attrib
	and ch,10h
	or cl,ch
	mov es:[esi].fat_attrib,cl
	mov eax,es:[edi].de_time
	mov edx,es:[edi].de_time+4
	call set_dir_time
;
	ModifySector
	UnlockSector

update_dir_entry_done:
	popad
	pop es
	ret
update_dir	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			update_file_entry
;
;		DESCRIPTION:	Update file entry
;
;		PARAMETERS:		EDX			Dir file entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public update_file

update_file	PROC far
	push es
	pushad
;
	mov ax,flat_sel
	mov es,ax
;
	mov edi,edx
	mov edx,es:[edi].ffe_entry_sector
	mov al,ds:drive_nr
	LockSector
	jc update_file_entry_done
;
	or si,es:[edi].ffe_entry_offset
	mov cl,es:[edi].de_attrib
	and cl,NOT 10h
	mov ch,es:[esi].fat_attrib
	and ch,10h
	or cl,ch
	mov es:[esi].fat_attrib,cl
	mov eax,es:[edi].de_time
	mov edx,es:[edi].de_time+4
	call set_dir_time
;
	ModifySector
	UnlockSector

update_file_entry_done:
	popad
	pop es
	ret
update_file	ENDP
	

code	ENDS

	END

