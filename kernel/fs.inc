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

dir_num		EQU 8
MAX_DRIVES	EQU 'Z' - 'A' + 1
file_num = 80h
map_num = 40h

FILE_ATTRIB_NOBUFFER = 80h

FILE_LIST_STATE_EMPTY = 0ACh
FILE_LIST_STATE_USED = 04Ah

FILE_LIST_FLAG_READAHEAD = 1

fs_data_seg		STRUC

map_list			DW ?
map_named_list		DW ?
sys_section			section_typ <>

file_defs			DB ?
file_def_arr		DD 2*32 DUP(?)
file_sys_arr		DD 2*256 DUP(?)

fs_data_seg		ENDS

fs_process_seg	STRUC

cur_dir_ptr			DD MAX_DRIVES DUP(?)
curr_drive			DB ?
resv1				DB ?
dir_free_list		DW ?
file_free_list		DW ?
handle_free_list	DW ?
dir_list			DB 4*dir_num DUP(?)
file_list			DB 8 * file_num DUP(?)
handle_list			DB 16 * map_num DUP(?)
file_handle_section	section_typ <>

fs_process_seg	ENDS

file_list_struc	STRUC

fl_prev				DD ?
fl_next				DD ?
fl_usage			DW ?
fl_ref_count		DW ?
fl_base				DD ?
fl_size				DD ?
fl_sel				DW ?
fl_state			DB ?
fl_flags			DB ?
fl_prev_small		DD ?
fl_next_small		DD ?

file_list_struc	ENDS

file_data_struc	STRUC

file_size_section	read_write_section_typ <>
file_list_section	section_typ <>
file_ptr			DD ?
file_dir_entry		DD ?
file_usage			DW ?
file_drive			DB ?
file_attrib			DB ?
file_parent			DW ?
file_cache_entry	DD ?
file_cache_ads		DD ?
file_size			DD ?
file_dir_shift		DB ?
file_entry_shift	DB ?
file_block_size		DD ?
file_dir_entries	DW ?
file_entries		DD ?

file_data_struc	ENDS

file_system_struc 	STRUC

;	IN	DX			DRIVE DATA
mount_proc				DD ?

dismount_proc			DD ?

;	OUT	EAX			FREE UNITS
;	OUT	CX			NUMBER OF BYTES/UNIT
;	OUT	EDX			TOTAL NUMBER OF UNITS
info_proc				DD ?

;	IN	ES:EDI		PATH NAME
set_cur_dir_proc		DD ?

;	IN	ES:EDI		PATH NAME
get_cur_dir_proc		DD ?

;	IN	ES:EDI		PATH NAME
make_dir_proc			DD ?

;	IN	ES:EDI		PATH NAME
remove_dir_proc			DD ?

;	IN	ES:EDI		PATH NAME
delete_file_proc		DD ?

;	IN	FS:ESI		CURRENT NAME
;	IN	ES:EDI		NEW NAME
rename_file_proc		DD ?

;	IN	ES:EDI		PATH NAME
;	OUT	CX			FILE ATTRIBUTE
get_file_attrib_proc	DD ?

;	IN	ES:EDI		PATH NAME
;	IN	CX			FILE ATTRIBUTE
set_file_attrib_proc	DD ?

;	IN	ES:EDI		PATH NAME
;	OUT	BX			DIR HANDLE
open_dir_proc			DD ?

;	IN	BX			DIR HANDLE
close_dir_proc			DD ?

;	IN	BX			DIR HANDLE
;	IN	DX			ENTRY #
;	IN	CX			MAX SIZE OF FILENAME
;	IN	ES:EDI		FILENAME BUFFER
;	OUT	ECX			FILE SIZE
;	OUT	BX			FILE ATTRIBUTE
;	OUT	EDX:EAX		FILE TIME/DATE
read_dir_proc			DD ?

;	IN	ES:EDI		PATH NAME
;	IN	CL			ACCESS MODE
;	OUT	BX			FILE HANDLE
open_file_proc			DD ?

;	IN	ES:EDI		PATH NAME
;	IN	CX			FILE ATTRIBUTE
;	OUT	BX			FILE HANDLE
create_file_proc		DD ?

;	IN	BX			FILE HANDLE
close_file_proc			DD ?

;	IN	BX			FILE HANDLE
;	OUT	DX			IOCTL DATA
get_ioctl_data_proc		DD ?

;	IN	BX			FILE HANDLE
;	OUT	EDX			FILE SIZE
get_file_size_proc		DD ?

;	IN	BX			FILE HANDLE
;	IN	EDX			FILE SIZE
set_file_size_proc		DD ?

;	IN	BX			FILE HANDLE
;	OUT	EDX:ECX		FILE TIME
get_file_time_proc		DD ?

;	IN	BX			FILE HANDLE
;	IN	EDX:ECX		FILE TIME
set_file_time_proc		DD ?

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

