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


MAX_LFN_ENTRIES = 20

lfn_pos_struc   STRUC

lfnp_sector     DD ?
lfnp_offset     DD ?

lfn_pos_struc   ENDS

lfn_struc   STRUC

lfn_entries         DW ?
lfn_entry_arr       DD 2 * MAX_LFN_ENTRIES DUP (?)
lfn_seq             DB ?
lfn_chksum          DB ?
lfn_name            DB 256 DUP(?)

lfn_struc   ENDS

lfn_entry_struc STRUC

lfne_seq    DB ?
lfne_char1  DB ?,?
lfne_char2  DB ?,?
lfne_char3  DB ?,?
lfne_char4  DB ?,?
lfne_char5  DB ?,?
lfne_attrib DB ?
lfne_type   DB ?
lfne_chksum DB ?
lfne_char6  DB ?,?
lfne_char7  DB ?,?
lfne_char8  DB ?,?
lfne_char9  DB ?,?
lfne_char10 DB ?,?
lfne_char11 DB ?,?
lfne_clust  DW ?
lfne_char12 DB ?,?
lfne_char13 DB ?,?

lfn_entry_struc ENDS

fat_dir_sel_data_struc	STRUC

fds_base			dir_sel_data_struc <>

fds_deleted_ptr		DD ?
fds_free_ptr		DD ?

fat_dir_sel_data_struc	ENDS

fe_struc	STRUC

fe_base				dir_entry_data_struc <>

fe_entry_sector		DD ?
fe_entry_offset		DW ?

fe_struc	ENDS

fde_struc	STRUC

fde_base			dir_dir_entry_data_struc <>

fde_entry_sector	DD ?
fde_entry_offset	DW ?
fde_start_cluster	DD ?
fde_start_sector	DD ?
fde_fat_name        DB 13 DUP(?)

fde_name		DB ?

fde_struc	ENDS

ffe_struc	STRUC

ffe_base			dir_file_entry_data_struc <>

ffe_entry_sector	DD ?
ffe_entry_offset	DW ?
ffe_start_cluster	DD ?
ffe_fat_name        DB 13 DUP(?)

ffe_name			DB ?

ffe_struc	ENDS

fat_file_list_struc	STRUC

ffl_basic			file_list_struc <>
ffl_sector_ptr		DD ?
ffl_clusters		DD ?

fat_file_list_struc	ENDS

drive_data_seg	STRUC

fat1_sector			DD ?
fat2_sector			DD ?
start_sector		DD ?
root_sector			DD ?
root_entries		DW ?
clusters			DD ?
free_clusters       DD ?
file_list_ptr		DD ?
file_free_ptr		DD ?
drive_root_handle	DW ?
cluster_section		section_typ <>
fat_type			DB ?
fat_cluster_shift	DB ?
drive_nr			DB ?

drive_data_seg	ENDS

