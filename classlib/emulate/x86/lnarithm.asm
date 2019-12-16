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
; LNARITHM.ASM
; Arithmetric group instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.486
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
;               NAME:           WordMemReg
;
;               DESCRIPTION:    Emulate (d)word ptr mem, reg
;
;               PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WordRegMem      Macro op1, op2

    public Long&op1&WordRegMem

Long&op1&WordRegMem        Proc near
    test [ebp].em_rex,8
    jnz Long&op1&QwordRegMem
;
    test byte ptr [ebp].em_flags,d32
    jnz Long&op1&DwordRegMem
;
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call LoadLongWordMemReg
    push ax
    call LoadLongWordReg
    pop bx
    mov cx,ax
;    
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 cx,bx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    mov ax,cx
    call SaveLongWordReg
    ret

Long&op1&DwordRegMem:
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call LoadLongDwordMemReg
    push eax
    call LoadLongDwordReg
    pop ebx
    mov ecx,eax
;    
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    mov eax,ecx
    call SaveLongDwordReg
    ret

Long&op1&QwordRegMem:
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    jz Long&op1&RegMemPossibleZero
;
    &op2 edx,edi
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp Long&op1&RegMemSave

Long&op1&RegMemPossibleZero:
    &op2 edx,edi
    lahf

Long&op1&RegMemSave:
    mov byte ptr [ebp].reg_eflags,ah
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
;               PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WordImsxMem     Macro op1, op2

    public Long&op1&WordImsxMem

Long&op1&WordImsxMem       Proc near
    mov [ebp].em_modrm,al
    mov [ebp].em_extra_bytes,1
;
    test [ebp].em_rex,8
    jnz Long&op1&QwordImsxMem
;
    test byte ptr [ebp].em_flags,d32
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 cx,bx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 cx,bx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    jz Long&op1&QwordImsxMemPossibleZero
;
    &op2 edx,edi
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp Long&op1&QwordImsxMemSave

Long&op1&QwordImsxMemPossibleZero:
    &op2 edx,edi
    lahf

Long&op1&QwordImsxMemSave:
    mov byte ptr [ebp].reg_eflags,ah
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    &op1 ecx,ebx
    jz Long&op1&QwordImsxRegPossibleZero
;
    &op2 edx,edi
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp Long&op1&QwordImsxRegSave

Long&op1&QwordImsxRegPossibleZero:
    &op2 edx,edi
    lahf

Long&op1&QwordImsxRegSave:
    mov byte ptr [ebp].reg_eflags,ah
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
;               PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LongCmpWordRegMem

LongCmpWordRegMem        Proc near
    test [ebp].em_rex,8
    jnz LongCmpQwordRegMem
;
    test byte ptr [ebp].em_flags,d32
    jnz LongCmpDwordRegMem
;
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call LoadLongWordMemReg
    push ax
    call LoadLongWordReg
    pop bx
    mov cx,ax
;    
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    cmp cx,bx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    ret

LongCmpDwordRegMem:
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
    call LoadLongDwordMemReg
    push eax
    call LoadLongDwordReg
    pop ebx
    mov ecx,eax
;    
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    cmp ecx,ebx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    ret

LongCmpQwordRegMem:
    call ReadLongCodeByte
    mov [ebp].em_modrm,al
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    sub ecx,ebx
    jz LongCmpRegMemPossibleZero
;
    sbb edx,edi
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp LongCmpRegMemSave

LongCmpRegMemPossibleZero:
    sbb edx,edi
    lahf

LongCmpRegMemSave:
    mov byte ptr [ebp].reg_eflags,ah
    ret
LongCmpWordRegMem        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongCmpByteImAcc
;
;               DESCRIPTION:    Emulate cmp byte mem, immediate
;
;               PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongCmpByteImAcc

LongCmpByteImAcc Proc near
    call ReadLongCodeByte
    mov bl,byte ptr [ebp].reg_eax
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    cmp bl,al
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    ret
LongCmpByteImAcc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongCmpWordImsxMem
;
;               DESCRIPTION:    Emulate (d)word mem, immediate with sign-extend
;
;               PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongCmpWordImsxMem

LongCmpWordImsxMem       Proc near
    mov [ebp].em_modrm,al
;
    test [ebp].em_rex,8
    jnz LongCmpQwordImsxMem
;
    test byte ptr [ebp].em_flags,d32
    jnz LongCmpDwordImsxMem
;
    call ReadLongCodeByte
    movsx ax,al
    push ax
    call LoadLongWordMemReg
    pop bx
    mov cx,ax
;    
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    cmp cx,bx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    ret

LongCmpDwordImsxMem:
    call ReadLongCodeByte
    movsx eax,al
    push eax
    call LoadLongDwordMemReg
    pop ebx
    mov ecx,eax
;    
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    cmp ecx,ebx
    lahf
    mov byte ptr [ebp].reg_eflags,ah
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
    mov ah,byte ptr [ebp].reg_eflags
    sahf
    sub ecx,ebx
    jz LongCmpImsxMemPossibleZero
;
    sbb edx,edi
    lahf
    mov byte ptr [ebp].reg_eflags,ah
    and ah,NOT 40h
    jmp LongCmpImsxMemSave

LongCmpImsxMemPossibleZero:
    sbb edx,edi
    lahf

LongCmpImsxMemSave:
    mov byte ptr [ebp].reg_eflags,ah
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
    test byte ptr [ebp].reg_cs.d_access, ACCESS_RPL
    jnz PrivilegeFault
;
    mov [ebp].em_modrm,al
    call LoadLongTbyteMem
    mov word ptr [ebp].reg_gdt.d_limit,ax
;
    shr eax,16
    push dx
    push ax
;
    shr edx,16
    push cx
    push dx
;
    pop eax
    mov [ebp+4].reg_gdt.d_base,eax
;
    pop eax
    mov [ebp].reg_gdt.d_base,eax
    ret
LongLgdtMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LongLidtMem
;
;               DESCRIPTION:    EMULATE lidt mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     public LongLidtMem

LongLidtMem       Proc near
    test byte ptr [ebp].reg_cs.d_access, ACCESS_RPL
    jnz PrivilegeFault
;
    mov [ebp].em_modrm,al
    call LoadLongTbyteMem
    mov word ptr [ebp].reg_idt.d_limit,ax
;
    shr eax,16
    push dx
    push ax
;
    shr edx,16
    push cx
    push dx
;
    pop eax
    mov [ebp+4].reg_idt.d_base,eax
;
    pop eax
    mov [ebp].reg_idt.d_base,eax
    ret
LongLidtMem       Endp

        END
