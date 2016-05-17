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
; VIDEO.INC
; Video interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VIDEO_ENTRIES   = 1Ch

STYLE_HOLLOW                    EQU 0
STYLE_FILLED                    EQU 1

video_api_struc STRUC

; IN  AX                Red
; IN  BX                Green
; IN  DX                Blue
v_set_rgb_color_proc            DD ?,?

v_clear_mask_proc                       DD ?,?

; IN  CX                x position
; IN  DX                y position
; IN  FS:ESI    bitmap info
; IN  ES:EDI    bitmap
v_add_mask_proc                     DD ?,?

; IN  AX        Font handle
v_set_font_proc                         DD ?,?

; IN  EAX                       RGB color
; OUT EAX           internal color
v_translate_color_proc      DD ?,?

;
; device-dependent functions
;

; IN  EAX                       Internal color
; IN  EDI               Position
v_set_proc                      DD ?,?

; IN  EAX                       Internal color
; IN  EDI               Position
; IN  CX                        Number of pixels
v_slab_proc                 DD ?,?

; IN  EAX           Source base
; IN  FS:ESI        Source pixels
; IN  EDI               Position
; IN  CX                        Number of pixels
v_copy_proc                 DD ?,?

; IN  EAX           Internal Color
; IN  CX                        number of pixels
; IN  DL            Start bit number
; IN  GS:EBX        Mask bits
; IN  EDI                   Dest buffer
v_mask_set_proc             DD ?,?

; IN  CX                        number of pixels
; IN  DL            Start bit number
; IN  GS:EBX        Mask bits
; IN  FS:ESI        Source pixels
; IN  EDI                   Dest buffer
v_mask_copy_proc            DD ?,?

;
; device-independent functions
;

; IN  CX                        x
; IN  DX                        y
; OUT ES:EDI            Buffer
; OUT AL            Bit number
v_get_line_proc                     DD ?,?

; IN  CX                        x
; IN  DX                        y
; OUT EAX                       RGB color
v_get_pixel_proc                        DD ?,?

; IN  CX                        x
; IN  DX                        y
v_set_pixel_proc                        DD ?,?

; IN  AX                        number of pixels
; IN  CX                        x
; IN  DX                        y
; IN  EDI               Position
v_get_native_row_proc           DD ?,?

; IN  AX                        number of pixels
; IN  CX                        x
; IN  DX                        y
; IN  EDI               Position
v_get_rgb_row_proc                  DD ?,?

; IN  AX                        number of pixels
; IN  CX                        x
; IN  DX                        y
; IN  EDI               Position
v_set_native_row_proc           DD ?,?

; IN  AX                        number of pixels
; IN  CX                        x
; IN  DX                        y
; IN  EDI               Position
v_set_rgb_row_proc                  DD ?,?

; IN  AX                        source row size
; IN  EBX                       color
; IN  ECX                       source x + y << 16
; IN  EDX                       dest x + y << 16
; IN  SI                        width
; IN  ES:EDI            1-bit mask
v_draw_mask_line_proc       DD ?,?

; IN  AX                        number of pixels
; IN  BL            bit number
; IN  CX                        x
; IN  DX                        y
; IN  ES:EDI            line buffer
v_set_sprite_row_proc           DD ?,?

; IN  AL            mask offset bit
; IN  BL            bit number
; IN  ECX                       x + y << 16
; IN  DX                        width
; IN  ESI               sprite bits
; IN  ES:EDI            1-bit mask bits
v_draw_sprite_line_proc         DD ?,?

; IN  CX                x position
; IN  DX                y position
; IN  ES:EDI    Null terminated string
v_draw_string_proc                  DD ?,?

; IN  AX                        x1
; IN  BX                        y1
; IN  CX                        x2
; IN  DX                        y2
v_draw_line_proc                        DD ?,?

; IN  AX                        x
; IN  BX                        y
; IN  CX                        w
; IN  DX                        b
v_draw_rect_proc                        DD ?,?

; IN  AX                        x
; IN  BX                        y
; IN  CX                        w
; IN  DX                        b
v_draw_ellipse_proc                     DD ?,?

; IN  EAX           Internal Color
; IN  CX                        number of pixels
; IN  GS:EBX        Antialias bitmap (256 levels)
; IN  EDI                   Dest buffer
v_anti_alias_proc           DD ?,?

; IN  ECX                       Number of pixels
; IN  ES:ESI            Bitmap buffer
; IN  ES:EDI            Physical buffer
v_phys_update_proc          DD ?,?

v_has_alpha_proc                        DD ?,?

; IN  CX                        x
; IN  DX                        y
; OUT EAX                       RGB color
v_get_alpha_proc                        DD ?,?

; IN  AX                        number of pixels
; IN  CX                        x
; IN  DX                        y
; IN  EDI               Position
v_get_rgba_row_proc            DD ?,?

; IN  AX                        number of pixels
; IN  CX                        x
; IN  DX                        y
; IN  EDI               Position
v_set_rgba_row_proc            DD ?,?

v_section           section_typ <>
v_sprite_section    section_typ <>
v_mode          DW ?
v_width         DW ?
v_height        DW ?
v_row_size          DW ?
v_app_base          DD ?
v_app_size          DD ?
v_phys_base             DD ?
v_has_focus         DB ?
v_bpp                   DB ?
v_bitmap        DW ?

v_sprite_count          DW ?
v_sprite_size           DW ?
v_sprite_sel            DW ?

v_usage_count           DW ?

v_x_min                 DW ?
v_y_min                 DW ?
v_x_max                 DW ?
v_y_max                 DW ?

v_row                           DW ?
v_col                           DW ?
v_row_count                     DW ?
v_col_count                     DW ?
v_text_font                     DW ?
v_pixels_per_row        DW ?
v_pixels_per_col        DW ?
v_text                          DW ?

v_color                         DD ?
v_lgop                  DW ?
v_font                  DW ?
v_style                         DB ?
v_alpha             DB ?

v_sprite_lines          DW ?
v_sprite_max_pos        DW ?

v_sprite_show_size  DW ?
v_sprite_show_x     DW ?
v_sprite_show_y     DW ?

video_api_struc ENDS

CONSOLE_FLAG_RGB      =  1

console_text_struc  STRUC

ct_char     DB ?
ct_dirty    DB ?
ct_fore_col DB ?
ct_back_col DB ?

console_text_struc  ENDS

console_struc   STRUC

c_lfb           DD ?
c_width         DW ?
c_height        DW ?
c_scan_size     DD ?
c_flags         DD ?
c_font          DW ?
c_font_height   DW ?
c_font_width    DW ?
c_rows          DW ?
c_cols          DW ?

c_usage         DW ?

c_text_entries  DW ?

c_text_data     DB ?

console_struc   ENDS
