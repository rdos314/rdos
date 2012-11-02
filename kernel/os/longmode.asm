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
; LONGMODE.ASM
; Long mode device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


include ..\driver.def
include ..\os.def
include ..\user.def
include ..\os.inc
include ..\user.inc
include protseg.def
include gate.def

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

MAP_LINEAR      = 110000h

IDT_LINEAR      = 11C000h
PAE_CR3_LINEAR  = 11D000h
IA64_PAE_LINEAR = 11E000h
IA64_CR3_LINEAR = 11F000h

UNITY_MAP_SIZE  = 10000h

pushq0  Macro
    db 6Ah
    db 0
        Endm

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
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;   32-bit device driver header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.686p

Code32 segment byte public use32 'code32'

sign dw 6452h
eip  dd OFFSET init
ib   dd MAP_LINEAR
ic   dd UNITY_MAP_SIZE
idt  dd IDT_LINEAR

    org MAP_LINEAR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupLongTrapGate
;
;   DESCRIPTION:    Setup long-mode trap gate
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      Dpl
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
    add edi,IDT_LINEAR
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
    add edi,IDT_LINEAR
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
;   NAME:           InitIdt
;
;   DESCRIPTION:    Init 64-bit IDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pretask_int_tab:
;
;               int #   Entry
;
pg0     DD      0,          OFFSET pretask0,        0
pg1     DD      1,          OFFSET pretask1,        0
pg2     DD      2,          OFFSET pretask2,        0
pg3     DD      3,          OFFSET pretask3,        0
pg4     DD      4,          OFFSET pretask4,        0
pg5     DD      5,          OFFSET pretask5,        0
pg6     DD      6,          OFFSET pretask6,        0
pg7     DD      7,          OFFSET pretask7,        0
pg8     DD      8,          OFFSET pretask8,        0
pg9     DD      9,          OFFSET pretask9,        0
pg10    DD      10,         OFFSET pretask10,       0
pg11    DD      11,         OFFSET pretask11,       0
pg12    DD      12,         OFFSET pretask12,       0
pg13    DD      13,         OFFSET pretask13,       0
pg14    DD      14,         OFFSET pretask14,       0
pg16    DD      16,         OFFSET pretask16,       0
rg66    DD      66h,        OFFSET int66,           3
rg67    DD      67h,        OFFSET int67,           3
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
    SetupLongTrapGate
;
    add edi,12
    jmp iiLoop

iiDone:
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
    mov edi,init_task
    HookInitTasking    
;    
    call InitIdt
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
    mov esi,OFFSET test_thread
    mov edi,OFFSET test_thread_name
    mov ax,4
    mov ecx,1000h
    CreateThread
;
    popad
    pop es
    pop ds
    retf
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Test_thread
;
;    DESCRIPTION:    Test thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_thread_name  DB 'Nasm Test Thread', 0

long_idt_size   DW 0FFFh
long_idt_base   DD IDT_LINEAR

test_irq    Proc far
    int 3
    ret
test_irq    Endp

test_thread:
    int 3
    mov al,80h
    CreateLongMsi
;
    xor bl,bl
    SetupLongIntGate
;    
    mov dx,cs
    mov es,dx
    mov dx,apic_data_sel
    mov ds,dx
    mov edi,OFFSET test_irq
    AddLongMsi
;    
    mov bx,ss
    GetSelectorBaseSize
    add edx,esp
    mov ax,syscall_data_sel
    mov ss,ax
    mov esp,edx    
;    
    mov edx,PAE_CR3_LINEAR
    xor ebx,ebx
    mov eax,cr3
    or al,67h
    SetPageEntry
;    
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    mov esi,PAE_CR3_LINEAR
    mov edi,IA64_PAE_LINEAR
    mov ecx,400h
    rep movsd
;
    mov edi,IA64_PAE_LINEAR
    mov al,7
    stosb
;    
    add edi,7    
    stosb
;    
    add edi,7    
    stosb
;    
    add edi,7    
    stosb
;
    mov edi,IA64_CR3_LINEAR
    mov eax,IA64_PAE_LINEAR + 7
    stosd
    xor eax,eax
    mov ecx,3FFh
    rep stosd    
;    
    mov edi,cr3
;
    int 3 
    mov edx,0B8000h
    mov eax,0B8007h
    xor ebx,ebx
    SetPageEntry
;    
    cli
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ecx,IA32_EFER
    rdmsr
    or eax,100h
    wrmsr
;
    mov eax,IA64_CR3_LINEAR
    mov cr3,eax  
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    lidt fword ptr ds:long_idt_size
    db 0EAh
    dd OFFSET test64
    dw long_kernel_code_sel

test32:        
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ecx,IA32_EFER
    rdmsr
    and eax,0FFFFFEFFh   
    wrmsr
;
    mov cr3,edi
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
    sti
    int 3
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  32-bit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

compat_test:
    mov eax,task_data_sel
    mov ds,ax
    int 80h
    int 3
    retf

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

pretask1:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,1
    jmp do_fault

pretask2:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,2
    jmp do_fault

pretask3:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,3
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

pretask6:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,6
    jmp do_fault

pretask7:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,7
    jmp do_fault

pretask8:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,8
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

pretask13:
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
    int 3
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
    pop rdx
    pop rcx
    mov ax,13
    jmp do_fault

pretask14:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
;
    mov rax,cr2
    int 3 
;       
    mov ax,14
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
;    EnterLongInt
;    SendEoi
;    sti
    push rax

MsiPatchLinear:
    mov edi,0
;   
    mov ds,[edi].msi_handler_data
    call fword ptr [edi].msi_handler_ads
;
    pop rax
    cli    
;    LeaveLongInt
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


comp_dest:
    dd OFFSET compat_test
    dw long_dev_code_sel
    
test64:
    db 0FFh
    db 1Ch
    db 25h
    dd OFFSET comp_dest
    int 3

stopl:
    jmp stopl        


text_end:

Code64  Ends

    end
