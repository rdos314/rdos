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
; boot64.asm
; 64-bit RDOS boot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


param_struc     STRUC

lfb_base        DD ?,?
lfb_width       DD ?
lfb_height      DD ?
lfb_line_size   DD ?
lfb_flags       DD ?
mem_entries     DD ?
acpi_table      DD ?,?

param_struc     ENDS

IMAGE_BASE = 110000h


_TEXT segment byte public use16 'CODE'

    .386p

    db 0Ebh            ; jmp init64
    db 38h + SIZE param_struc

param   param_struc <>

rom_gdt:
gdt0:
    dw 0
    dd 0
    dw 0
gdt8:
    dw 0
    dd 0
    dw 0
gdt10:
    dw 28h-1
    dd 92000000h + OFFSET rom_gdt + IMAGE_BASE
    dw 0
gdt18:
    dw 0FFFFh
    dd 9A000000h
    dw 0CFh
gdt20:
    dw 0FFFFh
    dd 92000000h
    dw 08Fh

gdt_ptr:
    dw 28h-1
    dd OFFSET rom_gdt + IMAGE_BASE
    dd 0

prot_ptr:
    dd OFFSET prot_init + IMAGE_BASE
    dw 18h

init64:
    db 0FAh    ; cli
    db 0Fh     ; lgdt gdt_ptr
    db 01h
    db 15h
    dd 0FFFFFFE8h
;
    db 0FFh
    db 1Dh
    dd 0FFFFFFECh

prot_init:
    db 0Fh     ; mov eax,cr0
    db 20h
    db 0C0h
;
    db 25h     ; and eax,7FFFFFFFh
    dd 07FFFFFFFh
;
    db 0Fh     ; mov cr0,eax
    db 22h
    db 0C0h
;
    db 0B9h    ; mov ecx,IA32_EFER
    dd 0C0000080h
;
    db 0Fh     ; rdmsr
    db 32h
;
    db 25h     ; and eax,0FFFFFEFFh
    dd 0FFFFFEFFh
;
    db 0Fh     ; wrmsr
    db 30h
;
    db 0Fh     ; mov rax,cr4
    db 20h
    db 0E0h
;
    db 83h     ; and eax,NOT 20h
    db 0E0h
    db 0DFh
;
    db 0Fh     ; mov cr4,rax
    db 22h
    db 0E0h
;
    db 0B8h    ; mov eax,20h
    dd 20h
;
    db 8Eh     ; mov ds,eax
    db 0D8h
;
    db 0BBh    ; mov ebx,OFFSET gdt18
    dd OFFSET gdt18 + IMAGE_BASE
;
    db 0BAh    ; mov edx,IMAGE_BASE
    dd IMAGE_BASE
;
    db 89h     ; mov [ebx+2],edx
    db 53h
    db 02h
;
    db 0B0h    ; mov al,9Ah
    db 9Ah
;
    db 86h     ; xchg al,[ebx+5]
    db 43h
    db 5
;
    db 32h     ; xor cl,cl
    db 0C9h
;
    db 8Ah     ; mov ch,al
    db 0E8h
;
    db 66h     ; mov [ebx+6],cx
    db 89h
    db 4Bh
    db 6
;
    db 0EAh    ; jmp 18:init
    dd OFFSET init
    dw 18h

init:
    mov ax,20h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
;
    mov ebx,OFFSET gdt8 + IMAGE_BASE
    mov edx,IMAGE_BASE
    mov cx,-1
    mov [ebx],cx
    mov [ebx+2],edx
    mov al,92h
    xchg al,[ebx+5]
    xor cl,cl
    mov ch,al
    mov [ebx+6],cx
    mov ecx,cs:param.mem_entries
    jmp start
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetLfb
;
;   DESCRIPTION:    Get LFB base
;
;   RETURNS:        EDI:ESI     LFB linear
;                   ECX         Line size
;                   EAX         Width
;                   EDX         Height
;                   EBX         Flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetLfb

GetLfb  Proc near
    mov esi,cs:param.lfb_base
    mov edi,cs:param.lfb_base+4
    mov ecx,cs:param.lfb_line_size
    mov eax,cs:param.lfb_width
    mov edx,cs:param.lfb_height
    mov ebx,cs:param.lfb_flags
    ret
GetLfb  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetMemCount
;
;   DESCRIPTION:    Get memory block count
;
;   RETURNS:        ECX		Memory block count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetMemCount

GetMemCount  Proc near
    mov ecx,cs:param.mem_entries
    ret
GetMemCount  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetAcpiTablePtr
;
;   DESCRIPTION:    Get ACPI table
;
;   RETURNS:        EDX:EAX		ACPI table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetAcpiTablePtr

GetAcpiTablePtr  Proc near
    mov edx,cs:param.acpi_table+4
    mov eax,cs:param.acpi_table
    ret
GetAcpiTablePtr  Endp

    extern start:near

_TEXT  Ends

    end
