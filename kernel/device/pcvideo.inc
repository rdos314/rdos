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
; PCVIDEO.INC
; PC video common types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VIDEO_MODE_FLAGS_PM		EQU 1
VIDEO_MODE_FLAGS_LFB	EQU 2

STYLE_HOLLOW			EQU 0
STYLE_FILLED			EQU 1

video_resol_struc	STRUC

vr_next				DW ?

vr_x_size			DW ?
vr_y_size			DW ?

vr_flat16_mode		DW ?
vr_flat24_mode		DW ?
vr_flat32_mode		DW ?

vr_flat16_flags		DB ?
vr_flat24_flags		DB ?
vr_flat32_flags		DB ?

video_resol_struc	ENDS

video_data_seg	STRUC

v_curr_object		DW ?
v_major_ver			DB ?
v_minor_ver			DB ?
v_cap				DW ?
v_video_mem			DD ?
v_pm16_stack		DW ?
v_pm16_entry		DD ?
v_pm32_io			DW ?
v_pm32_data_sel		DW ?
v_pm32_code_sel		DW ?
v_init_proc			DW ?
v_set_window_proc	DW ?
v_set_start_proc	DW ?
v_set_palette_proc	DW ?
v_video_resol_list	DW ?

video_data_seg	ENDS

video_thread_seg	STRUC

vt_color		DD ?
vt_lgop			DW ?
vt_style		DB ?

video_thread_seg	ENDS
