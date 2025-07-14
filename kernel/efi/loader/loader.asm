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
; loader.asm
; RDOS UEFI loader
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE \rdos\kernel\os.def
INCLUDE \rdos\kernel\os.inc
INCLUDE \rdos\kernel\driver.def
INCLUDE \rdos\kernel\os\port.def
INCLUDE \rdos\kernel\os\system.def
INCLUDE \rdos\kernel\os\system.inc

IMAGE_BASE = 110000h
MEM_BASE = 400h
RDOS_BASE = 121000h

mmap_struc  STRUC

mmap_len    DD ?
mmap_base   DD ?,?
mmap_size   DD ?,?
mmap_type   DD ?

mmap_struc  ENDS


_TEXT segment byte public use16 'CODE'

    extern GetLfb:near
    extern GetMemCount:near
    extern GetAcpiTablePtr:near

    .386p

crc_tab         DW 256 DUP(?)
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Font8x19
;
;   DESCRIPTION:    8x19 font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

font8x19:
f00 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f01 db 000h, 000h, 000h, 07Eh, 081h, 081h, 0A5h, 081h, 081h, 081h, 0BDh, 099h, 081h, 081h, 07Eh, 000h, 000h, 000h, 000h
f02 db 000h, 000h, 000h, 07Eh, 0FFh, 0FFh, 0DBh, 0FFh, 0FFh, 0FFh, 0C3h, 0E7h, 0FFh, 0FFh, 07Eh, 000h, 000h, 000h, 000h
f03 db 000h, 000h, 000h, 000h, 000h, 000h, 06Ch, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h
f04 db 000h, 000h, 000h, 000h, 000h, 000h, 010h, 038h, 07Ch, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h, 000h
f05 db 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 0E7h, 0E7h, 0E7h, 0E7h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f06 db 000h, 000h, 000h, 000h, 018h, 018h, 03Ch, 07Eh, 0FFh, 0FFh, 0FFh, 07Eh, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f07 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f08 db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0E7h, 0C3h, 0C3h, 0C3h, 0E7h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
f09 db 000h, 000h, 000h, 000h, 000h, 000h, 03Ch, 066h, 042h, 042h, 042h, 066h, 03Ch, 000h, 000h, 000h, 000h, 000h, 000h
f0A db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0C3h, 099h, 0BDh, 0BDh, 0BDh, 099h, 0C3h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
f0B db 000h, 000h, 000h, 01Eh, 006h, 00Eh, 01Ah, 030h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 000h, 000h, 000h, 000h
f0C db 000h, 000h, 000h, 03Ch, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 000h, 000h, 000h, 000h
f0D db 000h, 000h, 000h, 03Fh, 033h, 033h, 03Fh, 030h, 030h, 030h, 030h, 030h, 070h, 0F0h, 0E0h, 000h, 000h, 000h, 000h
f0E db 000h, 000h, 000h, 07Fh, 063h, 063h, 07Fh, 063h, 063h, 063h, 063h, 063h, 067h, 0E7h, 0E6h, 0C0h, 000h, 000h, 000h
f0F db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 0DBh, 03Ch, 0E7h, 0E7h, 03Ch, 0DBh, 018h, 018h, 000h, 000h, 000h, 000h
f10 db 000h, 000h, 000h, 080h, 0C0h, 0E0h, 0F0h, 0F8h, 0FEh, 0FEh, 0F8h, 0F0h, 0E0h, 0C0h, 080h, 000h, 000h, 000h, 000h
f11 db 000h, 000h, 000h, 002h, 006h, 00Eh, 01Eh, 03Eh, 0FEh, 0FEh, 03Eh, 01Eh, 00Eh, 006h, 002h, 000h, 000h, 000h, 000h
f12 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h, 000h, 000h, 000h
f13 db 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 066h, 066h, 000h, 000h, 000h, 000h
f14 db 000h, 000h, 000h, 07Fh, 0DBh, 0DBh, 0DBh, 0DBh, 07Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 000h, 000h, 000h, 000h
f15 db 000h, 000h, 000h, 07Ch, 0C6h, 060h, 038h, 06Ch, 0C6h, 0C6h, 06Ch, 038h, 00Ch, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f16 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 0FEh, 000h, 000h, 000h, 000h
f17 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 07Eh, 000h, 000h, 000h
f18 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f19 db 000h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h, 000h, 000h, 000h
f1A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 00Ch, 0FEh, 00Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1B db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 060h, 0FEh, 060h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h
f1D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 024h, 066h, 0FFh, 066h, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1E db 000h, 000h, 000h, 000h, 000h, 010h, 010h, 038h, 038h, 07Ch, 07Ch, 0FEh, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h
f1F db 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 07Ch, 07Ch, 038h, 038h, 010h, 010h, 000h, 000h, 000h, 000h, 000h, 000h
f20 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f21 db 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 03Ch, 018h, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f22 db 000h, 000h, 066h, 066h, 066h, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f23 db 000h, 000h, 000h, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h
f24 db 000h, 018h, 018h, 07Ch, 0C6h, 0C2h, 0C0h, 0C0h, 07Ch, 006h, 006h, 006h, 086h, 0C6h, 07Ch, 018h, 018h, 000h, 000h
f25 db 000h, 000h, 000h, 0C6h, 0C6h, 0CCh, 00Ch, 018h, 018h, 030h, 030h, 060h, 066h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f26 db 000h, 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 076h, 0DCh, 0DCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f27 db 000h, 000h, 018h, 018h, 018h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f28 db 000h, 000h, 000h, 00Ch, 018h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h
f29 db 000h, 000h, 000h, 030h, 018h, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 018h, 030h, 000h, 000h, 000h, 000h
f2A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 03Ch, 0FFh, 03Ch, 066h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2B db 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h
f2C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 030h, 000h, 000h, 000h
f2D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f2F db 000h, 000h, 000h, 006h, 006h, 00Ch, 00Ch, 018h, 018h, 030h, 030h, 060h, 060h, 0C0h, 0C0h, 000h, 000h, 000h, 000h
f30 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0D6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f31 db 000h, 000h, 000h, 018h, 038h, 078h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 000h, 000h, 000h, 000h
f32 db 000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 0C0h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f33 db 000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 006h, 03Ch, 006h, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f34 db 000h, 000h, 000h, 01Ch, 01Ch, 03Ch, 03Ch, 06Ch, 06Ch, 0CCh, 0FEh, 00Ch, 00Ch, 00Ch, 01Eh, 000h, 000h, 000h, 000h
f35 db 000h, 000h, 000h, 0FEh, 0C0h, 0C0h, 0C0h, 0C0h, 0FCh, 006h, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f36 db 000h, 000h, 000h, 038h, 060h, 0C0h, 0C0h, 0C0h, 0FCh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f37 db 000h, 000h, 000h, 0FEh, 0C6h, 006h, 006h, 006h, 00Ch, 018h, 018h, 030h, 030h, 030h, 030h, 000h, 000h, 000h, 000h
f38 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f39 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 006h, 006h, 00Ch, 078h, 000h, 000h, 000h, 000h
f3A db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h
f3B db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 030h, 000h, 000h, 000h, 000h
f3C db 000h, 000h, 000h, 000h, 006h, 00Ch, 018h, 030h, 060h, 060h, 030h, 018h, 00Ch, 006h, 000h, 000h, 000h, 000h, 000h
f3D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f3E db 000h, 000h, 000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 006h, 00Ch, 018h, 030h, 060h, 000h, 000h, 000h, 000h, 000h
f3F db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 006h, 006h, 00Ch, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f40 db 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0DEh, 0DEh, 0DEh, 0DCh, 0C0h, 0C0h, 07Ch, 000h, 000h, 000h, 000h
f41 db 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f42 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 066h, 066h, 066h, 066h, 066h, 0FCh, 000h, 000h, 000h, 000h
f43 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 000h, 000h, 000h, 000h
f44 db 000h, 000h, 000h, 0F8h, 06Ch, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 06Ch, 0F8h, 000h, 000h, 000h, 000h
f45 db 000h, 000h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f46 db 000h, 000h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f47 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0DEh, 0C6h, 0C6h, 0C6h, 066h, 03Ah, 000h, 000h, 000h, 000h
f48 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f49 db 000h, 000h, 000h, 03Ch, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f4A db 000h, 000h, 000h, 00Fh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f4B db 000h, 000h, 000h, 0E6h, 066h, 066h, 06Ch, 06Ch, 078h, 07Ch, 06Ch, 06Ch, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f4C db 000h, 000h, 000h, 0F0h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f4D db 000h, 000h, 000h, 0C6h, 0EEh, 0FEh, 0FEh, 0D6h, 0D6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f4E db 000h, 000h, 000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f4F db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
f50 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f51 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0D6h, 0DEh, 07Ch, 00Ch, 00Eh, 000h, 000h
f52 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 06Ch, 06Ch, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f53 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C0h, 060h, 038h, 00Ch, 006h, 006h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f54 db 000h, 000h, 000h, 07Eh, 07Eh, 05Ah, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f55 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f56 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 010h, 000h, 000h, 000h, 000h
f57 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0FEh, 06Ch, 06Ch, 000h, 000h, 000h, 000h
f58 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 06Ch, 06Ch, 038h, 038h, 06Ch, 06Ch, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f59 db 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f5A db 000h, 000h, 000h, 0FEh, 0C6h, 086h, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 0C2h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f5B db 000h, 000h, 000h, 03Ch, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Ch, 000h, 000h, 000h, 000h
f5C db 000h, 000h, 000h, 0C0h, 0C0h, 060h, 060h, 030h, 030h, 018h, 018h, 00Ch, 00Ch, 006h, 006h, 000h, 000h, 000h, 000h
f5D db 000h, 000h, 000h, 03Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 03Ch, 000h, 000h, 000h, 000h
f5E db 000h, 010h, 038h, 06Ch, 0C6h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f5F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h
f60 db 000h, 000h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f61 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f62 db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 078h, 06Ch, 066h, 066h, 066h, 066h, 066h, 0DCh, 000h, 000h, 000h, 000h
f63 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f64 db 000h, 000h, 000h, 01Ch, 00Ch, 00Ch, 00Ch, 03Ch, 06Ch, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f65 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f66 db 000h, 000h, 000h, 038h, 06Ch, 064h, 060h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f67 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 07Ch, 00Ch, 00Ch, 0CCh, 078h, 000h
f68 db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 06Ch, 076h, 066h, 066h, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f69 db 000h, 000h, 000h, 018h, 018h, 000h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f6A db 000h, 000h, 000h, 006h, 006h, 000h, 000h, 00Eh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 066h, 066h, 03Ch, 000h
f6B db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 066h, 066h, 06Ch, 078h, 078h, 06Ch, 066h, 0E6h, 000h, 000h, 000h, 000h
f6C db 000h, 000h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f6D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 0FEh, 0D6h, 0D6h, 0D6h, 0D6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f6E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h, 000h
f6F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f70 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 0F0h, 000h
f71 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 07Ch, 00Ch, 00Ch, 00Ch, 01Eh, 000h
f72 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 076h, 066h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f73 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 060h, 038h, 00Ch, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f74 db 000h, 000h, 000h, 010h, 030h, 030h, 030h, 0FCh, 030h, 030h, 030h, 030h, 030h, 036h, 01Ch, 000h, 000h, 000h, 000h
f75 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f76 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 000h, 000h, 000h, 000h
f77 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0FEh, 06Ch, 000h, 000h, 000h, 000h
f78 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 06Ch, 038h, 038h, 06Ch, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f79 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Ch, 078h, 000h
f7A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C6h, 00Ch, 018h, 030h, 060h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f7B db 000h, 000h, 000h, 00Eh, 018h, 018h, 018h, 018h, 070h, 070h, 018h, 018h, 018h, 018h, 00Eh, 000h, 000h, 000h, 000h
f7C db 000h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f7D db 000h, 000h, 000h, 070h, 018h, 018h, 018h, 018h, 00Eh, 00Eh, 018h, 018h, 018h, 018h, 070h, 000h, 000h, 000h, 000h
f7E db 000h, 000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f7F db 000h, 000h, 000h, 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 000h, 000h, 000h, 000h, 000h
f80 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 018h, 00Ch, 038h, 000h
f81 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f82 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f83 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f84 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f85 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f86 db 000h, 000h, 000h, 038h, 06Ch, 038h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f87 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 018h, 00Ch, 038h, 000h
f88 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f89 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f8A db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f8B db 000h, 000h, 000h, 000h, 066h, 066h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8C db 000h, 000h, 000h, 018h, 03Ch, 066h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8D db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8E db 0C6h, 0C6h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f8F db 038h, 06Ch, 038h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f90 db 00Ch, 018h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f91 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 036h, 036h, 07Eh, 0D8h, 0D8h, 0D8h, 06Eh, 000h, 000h, 000h, 000h
f92 db 000h, 000h, 000h, 03Eh, 06Ch, 0CCh, 0CCh, 0CCh, 0FEh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CEh, 000h, 000h, 000h, 000h
f93 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f94 db 000h, 000h, 000h, 000h, 0C6h, 0C6h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f95 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f96 db 000h, 000h, 000h, 030h, 078h, 0CCh, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f97 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f98 db 000h, 000h, 000h, 000h, 0C6h, 0C6h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Ch, 078h, 000h
f99 db 0C6h, 0C6h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
f9A db 0C6h, 0C6h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f9B db 000h, 000h, 000h, 018h, 018h, 03Ch, 066h, 060h, 060h, 060h, 060h, 066h, 03Ch, 018h, 018h, 000h, 000h, 000h, 000h
f9C db 000h, 000h, 038h, 06Ch, 064h, 060h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 0E6h, 0FCh, 000h, 000h, 000h, 000h
f9D db 000h, 000h, 000h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 07Eh, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f9E db 000h, 000h, 0F8h, 0CCh, 0CCh, 0CCh, 0F8h, 0C4h, 0CCh, 0DEh, 0CCh, 0CCh, 0CCh, 0CCh, 0C6h, 000h, 000h, 000h, 000h
f9F db 000h, 000h, 00Eh, 01Bh, 018h, 018h, 018h, 018h, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 070h, 000h, 000h
fA0 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
fA1 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
fA2 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
fA3 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
fA4 db 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h, 000h
fA5 db 076h, 0DCh, 000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h, 000h
fA6 db 000h, 000h, 03Ch, 06Ch, 06Ch, 06Ch, 03Eh, 000h, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA7 db 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 07Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA8 db 000h, 000h, 000h, 030h, 030h, 000h, 030h, 030h, 030h, 060h, 0C0h, 0C0h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
fA9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C0h, 0C0h, 0C0h, 0C0h, 000h, 000h, 000h, 000h, 000h, 000h
fAA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 006h, 006h, 006h, 000h, 000h, 000h, 000h, 000h, 000h
fAB db 000h, 000h, 0C0h, 0C0h, 0C0h, 0C2h, 0C6h, 0CCh, 018h, 030h, 060h, 0DCh, 0A6h, 00Ch, 018h, 030h, 03Eh, 000h, 000h
fAC db 000h, 000h, 0C0h, 0C0h, 0C0h, 0C2h, 0C6h, 0CCh, 018h, 030h, 060h, 0CCh, 09Ch, 03Ch, 07Eh, 00Ch, 00Ch, 000h, 000h
fAD db 000h, 000h, 000h, 018h, 018h, 000h, 000h, 018h, 018h, 018h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h
fAE db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 033h, 066h, 0CCh, 0CCh, 066h, 033h, 000h, 000h, 000h, 000h, 000h, 000h
fAF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 066h, 033h, 033h, 066h, 0CCh, 000h, 000h, 000h, 000h, 000h, 000h
fB0 db 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h
fB1 db 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h
fB2 db 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh
fB3 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB4 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB6 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fB7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fB8 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB9 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBA db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBC db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBD db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBE db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC0 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC1 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC3 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC4 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC6 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC7 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fC8 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCA db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCC db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCD db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCE db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCF db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD0 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD1 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD3 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD4 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD7 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD8 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD9 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fDA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fDB db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
fDC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
fDD db 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h
fDE db 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh
fDF db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fE0 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 0D8h, 0D8h, 0D8h, 0D8h, 0DCh, 076h, 000h, 000h, 000h, 000h
fE1 db 000h, 000h, 000h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0D8h, 0CCh, 0C6h, 0C6h, 0C6h, 0C6h, 0DCh, 000h, 000h, 000h, 000h
fE2 db 000h, 000h, 000h, 0FEh, 0C6h, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 000h, 000h, 000h, 000h
fE3 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h
fE4 db 000h, 000h, 000h, 0FEh, 0C6h, 0C0h, 060h, 030h, 018h, 018h, 030h, 060h, 0C0h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
fE5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h
fE6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 0C0h, 000h
fE7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
fE8 db 000h, 000h, 000h, 03Ch, 018h, 03Ch, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 03Ch, 000h, 000h, 000h, 000h
fE9 db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
fEA db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 06Ch, 06Ch, 0EEh, 000h, 000h, 000h, 000h
fEB db 000h, 000h, 000h, 01Eh, 030h, 018h, 00Ch, 03Eh, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 000h, 000h, 000h, 000h
fEC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0DBh, 0DBh, 0DBh, 0DBh, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h
fED db 000h, 000h, 000h, 000h, 000h, 003h, 006h, 07Eh, 0CFh, 0DBh, 0DBh, 0F3h, 07Eh, 060h, 0C0h, 000h, 000h, 000h, 000h
fEE db 000h, 000h, 000h, 01Ch, 030h, 060h, 060h, 060h, 07Ch, 060h, 060h, 060h, 060h, 030h, 01Ch, 000h, 000h, 000h, 000h
fEF db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
fF0 db 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h
fF1 db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 07Eh, 018h, 018h, 018h, 000h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF2 db 000h, 000h, 000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 00Ch, 018h, 030h, 060h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF3 db 000h, 000h, 000h, 000h, 006h, 00Ch, 018h, 030h, 060h, 030h, 018h, 00Ch, 006h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF4 db 000h, 000h, 000h, 00Eh, 01Bh, 01Bh, 01Bh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fF5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h
fF6 db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 07Eh, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h
fF7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h
fF8 db 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fF9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFB db 000h, 000h, 00Fh, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 0ECh, 06Ch, 06Ch, 03Ch, 01Ch, 000h, 000h, 000h, 000h
fFC db 000h, 000h, 0D8h, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFD db 000h, 000h, 038h, 06Ch, 00Ch, 018h, 030h, 064h, 07Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFE db 000h, 000h, 000h, 000h, 000h, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 000h, 000h, 000h, 000h, 000h
fFF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
    
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

GetLfbPos  Proc near
    push eax
    push edx
;    
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:efi_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
;
    pop edx
    pop eax    
    ret
GetLfbPos  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           WriteChar
;
;   DESCRIPTION:    Write a single character
;
;   PARAMETERS:     AL          Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteChar       Proc near
    push ds
    pushad
;    
    mov dx,system_data_sel
    mov ds,dx
    push ax
    mov ax,ds:efi_text_row
    mov cx,19
    mul cx
    add ax,4
    movzx eax,ax
    movzx edx,ds:efi_text_col
    shl edx,3
    xchg eax,edx
    call GetLfbPos
    pop ax
;
    mov ah,19
    mul ah
    mov bx,ax
    add bx,OFFSET font8x19
;
    mov cx,19

wcRowLoop:    
    push cx
    push edi
    mov cx,8
    mov al,cs:[bx]

wcLoop:
    test al,80h
    jz wcBack

wcFore:
    mov edx,dword ptr ds:efi_fore_col
    mov es:[edi],edx
    jmp wcNext

wcBack:
    mov edx,dword ptr ds:efi_back_col
    mov es:[edi],edx

wcNext:
    add edi,4
    shl al,1
;
    loop wcLoop    
;
    pop edi
    pop cx
    add edi,ds:efi_scan_size
    inc bx
;
    loop wcRowLoop    
    inc ds:efi_text_col
;
    popad        
    pop ds
    ret
WriteChar       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           WriteStr
;
;   DESCRIPTION:    Write a string
;
;   PARAMETERS:     DS:SI       string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteStr       Proc near
    push ax
    push si

wsLoop:
    mov al,ds:[si]
    or al,al
    jz wsDone
;
    call WriteChar
    inc si
    jmp wsLoop

wsDone:
    pop si
    pop ax
    ret
WriteStr    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SingleHex
;
;           DESCRIPTION:
;
;           PARAMETERS:         AL          Value in
;                           AX          Value out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SingleHex       Proc near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb shLow1
;
    add al,7

shLow1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb shHigh1
;
    add ah,7

shHigh1:
    add ah,30h
    ret
SingleHex  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteHexByte
;
;       DESCRIPTION:
;
;       PARAMETERS:     AL          HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    Proc near
    push ax
    push di
;
    call SingleHex
    mov di,ax
    mov al,ah
    call WriteChar
    mov ax,di
    call WriteChar
;
    pop di
    pop ax
    ret
WriteHexByte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteHexWord
;
;       DESCRIPTION:
;
;       PARAMETERS:     AX          HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    Proc near
    push ax
    push si
    push di
;
    mov si,ax
    shr ax,8
    call SingleHex
    mov di,ax
    call WriteChar
    mov ax,di
    mov al,ah
    call WriteChar
    mov ax,si
    call SingleHex
    mov di,ax
    call WriteChar
    mov ax,di
    mov al,ah
    call WriteChar
;
    pop di
    pop si
    pop ax
    ret
WriteHexWord  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteHexDword
;
;       DESCRIPTION:
;
;       PARAMETERS:     EAX          HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword    Proc near
    push eax
    shr eax,16
    call WriteHexWord
    pop eax
    call WriteHexWord
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocatePage
;
;       DESCRIPTION:    Allocate a single page
;
;       PARAMETERS:     ESI     Memory base
;
;       RETURNS:        ESI     Page allocated
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePage    MACRO
    Local LowRamLoop
    Local HighRamLoop
    Local LowRamNext
    Local RamFound

    mov ax,flat_sel
    mov ds,ax
    jmp LowRamNext
    
LowRamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
    
LowRamNext:
    add esi,1000h
    cmp esi,9F000h
    jc LowRamLoop
;    
    mov esi,100000h

HighRamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
;    
    add esi,1000h
    jmp HighRamLoop
    
RamFound:
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateCrc
;
;   DESCRIPTION:    Creates CRC table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCrc      MACRO
    mov ax,8
    mov ds,ax
    mov ax,1021h
;
    xor cl,cl
    mov bx,OFFSET crc_tab
    
create_crc_loop:   
    xor dx,dx
    xor dh,cl
    shl dx,1
    jnc no_xor0
;
    xor dx,ax

no_xor0:
    shl dx,1
    jnc no_xor1
;
    xor dx,ax 

no_xor1:       
    shl dx,1
    jnc no_xor2
;
    xor dx,ax 

no_xor2:       
    shl dx,1
    jnc no_xor3
;
    xor dx,ax 

no_xor3:       
    shl dx,1
    jnc no_xor4
;
    xor dx,ax 

no_xor4:       
    shl dx,1
    jnc no_xor5
;
    xor dx,ax 

no_xor5:       
    shl dx,1
    jnc no_xor6
;
    xor dx,ax 

no_xor6:       
    shl dx,1
    jnc no_xor7
;
    xor dx,ax 

no_xor7:      
    mov ds:[bx],dx
    add bx,2
    inc cx
    or cl,cl
    jnz create_crc_loop
    ENDM


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetMemBase
;
;   DESCRIPTION:    Get memory base from memmap info
;
;   PARAMETERS:     ECX Number of memory entries
;
;   RETURNS:        ESI Allocation base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMemBase      MACRO
    mov ax,flat_sel
    mov ds,ax
    xor esi,esi
    mov ebx,MEM_BASE
    or cx,cx
    jz gmbDone
;
    mov esi,0FFFFFFFFh

gmbLoop:
    mov eax,ds:[ebx].mmap_base+4
    or eax,eax
    jnz gmbNext
;
    cmp esi,ds:[ebx].mmap_base
    jb gmbNext
;
    mov esi,ds:[ebx].mmap_base

gmbNext:
    add ebx,ds:[ebx].mmap_len
    add ebx,4
    loop gmbLoop

gmbOk:
    or esi,esi
    jz gmbDone
;
    sub esi,1000h

gmbDone:
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetAdapter
;
;   DESCRIPTION:
;
;   PARAMETERS:     ESI     Adress to start search at
;
;   RETURNS:        ESI     Adapter base
;                   ECX     Size of adapter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignError       DB 'Rdos Signature Not Found',0
SizeError       DB 'To Large boot image',0
CrcBase         DB 'CRC error at ', 0
CrcSize         DB ' Size: ', 0
GotCrc          DB ' Got: ', 0
ExpCrc          DB ' Exp: ', 0
SumStr          DB ' Sum: ', 0

GetAdapter  Proc near
    push ds
    push esi
    mov ax,flat_sel
    mov ds,ax

GetAdapterNextDriver:
    mov eax,[esi]
    cmp eax,RdosSign
    je GetAdapterSignOk
;    
    mov ax,cs
    mov ds,ax
    mov si,OFFSET SignError
    call WriteStr
    stc
    jmp GetAdapterDone

GetAdapterSignOk:        
    cmp [esi].typ,RdosEnd
    je GetAdapterOk
;    
    mov edx,[esi].len
    add ecx,edx
    cmp ecx,1000000h
    jc GetAdapterSizeOk
;
    mov ax,cs
    mov ds,ax
    mov si,OFFSET SizeError
    call WriteStr
    stc
    jmp GetAdapterDone

GetAdapterSizeOk:    
    xor ax,ax
    xor edi,edi
    xor ebx,ebx
;
    push ecx
    push esi
    mov ecx,edx
    add esi,SIZE rdos_header
    sub ecx,SIZE rdos_header
    jz GetAdapterCrcDone

GetAdapterCrcLoop:
    mov bl,ds:[esi]
    add edi,ebx
    xor bl,ah
    shl ax,8
    xor ax,cs:[2*ebx].crc_tab
    inc esi
    sub ecx,1
    jnz GetAdapterCrcLoop

GetAdapterCrcDone:
    pop esi
    pop ecx
    cmp ax,[esi].crc
    je GetAdapterCrcOk
;
    push edi
    push esi
    push ax
    push ecx
    push esi
    push ds
    mov ax,cs
    mov ds,ax
    mov si,OFFSET CrcBase
    call WriteStr
    pop ds
;
    pop eax
    call WriteHexDword
;
    push ds
    mov ax,cs
    mov ds,ax
    mov si,OFFSET CrcSize
    call WriteStr
    pop ds
;
    pop eax
    call WriteHexDword
;
    push ds
    mov ax,cs
    mov ds,ax
    mov si,OFFSET GotCrc
    call WriteStr
    pop ds
;
    pop ax
    call WriteHexWord
;
    push ds
    mov ax,cs
    mov ds,ax
    mov si,OFFSET ExpCrc
    call WriteStr
    pop ds
    pop esi
    mov ax,[esi].crc
    call WriteHexWord
;
    push ds
    mov ax,cs
    mov ds,ax
    mov si,OFFSET SumStr
    call WriteStr
    pop ds
;
    pop eax
    call WriteHexDword    
    stc
    jmp GetAdapterDone

GetAdapterCrcOk:    
    add esi,edx
    jmp GetAdapterNextDriver

GetAdapterOk:
    clc

GetAdapterDone:
    pop esi
    pop ds
    ret
GetAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetAllAdapters
;
;   DESCRIPTION:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllAdapters  Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov esi,ds:rom1_base
    mov ds:rom_modules,0
    mov bx,OFFSET rom_adapters

get_adapters_loop:
    call GetAdapter
    jc get_adapters_done
;
    add ecx,SIZE rdos_header
    mov ds:rom_modules,1
    mov bx,OFFSET rom_adapters
    mov [bx].adapter_base,esi
    mov [bx].adapter_size,ecx
    mov [bx].adapter_crc,0
    mov ds:rom1_size,ecx

get_adapters_done:
    ret
GetAllAdapters  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           boot_idt
;
;   DESCRIPTION:    Default IDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BootIdtEntry        MACRO Offs
    dw OFFSET Offs
    dw device_code_sel
    dw 8E00h
    dw 0
                    ENDM

BootExceptionOnePar     MACRO Entry
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,Entry
    ShutDownPreTask
                ENDM

BootExceptionNoPar      MACRO Entry
    push dword ptr 0
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,Entry
    ShutDownPreTask
                ENDM

Boot0:
    BootExceptionNoPar 0

Boot1:
    BootExceptionNoPar 1

Boot2:
    BootExceptionNoPar 2

Boot3:
    BootExceptionNoPar 3

Boot4:
    BootExceptionNoPar 4

Boot5:
    BootExceptionNoPar 5

Boot6:
    BootExceptionNoPar 6

Boot7:
    BootExceptionNoPar 7

Boot8:
    BootExceptionNoPar 8

Boot9:
    BootExceptionNoPar 9

BootA:
    BootExceptionNoPar 0Ah

BootB:
    BootExceptionOnePar 0Bh

BootC:
    BootExceptionOnePar 0Ch

BootD:
    BootExceptionOnePar 0Dh

BootE:
    BootExceptionNoPar 0Eh

BootF:
    BootExceptionNoPar 0Fh

boot_idt:
    BootIdtEntry Boot0
    BootIdtEntry Boot1
    BootIdtEntry Boot2
    BootIdtEntry Boot3
    BootIdtEntry Boot4
    BootIdtEntry Boot5
    BootIdtEntry Boot6
    BootIdtEntry Boot7
    BootIdtEntry Boot8
    BootIdtEntry Boot9
    BootIdtEntry BootA
    BootIdtEntry BootB
    BootIdtEntry BootC
    BootIdtEntry BootD
    BootIdtEntry BootE
    BootIdtEntry BootF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           StartShutdownDevice
;
;   DESCRIPTION:    Starts shutdown-device
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartShutDownDevice     Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters
    or cx,cx
    jz StartShutDeviceEnd
    
StartShutAdapterLoop:
    push bx
    push cx
    mov esi,[bx].adapter_base

StartShutDeviceLoop:
    cmp es:[esi].typ,RdosShutDown
    je StartShutDeviceDo
;
    cmp es:[esi].typ,RdosEnd
    je StartShutNextAdapter
;
    add esi,es:[esi].len
    jmp StartShutDeviceLoop

StartShutNextAdapter:
    pop cx
    pop bx
    add bx,SIZE adapter_typ
    loop StartShutAdapterLoop
;    
    jmp StartShutDeviceEnd

StartShutDeviceDo:
    pop cx
    pop bx
;
    push ds
    push es
    pushad
    push cs
    push OFFSET StartShutDeviceInitied
    mov ax,flat_sel
    mov ds,ax
    mov bx,shutdown_code_sel
    push bx
    mov ecx,[esi].len
    add esi,SIZE rdos_header
    push word ptr [esi].init_ip
    add esi,SIZE simple_device_header
    mov ax,gdt_sel
    mov ds,ax
    dec cx
    mov [bx],cx
    mov [bx+2],esi
    mov ah,9Ah
    xchg ah,[bx+5]
    xor al,al
    mov [bx+6],ax
    retf

StartShutDeviceInitied:
    mov ax,gdt_sel
    mov ds,ax
    mov bx,idt_sel
    mov eax,OFFSET boot_idt + IMAGE_BASE
    mov [bx+2],eax
    mov ax,10h*8-1
    mov [bx],ax
    lidt fword ptr [bx]
;
    popad
    pop es
    pop ds

StartShutDeviceEnd:     
    ret
StartShutDownDevice     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetBootDevice
;
;   DESCRIPTION:    Get header of boot-device
;
;   RETURNS:        NC
;                   ESI             Boot device base
;                   CY              No boot device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBootDevice   Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters
    or cx,cx
    jz GetBootDeviceFail

GetBootAdapterLoop:
    push bx
    push cx
    mov esi,[bx].adapter_base

GetBootDeviceLoop:
    cmp es:[esi].typ,RdosKernel
    je GetBootDeviceOk
;
    cmp es:[esi].typ,RdosEnd
    je GetBootNextAdapter
;
    add esi,es:[esi].len
    jmp GetBootDeviceLoop

GetBootNextAdapter:
    pop cx
    pop bx
    add bx,SIZE adapter_typ
    loop GetBootAdapterLoop
;    
    jmp GetBootDeviceFail

GetBootDeviceOk:
    pop cx
    pop bx
    clc
    jmp GetBootDeviceEnd

GetBootDeviceFail:      
    stc
GetBootDeviceEnd:
    ret
GetBootDevice   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Start
;
;   DESCRIPTION:    Start boot
;
;   PARAMETERS:     ECX         Memory entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public start


BootingText  DB '            Booting', 0
StartingText DB ', Starting', 0
NoBootText   DB 'No kernel to boot up', 0
NoMemory     DB 'No memory map       ', 0

start:
    GetMemBase
    mov ebp,esi
;
    CreateCrc
;
    mov esi,ebp
    AllocatePage
    mov edx,esi
    mov edi,esi
    xor esi,esi
    mov ax,gdt_sel
    mov ds,ax
    mov ecx,2*5
    rep movs dword ptr es:[edi],ds:[esi]
    mov ax,flat_sel
    mov ds,ax
    mov esi,edx
    mov ebx,gdt_sel
    add ebx,esi
    mov word ptr [ebx],0FFFh
    mov [ebx+2],esi
    lgdt fword ptr ds:[ebx]
;
    mov byte ptr [ebx+5],92h
    mov word ptr [ebx+6],0
;    
    AllocatePage
    mov ax,gdt_sel
    mov ds,ax
    mov bx,system_data_sel
    mov word ptr [bx],0FFFh
    mov [bx+2],esi
    mov byte ptr [bx+5],92h
    mov word ptr [bx+6],0
;
    mov ax,gdt_sel
    mov ss,ax
    mov esp,1000h
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:alloc_base,esi
    mov ds:efi_text_row,5
    mov ds:efi_text_col,0
    mov ds:efi_fore_col,0FFFFFFh
    mov ds:efi_back_col,0
;
    mov ds:ram1_size,0A0000h
    mov ds:ram2_base,100000h
    mov ds:ram2_size,0
;    
    mov ds:rom1_base,RDOS_BASE
    mov ds:rom1_size,0
    mov ds:rom2_size,0
    mov ds:rom_shadow,0
;
    call GetLfb
    mov ds:efi_lfb,esi
    mov ds:efi_lfb+4,edi
    mov ds:efi_scan_size,ecx
    mov ds:efi_width,ax
    mov ds:efi_height,dx
    mov ds:efi_flags,ebx
;    
    mov ax,flat_sel
    mov es,ax
    xor di,di
    xor eax,eax
    mov cx,100h
    rep stosd
;
    call GetMemCount
    mov ax,flat_sel
    mov es,ax
    xor edx,edx
    mov ebx,MEM_BASE
    or cx,cx
    jnz bootMemOk
;
    mov ax,cs
    mov ds,ax
    mov si,OFFSET NoMemory
    call WriteStr
    jmp DoStop

bootMemOk:
    add edx,es:[ebx].mmap_len
    add edx,4
    add ebx,es:[ebx].mmap_len
    add ebx,4
    loop bootMemOk
;
    mov ds:multiboot_mmap_len,dx
    mov ds:multiboot_mmap_addr,MEM_BASE
;
    push ds    
    pushad
    mov ax,cs
    mov ds,ax
    mov si,OFFSET BootingText
    call WriteStr
    popad
    pop ds
;
    call GetAcpiTablePtr
    mov ds:efi_acpi,eax
    mov ds:efi_acpi+4,edx
;        
    call GetAllAdapters
    call StartShutDownDevice
    call GetBootDevice
    jnc DoBoot
;
    mov ax,cs
    mov ds,ax
    mov si,OFFSET NoBootText
    call WriteStr

DoStop:
    jmp DoStop

DoBoot:
    push ds    
    pushad
    mov ax,cs
    mov ds,ax
    mov si,OFFSET StartingText
    call WriteStr
    popad
    pop ds
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:efi_text_row,0
    mov ds:efi_text_col,0
;    
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    push word ptr kernel_code
    mov ecx,[esi].len
    add esi,SIZE rdos_header
    push word ptr [esi].init_ip
    add esi,SIZE simple_device_header
    mov ax,gdt_sel
    mov ds,ax
    dec cx
    mov bx,kernel_code
    mov [bx],cx
    mov [bx+2],esi
    mov ah,9Ah
    xchg ah,[bx+5]
    xor al,al
    mov [bx+6],ax
    retf


_TEXT  Ends

    end
