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
; boot.asm
; Common RDOS boot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


param_struc     STRUC

lfb_base        DD ?,?
uefi_data       DD ?,?

param_struc     ENDS

IMAGE_BASE = 110000h

_TEXT segment byte public use16 'CODE'

    extern GetLfb:near
    extern GetLfbPos:near

    .386p

text_row        DW ?
text_col        DW ?
scan_size       DD ?
fore_col        DD ?
back_col        DD ?
    
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
;   NAME:           WriteChar
;
;   DESCRIPTION:    Write a single character
;
;   PARAMETERS:     AL          Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteChar       Proc near
    pushad
;    
    push ax
    mov ax,cs:text_row
    mov cx,19
    mul cx
    movzx eax,ax
    movzx edx,cs:text_col
    shl edx,3
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
    mov edx,dword ptr cs:fore_col
    mov es:[edi],edx
    jmp wcNext

wcBack:
    mov edx,dword ptr cs:back_col
    mov es:[edi],edx

wcNext:
    add edi,4
    shl al,1
;
    loop wcLoop    
;
    pop edi
    pop cx
    add edi,cs:scan_size
    inc bx
;
    loop wcRowLoop    
;
    popad        
    ret
WriteChar       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Start
;
;   DESCRIPTION:    Start boot
;
;   PARAMETERS:     EAX         Scan size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public start

start:
    mov ds:scan_size,eax
    mov ds:text_row,0
    mov ds:text_col,0
    mov ds:fore_col,0FFFFFFh
    mov ds:back_col,0
;    
    mov al,'r'
    call WriteChar
    
stopl:
    jmp stopl


_TEXT  Ends

    end
