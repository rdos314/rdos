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
; discbase.ASM
; Basic disc server
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

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

_TEXT   segment use32 word public 'CODE'

    assume  cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalCmd
;
;       DESCRIPTION:    Run command
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowCmd:near

LocalCmd Proc near
    push edi
    mov ebx,edi
    add edi,SIZE vfs_cmd_struc
    push ecx
    mov esi,esp
    call LowCmd
    pop ecx
    pop edi
;
    mov ebx,[edi].fc_handle
    ReplyVfsPost
    ret
LocalCmd Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalReadSector
;
;       DESCRIPTION:    Read sector
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowReadSector:near

LocalRead Proc near
    push edx
    mov ebx,[edi].fc_handle
    MapVfsCmdBuf
    mov ebx,edx
    pop edx
;
    push ebx
    call LowReadSector
    mov [edi].fc_eax,eax
    pop edx
;
    mov ebx,[edi].fc_handle
    UnmapVfsCmdBuf
;
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalRead Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalWriteSector
;
;       DESCRIPTION:    Write sector
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern LowWriteSector:near

LocalWrite Proc near
    push edx
    mov ebx,[edi].fc_handle
    MapVfsCmdBuf
    mov ebx,edx
    pop edx
;    
    push ebx
    call LowWriteSector
    mov [edi].fc_eax,eax
    pop edx
;
    mov ebx,[edi].fc_handle
    UnmapVfsCmdBuf
;
    mov ebx,[edi].fc_handle
    ReplyVfsCmd
    ret
LocalWrite Endp

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


Unused   Proc near
    ret
Unused   Endp

msgtab:
m00 DD OFFSET Unused
m01 DD OFFSET Unused
m02 DD OFFSET Unused
m03 DD OFFSET Unused
m04 DD OFFSET Unused
m05 DD OFFSET Unused
m06 DD OFFSET Unused
m07 DD OFFSET Unused
m08 DD OFFSET Unused
m09 DD OFFSET Unused
m10 DD OFFSET Unused
m11 DD OFFSET Unused
m12 DD OFFSET Unused
m13 DD OFFSET Unused
m14 DD OFFSET Unused
m15 DD OFFSET LocalCmd
m16 DD OFFSET LocalRead
m17 DD OFFSET LocalWrite

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
