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
; cdc.inc
; CDC class structs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_CDC_UNITS =	16

FLAG_CDC_DISCONNECT = 2
FLAG_CDC_REINIT = 4

unit_struc      STRUC

unit_com_sel    DW ?

unit_in_size    DW ?
unit_out_size   DW ?

unit_bulk_in    DB ?
unit_bulk_out   DB ?

unit_interface  DB ?

unit_struc	ENDS

cdc_struc	STRUC

cdc_vendor              DW ?
cdc_product             DW ?
cdc_controller          DW ?
cdc_port                DB ?
cdc_device              DB ?

cdc_sub_class		DB ?
cdc_protocol            DB ?
cdc_abs_control_cap     DB ?

cdc_dev_handle          DW ?

cdc_dev_offset          DD ?
cdc_flags               DW ?

cdc_prev                DW ?
cdc_next                DW ?

cdc_detach              DW ?

cdc_unit_count          DB ?
cdc_unit_arr            DW MAX_CDC_UNITS DUP(?)

cdc_com_count           DB ?
cdc_com_arr             DW MAX_CDC_UNITS DUP(?)

cdc_dev_descr_size      DW ?
cdc_dev_descr_buf       DB ?

cdc_struc	ENDS
