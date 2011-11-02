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
; MP.ASM
; Multiprocessing module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\os\system.def
INCLUDE apic.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\proc.inc
INCLUDE ..\os\irq.inc
INCLUDE ..\os\acpi.def

INCLUDE ..\user.def
INCLUDE ..\user.inc

INCLUDE pci.inc

ipause   MACRO
    db 0F3h
    db 90h
    ENDM

MP_FLAG_MEM = 1
MP_FLAG_MSR = 2
MP_FLAG_TASK = 4


; PIC IRQs active low, edge triggered

apic_struc  STRUC

apic_type       DB ?
apic_len        DB ?

apic_struc  ENDS

apic_processor_struc  STRUC

ap_base         apic_struc <>

ap_acpi_id      DB ?
ap_apic_id      DB ?
ap_flags        DD ?

apic_processor_struc  ENDS

apic_ioapic_struc   STRUC

aio_base        apic_struc <>

aio_apic_id     DB ?
aio_resv        DB ?
aio_phys        DD ?
aio_int_base    DD ?

apic_ioapic_struc   ENDS

apic_override_struc STRUC

ao_base         apic_struc <>

ao_bus          DB ?
ao_source       DB ?
ao_int          DD ?
ao_flags        DW ?

apic_override_struc ENDS


apic_table  STRUC

apic_base       acpi_table <>

apic_phys       DD ?
apic_flags      DD ?

apic_entries    DB ?

apic_table  ENDS

ioapic_data_seg STRUC

ioapic_regsel       DB ?
ioapic_resv         DB 15 DUP(?)

ioapic_window       DD ?

ioapic_data_seg ENDS
        
data    SEGMENT byte public 'DATA'

mp_init_proc        DW ?
mp_startup_proc     DW ?
mp_int_proc         DW ?
mp_eoi_proc         DW ?
mp_stop_proc        DW ?
mp_isr_proc         DW ?

mp_thread           DW ?

mp_flags            DW ?

mp_processor_sign   DD ?
mp_proc             DW ?

isa_redir_arr       DD 16 DUP(?,?)

data    ENDS

.686p

code    SEGMENT byte public use16 'CODE'

irqmac  MACRO nr

msr_irq&nr:
    push ds
    push es
    push fs
    pushad
;
    EnterInt
    sti
;       
    mov ax,irq_sys_sel
    mov es,ax
    mov bx,OFFSET irq_arr + nr * SIZE irq_struc
    mov ax,word ptr es:[bx+4].user_handler
    or ax,ax
    jz msr_irq_default_error&nr
;
    mov ds,es:[bx].user_data
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET msr_irq_handle_done&nr
    push eax
    push es:[bx+4].user_handler
    push es:[bx].user_handler
    xor ax,ax
    mov es,ax
    retf32

msr_irq_default_error&nr:
;
; unmask IRQ here
;
    or es:bad_irqs, 1 SHL nr

msr_irq_handle_done&nr:
    cli
    xor eax,eax
    mov ecx,MSR_APIC_EOI
    wrmsr
    LeaveInt
;
    popad
    pop fs
    pop es
    pop ds
    iretd

mem_irq&nr:
    push ds
    push es
    push fs
    pushad
;
    EnterInt
    sti
;       
    mov ax,irq_sys_sel
    mov es,ax
    mov bx,OFFSET irq_arr + nr * SIZE irq_struc
    mov ax,word ptr es:[bx+4].user_handler
    or ax,ax
    jz mem_irq_default_error&nr
;
    mov ds,es:[bx].user_data
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET mem_irq_handle_done&nr
    push eax
    push es:[bx+4].user_handler
    push es:[bx].user_handler
    xor ax,ax
    mov es,ax
    retf32

mem_irq_default_error&nr:
;
; unmask IRQ here
;
    or es:bad_irqs, 1 SHL nr

mem_irq_handle_done&nr:
    cli
;    
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    popad
    pop fs
    pop es
    pop ds
    iretd

    ENDM

msimac  MACRO nr

msr_msi&nr:
    push ds
    push es
    push fs
    pushad
;
    EnterInt
    sti
;       
    mov ax,irq_sys_sel
    mov es,ax
    mov bx,OFFSET msi_arr + nr * SIZE irq_struc
    mov ax,word ptr es:[bx+4].user_handler
    or ax,ax
    jz msr_msi_default_error&nr
;
    mov ds,es:[bx].user_data
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET msr_msi_handle_done&nr
    push eax
    push es:[bx+4].user_handler
    push es:[bx].user_handler
    xor ax,ax
    mov es,ax
    retf32

msr_msi_default_error&nr:

msr_msi_handle_done&nr:
    cli
    xor eax,eax
    mov ecx,MSR_APIC_EOI
    wrmsr
    LeaveInt
;
    popad
    pop fs
    pop es
    pop ds
    iretd

mem_msi&nr:
    push ds
    push es
    push fs
    pushad
;
    EnterInt
    sti
;       
    mov ax,irq_sys_sel
    mov es,ax
    mov bx,OFFSET msi_arr + nr * SIZE irq_struc
    mov ax,word ptr es:[bx+4].user_handler
    or ax,ax
    jz mem_msi_default_error&nr
;
    mov ds,es:[bx].user_data
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET mem_msi_handle_done&nr
    push eax
    push es:[bx+4].user_handler
    push es:[bx].user_handler
    xor ax,ax
    mov es,ax
    retf32

mem_msi_default_error&nr:

mem_msi_handle_done&nr:
    cli
;    
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    popad
    pop fs
    pop es
    pop ds
    iretd

    ENDM
    

    assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Tables
;
;               DESCRIPTION:    GDT for protected mode initialization of AP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0000:0F80h

table_start:

gdt0:
    dw 0
    dd 0
    dw 0
gdt8:
    dw 28h-1
    dd 92000F80h
    dw 0
gdt10:
    dw 0FFFFh
    dd 9A001400h
    dw 0
gdt18:
    dw 0FFFFh
    dd 92000000h
    dw 0
gdt20:
    dw 0FFFFh
    dd 92001800h
    dw 0

table_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RealMode
;
;               DESCRIPTION:    Real mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0100:0000. It should contain no near jumps!

real_start:    
    cli
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    xor al,al
    out 71h,al
    jmp short $+2
;
    xor ax,ax
    mov ds,ax
;    
    mov bx,0F88h
    lgdt fword ptr ds:[bx]
;
    mov eax,cr0
    or al,1
    mov cr0,eax
;
    db 0EAh
    dw 0
    dw 10h

real_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ProtMode
;
;               DESCRIPTION:    Unpaged, protected mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01400. It should contain no near jumps!
    
prot_start:
    mov ax,18h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov sp,0F00h
;
    mov ax,20h
    mov es,ax
    mov eax,es:ap_cr3
    mov cr3,eax
;    
    db 66h
    lgdt fword ptr es:ap_gdt
;    
    db 66h
    lidt fword ptr es:ap_idt
;
    mov dx,es:ap_ss
;    
    mov eax,es:ap_cr0
    mov cr0,eax
;
    db 0EAh
    dw OFFSET ApInit
    dw SEG code

prot_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Paging
;
;               DESCRIPTION:    Paging variables for AP initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01800h. The code is relative to GDT selector 20h

page_struc  STRUC

ap_ss   DW ?
ap_cr0  DD ?
ap_cr3  DD ?
ap_cr4  DD ?
ap_gdt  DB 6 DUP(?)
ap_idt  DB 6 DUP(?)

page_struc  ENDS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ApInit
;
;               DESCRIPTION:    Paged entry-point for AP initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ApInit:
    mov eax,es:ap_cr4
    db 0Fh
    db 22h
    db 0E0h     ; mov cr4,eax
;    
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
;
    mov ss,dx
    mov sp,200h    
;
    mov ax,SEG data
    mov ds,ax
    mov eax,12345678h
    mov ds:mp_processor_sign,eax
    cli

ap_task_wait: 
    mov ax,ds:mp_flags
    test ax,MP_FLAG_TASK
    jz ap_task_wait
;    
    call InitApic

    GetApicId
    cmp edx,3
;    jae ap_crash
;    
    StartCore

stopl:
    jmp stopl

ap_crash:    

    StartCrashCore

apic_tab    DB 'APIC'
   
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
;       NAME:           HasApicMem
;
;       DESCRIPTION:    Check for APIC memory-based interface
;
;       RETURNS:        NC      Present        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_apic_mem_name    DB 'Has APIC Mem',0

has_apic_mem  Proc far
    clc
    retf32
has_apic_mem Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HasApicMsr
;
;       DESCRIPTION:    Check for APIC MSR-based interface
;
;       RETURNS:        NC      Present        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_apic_msr_name    DB 'Has APIC Msr',0

has_apic_msr  Proc far
    clc
    retf32
has_apic_msr Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetId
;
;               DESCRIPTION:    Get own ID, memory mode
;
;       RETURNS:        EDX     Apic ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_id_name    DB 'Get Apic ID',0

get_id_mem  Proc far
    push ds
    push ax
;    
    mov ax,apic_mem_sel
    mov ds,ax
    mov edx,ds:APIC_ID
    shr edx,24
;
    pop ax
    pop ds
    retf32
get_id_mem Endp

get_id_msr Proc far
    push eax
    push ecx
;
    mov ecx,MSR_APIC_ID
    rdmsr
    mov edx,eax
;
    pop ecx
    pop eax
    retf32
get_id_msr Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendEoi
;
;       DESCRIPTION:    Send EOI to APIC (only use for custom ISRs)
;
;       PARAMETERS:     AL      Int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_eoi_name    DB 'Send EOI',0

send_eoi_mem  Proc far
    push ds
    push eax
;    
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
;
    pop eax
    pop ds
    retf32
send_eoi_mem Endp

send_eoi_msr Proc far
    push eax
    push ecx
;
    xor eax,eax
    mov ecx,MSR_APIC_EOI
    wrmsr
;
    pop ecx
    pop eax
    retf32
send_eoi_msr Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendInitMem
;
;               DESCRIPTION:    Send init request using shared memory
;
;       PARAMETERS:     EDX     Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInitMem Proc near
    push ds
    push eax
    push edx
;    
    shl edx,24
    mov ax,apic_mem_sel
    mov ds,ax
    mov ds:APIC_ICR+10h,edx
;
    mov eax,0C500h
    mov ds:APIC_ICR,eax
;    
    mov ax,1
    call DelayMs
;
    mov eax,08500h
    mov ds:APIC_ICR,eax
;
    pop edx
    pop eax
    pop ds
    ret
SendInitMem Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendInitMsr
;
;               DESCRIPTION:    Send init request using MSRs
;
;       PARAMETERS:     EDX     Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInitMsr Proc near
    push eax
    push ecx
;
    mov eax,0C500h
    mov ecx,MSR_APIC_ICR
    wrmsr
;    
    mov ax,1
    call DelayMs
;
    mov eax,08500h
    mov ecx,MSR_APIC_ICR
    wrmsr
;
    pop ecx
    pop eax
    ret
SendInitMsr Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendNmiMem
;
;       DESCRIPTION:    Send NMI request using shared memory
;
;       PARAMETERS:     FS      Destination processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_nmi_name   DB 'Send NMI', 0

send_nmi_mem Proc far
    push ds
    push eax
    push edx
;    
    mov edx,fs:ps_apic
    shl edx,24
    mov ax,apic_mem_sel
    mov ds,ax
    mov ds:APIC_ICR+10h,edx
;
    mov eax,4400h
    mov ds:APIC_ICR,eax
;
    pop edx
    pop eax
    pop ds
    retf32
send_nmi_mem Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendNmiMsr
;
;       DESCRIPTION:    Send NMI request using MSRs
;
;       PARAMETERS:     FS      Destination processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_nmi_msr Proc far
    push eax
    push ecx
;
    mov edx,fs:ps_apic
    mov eax,4400h
    mov ecx,MSR_APIC_ICR
    wrmsr
;
    pop ecx
    pop eax
    retf32
send_nmi_msr Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendInit
;
;               DESCRIPTION:    Send init request
;
;       PARAMETERS:     EDX     Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInit Proc near
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    call ds:mp_init_proc
    mov ax,20
    call DelayMs
;
    pop ax
    pop ds    
    ret
SendInit Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendStartupMem
;
;               DESCRIPTION:    Send startup request using shared memory
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendStartupMem Proc near
    push ds
    push eax
    push ecx
    push edx
;    
    shl edx,24
    mov cx,apic_mem_sel
    mov ds,cx
    mov ds:APIC_ICR+10h,edx
;
    mov ah,46h
    movzx eax,ax
    mov ds:APIC_ICR,eax
;
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
SendStartupMem Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendStartupMsr
;
;               DESCRIPTION:    Send startup request using MSRs
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendStartupMsr Proc near
    push eax
    push ecx
;
    mov ah,46h
    movzx eax,ax
    mov ecx,MSR_APIC_ICR
    wrmsr
;
    pop ecx
    pop eax
    ret
SendStartupMsr Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendStartup
;
;               DESCRIPTION:    Send startup request
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendStartup Proc near
    push ds
    push ax
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    call ds:mp_startup_proc
    mov ax,1
    call DelayMs
;
    pop bx
    pop ax
    pop ds    
    ret
SendStartup Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendIntMem
;
;               DESCRIPTION:    Send int request using shared memory
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendIntMem Proc near
    pushf
    push ds
    push eax
    push ecx
    push edx
;    
    cli
    shl edx,24
    mov cx,apic_mem_sel
    mov ds,cx

simemLoop:
    mov ecx,ds:APIC_ICR
    test cx,1000h
    jz simemDo
;
    ipause
    jmp simemLoop

simemDo:    
    mov ds:APIC_ICR+10h,edx
;
    mov ah,40h
    movzx eax,ax
    mov ds:APIC_ICR,eax
;
    pop edx
    pop ecx
    pop eax
    pop ds
    popf
    ret
SendIntMem Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendIntMsr
;
;               DESCRIPTION:    Send int request using MSRs
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendIntMsr Proc near
    pushf
    push eax
    push ecx
;
    cli
    mov ah,40h
    movzx eax,ax
    push eax
    push edx

simsrLoop:
    mov ecx,MSR_APIC_ICR
    rdmsr
    test ax,1000h
    jz simsrDo
;    
    ipause
    jmp simsrLoop
    
simsrDo:
    pop edx    
    pop eax
;
    mov ecx,MSR_APIC_ICR
    wrmsr
;
    pop ecx
    pop eax
    popf
    ret
SendIntMsr Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendInt
;
;               DESCRIPTION:    Send int request
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInt Proc near
    push ds
    push ax
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    call ds:mp_int_proc
;
    pop bx
    pop ax
    pop ds    
    ret
SendInt Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendEoiMem
;
;               DESCRIPTION:    Send EOI using shared memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendEoiMem Proc near
    push ds
    push eax
;    
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
;
    pop eax
    pop ds
    ret
SendEoiMem Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendEoiMsr
;
;               DESCRIPTION:    Send EOI using MSRs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendEoiMsr Proc near
    push eax
    push ecx
;
    xor eax,eax
    mov ecx,MSR_APIC_EOI
    wrmsr
;
    pop ecx
    pop eax
    ret
SendEoiMsr Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   StartSysTimer
;
;               DESCRIPTION:    Start APIC timer
;
;               RETURNS:                EAX      Update tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_apic_timer_name    DB 'Start Apic Timer', 0

start_apic_mem_timer    Proc far
    push ds
    push es
    push bx
    push ecx
    push edx
    push esi
;
    mov ax,system_data_sel
    mov ds,ax
;
    mov edx,10000h
    xor eax,eax
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    div ecx
    mov esi,eax
;
    mov eax,80000000h
    mov bx,apic_mem_sel
    mov es,bx
    mov es:APIC_INIT_COUNT,eax    
    push fs
    GetCore
    pop fs
    mov eax,es:APIC_CURR_COUNT    
    neg eax
    add eax,80000000h
    mul esi
    add eax,eax
    adc edx,edx
    add eax,80000000h
    adc edx,0
;
    mov eax,80h
    mov es:APIC_TIMER,eax
    xor eax,eax
;
    pop esi
    pop edx
    pop ecx
    pop bx
    pop es
    pop ds
    retf32
start_apic_mem_timer  Endp

start_apic_msr_timer    Proc far
    push ds
    push ecx
    push edx
    push esi
;
    mov ax,system_data_sel
    mov ds,ax
;
    mov edx,10000h
    xor eax,eax
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    div ecx
    mov esi,eax
;
    mov eax,80000000h
    mov ecx,MSR_APIC_INIT_COUNT
    wrmsr
    push fs
    GetCore
    pop fs
    mov ecx,MSR_APIC_CURR_COUNT
    rdmsr
    neg eax
    add eax,80000000h
    mul esi
    add eax,eax
    adc edx,edx
    add eax,80000000h
    adc edx,0
;
    mov eax,80h
    mov ecx,MSR_APIC_TIMER
    wrmsr
    xor eax,eax
;
    pop esi
    pop edx
    pop ecx
    pop ds
    retf32
start_apic_msr_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopApicTimer
;
;       DESCRIPTION:    Stop APIC timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopApicTimerMem    Proc near
    push ds
    push eax
;
    mov ax,apic_mem_sel
    mov ds,ax
    mov eax,10000h
    mov ds:APIC_TIMER,eax
;
    pop eax
    pop ds
    ret
StopApicTimerMem  Endp

StopApicTimerMsr    Proc near
    push eax
    push ecx
;
    mov eax,10000h
    mov ecx,MSR_APIC_TIMER
    wrmsr
;
    pop ecx
    pop eax
    ret
StopApicTimerMsr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetIsr
;
;       DESCRIPTION:    Get ISR
;
;       RETURNS:        EAX     ISR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIsrMem    Proc near
    push ds
;
    mov ax,apic_mem_sel
    mov ds,ax
    mov eax,ds:APIC_ISR + 20h
;
    pop ds
    ret
GetIsrMem  Endp

GetIsrMsr    Proc near
    push ecx
;
    mov ecx,MSR_APIC_ISR + 2
    rdmsr
;
    pop ecx
    ret
GetIsrMsr  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ReloadSysTimer
;
;               DESCRIPTION:    Reload APIC timer
;
;               PARAMETERS:             AX      Reload tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reload_apic_timer_name    DB 'Reload Apic Timer', 0

reload_apic_mem_timer    Proc far
    push ds
    push eax
    push ecx
    push edx
;
    mov cx,system_data_sel
    mov ds,cx
;    
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    shl eax,16
    mul ecx
    inc edx
    mov ax,apic_mem_sel
    mov ds,ax    
    mov ds:APIC_INIT_COUNT,edx
;
    pop edx
    pop ecx
    pop eax
    pop ds
    retf32
reload_apic_mem_timer  Endp

reload_apic_msr_timer    Proc far
    push ds
    push eax
    push ecx
    push edx
;
    mov cx,system_data_sel
    mov ds,cx
;    
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    shl eax,16
    mul ecx
    inc edx
;
    mov eax,edx
    mov ecx,MSR_APIC_INIT_COUNT
    wrmsr
;
    pop edx
    pop ecx
    pop eax
    pop ds
    retf32
reload_apic_msr_timer  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:       GetPciIrq
;
;   DESCRIPTION:    Convert PCI int pin to int line
;
;   PARAMETERS:     BH          Bus
;                   BL          Device
;                   CH          Function
;
;   RETURNS:        AL      Line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pci_irq_name    DB 'Get Pci IRQ',0

get_pci_irq  Proc far
    mov cl,PCI_interrupt_line
    ReadPciByte
;    
    cmp al,10h
    jnc gpiOk
;    
    mov cl,PCI_interrupt_pin
    ReadPciByte
;
    add al,10h
    mov cl,bh
    shl cl,2
;    add al,cl
    cmp al,18h
    jc gpiOk
;
    int 3

gpiOk:    
    retf32
get_pci_irq  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartApCores
;
;       DESCRIPTION:    Start application cores
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_ap_cores_name    DB 'Start Ap Cores',0

start_ap_cores  Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    or ds:mp_flags,MP_FLAG_TASK
;
    mov ax,1
    call DelayMs
;    
    pop ax
    pop ds
    retf32
start_ap_cores  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendInt
;
;       DESCRIPTION:    Send int to processor
;
;       PARAMETERS:     FS      Processor selector
;                       AL      Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_int_name    DB 'Send Int',0

send_int  Proc far
    push ds
    push edx
;
    mov dx,SEG data
    mov ds,dx
    mov edx,fs:ps_apic
    call ds:mp_int_proc
;
    pop edx
    pop ds
    retf32
send_int  Endp

       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SetupMemGates
;
;               DESCRIPTION:    Set up shared memory gates for APIC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupMemGates   Proc near
    mov ax,apic_mem_sel
    mov ds,ax    
;
    mov eax,ds:APIC_LINT0
    test eax,10000h
    jnz smemgLint0Ok
;    
    and ah,7
    cmp ah,4
    je smemgLint0Disable
;
    cmp ah,7
    jne smemgLint0Ok

smemgLint0Disable:
    mov eax,10000h
    mov ds:APIC_LINT0,eax

smemgLint0Ok:
    mov eax,ds:APIC_LINT1
    test eax,10000h
    jnz smemgLint1Ok
;    
    and ah,7
    cmp ah,4
    je smemgLint1Disable
;
    cmp ah,7
    jne smemgLint1Ok

smemgLint1Disable:
    mov eax,10000h
    mov ds:APIC_LINT1,eax

smemgLint1Ok:
    mov ax,SEG data
    mov ds,ax
    mov ds:mp_init_proc, OFFSET SendInitMem
    mov ds:mp_startup_proc, OFFSET SendStartupMem
    mov ds:mp_int_proc, OFFSET SendIntMem
    mov ds:mp_eoi_proc, OFFSET SendEoiMem
    mov ds:mp_stop_proc, OFFSET StopApicTimerMem
    mov ds:mp_isr_proc, OFFSET GetIsrMem
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_id_mem
    mov edi,OFFSET get_id_name
    xor cl,cl
    mov ax,get_apic_id_nr
    RegisterOsGate
;
    mov esi,OFFSET send_eoi_mem
    mov edi,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
    RegisterOsGate
;
    mov esi,OFFSET send_nmi_mem
    mov edi,OFFSET send_nmi_name
    xor cl,cl
    mov ax,send_nmi_nr
    RegisterOsGate
;
    mov esi,OFFSET start_apic_mem_timer
    mov edi,OFFSET start_apic_timer_name
    xor cl,cl
    mov ax,start_sys_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET reload_apic_mem_timer
    mov edi,OFFSET reload_apic_timer_name
    xor cl,cl
    mov ax,reload_sys_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET disable_all_irq
    mov edi,OFFSET disable_all_irq_name
    xor cl,cl
    mov ax,disable_all_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET has_apic_mem
    mov edi,OFFSET has_apic_mem_name
    xor cl,cl
    mov ax,has_apic_mem_nr
    RegisterOsGate
;
    mov ax,cs
    mov ds,ax
    xor bl,bl
;
    mov al,41h
    mov esi,OFFSET mem_irq1
    CreateIntGateSelector
;
    mov al,43h
    mov esi,OFFSET mem_irq3
    CreateIntGateSelector
;
    mov al,44h
    mov esi,OFFSET mem_irq4
    CreateIntGateSelector
;
    mov al,45h
    mov esi,OFFSET mem_irq5
    CreateIntGateSelector
;
    mov al,46h
    mov esi,OFFSET mem_irq6
    CreateIntGateSelector
;
    mov al,47h
    mov esi,OFFSET mem_irq7
    CreateIntGateSelector
;
    mov al,48h
    mov esi,OFFSET mem_irq8
    CreateIntGateSelector
;
    mov al,49h
    mov esi,OFFSET mem_irq9
    CreateIntGateSelector
;
    mov al,4Ah
    mov esi,OFFSET mem_irq10
    CreateIntGateSelector
;
    mov al,4Bh
    mov esi,OFFSET mem_irq11
    CreateIntGateSelector
;
    mov al,4Ch
    mov esi,OFFSET mem_irq12
    CreateIntGateSelector
;
    mov al,4Dh
    mov esi,OFFSET mem_irq13
    CreateIntGateSelector
;
    mov al,4Eh
    mov esi,OFFSET mem_irq14
    CreateIntGateSelector
;
    mov al,4Fh
    mov esi,OFFSET mem_irq15
    CreateIntGateSelector
;
    mov al,50h
    mov esi,OFFSET mem_irq16
    CreateIntGateSelector
;
    mov al,51h
    mov esi,OFFSET mem_irq17
    CreateIntGateSelector
;
    mov al,52h
    mov esi,OFFSET mem_irq18
    CreateIntGateSelector
;
    mov al,53h
    mov esi,OFFSET mem_irq19
    CreateIntGateSelector
;
    mov al,54h
    mov esi,OFFSET mem_irq20
    CreateIntGateSelector
;
    mov al,55h
    mov esi,OFFSET mem_irq21
    CreateIntGateSelector
;
    mov al,56h
    mov esi,OFFSET mem_irq22
    CreateIntGateSelector
;
    mov al,57h
    mov esi,OFFSET mem_irq23
    CreateIntGateSelector
;
    mov al,58h
    mov esi,OFFSET mem_irq24
    CreateIntGateSelector
;
    mov al,59h
    mov esi,OFFSET mem_irq25
    CreateIntGateSelector
;
    mov al,5Ah
    mov esi,OFFSET mem_irq26
    CreateIntGateSelector
;
    mov al,5Bh
    mov esi,OFFSET mem_irq27
    CreateIntGateSelector
;
    mov al,5Ch
    mov esi,OFFSET mem_irq28
    CreateIntGateSelector
;
    mov al,5Dh
    mov esi,OFFSET mem_irq29
    CreateIntGateSelector
;
    mov al,5Eh
    mov esi,OFFSET mem_irq30
    CreateIntGateSelector
;
    mov al,5Fh
    mov esi,OFFSET mem_irq31
    CreateIntGateSelector
;
    mov al,0A0h
    mov esi,OFFSET mem_msi0
    CreateIntGateSelector
;
    mov al,0A1h
    mov esi,OFFSET mem_msi1
    CreateIntGateSelector
;
    mov al,0A2h
    mov esi,OFFSET mem_msi2
    CreateIntGateSelector
;
    mov al,0A3h
    mov esi,OFFSET mem_msi3
    CreateIntGateSelector
;
    mov al,0A4h
    mov esi,OFFSET mem_msi4
    CreateIntGateSelector
;
    mov al,0A5h
    mov esi,OFFSET mem_msi5
    CreateIntGateSelector
;
    mov al,0A6h
    mov esi,OFFSET mem_msi6
    CreateIntGateSelector
;
    mov al,0A7h
    mov esi,OFFSET mem_msi7
    CreateIntGateSelector
;
    mov al,0A8h
    mov esi,OFFSET mem_msi8
    CreateIntGateSelector
;
    mov al,0A9h
    mov esi,OFFSET mem_msi9
    CreateIntGateSelector
;
    mov al,0AAh
    mov esi,OFFSET mem_msi10
    CreateIntGateSelector
;
    mov al,0ABh
    mov esi,OFFSET mem_msi11
    CreateIntGateSelector
;
    mov al,0ACh
    mov esi,OFFSET mem_msi12
    CreateIntGateSelector
;
    mov al,0ADh
    mov esi,OFFSET mem_msi13
    CreateIntGateSelector
;
    mov al,0AEh
    mov esi,OFFSET mem_msi14
    CreateIntGateSelector
;
    mov al,0AFh
    mov esi,OFFSET mem_msi15
    CreateIntGateSelector
;
    mov al,0B0h
    mov esi,OFFSET mem_msi16
    CreateIntGateSelector
;
    mov al,0B1h
    mov esi,OFFSET mem_msi17
    CreateIntGateSelector
;
    mov al,0B2h
    mov esi,OFFSET mem_msi18
    CreateIntGateSelector
;
    mov al,0B3h
    mov esi,OFFSET mem_msi19
    CreateIntGateSelector
;
    mov al,0B4h
    mov esi,OFFSET mem_msi20
    CreateIntGateSelector
;
    mov al,0B5h
    mov esi,OFFSET mem_msi21
    CreateIntGateSelector
;
    mov al,0B6h
    mov esi,OFFSET mem_msi22
    CreateIntGateSelector
;
    mov al,0B7h
    mov esi,OFFSET mem_msi23
    CreateIntGateSelector
;
    mov al,0B8h
    mov esi,OFFSET mem_msi24
    CreateIntGateSelector
;
    mov al,0B9h
    mov esi,OFFSET mem_msi25
    CreateIntGateSelector
;
    mov al,0BAh
    mov esi,OFFSET mem_msi26
    CreateIntGateSelector
;
    mov al,0BBh
    mov esi,OFFSET mem_msi27
    CreateIntGateSelector
;
    mov al,0BCh
    mov esi,OFFSET mem_msi28
    CreateIntGateSelector
;
    mov al,0BDh
    mov esi,OFFSET mem_msi29
    CreateIntGateSelector
;
    mov al,0BEh
    mov esi,OFFSET mem_msi30
    CreateIntGateSelector
;
    mov al,0BFh
    mov esi,OFFSET mem_msi31
    CreateIntGateSelector
;
    mov al,0C0h
    mov esi,OFFSET mem_msi32
    CreateIntGateSelector
;
    mov al,0C1h
    mov esi,OFFSET mem_msi33
    CreateIntGateSelector
;
    mov al,0C2h
    mov esi,OFFSET mem_msi34
    CreateIntGateSelector
;
    mov al,0C3h
    mov esi,OFFSET mem_msi35
    CreateIntGateSelector
;
    mov al,0C4h
    mov esi,OFFSET mem_msi36
    CreateIntGateSelector
;
    mov al,0C5h
    mov esi,OFFSET mem_msi37
    CreateIntGateSelector
;
    mov al,0C6h
    mov esi,OFFSET mem_msi38
    CreateIntGateSelector
;
    mov al,0C7h
    mov esi,OFFSET mem_msi39
    CreateIntGateSelector
;
    mov al,0C8h
    mov esi,OFFSET mem_msi40
    CreateIntGateSelector
;
    mov al,0C9h
    mov esi,OFFSET mem_msi41
    CreateIntGateSelector
;
    mov al,0CAh
    mov esi,OFFSET mem_msi42
    CreateIntGateSelector
;
    mov al,0CBh
    mov esi,OFFSET mem_msi43
    CreateIntGateSelector
;
    mov al,0CCh
    mov esi,OFFSET mem_msi44
    CreateIntGateSelector
;
    mov al,0CDh
    mov esi,OFFSET mem_msi45
    CreateIntGateSelector
;
    mov al,0CEh
    mov esi,OFFSET mem_msi46
    CreateIntGateSelector
;
    mov al,0CFh
    mov esi,OFFSET mem_msi47
    CreateIntGateSelector
;
    mov al,0D0h
    mov esi,OFFSET mem_msi48
    CreateIntGateSelector
;
    mov al,0D1h
    mov esi,OFFSET mem_msi49
    CreateIntGateSelector
;
    mov al,0D2h
    mov esi,OFFSET mem_msi50
    CreateIntGateSelector
;
    mov al,0D3h
    mov esi,OFFSET mem_msi51
    CreateIntGateSelector
;
    mov al,0D4h
    mov esi,OFFSET mem_msi52
    CreateIntGateSelector
;
    mov al,0D5h
    mov esi,OFFSET mem_msi53
    CreateIntGateSelector
;
    mov al,0D6h
    mov esi,OFFSET mem_msi54
    CreateIntGateSelector
;
    mov al,0D7h
    mov esi,OFFSET mem_msi55
    CreateIntGateSelector
;
    mov al,0D8h
    mov esi,OFFSET mem_msi56
    CreateIntGateSelector
;
    mov al,0D9h
    mov esi,OFFSET mem_msi57
    CreateIntGateSelector
;
    mov al,0DAh
    mov esi,OFFSET mem_msi58
    CreateIntGateSelector
;
    mov al,0DBh
    mov esi,OFFSET mem_msi59
    CreateIntGateSelector
;
    mov al,0DCh
    mov esi,OFFSET mem_msi60
    CreateIntGateSelector
;
    mov al,0DDh
    mov esi,OFFSET mem_msi61
    CreateIntGateSelector
;
    mov al,0DEh
    mov esi,OFFSET mem_msi62
    CreateIntGateSelector
;
    mov al,0DFh
    mov esi,OFFSET mem_msi63
    CreateIntGateSelector
;    
    ret
SetupMemGates   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SetupMsrGates
;
;               DESCRIPTION:    Set up MSR gates for x2APIC mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupMsrGates   Proc near
    mov ecx,MSR_APIC_LINT0
    rdmsr
    test eax,10000h
    jnz smsrgLint0Ok
;    
    and ah,7
    cmp ah,4
    je smsrgLint0Disable
;
    cmp ah,7
    jne smsrgLint0Ok

smsrgLint0Disable:
    mov eax,10000h
    wrmsr

smsrgLint0Ok:
    mov ecx,MSR_APIC_LINT1
    rdmsr
    test eax,10000h
    jnz smsrgLint1Ok
;    
    and ah,7
    cmp ah,4
    je smsrgLint1Disable
;
    cmp ah,7
    jne smsrgLint1Ok

smsrgLint1Disable:
    mov eax,10000h
    wrmsr

smsrgLint1Ok:
    mov ax,SEG data
    mov ds,ax
    mov ds:mp_init_proc, OFFSET SendInitMsr
    mov ds:mp_startup_proc, OFFSET SendStartupMsr
    mov ds:mp_int_proc, OFFSET SendIntMsr
    mov ds:mp_eoi_proc, OFFSET SendEoiMsr
    mov ds:mp_stop_proc, OFFSET StopApicTimerMsr
    mov ds:mp_isr_proc, OFFSET GetIsrMsr
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_id_msr
    mov edi,OFFSET get_id_name
    xor cl,cl
    mov ax,get_apic_id_nr
    RegisterOsGate
;
    mov esi,OFFSET send_eoi_msr
    mov edi,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
    RegisterOsGate
;
    mov esi,OFFSET send_nmi_msr
    mov edi,OFFSET send_nmi_name
    xor cl,cl
    mov ax,send_nmi_nr
    RegisterOsGate
;
    mov esi,OFFSET start_apic_msr_timer
    mov edi,OFFSET start_apic_timer_name
    xor cl,cl
    mov ax,start_sys_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET reload_apic_msr_timer
    mov edi,OFFSET reload_apic_timer_name
    xor cl,cl
    mov ax,reload_sys_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET has_apic_msr
    mov edi,OFFSET has_apic_msr_name
    xor cl,cl
    mov ax,has_apic_msr_nr
    RegisterOsGate
;
    mov ax,cs
    mov ds,ax
    xor bl,bl
;
    mov al,41h
    mov esi,OFFSET msr_irq1
    CreateIntGateSelector
;
    mov al,43h
    mov esi,OFFSET msr_irq3
    CreateIntGateSelector
;
    mov al,44h
    mov esi,OFFSET msr_irq4
    CreateIntGateSelector
;
    mov al,45h
    mov esi,OFFSET msr_irq5
    CreateIntGateSelector
;
    mov al,46h
    mov esi,OFFSET msr_irq6
    CreateIntGateSelector
;
    mov al,47h
    mov esi,OFFSET msr_irq7
    CreateIntGateSelector
;
    mov al,48h
    mov esi,OFFSET msr_irq8
    CreateIntGateSelector
;
    mov al,49h
    mov esi,OFFSET msr_irq9
    CreateIntGateSelector
;
    mov al,4Ah
    mov esi,OFFSET msr_irq10
    CreateIntGateSelector
;
    mov al,4Bh
    mov esi,OFFSET msr_irq11
    CreateIntGateSelector
;
    mov al,4Ch
    mov esi,OFFSET msr_irq12
    CreateIntGateSelector
;
    mov al,4Dh
    mov esi,OFFSET msr_irq13
    CreateIntGateSelector
;
    mov al,4Eh
    mov esi,OFFSET msr_irq14
    CreateIntGateSelector
;
    mov al,4Fh
    mov esi,OFFSET msr_irq15
    CreateIntGateSelector
;
    mov al,50h
    mov esi,OFFSET msr_irq16
    CreateIntGateSelector
;
    mov al,51h
    mov esi,OFFSET msr_irq17
    CreateIntGateSelector
;
    mov al,52h
    mov esi,OFFSET msr_irq18
    CreateIntGateSelector
;
    mov al,53h
    mov esi,OFFSET msr_irq19
    CreateIntGateSelector
;
    mov al,54h
    mov esi,OFFSET msr_irq20
    CreateIntGateSelector
;
    mov al,55h
    mov esi,OFFSET msr_irq21
    CreateIntGateSelector
;
    mov al,56h
    mov esi,OFFSET msr_irq22
    CreateIntGateSelector
;
    mov al,57h
    mov esi,OFFSET msr_irq23
    CreateIntGateSelector
;
    mov al,58h
    mov esi,OFFSET msr_irq24
    CreateIntGateSelector
;
    mov al,59h
    mov esi,OFFSET msr_irq25
    CreateIntGateSelector
;
    mov al,5Ah
    mov esi,OFFSET msr_irq26
    CreateIntGateSelector
;
    mov al,5Bh
    mov esi,OFFSET msr_irq27
    CreateIntGateSelector
;
    mov al,5Ch
    mov esi,OFFSET msr_irq28
    CreateIntGateSelector
;
    mov al,5Dh
    mov esi,OFFSET msr_irq29
    CreateIntGateSelector
;
    mov al,5Eh
    mov esi,OFFSET msr_irq30
    CreateIntGateSelector
;
    mov al,5Fh
    mov esi,OFFSET msr_irq31
    CreateIntGateSelector
;
    mov al,0A0h
    mov esi,OFFSET msr_msi0
    CreateIntGateSelector
;
    mov al,0A1h
    mov esi,OFFSET msr_msi1
    CreateIntGateSelector
;
    mov al,0A2h
    mov esi,OFFSET msr_msi2
    CreateIntGateSelector
;
    mov al,0A3h
    mov esi,OFFSET msr_msi3
    CreateIntGateSelector
;
    mov al,0A4h
    mov esi,OFFSET msr_msi4
    CreateIntGateSelector
;
    mov al,0A5h
    mov esi,OFFSET msr_msi5
    CreateIntGateSelector
;
    mov al,0A6h
    mov esi,OFFSET msr_msi6
    CreateIntGateSelector
;
    mov al,0A7h
    mov esi,OFFSET msr_msi7
    CreateIntGateSelector
;
    mov al,0A8h
    mov esi,OFFSET msr_msi8
    CreateIntGateSelector
;
    mov al,0A9h
    mov esi,OFFSET msr_msi9
    CreateIntGateSelector
;
    mov al,0AAh
    mov esi,OFFSET msr_msi10
    CreateIntGateSelector
;
    mov al,0ABh
    mov esi,OFFSET msr_msi11
    CreateIntGateSelector
;
    mov al,0ACh
    mov esi,OFFSET msr_msi12
    CreateIntGateSelector
;
    mov al,0ADh
    mov esi,OFFSET msr_msi13
    CreateIntGateSelector
;
    mov al,0AEh
    mov esi,OFFSET msr_msi14
    CreateIntGateSelector
;
    mov al,0AFh
    mov esi,OFFSET msr_msi15
    CreateIntGateSelector
;
    mov al,0B0h
    mov esi,OFFSET msr_msi16
    CreateIntGateSelector
;
    mov al,0B1h
    mov esi,OFFSET msr_msi17
    CreateIntGateSelector
;
    mov al,0B2h
    mov esi,OFFSET msr_msi18
    CreateIntGateSelector
;
    mov al,0B3h
    mov esi,OFFSET msr_msi19
    CreateIntGateSelector
;
    mov al,0B4h
    mov esi,OFFSET msr_msi20
    CreateIntGateSelector
;
    mov al,0B5h
    mov esi,OFFSET msr_msi21
    CreateIntGateSelector
;
    mov al,0B6h
    mov esi,OFFSET msr_msi22
    CreateIntGateSelector
;
    mov al,0B7h
    mov esi,OFFSET msr_msi23
    CreateIntGateSelector
;
    mov al,0B8h
    mov esi,OFFSET msr_msi24
    CreateIntGateSelector
;
    mov al,0B9h
    mov esi,OFFSET msr_msi25
    CreateIntGateSelector
;
    mov al,0BAh
    mov esi,OFFSET msr_msi26
    CreateIntGateSelector
;
    mov al,0BBh
    mov esi,OFFSET msr_msi27
    CreateIntGateSelector
;
    mov al,0BCh
    mov esi,OFFSET msr_msi28
    CreateIntGateSelector
;
    mov al,0BDh
    mov esi,OFFSET msr_msi29
    CreateIntGateSelector
;
    mov al,0BEh
    mov esi,OFFSET msr_msi30
    CreateIntGateSelector
;
    mov al,0BFh
    mov esi,OFFSET msr_msi31
    CreateIntGateSelector
;
    mov al,0C0h
    mov esi,OFFSET msr_msi32
    CreateIntGateSelector
;
    mov al,0C1h
    mov esi,OFFSET msr_msi33
    CreateIntGateSelector
;
    mov al,0C2h
    mov esi,OFFSET msr_msi34
    CreateIntGateSelector
;
    mov al,0C3h
    mov esi,OFFSET msr_msi35
    CreateIntGateSelector
;
    mov al,0C4h
    mov esi,OFFSET msr_msi36
    CreateIntGateSelector
;
    mov al,0C5h
    mov esi,OFFSET msr_msi37
    CreateIntGateSelector
;
    mov al,0C6h
    mov esi,OFFSET msr_msi38
    CreateIntGateSelector
;
    mov al,0C7h
    mov esi,OFFSET msr_msi39
    CreateIntGateSelector
;
    mov al,0C8h
    mov esi,OFFSET msr_msi40
    CreateIntGateSelector
;
    mov al,0C9h
    mov esi,OFFSET msr_msi41
    CreateIntGateSelector
;
    mov al,0CAh
    mov esi,OFFSET msr_msi42
    CreateIntGateSelector
;
    mov al,0CBh
    mov esi,OFFSET msr_msi43
    CreateIntGateSelector
;
    mov al,0CCh
    mov esi,OFFSET msr_msi44
    CreateIntGateSelector
;
    mov al,0CDh
    mov esi,OFFSET msr_msi45
    CreateIntGateSelector
;
    mov al,0CEh
    mov esi,OFFSET msr_msi46
    CreateIntGateSelector
;
    mov al,0CFh
    mov esi,OFFSET msr_msi47
    CreateIntGateSelector
;
    mov al,0D0h
    mov esi,OFFSET msr_msi48
    CreateIntGateSelector
;
    mov al,0D1h
    mov esi,OFFSET msr_msi49
    CreateIntGateSelector
;
    mov al,0D2h
    mov esi,OFFSET msr_msi50
    CreateIntGateSelector
;
    mov al,0D3h
    mov esi,OFFSET msr_msi51
    CreateIntGateSelector
;
    mov al,0D4h
    mov esi,OFFSET msr_msi52
    CreateIntGateSelector
;
    mov al,0D5h
    mov esi,OFFSET msr_msi53
    CreateIntGateSelector
;
    mov al,0D6h
    mov esi,OFFSET msr_msi54
    CreateIntGateSelector
;
    mov al,0D7h
    mov esi,OFFSET msr_msi55
    CreateIntGateSelector
;
    mov al,0D8h
    mov esi,OFFSET msr_msi56
    CreateIntGateSelector
;
    mov al,0D9h
    mov esi,OFFSET msr_msi57
    CreateIntGateSelector
;
    mov al,0DAh
    mov esi,OFFSET msr_msi58
    CreateIntGateSelector
;
    mov al,0DBh
    mov esi,OFFSET msr_msi59
    CreateIntGateSelector
;
    mov al,0DCh
    mov esi,OFFSET msr_msi60
    CreateIntGateSelector
;
    mov al,0DDh
    mov esi,OFFSET msr_msi61
    CreateIntGateSelector
;
    mov al,0DEh
    mov esi,OFFSET msr_msi62
    CreateIntGateSelector
;
    mov al,0DFh
    mov esi,OFFSET msr_msi63
    CreateIntGateSelector
;       
    ret
SetupMsrGates   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DoStartCore
;
;       DESCRIPTION:    Start a CPU core
;
;       PARAMETERS:     EDX         APIC ID
;
;       RETURNS:        FS          Processor sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoStartCore   Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov fs,ax
;    
    mov ebp,edx    
    mov eax,2000h
    AllocateBigLinear
;
    mov eax,63h
    SetPhysicalPage
;    
    mov eax,1063h
    add edx,1000h
    SetPhysicalPage
    sub edx,1000h
;
    AllocateGdt
    mov ecx,2000h
    CreateDataSelector32
    mov es,bx
    mov ax,cs
    mov ds,ax
;
    mov di,0F80h
    mov si,OFFSET table_start
    mov cx,OFFSET table_end - OFFSET table_start
    rep movsb
;
    mov di,1000h
    mov si,OFFSET real_start
    mov cx,OFFSET real_end - OFFSET real_start
    rep movsb
;
    mov di,1400h
    mov si,OFFSET prot_start
    mov cx,OFFSET prot_end - OFFSET prot_start
    rep movsb
;
    mov di,1800h
    mov eax,cr0
    mov es:[di].ap_cr0,eax
    mov eax,cr3
    mov es:[di].ap_cr3,eax
;
    db 0Fh
    db 20h
    db 0E0h     ; mov eax,cr4
    mov es:[di].ap_cr4,eax
;
    push cx
    push edx
    db 66h
    sidt fword ptr es:[di].ap_idt
;    
    CreateCoreGdt
    dec cx
    mov word ptr es:[di].ap_gdt,cx
    mov dword ptr es:[di].ap_gdt+2,edx
;    
    pop edx
    pop cx
;
    push es
    mov eax,200h
    AllocateSmallGlobalMem
    mov ax,es
    pop es
    mov es:[di].ap_ss,ax
;
    mov bx,467h
    mov ax,0
    mov es:[bx],ax
    mov ax,100h
    mov es:[bx+2],ax
;
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    mov al,0Ah
    out 71h,al
    jmp short $+2
;
    mov fs:mp_processor_sign,0
;
    xchg edx,ebp
    call SendInit
;
    mov eax,fs:mp_processor_sign
    cmp eax,12345678h
    je scOk
;    
    mov al,1
    call SendStartup
    
    mov cx,250

scLoop1:
    mov eax,fs:mp_processor_sign
    cmp eax,12345678h
    je scOk
;    
    mov ax,1
    call DelayMs    
    loop scLoop1
;
    mov al,1    
    call SendStartup
;    
    mov cx,250

scLoop2:
    mov eax,fs:mp_processor_sign
    cmp eax,12345678h
    je scOk
;    
    mov ax,1
    call DelayMs    
    loop scLoop2
;
    xor ax,ax
    mov fs,ax
    stc
    jmp scDone

scOk:
    push es
    mov edx,dword ptr es:[di].ap_gdt+2
    CreateCore
    mov ax,es
    mov fs,ax    
    pop es
    clc

scDone:
    pushf
;
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    xor al,al
    out 71h,al
    jmp short $+2
;
    mov edx,ebp
    xor eax,eax
    add edx,1000h
    SetPhysicalPage
    sub edx,1000h
;    
    SetPhysicalPage
    FreeMem
;
    popf   
    popad
    pop es
    pop ds
    ret
DoStartCore   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ReadIoApicInt
;
;               DESCRIPTION:    Read setting for IO-APIC int
;
;       PARAMETERS:     AL      Int #
;
;       RETURNS:        EDX:EAX IO-APIC setting
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadIoApicInt   Proc near
    push ds
    push bx
;    
    mov bx,ioapic_mem_sel
    mov ds,bx
;       
    mov bl,10h
    add bl,al
    add bl,al
;    
    mov ds:ioapic_regsel,bl
    mov eax,ds:ioapic_window
;
    inc bl
    mov ds:ioapic_regsel,bl
    mov edx,ds:ioapic_window
;
    pop bx
    pop ds
    ret
ReadIoApicInt   Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   IRQx
;
;               DESCRIPTION:    IRQ handlers
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; fixed IRQs (IOAPIC)

    irqmac 1
    irqmac 3
    irqmac 4
    irqmac 5
    irqmac 6
    irqmac 7
    irqmac 8
    irqmac 9
    irqmac 10
    irqmac 11
    irqmac 12
    irqmac 13
    irqmac 14
    irqmac 15
    irqmac 16
    irqmac 17
    irqmac 18
    irqmac 19
    irqmac 20
    irqmac 21
    irqmac 22
    irqmac 23
    irqmac 24
    irqmac 25
    irqmac 26
    irqmac 27
    irqmac 28
    irqmac 29
    irqmac 30
    irqmac 31

; Allocatable IRQs (MSI)

    msimac 0
    msimac 1
    msimac 2
    msimac 3
    msimac 4
    msimac 5
    msimac 6
    msimac 7
    msimac 8
    msimac 9
    msimac 10
    msimac 11
    msimac 12
    msimac 13
    msimac 14
    msimac 15
    msimac 16
    msimac 17
    msimac 18
    msimac 19
    msimac 20
    msimac 21
    msimac 22
    msimac 23
    msimac 24
    msimac 25
    msimac 26
    msimac 27
    msimac 28
    msimac 29
    msimac 30
    msimac 31
    msimac 32
    msimac 33
    msimac 34
    msimac 35
    msimac 36
    msimac 37
    msimac 38
    msimac 39
    msimac 40
    msimac 41
    msimac 42
    msimac 43
    msimac 44
    msimac 45
    msimac 46
    msimac 47
    msimac 48
    msimac 49
    msimac 50
    msimac 51
    msimac 52
    msimac 53
    msimac 54
    msimac 55
    msimac 56
    msimac 57
    msimac 58
    msimac 59
    msimac 60
    msimac 61
    msimac 62
    msimac 63

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EnableIrq
;
;               description:    Enable IRQ in IOAPIC controller
;
;               PARAMETERS:             AL                      irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_irq  Proc far
    push ds
    push eax
    push bx
    push edx
;
    movzx edx,al
    mov dh,0A9h
    cmp al,10h
    jae enable_irq_do
;    
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    shl bx,3
    mov edx,ds:[bx].isa_redir_arr
    sub dl,40h
    xchg al,dl

enable_irq_do:
    add dl,40h
;    
    mov bx,ioapic_mem_sel
    mov ds,bx
;       
    mov bl,10h
    add bl,al
    add bl,al
;    
    mov ds:ioapic_regsel,bl
    mov ds:ioapic_window,edx
;
    inc bl
    mov ds:ioapic_regsel,bl
    mov edx,0FF000000h
;    GetApicId
;    shl edx,24
    mov ds:ioapic_window,edx
;
    pop edx
    pop bx
    pop eax
    pop ds
    ret
enable_irq  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DisableIrq
;
;               description:    Disable IRQ in APIC controller
;
;               PARAMETERS:             AL                      irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_irq  Proc far
    push ds
    push eax
    push bx
;    
    mov bx,ioapic_mem_sel
    mov ds,bx
;       
    mov bl,10h
    add bl,al
    add bl,al
;    
    mov ds:ioapic_regsel,bl
    mov eax,10000h
    mov ds:ioapic_window,eax
;
    inc bl
    mov ds:ioapic_regsel,bl
    xor eax,eax
    mov ds:ioapic_window,eax
;
    pop bx
    pop eax
    pop ds
    ret
disable_irq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           DisableAllIrq
;
;               description:    Disable all IRQs in APIC controller
;
;               RETURNS:        EAX     Active IRQs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_all_irq_name    DB 'Disable All IRQs', 0

disable_all_irq  Proc far
    push ds
    push bx
    push cx
; 
    mov bx,SEG data
    mov ds,bx
    call ds:mp_stop_proc   
;    
    mov cx,24
    mov bx,ioapic_mem_sel
    mov ds,bx
;       
    mov bl,10h

daiLoop:   
    mov ds:ioapic_regsel,bl
    mov eax,10000h
    mov ds:ioapic_window,eax
;
    inc bl
    mov ds:ioapic_regsel,bl
    xor eax,eax
    mov ds:ioapic_window,eax
    inc bl
    loop daiLoop
;
    call InitApic
    mov bx,SEG data
    mov ds,bx
    call ds:mp_isr_proc
;
    pop cx
    pop bx
    pop ds
    retf32
disable_all_irq Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EnableIrqDetect
;
;               description:    Enable IRQ detect in PIC controller
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_irq_detect  Proc far
    ret
enable_irq_detect   Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CheckMp
;
;               DESCRIPTION:    Check for an MP header
;
;       PARAMETERS:     DS:SI       Base address to check
;
;       RETURNS:        NC          OK
;                       EAX         Physical address
;                       EDX         Feature bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mp_sign DB '_MP_'

CheckMp   Proc near
    mov eax,dword ptr cs:mp_sign
    cmp eax,[si]
    jne check_mp_fail
;
    push cx
    push si
;    
    xor al,al        
    mov cx,10h

check_mp_loop:
    add al,[si]
    inc si
    loop check_mp_loop
;
    pop si
    pop cx    
;
    or al,al
    jnz check_mp_fail
;
    movzx ax,byte ptr [si+8]
    shl ax,4
    cmp ax,10h
    jb check_mp_fail
;    
    mov eax,[si+4]
    mov ebp,[si+11]
    clc
    jmp check_mp_done

check_mp_fail:
    stc

check_mp_done:    
    ret
CheckMp   Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetMp
;
;               DESCRIPTION:    Get the MP
;
;       RETURNS:        NC          OK
;                       EAX         Physical address
;                       EBP         Feature bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMp Proc near
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
    push bp
;
    mov eax,1000h
    AllocateBigLinear
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov eax,7h
    SetPhysicalPage
    mov ds,bx    
;    
    mov esi,40Eh
    mov si,[si]
    movzx esi,si
    shl esi,4
;
    mov eax,esi
    and ax,0F000h
    or al,7
    SetPhysicalPage
    and si,0FFFh
;        
    mov cx,40h

get_mp_bda:
    call CheckMp
    jnc get_mp_ok
;
    add si,10h
    loop get_mp_bda
;     
    mov edi,0E0000h
    mov bp,20h

get_mp_bios:
    mov eax,edi
    and ax,0F000h
    or al,7
    SetPhysicalPage
;
    mov esi,edi
    and si,0FFFh
;
    mov cx,100h

get_mp_bios_page:
    call CheckMp
    jnc get_mp_ok
;    
    add si,10h
    loop get_mp_bios_page
;
    add edi,1000h
    sub bp,1
    jnz get_mp_bios
;
    stc
    jmp get_mp_done

get_mp_ok:
    clc

get_mp_done:    
    push eax
    pushf
    xor eax,eax
    mov ds,ax
    SetPhysicalPage
    mov ecx,1000h
    FreeLinear
    FreeGdt    
    popf
    pop eax
    mov edx,ebp
;    
    pop bp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
GetMp Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   apic_pr
;
;               DESCRIPTION:    APIC test thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

apic_name       DB 'Apic Test',0

apic_pr:
    int 3
    retf            

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   init_apic_thread
;
;               DESCRIPTION:    Init apic threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_apic_thread        PROC far
    push ds
    push es
    pusha
;
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test ax,200h
;    jz init_thread_done
;    
;    mov ecx,1Bh
;    rdmsr
;    test ah,8
;    jz init_thread_done
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;       
    mov si,OFFSET apic_pr
    mov di,OFFSET apic_name
    mov cx,stack0_size
    mov ax,4
    CreateThread

init_thread_done:
    popa
    pop es
    pop ds
    retf32
init_apic_thread        ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InitApic
;
;               DESCRIPTION:    Init APIC timer
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


InitApic    Proc near
    mov bx,apic_mem_sel
    mov es,bx
;
    mov eax,8700h
    mov es:APIC_LINT0,eax
;
    mov eax,400h
    mov es:APIC_LINT1,eax 
;   
    mov eax,10000h
    mov es:APIC_LERROR,eax
;
    mov eax,10000h
    mov es:APIC_THERMAL,eax
;
    mov eax,10000h
    mov es:APIC_PERF,eax
;
    mov eax,10000h
    mov es:APIC_TIMER,eax
;
    mov eax,es:APIC_SPUR
    and eax,NOT 1000h
    or eax,100h
    mov al,0Fh
    mov es:APIC_SPUR,eax    
;
    mov eax,0Bh
    mov es:APIC_DIV_CONFIG,eax
;
    mov eax,-1
    mov es:APIC_DEST_FORMAT,eax
;
    mov eax,10000000h    
    mov es:APIC_LOG_DEST,eax
;
    mov eax,0FFh
    mov es:APIC_TPR,eax
    ret
InitApic    Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InitApicTimer
;
;               DESCRIPTION:    Init APIC timer
;
;               PARAMETERS:             EAX     Physical base of timer
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

InitApicTimer Proc near    
    push ds
    push es
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
;    
    mov ecx,1Bh
    rdmsr
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
    and ax,0F000h
    or ax,33h
    SetPhysicalPage    
    mov bx,apic_mem_sel
    mov ecx,1000h
    CreateDataSelector16
;
    mov eax,1000h
    AllocateBigLinear
    mov eax,ebp
    mov eax,0FEC00000h
    or ax,33h
    SetPhysicalPage    
    mov bx,ioapic_mem_sel
    mov ecx,1000h
    CreateDataSelector16
;
    call InitApic

init_tsc_start:
    xor cx,cx    

init_tsc_wait_start_high:
    read_tics    
    test ax,8000h
    jnz init_tsc_wait_start_high_ok
    loop init_tsc_wait_start_high    

init_tsc_wait_start_high_ok:
    xor cx,cx    

init_tsc_wait_start_low:
    read_tics    
    test ax,8000h
    jz init_tsc_wait_start_low_ok
    loop init_tsc_wait_start_low

init_tsc_wait_start_low_ok:    
    mov eax,-1
    mov es:APIC_INIT_COUNT,eax

init_apic_start_done:
    xor cx,cx

init_tsc_wait_high:    
    read_tics
    test ax,8000h
    jnz init_tsc_wait_high_ok
    loop init_tsc_wait_high

init_tsc_wait_high_ok:
    xor cx,cx

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
InitApicTimer Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InitLocalApic
;
;               DESCRIPTION:    Init local APIC access
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitLocalApic   Proc near
    push ds
    push es
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test ax,20h
    jz init_local_apic_mmio
;    
    mov ecx,1Bh
    rdmsr
    test ah,8
    jz init_local_apic_done
;
    test ah,4
    jnz init_local_apic_msr

init_local_apic_mmio:
    or es:mp_flags, MP_FLAG_MEM
    call SetupMemGates
    jmp init_local_apic_done

init_local_apic_msr:
    or es:mp_flags, MP_FLAG_MSR
    call SetupMsrGates

init_local_apic_done:
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_pci_irq
    mov edi,OFFSET get_pci_irq_name
    xor cl,cl
    mov ax,get_pci_irq_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
InitLocalApic   Endp

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
    push ds
    push es
    push fs
    pushad
;
    mov ax,SEG data
    mov ds,ax
    call ds:mp_eoi_proc
    TimerExpired
;
    popad
    pop fs
    pop es
    pop ds
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           tlb_flush_int
;
;           DESCRIPTION:    TLB flush int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tlb_flush_int:
    push ds
    push es
    push fs
    pushad
;
    mov ax,SEG data
    mov ds,ax
    call ds:mp_eoi_proc
    FlushTlb    
;    
    popad
    pop fs
    pop es
    pop ds
    iretd    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   InitIpi
;
;               DESCRIPTION:    Init IPIs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ipi_tab:
;
;                       int #   Entry                   
;
pi80   DW      80h,    OFFSET timer_int
pi81   DW      81h,    OFFSET tlb_flush_int
       DW      0FFFFh

;
; tabell offsets
;
ipi_nr          EQU 0
ipi_entry       EQU 2

InitIpi Proc near
    push ds
    pushad
;    
    mov ax,cs
    mov ds,ax
    xor bl,bl
    mov di,OFFSET ipi_tab

ipiLoop:
    mov ax,cs:[di]
    cmp ax,0FFFFh
    jz ipiDone
;
    mov al,cs:[di].ipi_nr
    movzx esi, word ptr cs:[di].ipi_entry
    CreateIntGateSelector
    add di,4
    jmp ipiLoop
    
ipiDone:
    popad
    pop ds
    ret
InitIpi Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   InitSmp
;
;               DESCRIPTION:    Init multiprocessing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitSmp Proc near
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_ap_cores
    mov edi,OFFSET start_ap_cores_name
    xor cl,cl
    mov ax,start_ap_cores_nr
    RegisterOsGate
;
    mov esi,OFFSET send_int
    mov edi,OFFSET send_int_name
    xor cl,cl
    mov ax,send_int_nr
    RegisterOsGate
;
    popad       
    pop es
    pop ds
    ret
InitSmp Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateMsiInts
;
;       DESCRIPTION:    Allocate MSI interrupts
;
;       PARAMETERS:     CX      Number of ints (1,2,4,8,16 or 32)
;
;       RETURNS:        EDX     MSI address
;                       AX      MSI data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_msi_ints_name    DB 'Allocate MSI Ints',0

allocate_msi_ints  Proc far
    push ds
    push si
;    
    mov dx,ds
    mov ax,irq_sys_sel
    mov ds,ax
;
    cmp cx,32
    ja amiFailed
;
    cmp cx,16
    jbe amiNot32

ami32:
    xor ax,ax
    mov edx,ds:msi_mask
    or edx,edx
    jnz ami32_1
;
    mov edx,-1
    mov ds:msi_mask,edx    
    jmp amiOk

ami32_1:
    mov ax,32
    mov edx,ds:msi_mask+4
    or edx,edx
    jnz amiFailed
;
    mov edx,-1
    mov ds:msi_mask,edx    
    jmp amiOk

amiNot32:    
    cmp cx,8
    jbe amiNot16

ami16:
    xor ax,ax
    mov si,OFFSET msi_mask

ami16Loop:
    mov dx,ds:[si]
    or dx,dx
    jnz ami16Next
;
    mov dx,-1
    mov ds:[si],dx
    jmp amiOk

ami16Next:
    add ax,16
    add si,2
    cmp ax,64
    jne ami16Loop
    jmp amiFailed

amiNot16:
    cmp cx,4
    jbe amiNot8

ami8:
    xor ax,ax
    mov si,OFFSET msi_mask

ami8Loop:
    mov dl,ds:[si]
    or dl,dl
    jnz ami8Next
;
    mov dl,-1
    mov ds:[si],dl
    jmp amiOk

ami8Next:
    add ax,8
    inc si
    cmp ax,64
    jne ami8Loop
    jmp amiFailed
        
amiNot8:
    cmp cx,2
    jbe amiNot4

ami4:
    xor ax,ax
    mov si,OFFSET msi_mask

ami4Loop:
    mov dl,ds:[si]
    test dl,0Fh
    jnz ami4_1
;
    mov dl,0Fh
    or ds:[si],dl
    jmp amiOk

ami4_1:
    add ax,4
    test dl,0F0h
    jnz ami4Next
;    
    mov dl,0F0h
    or ds:[si],dl
    jmp amiOk

ami4Next:
    add ax,4
    inc si
    cmp ax,64
    jne ami4Loop
    jmp amiFailed
        
amiNot4:
    cmp cx,1
    jbe ami1

ami2:
    xor ax,ax
    mov si,OFFSET msi_mask

ami2Loop:
    mov dl,ds:[si]
    test dl,03h
    jnz ami2_1
;
    mov dl,03h
    or ds:[si],dl
    jmp amiOk

ami2_1:
    add ax,2
    test dl,0Ch
    jnz ami2_2
;
    mov dl,0Ch
    or ds:[si],dl
    jmp amiOk

ami2_2:
    add ax,2
    test dl,30h
    jnz ami2_3
;
    mov dl,30h
    or ds:[si],dl
    jmp amiOk

ami2_3:
    add ax,2
    test dl,0C0h
    jnz ami2Next
;
    mov dl,0C0h
    or ds:[si],dl
    jmp amiOk

ami2Next:
    add ax,2
    inc si
    cmp ax,64
    jne ami2Loop
    jmp amiFailed

ami1:
    xor ax,ax
    mov si,OFFSET msi_mask

ami1ByteLoop:
    mov dl,ds:[si]
    cmp dl,-1
    je ami1NextByte
;
    mov dh,1

ami1BitLoop:
    shr dl,1
    jc amiBitNext
;    
    or ds:[si],dh
    jmp amiOk

amiBitNext:
    shl dh,1
    inc ax
    jmp ami1BitLoop

ami1NextByte:
    add ax,8
    inc si
    cmp ax,64
    jne ami1ByteLoop
    jmp amiFailed

amiOk:
    add al,0A0h
    mov ah,1
    mov edx,0FEEFF000h
    clc
    jmp amiDone

amiFailed:
    stc

amiDone:    
    pop si
    pop ds    
    retf32
allocate_msi_ints  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RequestMsiHandler
;
;       DESCRIPTION:    Request an MSI-based interrupt-handler
;
;       PARAMETERS:     DS      Data passed to handler
;                       ES:EDI  Handler address
;                       AX      MSI data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_msi_handler_name    DB 'Request MSI Handler',0

request_msi_handler  Proc far
    push ds
    push eax
    push dx
    push si
;    
    push ds
    mov dx,irq_sys_sel
    mov ds,dx
;
    sub ax,0A0h
    xor ah,ah
    mov dx,SIZE irq_struc
    mul dx
    mov si,OFFSET msi_arr
    add si,ax
    pop dx
;
    EnterSection ds:[si].usage_section
    mov ds:[si].user_data,dx
    mov ds:[si].user_handler,edi
    mov word ptr ds:[si+4].user_handler,es
;    
    pop si
    pop dx
    pop eax
    pop ds    
    retf32
request_msi_handler  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeMsiInt
;
;       DESCRIPTION:    Free a single MSI int vector
;
;       PARAMETERS:     AX      MSI data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_msi_int_name    DB 'Free MSI Int',0

free_msi_int  Proc far
    push ds
    push ax
    push si
;    
    mov si,irq_sys_sel
    mov ds,si
;
    sub ax,0A0h
    xor ah,ah
    mov si,OFFSET msi_mask
    btc ds:[si],ax
;
    pop si
    pop ax
    pop ds
    retf32
free_msi_int    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SetupIrq
;
;               DESCRIPTION:    Setup IRQs to IOAPIC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupIrq    Proc near
    push ds
    pushad
;    
    mov ax,irq_sys_sel
    mov ds,ax
;    
    mov word ptr ds:irq_detect_proc,OFFSET enable_irq_detect
    mov word ptr ds:irq_detect_proc+2,cs
;    
    mov cx,32
    mov bx,OFFSET irq_arr
    xor eax,eax

init_irq_loop:
    mov word ptr ds:[bx].irq_enable_proc,OFFSET enable_irq
    mov word ptr ds:[bx].irq_enable_proc+2,cs
;
    mov word ptr ds:[bx].irq_disable_proc,OFFSET disable_irq
    mov word ptr ds:[bx].irq_disable_proc+2,cs
;
    add bx,SIZE irq_struc
    loop init_irq_loop
;
    mov ds:msi_mask,0
    mov ds:msi_mask+4,0
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET allocate_msi_ints
    mov edi,OFFSET allocate_msi_ints_name
    xor cl,cl
    mov ax,allocate_msi_ints_nr
    RegisterOsGate
;
    mov esi,OFFSET request_msi_handler
    mov edi,OFFSET request_msi_handler_name
    xor cl,cl
    mov ax,request_msi_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET free_msi_int
    mov edi,OFFSET free_msi_int_name
    xor cl,cl
    mov ax,free_msi_int_nr
    RegisterOsGate
;
    popad
    pop ds
    ret
SetupIrq    Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Init
;
;               DESCRIPTION:    Init apic mp module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,SEG data
    mov ds,ax
    mov ds:mp_flags,0
    mov bx,OFFSET isa_redir_arr
    xor edx,edx
    mov eax,40h
    mov cx,16

init_redir_loop:
    mov [bx],eax
    add bx,4
    mov [bx],edx
    add bx,4
    inc al
    loop init_redir_loop
;
    mov bx,OFFSET isa_redir_arr + 2 * 8
    mov eax,10000h
    mov [bx],eax 
;       
    mov eax,dword ptr cs:apic_tab
    GetAcpiTable
    jc init_apic_gates_ok
;
    call InitApicTimer
    call InitLocalApic
;
    mov di,OFFSET apic_entries
    mov cx,es:act_size
    sub cx,OFFSET apic_entries - OFFSET apic_phys
    xor bp,bp

init_table_loop:
    mov al,es:[di].apic_type
    or al,al
    jz init_proc
    cmp al,2
    je init_redir
;
    jmp init_table_next    
    
init_proc:
    or bp,bp
    jnz init_ap_proc

init_boot_proc:
    GetCore
    movzx edx,es:[di].ap_apic_id
    mov fs:ps_apic,edx
;
    mov al,es:[di].ap_acpi_id
    mov fs:ps_acpi,al
    inc bp
    jmp init_table_next

init_ap_proc:
    mov eax,es:[di].ap_flags
    test al,1
    jz init_table_next
;    
    movzx edx,es:[di].ap_apic_id
    call DoStartCore
    jc init_table_next    
;    
    cmp bp,1
    jnz init_ap_create
;    
    call InitSmp
    call InitIpi
    
init_ap_create:       
    mov fs:ps_apic,edx
;
    mov al,es:[di].ap_acpi_id
    mov fs:ps_acpi,al
;
    inc bp
    jmp init_table_next

init_redir:
    mov al,es:[di].ao_bus
    or al,al
    jnz init_table_next
;
    mov al,es:[di].ao_source
    cmp al,16
    jae init_table_next
;
    movzx bx,al
    shl bx,3
    add bx,OFFSET isa_redir_arr
;
    mov eax,es:[di].ao_int
    cmp eax,80h
    jae init_table_next
;
    add al,40h
    mov [bx],al
;
    mov ax,es:[di].ao_flags
    test al,1
    jz init_redir_pol_ok
;
    test al,2
    jz init_redir_pol_high

init_redir_pol_low:
    or word ptr [bx],2000h
    jmp init_redir_pol_ok

init_redir_pol_high:
    and word ptr [bx], NOT 2000h

init_redir_pol_ok:
    test al,4
    jz init_table_next
;
    test al,8
    jz init_redir_edge

init_redir_level:
    or word ptr [bx],8000h
    jmp init_table_next

init_redir_edge:
    and word ptr [bx],7FFFh

init_table_next:
    movzx ax,es:[di].apic_len
    add di,ax
    sub cx,ax
    ja init_table_loop
;
    call SetupIrq    
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_apic_thread
    HookInitTasking

init_apic_gates_ok:     
    ret
init    ENDP

code    ENDS

    END init

