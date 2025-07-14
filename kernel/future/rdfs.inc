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
; RDFS.INC
; RDFS filesystem common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INFO_STATE_NONE =	0
INFO_STATE_ALLOC =	1
INFO_STATE_FREE =	2

rdfs_info_struc	STRUC

ri_first_id			DD ?
ri_free_arr			DD ?
ri_free_arr_size	DD ?
ri_start_sector		DD ?
ri_total_sectors	DD ?
ri_root_dir			DD ?
ri_data_sectors		DD ?
ri_free_sectors		DD ?
ri_hole_start		DD ?
ri_hole_size		DD ?
ri_target_sector	DD ?
ri_target_offset	DW ?
ri_state			DW ?
ri_sector			DD ?
ri_count			DD ?

ri_last_id			DD ?

rdfs_info_struc	ENDS

alloc_struc	STRUC

as_base			DD ?
as_size			DD ?
as_start		DD ?
as_sectors		DD ?

alloc_struc	ENDS

drive_data_seg	STRUC

info_sector			rdfs_info_struc <>
alloc_section		section_typ <>
alloc_sel			DW ?
drive_nr			DB ?

drive_data_seg	ENDS

RC_FLAG_DIR			EQU 1
RC_FLAG_BACKUP		EQU 2

rdfs_control_struc	STRUC

rc_version			DB ?
rc_flags			DB ?
rc_key_offset		DW ?
rc_size				DD ?
rc_sector_arr		DD 126 DUP(?)

rdfs_control_struc	ENDS

rdfs_dir_sector_header_struc	STRUC

rdsh_version	DB ?
rdsh_chksum		DB ?

rdfs_dir_sector_header_struc	ENDS

rdfs_dir_block_struc	STRUC

rdbf_prev	DW ?
rdbf_next	DW ?
rdbs_prev	DW ?
rdbs_next	DW ?

rdfs_dir_block_struc	ENDS

rdfs_dir_ptr_struc	STRUC

rdp_rel_sector		DW ?
rdp_offset			DW ?

rdfs_dir_ptr_struc	ENDS

rdfs_dir_start_sector_struc	STRUC

rdss_dir_list		rdfs_dir_ptr_struc <>
rdss_file_list		rdfs_dir_ptr_struc <>

rdfs_dir_start_sector_struc	ENDS

rdfs_dir_entry_struc	STRUC

rde_time			DD ?,?
rde_attrib			DW ?
rde_name_size		DW ?
rde_name			rdfs_dir_ptr_struc <>
rde_start_sector	DD ?

rdfs_dir_entry_struc	ENDS
