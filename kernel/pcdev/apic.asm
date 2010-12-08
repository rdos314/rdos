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

mp_thread           DW ?

mp_flags            DW ?

mp_get_proc         DW ?

mp_processor_sign   DD ?
mp_apic             DD ?
mp_proc             DW ?

isa_redir_arr       DD 16 DUP(?,?)

apic_arr            DW 256 DUP(?)

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
    mov eax,es:[bx].user_handler
    or eax,eax
    jz msr_irq_default_error&nr
;
    mov ds,es:[bx].user_data
    push cs
    push OFFSET msr_irq_handle_done&nr
    push es:[bx].user_handler
    xor ax,ax
    mov es,ax
    retf

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
    mov eax,es:[bx].user_handler
    or eax,eax
    jz mem_irq_default_error&nr
;
    mov ds,es:[bx].user_data
    push cs
    push OFFSET mem_irq_handle_done&nr
    push es:[bx].user_handler
    xor ax,ax
    mov es,ax
    retf

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
    mov ax,flat_sel
    mov ds,ax    
;    
    call InitApic
;
    mov ax,SEG data
    mov ds,ax
    mov eax,12345678h
    mov ds:mp_processor_sign,eax
    GetApicId
    mov ds:mp_apic,edx
    cmp edx,3
    je ap_debug
;
    mov ax,5
    call DelayMs
;    
    AddDebugCore

; comment to start AP cores
    
stopl:
   cli
   jmp stopl


    

ap_wait:    
    sti
    hlt
    StartProcessor

ap_debug:
    StartSmpDebug


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
    ret
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
    ret
get_id_msr Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetProcessorId
;
;               DESCRIPTION:    Get processor #
;
;       RETURNS:        AX  Processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_processor_id_name    DB 'Get Processor ID',0

get_processor_id_mem  Proc far
    push ds
    push ebx
;    
    mov ax,apic_mem_sel
    mov ds,ax
    mov ebx,ds:APIC_ID
    shr ebx,24
    add bx,bx
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:[bx].apic_arr
    mov ax,ds:ps_id
;
    pop ebx
    pop ds
    retf32
get_processor_id_mem Endp

get_processor_id_msr Proc far
    push ds
    push bx
    push ecx
;
    mov ecx,MSR_APIC_ID
    rdmsr
    movzx bx,al
    add bx,bx
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:[bx].apic_arr
    mov ax,ds:ps_id
;
    pop ecx
    pop bx
    pop ds
    retf32
get_processor_id_msr Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetProcessor
;
;               DESCRIPTION:    Get processor selector
;
;       RETURNS:        FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_processor_mem  Proc far
    push ds
    push ax
    push ebx
;    
    mov ax,apic_mem_sel
    mov ds,ax
    mov ebx,ds:APIC_ID
    shr ebx,24
    add bx,bx
    mov ax,SEG data
    mov ds,ax
    mov fs,ds:[bx].apic_arr
;
    pop ebx
    pop ax
    pop ds
    ret
get_processor_mem Endp

get_processor_msr Proc far
    push ds
    push eax
    push bx
    push ecx
    push edx
;
    mov ecx,MSR_APIC_ID
    rdmsr
    movzx bx,al
    add bx,bx
    mov ax,SEG data
    mov ds,ax
    mov fs,ds:[bx].apic_arr
;
    pop edx
    pop ecx
    pop bx
    pop eax
    pop ds
    ret
get_processor_msr Endp
   
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
    ret
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
    ret
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
    push ds
    push eax
    push ecx
    push edx
;    
    shl edx,24
    mov cx,apic_mem_sel
    mov ds,cx

simemLoop:
    cli
    mov ecx,ds:APIC_ICR
    test cx,1000h
    jz simemDo
;
    sti
    ipause
    jmp simemLoop

simemDo:    
    mov ds:APIC_ICR+10h,edx
;
    mov ah,40h
    movzx eax,ax
    mov ds:APIC_ICR,eax
    sti
;
    pop edx
    pop ecx
    pop eax
    pop ds
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
    push eax
    push ecx
;
    mov ah,40h
    movzx eax,ax
    push eax
    push edx

simsrLoop:
    mov ecx,MSR_APIC_ICR
    cli
    rdmsr
    test ax,1000h
    jz simsrDo
;    
    sti
    ipause
    jmp simsrLoop
    
simsrDo:
    pop edx    
    pop eax
;
    mov ecx,MSR_APIC_ICR
    wrmsr
    sti
;
    pop ecx
    pop eax
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
    GetProcessor
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
    mov eax,81h
    mov es:APIC_TIMER,eax
;
    pop esi
    pop edx
    pop ecx
    pop es
    pop ds
    ret
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
    GetProcessor
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
    mov eax,81h
    mov ecx,MSR_APIC_TIMER
    wrmsr
;
    pop esi
    pop edx
    pop ecx
    pop ds
    ret
start_apic_msr_timer  Endp


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
    ret
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
    ret
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
    ret
get_pci_irq  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ResumeProcessor
;
;               DESCRIPTION:    Send a resume request
;
;       PARAMETERS:     FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resume_processor_name    DB 'Resume Processor',0

resume_processor  Proc far
    push ds
    push ax
    push edx
;
    mov ax,SEG data
    mov ds,ax
    mov al,80h
    mov edx,fs:ps_apic
    call ds:mp_int_proc
;
    pop edx
    pop ax
    pop ds
    ret
resume_processor  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   PreemptProcessor
;
;               DESCRIPTION:    Send a preempt req
;
;       PARAMETERS:     FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

preempt_processor_name    DB 'Preempt Processor',0

preempt_processor  Proc far
    push ds
    push ax
    push edx
;
    mov ax,SEG data
    mov ds,ax
    mov al,81h
    mov edx,fs:ps_apic
    call ds:mp_int_proc
;
    pop edx
    pop ax
    pop ds
    ret
preempt_processor  Endp

       
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
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET get_id_mem
    mov di,OFFSET get_id_name
    xor cl,cl
    mov ax,get_apic_id_nr
    RegisterOsGate
;
    mov si,OFFSET send_eoi_mem
    mov di,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
    RegisterOsGate
;
    mov si,OFFSET start_apic_mem_timer
    mov di,OFFSET start_apic_timer_name
    xor cl,cl
    mov ax,start_sys_timer_nr
    RegisterOsGate
;
    mov si,OFFSET reload_apic_mem_timer
    mov di,OFFSET reload_apic_timer_name
    xor cl,cl
    mov ax,reload_sys_timer_nr
    RegisterOsGate
;
    mov si,OFFSET get_processor_id_mem
    mov di,OFFSET get_processor_id_name
    xor dx,dx
    mov ax,get_processor_id_nr
    RegisterBimodalUserGate
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
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET get_id_msr
    mov di,OFFSET get_id_name
    xor cl,cl
    mov ax,get_apic_id_nr
    RegisterOsGate
;
    mov si,OFFSET send_eoi_msr
    mov di,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
    RegisterOsGate
;
    mov si,OFFSET start_apic_msr_timer
    mov di,OFFSET start_apic_timer_name
    xor cl,cl
    mov ax,start_sys_timer_nr
    RegisterOsGate
;
    mov si,OFFSET reload_apic_msr_timer
    mov di,OFFSET reload_apic_timer_name
    xor cl,cl
    mov ax,reload_sys_timer_nr
    RegisterOsGate
;
    mov si,OFFSET get_processor_id_msr
    mov di,OFFSET get_processor_id_name
    xor dx,dx
    mov ax,get_processor_id_nr
    RegisterBimodalUserGate
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
    ret
SetupMsrGates   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:               StartCore
;
;               DESCRIPTION:    Start a CPU core
;
;       PARAMETERS:     EDX         APIC ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartCore   Proc near
    push ds
    push es
    push fs
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
    db 66h
    sgdt fword ptr es:[di].ap_gdt
;
    db 66h
    sidt fword ptr es:[di].ap_idt
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
    stc
    jmp scDone

scOk:
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
    pop fs
    pop es
    pop ds
    ret
StartCore   Endp
   
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
    mov dh,0A0h
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
    GetApicId
    shl edx,24
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
;               description:    Disable IRQ in PIC controller
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
    mov eax,cr3
    mov cr3,eax
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
    mov eax,cr3
    mov cr3,eax
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
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:apic_arr
;    
    xor ax,ax
    mov bh,1
    mov bl,1
    FindPciClassAll
    jc apic_pr_done
;
    mov cl,10h
    ReadPciDword
    mov cl,al    
    and ax,0FFFCh
;
    mov si,ax
;
    mov ax,get_pci_irq_nr
    IsValidOsGate
    jc apic_pr_dir
;
    mov cl,PCI_interrupt_pin
    ReadPciByte
    GetPciIrqNr
    jmp apic_pr_read

apic_pr_dir:
    mov cl,PCI_interrupt_line
    ReadPciByte

apic_pr_read:
    call ReadIoApicInt

apic_pr_done:
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
    mov cx,500
    mov ax,4
    CreateThread

init_thread_done:
    popa
    pop es
    pop ds
    ret
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
    mov si,OFFSET get_pci_irq
    mov di,OFFSET get_pci_irq_name
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
;               NAME:                   ResumeInt
;
;               DESCRIPTION:    Resume IPI int
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resume_int:
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    call ds:mp_eoi_proc
;
    pop ax
    pop ds
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ShutdownInt
;
;               DESCRIPTION:    Shutdown IPI int
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shutdown_int:
    mov di,apic_mem_sel
    mov es,di    
    mov edi,es:APIC_CURR_COUNT
    Shutdown
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   PreemptInt
;
;               DESCRIPTION:    Preempt IPI int
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

preempt_int:
    push ds
    push es
    push fs
    pushad
;
    mov ax,SEG data
    mov ds,ax
    call ds:mp_eoi_proc
    DoPreemptProcessor
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
ipi80   DW      80h,    OFFSET resume_int
ipi81   DW      81h,    OFFSET preempt_int
ipi82   DW      82h,    OFFSET shutdown_int
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
    mov ax,SEG data
    mov ds,ax
    mov ds:mp_get_proc,0
    mov ax,ds:mp_flags
;    
    test ds:mp_flags,MP_FLAG_MEM
    jnz init_smp_check_msr
;   
    mov ds:mp_get_proc,OFFSET get_processor_mem
    jmp init_smp_done

init_smp_check_msr:
    test ds:mp_flags,MP_FLAG_MSR
    jnz init_smp_done
;    
    mov ds:mp_get_proc,OFFSET get_processor_msr

init_smp_done:
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET resume_processor
    mov di,OFFSET resume_processor_name
    xor cl,cl
    mov ax,resume_processor_nr
    RegisterOsGate
;
    mov si,OFFSET preempt_processor
    mov di,OFFSET preempt_processor_name
    xor cl,cl
    mov ax,preempt_processor_nr
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
;               NAME:                   SetupIrq
;
;               DESCRIPTION:    Setup IRQs to IOAPIC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupIrq    Proc near
    push ds
    push eax
    push bx
    push cx
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
    pop cx
    pop bx
    pop eax
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
    mov bx,SEG data
    mov es,bx
    mov di,OFFSET apic_arr
    xor ax,ax
    mov cx,100h
    rep stosw
    mov es:mp_flags,0
;
    mov ax,SEG data
    mov ds,ax
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
    GetProcessor
    movzx edx,es:[di].ap_apic_id
    movzx bx,dl
    add bx,bx
    mov ds:[bx].apic_arr,fs    
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
; decomment to start more than 3 cores
;
;    cmp bp,3
;    je init_table_next
;    
    movzx edx,es:[di].ap_apic_id
    call StartCore
    jc init_table_next    
;    
    cmp bp,1
    jnz init_ap_create
;    
    call InitSmp
    call InitIpi
    
init_ap_create:       
    push es
    push di    
    mov di,ds:mp_get_proc
    mov ax,cs
    mov es,ax
    CreateProcessor    
    mov ax,es
    mov fs,ax
    pop di
    pop es
;
    mov fs:ps_apic,edx
;
    movzx bx,dl
    add bx,bx
    mov ds:[bx].apic_arr,fs
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
    mov di,OFFSET init_apic_thread
    HookInitTasking

init_apic_gates_ok:     
    ret
init    ENDP

code    ENDS

    END init

