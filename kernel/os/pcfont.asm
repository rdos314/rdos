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
; PCFONT.ASM
; Fixed-size PC font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

        .386p

code    SEGMENT byte public 'CODE'

        assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetPcFontChar
;
;   DESCRIPTION:    Get PC font character
;
;   PARAMETERS:     AL      Character
;
;   RETURNS:        EBX     Offset to character font data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

font8x19:
f00 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f01 db 000h, 000h, 000h, 0FCh, 002h, 002h, 04Ah, 002h, 002h, 002h, 07Ah, 032h, 002h, 002h, 0FCh, 000h, 000h, 000h, 000h
f02 db 000h, 000h, 000h, 0FCh, 0FEh, 0FEh, 0B6h, 0FEh, 0FEh, 0FEh, 086h, 0CEh, 0FEh, 0FEh, 0FCh, 000h, 000h, 000h, 000h
f03 db 000h, 000h, 000h, 000h, 000h, 000h, 0D8h, 0FCh, 0FCh, 0FCh, 0FCh, 0FCh, 0F8h, 070h, 020h, 000h, 000h, 000h, 000h
f04 db 000h, 000h, 000h, 000h, 000h, 000h, 020h, 070h, 0F8h, 0FCh, 0FCh, 0F8h, 070h, 020h, 000h, 000h, 000h, 000h, 000h
f05 db 000h, 000h, 000h, 000h, 030h, 078h, 078h, 078h, 0CEh, 0CEh, 0CEh, 0CEh, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f06 db 000h, 000h, 000h, 000h, 030h, 030h, 078h, 0FCh, 0FEh, 0FEh, 0FEh, 0FCh, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f07 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 078h, 078h, 078h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f08 db 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0CEh, 086h, 086h, 086h, 0CEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh
f09 db 000h, 000h, 000h, 000h, 000h, 000h, 078h, 0CCh, 084h, 084h, 084h, 0CCh, 078h, 000h, 000h, 000h, 000h, 000h, 000h
f0A db 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 086h, 032h, 07Ah, 07Ah, 07Ah, 032h, 086h, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh
f0B db 000h, 000h, 000h, 03Ch, 00Ch, 01Ch, 034h, 060h, 0F0h, 098h, 098h, 098h, 098h, 098h, 0F0h, 000h, 000h, 000h, 000h
f0C db 000h, 000h, 000h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 030h, 0FCh, 030h, 030h, 000h, 000h, 000h, 000h
f0D db 000h, 000h, 000h, 07Eh, 066h, 066h, 07Eh, 060h, 060h, 060h, 060h, 060h, 0E0h, 0E0h, 0C0h, 000h, 000h, 000h, 000h
f0E db 000h, 000h, 000h, 0FEh, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0CEh, 0CEh, 0CCh, 080h, 000h, 000h, 000h
f0F db 000h, 000h, 000h, 000h, 000h, 030h, 030h, 0B6h, 078h, 0CEh, 0CEh, 078h, 0B6h, 030h, 030h, 000h, 000h, 000h, 000h
f10 db 000h, 000h, 000h, 000h, 080h, 0C0h, 0E0h, 0F0h, 0FCh, 0FCh, 0F0h, 0E0h, 0C0h, 080h, 000h, 000h, 000h, 000h, 000h
f11 db 000h, 000h, 000h, 004h, 00Ch, 01Ch, 03Ch, 07Ch, 0FCh, 0FCh, 07Ch, 03Ch, 01Ch, 00Ch, 004h, 000h, 000h, 000h, 000h
f12 db 000h, 000h, 000h, 030h, 078h, 0FCh, 030h, 030h, 030h, 030h, 030h, 030h, 0FCh, 078h, 030h, 000h, 000h, 000h, 000h
f13 db 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 000h, 0CCh, 0CCh, 000h, 000h, 000h, 000h
f14 db 000h, 000h, 000h, 0FEh, 0B6h, 0B6h, 0B6h, 0B6h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 000h, 000h, 000h, 000h
f15 db 000h, 000h, 000h, 0F8h, 08Ch, 0C0h, 070h, 0D8h, 08Ch, 08Ch, 0D8h, 070h, 018h, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f16 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 0FCh, 0FCh, 000h, 000h, 000h, 000h
f17 db 000h, 000h, 000h, 030h, 078h, 0FCh, 030h, 030h, 030h, 030h, 030h, 030h, 0FCh, 078h, 030h, 0FCh, 000h, 000h, 000h
f18 db 000h, 000h, 000h, 030h, 078h, 0FCh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 000h, 000h, 000h, 000h
f19 db 000h, 000h, 000h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0FCh, 078h, 030h, 000h, 000h, 000h, 000h
f1A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 018h, 0FCh, 018h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1B db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 060h, 0C0h, 0FCh, 0C0h, 060h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 080h, 080h, 080h, 080h, 0FCh, 000h, 000h, 000h, 000h, 000h, 000h
f1D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 048h, 0CCh, 0FEh, 0CCh, 048h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1E db 000h, 000h, 000h, 000h, 000h, 020h, 020h, 070h, 070h, 0F8h, 0F8h, 0FCh, 0FCh, 000h, 000h, 000h, 000h, 000h, 000h
f1F db 000h, 000h, 000h, 000h, 000h, 0FCh, 0FCh, 0F8h, 0F8h, 070h, 070h, 020h, 020h, 000h, 000h, 000h, 000h, 000h, 000h
f20 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f21 db 000h, 000h, 000h, 030h, 078h, 078h, 078h, 078h, 030h, 030h, 030h, 030h, 000h, 030h, 030h, 000h, 000h, 000h, 000h
f22 db 000h, 000h, 0CCh, 0CCh, 0CCh, 048h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f23 db 000h, 000h, 000h, 0D8h, 0D8h, 0D8h, 0FCh, 0D8h, 0D8h, 0D8h, 0D8h, 0FCh, 0D8h, 0D8h, 0D8h, 000h, 000h, 000h, 000h
f24 db 000h, 030h, 030h, 0F8h, 08Ch, 084h, 080h, 080h, 0F8h, 00Ch, 00Ch, 00Ch, 00Ch, 08Ch, 0F8h, 030h, 030h, 000h, 000h
f25 db 000h, 000h, 000h, 08Ch, 08Ch, 098h, 018h, 030h, 030h, 060h, 060h, 0C0h, 0CCh, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f26 db 000h, 000h, 000h, 070h, 0D8h, 0D8h, 0D8h, 070h, 0ECh, 0B8h, 0B8h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f27 db 000h, 000h, 030h, 030h, 030h, 060h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f28 db 000h, 000h, 000h, 018h, 030h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 030h, 018h, 000h, 000h, 000h, 000h
f29 db 000h, 000h, 000h, 060h, 030h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 030h, 060h, 000h, 000h, 000h, 000h
f2A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 078h, 0FEh, 078h, 0CCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2B db 000h, 000h, 000h, 000h, 000h, 000h, 030h, 030h, 030h, 0FEh, 030h, 030h, 030h, 000h, 000h, 000h, 000h, 000h, 000h
f2C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 030h, 030h, 060h, 000h, 000h, 000h
f2D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 030h, 000h, 000h, 000h, 000h
f2F db 000h, 000h, 000h, 00Ch, 00Ch, 018h, 018h, 030h, 030h, 060h, 060h, 0C0h, 0C0h, 080h, 080h, 000h, 000h, 000h, 000h
f30 db 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 0ACh, 0ACh, 0ACh, 0ACh, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f31 db 000h, 000h, 000h, 030h, 070h, 0F0h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0FCh, 000h, 000h, 000h, 000h
f32 db 000h, 000h, 000h, 0F8h, 08Ch, 00Ch, 00Ch, 018h, 030h, 060h, 0C0h, 080h, 080h, 08Ch, 0FCh, 000h, 000h, 000h, 000h
f33 db 000h, 000h, 000h, 0F8h, 08Ch, 00Ch, 00Ch, 00Ch, 078h, 00Ch, 00Ch, 00Ch, 00Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f34 db 000h, 000h, 000h, 038h, 038h, 078h, 078h, 0D8h, 0D8h, 098h, 0FCh, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f35 db 000h, 000h, 000h, 0FCh, 080h, 080h, 080h, 080h, 0F8h, 00Ch, 00Ch, 00Ch, 00Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f36 db 000h, 000h, 000h, 070h, 0C0h, 080h, 080h, 080h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f37 db 000h, 000h, 000h, 0FCh, 08Ch, 00Ch, 00Ch, 00Ch, 018h, 030h, 030h, 060h, 060h, 060h, 060h, 000h, 000h, 000h, 000h
f38 db 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f39 db 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 0FCh, 00Ch, 00Ch, 00Ch, 00Ch, 018h, 0F0h, 000h, 000h, 000h, 000h
f3A db 000h, 000h, 000h, 000h, 000h, 030h, 030h, 000h, 000h, 000h, 000h, 000h, 030h, 030h, 000h, 000h, 000h, 000h, 000h
f3B db 000h, 000h, 000h, 000h, 000h, 030h, 030h, 000h, 000h, 000h, 000h, 000h, 030h, 030h, 060h, 000h, 000h, 000h, 000h
f3C db 000h, 000h, 000h, 000h, 00Ch, 018h, 030h, 060h, 0C0h, 0C0h, 060h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h, 000h
f3D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 000h, 000h, 0FCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f3E db 000h, 000h, 000h, 000h, 0C0h, 060h, 030h, 018h, 00Ch, 00Ch, 018h, 030h, 060h, 0C0h, 000h, 000h, 000h, 000h, 000h
f3F db 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 00Ch, 00Ch, 018h, 030h, 030h, 030h, 000h, 030h, 030h, 000h, 000h, 000h, 000h
f40 db 000h, 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 0BCh, 0BCh, 0BCh, 0B8h, 080h, 080h, 0F8h, 000h, 000h, 000h, 000h
f41 db 000h, 000h, 000h, 020h, 070h, 0D8h, 08Ch, 08Ch, 08Ch, 0FCh, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f42 db 000h, 000h, 000h, 0F8h, 0CCh, 0CCh, 0CCh, 0CCh, 0F8h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0F8h, 000h, 000h, 000h, 000h
f43 db 000h, 000h, 000h, 078h, 0CCh, 084h, 080h, 080h, 080h, 080h, 080h, 080h, 084h, 0CCh, 078h, 000h, 000h, 000h, 000h
f44 db 000h, 000h, 000h, 0F0h, 0D8h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0D8h, 0F0h, 000h, 000h, 000h, 000h
f45 db 000h, 000h, 000h, 0FCh, 0CCh, 0C4h, 0C0h, 0D0h, 0F0h, 0D0h, 0C0h, 0C0h, 0C4h, 0CCh, 0FCh, 000h, 000h, 000h, 000h
f46 db 000h, 000h, 000h, 0FCh, 0CCh, 0C4h, 0C0h, 0D0h, 0F0h, 0D0h, 0C0h, 0C0h, 0C0h, 0C0h, 0E0h, 000h, 000h, 000h, 000h
f47 db 000h, 000h, 000h, 078h, 0CCh, 084h, 080h, 080h, 080h, 0BCh, 08Ch, 08Ch, 08Ch, 0CCh, 074h, 000h, 000h, 000h, 000h
f48 db 000h, 000h, 000h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0FCh, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f49 db 000h, 000h, 000h, 078h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f4A db 000h, 000h, 000h, 01Eh, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f4B db 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0D8h, 0D8h, 0F0h, 0F8h, 0D8h, 0D8h, 0CCh, 0CCh, 0CCh, 000h, 000h, 000h, 000h
f4C db 000h, 000h, 000h, 0E0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C4h, 0CCh, 0FCh, 000h, 000h, 000h, 000h
f4D db 000h, 000h, 000h, 08Ch, 0DCh, 0FCh, 0FCh, 0ACh, 0ACh, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f4E db 000h, 000h, 000h, 08Ch, 08Ch, 0CCh, 0CCh, 0ECh, 0ECh, 0BCh, 0BCh, 09Ch, 09Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f4F db 000h, 000h, 000h, 070h, 0D8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0D8h, 070h, 000h, 000h, 000h, 000h
f50 db 000h, 000h, 000h, 0F8h, 0CCh, 0CCh, 0CCh, 0CCh, 0F8h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0E0h, 000h, 000h, 000h, 000h
f51 db 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0ACh, 0BCh, 0F8h, 018h, 01Ch, 000h, 000h
f52 db 000h, 000h, 000h, 0F8h, 0CCh, 0CCh, 0CCh, 0CCh, 0F8h, 0D8h, 0D8h, 0CCh, 0CCh, 0CCh, 0CCh, 000h, 000h, 000h, 000h
f53 db 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 080h, 0C0h, 070h, 018h, 00Ch, 00Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f54 db 000h, 000h, 000h, 0FCh, 0FCh, 0B4h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f55 db 000h, 000h, 000h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f56 db 000h, 000h, 000h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0D8h, 070h, 020h, 000h, 000h, 000h, 000h
f57 db 000h, 000h, 000h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0ACh, 0ACh, 0ACh, 0FCh, 0D8h, 0D8h, 000h, 000h, 000h, 000h
f58 db 000h, 000h, 000h, 08Ch, 08Ch, 08Ch, 0D8h, 0D8h, 070h, 070h, 0D8h, 0D8h, 08Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f59 db 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f5A db 000h, 000h, 000h, 0FCh, 08Ch, 00Ch, 00Ch, 018h, 030h, 060h, 0C0h, 080h, 084h, 08Ch, 0FCh, 000h, 000h, 000h, 000h
f5B db 000h, 000h, 000h, 078h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 078h, 000h, 000h, 000h, 000h
f5C db 000h, 000h, 000h, 080h, 080h, 0C0h, 0C0h, 060h, 060h, 030h, 030h, 018h, 018h, 00Ch, 00Ch, 000h, 000h, 000h, 000h
f5D db 000h, 000h, 000h, 078h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 078h, 000h, 000h, 000h, 000h
f5E db 000h, 020h, 070h, 0D8h, 08Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f5F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h
f60 db 000h, 000h, 060h, 030h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f61 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F0h, 018h, 018h, 0F8h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f62 db 000h, 000h, 000h, 0C0h, 0C0h, 0C0h, 0C0h, 0F0h, 0D8h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0B8h, 000h, 000h, 000h, 000h
f63 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 08Ch, 080h, 080h, 080h, 080h, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f64 db 000h, 000h, 000h, 038h, 018h, 018h, 018h, 078h, 0D8h, 098h, 098h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f65 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 0FCh, 080h, 080h, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f66 db 000h, 000h, 000h, 070h, 0D8h, 0C8h, 0C0h, 0C0h, 0E0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0E0h, 000h, 000h, 000h, 000h
f67 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 098h, 098h, 098h, 098h, 098h, 0F8h, 018h, 018h, 098h, 0F0h, 000h
f68 db 000h, 000h, 000h, 0C0h, 0C0h, 0C0h, 0C0h, 0D8h, 0ECh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 000h, 000h, 000h, 000h
f69 db 000h, 000h, 000h, 030h, 030h, 000h, 000h, 070h, 030h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f6A db 000h, 000h, 000h, 00Ch, 00Ch, 000h, 000h, 01Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 0CCh, 0CCh, 078h, 000h
f6B db 000h, 000h, 000h, 0C0h, 0C0h, 0C0h, 0C0h, 0CCh, 0CCh, 0D8h, 0F0h, 0F0h, 0D8h, 0CCh, 0CCh, 000h, 000h, 000h, 000h
f6C db 000h, 000h, 000h, 070h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f6D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0D8h, 0FCh, 0ACh, 0ACh, 0ACh, 0ACh, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f6E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0B8h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 000h, 000h, 000h, 000h
f6F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f70 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0B8h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0F8h, 0C0h, 0C0h, 0C0h, 0E0h, 000h
f71 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 098h, 098h, 098h, 098h, 098h, 0F8h, 018h, 018h, 018h, 03Ch, 000h
f72 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0B8h, 0ECh, 0CCh, 0C0h, 0C0h, 0C0h, 0C0h, 0E0h, 000h, 000h, 000h, 000h
f73 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 08Ch, 0C0h, 070h, 018h, 00Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f74 db 000h, 000h, 000h, 020h, 060h, 060h, 060h, 0F8h, 060h, 060h, 060h, 060h, 060h, 06Ch, 038h, 000h, 000h, 000h, 000h
f75 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 098h, 098h, 098h, 098h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f76 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 030h, 000h, 000h, 000h, 000h
f77 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 08Ch, 08Ch, 08Ch, 0ACh, 0ACh, 0ACh, 0FCh, 0D8h, 000h, 000h, 000h, 000h
f78 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 08Ch, 08Ch, 0D8h, 070h, 070h, 0D8h, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f79 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0FCh, 00Ch, 00Ch, 018h, 0F0h, 000h
f7A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 08Ch, 018h, 030h, 060h, 0C0h, 08Ch, 0FCh, 000h, 000h, 000h, 000h
f7B db 000h, 000h, 000h, 01Ch, 030h, 030h, 030h, 030h, 0E0h, 0E0h, 030h, 030h, 030h, 030h, 01Ch, 000h, 000h, 000h, 000h
f7C db 000h, 000h, 000h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 000h, 000h, 000h, 000h
f7D db 000h, 000h, 000h, 0E0h, 030h, 030h, 030h, 030h, 01Ch, 01Ch, 030h, 030h, 030h, 030h, 0E0h, 000h, 000h, 000h, 000h
f7E db 000h, 000h, 000h, 0ECh, 0B8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f7F db 000h, 000h, 000h, 000h, 000h, 000h, 020h, 070h, 0D8h, 08Ch, 08Ch, 08Ch, 08Ch, 0FCh, 000h, 000h, 000h, 000h, 000h
f80 db 000h, 000h, 000h, 078h, 0CCh, 084h, 080h, 080h, 080h, 080h, 080h, 080h, 084h, 0CCh, 078h, 030h, 018h, 070h, 000h
f81 db 000h, 000h, 000h, 000h, 098h, 098h, 000h, 098h, 098h, 098h, 098h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f82 db 000h, 000h, 000h, 018h, 030h, 060h, 000h, 0F8h, 08Ch, 08Ch, 0FCh, 080h, 080h, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f83 db 000h, 000h, 000h, 020h, 070h, 0D8h, 000h, 0F0h, 018h, 018h, 0F8h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f84 db 000h, 000h, 000h, 000h, 098h, 098h, 000h, 0F0h, 018h, 018h, 0F8h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f85 db 000h, 000h, 000h, 0C0h, 060h, 030h, 000h, 0F0h, 018h, 018h, 0F8h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f86 db 000h, 000h, 000h, 070h, 0D8h, 070h, 000h, 0F0h, 018h, 018h, 0F8h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f87 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 08Ch, 080h, 080h, 080h, 080h, 08Ch, 0F8h, 030h, 018h, 070h, 000h
f88 db 000h, 000h, 000h, 020h, 070h, 0D8h, 000h, 0F8h, 08Ch, 08Ch, 0FCh, 080h, 080h, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f89 db 000h, 000h, 000h, 000h, 098h, 098h, 000h, 0F8h, 08Ch, 08Ch, 0FCh, 080h, 080h, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f8A db 000h, 000h, 000h, 0C0h, 060h, 030h, 000h, 0F8h, 08Ch, 08Ch, 0FCh, 080h, 080h, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f8B db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 070h, 030h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f8C db 000h, 000h, 000h, 030h, 078h, 0CCh, 000h, 070h, 030h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f8D db 000h, 000h, 000h, 0C0h, 060h, 030h, 000h, 070h, 030h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
f8E db 08Ch, 08Ch, 000h, 020h, 070h, 0D8h, 08Ch, 08Ch, 08Ch, 0FCh, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f8F db 070h, 0D8h, 070h, 000h, 070h, 0D8h, 08Ch, 08Ch, 08Ch, 0FCh, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
f90 db 018h, 030h, 000h, 0FCh, 0CCh, 0C4h, 0C0h, 0D0h, 0F0h, 0D0h, 0C0h, 0C0h, 0C4h, 0CCh, 0FCh, 000h, 000h, 000h, 000h
f91 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0D8h, 06Ch, 06Ch, 0FCh, 0B0h, 0B0h, 0B0h, 0DCh, 000h, 000h, 000h, 000h
f92 db 000h, 000h, 000h, 07Ch, 0D8h, 098h, 098h, 098h, 0FCh, 098h, 098h, 098h, 098h, 098h, 09Ch, 000h, 000h, 000h, 000h
f93 db 000h, 000h, 000h, 020h, 070h, 0D8h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f94 db 000h, 000h, 000h, 000h, 08Ch, 08Ch, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f95 db 000h, 000h, 000h, 0C0h, 060h, 030h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f96 db 000h, 000h, 000h, 060h, 0F0h, 098h, 000h, 098h, 098h, 098h, 098h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f97 db 000h, 000h, 000h, 0C0h, 060h, 030h, 000h, 098h, 098h, 098h, 098h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
f98 db 000h, 000h, 000h, 000h, 08Ch, 08Ch, 000h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0FCh, 00Ch, 00Ch, 018h, 0F0h, 000h
f99 db 08Ch, 08Ch, 000h, 070h, 0D8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0D8h, 070h, 000h, 000h, 000h, 000h
f9A db 08Ch, 08Ch, 000h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
f9B db 000h, 000h, 000h, 030h, 030h, 078h, 0CCh, 0C0h, 0C0h, 0C0h, 0C0h, 0CCh, 078h, 030h, 030h, 000h, 000h, 000h, 000h
f9C db 000h, 000h, 070h, 0D8h, 0C8h, 0C0h, 0C0h, 0E0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0CCh, 0F8h, 000h, 000h, 000h, 000h
f9D db 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 078h, 030h, 0FCh, 030h, 030h, 0FCh, 030h, 030h, 030h, 000h, 000h, 000h, 000h
f9E db 000h, 000h, 0F0h, 098h, 098h, 098h, 0F0h, 088h, 098h, 0BCh, 098h, 098h, 098h, 098h, 08Ch, 000h, 000h, 000h, 000h
f9F db 000h, 000h, 01Ch, 036h, 030h, 030h, 030h, 030h, 0FCh, 030h, 030h, 030h, 030h, 030h, 030h, 0B0h, 0E0h, 000h, 000h
fA0 db 000h, 000h, 000h, 018h, 030h, 060h, 000h, 0F0h, 018h, 018h, 0F8h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
fA1 db 000h, 000h, 000h, 018h, 030h, 060h, 000h, 070h, 030h, 030h, 030h, 030h, 030h, 030h, 078h, 000h, 000h, 000h, 000h
fA2 db 000h, 000h, 000h, 018h, 030h, 060h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
fA3 db 000h, 000h, 000h, 018h, 030h, 060h, 000h, 098h, 098h, 098h, 098h, 098h, 098h, 098h, 0ECh, 000h, 000h, 000h, 000h
fA4 db 000h, 000h, 000h, 000h, 0ECh, 0B8h, 000h, 0B8h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 000h, 000h, 000h, 000h
fA5 db 0ECh, 0B8h, 000h, 08Ch, 08Ch, 0CCh, 0CCh, 0ECh, 0ECh, 0BCh, 0BCh, 09Ch, 09Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
fA6 db 000h, 000h, 078h, 0D8h, 0D8h, 0D8h, 07Ch, 000h, 0FCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA7 db 000h, 000h, 070h, 0D8h, 0D8h, 0D8h, 070h, 000h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA8 db 000h, 000h, 000h, 060h, 060h, 000h, 060h, 060h, 060h, 0C0h, 080h, 080h, 08Ch, 08Ch, 0F8h, 000h, 000h, 000h, 000h
fA9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h, 000h, 000h
fAA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 00Ch, 00Ch, 00Ch, 00Ch, 000h, 000h, 000h, 000h, 000h, 000h
fAB db 000h, 000h, 080h, 080h, 080h, 084h, 08Ch, 098h, 030h, 060h, 0C0h, 0B8h, 04Ch, 018h, 030h, 060h, 07Ch, 000h, 000h
fAC db 000h, 000h, 080h, 080h, 080h, 084h, 08Ch, 098h, 030h, 060h, 0C0h, 098h, 038h, 078h, 0FCh, 018h, 018h, 000h, 000h
fAD db 000h, 000h, 000h, 030h, 030h, 000h, 000h, 030h, 030h, 030h, 030h, 078h, 078h, 078h, 030h, 000h, 000h, 000h, 000h
fAE db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 0CCh, 098h, 098h, 0CCh, 066h, 000h, 000h, 000h, 000h, 000h, 000h
fAF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 098h, 0CCh, 066h, 066h, 0CCh, 098h, 000h, 000h, 000h, 000h, 000h, 000h
fB0 db 022h, 088h, 022h, 088h, 022h, 088h, 022h, 088h, 022h, 088h, 022h, 088h, 022h, 088h, 022h, 088h, 022h, 088h, 022h
fB1 db 0AAh, 054h, 0AAh, 054h, 0AAh, 054h, 0AAh, 054h, 0AAh, 054h, 0AAh, 054h, 0AAh, 054h, 0AAh, 054h, 0AAh, 054h, 0AAh
fB2 db 0BAh, 0EEh, 0BAh, 0EEh, 0BAh, 0EEh, 0BAh, 0EEh, 0BAh, 0EEh, 0BAh, 0EEh, 0BAh, 0EEh, 0BAh, 0EEh, 0BAh, 0EEh, 0BAh
fB3 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fB4 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0F0h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fB5 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0F0h, 030h, 0F0h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fB6 db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 0ECh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fB7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fB8 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F0h, 030h, 0F0h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fB9 db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 0ECh, 00Ch, 0ECh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fBA db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fBB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 00Ch, 0ECh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fBC db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 0ECh, 00Ch, 0FCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBD db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 0FCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBE db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0F0h, 030h, 0F0h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F0h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fC0 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC1 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fC3 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Eh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fC4 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC5 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0FEh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fC6 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Eh, 030h, 03Eh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fC7 db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Eh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fC8 db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Eh, 060h, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 060h, 06Eh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fCA db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 0EEh, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 0EEh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fCC db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Eh, 060h, 06Eh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fCD db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCE db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 0EEh, 000h, 0EEh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fCF db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0FEh, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD0 db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD1 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 0FEh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fD2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fD3 db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD4 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Eh, 030h, 03Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Eh, 030h, 03Eh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fD6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fD7 db 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch
fD8 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0FEh, 030h, 0FEh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fD9 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0F0h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fDA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Eh, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fDB db 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh
fDC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh
fDD db 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h, 0E0h
fDE db 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh, 01Eh
fDF db 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fE0 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 0B8h, 0B0h, 0B0h, 0B0h, 0B0h, 0B8h, 0ECh, 000h, 000h, 000h, 000h
fE1 db 000h, 000h, 000h, 0F0h, 098h, 098h, 098h, 098h, 0B0h, 098h, 08Ch, 08Ch, 08Ch, 08Ch, 0B8h, 000h, 000h, 000h, 000h
fE2 db 000h, 000h, 000h, 0FCh, 08Ch, 08Ch, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 080h, 000h, 000h, 000h, 000h
fE3 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 000h, 000h, 000h, 000h
fE4 db 000h, 000h, 000h, 0FCh, 08Ch, 080h, 0C0h, 060h, 030h, 030h, 060h, 0C0h, 080h, 08Ch, 0FCh, 000h, 000h, 000h, 000h
fE5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 0B0h, 0B0h, 0B0h, 0B0h, 0B0h, 0B0h, 0E0h, 000h, 000h, 000h, 000h
fE6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0F8h, 0C0h, 0C0h, 080h, 000h
fE7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 0B8h, 030h, 030h, 030h, 030h, 030h, 030h, 000h, 000h, 000h, 000h
fE8 db 000h, 000h, 000h, 078h, 030h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 030h, 078h, 000h, 000h, 000h, 000h
fE9 db 000h, 000h, 000h, 070h, 0D8h, 08Ch, 08Ch, 08Ch, 0FCh, 08Ch, 08Ch, 08Ch, 08Ch, 0D8h, 070h, 000h, 000h, 000h, 000h
fEA db 000h, 000h, 000h, 070h, 0D8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 0D8h, 0D8h, 0D8h, 0DCh, 000h, 000h, 000h, 000h
fEB db 000h, 000h, 000h, 03Ch, 060h, 030h, 018h, 07Ch, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 000h, 000h, 000h, 000h
fEC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FCh, 0B6h, 0B6h, 0B6h, 0B6h, 0FCh, 000h, 000h, 000h, 000h, 000h, 000h
fED db 000h, 000h, 000h, 000h, 000h, 006h, 00Ch, 0FCh, 09Eh, 0B6h, 0B6h, 0E6h, 0FCh, 0C0h, 080h, 000h, 000h, 000h, 000h
fEE db 000h, 000h, 000h, 038h, 060h, 0C0h, 0C0h, 0C0h, 0F8h, 0C0h, 0C0h, 0C0h, 0C0h, 060h, 038h, 000h, 000h, 000h, 000h
fEF db 000h, 000h, 000h, 0F8h, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 08Ch, 000h, 000h, 000h, 000h
fF0 db 000h, 000h, 000h, 000h, 000h, 0FCh, 000h, 000h, 000h, 0FCh, 000h, 000h, 000h, 0FCh, 000h, 000h, 000h, 000h, 000h
fF1 db 000h, 000h, 000h, 000h, 000h, 030h, 030h, 030h, 0FCh, 030h, 030h, 030h, 000h, 000h, 0FCh, 000h, 000h, 000h, 000h
fF2 db 000h, 000h, 000h, 000h, 0C0h, 060h, 030h, 018h, 00Ch, 018h, 030h, 060h, 0C0h, 000h, 0FCh, 000h, 000h, 000h, 000h
fF3 db 000h, 000h, 000h, 000h, 00Ch, 018h, 030h, 060h, 0C0h, 060h, 030h, 018h, 00Ch, 000h, 0FCh, 000h, 000h, 000h, 000h
fF4 db 000h, 000h, 000h, 01Ch, 036h, 036h, 036h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h
fF5 db 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 0B0h, 0B0h, 0B0h, 0E0h, 000h, 000h, 000h, 000h
fF6 db 000h, 000h, 000h, 000h, 000h, 030h, 030h, 000h, 000h, 0FCh, 000h, 000h, 030h, 030h, 000h, 000h, 000h, 000h, 000h
fF7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 0B8h, 000h, 000h, 0ECh, 0B8h, 000h, 000h, 000h, 000h, 000h, 000h
fF8 db 000h, 000h, 070h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fF9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFB db 000h, 000h, 01Eh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 0D8h, 0D8h, 078h, 038h, 000h, 000h, 000h, 000h
fFC db 000h, 000h, 0B0h, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFD db 000h, 000h, 070h, 0D8h, 018h, 030h, 060h, 0C8h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFE db 000h, 000h, 000h, 000h, 000h, 0F8h, 0F8h, 0F8h, 0F8h, 0F8h, 0F8h, 0F8h, 0F8h, 0F8h, 000h, 000h, 000h, 000h, 000h
fFF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

    public GetPcFontChar

GetPcFontChar    PROC near
    push ax
    push dx
;    
    movzx ax,al
    mov dx,19
    mul dx
    movzx ebx,ax
    add ebx,OFFSET font8x19
;
    pop dx
    pop ax        
    ret
GetPcFontChar    ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetPcColor
;
;   DESCRIPTION:    Convert text-color to RGB
;
;   PARAMETERS:     AL      Color
;
;   RETURNS:        EAX     RGB value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

colortab:
ct00 DD 0000000h
ct01 DB 00000AAh
ct02 DB 000AA00h
ct03 DB 000AAAAh
ct04 DB 0AA0000h
ct05 DB 0AA00AAh
ct06 DB 0AA5500h
ct07 DB 0AAAAAAh
ct08 DB 0555555h
ct09 DB 05555FFh
ct0A DB 055FF55h
ct0B DB 055FFFFh
ct0C DB 0FF5555h
ct0D DB 0FF55FFh
ct0E DB 0FFFF55h
ct0F DB 0FFFFFFh

    public GetPcColor
    
GetPcColor  Proc near
    push ebx
    movzx ebx,al
    shl ebx,2
    mov eax,cs:[ebx].colortab
    pop ebx    
    ret
GetPcColor  Endp

code    ENDS

        END
