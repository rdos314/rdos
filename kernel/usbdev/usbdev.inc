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

MAX_USB_HUB_PORTS = 16

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

usb_dev_struc   STRUC

; IN  AH        Speed
; OUT FS        Pipe selector
create_control_proc	DD ?,?

; IN  AH        Speed
; OUT FS        Pipe selector
create_bulk_proc	DD ?,?

; IN  AL        Interval
; IN  AH        Speed
; IN  DL        Pipe #
; IN  CX        Max packet size
; OUT FS        Pipe selector
create_interrupt_proc	DD ?,?

; IN  FS        Pipe selector
; IN  CX        Size
; IN  ES:EDI    Data
add_setup_proc      DD ?,?

; IN  FS        Pipe selector
; IN  CX        Size
; IN  ES:EDI    Data
add_out_proc      DD ?,?

; IN  FS        Pipe selector
; IN  CX        Buffer size
; IN  ES:EDI    Buffer
add_in_proc      DD ?,?

; IN  FS        Pipe selector
add_status_out_proc      DD ?,?

; IN  FS        Pipe selector
add_status_in_proc      DD ?,?

; IN  FS        Pipe selector
issue_transfer_proc      DD ?,?

;  IN FS        Is request ready?
is_transfer_done_proc      DD ?,?

; IN  FS        Pipe selector
end_transfer_proc      DD ?,?

; IN  FS        Pipe selector
; OUT NC        Transaction ok
was_transfer_ok_proc      DD ?,?

; IN  FS        Pipe selector
; OUT CX        Returned size
get_data_size_proc      DD ?,?

; IN  FS        Pipe selector
close_pipe_proc     DD ?,?

; IN  FS        Pipe selector
wait_for_completion_proc      DD ?,?

; IN  FS        Pipe selector
change_address_proc      DD ?,?

;  IN FS        Is connected?
is_connected_proc      DD ?,?

; IN  FS        Pipe selector
reset_pipe_proc        DD ?,?

obs_lock_enum_proc         DD ?,?

obs_unlock_enum_proc       DD ?,?

; IN  GS        Hub selector
; IN  DX        Hub port
; OUT AL        Port
allocate_hub_port_proc DD ?,?

; IN  GS        Hub selector
; IN  AL        Port
free_hub_port_proc     DD ?,?

has_64bit_proc         DD ?,?

;  IN FS        Is stalled?
is_stalled_proc      DD ?,?

;  IN FS        Clear stalled
clear_stalled_proc      DD ?,?

; OUT AL        Maxlen
get_max_len_proc        DD ?,?

; IN  FS        Pipe selector
address_device_proc	DD ?,?

; IN  FS        Pipe selector
config_device_proc	DD ?,?

; IN  FS        Pipe selector
; IN  AL        Max len
set_max_len_proc        DD ?,?

; IN  FS        Control pipe selector
close_control_pipe_proc DD ?,?

; IN  FS        Pipe selector
issue_one_proc       DD ?,?

usb_section            section_typ <>

usb_controller_id      DW ?
usb_port_arr           DW MAX_USB_HUB_PORTS DUP(?)
usb_attach_thread_arr  DW MAX_USB_HUB_PORTS DUP(?)
usb_detach_thread_arr  DW MAX_USB_HUB_PORTS DUP(?)
usb_reset_thread_arr   DW MAX_USB_HUB_PORTS DUP(?)
usb_retry_arr          DW MAX_USB_HUB_PORTS DUP(?)
usb_timeout_arr        DD MAX_USB_HUB_PORTS DUP(?,?)
usb_addr_arr           DW 128 DUP(?)

usb_dev_struc   ENDS

usb_function_struc  STRUC

usbf_port               DB ?
usbf_slot               DB ?
usbf_address            DB ?
usbf_speed              DB ?
usbf_port_sel_arr       DW MAX_USB_HUB_PORTS DUP(?)
usbf_in_endpoint_arr    DW 16 DUP(?)
usbf_out_endpoint_arr   DW 16 DUP(?)

usb_function_struc  ENDS

usb_pipe_struc      STRUC

usbp_function_sel   DW ?
usbp_address        DB ?
usbp_endpoint       DB ?
usbp_seq            DB ?
usbp_mode           DB ?
usbp_dir            DB ?
usbp_speed          DB ?
usbp_maxlen         DW ?
usbp_section        section_typ <>
usbp_device_sel     DW ?
usbp_hub_sel        DW ?
usbp_hub_port       DW ?
usbp_signal         DW ?
usbp_wait           DW ?
usbp_config_sel     DW 16 DUP(?)

usb_pipe_struc   ENDS

usb_port_struc  STRUC

usb_function_sel    DW ?
usb_sync_section    section_typ <>
usb_in_pipe_arr     DW 16 DUP(?)
usb_out_pipe_arr    DW 16 DUP(?)
usb_port            DB ?
usb_configured      DB ?

usb_port_struc  ENDS

usb_user_pipe_struc     STRUC

usbu_func_sel       DW ?
usbu_port_sel       DW ?
usbu_pipe_sel       DW ?
usbu_data_list      DW ?
usbu_section        section_typ <>
usbu_copy           DB ?
usbu_pipe           DB ?
usbu_deleted        DB ?

usb_user_pipe_struc     ENDS
