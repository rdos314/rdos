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

STYLE_HOLLOW			EQU 0
STYLE_FILLED			EQU 1

; DS 		Video handle

video_api_struc	STRUC

destruct_proc			DD ?

switch_to_proc			DD ?

switch_from_proc		DD ?

; IN  BL		Blank fore color
; IN  BH		Blank back color
; IN  CX		Upper Column
; IN  DX		Upper Row
; IN  SI		Lower Column
; IN  DI		Lower Row
clear_proc			DD ?

; IN  CX		Column
; IN  DX		Row
set_cursor_position_proc	DD ?

; IN  AL		Char
; IN  BL		Fore color
; IN  BH		Back color
; IN  CX		Column
; IN  DX		Row
write_char_proc       	DD ?

; IN  CX		Column
; IN  DX		Row
; OUT AL		Char
; OUT BL		Fore color
; OUT BH		Back color
read_char_proc       	DD ?

; IN  AX		Number of lines
; IN  BL		Blank fore color
; IN  BH		Blank back color
; IN  CX		Upper Column
; IN  DX		Upper Row
; IN  SI		Lower Column
; IN  DI		Lower Row
scroll_up_proc			DD ?

; IN  AX		Number of lines
; IN  BL		Blank fore color
; IN  BH		Blank back color
; IN  CX		Upper Column
; IN  DX		Upper Row
; IN  SI		Lower Column
; IN  DI		Lower Row
scroll_down_proc		DD ?

; IN  AX        Font handle
set_font_proc  			DD ?

; IN  CX		Number of palette entries
; IN  ES:EDI	Palette
define_palette_proc		DD ?

; IN  AL		Palette index
set_palette_color_proc	DD ?

; IN  AX		Red
; IN  BX		Green
; IN  DX		Blue
set_rgb_color_proc		DD ?

clear_mask_proc			DD ?

; IN  CX		x position
; IN  DX		y position
; IN  FS:ESI	bitmap info
; IN  ES:EDI	bitmap
add_mask_proc			DD ?

; IN  CX		x position
; IN  DX		y position
; IN  AL		Char
draw_char_proc       	DD ?

; IN  CX		x position
; IN  DX		y position
; IN  ES:EDI	Null terminated string
draw_string_proc		DD ?

; IN  CX		x position
; IN  DX		y position
; IN  FS:ESI	bitmap info
; IN  ES:EDI	bitmap
draw_bitmap_proc		DD ?

; IN  AX		start x
; IN  BX		start y
; IN  CX		end x
; IN  DX		end y
fill_rect_proc			DD ?

; IN  EAX			RGB color
set_color_proc			DD ?

; IN  CX			x
; IN  DX			y
; OUT EAX			RGB color
get_pixel_proc			DD ?

; IN  CX			x
; IN  DX			y
set_pixel_proc			DD ?

; IN  AX			number of pixels
; IN  CX			x
; IN  DX			y
; IN  ES:EDI		line buffer
get_native_row_proc		DD ?

; IN  AX			number of pixels
; IN  CX			x
; IN  DX			y
; IN  ES:EDI		line buffer
get_rgb_row_proc		DD ?

; IN  AX			number of pixels
; IN  CX			x
; IN  DX			y
; IN  ES:EDI		line buffer
set_native_row_proc		DD ?

; IN  AX			number of pixels
; IN  CX			x
; IN  DX			y
; IN  ES:EDI		line buffer
set_rgb_row_proc		DD ?

; IN  CX			x
; IN  DX			y
; OUT ES:EDI		line buffer
get_line_proc			DD ?

; IN  AX			x1
; IN  BX			y1
; IN  CX			x2
; IN  DX			y2
draw_line_proc			DD ?

; IN  AX			x
; IN  BX			y
; IN  CX			w
; IN  DX			b
draw_rect_proc			DD ?

; IN  AX			x
; IN  BX			y
; IN  CX			w
; IN  DX			b
draw_ellipse_proc			DD ?

v_section	section_typ <>
v_mode		DW ?
v_width		DW ?
v_height	DW ?
v_row_size	DW ?
v_app_base	DD ?
v_app_size	DD ?
v_bpp		DB ?
v_bitmap	DW ?

v_color		DD ?
v_lgop		DW ?
v_style		DB ?

video_api_struc	ENDS
