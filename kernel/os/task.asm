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
; TASK.ASM
; Scheduling and thread handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE port.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE proc.inc
INCLUDE ..\handle.inc

section_handle_seg          STRUC

us_base     handle_header <>

us_value    DW ?
us_list     DW ?
us_owner    DW ?
us_count    DW ?

section_handle_seg          ENDS


task_seg    STRUC

ptab            DW 256 DUP(?)

prio_act            DW ?

help_call_ip    DW ?
help_call_cs    DW ?

init_clock_proc     DW ?
update_clock_proc   DW ?

tsc_sub_tics    DD ?
tsc_guard       DD ?
last_tsc        DD ?

clock_tics          DW ?
system_time         DD ?,?
time_diff           DD ?,?

apic_mul_tics       DD ?
apic_mul_rest       DW ?

update_tics         DD ?

signal_list         DW ?
has_signal      DB ?
has_list        DB ?
has_term        DB ?
owner_wait      DB ?

wakeup_list     DW ?
term_thread_list    DW ?
term_proc_list      DW ?

system_thread       DW ?

owner_sel       DW ?
owner_lock      DW ?
list_lock       DW ?

try_lock_proc       DW ?
lock_proc       DW ?
unlock_proc     DW ?
load_unlock_proc    DW ?

lock_list_proc      DW ?
unlock_list_proc    DW ?

get_cpu_proc    DD ?

processor_preempt   DD ?

processor_count     DW ?
processor_arr       DW 32 DUP(?)

task_seg_size       DB ?

task_seg    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

LocalGetSystemTime      MACRO
    mov eax,ds:system_time
    mov edx,ds:system_time+4
                    ENDM

LocalRemoveTimer    MACRO
    local timer_return

    cli
    mov bx,fs:ps_timer_head
    mov ax,fs:[bx].ps_timer_next
    mov fs:ps_timer_head,ax
    sti
    mov cx,fs:[bx].ps_timer_id
    mov eax,fs:[bx].ps_timer_lsb
    mov edx,fs:[bx].ps_timer_msb    
    push es
    push fs
    push bx
    push cs
    push OFFSET timer_return    
    push dword ptr fs:[bx].ps_timer_offset
    xor bx,bx
    mov ds,bx
    mov es,bx
    retf

timer_return:
    pop bx
    pop fs
    pop es
    mov ax,task_sel
    mov ds,ax
    cli
    mov ax,fs:ps_timer_free
    mov fs:[bx].ps_timer_next,ax
    mov fs:ps_timer_free,bx
    sti
                    ENDM

LocalStartTimer MACRO
    LOCAL start_try_next
    LOCAL start_insert
    mov si,fs:ps_timer_free
    mov fs:[si].ps_timer_owner,bx
    mov bx,fs:[si].ps_timer_next
    mov fs:ps_timer_free,bx
    mov fs:[si].ps_timer_lsb,eax
    mov fs:[si].ps_timer_msb,edx
    mov fs:[si].ps_timer_id,cx
    mov fs:[si].ps_timer_offset,di
    mov fs:[si].ps_timer_sel,es
    mov bx,OFFSET ps_timer_head
    push si
start_try_next:
    mov si,bx
    mov bx,fs:[bx].ps_timer_next
    cmp edx,fs:[bx].ps_timer_msb
    jc start_insert
    jnz start_try_next
    cmp eax,fs:[bx].ps_timer_lsb
    jnc start_try_next
start_insert:
    pop fs:[si].ps_timer_next
    mov si,fs:[si].ps_timer_next
    mov fs:[si].ps_timer_next,bx
                ENDM

LocalStopTimer  MACRO
    LOCAL timer_stop_next
    LOCAL timer_stop_this
    LOCAL timer_stop_done
    mov cx,bx
    mov bx,OFFSET ps_timer_head
timer_stop_next:
    mov si,bx
    mov bx,fs:[bx].ps_timer_next
    or bx,bx
    je timer_stop_done
    cmp cx,fs:[bx].ps_timer_owner
    jne timer_stop_next
timer_stop_this:
    mov ax,fs:[bx].ps_timer_next
    mov fs:[si].ps_timer_next,ax
    mov ax,fs:ps_timer_free
    mov fs:[bx].ps_timer_next,ax
    mov fs:ps_timer_free,bx
timer_stop_done:
                ENDM

;       ds:di   list
;       es          block

InsertBlock     MACRO
    LOCAL ins_empty
    LOCAL ins_done
    mov es:p_sleep_sel,ds
    mov word ptr es:p_sleep_offset,di
    mov word ptr es:p_sleep_offset+2,0
    push di
    mov di,[di]
    or di,di
    je ins_empty
    push ds
    push si
    mov ds,di
    mov si,ds:p_prev
    mov ds:p_prev,es
    mov ds,si
    mov ds:p_next,es
    mov es:p_next,di
    mov es:p_prev,si
    pop si
    pop ds
    pop di
    jmp ins_done
ins_empty:
    mov es:p_next,es
    mov es:p_prev,es
    pop di
    mov [di],es
ins_done:
        ENDM

;       ds:di   list
;       es          block

InsertFirst     MACRO
    LOCAL ins_empty
    LOCAL ins_done
    mov es:p_sleep_sel,ds
    mov word ptr es:p_sleep_offset,di
    mov word ptr es:p_sleep_offset+2,0
    push di
    mov di,[di]
    or di,di
    je ins_empty
    push ds
    push si
    mov ds,di
    mov si,ds:p_prev
    mov ds:p_prev,es
    mov ds,si
    mov ds:p_next,es
    mov es:p_next,di
    mov es:p_prev,si
    pop si
    pop ds
    pop di
    jmp ins_done
ins_empty:
    mov es:p_next,es
    mov es:p_prev,es
    pop di
ins_done:
    mov [di],es
        ENDM

;       ds:si       list
;       es              block

RemoveBlock     MACRO
    LOCAL rem_done
    push si
    mov es,[si]
    push di
    push ds
    mov di,es:p_next
    cmp di,[si]
    mov [si],di
    mov si,es:p_prev
    mov ds,di
    mov ds:p_prev,si
    mov ds,si
    mov ds:p_next,di
    pop ds
    pop di
    pop si
    jne rem_done
    mov word ptr [si],0
rem_done:
        ENDM
        
InsertBlock32   MACRO
    LOCAL ins_empty
    LOCAL ins_done
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi
    push di
    mov di,[edi]
    or di,di
    je ins_empty
    push ds
    push si
    mov ds,di
    mov si,ds:p_prev
    mov ds:p_prev,es
    mov ds,si
    mov ds:p_next,es
    mov es:p_next,di
    mov es:p_prev,si
    pop si
    pop ds
    pop di
    jmp ins_done
ins_empty:
    mov es:p_next,es
    mov es:p_prev,es
    pop di
    mov [edi],es
ins_done:
        ENDM

RemoveBlock32   MACRO
    LOCAL rem_done
    push esi
    mov es,[esi]
    push di
    push ds
    mov di,es:p_next
    cmp di,[esi]
    mov [esi],di
    mov si,es:p_prev
    mov ds,di
    mov ds:p_prev,si
    mov ds,si
    mov ds:p_next,di
    pop ds
    pop di
    pop esi
    jne rem_done
    mov word ptr [esi],0
rem_done:
        ENDM

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitPitClock
;
;           DESCRIPTION:    Init clock using PIT timer 2
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPitClock    Proc near
    push ds
    push ax
;
    mov ax,task_sel
    mov ds,ax
;    
    mov al,0B4h
    out TIMER_CONTROL,al
    jmp short $+2
    mov al,0
    out TIMER2,al
    jmp short $+2
    out TIMER2,al
    mov ds:clock_tics,0
    jmp short $+2
    mov al,0Dh
    out 61h,al
;
    pop ax
    pop ds      
    ret
InitPitClock    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UpdatePitClock
;
;           DESCRIPTION:    Update clock using PIT timer 2
;
;           PARAMETERS:         ES      Current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePitClock  Proc near
    mov al,80h
    out TIMER_CONTROL,al
    jmp short $+2
    in al,TIMER2
    mov ah,al
    jmp short $+2
    in al,TIMER2
    xchg al,ah
    mov dx,ax
    xchg ax,ds:clock_tics
    sub ax,dx
    movzx eax,ax
    add ds:system_time,eax
    adc ds:system_time+4,0
    ret
UpdatePitClock  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitTscClock
;
;           DESCRIPTION:    Init clock using TSC
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTscClock    Proc near
    push es
    pushad
;    
    mov ax,system_data_sel
    mov es,ax
    mov edx,10000h
    xor eax,eax
    mov ecx,es:tsc_tics
    shl ecx,16
    mov cx,es:tsc_rest
    div ecx
    mov ds:tsc_sub_tics,eax
;    
    rdtsc
    mov ds:last_tsc,eax
    mov ds:tsc_guard,0
;
    popad
    pop es      
    ret
InitTscClock    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UpdateTscClock
;
;           DESCRIPTION:    Update clock using TSC
;
;           PARAMETERS:         ES      Current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateTscClock  Proc near
    rdtsc
    mov edx,ds:last_tsc
    mov ds:last_tsc,eax
    sub eax,edx
    mul ds:tsc_sub_tics
    add ds:tsc_guard,eax
    adc ds:system_time,edx
    adc ds:system_time+4,0
    ret
UpdateTscClock  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartSysTimer
;
;           DESCRIPTION:    Start PIT timer
;
;           RETURNS:        EAX      Update tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_pit_timer_name    DB 'Start Pit Timer', 0

start_pit_timer    Proc far
    mov ax,task_sel
    mov ds,ax
    push es
    xor ax,ax
    mov es,ax
;    
    mov ax,30h
    out TIMER_CONTROL,al
;
    mov ax,100h
    cli
    out TIMER0,al
    xchg ah,al
    jmp short $+2
    out TIMER0,al
    call ds:update_clock_proc
    LocalGetSystemTime
    xor al,al
    out TIMER_CONTROL,al
    jmp short $+2
    in al,TIMER0
    mov ah,al
    jmp short $+2
    in al,TIMER0
    xchg al,ah
    neg ax
    add ax,100h
    movzx eax,ax
    add eax,eax
    add eax,eax
;
    push eax
    in al,INT0_MASK
    and al,NOT 1
    out INT0_MASK,al
    pop eax
;       
    pop es
    ret
start_pit_timer    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReloadSysTimer
;
;           DESCRIPTION:    Reload PIT timer
;
;           PARAMETERS:         AX      Reload count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reload_pit_timer_name    DB 'Reload Pit Timer', 0

reload_pit_timer    Proc far
    out TIMER0,al
    xchg al,ah
    jmp short $+2
    out TIMER0,al
;
    in al,INT0_MASK
    and al,NOT 1
    out INT0_MASK,al
    ret
reload_pit_timer  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReloadApicTimer
;
;           DESCRIPTION:    Reload APIC timer
;
;           PARAMETERS:         DS      Task sel
;               AX      Reload count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReloadApicTimer Proc near
    push es
    mov ecx,ds:apic_mul_tics
    shl ecx,16
    mov cx,ds:apic_mul_rest
    shl eax,16
    mul ecx
    inc edx
    mov ax,apic_mem_sel
    mov es,ax    
    mov es:APIC_INIT_COUNT,edx
    pop es
    ret
ReloadApicTimer  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           NotifyTimeDrift
;
;           DESCRIPTION:    Notification of time drift
;
;           PARAMETERS:         DS      System data sel
;               EAX     Drift in tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_time_drift_name  DB 'Notify Time Drift',0

MAX_DRIFT = 250000

notify_time_drift       Proc far
    push es
    push eax
    push ecx
    push edx
;    
    mov cx,task_sel
    mov es,cx
;
    sub es:time_diff,eax
    sbb es:time_diff,0
;    
    mov ecx,ds:tsc_tics
    or ecx,ecx
    jz ntdPit
;
;    cmp eax,MAX_DRIFT
;    jge ntdSetPit
;
;    cmp eax,-MAX_DRIFT
;    jle ntdSetPit
;
    mov ecx,es:tsc_sub_tics
    shr ecx,3
    imul ecx
;
    mov ecx,1193182
    idiv ecx
;    
    sub es:tsc_sub_tics,eax
    jmp ntdDone

ntdSetPit:
    mov ds:tsc_tics,0
    and ds:cpu_feature_flags, NOT 10h
    call InitPitClock
    mov es:update_clock_proc,OFFSET UpdatePitClock
    jmp ntdDone

ntdPit:

ntdDone:
    pop edx
    pop ecx
    pop eax
    pop es
    ret
notify_time_drift  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           TlbFlush386
;
;           DESCRIPTION:    TLB flush, 386 version
;
;           PARAMETERS:         EDX     Linear base
;               ECX     Page entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
TlbFlush386 Proc far
    push eax
    mov eax,cr3
    mov cr3,eax
    pop eax
    ret
TlbFlush386 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           TlbFlush486
;
;           DESCRIPTION:    TLB flush, 486 or higher version
;
;           PARAMETERS:         EDX     Linear base
;               ECX     Page entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IFNDEF __WASM__
 .486p
ENDIF

TlbFlush486 Proc far
    push ecx
    push edx
;
    or ecx,ecx
    jz tfDone

tfLoop:
    invlpg [edx]
    add edx,1000h
    loop tfLoop    

tfDone:    
    pop edx
    pop ecx
    ret
TlbFlush486 Endp

IFNDEF __WASM__
 .386p
ENDIF
 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_TASK
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task

    extrn allocate_fixed_system_mem:near
    extrn allocate_fixed_process_mem:near

init_task       PROC near
    pusha
    push ds
;
    mov ax,system_data_sel
    mov ds,ax
    mov word ptr ds:tlb_flush_proc+2,cs
    mov word ptr ds:tlb_flush_proc,OFFSET TlbFlush386
    mov al,ds:cpu_type
    cmp al,3
    je init_tlb_done
;
;    mov word ptr ds:tlb_flush_proc,OFFSET TlbFlush486

init_tlb_done:
    mov bx,task_sel
    mov eax,OFFSET task_seg_size
    push cs
    call allocate_fixed_system_mem
;
    mov ax,task_sel
    mov ds,ax
    mov ds:try_lock_proc,OFFSET TryLockDefault
    mov ds:lock_proc,OFFSET LockDefault
    mov ds:unlock_proc,OFFSET UnlockDefault
    mov ds:load_unlock_proc,OFFSET LoadUnlockDefault
    mov ds:lock_list_proc,OFFSET LockListSingle
    mov ds:unlock_list_proc,OFFSET UnlockListSingle
    mov ds:signal_list,0
    mov ds:wakeup_list,0
    mov ds:term_thread_list,0
    mov ds:term_proc_list,0
    mov ds:has_signal,0
    mov ds:has_list,0
    mov ds:has_term,0
    mov ds:owner_sel,0
    mov ds:system_thread,0
    mov ds:owner_lock,0
    mov ds:owner_wait,0
    mov ds:list_lock,0
    mov ds:help_call_ip,0
    mov ds:system_time,0
    mov ds:system_time+4,0
    mov ds:time_diff,0
    mov ds:time_diff+4,0
    mov bx,OFFSET ptab
    mov ds:prio_act,bx
;
    mov cx,256
ptab_init:
    mov word ptr [bx],0
    add bx,2
    loop ptab_init
;
    mov ds:processor_preempt,0
    mov ds:processor_count,0
;
    mov bx,OFFSET processor_arr
    mov cx,32
proc_init:
    mov word ptr [bx],0
    add bx,2
    loop proc_init
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET shutdown_pr
    mov di,OFFSET shutdown_name
    xor cl,cl
    mov ax,shutdown_nr
    RegisterOsGate
;
    mov si,OFFSET show_proc_debug
    mov di,OFFSET show_proc_debug_name
    xor cl,cl
    mov ax,show_proc_debug_nr
    RegisterOsGate
;
    mov si,OFFSET create_processor
    mov di,OFFSET create_processor_name
    xor cl,cl
    mov ax,create_processor_nr
    RegisterOsGate
;
    mov si,OFFSET get_processor
    mov di,OFFSET get_processor_name
    xor cl,cl
    mov ax,get_processor_nr
    RegisterOsGate
;
    mov si,OFFSET start_processor
    mov di,OFFSET start_processor_name
    xor cl,cl
    mov ax,start_processor_nr
    RegisterOsGate
;
    mov si,OFFSET do_preempt_processor
    mov di,OFFSET do_preempt_processor_name
    xor cl,cl
    mov ax,do_preempt_processor_nr
    RegisterOsGate
;
    mov si,OFFSET start_pit_timer
    mov di,OFFSET start_pit_timer_name
    xor cl,cl
    mov ax,start_sys_timer_nr
    RegisterOsGate
;
    mov si,OFFSET reload_pit_timer
    mov di,OFFSET reload_pit_timer_name
    xor cl,cl
    mov ax,reload_sys_timer_nr
    RegisterOsGate
;
    mov si,OFFSET enter_int
    mov di,OFFSET enter_int_name
    xor cl,cl
    mov ax,enter_int_nr
    RegisterOsGate
;
    mov si,OFFSET leave_int
    mov di,OFFSET leave_int_name
    xor cl,cl
    mov ax,leave_int_nr
    RegisterOsGate
;
    mov si,OFFSET lock_task
    mov di,OFFSET lock_task_name
    xor cl,cl
    mov ax,lock_task_nr
    RegisterOsGate
;
    mov si,OFFSET unlock_task
    mov di,OFFSET unlock_task_name
    xor cl,cl
    mov ax,unlock_task_nr
    RegisterOsGate
;
    mov si,OFFSET debug_exception
    mov di,OFFSET debug_exception_name
    xor cl,cl
    mov ax,debug_exception_nr
    RegisterOsGate
;
    mov si,OFFSET locked_debug_exception
    mov di,OFFSET locked_debug_exception_name
    xor cl,cl
    mov ax,locked_debug_exception_nr
    RegisterOsGate
;
    mov si,OFFSET start_timer
    mov di,OFFSET start_timer_name
    xor cl,cl
    mov ax,start_timer_nr
    RegisterOsGate
;
    mov si,OFFSET stop_timer
    mov di,OFFSET stop_timer_name
    xor cl,cl
    mov ax,stop_timer_nr
    RegisterOsGate
;
    mov si,OFFSET wake_thread
    mov di,OFFSET wake_thread_name
    xor cl,cl
    mov ax,wake_thread_nr
    RegisterOsGate
;
    mov si,OFFSET sleep_thread
    mov di,OFFSET sleep_thread_name
    xor cl,cl
    mov ax,sleep_thread_nr
    RegisterOsGate
;
    mov si,OFFSET clear_signal
    mov di,OFFSET clear_signal_name
    xor cl,cl
    mov ax,clear_signal_nr
    RegisterOsGate
;
    mov si,OFFSET signal_thread
    mov di,OFFSET signal_thread_name
    xor cl,cl
    mov ax,signal_nr
    RegisterOsGate
;
    mov si,OFFSET wait_for_signal
    mov di,OFFSET wait_for_signal_name
    xor cl,cl
    mov ax,wait_for_signal_nr
    RegisterOsGate
;
    mov si,OFFSET wait_for_signal_timeout
    mov di,OFFSET wait_for_signal_timeout_name
    xor cl,cl
    mov ax,wait_for_signal_timeout_nr
    RegisterOsGate
;
    mov si,OFFSET cpu_reset
    mov di,OFFSET cpu_reset_name
    xor dx,dx
    mov ax,cpu_reset_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET power_failure
    mov di,OFFSET power_failure_name
    xor dx,dx
    mov ax,power_failure_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_thread_pr
    mov di,OFFSET get_thread_name
    xor dx,dx
    mov ax,get_thread_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_processor_id
    mov di,OFFSET get_processor_id_name
    xor dx,dx
    mov ax,get_processor_id_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_cpu_time
    mov di,OFFSET get_cpu_time_name
    xor dx,dx
    mov ax,get_cpu_time_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET swap_out
    mov di,OFFSET swap_name
    xor dx,dx
    mov ax,swap_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET wait_milli_sec
    mov di,OFFSET wait_milli_name
    xor dx,dx
    mov ax,wait_milli_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET wait_micro_sec
    mov di,OFFSET wait_micro_name
    xor dx,dx
    mov ax,wait_micro_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET wait_until
    mov di,OFFSET wait_until_name
    xor dx,dx
    mov ax,wait_until_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET notify_time_drift
    mov di,OFFSET notify_time_drift_name
    xor cl,cl
    mov ax,notify_time_drift_nr
    RegisterOsGate
;
    mov si,OFFSET get_system_time
    mov di,OFFSET get_system_time_name
    xor dx,dx
    mov ax,get_system_time_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_time
    mov di,OFFSET get_time_name
    xor dx,dx
    mov ax,get_time_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET time_to_system_time
    mov di,OFFSET time_to_system_time_name
    xor dx,dx
    mov ax,time_to_system_time_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET system_time_to_time
    mov di,OFFSET system_time_to_time_name
    xor dx,dx
    mov ax,system_time_to_time_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET set_system_time
    mov di,OFFSET set_system_time_name
    xor cl,cl
    mov ax,set_system_time_nr
    RegisterOsGate
;
    mov si,OFFSET sim_sti
    mov di,OFFSET sim_sti_name
    xor cl,cl
    mov ax,sim_sti_nr
    RegisterOsGate
;
    mov si,OFFSET sim_cli
    mov di,OFFSET sim_cli_name
    xor cl,cl
    mov ax,sim_cli_nr
    RegisterOsGate
;
    mov si,OFFSET sim_set_flags
    mov di,OFFSET sim_set_flags_name
    xor cl,cl
    mov ax,sim_set_flags_nr
    RegisterOsGate
;
    mov si,OFFSET sim_get_flags
    mov di,OFFSET sim_get_flags_name
    xor cl,cl
    mov ax,sim_get_flags_nr
    RegisterOsGate
;
    mov si,OFFSET debug_break
    mov di,OFFSET debug_break_name
    xor cl,cl
    mov ax,debug_break_nr
    RegisterOsGate
;
    mov si,OFFSET enter_section
    mov di,OFFSET enter_section_name
    xor cl,cl
    mov ax,enter_section_nr
    RegisterOsGate
;
    mov si,OFFSET leave_section
    mov di,OFFSET leave_section_name
    xor cl,cl
    mov ax,leave_section_nr
    RegisterOsGate
;
    mov si,OFFSET get_debug_thread_sel
    mov di,OFFSET get_debug_thread_sel_name
    xor cl,cl
    mov ax,get_debug_thread_sel_nr
    RegisterOsGate
;
    mov si,OFFSET create_user_section
    mov di,OFFSET create_user_section_name
    xor dx,dx
    mov ax,create_user_section_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET create_blocked_user_section
    mov di,OFFSET create_blocked_user_section_name
    xor dx,dx
    mov ax,create_blocked_user_section_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET delete_user_section
    mov di,OFFSET delete_user_section_name
    xor dx,dx
    mov ax,delete_user_section_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET enter_user_section
    mov di,OFFSET enter_user_section_name
    xor dx,dx
    mov ax,enter_user_section_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET leave_user_section
    mov di,OFFSET leave_user_section_name
    xor dx,dx
    mov ax,leave_user_section_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_debug_thread
    mov di,OFFSET get_debug_thread_name
    xor dx,dx
    mov ax,get_debug_thread_nr
    RegisterBimodalUserGate
;
    mov bx,OFFSET get_debug_tss16
    mov si,OFFSET get_debug_tss32
    mov di,OFFSET get_debug_tss_name
    mov dx,virt_es_in
    mov ax,get_debug_tss_nr
    RegisterUserGate
;
    mov si,OFFSET debug_trace
    mov di,OFFSET debug_trace_name
    xor dx,dx
    mov ax,debug_trace_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_pace
    mov di,OFFSET debug_pace_name
    xor dx,dx
    mov ax,debug_pace_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_go
    mov di,OFFSET debug_go_name
    xor dx,dx
    mov ax,debug_go_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_next
    mov di,OFFSET debug_next_name
    xor dx,dx
    mov ax,debug_next_nr
    RegisterBimodalUserGate
;
    mov bx,OFFSET set_code_break16
    mov si,OFFSET set_code_break32
    mov di,OFFSET set_code_break_name
    mov dx,virt_es_in
    mov ax,set_code_break_nr
    RegisterUserGate
;
    mov bx,OFFSET set_read_data_break16
    mov si,OFFSET set_read_data_break32
    mov di,OFFSET set_read_data_break_name
    mov dx,virt_es_in
    mov ax,set_read_data_break_nr
    RegisterUserGate
;
    mov bx,OFFSET set_write_data_break16
    mov si,OFFSET set_write_data_break32
    mov di,OFFSET set_write_data_break_name
    mov dx,virt_es_in
    mov ax,set_write_data_break_nr
    RegisterUserGate
;
    mov si,OFFSET clear_break
    mov di,OFFSET clear_break_name
    xor dx,dx
    mov ax,clear_break_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET update_time
    mov di,OFFSET update_time_name
    xor cl,cl
    mov ax,update_time_nr
    RegisterBimodalUserGate
;
    mov di,OFFSET check_list
    HookState
;
    mov di,OFFSET get_processor_single
    CreateProcessor
;
    pop ds
    popa
    ret
init_task       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadWord
;
;           DESCRIPTION:    Read a word in another thread
;
;           PARAMETERS:         DX:ESI  Address
;                           ES          TSS
;
;           RETURNS:        AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadWord    Proc near
    push bx
    push cx
    push esi
    mov bx,es:tss_thread
    test es:tss_eflags+2,2
    jz read_word_prot
read_word_virt:
    ReadThreadSegment
    mov cx,ax
    inc si
    ReadThreadSegment
    mov ah,al
    mov al,cl
    jmp read_word_done
read_word_prot:
    ReadThreadSelector
    mov cx,ax
    inc esi
    ReadThreadSelector
    mov ah,al
    mov al,cl
read_word_done:
    pop esi
    pop cx
    pop bx  
    ret
ReadWord    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteWord
;
;           DESCRIPTION:    Write a word in another thread
;
;           PARAMETERS:         DX:ESI  Address
;                           ES          TSS
;                           AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteWord       Proc near
    push bx
    push cx
    push esi
    mov cx,ax
    mov bx,es:tss_thread
    test es:tss_eflags+2,2
    jz write_word_prot
write_word_virt:
    mov al,cl
    WriteThreadSegment
    inc si
    mov al,ch
    WriteThreadSegment
    jmp write_word_done
write_word_prot:
    mov al,cl
    WriteThreadSelector
    inc esi
    mov al,ch
    WriteThreadSelector
write_word_done:
    pop esi
    pop cx
    pop bx  
    ret
WriteWord       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DEBUG_THREAD_SEL
;
;           DESCRIPTION:    Get currently debugged thread selector
;
;           PARAMETERS:         AX          DEBUG THREAD OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_thread_sel_name   DB 'Get Debug Thread Sel', 0

get_debug_thread_sel    PROC far
    push ds
    push es
    push cx
    push dx
    push si
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:debug_thread
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    jz get_debug_sel_done

    mov dx,ax
get_debug_sel_try_next:
    cmp ax,cx
    je get_debug_sel_default
    mov es,ax
    mov ax,es:p_next
    cmp dx,ax
    je get_debug_sel_new
    jmp get_debug_sel_try_next
get_debug_sel_new:
    mov cx,[si]
get_debug_sel_default:
    mov ds:debug_thread,cx
    mov ax,cx
get_debug_sel_done:
    pop si
    pop dx
    pop cx
    pop es
    pop ds
    ret
get_debug_thread_sel    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DEBUG_THREAD
;
;           DESCRIPTION:    Get currently debugged thread ID
;
;           PARAMETERS:     AX         DEBUG THREAD ID OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_thread_name   DB 'Get Debug Thread', 0

get_debug_thread    PROC far
    push es
    call get_debug_thread_sel
    or ax,ax
    jz get_debug_done
;
    mov es,ax
    mov ax,es:p_id

get_debug_done:
    pop es
    retf32
get_debug_thread    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DEBUG_TSS
;
;           DESCRIPTION:    Get currently debugged TSS
;
;           PARAMETERS:         ES:(E)DI    BUFFER FOR TSS
;                           AX              THREAD BLOCK OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_tss_name      DB 'Get Debug TSS',0

get_debug_tss16 PROC far
    push ds
    push si
    call get_debug_thread_sel
    or ax,ax
    jz get_debug_tss_done16
    mov ds,ax
    mov ds,ds:p_tss_data_sel
    xor si,si
    mov cx,OFFSET tss_bitmap_space
    rep movsb
get_debug_tss_done16:   
    pop si
    pop ds
    ret
get_debug_tss16 ENDP

get_debug_tss32 PROC far
    push ds
    push esi
    call get_debug_thread_sel
    or ax,ax
    jz get_debug_tss_done32
    mov ds,ax
    mov ds,ds:p_tss_data_sel
    xor esi,esi
    mov ecx,OFFSET tss_bitmap_space
    rep movs byte ptr es:[edi],ds:[esi]
get_debug_tss_done32:   
    pop esi
    pop ds
    retf32
get_debug_tss32 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_TRACE
;
;           DESCRIPTION:    Trace one instruction in debugged thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_trace_name    DB 'Debug Trace',0

debug_trace     PROC far
    push ds
    push es
    pushad
    call get_debug_thread_sel
    or ax,ax
    jz debug_trace_done
    mov bx,ax
    mov es,bx
    mov es,es:p_tss_data_sel
    mov dx,es:tss_cs
    mov esi,dword ptr es:tss_eip
    call ReadWord
    push ax
    add esi,2
    call ReadWord
    mov dx,ax
    pop ax  
    cmp al,0CDh
    jne debug_trace_trace
;
    test es:tss_eflags+2,2
    jz debug_trace_trace
    and es:tss_eflags+2,NOT 2
    mov dx,vm_int_sel
    movzx esi,ah
    shl esi,2
    call ReadWord
    push ax
    add si,2
    call ReadWord
    mov dx,ax
    pop bx
;
    push dx
    push bx
    or es:tss_eflags+2,2
    mov bx,es:tss_thread
    mov dx,es:tss_ss
    movzx esi,es:tss_esp
    sub esi,6
    pop ax
    pop cx
    xchg ax,es:tss_eip
    xchg cx,es:tss_cs
    add ax,2
    call WriteWord
    mov ax,cx
    add esi,2
    call WriteWord
    mov ax,es:tss_eflags
    add esi,2
    call WriteWord
    sub es:tss_esp,6
    jmp debug_trace_done
debug_trace_trace:
    mov eax,es:tss_dr7
    and ax,0FFFCh
    mov es:tss_dr7,eax
    mov bx,es:tss_thread
    mov ax,es:tss_eflags
    or ax,100h
    mov es:tss_eflags,ax
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake
debug_trace_done:
    popad
    pop es
    pop ds
    retf32
debug_trace     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_PACE
;
;           DESCRIPTION:    Pace one instruction in debugged thread
;
;           PARAMETERS:         DS      Tss sel
;               ES      Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_pace_name DB 'Debug Pace',0

load_breaks Proc near
    mov eax,ds:tss_dr0
    mov dr0,eax
    mov eax,ds:tss_dr1
    mov dr1,eax
    mov eax,ds:tss_dr2
    mov dr2,eax
    mov eax,ds:tss_dr3
    mov dr3,eax
    mov eax,ds:tss_dr7
    mov dr7,eax
    and ax,0FFh
    jnz load_break_done
;
    and es:p_flags,NOT THREAD_FLAG_BP
    
load_break_done:
    ret
load_breaks Endp    

debug_pace      PROC far
    push ds
    push es
    pushad
    call get_debug_thread_sel
    or ax,ax
    jz debug_pace_done
    mov bx,ax
    mov es,bx
    mov es,es:p_tss_data_sel
    mov dx,es:tss_cs
    mov esi,dword ptr es:tss_eip
    call ReadWord
    push ax
    add esi,2
    call ReadWord
    mov dx,ax
    pop ax
    xor ebx,ebx
    add bx,2
    cmp al,0E2h
    je debug_pace_step
    cmp al,0CDh
    je debug_pace_step
    inc bx
    cmp al,0E8h
    je debug_pace_step
    add bx,2
    cmp ax,00B0Fh
    jne debug_pace_not_gate
    and dl,0FEh
    cmp dl,0D6h
    jne debug_pace_step
    add bx,3
    jmp debug_pace_step
debug_pace_not_gate:
    cmp al,9Ah
    je debug_pace_step
    inc bx
    cmp ax,9A66h
    jne debug_pace_trace
;
    add bx,2
    
debug_pace_step:
    push ax
    mov ax,es:tss_eflags+2
    test ax,2
    jz debug_pace_step_prot
    pop ax
    xor eax,eax
    xor edx,edx
    mov ax,es:tss_cs
    shl eax,4
    mov dx,es:tss_eip
    add eax,edx
    jmp debug_pace_step_do
debug_pace_step_prot:
    mov si,es:tss_cs
    test si,4
    jz debug_pace_step_gdt
    xor eax,eax
    mov ds,es:tss_thread
    mov ds,ds:p_ldt_sel
    mov si,es:tss_cs
    and si,0FFF8h
    pop ax
    cmp al,0E8h
    jne debug_pace_ldt16
    mov al,[si+6]
    test al,40h
    jz debug_pace_ldt16
    add bx,2
debug_pace_ldt16:
    mov eax,[si+2]
    rol eax,8
    mov al,[si+7]
    ror eax,8
    add eax,dword ptr es:tss_eip
    jmp debug_pace_step_do
debug_pace_step_gdt:
    and si,0FFF8h
    mov ax,gdt_sel
    mov ds,ax
    pop ax
    cmp al,0E8h
    jne debug_pace_gdt16
    mov al,[si+6]
    test al,40h
    jz debug_pace_gdt16
    add bx,2
debug_pace_gdt16:
    mov eax,[si+2]
    rol eax,8
    mov al,[si+7]
    ror eax,8
    add eax,dword ptr es:tss_eip
debug_pace_step_do:
    add eax,ebx
    mov es:tss_dr0,eax
    mov eax,es:tss_dr7
    and eax,0FFF0FFFCh
    or ax,1
    mov es:tss_dr7,eax
    mov ax,es:tss_eflags
    and ax,NOT 100h
    mov es:tss_eflags,ax
    jmp debug_pace_do
debug_pace_trace:
    mov eax,es:tss_dr7
    and ax,0FFFCh
    mov es:tss_dr7,eax
    mov ax,es:tss_eflags
    or ax,100h
    mov es:tss_eflags,ax

debug_pace_do:
    mov bx,es:tss_thread
    mov ds,bx
    or ds:p_flags,THREAD_FLAG_BP
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake
debug_pace_done:
    popad
    pop es
    pop ds
    retf32
debug_pace      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_GO
;
;           DESCRIPTION:    Run currently debugged thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_go_name   DB 'Debug Go',0

debug_go    PROC far
    push ds
    push es
    pushad
    call get_debug_thread_sel
    or ax,ax
    jz debug_go_done
    mov bx,ax
    mov es,bx
    mov es,es:p_tss_data_sel
    mov eax,es:tss_dr7
    and ax,0FFFCh
    mov es:tss_dr7,eax
    mov ax,es:tss_eflags
    and ax,NOT 100h
    mov es:tss_eflags,ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake
debug_go_done:
    popad
    pop es
    pop ds
    retf32
debug_go    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_NEXT
;
;           DESCRIPTION:    Select next thread as currently debugged
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_next_name DB 'Debug Next',0

debug_next      PROC far
    push ds
    push es
    push ax
    push si
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    je debug_next_end
    mov es,ax
    mov es,es:p_next
    mov [si],es
    mov ds:debug_thread,es
debug_next_end:
    pop si
    pop ax
    pop es
    pop ds
    retf32
debug_next      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ConvBreakThread
;
;           DESCRIPTION:    Convert thread into selector
;
;           PARAMETERS:     BX          Thread ID
;
;           RETURNS:        ES          Thread selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvBreakThread PROC near
    push ax
    push bx
;    
    or bx,bx
    jnz cbtDo
;
    GetThread
    mov es,ax
    clc
    jmp cbtDone

cbtDo:
    ThreadToSel
    jc cbtDone
;    
    mov es,bx

cbtDone:
    pop bx
    pop ax
    ret
ConvBreakThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           BreakToLinear
;
;           DESCRIPTION:    Convert break address to linear address
;
;           PARAMETERS:     ES:(E)DI        Address
;
;           RETURNS:        EDX             Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BreakToLinear PROC near
    push bx
    push ecx
;
    mov bx,es
    GetSelectorBaseSize
    jc btlDone
;
    or ecx,ecx
    jz btlAdd
;    
    cmp edi,ecx
    jae btlFail

btlAdd:
    add edx,edi
    clc
    jmp btlDone

btlFail:
    stc

btlDone:
    pop ecx
    pop bx    
    ret
BreakToLinear ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddBreak
;
;           DESCRIPTION:    Add a local breakpoint
;
;           PARAMETERS:     EDX     Linear address
;                           ES      Thread sel
;                           AL      Debug register
;                           AH      Type coding
;                           CL      Size of region
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abSizeTab:
ast00  DB 0
ast01  DB 0
ast02  DB 1
ast03  DB 3
ast04  DB 3
ast05  DB 2
ast06  DB 2
ast07  DB 2

AddBreak PROC near
    push ds
    push bx
    push cx
    push edx
    push esi
;
    mov ds,es:p_tss_data_sel
    cmp al,4
    jae abFail
;   
    movzx bx,al
    shl bx,2 
    add bx,OFFSET tss_dr0
    mov ds:[bx],edx
;
    cmp cl,7
    jbe abSizeOk
;
    mov cl,7

abSizeOk:
    movzx bx,cl
;    
    mov esi,0Fh
    mov cl,al
    shl cl,2
    add cl,16
    shl esi,cl
;    
    mov si,3
    mov cl,al
    shl cl,1
    shl si,cl
;    
    not esi
;    
    push eax
    mov cl,al
    shl cl,2
    add cl,16
    movzx eax,ah
    shl eax,cl
    movzx edx,byte ptr cs:[bx].abSizeTab
    add cl,2
    shl edx,cl
    or edx,eax
    pop eax
;
    mov cl,al
    shl cl,1
    mov dx,1
    shl dx,cl
    and ds:tss_dr7,esi
    or ds:tss_dr7,edx
    or es:p_flags,THREAD_FLAG_BP
    clc
    jmp abDone

abFail:
    stc

abDone:   
    pop esi
    pop edx
    pop cx
    pop bx
    pop ds
    ret
AddBreak ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveBreak
;
;           DESCRIPTION:    Remove a local breakpoint
;
;           PARAMETERS:     ES      Thread sel
;                           AL      Debug register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveBreak PROC near
    push ds
    push cx
    push edx
;
    mov ds,es:p_tss_data_sel
    cmp al,4
    jae rbFail
;    
    mov edx,0Fh
    mov cl,al
    shl cl,2
    add cl,16
    shl edx,cl
;    
    mov dx,3
    mov cl,al
    shl cl,1
    shl dx,cl
;    
    not edx
    and ds:tss_dr7,edx
    clc
    jmp rbDone

rbFail:
    stc

rbDone:   
    pop edx
    pop cx
    pop ds
    ret
RemoveBreak ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCodeBreak
;
;           DESCRIPTION:    Set a code breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           ES:(E)DI        Address
;                           AL              Debug register (0..3)    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_code_break_name DB 'Set Code Break',0

set_code_break PROC near
    push es
    push ax
    push bx
    push cx
    push edx
;    
    call BreakToLinear
    jc scbDone
;
    call ConvBreakThread
    jc scbDone
;
    xor ah,ah
    mov cl,1
    call AddBreak

scbDone:
    pop edx
    pop cx
    pop bx
    pop ax
    pop es
    ret
set_code_break ENDP

set_code_break16  Proc far
    push edi
    movzx edi,di
    call set_code_break
    pop edi
    ret
set_code_break16  Endp

set_code_break32  Proc far
    call set_code_break
    retf32
set_code_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetReadDataBreak
;
;           DESCRIPTION:    Set a read-data breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           ES:(E)DI        Address
;                           AL              Debug register (1..3)    
;                           CL              Size of region (1,2,4 or 8)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_read_data_break_name DB 'Set Read Data Break',0

set_read_data_break PROC near
    push es
    push ax
    push bx
    push edx
;    
    call BreakToLinear
    jc srdDone
;
    call ConvBreakThread
    jc srdDone
;
    mov ah,3
    call AddBreak

srdDone:
    pop edx
    pop bx
    pop ax
    pop es
    ret
set_read_data_break ENDP

set_read_data_break16  Proc far
    push edi
    movzx edi,di
    call set_read_data_break
    pop edi

    ret
set_read_data_break16  Endp

set_read_data_break32  Proc far
    call set_read_data_break
    retf32
set_read_data_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetWriteDataBreak
;
;           DESCRIPTION:    Set a write-data breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           ES:(E)DI        Address
;                           AL              Debug register (1..3)    
;                           CL              Size of region (1,2,4 or 8)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_write_data_break_name DB 'Set Write Data Break',0

set_write_data_break PROC near
    push es
    push ax
    push bx
    push edx
;    
    call BreakToLinear
    jc swdDone
;
    call ConvBreakThread
    jc swdDone
;
    mov ah,1
    call AddBreak

swdDone:
    pop edx
    pop bx
    pop ax
    pop es
    ret
set_write_data_break ENDP

set_write_data_break16  Proc far
    push edi
    movzx edi,di
    call set_write_data_break
    pop edi
    ret
set_write_data_break16  Endp

set_write_data_break32  Proc far
    call set_write_data_break
    retf32
set_write_data_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearBreak
;
;           DESCRIPTION:    Clear a breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           AL              Debug register (0..3)    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_break_name DB 'Clear Break',0

clear_break PROC far
    push es
    push ax
    push bx
;
    call ConvBreakThread
    jc cbDone
;    
    call RemoveBreak

cbDone:
    pop bx
    pop ax
    pop es
    retf32
clear_break ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           VIRT_sti
;
;           DESCRIPTION:    Simulate STI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public virt_sti

virt_sti    PROC near
    push ax
    GetThread
    mov ds,ax
    pop ax
    mov ds,ds:p_process_sel
    mov ds:ms_virt_flags,7200h
virt_sti_test_wake:
    cli
    cmp ds:ms_wait_sti,0
    jz virt_sti_nowake
    push si
    mov si,OFFSET ms_wait_sti
    Wake
    pop si
    jmp virt_sti_test_wake
virt_sti_nowake:
    sti
    inc byte ptr [bp].vm_eip
    ret
virt_sti    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           sim_sti
;
;           DESCRIPTION:    Simulate STI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_sti_name    DB 'Simulate Sti',0

sim_sti PROC far
    push ds
    push ax
    sti
    GetThread
    mov ds,ax
    mov ds,ds:p_process_sel
    mov ds:ms_virt_flags,7200h
sim_sti_test_wake:
    cmp ds:ms_wait_sti,0
    jz sim_sti_nowake
    push si
    mov si,OFFSET ms_wait_sti
    Wake
    pop si
    jmp sim_sti_test_wake
sim_sti_nowake:
    pop ax
    pop ds
    ret
sim_sti ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           virt_cli
;
;           DESCRIPTION:    Simulate CLI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public virt_cli

virt_cli    PROC near
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_process_sel
    cli
    mov ds:ms_cli_thread,ax
    mov ds:ms_virt_flags,7000h
    sti
    inc byte ptr [bp].vm_eip
    pop ax
    ret
virt_cli    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           sim_cli
;
;           DESCRIPTION:    Simulate CLI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_cli_name    DB 'Simulate Cli',0

sim_cli PROC far
    push ds
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_process_sel
    cli
    mov ds:ms_cli_thread,ax
    mov ds:ms_virt_flags,7000h
    sti
    pop ax
    pop ds
    ret
sim_cli ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           set_flags
;
;           DESCRIPTION:    Simulate set flags
;
;           PARAMETERS:         AX          FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_flags

set_flags       PROC near
    push ax
    GetThread
    mov ds,ax
    mov bx,ax
    pop ax
    mov ds,ds:p_process_sel
    cli
    mov ds:ms_cli_thread,bx
    mov bx,ax
    and bx,200h
    or bx,7000h
    mov ds:ms_virt_flags,bx
    sti
    test bx,200h
    jz set_flags_nowake
set_flags_test_wake:
    cmp ds:ms_wait_sti,0
    jz set_flags_nowake
    push si
    mov si,OFFSET ms_wait_sti
    Wake
    pop si
    jmp set_flags_test_wake
set_flags_nowake:
    and ax,NOT 7000h
    or ax,200h
    ret
set_flags       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           sim_set_flags
;
;           DESCRIPTION:    Simulate set flags
;
;           PARAMETERS:         AX          FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_set_flags_name      DB 'Set Flags',0

sim_set_flags   PROC far
    push ds
    push bx
    call set_flags
    pop bx
    pop ds
    ret
sim_set_flags   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_flags
;
;           DESCRIPTION:    Modify int bit in simulated flags
;
;           PARAMETERS:         AX          FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_flags

get_flags       PROC near
    push ax
    GetThread
    mov ds,ax
    pop ax
    mov ds,ds:p_process_sel
    and ax,NOT 200h
    mov bx,ds:ms_virt_flags
    and bx,200h
    or ax,bx
    or ax,7000h
    ret
get_flags       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           sim_get_flags
;
;           DESCRIPTION:    Modify int bit in simulated flags
;
;           PARAMETERS:         AX          FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_get_flags_name      DB 'Get Flags',0

sim_get_flags   PROC far
    push ds
    push bx
    call get_flags
    pop bx
    pop ds
    ret
sim_get_flags   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HandlePreempt
;
;           DESCRIPTION:    Handle preempt
;
;           PARAMETERS:     DS      Task sel
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePreempt    Proc near
    test fs:ps_flags,PS_FLAG_PREEMPT
    jz hpDone
;
    mov si,ds:prio_act
    mov ax,[si]
    or ax,ax
    jz hpDone
;       
    cmp ax,fs:ps_last_thread
    jne hpDone
;    
    mov es,ax
    mov ax,es:p_next
    mov [si],ax

hpDone:
    ret
HandlePreempt   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HandlePrio
;
;           DESCRIPTION:    Handle prio
;
;           PARAMETERS:     DS      Task sel
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePrio    Proc near
    mov si,ds:prio_act
    mov ax,[si]
    or ax,ax
    jnz hpqInt
;
    or si,si
    jz hpqDone
;
    sub si,2
    mov ds:prio_act,si
    jmp HandlePrio

hpqInt:
    mov es,ax
    mov es,es:p_process_sel
    test es:ms_virt_flags,200h
    jnz hpqDone
;
    cmp ax,es:ms_cli_thread
    je hpqDone
;
    call ds:lock_list_proc
    mov ax,es
    mov si,ds:prio_act
    RemoveBlock          
    push ds  
    mov ds,ax
    mov di,OFFSET ms_wait_sti
    InsertBlock
    pop ds
    call ds:unlock_list_proc
    jmp HandlePrio

hpqDone:
    ret
HandlePrio  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetPrioThread
;
;           DESCRIPTION:    Get thread from standard list
;
;           PARAMETERS:     DS      Task sel
;               FS      Processor selector
;
;       RETURNS:    ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPrioThread    Proc near
    mov si,ds:prio_act
    mov ax,[si]
    or ax,ax
    jz gptNull
;    
    RemoveBlock

gptLoop:
    mov ax,[si]
    or ax,ax
    jnz gptDone
;
    or si,si    
    jz gptDone
;
    sub si,2
    mov ds:prio_act,si
    jmp gptLoop

gptNull:
    mov es,fs:ps_null_thread

gptDone:
    ret
GetPrioThread   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetupPreempt
;
;           DESCRIPTION:    Setup preempt
;
;           PARAMETERS:     DS      Task sel
;               FS      Processor selector
;               ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupPreempt    Proc near
    mov ax,es
    cmp ax,fs:ps_null_thread
    je spSet
;    
    cmp ax,fs:ps_last_thread
    jne spSet
;
    test fs:ps_flags,PS_FLAG_PREEMPT
    jz spDone    

spSet:
    cli
    call ds:update_clock_proc
    LocalGetSystemTime
    sti
    add eax,1193
    adc edx,0
    mov fs:ps_preempt_lsb,eax
    mov fs:ps_preempt_msb,edx

spDone:
    and fs:ps_flags,NOT PS_FLAG_PREEMPT
    ret
SetupPreempt    Endp
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetNextThread
;
;           DESCRIPTION:    Get next thread to run
;
;           PARAMETERS:     DS      Task sel
;               FS      Processor selector
;
;       RETURNS:    ES      Thread to run next
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetNextThread    Proc near
    sti
    and fs:ps_flags,NOT PS_FLAG_PRIO_CHANGE
;
    call HandlePreempt
    call HandlePrio
    call GetPrioThread
    call SetupPreempt
    ret
GetNextThread   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ThreadSuspend
;
;           DESCRIPTION:    Suspend thread callback from scheduler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn prot_exception:near
    extrn virt_exception:near
    
thread_suspend:
    push dword ptr 0
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
;
    mov eax,[bp].vm_eflags
    or eax,10100h
    mov [bp].vm_eflags,eax
    test eax,20000h
    jnz tsVm
;
    mov al,1
    call prot_exception
    jmp tsRet

tsVm:
    mov al,1
    call virt_exception

tsRet:
    pop ds
    pop ebx
    pop eax
    pop bp
    add sp,4
    iretd

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddCallback
;
;           DESCRIPTION:    Add callback to thread
;
;       PARAMETERS:     DS      Thread TSS
;               ES      Thread block
;               BX      Callback routine
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCallback Proc near
    push dx
    push si
    push di
;    
    test dword ptr ds:tss_eflags,20000h
    jnz acVm
;
    test word ptr ds:tss_cs,3
    jnz acPm

acKernel:
    mov si,ss
    mov di,sp
;    
    mov dx,ds:tss_ss
    mov ss,dx
    mov sp,ds:tss_esp
;
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;
    mov ds:tss_ss,ss
    mov ds:tss_esp,sp
    mov ss,si
    mov sp,di
    jmp acDone

acPm:
    mov si,ss
    mov di,sp
;    
    mov dx,ds:tss_ess0
    mov ss,dx
    mov sp,ds:tss_esp0
;
    push dword ptr ds:tss_ss
    push dword ptr ds:tss_esp
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;
    mov ds:tss_ss,ss
    mov ds:tss_esp,sp
    mov ss,si
    mov sp,di
    jmp acDone

acVm:
    mov si,ss
    mov di,sp
;    
    mov dx,ds:tss_ess0
    mov ss,dx
    mov sp,ds:tss_esp0
;
    push dword ptr ds:tss_gs
    push dword ptr ds:tss_fs
    push dword ptr ds:tss_ds
    push dword ptr ds:tss_es
    push dword ptr ds:tss_ss
    push dword ptr ds:tss_esp
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;
    mov ds:tss_ss,ss
    mov ds:tss_esp,sp
    and dword ptr ds:tss_eflags,NOT 20000h
    mov ss,si
    mov sp,di

acDone:   
    mov ds:tss_cs,cs
    movzx ebx,bx
    mov dword ptr ds:tss_eip,ebx
;
    pop di
    pop si
    pop dx
    ret
AddCallback Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LoadCurrentThread
;
;           DESCRIPTION:    Load register-state for current thread
;
;       PARAMETERS:     DS      Task sel
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn thread_create:near

LoadCurrentThread:
;       call ds:load_unlock_proc
;
;   call ds:lock_proc

load_thread_loop:
    call UpdateLists
    call GetNextThread

load_reload_loop:
    mov eax,fs:ps_mask
    not eax
    lock and ds:processor_preempt,eax
;    
    and fs:ps_flags,NOT PS_FLAG_TIMER   
    cli
    call ds:update_clock_proc
    LocalGetSystemTime
    mov fs:ps_last_lsb,eax
    add eax,ds:update_tics
    adc edx,0
    mov bx,fs:ps_timer_head
    mov ecx,fs:ps_preempt_msb
    cmp ecx,fs:[bx].ps_timer_msb
    jc load_check_preempt
;
    jnz load_check_timer
;       
    mov ecx,fs:ps_preempt_lsb
    cmp ecx,fs:[bx].ps_timer_lsb
    jc load_check_preempt

load_check_timer:
    sub eax,fs:[bx].ps_timer_lsb
    sbb edx,fs:[bx].ps_timer_msb
    jc load_reload_timer
;       
    LocalRemoveTimer
    jmp load_reload_loop

load_check_preempt:
    sub eax,fs:ps_preempt_lsb
    sbb edx,fs:ps_preempt_msb
    jc load_reload_timer
;       
    or fs:ps_flags,PS_FLAG_PREEMPT

load_retry:
    mov ax,es
    cmp ax,fs:ps_null_thread
    je load_thread_loop
;
    mov di,es:p_prio
    InsertFirst
    cmp di,ds:prio_act
    jbe load_thread_loop
;
    mov ds:prio_act,di
    or fs:ps_flags,PS_FLAG_PRIO_CHANGE
    jmp load_thread_loop

load_reload_timer:
    neg eax
    ReloadSysTimer
;       
    sti
    mov ax,gdt_sel
    mov ds,ax
    mov bx,es:p_tss_sel
    and byte ptr ds:[bx+5],NOT 2
    ltr bx
;
    mov ax,sys_dir_sel
    mov ds,ax
    mov bx,(io_focus_linear SHR 20) AND 0FFFh
    mov edx,[bx]
    mov bx,process_dir_sel
    mov ds,bx
    mov bx,(io_focus_linear SHR 20) AND 0FFFh
    cmp edx,[bx]
    jne load_reload_cr3
;
    mov eax,cr3
    cmp eax,es:p_cr3
    je load_cr3_ok

load_reload_cr3:    
    mov [bx],edx        
    mov eax,es:p_cr3
    mov cr3,eax

load_cr3_ok:
    mov ds,es:p_tss_data_sel
;
    mov eax,cr0
    or al,8
    mov cr0,eax    
;
    lldt ds:tss_ldt
;
    mov ax,es:p_flags
    or ax,ax
    jz load_actions_done
;
    test ax,THREAD_FLAG_CREATE
    jz load_create_done
;
    and es:p_flags,NOT THREAD_FLAG_CREATE
    mov bx,OFFSET thread_create
    call AddCallback
    
load_create_done:
    mov ax,es:p_flags
    test ax,THREAD_FLAG_SUSPEND
    jz load_suspend_done
;
    and es:p_flags,NOT THREAD_FLAG_SUSPEND
    mov bx,OFFSET thread_suspend
    call AddCallback

load_suspend_done:
    mov ax,es:p_flags
    test ax,THREAD_FLAG_BP
    jz load_bp_done
;
    call load_breaks

load_bp_done:

load_actions_done: 
    push ds
    mov ax,task_sel
    mov ds,ax
    call ds:load_unlock_proc
    mov al,ds:has_signal
    or al,ds:has_list
    pop ds
    jnz load_relock
;
    test fs:ps_flags,PS_FLAG_TIMER
    jz load_regs

load_relock:
    sti
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    jmp load_retry
        
load_regs:
    mov fs:ps_curr_thread,es
    mov fs:ps_last_thread,es
;
    test dword ptr ds:tss_eflags,20000h
    jnz load_vm
;
    test word ptr ds:tss_cs,3
    jnz load_pm_app

load_kernel:
    mov ax,word ptr ds:tss_ss
    cmp ax,word ptr ds:tss_ess0
    je load_kernel_ss0_ok
;
    mov dx,word ptr ds:tss_ess0
    mov esi,dword ptr ds:tss_eip
    mov di,word ptr ds:tss_cs
    int 3

load_kernel_ss0_ok:
    mov ss,ax
    mov esp,dword ptr ds:tss_esp
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;       
    mov ecx,dword ptr ds:tss_ecx
    mov edx,dword ptr ds:tss_edx
    mov ebx,dword ptr ds:tss_ebx
    mov ebp,dword ptr ds:tss_ebp
    mov esi,dword ptr ds:tss_esi
    mov edi,dword ptr ds:tss_edi
;
    mov ax,word ptr ds:tss_es
    verr ax
    jz load_kernel_es
;
    xor ax,ax
    
load_kernel_es:
    mov es,ax
;       
    mov ax,word ptr ds:tss_fs
    verr ax
    jz load_kernel_fs
;
    xor ax,ax
    
load_kernel_fs:
    mov fs,ax
;       
    mov ax,word ptr ds:tss_gs
    verr ax
    jz load_kernel_gs
;
    xor ax,ax
    
load_kernel_gs:
    mov gs,ax
;       
    mov ax,word ptr ds:tss_ds
    verr ax
    jz load_kernel_ds
;
    xor ax,ax
    
load_kernel_ds:
    push ax
    mov eax,dword ptr ds:tss_eax
    pop ds
    iretd

load_pm_app:    
    mov ax,word ptr ds:tss_ess0
    mov ss,ax
    mov esp,dword ptr ds:tss_esp0
;
    push dword ptr ds:tss_ss
    push dword ptr ds:tss_esp
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;       
    mov ecx,dword ptr ds:tss_ecx
    mov edx,dword ptr ds:tss_edx
    mov ebx,dword ptr ds:tss_ebx
    mov ebp,dword ptr ds:tss_ebp
    mov esi,dword ptr ds:tss_esi
    mov edi,dword ptr ds:tss_edi
;
    mov ax,word ptr ds:tss_es
    verr ax
    jz load_pm_app_es
;
    xor ax,ax
    
load_pm_app_es:
    mov es,ax
;       
    mov ax,word ptr ds:tss_fs
    verr ax
    jz load_pm_app_fs
;
    xor ax,ax
    
load_pm_app_fs:
    mov fs,ax
;       
    mov ax,word ptr ds:tss_gs
    verr ax
    jz load_pm_app_gs
;
    xor ax,ax
    
load_pm_app_gs:
    mov gs,ax
;       
    mov ax,word ptr ds:tss_ds
    verr ax
    jz load_pm_app_ds
;
    xor ax,ax
    
load_pm_app_ds:
    push ax
    mov eax,dword ptr ds:tss_eax
    pop ds
    iretd

load_vm:
    mov ax,word ptr ds:tss_ess0
    mov ss,ax
    mov esp,dword ptr ds:tss_esp0
;
    push dword ptr ds:tss_gs
    push dword ptr ds:tss_fs
    push dword ptr ds:tss_ds
    push dword ptr ds:tss_es
    push dword ptr ds:tss_ss
    push dword ptr ds:tss_esp
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;
    mov eax,dword ptr ds:tss_eax
    mov ecx,dword ptr ds:tss_ecx
    mov edx,dword ptr ds:tss_edx
    mov ebx,dword ptr ds:tss_ebx
    mov ebp,dword ptr ds:tss_ebp
    mov esi,dword ptr ds:tss_esi
    mov edi,dword ptr ds:tss_edi
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SaveCurrentThread
;
;           DESCRIPTION:    Save state of current thread
;
;       PARAMETERS:     Stack, return IP
;
;       RETURNS:    SS:SP       Processor stack
;               DS      Task sel
;               FS      Processor selector
;               ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveCurrentThread       Proc near       
    push fs
    push ds
    push eax
    push edx
;
    pushf
    pop ax
    and ax,NOT 100h
    push ax
    popf
;    
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
;
    cli    
    call ds:update_clock_proc
    LocalGetSystemTime
    sti
    mov ds,fs:ps_curr_thread
    sub eax,fs:ps_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
;    
    mov ax,ds
    cmp ax,fs:ps_skip_thread
    je save_thread_skip
;    
    mov ds,ds:p_tss_data_sel
    pushfd
    pop dword ptr ds:tss_eflags
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_ebx,ebx
    mov dword ptr ds:tss_ebp,ebp
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov word ptr ds:tss_es,es
    mov word ptr ds:tss_cs,cs
    mov word ptr ds:tss_ss,ss
    mov word ptr ds:tss_gs,gs
;
    pop dword ptr ds:tss_edx
    pop eax
    mov dword ptr ds:tss_eax,eax
;
    pop word ptr ds:tss_ds
    pop word ptr ds:tss_fs
    pop bp
    pop dx
    movzx edx,dx
    mov dword ptr ds:tss_eip,edx
    mov dword ptr ds:tss_esp,esp
    mov edx,dword ptr ds:tss_edx
    jmp save_thread_setup

save_thread_skip:
    pop edx
    pop eax
    add sp,4
    pop bp
    add sp,2

save_thread_setup:
    push ax
    mov ax,task_sel
    mov ds,ax
    pop ax
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
    push bp
;
    xor bp,bp
    mov es,bp
    mov gs,bp    
    ret
SaveCurrentThread   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SaveLockedThread
;
;           DESCRIPTION:    Save state of current thread when lock is already taken
;
;       PARAMETERS:     Stack, return IP
;               FS      Processor selector
;
;       RETURNS:    SS:SP       Processor stack
;               DS      Task sel
;               ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveLockedThread    Proc near       
    push fs
    push ds
    push eax
    push edx
;
    mov ax,task_sel
    mov ds,ax
    cli    
    call ds:update_clock_proc
    LocalGetSystemTime
    sti
    mov ds,fs:ps_curr_thread
    sub eax,fs:ps_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
;    
    mov ax,fs:ps_curr_thread
    cmp ax,fs:ps_skip_thread
    je save_locked_thread_skip
;
    mov ds,ds:p_tss_data_sel
    pushfd
    pop dword ptr ds:tss_eflags
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_ebx,ebx
    mov dword ptr ds:tss_ebp,ebp
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov word ptr ds:tss_es,es
    mov word ptr ds:tss_cs,cs
    mov word ptr ds:tss_ss,ss
    mov word ptr ds:tss_gs,gs
;
    pop dword ptr ds:tss_edx
    pop eax
    mov dword ptr ds:tss_eax,eax
;
    pop word ptr ds:tss_ds
    pop word ptr ds:tss_fs
    pop bp
    pop dx
    movzx edx,dx
    mov dword ptr ds:tss_eip,edx
    mov dword ptr ds:tss_esp,esp
    mov edx,dword ptr ds:tss_edx
    jmp save_locked_thread_setup

save_locked_thread_skip:
    pop edx
    pop eax
    add sp,4
    pop bp
    add sp,2

save_locked_thread_setup:
    push ax
    mov ax,task_sel
    mov ds,ax
    pop ax
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
    push bp
;
    xor bp,bp
    mov es,bp
    mov gs,bp    
    ret
SaveLockedThread   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SkipCurrentThread
;
;           DESCRIPTION:    Skip current thread (no save of registers)
;
;       RETURNS:    SS:SP       Processor stack
;               DS      Task sel
;               FS      Processor selector
;               ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SkipCurrentThread       Proc near       
    push ax
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    pop ax
;
    push eax
    cli    
    call ds:update_clock_proc
    LocalGetSystemTime
    sti
    push ds
    mov ds,fs:ps_curr_thread
    sub eax,fs:ps_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    pop ds
    pop eax
;    
    pop bp
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
    push bp
;
    xor bp,bp
    mov es,bp
    mov gs,bp    
    ret
SkipCurrentThread   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ContinueCurrentThread
;
;           DESCRIPTION:    Continue current thread, by putting it into the ready-list.
;               Also releases scheduler lock
;
;       PARAMETERS:     FS      Processor selector
;               DS      Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ContinueCurrentThread:
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz cctDone
;
    push es
    mov es,ax
    mov di,es:p_prio
    cmp ax,fs:ps_null_thread
    je cctPop
;    
    InsertFirst
    cmp di,ds:prio_act
    jbe cctPop
;
    mov ds:prio_act,di
    or fs:ps_flags,PS_FLAG_PRIO_CHANGE

cctPop:
    pop es    

cctDone:
    mov fs:ps_curr_thread,0
    jmp LoadCurrentThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           BlockCurrentThread
;
;           DESCRIPTION:    Block current thread.
;               Also releases scheduler lock
;
;           PARAMETERS:         AX:EDI      Block list. AX = 0, no sleep list
;               FS      Processor selector
;               DS      Task sel
;
;       RETURNS:    ES      Blocked thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BlockCurrentThread:
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    mov es:p_sleep_sel,ax
    mov es:p_sleep_offset,edi
;
    or ax,ax
    jz bctUnlock
;    
    push ds
    call ds:lock_list_proc      
    mov ds,ax
    InsertBlock32
    pop ds
    call ds:unlock_list_proc

bctUnlock:      
    jmp LoadCurrentThread

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReloadTimer
;
;           DESCRIPTION:    Reload timer
;
;       PARAMETERS:     DS      Task sel
;               FS      Processor sel
;               CY      Lock succeeded
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReloadTimer Proc near
    jc reload_timer_loop
;
    or fs:ps_flags,PS_FLAG_TIMER    
    mov eax,fs:ps_mask
    lock or ds:processor_preempt,eax
    jmp reload_timer_done

reload_timer_loop:
    mov eax,fs:ps_mask
    not eax
    lock and ds:processor_preempt,eax
;    
    and fs:ps_flags,NOT PS_FLAG_TIMER   
    mov es,fs:ps_curr_thread
    cli
    call ds:update_clock_proc
    LocalGetSystemTime
    add eax,ds:update_tics
    adc edx,0
    mov bx,fs:ps_timer_head
    mov ecx,fs:ps_preempt_msb
    cmp ecx,fs:[bx].ps_timer_msb
    jc reload_check_preempt
    jnz reload_check_timer
;       
    mov ecx,fs:ps_preempt_lsb
    cmp ecx,fs:[bx].ps_timer_lsb
    jc reload_check_preempt

reload_check_timer:
    sub eax,fs:[bx].ps_timer_lsb
    sbb edx,fs:[bx].ps_timer_msb
    jc reload_timer_do
;       
    LocalRemoveTimer
    jmp reload_timer_loop

reload_check_preempt:
    sub eax,fs:ps_preempt_lsb
    sbb edx,fs:ps_preempt_msb
    jc reload_timer_do
;
    or fs:ps_flags,PS_FLAG_PREEMPT
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz reload_preempt_block
;    
    push OFFSET reload_timer_end
    call SaveLockedThread
    jmp ContinueCurrentThread

reload_preempt_block:
    cli
    call ds:update_clock_proc
    LocalGetSystemTime
    sti
    add eax,1193
    adc edx,0
    mov fs:ps_preempt_lsb,eax
    mov fs:ps_preempt_msb,edx
    jmp reload_timer_loop

reload_timer_do:
    neg eax
    ReloadSysTimer
;       call ds:reload_timer_proc

reload_timer_done:
    call ds:unlock_proc

reload_timer_end:       
    ret
ReloadTimer Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartProcessor
;
;           DESCRIPTION:    Start processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_processor_name    DB 'Start Processor', 0

start_processor:
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    StartSysTimer
    or fs:ps_flags,PS_FLAG_PREEMPT    
    jmp LoadCurrentThread
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteThread
;
;           DESCRIPTION:    Delete a thread
;
;       PARAMETERS:     ES      Thread block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteThread    Proc near
    push es
    mov es,es:p_tss_data_sel
    mov es,es:tss_ess0
    FreeMem
    pop es
;
    mov bx,es:p_tss_sel
    FreeGdt
;
    mov bx,es:p_tss_data_sel
    FreeMem
;
    FreeMem
    ret
DeleteThread    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteProcess
;
;           DESCRIPTION:    Delete a process
;
;       PARAMETERS:     ES      Thread block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteProcess    Proc near
    mov ax,es:p_process_sel
    push es
    mov es,ax
    FreeMem
    pop es
;
    cli
    mov bx,es
    mov ax,process_dir_sel
    mov ds,ax
    mov esi,alias_linear
    shr esi,20
    mov eax,es:p_cr3
    mov [si],eax
    mov eax,cr3
    mov cr3,eax
;
    mov ax,flat_sel
    mov ds,ax
    mov cx,400h
    mov edx,handle_linear
    shr edx,10
    add edx,alias_linear

cleanup_process_linear_loop:
    mov eax,[edx]
    test al,1
    jz cleanup_process_linear_next
;
    FreePhysical

cleanup_process_linear_next:
    add edx,4
    loop cleanup_process_linear_loop
;
    mov ax,process_page_sel
    mov ds,ax
    mov edx,handle_linear
    shr edx,10
    add edx,alias_linear
    shr edx,10
    mov eax,[edx]
    FreePhysical
;
    mov eax,es:p_cr3
    FreePhysical
;
    sti
    push es
    mov es,es:p_tss_data_sel
    mov es,es:tss_ess0
    FreeMem
    pop es
;
    mov bx,es:p_tss_data_sel
    FreeGdt
;
    mov bx,es:p_tss_sel
    FreeGdt
;
    FreeMem
    ret
DeleteProcess   Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           System thread
;
;           DESCRIPTION:    Cleans up threads & processes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

system_thread_name  DB 'System', 0

system_thread_pr:
    mov ax,task_sel
    mov ds,ax
    GetThread
    mov ds:system_thread,ax

stLoop:
    WaitForSignal

stThreadLoop:
    mov si,OFFSET term_thread_list
    mov ax,[si]
    or ax,ax
    jz stThreadOK
;
    call ds:lock_list_proc
    RemoveBlock
    call ds:unlock_list_proc
    call DeleteThread
    jmp stThreadLoop

stThreadOk:
    mov si,OFFSET term_proc_list
    mov ax,[si]
    or ax,ax
    jz stLoop
;
    call ds:lock_list_proc
    RemoveBlock
    call ds:unlock_list_proc
    call DeleteProcess
    jmp stThreadLoop
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartProcessorNullThreads
;
;           DESCRIPTION:    Start each of the null threads for a processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    public start_processor_null_threads

start_processor_null_threads    Proc near
    mov ax,task_sel
    mov ds,ax
    mov ds:try_lock_proc,OFFSET TryLockSingle
    mov ds:lock_proc,OFFSET LockSingle
    mov ds:unlock_proc,OFFSET UnlockSingle
    mov ds:load_unlock_proc,OFFSET LoadUnlockSingle
    mov ds:lock_list_proc,OFFSET LockListSingle
    mov ds:unlock_list_proc,OFFSET UnlockListSingle
    mov cx,ds:processor_count
    cmp cx,1
    jbe start_locks_ok
;
    mov ds:try_lock_proc,OFFSET TryLockMultiple
    mov ds:lock_proc,OFFSET LockMultiple
    mov ds:unlock_proc,OFFSET UnlockMultiple
    mov ds:load_unlock_proc,OFFSET LoadUnlockMultiple
    mov ds:lock_list_proc,OFFSET LockListMultiple
    mov ds:unlock_list_proc,OFFSET UnlockListMultiple

start_locks_ok:    
    mov ecx,200h
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET system_thread_pr
    mov di,OFFSET system_thread_name
    mov ax,1
    CreateThread
;    
    mov eax,10
    AllocateSmallGlobalMem
    xor di,di
    mov eax,cs:dword ptr null_base
    stosd
    mov al,' '
    stosb
    mov al,'1'
    stosb
    xor al,al
    stosb
;
    mov ax,task_sel
    mov ds,ax
    mov cx,ds:processor_count
    mov bx,OFFSET processor_arr
;
    add bx,2
    sub cx,1
    jz start_processor_free

create_null_loop:
    push ds
    push cx
;    
    mov ax,cs
    mov ds,ax
    xor ax,ax
    mov ecx,200h
    mov si,OFFSET null_thread
    xor di,di
    CreateThread
;
    pop cx
    pop ds
    mov di,5
    inc byte ptr es:[di]
;    
    add bx,2
    loop create_null_loop

start_processor_free:
    FreeMem
    ret
start_processor_null_threads    Endp

null_base   DB 'Null'

    public null_thread0

null_thread0:
    mov ax,task_sel
    mov ds,ax
    call ds:get_cpu_proc
    GetThread
    mov es,ax
    mov es:p_sleep_sel,fs
    mov es:p_sleep_offset,0
    mov fs:ps_null_thread,ax
;    mov fs:ps_skip_thread,ax
;
    push OFFSET null_loop
    call SaveCurrentThread
;    
    xor ax,ax
    xor edi,edi
    jmp BlockCurrentThread

null_thread:
    sti
    mov ax,task_sel
    mov ds,ax
    mov fs,ds:[bx]
    GetThread
    mov es,ax
    mov es:p_sleep_sel,fs
    mov es:p_sleep_offset,0
    mov fs:ps_null_thread,ax
;    mov fs:ps_skip_thread,ax
;
    ResumeProcessor
    push OFFSET null_loop
    call SaveCurrentThread
;
    xor ax,ax
    xor edi,edi
    jmp BlockCurrentThread
    
null_loop:
    hlt
    jmp null_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WakeThread
;
;           DESCRIPTION:    Wake up thread
;
;           PARAMETERS:         DX:ESI      Thread list
;                           EAX             Status to thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WakeThread      PROC near
    push ds
    push es
    push fs
    push bx
    push di
;    
    mov es,dx
    mov bx,task_sel
    mov ds,bx
    call ds:try_lock_proc
;
    mov di,es:[esi]
    or di,di
    jz wtUnlock
;       
    call ds:lock_list_proc
;
    push ds
    mov ds,dx    
    RemoveBlock32
    mov es:p_data,eax
    pop ds
;
    mov di,OFFSET wakeup_list
    InsertBlock
;       
    mov ds:has_list,1
    call ds:unlock_list_proc
    
wtUnlock:    
    call ds:unlock_proc
;
    pop di
    pop bx
    pop fs
    pop es      
    pop ds
    ret
WakeThread      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShutdownLocal
;
;           DESCRIPTION:    Shutdown
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShutdownLocal proc near
    push ds
    push fs
;
    mov ax,wd_code_sel
    verr ax
    jnz slDo
;
    cli
    CpuReset

slDo:
    mov ax,task_sel
    mov ds,ax
    call ds:get_cpu_proc
    mov ds,fs:ps_null_thread 
    mov ds,ds:p_tss_data_sel  
;    
    mov dword ptr ds:tss_ebx,ebx
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_edx,edx
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov dword ptr ds:tss_ebp,ebp
;
    pop ax
    mov ds:tss_fs,ax
;
    pop ax      
    mov ds:tss_ds,ax
;
    mov ax,es
    mov ds:tss_es,ax
    mov ax,gs
    mov ds:tss_gs,ax
;
    pushfd
    pop dword ptr ds:tss_eflags
;       
    mov ax,cs
    mov ds:tss_cs,ax
    pop ax
    movzx eax,ax
    mov dword ptr ds:tss_eip,eax
;
;   pop ax
;       mov dword ptr ds:tss_eax,eax
;
    mov ax,ss
    mov ds:tss_ss,ax
;    
    mov ax,sp
    movzx eax,ax
    mov dword ptr ds:tss_esp,eax
;       
    mov es,fs:ps_null_thread 
    mov ax,task_sel
    mov ds,ax
    mov es:p_error_code,3
;
    mov ax,system_data_sel
    mov ds,ax
    mov di,OFFSET debug_list
    InsertBlock
    ShutDownTask
ShutdownLocal    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Shutdown
;
;           DESCRIPTION:    Shutdown
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shutdown_name   DB 'Shutdown', 0

shutdown_pr proc far
    push ds
    push fs
;
    push eax
;
    mov ax,wd_code_sel
    verr ax
    jnz spDo
;
    cli
    CpuReset

spDo:
    mov ax,task_sel
    mov ds,ax
    mov ecx,ds:processor_preempt
    call ds:get_cpu_proc
    mov ds,fs:ps_null_thread 
    mov ds,ds:p_tss_data_sel  
    pop dword ptr ds:tss_eax
;    
    mov dword ptr ds:tss_ebx,ebx
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_edx,edx
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov dword ptr ds:tss_ebp,ebp
;
    pop ax
    mov ds:tss_fs,ax
;
    pop ax      
    mov ds:tss_ds,ax
;
    mov ax,es
    mov ds:tss_es,ax
    mov ax,gs
    mov ds:tss_gs,ax
;
    add sp,4
    pop dword ptr ds:tss_eip
    pop eax
    mov word ptr ds:tss_cs,ax
    pop dword ptr ds:tss_eflags
;
    mov ax,ss
    mov ds:tss_ss,ax
;    
    mov ax,sp
    movzx eax,ax
    mov dword ptr ds:tss_esp,eax
;       
    mov es,fs:ps_null_thread 
    mov ax,task_sel
    mov ds,ax
    mov es:p_error_code,3
;
    mov ax,system_data_sel
    mov ds,ax
    mov di,OFFSET debug_list
    InsertBlock
    ShutDownTask
shutdown_pr    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugException / LockedDebugException
;
;           DESCRIPTION:    Save current state from stack + local registers
;
;       PARAMETERS:     SS:BP       Exception stack
;                       AL      Fault vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_exception_name        DB 'Debug Exception', 0
locked_debug_exception_name     DB 'Locked Debug Exception', 0

locked_debug_exception:
    movzx ax,al
    push fs
    push ax
    mov ax,task_sel
    mov ds,ax
    pop ax
    call ds:get_cpu_proc
    jmp debug_normal

debug_exception:
    movzx ax,al
    push fs
    push ax
    mov ax,task_sel
    mov ds,ax
    pop ax
    call ds:try_lock_proc
    jc debug_normal

debug_fault:
    push ax
    mov ax,wd_code_sel
    verr ax
    pop ax
    jnz dfDo
;
    cli
    CpuReset

dfDo:
    mov ds,fs:ps_null_thread 
    mov ds:p_error_code,ax
    mov ds,ds:p_tss_data_sel  
;    
    mov eax,[bp].vm_eax
    mov dword ptr ds:tss_eax,eax
    mov eax,[bp].vm_ebx
    mov dword ptr ds:tss_ebx,eax
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_edx,edx
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov eax,ebp
    mov ax,[bp]
    mov dword ptr ds:tss_ebp,eax
;       
    mov eax,[bp].vm_eflags
    mov dword ptr ds:tss_eflags,eax
    mov ax,[bp].vm_cs
    mov ds:tss_cs,ax
    mov eax,[bp].vm_eip
    mov dword ptr ds:tss_eip,eax
;
    mov ax,ss
    mov ds:tss_ss,ax
    mov ax,bp
    add ax,vm_esp
    movzx eax,ax
    mov dword ptr ds:tss_esp,eax
;       
    mov ax,[bp].pm_ds
    mov ds:tss_ds,ax
    mov ax,es
    mov ds:tss_es,ax
;
    pop ax      
    mov ds:tss_fs,ax
;       
    mov ax,gs
    mov ds:tss_gs,ax
;
    mov ax,task_sel
    mov ds,ax
    mov es,fs:ps_null_thread
;
    mov ax,system_data_sel
    mov ds,ax
    mov di,OFFSET debug_list
    InsertBlock
    ShutDownTask
   
debug_normal:       
    push ax
    mov ax,fs:ps_curr_thread 
    or ax,ax
    pop ax
    jz debug_fault
;    
    mov ds,fs:ps_curr_thread 
    mov ds:p_error_code,ax
    mov ds,ds:p_tss_data_sel
;
    mov eax,[bp].vm_eax
    mov dword ptr ds:tss_eax,eax
    mov eax,[bp].vm_ebx
    mov dword ptr ds:tss_ebx,eax
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_edx,edx
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov eax,ebp
    mov ax,[bp]
    mov dword ptr ds:tss_ebp,eax
;       
    mov eax,[bp].vm_eflags
    mov dword ptr ds:tss_eflags,eax
    mov ax,[bp].vm_cs
    mov ds:tss_cs,ax
    mov eax,[bp].vm_eip
    mov dword ptr ds:tss_eip,eax
;       
    pop si
    test dword ptr [bp].vm_eflags,20000h
    jnz debug_vm

debug_pm:
    mov al,[bp].vm_cs
    test al,3
    jz debug_kernel
;
    mov ax,[bp].vm_ss
    mov ds:tss_ss,ax
    mov eax,[bp].vm_esp
    mov dword ptr ds:tss_esp,eax
    jmp debug_pm_common
    
debug_kernel:
    mov ax,ss
    mov ds:tss_ss,ax
    mov ax,bp
    add ax,vm_esp
    movzx eax,ax
    mov dword ptr ds:tss_esp,eax
    
debug_pm_common:
    mov ax,[bp].pm_ds
    mov ds:tss_ds,ax
    mov ax,es
    mov ds:tss_es,ax
    mov ds:tss_fs,si
    mov ax,gs
    mov ds:tss_gs,ax
    jmp debug_save_ok

debug_vm:
    mov ax,[bp].vm_gs
    mov ds:tss_gs,ax
    mov ax,[bp].vm_fs
    mov ds:tss_fs,ax
    mov ax,[bp].vm_ds
    mov ds:tss_ds,ax
    mov ax,[bp].vm_es
    mov ds:tss_es,ax
    mov ax,[bp].vm_ss
    mov ds:tss_ss,ax
    mov eax,[bp].vm_esp
    mov dword ptr ds:tss_esp,eax

debug_save_ok:
    mov ax,task_sel
    mov ds,ax
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
;
    xor ax,ax
    mov es,ax
    mov gs,ax    
;
    mov ax,fs:ps_curr_thread
    cmp ax,fs:ps_null_thread
    jne debug_block
;
    mov es,ax
    mov ax,wd_code_sel
    verr ax
    jnz dbDo
;
    cli
    CpuReset

dbDo:
    mov ax,system_data_sel
    mov ds,ax
    mov di,OFFSET debug_list
    InsertBlock
    ShutDownTask
    
debug_block:
    mov es,fs:ps_curr_thread
    mov eax,es:p_debug_proc
    or eax,eax
    jz debug_block_do
;
    call es:p_debug_proc

debug_block_do:
    mov ax,system_data_sel
    mov edi,OFFSET debug_list       
    jmp BlockCurrentThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoubleFault
;
;           DESCRIPTION:    Handle double fault exception (from task-gate)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public double_fault
    
double_fault:
    pushf
    pop ax
    and ax,NOT 4000h
    push ax
    popf
;       
    mov ax,gdt_sel
    mov ds,ax
    mov bx,double_tss_sel
    and byte ptr ds:[bx+5],NOT 2
;    
    mov ax,task_sel
    mov ds,ax
    call ds:try_lock_proc
    jc double_fault_lock_ok
;    
    mov ax,fs:ps_curr_thread
    or ax,ax
    jnz double_fatal_thread
    jmp double_fatal_no_thread
    
double_fault_lock_ok:    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
;
    xor ax,ax
    mov es,ax
    mov gs,ax    
;
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz double_block

double_fatal_no_thread:
    mov ax,double_tss_data_sel
    mov ds,ax
    mov bx,ds:tss_back_link
;
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    inc ecx
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
;       
    AllocateGdt
    CreateDataSelector16
    mov ds,bx
;    
    mov esi,dword ptr ds:tss_cs
    mov edi,dword ptr ds:tss_eip
    mov eax,dword ptr ds:tss_ss
    mov edx,dword ptr ds:tss_esp
    call ShutdownLocal

double_fatal_thread:
    mov ds,fs:ps_null_thread 
    mov es,ds:p_tss_data_sel  
;
    mov ax,double_tss_data_sel
    mov ds,ax
    mov bx,ds:tss_back_link
;
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    inc ecx
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
;       
    AllocateGdt
    CreateDataSelector16
    mov ds,bx
;    
    mov eax,dword ptr ds:tss_eax
    mov dword ptr es:tss_eax,eax
;
    mov eax,dword ptr ds:tss_ebx
    mov dword ptr es:tss_ebx,eax
;
    mov eax,dword ptr ds:tss_ecx
    mov dword ptr es:tss_ecx,eax
;
    mov eax,dword ptr ds:tss_edx
    mov dword ptr es:tss_edx,eax
;
    mov eax,dword ptr ds:tss_esi
    mov dword ptr es:tss_esi,eax
;
    mov eax,dword ptr ds:tss_edi
    mov dword ptr es:tss_edi,eax
;
    mov eax,dword ptr ds:tss_ebp
    mov dword ptr es:tss_ebp,eax
;
    mov ax,ds:tss_ds
    mov es:tss_ds,ax
;
    mov ax,ds:tss_es
    mov es:tss_es,ax
;
    mov ax,ds:tss_fs
    mov es:tss_fs,ax
;
    mov ax,ds:tss_gs
    mov es:tss_gs,ax
;
    mov ax,ds:tss_ss
    mov es:tss_ss,ax
;
    mov eax,dword ptr ds:tss_esp
    mov dword ptr ds:tss_esp,eax
;
    mov ax,ds:tss_cs
    mov es:tss_cs,ax
;
    mov eax,dword ptr ds:tss_eip           
    mov dword ptr es:tss_eip,eax
;
    mov eax,dword ptr ds:tss_eflags
    mov dword ptr es:tss_eflags,eax
;
    mov es,fs:ps_null_thread 
    mov ax,task_sel
    mov ds,ax
;       
    mov es:p_error_code,8
    mov ax,es:tss_ss
    verw ax
    jz double_stack_ok
;
    mov es:p_error_code,12

double_stack_ok:
    mov ax,wd_code_sel
    verr ax
    jnz double_stack_do
;
    cli
    CpuReset

double_stack_do:
    mov ax,system_data_sel
    mov ds,ax
    mov di,OFFSET debug_list
    InsertBlock
    ShutDownTask
    
double_block:
    mov es,ax    
    mov es:p_error_code,8
;
    mov ax,system_data_sel
    mov edi,OFFSET debug_list       
    jmp BlockCurrentThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateProcessor
;
;           DESCRIPTION:    Create processor
;
;       PARAMETERS:     ES:DI   Get processor callback
;
;       RETURNS:    AX      Processor #
;               ES      Processor sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_processor_name   DB 'Create Processor',0

create_processor    Proc far
    push ds
    push bx
    push cx
    push si
;    
    mov ax,task_sel
    mov ds,ax
    mov word ptr ds:get_cpu_proc,di
    mov word ptr ds:get_cpu_proc+2,es
;    
    mov eax,SIZE processor_seg
    AllocateSmallGlobalMem
;
    push es
    mov eax,200h    
    AllocateSmallGlobalMem
    mov ax,es
    pop es
    mov es:ps_ss,ax
    mov es:ps_sp,200h
;
    mov ax,task_sel
    mov ds,ax
    mov ax,ds:processor_count
    mov si,ax
    add si,si
    mov [si].processor_arr,es
    inc ds:processor_count
;
    mov es:ps_id,ax     
    mov cl,al
    mov eax,1
    shl eax,cl
    mov es:ps_mask,eax
;
    mov es:ps_nesting,-1
    mov es:ps_curr_thread,0
    mov es:ps_last_thread,-1
    mov es:ps_flags,0
    mov es:ps_null_thread,0
    mov es:ps_skip_thread,-1
    mov es:ps_apic,-1
    mov es:ps_wait,0
    mov es:ps_last_lsb,0
;
    mov bx,OFFSET ps_timer_entries
    mov es:[bx].ps_timer_next,0
    mov es:[bx].ps_timer_msb,0FFFFFFFFh
    mov es:[bx].ps_timer_lsb,0FFFFFFFFh
    mov es:ps_timer_head,bx
;       
    mov cx,0FFh
    add bx,SIZE timer_struc
    mov es:ps_timer_free,bx
timer_free_list_create:
    mov ax,bx
    add ax,SIZE timer_struc
    mov es:[bx].ps_timer_next,ax
    mov bx,ax
    loop timer_free_list_create
;
    mov ax,es:ps_id     
;
    pop si
    pop cx
    pop bx
    pop ds      
    ret
create_processor    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetTaskLock
;
;       DESCRIPTION:    Get state of task lock
;
;       RETURNS:        AX  Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_task_lock
    
get_task_lock   Proc near
    push ds
    push fs
    mov ax,task_sel
    mov ds,ax
    call ds:get_cpu_proc
    mov ax,fs:ps_nesting
    pop fs
    pop ds
    ret
get_task_lock    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProcessorSingle
;
;           DESCRIPTION:    Get current processor selector (single processor version)
;
;       RETURNS:    FS      Processor sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_processor_single    Proc far
    push ax
    mov ax,task_sel
    mov fs,ax
    mov fs,fs:processor_arr
    pop ax
    ret
get_processor_single    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProcessor
;
;           DESCRIPTION:    Get current processor selector
;
;       RETURNS:    FS      Processor sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_processor_name      DB 'Get Processor',0

get_processor   Proc far
    push ds
    push ax
;
    mov ax,task_sel
    mov ds,ax
    call ds:get_cpu_proc
;
    pop ax
    pop ds
    ret
get_processor   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateLists
;
;           DESCRIPTION:    Update lists (signals + wakeup)
;
;       PARAMETERS:     DS      Task_sel
;               FS      Processor sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLists Proc near

ulWakeupLoop:
    mov ds:has_list,0
    call ds:lock_list_proc
    mov si,OFFSET wakeup_list
    mov ax,[si]
    or ax,ax
    jz ulWakeupDone
;
    RemoveBlock
    mov di,es:p_prio
    InsertBlock
    cmp di,ds:prio_act
    jbe ulWakeupPrioOk
;       
    mov ds:prio_act,di
    or fs:ps_flags,PS_FLAG_PRIO_CHANGE

ulWakeupPrioOk:
    call ds:unlock_list_proc
    jmp ulWakeupLoop

ulWakeupDone:
    call ds:unlock_list_proc
;    
    mov ds:has_signal,0
    mov si,OFFSET signal_list
    mov ax,[si]
    or ax,ax
    jz ulSignalDone
;       
    mov dx,ax

ulSignalLoop:
    mov es,dx
    mov cl,es:p_signal
    or cl,cl
    jz ulSignalNext
;
    call ds:lock_list_proc
    mov [si],dx
    RemoveBlock
    mov di,es:p_prio
    InsertBlock
    cmp di,ds:prio_act
    jbe ulSignalPrioOk
;       
    mov ds:prio_act,di
    or fs:ps_flags,PS_FLAG_PRIO_CHANGE

ulSignalPrioOk:
    call ds:unlock_list_proc
;    
    mov si,OFFSET signal_list
    mov ax,[si]
    or ax,ax
    jz ulSignalDone
;       
    mov dx,ax
    jmp ulSignalLoop

ulSignalNext:   
    mov dx,es:p_next
    cmp dx,ax
    jne ulSignalLoop

ulSignalDone:    
    ret    
UpdateLists Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockListSingle
;
;           DESCRIPTION:    Lock list, single processor version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockListSingle  Proc near
    cli
    ret
LockListSingle  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockListSingle
;
;           DESCRIPTION:    Unlock list, single processor version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockListSingle    Proc near
    sti
    ret
UnlockListSingle    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockListMultiple
;
;           DESCRIPTION:    Lock list, multiple processor version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockListMultiple    Proc near
    push ax

llSpinLock:    
    sti
    mov ax,ds:list_lock
    or ax,ax
    je llGet
;
    pause
;    call ShutdownLocal
    jmp llSpinLock

llGet:
    cli
    inc ax
    xchg ax,ds:list_lock
    or ax,ax
    je llDone
;
;    call ShutdownLocal
    jmp llSpinLock

llDone:
    pop ax    
    ret
LockListMultiple    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockListMultiple
;
;           DESCRIPTION:    Unlock list, multiple processor version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockListMultiple      Proc near
    mov ds:list_lock,0
    sti
    ret
UnlockListMultiple      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TryLockDefault
;
;           DESCRIPTION:    Try to lock, pre-tasking version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TryLockDefault  Proc near
    call ds:get_cpu_proc
    add fs:ps_nesting,1
    stc
    ret
TryLockDefault  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockDefault
;
;           DESCRIPTION:    Lock, pre-tasking version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockDefault     Proc near
    call ds:get_cpu_proc
    add fs:ps_nesting,1
    stc
    ret
LockDefault     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockDefault
;
;           DESCRIPTION:    Unlock, pre-tasking version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockDefault   Proc near
    sub fs:ps_nesting,1
    ret
UnlockDefault   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadUnlockDefault
;
;           DESCRIPTION:    Thread load unlock, pre-tasking version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadUnlockDefault       Proc near
    sub fs:ps_nesting,1
    ret
LoadUnlockDefault       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TryLockSingle
;
;           DESCRIPTION:    Try to lock, single processor version
;
;       PARAMETERS:     DS      Task_sel
;
;       RETURNS:    CY      Owner of section
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TryLockSingle   Proc near
    call ds:get_cpu_proc
    add fs:ps_nesting,1
    ret
TryLockSingle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockSingle
;
;           DESCRIPTION:    Lock, single processor version
;
;       PARAMETERS:     DS      Task_sel
;
;       RETURNS:    CY      Owner of section
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockSingle      Proc near
    call ds:get_cpu_proc
    add fs:ps_nesting,1
    jc lsDone
;
    call ShutdownLocal

lsDone:     
    ret
LockSingle      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockSingle
;
;           DESCRIPTION:    Unlock, single processor version
;
;       PARAMETERS:     DS      Task_sel
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockSingle    Proc near
    push ax
    
tusRetry:    
    cli
    sub fs:ps_nesting,1
    jnc tusDone
;
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz tusDone
;    
    test fs:ps_flags,PS_FLAG_TIMER      
    jnz tusSwap
;    
    mov al,ds:has_signal
    or al,ds:has_list
    jz tusDone

tusSwap:
    add fs:ps_nesting,1
    jnc tusRetry
;
    sti
    push OFFSET tusDone
    call SaveLockedThread
    jmp ContinueCurrentThread

tusDone:
    sti
    pop ax
    ret
UnlockSingle    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadUnlockSingle
;
;           DESCRIPTION:    Thread load unlock, single processor version
;
;       PARAMETERS:     DS      Task_sel
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadUnlockSingle    Proc near
    cli
    sub fs:ps_nesting,1
    jc lulsDone
;
    mov cx,fs:ps_nesting
    call ShutdownLocal

lulsDone:       
    ret
LoadUnlockSingle    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WakeProcessor
;
;           DESCRIPTION:    Wake up a processor
;
;       PARAMETERS:     DS      Task_sel
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WakeProcessor   Proc near
    push fs
    push ax
    push bx
    push cx
;
    mov cx,ds:processor_count
    mov bx,OFFSET processor_arr
;
    mov al,'o'
    call ShowDebug

wpLoop:
    mov fs,[bx]
    xor ax,ax
    xchg ax,fs:ps_wait
    or ax,ax
    jz wpNext
;
    push ax
    mov al,'r'
    call ShowDebug
    pop ax
;
    ResumeProcessor
    jmp wpDone

wpNext:
    add bx,2
    loop wpLoop
;
    mov al,'q'
    call ShowDebug

wpDone:    
    pop cx
    pop bx
    pop ax
    pop fs    
    ret
WakeProcessor   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowDebug
;
;           DESCRIPTION:    Show debug char
;
;       PARAMETERS:         FS      Processor
;                           AL      Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowDebug   Proc near
    push ds
    push fs
    push bx
;
    mov bx,task_sel
    mov ds,bx
    call ds:get_cpu_proc
;        
    mov bx,__B800
    mov ds,bx
    mov bx,fs:ps_id
    add bx,50
    add bx,bx
    mov ah,7
    mov ds:[bx],ax
;
    pop bx
    pop fs
    pop ds
    ret
ShowDebug   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowProcDebug
;
;           DESCRIPTION:    Show processor debug char
;
;       PARAMETERS:         AL      Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_proc_debug_name    DB 'Show Processor Debug',0

show_proc_debug   Proc far
    push ds
    push fs
    push bx
;
    mov bx,task_sel
    mov ds,bx
    call ds:get_cpu_proc
;        
    mov bx,__B800
    mov ds,bx
    mov bx,fs:ps_id
    add bx,50
    add bx,bx
    mov ah,7
    mov ds:[bx],ax
;
    pop bx
    pop fs
    pop ds
    ret
show_proc_debug   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowDebugStop
;
;           DESCRIPTION:    Show debug char, and stop
;
;       PARAMETERS:         FS      Processor
;                           AL      Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowDebugStop   Proc near
    push ds
    push bx
;
    mov bx,fs:ps_nesting
    or bx,bx
    jz  sdsDone
;       
    cli
    mov bx,__B800
    mov ds,bx
    mov bx,fs:ps_id
    add bx,50
    add bx,bx
    mov ah,7
    mov ds:[bx],ax
sdsLoop:
    jmp sdsLoop

sdsDone:
    pop bx
    pop ds
    ret
ShowDebugStop   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TryLockMultiple
;
;           DESCRIPTION:    Try to lock, multiple processor version
;
;       PARAMETERS:     DS      Task_sel
;
;       RETURNS:    CY      Owner of section
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
TryLockMultiple Proc near
    push ax
    push dx

tlmSpinLock:
    sti
    mov ax,ds:owner_lock
    or ax,ax
    jz tlmGet
;
    pause
    jmp tlmSpinLock

tlmGet:
    cli
    inc ax
    xchg ax,ds:owner_lock
    or ax,ax
    jnz tlmSpinLock
;
    call ds:get_cpu_proc
;
    mov al,'1'
    call ShowDebug
;    
    mov ax,ds:owner_sel
    or ax,ax
    jz tlmTake
;
    mov dx,fs
    cmp ax,dx
    je tlmTake

tlmFail:
    mov al,'2'
    call ShowDebug
;
    add fs:ps_nesting,1
    mov ds:owner_lock,0
    clc
    jmp tlmDone

tlmTake:
    mov al,'A'
    call ShowDebug
;
    mov ds:owner_sel,fs
    add fs:ps_nesting,1
    mov ds:owner_lock,0    

tlmDone:
    sti
;
    pop dx
    pop ax
    ret
TryLockMultiple Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockMultiple
;
;           DESCRIPTION:    Lock, multiple processor version
;
;       PARAMETERS:     DS      Task_sel
;
;       RETURNS:    CY      Owner of section
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockMultiple    Proc near
    push ax
    push dx

lmSpinLock:
    sti
    mov ax,ds:owner_lock
    or ax,ax
    jz lmGet
;
    pause
    jmp lmSpinLock

lmGet:
    cli
    inc ax
    xchg ax,ds:owner_lock
    or ax,ax
    jnz lmSpinLock
;
    call ds:get_cpu_proc
    mov al,'4'
    call ShowDebug
;    
    mov ax,ds:owner_sel
    or ax,ax
    jz lmTake
;
    mov dx,fs
    cmp ax,dx
    je lmTake

lmHalt:
    mov al,'5'
    call ShowDebug
    
    inc ds:owner_wait
    mov fs:ps_wait,1
    mov ds:owner_lock,0
    sti
    hlt
    mov fs:ps_wait,0
;    
    mov al,'6'
    call ShowDebug
    jmp lmSpinLock

lmTake:
    mov al,'A'
    call ShowDebug
    
    mov ds:owner_sel,fs
    add fs:ps_nesting,1
    mov ds:owner_lock,0    
    sti
;
    pop dx
    pop ax
    ret
LockMultiple    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockMultiple
;
;           DESCRIPTION:    Unlock, multiple processor version
;
;       PARAMETERS:     DS      Task_sel
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockMultiple  Proc near
    push eax

    mov al,'a'
    call ShowDebug

tumSpinLock:
    sti
    mov ax,ds:owner_lock
    or ax,ax
    jz tumGet
;
    pause
    jmp tumSpinLock

tumGet:
    cli
    inc ax
    xchg ax,ds:owner_lock
    or ax,ax
    jnz tumSpinLock
    
tumRetry:    
    mov al,'b'
    call ShowDebug


    sub fs:ps_nesting,1
    jnc tumUnlock
;
    mov ax,fs
    cmp ax,ds:owner_sel
    jne tumUnlock
;
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz tumWake
;
    test fs:ps_flags,PS_FLAG_TIMER      
    jnz tumSwap
;       
    mov al,ds:has_signal
    or al,ds:has_list
    jz tumWake

tumSwap:
    add fs:ps_nesting,1
    jnc tumRetry
;
    mov ds:owner_lock,0
    sti
    push OFFSET tumDone
    call SaveLockedThread
    jmp ContinueCurrentThread

tumWake:
    mov ds:owner_sel,0  
    mov ds:owner_lock,0
    sti
    mov al,ds:owner_wait
    or al,al
    jz tumUnlock
;
    dec ds:owner_wait    
    call WakeProcessor
    jmp tumUnlockDo

tumUnlock:
    mov al,'c'
    call ShowDebug

    mov eax,fs:ps_mask
    not eax
    and eax,ds:processor_preempt
    jz tumUnlockDo
;
    push fs
    push bx
    mov bx,OFFSET processor_arr

tumPreemptLoop:
    rcr eax,1
    jc tumPreemptDo
;
    add bx,2
    jmp tumPreemptLoop

tumPreemptDo: 
    mov fs,ds:[bx]
    PreemptProcessor
    pop bx
    pop fs

tumUnlockDo:

tumDone:
    mov al,'0'
    call ShowDebug

    sti
    pop eax
    ret
UnlockMultiple  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadUnlockMultiple
;
;           DESCRIPTION:    Thread load unlock, multiple processor version
;
;       PARAMETERS:     DS      Task_sel
;               FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadUnlockMultiple      Proc near
    push eax

    mov al,'z'
    call ShowDebug

lumSpinLock:
    sti
    mov ax,ds:owner_lock
    or ax,ax
    jz lumGet
;
    pause
    jmp lumSpinLock

lumGet:
    cli
    inc ax
    xchg ax,ds:owner_lock
    or ax,ax
    jnz lumSpinLock
;    

    mov al,'y'
    call ShowDebug

    sub fs:ps_nesting,1
    jc lumNestingOk
;
    mov cx,fs:ps_nesting
    pop eax
    pop dx
    mov si,fs
    call ds:get_cpu_proc
    mov di,fs
    call ShutdownLocal

lumNestingOk:
    mov ax,fs
    cmp ax,ds:owner_sel
    je lumOwnerOk
;
    call ShutdownLocal

lumOwnerOk:    
    mov al,'x'
    call ShowDebug

    mov ds:owner_sel,0  
    mov ds:owner_lock,0
    sti
;
    mov al,ds:owner_wait
    or al,al
    jz lumUnlock
;
    mov al,'p'
    call ShowDebug

    dec ds:owner_wait    
    call WakeProcessor

    mov al,'t'
    call ShowDebug

    jmp lumUnlockDo

lumUnlock:
    mov al,'s'
    call ShowDebug

    mov eax,fs:ps_mask
    not eax
    and eax,ds:processor_preempt
    jz lumUnlockDo
;
    push fs
    push bx
    mov bx,OFFSET processor_arr

lumPreemptLoop:
    rcr eax,1
    jc lumPreemptDo
;
    add bx,2
    jmp lumPreemptLoop

lumPreemptDo: 
    mov fs,ds:[bx]
    PreemptProcessor
    pop bx
    pop fs

lumUnlockDo:

lumDone:
    mov al,'0'
    call ShowDebug

    pop eax
    ret
LoadUnlockMultiple      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnterInt
;
;           DESCRIPTION:    Enter interrupt notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_int_name  DB 'Enter Int',0

enter_int       Proc far
    mov ax,task_sel
    mov ds,ax
    call ds:try_lock_proc
    ret
enter_int       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LeaveInt
;
;           DESCRIPTION:    Leave interrupt notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_int_name  DB 'Leave Int',0

leave_int       Proc far
    mov ax,task_sel
    mov ds,ax
    call ds:unlock_proc
    ret
leave_int       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockTask
;
;           DESCRIPTION:    Lock task
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_task_name  DB 'Lock Task',0

lock_task       Proc far
    push ds
    push fs
    push ax
;    
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
;       
    pop ax
    pop fs
    pop ds
    ret
lock_task       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockTask
;
;           DESCRIPTION:    Unlock task
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_task_name    DB 'Unlock Task',0

unlock_task     Proc far
    push ds
    push fs
    push ax
;    
    mov ax,task_sel
    mov ds,ax
    call ds:get_cpu_proc
    call ds:unlock_proc
;
    pop ax
    pop fs
    pop ds      
    ret
unlock_task     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TIMER_INT
;
;           DESCRIPTION:    Timer interrupt handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public timer_int

timer_int:
    push ds
    push es
    push fs
    pushad
;
    in al,INT0_MASK
    or al,1
    out INT0_MASK,al
;
    mov al,20h
    out INT0_CONTROL,al
    mov ax,task_sel
    mov ds,ax
    call ds:try_lock_proc
    call ReloadTimer
;
    popad
    pop fs
    pop es
    pop ds
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoPreemptProcessor
;
;           DESCRIPTION:    Preempt processor from running thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_preempt_processor_name   DB 'Do Preempt Processor', 0

do_preempt_processor    Proc far
    mov ax,task_sel
    mov ds,ax
    call ds:try_lock_proc
    call ReloadTimer
    ret
do_preempt_processor    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           START_TIMER
;
;           DESCRIPTION:    Start a timer
;
;           PARAMETERS:         EDX:EAX     Timeout time
;                           ES:DI       Callback
;                           BX              Owner
;                           CX              ID
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_timer_name DB 'Start Timer',0

start_timer     PROC far
    push ds
    push es
    push fs
    pushad
;
    mov si,task_sel
    mov ds,si
    call ds:try_lock_proc
    cli
    pushf
    LocalStartTimer
    popf
    call ReloadTimer
    sti
;
    popad
    pop fs
    pop es
    pop ds
    ret
start_timer     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           STOP_TIMER
;
;           DESCRIPTION:    Stop timer
;
;           PARAMETERS:         BX              Owner
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_timer_name DB 'Stop Timer',0

stop_timer      PROC far
    push ds
    push es
    push fs
    pushad
;
    mov si,task_sel
    mov ds,si
    call ds:try_lock_proc
    cli
    pushf
    LocalStopTimer
    popf
    call ReloadTimer
    sti
;
    popad
    pop fs
    pop es
    pop ds
    ret
stop_timer      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_first_thread
;
;           DESCRIPTION:    Init first thread
;
;           PARAMETERS:         ES          Thread control block
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_first_thread

init_first_thread:
    mov ds,es:p_tss_data_sel
    mov ax,word ptr ds:tss_ss
    mov word ptr ds:tss_ess0,ax
    mov eax,dword ptr ds:tss_esp
    mov dword ptr ds:tss_esp0,eax
;    
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    mov di,es:p_prio
    mov ds:prio_act,di
    InsertBlock
;
    mov ax,system_data_sel
    mov es,ax
    mov ds:update_tics,0
    mov ds:init_clock_proc,OFFSET InitPitClock
    mov ds:update_clock_proc,OFFSET UpdatePitClock
    mov eax,es:tsc_tics
    or eax,eax
    jz timer_clock_done
;
    mov ds:init_clock_proc,OFFSET InitTscClock
    mov ds:update_clock_proc,OFFSET UpdateTscClock

timer_clock_done:
    StartSysTimer
    mov ds:update_tics,eax
    call ds:init_clock_proc
;
    mov bx,task_sel
    GetSelectorBaseSize
    mov bx,tasking_sel
    CreateDataSelector16
;
    mov bx,task_sel
    mov ds,bx
    call ds:get_cpu_proc
    jmp LoadCurrentThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WAKE_NEW
;
;           DESCRIPTION:    Wake-up a newly create thread
;
;           PARAMETERS:         ES              Thread
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public wake_new

wake_new    PROC near
    pushf
    mov dx,es
    push OFFSET wake_new_done
    call SaveCurrentThread
;
    mov es,dx
    cli
    mov di,es:p_prio
    InsertBlock
    cmp di,ds:prio_act
    jb wake_new_lower
;       
    mov ds:prio_act,di
    or fs:ps_flags,PS_FLAG_PRIO_CHANGE

wake_new_lower:
    jmp ContinueCurrentThread

wake_new_done:
    popf
    ret
wake_new    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SWAP
;
;           DESCRIPTION:    Voluntarily swap. Should not be used!
;
;           PARAMETER:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_name       DB 'Swap',0

swap_out    PROC far
    pushf
    push OFFSET swap_out_done
    call SaveCurrentThread
    jmp ContinueCurrentThread

swap_out_done:
    popf
    retf32
swap_out    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CleanupThread
;
;           DESCRIPTION:    Free resources for current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public cleanup_thread
    
cleanup_thread:
    call SkipCurrentThread
;    
    mov bx,ds:system_thread
    Signal    
;
    mov ax,task_sel
    mov edi,OFFSET term_thread_list
    jmp BlockCurrentThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CleanupProcess
;
;           DESCRIPTION:    Free resources for current process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public cleanup_process
    
cleanup_process:
    call SkipCurrentThread
;    
    mov bx,ds:system_thread
    Signal    
;
    mov ax,task_sel
    mov edi,OFFSET term_proc_list
    jmp BlockCurrentThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WAKE
;
;           DESCRIPTION:    Wake up thread
;
;           PARAMETERS:         DS:SI       Thread list
;                           EAX             Status to thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wake_thread_name    DB 'Wake',0

wake_thread     PROC far
    push dx
    push esi
;    
    mov dx,ds
    movzx esi,si
    call WakeThread
;
    pop esi
    pop dx
    ret
wake_thread     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SLEEP
;
;           DESCRIPTION:    Suspend thread
;
;           PARAMETERS:         DS:DI   Suspend list
;
;           RETURNS:        EAX         Wake-up status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sleep_thread_name       DB 'Sleep',0

sleep_thread    PROC far
    push ds
    pushf
    mov ax,ds
;
    push OFFSET sleep_thread_done
    call SaveCurrentThread
;
    movzx edi,di    
    jmp BlockCurrentThread

sleep_thread_done:
    GetThread
    mov ds,ax
    mov eax,ds:p_data
    popf
    pop ds
    ret
sleep_thread    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearSignal
;
;           DESCRIPTION:    Set status to unsignaled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_signal_name       DB 'Clear Signal',0

clear_signal    PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds:p_signal,0
;
    pop ax
    pop ds
    ret
clear_signal    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SIGNAL_THREAD
;
;           DESCRIPTION:    Send a signal to a thread
;
;           PARAMETERS:         BX              Thread to signal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_thread_name      DB 'Signal',0

signal_thread   PROC far
    push ax
    push ds
    push es
    push fs
;
    or bx,bx
    jz signal_done
;    
    mov ax,task_sel
    mov ds,ax
    call ds:try_lock_proc
;
    mov es,bx
    mov es:p_signal,1
    mov ds:has_signal,1
;
    call ds:unlock_proc
    
signal_done:       
    pop ax
    verr ax
    jz signal_fs_ok
;
    xor ax,ax
    
signal_fs_ok:
    mov fs,ax
;       
    pop ax
    verr ax
    jz signal_es_ok
;
    xor ax,ax
    
signal_es_ok:
    mov es,ax
;       
    pop ax
    verr ax
    jz signal_ds_ok
;
    xor ax,ax
    
signal_ds_ok:
    mov ds,ax
    pop ax
    ret
signal_thread   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForSignal
;
;           DESCRIPTION:    Wait for a signal
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_signal_name    DB 'Wait For Signal',0

wait_for_signal PROC far
    push ds
    push es
    push fs
    push ax
;
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
;    
    mov es,fs:ps_curr_thread
    xor al,al
    xchg al,es:p_signal
    or al,al
    jnz wait_for_signal_unlock
;
    push OFFSET wait_for_signal_clear
    call SaveLockedThread
;
    mov ax,task_sel
    mov edi,OFFSET signal_list
    jmp BlockCurrentThread

wait_for_signal_clear:
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    mov es,fs:ps_curr_thread
    mov es:p_signal,0

wait_for_signal_unlock:
    call ds:unlock_proc
;       
    pop ax
    pop fs
    pop es
    pop ds
    ret
wait_for_signal ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           signal_timeout
;
;           DESCRIPTION:    Signal timeout handler
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_timeout  PROC far
    mov bx,cx
    Signal
    ret
signal_timeout  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForSignalWithTimeout
;
;           DESCRIPTION:    Wait for a signal with timeout
;
;           PARAMETERS:         EDX:EAX     Timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_signal_timeout_name    DB 'Wait For Signal With Timeout',0

wait_for_signal_timeout PROC far
    push ds
    push es
    push fs
    push ax
    push bx
    push cx
    push di
;
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
;
    mov cx,cs
    mov es,cx
    mov di,OFFSET signal_timeout    
    mov bx,fs:ps_curr_thread
    mov cx,bx
    StartTimer
;    
    mov es,bx
    xor al,al
    xchg al,es:p_signal
    or al,al
    jnz wait_for_signal_timeout_unlock
;
    push OFFSET wait_for_signal_timeout_clear
    call SaveLockedThread
;
    mov ax,task_sel
    mov edi,OFFSET signal_list
    jmp BlockCurrentThread

wait_for_signal_timeout_clear:
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    mov es,fs:ps_curr_thread
    mov es:p_signal,0
    
wait_for_signal_timeout_unlock:
    mov bx,fs:ps_curr_thread
    StopTimer
    call ds:unlock_proc
;
    pop di
    pop cx
    pop bx
    pop ax
    pop fs
    pop es
    pop ds
    ret
wait_for_signal_timeout ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           enter_section
;
;           DESCRIPTION:    Enter section
;
;           PARAMETERS:         DS:ESI      ADDRESS OF SECTION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_section_name      DB 'Enter Critical Section',0

enter_section   PROC far
    push ax
    push dx
    push ds
    push fs
;    
    mov ax,ds
    mov dx,task_sel
    mov ds,dx
    call ds:lock_proc
;
    mov ds,ax
    mov dx,ds:[esi].cs_list
    cmp dx,-1
    jne ecsBlock
;
    mov ds:[esi].cs_list,0
    jmp ecsUnlock

ecsBlock:
    push OFFSET ecsDone
    call SaveLockedThread
;
    lea edi,[esi].cs_list   
    jmp BlockCurrentThread

ecsUnlock:
    mov dx,task_sel
    mov ds,dx
    call ds:unlock_proc
    
ecsDone:
    pop ax
    verr ax
    jz ecsFs
;
    xor ax,ax
    
ecsFs:
    mov fs,ax
;
    pop ax
    verr ax
    jz ecsDs
;
    xor ax,ax
    
ecsDs:
    mov ds,ax
;
    pop dx
    pop ax
    ret
enter_section   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LeaveSection
;
;           DESCRIPTION:    Leave section
;
;           PARAMETERS:         DS:ESI      ADDRESS OF SECTION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_section_name      DB 'Leave Critical Section',0
 
leave_section   PROC far
    push ax
    push dx
    push ds
    push fs
;
    mov dx,ds
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
;
    mov ds,dx
    mov ax,ds:[esi].cs_list
    or ax,ax
    jnz lcsUnblock
;
    mov ds:[esi].cs_list,-1
    mov ax,task_sel
    mov ds,ax
    jmp lcsUnlock

lcsUnblock:
    push es    
    push esi
    push di
;
    mov ax,task_sel
    mov ds,ax
;       
    call ds:lock_list_proc
;
    push ds
    mov ds,dx
    add esi,OFFSET cs_list
    RemoveBlock32
    mov es:p_data,0
    pop ds
;
    mov di,OFFSET wakeup_list
    InsertBlock
;       
    mov ds:has_list,1
    call ds:unlock_list_proc
;       
    pop di
    pop esi
    pop es

lcsUnlock:
    call ds:unlock_proc

lcsDone:
    pop ax
    verr ax
    jz lcsFs
;
    xor ax,ax
    
lcsFs:
    mov fs,ax
;
    pop ax
    verr ax
    jz lcsDs
;
    xor ax,ax
    
lcsDs:
    mov ds,ax
;
    pop dx
    pop ax
    ret
leave_section   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           create_user_section
;
;           DESCRIPTION:    Create user section
;
;           RETURNS:        BX          Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_user_section_name    DB 'Create User Section',0

create_user_section     PROC far
    push ds
    push eax
    push cx
;
    mov cx,SIZE section_handle_seg
    AllocateHandle
    mov ds:[bx].us_value,0
    mov ds:[bx].us_list,0
    mov ds:[bx].us_owner,0
    mov ds:[bx].us_count,0
    mov [bx].hh_sign,SECTION_HANDLE
    mov bx,[bx].hh_handle
    clc
;
    pop cx
    pop eax
    pop ds
    retf32
create_user_section     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           create_blocked_user_section
;
;           DESCRIPTION:    Create blocked user section
;
;           RETURNS:        BX          Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_blocked_user_section_name    DB 'Create Blocked User Section',0

create_blocked_user_section     PROC far
    push ds
    push eax
    push cx
;
    mov cx,SIZE section_handle_seg
    AllocateHandle
    mov ds:[bx].us_value,-1
    mov ds:[bx].us_list,0
    mov ds:[bx].us_owner,-1
    mov ds:[bx].us_count,1
    mov [bx].hh_sign,SECTION_HANDLE
    mov bx,[bx].hh_handle
    clc
;
    pop cx
    pop eax
    pop ds
    retf32
create_blocked_user_section     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_user_section
;
;           DESCRIPTION:    Delete user section
;
;           PARAMETERS:         BX          Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_user_section_name    DB 'Delete User Section',0

delete_user_section     PROC far
    push ds
    push bx
;
    mov ax,SECTION_HANDLE
    DerefHandle
    jc free_section_done
;
    FreeHandle
    clc

free_section_done:
    pop bx
    pop ds
    retf32
delete_user_section     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           enter_user_section
;
;           DESCRIPTION:    Enter user section
;
;           PARAMETERS:         BX          Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_user_section_name DB 'Enter User Section',0

enter_user_section      PROC far
    push ax
    push bx
    push dx
    push ds
    push fs
;
    mov ax,SECTION_HANDLE
    DerefHandle
    jc eusEnd
;
    lock sub ds:[bx].us_value,1
    jc eusDone
;
    str ax
    cmp ax,ds:[bx].us_owner
    je eusDone
;
    push ds
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    pop ds
;    
    mov ax,ds:[bx].us_list
    cmp ax,-1
    jne eusBlock
;
    mov ds:[bx].us_list,0
    jmp eusUnlock

eusBlock:
    mov ax,ds
    push OFFSET eusDone
    call SaveLockedThread
;
    lea di,[bx].us_list     
    movzx edi,di
    jmp BlockCurrentThread

eusUnlock:
    push ds
    mov ax,task_sel
    mov ds,ax
    call ds:unlock_proc
    pop ds
    
eusDone:
    str ax
    mov ds:[bx].us_owner,ax
    inc ds:[bx].us_count

eusEnd:
    pop ax
    verr ax
    jz eusFs
;
    xor ax,ax
    
eusFs:
    mov fs,ax
;
    pop ax
    verr ax
    jz eusDs
;
    xor ax,ax
    
eusDs:
    mov ds,ax
;
    pop dx
    pop bx
    pop ax
    retf32
enter_user_section      ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           leave_user_section
;
;           DESCRIPTION:    Leave user section
;
;           PARAMETERS:         BX          Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_user_section_name DB 'Leave User Section',0
 
leave_user_section      PROC far
    push ax
    push bx
    push dx
    push ds
    push fs
;
    mov ax,SECTION_HANDLE
    DerefHandle
    jc lusDone
;
    str ax
    cmp ax,ds:[bx].us_owner
    jne lusDone
;
    sub ds:[bx].us_count,1
    jz lusFreeOwner
;       
    lock add ds:[bx].us_value,1
    jnc lusNotValueError
;
    int 3

lusNotValueError:       
    jmp lusDone

lusFreeOwner:
    jnc lusNotCountError
;
    int 3

lusNotCountError:
    mov ds:[bx].us_owner,0
    lock add ds:[bx].us_value,1
    jc lusDone
;    
    push ds
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    pop ds
;
    mov ax,ds:[bx].us_list
    or ax,ax
    jnz lusUnblock
;
    mov ds:[bx].us_list,-1
    mov ax,task_sel
    mov ds,ax
    jmp lusUnlock

lusUnblock:
    push es
    push esi
    push di
;    
    lea esi,ds:[bx].us_list
    mov dx,ds
;    
    mov ax,task_sel
    mov ds,ax   
    call ds:lock_list_proc
;
    push ds
    mov ds,dx
    RemoveBlock32
    mov es:p_data,0
    pop ds
;
    mov di,OFFSET wakeup_list
    InsertBlock
;       
    mov ds:has_list,1
    call ds:unlock_list_proc
;
    pop di
    pop esi
    pop es

lusUnlock:
    call ds:unlock_proc

lusDone:
    pop ax
    verr ax
    jz lusFs
;
    xor ax,ax
    
lusFs:
    mov fs,ax
;
    pop ax
    verr ax
    jz lusDs
;
    xor ax,ax
    
lusDs:
    mov ds,ax
;
    pop dx
    pop bx
    pop ax
    retf32
leave_user_section      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_thread
;
;           DESCRIPTION:    Get current thread control block
;
;           PARAMETERS:         AX          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_thread

get_thread      PROC far
    push ds
    mov ax,task_sel
    verr ax
    jz get_thread_norm

get_thread_pre_tasking:
    mov ax,virt_thread_sel
    jmp get_thread_done

get_thread_norm:
    push es
    push si
    push di
;    
    mov ds,ax
    mov ax,gdt_sel
    mov es,ax
    mov di,tss_data_sel
    call ds:lock_list_proc
    str si
    movs word ptr es:[di],es:[si]
    movs word ptr es:[di],es:[si]
    lods word ptr es:[si]
    mov ah,92h
    stos word ptr es:[di]
    movs word ptr es:[di],es:[si]
    mov ax,tss_data_sel
    mov es,ax
    mov ax,es:tss_thread
    call ds:unlock_list_proc
;    
    pop di
    pop si
    pop es

get_thread_done:
    pop ds
    ret
get_thread      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetThread
;
;           DESCRIPTION:    Get current thread
;
;           PARAMETERS:         AX          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_name DB 'Get Thread',0

get_thread_pr   PROC far
    push ds
    push es
    push si
    push di
;       
    mov ax,task_sel
    mov ds,ax
    mov ax,gdt_sel
    mov es,ax
    mov di,tss_data_sel
    call ds:lock_list_proc
    str si
    movs word ptr es:[di],es:[si]
    movs word ptr es:[di],es:[si]
    lods word ptr es:[si]
    mov ah,92h
    stos word ptr es:[di]
    movs word ptr es:[di],es:[si]
    mov ax,tss_data_sel
    mov es,ax
    mov ax,es:tss_thread
    call ds:unlock_list_proc
;
    pop di
    pop si
    pop es
    pop ds
    retf32
get_thread_pr   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProcessor
;
;           DESCRIPTION:    Get current processor #
;
;           RETURNS:        AX          Processor
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_processor_id_name   DB 'Get Processor ID',0

get_processor_id    PROC far
    xor ax,ax
    retf32
get_processor_id    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CpuReset
;
;           DESCRIPTION:    Trigger a CPU reset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cpu_reset_name  DB 'Cpu Reset',0

cpu_reset       PROC far
    cli
wait_gate1:
    in al,64h
    and al,2
    jnz wait_gate1
    mov al,0D1h
    out 64h,al
wait_gate2:
    in al,64h
    and al,2
    jnz wait_gate2
    mov al,0FEh
    out 60h,al
;
    xor eax,eax
    mov cr3,eax

reset_wait:
    jmp reset_wait
    
    retf32
cpu_reset       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PowerFailure
;
;           DESCRIPTION:    Power failure indication
;
;       RETURNS:    AX  0 = power ok
;               1 = power failure
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

power_failure_name      DB 'Power Failure',0

power_failure   PROC far
    xor ax,ax
    retf32
power_failure   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCpuTime
;
;           DESCRIPTION:    Get used CPU time
;
;           PARAMETERS:         BX          Thread
;           
;           RETURNS:        EDX:EAX     Used CPU time               
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cpu_time_name       DB 'Get CPU time',0

get_cpu_time    PROC far
    push ds
    mov ds,bx
    mov eax,ds:p_lsb_tics
    mov edx,ds:p_msb_tics
    pop ds
    retf32
get_cpu_time    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WakeUntil
;
;           DESCRIPTION:    Timer callback for wait time
;
;           PARAMETERS:     CX      Thread to wake up
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wake_until      PROC far
    mov ax,task_sel
    mov ds,ax
    mov es,cx
    call ds:lock_list_proc
    mov di,OFFSET wakeup_list
    InsertBlock
    mov ds:has_list,1
    call ds:unlock_list_proc
    ret
wake_until      ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WAIT_UNTIL
;
;           DESCRIPTION:    Wait until time occurs.
;
;           PARAMETERS:         EDX:EAX     System time to wait until
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_until_name DB 'Wait Until',0

wait_until      PROC far
    pushf
    push OFFSET wait_until_done
    call SaveCurrentThread
;
    mov cx,fs:ps_curr_thread
    mov bx,cs
    mov es,bx
    mov di,OFFSET wake_until
    xor bx,bx
    cli
    LocalStartTimer
    sti
;
    xor ax,ax    
    mov edi,1
    jmp BlockCurrentThread

wait_until_done:
    popf
    retf32
wait_until      ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WAIT_MILLI_SEC
;
;           DESCRIPTION:    Wait a number of ms
;
;           PARAMETERS:         AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_milli_name DB 'Wait Milli Sec',0

wait_milli_sec  PROC far
    pushf
    push OFFSET wait_milli_done
    call SaveCurrentThread
;
    mov es,fs:ps_curr_thread
    mov bx,1193
    mul bx
    push dx
    push ax
    pop ebx
    cli
    call ds:update_clock_proc
    LocalGetSystemTime
    sti
;
    add eax,ebx
    adc edx,0
;
    mov cx,es
    mov bx,cs
    mov es,bx
    mov di,OFFSET wake_until
    xor bx,bx
    cli
    LocalStartTimer
    sti     
;    
    xor ax,ax
    mov edi,1
    jmp BlockCurrentThread

wait_milli_done:
    popf
    retf32
wait_milli_sec  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WAIT_MICRO_SEC
;
;           DESCRIPTION:    Wait a number of us
;
;           PARAMETERS:         AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_micro_name DB 'Wait Micro Seconds',0

wait_micro_sec  PROC far
    pushf
    push OFFSET wait_micro_done
    call SaveCurrentThread
;
    mov es,fs:ps_curr_thread
    movzx eax,ax
    mov ebx,78184
    mul ebx
    push dx
    push eax
    pop ax
    pop ebx
    cli
    call ds:update_clock_proc
    LocalGetSystemTime
    sti
    add eax,ebx
    adc edx,0
;
    mov cx,es
    mov bx,cs
    mov es,bx
    mov di,OFFSET wake_until
    xor bx,bx
    cli
    LocalStartTimer
    sti
;    
    xor ax,ax
    mov edi,1
    jmp BlockCurrentThread

wait_micro_done:
    popf
    retf32
wait_micro_sec  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CHECK_LIST
;
;           DESCRIPTION:    Check if thread is in list
;
;           PARAMETERS:         BX      Thread selector
;               ES:EDI      Buffer
;
;       RETURNS:        NC          processed
;               CX:EDX      List
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Wait_state DB 'Wait',0
Ready_state DB 'Ready',0
Signal_state DB 'Signal',0
Debug_state DB 'Debug',0

Run_state DB 'Run ', 0

check_list      Proc far
    push ds
    push fs
    push ax
    push si
;
    mov ax,task_sel
    mov ds,ax
    mov cx,ds:processor_count
    mov si,OFFSET processor_arr
    xor dx,dx

check_cpu_loop:
    mov fs,ds:[si]
    cmp bx,fs:ps_curr_thread
    je check_curr_ok
;
    cmp bx,fs:ps_null_thread
    je check_null_ok
;
    inc dx
    add si,2
    loop check_cpu_loop
    jmp check_not_cpu

check_curr_ok:
    mov si,OFFSET Run_state
    jmp check_copy_id

check_null_ok:
    mov si,OFFSET Ready_state
    jmp check_copy_cpu

check_copy_id:
    mov al,cs:[si]
    or al,al
    jz check_copy_id_done
;
    inc si
    stos byte ptr es:[edi]
    jmp check_copy_id

check_copy_id_done:
    mov al,'0'
    add al,dl
    stos byte ptr es:[edi]
    xor al,al
    stos byte ptr es:[edi]
;
    mov ds,bx
    mov ds,ds:p_tss_data_sel
    mov cx,ds:tss_cs
    mov edx,dword ptr ds:tss_eip   
    clc
    jmp check_done
    
check_not_cpu:
    mov fs,bx
    mov eax,fs:p_sleep_offset
    cmp eax,1
    jnz check_not_wait
;
    mov si,OFFSET Wait_state
    jmp check_copy_zero
    
check_not_wait:
    mov ax,fs:p_sleep_sel
    cmp ax,task_sel
    jne check_not_task
;
    mov eax,fs:p_sleep_offset
    cmp eax,OFFSET signal_list
    jne check_not_signal
;       
    mov si,OFFSET Signal_state
    jmp check_copy_zero
    
check_not_signal:
    mov si,OFFSET Ready_state
    jmp check_copy_cpu

check_not_task:
    cmp ax,system_data_sel
    jne check_not_system
;       
    mov eax,fs:p_sleep_offset
    cmp eax,OFFSET debug_list
    jne check_not_system
;
    mov si,OFFSET Debug_state
    jmp check_copy_cpu

check_copy_zero:
    xor cx,cx
    xor edx,edx
    jmp check_copy

check_copy_cpu:
    mov ds,bx
    mov ds,ds:p_tss_data_sel
    mov cx,ds:tss_cs
    mov edx,dword ptr ds:tss_eip   
    jmp check_copy

check_copy_sleep:
    mov ds,bx
    mov cx,ds:p_sleep_sel
    mov edx,ds:p_sleep_offset

check_copy:
    mov al,cs:[si]
    or al,al
    jz check_copy_done

    inc si
    stos byte ptr es:[edi]
    jmp check_copy

check_copy_done:
    xor al,al
    stos byte ptr es:[edi]
    clc
    jmp check_done
    
check_not_system:
    stc

check_done:
    pop si
    pop ax
    pop fs
    pop ds
    ret
check_list      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DebugBreak
;
;           DESCRIPTION:    Put thread in debug list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_break_name    DB 'Debug Break',0

debug_break:
    DebugException

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetSystemTime
;
;           DESCRIPTION:    Return system time.
;
;           PARAMETERS:         EDX:EAX     Binary time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_system_time_name    DB 'Get System Time',0

get_system_time PROC far
    push ds
    push es
    mov ax,task_sel
    mov ds,ax
    GetThread
    mov es,ax
    cli
    call ds:update_clock_proc
    LocalGetSystemTime
    sti
    pop es
    pop ds
    retf32
get_system_time ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetTime
;
;           DESCRIPTION:    Return user time
;
;           PARAMETERS:         EDX:EAX     Binary user time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_time_name   DB 'Get Time',0

get_time    PROC far
    push ds
    push es
    mov ax,task_sel
    mov ds,ax
    GetThread
    mov es,ax
    cli
    call ds:update_clock_proc
    LocalGetSystemTime
    add eax,ds:time_diff
    adc edx,ds:time_diff+4
    sti
    pop es
    pop ds
    retf32
get_time    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           TimeToSystemTime
;
;           DESCRIPTION:    Converts real time to system time
;
;           PARAMETERS:         EDX:EAX     Real time
;
;           RETURNS:        EDX:EAX     System time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

time_to_system_time_name    DB 'Time To System Time',0

time_to_system_time     PROC far
    push ds
    push bx
    mov bx,task_sel
    mov ds,bx
;
    cli
    sub eax,ds:time_diff
    sbb edx,ds:time_diff+4
    sti
;
    pop bx
    pop ds
    retf32
time_to_system_time     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SystemTimeToTime
;
;           DESCRIPTION:    Converts system time to real time
;
;           PARAMETERS:         EDX:EAX     System time
;
;           RETURNS:        EDX:EAX     Real time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

system_time_to_time_name    DB 'System Time To Time',0

system_time_to_time     PROC far
    push ds
    push bx
    mov bx,task_sel
    mov ds,bx
;
    cli
    add eax,ds:time_diff
    adc edx,ds:time_diff+4
    sti
;
    pop bx
    pop ds
    retf32
system_time_to_time     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetSystemTime
;
;           DESCRIPTION:    Set system time. Must not be called after tasking is
;                           started.
;
;           PARAMETERS:         EDX:EAX     Binary time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_system_time_name    DB 'Set System Time',0

set_system_time PROC far
    push ds
    push bx
    mov bx,task_sel
    mov ds,bx
    mov ds:system_time,eax
    mov ds:system_time+4,edx
    pop bx
    pop ds
    ret
set_system_time ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UpdateTime
;
;           DESCRIPTION:    Sets difference between real time and system time
;
;           PARAMETERS:         EDX:EAX     Difference
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_time_name    DB 'Update Time',0

update_time     PROC far
    push ds
    push bx
    mov bx,task_sel
    mov ds,bx
    cli
    mov ds:time_diff,eax
    mov ds:time_diff+4,edx
    sti
    pop bx
    pop ds
    retf32
update_time     ENDP

code    ENDS

    END

