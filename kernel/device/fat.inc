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
; FAT.INC
; FAT common types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat12				EQU 12
fat16				EQU 16
fat32				EQU 32

dir_data_struc	STRUC

dir_section			read_write_section_typ <>
dir_dir_ptr			DD ?
dir_file_ptr		DD ?
dir_deleted_ptr		DD ?
dir_free_ptr		DD ?
dir_parent_entry	DD ?
dir_parent			DW ?
dir_usage			DW ?

dir_data_struc	ENDS

dir_entry_struc	STRUC

dir_prev		DD ?
dir_next		DD ?
dir_handle		DW ?
dir_sector		DD ?
dir_offset		DW ?
dir_name_size	DB ?
dir_name		DB 13 DUP(?)
dir_attrib		DB ?
dir_time		DD ?,?
dir_cluster		DD ?
dir_file_size	DD ?
dir_drive		DB ?

dir_entry_struc	ENDS

file_data_struc	STRUC

file_section		read_write_section_typ <>
file_ptr			DD ?
file_dir_entry		DD ?
file_usage			DW ?
file_parent			DW ?
file_cache_entry	DD ?
file_cache_ads		DD ?

file_data_struc	ENDS

FILE_ENTRY_SIZE	EQU 16

file_entry_struc	STRUC

file_next		DD ?
file_cluster	DD ?,?,?

file_entry_struc	ENDS

drive_data_seg	STRUC

fat1_sector			DD ?
fat2_sector			DD ?
start_sector		DD ?
root_sector			DD ?
root_entries		DW ?
clusters			DD ?
file_list_ptr		DD ?
file_free_ptr		DD ?
drive_root_handle	DW ?
cluster_section		section_typ <>
fat_type			DB ?
fat_cluster_shift	DB ?
drive_nr			DB ?

drive_data_seg	ENDS

