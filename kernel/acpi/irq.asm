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
; irq.asm
; Irq module
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
;       NAME:           AllocateInts
;
;       DESCRIPTION:    Allocate interrupts
;
;       PARAMETERS:     CX      Number of ints (1,2,4,8,16 or 32)
;                       AL      Priority (0..31)
;
;       RETURNS:        AL      Base int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_ints_name    DB 'Allocate Ints',0

allocate_ints  Proc far
    push ds
    push ecx
    push edx
    push esi
;    
    mov edx,irq_data_sel
    mov ds,edx
;    
    and al,1Fh
    movzx esi,al
    shl al,3
;
    movzx ecx,cx
    cmp ecx,32
    ja aiFailed
;
    cmp ecx,16
    jbe aiNot32

ai32:
    test al,1Fh
    jnz aiFailed

ai32Loop:
    mov edx,ds:[esi]
    or edx,edx
    jz ai32Ok
;
    add al,32
    jc aiFailed
;
    add esi,4
    jmp ai32Loop
    
ai32Ok:
    mov edx,-1
    mov ds:[esi],edx    
    jmp aiOk

aiNot32:    
    cmp ecx,8
    jbe aiNot16

ai16:
    test al,0Fh
    jnz aiFailed

ai16Loop:
    mov dx,ds:[esi]
    or dx,dx
    jz ai16Ok
;
    add al,16
    jc aiFailed
;
    add esi,2
    jmp ai16Loop
    
ai16Ok:
    mov dx,-1
    mov ds:[esi],dx    
    jmp aiOk

aiNot16:
    cmp ecx,4
    jbe aiNot8

ai8:

ai8Loop:
    mov dl,ds:[esi]
    or dl,dl
    jz ai8Ok
;
    add al,8
    jc aiFailed
;
    inc esi
    jmp ai8Loop
    
ai8Ok:
    mov dl,-1
    mov ds:[esi],dl
    jmp aiOk
        
aiNot8:
    cmp ecx,2
    jbe aiNot4

ai4:

ai4Loop:
    mov dl,ds:[esi]
    mov dh,0Fh
    test dl,dh
    jz ai4Ok
;
    add al,4
    shl dh,4
    test dl,dh
    jz ai4Ok
;    
    add al,4
    jc aiFailed
;
    inc esi
    jmp ai4Loop

ai4Ok:
    or ds:[esi],dh
    jmp aiOk
        
aiNot4:
    cmp ecx,1
    jbe ai1

ai2:

ai2Loop:
    mov ecx,4
    mov dl,ds:[esi]
    mov dh,3

ai2BitLoop:    
    test dl,dh
    jz ai2Ok
;
    add al,2
    jc aiFailed
;
    shl dh,2
    loop ai2BitLoop
;
    inc esi
    jmp ai2Loop

ai2Ok:
    or ds:[esi],dh
    jmp aiOk

ai1:

ai1Loop:
    mov ecx,8
    mov dl,ds:[esi]
    mov dh,1

ai1BitLoop:    
    test dl,dh
    jz ai1Ok
;
    add al,1
    jc aiFailed
;
    shl dh,1
    loop ai1BitLoop
;
    inc esi
    jmp ai1Loop

ai1Ok:
    or ds:[esi],dh

aiOk:
    clc
    jmp aiDone

aiFailed:
    stc

aiDone:    
    pop esi
    pop edx
    pop ecx
    pop ds    
    ret
allocate_ints  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeInt
;
;       DESCRIPTION:    Free a single int vector
;
;       PARAMETERS:     AL      Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_int_name    DB 'Free Int',0

free_int  Proc far
    push ds
    push eax
    push esi
;    
    mov esi,irq_data_sel
    mov ds,esi
;
    movzx eax,al
    xor esi,esi
    btr ds:[esi],eax
;
    pop esi
    pop eax
    pop ds
    ret
free_int    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           Init_irq
;
;               DESCRIPTION:    Init irq module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_irq
        
init_irq    PROC near
    push ds
    push es
    pushad
;    
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET allocate_ints
    mov edi,OFFSET allocate_ints_name
    xor cl,cl
    mov ax,allocate_ints_nr
    RegisterOsGate
;
    mov esi,OFFSET free_int
    mov edi,OFFSET free_int_name
    xor cl,cl
    mov ax,free_int_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
init_irq    ENDP

code    ENDS

    END
    
