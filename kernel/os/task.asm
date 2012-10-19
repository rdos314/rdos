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
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE proc.inc
INCLUDE ..\handle.inc
INCLUDE ..\apicheck.inc
include ..\wait.inc


MSR_SYSENTER_CS  = 174h
MSR_SYSENTER_ESP = 175h
MSR_SYSENTER_EIP = 176h

MAX_CORES   = 64

TLB_FIXED_SIZE          = 64
MAX_TLB_PHYS_ENTRIES    = 10
;TLB_LINEAR_SIZE         = 10000h
TLB_LINEAR_SIZE         = 100000h

SLEEP_SEL_WAIT  = 1
SLEEP_SEL_SIGNAL = 2

DEFAULT_GLOBAL  = 25        ; 25% of wakeup-entries are put into global ready-queue

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

tlb_struc   STRUC

th_next             DD ?

th_remain_cores     DW ?

th_core_bits        DW (MAX_CORES SHR 4) DUP(?)

th_linear           DD ?
th_page_count       DW ?
th_phys_count       DW ?

th_spare            DW ?

th_phys_arr         DD MAX_TLB_PHYS_ENTRIES DUP(?)

tlb_struc   ENDS

task_seg    STRUC

global_ptab         DW 256 DUP(?)
global_prio_act     DW ?

global_spinlock     DW ?

term_thread_list    DW ?
term_proc_list      DW ?

list_lock           DW ?

tlb_spinlock        DW ?
tlb_list            DD ?
 
sys_lsb_tics_base   DD ?
sys_msb_tics_base   DD ?

tlb_block_spinlock  DW ?
tlb_block_list      DD ?
tlb_curr_linear     DD ?
tlb_remain_linear   DD ?

futex_section       section_typ <>

timer_spinlock      DW ?
timer_head          DW ?
timer_free          DW ?
timer_entries       DB 256 * SIZE timer_struc DUP(?)

task_seg    ENDS

proc_handle_seg     STRUC

ph_base handle_header <>

ph_lib_sel          DW ?
ph_proc_sel         DW ?

proc_handle_seg     ENDS

proc_end_wait_header    STRUC

pew_obj             wait_obj_header <>
pew_proc_sel        DW ?

proc_end_wait_header    ENDS

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

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn SetupMpPatch:near

    extrn free_handle_process:near

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

lock_cli_thread_proc        DW OFFSET LockCliThreadSingle
unlock_cli_thread_proc      DW OFFSET UnlockCliThreadSingle

lock_sti_thread_proc        DW OFFSET LockStiThreadSingle
unlock_sti_thread_proc      DW OFFSET UnlockStiThreadSingle
access_sti_thread_proc      DW OFFSET AccessStiThreadSingle

lock_ready_proc             DW OFFSET LockReadySingle
unlock_ready_proc           DW OFFSET UnlockReadySingle

lock_kernel_section_proc    DW OFFSET LockKernelSectionSingle
unlock_kernel_section_proc  DW OFFSET UnlockKernelSectionSingle

lock_user_section_proc      DW OFFSET LockUserSectionSingle
unlock_user_section_proc    DW OFFSET UnlockUserSectionSingle

lock_futex_proc             DW OFFSET LockFutexSingle
unlock_futex_proc           DW OFFSET UnlockFutexSingle

flush_tlb_proc              DW OFFSET FlushTlb386

preempt_reload_proc         DW OFFSET TimerPreemptReload

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
    mov ax,fs:ps_timer_spinlock
    or ax,ax
    je lticGet
;
    sti
    pause
    jmp lticSpinLock

lticGet:
    cli
    inc ax
    xchg ax,fs:ps_timer_spinlock
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
    mov fs:ps_timer_spinlock,0
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
    mov bx,fs:ps_timer_head
    mov ax,fs:[bx].timer_next
    mov fs:ps_timer_head,ax
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
    mov ax,fs:ps_timer_free
    mov fs:[bx].timer_next,ax
    mov fs:ps_timer_free,bx
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
    mov cx,kernel_patch_sel
    mov es,cx    
;
    sub es:time_diff,eax
    sbb es:time_diff,0

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
    mov bx,es
    test word ptr es:p_tss_eflags+2,2
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
    mov bx,es
    test word ptr es:p_tss_eflags+2,2
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
;           NAME:           LOCAL_GET_DEBUG_THREAD_SEL
;
;           DESCRIPTION:    Get currently debugged thread selector
;
;           PARAMETERS:         AX          DEBUG THREAD OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_debug_thread_sel    PROC near
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
local_get_debug_thread_sel    ENDP

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
    call local_get_debug_thread_sel
    retf32
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
    call local_get_debug_thread_sel
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
    call local_get_debug_thread_sel
    or ax,ax
    jz debug_trace_done
    mov bx,ax
    mov es,bx
    mov dx,es:p_tss_cs
    mov esi,es:p_tss_eip
    call ReadWord
    push ax
    add esi,2
    call ReadWord
    mov dx,ax
    pop ax  
    cmp al,0CDh
    jne debug_trace_trace
;
    test word ptr es:p_tss_eflags+2,2
    jz debug_trace_trace
    and word ptr es:p_tss_eflags+2,NOT 2
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
    or word ptr es:p_tss_eflags+2,2
    mov bx,es
    mov dx,es:p_tss_ss
    movzx esi,word ptr es:p_tss_esp
    sub esi,6
    pop ax
    pop cx
    xchg ax,word ptr es:p_tss_eip
    xchg cx,es:p_tss_cs
    add ax,2
    call WriteWord
    mov ax,cx
    add esi,2
    call WriteWord
    mov ax,word ptr es:p_tss_eflags
    add esi,2
    call WriteWord
    sub es:p_tss_esp,6
    jmp debug_trace_done
debug_trace_trace:
    mov eax,es:p_tss_dr7
    and ax,0FFFCh
    mov es:p_tss_dr7,eax
    mov bx,es
    mov ax,word ptr es:p_tss_eflags
    or ax,100h
    mov word ptr es:p_tss_eflags,ax
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
    mov eax,ds:p_tss_dr0
    mov dr0,eax
    mov eax,ds:p_tss_dr1
    mov dr1,eax
    mov eax,ds:p_tss_dr2
    mov dr2,eax
    mov eax,ds:p_tss_dr3
    mov dr3,eax
    mov eax,ds:p_tss_dr7
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
;    
    call local_get_debug_thread_sel
    or ax,ax
    jz debug_pace_done
;
    mov bx,ax
    mov es,bx
;
    xor cl,cl
    mov bx,es:p_tss_cs
    test byte ptr es:p_tss_eflags+2,2
    jnz debug_pace_bitness_done
;
    test bx,4
    jz debug_pace_bitness_gdt

debug_pace_bitness_ldt:
    mov ds,es:p_ldt_sel
    jmp debug_pace_bitness_get

debug_pace_bitness_gdt:
    mov ax,gdt_sel
    mov ds,ax

debug_pace_bitness_get:
    and bx,0FFF8h
    mov cl,ds:[bx+6]
    shr cl,6
    and cl,1

debug_pace_bitness_done:
    mov dx,es:p_tss_cs
    mov esi,es:p_tss_eip
    call ReadWord
;    
    xor ebx,ebx
    add bx,2
    cmp al,0E2h
    je debug_pace_step
;
    cmp al,0CDh
    je debug_pace_step
;    
    inc bx
    test cl,1
    jz debug_pace_size_ok
;
    add bx,2

debug_pace_size_ok:    
    cmp al,0E8h
    je debug_pace_step
;
    xor ebx,ebx

debug_pace_far_loop:
    mov esi,es:p_tss_eip
    add esi,ebx
    call ReadWord
    cmp al,66h
    je debug_pace_far_ov66
;   
    cmp al,67h
    je debug_pace_far_ov67 
;
    cmp al,9Ah
    je debug_pace_far_call
;
    jmp debug_pace_trace   

debug_pace_far_ov66:
    inc bx
    xor cl,1
    jmp debug_pace_far_loop

debug_pace_far_ov67:
    inc bx
    jmp debug_pace_far_loop

debug_pace_far_call:
    add bx,5
    test cl,1
    jz debug_pace_step
;
    add bx,2
    
debug_pace_step:
    mov ax,word ptr es:p_tss_eflags+2
    test ax,2
    jz debug_pace_step_prot    
;
    xor eax,eax
    xor edx,edx
    mov ax,es:p_tss_cs
    shl eax,4
    mov dx,word ptr es:p_tss_eip
    add eax,edx
    jmp debug_pace_step_do
    
debug_pace_step_prot:
    mov si,es:p_tss_cs
    test si,4
    jz debug_pace_step_gdt
;
    xor eax,eax
    mov ds,es:p_ldt_sel
    mov si,es:p_tss_cs
    and si,0FFF8h
    mov eax,[si+2]
    rol eax,8
    mov al,[si+7]
    ror eax,8
    add eax,es:p_tss_eip
    jmp debug_pace_step_do

debug_pace_step_gdt:
    and si,0FFF8h
    mov ax,gdt_sel
    mov ds,ax    
    mov eax,[si+2]
    rol eax,8
    mov al,[si+7]
    ror eax,8
    add eax,es:p_tss_eip

debug_pace_step_do:
    add eax,ebx
    mov es:p_tss_dr0,eax
    mov eax,es:p_tss_dr7
    and eax,0FFF0FFFCh
    or ax,1
    mov es:p_tss_dr7,eax
    mov ax,word ptr es:p_tss_eflags
    and ax,NOT 100h
    mov word ptr es:p_tss_eflags,ax
    jmp debug_pace_do
    
debug_pace_trace:
    mov eax,es:p_tss_dr7
    and ax,0FFFCh
    mov es:p_tss_dr7,eax
    mov ax,word ptr es:p_tss_eflags
    or ax,100h
    mov word ptr es:p_tss_eflags,ax

debug_pace_do:
    mov bx,es
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
    call local_get_debug_thread_sel
    or ax,ax
    jz debug_go_done
    mov bx,ax
    mov es,bx
    mov eax,es:p_tss_dr7
    and ax,0FFFCh
    mov es:p_tss_dr7,eax
    mov ax,word ptr es:p_tss_eflags
    and ax,NOT 100h
    mov word ptr es:p_tss_eflags,ax
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
;           NAME:           DebugRun
;
;           DESCRIPTION:    Run currently debugged thread with current DR-settings
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_run_name   DB 'Debug Run',0

debug_run    PROC far
    push ds
    push es
    pushad
    call local_get_debug_thread_sel
    or ax,ax
    jz debug_run_done
;
    mov bx,ax
    mov es,bx
;
    mov ax,word ptr es:p_tss_eflags
    and ax,NOT 100h
    mov word ptr es:p_tss_eflags,ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake

debug_run_done:
    popad
    pop es
    pop ds
    retf32
debug_run    ENDP


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
;           PARAMETERS:     SI:(E)DI        Address
;
;           RETURNS:        EDX             Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BreakToLinear PROC near
    push bx
    push ecx
;
    mov bx,si
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
    push bx
    push cx
    push edx
    push esi
;
    cmp al,4
    jae abFail
;   
    mov ch,1
    mov esi,edx

abFixSizeLoop:
    test esi,1
    jnz abFixSizeFix
;
    cmp ch,cl
    jae abFixSizeOk
;
    shl ch,1
    shr esi,1
    jmp abFixSizeLoop

abFixSizeFix:
    mov cl,ch

abFixSizeOk:
    movzx bx,al
    shl bx,2 
    add bx,OFFSET p_tss_dr0
    mov es:[bx],edx
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
    and es:p_tss_dr7,esi
    or es:p_tss_dr7,edx
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
    push cx
    push edx
;
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
    and es:p_tss_dr7,edx
    clc
    jmp rbDone

rbFail:
    stc

rbDone:   
    pop edx
    pop cx
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
;                           SI:(E)DI        Address
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
    retf32
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
;                           SI:(E)DI        Address
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
    retf32
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
;                           SI:(E)DI        Address
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
    retf32
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
;           NAME:           HandleGlobal
;
;           DESCRIPTION:    Handle global list
;
;           PARAMETERS:     DS      Task sel
;                           FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGlobal    Proc near
    mov si,ds:global_prio_act
    cmp si,fs:ps_prio_act
    jbe hgDone
;
    test fs:ps_flags,PS_FLAG_MOVE
    jz hgTake
;
    lock and fs:ps_flags,NOT PS_FLAG_MOVE
    jmp hgDone

hgTake:
    call cs:lock_ready_proc
    mov si,ds:global_prio_act
    cmp si,fs:ps_prio_act
    ja hgRemove
;
    call cs:unlock_ready_proc
    jmp hgDone    

hgRemove:
    call RemoveBlock
;
    mov ax,[si]
    or ax,ax
    jnz hgUnlock

hgPrioLoop:
    or si,si
    jz hgSavePrio
;    
    sub si,2
    mov ax,[si]
    or ax,ax
    jz hgPrioLoop

hgSavePrio:
    mov ds:global_prio_act,si

hgUnlock:
    call cs:unlock_ready_proc
;
    mov di,es:p_prio
    call InsertCoreBlock
    mov fs:ps_prio_act,di

hgDone:    
    ret
HandleGlobal   Endp
    
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
    test fs:ps_flags,PS_FLAG_PREEMPT
    jz hpDone
;
    mov si,fs:ps_prio_act
    mov ax,fs:[si]
    or ax,ax
    jz hpDone
;       
    cmp ax,fs:ps_last_thread
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
    mov si,fs:ps_prio_act
    mov ax,fs:[si]
    or ax,ax
    jnz hpqInt
;
    or si,si
    jz hpqDone
;
    sub si,2
    mov fs:ps_prio_act,si
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
    mov ax,es
    mov si,fs:ps_prio_act
    call RemoveCoreBlock          
;    
    call cs:lock_list_proc
    push ds  
    mov ds,ax
    mov di,OFFSET ms_wait_sti
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
    mov si,fs:ps_prio_act
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
    mov fs:ps_prio_act,si
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
;           PARAMETERS:     FS      Core selector
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
    GetSystemTime
    mov ecx,eax
    add eax,1193
    adc edx,0
    mov fs:ps_preempt_lsb,eax
    mov fs:ps_preempt_msb,edx

spDone:
    lock and fs:ps_flags,NOT PS_FLAG_PREEMPT
    ret
SetupPreempt    Endp
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetNextThread
;
;           DESCRIPTION:    Get next thread to run
;
;           PARAMETERS:     FS      Core selector
;                           DS      Task sel
;
;       RETURNS:    ES      Thread to run next
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetNextThread    Proc near
    sti
    lock and fs:ps_flags,NOT PS_FLAG_PRIO_CHANGE
;
    call HandleGlobal
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
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov eax,ds
    push eax
;
    mov eax,[ebp].trap_eflags
    or eax,10100h
    mov [ebp].trap_eflags,eax
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
    test ds:p_tss_eflags,20000h
    jnz acVm
;
    test ds:p_tss_cs,3
    jnz acPm

acKernel:
    mov si,ss
    mov edi,esp
;    
    mov dx,ds:p_tss_ss
    mov ss,dx
    mov esp,ds:p_tss_esp
;
    xor dx,dx
    push ds:p_tss_eflags
    push dx
    push ds:p_tss_cs
    push ds:p_tss_eip
;
    mov ds:p_tss_ss,ss
    mov ds:p_tss_esp,esp
    mov ss,si
    mov esp,edi
    jmp acDone

acPm:
    mov si,ss
    mov edi,esp
;    
    mov dx,ds:p_tss_ess0
    mov ss,dx
    mov esp,ds:p_tss_esp0
;
    xor dx,dx
    push dx
    push ds:p_tss_ss
    push ds:p_tss_esp
    push ds:p_tss_eflags
    push dx
    push ds:p_tss_cs
    push ds:p_tss_eip
;
    mov ds:p_tss_ss,ss
    mov ds:p_tss_esp,esp
    mov ss,si
    mov esp,edi
    jmp acDone

acVm:
    mov si,ss
    mov edi,esp
;    
    mov dx,ds:p_tss_ess0
    mov ss,dx
    mov esp,ds:p_tss_esp0
;
    xor dx,dx
    push dx
    push ds:p_tss_gs
    push dx
    push ds:p_tss_fs
    push dx
    push ds:p_tss_ds
    push dx
    push ds:p_tss_es
    push dx
    push ds:p_tss_ss
    push ds:p_tss_esp
    push ds:p_tss_eflags
    push dx
    push ds:p_tss_cs
    push ds:p_tss_eip
;
    mov ds:p_tss_ss,ss
    mov ds:p_tss_esp,esp
    and ds:p_tss_eflags,NOT 20000h
    mov ss,si
    mov esp,edi

acDone:   
    mov ds:p_tss_cs,cs
    movzx ebx,bx
    mov ds:p_tss_eip,ebx
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
    lock and fs:ps_flags,NOT PS_FLAG_TIMER   
    GetSystemTime
;
    call LockTimerCore
    mov fs:ps_last_lsb,eax
    add eax,cs:update_tics
    adc edx,0
    mov bx,fs:ps_timer_head
    mov ecx,fs:ps_preempt_msb
    cmp ecx,fs:[bx].timer_msb
    jc preempt_reload_check_preempt
;
    jnz preempt_reload_check_timer
;       
    mov ecx,fs:ps_preempt_lsb
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
    sub eax,fs:ps_preempt_lsb
    sbb edx,fs:ps_preempt_msb
    jc preempt_reload_timer
;       
    call UnlockTimerCore
    lock or fs:ps_flags,PS_FLAG_PREEMPT
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
    mov fs:ps_last_lsb,eax
    sub eax,fs:ps_preempt_lsb
    sbb edx,fs:ps_preempt_msb
    jc preempt_reload_ok
;       
    lock or fs:ps_flags,PS_FLAG_PREEMPT
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
    NotifyThreadCreated
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
    test fs:ps_flags,PS_FLAG_P_STATE
    jz load_thread_loop
;    
    lock and fs:ps_flags,NOT PS_FLAG_P_STATE
    UpdatePState

load_thread_loop:
    mov ax,task_sel
    mov ds,ax
    xor ax,ax
    mov es,ax
;
    xor al,al
    xchg al,fs:ps_tlb_flush
    or al,al
    jz load_thread_tlb_flush_ok
;
    mov ax,flat_sel
    mov es,ax
    stc
    call UpdateTlbList    

load_thread_tlb_flush_ok:

load_thread_wakeup_loop:    
    cli
    mov si,OFFSET ps_wakeup_list
    mov ax,fs:[si]
    or ax,ax
    jz load_thread_wakeup_done
;
    call RemoveCoreBlock
    sti
    call cs:access_sti_thread_proc
;
    mov di,es:p_prio
    or di,di
    jz load_wakeup_local_do
;    
    mov al,fs:ps_curr_post
    add al,fs:ps_global_post_perc
    sub al,100
    jnc load_thread_wakeup_global

load_wakeup_local:
    add al,100
    mov fs:ps_curr_post,al

load_wakeup_local_do:    
    call InsertCoreBlock
    cmp di,fs:ps_prio_act
    jbe load_thread_wakeup_loop
;       
    mov fs:ps_prio_act,di
    jmp load_thread_wakeup_loop

load_thread_wakeup_global:
    mov fs:ps_curr_post,al
;
    call cs:lock_ready_proc
    call InsertBlock
    cmp di,ds:global_prio_act
    jb load_thread_global_unlock
;
    mov ds:global_prio_act,di

load_thread_global_unlock:
    call cs:unlock_ready_proc    
    jmp load_thread_wakeup_loop
    
load_thread_wakeup_done:
    xor ax,ax
    mov es,ax
    sti    
    call GetNextThread

load_reload_loop:
    call cs:preempt_reload_proc
    jnc load_a_task
    
load_retry:
    mov ax,task_sel
    mov ds,ax
    mov ax,es
    cmp ax,fs:ps_null_thread
    je load_thread_loop
;    
    mov di,es:p_prio
    call InsertCoreFirst
    cmp di,fs:ps_prio_act
    jbe load_retry_do
;
    mov fs:ps_prio_act,di
    lock or fs:ps_flags,PS_FLAG_PRIO_CHANGE

load_retry_do:
    jmp load_thread_loop

load_a_task:
    lock or fs:ps_flags,PS_FLAG_LOADING
    mov ax,gdt_sel
    mov ds,ax
    mov bx,es:p_tss_sel
    and byte ptr ds:[bx+5],NOT 2
    ltr bx
;    
    test fs:ps_flags,PS_FLAG_FLUSH
    jz load_not_flush
;
    lock and fs:ps_flags, NOT PS_FLAG_FLUSH
    jmp load_reload_cr3

load_not_flush:
    mov edx,io_focus_linear
    GetSysPageDir
;    
    mov esi,eax
    mov edi,ebx
;
    mov edx,io_focus_linear
    GetPageDir
;    
    cmp esi,eax
    jne load_reload_cr3
;
    cmp edi,ebx
    jne load_reload_cr3    
;
    mov eax,cr3
    cmp eax,es:p_cr3
    je load_cr3_ok

load_reload_cr3:    
    GetPageDirAttrib
    xor edi,edi

load_reload_cr3_loop:
    mov edx,io_focus_linear
    add edx,edi
    GetSysPageDir
    SetPageDir
;    
    add edi,esi
    loop load_reload_cr3_loop
;
    mov eax,es:p_cr3
    mov cr3,eax

load_cr3_ok:
    mov ax,es
    mov ds,ax
;
    test fs:ps_flags,PS_FLAG_FPU
    jz load_fpu_ok
;    
    mov bx,fs:ps_math_thread
    cmp ax,bx
    je load_fpu_ok
;
    push ds
    mov ds,bx
    mov bx,OFFSET p_math_control
    clts
    db 9Bh, 66h, 0DDh, 37h      ;       32-bit fsave [bx]
    pop ds
;
    lock and fs:ps_flags,NOT PS_FLAG_FPU
;
    mov eax,cr0
    or al,8
    mov cr0,eax    

load_fpu_ok:
    lldt ds:p_tss_ldt
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
    call load_breaks
    jmp load_actions_done

load_bp_done:
    xor eax,eax
    mov dr7,eax

load_actions_done: 
    call LoadUnlockCore
    mov ax,fs:ps_wakeup_list
    or ax,ax
    jnz load_relock
;
    test fs:ps_flags,PS_FLAG_TIMER
    jz load_regs

load_relock:
    sti
    call LockCore
    jmp load_retry
        
load_regs:
    test fs:ps_flags,PS_FLAG_QUERY_SYS OR PS_FLAG_HAS_SYS
    jz load_no_syscall
;
    test fs:ps_flags,PS_FLAG_HAS_SYS
    jnz load_msr
;
    lock and fs:ps_flags,NOT PS_FLAG_QUERY_SYS
    mov ax,syscall_patch_nr
    IsValidOsGate
    jc load_no_syscall
;
    lock or fs:ps_flags,PS_FLAG_HAS_SYS 

load_msr:    
    mov eax,ds:p_stack0_top
    xor edx,edx
    mov ecx,MSR_SYSENTER_ESP
    wrmsr

load_no_syscall:    
    mov fs:ps_curr_thread,es
    mov fs:ps_last_thread,es
    lock and fs:ps_flags,NOT PS_FLAG_LOADING
;
    test ds:p_tss_eflags,20000h
    jnz load_vm
;
    test ds:p_tss_cs,3
    jnz load_pm_app

load_kernel:
    mov ax,ds:p_tss_ss
    mov ss,ax
    mov esp,ds:p_tss_esp
;
    xor ax,ax
    push ds:p_tss_eflags
    push ax
    push ds:p_tss_cs
    push ds:p_tss_eip
;       
    mov ecx,ds:p_tss_ecx
    mov edx,ds:p_tss_edx
    mov ebx,ds:p_tss_ebx
    mov ebp,ds:p_tss_ebp
    mov esi,ds:p_tss_esi
    mov edi,ds:p_tss_edi
;
    mov ax,ds:p_tss_es
    verr ax
    jz load_kernel_es
;
    xor ax,ax
    
load_kernel_es:
    mov es,ax
;       
    mov ax,ds:p_tss_fs
    verr ax
    jz load_kernel_fs
;
    xor ax,ax
    
load_kernel_fs:
    mov fs,ax
;       
    mov ax,ds:p_tss_gs
    verr ax
    jz load_kernel_gs
;
    xor ax,ax
    
load_kernel_gs:
    mov gs,ax
;       
    mov ax,ds:p_tss_ds
    verr ax
    jz load_kernel_ds
;
    xor ax,ax
    
load_kernel_ds:
    push ax
    mov eax,ds:p_tss_eax
    pop ds
    iretd

load_pm_app:    
    mov ax,ds:p_tss_ess0
    mov ss,ax
    mov esp,ds:p_tss_esp0
;
    xor ax,ax
    push ax
    push ds:p_tss_ss
    push ds:p_tss_esp
    push ds:p_tss_eflags
    push ax
    push ds:p_tss_cs
    push ds:p_tss_eip
;       
    mov ecx,ds:p_tss_ecx
    mov edx,ds:p_tss_edx
    mov ebx,ds:p_tss_ebx
    mov ebp,ds:p_tss_ebp
    mov esi,ds:p_tss_esi
    mov edi,ds:p_tss_edi
;
    mov ax,ds:p_tss_es
    verr ax
    jz load_pm_app_es
;
    xor ax,ax
    
load_pm_app_es:
    mov es,ax
;       
    mov ax,ds:p_tss_fs
    verr ax
    jz load_pm_app_fs
;
    xor ax,ax
    
load_pm_app_fs:
    mov fs,ax
;       
    mov ax,ds:p_tss_gs
    verr ax
    jz load_pm_app_gs
;
    xor ax,ax
    
load_pm_app_gs:
    mov gs,ax
;       
    mov ax,ds:p_tss_ds
    verr ax
    jz load_pm_app_ds
;
    xor ax,ax
    
load_pm_app_ds:
    push ax
    mov eax,ds:p_tss_eax
    pop ds
    iretd

load_vm:
    mov ax,ds:p_tss_ess0
    mov ss,ax
    mov esp,ds:p_tss_esp0
;
    xor ax,ax
    push ax
    push ds:p_tss_gs
    push ax
    push ds:p_tss_fs
    push ax
    push ds:p_tss_ds
    push ax
    push ds:p_tss_es
    push ax
    push ds:p_tss_ss
    push ds:p_tss_esp
    push ds:p_tss_eflags
    push ax
    push ds:p_tss_cs
    push ds:p_tss_eip
;
    mov eax,ds:p_tss_eax
    mov ecx,ds:p_tss_ecx
    mov edx,ds:p_tss_edx
    mov ebx,ds:p_tss_ebx
    mov ebp,ds:p_tss_ebp
    mov esi,ds:p_tss_esi
    mov edi,ds:p_tss_edi
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
    GetSystemTime
;    
    mov ds,fs:ps_curr_thread
    sub eax,fs:ps_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    add fs:ps_lsb_tics,eax
    adc fs:ps_msb_tics,0
;    
    pushfd
    pop eax
    or ax,200h
    mov ds:p_tss_eflags,eax    
;
    pushf
    pop ax    
    and ax,NOT 100h
    push ax
    popf
;
    mov ds:p_tss_ecx,ecx
    mov ds:p_tss_ebx,ebx
    mov ds:p_tss_ebp,ebp
    mov ds:p_tss_esi,esi
    mov ds:p_tss_edi,edi
    mov ds:p_tss_es,es
    mov ds:p_tss_cs,cs
    mov ds:p_tss_ss,ss
    mov ds:p_tss_gs,gs
;
    pop ds:p_tss_edx
    pop eax
    mov ds:p_tss_eax,eax
;
    pop ds:p_tss_ds
    pop ds:p_tss_fs
    pop bp
    pop dx
    movzx edx,dx
    mov ds:p_tss_eip,edx
    mov ds:p_tss_esp,esp
    mov edx,ds:p_tss_edx
;    
    mov ss,fs:ps_ss
    mov esp,fs:ps_esp
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
    GetSystemTime
    mov ds,fs:ps_curr_thread
    sub eax,fs:ps_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    add fs:ps_lsb_tics,eax
    adc fs:ps_msb_tics,0
;
    pushfd
    pop eax
    or ax,200h
    mov ds:p_tss_eflags,eax
    mov ds:p_tss_ecx,ecx
    mov ds:p_tss_ebx,ebx
    mov ds:p_tss_ebp,ebp
    mov ds:p_tss_esi,esi
    mov ds:p_tss_edi,edi
    mov ds:p_tss_es,es
    mov ds:p_tss_cs,cs
    mov ds:p_tss_ss,ss
    mov ds:p_tss_gs,gs
;
    pop ds:p_tss_edx
    pop eax
    mov ds:p_tss_eax,eax
;
    pop ds:p_tss_ds
    pop ds:p_tss_fs
    pop bp
    pop dx
    movzx edx,dx
    mov ds:p_tss_eip,edx
    mov ds:p_tss_esp,esp
    mov edx,ds:p_tss_edx
;    
    mov ss,fs:ps_ss
    mov esp,fs:ps_esp
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
;           NAME:           SaveLockedThreadKeepEs
;
;           DESCRIPTION:    Save state of current thread when lock is already taken
;
;       PARAMETERS:     Stack, return IP
;               FS      Core selector
;
;       RETURNS:    SS:SP       Processor stack
;                   GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveLockedThreadKeepEs    Proc near       
    push fs
    push ds
    push eax
    push edx
;
    GetSystemTime
    mov ds,fs:ps_curr_thread
    sub eax,fs:ps_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    add fs:ps_lsb_tics,eax
    adc fs:ps_msb_tics,0
;
    pushfd
    pop eax
    or ax,200h
    mov ds:p_tss_eflags,eax
    mov ds:p_tss_ecx,ecx
    mov ds:p_tss_ebx,ebx
    mov ds:p_tss_ebp,ebp
    mov ds:p_tss_esi,esi
    mov ds:p_tss_edi,edi
    mov ds:p_tss_es,es
    mov ds:p_tss_cs,cs
    mov ds:p_tss_ss,ss
    mov ds:p_tss_gs,gs
;
    pop ds:p_tss_edx
    pop eax
    mov ds:p_tss_eax,eax
;
    pop ds:p_tss_ds
    pop ds:p_tss_fs
    pop bp
    pop dx
    movzx edx,dx
    mov ds:p_tss_eip,edx
    mov ds:p_tss_esp,esp
    mov edx,ds:p_tss_edx
;    
    mov ss,fs:ps_ss
    mov esp,fs:ps_esp
    push bp
;
    xor bp,bp
    mov ds,bp
    mov gs,bp    
    ret
SaveLockedThreadKeepEs   Endp


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
    push eax
    push ds
    GetSystemTime
    mov ds,fs:ps_curr_thread
    sub eax,fs:ps_last_lsb
    add ds:p_lsb_tics,eax
    adc ds:p_msb_tics,0
    add fs:ps_lsb_tics,eax
    adc fs:ps_msb_tics,0
    pop ds
    pop eax
;    
    pop bp
;    
    mov ss,fs:ps_ss
    mov esp,fs:ps_esp
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
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz cctDone
;
    push es
    mov es,ax
    mov di,es:p_prio
    or di,di
    je cctPop
;
    test fs:ps_flags,PS_FLAG_PREEMPT
    jz cctLocal
;
    mov ax,task_sel
    mov ds,ax
    call cs:lock_ready_proc
    call InsertBlock
    cmp di,ds:global_prio_act
    jb cctGlobalUnlock
;
    mov ds:global_prio_act,di

cctGlobalUnlock:
    call cs:unlock_ready_proc    
    jmp cctPop
        
cctLocal:
    call InsertCoreFirst
    cmp di,fs:ps_prio_act
    jbe cctPop
;
    mov fs:ps_prio_act,di
    lock or fs:ps_flags,PS_FLAG_PRIO_CHANGE

cctPop:
    pop es    

cctDone:
    mov fs:ps_curr_thread,0
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
    or al,8
    mov cr0,eax    
;
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:ps_sel
;
    mov ax,start_syscall_nr
    IsValidOsGate
    jc  run_core_do
;
    StartSyscall

run_core_do:  
    sti
    call LockCore
    lock or fs:ps_flags,PS_FLAG_PREEMPT    
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
    mov es,es:p_tss_ess0
    FreeMem
    pop es
;
    mov bx,es:p_tss_sel
    FreeGdt
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
    call LockCore
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
    xor ebx,ebx
    FreePhysical

cleanup_process_linear_next:
    add edx,4
    loop cleanup_process_linear_loop
;
    mov edx,handle_linear
    shr edx,10
    add edx,alias_linear
    mov eax,2
    mov ecx,1
    FreePageEntries
;
    mov eax,es:p_cr3
    xor ebx,ebx
    FreePhysical
;
    sti
    push es
    mov es,es:p_tss_ess0
    FreeMem
    pop es
;
    mov bx,es:p_tss_sel
    FreeGdt
;    
    FreeMem
;
    call UnlockCore
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
    mov ax,kernel_patch_sel
    mov ds,ax
    GetThread
    mov ds:system_thread,ax
;
    mov ax,task_sel
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


start_processor_null_threads    Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov al,ds:cpu_type
    cmp al,3
    jbe start_locks_ok
;
    mov ax,kernel_patch_sel
    mov ds,ax
    mov ds:flush_tlb_proc,OFFSET FlushTlb486
;    
    GetCoreCount
    cmp cx,1
    jbe start_locks_ok
;
    mov ds:lock_list_proc,OFFSET LockListMultiple
    mov ds:unlock_list_proc,OFFSET UnlockListMultiple
    mov ds:lock_cli_thread_proc,OFFSET LockCliThreadMultiple
    mov ds:unlock_cli_thread_proc,OFFSET UnlockCliThreadMultiple
    mov ds:lock_sti_thread_proc,OFFSET LockStiThreadMultiple
    mov ds:unlock_sti_thread_proc,OFFSET UnlockStiThreadMultiple
    mov ds:access_sti_thread_proc,OFFSET AccessStiThreadMultiple
    mov ds:lock_ready_proc,OFFSET LockReadyMultiple
    mov ds:unlock_ready_proc,OFFSET UnlockReadyMultiple
    mov ds:lock_kernel_section_proc,OFFSET LockKernelSectionMultiple
    mov ds:unlock_kernel_section_proc,OFFSET UnlockKernelSectionMultiple
    mov ds:lock_user_section_proc,OFFSET LockUserSectionMultiple
    mov ds:unlock_user_section_proc,OFFSET UnlockUserSectionMultiple
    mov ds:lock_futex_proc,OFFSET LockFutexMultiple
    mov ds:unlock_futex_proc,OFFSET UnlockFutexMultiple
    mov ds:flush_tlb_proc,OFFSET FlushTlbMultiple

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
    mov di,5
    inc byte ptr es:[di]
    inc bx
    loop create_null_loop

start_processor_free:
    FreeMem
    ret
start_processor_null_threads    Endp

null_base   DB 'Null'

null_thread0:
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:ps_sel
    mov ax,fs:ps_curr_thread
    mov es,ax
    mov es:p_sleep_sel,fs
    mov es:p_sleep_offset,0
    mov fs:ps_null_thread,ax
    lock or fs:ps_flags,PS_FLAG_ACTIVE
;
    mov ax,start_core_nr
    IsValidOsGate
    jc null_ap_ok
;
    call SetupMpPatch

null_ap_ok:   
    push OFFSET null_loop_start
    call SaveCurrentThread
;    
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
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
    mov fs:ps_null_thread,ax
;
    push OFFSET null_loop_start
    call SaveCurrentThread
;    
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0    
    jmp LoadThread

null_loop_start:
    GetCore
    
null_loop:
    test fs:ps_flags,PS_FLAG_SHUTDOWN
    jz null_hlt
;
    push OFFSET null_loop_start
    call SaveCurrentThread
;
    call UnlockCore
    lock and fs:ps_flags,NOT PS_FLAG_SHUTDOWN
    mov fs:ps_curr_thread,0
    ShutdownCore    

null_hlt:    
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
    mov ds,dx
    call TryLockCore
;
    mov di,ds:[esi]
    or di,di
    jz wtUnlock
;       
    call cs:lock_list_proc
    call RemoveBlock32
    mov es:p_data,eax
    call cs:unlock_list_proc
;
    cli
    mov di,OFFSET ps_wakeup_list
    call InsertCoreBlock
    sti
    
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
;           NAME:           DebugException / LockedDebugException
;
;           DESCRIPTION:    Save current state from stack + local registers
;
;       PARAMETERS:     SS:EBP       Exception stack
;                       AL      Fault vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_exception_name        DB 'Debug Exception', 0
locked_debug_exception_name     DB 'Locked Debug Exception', 0

locked_debug_exception:
    movzx ax,al
    push fs
    push ax
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:ps_sel
    pop ax
    jmp debug_normal

debug_exception:
    movzx ax,al
    push fs
    call TryLockCore
    jc debug_normal

debug_fault:
    movzx eax,al
    CrashFault
   
debug_normal:       
    push ax
    mov ax,fs:ps_curr_thread 
    or ax,ax
    pop ax
    jz debug_fault
;    
    mov ds,fs:ps_curr_thread 
    mov al,[ebp].trap_exc_nr
    mov ds:p_fault_vector,al
    mov eax,[ebp].trap_err
    mov ds:p_fault_code,eax
;
    mov eax,[ebp].trap_eax
    mov ds:p_tss_eax,eax
    mov eax,[ebp].trap_ebx
    mov ds:p_tss_ebx,eax
    mov ds:p_tss_ecx,ecx
    mov ds:p_tss_edx,edx
    mov ds:p_tss_esi,esi
    mov ds:p_tss_edi,edi
    mov eax,[ebp].trap_ebp
    mov ds:p_tss_ebp,eax
;       
    mov eax,[ebp].trap_eflags
    mov ds:p_tss_eflags,eax
    mov ax,[ebp].trap_cs
    mov ds:p_tss_cs,ax
    mov eax,[ebp].trap_eip
    mov ds:p_tss_eip,eax
;       
    pop si
    test dword ptr [ebp].trap_eflags,20000h
    jnz debug_vm

debug_pm:
    mov al,[ebp].trap_cs
    test al,3
    jz debug_kernel
;
    mov ax,[ebp].trap_ss
    mov ds:p_tss_ss,ax
    mov eax,[ebp].trap_esp
    mov ds:p_tss_esp,eax
    jmp debug_pm_common
    
debug_kernel:
    mov ax,ss
    mov ds:p_tss_ss,ax
    mov eax,ebp
    add eax,trap_esp
    mov ds:p_tss_esp,eax
    
debug_pm_common:
    mov ax,[ebp].trap_pds
    mov ds:p_tss_ds,ax
    mov ax,es
    mov ds:p_tss_es,ax
    mov ds:p_tss_fs,si
    mov ax,gs
    mov ds:p_tss_gs,ax
    jmp debug_save_ok

debug_vm:
    mov ax,[ebp].trap_gs
    mov ds:p_tss_gs,ax
    mov ax,[ebp].trap_fs
    mov ds:p_tss_fs,ax
    mov ax,[ebp].trap_ds
    mov ds:p_tss_ds,ax
    mov ax,[ebp].trap_es
    mov ds:p_tss_es,ax
    mov ax,[ebp].trap_ss
    mov ds:p_tss_ss,ax
    mov eax,[ebp].trap_esp
    mov ds:p_tss_esp,eax

debug_save_ok:
    mov ss,fs:ps_ss
    mov esp,fs:ps_esp
;
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov gs,ax    
;
    mov ax,fs:ps_curr_thread
    cmp ax,fs:ps_null_thread
    je debug_fault
    
debug_block:
    mov es,fs:ps_curr_thread
    mov eax,es:p_debug_proc
    or eax,eax
    jz debug_block_do
;
    call es:p_debug_proc

debug_block_do:
    mov fs:ps_curr_thread,0
;    
    mov ax,system_data_sel
    mov ds,ax
    mov edi,OFFSET debug_list       
;
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
;
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi
    jmp LoadThread        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DebugBreak
;
;           DESCRIPTION:    Put current thread in debugger
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_break_name   DB 'Debug Bread',0

db_eax   EQU -8
db_fs    EQU -4
db_ds    EQU -2
db_bp    EQU 0
db_eip   EQU 2
db_cs    EQU 6
db_esp   EQU 10
db_ss    EQU 14 

debug_break:
    push bp
    mov bp,sp
;
    push ds
    push fs
    push eax
;    
    call LockCore
    mov ds,fs:ps_curr_thread 
;
    mov eax,[bp].db_eax
    mov ds:p_tss_eax,eax
    mov ds:p_tss_ebx,ebx
    mov ds:p_tss_ecx,ecx
    mov ds:p_tss_edx,edx
    mov ds:p_tss_esi,esi
    mov ds:p_tss_edi,edi
    mov eax,ebp
    mov ax,[bp].db_bp
    mov ds:p_tss_ebp,eax
;       
    pushfd
    pop ds:p_tss_eflags
;
    mov ax,[bp].db_cs
    mov ds:p_tss_cs,ax
    mov eax,[bp].db_eip
    mov ds:p_tss_eip,eax
;
    mov al,[bp].db_cs
    test al,3
    jz debug_break_kernel
;
    mov ax,[bp].db_ss
    mov ds:p_tss_ss,ax
    mov eax,[bp].db_esp
    mov ds:p_tss_esp,eax
    jmp debug_break_common
    
debug_break_kernel:
    mov ax,ss
    mov ds:p_tss_ss,ax
    mov ax,bp
    add ax,db_esp
    movzx eax,ax
    mov ds:p_tss_esp,eax
    
debug_break_common:
    mov ax,[bp].db_ds
    mov ds:p_tss_ds,ax
    mov ax,es
    mov ds:p_tss_es,ax
    mov ax,[bp].db_fs
    mov ds:p_tss_fs,ax
    mov ax,gs
    mov ds:p_tss_gs,ax
;
    mov ss,fs:ps_ss
    mov esp,fs:ps_esp
;
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov gs,ax    
;    
    mov es,fs:ps_curr_thread
    mov eax,es:p_debug_proc
    or eax,eax
    jz debug_break_block_do
;
    call es:p_debug_proc

debug_break_block_do:
    mov fs:ps_curr_thread,0
;    
    mov ax,system_data_sel
    mov ds,ax
    mov edi,OFFSET debug_list       
;
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
;
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi
    jmp LoadThread        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoubleFault
;
;           DESCRIPTION:    Handle double fault exception (from task-gate)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
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
    call TryLockCore
    jc double_fault_lock_ok
;    
    CrashTss
    
double_fault_lock_ok:    
    mov ss,fs:ps_ss
    mov esp,fs:ps_esp
;
    xor ax,ax
    mov es,ax
    mov gs,ax    
;
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz double_block

double_fatal_no_thread:
    CrashTss
    
double_block:
    mov es,ax    
    mov es:p_fault_vector,8
    mov es:p_fault_code,0
    mov fs:ps_curr_thread,0
;    
    mov ax,system_data_sel
    mov ds,ax
    mov edi,OFFSET debug_list       
;
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
;
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi
    jmp LoadThread        

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
;       NAME:           CreateCore
;
;       DESCRIPTION:    Create core
;
;       PARAMETERS:     EDX     Core GDT linear
;
;       RETURNS:        AX      Processor #
;                       ES      Processor sel
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
    mov cx,SIZE processor_seg
    xor di,di
    xor al,al
    rep stosb
    mov es:ps_sel,es
;
    mov eax,1000h
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector32
    mov es:ps_ss,bx
    mov es:ps_esp,1000h
    mov ds,bx
    mov ds:[0],bx
;
    mov ax,kernel_patch_sel
    mov ds,ax
    mov ax,ds:core_count
    mov si,ax
    add si,si
    mov ds:[si].core_arr,es
    inc ds:core_count
    mov es:ps_id,ax    
;
    xor ax,ax
    mov bx,OFFSET ps_ptab
    mov es:ps_prio_act,bx
;
    mov cx,256

ptab_init:
    mov es:[bx],ax
    add bx,2
    loop ptab_init
;
    mov es:ps_wakeup_list,0
    mov es:ps_nesting,-1
    mov es:ps_curr_thread,0
    mov es:ps_last_thread,-1
    mov es:ps_flags,PS_FLAG_INIT_CLOCK OR PS_FLAG_QUERY_SYS
    mov es:ps_null_thread,0
    mov es:ps_math_thread,0
    mov es:ps_apic,-1
    mov es:ps_last_lsb,0
    mov es:ps_global_post_perc,DEFAULT_GLOBAL
    mov es:ps_curr_post,0
    mov es:ps_tlb_flush,0
    mov es:ps_lsb_tics,0
    mov es:ps_msb_tics,0
;    
    mov es:cs_usel,flat_sel
    mov es:cs_uoffs,0
    mov es:cs_fault,-1
    mov es:cs_irq,0
;
    mov es:ps_timer_spinlock,0
    mov bx,OFFSET ps_timer_entries
    mov es:[bx].timer_next,0
    mov es:[bx].timer_msb,0FFFFFFFFh
    mov es:[bx].timer_lsb,0FFFFFFFFh
    mov es:ps_timer_head,bx
;       
    mov cx,0FFh
    add bx,SIZE timer_struc
    mov es:ps_timer_free,bx

core_timer_list_create:
    mov ax,bx
    add ax,SIZE timer_struc
    mov es:[bx].timer_next,ax
    mov bx,ax
    loop core_timer_list_create
;
    mov ax,es:ps_id     
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
    mov ax,fs:ps_nesting
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
    mov fs,fs:ps_sel
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
;           NAME:           LockCliThreadSingle
;
;           DESCRIPTION:    Lock thread with cli, single processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockCliThreadSingle  Proc near
    cli
    ret
LockCliThreadSingle  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockCliThreadSingle
;
;           DESCRIPTION:    Unlock thread with cli, single processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockCliThreadSingle    Proc near
    sti
    ret
UnlockCliThreadSingle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockStiThreadSingle
;
;           DESCRIPTION:    Lock thread with sti, single processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockStiThreadSingle  Proc near
    ret
LockStiThreadSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockStiThreadSingle
;
;           DESCRIPTION:    Unlock thread with sti, single processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockStiThreadSingle    Proc near
    ret
UnlockStiThreadSingle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AccessStiThreadSingle
;
;           DESCRIPTION:    Access thread lock with sti, single processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AccessStiThreadSingle  Proc near
    ret
AccessStiThreadSingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockReadySingle
;
;           DESCRIPTION:    Lock global ready-queue, single processor version
;
;           PARAMETERS:     DS      Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockReadySingle  Proc near
    ret
LockReadySingle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockReadySingle
;
;           DESCRIPTION:    Unlock global ready-queue, single processor version
;
;           PARAMETERS:     DS      Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockReadySingle    Proc near
    ret
UnlockReadySingle    Endp

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
;           NAME:           LockListMultiple
;
;           DESCRIPTION:    Lock list, multiple processor version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockListMultiple    Proc near
    push ds
    push ax
;
    mov ax,task_sel
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
    mov ax,task_sel
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
;           NAME:           LockCliThreadMultiple
;
;           DESCRIPTION:    Lock thread with cli, multiple processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockCliThreadMultiple    Proc near
    push ax

lctSpinLock:    
    sti
    mov ax,es:p_cli_spinlock
    or ax,ax
    je lctGet
;
    pause
    jmp lctSpinLock

lctGet:
    cli
    inc ax
    xchg ax,es:p_cli_spinlock
    or ax,ax
    jne lctSpinLock

lctDone:
    pop ax    
    ret
LockCliThreadMultiple    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockCliThreadMultiple
;
;           DESCRIPTION:    Unlock thread with cli, multiple processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockCliThreadMultiple      Proc near
    mov es:p_cli_spinlock,0
    sti
    ret
UnlockCliThreadMultiple      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockStiThreadMultiple
;
;           DESCRIPTION:    Lock thread with sti, multiple processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockStiThreadMultiple    Proc near
    push ax
    mov ax,1

lstSpinLock:    
    xchg ax,es:p_sti_spinlock
    or ax,ax
    je lstGet
;
    pause
    jmp lstSpinLock

lstGet:
    pop ax    
    ret
LockStiThreadMultiple    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockStiThreadMultiple
;
;           DESCRIPTION:    Unlock thread with sti, multiple processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockStiThreadMultiple      Proc near
    mov es:p_sti_spinlock,0
    ret
UnlockStiThreadMultiple      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AccessStiThreadMultiple
;
;           DESCRIPTION:    Access lock thread with sti, multiple processor version
;
;           PARAMETERS:     ES      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AccessStiThreadMultiple    Proc near
    push ax
    mov ax,1

astSpinLock:    
    xchg ax,es:p_sti_spinlock
    or ax,ax
    je astGet
;
    pause
    jmp astSpinLock

astGet:
    mov es:p_sti_spinlock,ax
    pop ax    
    ret
AccessStiThreadMultiple    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockReadyMultiple
;
;           DESCRIPTION:    Lock global ready-queue, multiple processor version
;
;           PARAMETERS:     DS      Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockReadyMultiple  Proc near
    push ax
    sti

lrSpinLock:    
    mov ax,ds:global_spinlock
    or ax,ax
    je lrGet
;
    pause
    jmp lrSpinLock

lrGet:
    inc ax
    xchg ax,ds:global_spinlock
    or ax,ax
    je lrDone
;
    jmp lrSpinLock

lrDone:
    pop ax    
    ret
LockReadyMultiple  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockReadyMultiple
;
;           DESCRIPTION:    Unlock global ready-queue, multiple processor version
;
;           PARAMETERS:     DS      Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockReadyMultiple    Proc near
    mov ds:global_spinlock,0
    sti
    ret
UnlockReadyMultiple    Endp

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
;           NAME:           TryLockCore
;
;           DESCRIPTION:    Try to lock
;
;       RETURNS:    CY      Owner of section
;               FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TryLockCore   Proc near
    push word ptr core_data_sel
    pop fs
    add fs:ps_nesting,1
    mov fs,fs:ps_sel
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
    push word ptr core_data_sel
    pop fs
    add fs:ps_nesting,1
    jc lcDone
;
    CrashGate

lcDone:     
    mov fs,fs:ps_sel
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
    push ax
    
tucRetry:    
    cli
    sub fs:ps_nesting,1
    jnc tucDone
;
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz tucDone
;    
    test fs:ps_flags,PS_FLAG_TIMER OR PS_FLAG_PREEMPT
    jnz tucSwap
;    
    mov ax,fs:ps_wakeup_list
    or ax,ax
    jz tucDone

tucSwap:
    add fs:ps_nesting,1
    jnc tucRetry
;
    sti
    push OFFSET tucDone
    call SaveLockedThread
    jmp ContinueCurrentThread

tucDone:
    sti
    pop ax
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
    push ax
    
ucRetry:    
    cli
    sub fs:ps_nesting,1
    jc ucNestOk
;
    CrashGate

ucNestOk:    
    test fs:ps_flags,PS_FLAG_TIMER OR PS_FLAG_PREEMPT
    jnz ucSwap
;    
    mov ax,fs:ps_wakeup_list
    or ax,ax
    jz ucDone

ucSwap:
    add fs:ps_nesting,1
    jnc ucRetry
;
    sti
    push OFFSET ucDone
    call SaveLockedThread
    jmp ContinueCurrentThread

ucDone:
    sti
    pop ax
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
    cli
    sub fs:ps_nesting,1
    jc lulcDone
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irq_schedule_name  DB 'IRQ Schedule',0

irq_schedule    Proc far    
    push OFFSET irqsDone
    call SaveLockedThread
    jmp ContinueCurrentThread

irqsDone:
    retf32
irq_schedule    Endp

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
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:ps_sel
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
;           NAME:           FlushTlb386
;
;           DESCRIPTION:    Flush TLB entries, 386 processor version
;
;           PARAMETERS:     CX      Number of entries
;                           EDX     Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushTlb386    Proc near
    push eax
    mov eax,cr3
    mov cr3,eax
    pop eax
    ret
FlushTlb386    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushTlb486
;
;           DESCRIPTION:    Flush TLB entries, 486+ processor version
;
;           PARAMETERS:     CX      Number of entries
;                           EDX     Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushTlb486    Proc near
    push ds
    push ax
    push cx
    push edx
;
    cmp cx,4
    jae ft4All
;
    mov ax,flat_sel
    mov ds,ax

ft4Loop:
    invlpg [edx]
    add edx,1000h
    loop ft4Loop
;
    jmp ft4Done
        
ft4All:    
    mov edx,cr3
    mov cr3,edx

ft4Done:    
    pop edx
    pop cx
    pop ax
    pop ds
    ret
FlushTlb486    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LockTlbBlock
;
;       DESCRIPTION:    Lock TLB block
;
;       PARAMETERS:     DS      Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockTlbBlock    Proc near

ltbSpinLock:    
    mov ax,ds:tlb_block_spinlock
    or ax,ax
    je ltbGet
;
    pause
    jmp ltbSpinLock

ltbGet:
    cli
    inc ax
    xchg ax,ds:tlb_block_spinlock
    or ax,ax
    je ltbDone
;
    jmp ltbSpinLock

ltbDone:
    ret
LockTlbBlock    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlockTlbBlock
;
;       DESCRIPTION:    Unlock TLB block
;
;       PARAMETERS:     DS      Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockTlbBlock    Proc near
    mov ds:tlb_block_spinlock,0
    sti
    ret
UnlockTlbBlock    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateTlbBlock
;
;       DESCRIPTION:    Allocate 64-byte TLB block
;
;       PARAMETERS:     DS      Task sel
;                       ES      Flat sel
;
;       RETURNS:        EDX     Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTlbBlock PROC near
    push eax
;    
    call LockTlbBlock
    mov edx,ds:tlb_block_list
    or edx,edx
    jnz atbDone
;
    push ecx
    sub ds:tlb_remain_linear,1000h
    jnz atbUseMore
;
    CrashGate

atbUseMore:
    mov edx,ds:tlb_curr_linear
    add ds:tlb_curr_linear,1000h
    mov ds:tlb_block_list,edx
    mov ecx,64
    
atbLoop:
    mov eax,edx
    add eax,ecx
    mov es:[edx],eax
    mov edx,eax
    test dx,0FFFh
    jnz atbLoop
;
    sub edx,ecx
    mov dword ptr es:[edx],0
    mov edx,ds:tlb_block_list
    pop ecx

atbDone:
    mov eax,es:[edx]
    mov ds:tlb_block_list,eax
    call UnlockTlbBlock
;
    pop eax
    ret
AllocateTlbBlock ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeTlbBlock
;
;       DESCRIPTION:    Free 64-byte TLB block
;
;       PARAMETERS:     DS      Task sel
;                       ES      Flat sel
;                       EDX     Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeTlbBlock     PROC near
    push eax
;    
    call LockTlbBlock
    mov eax,ds:tlb_block_list
    mov es:[edx],eax
    mov ds:tlb_block_list,edx
    call UnlockTlbBlock
;       
    pop eax
    ret
FreeTlbBlock     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockTlb
;
;           DESCRIPTION:    Lock TLB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockTlb    Proc near
    mov ax,task_sel
    mov ds,ax

ltmSpinLock:    
    mov ax,ds:tlb_spinlock
    or ax,ax
    je ltmGet
;
    pause
    jmp ltmSpinLock

ltmGet:
    cli
    inc ax
    xchg ax,ds:tlb_spinlock
    or ax,ax
    je ltmDone
;
    jmp ltmSpinLock

ltmDone:
    ret
LockTlb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockTlb
;
;           DESCRIPTION:    Unlock TLB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockTlb    Proc near
    mov ds:tlb_spinlock,0
    sti
    ret
UnlockTlb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateTlb
;
;           DESCRIPTION:    Allocate TLB header
;
;           PARAMETERS:     ES      Flat sel
;                           EDX     Linear base
;                           FS      Core sel
;
;           RETURNS:        EDX     Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTlb     Proc near
    push ecx
;    
    push edx
    call AllocateTlbBlock
    pop es:[edx].th_linear
    mov es:[edx].th_remain_cores,0
;
    lea edi,[edx].th_core_bits
    xor al,al
    mov ecx,MAX_CORES SHR 3
    rep stos byte ptr es:[edi]
;    
    pop ecx
    ret
AllocateTlb     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InsertTlb
;
;           DESCRIPTION:    Insert TLB entry
;
;           PARAMETERS:     ES      Flat sel
;                           EDX     Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertTlb     Proc near
    mov eax,ds:tlb_list
    mov es:[edx].th_next,eax
    mov ds:tlb_list,edx
    ret
InsertTlb   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushTlbMulti
;
;           DESCRIPTION:    Flush TLB entries
;
;           PARAMETERS:     ES      Flat sel
;                           FS      Core sel
;                           EDX     Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushTlbMulti     Proc near
    push ax
;
    mov ax,fs:ps_id
    bt es:[edx].th_core_bits,ax
    jnc ftDone
;
    push cx
    push edi
;    
    mov edi,es:[edx].th_linear
    mov cx,es:[edx].th_page_count

ftLoop:
    invlpg es:[edi]
    add edi,1000h
    loop ftLoop
;    
    mov ax,fs:ps_id
    btr es:[edx].th_core_bits,ax
    dec es:[edx].th_remain_cores
;    
    pop edi
    pop cx

ftDone:
    pop ax    
    ret
FlushTlbMulti   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushTlbList
;
;           DESCRIPTION:    Flush TLB list
;
;           PARAMETERS:     DS      Task sel
;                           ES      Flat sel
;                           FS      Core sel
;
;           RETURNS:        NC      List is done
;                           CY  ES  Entry that should be finalized
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushTlbList     Proc near
    xor esi,esi
    mov edx,ds:tlb_list

ftlLoop:
    or edx,edx
    jz ftlEmpty
;
    call FlushTlbMulti
    mov ax,es:[edx].th_remain_cores
    or ax,ax
    jz ftlRemove
;
    mov esi,edx
    mov edx,es:[edx].th_next
    jmp ftlLoop

ftlRemove:
    or esi,esi
    jz ftlRemoveHead
;
    mov eax,es:[edx].th_next
    mov es:[esi].th_next,eax
    stc
    jmp ftlDone
        
ftlRemoveHead:
    mov eax,es:[edx].th_next
    mov ds:tlb_list,eax
    stc 
    jmp ftlDone      

ftlEmpty:
    clc

ftlDone:    
    ret
FlushTlbList   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeTlb
;
;           DESCRIPTION:    Free TLB entries
;
;           PARAMETERS:     ES      Flat sel
;                           FS      Core sel
;                           EDX     Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeTlb     Proc near
    push eax
    push ebx
    push cx
    push esi
;    
    mov cx,es:[edx].th_phys_count
    lea esi,[edx].th_phys_arr
    
frtLoop:
    mov eax,es:[esi]
    xor ebx,ebx
    FreePhysical
    add esi,4
    loop frtLoop

frtDone:
    pop esi
    pop cx
    pop ebx
    pop eax    
    ret
FreeTlb   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateTlbList
;
;           DESCRIPTION:    Update TLB list (scheduler should be locked)
;
;           PARAMETERS:     FS  Core sel
;                           ES  Flat sel
;                           DS  Task sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateTlbList    Proc near

utlBaseLoop:
    call LockTlb    
    call FlushTlbList
    pushf
    call UnlockTlb
    popf
    sti
    jnc utlDone
;    
    mov ax,es:[edx].th_phys_count
    or ax,ax
    jz utlBaseFreeBlock
;    
    call FreeTlb

utlBaseFreeBlock:    
    call FreeTlbBlock
    jmp utlBaseLoop
       
utlDone:    
    ret
UpdateTlbList   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyFlushTlb
;
;           DESCRIPTION:    Flush request from core ISR (81)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_flush_tlb_name  DB 'Notify Flush TLB', 0

notify_flush_tlb   Proc far
    mov ax,task_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;    
    call TryLockCore
    call UpdateTlbList
    call TryUnlockCore
    retf32
notify_flush_tlb   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupGlobalTlbCores
;
;           DESCRIPTION:    Setup global TLB cores that should handle the request
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupGlobalTlbCores    Proc near
    push fs
;
    mov bx,OFFSET core_arr
    mov cx,cs:core_count

sgtcLoop:
    mov fs,cs:[bx]
    test fs:ps_flags,PS_FLAG_ACTIVE
    jz sgtcNext
;    
    test fs:ps_flags,PS_FLAG_LOADING
    jnz sgtcAdd
;    
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz sgtcNoThread
;
    cmp ax,fs:ps_null_thread
    je sgtcFlush

sgtcAdd:        
    mov ax,fs:ps_id
    bts es:[edx].th_core_bits,ax
    inc es:[edx].th_remain_cores
    jmp sgtcNext

sgtcNoThread:
    test fs:ps_flags,PS_FLAG_LOADING
    jnz sgtcAdd

sgtcFlush:
    lock or fs:ps_flags,PS_FLAG_FLUSH

sgtcNext:
    add bx,2
    loop sgtcLoop
;
    pop fs
    ret
SetupGlobalTlbCores Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupProcessTlbCores
;
;           DESCRIPTION:    Setup process TLB cores that should handle the request
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupProcessTlbCores    Proc near
    push ds
    push fs
;
    mov bx,OFFSET core_arr
    mov cx,cs:core_count
    mov edi,cr3

sptcLoop:
    mov fs,cs:[bx]
    test fs:ps_flags,PS_FLAG_ACTIVE
    jz sptcNext
;    
    test fs:ps_flags,PS_FLAG_LOADING
    jnz sptcAdd
;
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz sptcNoThread
;
    cmp ax,fs:ps_null_thread
    je sptcFlush
;    
    mov ds,ax
    cmp edi,ds:p_cr3
    jne sptcFlush

sptcAdd:
    mov ax,fs:ps_id
    bts es:[edx].th_core_bits,ax
    inc es:[edx].th_remain_cores
    jmp sptcNext

sptcNoThread:
    test fs:ps_flags,PS_FLAG_LOADING
    jnz sptcAdd
    
sptcFlush:  
    lock or fs:ps_flags,PS_FLAG_FLUSH
    
sptcNext:
    add bx,2
    loop sptcLoop
;
    pop fs
    pop ds
    ret
SetupProcessTlbCores Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SignalTlbCores
;
;           DESCRIPTION:    Signal cores that have new, pending requests
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignalTlbCores    Proc near
    push fs
;
    mov fs:ps_tlb_flush,1
    mov si,fs:ps_sel
    mov bx,OFFSET core_arr
    mov cx,cs:core_count
    xor di,di

stcLoop:
    bt es:[edx].th_core_bits,di
    jnc stcNext
;    
    mov ax,cs:[bx]
    cmp ax,si
    je stcNext
;
    mov fs,ax
    mov al,1
    xchg al,fs:ps_tlb_flush
    or al,al
    jnz stcNext    
;
    mov al,81h
    SendInt

stcNext:
    add bx,2
    inc di
    loop stcLoop
;
    pop fs
    ret
SignalTlbCores  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushTlbMultiple
;
;           DESCRIPTION:    Flush TLB entries, multiple processor version
;
;           PARAMETERS:     CX      Number of entries
;                           EDX     Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushTlbMultiple    Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,task_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;
    call TryLockCore
    pushf
;    
    call AllocateTlb
    mov es:[edx].th_page_count,cx
    mov es:[edx].th_phys_count,0
;    
    call LockTlb
    call SetupProcessTlbCores
    call InsertTlb
    call UnlockTlb
    call SignalTlbCores
;
    popf
    call UpdateTlbList
    call TryUnlockCore
;    
    popad
    pop fs
    pop es
    pop ds
    ret
FlushTlbMultiple    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FlushTLB
;
;           DESCRIPTION:    Flush TLB entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_tlb_name DB 'Flush Tlb', 0

flush_tlb Proc far
    call cs:flush_tlb_proc
    retf32
flush_tlb Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TimerExpired
;
;           DESCRIPTION:    Timer expired notification
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timer_expired_name   DB 'Timer Expired', 0

timer_expired    Proc far
    call TryLockCore
    sti
    mov ax,task_sel
    mov ds,ax

timer_expired_check:   
    GetSystemTime
    call LockTimerGlobal
    add eax,cs:update_tics
    adc edx,0
    mov bx,ds:timer_head
    sub eax,ds:[bx].timer_lsb
    sbb edx,ds:[bx].timer_msb
    jc timer_expired_reload
;
    call LocalRemoveTimerGlobal    
    jmp timer_expired_check

timer_expired_reload: 
    neg eax
    ReloadSysTimer
    jnc timer_expired_done
;
    call UnlockTimerGlobal
    jmp timer_expired_check

timer_expired_done:
    call UnlockTimerGlobal    
    call TryUnlockCore
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
    jc reload_preempt_locked
;
    lock or fs:ps_flags,PS_FLAG_PREEMPT
    jmp reload_preempt_done

reload_preempt_locked:
    lock or fs:ps_flags,PS_FLAG_PREEMPT
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz reload_preempt_done
;    
    push OFFSET reload_preempt_end
    call SaveLockedThread
    jmp ContinueCurrentThread

reload_preempt_done:
    call TryUnlockCore

reload_preempt_end:       
    retf32
preempt_expired    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PreemptTimerExpired
;
;           DESCRIPTION:    Preemption or timer expired notification
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

preempt_timer_expired_name   DB 'Preempt Timer Expired', 0

preempt_timer_expired    Proc far
    call TryLockCore
    jc reload_timer_preempt_locked
;
    lock or fs:ps_flags,PS_FLAG_TIMER    
    jmp reload_timer_preempt_done

reload_timer_preempt_locked:
    mov ax,task_sel
    mov ds,ax

reload_timer_preempt_loop:
    lock and fs:ps_flags,NOT PS_FLAG_TIMER   
    GetSystemTime
    call LockTimerCore
    add eax,cs:update_tics
    adc edx,0
    mov bx,fs:ps_timer_head
    mov ecx,fs:ps_preempt_msb
    cmp ecx,fs:[bx].timer_msb
    jc reload_check_preempt
    jnz reload_check_timer
;       
    mov ecx,fs:ps_preempt_lsb
    cmp ecx,fs:[bx].timer_lsb
    jc reload_check_preempt

reload_check_timer:
    sub eax,fs:[bx].timer_lsb
    sbb edx,fs:[bx].timer_msb
    jc reload_timer_preempt_do
;       
    call LocalRemoveTimerCore
    jmp reload_timer_preempt_loop

reload_check_preempt:
    sub eax,fs:ps_preempt_lsb
    sbb edx,fs:ps_preempt_msb
    jc reload_timer_preempt_do
;
    call UnlockTimerCore
    lock or fs:ps_flags,PS_FLAG_PREEMPT
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz reload_preempt_block
;    
    push OFFSET reload_timer_preempt_end
    call SaveLockedThread
    jmp ContinueCurrentThread

reload_preempt_block:
    sti
    GetSystemTime
    add eax,1193
    adc edx,0
    mov fs:ps_preempt_lsb,eax
    mov fs:ps_preempt_msb,edx
    jmp reload_timer_preempt_loop

reload_timer_preempt_do:
    neg eax
    ReloadSysPreemptTimer
    call UnlockTimerCore

reload_timer_preempt_done:
    call TryUnlockCore

reload_timer_preempt_end:       
    retf32
preempt_timer_expired    Endp

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
    mov si,task_sel
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
    push es
    pushad

start_global_retry:    
    GetSystemTime
    call LockTimerGlobal
    add eax,cs:update_tics
    adc edx,0
    mov bx,ds:timer_head
    sub eax,ds:[bx].timer_lsb
    sbb edx,ds:[bx].timer_msb
    jc start_global_reload
;    
    call LocalRemoveTimerGlobal
    jmp start_global_retry

start_global_reload:    
    neg eax
    ReloadSysTimer
    jnc start_global_idle
;
    call UnlockTimerGlobal
    jmp start_global_retry

start_global_idle:    
    call UnlockTimerGlobal
    call TryUnlockCore
    popad
    pop es
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
    mov ax,task_sel
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
    pushf
    call LockTimerCore
;    
    mov si,fs:ps_timer_free
    mov fs:[si].timer_owner,bx
    mov bx,fs:[si].timer_next
    mov fs:ps_timer_free,bx
    mov fs:[si].timer_lsb,eax
    mov fs:[si].timer_msb,edx
    mov fs:[si].timer_id,ecx
    mov fs:[si].timer_offset,edi
    mov fs:[si].timer_sel,es
    mov bx,OFFSET ps_timer_head
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
    call UnlockTimerCore
    popf
    jc start_core_reload_timer_loop
;
    lock or fs:ps_flags,PS_FLAG_TIMER    
    jmp start_core_reload_timer_done

start_core_reload_timer_loop:
    lock and fs:ps_flags,NOT PS_FLAG_TIMER   
    mov es,fs:ps_curr_thread
    GetSystemTime
    call LockTimerCore
    add eax,cs:update_tics
    adc edx,0
    mov bx,fs:ps_timer_head
    mov ecx,fs:ps_preempt_msb
    cmp ecx,fs:[bx].timer_msb
    jc start_core_reload_check_preempt
    jnz start_core_reload_check_timer
;       
    mov ecx,fs:ps_preempt_lsb
    cmp ecx,fs:[bx].timer_lsb
    jc start_core_reload_check_preempt

start_core_reload_check_timer:
    sub eax,fs:[bx].timer_lsb
    sbb edx,fs:[bx].timer_msb
    jc start_core_reload_timer_do
;       
    call LocalRemoveTimerCore
    jmp start_core_reload_timer_loop

start_core_reload_check_preempt:
    sub eax,fs:ps_preempt_lsb
    sbb edx,fs:ps_preempt_msb
    jc start_core_reload_timer_do
;
    call UnlockTimerCore
    lock or fs:ps_flags,PS_FLAG_PREEMPT
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz start_core_reload_preempt_block
;    
    push OFFSET start_core_reload_timer_end
    call SaveLockedThread
    jmp ContinueCurrentThread

start_core_reload_preempt_block:
    sti
    GetSystemTime
    add eax,1193
    adc edx,0
    mov fs:ps_preempt_lsb,eax
    mov fs:ps_preempt_msb,edx
    jmp start_core_reload_timer_loop

start_core_reload_timer_do:
    neg eax
    ReloadSysPreemptTimer
    call UnlockTimerCore

start_core_reload_timer_done:
    call TryUnlockCore

start_core_reload_timer_end:       
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
    mov bx,OFFSET ps_timer_head

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
    mov ax,fs:ps_timer_free
    mov fs:[bx].timer_next,ax
    mov fs:ps_timer_free,bx

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
    or al,8
    mov cr0,eax    
;    
    mov ax,es
    mov ds,ax
    mov ax,ds:p_tss_ss
    mov ds:p_tss_ess0,ax
    mov eax,ds:p_tss_esp
    mov ds:p_tss_esp0,eax
;    
    call LockCore
    mov di,es:p_prio
    mov fs:ps_prio_act,di
    call InsertCoreBlock
;
    mov bx,core_data_sel
    mov fs,bx
    mov fs,fs:ps_sel
;
    mov ax,start_preempt_timer_nr
    IsValidOsGate
    jc preempt_timer_combined
;
    mov bx,kernel_patch_sel
    mov ds,bx
;
    StartSysTimer
    mov ds:update_tics,eax
;
    StartPreemptTimer
    mov ds:preempt_reload_proc,OFFSET PreemptReload
;
    GetSystemTime
    mov ds:sys_lsb_tics_base,eax
    mov ds:sys_msb_tics_base,edx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET start_global_timer
    mov di,OFFSET start_global_timer_name
    xor cl,cl
    mov ax,start_timer_nr
    RegisterOsGate
;
    mov si,OFFSET stop_global_timer
    mov di,OFFSET stop_global_timer_name
    xor cl,cl
    mov ax,stop_timer_nr
    RegisterOsGate
    jmp LoadThread
        
preempt_timer_combined:        
    mov bx,kernel_patch_sel
    mov ds,bx
;
    StartSysPreemptTimer
    mov ds:update_tics,eax
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET start_core_timer
    mov di,OFFSET start_core_timer_name
    xor cl,cl
    mov ax,start_timer_nr
    RegisterOsGate
;
    mov si,OFFSET stop_core_timer
    mov di,OFFSET stop_core_timer_name
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
    cli
    mov di,OFFSET ps_wakeup_list
    call InsertCoreBlock
    sti
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
    lock and fs:ps_flags,NOT PS_FLAG_FPU
    mov fs:ps_math_thread,0
;    
    mov bx,cs:system_thread
    Signal    
;
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;    
    mov ax,task_sel
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
    lock and fs:ps_flags,NOT PS_FLAG_FPU
    mov fs:ps_math_thread,0
;    
    mov bx,cs:system_thread
    Signal    
;
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0    
;
    mov ax,task_sel
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
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    call cs:lock_list_proc
    call InsertBlock32
    call cs:unlock_list_proc
;        
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
    mov ds,ds:ps_curr_thread
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
    push es
    push fs
;
    or bx,bx
    jz signal_done
;
    mov es,bx
    call TryLockCore
    call cs:lock_cli_thread_proc
    mov es:p_signal,1
    mov ax,es:p_sleep_sel
    cmp ax,SLEEP_SEL_SIGNAL
    jne signal_unlock
;
    push di
    mov di,OFFSET ps_wakeup_list
    call InsertCoreBlock
    pop di
    mov es:p_sleep_sel,0
    mov es:p_signal,0

signal_unlock:
    call cs:unlock_cli_thread_proc
    call TryUnlockCore
    
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
    call LockCore
;    
    mov es,fs:ps_curr_thread
    call cs:lock_sti_thread_proc
    xor al,al
    call cs:lock_cli_thread_proc
    xchg al,es:p_signal
    or al,al
    jnz wait_for_signal_unlock
;
    mov es:p_sleep_sel,SLEEP_SEL_SIGNAL
    mov es:p_sleep_offset,0    
    call cs:unlock_cli_thread_proc
;
    push OFFSET wait_for_signal_done
    call SaveLockedThreadKeepEs
    call cs:unlock_sti_thread_proc    
    xor ax,ax
    mov es,ax
    mov fs:ps_curr_thread,ax
    jmp LoadThread

wait_for_signal_unlock:
    call cs:unlock_cli_thread_proc
    call cs:unlock_sti_thread_proc
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
    call LockCore
;
    mov cx,cs
    mov es,cx
    mov edi,OFFSET signal_timeout    
    mov bx,fs:ps_curr_thread
    mov cx,bx
    StartTimer
;    
    mov es,bx
    call cs:lock_sti_thread_proc
    xor al,al
    call cs:lock_cli_thread_proc
    xchg al,es:p_signal
    or al,al
    jnz wait_for_signal_timeout_unlock
;
    mov es:p_sleep_sel,SLEEP_SEL_SIGNAL
    mov es:p_sleep_offset,0    
    call cs:unlock_cli_thread_proc
;
    push OFFSET wait_for_signal_timeout_clear
    call SaveLockedThreadKeepEs
    call cs:unlock_sti_thread_proc   
    xor ax,ax
    mov es,ax 
    mov fs:ps_curr_thread,ax
    jmp LoadThread

wait_for_signal_timeout_clear:
    call LockCore
    mov bx,fs:ps_curr_thread
    StopTimer
    call UnlockCore
    jmp wait_for_signal_timeout_done
    
wait_for_signal_timeout_unlock:
    call cs:unlock_cli_thread_proc
    call cs:unlock_sti_thread_proc
    mov bx,fs:ps_curr_thread
    StopTimer
    call UnlockCore

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
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_kernel_section_proc
;
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi    
    jmp LoadThread

ecsUnlock:
    call cs:unlock_kernel_section_proc
    call UnlockCore
    
ecsDone:
    pop ax
    verr ax
    jz ecsFs
;
    xor ax,ax
    
ecsFs:
    mov fs,ax
;
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
;    
    cli
    mov di,OFFSET ps_wakeup_list
    call InsertCoreBlock
    sti

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
    pop ax
    verr ax
    jz lcsFs
;
    xor ax,ax
    
lcsFs:
    mov fs,ax
;
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
    call cs:lock_kernel_section_proc
    push ds
    mov ds,fs:ps_curr_thread
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
    mov cx,task_sel
    mov ds,cx
    mov cx,cs
    mov es,cx
    mov edi,OFFSET cond_section_timeout
    mov bx,fs:ps_curr_thread
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
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
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
    push ds
    push bx
;    
    mov bx,fs:ps_curr_thread
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
    pop ax
    verr ax
    jz cecsFs
;
    xor ax,ax
    
cecsFs:
    mov fs,ax
;
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
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

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
    mov ax,fs:ps_curr_thread
    cmp ax,ds:[ebx].us_owner
    je eusDone
;
    call LockCore
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
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_user_section_proc
;
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi    
    jmp LoadThread

eusUnlock:
    call cs:unlock_user_section_proc
    call UnlockCore
    
eusDone:
    mov ax,core_data_sel
    mov fs,ax
    mov ax,fs:ps_curr_thread
    mov ds:[ebx].us_owner,ax
    inc ds:[ebx].us_count

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
    pop ebx
    pop ax

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
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
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

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
    mov ax,fs:ps_curr_thread
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
;
    cli
    mov di,OFFSET ps_wakeup_list
    call InsertCoreBlock
    sti

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
    pop ebx
    pop ax

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
leave_user_section      ENDP
    
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
    mov ax,task_sel
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
    mov ax,task_sel
    mov ds,ax
    LeaveSection ds:futex_section
    pop ds

acquire_no_sect:
    call LockCore
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
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    call InsertBlock32
    call cs:unlock_futex_proc
;
    mov es:p_sleep_sel,ds
    mov es:p_sleep_offset,edi    
    jmp LoadThread

acquire_take:
    str ax
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
    mov di,es:p_tss_sel
    pop esi
    pop es
;
    mov es:[esi].fs_owner,di
    mov es:[esi].fs_counter,1
    call cs:unlock_futex_proc    
;
    push es    
    mov es,cx
    cli
    mov di,OFFSET ps_wakeup_list
    call InsertCoreBlock
    sti
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
;           NAME:           get_thread
;
;           DESCRIPTION:    Get current thread control block
;
;           PARAMETERS:         AX          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread      PROC far
    push ds
    mov ax,task_sel
    verr ax
    jz get_thread_norm

get_thread_pre_tasking:
    mov ax,virt_thread_sel
    jmp get_thread_done

get_thread_norm:
    mov ax,core_data_sel
    mov ds,ax
    mov ax,ds:ps_curr_thread

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
    mov ax,ds:ps_curr_thread    
    pop ds
    retf32
get_thread_pr   ENDP

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
    mov ax,ds:ps_id
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
    mov edx,ds:ps_msb_tics
    mov eax,ds:ps_lsb_tics
    cmp edx,ds:ps_msb_tics
    jne gclCoreRetry
;
    mov ds,ds:ps_null_thread

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
    mov edx,ds:ps_msb_tics
    mov eax,ds:ps_lsb_tics
    cmp edx,ds:ps_msb_tics
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
    mov ax,core_data_sel
    mov fs,ax
    mov ax,fs:ps_sel
    mov fs,ax
    mov es,cx
    cli
    mov di,OFFSET ps_wakeup_list
    call InsertCoreBlock
    sti
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
    mov cx,task_sel
    mov ds,cx
    mov cx,fs:ps_curr_thread
    mov bx,cs
    mov es,bx
    mov edi,OFFSET wake_until
    xor bx,bx
    StartTimer
;
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    mov es:p_sleep_sel,SLEEP_SEL_WAIT
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
    mov es,fs:ps_curr_thread
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
    mov cx,task_sel
    mov ds,cx
    mov cx,es
    mov bx,cs
    mov es,bx
    mov edi,OFFSET wake_until
    xor bx,bx
    StartTimer
;    
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    mov es:p_sleep_sel,SLEEP_SEL_WAIT
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
    mov es,fs:ps_curr_thread
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
    mov cx,task_sel
    mov ds,cx
    mov cx,es
    mov bx,cs
    mov es,bx
    mov edi,OFFSET wake_until
    xor bx,bx
    StartTimer
;    
    mov es,fs:ps_curr_thread
    mov fs:ps_curr_thread,0
;
    mov es:p_sleep_sel,SLEEP_SEL_WAIT
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

Wait_state      DB 'Wait',0
Ready_state     DB 'Ready',0
Signal_state    DB 'Signal',0
Debug_state     DB 'Debug',0

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
    cmp bx,fs:ps_curr_thread
    je check_curr_ok
;
    cmp bx,fs:ps_null_thread
    je check_null_ok
;   
    mov ax,fs
    mov fs,bx
    cmp ax,fs:p_sleep_sel
    jne check_cpu_next
;
    mov eax,fs:p_sleep_offset
    cmp ax,OFFSET ps_wakeup_list
    je check_wakeup_ok
    jmp check_cpu_ready_ok

check_cpu_next:
    inc dx
    add si,2
    loop check_cpu_loop
    jmp check_not_cpu

check_curr_ok:
    mov si,OFFSET Run_state
    jmp check_copy_id
    
check_null_ok:
    mov si,OFFSET Ready_cpu_state
    jmp check_copy_id

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
    mov al,'0'
    add al,dl
    stos byte ptr es:[edi]
    xor al,al
    stos byte ptr es:[edi]
;
    mov ds,bx
    mov cx,ds:p_tss_cs
    mov edx,ds:p_tss_eip   
    clc
    jmp check_done
    
check_not_cpu:
    mov fs,bx
    mov ax,fs:p_sleep_sel
    cmp ax,SLEEP_SEL_WAIT
    jne check_not_wait
;
    mov si,OFFSET Wait_state
    jmp check_copy_zero

check_not_wait:
    cmp ax,SLEEP_SEL_SIGNAL
    jne check_not_signal
;
    mov si,OFFSET Signal_state
    jmp check_copy_zero
    
check_not_signal:
    cmp ax,task_sel
    jne check_not_task
;
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
    mov cx,ds:p_tss_cs
    mov edx,ds:p_tss_eip   
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
    mov bx,kernel_patch_sel
    mov ds,bx
    cli
    mov ds:time_diff,eax
    mov ds:time_diff+4,edx
    sti
    pop bx
    pop ds
    retf32
update_time     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateProcHandle
;
;           DESCRIPTION:    Create a process handle
;
;       PARAMETERS:     AX      Lib selector
;               DX      Process descriptor
;
;       RETURNS:    BX      Process handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_proc_handle_name DB 'Create Process Handle',0

create_proc_handle      PROC far
    push ds
    push cx
    mov cx,SIZE proc_handle_seg
    AllocateHandle
    mov [ebx].ph_lib_sel,ax
    mov [ebx].ph_proc_sel,dx
    mov [ebx].hh_sign,PROCESS_HANDLE
    mov bx,[ebx].hh_handle
;
    mov ds,dx
    inc ds:pd_ref_count
;       
    pop cx
    pop ds
    retf32
create_proc_handle  Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DerefProcHandle
;
;           DESCRIPTION:    Deref a process handle
;
;       PARAMETERS:     BX      Process handle
;
;       RETURNS:    AX      Lib selector
;               DX      Process descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

deref_proc_handle_name  DB 'Deref Process Handle',0

deref_proc_handle       PROC far
    push ds
    push ebx
;    
    mov ax,PROCESS_HANDLE
    DerefHandle
    jc deref_proc_handle_done
;
    mov ax,[ebx].ph_lib_sel
    mov dx,[ebx].ph_proc_sel
    clc

deref_proc_handle_done:
    pop ebx
    pop ds
    retf32
deref_proc_handle   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeProcHandle
;
;           DESCRIPTION:    Free a process handle
;
;       PARAMETERS:     BX      Process handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_proc_handle_name   DB 'Free Process Handle',0

free_proc_handle    PROC far
    push ds
    push ax
    push ebx
    push dx
;    
    mov ax,PROCESS_HANDLE
    DerefHandle
    jc free_proc_handle_done
;
    mov dx,[ebx].ph_proc_sel
    FreeHandle
;       
    mov ds,dx
    sub ds:pd_ref_count,1
    jnz free_proc_handle_done
;
    push es
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem    
    pop es
    clc

free_proc_handle_done:
    pop dx
    pop ebx
    pop ax
    pop ds
    retf32
free_proc_handle    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetProcExitCode
;
;           DESCRIPTION:    Get process exit code
;
;       PARAMETERS:     BX      Process handle
;
;       RETURNS:    AX      Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_proc_exit_code_name DB 'Get Process Exit Code',0

get_proc_exit_code      PROC far
    push ds
    push ebx
;    
    mov ax,PROCESS_HANDLE
    DerefHandle
    mov ax,-1
    jc get_proc_exit_done
;
    mov ds,[ebx].ph_proc_sel
    mov ax,ds:pd_exit_code
    clc

get_proc_exit_done:
    pop ebx
    pop ds
    retf32
get_proc_exit_code   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForProcEnd
;
;           DESCRIPTION:    Start a wait for process end event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_proc_end PROC far
    push ds
    push eax
;
    ClearSignal
    mov ax,es:pew_proc_sel
    mov ds,ax
    mov ds:pd_wait,es
;
    mov ax,ds:pd_proc_sel
    or ax,ax
    jnz start_wait_done
;
    mov ds:pd_wait,0
    SignalWait

start_wait_done:    
    pop eax
    pop ds
    ret
start_wait_for_proc_end Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForProcEnd
;
;           DESCRIPTION:    Stop a wait for process end event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_proc_end  PROC far
    push ds
    push eax
;
    mov ax,es:pew_proc_sel
    mov ds,ax
    mov ds:pd_wait,0
;    
    pop eax
    pop ds
    ret
stop_wait_for_proc_end Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DummyClearProcEnd
;
;           DESCRIPTION:    Clear process end event
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_clear_proc_end    PROC far
    ret
dummy_clear_proc_end Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsProcEndIdle
;
;           DESCRIPTION:    Check if proc end is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_proc_end_idle    PROC far
    push ds
    push eax
;
    mov ax,es:pew_proc_sel
    mov ds,ax
    mov ax,ds:pd_proc_sel
    or ax,ax
    clc
    jne is_idle_done
;
    stc

is_idle_done:    
    pop eax
    pop ds
    ret
is_proc_end_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForProcEnd
;
;           DESCRIPTION:    Add a wait for process end
;
;           PARAMETERS:         AX      Process handle
;               BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_proc_end_name      DB 'Add Wait For Process End',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_proc_end,      kernel_code
aw1 DD OFFSET stop_wait_for_proc_end,       kernel_code
aw2 DD OFFSET dummy_clear_proc_end,     kernel_code
aw3 DD OFFSET is_proc_end_idle,         kernel_code

add_wait_for_proc_end   PROC far
    push ds
    push es
    push eax
    push dx
    push edi
;
    push bx
    mov bx,ax
    DerefProcHandle
    pop bx
    jc add_wait_done
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE proc_end_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;    
    mov es:pew_proc_sel,dx

add_wait_done:
    pop edi
    pop dx
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_proc_end   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_THREAD_BLOCK
;
;           DESCRIPTION:    Allocate thread control block
;
;           PARAMETERS:         ES          Thread control block
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_thread_block   PROC near
    mov eax,SIZE thread_seg
    AllocateSmallGlobalMem
    mov es:p_thread_sel,es
;
    mov bx,es
    GetSelectorBaseSize
    AllocateGdt
    CreateTssSelector
    mov es:p_tss_sel,bx
    ret
allocate_thread_block   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_THREAD_BLOCK
;
;           DESCRIPTION:    Init thread content
;
;           PARAMETERS:         ES          Thread
;                           DX          Priority
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread_block       PROC near
    GetThread
    mov ds,ax
;
    push fs
    mov ax,ds:p_process_sel
    mov fs,ax
    inc fs:ms_thread_count
    mov es:p_process_sel,ax
    pop fs
;
    mov es:p_cli_spinlock,0
    mov es:p_sti_spinlock,0
    mov ax,ds:p_app_sel
    mov es:p_app_sel,ax
    mov ax,ds:p_ldt_sel
    mov es:p_ldt_sel,ax
    mov ax,ds:p_lib_sel
    mov es:p_lib_sel,ax
    mov eax,ds:p_debug_proc
    mov es:p_debug_proc,eax
    mov es:p_signal,0
    mov es:p_parent_switch,0
    mov es:p_wait_list,0
    mov es:p_kill,0
    mov es:p_ref_count,0
    mov es:p_is_waiting,0
    mov es:p_flags,0
;
    add dx,dx
    mov es:p_prio,dx
    xor eax,eax
    mov es:p_msb_tics,eax
    mov es:p_lsb_tics,eax
    mov es:p_vm_deb_sel,ax
    mov es:p_vm_deb_offs,eax
    mov es:p_pm_deb_sel,ax
    mov es:p_pm_deb_offs,eax
    mov es:p_events,0
;
    mov es:p_sleep_sel,0
    mov es:p_sleep_offset,0
    push ds
    mov ax,system_data_sel
    mov ds,ax
    cli
    mov ax,ds:next_pid
    mov es:p_id,ax
    inc ax
    mov ds:next_pid,ax
    sti
    pop ds
    ret
init_thread_block       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROCESS_BLOCK
;
;           DESCRIPTION:    Init process content
;
;           PARAMETERS:         ES          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


init_process_block      PROC near
    push es
    mov eax,SIZE process_seg
    AllocateSmallGlobalMem
    mov es:ms_virt_flags,7200h
    mov es:ms_wait_sti,0
    mov es:ms_thread_count,1
    mov bx,es
;       
    mov eax,SIZE proc_descr_seg
    AllocateSmallGlobalMem
    mov es:pd_proc_sel,bx
    mov es:pd_exit_code,0
    mov es:pd_ref_count,1
    mov es:pd_wait,0
;       
    push ds
    mov ax,es
    mov ds,ax
    InitSection ds:pd_section
    pop ds
;    
    mov ax,es
    mov es,bx
    mov es:ms_pd_sel,ax
;       
    pop es
    mov es:p_process_sel,bx
;
    push es
    mov eax,SIZE app_seg
    AllocateSmallGlobalMem
    mov bx,es
    mov es:app_next,0
;
    pop es
    mov es:p_app_sel,bx
;
    mov es:p_ldt_sel,0
    ret
init_process_block      ENDP


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
;           NAME:           INIT_DEFAULT_TSS
;
;           DESCRIPTION:    Setup default TSS contents
;
;           PARAMETERS:         DS          TSS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_default_tss    PROC near
    mov ds:p_tss_back_link,0
    mov ds:p_tss_t,0
    mov ds:p_tss_bitmap,OFFSET p_tss_io_bitmap
;       
    push es
    push eax
    push bx
    push ecx
    mov eax,stack0_size
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector32
    mov ds:p_tss_esp0,stack0_size
    mov ds:p_tss_ess0,bx
    mov es,bx
    mov es:[0],bx
    pop ecx
    pop bx
    pop eax
    pop es
;
    add edx,stack0_size
    mov ds:p_stack0_top,edx
;    
    xor edx,edx
    mov ds:p_tss_esp1,edx
    mov ds:p_tss_ess1,dx
    mov ds:p_tss_esp2,edx
    mov ds:p_tss_ess2,dx
;
    mov edx,cr3
    mov es:p_cr3,edx
    mov ds:p_tss_cr3,edx
;
    mov edx,[ebp].cr_offs
    mov ds:p_tss_eip,edx
;
    mov edx,[ebp].cr_eax
    mov ds:p_tss_eax,edx
;
    mov edx,[ebp].cr_ecx
    mov ds:p_tss_ecx,edx
;
    mov edx,[ebp].cr_edx
    mov ds:p_tss_edx,edx
;    
    mov edx,[ebp].cr_ebx
    mov ds:p_tss_ebx,edx
;
    mov edx,[ebp].cr_ebp
    mov ds:p_tss_ebp,edx
;
    mov edx,[ebp].cr_esi
    mov ds:p_tss_esi,edx
;    
    mov edx,[ebp].cr_edi
    mov ds:p_tss_edi,edx
;    
    mov dx,[ebp].cr_seg
    mov ds:p_tss_cs,dx
;    
    sldt dx
    mov ds:p_tss_ldt,dx
;
; dr0 - dr7
;
    xor edx,edx
    mov ds:p_tss_dr0,edx
    mov ds:p_tss_dr1,edx
    mov ds:p_tss_dr2,edx
    mov ds:p_tss_dr3,edx
    mov ds:p_tss_dr7,edx
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
    mov ds:p_fault_code,0
; 
    push ds
    push es
    push si
    push di    
;
    mov ax,ds
    mov es,ax
    mov di,OFFSET p_tss_io_bitmap
    mov cx,40h
    mov ax,io_bitmap_sel
    mov ds,ax
    xor si,si
    rep movsw
;
    pop di
    pop si
    pop es
    pop ds        
    ret
init_default_tss    ENDP


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
    push fs
;
    GetThread
    mov fs,ax
    mov fs,fs:p_app_sel
;
    mov dx,[ebp].cr_flags
    or dx,200h
    and dx,NOT 7000h
    movzx edx,dx
    mov ds:p_tss_eflags,edx
;
    mov es:p_free_proc,0
    mov es:p_free_proc+4,0
    mov ax,[ebp].cr_seg
    test ax,3
    jz init_kernel_tss
;
    mov eax,fs:app_init_thread_proc
    or eax,fs:app_init_thread_proc+4
    jz init_prot_tss_default
;
    mov eax,fs:app_free_thread_proc
    mov es:p_free_proc,eax
    mov eax,fs:app_free_thread_proc+4
    mov es:p_free_proc+4,eax
;
    mov eax,[ebp].cr_stack
    mov es:p_stack_sel,0
    call fword ptr fs:app_init_thread_proc
    pop fs
    ret

init_prot_tss_default:
    push es
    mov eax,[ebp].cr_stack
    AllocateLocalMem
    sub eax,6
    mov ds:p_tss_esp,eax
    mov ds:p_tss_ss,es
    mov es:[eax+4],dx
    mov word ptr es:[eax+2],term_code_sel
    mov word ptr es:[eax],0
    mov bx,es
    pop es
    mov es:p_stack_sel,bx
    jmp init_prot_tss_com

init_kernel_tss:
    push es
    mov ax,ds:p_tss_ess0
    mov ds:p_tss_ss,ax
    mov bx,stack0_size - 6
    mov es,ax
    mov es:[bx+4],dx
    mov es:[bx+2],cs
    mov word ptr es:[bx],OFFSET terminate_thread
    pop es
    mov ds:p_tss_esp,stack0_size - 6
    mov es:p_stack_sel,0

init_prot_tss_com:
    mov ax,[ebp].cr_es
    mov ds:p_tss_es,ax
;
    mov ax,[ebp].cr_ds
    mov ds:p_tss_ds,ax
;    
    mov ax,[ebp].cr_fs
    mov ds:p_tss_fs,ax
;    
    mov ax,[ebp].cr_gs
    mov ds:p_tss_gs,ax    
    pop fs
    ret
init_prot_tss   ENDP


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
    mov ds:p_tss_ss,ax
    pop eax
    sub eax,6
    mov ds:p_tss_esp,eax
    mov dx,[ebp].cr_flags
    movzx edx,dx 
    or edx,20200h
    and dx,NOT 7000h
    mov ds:p_tss_eflags,edx
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
    mov ds:p_tss_es,ax
;
    mov ax,[ebp].cr_ds
    SelectorToSegment
    mov ds:p_tss_ds,ax
;
    mov ax,[ebp].cr_fs
    SelectorToSegment
    mov ds:p_tss_fs,ax
;
    mov ax,[ebp].cr_gs
    SelectorToSegment
    mov ds:p_tss_gs,ax
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
;                           AH              Mode, 0=PM, 1=VM
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
    call allocate_thread_block
    mov dx,[ebp].cr_prio
    call init_thread_block
    mov ax,es
    mov ds,ax
    call init_default_tss
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
;
    pop ax
    verr ax
    jz crp_zero_gs
    xor ax,ax
crp_zero_gs:
    mov gs,ax
;
    pop ax
    verr ax
    jz crp_zero_fs
    xor ax,ax
crp_zero_fs:
    mov fs,ax
;
    pop ax
    verr ax
    jz crp_zero_es
    xor ax,ax
crp_zero_es:
    mov es,ax
;
    pop ax
    verr ax
    jz crp_zero_ds
    xor ax,ax
crp_zero_ds:
    mov ds,ax
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
;           NAME:           TERMINATE_THREAD
;
;           DESCRIPTION:    Terminate thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

terminate_thread_name   DB 'Terminate Thread',0

terminate_thread:
    SimSti
    GetThread
    mov ds,ax
    mov al,ds:p_parent_switch
    or al,al
    jz terminate_focus_ok
;
    SetFocus

terminate_focus_ok:
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
    mov ds,ds:p_process_sel
    sub ds:ms_thread_count,1
    jz terminate_proc
;
    GetThread
    mov ds,ax
    mov eax,ds:p_free_proc
    or eax,ds:p_free_proc+4
    jz terminate_app_handled
;
    call fword ptr ds:p_free_proc

terminate_app_handled:
    NotifyThreadExit
    jmp cleanup_thread

terminate_proc:
    GetThread
    mov ds,ax
    mov ds,ds:p_process_sel
    mov ds,ds:ms_pd_sel
    sub ds:pd_ref_count,1
    jz terminate_free_pd
;
    EnterSection ds:pd_section
;    
    mov ds:pd_proc_sel,0
    mov ax,ds:pd_wait
    or ax,ax
    jz terminate_proc_sig_done
;
    mov es,ax
    SignalWait

terminate_proc_sig_done:   
    LeaveSection ds:pd_section
    xor ax,ax
    mov ds,ax
    jmp terminate_pd_done    

terminate_free_pd:
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem    

terminate_pd_done:
    NotifyThreadExit
    call free_handle_process
    NotifyProcessExit
    jmp cleanup_process


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROCESS_TSS
;
;           DESCRIPTION:    Init process TSS
;
;           PARAMETERS:         DS          TSS
;                           ES          Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_tss    PROC near
    mov eax,OFFSET create_process_callback
    mov ds:p_tss_eip,eax
    mov ds:p_tss_cs,cs
    mov ax,ds:p_tss_ess0
    mov ds:p_tss_ss,ax
    mov eax,stack0_size
    mov ds:p_tss_esp,eax
;
    mov ax,[ebp].cr_mode
    test ax,1
    jz init_tss_prot_iopl
    mov ax,[ebp].cr_flags
    or dx,200h
    and dx,NOT 7000h
    movzx edx,dx
    mov ds:p_tss_eflags,eax
    jmp init_tss_iopl_done

init_tss_prot_iopl:
    mov ax,[ebp].cr_flags
    or ax,200h
    and ax,NOT 7000h
    movzx eax,ax
    mov ds:p_tss_eflags,eax

init_tss_iopl_done:     
    xor ax,ax
    mov ds:p_tss_es,ax
    mov ds:p_tss_ds,ax
    mov ds:p_tss_fs,ax
    mov ds:p_tss_gs,ax
    ret
init_process_tss    ENDP


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
    mov ds:p_tss_ds,es
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
;           PARAMETERS:         AL              Priority
;                           AH              Mode, 0=PM, 1=VM
;                           ECX             Stack size
;                           DS:SI       Start address
;                           ES:DI       Thread name
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
    movzx esi,si
    movzx edi,di
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
    mov es:p_debug_proc,0
    call init_process_block
    mov ax,es
    mov ds,ax
    call init_default_tss
    NotifyCreateProcess
    mov ax,[ebp].cr_mode
    test ax,1
    jz create_mod_prot
    call init_virt_thread
    jmp create_mod_tss_done
create_mod_prot:
    call init_prot_thread
create_mod_tss_done:
    call init_process_tss
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
    pop ax
    verr ax
    jz crm_zero_gs
    xor ax,ax
crm_zero_gs:
    mov gs,ax
;
    pop ax
    verr ax
    jz crm_zero_fs
    xor ax,ax
crm_zero_fs:
    mov fs,ax
;
    pop ax
    verr ax
    jz crm_zero_es
    xor ax,ax
crm_zero_es:
    mov es,ax
;
    pop ax
    verr ax
    jz crm_zero_ds
    xor ax,ax
crm_zero_ds:
    mov ds,ax
    popf
    pop ebp
    add esp,30
    retf32
create_process  ENDP


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
    xor eax,eax
    mov eax,ds:cm_stack
    AllocateLocalMem
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
init_prot_callback_frame    ENDP

    
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
    GetThread
    mov fs,ax
    push ds
    NotifyProcessCreated
    pop ds
    mov es,ds:cm_process
    mov ax,ds:cm_mode
    test ax,1
    jz create_callback_prot
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
;


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

null_name       DB 'Null 0',0

create_first_thread       PROC near
    xor eax,eax
    mov es:p_prio,ax
    mov es:p_msb_tics,eax
    mov es:p_lsb_tics,eax
    mov es:p_vm_deb_sel,ax
    mov es:p_vm_deb_offs,eax
    mov es:p_pm_deb_sel,ax
    mov es:p_pm_deb_offs,eax
    mov es:p_debug_proc,0
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
    mov ax,system_data_sel
    mov ds,ax
    cli
    mov ax,ds:next_pid
    mov es:p_id,ax
    inc ax
    mov ds:next_pid,ax
    sti
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
    mov ds:p_tss_dr0,edx
    mov ds:p_tss_dr1,edx
    mov ds:p_tss_dr2,edx
    mov ds:p_tss_dr3,edx
    mov ds:p_tss_dr7,edx
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
    mov ds:p_fault_code,0
;
    mov ds:p_tss_cr3,edx
    mov ds:p_tss_eax,edx
    mov ds:p_tss_ecx,edx
    mov ds:p_tss_edx,edx
    mov ds:p_tss_ebx,edx
    mov ds:p_tss_ebp,edx
    mov ds:p_tss_esi,edx
    mov ds:p_tss_edi,edx    
    mov ds:p_tss_es,dx
    mov ds:p_tss_ds,dx
    mov ds:p_tss_fs,dx
    mov ds:p_tss_gs,dx
    mov ds:p_tss_ldt,0
    mov ds:p_tss_t,0
    mov ds:p_tss_bitmap,OFFSET p_tss_io_bitmap
    mov ds:p_tss_back_link,0
;
    mov eax,OFFSET init_first_process_callback
    mov ds:p_tss_eip,eax
    mov ds:p_tss_cs,cs
;
    mov di,OFFSET p_tss_io_bitmap
    xor ax,ax
    mov cx,40h
    rep stosw
;
    push es
    mov eax,stack0_size
    AllocateSmallGlobalMem
    mov ax,es
    pop es    
    mov ds:p_tss_ss,ax
    mov eax,stack0_size
    mov ds:p_tss_esp,eax
;
    pushfd
    pop eax
    and ax,NOT 7000h
    mov ds:p_tss_eflags,eax
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
    mov ax,0002h
    push ax
    popf    
;
    mov ax,virt_thread_sel
    mov es,ax
    call allocate_thread_block
    call create_first_thread
    call init_process_block
    mov ax,es
    mov ds,ax
    call init_first_tss
    NotifyCreateProcess
    mov ds:p_tss_es,fs
    GetCore
    mov fs:ps_null_thread,es
    mov es:p_cli_spinlock,0
    mov es:p_sti_spinlock,0
    ret
init_first_process      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_double_fault
;
;           DESCRIPTION:    Init double fault handler
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_double_fault       Proc near
    push ds
    push es
    pushad
;    
    mov eax,400h
    AllocateSmallLinear
;
    mov bx,double_tss_sel
        mov ecx,400h
        CreateTssSelector
;
    mov bx,double_tss_data_sel
    mov ecx,400h
    CreateDataSelector16
    mov ds,bx
    mov es,bx
;    
    xor di,di
    mov cx,100h
    xor eax,eax
    rep stosd
;
    mov eax,200h
    AllocateSmallGlobalMem
    mov ds:c_tss_ss,es
    mov ds:c_tss_esp,200h
    mov eax,cr3
    mov ds:c_tss_cr3,eax
;
    mov ds:c_tss_bitmap, OFFSET c_tss_bitmap_space
    mov bx,3FFh
    mov byte ptr ds:[bx],-1    
;
    mov ds:c_tss_cs,cs
    mov ds:c_tss_eip,OFFSET double_fault
;
        mov ax,idt_sel
        mov ds,ax
        mov bx,8 * 8
        mov word ptr [bx],0
        mov word ptr [bx+2],double_tss_sel
        mov byte ptr [bx+4],0
        mov byte ptr [bx+5],85h
        mov word ptr [bx+6],0    
;
    popad
    pop es
    pop ds
        ret
init_double_fault       Endp
    
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
    call init_double_fault
    NotifyInitProcess
    call start_processor_null_threads
    NotifyInitTasking
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
;           NAME:           INIT_TASK
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task

init_task       PROC near
    pusha
    push ds
;
    mov bx,task_sel
    mov eax,SIZE task_seg
    AllocateFixedSystemMem
;
    mov ax,task_sel
    mov ds,ax
    mov ds:term_thread_list,0
    mov ds:term_proc_list,0
    mov ds:list_lock,0
    mov ds:tlb_spinlock,0
    mov ds:tlb_list,0
    mov ds:tlb_block_spinlock,0
    mov ds:tlb_block_list,0
;
    mov eax,TLB_LINEAR_SIZE
    AllocateBigLinear
    mov ds:tlb_curr_linear,edx    
    mov ds:tlb_remain_linear,eax
;
    InitSection ds:futex_section
    mov ds:global_spinlock,0
    xor ax,ax
    mov bx,OFFSET global_ptab
    mov ds:global_prio_act,bx
;
    mov cx,256

glob_ptab_init:
    mov ds:[bx],ax
    add bx,2
    loop glob_ptab_init
;
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
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov si,OFFSET start_tasking
    mov di,OFFSET start_tasking_name
    xor cl,cl
    mov ax,start_tasking_nr
    RegisterOsGate
;
    mov si,OFFSET create_core
    mov di,OFFSET create_core_name
    xor cl,cl
    mov ax,create_core_nr
    RegisterOsGate
;
    mov si,OFFSET get_core
    mov di,OFFSET get_core_name
    xor cl,cl
    mov ax,get_core_nr
    RegisterOsGate
;
    mov si,OFFSET get_core_count
    mov di,OFFSET get_core_count_name
    xor cl,cl
    mov ax,get_core_count_nr
    RegisterOsGate
;
    mov si,OFFSET get_core_num
    mov di,OFFSET get_core_num_name
    xor cl,cl
    mov ax,get_core_num_nr
    RegisterOsGate
;
    mov si,OFFSET run_ap_core
    mov di,OFFSET run_ap_core_name
    xor cl,cl
    mov ax,run_ap_core_nr
    RegisterOsGate
;
    mov si,OFFSET preempt_expired
    mov di,OFFSET preempt_expired_name
    xor cl,cl
    mov ax,preempt_expired_nr
    RegisterOsGate
;
    mov si,OFFSET timer_expired
    mov di,OFFSET timer_expired_name
    xor cl,cl
    mov ax,timer_expired_nr
    RegisterOsGate
;
    mov si,OFFSET preempt_timer_expired
    mov di,OFFSET preempt_timer_expired_name
    xor cl,cl
    mov ax,preempt_timer_expired_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_flush_tlb
    mov edi,OFFSET notify_flush_tlb_name
    xor cl,cl
    mov ax,notify_flush_tlb_nr
    RegisterOsGate
;
    mov esi,OFFSET flush_tlb
    mov edi,OFFSET flush_tlb_name
    xor cl,cl
    mov ax,flush_tlb_nr
    RegisterOsGate
;
    mov si,OFFSET irq_schedule
    mov di,OFFSET irq_schedule_name
    xor cl,cl
    mov ax,irq_schedule_nr
    RegisterOsGate
;
    mov si,OFFSET get_scheduler_lock_counter
    mov di,OFFSET get_scheduler_lock_counter_name
    xor cl,cl
    mov ax,get_scheduler_lock_counter_nr
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
    mov si,OFFSET create_proc_handle
    mov di,OFFSET create_proc_handle_name
    xor cl,cl
    mov ax,create_proc_handle_nr
    RegisterOsGate
;
    mov si,OFFSET deref_proc_handle
    mov di,OFFSET deref_proc_handle_name
    xor cl,cl
    mov ax,deref_proc_handle_nr
    RegisterOsGate
;
    mov si,OFFSET free_proc_handle
    mov di,OFFSET free_proc_handle_name
    xor dx,dx
    mov ax,free_proc_handle_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_proc_exit_code
    mov di,OFFSET get_proc_exit_code_name
    xor dx,dx
    mov ax,get_proc_exit_code_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET add_wait_for_proc_end
    mov di,OFFSET add_wait_for_proc_end_name
    xor dx,dx
    mov ax,add_wait_for_proc_end_nr
    RegisterBimodalUserGate
;
    mov bx,OFFSET create_thread16
    mov si,OFFSET create_thread32
    mov di,OFFSET create_thread_name
    mov dx,virt_seg_in
    mov ax,create_thread_nr
    RegisterUserGate
;
    mov si,OFFSET terminate_thread
    mov di,OFFSET terminate_thread_name
    xor dx,dx
    mov ax,terminate_thread_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET create_process
    mov di,OFFSET create_process_name
    xor cl,cl
    mov ax,create_process_nr
    RegisterOsGate
;
    mov si,OFFSET soft_reset
    mov di,OFFSET soft_reset_name
    xor dx,dx
    mov ax,soft_reset_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET hard_reset
    mov di,OFFSET hard_reset_name
    xor dx,dx
    mov ax,hard_reset_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET power_failure
    mov di,OFFSET power_failure_name
    xor dx,dx
    mov ax,power_failure_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_break
    mov di,OFFSET debug_break_name
    xor dx,dx
    mov ax,debug_break_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_thread_pr
    mov di,OFFSET get_thread_name
    xor dx,dx
    mov ax,get_thread_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_core_id
    mov di,OFFSET get_core_id_name
    xor dx,dx
    mov ax,get_core_id_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_cpu_time
    mov di,OFFSET get_cpu_time_name
    xor dx,dx
    mov ax,get_cpu_time_nr
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
    mov si,OFFSET get_core_load
    mov di,OFFSET get_core_load_name
    xor dx,dx
    mov ax,get_core_load_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_core_duty
    mov di,OFFSET get_core_duty_name
    xor dx,dx
    mov ax,get_core_duty_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_exc_break
    mov di,OFFSET debug_exc_break_name
    xor cl,cl
    mov ax,debug_exc_break_nr
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
    mov si,OFFSET cond_enter_section
    mov di,OFFSET cond_enter_section_name
    xor cl,cl
    mov ax,cond_enter_section_nr
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
    mov si,OFFSET debug_run
    mov di,OFFSET debug_run_name
    xor dx,dx
    mov ax,debug_run_nr
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
    mov edi,OFFSET set_code_break_name
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
    mov ebx,OFFSET acquire_futex16
    mov esi,OFFSET acquire_futex32
    mov edi,OFFSET acquire_futex_name
    mov dx,virt_es_in
    mov ax,acquire_futex_nr
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
    mov edi,OFFSET check_list
    HookState
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
    mov edx,gdt_linear
    CreateCore
;
    pop ds
    popa
    ret
init_task       ENDP

code    ENDS

    END

