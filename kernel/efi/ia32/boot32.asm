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
; boot32.asm
; 32-bit RDOS boot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


param_struc     STRUC

lfb_base        DD ?,?
lfb_width       DD ?
lfb_height      DD ?
lfb_line_size   DD 1024
lfb_flags       DD ?

param_struc     ENDS

IMAGE_BASE = 110000h


_TEXT segment byte public use32 'CODE'

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
    cli
    mov ebx,OFFSET gdt_ptr + IMAGE_BASE
    lgdt fword ptr cs:[ebx]
;
    mov eax,20h
    mov ds,eax
    mov ebx,OFFSET gdt18 + IMAGE_BASE
    mov edx,IMAGE_BASE
    mov [ebx+2],edx
    mov al,9Ah
    xchg al,[ebx+5]
    xor cl,cl
    mov ch,al
    mov [ebx+6],cx
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
    mov ss,ax
    mov esp,0FFF0h
    mov eax,cs:param.lfb_line_size
;    jmp start
    
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
;
    pop edx
    pop eax    
    ret
GetLfbPos  Endp

;    extern start:near

_TEXT  Ends

    end
