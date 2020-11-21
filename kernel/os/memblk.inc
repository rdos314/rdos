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
; MEMBLK.INC
; Memory block interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_blk_header	STRUC

mblk_physical_base   DD ?,?
mblk_linear_base     DD ?
mblk_info_offset     DW ?
mblk_sign            DW ?

mem_blk_header	ENDS

mem_blk_info	STRUC

mblk_bitmap_offset   DW ?
mblk_data_offset     DW ?
mblk_bitmap_dd_count DW ?
mblk_free_bits       DW ?
mblk_size_shift      DB ?
mblk_is64            DB ?
mblk_ext_count       DW ?
mblk_ext_size        DW ?
mblk_ext_arr         DW ?

mem_blk_info	ENDS

mem_blk_extend	STRUC

mblke_header          mem_blk_header <>

mblke_bitmap_offset   DW ?
mblke_data_offset     DW ?
mblke_bitmap_dd_count DW ?
mblke_free_bits       DW ?
mblke_size_shift      DB ?
mblke_pad             DB ?

mem_blk_extend	ENDS

