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
; LMCONTR.ASM
; Control transfer emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include emcom.inc
include emmem.inc
include emseg.inc
include lnmem.inc
include empage.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           JccShort
;
;   DESCRIPTION:    Emulate jcc short
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JccShort        Macro op

        public Long&op&Short

Long&op&Short     Proc near
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op Long&op&ShortJump
        call ReadLongCodeByte
        ret

Long&op&ShortJump:
        call ReadLongCodeByte
        movsx eax,al
        xor edx,edx
        mov ebx,eax
        rcl ebx,1
        sbb edx,0
        add ds:[ebp].reg_eip,eax
        adc ds:[ebp].reg_eip+4,edx
        ret
Long&op&Short     Endp

                Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           JccNear
;
;               DESCRIPTION:    Emulate jcc near
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JccNear Macro op

        public Long&op&Near

Long&op&Near      Proc near
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op Long&op&NearJump
        call ReadLongCodeDword
        ret

Long&op&NearJump:
        call ReadLongCodeDword
        xor edx,edx
        mov ebx,eax
        rcl ebx,1
        sbb edx,0
        add ds:[ebp].reg_eip,eax
        adc ds:[ebp].reg_eip+4,edx
        ret
Long&op&Near      Endp

                Endm
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmJccShort
;
;               DESCRIPTION:    EMULATE jcc short
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        JccShort Jmp
        JccShort Jo     
        JccShort Jno
        JccShort Jb     
        JccShort Jnb
        JccShort Je
        JccShort Jne
        JccShort Jbe
        JccShort Jnbe
        JccShort Js
        JccShort Jns
        JccShort Jp
        JccShort Jnp
        JccShort Jl
        JccShort Jnl
        JccShort Jle
        JccShort Jnle
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmJccNear
;
;               DESCRIPTION:    EMULATE jcc near
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        JccNear Jmp
        JccNear Jo      
        JccNear Jno
        JccNear Jb      
        JccNear Jnb
        JccNear Je
        JccNear Jne
        JccNear Jbe
        JccNear Jnbe
        JccNear Js
        JccNear Jns
        JccNear Jp
        JccNear Jnp
        JccNear Jl
        JccNear Jnl
        JccNear Jle
        JccNear Jnle
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongCallFarMem
;
;               DESCRIPTION:    EMULATE call far mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LongCallFarMem

LongCallFarMem       Proc near
        mov ds:[ebp].em_modrm,al
;        
        test ds:[ebp].em_rex,8
        jnz LongCallFarMem64
;
        test byte ptr ds:[ebp].em_flags,d32
        jz LongCallFarMem16

LongCallFarMem32:
        call GetLongMemRegAds
        jc EmulateError
;
        call ReadLinearFword
        mov bx,dx
        mov esi,eax
        call CallFar32
        ret

LongCallFarMem16:
        call GetLongMemRegAds
        jc EmulateError
;
        call ReadLinearDword
        mov ebx,eax
        shr ebx,16
        movzx esi,ax
        call CallFar16
        ret

LongCallFarMem64:
        jmp EmulateError

LongCallFarMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongRetNear
;
;               DESCRIPTION:    EMULATE retn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LongRetNear

LongRetNear       proc near
        call PopLong
        mov ds:[ebp].reg_eip,eax
        mov ds:[ebp].reg_eip+4,edx
        ret
LongRetNear       endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:       LongJmpFar
;
;               DESCRIPTION:    EMULATE jmp far
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LongJmpFar

LongJmpFar       Proc near
    call ReadLongCodeDword
    mov esi,eax
    call ReadLongCodeWord
    mov bx,ax
    call JmpFar
    ret
LongJmpFar       Endp

code    ENDS

        END
