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
; SMP.ASM
; Simple message protocol implementation
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

data    SEGMENT byte public 'DATA'

ipc_cache_offset    DW ?
smp_host_section    section_typ <>
smp_host_list       DW ?
smp_thread      DW ?

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

    extrn init_smp_response:near
    extrn init_smp_send:near
    
    extrn EnterIpcSection:near
    extrn LeaveIpcSection:near
    extrn QueryMailslot:near
    extrn AllocateIpcHandle:near
    extrn QueueReset:near
    extrn HandleResponses:near
    extrn ReceiveRequest:near
    extrn ReceiveReply:near
    extrn GetSendMailslot:near
    extrn NameRequest:near
    extrn NameReply:near
    extrn ReceiveSupervise:near
    extrn SendSupervise:near
    extrn SendPerform:near
    extrn ResponseSupervise:near
    extrn ResponsePerform:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CalcChecksum
;
;           DESCRIPTION:    Calculate checksum for SMP
;
;           PARAMETERS:         AX          Checksum in
;                           CX          Size of data
;                           ES:DI   Data
;
;           RETURNS:        AX          Checksum out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CalcChecksum

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindHost
;
;           DESCRIPTION:    Find a SMP host
;
;           PARAMETERS:         EDX         IP
;
;           RETURNS:        AX          SMP host selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FindHost

FindHost    Proc near
    push ds
    push es
    push bx
    push edi
;
    LookupIpCache
    jc find_host_done
;
    mov ax,SEG data
    mov ds,ax
    call EnterIpcSection
;
    mov bx,ds:ipc_cache_offset
    mov ax,es:[bx]
    or ax,ax
    jnz find_host_buffered
;
    push fs
    mov ax,es
    mov fs,ax
    mov eax,SIZE smp_host_data
    AllocateSmallGlobalMem
    push ds
    mov ax,es
    mov ds,ax
    mov ds:shd_mailslot_list,0
    mov ds:shd_response_list,0
    mov ds:shd_ip,edx
    mov ds:shd_host,fs
    mov ds:shd_sign,HOST_SIGN
    InitSection ds:shd_section
    pop ds
;
    EnterSection ds:smp_host_section    
    mov ax,ds:smp_host_list
    mov es:shd_link,ax
    mov ds:smp_host_list,es
    mov ax,es
    mov fs:[bx],ax
    pop fs
    LeaveSection ds:smp_host_section

find_host_buffered:
    call LeaveIpcSection
    clc

find_host_done:
    pop edi
    pop bx
    pop es
    pop ds
    ret
FindHost    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetRemoteMailslot
;
;           DESCRIPTION:    Get remote mailslot from host & name
;
;           PARAMETERS:         EDX             IP address
;                           ES:(E)DI    Mailslot name
;
;           RETURNS:        BX              Mailslot handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_remote_mailslot_name    DB 'Get Remote Mailslot',0

get_remote_mailslot32   Proc far
    call GetSendMailslot
    retf32
get_remote_mailslot32   Endp

get_remote_mailslot16   Proc far
    push edi
    movzx edi,di
    call GetSendMailslot
    pop edi
    retf32
get_remote_mailslot16   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           Receive
;
;       Purpose:        Receive notify from IP
;
;       Parameters:     AX          Size of options
;                       ECX         Size of data
;                       EDX         Source IP address
;                       DS:ESI  Options
;                       ES:EDI  IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive Proc far
    push ax
    push cx
    push dx
    push si
    push di
;
    push di
    push dx
    mov dx,cx
    xchg dl,dh
    add dx,7900h
    adc dx,0
    adc dx,0
    sub si,8
    lodsw
    add dx,ax
    lodsw
    adc dx,ax
    lodsw
    adc dx,ax
    lodsw
    adc dx,ax
    mov ax,dx
    adc ax,0
    adc ax,0
    mov si,di
    call CalcChecksum
    not ax
    or al,ah
    pop dx
    pop di
    jnz receive_free
;
    mov al,es:[di].sh_flags
;
    test al,NAM
    jnz receive_name
;
    test al,REQ
    jnz receive_request
;
    and al,REQ OR RPY
    cmp al,REQ OR RPY
    je receive_free
;
    test al,RPY
    jnz receive_reply
    jmp receive_responses

receive_name:
    and al,REQ OR RPY
    cmp al,REQ OR RPY
    je receive_free
;
    test al,REQ
    jnz receive_name_request
;
    test al,RPY
    jnz receive_name_reply
    jmp receive_responses

receive_name_request:
    call HandleResponses
    jc receive_free
;
    call NameRequest
    jmp receive_free

receive_name_reply:
    call HandleResponses
    jc receive_free
;
    call NameReply
    jmp receive_free

receive_request:
    call HandleResponses
    jc receive_free
;
    call ReceiveRequest
    jmp receive_free

receive_reply:
    call HandleResponses
    jc receive_free
;
    call ReceiveReply
    jmp receive_free

receive_responses:
    call HandleResponses

receive_free:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    retf32
Receive Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           add_host
;
;           DESCRIPTION:    add host from IP cache
;
;           PARAMETERS:     ES          IP cache selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_host    PROC far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:ipc_cache_offset
    mov word ptr es:[bx],0
;
    pop bx
    pop ds
    retf32
add_host    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Supervise
;
;           DESCRIPTION:    Supervise send and response operations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Supervise       Proc near
    xor cx,cx
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:smp_host_section
    mov ax,ds:smp_host_list

supervise_loop:
    or ax,ax
    jz supervise_leave
;
    inc cx
    mov fs,ax
    push ds
    push cx
    call SendSupervise
    call ResponseSupervise
    pop cx
    pop ds
    mov ax,fs:shd_link
    jmp supervise_loop

supervise_leave:
    xor ax,ax
    mov fs,ax
    LeaveSection ds:smp_host_section
;
    or cx,cx
    stc
    jz supervise_done
;
    call SendPerform
    call ResponsePerform
    clc

supervise_done:
    ret
Supervise       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSmpThread
;
;           DESCRIPTION:    Get smp thread sel
;
;       PARAMETERS:     
;
;           RETURNS:        BX      Smp thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetSmpThread

GetSmpThread    Proc near
    push ds
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:smp_thread
    pop ds
    ret
GetSmpThread    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           smp_thread
;
;           DESCRIPTION:    supervisor thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

smp_thread_name DB 'SMP',0

smp_thread_pr:
    mov ax,SEG data
    mov ds,ax
    mov gs,ax
    GetThread
    mov ds:smp_thread,ax

smp_thread_loop:
    mov eax,100
    WaitMilliSec
;
    call ReceiveSupervise
    jc smp_thread_no_receive
;
    call Supervise
    jmp smp_thread_loop

smp_thread_no_receive:
    call Supervise
    jnc smp_thread_loop
;
    WaitForSignal
    jmp smp_thread_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_system
;
;           DESCRIPTION:    Create supervisor thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_system     Proc far
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET smp_thread_pr
    mov di,OFFSET smp_thread_name
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_system     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_smp
;
;           DESCRIPTION:    Init smp driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_smp

init_smp    PROC near
    mov ax,2
    AllocateIpCacheMem
;
    mov ax,SEG data
    mov ds,ax
    mov ds:ipc_cache_offset,bx
    mov ds:smp_host_list,0
    mov ds:smp_thread,0
    InitSection ds:smp_host_section
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_system
    HookInitTasking
;
    mov al,79h
    mov edi,OFFSET Receive
    HookIp
;
    mov edi,OFFSET add_host
    HookIpCache
;
    mov ebx,OFFSET get_remote_mailslot16
    mov esi,OFFSET get_remote_mailslot32
    mov edi,OFFSET get_remote_mailslot_name
    mov dx,virt_es_in
    mov ax,get_remote_mailslot_nr
    RegisterUserGate
;       
    call init_smp_response
    call init_smp_send
    ret
init_smp    ENDP

code    ENDS

    END
