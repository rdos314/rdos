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
; hub.INC
; Hub common types & constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HUB_BUF_SIZE    = 40h

FLAG_HUB_DISCONNECT     = 1
FLAG_HUB_REINIT         = 2
FLAG_HUB_OVER_CURRENT   = 4

usb_hub_descr   STRUC

uhd_len             DB ?
uhd_type            DB ?
uhd_ports           DB ?
uhd_info            DW ?
uhd_power_time  DB ?
uhd_current     DB ?

usb_hub_descr   ENDS

usb_hub_func_struc   STRUC

hub_func_base           usb_function_struc <>

hub_prev                DW ?
hub_next                DW ?

hub_server_thread       DW ?
hub_status_thread       DW ?
hub_port_thread         DW ?

hub_vendor              DW ?
hub_product             DW ?
hub_controller          DW ?
hub_port                DB ?
hub_address             DB ?

hub_device_handle       DW ?
hub_wait_handle         DW ?

hub_power_time          DW ?
hub_info                DW ?
hub_status_size         DW ?
hub_intr                DB ?
hub_flags               DB ?

hub_section             section_typ <>

hub_parent_sel          DW ?

hub_ports               DW ?
hub_status_arr          DW MAX_USB_HUB_PORTS DUP(?)
hub_adr_arr             DB MAX_USB_HUB_PORTS DUP(?)

hub_control_data        DB 8 DUP (?)
hub_buf                 DB HUB_BUF_SIZE DUP(?)

hub_dev_descr_size      DW ?
hub_dev_descr_buf       DB ?

usb_hub_func_struc   ENDS
