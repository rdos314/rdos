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
; MOUSE.INC
; Common mouse related types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mouse_seg	SEGMENT AT 0

m_cursor_flag	DW ?

m_cursor_type	DW ?
m_cursor_mask	DW ?
m_screen_mask	DW ?

m_horiz_pos		DW ?
m_vert_pos		DW ?

m_horiz_motion	DW ?
m_vert_motion	DW ?

m_horiz_mickey	DW ?
m_vert_mickey	DW ?

m_horiz_min		DW ?
m_horiz_max		DW ?
m_vert_min		DW ?
m_vert_max		DW ?

m_botton_status	DW ?

m_horiz_press0	DW ?
m_vert_press0	DW ?
m_count_press0	DW ?

m_horiz_press1	DW ?
m_vert_press1	DW ?
m_count_press1	DW ?

m_horiz_rel0	DW ?
m_vert_rel0		DW ?
m_count_rel0	DW ?

m_horiz_rel1	DW ?
m_vert_rel1		DW ?
m_count_rel1	DW ?

m_notify_thread	DW ?
m_notify_sel	DW ?
m_notify_offs	DD ?

m_end	DB ?

mouse_seg	ENDS

mouse_data_seg	SEGMENT AT 0

md_buttons		DW ?
md_dx			DW ?
md_dy			DW ?
md_mouse_thread	DW ?

md_end			DB ?

mouse_data_seg	ENDS
