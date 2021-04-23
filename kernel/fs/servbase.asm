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
; VFS.ASM
; Virtual file system
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\serv.def
include ..\serv.inc
include ..\user.def
include ..\user.inc

.386p

vfs_cmd_struc   STRUC

fc_op              DD ?

fc_eflags          DD ?
fc_eax             DD ?
fc_ebx             DD ?
fc_ecx             DD ?
fc_edx             DD ?
fc_esi             DD ?
fc_edi             DD ?

vfs_cmd_struc   ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

_TEXT   segment use32 word public 'CODE'

    assume  cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForMsg
;
;       DESCRIPTION:    Wait for msg
;
;       PARAMETERS:     EBX     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WaitForMsg_

    extern LowGetFreeSectors:near

msgtab:
m00 DD OFFSET LowGetFreeSectors

WaitForMsg_    Proc near
    pushad

wfmLoop:
    push ebx
    WaitForVfsCmd
    jc wfmDone
;
    push edx
;
    mov eax,[edx].fc_eax
    mov ebx,[edx].fc_ebx
    mov ecx,[edx].fc_ecx
    mov esi,[edx].fc_esi
    mov edi,[edx].fc_edi
    mov ebp,[edx].fc_op
    mov edx,[edx].fc_edx
    shl ebp,2
    call dword ptr [ebp].msgtab
    mov ebp,edx
;
    pop edx
;
    mov [edx].fc_eax,eax
    mov [edx].fc_ebx,ebx
    mov [edx].fc_ecx,ecx
    mov [edx].fc_esi,esi
    mov [edx].fc_edi,edi
    mov [edx].fc_edx,ebp
;
    pop ebx
    ReplyVfsCmd
    jmp wfmLoop

wfmDone:
    pop ebx
;
    popad
    ret
WaitForMsg_    Endp

_TEXT   ends

    END
