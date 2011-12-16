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
PS_FLAG_NMI         = 8
PS_FLAG_INIT_CLOCK  = 10h
PS_FLAG_ACTIVE      = 20h
PS_FLAG_FLUSH       = 40h
PS_FLAG_LOADING     = 80h
PS_FLAG_FPU         = 100h
PS_FLAG_HAS_TIMER   = 200h

processor_seg   STRUC

ps_ptab             DW 256 DUP(?)
ps_prio_act         DW ?

ps_wakeup_list      DW ?

ps_id               DW ?

ps_sel              DW ?

ps_ss               DW ?
ps_sp               DW ?

ps_nesting          DW ?
ps_curr_thread      DW ?
ps_last_thread      DW ?
ps_flags            DW ?
ps_null_thread      DW ?
ps_math_thread      DW ?

ps_apic             DD ?
ps_acpi             DB ?
ps_tlb_flush        DB ?

ps_preempt_lsb      DD ?
ps_preempt_msb	    DD ?

ps_last_lsb         DD ?

ps_tsc_guard        DD ?
ps_last_tsc         DD ?

ps_global_post_perc DB ?
ps_curr_post        DB ?

cs_irq              DD ?
cs_fault            DD ?

cs_cr0              DD ?
cs_cr2              DD ?
cs_cr3              DD ?
cs_cr4              DD ?

cs_dr0              DD ?
cs_dr1              DD ?
cs_dr2              DD ?
cs_dr3              DD ?
cs_dr7              DD ?

cs_eip              DD ?
cs_eflags           DD ?
cs_eax              DD ?
cs_ecx              DD ?
cs_edx              DD ?
cs_ebx              DD ?
cs_esp              DD ?
cs_ebp              DD ?
cs_esi              DD ?
cs_edi              DD ?

cs_es               DW ?
cs_cs               DW ?
cs_ss               DW ?
cs_ds               DW ?
cs_fs               DW ?
cs_gs               DW ?

cs_ldt              DW ?
cs_tr               DW ?
cs_gdtr             DD ?, ?
cs_idtr             DD ?, ?

cs_usel             DW ?
cs_uoffs            DD ?

processor_seg   ENDS
