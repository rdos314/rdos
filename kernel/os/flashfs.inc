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

fde_struc	STRUC

fde_base			dir_dir_entry_data_struc <>
fde_entry_sector	DD ?
fde_name			DB ?

fde_struc	ENDS

ffe_struc	STRUC

ffe_base			dir_file_entry_data_struc <>
ffe_entry_sector    DD ?
ffe_name			DB ?

ffe_struc	ENDS

drive_data_seg  STRUC

block_count			DB ?
drive_nr			DB ?
block_sectors		DW ?
control_sectors		DW ?
data_sectors		DW ?

drive_data_seg	ENDS

block_sector_struc	STRUC

bs_physical_sector	DW ?
bs_type				DW ?

block_sector_struc	ENDS

block_seg	STRUC

bc_alloc_handle		DD ?
bc_start_sector		DD ?
bc_handle_ptr		DD ?
bc_data_ptr			DD ?
bc_log_sector_ptr	DD ?
bc_phys_sector_ptr	DD ?
bc_version          DW ?
bc_logical_block	DB ?

block_seg	ENDS

fc_logical_block	EQU 1F8h
fc_version			EQU 1FAh
fc_signature		EQU 1FCh

FLASH_SIGN_OK	EQU	3AF6CD53h

logical_entry_struc	STRUC

le_physical_sector	DW ?
le_logical_entry	DW ?
le_resv				DW ?
le_type				DW ?

logical_entry_struc	ENDS

LOG_ENTRY_DIR_DATA =	04C58h
LOG_ENTRY_OBJECT =      0A6ADh
LOG_ENTRY_DIR_ENTRY =	05A74h
LOG_ENTRY_FILE_DATA =	0C4D5h
LOG_ENTRY_ERASE =		02F5Ah

dir_entry_header_struc	STRUC

deh_attrib			DB ?
deh_name			DB ?

dir_entry_header_struc	ENDS

dir_entry_struc	STRUC

fde_size			DD ?
fde_time			DD ?,?
fde_valid			DB ?

dir_entry_struc	ENDS

DIR_ENTRY_OK =	0B5h

object_struc	STRUC

o_log_entry		    DW ?
o_log_block	    	DB ?
o_valid				DB ?

object_struc	ENDS

OBJECT_OK = 67h

dir_data_struc	STRUC

fdd_log_entry	    DW ?
fdd_log_block   	DB ?
fdd_valid			DB ?

dir_data_struc	ENDS

DIR_DATA_OK = 0D4h
