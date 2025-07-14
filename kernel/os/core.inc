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
; Core.inc
; Core struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CS_FLAG_PREEMPT        = 1
CS_FLAG_PRIO_CHANGE    = 2
CS_FLAG_TIMER_EXPIRED  = 4
CS_FLAG_NMI            = 8
CS_FLAG_INIT_CLOCK     = 10h
CS_FLAG_ACTIVE         = 20h
CS_FLAG_LOADING        = 80h
CS_FLAG_FPU            = 100h
CS_FLAG_P_STATE        = 200h
CS_FLAG_SHUTDOWN       = 400h
CS_FLAG_MOVE           = 800h
CS_FLAG_LONG_MODE      = 1000h
CS_FLAG_SAVED          = 2000h

timer_struc     STRUC

timer_next              DW ?
timer_sel               DW ?
timer_lsb               DD ?
timer_msb               DD ?
timer_offset    DD ?
timer_id                DD ?
timer_owner             DW ?

timer_struc     ENDS

core_tlb32_struc        STRUC

pt32_locked     DD ?
pt32_used       DD ?
pt32_linear_arr DD 32 DUP(?)

core_tlb32_struc        ENDS

CORE_TIMER_COUNT    = 242
MAX_IRQ_NESTING     = 64
CORE_LOG_ENTRIES    = 200h
CORE_WAKEUP_ENTRIES = 64
IPI_WAKEUP_ENTRIES = 64

core_seg   STRUC

cs_base_data            core_base_struc <>    ; this must be first!

cs_wakeup_count         DW ?
cs_ipi_wakeup_count     DW ?
cs_ipi_spinlock         spinlock_typ <>

cs_id                   DW ?
cs_processor            DW ?

cs_sched_count          DW ?
cs_log_count            DW ?
cs_log_sel              DW ?
cs_log_entry            DW ?

cs_stack_offset         DD ?
cs_stack_sel            DW ?
cs_flags                DD ?

cs_nesting              DW ?
cs_curr_thread          DW ?
cs_last_thread          DW ?
cs_null_thread          DW ?
cs_math_thread          DW ?

cs_gdt_base             DD ?
cs_gdt_size             DW ?

cs_apic                 DD ?
cs_acpi                 DB ?
cs_pad1                 DB ?

cs_dump_offset          DW ?

cs_preempt_lsb          DD ?
cs_preempt_msb          DD ?

cs_last_lsb             DD ?

; TSC timer support

cs_system_time          DD ?,?
cs_tsc_guard            DD ?
cs_last_tsc             DD ?

cs_lsb_tics             DD ?
cs_msb_tics             DD ?

cs_linear               DD ?
cs_syscall_esp          DD ?
cs_syscall_eip          DD ?
cs_tls_linear           DD ?,?

cs_long_tr              DW ?
cs_long_ldt             DW ?
cs_tr_linear            DD ?

; these four bytes must be in this order!!

cs_curr_irq_nr          DB ?
cs_curr_irq_count       DB ?
cs_curr_irq_retries     DB ?
cs_curr_irq_spare       DB ?

cs_nested_irq_count     DW ?
cs_nested_irq_stack     DD MAX_IRQ_NESTING DUP(?)

cs_wakeup_arr           DW CORE_WAKEUP_ENTRIES DUP(?)
cs_ipi_wakeup_arr       DW IPI_WAKEUP_ENTRIES DUP(?)

cs_irq_count            DW ?
cs_irq_stack            DB MAX_IRQ_NESTING DUP(?)

cs_serv_sel             DW ?
cs_cr3                  DD ?
cs_mon_linear           DD ?
cs_tlb                  core_tlb32_struc <>
cs_work_tlb             core_tlb32_struc <>

cs_irq_arr_counter      DD 256 DUP(?)

cs_timer_spinlock       DW ?
cs_timer_head           DW ?
cs_timer_free           DW ?
cs_timer_entries        DB CORE_TIMER_COUNT * SIZE timer_struc DUP(?)

core_seg   ENDS

; FS        Core selector
NotifyIrqActivity   Macro
    inc fs:cs_curr_irq_count
    Endm
    
