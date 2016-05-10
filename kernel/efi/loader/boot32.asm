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
; boot32.asm
; 32-bit RDOS boot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


param_struc     STRUC

lfb_base        DD ?,?
lfb_width       DD ?
lfb_height      DD ?
lfb_line_size   DD ?
lfb_flags       DD ?
mem_entries     DD ?

param_struc     ENDS

IMAGE_BASE = 110000h


_TEXT segment byte public use16 'CODE'

    .386p

    db 0EBh            ; jmp init32
    db 2Eh + SIZE param_struc

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

init32:
    db 0FAh    ; cli
    db 0BBh    ; mov ebx,OFFSET gdt_ptr
    dd OFFSET gdt_ptr + IMAGE_BASE
;
    db 2Eh     ; lgdt fword ptr cs:[ebx]
    db 0Fh
    db 01h
    db 13h
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
;
    mov ax,8
    mov ds,ax
    mov eax,cs:param.lfb_line_size
    jmp start
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetLfb
;
;   DESCRIPTION:    Get LFB base
;
;   RETURNS:        EDI         LFB linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetLfb

GetLfb  Proc near
    mov edi,cs:param.lfb_base
    ret
GetLfb  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetLfbPos
;
;   DESCRIPTION:    Get LFB position
;
;   PARAMETERS:     EAX         X
;                   EDX         Y
;
;   RETURNS:        EDI         LFB linear
;                   ECX         Line size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetLfbPos

GetLfbPos  Proc near
    push eax
    push edx
;    
    push eax
    mov eax,cs:param.lfb_line_size
    mul edx
    mov edi,cs:param.lfb_base
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
    mov ecx,cs:param.lfb_line_size
;
    pop edx
    pop eax    
    ret
GetLfbPos  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetMemCount
;
;   DESCRIPTION:    Get memory block count
;
;   RETURNS:        ECX         Memory block count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetMemCount

GetMemCount  Proc near
    mov ecx,cs:param.mem_entries
    ret
GetMemCount  Endp

    extern start:near

_TEXT  Ends

    end
