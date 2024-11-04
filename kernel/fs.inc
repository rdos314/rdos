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

FILE_ATTRIB_NOBUFFER = 80h

FILE_LIST_STATE_EMPTY = 0ACh
FILE_LIST_STATE_USED = 04Ah

FILE_LIST_FLAG_READAHEAD = 1

fs_drive_seg	STRUC

fs_table            DD ?,?
fs_drive_param      DD ?,?
fs_root_dir_sel		DW ?
fs_mount_id			DD ?
fs_access_spinlock	spinlock_typ <>
fs_list_section		section_typ <>
fs_access_section	read_write_section_typ <>
fs_access_parse		DB ?

fs_drive_seg	ENDS

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

file_base               handle_sys_interface <>

file_prev		DW ?
file_next		DW ?
file_size_section	read_write_section_typ <>
file_list_section	section_typ <>
file_dir_entry		DD ?
file_dir_sel            DW ?
file_usage		DW ?
file_kernel_sel         DW ?
file_user_count         DW ?
file_drive	        DB ?
file_attrib	        DB ?
file_c_handle           DW ?
file_read_handle        DW ?
file_read_pos           DD ?
file_cache_entry	DD ?
file_cache_ads		DD ?
file_size		DD ?
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

max_dir_entry_data_struc	STRUC

mde_base			dir_entry_data_struc <>
mde_space           DW ?,?,?

max_dir_entry_data_struc	ENDS

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

;	IN	ES:EDI		FS name
;	IN	ECX			Number of sectors
;	IN	FS:EDX		DRIVE DATA
fs_format_proc				DD ?,?

;	IN	FS:EDX		DRIVE DATA
;	OUT	DS:ESI		Fs data
fs_mount_proc				DD ?,?

;	IN	DS:ESI		Fs data
fs_flush_proc				DD ?,?

;	IN	DS:ESI		Fs data
fs_dismount_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	OUT	EAX			FREE UNITS
;	OUT	CX			NUMBER OF BYTES/UNIT
;	OUT	EDX			TOTAL NUMBER OF UNITS
fs_info_proc				DD ?,?

;	IN	DS:ESI		Fs data
;	IN  AL			Drive
;	IN  BX			Parent dir selector
;	IN  EDX			Parent dir entry
;	OUT BX			DIR SELECTOR
fs_allocate_dir_sel_proc		DD ?,?

;	IN	DS:ESI		Fs data
;	IN  BX			DIR SELECTOR
fs_free_dir_sel_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	IN  BX			DIR SELECTOR
;	IN	EDX			DIR ENTRY OR 0
fs_cache_dir_proc				DD ?,?

;	IN	DS:ESI		Fs data
;	IN	EDX			DIR DIR ENTRY
fs_update_dir_proc		DD ?,?

;	IN	DS:ESI		Fs data
;	IN	EDX			DIR FILE ENTRY
fs_update_file_proc		DD ?,?

;	IN	DS:ESI		Fs data
;	IN	ES:EDI		PATH NAME
;	IN  BX			DIR SELECTOR
;	OUT	EDX			DIR ENTRY
fs_create_dir_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	IN  BX			DIR SELECTOR
;	IN	EDX			DIR ENTRY TO DELETE
fs_delete_dir_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	IN  BX			DIR SELECTOR
;	IN	EDX			FILE ENTRY TO DELETE
fs_delete_file_proc		DD ?,?

;	IN	FS:ESI		CURRENT NAME
;	IN	ES:EDI		NEW NAME
fs_rename_file_proc		DD ?,?

;	IN	DS:ESI		Fs data
;	IN	ES:EDI		PATH NAME
;	IN  BX			DIR SELECTOR
;	IN	CX			FILE ATTRIBUTE
;	OUT	EDX			DIR ENTRY
fs_create_file_proc		DD ?,?

;	IN	DS:ESI		Fs data
;	IN	BX			File sel
;	OUT	DX			IOCTL DATA
fs_get_ioctl_data_proc		DD ?,?

;	IN	DS:ESI		Fs data
;	IN	BX			File sel
;	IN	EDX			FILE SIZE
fs_set_file_size_proc		DD ?,?

;	IN	DS:ESI		Fs data
;	IN	BX			File sel
;	IN	ECX			NUMBER OF BYTES
;	IN	EDX			POSITION
;	IN	ES:EDI		DATA BUFFER
;	OUT	EAX			NUMBER OF BYTES READ
fs_read_file_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	IN	BX			File sel
;	IN	ECX			NUMBER OF BYTES
;	IN	EDX			POSITION
;	IN	ES:EDI		DATA BUFFER
;	OUT	EAX			NUMBER OF BYTES WRITTEN
fs_write_file_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	IN	BX			File sel
;	OUT	EDI			FILE LIST ENTRY
fs_allocate_file_list_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	IN	EDI			FILE LIST ENTRY
fs_free_file_list_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	IN	BX			File sel
;	IN	ECX			BYTES TO READ
;	IN	EDX			POSITION
;	IN	EDI			FILE LIST ENTRY
fs_read_file_block_proc			DD ?,?

;	IN	DS:ESI		Fs data
;	IN	BX			File sel
;	IN	ECX			BYTES TO WRITE
;	IN	EDX			POSITION
;	IN	EDI			FILE LIST ENTRY
fs_write_file_block_proc			DD ?,?

file_system_struc	ENDS

proc_cur_dir_struc   STRUC

pc_dir_sel_arr        DW 256 DUP(?)
pc_vfs_sel_arr        DW 32 DUP(?)
pc_vfs_handle_arr     DW 32 DUP(?)
pc_drive              DB ?

proc_cur_dir_struc   ENDS
