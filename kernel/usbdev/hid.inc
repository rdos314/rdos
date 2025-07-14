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
; hid.inc
; shared hid definitions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; keep synchronized with hid.c!!

hid_device_struc   STRUC

hid_controller      DW ?
hid_port            DB ?

hid_interface       DB ?
hid_protocol        DB ?
hid_intr_in         DB ?
hid_device_handle   DW ?
hid_control_wait    DW ?
hid_intr_wait       DW ?
hid_intr_size       DW ?
hid_intr_buf        DW ?
hid_pipe_size       DW ?

hid_country_code    DB ?
hid_descr_count     DB ?

hid_stop_req        DD ?

hid_thread          DD ?

hid_device_struc   ENDS

hid_table       STRUC

; IN  FS:ESI    Report struct
; IN  GS:EBX    Device
; OUT BX        Handle / selector
hid_begin_proc              DD ?,?

; IN  BX        Handle / selector
; IN  SI        Entry #
; IN  CL        Usage Page
; IN  AL        Usage ID low
; IN  AH        Usage ID high
; IN  EDX       Item params
hid_define_proc             DD ?,?

; IN  BX        Handle / selector
; OUT NC        Handle active
hid_end_proc                DD ?,?

; IN  BX        Handle / selector
hid_close_proc              DD ?,?

; IN  BX        Handle / selector
; IN  FS:ESI    Report data
hid_handle_report_proc      DD ?,?

hid_table   ENDS
