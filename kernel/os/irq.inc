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
; IRQ.INC
; Irq structures

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irq_struc	STRUC

user_data		    DW ?
user_handler	    DD ?,?

usage_section	    section_typ <>

irq_enable_proc     DD ?
irq_disable_proc    DD ?

irq_struc	ENDS

irq_proc_seg	STRUC

mask0			DB ?
mask1			DB ?

irq_proc_seg	ENDS

irq_sys_seg	STRUC

bad_irqs            DD ?

irq_detect_proc     DD ?

irq_arr			    DB 32 * SIZE irq_struc DUP(?)

irq_sys_seg	ENDS

share_handle_struc  STRUC

sh_user_handler DD ?,?
sh_user_data    DW ?

share_handle_struc  ENDS

MAX_SHARE   = 16

share_struc	STRUC

share_count     DW ?
share_handler   DB MAX_SHARE * SIZE share_handle_struc DUP(?)

share_struc ENDS

irq_ss		EQU 18
irq_esp		EQU 14
irq_eflags	EQU 10
irq_cs		EQU 6
irq_eip		EQU 2
irq_bp		EQU 0
