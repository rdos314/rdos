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
; LNMEM.ASM
; Long memory operand emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include emcom.inc
include emseg.inc
include empage.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   memory addressing procedures
;
;               RETURNS:                EDI:EBX             offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemEax PROC near
    mov ebx,ds:[ebp].reg_eax
    xor edi,edi
    ret
MemEax ENDP

MemEcx PROC near
    mov ebx,ds:[ebp].reg_ecx
    xor edi,edi
    ret
MemEcx ENDP

MemEdx PROC near
    mov ebx,ds:[ebp].reg_edx
    xor edi,edi
    ret
MemEdx ENDP

MemEbx PROC near
    mov ebx,ds:[ebp].reg_ebx
    xor edi,edi
    ret
MemEbx ENDP

MemEsi PROC near
    mov ebx,ds:[ebp].reg_esi
    xor edi,edi
    ret
MemEsi ENDP

MemEdi PROC near
    mov ebx,ds:[ebp].reg_edi
    xor edi,edi
    ret
MemEdi ENDP

MemEbp PROC near
    mov ebx,ds:[ebp].reg_ebp
    xor edi,edi
    ret
MemEbp ENDP

MemEsp PROC near
    mov ebx,ds:[ebp].reg_esp
    xor edi,edi
    ret
MemEsp ENDP

MemR8d PROC near
    mov ebx,ds:[ebp].reg_r8
    xor edi,edi
    ret
MemR8d ENDP

MemR9d PROC near
    mov ebx,ds:[ebp].reg_r9
    xor edi,edi
    ret
MemR9d ENDP

MemR10d PROC near
    mov ebx,ds:[ebp].reg_r10
    xor edi,edi
    ret
MemR10d ENDP

MemR11d PROC near
    mov ebx,ds:[ebp].reg_r11
    xor edi,edi
    ret
MemR11d ENDP

MemR12d PROC near
    mov ebx,ds:[ebp].reg_r12
    xor edi,edi
    ret
MemR12d ENDP

MemR13d PROC near
    mov ebx,ds:[ebp].reg_r13
    xor edi,edi
    ret
MemR13d ENDP

MemR14d PROC near
    mov ebx,ds:[ebp].reg_r14
    xor edi,edi
    ret
MemR14d ENDP

MemR15d PROC near
    mov ebx,ds:[ebp].reg_r15
    xor edi,edi
    ret
MemR15d ENDP

MemRax PROC near
    mov ebx,ds:[ebp].reg_eax
    mov edi,ds:[ebp].reg_eax+4
    ret
MemRax ENDP

MemRcx PROC near
    mov ebx,ds:[ebp].reg_ecx
    mov edi,ds:[ebp].reg_ecx+4
    ret
MemRcx ENDP

MemRdx PROC near
    mov ebx,ds:[ebp].reg_edx
    mov edi,ds:[ebp].reg_edx+4
    ret
MemRdx ENDP

MemRbx PROC near
    mov ebx,ds:[ebp].reg_ebx
    mov edi,ds:[ebp].reg_ebx+4
    ret
MemRbx ENDP

MemRsi PROC near
    mov ebx,ds:[ebp].reg_esi
    mov edi,ds:[ebp].reg_esi+4
    ret
MemRsi ENDP

MemRdi PROC near
    mov ebx,ds:[ebp].reg_edi
    mov edi,ds:[ebp].reg_edi+4
    ret
MemRdi ENDP

MemRbp PROC near
    mov ebx,ds:[ebp].reg_ebp
    mov edi,ds:[ebp].reg_ebp+4
    ret
MemRbp ENDP

MemRsp PROC near
    mov ebx,ds:[ebp].reg_esp
    mov edi,ds:[ebp].reg_esp+4
    ret
MemRsp ENDP

MemR8 PROC near
    mov ebx,ds:[ebp].reg_r8
    mov edi,ds:[ebp].reg_r8+4
    ret
MemR8 ENDP

MemR9 PROC near
    mov ebx,ds:[ebp].reg_r9
    mov edi,ds:[ebp].reg_r9+4
    ret
MemR9 ENDP

MemR10 PROC near
    mov ebx,ds:[ebp].reg_r10
    mov edi,ds:[ebp].reg_r10+4
    ret
MemR10 ENDP

MemR11 PROC near
    mov ebx,ds:[ebp].reg_r11
    mov edi,ds:[ebp].reg_r11+4
    ret
MemR11 ENDP

MemR12 PROC near
    mov ebx,ds:[ebp].reg_r12
    mov edi,ds:[ebp].reg_r12+4
    ret
MemR12 ENDP

MemR13 PROC near
    mov ebx,ds:[ebp].reg_r13
    mov edi,ds:[ebp].reg_r13+4
    ret
MemR13 ENDP

MemR14 PROC near
    mov ebx,ds:[ebp].reg_r14
    mov edi,ds:[ebp].reg_r14+4
    ret
MemR14 ENDP

MemR15 PROC near
    mov ebx,ds:[ebp].reg_r15
    mov edi,ds:[ebp].reg_r15+4
    ret
MemR15 ENDP

MemEaxD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_eax
    xor edi,edi
    ret
MemEaxD8 ENDP

MemEcxD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_ecx
    xor edi,edi
    ret
MemEcxD8 ENDP

MemEdxD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_edx
    xor edi,edi
    ret
MemEdxD8 ENDP

MemEbxD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_ebx
    xor edi,edi
    ret
MemEbxD8 ENDP

MemEbpD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_ebp
    xor edi,edi
    ret
MemEbpD8 ENDP

MemEsiD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_esi
    xor edi,edi
    ret
MemEsiD8 ENDP

MemEdiD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_edi
    xor edi,edi
    ret
MemEdiD8 ENDP

MemR8dD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_r8
    xor edi,edi
    ret
MemR8dD8 ENDP

MemR9dD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_r9
    xor edi,edi
    ret
MemR9dD8 ENDP

MemR10dD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_r10
    xor edi,edi
    ret
MemR10dD8 ENDP

MemR11dD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_r11
    xor edi,edi
    ret
MemR11dD8 ENDP

MemR13dD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_r13
    xor edi,edi
    ret
MemR13dD8 ENDP

MemR14dD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_r14
    xor edi,edi
    ret
MemR14dD8 ENDP

MemR15dD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    add ebx,ds:[ebp].reg_r15
    xor edi,edi
    ret
MemR15dD8 ENDP

MemRaxD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_eax
    adc edi,ds:[ebp].reg_eax+4
    ret
MemRaxD8 ENDP

MemRcxD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_ecx
    adc edi,ds:[ebp].reg_ecx+4
    ret
MemRcxD8 ENDP

MemRdxD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_edx
    adc edi,ds:[ebp].reg_edx+4
    ret
MemRdxD8 ENDP

MemRbxD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_ebx
    adc edi,ds:[ebp].reg_ebx+4
    ret
MemRbxD8 ENDP

MemRbpD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_ebp
    adc edi,ds:[ebp].reg_ebp+4
    ret
MemRbpD8 ENDP

MemRsiD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_esi
    adc edi,ds:[ebp].reg_esi+4
    ret
MemRsiD8 ENDP

MemRdiD8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_edi
    adc edi,ds:[ebp].reg_edi+4
    ret
MemRdiD8 ENDP

MemR8D8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r8
    adc edi,ds:[ebp].reg_r8+4
    ret
MemR8D8 ENDP

MemR9D8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r9
    adc edi,ds:[ebp].reg_r9+4
    ret
MemR9D8 ENDP

MemR10D8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r10
    adc edi,ds:[ebp].reg_r10+4
    ret
MemR10D8 ENDP

MemR11D8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r11
    adc edi,ds:[ebp].reg_r11+4
    ret
MemR11D8 ENDP

MemR13D8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r13
    adc edi,ds:[ebp].reg_r13+4
    ret
MemR13D8 ENDP

MemR14D8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r14
    adc edi,ds:[ebp].reg_r14+4
    ret
MemR14D8 ENDP

MemR15D8 PROC near
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r15
    adc edi,ds:[ebp].reg_r15+4
    ret
MemR15D8 ENDP

MemEaxD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_eax
    xor edi,edi
    ret
MemEaxD32 ENDP

MemEcxD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_ecx
    xor edi,edi
    ret
MemEcxD32 ENDP

MemEdxD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_edx
    xor edi,edi
    ret
MemEdxD32 ENDP

MemEbxD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_ebx
    xor edi,edi
    ret
MemEbxD32 ENDP

MemEbpD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_ebp
    xor edi,edi
    ret
MemEbpD32 ENDP

MemEsiD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_esi
    xor edi,edi
    ret
MemEsiD32 ENDP

MemEdiD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_edi
    xor edi,edi
    ret
MemEdiD32 ENDP

MemR8dD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_r8
    xor edi,edi
    ret
MemR8dD32 ENDP

MemR9dD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_r9
    xor edi,edi
    ret
MemR9dD32 ENDP

MemR10dD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_r10
    xor edi,edi
    ret
MemR10dD32 ENDP

MemR11dD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_r11
    xor edi,edi
    ret
MemR11dD32 ENDP

MemR13dD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_r13
    xor edi,edi
    ret
MemR13dD32 ENDP

MemR14dD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_r14
    xor edi,edi
    ret
MemR14dD32 ENDP

MemR15dD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_r15
    xor edi,edi
    ret
MemR15dD32 ENDP

MemRaxD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_eax
    adc edi,ds:[ebp].reg_eax+4
    ret
MemRaxD32 ENDP

MemRcxD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_ecx
    adc edi,ds:[ebp].reg_ecx+4
    ret
MemRcxD32 ENDP

MemRdxD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_edx
    adc edi,ds:[ebp].reg_edx+4
    ret
MemRdxD32 ENDP

MemRbxD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_ebx
    adc edi,ds:[ebp].reg_ebx+4
    ret
MemRbxD32 ENDP

MemRbpD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_ebp
    adc edi,ds:[ebp].reg_ebp+4
    ret
MemRbpD32 ENDP

MemRsiD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_esi
    adc edi,ds:[ebp].reg_esi+4
    ret
MemRsiD32 ENDP

MemRdiD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_edi
    adc edi,ds:[ebp].reg_edi+4
    ret
MemRdiD32 ENDP

MemR8D32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r8
    adc edi,ds:[ebp].reg_r8+4
    ret
MemR8D32 ENDP

MemR9D32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r9
    adc edi,ds:[ebp].reg_r9+4
    ret
MemR9D32 ENDP

MemR10D32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r10
    adc edi,ds:[ebp].reg_r10+4
    ret
MemR10D32 ENDP

MemR11D32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r11
    adc edi,ds:[ebp].reg_r11+4
    ret
MemR11D32 ENDP

MemR13D32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r13
    adc edi,ds:[ebp].reg_r13+4
    ret
MemR13D32 ENDP

MemR14D32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r14
    adc edi,ds:[ebp].reg_r14+4
    ret
MemR14D32 ENDP

MemR15D32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_r15
    adc edi,ds:[ebp].reg_r15+4
    ret
MemR15D32 ENDP

MemEipD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    add ebx,ds:[ebp].reg_eip
    movzx eax,ds:[ebp].em_extra_bytes
    add ebx,eax
    xor edi,edi
    ret
MemEipD32 ENDP

MemRipD32 PROC near
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    add ebx,ds:[ebp].reg_eip
    adc edi,ds:[ebp].reg_eip+4
    movzx eax,ds:[ebp].em_extra_bytes
    add ebx,eax
    adc edi,0
    ret
MemRipD32 ENDP

MemSibD8    PROC near
    call MemSib
    push edi
    push ebx
    call ReadLongCodeByte
    movzx ebx,al
    xor edi,edi
    mov eax,ebx
    rcl eax,1
    sbb edi,0
    pop eax
    add ebx,eax
    pop eax
    adc edi,eax
    ret
MemSibD8    ENDP

MemSibD32 PROC near
    call MemSib
    push edi
    push ebx
    call ReadLongCodeDword
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0
    pop eax
    add ebx,eax
    pop eax
    adc edi,eax
    ret
MemSibD32 ENDP

MemNone PROC near
    xor ebx,ebx
    xor edi,edi
    ret
MemNone Endp

MemModD32   PROC near
    xor ebx,ebx
    xor edi,edi
;    
    test al,0C0h
    jnz mm32Done
;
    call ReadLongCodeDword    
    mov ebx,eax
    xor edi,edi
    rcl eax,1
    sbb edi,0

mm32Done:
    ret
MemModD32   ENDP        

    public LongMemTab

LongMemTab:
mem32_000000     DD OFFSET MemEax
mem32_000001     DD OFFSET MemEcx
mem32_000010     DD OFFSET MemEdx
mem32_000011     DD OFFSET MemEbx
mem32_000100     DD OFFSET MemSib
mem32_000101     DD OFFSET MemEipD32
mem32_000110     DD OFFSET MemEsi
mem32_000111     DD OFFSET MemEdi
mem32_001000     DD OFFSET MemR8d
mem32_001001     DD OFFSET MemR9d
mem32_001010     DD OFFSET MemR10d
mem32_001011     DD OFFSET MemR11d
mem32_001100     DD OFFSET MemSib
mem32_001101     DD OFFSET MemEipD32
mem32_001110     DD OFFSET MemR14d
mem32_001111     DD OFFSET MemR15d
mem32_010000     DD OFFSET MemEaxD8
mem32_010001     DD OFFSET MemEcxD8
mem32_010010     DD OFFSET MemEdxD8
mem32_010011     DD OFFSET MemEbxD8
mem32_010100     DD OFFSET MemSibD8
mem32_010101     DD OFFSET MemEbpD8
mem32_010110     DD OFFSET MemEsiD8
mem32_010111     DD OFFSET MemEdiD8
mem32_011000     DD OFFSET MemR8dD8
mem32_011001     DD OFFSET MemR9dD8
mem32_011010     DD OFFSET MemR10dD8
mem32_011011     DD OFFSET MemR11dD8
mem32_011100     DD OFFSET MemSibD8
mem32_011101     DD OFFSET MemR13dD8
mem32_011110     DD OFFSET MemR14dD8
mem32_011111     DD OFFSET MemR15dD8
mem32_100000     DD OFFSET MemEaxD32
mem32_100001     DD OFFSET MemEcxD32
mem32_100010     DD OFFSET MemEdxD32
mem32_100011     DD OFFSET MemEbxD32
mem32_100100     DD OFFSET MemSibD32
mem32_100101     DD OFFSET MemEbpD32
mem32_100110     DD OFFSET MemEsiD32
mem32_100111     DD OFFSET MemEdiD32
mem32_101000     DD OFFSET MemR8dD32
mem32_101001     DD OFFSET MemR9dD32
mem32_101010     DD OFFSET MemR10dD32
mem32_101011     DD OFFSET MemR11dD32
mem32_101100     DD OFFSET MemSibD32
mem32_101101     DD OFFSET MemR13dD32
mem32_101110     DD OFFSET MemR14dD32
mem32_101111     DD OFFSET MemR15dD32
mem32_110000     DD OFFSET EmulateError
mem32_110001     DD OFFSET EmulateError
mem32_110010     DD OFFSET EmulateError
mem32_110011     DD OFFSET EmulateError
mem32_110100     DD OFFSET EmulateError
mem32_110101     DD OFFSET EmulateError
mem32_110110     DD OFFSET EmulateError
mem32_110111     DD OFFSET EmulateError
mem32_111000     DD OFFSET EmulateError
mem32_111001     DD OFFSET EmulateError
mem32_111010     DD OFFSET EmulateError
mem32_111011     DD OFFSET EmulateError
mem32_111100     DD OFFSET EmulateError
mem32_111101     DD OFFSET EmulateError
mem32_111110     DD OFFSET EmulateError
mem32_111111     DD OFFSET EmulateError
;
mem64_000000     DD OFFSET MemRax
mem64_000001     DD OFFSET MemRcx
mem64_000010     DD OFFSET MemRdx
mem64_000011     DD OFFSET MemRbx
mem64_000100     DD OFFSET MemSib
mem64_000101     DD OFFSET MemRipD32
mem64_000110     DD OFFSET MemRsi
mem64_000111     DD OFFSET MemRdi
mem64_001000     DD OFFSET MemR8
mem64_001001     DD OFFSET MemR9
mem64_001010     DD OFFSET MemR10
mem64_001011     DD OFFSET MemR11
mem64_001100     DD OFFSET MemSib
mem64_001101     DD OFFSET MemRipD32
mem64_001110     DD OFFSET MemR14
mem64_001111     DD OFFSET MemR15
mem64_010000     DD OFFSET MemRaxD8
mem64_010001     DD OFFSET MemRcxD8
mem64_010010     DD OFFSET MemRdxD8
mem64_010011     DD OFFSET MemRbxD8
mem64_010100     DD OFFSET MemSibD8
mem64_010101     DD OFFSET MemRbpD8
mem64_010110     DD OFFSET MemRsiD8
mem64_010111     DD OFFSET MemRdiD8
mem64_011000     DD OFFSET MemR8D8
mem64_011001     DD OFFSET MemR9D8
mem64_011010     DD OFFSET MemR10D8
mem64_011011     DD OFFSET MemR11D8
mem64_011100     DD OFFSET MemSibD8
mem64_011101     DD OFFSET MemR13D8
mem64_011110     DD OFFSET MemR14D8
mem64_011111     DD OFFSET MemR15D8
mem64_100000     DD OFFSET MemRaxD32
mem64_100001     DD OFFSET MemRcxD32
mem64_100010     DD OFFSET MemRdxD32
mem64_100011     DD OFFSET MemRbxD32
mem64_100100     DD OFFSET MemSibD32
mem64_100101     DD OFFSET MemRbpD32
mem64_100110     DD OFFSET MemRsiD32
mem64_100111     DD OFFSET MemRdiD32
mem64_101000     DD OFFSET MemR8D32
mem64_101001     DD OFFSET MemR9D32
mem64_101010     DD OFFSET MemR10D32
mem64_101011     DD OFFSET MemR11D32
mem64_101100     DD OFFSET MemSibD32
mem64_101101     DD OFFSET MemR13D32
mem64_101110     DD OFFSET MemR14D32
mem64_101111     DD OFFSET MemR15D32
mem64_110000     DD OFFSET EmulateError
mem64_110001     DD OFFSET EmulateError
mem64_110010     DD OFFSET EmulateError
mem64_110011     DD OFFSET EmulateError
mem64_110100     DD OFFSET EmulateError
mem64_110101     DD OFFSET EmulateError
mem64_110110     DD OFFSET EmulateError
mem64_110111     DD OFFSET EmulateError
mem64_111000     DD OFFSET EmulateError
mem64_111001     DD OFFSET EmulateError
mem64_111010     DD OFFSET EmulateError
mem64_111011     DD OFFSET EmulateError
mem64_111100     DD OFFSET EmulateError
mem64_111101     DD OFFSET EmulateError
mem64_111110     DD OFFSET EmulateError
mem64_111111     DD OFFSET EmulateError

LongSibIndexTab:
sibi32_0000     DD OFFSET MemEax
sibi32_0001     DD OFFSET MemEcx
sibi32_0010     DD OFFSET MemEdx
sibi32_0011     DD OFFSET MemEbx
sibi32_0100     DD OFFSET MemNone
sibi32_0101     DD OFFSET MemEbp
sibi32_0110     DD OFFSET MemEsi
sibi32_0111     DD OFFSET MemEdi
sibi32_1000     DD OFFSET MemR8d
sibi32_1001     DD OFFSET MemR9d
sibi32_1010     DD OFFSET MemR10d
sibi32_1011     DD OFFSET MemR11d
sibi32_1100     DD OFFSET MemR12d
sibi32_1101     DD OFFSET MemR13d
sibi32_1110     DD OFFSET MemR14d
sibi32_1111     DD OFFSET MemR15d
sibi64_0000     DD OFFSET MemRax
sibi64_0001     DD OFFSET MemRcx
sibi64_0010     DD OFFSET MemRdx
sibi64_0011     DD OFFSET MemRbx
sibi64_0100     DD OFFSET MemNone
sibi64_0101     DD OFFSET MemRbp
sibi64_0110     DD OFFSET MemRsi
sibi64_0111     DD OFFSET MemRdi
sibi64_1000     DD OFFSET MemR8
sibi64_1001     DD OFFSET MemR9
sibi64_1010     DD OFFSET MemR10
sibi64_1011     DD OFFSET MemR11
sibi64_1100     DD OFFSET MemR12
sibi64_1101     DD OFFSET MemR13
sibi64_1110     DD OFFSET MemR14
sibi64_1111     DD OFFSET MemR15

LongSibBaseTab:
sibb32_0000     DD OFFSET MemEax
sibb32_0001     DD OFFSET MemEcx
sibb32_0010     DD OFFSET MemEdx
sibb32_0011     DD OFFSET MemEbx
sibb32_0100     DD OFFSET MemEsp
sibb32_0101     DD OFFSET MemModD32
sibb32_0110     DD OFFSET MemEsi
sibb32_0111     DD OFFSET MemEdi
sibb32_1000     DD OFFSET MemR8d
sibb32_1001     DD OFFSET MemR9d
sibb32_1010     DD OFFSET MemR10d
sibb32_1011     DD OFFSET MemR11d
sibb32_1100     DD OFFSET MemR12d
sibb32_1101     DD OFFSET MemModD32
sibb32_1110     DD OFFSET MemR14d
sibb32_1111     DD OFFSET MemR15d
sibb64_0000     DD OFFSET MemRax
sibb64_0001     DD OFFSET MemRcx
sibb64_0010     DD OFFSET MemRdx
sibb64_0011     DD OFFSET MemRbx
sibb64_0100     DD OFFSET MemRsp
sibb64_0101     DD OFFSET MemModD32
sibb64_0110     DD OFFSET MemRsi
sibb64_0111     DD OFFSET MemRdi
sibb64_1000     DD OFFSET MemR8
sibb64_1001     DD OFFSET MemR9
sibb64_1010     DD OFFSET MemR10
sibb64_1011     DD OFFSET MemR11
sibb64_1100     DD OFFSET MemR12
sibb64_1101     DD OFFSET MemModD32
sibb64_1110     DD OFFSET MemR14
sibb64_1111     DD OFFSET MemR15

MemSib  PROC near
    ret
MemSib  ENDP

    public LongWordRegTab

LongWordRegTab:
regl_110000      DD OFFSET reg_eax
regl_110001      DD OFFSET reg_ecx
regl_110010      DD OFFSET reg_edx
regl_110011      DD OFFSET reg_ebx
regl_110100      DD OFFSET reg_esp
regl_110101      DD OFFSET reg_ebp
regl_110110      DD OFFSET reg_esi
regl_110111      DD OFFSET reg_edi
regl_111000      DD OFFSET reg_r8
regl_111001      DD OFFSET reg_r9
regl_111010      DD OFFSET reg_r10
regl_111011      DD OFFSET reg_r11
regl_111100      DD OFFSET reg_r12
regl_111101      DD OFFSET reg_r13
regl_111110      DD OFFSET reg_r14
regl_111111      DD OFFSET reg_r15

    public LongByteRegTab

LongByteRegTab:
regb_110000      DD OFFSET reg_eax
regb_110001      DD OFFSET reg_ecx
regb_110010      DD OFFSET reg_edx
regb_110011      DD OFFSET reg_ebx
regb_110100      DD OFFSET reg_eax + 1
regb_110101      DD OFFSET reg_ecx + 1
regb_110110      DD OFFSET reg_edx + 1
regb_110111      DD OFFSET reg_ebx + 1
regb_111000      DD OFFSET reg_r8
regb_111001      DD OFFSET reg_r9
regb_111010      DD OFFSET reg_r10
regb_111011      DD OFFSET reg_r11
regb_111100      DD OFFSET reg_r12
regb_111101      DD OFFSET reg_r13
regb_111110      DD OFFSET reg_r14
regb_111111      DD OFFSET reg_r15

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;     NAME:          LoadLongByteReg
;
;     DESCRIPTION:   Load byte from reg
;
;     RETURN:        AL             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadLongByteReg

LoadLongByteReg    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,1
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    shr bh,3
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongByteRegTab
    mov al,ds:[ebp+esi]
    ret
LoadLongByteReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;     NAME:          LoadLongWordReg
;
;     DESCRIPTION:   Load word from reg
;
;     RETURN:        AX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadLongWordReg

LoadLongWordReg    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,1
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    shr bh,3
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov ax,ds:[ebp+esi]
    ret
LoadLongWordReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;     NAME:          LoadLongDwordReg
;
;     DESCRIPTION:   Load dword from reg
;
;     RETURN:        EAX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadLongDwordReg

LoadLongDwordReg    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,1
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    shr bh,3
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov eax,ds:[ebp+esi]
    ret
LoadLongDwordReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;     NAME:          LoadLongQwordReg
;
;     DESCRIPTION:   Load qword from reg
;
;     RETURN:        EDX:EAX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadLongQwordReg

LoadLongQwordReg    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,1
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    shr bh,3
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov eax,ds:[ebp+esi]
    mov edx,ds:[ebp+esi+4]
    ret
LoadLongQwordReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LoadLongByteMemReg
;
;   DESCRIPTION:    Load byte from memory / reg
;
;   RETURNS:        AL             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadLongByteMemReg

LoadLongByteMemReg Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je LoadByteMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz LoadByteMemRegIndOk
;
    or bl,40h

LoadByteMemRegIndOk:
    movzx esi,bl
    call dword ptr cs:[4*esi].LongMemTab
    call ReadLinearByte
    ret

LoadByteMemRegReg:
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongByteRegTab
    mov al,ds:[ebp+esi]
    ret
LoadLongByteMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LoadLongWordMemReg
;
;   DESCRIPTION:    Load word from memory / reg
;
;   RETURNS:        AX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadLongWordMemReg

LoadLongWordMemReg Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je LoadWordMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz LoadWordMemRegIndOk
;
    or bl,40h

LoadWordMemRegIndOk:
    movzx esi,bl
    call dword ptr cs:[4*esi].LongMemTab
    call ReadLinearWord
    ret

LoadWordMemRegReg:
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov ax,ds:[ebp+esi]
    ret
LoadLongWordMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LoadLongDwordMemReg
;
;   DESCRIPTION:    Load dword from memory / reg
;
;   RETURNS:        EAX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadLongDwordMemReg

LoadLongDwordMemReg Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je LoadDwordMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz LoadDwordMemRegIndOk
;
    or bl,40h

LoadDwordMemRegIndOk:
    movzx esi,bl
    call dword ptr cs:[4*esi].LongMemTab
    call ReadLinearDword
    ret

LoadDwordMemRegReg:
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov eax,ds:[ebp+esi]
    ret
LoadLongDwordMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LoadLongQwordMemReg
;
;   DESCRIPTION:    Load qword from memory / reg
;
;   RETURNS:        EDX:EAX             data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadLongQwordMemReg

LoadLongQwordMemReg Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je LoadQwordMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz LoadQwordMemRegIndOk
;
    or bl,40h

LoadQwordMemRegIndOk:
    movzx esi,bl
    call dword ptr cs:[4*esi].LongMemTab
    call ReadLinearQword
    ret

LoadQwordMemRegReg:
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov eax,ds:[ebp+esi]
    mov edx,ds:[ebp+esi+4]
    ret
LoadLongQwordMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;     NAME:          SaveLongByteReg
;
;     DESCRIPTION:   Save byte to reg
;
;     PARAMETERS:    AL             data to save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveLongByteReg

SaveLongByteReg    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,1
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    shr bh,3
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongByteRegTab
    mov ds:[ebp+esi],al
    ret
SaveLongByteReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;     NAME:          SaveLongWordReg
;
;     DESCRIPTION:   Save word to reg
;
;     PARAMETERS:    AX             data to save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveLongWordReg

SaveLongWordReg    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,1
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    shr bh,3
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov ds:[ebp+esi],ax
    ret
SaveLongWordReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;     NAME:          SaveLongDwordReg
;
;     DESCRIPTION:   Save dword to reg
;
;     PARAMETERS:    EAX             data to save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveLongDwordReg

SaveLongDwordReg    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,1
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    shr bh,3
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov ds:[ebp+esi],eax
    ret
SaveLongDwordReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;     NAME:          SaveLongQwordReg
;
;     DESCRIPTION:   Save qword to reg
;
;     PARAMETERS:    EDX:EAX             data to save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SaveLongQwordReg

SaveLongQwordReg    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,1
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    shr bh,3
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov ds:[ebp+esi],eax
    mov ds:[ebp+esi+4],edx
    ret
SaveLongQwordReg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SaveLongByteMemReg
;
;   DESCRIPTION:    Save byte to memory / reg
;
;   PARAMETERS:     AL             data save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SaveLongByteMemReg

SaveLongByteMemReg Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je SaveByteMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz SaveByteMemRegIndOk
;
    or bl,40h

SaveByteMemRegIndOk:
    movzx esi,bl
    push eax
    call dword ptr cs:[4*esi].LongMemTab
    pop eax
    call WriteLinearByte
    ret

SaveByteMemRegReg:
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongByteRegTab
    mov ds:[ebp+esi],al
    ret
SaveLongByteMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SaveLongWordMemReg
;
;   DESCRIPTION:    Save word to memory / reg
;
;   PARAMETERS:     AX             data save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SaveLongWordMemReg

SaveLongWordMemReg Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je SaveWordMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz SaveWordMemRegIndOk
;
    or bl,40h

SaveWordMemRegIndOk:
    movzx esi,bl
    push eax
    call dword ptr cs:[4*esi].LongMemTab
    pop eax
    call WriteLinearWord
    ret

SaveWordMemRegReg:
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov ds:[ebp+esi],ax
    ret
SaveLongWordMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SaveLongDwordMemReg
;
;   DESCRIPTION:    Save dword to memory / reg
;
;   PARAMETERS:     EAX             data save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SaveLongDwordMemReg

SaveLongDwordMemReg Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je SaveDwordMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz SaveDwordMemRegIndOk
;
    or bl,40h

SaveDwordMemRegIndOk:
    movzx esi,bl
    push eax
    call dword ptr cs:[4*esi].LongMemTab
    pop eax
    call WriteLinearDword
    ret

SaveDwordMemRegReg:
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov ds:[ebp+esi],eax
    ret
SaveLongDwordMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SaveLongQwordMemReg
;
;   DESCRIPTION:    Save qword to memory / reg
;
;   PARAMETERS:     EDX:EAX             data save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SaveLongQwordMemReg

SaveLongQwordMemReg Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je SaveQwordMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz SaveQwordMemRegIndOk
;
    or bl,40h

SaveQwordMemRegIndOk:
    movzx esi,bl
    push edx
    push eax
    call dword ptr cs:[4*esi].LongMemTab
    pop eax
    pop edx
    call WriteLinearQword
    ret

SaveQwordMemRegReg:
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;    
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    movzx esi,bl
    mov esi,dword ptr cs:[4*esi].LongWordRegTab
    mov ds:[ebp+esi],eax
    mov ds:[ebp+esi+4],edx
    ret
SaveLongQwordMemReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetLongMemRegAds
;
;   DESCRIPTION:    Get long mem/reg address
;
;   RETURNS:        NC EDI:EBX     Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetLongMemRegAds

GetLongMemRegAds Proc near
    mov bl,ds:[ebp].em_modrm
    and bl,0C0h
    cmp bl,0C0h
    je GetLongMemRegReg
;
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz GetLongMemRegIndOk
;
    or bl,40h

GetLongMemRegIndOk:
    movzx esi,bl
    call dword ptr cs:[4*esi].LongMemTab
    clc
    ret

GetLongMemRegReg:
    stc
    ret
GetLongMemRegAds Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadLongFwordMem
;
;               DESCRIPTION:    Load fword from memory
;
;               PARAMETERS:     BL              op-code
;
;               RETURNS:        DX:EAX          data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LoadLongFwordMem

LoadLongFwordMem    Proc near
    mov bl,ds:[ebp].em_rex
    shl bl,3
    and bl,8
;
    mov bh,ds:[ebp].em_modrm
    and bh,7
    or bl,bh
;
    mov bh,ds:[ebp].em_modrm
    and bh,0C0h
    shr bh,2
    or bl,bh    
;
    test ds:[ebp].em_flags,a32
    jnz LoadFwordMemIndOk
;
    or bl,40h

LoadFwordMemIndOk:
    movzx esi,bl
    call dword ptr cs:[4*esi].LongMemTab
    call ReadLinearFword
    ret
LoadLongFwordMem    Endp

code    ENDS

        END
