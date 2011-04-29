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
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE proc.inc
INCLUDE ..\handle.inc

MAX_CORES   = 64

TIME_SYNC_RESET = 0
TIME_SYNC_IDLE  = 1
TIME_SYNC_WAIT  = 2
TIME_SYNC_READ  = 3

thread_balance_struc    STRUC

tb_thread_sel       DW ?
tb_pad              DW ?
tb_elapsed          DD ?

thread_balance_struc    ENDS

core_balance_struc  STRUC

cb_thread_sel       DW ?
cb_pad              DW ?
cb_elapsed          DD ?

core_balance_struc  ENDS

multicore_data_seg    STRUC

time_sync_state     DW ?
sync_core_count     DW ?

core_count          DW ?
core_arr            DW MAX_CORES DUP(?)

thread_base_tics    DD 256 DUP(?)

thread_balance_arr  DB MAX_CORES * SIZE thread_balance_struc DUP(?)
core_balance_arr    DB MAX_CORES * SIZE core_balance_struc DUP(?)

multicore_data_seg    ENDS

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
;           NAME:           ResetThreadList
;
;           DESCRIPTION:    Reset thread list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetThreadList Proc near
    push eax
    push bx
    push cx
;
    mov cx,MAX_CORES
    mov bx,OFFSET thread_balance_arr
    xor eax,eax

rtlLoop:    
    mov [bx].tb_thread_sel,ax
    mov [bx].tb_pad,ax
    mov [bx].tb_elapsed,eax
    add bx,SIZE thread_balance_struc
    loop rtlLoop
;
    pop cx
    pop bx
    pop eax
    ret
ResetThreadList Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddThreadList
;
;           DESCRIPTION:    Add to thread list
;
;           PARAMETERS:     ES  Thread
;                           EAX Elapsed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddThreadList Proc near
    pusha
;
    mov cx,MAX_CORES
    mov bx,OFFSET thread_balance_arr

atlFindLoop:    
    mov dx,ds:[bx].tb_thread_sel
    or dx,dx
    jz atlInsert
;
    cmp eax,ds:[bx].tb_elapsed
    ja atlInsert
;        
    add bx,SIZE thread_balance_struc
    loop atlFindLoop
;
    jmp atlDone 

atlInsert:
    mov dx,es

atlInsertLoop:    
    push ds:[bx].tb_thread_sel
    push ds:[bx].tb_elapsed
    mov ds:[bx].tb_thread_sel,dx
    mov ds:[bx].tb_elapsed,eax
    pop eax
    pop dx
    or dx,dx
    jz atlDone
;    
    add bx,SIZE thread_balance_struc
    loop atlInsertLoop

atlDone:    
    popa
    ret
AddThreadList Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetCoreList
;
;           DESCRIPTION:    Reset core list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetCoreList Proc near
    push eax
    push bx
    push cx
;
    mov cx,MAX_CORES
    mov bx,OFFSET core_balance_arr
    xor eax,eax

rclLoop:    
    mov [bx].cb_thread_sel,ax
    mov [bx].cb_pad,ax
    mov [bx].cb_elapsed,eax
    add bx,SIZE core_balance_struc
    loop rclLoop
;
    pop cx
    pop bx
    pop eax
    ret
ResetCoreList Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddCoreList
;
;           DESCRIPTION:    Add to core list
;
;           PARAMETERS:     ES  Thread
;                           EAX Elapsed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCoreList Proc near
    pusha
;
    mov cx,MAX_CORES
    mov bx,OFFSET core_balance_arr

aclFindLoop:    
    mov dx,ds:[bx].cb_thread_sel
    or dx,dx
    jz aclInsert
;
    cmp eax,ds:[bx].cb_elapsed
    ja aclInsert
;        
    add bx,SIZE core_balance_struc
    loop aclFindLoop
;
    jmp aclDone 

aclInsert:
    mov dx,es

aclInsertLoop:    
    push ds:[bx].cb_thread_sel
    push ds:[bx].cb_elapsed
    mov ds:[bx].cb_thread_sel,dx
    mov ds:[bx].cb_elapsed,eax
    pop eax
    pop dx
    or dx,dx
    jz aclDone
;    
    add bx,SIZE core_balance_struc
    loop aclInsertLoop

aclDone:    
    popa
    ret
AddCoreList Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateBalancerLists
;
;           DESCRIPTION:    Create elapsed time list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBalancerLists Proc near
    GetThread
    mov bp,ax
;    
    mov ax,task_sel
    mov ds,ax
;         
    call ResetThreadList
    call ResetCoreList
;    
    mov cx,256
    mov si,OFFSET thread_arr
    mov di,OFFSET thread_base_tics

cbGetLoop:
    mov bx,es:[si]
    or bx,bx
    jnz cbHandle
;
    xor eax,eax
    mov ds:[di],eax
    jmp cbGetNext

cbHandle:
    cmp bx,bp
    je cbGetNext
;    
    push es
    mov es,bx
    mov eax,es:p_lsb_tics
    mov edx,eax
    sub edx,ds:[di]
    jnc cbInRange
;
    xor edx,edx

cbInRange:    
    mov ds:[di],eax
;
    mov fs,es:p_core_sel
    cmp bx,fs:ps_null_thread
    je cbInsertCore

cbInsertThread: 
    mov eax,edx
    cmp eax,120
    jb cbAddPop
;    
    call AddThreadList
    jmp cbAddPop

cbInsertCore:
    mov eax,edx   
    test fs:ps_flags,PS_FLAG_ACTIVE
    jz cbAddPop
;    
    call AddCoreList

cbAddPop:
    pop es

cbGetNext:
    add si,2
    add di,4
    loop cbGetLoop
    ret
CreateBalancerLists Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CenterCoreList
;
;           DESCRIPTION:    Center core list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CenterCoreList Proc near
    pusha
;
    mov cx,MAX_CORES
    mov bx,OFFSET core_balance_arr
    xor eax,eax
    xor dx,dx

cclSumLoop:
    mov si,ds:[bx].cb_thread_sel
    or si,si
    jz cclSumDone
;
    inc dx
    add eax,ds:[bx].cb_elapsed
;    
    add bx,SIZE core_balance_struc
    loop cclSumLoop

cclSumDone:
    movzx ecx,dx
    xor edx,edx
    div ecx
;
    mov cx,MAX_CORES
    mov bx,OFFSET core_balance_arr

cclBiasLoop:
    mov si,ds:[bx].cb_thread_sel
    or si,si
    jz cclBiasDone
;
    sub ds:[bx].cb_elapsed,eax
    add bx,SIZE core_balance_struc
    loop cclBiasLoop

cclBiasDone:    
    popa
    ret
CenterCoreList Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCoreIndex
;
;           DESCRIPTION:    Get core index
;
;           PARAMETERS:     AX      Core sel
;
;           RETURNS:        DI      Core structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCoreIndex  Proc near
    push es
    push cx
;   
    mov es,ax
    mov ax,es:ps_null_thread
;
    mov cx,MAX_CORES
    mov di,OFFSET core_balance_arr

gciLoop:
    cmp ax,ds:[di].cb_thread_sel
    je gciFound
;
    add di,SIZE core_balance_struc
    loop gciLoop
    stc
    jmp gciDone

gciFound:
    clc

gciDone:
    pop cx
    pop es
    ret
GetCoreIndex  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PickThread
;
;           DESCRIPTION:    Pick thread to switch
;
;           RETURNS:        ES      Thread
;                           FS      New core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PickThread  Proc near
    mov eax,ds:core_balance_arr.cb_elapsed
    cmp eax,2 * 1193
    jb ptDone
;    
    mov cx,MAX_CORES
    mov bx,OFFSET thread_balance_arr

ptLoop:
    mov ax,ds:[bx].tb_thread_sel
    or ax,ax
    stc
    jz ptDone
;
    mov es,ax
    mov ax,es:p_core_sel
    call GetCoreIndex
    jc ptNext
;
    mov eax,ds:[di].cb_elapsed
    test eax,80000000h    
    jz ptNext
;
    neg eax
    mov edx,ds:[bx].tb_elapsed
    shr edx,1
    add edx,ds:[bx].tb_elapsed
    shr edx,1
    cmp edx,eax
    ja ptNext
;
    int 3
    clc    

ptNext:    
    add bx,SIZE thread_balance_struc
    loop ptLoop
;
    stc

ptDone:    
    ret
PickThread  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Balancer thread
;
;           DESCRIPTION:    Balances threads among available cores
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

balancer_thread_name  DB 'Core Balancer', 0

balancer_thread_pr:
    mov ax,500
    WaitMilliSec
;    
    mov ax,task_sel
    mov ds,ax    
;
    mov ax,system_data_sel
    mov es,ax
;    
    mov cx,256
    mov si,OFFSET thread_arr
    mov di,OFFSET thread_base_tics

btInitLoop:
    xor eax,eax
    mov ax,es:[si]
    or ax,ax
    jz btInitNext
;
    mov fs,ax
    mov eax,fs:p_lsb_tics

btInitNext:
    mov ds:[di],eax
    add si,2
    add di,4
    loop btInitLoop
;    
    EnterTermThreadSection

btBalanceLoop:
    LeaveTermThreadSection
;    
    mov ax,100
    WaitMilliSec
;   
    EnterTermThreadSection
;
    mov ax,system_data_sel
    mov es,ax
;    
    call CreateBalancerLists
    call CenterCoreList
    call PickThread
    jc btBalanceLoop
;    
    int 3
;
    jmp btBalanceLoop    

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
    push ds
    push ax
    push bx
;
    mov bx,multicore_data_sel
    mov ds,bx    
;
    cmp ax,ds:core_count
    jae gpnFail
;
    mov bx,ax
    add bx,bx
    mov ax,ds:[bx].core_arr
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCore
;
;           DESCRIPTION:    Get current core #
;
;           RETURNS:        AX          Core ID
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
;           RETURNS:        CX          Number of cores
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_core_count_name   DB 'Get Core Count',0

get_core_count    PROC far
    push ds
    mov cx,multicore_data_sel
    mov ds,cx
    mov cx,ds:core_count
    pop ds
    retf32
get_core_count    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddCore
;
;           DESCRIPTION:    Add a core
;
;           PARAMETERS:     FS      Core sel
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_core_name   DB 'Add Core',0

add_core    PROC far
    push ds
    push ax
    push si
;    
    mov ax,multicore_data_sel
    mov ds,ax
    mov ax,ds:core_count
    mov si,ax
    add si,si
    mov ds:[si].core_arr,fs
    inc ds:core_count
    mov fs:ps_id,ax     
;
    pop si
    pop ax
    pop ds    
    retf32
add_core    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartMulticore
;
;           DESCRIPTION:    Startup multicore environment
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_multicore_name   DB 'Start Multicore',0

start_multicore    PROC far
    push ds
    push es
    pusha
;    
    mov ecx,200h
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET balancer_thread_pr
    mov di,OFFSET balancer_thread_name
    mov ax,10
    CreateThread
;
    StartApCores    
    call DoSyncTime
;
    popa
    pop es
    pop ds    
    retf32
start_multicore Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           sync_clock_int
;
;           DESCRIPTION:    Clock synchronization int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sync_clock_int:
    push ds
    push fs
    push eax
    push edx
;
    mov ax,task_sel
    mov ds,ax
    mov ax,core_data_sel
    mov fs,ax
    test fs:ps_flags,PS_FLAG_INIT_CLOCK
    jz sync_ack_core
;
    StartSysTimer
    StartClock
    and fs:ps_flags,NOT PS_FLAG_INIT_CLOCK

sync_ack_core:    
    cmp ds:time_sync_state,TIME_SYNC_WAIT
    jne sync_clock_end
;
    lock sub ds:sync_core_count,1

sync_clock_wait_read:
    cmp ds:time_sync_state,TIME_SYNC_WAIT
    je sync_clock_wait_read
;
    cmp ds:time_sync_state,TIME_SYNC_READ
    jne sync_clock_end
;    
    GetSystemTime

sync_clock_wait_idle:
    cmp ds:time_sync_state,TIME_SYNC_IDLE
    jne sync_clock_wait_idle    
;
    mov ax,system_data_sel
    mov ds,ax
    cli
    mov eax,ds:last_time
    sub eax,fs:ps_system_time
    add fs:ps_system_time,eax
    adc fs:ps_system_time+4,0    

sync_clock_end:
    SendEoi
;
    pop edx
    pop eax
    pop fs
    pop ds
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoSyncTime
;
;           DESCRIPTION:    Perform a clock synchronization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoSyncTime  Proc near
    push ds
    mov ax,task_sel
    mov ds,ax
;    
    mov ds:sync_core_count,0
    mov ds:time_sync_state,TIME_SYNC_WAIT
    mov dx,fs
;
    push fs
    push bx
    push cx
;
    mov cx,ds:core_count
    mov bx,OFFSET core_arr

sync_int_loop:
    mov ax,ds:[bx]
    cmp ax,dx
    je sync_int_next
;
    mov fs,ax
    test fs:ps_flags,PS_FLAG_ACTIVE
    jz sync_int_next
;    
    lock add ds:sync_core_count,1
    mov al,60h
    SendInt

sync_int_next:
    add bx,2
    loop sync_int_loop
;
    pop cx
    pop bx
    pop fs
;
    push cx
    mov cx,256

sync_wait_loop:
    mov ax,ds:sync_core_count
    or ax,ax
    jz sync_wait_done
;
    loop sync_wait_loop

sync_wait_done:
    pop cx
    cli
    mov ds:time_sync_state,TIME_SYNC_READ
    mov ax,system_data_sel
    mov ds,ax
    GetSystemTime
    mov ds:last_time,eax
    mov ds:last_time+4,edx
    mov ds:time_sync_state,TIME_SYNC_IDLE
;
    pop ds
    ret
DoSyncTime  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartTimeSync
;
;           DESCRIPTION:    Start time-sync process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartTimeSync    Proc near
    mov ax,multicore_data_sel
    mov ds,ax
    cmp ds:time_sync_state,TIME_SYNC_IDLE
    jne stsDone
;
    mov ax,system_data_sel
    mov ds,ax
    sub ecx,ds:last_time
    sub ecx,1193
    pop ds
    jc stsDone
;
    call DoSyncTime

stsDone:
    ret
StartTimeSync    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    Initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov al,60h
    mov bl,0
    mov esi,OFFSET sync_clock_int
    CreateIntGateSelector
;    
    mov si,OFFSET get_core_num
    mov di,OFFSET get_core_num_name
    xor cl,cl
    mov ax,get_core_num_nr
    RegisterOsGate
;
    mov si,OFFSET get_core_id
    mov di,OFFSET get_core_id_name
    xor dx,dx
    mov ax,get_core_id_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_core
    mov di,OFFSET get_core_name
    xor cl,cl
    mov ax,get_core_nr
    RegisterOsGate
;
    mov si,OFFSET add_core
    mov di,OFFSET add_core_name
    xor cl,cl
    mov ax,add_core_nr
    RegisterOsGate
;
    mov si,OFFSET start_multicore
    mov di,OFFSET start_multicore_name
    xor cl,cl
    mov ax,start_multicore_nr
    RegisterOsGate
;
    mov ds:time_sync_state,TIME_SYNC_RESET
    mov ds:core_count,0
    ret
init    Endp

code    ENDS

    END init

