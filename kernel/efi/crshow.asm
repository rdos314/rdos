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
; CRSHOW.ASM
; Crash register dump
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\proc.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE ..\os\protseg.def

data    SEGMENT byte public 'DATA'

op_in_text      DB 100 DUP(?)
op_text_end     DW ?
op_size         DW ?

view_type       DB ?

curr_pos        DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn dis_ass_one:near
    
    extrn SetIpAds:near
    extrn GetOpBuf:near
    extrn GetIllegalOsGate:near
    extrn GetIllegalUserGate:near
    extrn GetOsCall:near
    extrn GetUserCall:near

    extrn LocalSetPhysicalPage:near
    extrn LocalGetSelectorBaseSize:near
    
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
;           NAME:           move_cursor
;
;           DESCRIPTION:    
;
;           PARAMETERS      CX              Column number (x)
;                           DX              Row number (y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public move_cursor
    
move_cursor Proc near
    push ds
    push ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:efi_text_row,cx
    mov ds:efi_text_col,dx    
;
    pop ax
    pop ds
    ret
move_cursor Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowChar
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowChar Proc near
    push ds
    push es
    pushad
;   
    push ax
    mov ax,system_data_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
; 
    mov ax,ds:efi_text_row
    mov cx,19
    mul cx
    add ax,4
    movzx eax,ax
    movzx edx,ds:efi_text_col
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:efi_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
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
;
    inc ds:efi_text_col
    mov ax,ds:efi_text_col
    cmp ax,80
    jne wcDone
;
    mov ds:efi_text_col,0
    inc ds:efi_text_row    

wcDone:
    popad        
    pop es
    pop ds
    ret
ShowChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InvertChar
;
;           DESCRIPTION:    CX  Col
;                           DX  Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InvertChar
    
InvertChar Proc near
    push ds
    push es
    pushad
;   
    push ax
    mov ax,system_data_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
; 
    push cx
    mov ax,dx
    mov cx,19
    mul cx
    add ax,4
    movzx eax,ax
    pop dx
    movzx edx,dx
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:efi_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
    pop ax
;
    mov cx,19

icRowLoop:    
    push cx
    push edi
    mov cx,8

icLoop:
    mov eax,es:[edi]
    not eax
    mov es:[edi],eax
    add edi,4
    loop icLoop    
;
    pop edi
    pop cx
    add edi,ds:efi_scan_size
;
    loop icRowLoop    
;
    popad        
    pop es
    pop ds
    ret
InvertChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowSizeString
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:DI       String
;                           CX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowSizeString Proc near
    push ax
    push cx
    push di
;
    or cx,cx
    jz sssDone

sssLoop:
    mov al,es:[di]
    call ShowChar
    inc di
    loop sssLoop    

sssDone:
    pop di
    pop cx
    pop ax    
    ret
ShowSizeString Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowAsciiz
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:DI       String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowAsciiz Proc near
    push ax
    push di

seaLoop:
    mov al,es:[di]
    or al,al
    jz seaDone
;
    call ShowChar
    inc di
    jmp seaLoop    

seaDone:
    pop di
    pop ax    
    ret
ShowAsciiz Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Clear
;
;           DESCRIPTION:    Clear screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Clear Proc near
    push ds
    push es
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax 
    mov ax,flat_sel
    mov es,ax
;
    mov edi,ds:efi_lfb
    mov cx,ds:efi_height

abort_clear_loop:
    push cx    
    mov ecx,ds:efi_scan_size    
    xor ax,ax
    rep stos byte ptr es:[edi]
    pop cx
    loop abort_clear_loop
;
    mov ds:efi_text_col,0
    mov ds:efi_text_row,0
;
    popad
    pop es
    pop ds    
    ret
Clear Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NewLine
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewLine Proc near
    push ds
    push ax
    push dx
;
    mov ax,system_data_sel
    mov ds,ax

nlRetry:    
    mov al,' '
    call ShowChar
;
    mov dx,ds:efi_text_col
    or dx,dx
    jnz nlRetry
;
    pop dx
    pop ax
    pop ds
    ret
NewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delimiter
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delimiter       Proc near
    push ax
    push cx
    mov cx,60
    mov al,'-'
write_delim_loop:
    call ShowChar
    loop write_delim_loop
    pop cx
    call NewLine
    pop ax
    ret
Delimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Blank
;
;           DESCRIPTION:    
;
;           PARAMETERS:         CX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Blank   Proc near
    push ax
    push cx
    mov al,' '
blank_loop:
    call ShowChar
    loop blank_loop
    pop cx
    pop ax
    ret
Blank   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Number
;                           AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

singel_hex      PROC near
hex_conv_low:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
    add al,7
ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
    add ah,7
ok_high1:
    add ah,30h
    ret
singel_hex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    PROC near
    push ax
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb write_byte_low1
    add al,7
write_byte_low1:
    add al,'0'
    call ShowChar
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb write_byte_high1
    add al,7
write_byte_high1:
    add al,'0'
    call ShowChar
    pop ax
    ret
WriteHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    PROC near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:         EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword   PROC near
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     EDX:EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexQword   PROC near
    push eax
;    
    push eax
    mov eax,edx
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
;
    mov al,'_'
    call ShowChar
;
    pop eax
;    
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
;
    pop eax    
    ret
WriteHexQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr16
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           BX          Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr16   PROC near
    push ax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov ax,bx
    call WriteHexWord
    pop ax
    ret
WriteHexPtr16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr32
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr32   PROC near
    push eax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,ebx
    call WriteHexDword
    pop eax
    ret
WriteHexPtr32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteEflags
;
;           DESCRIPTION:    
;
;           PARAMETERS:     GS      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_12   DB 0,0,0,       0,0,0
et_13   DB 0,0,0,       0,0,0
et_14   DB 'PR ' ,      'NT '
et_15   DB 0,0,0,       0,0,0
et_16   DB 0,0,0,       0,0,0
et_vm   DB 'PM ',       'VM '

iopl_text       DB ' IOPL=',0

WriteEflags     PROC near
    push es
    push di
    mov ax,cs
    mov es,ax
    mov ax,word ptr gs:cs_rflags
    and ax,200h
    shr ax,7
    or ax,word ptr gs:cs_rflags+2
    shl eax,16
    mov ax,word ptr gs:cs_rflags
    mov di,OFFSET eflags_tab
    mov cx,18
    
eflags_loop:
    mov dl,es:[di]
    or dl,dl
    je eflags_skip
    push di
    test ax,1
    jz eflags_pos_ok
    add di,3
    jmp eflags_write_one
    
eflags_pos_ok:
eflags_write_one:
    push cx
    mov cx,3
    call ShowSizeString
    pop cx
    pop di
eflags_skip:
    shr eax,1
    add di,6
    loop eflags_loop
;    
    mov di,OFFSET iopl_text
    call ShowAsciiz
    mov ax,word ptr gs:cs_rflags
    shr ax,12
    and ax,3
    add ax,'0'
    call ShowChar
    pop di
    pop es
    ret
WriteEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCore
;
;           DESCRIPTION:    Write core ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc_tab    DB 'Processor=',0    

WriteCore   PROC near
    mov di,OFFSET proc_tab
    call ShowAsciiz
    mov ax,gs:ps_id
    call WriteHexWord
;
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
;
    mov ax,gs
    call WriteHexWord
;
    mov al,')'
    call ShowChar
    mov al,' '
    call ShowChar
    ret
WriteCore   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteThread
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NoName DB 'No thread                       ', 0

WriteThread   PROC near
    push es
    push di
;    
    mov ax,gs:cs_tr
    or ax,ax
    jz wtNoThread
;    
    mov ax,gs:ps_curr_thread
    or ax,ax
    jz wtNoThread
;
    verr ax
    jnz wtNoThread
;
    mov es,ax
    mov di,OFFSET thread_name
    mov cx,32
    call ShowSizeString
    jmp wtDone

wtNoThread:
    mov ax,cs
    mov es,ax
    mov di,OFFSET NoName
    call ShowAsciiz

wtDone:
    pop di
    pop es
    ret
WriteThread Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteTable
;
;           DESCRIPTION:    Write IDT and GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

table_reg_tab:
    DB ' GDT='
    DW OFFSET cs_gdtr
    DB ' IDT='
    DW OFFSET cs_idtr
    DB 0

WriteTable   PROC near
    mov di,OFFSET table_reg_tab

table_write_loop:
    mov al,es:[di]
    or al,al
    je table_write_end
;
    mov cx,5
    call ShowSizeString
    add di,5
    mov bx,es:[di]
    mov eax,gs:[bx+2]
    call WriteHexDword
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
    mov ax,gs:[bx]
    call WriteHexWord       
    mov al,')'
    call ShowChar
;    
    add di,2
    jmp table_write_loop

table_write_end:
    ret
WriteTable   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteSel
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ES:DI       Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sel_reg_tr:
    DB ' TR='
    DW OFFSET cs_tr

sel_reg_ldt:
    DB ' DT='
    DW OFFSET cs_ldt

sel_reg_cs:
    DB ' CS='
    DW OFFSET cs_cs

sel_reg_ds:
    DB ' DS='
    DW OFFSET cs_ds

sel_reg_es:    
    DB ' ES='
    DW OFFSET cs_es

sel_reg_fs:    
    DB ' FS='
    DW OFFSET cs_fs

sel_reg_gs:
    DB ' GS='
    DW OFFSET cs_gs

sel_reg_ss:    
    DB ' SS='
    DW OFFSET cs_ss

sel_reg_us:    
    DB ' US='
    DW OFFSET cs_usel

sel_type_tab:
st00 DB 'Invalid         '
st01 DB 'TSS 16, avail   '
st02 DB 'LDT             '
st03 DB 'TSS 16, busy    '
st04 DB 'Call gate 16    '
st05 DB 'Task gate       '
st06 DB 'Int gate 16     '
st07 DB 'Trap gate 16    '
st08 DB 'Invalid         '
st09 DB 'TSS 32, avail   '
st0A DB 'Invalid         '
st0B DB 'TSS 32, busy    '
st0C DB 'Call gate 32    '
st0D DB 'Invalid         '
st0E DB 'Int gate 32     '
st0F DB 'Trap gate 32    '
st10 DB 'Read, up        '
st11 DB 'Read, up        '
st12 DB 'Read/write, up  '
st13 DB 'Read/write, up  '
st14 DB 'Read, down      '
st15 DB 'Read, down      '
st16 DB 'Read/write, down'
st17 DB 'Read/write, down'
st18 DB 'Code            '
st19 DB 'Code            '
st1A DB 'Code/read       '
st1B DB 'Code/read       '
st1C DB 'Code conf       '
st1D DB 'Code conf       '
st1E DB 'Code/read conf  ' 
st1F DB 'Code/read conf  ' 

WriteSelReg   PROC near
    mov cx,4
    call ShowSizeString
;
    add di,4
    mov bx,es:[di]
    mov bx,gs:[bx]
;    
    mov ax,bx
    call WriteHexWord
    mov al,' '
    call ShowChar
;    
    and bx,NOT 3
    or bx,bx
    jz write_sel_done
;
    test bx,4
    jz write_sel_gdt

write_sel_ldt:
    jmp write_sel_done      ; doesn't work yet

    mov si,gs:cs_ldt
    or si,si
    jz write_sel_done
;
    test si,4
    jnz write_sel_done
;
    push bx
    mov bx,cx
    call LocalGetSelectorBaseSize
    pop bx        
    jc write_sel_done
;
    dec ecx    
    jmp write_sel_do

write_sel_gdt:
    movzx ecx,word ptr gs:cs_gdtr
    mov edx,dword ptr gs:cs_gdtr+2

write_sel_do:
    and bx,0FFF8h
    cmp bx,cx
    ja write_sel_done
;
    mov ax,flat_sel
    mov ds,ax
    movzx ebx,bx
    add ebx,edx
;
    mov al,[ebx+5]
    test al,80h
    jz write_sel_done
;
    xor ecx,ecx
    mov cl,[ebx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[ebx]
    test byte ptr [ebx+6],80h
    jz write_sel_small
;
    shl ecx,12
    or cx,0FFFh

write_sel_small:
    mov edx,[ebx+2]
    rol edx,8
    mov dl,[ebx+7]
    ror edx,8
;
    mov eax,edx
    call WriteHexDword
;
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
;
    mov eax,ecx
    call WriteHexDword
;
    mov al,')'
    call ShowChar    
    mov al,' '
    call ShowChar
;
    push di
    mov al,[ebx+5]
    and al,1Fh
    movzx di,al
    shl di,4
    add di,OFFSET sel_type_tab
    mov cx,16
    call ShowSizeString
    pop di

write_sel_done:
    ret
WriteSelReg   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDwordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ES:DI       Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_irq_tab:
    DB ' IRQ='
    DW OFFSET cs_irq
    DW 0

dword_cr_reg_tab:
    DB ' CR0='
    DW OFFSET cs_cr0
    DB ' CR2='
    DW OFFSET cs_cr2
    DB ' CR3='
    DW OFFSET cs_cr3
    DB ' CR4='
    DW OFFSET cs_cr4
    DB 0

dword_dr_reg_tab:
    DB ' DR0='
    DW OFFSET cs_dr0
    DB ' DR1='
    DW OFFSET cs_dr1
    DB ' DR2='
    DW OFFSET cs_dr2
    DB ' DR3='
    DW OFFSET cs_dr3
    DB 0

dword_reg_tab1:
    DB ' EAX='
    DW OFFSET cs_rax
    DB ' EBX='
    DW OFFSET cs_rbx
    DB ' ECX='
    DW OFFSET cs_rcx
    DB ' EDX='
    DW OFFSET cs_rdx
    DB 0

dword_reg_tab2:
    DB ' ESI='
    DW OFFSET cs_rsi
    DB ' EDI='
    DW OFFSET cs_rdi
    DB ' ESP='
    DW OFFSET cs_rsp
    DB ' EBP='
    DW OFFSET cs_rbp
    DB 0

dword_reg_tab3:
    DB ' EPC='
    DW OFFSET cs_rip
    DB 0

WriteDwordRegs  PROC near
dword_write_loop:
    mov al,es:[di]
    or al,al
    je dword_write_end
    mov cx,5
    call ShowSizeString
    add di,5
    mov bx,es:[di]
    mov eax,gs:[bx]
    call WriteHexDword
    add di,2
    jmp dword_write_loop
dword_write_end:
    ret
WriteDwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteQwordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:DI       Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

qword_reg_tab1:
    DB ' RAX='
    DW OFFSET cs_rax
    DB ' RBX='
    DW OFFSET cs_rbx
    DB ' RCX='
    DW OFFSET cs_rcx
    DB 0

qword_reg_tab2:
    DB ' RDX='
    DW OFFSET cs_rdx
    DB ' RSI='
    DW OFFSET cs_rsi
    DB ' RDI='
    DW OFFSET cs_rdi
    DB 0

qword_reg_tab3:
    DB '  R8='
    DW OFFSET cs_r8
    DB '  R9='
    DW OFFSET cs_r9
    DB ' R10='
    DW OFFSET cs_r10
    DB 0

qword_reg_tab4:
    DB ' R11='
    DW OFFSET cs_r11
    DB ' R12='
    DW OFFSET cs_r12
    DB ' R13='
    DW OFFSET cs_r13
    DB 0

qword_reg_tab5:
    DB ' R14='
    DW OFFSET cs_r14
    DB ' R15='
    DW OFFSET cs_r15
    DB 0

qword_reg_tab6:
    DB ' RIP='
    DW OFFSET cs_rip
    DB ' RSP='
    DW OFFSET cs_rsp
    DB ' RBP='
    DW OFFSET cs_rbp
    DB 0

WriteQwordRegs  PROC near
qword_write_loop:
    mov al,es:[di]
    or al,al
    je qword_write_end
    mov cx,5
    call ShowSizeString
    add di,5
    mov bx,es:[di]
    mov eax,gs:[bx]
    mov edx,gs:[bx+4]
    call WriteHexQword
    add di,2
    jmp qword_write_loop
qword_write_end:
    ret
WriteQwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFault
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error            '
ke01    DB 'Single step             '
ke02    DB 'NMI                     '
ke03    DB 'Breakpoint              '
ke04    DB 'Overflow                '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code         '
ke07    DB '80387 not present       '
ke08    DB 'Double fault            '
ke09    DB '80387 overrun           '
ke0A    DB 'Invalid TSS             '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault             '
ke0D    DB 'Protection fault        '
ke0E    DB 'Page fault              '
ke0F    DB '                        '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '
ke19    DB 'NMI                     '
ke1A    DB 'Crash Gate              '

WriteFault    Proc near
    mov al,' '
    call ShowChar
;    
    mov edx,gs:cs_fault
    cmp dx,1Ah
    jbe wfDo
;
    mov dx,14h    

wfDo:
    mov bx,dx
    add bx,bx
    add bx,bx
    add bx,bx
    mov cx,bx
    add cx,cx
    add bx,cx
    mov ax,cs
    mov es,ax
    mov di,OFFSET error_code_tab
    add di,bx
    mov cx,24
    call ShowSizeString
    ret
WriteFault    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteProcFlags
;
;           DESCRIPTION:    Write processor flag registers
;
;           PARAMETERS:     GS      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nest_text       DB 'Nesting=',0
flag_preempt    DB 'Preempt ',0
flag_prio       DB 'Prio ',0
flag_timer      DB 'Timer ',0

WriteProcFlags     PROC near
    push fs
;    
    mov ax,cs
    mov es,ax
    mov di,OFFSET nest_text
    call ShowAsciiz
    mov ax,gs:ps_nesting
    call WriteHexWord
;
    mov al,' '
    call ShowChar
;
    test gs:ps_flags,PS_FLAG_PREEMPT
    jz wpfNoPreempt
;
    mov di, OFFSET flag_preempt
    call ShowAsciiz

wpfNoPreempt:    
    test gs:ps_flags,PS_FLAG_PRIO_CHANGE
    jz wpfNoPrio
;
    mov di, OFFSET flag_prio
    call ShowAsciiz

wpfNoPrio:
    pop fs
    ret
WriteProcFlags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBaseSize
;
;           DESCRIPTION:    
;
;           PARAMETERS:     GS          Core regs
;                           BX:EDX      Address
;
;           RETURNS:        NC
;                               EDX     Base
;                               ECX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBaseSize   PROC near
    push eax
    push ebx
    push esi
    push edi
;
    mov edi,edx 
;       
    and bx,NOT 3
    or bx,bx
    jz get_info_fail
;
    test bx,4
    jz get_info_gdt

get_info_ldt:
    mov si,gs:cs_ldt
    or si,si
    jz get_info_fail
;
    test si,4
    jnz get_info_fail
;
    push bx
    mov bx,si
    call LocalGetSelectorBaseSize
    pop bx        
    jc get_info_fail
;
    dec ecx    
    jmp get_info_do

get_info_gdt:
    movzx ecx,word ptr gs:cs_gdtr
    mov edx,dword ptr gs:cs_gdtr+2

get_info_do:
    and bx,0FFF8h
    cmp bx,cx
    ja get_info_fail
;
    mov ax,flat_sel
    mov ds,ax
    movzx ebx,bx
    add ebx,edx
;
    mov al,[ebx+5]
    test al,80h
    jz get_info_fail
;
    xor ecx,ecx
    mov cl,[ebx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[ebx]
    test byte ptr [ebx+6],80h
    jz get_info_small
;
    shl ecx,12
    or cx,0FFFh

get_info_small:
    mov edx,[ebx+2]
    rol edx,8
    mov dl,[ebx+7]
    ror edx,8
;
    sub ecx,edi
    jc get_info_fail
;
    add edx,edi
    clc
    jmp get_info_done

get_info_fail:
    stc

get_info_done:
    pop edi
    pop esi
    pop ebx
    pop eax
    ret
GetBaseSize   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBitness
;
;           DESCRIPTION:    
;
;           PARAMETERS:     GS          Core regs
;                           BX          Selector
;
;           RETURNS:        NC
;                               DL      Bitness (0 = 16, 1 = 32)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBitness   PROC near
    push ds
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    and bx,NOT 3
    or bx,bx
    jz get_bitness_fail
;
    test bx,4
    jz get_bitness_gdt

get_bitness_ldt:
    mov si,gs:cs_ldt
    or si,si
    jz get_bitness_fail
;
    test si,4
    jnz get_bitness_fail
;
    push bx
    mov bx,si
    call LocalGetSelectorBaseSize
    pop bx        
    jc get_bitness_fail
;
    dec ecx    
    jmp get_bitness_do

get_bitness_gdt:
    movzx ecx,word ptr gs:cs_gdtr
    mov edx,dword ptr gs:cs_gdtr+2

get_bitness_do:
    and bx,0FFF8h
    cmp bx,cx
    ja get_bitness_fail
;
    mov ax,flat_sel
    mov ds,ax
    movzx ebx,bx
    add ebx,edx
;
    mov dl,ds:[ebx+6]
    shr dl,6
    and dl,1
    clc
    jmp get_bitness_done
    
get_bitness_fail:
    stc

get_bitness_done:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
GetBitness   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadData
;
;       DESCRIPTION:    Read data item
;
;       PARAMETERS:     GS              Core regs
;                       EDX             Linear address
;
;       RETURNS:        NC
;                           AL  Data
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadData        Proc near
    push ds
    push ebx
;
    mov ebx,gs:cs_cr3
    mov cr3,ebx
;
    mov ebx,cr4
    test bx,20h
    jnz rd64

rd32:    
    mov bx,process_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,20
    and bl,0FCh
    mov eax,[bx]
    test al,1
    stc
    jz rdDone
;
    mov bx,process_page_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,10
    and bl,0FCh
    mov eax,[ebx]
    test al,1
    stc
    jz rdDone
;
    mov bx,flat_sel
    mov ds,bx
    mov al,[edx]
    clc
    jmp rdDone

rd64:    
    mov bx,process_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,18
    and bl,0F8h
    mov eax,[bx]
    test al,1
    stc
    jz rdDone
;
    mov bx,process_page_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,9
    and bl,0F8h
    mov eax,[ebx]
    test al,1
    stc
    jz rdDone
;
    mov bx,flat_sel
    mov ds,bx
    mov al,[edx]
    clc
    jmp rdDone

rdDone:
    pop ebx
    pop ds
    ret        
ReadData        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteDataRow
;
;       DESCRIPTION:    Write a data row
;
;       PARAMETERS:     GS          Core regs
;                       BX:EDX      Address
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow    Proc near
    mov ax,bx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,edx
    call WriteHexDword
    mov al,' '
    call ShowChar
;
    push bx
    push edx
;    
    mov bp,16
    call GetBaseSize
    jc wdrDataInv

wdrDataLoop:
    call ReadData
    jc wdrDataUndef
;
    call WriteHexByte
    jmp wdrDataNext

wdrDataUndef:
    mov al,'%'
    call ShowChar
    call ShowChar

wdrDataNext:
    mov al,' '
    call ShowChar
;
    sub bp,1
    jz wdrChar
;
    add edx,1
    sub ecx,1
    jnc wdrDataLoop            

wdrDataInv:
    mov al,'!'
    call ShowChar
    call ShowChar
    mov al,' '
    call ShowChar
;
    sub bp,1
    jnz wdrDataInv

wdrChar:  
    pop edx
    pop bx
;    
    mov bp,16
    call GetBaseSize
    jc wdrCharInv

wdrCharLoop:
    call ReadData
    jnc wdrCharDo
;
    mov al,'%'

wdrCharDo:    
    call ShowChar
;
    add edx,1
    sub ecx,1
    jc wdrCharInv
;    
    sub bp,1
    jnz wdrCharLoop            
    jmp wdrDone

wdrCharInv:
    mov al,'!'
    call ShowChar
;
    sub bp,1
    jnz wdrCharInv

wdrDone:  
    ret
WriteDataRow    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMne
;
;       DESCRIPTION:    Get instruction text
;
;       PARAMETERS:     GS          Core regs
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


GetMne  PROC near
    push si
    push di
;    
    mov ax,SEG data
    mov ds,ax
    xor dh,dh
;
    mov bx,gs:cs_cs
    call GetBitness
    jc get_mne_done
;   
    mov di,OFFSET op_in_text
    call GetOpBuf
;
    mov bp,si

remove_ov_loop:
    mov al,[si]
    cmp al,66h
    je remove_ads16
;
    cmp al,67h
    jne remove_ov_done
;    
    inc dh
    inc si
    jmp remove_ov_loop

remove_ads16:
    inc dh
    inc si
    xor dl,1
    jmp remove_ov_loop

remove_ov_done:
    mov al,[si]
    cmp al,9Ah
    jne not_call_far
;
    test dl,1
    jz write_call_far16
;
    mov dx,[si+5]
    cmp dx,2
    je oscall
;        
    cmp dx,3
    je usercall_32
;
    cmp dx,1
    jne not_call32

usercall_32:
    mov eax,[si+1]
    cmp eax,usergate_entries
    jnc write_special_fail
;
    shl eax,5
    mov ebx,eax
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetIllegalUserGate
    mov ds:op_size,bx
    clc
    jmp write_special_end

oscall:
    mov eax,[si+1]
    cmp eax,osgate_entries
    jnc write_special_fail
;
    shl eax,4
    mov ebx,eax
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetIllegalOsGate
    mov ds:op_size,bx
    clc
    jmp write_special_end
    
not_call32:
    mov bx,[si+1]
    mov dx,[si+5]
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    jnc write_special_end
;
    mov bx,[si+1]
    mov dx,[si+5]
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

write_call_far16:
    mov bx,[si+1]
    mov dx,[si+3]
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    jnc write_special_end
;
    mov bx,[si+1]
    mov dx,[si+3]
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

not_call_far:
    cmp al,0E8h
    jne write_special_fail
;
    test dl,1
    jz write_call_near16
;
    inc si
    inc dh    
    movzx ebx,dh
    add ebx,[si]
    add ebx,dword ptr gs:cs_rip
    add ebx,4
;
    push ebx
    mov dx,gs:cs_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    pop ebx
    jnc write_special_end
;
    mov dx,gs:cs_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end
    
write_call_near16:
    inc si
    inc dh
    movzx bx,dh
    add bx,[si]
    add bx,word ptr gs:cs_rip
    add bx,2
    push bx
    mov dx,gs:cs_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    pop bx
    jnc write_special_end
;
    mov dx,gs:cs_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

write_special_fail:
    stc

write_special_end:
        
get_mne_done:
    pop di
    pop si
    ret
GetMne  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetInstr
;
;       DESCRIPTION:    Fill instruction buffer
;
;       PARAMETERS:     GS          Core regs
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadInstr    Proc near
    mov dx,word ptr gs:cs_rip+4
    mov ebx,dword ptr gs:cs_rip
    call SetIpAds
;    
    mov dx,gs:p_cs
    call GetOpBuf
;
    mov bx,gs:cs_cs
    mov edx,dword ptr gs:cs_rip
;    
    call GetBaseSize
    jc read_instr_done
;    
    add ecx,1
    jc read_instr_full
;
    cmp ecx,16
    jb read_instr_loop

read_instr_full:
    mov ax,SEG data
    mov ds,ax
;    
    mov cx,16

read_instr_loop:
    call ReadData
    mov [si],al    
    inc edx
    inc si
    loop read_instr_loop
    clc

read_instr_done:
    ret
ReadInstr    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteInstr
;
;       DESCRIPTION:    Write instruction
;
;       PARAMETERS:     GS          Core regs
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr  Proc near
    push ds
    push es
    push fs
    pushad
;
    mov al,' '
    call ShowChar
;
    call ReadInstr
    jc write_instr_done
;
    call GetMne    
    jnc write_instr_do
;    
    mov bx,gs:cs_cs
    call GetBitness
    jc write_instr_done
;
    mov ax,SEG data
    mov ds,ax
    mov di,OFFSET op_in_text    
    call dis_ass_one
;
    mov ds:op_size,80

write_instr_do:
    mov ax,SEG data
    mov es,ax
    mov cx,40
    mov di,OFFSET op_in_text
    call ShowSizeString

write_instr_done:
    popad
    pop fs
    pop es
    pop ds 
    ret   
WriteInstr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpuReg32
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg32     Proc near
    push es
    mov ax,cs
    mov es,ax
;
    call WriteCore
    call WriteThread
    call NewLine    
;
    call WriteTable
    mov di,OFFSET dword_irq_tab
    call WriteDwordRegs
    call NewLine    
;
    mov di,OFFSET dword_cr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET dword_dr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET dword_reg_tab1
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET dword_reg_tab2
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET dword_reg_tab3
    call WriteDwordRegs
    call WriteFault
    call WriteInstr
    call NewLine
;
    mov di,OFFSET sel_reg_tr
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ldt
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_cs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ds
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_es
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_fs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_gs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ss
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_us
    call WriteSelReg
    call NewLine
;
    call WriteEflags
    call NewLine
;
    call WriteProcFlags
    call NewLine
;
    call Delimiter
;    
    mov bx,gs:cs_ss
    movzx edx,word ptr gs:cs_rsp
    call WriteDataRow
    call NewLine    
;    
    mov bx,gs:cs_cs
    movzx edx,word ptr gs:cs_rip
    call WriteDataRow
    call NewLine    
;    
    mov bx,gs:cs_usel
    mov edx,gs:cs_uoffs
    call WriteDataRow
    call NewLine    
    pop es
    ret
WriteCpuReg32     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpuReg64
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg64     Proc near
    push es
    mov ax,cs
    mov es,ax
;
    call WriteCore
    call WriteThread
    call NewLine    
;
    call WriteTable
    mov di,OFFSET dword_irq_tab
    call WriteDwordRegs
    call NewLine    
;
    mov di,OFFSET dword_cr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab1
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab2
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab3
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab4
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab5
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab6
    call WriteQwordRegs
    call NewLine
;
    call WriteFault
    call WriteInstr
    call NewLine
;
    mov di,OFFSET sel_reg_tr
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ldt
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_cs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ds
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_es
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_fs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_gs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ss
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_us
    call WriteSelReg
    call NewLine
;
    call WriteEflags
    call NewLine
;
    call WriteProcFlags
    call NewLine
;
    call Delimiter
;    
    mov bx,gs:cs_ss
    movzx edx,word ptr gs:cs_rsp
    call WriteDataRow
    call NewLine    
;    
    mov bx,gs:cs_cs
    movzx edx,word ptr gs:cs_rip
    call WriteDataRow
    call NewLine    
;    
    mov bx,gs:cs_usel
    mov edx,gs:cs_uoffs
    call WriteDataRow
    call NewLine    
    pop es
    ret
WriteCpuReg64     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteOneThread
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES      Thread
;                           AX      Prio
;                           DI      State offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteOneThread   PROC near
    push es
    push ax
    push ebx
    push cx
    push dx
    push di
;    
    call WriteHexWord
;
    mov al,':'
    call ShowChar
;
    mov al,' '
    call ShowChar
;            
    mov di,OFFSET thread_name
    mov cx,32
    call ShowSizeString
;
    mov al,' '
    call ShowChar
;    
    mov dx,es:p_cs
    mov ebx,dword ptr es:p_rip
    call WriteHexPtr32
;
    pop di
;
    mov ax,cs
    mov es,ax
    call ShowAsciiz
    call NewLine
;    
    pop dx
    pop cx
    pop ebx
    pop ax
    pop es
    ret
WriteOneThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCoreThreads
;
;           DESCRIPTION:    Write all threads active on core
;
;           PARAMETERS:     GS      Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

null_thread_name        DB ' Null',0
curr_thread_name        DB ' Curr',0
ready_thread_name       DB ' Rdy ',0
wake_thread_name        DB ' Wake',0

WriteCoreThreads   PROC near
    push es
    mov ax,cs
    mov es,ax
;
    call WriteCore
    call WriteThread
    call NewLine    
;
    mov ax,gs:ps_null_thread
    mov es,ax
    xor ax,ax
    mov di,OFFSET null_thread_name
    call WriteOneThread
;
    mov si,OFFSET ps_ptab
    mov cx,256
    xor ax,ax

wctLoop:
    mov bx,gs:[si]
    or bx,bx
    jz wctNext
;
    mov es,bx
    mov di,OFFSET ready_thread_name
    call WriteOneThread

wctListLoop:    
    mov dx,es:p_next
    cmp bx,dx
    je wctNext
;
    mov es,dx
    mov di,OFFSET ready_thread_name
    call WriteOneThread
    jmp wctListLoop    

wctNext:
    inc ax
    add si,2
    loop wctLoop
;
    mov bx,gs:ps_wakeup_list
    or bx,bx
    jz wcwDone
;
    mov es,bx
    mov ax,es:p_prio
    shr ax,1
    mov di,OFFSET wake_thread_name
    call WriteOneThread

wcwListLoop:    
    mov dx,es:p_next
    cmp bx,dx
    je wcwDone
;
    mov es,dx
    mov ax,es:p_prio
    shr ax,1
    mov di,OFFSET wake_thread_name
    call WriteOneThread
    jmp wcwListLoop    

wcwDone:
    mov ax,gs:ps_curr_thread
    or ax,ax
    jz wctDone
;  
    cmp ax,gs:ps_null_thread
    je wctDone
;      
    mov es,ax
    mov ax,es:p_prio
    shr ax,1
    mov di,OFFSET curr_thread_name
    call WriteOneThread

wctDone:
    pop es
    ret
WriteCoreThreads    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetViewType
;
;           DESCRIPTION:    
;
;           PARAMETERS:     AL      View type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetViewType
    
SetViewType    Proc near
    push ds
    push bx
    mov bx,SEG data
    mov ds,bx
    mov ds:view_type,al
    pop bx
    pop ds
    ret
SetViewType Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCrashCore
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ShowCrashCore
    
ShowCrashCore    Proc near
    push ds
    mov ax,SEG data
    mov ds,ax
    call Clear
;

sccCore:    
    mov al,ds:view_type
    cmp al,'R'
    je sccRegs
;
    call WriteCoreThreads
    jmp sccDone
        
sccRegs:        
    test gs:ps_flags,PS_FLAG_LONG_MODE
    jz scc32

scc64:
    call WriteCpuReg64
    jmp sccDone

scc32:    
    call WriteCpuReg32

sccDone:
    pop ds
    ret
ShowCrashCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitCrashShow
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitCrashShow

InitCrashShow    Proc near
    push ds
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_pos,0
    mov ds:view_type,'R'
;        
    popad
    pop ds
    ret
InitCrashShow    Endp

code    ENDS

    END
