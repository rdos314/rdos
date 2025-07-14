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
; EMTRANS.ASM
; Transaction group functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        .386p

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\os\protseg.def
include ..\os\system.def


include emulate.inc
include emcom.inc
include emmem.inc
include emseg.inc

LoadPointer             MACRO seg

        public EmL&seg

EmL&seg Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmL&seg&Dword
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordMem
        push ax
        ror eax,16
        call ValidateSegment
        mov [bp].reg_&seg,ax
        pop ax
        pop bx
        call SaveWordReg
        ret

EmL&seg&Dword:
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadFwordMem
        mov [bp].reg_&seg,dx
        pop bx
        call SaveDwordReg
        ret
EmL&seg Endp

                        Endm

MoveByteRegIm   Macro reg, name

        public EmMove&name&Im

EmMove&name&Im  Proc near
        call ReadCodeByte
        mov byte ptr [bp].reg_e&reg,al
        ret
EmMove&name&Im  Endp

                        Endm

MoveWordRegIm   Macro reg, name

        public EmMove&name&Im

EmMove&name&Im  Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmMoveE&reg&Im
;
        call ReadCodeWord
        mov word ptr [bp].reg_e&reg,ax
        ret

EmMoveE&reg&Im:
        call ReadCodeDword
        mov [bp].reg_e&reg,eax
        ret
EmMove&name&Im  Endp

                        Endm

MovxByteMem     Macro op
 
        public Em&op&ByteMem

Em&op&ByteMem   Proc near
        test byte ptr [bp].em_flags,d32
        jnz Em&op&DwordMem8
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteMemReg
        pop bx
        &op eax,al
        call SaveWordReg
        ret
Em&op&ByteMem   Endp

Em&op&DwordMem8 Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteMemReg
        pop bx
        &op eax,ax
        call SaveDwordReg
        ret
Em&op&DwordMem8 Endp

                        Endm


MovxWordMem     Macro op

        public Em&op&WordMem

Em&op&WordMem   Proc near
        test byte ptr [bp].em_flags,d32
        jnz Em&op&DwordMem16
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteMemReg
        pop bx
        &op ax,al
        call SaveWordReg
        ret
Em&op&WordMem   Endp

Em&op&DwordMem16        Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordMemReg
        pop bx
        &op eax,ax
        call SaveDwordReg
        ret
Em&op&DwordMem16        Endp

                        Endm

PushReg Macro reg, name

        public EmPush&name

EmPush&name     Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPushE&reg
;
        mov ax,word ptr [bp].reg_e&reg
        call PushWord
        ret

EmPushE&reg:
        mov eax,[bp].reg_e&reg
        call PushDword
        ret
EmPush&name     Endp

                        Endm

PushSreg        MACRO sreg, name

        public EmPush&name

EmPush&name     Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPush&name&32
;
        mov ax,[bp].reg_&sreg
        call PushWord
        ret

EmPush&name&32:
        mov eax,2
        call SubFromStack
        mov ax,[bp].reg_&sreg
        call PushWord
        ret
EmPush&name     Endp

                        Endm

PopReg  Macro reg, name

        public EmPop&name

EmPop&name      Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPopE&reg
;
        call PopWord
        mov word ptr [bp].reg_e&reg,ax
        ret

EmPopE&reg:
        call PopDword
        mov [bp].reg_e&reg,eax
        ret
EmPop&name      Endp

                        Endm

PopSreg Macro sreg, name

        public EmPop&name

EmPop&name      Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPop&name&32
;
        call PopWord
        call ValidateSegment
        mov [bp].reg_&sreg,ax
        ret

EmPop&name&32:
        call PopDword
        call ValidateSegment
        mov [bp].reg_&sreg,ax
        ret
EmPop&name      Endp

                        Endm

XchgAxReg       Macro reg, name

        public EmXchgAx&name

EmXchgAx&name   Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmXchgEaxE&reg
;
        mov ax,word ptr [bp].reg_eax
        xchg ax,word ptr [bp].reg_e&reg
        mov word ptr [bp].reg_eax,ax
        ret

EmXchgEaxE&reg:
        mov eax,[bp].reg_eax
        xchg eax,[bp].reg_e&reg
        mov [bp].reg_eax,eax
        ret
EmXchgAx&name   Endp

                Endm

code    SEGMENT byte public use16 'CODE'

        assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveByteMemToReg
;
;               DESCRIPTION:    EMULATE mov reg,byte ptr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveByteMemToReg

EmMoveByteMemToReg      Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteMemReg
        pop bx
        call SaveByteReg
        ret
EmMoveByteMemToReg      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveWordMemToReg
;
;               DESCRIPTION:    EMULATE mov reg,word ptr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordMemToReg

EmMoveWordMemToReg      Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmMoveDwordMemToReg
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordMemReg
        pop bx
        call SaveWordReg
        ret
EmMoveWordMemToReg      Endp

EmMoveDwordMemToReg     Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordMemReg
        pop bx
        call SaveDwordReg
        ret
EmMoveDwordMemToReg     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveByteRegToMem
;
;               DESCRIPTION:    EMULATE mov byte ptr mem,Reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveByteRegToMem

EmMoveByteRegToMem      Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteReg
        pop bx
        call SaveByteMemReg
        ret
EmMoveByteRegToMem      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveWordRegToMem
;
;               DESCRIPTION:    EMULATE mov word ptr mem,Reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordRegToMem

EmMoveWordRegToMem      Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmMoveDwordRegToMem
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordReg
        pop bx
        call SaveWordMemReg
        ret
EmMoveWordRegToMem      Endp

EmMoveDwordRegToMem     Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordReg
        pop bx
        call SaveDwordMemReg
        ret
EmMoveDwordRegToMem     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveByteMemToAcc
;
;               DESCRIPTION:    EMULATE mov al,byte ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveByteMemToAcc

EmMoveByteMemToAcc      Proc near
        test byte ptr [bp].em_flags,a32
        jnz EmMoveByteMemToAcc32
;
        call MemD16
        call ReadByte
        mov byte ptr [bp].reg_eax,al
        ret

EmMoveByteMemToAcc32:
        call MemD32
        call ReadByte
        mov byte ptr [bp].reg_eax,al
        ret
EmMoveByteMemToAcc      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveWordMemToAcc
;
;               DESCRIPTION:    EMULATE mov reg,word ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordMemToAcc

EmMoveWordMemToAcc      Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmMoveDwordMemToAcc
;
        test byte ptr [bp].em_flags,a32
        jnz EmMoveWordMemToAcc32
;
        call MemD16
        call ReadWord
        mov word ptr [bp].reg_eax,ax
        ret

EmMoveWordMemToAcc32:
        call MemD32
        call ReadWord
        mov word ptr [bp].reg_eax,ax
        ret
EmMoveWordMemToAcc      Endp

EmMoveDwordMemToAcc     Proc near
        test byte ptr [bp].em_flags,a32
        jnz EmMoveDwordMemToAcc32
;
        call MemD16
        call ReadDword
        mov [bp].reg_eax,eax
        ret

EmMoveDwordMemToAcc32:
        call MemD32
        call ReadDword
        mov [bp].reg_eax,eax
        ret
EmMoveDwordMemToAcc     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveByteAccToMem
;
;               DESCRIPTION:    EMULATE mov byte ptr mem,al
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveByteAccToMem

EmMoveByteAccToMem      Proc near
        test byte ptr [bp].em_flags,a32
        jnz EmMoveByteAccTomem32
;
        call MemD16
        mov al,byte ptr [bp].reg_eax
        call WriteByte
        ret

EmMoveByteAccTomem32:
        call MemD32
        mov al,byte ptr [bp].reg_eax
        call WriteByte
        ret
EmMoveByteAccToMem      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveWordAccToMem
;
;               DESCRIPTION:    EMULATE mov word ptr mem,(e)ax
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordAccToMem

EmMoveWordAccToMem      Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmMoveDwordAccToMem
;
        test byte ptr [bp].em_flags,a32
        jnz EmMoveWordAccToMem32
;
        call MemD16
        mov ax,word ptr [bp].reg_eax
        call WriteWord
        ret

EmMoveWordAccToMem32:
        call MemD32
        mov ax,word ptr [bp].reg_eax
        call WriteWord
        ret
EmMoveWordAccToMem      Endp

EmMoveDwordAccToMem     Proc near
        test byte ptr [bp].em_flags,a32
        jnz EmMoveDwordAccToMem32
;
        call MemD16
        mov eax,[bp].reg_eax
        call WriteDword
        ret

EmMoveDwordAccToMem32:
        call MemD32
        mov eax,[bp].reg_eax
        call WriteDword
        ret
EmMoveDwordAccToMem     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveByteImToMem
;
;               DESCRIPTION:    EMULATE mov byte ptr mem,im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveByteImToMem

EmMoveByteImToMem       Proc near
        call ReadCodeByte
        mov bl,al
        and al,38h
        jnz EmulateError
;
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmMoveByteImToReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [bp].em_flags,a32
        jz EmMoveByteImToMem16
        or bl,40h       
EmMoveByteImToMem16:
        xor bh,bh
        call word ptr cs:[bx].MemTab
        push si
        push ebx
        call ReadCodeByte
        pop ebx
        pop si
        call WriteByte
        ret

EmMoveByteImToReg:
        call ReadCodeByte
        and bh,7
        shl bh,1
        movzx si,bh
        mov si,word ptr cs:[si].ByteRegTab
        mov [bp+si],al
        ret
EmMoveByteImToMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveWordImToMem
;
;               DESCRIPTION:    EMULATE mov word ptr mem,im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordImToMem

EmMoveWordImToMem       Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmMoveDwordImToMem
;
        call ReadCodeByte
        mov bl,al
        and al,38h
        jnz EmulateError
;
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmMoveWordImToReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [bp].em_flags,a32
        jz EmMoveWordImToMem16
        or bl,40h       
EmMoveWordImToMem16:
        xor bh,bh
        call word ptr cs:[bx].MemTab
        push si
        push ebx
        call ReadCodeWord
        pop ebx
        pop si
        call WriteWord
        ret

EmMoveWordImToReg:
        call ReadCodeWord
        and bh,7
        shl bh,1
        movzx si,bh
        mov si,word ptr cs:[si].WordRegTab
        mov [bp+si],ax
        ret
EmMoveWordImToMem       Endp

EmMoveDwordImToMem      Proc near
        call ReadCodeByte
        mov bl,al
        and al,38h
        jnz EmulateError
;
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmMoveDwordImToReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [bp].em_flags,a32
        jz EmMoveDwordImToMem16
        or bl,40h       
EmMoveDwordImToMem16:
        xor bh,bh
        call word ptr cs:[bx].MemTab
        push si
        push ebx
        call ReadCodeDword
        pop ebx
        pop si
        call WriteDword
        ret

EmMoveDwordImToReg:
        call ReadCodeDword
        and bh,7
        shl bh,1
        movzx si,bh
        mov si,word ptr cs:[si].DwordRegTab
        mov [bp+si],eax
        ret
EmMoveDwordImToMem      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveByteRegIm
;
;               DESCRIPTION:    EMULATE mov byte reg,im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        MoveByteRegIm ax, Al
        MoveByteRegIm bx, Bl
        MoveByteRegIm cx, Cl
        MoveByteRegIm dx, Dl
        MoveByteRegIm ax+1, Ah
        MoveByteRegIm bx+1, Bh
        MoveByteRegIm cx+1, Ch
        MoveByteRegIm dx+1, Dh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveWordRegIm
;
;               DESCRIPTION:    EMULATE mov word reg,im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        MoveWordRegIm ax, Ax
        MoveWordRegIm bx, Bx
        MoveWordRegIm cx, Cx
        MoveWordRegIm dx, Dx
        MoveWordRegIm sp, Sp
        MoveWordRegIm bp, Bp
        MoveWordRegIm si, Si
        MoveWordRegIm di, Di

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmLea
;
;               DESCRIPTION:    EMULATE mov lea
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLea

EmLea   Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmulateError
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [bp].em_flags,a32
        jz EmLea16

EmLea32:
        test byte ptr [bp].em_flags,d32
        jz EmLea32To16

EmLea32To32:
        or bl,40h       
        xor bh,bh
        call word ptr cs:[bx].MemTab
        mov eax,ebx
        pop bx  
        call SaveDwordReg
        ret

EmLea32To16:
        xor bh,bh
        call word ptr cs:[bx].MemTab
        mov ax,bx
        pop bx  
        call SaveWordReg
        ret

EmLea16:
        test byte ptr [bp].em_flags,d32
        jnz EmLea16To32

EmLea16To16:
        xor bh,bh
        call word ptr cs:[bx].MemTab
        mov ax,bx
        pop bx  
        call SaveWordReg
        ret

EmLea16To32:
        xor bh,bh
        or bl,40h       
        call word ptr cs:[bx].MemTab
        movzx eax,bx
        pop bx  
        call SaveDwordReg
        ret
EmLea   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmLds, EmLes, EmLfs, EmLgs, EmLss
;
;               DESCRIPTION:    EMULATE mov lds, les, lfs, lgs, lss
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadPointer ds
LoadPointer es
LoadPointer fs
LoadPointer gs
LoadPointer ss  
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveSregToMem
;
;               DESCRIPTION:    EMULATE mov mem,sReg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveSregToMem

EmMoveSregToMem Proc near
        call ReadCodeByte
        mov bl,al
        and al,38h
        shr al,2
        movzx si,al
        cmp al,2*6
        jnc EmulateError
;
        mov si,word ptr cs:[si].SegDsTab
        mov ax,[bp+si]
        call SaveWordMemReg
        ret
EmMoveSregToMem Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMoveMemToSreg
;
;               DESCRIPTION:    EMULATE mov sreg,Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveMemToSreg

EmMoveMemToSreg Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordMemReg
        call ValidateSegment
        pop bx
        and bl,38h
        shr bl,2
        movzx si,bl
        cmp bl,2*6
        jnc EmulateError
;
        mov si,word ptr cs:[si].SegDsTab
        mov [bp+si],ax
        ret
EmMoveMemToSreg Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMovzx
;
;               DESCRIPTION:    EMULATE movzx
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MovxByteMem     Movzx
MovxWordMem     Movzx
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMovsx
;
;               DESCRIPTION:    EMULATE movsx
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MovxByteMem     Movsx
MovxWordMem     Movsx
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmEnter
;
;               DESCRIPTION:    EMULATE EmEnter x,y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmEnter

EmEnter Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmEnter32
;
        mov ax,word ptr [bp].reg_ebp
        call PushWord
        mov ax,word ptr [bp].reg_esp
        mov word ptr [bp].reg_ebp,ax
        call ReadCodeWord
        call SubFromStack
        call ReadCodeByte
        or al,al
        jnz EmulateError
        ret

EmEnter32:
        mov eax,[bp].reg_ebp
        call PushDword
        mov eax,[bp].reg_esp
        mov [bp].reg_ebp,eax
        call ReadCodeWord
        call SubFromStack
        call ReadCodeByte
        or al,al
        jnz EmulateError
        ret
EmEnter Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmLeave
;
;               DESCRIPTION:    EMULATE EmLeave
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLeave

EmLeave Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmLeave32
;
        mov ax,word ptr [bp].reg_ebp
        mov word ptr [bp].reg_esp,ax
        call PopWord
        mov word ptr [bp].reg_ebp,ax
        ret

EmLeave32:
        mov eax,[bp].reg_ebp
        mov [bp].reg_esp,eax
        call PopDword
        mov [bp].reg_ebp,eax
        ret
EmLeave Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPushMem
;
;               DESCRIPTION:    EMULATE EmPush Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPushMem

EmPushMem       Proc near
        mov bl,al
        test byte ptr [bp].em_flags,d32
        jnz EmPushMem32
;
        call LoadWordMemReg
        call PushWord
        ret

EmPushMem32:
        call LoadDwordMemReg
        call PushDword
        ret
EmPushMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPusha
;
;               DESCRIPTION:    EMULATE pusha
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPusha

EmPusha Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPushad
;
        push word ptr [bp].reg_esp
        mov ax,word ptr [bp].reg_eax
        call PushWord
        mov ax,word ptr [bp].reg_ecx
        call PushWord
        mov ax,word ptr [bp].reg_edx
        call PushWord
        mov ax,word ptr [bp].reg_ebx
        call PushWord
        pop ax
        call PushWord
        mov ax,word ptr [bp].reg_ebp
        call PushWord
        mov ax,word ptr [bp].reg_esi
        call PushWord
        mov ax,word ptr [bp].reg_edi
        call PushWord
        ret

EmPushad:
        push dword ptr [bp].reg_esp
        mov eax,[bp].reg_eax
        call PushDword
        mov eax,[bp].reg_ecx
        call PushDword
        mov eax,[bp].reg_edx
        call PushDword
        mov eax,[bp].reg_ebx
        call PushDword
        pop eax
        call PushDword
        mov eax,[bp].reg_ebp
        call PushDword
        mov eax,[bp].reg_esi
        call PushDword
        mov eax,[bp].reg_edi
        call PushDword
        ret
EmPusha Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPushIm
;
;               DESCRIPTION:    EMULATE push im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPushIm

EmPushIm        Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPushIm32

EmPushIm16:
        call ReadCodeWord
        call PushWord
        ret

EmPushIm32:
        call ReadCodeDword
        call PushDword
        ret
EmPushIm        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPushImsx
;
;               DESCRIPTION:    EMULATE push imsx
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPushImsx

EmPushImsx      Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPushImsx32

EmPushImsx16:
        call ReadCodeByte
        movsx ax,al
        call PushWord
        ret

EmPushImsx32:
        call ReadCodeByte
        movsx eax,al
        call PushDword
        ret
EmPushImsx      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPushReg
;
;               DESCRIPTION:    EMULATE push reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        PushReg ax, Ax
        PushReg bx, Bx
        PushReg cx, Cx
        PushReg dx, Dx
        PushReg sp, Sp
        PushReg bp, Bp
        PushReg si, Si
        PushReg di, Di
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPushSreg
;
;               DESCRIPTION:    EMULATE push sreg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        PushSreg ds, Ds
        PushSreg es, Es
        PushSreg cs, Cs
        PushSreg ss, Ss
        PushSreg fs, Fs
        PushSreg gs, Gs
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPopMem
;
;               DESCRIPTION:    EMULATE EmPop Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPopMem

EmPopMem        Proc near
        push ax
        test byte ptr [bp].em_flags,d32
        jnz EmPopMem32
;
        call PopWord
        pop bx
        call SaveWordMemReg
        ret

EmPopMem32:
        call PopDword
        pop bx
        call SaveDwordMemReg
        ret
EmPopMem        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPopa
;
;               DESCRIPTION:    EMULATE Popa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPopa

EmPopa  Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPopad
;
        call PopWord
        mov word ptr [bp].reg_edi,ax
        call PopWord
        mov word ptr [bp].reg_esi,ax
        call PopWord
        mov word ptr [bp].reg_ebp,ax
        call PopWord
        call PopWord
        mov word ptr [bp].reg_ebx,ax
        call PopWord
        mov word ptr [bp].reg_edx,ax
        call PopWord
        mov word ptr [bp].reg_ecx,ax
        call PopWord
        mov word ptr [bp].reg_eax,ax
        ret

EmPopad:
        call PopDword
        mov [bp].reg_edi,eax
        call PopDword
        mov [bp].reg_esi,eax
        call PopDword
        mov [bp].reg_ebp,eax
        call PopDword
        call PopDword
        mov [bp].reg_ebx,eax
        call PopDword
        mov [bp].reg_edx,eax
        call PopDword
        mov [bp].reg_ecx,eax
        call PopDword
        mov [bp].reg_eax,eax
        ret
EmPopa  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPopReg
;
;               DESCRIPTION:    EMULATE pop reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        PopReg ax, Ax
        PopReg bx, Bx
        PopReg cx, Cx
        PopReg dx, Dx
        PopReg sp, Sp
        PopReg bp, Bp
        PopReg si, Si
        PopReg di, Di
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPopSreg
;
;               DESCRIPTION:    EMULATE pop sreg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        PopSreg ds, Ds
        PopSreg es, Es
        PopSreg ss, Ss
        PopSreg fs, Fs
        PopSreg gs, Gs
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmXchgByteRegMem
;
;               DESCRIPTION:    EMULATE xchg reg,byte ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmXchgByteRegMem

EmXchgByteRegMem        Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteReg
        pop bx
;
        push bx
        push ax
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmXchgByteRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [bp].em_flags,a32
        jz EmXchgByteRegMem16
        or bl,40h       
EmXchgByteRegMem16:
        xor bh,bh
        call word ptr cs:[bx].MemTab
        push ebx
        call ReadByte
        pop ebx
        pop cx
        push ax
        mov ax,cx
        call WriteByte
        pop ax
        pop bx
        call SaveByteReg
        ret

EmXchgByteRegReg:
        and bh,7
        shl bh,1
        movzx si,bh
        mov si,word ptr cs:[si].ByteRegTab
        pop ax
        xchg al,[bp+si]
        pop bx
        call SaveByteReg
        ret
EmXchgByteRegMem        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmXchgWordRegMem
;
;               DESCRIPTION:    EMULATE xchg reg,word ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmXchgWordRegMem

EmXchgWordRegMem        Proc near
        test byte ptr [bp].em_flags,d32
        jnz EmXchgDwordRegMem
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordReg
        pop bx
;
        push bx
        push ax
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmXchgWordRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [bp].em_flags,a32
        jz EmXchgWordRegMem16
        or bl,40h       
EmXchgWordRegMem16:
        xor bh,bh
        call word ptr cs:[bx].MemTab
        push ebx
        call ReadWord
        pop ebx
        pop cx
        push ax
        mov ax,cx
        call WriteWord
        pop ax
        pop bx
        call SaveWordReg
        ret

EmXchgWordRegReg:
        and bh,7
        shl bh,1
        movzx si,bh
        mov si,word ptr cs:[si].WordRegTab
        pop ax
        xchg ax,[bp+si]
        pop bx
        call SaveWordReg
        ret
EmXchgWordRegMem        Endp

EmXchgDwordRegMem       Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordReg
        pop bx
;
        push bx
        push eax
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmXchgDwordRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [bp].em_flags,a32
        jz EmXchgDwordRegMem16
        or bl,40h       
EmXchgDwordRegMem16:
        xor bh,bh
        call word ptr cs:[bx].MemTab
        push ebx
        call ReadDword
        pop ebx
        pop ecx
        push eax
        mov eax,ecx
        call WriteDword
        pop eax
        pop bx
        call SaveDwordReg
        ret

EmXchgDwordRegReg:
        and bh,7
        shl bh,1
        movzx si,bh
        mov si,word ptr cs:[si].WordRegTab
        pop eax
        xchg eax,[bp+si]
        pop bx
        call SaveDwordReg
        ret
EmXchgDwordRegMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmXchgAxReg
;
;               DESCRIPTION:    EMULATE xchg ax,reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        XchgAxReg bx, Bx
        XchgAxReg cx, Cx
        XchgAxReg dx, Dx
        XchgAxReg sp, Sp
        XchgAxReg bp, Bp
        XchgAxReg si, Si
        XchgAxReg di, Di

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   EmInByteDx / EmInByteIm
;
;               DESCRIPTION:    EMULERA IN AL,DX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmInByteIm

EmInByteIm      Proc near
        call ReadCodeByte
        movzx dx,al
        call InByte
        mov byte ptr [bp].reg_eax,al
        ret
EmInByteIm      Endp

        public EmInByteDx

EmInByteDx      PROC near
        mov dx,word ptr [bp].reg_edx
        call InByte
        mov byte ptr [bp].reg_eax,al
        ret
EmInByteDx      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   EmInWordDx / EmInDwordDx / EmInWordIm
;
;               DESCRIPTION:    EMULERA IN (E)AX,DX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmInWordIm

EmInWordIm      Proc near
        call ReadCodeByte
        movzx dx,al
        test byte ptr [bp].em_flags,d32
        jnz EmInDwordIm
        call InWord
        mov word ptr [bp].reg_eax,ax
        ret

EmInDwordIm:
        call InDword
        mov [bp].reg_eax,eax
        ret
EmInWordIm      Endp

        public EmInWordDx
        
EmInWordDx      PROC near
        mov dx,word ptr [bp].reg_edx
        test byte ptr [bp].em_flags,d32
        jnz EmInDwordDx
        call InWord
        mov word ptr [bp].reg_eax,ax
        ret

EmInDwordDx:
        call InDword
        mov [bp].reg_eax,eax
        ret
EmInWordDx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   EmOutByteDx / EmOutByteIm
;
;               DESCRIPTION:    EMULERA OUT DX,AL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmOutByteIm

EmOutByteIm     Proc near
        call ReadCodeByte
        movzx dx,al
        mov al,byte ptr [bp].reg_eax
        call OutByte
        ret
EmOutByteIm     Endp

        public EmOutByteDx

EmOutByteDx     PROC near
        mov dx,word ptr [bp].reg_edx
        mov al,byte ptr [bp].reg_eax
        call OutByte
        ret
EmOutByteDx     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   EmOutWordDx / EmOutDwordDx / EmOutWordIm
;
;               DESCRIPTION:    EMULERA OUT DX,(E)AX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmOutWordIm

EmOutWordIm     Proc near
        call ReadCodeByte
        movzx dx,al
        test byte ptr [bp].em_flags,d32
        jnz EmOutDwordIm
        mov ax,word ptr [bp].reg_eax
        call OutWord
        ret

EmOutDwordIm:
        mov eax,[bp].reg_eax
        call OutDword
        ret
EmOutWordIm     Endp

        public EmOutWordDx
        
EmOutWordDx     PROC near
        mov dx,word ptr [bp].reg_edx
        test byte ptr [bp].em_flags,d32
        jnz EmOutDwordDx
        mov ax,word ptr [bp].reg_eax
        call OutWord
        ret

EmOutDwordDx:
        mov eax,[bp].reg_eax
        call OutDword
        ret
EmOutWordDx     ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPushf / EmPushfd
;
;               DESCRIPTION:    EMULATE Pushf / Pushfd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPushf

EmPushf proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPushfd
;
        mov ax,word ptr [bp].reg_eflags
        GetFlags
        call PushWord
        ret

EmPushfd:
        mov eax,[bp].reg_eflags
        GetFlags
        call PushDword
        ret
EmPushf endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmPopf / EmPopfd
;
;               DESCRIPTION:    EMULATE popf / popfd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPopf

EmPopf  proc near
        test byte ptr [bp].em_flags,d32
        jnz EmPopfd
;
        call PopWord
        SetFlags
        mov word ptr [bp].reg_eflags,ax
        ret

EmPopfd:
        call PopDword
        SetFlags
        mov [bp].reg_eflags,eax
        ret
EmPopf  endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmLahf
;
;               DESCRIPTION:    EMULATE lahf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLahf

EmLahf  proc near
        mov al,byte ptr [bp].reg_eflags
        mov byte ptr [bp].reg_eax+1,al
        ret
EmLahf  endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmSahf
;
;               DESCRIPTION:    EMULATE sahf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmSahf

EmSahf  proc near
        mov al,byte ptr [bp].reg_eax+1
        mov byte ptr [bp].reg_eflags,al
        ret
EmSahf  endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmClc
;
;               DESCRIPTION:    EMULATE clc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmClc

EmClc   proc near
        and byte ptr [bp].reg_eflags, NOT EFLAGS_CF
        ret
EmClc   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmStc
;
;               DESCRIPTION:    EMULATE stc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmStc

EmStc   proc near
        or byte ptr [bp].reg_eflags, EFLAGS_CF
        ret
EmStc   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmCmc
;
;               DESCRIPTION:    EMULATE cmc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCmc

EmCmc   proc near
        xor byte ptr [bp].reg_eflags, EFLAGS_CF
        ret
EmCmc   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmCld
;
;               DESCRIPTION:    EMULATE cld
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCld

EmCld   proc near
        and word ptr [bp].reg_eflags, NOT EFLAGS_DF
        ret
EmCld   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmStd
;
;               DESCRIPTION:    EMULATE std
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmStd

EmStd   proc near
        or word ptr [bp].reg_eflags, EFLAGS_DF
        ret
EmStd   endp

code    ENDS

        END
