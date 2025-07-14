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
; partbase.ASM
; Basic partition server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include \rdos\kernel\serv.def
include \rdos\kernel\serv.inc
include \rdos\kernel\user.def
include \rdos\kernel\user.inc

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

    extern LowLockDirLink:near
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
    call LowLockDirLink
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
    mov bx,[edi].dl_wait_handle
    or bx,bx
    jnz ldlDoWait
;
    lock sub [edi].dl_wait_count,1
    jc ldlWaitCreate
;
    lock inc [edi].dl_wait_count
;
    mov ax,1
    WaitMilliSec
    jmp ldlRetry

ldlWaitCreate:
    push edi
    mov edi,OFFSET wait_name
    CreateThreadBlock
    pop edi
    mov [edi].dl_wait_handle,bx
;
    lock inc [edi].dl_wait_count

ldlDoWait:
    WaitThreadBlock
    jmp ldlRetry

ldlDone:
    lock inc [edi].dl_ref_count
;
    pop ebx
    pop eax
    ret
LockDirLinkObject_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockDirLinkObject
;
;       DESCRIPTION:    Unlock dir link object
;
;       PARAMETERS:     ESI           Dir object
;                       EDI           Link object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowUnlockDirLink:near

    public UnlockDirLinkObject_

UnlockDirLinkObject_ Proc near
    lock sub [edi].dl_ref_count,1
    jnz udlDone
;
    call LowUnlockDirLink

udlDone:
    ret
UnlockDirLinkObject_ Endp

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
;       NAME:           LocalOpenFile
;
;       DESCRIPTION:    Open file
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowOpenFile:near
    extern LowGetFileHandle:near
    extern LowGetFileAttrib:near

LocalOpenFile Proc near
    push edi
    mov eax,[edi].fc_eax
    add edi,SIZE vfs_cmd_struc
    push ecx
    mov esi,esp
    call LowOpenFile
    pop ecx
    pop edi
;
    cmp eax,-1
    je ofDone
;
    mov [edi].fc_eax,eax
;
    push edi
    call LowGetFileAttrib
    pop edi
    mov [edi].fc_ecx,eax
;
    mov eax,[edi].fc_eax
    push edi
    call LowGetFileHandle
    pop edi
    mov [edi].fc_ebx,eax
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1

ofDone:
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalOpenFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalCreateFile
;
;       DESCRIPTION:    Create file
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowCreateFile:near

LocalCreateFile Proc near
    push edi
    mov eax,[edi].fc_eax
    mov ecx,[edi].fc_ecx
    add edi,SIZE vfs_cmd_struc
    push ecx
    mov esi,esp
    call LowCreateFile
    pop ecx
    pop edi
;
    cmp eax,-1
    je cfDone
;
    mov [edi].fc_eax,eax
;
    push edi
    call LowGetFileHandle
    pop edi
    mov [edi].fc_ebx,eax
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1

cfDone:
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalCreateFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalCloseFile
;
;       DESCRIPTION:    Close file
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowCloseFile:near

LocalCloseFile Proc near
    push edi
    mov esi,[edi].fc_handle
    call LowCloseFile
    pop edi
;
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalCloseFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalDerefFile
;
;       DESCRIPTION:    Deref file
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowDerefFile:near

LocalDerefFile Proc near
    push edi
    mov esi,[edi].fc_handle
    call LowDerefFile
    pop edi
;
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalDerefFile Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalStart
;
;       DESCRIPTION:    Start partition
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowStart:near

LocalStart Proc near
    call LowStart
;
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalStart Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalStop
;
;       DESCRIPTION:    Stop partition
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowStop:near

LocalStop Proc near
    call LowStop
;
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalStop Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalFormat
;
;       DESCRIPTION:    Format partition
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   extern LowFormat:near

LocalFormat Proc near
    call LowFormat
;
    mov [edi].fc_eax,eax
    or eax,eax
    jz lfReply
;
    and [edi].fc_eflags,NOT 1

lfReply:
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalFormat Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalCreateDir
;
;       DESCRIPTION:    Create dir
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowCreateDir:near

LocalCreateDir Proc near
    push edi
    mov eax,[edi].fc_eax
    add edi,SIZE vfs_cmd_struc
    call LowCreateDir
    pop edi
;
    or eax,eax
    je cdDone
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1

cdDone:
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalCreateDir Endp

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
m00 DD OFFSET LocalStart
m01 DD OFFSET LocalStop
m02 DD OFFSET GetFreeSectors
m03 DD OFFSET GetDir
m04 DD OFFSET GetDirEntryAttrib
m05 DD OFFSET LockRelDir
m06 DD OFFSET CloneRelDir
m07 DD OFFSET UnlockRelDir
m08 DD OFFSET GetRelDir
m09 DD OFFSET LocalOpenFile
m10 DD OFFSET LocalDerefFile
m11 DD OFFSET LocalCloseFile
m12 DD OFFSET LocalFormat
m13 DD OFFSET LocalCreateDir
m14 DD OFFSET LocalCreateFile

WaitForMsg_    Proc near
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    xor eax,eax
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
    mov eax,1

wfmDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
WaitForMsg_    Endp

_TEXT   ends

    END
