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

.x64

Code64 segment byte public use64 'code64'

param_struc     STRUC

lfb_base        DQ ?
uefi_data       DQ ?

param_struc     ENDS

    org 0110000h

    jmp init

param   param_struc <>

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

prot_ptr:
    dd OFFSET prot_init
    dw 18h

init:
    cli
    lgdt tbyte ptr gdt_ptr
    mov eax,OFFSET prot_ptr
    call fword ptr [rax]

prot_init:

    
Code64  Ends

    end
