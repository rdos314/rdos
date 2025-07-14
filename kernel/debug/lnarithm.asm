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
; LNARITHM.ASM
; Arithmetric group instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include emcom.inc
include lnmem.inc
include emmem.inc
include emseg.inc
include empage.inc


.486p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WordMemReg
;
;               DESCRIPTION:    Emulate (d)word ptr mem, reg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WordRegMem      Macro op1, op2

    public Long&op1&WordRegMem

Long&op1&WordRegMem        Proc near
    test ds:[ebp].em_rex,8
    jnz Long&op1&QwordRegMem
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz Long&op1&DwordRegMem
;
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongWordMemReg
    push ax
    call LoadLongWordReg
    pop bx
    mov cx,ax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 cx,bx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    mov ax,cx
    call SaveLongWordReg
    ret

Long&op1&DwordRegMem:
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongDwordMemReg
    push eax
    call LoadLongDwordReg
    pop ebx
    mov ecx,eax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    mov eax,ecx
    call SaveLongDwordReg
    ret

Long&op1&QwordRegMem:
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongQwordMemReg
    push edx
    push eax
    call LoadLongQwordReg
    pop ebx
    pop edi
    mov ecx,eax
;    
; edi:ebx = memory operand
; edx:ecx = register operand
;
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    jz Long&op1&RegMemPossibleZero
;
    &op2 edx,edi
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp Long&op1&RegMemSave

Long&op1&RegMemPossibleZero:
    &op2 edx,edi
    lahf

Long&op1&RegMemSave:
    mov byte ptr ds:[ebp].reg_eflags,ah
;    
    mov eax,ecx
    call SaveLongQwordReg
    ret
Long&op1&WordRegMem        Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WordImsxMem
;
;               DESCRIPTION:    Emulate (d)word mem, immediate with sign-extend
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WordImsxMem     Macro op1, op2

    public Long&op1&WordImsxMem

Long&op1&WordImsxMem       Proc near
    mov ds:[ebp].em_modrm,al
    mov ds:[ebp].em_extra_bytes,1
;
    test ds:[ebp].em_rex,8
    jnz Long&op1&QwordImsxMem
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz Long&op1&DwordImsxMem
;
    call GetLongMemRegAds
    jc Long&op1&WordImsxReg
;
    call ReadLongCodeByte
    movsx ax,al
    push ax
    call ReadLinearWord
    pop bx
    mov cx,ax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 cx,bx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    mov ax,cx
    call WriteLinearWord
    ret

Long&op1&WordImsxReg:
    call ReadLongCodeByte
    movsx ax,al
    push ax
    call LoadLongWordMemReg
    pop bx
    mov cx,ax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 cx,bx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    mov ax,cx
    call SaveLongWordMemReg
    ret

Long&op1&DwordImsxMem:
    call GetLongMemRegAds
    jc Long&op1&DwordImsxReg
;
    call ReadLongCodeByte
    movsx eax,al
    push eax
    call ReadLinearDword
    pop ebx
    mov ecx,eax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    mov eax,ecx
    call WriteLinearDword
    ret

Long&op1&DwordImsxReg:
    call ReadLongCodeByte
    movsx eax,al
    push eax
    call LoadLongDwordMemReg
    pop ebx
    mov ecx,eax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    mov eax,ecx
    call SaveLongDwordMemReg
    ret

Long&op1&QwordImsxMem:
    call GetLongMemRegAds
    jc Long&op1&QwordImsxReg
;
    call ReadLongCodeByte
    movsx ecx,al
    xor edx,edx
    rcl al,1
    sbb edx,0 
    push edx   
    push ecx
    call ReadLinearQword
    pop ebx
    pop edi
    mov ecx,eax
;    
; edi:ebx = memory operand
; edx:ecx = register operand
;
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    jz Long&op1&QwordImsxMemPossibleZero
;
    &op2 edx,edi
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp Long&op1&QwordImsxMemSave

Long&op1&QwordImsxMemPossibleZero:
    &op2 edx,edi
    lahf

Long&op1&QwordImsxMemSave:
    mov byte ptr ds:[ebp].reg_eflags,ah
    mov eax,ecx
    call WriteLinearQword
    ret

Long&op1&QwordImsxReg:
    call ReadLongCodeByte
    movsx ecx,al
    xor edx,edx
    rcl al,1
    sbb edx,0 
    push edx   
    push ecx
    call LoadLongQwordMemReg
    pop ebx
    pop edi
    mov ecx,eax
;    
; edi:ebx = memory operand
; edx:ecx = register operand
;
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    jz Long&op1&QwordImsxRegPossibleZero
;
    &op2 edx,edi
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp Long&op1&QwordImsxRegSave

Long&op1&QwordImsxRegPossibleZero:
    &op2 edx,edi
    lahf

Long&op1&QwordImsxRegSave:
    mov byte ptr ds:[ebp].reg_eflags,ah
    mov eax,ecx
    call SaveLongQwordMemReg
    ret
Long&op1&WordImsxMem        Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           or
;
;   DESCRIPTION:    EMULATE or
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    WordRegMem Or, Or

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           add
;
;   DESCRIPTION:    EMULATE add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    WordRegMem Add, Adc
    WordImsxMem Add, Adc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongCmpWordRegMem
;
;               DESCRIPTION:    Emulate check (d)word reg, mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LongCmpWordRegMem

LongCmpWordRegMem        Proc near
    test ds:[ebp].em_rex,8
    jnz LongCmpQwordRegMem
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongCmpDwordRegMem
;
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongWordMemReg
    push ax
    call LoadLongWordReg
    pop bx
    mov cx,ax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    cmp cx,bx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    ret

LongCmpDwordRegMem:
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongDwordMemReg
    push eax
    call LoadLongDwordReg
    pop ebx
    mov ecx,eax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    cmp ecx,ebx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    ret

LongCmpQwordRegMem:
    call ReadLongCodeByte
    mov ds:[ebp].em_modrm,al
    call LoadLongQwordMemReg
    push edx
    push eax
    call LoadLongQwordReg
    pop ebx
    pop edi
    mov ecx,eax
;    
; edi:ebx = memory operand
; edx:ecx = register operand
;
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    sub ecx,ebx
    jz LongCmpRegMemPossibleZero
;
    sbb edx,edi
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp LongCmpRegMemSave

LongCmpRegMemPossibleZero:
    sbb edx,edi
    lahf

LongCmpRegMemSave:
    mov byte ptr ds:[ebp].reg_eflags,ah
    ret
LongCmpWordRegMem        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongCmpByteImAcc
;
;               DESCRIPTION:    Emulate cmp byte mem, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongCmpByteImAcc

LongCmpByteImAcc Proc near
    call ReadLongCodeByte
    mov bl,byte ptr ds:[ebp].reg_eax
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    cmp bl,al
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    ret
LongCmpByteImAcc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongCmpWordImsxMem
;
;               DESCRIPTION:    Emulate (d)word mem, immediate with sign-extend
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongCmpWordImsxMem

LongCmpWordImsxMem       Proc near
    mov ds:[ebp].em_modrm,al
;
    test ds:[ebp].em_rex,8
    jnz LongCmpQwordImsxMem
;
    test byte ptr ds:[ebp].em_flags,d32
    jnz LongCmpDwordImsxMem
;
    call ReadLongCodeByte
    movsx ax,al
    push ax
    call LoadLongWordMemReg
    pop bx
    mov cx,ax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    cmp cx,bx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    ret

LongCmpDwordImsxMem:
    call ReadLongCodeByte
    movsx eax,al
    push eax
    call LoadLongDwordMemReg
    pop ebx
    mov ecx,eax
;    
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    cmp ecx,ebx
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    ret

LongCmpQwordImsxMem:
    call ReadLongCodeByte
    movzx ecx,al
    xor edx,edx
    rcl al,1
    sbb edx,0
;    
    push edx
    push ecx
    call LoadLongQwordMemReg
    pop ebx
    pop edi
;
    mov ecx,eax
;    
; edi:ebx = memory operand
; edx:ecx = register operand
;
    mov ah,byte ptr ds:[ebp].reg_eflags
    sahf
    sub ecx,ebx
    jz LongCmpImsxMemPossibleZero
;
    sbb edx,edi
    lahf
    mov byte ptr ds:[ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp LongCmpImsxMemSave

LongCmpImsxMemPossibleZero:
    sbb edx,edi
    lahf

LongCmpImsxMemSave:
    mov byte ptr ds:[ebp].reg_eflags,ah
    ret
LongCmpWordImsxMem        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongLgdtMem
;
;               DESCRIPTION:    EMULATE lgdt mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     public LongLgdtMem

LongLgdtMem       Proc near
    test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
    jnz PrivilegeFault
;
    mov ds:[ebp].em_modrm,al
    call LoadLongFwordMem
    mov word ptr ds:[ebp].reg_gdt.d_limit,ax
    ror edx,16
    ror eax,16
    mov dx,ax
    mov ds:[ebp].reg_gdt.d_base,edx
    ret
LongLgdtMem       Endp

code	ENDS

        END
