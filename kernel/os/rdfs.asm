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
; RDFS.ASM
; RDFS (RDOS File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME rdfs

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
INCLUDE rdfs.inc

attr_read_only		EQU 1
attr_hidden			EQU 2
attr_system			EQU 4
attr_volume			EQU 8
attr_dir			EQU 10h
attr_arcive			EQU 20h

	extrn ExtentSizeTab:near
	extrn CryptTab:near
	extrn KeyTab:near
	extrn get_param:near

	extrn cache_dir:near
	extrn create_dir:near
	extrn delete_dir:near
	extrn delete_file:near
	extrn rename_file:near
	extrn create_file:near
	extrn update_dir:near
	extrn update_file:near

	extrn set_file_size:near
	extrn allocate_file_list:near
	extrn free_file_list:near
	extrn read_file_block:near
	extrn write_file_block:near

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetRdfsInfo
;
;		DESCRIPTION:	Get RDFS info
;
;		PARAMETERS:		DS:(E)SI		Main key buffer
;						ES:(E)DI		Selection key buffer
;						GS:(E)BX		Extent size buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_rdfs_info_name	DB 'Get RDFS info',0

get_rdfs_info	Proc near
	push ds
	push ecx
	push esi
	push edi
;
	push ds
	push esi
;
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET KeyTab
	mov ecx,2 * 4096
	rep movs dword ptr es:[edi],[esi]
	pop edi
	pop es
;
	mov esi,OFFSET CryptTab
	mov ecx,4096 / 4
	rep movs dword ptr es:[edi],[esi]
;
	mov ax,gs
	mov es,ax
	mov edi,ebx
	mov esi,OFFSET ExtentSizeTab
	mov ecx,80h
	rep movs dword ptr es:[edi],[esi]
;
	pop edi
	pop esi
	pop ecx
	pop ds
	ret
get_rdfs_info	Endp

get_rdfs_info32	Proc far
	call get_rdfs_info
	retf32
get_rdfs_info32	Endp

get_rdfs_info16	Proc far
	push ebx
	push esi
	push edi
;
	movzx ebx,bx
	movzx esi,si
	movzx edi,di
	call get_rdfs_info
;
	pop edi
	pop esi
	pop ebx
	ret
get_rdfs_info16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDrive
;
;		DESCRIPTION:	Create drive
;
;		PARAMETERS:		AL			Drive
;						ECX			Number of sectors
;
;		RETURNS:		DS			Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDrive	Proc near
	push es
	push eax
	push edx
;
	mov eax,SIZE drive_data_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
;
	mov ds:info_sector.ri_free_arr,2
	mov edx,ecx
	shr edx,7
	inc edx
	mov ds:info_sector.ri_free_arr_size,edx
	add edx,2
	mov ds:info_sector.ri_root_dir,edx
	sub edx,ecx
	neg edx
	mov ds:info_sector.ri_total_sectors,edx
	sub edx,4
	mov ds:info_sector.ri_free_sectors,edx
;
	pop edx
	pop eax
	mov ds:drive_nr,al
	pop es
	ret
CreateDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteInfoSector
;
;		DESCRIPTION:	Write info sector
;
;		PARAMETERS:		DS			Drive
;						ECX			Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInfoSector	Proc near
	pushad
;
	mov al,ds:drive_nr
	mov edx,1
	NewSector
;
	mov edi,esi
	mov ecx,128
	xor eax,eax
	rep stos dword ptr es:[edi]
;
	mov esi,OFFSET info_sector
	mov ecx,SIZE rdfs_info_struc
	rep movs byte ptr es:[edi],[esi]
;
	ModifySector
	UnlockSector
;
	popad
	ret
WriteInfoSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteAllocationArr
;
;		DESCRIPTION:	Write allocate array
;
;		PARAMETERS:		DS			Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteAllocationArr	Proc near
	pushad
;
	mov al,ds:drive_nr
	mov edx,2
	NewSector
;
	mov eax,-1
	mov ecx,ds:info_sector.ri_root_dir
write_alloc_used_loop:
	mov dword ptr es:[esi],eax
	add esi,4
	test si,01FFh
	jnz write_alloc_used_next
;
	ModifySector
	UnlockSector
	inc edx
	push ax
	mov al,ds:drive_nr
	NewSector
	pop ax

write_alloc_used_next:
	loop write_alloc_used_loop
;
	xor eax,eax

write_alloc_free_loop:
	mov dword ptr es:[esi],eax
	add esi,4
	test si,01FFh
	jnz write_alloc_free_loop
;
	ModifySector
	UnlockSector
	inc edx
	cmp edx,ds:info_sector.ri_root_dir
	je write_alloc_done
;
	push ax
	mov al,ds:drive_nr
	NewSector
	pop ax
	jmp write_alloc_free_loop

write_alloc_done:
	popad
	ret
WriteAllocationArr	Endp

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
	push ds
	push es
	pushad
;
	int 3
	mov bx,flat_sel
	mov es,bx
	call CreateDrive
	call WriteInfoSector
	call WriteAllocationArr
;
	mov bx,ds
	mov es,bx
	xor bx,bx
	mov ds,bx
	FreeMem
	clc
;
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
;		RETRUNS:		DS:SI		ADDRESS TO DRIVE DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mount	PROC far
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
	call get_param
;
	pop es
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
	mov eax,ds:ri_free_sectors
	mov edx,ds:ri_total_sectors
	mov cx,200h
	clc
	ret
get_drive_info	ENDP

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Dummy
;
;		DESCRIPTION:	Unsupported functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy	PROC far
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

rdfs_name	DB 'RDFS',0

rdfs_ctrl:
rdfs00	DW OFFSET format,			rdfs_code_sel
rdfs01	DW OFFSET mount,			rdfs_code_sel
rdfs02	DW OFFSET flush,			rdfs_code_sel
rdfs03	DW OFFSET dismount,			rdfs_code_sel
rdfs04	DW OFFSET get_drive_info,	rdfs_code_sel
rdfs05	DW OFFSET cache_dir,		rdfs_code_sel
rdfs06	DW OFFSET update_dir,		rdfs_code_sel
rdfs07	DW OFFSET update_file,		rdfs_code_sel
rdfs08	DW OFFSET create_dir,		rdfs_code_sel
rdfs09	DW OFFSET delete_dir,		rdfs_code_sel
rdfs10	DW OFFSET delete_file,		rdfs_code_sel
rdfs11	DW OFFSET rename_file,		rdfs_code_sel
rdfs12	DW OFFSET create_file,		rdfs_code_sel
rdfs13	DW OFFSET get_ioctl_data,	rdfs_code_sel
rdfs14	DW OFFSET set_file_size,	rdfs_code_sel
rdfs15	DW OFFSET dummy,			rdfs_code_sel
rdfs16	DW OFFSET dummy,			rdfs_code_sel
rdfs17	DW OFFSET allocate_file_list,rdfs_code_sel
rdfs18	DW OFFSET free_file_list,	rdfs_code_sel
rdfs19	DW OFFSET read_file_block,	rdfs_code_sel
rdfs20	DW OFFSET write_file_block,	rdfs_code_sel

init	PROC far
	push ds
	push es
	push fs
	push gs
	pushad
	mov bx,rdfs_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET get_rdfs_info32
	mov di,OFFSET get_rdfs_info_name
	xor cl,cl
	mov ax,get_rdfs_info_nr
	RegisterUserGate32
;
	mov si,OFFSET get_rdfs_info16
	mov di,OFFSET get_rdfs_info_name
	xor cl,cl
	mov ax,get_rdfs_info_nr
	RegisterUserGate16
;
	mov si,OFFSET rdfs_name
	mov di,OFFSET rdfs_ctrl
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
