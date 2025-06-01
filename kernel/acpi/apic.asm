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
INCLUDE ..\os\core.inc
INCLUDE ..\acpi\acpitab.inc
INCLUDE ..\os\realmon.def
INCLUDE ..\bios\vbe.inc

INCLUDE ..\user.def
INCLUDE ..\user.inc

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
gi_long_ads         DD ?
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

ioapic_core_irq_struc   STRUC

ioapic_sel      DW ?
ioapic_num      DB ?

ioapic_core_irq_struc   ENDS

time_seg  STRUC

t_phys              DD ?,?
t_spinlock          DW ?
t_clock_tics        DW ?
t_system_time       DD ?,?

t_hpet_guard        DD ?
t_prev_hpet         DD ?
t_hpet_sel          DW ?
t_hpet_factor       DD ?
t_hpet_counters     DW ?

time_seg  ENDS


data    SEGMENT byte public 'DATA'

bsp_id              DD ?

ioapic_spinlock     DW ?

detected_irqs       DD ?,?

ioapic_count        DW ?
ioapic_arr          DW 16 DUP(?)

redir_arr           DB 16 DUP(?)

global_int_arr      DD 256 DUP(?,?,?,?)

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use32 'CODE'

    assume cs:code

    extern setup_hpet_timer:near    
    
    extern GetAcpiTable:near
    extern GetApicTable:near
    extern InitApicTimer:near

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
;               NAME:           Get IOAPIC state
;
;               DESCRIPTION:    Get state for IOAPIC int
;
;               PARAMETERS:     AL      Global int #
;
;               RETURNS:        EDX:EAX IOAPIC entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ioapic_state_name   DB 'Get IO-APIC State',0

get_ioapic_state    Proc far
    push ds
    push fs
    push ebx
;    
    mov ebx,apic_mem_sel
    mov ds,ebx
    mov ebx,APIC_ISR + 50h
    mov edx,ds:[ebx]
;
    mov bx,APIC_IRR + 50h
    mov edx,ds:[ebx]        
;    
    mov ebx,SEG data
    mov ds,ebx
;
    movzx ebx,al
    shl ebx,4
    add ebx,OFFSET global_int_arr
;    
    mov al,ds:[ebx].gi_ioapic_id
    mov fs,ds:[ebx].gi_ioapic_sel
;       
    mov bl,10h
    add bl,al
    add bl,al
;
    LockIoApic   
    mov fs:ioapic_regsel,bl
    mov eax,fs:ioapic_window
;
    inc bl
    mov fs:ioapic_regsel,bl
    mov edx,fs:ioapic_window
    UnlockIoApic
;    
    pop ebx
    pop fs
    pop ds
    ret
get_ioapic_state    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddIoApicHandler
;
;       DESCRIPTION:    Add core mover for IO-APIC
;
;       PARAMETERS:     AL      IO-APIC entry
;                       FS      IO-APIC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIoApicHandler    Proc near
    push es
;    
    push eax
    mov eax,SIZE ioapic_core_irq_struc
    AllocateSmallGlobalMem
    pop eax
;    
    mov es:ioapic_sel,fs
    mov es:ioapic_num,al
;
    pop es
    ret
AddIoApicHandler    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ISA IRQ handler
;
;               DESCRIPTION:    Code for patching into ISA (edge mode) IRQ handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code should not contain near jumps or references to near labels!

isa_irq_handler_struc   STRUC

isa_irq_linear          DD ?
isa_irq_handler_ads     DD ?,?
isa_irq_handler_data    DW ?
isa_irq_type            DW ?
isa_irq_chain           DW ?
isa_irq_nr              DB ?
isa_irq_detect_nr       DB ?

isa_irq_handler_struc   ENDS

IsaIrqStart:

isa_irq_handler     isa_irq_handler_struc <>

IsaIrqEntry:
    pushad
    push ds
    push es
    push fs
;
    mov al,cs:isa_irq_nr
    EnterInt
;       
    mov ax,word ptr fs:cs_curr_irq_nr
    or ax,ax
    jz IsaIrqPrevOk
;    
    mov ax,fs:cs_nested_irq_count
    mov bx,ax
    inc ax
    cmp ax,MAX_IRQ_NESTING
    jne IsaIrqAddStack
;
    int 3

IsaIrqAddStack:
    mov fs:cs_nested_irq_count,ax
;
    shl bx,2
    mov eax,dword ptr fs:cs_curr_irq_nr
    mov fs:[bx].cs_nested_irq_stack,eax

IsaIrqPrevOk: 
    movzx bx,cs:isa_irq_nr
    mov word ptr fs:cs_curr_irq_nr,bx
    mov fs:cs_curr_irq_retries,0
;
    sti

IsaIrqRetry:    
    mov ds,cs:isa_irq_handler_data
    call fword ptr cs:isa_irq_handler_ads
;
    mov bx,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    jmp cs:isa_irq_chain

IsaIrqExit:
    cli    
;
    mov ax,word ptr fs:cs_curr_irq_nr
    or ah,ah
    jz IsaIrqExitCountOk
;
    mov fs:cs_curr_irq_count,0
    mov al,fs:cs_curr_irq_retries
    inc al
    mov fs:cs_curr_irq_retries,al
;    
    sti
    cmp al,100
    jne IsaIrqRetry
;
    int 3    
    jmp IsaIrqRetry
    
IsaIrqExitCountOk: 
    mov word ptr fs:cs_curr_irq_nr,0
    mov bx,fs:cs_nested_irq_count
    or bx,bx
    jz IsaIrqExitNestingOk
;
    dec bx
    mov fs:cs_nested_irq_count,bx
    shl bx,2
    mov eax,fs:[bx].cs_nested_irq_stack
    mov dword ptr fs:cs_curr_irq_nr,eax
    
IsaIrqExitNestingOk:
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop eax
    verr ax
    jz IrqExitFs
;    
    xor eax,eax

IrqExitFs:
    mov fs,eax
;
    pop eax
    verr ax
    jz IrqExitEs
;    
    xor eax,eax

IrqExitEs:
    mov es,eax
;
    pop eax
    verr ax
    jz IrqExitDs
;    
    xor eax,eax

IrqExitDs:
    mov ds,eax
;
    popad
    iretd

IsaIrqDetect:
    mov ax,SEG data
    mov ds,ax
    movzx bx,cs:isa_irq_detect_nr
    shl bx,4
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
    movzx dx,cs:isa_irq_detect_nr
    cmp dx,64
    jae IsaIrqDetectDone
;    
    mov bx,OFFSET detected_irqs
    bts ds:[bx],dx

IsaIrqDetectDone:
    retf

IsaIrqEnd:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ISA IRQ chaining
;
;               DESCRIPTION:    Code for adding at end of ISA IRQ handler in order to chain
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code should not contain near jumps or references to near labels!

isa_irq_chain_struc  STRUC

isa_irch_handler_ads     DD ?,?
isa_irch_handler_data    DW ?
isa_irch_chain           DW ?

isa_irq_chain_struc ENDS

IsaIrqChainStart:

isa_irch_handler      isa_irq_chain_struc <>

IsaIrqChainEntry:
    push bx
    mov ds,cs:[bx].isa_irch_handler_data
    call fword ptr cs:[bx].isa_irch_handler_ads
    pop bx
;
    mov si,bx
    add bx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    jmp cs:[si].isa_irch_chain

IsaIrqChainEnd:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIsaIrq
;
;       DESCRIPTION:    Create new ISA IRQ context
;
;       PARAMETERS:     AL           IRQ #
;
;       RETURNS:        DS:ESI       Address of entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIsaIrq   Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    push eax
    mov eax,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector32
;
    mov eax,cs
    mov ds,eax
    mov eax,flat_sel
    mov es,eax
    mov esi,OFFSET IsaIrqStart
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es:[edx].isa_irq_linear,edx
    mov word ptr es:[edx].isa_irq_chain,OFFSET IsaIrqExit - OFFSET IsaIrqStart
    mov dword ptr es:[edx].isa_irq_handler_ads,OFFSET IsaIrqDetect - OFFSET IsaIrqStart
    mov word ptr es:[edx].isa_irq_handler_ads+4,bx
    mov es:[edx].isa_irq_handler_data,0
    pop eax
    mov es:[edx].isa_irq_nr,al
    mov es:[edx].isa_irq_detect_nr,al
    mov es:[edx].isa_irq_type,IRQ_TYPE_ISA
;
    mov ds,bx
    mov esi,OFFSET IsaIrqEntry - OFFSET IsaIrqStart
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
CreateIsaIrq   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ForceLevelIrq
;
;       DESCRIPTION:    Force IRQ to level triggered mode
;
;       PARAMETERS:     AL      Global int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

force_level_irq_name    DB 'Force Level IRQ',0

force_level_irq Proc far
    push ds
    push eax
    push ebx
;    
    mov ebx,SEG data
    mov ds,ebx    
    movzx ebx,al
    shl ebx,4
    add ebx,OFFSET global_int_arr    
    mov [ebx].gi_trigger_mode,0A0h
;
    pop ebx
    pop eax
    pop ds
    ret
force_level_irq Endp    
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RequestIrqHandler
;
;       DESCRIPTION:    Request ISA IRQ-based interrupt-handler
;
;       PARAMETERS:     DS      Data passed to handler
;                       ES:EDI  Handler address
;                       AL      Global int #
;                       AH      Priority
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_irq_handler_name    DB 'Request ISA IRQ Handler',0

request_irq_handler Proc far
    push fs
    pushad
;
    movzx ebx,al
    shl ebx,4
    mov edx,SEG data
    mov fs,edx
    mov esi,fs:[ebx].global_int_arr.gi_long_ads
    mov bx,fs:[ebx].global_int_arr.gi_handler_sel
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
    push eax
;   
    or esi,esi
    jz rihLongOk
;
    AddLongIrq

rihLongOk:
    mov fs,ebx
    mov edx,fs:isa_irq_linear
    mov eax,flat_sel
    mov fs,eax
;
    mov al,fs:[edx].isa_irq_detect_nr
    cmp al,-1
    jne rihReplace

rihChain:
    push ds
    push es
    push ecx
    push esi
    push edi
;
    mov eax,flat_sel
    mov ds,eax
    mov es,eax
;    
    mov esi,edx
    GetSelectorBaseSize
    push ecx
    mov eax,ecx        
    add eax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    AllocateSmallLinear
    push edx
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
    mov ebp,edi
;    
    xchg edx,ds:[edx].isa_irq_linear
    xor ecx,ecx
    FreeLinear
;
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET IsaIrqChainStart
    mov ecx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop edx
    pop ecx
    add ecx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    CreateCodeSelector32
;    
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
;
    mov fs:[ebp].isa_irch_handler_data,ds
    mov fs:[ebp].isa_irch_handler_ads,edi
    mov word ptr fs:[ebp].isa_irch_handler_ads+4,es
    mov eax,ebp
    sub eax,edx
    add eax,OFFSET IsaIrqChainEntry - OFFSET IsaIrqChainStart
    sub eax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    cmp eax,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    jae rihChainPrev
;    
    add eax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    xchg ax,fs:[edx].isa_irq_chain
    mov fs:[ebp].isa_irch_chain,ax
    jmp rihChainDone

rihChainPrev:
    mov edx,ebp
    sub edx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    add eax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    xchg ax,fs:[edx].isa_irch_chain
    mov fs:[ebp].isa_irch_chain,ax
    jmp rihChainDone
        
rihReplace:    
    mov fs:[edx].isa_irq_handler_data,ds
    mov fs:[edx].isa_irq_handler_ads,edi
    mov word ptr fs:[edx].isa_irq_handler_ads+4,es
    mov fs:[edx].isa_irq_detect_nr,-1

rihChainDone:
    pop eax
;    
    movzx ebx,al
    shl ebx,4
    add ebx,OFFSET global_int_arr
    mov edx,SEG data
    mov fs,edx
    mov dl,fs:[ebx].gi_prio
    cmp ah,dl
    jbe rihDone
;
    mov fs:[ebx].gi_prio,ah
    mov al,fs:[ebx].gi_int_num
    FreeInt

rihChangePrio:
    mov al,fs:[ebx].gi_prio
    mov cx,1
    AllocateInts
    jnc rihPrioOk
;
    dec fs:[ebx].gi_prio
    jmp rihChangePrio    

rihPrioOk:    
    push ds
    push ebx
;
    mov esi,fs:[ebx].gi_long_ads
    or esi,esi
    jz rihLongPrioOk
;
    push ebx
    xor bl,bl
    SetupLongIntGate
    pop ebx

rihLongPrioOk:    
    mov ds,fs:[ebx].gi_handler_sel
    mov esi,OFFSET IsaIrqEntry - OFFSET IsaIrqStart
    xor bl,bl
    SetupIntGate
;    
    pop ebx
    pop ds
;
    mov fs:[ebx].gi_int_num,al
;
    push ds
    mov eax,SEG data
    mov ds,eax
;    
    mov al,fs:[ebx].gi_ioapic_id
    movzx edx,fs:[ebx].gi_int_num
    mov dh,fs:[ebx].gi_trigger_mode
    mov fs,fs:[ebx].gi_ioapic_sel
    call AddIoApicHandler
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
;
    mov edx,ds:bsp_id
    shl edx,24
    mov fs:ioapic_window,edx
    UnlockIoApic
    pop ds

rihDone:
    popad
    pop fs    
    ret
request_irq_handler Endp

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

    public SetupLocalApic

SetupLocalApic    Proc near
    push es
    push eax
    push ebx
;    
    mov ebx,apic_mem_sel
    mov es,ebx
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
    xor eax,eax
    mov es:APIC_TPR,eax
;
    pop ebx
    pop eax
    pop es    
    ret
SetupLocalApic    Endp
   
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
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
;
    pop eax
    pop ds
    ret
send_eoi Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyIrq
;
;       DESCRIPTION:    Notify IRQ occurred
;
;       PARAMETERS:     AL      Int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_irq_name    DB 'Notify IRQ',0

notify_irq  Proc far
    push ds
    push es
    push eax
    push ebx
    push edx
;    
    push eax
    movzx ebx,al
    mov eax,SEG data
    mov ds,eax
    shl ebx,4
    add ebx,OFFSET global_int_arr
    mov al,ds:[ebx].gi_ioapic_id
    mov dx,ds:[ebx].gi_ioapic_sel
    or dx,dx
    jz niNoIoApic
;       
    mov es,edx
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

niNoIoApic:
    pop eax
;
    movzx edx,al
    cmp edx,64
    jae niDone
;    
    mov ebx,OFFSET detected_irqs
    bts ds:[ebx],edx

niDone:
    pop edx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
notify_irq  Endp    

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
    mov eax,SEG data
    mov ds,eax
    mov ecx,64
    mov esi,OFFSET global_int_arr

edLoop:
    mov dl,ds:[esi].gi_prio
    or dl,dl
    jnz edNext
;
    mov dx,ds:[esi].gi_ioapic_sel
    or dx,dx
    jz edNext
;    
    mov es,dx
    movzx edx,ds:[esi].gi_int_num
    mov dh,ds:[esi].gi_trigger_mode
    mov al,ds:[esi].gi_ioapic_id
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
;
    mov edx,ds:bsp_id
    shl edx,24
    mov es:ioapic_window,edx
    UnlockIoApic

edNext:
    add esi,16
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
    push eax
;       
    mov eax,SEG data
    mov ds,eax
    mov ds:detected_irqs,0
    call EnableDetect
;
    mov ax,1
    WaitMilliSec
;
    mov ds:detected_irqs,0       
    mov ds:detected_irqs+4,0       
;
    pop eax
    pop ds
    ret
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
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:detected_irqs
    mov edx,ds:detected_irqs+4
;
    pop ds
    ret
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
    push ebx
    push ecx
    push esi
;
    mov eax,apic_mem_sel
    mov ds,eax
    mov eax,10000h
    mov ds:APIC_TIMER,eax
;    
    mov eax,SEG data
    mov ds,eax
;    
    movzx ecx,ds:ioapic_count
    mov esi,OFFSET ioapic_arr

daiApicLoop:
    push ds
    push ecx
    mov ds,ds:[esi]
;    
    mov ecx,24
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
    pop ecx
    pop ds
    add esi,2
    loop daiApicLoop    
;
    call SetupLocalApic
;
    mov eax,apic_mem_sel
    mov ds,eax
    mov eax,ds:APIC_ISR + 20h
;
    pop esi
    pop ecx
    pop ebx
    pop ds
    ret
disable_all_irq Endp

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
;               NAME:           TimerInt
;
;               DESCRIPTION:    Timer interrupt
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timer_int:
    pushad
    push ds
    push es
    push fs
;
    mov al,-1
    EnterInt    
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop eax
    verr ax
    jz timer_fs_ok
;
    xor eax,eax

timer_fs_ok:
    mov fs,eax
;    
    pop eax
    verr ax
    jz timer_es_ok
;
    xor eax,eax

timer_es_ok:
    mov es,eax
;    
    pop eax
    verr ax
    jz timer_ds_ok
;
    xor eax,eax

timer_ds_ok:
    mov ds,eax
;    
    popad
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
    pushad
    push ds
    push es
    push fs
;
    mov al,-1
    EnterInt    
    lock or fs:cs_flags,CS_FLAG_PREEMPT
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop eax
    verr ax
    jz preempt_fs_ok
;
    xor eax,eax

preempt_fs_ok:
    mov fs,eax
;    
    pop eax
    verr ax
    jz preempt_es_ok
;
    xor eax,eax

preempt_es_ok:
    mov es,eax
;    
    pop eax
    verr ax
    jz preempt_ds_ok
;
    xor eax,eax

preempt_ds_ok:
    mov ds,eax
;    
    popad
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           tlb_int
;
;           DESCRIPTION:    TLB invalidate int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tlb_int:
    pushad
    push ds
    push es
    push fs
    push gs
;
    mov al,-1
    EnterInt
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop eax
    verr ax
    jz TlbExitGs
;    
    xor eax,eax

TlbExitGs:
    mov gs,eax
;
    pop eax
    verr ax
    jz TlbExitFs
;    
    xor eax,eax

TlbExitFs:
    mov fs,eax
;
    pop eax
    verr ax
    jz TlbExitEs
;    
    xor eax,eax

TlbExitEs:
    mov es,eax
;
    pop eax
    verr ax
    jz TlbExitDs
;    
    xor eax,eax

TlbExitDs:
    mov ds,eax
    popad
    iretd    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           wakeup_int
;
;           DESCRIPTION:    Wakeup int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wakeup_int:
    pushad
    push ds
    push es
    push fs
    push gs
;
    mov al,-1
    EnterInt
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
    IpiWakeup
    LeaveInt
;
    pop eax
    verr ax
    jz WiExitGs
;    
    xor eax,eax

WiExitGs:
    mov gs,eax
;
    pop eax
    verr ax
    jz WiExitFs
;    
    xor eax,eax

WiExitFs:
    mov fs,eax
;
    pop eax
    verr ax
    jz WiExitEs
;    
    xor eax,eax

WiExitEs:
    mov es,eax
;
    pop eax
    verr ax
    jz WiExitDs
;    
    xor eax,eax

WiExitDs:
    mov ds,eax
    popad
    iretd    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           SetupInts
;
;               DESCRIPTION:    Setup ints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SetupInts Proc near
    push ds
    pushad

    mov ax,cs
    mov ds,ax
    xor bl,bl
;
    mov al,0Fh
    mov esi,OFFSET spurious_int
    SetupIntGate
;    
    mov ax,setup_long_spurious_int_nr
    IsValidOsGate
    jc siSpurOk
;    
    mov al,0Fh
    SetupLongSpuriousInt

siSpurOk:
    mov al,25h
    mov esi,OFFSET tlb_int
    SetupIntGate
;        
    mov al,26h
    mov esi,OFFSET wakeup_int
    SetupIntGate
;
    popad
    pop ds
    ret
SetupInts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           SetupTimerInts
;
;               DESCRIPTION:    Setup timer ints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SetupTimerInts Proc near
    push ds
    pushad

    mov ax,cs
    mov ds,ax
    xor bl,bl
;
    mov al,40h
    mov esi,OFFSET timer_int
    SetupIntGate
;    
    mov ax,setup_long_timer_int_nr
    IsValidOsGate
    jc stiTimerOk
;    
    mov al,40h
    SetupLongTimerInt

stiTimerOk:
    mov al,80h
    mov esi,OFFSET preempt_int
    SetupIntGate
;    
    mov ax,setup_long_preempt_int_nr
    IsValidOsGate
    jc stiPreemptOk
;    
    mov al,80h
    SetupLongPreemptInt

stiPreemptOk:
    mov ax,setup_long_schedule_int_nr
    IsValidOsGate
    jc stiSchedOk
;    
    mov al,82h
    SetupLongScheduleInt

stiSchedOk:
    mov al,83h
    mov esi,OFFSET timer_int
    SetupIntGate
;    
    mov ax,setup_long_timer_int_nr
    IsValidOsGate
    jc stiPreemptTimerOk
;    
    mov al,83h
    SetupLongTimerInt

stiPreemptTimerOk:
    popad
    pop ds
    ret
SetupTimerInts Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           InitIoApic
;
;               DESCRIPTION:    Init IO-APIC
;
;               PARAMETERS:     ES      Apic table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitIoApic    Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:ioapic_count,0
;
    push es
    mov ax,SEG data
    mov es,ax
    mov ecx,256 * 4
    xor eax,eax
    mov edi,OFFSET global_int_arr
    rep stosd        
    pop es
;
    mov ecx,16
    mov edi,OFFSET global_int_arr

init_ioapic_isa_trigger_mode:
    mov ds:[edi].gi_trigger_mode,0
    mov ds:[edi].gi_long_ads,0
    add edi,16
    loop init_ioapic_isa_trigger_mode
;
    mov ecx,256-16

init_ioapic_pci_trigger_mode:
    mov [edi].gi_trigger_mode,0A0h
    add edi,16
    loop init_ioapic_pci_trigger_mode
;        
    mov eax,1000h
    AllocateBigLinear
    mov eax,es:apic_phys
    or ax,33h
    xor ebx,ebx
    SetPageEntry    
    mov bx,apic_mem_sel
    mov ecx,1000h
    CreateDataSelector16
;
    mov edi,OFFSET apic_entries
    movzx ecx,es:act_size
    sub ecx,OFFSET apic_entries - OFFSET apic_phys

init_ioapic_table_loop:
    mov al,es:[edi].apic_type
    cmp al,1
    jne init_ioapic_table_next    
;
    push ecx
    mov eax,1000h
    AllocateBigLinear
    mov eax,es:[edi].aio_phys
    or ax,33h
    xor ebx,ebx
    SetPageEntry    
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
    inc ecx
    pop ds
;    
    movzx ebx,ds:ioapic_count
    add ebx,ebx
    mov ds:[ebx].ioapic_arr,ax
    inc ds:ioapic_count
;
    mov ebx,es:[edi].aio_int_base
    shl ebx,4
    add ebx,OFFSET global_int_arr
    xor dl,dl

init_ioapic_loop:
    mov ds:[ebx].gi_ioapic_sel,ax
    mov ds:[ebx].gi_ioapic_id,dl
    add ebx,16
    inc dl
    loop init_ioapic_loop
;    
    pop ecx

init_ioapic_table_next:
    movzx eax,es:[edi].apic_len
    add edi,eax
    sub ecx,eax
    ja init_ioapic_table_loop
;    
    GetApicId
    mov ds:bsp_id,edx
    ret
InitIoApic    Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIrqHandlers
;
;       DESCRIPTION:    Create default IRQ handlers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIrqHandlers    Proc near
    mov eax,SEG data
    mov ds,eax
    mov ebx,OFFSET global_int_arr
    mov ecx,64
    xor dl,dl

create_irq_loop:
    mov ax,ds:[ebx].gi_ioapic_sel
    or ax,ax
    jz create_irq_next
;    
    push ecx
    mov cx,1
    xor al,al
    mov ds:[bx].gi_prio,al
    AllocateInts
    mov ds:[bx].gi_int_num,al
    pop ecx
;
    push ds
    push ebx
;    
    push eax
    mov ds:[ebx].gi_long_ads,0
;    
    mov ax,create_long_irq_nr
    IsValidOsGate
    jc create_irq32
;
    mov al,dl
    CreateLongIrq
    mov ds:[ebx].gi_long_ads,esi
    pop eax
;
    push eax
    xor bl,bl
    SetupLongIntGate
    
create_irq32:
    mov al,dl
    call CreateIsaIrq
    pop eax
;        
    xor bl,bl
    SetupIntGate
    mov ax,ds
;    
    pop ebx
    pop ds
    mov ds:[ebx].gi_handler_sel,ax

create_irq_next:
    add ebx,16
    inc dl
    loop create_irq_loop
;
    ret
CreateIrqHandlers    Endp
      
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
    mov eax,SEG data
    mov ds,eax
;
    mov edi,OFFSET apic_entries
    movzx ecx,es:act_size
    sub ecx,OFFSET apic_entries - OFFSET apic_phys

init_apic_loop:
    mov al,es:[edi].apic_type
    cmp al,2
    jne init_apic_next
;
    mov al,es:[edi].ao_bus
    or al,al
    jnz init_apic_next
;
    mov al,es:[edi].ao_source
    cmp al,16
    jae init_apic_next
;
    mov eax,es:[edi].ao_int
    cmp eax,80h
    jae init_apic_next
;
    mov ebx,eax
    shl ebx,4
    add ebx,OFFSET global_int_arr
;
    mov ax,es:[edi].ao_flags
    test al,1
    jz init_apic_redir_pol_ok
;
    test al,2
    jz init_apic_redir_pol_high

init_apic_redir_pol_low:
    or [ebx].gi_trigger_mode,20h
    jmp init_apic_redir_pol_ok

init_apic_redir_pol_high:
    and [ebx].gi_trigger_mode,NOT 20h

init_apic_redir_pol_ok:
    test al,4
    jz init_apic_next
;
    test al,8
    jz init_apic_redir_edge

init_apic_redir_level:
    or [ebx].gi_trigger_mode,80h
    jmp init_apic_next

init_apic_redir_edge:
    and [ebx].gi_trigger_mode,7Fh

init_apic_next:
    movzx eax,es:[edi].apic_len
    add edi,eax
    sub ecx,eax
    ja init_apic_loop
    ret
ProcessApicTable    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Name:           GetValue
;
;   Purpose:        Get value from environment
;
;   Parameters:     ES:EDI   Name
;
;   Returns:        NC          Found
;                   AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
        public GetValue
        
GetValue    Proc near
    push ds
    push ebx
    push ecx
    push esi
;
    LockSysEnv
    mov ds,bx
    xor esi,esi
    
find_val:
    push edi

find_val_loop:
    cmpsb
    jnz find_val_next
;       
    mov al,es:[edi]
    or al,al
    jnz find_val_loop
    mov al,[esi]
    cmp al,'='
    je find_val_found

find_val_next:
    pop edi

find_val_next_bp:
    lodsb
    or al,al
    jnz find_val_next_bp
;
    mov al,[esi]
    or al,al
    jne find_val
;
    xor ax,ax
    stc
    jmp find_val_done

find_val_found:
    pop edi
    inc esi  
    xor ax,ax

find_val_digit:
    mov bl,[esi]
    inc esi
    sub bl,'0'
    jc find_val_save
;
    cmp bl,10
    jnc find_val_save
;       
    mov cx,10
    mul cx
    add al,bl
    adc ah,0
    jmp find_val_digit

find_val_save:
    clc

find_val_done:
    pushf
    UnlockSysEnv
    popf
;
    pop esi
    pop ecx
    pop ebx
    pop ds
    ret
GetValue    Endp
    
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

hpet_tab    DB 'HPET'

    public init_apic
        
init_apic    PROC near
;
    mov eax,2000h
    AllocateBigLinear
;
    mov bx,time_data_sel
    mov ecx,2000h
    CreateDataSelector16
;
    mov es,ebx
    xor edi,edi
    mov ecx,800h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    add edx,1000h
    GetPageEntry
    xor al,al
    mov es:t_phys,eax
    mov es:t_phys+4,ebx
;
    mov eax,SEG data
    mov ds,eax
    mov ds:ioapic_spinlock,0
;    
    mov al,34h
    out TIMER_CONTROL,al
    jmp short $+2
    mov al,0
    out TIMER0,al
    jmp short $+2
    out TIMER0,al
    jmp short $+2
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET get_ioapic_state
    mov edi,OFFSET get_ioapic_state_name
    xor cl,cl
    mov ax,get_ioapic_state_nr
    RegisterOsGate
;
    mov esi,OFFSET send_eoi
    mov edi,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_irq
    mov edi,OFFSET notify_irq_name
    xor cl,cl
    mov ax,notify_irq_nr
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
    mov esi,OFFSET force_level_irq
    mov edi,OFFSET force_level_irq_name
    xor cl,cl
    mov ax,force_level_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET request_irq_handler
    mov edi,OFFSET request_irq_handler_name
    xor cl,cl
    mov ax,request_irq_handler_nr
    RegisterOsGate
;
    mov eax,dword ptr cs:hpet_tab
    call GetAcpiTable
    jc init_hpet_obj
;    
    mov ebx,es:hpett_phys_base
    jmp init_hpet_check

init_hpet_obj: 
    mov ebx,0FED00000h

init_hpet_check:    
    mov eax,1000h
    AllocateBigLinear
    mov eax,ebx
    or ax,33h
    xor ebx,ebx
    SetPageEntry
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es,bx
;
    mov eax,es:hpet_period
    or eax,eax
    jz init_hpet_done
;
    cmp eax,5F5E100h
    ja init_hpet_done
;
    mov eax,es:hpet_cap
    or al,al
    jz init_hpet_done
;
    mov ax,time_data_sel
    mov ds,ax
    mov ds:t_hpet_sel,es
;    
    mov eax,es:hpet_config
    and al,NOT 2
    mov es:hpet_config,eax
;    
    mov eax,es:hpet_period
    mov ds:t_hpet_factor,eax
;
    mov eax,es:hpet_cap
    mov al,ah
    and ax,1Fh
    inc ax
    mov ds:t_hpet_counters,ax
;
    movzx ecx,ax
    mov ebx,OFFSET hpet_counter_arr    

init_hpet_loop:
    mov eax,es:[ebx].hpetc_config
    and ax,NOT 4004h
    mov es:[ebx].hpetc_config,eax
    add ebx,SIZE hpet_counter_struc
    loop init_hpet_loop
;    
    mov eax,es:hpet_config
    and al,NOT 3
    or al,1
    mov es:hpet_config,eax
;
    call setup_hpet_timer

init_hpet_done:    
    call GetApicTable
;    
    call DisablePic    
    call SetupInts
    call SetupTimerInts
    call InitIoApic
    call CreateIrqHandlers
    call ProcessApicTable
    call SetupLocalApic
    call EnableDetect
;    
    call InitApicTimer

init_apic_gates_ok:     
    ret
init_apic    ENDP

code    ENDS

    END
    
