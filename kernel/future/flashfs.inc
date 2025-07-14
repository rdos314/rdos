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
; FLASHFS.INC
; FLASHFS filesystem common data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flash_dir_sel_data_struc	STRUC

fds_base			dir_sel_data_struc <>

fds_owner_sector	DD ?
fds_entry_sector	DD ?
fds_object_sector	DD ?
fds_data_sector		DD ?
fds_used_entries	DD ?
fds_deleted_entries	DD ?
fds_info_offset		DW ?

flash_dir_sel_data_struc	ENDS

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
spare_sector		DD ?

drive_data_seg	ENDS

block_sector_struc	STRUC

bs_owner            DD ?
bs_physical_sector	DW ?
bs_status			DB ?

block_sector_struc	ENDS

fl_block_seg	STRUC

bc_op_handle		DD ?
bc_op_ads           DD ?
bc_start_sector		DD ?
bc_handle_ptr		DD ?
bc_data_ptr			DD ?
bc_log_sector_ptr	DD ?
bc_phys_sector_ptr	DD ?
bc_version          DW ?
bc_logical_block	DB ?

fl_block_seg	ENDS

fc_logical_block	EQU 1F8h
fc_version			EQU 1FAh
fc_signature		EQU 1FCh

FLASH_SIGN_OK	EQU	3AF6CD55h

logical_entry_struc	STRUC

le_physical_sector	DW ?
le_logical_entry	DW ?
le_owner			DB ?,?,?
le_status			DB ?

logical_entry_struc	ENDS

LOG_ENTRY_DIR_DATA =	00010100b
LOG_ENTRY_OBJECT =      00001010b
LOG_ENTRY_DIR_ENTRY =	00000101b
LOG_ENTRY_FILE_DATA =	00011100b
LOG_ENTRY_ERASE =		00001011b

LOG_STATUS_BEFORE_ALLOC = 11100000b
LOG_STATUS_AFTER_ALLOC  = 11000000b
LOG_STATUS_BEFORE_FREE  = 10000000b
LOG_STATUS_AFTER_FREE   = 00000000b

dir_entry_header_struc	STRUC

deh_attrib			DB ?
deh_name			DB ?

dir_entry_header_struc	ENDS

dir_entry_struc	STRUC

fde_size			DD ?
fde_time			DD ?,?
fde_valid			DB ?

dir_entry_struc	ENDS

DIR_ENTRY_OK =			0B5h
DIR_ENTRY_RESTRUCT =	0FDh	; must be possible to convert to Free
DIR_ENTRY_FREE =        0F5h    ; must be possible to convert to OK

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
