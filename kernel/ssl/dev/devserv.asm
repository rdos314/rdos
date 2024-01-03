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

data    SEGMENT byte public 'DATA'

ssl_serv_handle    DW ?
ssl_msg_sel        DW ?

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

LoadSslServer  Proc near
    push ds
    push es
    pushad
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
    popad
    pop es
    pop ds
    ret
LoadSslServer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateMsgSel
;
;       DESCRIPTION:    Create msg sel
;
;       RETURNS:        AX     MSG sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMsgSel  Proc near
    push es
    push ecx
    push edi
;
    mov eax,SIZE ssl_cmd
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov eax,es
;
    pop edi
    pop ecx
    pop es
    ret
CreateMsgSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMsgSel
;
;       DESCRIPTION:    Get msg sel
;
;       RETURNS:        DS     MSG sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMsgSel  Proc near
    push eax
;
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:ssl_msg_sel
    or ax,ax
    jnz gmsOk
;
    call CreateMsgSel
    call LoadSslServer

gmsOk:
    mov ds,eax
;
    pop eax
    ret
GetMsgSel Endp

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
    call GetMsgSel
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
;       NAME:           GetMsgEntry
;
;       DESCRIPTION:    Get fs msg entry
;
;       PARAMETERS:     DS      Msg sel
;
;       RETURNS:        EBX     FS entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMsgEntry  Proc near
    push ecx

gmeRetry:
    mov ebx,ds:ssl_cmd_free_mask
    or ebx,ebx
    jz gmeTryUnused
;
    bsf ecx,ebx
    lock btc ds:ssl_cmd_free_mask,ecx
    jc gmeOk
    jmp gmeRetry

gmeTryUnused:
    mov ebx,ds:ssl_cmd_unused_mask
    or ebx,ebx
    jz gmeBlock
;
    bsf ecx,ebx
    lock btc ds:ssl_cmd_unused_mask,ecx
    jc gmeAlloc
    jmp gmeRetry

gmeBlock:
    int 3
    jmp gmeRetry

gmeAlloc:
    mov ebx,ecx
    shl ebx,4
    add ebx,OFFSET ssl_cmd_arr
;
    push eax
    push ebx
    push edx
    push edi
;
    mov edi,ebx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov ds:[edi].ssls_phys,eax
    mov ds:[edi].ssls_phys+4,ebx
;
    or al,63h
    SetPageEntry
;    
    mov ecx,1000h
    AllocateGdt
    mov ds:[edi].ssls_sel,bx
    CreateDataSelector32
;
    mov ds:[edi].ssls_server_linear,0
    mov ds:[edi].ssls_thread,0
;
    pop edi
    pop edx
    pop ebx
    pop eax
;
    clc
    jmp gmeDone

gmeFailed:
    stc
    jmp gmeDone

gmeOk:
    mov ebx,ecx
    shl ebx,4
    add ebx,OFFSET ssl_cmd_arr
    clc

gmeDone:
    pop ecx
    ret
GetMsgEntry  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateMsg
;
;       DESCRIPTION:    Allocate msg
;
;       RETURNS:        DS      Msg sel
;                       EBX     Msg entry
;                       ES      Msg buffer
;                       EDI     FS msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateMsg

AllocateMsg  Proc near
    push ebx
;
    call GetMsgSel
    call GetMsgEntry
    jnc amSave
;
    pop ebx
    xor ebx,ebx
    mov es,ebx
    stc
    jmp amDone

amSave:
    mov es,ds:[ebx].ssls_sel
    mov es:reg_size,0
    pop es:reg_ebx
;
    stc
    pushfd
    pop es:reg_eflags
;
    mov es:reg_eax,eax
    mov es:reg_ecx,ecx
    mov es:reg_edx,edx
    mov es:reg_esi,esi
    mov es:reg_edi,edi
;
    mov edi,SIZE ssl_reg
    clc

amDone:
    ret
AllocateMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           no_reply
;
;       DESCRIPTION:    No reply processing
;
;       PARAMETERS:     ES      Msg buf
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

no_reply   Proc near
    xor ebp,ebp
    clc
    ret
no_reply   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunMsg
;
;       DESCRIPTION:    Run ssl msg
;
;       PARAMETERS:     DS      Msg sel
;                       ES      Msg buf
;                       EAX     Op
;                       EBX     Msg entry
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RunMsg

reply_tab:
r00 DD OFFSET no_reply

RunMsg  Proc near
    mov esi,ebx
    mov es:reg_op,eax
;
    GetThread
    mov ds:[esi].ssls_thread,ax
;
    sub ebx,OFFSET ssl_cmd_arr
    shr ebx,4
    mov al,bl
    inc al
;
    movzx ebx,ds:ssl_cmd_tail
    mov ds:[ebx].ssl_cmd_ring,al
    inc bl
    cmp bl,34
    jb rmSaveTail
;
    xor bl,bl

rmSaveTail:
    mov ds:ssl_cmd_tail,bl
;
    mov bx,ds:ssl_cmd_thread
    Signal

rmWait:
    WaitForSignal
;
    mov bx,ds:[esi].ssls_thread
    or bx,bx
    jnz rmWait
;
    mov ebp,es:reg_eax
    mov ebx,es:reg_ebx
    mov ecx,es:reg_ecx
    mov edx,es:reg_edx
    mov esi,es:reg_esi
    mov edi,es:reg_edi
;
    dec al
    movzx eax,al
    push es:reg_eflags
    push ebp
    push eax
;
    xor ebp,ebp
    push es:reg_eflags
    popfd
    jc rmFree
;
    push ebx
    mov ebx,es:reg_op
    shl ebx,2
    call dword ptr cs:[ebx].reply_tab
    pop ebx

rmFree:
    pop eax
    lock bts ds:ssl_cmd_free_mask,eax
;
    pop eax
    popfd

rmDone:
    ret
RunMsg  Endp

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
    mov es:ssl_msg_sel,0
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
