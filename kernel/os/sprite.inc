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
; SPRITE.INC
; Sprite interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SP_FLAG_VISIBLE  EQU 1

sprite_struc	STRUC

sp_base		    handle_header <>
sp_sel              DW ?

sprite_struc	ENDS

sprite_sel_struc  STRUC

sp_back_handle      DW ?
sp_back_sel         DW ?
sp_dest_sel         DW ?
sp_bitmap_handle    DW ?
sp_bitmap_sel       DW ?
sp_mask_sel         DW ?
sp_lgop             DW ?
sp_x                DW ?
sp_y                DW ?
sp_w                DW ?
sp_h                DW ?
sp_dest_w           DW ?
sp_dest_h           DW ?
sp_bpp              DB ?
sp_flags            DB ?

sprite_sel_struc    ENDS
