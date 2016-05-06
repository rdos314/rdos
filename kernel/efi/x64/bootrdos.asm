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
; bootrdos.ASM
; 64-bit RDOS boot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.686p

Code32 segment byte public use32 'code32'


    org 0110000h

;
; 64 bit code (not assembled here)
;

    db 0Ebh
    db 42h

lfb_base        DQ ?
uefi_data       DQ ?

rom_gdt:
gdt0:
    dw 0
    dd 0
    dw 0
gdt8:
    dw 10h*8-1
    dd 92000000h
    dw 0
gdt10:
    dw 28h-1
    dd 92000000h + OFFSET rom_gdt
    dw 0
gdt18:
    dw 0FFFFh
    dd 9A000000h
    dw 0CFh
gdt20:
    dw 0FFFFh
    dd 92000000h
    dw 8Fh

gdt_ptr:
    dw 28h-1
    dq OFFSET rom_gdt

init64:
    db 0FAh
    db 2Eh
    db 0Fh
    db 01h
    db 15h
    dd 0FFFFFFEDh
;
    db 0EAh
    dd OFFSET prot_init
    dw 18h

prot_init:
    mov eax,20h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov esp,120000h
    
Code32  Ends

    end
