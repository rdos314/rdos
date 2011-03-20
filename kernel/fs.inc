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
; FS.INC
; File system interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_DRIVES	EQU 'Z' - 'A' + 1

FILE_ATTRIB_NOBUFFER = 80h

FILE_LIST_STATE_EMPTY = 0ACh
FILE_LIST_STATE_USED = 04Ah

FILE_LIST_FLAG_READAHEAD = 1

fs_drive_seg	STRUC

fs_sys_arr			DD 2*256 DUP(?)
fs_root_dir_sel		DW ?
fs_mount_id			DD ?
fs_list_section		section_typ <>
fs_access_section	read_write_section_typ <>
fs_access_parse		DB ?

fs_drive_seg	ENDS

fs_data_seg		STRUC

fs_init_section		section_typ <>
fs_init_done		DB ?

file_defs			DB ?
fs_init_hooks		DB ?
file_def_arr		DD 2*32 DUP(?)
fs_init_hook_arr	DD 32 DUP(?)
media_check_proc	DD 256 DUP(?)
media_check_handle	DW 256 DUP(?)
fs_sel				DW 256 DUP(?)

fs_data_seg		ENDS

fs_process_seg	STRUC

cur_dir_sel			DW 256 DUP(?)
curr_drive			DB ?
memmap_list			DD ?

fs_process_seg	ENDS

file_list_struc	STRUC

fl_usage			DW ?
fl_ref_count		DW ?
fl_base				DD ?
fl_size				DD ?
fl_pos				DD ?
fl_sel				DW ?
fl_state			DB ?
fl_flags			DB ?
fl_prev_small		DD ?
fl_next_small		DD ?

file_list_struc	ENDS

file_data_struc	STRUC

file_prev		    DW ?
file_next			DW ?
file_size_section	read_write_section_typ <>
file_list_section	section_typ <>
file_dir_entry		DD ?
file_usage			DW ?
file_drive			DB ?
file_attrib			DB ?
file_cache_entry	DD ?
file_cache_ads		DD ?
file_size			DD ?
file_dir_shift		DB ?
file_entry_shift	DB ?
file_block_size		DD ?
file_dir_entries	DW ?
file_entries		DD ?

file_data_struc	ENDS

dir_entry_data_struc	STRUC

de_prev				DD ?
de_next				DD ?
de_usage			DW ?
de_size				DW ?
de_sel				DW ?
de_time				DD ?,?
de_attrib			DB ?
de_drive			DB ?
de_name_size		DW ?
de_name				DD ?

dir_entry_data_struc	ENDS

dir_dir_entry_data_struc	STRUC

dde_base			dir_entry_data_struc <>

dir_dir_entry_data_struc	ENDS

dir_file_entry_data_struc	STRUC

dfe_base			dir_entry_data_struc <>
dfe_data_size		DD ?
dfe_file_sel		DW ?

dir_file_entry_data_struc	ENDS

dir_sel_data_struc	STRUC

ds_access_section	read_write_section_typ <>
ds_list_section		section_typ <>
ds_dir_ptr			DD ?
ds_file_ptr			DD ?
ds_usage			DW ?
ds_parent			DW ?
ds_handle			DD ?
ds_mount_id			DD ?
ds_drive			DB ?

dir_sel_data_struc	ENDS

dir_handle_struc	STRUC

dhs_count			DW ?
dhs_drive			DB ?
dhs_pad				DB ?
dhs_mount_id		DD ?
dhs_data			DB ?

dir_handle_struc	ENDS

file_system_struc 	STRUC

;	IN	ES:DI		FS name
;	IN	ECX			Number of sectors
;	IN	FS:EDX		DRIVE DATA
format_proc				DD ?

;	IN	FS:EDX		DRIVE DATA
mount_proc				DD ?

flush_proc				DD ?

dismount_proc			DD ?

;	OUT	EAX			FREE UNITS
;	OUT	CX			NUMBER OF BYTES/UNIT
;	OUT	EDX			TOTAL NUMBER OF UNITS
info_proc				DD ?

;	IN  AL			Drive
;	IN  BX			Parent dir selector
;	IN  EDX			Parent dir entry
;	OUT BX			DIR SELECTOR
allocate_dir_sel_proc		DD ?

;	IN  BX			DIR SELECTOR
free_dir_sel_proc			DD ?

;	IN  BX			DIR SELECTOR
;	IN	EDX			DIR ENTRY OR 0
cache_dir_proc				DD ?

;	IN	EDX			DIR DIR ENTRY
update_dir_proc		DD ?

;	IN	EDX			DIR FILE ENTRY
update_file_proc		DD ?

;	IN	ES:EDI		PATH NAME
;	IN  BX			DIR SELECTOR
;	OUT	EDX			DIR ENTRY
create_dir_proc			DD ?

;	IN  BX			DIR SELECTOR
;	IN	EDX			DIR ENTRY TO DELETE
delete_dir_proc			DD ?

;	IN  BX			DIR SELECTOR
;	IN	EDX			FILE ENTRY TO DELETE
delete_file_proc		DD ?

;	IN	FS:ESI		CURRENT NAME
;	IN	ES:EDI		NEW NAME
rename_file_proc		DD ?

;	IN	ES:EDI		PATH NAME
;	IN  BX			DIR SELECTOR
;	IN	CX			FILE ATTRIBUTE
;	OUT	EDX			DIR ENTRY
create_file_proc		DD ?

;	IN	BX			FILE HANDLE
;	OUT	DX			IOCTL DATA
get_ioctl_data_proc		DD ?

;	IN	BX			FILE HANDLE
;	IN	EDX			FILE SIZE
set_file_size_proc		DD ?

;	IN	BX			FILE HANDLE
;	IN	ECX			NUMBER OF BYTES
;	IN	EDX			POSITION
;	IN	ES:EDI		DATA BUFFER
;	OUT	EAX			NUMBER OF BYTES READ
read_file_proc			DD ?

;	IN	BX			FILE HANDLE
;	IN	ECX			NUMBER OF BYTES
;	IN	EDX			POSITION
;	IN	ES:EDI		DATA BUFFER
;	OUT	EAX			NUMBER OF BYTES WRITTEN
write_file_proc			DD ?

;	IN	BX			FILE HANDLE
;	OUT	EDI			FILE LIST ENTRY
allocate_file_list_proc			DD ?

;	IN	EDI			FILE LIST ENTRY
free_file_list_proc			DD ?

;	IN	BX			FILE HANDLE
;	IN	ECX			BYTES TO READ
;	IN	EDX			POSITION
;	IN	EDI			FILE LIST ENTRY
read_file_block_proc			DD ?

;	IN	BX			FILE HANDLE
;	IN	ECX			BYTES TO WRITE
;	IN	EDX			POSITION
;	IN	EDI			FILE LIST ENTRY
write_file_block_proc			DD ?

file_system_struc	ENDS

