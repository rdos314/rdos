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
; PRINTER.INC
; Device-independent printer class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

printer_struc	STRUC

pr_jammed_proc              DD ?,?

pr_paper_low_proc           DD ?,?

pr_paper_end_proc           DD ?,?

pr_cutter_jammed_proc       DD ?,?

pr_ok_proc                  DD ?,?

pr_head_lifted_proc         DD ?,?

pr_paper_in_presenter_proc  DD ?,?

pr_temp_error_proc          DD ?,?

pr_feed_error_proc          DD ?,?

pr_print_test_proc          DD ?,?

; IN  DX    Height
; OUT BX    Bitmap
pr_create_bitmap_proc       DD ?,?

; IN  BX    Bitmap
pr_print_bitmap_proc        DD ?,?

; IN  AX    Amount in mm
pr_present_media_proc       DD ?,?

pr_eject_media_proc         DD ?,?

pr_wait_for_print_proc      DD ?,?

; IN  ES:EDI    Name
pr_get_name_proc            DD ?,?

pr_reset_proc               DD ?,?

printer_device              DW ?

printer_struc	ENDS

