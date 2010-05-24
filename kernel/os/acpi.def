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
; ACPI.DEF
; ACPI types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

acpi_header STRUC

acpi_sign       DD ?
acpi_size       DD ?

acpi_rev        DB ?
acpi_sum        DB ?

acpi_oem        DB 6 DUP(?)
acpi_oem_id     DD ?, ?
acpi_oem_rev    DD ?
acpi_cr_id      DD ?
acpi_cr_rev     DD ?

acpi_header ENDS

acpi_table  STRUC

act_next        DW ?
act_size        DW ?
act_sign        DD ?
act_oem_id      DD ?, ?

acpi_table  ENDS
