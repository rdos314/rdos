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
; timer.asm
; Timer module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\os\system.def
INCLUDE apic.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\core.inc
INCLUDE ..\acpi\acpitab.inc
INCLUDE ..\os\realmon.def
INCLUDE ..\bios\vbe.inc

INCLUDE ..\user.def
INCLUDE ..\user.inc

hpet_table  STRUC

hpet_base       acpi_table <>

hpett_event_block    DD ?
hpett_flags          DD ?
hpett_phys_base      DD ?,?
hpett_nr             DB ?
hpett_min_tics       DW ?

hpet_table  ENDS

hpet_counter_struc  STRUC

hpetc_config        DD ?
hpetc_int_mask      DD ?
hpetc_compare       DD ?,?
hpetc_msi_data      DD ?
hpetc_msi_ads       DD ?
hpetc_resv          DD ?,?

hpet_counter_struc  ENDS

hpet_struc      STRUC

hpet_cap            DD ?
hpet_period         DD ?
hpet_resv1          DD ?,?
hpet_config         DD ?,?,?,?
hpet_int_status     DD ?,?,?,?

hpet_resv2          DB 0C0h DUP(?)

hpet_count          DD ?,?,?,?

hpet_counter_arr    DB 32 * SIZE hpet_counter_struc DUP(?)

hpet_struc      ENDS

time_seg  STRUC

t_phys              DD ?,?
t_spinlock          DW ?
t_clock_tics        DW ?
t_system_time       DD ?,?

t_hpet_guard        DD ?
t_prev_hpet         DD ?
t_hpet_sel          DW ?
t_hpet_factor       DD ?
t_hpet_counters     DW ?

time_seg  ENDS


data    SEGMENT byte public 'DATA'

apic_tics           DD ?
apic_rest           DW ?

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use32 'CODE'

    assume cs:code
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   DelayMs
;
;               DESCRIPTION:    Delay for Init/SIPI
;
;       PARAMETERS:     AX      Delay in ms
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DelayMs

DelayMs Proc near
    push ds
    push es
    pushad
;
    mov edx,SEG data
    mov ds,edx
    movzx eax,ax
    mov ecx,1193
    mul ecx
;        
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    shl eax,16
    mul ecx
    inc edx
;
    mov eax,apic_mem_sel
    mov es,eax    
    mov es:APIC_INIT_COUNT,edx

dmLoop:
    mov eax,es:APIC_CURR_COUNT
    or eax,eax
    jnz dmLoop
;       
    popad
    pop es
    pop ds
    ret
DelayMs Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetSystemTime
;
;           DESCRIPTION:    Read system time, PIT version
;
;           RETURNS:        EDX:EAX     System time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pit_time_name    DB 'Get System Time', 0

get_pit_time  Proc far
    push ds
;
    mov eax,time_data_sel
    mov ds,eax

gstSpinLock:    
    mov ax,ds:t_spinlock
    or ax,ax
    je gstGet
;
    sti
    pause
    jmp gstSpinLock

gstGet:
    cli
    inc ax
    xchg ax,ds:t_spinlock
    or ax,ax
    jne gstSpinLock
;
    mov al,0
    out TIMER_CONTROL,al
    jmp short $+2
    in al,TIMER0
    mov ah,al
    jmp short $+2
    in al,TIMER0
    xchg al,ah
    mov dx,ax
    xchg ax,ds:t_clock_tics
    sub ax,dx
    movzx eax,ax
    add ds:t_system_time,eax
    adc ds:t_system_time+4,0
;    
    mov eax,ds:t_system_time
    mov edx,ds:t_system_time+4
;
    mov ds:ut_system_time+1000h,eax
    mov ds:ut_system_time+1004h,edx
;    
    mov ds:t_spinlock,0
    sti
    pop ds
    ret
get_pit_time  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetSystemTime
;
;           DESCRIPTION:    Read system time, HPET version
;
;           RETURNS:        EDX:EAX     System time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_hpet_time_name    DB 'Get System Time', 0

get_hpet_time  Proc far
    push ecx
    push ds
    push es
;
    mov eax,time_data_sel
    mov ds,eax
    mov es,ds:t_hpet_sel

ghtSpinLock:    
    mov ax,ds:t_spinlock
    or ax,ax
    je ghtGet
;
    sti
    pause
    jmp ghtSpinLock

ghtGet:
    cli
    inc ax
    xchg ax,ds:t_spinlock
    or ax,ax
    jne ghtSpinLock
;
    mov eax,es:hpet_count
    mov edx,eax
    xchg edx,ds:t_prev_hpet
    sub eax,edx
    mul ds:t_hpet_factor
    add eax,ds:t_hpet_guard
    adc edx,0
;
    mov ecx,31F5C4EDh
    div ecx
    mov ds:t_hpet_guard,edx
    add ds:t_system_time,eax
    adc ds:t_system_time+4,0
;    
    mov eax,ds:t_system_time
    mov edx,ds:t_system_time+4
;
    mov ds:ut_system_time+1000h,eax
    mov ds:ut_system_time+1004h,edx
;    
    mov ds:t_spinlock,0
    sti
;
    pop ecx
    verr cx
    jz hpet_time_es_ok
;
    xor ecx,ecx
    
hpet_time_es_ok:
    mov es,ecx
;
    pop ecx
    verr cx
    jz hpet_time_ds_ok
;
    xor ecx,ecx
    
hpet_time_ds_ok:
    mov ds,ecx
    pop ecx
    ret
get_hpet_time  Endp
    
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
    push ebx
;
    mov ebx,time_data_sel
    mov ds,ebx
    mov ds:t_system_time,eax
    mov ds:t_system_time+4,edx
;
    pop ebx
    pop ds
    ret
set_system_time ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasGlobalTimer
;
;           DESCRIPTION:    Check if system has global timer
;
;           RETURNS:        NC      Global timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_local_timer_name    DB 'Has Global Timer', 0

has_local_timer  Proc far
    stc
    ret
has_local_timer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LongTimerHandler
;
;           DESCRIPTION:    Long timer int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

long_timer_handler_name    DB 'Long Timer Handler', 0

long_timer_handler      Proc far
    mov al,-1
    EnterInt    
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
    ret
long_timer_handler      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           StartSysPreemptTimer
;
;               DESCRIPTION:    Start mixed system and preempt timer
;
;               RETURNS:        EAX      Update tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_sys_preempt_timer_name    DB 'Start Apic Sys Preempt Timer', 0

start_sys_preempt_timer    Proc far
    push ds
;    
    mov eax,apic_mem_sel
    mov ds,eax
    mov eax,83h
    mov ds:APIC_TIMER,eax
    xor eax,eax
;
    pop ds
    ret
start_sys_preempt_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ReloadSysPreemptTimer
;
;               DESCRIPTION:    Reload mixed system and preempt timer
;
;               PARAMETERS:     AX      Reload tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reload_sys_preempt_timer_name    DB 'Reload Apic Sys Preempt Timer', 0

reload_sys_preempt_timer    Proc far
    push ds
    push eax
    push ecx
    push edx
;
    mov ecx,SEG data
    mov ds,ecx
;    
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    shl eax,16
    mul ecx
    inc edx
    mov eax,apic_mem_sel
    mov ds,eax    
    mov ds:APIC_INIT_COUNT,edx
    clc
;
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
reload_sys_preempt_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           TimerInt
;
;               DESCRIPTION:    Timer interrupt
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timer_int:
    pushad
    push ds
    push es
    push fs
;
    mov al,-1
    EnterInt    
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop eax
    verr ax
    jz timer_fs_ok
;
    xor eax,eax

timer_fs_ok:
    mov fs,eax
;    
    pop eax
    verr ax
    jz timer_es_ok
;
    xor eax,eax

timer_es_ok:
    mov es,eax
;    
    pop eax
    verr ax
    jz timer_ds_ok
;
    xor eax,eax

timer_ds_ok:
    mov ds,eax
;    
    popad
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PreemptInt
;
;               DESCRIPTION:    Preempt interrupt
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

preempt_int:
    pushad
    push ds
    push es
    push fs
;
    mov al,-1
    EnterInt    
    lock or fs:cs_flags,CS_FLAG_PREEMPT
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop eax
    verr ax
    jz preempt_fs_ok
;
    xor eax,eax

preempt_fs_ok:
    mov fs,eax
;    
    pop eax
    verr ax
    jz preempt_es_ok
;
    xor eax,eax

preempt_es_ok:
    mov es,eax
;    
    pop eax
    verr ax
    jz preempt_ds_ok
;
    xor eax,eax

preempt_ds_ok:
    mov ds,eax
;    
    popad
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           SetupInts
;
;               DESCRIPTION:    Setup ints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts Proc near
    push ds
    pushad

    mov ax,cs
    mov ds,ax
    xor bl,bl
;
    mov al,40h
    mov esi,OFFSET timer_int
    SetupIntGate
;    
    mov ax,setup_long_timer_int_nr
    IsValidOsGate
    jc stiTimerOk
;    
    mov al,40h
    SetupLongTimerInt

stiTimerOk:
    mov al,80h
    mov esi,OFFSET preempt_int
    SetupIntGate
;    
    mov ax,setup_long_preempt_int_nr
    IsValidOsGate
    jc stiPreemptOk
;    
    mov al,80h
    SetupLongPreemptInt

stiPreemptOk:
    mov ax,setup_long_schedule_int_nr
    IsValidOsGate
    jc stiSchedOk
;    
    mov al,82h
    SetupLongScheduleInt

stiSchedOk:
    mov al,83h
    mov esi,OFFSET timer_int
    SetupIntGate
;    
    mov ax,setup_long_timer_int_nr
    IsValidOsGate
    jc stiPreemptTimerOk
;    
    mov al,83h
    SetupLongTimerInt

stiPreemptTimerOk:
    popad
    pop ds
    ret
SetupInts Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Start timer
;
;               DESCRIPTION:    start timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_tics   MACRO
    mov al,0
    out TIMER_CONTROL,al
    jmp short $+2
    in al,TIMER0
    mov ah,al
    jmp short $+2
    in al,TIMER0
    xchg al,ah
            ENDM

    public start_timer

start_timer Proc near    
    push ds
    push es
    pushad
;    
    mov eax,SEG data
    mov ds,eax
    mov eax,apic_mem_sel
    mov es,eax

init_tsc_start:
    mov ecx,10000h    

init_tsc_wait_start_high:
    read_tics    
    test ax,8000h
    jnz init_tsc_wait_start_high_ok
    loop init_tsc_wait_start_high    

init_tsc_wait_start_high_ok:
    mov ecx,10000h    

init_tsc_wait_start_low:
    read_tics    
    test ax,8000h
    jz init_tsc_wait_start_low_ok
    loop init_tsc_wait_start_low

init_tsc_wait_start_low_ok:    
    mov eax,-1
    mov es:APIC_INIT_COUNT,eax

init_apic_start_done:
    mov ecx,10000h    

init_tsc_wait_high:    
    read_tics
    test ax,8000h
    jnz init_tsc_wait_high_ok
    loop init_tsc_wait_high

init_tsc_wait_high_ok:
    mov ecx,10000h    

init_tsc_wait_low:    
    read_tics
    test ax,8000h
    jz init_tsc_wait_low_ok
    loop init_tsc_wait_low

init_tsc_wait_low_ok:
    mov eax,-1
    sub eax,es:APIC_CURR_COUNT    
    xor edx,edx
    mov ecx,8000h
    div ecx
;
    mov ds:apic_tics,eax
    mov ds:apic_rest,dx    
;    
    popad
    pop es
    pop ds
    ret
start_timer Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Init_timer
;
;               DESCRIPTION:    Init timer module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hpet_tab    DB 'HPET'

    public init_timer
        
init_timer    PROC near
    push ds
    push es
    pushad
;
    mov eax,2000h
    AllocateBigLinear
;
    mov bx,time_data_sel
    mov ecx,2000h
    CreateDataSelector16
;
    mov es,ebx
    xor edi,edi
    mov ecx,800h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    add edx,1000h
    GetPageEntry
    xor al,al
    mov es:t_phys,eax
    mov es:t_phys+4,ebx
;    
    mov al,34h
    out TIMER_CONTROL,al
    jmp short $+2
    mov al,0
    out TIMER0,al
    jmp short $+2
    out TIMER0,al
    jmp short $+2
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET start_sys_preempt_timer
    mov edi,OFFSET start_sys_preempt_timer_name
    xor cl,cl
    mov ax,start_sys_preempt_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET reload_sys_preempt_timer
    mov edi,OFFSET reload_sys_preempt_timer_name
    xor cl,cl
    mov ax,reload_sys_preempt_timer_nr
    RegisterOsGate
    mov esi,OFFSET set_system_time
    mov edi,OFFSET set_system_time_name
    xor cl,cl
    mov ax,set_system_time_nr
    RegisterOsGate
;
    mov esi,OFFSET long_timer_handler
    mov edi,OFFSET long_timer_handler_name
    xor cl,cl
    mov ax,long_timer_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET get_pit_time
    mov edi,OFFSET get_pit_time_name
    xor dx,dx
    mov ax,get_system_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_local_timer
    mov edi,OFFSET has_local_timer_name
    xor dx,dx
    mov ax,has_global_timer_nr
    RegisterBimodalUserGate
;
    mov eax,system_data_sel
    mov es,eax
    mov ax,es:acpi_hpet_table
    mov es,eax
    or ax,ax
    jz init_hpet_obj    
;    
    mov ebx,es:hpett_phys_base
    jmp init_hpet_check

init_hpet_obj: 
    mov ebx,0FED00000h

init_hpet_check:    
    mov eax,1000h
    AllocateBigLinear
    mov eax,ebx
    or ax,33h
    xor ebx,ebx
    SetPageEntry
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es,bx
;
    mov eax,es:hpet_period
    or eax,eax
    jz init_hpet_done
;
    cmp eax,5F5E100h
    ja init_hpet_done
;
    mov eax,es:hpet_cap
    or al,al
    jz init_hpet_done
;
    mov ax,time_data_sel
    mov ds,ax
    mov ds:t_hpet_sel,es
;    
    mov eax,es:hpet_config
    and al,NOT 2
    mov es:hpet_config,eax
;    
    mov eax,es:hpet_period
    mov ds:t_hpet_factor,eax
;
    mov eax,es:hpet_cap
    mov al,ah
    and ax,1Fh
    inc ax
    mov ds:t_hpet_counters,ax
;
    movzx ecx,ax
    mov ebx,OFFSET hpet_counter_arr    

init_hpet_loop:
    mov eax,es:[ebx].hpetc_config
    and ax,NOT 4004h
    mov es:[ebx].hpetc_config,eax
    add ebx,SIZE hpet_counter_struc
    loop init_hpet_loop
;    
    mov eax,es:hpet_config
    and al,NOT 3
    or al,1
    mov es:hpet_config,eax
;
    mov eax,cs
    mov ds,eax
    mov es,eax    
;    
    mov esi,OFFSET get_hpet_time
    mov edi,OFFSET get_hpet_time_name
    xor dx,dx
    mov ax,get_system_time_nr
    RegisterBimodalUserGate

init_hpet_done:    
    call SetupInts
;    
    popad
    pop es
    pop ds
    ret
init_timer    ENDP

code    ENDS

    END
    
