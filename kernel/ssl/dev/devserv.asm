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

MAX_CONN_COUNT = 128
MAX_LISTEN_COUNT = 16

data    SEGMENT byte public 'DATA'

ssl_msg_sel        DW ?
listen_arr         DW MAX_LISTEN_COUNT DUP(?)
conn_arr           DW MAX_CONN_COUNT DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code
    
    extern CreateConnection:near
    extern DeleteConnection:near
    extern CreateListen:near
    extern DeleteListen:near
    extern CopyToBuffer:near
    extern CopyFromBuffer:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetConnSel
;
;       DESCRIPTION:    Get connection sel
;
;       PARAMETERS:     EBX              Connection index
;
;       RETURNS:        DS               Connection sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetConnSel

GetConnSel   Proc near
    push eax
    push ebx
;
    or ebx,ebx
    stc
    jz gcsDone
;
    dec ebx
    mov eax,SEG data
    mov ds,eax
    mov bx,ds:[2*ebx].conn_arr
    or bx,bx
    clc
    jnz gcsDone
;
    stc

gcsDone:
    mov ds,ebx
;
    pop ebx
    pop eax
    ret
GetConnSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetListenSel
;
;       DESCRIPTION:    Get listen sel
;
;       PARAMETERS:     EBX              Listen index
;
;       RETURNS:        DS               Listen sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetListenSel

GetListenSel   Proc near
    push eax
    push ebx
;
    or ebx,ebx
    stc
    jz gclDone
;
    dec ebx
    mov eax,SEG data
    mov ds,eax
    mov bx,ds:[2*ebx].listen_arr
    clc

gclDone:
    mov ds,ebx
;
    pop ebx
    pop eax
    ret
GetListenSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SslServer
;
;       DESCRIPTION:    SSL server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lpname DB 'sslserv', 0
lpcmd  DB 0

SslServer:
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET lpcmd
    mov edi,OFFSET lpname
    mov ax,4
    xor bx,bx
    LoadServer

ssLoop:
    mov ax,250
    WaitMilliSec
    jmp ssLoop
;
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LoadSslServer
;
;       DESCRIPTION:    Load SSL server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LoadSslServer

LoadSslServer  Proc near
    push ds
    push es
    pushad
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET SslServer
    mov edi,OFFSET lpname
    mov al,2
    CreateServerProcess
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
    mov es:ssl_cmd_unused_mask,-1
    InitSection es:ssl_req_section
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

    public GetMsgSel

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
    mov ds:ssl_msg_sel,ax
;
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
    lock btr ds:ssl_cmd_free_mask,ecx
    jc gmeOk
    jmp gmeRetry

gmeTryUnused:
    mov ebx,ds:ssl_cmd_unused_mask
    or ebx,ebx
    jz gmeBlock
;
    bsf ecx,ebx
    lock btr ds:ssl_cmd_unused_mask,ecx
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
;       NAME:           AddMsgBuffer
;
;       DESCRIPTION:    Add msg buffer
;
;       PARAMETERS:     DS      Msg sel
;                       ES      Msg buffer
;                       GS:EDI  Data buffer
;                       ECX     Size of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddMsgBuffer

AddMsgBuffer  Proc near
    mov es:reg_buf,edi
    mov es:reg_buf+4,gs
    mov es:reg_size,ecx
    ret
AddMsgBuffer  Endp

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
;       NAME:           data_reply
;
;       DESCRIPTION:    Data reply processing
;
;       PARAMETERS:     ES      Msg buf
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

data_reply  Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    xor ebp,ebp
    mov eax,es
    mov ds,eax
    mov esi,SIZE ssl_reg
    mov ecx,ds:reg_size
    or ecx,ecx
    jz drpDone
;
    lods dword ptr ds:[esi]
    or eax,eax
    jz drpDone
;
    cmp eax,ecx
    jae drpCopy
;
    mov ecx,eax

drpCopy:
    mov ebp,ecx
    les edi,ds:reg_buf
    rep movs byte ptr es:[edi],ds:[esi]

drpDone:
    clc
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
data_reply  Endp

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
r01 DD OFFSET data_reply

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
;       NAME:           ReplySslCmd
;
;       DESCRIPTION:    Reply on SSL run cmd
;
;       PARAMETERS:     EBX        SSL handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_ssl_cmd_name DB 'Reply SSL Cmd', 0

reply_ssl_cmd   Proc far
    push ds
    push es
    pushad
;
    mov es:[edi].reg_op,REPLY_DEFAULT
;
    call GetMsgSel
    mov esi,ds:ssl_cmd_curr
    dec esi
    shl esi,4
    add esi,OFFSET ssl_cmd_arr
    xor bx,bx
    xchg bx,ds:[esi].ssls_thread
    Signal
;
    mov edx,ds:[esi].ssls_server_linear
    mov eax,ds:[esi].ssls_phys
    mov ebx,ds:[esi].ssls_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov es,cx
    add edx,es:flat_base
    SetPageEntry

rfcDone:
    popad
    pop es
    pop ds
    ret
reply_ssl_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReplySslDataCmd
;
;       DESCRIPTION:    Reply on SSL data cmd
;
;       PARAMETERS:     EBX        SSL handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_ssl_data_cmd_name DB 'Reply SSL Data Cmd', 0

reply_ssl_data_cmd   Proc far
    push ds
    push es
    pushad
;
    mov es:[edi].reg_op,REPLY_DATA
;
    call GetMsgSel
    mov esi,ds:ssl_cmd_curr
    dec esi
    shl esi,4
    add esi,OFFSET ssl_cmd_arr
    xor bx,bx
    xchg bx,ds:[esi].ssls_thread
    Signal
;
    mov edx,ds:[esi].ssls_server_linear
    mov eax,ds:[esi].ssls_phys
    mov ebx,ds:[esi].ssls_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov es,cx
    add edx,es:flat_base
    SetPageEntry
;
    popad
    pop es
    pop ds
    ret
reply_ssl_data_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateSslConnection
;
;       DESCRIPTION:    Create SSL connection
;
;       PARAMETERS:     EBX              Connection index
;                       EDX              IP
;                       SI               Local port
;                       DI               Remote port
;                       ECX              Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_ssl_conn_name DB 'Create SSL Connection', 0

create_ssl_conn   Proc far
    push ds
    push eax
    push ebx
    push edx
;
    or ebx,ebx
    jz cscDone
;    
    cmp ebx,MAX_CONN_COUNT
    ja cscDone
;
    dec ebx
    call CreateConnection
    mov edx,ds
    mov eax,SEG data
    mov ds,eax
    mov ds:[2*ebx].conn_arr,dx

cscDone:
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
create_ssl_conn  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteSslConnection
;
;       DESCRIPTION:    Delete SSL connection
;
;       PARAMETERS:     EBX              Connection index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_ssl_conn_name DB 'Delete SSL Connection', 0

delete_ssl_conn   Proc far
    push ds
    push eax
    push ebx
;
    or ebx,ebx
    jz dscDone
;
    dec ebx
    mov eax,SEG data
    mov ds,eax
    xor ax,ax
    xchg ax,ds:[2*ebx].conn_arr
    or ax,ax
    jz dscDone
;
    mov ds,ax
    call DeleteConnection

dscDone:
    pop ebx
    pop eax
    pop ds
    ret
delete_ssl_conn  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SslStart
;
;       DESCRIPTION:    Start SSL handler
;
;       PARAMETERS:     EBX            Connection Index
;                       EAX            Socket handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handler_start_name DB 'SSL Handler Start', 0

handler_start   PROC far
    push ds
    push eax
    push ebx
;
    call GetConnSel
    jc hsDone
;
    mov ebx,eax
    StartTcpConnectionNotify
;
    mov ds:sc_socket_handle,ax
    GetThread
    mov ds:sc_server,ax

hsDone:
    pop ebx
    pop eax
    pop ds
    ret
handler_start   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SslStop
;
;       DESCRIPTION:    Stop SSL handler
;
;       PARAMETERS:     EBX            Connection Index
;                       EAX            Socket handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handler_stop_name DB 'SSL Handler Stop', 0

handler_stop   PROC far
    push ds
    push ebx
;
    call GetConnSel
    jc heDone
;
    mov ebx,eax
    StopTcpConnectionNotify
;
    mov ds:sc_server,0
    mov ds:sc_active,0
    mov ds:sc_closed,1
    mov ds:sc_socket_handle,0
;
    mov bx,ds:sc_wait_rec
    or bx,bx
    jz heDone
;
    push es
    mov es,ebx
    SignalWait
    pop es
    
heDone:
    pop ebx
    pop ds
    ret
handler_stop   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitStart
;
;       DESCRIPTION:    Start initialization process
;
;       PARAMETERS:     EBX            Connection Index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_start_name DB 'SSL Init Start', 0

init_start   PROC far
    push ds
;
    call GetConnSel
    jc isDone
;
    mov ds:sc_active,0

isDone:
    pop ds
    ret
init_start   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitDone
;
;       DESCRIPTION:    Initialization process done
;
;       PARAMETERS:     EBX            Connection Index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_done_name DB 'SSL Init Done', 0

init_done   PROC far
    push ds
    push ebx
;
    call GetConnSel
    jc idDone
;
    mov ds:sc_active,1
    mov bx,ds:sc_wait_conn
    or bx,bx
    jz idDone
;
    Signal

idDone:
    pop ebx
    pop ds
    ret
init_done   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetReceiveSpace
;
;       DESCRIPTION:    Get space in receive buffer
;
;       PARAMETERS:     EBX            Connection index
;
;       RETURNS:        ECX            Space in receive buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_receive_space_name DB 'SSL Get Receive Space', 0

get_receive_space   PROC far
    push ds
    push ebx
;
    xor ecx,ecx
    call GetConnSel
    jc grsDone
;
    mov cx,ds:sc_buffer_size
    sub cx,ds:sc_receive_count
    movzx ecx,cx

grsDone:
    pop ebx
    pop ds
    ret
get_receive_space   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddReceiveBuf
;
;       DESCRIPTION:    Add data to receive buffer
;
;       PARAMETERS:     EBX            Connection index
;                       ES:EDI         Buffer
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_receive_buf_name DB 'SSL Add Receive Buf', 0

add_receive_buf   PROC far
    push ds
    push fs
    push ebx
    push esi
;
    call GetConnSel
    jc arbDone
;
    mov esi,edi
    EnterSection ds:sc_section
    mov fs,ds:sc_receive_buffer
    add ds:sc_receive_count,cx
    mov bx,ds:sc_receive_tail
    call CopyToBuffer
    mov ds:sc_receive_tail,bx
    LeaveSection ds:sc_section
;
    mov bx,ds:sc_wait_rec
    or bx,bx
    jz arbDone
;
    push es
    mov es,ebx
    SignalWait
    pop es

arbDone:
    pop esi
    pop ebx
    pop fs
    pop ds
    ret
add_receive_buf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSendCount
;
;       DESCRIPTION:    Get bytes in send buffer
;
;       PARAMETERS:     EBX            Connection index
;
;       RETURNS:        ECX            Bytes in send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_send_count_name DB 'SSL Get Send Count', 0

get_send_count   PROC far
    push ds
    push ebx
;
    xor ecx,ecx
    call GetConnSel
    jc gscDone
;
    movzx ecx,ds:sc_send_count

gscDone:
    pop ebx
    pop ds
    ret
get_send_count   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSendBuf
;
;       DESCRIPTION:    Get send buffer size
;
;       PARAMETERS:     EBX            Connection index
;                       ES:EDI         Buffer
;
;       RETURNS:        ECX            Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_send_buf_name DB 'SSL Get Send Buf', 0

get_send_buf   PROC far
    push ds
    push fs
    push eax
    push ebx
    push edi
;
    xor ecx,ecx
    call GetConnSel
    jc gsbDone
;
    movzx ecx,ds:sc_send_count
    or ecx,ecx
    jz gsbDone
;
    EnterSection ds:sc_section
    mov fs,ds:sc_send_buffer
    mov bx,ds:sc_send_head
    call CopyFromBuffer
    LeaveSection ds:sc_section

gsbDone:
    pop edi
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
get_send_buf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ClearSendCount
;
;       DESCRIPTION:    Remove bytes in send buffer
;
;       PARAMETERS:     EBX            Connection index
;                       ECX            Bytes to remove from send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_send_count_name DB 'SSL Clear Send Count', 0

clear_send_count   PROC far
    push ds
    push ebx
;
    call GetConnSel
    jc clscDone
;
    EnterSection ds:sc_section
    sub ds:sc_send_count,cx
    mov bx,ds:sc_send_head
    add bx,cx
;
    cmp bx,ds:sc_buffer_size
    jb clscSave
;
    sub bx,ds:sc_buffer_size

clscSave:
    mov ds:sc_send_head,bx
    LeaveSection ds:sc_section

clscDone:
    pop ebx
    pop ds
    ret
clear_send_count   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForChange
;
;       DESCRIPTION:    Wait for connection change
;
;       PARAMETERS:     EBX            Connection Index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_change_name DB 'SSL Wait For Change', 0

wait_for_change   PROC far
    push ds
    push eax
    push ebx
;
    call GetConnSel
    jc wafcDone
;
    mov bx,ds:sc_send_count
    or bx,bx
    jnz wafcDone
;
    mov bx,ds:sc_socket_handle
    PollTcpConnection
    or ax,ax
    jnz wafcDone
;
    WaitForSignal

wafcDone:
    pop ebx
    pop eax
    pop ds
    ret
wait_for_change   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateSslListen
;
;       DESCRIPTION:    Create SSL listen
;
;       PARAMETERS:     EBX              Listen index
;                       SI               Port
;                       ECX              Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_ssl_listen_name DB 'Create SSL Listen', 0

create_ssl_listen   Proc far
    push ds
    push eax
    push ebx
    push edx
;
    or ebx,ebx
    jz cscDone
;    
    cmp ebx,MAX_LISTEN_COUNT
    ja cslDone
;
    dec ebx
    call CreateListen
    mov edx,ds
    mov eax,SEG data
    mov ds,eax
    mov ds:[2*ebx].listen_arr,dx

cslDone:
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
create_ssl_listen  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteSslListen
;
;       DESCRIPTION:    Delete SSL listen
;
;       PARAMETERS:     EBX              Listen index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_ssl_listen_name DB 'Delete SSL Listen', 0

delete_ssl_listen   Proc far
    push ds
    push eax
    push ebx
;
    or ebx,ebx
    jz dslDone
;
    dec ebx
    mov eax,SEG data
    mov ds,eax
    xor ax,ax
    xchg ax,ds:[2*ebx].listen_arr
    or ax,ax
    jz dslDone
;
    mov ds,ax
    call DeleteListen

dslDone:
    pop ebx
    pop eax
    pop ds
    ret
delete_ssl_listen  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddSslListen
;
;       DESCRIPTION:    Add SSL listen
;
;       PARAMETERS:     EBX              Listen index
;                       EAX              Connection entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_ssl_listen_name DB 'Add SSL Listen', 0

add_ssl_listen   Proc far
    push ds
    push es
    push ebx
    push edx
;
    or ebx,ebx
    jz aslDone
;
    or eax,eax
    jz aslDone
;
    dec ebx
    dec eax
    mov edx,SEG data
    mov ds,edx
    mov dx,ds:[2*ebx].listen_arr
    or dx,dx
    jz aslDone
;
    mov ds,dx
    EnterSection ds:sl_section
    bts ds:sl_pend_mask,eax
    jc aslLeave
;
    inc ds:sl_pend_count

aslLeave:
    LeaveSection ds:sl_section
;
    mov dx,ds:sl_wait
    or dx,dx
    jz aslDone
;
    mov es,edx
    SignalWait

aslDone:
    pop edx
    pop ebx
    pop es
    pop ds
    ret
add_ssl_listen  Endp

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
    mov es:ssl_msg_sel,0
;
    mov edi,OFFSET conn_arr
    mov ecx,MAX_CONN_COUNT
    xor ax,ax
    rep stosw
;
    mov edi,OFFSET listen_arr
    mov ecx,MAX_LISTEN_COUNT
    xor ax,ax
    rep stosw
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
;
    mov esi,OFFSET reply_ssl_cmd
    mov edi,OFFSET reply_ssl_cmd_name
    xor cl,cl
    mov ax,reply_ssl_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET reply_ssl_data_cmd
    mov edi,OFFSET reply_ssl_data_cmd_name
    xor cl,cl
    mov ax,reply_ssl_data_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET create_ssl_conn
    mov edi,OFFSET create_ssl_conn_name
    xor cl,cl
    mov ax,create_ssl_conn_nr
    RegisterServGate
;
    mov esi,OFFSET delete_ssl_conn
    mov edi,OFFSET delete_ssl_conn_name
    xor cl,cl
    mov ax,delete_ssl_conn_nr
    RegisterServGate
;
    mov esi,OFFSET handler_start
    mov edi,OFFSET handler_start_name
    xor cl,cl
    mov ax,ssl_start_nr
    RegisterServGate
;
    mov esi,OFFSET handler_stop
    mov edi,OFFSET handler_stop_name
    xor cl,cl
    mov ax,ssl_stop_nr
    RegisterServGate
;
    mov esi,OFFSET init_start
    mov edi,OFFSET init_start_name
    xor cl,cl
    mov ax,ssl_init_start_nr
    RegisterServGate
;
    mov esi,OFFSET init_done
    mov edi,OFFSET init_done_name
    xor cl,cl
    mov ax,ssl_init_done_nr
    RegisterServGate
;
    mov esi,OFFSET get_receive_space
    mov edi,OFFSET get_receive_space_name
    xor cl,cl
    mov ax,ssl_get_receive_space_nr
    RegisterServGate
;
    mov esi,OFFSET add_receive_buf
    mov edi,OFFSET add_receive_buf_name
    xor cl,cl
    mov ax,ssl_add_receive_buf_nr
    RegisterServGate
;
    mov esi,OFFSET get_send_count
    mov edi,OFFSET get_send_count_name
    xor cl,cl
    mov ax,ssl_get_send_count_nr
    RegisterServGate
;
    mov esi,OFFSET get_send_buf
    mov edi,OFFSET get_send_buf_name
    xor cl,cl
    mov ax,ssl_get_send_buf_nr
    RegisterServGate
;
    mov esi,OFFSET clear_send_count
    mov edi,OFFSET clear_send_count_name
    xor cl,cl
    mov ax,ssl_clear_send_count_nr
    RegisterServGate
;
    mov esi,OFFSET wait_for_change
    mov edi,OFFSET wait_for_change_name
    xor cl,cl
    mov ax,ssl_wait_for_change_nr
    RegisterServGate
;
    mov esi,OFFSET create_ssl_listen
    mov edi,OFFSET create_ssl_listen_name
    xor cl,cl
    mov ax,create_ssl_listen_nr
    RegisterServGate
;
    mov esi,OFFSET delete_ssl_listen
    mov edi,OFFSET delete_ssl_listen_name
    xor cl,cl
    mov ax,delete_ssl_listen_nr
    RegisterServGate
;
    mov esi,OFFSET add_ssl_listen
    mov edi,OFFSET add_ssl_listen_name
    xor cl,cl
    mov ax,add_ssl_listen_nr
    RegisterServGate
    ret
init_server    Endp

code    ENDS

    END
