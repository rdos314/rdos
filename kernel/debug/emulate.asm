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
; Main emulator module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include emcom.inc
include emseg.inc
include emarithm.inc
include emtrans.inc
include emcontr.inc
include emstring.inc
include emprot.inc
include lntrans.inc
include lnarithm.inc
include lncontr.inc

.code

.686p
.387

code    SEGMENT byte use32 public 'CODE'

GetIntVector    Proc near
    int 3
    ret
GetIntVector    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmWrmsr
;
;               DESCRIPTION:            wrmsr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmWrmsr   Proc near
        mov edx,ds:[ebp].reg_edx
        mov eax,ds:[ebp].reg_eax
        mov ecx,ds:[ebp].reg_ecx
        wrmsr
        ret
EmWrmsr Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmRdmsr
;
;               DESCRIPTION:            rdmsr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmRdmsr   Proc near
        mov ecx,ds:[ebp].reg_ecx
        rdmsr
        mov ds:[ebp].reg_edx,edx
        mov ds:[ebp].reg_eax,eax
        ret
EmRdmsr Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCpuid
;
;               DESCRIPTION:    cpuid
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmCpuid   Proc near
        mov eax,ds:[ebp].reg_eax
        cmp eax,0
        je EmCpuid0
;
        cmp eax,1
        je EmCpuid1        
;       
        cmp eax,80000000h
        je EmCpuidE0        
;
        cmp eax,80000001h
        je EmCpuid1
;
        jmp EmCpuidFail        

EmCpuid0:        
        mov ds:[ebp].reg_eax,80000004h
        mov ds:[ebp].reg_ebx,30303030h
        mov ds:[ebp].reg_ecx,30303030h
        mov ds:[ebp].reg_edx,30303030h
        ret        

EmCpuid1:
        mov ds:[ebp].reg_eax,600h
        mov ds:[ebp].reg_edx,863h
        mov ds:[ebp].reg_ecx,0
        ret

EmCpuidE0:
        mov ds:[ebp].reg_eax,80000004h
        ret

EmCpuidFail:        
        xor bx,bx
        call ProtectionFault
        ret
EmCpuid   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmNop
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
;               NAME:           EmHlt
;
;               DESCRIPTION:    hlt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmHlt   Proc near
        mov eax,ds:[ebp].org_eip
        mov ds:[ebp].reg_eip,eax
        mov eax,ds:[ebp].org_esp
        mov ds:[ebp].reg_esp,eax
        mov eax,ds:[ebp].org_stack
        mov esp,eax
        ret
EmHlt   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmOverrideData
;
;               DESCRIPTION:    change size of data between 16 & 32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideData:
        xor byte ptr ds:[ebp].em_flags,d32
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmOverrideAdr
;
;               DESCRIPTION:    change size of address between 16 & 32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideAdr:
        xor byte ptr ds:[ebp].em_flags,a32
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmOverrideCs
;
;               DESCRIPTION:    Use cs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideCs:
        mov byte ptr ds:[ebp].em_sreg,seg_cs
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmOverrideSS
;
;               DESCRIPTION:    Use ss for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideSs:
        mov byte ptr ds:[ebp].em_sreg,seg_ss
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmOverrideDS
;
;               DESCRIPTION:    Use ds for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideDs:
        mov byte ptr ds:[ebp].em_sreg,seg_ds
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmOverrideES
;
;               DESCRIPTION:    Use es for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideEs:
        mov byte ptr ds:[ebp].em_sreg,seg_es
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmOverrideFS
;
;               DESCRIPTION:    Use fs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideFs:
        mov byte ptr ds:[ebp].em_sreg,seg_fs
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmOverrideGS
;
;               DESCRIPTION:    Use gs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideGs:
        mov byte ptr ds:[ebp].em_sreg,seg_gs
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmLock
;
;               DESCRIPTION:    EMULATE lock
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmLock:
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmREPE
;
;               DESCRIPTION:    EMULATE repe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmRepe:
        or byte ptr ds:[ebp].em_flags,rep_z
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmREPNE
;
;               DESCRIPTION:    EMULATE repne
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmRepne:
        or byte ptr ds:[ebp].em_flags,rep_nz
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].EmulateTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM0F00
;
;               DESCRIPTION:    EMULATE 0F00 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0F00Tab:
em0F00_000      DD OFFSET EmSldtMem
em0F00_001      DD OFFSET EmStrMem
em0F00_010      DD OFFSET EmLldtMem
em0F00_011      DD OFFSET EmLtrMem
em0F00_100      DD OFFSET EmVerrMem
em0F00_101      DD OFFSET EmVerwMem
em0F00_110      DD OFFSET EmulateError
em0F00_111      DD OFFSET EmulateError

Em0F00:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Em0F00Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM0F01
;
;               DESCRIPTION:    EMULATE 0F01 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0F01Tab:
em0F01_000      DD OFFSET EmSgdtMem
em0F01_001      DD OFFSET EmSidtMem
em0F01_010      DD OFFSET EmLgdtMem
em0F01_011      DD OFFSET EmLidtMem
em0F01_100      DD OFFSET EmSmswMem
em0F01_101      DD OFFSET EmulateError
em0F01_110      DD OFFSET EmLmswMem
em0F01_111      DD OFFSET EmInvlpg

Em0F01:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Em0F01Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM0FBA
;
;               DESCRIPTION:    EMULATE 0FBA instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0FBATab:
em0FBA_000      DD OFFSET EmulateError
em0FBA_001      DD OFFSET EmulateError
em0FBA_010      DD OFFSET EmulateError
em0FBA_011      DD OFFSET EmulateError
em0FBA_100      DD OFFSET EmBtImMem
em0FBA_101      DD OFFSET EmBtsImMem
em0FBA_110      DD OFFSET EmBtrImMem
em0FBA_111      DD OFFSET EmBtcImMem

Em0FBA:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Em0FBATab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM0F
;
;               DESCRIPTION:    EMULATE 0F instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0FTab:
emt0F00  DD OFFSET Em0F00,                       OFFSET Em0F01
emt0F02  DD OFFSET EmLarRegMem,                  OFFSET EmLslRegMem
emt0F04  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F06  DD OFFSET EmClts,                       OFFSET EmulateError
emt0F08  DD OFFSET EmulateError,                 OFFSET EmNop
emt0F0A  DD OFFSET EmulateError,                 OFFSET OpcodeFault
emt0F0C  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F0E  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F10  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F12  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F14  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F16  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F18  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F1A  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F1C  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F1E  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F20  DD OFFSET EmMoveRegCr,                  OFFSET EmMoveRegDr
emt0F22  DD OFFSET EmMoveCrReg,                  OFFSET EmMoveDrReg
emt0F24  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F26  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F28  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F2A  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F2C  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F2E  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F30  DD OFFSET EmWrmsr,                      OFFSET EmulateError
emt0F32  DD OFFSET EmRdmsr,                      OFFSET EmulateError
emt0F34  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F36  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F38  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F3A  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F3C  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F3E  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F40  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F42  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F44  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F46  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F48  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F4A  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F4C  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F4E  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F50  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F52  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F54  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F56  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F58  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F5A  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F5C  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F5E  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F60  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F62  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F64  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F66  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F68  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F6A  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F6C  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F6E  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F70  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F72  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F74  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F76  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F78  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F7A  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F7C  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F7E  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0F80  DD OFFSET EmJoNear,                     OFFSET EmJnoNear
emt0F82  DD OFFSET EmJbNear,                     OFFSET EmJnbNear
emt0F84  DD OFFSET EmJeNear,                     OFFSET EmJneNear
emt0F86  DD OFFSET EmJbeNear,                    OFFSET EmJnbeNear
emt0F88  DD OFFSET EmJsNear,                     OFFSET EmJnsNear
emt0F8A  DD OFFSET EmJpNear,                     OFFSET EmJnpNear
emt0F8C  DD OFFSET EmJlNear,                     OFFSET EmJnlNear
emt0F8E  DD OFFSET EmJleNear,                    OFFSET EmJnleNear
emt0F90  DD OFFSET EmSeto,                       OFFSET EmSetno
emt0F92  DD OFFSET EmSetb,                       OFFSET EmSetnb
emt0F94  DD OFFSET EmSete,                       OFFSET EmSetne
emt0F96  DD OFFSET EmSetbe,                      OFFSET EmSetnbe
emt0F98  DD OFFSET EmSets,                       OFFSET EmSetns
emt0F9A  DD OFFSET EmSetp,                       OFFSET EmSetnp
emt0F9C  DD OFFSET EmSetl,                       OFFSET EmSetnl
emt0F9E  DD OFFSET EmSetle,                      OFFSET EmSetnle
emt0FA0  DD OFFSET EmPushFs,                     OFFSET EmPopFs
emt0FA2  DD OFFSET EmCpuid,                      OFFSET EmBtMemReg
emt0FA4  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FA6  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FA8  DD OFFSET EmPushGs,                     OFFSET EmPopGs
emt0FAA  DD OFFSET EmulateError,                 OFFSET EmBtsMemReg
emt0FAC  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FAE  DD OFFSET EmulateError,                 OFFSET EmImulWordRegMem
emt0FB0  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FB2  DD OFFSET EmLss,                        OFFSET EmBtrMemReg
emt0FB4  DD OFFSET EmLfs,                        OFFSET EmLgs
emt0FB6  DD OFFSET EmMovzxByteMem,               OFFSET EmMovzxWordMem
emt0FB8  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FBA  DD OFFSET Em0FBA,                       OFFSET EmBtcMemReg
emt0FBC  DD OFFSET EmBsf,                        OFFSET EmBsr
emt0FBE  DD OFFSET EmMovsxByteMem,               OFFSET EmMovsxWordMem
emt0FC0  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FC2  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FC4  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FC6  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FC8  DD OFFSET EmBswap,                      OFFSET EmBswap
emt0FCA  DD OFFSET EmBswap,                      OFFSET EmBswap
emt0FCC  DD OFFSET EmBswap,                      OFFSET EmBswap
emt0FCE  DD OFFSET EmBswap,                      OFFSET EmBswap
emt0FD0  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FD2  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FD4  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FD6  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FD8  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FDA  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FDC  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FDE  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FE0  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FE2  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FE4  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FE6  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FE8  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FEA  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FEC  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FEE  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FF0  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FF2  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FF4  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FF6  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FF8  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FFA  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FFC  DD OFFSET EmulateError,                 OFFSET EmulateError
emt0FFE  DD OFFSET EmulateError,                 OFFSET EmulateError

Em0F:
        call ReadCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].Em0FTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM80
;
;               DESCRIPTION:    EMULATE 80 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em80Tab:
em80_000        DD OFFSET EmAddByteImMem
em80_001        DD OFFSET EmOrByteImMem
em80_010        DD OFFSET EmAdcByteImMem
em80_011        DD OFFSET EmSbbByteImMem
em80_100        DD OFFSET EmAndByteImMem
em80_101        DD OFFSET EmSubByteImMem
em80_110        DD OFFSET EmXorByteImMem
em80_111        DD OFFSET EmCmpByteImMem

Em80:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Em80Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM81
;
;               DESCRIPTION:    EMULATE 81 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em81Tab:
em81_000        DD OFFSET EmAddWordImMem
em81_001        DD OFFSET EmOrWordImMem
em81_010        DD OFFSET EmAdcWordImMem
em81_011        DD OFFSET EmSbbWordImMem
em81_100        DD OFFSET EmAndWordImMem
em81_101        DD OFFSET EmSubWordImMem
em81_110        DD OFFSET EmXorWordImMem
em81_111        DD OFFSET EmCmpWordImMem

Em81:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Em81Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM82
;
;               DESCRIPTION:    EMULATE 82 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em82Tab:
em82_000        DD OFFSET EmAddByteImMem
em82_001        DD OFFSET EmOrByteImMem
em82_010        DD OFFSET EmAdcByteImMem
em82_011        DD OFFSET EmSbbByteImMem
em82_100        DD OFFSET EmAndByteImMem
em82_101        DD OFFSET EmSubByteImMem
em82_110        DD OFFSET EmXorByteImMem
em82_111        DD OFFSET EmCmpByteImMem

Em82:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Em82Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM83
;
;               DESCRIPTION:    EMULATE 83 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em83Tab:
em83_000        DD OFFSET EmAddWordImsxMem
em83_001        DD OFFSET EmOrWordImsxMem
em83_010        DD OFFSET EmAdcWordImsxMem
em83_011        DD OFFSET EmSbbWordImsxMem
em83_100        DD OFFSET EmAndWordImsxMem
em83_101        DD OFFSET EmSubWordImsxMem
em83_110        DD OFFSET EmXorWordImsxMem
em83_111        DD OFFSET EmCmpWordImsxMem

Em83:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Em83Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EM8F
;
;               DESCRIPTION:    EMULATE 8F instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em8FTab:
em8F_000        DD OFFSET EmPopMem
em8F_001        DD OFFSET EmulateError
em8F_010        DD OFFSET EmulateError
em8F_011        DD OFFSET EmulateError
em8F_100        DD OFFSET EmulateError
em8F_101        DD OFFSET EmulateError
em8F_110        DD OFFSET EmulateError
em8F_111        DD OFFSET EmulateError

Em8F:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Em8FTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMC0
;
;               DESCRIPTION:    EMULATE C0 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmC0Tab:
emC0_000        DD OFFSET EmRolByteMemIm
emC0_001        DD OFFSET EmRorByteMemIm
emC0_010        DD OFFSET EmRclByteMemIm
emC0_011        DD OFFSET EmRcrByteMemIm
emC0_100        DD OFFSET EmShlByteMemIm
emC0_101        DD OFFSET EmShrByteMemIm
emC0_110        DD OFFSET EmulateError
emC0_111        DD OFFSET EmSarByteMemIm

EmC0:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmC0Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMC1
;
;               DESCRIPTION:    EMULATE C1 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmC1Tab:
emC1_000        DD OFFSET EmRolWordMemIm
emC1_001        DD OFFSET EmRorWordMemIm
emC1_010        DD OFFSET EmRclWordMemIm
emC1_011        DD OFFSET EmRcrWordMemIm
emC1_100        DD OFFSET EmShlWordMemIm
emC1_101        DD OFFSET EmShrWordMemIm
emC1_110        DD OFFSET EmulateError
emC1_111        DD OFFSET EmSarWordMemIm

EmC1:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmC1Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMD0
;
;               DESCRIPTION:    EMULATE D0 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD0Tab:
emD0_000        DD OFFSET EmRolByteMem1
emD0_001        DD OFFSET EmRorByteMem1
emD0_010        DD OFFSET EmRclByteMem1
emD0_011        DD OFFSET EmRcrByteMem1
emD0_100        DD OFFSET EmShlByteMem1
emD0_101        DD OFFSET EmShrByteMem1
emD0_110        DD OFFSET EmulateError
emD0_111        DD OFFSET EmSarByteMem1

EmD0:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmD0Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMD1
;
;               DESCRIPTION:    EMULATE D1 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD1Tab:
emD1_000        DD OFFSET EmRolWordMem1
emD1_001        DD OFFSET EmRorWordMem1
emD1_010        DD OFFSET EmRclWordMem1
emD1_011        DD OFFSET EmRcrWordMem1
emD1_100        DD OFFSET EmShlWordMem1
emD1_101        DD OFFSET EmShrWordMem1
emD1_110        DD OFFSET EmulateError
emD1_111        DD OFFSET EmSarWordMem1

EmD1:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmD1Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMD2
;
;               DESCRIPTION:    EMULATE D2 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD2Tab:
emD2_000        DD OFFSET EmRolByteMemCl
emD2_001        DD OFFSET EmRorByteMemCl
emD2_010        DD OFFSET EmRclByteMemCl
emD2_011        DD OFFSET EmRcrByteMemCl
emD2_100        DD OFFSET EmShlByteMemCl
emD2_101        DD OFFSET EmShrByteMemCl
emD2_110        DD OFFSET EmulateError
emD2_111        DD OFFSET EmSarByteMemCl

EmD2:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmD2Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMD3
;
;               DESCRIPTION:    EMULATE D3 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD3Tab:
emD3_000        DD OFFSET EmRolWordMemCl
emD3_001        DD OFFSET EmRorWordMemCl
emD3_010        DD OFFSET EmRclWordMemCl
emD3_011        DD OFFSET EmRcrWordMemCl
emD3_100        DD OFFSET EmShlWordMemCl
emD3_101        DD OFFSET EmShrWordMemCl
emD3_110        DD OFFSET EmulateError
emD3_111        DD OFFSET EmSarWordMemCl

EmD3:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmD3Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMF6
;
;               DESCRIPTION:    EMULATE F6 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmF6Tab:
emF6_000        DD OFFSET EmTestByteImMem
emF6_001        DD OFFSET EmulateError
emF6_010        DD OFFSET EmNotByteMem
emF6_011        DD OFFSET EmNegByteMem
emF6_100        DD OFFSET EmMulByteMem
emF6_101        DD OFFSET EmImulByteMem
emF6_110        DD OFFSET EmDivByteMem
emF6_111        DD OFFSET EmIdivByteMem

EmF6:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmF6Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMF7
;
;               DESCRIPTION:    EMULATE F7 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmF7Tab:
emF7_000        DD OFFSET EmTestWordImMem
emF7_001        DD OFFSET EmulateError
emF7_010        DD OFFSET EmNotWordMem
emF7_011        DD OFFSET EmNegWordMem
emF7_100        DD OFFSET EmMulWordMem
emF7_101        DD OFFSET EmImulWordMem
emF7_110        DD OFFSET EmDivWordMem
emF7_111        DD OFFSET EmIdivWordMem

EmF7:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmF7Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMFE
;
;               DESCRIPTION:    EMULATE FE instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFETab:
emFE_000        DD OFFSET EmIncByteMem
emFE_001        DD OFFSET EmDecByteMem
emFE_010        DD OFFSET EmulateError
emFE_011        DD OFFSET EmulateError
emFE_100        DD OFFSET EmulateError
emFE_101        DD OFFSET EmulateError
emFE_110        DD OFFSET EmulateError
emFE_111        DD OFFSET EmulateError

EmFE:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmFETab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EMFF
;
;               DESCRIPTION:    EMULATE FF instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFFTab:
emFF_000        DD OFFSET EmIncWordMem
emFF_001        DD OFFSET EmDecWordMem
emFF_010        DD OFFSET EmCallNearMem
emFF_011        DD OFFSET EmCallFarMem
emFF_100        DD OFFSET EmJmpNearMem
emFF_101        DD OFFSET EmJmpFarMem
emFF_110        DD OFFSET EmPushMem
emFF_111        DD OFFSET EmulateError

EmFF:
        call ReadCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].EmFFTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmulateTab
;
;               description:    emulate instruction
;
;               PARAMETERS:     DS:BP           CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmulateTab:
emt00   DD OFFSET EmAddByteMemReg,              OFFSET EmAddWordMemReg
emt02   DD OFFSET EmAddByteRegMem,              OFFSET EmAddWordRegMem
emt04   DD OFFSET EmAddByteImAcc,               OFFSET EmAddWordImAcc
emt06   DD OFFSET EmPushEs,                     OFFSET EmPopEs
emt08   DD OFFSET EmOrByteMemReg,               OFFSET EmOrWordMemReg
emt0A   DD OFFSET EmOrByteRegMem,               OFFSET EmOrWordRegMem
emt0C   DD OFFSET EmOrByteImAcc,                OFFSET EmOrWordImAcc
emt0E   DD OFFSET EmPushCs,                     OFFSET Em0F
emt10   DD OFFSET EmAdcByteMemReg,              OFFSET EmAdcWordMemReg
emt12   DD OFFSET EmAdcByteRegMem,              OFFSET EmAdcWordRegMem
emt14   DD OFFSET EmAdcByteImAcc,               OFFSET EmAdcWordImAcc
emt16   DD OFFSET EmPushSs,                     OFFSET EmPopSs
emt18   DD OFFSET EmSbbByteMemReg,              OFFSET EmSbbWordMemReg
emt1A   DD OFFSET EmSbbByteRegMem,              OFFSET EmSbbWordRegMem
emt1C   DD OFFSET EmSbbByteImAcc,               OFFSET EmSbbWordImAcc
emt1E   DD OFFSET EmPushDs,                     OFFSET EmPopDs
emt20   DD OFFSET EmAndByteMemReg,              OFFSET EmAndWordMemReg
emt22   DD OFFSET EmAndByteRegMem,              OFFSET EmAndWordRegMem
emt24   DD OFFSET EmAndByteImAcc,               OFFSET EmAndWordImAcc
emt26   DD OFFSET EmOverrideEs,                 OFFSET EmDaa
emt28   DD OFFSET EmSubByteMemReg,              OFFSET EmSubWordMemReg
emt2A   DD OFFSET EmSubByteRegMem,              OFFSET EmSubWordRegMem
emt2C   DD OFFSET EmSubByteImAcc,               OFFSET EmSubWordImAcc
emt2E   DD OFFSET EmOverrideCs,                 OFFSET EmDas
emt30   DD OFFSET EmXorByteMemReg,              OFFSET EmXorWordMemReg
emt32   DD OFFSET EmXorByteRegMem,              OFFSET EmXorWordRegMem
emt34   DD OFFSET EmXorByteImAcc,               OFFSET EmXorWordImAcc
emt36   DD OFFSET EmOverrideSs,                 OFFSET EmAaa
emt38   DD OFFSET EmCmpByteMemReg,              OFFSET EmCmpWordMemReg
emt3A   DD OFFSET EmCmpByteRegMem,              OFFSET EmCmpWordRegMem
emt3C   DD OFFSET EmCmpByteImAcc,               OFFSET EmCmpWordImAcc
emt3E   DD OFFSET EmOverrideDs,                 OFFSET EmAas
emt40   DD OFFSET EmIncAx,                      OFFSET EmIncCx
emt42   DD OFFSET EmIncDx,                      OFFSET EmIncBx
emt44   DD OFFSET EmIncSp,                      OFFSET EmIncBp
emt46   DD OFFSET EmIncSi,                      OFFSET EmIncDi
emt48   DD OFFSET EmDecAx,                      OFFSET EmDecCx
emt4A   DD OFFSET EmDecDx,                      OFFSET EmDecBx
emt4C   DD OFFSET EmDecSp,                      OFFSET EmDecBp
emt4E   DD OFFSET EmDecSi,                      OFFSET EmDecDi
emt50   DD OFFSET EmPushAx,                     OFFSET EmPushCx
emt52   DD OFFSET EmPushDx,                     OFFSET EmPushBx
emt54   DD OFFSET EmPushSp,                     OFFSET EmPushBp
emt56   DD OFFSET EmPushSi,                     OFFSET EmPushDi
emt58   DD OFFSET EmPopAx,                      OFFSET EmPopCx
emt5A   DD OFFSET EmPopDx,                      OFFSET EmPopBx
emt5C   DD OFFSET EmPopSp,                      OFFSET EmPopBp
emt5E   DD OFFSET EmPopSi,                      OFFSET EmPopDi
emt60   DD OFFSET EmPusha,                      OFFSET EmPopa
emt62   DD OFFSET EmulateError,                 OFFSET EmArplRegMem
emt64   DD OFFSET EmOverrideFs,                 OFFSET EmOverrideGs
emt66   DD OFFSET EmOverrideData,               OFFSET EmOverrideAdr
emt68   DD OFFSET EmPushIm,                     OFFSET EmImulWordImMem
emt6A   DD OFFSET EmPushImsx,                   OFFSET EmImulWordImsxMem
emt6C   DD OFFSET EmInsb,                       OFFSET EmInsw
emt6E   DD OFFSET EmOutsb,                      OFFSET EmOutsw
emt70   DD OFFSET EmJoShort,                    OFFSET EmJnoShort
emt72   DD OFFSET EmJbShort,                    OFFSET EmJnbShort
emt74   DD OFFSET EmJeShort,                    OFFSET EmJneShort
emt76   DD OFFSET EmJbeShort,                   OFFSET EmJnbeShort
emt78   DD OFFSET EmJsShort,                    OFFSET EmJnsShort
emt7A   DD OFFSET EmJpShort,                    OFFSET EmJnpShort
emt7C   DD OFFSET EmJlShort,                    OFFSET EmJnlShort
emt7E   DD OFFSET EmJleShort,                   OFFSET EmJnleShort
emt80   DD OFFSET Em80,                         OFFSET Em81
emt82   DD OFFSET Em82,                         OFFSET Em83
emt84   DD OFFSET EmTestByteMemReg,             OFFSET EmTestWordMemReg
emt86   DD OFFSET EmXchgByteRegMem,             OFFSET EmXchgWordRegMem
emt88   DD OFFSET EmMoveByteRegToMem,           OFFSET EmMoveWordRegToMem
emt8A   DD OFFSET EmMoveByteMemToReg,           OFFSET EmMoveWordMemToReg
emt8C   DD OFFSET EmMoveSregToMem,              OFFSET EmLea
emt8E   DD OFFSET EmMoveMemToSreg,              OFFSET Em8F
emt90   DD OFFSET EmNop,                        OFFSET EmXchgAxCx
emt92   DD OFFSET EmXchgAxDx,                   OFFSET EmXchgAxBx
emt94   DD OFFSET EmXchgAxSp,                   OFFSET EmXchgAxBp
emt96   DD OFFSET EmXchgAxSi,                   OFFSET EmXchgAxDi
emt98   DD OFFSET EmCbw,                        OFFSET EmCwd
emt9A   DD OFFSET EmCallFar,                    OFFSET EmulateError
emt9C   DD OFFSET EmPushf,                      OFFSET EmPopf
emt9E   DD OFFSET EmSahf,                       OFFSET EmLahf
emtA0   DD OFFSET EmMoveByteMemToAcc,           OFFSET EmMoveWordMemToAcc
emtA2   DD OFFSET EmMoveByteAccToMem,           OFFSET EmMoveWordAccToMem
emtA4   DD OFFSET EmMovsb,                      OFFSET EmMovsw
emtA6   DD OFFSET EmCmpsb,                      OFFSET EmCmpsw
emtA8   DD OFFSET EmTestByteImAcc,              OFFSET EmTestWordImAcc
emtAA   DD OFFSET EmStosb,                      OFFSET EmStosw
emtAC   DD OFFSET EmLodsb,                      OFFSET EmLodsw
emtAE   DD OFFSET EmScasb,                      OFFSET EmScasw
emtB0   DD OFFSET EmMoveAlIm,                   OFFSET EmMoveClIm
emtB2   DD OFFSET EmMoveDlIm,                   OFFSET EmMoveBlIm
emtB4   DD OFFSET EmMoveAhIm,                   OFFSET EmMoveChIm
emtB6   DD OFFSET EmMoveDhIm,                   OFFSET EmMoveBhIm
emtB8   DD OFFSET EmMoveAxIm,                   OFFSET EmMoveCxIm
emtBA   DD OFFSET EmMoveDxIm,                   OFFSET EmMoveBxIm
emtBC   DD OFFSET EmMoveSpIm,                   OFFSET EmMoveBpIm
emtBE   DD OFFSET EmMoveSiIm,                   OFFSET EmMoveDiIm
emtC0   DD OFFSET EmC0,                         OFFSET EmC1
emtC2   DD OFFSET EmRetNearN,                   OFFSET EmRetNear
emtC4   DD OFFSET EmLes,                        OFFSET EmLds
emtC6   DD OFFSET EmMoveByteImToMem,            OFFSET EmMoveWordImToMem
emtC8   DD OFFSET EmEnter,                      OFFSET EmLeave
emtCA   DD OFFSET EmRetFarN,                    OFFSET EmRetFar
emtCC   DD OFFSET EmInt3,                       OFFSET EmInt
emtCE   DD OFFSET EmulateError,                 OFFSET EmIret
emtD0   DD OFFSET EmD0,                         OFFSET EmD1
emtD2   DD OFFSET EmD2,                         OFFSET EmD3
emtD4   DD OFFSET EmulateError,                 OFFSET EmulateError
emtD6   DD OFFSET EmulateError,                 OFFSET EmXlat
emtD8   DD OFFSET EmulateError,                 OFFSET EmulateError
emtDA   DD OFFSET EmulateError,                 OFFSET EmulateError
emtDC   DD OFFSET EmulateError,                 OFFSET EmulateError
emtDE   DD OFFSET EmulateError,                 OFFSET EmulateError
emtE0   DD OFFSET EmLoopnzShort,                OFFSET EmLoopzShort
emtE2   DD OFFSET EmLoopShort,                  OFFSET EmJcxzShort
emtE4   DD OFFSET EmInByteIm,                   OFFSET EmInWordIm
emtE6   DD OFFSET EmOutByteIm,                  OFFSET EmOutWordIm
emtE8   DD OFFSET EmCallNear,                   OFFSET EmJmpNear
emtEA   DD OFFSET EmJmpFar,                     OFFSET EmJmpShort
emtEC   DD OFFSET EmInByteDx,                   OFFSET EmInWordDx
emtEE   DD OFFSET EmOutByteDx,                  OFFSET EmOutWordDx
emtF0   DD OFFSET EmLock,                       OFFSET EmulateError
emtF2   DD OFFSET EmRepne,                      OFFSET EmRepe
emtF4   DD OFFSET EmHlt,                        OFFSET EmCmc
emtF6   DD OFFSET EmF6,                         OFFSET EmF7
emtF8   DD OFFSET EmClc,                        OFFSET EmStc
emtFA   DD OFFSET EmCli,                        OFFSET EmSti
emtFC   DD OFFSET EmCld,                        OFFSET EmStd
emtFE   DD OFFSET EmFE,                         OFFSET EmFF
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongRex
;
;               DESCRIPTION:    Handle rex instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LongRex:
        and al,0Fh
        mov ds:[ebp].em_rex,al
        call ReadLongCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].LongTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongOverrideData
;
;               DESCRIPTION:    change size of data between 32 & 64
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LongOverrideData:
    xor byte ptr ds:[ebp].em_flags,d32
    call ReadLongCodeByte
    movzx ebx,al
    shl ebx,2
    jmp dword ptr cs:[ebx].LongTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongOverrideAdr
;
;               DESCRIPTION:    change size of address between 16 & 32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LongOverrideAdr:
    xor byte ptr ds:[ebp].em_flags,a32
    call ReadLongCodeByte
    movzx ebx,al
    shl ebx,2
    jmp dword ptr cs:[ebx].LongTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongOverrideCs
;
;               DESCRIPTION:    Use cs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LongOverrideCs:
    call ReadLongCodeByte
    movzx ebx,al
    shl ebx,2
    jmp dword ptr cs:[ebx].LongTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Long0F00
;
;               DESCRIPTION:    EMULATE 0F00 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Long0F00Tab:
ln0F00_000      DD OFFSET EmulateError
ln0F00_001      DD OFFSET EmulateError
ln0F00_010      DD OFFSET EmulateError
ln0F00_011      DD OFFSET EmulateError
ln0F00_100      DD OFFSET EmulateError
ln0F00_101      DD OFFSET EmulateError
ln0F00_110      DD OFFSET EmulateError
ln0F00_111      DD OFFSET EmulateError

Long0F00:
        call ReadLongCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Long0F00Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Long0F01
;
;               DESCRIPTION:    EMULATE 0F01 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Long0F01Tab:
ln0F01_000      DD OFFSET EmulateError
ln0F01_001      DD OFFSET EmulateError
ln0F01_010      DD OFFSET LongLgdtMem
ln0F01_011      DD OFFSET EmulateError
ln0F01_100      DD OFFSET EmulateError
ln0F01_101      DD OFFSET EmulateError
ln0F01_110      DD OFFSET EmulateError
ln0F01_111      DD OFFSET EmulateError

Long0F01:
        call ReadLongCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Long0F01Tab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Long0F
;
;               DESCRIPTION:    EMULATE 0F instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Long0FTab:
lnt0F00  DD OFFSET Long0F00,                     OFFSET Long0F01
lnt0F02  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F04  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F06  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F08  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F0A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F0C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F0E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F10  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F12  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F14  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F16  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F18  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F1A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F1C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F1E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F20  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F22  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F24  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F26  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F28  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F2A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F2C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F2E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F30  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F32  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F34  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F36  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F38  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F3A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F3C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F3E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F40  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F42  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F44  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F46  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F48  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F4A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F4C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F4E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F50  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F52  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F54  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F56  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F58  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F5A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F5C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F5E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F60  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F62  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F64  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F66  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F68  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F6A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F6C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F6E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F70  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F72  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F74  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F76  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F78  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F7A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F7C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F7E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F80  DD OFFSET LongJoNear,                   OFFSET LongJnoNear
lnt0F82  DD OFFSET LongJbNear,                   OFFSET LongJnbNear
lnt0F84  DD OFFSET LongJeNear,                   OFFSET LongJneNear
lnt0F86  DD OFFSET LongJbeNear,                  OFFSET LongJnbeNear
lnt0F88  DD OFFSET LongJsNear,                   OFFSET LongJnsNear
lnt0F8A  DD OFFSET LongJpNear,                   OFFSET LongJnpNear
lnt0F8C  DD OFFSET LongJlNear,                   OFFSET LongJnlNear
lnt0F8E  DD OFFSET LongJleNear,                  OFFSET LongJnleNear
lnt0F90  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F92  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F94  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F96  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F98  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F9A  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F9C  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0F9E  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FA0  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FA2  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FA4  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FA6  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FA8  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FAA  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FAC  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FAE  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FB0  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FB2  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FB4  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FB6  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FB8  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FBA  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FBC  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FBE  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FC0  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FC2  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FC4  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FC6  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FC8  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FCA  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FCC  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FCE  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FD0  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FD2  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FD4  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FD6  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FD8  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FDA  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FDC  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FDE  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FE0  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FE2  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FE4  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FE6  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FE8  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FEA  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FEC  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FEE  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FF0  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FF2  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FF4  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FF6  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FF8  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FFA  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FFC  DD OFFSET EmulateError,                 OFFSET EmulateError
lnt0FFE  DD OFFSET EmulateError,                 OFFSET EmulateError

Long0F:
        call ReadLongCodeByte
        movzx ebx,al
        shl ebx,2
        jmp dword ptr cs:[ebx].Long0FTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Long83
;
;               DESCRIPTION:    EMULATE 83 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Long83Tab:
ln83_000        DD OFFSET LongAddWordImsxMem
ln83_001        DD OFFSET EmulateError
ln83_010        DD OFFSET EmulateError
ln83_011        DD OFFSET EmulateError
ln83_100        DD OFFSET EmulateError
ln83_101        DD OFFSET EmulateError
ln83_110        DD OFFSET EmulateError
ln83_111        DD OFFSET LongCmpWordImsxMem

Long83:
        call ReadLongCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].Long83Tab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongFF
;
;               DESCRIPTION:    EMULATE FF instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LongFFTab:
lnFF_000        DD OFFSET EmulateError
lnFF_001        DD OFFSET EmulateError
lnFF_010        DD OFFSET EmulateError
lnFF_011        DD OFFSET LongCallFarMem
lnFF_100        DD OFFSET EmulateError
lnFF_101        DD OFFSET EmulateError
lnFF_110        DD OFFSET EmulateError
lnFF_111        DD OFFSET EmulateError

LongFF:
        call ReadLongCodeByte
        movzx ebx,al
        shr bl,2
        and bl,0Eh
        jmp dword ptr cs:[2*ebx].LongFFTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongTab
;
;               description:    emulate instruction
;
;               PARAMETERS:     DS:EBP           CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LongTab:
lnt00   DD OFFSET EmulateError,             OFFSET EmulateError
lnt02   DD OFFSET EmulateError,             OFFSET LongAddWordRegMem
lnt04   DD OFFSET EmulateError,             OFFSET EmulateError
lnt06   DD OFFSET EmulateError,             OFFSET EmulateError
lnt08   DD OFFSET EmulateError,             OFFSET EmulateError
lnt0A   DD OFFSET EmulateError,             OFFSET LongOrWordRegMem
lnt0C   DD OFFSET EmulateError,             OFFSET EmulateError
lnt0E   DD OFFSET EmulateError,             OFFSET Long0F
lnt10   DD OFFSET EmulateError,             OFFSET EmulateError
lnt12   DD OFFSET EmulateError,             OFFSET EmulateError
lnt14   DD OFFSET EmulateError,             OFFSET EmulateError
lnt16   DD OFFSET EmulateError,             OFFSET EmulateError
lnt18   DD OFFSET EmulateError,             OFFSET EmulateError
lnt1A   DD OFFSET EmulateError,             OFFSET EmulateError
lnt1C   DD OFFSET EmulateError,             OFFSET EmulateError
lnt1E   DD OFFSET EmulateError,             OFFSET EmulateError
lnt20   DD OFFSET EmulateError,             OFFSET EmulateError
lnt22   DD OFFSET EmulateError,             OFFSET EmulateError
lnt24   DD OFFSET EmulateError,             OFFSET EmulateError
lnt26   DD OFFSET EmulateError,             OFFSET EmulateError
lnt28   DD OFFSET EmulateError,             OFFSET EmulateError
lnt2A   DD OFFSET EmulateError,             OFFSET EmulateError
lnt2C   DD OFFSET EmulateError,             OFFSET EmulateError
lnt2E   DD OFFSET LongOverrideCs,           OFFSET EmulateError
lnt30   DD OFFSET EmulateError,             OFFSET EmulateError
lnt32   DD OFFSET EmulateError,             OFFSET EmulateError
lnt34   DD OFFSET EmulateError,             OFFSET EmulateError
lnt36   DD OFFSET EmulateError,             OFFSET EmulateError
lnt38   DD OFFSET EmulateError,             OFFSET EmulateError
lnt3A   DD OFFSET EmulateError,             OFFSET LongCmpWordRegMem
lnt3C   DD OFFSET LongCmpByteImAcc,         OFFSET EmulateError
lnt3E   DD OFFSET EmulateError,             OFFSET EmulateError
lnt40   DD OFFSET LongRex,                  OFFSET LongRex
lnt42   DD OFFSET LongRex,                  OFFSET LongRex
lnt44   DD OFFSET LongRex,                  OFFSET LongRex
lnt46   DD OFFSET LongRex,                  OFFSET LongRex
lnt48   DD OFFSET LongRex,                  OFFSET LongRex
lnt4A   DD OFFSET LongRex,                  OFFSET LongRex
lnt4C   DD OFFSET LongRex,                  OFFSET LongRex
lnt4E   DD OFFSET LongRex,                  OFFSET LongRex
lnt50   DD OFFSET LongPushRax,              OFFSET LongPushRcx
lnt52   DD OFFSET LongPushRdx,              OFFSET LongPushRbx
lnt54   DD OFFSET LongPushRsp,              OFFSET LongPushRbp
lnt56   DD OFFSET LongPushRsi,              OFFSET LongPushRdi
lnt58   DD OFFSET LongPopRax,               OFFSET LongPopRcx
lnt5A   DD OFFSET LongPopRdx,               OFFSET LongPopRbx
lnt5C   DD OFFSET LongPopRsp,               OFFSET LongPopRbp
lnt5E   DD OFFSET LongPopRsi,               OFFSET LongPopRdi
lnt60   DD OFFSET EmulateError,             OFFSET EmulateError
lnt62   DD OFFSET EmulateError,             OFFSET EmulateError
lnt64   DD OFFSET EmulateError,             OFFSET EmulateError
lnt66   DD OFFSET LongOverrideData,         OFFSET LongOverrideAdr
lnt68   DD OFFSET EmulateError,             OFFSET EmulateError
lnt6A   DD OFFSET EmulateError,             OFFSET EmulateError
lnt6C   DD OFFSET EmulateError,             OFFSET EmulateError
lnt6E   DD OFFSET EmulateError,             OFFSET EmulateError
lnt70   DD OFFSET LongJoShort,              OFFSET LongJnoShort
lnt72   DD OFFSET LongJbShort,              OFFSET LongJnbShort
lnt74   DD OFFSET LongJeShort,              OFFSET LongJneShort
lnt76   DD OFFSET LongJbeShort,             OFFSET LongJnbeShort
lnt78   DD OFFSET LongJsShort,              OFFSET LongJnsShort
lnt7A   DD OFFSET LongJpShort,              OFFSET LongJnpShort
lnt7C   DD OFFSET LongJlShort,              OFFSET LongJnlShort
lnt7E   DD OFFSET LongJleShort,             OFFSET LongJnleShort
lnt80   DD OFFSET EmulateError,             OFFSET EmulateError
lnt82   DD OFFSET EmulateError,             OFFSET Long83
lnt84   DD OFFSET EmulateError,             OFFSET EmulateError
lnt86   DD OFFSET LongXchgByteRegMem,       OFFSET LongXchgWordRegMem
lnt88   DD OFFSET EmulateError,             OFFSET EmulateError
lnt8A   DD OFFSET LongMoveByteMemToReg,     OFFSET LongMoveWordMemToReg
lnt8C   DD OFFSET EmulateError,             OFFSET EmulateError
lnt8E   DD OFFSET LongMoveMemToSreg,        OFFSET EmulateError
lnt90   DD OFFSET EmulateError,             OFFSET EmulateError
lnt92   DD OFFSET EmulateError,             OFFSET EmulateError
lnt94   DD OFFSET EmulateError,             OFFSET EmulateError
lnt96   DD OFFSET EmulateError,             OFFSET EmulateError
lnt98   DD OFFSET EmulateError,             OFFSET EmulateError
lnt9A   DD OFFSET EmulateError,             OFFSET EmulateError
lnt9C   DD OFFSET LongPushf,                OFFSET LongPopf
lnt9E   DD OFFSET EmulateError,             OFFSET EmulateError
lntA0   DD OFFSET EmulateError,             OFFSET EmulateError
lntA2   DD OFFSET EmulateError,             OFFSET EmulateError
lntA4   DD OFFSET EmulateError,             OFFSET EmulateError
lntA6   DD OFFSET EmulateError,             OFFSET EmulateError
lntA8   DD OFFSET EmulateError,             OFFSET EmulateError
lntAA   DD OFFSET EmulateError,             OFFSET EmulateError
lntAC   DD OFFSET EmulateError,             OFFSET EmulateError
lntAE   DD OFFSET EmulateError,             OFFSET EmulateError
lntB0   DD OFFSET LongMoveAlIm,             OFFSET LongMoveClIm
lntB2   DD OFFSET LongMoveDlIm,             OFFSET LongMoveBlIm
lntB4   DD OFFSET LongMoveAhIm,             OFFSET LongMoveChIm
lntB6   DD OFFSET LongMoveDhIm,             OFFSET LongMoveBhIm
lntB8   DD OFFSET LongMoveAxIm,             OFFSET LongMoveCxIm
lntBA   DD OFFSET LongMoveDxIm,             OFFSET LongMoveBxIm
lntBC   DD OFFSET LongMoveSpIm,             OFFSET LongMoveBpIm
lntBE   DD OFFSET LongMoveSiIm,             OFFSET LongMoveDiIm
lntC0   DD OFFSET EmulateError,             OFFSET EmulateError
lntC2   DD OFFSET EmulateError,             OFFSET LongRetNear
lntC4   DD OFFSET EmulateError,             OFFSET EmulateError
lntC6   DD OFFSET EmulateError,             OFFSET LongMoveWordImToMem
lntC8   DD OFFSET EmulateError,             OFFSET EmulateError
lntCA   DD OFFSET EmulateError,             OFFSET EmulateError
lntCC   DD OFFSET EmulateError,             OFFSET EmulateError
lntCE   DD OFFSET EmulateError,             OFFSET EmulateError
lntD0   DD OFFSET EmulateError,             OFFSET EmulateError
lntD2   DD OFFSET EmulateError,             OFFSET EmulateError
lntD4   DD OFFSET EmulateError,             OFFSET EmulateError
lntD6   DD OFFSET EmulateError,             OFFSET EmulateError
lntD8   DD OFFSET EmulateError,             OFFSET EmulateError
lntDA   DD OFFSET EmulateError,             OFFSET EmulateError
lntDC   DD OFFSET EmulateError,             OFFSET EmulateError
lntDE   DD OFFSET EmulateError,             OFFSET EmulateError
lntE0   DD OFFSET EmulateError,             OFFSET EmulateError
lntE2   DD OFFSET EmulateError,             OFFSET EmulateError
lntE4   DD OFFSET EmulateError,             OFFSET EmulateError
lntE6   DD OFFSET EmulateError,             OFFSET EmulateError
lntE8   DD OFFSET LongCallNear,             OFFSET LongJmpNear
lntEA   DD OFFSET EmulateError,             OFFSET LongJmpShort
lntEC   DD OFFSET EmulateError,             OFFSET EmulateError
lntEE   DD OFFSET EmulateError,             OFFSET EmulateError
lntF0   DD OFFSET EmulateError,             OFFSET EmulateError
lntF2   DD OFFSET EmulateError,             OFFSET EmulateError
lntF4   DD OFFSET EmulateError,             OFFSET EmulateError
lntF6   DD OFFSET EmulateError,             OFFSET EmulateError
lntF8   DD OFFSET EmulateError,             OFFSET EmulateError
lntFA   DD OFFSET EmCli,                    OFFSET EmSti
lntFC   DD OFFSET EmulateError,             OFFSET EmulateError
lntFE   DD OFFSET EmulateError,             OFFSET LongFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Emulate
;
;               description:    Emulate an instruction
;
;               PARAMETERS:     DS:ESP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public Emulate

Emulate Proc near
        pushad
;
        mov ax,ds:[ebp].reg_cs.d_access
        and al,ACCESS_RPL
        mov ds:[ebp].em_pl,al
;
        test ds:[ebp].reg_cs.d_access,ACCESS_32
        jz emulate_not32

emulate32:
        mov ds:[ebp].em_flags,a32 OR d32
        jmp emulate_start

emulate_not32:
        test ds:[ebp].reg_cs.d_access,ACCESS_64
        jnz emulate64        
;
        mov ds:[ebp].em_flags,0
        jmp emulate_start

emulate64:
        mov ds:[ebp].em_flags,l64 OR d32
        mov ds:[ebp].em_rex,0
        mov ds:[ebp].em_extra_bytes,0
;       
        mov eax,ds:[ebp].reg_eip
        mov ds:[ebp].org_eip,eax
        mov eax,ds:[ebp].reg_eip+4
        mov ds:[ebp].org_eip+4,eax
;
        mov eax,ds:[ebp].reg_esp
        mov ds:[ebp].org_esp,eax
        mov eax,ds:[ebp].reg_esp+4
        mov ds:[ebp].org_esp+4,eax
;        
        mov eax,esp
        sub eax,4
        mov ds:[ebp].org_stack,eax
;
        test ds:[ebp].reg_eflags,EFLAGS_IF
        jz emulate_no_int64
;
;        mov al,ds:[ebp].pending_int
;        or al,al
;        jz emulate_no_int64
        jmp emulate_no_int64
;
        call GetIntVector
        call HwInt
        jmp emulate_done

emulate_no_int64:
        test ds:[ebp].reg_eflags,EFLAGS_TF
        jz emulate_no_trap64
;
        mov al,1
        call IntFar
        jmp emulate_done

emulate_no_trap64:
        call ReadLongCodeByte
        test ds:[ebp].em_flags, single_faulted
        jnz emulate_done
;
        movzx ebx,al
        shl ebx,2
        call dword ptr cs:[ebx].LongTab
        jmp emulate_done

emulate_start:
        mov ds:[ebp].em_sreg,seg_def
;       
        mov eax,ds:[ebp].reg_eip
        mov ds:[ebp].org_eip,eax
        mov eax,ds:[ebp].reg_esp
        mov ds:[ebp].org_esp,eax
        mov eax,esp
        sub eax,4
        mov ds:[ebp].org_stack,eax
;
        test ds:[ebp].reg_eflags,EFLAGS_IF
        jz emulate_no_int
;
;        mov al,ds:[ebp].pending_int
;        or al,al
;        jz emulate_no_int
        jmp emulate_no_int
;
        call GetIntVector
        call HwInt
        jmp emulate_done

emulate_no_int:
        test ds:[ebp].reg_eflags,EFLAGS_TF
        jz emulate_no_trap
;
        mov al,1
        call IntFar
        jmp emulate_done

emulate_no_trap:
        call ReadCodeByte
        test ds:[ebp].em_flags, single_faulted
        jnz emulate_done
;
        movzx ebx,al
        shl ebx,2
        call dword ptr cs:[ebx].EmulateTab

emulate_done:
        popad
        ret
Emulate Endp

code    ENDS

        END
