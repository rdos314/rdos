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
; FLASHFS.INC
; FLASHFS filesystem common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_data_seg  STRUC

block_count			DW ?
drive_nr			DB ?
resv				DB ?

drive_data_seg	ENDS

block_sector_struc	STRUC

bs_physical_sector	DB ?
bs_type				DB ?

block_sector_struc	ENDS

block_seg	STRUC

bc_handle			DD ?
bc_ptr				DD ?
bc_start_sector		DD ?
bc_logical_block	DW ?
bc_log_sector_arr	DB 127 * SIZE block_sector_struc DUP (?)
bc_phys_sector_arr	DB 127 DUP (?)

block_seg	ENDS

fc_logical_block	EQU 1FBh
fc_version			EQU 1FDh
fc_signature		EQU 1FEh

FLASH_SIGN_OK	=	0CD05h

logical_entry_struc	STRUC

le_physical_sector	DB ?
le_logical_entry	DB ?
le_type				DB ?

logical_entry_struc	ENDS

LOG_ENTRY_DIR_DATA =	04Ch
LOG_ENTRY_DIR_ENTRY =	05Ah
LOG_ENTRY_FILE_DATA =	0C4h

dir_entry_header_struc	STRUC

deh_attrib			DB ?
deh_name			DB ?

dir_entry_header_struc	ENDS

dir_entry_struc	STRUC

de_size				DD ?
de_time				DD ?,?
de_cluster_entry	DB ?
de_cluster_block	DW ?
de_valid			DB ?

dir_entry_struc	ENDS

DIR_ENTRY_OK =	0B5h

cluster_struc	STRUC

c_cluster_entry		DB ?
c_cluster_block		DW ?
c_valid				DB ?

cluster_struc	ENDS

CLUSTER_OK = 67h

dir_data_struc	STRUC

dd_cluster_entry	DB ?
dd_cluster_block	DW ?
dd_valid			DB ?

dir_data_struc	ENDS

DIR_DATA_OK = 0D4h
