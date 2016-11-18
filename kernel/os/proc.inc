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

PS_FLAG_PREEMPT        = 1
PS_FLAG_PRIO_CHANGE    = 2
PS_FLAG_TIMER_EXPIRED  = 4
PS_FLAG_NMI            = 8
PS_FLAG_INIT_CLOCK     = 10h
PS_FLAG_ACTIVE         = 20h
PS_FLAG_LOADING        = 80h
PS_FLAG_FPU            = 100h
PS_FLAG_P_STATE        = 200h
PS_FLAG_SHUTDOWN       = 400h
PS_FLAG_MOVE           = 800h
PS_FLAG_LONG_MODE      = 1000h
PS_FLAG_SAVED          = 2000h

timer_struc     STRUC

timer_next              DW ?
timer_sel               DW ?
timer_lsb               DD ?
timer_msb               DD ?
timer_offset    DD ?
timer_id                DD ?
timer_owner             DW ?

timer_struc     ENDS

PROC_LOG_ENTRIES    = 200h

; should always be 16 bytes!

proc_log_struc  STRUC

pls_time        DD ?,?
pls_type        DW ?
pls_proc        DW ?
pls_data        DD ?

proc_log_struc  ENDS

proc_tlb32_struc        STRUC

pt32_locked     DD ?
pt32_used       DD ?
pt32_linear_arr DD 32 DUP(?)

proc_tlb32_struc        ENDS

processor_seg   STRUC

ps_ptab             DW 256 DUP(?)
ps_prio_act         DW ?

ps_wakeup_list      DW ?

ps_id               DW ?

ps_sel              DW ?

ps_sched_count      DW ?
ps_log_count        DW ?
ps_log_sel          DW ?
ps_log_entry        DW ?

ps_stack_offset     DD ?
ps_stack_sel        DW ?
ps_flags            DD ?

ps_nesting          DW ?
ps_curr_thread      DW ?
ps_last_thread      DW ?
ps_null_thread      DW ?
ps_math_thread      DW ?

ps_gdt_base         DD ?
ps_gdt_size         DW ?

ps_apic             DD ?
ps_acpi             DB ?

ps_dump_offset      DW ?

ps_preempt_lsb      DD ?
ps_preempt_msb      DD ?

ps_last_lsb         DD ?

; TSC timer support

ps_system_time      DD ?,?
ps_tsc_guard        DD ?
ps_last_tsc         DD ?

ps_clock_tics       DW ?  ; not used

ps_lsb_tics         DD ?
ps_msb_tics         DD ?

ps_wakeup_spinlock  DW ?

ps_linear           DD ?
ps_syscall_esp      DD ?
ps_syscall_eip      DD ?
ps_tls_linear       DD ?,?

ps_long_tr          DW ?
ps_long_ldt         DW ?
ps_tr_linear        DD ?

ps_cr3              DD ?
ps_tlb              proc_tlb32_struc <>
ps_work_tlb         proc_tlb32_struc <>

ps_timer_spinlock   DW ?
ps_timer_head           DW ?
ps_timer_free           DW ?
ps_timer_entries    DB 256 * SIZE timer_struc DUP(?)

processor_seg   ENDS

; FS        Core selector
NotifyIrqActivity   Macro
    Endm
    
