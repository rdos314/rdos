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
; 9 bit phys = 512 sectors, 64 bytes bitmap, 4 byte linear
; 8 bit 16k bitmap
; 10 bit linear, 4k linear (4x16k bitmap)
; 10 bit linear, 16k bitmap + 4k linear
;
; 29 bits: 0.5G 4k blocks / entry
;
; 48 bits: 0.5M entries, 2M memory
;
; VFS.INC
; File system interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VFS_HANDLE_SIG     = 'H'
VFS_REQ_SIG        = 'R'

VFS_FLAG_STOPPED   = 1
VFS_FLAG_BUSY      = 2

MAX_VFS_PARTITIONS = 15
MAX_VFS_REQ_COUNT  = 15
MAX_VFS_ENTRY_COUNT = 255
MAX_VFS_FILE_COUNT  = 1024
MAX_VFS_FILE_REQ_COUNT  = 4096

MAX_PROC_COUNT           = 256

vfs_table_struc    STRUC

; IN  BX        Param
; OUT EDX:EAX   Sector count
; OUT BX        Max req size in sectors
; OUT CX        Bytes per sector
vfs_init                 DD ?,?

; IN  BX        Param
; IN  EDI       Vendor buffer
vfs_get_vendor           DD ?,?

; IN  BX        Param
vfs_exit                 DD ?,?

; OUT AX        Heads
; OUT BX        Sectors per cylinder
vfs_get_bios             DD ?,?

; IN  CX        Sector count
; IN  EDX:EAX   Start sector
; IN  ES:EDI    Physical entries
vfs_read                 DD ?,?

; IN  CX        Sector count
; IN  EDX:EAX   Start sector
; IN  ES:EDI    Physical entries
vfs_write                DD ?,?

; OUT NC        Static
;     CY        Dynamic
vfs_is_static            DD ?,?

vfs_table_struc   ENDS

vfs_struc  STRUC

vfs_table                vfs_table_struc <>

vfs_sectors              DD ?,?
vfs_blocks               DD ?,?
vfs_dirs                 DD ?,?

vfs_bytes_per_sector     DW ?
vfs_max_req              DW ?
vfs_param                DW ?
vfs_server               DW ?
vfs_req_buf              DW ?
vfs_sectors_per_block    DW ?
vfs_flags                DB ?
vfs_sector_shift         DB ?

vfs_section              section_typ <>

vfs_disc_nr              DB ?
vfs_byte_pad             DB ?
vfs_app_sel              DW ?
vfs_req_list             DW ?

vfs_map_entry            DD ?
vfs_active_count         DD ?
vfs_scan_pos             DD ?,?

vfs_locked_pages         DD ?
vfs_cached_pages         DD ?
vfs_max_cached_pages     DD ?

vfs_curr_start_sector    DD ?,?
vfs_curr_sector_count    DD ?,?
vfs_gpt_entry_count      DD ?
vfs_gpt_base             DD ?
vfs_gpt_start            DD ?
vfs_gpt_start_sector     DD ?,?

vfs_cache_discard_pos    DD ?,?

vfs_part_thread          DW ?
vfs_part_done            DW ?

vfs_cmd_thread           DW ?
vfs_vendor_str           DB 256 DUP(?)

vfs_my_part              DW ?
vfs_part_arr             DW MAX_VFS_PARTITIONS DUP(?)

vfs_buf_count            DD ?

vfs_buf_arr              DD ?

vfs_struc  ENDS

VFS_PHYS_PRESENT = 1
VFS_PHYS_VALID   = 2
VFS_PHYS_USED    = 4
VFS_PHYS_ERRORS  = 8

VFS_PHYS_PRESENT_BIT  = 0
VFS_PHYS_VALID_BIT    = 1
VFS_PHYS_USED_BIT     = 2
VFS_PHYS_ERRORS_BIT   = 3

vfs_phys_entry   STRUC

vfsp_wr_bitmap            DB ?
vfsp_flags                DB ?
vfsp_phys                 DW ?,?
vfsp_ref_bitmap           DW ?

vfs_phys_entry   ENDS

VFS_BUF_PRESENT = 1
VFS_BUF_RD_REQ  = 2
VFS_BUF_WR_REQ  = 4

vfs_buf_entry    STRUC

vfsb_ref_count            DB ?
vfsb_flags                DB ?
vfsb_linear               DW ?

vfs_buf_entry    ENDS

vfs_req          STRUC

vfsrq_prev                DW ?
vfsrq_next                DW ?

vfsrq_sector              DD ?,?
vfsrq_thread              DW ?

vfs_req          ENDS

; should be 16 bytes!

vfs_server_msg  STRUC

vfss_phys                  DD ?,?
vfss_server_linear         DD ?
vfss_sel                   DW ?
vfss_thread                DW ?

vfs_server_msg  ENDS

VFSP_FLAG_STOPPED   = 1

vfs_part  STRUC

vfsp_start_sector         DD ?,?
vfsp_sector_count         DD ?,?

vfsp_part_type            DD ?

vfsp_req_section          section_typ <>
vfsp_cmd_thread           DW ?
vfsp_cmd_curr             DD ?

vfsp_cmd_unused_mask      DD ?
vfsp_cmd_free_mask        DD ?
vfsp_cmd_arr              DD 4 * 32 DUP(?)
vfsp_cmd_ring             DB 34 DUP(?)
vfsp_cmd_head             DB ?
vfsp_cmd_tail             DB ?

vfsp_req_arr              DW MAX_VFS_REQ_COUNT DUP(?)

vfsp_io_section           section_typ <>
vfsp_io_sel               DW ?
vfsp_io_thread            DW ?
vfsp_io_wr_ptr            DW ?
vfsp_app_sel              DW ?
vfsp_disc_sel             DW ?
vfsp_flag                 DW ?
vfsp_disc_nr              DB ?
vfsp_part_nr              DB ?
vfsp_drive_nr             DB ?
vfsp_resv                 DB ?

vfs_part  ENDS

vfs_file_part    STRUC

vfsp_base                 vfs_part <>

vfsp_file_list            DW ?

vfsp_file_arr             DW MAX_VFS_FILE_COUNT DUP(?,?,?,?)
vfsp_file_req_arr         DW MAX_VFS_FILE_REQ_COUNT DUP(?,?)

vfs_file_part    ENDS


; should be 4 bytes!!

vfs_req_base  STRUC

vfsr_callback             DD ?

vfs_req_base  ENDS

; should be 16 bytes!!

vfs_req_header  STRUC

vfsrh_header              vfs_req_base <>
vfsrh_entry_count         DW ?
vfsrh_deleted_count       DW ?
vfsrh_remain_count        DD ?
vfsrh_wait_obj            DW ?
vfsrh_pad                 DW ?

vfs_req_header  ENDS

; should be 16 bytes!!

vfs_req_entry  STRUC

vfsre_start_sector        DD ?,?
vfsre_sector_count        DD ?
vfsre_linear              DD ?

vfs_req_entry  ENDS

vfs_part_req  STRUC

vfspr_hdr                 vfs_req_header <>

vfspr_arr                 DB SIZE vfs_req_entry * MAX_VFS_ENTRY_COUNT DUP(?)

vfs_part_req  ENDS

vfs_read_msb  STRUC

vfsm_rd_ptr        DD ?
vfsm_rd_count      DD ?
vfsm_rd_size       DD ?
vfsm_rd_pad        DD ?

vfs_read_msb  ENDS

vfs_read_entry  STRUC

vfs_rd_header         vfs_req_base <>

vfs_rd_index          DD ?
vfs_rd_file_handle    DD ?
vfs_rd_req_handle     DD ?
vfs_rd_remain_count   DD ?
vfs_rd_sectors        DD ?
vfs_rd_start_msb      DD ?
vfs_rd_msb_count      DD ?

vfs_rd_chain_ptr      DD ?
vfs_rd_sorted_ptr     DD ?
vfs_rd_index_ptr      DD ?
vfs_rd_msb_ptr        DD ?

vfs_read_entry  ENDS

share_block_struc       STRUC

sb_usage    DW ?
sb_pages    DW ?

share_block_struc       ENDS

fs_queue_entry   STRUC

fqe_p64          DD ?,?
fqe_p32          DD ?
fqe_handle       DW ?
fqe_op           DW ?

fs_queue_entry   ENDS
