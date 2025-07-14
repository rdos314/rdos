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
; futex.asm
; Futex interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include \rdos\kernel\user.def
include \rdos\kernel\user.inc
include \rdos\kernel\os\system.def

.386p

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

_TEXT   segment use32 word public 'CODE'

    assume  cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitFutex
;
;       DESCRIPTION:    Init futex object
;
;       PARAMETERS:     EBX           Futex object
;                       EDI           Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitFutex

InitFutex Proc near
    mov [ebx].fs_handle,0
    mov [ebx].fs_val,-1
    mov [ebx].fs_counter,0
    mov [ebx].fs_owner,0
    mov [ebx].fs_sect_name,edi
    ret
InitFutex Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EnterFutex
;
;       DESCRIPTION:    Enter futex object
;
;       PARAMETERS:     EBX           Futex object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public EnterFutex

EnterFutex Proc near
    push eax
;    
    str ax
    cmp ax,[ebx].fs_owner
    jne efLock
;
    inc [ebx].fs_counter
    jmp efDone

efLock:
    lock add [ebx].fs_val,1
    jc efTake
;
    mov eax,1
    xchg ax,[ebx].fs_val
    cmp ax,-1
    jne efBlock

efTake:
    str ax
    mov [ebx].fs_owner,ax
    mov [ebx].fs_counter,1
    jmp efDone

efBlock:
    push edi
    mov edi,[ebx].fs_sect_name
    UserGateApp acquire_named_futex_nr
    pop edi

efDone:
    pop eax    
    ret
EnterFutex Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LeaveFutex
;
;       DESCRIPTION:    Leave futex object
;
;       PARAMETERS:     EBX           Futex object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LeaveFutex

LeaveFutex Proc near
    push eax
;
    str ax
    cmp ax,[ebx].fs_owner
    jne lfDone
;
    sub [ebx].fs_counter,1
    jnz lfDone
;
    mov [ebx].fs_owner,0
    lock sub [ebx].fs_val,1
    jc lfDone
;
    mov [ebx].fs_val,-1
    UserGateApp release_futex_nr

lfDone:
    pop ebx
    ret
LeaveFutex Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ResetFutex
;
;       DESCRIPTION:    Reset futex object
;
;       PARAMETERS:     EBX           Futex object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ResetFutex

ResetFutex Proc near
    push eax
;
    mov eax,[ebx].fs_handle
    or eax,eax
    jz rfDone
;    
    UserGateApp cleanup_futex_nr

rfDone:
    pop eax
    ret
ResetFutex Endp

_TEXT   ends

    END
