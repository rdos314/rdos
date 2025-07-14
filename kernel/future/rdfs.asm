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
; RDFS.ASM
; RDFS (RDOS File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\fs.inc
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
	extrn FormatInfoSector:near
	extrn FormatAllocationArr:near
	extrn FreeAllocationArr:near
	extrn CreateRootDir:near

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
	mov ecx,2 * 2048
	rep movs dword ptr es:[edi],ds:[esi]
	pop edi
	pop es
;
	mov esi,OFFSET CryptTab
	mov ecx,4096 / 4
	rep movs dword ptr es:[edi],ds:[esi]
;
	mov ax,gs
	mov es,ax
	mov edi,ebx
	mov esi,OFFSET ExtentSizeTab
	mov ecx,80h
	rep movs dword ptr es:[edi],ds:[esi]
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
	mov ds:info_sector.ri_first_id,1
	mov ds:info_sector.ri_last_id,1
	mov ds:info_sector.ri_state, INFO_STATE_NONE
	mov ds:info_sector.ri_free_arr,3
	mov ds:info_sector.ri_total_sectors,ecx
	mov edx,ecx
	shr edx,7
	inc edx
	mov ds:info_sector.ri_free_arr_size,edx
	add edx,3
	mov ds:info_sector.ri_start_sector,edx
	mov ds:info_sector.ri_root_dir,edx
	mov ds:info_sector.ri_hole_start,edx
	sub edx,ecx
	neg edx
	mov ds:info_sector.ri_data_sectors,edx
	mov ds:info_sector.ri_free_sectors,edx
	mov ds:info_sector.ri_hole_size,edx
	InitSection ds:alloc_section
	mov ds:alloc_sel,0
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
	mov bx,flat_sel
	mov es,bx
	call CreateDrive
	call FreeAllocationArr
	call FormatInfoSector
	call FormatAllocationArr
	call CreateRootDir
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
	mov edx,ds:ri_data_sectors
	mov cx,200h
	clc
	ret
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
	ret
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
	ret
free_dir_sel	ENDP


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
rdfs05	DW OFFSET allocate_dir_sel,	rdfs_code_sel
rdfs06	DW OFFSET free_dir_sel,		rdfs_code_sel
rdfs07	DW OFFSET cache_dir,		rdfs_code_sel
rdfs08	DW OFFSET update_dir,		rdfs_code_sel
rdfs09	DW OFFSET update_file,		rdfs_code_sel
rdfs10	DW OFFSET create_dir,		rdfs_code_sel
rdfs11	DW OFFSET delete_dir,		rdfs_code_sel
rdfs12	DW OFFSET delete_file,		rdfs_code_sel
rdfs13	DW OFFSET rename_file,		rdfs_code_sel
rdfs14	DW OFFSET create_file,		rdfs_code_sel
rdfs15	DW OFFSET get_ioctl_data,	rdfs_code_sel
rdfs16	DW OFFSET set_file_size,	rdfs_code_sel
rdfs17	DW OFFSET dummy,			rdfs_code_sel
rdfs18	DW OFFSET dummy,			rdfs_code_sel
rdfs19	DW OFFSET allocate_file_list,rdfs_code_sel
rdfs20	DW OFFSET free_file_list,	rdfs_code_sel
rdfs21	DW OFFSET read_file_block,	rdfs_code_sel
rdfs22	DW OFFSET write_file_block,	rdfs_code_sel

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
	mov bx,OFFSET get_rdfs_info16
	mov si,OFFSET get_rdfs_info32
	mov di,OFFSET get_rdfs_info_name
	mov dx,virt_ds_in OR virt_es_in OR virt_gs_in
	mov ax,get_rdfs_info_nr
	RegisterUserGate
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
