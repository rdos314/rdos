;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2013, Leif Ekblad
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
; hub.INC
; Hub common types & constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HUB_BUF_SIZE    = 40h
MAX_HUB_PORTS   = 16

usb_hub_descr   STRUC

uhd_len             DB ?
uhd_type            DB ?
uhd_ports           DB ?
uhd_info            DW ?
uhd_power_time  DB ?
uhd_current     DB ?

usb_hub_descr   ENDS

; must be less than 4 bytes!

hub_port_status STRUC

hps_status      DW ?
hps_dev_port    DB ?

hub_port_status ENDS

hub_struc   STRUC

hub_next            DW ?

hub_thread          DW ?
hub_attached        DW ?

hub_controller      DW ?
hub_device          DB ?
hub_intr            DB ?

hub_control_wait    DW ?
hub_control_handle  DW ?

hub_status_handle   DW ?
hub_status_size     DW ?
hub_status_sel      DW ?
hub_status_req      DW ?

hub_power_time      DW ?
hub_info            DW ?

hub_dev_sel         DW ?

hub_ports           DW ?
hub_port_arr        DD MAX_HUB_PORTS DUP(?)

hub_control_data    DB 8 DUP (?)
hub_buf             DB HUB_BUF_SIZE DUP(?)

hub_struc   ENDS
