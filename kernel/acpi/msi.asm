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
; msi.asm
; MSI module
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

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use32 'CODE'

    assume cs:code
    
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
    mov eax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax    
    LeaveInt
;
    pop eax
    verr ax
    jz MsiExitFs
;    
    xor eax,eax

MsiExitFs:
    mov fs,eax
;
    pop eax
    verr ax
    jz MsiExitEs
;    
    xor eax,eax

MsiExitEs:
    mov es,eax
;
    pop eax
    verr ax
    jz MsiExitDs
;    
    xor eax,eax

MsiExitDs:
    mov ds,eax
;
    popad
    iretd
    
MsiDefault:
    retf

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
    CreateCodeSelector32
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
    push eax
    push edx
;
    mov fs,ebx
    mov edx,fs:msi_linear
    mov eax,flat_sel
    mov fs,eax
;
    mov fs:[edx].msi_handler_data,ds
    mov fs:[edx].msi_handler_ads,edi
    mov word ptr fs:[edx].msi_handler_ads+4,es
;
    pop edx
    pop eax
    pop fs    
    ret
SetupMsiHandler   Endp
   
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
    ret
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
    push ebx
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
    push eax
    mov ax,create_long_msi_nr
    IsValidOsGate
    pop eax
    jc rmhDone
;
    CreateLongMsi
;
    push ebx
    xor bl,bl
    SetupLongIntGate
    pop ebx
;    
    AddLongMsi

rmhDone:
    pop esi
    pop ebx
    ret
request_msi_handler  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Init
;
;               DESCRIPTION:    Init apic mp module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_msi
        
init_msi    PROC near
    push ds
    push es
    pushad
;    
    mov eax,cs
    mov ds,eax
    mov es,eax
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
    popad
    pop es
    pop ds
    ret
init_msi    ENDP

code    ENDS

    END
    
