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
; ICMP.ASM
; ICMP protocol
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
INCLUDE tcp.inc

TYPE_ECHO_REPLY = 0
TYPE_UNREACHABLE = 3
TYPE_QUENCH = 4
TYPE_REDIRECT = 5
TYPE_ECHO_REQ = 8
TYPE_TIMEOUT = 11
TYPE_PARAMETER_ERROR = 12
TYPE_TIMESTAMP_REQ = 13
TYPE_TIMESTAMP_REPLY = 14
TYPE_INFO_REQ = 15
TYPE_INFO_REPLY = 16

icmp_header     STRUC

icmp_type           DB ?
icmp_code           DB ?
icmp_checksum   DW ?
icmp_data           DB ?

icmp_header     ENDS

Reverse MACRO
    xchg al,ah
    rol eax,16
    xchg al,ah
        ENDM

data    SEGMENT byte public 'DATA'

ping_section        section_typ <>
ping_thread             DW ?
ping_id             DD ?
ping_status             DB ?

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

    extrn RebindIP:near
    extrn IsDhcpActive:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CalcChecksum
;
;           DESCRIPTION:    Calculate checksum for TCP
;
;           PARAMETERS:         AX          Checksum in
;                           CX          Size of data
;                           ES:DI   Data
;
;           RETURNS:        AX          Checksum out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcChecksum    Proc near
    push ds
    push cx
    push dx
    push si
;
    mov si,es
    mov ds,si
    mov si,di
    mov dx,ax
    shr cx,1
    pushf
    clc
checksum_loop:
    lodsw
    adc dx,ax
    loop checksum_loop
    adc dx,0
    adc dx,0
    popf
    jnc calc_checksum_done
    xor ah,ah
    lodsb
    add dx,ax
    adc dx,0
    adc dx,0
calc_checksum_done:
    mov ax,dx
;
    pop si
    pop dx
    pop cx
    pop ds
    ret
CalcChecksum    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveEchoReply
;
;       Purpose:        Received echo reply from IP
;
;       Parameters:         ECX         Size of data
;                       EDX         Source IP address
;                       DS:ESI  Options
;                       ES:EDI  IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveEchoReply    Proc near
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:ping_thread
    or bx,bx
    jz receive_echo_reply_done
;
    mov eax,ds:ping_id
    cmp eax,dword ptr es:[edi].icmp_data
    jne receive_echo_reply_done
;
    mov ds:ping_status,1
    Signal

receive_echo_reply_done:
    ret
ReceiveEchoReply    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveEchoReq
;
;       Purpose:        Received echo from IP
;
;       Parameters:         ECX         Size of data
;                       EDX         Source IP address
;                       DS:ESI  Options
;                       ES:EDI  IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveEchoReq  Proc near
    push es
;
    call IsDhcpActive
    jc rerDone
;
    push es
    push edi
    mov si,es:[0]
    mov edx,es:[si].ip_source
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET PingOptions
    mov ah,20h
    mov al,1
    CreateIpHeader
    pop esi
    pop ds
    jc rerDone
;
    mov es:[di].icmp_type,0
    mov es:[di].icmp_code,0
    mov es:[di].icmp_checksum,0
;
    push cx
    push si
    push di
    add si,4
    add di,4
    sub cx,4
    rep movsb
    pop di
    pop si
    pop cx
;
    xor ax,ax
    call CalcChecksum
    not ax
    mov es:[di].icmp_checksum,ax
;        
    SendIp

rerDone:
    pop es
    ret
ReceiveEchoReq  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveUnreachable
;
;       Purpose:        Received unreachable msg
;
;       Parameters:     ECX         Size of data
;                       EDX         Source IP address
;                       DS:ESI      Options
;                       ES:EDI      IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveUnreachable    Proc near
    mov al,es:[edi+1]
    cmp al,4
    jne ruDone
; 
    add edi,8
    mov al,es:[edi].ip_proto
    cmp al,6
    jne ruDone
;
    mov ax,es:[edi-2]
    xchg al,ah
    mov cx,ax
;    
    mov edx,es:[edi].ip_dest
    add edi,SIZE ip_header
    mov ax,es:[edi].tcp_dest
    xchg al,ah
    mov di,ax
    UpdateTcpMtu
    
ruDone:
    ret
ReceiveUnreachable    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           Receive
;
;       Purpose:        Receive notify from IP
;
;       Parameters:         AX          Size of options
;                       ECX         Size of data
;                       EDX         Source IP address
;                       DS:ESI  Options
;                       ES:EDI  IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveDiscard  Proc near
    ret
ReceiveDiscard  Endp

ReceiveTab:
rt00 DW OFFSET ReceiveEchoReply
rt01 DW OFFSET ReceiveDiscard
rt02 DW OFFSET ReceiveDiscard
rt03 DW OFFSET ReceiveUnreachable
rt04 DW OFFSET ReceiveDiscard
rt05 DW OFFSET ReceiveDiscard
rt06 DW OFFSET ReceiveDiscard
rt07 DW OFFSET ReceiveDiscard
rt08 DW OFFSET ReceiveEchoReq
rt09 DW OFFSET ReceiveDiscard
rt0A DW OFFSET ReceiveDiscard
rt0B DW OFFSET ReceiveDiscard
rt0C DW OFFSET ReceiveDiscard
rt0D DW OFFSET ReceiveDiscard
rt0E DW OFFSET ReceiveDiscard
rt0F DW OFFSET ReceiveDiscard

Receive Proc far
    push ax
    push bx
;
    xor ax,ax
    call CalcChecksum
    not ax
    or ax,ax
    jnz receive_done
;
    movzx bx,es:[di].icmp_type
    cmp bl,16
    ja receive_done
;
    shl bx,1
    call word ptr cs:[bx].ReceiveTab

receive_done:
    pop bx
    pop ax
    retf32
Receive Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           Ping
;
;       Purpose:        Ping node
;
;       Parameters:         EAX         Timeout in ms
;                       EDX         Dest IP address
;
;       Returns:        NC          Ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ping_name       DB 'Ping',0

PingTimeout     Proc far
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:ping_thread
    Signal
    retf32
PingTimeout     Endp

PingOptions DB 0

ping_node Proc far 
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    push eax
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:ping_section
    push edx
    GetSystemTime
    mov ds:ping_id,eax
    mov ebp,eax
    GetThread
    mov ds:ping_thread,ax
    mov ds:ping_status,0
    ClearSignal
;
    mov dx,cs
    mov ds,dx
    mov esi,OFFSET PingOptions
    pop edx
    mov ah,20h
    mov al,1
    mov ecx,40
    CreateIpHeader
    jc ping_pop_fail
;
    mov es:[di].icmp_type,8
    mov es:[di].icmp_code,0
    mov es:[di].icmp_checksum,0
    mov dword ptr es:[di].icmp_data,ebp
    push cx
    push di
    add di,8
    mov cx,32
    mov al,'r'
    rep stosb
    pop di
    pop cx
    xor ax,ax
    call CalcChecksum
    not ax
    mov es:[di].icmp_checksum,ax
    SendIp
;
    mov ax,SEG data
    mov ds,ax
    mov ax,cs
    mov es,ax
    mov edi,OFFSET PingTimeout
    pop eax
;
    push edx
    mov edx,1192
    mul edx
    mov ecx,eax
    GetSystemTime
    add eax,ecx
    adc edx,0
    mov bx,ds:ping_thread
    StartTimer
    WaitForSignal
    StopTimer
    pop edx
;
    mov ds:ping_thread,0
    mov al,ds:ping_status
    LeaveSection ds:ping_section
;
    or al,al
    jz ping_fail
;
    clc
    jmp ping_done

ping_fail:
    call RebindIP
    stc
    jmp ping_done
    
ping_pop_fail:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:ping_section
    pop eax

ping_done:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
ping_node       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init ICMP driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task_icmp

init_task_icmp       PROC near
    mov ax,SEG data
    mov ds,ax
    InitSection ds:ping_section
    mov ds:ping_thread,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov al,1
    mov edi,OFFSET Receive
    HookIp
;
    mov esi,OFFSET ping_node
    mov edi,OFFSET ping_name
    xor dx,dx
    mov ax,ping_nr
    RegisterBimodalUserGate
    ret
init_task_icmp       ENDP

code    ENDS

    END
