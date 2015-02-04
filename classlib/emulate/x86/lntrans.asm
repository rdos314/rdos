;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Em486 CPU emulator
; Copyright (C) 1998-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage. For information on commercial usage,
; contact em486@rdos.net.
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
; LNTRANS.ASM
; Move type of instruction emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

include \rdos\classlib\emulate\x86\emulate.inc
include \rdos\classlib\emulate\x86\emcom.inc
include \rdos\classlib\emulate\x86\lnmem.inc

.code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongMoveWordMemToReg
;
;               DESCRIPTION:    EMULATE mov reg,word ptr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveWordMemToReg

LongMoveWordMemToReg      Proc near
        test [ebp].em_rex,8
        jnz LongMoveQwordMemToReg
;
        call ReadLongCodeByte
        mov [ebp].em_modrm,al
        call LoadLongDwordMemReg
        call SaveLongDwordReg
        ret
LongMoveWordMemToReg      Endp

LongMoveQwordMemToReg     Proc near
        call ReadLongCodeByte
        mov [ebp].em_modrm,al
        call LoadLongQwordMemReg
        call SaveLongQwordReg
        ret
LongMoveQwordMemToReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveAxIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveAxIm

LongMoveAxIm    Proc near
    test [ebp].em_rex,8
    jnz LongMoveRaxIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveEaxIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_eax,ax
    ret

LongMoveEaxIm:
    call ReadLongCodeDword
    mov [ebp].reg_eax,eax
    ret

LongMoveRaxIm:
    call ReadLongCodeQword
    mov [ebp].reg_eax,eax
    mov [ebp].reg_eax+4,edx
    ret
LongMoveAxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PushReg
;
;               DESCRIPTION:    Emulate push reg
;
;               PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongPushRax

LongPushRax Proc near
    test [ebp].em_rex,1
    jnz LongPushR8
;
    mov eax,[ebp].reg_eax
    mov edx,[ebp].reg_eax+4
    call PushLong
    ret

LongPushR8:
    mov eax,[ebp].reg_r8
    mov edx,[ebp].reg_r8+4
    call PushLong
    ret
LongPushRax Endp

    public LongPushRcx

LongPushRcx Proc near
    test [ebp].em_rex,1
    jnz LongPushR9
;
    mov eax,[ebp].reg_ecx
    mov edx,[ebp].reg_ecx+4
    call PushLong
    ret

LongPushR9:
    mov eax,[ebp].reg_r9
    mov edx,[ebp].reg_r9+4
    call PushLong
    ret
LongPushRcx Endp

    public LongPushRdx

LongPushRdx Proc near
    test [ebp].em_rex,1
    jnz LongPushR10
;
    mov eax,[ebp].reg_edx
    mov edx,[ebp].reg_edx+4
    call PushLong
    ret

LongPushR10:
    mov eax,[ebp].reg_r10
    mov edx,[ebp].reg_r10+4
    call PushLong
    ret
LongPushRdx Endp

    public LongPushRbx

LongPushRbx Proc near
    test [ebp].em_rex,1
    jnz LongPushR11
;
    mov eax,[ebp].reg_ebx
    mov edx,[ebp].reg_ebx+4
    call PushLong
    ret

LongPushR11:
    mov eax,[ebp].reg_r11
    mov edx,[ebp].reg_r11+4
    call PushLong
    ret
LongPushRbx Endp

    public LongPushRsp

LongPushRsp Proc near
    test [ebp].em_rex,1
    jnz LongPushR12
;
    mov eax,[ebp].reg_esp
    mov edx,[ebp].reg_esp+4
    call PushLong
    ret

LongPushR12:
    mov eax,[ebp].reg_r12
    mov edx,[ebp].reg_r12+4
    call PushLong
    ret
LongPushRsp Endp

    public LongPushRbp

LongPushRbp Proc near
    test [ebp].em_rex,1
    jnz LongPushR13
;
    mov eax,[ebp].reg_ebp
    mov edx,[ebp].reg_ebp+4
    call PushLong
    ret

LongPushR13:
    mov eax,[ebp].reg_r13
    mov edx,[ebp].reg_r13+4
    call PushLong
    ret
LongPushRbp Endp

    public LongPushRsi

LongPushRsi Proc near
    test [ebp].em_rex,1
    jnz LongPushR14
;
    mov eax,[ebp].reg_esi
    mov edx,[ebp].reg_esi+4
    call PushLong
    ret

LongPushR14:
    mov eax,[ebp].reg_r14
    mov edx,[ebp].reg_r14+4
    call PushLong
    ret
LongPushRsi Endp

    public LongPushRdi

LongPushRdi Proc near
    test [ebp].em_rex,1
    jnz LongPushR15
;
    mov eax,[ebp].reg_edi
    mov edx,[ebp].reg_edi+4
    call PushLong
    ret

LongPushR15:
    mov eax,[ebp].reg_r15
    mov edx,[ebp].reg_r15+4
    call PushLong
    ret
LongPushRdi Endp

        END
