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
; RDFS.INC
; RDFS filesystem common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

boot_struc	STRUC

boot_jmp					DB ?,?,?
boot_name					DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_resv1					DB ?
boot_mapping_sectors		DW ?
boot_resv3					DB ?
boot_resv4					DW ?
boot_resv5					DW ?
boot_media					DB ?
boot_resv6					DW ?
boot_sectors_per_cyl		DW ?
boot_heads					DW ?
boot_hidden_sectors			DD ?
boot_sectors				DD ?
boot_drive_nr				DB ?,?
boot_signature				DB ?
boot_serial					DD ?
boot_volume					DB 11 DUP(?)
boot_fs						DB 8 DUP(?)

boot_struc		ENDS

dir_data_struc	STRUC

dir_section			section_typ <>
dir_dir_ptr			DD ?
dir_file_ptr		DD ?
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
dir_attrib		DB ?
dir_time		DD ?,?
dir_cluster		DW ?
dir_file_size	DD ?
dir_drive		DB ?
dir_name_size	DB ?
dir_name		DB ?

dir_entry_struc	ENDS

file_data_struc	STRUC

file_section		section_typ <>
file_ptr			DD ?
file_dir_entry		DD ?
file_usage			DW ?
file_parent			DW ?

file_data_struc	ENDS

drive_data_seg	STRUC

mapping_sector		DD ?
data_sector			DD ?
sectors				DD ?
drive_root_handle	DW ?
drive_nr			DB ?

drive_data_seg	ENDS

