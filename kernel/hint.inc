;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; HINT.INC
; Handle interfaces
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC_HANDLE_COUNT     = 64
PROC_BITMAP_COUNT     = PROC_HANDLE_COUNT SHR 5

handle_sys_interface    STRUC

hsi_blk                   blk_header <>

;  IN	DS                Handle sys interface
;  OUT  AX                Proc interface
hsi_create_proc_proc      DD ?,?

;  IN	DS                Handle sys interface
;  OUT  AX                Kernel interface
hsi_create_kernel_proc    DD ?,?

;  IN	DS                Handle sys interface
;  OUT  AX                Handle interface
hsi_create_handle_proc    DD ?,?

;  IN	DS                Handle sys interface
hsi_delete_proc           DD ?,?

hsi_index                 DD ?
hsi_section               section_typ <>

hsi_ref_count             DW ?

hsi_kernel_sel            DW ?
hsi_proc_bitmap           DD PROC_BITMAP_COUNT DUP(?)
hsi_proc_arr              DD PROC_HANDLE_COUNT DUP(?)
hsi_sel_arr               DW PROC_HANDLE_COUNT DUP(?)

handle_sys_interface    ENDS

handle_proc_interface    STRUC

;  IN	DS                Handle proc interface
;  IN   CX                Access
;  OUT  AX                Handle interface
hpi_create_proc           DD ?,?

;  IN	DS                Handle proc interface
hpi_delete_proc           DD ?,?

hpi_ref_count             DW ?
hpi_linear                DD ?
hpi_proc_linear           DD ?
hpi_index                 DD ?
hpi_sys_index             DD ?
hpi_sys_sel               DW ?

handle_proc_interface    ENDS

handle_entry_interface    STRUC

;  IN	DS                Handle entry interface
;  IN   CX                Access
;  OUT  AX                New interface
hei_dup_proc              DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EAX               Map index
;  OUT  EDI               Map linear address
hei_get_map_proc          DD ?,?

;  IN	DS                Handle entry interface
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  EAX               Read count
hei_poll_proc             DD ?,?

;  IN	DS                Handle entry interface
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  EAX               Read count
hei_read_proc             DD ?,?

;  IN	DS                Handle entry interface
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  EAX               Read count
hei_poll_proc             DD ?,?

;  IN	DS                Handle entry interface
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  EAX               Written count
hei_write_proc            DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Size
hei_get_size_proc         DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX:EAX           Size
hei_set_size_proc         DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Pos
hei_get_pos_proc          DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX:EAX           Pos
hei_set_pos_proc          DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Tics
hei_get_create_time_proc  DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Tics
hei_get_modify_time_proc  DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Tics
hei_get_access_time_proc  DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX:EAX           Tics
hei_set_modify_time_proc  DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EAX               -1 = error, 0 = not eof, 1 = eof
hei_is_eof_proc           DD ?,?

;  IN	DS                Handle entry interface
;  OUT  NC                Device
hei_is_device_proc        DD ?,?

;  IN	DS                Handle entry interface
;  OUT  NC                IP ver4
hei_is_ip4_proc           DD ?,?

;  IN	DS                Handle entry interface
;  OUT  ECX               Bytes in input buffer
hei_input_size_proc       DD ?,?

;  IN	DS                Handle entry interface
;  OUT  ECX               Available bytes in output buffer
hei_output_size_proc      DD ?,?

;  IN	DS                Handle entry interface
hei_delete_proc           DD ?,?

hei_ref_count             DW ?
hei_index                 DD ?
hei_proc_index            DD ?
hei_proc_sel              DW ?
hei_sys_index             DD ?
hei_sys_sel               DW ?

handle_entry_interface    ENDS

handle_kernel_interface    STRUC

;  IN	DS                Handle kernel interface
;  IN   EDX:EAX           Position
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  ECX               Read count
;  OUT  EDX:EAX           New position
hki_read_proc             DD ?,?

;  IN	DS                Handle kernel interface
;  IN   EDX:EAX           Position
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  ECX               Written count
;  OUT  EDX:EAX           New position
hki_write_proc            DD ?,?

;  IN	DS                Handle kernel interface
hki_delete_proc           DD ?,?

hki_ref_count             DW ?
hki_sys_index             DD ?
hki_sys_sel               DW ?

handle_kernel_interface    ENDS
