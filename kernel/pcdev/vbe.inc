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
; VBE.INC
; VBE common types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pm_info_block	STRUC

pmi_signature	DB 4 DUP(?)
pmi_entry_point	DW ?
pmi_init		DW ?
pmi_bios_data	DW ?
pmi_A000		DW ?
pmi_B000		DW ?
pmi_B800		DW ?
pmi_C000		DW ?
pmi_mode		DB ?
pmi_chksum		DB ?

pm_info_block	ENDS

vesa_info_struc	STRUC

vesa_name		DB 4 DUP(?)
vesa_minor_ver	DB ?
vesa_major_ver	DB ?
vesa_oem_ptr	DD ?
vesa_cap		DD ?
vesa_modes		DD ?
vesa_video_mem	DW ?

vesa_info_struc	ENDS

vesa_pm_struc	STRUC

vpm_set_window		DW ?
vpm_set_disp_start	DW ?
vpm_set_palette		DW ?
vpm_table			DW ?

vesa_pm_struc	ENDS

MODE_ATTRIB_SUPORTED	EQU 1
MODE_ATTRIB_TTY			EQU 4
MODE_ATTRIB_COLOR		EQU 8
MODE_ATTRIB_GRAPHICS	EQU 10h
MODE_ATTRIB_NON_VGA		EQU 20h
MODE_ATTRIB_NO_WINDOW	EQU 40h
MODE_ATTRIB_LFB			EQU 80h
MODE_ATTRIB_DOUBLE_SCAN	EQU 100h
MODE_ATTRIB_INTERLACED	EQU 200h
MODE_ATTRIB_TRIPPLE_BUF	EQU 400h
MODE_ATTRIB_STEREO		EQU 800h
MODE_ATTRIB_DUAL_START	EQU 1000h

MODE_ATTRIB_REQUIRED	EQU 99h

WIN_ATTRIB_RELOC		EQU 1
WIN_ATTRIB_READ			EQU 2
WIN_ATTRIB_WRITE		EQU 4

MODEL_TEXT				EQU 0
MODEL_CGA				EQU 1
MODEL_HERC				EQU 2
MODEL_PLANAR			EQU 3
MODEL_PACKED			EQU 4
MODEL_256				EQU 5
MODEL_DIRECT			EQU 6
MODEL_YUV				EQU 7

vesa_mode_info	STRUC

vmi_mode_attrib		DW ?
vmi_wina_attrib		DB ?
vmi_winb_attrib		DB ?
vmi_granularity		DW ?
vmi_size			DW ?
vmi_wina_seg		DW ?
vmi_winb_seg		DW ?
vmi_win_func		DD ?
vmi_scan_lines		DW ?
vmi_x_pixels		DW ?
vmi_y_pixels		DW ?
vmi_x_chars			DB ?
vmi_y_chars			DB ?
vmi_planes			DB ?
vmi_bits_per_pixel	DB ?
vmi_banks			DB ?
vmi_memory_model	DB ?
vmi_bank_size		DB ?
vmi_pages			DB ?
vmi_resv1			DB ?
vmi_red_mask_size	DB ?
vmi_red_position	DB ?
vmi_green_mask_size	DB ?
vmi_green_position	DB ?
vmi_blue_mask_size	DB ?
vmi_blue_position	DB ?
vmi_rsvd_mask_size	DB ?
vmi_rsvd_position	DB ?
vmi_dir_color_mode	DB ?
vmi_lfb				DD ?

vesa_mode_info	ENDS

vbe_object	STRUC

vo_base			video_api_struc <>
vo_lfb			DD ?
vo_lfb_base		DD ?
vo_mem_base		DD ?
vo_flags		DB ?
vo_has_focus	DB ?
vo_mode_info	vesa_mode_info <>

vbe_object	ENDS
