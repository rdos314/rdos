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
; SPRITE.INC
; Sprite interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SP_FLAG_VISIBLE  EQU 1
SP_FLAG_OVL_OLD  EQU 2
SP_FLAG_OVL_NEW  EQU 4 

sprite_struc	STRUC

sp_base		    handle_header <>
sp_sel          DW ?

sprite_struc	ENDS

sprite_info_struc   STRUC

spi_x_min       DW ?
spi_y_min       DW ?
spi_x_max       DW ?
spi_y_max       DW ?
spi_width       DW ?
spi_height      DW ?
spi_sel         DW ?
spi_flags       DB ?

sprite_info_struc   ENDS

sprite_line_struc   STRUC

spl_lower_ind       DW ?
spl_upper_ind       DW ?

sprite_line_struc   ENDS

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
sp_new_x			DW ?
sp_new_y			DW ?
sp_w                DW ?
sp_h                DW ?
sp_dest_w           DW ?
sp_dest_h           DW ?
sp_index            DW ?
sp_x_min            DW ?
sp_y_min            DW ?
sp_x_max            DW ?
sp_y_max            DW ?
sp_bpp              DB ?
sp_flags            DB ?

sprite_sel_struc    ENDS
