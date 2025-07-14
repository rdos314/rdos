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
; FAT.INC
; FAT common types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat12				EQU 12
fat16				EQU 16
fat32				EQU 32

fat_info_struc  STRUC

fi_ext_sign         DD ?
fi_resv             DB 480 DUP(?)
fi_info_sign        DD ?
fi_free_clusters    DD ?
fi_next_cluster     DD ?
fi_info_resv        DB 12 DUP(?)
fi_info_end         DD ?

fat_info_struc  ENDS

MAX_LFN_ENTRIES = 20

lfn_pos_struc   STRUC

lfnp_sector     DD ?
lfnp_offset     DD ?

lfn_pos_struc   ENDS

lfn_struc   STRUC

lfn_fat_sector      DD ?
lfn_fat_offset      DW ?
lfn_entries         DW ?
lfn_entry_arr       DD 2 * MAX_LFN_ENTRIES DUP (?)
lfn_seq             DB ?
lfn_chksum          DB ?
lfn_fat_name        DB 13 DUP(?)
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

fds_start_sector    DD ?
fds_deleted_ptr		DD ?
fds_free_ptr		DD ?

fat_dir_sel_data_struc	ENDS

fe_struc	STRUC

fe_base				max_dir_entry_data_struc <>

fe_entry_sector		DD ?
fe_entry_offset		DW ?

fe_struc	ENDS

fde_struc	STRUC

fde_base			dir_dir_entry_data_struc <>

fde_entry_sector	DD ?
fde_entry_offset	DW ?
fde_start_cluster	DD ?
fde_start_sector	DD ?
fde_lfn_count       DW ?
fde_lfn_arr         DD 2 * MAX_LFN_ENTRIES DUP (?)
fde_fat_name        DB 13 DUP(?)

fde_name		DB ?

fde_struc	ENDS

ffe_struc	STRUC

ffe_base			dir_file_entry_data_struc <>

ffe_entry_sector	DD ?
ffe_entry_offset	DW ?
ffe_start_cluster	DD ?
ffe_lfn_count       DW ?
ffe_lfn_arr         DD 2 * MAX_LFN_ENTRIES DUP (?)
ffe_fat_name        DB 13 DUP(?)

ffe_name			DB ?

ffe_struc	ENDS

fat_file_list_struc	STRUC

ffl_basic			file_list_struc <>
ffl_sector_ptr		DD ?
ffl_clusters		DD ?

fat_file_list_struc	ENDS

drive_data_seg	STRUC

info_sector         DD ?
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

