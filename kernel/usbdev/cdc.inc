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
; cdc.inc
; CDC class structs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_CDC_UNITS =	16

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
cdc_device              DB ?

cdc_sub_class		DB ?
cdc_protocol            DB ?
cdc_abs_control_cap     DB ?

cdc_control_wait        DW ?
cdc_control_pipe        DW ?

cdc_thread              DW ?

cdc_com_dev_sel         DW ?

cdc_dev_offset          DD ?
cdc_flags               DW ?

cdc_unit_count          DB ?
cdc_unit_arr            DW MAX_CDC_UNITS DUP(?)

cdc_struc	ENDS
