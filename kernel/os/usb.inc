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
; usb.INC
; usb common types & constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_USB_HUB_PORTS = 16

PID_IN = 69h
PID_OUT = 0E1h
PID_SETUP = 2Dh

MODE_CONTROL = 1
MODE_ISO = 2
MODE_INTR = 3
MODE_BULK = 4

usb_dev_struc   STRUC

; OUT FS        Pipe selector
create_control_proc	DD ?

; IN  CX        Size
; OUT ES:EDI    Buffer
allocate_buf_proc   DD ?

; IN  FS        Pipe selector
; OUT EDX       Queue handle
start_queue_proc    DD ?

; IN  FS        Pipe selector
; IN  CX        Size
; IN  ES:EDI    Data
; IN  EDX       Queue
add_setup_proc      DD ?

; IN  FS        Pipe selector
; IN  CX        Size
; IN  ES:EDI    Data
; IN  EDX       Queue
add_out_proc      DD ?

; IN  FS        Pipe selector
; IN  CX        Size
; IN  ES:EDI    Data
; IN  EDX       Queue
add_in_proc      DD ?

; IN  FS        Pipe selector
; IN  EDX       Queue
add_status_proc      DD ?

; IN  FS        Pipe selector
; IN  EDX       Queue
issue_transfer_proc      DD ?

usb_port_sel_arr    DW MAX_USB_HUB_PORTS DUP(?)
usb_addr_arr        DW 128 DUP(?)

usb_dev_struc   ENDS

usb_function_struc  STRUC

usbf_address        DB ?
usbf_port_sel_arr   DW MAX_USB_HUB_PORTS DUP(?)

usb_function_struc  ENDS

usb_pipe_struc      STRUC

usbp_function_sel   DW ?
usbp_address        DB ?
usbp_endpoint       DB ?
usbp_seq            DB ?
usbp_mode           DB ?
usbp_maxlen         DW ?

usb_pipe_struc      ENDS

usb_setup_data  STRUC

usd_type        DB ?
usd_req         DB ?
usd_value       DW ?
usd_index       DW ?
usd_len         DW ?

usb_setup_data  ENDS
