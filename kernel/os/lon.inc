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
; LON.INC
; Device-independent lonworks class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lon_struc	STRUC

lon_open_proc       DD ?,?

lon_close_proc      DD ?,?

lon_start_send_proc DD ?,?

lon_reset_proc      DD ?,?

lon_avail_obj       DW ?

lon_section         section_typ <>

lon_send_count      DW ?
lon_rec_count       DW ?

lon_send_head       DW ?
lon_rec_head        DW ?

lon_send_tail       DW ?
lon_rec_tail        DW ?

lon_send_size       DW ?
lon_rec_size        DW ?

lon_rec_buf         DW ?
lon_send_buf        DW ?

lon_struc	ENDS
