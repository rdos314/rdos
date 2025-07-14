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
; sslbase.ASM
; Basic ssl server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\serv.def
include ..\serv.inc
include ..\user.def
include ..\user.inc

.386p

ssl_cmd_struc   STRUC

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

ssl_cmd_struc   ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

_TEXT   segment use32 word public 'CODE'

    assume  cs:_TEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalOpenSession
;
;       DESCRIPTION:    open session
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern OpenSession:near

LocalOpenSession Proc near
    call OpenSession
    mov [edi].fc_ebx,ebx
    or ebx,ebx
    jz osReply
;
    and [edi].fc_eflags,NOT 1

osReply:
    mov ebx,[edi].fc_handle
    ReplySslCmd
    ret
LocalOpenSession Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalCloseSession
;
;       DESCRIPTION:    close session
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern CloseSession:near

LocalCloseSession Proc near
    call CloseSession
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1
    ReplySslCmd
    ret
LocalCloseSession Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalOpenConnection
;
;       DESCRIPTION:    open connection
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern OpenConnection:near

LocalOpenConnection Proc near
    push edi
    mov edi,[edi].fc_edi
    call OpenConnection
    pop edi
;
    mov [edi].fc_ebx,ebx
    or ebx,ebx
    jz ocReply
;
    and [edi].fc_eflags,NOT 1

ocReply:
    mov ebx,[edi].fc_handle
    ReplySslCmd
    ret
LocalOpenConnection Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalCloseConnection
;
;       DESCRIPTION:    close connection
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern CloseConnection:near

LocalCloseConnection Proc near
    call CloseConnection
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1
    ReplySslCmd
    ret
LocalCloseConnection Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalPushConnection
;
;       DESCRIPTION:    Push connection
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern PushConnection:near

LocalPushConnection Proc near
    call PushConnection
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1
    ReplySslCmd
    ret
LocalPushConnection Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalOpenServer
;
;       DESCRIPTION:    open server
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern OpenServer:near

LocalOpenServer Proc near
    call OpenServer
;
    mov [edi].fc_ebx,ebx
    or ebx,ebx
    jz osrvReply
;
    and [edi].fc_eflags,NOT 1

osrvReply:
    mov ebx,[edi].fc_handle
    ReplySslCmd
    ret
LocalOpenServer Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalCloseServer
;
;       DESCRIPTION:    close server
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern CloseServer:near

LocalCloseServer Proc near
    call CloseServer
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1
    ReplySslCmd
    ret
LocalCloseServer Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalAcceptServer
;
;       DESCRIPTION:    Accept server socket
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern AcceptServer:near

LocalAcceptServer Proc near
    call AcceptServer
;
    mov [edi].fc_ebx,ebx
    or ebx,ebx
    jz asrvReply
;
    and [edi].fc_eflags,NOT 1

asrvReply:
    mov ebx,[edi].fc_handle
    ReplySslCmd
    ret
LocalAcceptServer Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalSetServerCert
;
;       DESCRIPTION:    Set server certificate
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern SetServerCert:near

LocalSetServerCert Proc near
    push esi
    push edi
;
    add edi,SIZE ssl_cmd_struc
    add esi,edi
    add edx,edi
    call SetServerCert
;
    pop edi
    pop esi
;
    and [edi].fc_eflags,NOT 1
;
    mov ebx,[edi].fc_handle
    ReplySslCmd
    ret
LocalSetServerCert Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalGetConnectionCert
;
;       DESCRIPTION:    Get connection certificate
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern GetConnectionCert:near

LocalGetConnectionCert Proc near
    push edi
    add edi,SIZE ssl_cmd_struc
    add edi,4
    mov ecx,1000h - SIZE ssl_cmd_struc - 5
    call GetConnectionCert
    pop edi
;
    or eax,eax
    jz gccFail
;
    push edi
    add edi,SIZE ssl_cmd_struc
    stosd
    pop edi
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1
    ReplySslDataCmd
    ret

gccFail:
    mov ebx,[edi].fc_handle
    ReplySslCmd
    ret
LocalGetConnectionCert Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalGetCertJson
;
;       DESCRIPTION:    Get certificate in JSON format
;
;       PARAMETERS:     EDI         Msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern GetCertJson:near

LocalGetCertJson Proc near
    push esi
    push edi
    mov eax,[edi].fc_eax
    add edi,SIZE ssl_cmd_struc
    mov esi,edi
    add edi,4
    mov ecx,1000h - SIZE ssl_cmd_struc - 5
    call GetCertJson
    pop edi
    pop esi
;
    or eax,eax
    jz gcjFail
;
    push edi
    add edi,SIZE ssl_cmd_struc
    stosd
    pop edi
;
    mov ebx,[edi].fc_handle
    and [edi].fc_eflags,NOT 1
    ReplySslDataCmd
    ret

gcjFail:
    mov ebx,[edi].fc_handle
    ReplySslCmd
    ret
LocalGetCertJson Endp

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
m00 DD OFFSET LocalOpenSession
m01 DD OFFSET LocalCloseSession
m02 DD OFFSET LocalOpenConnection
m03 DD OFFSET LocalCloseConnection
m04 DD OFFSET LocalPushConnection
m05 DD OFFSET LocalOpenServer
m06 DD OFFSET LocalCloseServer
m07 DD OFFSET LocalAcceptServer
m08 DD OFFSET LocalSetServerCert
m09 DD OFFSET LocalGetConnectionCert
m0A DD OFFSET LocalGetCertJson

WaitForMsg_    Proc near
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    xor eax,eax
    WaitForSslCmd
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
