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
include \rdos\classlib\emulate\x86\emmem.inc
include \rdos\classlib\emulate\x86\emseg.inc
include \rdos\classlib\emulate\x86\empage.inc

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
;   NAME:           LongMoveMemToSreg
;
;   DESCRIPTION:    EMULATE mov sreg,Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveMemToSreg

LongMoveMemToSreg Proc near
        call ReadLongCodeByte
        mov [ebp].em_modrm,al
        call LoadLongWordMemReg
        mov bl,[ebp].em_modrm
        and bl,38h
        shr bl,2
        movzx esi,bl
        cmp bl,2*6
        jnc EmulateError
;
        mov esi,dword ptr [2*esi].SegDsTab
        call LoadSegment
        ret
LongMoveMemToSreg Endp

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
;   NAME:           LongXchgWordRegMem
;
;   DESCRIPTION:    EMULATE xchg reg,word ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongXchgWordRegMem

LongXchgWordRegMem        Proc near
    test [ebp].em_rex,8
    jnz LongXchgQwordRegMem
;
    test byte ptr [ebp].em_flags,d32
    jnz LongXchgDwordRegMem
;
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call GetLongMemRegAds
    jc LongXchgWordRegs
;
    push edi
    push ebx
    call LoadLongWordReg
    pop ebx
    pop edi
;        
    push edi
    push ebx
;
    push ax
    call ReadLinearWord
    call SaveLongWordReg
    pop ax
;
    pop ebx
    pop edi
    call WriteLinearWord
    ret    

LongXchgWordRegs:    
    call LoadLongWordReg
    push ax
    call LoadLongWordMemReg
    call SaveLongWordReg
    pop ax
    call SaveLongWordMemReg
    ret    

LongXchgDwordRegMem:
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call GetLongMemRegAds
    jc LongXchgDwordRegs
;
    push edi
    push ebx
    call LoadLongDwordReg
    pop ebx
    pop edi
;        
    push edi
    push ebx
;
    push eax
    call ReadLinearDword
    call SaveLongDwordReg
    pop eax
;
    pop ebx
    pop edi
    call WriteLinearDword
    ret    

LongXchgDwordRegs:    
    call LoadLongDwordReg
    push eax
    call LoadLongDwordMemReg
    call SaveLongDwordReg
    pop eax
    call SaveLongDwordMemReg
    ret    

LongXchgQwordRegMem:
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call GetLongMemRegAds
    jc LongXchgQwordRegs
;
    push edi
    push ebx
    call LoadLongQwordReg
    pop ebx
    pop edi
;        
    push edi
    push ebx
;
    push edx
    push eax
    call ReadLinearQword
    call SaveLongQwordReg
    pop eax
    pop edx
;
    pop ebx
    pop edi
    call WriteLinearQword
    ret    

LongXchgQwordRegs:    
    call LoadLongQwordReg
    push edx
    push eax
    call LoadLongQwordMemReg
    call SaveLongQwordReg
    pop eax
    pop edx
    call SaveLongQwordMemReg
    ret    
LongXchgWordRegMem       Endp

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PopReg
;
;               DESCRIPTION:    Emulate pop reg
;
;               PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongPopRax

LongPopRax Proc near
    test [ebp].em_rex,1
    jnz LongPopR8
;
    call PopLong
    mov [ebp].reg_eax,eax
    mov [ebp].reg_eax+4,edx
    ret

LongPopR8:
    call PopLong
    mov [ebp].reg_r8,eax
    mov [ebp].reg_r8+4,edx
    ret
LongPopRax Endp

    public LongPopRcx

LongPopRcx Proc near
    test [ebp].em_rex,1
    jnz LongPopR9
;
    call PopLong
    mov [ebp].reg_ecx,eax
    mov [ebp].reg_ecx+4,edx
    ret

LongPopR9:
    call PopLong
    mov [ebp].reg_r9,eax
    mov [ebp].reg_r9+4,edx
    ret
LongPopRcx Endp

    public LongPopRdx

LongPopRdx Proc near
    test [ebp].em_rex,1
    jnz LongPopR10
;
    call PopLong
    mov [ebp].reg_edx,eax
    mov [ebp].reg_edx+4,edx
    ret

LongPopR10:
    call PopLong
    mov [ebp].reg_r10,eax
    mov [ebp].reg_r10+4,edx
    ret
LongPopRdx Endp

    public LongPopRbx

LongPopRbx Proc near
    test [ebp].em_rex,1
    jnz LongPopR11
;
    call PopLong
    mov [ebp].reg_ebx,eax
    mov [ebp].reg_ebx+4,edx
    ret

LongPopR11:
    call PopLong
    mov [ebp].reg_r11,eax
    mov [ebp].reg_r11+4,edx
    ret
LongPopRbx Endp

    public LongPopRsp

LongPopRsp Proc near
    test [ebp].em_rex,1
    jnz LongPopR12
;
    call PopLong
    mov [ebp].reg_esp,eax
    mov [ebp].reg_esp+4,edx
    ret

LongPopR12:
    call PopLong
    mov [ebp].reg_r12,eax
    mov [ebp].reg_r12+4,edx
    ret
LongPopRsp Endp

    public LongPopRbp

LongPopRbp Proc near
    test [ebp].em_rex,1
    jnz LongPopR13
;
    call PopLong
    mov [ebp].reg_ebp,eax
    mov [ebp].reg_ebp+4,edx
    ret

LongPopR13:
    call PopLong
    mov [ebp].reg_r13,eax
    mov [ebp].reg_r13+4,edx
    ret
LongPopRbp Endp

    public LongPopRsi

LongPopRsi Proc near
    test [ebp].em_rex,1
    jnz LongPopR14
;
    call PopLong
    mov [ebp].reg_esi,eax
    mov [ebp].reg_esi+4,edx
    ret

LongPopR14:
    call PopLong
    mov [ebp].reg_r14,eax
    mov [ebp].reg_r14+4,edx
    ret
LongPopRsi Endp

    public LongPopRdi

LongPopRdi Proc near
    test [ebp].em_rex,1
    jnz LongPopR15
;
    call PopLong
    mov [ebp].reg_edi,eax
    mov [ebp].reg_edi+4,edx
    ret

LongPopR15:
    call PopLong
    mov [ebp].reg_r15,eax
    mov [ebp].reg_r15+4,edx
    ret
LongPopRdi Endp

        END
