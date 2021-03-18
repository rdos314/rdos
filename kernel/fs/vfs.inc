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
; VFS.INC
; File system interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VFS_FLAG_STOPPED   = 1

vfs_table_struc    STRUC

; IN  BX        Param
; OUT EDX:EAX   Sector count
; OUT BX        Max req size in sectors
; OUT CX        Bytes per sector
vfs_init                 DD ?,?

; IN  BX        Param
vfs_exit                 DD ?,?

; IN  CX        Sector count
; IN  EDX:EAX   Start sector
; IN  ES:EDI    Physical entries
vfs_read                 DD ?,?

; IN  CX        Sector count
; IN  EDX:EAX   Start sector
; IN  ES:EDI    Physical entries
vfs_write                DD ?,?

vfs_table_struc   ENDS

vfs_struc  STRUC

vfs_table                vfs_table_struc <>

vfs_sectors              DD ?,?
vfs_blocks               DD ?,?
vfs_dirs                 DD ?,?
vfs_entries              DD ?
vfs_bytes_per_sector     DW ?
vfs_max_req              DW ?
vfs_param                DW ?
vfs_server               DW ?
vfs_flags                DB ?
vfs_sector_shift         DB ?
vfs_phys_shift           DB ?
vfs_buf_shift0           DB ?
vfs_buf_shift1           DB ?

vfs_struc  ENDS

VFS_PHYS_PRESENT = 0
VFS_PHYS_RD_REQ  = 1
VFS_PHYS_WR_REQ  = 2
VFS_PHYS_REF     = 4

vfs_phys_entry   STRUC

vfsp_ref_count            DB ?
vfsp_flags                DB ?
vfsp_phys                 DW ?,?,?

vfs_phys_entry   ENDS

VFS_BUF_PRESENT = 400h

vfs_buf_entry    STRUC

vfsb_flag_bitmap          DW ?
vfsb_linear               DW ?

vfs_buf_entry    ENDS
