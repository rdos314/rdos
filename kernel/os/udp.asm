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
; UDP.ASM
; UDP protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc
include ..\wait.inc
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE udp.inc

BROADCAST_QUERY_PORT    EQU 4094


RESEND_TIMEOUT  EQU 2000        ; 2000 ms

Reverse MACRO
    xchg al,ah
    rol eax,16
    xchg al,ah
        ENDM

udp_wait_header STRUC

uw_obj          wait_obj_header <>
uw_handle       DW ?

udp_wait_header ENDS

udp_handle_seg      STRUC

udp_handle_base     handle_header <>
udp_handle_sel      DW ?

udp_handle_seg      ENDS

udp_listen_header STRUC

ulw_obj              wait_obj_header <>
ulw_handle           DW ?

udp_listen_header ENDS

listen_handle_seg           STRUC

listen_handle_base      handle_header <>
listen_handle_sel       DW ?

listen_handle_seg           ENDS

listen_data_seg     STRUC

listen_size     DW ?
listen_ip       DD ?
listen_port     DW ?
listen_data     DB ?

listen_data_seg ENDS

udp_connection  STRUC

udp_next                DW ?
udp_port                DW ?
udp_remote_ip           DD ?
udp_remote_port         DW ?
udp_wait                DW ?
udp_data_sel            DW ?
udp_data_size           DW ?
udp_conn_section        section_typ <>

udp_connection  ENDS

    extrn ReceiveClientDhcp:near
    extrn ReceiveServerDhcp:near

data    SEGMENT byte public 'DATA'

curr_port           DW ?
query_free          DW ?
query_head          DW ?
udp_spinlock        spinlock_typ <>
udp_section         section_typ <>
bq_section          section_typ <>
bq_ip               DD ?
bq_req_size         DD ?
bq_reply_size       DD ?
bq_req_offset       DD ?
bq_req_sel          DW ?
bq_reply_sel        DW ?
bq_source_port      DW ?
bq_dest_port        DW ?
bq_thread           DW ?
listen_list         DW ?
connection_list     DW ?
udp_queries         DB UDP_QUERY_ENTRIES * SIZE udp_query DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF
    
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CalcUdpCheckSum
;
;           DESCRIPTION:    Calculate checksum for UDP
;
;           PARAMETERS:     ES:DI       Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CalcUdpCheckSum

CalcUdpCheckSum    Proc near
    push dx
    push si
;
    mov es:[di].udp_checksum,0
    mov cx,es:[edi].udp_len
    mov dx,cx
    xchg cl,ch
    add dx,1100h
    adc dx,0
    adc dx,0
    mov si,di
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
    call CalcChecksum
    not ax
    mov es:[di].udp_checksum,ax
;
    pop si
    pop dx
    ret
CalcUdpCheckSum  Endp
        
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
    RequestSpinlock ds:udp_spinlock
    mov bx,ds:query_free
    mov si,ds:[bx].udp_query_next
    mov ds:query_free,si
    ReleaseSpinlock ds:udp_spinlock
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
    RequestSpinlock ds:udp_spinlock
    mov si,ds:query_free
    mov ds:[bx].udp_query_next,si
    mov ds:query_free,bx
    ReleaseSpinlock ds:udp_spinlock
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
    RequestSpinlock ds:udp_spinlock
    mov si,ds:query_head
    mov ds:[bx].udp_query_next,si
    mov ds:query_head,bx
    ReleaseSpinlock ds:udp_spinlock
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
    push di
;
    mov bx,OFFSET query_head
    mov di,cx
    mov cx,UDP_QUERY_ENTRIES
    RequestSpinlock ds:udp_spinlock

remove_next:
    mov si,bx
    mov bx,ds:[bx].udp_query_next
    or bx,bx
    je remove_fail
;    
    cmp di,ds:[bx].udp_query_port
    je remove_this
;
    loop remove_next    
;
    jmp remove_fail
    
remove_this:
    mov ax,ds:[bx].udp_query_next
    mov ds:[si].udp_query_next,ax
    ReleaseSpinlock ds:udp_spinlock
    clc
    jmp remove_done

remove_fail:
    ReleaseSpinlock ds:udp_spinlock
    stc

remove_done:
    pop di
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
;       Parameters:     EAX             Timeout in ms
;                       BX              destination port
;                       EDX             IP-address
;                       CX              Number of bytes to send
;                       ES:EDI          Query buffer
;
;       Returns:        NC              Ok
;                       CX              Number of bytes received
;                       ES:EDI          Answer buffer
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
;
    RequestSpinlock ds:udp_spinlock    
    mov cx,ds:curr_port
    inc cx
    or cx,cx
    jnz udp_query_port_ok
;    
    mov cx,8000h

udp_query_port_ok:
    mov ds:curr_port,cx
    ReleaseSpinlock ds:udp_spinlock
;        
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
    movzx edi,di
    clc
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
    retf32
query_udp       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendUdp
;
;       Purpose:        Send UDP data
;
;       Parameters:     SI              source port
;                       BX              destination port
;                       EDX             IP-address
;                       (E)CX           Number of bytes to send
;                       ES:(E)DI        Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_udp_name DB 'Send UDP',0

send_udp       Proc near
    push ds
    push es
    pushad
;
    push es
    push edi
    push si
;
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET ip_options
    mov al,17
    mov ah,30
    add ecx,SIZE udp_header
    CreateIpHeader
;    
    pop ax
    pop esi
    pop ds
    jc send_udp_done
;       
    xchg al,ah
    mov es:[edi].udp_source,ax
;    
    mov ax,bx
    xchg al,ah
    mov es:[edi].udp_dest,ax
;
    xchg cl,ch
    mov es:[edi].udp_len,cx
    xchg cl,ch
;
    push ecx
    push edi
    sub ecx,SIZE udp_header
    add edi,SIZE udp_header
    rep movs byte ptr es:[edi],[esi]
    pop edi
    pop ecx
;
    mov es:[edi].udp_checksum,0
    mov ax,cx
    xchg al,ah
    add ax,1100h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add edi,8
    mov es:[edi].udp_checksum,ax
    sub ecx,8
    SendIp

send_udp_done:
    popad
    pop es
    pop ds    
    ret
send_udp       Endp

send_udp16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call send_udp    
;
    pop edi
    pop ecx
    retf32    
send_udp16   Endp

send_udp32   Proc far
    call send_udp    
    retf32    
send_udp32   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           BroadcastDriverUdp
;
;       Purpose:        Broadcast driver UDP data
;
;       Parameters:     SI              source port
;                       BX              destination port
;                       FS              Driver sel
;                       ECX             Number of bytes to send
;                       ES:EDI          Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

broadcast_driver_udp_name DB 'Broadcast Driver UDP',0

broadcast_driver_udp       Proc far
    push ds
    push es
    push fs
    pushad
;
    push es
    push edi
    push si
;
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET ip_options
    mov al,17
    mov ah,30
    add ecx,SIZE udp_header
    CreateBroadcastIp
;    
    pop ax
    pop esi
    pop ds
    jc broadcast_driver_udp_done
;       
    xchg al,ah
    mov es:[edi].udp_source,ax
;    
    mov ax,bx
    xchg al,ah
    mov es:[edi].udp_dest,ax
;
    xchg cl,ch
    mov es:[edi].udp_len,cx
    xchg cl,ch
;
    push ecx
    push edi
    sub ecx,SIZE udp_header
    add edi,SIZE udp_header
    rep movs byte ptr es:[edi],[esi]
    pop edi
    pop ecx
;
    mov es:[edi].udp_checksum,0
    mov ax,cx
    xchg al,ah
    add ax,1100h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add edi,8
    mov es:[edi].udp_checksum,ax
    sub ecx,8
    SendBroadcastIp

broadcast_driver_udp_done:
    popad
    pop fs
    pop es
    pop ds    
    retf32
broadcast_driver_udp       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendDriverUdp
;
;       Purpose:        Send UDP data to specific driver
;
;       Parameters:     AX              source port
;                       BX              destination port
;                       ECX             Number of bytes to send
;                       EDX             IP
;                       ES:EDI          Buffer
;                       FS              Driver
;                       DS:ESI          Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_driver_udp_name DB 'Send Driver UDP',0

send_driver_udp       Proc far
    push es
    push fs
    pushad
;
    push ds
    push esi
;    
    push es
    push edi
    push ax
;
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET ip_options
    mov al,17
    mov ah,30
    add ecx,SIZE udp_header
    CreateDriverIp
;    
    pop ax
    pop esi
    pop ds
    jc send_driver_udp_pop_fail
;       
    xchg al,ah
    mov es:[edi].udp_source,ax
;    
    mov ax,bx
    xchg al,ah
    mov es:[edi].udp_dest,ax
;
    xchg cl,ch
    mov es:[edi].udp_len,cx
    xchg cl,ch
;
    push ecx
    push edi
    sub ecx,SIZE udp_header
    add edi,SIZE udp_header
    rep movs byte ptr es:[edi],[esi]
    pop edi
    pop ecx
;
    mov es:[edi].udp_checksum,0
    mov ax,cx
    xchg al,ah
    add ax,1100h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add edi,8
    mov es:[edi].udp_checksum,ax
    sub ecx,8
;
    pop esi
    pop ds    
    SendDriverIp
    jmp send_driver_udp_done

send_driver_udp_pop_fail:
    pop esi
    pop ds

send_driver_udp_done:
    popad
    pop fs
    pop es
    retf32
send_driver_udp       Endp

        
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
;       Name:           ListenUdpPort
;
;       Purpose:        Listen on a udp port
;
;       Parameters:     SI                  local port
;                       ES:EDI              connection callback
;                           IN      CX      UDP request size
;                           IN      ES:EDI  UDP request data
;                           OUT     CX      UDP reply size
;                           OUT     ES:EDI  UDP reply data
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
    mov dword ptr es:udp_listen_callback,edi
    mov word ptr es:udp_listen_callback+4,cx
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
    retf32
listen_udp_port Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           broadcast_listen_callback
;
;       Purpose:        Broadcast listen callback
;
;       Parameters:     CX      UDP request size
;                       EDX     IP
;                       ES:EDI  UDP request data
;
;       Returns:        CX      UDP reply size
;                       ES:EDI  UDP reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

broadcast_listen_callback   Proc far
    push ds
    push eax
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:bq_thread
    or ax,ax
    jz blcDone
;
    push es
    push fs
    push esi
;
    movzx ecx,cx
    mov ax,es    
    mov fs,ax
    mov esi,edi
;
    mov eax,ecx
    AllocateSmallGlobalMem
    mov ds:bq_reply_size,ecx
    mov ds:bq_ip,edx
;    
    xor edi,edi
    rep movs byte ptr es:[edi],fs:[esi]
    mov ds:bq_reply_sel,es
;
    pop esi
    pop fs
    pop es
;
    push bx
    xor bx,bx
    xchg bx,ds:bq_thread
    Signal
    pop bx                

blcDone:
    xor ecx,ecx
;    
    pop eax
    pop ds        
    retf32
broadcast_listen_callback   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           broadcast_udp_callback
;
;       DESCRIPTION:    Broadcast UDP callback
;
;       PARAMETERS:     DS          Class selector
;                       FS          Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

broadcast_udp_callback    Proc far
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    mov si,ds:bq_source_port
    mov bx,ds:bq_dest_port
    mov ecx,ds:bq_req_size
    mov es,ds:bq_req_sel
    mov edi,ds:bq_req_offset
    BroadcastDriverUdp
;
    popad
    pop es
    pop ds
    retf32
broadcast_udp_callback    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           BroadcastUdp
;
;       Purpose:        Broadcast UDP
;
;       Parameters:     (E)CX       Size of setup message
;                       ES:(E)DI    Answer buffer
;                       SI          Source port
;                       BX          Destination port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

broadcast_udp_name    DB 'Broadcast UDP',0

broadcast_udp Proc near
    push ds
    push es
    push ecx
    push edi
;           
    mov ax,SEG data
    mov ds,ax    
    EnterSection ds:bq_section
;
    mov ds:bq_req_size,ecx
    mov ds:bq_req_sel,es 
    mov ds:bq_req_offset,edi 
    mov ds:bq_dest_port,bx  
    mov ds:bq_source_port,si  
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET broadcast_udp_callback
    NetBroadcast
;    
    LeaveSection ds:bq_section
;
    pop edi
    pop ecx
    pop es
    pop ds    
    ret
broadcast_udp Endp

broadcast_udp16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call broadcast_udp    
;
    pop edi
    pop ecx
    retf32    
broadcast_udp16   Endp

broadcast_udp32   Proc far
    call broadcast_udp    
    retf32    
broadcast_udp32   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           broadcast_send_callback
;
;       DESCRIPTION:    Broadcast send callback
;
;       PARAMETERS:     DS          Class selector
;                       FS          Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

broadcast_send_callback    Proc far
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    mov si,BROADCAST_QUERY_PORT
    mov bx,ds:bq_dest_port
    mov ecx,ds:bq_req_size
    mov es,ds:bq_req_sel
    mov edi,ds:bq_req_offset
    BroadcastDriverUdp
;
    popad
    pop es
    pop ds
    retf32
broadcast_send_callback    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           BroadcastQueryUdp
;
;       Purpose:        Broadcast query UDP
;
;       Parameters:     EDX         Timeout in ms
;                       (E)CX       Size of setup message
;                       DS:(E)SI    Request buffer  
;                       ES:(E)DI    Answer buffer
;                       BX          Destination port
;
;       Returns:        EAX         Size of answer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

broadcast_query_udp_name    DB 'Broadcast Query UDP',0

broadcast_query_udp Proc near
    push ds
    push fs
    push ecx
;
    mov ax,ds
    mov fs,ax 
;           
    mov ax,SEG data
    mov ds,ax    
    EnterSection ds:bq_section
;
    mov ds:bq_req_size,ecx
    mov ds:bq_req_sel,fs 
    mov ds:bq_req_offset,esi 
    mov ds:bq_dest_port,bx  
    mov ds:bq_reply_sel,0
    GetThread
    mov ds:bq_thread,ax    
;
    mov si,BROADCAST_QUERY_PORT
    call FindListen
    jnc bquListenOk
;
    push es
    push edi
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET broadcast_listen_callback
    ListenUdpPort
;
    pop edi
    pop es

bquListenOk:
    push es
    push edi
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET broadcast_send_callback
    NetBroadcast
;
    pop edi
    pop es
;
    mov ax,SEG data
    mov ds,ax    
;
    mov eax,1193
    mul edx
    push edx
    push eax    
    GetSystemTime
    pop ecx
    add eax,ecx
    pop ecx
    adc edx,ecx
    WaitForSignalWithTimeout    
;    
    mov dx,ds:bq_reply_sel
    or dx,dx
    jz bquFailed
;    
    xor edx,edx
    mov ecx,ds:bq_reply_size
    or ecx,ecx
    jz bquFailed
;
    push ds
    push esi
    mov ds,ds:bq_reply_sel    
    xor esi,esi
    rep movs byte ptr es:[edi],ds:[esi]
    pop esi
    pop ds
;
    push es
    mov es,ds:bq_reply_sel
    FreeMem
    pop es    
    mov edx,ds:bq_ip
    clc
    jmp bquLeave

bquFailed:
    stc

bquLeave:
    mov eax,ds:bq_reply_size
    mov ds:bq_req_sel,0
    mov ds:bq_thread,0
    LeaveSection ds:bq_section
;
    pop ecx
    pop fs
    pop ds    
    ret
broadcast_query_udp Endp

broadcast_query_udp16   Proc far
    push ecx
    push esi
    push edi
;
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call broadcast_query_udp    
;
    pop edi
    pop esi
    pop ecx
    retf32    
broadcast_query_udp16   Endp

broadcast_query_udp32   Proc far
    call broadcast_query_udp    
    retf32    
broadcast_query_udp32   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateConnection
;
;       Purpose:        Create a connection and link it
;
;       Parameters:     EDX         ip address
;                       SI          local port
;                       DI          remote port
;
;       Returns:        AX          connection selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateConnection    Proc near
    push ds
    push es
;
    mov eax,SIZE udp_connection
    AllocateSmallGlobalMem
    InitSection es:udp_conn_section
    mov es:udp_port,si
    mov es:udp_remote_ip,edx
    mov es:udp_remote_port,di
    mov es:udp_data_sel,0
    mov es:udp_data_size,0
    mov es:udp_wait,0
;       
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:udp_section
    mov dx,ds:connection_list
    mov es:udp_next,dx
    mov ds:connection_list,es
    LeaveSection ds:udp_section
;
    mov ax,es
;    
    pop es
    pop ds
    ret
CreateConnection    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DeleteConnection
;
;       Purpose:        Delete a connection.
;
;       Parameters:     DS          connection selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteConnection    Proc near
    push es
    push ax
    push bx
    push ecx
    push edx
;
    push ds
    mov dx,ds:udp_next
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:udp_section    
;
    mov ax,ds:connection_list
    cmp ax,bx
    jne delete_connect_loop
;
    mov ds:connection_list,dx
    jmp delete_connect_unlinked

delete_connect_loop:
    or ax,ax
    jz delete_connect_unlinked
;       
    mov ds,ax
    mov cx,ax
    mov ax,ds:udp_next
    cmp ax,bx
    jne delete_connect_loop
;
    mov ds,ax
    mov ax,ds:udp_next
    mov ds,cx
    mov ds:udp_next,ax

delete_connect_unlinked:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:udp_section
;    
    pop ds
;
    mov ax,25
    WaitMilliSec
;
    mov ax,ds:udp_data_sel
    or ax,ax
    jz delete_data_freed
;
    mov es,ax
    FreeMem

delete_data_freed:        
    mov ax,ds
    mov es,ax
    FreeMem
;
    pop edx
    pop ecx
    pop bx
    pop ax
    pop es
    ret
DeleteConnection    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindConnection
;
;       Purpose:        Look for a connection
;
;       Parameters:     EDX         remote ip
;                       SI          local port
;                       DI          remote port
;
;       Returns:        NC          connection found
;                       AX          connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindConnection  Proc near
    push ds
    push es
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:udp_section
    mov ax,ds:connection_list

find_connection_loop:
    or ax,ax
    jz find_connection_fail
;
    mov es,ax
    cmp edx,es:udp_remote_ip
    jne find_connection_next
;
    cmp si,es:udp_port
    jne find_connection_next

    cmp di,es:udp_remote_port
    je find_connection_ok

find_connection_next:
    mov ax,es:udp_next
    jmp find_connection_loop

find_connection_fail:
    stc
    jmp find_connection_done

find_connection_ok:
    clc

find_connection_done:
    LeaveSection ds:udp_section
;
    pop es
    pop ds
    ret
FindConnection  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateConnection
;
;       Purpose:        Update connection
;
;       Parameters:     AX          Connection selector
;                       CX          Size of data
;                       ES:DI       Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateConnection  Proc near
    push ds
    push es
    push fs
    pusha
;
    mov si,es
    mov fs,si
    mov si,di
;
    mov ds,ax
    EnterSection ds:udp_conn_section
    mov ax,ds:udp_data_sel
    or ax,ax
    jz update_conn_add
;
    mov es,ax
    FreeMem

update_conn_add:
    movzx eax,cx
    AllocateSmallGlobalMem
    mov ds:udp_data_sel,es
    mov ds:udp_data_size,cx
;    
    xor di,di
    rep movs es:[di],fs:[si]    
;
    LeaveSection ds:udp_conn_section
;
    xor ax,ax
    xchg ax,ds:udp_wait
    or ax,ax
    jz update_conn_done
;
    mov es,ax    
    SignalWait

update_conn_done:
    popa
    pop fs
    pop es
    pop ds    
    ret
UpdateConnection    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           OpenUdpConnection
;
;       Purpose:        Open a udp connection
;
;       Parameters:     ECX         buffer size
;                       EDX         ip address
;                       SI          local port
;                       DI          remote port
;
;       Returns:        NC          ok
;                       BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_udp_connection_name    DB 'Open UDP Connection',0

open_udp_connection     Proc far
    push ds
    push ax
    push dx
;    
    call CreateConnection
    mov dx,ax
;
    mov ax,UDP_SOCKET_HANDLE
    mov cx,SIZE udp_handle_seg
    AllocateHandle
    mov ds:[ebx].udp_handle_sel,dx
    mov ds:[ebx].hh_sign,UDP_SOCKET_HANDLE
    mov bx,ds:[ebx].hh_handle
    clc
;    
    pop dx
    pop ax
    pop ds
    retf32
open_udp_connection     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseUdpConnection
;
;       Purpose:        Close connection
;
;       Parameters:     BX          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_udp_connection_name DB 'Close UDP Connection',0

close_udp_connection    Proc far
    push ds
    push ax
;
    mov ax,UDP_SOCKET_HANDLE
    DerefHandle
    jc close_udp_done
;
    push word ptr [ebx].udp_handle_sel
    FreeHandle
    pop ax
;    
    or ax,ax
    stc
    jz close_udp_done
;
    mov ds,ax
    call DeleteConnection

close_udp_done:    
    pop ax
    pop ds
    retf32
close_udp_connection    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendUdpConnection
;
;       Purpose:        Send UDP data
;
;       Parameters:     BX              Connection handle
;                       ES:(E)DI        Buffer
;                       (E)CX           Number of bytes to send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_udp_connection_name DB 'Send UDP Connection',0

send_udp_connection       Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,UDP_SOCKET_HANDLE
    DerefHandle
    jc send_udp_done
;    
    mov ax,[ebx].udp_handle_sel
    or ax,ax
    stc
    jz send_udp_conn_done
;
    mov fs,ax
    push es
    push edi
;
    mov edx,fs:udp_remote_ip
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET ip_options
    mov al,17
    mov ah,30
    add ecx,SIZE udp_header
    CreateIpHeader
;    
    pop esi
    pop ds
    jc send_udp_conn_done
;       
    mov ax,fs:udp_port
    xchg al,ah
    mov es:[edi].udp_source,ax
;    
    mov ax,fs:udp_remote_port
    xchg al,ah
    mov es:[edi].udp_dest,ax
;
    xchg cl,ch
    mov es:[edi].udp_len,cx
    xchg cl,ch
;
    push ecx
    push edi
    sub ecx,SIZE udp_header
    add edi,SIZE udp_header
    rep movs byte ptr es:[edi],[esi]
    pop edi
    pop ecx
;
    mov es:[edi].udp_checksum,0
    mov ax,cx
    xchg al,ah
    add ax,1100h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add edi,8
    mov es:[edi].udp_checksum,ax
    sub ecx,8
    SendIp
    clc

send_udp_conn_done:    
    popad
    pop fs
    pop es
    pop ds    
    ret
send_udp_connection       Endp

send_udp_connection16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call send_udp_connection    
;
    pop edi
    pop ecx
    retf32    
send_udp_connection16   Endp

send_udp_connection32   Proc far
    call send_udp_connection 
    retf32    
send_udp_connection32   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           PeekUdpConnection
;
;       Purpose:        Peek connection
;
;       Parameters:     BX          Connection handle
;
;       Returns:        ECX         Size of message or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

peek_udp_connection_name DB 'Peek UDP Connection',0

peek_udp_connection    Proc far
    push ds
    push ax
;
    mov ax,UDP_SOCKET_HANDLE
    DerefHandle
    jc peek_udp_done
;
    mov ax,[ebx].udp_handle_sel
    or ax,ax
    stc
    jz peek_udp_done
;
    mov ds,ax
    movzx ecx,ds:udp_data_size
    clc

peek_udp_done:    
    pop ax
    pop ds
    retf32
peek_udp_connection    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReadUdpConnection
;
;       Purpose:        Read UDP data
;
;       Parameters:     BX              Connection handle
;                       ES:(E)DI        Buffer
;                       (E)CX           Buffer size
;
;       Returns:        (E)AX           Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_udp_connection_name DB 'Read UDP Connection',0

read_udp_connection       Proc near
    push ds
;
    mov ax,UDP_SOCKET_HANDLE
    DerefHandle
    jc read_udp_done
;
    mov ax,[ebx].udp_handle_sel
    or ax,ax
    stc
    jz read_udp_done
;
    push ecx
    push esi
    push edi
;
    mov ds,ax
    EnterSection ds:udp_conn_section
;
    mov eax,ecx
    movzx ecx,ds:udp_data_size
    cmp ecx,eax
    jbe read_udp_do
;
    mov ecx,eax

read_udp_do:
    mov eax,ecx
    or ecx,ecx
    jz read_udp_copied
;    
    push ds
    push es
    mov ds,ds:udp_data_sel
    xor esi,esi
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov cx,ds
    mov es,cx
    xor cx,cx
    mov es,cx
    FreeMem    
;
    pop es
    pop ds
    mov ds:udp_data_sel,0
    mov ds:udp_data_size,0
    
read_udp_copied:
    LeaveSection ds:udp_conn_section
;
    pop edi
    pop esi
    pop ecx    
    clc

read_udp_done:    
    pop ds
    ret
read_udp_connection       Endp

read_udp_connection16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call read_udp_connection    
;
    pop edi
    pop ecx
    retf32    
read_udp_connection16   Endp

read_udp_connection32   Proc far
    call read_udp_connection 
    retf32    
read_udp_connection32   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForConnection
;
;           DESCRIPTION:    Start a wait for connection
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_connection       PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:uw_handle
    mov ax,UDP_SOCKET_HANDLE
    DerefHandle
    jc start_wait_for_done
;    
    mov ax,[ebx].udp_handle_sel
    or ax,ax
    jz start_wait_for_done
;
    mov ds,ax
    mov ds:udp_wait,es
;
    mov ax,ds:udp_data_sel
    or ax,ax
    jz start_wait_for_done
;
    mov ds:udp_wait,0
    SignalWait

start_wait_for_done:
    pop ebx
    pop ax
    pop ds
    retf32
start_wait_for_connection Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForConnection
;
;           DESCRIPTION:    Stop a wait for connection
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_connection    PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:uw_handle
    mov ax,UDP_SOCKET_HANDLE
    DerefHandle
    jc stop_wait_done
;    
    mov ax,[ebx].udp_handle_sel
    or ax,ax
    jz stop_wait_done
;
    mov ds,ax
    mov ds:udp_wait,0

stop_wait_done:
    pop ebx
    pop ax
    pop ds
    retf32
stop_wait_for_connection Endp


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearConnection
;
;           DESCRIPTION:    Clear udp connection
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_connection    PROC far
    retf32
clear_connection Endp


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsConnectionIdle
;
;           DESCRIPTION:    Check if connection is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_connection_idle      PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:uw_handle
    mov ax,UDP_SOCKET_HANDLE
    DerefHandle
    jc is_idle_done
;    
    mov ax,[ebx].udp_handle_sel
    or ax,ax
    stc
    jz is_idle_done
;
    mov ax,ds:udp_data_sel
    or ax,ax
    clc
    je is_idle_done
;
    stc

is_idle_done:
    pop ebx
    pop ax
    pop ds
    retf32
is_connection_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AddWaitForiUdpConnection
;
;   DESCRIPTION:    Add a wait for UDP connection
;
;   PARAMETERS:     AX      Connection handle
;                   BX      Wait handle
;                   ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_udp_connection_name    DB 'Add Wait For UDP Connection',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_connection,    SEG code
aw1 DD OFFSET stop_wait_for_connection,     SEG code
aw2 DD OFFSET clear_connection,             SEG code
aw3 DD OFFSET is_connection_idle,           SEG code

add_wait_for_udp_connection     PROC far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE udp_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;
    mov es:uw_handle,ax

add_wait_done:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_udp_connection     ENDP
        
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
    push dx
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
    pop dx
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
    jmp receive_free

receive_not_cl_dhcp:
    cmp ax,68
    jne receive_not_dhcp
;
    call ReceiveServerDhcp
    jmp receive_free

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
    push es
    push ds
;
    mov ax,es
    mov ds,ax
    mov si,di
;
    movzx eax,cx
    AllocateSmallGlobalMem
    xor di,di
    rep movs byte ptr es:[di],ds:[si]
; 
    pop ds
    mov ds:[bx].udp_query_offset,0
    mov ds:[bx].udp_query_sel,es
    mov bx,ds:[bx].udp_query_thread
    StopTimer
    Signal
    pop es
    jmp receive_free

receive_not_query:
    push di
    mov ax,es:[di].udp_dest
    xchg al,ah
    mov si,ax
    mov ax,es:[di].udp_source
    xchg al,ah
    mov di,ax
    call FindConnection
    pop di
    jc receive_not_conn
;
    mov cx,es:[di].udp_len
    xchg cl,ch
    sub cx,SIZE udp_header
    add di,SIZE udp_header
    call UpdateConnection
    jmp receive_free

receive_not_conn:
    call FindListen
    jc receive_free
;
    push ds
    push es
    push edi
;
    mov ax,es:[di].udp_source
    xchg al,ah
;
    mov cx,es:[di].udp_len
    xchg cl,ch
    sub cx,SIZE udp_header
    add di,SIZE udp_header
    movzx edi,di
    call fword ptr ds:udp_listen_callback
;
    mov ax,es
;
    pop edi
    pop es
    pop ds
;
    or cx,cx
    jz receive_free
;    
    mov fs,ax
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
;   Name:           UdpListenCallback
;
;   Purpose:        UDP listen callback
;
;   Parameters:     DS      Listen struct
;                   ES:DI   UDP data
;                   CX      Size of UDP data
;                   EDX     IP
;                   AX      Source
;
;   Returns:        CX      Reply size 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;o

UdpListenCallback   Proc far
    push ds
    push es
    push bx
    push si
    push di
;    
    mov bx,ax
;
    push ds
    mov ax,es
    mov ds,ax
    mov si,di
;    
    movzx eax,cx
    add eax,OFFSET listen_data
    AllocateSmallGlobalMem
;
    mov es:listen_size,cx
    mov es:listen_ip,edx
    mov es:listen_port,bx
;
    mov di,OFFSET listen_data
    rep movsb
    pop ds
;
    mov dx,es
    EnterSection ds:udp_listen_section
    mov es,ds:udp_listen_data
    mov cx,ds:udp_listen_size
    xor di,di

ulcLoop:
    mov ax,es:[di]
    or ax,ax
    jz ulcFound
;
    add di,2
    loop ulcLoop
;
    LeaveSection ds:udp_listen_section
    mov es,dx
    FreeMem
    jmp ulcDone

ulcFound:
    mov es:[di],dx        
    LeaveSection ds:udp_listen_section
;
    xor ax,ax
    xchg ax,ds:udp_listen_wait_obj
    or ax,ax
    jz ulcDone
;
    mov es,ax
    SignalWait    
        
ulcDone:
    xor cx,cx
;
    pop di
    pop si
    pop bx
    pop es
    pop ds
    retf32
UdpListenCallback   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Name:           CreateUdpListen
;
;   Purpose:        Create a UDP listen handle
;
;   Parameters:     AX      message buffer count
;                   SI      local port
;
;   Returns:        BX      listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_udp_listen_name  DB 'Create UDP listen',0

create_udp_listen       Proc far
    push ds
    push es
    push eax
    push cx
    push dx
    push di
;
    or ax,ax
    jnz culBufNotZero
;
    mov ax,1

culBufNotZero:    
    cmp ax,16
    jbe culBufOk
;
    mov ax,16    

culBufOk:    
    push ax
;
    mov cx,ax
    movzx eax,ax
    shl eax,1
    AllocateSmallGlobalMem
    xor di,di
    xor ax,ax
    rep stosw
    mov dx,es
;       
    mov eax,SIZE udp_listen
    AllocateSmallGlobalMem
    mov dword ptr es:udp_listen_callback,OFFSET UdpListenCallback
    mov word ptr es:udp_listen_callback+4,cs
    mov es:udp_listen_port,si
    mov es:udp_listen_data,dx
    mov es:udp_listen_wait_obj,0
;
    pop ax
    mov es:udp_listen_size,ax    
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
    mov ax,UDP_LISTEN_HANDLE
    mov cx,SIZE listen_handle_seg
    AllocateHandle
    mov [ebx].listen_handle_sel,es
    mov [ebx].hh_sign,UDP_LISTEN_HANDLE
    mov bx,[ebx].hh_handle
;       
    pop di
    pop dx
    pop cx
    pop eax
    pop es
    pop ds
    retf32
create_udp_listen   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Name:           GetUdpListenSize
;
;   Purpose:        Get current UDP listen object size
;
;   Parameters:     BX      listen handle
;
;   Returns:        EAX     Message size or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_udp_listen_size_name     DB 'Get UDP Listen Size',0

get_udp_listen_size  Proc far
    push ds
    push ebx
    push cx
    push dx
;
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc get_udp_listen_size_fail
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jc get_udp_listen_size_fail
;
    mov ds,ax
    mov ds,ds:udp_listen_data
    mov ax,ds:[0]
    or ax,ax
    jz get_udp_listen_size_fail
;
    mov ds,ax
    movzx eax,ds:listen_size
    clc
    jmp get_udp_listen_size_done

get_udp_listen_size_fail:
    xor eax,eax
    stc

get_udp_listen_size_done:
    pop dx
    pop cx
    pop ebx
    pop ds  
    retf32
get_udp_listen_size Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Name:           GetUdpListenIP
;
;   Purpose:        Get current UDP listen source IP
;
;   Parameters:     BX      listen handle
;
;   Returns:        EAX     IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_udp_listen_ip_name     DB 'Get UDP Listen IP',0

get_udp_listen_ip  Proc far
    push ds
    push ebx
    push cx
    push dx
;
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc get_udp_listen_ip_fail
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jc get_udp_listen_ip_fail
;
    mov ds,ax
    mov ds,ds:udp_listen_data
    mov ax,ds:[0]
    or ax,ax
    jz get_udp_listen_ip_fail
;
    mov ds,ax
    mov eax,ds:listen_ip
    clc
    jmp get_udp_listen_ip_done

get_udp_listen_ip_fail:
    xor eax,eax
    stc

get_udp_listen_ip_done:
    pop dx
    pop cx
    pop ebx
    pop ds  
    retf32
get_udp_listen_ip Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Name:           GetUdpListenPort
;
;   Purpose:        Get current UDP listen source port
;
;   Parameters:     BX      listen handle
;
;   Returns:        EAX     Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_udp_listen_port_name     DB 'Get UDP Listen Port',0

get_udp_listen_port  Proc far
    push ds
    push ebx
    push cx
    push dx
;
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc get_udp_listen_port_fail
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jc get_udp_listen_port_fail
;
    mov ds,ax
    mov ds,ds:udp_listen_data
    mov ax,ds:[0]
    or ax,ax
    jz get_udp_listen_port_fail
;
    mov ds,ax
    movzx eax,ds:listen_port
    clc
    jmp get_udp_listen_port_done

get_udp_listen_port_fail:
    xor eax,eax
    stc

get_udp_listen_port_done:
    pop dx
    pop cx
    pop ebx
    pop ds  
    retf32
get_udp_listen_port Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetUdpListenData
;
;       Purpose:        Get current UDP listen data 
;
;       Parameters:     BX              Listen handle
;                       ES:(E)DI        Buffer
;                       (E)CX           Buffer size
;
;       Returns:        (E)AX           Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_udp_listen_data_name DB 'Get UDP Listen Data',0

get_udp_listen_data       Proc near
    push ds
    push ebx
    push ecx
    push esi
    push edi
;
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc get_udp_listen_data_fail
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jc get_udp_listen_data_fail
;
    mov ds,ax
    mov ds,ds:udp_listen_data
    mov ax,ds:[0]
    or ax,ax
    jz get_udp_listen_data_fail
;
    mov ds,ax
    mov esi,OFFSET listen_data
    movzx eax,ds:listen_size
    cmp ecx,eax
    jbe get_udp_listen_copy_data
;
    mov ecx,eax

get_udp_listen_copy_data:
    mov eax,ecx
    rep movs byte ptr es:[edi],ds:[esi]    
    clc
    jmp get_udp_listen_data_done

get_udp_listen_data_fail:
    xor eax,eax
    stc

get_udp_listen_data_done:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop ds  
    ret
get_udp_listen_data       Endp

get_udp_listen_data16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_udp_listen_data
;
    pop edi
    pop ecx
    retf32    
get_udp_listen_data16   Endp

get_udp_listen_data32   Proc far
    call get_udp_listen_data 
    retf32    
get_udp_listen_data32   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Name:           ClearUdpListen
;
;   Purpose:        Clear current UDP listen message
;
;   Parameters:     BX      listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_udp_listen_name     DB 'Clear UDP Listen',0

clear_udp_listen  Proc far
    push ds
    push es
    push ebx
    push cx
    push dx
    push si
    push di
;
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc clear_udp_listen_done
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jc clear_udp_listen_done
;
    mov ds,ax
    mov es,ds:udp_listen_data
    mov cx,ds:udp_listen_size
    xor di,di
    mov si,2
    mov ax,es:[di]
    or ax,ax
    jz clear_udp_listen_done
;
    push es
    mov es,ax
    FreeMem
    pop es
;    
    EnterSection ds:udp_listen_section
    dec cx
    rep movs word ptr es:[di],es:[si]
    xor ax,ax
    stosw
    LeaveSection ds:udp_listen_section

clear_udp_listen_done:
    pop di
    pop si
    pop dx
    pop cx
    pop ebx
    pop es
    pop ds  
    retf32
clear_udp_listen Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseUdpListen
;
;       Purpose:        Close UDP listen
;
;       Parameters:     BX          Listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_udp_listen_name DB 'Close UDP Listen',0

close_udp_listen    Proc far
    push ds
    push es
    pushad
;
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc close_udp_listen_done
;    
    push ds
    push ebx
;    
    mov dx,[ebx].listen_handle_sel
    or dx,dx
    stc
    jz close_udp_listen_handle
;
    mov ax,SEG data
    mov ds,ax
    xor cx,cx
    mov es,cx    
    EnterSection ds:udp_section
;    
    mov ax,ds:listen_list

close_udp_listen_loop:    
    or ax,ax
    jz close_udp_listen_leave
;
    cmp ax,dx
    je close_udp_listen_found
;    
    mov es,ax
    mov ax,es:udp_listen_next
    jmp close_udp_listen_loop

close_udp_listen_found:
    mov cx,es
    or cx,cx
    jz close_udp_listen_head

close_udp_listen_link:
    mov es,es:udp_listen_next
    mov ax,es:udp_listen_next
    mov es,cx
    mov es:udp_listen_next,ax
    jmp close_udp_listen_delete

close_udp_listen_head:
    mov es,ds:listen_list
    mov ax,es:udp_listen_next
    mov ds:listen_list,ax

close_udp_listen_delete:
    LeaveSection ds:udp_section
;
    mov ds,dx
    mov cx,ds:udp_listen_size
    mov ds,ds:udp_listen_data
    xor si,si

close_udp_listen_del_loop:
    lodsw
    or ax,ax
    jz close_udp_listen_del_next
;
    mov es,ax
    FreeMem

close_udp_listen_del_next:
    loop close_udp_listen_del_loop
;
    mov ds,dx
    mov es,ds:udp_listen_data
    FreeMem
;
    xor ax,ax
    mov ds,ax
    mov es,dx
    FreeMem        
    jmp close_udp_listen_handle
        
close_udp_listen_leave:
    LeaveSection ds:udp_section

close_udp_listen_handle:
    pop ebx
    pop ds
;
    FreeHandle

close_udp_listen_done:
    popad
    pop es
    pop ds
    retf32
close_udp_listen    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartWaitForListen
;
;       DESCRIPTION:    Start a wait for listen
;
;       PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_listen   PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:ulw_handle
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc start_wait_for_listen_done
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jz start_wait_for_listen_done
;
    mov ds,ax
    mov ds:udp_listen_wait_obj,es
;
    push ds
    mov ds,ds:udp_listen_data
    mov ax,ds:[0]
    pop ds
    or ax,ax
    jz start_wait_for_listen_done
;    
    mov ds:udp_listen_wait_obj,0
    SignalWait

start_wait_for_listen_done:
    pop ebx
    pop ax
    pop ds
    retf32
start_wait_for_listen Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopWaitForListen
;
;       DESCRIPTION:    Stop a wait for listen
;
;       PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_listen    PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:ulw_handle
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc stop_wait_listen_done
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jz stop_wait_listen_done
;
    mov ds,ax
    mov ds:udp_listen_wait_obj,0

stop_wait_listen_done:
    pop ebx
    pop ax
    pop ds
    retf32
stop_wait_for_listen Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ClearListen
;
;       DESCRIPTION:    Clear tcp listen
;
;       PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_listen    PROC far
    retf32
clear_listen Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsListenIdle
;
;       DESCRIPTION:    Check if listen is idle
;
;       PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_listen_idle  PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:ulw_handle
    mov ax,UDP_LISTEN_HANDLE
    DerefHandle
    jc is_listen_idle_done
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    stc
    jz is_listen_idle_done
;
    mov ds,ax
    mov ds,ds:udp_listen_data
    mov ax,ds:[0]
    or ax,ax
    clc
    jne is_listen_idle_done
;
    stc    

is_listen_idle_done:
    pop ebx
    pop ax
    pop ds
    retf32
is_listen_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddWaitForUdpListen
;
;       DESCRIPTION:    Add a wait for UDP listen
;
;       PARAMETERS:     AX      Listen handle
;                       BX      Wait handle
;                       ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_udp_listen_name    DB 'Add Wait For UDP Listen',0

add_wait_listen_tab:
al0 DD OFFSET start_wait_for_listen,        SEG code
al1 DD OFFSET stop_wait_for_listen,         SEG code
al2 DD OFFSET clear_listen,                 SEG code
al3 DD OFFSET is_listen_idle,               SEG code

add_wait_for_udp_listen PROC far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE udp_listen_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_listen_tab
    AddWait
    pop ax
    jc add_wait_listen_done
;
    mov es:ulw_handle,ax

add_wait_listen_done:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_udp_listen ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseUdpSocket
;
;       DESCRIPTION:    Close UDP socket
;
;       PARAMETERS:     IN  BX        Udp selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_udp_socket_name DB 'Close Udp Socket', 0

close_udp_socket    Proc far
    retf32
close_udp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadUdpSocket
;
;       DESCRIPTION:    Read UDP socket
;
;       PARAMETERS;     IN  BX        Udp selector
;                       IN  EDX:EAX   Position
;                       IN  ES:EDI    Buffer
;                       IN  ECX       Size
;                       OUT ECX       Read size
;                       OUT EDX:EAX   New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_udp_socket_name DB 'Read Udp Socket', 0

read_udp_socket    Proc far
    stc
    retf32
read_udp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteUdpSocket
;
;       DESCRIPTION:    Write UDP socket
;
;       PARAMETERS;     IN  BX        Udp selector
;                       IN  EDX       Position
;                       IN  ES:EDI    Buffer
;                       IN  ECX       Size
;                       OUT EAX       Written size
;                       OUT EDX       New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_udp_socket_name DB 'Write Udp Socket', 0

write_udp_socket    Proc far
    stc
    retf32
write_udp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartReadUdpSocket
;
;       DESCRIPTION:    Start read UDP socket
;
;       PARAMETERS;     IN  BX        Udp selector
;                       IN  AX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_read_udp_socket_name DB 'Start Read Udp Socket', 0

start_read_udp_socket    Proc far
    retf32
start_read_udp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopReadUdpSocket
;
;       DESCRIPTION:    Stop read UDP socket
;
;       PARAMETERS;     IN  BX        Udp selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_read_udp_socket_name DB 'Stop Read Udp Socket', 0

stop_read_udp_socket    Proc far
    retf32
stop_read_udp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetUdpSocketReadCount
;
;       DESCRIPTION:    Get UDP socket read count
;
;       PARAMETERS;     IN  BX        Udp selector
;                       OUT ECX       Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_udp_socket_read_count_name DB 'Get Udp Socket Read Count', 0

get_udp_socket_read_count    Proc far
    stc
    retf32
get_udp_socket_read_count    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ConnectUdpSocket
;
;           DESCRIPTION:    Connect UDP socket
;
;           PARAMETERS:    IN  EDX               IP
;                          IN  SI                port
;
;           RETURNS:       OUT AX                Udp selector
;                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

connect_udp_socket_name  DB 'Connect Udp Socket', 0

connect_udp_socket	Proc far
    xor ax,ax
    stc
    retf32
connect_udp_socket	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_task_udp
;
;           DESCRIPTION:    Init udp driver, tasking part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task_udp

init_task_udp    PROC near
    push ds
    push es
    pusha
;
    mov bx,SEG data
    mov ds,bx
    mov es,bx
;
    InitSection ds:udp_section
    InitSection ds:bq_section
    InitSpinlock ds:udp_spinlock
    mov ds:listen_list,0
    mov ds:connection_list,0
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
    mov esi,OFFSET broadcast_driver_udp
    mov edi,OFFSET broadcast_driver_udp_name
    xor cl,cl
    mov ax,broadcast_driver_udp_nr
    RegisterOsGate
;
    mov esi,OFFSET send_driver_udp
    mov edi,OFFSET send_driver_udp_name
    xor cl,cl
    mov ax,send_driver_udp_nr
    RegisterOsGate
;
    mov esi,OFFSET query_udp
    mov edi,OFFSET query_udp_name
    xor cl,cl
    mov ax,query_udp_nr
    RegisterOsGate
;
    mov esi,OFFSET listen_udp_port
    mov edi,OFFSET listen_udp_port_name
    xor cl,cl
    mov ax,listen_udp_port_nr
    RegisterOsGate
;
    mov esi,OFFSET connect_udp_socket
    mov edi,OFFSET connect_udp_socket_name
    xor cl,cl
    mov ax,connect_udp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET close_udp_socket
    mov edi,OFFSET close_udp_socket_name
    xor cl,cl
    mov ax,close_udp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET read_udp_socket
    mov edi,OFFSET read_udp_socket_name
    xor cl,cl
    mov ax,read_udp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET write_udp_socket
    mov edi,OFFSET write_udp_socket_name
    xor cl,cl
    mov ax,write_udp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET get_udp_socket_read_count
    mov edi,OFFSET get_udp_socket_read_count_name
    xor cl,cl
    mov ax,udp_socket_read_count_nr
    RegisterOsGate
;
    mov esi,OFFSET start_read_udp_socket
    mov edi,OFFSET start_read_udp_socket_name
    xor cl,cl
    mov ax,start_read_udp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_read_udp_socket
    mov edi,OFFSET stop_read_udp_socket_name
    xor cl,cl
    mov ax,stop_read_udp_socket_nr
    RegisterOsGate
;
    mov ebx,OFFSET broadcast_udp16
    mov esi,OFFSET broadcast_udp32
    mov edi,OFFSET broadcast_udp_name
    mov dx,virt_es_in
    mov ax,broadcast_udp_nr
    RegisterUserGate
;
    mov ebx,OFFSET broadcast_query_udp16
    mov esi,OFFSET broadcast_query_udp32
    mov edi,OFFSET broadcast_query_udp_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,broadcast_query_udp_nr
    RegisterUserGate
;
    mov ebx,OFFSET send_udp16
    mov esi,OFFSET send_udp32
    mov edi,OFFSET send_udp_name
    mov dx,virt_es_in
    mov ax,send_udp_nr
    RegisterUserGate
;
    mov esi,OFFSET create_udp_listen
    mov edi,OFFSET create_udp_listen_name
    xor dx,dx
    mov ax,create_udp_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_udp_listen_size
    mov edi,OFFSET get_udp_listen_size_name
    xor dx,dx
    mov ax,get_udp_listen_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_udp_listen_ip
    mov edi,OFFSET get_udp_listen_ip_name
    xor dx,dx
    mov ax,get_udp_listen_ip_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_udp_listen_port
    mov edi,OFFSET get_udp_listen_port_name
    xor dx,dx
    mov ax,get_udp_listen_port_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_udp_listen_data16
    mov esi,OFFSET get_udp_listen_data32
    mov edi,OFFSET get_udp_listen_data_name
    mov dx,virt_es_in
    mov ax,get_udp_listen_data_nr
    RegisterUserGate
;
    mov esi,OFFSET clear_udp_listen
    mov edi,OFFSET clear_udp_listen_name
    xor dx,dx
    mov ax,clear_udp_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_udp_listen
    mov edi,OFFSET close_udp_listen_name
    xor dx,dx
    mov ax,close_udp_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_udp_listen
    mov edi,OFFSET add_wait_for_udp_listen_name
    xor dx,dx
    mov ax,add_wait_for_udp_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_udp_connection
    mov edi,OFFSET open_udp_connection_name
    xor dx,dx
    mov ax,open_udp_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_udp_connection
    mov edi,OFFSET close_udp_connection_name
    xor dx,dx
    mov ax,close_udp_connection_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET send_udp_connection16
    mov esi,OFFSET send_udp_connection32
    mov edi,OFFSET send_udp_connection_name
    mov dx,virt_es_in
    mov ax,send_udp_connection_nr
    RegisterUserGate
;
    mov esi,OFFSET peek_udp_connection
    mov edi,OFFSET peek_udp_connection_name
    xor dx,dx
    mov ax,peek_udp_connection_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_udp_connection16
    mov esi,OFFSET read_udp_connection32
    mov edi,OFFSET read_udp_connection_name
    mov dx,virt_es_in
    mov ax,read_udp_connection_nr
    RegisterUserGate
;
    mov esi,OFFSET add_wait_for_udp_connection
    mov edi,OFFSET add_wait_for_udp_connection_name
    xor dx,dx
    mov ax,add_wait_for_udp_connection_nr
    RegisterBimodalUserGate
;
    mov al,17
    mov edi,OFFSET Receive
    HookIp
;
    popa
    pop es
    pop ds
    ret
init_task_udp    ENDP

code    ENDS

    END
