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
fc_handle          DD ?
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
;       NAME:           GetFreeSectors
;
;       DESCRIPTION:    Get free sectors
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowGetFreeSectors:near

GetFreeSectors Proc near
    push edi
    call LowGetFreeSectors
    pop edi
;
    mov [edi].fc_eax,eax
    mov [edi].fc_edx,edx
    and [edi].fc_eflags,NOT 1
;
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
GetFreeSectors Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDir
;
;       DESCRIPTION:    Get dir
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowGetDir:near
    extern LowGetDirHeaderSize:near

GetDir Proc near
    push edi
    mov eax,[edi].fc_eax
    add edi,SIZE vfs_cmd_struc
    push ecx
    mov esi,esp
    call LowGetDir
    pop ecx
    pop edi
;
    or edx,edx
    jz gdFail
;
    mov [edi].fc_ecx,ecx
    and [edi].fc_eflags,NOT 1
;
    push edi
    call LowGetDirHeaderSize
    pop edi
    mov [edi].fc_eax,eax
;
    mov ebx,[edi].fc_handle
    ReplyVfsBlockCmd
    ret

gdFail:
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
GetDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDirEntryAttrib
;
;       DESCRIPTION:    Get dir entry attrib
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowGetDirEntryAttrib:near

GetDirEntryAttrib Proc near
    push edi
    mov eax,[edi].fc_eax
    add edi,SIZE vfs_cmd_struc
    push ecx
    mov esi,esp
    call LowGetDirEntryAttrib
    pop ecx
    pop edi
;
    cmp eax,-1
    je gdeaReply
;
    mov [edi].fc_eax,eax
    and [edi].fc_eflags,NOT 1

gdeaReply:
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
GetDirEntryAttrib Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockRelDir
;
;       DESCRIPTION:    Lock rel dir
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowLockRelDir:near

LockRelDir Proc near
    push edi
    mov eax,[edi].fc_eax
    add edi,SIZE vfs_cmd_struc
    push ecx
    mov esi,esp
    call LowLockRelDir
    pop ecx
    pop edi
;
    cmp eax,-1
    je lrdReply
;
    mov [edi].fc_eax,eax
    and [edi].fc_eflags,NOT 1

lrdReply:
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LockRelDir Endp

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

msgtab:
m00 DD OFFSET GetFreeSectors
m01 DD OFFSET GetDir
m02 DD OFFSET GetDirEntryAttrib
m03 DD OFFSET LockRelDir

WaitForMsg_    Proc near
    pushad

wfmLoop:
    push ebx
    WaitForVfsCmd
    jc wfmDone
;
    mov edi,edx
    mov [edi].fc_handle,ebx
    mov eax,[edi].fc_eax
    mov ebx,[edi].fc_ebx
    mov ecx,[edi].fc_ecx
    mov esi,[edi].fc_esi
    mov ebp,[edi].fc_op
    mov edx,[edi].fc_edx
    shl ebp,2
    call dword ptr [ebp].msgtab
    jmp wfmLoop

wfmDone:
    pop ebx
;
    popad
    ret
WaitForMsg_    Endp

_TEXT   ends

    END
