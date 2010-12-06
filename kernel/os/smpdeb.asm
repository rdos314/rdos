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
; SMPDEB.ASM
; SMP debugger/monitor module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE irq.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE smpdeb.inc

data    SEGMENT byte public 'DATA'

curr_core    DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn InitKeyboardIrq:near
    extrn UpdateMode:near
    extrn GetKey:near

    extrn InitShow:near
    extrn ShowCore:near
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           DelayMs
;
;               DESCRIPTION:    Delay that does not use multitasking functions
;
;       PARAMETERS:     AX      Delay in ms
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DelayMs Proc near
    push ds
    push es
    pushad
;
    mov dx,system_data_sel
    mov ds,dx
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
    mov ax,apic_mem_sel
    mov es,ax    
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
;               NAME:           SaveCore
;
;               DESCRIPTION:    Save core state
;
;       PARAMETERS:     GS      Code selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveCore Proc near
    push eax
;    
    mov gs:cs_eax,eax
    mov gs:cs_ecx,ecx
    mov gs:cs_edx,edx
    mov gs:cs_ebx,ebx
    mov gs:cs_esp,esp
    mov gs:cs_ebp,ebp
    mov gs:cs_esi,esi
    mov gs:cs_edi,edi
;
    mov gs:cs_es,es
    mov gs:cs_cs,cs
    mov gs:cs_ss,ss
    mov gs:cs_ds,ds
    mov gs:cs_fs,fs
    mov gs:cs_gs,gs
;
    pushfd
    pop gs:cs_eflags
    mov gs:cs_eip, OFFSET SaveCore
;
    mov eax,cr0
    mov gs:cs_cr0,eax
    mov eax,cr2
    mov gs:cs_cr2,eax
    mov eax,cr3
    mov gs:cs_cr3,eax
    mov eax,cr4
    mov gs:cs_cr4,eax
;
    mov eax,dr0
    mov gs:cs_dr0,eax
    mov eax,dr1
    mov gs:cs_dr1,eax
    mov eax,dr2
    mov gs:cs_dr2,eax
    mov eax,dr3
    mov gs:cs_dr3,eax
    mov eax,dr7
    mov gs:cs_dr7,eax
;
    sldt gs:cs_ldt
    str gs:cs_tr
    sgdt fword ptr gs:cs_gdtr
    sidt fword ptr gs:cs_idtr
;
    GetProcessorId
    mov gs:cs_id,ax    
;        
    pop eax
    ret
SaveCore Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Smp_deb_thread
;
;           DESCRIPTION:    SMP debug thread (for test purposes)
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

smp_deb_thread_name     DB 'SMP debug', 0
start_smp_debug_name    DB 'Start SMP Debug', 0

start_smp_debug:
    mov ax,250
    call DelayMs
;    
    call InitShow
    call InitKeyboardIrq
    sti
;
    mov ax,SEG data
    mov ds,ax
    mov gs,ds:curr_core
    call SaveCore

handle_loop:
    hlt
    call GetKey
    jc handle_next
;    
    call ShowCore

handle_next:        
    call UpdateMode
    jmp handle_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_thread
;
;           DESCRIPTION:    Create thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread     Proc far
    push ds
    push es
    pushad
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET start_smp_debug
    mov di,OFFSET smp_deb_thread_name
    mov ax,1
    mov cx,256
    CreateThread
;
    popad
    pop es
    pop ds
init_thread     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Module initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET start_smp_debug
    mov di,OFFSET start_smp_debug_name
    xor cl,cl
    mov ax,start_smp_debug_nr
    RegisterOsGate
;
    mov di,OFFSET init_thread
;    HookInitTasking
;
    mov eax,1000h
    AllocateGlobalMem
    mov ax,es
    mov gs,ax    
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_core,gs
;
    ret
init    ENDP

code    ENDS

    END init
