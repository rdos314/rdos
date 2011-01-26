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
; PRINTER.INC
; Device-independent printer class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

printer_struc	STRUC

pr_jammed_proc              DD ?

pr_paper_low_proc           DD ?

pr_paper_end_proc           DD ?

pr_ok_proc                  DD ?

pr_head_lifted_proc         DD ?

pr_paper_in_presenter_proc  DD ?

pr_print_test_proc          DD ?

; IN  DX    Height
; OUT BX    Bitmap
pr_create_bitmap_proc       DD ?

; IN  BX    Bitmap
pr_print_bitmap_proc        DD ?

; IN  AX    Amount in mm
pr_present_media_proc       DD ?

pr_eject_media_proc         DD ?

printer_device              DW ?

printer_struc	ENDS

