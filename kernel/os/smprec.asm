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
; SMPREC.ASM
; Receiver part of Simple Message Protocol (remote IPC)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE ipc.inc
INCLUDE smp.inc

Reverse MACRO
    xchg al,ah
    rol eax,16
    xchg al,ah
        ENDM

MAX_PENDING_REQUESTS    EQU 16
REORDER_ENTRIES EQU 8

reorder_entry   STRUC

reorder_offset  DD ?
reorder_size    DD ?

reorder_entry   ENDS

rec_list_data   STRUC

l_ml_data               mailslot_list_data <>
l_receive_ip        DD ?
l_connection        DD ?
l_host_entry        DW ?
l_size              DD ?
l_pos               DD ?
l_ack               DD ?
l_reorder_count     DW ?
l_reorder_arr       DD 2 * REORDER_ENTRIES DUP(?)
l_msg               DB ?

rec_list_data   ENDS

rec_host_data   STRUC

h_link              DW ?
h_host              DW ?
h_ip                DD ?
h_mailslot              DW ?
h_req_section       section_typ <>
h_req_unacked       DW ?
h_req_connection    DD ?
h_req_index             DW ?
h_req_arr               DW MAX_PENDING_REQUESTS DUP(?)
h_reply_section     section_typ <>
h_reply_list        DW ?

rec_host_data   ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

    extrn EnterIpcSection:near
    extrn LeaveIpcSection:near
    extrn GetIpcMailslotList:near
    extrn GetSmpThread:near
    extrn CreateSegment:near
    extrn CalcChecksum:near
    extrn SelectorToLinear:near
    extrn QueueTooLarge:near
    extrn CopyToReceiver:near
    extrn QueueReceiveRequest:near
    extrn FindHost:near
    extrn QueueAck:near
    extrn QueueReset:near
    extrn FlushResponses:near

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindReceiveMailslot
;
;       Purpose:        Find request mailslot
;
;       Parameters:         BX          Mailslot 
;
;       Returns:        DS          Mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FindReceiveMailslot

FindReceiveMailslot     Proc near
    push fs
    push ax
    push bx
;
    call EnterIpcSection
    call GetIpcMailslotList

find_rec_mailslot_search:
    or ax,ax
    stc
    jz find_rec_mailslot_leave
;
    cmp ax,bx
    clc
    je find_rec_mailslot_leave
;
    mov fs,ax
    mov ax,fs:m_link
    jmp find_rec_mailslot_search

find_rec_mailslot_leave:
    pushf
    xor ax,ax
    mov fs,ax
    call LeaveIpcSection
    popf
    jc find_rec_mailslot_done
;
    mov ds,bx

find_rec_mailslot_done:
    pop bx
    pop ax
    pop fs
    ret
FindReceiveMailslot     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindReceiveMailslotHost
;
;           DESCRIPTION:    Find a remote mailslot host
;
;           PARAMETERS:         DS          Mailslot
;                           EDX         IP
;
;           RETURNS:        AX          SMP host list selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FindReceiveMailslotHost

FindReceiveMailslotHost Proc near
    push es
    push bx
;
    EnterSection ds:m_host_section
    mov ax,ds:m_host_list

find_rec_mailslot_host_loop:
    or ax,ax
    stc
    jz find_rec_mailslot_host_done
;
    mov es,ax
    cmp edx,es:h_ip
    clc
    je find_rec_mailslot_host_done
;
    mov ax,es:h_link
    jmp find_rec_mailslot_host_loop

find_rec_mailslot_host_done:
    pushf
    xor bx,bx
    mov es,bx
    LeaveSection ds:m_host_section
    popf
;
    pop bx
    pop es
    ret
FindReceiveMailslotHost Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddReceiveMailslotHost
;
;           DESCRIPTION:    Add a receive mailslot host
;
;           PARAMETERS:         DS          Mailslot
;                           FS          Host data selector
;
;           RETURNS:        AX          SMP host list selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReceiveMailslotHost  Proc near
    push es
    push cx
    push edx
    push di
;
    mov eax,SIZE rec_host_data
    AllocateSmallGlobalMem
    mov es:h_host,fs
    mov eax,fs:shd_ip
    mov es:h_ip,eax
    GetSystemTime
    mov es:h_req_connection,eax
    mov es:h_req_index,0
    mov es:h_req_unacked,0
    mov es:h_mailslot,ds
    mov es:h_reply_list,0
    mov di,OFFSET h_req_arr
    mov cx,MAX_PENDING_REQUESTS
    xor ax,ax
    rep stosw       
    push ds
    mov ax,es
    mov ds,ax
    InitSection ds:h_req_section
    InitSection ds:h_reply_section
    pop ds
;    
    EnterSection ds:m_host_section
    mov ax,ds:m_host_list
    mov es:h_link,ax
    mov ds:m_host_list,es
    LeaveSection ds:m_host_section
    mov ax,es
;
    pop di
    pop edx
    pop cx
    pop es
    ret
AddReceiveMailslotHost  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetReceiveMailslotHost
;
;           DESCRIPTION:    Reset a receive mailslot host
;
;           PARAMETERS:         DS          Mailslot
;                           FS          Host data selector
;                           AX          SMP host list selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetReceiveMailslotHost    Proc near
    push ds
    push es
    push eax
    push cx
    push edx
    push di
;
    mov ds,ax
    call FlushResponses
    EnterSection ds:h_req_section
    EnterSection ds:h_reply_section
;
    add ds:h_req_connection,10000h
    mov ds:h_req_index,0
    mov ds:h_req_unacked,0

reset_reply_loop:
    mov ax,ds:h_reply_list
    or ax,ax
    jz reset_reply_ok
;
    mov es,ax
    call DequeueReply
    FreeMem
    jmp reset_reply_loop

reset_reply_ok:
    mov di,OFFSET h_req_arr
    mov cx,MAX_PENDING_REQUESTS

reset_req_loop:
    xor ax,ax
    xchg ax,[di]
    or ax,ax
    jz reset_req_next
;
    mov es,ax
    FreeMem

reset_req_next:
    add di,2
    loop reset_req_loop
;
    LeaveSection ds:h_reply_section
    LeaveSection ds:h_req_section

reset_host_done:
    pop di
    pop edx
    pop cx
    pop eax
    pop es
    pop ds
    ret
ResetReceiveMailslotHost    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetReceiveMailslot
;
;           DESCRIPTION:    Get receiver side mailslot
;
;           PARAMETERS:         EDX             IP address
;       
;           Returns:        EDX             Connection
;                           BX              Mailslot                    
;                           FS              Host list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetReceiveMailslot      Proc near
    push ds
    push es
    push ax
;
    call FindHost
    jc get_mailslot_done
;
    mov fs,ax
    call FindReceiveMailslotHost
    jnc get_mailslot_found
;
    call AddReceiveMailslotHost
    call GetSmpThread
    Signal
    jmp get_mailslot_ok

get_mailslot_found:
    call ResetReceiveMailslotHost

get_mailslot_ok:
    mov es,ax
    mov edx,es:h_req_connection
    mov bx,ds
    clc

get_mailslot_done:
    pop ax
    pop es
    pop ds
    ret
GetReceiveMailslot      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SendData
;
;           DESCRIPTION:    Send data to network
;
;           PARAMETERS:         BX              Mailslot selector
;                           DS              Host list
;                           ES              Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendData    Proc near
    push fs
    push gs
    pushad
;
    mov ax,es
    mov gs,ax
    mov fs,es:l_host_entry
    mov fs,fs:h_host
    mov ecx,es:l_size
    sub ecx,es:l_pos
    push bx
    call CreateSegment
;
    mov eax,gs:l_connection
    Reverse
    mov es:[di].sh_connection,eax
;
    mov eax,gs:l_size
    Reverse
    mov es:[di].sh_offset_size,eax
;
    pop ax
    xchg al,ah
    mov es:[di].sh_mailslot,ax
;
    mov es:[di].sh_flags, SOM or EOM or RPY
;
    push cx
    push di
    mov esi,OFFSET l_msg
    add esi,gs:l_pos
    add gs:l_pos,ecx
    movzx edi,bx
    rep movs byte ptr es:[edi],gs:[esi]
    pop di
    pop cx
    xor ax,ax
    mov fs,ax
    mov gs,ax
    LeaveSection ds:h_reply_section
    mov ds,ax
;
    add cx,bx
    sub cx,di
    mov ax,cx
    xchg al,ah
    mov es:[di].sh_size,ax
    mov es:[di].sh_checksum,0
    add ax,7900h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add di,8
    mov es:[di].sh_checksum,ax
    SendIp
;
    popad
    pop gs
    pop fs
    ret
SendData    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SendAck
;
;           DESCRIPTION:    Send ACK to network
;
;           PARAMETERS:         DS              Mailslot selector
;                           ES              SMP connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendAck Proc near
    push ds
    push fs
    push gs
    pushad
;
    mov ax,es
    mov gs,ax
    mov fs,es:l_host_entry
    mov fs,fs:h_host
    xor ecx,ecx
    call CreateSegment
;
    mov es:[di].sh_connection,0
    mov es:[di].sh_offset_size,0
    mov es:[di].sh_mailslot,0
    mov es:[di].sh_flags, 0
;
    xor ax,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax
;
    add cx,bx
    sub cx,di
    mov ax,cx
    xchg al,ah
    mov es:[di].sh_size,ax
    mov es:[di].sh_checksum,0
    add ax,7900h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add di,8
    mov es:[di].sh_checksum,ax
    SendIp
;
    popad
    pop gs
    pop fs
    pop ds
    ret
SendAck Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SendGoodNameReply
;
;           DESCRIPTION:    Send a good name resolution reply to network
;
;           PARAMETERS:         DS              Mailslot selector
;                           ES              Received IP data
;                           EDX             Connection
;                           FS              Host
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendGoodNameReply       Proc near
    push ds
    push es
    push fs
    push eax
    push ebx
    push ecx
    push si
    push di
;
    mov ecx,2
    mov si,OFFSET m_name

send_good_name_size_loop:
    lodsb
    inc ecx
    or al,al
    jnz send_good_name_size_loop
;
    push edx
    call CreateSegment
    pop edx
;
    mov eax,edx
    Reverse
    mov es:[di].sh_connection,eax
;
    mov eax,ds:m_rec_max_size
    Reverse
    mov es:[di].sh_offset_size,eax
;
    mov ax,ds
    xchg al,ah
    mov es:[di].sh_mailslot,ax
;
    mov es:[di].sh_flags, NAM OR RPY
;
    mov ax,MAX_PENDING_REQUESTS
    xchg al,ah
    mov es:[bx],ax
;
    push di
    mov di,bx
    add di,2
    mov si,OFFSET m_name

send_good_name_move_loop:
    lodsb
    stosb
    or al,al
    jnz send_good_name_move_loop
;
    pop di
    xor ax,ax
    mov ds,ax
    mov fs,ax
;
    add cx,bx
    sub cx,di
    mov ax,cx
    xchg al,ah
    mov es:[di].sh_size,ax
    mov es:[di].sh_checksum,0
    add ax,7900h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add di,8
    mov es:[di].sh_checksum,ax
    SendIp
;
    pop di
    pop si
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
SendGoodNameReply       Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           QueueReply
;
;           DESCRIPTION:    Queue reply
;
;           PARAMETERS:         DS              Host list entry
;                           ES              Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueueReply      Proc near
    push di
;
    mov di,ds:h_reply_list
    or di,di
    je queue_reply_empty
;
    push ds
    push si
    mov ds,di
    mov si,ds:ml_prev
    mov ds:ml_prev,es
    mov ds,si
    mov ds:ml_next,es
    mov es:ml_next,di
    mov es:ml_prev,si
    pop si
    pop ds
    jmp queue_reply_done

queue_reply_empty:
    mov es:ml_next,es
    mov es:ml_prev,es
    mov ds:h_reply_list,es

queue_reply_done:
    pop di
    ret
QueueReply      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DequeueReply
;
;           DESCRIPTION:    Dequeue reply
;
;           PARAMETERS:         DS              Host list entry
;                           ES              Connection to dequeue
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DequeueReply    Proc near
    push ax
    push di
;
    push ds
    mov di,es:ml_next
    mov ax,es
    cmp ax,di
    mov ax,es:ml_prev
    mov ds,ax
    mov ds:ml_next,di
    mov ds,di
    mov ds:ml_prev,ax
    pop ds
    jne dequeue_more
;
    mov ds:h_reply_list,0
    jmp dequeue_removed

dequeue_more:
    mov ax,es:ml_next
    mov ds:h_reply_list,ax

dequeue_removed:
    pop di
    pop ax
    ret
DequeueReply    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FindReply
;
;           DESCRIPTION:    Find reply
;
;           PARAMETERS:         DS              Host list entry
;                           EBX             Connection
;
;           RETURNS:        ES              Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindReply       Proc near
    push ax
;
    mov ax,ds:h_reply_list
    or ax,ax
    stc
    jz find_reply_done

find_reply_loop:
    mov es,ax
    cmp ebx,es:l_connection
    clc
    je find_reply_done
;
    mov ax,es:ml_next
    cmp ax,ds:h_reply_list
    jne find_reply_loop
    stc

find_reply_done:
    pop ax
    ret
FindReply       Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyFromSmp
;
;           DESCRIPTION:    Copy message from SMP
;
;           PARAMETERS:         DS              Mailslot
;                           ES              SMP request list entry
;                           FS:ESI      Message buffer
;
;           RETURNS:        ECX             Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyFromSmp     Proc near
    push eax
    push esi
    push edi
;
    mov ds:m_current,es
    mov ds:m_send_thread,-1
    mov ecx,es:l_size
    push ds
    push ecx
    mov ax,es
    mov ds,ax
    mov ax,fs
    mov es,ax
    mov edi,esi
    mov esi,OFFSET l_msg
    rep movs byte ptr es:[edi],ds:[esi]
    pop ecx
    pop ds
;
    xor ax,ax
    mov es,ax
    LeaveSection ds:m_section
;
    pop edi
    pop esi
    pop eax
    ret
CopyFromSmp     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReplyToSmp
;
;           DESCRIPTION:    Reply to SMP
;
;           PARAMETERS:         DS              Mailslot
;                           ES:EDI      Message buffer
;                           ECX             Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReplyToSmp      Proc near
    push ds
    push es
    pushad
;
    push ds
    mov eax,ecx
    add eax,OFFSET l_msg
    push es
    AllocateSmallGlobalMem
;
    push es
    mov ds:m_send_thread,0
    mov es,ds:m_current
    mov ebx,es:l_connection
    mov edx,es:l_receive_ip
    mov ds,es:l_host_entry  
    FreeMem
    pop es
;
    EnterSection ds:h_reply_section
    mov es:l_host_entry,ds
    mov es:l_connection,ebx
    mov es:l_size,ecx
    mov es:l_receive_ip,edx
    mov es:l_pos,0
    mov es:l_ack,0
    mov es:l_reorder_count,0
    call QueueReply
;
    mov ax,ds
    pop ds
    mov esi,edi
    mov edi,OFFSET l_msg
    rep movs byte ptr es:[edi],ds:[esi]
    mov ds,ax
    pop bx
    call SendData
;
    popad
    pop es
    pop ds
    ret
ReplyToSmp      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SmpToReceiver
;
;           DESCRIPTION:    Send SMP data to local mailslot
;
;           Parameters:         DS          Mailslot
;                           ES          Receive list data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SmpToReceiver   Proc near
    push ax
;
    EnterSection ds:m_section
    mov ax,ds:m_rec_thread
    or ax,ax
    jz send_smp_busy
;
    mov ax,ds:m_send_thread
    or ax,ax
    jz send_smp_idle

send_smp_busy:
    call QueueReceiveRequest
    xor ax,ax
    mov es,ax
    LeaveSection ds:m_section
    jmp send_smp_done

send_smp_idle:
    push ecx
    push esi
;
    push fs
    mov ax,es
    mov fs,ax
    mov ecx,es:l_size
    mov esi,OFFSET l_msg
    mov ds:m_current,es
    xor ax,ax
    mov es,ax
    mov ds:m_send_thread,-1
    mov ds:m_reply_callb,OFFSET ReplyToSmp
    call CopyToReceiver
    pop fs
;
    pop esi
    pop ecx

send_smp_done:
    pop ax
    ret
SmpToReceiver   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendRequest
;
;       Purpose:        Send completed request
;
;       Parameters:         DS          Host list
;                       ES          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendRequest     Proc near
    push ax
    push ebx
    push cx
    push edx
;
    mov edx,es:l_connection
    xor ax,ax
    mov es,ax
    cmp edx,ds:h_req_connection
    jne send_req_done
;
    movzx ebx,ds:h_req_index
    mov cx,ds:h_req_unacked

send_req_loop:
    xor ax,ax
    xchg ax,ds:[2*ebx].h_req_arr
    or ax,ax
    jz send_req_save
;
    push ds
    mov es,ax
    mov ds,ds:h_mailslot
    call SmpToReceiver
    xor ax,ax
    mov es,ax
    pop ds
;
    inc edx
    inc bx
    cmp bx,MAX_PENDING_REQUESTS
    jb send_req_conn_ok
;
    sub bx,MAX_PENDING_REQUESTS

send_req_conn_ok:
    loop send_req_loop

send_req_save:
    mov ds:h_req_index,bx
    mov ds:h_req_unacked,cx
    mov ds:h_req_connection,edx

send_req_done:
    pop edx
    pop cx
    pop ebx
    pop ax
    ret
SendRequest     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           InsertReordered
;
;       Purpose:        Insert reordered data
;
;       Parameters:         ES          Connection
;                       EAX         Position
;                       CX          Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertReordered Proc near
    pushad
;
    movzx esi,cx
    mov edi,eax
;
    mov bx,OFFSET l_reorder_arr
    mov cx,es:l_reorder_count
    or cx,cx
    jz insert_reorder_do

insert_reorder_loop:
    mov edx,es:[bx].reorder_offset
    cmp eax,edx
    jb insert_reorder_do
;
    add edx,es:[bx].reorder_size
    cmp eax,edx
    ja insert_reorder_next
;
    add eax,esi
    cmp eax,edx
    jbe insert_reorder_done
;
    mov eax,esi
    add eax,edi
    sub eax,es:[bx].reorder_offset
    mov es:[bx].reorder_size,eax
    jmp insert_reorder_check_merge

insert_reorder_next:
    add bx,8
    loop insert_reorder_loop

insert_reorder_do:
    mov dx,es:l_reorder_count
    cmp dx,REORDER_ENTRIES
    jne insert_reorder_not_full
;
    sub cx,1
    jc insert_reorder_done
;
    dec es:l_reorder_count

insert_reorder_not_full:
    inc es:l_reorder_count
    mov dx,cx
    shl dx,3
    add bx,dx
    push cx
;
    or cx,cx
    jz insert_reorder_add

insert_reorder_move_fwd:
    mov edx,es:[bx-8]
    mov es:[bx],edx
    mov edx,es:[bx-4]
    mov es:[bx+4],edx
    sub bx,8
    loop insert_reorder_move_fwd

insert_reorder_add:
    pop cx
    inc cx
    mov es:[bx].reorder_offset,edi
    mov es:[bx].reorder_size,esi

insert_reorder_check_merge:
    cmp cx,1
    jbe insert_reorder_done
;
    mov eax,es:[bx].reorder_offset
    add eax,es:[bx].reorder_size
    cmp eax,es:[bx+8].reorder_offset
    jb insert_reorder_done
;
    mov eax,es:[bx+8].reorder_offset
    add eax,es:[bx+8].reorder_size
    sub eax,es:[bx].reorder_offset
    cmp eax,es:[bx].reorder_size
    jb insert_reorder_size_ok
;
    mov es:[bx].reorder_size,eax

insert_reorder_size_ok:
    dec cx
    dec es:l_reorder_count
;
    or cx,cx
    jz insert_reorder_done

    push bx
    push cx
insert_reorder_move_back:
    add bx,8
    mov eax,es:[bx+8]
    mov es:[bx],eax
    mov eax,es:[bx+12]
    mov es:[bx+4],eax
    loop insert_reorder_move_back
;
    pop cx
    pop bx
    jmp insert_reorder_check_merge

insert_reorder_done:
    popad
    ret
InsertReordered Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateRequest
;
;           DESCRIPTION:    Create a request
;
;           Parameters:         DS          Host list selector
;                           ES:DI   SMP header
;                           ES:SI   SMP data
;
;           Returns:        AX          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRequest   Proc near
    push es
    push ecx
    push edx
    push edi
;
    mov ecx,eax
    mov eax,es:[di].sh_connection
    Reverse
    mov edx,eax
;
    mov edi,es:ip_dest      
    mov eax,OFFSET l_msg
    add eax,ecx
    AllocateSmallGlobalMem
    mov es:ml_rec_callb,OFFSET CopyFromSmp
    mov es:ml_reply_callb,OFFSET ReplyToSmp
    mov es:l_reorder_count,0
    mov es:l_pos,0
    mov es:l_ack,0
    mov es:l_host_entry,ds
    mov es:l_connection,edx
    mov es:l_receive_ip,edi
    mov es:l_size,ecx       
    mov ds:[bx].h_req_arr,es
    inc ds:h_req_unacked
    mov ax,es
;
    pop edi
    pop edx
    pop ecx
    pop es
    ret
CreateRequest   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyRequestData
;
;           DESCRIPTION:    Copy request data
;
;           Parameters:         DS          Host list selector
;                           AX          Connection
;                           ES:DI   SMP header
;                           ES:SI   SMP data
;                           CX          Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyRequestData Proc near
    push eax
;
    push ds
    push es
    push ecx
    push esi
    push edi
;
    push es
    mov es,ax
    pop ds
;
    mov eax,es:l_pos
    cmp eax,es:l_size
    je copy_req_check
;
    mov bx,di
    movzx ecx,cx
    movzx esi,si
    xor edi,edi
;
    test ds:[bx].sh_flags,SOM
    jnz copy_req_offset_ok
;
    mov eax,ds:[bx].sh_offset_size
    Reverse
    mov edi,eax

copy_req_offset_ok:
    cmp edi,es:l_size
    jae copy_req_check
;
    mov eax,edi
    add eax,ecx
    cmp eax,es:l_size
    jb copy_req_move_it
;
    mov ecx,es:l_size
    sub ecx,edi

copy_req_move_it:
    push ecx
    push edi
    add edi,OFFSET l_msg
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
    pop ecx
;
    mov eax,edi
    cmp eax,es:l_pos
    ja copy_req_reorder
;
    mov eax,es:l_pos

copy_req_reorder:
    call InsertReordered
;
    mov eax,es:l_reorder_arr.reorder_offset
    cmp eax,es:l_pos
    ja copy_req_check
;
    add eax,es:l_reorder_arr.reorder_size
    sub eax,es:l_pos
    add es:l_pos,eax

copy_req_check:
    mov eax,es:l_pos
    cmp eax,es:l_size

copy_req_move_done:
    mov ax,es
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    jne copy_req_done
;
    push es
    mov es,ax
    call SendRequest
    pop es

copy_req_done:
    pop eax
    ret
CopyRequestData Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HandleRequest
;
;           DESCRIPTION:    Handle a request
;
;           Parameters:         DS          Host list selector
;                           ES:DI   SMP header
;                           ES:SI   SMP data
;                           CX          Size of data
;                           EDX         Max receive size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRequest   Proc near
    push es
    push eax
    push bx
;
    EnterSection ds:h_req_section
    mov eax,es:[di].sh_connection
    Reverse
    sub eax,ds:h_req_connection
    jl handle_req_check_reply
;
    cmp eax,MAX_PENDING_REQUESTS
    jae handle_req_reset_leave
;
    mov bx,ax
    add bx,ds:h_req_index
    cmp bx,MAX_PENDING_REQUESTS
    jb handle_req_conn_ok
;
    sub bx,MAX_PENDING_REQUESTS

handle_req_conn_ok:
    add bx,bx
    mov ax,ds:[bx].h_req_arr
    or ax,ax
    jnz handle_req_copy_data
;
    test es:[di].sh_flags,SOM
    jz handle_req_leave
;
    mov eax,es:[di].sh_offset_size
    Reverse
    cmp eax,edx
    ja handle_req_out_of_range
;
    call CreateRequest

handle_req_copy_data:   
    call CopyRequestData
    jmp handle_req_leave

handle_req_out_of_range:
    push ds
    mov eax,es:[di].sh_connection
    Reverse
    mov edx,eax
    mov bx,ds:h_mailslot
    mov ds,ds:h_host
    call QueueTooLarge
    pop ds
    jmp handle_req_leave

handle_req_check_reply:
    LeaveSection ds:h_req_section
;
    mov eax,es:[di].sh_connection
    Reverse
    mov ebx,eax
    EnterSection ds:h_reply_section
    call FindReply
    jc handle_reply_reset
;
    mov bx,ds:h_mailslot
    mov eax,es:l_ack
    mov es:l_pos,eax
    call SendData
    jmp handle_req_done

handle_reply_reset:
    push ds
    mov eax,es:[di].sh_connection
    Reverse
    mov edx,eax
    mov bx,ds:h_mailslot
    mov ds,ds:h_host
    call QueueReset
    pop ds

handle_reply_leave:
    LeaveSection ds:h_reply_section
    jmp handle_req_done

handle_req_reset_leave:
    push ds
    mov eax,es:[di].sh_connection
    Reverse
    mov edx,eax
    mov bx,ds:h_mailslot
    mov ds,ds:h_host
    call QueueReset
    pop ds

handle_req_leave:
    LeaveSection ds:h_req_section

handle_req_done:
    pop bx
    pop eax
    pop es
    ret
HandleRequest   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveRequest
;
;       Purpose:        Receive request notify from IP
;
;       Parameters:         AX          Size of options
;                       ECX         Size of data
;                       EDX         Source IP address
;                       DS:ESI  SMP data
;                       ES:EDI  SMP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReceiveRequest

ReceiveRequest  Proc near
    push ds
    push ax
    push bx
;
    mov bx,es:[di].sh_mailslot
    xchg bl,bh
    call FindReceiveMailslot
    jc receive_fail
;
    call FindReceiveMailslotHost
    jc receive_fail
;
    push edx
    mov edx,ds:m_rec_max_size
    mov ds,ax
    call HandleRequest
    pop edx
    jmp receive_done

receive_fail:
    call FindHost
    jc receive_done
;
    push edx
    mov ds,ax
    mov eax,es:[di].sh_connection
    Reverse
    mov edx,eax
    mov bx,es:[di].sh_mailslot
    xchg bl,bh
    call QueueReset
    pop edx
;
    call GetSmpThread
    Signal

receive_done:
    pop bx
    pop ax
    pop ds
    ret
ReceiveRequest  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiverAck
;
;       Purpose:        Receiver ACK
;
;       Parameters:         ES:SI   Response data
;                       DS          Mailslot
;                       GS          Host list entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReceiverAck

ReceiverAck     Proc near
    push ds
    push es
    push eax
    push ecx
    push edx
;
    mov ax,gs
    mov ds,ax
    mov bx,si
    add bx,SIZE smp_response
    mov eax,es:[bx]
    Reverse
    mov ecx,eax
;
    mov eax,es:[si].sr_connection
    Reverse
    mov ebx,eax
;
    EnterSection ds:h_reply_section
    call FindReply
    jc proc_ack_done
;
    cmp ecx,es:l_ack
    jc proc_ack_done
;
    mov es:l_ack,ecx
    cmp ecx,es:l_size
    jc proc_ack_done
;
    call DequeueReply
    FreeMem

proc_ack_done:
    xor ax,ax
    mov es,ax
    LeaveSection ds:h_reply_section
    clc
;
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
ReceiverAck     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NameRequest
;
;           DESCRIPTION:    Name resolve request
;
;           Parameters:         AX          Size of options
;                           ECX         Size of data
;                           EDX         Source IP address
;                           DS:ESI  SMP data
;                           ES:EDI  SMP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NameRequest

NameRequest     Proc near
    push ds
    pushad
;
    mov di,si
    call EnterIpcSection
    call GetIpcMailslotList
    mov bx,ax
    or bx,bx
    jz name_res_done_leave

name_res_loop:
    mov ds,bx
    mov si,OFFSET m_name
;
    push di

name_res_comp:
    mov al,[si]
    cmp al,es:[di]
    jne name_res_next
;
    or al,al
    jz name_res_ok
;
    inc si
    inc di
    jmp name_res_comp

name_res_next:
    pop di
    mov bx,ds:m_link
    or bx,bx
    jnz name_res_loop       
;
    jmp name_res_done_leave

name_res_ok:
    pop di
;
    call LeaveIpcSection
    call GetReceiveMailslot
    jc name_res_done
;
    mov ds,bx
    call SendGoodNameReply
    jmp name_res_done

name_res_done_leave:
    call LeaveIpcSection

name_res_done:
    popad
    pop ds
    ret
NameRequest     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SuperviseMailslotHost
;
;           DESCRIPTION:    Supervise a mailslot host
;
;           PARAMETERS:         DS          Host list entry
;
;           RETURNS:        CY          Nothing to do
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SuperviseMailslotHost   Proc near
    ret
SuperviseMailslotHost   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SuperviseMailslot
;
;           DESCRIPTION:    Supervise a mailslot
;
;           PARAMETERS:         DS          Mailslot
;
;           RETURNS:        CY          Nothing to do
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SuperviseMailslot       Proc near
    push cx
;
    xor cx,cx
    EnterSection ds:m_host_section
    mov ax,ds:m_host_list
    push ds

supervise_mailslot_host_loop:
    or ax,ax
    stc
    jz supervise_mailslot_host_done
;
    inc cx
    mov ds,ax
    call SuperviseMailslotHost
;
    mov ax,ds:h_link
    jmp supervise_mailslot_host_loop

supervise_mailslot_host_done:
    pop ds
    LeaveSection ds:m_host_section
;
    or cx,cx
    stc
    jz supervise_mailslot_done
;
    clc

supervise_mailslot_done:
    pop cx  
    ret
SuperviseMailslot       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReceiveSupervise
;
;           DESCRIPTION:    Supervise receive operations
;
;           RETURNS:        CY          Nothing to do
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReceiveSupervise

ReceiveSupervise    Proc near
    xor cx,cx
;
    call EnterIpcSection
    call GetIpcMailslotList

receive_supervise_loop:
    or ax,ax
    jz receive_supervise_leave
;
    mov ds,ax
    call SuperviseMailslot
    jc receive_supervise_next
;
    inc cx

receive_supervise_next:
    mov ax,ds:m_link
    jmp receive_supervise_loop

receive_supervise_leave:
    call LeaveIpcSection
;
    or cx,cx
    stc
    jz receive_supervise_done
;
    clc

receive_supervise_done:
    ret
ReceiveSupervise    Endp

code    ENDS

    END
