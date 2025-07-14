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
; SMPSEND.ASM
; Sender part of Simple Message Protocol (remote IPC)
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

REORDER_ENTRIES EQU 8
MAX_PENDING_REQUESTS    EQU 16

reorder_entry   STRUC

reorder_offset  DD ?
reorder_size    DD ?

reorder_entry   ENDS

send_list_data  STRUC

l_receive_ip            DD ?
l_connection            DD ?
l_size                          DD ?
l_pos                           DD ?
l_ack                           DD ?
l_reorder_count         DW ?
l_reorder_arr           DD 2 * REORDER_ENTRIES DUP(?)
l_send_base                     DD ?
l_send_size                     DD ?
l_send_glob_base        DD ?
l_send_glob_size        DD ?
l_send_glob_sel         DW ?
l_send_thread           DW ?
l_reply_max_size        DD ?
l_reply_base            DD ?
l_reply_glob_base       DD ?
l_reply_glob_size       DD ?
l_reply_glob_sel        DW ?
l_reply_thread          DW ?
l_send_time                     DD ?
l_timeout                       DD ?

send_list_data  ENDS

smp_mailslot_data       STRUC

vm_common                       mailslot_data <>
vm_supervisor_link      DW ?
vm_host                         DW ?
vm_mailslot                     DW ?
vm_rec_max_size         DD ?
vm_max_active           DW ?
vm_connection           DD ?
vm_send_connection      DD ?
vm_requests                     DW ?
vm_index                        DW ?
vm_arr                          DW MAX_PENDING_REQUESTS DUP(?)
vm_pending_list         DW ?
vm_name_timeout         DD ?
vm_name_time            DD ?
vm_valid                        DB ?
vm_name                         DB ?

smp_mailslot_data       ENDS

data    SEGMENT byte public 'DATA'

super_mailslot_list     DW ?

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
        
        assume cs:code

    extrn GetSmpThread:near
        extrn CreateSegment:near
        extrn CalcChecksum:near
        extrn SelectorToLinear:near
        extrn QueueAck:near
        extrn QueueTooLarge:near
        extrn FindHost:near
        extrn AllocateIpcHandle:near
        extrn FlushResponses:near

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   FindSendMailslot
;
;       Purpose:                Find send mailslot
;
;       Parameters:             BX              Mailslot
;                                       EDX             IP address
;
;       Returns:                DS              Mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public FindSendMailslot

FindSendMailslot        Proc near
        push ax
        push bx
;
        call FindHost
        jc find_send_mailslot_done
;
        mov ds,ax
        push ds
        EnterSection ds:shd_section
;
        mov ax,bx
        mov bx,ds:shd_mailslot_list
        or bx,bx
        stc
        jz find_send_mailslot_done

find_send_mailslot_loop:
        mov ds,bx
        cmp ax,ds:vm_mailslot
        clc
        je find_send_mailslot_done
;
        mov bx,ds:m_link
        or bx,bx
        jnz find_send_mailslot_loop     
;
        stc

find_send_mailslot_done:        
        pop ds
        pushf
        LeaveSection ds:shd_section
        popf
        mov ds,bx
;
        pop bx
        pop ax
        ret
FindSendMailslot        Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendData
;
;               DESCRIPTION:    Send message through SMP
;
;               PARAMETERS:             DS                      Virtual mailslot selector
;                                               GS                      SMP connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendData        Proc near
        push ds
        push fs
        pushad
;
        mov fs,ds:vm_host
        mov ecx,gs:l_size
        sub ecx,gs:l_pos
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
        mov ax,ds:vm_mailslot
        xchg al,ah
        mov es:[di].sh_mailslot,ax
;
        mov es:[di].sh_flags, SOM or EOM or REQ
;
        push ds
        push cx
        push di
        mov ds,gs:l_send_glob_sel
        movzx edi,bx
        mov esi,gs:l_pos
        add gs:l_pos,ecx
        rep movs byte ptr es:[edi],ds:[esi]
        pop di
        pop cx
        pop ds
;
        xor ax,ax
        mov fs,ax
        mov gs,ax
        LeaveSection ds:m_section
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
        pop fs
        pop ds
        ret
SendData        Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendAck
;
;               DESCRIPTION:    Send ACK
;
;               PARAMETERS:             DS                      Virtual mailslot selector
;                                               GS                      SMP connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendAck Proc near
        push ds
        push fs
        pushad
;
        mov fs,ds:vm_host
        mov ecx,gs:l_size
        xor ecx,ecx
        call CreateSegment
;
        mov es:[di].sh_connection,0
        mov es:[di].sh_offset_size,0
        mov es:[di].sh_mailslot,0
        mov es:[di].sh_flags, 0
;
        xor ax,ax
        mov fs,ax
        mov gs,ax
        LeaveSection ds:m_section
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
        pop fs
        pop ds
        ret
SendAck Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendNameRequest
;
;               DESCRIPTION:    Send name resolution request
;
;               PARAMETERS:             DS                      Virtual mailslot selector
;                                               EDX                     IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendNameRequest Proc near
        push ds
        push es
        push fs
        pushad
;
        xor ecx,ecx
        mov si,OFFSET vm_name

send_name_size_loop:
        lodsb
        inc ecx
        or al,al
        jnz send_name_size_loop
;
        mov fs,ds:vm_host
        call CreateSegment
;
        mov es:[di].sh_connection,0
        mov es:[di].sh_offset_size,0
        mov es:[di].sh_mailslot,0
        mov es:[di].sh_flags, NAM or REQ
;
        push cx
        push di
        mov di,bx
        mov si,OFFSET vm_name
        rep movsb
        pop di
        pop cx
;
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
        popad
        pop fs
        pop es
        pop ds
        ret
SendNameRequest Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CreateMailslot
;
;               DESCRIPTION:    Create a virtual mailslot selector
;
;               PARAMETERS:             DS                      Host
;                                               ES:EDI          Mailslot name
;
;               RETURNS:                BX                      Virtual mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMailslot  Proc near
        push es
        push fs
        push eax
        push ecx
        push esi
        push edi
;
        push edi
        mov ecx,10000h
        xor al,al
        repne scas byte ptr es:[edi]
        neg cx
        movzx ecx,cx
        pop edi
;
        mov ax,es
        mov fs,ax
        mov eax,OFFSET vm_name
        add eax,ecx
        AllocateSmallGlobalMem
        mov es:vm_host,ds
        push ds
        mov ax,es
        mov ds,ax
        mov ds:m_send_callb,OFFSET SendToSmp
        mov ds:m_link,0
        mov ds:m_usage,0
        mov ds:vm_requests,0
        mov ds:vm_index,0
        mov ds:vm_pending_list,0
        mov ds:vm_valid,0
        InitSection ds:m_section
        pop ds
;
        mov esi,edi
        mov edi,OFFSET vm_name
        rep movs byte ptr es:[edi],fs:[esi]
;
        mov di,OFFSET vm_arr
        mov cx,MAX_PENDING_REQUESTS
        xor ax,ax
        rep stosw
;
        mov bx,es
;
        pop edi
        pop esi
        pop ecx
        pop eax
        pop fs
        pop es
        ret
CreateMailslot  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   QueryMailslot
;
;               DESCRIPTION:    Query mailslot
;
;               PARAMETERS:             DS                      Host
;                                               ES:EDI          Mailslot name
;
;               RETURNS:                AX                      Virtual mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public QueryMailslot
    
QueryMailslot   Proc near
        push bx
        push edx
;
        call CreateMailslot
        push es
;       
        push ds
        mov ds,bx
        EnterSection ds:m_section
        pop ds
;       
        mov es,bx
        mov ax,ds:shd_mailslot_list
        mov ds:shd_mailslot_list,es
        mov es:m_link,ax
        pop es
;
        push ds
        mov ds,ds:shd_host
        GetHostTimeout
        mov ds,bx
        mov ds:vm_name_timeout,eax
;
        GetSystemTime
        mov ds:vm_name_time,eax
;
        mov ax,ds
        call GetSmpThread
        Signal
        pop ds
;
        pop edx
        pop bx
        ret
QueryMailslot   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetRemoteMailslot
;
;               DESCRIPTION:    Get remote mailslot from host & name
;
;               PARAMETERS:             EDX                     IP address
;                                               ES:EDI          Mailslot name
;
;               RETURNS:                BX                      Virtual mailslot handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GetSendMailslot

GetSendMailslot Proc near
        push ds
        push es
        push eax
        push si
;
        call FindHost
        jc get_send_mailslot_done
;
        mov ds,ax
        push ds
;
        EnterSection ds:shd_section
        mov bx,ds:shd_mailslot_list
        or bx,bx
        jz get_send_mailslot_query

get_send_mailslot_loop:
        mov ds,bx
        mov si,OFFSET vm_name
;
        push edi

get_send_mailslot_comp:
        mov al,[si]
        cmp al,es:[edi]
        jne get_send_mailslot_next
;
        or al,al
        jz get_send_mailslot_found
;
        inc si
        inc edi
        jmp get_send_mailslot_comp

get_send_mailslot_found:
        mov bx,ds
        pop edi
        pop ds
        LeaveSection ds:shd_section
        mov ds,bx
        jmp get_send_mailslot_ok
        
get_send_mailslot_next:
        pop edi
        mov bx,ds:m_link
        or bx,bx
        jnz get_send_mailslot_loop      

get_send_mailslot_query:        
        pop ds
        call QueryMailslot
        LeaveSection ds:shd_section
;
        mov ds,ax
        LeaveSection ds:m_section
        call SendNameRequest

get_send_mailslot_ok:
        inc ds:m_usage
        mov bx,ds
        call AllocateIpcHandle
        clc
        jmp get_send_mailslot_done

get_send_mailslot_fail:
        stc

get_send_mailslot_done:
        pop si
        pop eax
        pop es
        pop ds
        ret
GetSendMailslot Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   QueuePendingRequest
;
;               DESCRIPTION:    Queue pending request
;
;               PARAMETERS:             DS                      Virtual mailslot
;                                               GS                      Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueuePendingRequest     Proc near
        push di
;
        mov di,ds:vm_pending_list
        or di,di
        je queue_pending_empty
;
        push ds
        push si
        mov ds,di
        mov si,ds:ml_prev
        mov ds:ml_prev,gs
        mov ds,si
        mov ds:ml_next,gs
        mov gs:ml_next,di
        mov gs:ml_prev,si
        pop si
        pop ds
        jmp queue_pending_done

queue_pending_empty:
        mov gs:ml_next,gs
        mov gs:ml_prev,gs
        mov ds:vm_pending_list,gs

queue_pending_done:
        pop di
        ret
QueuePendingRequest     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   DequeuePendingRequest
;
;               DESCRIPTION:    Dequeue pending request
;
;               PARAMETERS:             DS                      Virtual mailslot
;                                               GS                      Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DequeuePendingRequest   Proc near
        push ax
        push di
;
        push ds
        mov di,gs:ml_next
        mov ax,gs
        cmp ax,di
        mov ax,gs:ml_prev
        mov ds,ax
        mov ds:ml_next,di
        mov ds,di
        mov ds:ml_prev,ax
        pop ds
        jne dequeue_pending_more
;
        mov ds:vm_pending_list,0
        jmp dequeue_pending_removed

dequeue_pending_more:
        mov ax,gs:ml_next
        mov ds:vm_pending_list,ax

dequeue_pending_removed:
        pop di
        pop ax
        ret
DequeuePendingRequest   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   QueueActiveRequest
;
;               DESCRIPTION:    Queue active request
;
;               PARAMETERS:             DS                      Virtual mailslot
;                                               GS                      Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueueActiveRequest      Proc near
        push ebx
;
        mov eax,ds:vm_send_connection
        mov ebx,eax
        inc eax
        mov ds:vm_send_connection,eax
        inc ds:vm_requests
;
        mov gs:l_connection,ebx
        sub ebx,ds:vm_connection
        add bx,ds:vm_index
        cmp bx,ds:vm_max_active
        jb queue_active_conn_ok
;
        sub bx,ds:vm_max_active

queue_active_conn_ok:
        add bx,bx
        mov ds:[bx].vm_arr,gs
;
        pop ebx
        ret
QueueActiveRequest      Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   DequeueActiveRequest
;
;       Purpose:                Dequeue a completed active request
;
;       Parameters:             DS              Host list
;                                       GS              Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DequeueActiveRequest    Proc near
        push ax
        push ebx
        push cx
        push edx
;
        mov ebx,gs:l_connection
        xor ax,ax
        mov gs,ax
;
        sub ebx,ds:vm_connection
        add bx,ds:vm_index
        cmp bx,ds:vm_max_active
        jb dequeue_active_index_ok
;
        sub bx,ds:vm_max_active

dequeue_active_index_ok:
        xor ax,ax
        xchg ax,ds:[2*ebx].vm_arr
        or ax,ax
        jz dequeue_active_done
;
        push es
        mov es,ax
        FreeMem
        pop es
;
        cmp bx,ds:vm_index
        jne dequeue_active_done
;
        mov cx,ds:vm_requests
        cmp cx,ds:vm_max_active
        jbe dequeue_active_loop
;
        mov cx,ds:vm_max_active

dequeue_active_loop:
        or cx,cx
        jz dequeue_active_done
;
        mov ax,ds:[2*ebx].vm_arr
        or ax,ax
        jnz dequeue_active_done
;
        inc bx
        cmp bx,ds:vm_max_active
        jb dequeue_active_conn_ok
;
        sub bx,ds:vm_max_active

dequeue_active_conn_ok:
        mov ds:vm_index,bx
        dec ds:vm_requests
        inc ds:vm_connection
;
        mov ax,ds:vm_pending_list
        or ax,ax
        jz dequeue_active_no_pending
;
        mov gs,ax
        call DequeuePendingRequest
        call QueueActiveRequest
;
        GetSystemTime
        mov gs:l_send_time,eax
        push ds
        mov ds,ds:vm_host
        mov ds,ds:shd_host
        GetHostTimeout
        mov gs:l_timeout,eax
        pop ds
        call SendData   
;
        EnterSection ds:m_section

dequeue_active_no_pending:
        movzx ebx,ds:vm_index
        mov cx,ds:vm_requests
        cmp cx,ds:vm_max_active
        jz dequeue_active_done
        jbe dequeue_active_loop
;
        mov cx,ds:vm_max_active
        jmp dequeue_active_loop

dequeue_active_done:
        pop edx
        pop cx
        pop ebx
        pop ax
        ret
DequeueActiveRequest    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ResetMailslot
;
;               DESCRIPTION:    Reset mailslot
;
;               PARAMETERS:             DS                      Virtual mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetMailslot   Proc near
        push gs
        push ax
        push bx
        push cx
;
        mov bx,OFFSET vm_arr
        mov cx,MAX_PENDING_REQUESTS
reset_mailslot_loop:
        xor ax,ax
        xchg ax,[bx]
        or ax,ax
        jz reset_mailslot_next
;
        mov gs,ax
        call QueuePendingRequest

reset_mailslot_next:
        add bx,2
        loop reset_mailslot_loop
;
        xor ax,ax
        mov gs,ax
        mov ds:vm_requests,ax
        mov ds:vm_valid,0
;
        pop cx
        pop bx
        pop ax
        pop gs
        ret
ResetMailslot   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ActivateMailslot
;
;               DESCRIPTION:    Activate mailslot
;
;               PARAMETERS:             DS                      Virtual mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ActivateMailslot        Proc near
        push gs
        push eax
        push edx

activate_mailslot_loop:
        mov ax,ds:vm_requests
        cmp ax,ds:vm_max_active
        ja activate_mailslot_done
;
        mov ax,ds:vm_pending_list
        or ax,ax
        jz activate_mailslot_done
;
        mov gs,ax
        call DequeuePendingRequest
        call QueueActiveRequest
        GetSystemTime
        mov gs:l_send_time,eax
        push ds
        mov ds,ds:vm_host
        mov ds,ds:shd_host
        GetHostTimeout
        mov gs:l_timeout,eax
        pop ds
        call SendData
        EnterSection ds:m_section
        jmp activate_mailslot_loop

activate_mailslot_done:
        pop edx
        pop eax
        pop gs
        ret
ActivateMailslot        Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   FindRequest
;
;               DESCRIPTION:    Find active request
;
;               PARAMETERS:             DS                      Host list entry
;                                               EBX                     Connection
;
;               RETURNS:                GS                      Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindRequest     Proc near
        push ebx
;
        sub ebx,ds:vm_connection
        jl find_req_fail
;
        test ebx,0FFFF0000h
        jnz find_req_fail
;
        cmp bx,ds:vm_requests
        jae find_req_fail
;
        cmp bx,ds:vm_max_active
        jae find_req_fail
;
        add bx,ds:vm_index
        cmp bx,ds:vm_max_active
        jb find_req_ok
;
        sub bx,ds:vm_max_active

find_req_ok:
        mov bx,ds:[2*ebx].vm_arr
        or bx,bx
        jz find_req_fail
;
        mov gs,bx
        clc
        jmp find_req_done

find_req_fail:
        stc

find_req_done:
        pop ebx
        ret
FindRequest     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   QueueSend
;
;               DESCRIPTION:    Queue a SMP send
;
;               PARAMETERS:             DS                      Virtual mailslot
;                                               GS                      SMP connection
;                                               FS:ESI          Send buffer
;                                               ECX                     Send size
;                                               ES:EDI          Reply buffer
;                                               EAX                     Max reply size
;                                               EBX                     Connection number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueueSend       Proc near
        push es
        pushad
;
        mov ebp,ecx
        mov ecx,eax
;
        call SelectorToLinear
        mov al,es:[edi]
        mov al,es:[edi+ecx-1]
;
        GetThread
        mov gs:l_reply_thread,ax
        mov gs:l_reply_base,edx
        mov gs:l_reply_max_size,ecx
        mov eax,edx
        add eax,ecx
        dec eax
        and ax,0F000h
        add eax,1000h
        and dx,0F000h
        sub eax,edx
        mov gs:l_reply_glob_size,eax
        AllocateBigLinear
        mov gs:l_reply_glob_base,edx
        mov ax,word ptr gs:l_reply_base
        and ax,0FFFh
        or dx,ax
        AllocateGdt
        mov ecx,gs:l_reply_max_size
        CreateDataSelector32
        mov gs:l_reply_glob_sel,bx
;
        mov edx,esi
        mov ecx,gs:l_reply_glob_size
        shr ecx,12
        mov esi,gs:l_reply_base
        and si,0F000h
        mov edi,gs:l_reply_glob_base
        CopyPageEntries
;
        mov edi,edx
        mov ecx,ebp
        mov ax,fs
        mov es,ax
        call SelectorToLinear
        mov al,es:[edi]
        mov al,es:[edi+ecx-1]
;
        GetThread
        mov gs:l_send_thread,ax
        mov gs:l_send_base,edx
        mov gs:l_send_size,ecx
        mov eax,edx
        add eax,ecx
        dec eax
        and ax,0F000h
        add eax,1000h
        and dx,0F000h
        sub eax,edx
        mov gs:l_send_glob_size,eax
        AllocateBigLinear
        mov gs:l_send_glob_base,edx
        mov ax,word ptr gs:l_send_base
        and ax,0FFFh
        or dx,ax
        AllocateGdt
        mov ecx,gs:l_send_size
        CreateDataSelector32
        mov gs:l_send_glob_sel,bx
        mov ecx,gs:l_send_glob_size
        shr ecx,12
        mov esi,gs:l_send_base
        and si,0F000h
        mov edi,gs:l_send_glob_base
        CopyPageEntries
;
        popad
        pop es
        ret
QueueSend       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RemoveSend
;
;               DESCRIPTION:    Remove SMP send request
;
;               PARAMETERS:             ECX             Size of send buffer
;                                               ESI             Global base
;                                               EDI             Local base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveSend      Proc near
        pushad
;
        mov edx,esi
        shr ecx,12
        push ecx
        and di,0F000h
        MovePageEntries
;
        pop ecx
        shl ecx,12
        FreeLinear
;
        popad
        ret
RemoveSend      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RemoveReply
;
;               DESCRIPTION:    Remove reply request
;
;               PARAMETERS:             ECX             Size of reply buffer
;                                               ESI             Global base
;                                               EDI             Local base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveReply     Proc near
        pushad
;
        mov edx,esi
        shr ecx,12
        push ecx
        and di,0F000h
        MovePageEntries
;
        pop ecx
        shl ecx,12
        FreeLinear
;
        popad
        ret
RemoveReply     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendToSmp
;
;               DESCRIPTION:    Send a message to SMP
;
;               PARAMETERS:             DS                      Virtual mailslot selector
;                                               FS:ESI          Message buffer
;                                               ECX                     Message size
;                                               ES:EDI          Reply buffer
;                                               EBP                     Max reply size
;
;               RETURNS:                ECX                     Reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendToSmp       Proc near
        push es
        push gs
        push eax
        push ebx
        push edx
        push esi
        push edi
;
        push es
        mov eax,SIZE send_list_data
        AllocateSmallGlobalMem
        mov ax,es
        mov gs,ax
        pop es
;
        EnterSection ds:m_section
        mov gs:l_size,ecx
        mov gs:l_pos,0
        mov gs:l_ack,0
        mov gs:l_reorder_count,0
;
        mov eax,ebp
        call QueueSend
        ClearSignal
        mov ecx,gs:l_send_glob_size
        mov esi,gs:l_send_glob_base
        mov edi,gs:l_send_base
        push gs:l_reply_glob_size
        push gs:l_reply_glob_base
        push gs:l_reply_base
;
        mov al,ds:vm_valid
        or al,al
        jz send_to_smp_queue
;
        mov ax,ds:vm_requests
        cmp ax,ds:vm_max_active
        jae send_to_smp_queue
;
        call QueueActiveRequest
;
        GetSystemTime
        mov gs:l_send_time,eax
        push ds
        mov ds,ds:vm_host
        mov ds,ds:shd_host
        GetHostTimeout
        mov gs:l_timeout,eax
        pop ds
        call SendData
        jmp send_to_smp_wait

send_to_smp_queue:
        call QueuePendingRequest
        xor ax,ax
        mov gs,ax
        LeaveSection ds:m_section

send_to_smp_wait:
        WaitForSignal
        call RemoveSend
        pop edi
        pop esi
        pop ecx
        call RemoveReply
;
        push ds
        GetThread
        mov ds,ax
        mov ecx,ds:p_data
        pop ds
        clc
;
        pop edi
        pop esi
        pop edx
        pop ebx
        pop eax
        pop gs
        pop es
        ret
SendToSmp       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SmpToSender
;
;               DESCRIPTION:    SMP reply to local mailslot
;
;               Parameters:             DS              Virtual mailslot
;                                               GS              Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SmpToSender     Proc near
        push es
        push ax
        push bx
        push ecx
;
        mov bx,gs:l_send_thread
        mov ecx,gs:l_size
        call DequeueActiveRequest
        LeaveSection ds:m_section
;
        mov es,bx
        mov es:p_data,ecx
        xor ax,ax
        mov es,ax
        Signal
;
        pop ecx
        pop bx
        pop ax
        pop es
        ret
SmpToSender     Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   InsertReordered
;
;       Purpose:                Insert reordered data
;
;       Parameters:             GS              Connection
;                                       EAX             Position
;                                       CX              Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertReordered Proc near
        pushad
;
        movzx esi,cx
        mov edi,eax
;
        mov bx,OFFSET l_reorder_arr
        mov cx,gs:l_reorder_count
        or cx,cx
        jz insert_reorder_do

insert_reorder_loop:
        mov edx,gs:[bx].reorder_offset
        cmp eax,edx
        jb insert_reorder_do
;
        add edx,gs:[bx].reorder_size
        cmp eax,edx
        ja insert_reorder_next
;
        add eax,esi
        cmp eax,edx
        jbe insert_reorder_done
;
        mov eax,esi
        add eax,edi
        sub eax,gs:[bx].reorder_offset
        mov gs:[bx].reorder_size,eax
        jmp insert_reorder_check_merge

insert_reorder_next:
        add bx,8
        loop insert_reorder_loop

insert_reorder_do:
        mov dx,gs:l_reorder_count
        cmp dx,REORDER_ENTRIES
        jne insert_reorder_not_full
;
        sub cx,1
        jc insert_reorder_done
;
        dec gs:l_reorder_count

insert_reorder_not_full:
        inc gs:l_reorder_count
        mov dx,cx
        shl dx,3
        add bx,dx
        push cx
;
        or cx,cx
        jz insert_reorder_add

insert_reorder_move_fwd:
        mov edx,gs:[bx-8]
        mov gs:[bx],edx
        mov edx,gs:[bx-4]
        mov gs:[bx+4],edx
        sub bx,8
        loop insert_reorder_move_fwd

insert_reorder_add:
        pop cx
        inc cx
        mov gs:[bx].reorder_offset,edi
        mov gs:[bx].reorder_size,esi

insert_reorder_check_merge:
        cmp cx,1
        jbe insert_reorder_done
;
        mov eax,gs:[bx].reorder_offset
        add eax,gs:[bx].reorder_size
        cmp eax,gs:[bx+8].reorder_offset
        jb insert_reorder_done
;
        mov eax,gs:[bx+8].reorder_offset
        add eax,gs:[bx+8].reorder_size
        sub eax,gs:[bx].reorder_offset
        cmp eax,gs:[bx].reorder_size
        jb insert_reorder_size_ok
;
        mov gs:[bx].reorder_size,eax

insert_reorder_size_ok:
        dec cx
        dec gs:l_reorder_count
;
        or cx,cx
        jz insert_reorder_done

        push bx
        push cx
insert_reorder_move_back:
        add bx,8
        mov eax,gs:[bx+8]
        mov gs:[bx],eax
        mov eax,gs:[bx+12]
        mov gs:[bx+4],eax
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
;               NAME:                   CopyReplyData
;
;               DESCRIPTION:    Copy reply data
;
;               Parameters:             DS              Virtual mailslot
;                                               GS              Connection
;                                               ES:DI   SMP header
;                                               ES:SI   SMP data
;                                               CX              Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyReplyData   Proc near
        pushad
;
        mov eax,es:[di].sh_offset_size
        Reverse
        test es:[di].sh_flags,SOM
        jz copy_reply_do
;
        mov ecx,eax
        cmp ecx,ds:vm_rec_max_size
        jbe copy_reply_inrange
;
        mov edx,gs:l_connection
        push ds
        mov bx,ds:vm_mailslot
        mov ds,ds:vm_host
        call QueueTooLarge
        pop ds
        mov ecx,ds:vm_rec_max_size

copy_reply_inrange:
        mov gs:l_size,ecx
        xor eax,eax

copy_reply_do:
        push ds
        push es
        push ax
        push ecx
;
        movzx esi,si
        movzx ecx,cx
        mov edi,eax
        mov ax,es
        mov ds,ax
        mov es,gs:l_reply_glob_sel
        rep movs byte ptr es:[edi],ds:[esi]
;
        pop ecx
        pop ax
        pop es
        pop ds
;
        cmp eax,gs:l_pos
        ja copy_reply_reorder
;
        mov eax,gs:l_pos

copy_reply_reorder:
        call InsertReordered
;
        mov eax,gs:l_reorder_arr.reorder_offset
        cmp eax,gs:l_pos
        ja copy_reply_move_done
;
        add eax,gs:l_reorder_arr.reorder_size
        sub eax,gs:l_pos
        add gs:l_pos,eax
;
        mov eax,gs:l_pos
        cmp eax,gs:l_size

copy_reply_move_done:
        jnz copy_reply_leave
;
        xor bx,bx
        xchg bx,gs:l_reply_glob_sel
        FreeGdt
;
        mov ecx,gs:l_pos
        mov edx,gs:l_connection
        push ds
        mov bx,ds:vm_mailslot
        mov ds,ds:vm_host
        call QueueAck
        pop ds
        call SmpToSender
        jmp copy_reply_done

copy_reply_leave:
        xor ax,ax
        mov gs,ax
        LeaveSection ds:m_section

copy_reply_done:
        popad
        ret
CopyReplyData   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   HandleReply
;
;               DESCRIPTION:    Handle a reply
;
;               Parameters:             DS              Virtual mailslot
;                                               ES:DI   SMP header
;                                               ES:SI   SMP data
;                                               CX              Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleReply     Proc near
        push gs
        push eax
        push ebx
        push edx
;
        mov al,ds:vm_valid
        or al,al
        jz handle_reply_done
;
        EnterSection ds:m_section
        mov eax,es:[di].sh_connection
        Reverse
        mov ebx,eax
        call FindRequest
        jc handle_reply_leave
;
        mov ax,gs:l_send_glob_sel
        or ax,ax
        jz handle_reply_copy
;
        test es:[di].sh_flags,SOM
        jz handle_reply_leave
;
        xor bx,bx
        xchg bx,gs:l_send_glob_sel
        FreeGdt
;
        mov gs:l_pos,0
        mov gs:l_ack,0
        mov gs:l_reorder_count,0

handle_reply_copy:
        call CopyReplyData
        jmp handle_reply_done

handle_reply_leave:
        xor ax,ax
        mov gs,ax
        LeaveSection ds:m_section

handle_reply_done:
    pop edx
        pop ebx
        pop eax
        pop gs
        ret
HandleReply     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ReceiveReply
;
;               DESCRIPTION:    Handle a reply
;
;               Parameters:             ES:DI   SMP header
;                                               ES:SI   SMP data
;                                               CX              Size of data
;                       EDX     IP source
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReceiveReply

ReceiveReply    Proc near
        push ds
        push bx
;
        mov bx,es:[di].sh_mailslot
        xchg bl,bh
        call FindSendMailslot
        jc receive_reply_done
;       
        call HandleReply

receive_reply_done:
        pop bx
        pop ds
        ret
ReceiveReply    Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   HandleReset
;
;       Purpose:                Handle a reset message
;
;       Parameters:             ES:SI   Response data
;                   EDX     IP source
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public HandleReset

HandleReset     Proc near
        push ds
        push gs
        push eax
        push ebx
        push ecx
;       
        mov bx,es:[si].sr_mailslot
        xchg bl,bh
        call FindSendMailslot
        jc handle_reset_done
;
        EnterSection ds:m_section
        mov eax,es:[si].sr_connection
        Reverse
;
        sub eax,ds:vm_connection
        jl handle_reset_leave
;
        test eax,0FFFF0000h
        jnz handle_reset_leave
;
        cmp ax,ds:vm_requests
        jae handle_reset_leave

handle_reset_do:
    push edx
        mov ds:vm_valid,0
        LeaveSection ds:m_section
        mov fs,ds:vm_host
        call FlushResponses
        EnterSection ds:m_section
        call ResetMailslot
        LeaveSection ds:m_section
;
        push ds
        mov ds,fs:shd_host
        GetHostTimeout
        pop ds
        mov ds:vm_name_timeout,eax
;
        GetSystemTime
        mov ds:vm_name_time,eax
        pop edx
;
        call SendNameRequest
        jmp handle_reset_done

handle_reset_leave:
        LeaveSection ds:m_section

handle_reset_done:
        clc
        pop ecx
        pop ebx
        pop eax
        pop gs
        pop ds
        ret
HandleReset     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   HandleName
;
;               DESCRIPTION:    Handle name resolve reply
;
;               Parameters:             DS              Virtual mailslot
;                                               ES:EDI  SMP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleName      Proc near
        push eax
        push edx
;
        EnterSection ds:m_section
        mov al,ds:vm_valid
        or al,al
        jnz handle_name_done
;
        GetSystemTime
        sub eax,ds:vm_name_time
        jnz handle_name_rtt_done
;
        push ds
        mov ds,ds:vm_host
        mov ds,ds:shd_host
        UpdateRoundTripTime
        pop ds

handle_name_rtt_done:           
        mov ax,es:[di].sh_mailslot
        or ax,ax
        jz handle_name_done
;
        xchg al,ah
        mov ds:vm_mailslot,ax
;
        mov eax,es:[di].sh_connection
        Reverse
        mov ds:vm_connection,eax
        mov ds:vm_send_connection,eax
;
        mov eax,es:[di].sh_offset_size
        or eax,eax
        jz handle_name_done
;
        Reverse
        mov ds:vm_rec_max_size,eax
;
        mov ax,es:[si]
        or ax,ax
        jz handle_name_done
;
        xchg al,ah
        mov ds:vm_max_active,ax
        mov ds:vm_valid,1
        call ActivateMailslot

handle_name_done:
        LeaveSection ds:m_section
        pop edx
        pop eax
        ret
HandleName      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NameReply
;
;               DESCRIPTION:    Name resolve reply
;
;               Parameters:             AX              Size of options
;                                               ECX             Size of data
;                       EDX     IP source
;                                               DS:ESI  SMP data
;                                               ES:EDI  SMP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public NameReply

NameReply       Proc near
        push ds
        push eax
        push bx
        push edx
;
        call FindHost
        jc name_reply_done
;
        mov ds,ax
        push di
;
        mov di,si
        add di,2
;
        EnterSection ds:shd_section
        push ds
        push si
        mov bx,ds:shd_mailslot_list
        or bx,bx
        jz name_reply_pop_done

name_reply_loop:
        mov ds,bx
        mov si,OFFSET vm_name
;
        push di

name_reply_comp:
        mov al,[si]
        cmp al,es:[di]
        jne name_reply_next
;
        or al,al
        jz name_reply_found
;
        inc si
        inc di
        jmp name_reply_comp
        
name_reply_next:
        pop di
        mov bx,ds:m_link
        or bx,bx
        jnz name_reply_loop     

name_reply_pop_done:
        pop si
        pop ds
        pop di
        LeaveSection ds:shd_section
        jmp name_reply_done

name_reply_found:
        mov bx,ds
        pop di
        pop si
        pop ds
        pop di
        LeaveSection ds:shd_section
;
        mov ds,bx
        call HandleName

name_reply_done:
        pop edx
        pop bx
        pop eax
        pop ds
        ret
NameReply       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SuperviseMailslot
;
;               DESCRIPTION:    Supervise a virtual mailslot
;
;               PARAMETERS:             DS              Virtual mailslot
;                                               FS              Host
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SuperviseMailslot       Proc near
        mov bl,ds:vm_valid
        or bl,bl
        jz supervise_mail_name

supervise_mail_active:
        mov ax,gs:super_mailslot_list
        mov ds:vm_supervisor_link,ax
        mov gs:super_mailslot_list,ds
        jmp supervise_mail_done

supervise_mail_name:
        GetSystemTime
        sub eax,ds:vm_name_time
        cmp eax,ds:vm_name_timeout
        jb supervise_mail_done
;
        mov ax,gs:super_mailslot_list
        mov ds:vm_supervisor_link,ax
        mov gs:super_mailslot_list,ds
        
supervise_mail_done:
        ret
SuperviseMailslot       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SendSupervise
;
;               DESCRIPTION:    Supervise send operations
;
;               PARAMETERS:             FS              Host
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SendSupervise

SendSupervise   Proc near
        mov ax,fs
        mov ds,ax
;
        EnterSection ds:shd_section
        push ds
        mov bx,ds:shd_mailslot_list
        or bx,bx
        jz send_supervise_leave

send_supervise_loop:
        mov ds,bx
        call SuperviseMailslot
;
        mov bx,ds:m_link
        or bx,bx
        jnz send_supervise_loop 

send_supervise_leave:   
        pop ds
        LeaveSection ds:shd_section
        ret
SendSupervise   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ResendData
;
;               DESCRIPTION:    Resend data request
;
;               PARAMETERS:             DS              Virtual mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResendData      Proc near
        push gs
;
        mov si,OFFSET vm_arr
        mov cx,MAX_PENDING_REQUESTS
        EnterSection ds:m_section

resend_data_loop:
        push cx
        mov bx,[si]
        or bx,bx
        jz resend_data_next
;
        mov gs,bx
        movzx eax,ds:vm_requests
        mov ecx,gs:l_timeout
        mul ecx
        mov ecx,eax
        GetSystemTime
        sub eax,gs:l_send_time
        cmp eax,ecx
        jb resend_data_next
;
        mov ecx,gs:l_ack
        mov gs:l_pos,ecx
        GetSystemTime
        mov gs:l_send_time,eax
;
        mov eax,gs:l_timeout
        cmp eax,1193000 * 15
        ja resend_data_timeout_ok
;
        add gs:l_timeout,eax

resend_data_timeout_ok:
        call SendData
        EnterSection ds:m_section

resend_data_next:
        pop cx
        add si,2
        sub cx,1
        jnz resend_data_loop
;
        xor ax,ax
        mov gs,ax
        LeaveSection ds:m_section
        pop gs
        ret
ResendData      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ResendName
;
;               DESCRIPTION:    Resend name request
;
;               PARAMETERS:             DS              Virtual mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResendName      Proc near
        GetSystemTime
        mov ds:vm_name_time,eax
;
        mov ecx,ds:vm_name_timeout
        cmp ecx,1193000 * 15
        ja resend_name_timeout_ok
;
        add ds:vm_name_timeout,ecx

resend_name_timeout_ok:
        mov fs,ds:vm_host
        mov edx,fs:shd_ip
        call SendNameRequest
        ret
ResendName      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SendPerform
;
;               DESCRIPTION:    Perform send operations
;
;               PARAMETERS:             GS              IPC sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public SendPerform

SendPerform     Proc near
        mov ax,gs:super_mailslot_list

perform_loop:
        or ax,ax
        jz perform_done
;
        mov ds,ax
        mov al,ds:vm_valid
        or al,al
        jz perform_name

perform_timeout:
        call ResendData
        jmp perform_next

perform_name:
        call ResendName

perform_next:
        mov ax,ds:vm_supervisor_link
        jmp perform_loop

perform_done:
        mov gs:super_mailslot_list,0
        ret
SendPerform     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init_smp_send
;
;               DESCRIPTION:    Init smp send module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_smp_send

init_smp_send   Proc near
    mov ax,SEG data
    mov ds,ax
        mov ds:super_mailslot_list,0
        ret
init_smp_send   Endp

code    ENDS

        END
