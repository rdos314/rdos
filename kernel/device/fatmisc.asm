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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CHECK_FILE_ATTRIBUTE
;
;		DESCRIPTION:	Check file attribute
;
;		PARAMETERS:		DL		Check attribute
;						DH		Actual attribute
;
;		RETRUNS:		NC		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_file_attribute	PROC near
	push dx
	and dl,NOT 21h
	and dh,NOT 21h
	or dh,dh
	jz check_file_attrib_file
	test dh,10h
	jnz check_file_attrib_dir
	test dh,8
	jnz check_file_attrib_volume
	and dh,6
	and dl,6
	cmp dl,dh
	je check_file_attrib_ok
	jmp check_file_attrib_fail
check_file_attrib_volume:
	test dl,8
	jnz check_file_attrib_ok
	jmp check_file_attrib_fail	
check_file_attrib_dir:
	test dl,10h
	jnz check_file_attrib_ok
	jmp check_file_attrib_fail	
check_file_attrib_file:
	cmp dl,8
	jne check_file_attrib_ok
	jmp check_file_attrib_fail
check_file_attrib_fail:
	stc
	pop dx
	ret
check_file_attrib_ok:
	clc
	pop dx
	ret
check_file_attribute	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SETUP_DIR_ENTRY
;
;		DESCRIPTION:	Setup directory entry from string
;
;		PARAMETERS:		SS:BP		12 BYTE BUFFER
;						ES:EDI		PATHNAME
;
;		RETURNS:		NC			SUCCESS
;						CY			FAILED
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat_base_done	PROC near
	mov ah,' '
fat_base_pad:
	mov ss:[bp],ah
	inc bp
	loop fat_base_pad
	dec edi
	clc
	ret
fat_base_done	ENDP

fat_base_illegal	PROC near
	stc
	ret
fat_base_illegal	ENDP

fat_base_save	PROC near
	mov ss:[bp],al
	inc bp
	dec cx
	clc
	ret
fat_base_save	ENDP

fat_base_save_uppercase	PROC near
	sub al,20h
	mov ss:[bp],al
	inc bp
	dec cx
	clc
	ret
fat_base_save_uppercase	ENDP

fat_base_tab:
fb00 DW OFFSET fat_base_done
fb01 DW OFFSET fat_base_illegal
fb02 DW OFFSET fat_base_illegal
fb03 DW OFFSET fat_base_illegal
fb04 DW OFFSET fat_base_illegal
fb05 DW OFFSET fat_base_illegal
fb06 DW OFFSET fat_base_illegal
fb07 DW OFFSET fat_base_illegal
fb08 DW OFFSET fat_base_illegal
fb09 DW OFFSET fat_base_illegal
fb0A DW OFFSET fat_base_illegal
fb0B DW OFFSET fat_base_illegal
fb0C DW OFFSET fat_base_illegal
fb0D DW OFFSET fat_base_illegal
fb0E DW OFFSET fat_base_illegal
fb0F DW OFFSET fat_base_illegal
fb10 DW OFFSET fat_base_illegal
fb11 DW OFFSET fat_base_illegal
fb12 DW OFFSET fat_base_illegal
fb13 DW OFFSET fat_base_illegal
fb14 DW OFFSET fat_base_illegal
fb15 DW OFFSET fat_base_illegal
fb16 DW OFFSET fat_base_illegal
fb17 DW OFFSET fat_base_illegal
fb18 DW OFFSET fat_base_illegal
fb19 DW OFFSET fat_base_illegal
fb1A DW OFFSET fat_base_illegal
fb1B DW OFFSET fat_base_illegal
fb1C DW OFFSET fat_base_illegal
fb1D DW OFFSET fat_base_illegal
fb1E DW OFFSET fat_base_illegal
fb1F DW OFFSET fat_base_illegal
fb20 DW OFFSET fat_base_illegal
fb21 DW OFFSET fat_base_save
fb22 DW OFFSET fat_base_illegal
fb23 DW OFFSET fat_base_save
fb24 DW OFFSET fat_base_save
fb25 DW OFFSET fat_base_save
fb26 DW OFFSET fat_base_save
fb27 DW OFFSET fat_base_save
fb28 DW OFFSET fat_base_save
fb29 DW OFFSET fat_base_save
fb2A DW OFFSET fat_base_illegal
fb2B DW OFFSET fat_base_illegal
fb2C DW OFFSET fat_base_illegal
fb2D DW OFFSET fat_base_save
fb2E DW OFFSET fat_base_done
fb2F DW OFFSET fat_base_illegal
fb30 DW OFFSET fat_base_save
fb31 DW OFFSET fat_base_save
fb32 DW OFFSET fat_base_save
fb33 DW OFFSET fat_base_save
fb34 DW OFFSET fat_base_save
fb35 DW OFFSET fat_base_save
fb36 DW OFFSET fat_base_save
fb37 DW OFFSET fat_base_save
fb38 DW OFFSET fat_base_save
fb39 DW OFFSET fat_base_save
fb3A DW OFFSET fat_base_illegal
fb3B DW OFFSET fat_base_illegal
fb3C DW OFFSET fat_base_illegal
fb3D DW OFFSET fat_base_illegal
fb3E DW OFFSET fat_base_illegal
fb3F DW OFFSET fat_base_illegal
fb40 DW OFFSET fat_base_save
fb41 DW OFFSET fat_base_save
fb42 DW OFFSET fat_base_save
fb43 DW OFFSET fat_base_save
fb44 DW OFFSET fat_base_save
fb45 DW OFFSET fat_base_save
fb46 DW OFFSET fat_base_save
fb47 DW OFFSET fat_base_save
fb48 DW OFFSET fat_base_save
fb49 DW OFFSET fat_base_save
fb4A DW OFFSET fat_base_save
fb4B DW OFFSET fat_base_save
fb4C DW OFFSET fat_base_save
fb4D DW OFFSET fat_base_save
fb4E DW OFFSET fat_base_save
fb4F DW OFFSET fat_base_save
fb50 DW OFFSET fat_base_save
fb51 DW OFFSET fat_base_save
fb52 DW OFFSET fat_base_save
fb53 DW OFFSET fat_base_save
fb54 DW OFFSET fat_base_save
fb55 DW OFFSET fat_base_save
fb56 DW OFFSET fat_base_save
fb57 DW OFFSET fat_base_save
fb58 DW OFFSET fat_base_save
fb59 DW OFFSET fat_base_save
fb5A DW OFFSET fat_base_save
fb5B DW OFFSET fat_base_illegal
fb5C DW OFFSET fat_base_done
fb5D DW OFFSET fat_base_illegal
fb5E DW OFFSET fat_base_save
fb5F DW OFFSET fat_base_save
fb60 DW OFFSET fat_base_save
fb61 DW OFFSET fat_base_save_uppercase
fb62 DW OFFSET fat_base_save_uppercase
fb63 DW OFFSET fat_base_save_uppercase
fb64 DW OFFSET fat_base_save_uppercase
fb65 DW OFFSET fat_base_save_uppercase
fb66 DW OFFSET fat_base_save_uppercase
fb67 DW OFFSET fat_base_save_uppercase
fb68 DW OFFSET fat_base_save_uppercase
fb69 DW OFFSET fat_base_save_uppercase
fb6A DW OFFSET fat_base_save_uppercase
fb6B DW OFFSET fat_base_save_uppercase
fb6C DW OFFSET fat_base_save_uppercase
fb6D DW OFFSET fat_base_save_uppercase
fb6E DW OFFSET fat_base_save_uppercase
fb6F DW OFFSET fat_base_save_uppercase
fb70 DW OFFSET fat_base_save_uppercase
fb71 DW OFFSET fat_base_save_uppercase
fb72 DW OFFSET fat_base_save_uppercase
fb73 DW OFFSET fat_base_save_uppercase
fb74 DW OFFSET fat_base_save_uppercase
fb75 DW OFFSET fat_base_save_uppercase
fb76 DW OFFSET fat_base_save_uppercase
fb77 DW OFFSET fat_base_save_uppercase
fb78 DW OFFSET fat_base_save_uppercase
fb79 DW OFFSET fat_base_save_uppercase
fb7A DW OFFSET fat_base_save_uppercase
fb7B DW OFFSET fat_base_save
fb7C DW OFFSET fat_base_illegal
fb7E DW OFFSET fat_base_save
fb7F DW OFFSET fat_base_save
fb80 DW OFFSET fat_base_save
fb81 DW OFFSET fat_base_save
fb82 DW OFFSET fat_base_save
fb83 DW OFFSET fat_base_save
fb84 DW OFFSET fat_base_save
fb85 DW OFFSET fat_base_save
fb86 DW OFFSET fat_base_save
fb87 DW OFFSET fat_base_save
fb88 DW OFFSET fat_base_save
fb89 DW OFFSET fat_base_save
fb8A DW OFFSET fat_base_save
fb8B DW OFFSET fat_base_save
fb8C DW OFFSET fat_base_save
fb8D DW OFFSET fat_base_save
fb8E DW OFFSET fat_base_save
fb8F DW OFFSET fat_base_save
fb90 DW OFFSET fat_base_save
fb91 DW OFFSET fat_base_save
fb92 DW OFFSET fat_base_save
fb93 DW OFFSET fat_base_save
fb94 DW OFFSET fat_base_save
fb95 DW OFFSET fat_base_save
fb96 DW OFFSET fat_base_save
fb97 DW OFFSET fat_base_save
fb98 DW OFFSET fat_base_save
fb99 DW OFFSET fat_base_save
fb9A DW OFFSET fat_base_save
fb9B DW OFFSET fat_base_save
fb9C DW OFFSET fat_base_save
fb9D DW OFFSET fat_base_save
fb9E DW OFFSET fat_base_save
fb9F DW OFFSET fat_base_save
fbA0 DW OFFSET fat_base_save
fbA1 DW OFFSET fat_base_save
fbA2 DW OFFSET fat_base_save
fbA3 DW OFFSET fat_base_save
fbA4 DW OFFSET fat_base_save
fbA5 DW OFFSET fat_base_save
fbA6 DW OFFSET fat_base_save
fbA7 DW OFFSET fat_base_save
fbA8 DW OFFSET fat_base_save
fbA9 DW OFFSET fat_base_save
fbAA DW OFFSET fat_base_save
fbAB DW OFFSET fat_base_save
fbAC DW OFFSET fat_base_save
fbAD DW OFFSET fat_base_save
fbAE DW OFFSET fat_base_save
fbAF DW OFFSET fat_base_save
fbB0 DW OFFSET fat_base_save
fbB1 DW OFFSET fat_base_save
fbB2 DW OFFSET fat_base_save
fbB3 DW OFFSET fat_base_save
fbB4 DW OFFSET fat_base_save
fbB5 DW OFFSET fat_base_save
fbB6 DW OFFSET fat_base_save
fbB7 DW OFFSET fat_base_save
fbB8 DW OFFSET fat_base_save
fbB9 DW OFFSET fat_base_save
fbBA DW OFFSET fat_base_save
fbBB DW OFFSET fat_base_save
fbBC DW OFFSET fat_base_save
fbBD DW OFFSET fat_base_save
fbBE DW OFFSET fat_base_save
fbBF DW OFFSET fat_base_save
fbC0 DW OFFSET fat_base_save
fbC1 DW OFFSET fat_base_save
fbC2 DW OFFSET fat_base_save
fbC3 DW OFFSET fat_base_save
fbC4 DW OFFSET fat_base_save
fbC5 DW OFFSET fat_base_save
fbC6 DW OFFSET fat_base_save
fbC7 DW OFFSET fat_base_save
fbC8 DW OFFSET fat_base_save
fbC9 DW OFFSET fat_base_save
fbCA DW OFFSET fat_base_save
fbCB DW OFFSET fat_base_save
fbCC DW OFFSET fat_base_save
fbCD DW OFFSET fat_base_save
fbCE DW OFFSET fat_base_save
fbCF DW OFFSET fat_base_save
fbD0 DW OFFSET fat_base_save
fbD1 DW OFFSET fat_base_save
fbD2 DW OFFSET fat_base_save
fbD3 DW OFFSET fat_base_save
fbD4 DW OFFSET fat_base_save
fbD5 DW OFFSET fat_base_save
fbD6 DW OFFSET fat_base_save
fbD7 DW OFFSET fat_base_save
fbD8 DW OFFSET fat_base_save
fbD9 DW OFFSET fat_base_save
fbDA DW OFFSET fat_base_save
fbDB DW OFFSET fat_base_save
fbDC DW OFFSET fat_base_save
fbDD DW OFFSET fat_base_save
fbDE DW OFFSET fat_base_save
fbDF DW OFFSET fat_base_save
fbE0 DW OFFSET fat_base_save
fbE1 DW OFFSET fat_base_save
fbE2 DW OFFSET fat_base_save
fbE3 DW OFFSET fat_base_save
fbE4 DW OFFSET fat_base_save
fbE5 DW OFFSET fat_base_save
fbE6 DW OFFSET fat_base_save
fbE7 DW OFFSET fat_base_save
fbE8 DW OFFSET fat_base_save
fbE9 DW OFFSET fat_base_save
fbEA DW OFFSET fat_base_save
fbEB DW OFFSET fat_base_save
fbEC DW OFFSET fat_base_save
fbED DW OFFSET fat_base_save
fbEE DW OFFSET fat_base_save
fbEF DW OFFSET fat_base_save
fbF0 DW OFFSET fat_base_save
fbF1 DW OFFSET fat_base_save
fbF2 DW OFFSET fat_base_save
fbF3 DW OFFSET fat_base_save
fbF4 DW OFFSET fat_base_save
fbF5 DW OFFSET fat_base_save
fbF6 DW OFFSET fat_base_save
fbF7 DW OFFSET fat_base_save
fbF8 DW OFFSET fat_base_save
fbF9 DW OFFSET fat_base_save
fbFA DW OFFSET fat_base_save
fbFB DW OFFSET fat_base_save
fbFC DW OFFSET fat_base_save
fbFD DW OFFSET fat_base_save
fbFE DW OFFSET fat_base_save
fbFF DW OFFSET fat_base_save

fat_ext_done	PROC near
	mov ah,' '
fat_ext_pad:
	mov ss:[bp],ah
	inc bp
	loop fat_ext_pad
	dec edi
	clc
	ret
fat_ext_done	ENDP

fat_ext_illegal	PROC near
	stc
	ret
fat_ext_illegal	ENDP

fat_ext_save	PROC near
	mov ss:[bp],al
	inc bp
	dec cx
	clc
	ret
fat_ext_save	ENDP

fat_ext_save_uppercase	PROC near
	sub al,20h
	mov ss:[bp],al
	inc bp
	dec cx
	clc
	ret
fat_ext_save_uppercase	ENDP

fat_ext_tab:
fe00 DW OFFSET fat_ext_done
fe01 DW OFFSET fat_ext_illegal
fe02 DW OFFSET fat_ext_illegal
fe03 DW OFFSET fat_ext_illegal
fe04 DW OFFSET fat_ext_illegal
fe05 DW OFFSET fat_ext_illegal
fe06 DW OFFSET fat_ext_illegal
fe07 DW OFFSET fat_ext_illegal
fe08 DW OFFSET fat_ext_illegal
fe09 DW OFFSET fat_ext_illegal
fe0A DW OFFSET fat_ext_illegal
fe0B DW OFFSET fat_ext_illegal
fe0C DW OFFSET fat_ext_illegal
fe0D DW OFFSET fat_ext_illegal
fe0E DW OFFSET fat_ext_illegal
fe0F DW OFFSET fat_ext_illegal
fe10 DW OFFSET fat_ext_illegal
fe11 DW OFFSET fat_ext_illegal
fe12 DW OFFSET fat_ext_illegal
fe13 DW OFFSET fat_ext_illegal
fe14 DW OFFSET fat_ext_illegal
fe15 DW OFFSET fat_ext_illegal
fe16 DW OFFSET fat_ext_illegal
fe17 DW OFFSET fat_ext_illegal
fe18 DW OFFSET fat_ext_illegal
fe19 DW OFFSET fat_ext_illegal
fe1A DW OFFSET fat_ext_illegal
fe1B DW OFFSET fat_ext_illegal
fe1C DW OFFSET fat_ext_illegal
fe1D DW OFFSET fat_ext_illegal
fe1E DW OFFSET fat_ext_illegal
fe1F DW OFFSET fat_ext_illegal
fe20 DW OFFSET fat_ext_illegal
fe21 DW OFFSET fat_ext_save
fe22 DW OFFSET fat_ext_illegal
fe23 DW OFFSET fat_ext_save
fe24 DW OFFSET fat_ext_save
fe25 DW OFFSET fat_ext_save
fe26 DW OFFSET fat_ext_save
fe27 DW OFFSET fat_ext_save
fe28 DW OFFSET fat_ext_save
fe29 DW OFFSET fat_ext_save
fe2A DW OFFSET fat_ext_illegal
fe2B DW OFFSET fat_ext_illegal
fe2C DW OFFSET fat_ext_illegal
fe2D DW OFFSET fat_ext_save
fe2E DW OFFSET fat_ext_illegal
fe2F DW OFFSET fat_ext_illegal
fe30 DW OFFSET fat_ext_save
fe31 DW OFFSET fat_ext_save
fe32 DW OFFSET fat_ext_save
fe33 DW OFFSET fat_ext_save
fe34 DW OFFSET fat_ext_save
fe35 DW OFFSET fat_ext_save
fe36 DW OFFSET fat_ext_save
fe37 DW OFFSET fat_ext_save
fe38 DW OFFSET fat_ext_save
fe39 DW OFFSET fat_ext_save
fe3A DW OFFSET fat_ext_illegal
fe3B DW OFFSET fat_ext_illegal
fe3C DW OFFSET fat_ext_illegal
fe3D DW OFFSET fat_ext_illegal
fe3E DW OFFSET fat_ext_illegal
fe3F DW OFFSET fat_ext_illegal
fe40 DW OFFSET fat_ext_save
fe41 DW OFFSET fat_ext_save
fe42 DW OFFSET fat_ext_save
fe43 DW OFFSET fat_ext_save
fe44 DW OFFSET fat_ext_save
fe45 DW OFFSET fat_ext_save
fe46 DW OFFSET fat_ext_save
fe47 DW OFFSET fat_ext_save
fe48 DW OFFSET fat_ext_save
fe49 DW OFFSET fat_ext_save
fe4A DW OFFSET fat_ext_save
fe4B DW OFFSET fat_ext_save
fe4C DW OFFSET fat_ext_save
fe4D DW OFFSET fat_ext_save
fe4E DW OFFSET fat_ext_save
fe4F DW OFFSET fat_ext_save
fe50 DW OFFSET fat_ext_save
fe51 DW OFFSET fat_ext_save
fe52 DW OFFSET fat_ext_save
fe53 DW OFFSET fat_ext_save
fe54 DW OFFSET fat_ext_save
fe55 DW OFFSET fat_ext_save
fe56 DW OFFSET fat_ext_save
fe57 DW OFFSET fat_ext_save
fe58 DW OFFSET fat_ext_save
fe59 DW OFFSET fat_ext_save
fe5A DW OFFSET fat_ext_save
fe5B DW OFFSET fat_ext_illegal
fe5C DW OFFSET fat_ext_done
fe5D DW OFFSET fat_ext_illegal
fe5E DW OFFSET fat_ext_save
fe5F DW OFFSET fat_ext_save
fe60 DW OFFSET fat_ext_save
fe61 DW OFFSET fat_ext_save_uppercase
fe62 DW OFFSET fat_ext_save_uppercase
fe63 DW OFFSET fat_ext_save_uppercase
fe64 DW OFFSET fat_ext_save_uppercase
fe65 DW OFFSET fat_ext_save_uppercase
fe66 DW OFFSET fat_ext_save_uppercase
fe67 DW OFFSET fat_ext_save_uppercase
fe68 DW OFFSET fat_ext_save_uppercase
fe69 DW OFFSET fat_ext_save_uppercase
fe6A DW OFFSET fat_ext_save_uppercase
fe6B DW OFFSET fat_ext_save_uppercase
fe6C DW OFFSET fat_ext_save_uppercase
fe6D DW OFFSET fat_ext_save_uppercase
fe6E DW OFFSET fat_ext_save_uppercase
fe6F DW OFFSET fat_ext_save_uppercase
fe70 DW OFFSET fat_ext_save_uppercase
fe71 DW OFFSET fat_ext_save_uppercase
fe72 DW OFFSET fat_ext_save_uppercase
fe73 DW OFFSET fat_ext_save_uppercase
fe74 DW OFFSET fat_ext_save_uppercase
fe75 DW OFFSET fat_ext_save_uppercase
fe76 DW OFFSET fat_ext_save_uppercase
fe77 DW OFFSET fat_ext_save_uppercase
fe78 DW OFFSET fat_ext_save_uppercase
fe79 DW OFFSET fat_ext_save_uppercase
fe7A DW OFFSET fat_ext_save_uppercase
fe7B DW OFFSET fat_ext_save
fe7C DW OFFSET fat_ext_illegal
fe7E DW OFFSET fat_ext_save
fe7F DW OFFSET fat_ext_save
fe80 DW OFFSET fat_ext_save
fe81 DW OFFSET fat_ext_save
fe82 DW OFFSET fat_ext_save
fe83 DW OFFSET fat_ext_save
fe84 DW OFFSET fat_ext_save
fe85 DW OFFSET fat_ext_save
fe86 DW OFFSET fat_ext_save
fe87 DW OFFSET fat_ext_save
fe88 DW OFFSET fat_ext_save
fe89 DW OFFSET fat_ext_save
fe8A DW OFFSET fat_ext_save
fe8B DW OFFSET fat_ext_save
fe8C DW OFFSET fat_ext_save
fe8D DW OFFSET fat_ext_save
fe8E DW OFFSET fat_ext_save
fe8F DW OFFSET fat_ext_save
fe90 DW OFFSET fat_ext_save
fe91 DW OFFSET fat_ext_save
fe92 DW OFFSET fat_ext_save
fe93 DW OFFSET fat_ext_save
fe94 DW OFFSET fat_ext_save
fe95 DW OFFSET fat_ext_save
fe96 DW OFFSET fat_ext_save
fe97 DW OFFSET fat_ext_save
fe98 DW OFFSET fat_ext_save
fe99 DW OFFSET fat_ext_save
fe9A DW OFFSET fat_ext_save
fe9B DW OFFSET fat_ext_save
fe9C DW OFFSET fat_ext_save
fe9D DW OFFSET fat_ext_save
fe9E DW OFFSET fat_ext_save
fe9F DW OFFSET fat_ext_save
feA0 DW OFFSET fat_ext_save
feA1 DW OFFSET fat_ext_save
feA2 DW OFFSET fat_ext_save
feA3 DW OFFSET fat_ext_save
feA4 DW OFFSET fat_ext_save
feA5 DW OFFSET fat_ext_save
feA6 DW OFFSET fat_ext_save
feA7 DW OFFSET fat_ext_save
feA8 DW OFFSET fat_ext_save
feA9 DW OFFSET fat_ext_save
feAA DW OFFSET fat_ext_save
feAB DW OFFSET fat_ext_save
feAC DW OFFSET fat_ext_save
feAD DW OFFSET fat_ext_save
feAE DW OFFSET fat_ext_save
feAF DW OFFSET fat_ext_save
feB0 DW OFFSET fat_ext_save
feB1 DW OFFSET fat_ext_save
feB2 DW OFFSET fat_ext_save
feB3 DW OFFSET fat_ext_save
feB4 DW OFFSET fat_ext_save
feB5 DW OFFSET fat_ext_save
feB6 DW OFFSET fat_ext_save
feB7 DW OFFSET fat_ext_save
feB8 DW OFFSET fat_ext_save
feB9 DW OFFSET fat_ext_save
feBA DW OFFSET fat_ext_save
feBB DW OFFSET fat_ext_save
feBC DW OFFSET fat_ext_save
feBD DW OFFSET fat_ext_save
feBE DW OFFSET fat_ext_save
feBF DW OFFSET fat_ext_save
feC0 DW OFFSET fat_ext_save
feC1 DW OFFSET fat_ext_save
feC2 DW OFFSET fat_ext_save
feC3 DW OFFSET fat_ext_save
feC4 DW OFFSET fat_ext_save
feC5 DW OFFSET fat_ext_save
feC6 DW OFFSET fat_ext_save
feC7 DW OFFSET fat_ext_save
feC8 DW OFFSET fat_ext_save
feC9 DW OFFSET fat_ext_save
feCA DW OFFSET fat_ext_save
feCB DW OFFSET fat_ext_save
feCC DW OFFSET fat_ext_save
feCD DW OFFSET fat_ext_save
feCE DW OFFSET fat_ext_save
feCF DW OFFSET fat_ext_save
feD0 DW OFFSET fat_ext_save
feD1 DW OFFSET fat_ext_save
feD2 DW OFFSET fat_ext_save
feD3 DW OFFSET fat_ext_save
feD4 DW OFFSET fat_ext_save
feD5 DW OFFSET fat_ext_save
feD6 DW OFFSET fat_ext_save
feD7 DW OFFSET fat_ext_save
feD8 DW OFFSET fat_ext_save
feD9 DW OFFSET fat_ext_save
feDA DW OFFSET fat_ext_save
feDB DW OFFSET fat_ext_save
feDC DW OFFSET fat_ext_save
feDD DW OFFSET fat_ext_save
feDE DW OFFSET fat_ext_save
feDF DW OFFSET fat_ext_save
feE0 DW OFFSET fat_ext_save
feE1 DW OFFSET fat_ext_save
feE2 DW OFFSET fat_ext_save
feE3 DW OFFSET fat_ext_save
feE4 DW OFFSET fat_ext_save
feE5 DW OFFSET fat_ext_save
feE6 DW OFFSET fat_ext_save
feE7 DW OFFSET fat_ext_save
feE8 DW OFFSET fat_ext_save
feE9 DW OFFSET fat_ext_save
feEA DW OFFSET fat_ext_save
feEB DW OFFSET fat_ext_save
feEC DW OFFSET fat_ext_save
feED DW OFFSET fat_ext_save
feEE DW OFFSET fat_ext_save
feEF DW OFFSET fat_ext_save
feF0 DW OFFSET fat_ext_save
feF1 DW OFFSET fat_ext_save
feF2 DW OFFSET fat_ext_save
feF3 DW OFFSET fat_ext_save
feF4 DW OFFSET fat_ext_save
feF5 DW OFFSET fat_ext_save
feF6 DW OFFSET fat_ext_save
feF7 DW OFFSET fat_ext_save
feF8 DW OFFSET fat_ext_save
feF9 DW OFFSET fat_ext_save
feFA DW OFFSET fat_ext_save
feFB DW OFFSET fat_ext_save
feFC DW OFFSET fat_ext_save
feFD DW OFFSET fat_ext_save
feFE DW OFFSET fat_ext_save
feFF DW OFFSET fat_ext_save

	public setup_dir_entry

setup_dir_entry	PROC near
	push ax
	push bx
	push cx
	push bp
	mov cx,8
	mov al,es:[edi]
	cmp al,'.'
	jne setup_dir_base_loop
	mov ss:[bp],al
	inc edi
	inc bp
	dec cx
	mov al,es:[edi]
	cmp al,'.'
	jne setup_dir_base_loop
	mov ss:[bp],al
	inc edi
	inc bp
	dec cx
setup_dir_base_loop:
	mov al,es:[edi]
	inc edi
	movzx bx,al
	add bx,bx
	call word ptr cs:[bx].fat_base_tab
	jc setup_dir_done
	or cx,cx
	jnz setup_dir_base_loop
	mov al,es:[edi]
	inc edi
	cmp al,'.'
	je setup_dir_ext
	dec edi
	or al,al
	je setup_dir_ext
	cmp al,'\'
	je setup_dir_ext
	stc
	jmp setup_dir_done
setup_dir_ext:
	mov cx,3
setup_dir_ext_loop:
	mov al,es:[edi]
	inc edi
	movzx bx,al
	add bx,bx
	call word ptr cs:[bx].fat_ext_tab
	jc setup_dir_done
	or cx,cx
	jnz setup_dir_ext_loop
	mov al,es:[edi]
	or al,al
	je setup_dir_ok
	cmp al,'\'
	je setup_dir_ok
	stc
	jmp setup_dir_ok
setup_dir_ok:
	clc
setup_dir_done:
	pop bp
	pop cx
	pop bx
	pop ax
	ret
setup_dir_entry	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SETUP_START_SECTOR
;
;		DESCRIPTION:	Setup start sector for path
;
;		PARAMETERS:		FS			FAT_DATA_SEL
;						ES:EDI		Pathname
;
;		RETURNS:		ES:EDI		Rest of pathname
;						AL			Drive
;						EDX			Start sector
;						NC			OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public setup_start_sector

setup_start_sector	PROC near
	push bx
	GetCurDirPtr
	mov bl,es:[edi]
	cmp bl,'\'
	jne setup_start_not_root
	inc edi
	movzx bx,al
	shl bx,6
	mov edx,fs:start_sector
setup_start_not_root:
	pop bx
	clc
	ret
setup_start_sector	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADVANCE_DIR
;
;		DESCRIPTION:	Advance to next sub-directory
;
;		PARAMETERS:		DS			FAT_DATA_SEL
;						ES:ESI		Directory to go to
;						AL			Drive
;
;		RETRUNS:		EDX			Sector
;						NC			OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public advance_dir

advance_dir	PROC near	
	push ecx
	mov cl,es:[esi].fat_attrib
	test cl,10h
	stc
	jz advance_dir_done
;
	cmp ds:fat_type,fat32
	je advance_cluster32
;
	movzx ecx,es:[esi].fat_cluster
	or ecx,ecx
	jnz advance_dir_not_sector0
;
	movzx bx,al
	shl bx,6
	mov edx,ds:root_sector
	clc
	jmp advance_dir_done

advance_cluster32:
	mov cx,es:[esi].fat_cluster_hi
	shl ecx,16
	mov cx,es:[esi].fat_cluster

advance_dir_not_sector0:
	mov edx,ecx
	sub edx,2
	mov cl,ds:fat_cluster_shift
	shl edx,cl
	add edx,ds:start_sector
	clc
advance_dir_done:
	pop ecx
	ret
advance_dir	ENDP

code	ENDS

	END

