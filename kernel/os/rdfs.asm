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
	int 3
	stc
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
rdfs00	DW OFFSET mount,			rdfs_code_sel
rdfs01	DW OFFSET flush,			rdfs_code_sel
rdfs02	DW OFFSET dismount,			rdfs_code_sel
rdfs03	DW OFFSET get_drive_info,	rdfs_code_sel
rdfs04	DW OFFSET cache_dir,		rdfs_code_sel
rdfs05	DW OFFSET update_dir,		rdfs_code_sel
rdfs06	DW OFFSET update_file,		rdfs_code_sel
rdfs07	DW OFFSET create_dir,		rdfs_code_sel
rdfs08	DW OFFSET delete_dir,		rdfs_code_sel
rdfs09	DW OFFSET delete_file,		rdfs_code_sel
rdfs10	DW OFFSET rename_file,		rdfs_code_sel
rdfs11	DW OFFSET create_file,		rdfs_code_sel
rdfs12	DW OFFSET get_ioctl_data,	rdfs_code_sel
rdfs13	DW OFFSET set_file_size,	rdfs_code_sel
rdfs14	DW OFFSET dummy,			rdfs_code_sel
rdfs15	DW OFFSET dummy,			rdfs_code_sel
rdfs16	DW OFFSET allocate_file_list,rdfs_code_sel
rdfs17	DW OFFSET free_file_list,	rdfs_code_sel
rdfs18	DW OFFSET read_file_block,	rdfs_code_sel
rdfs19	DW OFFSET write_file_block,	rdfs_code_sel

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
