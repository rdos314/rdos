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
;               NAME:           LongMoveByteMemToReg
;
;               DESCRIPTION:    EMULATE mov reg,byte ptr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveByteMemToReg

LongMoveByteMemToReg      Proc near
        call ReadLongCodeByte
        mov [ebp].em_modrm,al
        call LoadLongByteMemReg
        call SaveLongByteReg
        ret
LongMoveByteMemToReg      Endp
        
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
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveDwordMemToReg
;
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call LoadLongWordMemReg
    call SaveLongWordReg
    ret

LongMoveDwordMemToReg:
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call LoadLongDwordMemReg
    call SaveLongDwordReg
    ret

LongMoveQwordMemToReg:
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call LoadLongQwordMemReg
    call SaveLongQwordReg
    ret
LongMoveWordMemToReg      Endp
        
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
    test [ebp].em_rex,1
    jnz LongMoveR8Im
;    
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

LongMoveR8Im:    
    test [ebp].em_rex,8
    jnz LongMoveR8qIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveR8dIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_r8,ax
    ret

LongMoveR8dIm:
    call ReadLongCodeDword
    mov [ebp].reg_r8,eax
    ret

LongMoveR8qIm:
    call ReadLongCodeQword
    mov [ebp].reg_r8,eax
    mov [ebp].reg_r8+4,edx
    ret
LongMoveAxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveCxIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveCxIm

LongMoveCxIm    Proc near
    test [ebp].em_rex,1
    jnz LongMoveR9Im
;    
    test [ebp].em_rex,8
    jnz LongMoveRcxIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveEcxIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_ecx,ax
    ret

LongMoveEcxIm:
    call ReadLongCodeDword
    mov [ebp].reg_ecx,eax
    ret

LongMoveRcxIm:
    call ReadLongCodeQword
    mov [ebp].reg_ecx,eax
    mov [ebp].reg_ecx+4,edx
    ret

LongMoveR9Im:    
    test [ebp].em_rex,8
    jnz LongMoveR9qIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveR9dIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_r9,ax
    ret

LongMoveR9dIm:
    call ReadLongCodeDword
    mov [ebp].reg_r9,eax
    ret

LongMoveR9qIm:
    call ReadLongCodeQword
    mov [ebp].reg_r9,eax
    mov [ebp].reg_r9+4,edx
    ret
LongMoveCxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveDxIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveDxIm

LongMoveDxIm    Proc near
    test [ebp].em_rex,1
    jnz LongMoveR10Im
;    
    test [ebp].em_rex,8
    jnz LongMoveRdxIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveEdxIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_edx,ax
    ret

LongMoveEdxIm:
    call ReadLongCodeDword
    mov [ebp].reg_edx,eax
    ret

LongMoveRdxIm:
    call ReadLongCodeQword
    mov [ebp].reg_edx,eax
    mov [ebp].reg_edx+4,edx
    ret

LongMoveR10Im:    
    test [ebp].em_rex,8
    jnz LongMoveR10qIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveR10dIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_r10,ax
    ret

LongMoveR10dIm:
    call ReadLongCodeDword
    mov [ebp].reg_r10,eax
    ret

LongMoveR10qIm:
    call ReadLongCodeQword
    mov [ebp].reg_r10,eax
    mov [ebp].reg_r10+4,edx
    ret
LongMoveDxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveBxIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveBxIm

LongMoveBxIm    Proc near
    test [ebp].em_rex,1
    jnz LongMoveR11Im
;    
    test [ebp].em_rex,8
    jnz LongMoveRbxIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveEbxIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_ebx,ax
    ret

LongMoveEbxIm:
    call ReadLongCodeDword
    mov [ebp].reg_ebx,eax
    ret

LongMoveRbxIm:
    call ReadLongCodeQword
    mov [ebp].reg_ebx,eax
    mov [ebp].reg_ebx+4,edx
    ret

LongMoveR11Im:    
    test [ebp].em_rex,8
    jnz LongMoveR11qIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveR11dIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_r11,ax
    ret

LongMoveR11dIm:
    call ReadLongCodeDword
    mov [ebp].reg_r11,eax
    ret

LongMoveR11qIm:
    call ReadLongCodeQword
    mov [ebp].reg_r11,eax
    mov [ebp].reg_r11+4,edx
    ret
LongMoveBxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveSpIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveSpIm

LongMoveSpIm    Proc near
    test [ebp].em_rex,1
    jnz LongMoveR12Im
;    
    test [ebp].em_rex,8
    jnz LongMoveRspIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveEspIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_esp,ax
    ret

LongMoveEspIm:
    call ReadLongCodeDword
    mov [ebp].reg_esp,eax
    ret

LongMoveRspIm:
    call ReadLongCodeQword
    mov [ebp].reg_esp,eax
    mov [ebp].reg_esp+4,edx
    ret

LongMoveR12Im:    
    test [ebp].em_rex,8
    jnz LongMoveR12qIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveR12dIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_r12,ax
    ret

LongMoveR12dIm:
    call ReadLongCodeDword
    mov [ebp].reg_r12,eax
    ret

LongMoveR12qIm:
    call ReadLongCodeQword
    mov [ebp].reg_r12,eax
    mov [ebp].reg_r12+4,edx
    ret
LongMoveSpIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveBpIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveBpIm

LongMoveBpIm    Proc near
    test [ebp].em_rex,1
    jnz LongMoveR13Im
;    
    test [ebp].em_rex,8
    jnz LongMoveRbpIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveEbpIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_ebp,ax
    ret

LongMoveEbpIm:
    call ReadLongCodeDword
    mov [ebp].reg_ebp,eax
    ret

LongMoveRbpIm:
    call ReadLongCodeQword
    mov [ebp].reg_ebp,eax
    mov [ebp].reg_ebp+4,edx
    ret

LongMoveR13Im:    
    test [ebp].em_rex,8
    jnz LongMoveR13qIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveR13dIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_r13,ax
    ret

LongMoveR13dIm:
    call ReadLongCodeDword
    mov [ebp].reg_r13,eax
    ret

LongMoveR13qIm:
    call ReadLongCodeQword
    mov [ebp].reg_r13,eax
    mov [ebp].reg_r13+4,edx
    ret
LongMoveBpIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveSiIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveSiIm

LongMoveSiIm    Proc near
    test [ebp].em_rex,1
    jnz LongMoveR14Im
;    
    test [ebp].em_rex,8
    jnz LongMoveRsiIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveEsiIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_esi,ax
    ret

LongMoveEsiIm:
    call ReadLongCodeDword
    mov [ebp].reg_esi,eax
    ret

LongMoveRsiIm:
    call ReadLongCodeQword
    mov [ebp].reg_esi,eax
    mov [ebp].reg_esi+4,edx
    ret

LongMoveR14Im:    
    test [ebp].em_rex,8
    jnz LongMoveR14qIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveR14dIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_r14,ax
    ret

LongMoveR14dIm:
    call ReadLongCodeDword
    mov [ebp].reg_r14,eax
    ret

LongMoveR14qIm:
    call ReadLongCodeQword
    mov [ebp].reg_r14,eax
    mov [ebp].reg_r14+4,edx
    ret
LongMoveSiIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveDiIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveDiIm

LongMoveDiIm    Proc near
    test [ebp].em_rex,1
    jnz LongMoveR15Im
;    
    test [ebp].em_rex,8
    jnz LongMoveRdiIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveEdiIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_edi,ax
    ret

LongMoveEdiIm:
    call ReadLongCodeDword
    mov [ebp].reg_edi,eax
    ret

LongMoveRdiIm:
    call ReadLongCodeQword
    mov [ebp].reg_edi,eax
    mov [ebp].reg_edi+4,edx
    ret

LongMoveR15Im:    
    test [ebp].em_rex,8
    jnz LongMoveR15qIm
;
    test byte ptr [ebp].em_flags,d32
    jnz LongMoveR15dIm
;
    call ReadLongCodeWord
    mov word ptr [ebp].reg_r15,ax
    ret

LongMoveR15dIm:
    call ReadLongCodeDword
    mov [ebp].reg_r15,eax
    ret

LongMoveR15qIm:
    call ReadLongCodeQword
    mov [ebp].reg_r15,eax
    mov [ebp].reg_r15+4,edx
    ret
LongMoveDiIm  Endp
        
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
