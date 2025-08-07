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
;       NAME:           RequestMsiHandler
;
;       DESCRIPTION:    Request an MSI-based interrupt-handler
;
;       PARAMETERS:     DS      Data passed to handler
;                       ES:EDI  Handler address
;                       AL      Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RequestMsiHandler

RequestMsiHandler  Proc near
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
RequestMsiHandler  Endp

code    ENDS

    END
    
