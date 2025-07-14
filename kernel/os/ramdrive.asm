;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; RAMDRIVE.ASM
; Preloadable in-system drive (z:) support.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\fs.inc

MAX_RAM_DRIVES		EQU 4

dev_name		EQU 8
dev_param		EQU 90h
dev_next		EQU 0E0h
dev_type		EQU 0E4h
dev_ip			EQU 0FAh

old_file_header	STRUC

old_head_base		DB 8 DUP(?)
old_head_ext		DB 3 DUP(?)
old_head_attrib		DB ?
old_head_resv		DB 10 DUP(?)
old_head_time		DW ?
old_head_date		DW ?
old_head_cluster	DW ?
old_head_size		DD ?
old_head_data		DB ?

old_file_header	ENDS

file_header	STRUC

head_size           DD ?
head_lsb            DD ?
head_msb            DD ?
head_file_size      DD ?
head_attrib         DB ?
head_name           DB ?

file_header	ENDS

rde_struc	STRUC

rde_base	dir_dir_entry_data_struc <>

rde_ptr			DD ?
rde_data		DD ?
rde_name		DB ?

rde_struc	ENDS

rfe_struc	STRUC

rfe_base	dir_file_entry_data_struc <>

rfe_ptr			DD ?
rfe_data		DD ?
rfe_name		DB ?

rfe_struc	ENDS

drive_data_seg	STRUC

drive_list_ptr	DD ?
drive_root_ptr	DD ?
drive_free_ptr	DD ?
drive_nr		DB ?

drive_data_seg	ENDS

data    SEGMENT byte public 'DATA'

drive_count		DW ?
drive_arr		DW 26 DUP(?)
drive_sel_arr	DW MAX_RAM_DRIVES DUP(?)

data    ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format	PROC far
	stc
	retf32
format	Endp

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
	mov ax,SEG data
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
	pop bx
	pop es
	retf32
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
	stc
	retf32
flush	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISMOUNT
;
;		DESCRIPTION:	Unmount filesystem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dismount	PROC far
	retf32
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
	push edx
	GetFreePhysical
	pop edx
	shr edx,12
	shr eax,12
	mov cx,1000h
	clc
	retf32
get_drive_info	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateDirSel
;
;		DESCRIPTION:	Allocate dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dir_sel	PROC far
	push es
	push eax
;
	mov eax,SIZE dir_sel_data_struc
	AllocateSmallGlobalMem
	mov bx,es
;
	pop eax
	pop es
	retf32
allocate_dir_sel	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeDirSel
;
;		DESCRIPTION:	Free dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dir_sel	PROC far
	push es
;
	mov es,bx
	FreeMem
;
	pop es
	retf32
free_dir_sel	ENDP


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
	push es
	push fs
	push gs
	push eax
	push bx
	push ecx
	push edi
	push ebp
;
	mov ax,es
	mov gs,ax
	mov ebp,edi
	mov fs,bx
;
	call get_file_name_size
	mov ax,flat_sel
	mov es,ax
	mov eax,SIZE rde_struc
	add eax,ecx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET rde_name
	mov es:[edi].de_name,edx
	mov es:[edi].de_name_size,cx
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,1
	mov es:[edi].de_attrib,10h
;
	push esi
	push edi
	mov esi,ebp
	mov edi,edx
	rep movs byte ptr es:[edi],gs:[esi]
	xor al,al
	stos byte ptr es:[edi]
	pop edi
	pop esi
;
	GetTime
	mov es:[edi].de_time,eax
	mov es:[edi+4].de_time,edx
;
	mov bx,fs
	mov edx,edi
	InsertDirEntry
	clc
;
	pop ebp
	pop edi
	pop ecx
	pop bx
	pop eax
	pop gs
	pop fs
	pop es
	retf32
create_dir	ENDP


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
	push ecx
	xor ecx,ecx
	FreeLinear
	pop ecx
	clc
	retf32
delete_dir	ENDP


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

delete_file	PROC far
	push ecx
	xor ecx,ecx
	FreeLinear
	pop ecx
	clc
	retf32
delete_file	ENDP


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
	retf32
rename_file	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_file_name_size
;
;		DESCRIPTION:	Get file name size
;
;		PARAMETERS:		ES:EDI		Filename
;
;		RETURNS:		ECX			File name size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_name_size	Proc near
	push ax
	push edi
;
	xor ecx,ecx

get_name_size_loop:
	mov al,es:[edi]
	inc ecx
	inc edi
	or al,al
	jnz get_name_size_loop
;
	dec ecx
	pop edi
	pop ax
	ret
get_file_name_size	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_FILE
;
;		DESCRIPTION:	Create file
;
;		PARAMETERS:		ES:EDI		Filename
;						BX			Dir
;						CX			Attribute
;
;		RETURNS:		EDX			Dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_file	PROC far
	push es
	push fs
	push gs
	push eax
	push bx
	push edi
	push ebp
;
	mov ax,es
	mov gs,ax
	mov ebp,edi
	mov fs,bx
;
	push ecx
	call get_file_name_size
	mov ax,flat_sel
	mov es,ax
	mov eax,SIZE rfe_struc
	add eax,ecx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET rfe_name
	mov es:[edi].de_name,edx
	mov es:[edi].de_name_size,cx
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,1
;
	push esi
	push edi
	mov esi,ebp
	mov edi,edx
	rep movs byte ptr es:[edi],gs:[esi]
	xor al,al
	stos byte ptr es:[edi]
	pop edi
	pop esi
;
	pop ecx
	mov es:[edi].de_attrib,cl
;
	GetTime
	mov es:[edi].de_time,eax
	mov es:[edi+4].de_time,edx
	mov es:[edi].dfe_file_sel,0
	mov es:[edi].dfe_data_size,0
;
	mov bx,fs
	mov edx,edi
	InsertFileEntry
	clc
;
	pop ebp
	pop edi
	pop bx
	pop eax
	pop gs
	pop fs
	pop es
	retf32
create_file	ENDP


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
	retf32
get_ioctl_data	ENDP


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
	push edi
;
	mov di,flat_sel
	mov es,di
	mov fs,bx
	mov fs:file_size,edx
	mov edi,fs:file_dir_entry
	mov es:[edi].dfe_data_size,edx
	clc
;
	pop edi
	pop fs
	pop es
	retf32
set_file_size	ENDP
	

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
	clc
	retf32
update_dir	ENDP
	

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
	clc
	retf32
update_file	ENDP
	

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
	mov esi,ds:file_dir_entry
	mov ax,flat_sel
	mov ds,ax
	mov eax,[esi].dfe_data_size
	mov esi,[esi].rfe_data
	sub eax,edx
	jc read_file_done
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
	add esi,edx
	mov eax,ecx
	shr ecx,2
	rep movs dword ptr es:[edi],ds:[esi]
	movzx ecx,al
	and cl,3
	rep movs byte ptr es:[edi],ds:[esi]
	clc

read_file_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ds
	retf32
read_file	ENDP


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
	stc
 	retf32
write_file	ENDP


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
	push eax
	push ecx
	push edx
;
	mov eax,SIZE file_list_struc
	AllocateSmallLinear
	mov edi,edx
;
	pop edx
	pop ecx
	pop eax
	clc
	retf32
allocate_file_list	ENDP


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
	push ecx
	push edx
;
	mov edx,edi
	mov ecx,SIZE file_list_struc
	FreeLinear
;
	pop edx
	pop ecx
	clc
	retf32
free_file_list	ENDP


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
	clc
	retf32
read_file_block	ENDP


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
	clc
	retf32
write_file_block	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_old_entry_name_size
;
;		DESCRIPTION:	Get old dir entry name size
;
;		PARAMETERS:		ESI		Entry data
;
;		RETURNS:		ECX		Size of entry name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_old_entry_name_size	Proc near
	push dx
	push esi
;
	xor ecx,ecx
	xor dl,dl
	mov cx,8

get_old_name_base_loop:
	lods byte ptr es:[esi]
	cmp al,' '
	je get_old_name_base_ok
;
	inc dl
	loop get_old_name_base_loop
;
	inc esi

get_old_name_base_ok:
	dec esi
	add esi,ecx
	inc dl
;
	mov cx,3

get_old_name_ext_loop:
	lods byte ptr es:[esi]
	cmp al,' '
	je get_old_name_ext_ok
;
	inc dl
	loop get_old_name_ext_loop

get_old_name_ext_ok:
	movzx ecx,dl
	pop esi
	pop dx
	ret
get_old_entry_name_size	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			copy_entry_name
;
;		DESCRIPTION:	Copy entry name
;
;		PARAMETERS:		ESI		Entry data
;						EDI		Dir entry name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy_entry_name	Proc near
	push dx
	push esi
	push edi
;
	mov edi,es:[edi].de_name
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
	pop edi
	mov es:[edi].de_name_size,dx
	pop esi
	pop dx
	ret
copy_entry_name	Endp

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
	mov dx,es:[esi].old_head_date
	mov ax,dx
	shr dx,9
	add dx,1980
	mov cx,ax
	shr cx,5
	mov ch,cl
	and ch,0Fh
	mov cl,al
	and cl,1Fh
	mov bx,es:[esi].old_head_time
	mov ax,bx
	shr bx,11
	mov bh,bl
	shr ax,5
	and al,3Fh
	mov bl,al
	mov ax,es:[esi].old_head_time
	mov ah,al
	add ah,ah
	and ah,3Fh
	TimeToBinary
;
	pop cx
	pop bx
	ret
get_entry_time	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_OLD_FILE_ENTRY
;
;		DESCRIPTION:	Cache old file entry
;
;		PARAMETERS:		ES:EDX	device header
;						FS		dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_old_file_entry	Proc near
	pushad
;
	mov esi,edx
	add esi,SIZE rdos_header
	call get_old_entry_name_size
	mov eax,SIZE rfe_struc
	add eax,ecx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET rfe_name
	mov es:[edi].de_name,edx
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0
	mov al,es:[esi].old_head_attrib
	or al,80h
	mov es:[edi].de_attrib,al
	call copy_entry_name
	call get_entry_time
	mov es:[edi].de_time,eax
	mov es:[edi+4].de_time,edx
	mov es:[edi].dfe_file_sel,0
	mov eax,es:[esi].old_head_size
	mov es:[edi].dfe_data_size,eax
	lea edx,[esi].old_head_data
	mov es:[edi].rfe_data,edx
;
	mov bx,fs
	mov edx,edi
	InsertFileEntry
;
	popad
	ret
cache_old_file_entry	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_FILE_ENTRY
;
;		DESCRIPTION:	Cache file entry
;
;		PARAMETERS:		ES:EDX	device header
;						FS		dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_file_entry	Proc near
	pushad
;
    add edx,SIZE rdos_header
	mov esi,edx
    add esi,OFFSET head_name
	xor ecx,ecx

cache_file_size_loop:
    inc ecx
    lods byte ptr es:[esi]
    or al,al
    jnz cache_file_size_loop
;
	mov esi,edx    
  	mov eax,SIZE rfe_struc
	add eax,ecx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET rfe_name
	mov es:[edi].de_name,edx
	mov ax,cx
	dec ax
	mov es:[edi].de_name_size,ax
;
    push esi
    push edi
    add esi,OFFSET head_name
    mov edi,es:[edi].de_name
    rep movs byte ptr es:[edi],es:[esi]
    pop edi
    pop esi
;	
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0
	mov al,es:[esi].head_attrib
	or al,80h
	mov es:[edi].de_attrib,al
	mov eax,es:[esi].head_lsb
	mov es:[edi].de_time,eax
    mov eax,es:[esi].head_msb
	mov es:[edi+4].de_time,eax
	mov es:[edi].dfe_file_sel,0
	mov eax,es:[esi].head_file_size
	mov es:[edi].dfe_data_size,eax
;
    mov eax,es:[esi].head_size
    add eax,esi
	mov es:[edi].rfe_data,eax
;
	mov bx,fs
	mov edx,edi
	InsertFileEntry
;
	popad
	ret
cache_file_entry	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			cache_adapter_files
;
;		DESCRIPTION:	cache all files in adapter
;
;		PARAMETERS:		EDX			base address
;						BX			Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_adapter_files	Proc near
	push ax
	push bx
	push edx

cache_adapter_files_loop:
	mov ax,es:[edx].typ
	cmp ax,RdosOldFile
	jne cache_not_old_file
;
	call cache_old_file_entry
	jmp cache_adapter_files_next

cache_not_old_file:	
	cmp ax,RdosFile
	jne cache_adapter_skip
;
	call cache_file_entry
	jmp cache_adapter_files_next

cache_adapter_skip:
	cmp ax,RdosEnd
	je cache_adapter_files_done

cache_adapter_files_next:
	add edx,es:[edx].len
	jmp cache_adapter_files_loop

cache_adapter_files_done:
	pop edx
	pop bx
	pop ax
	ret
cache_adapter_files	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Cache_adapter
;
;		DESCRIPTION:	Cache adapter
;
;		PARAMETERS:		EDX			Dir entry to cache or 0
;						BX			Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_adapter	Proc near
	push es
	push fs
	push gs
	pushad
;
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
	mov ax,system_data_sel
	mov gs,ax
	mov cx,gs:rom_modules
	mov bx,OFFSET rom_adapters
	mov esi,2
	xor edi,edi
cache_adapter_loop:
	mov edx,gs:[bx].adapter_base
	call cache_adapter_files
	add bx,SIZE adapter_typ
	loop cache_adapter_loop	
;
	popad
	pop gs
	pop fs
	pop es
	ret
cache_adapter	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Cache_dir
;
;		DESCRIPTION:	Cache dir
;
;		PARAMETERS:		EDX			Dir entry to cache or 0
;						BX			Cached dir selector
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_dir	PROC far
	or edx,edx
	jnz cache_dir_subdir
;
	call cache_adapter
	jmp cache_dir_done

cache_dir_subdir:

cache_dir_done:
	retf32
cache_dir	Endp


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
	retf32
dummy	Endp

fs_name	DB 'MEMORY',0

fs_ctrl:
fs00	DD OFFSET format,			SEG code
fs01	DD OFFSET mount,			SEG code
fs02	DD OFFSET flush,			SEG code
fs03	DD OFFSET dismount,			SEG code
fs04	DD OFFSET get_drive_info,	SEG code
fs05	DD OFFSET allocate_dir_sel,	SEG code
fs06	DD OFFSET free_dir_sel,		SEG code
fs07	DD OFFSET cache_dir,		SEG code
fs08	DD OFFSET update_dir,		SEG code
fs09	DD OFFSET update_file,		SEG code
fs10	DD OFFSET create_dir,		SEG code
fs11	DD OFFSET delete_dir,		SEG code
fs12	DD OFFSET delete_file,		SEG code
fs13	DD OFFSET rename_file,		SEG code
fs14	DD OFFSET create_file,		SEG code
fs15	DD OFFSET get_ioctl_data,	SEG code
fs16	DD OFFSET set_file_size,	SEG code
fs17	DD OFFSET read_file,		SEG code
fs18	DD OFFSET write_file,		SEG code
fs19	DD OFFSET allocate_file_list,SEG code
fs20	DD OFFSET free_file_list,	SEG code
fs21	DD OFFSET read_file_block,	SEG code
fs22	DD OFFSET write_file_block,	SEG code

    public init_ramdrive
    
init_ramdrive	PROC near
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov ds:drive_count,0
    mov cx,26
    xor ax,ax
    mov di,OFFSET drive_arr
    rep stosw
    mov cx,MAX_RAM_DRIVES
    mov di,OFFSET drive_sel_arr
    rep stosw
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET fs_name
    mov edi,OFFSET fs_ctrl
    RegisterFileSystem
;
    mov al,'Z' - 'A'
    AllocateFixedDrive
    mov edi,OFFSET fs_name
    InstallFileSystem
    mov ecx,-1
    StartFileSystem
    ret
init_ramdrive	ENDP

code	ENDS

	END

