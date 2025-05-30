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

ipause   MACRO
    db 0F3h
    db 90h
    ENDM


IRQ_TYPE_ISA    = 5Ch
IRQ_TYPE_PCI    = 9Ah
IA32_EFER       = 0C0000080h

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

mp_processor_sign   DD ?

bsp_id              DD ?

ioapic_spinlock     DW ?

apic_tics           DD ?
apic_rest           DW ?

vbe_desired         DW ?
vbe_width           DW ?
vbe_height          DW ?
vbe_lfb             DD ?
vbe_mode            DW ?
vbe_scan_size       DW ?

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
    dw 30h-1
    dd 92000F80h
    dw 0
gdt10:
    dw 0FFFFh
    dd 9A001400h
    dw 0
gdt18:
    dw 0FFFFh
    dd 92000000h
    dw 0CFh
gdt20:
    dw 0FFFFh
    dd 92001800h
    dw 0
gdt28:
    dw 0FFFFh
    dd 9A000000h
    dw 0AFh

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
    db 0FAh             ; cli
;
    db 0B0h, 0Fh        ; mov al,0Fh
    db 0E6h, 70h        ; out 70h,al
    db 0EBh, 0          ; jmp short $+2
;
    db 32h, 0C0h        ; xor al,al
    db 0E6h, 71h        ; out 71h,al
    db 0EBh, 0          ; jmp short $+2
;
    db 33h, 0C0h        ; xor ax,ax
    db 8Eh, 0D8h        ; mov ds,ax
;    
    db 0BBh, 88h, 0Fh   ; mov bx,0F88h
    db 0Fh, 1, 17h      ; lgdt fword ptr ds:[bx]
;
    db 0Fh, 20h, 0C0h   ; mov eax,cr0
    db 0Ch, 1           ; or al,1
    db 0Fh, 22h, 0C0h   ; mov cr0,eax
;
    db 0EAh             ; jmp 10:0
    dw 0
    dw 10h

real_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           VbeInfo
;
;               DESCRIPTION:    Real get VBE info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0100:0000. It should contain no near jumps!

; this data is located at 1900.

vbe_req_sign = 5A4Fh
vbe_ack_sign = 65A4h

vbe_info_struc  STRUC

vbe_sign    DW ?
vbe_op      DW ?
vbe_bx      DW ?
vbe_cx      DW ?
vbe_res     DW ?
vbe_buf     DW ?

vbe_info_struc  ENDS

vbe_info_start: 
    db 0B8h, 90h, 1     ; mov ax,190h
    db 8Eh, 0C0h        ; mov es,ax
    db 0BFh
    dw OFFSET vbe_buf   ; mov di,OFFSET vbe_buf
    db 0B8h, 40h, 1     ; mov ax,140h
    db 8Eh, 0D0h        ; mov ss,ax
    db 0BCh, 0, 4       ; mov sp,400h

vbe_loop:
    db 26h, 0A1h
    dw OFFSET vbe_op    ; mov ax,es:vbe_op
    db 26h, 8Bh, 1Eh
    dw OFFSET vbe_bx    ; mov bx,es:vbe_bx
    db 26h, 8Bh, 0Eh
    dw OFFSET vbe_cx    ; mov cx,es:vbe_cx
    db 0CDh, 10h        ; int 10h
    db 26h, 0A3h
    dw OFFSET vbe_res   ; mov es:vbe_res,ax
    db 26h, 0C7h, 6
    dw OFFSET vbe_sign   
    dw vbe_ack_sign     ; mov es:vbe_sign,vbe_ack_sign

vbe_wait:
    db 26h, 0A1h 
    dw OFFSET vbe_sign  ; mov ax,es:vbe_sign
    db 3Dh
    dw vbe_req_sign     ; cmp ax,vbe_req_sign
    db 75h, 0F7h        ; jne short vbe_wait
;
    db 26h, 0C7h, 6
    dw OFFSET vbe_res
    dw 0FFFFh           ; mov es:vbe_res,-1
    db 26h, 0A1h
    dw OFFSET vbe_op    ; mov ax,es:vbe_op
    db 83h, 0F8h, 0FFh  ; cmp ax,-1
    db 75h, 0CCh        ; jne short vbe_loop
;
    db 0FAh             ; cli
    db 0B0h, 0Fh        ; mov al,0Fh
    db 0E6h, 70h        ; out 70h,al
    db 0EBh, 0          ; jmp short $+2
;
    db 32h, 0C0h        ; xor al,al
    db 0E6h, 71h        ; out 71h,al
    db 0EBh, 0          ; jmp short $+2
;
    db 33h, 0C0h        ; xor ax,ax
    db 8Eh, 0D8h        ; mov ds,ax
;    
    db 0BBh, 88h, 0Fh   ; mov bx,0F88h
    db 0Fh, 1, 17h      ; lgdt fword ptr ds:[bx]
;
    db 0Fh, 20h, 0C0h   ; mov eax,cr0
    db 0Ch, 1           ; or al,1
    db 0Fh, 22h, 0C0h   ; mov cr0,eax
;
    db 0EAh             ; jmp 10:0
    dw 0
    dw 10h

vbe_info_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ProtMode
;
;               DESCRIPTION:    Unpaged, protected mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01400. It should contain no near jumps!
; offset 0BCh
    
prot_start:
    db 0B8h, 18h, 0     ; mov ax,18h
    db 8Eh, 0D8h        ; mov ds,ax
    db 8Eh, 0C0h        ; mov es,ax
    db 8Eh, 0E0h        ; mov fs,ax
    db 8Eh, 0E8h        ; mov gs,ax
    db 8Eh, 0D0h        ; mov ss,ax
    db 0BCh, 0, 0Fh     ; mov sp,0F00h
;
    db 0B8h, 20h, 0     ; mov ax,20h
    db 8Eh, 0C0h        ; mov es,ax
;    
    db 66h, 26h, 0A1h
    dw OFFSET ap_cr4    ; mov eax,es:ap_cr4
    db 0Fh, 22h, 0E0h   ; mov cr4,eax
;
    db 66h, 26h, 0A1h
    dw OFFSET ap_cr3    ; mov eax,es:ap_cr3
    db 0Fh, 22h, 0D8h   ;mov cr3,eax
;    
    db 66h, 26h, 0Fh, 1, 16h
    dw OFFSET ap_gdt    ; lgdt fword ptr es:ap_gdt
;    
    db 66h, 26h, 0Fh, 1, 1Eh
    dw OFFSET ap_idt    ; lidt fword ptr es:ap_idt
;
    db 66h, 26h, 8Bh, 16h
    dw OFFSET ap_stack_offset  ; mov edx,es:ap_stack_offset
    db 26h, 8Bh, 1Eh
    dw OFFSET ap_stack_sel     ; mov bx,es:ap_stack_sel
;    
    db 66h, 26h, 0A1h
    dw OFFSET ap_cr0    ; mov eax,es:ap_cr0
    db 0Fh, 22h, 0C0h   ; mov cr0,eax
;
    db 0EAh
    dw OFFSET ApInit
    dw SEG code

prot_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           RtMode
;
;               DESCRIPTION:    Unpaged, protected mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01400. It should contain no near jumps!
    
rt_start:
    db 33h, 0C0h        ; xor ax,ax
    db 8Eh, 0D8h        ; mov ds,ax
    db 8Eh, 0E0h        ; mov fs,ax
    db 8Eh, 0E8h        ; mov gs,ax
;
    db 0B8h, 18h, 0     ; mov ax,18h
    db 8Eh, 0D0h        ; mov ss,ax
    db 66h, 0BCh
    dd OFFSET rt_end - rt_start + 1400h + 10h
                        ; mov esp,OFFSET rt_end - rt_start + 1400h + 10h
;
    db 0B8h, 20h, 0     ; mov ax,20h
    db 8Eh, 0C0h        ; mov es,ax
;    
    db 66h, 0B8h
    dd 12345678h        ; mov eax,12345678h
    db 66h, 26h, 87h, 6
    dw OFFSET ap_cr4    ; xchg eax,es:ap_cr4
    db 0Ch, 20h         ; or al,20h
    db 0Fh, 22h, 0E0h   ; mov cr4,eax
;
    db 66h, 0B9h
    dd IA32_EFER        ; mov ecx,IA32_EFER
    db 0Fh, 32h         ; rdmsr
    db 66h, 0Dh
    dd 101h             ; or eax,101h
    db 0Fh, 30h         ; wrmsr
;
    db 66h, 26h, 0A1h
    dw OFFSET ap_cr3    ; mov eax,es:ap_cr3
    db 0Fh, 22h, 0D8h   ; mov cr3,eax
;    
    db 0Fh, 22h, 0C0h   ; mov eax,cr0
    db 66h, 0Dh
    dd 80010008h        ; or eax,80010008h
    db 0Fh, 22h, 0C0h   ; mov cr0,eax
;
    db 66h, 26h, 8Bh, 16h
    dw OFFSET ap_stack_offset
                        ; mov edx,es:ap_stack_offset
;
    db 33h, 0C0h        ; xor ax,ax
    db 8Eh, 0C0h        ; mov es,ax
;
    db 0EAh
    dw OFFSET rt_init64 - rt_start + 1400h
    dw 28h

rt_init64:
    db 48h  ; mov rbx,0FFFFFF8000201000h
    db 0BBh
    dd 201000h
    dd 0FFFFFF80h
;  
    db 48h   ; mov rsp,rbx
    db 8Bh
    db 0E3h
;
    db 48h  ; mov rbx,0FFFFFF8000000000h
    db 0BBh
    dd 0
    dd 0FFFFFF80h
;
    db 89h  ; mov [rbx+10],edx
    db 53h
    db 0Ah
;
    db 48h   ; mov rax,[rbx+2]
    db 8Bh
    db 43h
    db 2
;
    db 48h   ; add rbx,rax
    db 3
    db 0D8h
;
    db 53h  ; push rbx
;
    db 0C3h ; ret

rt_end:
    
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

ap_stack_offset DD ?
ap_stack_sel    DW ?
ap_cr0          DD ?
ap_cr3          DD ?
ap_cr4          DD ?
ap_gdt          DB 6 DUP(?)
ap_idt          DB 6 DUP(?)

page_struc  ENDS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ApInit
;
;               DESCRIPTION:    Paged entry-point for AP initialization
;
;               PARAMETERS:     BX:EDX      Stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ApInit:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
;
    mov ss,bx
    mov esp,edx
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
    push bx
;    
    mov bx,apic_mem_sel
    mov ds,bx
    mov bx,APIC_ISR + 50h
    mov edx,ds:[bx]
;
    mov bx,APIC_IRR + 50h
    mov edx,ds:[bx]        
;    
    mov bx,SEG data
    mov ds,bx
;
    movzx bx,al
    shl bx,4
    add bx,OFFSET global_int_arr
;    
    mov al,ds:[bx].gi_ioapic_id
    mov fs,ds:[bx].gi_ioapic_sel
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
    pop bx
    pop fs
    pop ds
    retf32
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
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop ax
    verr ax
    jz IrqExitFs
;    
    xor ax,ax

IrqExitFs:
    mov fs,ax
;
    pop ax
    verr ax
    jz IrqExitEs
;    
    xor ax,ax

IrqExitEs:
    mov es,ax
;
    pop ax
    verr ax
    jz IrqExitDs
;    
    xor ax,ax

IrqExitDs:
    mov ds,ax
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
    retf32

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
    push bx
    push ecx
    push edx
    push edi
;
    push ax
    mov eax,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector16
;
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,OFFSET IsaIrqStart
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es:[edx].isa_irq_linear,edx
    mov word ptr es:[edx].isa_irq_chain,OFFSET IsaIrqExit - OFFSET IsaIrqStart
    mov dword ptr es:[edx].isa_irq_handler_ads,OFFSET IsaIrqDetect - OFFSET IsaIrqStart
    mov word ptr es:[edx].isa_irq_handler_ads+4,bx
    mov es:[edx].isa_irq_handler_data,0
    pop ax
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
    pop bx
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
    push ax
    push bx
;    
    mov bx,SEG data
    mov ds,bx    
    movzx bx,al
    shl bx,4
    add bx,OFFSET global_int_arr    
    mov [bx].gi_trigger_mode,0A0h
;
    pop bx
    pop ax
    pop ds
    retf32
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
    movzx bx,al
    shl bx,4
    mov dx,SEG data
    mov fs,dx
    mov esi,fs:[bx].global_int_arr.gi_long_ads
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
    or esi,esi
    jz rihLongOk
;
    AddLongIrq

rihLongOk:
    mov fs,bx
    mov edx,fs:isa_irq_linear
    mov ax,flat_sel
    mov fs,ax
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
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
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
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET IsaIrqChainStart
    mov ecx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop edx
    pop ecx
    add ecx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    CreateCodeSelector16
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
    add ax,OFFSET IsaIrqChainEntry - OFFSET IsaIrqChainStart
    sub ax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    cmp ax,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    jae rihChainPrev
;    
    add ax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    xchg ax,fs:[edx].isa_irq_chain
    mov fs:[ebp].isa_irch_chain,ax
    jmp rihChainDone

rihChainPrev:
    mov edx,ebp
    sub edx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    add ax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    xchg ax,fs:[edx].isa_irch_chain
    mov fs:[ebp].isa_irch_chain,ax
    jmp rihChainDone
        
rihReplace:    
    mov fs:[edx].isa_irq_handler_data,ds
    mov fs:[edx].isa_irq_handler_ads,edi
    mov word ptr fs:[edx].isa_irq_handler_ads+4,es
    mov fs:[edx].isa_irq_detect_nr,-1

rihChainDone:
    pop ax
;    
    movzx bx,al
    shl bx,4
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
    mov esi,fs:[bx].gi_long_ads
    or esi,esi
    jz rihLongPrioOk
;
    push bx
    xor bl,bl
    SetupLongIntGate
    pop bx

rihLongPrioOk:    
    mov ds,fs:[bx].gi_handler_sel
    mov esi,OFFSET IsaIrqEntry - OFFSET IsaIrqStart
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
msi_irq_nr          DB ?

msi_handler_struc   ENDS

MsiStart:

msi_handler     msi_handler_struc <>

MsiEntry:
    pushad
    push ds
    push es
    push fs
;
    mov al,cs:msi_irq_nr
    EnterInt
;       
    mov ax,word ptr fs:cs_curr_irq_nr
    or ax,ax
    jz MsiPrevOk
;    
    mov ax,fs:cs_nested_irq_count
    mov bx,ax
    inc ax
    cmp ax,MAX_IRQ_NESTING
    jne MsiAddStack
;
    int 3

MsiAddStack:
    mov fs:cs_nested_irq_count,ax
    shl bx,2
    mov eax,dword ptr fs:cs_curr_irq_nr
    mov fs:[bx].cs_nested_irq_stack,eax

MsiPrevOk: 
    movzx bx,cs:msi_irq_nr
    mov word ptr fs:cs_curr_irq_nr,bx
;    
    sti    
    mov ds,cs:msi_handler_data
    call fword ptr cs:msi_handler_ads
    cli
    mov word ptr fs:cs_curr_irq_nr,0
;    
    mov bx,fs:cs_nested_irq_count
    or bx,bx
    jz MsiExitNestingOk
;
    dec bx
    mov fs:cs_nested_irq_count,bx
    shl bx,2
    mov eax,fs:[bx].cs_nested_irq_stack
    mov dword ptr fs:cs_curr_irq_nr,eax
    
MsiExitNestingOk:
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax    
    LeaveInt
;
    pop ax
    verr ax
    jz MsiExitFs
;    
    xor ax,ax

MsiExitFs:
    mov fs,ax
;
    pop ax
    verr ax
    jz MsiExitEs
;    
    xor ax,ax

MsiExitEs:
    mov es,ax
;
    pop ax
    verr ax
    jz MsiExitDs
;    
    xor ax,ax

MsiExitDs:
    mov ds,ax
;
    popad
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
;       PARAMETERS:     AL          IRQ #
;
;       RETURNS:        DS:ESI       Address of entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMsi   Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    push eax
;
    mov eax,OFFSET MsiEnd - OFFSET MsiStart
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector16
;
    mov eax,cs
    mov ds,eax
    mov eax,flat_sel
    mov es,eax
    mov esi,OFFSET MsiStart
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
    pop eax
;
    mov es:[edx].msi_linear,edx
    mov dword ptr es:[edx].msi_handler_ads,OFFSET MsiDefault - OFFSET MsiStart
    mov word ptr es:[edx].msi_handler_ads+4,bx
    mov es:[edx].msi_handler_data,0
    mov es:[edx].msi_irq_nr,al
;
    mov ds,ebx
    mov esi,OFFSET MsiEntry - OFFSET MsiStart
;
    pop edi
    pop edx
    pop ecx
    pop ebx
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
    xor eax,eax
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
    push bx
    push dx
;    
    push ax
    movzx bx,al
    mov ax,SEG data
    mov ds,ax
    shl bx,4
    add bx,OFFSET global_int_arr
    mov al,ds:[bx].gi_ioapic_id
    mov dx,ds:[bx].gi_ioapic_sel
    or dx,dx
    jz niNoIoApic
;       
    mov es,dx
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
    pop ax
;
    movzx dx,al
    cmp dx,64
    jae niDone
;    
    mov bx,OFFSET detected_irqs
    bts ds:[bx],dx

niDone:
    pop dx
    pop bx
    pop eax
    pop es
    pop ds
    retf32
notify_irq  Endp    
   
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
    mov edx,fs:cs_apic
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
;       NAME:           SendLockedInt
;
;       DESCRIPTION:    Send int to processor. Scheduler lock must be taken
;
;       PARAMETERS:     FS      Processor selector
;                       AL      Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_locked_int_name    DB 'Send Locked Int',0

send_locked_int  Proc far
    push ds
    push eax
    push ecx
    push edx
;    
    mov edx,fs:cs_apic
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
    retf32
send_locked_int  Endp

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
    mov ds:detected_irqs+4,0       
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
    mov edx,ds:detected_irqs+4
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
    retf32
disable_all_irq Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMsiVector
;
;       DESCRIPTION:    Get MSI vector
;
;       PARAMETERS:     AL      IRQ
;                       FS      Core
;
;       RETURNS:        EDX     MSI address
;                       AX      MSI data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_msi_vector_name    DB 'Get MSI Vector',0

get_msi_vector  Proc far
    movzx ax,al
    mov edx,fs:cs_apic
    shl edx,12
    or edx,0FEE00000h
    retf32
get_msi_vector  Endp
   
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
    push ax
    mov ax,create_long_msi_nr
    IsValidOsGate
    pop ax
    jc rmhDone
;
    CreateLongMsi
;
    push bx
    xor bl,bl
    SetupLongIntGate
    pop bx
;    
    AddLongMsi

rmhDone:
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
    mov ax,time_data_sel
    mov ds,ax
    mov es,ds:t_hpet_sel
    mov bx,OFFSET hpet_counter_arr    
    mov eax,es:[bx].hpetc_config
    test ax,8000h
    jnz start_hpet_msi
;        
    push es
    mov al,2
    mov ah,12
    mov bx,cs
    mov es,bx
    mov edi,OFFSET hpet_ioapic_int
    RequestIrqHandler
    pop es
;
    mov eax,es:hpet_config
    or al,3
    mov es:hpet_config,eax
;    
    mov bx,OFFSET hpet_counter_arr    
    mov edx,es:[bx].hpetc_config
    and dx,NOT 08h
    or dx,506h 
    mov es:[bx].hpetc_config,edx
    jmp start_hpet_done

start_hpet_msi: 
    mov ax,SEG data
    mov ds,ax
    mov eax,40h
    mov edx,ds:bsp_id
    shl edx,12
    or edx,0FEE00000h
;
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
    mov dx,time_data_sel
    mov ds,dx
    movzx eax,ax
    mov edx,31F5C4EDh
    mul edx
    div ds:t_hpet_factor
    inc eax
;    
    mov ds,ds:t_hpet_sel
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
    mov ax,time_data_sel
    mov ds,ax

gstSpinLock:    
    mov ax,ds:t_spinlock
    or ax,ax
    je gstGet
;
    sti
    pause
    jmp gstSpinLock

gstGet:
    cli
    inc ax
    xchg ax,ds:t_spinlock
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
    xchg ax,ds:t_clock_tics
    sub ax,dx
    movzx eax,ax
    add ds:t_system_time,eax
    adc ds:t_system_time+4,0
;    
    mov eax,ds:t_system_time
    mov edx,ds:t_system_time+4
;
    mov ds:ut_system_time+1000h,eax
    mov ds:ut_system_time+1004h,edx
;    
    mov ds:t_spinlock,0
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
    push ecx
    push ds
    push es
;
    mov ax,time_data_sel
    mov ds,ax
    mov es,ds:t_hpet_sel

ghtSpinLock:    
    mov ax,ds:t_spinlock
    or ax,ax
    je ghtGet
;
    sti
    pause
    jmp ghtSpinLock

ghtGet:
    cli
    inc ax
    xchg ax,ds:t_spinlock
    or ax,ax
    jne ghtSpinLock
;
    mov eax,es:hpet_count
    mov edx,eax
    xchg edx,ds:t_prev_hpet
    sub eax,edx
    mul ds:t_hpet_factor
    add eax,ds:t_hpet_guard
    adc edx,0
;
    mov ecx,31F5C4EDh
    div ecx
    mov ds:t_hpet_guard,edx
    add ds:t_system_time,eax
    adc ds:t_system_time+4,0
;    
    mov eax,ds:t_system_time
    mov edx,ds:t_system_time+4
;
    mov ds:ut_system_time+1000h,eax
    mov ds:ut_system_time+1004h,edx
;    
    mov ds:t_spinlock,0
    sti
;
    pop cx
    verr cx
    jz hpet_time_es_ok
;
    xor cx,cx
    
hpet_time_es_ok:
    mov es,cx
;
    pop cx
    verr cx
    jz hpet_time_ds_ok
;
    xor cx,cx
    
hpet_time_ds_ok:
    mov ds,cx
    pop ecx
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
    mov bx,time_data_sel
    mov ds,bx
    mov ds:t_system_time,eax
    mov ds:t_system_time+4,edx
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
;           NAME:           LongTimerHandler
;
;           DESCRIPTION:    Long timer int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

long_timer_handler_name    DB 'Long Timer Handler', 0

long_timer_handler      Proc far
    mov al,-1
    EnterInt    
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
    retf32
long_timer_handler      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LongHpetHandler
;
;           DESCRIPTION:    Long HPET int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

long_hpet_handler_name    DB 'Long Hpet Handler', 0

long_hpet_handler      Proc far
    mov ax,time_data_sel
    mov ds,ax
    mov ds,ds:t_hpet_sel
    mov edx,ds:hpet_int_status
    mov ds:hpet_int_status,edx
;    
    mov al,-1
    EnterInt    
    lock or fs:cs_flags,cS_FLAG_TIMER_EXPIRED
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
    retf32
long_hpet_handler       Endp

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
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop ax
    verr ax
    jz timer_fs_ok
;
    xor ax,ax

timer_fs_ok:
    mov fs,ax
;    
    pop ax
    verr ax
    jz timer_es_ok
;
    xor ax,ax

timer_es_ok:
    mov es,ax
;    
    pop ax
    verr ax
    jz timer_ds_ok
;
    xor ax,ax

timer_ds_ok:
    mov ds,ax
;    
    popad
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
    pushad
    push ds
    push es
    push fs
;
    mov ax,time_data_sel
    mov ds,ax
    mov ds,ds:t_hpet_sel
    mov edx,ds:hpet_int_status
    mov ds:hpet_int_status,edx
;    
    mov al,-1
    EnterInt    
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;    
    pop ax
    verr ax
    jz hpet_fs_ok
;
    xor ax,ax

hpet_fs_ok:
    mov fs,ax
;    
    pop ax
    verr ax
    jz hpet_es_ok
;
    xor ax,ax

hpet_es_ok:
    mov es,ax
;    
    pop ax
    verr ax
    jz hpet_ds_ok
;
    xor ax,ax

hpet_ds_ok:
    mov ds,ax
;    
    popad
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           HpetIoapicInt
;
;               DESCRIPTION:    HPET IOAPIC interrupt
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hpet_ioapic_int Proc far
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    mov dx,time_data_sel
    mov ds,dx
    mov ds,ds:t_hpet_sel
    mov edx,ds:hpet_int_status
    mov ds:hpet_int_status,edx  
    retf32
hpet_ioapic_int Endp

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
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop ax
    verr ax
    jz preempt_fs_ok
;
    xor ax,ax

preempt_fs_ok:
    mov fs,ax
;    
    pop ax
    verr ax
    jz preempt_es_ok
;
    xor ax,ax

preempt_es_ok:
    mov es,ax
;    
    pop ax
    verr ax
    jz preempt_ds_ok
;
    xor ax,ax

preempt_ds_ok:
    mov ds,ax
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
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    LeaveInt
;
    pop ax
    verr ax
    jz TlbExitGs
;    
    xor ax,ax

TlbExitGs:
    mov gs,ax
;
    pop ax
    verr ax
    jz TlbExitFs
;    
    xor ax,ax

TlbExitFs:
    mov fs,ax
;
    pop ax
    verr ax
    jz TlbExitEs
;    
    xor ax,ax

TlbExitEs:
    mov es,ax
;
    pop ax
    verr ax
    jz TlbExitDs
;    
    xor ax,ax

TlbExitDs:
    mov ds,ax
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
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax
    IpiWakeup
    LeaveInt
;
    pop ax
    verr ax
    jz WiExitGs
;    
    xor ax,ax

WiExitGs:
    mov gs,ax
;
    pop ax
    verr ax
    jz WiExitFs
;    
    xor ax,ax

WiExitFs:
    mov fs,ax
;
    pop ax
    verr ax
    jz WiExitEs
;    
    xor ax,ax

WiExitEs:
    mov es,ax
;
    pop ax
    verr ax
    jz WiExitDs
;    
    xor ax,ax

WiExitDs:
    mov ds,ax
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
    mov al,40h
    mov esi,OFFSET timer_int
    SetupIntGate
;    
    mov ax,setup_long_timer_int_nr
    IsValidOsGate
    jc siTimerOk
;    
    mov al,40h
    SetupLongTimerInt

siTimerOk:
    mov al,80h
    mov esi,OFFSET preempt_int
    SetupIntGate
;    
    mov ax,setup_long_preempt_int_nr
    IsValidOsGate
    jc siPreemptOk
;    
    mov al,80h
    SetupLongPreemptInt

siPreemptOk:
    mov al,25h
    mov esi,OFFSET tlb_int
    SetupIntGate
;        
    mov ax,setup_long_schedule_int_nr
    IsValidOsGate
    jc siSchedOk
;    
    mov al,82h
    SetupLongScheduleInt

siSchedOk:
    mov al,82h
    mov esi,OFFSET hpet_int
    SetupIntGate
;        
    mov ax,setup_long_hpet_int_nr
    IsValidOsGate
    jc siHpetOk
;    
    mov al,82h
    SetupLongHpetInt

siHpetOk:
    mov al,83h
    mov esi,OFFSET timer_int
    SetupIntGate
;    
    mov ax,setup_long_timer_int_nr
    IsValidOsGate
    jc siPreemptTimerOk
;    
    mov al,83h
    SetupLongTimerInt

siPreemptTimerOk:
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
    test fs:cs_flags,CS_FLAG_SHUTDOWN
    jz start_core_normal
;
    lock and fs:cs_flags,NOT CS_FLAG_SHUTDOWN

start_core_normal:    
    lock or fs:cs_flags,CS_FLAG_ACTIVE
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
    cli
    call SetupLocalApic
;
    GetCore
    lock and fs:cs_flags,NOT CS_FLAG_ACTIVE
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
    test fs:cs_flags,cS_FLAG_ACTIVE
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
    RunApCore
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           BootRealtimeCore
;
;               DESCRIPTION:    Boot realtime core
;
;               PARAMETERS:     FS      Processor sel
;                               EBX     CR3
;                               ES:EDI  Realtime startup proc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

boot_realtime_core_name DB 'Boot Realtime Core', 0

boot_realtime_core    Proc far
    push ds
    push es
    push fs
    pushad
;
    mov esi,ebx
;
    xor edx,edx
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,63h
    SetPageEntry
;    
    mov edx,1000h
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,1063h
    SetPageEntry
;
    mov ax,SEG data
    mov ds,ax
;
    mov ax,flat_sel
    mov es,ax
;    
    mov edi,1800h
    mov eax,cr0
    mov es:[edi].ap_cr0,eax
    mov es:[edi].ap_cr3,esi
;
    mov eax,cr4
    mov es:[edi].ap_cr4,eax
;
    GetApicId
    mov es:[edi].ap_stack_offset,edx
;
    mov edi,0F80h
    mov esi,OFFSET table_start
    mov ecx,OFFSET table_end - OFFSET table_start
    rep movs byte ptr es:[edi],cs:[esi]
;
    mov edi,1000h
    mov esi,OFFSET real_start
    mov ecx,OFFSET real_end - OFFSET real_start
    rep movs byte ptr es:[edi],cs:[esi]
;
    mov edi,1400h
    mov esi,OFFSET rt_start
    mov ecx,OFFSET rt_end - OFFSET rt_start
    rep movs byte ptr es:[edi],cs:[esi]
;
    mov edi,1800h
;
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    mov al,0Ah
    out 71h,al
    jmp short $+2
;
    mov edx,fs:cs_apic
    call SendInit
;
    mov eax,es:[edi].ap_cr4
    cmp eax,12345678h
    je brcDone
;    
    mov al,1
    call SendStartup
    
    mov cx,250

brcLoop1:
    mov eax,es:[edi].ap_cr4
    cmp eax,12345678h
    je brcDone
;    
    mov ax,1
    call DelayMs
    loop brcLoop1
;
    mov al,1    
    call SendStartup
;    
    mov cx,250

brcLoop2:
    mov eax,es:[edi].ap_cr4
    cmp eax,12345678h
    je brcDone
;    
    mov ax,1
    call DelayMs
    loop brcLoop2

brcDone:
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    xor al,al
    out 71h,al
    jmp short $+2
;
    pop ebx
    pop eax
    mov edx,1000h
    SetPageEntry
;
    pop ebx
    pop eax
    xor edx,edx
    SetPageEntry
;
    popad
    pop fs
    pop es
    pop ds
    retf32
boot_realtime_core   Endp
       
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
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,63h
    SetPageEntry
;    
    mov edx,1000h
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,1063h
    SetPageEntry
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
    mov eax,cr4
    mov es:[di].ap_cr4,eax
;
    db 66h
    sidt fword ptr es:[di].ap_idt
;    
    mov ax,fs:cs_gdt_size
    dec ax
    mov word ptr es:[di].ap_gdt,ax
    mov eax,fs:cs_gdt_base
    mov dword ptr es:[di].ap_gdt+2,eax
;
    mov eax,fs:cs_stack_offset
    mov es:[di].ap_stack_offset,eax
    mov ax,fs:cs_stack_sel
    mov es:[di].ap_stack_sel,ax
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
    mov edx,fs:cs_apic
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
    pop ebx
    pop eax
    mov edx,1000h
    SetPageEntry
;
    pop ebx
    pop eax
    xor edx,edx
    SetPageEntry
;
    popad
    pop es
    pop ds
    ret
BootCore   Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleVbe
;
;       DESCRIPTION:    Handle VBE session
;
;       PARAMETERS:     BX      Requests width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vesa_id DB 'VESA'

HandleVbe    Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,SEG data
    mov fs,ax
    mov fs:vbe_width,0
    mov fs:vbe_height,0
    mov fs:vbe_lfb,0
    mov fs:vbe_mode,0
    mov fs:vbe_scan_size,0
;
    mov si,1900h
    mov ax,ds:[si].vbe_res
    cmp ax,4Fh
    jne hvDone
;
    add si,OFFSET vbe_buf
    mov eax,dword ptr ds:[si].vesa_name
    cmp eax,dword ptr cs:vesa_id
    jne hvDone
;
    movzx eax,word ptr ds:[si].vesa_modes+2
    shl eax,4
    movzx esi,word ptr ds:[si].vesa_modes
    add esi,eax
;
    push esi
    xor ecx,ecx

hvCountLoop:
    mov ax,ds:[esi]
    cmp ax,-1
    je hvCountOk
;
    or ax,ax
    je hvCountOk
;
    add esi,2
    inc ecx
    jmp hvCountLoop

hvCountOk:
    pop esi
;
    push ecx
    mov eax,ecx
    shl eax,1
    AllocateSmallGlobalMem
;
    xor edi,edi
    rep movs word ptr es:[edi],ds:[esi]
;
    pop ecx
;
    xor di,di

hvGetLoop:
    mov si,1900h
    mov ds:[si].vbe_op,4F01h
    mov bx,es:[di]
    mov ds:[si].vbe_cx,bx
    mov ds:[si].vbe_sign,vbe_req_sign
;
    push cx    
    mov cx,250

hvWaitLoop:
    mov ax,ds:[si].vbe_sign
    cmp ax,vbe_ack_sign
    je hvGetOk
;    
    mov ax,1
    call DelayMs
    loop hvWaitLoop

hvGetOk:
    pop cx
;
    mov si,1900h
    add si,OFFSET vbe_buf
    mov dx,ds:[si].vmi_mode_attrib
    and dx,MODE_ATTRIB_REQUIRED
    cmp dx,MODE_ATTRIB_REQUIRED
    jne hvGetNext
;
    mov dl,ds:[si].vmi_memory_model
    cmp dl,MODEL_DIRECT
    jne hvGetNext
;
    pushad
    movzx ax,ds:[si].vmi_bits_per_pixel
    mov cx,ds:[si].vmi_x_pixels
    mov dx,ds:[si].vmi_y_pixels
;
    cmp ax,32
    jne hvSkip
;
    mov bp,fs:vbe_desired
    cmp bp,1
    je hvHighest

hvPart:
    cmp bp,cx
    je hvSet
;
    mov eax,ds:[si].vmi_lfb
    or eax,eax
    jz hvSkip
;    
    cmp bp,fs:vbe_width
    je hvSet
    jmp hvCmp

hvHighest:
    mov eax,ds:[si].vmi_lfb
    or eax,eax
    jz hvSkip

hvCmp:
    cmp cx,fs:vbe_width
    jc hvSkip

hvSet:
    mov eax,ds:[si].vmi_lfb
    mov fs:vbe_lfb,eax
    mov fs:vbe_width,cx
    mov fs:vbe_height,dx
    mov ax,ds:[si].vmi_scan_lines
    mov fs:vbe_scan_size,ax
    mov fs:vbe_mode,bx

hvSkip:
    popad

hvGetNext:
    add di,2
    sub cx,1
    jnz hvGetLoop
;
    mov bx,fs:vbe_mode
    mov si,1900h
    mov ds:[si].vbe_op,4F02h
    mov ds:[si].vbe_bx,bx
    mov ds:[si].vbe_sign,vbe_req_sign
;
    push cx    
    mov cx,250

hvSetLoop:
    mov ax,ds:[si].vbe_sign
    cmp ax,vbe_ack_sign
    je hvSetOk
;    
    mov ax,1
    call DelayMs
    loop hvSetLoop

hvSetOk:
    pop cx
;
    mov ds:[si].vbe_op,-1
    mov ds:[si].vbe_sign,vbe_req_sign
;
    mov ax,1
    call DelayMs
;
    mov ax,system_data_sel
    mov es,ax 
;
    mov ax,fs:vbe_width
    mov es:efi_width,ax
;
    mov ax,fs:vbe_height
    mov es:efi_height,ax
;
    movzx eax,fs:vbe_scan_size
    mov es:efi_scan_size,eax
;
    movzx edx,fs:vbe_scan_size
    movzx eax,fs:vbe_height
    mul edx
    shl eax,2
    AllocateBigLinear
;
    mov eax,fs:vbe_lfb
    xor ebx,ebx
    mov al,6Bh
    mov es:efi_lfb,edx
    mov es:mon_fixed_lfb,edx
;
    mov es:fixed_lfb_phys,eax
    mov es:fixed_lfb_phys+4,ebx
    mov es:fixed_lfb_linear,edx

hvSetupLoop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    loop hvSetupLoop
;
    mov es:efi_fore_col,0FFFFFFh
    mov es:efi_back_col,0

hvDone:
    popad
    pop fs
    pop es
    pop ds
    ret
HandleVbe   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BootVbeCore
;
;       DESCRIPTION:    Boot a new AP core to collect VBE info
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BootVbeCore    Proc near
    push ds
    push es
    pushad
;
    xor edx,edx
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,63h
    SetPageEntry
;    
    mov edx,1000h
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,1063h
    SetPageEntry
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
    mov si,OFFSET vbe_info_start
    mov cx,OFFSET vbe_info_end - OFFSET vbe_info_start
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
    mov eax,cr4
    mov es:[di].ap_cr4,eax
;
    db 66h
    sidt fword ptr es:[di].ap_idt
;    
    mov ax,fs:cs_gdt_size
    dec ax
    mov word ptr es:[di].ap_gdt,ax
    mov eax,fs:cs_gdt_base
    mov dword ptr es:[di].ap_gdt+2,eax
;
    mov eax,fs:cs_stack_offset
    mov es:[di].ap_stack_offset,eax
    mov ax,fs:cs_stack_sel
    mov es:[di].ap_stack_sel,ax
;
    mov di,1900h
    mov es:[di].vbe_sign,vbe_req_sign
    mov es:[di].vbe_op,4F00h
    mov es:[di].vbe_cx,0
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
    mov edx,fs:cs_apic
    call SendInit
;
    mov ax,es:[di].vbe_sign
    cmp ax,vbe_ack_sign
    je bvcDone
;    
    mov al,1
    call SendStartup
    
    mov cx,250

bvcLoop1:
    mov ax,es:[di].vbe_sign
    cmp ax,vbe_ack_sign
    je bvcDone
;    
    mov ax,1
    call DelayMs
    loop bvcLoop1
;
    mov al,1    
    call SendStartup
;    
    mov cx,250

bvcLoop2:
    mov ax,es:[di].vbe_sign
    cmp ax,vbe_ack_sign
    je bvcDone
;    
    mov ax,1
    call DelayMs
    loop bvcLoop2

bvcDone:
    call HandleVbe
;
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    xor al,al
    out 71h,al
    jmp short $+2
;
    pop ebx
    pop eax
    mov edx,1000h
    SetPageEntry
;
    pop ebx
    pop eax
    xor edx,edx
    SetPageEntry
;
    popad
    pop es
    pop ds
    ret
BootVbeCore   Endp
   
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
    mov es:cs_gdt_base,edx
    mov es:cs_gdt_size,cx
    mov cx,es
    mov fs,cx
;
    pop edx
    pop cx
    pop eax
    pop es
    ret
DoCreateCore   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Name:           GetValue
;
;   Purpose:        Get value from environment
;
;   Parameters:     ES:DI   Name
;
;   Returns:        NC          Found
;                   AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
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
;               NAME:           StartupApCores
;
;               DESCRIPTION:    Startup application cores
;
;               PARAMETERS:     ES      Apic table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

max_cores_name  DB 'CORES', 0
vbe_name        DB 'VBE', 0

StartupApCores    Proc near
    push es
    mov ax,cs
    mov es,ax
    mov edi,OFFSET vbe_name
    call GetValue
    mov bx,ax
    mov ax,SEG data
    mov es,ax
    mov es:vbe_desired,bx
    pop es
;
    push es
    mov ax,cs
    mov es,ax
    mov edi,OFFSET max_cores_name
    call GetValue
    pop es
    mov si,ax
;
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
    mov fs:cs_apic,edx
;
    mov al,es:[di].ap_acpi_id
    mov fs:cs_acpi,al
    inc bp
    jmp init_core_next

init_ap_proc:
    cmp si,bp
    je init_core_done
;    
    mov eax,es:[di].ap_flags
    test al,1
    jz init_core_next
;    
    call DoCreateCore    
    movzx edx,es:[di].ap_apic_id
    mov fs:cs_apic,edx
    mov al,es:[di].ap_acpi_id
    mov fs:cs_acpi,al
    or bx,bx
    jz init_ap_boot
;
    call BootVbeCore
    xor bx,bx
    jmp init_ap_done

init_ap_boot:
    call BootCore

init_ap_done:
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
    mov eax,2000h
    AllocateBigLinear
;
    mov bx,time_data_sel
    mov ecx,2000h
    CreateDataSelector16
;
    mov es,bx
    xor di,di
    mov cx,800h
    xor eax,eax
    rep stos dword ptr es:[di]
;
    add edx,1000h
    GetPageEntry
    xor al,al
    mov es:t_phys,eax
    mov es:t_phys+4,ebx
;
    mov ax,SEG data
    mov ds,ax
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
    mov eax,dword ptr cs:apic_tab
    GetAcpiTable
    jc init_apic_gates_ok
;
    push es
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_ioapic_state
    mov edi,OFFSET get_ioapic_state_name
    xor cl,cl
    mov ax,get_ioapic_state_nr
    RegisterOsGate
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
    mov esi,OFFSET boot_realtime_core
    mov edi,OFFSET boot_realtime_core_name
    xor cl,cl
    mov ax,boot_realtime_core_nr
    RegisterOsGate
;
    mov esi,OFFSET send_locked_int
    mov edi,OFFSET send_locked_int_name
    xor cl,cl
    mov ax,send_locked_int_nr
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
    mov esi,OFFSET notify_irq
    mov edi,OFFSET notify_irq_name
    xor cl,cl
    mov ax,notify_irq_nr
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
    mov esi,OFFSET get_msi_vector
    mov edi,OFFSET get_msi_vector_name
    xor cl,cl
    mov ax,get_msi_vector_nr
    RegisterOsGate
;
    mov esi,OFFSET request_msi_handler
    mov edi,OFFSET request_msi_handler_name
    xor cl,cl
    mov ax,request_msi_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET set_system_time
    mov edi,OFFSET set_system_time_name
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
    mov esi,OFFSET long_timer_handler
    mov edi,OFFSET long_timer_handler_name
    xor cl,cl
    mov ax,long_timer_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET get_pit_time
    mov edi,OFFSET get_pit_time_name
    xor dx,dx
    mov ax,get_system_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_local_timer
    mov edi,OFFSET has_local_timer_name
    xor dx,dx
    mov ax,has_global_timer_nr
    RegisterBimodalUserGate
;
    mov eax,dword ptr cs:hpet_tab
    GetAcpiTable
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
    push es
    mov ax,cs
    mov ds,ax
    mov es,ax    
    mov esi,OFFSET get_hpet_time
    mov edi,OFFSET get_hpet_time_name
    xor dx,dx
    mov ax,get_system_time_nr
    RegisterBimodalUserGate
    pop es
;    
    mov bx,OFFSET hpet_counter_arr    
    mov eax,es:[bx].hpetc_config
    test ax,8000h
    jz init_hpet_done

; never use global timer!

    jmp init_hpet_done

init_hpet_timer_ok:
    UseOwnPreemptTimer
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
    mov esi,OFFSET long_hpet_handler
    mov edi,OFFSET long_hpet_handler_name
    xor cl,cl
    mov ax,long_hpet_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET has_global_timer
    mov edi,OFFSET has_global_timer_name
    xor dx,dx
    mov ax,has_global_timer_nr
    RegisterBimodalUserGate

init_hpet_done:    
    pop es
;
    call DisablePic    
    call SetupInts
    call InitIoApic
    call CreateIrqHandlers
    call ProcessApicTable
    call SetupLocalApic
    call EnableDetect
;    
    call InitApicTimer
    call StartupApCores

init_apic_gates_ok:     
    ret
init    ENDP

code    ENDS

    END init

