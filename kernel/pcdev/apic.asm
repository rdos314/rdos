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
; apic.asm
; APIC module
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
INCLUDE ..\acpi\acpi.inc

INCLUDE ..\user.def
INCLUDE ..\user.inc

INCLUDE pci.inc

ipause   MACRO
    db 0F3h
    db 90h
    ENDM


; PCI IRQs active low, edge triggered

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

hpet_table  STRUC

hpet_base       acpi_table <>

hpett_event_block    DD ?
hpett_flags          DD ?
hpett_phys_base      DD ?,?
hpett_nr             DB ?
hpett_min_tics       DW ?

hpet_table  ENDS

ioapic_data_seg STRUC

ioapic_regsel       DB ?
ioapic_resv         DB 15 DUP(?)

ioapic_window       DD ?

ioapic_data_seg ENDS

global_int_struc    STRUC

gi_handler_sel      DW ?
gi_ioapic_sel       DW ?
gi_ioapic_id        DB ?
gi_int_num          DB ?
gi_prio             DB ?
gi_trigger_mode     DB ?

global_int_struc    ENDS

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

        
data    SEGMENT byte public 'DATA'

mp_processor_sign   DD ?

time_spinlock       DW ?
clock_tics          DW ?
system_time         DD ?,?

ioapic_spinlock     DW ?

apic_tics           DD ?
apic_rest           DW ?

hpet_guard          DD ?
prev_hpet           DD ?
hpet_sel            DW ?
hpet_factor         DD ?
hpet_counters       DW ?

detected_irqs       DD ?

isa_redir_arr       DD 16 DUP(?,?)

ioapic_count        DW ?
ioapic_arr          DW 16 DUP(?)

global_int_arr      DD 256 DUP(?,?)

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
;
    ShutdownCore

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LockIoApic
;
;       DESCRIPTION:    Lock IO-APIC 
;
;       PARAMETERS:     DS      SEG data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockIoApic  MACRO
    local SpinLock
    local Get

SpinLock:    
    mov ax,ds:ioapic_spinlock
    or ax,ax
    je Get
;
    sti
    pause
    jmp SpinLock

Get:
    cli
    inc ax
    xchg ax,ds:ioapic_spinlock
    or ax,ax
    jne SpinLock
        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlockIoApic
;
;       DESCRIPTION:    Unlock IO-APIC
;
;       PARAMETERS:     DS      SEG data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockIoApic    MACRO
    mov ds:ioapic_spinlock,0
    sti
                ENDM
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           IRQ handler
;
;               DESCRIPTION:    Code for patching into IRQ handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code should not contain near jumps or references to near labels!

irq_handler_struc   STRUC

irq_linear          DD ?
irq_handler_ads     DD ?,?
irq_handler_data    DW ?
irq_chain           DW ?
irq_detect_nr       DB ?

irq_handler_struc   ENDS

IrqStart:

irq_handler     irq_handler_struc <>

IrqEntry:
    push ds
    push es
    push fs
    pushad
;
    EnterInt
    sti
;       
    mov ds,cs:irq_handler_data
    call fword ptr cs:irq_handler_ads
;
    mov bx,OFFSET IrqEnd - OFFSET IrqStart
    jmp cs:irq_chain

IrqExit:
    cli    
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

IrqDetect:
    mov ax,SEG data
    mov ds,ax
    movzx bx,cs:irq_detect_nr
    shl bx,3
    add bx,OFFSET global_int_arr
    mov al,ds:[bx].gi_ioapic_id
    mov es,ds:[bx].gi_ioapic_sel
;       
    mov bl,10h
    add bl,al
    add bl,al
;    
    LockIoApic
    mov es:ioapic_regsel,bl
    mov eax,10000h
    mov es:ioapic_window,eax
;
    inc bl
    mov es:ioapic_regsel,bl
    xor eax,eax
    mov es:ioapic_window,eax
    UnlockIoApic
;
    movzx dx,cs:irq_detect_nr
    cmp dx,24
    jae IrqDetectDone
;    
    mov bx,OFFSET detected_irqs
    bts ds:[bx],dx

IrqDetectDone:
    retf32

IrqEnd:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           IRQ chaining
;
;               DESCRIPTION:    Code for adding at end of IRQ handler in order to chain
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code should not contain near jumps or references to near labels!

irq_chain_struc  STRUC

irch_handler_ads     DD ?,?
irch_handler_data    DW ?
irch_chain           DW ?

irq_chain_struc ENDS

IrqChainStart:

irch_handler      irq_chain_struc <>

IrqChainEntry:
    push bx
    mov ds,cs:[bx].irch_handler_data
    call fword ptr cs:[bx].irch_handler_ads
    pop bx
;
    mov si,bx
    add bx,OFFSET IrqChainEnd - OFFSET IrqChainStart
    jmp cs:[si].irch_chain

IrqChainEnd:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIrq
;
;       DESCRIPTION:    Create new IRQ context
;
;       PARAMETERS:     AL           IRQ # (for detect)
;
;       RETURNS:        DS:ESI       Address of entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIrq   Proc near
    push es
    push eax
    push bx
    push ecx
    push edx
    push edi
;
    push ax
    mov eax,OFFSET IrqEnd - OFFSET IrqStart
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector16
;
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,OFFSET IrqStart
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es:[edx].irq_linear,edx
    mov word ptr es:[edx].irq_chain,OFFSET IrqExit - OFFSET IrqStart
    mov dword ptr es:[edx].irq_handler_ads,OFFSET IrqDetect - OFFSET IrqStart
    mov word ptr es:[edx].irq_handler_ads+4,bx
    mov es:[edx].irq_handler_data,0
    pop ax
    mov es:[edx].irq_detect_nr,al
;
    mov ds,bx
    mov esi,OFFSET IrqEntry - OFFSET IrqStart
;
    pop edi
    pop edx
    pop ecx
    pop bx
    pop eax
    pop es
    ret
CreateIrq   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RequestIrqHandler
;
;       DESCRIPTION:    Request an IRQ-based interrupt-handler
;
;       PARAMETERS:     DS      Data passed to handler
;                       ES:EDI  Handler address
;                       AL      Global int #
;                       AH      Priority
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_irq_handler_name    DB 'Request IRQ Handler',0

request_irq_handler Proc far
    push fs
    pushad
;
    movzx bx,al
    shl bx,3
    mov dx,SEG data
    mov fs,dx
    mov bx,fs:[bx].global_int_arr.gi_handler_sel
    or bx,bx
    jz rihDone
;
    cmp ah,31
    jbe rihPrioHighOk
;
    mov ah,31

rihPrioHighOk:
    or ah,ah
    jne rihPrioLowOk
;
    mov ah,1    

rihPrioLowOk:
    push ax
;   
    mov fs,bx
    mov edx,fs:irq_linear
    mov ax,flat_sel
    mov fs,ax
;
    mov al,fs:[edx].irq_detect_nr
    cmp al,-1
    jne rihReplace

rihChain:
    push ds
    push es
    push ecx
    push esi
    push edi
;
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;    
    mov esi,edx
    GetSelectorBaseSize
    push ecx
    mov eax,ecx        
    add eax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    AllocateSmallLinear
    push edx
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
    mov ebp,edi
;    
    xchg edx,ds:[edx].irq_linear
    xor ecx,ecx
    FreeLinear
;
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET IrqChainStart
    mov ecx,OFFSET IrqChainEnd - OFFSET IrqChainStart
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop edx
    pop ecx
    add ecx,OFFSET IrqChainEnd - OFFSET IrqChainStart
    CreateCodeSelector16
;    
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
;
    mov fs:[ebp].irch_handler_data,ds
    mov fs:[ebp].irch_handler_ads,edi
    mov word ptr fs:[ebp].irch_handler_ads+4,es
    mov eax,ebp
    sub eax,edx
    add ax,OFFSET IrqChainEntry - OFFSET IrqChainStart
    sub ax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    cmp ax,OFFSET IrqEnd - OFFSET IrqStart
    jae rihChainPrev
;    
    add ax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    xchg ax,fs:[edx].irq_chain
    mov fs:[ebp].irch_chain,ax
    jmp rihChainDone

rihChainPrev:
    mov edx,ebp
    sub edx,OFFSET IrqChainEnd - OFFSET IrqChainStart
    add ax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    xchg ax,fs:[edx].irch_chain
    mov fs:[ebp].irch_chain,ax
    jmp rihChainDone
        
rihReplace:    
    mov fs:[edx].irq_handler_data,ds
    mov fs:[edx].irq_handler_ads,edi
    mov word ptr fs:[edx].irq_handler_ads+4,es
    mov fs:[edx].irq_detect_nr,-1

rihChainDone:
    pop ax
;    
    movzx bx,al
    shl bx,3
    add bx,OFFSET global_int_arr
    mov dx,SEG data
    mov fs,dx
    mov dl,fs:[bx].gi_prio
    cmp ah,dl
    jbe rihDone
;
    mov fs:[bx].gi_prio,ah
    mov al,fs:[bx].gi_int_num
    FreeInt

rihChangePrio:
    mov al,fs:[bx].gi_prio
    mov cx,1
    AllocateInts
    jnc rihPrioOk
;
    dec fs:[bx].gi_prio
    jmp rihChangePrio    

rihPrioOk:    
    push ds
    push bx
;
    mov ds,fs:[bx].gi_handler_sel
    mov esi,OFFSET IrqEntry - OFFSET IrqStart
    xor bl,bl
    SetupIntGate
;    
    pop bx
    pop ds
;
    mov fs:[bx].gi_int_num,al
;
    push ds
    mov ax,SEG data
    mov ds,ax
;    
    mov al,fs:[bx].gi_ioapic_id
    movzx edx,fs:[bx].gi_int_num
    mov dh,fs:[bx].gi_trigger_mode
    mov fs,fs:[bx].gi_ioapic_sel
;       
    mov bl,10h
    add bl,al
    add bl,al
;
    LockIoApic   
    mov fs:ioapic_regsel,bl
    mov fs:ioapic_window,edx
;
    inc bl
    mov fs:ioapic_regsel,bl
    mov edx,0FF000000h
    mov fs:ioapic_window,edx
    UnlockIoApic
    pop ds

rihDone:
    popad
    pop fs    
    retf32
request_irq_handler Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           MSI handler
;
;               DESCRIPTION:    Code for creating MSI interrupt handlers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code should not contain near jumps or references to near labels!

msi_handler_struc   STRUC

msi_linear          DD ?
msi_handler_ads     DD ?,?
msi_handler_data    DW ?

msi_handler_struc   ENDS

MsiStart:

msi_handler     msi_handler_struc <>

MsiEntry:
    push ds
    push es
    push fs
    pushad
;
    EnterInt
    sti
;       
    mov ds,cs:msi_handler_data
    call fword ptr cs:msi_handler_ads
;
    cli    
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
    
MsiDefault:
    retf32

MsiEnd:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateMsi
;
;       DESCRIPTION:    Create new MSI context
;
;       RETURNS:        DS:ESI       Address of entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMsi   Proc near
    push es
    push eax
    push bx
    push ecx
    push edx
    push edi
;
    mov eax,OFFSET MsiEnd - OFFSET MsiStart
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector16
;
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,OFFSET MsiStart
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es:[edx].msi_linear,edx
    mov dword ptr es:[edx].msi_handler_ads,OFFSET MsiDefault - OFFSET MsiStart
    mov word ptr es:[edx].msi_handler_ads+4,bx
    mov es:[edx].msi_handler_data,0
;
    mov ds,bx
    mov esi,OFFSET MsiEntry - OFFSET MsiStart
;
    pop edi
    pop edx
    pop ecx
    pop bx
    pop eax
    pop es
    ret
CreateMsi   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetupMsiHandler
;
;       DESCRIPTION:    Setup MSI handler
;
;       PARAMETERS:     BX      MSI handler
;                       DS      Data passed to handler
;                       ES:EDI  Handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupMsiHandler   Proc near
    push fs
    push ax
    push edx
;
    mov fs,bx
    mov edx,fs:msi_linear
    mov ax,flat_sel
    mov fs,ax
;
    mov fs:[edx].msi_handler_data,ds
    mov fs:[edx].msi_handler_ads,edi
    mov word ptr fs:[edx].msi_handler_ads+4,es
;
    pop edx
    pop ax
    pop fs    
    ret
SetupMsiHandler   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SetupLocalApic
;
;               DESCRIPTION:    Setup local APIC
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupLocalApic    Proc near
    push es
    push eax
    push bx
;    
    mov bx,apic_mem_sel
    mov es,bx
;
    mov eax,10000h
    mov es:APIC_LINT0,eax
;
    mov eax,10000h
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
;
    pop bx
    pop eax
    pop es    
    ret
SetupLocalApic    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EnableTpr
;
;               DESCRIPTION:    Set TPR to allow "lowest priority ints"
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableTpr    Proc near
    push es
    push eax
;    
    mov ax,apic_mem_sel
    mov es,ax
;
    xor eax,eax
    mov es:APIC_TPR,eax
;
    pop eax
    pop es    
    ret
EnableTpr    Endp
   
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
    mov dx,SEG data
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
;               NAME:           Test gate
;
;               DESCRIPTION:    Test gate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_gate_name    DB 'Test Gate',0

test_gate_pr  Proc far
    mov ax,SEG data
    mov ds,ax
    mov eax,ds:detected_irqs
    retf32
test_gate_pr    Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           GetId
;
;               DESCRIPTION:    Get own ID
;
;       RETURNS:        EDX     Apic ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_id_name    DB 'Get Apic ID',0

get_id  Proc far
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
get_id Endp
   
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

send_eoi  Proc far
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
send_eoi Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendNmi
;
;       DESCRIPTION:    Send NMI request
;
;       PARAMETERS:     FS      Destination processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_nmi_name   DB 'Send NMI', 0

send_nmi Proc far
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
send_nmi Endp
   
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

siLoop:
    mov ecx,ds:APIC_ICR
    test cx,1000h
    jz siDo
;
    ipause
    jmp siLoop

siDo:    
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
    retf32
send_int  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           EnableDetect
;
;   Description:    Enable IRQ detect
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableDetect  Proc near
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    mov cx,18h
    mov si,OFFSET global_int_arr

edLoop:
    mov dl,ds:[si].gi_prio
    or dl,dl
    jnz edNext
;
    mov dx,ds:[si].gi_ioapic_sel
    or dx,dx
    jz edNext
;    
    mov es,dx
    movzx edx,ds:[si].gi_int_num
    mov dh,ds:[si].gi_trigger_mode
    mov al,ds:[si].gi_ioapic_id
;       
    mov bl,10h
    add bl,al
    add bl,al
;   
    LockIoApic
    mov es:ioapic_regsel,bl
    mov es:ioapic_window,edx
;
    inc bl
    mov es:ioapic_regsel,bl
    mov edx,0FF000000h
    mov es:ioapic_window,edx
    UnlockIoApic

edNext:
    add si,8
    loop edLoop
;
    popad
    pop es
    pop ds    
    ret
EnableDetect  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setup_irq_detect
;
;           description:    Setup IRQ detect
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_irq_detect_name   DB 'Setup IRQ detect',0

setup_irq_detect    Proc far
    push ds
    push ax
;       
    mov ax,SEG data
    mov ds,ax
    mov ds:detected_irqs,0
    call EnableDetect
;
    mov ax,1
    WaitMilliSec
;
    mov ds:detected_irqs,0       
;
    pop ax
    pop ds
    retf32
setup_irq_detect    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           poll_irq_detect
;
;           description:    Poll detected IRQs
;
;       RETURNS:    EAX      Detected IRQs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_irq_detect_name    DB 'Poll IRQ detect',0

poll_irq_detect Proc far
    push ds
;       
    mov ax,SEG data
    mov ds,ax
    mov eax,ds:detected_irqs
;
    pop ds
    retf32
poll_irq_detect Endp

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
    push si
;
    mov ax,apic_mem_sel
    mov ds,ax
    mov eax,10000h
    mov ds:APIC_TIMER,eax
;    
    mov ax,SEG data
    mov ds,ax
;    
    mov cx,ds:ioapic_count
    mov si,OFFSET ioapic_arr

daiApicLoop:
    push ds
    push cx
    mov ds,ds:[si]
;    
    mov cx,24       
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
    pop cx
    pop ds
    add si,2
    loop daiApicLoop    
;
    call SetupLocalApic
    call EnableTpr
;
    mov ax,apic_mem_sel
    mov ds,ax
    mov eax,ds:APIC_ISR + 20h
;
    pop si
    pop cx
    pop bx
    pop ds
    retf32
disable_all_irq Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMsiParam
;
;       DESCRIPTION:    Get MSI parameters
;
;       PARAMETERS:     AL      Int base
;
;       RETURNS:        EDX     MSI address
;                       AX      MSI data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_msi_param_name    DB 'Get MSI Param',0

get_msi_param  Proc far
    mov ah,1
    mov edx,0FEEFF000h
    retf32
get_msi_param  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RequestMsiHandler
;
;       DESCRIPTION:    Request an MSI-based interrupt-handler
;
;       PARAMETERS:     DS      Data passed to handler
;                       ES:EDI  Handler address
;                       AL      Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_msi_handler_name    DB 'Request MSI Handler',0

request_msi_handler  Proc far
    push bx
    push esi
;    
    push ds
    call CreateMsi
    xor bl,bl
    SetupIntGate
    mov bx,ds
    pop ds    
    call SetupMsiHandler
;
    pop esi
    pop bx
    retf32
request_msi_handler  Endp

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
    mov ax,apic_mem_sel
    mov ds,ax
    mov eax,83h
    mov ds:APIC_TIMER,eax
    xor eax,eax
;
    pop ds
    retf32
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
    mov cx,SEG data
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
    clc
;
    pop edx
    pop ecx
    pop eax
    pop ds
    retf32
reload_sys_preempt_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartSysTimer
;
;           DESCRIPTION:    Start HPET sys timer
;
;           RETURNS:        EAX      Update tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_hpet_timer_name    DB 'Start HPET Timer', 0

start_hpet_timer    Proc far
    push ds
    push es
    push bx
    push edx
;
    mov ax,SEG data
    mov ds,ax
    mov es,ds:hpet_sel
    mov bx,OFFSET hpet_counter_arr    
    mov eax,es:[bx].hpetc_config
    test ax,8000h
    jnz start_hpet_msi

start_hpet_iopic:
;    mov eax,es:hpet_config
;    or al,2
;    mov es:hpet_config,eax
    push bx
;    
    mov bx,OFFSET global_int_arr + 8 * 2
    mov ax,ds:[bx].gi_ioapic_sel
;    
    push ax
    mov al,ds:[bx].gi_ioapic_id
    pop ds
;       
    mov bl,10h
    add bl,al
    add bl,al
;    
    mov edx,2982h
    mov ds:ioapic_regsel,bl
    mov ds:ioapic_window,edx
;
    inc bl
    mov ds:ioapic_regsel,bl
    mov edx,0FF000000h
    mov ds:ioapic_window,edx
;
    pop bx
    mov eax,es:[bx].hpetc_config
;    and ax,NOT 7E0Ah
    or ax,506h
    mov es:[bx].hpetc_config,eax   
    jmp start_hpet_done

start_hpet_msi: 
    mov ax,140h
    mov edx,0FEEFF000h
    mov es:[bx].hpetc_msi_data,eax
    mov es:[bx].hpetc_msi_ads,edx
;
    mov eax,es:[bx].hpetc_config
    and ax,NOT 0Ah
    or ax,4104h 
    mov es:[bx].hpetc_config,eax

start_hpet_done:
    xor eax,eax
;
    pop edx
    pop bx
    pop es
    pop ds
    retf32
start_hpet_timer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReloadSysTimer
;
;           DESCRIPTION:    Reload HPET timer
;
;           PARAMETERS:     AX      Reload count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reload_hpet_timer_name    DB 'Reload HPET Timer', 0

reload_hpet_timer    Proc far
    push ds
    push eax
    push edx
;    
    mov dx,SEG data
    mov ds,dx
    movzx eax,ax
    mov edx,31F5C4EDh
    mul edx
    div ds:hpet_factor
    inc eax
;    
    mov ds,ds:hpet_sel
    mov ds:hpet_int_status,1
    add eax,ds:hpet_count
    mov ds:hpet_counter_arr.hpetc_compare,eax
    mov eax,ds:hpet_counter_arr.hpetc_compare
    cmp eax,ds:hpet_count
    jg reload_hpet_ok
;
    stc
    jmp reload_hpet_done
     
reload_hpet_ok:
    clc

reload_hpet_done:
    pop edx
    pop eax
    pop ds    
    retf32
reload_hpet_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           StartPreemptionTimer
;
;               DESCRIPTION:    Start APIC timer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_apic_preempt_timer_name    DB 'Start Apic Preempt Timer', 0

start_apic_preempt_timer    Proc far
    push ds
    mov ax,apic_mem_sel
    mov ds,ax
    mov eax,80h
    mov ds:APIC_TIMER,eax
    pop ds
    retf32
start_apic_preempt_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ReloadPreemptionTimer
;
;               DESCRIPTION:    Reload APIC timer with preemption only
;
;               PARAMETERS:     AX      Reload tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reload_apic_preempt_timer_name    DB 'Reload Apic Preempt Timer', 0

reload_apic_preempt_timer    Proc far
    push ds
    push eax
    push ecx
    push edx
;
    mov cx,SEG data
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
reload_apic_preempt_timer  Endp

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
    mov ax,SEG data
    mov ds,ax

gstSpinLock:    
    mov ax,ds:time_spinlock
    or ax,ax
    je gstGet
;
    sti
    pause
    jmp gstSpinLock

gstGet:
    cli
    inc ax
    xchg ax,ds:time_spinlock
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
    xchg ax,ds:clock_tics
    sub ax,dx
    movzx eax,ax
    add ds:system_time,eax
    adc ds:system_time+4,0
;    
    mov eax,ds:system_time
    mov edx,ds:system_time+4
;    
    mov ds:time_spinlock,0
    sti
    pop ds
    retf32
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
    push ds
    push es
    push ecx
;
    mov ax,SEG data
    mov ds,ax

ghtSpinLock:    
    mov ax,ds:time_spinlock
    or ax,ax
    je ghtGet
;
    sti
    pause
    jmp ghtSpinLock

ghtGet:
    cli
    inc ax
    xchg ax,ds:time_spinlock
    or ax,ax
    jne ghtSpinLock
;
    mov es,ds:hpet_sel
    mov eax,es:hpet_count
    mov edx,eax
    xchg edx,ds:prev_hpet
    sub eax,edx
    mul ds:hpet_factor
    add eax,ds:hpet_guard
    adc edx,0
;
    mov ecx,31F5C4EDh
    div ecx
    mov ds:hpet_guard,edx
    add ds:system_time,eax
    adc ds:system_time+4,0
;    
    mov eax,ds:system_time
    mov edx,ds:system_time+4
;    
    mov ds:time_spinlock,0
    sti
;
    pop ecx
    pop es
    pop ds
    retf32
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
    push bx
    mov bx,SEG data
    mov ds,bx
    mov ds:system_time,eax
    mov ds:system_time+4,edx
    pop bx
    pop ds
    retf32
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

has_global_timer_name    DB 'Has Global Timer', 0
has_local_timer_name    DB 'Has Global Timer', 0

has_global_timer  Proc far
    clc
    retf32
has_global_timer    Endp

has_local_timer  Proc far
    stc
    retf32
has_local_timer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SpuriousInt
;
;               DESCRIPTION:    Spurious int
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spurious_int:
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           nmi_int
;
;               DESCRIPTION:    Default NMI handler
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi_int:
    push ds
    push es
    push fs
    pushad
;
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
;
    popad
    pop fs
    pop es
    pop ds
    iretd

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
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
;    
    TimerExpired
;
    popad
    pop fs
    pop es
    pop ds
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           HpetInt
;
;               DESCRIPTION:    HPET interrupt
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hpet_int:
    push ds
    push es
    push fs
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    mov ds,ds:hpet_sel
    mov edx,ds:hpet_int_status
    mov ds:hpet_int_status,edx
;
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
;  
    TimerExpired

hpet_int_done:
    popad
    pop fs
    pop es
    pop ds
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
    push ds
    push es
    push fs
    pushad
;    
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
;    
    PreemptExpired
;
    popad
    pop fs
    pop es
    pop ds
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           MixedInt
;
;               DESCRIPTION:    Mixed timer & preempt interrupt
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mixed_int:
    push ds
    push es
    push fs
    pushad
;    
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
;    
    PreemptTimerExpired
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
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
;
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
;               NAME:           SetupInts
;
;               DESCRIPTION:    Setup ints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ipi_tab:
;
;                       int #   Entry                   
;
pi02   DW      02h,    OFFSET nmi_int
pi0F   DW      0Fh,    OFFSET spurious_int
pi40   DW      40h,    OFFSET timer_int
pi80   DW      80h,    OFFSET preempt_int
pi81   DW      81h,    OFFSET tlb_flush_int
pi82   DW      82h,    OFFSET hpet_int
pi83   DW      83h,    OFFSET mixed_int
       DW      0FFFFh

;
; tabell offsets
;
ipi_nr          EQU 0
ipi_entry       EQU 2

SetupInts Proc near
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
    SetupIntGate
    add di,4
    jmp ipiLoop
    
ipiDone:
    popad
    pop ds
    ret
SetupInts Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ProcessApicTable
;
;               DESCRIPTION:    Define basic APIC vars
;
;               PARAMETERS:     ES      Apic table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessApicTable    Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:ioapic_count,0
;
    mov bx,OFFSET isa_redir_arr
    xor edx,edx
    mov eax,40h
    mov cx,16

init_apic_redir_loop:
    mov [bx],eax
    add bx,4
    mov [bx],edx
    add bx,4
    inc al
    loop init_apic_redir_loop
;
    mov bx,OFFSET isa_redir_arr + 2 * 8
    mov eax,10000h
    mov [bx],eax 
;
    push es
    mov ax,SEG data
    mov es,ax
    mov cx,256 * 2
    xor eax,eax
    mov di,OFFSET global_int_arr
    rep stosd        
    pop es
;
    mov eax,1000h
    AllocateBigLinear
    mov eax,es:apic_phys
    or ax,33h
    SetPhysicalPage    
    mov bx,apic_mem_sel
    mov ecx,1000h
    CreateDataSelector16
;
    mov di,OFFSET apic_entries
    mov cx,es:act_size
    sub cx,OFFSET apic_entries - OFFSET apic_phys

init_apic_loop:
    mov al,es:[di].apic_type
    cmp al,1
    je init_apic_ioapic
;    
    cmp al,2
    je init_apic_redir
;
    jmp init_apic_next    

init_apic_ioapic:
    push ecx
    mov eax,1000h
    AllocateBigLinear
    mov eax,es:[di].aio_phys
    or ax,33h
    SetPhysicalPage    
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov ax,bx
;
    push ds
    mov ds,ax
    mov ds:ioapic_regsel,1
    mov ecx,ds:ioapic_window
    shr ecx,16
    inc cx
    pop ds
;    
    mov bx,ds:ioapic_count
    add bx,bx
    mov ds:[bx].ioapic_arr,ax
    inc ds:ioapic_count
;
    mov ebx,es:[di].aio_int_base
    shl bx,3
    add bx,OFFSET global_int_arr
    xor dl,dl

init_ioapic_loop:
    mov ds:[bx].gi_ioapic_sel,ax
    mov ds:[bx].gi_ioapic_id,dl
    add bx,8
    inc dl
    loop init_ioapic_loop
;    
    pop ecx
    jmp init_apic_next

init_apic_redir:
    mov al,es:[di].ao_bus
    or al,al
    jnz init_apic_next
;
    mov al,es:[di].ao_source
    cmp al,16
    jae init_apic_next
;
    movzx bx,al
    shl bx,3
    add bx,OFFSET isa_redir_arr
;
    mov eax,es:[di].ao_int
    cmp eax,80h
    jae init_apic_next
;
    add al,40h
    mov [bx],al
;
    mov ax,es:[di].ao_flags
    test al,1
    jz init_apic_redir_pol_ok
;
    test al,2
    jz init_apic_redir_pol_high

init_apic_redir_pol_low:
    or word ptr [bx],2000h
    jmp init_apic_redir_pol_ok

init_apic_redir_pol_high:
    and word ptr [bx], NOT 2000h

init_apic_redir_pol_ok:
    test al,4
    jz init_apic_next
;
    test al,8
    jz init_apic_redir_edge

init_apic_redir_level:
    or word ptr [bx],8000h
    jmp init_apic_next

init_apic_redir_edge:
    and word ptr [bx],7FFFh

init_apic_next:
    movzx ax,es:[di].apic_len
    add di,ax
    sub cx,ax
    ja init_apic_loop
    ret
ProcessApicTable    Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetupDefaultIrqHandlers
;
;       DESCRIPTION:    Setup default IRQ handlers
;
;       PARAMETERS:     ES      Apic table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDefaultIrqHandlers    Proc near
    mov ax,SEG data
    mov ds,ax
    mov bx,OFFSET global_int_arr
    mov cx,18h
    xor dl,dl

setup_irq_loop:
    mov ax,ds:[bx].gi_ioapic_sel
    or ax,ax
    jz setup_irq_next
;    
    push cx
    mov cx,1
    xor al,al
    mov ds:[bx].gi_prio,al
    AllocateInts
    mov ds:[bx].gi_int_num,al
    mov ds:[bx].gi_trigger_mode,0A9h
    pop cx
;
    push ds
    push bx
;    
    push ax
    mov al,dl
    call CreateIrq
    pop ax
;        
    xor bl,bl
    SetupIntGate
    mov ax,ds
;    
    pop bx
    pop ds
    mov ds:[bx].gi_handler_sel,ax

setup_irq_next:
    add bx,8
    inc dl
    loop setup_irq_loop
;
    mov cx,10h
    mov bx,OFFSET isa_redir_arr

setup_isa_redir_loop:
    mov edx,ds:[bx]
    test edx,10000h
    jnz setup_isa_redir_next
;    
    sub dl,40h
    movzx si,dl
    shl si,3
    or dh,9
    mov ds:[si].global_int_arr.gi_trigger_mode,dh

setup_isa_redir_next:
    add bx,8
    loop setup_isa_redir_loop    
;
    ret
SetupDefaultIrqHandlers Endp    
    
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
    mov ax,SEG data
    mov ds,ax
    mov ax,apic_mem_sel
    mov es,ax

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
;               NAME:                   SendInit
;
;               DESCRIPTION:    Send init request
;
;       PARAMETERS:     EDX     Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInit Proc near
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
    mov ax,20
    call DelayMs
;
    pop edx
    pop eax
    pop ds    
    ret
SendInit Endp
       
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
    mov ax,1
    call DelayMs
;
    pop edx
    pop ecx
    pop eax
    pop ds    
    ret
SendStartup Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartCore
;
;       DESCRIPTION:    Start a new AP core
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_core_name DB 'Start Core', 0

start_core   Proc far
    test fs:ps_flags,PS_FLAG_SHUTDOWN
    jz start_core_normal
;
    lock and fs:ps_flags,NOT PS_FLAG_SHUTDOWN

start_core_normal:    
    lock or fs:ps_flags,PS_FLAG_ACTIVE
    SendNmi
    retf32
start_core   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ShutdownCore
;
;       DESCRIPTION:    Shutdown AP core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shutdown_core_name DB 'Shutdown Core', 0

shutdown_core:
    call SetupLocalApic
;
    GetCore
    lock and fs:ps_flags,NOT PS_FLAG_ACTIVE
;
    wbinvd
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax

sdcLoop:    
    cli
    mov ax,enter_c3_nr
    IsValidOsGate
    jc sdcHlt
;
;    EnterC3        
;    jmp sdcCheck

sdcHlt:    
    hlt

sdcCheck:    
    GetCore
    test fs:ps_flags,PS_FLAG_ACTIVE
    jz sdcLoop
;
    mov ax,start_preempt_timer_nr
    IsValidOsGate
    jc sdcCombined
;
    StartPreemptTimer
    jmp sdcDone

sdcCombined:
    StartSysPreemptTimer

sdcDone:
    call EnableTpr
    RunApCore
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BootCore
;
;       DESCRIPTION:    Boot a new AP core, but don't activate it.
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BootCore    Proc near
    push ds
    push es
    pushad
;
    xor edx,edx
    GetPhysicalPage
    push eax
;    
    mov eax,63h
    SetPhysicalPage
;    
    mov edx,1000h
    GetPhysicalPage
    push eax
;    
    mov eax,1063h
    SetPhysicalPage
;
    mov ax,flat_sel
    mov es,ax
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
    mov ax,SEG data
    mov ds,ax
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
    sidt fword ptr es:[di].ap_idt
;    
    mov ax,fs:ps_gdt_size
    dec ax
    mov word ptr es:[di].ap_gdt,ax
    mov eax,fs:ps_gdt_base
    mov dword ptr es:[di].ap_gdt+2,eax
;
    mov ax,fs:ps_ss
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
    mov ds:mp_processor_sign,0
;
    mov edx,fs:ps_apic
    call SendInit
;
    mov eax,ds:mp_processor_sign
    cmp eax,12345678h
    je bcDone
;    
    mov al,1
    call SendStartup
    
    mov cx,250

bcLoop1:
    mov eax,ds:mp_processor_sign
    cmp eax,12345678h
    je bcDone
;    
    mov ax,1
    call DelayMs
    loop bcLoop1
;
    mov al,1    
    call SendStartup
;    
    mov cx,250

bcLoop2:
    mov eax,ds:mp_processor_sign
    cmp eax,12345678h
    je bcDone
;    
    mov ax,1
    call DelayMs
    loop bcLoop2

bcDone:
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    xor al,al
    out 71h,al
    jmp short $+2
;
    pop eax
    mov edx,1000h
    SetPhysicalPage
;
    pop eax
    xor edx,edx
    SetPhysicalPage
;
    popad
    pop es
    pop ds
    ret
BootCore   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DoCreteCore
;
;       DESCRIPTION:    Create a CPU core
;
;       RETURNS:        FS          Processor sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoCreateCore   Proc near    
    push es
    push eax
    push cx
    push edx
;    
    CreateCoreGdt
    CreateCore
    mov es:ps_gdt_base,edx
    mov es:ps_gdt_size,cx
    mov cx,es
    mov fs,cx
;
    pop edx
    pop cx
    pop eax
    pop es
    ret
DoCreateCore   Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           StartupApCores
;
;               DESCRIPTION:    Startup application cores
;
;               PARAMETERS:     ES      Apic table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartupApCores    Proc near
    mov di,OFFSET apic_entries
    mov cx,es:act_size
    sub cx,OFFSET apic_entries - OFFSET apic_phys
    xor bp,bp

init_core_loop:
    mov al,es:[di].apic_type
    or al,al
    jnz init_core_next    
;    
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
    jmp init_core_next

init_ap_proc:
    mov eax,es:[di].ap_flags
    test al,1
    jz init_core_next
;    
    call DoCreateCore    
    movzx edx,es:[di].ap_apic_id
    mov fs:ps_apic,edx
    mov al,es:[di].ap_acpi_id
    mov fs:ps_acpi,al
    call BootCore
;
    inc bp

init_core_next:
    movzx ax,es:[di].apic_len
    add di,ax
    sub cx,ax
    ja init_core_loop

init_core_done:
    ret
StartupApCores   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           DisablePic
;
;               DESCRIPTION:    Disable legacy PIC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisablePic  Proc near
    push edx
;
    cli
    mov al,0FFh
    out 21h,al
    jmp short $+2
    out 0A1h,al
    jmp short $+2
;
    xor edx,edx
    mov al,0Bh
    out 0A0h,al
    jmp short $+2
    in al,0A0h
    mov dh,al

daiSlaveLoop:
    or al,al
    jz daiSlaveOk
;
    mov al,20h
    out 0A0h,al
    jmp short $+2
    mov al,0Bh
    out 0A0h,al
    jmp short $+2
    in al,0A0h
    jmp daiSlaveLoop

daiSlaveOk:
    mov al,0Bh
    out 20h,al
    jmp short $+2
    in al,20h
    mov dl,al

daiMasterLoop:
    or al,al
    jz daiMasterOk
;
    mov al,20h
    out 20h,al
    jmp short $+2
    mov al,0Bh
    out 20h,al
    jmp short $+2
    in al,20h
    jmp daiMasterLoop

daiMasterOk:
    pop edx
    ret
DisablePic  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Init
;
;               DESCRIPTION:    Init apic mp module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

apic_tab    DB 'APIC'
hpet_tab    DB 'HPET'

init    PROC far
    mov ax,SEG data
    mov ds,ax
    mov ds:system_time,0
    mov ds:system_time+4,0
    mov ds:time_spinlock,0
    mov ds:ioapic_spinlock,0
    mov ds:prev_hpet,0
    mov ds:hpet_guard,0
;    
    mov al,34h
    out TIMER_CONTROL,al
    jmp short $+2
    mov al,0
    out TIMER0,al
    jmp short $+2
    out TIMER0,al
    mov ds:clock_tics,0
    jmp short $+2
;
    mov eax,dword ptr cs:apic_tab
    GetAcpiTable
    jc init_apic_gates_ok
;
    push es
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_core
    mov edi,OFFSET start_core_name
    xor cl,cl
    mov ax,start_core_nr
    RegisterOsGate
;
    mov esi,OFFSET shutdown_core
    mov edi,OFFSET shutdown_core_name
    xor cl,cl
    mov ax,shutdown_core_nr
    RegisterOsGate
;
    mov esi,OFFSET send_int
    mov edi,OFFSET send_int_name
    xor cl,cl
    mov ax,send_int_nr
    RegisterOsGate
;
    mov esi,OFFSET get_id
    mov edi,OFFSET get_id_name
    xor cl,cl
    mov ax,get_apic_id_nr
    RegisterOsGate
;
    mov esi,OFFSET send_eoi
    mov edi,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
    RegisterOsGate
;
    mov esi,OFFSET send_nmi
    mov edi,OFFSET send_nmi_name
    xor cl,cl
    mov ax,send_nmi_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_irq_detect
    mov edi,OFFSET setup_irq_detect_name
    xor cl,cl
    mov ax,setup_irq_detect_nr
    RegisterOsGate
;
    mov esi,OFFSET poll_irq_detect
    mov edi,OFFSET poll_irq_detect_name
    xor cl,cl
    mov ax,poll_irq_detect_nr
    RegisterOsGate
;
    mov esi,OFFSET disable_all_irq
    mov edi,OFFSET disable_all_irq_name
    xor cl,cl
    mov ax,disable_all_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET request_irq_handler
    mov edi,OFFSET request_irq_handler_name
    xor cl,cl
    mov ax,request_irq_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET get_msi_param
    mov edi,OFFSET get_msi_param_name
    xor cl,cl
    mov ax,get_msi_param_nr
    RegisterOsGate
;
    mov esi,OFFSET request_msi_handler
    mov edi,OFFSET request_msi_handler_name
    xor cl,cl
    mov ax,request_msi_handler_nr
    RegisterOsGate
;
    mov si,OFFSET set_system_time
    mov di,OFFSET set_system_time_name
    xor cl,cl
    mov ax,set_system_time_nr
    RegisterOsGate
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
;
    mov si,OFFSET get_pit_time
    mov di,OFFSET get_pit_time_name
    xor dx,dx
    mov ax,get_system_time_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET has_local_timer
    mov di,OFFSET has_local_timer_name
    xor dx,dx
    mov ax,has_global_timer_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET test_gate_pr
    mov edi,OFFSET test_gate_name
    xor dx,dx
    mov ax,test_gate_nr
    RegisterBimodalUserGate
;
    mov eax,dword ptr cs:hpet_tab
    GetAcpiTable
    jc init_hpet_done
; 
    push es
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov si,OFFSET get_hpet_time
    mov di,OFFSET get_hpet_time_name
    xor dx,dx
    mov ax,get_system_time_nr
    RegisterBimodalUserGate
    pop es
;
    mov ax,SEG data
    mov ds,ax
;      
    mov eax,1000h
    AllocateBigLinear
    mov eax,es:hpett_phys_base
    or ax,33h
    SetPhysicalPage
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov ds:hpet_sel,bx
    mov es,bx
;    
    mov eax,es:hpet_config
    and al,NOT 2
    mov es:hpet_config,eax
;
    mov eax,es:hpet_period
    mov ds:hpet_factor,eax
;
    mov eax,es:hpet_cap
    mov al,ah
    and ax,1Fh
    inc ax
    mov ds:hpet_counters,ax
;
    mov cx,ax
    mov bx,OFFSET hpet_counter_arr    

init_hpet_loop:
    mov eax,es:[bx].hpetc_config
    and ax,NOT 4004h
    mov es:[bx].hpetc_config,eax
    add bx,SIZE hpet_counter_struc
    loop init_hpet_loop
;    
    mov eax,es:hpet_config
    and al,NOT 3
    or al,1
    mov es:hpet_config,eax
;    
    mov bx,OFFSET hpet_counter_arr    
    mov eax,es:[bx].hpetc_config
    test ax,8000h
    jz init_hpet_done
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_apic_preempt_timer
    mov edi,OFFSET start_apic_preempt_timer_name
    xor cl,cl
    mov ax,start_preempt_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET reload_apic_preempt_timer
    mov edi,OFFSET reload_apic_preempt_timer_name
    xor cl,cl
    mov ax,reload_preempt_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET start_hpet_timer
    mov edi,OFFSET start_hpet_timer_name
    xor cl,cl
    mov ax,start_sys_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET reload_hpet_timer
    mov edi,OFFSET reload_hpet_timer_name
    xor cl,cl
    mov ax,reload_sys_timer_nr
    RegisterOsGate
;
    mov si,OFFSET has_global_timer
    mov di,OFFSET has_global_timer_name
    xor dx,dx
    mov ax,has_global_timer_nr
    RegisterBimodalUserGate

init_hpet_done:    
    pop es
;
    call DisablePic    
    call SetupInts
    call ProcessApicTable
    call SetupDefaultIrqHandlers
    call SetupLocalApic
    call EnableTpr
    call EnableDetect
;    
    call InitApicTimer
    call StartupApCores

init_apic_gates_ok:     
    ret
init    ENDP

code    ENDS

    END init

