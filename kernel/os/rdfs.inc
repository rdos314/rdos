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

drive_data_seg	STRUC

mapping_sector		DD ?
data_sector			DD ?
sectors				DD ?
drive_root_handle	DW ?
drive_nr			DB ?

drive_data_seg	ENDS

rdfs_dir_ptr_struc	STRUC

rdp_rel_sector		DW ?
rdp_offset			DW ?

rdfs_dir_ptr_struc	ENDS

rdfs_dir_sector_struc	STRUC

rds_free_list		DW ?

rdfs_dir_sector_struc	ENDS

rdfs_dir_start_sector_struc	STRUC

rdss_base			rdfs_dir_sector_struc <>
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
