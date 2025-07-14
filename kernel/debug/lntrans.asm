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
; LNTRANS.ASM
; Move type of instruction emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include emcom.inc
include lnmem.inc
include emmem.inc
include emseg.inc
include empage.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'
        
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
        mov ds:[ebp].em_modrm,al
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
    test ds:[ebp].em_rex,8
    jnz LongMoveQwordMemToReg
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveDwordMemToReg
;
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongWordMemReg
    call SaveLongWordReg
    ret

LongMoveDwordMemToReg:
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongDwordMemReg
    call SaveLongDwordReg
    ret

LongMoveQwordMemToReg:
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongQwordMemReg
    call SaveLongQwordReg
    ret
LongMoveWordMemToReg      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongMoveWordImToMem
;
;               DESCRIPTION:    EMULATE mov word ptr mem,im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveWordImToMem

LongMoveWordImToMem      Proc near
    test ds:[ebp].em_rex,8
    jnz LongMoveQwordImToMem
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveDwordImToMem
;
    mov ds:[ebp].em_extra_bytes,2
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call GetLongMemRegAds
    jc LongMoveWordImToReg
;
    push edi
    push ebx
    call ReadLongCodeWord
    pop ebx
    pop edi
    call WriteLinearWord
    ret
        
LongMoveWordImToReg:    
    call ReadLongCodeWord
    call SaveLongWordMemReg
    ret

LongMoveDwordImToMem:
    mov ds:[ebp].em_extra_bytes,4
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call GetLongMemRegAds
    jc LongMoveDwordImToReg
;
    push edi
    push ebx
    call ReadLongCodeDword
    pop ebx
    pop edi
    call WriteLinearDword
    ret

LongMoveDwordImToReg:    
    call ReadLongCodeDword
    call SaveLongDwordMemReg
    ret

LongMoveQwordImToMem:
    mov ds:[ebp].em_extra_bytes,4
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call GetLongMemRegAds
    jc LongMoveDwordImToReg
;
    push edi
    push ebx
    call ReadLongCodeDword
    mov ebx,eax
    xor edx,edx
    rcl ebx,1
    sbb edx,0
    pop ebx
    pop edi
    call WriteLinearQword
    ret

LongMoveQwordImToReg:    
    call ReadLongCodeDword
    mov ebx,eax
    xor edx,edx
    rcl ebx,1
    sbb edx,0
    call SaveLongQwordMemReg
    ret
LongMoveWordImToMem      Endp
        
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
        mov ds:[ebp].em_modrm,al
        call LoadLongWordMemReg
        mov bl,ds:[ebp].em_modrm
        and bl,38h
        shr bl,2
        movzx esi,bl
        cmp bl,2*6
        jnc EmulateError
;
        mov esi,dword ptr cs:[2*esi].SegDsTab
        call LoadSegment
        ret
LongMoveMemToSreg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveAlIm
;
;   DESCRIPTION:    Emulate move byte reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveAlIm

LongMoveAlIm    Proc near
    call ReadLongCodeByte
    mov byte ptr ds:[ebp].reg_eax,al
    ret
LongMoveAlIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveClIm
;
;   DESCRIPTION:    Emulate move byte reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveClIm

LongMoveClIm    Proc near
    call ReadLongCodeByte
    mov byte ptr ds:[ebp].reg_ecx,al
    ret
LongMoveClIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveDlIm
;
;   DESCRIPTION:    Emulate move byte reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveDlIm

LongMoveDlIm    Proc near
    call ReadLongCodeByte
    mov byte ptr ds:[ebp].reg_edx,al
    ret
LongMoveDlIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveBlIm
;
;   DESCRIPTION:    Emulate move byte reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveBlIm

LongMoveBlIm    Proc near
    call ReadLongCodeByte
    mov byte ptr ds:[ebp].reg_ebx,al
    ret
LongMoveBlIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveAhIm
;
;   DESCRIPTION:    Emulate move byte reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveAhIm

LongMoveAhIm    Proc near
    call ReadLongCodeByte
    mov byte ptr ds:[ebp].reg_eax+1,al
    ret
LongMoveAhIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveChIm
;
;   DESCRIPTION:    Emulate move byte reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveChIm

LongMoveChIm    Proc near
    call ReadLongCodeByte
    mov byte ptr ds:[ebp].reg_ecx+1,al
    ret
LongMoveChIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveDhIm
;
;   DESCRIPTION:    Emulate move byte reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveDhIm

LongMoveDhIm    Proc near
    call ReadLongCodeByte
    mov byte ptr ds:[ebp].reg_edx+1,al
    ret
LongMoveDhIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveBhIm
;
;   DESCRIPTION:    Emulate move byte reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveBhIm

LongMoveBhIm    Proc near
    call ReadLongCodeByte
    mov byte ptr ds:[ebp].reg_ebx+1,al
    ret
LongMoveBhIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveAxIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveAxIm

LongMoveAxIm    Proc near
    test ds:[ebp].em_rex,1
    jnz LongMoveR8Im
;    
    test ds:[ebp].em_rex,8
    jnz LongMoveRaxIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveEaxIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_eax,ax
    ret

LongMoveEaxIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_eax,eax
    ret

LongMoveRaxIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_eax,eax
    mov ds:[ebp].reg_eax+4,edx
    ret

LongMoveR8Im:    
    test ds:[ebp].em_rex,8
    jnz LongMoveR8qIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveR8dIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_r8,ax
    ret

LongMoveR8dIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_r8,eax
    ret

LongMoveR8qIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_r8,eax
    mov ds:[ebp].reg_r8+4,edx
    ret
LongMoveAxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveCxIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveCxIm

LongMoveCxIm    Proc near
    test ds:[ebp].em_rex,1
    jnz LongMoveR9Im
;    
    test ds:[ebp].em_rex,8
    jnz LongMoveRcxIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveEcxIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_ecx,ax
    ret

LongMoveEcxIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_ecx,eax
    ret

LongMoveRcxIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_ecx,eax
    mov ds:[ebp].reg_ecx+4,edx
    ret

LongMoveR9Im:    
    test ds:[ebp].em_rex,8
    jnz LongMoveR9qIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveR9dIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_r9,ax
    ret

LongMoveR9dIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_r9,eax
    ret

LongMoveR9qIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_r9,eax
    mov ds:[ebp].reg_r9+4,edx
    ret
LongMoveCxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveDxIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveDxIm

LongMoveDxIm    Proc near
    test ds:[ebp].em_rex,1
    jnz LongMoveR10Im
;    
    test ds:[ebp].em_rex,8
    jnz LongMoveRdxIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveEdxIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_edx,ax
    ret

LongMoveEdxIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_edx,eax
    ret

LongMoveRdxIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_edx,eax
    mov ds:[ebp].reg_edx+4,edx
    ret

LongMoveR10Im:    
    test ds:[ebp].em_rex,8
    jnz LongMoveR10qIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveR10dIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_r10,ax
    ret

LongMoveR10dIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_r10,eax
    ret

LongMoveR10qIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_r10,eax
    mov ds:[ebp].reg_r10+4,edx
    ret
LongMoveDxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveBxIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveBxIm

LongMoveBxIm    Proc near
    test ds:[ebp].em_rex,1
    jnz LongMoveR11Im
;    
    test ds:[ebp].em_rex,8
    jnz LongMoveRbxIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveEbxIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_ebx,ax
    ret

LongMoveEbxIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_ebx,eax
    ret

LongMoveRbxIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_ebx,eax
    mov ds:[ebp].reg_ebx+4,edx
    ret

LongMoveR11Im:    
    test ds:[ebp].em_rex,8
    jnz LongMoveR11qIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveR11dIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_r11,ax
    ret

LongMoveR11dIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_r11,eax
    ret

LongMoveR11qIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_r11,eax
    mov ds:[ebp].reg_r11+4,edx
    ret
LongMoveBxIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveSpIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveSpIm

LongMoveSpIm    Proc near
    test ds:[ebp].em_rex,1
    jnz LongMoveR12Im
;    
    test ds:[ebp].em_rex,8
    jnz LongMoveRspIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveEspIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_esp,ax
    ret

LongMoveEspIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_esp,eax
    ret

LongMoveRspIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_esp,eax
    mov ds:[ebp].reg_esp+4,edx
    ret

LongMoveR12Im:    
    test ds:[ebp].em_rex,8
    jnz LongMoveR12qIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveR12dIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_r12,ax
    ret

LongMoveR12dIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_r12,eax
    ret

LongMoveR12qIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_r12,eax
    mov ds:[ebp].reg_r12+4,edx
    ret
LongMoveSpIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveBpIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveBpIm

LongMoveBpIm    Proc near
    test ds:[ebp].em_rex,1
    jnz LongMoveR13Im
;    
    test ds:[ebp].em_rex,8
    jnz LongMoveRbpIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveEbpIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_ebp,ax
    ret

LongMoveEbpIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_ebp,eax
    ret

LongMoveRbpIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_ebp,eax
    mov ds:[ebp].reg_ebp+4,edx
    ret

LongMoveR13Im:    
    test ds:[ebp].em_rex,8
    jnz LongMoveR13qIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveR13dIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_r13,ax
    ret

LongMoveR13dIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_r13,eax
    ret

LongMoveR13qIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_r13,eax
    mov ds:[ebp].reg_r13+4,edx
    ret
LongMoveBpIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveSiIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveSiIm

LongMoveSiIm    Proc near
    test ds:[ebp].em_rex,1
    jnz LongMoveR14Im
;    
    test ds:[ebp].em_rex,8
    jnz LongMoveRsiIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveEsiIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_esi,ax
    ret

LongMoveEsiIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_esi,eax
    ret

LongMoveRsiIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_esi,eax
    mov ds:[ebp].reg_esi+4,edx
    ret

LongMoveR14Im:    
    test ds:[ebp].em_rex,8
    jnz LongMoveR14qIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveR14dIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_r14,ax
    ret

LongMoveR14dIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_r14,eax
    ret

LongMoveR14qIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_r14,eax
    mov ds:[ebp].reg_r14+4,edx
    ret
LongMoveSiIm  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongMoveDiIm
;
;   DESCRIPTION:    Emulate move (d)word reg, immediate
;
;   PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongMoveDiIm

LongMoveDiIm    Proc near
    test ds:[ebp].em_rex,1
    jnz LongMoveR15Im
;    
    test ds:[ebp].em_rex,8
    jnz LongMoveRdiIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveEdiIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_edi,ax
    ret

LongMoveEdiIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_edi,eax
    ret

LongMoveRdiIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_edi,eax
    mov ds:[ebp].reg_edi+4,edx
    ret

LongMoveR15Im:    
    test ds:[ebp].em_rex,8
    jnz LongMoveR15qIm
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongMoveR15dIm
;
    call ReadLongCodeWord
    mov word ptr ds:[ebp].reg_r15,ax
    ret

LongMoveR15dIm:
    call ReadLongCodeDword
    mov ds:[ebp].reg_r15,eax
    ret

LongMoveR15qIm:
    call ReadLongCodeQword
    mov ds:[ebp].reg_r15,eax
    mov ds:[ebp].reg_r15+4,edx
    ret
LongMoveDiIm  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongXchgByteRegMem
;
;   DESCRIPTION:    EMULATE xchg reg,byte ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongXchgByteRegMem

LongXchgByteRegMem        Proc near
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call GetLongMemRegAds
    jc LongXchgByteRegs
;
    push edi
    push ebx
    call LoadLongByteReg
    pop ebx
    pop edi
;        
    push edi
    push ebx
;
    push ax
    call ReadLinearByte
    call SaveLongByteReg
    pop ax
;
    pop ebx
    pop edi
    call WriteLinearByte
    ret    

LongXchgByteRegs:    
    call LoadLongByteReg
    push ax
    call LoadLongByteMemReg
    call SaveLongByteReg
    pop ax
    call SaveLongByteMemReg
    ret    
LongXchgByteRegMem       Endp
        
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
    test ds:[ebp].em_rex,8
    jnz LongXchgQwordRegMem
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongXchgDwordRegMem
;
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
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
    mov ds:[ebp].em_modrm,al
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
    mov ds:[ebp].em_modrm,al
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
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongPushRax

LongPushRax Proc near
    test ds:[ebp].em_rex,1
    jnz LongPushR8
;
    mov eax,ds:[ebp].reg_eax
    mov edx,ds:[ebp].reg_eax+4
    call PushLong
    ret

LongPushR8:
    mov eax,ds:[ebp].reg_r8
    mov edx,ds:[ebp].reg_r8+4
    call PushLong
    ret
LongPushRax Endp

    public LongPushRcx

LongPushRcx Proc near
    test ds:[ebp].em_rex,1
    jnz LongPushR9
;
    mov eax,ds:[ebp].reg_ecx
    mov edx,ds:[ebp].reg_ecx+4
    call PushLong
    ret

LongPushR9:
    mov eax,ds:[ebp].reg_r9
    mov edx,ds:[ebp].reg_r9+4
    call PushLong
    ret
LongPushRcx Endp

    public LongPushRdx

LongPushRdx Proc near
    test ds:[ebp].em_rex,1
    jnz LongPushR10
;
    mov eax,ds:[ebp].reg_edx
    mov edx,ds:[ebp].reg_edx+4
    call PushLong
    ret

LongPushR10:
    mov eax,ds:[ebp].reg_r10
    mov edx,ds:[ebp].reg_r10+4
    call PushLong
    ret
LongPushRdx Endp

    public LongPushRbx

LongPushRbx Proc near
    test ds:[ebp].em_rex,1
    jnz LongPushR11
;
    mov eax,ds:[ebp].reg_ebx
    mov edx,ds:[ebp].reg_ebx+4
    call PushLong
    ret

LongPushR11:
    mov eax,ds:[ebp].reg_r11
    mov edx,ds:[ebp].reg_r11+4
    call PushLong
    ret
LongPushRbx Endp

    public LongPushRsp

LongPushRsp Proc near
    test ds:[ebp].em_rex,1
    jnz LongPushR12
;
    mov eax,ds:[ebp].reg_esp
    mov edx,ds:[ebp].reg_esp+4
    call PushLong
    ret

LongPushR12:
    mov eax,ds:[ebp].reg_r12
    mov edx,ds:[ebp].reg_r12+4
    call PushLong
    ret
LongPushRsp Endp

    public LongPushRbp

LongPushRbp Proc near
    test ds:[ebp].em_rex,1
    jnz LongPushR13
;
    mov eax,ds:[ebp].reg_ebp
    mov edx,ds:[ebp].reg_ebp+4
    call PushLong
    ret

LongPushR13:
    mov eax,ds:[ebp].reg_r13
    mov edx,ds:[ebp].reg_r13+4
    call PushLong
    ret
LongPushRbp Endp

    public LongPushRsi

LongPushRsi Proc near
    test ds:[ebp].em_rex,1
    jnz LongPushR14
;
    mov eax,ds:[ebp].reg_esi
    mov edx,ds:[ebp].reg_esi+4
    call PushLong
    ret

LongPushR14:
    mov eax,ds:[ebp].reg_r14
    mov edx,ds:[ebp].reg_r14+4
    call PushLong
    ret
LongPushRsi Endp

    public LongPushRdi

LongPushRdi Proc near
    test ds:[ebp].em_rex,1
    jnz LongPushR15
;
    mov eax,ds:[ebp].reg_edi
    mov edx,ds:[ebp].reg_edi+4
    call PushLong
    ret

LongPushR15:
    mov eax,ds:[ebp].reg_r15
    mov edx,ds:[ebp].reg_r15+4
    call PushLong
    ret
LongPushRdi Endp

    public LongPushf

LongPushf Proc near
    mov eax,ds:[ebp].reg_eflags
    mov edx,ds:[ebp].reg_eflags+4
    call PushLong
    ret
LongPushf Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PopReg
;
;               DESCRIPTION:    Emulate pop reg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongPopRax

LongPopRax Proc near
    test ds:[ebp].em_rex,1
    jnz LongPopR8
;
    call PopLong
    mov ds:[ebp].reg_eax,eax
    mov ds:[ebp].reg_eax+4,edx
    ret

LongPopR8:
    call PopLong
    mov ds:[ebp].reg_r8,eax
    mov ds:[ebp].reg_r8+4,edx
    ret
LongPopRax Endp

    public LongPopRcx

LongPopRcx Proc near
    test ds:[ebp].em_rex,1
    jnz LongPopR9
;
    call PopLong
    mov ds:[ebp].reg_ecx,eax
    mov ds:[ebp].reg_ecx+4,edx
    ret

LongPopR9:
    call PopLong
    mov ds:[ebp].reg_r9,eax
    mov ds:[ebp].reg_r9+4,edx
    ret
LongPopRcx Endp

    public LongPopRdx

LongPopRdx Proc near
    test ds:[ebp].em_rex,1
    jnz LongPopR10
;
    call PopLong
    mov ds:[ebp].reg_edx,eax
    mov ds:[ebp].reg_edx+4,edx
    ret

LongPopR10:
    call PopLong
    mov ds:[ebp].reg_r10,eax
    mov ds:[ebp].reg_r10+4,edx
    ret
LongPopRdx Endp

    public LongPopRbx

LongPopRbx Proc near
    test ds:[ebp].em_rex,1
    jnz LongPopR11
;
    call PopLong
    mov ds:[ebp].reg_ebx,eax
    mov ds:[ebp].reg_ebx+4,edx
    ret

LongPopR11:
    call PopLong
    mov ds:[ebp].reg_r11,eax
    mov ds:[ebp].reg_r11+4,edx
    ret
LongPopRbx Endp

    public LongPopRsp

LongPopRsp Proc near
    test ds:[ebp].em_rex,1
    jnz LongPopR12
;
    call PopLong
    mov ds:[ebp].reg_esp,eax
    mov ds:[ebp].reg_esp+4,edx
    ret

LongPopR12:
    call PopLong
    mov ds:[ebp].reg_r12,eax
    mov ds:[ebp].reg_r12+4,edx
    ret
LongPopRsp Endp

    public LongPopRbp

LongPopRbp Proc near
    test ds:[ebp].em_rex,1
    jnz LongPopR13
;
    call PopLong
    mov ds:[ebp].reg_ebp,eax
    mov ds:[ebp].reg_ebp+4,edx
    ret

LongPopR13:
    call PopLong
    mov ds:[ebp].reg_r13,eax
    mov ds:[ebp].reg_r13+4,edx
    ret
LongPopRbp Endp

    public LongPopRsi

LongPopRsi Proc near
    test ds:[ebp].em_rex,1
    jnz LongPopR14
;
    call PopLong
    mov ds:[ebp].reg_esi,eax
    mov ds:[ebp].reg_esi+4,edx
    ret

LongPopR14:
    call PopLong
    mov ds:[ebp].reg_r14,eax
    mov ds:[ebp].reg_r14+4,edx
    ret
LongPopRsi Endp

    public LongPopRdi

LongPopRdi Proc near
    test ds:[ebp].em_rex,1
    jnz LongPopR15
;
    call PopLong
    mov ds:[ebp].reg_edi,eax
    mov ds:[ebp].reg_edi+4,edx
    ret

LongPopR15:
    call PopLong
    mov ds:[ebp].reg_r15,eax
    mov ds:[ebp].reg_r15+4,edx
    ret
LongPopRdi Endp

    public LongPopf

LongPopf Proc near
    call PopLong
    mov ds:[ebp].reg_eflags,eax
    mov ds:[ebp].reg_eflags+4,edx
    ret
LongPopf Endp

code    ENDS

        END
