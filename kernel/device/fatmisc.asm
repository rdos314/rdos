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
; FATMISC.ASM
; Untilty functions for FAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME fatmisc

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\fs.inc
INCLUDE fat.inc

boot_struc	STRUC

boot_jmp					DB ?,?,?
boot_name					DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_sectors_per_cluster	DB ?
boot_resv_sectors			DW ?
boot_fats					DB ?
boot_root_dirs				DW ?
boot_sectors16				DW ?
boot_media					DB ?
boot_fat_sectors16			DW ?
boot_sectors_per_cyl		DW ?
boot_heads					DW ?
boot_hidden_sectors			DD ?
boot_sectors				DD ?
boot_fat_sectors			DD ?
boot_ext_flags				DW ?
boot_fs_version				DW ?
boot_root_cluster			DD ?
boot_info_sector			DW ?
boot_backup_sector			DW ?

boot_struc		ENDS

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

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LOCK_SECTOR
;
;		DESCRIPTION:	Lock a sector
;
;		PARAMETERS:		AL			Drive #
;						EDX			Sector to first FAT
;
;		RETURNS:		EBX			Sector handle
;						ESI			Linear address
;						NC			OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lock_sector

lock_sector	PROC near
	LockSector
	ret
lock_sector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_PARAM
;
;		DESCRIPTION:	Read drive parameters from boot-record
;
;		RETRUNS:		DS			Drive data
;						ES			FLAT_SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public get_param

get_param	Proc near
	push ax
	push ebx
	push ecx
	push edx
	push esi
;
	InitSection ds:cluster_section
	mov ds:drive_root_handle,0
	mov ds:drive_nr,al
	mov ds:file_list_ptr,0
	mov ds:file_free_ptr,0
	xor edx,edx
	LockSector
	mov cl,es:[esi].boot_sectors_per_cluster
	mov ch,0
get_param_shift_loop:
	rcr cl,1	
	jc get_param_shift_ok
	inc ch
	jmp get_param_shift_loop
get_param_shift_ok:
	mov ds:fat_cluster_shift,ch
	mov cx,es:[esi].boot_root_dirs
	mov ds:root_entries,cx
	movzx edx,es:[esi].boot_resv_sectors
	mov ds:fat1_sector,edx
	movzx ecx,es:[esi].boot_fat_sectors16
	or cx,cx
	jnz get_param_fat_sectors16
;
	mov ax,es:[esi].boot_root_dirs
	or ax,ax
	jnz get_param_fat_sectors16

get_param_fat_sectors32:
	mov ecx,es:[esi].boot_fat_sectors
	add edx,ecx
	mov ds:fat2_sector,edx
	add edx,ecx
	mov ds:start_sector,edx
	mov edx,es:[esi].boot_root_cluster
	sub edx,2
	mov cl,ds:fat_cluster_shift
	shl edx,cl
	add edx,ds:start_sector
	mov ds:root_sector,edx
	mov edx,es:[esi].boot_sectors
	jmp get_param_total_ok

get_param_fat_sectors16:
	add edx,ecx
	mov ds:fat2_sector,edx
	add edx,ecx
	mov ds:root_sector,edx
	movzx ecx,ds:root_entries
	shr ecx,4
	add edx,ecx
	mov ds:start_sector,edx
	movzx edx,es:[esi].boot_sectors16
	or edx,edx
	jnz get_param_total_ok
	mov edx,es:[esi].boot_sectors

get_param_total_ok:
	sub edx,ds:start_sector
	mov cl,ds:fat_cluster_shift
	shr edx,cl
	add edx,2
	mov ds:clusters,edx
	UnlockSector
;
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ax
	ret
get_param	Endp

code	ENDS

	END

