;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
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
; UDP.ASM
; UDP protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE exec.def
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE udp.inc

RESEND_TIMEOUT  EQU 2000        ; 2000 ms

Reverse MACRO
    xchg al,ah
    rol eax,16
    xchg al,ah
        ENDM

    extrn ReceiveClientDhcp:near
    extrn ReceiveServerDhcp:near

data    SEGMENT byte public 'DATA'

curr_port           DW ?
query_free          DW ?
query_head          DW ?
udp_section         section_typ <>
listen_list         DW ?
udp_queries         DB UDP_QUERY_ENTRIES * SIZE udp_query DUP(?)

data    ENDS


code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CalcChecksum
;
;           DESCRIPTION:    Calculate checksum for UDP
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
;       Name:           AllocateQuery
;
;       Purpose:        Allocate query
;
;       Returns:        BX          Query entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQuery   Proc near
    push si
    cli
    mov bx,ds:query_free
    mov si,ds:[bx].udp_query_next
    mov ds:query_free,si
    sti
    pop si
    ret
AllocateQuery   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FreeQuery
;
;       Purpose:        Free query
;
;       Parameters:         BX          Query entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeQuery       Proc near
    push si
    cli
    mov si,ds:query_free
    mov ds:[bx].udp_query_next,si
    mov ds:query_free,bx
    sti
    pop si
    ret
FreeQuery       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           InsertQuery
;
;       Purpose:        Insert query
;
;       Parameters:         BX          Query entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertQuery     Proc near
    push si
    cli
    mov si,ds:query_head
    mov ds:[bx].udp_query_next,si
    mov ds:query_head,bx
    sti
    pop si
    ret
InsertQuery     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RemoveQuery
;
;       Purpose:        Remove query
;
;       Parameters:         CX          Port #
;
;       Returns:        BX          Query entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveQuery     Proc near
    push si
;
    mov bx,OFFSET query_head
    cli
remove_next:
    mov si,bx
    mov bx,ds:[bx].udp_query_next
    or bx,bx
    je remove_fail
    cmp cx,ds:[bx].udp_query_port
    jne remove_next
remove_this:
    mov ax,ds:[bx].udp_query_next
    mov ds:[si].udp_query_next,ax
    sti
    clc
    jmp remove_done

remove_fail:
    sti
    stc

remove_done:
    pop si
    ret
RemoveQuery     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           Timeout
;
;       Purpose:        Expired timer
;
;       Parameters:         CX          Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Timeout Proc far
    mov ax,SEG data
    mov ds,ax
    call RemoveQuery
    jc udp_timeout_done
    mov bx,ds:[bx].udp_query_thread
    Signal

udp_timeout_done:
    retf32
Timeout Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           StartTimeout
;
;       Purpose:        Start timer
;
;       Parameters:         EAX             Timeout in ms
;                       BX              Query buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartTimeout    Proc near
    push es
    push eax
    push bx
    push cx
    push edx
    push edi
;
    mov edx,1193
    mul edx
    push edx
    push eax
    GetThread
    mov ds:[bx].udp_query_thread,ax
    mov ax,cs
    mov es,ax
    GetSystemTime
    pop edi
    add eax,edi
    pop edi
    adc edx,edi
    mov edi,OFFSET Timeout
    mov cx,ds:[bx].udp_query_port
    mov bx,ds:[bx].udp_query_thread
    StartTimer
;
    pop edi
    pop edx
    pop cx
    pop bx
    pop eax
    pop es
    ret
StartTimeout    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           QueryUdp
;
;       Purpose:        Query UDP port
;
;       Parameters:         EAX             Timeout in ms
;                       BX              destination port
;                       EDX             IP-address
;                       CX              Number of bytes to send
;                       ES:EDI      Query buffer
;
;       Returns:        NC              Ok
;                       CX              Number of bytes received
;                       ES:DI       Answer buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

query_udp_name DB 'Query UDP',0

ip_options      DB 0

query_udp       Proc far
    push ds
    push fs
    push eax
    push bx
    push dx
    push esi
;
    push es
    push ecx
    push edi
;
    push bx
    mov bx,es
    mov fs,bx
    mov bx,SEG data
    mov ds,bx
    call AllocateQuery
    or bx,bx
    jz udp_query_pop_fail
;
    push ds
    push ax
    push edi
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET ip_options
    mov al,17
    mov ah,30
    add ecx,SIZE udp_header
    CreateIpHeader
    pop esi
    pop ax
    pop ds
    jc udp_query_pop_fail
;       
    pop dx
    xchg dl,dh
    mov es:[edi].udp_dest,dx
    push cx
    cli
    mov cx,ds:curr_port
    inc cx
    or cx,cx
    jnz udp_query_port_ok
    mov cx,8000h
udp_query_port_ok:
    mov ds:curr_port,cx
    sti
    mov ds:[bx].udp_query_port,cx
    xchg cl,ch
    mov es:[edi].udp_source,cx
    pop cx
;
    xchg cl,ch
    mov es:[edi].udp_len,cx
    xchg cl,ch
;
    push cx
    push di
    sub cx,SIZE udp_header
    add di,SIZE udp_header
    rep movs byte ptr es:[edi],fs:[esi]
    pop di
    pop cx
;
    push ax
    mov es:[di].udp_checksum,0
    mov ax,cx
    xchg al,ah
    add ax,1100h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add di,8
    mov es:[di].udp_checksum,ax
    sub cx,8
    pop ax
;
    mov ds:[bx].udp_query_sel,-1
    mov ds:[bx].udp_query_offset,0
    ClearSignal
    call InsertQuery
    call StartTimeout
    SendIp
    WaitForSignal
;
    xor ax,ax
    xchg ax,ds:[bx].udp_query_sel
    cmp ax,-1
    je udp_query_failed
;
    mov es,ax
    mov di,ds:[bx].udp_query_offset
    movzx ecx,es:[di].udp_len
    xchg cl,ch
    sub cx,SIZE udp_header
    add di,SIZE udp_header
    call FreeQuery
    add sp,10
    clc
    jmp udp_query_done
    pop edi
    pop ecx
    pop es
    stc
    jmp udp_query_done

udp_query_pop_fail:
    pop dx

udp_query_failed:
    call FreeQuery
    pop edi
    pop ecx
    pop es
    stc

udp_query_done:
    pop esi
    pop dx
    pop bx
    pop eax
    pop fs
    pop ds  
    ret
query_udp       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindListen
;
;       Purpose:        Look for a listen request
;
;       Parameters:         SI          local port
;                       
;       Returns:        NC          connection found
;                       DS          listen request
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindListen      Proc near
    push es
    push ax
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:udp_section
    mov ax,ds:listen_list

find_listen_loop:
    or ax,ax
    jz find_listen_fail
;
    mov es,ax
    cmp si,es:udp_listen_port
    je find_listen_ok
find_listen_next:
    mov ax,es:udp_listen_next
    jmp find_listen_loop

find_listen_fail:
    LeaveSection ds:udp_section
    stc
    jmp find_listen_done

find_listen_ok:
    LeaveSection ds:udp_section
    mov ax,es
    mov ds,ax
    clc

find_listen_done:
    pop ax
    pop es
    ret
FindListen      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           Receive
;
;       Purpose:        Receive notify from IP
;
;       Parameters:         FS      Protocol handle
;           GS      Driver handle
;           AX      Size of options
;                       ECX         Size of data
;                       EDX         Source IP address
;                       DS:ESI  Options
;                       ES:EDI  IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive Proc far
    push ax
    push bx
    push cx
    push dx
    push si
    push di
;
    push di
    mov dx,cx
    xchg dl,dh
    add dx,1100h
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
    pop di
    jnz receive_free
;
    mov ax,SEG data
    mov ds,ax
    mov ax,es:[di].udp_source
    xchg al,ah
;
    cmp ax,67
    jne receive_not_cl_dhcp
;
    call ReceiveClientDhcp
    jmp receive_done

receive_not_cl_dhcp:
    cmp ax,68
    jne receive_not_dhcp
;
    call ReceiveServerDhcp
    jmp receive_done

receive_not_dhcp:
    mov ax,es:[di].udp_dest
    xchg al,ah
    test ax,8000h
    jz receive_not_query
;
    push cx
    mov cx,ax
    call RemoveQuery
    pop cx
    jc receive_free
;
    mov ax,ds:[bx].udp_query_sel
    cmp ax,-1
    jne receive_free
;
    mov ds:[bx].udp_query_sel,es
    mov ds:[bx].udp_query_offset,di
    mov bx,ds:[bx].udp_query_thread
    xor ax,ax
    mov es,ax
    StopTimer
    Signal
    jmp receive_done

receive_not_query:
    mov si,ax
    call FindListen
    jc receive_free
;
    push ds
    push es
    push di
;
    mov cx,es:[di].udp_len
    xchg cl,ch
    sub cx,SIZE udp_header
    add di,SIZE udp_header
    call dword ptr ds:udp_listen_callback
;
    mov ax,es
    mov fs,ax
;
    pop di
    pop es
    pop ds
;
    mov edx,es:ip_source
    push es
    push di
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET ip_options
    mov al,17
    mov ah,30
    add cx,SIZE udp_header
    movzx ecx,cx
    CreateIpHeader
    pop si
    jc receive_pop_free
;
    push cx
    push si
    push di
    sub cx,SIZE udp_header
    xor si,si
    add di,SIZE udp_header
    rep movs byte ptr es:[di],fs:[si]
    pop di
    pop si
    pop cx
;
    pop ds
    mov ax,ds:[si].udp_source
    mov es:[di].udp_dest,ax
    mov ax,ds:[si].udp_dest
    mov es:[di].udp_source,ax
    xchg cl,ch
    mov es:[di].udp_len,cx
    xchg cl,ch
;
    mov es:[di].udp_checksum,0
    mov ax,cx
    xchg al,ah
    add ax,1100h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add di,8
    mov es:[di].udp_checksum,ax
    SendIp
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    mov ax,ds
    mov es,ax
    jmp receive_free

receive_pop_free:
    pop es

receive_free:
    xor ax,ax
    mov ds,ax
    FreeMem

receive_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    retf32
Receive Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ListenUdpPort
;
;       Purpose:        Listen on a udp port
;
;       Parameters:         SI                  local port
;                       ES:DI           connection callback
;                           IN      CX          UDP request size
;                           IN      ES:DI   UDP request data
;                           OUT     CX          UDP reply size
;                           OUT     ES:DI   UDP reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

listen_udp_port_name    DB 'Listen UDP Port',0

listen_udp_port Proc far
    push ds
    push es
    push eax
    push cx
;
    mov cx,es
    mov eax,SIZE udp_listen
    AllocateSmallGlobalMem
    mov es:udp_listen_callback,di
    mov es:udp_listen_callback+2,cx
    mov es:udp_listen_port,si
;
    mov ax,es
    mov ds,ax
    InitSection ds:udp_listen_section
;       
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:udp_section
    mov ax,ds:listen_list
    mov es:udp_listen_next,ax
    mov ds:listen_list,es
    LeaveSection ds:udp_section
;
    pop cx
    pop eax
    pop es
    pop ds  
    ret
listen_udp_port Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_udp
;
;           DESCRIPTION:    Init udp driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_udp

init_udp    PROC near
    push ds
    push es
    pusha
;
    mov bx,SEG data
    mov ds,bx
    mov es,bx
;
    InitSection ds:udp_section
    mov ds:listen_list,0
    mov cx,UDP_QUERY_ENTRIES - 1
    mov bx,OFFSET udp_queries
    mov ds:query_head,0
    mov ds:query_free,bx
query_list_create:
    mov ax,bx
    add ax,SIZE udp_query
    mov ds:[bx].udp_query_next,ax
    mov bx,ax
    loop query_list_create
    mov ds:[bx].udp_query_next,0
    mov ds:curr_port,7FFFh
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET query_udp
    mov edi,OFFSET query_udp_name
    xor cl,cl
    mov ax,query_udp_nr
    RegisterOldOsGate
;
    mov esi,OFFSET listen_udp_port
    mov edi,OFFSET listen_udp_port_name
    xor cl,cl
    mov ax,listen_udp_port_nr
    RegisterOldOsGate
;
    mov al,17
    mov edi,OFFSET Receive
    HookIp
;
    popa
    pop es
    pop ds
    ret
init_udp    ENDP

code    ENDS

    END
