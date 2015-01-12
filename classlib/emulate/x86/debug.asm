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
; DEBUG.ASM
; Debugger support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

INCLUDE \rdos\classlib\emulate\x86\emulate.inc
INCLUDE \rdos\classlib\emulate\x86\emcom.inc
INCLUDE \rdos\classlib\emulate\debhelp.inc

.data

FloatBuffer DB 40 DUP(?)

.code
        extrn FloatToString:near
;        extrn _debugflag:dword                ;the underscore because of the C language
        extrn op_code_size:dword
        extrn op_in_code:byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteInstr
;
;               DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr      Proc near

;d'abord on va ecrire l'offset
;a priori les registres sont sauvegardés

        lea     ebx,[ebp].reg_cs
        mov     dx,[ebx].d_selector
        mov     ebx,[ebp].reg_eip
        call    WriteHexPtr32

;un peu d'espace

        mov     ecx,1
        call    Blank
                
;maintenant on va copier les bytes d'istruction 
        mov     esi,offset op_in_code
        mov     ecx,op_code_size
@@1:
        lodsb
        call    WriteHexByte
        push    ecx
        mov     ecx,1
        call    Blank
        pop     ecx
        loop    @@1             
        
;un peu d'espace
        mov     eax,op_code_size
        mov     ecx,eax
        shl     eax,1
        add     eax,ecx
        mov     ecx,DISTANCE_INSTRUCTION 
        inc     eax
        sub     ecx,eax         ;pour aligner les instructions * J'ai des problemes pour aligner

        call    Blank
;                                       ##GIL END##     
        lea     edi,[ebp].opcode_text
        call    WriteAsciiz
        call    NewLine
        ret
WriteInstr      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteCpuReg
;
;               DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg     Proc near
        call WriteInstr
        ret
WriteCpuReg     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteRegs_
;
;               DESCRIPTION:    Write CPU registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _WriteRegs

_WriteRegs       Proc near
        push ebp
        mov ebp,esp
        pushad
        mov ebp,[ebp+8]
;
        call WriteCpuReg
;
        popad
        pop ebp
        ret 4
_WriteRegs       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;        NAME:           _FormatFpuReg
;
;       DESCRIPTION:    Create string for FPU register
;
;       PARAMETERS:     Fpu reg
;                       String (36+ byte long)
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _FormatFpuReg

_FormatFpuReg Proc near
    push ebp
    mov ebp,esp
    pushad
;        
    mov esi,[ebp+8]
    mov edi,[ebp+12]
;        
    finit
    fld tbyte ptr [esi]
;
    push edi        
    mov al,' '
    mov ecx,35
    rep stosb
    xor al,al
    stosb
    pop edi
;        
    mov ecx,35
    mov dl,18
    call FloatToString
;    
    popad
    pop ebp
    ret 8
_FormatFpuReg Endp

        END
