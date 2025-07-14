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
; FLASHFS.ASM
; FLASHFS (Flash File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

	extrn allocate_dir_sel:far
	extrn free_dir_sel:far
	extrn cache_dir:far
	extrn create_file:far
	extrn delete_file:far

    extrn EraseBlock:near
    extrn AllocateBlock:near
    extrn InitBlock:near
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
	push gs
	push eax
	push ebx
	push ecx
	push edx
	push edi
;
	push ax
;
	push ecx
	GetDriveParam
	pop ecx
;
	mov eax,ecx
	xor edx,edx
	movzx esi,si
	div esi
	mov ecx,eax

mount_block_norm:
	cmp ecx,100h
	jb mount_block_ok
;
	shr ecx,1
	shl esi,1
	jmp mount_block_norm

mount_block_ok:		
	mov eax,SIZE drive_data_seg
	add eax,ecx
	add eax,ecx
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	pop ax
;
	mov ds:block_count,cl
	mov ds:block_sectors,si
	mov ds:drive_nr,al
;
	mov ax,ds:block_sectors
	shr ax,6
	inc ax
	mov dx,ax
	shr dx,1
	add ax,dx
	mov ds:control_sectors,ax
	mov dx,ds:block_sectors
	sub dx,ax
	mov ds:data_sectors,dx
;
    movzx eax,ds:block_count
    add eax,eax
    AllocateSmallGlobalMem
;
    push cx    
    xor di,di
    xor ax,ax
    rep stosw
    pop cx
;
    xor edx,edx
	mov di,SIZE drive_data_seg

mount_cache_loop:
    push es
	mov ax,flat_sel
	mov es,ax
	call InitBlock
	pop es
	mov word ptr ds:[di],0
;	
    mov ax,gs
    or ax,ax
    jnz mount_cache_check
;
	mov ds:spare_sector,edx
	jmp mount_cache_next

mount_cache_check:
    movzx bx,gs:bc_logical_block
    add bx,bx
;
    mov ax,es:[bx]
    or ax,ax
    jz mount_cache_save
;
    push es
    mov es,ax
    mov ax,es:bc_version
    pop es
    cmp ax,gs:bc_version
    jl mount_cache_save_this
;
    push es
    push edx
    mov ax,gs
    mov es,ax
    xor ax,ax
    mov gs,ax
    mov edx,es:bc_start_sector
	mov ds:spare_sector,edx
    call EraseBlock
    FreeMem
    pop es
    jmp mount_cache_next
    
mount_cache_save_this:
    push es
    push edx
    mov es,es:[bx]
    mov edx,es:bc_start_sector
    call EraseBlock
	mov ds:spare_sector,edx
    FreeMem
    pop edx
    pop es

mount_cache_save:
    mov es:[bx],gs
	mov ds:[di],gs

mount_cache_next:	
	add di,2
	movzx eax,ds:block_sectors
    add edx,eax
    sub cx,1
	jnz mount_cache_loop
;
    xor bx,bx
    xor si,si
    movzx cx,ds:block_count
    dec cx

mount_init_loop:
    mov ax,es:[si]
    or ax,ax
    jnz mount_init_cache
;
    push es
    mov ax,flat_sel
    mov es,ax
    call AllocateBlock
    pop es
    mov es:[si],gs
    jmp mount_init_next

mount_init_cache:
    push es
    mov gs,ax
	mov ax,flat_sel
	mov es,ax
	call CacheBlock
	pop es

mount_init_next:
    add si,2
    inc bx
    loop mount_init_loop
;
    xor si,si
    mov di,SIZE drive_data_seg
    movzx cx,ds:block_count
    dec cx

mount_move_loop:
    mov ax,es:[si]
    mov [di],ax
    add si,2
    add di,2
    loop mount_move_loop
;
    mov word ptr [di],0
;
    FreeMem
	xor si,si
;
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop gs
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
	push gs
	push di
;
	xor edx,edx
	movzx cx,ds:block_count
	mov di,SIZE drive_data_seg

get_info_loop:
	mov ax,ds:[di]
	or ax,ax
	jz get_info_next
;	
	push cx
	mov gs,ax
	call GetFreeBlockSectors
	add edx,ecx
	pop cx
	jmp get_info_next

get_info_next:
	add di,2
    loop get_info_loop
;
	push edx
	mov cx,512
	movzx eax,ds:block_count
	movzx edx,ds:data_sectors
	mul edx
	mov edx,eax
	pop eax
	clc
;
	pop di
	pop gs
	ret
get_drive_info	ENDP


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
ffs00	DW OFFSET format,			SEG code
ffs01	DW OFFSET mount,			SEG code
ffs02	DW OFFSET flush,		    SEG code
ffs03	DW OFFSET dismount,			SEG code
ffs04	DW OFFSET get_drive_info,	SEG code
ffs05	DW OFFSET allocate_dir_sel,	SEG code
ffs06	DW OFFSET free_dir_sel,		SEG code
ffs07	DW OFFSET cache_dir,		SEG code
ffs08	DW OFFSET update_dir,		SEG code
ffs09	DW OFFSET update_file,		SEG code
ffs10	DW OFFSET create_dir,		SEG code
ffs11	DW OFFSET delete_dir,		SEG code
ffs12	DW OFFSET delete_file,		SEG code
ffs13	DW OFFSET rename_file,		SEG code
ffs14	DW OFFSET create_file,		SEG code
ffs15	DW OFFSET get_ioctl_data,	SEG code
ffs16	DW OFFSET set_file_size,	SEG code
ffs17	DW OFFSET read_file,		SEG code
ffs18	DW OFFSET write_file,		SEG code
ffs19	DW OFFSET allocate_file_list,SEG code
ffs20	DW OFFSET free_file_list,	SEG code
ffs21	DW OFFSET read_file_block,	SEG code
ffs22	DW OFFSET write_file_block,	SEG code

init	PROC far
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET flashfs_name
	mov di,OFFSET flashfs_ctrl
	RegisterFileSystem
	ret
init	ENDP

code	ENDS

	END init
