;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage in embedded systems. For information on
; usage in commercial embedded systems, contact embedded@rdos.net
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
; futex.asm
; Futex interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\..\kernel\user.def
include ..\..\kernel\user.inc
include ..\..\kernel\os\system.def

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
