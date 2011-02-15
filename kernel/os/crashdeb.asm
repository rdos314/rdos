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
; CRASHDEB.ASM
; Crash debugger/monitor module
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
INCLUDE crashdeb.inc

data    SEGMENT byte public 'DATA'

core_list       DW ?
curr_core       DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn InitCrashKeyboardIrq:near
    extrn UpdateCrashKeyboardMode:near
    extrn GetCrashKey:near

    extrn InitCrashShow:near
    extrn ShowCrashCore:near
   
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
    mov bx,fs:core_list

nmi_core_loop:
    mov gs,bx
    cmp ax,gs:cs_proc_sel
    je nmi_core_found
;
    mov bx,gs:cs_next
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
    jz nmi_kernel
;
    mov eax,[bp].nmi_esp
    mov gs:cs_esp,eax
    mov ax,[bp].nmi_ss
    mov gs:cs_ss,ax
    jmp nmi_block

nmi_kernel:
    movzx eax,bp
    add ax,nmi_esp
    mov gs:cs_esp,eax
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
;       NAME:           abort_cores
;
;       DESCRIPTION:    Stop all cores except self
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abort_cores:
    GetProcessor
    or fs:ps_flags,PS_FLAG_NMI    
    mov dx,fs
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:core_list

abort_loop:    
    or ax,ax
    jz nmi_block
;
    mov gs,ax
    mov ax,gs:cs_proc_sel
    cmp ax,dx
    jz abort_next
;    
    mov fs,ax
    SendNmi

abort_next:
    mov ax,gs:cs_next
    jmp abort_loop

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           int 82
;
;       DESCRIPTION:    Shutdown interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int_gs  EQU 48
int_fs  EQU 44
int_ds  EQU 40
int_es  EQU 36
int_ss  EQU 32
int_esp EQU 28
int_efl EQU 24
int_cs  EQU 20
int_eip EQU 16
int_sfs EQU 14
int_sgs EQU 12
int_eax EQU 8
int_ebx EQU 4
int_ebp EQU 0

shutdown_handler:
    push fs
    push gs
    push eax
    push ebx
    push ebp
    mov bp,sp
;    
    GetProcessor
    mov ax,fs
    mov bx,SEG data    
    mov fs,bx
    mov bx,fs:core_list

int_core_loop:
    mov gs,bx
    cmp ax,gs:cs_proc_sel
    je int_core_found
;
    mov bx,gs:cs_next
    jmp int_core_loop    

int_core_found:
    call SaveCore
    mov eax,[bp].int_ebp
    mov gs:cs_ebp,eax
    mov eax,[bp].int_ebx
    mov gs:cs_ebx,eax
    mov eax,[bp].int_eax
    mov gs:cs_eax,eax
    mov eax,[bp].int_eip
    mov gs:cs_eip,eax
    mov ax,[bp].int_cs
    mov gs:cs_cs,ax
    mov ebx,[bp].int_efl
    mov gs:cs_eflags,ebx
    test ebx,20000h
    jnz int_v86
;    
    mov bx,[bp].int_sfs
    mov gs:cs_fs,bx
    mov bx,[bp].int_sgs
    mov gs:cs_gs,bx
;    
    and al,3
    or al,al
    jz int_kernel
;
    mov eax,[bp].int_esp
    mov gs:cs_esp,eax
    mov ax,[bp].int_ss
    mov gs:cs_ss,ax
    jmp abort_cores

int_kernel:
    movzx eax,bp
    add ax,int_esp
    mov gs:cs_esp,eax
    jmp abort_cores
    
int_v86:
    mov eax,[bp].int_esp
    mov gs:cs_esp,eax
    mov ax,[bp].int_ss
    mov gs:cs_ss,ax
    mov ax,[bp].int_ds
    mov gs:cs_ds,ax
    mov ax,[bp].int_es
    mov gs:cs_es,ax
    mov ax,[bp].int_fs
    mov gs:cs_fs,ax
    mov ax,[bp].int_gs
    mov gs:cs_gs,ax
    jmp abort_cores
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           int 83
;
;       DESCRIPTION:    Shutdown gate interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gt_fs  EQU 28
gt_efl EQU 24
gt_cs  EQU 20
gt_eip EQU 16
gt_sgs EQU 12
gt_eax EQU 8
gt_ebx EQU 4
gt_ebp EQU 0

shutdown_gate_handler:
    push fs
    push gs
    push eax
    push ebx
    push ebp
    mov bp,sp
;    
    GetProcessor
    mov ax,fs
    mov bx,SEG data    
    mov fs,bx
    mov bx,fs:core_list

gate_core_loop:
    mov gs,bx
    cmp ax,gs:cs_proc_sel
    je gate_core_found
;
    mov bx,gs:cs_next
    jmp gate_core_loop    

gate_core_found:
    call SaveCore
    mov bx,[bp].gt_ebp
;
    mov eax,ss:[bx].vm_eax
    mov gs:cs_eax,eax
    mov eax,ss:[bx].vm_ebx
    mov gs:cs_ebx,eax
;
    mov eax,ebp
    mov ax,ss:[bx]
    mov gs:cs_ebp,eax
;       
    mov eax,ss:[bx].vm_eflags
    mov gs:cs_eflags,eax
;    
    mov ax,ss:[bx].vm_cs
    mov gs:cs_cs,ax
;
    mov eax,ss:[bx].vm_eip
    mov gs:cs_eip,eax
;
    mov ax,bx
    add ax,vm_esp
    movzx eax,ax
    mov gs:cs_esp,eax
;       
    mov ax,ss:[bx].pm_ds
    mov gs:cs_ds,ax
;    
    mov bx,[bp].gt_fs
    mov gs:cs_fs,bx
;
    mov bx,[bp].gt_sgs
    mov gs:cs_gs,bx
    jmp abort_cores
   
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
;           NAME:           SmpDebug
;
;           DESCRIPTION:    SMP debug procedure
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_smp_debug_name    DB 'Start SMP Debug', 0

start_smp_debug:
    mov ax,250
    call DelayMs
;    
    call InitCrashShow
    call InitCrashKeyboardIrq
    sti
;
    mov ax,SEG data
    mov ds,ax
    mov gs,ds:core_list

handle_loop:
    hlt
    call GetCrashKey
    jc handle_next
;    
    test ah,80h
    jnz handle_next
;
    cmp al,'A'
    je handle_abort
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
    call ShowCrashCore
    jmp handle_next

handle_abort:
    mov ax,ds:core_list

handle_abort_loop:    
    or ax,ax
    jz handle_show
;
    mov gs,ax
    mov fs,gs:cs_proc_sel
    SendNmi
;
    mov ax,gs:cs_next
    jmp handle_abort_loop

handle_next:        
    call UpdateCrashKeyboardMode
    jmp handle_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SmpDebThread
;
;           DESCRIPTION:    SMP debug thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

smp_deb_thread_name     DB 'SMP debug', 0

smp_deb_thread:
    int 3
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:core_list

smp_abort_loop:    
    or ax,ax
    jz smp_abort_done
;
    mov gs,ax
    mov fs,gs:cs_proc_sel
    SendNmi
;
    mov ax,gs:cs_next
    jmp smp_abort_loop

smp_abort_done:
    int 3 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_task
;
;           DESCRIPTION:    Init task
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_task     Proc far
    push ds
    push es
    pushad
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET smp_deb_thread
    mov di,OFFSET smp_deb_thread_name
    mov ax,1
    mov cx,256
    CreateThread
;
    popad
    pop es
    pop ds
    ret
init_task     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init_crashdeb
;
;           DESCRIPTION:    Module initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crashdeb
    
init_crashdeb    PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov al,2
    xor bl,bl
    mov esi,OFFSET nmi_handler
    CreateIntGateSelector
;
    mov al,82h
    mov esi,OFFSET shutdown_handler
    CreateIntGateSelector
;
    mov al,83h
    mov esi,OFFSET shutdown_gate_handler
    CreateIntGateSelector
;
    mov esi,OFFSET start_smp_debug
    mov edi,OFFSET start_smp_debug_name
    xor cl,cl
    mov ax,start_smp_debug_nr
    RegisterOsGate
;
    mov esi,OFFSET add_debug_core
    mov edi,OFFSET add_debug_core_name
    xor cl,cl
    mov ax,add_debug_core_nr
    RegisterOsGate
;
;    mov di,OFFSET init_task
;    HookInitTasking
;
    AddDebugCore
;
    ret
init_crashdeb    ENDP

code    ENDS

    END
