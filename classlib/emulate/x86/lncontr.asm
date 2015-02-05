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
; LMCONTR.ASM
; Control transfer emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

include \rdos\classlib\emulate\x86\emulate.inc
include \rdos\classlib\emulate\x86\emcom.inc
include \rdos\classlib\emulate\x86\emmem.inc
include \rdos\classlib\emulate\x86\emseg.inc

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           JccShort
;
;   DESCRIPTION:    Emulate jcc short
;
;   PARAMETERS:     SS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JccShort        Macro op

        public Long&op&Short

Long&op&Short     Proc near
        mov ah,byte ptr [ebp].reg_eflags
        sahf
        &op Long&op&ShortJump
        call ReadLongCodeByte
        ret

Long&op&ShortJump:
        call ReadLongCodeByte
        movsx eax,al
        xor edx,edx
        mov ebx,eax
        rcl ebx,1
        sbb edx,0
        add [ebp].reg_eip,eax
        adc [ebp].reg_eip+4,edx
        ret
Long&op&Short     Endp

                Endm
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmJccShort
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

        END
