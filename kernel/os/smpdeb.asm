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
INCLUDE proc.inc
INCLUDE smpdeb.inc

data    SEGMENT byte public 'DATA'

core_list    DW ?
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
;               NAME:           Nmi
;
;               DESCRIPTION:    NMI handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi_gs  EQU 48
nmi_fs  EQU 44
nmi_ds  EQU 40
nmi_es  EQU 36
nmi_ss  EQU 32
nmi_esp EQU 28
nmi_efl EQU 24
nmi_cs  EQU 20
nmi_eip EQU 16
nmi_sfs EQU 14
nmi_sgs EQU 12
nmi_eax EQU 8
nmi_ebx EQU 4
nmi_ebp EQU 0

nmi_handler:
    push fs
    push gs
    push eax
    push ebx
    push ebp
    mov bp,sp
;    
    GetProcessor
    test fs:ps_flags,PS_FLAG_NMI
    jnz nmi_ret
;
    or fs:ps_flags,PS_FLAG_NMI    
    mov ax,fs
    mov bx,SEG data    
    mov fs,bx
    mov bx,OFFSET core_list
    mov bx,fs:[bx]
nmi_core_loop:
    mov gs,bx
    cmp ax,gs:cs_proc_sel
    je nmi_core_found
;
    mov bx,fs:[bx].cs_next
    jmp nmi_core_loop    

nmi_core_found:
    call SaveCore
    mov eax,[bp].nmi_ebp
    mov gs:cs_ebp,eax
    mov eax,[bp].nmi_ebx
    mov gs:cs_ebx,eax
    mov eax,[bp].nmi_eax
    mov gs:cs_eax,eax
    mov eax,[bp].nmi_eip
    mov gs:cs_eip,eax
    mov ax,[bp].nmi_cs
    mov gs:cs_cs,ax
    mov ebx,[bp].nmi_efl
    mov gs:cs_eflags,ebx
    test ebx,20000h
    jnz nmi_v86
;    
    mov bx,[bp].nmi_sfs
    mov gs:cs_fs,bx
    mov bx,[bp].nmi_sgs
    mov gs:cs_gs,bx
;    
    and al,3
    or al,al
    jz nmi_block
;
    mov eax,[bp].nmi_esp
    mov gs:cs_esp,eax
    mov ax,[bp].nmi_ss
    mov gs:cs_ss,ax
    jmp nmi_block

nmi_v86:
    mov eax,[bp].nmi_esp
    mov gs:cs_esp,eax
    mov ax,[bp].nmi_ss
    mov gs:cs_ss,ax
    mov ax,[bp].nmi_ds
    mov gs:cs_ds,ax
    mov ax,[bp].nmi_es
    mov gs:cs_es,ax
    mov ax,[bp].nmi_fs
    mov gs:cs_fs,ax
    mov ax,[bp].nmi_gs
    mov gs:cs_gs,ax

nmi_block:
    jmp nmi_block

nmi_ret:
    pop ebp
    pop ebx
    pop eax
    pop gs
    pop fs
    iretd
   
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
    pop eax
    ret
SaveCore Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddDebugCore
;
;           DESCRIPTION:    Add a new debug core
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_debug_core_name     DB 'Add Debug Core', 0

add_debug_core  Proc far
    push es
    push fs
    push gs
    pushad
;    
    mov eax,1000h
    AllocateGlobalMem
    mov ax,es
    mov gs,ax    
    mov gs:cs_usel,flat_sel
    mov gs:cs_uoffs,0
;
    GetProcessor
    mov gs:cs_proc_sel,fs    
;
    call SaveCore
;
    mov ax,SEG data
    mov es,ax
    mov ax,es:core_list
    mov gs:cs_next,ax
    mov es:core_list,gs
    mov es:curr_core,gs
;
    popad
    pop gs
    pop fs
    pop es
    ret
add_debug_core  Endp    

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
    mov gs,ds:core_list

handle_loop:
    hlt
    call GetKey
    jc handle_next
;    
    test ah,80h
    jnz handle_next
;    
    cmp al,'N'
    jne handle_show
;
    mov ax,gs:cs_next
    or ax,ax
    jnz handle_next_set
;
    mov ax,ds:core_list

handle_next_set:
    mov gs,ax

handle_show:
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
    mov si,OFFSET add_debug_core
    mov di,OFFSET add_debug_core_name
    xor cl,cl
    mov ax,add_debug_core_nr
    RegisterOsGate
;
    mov di,OFFSET init_thread
;    HookInitTasking
;
    mov al,2
    xor bl,bl
    mov esi,OFFSET nmi_handler
    CreateIntGateSelector
;
    AddDebugCore
;
    ret
init    ENDP

code    ENDS

    END init
