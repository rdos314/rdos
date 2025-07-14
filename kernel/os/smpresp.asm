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
; SMPRESP.ASM
; Response handling of Simple Message Protocol (remote IPC)
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

smp_host_response       STRUC

shr_link                        DW ?
shr_data                        smp_response <>

smp_host_response       ENDS

data    SEGMENT byte public 'DATA'

super_response_list     DW ?

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
        
        assume cs:code

        extrn FindHost:near
        extrn CalcChecksum:near
        extrn ReceiverAck:near
        extrn FindReceiveMailslotHost:near
        extrn FindReceiveMailslot:near
        extrn FindSendMailslot:near
        extrn HandleReset:near

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   CreateSegment
;
;       Purpose:                Create a segment
;
;       Parameters:             FS              Host data selector
;                                       CX              Size of data
;
;       Returns:                ES:DI   SMP header
;                                       ES:BX   SMP data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

smp_options     DB 0

        public CreateSegment

CreateSegment   Proc near
        push ds
        push ax
        push ecx
        push edx
        push esi
;
        mov ax,fs:shd_response_list
        or ax,ax
        jz create_segment_no_response
;
        mov ax,fs
        mov ds,ax
        EnterSection ds:shd_section
;
        push ds
        mov ax,ds:shd_response_list

create_segment_size_loop:
        or ax,ax
        jz create_segment_alloc
;
        mov ds,ax
        add cx,SIZE smp_response
        add cl,ds:shr_data.sr_size
        adc ch,0
        mov ax,ds:shr_link
        jmp create_segment_size_loop

create_segment_alloc:
        mov al,121
        mov ah,60
        mov bx,fs:shd_id
        inc bx
        mov fs:shd_id,bx
        xchg bl,bh
        add cx,SIZE smp_header
        movzx ecx,cx
        mov edx,fs:shd_ip
        mov si,cs
        mov ds,si
        mov esi,OFFSET smp_options
        CreateIpHeader
        pop ds
;
        mov ax,ds:shd_response_list
        xor dl,dl
        push ds
        push di
;
        add di,SIZE smp_header

create_segment_move_loop:
        or ax,ax
        jz create_segment_leave
;
        mov ds,ax
        mov cx,SIZE smp_response
        add cl,ds:shr_data.sr_size
        adc ch,0
        mov si,OFFSET shr_data
        rep movsb
        mov ax,ds:shr_link
        inc dl
        push es
        mov cx,ds
        mov es,cx
        xor cx,cx
        mov ds,cx
        FreeMem
        pop es
        jmp create_segment_move_loop

create_segment_leave:
        mov bx,di
        pop di
        pop ds
        mov ds:shd_response_list,0
        LeaveSection ds:shd_section
        mov es:[di].sh_responses,dl
        jmp create_segment_done

create_segment_no_response:
        mov al,121
        mov ah,60
        mov bx,fs:shd_id
        inc bx
        mov fs:shd_id,bx
        xchg bl,bh
        add cx,SIZE smp_header
        movzx ecx,cx
        mov edx,fs:shd_ip
        mov si,cs
        mov ds,si
        mov esi,OFFSET smp_options
        CreateIpHeader
        mov bx,di
        add bx,SIZE smp_header
        mov es:[di].sh_responses,0

create_segment_done:
        pop esi
        pop edx
        pop ecx
        pop ax
        pop ds
        ret
CreateSegment   Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   FlushResponses
;
;       Purpose:                Flush all responses
;
;       Parameters:             FS              Host data selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public FlushResponses

FlushResponses  Proc near
        push ds
        push es
        push ax
;
        mov ax,fs:shd_response_list
        or ax,ax
        jz flush_resp_done
;
        mov ax,fs
        mov ds,ax
        EnterSection ds:shd_section
;
        mov ax,ds:shd_response_list

flush_resp_loop:
        or ax,ax
        jz flush_resp_leave
;
        mov es,ax
        mov ax,es:shr_link
        FreeMem
        jmp flush_resp_loop

flush_resp_leave:
        mov ds:shd_response_list,0
        LeaveSection ds:shd_section

flush_resp_done:
        pop ax
        pop es
        pop ds
        ret
FlushResponses  Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   HandleAck
;
;       Purpose:                Handle ACK response
;
;       Parameters:             ES:SI   Response data
;                   EDX     IP source
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleAck       Proc near
        push ds
        push eax
        push bx
;
        mov bx,es:[si].sr_mailslot
        xchg bl,bh
;
        cmp es:[si].sr_size,4
        jnz handle_ack_done
;
        call FindReceiveMailslot
        jc handle_ack_done
;
        call FindReceiveMailslotHost
        jc handle_ack_done
;
        push gs
        mov gs,ax
        call ReceiverAck
        pop gs

handle_ack_done:
        pop bx
        pop eax
        pop ds
        ret
HandleAck       Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   HandleTooLarge
;
;       Purpose:                Handle too large message
;
;       Parameters:             ES:SI   Response data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTooLarge  Proc near
        ret
HandleTooLarge  Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   HandleBusy
;
;       Purpose:                Handle busy response
;
;       Parameters:             ES:SI   Response data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleBusy      Proc near
        int 3
        ret
HandleBusy      Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ActOnResponse
;
;       Purpose:                Act on a response
;
;       Parameters:             ES:SI   Response data
;                                       CX              Size of data
;                   EDX     IP source
;
;       Returns:                ES:SI   Next response
;                                       CX              Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResponseError   Proc near
        ret
ResponseError   Endp

ResponseTab:
rt00 DW OFFSET ResponseError
rt01 DW OFFSET HandleReset
rt02 DW OFFSET HandleAck
rt03 DW OFFSET HandleTooLarge
rt04 DW OFFSET HandleBusy
rt05 DW OFFSET ResponseError
rt06 DW OFFSET ResponseError
rt07 DW OFFSET ResponseError
rt08 DW OFFSET ResponseError
rt09 DW OFFSET ResponseError
rt0A DW OFFSET ResponseError
rt0B DW OFFSET ResponseError
rt0C DW OFFSET ResponseError
rt0D DW OFFSET ResponseError
rt0E DW OFFSET ResponseError
rt0F DW OFFSET ResponseError

ActOnResponse   Proc near
        push bx
;
        sub cx,SIZE smp_response
        jc act_on_response_done
        sub cl,es:[si].sr_size
        sbb ch,0
        jc act_on_response_done
;
        movzx bx,es:[si].sr_action
        cmp bx,10h
        cmc
        jc act_on_response_done
;
        add bx,bx
        call word ptr cs:[bx].ResponseTab
        movzx bx,es:[si].sr_size
        add si,SIZE smp_response
        add si,bx
        clc

act_on_response_done:
        pop bx
        ret
ActOnResponse   Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   HandleResponses
;
;       Purpose:                Handle responses
;
;       Parameters:             ES:DI   SMP header
;                                       CX              Size of data + header
;                   EDX     IP source
;
;       Returns:                ES:SI   SMP data
;                                       CX              Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public HandleResponses

HandleResponses Proc near 
        mov si,di
        add si,SIZE smp_header
        sub cx,SIZE smp_header
        jc handle_responses_done
;
        mov al,es:[di].sh_responses
        or al,al
        clc
        jz handle_responses_done

handle_responses_loop:
        call ActOnResponse
        jc handle_responses_done
;
        sub al,1
        jnz handle_responses_loop
        clc

handle_responses_done:
        ret
HandleResponses Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   QueueResponse
;
;       Purpose:                Queue a response
;
;       Parameters:             DS              Host data selector
;                                       ES              Response
;                                       EDX:EAX Response timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueueResponse   Proc near
        push bx
;
        EnterSection ds:shd_section
        push ax
        mov ax,ds:shd_response_list
        mov es:shr_link,ax
        mov ds:shd_response_list,es
        xor bx,bx
        mov es,bx
        or ax,ax
        pop ax
        jz queue_response_set_timeout
;
        sub eax,ds:shd_response_time
        sbb edx,ds:shd_response_time+4
        jnc queue_response_leave
;
        add eax,ds:shd_response_time
        adc edx,ds:shd_response_time+4

queue_response_set_timeout:             
        mov ds:shd_response_time,eax
        mov ds:shd_response_time+4,edx

queue_response_leave:
        xor ax,ax
        mov es,ax
        LeaveSection ds:shd_section
;
        pop bx
        ret
QueueResponse   Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   QueueReset
;
;       Purpose:                Queue reset message
;
;       Parameters:             DS              Host
;                                       BX              Mailslot
;                                       EDX             Connection # 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public QueueReset

QueueReset      Proc near
        push es
        push eax
        push bx
        push edx
;
        mov eax,SIZE smp_host_response
        AllocateSmallGlobalMem
        mov eax,edx
        Reverse
        mov es:shr_data.sr_connection,eax
        mov ax,bx
        xchg al,ah
        mov es:shr_data.sr_mailslot,ax
        mov es:shr_data.sr_size,0
        mov es:shr_data.sr_action,ACTION_RESET
;
        GetSystemTime
        add eax,ACK_DELAY * 1193
        adc edx,0
        call QueueResponse
;
        pop edx
        pop bx
        pop eax
        pop es
        ret
QueueReset      Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   QueueAck
;
;       Purpose:                Queue an ACK response
;
;       Parameters:             DS              Host
;                                       BX              Mailslot
;                                       ECX             Ack position
;                                       EDX             Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public QueueAck

QueueAck        Proc near
        push es
        push eax
        push bx
        push edx
;
        mov eax,SIZE smp_host_response + 4
        AllocateSmallGlobalMem
        mov eax,edx
        Reverse
        mov es:shr_data.sr_connection,eax
        mov ax,bx
        xchg al,ah
        mov es:shr_data.sr_mailslot,ax
        mov es:shr_data.sr_size,4
        mov es:shr_data.sr_action,ACTION_ACK
        mov bx,SIZE smp_host_response
        mov eax,ecx
        Reverse
        mov es:[bx],eax
;
        GetSystemTime
        add eax,ACK_DELAY * 1193
        adc edx,0
        call QueueResponse
;
        pop edx
        pop bx
        pop eax
        pop es
        ret
QueueAck        Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   QueueTooLarge
;
;       Purpose:                Queue too large message error
;
;       Parameters:             DS              Host
;                                       BX              Mailslot
;                                       EDX             Connection # 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public QueueTooLarge

QueueTooLarge   Proc near
        push es
        push eax
        push bx
        push edx
;
        mov eax,SIZE smp_host_response
        AllocateSmallGlobalMem
        mov eax,edx
        Reverse
        mov es:shr_data.sr_connection,eax
        mov ax,bx
        xchg al,ah
        mov es:shr_data.sr_mailslot,ax
        mov es:shr_data.sr_size,0
        mov es:shr_data.sr_action,ACTION_TOO_LARGE
;
        GetSystemTime
        add eax,ACK_DELAY * 1193
        adc edx,0
        call QueueResponse
;
        pop edx
        pop bx
        pop eax
        pop es
        ret
QueueTooLarge   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ResponseSupervise
;
;               DESCRIPTION:    Supervise response operations
;
;               PARAMETERS:             FS              Host
;                                               GS              IPC data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ResponseSupervise

ResponseSupervise       Proc near
        mov ax,fs:shd_response_list
        or ax,ax
        jz response_supervise_done
;
    push ds
    mov ax,fs
    mov ds,ax
        EnterSection ds:shd_section
;    
        GetSystemTime
        sub eax,fs:shd_response_time
        sbb edx,fs:shd_response_time+4
;
        LeaveSection ds:shd_section
        pop ds
        jc response_supervise_done
;
        mov ax,gs:super_response_list
        mov fs:shd_perform_list,ax
        mov gs:super_response_list,fs

response_supervise_done:
        ret
ResponseSupervise       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendResponses
;
;               DESCRIPTION:    Send responses through SMP
;
;               PARAMETERS:             FS              Host
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendResponses   Proc near
        xor ecx,ecx
        call CreateSegment
;
        xor eax,eax
        mov es:[di].sh_connection,eax
        mov es:[di].sh_offset_size,eax
        mov es:[di].sh_mailslot,ax
        mov es:[di].sh_flags,al
        mov es:[di].sh_checksum,ax
        add cx,bx
        sub cx,di
        mov ax,cx
        xchg al,ah
        mov es:[di].sh_size,ax
;
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
        ret
SendResponses   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ResponsePerform
;
;               DESCRIPTION:    Perform response operations
;
;               PARAMETERS:             GS              IPC data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ResponsePerform

ResponsePerform Proc near
        mov ax,gs:super_response_list

response_perform_loop:
        or ax,ax
        jz response_perform_done
;
        mov fs,ax
        call SendResponses
        mov ax,fs:shd_perform_list
        jmp response_perform_loop

response_perform_done:
        xor ax,ax
        mov fs,ax
        mov gs:super_response_list,ax
        ret
ResponsePerform Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init_smp_response
;
;               DESCRIPTION:    Init smp response module
;
;               PARAMETERS:             GS              IPC data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_smp_response

init_smp_response       Proc near
    mov ax,SEG data
    mov ds,ax
        mov ds:super_response_list,0
        ret
init_smp_response   Endp

code    ENDS

        END
