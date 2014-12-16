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
; IPCGUI.INC
; Common types for IPC-based remote GUI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gen_req_struc	STRUC

gr_op		    DB ?

gen_req_struc	ENDS

video_req_struc	STRUC

vr_op		    DB ?
vr_row          DW ?

video_req_struc	ENDS

mode_reply_struc	STRUC

grm_mode		DW ?
grm_width       DW ?
grm_height      DW ?
grm_row_size    DW ?
grm_bpp         DB ?

mode_reply_struc	ENDS

GUI_REQ_MODE    	EQU 1
GUI_REQ_VIDEO       EQU 2

