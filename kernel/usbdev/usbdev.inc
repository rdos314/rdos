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
; usbdev.INC
; usbdev common types & constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_USB_HUB_PORTS = 32
MAX_USB_SCATTER_COUNT = 32

DEV_FLAG_DETACHED       = 1
DEV_FLAG_ATTACHED       = 2
DEV_FLAG_FAULT          = 4
DEV_FLAG_CONTROL_ACTIVE = 8

PIPE_FLAG_ACTIVE        = 1
PIPE_FLAG_FAULT         = 2

usb_function_struc   STRUC

lock_proc                  DD ?,?

unlock_proc                DD ?,?

; IN  DL        Port
; OUT AL        Speed
power_off_port_proc        DD ?,?

; IN  DL        Port
; OUT AL        Speed
power_on_port_proc         DD ?,?

; IN  DL        Port
; OUT AL        Speed
reset_port_proc            DD ?,?

; IN  DL        Port
disable_port_proc          DD ?,?

; IN  ES        Device
disable_device_proc        DD ?,?

; IN  DL        Port
is_port_connected_proc     DD ?,?

is_running_proc            DD ?,?

; OUT AL        Address
allocate_address_proc      DD ?,?

; IN  AL        Address
free_address_proc          DD ?,?

; OUT ES        Device sel
create_dev_proc            DD ?,?

; IN ES        Device
unlink_proc                DD ?,?

; IN ES        Device
is_dev_connected_proc      DD ?,?

; IN  ES        Device
free_dev_proc              DD ?,?

; IN  ES        Device sel
create_control_proc        DD ?,?

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

;  IN  ES       Device selector
;  IN  AL       Address
address_device_proc        DD ?,?

; IN  ES        Device sel
change_address_proc        DD ?,?

; IN  ES        Device selector
; IN  AL        Max len
update_control_maxlen_proc DD ?,?

; IN  ES        Device
; IN  GS:EDI    Buffer
; OUT CX        Actual size
control_msg_proc           DD ?,?

; IN  ES        Device
; IN  CX        Hub sel
; IN  DL        Configuration #
config_device_proc	   DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
; IN  CX        Packet count
; OUT BX        Packet sel
open_packet_proc          DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
; IN  BX        Packet sel
close_packet_proc          DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
start_packet_proc          DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
; OUT EDX       Buffer linear
; OUT CX        Size
req_packet_proc            DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
rel_packet_proc            DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
; IN  CX        Buffer size
; OUT BX        Raw sel
open_raw_proc          DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
; IN  BX        Raw sel
close_raw_proc          DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
; IN  CX        Size
read_raw_proc              DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
; IN  CX        Size
write_raw_proc              DD ?,?

; IN  ES        Device
; IN  GS        Pipe sel
; OUT CX        Actual size
finish_raw_proc              DD ?,?

usb_section            section_typ <>
usb_addr_section       section_typ <>

usb_controller_id      DW ?
usb_hub_id             DB ?
usb_route_depth        DB ?
usb_fresv              DB ?
usb_root_port          DB ?
usb_route_str          DD ?
usb_addr_bitmap        DD 4 DUP(?)
usb_reset_bitmap       DD ?
usb_oc_bitmap          DD ?
usb_handle_arr         DW MAX_USB_HUB_PORTS DUP(?)
usb_thread_arr         DW MAX_USB_HUB_PORTS DUP(?)
usb_dev_arr            DW MAX_USB_HUB_PORTS DUP(?)

usb_function_struc   ENDS

usb_device_struc  STRUC

usbd_mem_blk            mem_blk_header <>

usbd_func_sel           DW ?
usbd_parent_hub         DW ?
usbd_parent_thread      DW ?
usbd_my_hub             DW ?
usbd_dev_sel            DW ?
usbd_thread             DW ?
usbd_wait_dev           DW ?
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

usb_pipe_struc    STRUC

usbp_descr        usb_endpoint_descr <>
usbp_flags        DB ?

usbp_wait         DW ?
usbp_packet_sel   DW ?
usbp_raw_sel      DW ?

usb_pipe_struc   ENDS

usb_packet_struc     STRUC

usbpk_section        section_typ <>
usbpk_entry_count    DW ?
usbpk_rd_ptr         DW ?
usbpk_wr_ptr         DW ?
usbpk_tail_ptr       DW ?

usb_packet_struc     ENDS

usb_raw_struc  STRUC

usbr_buf_size     DW ?
usbr_buf_linear   DD ?
usbr_buf_sel      DW ?
usbr_wait_dev     DW ?
usbr_timeout      DD ?
usbr_name         DB 12 DUP(?)

usb_raw_struc  ENDS

usb_scatter_entry  STRUC

usbe_phys         DD ?,?
usbe_size         DD ?
usbe_td           DD ?

usb_scatter_entry  ENDS

usb_scatter_struc  STRUC

usbsc_thread      DW ?
usbsc_count       DW ?

usbsc_arr         DD 4 * MAX_USB_SCATTER_COUNT DUP(?)

usb_scatter_struc  ENDS
