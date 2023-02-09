;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; FILEMAP.INC
; Mapping files in user space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FILE_MAP_BASE_SIGN     = 0FA67h
FILE_MAP_EXTEND_SIGN   = 045A8h

file_map_header	STRUC

fmh_adr             DD ?
fmh_bitmap_offset   DW ?
fmh_data_offset     DW ?
fmh_bitmap_dd_count DW ?
fmh_free_bits       DW ?
fmh_sign            DW ?
fmh_size_shift      DB ?
fmh_pad             DB ?

file_map_header	ENDS

file_map_buf  STRUC

fmb_pos             DD ?,?
fmb_size            DD ?
fmb_wr_bitmap       DD ?
fmb_ptr             DD ?

file_map_buf  ENDS

file_map_entry  STRUC

fme_header          file_map_header <>
fme_info            DD ?
fme_user_handle     DW ?
fme_kernel_handle   DW ?
fme_pos             DD ?,?
fme_buf_arr         DD 256 DUP(?)

file_map_entry  ENDS
