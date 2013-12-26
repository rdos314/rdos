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
