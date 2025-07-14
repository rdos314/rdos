;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; LONGMODE.ASM
; Long mode device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


include ..\driver.def
include ..\os.def
include ..\user.def
include ..\os.inc
include ..\user.inc
include system.def
include core.inc
include protseg.def
include gate.def
include elf.def
include ..\debug\kdebug.inc

PAGE_TABLE_LINEAR   equ 0FFFFFF8000000000h
DIR_TABLE_LINEAR    equ 0FFFFFFFFC0000000h
PTR_TABLE_LINEAR    equ 0FFFFFFFFFFE00000h
PLM4_TABLE_LINEAR   equ 0FFFFFFFFFFFFF000h

fault_ss            equ 48
fault_rsp           equ 40
fault_rflags        equ 32
fault_cs            equ 24
fault_rip           equ 16
fault_error_code    equ 8
fault_rbp           equ 0
fault_rax           equ -8
fault_rbx           equ -16

IA32_EFER       = 0C0000080h
IA32_STAR       = 0C0000081h
IA32_LSTAR      = 0C0000082h
IA32_CSTAR      = 0C0000083h
IA32_FMASK      = 0C0000084h
MSR_GS_BASE     = 0C0000101h

pushq0  Macro
    db 6Ah
    db 0
        Endm


; this should be at linear address long_process_linear

elf_proc_struc  STRUC

ep_header       elf_header <>

ep_prog_name    DD ?
ep_prog_cmd     DD ?
ep_file_handle  DW ?

elf_proc_struc  ENDS

isa_irq_handler_struc   STRUC

isa_irq_handler_ads     DD ?,?
isa_irq_chain           DQ ?
isa_irq_handler_data    DW ?
isa_irq_size            DW ?
isa_irq_detect_nr       DB ?

isa_irq_handler_struc   ENDS

isa_irq_chain_struc  STRUC

isa_irch_handler_ads     DD ?,?
isa_irch_handler_data    DW ?
isa_irch_chain           DQ ?

isa_irq_chain_struc ENDS

msi_handler_struc   STRUC

msi_handler_ads     DD ?,?
msi_handler_data    DW ?

msi_handler_struc   ENDS

Reg64   struc

reg_fault   dw ?
reg_rax     dq ?
reg_rcx     dq ?
reg_rdx     dq ?
reg_rbx     dq ?
reg_rsp     dq ?
reg_rbp     dq ?
reg_rsi     dq ?
reg_rdi     dq ?
reg_r8      dq ?
reg_r9      dq ?
reg_r10     dq ?
reg_r11     dq ?
reg_r12     dq ?
reg_r13     dq ?
reg_r14     dq ?
reg_r15     dq ?
reg_rip     dq ?
reg_cs      dw ?
reg_ds      dw ?
reg_es      dw ?
reg_fs      dw ?
reg_gs      dw ?
reg_ss      dw ?
reg_flags   dq ?

reg_end     db ?

Reg64   Ends

long_thread_info_struc  STRUC

lti_stack_size      DQ ?
lti_param           DQ ?
lti_start           DQ ?

long_thread_info_struc  ENDS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;   32-bit device driver header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.686p

Code32 segment byte public use32 'code32'

sgn  dw 6452h
eip  dd OFFSET init
ib   dd long_map_linear
ic   dd long_map_size
idt  dd long_idt_linear

    org long_map_linear

prot_idt_size   DW ?
prot_idt_base   DD ? 

long_idt_size   DW 0FFFh
long_idt_base   DD long_idt_linear

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HasLongMode
;
;   DESCRIPTION:    Check for long-mode support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_long_mode_name   DB 'Has Long Mode', 0
    
has_long_mode  proc far
    clc
    ret
has_long_mode Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongTrapGate
;
;   DESCRIPTION:    Setup long-mode trap gate
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      Dpl
;                   BH      IST
;                   ESI     Entry point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_trap_gate_name   DB 'Setup Long Trap Gate', 0
    
setup_long_trap_gate  proc far
    push ds
    push eax
    push edx
    push edi
;
    mov dx,flat_sel
    mov ds,dx
;
    movzx edi,al
    shl edi,4
    add edi,long_idt_linear
;
    mov edx,esi
    mov [edi],dx
;
    shr edx,16
    mov [edi+6],dx
;
    mov dx,long_kernel_code_sel
    mov [edi+2],dx
;
    xor edx,edx    
    mov [edi+8],edx
    mov [edi+12],edx
;
    mov al,bh
    mov ah,bl
    shl ah,5
    or ah,8Fh
    mov [edi+4],ax
;
    pop edi
    pop edx
    pop eax
    pop ds
    ret
setup_long_trap_gate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongIntGate
;
;   DESCRIPTION:    Setup long-mode int gate
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      Dpl
;                   ESI     Entry point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_int_gate_name   DB 'Setup Long Int Gate', 0
    
setup_long_int_gate  proc far
    push ds
    push eax
    push edx
    push edi
;
    mov dx,flat_sel
    mov ds,dx
;
    movzx edi,al
    shl edi,4
    add edi,long_idt_linear
;
    mov edx,esi
    mov [edi],dx
;
    shr edx,16
    mov [edi+6],dx
;
    mov dx,long_kernel_code_sel
    mov [edi+2],dx
;
    xor edx,edx    
    mov [edi+8],edx
    mov [edi+12],edx
;
    xor al,al
    mov ah,bl
    shl ah,5
    or ah,8Eh
    mov [edi+4],ax
;
    pop edi
    pop edx
    pop eax
    pop ds
    ret
setup_long_int_gate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongSpuriousInt
;
;   DESCRIPTION:    Setup long-mode spurious int
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      DPL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_spurious_int_name   DB 'Setup Long Spurious Int', 0
    
setup_long_spurious_int  proc far
    push esi
    mov esi,OFFSET spurious_int
    SetupLongIntGate
    pop esi
    ret
setup_long_spurious_int Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongScheduleInt
;
;   DESCRIPTION:    Setup long-mode scheduler int
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      DPL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_schedule_int_name   DB 'Setup Long Schedule Int', 0
    
setup_long_schedule_int  proc far
    push esi
    mov esi,OFFSET schedule_int
    SetupLongIntGate
    pop esi
    ret
setup_long_schedule_int Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongTimerInt
;
;   DESCRIPTION:    Setup long-mode timer int
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      DPL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_timer_int_name   DB 'Setup Long Timer Int', 0
    
setup_long_timer_int  proc far
    push esi
    mov esi,OFFSET timer_int
    SetupLongIntGate
    pop esi
    ret
setup_long_timer_int Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongPreemptInt
;
;   DESCRIPTION:    Setup long-mode preemption int
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      DPL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_preempt_int_name   DB 'Setup Long Preempt Int', 0
    
setup_long_preempt_int  proc far
    push esi
    mov esi,OFFSET preempt_int
    SetupLongIntGate
    pop esi
    ret
setup_long_preempt_int Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongHpetInt
;
;   DESCRIPTION:    Setup long-mode HPET int
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      DPL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_hpet_int_name   DB 'Setup Long HPET Int', 0
    
setup_long_hpet_int  proc far
    push esi
    mov esi,OFFSET hpet_int
    SetupLongIntGate
    pop esi
    ret
setup_long_hpet_int Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongCrashGate
;
;   DESCRIPTION:    Setup long-mode crash gate
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      DPL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_crash_gate_name   DB 'Setup Long Crash Gate', 0
    
setup_long_crash_gate  proc far
    push esi
    mov esi,OFFSET crash_gate_int
    SetupLongIntGate
    pop esi
    ret
setup_long_crash_gate Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongNmiCoreDump
;
;   DESCRIPTION:    Setup long-mode core dump NMI handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_nmi_core_dump_name   DB 'Setup Long Core Dump Nmi', 0
    
setup_long_nmi_core_dump  proc far
    push eax
    push ebx
    push esi
;    
    mov al,2
    xor bl,bl
    mov esi,OFFSET crash_nmi_int
    SetupLongIntGate
;
    pop esi
    pop ebx
    pop eax
    ret
setup_long_nmi_core_dump Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitIdt
;
;   DESCRIPTION:    Init 64-bit IDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pretask_int_tab:
;
;               int #       Entry                   DPL     IST
;
pg0     DD      0,          OFFSET pretask0,        0,      0
pg1     DD      1,          OFFSET trap_1,          0,      0
pg2     DD      2,          OFFSET pretask2,        0,      0
pg3     DD      3,          OFFSET trap_3,          0,      0
pg4     DD      4,          OFFSET pretask4,        0,      0
pg5     DD      5,          OFFSET pretask5,        0,      0
pg6     DD      6,          OFFSET invalid_opcode,  0,      0
pg7     DD      7,          OFFSET pretask7,        0,      0
pg8     DD      8,          OFFSET double_fault,    0,      1
pg9     DD      9,          OFFSET pretask9,        0,      0
pg10    DD      10,         OFFSET pretask10,       0,      0
pg11    DD      11,         OFFSET pretask11,       0,      0
pg12    DD      12,         OFFSET pretask12,       0,      0
pg13    DD      13,         OFFSET protection_fault,0,      0
pg14    DD      14,         OFFSET page_fault,      0,      0
pg16    DD      16,         OFFSET pretask16,       0,      0
rg66    DD      66h,        OFFSET int66,           3,      0
rg67    DD      67h,        OFFSET int67,           3,      0
pg7_end DD      0FFFFFFFFh

InitIdt proc near
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
;
    mov edi,pretask_int_tab

iiLoop:
    mov eax,[edi]
    cmp eax,0FFFFFFFFh
    jz iiDone
;    
    mov esi,[edi+4]
    mov bl,[edi+8]
    mov bh,[edi+12]
    SetupLongTrapGate
;
    add edi,16
    jmp iiLoop

iiDone:
    mov ax,flat_sel
    mov ds,ax
    sidt fword ptr ds:prot_idt_size
;
    popad
    pop es
    pop ds
    ret
InitIdt Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateLongIrq
;
;       DESCRIPTION:    Create new ISA IRQ context
;
;       PARAMETERS:     AL           IRQ # (for detect)
;
;       RETURNS:        ESI          Linear address of entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_long_irq_name    DB 'Create Long IRQ', 0

create_long_irq   Proc far
    push ds
    push es
    push eax
    push bx
    push ecx
    push edx
    push edi
;
    push ax
    mov eax,1000h
    AllocateBigLinear
;
    mov ecx,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,OFFSET IsaIrqStart
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov edi,edx
    add edi,OFFSET IsaIrqPatchLinear + 1 - OFFSET IsaIrqStart
    mov es:[edi],edx
;    
    mov eax,OFFSET IsaIrqExit - OFFSET IsaIrqStart
    add eax,edx
    mov dword ptr es:[edx].isa_irq_chain,eax
    mov dword ptr es:[edx].isa_irq_chain+4,0
;
    mov eax,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    mov es:[edx].isa_irq_size,ax
;
    mov eax,OFFSET IsaIrqDetect - OFFSET IsaIrqStart    
    add eax,edx
    mov dword ptr es:[edx].isa_irq_handler_ads,eax
    mov word ptr es:[edx].isa_irq_handler_ads+4,long_kernel_code_sel
    mov word ptr es:[edx].isa_irq_handler_data,0
    pop ax
    mov es:[edx].isa_irq_detect_nr,al    
;
    mov esi,OFFSET IsaIrqEntry - OFFSET IsaIrqStart
    add esi,edx
;
    pop edi
    pop edx
    pop ecx
    pop bx
    pop eax
    pop es
    pop ds
    ret
create_long_irq   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddLongIrq
;
;       DESCRIPTION:    Add IRQ handler
;
;       PARAMETERS:     ESI         Linear address of entry-point
;                       DS          Handler data
;                       ES:EDI      Handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_long_irq_name   DB 'Add Long IRQ', 0

add_long_irq   Proc far
    push ds
    push es
    pushad
;
    push ds
    push es
    push edi
;    
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;    
    mov edx,esi
    sub edx,OFFSET IsaIrqEntry - OFFSET IsaIrqStart
;
    mov al,es:[edx].isa_irq_detect_nr
    cmp al,-1
    jne sirhReplace
;
    movzx ecx,es:[edx].isa_irq_size
    mov eax,ecx
    add ecx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    cmp ecx,1000h
    ja sirhFail
;
    mov es:[edx].isa_irq_size,cx
    mov edi,edx
    add edi,eax
    mov ebp,edi
;    
    mov esi,OFFSET IsaIrqChainStart
    mov ecx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    rep movs byte ptr es:[edi],ds:[esi]
;    
    pop esi
    pop ds
    pop ebx
;    
    mov es:[ebp].isa_irch_handler_data,bx
    mov es:[ebp].isa_irch_handler_ads,esi
    mov word ptr es:[ebp].isa_irch_handler_ads+4,ds
;
    mov eax,ebp
    sub eax,edx
    add eax,OFFSET IsaIrqChainEntry - OFFSET IsaIrqChainStart
    sub eax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    cmp eax,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    jae sirhChainPrev
;    
    add eax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    add eax,edx
    xchg eax,dword ptr es:[edx].isa_irq_chain
    mov dword ptr es:[ebp].isa_irch_chain,eax
;
    xor eax,eax
    xchg eax,dword ptr es:[edx].isa_irq_chain+4
    mov dword ptr es:[ebp].isa_irch_chain+4,eax
    jmp sirhDone

sirhChainPrev:
    mov ecx,ebp
    sub ecx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    add eax,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    add eax,edx
    xchg eax,dword ptr es:[ecx].isa_irch_chain
    mov dword ptr es:[ebp].isa_irch_chain,eax
;    
    xor eax,eax
    xchg eax,dword ptr es:[ecx].isa_irch_chain+4
    mov dword ptr es:[ebp].isa_irch_chain+4,eax
    jmp sirhDone
        
sirhReplace:    
    pop esi
    pop ds
    pop ebx
;    
    mov es:[edx].isa_irq_handler_data,bx
    mov es:[edx].isa_irq_handler_ads,esi
    mov word ptr es:[edx].isa_irq_handler_ads+4,ds
    mov es:[edx].isa_irq_detect_nr,-1
    jmp sirhDone

sirhFail:
    pop esi
    pop ds
    pop ebx
    
sirhDone:
    popad
    pop es
    pop ds
    ret
add_long_irq  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateLongMsi
;
;       DESCRIPTION:    Create new MSI context
;
;       RETURNS:        ESI       Address of entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_long_msi_name DB 'Create Long MSI', 0

create_long_msi   Proc far
    push ds
    push es
    push eax
    push bx
    push ecx
    push edx
    push edi
;
    mov ecx,OFFSET MsiEnd - OFFSET MsiStart
    mov eax,ecx
    AllocateSmallLinear
;
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,OFFSET MsiStart
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov edi,edx
    add edi,OFFSET MsiPatchLinear + 1 - OFFSET MsiStart
    mov es:[edi],edx
;
    mov eax,OFFSET MsiDefault - OFFSET MsiStart    
    add eax,edx
    mov dword ptr es:[edx].msi_handler_ads,eax
    mov word ptr es:[edx].msi_handler_ads+4,long_kernel_code_sel
    mov word ptr es:[edx].msi_handler_data,0
;    
    mov esi,OFFSET MsiEntry - OFFSET MsiStart
    add esi,edx
;
    pop edi
    pop edx
    pop ecx
    pop bx
    pop eax
    pop es
    pop ds
    ret
create_long_msi   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddLongMsi
;
;       DESCRIPTION:    Add MSI handler
;
;       PARAMETERS:     ESI         Linear address of entry-point
;                       DS          Handler data
;                       ES:EDI      Handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_long_msi_name   DB 'Add Long MSI', 0

add_long_msi   Proc far
    push fs
    push ax
    push edx
;    
    mov ax,flat_sel
    mov fs,ax
;    
    mov edx,esi
    sub edx,OFFSET MsiEntry - OFFSET MsiStart
;    
    mov fs:[edx].msi_handler_data,ds
    mov fs:[edx].msi_handler_ads,edi
    mov word ptr fs:[edx].msi_handler_ads+4,es
;    
    pop edx
    pop ax
    pop fs
    ret
add_long_msi  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartSyscall
;
;       DESCRIPTION:    Start syscall
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_syscall_name   DB 'Start Syscall', 0

start_syscall   Proc far
    push es
    push fs
    pushad
;    
    GetCore
    mov edx,fs:cs_syscall_eip
    or edx,edx
    jnz start_syscall_setup
;   
    mov ax,flat_sel
    mov es,ax 
    mov eax,OFFSET syscall_end - OFFSET syscall_start
    mov ecx,eax
    AllocateSmallLinear
    mov fs:cs_syscall_eip,edx
;
    mov esi,OFFSET syscall_start
    mov edi,edx
    rep movs byte ptr es:[edi],es:[esi]
;
    mov eax,fs:cs_linear
    mov es:[edx+2],eax
    xor eax,eax
    mov es:[edx+6],eax            

start_syscall_setup:    
    mov eax,fs:cs_syscall_eip
    mov edx,long_user_data_sel - 8
    shl edx,16
    mov dx,long_kernel_code_sel
    mov ecx,IA32_STAR
    wrmsr
;
    mov eax,fs:cs_syscall_eip
    xor edx,edx
    mov ecx,IA32_LSTAR
    wrmsr
;
    mov ecx,IA32_CSTAR
    wrmsr
;
    mov eax,700h
    xor edx,edx
    mov ecx,IA32_FMASK
    wrmsr
;
    popad
    pop fs
    pop es
    ret
start_syscall   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SwitchToLongMode
;
;       DESCRIPTION:    Switch to long mode
;
;       PARAMETERS:     EAX         Long mode CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_to_long_mode_name   DB 'Switch To Long Mode', 0

switch_to_long_mode   Proc far
    push eax
    push ebx
    push ecx
    push edx
    pushf
;
    mov ebx,eax
    cli
;
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ecx,IA32_EFER
    rdmsr
    or eax,101h
    wrmsr
;
    mov cr3,ebx
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    lidt fword ptr cs:long_idt_size
;
    popf
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
switch_to_long_mode  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SwitchToProtectedMode
;
;       DESCRIPTION:    Switch to protected mode
;
;       PARAMETERS:     EAX         Protected mode CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_to_protected_mode_name   DB 'Switch To Protected Mode', 0

switch_to_protected_mode   Proc far
    push eax
    push ebx
    push ecx
    push edx
    pushf
;
    mov ebx,eax
    cli
;
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ecx,IA32_EFER
    rdmsr
    and eax,0FFFFFEFFh   
    wrmsr
;
    mov cr3,ebx
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    lidt fword ptr cs:prot_idt_size
;
    popf
    pop edx
    pop ecx
    pop ebx
    pop eax    
    ret
switch_to_protected_mode  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LongModeReset
;
;       DESCRIPTION:    Long mode reset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

long_mode_reset_name   DB 'Long Mode Reset', 0

long_mode_reset:
    mov dx,flat_sel
    mov ds,dx
;
    movzx edi,al
    shl edi,4
    add edi,long_idt_linear
;    
    mov ebx,13 * 16
    xor eax,eax
    mov [ebx+edi],eax
    mov [ebx+edi+4],eax
    mov [ebx+edi+8],eax
    mov [ebx+edi+12],eax
;
    mov ebx,8 * 16
    mov [ebx+edi],eax
    mov [ebx+edi+4],eax
    mov [ebx+edi+8],eax
    mov [ebx+edi+12],eax
;
    mov ax,-1
    mov ds,ax

reset_wait:
    jmp reset_wait

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Is64BitExe
;
;       DESCRIPTION:    Check for 64-bit exe
;
;       PARAMETERS:     DS:(E)SI  Program name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_64_bit_exe_name DB 'Is 64-bit Executable?', 0

is_64_bit_exe   Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    mov ax,ds
    mov es,ax
    mov edi,esi
;
    xor cl,cl
    OpenFile
    jc is_64_done
;
    mov eax,SIZE elf_header
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    ReadFile
    jc is_64_close_fail
;
    cmp eax,ecx
    jnz is_64_close_fail
;
    mov eax,es:elf_magic
    cmp eax,464C457Fh
    jne is_64_close_fail
;
    mov al,es:elf_file_class
    cmp al,EFC64
    jne is_64_close_fail
;
    mov al,es:elf_endian
    cmp al,EELSB
    jne is_64_close_fail
;        
    mov al,es:elf_abi
    cmp al,EOSABI_SYSV
    jne is_64_close_fail
;
    mov ax,es:elf_type
    cmp ax,ET_EXEC
    jne is_64_close_fail
;
    FreeMem    
    CloseFile
    clc
    jmp is_64_done

is_64_close_fail:
    FreeMem
    CloseFile
    stc
        
is_64_done:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
is_64_bit_exe   Endp

is_64_bit_exe16 Proc far
    push esi
    movzx esi,si
    call is_64_bit_exe
    pop esi
    ret
is_64_bit_exe16 Endp

is_64_bit_exe32 Proc far
    call is_64_bit_exe
    ret
is_64_bit_exe32 Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateLongThread
;
;       DESCRIPTION:    Create long mode thread
;
;       PARAMETERS:     AL      Prio
;                       RCX     Stack size
;                       RDX     Param
;                       RSI     Start address
;                       ES:EDI  Thread name                       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_long_thread_name DB 'Create Long Thread', 0

create_long_thread   Proc far
    push gs
    push eax
;
    mov ax,flat_sel
    mov gs,ax
;    
    CreateLongThreadInfo
    mov edx,esi
    mov ax,long_kernel_code_sel
    mov ds,ax
    mov esi,OFFSET long_thread_start
    pop eax
    mov ah,2
    CreateThread
    pop gs
    ret
create_long_thread  Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitLongProcess
;
;       DESCRIPTION:    Init process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitLongProcess   Proc near
    push ds
    pushad
;
    mov ax,flat_sel
    mov ds,ax
;    
    mov edx,OFFSET long_alloc_section
    xor eax,eax
    mov [edx],eax
    mov [edx+4],eax
;    
    mov edx,OFFSET long_alloc_base
    mov eax,long_buf_linear SHR 9
    mov [edx],eax
    mov eax,PAGE_TABLE_LINEAR SHR 32
    mov [edx+4],eax
;
    mov edx,OFFSET long_ldt_spinlock
    xor eax,eax
    mov [edx],eax
    mov [edx+4],eax
;    
    mov edx,long_ldt_linear
    mov ecx,1FFFh
    mov eax,edx
    mov eax,8
    xor ebx,ebx

init_ldt_loop:
    mov [edx],eax    
    mov [edx+4],ebx
    add edx,8
    add eax,8
    loop init_ldt_loop                
;
    mov eax,-1
    mov [edx],eax    
;
    popad
    pop ds
    ret
InitLongProcess Endp    
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetLongTlsLinear
;
;       DESCRIPTION:    Setup long TLS linear
;
;       PARAMETERS:     EDX:EAX TLS linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_long_tls_linear_name DB 'Set Long TLS Linear', 0

set_long_tls_linear   Proc far
    push es
;    
    mov ebx,eax
    GetThread
    mov es,ax
    mov dword ptr es:p_tls_linear,ebx
    mov dword ptr es:p_tls_linear+4,edx
;
    pop es    
    ret
set_long_tls_linear   Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitLongExe
;
;       DESCRIPTION:    Init long mode executable
;
;       PARAMETERS:     DS:ESI  Program name
;                       ES:EDI  Cmd line    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_long_exe_name DB 'Init Long Exe', 0

init_long_exe   Proc far
    push ds
    push es
    pushad
;
    call InitLongProcess
;    
    mov ebp,long_process_linear
    push esi
    xor ecx,ecx

init_pg_name_loop:
    lodsb
    or al,al
    jz init_pg_name_ok
;
    inc ecx
    jmp init_pg_name_loop

init_pg_name_ok:
    pop esi
    inc ecx
;
    push es
    push edi
;    
    mov eax,ecx
    AllocateLongBuf
    mov edi,edx
;    
    mov ax,flat_sel
    mov es,ax
    mov es:[ebp].ep_prog_name,edi
    rep movsb
;
    pop edi
    pop es
;
    mov ax,es
    mov ds,ax
    mov esi,edi
;    
    push esi
    xor ecx,ecx

init_pg_cmd_loop:
    lodsb
    or al,al
    jz init_pg_cmd_ok
;
    inc ecx
    jmp init_pg_cmd_loop

init_pg_cmd_ok:
    pop esi
    inc ecx
;    
    mov eax,ecx
    AllocateLongBuf
    mov edi,edx
;    
    mov ax,flat_sel
    mov es,ax
    mov es:[ebp].ep_prog_cmd,edi
    rep movsb
;
    mov edi,es:[ebp].ep_prog_name
    xor cx,cx
    OpenFile
    mov es:[ebp].ep_file_handle,bx    
;    
    popad
    pop es
    pop ds
    ret
init_long_exe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateTlsHeader
;
;   DESCRIPTION:    Create TLS header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateTlsHeader    Proc near
    push ebx
    push ecx
    push edx
    push esi
    push edi
;    
    mov esi,long_process_linear
    movzx ebx,[esi].elf_shentsize
    movzx ecx,[esi].elf_shnum
;    
    mov esi,dword ptr ds:[esi].elf_shoff
    mov [esi].elft_paddr,0
    mov [esi].elft_psize,0
    mov [esi].elft_vsize,0
;    
    mov edi,esi
    add edi,ebx
    sub ecx,1
    jbe create_tls_done

create_tls_loop:
    mov eax,dword ptr [edi].elfs_flags
    test ax,400h
    jz create_tls_next
;
    mov eax,[esi].elft_paddr
    or eax,eax
    jnz create_tls_add
;
    mov eax,dword ptr [edi].elfs_paddr
    mov [esi].elft_paddr,eax
;
    mov eax,dword ptr [edi].elfs_align
    mov [esi].elft_vsize,eax
;
    mov eax,dword ptr [edi].elfs_size
    mov [esi].elft_psize,eax
    jmp create_tls_next    

create_tls_add:
    mov eax,dword ptr [edi].elfs_align
    add [esi].elft_vsize,eax
    
create_tls_next:
    add edi,ebx
    loop create_tls_loop
;
    mov eax,[esi].elft_vsize
    or eax,eax
    jz create_tls_done
;
    mov edi,long_process_linear
    mov bx,ds:[edi].ep_file_handle
;
    mov eax,[esi].elft_paddr
    SetFilePos32
;
    mov eax,[esi].elft_vsize
    mov ecx,eax
    AllocateLongBuf
    mov edi,edx
    mov [esi].elft_data,edi
;
    mov ecx,[esi].elft_psize
    ReadFile            
;
    add edi,ecx
    mov ecx,[esi].elft_vsize
    sub ecx,[esi].elft_psize
    jbe create_tls_done
;
    xor al,al
    rep stos byte ptr es:[edi]

create_tls_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
CreateTlsHeader    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartLongExe
;
;       DESCRIPTION:    Start long mode executable
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_long_exe_name DB 'Start Long Exe', 0

start_long_exe:
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
    mov gs,ax
;
    mov esi,long_process_linear
    mov bx,ds:[esi].ep_file_handle
;
    xor eax,eax
    SetFilePos32
;
    mov edi,long_process_linear
    mov ecx,SIZE elf_header
    ReadFile            
;
    mov ax,ds:[esi].elf_phnum
    mov dx,ds:[esi].elf_phentsize
    mul dx
    push dx
    push ax
    pop eax
    or eax,eax
    jz sleFailed
;
    mov ecx,eax
    AllocateLongBuf
    mov edi,edx
;
    mov eax,dword ptr ds:[esi].elf_phoff
    SetFilePos32    
    ReadFile
;
    cmp eax,ecx
    jne sleFailed        
;    
    mov dword ptr ds:[esi].elf_phoff,edi
;
    mov ax,ds:[esi].elf_shnum
    mov dx,ds:[esi].elf_shentsize
    mul dx
    push dx
    push ax
    pop eax
    or eax,eax
    jz sleLoad
;
    mov ecx,eax
    AllocateLongBuf
    mov edi,edx
;
    mov eax,dword ptr ds:[esi].elf_shoff
    SetFilePos32    
    ReadFile
;
    cmp eax,ecx
    jne sleLoad
;    
    mov dword ptr ds:[esi].elf_shoff,edi
;
    call CreateTlsHeader    

sleLoad:    
    db 0EAh
    dd OFFSET start64
    dw long_kernel_code_sel
    
sleFailed:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleCodeFault
;
;       DESCRIPTION:    Handle code fault from long mode
;
;       PARAMETERS:     EDX         Offset into file
;
;       RETURNS:        EDX         Linear buffer offset
;                       EAX         Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_code_fault_name DB 'Handle Code Fault', 0

handle_code_fault   Proc far
    push es
;
    mov ax,flat_sel
    mov es,ax
    mov esi,long_process_linear
;   
    mov bx,es:[esi].ep_file_handle
    mov eax,edx
    SetFilePos32    
;   
    mov eax,ecx
    AllocateLongBuf
;
    mov edi,edx
    ReadFile
;
    push eax
    push edx
    GetThread
    mov es,ax
    mov eax,dword ptr es:p_tls_linear
    mov edx,dword ptr es:p_tls_linear+4
    mov ecx,0C0000101h
    wrmsr
    pop edx
    pop eax
;
    pop es            
    ret
handle_code_fault   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Init
;
;    DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init    proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET has_long_mode
    mov edi,OFFSET has_long_mode_name
    xor cl,cl
    mov ax,has_long_mode_nr
    RegisterOsGate
;
    mov esi,OFFSET create_long_irq
    mov edi,OFFSET create_long_irq_name
    xor cl,cl
    mov ax,create_long_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET add_long_irq
    mov edi,OFFSET add_long_irq_name
    xor cl,cl
    mov ax,add_long_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET create_long_msi
    mov edi,OFFSET create_long_msi_name
    xor cl,cl
    mov ax,create_long_msi_nr
    RegisterOsGate
;
    mov esi,OFFSET add_long_msi
    mov edi,OFFSET add_long_msi_name
    xor cl,cl
    mov ax,add_long_msi_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_trap_gate
    mov edi,OFFSET setup_long_trap_gate_name
    xor cl,cl
    mov ax,setup_long_trap_gate_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_int_gate
    mov edi,OFFSET setup_long_int_gate_name
    xor cl,cl
    mov ax,setup_long_int_gate_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_spurious_int
    mov edi,OFFSET setup_long_spurious_int_name
    xor cl,cl
    mov ax,setup_long_spurious_int_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_schedule_int
    mov edi,OFFSET setup_long_schedule_int_name
    xor cl,cl
    mov ax,setup_long_schedule_int_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_timer_int
    mov edi,OFFSET setup_long_timer_int_name
    xor cl,cl
    mov ax,setup_long_timer_int_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_preempt_int
    mov edi,OFFSET setup_long_preempt_int_name
    xor cl,cl
    mov ax,setup_long_preempt_int_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_hpet_int
    mov edi,OFFSET setup_long_hpet_int_name
    xor cl,cl
    mov ax,setup_long_hpet_int_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_crash_gate
    mov edi,OFFSET setup_long_crash_gate_name
    xor cl,cl
    mov ax,setup_long_crash_gate_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_long_nmi_core_dump
    mov edi,OFFSET setup_long_nmi_core_dump_name
    xor cl,cl
    mov ax,setup_long_nmi_core_dump_nr
    RegisterOsGate
;
    mov esi,OFFSET switch_to_long_mode
    mov edi,OFFSET switch_to_long_mode_name
    xor cl,cl
    mov ax,switch_to_long_mode_nr
    RegisterOsGate
;
    mov esi,OFFSET switch_to_protected_mode
    mov edi,OFFSET switch_to_protected_mode_name
    xor cl,cl
    mov ax,switch_to_protected_mode_nr
    RegisterOsGate
;
    mov esi,OFFSET long_mode_reset
    mov edi,OFFSET long_mode_reset_name
    xor cl,cl
    mov ax,long_mode_reset_nr
    RegisterOsGate
;
    mov esi,OFFSET init_long_exe
    mov edi,OFFSET init_long_exe_name
    xor cl,cl
    mov ax,init_long_exe_nr
    RegisterOsGate
;
    mov esi,OFFSET start_long_exe
    mov edi,OFFSET start_long_exe_name
    xor cl,cl
    mov ax,start_long_exe_nr
    RegisterOsGate
;
    mov esi,OFFSET set_long_tls_linear
    mov edi,OFFSET set_long_tls_linear_name
    xor cl,cl
    mov ax,set_long_tls_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET handle_code_fault
    mov edi,OFFSET handle_code_fault_name
    xor cl,cl
    mov ax,handle_long_code_fault_nr
    RegisterOsGate
;
    mov esi,OFFSET start_syscall
    mov edi,OFFSET start_syscall_name
    xor cl,cl
    mov ax,start_syscall_nr
    RegisterOsGate
;
    mov ebx,OFFSET is_64_bit_exe16
    mov esi,OFFSET is_64_bit_exe32
    mov edi,OFFSET is_64_bit_exe_name
    mov dx,virt_ds_in
    mov ax,is_64_bit_exe_nr
    RegisterUserGate
;
    mov esi,OFFSET create_long_thread
    mov edi,OFFSET create_long_thread_name
    xor dx,dx
    mov ecx,UG_SYSCALL_RD_PAR_ES_EDI
    mov ax,create_long_thread_nr
    RegisterBimodalSyscall
;    
    call InitIdt
;
    mov esi,OFFSET nmi_int
    mov al,2
    xor bl,bl
    SetupLongIntGate    
;
    mov ax,long_kernel_code_sel
    mov ds,ax
    mov es,ax
;    
    mov esi,OFFSET load_long_regs
    mov edi,OFFSET load_long_regs_name
    xor cl,cl
    mov ax,load_long_regs_nr
    RegisterOsGate
;    
    mov esi,OFFSET load_long_breaks
    mov edi,OFFSET load_long_breaks_name
    xor cl,cl
    mov ax,load_long_breaks_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_buf
    mov edi,OFFSET allocate_buf_name
    xor cl,cl
    mov ax,allocate_long_buf_nr
    RegisterOsGate
;
    mov esi,OFFSET free_buf
    mov edi,OFFSET free_buf_name
    xor cl,cl
    mov ax,free_long_buf_nr
    RegisterOsGate
;
    mov esi,OFFSET create_long_thread_info
    mov edi,OFFSET create_long_thread_info_name
    xor cl,cl
    mov ax,create_long_thread_info_nr
    RegisterOsGate
;
    mov bx,long_ldt_sel
    xor cx,cx
    mov edx,long_ldt_linear
    CreateLdtSelector        
    ret
init    endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Init_task
;
;    DESCRIPTION:    Init tasking
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_task:
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET test_process
    mov edi,OFFSET test_process_name
    mov ax,202h
    mov ecx,1000h
    mov bx,1
    CreateProcess
;
    popad
    pop es
    pop ds
    retf
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Test_process
;
;    DESCRIPTION:    Test process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_process_name  DB 'Test Process', 0

test_process:
    int 3
    db 0EAh
    dd OFFSET test64
    dw long_kernel_code_sel
    
    option PROCALIGN:32 

code32_end  Proc near
code32_end  Endp

code32  Ends    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  64-bit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.x64

Code64 segment byte public use64 'code64'

    org OFFSET code32_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LocalWriteChar
;
;   DESCRIPTION:    Write a char to screen
;
;   PARAMETERS:     DL          Char
;                   DH          Attrib
;                   AL          Row
;                   AH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalWriteChar  proc near
    push rax
    push rbx
    push rcx
;    
    mov cx,ax
    mov al,80
    mul ch
    add al,cl
    adc ah,0
    add ax,ax
    movzx rbx,ax
    mov [r8+rbx],dx
;
    pop rcx
    pop rbx
    pop rax
    ret
LocalWriteChar  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SingleHex
;
;   DESCRIPTION:    Convert number to printable hex
;
;   PARAMETERS:     AL          Value
;
;   RETURNS:        AX          Hex value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SingelHex   Proc near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb shLow1
    
    add al,7

shLow1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb shHigh1
    
    add ah,7

shHigh1:
    add ah,30h
    ret
SingelHex   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteSpace
;
;   DESCRIPTION:    Write space
;
;   PARAMETERS:     CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSpace  Proc near
    push rax
    push rcx
    push rdx
;
    mov ah,cl    
    xchg rax,rdx
    mov dl,'_'
    call LocalWriteChar
;    
    pop rdx
    pop rcx
    pop rax
    add dl,1
    ret
WriteSpace  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteHexByte
;
;   DESCRIPTION:    Write a hex byte to screen
;
;   PARAMETERS:     AL          Data
;                   CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    Proc near
    push rax
    push rcx
    push rdx
;
    mov ah,cl
    mov cx,ax
    call SingelHex
;    
    push rax
    xchg rax,rdx
    mov dh,ch
    call LocalWriteChar
    pop rdx
;    
    inc al
    mov dl,dh
    mov dh,ch
    call LocalWriteChar
    pop rdx
    add dl,2
;    
    pop rcx
    pop rax
    ret
WriteHexByte    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteHexWord
;
;   DESCRIPTION:    Write a hex word to screen
;
;   PARAMETERS:     AX          Data
;                   CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    Proc near
    push rax
    rol ax,8
    call WriteHexByte
    rol ax,8
    call WriteHexByte
    pop rax
    ret
WriteHexWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteHexDword
;
;   DESCRIPTION:    Write a hex dword to screen
;
;   PARAMETERS:     EAX         Data
;                   CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword   Proc near
    push rax
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    pop rax
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteHexQword
;
;   DESCRIPTION:    Write a hex qword to screen
;
;   PARAMETERS:     RAX         Data
;                   CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexQword   Proc near
    push rax
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
;  
    call WriteSpace
;    
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    pop rax
    ret
WriteHexQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteString
;
;   DESCRIPTION:    Write string to screen
;
;   PARAMETERS:     RDI         String
;                   AH          Attrib
;                   DH          Row
;                   DL          Col
;                   RCX         Characters
;                   R8          Screen base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteString Proc near
    xchg rax,rdx
    push rdi
    push rbx

wsLoop:
    push rax
    mov bh,al
    mov al,ah
    mov bl,80
    mul bl
    add al,bh
    adc ah,0
    add ax,ax
    movzx rbx,ax
    pop rax
    mov dl,[rdi]
    cmp dl,13
    jne wsNotCr

    xor al,al
    jmp wsEnd

wsNotCr:
    cmp dl,10
    jne wsNotLf

    inc ah
    jmp wsEnd
    
wsNotLf:
    mov [r8+rbx],dx
    
    inc al

wsEnd:
    cmp al,80
    jne wsLineShiftOk

    inc ah
    mov al,0

wsLineShiftOk:
    cmp ah,24
    jb wsPageShiftOk
    
    mov ah,24       

wsPageShiftOk:
    inc rdi
    loop wsLoop

    pop rbx
    pop rdi
    xchg rax,rdx
    ret
WriteString Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteQwordReg
;
;   DESCRIPTION:    Write 64-bit registers
;
;   PARAMETERS:     RDI     Register table
;                   CL      Attrib
;                   DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteQwordReg   Proc near
    push rcx
    mov ah,cl
    mov rcx,4
    call WriteString
    pop rcx   
    add rdi,4
;
    xor rbx,rbx
    mov ebx,[rdi]
    mov rax,[r15+rbx]
    call WriteHexQword
    add rdi,4
    inc dl
    mov al,[rdi]
    or al,al
    jnz WriteQwordReg
;
    ret
WriteQwordReg   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteSegReg
;
;   DESCRIPTION:    Write segment registers
;
;   PARAMETERS:     CL      Attrib
;                   DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

seg_reg_tab:
    db 'CS='
    dd reg_cs
    db 'DS='
    dd reg_ds
    db 'ES='
    dd reg_es
    db 'FS='
    dd reg_fs
    db 'GS='
    dd reg_gs
    db 'SS='
    dd reg_ss
    db 0

WriteSegReg Proc near
    mov rdi,OFFSET seg_reg_tab

wsrLoop:
    push rcx
    mov ah,cl
    mov rcx,3
    call WriteString
    pop rcx   
    add rdi,3
;
    xor rbx,rbx
    mov ebx,[rdi]
    mov ax,[r15+rbx]
    call WriteHexWord
    add rdi,4
    inc dl
    mov al,[rdi]
    or al,al
    jnz wsrLoop
;
    ret
WriteSegReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteFlags
;
;   DESCRIPTION:    Write FLAGS
;
;   PARAMETERS:     DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


flags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_end  DB 0FFh

WriteFlags  Proc near
    mov rbx,reg_flags
    mov rax,[r15+rbx]
    mov rdi,OFFSET flags_tab

wfLoop:
    mov ch,[rdi]
    or ch,ch
    je wfNext
;    
    cmp ch,0FFh
    je wfDone
;    
    push rdi
    mov cl,10
    test ax,1
    jz wfPosOk
;
    add rdi,3
    mov cl,12

wfPosOk:
    push rax
    mov ah,cl
    mov rcx,3
    call WriteString
    pop rax
    pop rdi
    
wfNext:
    add rdi,6
    shr rax,1
    jmp wfLoop
    
wfDone:
    ret
WriteFlags  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   qword reg tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

qword_reg_tab1:
    db 'RAX='
    dd reg_rax
    db 'RBX='
    dd reg_rbx
    db 'RCX='
    dd reg_rcx
    db 0

qword_reg_tab2:
    db 'RDX='
    dd reg_rdx
    db 'RSI='
    dd reg_rsi
    db 'RDI='
    dd reg_rdi
    db 0

qword_reg_tab3:
    db ' R8='
    dd reg_r8
    db ' R9='
    dd reg_r9
    db 'R10='
    dd reg_r10
    db 0

qword_reg_tab4:
    db 'R11='
    dd reg_r11
    db 'R12='
    dd reg_r12
    db 'R13='
    dd reg_r13
    db 0

qword_reg_tab5:
    db 'R14='
    dd reg_r14
    db 'R15='
    dd reg_r15
    db 0

qword_reg_tab6:
    db 'RIP='
    dd reg_rip
    db 'RSP='
    dd reg_rsp
    db 'RBP='
    dd reg_rbp
    db 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteFault
;
;   DESCRIPTION:    Write fault
;
;   PARAMETERS:     AX      Fault #
;                   DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error            '
ke01    DB 'Single step             '
ke02    DB 'NMI                     '
ke03    DB 'Breakpoint              '
ke04    DB 'Overflow                '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code         '
ke07    DB '80387 not present       '
ke08    DB 'Double fault            '
ke09    DB '80387 overrun           '
ke0A    DB 'Invalid TSS             '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault             '
ke0D    DB 'Protection fault        '
ke0E    DB 'Page fault              '
ke0F    DB 'Unknown Fault           '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '

WriteFault  Proc near
    movzx edi,ax
    shl edi,3
    mov eax,edi
    add eax,eax
    add edi,eax
    add edi,OFFSET error_code_tab
    mov ecx,24
    mov ah,11
    call WriteString
;
    add dl,2
    ret
WriteFault  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteErrorCode
;
;   DESCRIPTION:    Write error code
;
;   PARAMETERS:     EAX     Error code
;                   DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_idt  DB 'Idt '
ft_ldt  DB 'Ldt '
ft_gdt  DB 'Gdt '

WriteErrorCode  proc near
    or eax,eax
    jz wecDone
;    
    test ax,2
    jz wecNotIdt
;    
    mov edi,OFFSET ft_idt
    shr ax,3
    jmp wecDo

wecNotIdt:
    mov edi,OFFSET ft_gdt
    test ax,4
    jz wecDo
;    
    mov edi,OFFSET ft_ldt

wecDo:
    push rax
    mov ah,11
    mov cx,4
    call WriteString
    pop rax
;    
    and ax,0FFF8h
    mov cl,11
    call WriteHexWord

wecDone:
    inc dh
    xor dl,dl
    ret
WriteErrorCode  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           do_fault
;
;   DESCRIPTION:    Write fault info
;
;   PARAMETERS:     RBP     Frame pointer
;                   AX      Vector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_fault:
    mov rbx,long_kernel_data_sel
    mov ss,bx
;    
    cli
    push r15
    mov r15,OFFSET regs
    mov [r15+reg_fault],ax
    mov [r15+reg_rcx],rcx
    mov [r15+reg_rdx],rdx
    mov [r15+reg_rsi],rsi
    mov [r15+reg_rdi],rdi
    mov [r15+reg_r8],r8
    mov [r15+reg_r9],r9
    mov [r15+reg_r10],r10
    mov [r15+reg_r11],r11
    mov [r15+reg_r12],r12
    mov [r15+reg_r13],r13
    mov [r15+reg_r14],r14
    pop rax
    mov [r15+reg_r15],rax
;    
    mov rax,[rbp+fault_rip]
    mov [r15+reg_rip],rax
;    
    mov ax,[rbp+fault_cs]
    mov [r15+reg_cs],ax
;
    mov rax,[rbp+fault_rflags]
    mov [r15+reg_flags],rax
;   
    mov rax,[rbp+fault_rsp]
    mov [r15+reg_rsp],rax
;
    mov ax,[rbp+fault_ss]
    mov [r15+reg_ss],ax
;
    mov rax,[rbp+fault_rax]
    mov [r15+reg_rax],rax
;
    mov rax,[rbp+fault_rbx]
    mov [r15+reg_rbx],rax
;
    mov rax,[rbp+fault_rbp]
    mov [r15+reg_rbp],rax
;     
    mov [r15+reg_ds],ds
    mov [r15+reg_es],es
    mov [r15+reg_fs],fs
    mov [r15+reg_gs],gs
;
    mov r8,0B8000h
    xor rdx,rdx
;
    mov ax,[r15+reg_fault]
    call WriteFault
;
    mov eax,[rbp+fault_error_code]
    call WriteErrorCode    
;    
    mov rdi,OFFSET qword_reg_tab1
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab2
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab3
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab4
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab5
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab6
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov cl,10
    xor dl,dl
    call WriteSegReg
    inc dh
    xor dl,dl
;    
    mov cl,10
    xor dl,dl
    call WriteFlags
    inc dh
    xor dl,dl

trap3_loop:
    jmp trap3_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Code patching
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

long_patch_spinlock  DD 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnterCodePatch
;
;           DESCRIPTION:    Take code-patching spinlock
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnterCodePatch    Proc near
    push rax

ecpLoop:
    mov eax,1
    xchg eax,[long_patch_spinlock]
    or eax,eax
    jz ecpLocked
;
    pause
    jmp ecpLoop

ecpLocked:     
    pop rax
    ret
EnterCodePatch    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LeaveCodePatch
;
;           DESCRIPTION:    Release code-patching spinlock
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LeaveCodePatch    Proc near
    mov [long_patch_spinlock],0
    ret
LeaveCodePatch    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PatchUser16
;
;           DESCRIPTION:    Patch 16-bit user gate
;
;           PARAMETERS:     RBP     Fault frame
;                           EDX     Code address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PatchUser16 Proc near
    mov ebx,[edx+3]
    shl ebx,USER_GATE_SHIFT
    add ebx,usergate_linear
;
    mov eax,[ebx].user_gate_entry_offset16
    xchg eax,[edx+3]
;
    mov ax,[ebx].user_gate_entry_sel16
    xchg ax,[edx+7]
;    
    mov al,90h
    xchg al,[edx]
    ret
PatchUser16 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PatchUser32
;
;           DESCRIPTION:    Patch 32-bit user gate
;
;           PARAMETERS:     RBP     Fault frame
;                           EDX     Code address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PatchUser32 Proc near
    mov ebx,[edx+3]
    shl ebx,USER_GATE_SHIFT
    add ebx,usergate_linear
;
    mov eax,[ebx].user_gate_entry_offset32
    xchg eax,[edx+3]
;
    mov ax,[ebx].user_gate_entry_sel32
    xchg ax,[edx+7]
;    
    mov al,90h
    xchg al,[edx]
    ret
PatchUser32 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PatchOs
;
;           DESCRIPTION:    Patch os gate
;
;           PARAMETERS:     RBP     Fault frame
;                           EDX     Code address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PatchOs Proc near
    mov ebx,[edx+3]
    shl ebx,4
    add ebx,osgate_linear
    mov eax,[ebx].os_gate_offset
    xchg eax,[edx+3]
;
    mov ax,[ebx].os_gate_sel
    xchg ax,[edx+7]
;    
    mov al,90h
    xchg al,[edx]
    ret
PatchOs Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int66, int67
;
;           DESCRIPTION:    Trap handlers for int 66 and 67
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PatchError  Proc near
    mov al,0CCh
    mov [edx],al
    ret
PatchError  Endp

int_patch_tab:
ict00   DQ OFFSET PatchError
ict01   DQ OFFSET PatchUser16
ict02   DQ OFFSET PatchOs
ict03   DQ OFFSET PatchUser32

int66:
int67:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    push rcx
    push rdx
;
    call EnterCodePatch
;
    mov ebx,[rbp+fault_cs]
    IsLongCodeSelector
    jnc intpRetry
;
    GetSelectorBaseSize
    jc intpRetry
;
    mov eax,[rbp+fault_rip]
    cmp eax,ecx
    jae intpRetry
;    
    add edx,eax
    sub edx,2
    mov al,[edx]
    cmp al,0CDh
    jne intpRetry
;
    sub dword ptr [rbp+fault_rip],2
    movzx eax,word ptr [edx+7]
    cmp eax,4
    jb intpCall
;
    xor eax,eax

intpCall:
    shl eax,3
    add eax,OFFSET int_patch_tab
    call [eax]

intpRetry:
    call LeaveCodePatch
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rbp
    add rsp,8
    iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           trap vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

regs  Reg64 <>

pretask0:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,0
    jmp do_fault

pretask2:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,2
    jmp do_fault

pretask4:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,4
    jmp do_fault

pretask5:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,5
    jmp do_fault

pretask7:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,7
    jmp do_fault

pretask9:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,9
    jmp do_fault

pretask10:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,10
    jmp do_fault

pretask11:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,11
    jmp do_fault

pretask12:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,12
    jmp do_fault

pretask16:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,9
    jmp do_fault


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           do_exception
;
;   DESCRIPTION     run exception handler
;
;   PARAMETERS:     AX      Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_exception:
    push fs
    TryLockTask
    jc do_exception_block
;
    CrashGate

do_exception_block:
    push rax
    GetThread
    mov bx,ax
    GetSelectorBaseSize
    pop rax
;
    mov [edx].p_fault_vector,al
;    
    pop rbx
    mov [edx].p_fs,bx
;    
    pop [edx].p_rdi
    pop [edx].p_rsi
    pop [edx].p_rdx
    pop [edx].p_rcx
    pop [edx].p_rbx
    pop [edx].p_rax
;
    pop [edx].p_rbp
    pop rbx
    mov [edx].p_fault_code,rbx
;
    pop [edx].p_rip
    pop rbx
    mov [edx].p_cs,bx
;    
    pop [edx].p_rflags
;    
    pop [edx].p_rsp
    pop rbx
    mov [edx].p_ss,bx
;
    mov [edx].p_r8,r8    
    mov [edx].p_r9,r9  
    mov [edx].p_r10,r10   
    mov [edx].p_r11,r11   
    mov [edx].p_r12,r12   
    mov [edx].p_r13,r13   
    mov [edx].p_r14,r14   
    mov [edx].p_r15,r15    
;
    mov [edx].p_ds,ds
    mov [edx].p_es,es
    mov [edx].p_gs,gs
;            
    DebugBlock

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           trap_1
;
;   DESCRIPTION     Single step fault
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_1:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;
    GetSchedulerLockCounter
    add ax,1
    jnc t1_ret
;    
    GetThread
    or ax,ax
    jz t1_ret
;    
    sti
    mov eax,[rbp+fault_rflags]
    or eax,10100h
    mov [rbp+fault_rflags],eax
;
    mov eax,1
    jmp do_exception

t1_ret:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rbp
    add rsp,8
    iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           trap_3
;
;   DESCRIPTION     Breakpoint fault
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_3:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;    
    mov eax,3
    jmp do_exception


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           invalid_opcode
;
;   DESCRIPTION     Invalid opcode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

invalid_opcode:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;    
    mov eax,6
    jmp do_exception

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           protection fault
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

protection_fault:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;
    call EnterCodePatch
;    
    mov ebx,[rbp+fault_cs]
    IsLongCodeSelector
    jnc gpfDefault
;
    GetSelectorBaseSize
    jc gpfDefault
;
    mov eax,[rbp+fault_rip]
    cmp eax,ecx
    jae gpfDefault
;    
    add edx,eax
    mov al,[edx]
;
    cmp al,0CDh
    jne gpfNotInt
;
    mov al,[edx+1]
    cmp al,66h
    je gpfRetry
;
    cmp al,67h
    je gpfRetry
;
    cmp al,9Ah
    je gpfRetry
;
    jmp gpfDefault
        
gpfNotInt:
    cmp al,3Eh
    je gpfGate32
;
    cmp al,67h
    jne gpfDefault
;
    mov al,[edx+2]
    cmp al,9Ah
    jne gpfDefault
;
    mov ax,[edx+7]
    or ax,ax
    jz gpfDefault
;
    cmp ax,3
    ja gpfDefault

gpfGate16:
    call LeaveCodePatch
;
    mov al,0CDh
    xchg al,[edx]
    jmp gpfDoRetry

gpfGate32:    
    mov al,[edx+1]
    cmp al,67h
    jne gpfDefault
;
    mov ax,[edx+7]
    cmp ax,3
    ja gpfDefault

gpfCall32:
    call LeaveCodePatch
;
    mov al,0CDh
    xchg al,[edx]
    jmp gpfDoRetry

gpfRetry:
    call LeaveCodePatch

gpfDoRetry:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rbp
    add rsp,8
    iretq

gpfDefault:
    call LeaveCodePatch
;    
    mov eax,13
    jmp do_exception

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_error
;
;           DESCRIPTION:    Page fault error
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_error    Proc near
    pop rax
    mov eax,14
    jmp do_exception

page_fault_error    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_plm4
;
;           DESCRIPTION:    Page fault in PLM4
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_plm4    Proc near
    mov rdi,rsi
    sub rdi,PTR_TABLE_LINEAR
    shr rdi,9
    and rdi,0FFFFFFFFFFFFFFF8h
    mov cx,di
    add rdi,PLM4_TABLE_LINEAR
;
    push rdi
    AllocatePhysical64
    pop rdi
;    
    shl rbx,32
    or rax,rbx
    shr cx,9
    and cl,4
    xor cl,4
    or cl,3
    mov al,cl
    mov [rdi],rax
;
    sub rdi,PLM4_TABLE_LINEAR
    shl rdi,9
    add rdi,PTR_TABLE_LINEAR
    mov rcx,512
    xor rax,rax
    rep stosq        
    ret
page_fault_plm4     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_ptr
;
;           DESCRIPTION:    Page fault in dir ptr
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_ptr    Proc near
    mov rdi,rsi
    sub rdi,DIR_TABLE_LINEAR
    shr rdi,9
    and rdi,0FFFFFFFFFFFFFFF8h
    add rdi,PTR_TABLE_LINEAR
;
    push rdi
    AllocatePhysical64
    pop rdi
;    
    shl rbx,32
    or rax,rbx
    mov al,7
    mov [rdi],rax
;
    sub rdi,PTR_TABLE_LINEAR
    shl rdi,9
    add rdi,DIR_TABLE_LINEAR
    mov rcx,512
    xor rax,rax
    rep stosq
    ret
page_fault_ptr     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           process_fault_dir
;
;           DESCRIPTION:    Page fault in process dir
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_fault_dir   Proc near
    mov rax,rsi
    sub rax,process_page_linear
    shl rax,9
    and eax,0FFC00000h
;
    mov rbx,rax
    shr rbx,32
    or rbx,rbx
    jnz process_fault_dir_local
;
    cmp eax,system_mem_start
    jc process_fault_dir_local
;
    cmp eax,handle_linear
    je process_fault_dir_local
;
    cmp eax,long_process_linear
    je process_fault_dir_local
;
    cmp eax,fixed_process_linear
    je process_fault_dir_local

process_fault_dir_global:
    int 3

process_fault_dir_local:
    mov rax,rsi
    mov rbx,process_page_linear
    sub rax,rbx
    shr rax,9
    mov rdx,DIR_TABLE_LINEAR
    and dl,0F8h
    mov rbx,[rax+rdx]
;
    test bl,1
    jnz page_fault_error
;
    push rax
    push rdx
    AllocatePhysical64
    shl rbx,32
    or rbx,rax
    mov bl,7
;    
    pop rdx
    pop rax
;    
    mov [rax+rdx],rbx
;
    shl rax,9
    mov rdi,PAGE_TABLE_LINEAR
    add rdi,rax
    xor rax,rax
    mov rcx,512
    rep stosq
    ret
process_fault_dir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_dir
;
;           DESCRIPTION:    Page fault in dir
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_dir    Proc near
    mov rax,rsi
    mov rbx,PAGE_TABLE_LINEAR
    sub rax,rbx
    shl rax,9
    and rax,0FFFFFFFFFFC00000h
;
    mov rbx,rax
    shr rbx,32
    or rbx,rbx
    jz page_fault_dir_not_long
;
    jmp page_fault_dir_local
    
page_fault_dir_not_long:
    cmp eax,system_mem_start
    jc page_fault_dir_local
;
    cmp eax,handle_linear
    je page_fault_dir_local
;
    cmp eax,long_process_linear
    je page_fault_dir_local
;
    cmp eax,fixed_process_linear
    je page_fault_dir_local

page_fault_dir_global:
    mov rdx,rsi
    sub rdx,DIR_TABLE_LINEAR
    shl rdx,9
    GetSysPageDir    
    test al,1
    jnz page_fault_dir_global_valid
;    
    int 3

page_fault_dir_global_valid:
    SetPageDir
    ret

page_fault_dir_local:
    mov rax,rsi
    mov rbx,PAGE_TABLE_LINEAR
    sub rax,rbx
    shr rax,9
    mov rdx,DIR_TABLE_LINEAR
    and al,0F8h
    mov rbx,[rax+rdx]
;
    test bl,1
    jnz page_fault_error
;
    push rax
    push rdx
    AllocatePhysical64
    shl rbx,32
    or rbx,rax
    mov bl,7
;    
    pop rdx
    pop rax
;    
    mov [rax+rdx],rbx
;
    shl rax,9
    mov rdi,PAGE_TABLE_LINEAR
    add rdi,rax
    xor rax,rax
    mov rcx,512
    rep stosq
    ret
page_fault_dir     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault64
;
;           DESCRIPTION:    Page fault above 4G
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault64    Proc near
    mov rax,rsi
    mov rbx,PLM4_TABLE_LINEAR
    cmp rax,rbx
    jae page_fault_error
;
    mov rbx,PTR_TABLE_LINEAR    
    cmp rax,rbx
    jae page_fault_plm4
;
    mov rbx,DIR_TABLE_LINEAR
    cmp rax,rbx
    jae page_fault_ptr
;
    mov rbx,PAGE_TABLE_LINEAR
    cmp rax,rbx
    jae page_fault_dir
;        
    mov rbx,long_code_linear
    cmp rax,rbx
    jb page_fault_error
;
    mov rcx,long_code_size
    add rbx,rcx
    cmp rax,rbx
    jae page_fault_not_code
;
    call LoadCode
    jc page_fault_error

page_fault_loaded:
    shr rsi,9    
    mov rdx,PAGE_TABLE_LINEAR
    add rsi,rdx
    and rsi,0FFFFFFFFFFFFFFF8h
    mov [rsi],rax
    jmp page_fault64_retry

page_fault_not_code:
    int 3
    mov rbx,long_ldata_linear
    cmp rax,rbx
    jb page_fault_init
;
    mov rcx,long_ldata_size
    add rbx,rcx
    cmp rax,rbx
    jae page_fault_init
;
    call LoadCode
    jnc page_fault_loaded
    jmp page_fault_error

page_fault_init:
    shr rsi,9    
    mov rdx,PAGE_TABLE_LINEAR
    add rsi,rdx
    and rsi,0FFFFFFFFFFFFFFF8h
    mov rax,[rsi]
    test al,1
    jnz page_fault64_retry
;
    cmp rax,2
    jne page_fault_error    
;
    push rsi
    AllocatePhysical64
    shl rbx,32
    or rax,rbx
    mov al,7
    pop rdi
    mov [rdi],rax
;
    mov rdx,PAGE_TABLE_LINEAR
    sub rdi,rdx
    shl rdi,9
;            
    xor rax,rax
    mov rcx,200h
    rep stosq

page_fault64_retry:    
    ret
page_fault64    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_global
;
;           DESCRIPTION:    Page fault in global memory
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_global    Proc near
    mov rax,PAGE_TABLE_LINEAR
    mov rdx,rsi
    mov rdi,rdx
    shr rdi,9
    and di,0FFF8h
    add rdi,rax
    mov rax,[rdi]
;    
    test al,1
    jnz page_fault_global_retry
;
    push rdi
    AllocatePhysical64
    pop rdi
;
    shl rbx,32
    or rax,rbx
    mov ax,107h
    xchg rax,[rdi]
    test al,1
    jz page_fault_global_retry
;
    mov cx,1
    FlushTlb
    
page_fault_global_retry:
    ret
page_fault_global    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_user
;
;           DESCRIPTION:    Page fault in user memory
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_user    Proc near
    mov rax,PAGE_TABLE_LINEAR
    mov rdx,rsi
    mov rdi,rdx
    shr rdi,9
    and di,0FFF8h
    add rdi,rax
    mov rax,[rdi]
;    
    test al,1
    jnz page_fault_user_retry
;
    and al,7
    cmp al,6
    jne page_fault_user_normal
    jmp page_fault_error

page_fault_user_normal:
    push rdi
    AllocatePhysical64
    pop rdi
;
    shl rbx,32
    or rax,rbx
    mov al,7
    xchg rax,[rdi]
    test al,1
    jz page_fault_user_retry
;
    mov cx,1
    FlushTlb
    
page_fault_user_retry:
    ret
page_fault_user    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_system
;
;           DESCRIPTION:    Page fault in system memory
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_system    Proc near
    mov rax,PAGE_TABLE_LINEAR
    mov rdx,rsi
    mov rdi,rdx
    shr rdi,9
    and di,0FFF8h
    add rdi,rax
    mov rax,[rdi]
;    
    test al,1
    jnz page_fault_system_retry
;
    push rdi
    AllocatePhysical64
    pop rdi
;
    shl rbx,32
    or rax,rbx
    mov al,7
    mov [rdi],rax    
    
page_fault_system_retry:
    ret
page_fault_system    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           handle_page_fault
;
;           DESCRIPTION:    Handle non-present page
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_page_fault   Proc near
    mov rsi,cr2
    mov rax,rsi
    mov rbx,rax
    shr rbx,32
    or rbx,rbx
    jnz page_fault64

page_fault32:
    and eax,0FF800000h
    cmp eax,process_page_linear
    je process_fault_dir
;
    cmp eax,sys_page_linear
    je page_fault_error
;
    mov rax,rsi
    and eax,0FFC00000h
;
    cmp eax,system_mem_start
    jc page_fault_user
;
    cmp eax,handle_linear
    je page_fault_user
;
    cmp eax,long_process_linear
    je page_fault_user
;
    cmp eax,global_page_linear
    jc page_fault_global    
;
    cmp eax,kernel_linear
    jnc page_fault_global
;
    cmp eax,fixed_process_linear
    je page_fault_user
;
    jmp page_fault_system
;
    ret
handle_page_fault   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           page fault
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;    
    mov rax,[rbp].fault_error_code
    test ax,1
    jz page_not_present

page_error_do:
    call page_fault_error
    jmp page_fault_done

page_not_present:
    call handle_page_fault
    mov rax,cr3
    mov cr3,rax

page_fault_done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rbp
    add rsp,8
    iretq
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ISA IRQ handler
;
;               DESCRIPTION:    Code for patching into IRQ handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsaIrqStart:

isa_irq_handler     isa_irq_handler_struc <>

IsaIrqEntry:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;
    mov eax,ds
    push rax
;
    mov eax,es
    push rax
;            
    mov eax,fs
    push rax
;
    xor eax,eax
    mov ds,eax
    mov es,eax
    mov fs,eax
;
    EnterLongInt
    sti
    push rax

IsaIrqPatchLinear:
    mov edi,0
;   
    mov ds,[edi].isa_irq_handler_data
    call fword ptr [edi].isa_irq_handler_ads
;
    mov ebx,OFFSET IsaIrqEnd - OFFSET IsaIrqStart
    add ebx,edi
    jmp [edi].isa_irq_chain

IsaIrqExit:
    pop rax
    cli
    SendEoi
    LeaveLongInt
;
    pop rax
    mov fs,eax
;
    pop rax
    mov es,eax
;
    pop rax
    mov ds,eax
;
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq

IsaIrqDetect:
    mov al,[edi].isa_irq_detect_nr
    NotifyIrq
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

IsaIrqChainStart:

isa_irch_handler      isa_irq_chain_struc <>

IsaIrqChainEntry:
    push rbx
    mov ds,[ebx].isa_irch_handler_data
    call fword ptr [ebx].isa_irch_handler_ads
    pop rbx
;
    mov esi,ebx
    add ebx,OFFSET IsaIrqChainEnd - OFFSET IsaIrqChainStart
    jmp [esi].isa_irch_chain

IsaIrqChainEnd:

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           MSI handler
;
;               DESCRIPTION:    Code for creating MSI interrupt handlers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MsiStart:

msi_handler     msi_handler_struc <>

MsiEntry:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;
    mov eax,ds
    push rax
;
    mov eax,es
    push rax
;            
    mov eax,fs
    push rax
;
    xor eax,eax
    mov ds,eax
    mov es,eax
    mov fs,eax
;
    EnterLongInt
    SendEoi
    sti
    push rax

MsiPatchLinear:
    mov edi,0
;   
    mov ds,[edi].msi_handler_data
    call fword ptr [edi].msi_handler_ads
;
    pop rax
    cli    
    LeaveLongInt
;
    pop rax
    mov fs,eax
;
    pop rax
    mov es,eax
;
    pop rax
    mov ds,eax
;
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq
    
MsiDefault:
    retf

MsiEnd:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           nmi_int
;
;   DESCRIPTION:    NMI handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi_int:
    mov ax,long_kernel_data_sel
    mov ss,ax
;    
    SendEoi
    iretq
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           spurious_int
;
;   DESCRIPTION:    Spurious handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spurious_int:
    iretq
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:          schedule_int
;
;      DESCRIPTION:    Scheduler int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

schedule_int:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;
    mov eax,ds
    push rax
;
    mov eax,es
    push rax
;            
    mov eax,fs
    push rax
;
    xor eax,eax
    mov ds,eax
    mov es,eax
    mov fs,eax
;
    EnterLongInt
    SendEoi
    LeaveLongInt
;
    pop rax
    mov fs,eax
;
    pop rax
    mov es,eax
;
    pop rax
    mov ds,eax
;
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Timer int
;
;   DESCRIPTION:    timer int handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timer_int:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;
    mov eax,ds
    push rax
;
    mov eax,es
    push rax
;            
    mov eax,fs
    push rax
;
    xor eax,eax
    mov ds,eax
    mov es,eax
    mov fs,eax
;
    LongTimerHandler
;    
    pop rax
    mov fs,eax
;
    pop rax
    mov es,eax
;
    pop rax
    mov ds,eax
;
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Preempt int
;
;   DESCRIPTION:    preemption int handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

preempt_int:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;
    mov eax,ds
    push rax
;
    mov eax,es
    push rax
;            
    mov eax,fs
    push rax
;
    xor eax,eax
    mov ds,eax
    mov es,eax
    mov fs,eax
;
    SendEoi
    PreemptExpired
;    
    pop rax
    mov fs,eax
;
    pop rax
    mov es,eax
;
    pop rax
    mov ds,eax
;
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           hpet_int
;
;   DESCRIPTION:    HPET int handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hpet_int:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
;
    mov eax,ds
    push rax
;
    mov eax,es
    push rax
;            
    mov eax,fs
    push rax
;
    xor eax,eax
    mov ds,eax
    mov es,eax
    mov fs,eax
;
    LongHpetHandler
;    
    pop rax
    mov fs,eax
;
    pop rax
    mov es,eax
;
    pop rax
    mov ds,eax
;
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           double_fault
;
;   DESCRIPTION:    double fault
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

double_fault:
    cli
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;   
    mov ax,ds
    push rax
;    
    StartCoreDump
    jc dfFail
;
    mov bx,ds
    GetSelectorBaseSize
    add edx,ebp
;
    mov [edx].fault_vect,8
;
    pop rax
    mov [edx].reg_ds.d_selector,ax
;    
    pop rax
    mov qword ptr [edx].reg_ebp,rax
;    
    pop rax
    mov qword ptr [edx].reg_edi,rax
;    
    pop rax
    mov qword ptr [edx].reg_esi,rax
;    
    pop rax
    mov qword ptr [edx].reg_edx,rax
;    
    pop rax
    mov qword ptr [edx].reg_ecx,rax
;    
    pop rax
    mov qword ptr [edx].reg_ebx,rax
;    
    pop rax
    mov qword ptr [edx].reg_eax,rax
;
    pop rax
    mov [edx].reg_cs.d_selector,ax
;    
    pop rax
    mov qword ptr [edx].reg_eip,rax
;
    pop rax
    mov qword ptr [edx].reg_eflags,rax
;
    pop rax
    mov qword ptr [edx].reg_esp,rax
;
    pop rax
    mov [edx].reg_ss.d_selector,ax
;    
    mov [edx].reg_es.d_selector,es
    mov [edx].reg_fs.d_selector,fs
    mov [edx].reg_gs.d_selector,gs
;            
    mov qword ptr [edx].reg_r8,r8
    mov qword ptr [edx].reg_r9,r9
    mov qword ptr [edx].reg_r10,r10
    mov qword ptr [edx].reg_r11,r11
    mov qword ptr [edx].reg_r12,r12
    mov qword ptr [edx].reg_r13,r13
    mov qword ptr [edx].reg_r14,r14
    mov qword ptr [edx].reg_r15,r15
;
    sldt eax
    mov [edx].reg_ldt.d_selector,ax
;
    str eax
    mov [edx].reg_tr.d_selector,ax
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
    NotifyCoreDump

dfFail:
    jmp dfFail
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           crash_gate_int
;
;   DESCRIPTION:    Crash gate handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crash_gate_int:
    cli
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;   
    mov ax,ds
    push rax
;    
    StartCoreDump
    jc cgFail
;
    mov bx,ds
    GetSelectorBaseSize
    add edx,ebp
;
    mov [edx].fault_vect,1Ah
;
    pop rax
    mov [edx].reg_ds.d_selector,ax
;    
    pop rax
    mov qword ptr [edx].reg_ebp,rax
;    
    pop rax
    mov qword ptr [edx].reg_edi,rax
;    
    pop rax
    mov qword ptr [edx].reg_esi,rax
;    
    pop rax
    mov qword ptr [edx].reg_edx,rax
;    
    pop rax
    mov qword ptr [edx].reg_ecx,rax
;    
    pop rax
    mov qword ptr [edx].reg_ebx,rax
;    
    pop rax
    mov qword ptr [edx].reg_eax,rax
;
    pop rax
    mov [edx].reg_cs.d_selector,ax
;    
    pop rax
    mov qword ptr [edx].reg_eip,rax
;
    pop rax
    mov qword ptr [edx].reg_eflags,rax
;
    pop rax
    mov qword ptr [edx].reg_esp,rax
;
    pop rax
    mov [edx].reg_ss.d_selector,ax
;    
    mov [edx].reg_es.d_selector,es
    mov [edx].reg_fs.d_selector,fs
    mov [edx].reg_gs.d_selector,gs
;            
    mov qword ptr [edx].reg_r8,r8
    mov qword ptr [edx].reg_r9,r9
    mov qword ptr [edx].reg_r10,r10
    mov qword ptr [edx].reg_r11,r11
    mov qword ptr [edx].reg_r12,r12
    mov qword ptr [edx].reg_r13,r13
    mov qword ptr [edx].reg_r14,r14
    mov qword ptr [edx].reg_r15,r15
;
    sldt eax
    mov [edx].reg_ldt.d_selector,ax
;
    str eax
    mov [edx].reg_tr.d_selector,ax
;    
    mov ax,long_kernel_data_sel
    mov ss,ax
    NotifyCoreDump

cgFail:
    jmp cgFail
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           crash_nmi_int
;
;   DESCRIPTION:    Crash NMI handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crash_nmi_int:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
;   
    mov ax,ds
    push rax
;    
    StartCoreDump
    jc nmi_ret
;
    mov bx,ds
    GetSelectorBaseSize
    add edx,ebp
;
    mov [edx].fault_vect,19h
;
    pop rax
    mov [edx].reg_ds.d_selector,ax
;    
    pop rax
    mov qword ptr [edx].reg_ebp,rax
;    
    pop rax
    mov qword ptr [edx].reg_edi,rax
;    
    pop rax
    mov qword ptr [edx].reg_esi,rax
;    
    pop rax
    mov qword ptr [edx].reg_edx,rax
;    
    pop rax
    mov qword ptr [edx].reg_ecx,rax
;    
    pop rax
    mov qword ptr [edx].reg_ebx,rax
;    
    pop rax
    mov qword ptr [edx].reg_eax,rax
;
    pop rax
    mov [edx].reg_cs.d_selector,ax
;    
    pop rax
    mov qword ptr [edx].reg_eip,rax
;
    pop rax
    mov qword ptr [edx].reg_eflags,rax
;
    pop rax
    mov qword ptr [edx].reg_esp,rax
;
    pop rax
    mov [edx].reg_ss.d_selector,ax
;    
    mov [edx].reg_es.d_selector,es
    mov [edx].reg_fs.d_selector,fs
    mov [edx].reg_gs.d_selector,gs
;            
    mov qword ptr [edx].reg_r8,r8
    mov qword ptr [edx].reg_r9,r9
    mov qword ptr [edx].reg_r10,r10
    mov qword ptr [edx].reg_r11,r11
    mov qword ptr [edx].reg_r12,r12
    mov qword ptr [edx].reg_r13,r13
    mov qword ptr [edx].reg_r14,r14
    mov qword ptr [edx].reg_r15,r15
;
    sldt eax
    mov [edx].reg_ldt.d_selector,ax
;
    str eax
    mov [edx].reg_tr.d_selector,ax
;
    mov ax,long_kernel_data_sel
    mov ss,ax
    NotifyCoreDump

nmi_ret:
    pop rax
    mov ds,ax
;    
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           LoadLongRegs
;
;   DESCRIPTION:    Load long mode registers
;
;   PARAMETERS:     EDX     Thread base      
;                   EDI     TSS base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_long_regs_name DB 'Load Long Regs', 0

load_long_regs:
    xor rax,rax
    mov eax,[edx].p_kernel_stack
    mov [edi+4],rax
;
    movzx rax,[edx].p_ss
    push rax
    push [edx].p_rsp
;
    push [edx].p_rflags
;
    movzx rax,[edx].p_cs
    push rax
    push [edx].p_rip
    push [edx].p_rdx
    push [edx].p_rax
;    
    mov rbx,[edx].p_rbx
    mov rcx,[edx].p_rcx
    mov rsi,[edx].p_rsi
    mov rdi,[edx].p_rdi
    mov rbp,[edx].p_rbp
;
    mov r8,[edx].p_r8    
    mov r9,[edx].p_r9  
    mov r10,[edx].p_r10   
    mov r11,[edx].p_r11   
    mov r12,[edx].p_r12   
    mov r13,[edx].p_r13   
    mov r14,[edx].p_r14   
    mov r15,[edx].p_r15    
;
    mov ds,[edx].p_ds
    mov es,[edx].p_es
    mov fs,[edx].p_fs
    mov ax,[edx].p_gs
    mov gs,ax    
    or ax,ax
    jnz load_tls_done
    jmp load_tls_done   ; test, should be removed!
;
    push rcx
    mov eax,dword ptr [edx].p_tls_linear
    mov edx,dword ptr [edx].p_tls_linear+4
    mov ecx,0C0000101h
    wrmsr
    pop rcx

load_tls_done:
    pop rax
    pop rdx
    iretq

test64:
    mov ax,100
;    WaitMicroSec
    jmp test64
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           LoadLongBreaks
;
;   DESCRIPTION:    Load long mode break-points
;
;   PARAMETERS:     EDX     Thread base      
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_long_breaks_name DB 'Load Long Breaks', 0

load_long_breaks    Proc far
    mov rax,[edx].p_dr0
    mov dr0,rax
    mov rax,[edx].p_dr1
    mov dr1,rax
    mov rax,[edx].p_dr2
    mov dr2,rax
    mov rax,[edx].p_dr3
    mov dr3,rax
    mov rax,[edx].p_dr7
    mov dr7,rax
    and ax,0FFh
    jnz load_break_done
;
    and [edx].p_flags,NOT THREAD_FLAG_BP
    
load_break_done:
    ret
load_long_breaks    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateLongThreadInfo
;
;   DESCRIPTION:    Create info buffer for long mode thread
;
;   PARAMETERS:     RCX     Stack size
;                   RDX     Param
;                   RSI     Start address
;
;   RETURNS:        ESI     Block buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_long_thread_info_name DB 'Create Long Thread Info', 0

create_long_thread_info    Proc far
    push rsi
    push rdx
    mov eax,SIZE long_thread_info_struc
    AllocateLongBuf
    mov esi,edx
    pop rdx
;
    mov [esi].lti_stack_size,rcx
    mov [esi].lti_param,rdx
    pop rax
    mov [esi].lti_start,rax    
    ret
create_long_thread_info Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateLongBuf
;
;   DESCRIPTION:    Allocate long buffer
;
;   PARAMETERS:     EAX     Number of bytes
;
;   RETURNS:        EDX     Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_buf_name DB 'Allocate Long Buf', 0

allocate_buf    Proc far
    push rax
    push rcx
;    
    mov ecx,eax
    dec rcx
    shr rcx,12
    inc rcx
;
    call AllocateBuf
    mov rax,PAGE_TABLE_LINEAR
    sub rdx,rax
    shl rdx,9
; 
    pop rcx   
    pop rax    
    ret
allocate_buf    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeLongBuf
;
;   DESCRIPTION:    Free long buffer
;
;   PARAMETERS:     ECX     Number of bytes
;                   EDX     Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_buf_name DB 'Free Long Buf', 0

free_buf    Proc far
    push rax
    push rcx
    push rdx
;    
    dec rcx
    shr rcx,12
    inc rcx
;
    shr rdx,9
    and rdx,0FFFFFFFFFFFFFFF8h
    mov rax,PAGE_TABLE_LINEAR
    add rdx,rax
;
    call FreeBuf
; 
    pop rdx
    pop rcx   
    pop rax
    ret
free_buf    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateUserStack
;
;   DESCRIPTION:    Allocate long mode user stack
;
;   PARAMETERS:     RCX     Stack size
;
;   RETURNS:        RDX     Stack top
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateUserStack   Proc near
    push rax
    push rbx
    push rcx
    push rdi
    push r12
;
    mov r12,rcx
    dec r12
    mov rcx, long_stack_size SHR 30
    mov rdi,PTR_TABLE_LINEAR + long_stack_linear SHR 27

ausLoop:
    mov rax,[rdi]
    test al,1
    jz ausOk
;
    add rdi,8
    loop ausLoop
;
    stc
    jmp ausDone

ausOk:        
    push rdi
    AllocatePhysical64
    pop rdi
;    
    shr rbx,32
    or rax,rbx
    or al,7
    mov [rdi],rax
;
    sub rdi,PTR_TABLE_LINEAR
    shl rdi,9
    add rdi,DIR_TABLE_LINEAR
;
    xor rax,rax
    mov rcx,512
    rep stosq
;
    sub rdi,400h
    push rdi
;
    mov rcx,r12
    shr rcx,21
    inc rcx
    sub rdi,8

ausDirLoop:
    push rcx
    push rdi
    AllocatePhysical64
    pop rdi
    pop rcx
;    
    shr rbx,32
    or rax,rbx
    or al,7
    mov [rdi],rax
;
    sub rdi,8
    loop ausDirLoop    
;
    pop rdi
;
    mov rcx,r12
    shr rcx,21
    inc rcx
;    
    sub rdi,DIR_TABLE_LINEAR
    shl rdi,9
    mov rax,PAGE_TABLE_LINEAR
    add rdi,rax
;
    shl rcx,9
    mov rax,rcx
    shl rax,3
    sub rdi,rax
;
    shr r12,12
    inc r12
    sub rcx,r12
    xor rax,rax
    rep stosq    
;    
    mov rcx,r12
    mov rax,2
    rep stosq
;
    mov rdx,rdi
    mov rax,PAGE_TABLE_LINEAR
    sub rdx,rax
    shl rdx,9
    clc
    
ausDone:
    pop r12
    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret
AllocateUserStack   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           MarkValid
;
;   DESCRIPTION:    Mark area as valid
;
;   PARAMETERS:     RCX     Size
;                   RDX     Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MarkValid   Proc near
    push rax
    push rcx
    push rdx
    push rdi
;
    mov rdi,rdx
    and rdi,0FFFFFFFFFFFFF000h
;
    and rdx,0FFFh
    add rcx,rdx
    dec rcx
    shr rcx,12
    inc rcx
;
    shr rdi,9
    mov rax,PAGE_TABLE_LINEAR
    add rdi,rax
;
    mov rax,2
    rep stosq                
;
    pop rdi
    pop rdx
    pop rcx
    pop rax    
    ret
MarkValid   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           LoadCode
;
;   DESCRIPTION:    Load code
;
;   PARAMETERS:     RSI     Fault RIP
;
;   RETURNS:        RAX     Physical page to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadCode    Proc near
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
;    
    mov r8,long_process_linear
    mov rdi,[r8].elf_phoff
    movzx rcx,[r8].elf_phnum

load_code_sect_loop:
    mov rdx,[rdi].elfp_vaddr
    cmp rsi,rdx
    jc load_code_sect_next
;
    add rdx,[rdi].elfp_memsz
    cmp rsi,rdx
    jc load_code_sect_do

load_code_sect_next:
    movzx rax,[r8].elf_phentsize
    add rdi,rax
    loop load_code_sect_loop
;
    stc
    jmp load_code_done

load_code_sect_do:
    mov rax,[rdi].elfp_vaddr
    mov rdx,rsi
    sub rdx,rax
    and rdx,0FFFFFFFFFFFFF000h
    mov rcx,[rdi].elfp_filez
    sub rcx,rdx    
    jbe load_code_loaded
;
    cmp rcx,1000h
    jb load_code_size_ok
;
    mov rcx,1000h

load_code_size_ok:        
    mov eax,[rdi].elfp_flags
    push rax
    push [rdi].elfp_memsz
    add rdx,[rdi].elfp_offset
    HandleLongCodeFault
    pop rcx
;
    sub rcx,rax
    mov rdi,rdx
    add rdi,rax
    xor rax,rax
    push rcx
    and rcx,7
    rep stosb
    pop rcx
    shr rcx,3
    rep stosq
;    
    mov rsi,PAGE_TABLE_LINEAR
    mov rax,rdx
    shr rax,9
    add rsi,rax
    xor rax,rax
    xchg rax,[rsi]
    pop rbx
    test bl,2
    jnz load_code_loaded
;
    and rax,NOT 2
                    
load_code_loaded:
    clc

load_code_done:
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
LoadCode    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           InitTls
;
;   DESCRIPTION:    Init TLS
;
;   PARAMETERS:     RDX     Stack base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTls    Proc near
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
;
    mov rsi,long_process_linear
    mov rsi,[rsi].elf_shoff
    mov ecx,[rsi].elft_vsize
    dec ecx
    and cx,0F00h
    add ecx,1000h
    add rdx,8000000h
;    
    push rdx
    sub rdx,rcx
    add ecx, 80000h
    call MarkValid
    pop rdx
;
    mov rdi,rdx
    mov ecx,[rsi].elft_vsize
    sub rdi,rcx
    mov esi,[rsi].elft_data
    rep movs byte ptr [rdi],[rsi]
;
    mov [rdx],rdx
    mov rax,rdx
    shr rdx,32
    SetLongTlsLinear
;    
    xor ax,ax
    mov gs,ax
;    
    mov ax,1
    WaitMilliSec
;    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
InitTls Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           start64
;
;   DESCRIPTION:    Start 64-bit app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start64:
    mov rsi,long_process_linear
    mov rdi,[rsi].elf_phoff
    movzx rcx,[rsi].elf_phnum

alloc_sect_loop:
    push rcx
    mov rdx,[rdi].elfp_vaddr
    mov rcx,[rdi].elfp_memsz
    call MarkValid
    pop rcx
;
    movzx rax,[esi].elf_phentsize
    add rdi,rax
    loop alloc_sect_loop
;
    mov rcx,10000h
    call AllocateUserStack
;    
    mov rax,rdx
    shr rax,30
    SetFutexId
;
    call InitTls
    mov rax,rdx
;
    push rcx
    push rdx
    mov rdx,long_section_linear
    mov rcx,long_section_size
    call MarkValid
    pop rdx
    pop rcx
;
    push rsi
    push rdi
;    
    mov rsi,long_section_linear
    shr rsi,18
    add rsi,DIR_TABLE_LINEAR
;    
    mov rdi,long_section_alias
    shr rdi,18
    add rdi,DIR_TABLE_LINEAR
;
    movsq
    pop rdi
    pop rsi
;
    mov rax,long_kernel_data_sel
    mov ss,ax
;
    mov rax,long_user_data_sel
    push rax
    push rdx
    pushfq
;
    mov rax,long_user_code_sel
    push rax
    mov rax,[rsi].elf_entry
    push rax
    iretq
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           LongThreadStart
;
;   DESCRIPTION:    Startup procedure for long mode thread
;
;   PARAMETERS:     EDX     Block buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

long_thread_start:
    int 3
    mov ax,flat_sel
    mov gs,ax
;    
    mov rdi,rdx
    mov rcx,[rdi].lti_stack_size
    call AllocateUserStack
;    
    mov rax,rdx
    shr rax,30
    SetFutexId
;
    call InitTls
    int 3
;
    mov rax,long_kernel_data_sel
    mov ss,ax
;
    mov rax,long_user_data_sel
    push rax
    push rdx
    pushfq
;
    mov rax,long_user_code_sel
    push rax
    mov rax,[rdi].lti_start
    push rax
;
    mov rsi,[rdi].lti_param
    mov ecx,SIZE long_thread_info_struc
    mov edx,edi
    FreeLongBuf
    mov rdx,rsi        
    iretq    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           LDT locks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockLdt    Macro
    local eldtLoop
    local eldtLocked
    
    mov r9,OFFSET long_ldt_spinlock

eldtLoop:
    mov r8,1
    xchg r8,[r9]
    or r8,r8
    jz eldtLocked
;
    pause
    jmp eldtLoop

eldtLocked:     
            Endm

UnlockLdt    Macro
    mov r9,OFFSET long_ldt_spinlock
    xor r8,r8
    mov [r9],r8
        Endm
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateLongLdt
;
;   DESCRIPTION:    Allocate a new ldt-selector and assign it base & size
;
;   PARAMETERS:     EDX     Base
;                   ECX     Size
;
;   RETURNS:        BX      Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateLongLdt Proc near
    LockLdt
;
    mov r8,long_ldt_linear
    mov rbx,[r8]
    mov r9,[r8+rbx]
    mov [r8],r9
;
    UnlockLdt
;
    dec ecx
    mov r8,long_ldt_linear
    cmp ecx,100000h
    jae ldtBig

ldtSmall:
    mov [r8+rbx],cx
    mov [r8+rbx+2],edx
    mov al,92h
    xchg al,[r8+rbx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [r8+rbx+6],cx
    jmp ldtDone

ldtBig:
    shr ecx,12
    mov [r8+rbx],cx
    mov [r8+rbx+2],edx
    mov al,92h
    xchg al,[r8+rbx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [r8+rbx+6],cx

ldtDone:        
    add rbx,4
    ret
AllocateLongLdt Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeLongLdt
;
;   DESCRIPTION:    Free ldt-selector and return its base & size
;
;   PARAMETERS:     BX      Selector
;
;   RETURNS:        EDX     Base
;                   ECX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeLongLdt Proc near
    mov r8,long_ldt_linear
    and rbx,0FFF8h
    add rbx,r8
;    
    xor ecx,ecx
    mov cl,[rbx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[rbx]
    test byte ptr [rbx+6],80h
    jz fllSmall
;
    shl ecx,12
    or cx,0FFFh

fllSmall:
    inc ecx
;    
    mov edx,[rbx+2]
    rol edx,8
    mov dl,[rbx+7]
    ror edx,8
;
    LockLdt
;
    mov r8,long_ldt_linear
    mov r9,[r8]
    mov [rbx],r9
    sub rbx,r8
    mov [r8],rbx
;
    UnlockLdt
    ret
FreeLongLdt Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeLdtSel
;
;   DESCRIPTION:    Free possible ldt selector
;
;   PARAMETERS:     BX      Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeLdtSel  Proc near
    test bx,4
    jz flsDone
;
    push rax
    push rcx
    push rdx
    push rdi
;
    call FreeLongLdt
;
    dec rcx
    shr rcx,12
    inc rcx
    mov rax,PAGE_TABLE_LINEAR
    shr rdx,9
    and rdx,0FFFFFFFFFFFFFFF8h
    add rdx,rax
    mov rdi,rdx
    xor rax,rax
    rep stosq    
;    
    pop rdi
    pop rdx
    pop rcx    
    pop rax

flsDone:    
    ret
FreeLdtSel  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Buffer locks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockBuf    Macro
    LOCAL lock_done

    push rsi
    mov rsi,long_alloc_section
    lock sub [rsi].cs_value,1
    jc lock_done
;    
    OsGate64 enter_section_nr

lock_done:
    pop rsi
            Endm

UnlockBuf    Macro
    local unlock_done
    
    push rsi
    mov rsi,long_alloc_section
    lock add [rsi].cs_value,1
    jc unlock_done
;    
    OsGate64 leave_section_nr

unlock_done:
    pop rsi
        Endm
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ValidateWriteBuf
;
;   DESCRIPTION:    Validate buffer for read/write
;
;   PARAMETERS:     RSI     Page table buffer
;                   RCX     Number of pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ValidateWriteBuf Proc near
    push rcx
    push rsi
;    
    or rcx,rcx
    jz vwbFail

vwbLoop:
    lodsq
    test al,1
    jnz vwbPresent
;
    cmp rax,2
    jne vwbFail
;   
    mov r8,rsi
    sub r8,8
    mov rax,PAGE_TABLE_LINEAR
    sub r8,rax
    shl r8,9
    mov rax,[r8]
    mov rax,[rsi-8]

vwbPresent:
    test al,2
    jz vwbFail
;
    loop vwbLoop
;
    clc
    jmp vwbDone
    
vwbFail:
    stc

vwbDone:    
    pop rsi
    pop rcx            
    ret
ValidateWriteBuf Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ValidateReadBuf
;
;   DESCRIPTION:    Validate buffer for read-only
;
;   PARAMETERS:     RSI     Page table buffer
;                   RCX     Number of pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ValidateReadBuf Proc near
    push rcx
    push rsi
;    
    or rcx,rcx
    jz vrbFail

vrbLoop:
    lodsq
    test al,1
    jnz vrbPresent
;
    cmp rax,2
    jne vrbFail
;   
    mov r8,rsi
    sub r8,8
    mov rax,PAGE_TABLE_LINEAR
    sub r8,rax
    shl r8,9
    mov rax,[r8]

vrbPresent:
    loop vrbLoop
;
    clc
    jmp vrbDone
    
vrbFail:
    stc

vrbDone:    
    pop rsi
    pop rcx            
    ret
ValidateReadBuf Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBuf
;
;   DESCRIPTION:    Allocate buffer below 4G
;
;   PARAMETERS:     RCX     Number of pages
;
;   RETURNS:        RDX     Pointer into page-table     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBuf Proc near
    push rax
    push rcx
    push rsi
    push rdi
;
    LockBuf
;
    mov rdi,long_alloc_base
    mov rdi,[rdi]

abRetry:    
    mov rsi,rdi
            
abLoop:
    mov rax,[rdi]
    or rax,rax
    jnz abRestart
;
    mov rax,2
    stosq
    loop abLoop    
;
    mov rax,long_alloc_base
    mov [rax],rdi
;
    mov rdx,rsi
    clc
    jmp abDone

abRestart:
    cmp rdi,rsi
    je abNext
;
    xor rax,rax
    mov [rdi],rax
    sub rdi,8
    sub rsi,8
    inc rcx
    jmp abRestart

abNext:
    mov rax,rcx
    shl rax,3
    add rdi,rax
;
    cmp edi,80000000h SHR 9
    jb abRetry
;
    mov rdi,long_buf_linear SHR 9 + PAGE_TABLE_LINEAR
    jmp abRetry

abDone:    
    UnlockBuf
;    
    pop rdi
    pop rsi
    pop rcx            
    pop rax
    ret
AllocateBuf Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeBuf
;
;   DESCRIPTION:    Free buffer below 4G
;
;   PARAMETERS:     RCX     Number of pages
;                   RDX     Pointer into page table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBuf Proc near
    push rax
    push rcx
    push rdi
;
    mov rdi,rdx
    xor rax,rax
    rep stosq
;    
    pop rdi
    pop rcx
    pop rax            
    ret
FreeBuf Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CopyBuf
;
;   DESCRIPTION:    Copy buffer below 4G
;
;   PARAMETERS:     RSI     Page table buffer
;                   RCX     Number of pages
;
;   RETURNS:        EDX     New buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyBuf Proc near
    push rcx
    push rsi
    push rdi
;
    LockBuf
;
    mov rdi,long_alloc_base
    mov rdi,[rdi]

cbRetry:    
    mov r8,rdi
            
cbLoop:
    mov rax,[rdi]
    or rax,rax
    jnz cbRestart
;
    movsq
    loop cbLoop    
;
    mov rax,long_alloc_base
    mov [rax],rdi
;
    mov rdx,r8
    jmp cbDone

cbRestart:
    cmp rdi,r8
    je cbNext
;
    xor rax,rax
    mov [rdi],rax
    sub rdi,8
    sub rsi,8
    inc rcx
    jmp cbRestart

cbNext:
    mov rax,rcx
    shl rax,3
    add rdi,rax
;
    cmp edi,80000000h SHR 9
    jb cbRetry
;
    mov rdi,long_buf_linear SHR 9 + PAGE_TABLE_LINEAR
    jmp cbRetry

cbDone:    
    UnlockBuf
;    
    pop rdi
    pop rsi
    pop rcx            
    ret
CopyBuf Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Cleanup
;
;   DESCRIPTION:    Cleanup after syscall
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Cleanup Proc near
    push rax
    push rbx
;
    mov rbx,ds
    or rbx,rbx
    jz cDsOk
;
    xor rax,rax
    mov ds,rax
    call FreeLdtSel

cDsOk:
    mov rbx,es
    or rbx,rbx
    jz cEsOk
;
    xor rax,rax
    mov es,rax
    call FreeLdtSel
                    
cEsOk:    
    pop rbx
    pop rax
    ret
Cleanup Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           SetupRdEsEdi
;
;   DESCRIPTION:    Setup read-only to es:edi
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_rd_es_edi    Proc near
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
;
    mov rax,rdi
    shr rax,39
    or ax,ax
    stc
    jz setup_rd_es_edi_done
;
    cmp rax,7FFh
    cmc
    jc setup_rd_es_edi_done
;    
    mov rcx,rdi
    mov rsi,rdi
    and rsi,0FFFFFFFFFFFFF000h
    add rcx,r12
    sub rcx,rsi
    dec rcx
    shr rcx,12
    inc rcx
; 
    mov rax,PAGE_TABLE_LINEAR
    shr rsi,9
    add rsi,rax
;    
    call ValidateReadBuf
    jc setup_rd_es_edi_done
;
    call CopyBuf    
    mov rax,PAGE_TABLE_LINEAR
    sub rdx,rax
    shl rdx,9
;   
    and rdi,0FFFh
    add rdx,rdi
    mov rcx,r12
    call AllocateLongLdt
    mov es,rbx
    xor rdi,rdi
    clc

setup_rd_es_edi_done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
setup_rd_es_edi    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           SetupWrEsEdi
;
;   DESCRIPTION:    Setup read/write to es:edi
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_wr_es_edi    Proc near
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
;
    mov rax,rdi
    shr rax,39
    or ax,ax
    stc
    jz setup_wr_es_edi_done
;
    cmp rax,7FFh
    cmc
    jc setup_wr_es_edi_done
;    
    mov rcx,rdi
    mov rsi,rdi
    and rsi,0FFFFFFFFFFFFF000h
    add rcx,r12
    sub rcx,rsi
    dec rcx
    shr rcx,12
    inc rcx
; 
    mov rax,PAGE_TABLE_LINEAR
    shr rsi,9
    add rsi,rax
;    
    call ValidateWriteBuf
    jc setup_wr_es_edi_done
;
    call CopyBuf    
    mov rax,PAGE_TABLE_LINEAR
    sub rdx,rax
    shl rdx,9
;   
    and rdi,0FFFh
    add rdx,rdi
    mov rcx,r12
    call AllocateLongLdt
    mov es,rbx
    xor rdi,rdi
    clc

setup_wr_es_edi_done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
setup_wr_es_edi    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           SetupParam
;
;   DESCRIPTION:    Setup parameter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_param_tab:
spt00 DQ OFFSET setup_rd_es_edi
spt01 DQ OFFSET setup_wr_es_edi
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           syscall entry point (template only)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

syscall_start:
    mov r9,123456789ABCh        ; patch to address of processor block
    mov r10d,[r9].cs_syscall_esp
    xchg rsp,r10
    push r10
    mov r10,qword ptr [r9].cs_tls_linear
    push rcx
    push r11
    popfq
    mov rcx,r8
    push rbp
;
    mov r9,usergate_linear
    shl r14,USER_GATE_SHIFT
    add r14,r9
    test [r14].user_gate_syscall_flags,UG_SYSCALL_FLAG_HAS_PAR0
    jz syscall_do
;  
    cmp r12,20000000h
    ja syscall_cleanup_fail
;
    mov r8,OFFSET setup_param_tab
    xor r9,r9
    mov r9b,[r14].user_gate_syscall_par
    shl r9,3
    call near ptr [r8+r9]
    jc syscall_cleanup
;    
    call fword ptr [r14]
    jnc syscall_cleanup_ok

syscall_cleanup_fail:
    or r11,1
    jmp syscall_cleanup

syscall_cleanup_ok:
    and r11,NOT 1

syscall_cleanup:    
    mov r8,OFFSET Cleanup
    call r8
    jmp syscall_done

syscall_do:
    call fword ptr [r14]
    jc syscall_fail

syscall_ok:
    and r11,NOT 1 
    jmp syscall_done   
       
syscall_fail:
    or r11,1

syscall_done:       
    pop rbp
    mov r8,rcx
;    
    push rax
    push rdx
    mov rax,r10
    mov rdx,r10
    shr rdx,32
    mov ecx,0C0000101h
    wrmsr
    pop rdx
    pop rax
;
    pop rcx
    cli
    pop rsp
;    
    db 48h
    sysret        

syscall_end:

local_st_space  DQ 512 DUP(?)
local_stack     DQ ?     
    
text_end:

Code64  Ends

    end
