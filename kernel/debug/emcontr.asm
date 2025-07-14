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
; EMCONTR.ASM
; Control transfer emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


include kdebug.inc
include emcom.inc
include emmem.inc
include emseg.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           JccShort
;
;               DESCRIPTION:    Emulate jcc short
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JccShort        Macro op

        public Em&op&Short

Em&op&Short     Proc near
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op Em&op&ShortJump
        call ReadCodeByte
        ret

Em&op&ShortJump:
        call ReadCodeByte
        movsx eax,al
        add eax,ds:[ebp].reg_eip
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        mov ds:[ebp].reg_eip,eax
        ret
Em&op&Short     Endp

                Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           JecxShort
;
;               DESCRIPTION:    Emulate jecx short
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JecxShort       Macro op

        public Em&op&Short

Em&op&Short     Proc near
        test byte ptr ds:[ebp].em_flags,a32
        jnz Em&op&Short32

Em&op&Short16:
        mov ecx,ds:[ebp].reg_ecx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        db 67h
        &op Em&op&ShortJump
        mov ds:[ebp].reg_ecx,ecx
        call ReadCodeByte
        ret

Em&op&Short32:
        mov ecx,ds:[ebp].reg_ecx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op Em&op&ShortJump
        mov ds:[ebp].reg_ecx,ecx
        call ReadCodeByte
        ret

Em&op&ShortJump:
        mov ds:[ebp].reg_ecx,ecx
;
        call ReadCodeByte
        movsx eax,al
        add eax,ds:[ebp].reg_eip
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        mov ds:[ebp].reg_eip,eax
        ret
Em&op&Short     Endp

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

        public Em&op&Near

Em&op&Near      Proc near
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op Em&op&NearJump
        test byte ptr ds:[ebp].em_flags,d32
        jz Em&op&NearSkip16

Em&op&NearSkip32:
        call ReadCodeDword
        ret

Em&op&NearSkip16:
        call ReadCodeWord
        ret

Em&op&NearJump:
        test byte ptr ds:[ebp].em_flags,d32
        jz Em&op&Near16

Em&op&Near32:
        call ReadCodeDword
        add eax,ds:[ebp].reg_eip
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        mov ds:[ebp].reg_eip,eax
        ret

Em&op&Near16:
        call ReadCodeWord
        add ax,word ptr ds:[ebp].reg_eip
        movzx eax,ax
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        mov word ptr ds:[ebp].reg_eip,ax
        ret
Em&op&Near      Endp

                Endm
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCli
;
;               DESCRIPTION:    EMULATE cli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        public EmCli

EmCli   proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmCliDo
;
        test byte ptr ds:[ebp].reg_eflags+2,2
        jz EmCliPm
;
        test ds:[ebp].reg_cr4,1
        jz EmCliComp
;
        and ds:[ebp].reg_eflags,NOT 80000h
        ret        

EmCliComp:        
        mov ecx,ds:[ebp].reg_eflags
        and ecx,EFLAGS_IOPL
        cmp ecx,EFLAGS_IOPL
        jne PrivilegeFault
        jmp EmCliDo

EmCliPm:
        mov ecx,ds:[ebp].reg_eflags
        ror cx,4
        mov ch,byte ptr ds:[ebp].reg_cs.d_access
        and cx,303h
        cmp cl,ch
        jc PrivilegeFault

EmCliDo:
        and word ptr ds:[ebp].reg_eflags,NOT 200h
        ret
EmCli   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmSti
;
;               DESCRIPTION:    EMULATE sti
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmSti

EmSti   proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmStiDo
;
        test byte ptr ds:[ebp].reg_eflags+2,2
        jz EmStiPm
;
        test ds:[ebp].reg_cr4,1
        jz EmStiComp
;        
        or ds:[ebp].reg_eflags,80000h
        ret        

EmStiComp:
        mov ecx,ds:[ebp].reg_eflags
        and ecx,EFLAGS_IOPL
        cmp ecx,EFLAGS_IOPL
        jne PrivilegeFault
        jmp EmStiDo

EmStiPm:
        mov ecx,ds:[ebp].reg_eflags
        ror cx,4
        mov ch,byte ptr ds:[ebp].reg_cs.d_access
        and cx,303h
        cmp cl,ch
        jc PrivilegeFault

EmStiDo:
        or word ptr ds:[ebp].reg_eflags,200h
        ret
EmSti   endp
        
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
        JecxShort Jcxz
        JecxShort Loop
        JecxShort Loopz
        JecxShort Loopnz
        
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
;               NAME:           EmJmpNearMem
;
;               DESCRIPTION:    EMULATE jmp near mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmJmpNearMem

EmJmpNearMem    Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jz EmJmpNearMem16

EmJmpNearMem32:
        mov bl,al
        call LoadDwordMemReg
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        mov ds:[ebp].reg_eip,eax
        ret

EmJmpNearMem16:
        mov bl,al
        call LoadWordMemReg
        movzx eax,ax
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        mov word ptr ds:[ebp].reg_eip,ax
        ret
EmJmpNearMem    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCallNear
;
;               DESCRIPTION:    EMULATE call near
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCallNear

EmCallNear      Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jz EmCallNear16

EmCallNear32:
        call ReadCodeDword
        add eax,ds:[ebp].reg_eip
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        xchg eax,ds:[ebp].reg_eip
        call PushDword
        ret

EmCallNear16:
        call ReadCodeWord
        add ax,word ptr ds:[ebp].reg_eip
        movzx eax,ax
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        xchg ax,word ptr ds:[ebp].reg_eip
        call PushWord
        ret
EmCallNear      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LongCallNear
;
;   DESCRIPTION:    EMULATE call near
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LongCallNear

LongCallNear      Proc near
    call ReadLongCodeDword
    mov ebx,eax
    xor edx,edx
    rcl ebx,1
    sbb edx,0
    add eax,ds:[ebp].reg_eip
    adc edx,ds:[ebp].reg_eip+4
;
    xchg eax,ds:[ebp].reg_eip
    xchg edx,ds:[ebp].reg_eip+4
    call PushLong
    ret
LongCallNear      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCallNearMem
;
;               DESCRIPTION:    EMULATE call near mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCallNearMem

EmCallNearMem   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jz EmCallNearMem16

EmCallNearMem32:
        mov bl,al
        call LoadDwordMemReg
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        xchg eax,ds:[ebp].reg_eip
        call PushDword
        ret

EmCallNearMem16:
        mov bl,al
        call LoadWordMemReg
        movzx eax,ax
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        xchg ax,word ptr ds:[ebp].reg_eip
        call PushWord
        ret
EmCallNearMem   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmRetNear
;
;               DESCRIPTION:    EMULATE retn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmRetNear

EmRetNear       proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmRetNear32

EmRetNear16:
        call PopWord
        movzx eax,ax
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        mov word ptr ds:[ebp].reg_eip,ax
        ret

EmRetNear32:
        call PopDword
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
        mov ds:[ebp].reg_eip,eax
        ret
EmRetNear       endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmRetNearN
;
;               DESCRIPTION:    EMULATE retn n
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmRetNearN

EmRetNearN      proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmRetNearN32

EmRetNearN16:
        call ReadCodeWord
        push ax
        call PopWord
        movzx eax,ax
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
;
        mov word ptr ds:[ebp].reg_eip,ax
        pop ax
        movzx eax,ax
        call AddToStack 
        ret

EmRetNearN32:
        call ReadCodeWord
        push ax
        call PopDword
        cmp eax,ds:[ebp].reg_cs.d_limit
        ja AccessFault
;
        mov ds:[ebp].reg_eip,eax
        pop ax
        movzx eax,ax
        call AddToStack 
        ret
EmRetNearN      endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmJmpFar
;
;               DESCRIPTION:    EMULATE jmp far
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmJmpFar

EmJmpFar        Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jz EmJmpFar16

EmJmpFar32:
        call ReadCodeFword
        mov bx,dx
        mov esi,eax
        call JmpFar
        ret

EmJmpFar16:
        call ReadCodeDword
        mov ebx,eax
        movzx esi,ax
        ror ebx,16
        call JmpFar
        ret
EmJmpFar        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmJmpFarMem
;
;               DESCRIPTION:    EMULATE jmp far mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmJmpFarMem

EmJmpFarMem     Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jz EmJmpFarMem16

EmJmpFarMem32:
        mov bl,al
        call LoadFwordMem
        mov bx,dx
        mov esi,eax
        call JmpFar
        ret

EmJmpFarMem16:
        mov bl,al
        call LoadDwordMem
        mov ebx,eax
        movzx esi,ax
        ror ebx,16
        call JmpFar
        ret
EmJmpFarMem     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCallFar
;
;               DESCRIPTION:    EMULATE call far
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCallFar

EmCallFar       Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jz EmCallFar16

EmCallFar32:
        call ReadCodeFword
        mov bx,dx
        mov esi,eax
        call CallFar32
        ret

EmCallFar16:
        call ReadCodeDword
        mov ebx,eax
        movzx esi,ax
        ror ebx,16
        call CallFar16
        ret
EmCallFar       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCallFarMem
;
;               DESCRIPTION:    EMULATE call far mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCallFarMem

EmCallFarMem    Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jz EmCallFarMem16

EmCallFarMem32:
        mov bl,al
        call LoadFwordMem
        mov bx,dx
        mov esi,eax
        call CallFar32
        ret

EmCallFarMem16:
        mov bl,al
        call LoadDwordMem
        mov ebx,eax
        movzx esi,ax
        ror ebx,16
        call CallFar16
        ret
EmCallFarMem    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmRetFar
;
;               DESCRIPTION:    EMULATE retf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmRetFar

EmRetFar        proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmRetFar32

EmRetFar16:
        xor cl,cl
        call RetFar16
        ret

EmRetFar32:
        xor cl,cl
        call RetFar32
        ret
EmRetFar        endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmRetFarN
;
;               DESCRIPTION:    EMULATE retf n
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmRetFarN

EmRetFarN       proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmRetFarN32

EmRetFarN16:
        call ReadCodeWord
        push ax
        xor cl,cl
        call RetFar16
        pop ax
        movzx eax,ax
        call AddToStack 
        ret

EmRetFarN32:
        call ReadCodeWord
        push ax
        xor cl,cl
        call RetFar32
        pop ax
        movzx eax,ax
        call AddToStack 
        ret
EmRetFarN       endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmInt3, EmInt
;
;               DESCRIPTION:    EMULATE int 3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmInt3
        public EmInt

EmInt3  Proc near
        mov al,3
        call IntFar
        ret
EmInt3  Endp

        public EmInt

EmInt   Proc near
        call ReadCodeByte
        call IntFar
        ret
EmInt   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmIret / EmIretd
;
;               DESCRIPTION:    EMULATE iret / iretd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmIret

EmIret  proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmIretNotTss
;
        test byte ptr ds:[ebp].reg_eflags+2,2
        jnz EmIretNotTss
;
        test ds:[ebp].reg_eflags,EFLAGS_NT
        jz EmIretNotTss
;
        call IretTss
        ret

EmIretNotTss:
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmIret32

EmIret16:
        call IretFar16
        ret

EmIret32:
        call IretFar32
        ret
EmIret  endp

code	ENDS

        END
