;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; REMDEBUG.INC
; Remote debugger data types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_seg	SEGMENT AT 0

op_syntax	DW ?
op_codes	DW 100 DUP(?)
op_in_text	DB 100 DUP(?)
op_text_end	DW ?
op_size		DW ?
op_ads		DW ?,?
gaddr_mode	DB ?
data_mode	DB ?
gdata_mode	DB ?
edata_mode	DB ?
override	DW ?
ignore_ptr	DB ?
data_off	DD ?
data_sel	DW ?
data_good	DB ?
op_in_code	DB 50 DUP(?)

debug_data_size	DB ?

debug_seg	ENDS

