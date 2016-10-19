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
; CRSHOW.ASM
; Crash register dump
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\proc.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\gate.def
INCLUDE kdebug.inc

data    SEGMENT byte public 'DATA'

map_linear   DD ?
map_sel      DW ?
map_spinlock DW ?

mon_sel      DW ?

data    ENDS

    .386p

code    SEGMENT byte public use32 'CODE'

    assume cs:code
    
    extrn init_monitor:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartupMonitor
;
;           DESCRIPTION:    Startup monitor
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartupMonitor:
    mov ax,system_data_sel
    mov ds,ax

smSpin:
    mov ax,1
    xchg ax,ds:shut_spinlock
    or ax,ax
    jz smEnter
;
    jmp smWait

smEnter:
    DisableAllIrq
    SetupNmiCoreDump
    SetupLongNmiCoreDump
;
    xor ax,ax

smNmiLoop:    
    GetCoreNumber
    jc smNmiDone
;
    test fs:ps_flags,PS_FLAG_NMI
    jnz smNmiNext
;        
    push ax
    mov al,2
    SendInt
    pop ax
        
smNmiNext:
    inc ax
    jmp smNmiLoop

smNmiDone:
    GetCore
;    
    mov ax,SEG data
    mov ds,ax

smLoop:
    jmp smLoop

smWait:
    jmp smWait
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartCoreDump
;
;           DESCRIPTION:    Start core dump
;
;           RETURNS:        NC
;                               DS:EBP  Cpu registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_core_dump_name    DB 'Start Core Dump', 0
    
start_core_dump Proc far
    push fs
    push eax
    push ebx
;   
    int 3
    GetCore
    test fs:ps_flags,PS_FLAG_NMI
    jnz scdFail
;
    or fs:ps_flags,PS_FLAG_NMI    
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:mon_sel
    or ax,ax
    jz scdFail
;
    mov ds,ax
    mov bx,fs:ps_id
    cmp bx,ds:mon_core_count
    jae scdFail
;
    movzx ebx,bx
    shl ebx,3
    add ebx,OFFSET mon_core_regs
    mov ebp,ds:[ebx].mc_regs_linear
    mov ax,flat_sel
    mov ds,ax
    clc
    jmp scdDone

scdFail:
    stc

scdDone:
    pop ebx
    pop eax
    pop fs
    ret
start_core_dump Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyCoreDump
;
;           DESCRIPTION:    Notify core dump
;
;           PARAMETERS:     DS:EBP      Cpu registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_core_dump_name    DB 'Notify Core Dump', 0
    
notify_core_dump:
    GetCore
    mov ds:[ebp].debug_core_sel,fs
    mov ax,fs:ps_id
    mov ds:[ebp].debug_core_id,ax
;
    mov eax,cr0
    mov ds:[ebp].reg_cr0,eax
;
    mov eax,cr2
    mov ds:[ebp].reg_cr2,eax
;
    mov eax,cr3
    mov ds:[ebp].reg_cr3,eax
;
    mov eax,cr4
    mov ds:[ebp].reg_cr4,eax
;
    mov eax,dr0
    mov ds:[ebp].reg_dr0,eax               
;
    mov eax,dr1
    mov ds:[ebp].reg_dr1,eax               
;
    mov eax,dr2
    mov ds:[ebp].reg_dr2,eax               
;
    mov eax,dr6
    mov ds:[ebp].reg_dr6,eax               
;
    mov eax,dr7
    mov ds:[ebp].reg_dr7,eax               
;
    mov eax,dr0
    mov ds:[ebp].reg_dr0,eax               
;
    sgdt fword ptr ds:[ebp].temp_size
    movzx eax,ds:[ebp].temp_size
    mov ds:[ebp].reg_gdt.d_limit,eax
    mov eax,ds:[ebp].temp_base
    mov ds:[ebp].reg_gdt.d_base,eax
;
    sidt fword ptr ds:[ebp].temp_size
    movzx eax,ds:[ebp].temp_size
    mov ds:[ebp].reg_idt.d_limit,eax
    mov eax,ds:[ebp].temp_base
    mov ds:[ebp].reg_idt.d_base,eax
;    
    mov ds:[ebp].reg_ldt.d_limit,0
    mov ds:[ebp].reg_ldt.d_base,0
;    
    mov ds:[ebp].reg_tr.d_limit,0
    mov ds:[ebp].reg_tr.d_base,0
    jmp StartupMonitor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setup_crash
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_crash     Proc near
    GetCoreCount
    movzx ecx,cx
    mov eax,ecx
    shl eax,3
    mov edi,OFFSET mon_core_regs
    add eax,edi
    AllocateSmallGlobalMem
    mov es:mon_core_count,cx
    xor si,si

scCoreLoop:    
    push ecx
    mov es:[edi].mc_core_linear,0    
    mov es:[edi].mc_regs_linear,0    
    mov ax,si
    GetCoreNumber
    jc scCoreNext
;
    mov bx,fs
    GetSelectorBaseSize
    mov es:[edi].mc_core_linear,edx
;
    mov eax,SIZE cpu_struc
    AllocateBigLinear    
    mov es:[edi].mc_regs_linear,edx

scCoreNext:
    pop ecx
    add edi,8
    inc si
    loop scCoreLoop
;    
    mov eax,1000h
    AllocateBigLinear
    mov es:mon_map_linear,edx
;   
    mov ax,SEG data
    mov ds,ax
    mov ds:mon_sel,es
;     
    mov bx,es
    call init_monitor
    ret
setup_crash     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           test_pr
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_name  DB 'Crash Thread', 0

deb_val DB 11

deb_code:
    mov al,cs:deb_val

test_pr:
    sti
    mov ax,41h
    EnableFocus
;
    int 3    
;    
    CrashGate
    mov esp,0
    push eax
    int 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_crash_tasking
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crash_tasking

init_crash_tasking    Proc near
    push ds
    pushad
;
    call setup_crash
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET test_pr
    mov edi,OFFSET test_name
    mov ecx,stack0_size
    mov ax,26
    CreateProcess
;        
    popad
    pop ds
    ret
init_crash_tasking    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          init_crash_driver
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crash_driver

init_crash_driver    Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:map_spinlock,0
    mov ds:mon_sel,0
;
    mov eax,1000h
    AllocateBigLinear
    mov ds:map_linear,edx    
    xor ebx,ebx
    mov eax,67h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov ds:map_sel,bx    
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov esi,OFFSET start_core_dump
    mov edi,OFFSET start_core_dump_name
    xor cl,cl
    mov ax,start_core_dump_nr
    RegisterOsGate
;    
    mov esi,OFFSET notify_core_dump
    mov edi,OFFSET notify_core_dump_name
    xor cl,cl
    mov ax,notify_core_dump_nr
    RegisterOsGate
    ret
init_crash_driver       Endp

code    ENDS

    END
