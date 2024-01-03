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
; DEVSERV.ASM
; SSL server part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\serv.def
include ..\serv.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include ..\os\protseg.def
include ..\fs.inc
include ..\os\exec.def
include ssl.inc

    .386p

REPLY_DEFAULT      = 0
REPLY_BLOCK        = 1
REPLY_DATA         = 2

data    SEGMENT byte public 'DATA'

ssl_serv_handle    DW ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LoadSslServer
;
;       DESCRIPTION:    Load SSL server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lpname DB 'sslserv', 0
lpcmd  DB 0

    public LoadSslServer

LoadSslServer  Proc near
    push ds
    push es
    push fs
    push eax
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET lpcmd
    mov edi,OFFSET lpname
    mov ax,4
    xor bx,bx
    LoadServer
;
    mov eax,SEG data
    mov ds,eax
    mov ds:ssl_serv_handle,bx
;
    pop eax
    pop fs
    pop es
    pop ds
    ret
LoadSslServer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForVfsCmd
;
;       DESCRIPTION:    Wait for VFS cmd
;
;       PARAMETERS:     EBX        SSL handle
;
;       RETURNS:        EDX        Msg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_ssl_cmd_name DB 'Wait For SSL Cmd', 0

wait_for_ssl_cmd   Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    stc
;    call HandleToPartEs
    jc wfcDone
;
    mov ax,es
    mov ds,ax
;
    GetThread
    mov ds:ssl_cmd_thread,ax
    jmp wfcCheck

wfcRetry:
    WaitForSignal

wfcCheck:
    movzx ebx,ds:ssl_cmd_head
    mov al,ds:[ebx].ssl_cmd_ring
    cmp bl,ds:ssl_cmd_tail
    je wfcRetry
;
    inc bl
    cmp bl,34
    jb wfcSaveHead
;
    xor bl,bl

wfcSaveHead:
    mov ds:ssl_cmd_head,bl
;
    movzx ebx,al
    mov ds:ssl_cmd_curr,ebx
    dec ebx
    shl ebx,4
    add ebx,OFFSET ssl_cmd_arr
    mov edx,ds:[ebx].ssls_server_linear
    or edx,edx
    jnz wfcMap
;
    mov eax,1000h
    AllocateLocalLinear
    mov ds:[ebx].ssls_server_linear,edx

wfcMap:
    push ds
    push edx
;
    mov eax,[ebx].ssls_phys
    mov ebx,[ebx].ssls_phys+4
    or ax,867h
;
    mov cx,system_data_sel
    mov ds,cx
    add edx,ds:flat_base
    SetPageEntry
;
    pop edx
    pop ds
    clc

wfcDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
wait_for_ssl_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_server
;
;       description:    Init server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_server

init_server    Proc near
    mov eax,SEG data
    mov es,eax
    mov es:ssl_serv_handle,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET wait_for_ssl_cmd
    mov edi,OFFSET wait_for_ssl_cmd_name
    xor cl,cl
    mov ax,wait_for_ssl_cmd_nr
    RegisterServGate
    ret
init_server    Endp

code    ENDS

    END
