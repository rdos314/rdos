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
; usbdev.INC
; usbdev common types & constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_USB_HUB_PORTS = 32

FLAG_DETACHED  = 1

PID_IN = 69h
PID_OUT = 0E1h
PID_SETUP = 2Dh

MODE_CONTROL = 1
MODE_ISO = 2
MODE_INTR = 3
MODE_BULK = 4

DIR_IN = 80h
DIR_OUT = 0

USBF_XHCI   = 1

USB_PIPE_FLAG_ENABLED = 1

usb_function_struc   STRUC

; OUT AL        Address
allocate_address_proc DD ?,?

; IN  AL        Address
free_address_proc     DD ?,?

; IN  AL        Address
; IN  AH        Speed
; IN  BX        Hub selector
; IN  DX        Port
; OUT ES        Device sel
create_dev_proc       DD ?,?

; IN  ES        Device sel
create_control_proc	DD ?,?

; IN  ES        Device sel
change_address_proc      DD ?,?

; IN  ES        Device selector
reset_dev_proc        DD ?,?

;  IN  ES       Device selector
;  IN  AL       Address
address_device_proc	DD ?,?

; IN  FS        Pipe selector
; IN  CX        Hub sel
; IN  DL        Configuration #
config_device_proc	DD ?,?

; IN  ES        Device selector
; IN  AL        Max len
update_control_maxlen_proc        DD ?,?

;  IN ES        Device
is_dev_connected_proc      DD ?,?

; IN  ES        Device
; IN  GS:EDI    Buffer
; OUT CX        Actual size
control_msg_proc      DD ?,?

; IN  ES        Device
; IN  CX        Buffer count
; IN  DL        Pipe #
; OUT BX        Pipe sel
create_bulk_pipe_proc      DD ?,?

; IN  ES        Device
; IN  CX        Buffer count
; IN  DL        Pipe #
; IN  DH        Interval
; OUT BX        Pipe sel
create_intr_pipe_proc      DD ?,?

;  IN ES        Device
unlink_proc      DD ?,?

;  IN ES        Device
;  IN GS        Pipe sel
enable_pipe_proc      DD ?,?

;  IN ES        Device
;  IN GS        Pipe sel
disable_pipe_proc      DD ?,?

;  IN  ES        Device
;  IN  GS        Pipe sel
;  OUT CX        Used buffer count
used_buffers_proc      DD ?,?

;  IN  ES        Device
;  IN  GS        Pipe sel
;  OUT CX        Free buffer count
free_buffers_proc      DD ?,?

;  IN  ES        Device
;  IN  GS        Pipe sel
;  OUT EDX       Buffer linear
;  OUT CX        Size
req_buffer_proc      DD ?,?

;  IN  ES        Device
;  IN  GS        Pipe sel
;  IN  CX        Size
rel_buffer_proc      DD ?,?

usb_section            section_typ <>
usb_addr_section       section_typ <>

usb_controller_id      DW ?
usb_hub_id             DB ?
usb_route_depth        DB ?
usb_fresv              DB ?
usb_root_port          DB ?
usb_route_str          DD ?
usb_addr_bitmap        DD 4 DUP(?)
usb_handle_arr         DW MAX_USB_HUB_PORTS DUP(?)
usb_thread_arr         DW MAX_USB_HUB_PORTS DUP(?)
usb_dev_arr            DW MAX_USB_HUB_PORTS DUP(?)

usb_function_struc   ENDS

usb_device_struc  STRUC

usbd_mem_blk            mem_blk_header <>

usbd_func_sel           DW ?
usbd_hub_sel            DW ?
usbd_dev_sel            DW ?
usbd_maxlen             DW ?
usbd_port               DB ?
usbd_address            DB ?
usbd_speed              DB ?
usbd_flags              DB ?
usbd_curr_config        DW ?

usbd_in_pipe_arr        DW 15 DUP(?)
usbd_out_pipe_arr       DW 15 DUP(?)

usbd_section            section_typ <>

usbd_control_buf        DB 8 DUP(?)
usbd_temp_buf           DB 8 DUP(?)
usbd_device_descr       DB 18 DUP(?)
usbd_config_sel         DW 16 DUP(?)

usb_device_struc  ENDS

usb_device_pipe_struc    STRUC

usbdp_descr        usb_endpoint_descr <>
usbdp_flags        DB ?
usbdp_wait         DW ?

usb_device_pipe_struc   ENDS
