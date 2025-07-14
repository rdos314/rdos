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
; usb.INC
; usb common types & constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

USB_EVENT_ATTACH                = 1
USB_EVENT_DETACH                = 2
USB_EVENT_CONTROLLER_ERROR      = 3
USB_EVENT_CRC_ERROR             = 4
USB_EVENT_BIT_STUFFING_ERROR    = 5
USB_EVENT_DATA_TOGGLE_ERROR     = 6
USB_EVENT_STALL                 = 7
USB_EVENT_NOT_RESPONDING        = 8
USB_EVENT_PID_FAILURE           = 9
USB_EVENT_UNEXPECTED_PID        = 10
USB_EVENT_DATA_OVERRUN          = 11
USB_EVENT_DATA_UNDERRUN         = 12
USB_EVENT_BUFFER_OVERRUN        = 13
USB_EVENT_BUFFER_UNDERRUN       = 14 
USB_EVENT_DATA_BUFFER_ERROR     = 15
USB_EVENT_BABBLE                = 16
USB_EVENT_TRANS_ERROR           = 17
USB_EVENT_MISSED_MICROFRAME     = 18
USB_EVENT_HALTED                = 19
USB_EVENT_TRB_ERROR             = 20
USB_EVENT_UNKNOWN               = 21
USB_EVENT_BANDWIDTH_ERROR       = 22
USB_EVENT_NO_SLOTS              = 23
USB_EVENT_SLOT_NOT_ENABLED      = 24
USB_EVENT_PIPE_NOT_ENABLED      = 25
USB_EVENT_NO_PING               = 26
USB_EVENT_RESET                 = 27
USB_EVENT_OVER_CURRENT          = 28

usb_event       STRUC

ue_event        DW ?
ue_controller   DW ?
ue_port         DW ?
ue_pipe         DB ?

usb_event       ENDS

usb_setup_data  STRUC

usd_type        DB ?
usd_req         DB ?
usd_value       DW ?
usd_index       DW ?
usd_len         DW ?

usb_setup_data  ENDS

usb_device_descr	STRUC

udd_len		DB ?
udd_type	DB ?
udd_usb_ver	DW ?
udd_class	DB ?
udd_sub_class	DB ?
udd_proto	DB ?
udd_maxlen	DB ?
udd_vendor	DW ?
udd_prod	DW ?
udd_device	DW ?
udd_man		DB ?
udd_prodid	DB ?
udd_num		DB ?
udd_configs	DB ?

usb_device_descr	ENDS

usb_config_descr	STRUC

ucd_len	    		DB ?
ucd_type	    	DB ?
ucd_size		    DW ?
ucd_interface_count	DB ?
ucd_config_id		DB ?
ucd_config_str		DB ?
ucd_attrib  		DB ?
ucd_power	    	DB ?

usb_config_descr	ENDS

usb_endpoint_descr  STRUC

ued_len             DB ?
ued_type            DB ?
ued_address         DB ?
ued_attrib          DB ?
ued_maxsize         DW ?
ued_interval        DB ?

usb_endpoint_descr  ENDS

usb_interface_descr  STRUC

uid_len             DB ?
uid_type            DB ?
uid_id              DB ?
uid_alt_id          DB ?
uid_endpoints       DB ?
uid_class           DB ?
uid_sub_class       DB ?
uid_proto           DB ?
uid_interface_id    DB ?

usb_interface_descr  ENDS
