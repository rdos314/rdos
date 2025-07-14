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
; EMULATE.ASM
; Main module of instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                

include ..\os\protseg.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\system.def
include ..\os\int.def

        .386p

include emulate.inc
include emcom.inc
include emseg.inc
include emarithm.inc
include emtrans.inc
include emcontr.inc
include emstring.inc
include emprot.inc
include em387.inc

code    SEGMENT byte public use16 'CODE'

        assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmNop
;
;               DESCRIPTION:    nop
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmNop   Proc near
        ret
EmNop   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmHlt
;
;               DESCRIPTION:    hlt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmHlt   Proc near
        hlt
        ret
EmHlt   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOverrideData
;
;               DESCRIPTION:    change size of data between 16 & 32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideData:
        xor byte ptr [ebp].em_flags,d32
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOverrideAdr
;
;               DESCRIPTION:    change size of address between 16 & 32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideAdr:
        xor byte ptr [ebp].em_flags,a32
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOverrideCs
;
;               DESCRIPTION:    Use cs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideCs:
        mov byte ptr [ebp].em_sreg,seg_cs
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOverrideSS
;
;               DESCRIPTION:    Use ss for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideSs:
        mov byte ptr [ebp].em_sreg,seg_ss
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOverrideDS
;
;               DESCRIPTION:    Use ds for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideDs:
        mov byte ptr [ebp].em_sreg,seg_ds
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOverrideES
;
;               DESCRIPTION:    Use es for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideEs:
        mov byte ptr [ebp].em_sreg,seg_es
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOverrideFS
;
;               DESCRIPTION:    Use fs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideFs:
        mov byte ptr [ebp].em_sreg,seg_fs
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOverrideGS
;
;               DESCRIPTION:    Use gs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideGs:
        mov byte ptr [ebp].em_sreg,seg_gs
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmREPE
;
;               DESCRIPTION:    EMULATE repe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmRepe:
        or byte ptr [ebp].em_flags,rep_z
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmREPNE
;
;               DESCRIPTION:    EMULATE repne
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmRepne:
        or byte ptr [ebp].em_flags,rep_nz
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmulateTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM0F00
;
;               DESCRIPTION:    EMULATE 0F00 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0F00Tab:
em0F00_000      DW OFFSET EmSldtMem
em0F00_001      DW OFFSET EmStrMem
em0F00_010      DW OFFSET EmLldtMem
em0F00_011      DW OFFSET EmLtrMem
em0F00_100      DW OFFSET EmVerrMem
em0F00_101      DW OFFSET EmVerwMem
em0F00_110      DW OFFSET EmulateError
em0F00_111      DW OFFSET EmulateError

Em0F00:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].Em0F00Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM0F01
;
;               DESCRIPTION:    EMULATE 0F01 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0F01Tab:
em0F01_000      DW OFFSET EmSgdtMem
em0F01_001      DW OFFSET EmSidtMem
em0F01_010      DW OFFSET EmLgdtMem
em0F01_011      DW OFFSET EmLidtMem
em0F01_100      DW OFFSET EmSmswMem
em0F01_101      DW OFFSET EmulateError
em0F01_110      DW OFFSET EmLmswMem
em0F01_111      DW OFFSET EmulateError

Em0F01:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].Em0F01Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM0FBA
;
;               DESCRIPTION:    EMULATE 0FBA instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0FBATab:
em0FBA_000      DW OFFSET EmulateError
em0FBA_001      DW OFFSET EmulateError
em0FBA_010      DW OFFSET EmulateError
em0FBA_011      DW OFFSET EmulateError
em0FBA_100      DW OFFSET EmBtImMem
em0FBA_101      DW OFFSET EmBtsImMem
em0FBA_110      DW OFFSET EmBtrImMem
em0FBA_111      DW OFFSET EmBtcImMem

Em0FBA:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].Em0FBATab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM0F
;
;               DESCRIPTION:    EMULATE 0F instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0FTab:
tem0F00 DW OFFSET Em0F00,                               OFFSET Em0F01
tem0F02 DW OFFSET EmLarRegMem,                  OFFSET EmLslRegMem
tem0F04 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F06 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F08 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F0A DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F0C DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F0E DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F10 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F12 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F14 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F16 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F18 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F1A DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F1C DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F1E DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F20 DW OFFSET EmMoveRegCr,                  OFFSET EmMoveRegDr
tem0F22 DW OFFSET EmMoveCrReg,                  OFFSET EmMoveDrReg
tem0F24 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F26 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F28 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F2A DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F2C DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F2E DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F30 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F32 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F34 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F36 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F38 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F3A DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F3C DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F3E DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F40 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F42 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F44 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F46 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F48 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F4A DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F4C DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F4E DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F50 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F52 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F54 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F56 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F58 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F5A DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F5C DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F5E DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F60 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F62 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F64 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F66 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F68 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F6A DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F6C DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F6E DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F70 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F72 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F74 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F76 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F78 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F7A DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F7C DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F7E DW OFFSET EmulateError,                 OFFSET EmulateError
tem0F80 DW OFFSET EmJoNear,                             OFFSET EmJnoNear
tem0F82 DW OFFSET EmJbNear,                             OFFSET EmJnbNear
tem0F84 DW OFFSET EmJeNear,                             OFFSET EmJneNear
tem0F86 DW OFFSET EmJbeNear,                    OFFSET EmJnbeNear
tem0F88 DW OFFSET EmJsNear,                             OFFSET EmJnsNear
tem0F8A DW OFFSET EmJpNear,                             OFFSET EmJnpNear
tem0F8C DW OFFSET EmJlNear,                             OFFSET EmJnlNear
tem0F8E DW OFFSET EmJleNear,                    OFFSET EmJnleNear
tem0F90 DW OFFSET EmSeto,                               OFFSET EmSetno
tem0F92 DW OFFSET EmSetb,                               OFFSET EmSetnb
tem0F94 DW OFFSET EmSete,                               OFFSET EmSetne
tem0F96 DW OFFSET EmSetbe,                              OFFSET EmSetnbe
tem0F98 DW OFFSET EmSets,                               OFFSET EmSetns
tem0F9A DW OFFSET EmSetp,                               OFFSET EmSetnp
tem0F9C DW OFFSET EmSetl,                               OFFSET EmSetnl
tem0F9E DW OFFSET EmSetle,                              OFFSET EmSetnle
tem0FA0 DW OFFSET EmPushFs,                             OFFSET EmPopFs
tem0FA2 DW OFFSET EmulateError,                 OFFSET EmBtMemReg
tem0FA4 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FA6 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FA8 DW OFFSET EmPushGs,                             OFFSET EmPopGs
tem0FAA DW OFFSET EmulateError,                 OFFSET EmBtsMemReg
tem0FAC DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FAE DW OFFSET EmulateError,                 OFFSET EmImulWordRegMem
tem0FB0 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FB2 DW OFFSET EmLss,                                OFFSET EmBtrMemReg
tem0FB4 DW OFFSET EmLfs,                                OFFSET EmLgs
tem0FB6 DW OFFSET EmMovzxByteMem,               OFFSET EmMovzxWordMem
tem0FB8 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FBA DW OFFSET Em0FBA,                               OFFSET EmBtcMemReg
tem0FBC DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FBE DW OFFSET EmMovsxByteMem,               OFFSET EmMovsxWordMem
tem0FC0 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FC2 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FC4 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FC6 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FC8 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FCA DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FCC DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FCE DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FD0 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FD2 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FD4 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FD6 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FD8 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FDA DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FDC DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FDE DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FE0 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FE2 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FE4 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FE6 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FE8 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FEA DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FEC DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FEE DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FF0 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FF2 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FF4 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FF6 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FF8 DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FFA DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FFC DW OFFSET EmulateError,                 OFFSET EmulateError
tem0FFE DW OFFSET EmulateError,                 OFFSET EmulateError

Em0F:
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].Em0FTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM80
;
;               DESCRIPTION:    EMULATE 80 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em80Tab:
em80_000        DW OFFSET EmAddByteImMem
em80_001        DW OFFSET EmOrByteImMem
em80_010        DW OFFSET EmAdcByteImMem
em80_011        DW OFFSET EmSbbByteImMem
em80_100        DW OFFSET EmAndByteImMem
em80_101        DW OFFSET EmSubByteImMem
em80_110        DW OFFSET EmXorByteImMem
em80_111        DW OFFSET EmCmpByteImMem

Em80:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].Em80Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM81
;
;               DESCRIPTION:    EMULATE 81 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em81Tab:
em81_000        DW OFFSET EmAddWordImMem
em81_001        DW OFFSET EmOrWordImMem
em81_010        DW OFFSET EmAdcWordImMem
em81_011        DW OFFSET EmSbbWordImMem
em81_100        DW OFFSET EmAndWordImMem
em81_101        DW OFFSET EmSubWordImMem
em81_110        DW OFFSET EmXorWordImMem
em81_111        DW OFFSET EmCmpWordImMem

Em81:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].Em81Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM82
;
;               DESCRIPTION:    EMULATE 82 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em82Tab:
em82_000        DW OFFSET EmAddByteImMem
em82_001        DW OFFSET EmOrByteImMem
em82_010        DW OFFSET EmAdcByteImMem
em82_011        DW OFFSET EmSbbByteImMem
em82_100        DW OFFSET EmAndByteImMem
em82_101        DW OFFSET EmSubByteImMem
em82_110        DW OFFSET EmXorByteImMem
em82_111        DW OFFSET EmCmpByteImMem

Em82:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].Em82Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM83
;
;               DESCRIPTION:    EMULATE 83 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em83Tab:
em83_000        DW OFFSET EmAddWordImsxMem
em83_001        DW OFFSET EmOrWordImsxMem
em83_010        DW OFFSET EmAdcWordImsxMem
em83_011        DW OFFSET EmSbbWordImsxMem
em83_100        DW OFFSET EmAndWordImsxMem
em83_101        DW OFFSET EmSubWordImsxMem
em83_110        DW OFFSET EmXorWordImsxMem
em83_111        DW OFFSET EmCmpWordImsxMem

Em83:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].Em83Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EM8F
;
;               DESCRIPTION:    EMULATE 8F instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em8FTab:
em8F_000        DW OFFSET EmPopMem
em8F_001        DW OFFSET EmulateError
em8F_010        DW OFFSET EmulateError
em8F_011        DW OFFSET EmulateError
em8F_100        DW OFFSET EmulateError
em8F_101        DW OFFSET EmulateError
em8F_110        DW OFFSET EmulateError
em8F_111        DW OFFSET EmulateError

Em8F:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].Em8FTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMC0
;
;               DESCRIPTION:    EMULATE C0 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmC0Tab:
emC0_000        DW OFFSET EmRolByteMemIm
emC0_001        DW OFFSET EmRorByteMemIm
emC0_010        DW OFFSET EmRclByteMemIm
emC0_011        DW OFFSET EmRcrByteMemIm
emC0_100        DW OFFSET EmShlByteMemIm
emC0_101        DW OFFSET EmShrByteMemIm
emC0_110        DW OFFSET EmulateError
emC0_111        DW OFFSET EmSarByteMemIm

EmC0:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmC0Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMC1
;
;               DESCRIPTION:    EMULATE C1 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmC1Tab:
emC1_000        DW OFFSET EmRolWordMemIm
emC1_001        DW OFFSET EmRorWordMemIm
emC1_010        DW OFFSET EmRclWordMemIm
emC1_011        DW OFFSET EmRcrWordMemIm
emC1_100        DW OFFSET EmShlWordMemIm
emC1_101        DW OFFSET EmShrWordMemIm
emC1_110        DW OFFSET EmulateError
emC1_111        DW OFFSET EmSarWordMemIm

EmC1:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmC1Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMD0
;
;               DESCRIPTION:    EMULATE D0 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD0Tab:
emD0_000        DW OFFSET EmRolByteMem1
emD0_001        DW OFFSET EmRorByteMem1
emD0_010        DW OFFSET EmRclByteMem1
emD0_011        DW OFFSET EmRcrByteMem1
emD0_100        DW OFFSET EmShlByteMem1
emD0_101        DW OFFSET EmShrByteMem1
emD0_110        DW OFFSET EmulateError
emD0_111        DW OFFSET EmSarByteMem1

EmD0:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmD0Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMD1
;
;               DESCRIPTION:    EMULATE D1 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD1Tab:
emD1_000        DW OFFSET EmRolWordMem1
emD1_001        DW OFFSET EmRorWordMem1
emD1_010        DW OFFSET EmRclWordMem1
emD1_011        DW OFFSET EmRcrWordMem1
emD1_100        DW OFFSET EmShlWordMem1
emD1_101        DW OFFSET EmShrWordMem1
emD1_110        DW OFFSET EmulateError
emD1_111        DW OFFSET EmSarWordMem1

EmD1:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmD1Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMD2
;
;               DESCRIPTION:    EMULATE D2 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD2Tab:
emD2_000        DW OFFSET EmRolByteMemCl
emD2_001        DW OFFSET EmRorByteMemCl
emD2_010        DW OFFSET EmRclByteMemCl
emD2_011        DW OFFSET EmRcrByteMemCl
emD2_100        DW OFFSET EmShlByteMemCl
emD2_101        DW OFFSET EmShrByteMemCl
emD2_110        DW OFFSET EmulateError
emD2_111        DW OFFSET EmSarByteMemCl

EmD2:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmD2Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMD3
;
;               DESCRIPTION:    EMULATE D3 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD3Tab:
emD3_000        DW OFFSET EmRolWordMemCl
emD3_001        DW OFFSET EmRorWordMemCl
emD3_010        DW OFFSET EmRclWordMemCl
emD3_011        DW OFFSET EmRcrWordMemCl
emD3_100        DW OFFSET EmShlWordMemCl
emD3_101        DW OFFSET EmShrWordMemCl
emD3_110        DW OFFSET EmulateError
emD3_111        DW OFFSET EmSarWordMemCl

EmD3:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmD3Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMF6
;
;               DESCRIPTION:    EMULATE F6 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmF6Tab:
emF6_000        DW OFFSET EmTestByteImMem
emF6_001        DW OFFSET EmulateError
emF6_010        DW OFFSET EmNotByteMem
emF6_011        DW OFFSET EmNegByteMem
emF6_100        DW OFFSET EmMulByteMem
emF6_101        DW OFFSET EmImulByteMem
emF6_110        DW OFFSET EmDivByteMem
emF6_111        DW OFFSET EmIdivByteMem

EmF6:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmF6Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMF7
;
;               DESCRIPTION:    EMULATE F7 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmF7Tab:
emF7_000        DW OFFSET EmTestWordImMem
emF7_001        DW OFFSET EmulateError
emF7_010        DW OFFSET EmNotWordMem
emF7_011        DW OFFSET EmNegWordMem
emF7_100        DW OFFSET EmMulWordMem
emF7_101        DW OFFSET EmImulWordMem
emF7_110        DW OFFSET EmDivWordMem
emF7_111        DW OFFSET EmIdivWordMem

EmF7:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmF7Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMFE
;
;               DESCRIPTION:    EMULATE FE instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFETab:
emFE_000        DW OFFSET EmIncByteMem
emFE_001        DW OFFSET EmDecByteMem
emFE_010        DW OFFSET EmulateError
emFE_011        DW OFFSET EmulateError
emFE_100        DW OFFSET EmulateError
emFE_101        DW OFFSET EmulateError
emFE_110        DW OFFSET EmulateError
emFE_111        DW OFFSET EmulateError

EmFE:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmFETab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMFF
;
;               DESCRIPTION:    EMULATE FF instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFFTab:
emFF_000        DW OFFSET EmIncWordMem
emFF_001        DW OFFSET EmDecWordMem
emFF_010        DW OFFSET EmCallNearMem
emFF_011        DW OFFSET EmCallFarMem
emFF_100        DW OFFSET EmJmpNearMem
emFF_101        DW OFFSET EmJmpFarMem
emFF_110        DW OFFSET EmPushMem
emFF_111        DW OFFSET EmulateError

EmFF:
        call ReadCodeByte
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmFFTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmulateTab
;
;               description:    emulate instruction
;
;               PARAMETERS:             SS:ebp           CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmulateTab:
emt00   DW OFFSET EmAddByteMemReg,              OFFSET EmAddWordMemReg
emt02   DW OFFSET EmAddByteRegMem,              OFFSET EmAddWordRegMem
emt04   DW OFFSET EmAddByteImAcc,               OFFSET EmAddWordImAcc
emt06   DW OFFSET EmPushEs,                             OFFSET EmPopEs
emt08   DW OFFSET EmOrByteMemReg,               OFFSET EmOrWordMemReg
emt0A   DW OFFSET EmOrByteRegMem,               OFFSET EmOrWordRegMem
emt0C   DW OFFSET EmOrByteImAcc,                OFFSET EmOrWordImAcc
emt0E   DW OFFSET EmPushCs,                             OFFSET Em0F
emt10   DW OFFSET EmAdcByteMemReg,              OFFSET EmAdcWordMemReg
emt12   DW OFFSET EmAdcByteRegMem,              OFFSET EmAdcWordRegMem
emt14   DW OFFSET EmAdcByteImAcc,               OFFSET EmAdcWordImAcc
emt16   DW OFFSET EmPushSs,                             OFFSET EmPopSs
emt18   DW OFFSET EmSbbByteMemReg,              OFFSET EmSbbWordMemReg
emt1A   DW OFFSET EmSbbByteRegMem,              OFFSET EmSbbWordRegMem
emt1C   DW OFFSET EmSbbByteImAcc,               OFFSET EmSbbWordImAcc
emt1E   DW OFFSET EmPushDs,                             OFFSET EmPopDs
emt20   DW OFFSET EmAndByteMemReg,              OFFSET EmAndWordMemReg
emt22   DW OFFSET EmAndByteRegMem,              OFFSET EmAndWordRegMem
emt24   DW OFFSET EmAndByteImAcc,               OFFSET EmAndWordImAcc
emt26   DW OFFSET EmOverrideEs,                 OFFSET EmDaa
emt28   DW OFFSET EmSubByteMemReg,              OFFSET EmSubWordMemReg
emt2A   DW OFFSET EmSubByteRegMem,              OFFSET EmSubWordRegMem
emt2C   DW OFFSET EmSubByteImAcc,               OFFSET EmSubWordImAcc
emt2E   DW OFFSET EmOverrideCs,                 OFFSET EmDas
emt30   DW OFFSET EmXorByteMemReg,              OFFSET EmXorWordMemReg
emt32   DW OFFSET EmXorByteRegMem,              OFFSET EmXorWordRegMem
emt34   DW OFFSET EmXorByteImAcc,               OFFSET EmXorWordImAcc
emt36   DW OFFSET EmOverrideSs,                 OFFSET EmAaa
emt38   DW OFFSET EmCmpByteMemReg,              OFFSET EmCmpWordMemReg
emt3A   DW OFFSET EmCmpByteRegMem,              OFFSET EmCmpWordRegMem
emt3C   DW OFFSET EmCmpByteImAcc,               OFFSET EmCmpWordImAcc
emt3E   DW OFFSET EmOverrideDs,                 OFFSET EmAas
emt40   DW OFFSET EmIncAx,                              OFFSET EmIncCx
emt42   DW OFFSET EmIncDx,                              OFFSET EmIncBx
emt44   DW OFFSET EmIncSp,                              OFFSET EmIncBp
emt46   DW OFFSET EmIncSi,                              OFFSET EmIncDi
emt48   DW OFFSET EmDecAx,                              OFFSET EmDecCx
emt4A   DW OFFSET EmDecDx,                              OFFSET EmDecBx
emt4C   DW OFFSET EmDecSp,                              OFFSET EmDecBp
emt4E   DW OFFSET EmDecSi,                              OFFSET EmDecDi
emt50   DW OFFSET EmPushAx,                             OFFSET EmPushCx
emt52   DW OFFSET EmPushDx,                             OFFSET EmPushBx
emt54   DW OFFSET EmPushSp,                             OFFSET EmPushBp
emt56   DW OFFSET EmPushSi,                             OFFSET EmPushDi
emt58   DW OFFSET EmPopAx,                              OFFSET EmPopCx
emt5A   DW OFFSET EmPopDx,                              OFFSET EmPopBx
emt5C   DW OFFSET EmPopSp,                              OFFSET EmPopBp
emt5E   DW OFFSET EmPopSi,                              OFFSET EmPopDi
emt60   DW OFFSET EmPusha,                              OFFSET EmPopa
emt62   DW OFFSET EmulateError,                 OFFSET EmArplRegMem
emt64   DW OFFSET EmOverrideFs,                 OFFSET EmOverrideGs
emt66   DW OFFSET EmOverrideData,               OFFSET EmOverrideAdr
emt68   DW OFFSET EmPushIm,                             OFFSET EmImulWordImMem
emt6A   DW OFFSET EmPushImsx,                   OFFSET EmImulWordImsxMem
emt6C   DW OFFSET EmInsb,                               OFFSET EmInsw
emt6E   DW OFFSET EmOutsb,                              OFFSET EmOutsw
emt70   DW OFFSET EmJoShort,                    OFFSET EmJnoShort
emt72   DW OFFSET EmJbShort,                    OFFSET EmJnbShort
emt74   DW OFFSET EmJeShort,                    OFFSET EmJneShort
emt76   DW OFFSET EmJbeShort,                   OFFSET EmJnbeShort
emt78   DW OFFSET EmJsShort,                    OFFSET EmJnsShort
emt7A   DW OFFSET EmJpShort,                    OFFSET EmJnpShort
emt7C   DW OFFSET EmJlShort,                    OFFSET EmJnlShort
emt7E   DW OFFSET EmJleShort,                   OFFSET EmJnleShort
emt80   DW OFFSET Em80,                                 OFFSET Em81
emt82   DW OFFSET Em82,                                 OFFSET Em83
emt84   DW OFFSET EmTestByteMemReg,             OFFSET EmTestWordMemReg
emt86   DW OFFSET EmXchgByteRegMem,             OFFSET EmXchgWordRegMem
emt88   DW OFFSET EmMoveByteRegToMem,   OFFSET EmMoveWordRegToMem
emt8A   DW OFFSET EmMoveByteMemToReg,   OFFSET EmMoveWordMemToReg
emt8C   DW OFFSET EmMoveSregToMem,              OFFSET EmLea
emt8E   DW OFFSET EmMoveMemToSreg,              OFFSET Em8F
emt90   DW OFFSET EmNop,                                OFFSET EmXchgAxCx
emt92   DW OFFSET EmXchgAxDx,                   OFFSET EmXchgAxBx
emt94   DW OFFSET EmXchgAxSp,                   OFFSET EmXchgAxBp
emt96   DW OFFSET EmXchgAxSi,                   OFFSET EmXchgAxDi
emt98   DW OFFSET EmCbw,                                OFFSET EmCwd
emt9A   DW OFFSET EmCallFar,                    OFFSET EmWait
emt9C   DW OFFSET EmPushf,                              OFFSET EmPopf
emt9E   DW OFFSET EmSahf,                               OFFSET EmLahf
emtA0   DW OFFSET EmMoveByteMemToAcc,   OFFSET EmMoveWordMemToAcc
emtA2   DW OFFSET EmMoveByteAccToMem,   OFFSET EmMoveWordAccToMem
emtA4   DW OFFSET EmMovsb,                              OFFSET EmMovsw
emtA6   DW OFFSET EmCmpsb,                              OFFSET EmCmpsw
emtA8   DW OFFSET EmTestByteImAcc,              OFFSET EmTestWordImAcc
emtAA   DW OFFSET EmStosb,                              OFFSET EmStosw
emtAC   DW OFFSET EmLodsb,                              OFFSET EmLodsw
emtAE   DW OFFSET EmScasb,                              OFFSET EmScasw
emtB0   DW OFFSET EmMoveAlIm,                   OFFSET EmMoveClIm
emtB2   DW OFFSET EmMoveDlIm,                   OFFSET EmMoveBlIm
emtB4   DW OFFSET EmMoveAhIm,                   OFFSET EmMoveChIm
emtB6   DW OFFSET EmMoveDhIm,                   OFFSET EmMoveBhIm
emtB8   DW OFFSET EmMoveAxIm,                   OFFSET EmMoveCxIm
emtBA   DW OFFSET EmMoveDxIm,                   OFFSET EmMoveBxIm
emtBC   DW OFFSET EmMoveSpIm,                   OFFSET EmMoveBpIm
emtBE   DW OFFSET EmMoveSiIm,                   OFFSET EmMoveDiIm
emtC0   DW OFFSET EmC0,                                 OFFSET EmC1
emtC2   DW OFFSET EmRetNearN,                   OFFSET EmRetNear
emtC4   DW OFFSET EmLes,                                OFFSET EmLds
emtC6   DW OFFSET EmMoveByteImToMem,    OFFSET EmMoveWordImToMem
emtC8   DW OFFSET EmEnter,                              OFFSET EmLeave
emtCA   DW OFFSET EmulateError,                 OFFSET EmRetFar
emtCC   DW OFFSET EmInt3,                               OFFSET EmInt
emtCE   DW OFFSET EmulateError,                 OFFSET EmIret
emtD0   DW OFFSET EmD0,                                 OFFSET EmD1
emtD2   DW OFFSET EmD2,                                 OFFSET EmD3
emtD4   DW OFFSET EmulateError,                 OFFSET EmulateError
emtD6   DW OFFSET EmulateError,                 OFFSET EmXlat
emtD8   DW OFFSET EmD8,                                 OFFSET EmD9
emtDA   DW OFFSET EmDA,                                 OFFSET EmDB
emtDC   DW OFFSET EmDC,                                 OFFSET EmDD
emtDE   DW OFFSET EmDE,                                 OFFSET EmDF
emtE0   DW OFFSET EmLoopnzShort,                OFFSET EmLoopzShort
emtE2   DW OFFSET EmLoopShort,                  OFFSET EmJcxzShort
emtE4   DW OFFSET EmInByteIm,                   OFFSET EmInWordIm
emtE6   DW OFFSET EmOutByteIm,                  OFFSET EmOutWordIm
emtE8   DW OFFSET EmCallNear,                   OFFSET EmJmpNear
emtEA   DW OFFSET EmJmpFar,                             OFFSET EmJmpShort
emtEC   DW OFFSET EmInByteDx,                   OFFSET EmInWordDx
emtEE   DW OFFSET EmOutByteDx,                  OFFSET EmOutWordDx
emtF0   DW OFFSET EmulateError,                 OFFSET EmulateError
emtF2   DW OFFSET EmRepne,                              OFFSET EmRepe
emtF4   DW OFFSET EmHlt,                                OFFSET EmCmc
emtF6   DW OFFSET EmF6,                                 OFFSET EmF7
emtF8   DW OFFSET EmClc,                                OFFSET EmStc
emtFA   DW OFFSET EmCli,                                OFFSET EmSti
emtFC   DW OFFSET EmCld,                                OFFSET EmStd
emtFE   DW OFFSET EmFE,                                 OFFSET EmFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Emulate
;
;               description:    Emulate an instruction
;
;               PARAMETERS:             CPU registers, must be on stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

emulate_name DB 'Emulate OpCode',0

emulate PROC far
        mov [ebp].trap_state,al
        test byte ptr [ebp+2].trap_eflags,2
        jnz emulate_vm

emulate_pm:
        test byte ptr [ebp].trap_cs,3
        jz emulate_kernel
;
        push gs
        push fs
        push word ptr [ebp].trap_pds
        push es
        push word ptr [ebp].trap_ss
        push dword ptr [ebp].trap_esp
        push dword ptr [ebp].trap_eflags
        push word ptr [ebp].trap_cs
        push dword ptr [ebp].trap_eip
        push dword ptr [ebp].trap_eax
        push dword ptr [ebp].trap_ebx
        push ecx
        push edx
        push esi
        push edi
        mov eax,[ebp].trap_ebp
        push eax
        push ebp
        mov ebp,esp
        sub esp,2
        mov byte ptr [ebp].em_sreg,seg_def
        mov byte ptr [ebp].em_flags,0
        call GetCsBitness
        call GetSsBitness
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        call word ptr cs:[bx].EmulateTab
;
        add esp,2
        pop ebp
        pop eax
        mov [ebp].trap_ebp,eax
        pop edi
        pop esi
        pop edx
        pop ecx
        pop dword ptr [ebp].trap_ebx
        pop dword ptr [ebp].trap_eax
        pop dword ptr [ebp].trap_eip
        pop word ptr [ebp].trap_cs
        pop dword ptr [ebp].trap_eflags
        pop dword ptr [ebp].trap_esp
        pop word ptr [ebp].trap_ss
        pop es
        pop word ptr [ebp].trap_pds
        pop fs
        pop gs
        test word ptr [ebp].trap_eflags,100h
        jz emulate_pm_done
;
        mov ax,1
        ReflectException

emulate_pm_done:
        retf32

emulate_kernel:
        push gs
        push fs
        push word ptr [ebp].trap_pds
        push es
        push ss
        push ebp
        push dword ptr [ebp].trap_eflags
        push word ptr [ebp].trap_cs
        push dword ptr [ebp].trap_eip
        push dword ptr [ebp].trap_eax
        push dword ptr [ebp].trap_ebx
        push ecx
        push edx
        push esi
        push edi
        mov eax,[ebp].trap_ebp
        push eax
        push ebp
        mov ebp,esp
        sub esp,2
        mov byte ptr [ebp].em_sreg,seg_def
        mov byte ptr [ebp].em_flags,0
        call GetCsBitness
        call GetSsBitness
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        call word ptr cs:[bx].EmulateTab
;
        mov eax,[ebp].reg_esp
        sub eax,[ebp].reg_old_ebp
        je emulate_kernel_stack_ok
        jc emulate_kernel_stack_pushed
;
        mov esi,[ebp].reg_old_ebp
        mov edi,[ebp].reg_esp
        mov cx,ss
        mov es,cx
        add esi,16
        add edi,16
        mov ecx,esi
        sub ecx,esp
        shr ecx,1
        inc ecx
        std
        rep movs word ptr es:[edi],es:[esi]
        cld
        add esp,eax
        add ebp,eax
        add [ebp].reg_old_ebp,eax
        jmp emulate_kernel_stack_ok

emulate_kernel_stack_pushed:
        mov eax,[ebp].reg_esp
        mov [ebp].reg_old_ebp,eax

emulate_kernel_stack_ok:
        add esp,2
        pop ebp
        pop eax
        mov [ebp].trap_ebp,eax
;
        pop edi
        pop esi
        pop edx
        pop ecx
        pop dword ptr [ebp].trap_ebx
        pop dword ptr [ebp].trap_eax
        pop dword ptr [ebp].trap_eip
        pop word ptr [ebp].trap_cs
        pop dword ptr [ebp].trap_eflags
        add esp,6
        pop es
        pop word ptr [ebp].trap_pds
        pop fs
        pop gs
        test word ptr [ebp].trap_eflags,100h
        jz emulate_kernel_done
;
        mov ax,1
        ReflectException

emulate_kernel_done:
        retf32

emulate_vm:
        push word ptr [ebp].trap_gs
        push word ptr [ebp].trap_fs
        push word ptr [ebp].trap_ds
        push word ptr [ebp].trap_es
        push word ptr [ebp].trap_ss
        push dword ptr [ebp].trap_esp
        push dword ptr [ebp].trap_eflags
        push word ptr [ebp].trap_cs
        push dword ptr [ebp].trap_eip
        push dword ptr [ebp].trap_eax
        push dword ptr [ebp].trap_ebx
        push ecx
        push edx
        push esi
        push edi
        mov eax,[ebp].trap_ebp
        push eax
        push ebp
        mov ebp,esp
        sub esp,2
;
        mov byte ptr [ebp].em_sreg,seg_def
        mov byte ptr [ebp].em_flags,0
        call GetCsBitness
        call GetSsBitness
        call ReadCodeByte
        movzx bx,al
        add bx,bx
        call word ptr cs:[bx].EmulateTab
;
        add esp,2
        pop ebp
        pop eax
        mov [ebp].trap_ebp,eax
        pop edi
        pop esi
        pop edx
        pop ecx
        pop dword ptr [ebp].trap_ebx
        pop dword ptr [ebp].trap_eax
        pop word ptr [ebp].trap_eip
        add esp,2
        pop word ptr [ebp].trap_cs
        pop word ptr [ebp].trap_eflags
        add esp,2
        pop word ptr [ebp].trap_esp
        add esp,2
        pop word ptr [ebp].trap_ss
        pop word ptr [ebp].trap_es
        pop word ptr [ebp].trap_ds
        pop word ptr [ebp].trap_fs
        pop word ptr [ebp].trap_gs
        test word ptr [ebp].trap_eflags,100h
        jz emulate_vm_done
;
        mov ax,1
        ReflectException

emulate_vm_done:
        retf32
emulate ENDP

init    PROC far
    mov ax,system_data_sel
    mov ds,ax
    mov al,ds:cpu_type
    cmp al,3
    je init_start
;    
    mov eax,cr4
    and al,NOT 1
    mov cr4,eax

init_start:
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov esi,OFFSET emulate
        mov edi,OFFSET emulate_name
        xor cl,cl
        mov ax,emulate_opcode_nr
        RegisterOsGate
;    
        call init_common
        ret
init    ENDP

code    ENDS

        END init
