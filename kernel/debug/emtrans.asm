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
; Move type of instruction emulation
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
;               NAME:           LoadPointer
;
;               DESCRIPTION:    Load pointer macro
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadPointer             MACRO seg

        public EmL&seg

EmL&seg Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmL&seg&Dword
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordMem
        push ax
        ror eax,16
        mov esi,OFFSET reg_&seg
        call LoadSegment
        pop ax
        pop bx
        call SaveWordReg
        ret

EmL&seg&Dword:
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadFwordMem
        push eax
        mov ax,dx
        mov esi,OFFSET reg_&seg
        call LoadSegment
        pop eax
        pop bx
        call SaveDwordReg
        ret
EmL&seg Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           MoveByteRegIm
;
;               DESCRIPTION:    Emulate move byte reg, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveByteRegIm   Macro reg, name

        public EmMove&name&Im

EmMove&name&Im  Proc near
        call ReadCodeByte
        mov byte ptr ds:[ebp].reg_e&reg,al
        ret
EmMove&name&Im  Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           MoveWordRegIm
;
;               DESCRIPTION:    Emulate move (d)word reg, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveWordRegIm   Macro reg, name

        public EmMove&name&Im

EmMove&name&Im  Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmMoveE&reg&Im
;
        call ReadCodeWord
        mov word ptr ds:[ebp].reg_e&reg,ax
        ret

EmMoveE&reg&Im:
        call ReadCodeDword
        mov ds:[ebp].reg_e&reg,eax
        ret
EmMove&name&Im  Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           MovxByteMem
;
;               DESCRIPTION:    Emulate movx byte mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MovxByteMem     Macro op
 
        public Em&op&ByteMem

Em&op&ByteMem   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMem8
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteMemReg
        pop bx
        &op ax,al
        call SaveWordReg
        ret
Em&op&ByteMem   Endp

Em&op&DwordMem8 Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteMemReg
        pop bx
        &op eax,al
        call SaveDwordReg
        ret
Em&op&DwordMem8 Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           MovxWordMem
;
;               DESCRIPTION:    Emulate movx word mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MovxWordMem     Macro op

        public Em&op&WordMem

Em&op&WordMem   Proc near
        test byte ptr ds:[ebp].em_flags,d32
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

PushReg Macro reg, name

        public EmPush&name

EmPush&name     Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmPushE&reg
;
        mov ax,word ptr ds:[ebp].reg_e&reg
        call PushWord
        ret

EmPushE&reg:
        mov eax,ds:[ebp].reg_e&reg
        call PushDword
        ret
EmPush&name     Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PushSreg
;
;               DESCRIPTION:    Emulate push sreg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PushSreg        MACRO sreg, name

        public EmPush&name

EmPush&name     Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmPush&name&32
;
        mov ax,ds:[ebp].reg_&sreg.d_selector
        call PushWord
        ret

EmPush&name&32:
        mov eax,2
        call SubFromStack
        mov ax,ds:[ebp].reg_&sreg.d_selector
        call PushWord
        ret
EmPush&name     Endp

                        Endm

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

PopReg  Macro reg, name

        public EmPop&name

EmPop&name      Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmPopE&reg
;
        call PopWord
        mov word ptr ds:[ebp].reg_e&reg,ax
        ret

EmPopE&reg:
        call PopDword
        mov ds:[ebp].reg_e&reg,eax
        ret
EmPop&name      Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PopSreg
;
;               DESCRIPTION:    Emulate pop sreg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PopSreg Macro sreg, name

        public EmPop&name

EmPop&name      Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmPop&name&32
;
        call PopWord
        mov esi,OFFSET reg_&sreg
        call LoadSegment
        ret

EmPop&name&32:
        call PopDword
        mov esi,OFFSET reg_&sreg
        call LoadSegment
        ret
EmPop&name      Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           XchgAxReg
;
;               DESCRIPTION:    Emulate xchg ax,reg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

XchgAxReg       Macro reg, name

        public EmXchgAx&name

EmXchgAx&name   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmXchgEaxE&reg
;
        mov ax,word ptr ds:[ebp].reg_eax
        xchg ax,word ptr ds:[ebp].reg_e&reg
        mov word ptr ds:[ebp].reg_eax,ax
        ret

EmXchgEaxE&reg:
        mov eax,ds:[ebp].reg_eax
        xchg eax,ds:[ebp].reg_e&reg
        mov ds:[ebp].reg_eax,eax
        ret
EmXchgAx&name   Endp

                Endm
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveByteMemToReg
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
;               NAME:           EmMoveWordMemToReg
;
;               DESCRIPTION:    EMULATE mov reg,word ptr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordMemToReg

EmMoveWordMemToReg      Proc near
        test byte ptr ds:[ebp].em_flags,d32
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
;               NAME:           EmMoveByteRegToMem
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
;               NAME:           EmMoveWordRegToMem
;
;               DESCRIPTION:    EMULATE mov word ptr mem,Reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordRegToMem

EmMoveWordRegToMem      Proc near
        test byte ptr ds:[ebp].em_flags,d32
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
;               NAME:           EmMoveByteMemToAcc
;
;               DESCRIPTION:    EMULATE mov al,byte ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveByteMemToAcc

EmMoveByteMemToAcc      Proc near
        test byte ptr ds:[ebp].em_flags,a32
        jnz EmMoveByteMemToAcc32
;
        call MemD16
        call ReadByte
        mov byte ptr ds:[ebp].reg_eax,al
        ret

EmMoveByteMemToAcc32:
        call MemD32
        call ReadByte
        mov byte ptr ds:[ebp].reg_eax,al
        ret
EmMoveByteMemToAcc      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveWordMemToAcc
;
;               DESCRIPTION:    EMULATE mov reg,word ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordMemToAcc

EmMoveWordMemToAcc      Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmMoveDwordMemToAcc
;
        test byte ptr ds:[ebp].em_flags,a32
        jnz EmMoveWordMemToAcc32
;
        call MemD16
        call ReadWord
        mov word ptr ds:[ebp].reg_eax,ax
        ret

EmMoveWordMemToAcc32:
        call MemD32
        call ReadWord
        mov word ptr ds:[ebp].reg_eax,ax
        ret
EmMoveWordMemToAcc      Endp

EmMoveDwordMemToAcc     Proc near
        test byte ptr ds:[ebp].em_flags,a32
        jnz EmMoveDwordMemToAcc32
;
        call MemD16
        call ReadDword
        mov ds:[ebp].reg_eax,eax
        ret

EmMoveDwordMemToAcc32:
        call MemD32
        call ReadDword
        mov ds:[ebp].reg_eax,eax
        ret
EmMoveDwordMemToAcc     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveByteAccToMem
;
;               DESCRIPTION:    EMULATE mov byte ptr mem,al
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveByteAccToMem

EmMoveByteAccToMem      Proc near
        test byte ptr ds:[ebp].em_flags,a32
        jnz EmMoveByteAccTomem32
;
        call MemD16
        mov al,byte ptr ds:[ebp].reg_eax
        call WriteByte
        ret

EmMoveByteAccTomem32:
        call MemD32
        mov al,byte ptr ds:[ebp].reg_eax
        call WriteByte
        ret
EmMoveByteAccToMem      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveWordAccToMem
;
;               DESCRIPTION:    EMULATE mov word ptr mem,(e)ax
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordAccToMem

EmMoveWordAccToMem      Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmMoveDwordAccToMem
;
        test byte ptr ds:[ebp].em_flags,a32
        jnz EmMoveWordAccToMem32
;
        call MemD16
        mov ax,word ptr ds:[ebp].reg_eax
        call WriteWord
        ret

EmMoveWordAccToMem32:
        call MemD32
        mov ax,word ptr ds:[ebp].reg_eax
        call WriteWord
        ret
EmMoveWordAccToMem      Endp

EmMoveDwordAccToMem     Proc near
        test byte ptr ds:[ebp].em_flags,a32
        jnz EmMoveDwordAccToMem32
;
        call MemD16
        mov eax,ds:[ebp].reg_eax
        call WriteDword
        ret

EmMoveDwordAccToMem32:
        call MemD32
        mov eax,ds:[ebp].reg_eax
        call WriteDword
        ret
EmMoveDwordAccToMem     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveByteImToMem
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
        test byte ptr ds:[ebp].em_flags,a32
        jz EmMoveByteImToMem16
        or bl,40h       
EmMoveByteImToMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadCodeByte
        pop ebx
        pop esi
        call WriteByte
        ret

EmMoveByteImToReg:
        call ReadCodeByte
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov ds:[ebp+esi],al
        ret
EmMoveByteImToMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveWordImToMem
;
;               DESCRIPTION:    EMULATE mov word ptr mem,im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveWordImToMem

EmMoveWordImToMem       Proc near
        test byte ptr ds:[ebp].em_flags,d32
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
        test byte ptr ds:[ebp].em_flags,a32
        jz EmMoveWordImToMem16
        or bl,40h       
EmMoveWordImToMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadCodeWord
        pop ebx
        pop esi
        call WriteWord
        ret

EmMoveWordImToReg:
        call ReadCodeWord
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ds:[ebp+esi],ax
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
        test byte ptr ds:[ebp].em_flags,a32
        jz EmMoveDwordImToMem16
        or bl,40h       
EmMoveDwordImToMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadCodeDword
        pop ebx
        pop esi
        call WriteDword
        ret

EmMoveDwordImToReg:
        call ReadCodeDword
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ds:[ebp+esi],eax
        ret
EmMoveDwordImToMem      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveByteRegIm
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
;               NAME:           EmMoveWordRegIm
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
;               NAME:           EmLea
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
        test byte ptr ds:[ebp].em_flags,a32
        jz EmLea16

EmLea32:
        test byte ptr ds:[ebp].em_flags,d32
        jz EmLea32To16

EmLea32To32:
        or bl,40h       
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        mov eax,ebx
        pop bx  
        call SaveDwordReg
        ret

EmLea32To16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        mov ax,bx
        pop bx  
        call SaveWordReg
        ret

EmLea16:
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmLea16To32

EmLea16To16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        mov ax,bx
        pop bx  
        call SaveWordReg
        ret

EmLea16To32:
        or bl,40h       
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        movzx eax,bx
        pop bx  
        call SaveDwordReg
        ret
EmLea   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmLds, EmLes, EmLfs, EmLgs, EmLss
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
;               NAME:           EmMoveSregToMem
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
        movzx esi,al
        cmp al,2*6
        jnc EmulateError
;
        mov esi,dword ptr cs:[2*esi].SegDsTab
        mov ax,ds:[ebp+esi].d_selector
        call SaveWordMemReg
        ret
EmMoveSregToMem Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveMemToSreg
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
        pop bx
        and bl,38h
        shr bl,2
        movzx esi,bl
        cmp bl,2*6
        jnc EmulateError
;
        mov esi,dword ptr cs:[2*esi].SegDsTab
        call LoadSegment
        ret
EmMoveMemToSreg Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMovzx
;
;               DESCRIPTION:    EMULATE movzx
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MovxByteMem     Movzx
MovxWordMem     Movzx
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMovsx
;
;               DESCRIPTION:    EMULATE movsx
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MovxByteMem     Movsx
MovxWordMem     Movsx
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmEnter
;
;               DESCRIPTION:    EMULATE EmEnter x,y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmEnter

EmEnter Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmEnter32
;
        mov ax,word ptr ds:[ebp].reg_ebp
        call PushWord
        mov ax,word ptr ds:[ebp].reg_esp
        mov word ptr ds:[ebp].reg_ebp,ax
        call ReadCodeWord
        call SubFromStack
        call ReadCodeByte
        or al,al
        jnz EmulateError
        ret

EmEnter32:
        mov eax,ds:[ebp].reg_ebp
        call PushDword
        mov eax,ds:[ebp].reg_esp
        mov ds:[ebp].reg_ebp,eax
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
;               NAME:           EmLeave
;
;               DESCRIPTION:    EMULATE EmLeave
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLeave

EmLeave Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmLeave32
;
        mov ax,word ptr ds:[ebp].reg_ebp
        mov word ptr ds:[ebp].reg_esp,ax
        call PopWord
        mov word ptr ds:[ebp].reg_ebp,ax
        ret

EmLeave32:
        mov eax,ds:[ebp].reg_ebp
        mov ds:[ebp].reg_esp,eax
        call PopDword
        mov ds:[ebp].reg_ebp,eax
        ret
EmLeave Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmPushMem
;
;               DESCRIPTION:    EMULATE EmPush Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPushMem

EmPushMem       Proc near
        mov bl,al
        test byte ptr ds:[ebp].em_flags,d32
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
;               NAME:           EmPusha
;
;               DESCRIPTION:    EMULATE pusha
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPusha

EmPusha Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmPushad
;
        push word ptr ds:[ebp].reg_esp
        mov ax,word ptr ds:[ebp].reg_eax
        call PushWord
        mov ax,word ptr ds:[ebp].reg_ecx
        call PushWord
        mov ax,word ptr ds:[ebp].reg_edx
        call PushWord
        mov ax,word ptr ds:[ebp].reg_ebx
        call PushWord
        pop ax
        call PushWord
        mov ax,word ptr ds:[ebp].reg_ebp
        call PushWord
        mov ax,word ptr ds:[ebp].reg_esi
        call PushWord
        mov ax,word ptr ds:[ebp].reg_edi
        call PushWord
        ret

EmPushad:
        push ds:[ebp].reg_esp
        mov eax,ds:[ebp].reg_eax
        call PushDword
        mov eax,ds:[ebp].reg_ecx
        call PushDword
        mov eax,ds:[ebp].reg_edx
        call PushDword
        mov eax,ds:[ebp].reg_ebx
        call PushDword
        pop eax
        call PushDword
        mov eax,ds:[ebp].reg_ebp
        call PushDword
        mov eax,ds:[ebp].reg_esi
        call PushDword
        mov eax,ds:[ebp].reg_edi
        call PushDword
        ret
EmPusha Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmPushIm
;
;               DESCRIPTION:    EMULATE push im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPushIm

EmPushIm        Proc near
        test byte ptr ds:[ebp].em_flags,d32
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
;               NAME:           EmPushImsx
;
;               DESCRIPTION:    EMULATE push imsx
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPushImsx

EmPushImsx      Proc near
        test byte ptr ds:[ebp].em_flags,d32
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
;               NAME:           EmPushReg
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
;               NAME:           EmPushSreg
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
;               NAME:           EmPopMem
;
;               DESCRIPTION:    EMULATE EmPop Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPopMem

EmPopMem        Proc near
        push ax
        test byte ptr ds:[ebp].em_flags,d32
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
;               NAME:           EmPopa
;
;               DESCRIPTION:    EMULATE Popa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPopa

EmPopa  Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmPopad
;
        call PopWord
        mov word ptr ds:[ebp].reg_edi,ax
        call PopWord
        mov word ptr ds:[ebp].reg_esi,ax
        call PopWord
        mov word ptr ds:[ebp].reg_ebp,ax
        call PopWord
        call PopWord
        mov word ptr ds:[ebp].reg_ebx,ax
        call PopWord
        mov word ptr ds:[ebp].reg_edx,ax
        call PopWord
        mov word ptr ds:[ebp].reg_ecx,ax
        call PopWord
        mov word ptr ds:[ebp].reg_eax,ax
        ret

EmPopad:
        call PopDword
        mov ds:[ebp].reg_edi,eax
        call PopDword
        mov ds:[ebp].reg_esi,eax
        call PopDword
        mov ds:[ebp].reg_ebp,eax
        call PopDword
        call PopDword
        mov ds:[ebp].reg_ebx,eax
        call PopDword
        mov ds:[ebp].reg_edx,eax
        call PopDword
        mov ds:[ebp].reg_ecx,eax
        call PopDword
        mov ds:[ebp].reg_eax,eax
        ret
EmPopa  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmPopReg
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
;               NAME:           EmPopSreg
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
;               NAME:           EmXchgByteRegMem
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
        test byte ptr ds:[ebp].em_flags,a32
        jz EmXchgByteRegMem16
        or bl,40h       
EmXchgByteRegMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
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
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        pop ax
        xchg al,ds:[ebp+esi]
        pop bx
        call SaveByteReg
        ret
EmXchgByteRegMem        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmXchgWordRegMem
;
;               DESCRIPTION:    EMULATE xchg reg,word ptr Mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmXchgWordRegMem

EmXchgWordRegMem        Proc near
        test byte ptr ds:[ebp].em_flags,d32
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
        test byte ptr ds:[ebp].em_flags,a32
        jz EmXchgWordRegMem16
        or bl,40h       
EmXchgWordRegMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
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
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        pop ax
        xchg ax,ds:[ebp+esi]
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
        test byte ptr ds:[ebp].em_flags,a32
        jz EmXchgDwordRegMem16
        or bl,40h       
EmXchgDwordRegMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
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
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        pop eax
        xchg eax,ds:[ebp+esi]
        pop bx
        call SaveDwordReg
        ret
EmXchgDwordRegMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmXchgAxReg
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
;               NAME:           EmInByteDx / EmInByteIm
;
;               DESCRIPTION:    EMULERA IN AL,DX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmInByteIm

EmInByteIm      Proc near
        call ReadCodeByte
        movzx dx,al
        call InByte
        mov byte ptr ds:[ebp].reg_eax,al
        ret
EmInByteIm      Endp

        public EmInByteDx

EmInByteDx      PROC near
        mov dx,word ptr ds:[ebp].reg_edx
        call InByte
        mov byte ptr ds:[ebp].reg_eax,al
        ret
EmInByteDx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           EmInWordDx / EmInDwordDx / EmInWordIm
;
;               DESCRIPTION:    EMULERA IN (E)AX,DX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmInWordIm

EmInWordIm      Proc near
        call ReadCodeByte
        movzx dx,al
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmInDwordIm
        call InWord
        mov word ptr ds:[ebp].reg_eax,ax
        ret

EmInDwordIm:
        call InDword
        mov ds:[ebp].reg_eax,eax
        ret
EmInWordIm      Endp

        public EmInWordDx
        
EmInWordDx      PROC near
        mov dx,word ptr ds:[ebp].reg_edx
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmInDwordDx
        call InWord
        mov word ptr ds:[ebp].reg_eax,ax
        ret

EmInDwordDx:
        call InDword
        mov ds:[ebp].reg_eax,eax
        ret
EmInWordDx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           EmOutByteDx / EmOutByteIm
;
;               DESCRIPTION:    EMULERA OUT DX,AL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmOutByteIm

EmOutByteIm     Proc near
        call ReadCodeByte
        movzx dx,al
        mov al,byte ptr ds:[ebp].reg_eax
        call OutByte
        ret
EmOutByteIm     Endp

        public EmOutByteDx

EmOutByteDx     PROC near
        mov dx,word ptr ds:[ebp].reg_edx
        mov al,byte ptr ds:[ebp].reg_eax
        call OutByte
        ret
EmOutByteDx     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           EmOutWordDx / EmOutDwordDx / EmOutWordIm
;
;               DESCRIPTION:    EMULERA OUT DX,(E)AX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmOutWordIm

EmOutWordIm     Proc near
        call ReadCodeByte
        movzx dx,al
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmOutDwordIm
        mov ax,word ptr ds:[ebp].reg_eax
        call OutWord
        ret

EmOutDwordIm:
        mov eax,ds:[ebp].reg_eax
        call OutDword
        ret
EmOutWordIm     Endp

        public EmOutWordDx
        
EmOutWordDx     PROC near
        mov dx,word ptr ds:[ebp].reg_edx
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmOutDwordDx
        mov ax,word ptr ds:[ebp].reg_eax
        call OutWord
        ret

EmOutDwordDx:
        mov eax,ds:[ebp].reg_eax
        call OutDword
        ret
EmOutWordDx     ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmPushf / EmPushfd
;
;               DESCRIPTION:    EMULATE Pushf / Pushfd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPushf

EmPushf proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmPushfd
;
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmPushfDo
;
        test byte ptr ds:[ebp].reg_eflags+2,2
        jz EmPushfDo
;
        test ds:[ebp].reg_cr4,1
        jz EmPushfComp
;
        mov eax,ds:[ebp].reg_eflags
        mov ebx,eax
        and ebx,80000h
        shr ebx,10
        and ax,NOT 200h
        or ax,bx        
        call PushWord
        ret

EmPushfComp:
        mov ecx,ds:[ebp].reg_eflags
        and ecx,EFLAGS_IOPL
        cmp ecx,EFLAGS_IOPL
        jne PrivilegeFault

EmPushfDo:
        mov ax,word ptr ds:[ebp].reg_eflags
        call PushWord
        ret

EmPushfd:
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmPushfdDo
;
        test byte ptr ds:[ebp].reg_eflags+2,2
        jz EmPushfdDo
;
        test ds:[ebp].reg_cr4,1
        jz EmPushfdComp
;
        mov eax,ds:[ebp].reg_eflags
        mov ebx,eax
        and ebx,80000h
        shr ebx,10
        and ax,NOT 200h
        or ax,bx        
        call PushDword
        ret
        
EmPushfdComp:        
        mov ecx,ds:[ebp].reg_eflags
        and ecx,EFLAGS_IOPL
        cmp ecx,EFLAGS_IOPL
        jne PrivilegeFault

EmPushfdDo:
        mov eax,ds:[ebp].reg_eflags
        call PushDword
        ret
EmPushf endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmPopf / EmPopfd
;
;               DESCRIPTION:    EMULATE popf / popfd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmPopf

EmPopf  proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmPopfd
;
        call PopWord
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmPopfDo
;
        test byte ptr ds:[ebp].reg_eflags+2,2
        jz EmPopfPm
;
        test ds:[ebp].reg_cr4,1
        jz EmPopfComp
;        
        mov ebx,ds:[ebp].reg_eflags
        and ebx,NOT 80000h
        mov bx,ax
        mov eax,ebx
;
        and ebx,200h
        shl ebx,10
        or eax,ebx
        or al,2
        and ax,NOT 200h
        mov bx,word ptr ds:[ebp].reg_eflags
        and bx,200h
        or ax,bx
        mov ds:[ebp].reg_eflags,eax
        ret

EmPopfComp:
        mov ecx,ds:[ebp].reg_eflags
        and ecx,EFLAGS_IOPL
        cmp ecx,EFLAGS_IOPL
        jne PrivilegeFault
        jmp EmPopfDo

EmPopfPm:
        mov ecx,ds:[ebp].reg_eflags
        ror cx,4
        mov ch,byte ptr ds:[ebp].reg_cs.d_access
        and cx,303h
        cmp cl,ch
        jc EmPopfDone

EmPopfDo:
        or al,2
        mov word ptr ds:[ebp].reg_eflags,ax

EmPopfDone:
        ret

EmPopfd:
        call PopDword
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmPopfdDo
;
        test byte ptr ds:[ebp].reg_eflags+2,2
        jz EmPopfdPm
;
        test ds:[ebp].reg_cr4,1
        jz EmPopfdComp
;        
        mov ebx,ds:[ebp].reg_eflags
        and ebx,NOT 80000h
        mov bx,ax
        mov eax,ebx
;
        and ebx,200h
        shl ebx,10
        or eax,ebx
        or al,2
        and ax,NOT 200h
        mov bx,word ptr ds:[ebp].reg_eflags
        and bx,200h
        or ax,bx
        mov ds:[ebp].reg_eflags,eax
        ret

EmPopfdComp:
        mov ecx,ds:[ebp].reg_eflags
        and ecx,EFLAGS_IOPL
        cmp ecx,EFLAGS_IOPL
        jne PrivilegeFault
        jmp EmPopfdDo

EmPopfdPm:
        mov ecx,ds:[ebp].reg_eflags
        ror cx,4
        mov ch,byte ptr ds:[ebp].reg_cs.d_access
        and cx,303h
        cmp cl,ch
        jc EmPopfdDone

EmPopfdDo:
        or al,2
        mov ds:[ebp].reg_eflags,eax

EmPopfdDone:
        ret
EmPopf  endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmLahf
;
;               DESCRIPTION:    EMULATE lahf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLahf

EmLahf  proc near
        mov al,byte ptr ds:[ebp].reg_eflags
        mov byte ptr ds:[ebp].reg_eax+1,al
        ret
EmLahf  endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmSahf
;
;               DESCRIPTION:    EMULATE sahf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmSahf

EmSahf  proc near
        mov al,byte ptr ds:[ebp].reg_eax+1
        and al,NOT 28h
        or al,2
        mov byte ptr ds:[ebp].reg_eflags,al
        ret
EmSahf  endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmClc
;
;               DESCRIPTION:    EMULATE clc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmClc

EmClc   proc near
        and byte ptr ds:[ebp].reg_eflags, NOT EFLAGS_CF
        ret
EmClc   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmStc
;
;               DESCRIPTION:    EMULATE stc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmStc

EmStc   proc near
        or byte ptr ds:[ebp].reg_eflags, EFLAGS_CF
        ret
EmStc   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCmc
;
;               DESCRIPTION:    EMULATE cmc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCmc

EmCmc   proc near
        xor byte ptr ds:[ebp].reg_eflags, EFLAGS_CF
        ret
EmCmc   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCld
;
;               DESCRIPTION:    EMULATE cld
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCld

EmCld   proc near
        and word ptr ds:[ebp].reg_eflags, NOT EFLAGS_DF
        ret
EmCld   endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmStd
;
;               DESCRIPTION:    EMULATE std
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmStd

EmStd   proc near
        or word ptr ds:[ebp].reg_eflags, EFLAGS_DF
        ret
EmStd   endp

code    ENDS

        END
