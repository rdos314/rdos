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
INCLUDE ..\serv.def
INCLUDE ..\serv.inc
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE core.inc
INCLUDE ..\handle.inc
INCLUDE ..\apicheck.inc
include ..\wait.inc
include gate.def
include exec.def
INCLUDE servdev.def

MSR_SYSENTER_CS  = 174h
MSR_SYSENTER_ESP = 175h
MSR_SYSENTER_EIP = 176h

IA32_PAT      = 277h

MAX_CORES   = 64
WAIT_DEV_COUNT = 256

SLEEP_TYPE_WAIT  = 1
SLEEP_TYPE_SIGNAL = 2
SLEEP_TYPE_FUTEX = 3
SLEEP_TYPE_SECTION = 4
SLEEP_TYPE_DEBUG = 5
SLEEP_TYPE_SUSPEND = 6
SLEEP_TYPE_WAIT_DEV = 7
SLEEP_TYPE_BLOCK = 8

WAIT_DEV_ACTIVE   = 1
WAIT_DEV_SIGNAL   = 2

section_handle_seg          STRUC

us_base     handle_header <>

us_value    DW ?
us_list     DW ?
us_owner    DW ?
us_count    DW ?
us_lock     DW ?

section_handle_seg          ENDS

futex_handle_seg          STRUC

fh_base     handle_header <>

fh_list     DW ?
fh_lock     DW ?

futex_handle_seg          ENDS

block_handle_seg          STRUC

bh_base     handle_header <>

bh_list     DW ?
bh_lock     DW ?
bh_stopped  DW ?
bh_name     DW ?

block_handle_seg          ENDS

; this should always be 4 bytes!

wait_dev_seg  STRUC

wd_flags    DB ?
wd_lock     DB ?
wd_thread   DW ?

wait_dev_seg  ENDS

process_callback_seg    STRUC
cm_mode     DW ?
cm_stack    DD ?
cm_process      DW ?
cm_cs       DW ?
cm_eip      DD ?
cm_flags    DW ?
cm_eax      DD ?
cm_ebx      DD ?
cm_ecx      DD ?
cm_edx      DD ?
cm_esi      DD ?
cm_edi      DD ?
cm_ebp      DD ?
process_callback_seg    ENDS

cr_seg      EQU 28
cr_offs     EQU 24
cr_prio     EQU 22
cr_stack    EQU 18
cr_mode     EQU 16
cr_name     EQU 10
cr_cs       EQU 8
cr_eip      EQU 4
cr_ebp      EQU 0
cr_flags    EQU -2
cr_ds       EQU -4
cr_es       EQU -6
cr_fs       EQU -8
cr_gs       EQU -10
cr_eax      EQU -14
cr_ebx      EQU -18
cr_ecx      EQU -22
cr_edx      EQU -26
cr_esi      EQU -30
cr_edi      EQU -34

data    SEGMENT byte public 'DATA'

; keep this at 0

wait_dev_arr        DD WAIT_DEV_COUNT DUP(?)

wait_dev_pos        DW ?

term_thread_list    DW ?
term_proc_list      DW ?

list_lock           DW ?
 
sys_lsb_tics_base   DD ?
sys_msb_tics_base   DD ?

futex_section       section_typ <>

patch_sel           DW ?

timer_spinlock      DW ?
timer_head          DW ?
timer_free          DW ?
timer_entries       DB 256 * SIZE timer_struc DUP(?)

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Procedure addresses for SMP/non-SMP variants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

time_diff                   DD 0,0
update_tics                 DD 0

system_thread               DW 0

lock_list_proc              DW OFFSET LockListSingle
unlock_list_proc            DW OFFSET UnlockListSingle

lock_signal_proc            DW OFFSET LockSignalSingle
unlock_signal_proc          DW OFFSET UnlockSignalSingle

lock_wait_dev_proc          DW OFFSET LockWaitDevSingle
unlock_wait_dev_proc        DW OFFSET UnlockWaitDevSingle

lock_kernel_section_proc    DW OFFSET LockKernelSectionSingle
unlock_kernel_section_proc  DW OFFSET UnlockKernelSectionSingle

lock_user_section_proc      DW OFFSET LockUserSectionSingle
unlock_user_section_proc    DW OFFSET UnlockUserSectionSingle

lock_futex_proc             DW OFFSET LockFutexSingle
unlock_futex_proc           DW OFFSET UnlockFutexSingle

lock_block_proc             DW OFFSET LockBlockSingle
unlock_block_proc           DW OFFSET UnlockBlockSingle

flush_tlb_proc              DW OFFSET FlushTlb386

update_timer_proc           DW OFFSET UpdateCombinedTimer

preempt_reload_proc         DW OFFSET TimerPreemptReload

fpu_exception_proc          DW OFFSET FpuExceptionSingle
fpu_save_proc               DW OFFSET FpuSaveSingle

core_count                  DW 0
core_arr                    DW MAX_CORES DUP(0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LockTimerGlobal
;
;       DESCRIPTION:    Lock timer struc, global version
;
;       PARAMETERS:     DS      Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockTimerGlobal    Proc near
    push ax

ltigSpinLock:    
    mov ax,ds:timer_spinlock
    or ax,ax
    je ltigGet
;
    sti
    pause
    jmp ltigSpinLock

ltigGet:
    cli
    inc ax
    xchg ax,ds:timer_spinlock
    or ax,ax
    jne ltigSpinLock
;
    pop ax
    ret
LockTimerGlobal    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlockTimerGlobal
;
;       DESCRIPTION:    Unlock timer, global version
;
;       PARAMETERS:     DS      task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockTimerGlobal    Proc near
    mov ds:timer_spinlock,0
    sti
    ret
UnlockTimerGlobal    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LockTimerCore
;
;       DESCRIPTION:    Lock timer struc, per core version
;
;       PARAMETERS:     FS      Core data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockTimerCore    Proc near
    push ax

lticSpinLock:    
    mov ax,fs:cs_timer_spinlock
    or ax,ax
    je lticGet
;
    sti
    pause
    jmp lticSpinLock

lticGet:
    cli
    inc ax
    xchg ax,fs:cs_timer_spinlock
    or ax,ax
    jne lticSpinLock
;
    pop ax
    ret
LockTimerCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlockTimerCore
;
;       DESCRIPTION:    Unlock timer, per core version
;
;       PARAMETERS:     FS      Core data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockTimerCore    Proc near
    mov fs:cs_timer_spinlock,0
    sti
    ret
UnlockTimerCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LocalRemoveTimerGlobal
;
;           DESCRIPTION:    Remove timer, global version
;
;           PARAMETERS:     DS      Task sel
;                           FS      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalRemoveTimerGlobal Proc near
    mov bx,ds:timer_head
    mov ax,ds:[bx].timer_next
    mov ds:timer_head,ax
;    
    push ds
    push es
    push fs
;    
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET timer_global_return
    push eax
    mov ax,ds:[bx].timer_sel
    push eax
    push ds:[bx].timer_offset
;
    mov ax,ds:timer_free
    mov ds:[bx].timer_next,ax
    mov ds:timer_free,bx
;    
    mov ecx,ds:[bx].timer_id
    mov eax,ds:[bx].timer_lsb
    mov edx,ds:[bx].timer_msb        
    call UnlockTimerGlobal
;    
    xor bx,bx
    mov ds,bx
    mov es,bx
    retf32

timer_global_return:
    pop fs
    pop es
    pop ds
    ret
LocalRemoveTimerGlobal    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LocalRemoveTimerCore
;
;           DESCRIPTION:    Remove timer, per core version
;
;           PARAMETERS:     DS      Task sel
;                           FS      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalRemoveTimerCore Proc near
    mov bx,fs:cs_timer_head
    mov ax,fs:[bx].timer_next
    mov fs:cs_timer_head,ax
;    
    push es
    push fs
;    
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET timer_core_return
    push eax
    mov ax,fs:[bx].timer_sel
    push eax
    push fs:[bx].timer_offset
;
    mov ax,fs:cs_timer_free
    mov fs:[bx].timer_next,ax
    mov fs:cs_timer_free,bx
;    
    mov ecx,fs:[bx].timer_id
    mov eax,fs:[bx].timer_lsb
    mov edx,fs:[bx].timer_msb        
    call UnlockTimerCore
;    
    xor bx,bx
    mov ds,bx
    mov es,bx
    retf32

timer_core_return:
    pop fs
    pop es
    ret
LocalRemoveTimerCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InsertCoreBlock
;
;           DESCRIPTION:    Insert thread into core list
;
;           PARAMETERS:     FS:DI       List
;                           ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertCoreBlock Proc near
    mov es:p_sleep_sel,fs
    mov word ptr es:p_sleep_offset,di
    mov word ptr es:p_sleep_offset+2,0
    push di
    mov di,fs:[di]
    or di,di
    je icbEmpty
;    
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
    jmp icbDone
    
icbEmpty:
    mov es:p_next,es
    mov es:p_prev,es
    pop di
    mov fs:[di],es

icbDone:
    ret
InsertCoreBlock Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InsertCoreFirst
;
;           DESCRIPTION:    Insert thread first into core list
;
;           PARAMETERS:     FS:DI       List
;                           ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertCoreFirst Proc near
    mov es:p_sleep_sel,fs
    mov word ptr es:p_sleep_offset,di
    mov word ptr es:p_sleep_offset+2,0
    push di
    mov di,fs:[di]
    or di,di
    je icfEmpty
;
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
    jmp icfDone
    
icfEmpty:
    mov es:p_next,es
    mov es:p_prev,es
    pop di

icfDone:
    mov fs:[di],es
    ret
InsertCoreFirst Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InsertBlock
;
;           DESCRIPTION:    Insert thread into global list
;
;           PARAMETERS:     DS:DI       List
;                           ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertBlock Proc near
    mov es:p_sleep_sel,ds
    mov word ptr es:p_sleep_offset,di
    mov word ptr es:p_sleep_offset+2,0
    push di
    mov di,[di]
    or di,di
    je ibEmpty
;
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
    jmp ibDone
    
ibEmpty:
    mov es:p_next,es
    mov es:p_prev,es
    pop di
    mov [di],es

ibDone:
    ret
InsertBlock Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveCoreBlock
;
;           DESCRIPTION:    Remove thread from core list
;
;           PARAMETERS:     FS:SI       List
;                           ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveCoreBlock Proc near
    push si
    mov es,fs:[si]
    push di
    push ds
    mov di,es:p_next
    cmp di,fs:[si]
    mov fs:[si],di
    mov si,es:p_prev
    mov ds,di
    mov ds:p_prev,si
    mov ds,si
    mov ds:p_next,di
    pop ds
    pop di
    pop si
    jne rcbDone
;    
    mov word ptr fs:[si],0
    
rcbDone:
    ret
RemoveCoreBlock Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveBlock
;
;           DESCRIPTION:    Remove thread from global list
;
;           PARAMETERS:     DS:SI       List
;                           ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveBlock Proc near
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
    jne rblDone
;    
    mov word ptr [si],0

rblDone:
    ret
RemoveBlock Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InsertBlock
;
;           DESCRIPTION:    Insert thread into global list
;
;           PARAMETERS:     DS:EDI       List
;                           ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertBlock32 Proc near
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi
    push di
    mov di,[edi]
    or di,di
    je ib32Empty
;
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
    jmp ib32Done
    
ib32Empty:
    mov es:p_next,es
    mov es:p_prev,es
    pop di
    mov [edi],es
ib32Done:
    ret
InsertBlock32   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveBlock32
;
;           DESCRIPTION:    Remove thread from global list
;
;           PARAMETERS:     DS:ESI       List
;                           ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveBlock32 Proc near
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
    jne rb32Done
    
    mov word ptr [esi],0

rb32Done:
    ret
RemoveBlock32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FpuExceptionSingle
;
;           DESCRIPTION:    Notification FPU exception, single core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FpuExceptionSingle  Proc near
    push fs
;
    call LockCore
    mov ax,fs:cs_curr_thread    
    clts
;
    test fs:cs_flags,CS_FLAG_FPU
    jz fpu_exc_saved
;    
    mov bx,fs:cs_math_thread
    cmp ax,bx
    je fpu_exc_done
;
    mov ds,bx
    mov bx,OFFSET p_math_control
    db 9Bh, 66h, 0DDh, 37h      ;       32-bit fsave [bx]

fpu_exc_saved:
    mov ds,ax
    mov bx,OFFSET p_math_control
    db 9Bh, 66h, 0DDh, 27h      ;       32-bit frstor [bx]
;
    mov fs:cs_math_thread,ax
    lock or fs:cs_flags,CS_FLAG_FPU

fpu_exc_done:
    call UnlockCore
    pop fs    
    ret
FpuExceptionSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FpuExceptionMultiple
;
;           DESCRIPTION:    Notification FPU exception, multiple core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FpuExceptionMultiple  Proc near
    push fs
    call LockCore
;    
    mov ax,fs:cs_curr_thread    
    clts
    mov ds,ax
    mov bx,OFFSET p_math_control
    db 9Bh, 66h, 0DDh, 27h      ;       32-bit frstor [bx]
;
    mov fs:cs_math_thread,ax
    lock or fs:cs_flags,CS_FLAG_FPU
;
    call UnlockCore
    pop fs    
    ret
FpuExceptionMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FpuException
;
;           DESCRIPTION:    Notification FPU exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fpu_exception_name  DB 'Fpu Exception',0

fpu_exception       Proc far
    call cs:fpu_exception_proc
    retf32
fpu_exception       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FpuSaveSingle
;
;   DESCRIPTION:    Save FPU on thread switch, single core
;
;   PARAMETERS:     FS      Locked core
;                   DS      Current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FpuSaveSingle  Proc near
    test fs:cs_flags,CS_FLAG_FPU
    jz fpu_save_single_done
;
    push ebx
    mov ebx,cr0
    or bl,8
    mov cr0,ebx    
    pop ebx

fpu_save_single_done:    
    ret
FpuSaveSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FpuSaveMultiple
;
;   DESCRIPTION:    Save FPU on thread switch, multiple core
;
;   PARAMETERS:     FS      Locked core
;                   DS      Current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FpuSaveMultiple  Proc near
    test fs:cs_flags,CS_FLAG_FPU
    jz fpu_save_mult_done
;
    push ebx
;    
    mov bx,OFFSET p_math_control
    clts
    db 9Bh, 66h, 0DDh, 37h      ;       32-bit fsave [bx]
;
    lock and fs:cs_flags,NOT cS_FLAG_FPU
;
    mov ebx,cr0
    or bl,8
    mov cr0,ebx  
;
    pop ebx  

fpu_save_mult_done:
    ret
FpuSaveMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           NotifyTimeDrift
;
;           DESCRIPTION:    Notification of time drift
;
;           PARAMETERS:     DS      System data sel
;                           EAX     Drift in tics
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
    mov cx,SEG data
    mov es,cx
    mov es,es:patch_sel
;
    cdq
    sub es:time_diff,eax
    sbb es:time_diff+4,edx
;
    mov eax,es:time_diff
    mov edx,es:time_diff+4
;
    mov cx,time_data_sel
    mov es,cx
    mov es:ut_time_diff+1000h,eax
    mov es:ut_time_diff+1004h,edx

ntdDone:
    pop edx
    pop ecx
    pop eax
    pop es
    retf32
notify_time_drift  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HandlePreempt
;
;           DESCRIPTION:    Handle preempt
;
;           PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePreempt    Proc near
    test fs:cs_flags,CS_FLAG_PREEMPT
    jz hpDone
;
    mov si,fs:cs_prio_act
    mov ax,fs:[si]
    or ax,ax
    jz hpDone
;       
    cmp ax,fs:cs_last_thread
    jne hpDone
;    
    mov es,ax
    mov ax,es:p_next
    mov fs:[si],ax

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
;           PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePrio    Proc near
    mov si,fs:cs_prio_act
    mov ax,fs:[si]
    or ax,ax
    jnz hpqInt
;
    or si,si
    jz hpqDone
;
    sub si,2
    mov fs:cs_prio_act,si
    jmp HandlePrio

hpqInt:
    mov es,ax
    mov es,es:p_proc_sel
    test es:pf_virt_flags,200h
    jnz hpqDone
;
    cmp ax,es:pf_cli_thread
    je hpqDone
;
    mov ax,es
    mov si,fs:cs_prio_act
    call RemoveCoreBlock          
;    
    call cs:lock_list_proc
    push ds  
    mov ds,ax
    mov di,OFFSET pf_wait_sti
    call InsertBlock
    pop ds
    call cs:unlock_list_proc
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
;           PARAMETERS:     FS      Core selector
;
;       RETURNS:    ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPrioThread    Proc near
    mov si,fs:cs_prio_act
    mov ax,fs:[si]
    or ax,ax
    jz gptNull
;    
    call RemoveCoreBlock

gptLoop:
    mov ax,fs:[si]
    or ax,ax
    jnz gptDone
;
    or si,si    
    jz gptDone
;
    sub si,2
    mov fs:cs_prio_act,si
    jmp gptLoop

gptNull:
    mov es,fs:cs_null_thread

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
;           PARAMETERS:     FS      Core selector
;               ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupPreempt    Proc near
    mov ax,es
    cmp ax,fs:cs_null_thread
    je spSet
;    
    cmp ax,fs:cs_last_thread
    jne spSet
;
    test fs:cs_flags,CS_FLAG_PREEMPT
    jz spDone    

spSet:
    GetSystemTime
    mov ecx,eax
    add eax,1193
    adc edx,0
    mov fs:cs_preempt_lsb,eax
    mov fs:cs_preempt_msb,edx

spDone:
    lock and fs:cs_flags,NOT CS_FLAG_PREEMPT
    ret
SetupPreempt    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ThreadSuspend
;
;           DESCRIPTION:    Suspend thread callback from scheduler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
thread_suspend:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov eax,ds
    push eax
;
    NotifyThreadSuspend
;    
    pop eax
    mov ds,ax
    pop ebx
    pop eax
    pop ebp
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
    test dword ptr ds:p_rflags,20000h
    jnz acVm
;
    test ds:p_cs,3
    jnz acPm

acKernel:
    mov si,ss
    mov edi,esp
;    
    mov dx,ds:p_ss
    mov ss,dx
    mov esp,dword ptr ds:p_rsp
;
    xor dx,dx
    push dword ptr ds:p_rflags
    push dx
    push ds:p_cs
    push dword ptr ds:p_rip
;
    mov ds:p_ss,ss
    mov dword ptr ds:p_rsp,esp
    mov ss,si
    mov esp,edi
    jmp acDone

acPm:
    push es
    mov dx,ds:p_kernel_ss
    mov es,dx
    mov edi,ds:p_kernel_esp
    mov word ptr es:[edi-2],0
    pop es
;    
    mov si,ss
    mov edi,esp
;    
    mov ss,dx
    mov esp,ds:p_kernel_esp
;
    xor dx,dx
    push dx
    push ds:p_ss
    push dword ptr ds:p_rsp
    push dword ptr ds:p_rflags
    push dx
    push ds:p_cs
    push dword ptr ds:p_rip
;
    mov ds:p_ss,ss
    mov dword ptr ds:p_rsp,esp
    mov ss,si
    mov esp,edi
    jmp acDone

acVm:
    mov si,ss
    mov edi,esp
;    
    mov dx,ds:p_kernel_ss
    mov ss,dx
    mov esp,ds:p_kernel_esp
;
    xor dx,dx
    push dx
    push ds:p_gs
    push dx
    push ds:p_fs
    push dx
    push ds:p_ds
    push dx
    push ds:p_es
    push dx
    push ds:p_ss
    push dword ptr ds:p_rsp
    push dword ptr ds:p_rflags
    push dx
    push ds:p_cs
    push dword ptr ds:p_rip
;
    mov ds:p_ss,ss
    mov dword ptr ds:p_rsp,esp
    and dword ptr ds:p_rflags,NOT 20000h
    mov ss,si
    mov esp,edi

acDone:   
    mov ds:p_cs,cs
    movzx ebx,bx
    mov dword ptr ds:p_rip,ebx
;
    pop di
    pop si
    pop dx
    ret
AddCallback Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           TimerPreemptReload
;
;           DESCRIPTION:    Timer & preemption reload
;
;       PARAMETERS:         DS  Task sel
;                           FS  Core selector
;
;       RETURNS:            NC      Load a new task
;                           CY      Retry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TimerPreemptReload  Proc near

preempt_reload_loop:
    GetSystemTime
;
    call LockTimerCore
    mov fs:cs_last_lsb,eax
    add eax,cs:update_tics
    adc edx,0
    mov bx,fs:cs_timer_head
    mov ecx,fs:cs_preempt_msb
    cmp ecx,fs:[bx].timer_msb
    jc preempt_reload_check_preempt
;
    jnz preempt_reload_check_timer
;       
    mov ecx,fs:cs_preempt_lsb
    cmp ecx,fs:[bx].timer_lsb
    jc preempt_reload_check_preempt

preempt_reload_check_timer:
    sub eax,fs:[bx].timer_lsb
    sbb edx,fs:[bx].timer_msb
    jc preempt_reload_timer
;       
    call LocalRemoveTimerCore
    jmp preempt_reload_loop

preempt_reload_check_preempt:
    sub eax,fs:cs_preempt_lsb
    sbb edx,fs:cs_preempt_msb
    jc preempt_reload_timer
;       
    call UnlockTimerCore
    lock or fs:cs_flags,CS_FLAG_PREEMPT
    stc
    jmp preempt_timer_reload_done

preempt_reload_timer:
    neg eax
    ReloadSysPreemptTimer
    pushf
    call UnlockTimerCore
    popf
    jc preempt_reload_loop

preempt_timer_reload_done:
    ret
TimerPreemptReload  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PreemptReload
;
;           DESCRIPTION:    Preemption reload
;
;       PARAMETERS:         DS  Task sel
;                           FS  Core selector
;
;       RETURNS:            NC      Load a new task
;                           CY      Retry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PreemptReload  Proc near
    GetSystemTime
    mov fs:cs_last_lsb,eax
    sub eax,fs:cs_preempt_lsb
    sbb edx,fs:cs_preempt_msb
    jc preempt_reload_ok
;       
    lock or fs:cs_flags,CS_FLAG_PREEMPT
    stc
    jmp preempt_reload_done

preempt_reload_ok:
    neg eax
    ReloadPreemptTimer
    clc

preempt_reload_done:
    ret
PreemptReload  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           load_breaks
;
;       DESCRIPTION:    Load break-points
;
;       PARAMETERS:     FS  Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_breaks Proc near
    mov eax,dword ptr ds:p_dr0
    mov dr0,eax
    mov eax,dword ptr ds:p_dr1
    mov dr1,eax
    mov eax,dword ptr ds:p_dr2
    mov dr2,eax
    mov eax,dword ptr ds:p_dr3
    mov dr3,eax
    mov eax,dword ptr ds:p_dr7
    mov dr7,eax
    and ax,0FFh
    jnz load_break_done
;
    and es:p_flags,NOT THREAD_FLAG_BP
    
load_break_done:
    ret
load_breaks Endp    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LoadThread
;
;           DESCRIPTION:    Load a new thread
;
;       PARAMETERS:     FS  Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

thread_create:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    push word ptr 0
    push ds
    push es
;
    call trap_create_thread
;
    pop es
    pop ds
    pop ax
    pop ebx
    pop eax
    pop ebp
    add esp,4
    iretd    

LoadThread:
    test fs:cs_flags,cS_FLAG_P_STATE
    jz load_thread_loop
;    
    lock and fs:cs_flags,NOT CS_FLAG_P_STATE
    UpdatePState

load_thread_loop:
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    mov es,ax

load_thread_wakeup_loop:    
    cli
    mov ax,fs:cs_wakeup_count
    or ax,ax
    jz load_thread_wakeup_done
;
    call RemoveWakeup
;    
    mov di,es:p_prio
    call InsertCoreBlock
    cmp di,fs:cs_prio_act
    jbe load_thread_wakeup_loop
;       
    lock or fs:cs_flags,CS_FLAG_PRIO_CHANGE
    mov fs:cs_prio_act,di
    jmp load_thread_wakeup_loop
    
load_thread_wakeup_done:
    xor ax,ax
    mov es,ax
    sti    
    lock and fs:cs_flags,NOT CS_FLAG_PRIO_CHANGE
;
    call HandlePreempt
    call HandlePrio
    call GetPrioThread
    call SetupPreempt
;
    xor ax,ax
    xchg ax,es:p_wanted_core
    or ax,ax
    jz load_reload_loop
;
    mov es:p_core,ax
    mov dx,fs
    cmp dx,ax
    jz load_reload_loop
;    
    call InsertLockedWakeup
    jmp load_thread_loop

load_reload_loop:
    call cs:preempt_reload_proc
    jnc load_a_task
    
load_retry:
    mov ax,SEG data
    mov ds,ax
;
    test fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    jz load_timer_not_expired
;
    call cs:update_timer_proc

load_timer_not_expired:        
    mov ax,es
    cmp ax,fs:cs_null_thread
    je load_thread_loop
;    
    mov di,es:p_prio
    call InsertCoreFirst
    cmp di,fs:cs_prio_act
    jbe load_thread_loop
;
    mov fs:cs_prio_act,di
    lock or fs:cs_flags,CS_FLAG_PRIO_CHANGE
    jmp load_thread_loop

load_a_task:
    mov es:p_sleep_type,0
    lock or fs:cs_flags,CS_FLAG_LOADING
    mov ax,gdt_sel
    mov ds,ax
    mov bx,es:p_tss_sel
    or bx,bx
    jnz load_protected_mode

load_long_mode:
    test fs:cs_flags,CS_FLAG_LONG_MODE
    jnz load_not_flush
;    
    mov bx,fs:cs_long_tr
    and byte ptr ds:[bx+5],NOT 2
    ltr bx
;    
    mov eax,es:p_cr3
    SwitchToLongMode
    lock or fs:cs_flags,CS_FLAG_LONG_MODE
    jmp load_not_flush

load_protected_mode:    
    test fs:cs_flags,CS_FLAG_LONG_MODE
    jz load_prot_switch_ok
;
    mov eax,es:p_cr3
    SwitchToProtectedMode
    lock and fs:cs_flags, NOT CS_FLAG_LONG_MODE

load_prot_switch_ok:    
    mov bx,es:p_tss_sel
    and byte ptr ds:[bx+5],NOT 2
    ltr bx

load_not_flush:
    mov ax,es:p_serv_sel
    mov fs:cs_serv_sel,ax
;
    mov eax,cr3
    cmp eax,es:p_cr3
    je load_cr3_ok
;
    mov eax,es:p_cr3
    mov cr3,eax
    mov fs:cs_tlb.pt32_used,0
    and ax,0F000h
    mov fs:cs_cr3,eax
    jmp load_cr3_flush_ok

load_cr3_ok:
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz load_cr3_flush_ok
;
    call cs:flush_tlb_proc

load_cr3_flush_ok:
    mov ax,es
    mov ds,ax
    lldt ds:p_ldt
;
    mov ax,ds:p_flags
    or ax,ax
    jz load_bp_done
;
    test ax,THREAD_FLAG_CREATE
    jz load_create_done
;
    and ds:p_flags,NOT THREAD_FLAG_CREATE
    mov bx,OFFSET thread_create
    call AddCallback
    
load_create_done:
    mov ax,ds:p_flags
    test ax,THREAD_FLAG_SUSPEND
    jz load_suspend_done
;
    and ds:p_flags,NOT THREAD_FLAG_SUSPEND
    mov bx,OFFSET thread_suspend
    call AddCallback

load_suspend_done:
    mov ax,ds:p_flags
    test ax,THREAD_FLAG_BP
    jz load_bp_done
;
    test fs:cs_flags,CS_FLAG_LONG_MODE
    jz load_prot_breaks
;
    mov edx,ds:p_linear
    LoadLongBreaks
    jmp load_actions_done

load_prot_breaks:    
    call load_breaks
    jmp load_actions_done

load_bp_done:
    xor eax,eax
    mov dr7,eax

load_actions_done: 
    cli
    call LoadUnlockCore
;
    mov ax,fs:cs_wakeup_count
    or ax,ax
    jnz load_relock
;
    test fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    jnz load_relock    
;
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz load_regs

load_relock:
    call LockCore
    sti
    jmp load_retry
        
load_regs:
    test fs:cs_flags,CS_FLAG_LONG_MODE
    jz load_prot_regs
;    
    mov fs:cs_curr_thread,es
    mov fs:cs_last_thread,es
    lock and fs:cs_flags,NOT CS_FLAG_LOADING
;
    mov eax,es:p_kernel_stack
    mov fs:cs_syscall_esp,eax
;    
    mov eax,dword ptr es:p_tls_linear
    mov fs:cs_tls_linear,eax
    mov eax,dword ptr es:p_tls_linear+4
    mov fs:cs_tls_linear+4,eax
;    
    mov edx,es:p_linear
    mov edi,fs:cs_tr_linear
    LoadLongRegs

load_prot_regs:
    mov fs:cs_curr_thread,es
    mov fs:cs_last_thread,es
    lock and fs:cs_flags,NOT cS_FLAG_LOADING
;
    test dword ptr ds:p_rflags,20000h
    jnz load_vm
;
    test ds:p_cs,3
    jnz load_pm_app

load_kernel:
    mov ax,ds:p_ss
    mov ss,ax
    mov esp,dword ptr ds:p_rsp
;
    xor ax,ax
    push dword ptr ds:p_rflags
    push ax
    push ds:p_cs
    push dword ptr ds:p_rip
;       
    mov ecx,dword ptr ds:p_rcx
    mov edx,dword ptr ds:p_rdx
    mov ebx,dword ptr ds:p_rbx
    mov ebp,dword ptr ds:p_rbp
    mov esi,dword ptr ds:p_rsi
    mov edi,dword ptr ds:p_rdi
;
    mov ax,ds:p_es
    verr ax
    jz load_kernel_es
;
    xor ax,ax
    
load_kernel_es:
    mov es,ax
;       
    mov ax,ds:p_fs
    verr ax
    jz load_kernel_fs
;
    xor ax,ax
    
load_kernel_fs:
    mov fs,ax
;       
    mov ax,ds:p_gs
    verr ax
    jz load_kernel_gs
;
    xor ax,ax
    
load_kernel_gs:
    mov gs,ax
;       
    mov ax,ds:p_ds
    verr ax
    jz load_kernel_ds
;
    xor ax,ax
    
load_kernel_ds:
    push ax
    mov eax,dword ptr ds:p_rax
    pop ds
    iretd

load_pm_app:    
    mov ax,ds:p_kernel_ss
    mov ss,ax
    mov esp,ds:p_kernel_esp
;
    xor ax,ax
    push ax
    push ds:p_ss
    push dword ptr ds:p_rsp
    push dword ptr ds:p_rflags
    push ax
    push ds:p_cs
    push dword ptr ds:p_rip
;       
    mov ecx,dword ptr ds:p_rcx
    mov edx,dword ptr ds:p_rdx
    mov ebx,dword ptr ds:p_rbx
    mov ebp,dword ptr ds:p_rbp
    mov esi,dword ptr ds:p_rsi
    mov edi,dword ptr ds:p_rdi
;
    mov ax,ds:p_es
    verr ax
    jz load_pm_app_es
;
    xor ax,ax
    
load_pm_app_es:
    mov es,ax
;       
    mov ax,ds:p_fs
    verr ax
    jz load_pm_app_fs
;
    xor ax,ax
    
load_pm_app_fs:
    mov fs,ax
;       
    mov ax,ds:p_gs
    verr ax
    jz load_pm_app_gs
;
    xor ax,ax
    
load_pm_app_gs:
    mov gs,ax
;       
    mov ax,ds:p_ds
    verr ax
    jz load_pm_app_ds
;
    xor ax,ax
    
load_pm_app_ds:
    push ax
    mov eax,dword ptr ds:p_rax
    pop ds
    iretd

load_vm:
    mov ax,ds:p_kernel_ss
    mov ss,ax
    mov esp,ds:p_kernel_esp
;
    xor ax,ax
    push ax
    push ds:p_gs
    push ax
    push ds:p_fs
    push ax
    push ds:p_ds
    push ax
    push ds:p_es
    push ax
    push ds:p_ss
    push dword ptr ds:p_rsp
    push dword ptr ds:p_rflags
    push ax
    push ds:p_cs
    push dword ptr ds:p_rip
;
    mov eax,dword ptr ds:p_rax
    mov ecx,dword ptr ds:p_rcx
    mov edx,dword ptr ds:p_rdx
    mov ebx,dword ptr ds:p_rbx
    mov ebp,dword ptr ds:p_rbp
    mov esi,dword ptr ds:p_rsi
    mov edi,dword ptr ds:p_rdi
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
;       RETURNS:    SS:SP       Core stack
;               FS          Core selector
;               ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveCurrentThread       Proc near       
    push fs
    push ds
    push eax
    push edx
;    
    call LockCore    
    sti
;
    GetSystemTime
    mov ds,fs:cs_curr_thread
    sub eax,fs:cs_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    add fs:cs_lsb_tics,eax
    adc fs:cs_msb_tics,0
;    
    pushfd
    pop eax
    or ax,200h
    mov dword ptr ds:p_rflags,eax    
;
    pushf
    pop ax    
    and ax,NOT 100h
    push ax
    popf
;
    mov dword ptr ds:p_rcx,ecx
    mov dword ptr ds:p_rbx,ebx
    mov dword ptr ds:p_rbp,ebp
    mov dword ptr ds:p_rsi,esi
    mov dword ptr ds:p_rdi,edi
    mov ds:p_es,es
    mov ds:p_cs,cs
    mov ds:p_ss,ss
    mov ds:p_gs,gs
;
    pop dword ptr ds:p_rdx
    pop eax
    mov dword ptr ds:p_rax,eax
;
    pop ds:p_ds
    pop ds:p_fs
    pop bp
    pop dx
    movzx edx,dx
    mov dword ptr ds:p_rip,edx
    mov dword ptr ds:p_rsp,esp
;
    lss esp,fword ptr fs:cs_stack_offset
    call cs:fpu_save_proc
    mov edx,dword ptr ds:p_rdx    
    push bp
;
    xor bp,bp
    mov ds,bp
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
;               FS      Core selector
;
;       RETURNS:    SS:SP       Processor stack
;               ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveLockedThread    Proc near       
    push fs
    push ds
    push eax
    push edx
;
    mov ax,fs:cs_curr_thread
    or ax,ax
    jnz sltSave
;
    add esp,12
    pop bp
    lss esp,fword ptr fs:cs_stack_offset        
    push bp
;
    xor bp,bp
    mov ds,bp
    mov es,bp
    mov gs,bp    
    ret
    
sltSave:    
    mov ds,ax
    GetSystemTime
    sub eax,fs:cs_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    add fs:cs_lsb_tics,eax
    adc fs:cs_msb_tics,0
;
    pushfd
    pop eax
    or ax,200h
    mov dword ptr ds:p_rflags,eax
    mov dword ptr ds:p_rcx,ecx
    mov dword ptr ds:p_rbx,ebx
    mov dword ptr ds:p_rbp,ebp
    mov dword ptr ds:p_rsi,esi
    mov dword ptr ds:p_rdi,edi
    mov ds:p_es,es
    mov ds:p_cs,cs
    mov ds:p_ss,ss
    mov ds:p_gs,gs
;
    pop dword ptr ds:p_rdx
    pop eax
    mov dword ptr ds:p_rax,eax
;
    pop ds:p_ds
    pop ds:p_fs
    pop bp
    pop dx
    movzx edx,dx
    mov dword ptr ds:p_rip,edx
    mov dword ptr ds:p_rsp,esp
;
    lss esp,fword ptr fs:cs_stack_offset        
    call cs:fpu_save_proc
    mov edx,dword ptr ds:p_rdx
    push bp
;
    xor bp,bp
    mov ds,bp
    mov es,bp
    mov gs,bp    
    ret
SaveLockedThread   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SaveIrqThread
;
;       DESCRIPTION:    Save state of current thread when lock is already taken in IRQ
;                       Will return with interrupts disable to forece the stack to unwind.
;
;       PARAMETERS:     Stack, return IP
;                       FS      Core selector
;
;       RETURNS:        SS:SP       Processor stack
;                       ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveIrqThread    Proc near       
    push fs
    push ds
    push eax
    push edx
;
    mov ax,fs:cs_curr_thread
    mov ds,ax
    GetSystemTime
    sub eax,fs:cs_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    add fs:cs_lsb_tics,eax
    adc fs:cs_msb_tics,0
;
    pushfd
    pop eax
    and ax,NOT 200h
    mov dword ptr ds:p_rflags,eax
    mov dword ptr ds:p_rcx,ecx
    mov dword ptr ds:p_rbx,ebx
    mov dword ptr ds:p_rbp,ebp
    mov dword ptr ds:p_rsi,esi
    mov dword ptr ds:p_rdi,edi
    mov ds:p_es,es
    mov ds:p_cs,cs
    mov ds:p_ss,ss
    mov ds:p_gs,gs
;
    pop dword ptr ds:p_rdx
    pop eax
    mov dword ptr ds:p_rax,eax
;
    pop ds:p_ds
    pop ds:p_fs
    pop bp
    pop dx
    movzx edx,dx
    mov dword ptr ds:p_rip,edx
    mov dword ptr ds:p_rsp,esp
;
    lss esp,fword ptr fs:cs_stack_offset        
    call cs:fpu_save_proc
    mov edx,dword ptr ds:p_rdx
    push bp
;
    xor bp,bp
    mov ds,bp
    mov es,bp
    mov gs,bp    
    ret
SaveIrqThread   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SkipCurrentThread
;
;           DESCRIPTION:    Skip current thread (no save of registers)
;
;       RETURNS:    SS:SP       Core stack
;               FS      Core selector
;               ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SkipCurrentThread       Proc near       
    call LockCore
    sti
    push eax
    push ds
    GetSystemTime
    mov ds,fs:cs_curr_thread
    sub eax,fs:cs_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    add fs:cs_lsb_tics,eax
    adc fs:cs_msb_tics,0
    pop ds
    pop eax
;    
    pop bp    
    lss esp,fword ptr fs:cs_stack_offset        
    push bp
;
    xor bp,bp
    mov ds,bp
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
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ContinueCurrentThread:
    mov ax,fs:cs_curr_thread
    or ax,ax
    jz cctDone
;
    push es
    mov es,ax
    mov di,es:p_prio
    or di,di
    je cctPop
;
    call InsertCoreBlock
    cmp di,fs:cs_prio_act
    jbe cctPop
;
    mov fs:cs_prio_act,di
    lock or fs:cs_flags,CS_FLAG_PRIO_CHANGE

cctPop:
    pop es    

cctDone:
    mov fs:cs_curr_thread,0
    jmp LoadThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RunApCore
;
;           DESCRIPTION:    Run AP core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_ap_core_name    DB 'Run AP Core', 0

run_ap_core:
    mov eax,cr0
    or eax,10008h
    mov cr0,eax    
;
    mov ax,system_data_sel
    mov es,ax
    mov eax,es:cpu_feature_flags
    test eax,10000h
    jz run_ap_pat_done
;
    mov ecx,IA32_PAT
    rdmsr
    and ah,NOT 7
    or ah,1
    wrmsr

run_ap_pat_done:
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:cs_sel
    mov es,fs:cs_null_thread
    mov es:p_active,1
;
    StartSyscall

run_core_do:  
    call LockCore
    sti
    lock or fs:cs_flags,CS_FLAG_PREEMPT    
    jmp LoadThread
    
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
    mov es,es:p_kernel_ss
    FreeMem
    pop es
;
    mov bx,es:p_tss_sel
    FreeGdt
;    
    mov edx,es:p_tss_linear
    mov ecx,SIZE tss32_seg
    FreeLinear
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
    push es
    mov es,es:p_kernel_ss
    FreeMem
    pop es
;
    mov bx,es:p_tss_sel
    FreeGdt
;    
    mov edx,es:p_tss_linear
    mov ecx,SIZE tss32_seg
    FreeLinear
;
    mov eax,es:p_cr3
    FreeMem
    NotifyDeleteProcess    
    ret
DeleteProcess   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           delete_process_sel
;
;       DESCRIPTION:    Delete process selector
;
;       PARAMETERS:     ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_process_sel Proc near
    push ds
    push es
    pushad
;
    mov ds,es:p_proc_sel
    mov ax,ds:pf_cur_dir_sel
    DeleteCurDir
;
    mov ax,ds:pf_env_sel
    DeleteEnvSel
;
    mov ax,es:p_proc_id
    mov ds,es:p_prog_sel
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_process_count
    xor ebx,ebx
    or ecx,ecx
    jz dpsLeave

dpsLoop:
    cmp ax,ds:[2*ebx].pr_process_arr
    je dpsFound
;
    inc ebx
    loop dpsLoop
;
    jmp dpsLeave

dpsFound:
    dec ds:pr_process_count
;
    mov ax,ds:pr_page_table_count
    or ax,ax
    jz dpsTablesOk
;
    dec ax
    mov ds:pr_page_table_count,ax

dpsTablesOk:
    sub ecx,1
    jz dpsLeave

dpsMove:
    mov ax,ds:[2*ebx+2].pr_process_arr
    mov ds:[2*ebx].pr_process_arr,ax
;
    mov eax,ds:[4*ebx+4].pr_page_dir_arr
    mov ds:[4*ebx].pr_page_dir_arr,eax
;
    mov eax,ds:[4*ebx+4].pr_page_table_arr
    mov ds:[4*ebx].pr_page_table_arr,eax
;    
    inc ebx
    loop dpsMove

dpsLeave:
    LeaveSection ds:pr_section
;
    popad
    pop es
    pop ds
    ret
delete_process_sel Endp

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
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:patch_sel
    GetThread
    mov ds:system_thread,ax
;
    mov ax,SEG data
    mov ds,ax    

stLoop:
    WaitForSignal

stThreadLoop:
    mov si,OFFSET term_thread_list
    mov ax,[si]
    or ax,ax
    jz stThreadOK
;
    call cs:lock_list_proc
    call RemoveBlock
    call cs:unlock_list_proc
;    
    push ds
    GetThread
    mov ds,ax
    mov ax,es:p_proc_id
    mov ds:p_proc_id,ax
    pop ds
;
    call DeleteThread
    jmp stThreadLoop

stThreadOk:
    mov si,OFFSET term_proc_list
    mov ax,[si]
    or ax,ax
    jz stLoop
;
    call cs:lock_list_proc
    call RemoveBlock
    call cs:unlock_list_proc
;    
    push ds
    GetThread
    mov ds,ax
    mov ax,es:p_proc_id
    mov ds:p_proc_id,ax
    pop ds
;
    call delete_process_sel
;
    push ds
    mov bx,es:p_prog_id
    mov ds,es:p_proc_sel
    RemovedProcess
    pop ds
;
    push ds
    movzx ebx,es:p_proc_sel
    mov ds,ebx
    movzx eax,ds:pf_exit_code
    ProcessTerminated
    pop ds
;
    push es
    mov es,ebx
    FreeMem
    pop es
;
    call DeleteProcess
    jmp stThreadLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ToHex
;
;           DESCRIPTION:    
;
;           PARAMETERS:     AL          Number
;
;           RETURNS:        AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ToHex      PROC near

hex_conv_low:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;    
    add ah,7

ok_high1:
    add ah,30h
    ret
ToHex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartProcessorNullThreads
;
;           DESCRIPTION:    Start each of the null threads for a processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


start_processor_null_threads    Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov al,ds:cpu_type
    cmp al,3
    jbe start_locks_ok
;
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:patch_sel
    mov ds:flush_tlb_proc,OFFSET FlushTlb486
;    
    GetCoreCount
    cmp cx,1
    jbe start_locks_ok
;
    mov ds:lock_list_proc,OFFSET LockListMultiple
    mov ds:unlock_list_proc,OFFSET UnlockListMultiple
    mov ds:lock_signal_proc,OFFSET LockSignalMultiple
    mov ds:unlock_signal_proc,OFFSET UnlockSignalMultiple
    mov ds:lock_wait_dev_proc,OFFSET LockWaitDevMultiple
    mov ds:unlock_wait_dev_proc,OFFSET UnlockWaitDevMultiple
    mov ds:lock_kernel_section_proc,OFFSET LockKernelSectionMultiple
    mov ds:unlock_kernel_section_proc,OFFSET UnlockKernelSectionMultiple
    mov ds:lock_user_section_proc,OFFSET LockUserSectionMultiple
    mov ds:unlock_user_section_proc,OFFSET UnlockUserSectionMultiple
    mov ds:lock_futex_proc,OFFSET LockFutexMultiple
    mov ds:unlock_futex_proc,OFFSET UnlockFutexMultiple
    mov ds:lock_block_proc,OFFSET LockBlockMultiple
    mov ds:unlock_block_proc,OFFSET UnlockBlockMultiple
    mov ds:fpu_exception_proc,OFFSET FpuExceptionMultiple
    mov ds:fpu_save_proc,OFFSET FpuSaveMultiple

start_locks_ok:
    mov ecx,stack0_size
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET system_thread_pr
    mov di,OFFSET system_thread_name
    mov ax,1
    CreateThread
;    
    mov eax,16
    AllocateSmallGlobalMem
    xor di,di
    mov eax,cs:dword ptr core_name_base
    stosd
    mov al,' '
    stosb
    mov al,'0'
    stosb
    mov al,'1'
    stosb
    xor al,al
    stosb
;
    GetCoreCount
    mov bx,1
    sub cx,1
    jz start_processor_free

create_null_loop:
    push cx
    mov ax,cs
    mov ds,ax
    xor ax,ax
    mov ecx,stack0_size
    mov si,OFFSET null_thread
    xor di,di
    CreateThread
    pop cx
;
    inc bx
    mov al,bl
    call ToHex
    mov di,5
    mov es:[di],ax
    loop create_null_loop

start_processor_free:
    FreeMem
    ret
start_processor_null_threads    Endp

core_name_base   DB 'Core'

null_thread0:
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:cs_sel
    mov ax,fs:cs_curr_thread
    mov es,ax
    mov es:p_sleep_sel,fs
    mov es:p_sleep_offset,0
    mov fs:cs_null_thread,ax
    mov es:p_core,fs
    lock or fs:cs_flags,CS_FLAG_ACTIVE
;
    mov ax,start_core_nr
    IsValidOsGate
    jc null_ap_ok
;
    SetupSmpPatch

null_ap_ok:   
    push OFFSET null_loop_start
    call SaveCurrentThread
;    
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0    
    jmp LoadThread

null_thread:
    sti
    mov ax,bx
    GetCoreNumber
    GetThread
    mov es,ax
    mov es:p_sleep_sel,fs
    mov es:p_sleep_offset,0
    mov fs:cs_null_thread,ax
    mov es:p_core,fs
    mov es:p_wanted_core,0    
;
    push OFFSET null_loop_start
    call SaveCurrentThread
;    
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0    
    jmp LoadThread

null_loop_start:
    mov ss,es:p_kernel_ss
    mov esp,es:p_kernel_esp
    GetCore
    
null_loop:
    test fs:cs_flags,CS_FLAG_SHUTDOWN
    jz null_hlt
;
    push OFFSET null_loop_start
    call SaveCurrentThread
;
    call UnlockCore
    lock and fs:cs_flags,NOT CS_FLAG_SHUTDOWN
    mov fs:cs_curr_thread,0
    ShutdownCore    

null_hlt:  
    mov ax,fs:cs_nesting
    cmp ax,-1
    je null_nest_ok
;    
    CrashGate

null_nest_ok:      
    mov ax,fs:cs_wakeup_count
    or ax,ax
    jz null_wakeup_ok
;
;    CrashGate

null_wakeup_ok:
    hlt
    jmp null_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemoveWakeup
;
;           DESCRIPTION:    Remove wakeup
;
;           RETURNS:        ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveWakeup  PROC near
    push ax
    push bx
    push cx
;
    mov bx,OFFSET cs_wakeup_arr
    mov cx,CORE_WAKEUP_ENTRIES

rwLoop:
    xor ax,ax
    xchg ax,fs:[bx]
    or ax,ax
    jnz rwOk
;
    add bx,2
    loop rwLoop
;
    CrashGate

rwOk:
    mov es,ax
    lock sub fs:cs_wakeup_count,1
;
    pop cx
    pop bx    
    pop ax
    ret
RemoveWakeup  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddWakeup
;
;           DESCRIPTION:    Add to wakeup
;
;           PARAMETERS:     ES      Thread
;                           FS      Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddWakeup  PROC near
    push ax
    push bx
    push cx
    push dx
;
    mov bx,OFFSET cs_wakeup_arr
;
    mov es:p_sleep_sel,fs
    mov word ptr es:p_sleep_offset,bx
;
    mov cx,CORE_WAKEUP_ENTRIES
    mov dx,es

awLoop:
    mov ax,fs:[bx]
    or ax,ax
    jnz awNext
;
    xchg dx,fs:[bx]
    or dx,dx
    jz awAdd

awNext:
    add bx,2
    loop awLoop    
;
    CrashGate
   
awAdd:
    lock add fs:cs_wakeup_count,1
;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
AddWakeup  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InsertLockedWakeup
;
;           DESCRIPTION:    Add to wakeup. Scheduler must be locked
;
;           PARAMETERS:     ES      Thread
;                           FS      Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertLockedWakeup  PROC near
    push ax
    push di
;
    mov ax,fs
    mov di,es:p_core
    cmp ax,di
    jne iwOther

iwSelf:    
    call AddWakeup
    jmp iwDone
    
iwOther:    
    push fs
    mov fs,di
;
    call AddWakeup
;    
    mov al,81h
    SendLockedInt

iwIntOk:
    pop fs

iwDone:    
    pop di
    pop ax
    ret
InsertLockedWakeup  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockSignalSingle
;
;           DESCRIPTION:    Lock signal, single core
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockSignalSingle  PROC near
    sti
    ret
LockSignalSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockSignalMultiple
;
;           DESCRIPTION:    Lock signal, multiple core
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockSignalMultiple  PROC near
    push ax

lsmTryLock:    
    mov ax,es:p_signal_spinlock
    or ax,ax
    je lsmGet
;
    sti
    pause
    jmp lsmTryLock

lsmGet:
    cli
    inc ax
    xchg ax,es:p_signal_spinlock
    or ax,ax
    je lsmLocked
;
    sti
    jmp lsmTryLock

lsmLocked:
    pop ax
    ret
LockSignalMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockSignalSingle
;
;           DESCRIPTION:    Unlock signal, single core
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockSignalSingle  PROC near
    sti
    ret
UnlockSignalSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockSignalMultiple
;
;           DESCRIPTION:    Unlock signal, multiple core
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockSignalMultiple  PROC near
    mov es:p_signal_spinlock,0
    sti
    ret
UnlockSignalMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockWaitDevSingle
;
;           DESCRIPTION:    Lock wait dev, single core
;
;           PARAMETERS:     DS:SI    Wait dev struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockWaitDevSingle  PROC near
    sti
    ret
LockWaitDevSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockWaitDevMultiple
;
;           DESCRIPTION:    Lock wait dev, multiple core
;
;           PARAMETERS:     DS:SI    Wait dev struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockWaitDevMultiple  PROC near
    push ax

lwdmTryLock:    
    mov al,ds:[si].wd_lock
    or al,al
    je lwdmGet
;
    sti
    pause
    jmp lwdmTryLock

lwdmGet:
    cli
    inc al
    xchg al,ds:[si].wd_lock
    or al,al
    je lwdmLocked
;
    sti
    jmp lwdmTryLock

lwdmLocked:
    pop ax
    ret
LockWaitDevMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockWaitDevSingle
;
;           DESCRIPTION:    Unlock wait dev, single core
;
;           PARAMETERS:     DS:SI    Wait dev struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockWaitDevSingle  PROC near
    sti
    ret
UnlockWaitDevSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockWaitDevMultiple
;
;           DESCRIPTION:    Unlock wait dev, multiple core
;
;           PARAMETERS:     DS:SI    Wait dev struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockWaitDevMultiple  PROC near
    mov ds:[si].wd_lock,0
    sti
    ret
UnlockWaitDevMultiple  Endp

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
    mov ds,dx
    call TryLockCore
    sti
;
    mov di,ds:[esi]
    or di,di
    jz wtUnlock
;       
    call cs:lock_list_proc
    call RemoveBlock32
    mov es:p_data,eax
    call cs:unlock_list_proc
    call InsertLockedWakeup
    
wtUnlock:    
    call TryUnlockCore
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
;       NAME:           DebugBlock
;
;       DESCRIPTION:    Block thread into debug list
;
;       PARAMETERS:     FS  Core block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_block_name        DB 'Debug Block', 0

debug_block:
    mov ds,fs:cs_curr_thread
    lss esp,fword ptr fs:cs_stack_offset        
    call cs:fpu_save_proc    
;
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov gs,ax    
;    
    mov es,fs:cs_curr_thread
    mov ds,es:p_prog_sel
    mov ax,ds:pr_debug_id
    or ax,ax
    jz debug_block_do
;
    KernelDebugEvent

debug_block_do:
    mov fs:cs_curr_thread,0
;    
    mov ax,system_data_sel
    mov ds,ax
    mov edi,OFFSET debug_list       
;
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
;
    mov es:p_sleep_type,SLEEP_TYPE_DEBUG
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi
    jmp LoadThread        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DebugRealtime
;
;       DESCRIPTION:    Put realtime task in debug list
;
;       PARAMETERS:     FS  Core block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_realtime_name        DB 'Debug Realtime', 0

debug_realtime  Proc far
    push ds
    push es
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    mov edi,OFFSET debug_list       
    mov es,fs:cs_null_thread
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
    mov es:p_sleep_type,SLEEP_TYPE_DEBUG
;
    popad
    pop es
    pop ds
    retf32
debug_realtime  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunRealtime
;
;       DESCRIPTION:    Run realtime task (remove from debug list)
;
;       PARAMETERS:     FS  Core block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_realtime_name        DB 'Run Realtime', 0

run_realtime    Proc far
    push ds
    push es
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    mov esi,OFFSET debug_list       
    mov es,fs:cs_null_thread
    call cs:lock_list_proc
    call RemoveBlock32
    call cs:unlock_list_proc
;
    popad
    pop es
    pop ds
    retf32
run_realtime    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PreemptNotify
;
;       DESCRIPTION:    Default preempt procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

preempt_notify_name   DB 'Preempt Notify',0

preempt_notify    Proc far
    retf32
preempt_notify    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateLongTss
;
;       DESCRIPTION:    Create long-mode TSS
;
;       RETURNS:        BX      TSS selector 
;                       EDX     Tss linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_long_tss   Proc near
    push es
    push eax
    push ecx
;
    mov ax,flat_sel
    mov es,ax
;    
    mov eax,SIZE tss64_seg
    mov ecx,eax
    AllocateSmallLinear
    mov edi,edx
;    
    push ecx
    push edi
    xor al,al
    rep stos byte ptr es:[edi]
    pop edi
    pop ecx
;
    mov es:[edi].tss64_bitmap,OFFSET tss64_io_bitmap
;
    mov eax,1000h
    AllocateBigLinear
    mov dword ptr es:[edi].tss64_ist1,edx    
;
    mov eax,1000h
    AllocateBigLinear
    mov dword ptr es:[edi].tss64_ist2,edx    
;    
    mov ecx,SIZE tss64_seg
    mov edx,edi
    AllocateGdt
    CreateTssSelector
;
    pop ecx
    pop eax
    pop es
    ret
create_long_tss   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddDumpCore
;
;           DESCRIPTION:    Add dump core
;
;           PARAMETERS:     ES  core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDumpCore    Proc near
    pushad
    push ds
    push es
;    
    mov si,core_image_sel
    mov ds,si
    mov si,ds:ic_cores
    cmp si,16
    jb adcDo
;
    xor si,si
    jmp adcDone    

adcDo:
    mov eax,4000h
    AllocateBigLinear
;
    inc ds:ic_cores
    shl si,2
    add si,OFFSET ic_linear
    mov es:cs_dump_offset,si    
;    
    mov ds:[si],edx
;    
    mov si,core_save_sel
    mov ds,si
    mov si,ds:sc_cores
;
    inc ds:sc_cores
    shl si,5
    add si,OFFSET sc_phys
    mov edi,edx
;
    AllocatePhysical64
    mov dword ptr ds:[si].scp_core_phys,eax
    mov dword ptr ds:[si].scp_core_phys+4,ebx
    mov al,13h
    SetPageEntry
    add edx,1000h
;        
    AllocatePhysical64
    mov dword ptr ds:[si].scp_stack_phys,eax
    mov dword ptr ds:[si].scp_stack_phys+4,ebx
    mov al,13h
    SetPageEntry
    add edx,1000h
;        
    AllocatePhysical64
    mov dword ptr ds:[si].scp_log_phys,eax
    mov dword ptr ds:[si].scp_log_phys+4,ebx
    mov al,13h
    SetPageEntry
    add edx,1000h
;        
    AllocatePhysical64
    mov dword ptr ds:[si].scp_log_phys+8,eax
    mov dword ptr ds:[si].scp_log_phys+12,ebx
    mov al,13h
    SetPageEntry
;    
    mov ax,flat_sel
    mov es,ax
    mov ecx,1000h
    xor eax,eax
    rep stos dword ptr es:[edi]    
        
adcDone:
    pop es
    pop ds    
    popad
    ret
AddDumpCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitCore
;
;       DESCRIPTION:    Init core
;
;       PARAMETERS:     ES      Core sel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitCore    Proc near
    pushad
;
    HasLongMode
    jnc icFlatStack
;    
    mov eax,1000h
    AllocateBigLinear
    AllocateGdt
;    
    mov ecx,1000h
    CreateDataSelector32
;
    mov ds,bx
    mov ds:[0],dx
    mov es:cs_stack_offset,ecx
    mov es:cs_stack_sel,bx
    jmp icStackOk    
    
icFlatStack:
    mov ax,flat_sel
    mov ds,ax
;
    mov eax,3000h
    AllocateBigLinear
    xor ebx,ebx
    mov eax,4
    SetPageEntry
    add edx,2000h
    SetPageEntry
    sub edx,1000h
;    
    mov ds:[edx],dx
    add edx,1000h
    mov es:cs_stack_offset,edx
    mov es:cs_stack_sel,long_kernel_data_sel
    
icStackOk:
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:patch_sel
    mov ax,ds:core_count
    mov si,ax
    add si,si
    mov ds:[si].core_arr,es
    inc ds:core_count
    mov es:cs_id,ax    
;
    xor ax,ax
    mov ds,ax
    mov bx,OFFSET cs_ptab
    mov es:cs_prio_act,bx
;
    mov cx,256

icPtabInit:
    mov es:[bx],ax
    add bx,2
    loop icPtabInit
;
    mov cx,CORE_WAKEUP_ENTRIES
    mov bx,OFFSET cs_wakeup_arr
    xor ax,ax

icWakeupInit:
    mov es:[bx],ax
    add bx,2
    loop icWakeupInit
;
    mov es:cs_serv_sel,0
    mov es:cs_wakeup_count,0
    mov es:cs_nesting,-1
    mov es:cs_curr_thread,0
    mov es:cs_last_thread,-1
    mov es:cs_flags,CS_FLAG_INIT_CLOCK
    mov es:cs_null_thread,0
    mov es:cs_math_thread,0
    mov es:cs_apic,-1
    mov es:cs_last_lsb,0
    mov es:cs_lsb_tics,0
    mov es:cs_msb_tics,0
    mov es:cs_tlb.pt32_locked,0
    mov es:cs_tlb.pt32_used,0
    mov eax,cr3
    and ax,0F000h
    mov es:cs_cr3,eax
;
    mov es:cs_timer_spinlock,0
    mov bx,OFFSET cs_timer_entries
    mov es:[bx].timer_next,0
    mov es:[bx].timer_msb,0FFFFFFFFh
    mov es:[bx].timer_lsb,0FFFFFFFFh
    mov es:cs_timer_head,bx
;       
    mov cx,0FFh
    add bx,SIZE timer_struc
    mov es:cs_timer_free,bx

icTimerListCreate:
    mov ax,bx
    add ax,SIZE timer_struc
    mov es:[bx].timer_next,ax
    mov bx,ax
    loop icTimerListCreate
;       
    mov es:cs_sched_count,0
    mov es:cs_log_count,0
    mov es:cs_log_sel,0
    mov es:cs_log_entry,0
;
    mov es:cs_curr_irq_nr,0
    mov es:cs_curr_irq_count,0
    mov es:cs_curr_irq_retries,0
    mov es:cs_nested_irq_count,0    
    mov es:cs_irq_count,0
;
    call create_long_tss
    mov es:cs_long_tr,bx
    mov es:cs_tr_linear,edx
;
    mov bx,es
    GetSelectorBaseSize
    mov es:cs_linear,edx
    mov es:cs_long_ldt,0
    mov es:cs_syscall_esp,0
    mov es:cs_syscall_eip,0
    call AddDumpCore
;    
    popad
    ret
InitCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateCore
;
;       DESCRIPTION:    Create core
;
;       PARAMETERS:     EDX     Core GDT linear
;
;       RETURNS:        AX      Core #
;                       ES      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_core_name   DB 'Create Core',0

create_core    Proc far
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push edi
;   
    mov ax,flat_sel
    mov ds,ax
    mov ax,gdt_sel
    mov es,ax
;
    AllocateGdt
    mov eax,[edx+core_data_sel]
    mov es:[bx],eax    
;    
    mov eax,[edx+core_data_sel+4]
    mov es:[bx+4],eax
    mov es,bx
;
    mov cx,SIZE core_seg
    xor di,di
    xor al,al
    rep stosb
    mov es:cs_sel,es
    mov es:cs_processor,0
;
    call InitCore
    mov ax,es:cs_id     
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds      
    retf32
create_core    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetSchedulerLockCounter
;
;       DESCRIPTION:    Get state of task lock
;
;       RETURNS:        AX  Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_scheduler_lock_counter_name   DB 'Get Scheduler Lock Counter',0

get_scheduler_lock_counter   Proc far
    push fs
    mov ax,core_data_sel
    mov fs,ax
    mov ax,fs:cs_nesting
    pop fs
    retf32
get_scheduler_lock_counter    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCore
;
;           DESCRIPTION:    Get current core selector
;
;       RETURNS:    FS      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_core_name      DB 'Get Core',0

get_core   Proc far
    push ax
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:cs_sel
    pop ax    
    retf32
get_core   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetCoreNumber
;
;       DESCRIPTION:    Get core selector for specified processor #
;
;       PARAMETERS:     AX      Core #
;
;       RETURNS:        FS      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_core_num_name      DB 'Get Core Number',0

get_core_num   Proc far
    push ax
    push bx
;
    cmp ax,cs:core_count
    jae gpnFail
;
    mov bx,ax
    add bx,bx
    mov ax,cs:[bx].core_arr
    mov fs,ax
    clc
    jmp gpnDone

gpnFail:
    xor ax,ax
    mov fs,ax
    stc

gpnDone:
    pop bx
    pop ax
    retf32
get_core_num   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetThreadCore
;
;       DESCRIPTION:    Set core for a thread
;
;       PARAMETERS:     AX      Core #
;                       ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_thread_core_name      DB 'Set Thread Core',0

set_thread_core   Proc far
    push bx
;
    cmp ax,cs:core_count
    jae stcDone
;    
    mov bx,ax
    add bx,bx
    mov bx,cs:[bx].core_arr
    mov es:p_wanted_core,bx

stcDone:
    pop bx
    retf32
set_thread_core   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockListSingle
;
;           DESCRIPTION:    Lock list, single processor version
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockListSingle    Proc near
    sti
    ret
UnlockListSingle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockKernelSectionSingle
;
;           DESCRIPTION:    Lock kernel critical section, single processor version
;
;           PARAMETERS:     DS:ESI      Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockKernelSectionSingle  Proc near
    ret
LockKernelSectionSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockKernelSectionSingle
;
;           DESCRIPTION:    Unlock kernel critical section, single processor version
;
;           PARAMETERS:     DS:ESI      Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockKernelSectionSingle    Proc near
    ret
UnlockKernelSectionSingle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockUserSectionSingle
;
;           DESCRIPTION:    Lock user critical section, single processor version
;
;           PARAMETERS:     DS:EBX      Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockUserSectionSingle  Proc near
    ret
LockUserSectionSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockUserSectionSingle
;
;           DESCRIPTION:    Unlock user critical section, single processor version
;
;           PARAMETERS:     DS:EBX      Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockUserSectionSingle    Proc near
    ret
UnlockUserSectionSingle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockFutexSingle
;
;           DESCRIPTION:    Lock futex, single processor version
;
;           PARAMETERS:     DS:EBX      Futex handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockFutexSingle  Proc near
    ret
LockFutexSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockFutexSingle
;
;           DESCRIPTION:    Unlock futex, single processor version
;
;           PARAMETERS:     DS:EBX      Futex handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockFutexSingle    Proc near
    ret
UnlockFutexSingle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockBlockSingle
;
;           DESCRIPTION:    Lock block, single processor version
;
;           PARAMETERS:     DS:EBX      Block handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockBlockSingle  Proc near
    ret
LockBlockSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockBlockSingle
;
;           DESCRIPTION:    Unlock block, single processor version
;
;           PARAMETERS:     DS:EBX      Block handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockBlockSingle    Proc near
    ret
UnlockBlockSingle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockListMultiple
;
;           DESCRIPTION:    Lock list, multiple processor version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockListMultiple    Proc near
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax    

llSpinLock:    
    sti
    mov ax,ds:list_lock
    or ax,ax
    je llGet
;
    pause
    jmp llSpinLock

llGet:
    cli
    inc ax
    xchg ax,ds:list_lock
    or ax,ax
    je llDone
;
    jmp llSpinLock

llDone:
    pop ax    
    pop ds
    ret
LockListMultiple    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockListMultiple
;
;           DESCRIPTION:    Unlock list, multiple processor version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockListMultiple      Proc near
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax    
    mov ds:list_lock,0
    sti
;
    pop ax
    pop ds    
    ret
UnlockListMultiple      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockKernelSectionMultiple
;
;           DESCRIPTION:    Lock kernel critical section, multiple processor version
;
;           PARAMETERS:     DS:ESI      Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockKernelSectionMultiple  Proc near
    push ax

lksmSpinLock:    
    mov ax,ds:[esi].cs_lock
    or ax,ax
    je lksmGet
;
    pause
    jmp lksmSpinLock

lksmGet:
    inc ax
    xchg ax,ds:[esi].cs_lock
    or ax,ax
    je lksmDone
;
    jmp lksmSpinLock

lksmDone:
    pop ax    
    ret
LockKernelSectionMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockKernelSectionMultiple
;
;           DESCRIPTION:    Unlock kernel critical section, multiple processor version
;
;           PARAMETERS:     DS:ESI      Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockKernelSectionMultiple    Proc near
    mov ds:[esi].cs_lock,0
    sti
    ret
UnlockKernelSectionMultiple    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockUserSectionMultiple
;
;           DESCRIPTION:    Lock user critical section, multiple processor version
;
;           PARAMETERS:     DS:EBX      Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockUserSectionMultiple  Proc near
    push ax

lusmSpinLock:    
    mov ax,ds:[ebx].us_lock
    or ax,ax
    je lusmGet
;
    pause
    jmp lusmSpinLock

lusmGet:
    inc ax
    xchg ax,ds:[ebx].us_lock
    or ax,ax
    je lusmDone
;
    jmp lusmSpinLock

lusmDone:
    pop ax    
    ret
LockUserSectionMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockUserSectionMultiple
;
;           DESCRIPTION:    Unlock user critical section, multiple processor version
;
;           PARAMETERS:     DS:EBX      Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockUserSectionMultiple    Proc near
    mov ds:[ebx].us_lock,0
    sti
    ret
UnlockUserSectionMultiple    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockFutexMultiple
;
;           DESCRIPTION:    Lock futex, multiple processor version
;
;           PARAMETERS:     DS:EBX      Futex handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockFutexMultiple  Proc near
    push ax

lfSpinLock:    
    mov ax,ds:[ebx].fh_lock
    or ax,ax
    je lfGet
;
    pause
    jmp lfSpinLock

lfGet:
    inc ax
    xchg ax,ds:[ebx].fh_lock
    or ax,ax
    je lfDone
;
    jmp lfSpinLock

lfDone:
    pop ax    
    ret
LockFutexMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockFutexMultiple
;
;           DESCRIPTION:    Unlock futex, multiple processor version
;
;           PARAMETERS:     DS:EBX      Futex handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockFutexMultiple    Proc near
    mov ds:[ebx].fh_lock,0
    sti
    ret
UnlockFutexMultiple    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockBlockMultiple
;
;           DESCRIPTION:    Lock block, multiple processor version
;
;           PARAMETERS:     DS:EBX      Block handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockBlockMultiple  Proc near
    push ax

lbSpinLock:    
    mov ax,ds:[ebx].bh_lock
    or ax,ax
    je lbGet
;
    pause
    jmp lbSpinLock

lbGet:
    inc ax
    xchg ax,ds:[ebx].bh_lock
    or ax,ax
    je lbDone
;
    jmp lbSpinLock

lbDone:
    pop ax    
    ret
LockBlockMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockBlockMultiple
;
;           DESCRIPTION:    Unlock block, multiple processor version
;
;           PARAMETERS:     DS:EBX      Block handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockBlockMultiple    Proc near
    mov ds:[ebx].bh_lock,0
    sti
    ret
UnlockBlockMultiple    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TryLockCore
;
;           DESCRIPTION:    Try to lock
;
;       RETURNS:    CY      Owner of section
;               FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TryLockCore   Proc near
    cli
    push word ptr core_data_sel
    pop fs
    mov fs,fs:cs_sel
    lock add fs:cs_nesting,1
    ret
TryLockCore   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockCore
;
;           DESCRIPTION:    Lock
;
;       RETURNS:    CY      Owner of section
;               FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockCore      Proc near
    cli
    push word ptr core_data_sel
    pop fs
    mov fs,fs:cs_sel
    lock add fs:cs_nesting,1
    jc lcDone
;
    mov ax,fs:cs_nesting
    or ax,ax
    je lcDone
;
    CrashGate

lcDone:     
    ret
LockCore      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TryUnlockCore
;
;           DESCRIPTION:    Try to unlock
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TryUnlockCore    Proc near
    push eax
    
tucRetry:    
    cli
    lock sub fs:cs_nesting,1
    jnc tucDone
;
    test fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    jz tucTimerOk
;
    lock add fs:cs_nesting,1
    jc tucHandleTimer
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz tucHandleTimer
;    
    CrashGate

tucHandleTimer:
    sti
    pushad
    call cs:update_timer_proc
    popad
    jmp tucRetry
    
tucTimerOk:      
    mov ax,fs:cs_wakeup_count
    or ax,ax
    jnz tucSwap
;
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz tucTlbDone
;
    lock add fs:cs_nesting,1
    jc tucFlush
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz tucFlush
;    
    CrashGate    

tucFlush:
    sti
    call cs:flush_tlb_proc
    jmp tucRetry

tucTlbDone:    
    mov ax,fs:cs_curr_thread
    or ax,ax
    jz tucDone
;
    test fs:cs_flags,CS_FLAG_PREEMPT
    jz tucDone

tucSwap:
    lock add fs:cs_nesting,1
    jc tucSched
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz tucSched
;    
    CrashGate

tucSched:
    sti
    push OFFSET tucDone
    call SaveLockedThread
    jmp ContinueCurrentThread

tucDone:
    sti
    pop eax
    ret
TryUnlockCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockCore
;
;           DESCRIPTION:    Unlock
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockCore    Proc near
    push eax
    
ucRetry:    
    cli
    lock sub fs:cs_nesting,1
    jc ucNestOk
;
    mov ax,fs:cs_nesting
    cmp ax,-1
    je ucNestOk
;    
    CrashGate

ucNestOk:    
    test fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    jz ucTimerOk
;
    lock add fs:cs_nesting,1
    jc ucHandleTimer
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz ucHandleTimer
;    
    CrashGate

ucHandleTimer:
    sti
    pushad
    call cs:update_timer_proc
    popad
    jmp ucRetry
    
ucTimerOk:      
    mov ax,fs:cs_wakeup_count
    or ax,ax
    jnz ucSwap
;
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz ucTlbDone
;
    lock add fs:cs_nesting,1
    jc ucFlush
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz ucFlush
;    
    CrashGate    

ucFlush:
    sti
    call cs:flush_tlb_proc
    jmp ucRetry

ucTlbDone:    
    test fs:cs_flags,CS_FLAG_PREEMPT
    jz ucDone

ucSwap:
    lock add fs:cs_nesting,1
    jc ucSched
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz ucSched
;    
    CrashGate

ucSched:
    sti
    push OFFSET ucDone
    call SaveLockedThread
    jmp ContinueCurrentThread

ucDone:
    sti
    pop eax
    ret
UnlockCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadUnlockCore
;
;           DESCRIPTION:    Thread load unlock
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadUnlockCore    Proc near
    lock sub fs:cs_nesting,1
    jc lulcDone
;
    mov ax,fs:cs_nesting
    or ax,ax
    jne lulcCrash
;
    lock sub fs:cs_nesting,1
    jc lulcDone

lulcCrash:    
    mov ax,fs:cs_nesting
    cmp ax,-1
    je lulcDone
;    
    CrashGate

lulcDone:       
    ret
LoadUnlockCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IrqSchedule
;
;           DESCRIPTION:    IRQ scheduling
;
;           PARAMETERS:     FS  Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irq_schedule_name  DB 'IRQ Schedule',0

irq_schedule    Proc far    
    push OFFSET irqsDone
    call SaveIrqThread
    jmp ContinueCurrentThread

irqsDone:
    retf32
irq_schedule    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TryLockTask
;
;           DESCRIPTION:    Try lock task
;
;           RETURNS:        FS      Core sel
;                           NC      Not previously locked
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

try_lock_task_name  DB 'Try Lock Task',0

try_lock_task       Proc far
    push ds
    call TryLockCore
    pop ds
    retf32
try_lock_task       Endp


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
;    
    call LockCore
;       
    pop fs
    pop ds
    retf32
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
    pushf
    cli
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:cs_sel
    popf
    call UnlockCore
;
    pop ax
    pop fs
    pop ds      
    retf32
unlock_task     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           EnterLongInt
;
;   DESCRIPTION:    Enter long mode int
;
;   RETURNS:        AX      Locked core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_long_int_name  DB 'Enter Long Int',0

enter_long_int   Proc far
    mov ax,core_data_sel
    mov ds,ax
    mov ds,ds:cs_sel
    add ds:cs_nesting,1
    mov ax,ds:cs_sel
    retf32
enter_long_int  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LeaveLongInt
;
;   DESCRIPTION:    Leave long mode int
;
;   PARAMETERS:     AX      Locked core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_long_int_name  DB 'Leave Long Int',0

leave_long_int   Proc far
    mov ds,ax
    
lliRetry:
    cli
    lock sub ds:cs_nesting,1
    jnc lliDone
;
    test fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    jz lliTimerOk
;
    lock add fs:cs_nesting,1
    jc lliHandleTimer
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz lliHandleTimer
;
    CrashGate

lliHandleTimer:
    sti
    pushad
    call cs:update_timer_proc
    popad
    jmp lliRetry
    
lliTimerOk:    
    mov ax,fs:cs_wakeup_count
    or ax,ax
    jnz lliSwap
;
    mov ax,fs:cs_curr_thread
    or ax,ax
    jz lliDone
;
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz lliTlbDone
;
    lock add fs:cs_nesting,1
    jc lliFlush
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz lliFlush
;
    CrashGate

lliFlush:
    sti
    call cs:flush_tlb_proc
    jmp lliRetry

lliTlbDone:    
    test fs:cs_flags,CS_FLAG_PREEMPT
    jz lliDone

lliSwap:
    lock add fs:cs_nesting,1
    jc lliSched
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz lliSched
;
    CrashGate    

lliSched:
    sti
    push OFFSET lliDone
    call SaveLockedThread
    jmp ContinueCurrentThread

lliDone:
    retf32
leave_long_int  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushTlb386
;
;           DESCRIPTION:    Flush TLB entries, 386 processor version
;
;           PARAMETERS:     FS  Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushTlb386    Proc near
    push eax

ft386Again:
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz ft386Done
;
    mov fs:cs_tlb.pt32_used,0    
    mov eax,cr3
    mov cr3,eax
    jmp ft386Again

ft386Done:    
    pop eax
    ret
FlushTlb386    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushTlb486
;
;           DESCRIPTION:    Flush TLB entries, 486 or higher processor version
;
;           PARAMETERS:     FS  Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushTlb486    Proc near

ft486Again:
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz ft486Done
;    
    cmp eax,-1
    je ft486All
;
    push es
    pushad
;    
    mov cx,fs
    mov es,cx
    mov cx,32
    mov si,OFFSET cs_tlb.pt32_linear_arr
    mov di,OFFSET cs_work_tlb.pt32_linear_arr
    rep movs dword ptr es:[di],es:[si]
    lock xor fs:cs_tlb.pt32_used,eax
;
    mov cx,flat_sel
    mov es,cx
    mov cx,32
    mov di,OFFSET cs_work_tlb.pt32_linear_arr
    mov esi,1
    
ft486Loop:    
    test esi,eax
    jz ft486Next
;
    mov edx,fs:[di]    
    invlpg es:[edx]

ft486Next:
    add di,4
    shl esi,1
    sub cx,1
    jnz ft486Loop
;
    popad
    pop es    
    jmp ft486Again

ft486All:
    mov fs:cs_tlb.pt32_used,0
    mov eax,cr3
    mov cr3,eax
    jmp ft486Again

ft486Done:    
    ret
FlushTlb486    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoFlushTlb
;
;           DESCRIPTION:    Flush TLB callback from leave int
;
;           PARAMETERS:     FS  Core, locked
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_flush_tlb_name  DB 'Do Flush TLB', 0

do_flush_tlb  Proc far
    call cs:flush_tlb_proc
    retf32    
do_flush_tlb   ENDP
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           AddCoreTlb
;
;    DESCRIPTION:    Add core TLB
;
;    PARAMETERS:     EDX        Linear address
;                    FS         Core
;                    BX         Server sel or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCoreTlb     Proc near
    push eax
    push ecx
    push di
;
    cmp edx,system_mem_start 
    jae actTryLock
;
    or bx,bx
    jz actCheckCr3

actCheckServ:
    cmp bx,fs:cs_serv_sel
    je actTryLock
    jmp actDone

actCheckCr3:
    mov eax,cr3
    and ax,0F000h
    cmp eax,fs:cs_cr3
    jne actDone

actTryLock:
    mov eax,fs:cs_tlb.pt32_used
    or eax,fs:cs_tlb.pt32_locked
    not eax
    bsf ecx,eax
    jnz actHasEntry
;
    mov fs:cs_tlb.pt32_used,-1
    mov fs:cs_tlb.pt32_locked,0
    jmp actDone

actHasEntry:    
    cli
    lock bts fs:cs_tlb.pt32_locked,ecx
    jnc actLockOk
;
    sti
    pause
    jmp actTryLock

actLockOk:
    mov di,cx
    shl di,2
    mov fs:[di].cs_tlb.pt32_linear_arr,edx
;
    lock bts fs:cs_tlb.pt32_used,ecx
    jnc actUnlock
;
    lock btr fs:cs_tlb.pt32_locked,ecx
    sti
    pause
    jmp actTryLock

actUnlock:
    lock btr fs:cs_tlb.pt32_locked,ecx
    sti

actDone:    
    pop di
    pop ecx
    pop eax
    ret
AddCoreTlb     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushTLB
;
;           DESCRIPTION:    Flush TLB entries
;
;           PARAMETERS:     CX    Number of entries
;                           EDX   Linear base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_tlb_name DB 'Flush Tlb', 0

flush_tlb Proc far
    push fs
    pushad
;
    xor bx,bx
;
    or cx,cx
    jz nfDone    
;
    cmp edx,system_mem_start
    jae ftlbLoop
;
    cmp edx,serv_linear
    jb ftlbLoop
;
    push es
    GetThread
    mov es,ax
    mov bx,es:p_serv_sel
    pop es

ftlbLoop:
    push cx
    push edx
;    
    mov cx,cs:core_count
    or cx,cx
    jz ateDone
;
    mov si,OFFSET core_arr

ateLoop:
    mov fs,cs:[si]
    test fs:cs_flags,CS_FLAG_ACTIVE
    jz ateNext
;    
    call AddCoreTlb

ateNext:
    add si,2
    sub cx,1
    jnz ateLoop    

ateDone:
    pop edx
    pop cx
;
    add edx,1000h
    sub cx,1
    jnz ftlbLoop    
;
    mov cx,cs:core_count
    or cx,cx
    jz nfDone
;
    call TryLockCore
    sti
    mov dx,fs
    mov si,OFFSET core_arr

nfLoop:
    mov bx,cs:[si]
    cmp dx,bx
    je nfNext
;    
    mov fs,bx
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz nfNext
;
    test fs:cs_flags,CS_FLAG_ACTIVE
    jz nfNext
;    
    mov al,81h
    SendLockedInt

nfNext:
    add si,2
    sub cx,1
    jnz nfLoop    
;
    mov fs,dx
    call TryUnlockCore 

nfDone:
    popad    
    pop fs
    retf32
flush_tlb Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateOwnTimer
;
;           DESCRIPTION:    Update timers without preempt
;
;           PARAMETERS:     FS  locked core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateOwnTimer    Proc near
    push ds
;    
    mov ax,SEG data
    mov ds,ax
    lock and fs:cs_flags,NOT CS_FLAG_TIMER_EXPIRED

uotCheck:   
    GetSystemTime
    call LockTimerGlobal
    add eax,cs:update_tics
    adc edx,0
    mov bx,ds:timer_head
    sub eax,ds:[bx].timer_lsb
    sbb edx,ds:[bx].timer_msb
    jc uotReload
;
    call LocalRemoveTimerGlobal    
    jmp uotCheck

uotReload: 
    neg eax
    ReloadSysTimer
    jnc uotDone
;
    call UnlockTimerGlobal
    jmp uotCheck

uotDone:
    call UnlockTimerGlobal    
;
    pop ds   
    ret
UpdateOwnTimer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateCombinedTimer
;
;           DESCRIPTION:    Update combined timer
;
;           PARAMETERS:     FS  locked core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCombinedTimer    Proc near
    push ds
;    
    mov ax,SEG data
    mov ds,ax
    lock and fs:cs_flags,NOT CS_FLAG_TIMER_EXPIRED

uctLoop:
    GetSystemTime
    call LockTimerCore
    add eax,cs:update_tics
    adc edx,0
    mov bx,fs:cs_timer_head
    mov ecx,fs:cs_preempt_msb
    cmp ecx,fs:[bx].timer_msb
    jc uctPreempt
    jnz uctTimer
;       
    mov ecx,fs:cs_preempt_lsb
    cmp ecx,fs:[bx].timer_lsb
    jc uctPreempt

uctTimer:
    sub eax,fs:[bx].timer_lsb
    sbb edx,fs:[bx].timer_msb
    jc uctReload
;       
    call LocalRemoveTimerCore
    jmp uctLoop

uctPreempt:
    sub eax,fs:cs_preempt_lsb
    sbb edx,fs:cs_preempt_msb
    jc uctReload
;
    call UnlockTimerCore
    lock or fs:cs_flags,CS_FLAG_PREEMPT
;
    GetSystemTime
    add eax,1193
    adc edx,0
    mov fs:cs_preempt_lsb,eax
    mov fs:cs_preempt_msb,edx
    jmp uctLoop

uctReload:
    neg eax
    ReloadSysPreemptTimer
    call UnlockTimerCore
;
    pop ds   
    ret
UpdateCombinedTimer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UseCombinedTimer
;
;           DESCRIPTION:    Use combined timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

use_own_preempt_timer_name   DB 'Use Own Preempt Timer', 0

use_own_preempt_timer    Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:patch_sel
    mov ds:update_timer_proc,OFFSET UpdateOwnTimer
;
    pop ax
    pop ds
    retf32
use_own_preempt_timer      Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TimerExpired
;
;           DESCRIPTION:    Timer expired notification from normal IRQ
;
;           PARAMETERS:     FS          Locked core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timer_expired_name   DB 'Timer Expired', 0

timer_expired    Proc far
    call cs:update_timer_proc
    retf32
timer_expired    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PreemptExpired
;
;           DESCRIPTION:    Preemption expired notification
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

preempt_expired_name   DB 'Preempt Expired', 0

preempt_expired    Proc far
    call TryLockCore
    sti
    lock or fs:cs_flags,CS_FLAG_PREEMPT
    call TryUnlockCore
    retf32
preempt_expired    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           START_TIMER
;
;           DESCRIPTION:    Start a timer, global version
;
;           PARAMETERS:     EDX:EAX         Timeout time
;                           ES:EDI          Callback
;                           BX              Owner (selector ID)
;                           ECX             ID passed to callback
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_global_timer_name DB 'Start Timer',0

start_global_timer     PROC far
    push ds
    push fs
    push bx
    push si
;
    mov si,SEG data
    mov ds,si    
;    
    call LockTimerGlobal
;    
    mov si,ds:timer_free
    mov ds:[si].timer_owner,bx
    mov bx,ds:[si].timer_next
    mov ds:timer_free,bx
    mov ds:[si].timer_lsb,eax
    mov ds:[si].timer_msb,edx
    mov ds:[si].timer_id,ecx
    mov ds:[si].timer_offset,edi
    mov ds:[si].timer_sel,es
    mov bx,OFFSET timer_head
    push si

    mov si,bx
    mov bx,ds:[bx].timer_next
    cmp edx,ds:[bx].timer_msb
    jc start_global_insert_first
    jnz start_global_try_next
    cmp eax,ds:[bx].timer_lsb
    jnc start_global_try_next

start_global_insert_first:
    pop ds:[si].timer_next
    mov si,ds:[si].timer_next
    mov ds:[si].timer_next,bx
;
    call TryLockCore
    call UnlockTimerGlobal    
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    call TryUnlockCore
    jmp start_global_done
    
start_global_try_next:
    mov si,bx
    mov bx,ds:[bx].timer_next
    cmp edx,ds:[bx].timer_msb
    jc start_global_insert
    jnz start_global_try_next
    cmp eax,ds:[bx].timer_lsb
    jnc start_global_try_next

start_global_insert:
    pop ds:[si].timer_next
    mov si,ds:[si].timer_next
    mov ds:[si].timer_next,bx
    call UnlockTimerGlobal

start_global_done:
    pop si
    pop bx
    pop fs
    pop ds
    retf32
start_global_timer     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           STOP_TIMER
;
;           DESCRIPTION:    Stop timer, global version
;
;           PARAMETERS:         BX              Owner
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_global_timer_name DB 'Stop Timer',0

stop_global_timer      PROC far
    push ds
    push ax
    push bx
    push cx
    push si
;    
    mov ax,SEG data
    mov ds,ax
;    
    call LockTimerGlobal
;
    mov cx,bx
    mov bx,OFFSET timer_head

timer_global_stop_next:
    mov si,bx
    mov bx,ds:[bx].timer_next
    or bx,bx
    je timer_global_stop_done

    cmp cx,ds:[bx].timer_owner
    jne timer_global_stop_next

timer_global_stop_this:
    mov ax,ds:[bx].timer_next
    mov ds:[si].timer_next,ax
    mov ax,ds:timer_free
    mov ds:[bx].timer_next,ax
    mov ds:timer_free,bx

timer_global_stop_done:
    call UnlockTimerGlobal
;
    pop si
    pop cx
    pop bx
    pop ax
    pop ds
    retf32
stop_global_timer      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           START_TIMER
;
;           DESCRIPTION:    Start a timer, per core version
;
;           PARAMETERS:     EDX:EAX         Timeout time
;                           ES:EDI          Callback
;                           BX              Owner (selector ID)
;                           ECX             ID passed to callback
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_core_timer_name DB 'Start Timer',0

start_core_timer     PROC far
    push ds
    push es
    push fs
    pushad
;
    call TryLockCore
    sti
    call LockTimerCore
;    
    mov si,fs:cs_timer_free
    mov fs:[si].timer_owner,bx
    mov bx,fs:[si].timer_next
    mov fs:cs_timer_free,bx
    mov fs:[si].timer_lsb,eax
    mov fs:[si].timer_msb,edx
    mov fs:[si].timer_id,ecx
    mov fs:[si].timer_offset,edi
    mov fs:[si].timer_sel,es
    mov bx,OFFSET cs_timer_head
    push si

start_core_try_next:
    mov si,bx
    mov bx,fs:[bx].timer_next
    cmp edx,fs:[bx].timer_msb
    jc start_core_insert
    
    jnz start_core_try_next

    cmp eax,fs:[bx].timer_lsb
    jnc start_core_try_next

start_core_insert:
    pop fs:[si].timer_next
    mov si,fs:[si].timer_next
    mov fs:[si].timer_next,bx
;    
    call UnlockTimerCore
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    call TryUnlockCore
;
    popad
    pop fs
    pop es
    pop ds
    retf32
start_core_timer     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           STOP_TIMER
;
;           DESCRIPTION:    Stop timer, per core version
;
;           PARAMETERS:         BX              Owner
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_core_timer_name DB 'Stop Timer',0

stop_core_timer      PROC far
    push fs
    push ax
    push bx
    push cx
    push si
;    
    mov cx,cs:core_count
    mov si,OFFSET core_arr

stop_core_loop:
    push bx
    push cx
    push si
; 
    mov fs,cs:[si]   
    call LockTimerCore
;
    mov cx,bx
    mov bx,OFFSET cs_timer_head

core_timer_stop_next:
    mov si,bx
    mov bx,fs:[bx].timer_next
    or bx,bx
    je core_timer_stop_done
    cmp cx,fs:[bx].timer_owner
    jne core_timer_stop_next

core_timer_stop_this:
    mov ax,fs:[bx].timer_next
    mov fs:[si].timer_next,ax
    mov ax,fs:cs_timer_free
    mov fs:[bx].timer_next,ax
    mov fs:cs_timer_free,bx

core_timer_stop_done:
    call UnlockTimerCore
;
    pop si
    pop cx
    pop bx
    add si,2
    loop stop_core_loop    
;
    pop si
    pop cx
    pop bx
    pop ax
    pop fs    
    retf32
stop_core_timer      ENDP

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
    
init_first_thread:
    mov eax,cr0
    or eax,10008h
    mov cr0,eax    
    StartSyscall
;    
    mov ax,es
    mov ds,ax
    mov ax,ds:p_ss
    mov ds:p_kernel_ss,ax
    mov eax,dword ptr ds:p_rsp
    mov ds:p_kernel_esp,eax
;    
    call LockCore
    sti
    mov di,es:p_prio
    mov fs:cs_prio_act,di
    call InsertCoreBlock
;
    mov bx,core_data_sel
    mov fs,bx
    mov fs,fs:cs_sel
;
    mov ax,start_preempt_timer_nr
    IsValidOsGate
    jc preempt_timer_combined
;
    StartSysTimer
    mov bx,SEG data
    mov ds,bx
    mov ds,ds:patch_sel
    mov ds:update_tics,eax
    xor ax,ax
    mov ds,ax
;
    StartPreemptTimer
    mov bx,SEG data
    mov ds,bx
    mov ds,ds:patch_sel
    mov ds:preempt_reload_proc,OFFSET PreemptReload
;
    mov bx,SEG data
    mov ds,bx
    GetSystemTime
    mov ds:sys_lsb_tics_base,eax
    mov ds:sys_msb_tics_base,edx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_global_timer
    mov edi,OFFSET start_global_timer_name
    xor cl,cl
    mov ax,start_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_global_timer
    mov edi,OFFSET stop_global_timer_name
    xor cl,cl
    mov ax,stop_timer_nr
    RegisterOsGate
    jmp LoadThread
        
preempt_timer_combined:        
    StartSysPreemptTimer
    mov bx,SEG data
    mov ds,bx
    mov ds,ds:patch_sel
    mov ds:update_tics,eax
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_core_timer
    mov edi,OFFSET start_core_timer_name
    xor cl,cl
    mov ax,start_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_core_timer
    mov edi,OFFSET stop_core_timer_name
    xor cl,cl
    mov ax,stop_timer_nr
    RegisterOsGate
    jmp LoadThread

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

wake_new    PROC near
    pushf
    mov dx,es
    push OFFSET wake_new_done
    call SaveCurrentThread
;
    mov es,dx
    call InsertLockedWakeup
    jmp ContinueCurrentThread

wake_new_other_core:
    CrashGate

wake_new_done:
    popf
    ret
wake_new    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CleanupThread
;
;           DESCRIPTION:    Free resources for current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
cleanup_thread:
    call SkipCurrentThread
    mov ax,fs:cs_curr_thread
    cmp ax,fs:cs_math_thread
    jne cleanup_thread_math_ok
;    
    lock and fs:cs_flags,NOT CS_FLAG_FPU
    mov fs:cs_math_thread,0

cleanup_thread_math_ok:
    mov bx,cs:system_thread
    Signal    
;
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;    
    mov ax,SEG data
    mov ds,ax    
    mov edi,OFFSET term_thread_list
;
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
;
    xor ax,ax
    mov es,ax
    jmp LoadThread        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CleanupProcess
;
;           DESCRIPTION:    Free resources for current process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
cleanup_process:
    call SkipCurrentThread
    mov ax,fs:cs_curr_thread
    cmp ax,fs:cs_math_thread
    jne cleanup_process_math_ok
;    
    lock and fs:cs_flags,NOT CS_FLAG_FPU
    mov fs:cs_math_thread,0

cleanup_process_math_ok:    
    mov bx,cs:system_thread
    Signal    
;
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0    
;
    mov ax,SEG data
    mov ds,ax
    mov edi,OFFSET term_proc_list
;
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
;
    xor ax,ax
    mov es,ax        
    jmp LoadThread

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
    retf32
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
    mov ds,ax
    movzx edi,di    
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
;        
    mov es:p_sleep_type,SLEEP_TYPE_SUSPEND
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi
    jmp LoadThread

sleep_thread_done:
    GetThread
    mov ds,ax
    mov eax,ds:p_data
    popf
    pop ds
    retf32
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
    mov ax,core_data_sel
    mov ds,ax
    mov ds,ds:cs_curr_thread
    mov ds:p_signal,0
;
    pop ax
    pop ds
    retf32
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
    push si
    push es
    push fs
;
    or bx,bx
    jz signal_done
;
    cli
    mov es,bx
    call TryLockCore
;
    mov bx,es
    or bx,bx
    jz signal_unlock_core
;
    test es:p_flags,THREAD_FLAG_TERMINATED
    jnz signal_unlock_core    
;
    mov si,fs:cs_irq_count
    or si,si
    jz signal_other_thread
;
    dec si
    mov al,fs:[si].cs_irq_stack
    cmp al,-1
    je signal_do_lock
;
    movzx ax,al
    bts word ptr es:p_irq_bitmap,ax
    jmp signal_do_lock

signal_other_thread:

signal_do_lock:
    call cs:lock_signal_proc
    mov es:p_signal,1
;    
    mov ax,es:p_sleep_type
    cmp ax,SLEEP_TYPE_SIGNAL
    jne signal_unlock_signal
;    
    mov es:p_sleep_type,0
    mov es:p_signal,0
    call cs:unlock_signal_proc
    call InsertLockedWakeup    
    jmp signal_unlock_core

signal_unlock_signal:
    call cs:unlock_signal_proc

signal_unlock_core:
    call TryUnlockCore

signal_done:       
    pop fs
    pop es
    pop si
    pop ax
    retf32
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
    push es
    push fs
    push ax
;
    cli
    call LockCore
    mov es,fs:cs_curr_thread
    call cs:lock_signal_proc
;    
    xor al,al
    xchg al,es:p_signal
    or al,al
    jnz wait_for_signal_unlock
;
    mov es:p_sleep_type,SLEEP_TYPE_SIGNAL
    call cs:unlock_signal_proc
;
    push OFFSET wait_for_signal_done
    call SaveLockedThread
    xor ax,ax
    mov es,ax
    mov fs:cs_curr_thread,ax
    jmp LoadThread

wait_for_signal_unlock:
    call cs:unlock_signal_proc
    call UnlockCore

wait_for_signal_done:       
    pop ax
    pop fs
    pop es
    retf32
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
    retf32
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
    push es
    push fs
    push ax
    push bx
    push cx
    push edi
;
    cli
    call LockCore
    mov es,fs:cs_curr_thread
    call cs:lock_signal_proc
;    
    xor al,al
    xchg al,es:p_signal
    or al,al
    jnz wait_for_signal_timeout_unlock
;
    mov es:p_sleep_type,SLEEP_TYPE_SIGNAL
    call cs:unlock_signal_proc
;
    mov bx,es
    mov cx,cs
    mov es,cx
    mov edi,OFFSET signal_timeout    
    mov cx,bx
    StartTimer
;
    push OFFSET wait_for_signal_timeout_clear
    call SaveLockedThread
    xor ax,ax
    mov es,ax 
    mov fs:cs_curr_thread,ax
    jmp LoadThread

wait_for_signal_timeout_unlock:
    call cs:unlock_signal_proc
    call UnlockCore
    jmp wait_for_signal_timeout_done

wait_for_signal_timeout_clear:
    GetThread
    mov bx,ax
    StopTimer
    
wait_for_signal_timeout_done:
    pop edi
    pop cx
    pop bx
    pop ax
    pop fs
    pop es
    retf32
wait_for_signal_timeout ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateWaitDev
;
;           DESCRIPTION:    Create wait device
;
;           RETURNS:        BX          Wait dev handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_wait_dev_name    DB 'Create Wait Device',0

create_wait_dev   Proc far
    push ds
    push ax
    push cx
    push si
;
    mov ax,SEG data
    mov ds,ax
;
    mov bx,ds:wait_dev_pos
    mov si,bx
    shl si,2
    mov cx,WAIT_DEV_COUNT

crwdLoop:
    cmp bx,WAIT_DEV_COUNT
    jne crwdCheck
;
    xor bx,bx
    xor si,si

crwdCheck:
    mov ax,ds:[si].wd_thread
    cmp ax,-1
    jne crwdNext
;
    xor ax,ax
    xchg ax,ds:[si].wd_thread
    cmp ax,-1
    je crwdOK

crwdNext:
    add si,4
    inc bx
    loop crwdLoop
;
    int 3
    stc
    jmp crwdDone

crwdOk:
    mov ds:[si].wd_flags,0
    mov ds:[si].wd_lock,0
    inc bx
    mov ds:wait_dev_pos,bx
    clc

crwdDone:
    pop si
    pop cx
    pop ax
    pop ds
    retf32
create_wait_dev   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseWaitDev
;
;           DESCRIPTION:    Close wait device
;
;           PARAMETERS:     BX          Wait dev handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_wait_dev_name    DB 'Close Wait Device',0

close_wait_dev PROC far
    push ds
    push si
;
    or bx,bx
    jz clwdDone
;
    cmp bx,WAIT_DEV_COUNT
    ja clwdDone
;
    mov si,SEG data
    mov ds,si
    mov si,bx
    dec si
    shl si,2
    mov ds:[si].wd_thread,-1

clwdDone:
    pop si
    pop ds
    retf32
close_wait_dev  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PrepareWaitDev
;
;           DESCRIPTION:    Prepare wait for device
;
;           PARAMS:         BX          Wait dev handle
;                           ES:EDI      Name of dev
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

prepare_wait_dev_name    DB 'Prepare Wait Device',0

prepare_wait_dev   Proc far
    push ds
    push eax
    push ecx
    push esi
    push edi
;
    or bx,bx
    jz pwdDone
;
    cmp bx,WAIT_DEV_COUNT
    ja pwdDone
;
    GetThread
    mov ds,ax
    mov esi,OFFSET p_list_name
    mov ecx,31

pwdCopy:    
    mov al,es:[edi]
    mov ds:[esi],al
    inc esi
    inc edi
    or al,al
    jz pwdCopied
;
    loop pwdCopy

pwdCopied:
    xor al,al
    mov ds:[esi],al
;
    mov cx,ds
    mov ax,SEG data
    mov ds,ax
    mov si,bx
    dec si
    shl si,2
    mov ax,ds:[si].wd_thread
    cmp ax,-1
    je pwdDone
;
    mov ds:[si].wd_thread,0
    mov ds:[si].wd_flags,WAIT_DEV_ACTIVE
   
pwdDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    pop ds
    retf32
prepare_wait_dev  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           wait_dev_timeout
;
;       DESCRIPTION:    Wait dev timeout handler
;
;       PARAMETERS:     CX      Wait dev handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_dev_timeout  PROC far
    mov bx,cx
    SignalWaitDev
    retf32
wait_dev_timeout  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForDevice
;
;           DESCRIPTION:    Wait for a device
;
;           PARAMETERS:     BX          Wait dev handle
;                           EDX:EAX     Timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_dev_name    DB 'Wait For Device',0

wait_for_dev PROC far
    push ds
    push es
    push fs
    push ax
    push bx
    push cx
    push si
    push edi
;
    or bx,bx
    jz wfdDone
;
    cmp bx,WAIT_DEV_COUNT
    ja wfdDone
;
    mov cx,SEG data
    mov ds,cx
    mov si,bx
    dec si
    shl si,2
    mov cx,ds:[si].wd_thread
    cmp cx,-1
    je wfdDone
;
    cli
    call LockCore
    mov es,fs:cs_curr_thread
    call cs:lock_wait_dev_proc
;    
    test ds:[si].wd_flags,WAIT_DEV_SIGNAL
    jnz wfdUnlock
;
    mov ds:[si].wd_thread,es
    lock or ds:[si].wd_flags,WAIT_DEV_ACTIVE
;
    mov es:p_sleep_type,SLEEP_TYPE_WAIT_DEV
    mov es:p_sleep_sel,ds
    mov word ptr es:p_sleep_offset,si
    mov word ptr es:p_sleep_offset+2,0
    call cs:unlock_wait_dev_proc
;
    push es
    mov cx,cs
    mov es,cx
    mov cx,bx
    pop bx
    mov edi,OFFSET wait_dev_timeout    
    StartTimer
;
    push OFFSET wfdClear
    call SaveLockedThread
    xor ax,ax
    mov es,ax 
    mov fs:cs_curr_thread,ax
    jmp LoadThread

wfdUnlock:
    mov ds:[si].wd_flags,0
    mov ds:[si].wd_thread,0
;
    call cs:unlock_wait_dev_proc
    call UnlockCore
    jmp wfdDone

wfdClear:
    mov ds:[si].wd_flags,0
    mov ds:[si].wd_thread,0
;
    GetThread
    mov bx,ax
    StopTimer
    
wfdDone:
    pop edi
    pop si
    pop cx
    pop bx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
wait_for_dev ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SignalWaitDev
;
;           DESCRIPTION:    Signal wait dev
;
;           PARAMETERS:     BX        Wait dev handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_wait_dev_name      DB 'Signal Wait Device',0

signal_wait_dev   PROC far
    push ds
    push es
    push fs
    push ax
    push si
;
    or bx,bx
    jz swdDone
;
    cmp bx,WAIT_DEV_COUNT
    ja swdDone
;
    mov ax,SEG data
    mov ds,ax
;
    mov si,bx
    dec si
    shl si,2
    mov ax,ds:[si].wd_thread
    cmp ax,-1
    je swdDone
;
    cli
    call TryLockCore
;
    call cs:lock_wait_dev_proc
    test ds:[si].wd_flags,WAIT_DEV_ACTIVE
    jz swdUnlock
;
    lock or ds:[si].wd_flags,WAIT_DEV_SIGNAL
    xor ax,ax
    xchg ax,ds:[si].wd_thread
    or ax,ax
    jz swdUnlock
;    
    mov es,ax
    mov es:p_sleep_type,0
    call cs:unlock_wait_dev_proc
    call InsertLockedWakeup    
    jmp swdCore

swdUnlock:
    call cs:unlock_wait_dev_proc

swdCore:
    call TryUnlockCore

swdDone:       
    pop si
    pop ax
    pop fs
    pop es
    pop ds
    retf32
signal_wait_dev   ENDP
    
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
    push fs
;    
    call LockCore
    sti
    call cs:lock_kernel_section_proc
    mov dx,ds:[esi].cs_list
    cmp dx,-1
    jne ecsBlock
;
    mov ds:[esi].cs_list,0
    jmp ecsUnlock

ecsBlock:
    mov ax,ds
    push OFFSET ecsDone
    call SaveLockedThread
;
    mov ds,ax
    lea edi,[esi].cs_list   
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_kernel_section_proc
;    
    mov es:p_sleep_type,SLEEP_TYPE_SECTION
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,esi
    jmp LoadThread

ecsUnlock:
    call cs:unlock_kernel_section_proc
    call UnlockCore
    
ecsDone:
    pop fs
    pop dx
    pop ax
    retf32
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
    push fs
;
    call LockCore
    sti
    call cs:lock_kernel_section_proc
    mov ax,ds:[esi].cs_list
    cmp ax,-1
    je lcsUnlockList
;
    or ax,ax
    jnz lcsUnblock
;
    mov ds:[esi].cs_list,-1
    jmp lcsUnlockList

lcsUnblock:
    push es    
    push esi
    push di
;       
    add esi,OFFSET cs_list
    call RemoveBlock32
    mov es:p_data,0
    sub esi,OFFSET cs_list
    call cs:unlock_kernel_section_proc        
    call InsertLockedWakeup

lcsUnblocked:
    pop di
    pop esi
    pop es
    jmp lcsUnlock

lcsUnlockList:
    call cs:unlock_kernel_section_proc

lcsUnlock:
    call UnlockCore

lcsDone:
    pop fs
    pop dx
    pop ax
    retf32
leave_section   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           cond_section_timeout
;
;           DESCRIPTION:    Timeout on enter section
;
;       PARAMETERS:         CX       thread to remove from list
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cond_section_timeout Proc far
    push ds
    push es
    push fs
    push esi
;    
    mov es,cx
    call TryLockCore
    sti
;    
    mov eax,es:p_data
    cmp eax,-1
    jne cstDone
;    
    mov ds,es:p_sleep_sel
    mov esi,es:p_sleep_offset
;    
    sub esi,OFFSET cs_list
    call cs:lock_kernel_section_proc
;    
    add esi,OFFSET cs_list
    mov ax,[esi]
    or ax,ax
    jz cstUnlock
;    
    cmp ax,-1
    je cstUnlock
;
    call RemoveBlock32

cstUnlock:
    sub esi,OFFSET cs_list
    call cs:unlock_kernel_section_proc

cstDone:
    call TryUnlockCore
;
    pop esi
    pop fs
    pop es
    pop ds    
    retf32
cond_section_timeout  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           cond_enter_section
;
;           DESCRIPTION:    Conditional enter section
;
;           PARAMETERS:     DS:ESI      ADDRESS OF SECTION
;                           EAX         Timeout in milliseconds
;
;           RETURNS:        CY          Entered ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cond_enter_section_name      DB 'Conditional Enter Critical Section',0

cond_enter_section   PROC far
    push eax
    push edx
    push fs
;    
    call LockCore
    sti
    call cs:lock_kernel_section_proc
    push ds
    mov ds,fs:cs_curr_thread
    mov ds:p_data,-1
    pop ds
;
    mov dx,ds:[esi].cs_list
    cmp dx,-1
    jne cecsBlock
;
    mov ds:[esi].cs_list,0
    jmp cecsUnlockOk

cecsBlock:
    or eax,eax
    jz cecsUnlockFail
;
    push es
    push bx
    push ecx
    push edi
;    
    mov eax,1193
    mul ecx
    push edx
    push eax
    GetSystemTime
    pop ecx
    add eax,ecx
    pop ecx
    adc edx,ecx
;
    push ds
    mov cx,SEG data
    mov ds,cx
    mov cx,cs
    mov es,cx
    mov edi,OFFSET cond_section_timeout
    mov bx,fs:cs_curr_thread
    mov cx,bx
    StartTimer
    pop ds
;
    pop edi
    pop ecx
    pop bx
    pop es
;        
    mov ax,ds
    push OFFSET cecsDone
    call SaveLockedThread
;
    mov ds,ax
    lea edi,[esi].cs_list   
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_kernel_section_proc
;
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi    
    jmp LoadThread

cecsUnlockOk:
    call cs:unlock_kernel_section_proc
    call UnlockCore
    stc
    jmp cecsLeave

cecsUnlockFail:
    call cs:unlock_kernel_section_proc
    call UnlockCore
    clc
    jmp cecsLeave
    
cecsDone:
    call LockCore
    sti
    push ds
    push bx
;    
    mov bx,fs:cs_curr_thread
    StopTimer
;    
    mov ds,bx
    mov eax,ds:p_data
    call UnlockCore
;
    pop bx
    pop ds
    or eax,eax
    stc
    jz cecsLeave
;    
    clc

cecsLeave:
    pop fs
    pop edx
    pop eax
    retf32
cond_enter_section   ENDP
    
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
    mov ds:[ebx].us_value,0
    mov ds:[ebx].us_list,0
    mov ds:[ebx].us_owner,0
    mov ds:[ebx].us_count,0
    mov ds:[ebx].us_lock,0
    mov [ebx].hh_sign,SECTION_HANDLE
    mov bx,[ebx].hh_handle
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
;           NAME:           create_named_user_section
;
;           DESCRIPTION:    Create named user section
;
;           PARAMETERS:     ES:(E)DI    Section name
;
;           RETURNS:        BX          Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_named_user_section_name    DB 'Create Named User Section',0

create_named_user_section     PROC near
    push ds
    push eax
    push cx
;
    mov cx,SIZE section_handle_seg
    AllocateHandle
    mov ds:[ebx].us_value,0
    mov ds:[ebx].us_list,0
    mov ds:[ebx].us_owner,0
    mov ds:[ebx].us_count,0
    mov ds:[ebx].us_lock,0
    mov [ebx].hh_sign,SECTION_HANDLE
    mov bx,[ebx].hh_handle
    clc
;
    pop cx
    pop eax
    pop ds
    ret
create_named_user_section     ENDP

create_named_user_section16 Proc far
    push edi
;
    movzx edi,di
    call create_named_user_section
;
    pop edi
    retf32
create_named_user_section16 Endp

create_named_user_section32 Proc far
    call create_named_user_section
    retf32
create_named_user_section32 Endp
    
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
    mov ds:[ebx].us_value,-1
    mov ds:[ebx].us_list,0
    mov ds:[ebx].us_owner,-1
    mov ds:[ebx].us_count,1
    mov [ebx].hh_sign,SECTION_HANDLE
    mov bx,[ebx].hh_handle
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
    push ebx
;
    mov ax,SECTION_HANDLE
    DerefHandle
    jc free_section_done
;
    FreeHandle
    clc

free_section_done:
    pop ebx
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
    push ebx
    push dx
    push ds
    push fs
;
    mov ax,SECTION_HANDLE
    DerefHandle
    jc eusEnd
;
    lock sub ds:[ebx].us_value,1
    jc eusDone
;
    mov ax,core_data_sel
    mov fs,ax
    mov ax,fs:cs_curr_thread
    cmp ax,ds:[ebx].us_owner
    je eusDone
;
    call LockCore
    sti
    call cs:lock_user_section_proc
    mov ax,ds:[ebx].us_list
    cmp ax,-1
    jne eusBlock
;
    mov ds:[ebx].us_list,0
    jmp eusUnlock

eusBlock:
    mov ax,ds
    push OFFSET eusDone
    call SaveLockedThread
;
    mov ds,ax
    lea edi,[ebx].us_list     
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_user_section_proc
;
    mov es:p_sleep_type,SLEEP_TYPE_SECTION
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi    
    jmp LoadThread

eusUnlock:
    call cs:unlock_user_section_proc
    call UnlockCore
    
eusDone:
    mov ax,core_data_sel
    mov fs,ax
    mov ax,fs:cs_curr_thread
    mov ds:[ebx].us_owner,ax
    inc ds:[ebx].us_count

eusEnd:
    pop fs
    pop ds
    pop dx
    pop ebx
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
    push ebx
    push dx
    push ds
    push fs
;
    mov ax,SECTION_HANDLE
    DerefHandle
    jc lusDone
;
    mov ax,core_data_sel
    mov fs,ax
    mov ax,fs:cs_curr_thread
    cmp ax,ds:[ebx].us_owner
    jne lusDone
;
    sub ds:[ebx].us_count,1
    jz lusFreeOwner
;       
    lock add ds:[ebx].us_value,1
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
    mov ds:[ebx].us_owner,0
    lock add ds:[ebx].us_value,1
    jc lusDone
;    
    call LockCore
    sti
    call cs:lock_user_section_proc
    mov ax,ds:[ebx].us_list
    or ax,ax
    jnz lusUnblock
;
    mov ds:[ebx].us_list,-1
    jmp lusUnlockList

lusUnblock:
    push es
    push esi
    push di
;    
    lea esi,ds:[ebx].us_list
    call RemoveBlock32
    mov es:p_data,0
    call cs:unlock_user_section_proc
    call InsertLockedWakeup

lusUnblocked:
    pop di
    pop esi
    pop es
    jmp lusUnlock

lusUnlockList:
    call cs:unlock_user_section_proc

lusUnlock:
    call UnlockCore

lusDone:
    pop fs
    pop ds
    pop dx
    pop ebx
    pop ax
    retf32
leave_user_section      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetFutexId
;
;           DESCRIPTION:    Set futex ID
;
;           PARAMS:         AX      Futex ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_futex_id_name    DB 'Set Futex ID',0

set_futex_id    Proc far
    push es
    push bx
;    
    push ax
    GetThread
    mov es,ax
    pop ax
    mov es:p_futex_id,ax
;
    pop bx
    pop es    
    retf32
set_futex_id Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           acquire_futex
;
;           DESCRIPTION:    Acquire futex
;
;           PARAMS:         ES:(E)BX    address to futex struct
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

acquire_futex_name    DB 'Acquire Futex',0

acquire_futex   Proc near
    push ds
    push fs
    push eax
    push ebx
    push cx
    push esi
;    
    mov esi,ebx
    mov ebx,es:[esi].fs_handle
    mov ax,FUTEX_HANDLE
    DerefHandle
    jnc acquire_no_sect
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:futex_section
;
    mov ebx,es:[esi].fs_handle
    mov ax,FUTEX_HANDLE
    DerefHandle
    jnc acquire_handle_ok
;
    mov cx,SIZE futex_handle_seg
    AllocateHandle
    mov ds:[ebx].fh_list,0
    mov ds:[ebx].fh_lock,0
    mov [ebx].hh_sign,FUTEX_HANDLE
;
    movzx eax,[ebx].hh_handle
    mov es:[esi].fs_handle,eax

acquire_handle_ok:
    push ds
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:futex_section
    pop ds

acquire_no_sect:
    call LockCore
    sti
    call cs:lock_futex_proc    
    mov ax,1
    xchg ax,es:[esi].fs_val
    cmp ax,-1
    je acquire_take
;
    mov ax,ds
    push OFFSET acquire_done
    call SaveLockedThread
    mov ds,ax
;
    lea edi,[ebx].fh_list     
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_futex_proc
;
    mov es:p_sleep_type,SLEEP_TYPE_FUTEX
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,esi
    jmp LoadThread

acquire_take:
    push es
    mov es,fs:cs_curr_thread
    mov ax,es:p_futex_id
    pop es
    mov es:[esi].fs_owner,ax
    mov es:[esi].fs_counter,1
;    
    call cs:unlock_futex_proc
    call UnlockCore
    
acquire_done:
    pop esi
    pop cx
    pop ebx
    pop eax
    pop fs
    pop ds    
    ret
acquire_futex   Endp

acquire_futex16 Proc far
    push ebx
    movzx ebx,bx
    call acquire_futex
    pop ebx
    retf32
acquire_futex16 Endp

acquire_futex32 Proc far
    call acquire_futex
    retf32
acquire_futex32 Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           acquire_named_futex
;
;           DESCRIPTION:    Acquire named futex
;
;           PARAMS:         ES:(E)BX    address to futex struct
;                           ES:(E)DI    name of section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

acquire_named_futex_name    DB 'Acquire Named Futex',0

acquire_named_futex   Proc near
    push ds
    push fs
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    GetThread
    mov fs,ax
    mov esi,OFFSET p_list_name
    mov ecx,31

acquire_named_copy:    
    mov al,es:[edi]
    mov fs:[esi],al
    inc esi
    inc edi
    or al,al
    jz acquire_named_copied
;
    loop acquire_named_copy

acquire_named_copied:
    xor al,al
    mov fs:[esi],al
;    
    mov esi,ebx
    mov ebx,es:[esi].fs_handle
    mov ax,FUTEX_HANDLE
    DerefHandle
    jnc acquire_named_no_sect
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:futex_section
;
    mov ebx,es:[esi].fs_handle
    mov ax,FUTEX_HANDLE
    DerefHandle
    jnc acquire_named_handle_ok
;
    mov cx,SIZE futex_handle_seg
    AllocateHandle
    mov ds:[ebx].fh_list,0
    mov ds:[ebx].fh_lock,0
    mov [ebx].hh_sign,FUTEX_HANDLE
;
    movzx eax,[ebx].hh_handle
    mov es:[esi].fs_handle,eax

acquire_named_handle_ok:
    push ds
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:futex_section
    pop ds

acquire_named_no_sect:
    call LockCore
    sti
    call cs:lock_futex_proc    
    mov ax,1
    xchg ax,es:[esi].fs_val
    cmp ax,-1
    je acquire_named_take
;
    mov ax,ds
    push OFFSET acquire_named_done
    call SaveLockedThread
    mov ds,ax
;
    lea edi,[ebx].fh_list     
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_futex_proc
;
    mov es:p_sleep_type,SLEEP_TYPE_FUTEX
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,esi
    jmp LoadThread

acquire_named_take:
    push es
    mov es,fs:cs_curr_thread
    mov ax,es:p_futex_id
    pop es
    mov es:[esi].fs_owner,ax
    mov es:[esi].fs_counter,1
;    
    call cs:unlock_futex_proc
    call UnlockCore
    
acquire_named_done:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop ds    
    ret
acquire_named_futex   Endp

acquire_named_futex16 Proc far
    push ebx
    push edi
    movzx edi,di
    movzx ebx,bx
    call acquire_named_futex
    pop edi
    pop ebx
    retf32
acquire_named_futex16 Endp

acquire_named_futex32 Proc far
    call acquire_named_futex
    retf32
acquire_named_futex32 Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           release_futex
;
;           DESCRIPTION:    Release futex
;
;           PARAMS:         ES:(E)BX    address to futex struct
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

release_futex_name    DB 'Release Futex',0

release_futex   Proc near
    push ds
    push fs
    push eax
    push ebx
    push cx
    push esi
;
    mov esi,ebx
    mov ebx,es:[esi].fs_handle
    mov ax,FUTEX_HANDLE
    DerefHandle
    jc release_done
;
    call LockCore
    sti
    call cs:lock_futex_proc    
;    
    mov ax,ds:[ebx].fh_list
    or ax,ax
    jz release_unlock
;    
    mov ax,1
    xchg ax,es:[esi].fs_val
    cmp ax,-1
    jne release_unlock
;    
    push di
;    
    push es
    push esi
    lea esi,ds:[ebx].fh_list
    call RemoveBlock32
    mov es:p_data,0
    mov cx,es
    mov di,es:p_futex_id
    pop esi
    pop es
;
    mov es:[esi].fs_owner,di
    mov es:[esi].fs_counter,1
    call cs:unlock_futex_proc    
;
    push es    
    mov es,cx
    call InsertLockedWakeup
    pop es
;    
    pop di
;    
    call UnlockCore
    jmp release_done

release_unlock:
    call cs:unlock_futex_proc
    call UnlockCore
    
release_done:
    pop esi
    pop cx
    pop ebx
    pop eax
    pop fs
    pop ds    
    ret
release_futex   Endp

release_futex16 Proc far
    push ebx
    movzx ebx,bx
    call release_futex
    pop ebx
    retf32
release_futex16 Endp

release_futex32 Proc far
    call release_futex
    retf32
release_futex32 Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           cleanup_futex
;
;           DESCRIPTION:    Cleanup futex
;
;           PARAMS:         ES:(E)BX    address to futex struct
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cleanup_futex_name    DB 'Cleanup Futex',0

cleanup_futex   Proc near
    push ds
    push eax
    push ebx
;
    mov ebx,es:[ebx].fs_handle
    mov ax,FUTEX_HANDLE
    DerefHandle
    jc cleanup_done
;
    FreeHandle

cleanup_done:
    pop ebx
    pop eax
    pop ds
    ret
cleanup_futex   Endp

cleanup_futex16 Proc far
    push ebx
    movzx ebx,bx
    call cleanup_futex
    pop ebx
    retf32
cleanup_futex16 Endp

cleanup_futex32 Proc far
    call cleanup_futex
    retf32
cleanup_futex32 Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           create_thread_block
;
;           DESCRIPTION:    Create thread block
;
;           PARAMETERS:     ES:(E)DI    Block name
;
;           RETURNS:        BX          Block handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_thread_block_name    DB 'Create Thread Block',0

create_thread_block     PROC near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov ax,es
    mov ds,ax
    mov esi,edi
    xor ecx,ecx

ctbSizeLoop:
    inc ecx
    lods byte ptr ds:[esi]
    or al,al
    jne ctbSizeLoop
;
    mov eax,ecx
    AllocateSmallGlobalMem    
;
    mov esi,edi
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov cx,SIZE section_handle_seg
    AllocateHandle
    mov ds:[ebx].bh_list,0
    mov ds:[ebx].bh_lock,0
    mov ds:[ebx].bh_stopped,0
    mov ds:[ebx].bh_name,es
    mov [ebx].hh_sign,BLOCK_HANDLE
    mov bx,[ebx].hh_handle
    clc
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_thread_block     ENDP

create_thread_block16 Proc far
    push edi
;
    movzx edi,di
    call create_thread_block
;
    pop edi
    retf32
create_thread_block16 Endp

create_thread_block32 Proc far
    call create_thread_block
    retf32
create_thread_block32 Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           wait_thread_block
;
;           DESCRIPTION:    Wait thread block
;
;           PARAMETERS:     BX          Block handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_thread_block_name    DB 'Wait Thread Block',0

wait_thread_block     PROC far
    push ds
    push es
    push fs
    pushad
;
    mov ax,BLOCK_HANDLE
    DerefHandle
    jc wtbDone
;
    call LockCore
    sti
    call cs:lock_block_proc    
;
    mov ax,ds:[ebx].bh_stopped
    or ax,ax
    jnz wtbLeave
;
    push ds
    mov ds,ds:[ebx].bh_name
    xor esi,esi
;
    GetThread
    mov es,ax
    mov edi,OFFSET p_list_name
    mov ecx,31

wtbNameCopy:    
    lods byte ptr ds:[esi]
    stos byte ptr es:[edi]
    or al,al
    jz wtbNameCopied
;
    loop wtbNameCopy

wtbNameCopied:
    xor al,al
    stos byte ptr es:[edi]
    pop ds
;
    mov ax,ds
    push OFFSET wtbDone
    call SaveLockedThread
    mov ds,ax
;
    lea edi,[ebx].bh_list
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_block_proc
;
    mov es:p_sleep_type,SLEEP_TYPE_BLOCK
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,esi
    jmp LoadThread

wtbLeave:
    call cs:unlock_block_proc
    call UnlockCore

wtbDone:
    popad
    pop fs
    pop es
    pop ds
    retf32
wait_thread_block     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           close_thread_block
;
;           DESCRIPTION:    Close thread block
;
;           PARAMETERS:     BX          Block handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_thread_block_name    DB 'Close Thread Block',0

close_thread_block     PROC far
    push ds
    push es
    push fs
    pushad
;
    mov ax,BLOCK_HANDLE
    DerefHandle
    jc ctbDone
;
    mov ds:[ebx].hh_sign,0
;
    call LockCore
    sti
    call cs:lock_block_proc    
;   
    inc ds:[ebx].bh_stopped

ctbWake: 
    mov ax,ds:[ebx].bh_list
    or ax,ax
    jz ctbUnlock
;    
    lea esi,ds:[ebx].bh_list
    call RemoveBlock32
    mov es:p_data,0
;
    call InsertLockedWakeup
    jmp ctbWake

ctbUnlock:
    call cs:unlock_block_proc
    call UnlockCore
;
    call LockCore
    sti
    call cs:lock_block_proc    
    call cs:unlock_block_proc
    call UnlockCore
;
    mov es,ds:[ebx].bh_name
    FreeMem
;
    FreeHandle

ctbDone:
    popad
    pop fs
    pop es
    pop ds
    retf32
close_thread_block     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete thread block handle
;
;           DESCRIPTION:    Delete a handle (called from handle module)
;
;           PARAMETERS:     BX              HANDLE TO DIR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_thread_block_handle   Proc far
    push ds
    push es
    push ax
    push ebx
;
    mov ax,BLOCK_HANDLE
    DerefHandle
    jc dtbhDone
;
    mov es,ds:[ebx].bh_name
    FreeMem
;
    FreeHandle
    clc

dtbhDone:
    pop ebx
    pop ax
    pop es
    pop ds
    ret
delete_thread_block_handle   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           set_thread_action
;
;           DESCRIPTION:    Set thread action text
;
;           PARAMS:         ES:(E)DI    Action buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_thread_action_name    DB 'Set Thread Action',0

set_thread_action   Proc near
    push ds
    push eax
    push ecx
    push esi
    push edi
;    
    mov esi,OFFSET p_action_text
    mov ecx,32
    GetThread
    mov ds,ax

staLoop:
    mov al,es:[edi]
    mov ds:[esi],al
    or al,al
    jz staDone
;
    inc esi
    inc edi
    loop staLoop    

staDone:  
    pop edi
    pop esi
    pop ecx
    pop eax
    pop ds      
    ret
set_thread_action   Endp

set_thread_action16 Proc far
    push edi
    movzx edi,di
    call set_thread_action
    pop edi
    retf32
set_thread_action16 Endp

set_thread_action32 Proc far
    call set_thread_action
    retf32
set_thread_action32 Endp

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

get_thread      PROC far
    push ds
    mov ax,SEG data
    verr ax
    jz get_thread_norm

get_thread_pre_tasking:
    mov ax,virt_thread_sel
    jmp get_thread_done

get_thread_norm:
    mov ax,core_data_sel
    mov ds,ax
    mov ax,ds:cs_curr_thread

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
    mov ax,core_data_sel
    mov ds,ax
    mov ax,ds:cs_curr_thread    
    pop ds
    retf32
get_thread_pr   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFlatSize
;
;           DESCRIPTION:    Get flat size
;
;           PARAMETERS:     EAX          Flat size
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_flat_size_name DB 'Get Flat Size',0

get_flat_size   PROC far
    push ds
    mov ax,core_data_sel
    mov ds,ax
    mov ds,ds:cs_curr_thread    
    mov eax,ds:p_flat_size
    pop ds
    retf32
get_flat_size   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsLongThread
;
;       DESCRIPTION:    Check for long mode thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_long_thread_name   DB 'Is Long Thread', 0

is_long_thread   Proc far
    push ds
    push ax
;    
    mov ax,core_data_sel
    mov ds,ax
    mov ds,ds:cs_curr_thread    
    mov ax,ds:p_tss_sel
    or ax,ax
    clc
    jz iltDone
;
    stc

iltDone:
    pop ax    
    pop ds
    retf32
is_long_thread  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCore
;
;           DESCRIPTION:    Get current core #
;
;           RETURNS:        AX          Core
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_core_id_name   DB 'Get Core ID',0

get_core_id    PROC far
    push ds
    mov ax,core_data_sel
    mov ds,ax
    mov ax,ds:cs_id
    pop ds
    retf32
get_core_id    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCoreCount
;
;           DESCRIPTION:    Get number of cores
;
;           RETURNS:        CX          Core count
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_core_count_name   DB 'Get Core Count',0

get_core_count    PROC far
    mov cx,cs:core_count
    retf32
get_core_count    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCoreLoad
;
;           DESCRIPTION:    Get core load
;
;           PARAMETERS:     AX          Core #
;
;           RETURNS:        EDX:EAX     core tics
;                           ECX:EBX     null tics
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_core_load_name   DB 'Get Core Load',0

get_core_load    PROC far
    cmp ax,cs:core_count
    jae gclFail
;
    push ds
    push si
;    
    mov si,ax
    add si,si
    mov ds,cs:[si].core_arr

gclCoreRetry:    
    mov edx,ds:cs_msb_tics
    mov eax,ds:cs_lsb_tics
    cmp edx,ds:cs_msb_tics
    jne gclCoreRetry
;
    mov ds,ds:cs_null_thread

gclNullRetry:
    mov ecx,ds:p_msb_tics
    mov ebx,ds:p_lsb_tics
    cmp ecx,ds:p_msb_tics
    jne gclNullRetry
;
    pop si
    pop ds
    clc
    jmp gclDone

gclFail:
    stc

gclDone:             
    retf32
get_core_load    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCoreDuty
;
;           DESCRIPTION:    Get core duty cycle
;
;           PARAMETERS:     AX          Core #
;
;           RETURNS:        EDX:EAX     core tics
;                           ECX:EBX     total tics
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_core_duty_name   DB 'Get Core Duty',0

get_core_duty    PROC far
    cmp ax,cs:core_count
    jae gcdFail
;
    push ds
    push si
;    
    mov si,ax
    add si,si
    mov ds,cs:[si].core_arr
    GetSystemTime
    mov ecx,edx
    mov ebx,eax

gcdRetry:    
    mov edx,ds:cs_msb_tics
    mov eax,ds:cs_lsb_tics
    cmp edx,ds:cs_msb_tics
    jne gcdRetry
;
    pop si
    pop ds
    clc
    jmp gcdDone

gcdFail:
    stc

gcdDone:             
    retf32
get_core_duty    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SoftReset
;
;           DESCRIPTION:    Trigger a CPU soft reset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

soft_reset_name  DB 'Soft Reset',0

soft_reset       PROC far
    IsLongThread
    cli
    pushf
;
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
    popf
    jc prot_reset
;
    xor eax,eax
    mov cr3,eax
;    LongModeReset

prot_reset:    
    mov ax,idt_sel
    mov ds,ax
;    
    mov bx,13 * 8
    xor eax,eax
    mov [bx],eax
    mov [bx+4],eax
;
    mov bx,8 * 8
    mov [bx],eax
    mov [bx+4],eax
;
    mov ax,-1
    mov ds,ax

reset_wait:
    jmp reset_wait
    
    retf32
soft_reset       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HardReset
;
;           DESCRIPTION:    Trigger a CPU hard reset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hard_reset_name  DB 'Hard Reset',0

hard_reset       PROC far
    SoftReset
    retf32
hard_reset       ENDP

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
    call TryLockCore
    sti
    mov es,cx
    call InsertLockedWakeup
    call TryUnlockCore
    retf32
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
    mov cx,SEG data
    mov ds,cx
    mov cx,fs:cs_curr_thread
    mov bx,cs
    mov es,bx
    mov edi,OFFSET wake_until
    xor bx,bx
    StartTimer
;
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    mov es:p_sleep_type,SLEEP_TYPE_WAIT
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0
    jmp LoadThread

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
    mov es,fs:cs_curr_thread
    mov bx,1193
    mul bx
    push dx
    push ax
    pop ebx
    GetSystemTime
;
    add eax,ebx
    adc edx,0
;
    mov cx,SEG data
    mov ds,cx
    mov cx,es
    mov bx,cs
    mov es,bx
    mov edi,OFFSET wake_until
    xor bx,bx
    StartTimer
;    
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    mov es:p_sleep_type,SLEEP_TYPE_WAIT
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0    
    jmp LoadThread

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
    mov es,fs:cs_curr_thread
    movzx eax,ax
    mov ebx,78184
    mul ebx
    push dx
    push eax
    pop ax
    pop ebx
    GetSystemTime
    add eax,ebx
    adc edx,0
;
    mov cx,SEG data
    mov ds,cx
    mov cx,es
    mov bx,cs
    mov es,bx
    mov edi,OFFSET wake_until
    xor bx,bx
    StartTimer
;    
    mov es,fs:cs_curr_thread
    mov fs:cs_curr_thread,0
;
    mov es:p_sleep_type,SLEEP_TYPE_WAIT
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0
    jmp LoadThread

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

Inactive_state  DB 'Inactive',0
Realtime_state  DB 'Realtime',0
Wait_state      DB 'Wait',0
Ready_state     DB 'Ready',0
Signal_state    DB 'Signal',0
Debug_state     DB 'Debug',0
Futex_state     DB 'User Section',0
Section_state   DB 'Kernel Section',0
Suspend_state   DB 'Suspend',0

Irq_state       DB 'Irq ', 0
Wakeup_state    DB 'Wakeup ',0 
Run_state       DB 'Run ', 0
Ready_cpu_state DB 'Ready ',0

check_list      Proc far
    push ds
    push fs
    push ax
    push si
;
    GetCoreCount
    xor dx,dx

check_cpu_loop:
    mov ax,dx
    GetCoreNumber
    jc check_not_cpu
;
    cmp bx,fs:cs_null_thread
    je check_null_ok
;    
    cmp bx,fs:cs_curr_thread
    je check_curr_ok
;   
    mov ax,fs
    mov fs,bx
    cmp ax,fs:p_sleep_sel
    jne check_cpu_next
;
    mov eax,fs:p_sleep_offset
    cmp ax,OFFSET cs_wakeup_arr
    je check_wakeup_ok
;
    mov ax,fs:p_sleep_type
    or ax,ax
    jz check_cpu_ready_ok

check_cpu_next:
    inc dx
    add si,2
    loop check_cpu_loop
    jmp check_not_cpu

check_curr_ok:
    mov si,OFFSET Run_state
    jmp check_copy_id
    
check_null_ok:    
    cmp bx,fs:cs_curr_thread
    mov si,OFFSET Run_state
    je check_copy_id
;
    mov fs,bx
    mov al,fs:p_active
    mov si,OFFSET Ready_cpu_state
    or al,al
    jnz check_copy_id
;
    mov al,fs:p_realtime
    mov si,OFFSET Realtime_state
    or al,al
    jnz check_copy_no_id
;
    mov si,OFFSET Inactive_state

check_copy_no_id:
    mov al,cs:[si]
    or al,al
    jz check_copy_end
;
    inc si
    stos byte ptr es:[edi]
    jmp check_copy_no_id

check_wakeup_ok:
    mov si,OFFSET Wakeup_state
    jmp check_copy_id

check_cpu_ready_ok:
    mov si,OFFSET Ready_cpu_state
    jmp check_copy_id

check_copy_id:
    mov al,cs:[si]
    or al,al
    jz check_copy_id_done
;
    inc si
    stos byte ptr es:[edi]
    jmp check_copy_id

check_copy_id_done:
    mov al,dl
    call ToHex
    stos word ptr es:[edi]

check_copy_end:
    xor al,al
    stos byte ptr es:[edi]
;
    mov ds,bx
    mov cx,ds:p_cs
    mov edx,dword ptr ds:p_rip   
    clc
    jmp check_done
    
check_not_cpu:
    mov fs,bx
    mov ax,fs:p_sleep_type
    cmp ax,SLEEP_TYPE_WAIT
    jne check_not_wait
;
    mov si,OFFSET Wait_state
    jmp check_copy_zero

check_not_wait:
    cmp ax,SLEEP_TYPE_SIGNAL
    jne check_not_signal
;
    mov al,fs:p_irq
    or al,al
    jz check_signal
;
    mov si,OFFSET Irq_state

check_copy_irq:
    mov al,cs:[si]
    or al,al
    jz check_copy_irq_done
;
    inc si
    stos byte ptr es:[edi]
    jmp check_copy_irq

check_copy_irq_done:
    push fs
    mov fs,fs:p_core
    mov ax,fs:cs_id
    pop fs
    call ToHex
    stos word ptr es:[edi]
;
    mov al,'.'
    stos byte ptr es:[edi]
;    
    mov al,fs:p_irq
    call ToHex
    stos word ptr es:[edi]
;
    xor al,al    
    stos byte ptr es:[edi]
;
    xor cx,cx
    xor edx,edx
    clc
    jmp check_done

check_signal:
    mov si,OFFSET Signal_state
    jmp check_copy_zero
    
check_not_signal:
    cmp ax,SLEEP_TYPE_DEBUG
    jne check_not_debug
;
    mov si,OFFSET Debug_state
    jmp check_copy_cpu
    
check_not_debug:
    cmp ax,SLEEP_TYPE_SECTION
    jne check_not_kernel
;
    mov si,OFFSET Section_state
    jmp check_copy_sleep
    
check_not_kernel:
    cmp ax,SLEEP_TYPE_SUSPEND
    jne check_not_suspend
;
    mov si,OFFSET Suspend_state
    jmp check_copy_sleep
    
check_not_suspend:
    cmp ax,SLEEP_TYPE_FUTEX
    jne check_not_futex
;
    mov si,OFFSET p_list_name
    mov cx,32

check_futex_copy:
    mov al,fs:[si]
    or al,al
    jz check_futex_done

    inc si
    stos byte ptr es:[edi]
    loop check_futex_copy

check_futex_done:
    xor al,al    
    stos byte ptr es:[edi]
;
    xor cx,cx
    xor edx,edx
    clc
    jmp check_done

check_not_futex:
    cmp ax,SLEEP_TYPE_BLOCK
    jne check_not_block
;
    mov si,OFFSET p_list_name
    mov cx,32

check_block_copy:
    mov al,fs:[si]
    or al,al
    jz check_block_done

    inc si
    stos byte ptr es:[edi]
    loop check_block_copy

check_block_done:
    xor al,al    
    stos byte ptr es:[edi]
;
    xor cx,cx
    xor edx,edx
    clc
    jmp check_done

check_not_block:
    cmp ax,SLEEP_TYPE_WAIT_DEV
    jne check_not_wait_dev
;
    mov si,OFFSET p_list_name
    mov cx,32

check_wait_dev_copy:
    mov al,fs:[si]
    or al,al
    jz check_wait_dev_done

    inc si
    stos byte ptr es:[edi]
    loop check_wait_dev_copy

check_wait_dev_done:
    xor al,al    
    stos byte ptr es:[edi]
;
    xor cx,cx
    xor edx,edx
    clc
    jmp check_done

check_not_wait_dev:
    cmp ax,SEG data
    jne check_failed
;
    mov si,OFFSET Ready_state
    jmp check_copy_cpu

check_copy_zero:
    xor cx,cx
    xor edx,edx
    jmp check_copy

check_copy_cpu:
    mov ds,bx
    mov cx,ds:p_cs
    mov edx,dword ptr ds:p_rip   
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
    
check_failed:
    stc

check_done:
    pop si
    pop ax
    pop fs
    pop ds
    retf32
check_list      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DebugBreak
;
;           DESCRIPTION:    Put thread in debug list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_exc_break_name    DB 'Debug Exc Break',0

debug_exc_break:
    DebugException
    
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
    GetSystemTime
    add eax,cs:time_diff
    adc edx,cs:time_diff+4
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
    cli
    sub eax,cs:time_diff
    sbb edx,cs:time_diff+4
    sti
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
    cli
    add eax,cs:time_diff
    adc edx,cs:time_diff+4
    sti
    retf32
system_time_to_time     ENDP
    
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
    push esi
    push edi
;    
    mov bx,SEG data
    mov ds,bx
    mov ds,ds:patch_sel
    cli
    mov esi,ds:time_diff
    mov edi,ds:time_diff+4
    mov ds:time_diff,eax
    mov ds:time_diff+4,edx
    sti
;
    mov bx,time_data_sel
    mov ds,bx
    mov ds:ut_time_diff+1000h,eax
    mov ds:ut_time_diff+1004h,edx
;
    sub esi,eax
    sbb edi,edx
    test edi,80000000h    
    jz utSignOk
;
    not esi
    not edi

utSignOk:    
    or edi,edi
    jnz utSetRtc
;
    cmp esi,1193000
    jb utDone    

utSetRtc:
    mov ax,update_rtc_nr
    IsValidOsGate
    jc utDone
;
    UpdateRtc

utDone:
    pop edi
    pop esi
    pop bx
    pop ds
    retf32
update_time     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_THREAD_BLOCK
;
;           DESCRIPTION:    Allocate thread control block
;
;           RETURNS:        ES          Thread control block
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_thread_block   PROC near
    push ebx
    push ecx
    push edx
;
    mov eax,SIZE thread_seg
    AllocateSmallGlobalMem
    mov es:p_thread_sel,es
;    
    mov bx,es
    GetSelectorBaseSize
    mov es:p_linear,edx
    mov es:p_active,1
    mov es:p_realtime,0
;
    pop edx
    pop ecx
    pop ebx    
    ret
allocate_thread_block   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_NULL_THREAD_BLOCK
;
;           DESCRIPTION:    Allocate thread control block for null process (4k page aligned)
;
;           RETURNS:        ES          Thread control block
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_null_thread_block   PROC near
    push eax
    push ebx
    push ecx
    push edx
;
    mov eax,SIZE thread_seg
    dec eax
    and ax,0F000h
    add eax,1000h
    push eax
    AllocateBigLinear
    pop ecx
    AllocateGdt
    CreateDataSelector32
    mov es,bx
    mov es:p_linear,edx
    mov es:p_active,0
    mov es:p_realtime,0
    mov es:p_serv_sel,0
;
    pop edx
    pop ecx
    pop ebx    
    pop eax
    ret
allocate_null_thread_block   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_CREATE_THREAD
;
;           DESCRIPTION:    Handle CreateThread hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_create_thread      PROC near
    sti
    push cx
    mov ax,hook_sel
    mov ds,ax
    mov cl,ds:create_thread_hooks
    or cl,cl
    je trap_create_thread_done
;
    mov bx,OFFSET create_thread_arr

trap_create_thread_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_create_thread_loop

trap_create_thread_done:
    pop cx
    ret
trap_create_thread      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_TERMINATE_THREAD
;
;           DESCRIPTION:    Handle TerminateThread hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_terminate_thread   PROC near
    push cx
    mov ax,hook_sel
    mov ds,ax
    mov cl,ds:terminate_thread_hooks
    or cl,cl
    je trap_terminate_thread_done
;
    mov bx,OFFSET terminate_thread_arr

trap_terminate_thread_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_terminate_thread_loop

trap_terminate_thread_done:
    pop cx
    ret
trap_terminate_thread   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_CREATE_PROCESS
;
;           DESCRIPTION:    Handle CreateProcess hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_create_process     PROC near
    sti
    push cx
    push si
;
    InitProcessMem
;
    mov ax,hook_sel
    mov ds,ax
    mov cl,ds:create_process_hooks
    or cl,cl
    je trap_create_process_done
    mov bx,OFFSET create_process_arr
trap_create_process_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_create_process_loop
trap_create_process_done:
    pop si
    pop cx
;
    xor ebp,ebp
    call trap_create_thread
    ret
trap_create_process     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitProcess
;
;           DESCRIPTION:    Init process
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_name DB 'Init Process', 0

init_process     PROC far
    push ds
    push es
    push fs
    push gs
    pushad
;
    InitProcessMem
;
    mov ax,hook_sel
    mov ds,ax
    mov cl,ds:create_process_hooks
    or cl,cl
    je init_process_done
;
    mov bx,OFFSET create_process_arr

init_process_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz init_process_loop

init_process_done:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    retf32
init_process     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_INIT_TASKING
;
;           DESCRIPTION:    Handle init-tasking hooks
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
trap_init_tasking       PROC near
    InitTrapGates
;
    mov al,16
    SetBitness
;
    call trap_create_process
    CreatePrivateLdt
    CreateHandleData
    ApplyProcHandle
;
    push cx
    mov ax,hook_sel
    mov ds,ax
    mov cl,ds:init_tasking_hooks
    or cl,cl
    je trap_init_tasking_done
    mov bx,OFFSET init_tasking_arr
trap_init_tasking_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
;
    add bx,8
    dec cl
    jnz trap_init_tasking_loop
trap_init_tasking_done:
    pop cx
    ret
trap_init_tasking       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI       Buffer
;                           AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
AddHexByte    PROC near
    push eax
;    
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb add_byte_low1
;    
    add al,7

add_byte_low1:
    add al,'0'
    stosb
;
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb add_byte_high1
;
    add al,7

add_byte_high1:
    add al,'0'
    stosb
;
    pop eax
    ret
AddHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI       Buffer
;                           AX           Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
AddHexWord    PROC near
    xchg al,ah
    call AddHexByte
    xchg al,ah
    call AddHexByte
    ret
AddHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           create_process_sel
;
;       DESCRIPTION:    Create process selector
;
;       PARAMETERS:     EAX         CR3
;                       BX          Program ID
;                       ES          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_process_sel Proc near
    push ds
    push es
    push fs
    pushad
;
    mov edx,es
    mov fs,edx
;
    push eax
    mov eax,SIZE process_struc + 4
    AllocateSmallGlobalMem
    pop eax
    mov es:pf_cr3,eax
;
    mov es:pf_virt_flags,7200h
    mov es:pf_wait_sti,0
    mov es:pf_iopl,0
    mov es:pf_cli_thread,0
    mov es:pf_thread_count,0
    mov es:pf_module_count,0
    mov es:pf_cur_dir_sel,0
    mov es:pf_env_sel,0
    mov es:pf_program_id,bx
    InitSection es:pf_section
;
    mov es:pf_mem_blocks,0
    InitSection es:pf_mem_section
;
    mov fs:p_prog_id,bx
    movzx ebx,bx
    GetProgramSel
    mov es:pf_program_sel,ax
    mov fs:p_prog_sel,ax
;
    mov ds,ax
    mov bx,es
    movzx ebx,bx
    ProcessCreated
;
    push ax
    mov edi,OFFSET pf_name
    call AddHexWord
    xor al,al
    stosb
    pop ax
;
    EnterSection ds:pr_section
;
    movzx ecx,ds:pr_process_count
    cmp ecx,MAX_PROGRAM_PROCESSES
    jae cpsLeave
;
    mov ebx,ecx
    shl ebx,1
    inc ecx
    mov ds:pr_process_count,cx
;
    mov ds:[ebx].pr_process_arr,ax
    
cpsLeave:
    LeaveSection ds:pr_section
;
    mov fs:p_proc_id,ax
    movzx ebx,ax
    ProcessIdToSel
    mov fs:p_proc_sel,bx
;
    popad
    pop fs
    pop es
    pop ds
    ret
create_process_sel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           add_process_thread
;
;       DESCRIPTION:    Add thread to process
;
;       PARAMETERS:     DS          Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_process_thread Proc near
    push ds
    mov ax,ds:p_id
    mov ds,ds:p_proc_sel
    EnterSection ds:pf_section
;
    movzx ecx,ds:pf_thread_count
    cmp ecx,MAX_PROCESS_THREADS
    jae aptLeave
;
    mov ebx,ecx
    shl ebx,1
    inc ecx
    mov ds:pf_thread_count,cx
;
    mov ds:[ebx].pf_thread_arr,ax
    
aptLeave:
    LeaveSection ds:pf_section
    pop ds
    ret
add_process_thread   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           copy_process_modules
;
;       DESCRIPTION:    Copy modules to new process
;
;       PARAMETERS:     ES          New thread
;                       FS          Present thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy_process_modules Proc near
    push ds
    push es
    pushad
;
    mov ds,fs:p_proc_sel
    mov es,es:p_proc_sel
    xor ebx,ebx
    movzx ecx,ds:pf_module_count
    mov es:pf_module_count,cx

cpmLoop:
    mov ax,ds:[ebx].pf_module_arr
    mov es:[ebx].pf_module_arr,ax
;
    mov ax,ds:[ebx].pf_module_usage_arr
    mov es:[ebx].pf_module_usage_arr,ax
;
    add ebx,2
    loop cpmLoop
;
    popad
    pop es
    pop ds
    ret
copy_process_modules Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           setup_fork
;
;       DESCRIPTION:    Setup fork environment
;
;       PARAMETERS:     ES          Forked thread
;                       FS          Forking thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_fork Proc near
    push ds
    push gs
    pushad
;
    mov ds,es:p_prog_sel
    EnterSection ds:pr_cow_section
;
    movzx ecx,ds:pr_page_table_count
    or ecx,ecx
    jnz sfAddNew
;
    mov ds,fs:p_proc_sel
    mov eax,fs:p_cr3
    CreateFork
;
    mov eax,ds:pf_page_dir
    mov edx,ds:pf_page_table
;
    mov ds,es:p_prog_sel
    mov ds:pr_page_dir_arr,eax
    mov ds:pr_page_table_arr,edx
    inc ecx

sfAddNew:
    mov ds,es:p_proc_sel
    mov eax,es:p_cr3
    CreateFork
;
    mov eax,ds:pf_page_dir
    mov edx,ds:pf_page_table
;
    mov ds,es:p_prog_sel
    mov ebx,ecx
    shl ebx,2
    mov ds:[ebx].pr_page_dir_arr,eax
    mov ds:[ebx].pr_page_table_arr,edx
;
    inc ecx
    mov ds:pr_page_table_count,cx
;
    push es
    mov ds,fs:p_proc_sel
    mov es,es:p_proc_sel
    StartFork
    pop es
;
    mov ds,es:p_prog_sel
    LeaveSection ds:pr_cow_section

    popad
    pop gs
    pop ds
    ret
setup_fork Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           create_env_sel
;
;           DESCRIPTION:    create env selector
;
;           PARAMETERS:     ES          New thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_env_sel       PROC near
    push ds
    push es
    push fs
    push eax
;
    GetThread
    mov ds,ax
    mov fs,ds:p_proc_sel
    mov ax,fs:pf_env_sel
    or ax,ax
    jz cesCreate

cesClone:
    CloneEnvSel
    jmp cesSave

cesCreate:
    CreateEnvSel

cesSave:
    mov fs,es:p_proc_sel
    mov fs:pf_env_sel,ax    
;
    pop eax
    pop fs
    pop es 
    pop ds
    ret
create_env_sel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           create_cur_dir
;
;           DESCRIPTION:    create current dir sel
;
;           PARAMETERS:     ES          New thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_cur_dir       PROC near
    push ds
    push es
    push fs
    push eax
;
    GetThread
    mov ds,ax
    mov fs,ds:p_proc_sel
    mov ax,fs:pf_cur_dir_sel
    or ax,ax
    jz ccdCreate

ccdClone:
    CloneCurDir
    jmp ccdSave

ccdCreate:
    CreateCurDir

ccdSave:
    mov fs,es:p_proc_sel
    mov fs:pf_cur_dir_sel,ax    
;
    pop eax
    pop fs
    pop es 
    pop ds
    ret
create_cur_dir  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_THREAD_BLOCK
;
;           DESCRIPTION:    Init thread content
;
;           PARAMETERS:     ES          Thread
;                           DX          Priority
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread_block       PROC near
    GetThread
    mov ds,ax
;
    push fs
    GetCore
    mov es:p_core,fs
    pop fs
;
    mov es:p_irq,0
    mov es:p_signal_spinlock,0
    mov es:p_wanted_core,0
;
    mov ax,ds:p_prog_id
    mov es:p_prog_id,ax
;
    mov ax,ds:p_prog_sel
    mov es:p_prog_sel,ax
;
    mov ax,ds:p_proc_id
    mov es:p_proc_id,ax
;
    mov ax,ds:p_proc_sel
    mov es:p_proc_sel,ax
;
    mov ax,ds:p_loader
    mov es:p_loader,ax
;
    mov eax,ds:p_flat_size
    mov es:p_flat_size,eax
;
    mov ax,ds:p_ldt_sel
    mov es:p_ldt_sel,ax
;
    mov ax,ds:p_ldt_obj
    mov es:p_ldt_obj,ax
;
    mov ax,ds:p_serv_sel
    mov es:p_serv_sel,ax
;
    mov eax,ds:p_tls_bitmap
    mov es:p_tls_bitmap,eax
;
    mov ax,ds:p_console
    mov es:p_console,ax
;
    mov ax,ds:p_parent_console
    mov es:p_parent_console,ax
;
    mov ax,ds:p_lib_sel
    mov es:p_lib_sel,ax
;
    mov es:p_debug_event,0
;
    mov es:p_signal,0
    mov es:p_wait_list,0
    mov es:p_kill,0
    mov es:p_ref_count,0
    mov es:p_is_waiting,0
    mov es:p_flags,0
    mov es:p_sleep_sel,0
;
    add dx,dx
    mov es:p_prio,dx
    xor eax,eax
    mov es:p_msb_tics,eax
    mov es:p_lsb_tics,eax
    mov es:p_deb_phys,eax
    mov es:p_deb_phys+4,eax
    mov es:p_pm_deb_sel,ax
    mov es:p_pm_deb_offs,eax
    mov es:p_events,0
;
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0
    CreatePid
    mov es:p_id,ax
    ret
init_thread_block       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROT_THREAD
;
;           DESCRIPTION:    Init protected mode thread
;
;           PARAMETERS:         ES          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_prot_thread    PROC near
    push ds
    lds esi,[ebp].cr_name
    mov di,OFFSET thread_name
    mov cx,30
pm_move_thread_name:
    lods byte ptr [esi]
    or al,al
    jz pm_move_pad_name
    stosb
    loop pm_move_thread_name
    jmp pm_move_pad_done
pm_move_pad_name:
    mov al,' '
    rep stosb
pm_move_pad_done:
    pop ds
    ret
init_prot_thread    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_VIRT_THREAD
;
;           DESCRIPTION:    Init V86 mode thread
;
;           PARAMETERS:         ES          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_virt_thread    PROC near
    push ds
    xor eax,eax
    mov ax,[ebp].cr_name
    xor edx,edx
    mov dx,[ebp+4].cr_name
    shl edx,4
    add edx,eax
    mov ax,flat_sel
    mov ds,ax
    mov di,OFFSET thread_name
    mov cx,30
vm_move_thread_name:
    mov al,[edx]
    or al,al
    jz vm_move_pad_name
    inc edx
    stosb
    loop vm_move_thread_name
    jmp vm_move_pad_done
vm_move_pad_name:
    mov al,' '
    rep stosb
vm_move_pad_done:
    pop ds
    ret
init_virt_thread    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateTss32
;
;   DESCRIPTION:    Create 32-bit TSS
;
;   PARAMETERS:     DS          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_tss32    PROC near
    push es
    push eax
    push ebx
    push ecx
    push edx
;
    mov ax,flat_sel
    mov es,ax
;    
    mov eax,SIZE tss32_seg
    mov ecx,eax
    AllocateSmallLinear
    mov edi,edx
;    
    push ecx
    push edi
    xor al,al
    rep stos byte ptr es:[edi]
    pop edi
    pop ecx
;
    mov es:[edi].tss32_bitmap,OFFSET tss32_io_bitmap
;    
    mov eax,stack0_size
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector32
;    
    mov es:[edi].tss32_esp0,stack0_size
    mov es:[edi].tss32_ess0,bx
;    
    mov ds:p_kernel_esp,stack0_size
    mov ds:p_kernel_ss,bx
    mov es,bx
    mov es:[0],bx
;
    add edx,stack0_size
    mov ds:p_kernel_stack,edx
;    
    mov ecx,SIZE tss32_seg
    mov edx,edi
    AllocateGdt
    CreateTssSelector
    mov ds:p_tss_sel,bx
    mov ds:p_tss_linear,edi
    mov ds:p_futex_id,bx
;    
    sldt dx
    mov ds:p_ldt,dx
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
create_tss32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateInitialTss
;
;   DESCRIPTION:    Create initial TSS
;
;   PARAMETERS:     DS          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_initial_tss    PROC near
    push es
    push eax
    push ebx
    push ecx
    push edx
;
    mov ax,flat_sel
    mov es,ax
;    
    mov eax,OFFSET tss32_io_bitmap + 2000h
    mov ecx,eax
    AllocateSmallLinear
    mov edi,edx
;    
    push ecx
    push edi
    xor al,al
    rep stos byte ptr es:[edi]
    pop edi
    pop ecx
;
    mov es:[edi].tss32_bitmap,OFFSET tss32_io_bitmap
;    
    mov eax,stack0_size
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector32
;    
    mov es:[edi].tss32_esp0,stack0_size
    mov es:[edi].tss32_ess0,bx
;    
    mov ds:p_kernel_esp,stack0_size
    mov ds:p_kernel_ss,bx
    mov es,bx
    mov es:[0],bx
;
    add edx,stack0_size
    mov ds:p_kernel_stack,edx
;    
    mov ecx,OFFSET tss32_io_bitmap + 2000h
    mov edx,edi
    AllocateGdt
    CreateTssSelector
    mov ds:p_tss_sel,bx
    mov ds:p_futex_id,bx
;    
    sldt dx
    mov ds:p_ldt,dx
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
create_initial_tss    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateTss64
;
;   DESCRIPTION:    Create 64-bit TSS
;
;   PARAMETERS:     DS          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_tss64    PROC near
    push es
    push eax
    push ebx
    push ecx
    push edx
;
    mov ax,flat_sel
    mov es,ax
;    
    mov eax,stack0_size
    AllocateBigLinear
    mov es:[edx],eax
;    
    add edx,stack0_size
    mov ds:p_kernel_stack,edx
;
    mov ds:p_kernel_esp,edx
    mov ds:p_kernel_ss,long_kernel_data_sel
;
    mov ds:p_tss_sel,0
    mov ds:p_ldt_sel,0
    mov ds:p_ldt_obj,0
    mov ds:p_flat_size,0
    mov ds:p_ldt,long_ldt_sel
    mov ds:p_futex_id,0
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
create_tss64    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_DEFAULT_REGS
;
;           DESCRIPTION:    Setup default register state
;
;           PARAMETERS:     DS         Thread block
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_default_regs    PROC near
    mov edx,cr3
    mov es:p_cr3,edx
;
    mov edx,[ebp].cr_offs
    mov dword ptr ds:p_rip,edx
;
    mov edx,[ebp].cr_eax
    mov dword ptr ds:p_rax,edx
;
    mov edx,[ebp].cr_ecx
    mov dword ptr ds:p_rcx,edx
;
    mov edx,[ebp].cr_edx
    mov dword ptr ds:p_rdx,edx
;    
    mov edx,[ebp].cr_ebx
    mov dword ptr ds:p_rbx,edx
;
    mov edx,[ebp].cr_ebp
    mov dword ptr ds:p_rbp,edx
;
    mov edx,[ebp].cr_esi
    mov dword ptr ds:p_rsi,edx
;    
    mov edx,[ebp].cr_edi
    mov dword ptr ds:p_rdi,edx
;
    xor edx,edx
    mov dword ptr ds:p_rip+4,edx
    mov dword ptr ds:p_rsp+4,edx
    mov dword ptr ds:p_rflags+4,edx
    mov dword ptr ds:p_rax+4,edx
    mov dword ptr ds:p_rcx+4,edx
    mov dword ptr ds:p_rdx+4,edx
    mov dword ptr ds:p_rbx+4,edx
    mov dword ptr ds:p_rbp+4,edx
    mov dword ptr ds:p_rsi+4,edx
    mov dword ptr ds:p_rdi+4,edx
;    
    mov dword ptr ds:p_r8,edx
    mov dword ptr ds:p_r8+4,edx
;    
    mov dword ptr ds:p_r9,edx
    mov dword ptr ds:p_r9+4,edx
;    
    mov dword ptr ds:p_r10,edx
    mov dword ptr ds:p_r10+4,edx
;    
    mov dword ptr ds:p_r11,edx
    mov dword ptr ds:p_r11+4,edx
;    
    mov dword ptr ds:p_r12,edx
    mov dword ptr ds:p_r12+4,edx
;    
    mov dword ptr ds:p_r13,edx
    mov dword ptr ds:p_r13+4,edx
;    
    mov dword ptr ds:p_r14,edx
    mov dword ptr ds:p_r14+4,edx
;    
    mov dword ptr ds:p_r15,edx
    mov dword ptr ds:p_r15+4,edx
;    
    mov dx,[ebp].cr_seg
    mov ds:p_cs,dx
;
; dr0 - dr7
;
    xor edx,edx
    mov dword ptr ds:p_dr0,edx
    mov dword ptr ds:p_dr0+4,edx
    mov dword ptr ds:p_dr1,edx
    mov dword ptr ds:p_dr1+4,edx
    mov dword ptr ds:p_dr2,edx
    mov dword ptr ds:p_dr2+4,edx
    mov dword ptr ds:p_dr3,edx
    mov dword ptr ds:p_dr3+4,edx
    mov dword ptr ds:p_dr7,edx
    mov dword ptr ds:p_dr7+4,edx
;
; 387 status
;
    mov ds:p_math_control,37Fh
    mov ds:p_math_status,0
    mov ds:p_math_tag,0FFFFh
    mov ds:p_math_eip,0
    mov ds:p_math_cs,0
    mov ds:p_math_data_offs,0
    mov ds:p_math_data_sel,0
;
; thread control
;
    mov ds:p_fault_vector,-1
    mov dword ptr ds:p_fault_code,0
    mov dword ptr ds:p_fault_code+4,0
    mov ds:p_action_text,0
;
    mov ds:p_tls_array,0
    ret
init_default_regs    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROT_TSS
;
;           DESCRIPTION:    Init protected mode TSS
;
;           PARAMETERS:         DS              TSS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_prot_tss   PROC near
    mov dx,[ebp].cr_flags
    or dx,200h
    and dx,NOT 7000h
    movzx edx,dx
    mov dword ptr ds:p_rflags,edx
;
    mov ax,[ebp].cr_es
    mov ds:p_es,ax
;
    mov ax,[ebp].cr_ds
    mov ds:p_ds,ax
;    
    mov ax,[ebp].cr_fs
    mov ds:p_fs,ax
;    
    mov ax,[ebp].cr_gs
    mov ds:p_gs,ax    
;
    mov es:p_free_proc,0
    mov es:p_free_proc+4,0
    mov ax,[ebp].cr_seg
    test ax,3
    jz init_kernel_tss
;
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov dword ptr ds:p_rsp,stack0_size
    mov ds:p_stack_sel,0
;
    mov ecx,[ebp].cr_stack
    CreateAppThread
    jmp init_prot_tss_com

init_kernel_tss:
    push es
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov bx,stack0_size - 6
    mov es,ax
    mov es:[bx+4],dx
    mov es:[bx+2],cs
    mov word ptr es:[bx],OFFSET do_terminate
    pop es
    mov dword ptr ds:p_rsp,stack0_size - 6
    mov es:p_stack_sel,0

init_prot_tss_com:
    ret
init_prot_tss   ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_LONG_TSS
;
;           DESCRIPTION:    Init long mode TSS
;
;           PARAMETERS:     DS              TSS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_long_tss   PROC near
    push fs
;
    mov dx,[ebp].cr_flags
    or dx,200h
    and dx,NOT 7000h
    movzx edx,dx
    mov dword ptr ds:p_rflags,edx
;
    mov ax,[ebp].cr_seg
    test ax,3
    jz init_long_kernel_tss
;
    int 3
    jmp init_long_tss_com

init_long_kernel_tss:
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov ebx,ds:p_kernel_stack
    mov dword ptr ds:p_rsp,ebx
    mov es:p_stack_sel,0

init_long_tss_com:
    mov ax,[ebp].cr_es
    mov ds:p_es,ax
;
    mov ax,[ebp].cr_ds
    mov ds:p_ds,ax
;    
    mov ax,[ebp].cr_fs
    mov ds:p_fs,ax
;    
    mov ax,[ebp].cr_gs
    mov ds:p_gs,ax    
    pop fs
    ret
init_long_tss   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_VIRT_TSS
;
;           DESCRIPTION:    Init V86 mode TSS
;
;           PARAMETERS:         DS          TSS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_virt_tss   PROC near
    push es
    xor eax,eax
    mov ax,[ebp].cr_stack
    AllocateDosMem
    push eax
    mov ax,es
    SelectorToSegment
    mov ds:p_ss,ax
    pop eax
    sub eax,6
    mov dword ptr ds:p_rsp,eax
    mov dx,[ebp].cr_flags
    movzx edx,dx 
    or edx,20200h
    and dx,NOT 7000h
    mov dword ptr ds:p_rflags,edx
    mov es:[eax+4],dx
;       mov dx,SEG code
    mov es:[eax+2],dx
;       mov dx,OFFSET terminate_thread_pr
    mov es:[eax],dx
    mov ax,es
    pop es
    mov es:p_stack_sel,ax
;
    mov ax,[ebp].cr_es
    SelectorToSegment
    mov ds:p_es,ax
;
    mov ax,[ebp].cr_ds
    SelectorToSegment
    mov ds:p_ds,ax
;
    mov ax,[ebp].cr_fs
    SelectorToSegment
    mov ds:p_fs,ax
;
    mov ax,[ebp].cr_gs
    SelectorToSegment
    mov ds:p_gs,ax
    ret
init_virt_tss   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_THREAD
;
;           DESCRIPTION:    Create a thread
;
;           PARAMETERS:         AL              Priority
;                           AH              Mode, 0=PM, 1=VM, 2=long
;                           ECX             Stack size
;                           DS:(E)SI    Start address
;                           ES:(E)DI    Thread name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_thread_name      DB 'Create Thread',0

create_thread   PROC near
    sub esp,30
    push ebp
    mov ebp,esp
    pushf
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov [ebp].cr_seg,ds
    mov [ebp].cr_offs,esi
    xor dx,dx
    mov dl,al       
    mov [ebp].cr_prio,dx
    mov [ebp].cr_stack,ecx
    mov dl,ah
    mov [ebp].cr_mode,dx
    mov [ebp].cr_name,edi
    mov [ebp+4].cr_name,es
    or al,al
    jz create_null

    call allocate_thread_block
    jmp create_block_ok

create_null:
    call allocate_null_thread_block

create_block_ok:
    mov dx,[ebp].cr_prio
    call init_thread_block
    mov ax,es
    mov ds,ax
    mov ax,[ebp].cr_mode
    cmp ax,2
    jne create_t32

create_t64:
    call create_tss64
    call init_default_regs
    call add_process_thread
    jmp create_prot

create_t32:
    call create_tss32
    call init_default_regs
    call add_process_thread
    mov ax,[ebp].cr_mode
    test ax,1
    jz create_prot
    call init_virt_thread
    call init_virt_tss
    jmp create_tss_done

create_prot:
    call init_prot_thread
    call init_prot_tss
create_tss_done:
;
    or es:p_flags,THREAD_FLAG_CREATE
    call wake_new
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    popf
    pop ebp
    add esp,30
    ret
create_thread   ENDP

create_thread16 Proc far
    push ecx
    push esi
    push edi
;
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call create_thread
;
    pop edi
    pop esi
    pop ecx
    retf32
create_thread16 Endp

create_thread32 Proc far
    call create_thread
    retf32
create_thread32 Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_TIMER_THREAD
;
;           DESCRIPTION:    Create timer thread
;
;           PARAMETERS:     EBX         TLS sel
;                           EDX         Passed to thread
;                           ES:EDI      Startup of thread
;
;           RETURNS:        NC          Thread started
;                           CY          Thread already running
;                           EAX         Timer object address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_timer_thread_name DB 'Create Timer Thread',0
    
create_timer_thread   Proc far
    sub esp,32
    push ebp
    mov ebp,esp
    pushf
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov [ebp].cr_seg,es
    mov [ebp].cr_offs,edi
    mov word ptr [ebp].cr_prio,3
    mov dword ptr [ebp].cr_stack,4000h
    mov word ptr [ebp].cr_mode,0
;
    GetThread
    mov ds,eax
    mov fs,ds:p_prog_sel
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_timer_sel
    mov eax,1
    xchg al,ds:kt_started
    sub eax,1
    stc
    jz cttDone
;
    InitUserTimer
    mov esi,ds:kt_user_ptr
    add esi,1000h
    mov [ebp].cr_edi,esi
;
    mov eax,50
    AllocateSmallGlobalMem
;
    mov fs,fs:pr_name_sel
    xor esi,esi
    xor di,di
    mov cx,32

cttNameLoop:
    lods byte ptr fs:[esi]
    or al,al
    jz cttNamePad
;
    stosb
    loop cttNameLoop

cttNamePad:
    cmp cx,1
    jne cttNameTerm
;
    dec di

cttNameTerm:
    mov al,'@'
    stosb

cttNameDone:
    xor al,al
    stosb
;
    push es
;
    mov dword ptr [ebp].cr_name,0
    mov [ebp+4].cr_name,es
;
    call allocate_thread_block
;
    mov dx,[ebp].cr_prio
    call init_thread_block
    mov ax,es
    mov ds,ax
    call create_tss32
    call init_default_regs
    call add_process_thread
    call init_prot_thread
    call init_prot_tss
;
    or es:p_flags,THREAD_FLAG_CREATE
    call wake_new
;
    pop es
    FreeMem
;
    mov eax,1
    clc

cttDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    add esp,4
    pop gs
    pop fs
    pop es
    pop ds
    add esp,2
    pop ebp
    add esp,32
    retf32
create_timer_thread   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           remove_process_thread
;
;           DESCRIPTION:    Remove thread from process
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_process_thread    Proc near
    push ds
    push eax
    push ebx
    push ecx
;
    mov ds,es:p_proc_sel
    EnterSection ds:pf_section
;
    mov ax,es:p_id
    movzx ecx,ds:pf_thread_count
    mov ebx,OFFSET pf_thread_arr
    or ecx,ecx
    jz rptLeave

rptLoop:
    cmp ax,ds:[ebx]
    je rptFound
;
    add bx,2
    loop rptLoop
;
    jmp rptLeave

rptFound:
    dec ds:pf_thread_count
;
    sub ecx,1
    jz rptLeave

rptMove:
    mov ax,ds:[ebx+2]
    mov ds:[ebx],ax
    add ebx,2
    loop rptMove

rptLeave:
    LeaveSection ds:pf_section
            
rptDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
remove_process_thread    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           TERMINATE_THREAD
;
;           DESCRIPTION:    Terminate thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_thread_name   DB 'Terminate Thread',0

do_terminate:
    TerminateThread

terminate_thread:
    pushfd
    push eax
    mov eax,[esp+12]
    test al,3
    jz terminate_thread_not_user
;
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp,esp
    add ebp,28
    push dword ptr [ebp+4].load_eax
    mov eax,[ebp+4].load_eip
    mov [ebp].load_eip,eax
    mov eax,[ebp+4].load_cs
    mov [ebp].load_cs,eax
    pop dword ptr [ebp].load_eflags   
;
    TerminateAppThread

terminate_thread_not_user:
    GetThread
    mov ds,ax
    mov es,ax
    lock or es:p_flags,THREAD_FLAG_TERMINATED
;
    call remove_process_thread
;
    mov es,ds:p_thread_sel
    mov bx,es:p_stack_sel
    verr bx
    jnz no_free_ss
;
    mov es,bx
    FreeMem

no_free_ss:
    GetThread
    mov ds,ax
    mov ax,ds:p_proc_sel
    or ax,ax
    jz t_thread
;
    mov ds,ax
    mov ax,ds:pf_thread_count
    or ax,ax
    jz terminate_proc

t_thread:
    GetThread
    mov ds,ax
    mov eax,ds:p_free_proc
    or eax,ds:p_free_proc+4
    jz terminate_app_handled
;
    call fword ptr ds:p_free_proc

terminate_app_handled:
    call trap_terminate_thread
    jmp cleanup_thread

terminate_proc:
    call trap_terminate_thread
    jmp cleanup_process


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROCESS_REGS
;
;           DESCRIPTION:    Init process regs
;
;           PARAMETERS:     DS          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_regs    PROC near
    mov ax,[ebp].cr_mode
    cmp ax,2
    je init_long_proc_esp
;    
    mov eax,OFFSET create_process_callback
    mov dword ptr ds:p_rip,eax
    mov ds:p_cs,cs
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov eax,stack0_size
    mov dword ptr ds:p_rsp,eax
    jmp init_proc_esp_ok

init_long_proc_esp:    
    mov eax,OFFSET create_process_callback
    mov dword ptr ds:p_rip,eax
    mov ds:p_cs,cs
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov eax,ds:p_kernel_stack
    mov dword ptr ds:p_rsp,eax

init_proc_esp_ok:
    mov ax,[ebp].cr_mode
    cmp ax,1
    jnz init_regs_prot_iopl
;
    mov ax,[ebp].cr_flags
    or dx,200h
    and dx,NOT 7000h
    movzx edx,dx
    mov dword ptr ds:p_rflags,eax
    jmp init_regs_iopl_done

init_regs_prot_iopl:
    mov ax,[ebp].cr_flags
    or ax,200h
    and ax,NOT 7000h
    movzx eax,ax
    mov dword ptr ds:p_rflags,eax

init_regs_iopl_done:     
    xor ax,ax
    mov ds:p_es,ax
    mov ds:p_ds,ax
    mov ds:p_fs,ax
    mov ds:p_gs,ax
    mov ds:p_stack_sel,0
;
    mov ds:p_tls_bitmap,0
    mov ds:p_tls_array,0
    ret
init_process_regs    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROCESS_CALLBACK
;
;           DESCRIPTION:    Init process data
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_callback   PROC near
    push es
    mov eax,1000h
    AllocateGlobalMem
    mov ds:p_ds,es
;
    mov ax,[ebp].cr_mode
    mov es:cm_mode,ax
    mov eax,[ebp].cr_stack
    mov es:cm_stack,eax
    mov es:cm_process,fs
    mov ax,[ebp].cr_flags
    mov es:cm_flags,ax
    mov ax,[ebp].cr_seg
    mov es:cm_cs,ax
    mov eax,[ebp].cr_offs
    mov es:cm_eip,eax
    mov eax,[ebp].cr_eax
    mov es:cm_eax,eax
    mov eax,[ebp].cr_ebx
    mov es:cm_ebx,eax
    mov eax,[ebp].cr_ecx
    mov es:cm_ecx,eax
    mov eax,[ebp].cr_edx
    mov es:cm_edx,eax
    mov eax,[ebp].cr_esi
    mov es:cm_esi,eax
    mov eax,[ebp].cr_edi
    mov es:cm_edi,eax
    mov eax,[ebp].cr_ebp
    mov es:cm_ebp,eax
    pop es
    ret
init_process_callback   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CREATE_PROCESS
;
;           DESCRIPTION:    Create process
;
;           PARAMETERS:     AL          Priority
;                           AH          Mode, 0=Protected mode, 1=V86 mode, 2=Long mode
;                           BX          Program ID
;                           ECX         Stack size
;                           DS:ESI      Start address
;                           ES:EDI      Thread name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_process_name     DB 'Create Process',0

create_process  PROC far
    sub esp,30
    push ebp
    mov ebp,esp
    pushf
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov [ebp].cr_seg,ds
    mov [ebp].cr_offs,esi
    xor dx,dx
    mov dl,al       
    mov [ebp].cr_prio,dx
    mov [ebp].cr_stack,ecx
    mov dl,ah
    mov [ebp].cr_mode,dx
    mov [ebp].cr_name,edi
    mov [ebp+4].cr_name,es
    xor ax,ax
    mov fs,ax
    mov gs,ax
    call allocate_thread_block
    mov dx,[ebp].cr_prio
    call init_thread_block
    mov es:p_debug_event,0
;
    mov ax,es
    mov ds,ax
    mov ax,[ebp].cr_mode
    cmp ax,2
    jne cp32

cp64:
    call create_tss64
    call init_default_regs
    NotifyCreateLongProcess
;
    mov bx,[ebp].cr_ebx
    call create_process_sel
    call add_process_thread
    cmp bx,1
    je cpSkipped64
;
    CreateProcHandle
    call create_cur_dir
    call create_env_sel

cpSkipped64:
    jmp cpProt

cp32:
    call create_tss32
    call init_default_regs
;
    NotifyCreateProcess
    mov es:p_cr3,eax
;
    mov bx,[ebp].cr_ebx
    call create_process_sel
    call add_process_thread
    cmp bx,1
    je cpSkipped32
;
    CreateProcHandle
    call create_cur_dir
    call create_env_sel

cpSkipped32:
    mov ax,[ebp].cr_mode
    cmp ax,1
    jne cpProt
;
    call init_virt_thread
    jmp cpTssDone

cpProt:
    call init_prot_thread

cpTssDone:
    call init_process_regs
    call init_process_callback
;
    call wake_new
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
;
    pop gs
    pop fs
    pop es
    pop ds
    popf
    pop ebp
    add esp,30
    retf32
create_process  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_serv_proc_regs
;
;           DESCRIPTION:    Init server process regs
;
;           PARAMETERS:     DS          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_serv_proc_regs    PROC near
    mov eax,OFFSET create_serv_proc_callback
    mov dword ptr ds:p_rip,eax
    mov ds:p_cs,cs
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov eax,stack0_size
    mov dword ptr ds:p_rsp,eax
;
    mov ax,[ebp].cr_flags
    or ax,200h
    and ax,NOT 7000h
    movzx eax,ax
    mov dword ptr ds:p_rflags,eax
;
    xor ax,ax
    mov ds:p_es,ax
    mov ds:p_ds,ax
    mov ds:p_fs,ax
    mov ds:p_gs,ax
    mov ds:p_stack_sel,0
;
    mov ds:p_tls_bitmap,0
    mov ds:p_tls_array,0
    ret
init_serv_proc_regs    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateServProc
;
;           DESCRIPTION:    Create server process
;
;           PARAMETERS:     AL          Priority
;                           DS:ESI      Start address
;                           ES:EDI      Thread name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_serv_proc_name     DB 'Create Server Process',0

create_serv_proc  PROC far
    sub esp,30
    push ebp
    mov ebp,esp
    pushf
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov [ebp].cr_seg,ds
    mov [ebp].cr_offs,esi
    xor dx,dx
    mov dl,al       
    mov [ebp].cr_prio,dx
    mov dword ptr [ebp].cr_stack,stack0_size
    mov [ebp].cr_name,edi
    mov [ebp+4].cr_name,es
    xor ax,ax
    mov fs,ax
    mov gs,ax
    call allocate_thread_block
    mov dx,[ebp].cr_prio
    call init_thread_block
    mov es:p_debug_event,0
;
    mov ax,es
    mov ds,ax
    call create_tss32
    call init_default_regs
;
    NotifyCreateProcess
    mov es:p_cr3,eax
;
    mov bx,1
    call create_process_sel
    call add_process_thread
    call init_prot_thread
    call init_serv_proc_regs
    call init_process_callback
;
    call wake_new
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
;
    pop gs
    pop fs
    pop es
    pop ds
    popf
    pop ebp
    add esp,30
    retf32
create_serv_proc  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_FORK_REGS
;
;           DESCRIPTION:    Setup fork register state
;
;           PARAMETERS:     DS         Thread block
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_fork_regs    PROC near
    mov dword ptr ds:p_rip,OFFSET fork_start
    pushfd
    pop edx
    mov dword ptr ds:p_rflags,edx
;
    xor edx,edx
    mov dword ptr ds:p_rcx,edx
    mov dword ptr ds:p_rbx,edx
    mov dword ptr ds:p_rbp,edx
    mov dword ptr ds:p_rsi,edx
    mov dword ptr ds:p_rdi,edx
    mov dword ptr ds:p_rip+4,edx
    mov dword ptr ds:p_rsp+4,edx
    mov dword ptr ds:p_rflags+4,edx
    mov dword ptr ds:p_rax+4,edx
    mov dword ptr ds:p_rcx+4,edx
    mov dword ptr ds:p_rdx+4,edx
    mov dword ptr ds:p_rbx+4,edx
    mov dword ptr ds:p_rbp+4,edx
    mov dword ptr ds:p_rsi+4,edx
    mov dword ptr ds:p_rdi+4,edx
;    
    mov dword ptr ds:p_r8,edx
    mov dword ptr ds:p_r8+4,edx
;    
    mov dword ptr ds:p_r9,edx
    mov dword ptr ds:p_r9+4,edx
;    
    mov dword ptr ds:p_r10,edx
    mov dword ptr ds:p_r10+4,edx
;    
    mov dword ptr ds:p_r11,edx
    mov dword ptr ds:p_r11+4,edx
;    
    mov dword ptr ds:p_r12,edx
    mov dword ptr ds:p_r12+4,edx
;    
    mov dword ptr ds:p_r13,edx
    mov dword ptr ds:p_r13+4,edx
;    
    mov dword ptr ds:p_r14,edx
    mov dword ptr ds:p_r14+4,edx
;    
    mov dword ptr ds:p_r15,edx
    mov dword ptr ds:p_r15+4,edx
;    
    mov ds:p_cs,cs
;
; dr0 - dr7
;
    xor edx,edx
    mov dword ptr ds:p_dr0,edx
    mov dword ptr ds:p_dr0+4,edx
    mov dword ptr ds:p_dr1,edx
    mov dword ptr ds:p_dr1+4,edx
    mov dword ptr ds:p_dr2,edx
    mov dword ptr ds:p_dr2+4,edx
    mov dword ptr ds:p_dr3,edx
    mov dword ptr ds:p_dr3+4,edx
    mov dword ptr ds:p_dr7,edx
    mov dword ptr ds:p_dr7+4,edx
;
; 387 status
;
    mov ds:p_math_control,37Fh
    mov ds:p_math_status,0
    mov ds:p_math_tag,0FFFFh
    mov ds:p_math_eip,0
    mov ds:p_math_cs,0
    mov ds:p_math_data_offs,0
    mov ds:p_math_data_sel,0
;
; thread control
;
    mov ds:p_fault_vector,-1
    mov dword ptr ds:p_fault_code,0
    mov dword ptr ds:p_fault_code+4,0
    mov ds:p_action_text,0
    mov ds:p_stack_sel,0
    ret
init_fork_regs    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_FORK_THREAD
;
;           DESCRIPTION:    Init fork thread
;
;           PARAMETERS:     ES          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_fork_thread    PROC near
    push ds
;
    GetThread
    mov ds,ax
    mov si,OFFSET thread_name
    mov di,OFFSET thread_name
    mov cx,30
    rep movsb
;
    dec di

init_fork_space_loop:
    mov al,es:[di]
    cmp al,' '
    jne init_fork_space_ok
;
    dec di
    jmp init_fork_space_loop

init_fork_space_ok:
    inc di
    mov cx,di
    sub cx,OFFSET thread_name
    cmp cx,28
    jb init_fork_add
;
    mov cx,28

init_fork_add:
    mov di,OFFSET thread_name
    add di,cx
    mov al,'@'
    stosb
    mov al,'0'
    stosb
;
    pop ds
    ret
init_fork_thread    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_FORK_STACK
;
;           DESCRIPTION:    Init fork stack
;
;           PARAMETERS:     ES          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_fork_stack Proc near
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    movzx eax,sp
    add ax,2
    mov dword ptr ds:p_rsp,eax
;
    push ds
    push es
;
    mov es,ds:p_kernel_ss
    mov ax,ss
    mov ds,ax
    mov si,sp
    mov di,sp
    mov cx,stack0_size
    sub cx,sp
    shr cx,1
    rep movsw 
;
    pop es
    pop ds
;
    ret
init_fork_stack Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FORK_PROCESS
;
;           DESCRIPTION:    Fork process
;
;           RETURNS:        AX = 0, child process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fork_process_name     DB 'Fork Process',0

fork_start:
    sti
    call trap_create_process
    CloneLdt
    CloneProcHandle
    xor eax,eax
    jmp fork_done

fork_process  PROC far
    push ds
    push es
    push fs
    push gs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;    
    GetThread
    mov fs,ax
;    
    call allocate_thread_block
;    
    mov dx,fs:p_prio
    shr dx,1
    call init_thread_block
;    
    mov eax,es
    mov ds,eax
;    
    call create_tss32
    call init_fork_regs
    NotifyCreateProcess
    mov es:p_cr3,eax
;
    mov bx,fs:p_prog_id
    call create_process_sel
    call add_process_thread
    call copy_process_modules
    call setup_fork
;
    call create_cur_dir
    call create_env_sel
;
    call init_fork_thread
    call init_fork_stack
    call wake_new
    mov ax,es:p_proc_id

fork_done:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop gs
    pop fs
    pop es 
    pop ds   
    retf32
fork_process  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_VIRT_CALLBACK_FRAME
;
;           DESCRIPTION:    Create V86 mode IRETD stack frame
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_virt_callback_frame    PROC near
    pop bp
    xor eax,eax
    push eax
    push eax
    push eax
    push eax
    mov eax,ds:cm_stack
    AllocateDosMem
    mov ax,es
    SelectorToSegment
    push 0
    push ax
;
    mov eax,ds:cm_stack
    push eax
;
    push 2
    mov ax,ds:cm_flags
    or ax,3200h
    and ax,NOT 4000h
    push ax
;
    mov ax,ds:cm_cs
    push eax
;
    mov eax,ds:cm_eip
    push eax
;
    push bp
    ret
init_virt_callback_frame    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROT_CALLBACK_FRAME
;
;           DESCRIPTION:    Create protected mode IRETD stack frame
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_prot_callback_frame    PROC near
    pop bp
;
    mov ax,ds:cm_cs
    test al,3
    jz init_prot_kernel_frame
;
    mov eax,ds:cm_stack
    add eax,100
    AllocateLocalMem
    mov ax,es
    jmp init_prot_create_frame

init_prot_kernel_frame:
    xor eax,eax

init_prot_create_frame:
    push eax
;
    mov eax,ds:cm_stack
    push eax
;
    movzx eax,ds:cm_flags
    or ax,200h
    and ax,NOT 7000h
    push eax
;
    movzx eax,ds:cm_cs
    push eax
;
    mov eax,ds:cm_eip
    push eax
;
    push bp
    ret
init_prot_callback_frame    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_LONG_CALLBACK_FRAME
;
;           DESCRIPTION:    Create long mode IRETD stack frame
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_long_callback_frame    PROC near
    pop bp
    xor eax,eax
    mov eax,ds:cm_stack
    AllocateGlobalMem
;
    push 0
    push es
;
    push eax
;
    push 0
    mov ax,ds:cm_flags
    or ax,200h
    and ax,NOT 7000h
    push ax
;
    mov ax,ds:cm_cs
    push eax
;
    mov eax,ds:cm_eip
    push eax
;
    push bp
    ret
init_long_callback_frame    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_PROCESS_CALLBACK
;
;           DESCRIPTION:    Process startup (in new address space)
;
;           PARAMETERS:         DS          Process data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_process_callback:
    sti
    GetThread
    mov fs,ax
;
    push ds
    call trap_create_process
    pop ds
;
    mov es,ds:cm_process
    mov ax,ds:cm_mode
    or ax,ax
    jz create_callback_prot
;    
    cmp ax,1
    je create_callback_virt
;
    call init_long_callback_frame
    jmp create_callback_frame_done

create_callback_virt:    
    call init_virt_callback_frame
    jmp create_callback_frame_done

create_callback_prot:
    call init_prot_callback_frame
    
create_callback_frame_done:
    mov eax,ds:cm_eax
    mov ebx,ds:cm_ebx
    mov ecx,ds:cm_ecx
    mov edx,ds:cm_edx
    mov esi,ds:cm_esi
    mov edi,ds:cm_edi
    mov ebp,ds:cm_ebp
    push ax
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax
    FreeMem
    pop ax
    iretd

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           create_serv_proc_callback
;
;           DESCRIPTION:    Process startup (in new address space)
;
;           PARAMETERS:     DS          Process data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_serv_proc_callback:
    GetThread
    mov es,ax
    mov es:p_ldt,0
    mov es:p_flat_size,serv_linear
    sti
;
    push ds
    call trap_create_process
    pop ds
;
    CreateSharedLdt
;
    mov es,ds:cm_process
    call init_prot_callback_frame
;
    mov eax,ds:cm_eax
    mov ebx,ds:cm_ebx
    mov ecx,ds:cm_ecx
    mov edx,ds:cm_edx
    mov esi,ds:cm_esi
    mov edi,ds:cm_edi
    mov ebp,ds:cm_ebp
    push ax
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax
    FreeMem
    pop ax
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateFirstThread
;
;           DESCRIPTION:    Create first thread control block
;
;           PARAMETERS:         ES          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

null_name       DB 'Core 00',0

create_first_thread       PROC near
    xor eax,eax
    mov es:p_prio,ax
    mov es:p_msb_tics,eax
    mov es:p_lsb_tics,eax
    mov es:p_deb_phys,eax
    mov es:p_deb_phys+4,eax
    mov es:p_pm_deb_sel,ax
    mov es:p_pm_deb_offs,eax
    mov es:p_prog_id,ax
    mov es:p_prog_sel,ax
    mov es:p_proc_id,ax
    mov es:p_proc_sel,ax
    mov es:p_loader,ax
    mov es:p_console,ax
    mov es:p_parent_console,ax
    mov ds:p_flat_size,flat_size
    mov es:p_ldt_sel,ax
    mov es:p_ldt_obj,ax
    mov es:p_lib_sel,ax
    mov es:p_serv_sel,ax
;
    mov es:p_irq,0
    mov es:p_debug_event,0
    mov es:p_flags,0
    mov es:p_signal_spinlock,0
    mov es:p_wanted_core,0
    mov es:p_signal,0
    mov es:p_wait_list,0
    mov es:p_kill,0
    mov es:p_ref_count,0
    mov es:p_is_waiting,0
;
    mov ax,cs
    mov ds,ax
    mov si,OFFSET null_name
    mov di,OFFSET thread_name
    mov cx,30
first_move_name:
    lodsb
    or al,al
    jz first_move_pad
    stosb
    loop first_move_name
    jmp first_move_done
first_move_pad:
    mov al,' '
    rep stosb
first_move_done:
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0
    push ds
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    pop ds  
    ret
create_first_thread       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_FIRST_TSS
;
;           DESCRIPTION:    Init first TSS
;
;           PARAMETERS:         DS          TSS
;                           ES          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_first_tss  PROC near
    xor edx,edx
;
; dr0 - dr7
;
    mov dword ptr ds:p_dr0,edx
    mov dword ptr ds:p_dr0+4,edx
    mov dword ptr ds:p_dr1,edx
    mov dword ptr ds:p_dr1+4,edx
    mov dword ptr ds:p_dr2,edx
    mov dword ptr ds:p_dr2+4,edx
    mov dword ptr ds:p_dr3,edx
    mov dword ptr ds:p_dr3+4,edx
    mov dword ptr ds:p_dr7,edx
    mov dword ptr ds:p_dr7+4,edx
;
; 387 status
;
    mov ds:p_math_control,37Fh
    mov ds:p_math_status,0
    mov ds:p_math_tag,0FFFFh
    mov ds:p_math_eip,0
    mov ds:p_math_cs,0
    mov ds:p_math_data_offs,0
    mov ds:p_math_data_sel,0
;
; thread control
;
    mov ds:p_fault_vector,-1
    mov dword ptr ds:p_fault_code,0
    mov dword ptr ds:p_fault_code+4,0
    mov ds:p_action_text,0
;
    mov ds:p_cr3,edx
    mov dword ptr ds:p_rax,edx
    mov dword ptr ds:p_rcx,edx
    mov dword ptr ds:p_rdx,edx
    mov dword ptr ds:p_rbx,edx
    mov dword ptr ds:p_rbp,edx
    mov dword ptr ds:p_rsi,edx
    mov dword ptr ds:p_rdi,edx    
    mov ds:p_es,dx
    mov ds:p_ds,dx
    mov ds:p_fs,dx
    mov ds:p_gs,dx
    mov ds:p_ldt,0
;
    mov eax,OFFSET init_first_process_callback
    mov dword ptr ds:p_rip,eax
    mov ds:p_cs,cs
;
    push es
    mov eax,stack0_size
    AllocateSmallGlobalMem
    mov ax,es
    pop es    
    mov ds:p_ss,ax
    mov eax,stack0_size
    mov dword ptr ds:p_rsp,eax
;
    pushfd
    pop eax
    and ax,NOT 7000h
    mov dword ptr ds:p_rflags,eax
    ret
init_first_tss  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_FIRST_PROCESS
;
;           DESCRIPTION:    Init first process (system process)
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_first_process      Proc near
    StartSmpCoreDump
    mov ax,0002h
    push ax
    popf    
;
    mov ax,virt_thread_sel
    mov es,ax
    call allocate_null_thread_block
    mov es:p_active,1
;
    mov ax,es
    mov ds,ax
    call create_initial_tss
;
    call create_first_thread
;
    mov ax,es
    mov ds,ax
    call init_first_tss
    NotifyCreateProcess
    mov es:p_cr3,eax
;
    mov bx,1
    call create_process_sel
;
    mov ds:p_es,0
    GetCore
    mov fs:cs_null_thread,es
    mov es:p_signal_spinlock,0
    mov es:p_wanted_core,0
    mov es:p_core,fs
    mov es:p_sleep_sel,0
;
    mov ds,ds:p_proc_sel
    mov ds:pf_thread_count,1
    mov ds:pf_thread_arr,0
;
    CreateEnvSel
    mov ds:pf_env_sel,ax
;
    CreateProcHandle
;
    ret
init_first_process      Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_FIRST_PROCESS_CALLBACK
;
;           DESCRIPTION:    Startup code of system process
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_first_process_callback:
    NotifyInitProcess
    call start_processor_null_threads
;
    call trap_init_tasking
    sti
    jmp null_thread0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartTasking
;
;           DESCRIPTION:    Start tasikng
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_tasking_name  DB 'Start Tasking', 0

start_tasking:    
    call init_first_process
    jmp init_first_thread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           create_serv_app_callback
;
;           DESCRIPTION:    Process startup (in new address space)
;
;           PARAMETERS:     DS          Process data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_serv_app_callback:
    sti
    push ds
    call trap_create_process
    pop ds
;
    mov es,ds:cm_process
    call init_prot_callback_frame
;
    mov edx,ds:cm_edx
    mov ebx,ds:cm_ebx
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
;
    ExecServer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_serv_app_regs
;
;           DESCRIPTION:    Init server apps regs
;
;           PARAMETERS:     DS          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_serv_app_regs    PROC near
    mov eax,OFFSET create_serv_app_callback
    mov dword ptr ds:p_rip,eax
    mov ds:p_cs,cs
    mov ax,ds:p_kernel_ss
    mov ds:p_ss,ax
    mov eax,stack0_size
    mov dword ptr ds:p_rsp,eax
;
    mov ax,[ebp].cr_flags
    or ax,200h
    and ax,NOT 7000h
    movzx eax,ax
    mov dword ptr ds:p_rflags,eax
;
    xor ax,ax
    mov ds:p_es,ax
    mov ds:p_ds,ax
    mov ds:p_fs,ax
    mov ds:p_gs,ax
    mov ds:p_stack_sel,0
    ret
init_serv_app_regs    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateServerApp
;
;           DESCRIPTION:    Create server app
;
;           PARAMETERS:     BX          Program sel
;                           ES:EDI      Thread name
;                           EDX         Server image header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_serv_app_name DB 'Create Server App', 0

create_serv_app  PROC far
    sub esp,30
    push ebp
    mov ebp,esp
    pushf
    push ds
    push es
    push fs
    push gs
;
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov [ebp].cr_seg,cs
    mov dword ptr [ebp].cr_offs,0
    mov word ptr [ebp].cr_prio,2
    mov dword ptr [ebp].cr_stack,stack0_size
    mov word ptr [ebp].cr_mode,0
    mov dword ptr [ebp].cr_name,edi
    mov [ebp+4].cr_name,es
    xor ax,ax
    mov fs,ax
    mov gs,ax
    call allocate_thread_block
    mov dx,[ebp].cr_prio
    call init_thread_block
    mov es:p_debug_event,0
;
    mov ax,es
    mov ds,ax
;
    call create_tss32
    call init_default_regs
;
    NotifyCreateProcess
    mov es:p_cr3,eax
;
    mov bx,[ebp].cr_ebx
    call create_process_sel
    call add_process_thread
    CreateProcHandle
    call create_cur_dir
    call create_env_sel
    call init_prot_thread
    call init_serv_app_regs
    call init_process_callback
;
    call wake_new
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
;
    pop gs
    pop fs
    pop es
    pop ds
    popf
    pop ebp
    add esp,30
    retf32
create_serv_app  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateCoreDump
;
;           DESCRIPTION:    Create core dump
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCoreDump    Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov ds:core_dump_sel,0
;    
    mov eax,1000h
    AllocateBigLinear
;
    xor ebx,ebx
    mov eax,core_save_phys
    and eax,NOT 0FFFh
    mov al,13h
    SetPageEntry
;
    mov bx,core_save_sel
    mov eax,core_save_phys
    and eax,0FFFh
    add edx,eax
    mov ecx,SIZE save_core_struc
    CreateDataSelector16
    mov ds,bx
    mov eax,ds:sc_sign
    cmp eax,SAVE_CORE_SIGN
    jnz ccdSetup
;
    mov cx,ds:sc_cores
    cmp cx,MAX_SAVE_CORES
    ja ccdSetup
;
    or cx,cx    
    jz ccdSetup    
;    
    mov eax,1000h
    AllocateBigLinear
;
    mov eax,SIZE image_core_struc
    AllocateSmallGlobalMem
    mov bx,core_save_sel
    mov ds,bx
    mov cx,ds:sc_cores
    mov es:ic_cores,cx
    mov si,OFFSET sc_phys
    mov di,OFFSET ic_linear

ccdLoop:
    push es
    push cx
    push di
;    
    push edx
    mov eax,4000h
    AllocateBigLinear
    mov es:[di],edx
    mov edi,edx
    pop edx
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov eax,dword ptr ds:[si].scp_core_phys
    mov ebx,dword ptr ds:[si].scp_core_phys+4
    mov al,13h
    SetPageEntry
;
    push si
    mov esi,edx
    mov ecx,400h
    rep movs dword ptr es:[edi],es:[esi]
    pop si
;    
    mov eax,dword ptr ds:[si].scp_stack_phys
    mov ebx,dword ptr ds:[si].scp_stack_phys+4
    mov al,13h
    SetPageEntry
;
    push si
    mov esi,edx
    mov ecx,400h
    rep movs dword ptr es:[edi],es:[esi]
    pop si
;    
    mov eax,dword ptr ds:[si].scp_log_phys
    mov ebx,dword ptr ds:[si].scp_log_phys+4
    mov al,13h
    SetPageEntry
;
    push si
    mov esi,edx
    mov ecx,400h
    rep movs dword ptr es:[edi],es:[esi]
    pop si
;    
    mov eax,dword ptr ds:[si].scp_log_phys+8
    mov ebx,dword ptr ds:[si].scp_log_phys+12
    mov al,13h
    SetPageEntry
;
    push si
    mov esi,edx
    mov ecx,400h
    rep movs dword ptr es:[edi],es:[esi]
    pop si
;        
    pop di
    pop cx
    pop es
;
    add si,SIZE save_core_phys_struc
    add di,4    
    sub cx,1
    jnz ccdLoop
;    
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
    mov ecx,1000h
    FreeLinear
;       
    mov ax,system_data_sel
    mov ds,ax
    mov ds:core_dump_sel,es

ccdSetup:
    mov bx,core_save_sel
    mov ds,bx
    mov ds:sc_sign,0
    mov ds:sc_cores,0            
;
    mov eax,SIZE image_core_struc
    mov bx,core_image_sel
    AllocateFixedSystemMem
    mov es:ic_cores,0        
    ret
CreateCoreDump  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasCrashInfo
;
;           DESCRIPTION:    Check for crash info
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_crash_info_name    DB 'Has Crash Info',0

has_crash_info    Proc far
    push ds
    push ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov ax,ds:core_dump_sel
    or ax,ax
    stc
    jz hciDone
;
    clc    

hciDone:   
    pop ax
    pop ds 
    retf32
has_crash_info    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCrashCoreInfo
;
;           DESCRIPTION:    Get crash info for core
;
;           PARAMETERS:     AX      Core #
;                           ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_crash_core_name    DB 'Get Crash Core Info',0

get_crash_core    Proc near
    push ds
    push eax
    push ecx
    push esi
    push edi
;
    mov si,system_data_sel
    mov ds,si
    mov si,ds:core_dump_sel
    or si,si
    jz gcciFail
;
    mov ds,si
    cmp ax,ds:ic_cores
    jae gcciFail
;
    mov si,ax
    shl si,2
    mov esi,ds:[si].ic_linear
    mov ax,flat_sel
    mov ds,ax
;
    mov eax,ds:[esi].cls_sign
    cmp eax,LOG_CORE_SIGN
    jne gcciFail
;    
    mov ecx,1000h
    rep movs dword ptr es:[edi],ds:[esi]    
    clc    
    jmp gcciDone

gcciFail:
    stc

gcciDone:   
    pop edi
    pop esi
    pop ecx
    pop eax
    pop ds 
    ret
get_crash_core    Endp

get_crash_core16:
    push edi
    movzx edi,di
    call get_crash_core
    pop edi
    retf32

get_crash_core32:
    call get_crash_core
    retf32


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

terminate_user_start:
    TerminateThread
terminate_user_end:

init       PROC far
    pusha
    push ds
;
    mov eax,OFFSET terminate_user_end - OFFSET terminate_user_start
    AllocateSmallLinear
    mov bx,term_code_sel
    mov ecx,eax
    CreateDataSelector16
;
    mov es,bx
    xor di,di
    mov ax,cs
    mov ds,ax
    mov si,OFFSET terminate_user_start
    mov cx,OFFSET terminate_user_end - OFFSET terminate_user_start
    rep movsb
    and bx,0FFF8h
    mov ax,gdt_sel
    mov ds,ax
    mov byte ptr [bx+5],0FAh
;    
    mov ax,SEG data
    mov ds,ax
    mov ds:term_thread_list,0
    mov ds:term_proc_list,0
    mov ds:list_lock,0
    mov ds:wait_dev_pos,0
;       
    mov cx,WAIT_DEV_COUNT
    xor bx,bx

wait_dev_init:
    mov ds:[bx].wd_lock,0
    mov ds:[bx].wd_thread,-1
    add bx,4
    loop wait_dev_init
;
    InitSection ds:futex_section
    mov ds:timer_spinlock,0
    mov bx,OFFSET timer_entries
    mov ds:[bx].timer_next,0
    mov ds:[bx].timer_msb,0FFFFFFFFh
    mov ds:[bx].timer_lsb,0FFFFFFFFh
    mov ds:timer_head,bx
;       
    mov cx,0FFh
    add bx,SIZE timer_struc
    mov ds:timer_free,bx
timer_free_list_create:
    mov ax,bx
    add ax,SIZE timer_struc
    mov ds:[bx].timer_next,ax
    mov bx,ax
    loop timer_free_list_create
;
    mov bx,cs
    GetSelectorBaseSize
    AllocateGdt
    CreateDataSelector32
    mov ds:patch_sel,bx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov edi,OFFSET delete_thread_block_handle
    mov ax,BLOCK_HANDLE
    RegisterHandle
;
    mov esi,OFFSET start_tasking
    mov edi,OFFSET start_tasking_name
    xor cl,cl
    mov ax,start_tasking_nr
    RegisterOsGate
;
    mov esi,OFFSET init_process
    mov edi,OFFSET init_process_name
    xor cl,cl
    mov ax,init_process_nr
    RegisterOsGate
;
    mov esi,OFFSET create_core
    mov edi,OFFSET create_core_name
    xor cl,cl
    mov ax,create_core_nr
    RegisterOsGate
;
    mov esi,OFFSET get_core
    mov edi,OFFSET get_core_name
    xor cl,cl
    mov ax,get_core_nr
    RegisterOsGate
;
    mov esi,OFFSET get_core_count
    mov edi,OFFSET get_core_count_name
    xor cl,cl
    mov ax,get_core_count_nr
    RegisterOsGate
;
    mov esi,OFFSET get_core_num
    mov edi,OFFSET get_core_num_name
    xor cl,cl
    mov ax,get_core_num_nr
    RegisterOsGate
;
    mov esi,OFFSET run_ap_core
    mov edi,OFFSET run_ap_core_name
    xor cl,cl
    mov ax,run_ap_core_nr
    RegisterOsGate
;
    mov esi,OFFSET get_flat_size
    mov edi,OFFSET get_flat_size_name
    xor cl,cl
    mov ax,get_flat_size_nr
    RegisterOsGate
;
    mov esi,OFFSET use_own_preempt_timer
    mov edi,OFFSET use_own_preempt_timer_name
    xor cl,cl
    mov ax,use_own_preempt_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET preempt_expired
    mov edi,OFFSET preempt_expired_name
    xor cl,cl
    mov ax,preempt_expired_nr
    RegisterOsGate
;
    mov esi,OFFSET timer_expired
    mov edi,OFFSET timer_expired_name
    xor cl,cl
    mov ax,timer_expired_nr
    RegisterOsGate
;
    mov esi,OFFSET flush_tlb
    mov edi,OFFSET flush_tlb_name
    xor cl,cl
    mov ax,flush_tlb_nr
    RegisterOsGate
;
    mov esi,OFFSET irq_schedule
    mov edi,OFFSET irq_schedule_name
    xor cl,cl
    mov ax,irq_schedule_nr
    RegisterOsGate
;
    mov esi,OFFSET get_scheduler_lock_counter
    mov edi,OFFSET get_scheduler_lock_counter_name
    xor cl,cl
    mov ax,get_scheduler_lock_counter_nr
    RegisterOsGate
;
    mov esi,OFFSET try_lock_task
    mov edi,OFFSET try_lock_task_name
    xor cl,cl
    mov ax,try_lock_task_nr
    RegisterOsGate
;
    mov esi,OFFSET lock_task
    mov edi,OFFSET lock_task_name
    xor cl,cl
    mov ax,lock_task_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_task
    mov edi,OFFSET unlock_task_name
    xor cl,cl
    mov ax,unlock_task_nr
    RegisterOsGate
;
    mov esi,OFFSET set_futex_id
    mov edi,OFFSET set_futex_id_name
    xor cl,cl
    mov ax,set_futex_id_nr
    RegisterOsGate
;
    mov esi,OFFSET enter_long_int
    mov edi,OFFSET enter_long_int_name
    xor cl,cl
    mov ax,enter_long_int_nr
    RegisterOsGate
;
    mov esi,OFFSET leave_long_int
    mov edi,OFFSET leave_long_int_name
    xor cl,cl
    mov ax,leave_long_int_nr
    RegisterOsGate
;
    mov esi,OFFSET set_thread_core
    mov edi,OFFSET set_thread_core_name
    xor cl,cl
    mov ax,set_thread_core_nr
    RegisterOsGate
;
    mov esi,OFFSET debug_block
    mov edi,OFFSET debug_block_name
    xor cl,cl
    mov ax,debug_block_nr
    RegisterOsGate
;
    mov esi,OFFSET debug_realtime
    mov edi,OFFSET debug_realtime_name
    xor cl,cl
    mov ax,debug_realtime_nr
    RegisterOsGate
;
    mov esi,OFFSET run_realtime
    mov edi,OFFSET run_realtime_name
    xor cl,cl
    mov ax,run_realtime_nr
    RegisterOsGate
;
    mov esi,OFFSET wake_thread
    mov edi,OFFSET wake_thread_name
    xor cl,cl
    mov ax,wake_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET sleep_thread
    mov edi,OFFSET sleep_thread_name
    xor cl,cl
    mov ax,sleep_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET clear_signal
    mov edi,OFFSET clear_signal_name
    xor cl,cl
    mov ax,clear_signal_nr
    RegisterOsGate
;
    mov esi,OFFSET signal_thread
    mov edi,OFFSET signal_thread_name
    xor cl,cl
    mov ax,signal_nr
    RegisterOsGate
;
    mov esi,OFFSET wait_for_signal
    mov edi,OFFSET wait_for_signal_name
    xor cl,cl
    mov ax,wait_for_signal_nr
    RegisterOsGate
;
    mov esi,OFFSET wait_for_signal_timeout
    mov edi,OFFSET wait_for_signal_timeout_name
    xor cl,cl
    mov ax,wait_for_signal_timeout_nr
    RegisterOsGate
;
    mov esi,OFFSET create_wait_dev
    mov edi,OFFSET create_wait_dev_name
    xor cl,cl
    mov ax,create_wait_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET close_wait_dev
    mov edi,OFFSET close_wait_dev_name
    xor cl,cl
    mov ax,close_wait_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET prepare_wait_dev
    mov edi,OFFSET prepare_wait_dev_name
    xor cl,cl
    mov ax,prepare_wait_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET wait_for_dev
    mov edi,OFFSET wait_for_dev_name
    xor cl,cl
    mov ax,wait_for_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET signal_wait_dev
    mov edi,OFFSET signal_wait_dev_name
    xor cl,cl
    mov ax,signal_wait_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET fpu_exception
    mov edi,OFFSET fpu_exception_name
    xor cl,cl
    mov ax,fpu_exception_nr
    RegisterOsGate
;
    mov esi,OFFSET do_flush_tlb
    mov edi,OFFSET do_flush_tlb_name
    xor cl,cl
    mov ax,do_flush_tlb_nr
    RegisterOsGate
;
    mov esi,OFFSET soft_reset
    mov edi,OFFSET soft_reset_name
    xor dx,dx
    mov ax,fault_reset_nr
    RegisterOsGate
;
    mov ebx,OFFSET create_thread16
    mov esi,OFFSET create_thread32
    mov edi,OFFSET create_thread_name
    mov dx,virt_es_in
    mov ax,create_thread_nr
    RegisterUserGate
;
    mov esi,OFFSET terminate_thread
    mov edi,OFFSET terminate_thread_name
    xor dx,dx
    mov ax,terminate_thread_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_timer_thread
    mov edi,OFFSET create_timer_thread_name
    xor dx,dx
    mov ax,create_timer_thread_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_process
    mov edi,OFFSET create_process_name
    xor cl,cl
    mov ax,create_process_nr
    RegisterOsGate
;
    mov esi,OFFSET create_serv_proc
    mov edi,OFFSET create_serv_proc_name
    xor cl,cl
    mov ax,create_serv_proc_nr
    RegisterOsGate
;
    mov esi,OFFSET create_serv_app
    mov edi,OFFSET create_serv_app_name
    xor cl,cl
    mov ax,create_serv_app_nr
    RegisterOsGate
;
    mov esi,OFFSET fork_process
    mov edi,OFFSET fork_process_name
    xor cl,cl
    mov ax,fork_process_nr
    RegisterOsGate
;
    mov esi,OFFSET soft_reset
    mov edi,OFFSET soft_reset_name
    xor dx,dx
    mov ax,soft_reset_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET hard_reset
    mov edi,OFFSET hard_reset_name
    xor dx,dx
    mov ax,hard_reset_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET power_failure
    mov edi,OFFSET power_failure_name
    xor dx,dx
    mov ax,power_failure_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_thread_pr
    mov edi,OFFSET get_thread_name
    xor dx,dx
    mov ax,get_thread_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_core_id
    mov edi,OFFSET get_core_id_name
    xor dx,dx
    mov ax,get_core_id_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_cpu_time
    mov edi,OFFSET get_cpu_time_name
    xor dx,dx
    mov ax,get_cpu_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_milli_sec
    mov edi,OFFSET wait_milli_name
    xor dx,dx
    mov ax,wait_milli_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_micro_sec
    mov edi,OFFSET wait_micro_name
    xor dx,dx
    mov ax,wait_micro_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_until
    mov edi,OFFSET wait_until_name
    xor dx,dx
    mov ax,wait_until_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET notify_time_drift
    mov edi,OFFSET notify_time_drift_name
    xor cl,cl
    mov ax,notify_time_drift_nr
    RegisterOsGate
;
    mov esi,OFFSET get_time
    mov edi,OFFSET get_time_name
    xor dx,dx
    mov ax,get_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET time_to_system_time
    mov edi,OFFSET time_to_system_time_name
    xor dx,dx
    mov ax,time_to_system_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET system_time_to_time
    mov edi,OFFSET system_time_to_time_name
    xor dx,dx
    mov ax,system_time_to_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_core_load
    mov edi,OFFSET get_core_load_name
    xor dx,dx
    mov ax,get_core_load_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_core_duty
    mov edi,OFFSET get_core_duty_name
    xor dx,dx
    mov ax,get_core_duty_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET debug_exc_break
    mov edi,OFFSET debug_exc_break_name
    xor cl,cl
    mov ax,debug_exc_break_nr
    RegisterOsGate
;
    mov esi,OFFSET enter_section
    mov edi,OFFSET enter_section_name
    xor cl,cl
    mov ax,enter_section_nr
    RegisterOsGate
;
    mov esi,OFFSET leave_section
    mov edi,OFFSET leave_section_name
    xor cl,cl
    mov ax,leave_section_nr
    RegisterOsGate
;
    mov esi,OFFSET cond_enter_section
    mov edi,OFFSET cond_enter_section_name
    xor cl,cl
    mov ax,cond_enter_section_nr
    RegisterOsGate
;
    mov esi,OFFSET is_long_thread
    mov edi,OFFSET is_long_thread_name
    xor cl,cl
    mov ax,is_long_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET create_user_section
    mov edi,OFFSET create_user_section_name
    xor dx,dx
    mov ax,create_user_section_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_named_user_section
    mov edi,OFFSET create_named_user_section_name
    xor dx,dx
    mov ax,create_named_user_section_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_blocked_user_section
    mov edi,OFFSET create_blocked_user_section_name
    xor dx,dx
    mov ax,create_blocked_user_section_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET delete_user_section
    mov edi,OFFSET delete_user_section_name
    xor dx,dx
    mov ax,delete_user_section_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET enter_user_section
    mov edi,OFFSET enter_user_section_name
    xor dx,dx
    mov ax,enter_user_section_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET leave_user_section
    mov edi,OFFSET leave_user_section_name
    xor dx,dx
    mov ax,leave_user_section_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET create_thread_block16
    mov esi,OFFSET create_thread_block32
    mov edi,OFFSET create_thread_block_name
    mov dx,virt_es_in
    mov ax,create_thread_block_nr
    RegisterUserGate
;
    mov esi,OFFSET wait_thread_block
    mov edi,OFFSET wait_thread_block_name
    xor dx,dx
    mov ax,wait_thread_block_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_thread_block
    mov edi,OFFSET close_thread_block_name
    xor dx,dx
    mov ax,close_thread_block_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET update_time
    mov edi,OFFSET update_time_name
    xor cl,cl
    mov ax,update_time_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET acquire_futex16
    mov esi,OFFSET acquire_futex32
    mov edi,OFFSET acquire_futex_name
    mov dx,virt_es_in
    mov ax,acquire_futex_nr
    RegisterUserGate
;
    mov ebx,OFFSET acquire_named_futex16
    mov esi,OFFSET acquire_named_futex32
    mov edi,OFFSET acquire_named_futex_name
    mov dx,virt_es_in
    mov ax,acquire_named_futex_nr
    RegisterUserGate
;
    mov ebx,OFFSET release_futex16
    mov esi,OFFSET release_futex32
    mov edi,OFFSET release_futex_name
    mov dx,virt_es_in
    mov ax,release_futex_nr
    RegisterUserGate
;
    mov ebx,OFFSET cleanup_futex16
    mov esi,OFFSET cleanup_futex32
    mov edi,OFFSET cleanup_futex_name
    mov dx,virt_es_in
    mov ax,cleanup_futex_nr
    RegisterUserGate
;
    mov ebx,OFFSET set_thread_action16
    mov esi,OFFSET set_thread_action32
    mov edi,OFFSET set_thread_action_name
    mov dx,virt_es_in
    mov ax,set_thread_action_nr
    RegisterUserGate
;
    mov esi,OFFSET has_crash_info
    mov edi,OFFSET has_crash_info_name
    xor cl,cl
    mov ax,has_crash_info_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_crash_core16
    mov esi,OFFSET get_crash_core32
    mov edi,OFFSET get_crash_core_name
    mov dx,virt_es_in
    mov ax,get_crash_core_info_nr
    RegisterUserGate
;
    mov edi,OFFSET check_list
    HookState
;
    call CreateCoreDump
;
    mov eax,4000h
    AllocateBigLinear
    mov edi,edx    
    mov ax,flat_sel
    mov es,ax
    mov cx,1000h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov ax,core_data_sel
    mov ds,ax
    mov edi,gdt_core_linear
    mov ecx,SIZE core_seg
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov edi,gdt_core_linear
    xor esi,esi
    mov ecx,SIZE core_base_struc
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov edx,gdt_core_linear
    mov bx,core_data_sel
    mov ecx,SIZE core_seg
    CreateDataSelector16
;
    AllocateGdt
    mov edx,gdt_core_linear
    mov ecx,SIZE core_seg
    CreateDataSelector16
;
    mov es,bx
    mov es:cs_sel,es
    mov es:cs_processor,0
;
    call InitCore
    or es:cs_flags,CS_FLAG_ACTIVE
;
    pop ds
    popa
    ret
init       ENDP

code    ENDS

    END init

