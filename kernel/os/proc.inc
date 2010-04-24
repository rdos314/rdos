;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2010, Leif Ekblad
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
; PROC.INC
; Processor struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PS_FLAG_PREEMPT     = 1
PS_FLAG_PRIO_CHANGE = 2
PS_FLAG_TIMER       = 4

timer_struc	STRUC

ps_timer_next		DW ?
ps_timer_id		    DW ?
ps_timer_lsb		DD ?
ps_timer_msb		DD ?
ps_timer_offset	    DW ?
ps_timer_sel		DW ?
ps_timer_owner		DW ?

timer_struc	ENDS

processor_seg   STRUC

ps_id               DW ?
ps_ss               DW ?
ps_sp               DW ?
ps_nesting          DW ?
ps_curr_thread      DW ?
ps_skip_thread      DW ?
ps_last_thread      DW ?
ps_flags            DW ?
ps_null_thread      DW ?
ps_apic             DD ?
ps_wait             DW ?
ps_mask             DD ?

ps_preempt_lsb      DD ?
ps_preempt_msb	    DD ?

ps_last_lsb         DD ?

ps_timer_head		DW ?
ps_timer_free		DW ?
ps_timer_entries    DB 256 * SIZE timer_struc DUP(?)

processor_seg   ENDS
