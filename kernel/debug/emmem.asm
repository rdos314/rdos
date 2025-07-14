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
; EMMEM.ASM
; Memory operand emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include emcom.inc
include emseg.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   segment register override tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SegDsTab

SegDsTab:
dst0    DD OFFSET reg_es
dst1    DD OFFSET reg_cs
dst2    DD OFFSET reg_ss
dst3    DD OFFSET reg_ds
dst4    DD OFFSET reg_fs
dst5    DD OFFSET reg_gs
dst6    DD OFFSET reg_ds
dst7    DD OFFSET reg_ds

SegSsTab:
sst0    DD OFFSET reg_es
sst1    DD OFFSET reg_cs
sst2    DD OFFSET reg_ss
sst3    DD OFFSET reg_ds
sst4    DD OFFSET reg_fs
sst5    DD OFFSET reg_gs
sst6    DD OFFSET reg_ss
sst7    DD OFFSET reg_ss

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   memory addressing procedures
;
;               RETURNS:                ESI             segment
;                                               EBX             offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemBxSi PROC near
        movzx ebx,word ptr ds:[ebp].reg_ebx
        add bx,word ptr ds:[ebp].reg_esi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBxSi ENDP

MemBxDi PROC near
        movzx ebx,word ptr ds:[ebp].reg_ebx
        add bx,word ptr ds:[ebp].reg_edi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBxDi ENDP

MemBpSi PROC near
        movzx ebx,word ptr ds:[ebp].reg_ebp
        add bx,word ptr ds:[ebp].reg_esi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemBpSi ENDP

MemBpDi PROC near
        movzx ebx,word ptr ds:[ebp].reg_ebp
        add bx,word ptr ds:[ebp].reg_edi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemBpDi ENDP

        public MemSi

MemSi   PROC near
        movzx ebx,word ptr ds:[ebp].reg_esi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemSi   ENDP

        public MemDi

MemDi   PROC near
        movzx ebx,word ptr ds:[ebp].reg_edi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemDi   ENDP

        public MemD16

MemD16  PROC near
        call ReadCodeWord
        movzx ebx,ax
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemD16  ENDP

        public MemBx

MemBx   PROC near
        movzx ebx,word ptr ds:[ebp].reg_ebx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBx   ENDP

MemBxSiD8       PROC near
        call ReadCodeByte
        movsx bx,al
        add bx,word ptr ds:[ebp].reg_ebx
        add bx,word ptr ds:[ebp].reg_esi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBxSiD8       ENDP

MemBxDiD8       PROC near
        call ReadCodeByte
        movsx bx,al
        add bx,word ptr ds:[ebp].reg_ebx
        add bx,word ptr ds:[ebp].reg_edi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBxDiD8       ENDP

MemBpSiD8       PROC near
        call ReadCodeByte
        movsx bx,al
        add bx,word ptr ds:[ebp].reg_ebp
        add bx,word ptr ds:[ebp].reg_esi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemBpSiD8       ENDP

MemBpDiD8       PROC near
        call ReadCodeByte
        movsx bx,al
        add bx,word ptr ds:[ebp].reg_ebp
        add bx,word ptr ds:[ebp].reg_edi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemBpDiD8       ENDP

MemSiD8 PROC near
        call ReadCodeByte
        movsx bx,al
        add bx,word ptr ds:[ebp].reg_esi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemSiD8 ENDP

MemDiD8 PROC near
        call ReadCodeByte
        movsx bx,al
        add bx,word ptr ds:[ebp].reg_edi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemDiD8 ENDP

MemBpD8 PROC near
        call ReadCodeByte
        movsx bx,al
        add bx,word ptr ds:[ebp].reg_ebp
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemBpD8 ENDP

MemBxD8 PROC near
        call ReadCodeByte
        movsx bx,al
        add bx,word ptr ds:[ebp].reg_ebx
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBxD8 ENDP

MemBxSiD16      PROC near
        call ReadCodeWord
        mov bx,ax
        add bx,word ptr ds:[ebp].reg_ebx
        add bx,word ptr ds:[ebp].reg_esi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBxSiD16      ENDP

MemBxDiD16      PROC near
        call ReadCodeWord
        mov bx,ax
        add bx,word ptr ds:[ebp].reg_ebx
        add bx,word ptr ds:[ebp].reg_edi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBxDiD16      ENDP

MemBpSiD16      PROC near
        call ReadCodeWord
        mov bx,ax
        add bx,word ptr ds:[ebp].reg_ebp
        add bx,word ptr ds:[ebp].reg_esi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemBpSiD16      ENDP

MemBpDiD16      PROC near
        call ReadCodeWord
        mov bx,ax
        add bx,word ptr ds:[ebp].reg_ebp
        add bx,word ptr ds:[ebp].reg_edi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemBpDiD16      ENDP

MemSiD16        PROC near
        call ReadCodeWord
        mov bx,ax
        add bx,word ptr ds:[ebp].reg_esi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemSiD16        ENDP

MemDiD16        PROC near
        call ReadCodeWord
        mov bx,ax
        add bx,word ptr ds:[ebp].reg_edi
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemDiD16        ENDP

MemBpD16        PROC near
        call ReadCodeWord
        mov bx,ax
        add bx,word ptr ds:[ebp].reg_ebp
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemBpD16        ENDP

MemBxD16        PROC near
        call ReadCodeWord
        mov bx,ax
        add bx,word ptr ds:[ebp].reg_ebx
        movzx ebx,bx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemBxD16        ENDP

MemEax  PROC near
        mov ebx,ds:[ebp].reg_eax
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEax  ENDP

MemEcx  PROC near
        mov ebx,ds:[ebp].reg_ecx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEcx  ENDP

MemEdx  PROC near
        mov ebx,ds:[ebp].reg_edx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEdx  ENDP

        public MemEbx

MemEbx  PROC near
        mov ebx,ds:[ebp].reg_ebx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEbx  ENDP

        public MemD32

MemD32  PROC near
        call ReadCodeDword
        mov ebx,eax
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemD32  ENDP

        public MemEsi

MemEsi  PROC near
        mov ebx,ds:[ebp].reg_esi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEsi  ENDP

        public MemEdi

MemEdi  PROC near
        mov ebx,ds:[ebp].reg_edi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEdi  ENDP

MemEsp  PROC near
        mov ebx,ds:[ebp].reg_esp
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemEsp  ENDP

MemEaxD8        PROC near
        call ReadCodeByte
        movsx ebx,al
        add ebx,ds:[ebp].reg_eax
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEaxD8        ENDP

MemEcxD8        PROC near
        call ReadCodeByte
        movsx ebx,al
        add ebx,ds:[ebp].reg_ecx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEcxD8        ENDP

MemEdxD8        PROC near
        call ReadCodeByte
        movsx ebx,al
        add ebx,ds:[ebp].reg_edx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEdxD8        ENDP

MemEbxD8        PROC near
        call ReadCodeByte
        movsx ebx,al
        add ebx,ds:[ebp].reg_ebx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEbxD8        ENDP

MemEbpD8        PROC near
        call ReadCodeByte
        movsx ebx,al
        add ebx,ds:[ebp].reg_ebp
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemEbpD8        ENDP

MemEsiD8        PROC near
        call ReadCodeByte
        movsx ebx,al
        add ebx,ds:[ebp].reg_esi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEsiD8        ENDP

MemEdiD8        PROC near
        call ReadCodeByte
        movsx ebx,al
        add ebx,ds:[ebp].reg_edi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEdiD8        ENDP

MemEspD8        PROC near
        call ReadCodeByte
        movsx ebx,al
        add ebx,ds:[ebp].reg_esp
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemEspD8        ENDP

MemEaxD32       PROC near
        call ReadCodeDword
        mov ebx,eax
        add ebx,ds:[ebp].reg_eax
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEaxD32       ENDP

MemEcxD32       PROC near
        call ReadCodeDword
        mov ebx,eax
        add ebx,ds:[ebp].reg_ecx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEcxD32       ENDP

MemEdxD32       PROC near
        call ReadCodeDword
        mov ebx,eax
        add ebx,ds:[ebp].reg_edx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEdxD32       ENDP

MemEbxD32       PROC near
        call ReadCodeDword
        mov ebx,eax
        add ebx,ds:[ebp].reg_ebx
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEbxD32       ENDP

MemEbpD32       PROC near
        call ReadCodeDword
        mov ebx,eax
        add ebx,ds:[ebp].reg_ebp
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemEbpD32       ENDP

MemEsiD32       PROC near
        call ReadCodeDword
        mov ebx,eax
        add ebx,ds:[ebp].reg_esi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEsiD32       ENDP

MemEdiD32       PROC near
        call ReadCodeDword
        mov ebx,eax
        add ebx,ds:[ebp].reg_edi
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegDsTab
        ret
MemEdiD32       ENDP

MemEspD32       PROC near
        call ReadCodeDword
        mov ebx,eax
        add ebx,ds:[ebp].reg_esp
        movzx esi,byte ptr ds:[ebp].em_sreg
        mov esi,dword ptr cs:[4*esi].SegSsTab
        ret
MemEspD32       ENDP

SibIndexTab:
sit000  DD OFFSET reg_eax
sit001  DD OFFSET reg_ecx
sit010  DD OFFSET reg_edx
sit011  DD OFFSET reg_ebx
sit100  DD 0
sit101  DD OFFSET reg_ebp
sit110  DD OFFSET reg_esi
sit111  DD OFFSET reg_edi

Sib0Tab:
sib0_000        DD OFFSET MemEax
sib0_001        DD OFFSET MemEcx
sib0_010        DD OFFSET MemEdx
sib0_011        DD OFFSET MemEbx
sib0_100        DD OFFSET MemEsp
sib0_101        DD OFFSET MemD32
sib0_110        DD OFFSET MemEsi
sib0_111        DD OFFSET MemEdi

Sib1Tab:
sib1_000        DD OFFSET MemEaxD8
sib1_001        DD OFFSET MemEcxD8
sib1_010        DD OFFSET MemEdxD8
sib1_011        DD OFFSET MemEbxD8
sib1_100        DD OFFSET MemEspD8
sib1_101        DD OFFSET MemEbpD8
sib1_110        DD OFFSET MemEsiD8
sib1_111        DD OFFSET MemEdiD8

Sib2Tab:
sib2_000        DD OFFSET MemEaxD32
sib2_001        DD OFFSET MemEcxD32
sib2_010        DD OFFSET MemEdxD32
sib2_011        DD OFFSET MemEbxD32
sib2_100        DD OFFSET MemEspD32
sib2_101        DD OFFSET MemEbpD32
sib2_110        DD OFFSET MemEsiD32
sib2_111        DD OFFSET MemEdiD32
 
MemSib0 PROC near
        call ReadCodeByte
        push ax
        movzx ebx,al
        and bl,7
        shl ebx,2
        call dword ptr cs:[ebx].Sib0Tab
        pop ax
        mov cl,al
        shr cl,6
        and cl,3
        mov di,ax
        shr di,2
        and edi,0Eh
        mov edi,dword ptr cs:[2*edi].SibIndexTab
        or edi,edi
        jz MemSib0Done
;
        mov eax,ds:[ebp+edi]
        shl eax,cl
        add ebx,eax

MemSib0Done:
        ret
MemSib0 ENDP
 
MemSib1 PROC near
        call ReadCodeByte
        push ax
        movzx ebx,al
        and bl,7
        shl ebx,2
        call dword ptr cs:[ebx].Sib1Tab
        pop ax
        mov cl,al
        shr cl,6
        and cl,3
        mov di,ax
        shr di,2
        and edi,0Eh
        mov edi,dword ptr cs:[2*edi].SibIndexTab
        or edi,edi
        jz MemSib1Done
;
        mov eax,ds:[ebp+edi]
        shl eax,cl
        add ebx,eax

MemSib1Done:
        ret
MemSib1 ENDP

MemSib2 PROC near
        call ReadCodeByte
        push ax
        movzx ebx,al
        and bl,7
        shl ebx,2
        call dword ptr cs:[ebx].Sib2Tab
        pop ax
        mov cl,al
        shr cl,6
        and cl,3
        mov di,ax
        shr di,2
        and edi,0Eh
        mov edi,dword ptr cs:[2*edi].SibIndexTab
        or edi,edi
        jz MemSib2Done
;
        mov eax,ds:[ebp+edi]
        shl eax,cl
        add ebx,eax

MemSib2Done:
        ret
MemSib2 ENDP

        public MemTab

MemTab:
mem16_00000     DD OFFSET MemBxSi
mem16_00001     DD OFFSET MemBxDi
mem16_00010     DD OFFSET MemBpSi
mem16_00011     DD OFFSET MemBpDi
mem16_00100     DD OFFSET MemSi
mem16_00101     DD OFFSET MemDi
mem16_00110     DD OFFSET MemD16
mem16_00111     DD OFFSET MemBx
mem16_01000     DD OFFSET MemBxSiD8
mem16_01001     DD OFFSET MemBxDiD8
mem16_01010     DD OFFSET MemBpSiD8
mem16_01011     DD OFFSET MemBpDiD8
mem16_01100     DD OFFSET MemSiD8
mem16_01101     DD OFFSET MemDiD8
mem16_01110     DD OFFSET MemBpD8
mem16_01111     DD OFFSET MemBxD8
mem16_10000     DD OFFSET MemBxSiD16
mem16_10001     DD OFFSET MemBxDiD16
mem16_10010     DD OFFSET MemBpSiD16
mem16_10011     DD OFFSET MemBpDiD16
mem16_10100     DD OFFSET MemSiD16
mem16_10101     DD OFFSET MemDiD16
mem16_10110     DD OFFSET MemBpD16
mem16_10111     DD OFFSET MemBxD16
mem16_11000     DD OFFSET EmulateError
mem16_11001     DD OFFSET EmulateError
mem16_11010     DD OFFSET EmulateError
mem16_11011     DD OFFSET EmulateError
mem16_11100     DD OFFSET EmulateError
mem16_11101     DD OFFSET EmulateError
mem16_11110     DD OFFSET EmulateError
mem16_11111     DD OFFSET EmulateError
;
mem32_00000     DD OFFSET MemEax
mem32_00001     DD OFFSET MemEcx
mem32_00010     DD OFFSET MemEdx
mem32_00011     DD OFFSET MemEbx
mem32_00100     DD OFFSET MemSib0
mem32_00101     DD OFFSET MemD32
mem32_00110     DD OFFSET MemEsi
mem32_00111     DD OFFSET MemEdi
mem32_01000     DD OFFSET MemEaxD8
mem32_01001     DD OFFSET MemEcxD8
mem32_01010     DD OFFSET MemEdxD8
mem32_01011     DD OFFSET MemEbxD8
mem32_01100     DD OFFSET MemSib1
mem32_01101     DD OFFSET MemEbpD8
mem32_01110     DD OFFSET MemEsiD8
mem32_01111     DD OFFSET MemEdiD8
mem32_10000     DD OFFSET MemEaxD32
mem32_10001     DD OFFSET MemEcxD32
mem32_10010     DD OFFSET MemEdxD32
mem32_10011     DD OFFSET MemEbxD32
mem32_10100     DD OFFSET MemSib2
mem32_10101     DD OFFSET MemEbpD32
mem32_10110     DD OFFSET MemEsiD32
mem32_10111     DD OFFSET MemEdiD32
mem32_11000     DD OFFSET EmulateError
mem32_11001     DD OFFSET EmulateError
mem32_11010     DD OFFSET EmulateError
mem32_11011     DD OFFSET EmulateError
mem32_11100     DD OFFSET EmulateError
mem32_11101     DD OFFSET EmulateError
mem32_11110     DD OFFSET EmulateError
mem32_11111     DD OFFSET EmulateError

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   register load/save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ByteRegTab

ByteRegTab:
regs_11000      DD OFFSET reg_eax
regs_11001      DD OFFSET reg_ecx
regs_11010      DD OFFSET reg_edx
regs_11011      DD OFFSET reg_ebx
regs_11100      DD OFFSET reg_eax+1
regs_11101      DD OFFSET reg_ecx+1
regs_11110      DD OFFSET reg_edx+1
regs_11111      DD OFFSET reg_ebx+1

        public WordRegTab
        public DwordRegTab

WordRegTab:
DwordRegTab:
regl_11000      DD OFFSET reg_eax
regl_11001      DD OFFSET reg_ecx
regl_11010      DD OFFSET reg_edx
regl_11011      DD OFFSET reg_ebx
regl_11100      DD OFFSET reg_esp
regl_11101      DD OFFSET reg_ebp
regl_11110      DD OFFSET reg_esi
regl_11111      DD OFFSET reg_edi

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadByteMemReg
;
;               DESCRIPTION:    Load byte from memory / reg
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        AL              data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadByteMemReg

LoadByteMemReg  Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je LoadByteMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadByteMemReg16
        or bl,40h       
LoadByteMemReg16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadByte
        ret

LoadByteMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov al,ds:[ebp+esi]
        ret
LoadByteMemReg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadWordMemReg
;
;               DESCRIPTION:    Load word from memory / reg
;
;               PARAMETERS:     BL              op code
;
;               RETURNS:        AX              data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadWordMemReg

LoadWordMemReg  Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je LoadWordMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadWordMemReg16
        or bl,40h       
LoadWordMemReg16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadWord
        ret

LoadWordMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ax,ds:[ebp+esi]
        ret
LoadWordMemReg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadDwordMemReg
;
;               DESCRIPTION:    Load dword from memory / reg
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        EAX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadDwordMemReg

LoadDwordMemReg Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je LoadDwordMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadDwordMemReg16
        or bl,40h       
LoadDwordMemReg16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadDword
        ret

LoadDwordMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        ret
LoadDwordMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveByteMemReg
;
;               DESCRIPTION:    Save byte to memory / reg
;
;               PARAMETERS:     AL              data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveByteMemReg

SaveByteMemReg  Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je SaveByteMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveByteMemReg16
        or bl,40h       
SaveByteMemReg16:
        movzx ebx,bl
        push ax
        call dword ptr cs:[2*ebx].MemTab
        pop ax
        call WriteByte
        ret

SaveByteMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov ds:[ebp+esi],al
        ret
SaveByteMemReg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveWordMemReg
;
;               DESCRIPTION:    Save word to memory / reg
;
;               PARAMETERS:     AX              data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveWordMemReg

SaveWordMemReg  Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je SaveWordMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveWordMemReg16
        or bl,40h       
SaveWordMemReg16:
        movzx ebx,bl
        push ax
        call dword ptr cs:[2*ebx].MemTab
        pop ax
        call WriteWord
        ret

SaveWordMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ds:[ebp+esi],ax
        ret
SaveWordMemReg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveDwordMemReg
;
;               DESCRIPTION:    Save dword to memory / reg
;
;               PARAMETERS:     EAX             data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveDwordMemReg

SaveDwordMemReg Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je SaveDwordMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveDwordMemReg16
        or bl,40h       
SaveDwordMemReg16:
        movzx ebx,bl
        push eax
        call dword ptr cs:[2*ebx].MemTab
        pop eax
        call WriteDword
        ret

SaveDwordMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ds:[ebp+esi],eax
        ret
SaveDwordMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadByteMem
;
;               DESCRIPTION:    Load byte from memory
;
;               PARAMETER:      BL              op-code
;
;               RETURNS:        AL              data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadByteMem

LoadByteMem     Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadByteMem16
        or bl,40h       
LoadByteMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadByte
        ret
LoadByteMem     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadWordMem
;
;               DESCRIPTION:    Load word from memory
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        AX              data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadWordMem

LoadWordMem     Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadWordMem16
        or bl,40h       
LoadWordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadWord
        ret
LoadWordMem     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadDwordMem
;
;               DESCRIPTION:    Load dword from memory
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        EAX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadDwordMem

LoadDwordMem    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadDwordMem16
        or bl,40h       
LoadDwordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadDword
        ret
LoadDwordMem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadFwordMem
;
;               DESCRIPTION:    Load fword from memory
;
;               PARAMETERS:     BL                      op-code
;
;               RETURNS:        DX:EAX                  data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadFwordMem

LoadFwordMem    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadFwordMem16
        or bl,40h       
LoadFwordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadFword
        ret
LoadFwordMem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadQwordMem
;
;               DESCRIPTION:    Load qword from memory
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        EDX:EAX         data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadQwordMem

LoadQwordMem    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadQwordMem16
        or bl,40h       
LoadQwordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadQword
        ret
LoadQwordMem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadTbyteMem
;
;               DESCRIPTION:    Load tbyte from memory
;
;               PARAMETERS:     BL                      op-code
;
;               RETURNS:        CX:EDX:EAX              data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadTbyteMem

LoadTbyteMem    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz LoadTbyteMem16
        or bl,40h       
LoadTbyteMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadTbyte
        ret
LoadTbyteMem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveByteMem
;
;               DESCRIPTION:    Save byte to memory
;
;               PARAMETERS:     AL              data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveByteMem

SaveByteMem     Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveByteMem16
        or bl,40h       
SaveByteMem16:
        movzx ebx,bl
        push ax
        call dword ptr cs:[2*ebx].MemTab
        pop ax
        call WriteByte
        ret
SaveByteMem     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveWordMem
;
;               DESCRIPTION:    Save word to memory
;
;               PARAMETERS:     AX              data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveWordMem

SaveWordMem     Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveWordMem16
        or bl,40h       
SaveWordMem16:
        movzx ebx,bl
        push ax
        call dword ptr cs:[2*ebx].MemTab
        pop ax
        call WriteWord
        ret
SaveWordMem     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveDwordMem
;
;               DESCRIPTION:    Save dword to memory
;
;               PARAMETERS:     EAX             data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveDwordMem

SaveDwordMem    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveDwordMem16
        or bl,40h       
SaveDwordMem16:
        movzx ebx,bl
        push eax
        call dword ptr cs:[2*ebx].MemTab
        pop eax
        call WriteDword
        ret
SaveDwordMem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveFwordMem
;
;               DESCRIPTION:    Save fword to memory
;
;               PARAMETERS:     DX:EAX          data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveFwordMem

SaveFwordMem    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveFwordMem16
        or bl,40h       
SaveFwordMem16:
        movzx ebx,bl
        push eax
        push dx
        call dword ptr cs:[2*ebx].MemTab
        pop dx
        pop eax
        call WriteFword
        ret
SaveFwordMem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveQwordMem
;
;               DESCRIPTION:    Save qword to memory
;
;               PARAMETERS:     EDX:EAX         data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveQwordMem

SaveQwordMem    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveQwordMem16
        or bl,40h       
SaveQwordMem16:
        movzx ebx,bl
        push eax
        push edx
        call dword ptr cs:[2*ebx].MemTab
        pop edx
        pop eax
        call WriteQword
        ret
SaveQwordMem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveTbyteMem
;
;               DESCRIPTION:    Save tbyte to memory
;
;               PARAMETERS:     CX:EDX:EAX              data to save
;                               BL                      op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveTbyteMem

SaveTbyteMem    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz SaveTbyteMem16
        or bl,40h       
SaveTbyteMem16:
        movzx ebx,bl
        push eax
        push edx
        push cx
        call dword ptr cs:[2*ebx].MemTab
        pop cx
        pop edx
        pop eax
        call WriteTbyte
        ret
SaveTbyteMem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadByteReg
;
;               DESCRIPTION:    Load byte from reg
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        AL              data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadByteReg

LoadByteReg     Proc near
        shr bl,2
        and bl,0Eh
        movzx esi,bl
        mov esi,dword ptr cs:[2*esi].ByteRegTab
        mov al,ds:[ebp+esi]
        ret
LoadByteReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadWordReg
;
;               DESCRIPTION:    Load word from reg
;
;               PARAMETERS:     BL              op code
;
;               RETURNS:        AX              data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadWordReg

LoadWordReg     Proc near
        shr bl,2
        and bl,0Eh
        movzx esi,bl
        mov esi,dword ptr cs:[2*esi].WordRegTab
        mov ax,ds:[ebp+esi]
        ret
LoadWordReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadDwordReg
;
;               DESCRIPTION:    Load dword from reg
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        EAX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadDwordReg

LoadDwordReg    Proc near
        shr bl,2
        and bl,0Eh
        movzx esi,bl
        mov esi,dword ptr cs:[2*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        ret
LoadDwordReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveByteReg
;
;               DESCRIPTION:    Save byte to reg
;
;               PARAMETERS:     AL              data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveByteReg

SaveByteReg     Proc near
        shr bl,2
        and bl,0Eh
        movzx esi,bl
        mov esi,dword ptr cs:[2*esi].ByteRegTab
        mov ds:[ebp+esi],al
        ret
SaveByteReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveWordReg
;
;               DESCRIPTION:    Save word to reg
;
;               PARAMETERS:     AX              data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveWordReg

SaveWordReg     Proc near
        shr bl,2
        and bl,0Eh
        movzx esi,bl
        mov esi,dword ptr cs:[2*esi].WordRegTab
        mov ds:[ebp+esi],ax
        ret
SaveWordReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SaveDwordReg
;
;               DESCRIPTION:    Save dword to reg
;
;               PARAMETERS:     EAX             data to save
;                               BL              op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveDwordReg

SaveDwordReg    Proc near
        shr bl,2
        and bl,0Eh
        movzx esi,bl
        mov esi,dword ptr cs:[2*esi].DwordRegTab
        mov ds:[ebp+esi],eax
        ret
SaveDwordReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           GetMemAddress
;
;               DESCRIPTION:    Get memory address of operand
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        EDI:EBX         Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GetMemAddress

GetMemAddress    Proc near
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz GetMemAddressDo
;        
        or bl,40h
               
GetMemAddressDo:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        ret
GetMemAddress   Endp

code    ENDS

        END
