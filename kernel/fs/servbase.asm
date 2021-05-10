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
fc_buf             DD ?,?
fc_size            DD ?
fc_eflags          DD ?
fc_eax             DD ?
fc_ebx             DD ?
fc_ecx             DD ?
fc_edx             DD ?
fc_esi             DD ?
fc_edi             DD ?

vfs_cmd_struc   ENDS

dir_link_struc  STRUC

dl_offset          DD ?
dl_link            DD ?
dl_wait_handle     DW ?
dl_ref_count       DB ?
dl_wait_count      DB ?

dir_link_struc  ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

_TEXT   segment use32 word public 'CODE'

    assume  cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockDirLinkObject
;
;       DESCRIPTION:    Lock dir link object
;
;       PARAMETERS:     ESI           Dir object
;                       EDI           Link object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowReadDirLink:near
    public LockDirLinkObject_

wait_name DB "Wait Dir", 0

LockDirLinkObject_ Proc near
    push eax
    push ebx

ldlRetry:
    test [edi].dl_ref_count,80h
    jnz ldlWait
;
    cmp [edi].dl_link,0
    jnz ldlDone
;
    lock sub [edi].dl_ref_count,1
    jnc ldlLockFailed
;
    call LowReadDirLink
    lock inc [edi].dl_ref_count

ldlWaitLoop:
    cmp [edi].dl_wait_count,0
    je ldlWaitOk
;
    mov ax,1
    WaitMilliSec
    jmp ldlWaitLoop

ldlWaitOk:
    xor bx,bx
    xchg bx,[edi].dl_wait_handle
    or bx,bx
    jz ldlDone
;
    CloseThreadBlock
    jmp ldlDone

ldlLockFailed:
    lock inc [edi].dl_ref_count
    jmp ldlRetry

ldlWait:
    cmp [edi].dl_wait_handle,0
    jnz ldlDoWait
;
    lock sub [edi].dl_wait_count,1
    jnc ldlWaitUnlock
;
    push edi
    mov edi,OFFSET wait_name
    CreateThreadBlock
    pop edi
    mov [edi].dl_wait_handle,bx

ldlWaitUnlock:
    lock inc [edi].dl_wait_count

ldlDoWait:
    mov bx,[edi].dl_wait_handle
    or bx,bx
    jz ldlWaitYield
;
    WaitThreadBlock
    jmp ldlRetry

ldlWaitYield:
    mov ax,1
    WaitMilliSec
    jmp ldlRetry

ldlDone:
    pop ebx
    pop eax
    ret
LockDirLinkObject_ Endp

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
    call LowLockRelDir
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
;       NAME:           CloneRelDir
;
;       DESCRIPTION:    Clone rel dir
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowCloneRelDir:near

CloneRelDir Proc near
    push edi
    mov eax,[edi].fc_eax
    call LowCloneRelDir
    pop edi
;
    and [edi].fc_eflags,NOT 1
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
CloneRelDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockRelDir
;
;       DESCRIPTION:    Unlock rel dir
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowUnlockRelDir:near

UnlockRelDir Proc near
    push edi
    mov eax,[edi].fc_eax
    call LowUnlockRelDir
    pop edi
;
    and [edi].fc_eflags,NOT 1
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
UnlockRelDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetRelDir
;
;       DESCRIPTION:    Get rel dir
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowGetRelDir:near

GetRelDir Proc near
    push edi
    mov eax,[edi].fc_eax
    add edi,SIZE vfs_cmd_struc
    add edi,4
    call LowGetRelDir
    pop edi
;
    push edi
    add edi,SIZE vfs_cmd_struc
    stosd
    pop edi
;
    and [edi].fc_eflags,NOT 1
    mov ebx,[edi].fc_handle
    ReplyVfsDataCmd
    ret
GetRelDir Endp

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
m04 DD OFFSET CloneRelDir
m05 DD OFFSET UnlockRelDir
m06 DD OFFSET GetRelDir

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
