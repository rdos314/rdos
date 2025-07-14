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
; EMARITHM.ASM
; Arithmetric group instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include emcom.inc
include emmem.inc
include emseg.inc

.486p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ByteRegMem
;
;               DESCRIPTION:    Emulate byte ptr reg, mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ByteRegMem      Macro op

        public Em&op&ByteRegMem

Em&op&ByteRegMem        Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteReg
        pop bx
        push bx
        push ax
        call LoadByteMemReg
        mov bl,al
        pop ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,bl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop bx
        call SaveByteReg
        ret
Em&op&ByteRegMem        Endp
                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ByteWordMem
;
;               DESCRIPTION:    Emulate (d)word ptr reg, mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WordRegMem      Macro op

        public Em&op&WordRegMem

Em&op&WordRegMem        Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordRegMem
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordReg
        pop bx
        push bx
        push ax
        call LoadWordMemReg
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop bx
        call SaveWordReg
        ret
Em&op&WordRegMem        Endp

Em&op&DwordRegMem       Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordReg
        pop bx
        push bx
        push eax
        call LoadDwordMemReg
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop bx
        call SaveDwordReg
        ret
Em&op&DwordRegMem       Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ByteMemReg
;
;               DESCRIPTION:    Emulate byte ptr mem, reg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ByteMemReg      Macro op

        public Em&op&ByteMemReg

Em&op&ByteMemReg        Proc near
        call ReadCodeByte
        mov bl,al
;
        push bx
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&ByteMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&ByteMemReg16
        or bl,40h       
Em&op&ByteMemReg16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        pop ax
        push esi
        push ebx
        push ax
        call ReadByte
        pop bx
        push ax
        call LoadByteReg
        mov bl,al
        pop ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,bl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop ebx
        pop esi
        call WriteByte
        ret

Em&op&ByteMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov al,ds:[ebp+esi]
        pop bx
        push esi
        push ax
        call LoadByteReg
        mov bl,al
        pop ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,bl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop esi
        mov ds:[ebp+esi],al
        ret
Em&op&ByteMemReg        Endp
                        Endm

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

WordMemReg      Macro op

        public Em&op&WordMemReg

Em&op&WordMemReg        Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMemReg
;
        call ReadCodeByte
        mov bl,al
        push bx
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&WordMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&WordMemReg16
        or bl,40h       
Em&op&WordMemReg16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        pop ax
        push esi
        push ebx
        push ax
        call ReadWord
        pop bx
        push ax
        call LoadWordReg
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop ebx
        pop esi
        call WriteWord
        ret

Em&op&WordMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ax,ds:[ebp+esi]
        pop bx
        push esi
        push ax
        call LoadWordReg
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop esi
        mov ds:[ebp+esi],bx
        ret
Em&op&WordMemReg        Endp

Em&op&DwordMemReg       Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&DwordMemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&DwordMemReg16
        or bl,40h       
Em&op&DwordMemReg16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        pop ax
        push esi
        push ebx
        push ax
        call ReadDword
        pop bx
        push eax
        call LoadDwordReg
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop ebx
        pop esi
        call WriteDword
        ret

Em&op&DwordMemRegReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        pop bx
        push esi
        push eax
        call LoadDwordReg
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop esi
        mov ds:[ebp+esi],ebx
        ret
Em&op&DwordMemReg       Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ByteMem
;
;               DESCRIPTION:    Emulate byte ptr mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ByteMem Macro op

        public Em&op&ByteMem

Em&op&ByteMem   Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&ByteMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&ByteMem16
        or bl,40h       
Em&op&ByteMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadByte
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop ebx
        pop esi
        call WriteByte
        ret

Em&op&ByteMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op byte ptr ds:[ebp+esi]
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&ByteMem   Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WordMem
;
;               DESCRIPTION:    Emulate (d)word ptr mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WordMem Macro op

        public Em&op&WordMem

Em&op&WordMem   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMem
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&WordMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&WordMem16
        or bl,40h       
Em&op&WordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadWord
        mov dx,ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,dx
        pop ebx
        pop esi
        call WriteWord
        ret

Em&op&WordMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op word ptr ds:[ebp+esi]
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordMem   Endp

Em&op&DwordMem  Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&DwordMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&DwordMem16
        or bl,40h       
Em&op&DwordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadDword
        mov edx,eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,edx
        pop ebx
        pop esi
        call WriteDword
        ret

Em&op&DwordMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op dword ptr ds:[ebp+esi]
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordMem  Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ByteImMem
;
;               DESCRIPTION:    Emulate byte ptr mem, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ByteImMem       Macro op

        public Em&op&ByteImMem

Em&op&ByteImMem Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&ByteImMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&ByteImMem16
        or bl,40h       
Em&op&ByteImMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadByte
        push ax
        call ReadCodeByte
        mov bl,al
        pop ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,bl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop ebx
        pop esi
        call WriteByte
        ret

Em&op&ByteImMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov al,ds:[ebp+esi]
        push esi
        push ax
        call ReadCodeByte
        mov bl,al
        pop ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,bl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop esi
        mov ds:[ebp+esi],al
        ret
Em&op&ByteImMem Endp
                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WordImMem
;
;               DESCRIPTION:    Emulate (d)word ptr mem, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WordImMem       Macro op

        public Em&op&WordImMem

Em&op&WordImMem Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordImMem
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&WordImMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&WordImMem16
        or bl,40h       
Em&op&WordImMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadWord
        push ax
        call ReadCodeWord
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop ebx
        pop esi
        call WriteWord
        ret

Em&op&WordImMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ax,ds:[ebp+esi]
        push esi
        push ax
        call ReadCodeWord
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop esi
        mov ds:[ebp+esi],bx
        ret
Em&op&WordImMem Endp

Em&op&DwordImMem        Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&DwordImMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&DwordImMem16
        or bl,40h       
Em&op&DwordImMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadDword
        push eax
        call ReadCodeDword
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop ebx
        pop esi
        call WriteDword
        ret

Em&op&DwordImMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        push esi
        push eax
        call ReadCodeDword
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop esi
        mov ds:[ebp+esi],ebx
        ret
Em&op&DwordImMem        Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ByteImAcc
;
;               DESCRIPTION:    Emulate al, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ByteImAcc       Macro op

        public Em&op&ByteImAcc

Em&op&ByteImAcc Proc near
        call ReadCodeByte
        mov bl,byte ptr ds:[ebp].reg_eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bl,al
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov byte ptr ds:[ebp].reg_eax,bl
        ret
Em&op&ByteImAcc Endp
                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WordImAcc
;
;               DESCRIPTION:    Emulate (e)ax, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WordImAcc       Macro op

        public Em&op&WordImAcc

Em&op&WordImAcc Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordImAcc
;
        call ReadCodeWord
        mov dx,ax
        mov bx,word ptr ds:[ebp].reg_eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,bx
        ret
Em&op&WordImAcc Endp

Em&op&DwordImAcc        Proc near
        call ReadCodeDword
        mov edx,eax
        mov ebx,ds:[ebp].reg_eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ds:[ebp].reg_eax,ebx
        ret
Em&op&DwordImAcc        Endp

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

WordImsxMem     Macro op

        public Em&op&WordImsxMem

Em&op&WordImsxMem       Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordImsxMem
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&WordImsxMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&WordImsxMem16
        or bl,40h       
Em&op&WordImsxMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadWord
        push ax
        call ReadCodeByte
        movsx dx,al
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop ebx
        pop esi
        call WriteWord
        ret

Em&op&WordImsxMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ax,ds:[ebp+esi]
        push esi
        push ax
        call ReadCodeByte
        movsx dx,al
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop esi
        mov ds:[ebp+esi],bx
        ret
Em&op&WordImsxMem       Endp

Em&op&DwordImsxMem      Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&DwordImsxMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&DwordImsxMem16
        or bl,40h       
Em&op&DwordImsxMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadDword
        push eax
        call ReadCodeByte
        movsx edx,al
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop ebx
        pop esi
        call WriteDword
        ret

Em&op&DwordImsxMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        push esi
        push eax
        call ReadCodeByte
        movsx edx,al
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop esi
        mov ds:[ebp+esi],ebx
        ret
Em&op&DwordImsxMem      Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckByteMemReg
;
;               DESCRIPTION:    Emulate check byte mem, reg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckByteMemReg Macro op

        public Em&op&ByteMemReg

Em&op&ByteMemReg        Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteReg
        pop bx
        push ax
        call LoadByteMemReg
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,bl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&ByteMemReg        Endp

                                Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckWordMemReg
;
;               DESCRIPTION:    Emulate check (d)word mem, reg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckWordMemReg Macro op

        public Em&op&WordMemReg

Em&op&WordMemReg        Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMemReg
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordReg
        pop bx
        push ax
        call LoadWordMemReg
        pop bx
        mov dx,ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op dx,bx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordMemReg        Endp

Em&op&DwordMemReg       Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordReg
        pop bx
        push eax
        call LoadDwordMemReg
        pop ebx
        mov edx,eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op edx,ebx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordMemReg       Endp

                                Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckByteRegMem
;
;               DESCRIPTION:    Emulate check byte reg, mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckByteRegMem Macro op

        public Em&op&ByteRegMem

Em&op&ByteRegMem        Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadByteReg
        pop bx
        push ax
        call LoadByteMemReg
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bl,al
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&ByteRegMem        Endp

                                Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckWordRegMem
;
;               DESCRIPTION:    Emulate check (d)word reg, mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckWordRegMem Macro op

        public Em&op&WordRegMem

Em&op&WordRegMem        Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordRegMem
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordReg
        pop bx
        push ax
        call LoadWordMemReg
        pop bx
        mov dx,ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordRegMem        Endp

Em&op&DwordRegMem       Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordReg
        pop bx
        push eax
        call LoadDwordMemReg
        pop ebx
        mov edx,eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordRegMem       Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckByteImMem
;
;               DESCRIPTION:    Emulate check byte mem, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckByteImMem  Macro op

        public Em&op&ByteImMem

Em&op&ByteImMem Proc near
        mov bl,al
        call LoadByteMemReg
        push ax
        call ReadCodeByte
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bl,al
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&ByteImMem Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckWordImMem
;
;               DESCRIPTION:    Emulate check (d)word mem, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckWordImMem  Macro op

        public Em&op&WordImMem

Em&op&WordImMem Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordImMem
;
        mov bl,al
        call LoadWordMemReg
        push ax
        call ReadCodeWord
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordImMem Endp

Em&op&DwordImMem        Proc near
        mov bl,al
        call LoadDwordMemReg
        push eax
        call ReadCodeDword
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordImMem        Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckByteImAcc
;
;               DESCRIPTION:    Emulate check al, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckByteImAcc  Macro op

        public Em&op&ByteImAcc

Em&op&ByteImAcc Proc near
        call ReadCodeByte
        mov bl,byte ptr ds:[ebp].reg_eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bl,al
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&ByteImAcc Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckWordImAcc
;
;               DESCRIPTION:    Emulate check (e)ax, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckWordImAcc  Macro op

        public Em&op&WordImAcc

Em&op&WordImAcc Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordImAcc
;
        call ReadCodeWord
        mov dx,ax
        mov bx,word ptr ds:[ebp].reg_eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordImAcc Endp

Em&op&DwordImAcc        Proc near
        call ReadCodeDword
        mov edx,eax
        mov ebx,ds:[ebp].reg_eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordImAcc        Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CheckWordImsxMem
;
;               DESCRIPTION:    Emulate check (d)word mem, immediate with sign-extend
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckWordImsxMem        Macro op

        public Em&op&WordImsxMem

Em&op&WordImsxMem       Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordImsxMem
;
        mov bl,al
        call LoadWordMemReg
        push ax
        call ReadCodeByte
        movsx dx,al
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordImsxMem       Endp

Em&op&DwordImsxMem      Proc near
        mov bl,al
        call LoadDwordMemReg
        push eax
        call ReadCodeByte
        movsx edx,al
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordImsxMem      Endp

                Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RotateByteMem1
;
;               DESCRIPTION:    Emulate rotate byte, mem, 1
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotateByteMem1  Macro op

        public Em&op&ByteMem1

Em&op&ByteMem1  Proc near
        mov bl,al
;
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&ByteMemReg1
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&ByteMem116
        or bl,40h       
Em&op&ByteMem116:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadByte
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,1
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop ebx
        pop esi
        call WriteByte
        ret

Em&op&ByteMemReg1:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op byte ptr ds:[ebp+esi], 1
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&ByteMem1  Endp
                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RotateWordMem1
;
;               DESCRIPTION:    Emulate rotate (d)word, mem, 1
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotateWordMem1  Macro op

        public Em&op&WordMem1

Em&op&WordMem1  Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMem1
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&WordMemReg1
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&WordMem116
        or bl,40h       
Em&op&WordMem116:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadWord
        mov bx,ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,1
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop ebx
        pop esi
        call WriteWord
        ret

Em&op&WordMemReg1:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op word ptr ds:[ebp+esi], 1
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordMem1  Endp

Em&op&DwordMem1 Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&DwordMemReg1
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&DwordMem116
        or bl,40h       
Em&op&DwordMem116:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadDword
        mov ebx,eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,1
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop ebx
        pop esi
        call WriteDword
        ret

Em&op&DwordMemReg1:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op dword ptr ds:[ebp+esi], 1
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordMem1 Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RotateByteMemCl
;
;               DESCRIPTION:    Emulate rotate byte, mem, cl
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotateByteMemCl Macro op

        public Em&op&ByteMemCl

Em&op&ByteMemCl Proc near
        mov bl,al
;
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&ByteMemRegCl
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&ByteMemCl16
        or bl,40h       
Em&op&ByteMemCl16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadByte
        mov cl,byte ptr ds:[ebp].reg_ecx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop ebx
        pop esi
        call WriteByte
        ret

Em&op&ByteMemRegCl:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov cl,byte ptr ds:[ebp].reg_ecx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op byte ptr ds:[ebp+esi], cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&ByteMemCl Endp
                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RotateWordMemCl
;
;               DESCRIPTION:    Emulate rotate (d)word, mem, cl
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotateWordMemCl Macro op

        public Em&op&WordMemCl

Em&op&WordMemCl Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMemCl
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&WordMemRegCl
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&WordMemCl16
        or bl,40h       
Em&op&WordMemCl16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadWord
        mov bx,ax
        mov cl,byte ptr ds:[ebp].reg_ecx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop ebx
        pop esi
        call WriteWord
        ret

Em&op&WordMemRegCl:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov cl,byte ptr ds:[ebp].reg_ecx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op word ptr ds:[ebp+esi], cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordMemCl Endp

Em&op&DwordMemCl        Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&DwordMemRegCl
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&DwordMemCl16
        or bl,40h       
Em&op&DwordMemCl16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadDword
        mov ebx,eax
        mov cl,byte ptr ds:[ebp].reg_ecx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop ebx
        pop esi
        call WriteDword
        ret

Em&op&DwordMemRegCl:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov cl,byte ptr ds:[ebp].reg_ecx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op dword ptr ds:[ebp+esi], cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordMemCl        Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RotateByteMemIm
;
;               DESCRIPTION:    Emulate rotate byte, mem, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotateByteMemIm Macro op

        public Em&op&ByteMemIm

Em&op&ByteMemIm Proc near
        mov bl,al
;
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&ByteMemRegIm
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&ByteMemIm16
        or bl,40h       
Em&op&ByteMemIm16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadByte
        push ax
        call ReadCodeByte
        mov cl,al
        pop ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al,cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        pop ebx
        pop esi
        call WriteByte
        ret

Em&op&ByteMemRegIm:
        push bx
        call ReadCodeByte
        mov cl,al
        pop bx
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op byte ptr ds:[ebp+esi], cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&ByteMemIm Endp
                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RotateByteWordIm
;
;               DESCRIPTION:    Emulate rotate (d)word, mem, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotateWordMemIm Macro op

        public Em&op&WordMemIm

Em&op&WordMemIm Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMemIm
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&WordMemRegIm
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&WordMemIm16
        or bl,40h       
Em&op&WordMemIm16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadWord
        push ax
        call ReadCodeByte
        mov cl,al
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op bx,cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop ebx
        pop esi
        call WriteWord
        ret

Em&op&WordMemRegIm:
        push bx
        call ReadCodeByte
        mov cl,al
        pop bx
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op word ptr ds:[ebp+esi],cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&WordMemIm Endp

Em&op&DwordMemIm        Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&DwordMemRegIm
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&DwordMemIm16
        or bl,40h       
Em&op&DwordMemIm16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        push esi
        push ebx
        call ReadDword
        push eax
        call ReadCodeByte
        mov cl,al
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ebx,cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop ebx
        pop esi
        call WriteDword
        ret

Em&op&DwordMemRegIm:
        push bx
        call ReadCodeByte
        mov cl,al
        pop bx
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op dword ptr ds:[ebp+esi],cl
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        ret
Em&op&DwordMemIm        Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           FlagsReg
;
;               DESCRIPTION:    Emulate flags
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlagsRegOne     MACRO op, reg, name

        public Em&op&name

Em&op&name      Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&E&reg
;
        mov dx,word ptr ds:[ebp].reg_e&reg
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_e&reg,dx
        ret

Em&op&E&reg:
        mov edx,ds:[ebp].reg_e&reg
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ds:[ebp].reg_e&reg,edx
        ret
Em&op&name      Endp

                Endm

FlagsReg        Macro   op

        FlagsRegOne op, ax, Ax
        FlagsRegOne op, bx, Bx
        FlagsRegOne op, cx, Cx
        FlagsRegOne op, dx, Dx
        FlagsRegOne op, sp, Sp
        FlagsRegOne op, bp, Bp
        FlagsRegOne op, si, Si
        FlagsRegOne op, di, Di

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ExtByteMem
;
;               DESCRIPTION:    Emulate extend byte, mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExtByteMem      Macro op

        public Em&op&ByteMem

Em&op&ByteMem   Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&ByteMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&ByteMem16
        or bl,40h       
Em&op&ByteMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadByte
        mov  bl,al
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax   ;MUL utilise AL et DIV utilise AX
        &op bl
        mov bx,ax
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,bx
        ret

Em&op&ByteMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax   ;MUL utilise AL et DIV utilise AX
        &op byte ptr ds:[ebp+esi]
        mov cx,ax
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,cx
        ret
Em&op&ByteMem   Endp

        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ExtWordMem
;
;               DESCRIPTION:    Emulate extend (d)word, mem
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExtWordMem      Macro op

        public Em&op&WordMem

Em&op&WordMem   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMem
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&WordMemReg             ;One of the the 8 registers mode
;                                        else one of the 24  addressing modes
;bl=xx000000   bh=yyyyyyyy

        shr bl,2        ;bl=00xx0000            
        and bh,7        ;bh=00000yyy
        shl bh,1        ;bh=0000yyy0
        or bl,bh        ;bl=00xxyyy0
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&WordMem16
        or bl,40h       
Em&op&WordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadWord
        mov cx,ax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax   ;MUL utilise AX 
        mov dx,word ptr ds:[ebp].reg_edx   ;et DIV utilise DX:AX

        &op cx
        mov cx,ax
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,cx
        mov word ptr ds:[ebp].reg_edx,dx
        ret

Em&op&WordMemReg:
        and bh,7        ;bh=00000yyy
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax   ;MUL utilise AX 
        mov dx,word ptr ds:[ebp].reg_edx   ;et DIV utilise DX:AX
        &op word ptr ds:[ebp+esi]
        mov cx,ax       
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,cx
        mov word ptr ds:[ebp].reg_edx,dx
        ret

Em&op&WordMem   Endp

Em&op&DwordMem  Proc near
        mov bl,al
        
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&DwordMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&DwordMem16
        or bl,40h       
Em&op&DwordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadDword

        mov ecx,eax
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov eax,ds:[ebp].reg_eax   ;MUL utilise EAX 
        mov edx,ds:[ebp].reg_edx   ;et DIV utilise EDX:EAX

        &op ecx
        mov ecx,eax
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ds:[ebp].reg_eax,ecx
        mov ds:[ebp].reg_edx,edx
        ret
        
Em&op&DwordMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov eax,ds:[ebp].reg_eax   ;MUL utilise EAX 
        mov edx,ds:[ebp].reg_edx   ;et DIV utilise EDX:EAX

        &op dword ptr ds:[ebp+esi]
        mov ecx,eax     
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ds:[ebp].reg_eax,ecx
        mov ds:[ebp].reg_edx,edx
        ret

Em&op&DwordMem  Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Adjust
;
;               DESCRIPTION:    Emulate adjust
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Adjust  Macro op

        public Em&op

Em&op   Proc near
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax
        &op
        mov cx,ax
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,cx
        ret
Em&op   Endp

                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Setcc
;
;               DESCRIPTION:    Emulate set condition code
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Setcc   Macro op

        public Em&op

Em&op   Proc near
        call ReadCodeByte
        mov bl,al
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op al
        call SaveByteMemReg
        ret
Em&op   Endp
                        Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           BitMemReg
;
;               DESCRIPTION:    Emulate bit mem, reg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BitMemReg       Macro op

        public Em&op&MemReg

Em&op&MemReg    Proc near
        call ReadCodeByte
        mov bl,al
;
        test byte ptr ds:[ebp].em_flags,d32
        jnz Em&op&DwordMemReg

Em&op&WordMemReg:
        push bx
        call LoadWordReg
        pop bx
        movzx eax,ax
        push eax
        jmp Em&op&MemRegDo

Em&op&DwordMemReg:
        push bx
        call LoadDwordReg
        pop bx
        push eax

Em&op&MemRegDo:
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&MemRegReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&MemReg16
        or bl,40h       
Em&op&MemReg16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        pop eax
        mov cl,al
        and cx,7
        shr eax,3
        add ebx,eax
;
        push ebx
        push esi
        push cx
        call ReadByte
        pop cx
;
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ax,cx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
;       
        pop esi
        pop ebx
        call WriteByte
        ret

Em&op&MemRegReg:
        and bh,7
        pop ecx
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax
        &op ax,cx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ds:[ebp+esi],eax       
        ret
Em&op&MemReg    Endp

                                Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           BitImMem
;
;               DESCRIPTION:    Emulate bit mem, immediate
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BitImMem        Macro op

        public Em&op&ImMem

Em&op&ImMem     Proc near
        mov bl,al
        push bx
        call ReadCodeByte
        pop bx
        movzx eax,al
        push eax
;
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je Em&op&ImMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz Em&op&ImMem16
        or bl,40h       
Em&op&ImMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        pop eax
        mov cl,al
        and cx,7
        shr eax,3
        add ebx,eax
;
        push ebx
        push esi
        push cx
        call ReadByte
        pop cx
;
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        &op ax,cx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
;       
        pop esi
        pop ebx
        call WriteByte
        ret

Em&op&ImMemReg:
        and bh,7
        pop ecx
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax
        &op ax,cx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ds:[ebp+esi],eax       
        ret
Em&op&ImMem     Endp

                                Endm
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           add
;
;               DESCRIPTION:    EMULATE add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMemReg Add
        WordMemReg Add
        ByteRegMem Add
        WordRegMem Add
        ByteImAcc Add
        WordImAcc Add
        ByteImMem Add
        WordImMem Add
        WordImsxMem Add

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           adc
;
;               DESCRIPTION:    EMULATE adc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMemReg Adc
        WordMemReg Adc
        ByteRegMem Adc
        WordRegMem Adc
        ByteImAcc Adc
        WordImAcc Adc
        ByteImMem Adc
        WordImMem Adc
        WordImsxMem Adc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           sub
;
;               DESCRIPTION:    EMULATE sub
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMemReg Sub
        WordMemReg Sub
        ByteRegMem Sub
        WordRegMem Sub
        ByteImAcc Sub
        WordImAcc Sub
        ByteImMem Sub
        WordImMem Sub
        WordImsxMem Sub

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           sbb
;
;               DESCRIPTION:    EMULATE sbb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMemReg Sbb
        WordMemReg Sbb
        ByteRegMem Sbb
        WordRegMem Sbb
        ByteImAcc Sbb
        WordImAcc Sbb
        ByteImMem Sbb
        WordImMem Sbb
        WordImsxMem Sbb

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           and
;
;               DESCRIPTION:    EMULATE and
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMemReg And
        WordMemReg And
        ByteRegMem And
        WordRegMem And
        ByteImAcc And
        WordImAcc And
        ByteImMem And
        WordImMem And
        WordImsxMem And

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           or
;
;               DESCRIPTION:    EMULATE or
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMemReg Or
        WordMemReg Or
        ByteRegMem Or
        WordRegMem Or
        ByteImAcc Or
        WordImAcc Or
        ByteImMem Or
        WordImMem Or
        WordImsxMem Or

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           xor
;
;               DESCRIPTION:    EMULATE xor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMemReg Xor
        WordMemReg Xor
        ByteRegMem Xor
        WordRegMem Xor
        ByteImAcc Xor
        WordImAcc Xor
        ByteImMem Xor
        WordImMem Xor
        WordImsxMem Xor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           bsf
;
;               DESCRIPTION:    EMULATE bsf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmBsf

EmBsf   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmBsf32
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordReg
        pop bx
        push bx
        push ax
        call LoadWordMemReg
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        bsf bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop bx
        call SaveWordReg
        ret
EmBsf   Endp

EmBsf32 Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordReg
        pop bx
        push bx
        push eax
        call LoadDwordMemReg
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        bsf ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop bx
        call SaveDwordReg
        ret
EmBsf32 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           bsr
;
;               DESCRIPTION:    EMULATE bsr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmBsr

EmBsr   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmBsr32
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordReg
        pop bx
        push bx
        push ax
        call LoadWordMemReg
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        bsr bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop bx
        call SaveWordReg
        ret
EmBsr   Endp

EmBsr32 Proc near
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadDwordReg
        pop bx
        push bx
        push eax
        call LoadDwordMemReg
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        bsr ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop bx
        call SaveDwordReg
        ret
EmBsr32 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           cmp
;
;               DESCRIPTION:    EMULATE cmp reg,byte ptr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        CheckByteMemReg Cmp
        CheckWordMemReg Cmp
        CheckByteRegMem Cmp
        CheckWordRegMem Cmp
        CheckByteImAcc Cmp
        CheckWordImAcc Cmp
        CheckByteImMem Cmp
        CheckWordImMem Cmp
        CheckWordImsxMem Cmp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           TestByteImMem
;
;               DESCRIPTION:    EMULATE test byte ptr mem,im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        CheckByteMemReg Test
        CheckWordMemReg Test
        CheckByteImAcc Test
        CheckWordImAcc Test
        CheckByteImMem Test
        CheckWordImMem Test
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmInc
;
;               DESCRIPTION:    EMULATE inc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        FlagsReg Inc
        ByteMem Inc
        WordMem Inc
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmDec
;
;               DESCRIPTION:    EMULATE dec
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        FlagsReg Dec
        ByteMem Dec
        WordMem Dec
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmNot
;
;               DESCRIPTION:    EMULATE not
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMem Not
        WordMem Not
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmNeg
;
;               DESCRIPTION:    EMULATE neg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ByteMem Neg
        WordMem Neg
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmBt
;
;               DESCRIPTION:    EMULATE bt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        BitMemReg Bt
        BitImMem Bt
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmBtr
;
;               DESCRIPTION:    EMULATE btr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        BitMemReg Btr
        BitImMem Btr
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmBts
;
;               DESCRIPTION:    EMULATE bts
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        BitMemReg Bts
        BitImMem Bts
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmBtc
;
;               DESCRIPTION:    EMULATE btc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        BitMemReg Btc
        BitImMem Btc
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMul
;
;               DESCRIPTION:    EMULATE mul
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ExtByteMem Mul
        ExtWordMem Mul
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmImul
;
;               DESCRIPTION:    EMULATE imul
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ExtByteMem Imul
        ExtWordMem Imul
        WordRegMem Imul

        public EmImulWordImsxMem

EmImulWordImsxMem Proc near
        call ReadCodeByte
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmImulDwordImsxMem
;
        push ax
        mov bl,al
        call LoadWordMemReg
        push ax
        call ReadCodeByte
        movsx dx,al
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        imul bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop bx
        call SaveWordReg
        ret
EmImulWordImsxMem       Endp

EmImulDwordImsxMem      Proc near
        push ax
        mov bl,al
        call LoadDwordMemReg
        push eax
        call ReadCodeByte
        movsx edx,al
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        imul ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop bx
        call SaveDwordReg
        ret
EmImulDwordImsxMem      Endp

        public EmImulWordImMem

EmImulWordImMem Proc near
        call ReadCodeByte
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmImulDwordImMem
;
        push ax
        mov bl,al
        call LoadWordMemReg
        push ax
        call ReadCodeWord
        mov dx,ax
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        imul bx,dx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ax,bx
        pop bx
        call SaveWordReg
        ret
EmImulWordImMem       Endp

EmImulDwordImMem      Proc near
        push ax
        mov bl,al
        call LoadDwordMemReg
        push eax
        call ReadCodeDword
        mov edx,eax
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        imul ebx,edx
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov eax,ebx
        pop bx
        call SaveDwordReg
        ret
EmImulDwordImMem      Endp
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           DivByte
;
;               DESCRIPTION:    EMULATE div byte
;
;               PARAMETERS:     BL              dividend
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DivByte Proc near
        mov ax,word ptr ds:[ebp].reg_eax
        cmp ah,bl
        jae DivFault
;
;       mov ah,byte ptr ds:[ebp].reg_eflags
;       sahf
        mov ax,word ptr ds:[ebp].reg_eax
        div bl
        mov cx,ax
;       lahf
;       mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,cx
        ret
DivByte Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           DivWord
;
;               DESCRIPTION:    EMULATE div word
;
;               PARAMETERS:     BX              dividend
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DivWord Proc near
        mov dx,word ptr ds:[ebp].reg_edx
        cmp dx,bx
        jae DivFault
;
;       mov ah,byte ptr ds:[ebp].reg_eflags
;       sahf
        mov ax,word ptr ds:[ebp].reg_eax
        div bx
        mov cx,ax
;       lahf
;       mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,cx
        mov word ptr ds:[ebp].reg_edx,dx
        ret
DivWord Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           DivDword
;
;               DESCRIPTION:    EMULATE div dword
;
;               PARAMETERS:     EBX             dividend
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DivDword        Proc near
        mov edx,ds:[ebp].reg_edx
        cmp edx,ebx
        jae DivFault
;
;       mov ah,byte ptr ds:[ebp].reg_eflags
;       sahf
        mov eax,ds:[ebp].reg_eax
        div ebx
        mov ecx,eax
;       lahf
;       mov byte ptr ds:[ebp].reg_eflags,ah
        mov ds:[ebp].reg_eax,ecx
        mov ds:[ebp].reg_edx,edx
        ret
DivDword        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmDiv
;
;               DESCRIPTION:    EMULATE div
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmDivByteMem

EmDivByteMem    Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmDivByteMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz EmDivByteMem16
        or bl,40h       
EmDivByteMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadByte
        mov bl,al
        call DivByte
        ret

EmDivByteMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov bl,ds:[ebp+esi]
        call DivByte
        ret
EmDivByteMem    Endp

        public EmDivWordMem

EmDivWordMem    Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmDivDwordMem
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmDivWordMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz EmDivWordMem16
        or bl,40h       
EmDivWordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadWord
        mov bx,ax
        call DivWord
        ret

EmDivWordMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov bx,ds:[ebp+esi]
        call DivWord
        ret
EmDivWordMem    Endp

EmDivDwordMem   Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmDivDwordMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz EmDivDwordMem16
        or bl,40h       
EmDivDwordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadDword
        mov ebx,eax
        call DivDword
        ret

EmDivDwordMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ebx,ds:[ebp+esi]
        call DivDword
        ret
EmDivDwordMem   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           IdivByte
;
;               DESCRIPTION:    EMULATE idiv byte
;
;               PARAMETERS:     BL              dividend
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IdivByte        Proc near
        push bx
        mov ah,byte ptr ds:[ebp+1].reg_eax
        test ah,80h
        jz idiv_byte_ah_pos
;
        neg ah

idiv_byte_ah_pos:
        test bl,80h
        jz idiv_byte_bl_pos
;
        neg bl

idiv_byte_bl_pos:
        cmp ah,bl
        jae DivFault
;
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax
        idiv bl
        mov cx,ax
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,cx
        ret
IdivByte        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           IdivWord
;
;               DESCRIPTION:    EMULATE idiv word
;
;               PARAMETERS:     BX              dividend
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IdivWord        Proc near
        push bx
        mov dx,word ptr ds:[ebp].reg_edx
        test dh,80h
        jz idiv_word_dx_pos
;
        neg dx

idiv_word_dx_pos:
        test bh,80h
        jz idiv_word_bx_pos
;
        neg bx

idiv_word_bx_pos:
        cmp dx,bx
        jae DivFault
;
        pop bx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov ax,word ptr ds:[ebp].reg_eax
        mov dx,word ptr ds:[ebp].reg_edx
        div bx
        mov cx,ax
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov word ptr ds:[ebp].reg_eax,cx
        mov word ptr ds:[ebp].reg_edx,dx
        ret
IdivWord        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           IdivDword
;
;               DESCRIPTION:    EMULATE idiv dword
;
;               PARAMETERS:     EBX             dividend
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IdivDword       Proc near
        push ebx
        mov edx,ds:[ebp].reg_edx
        test edx,80000000h
        jz idiv_dword_edx_pos
;
        neg edx

idiv_dword_edx_pos:
        test ebx,80000000h
        jz idiv_dword_ebx_pos
;
        neg ebx

idiv_dword_ebx_pos:
        cmp edx,ebx
        jae DivFault
;
        pop ebx
        mov ah,byte ptr ds:[ebp].reg_eflags
        sahf
        mov eax,ds:[ebp].reg_eax
        mov edx,ds:[ebp].reg_edx
        div ebx
        mov ecx,eax
        lahf
        mov byte ptr ds:[ebp].reg_eflags,ah
        mov ds:[ebp].reg_eax,ecx
        mov ds:[ebp].reg_edx,edx
        ret
IdivDword       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmIdiv
; 
;               DESCRIPTION:    EMULATE idiv
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmIdivByteMem

EmIdivByteMem   Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmIdivByteMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz EmIdivByteMem16
        or bl,40h       
EmIdivByteMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadByte
        mov bl,al
        call IdivByte
        ret

EmIdivByteMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].ByteRegTab
        mov bl,ds:[ebp+esi]
        call IdivByte
        ret
EmIdivByteMem   Endp

        public EmIdivWordMem

EmIdivWordMem   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmIdivDwordMem
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmIdivWordMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz EmIdivWordMem16
        or bl,40h       
EmIdivWordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadWord
        mov bx,ax
        call IdivWord
        ret

EmIdivWordMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].WordRegTab
        mov bx,ds:[ebp+esi]
        call IdivWord
        ret
EmIdivWordMem   Endp

EmIdivDwordMem  Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        cmp bl,0C0h
        je EmIdivDwordMemReg
;
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr ds:[ebp].em_flags,a32
        jz EmIdivDwordMem16
        or bl,40h       
EmIdivDwordMem16:
        movzx ebx,bl
        call dword ptr cs:[2*ebx].MemTab
        call ReadDword
        mov ebx,eax
        call IdivDword
        ret

EmIdivDwordMemReg:
        and bh,7
        movzx esi,bh
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ebx,ds:[ebp+esi]
        call IdivDword
        ret
EmIdivDwordMem  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmRol
;
;               DESCRIPTION:    EMULATE rol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        RotateByteMem1 Rol
        RotateByteMemCl Rol
        RotateByteMemIm Rol
        RotateWordMem1 Rol
        RotateWordMemCl Rol
        RotateWordMemIm Rol
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmRor
;
;               DESCRIPTION:    EMULATE ror
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        RotateByteMem1 Ror
        RotateByteMemCl Ror
        RotateByteMemIm Ror
        RotateWordMem1 Ror
        RotateWordMemCl Ror
        RotateWordMemIm Ror
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmRcl
;
;               DESCRIPTION:    EMULATE rcl
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        RotateByteMem1 Rcl
        RotateByteMemCl Rcl
        RotateByteMemIm Rcl
        RotateWordMem1 Rcl
        RotateWordMemCl Rcl
        RotateWordMemIm Rcl
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmRcr
;
;               DESCRIPTION:    EMULATE rcr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        RotateByteMem1 Rcr
        RotateByteMemCl Rcr
        RotateByteMemIm Rcr
        RotateWordMem1 Rcr
        RotateWordMemCl Rcr
        RotateWordMemIm Rcr
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmShl
;
;               DESCRIPTION:    EMULATE shl
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        RotateByteMem1 Shl
        RotateByteMemCl Shl
        RotateByteMemIm Shl
        RotateWordMem1 Shl
        RotateWordMemCl Shl
        RotateWordMemIm Shl
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmShr
;
;               DESCRIPTION:    EMULATE shr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        RotateByteMem1 Shr
        RotateByteMemCl Shr
        RotateByteMemIm Shr
        RotateWordMem1 Shr
        RotateWordMemCl Shr
        RotateWordMemIm Shr
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmSar
;
;               DESCRIPTION:    EMULATE sar
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        RotateByteMem1 Sar
        RotateByteMemCl Sar
        RotateByteMemIm Sar
        RotateWordMem1 Sar
        RotateWordMemCl Sar
        RotateWordMemIm Sar
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmSetcc
;
;               DESCRIPTION:    EMULATE setcc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        Setcc Seto
        Setcc Setno
        Setcc Setb
        Setcc Setnb
        Setcc Sete
        Setcc Setne
        Setcc Setbe
        Setcc Setnbe
        Setcc Sets
        Setcc Setns
        Setcc Setp
        Setcc Setnp
        Setcc Setl
        Setcc Setnl
        Setcc Setle
        Setcc Setnle
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmAaa, Aas, Daa, Das
;
;               DESCRIPTION:    EMULATE aaa, aas, daa, das
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        Adjust Aaa
        Adjust Aas
        Adjust Daa
        Adjust Das
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCbw
;
;               DESCRIPTION:    EMULATE cbw
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCbw

EmCbw   Proc near
        mov al,byte ptr ds:[ebp].reg_eax
        cbw
        mov word ptr ds:[ebp].reg_eax,ax
        ret
EmCbw   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmCwd, Cdq
;
;               DESCRIPTION:    EMULATE cbw, cdq
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCwd

EmCwd   Proc near
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmCdq
;
        mov ax,word ptr ds:[ebp].reg_eax
        cwd
        mov word ptr ds:[ebp].reg_eax,ax
        mov word ptr ds:[ebp].reg_edx,dx
        ret

EmCdq:
        mov eax,ds:[ebp].reg_eax
        cdq
        mov ds:[ebp].reg_eax,eax
        mov ds:[ebp].reg_edx,edx
        ret
EmCwd   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmBswap
;
;               DESCRIPTION:    EMULATE bswap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmBswap
        
EmBswap proc near
        and al,7
        movzx esi,al
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ebx,ds:[ebp+esi]
        bswap ebx
        mov ds:[ebp+esi],ebx
        ret
EmBswap endp    

code    ENDS

        END
