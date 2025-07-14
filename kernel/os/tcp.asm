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
; TCP.ASM
; TCP protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
include ..\handle.inc
include ..\wait.inc
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE tcp.inc
INCLUDE ..\apicheck.inc

Reverse MACRO
    xchg al,ah
    rol eax,16
    xchg al,ah
        ENDM

tcp_wait_header STRUC

tw_obj          wait_obj_header <>
tw_handle           DW ?

tcp_wait_header ENDS

tcp_handle_seg      STRUC

tcp_handle_base     handle_header <>
tcp_handle_sel      DW ?

tcp_handle_seg      ENDS

listen_handle_seg           STRUC

listen_handle_base      handle_header <>
listen_handle_sel       DW ?

listen_handle_seg           ENDS

data    SEGMENT byte public 'DATA'

ConnSpinlock        spinlock_typ <>
ListSection         section_typ <>
Handle              DW ?
ConnectionList      DW ?
ConnectionCount     DW ?
ListenList          DW ?
TcpThread           DW ?
LastPort            DW ?

RtoLogHandle        DW ?

PortMap             DB 2000h DUP(?)

data    ENDS


code    SEGMENT byte public 'CODE'

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF
    
    assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CheckConnectionList
;
;       Purpose:        Check connection list integrity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckConnectionList     Proc near
    push ds
    pushad
;    
    xor cx,cx
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:ConnectionList
    or ax,ax
    jz cclCheck

cclLoop:
    inc cx
    mov ds,ax
    mov ax, ds:tcp_next
    or ax,ax
    jnz cclLoop

cclCheck:
    mov ax,SEG data
    mov ds,ax
;
    cmp cx,ds:ConnectionCount
    je cclDone
;
    int 3

cclDone:    
    popad
    pop ds
    ret
CheckConnectionList Endp    

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           AllocatePort
;
;       Purpose:        Allocate a dynamic port
;
;       Returns:        SI          Local port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePort    Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov ax,SEG data
    mov ds,ax

allocate_port_loop:
    GetSystemTime
    mov ebx,edx
    movzx ecx,ds:LastPort
    mul ecx
    add eax,ebx
    xor edx,edx
    mov ecx,0F800h
    div ecx
    mov ax,dx
    mov ds:LastPort,ax
;       
    mov bx,ax
    shr bx,3
    add bx,OFFSET PortMap
    and ax,7
    btr [bx],ax
    jnc allocate_port_loop
;
    mov si,800h
    add si,dx
    clc
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AllocatePort    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FreePort
;
;       Purpose:        Free a dynamic port
;
;       Parameters:         SI          Local port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePort    Proc near
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov ax,si
    sub ax,800h
    jc free_port_done
;       
    mov bx,ax
    shr bx,3
    add bx,OFFSET PortMap
    and ax,7
    bts [bx],ax

free_port_done:
    pop ax
    pop ds
    ret
FreePort    Endp


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
;           RETURNS:        AX          Checksum ut
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
;       Name:           GetIss
;
;       Purpose:        Get initial ISS value
;
;       Parameters:         DS          connection selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIss  Proc near
    push edx
    push eax
;
    GetSystemTime
    rcr edx,1
    rcr eax,1
    rcr edx,1
    rcr eax,1
    rcr edx,1
    rcr eax,1
    mov ds:tcp_iss,eax
    mov ds:tcp_time_seq,eax
    mov ds:tcp_id,ax
;
    pop eax
    pop edx
    ret
GetIss  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateSegment
;
;       Purpose:        Create a tcp segment
;
;       Parameters:         DS          connection selector
;                       ECX         size of data portion
;
;       Returns:        ES:DI   segment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSegment   Proc near
    push ax
    push bx
    push ecx
    push edx
    push esi
;
    mov al,6
    mov ah,60
    mov bx,ds:tcp_id
    inc bx
    mov ds:tcp_id,bx
    xchg bl,bh
    add ecx,SIZE tcp_header
    mov edx,ds:tcp_remote_ip
    mov esi,OFFSET tcp_options
    CreateIpHeader
    jc csDone
;
    mov ax,ds:tcp_port
    xchg al,ah
    mov es:[di].tcp_source,ax
    mov ax,ds:tcp_remote_port
    xchg al,ah
    mov es:[di].tcp_dest,ax
    mov es:[di].tcp_seq,0
    mov es:[di].tcp_ack,0
    mov es:[di].tcp_header_len,50h
    mov es:[di].tcp_flags,0
    mov ax,ds:tcp_rcv_wnd
    xchg al,ah
    mov es:[di].tcp_window,ax
    mov es:[di].tcp_urgent,0
    clc

csDone:
    pop esi
    pop edx
    pop ecx
    pop bx
    pop ax
    ret
CreateSegment   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendSegment
;
;       Purpose:        Send a tcp segment
;
;       Parameters:         DS          connection selector
;                       ES:DI   TCP data
;                       ECX         size of data portion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendSegment     Proc near
    push ax
    push cx
;
    mov ax,ds:tcp_checksum_base
    add cx,SIZE tcp_header
    xchg cl,ch
    add ax,cx
    adc ax,0
    adc ax,0
    xchg cl,ch
    mov es:[di].tcp_checksum,0
    call CalcChecksum
    not ax
    mov es:[di].tcp_checksum,ax
    SendIp
;
    pop cx
    pop ax
    ret
SendSegment     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateBuffer
;
;       Purpose:        Create a buffer
;
;       Parameters:         ECX     Buffer size
;
;       Returns:        AX      Buffer selector     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBuffer    Proc near
    push es
    push bx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov edi,ecx
    add ecx,ecx
    mov eax,ecx
    AllocateBigLinear
    mov ebp,edx
    AllocateGdt
    mov ecx,eax
    CreateDataSelector16    
;
    mov ecx,edi
    push ecx
    mov es,bx   
    xor edi,edi
    shr ecx,2
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop ecx
;
    shr ecx,12
    xor esi,esi
;
    push ebx    

cbAlias:
    lea edx,[esi+ebp]
    GetPageEntry
;
    lea edx,[edi+ebp]
    SetPageEntry
;
    add esi,1000h
    add edi,1000h
    loop cbAlias    
;
    pop ebx    
;
    mov ax,bx    
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop bx
    pop es
    ret
CreateBuffer    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FreeBuffer
;
;       Purpose:        Free buffer
;
;       Parameters:         AX      Buffer selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBuffer    Proc near
    push es
    push eax
    push bx
    push ecx
    push edx
;
    mov bx,ax
    GetSelectorBaseSize
;
    shr ecx,1
    add edx,ecx
    shr ecx,12
;
    push ebx
    
fbAlias:
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
    add edx,1000h
    loop fbAlias    
;
    pop ebx
;    
    mov es,bx
    FreeMem
;    
    pop edx
    pop ecx
    pop bx
    pop eax
    pop es
    ret
FreeBuffer    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CopyFromBuffer
;
;       Purpose:        Copy from buffer
;
;       Parameters:         CX      Number of bytes
;           FS:BX       Buffer pointer
;           ES:EDI      Destination address
;
;   Returns:    BX      New buffer pointer
;           EDI     New destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyFromBuffer    Proc near
    push cx
;
    cmp cx,10h
    jb cfbSmall
;
    push esi
    movzx ecx,cx
    movzx esi,bx
    push cx
    shr cx,2
    rep movs dword ptr es:[edi],fs:[esi]
    pop cx
    and cx,3
    rep movs byte ptr es:[edi],fs:[esi]
    mov bx,si
    pop esi
    cmp bx,ds:tcp_buffer_size
    jb cfbDone
;
    sub bx,ds:tcp_buffer_size
    jmp cfbDone

cfbSmall:
    or cx,cx
    jz cfbDone
;    
    push eax

cfbLoop:
    mov al,fs:[bx]
    mov es:[edi],al
    inc bx
    inc edi
    cmp bx,ds:tcp_buffer_size
    jnz cfbWrapDone
    
    xor bx,bx
    
cfbWrapDone:
    loop cfbLoop
;       
    pop eax

cfbDone:
    pop cx
    ret
CopyFromBuffer  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CopyToBuffer
;
;       Purpose:        Copy to buffer
;
;       Parameters:         CX      Number of bytes
;           FS:BX       Buffer pointer
;           ES:ESI      Source address
;
;   Returns:    BX      New buffer pointer
;           ESI     New source
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CopyToBuffer    Proc near
    push eax
    push cx
;
    cmp cx,10h
    jb ctbSmall
;
    push ds
    push es
    push edi
;    
    movzx edi,bx
    movzx ecx,cx
    mov ax,es
    mov ds,ax
    mov ax,fs
    mov es,ax
;
    push cx
    shr cx,2
    rep movs dword ptr es:[edi],ds:[esi]
    pop cx
    and cx,3
    rep movs byte ptr es:[edi],ds:[esi]
    mov bx,di
;
    pop edi
    pop es
    pop ds
;    
    cmp bx,ds:tcp_buffer_size
    jb ctbDone
;
    sub bx,ds:tcp_buffer_size
    jmp ctbDone

ctbSmall:
    or cx,cx
    jz ctbDone    

ctbLoop:
    mov al,es:[esi]
    mov fs:[bx],al
    inc bx
    inc esi
    cmp bx,ds:tcp_buffer_size
    jnz ctbWrapDone
;
    xor bx,bx
    
ctbWrapDone:
    loop ctbLoop

ctbDone:
    pop cx
    pop eax
    ret
CopyToBuffer    Endp    

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateConnection
;
;       Purpose:        Create a connection and link it
;
;       Parameters:         EAX         Timeout in seconds for connection
;                       CX          buffer size
;                       EDX         ip address
;                       SI          local port
;                       DI          remote port
;
;       Returns:        DS          connection selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateConnection    Proc near
    push es
    push ax
    push ecx
    push edx
;
    dec ecx
    and cx,0F000h
    add ecx,1000h
;
    push eax
    mov eax,SIZE tcp_connection
    AllocateSmallGlobalMem
    pop eax
    mov es:tcp_owner,0
    mov es:tcp_writer,0
    mov es:tcp_wait,0
    mov es:tcp_read_wait,0
    mov es:tcp_write_wait,0
    mov es:tcp_exc_wait,0
    mov es:tcp_signal_change,0
    mov es:tcp_options,0
    mov es:tcp_port,si
    mov es:tcp_remote_ip,edx
    mov es:tcp_remote_port,di
    mov es:tcp_timeout,eax
    mov es:tcp_buffer_size,cx
    mov es:tcp_rcv_wnd,cx
    mov es:tcp_state,-1
    mov es:tcp_has_time,0
    mov es:tcp_mtu,1400
    mov es:tcp_pending,0
    mov es:tcp_push_timeout,0
    mov es:tcp_rtt,1193 * 10   ; 10 ms
    mov es:tcp_rto,1193 * 300  ; 300 ms
    mov es:tcp_rts,1193 * 300  ; 300 ms
    mov es:tcp_rtm,0
    mov es:tcp_reorder_count,0
    mov es:tcp_send_timeout,0
    mov es:tcp_delete_timeout,0
    mov es:tcp_resend_count,0
    mov es:tcp_resend_timeout,1
;
    call CreateBuffer
    mov es:tcp_receive_buffer,ax
    mov es:tcp_receive_count,0
    mov es:tcp_receive_head,0
    mov es:tcp_receive_tail,0
;
    call CreateBuffer
    mov es:tcp_send_buffer,ax
    mov es:tcp_send_count,0
    mov es:tcp_send_head,0
    mov es:tcp_send_tail,0
;       
    mov ax,es
    mov ds,ax
    InitSection ds:tcp_section
    EnterSection ds:tcp_section
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:ListSection
    mov dx,ds:ConnectionList
    mov es:tcp_next,dx
    mov ds:ConnectionList,es
    inc ds:ConnectionCount
    call CheckConnectionList
    LeaveSection ds:ListSection
    mov ax,es
    mov ds,ax
    call GetIss
;
    GetIpAddress
    push edx
    pop ax
    pop dx
;
    add dx,ax
    adc dx,word ptr ds:tcp_remote_ip
    adc dx,word ptr ds:tcp_remote_ip+2
    adc dx,600h
    adc dx,0
    adc dx,0
    mov ds:tcp_checksum_base,dx
;
    mov ax,SEG data
    mov es,ax
    mov bx,es:TcpThread
    Signal
;
    pop edx
    pop ecx
    pop ax
    pop es
    ret
CreateConnection    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DeleteConnection
;
;       Purpose:        Delete a connection. ListSection & connection section
;                       must be taken prior to call
;
;       Parameters:         DS          connection selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteConnection    Proc near
    push es
    push ax
    push bx
    push ecx
    push edx
    push esi
;    
    mov si,ds:tcp_port
    call FreePort
;
    mov ax,ds:tcp_receive_buffer
    call FreeBuffer
;
    mov ax,ds:tcp_send_buffer
    call FreeBuffer
;
    mov dx,ds:tcp_next
    mov bx,ds
    mov es,bx
;
    mov ax,SEG data
    mov ds,ax
;
    mov ax,ds:ConnectionList
    cmp ax,bx
    jne delete_connect_loop
;
    mov ds:ConnectionList,dx
    dec ds:ConnectionCount
    jmp delete_connect_unlinked

delete_connect_loop:
    or ax,ax
    jz delete_connect_unlinked
;       
    mov ds,ax
    mov cx,ax
    mov ax,ds:tcp_next
    cmp ax,bx
    jne delete_connect_loop
;
    mov ds,ax
    mov ax,ds:tcp_next
    mov ds,cx
    mov ds:tcp_next,ax
;       
    mov ax,SEG data
    mov ds,ax
    dec ds:ConnectionCount

delete_connect_unlinked:
    mov ax,SEG data
    mov ds,ax
    RequestSpinlock ds:ConnSpinlock
    ReleaseSpinlock ds:ConnSpinlock
    call CheckConnectionList       
    FreeMem
;
    pop esi
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
;       Parameters:         EDX         remote ip
;                       SI          local port
;                       DI          remote port
;
;       Returns:        NC          connection found
;                       DS          connection, locked
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindConnection  Proc near
    push es
    push ax
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:ListSection
    mov ax,ds:ConnectionList

find_connection_loop:
    or ax,ax
    jz find_connection_fail
    mov es,ax
    cmp edx,es:tcp_remote_ip
    jne find_connection_next
    cmp si,es:tcp_port
    jne find_connection_next
    cmp di,es:tcp_remote_port
    je find_connection_ok
find_connection_next:
    mov ax,es:tcp_next
    jmp find_connection_loop

find_connection_fail:
    LeaveSection ds:ListSection
    stc
    jmp find_connection_done

find_connection_ok:
    mov ax,es
    push ax
    mov ds,ax
    EnterSection ds:tcp_section
    test ds:tcp_pending,FLAG_DELETE_NET
    jz find_connection_not_deleted
;
    pop ax
    LeaveSection ds:tcp_section
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:ListSection
    stc
    jmp find_connection_done

find_connection_not_deleted:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:ListSection
    pop ds
    clc

find_connection_done:
    pop ax
    pop es
    ret
FindConnection  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindWildConnection
;
;       Purpose:        Look for a connection with zero in remote port
;
;       Parameters:         EDX         remote ip
;                       SI          local port
;
;       Returns:        NC          connection found
;                       DS          connection, locked
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindWildConnection      Proc near
    push es
    push ax
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:ListSection
    mov ax,ds:ConnectionList

find_wild_connection_loop:
    or ax,ax
    jz find_wild_connection_fail
    mov es,ax
    cmp edx,es:tcp_remote_ip
    jne find_wild_connection_next
    cmp si,es:tcp_port
    jne find_wild_connection_next
    mov ax,es:tcp_remote_port
    or ax,ax
    je find_wild_connection_ok

find_wild_connection_next:
    mov ax,es:tcp_next
    jmp find_wild_connection_loop

find_wild_connection_fail:
    LeaveSection ds:ListSection
    stc
    jmp find_wild_connection_done

find_wild_connection_ok:
    mov ax,es
    push ax
    mov ds,ax
    EnterSection ds:tcp_section
    test ds:tcp_pending,FLAG_DELETE_NET
    jz find_wild_connection_not_deleted
;
    pop ax
    LeaveSection ds:tcp_section
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:ListSection
    stc
    jmp find_wild_connection_done

find_wild_connection_not_deleted:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:ListSection
    pop ds
    clc

find_wild_connection_done:
    pop ax
    pop es
    ret
FindWildConnection      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateListen
;
;       Purpose:        Create a listen and link it
;
;       Parameters:         AX      Max connections
;                       ECX         buffer size
;                       SI          local port
;
;       Returns:        DS          listen selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateListen    Proc near
    push es
    push dx
;
    push eax
    mov eax,SIZE tcp_listen
    AllocateSmallGlobalMem
    pop eax
;       
    push si
    mov si,es
    mov ds,si
    InitSection ds:tcp_listen_section
    pop si
;       
    mov es:tcp_listen_port,si
    mov es:tcp_listen_max_conn,ax
    mov es:tcp_listen_conn_count,0
    mov es:tcp_listen_buffer_size,ecx
    mov es:tcp_listen_list,0
    mov es:tcp_listen_wait,0
    mov dx,SEG data
    mov ds,dx
    EnterSection ds:ListSection
    mov dx,ds:ListenList
    mov es:tcp_listen_next,dx
    mov ds:ListenList,es
    LeaveSection ds:ListSection
    mov dx,es
    mov ds,dx
;
    pop dx
    pop es
    ret 
CreateListen    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DeleteListen
;
;       Purpose:        Delete a listen. Listen section
;           must be taken prior to call
;
;       Parameters:         DS          listen selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteListen    Proc near
    push es
    push ax
    push bx
    push ecx
    push edx
;
    mov dx,ds:tcp_listen_next
    mov bx,ds
    mov es,bx
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:ListSection
;       
    mov ax,ds:ListenList
    cmp ax,bx
    jne delete_listen_loop
;
    mov ds:ListenList,dx
    jmp delete_listen_unlinked

delete_listen_loop:
    or ax,ax
    jz delete_listen_unlinked
;       
    mov ds,ax
    mov cx,ax
    mov ax,ds:tcp_listen_next
    cmp ax,bx
    jne delete_listen_loop
;
    mov ds,cx
    mov ds:tcp_listen_next,bx
;
    mov ax,ds:tcp_listen_list
    or ax,ax
    jz delete_listen_unlinked
;
    mov ds,ax

delete_listen_connections:
    mov dx,ds:tcp_next
;
    mov ax,ds:tcp_receive_buffer
    call FreeBuffer
;
    mov ax,ds:tcp_send_buffer
    call FreeBuffer
;
    push es
    mov ax,ds
    mov es,ax
    mov ds,dx
    FreeMem
    pop es
    jmp delete_listen_connections    

delete_listen_unlinked:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:ListSection
    FreeMem
;
    pop edx
    pop ecx
    pop bx
    pop ax
    pop es
    ret
DeleteListen    Endp

        
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
    EnterSection ds:ListSection
    mov ax,ds:ListenList

find_listen_loop:
    or ax,ax
    jz find_listen_fail
    mov es,ax
    cmp si,es:tcp_listen_port
    je find_listen_ok
find_listen_next:
    mov ax,es:tcp_listen_next
    jmp find_listen_loop

find_listen_fail:
    LeaveSection ds:ListSection
    stc
    jmp find_listen_done

find_listen_ok:
    LeaveSection ds:ListSection
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
;       Name:           UpdateRto
;
;       Purpose:        Update Round trip time meassurement
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateRto       Proc near
    pushad
;
    mov al,ds:tcp_has_time
    or al,al
    jz update_rto_done
;
    GetSystemTime
    sub eax,ds:tcp_time_val

    cmp eax,5 * 1193000
    ja update_rto_rtt_ok
;       
    mov edx,ds:tcp_rtt
    add edx,eax
    sar edx,1
    mov ds:tcp_rtt,edx

update_rto_rtt_ok:
    sub eax,ds:tcp_rts
    mov edx,eax
    jae update_rto_err_ok
    neg eax
update_rto_err_ok:
    mov ecx,ds:tcp_rtm
    sub eax,ecx
    sar eax,2
    add ds:tcp_rtm,eax
;
    sar edx,3
    add ds:tcp_rts,edx
;
    mov eax,ds:tcp_rtm
    sal eax,2
    add eax,ds:tcp_rts
    cmp eax,240 * 1193000
    jb update_rto_small
    mov eax,240 * 1193000
update_rto_small:
    mov ds:tcp_rto,eax

update_rto_done:
    popad
    ret
UpdateRto       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SignalChange
;
;       Purpose:        Signal change in connection
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignalChange     Proc near
    push ebx
;
    mov bx,ds:tcp_signal_change
    or bx,bx
    jz scDone
;
    Signal

scDone:
    pop ebx
    ret
SignalChange     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           IgnoreDummy
;
;       Purpose:        Igonre (dummy proc)
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IgnoreDummy     Proc near
    ret
IgnoreDummy     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SetResendTimeout
;
;       Purpose:        Setup resend timeout
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetResendTimeout    Proc near
    push ecx
    mov eax,ds:tcp_rto
    add eax,119300 / 2
    xor edx,edx
    mov ecx,119300
    div ecx
    add ax,1
;
    mov cl,ds:tcp_resend_count
    shl ax,cl
    or ax,ax
    jz set_resend_timeout_max
;
    cmp ax,10 * 10
    jb set_resend_timeout_do

set_resend_timeout_max:
    mov ax,10 * 10

set_resend_timeout_do:
    mov ds:tcp_resend_timeout,ax
    pop ecx
    ret
SetResendTimeout    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SetSendTimeout
;
;       Purpose:        Setup send timeout
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSendTimeout  Proc near
    push eax
    push ecx
    push edx
;
    mov ax,ds:tcp_send_timeout
    or ax,ax
    jnz set_send_timeout_done
;
    mov eax,ds:tcp_rtt
    add eax,119300 / 2
    xor edx,edx
    mov ecx,119300
    div ecx
    add ax,1
    mov ds:tcp_send_timeout,ax

set_send_timeout_done:
    pop edx
    pop ecx
    pop eax
    ret
SetSendTimeout  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendAck
;
;       Purpose:        Send an ACK segment (possibly with data)
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendAck Proc near
    push es
    push di
;
    mov ds:tcp_send_timeout,0
    and ds:tcp_pending,NOT FLAG_DELAY_ACK
    movzx ecx,ds:tcp_send_count
    or cx,cx
    jnz send_ack_and_data
;
    and ds:tcp_pending, NOT FLAG_RESENT
    call CreateSegment
    mov es:[di].tcp_flags, ACK
    mov eax,ds:tcp_send_next
    Reverse
    mov es:[di].tcp_seq,eax
    mov eax,ds:tcp_rcv_next
    Reverse
    mov es:[di].tcp_ack,eax
    test ds:tcp_pending,FLAG_CLOSING
    jz send_ack_no_fin
;
    and ds:tcp_pending,NOT FLAG_CLOSING
    inc ds:tcp_send_next
    mov es:[di].tcp_flags, ACK OR FIN

send_ack_no_fin:
    test ds:tcp_pending,FLAG_SEND_PUSH
    jz send_ack_no_push
;
    and ds:tcp_pending, NOT FLAG_SEND_PUSH
    or es:[di].tcp_flags, PSH

send_ack_no_push:
    call SendSegment
    jmp send_ack_done

send_ack_and_data:
    test ds:tcp_pending,FLAG_RESENT
    jnz send_ack_no_rtt
;
    mov eax,ds:tcp_time_seq
    sub eax,ds:tcp_send_una
    jg send_ack_no_rtt
;
    GetSystemTime
    mov ds:tcp_time_val,eax 
    mov ds:tcp_has_time,1
    mov eax,ds:tcp_send_next
    mov ds:tcp_time_seq,eax

send_ack_no_rtt:
    movzx ecx,ds:tcp_send_count
    movzx eax,ds:tcp_send_wnd
    cmp eax,ds:tcp_cwnd
    jb send_ack_cong_ok
    mov eax,ds:tcp_cwnd
send_ack_cong_ok:
    add eax,ds:tcp_send_una
    sub eax,ds:tcp_send_next
;
    cmp ecx,eax
    jb send_ack_check_mtu
;
    mov ecx,eax

send_ack_check_mtu:
    movzx eax,ds:tcp_mtu
    cmp ecx,eax
    jc send_ack_size_ok
;
    mov ecx,eax

send_ack_size_ok:
    call CreateSegment
    mov es:[di].tcp_flags, ACK
    mov eax,ds:tcp_send_next
    Reverse
    mov es:[di].tcp_seq,eax
    mov eax,ds:tcp_rcv_next
    Reverse
    mov es:[di].tcp_ack,eax
    add ds:tcp_send_next,ecx
;
    test ds:tcp_pending,FLAG_CLOSING
    jz send_ack_data_no_fin
;
    cmp cx,ds:tcp_send_count
    jne send_ack_data_no_fin
;
    and ds:tcp_pending,NOT FLAG_CLOSING
    inc ds:tcp_send_next
    mov es:[di].tcp_flags, ACK OR FIN

send_ack_data_no_fin:
    cmp cx,ds:tcp_send_count
    jne send_ack_data_no_push
;
    test ds:tcp_pending,FLAG_SEND_PUSH
    jz send_ack_data_no_push
;
    and ds:tcp_pending, NOT FLAG_SEND_PUSH
    or es:[di].tcp_flags, PSH

send_ack_data_no_push:
    push fs
    push cx
    push di
;
    add di,SIZE tcp_header
    mov fs,ds:tcp_send_buffer
    or cx,cx
    jz send_ack_do
;
    movzx edi,di
    sub ds:tcp_send_count,cx
    mov bx,ds:tcp_send_head
    call CopyFromBuffer
    mov ds:tcp_send_head,bx

send_ack_do:
    pop di
    pop cx
    pop fs
    call SendSegment

send_ack_done:
    pop di
    pop es
    ret
SendAck Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendData
;
;       Purpose:        Send a data segment if Nagle permits
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendData    Proc near
    test ds:tcp_pending,FLAG_DELETE_NET
    jnz send_data_done
;    
    test ds:tcp_pending,FLAG_CLOSING
    jnz send_data_do
;
    movzx ecx,ds:tcp_send_count
    movzx eax,ds:tcp_send_wnd
    add eax,ds:tcp_send_una
    sub eax,ds:tcp_send_next
    movzx edx,ds:tcp_mtu
    cmp edx,eax
    ja send_data_check2
    cmp dx,cx
    jbe send_data_do

send_data_check2:
    cmp eax,ecx
    jb send_data_check3
;
    test ds:tcp_pending,FLAG_SEND_PUSH
    jz send_data_check3
;
    mov eax,ds:tcp_send_una
    cmp eax,ds:tcp_send_next
    je send_data_do

send_data_check3:
    movzx edx,ds:tcp_send_max_wnd
    shr edx,1
    cmp edx,eax
    ja send_data_check4
    cmp dx,cx
    jbe send_data_do

send_data_check4:
    test ds:tcp_pending,FLAG_SEND_PUSH
    jz send_data_done
;
    cmp ds:tcp_push_timeout,0
    jnz send_data_done

send_data_do:
    movzx eax,ds:tcp_send_wnd
    cmp eax,ds:tcp_cwnd
    jb send_data_cong_ok
    mov eax,ds:tcp_cwnd
send_data_cong_ok:
    add eax,ds:tcp_send_una
    sub eax,ds:tcp_send_next
    jbe send_data_done
;
    call SendAck
    
send_data_done:
    ret
SendData    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RetransmitSynSent
;
;       Purpose:        Retransmit in SYN-SENT state
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RetransmitSynSent       Proc near
    mov ax,ds:tcp_remote_port
    or ax,ax
    jz rssDone
;
    GetSystemTime
    mov ds:tcp_time_val,eax
;
    xor ecx,ecx
    call CreateSegment
    jc rssDone
;       
    mov es:[di].tcp_flags, SYN
    mov eax,ds:tcp_iss
    Reverse
    mov es:[di].tcp_seq,eax
    call SendSegment

rssDone:
    ret
RetransmitSynSent       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RetransmitSynRcvd
;
;       Purpose:        Retransmit in SYN-RCVD state
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RetransmitSynRcvd       Proc near
    GetSystemTime
    mov ds:tcp_time_val,eax
;
    xor ecx,ecx
    call CreateSegment
    mov es:[di].tcp_flags, SYN OR ACK
    mov eax,ds:tcp_iss
    Reverse
    mov es:[di].tcp_seq,eax
    mov eax,ds:tcp_rcv_next
    Reverse
    mov es:[di].tcp_ack,eax
    call SendSegment
    ret
RetransmitSynRcvd       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RetransmitData
;
;       Purpose:        Retransmit data
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RetransmitData  Proc near
    mov ecx,ds:tcp_send_next
    sub ecx,ds:tcp_send_una
    movzx eax,ds:tcp_mtu
    cmp ecx,eax
    jb retrans_data_mtu_ok
;
    mov ecx,eax

retrans_data_mtu_ok:
    call CreateSegment
    mov es:[di].tcp_flags, ACK
;
    test ds:tcp_pending,FLAG_CLOSING
    jz retrans_data_no_fin
;
    mov ax,ds:tcp_send_count
    or ax,ax
    jnz retrans_data_no_fin
;
    mov eax,ds:tcp_send_next
    sub eax,ds:tcp_send_una
    cmp eax,ecx
    jne retrans_data_no_fin
;
    mov es:[di].tcp_flags, ACK OR FIN

retrans_data_no_fin:
    mov eax,ds:tcp_send_una
    Reverse
    mov es:[di].tcp_seq,eax
    mov eax,ds:tcp_rcv_next
    Reverse
    mov es:[di].tcp_ack,eax
;
    push fs
    push cx
    push di
;
    add di,SIZE tcp_header
    mov fs,ds:tcp_send_buffer
    mov bx,ds:tcp_send_head
    mov eax,ds:tcp_send_next
    sub eax,ds:tcp_send_una
    sub bx,ax
    jnc retrans_data_copy
;
    add bx,ds:tcp_buffer_size

retrans_data_copy:
    or cx,cx
    jz retrans_data_do
;
    movzx edi,di
    call CopyFromBuffer

retrans_data_do:
    pop di
    pop cx
    pop fs
    call SendSegment

retrans_data_done:
    ret
RetransmitData  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           Retransmit
;
;       Purpose:        Retransmit data
;
;       Parameters:         DS          Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

retransmit_tab:
rt0     DW OFFSET RetransmitSynSent
rt1 DW OFFSET RetransmitSynRcvd
rt2 DW OFFSET RetransmitData
rt3     DW OFFSET RetransmitData
rt4     DW OFFSET IgnoreDummy
rt5 DW OFFSET RetransmitData
rt6 DW OFFSET RetransmitData
rt7 DW OFFSET IgnoreDummy
rt8 DW OFFSET IgnoreDummy

Retransmit      Proc near
    push es
    push cx
    push di
;
    test ds:tcp_pending,FLAG_DELETE_NET OR FLAG_DELETE_USER
    jnz retrans_done
;    
    mov ds:tcp_has_time,0
;
    test ds:tcp_pending,FLAG_RETRY
    jz retrans_first
;
    mov ax,ds:tcp_retries
    cmp ax,10
    ja retrans_close
;
    inc ax
    mov ds:tcp_retries,ax
    jmp retrans_do    

retrans_close:    
    or ds:tcp_pending,FLAG_DELETE_NET
    mov bx,ds:tcp_owner
    Signal
;
    call SignalChange
;
    xor bx,bx
    xchg bx,ds:tcp_read_wait
    or bx,bx
    jz retrans_not_read
;
    SignalReadHandle

retrans_not_read:
    xor bx,bx
    xchg bx,ds:tcp_write_wait
    or bx,bx
    jz retrans_not_write
;
    SignalWriteHandle

retrans_not_write:
    xor bx,bx
    xchg bx,ds:tcp_exc_wait
    or bx,bx
    jz retrans_not_exc
;
    SignalExceptionHandle

retrans_not_exc:
    mov bx,ds:tcp_writer
    or bx,bx
    jz retrans_no_writer
;
    Signal

retrans_no_writer:
    xor bx,bx
    xchg bx,ds:tcp_wait  
    or bx,bx
    jz retrans_done
;
    push es
    mov es,bx
    SignalWait
    pop es
    jmp retrans_done

retrans_first:
    mov ds:tcp_retries,0

retrans_do:
    or ds:tcp_pending,FLAG_RESENT OR FLAG_RETRY
    and ds:tcp_pending,NOT FLAG_DELAY_ACK
    inc ds:tcp_resend_count
    call SetResendTimeout
;
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].retransmit_tab

retrans_done:
    pop di
    pop cx
    pop es
    ret
Retransmit      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CheckSeq
;
;       Purpose:        Check if an SEQ is acceptable
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckSeq    Proc near
    mov eax,es:[di].tcp_seq
    Reverse
    mov edx,eax
;
    or cx,cx
    jz check_seq_no_data
;
    mov ax,ds:tcp_buffer_size
    sub ax,ds:tcp_receive_count
    jz check_seq_bad
;
    movzx eax,ax
    add eax,ds:tcp_rcv_next
    cmp edx,eax
    jg check_seq_test2
;
    cmp edx,ds:tcp_rcv_next
    jge check_seq_ok

check_seq_test2:
    movzx ecx,cx
    add edx,ecx
    dec edx
;
    mov ax,ds:tcp_buffer_size
    sub ax,ds:tcp_receive_count
    movzx eax,ax
    add eax,ds:tcp_rcv_next
    cmp edx,eax
    jg check_seq_bad
;
    cmp edx,ds:tcp_rcv_next
    jg check_seq_ok
    jmp check_seq_bad

check_seq_no_data:
    mov ax,ds:tcp_buffer_size
    sub ax,ds:tcp_receive_count
    jz check_seq_both_zero
;
    movzx eax,ax
    add eax,ds:tcp_rcv_next
    cmp edx,eax
    jg check_seq_bad
;
    cmp edx,ds:tcp_rcv_next
    jge check_seq_ok
    jmp check_seq_bad

check_seq_both_zero:
    mov eax,es:[di].tcp_seq
    Reverse
    cmp eax,ds:tcp_rcv_next
    je check_seq_ok

check_seq_bad:
    mov al,es:[di].tcp_flags
    test al,RST
    jnz check_seq_fail
;
    or ds:tcp_pending,FLAG_ACK

check_seq_fail:
    stc
    ret

check_seq_ok:
    clc
    ret
CheckSeq    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CheckRst
;
;       Purpose:        Check for RST
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckRst    Proc near
    mov al,es:[di].tcp_flags
    test al,RST
    clc
    jz check_rst_done
;
    or ds:tcp_pending,FLAG_DELETE_NET
    mov bx,ds:tcp_owner
    Signal
;
    call SignalChange
;
    xor bx,bx
    xchg bx,ds:tcp_read_wait
    or bx,bx
    jz check_rst_not_read
;
    SignalReadHandle

check_rst_not_read:
    xor bx,bx
    xchg bx,ds:tcp_write_wait
    or bx,bx
    jz check_rst_not_write
;
    SignalWriteHandle

check_rst_not_write:
    xor bx,bx
    xchg bx,ds:tcp_exc_wait
    or bx,bx
    jz check_rst_not_exc
;
    SignalExceptionHandle

check_rst_not_exc:
    mov bx,ds:tcp_writer
    or bx,bx
    jz check_rst_no_writer
;
    Signal

check_rst_no_writer:
    xor bx,bx
    xchg bx,ds:tcp_wait  
    or bx,bx
    jz check_rst_ok
;
    push es
    mov es,bx
    SignalWait
    pop es

check_rst_ok:
    stc

check_rst_done:
    ret
CheckRst    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CheckSyn
;
;       Purpose:        Check for SYN
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckSyn    Proc near
    mov al,es:[di].tcp_flags
    test al,SYN
    clc
    jz check_syn_done
;
    or ds:tcp_pending,FLAG_DELETE_NET
    mov bx,ds:tcp_owner
    Signal
    stc

check_syn_done:
    ret
CheckSyn    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           InitConnection
;
;       Purpose:        Init connection
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitConnection  Proc near
    test ds:tcp_pending,FLAG_WAIT
    jz init_con_nowait
;
    and ds:tcp_pending,NOT FLAG_WAIT
    mov bx,ds:tcp_owner
    Signal

init_con_nowait:
    movzx eax,ds:tcp_mtu
    add eax,eax
    mov edx,eax
    cmp edx,4380
    ja iw_max_ok
;
    mov edx,4380    

iw_max_ok:
    add eax,eax
    cmp eax,edx
    jb iw_min_ok
;
    mov eax,edx    

iw_min_ok:
    mov ds:tcp_cwnd,eax
    mov ds:tcp_ssthresh,10000h
    mov ds:tcp_dup_acks,0
;
    mov eax,es:[di].tcp_seq
    Reverse
    mov ds:tcp_send_wl1,eax
    mov eax,es:[di].tcp_ack
    Reverse
    mov ds:tcp_send_wl2,eax
;
    mov ax,es:[di].tcp_window
    xchg al,ah
    mov ds:tcp_send_wnd,ax
    mov ds:tcp_send_max_wnd,ax
    ret
InitConnection  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           NewAck
;
;       Purpose:        Handle new ACK
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewAck  Proc near
    mov ax,es:[di].tcp_window
    xchg al,ah
    mov ds:tcp_send_wnd,ax
    cmp ax,ds:tcp_send_max_wnd
    jb new_ack_not_max_wnd
    mov ds:tcp_send_max_wnd,ax
new_ack_not_max_wnd:
    mov eax,es:[di].tcp_seq
    Reverse
    mov ds:tcp_send_wl1,eax
    mov eax,es:[di].tcp_ack
    Reverse
    mov ds:tcp_send_wl2,eax
;
    xor ax,ax
    xchg ax,ds:tcp_dup_acks
    cmp ax,3
    jb new_ack_congestion
;
    mov eax,ds:tcp_cwnd
    mov ds:tcp_ssthresh,eax
    jmp new_ack_done

new_ack_congestion:
    mov eax,ds:tcp_cwnd
    cmp eax,ds:tcp_ssthresh
    jbe new_ack_slow_start
;
    mov eax,es:[di].tcp_ack
    Reverse
    sub eax,ds:tcp_send_una
    jl new_ack_done
;       
    mul eax
    div ds:tcp_cwnd
    add ds:tcp_cwnd,eax
    jmp new_ack_done

new_ack_slow_start:
    movzx edx,ds:tcp_mtu
    add eax,edx
    mov ds:tcp_cwnd,eax

new_ack_done:
    ret
NewAck  Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DuplicateAck
;
;       Purpose:        Handle duplicate ACK
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DuplicateAck    Proc near
    mov ax,ds:tcp_dup_acks
    inc ax
    mov ds:tcp_dup_acks,ax
    cmp ax,3
    jb dupl_ack_congestion
    jne dupl_ack_not3

dupl_ack3:
    mov eax,ds:tcp_cwnd
    shr eax,1
    movzx edx,ds:tcp_mtu
    add edx,edx
    cmp eax,edx
    ja dupl_ack3_set_thresh
    mov eax,edx
dupl_ack3_set_thresh:
    mov ds:tcp_ssthresh,eax
    add eax,edx
    movzx edx,ds:tcp_mtu
    add eax,edx
    mov ds:tcp_cwnd,eax
    call Retransmit
    jmp dupl_ack_done

dupl_ack_not3:
    movzx eax,ds:tcp_mtu
    add ds:tcp_cwnd,eax
    jmp dupl_ack_done

dupl_ack_congestion:
    mov dx,es:[di].tcp_window
    xchg dl,dh
    movzx edx,dx
;
    mov eax,ds:tcp_cwnd
    cmp eax,edx
    jb dupl_ack_min_ok
    mov eax,edx
dupl_ack_min_ok:
    movzx edx,ds:tcp_mtu
    add edx,edx
    shr eax,1
    cmp eax,edx
    ja upd_thres_size_ok
    mov eax,edx
upd_thres_size_ok:
    mov ds:tcp_ssthresh,eax

dupl_ack_done:
    ret
DuplicateAck    Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateSendWnd
;
;       Purpose:        Update send window
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSendWnd   Proc near
    mov eax,es:[di].tcp_ack
    Reverse
    cmp eax,ds:tcp_send_next
    jg update_send_wnd_fail

update_send_wnd_ok:
    cmp eax,ds:tcp_send_una
    jle update_send_wnd_old
;
    mov eax,es:[di].tcp_seq
    Reverse
    cmp eax,ds:tcp_send_wl1
    jg update_send_wnd_new
    jne update_send_wnd_old
;
    mov eax,es:[di].tcp_ack
    Reverse
    cmp eax,ds:tcp_send_wl2
    jl update_send_wnd_old

update_send_wnd_new:
    call NewAck
    mov ds:tcp_resend_count,0
    call SetResendTimeout
;
    mov eax,es:[di].tcp_ack
    Reverse
    mov ds:tcp_send_una,eax
;
    call UpdateRto
    mov ds:tcp_has_time,0
    clc
    jmp update_send_wnd_done

update_send_wnd_old:
    mov ax,es:[di].tcp_window
    xchg al,ah
    cmp ax,ds:tcp_send_wnd
    jne update_send_wnd_new
;
    mov eax,ds:tcp_send_una
    cmp eax,ds:tcp_send_next
    je update_send_wnd_empty
;
    call DuplicateAck
    clc
    jmp update_send_wnd_done

update_send_wnd_empty:
    mov ds:tcp_dup_acks,0
    clc
    jmp update_send_wnd_done

update_send_wnd_fail:
    or ds:tcp_pending,FLAG_ACK
    clc

update_send_wnd_done:
    ret
UpdateSendWnd   Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateReceiveWnd
;
;       Purpose:        Update receive window
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateReceiveWnd    Proc near
    mov ax,ds:tcp_buffer_size
    mov dx,ax
    sub ax,ds:tcp_receive_count
    sub ax,ds:tcp_rcv_wnd
    shr dx,1
    cmp ax,dx
    jb update_rec_wnd_done
;
    cmp ax,ds:tcp_mtu
    jb update_rec_wnd_done
;
    mov ds:tcp_rcv_wnd,ax
    or ds:tcp_pending,FLAG_ACK
    
update_rec_wnd_done:
    ret
UpdateReceiveWnd    Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           InsertReordered
;
;       Purpose:        Insert reordered data
;
;       Parameters:         DS          Connection
;                       EAX         Sequence number
;                       CX          Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertReordered Proc near
    push esi
    push edi
;
    movzx esi,cx
    mov edi,eax
;
    mov bx,OFFSET tcp_reorder_arr
    mov cx,ds:tcp_reorder_count
    or cx,cx
    jz insert_reorder_do

insert_reorder_loop:
    mov edx,ds:[bx].reorder_seq
    cmp eax,edx
    jl insert_reorder_do
;
    add edx,ds:[bx].reorder_size
    cmp eax,edx
    jg insert_reorder_next
;
    add eax,esi
    cmp eax,edx
    jle insert_reorder_done
;
    mov eax,esi
    add eax,edi
    sub eax,ds:[bx].reorder_seq
    mov ds:[bx].reorder_size,eax
    jmp insert_reorder_check_merge

insert_reorder_next:
    add bx,8
    loop insert_reorder_loop

insert_reorder_do:
    mov dx,ds:tcp_reorder_count
    cmp dx,REORDER_ENTRIES
    jne insert_reorder_not_full
;
    sub cx,1
    jc insert_reorder_done
;
    dec ds:tcp_reorder_count

insert_reorder_not_full:
    inc ds:tcp_reorder_count
    mov dx,cx
    shl dx,3
    add bx,dx
    push cx
;
    or cx,cx
    jz insert_reorder_add

insert_reorder_move_fwd:
    mov edx,ds:[bx-8]
    mov ds:[bx],edx
    mov edx,ds:[bx-4]
    mov ds:[bx+4],edx
    sub bx,8
    loop insert_reorder_move_fwd

insert_reorder_add:
    pop cx
    inc cx
    mov ds:[bx].reorder_seq,edi
    mov ds:[bx].reorder_size,esi

insert_reorder_check_merge:
    cmp cx,1
    jbe insert_reorder_done
;
    mov eax,ds:[bx].reorder_seq
    add eax,ds:[bx].reorder_size
    cmp eax,ds:[bx+8].reorder_seq
    jl insert_reorder_done
;
    mov eax,ds:[bx+8].reorder_seq
    add eax,ds:[bx+8].reorder_size
    sub eax,ds:[bx].reorder_seq
    cmp eax,ds:[bx].reorder_size
    jb insert_reorder_size_ok
;
    mov ds:[bx].reorder_size,eax

insert_reorder_size_ok:
    dec cx
    dec ds:tcp_reorder_count
;
    or cx,cx
    jz insert_reorder_done

    push bx
    push cx
insert_reorder_move_back:
    add bx,8
    mov eax,ds:[bx+8]
    mov ds:[bx],eax
    mov eax,ds:[bx+12]
    mov ds:[bx+4],eax
    loop insert_reorder_move_back
;
    pop cx
    pop bx
    jmp insert_reorder_check_merge

insert_reorder_done:
    pop edi
    pop esi
    ret
InsertReordered Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ProcessData
;
;       Purpose:        Process received data
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessData     Proc near;
    mov al,es:[di].tcp_flags
    test al,FIN
    clc
    jz process_data_no_fin
;
    or ds:tcp_pending, FLAG_REC_FIN
    mov eax,es:[di].tcp_seq
    Reverse
    movzx ecx,cx
    add eax,ecx
    mov ds:tcp_fin_seq,eax

process_data_no_fin:
    or cx,cx
    jnz process_data_available
;
    test ds:tcp_pending, FLAG_REC_FIN
    jnz process_data_check_fin
;
    mov al,es:[di].tcp_flags
    test al,PSH
    jz process_data_done
;
    or ds:tcp_pending,FLAG_REC_PUSH
    jmp process_data_check_fin

process_data_available:
    mov fs,ds:tcp_receive_buffer
    mov bx,ds:tcp_receive_tail
    mov eax,es:[di].tcp_seq
    Reverse
    sub eax,ds:tcp_rcv_next
    jg process_data_in_future
;
    jz process_data_new
;
    or ds:tcp_pending,FLAG_ACK

process_data_new:
    neg ax
    add si,ax
    sub cx,ax
    jc process_data_done
;
    mov dx,ds:tcp_buffer_size
    mov ax,dx
    sub ax,ds:tcp_receive_count
    cmp cx,ax
    jbe process_data_do
    mov cx,ax
    jmp process_data_do

process_data_in_future:
    or ds:tcp_pending,FLAG_ACK
    add bx,ax
    cmp bx,ds:tcp_buffer_size
    jc process_data_future_nowrap
;
    sub bx,ds:tcp_buffer_size

process_data_future_nowrap:
    mov dx,ax
    mov ax,ds:tcp_buffer_size
    sub ax,dx
    sub ax,ds:tcp_receive_count
    cmp cx,ax
    jbe process_data_do
    mov cx,ax
    
process_data_do:
    push cx
    push bx
;
    mov eax,es:[di].tcp_seq
    Reverse
    cmp eax,ds:tcp_rcv_next
    jg process_data_reorder
;
    mov eax,ds:tcp_rcv_next

process_data_reorder:
    call InsertReordered
    pop bx
    pop cx
;
    movzx esi,si
    call CopyToBuffer

process_data_moved:
    mov eax,ds:tcp_reorder_arr.reorder_seq
    cmp eax,ds:tcp_rcv_next
    jg process_data_empty
;
    add eax,ds:tcp_reorder_arr.reorder_size
    sub eax,ds:tcp_rcv_next
    add ds:tcp_rcv_next,eax
    mov bx,ds:tcp_receive_tail
    add bx,ax
    cmp bx,ds:tcp_buffer_size
    jc process_data_new_tail_ok
;
    sub bx,ds:tcp_buffer_size

process_data_new_tail_ok:
    mov ds:tcp_receive_tail,bx
    add ds:tcp_receive_count,ax
    sub ds:tcp_rcv_wnd,ax
;
    call UpdateReceiveWnd
    test ds:tcp_pending,FLAG_DELAY_ACK
    jnz process_data_delay_ack_ok
    
    or ds:tcp_pending,FLAG_DELAY_ACK
    mov ds:tcp_ack_timeout,4

process_data_delay_ack_ok:
    mov cx,ds:tcp_reorder_count
    sub cx,1
    mov ds:tcp_reorder_count,cx
    jz process_data_empty
;
    mov bx,OFFSET tcp_reorder_arr

process_data_reorder_remove_loop:
    mov eax,ds:[bx+8]
    mov ds:[bx],eax
    mov eax,ds:[bx+12]
    mov ds:[bx+4],eax
    loop process_data_reorder_remove_loop

process_data_empty:
    mov al,es:[di].tcp_flags
    test al,PSH
    jz process_data_check_fin
;
    or ds:tcp_pending,FLAG_REC_PUSH

process_data_check_fin:
    test ds:tcp_pending, FLAG_REC_FIN
    jz process_data_wake
;
    mov eax,ds:tcp_rcv_next
    cmp eax,ds:tcp_fin_seq
    jl process_data_wake
;
    mov eax,ds:tcp_fin_seq
    inc eax
    mov ds:tcp_rcv_next,eax
    or ds:tcp_pending, FLAG_DELAY_ACK OR FLAG_CLOSED

process_data_wake:
    mov bx,ds:tcp_receive_count
    or bx,bx
    jz process_data_not_read
;
    call SignalChange
;
    xor bx,bx
    xchg bx,ds:tcp_read_wait
    or bx,bx
    jz process_data_not_read
;
    SignalReadHandle

process_data_not_read:
    mov bx,ds:tcp_owner
    Signal
;
    xor bx,bx
    xchg bx,ds:tcp_wait  
    or bx,bx
    jz process_data_done
;
    push es
    mov es,bx
    SignalWait
    pop es

process_data_done:
    ret
ProcessData     Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveListen
;
;       Purpose:        Received data in LISTEN state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveListen   Proc near
    mov eax,es:[di].tcp_seq
    Reverse
    inc eax
    mov ds:tcp_rcv_next,eax
;
    mov eax,ds:tcp_iss
    mov ds:tcp_send_una,eax
    inc eax
    mov ds:tcp_send_next,eax    
    mov ds:tcp_state,STATE_SYN_RCVD
;
    GetSystemTime
    mov ds:tcp_time_val,eax
;
    xor ecx,ecx
    call CreateSegment
    mov es:[di].tcp_flags, SYN OR ACK
    mov eax,ds:tcp_iss
    Reverse
    mov es:[di].tcp_seq,eax
    mov eax,ds:tcp_rcv_next
    Reverse
    mov es:[di].tcp_ack,eax
    call SendSegment
    ret
ReceiveListen   Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveSynSent
;
;       Purpose:        Received data in SYN-SENT state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveSynSent  Proc near
    mov dl,es:[di].tcp_flags
    test dl,ACK
    jz receive_syn_sent_noack
;
    mov eax,es:[di].tcp_ack
    Reverse
    cmp eax,ds:tcp_iss
    jle receive_syn_sent_reset
;
    cmp eax,ds:tcp_send_next
    jg receive_syn_sent_reset
;
    mov dl,es:[di].tcp_flags
    test dl,RST
    jz receive_syn_sent_norst
;
    or ds:tcp_pending,FLAG_DELETE_NET
    mov bx,ds:tcp_owner
    Signal
    jmp receive_syn_sent_done

receive_syn_sent_noack:
    test dl,RST
    jnz receive_syn_sent_done

receive_syn_sent_norst:
    test dl,SYN
    jz receive_syn_sent_done
;
    mov eax,es:[di].tcp_seq
    Reverse
    inc eax
    mov ds:tcp_rcv_next,eax
;
    test dl,ACK
    jz receive_syn_sent_answer
;
    mov eax,es:[di].tcp_ack
    Reverse
    mov ds:tcp_send_una,eax

receive_syn_sent_answer:
    mov eax,ds:tcp_send_una
    cmp eax,ds:tcp_iss
    jg receive_syn_sent_ok
;
    GetSystemTime
    mov ds:tcp_time_val,eax
;
    mov ds:tcp_state, STATE_SYN_RCVD
    xor ecx,ecx
    call CreateSegment
    mov es:[di].tcp_flags, SYN OR ACK
    mov eax,ds:tcp_iss
    Reverse
    mov es:[di].tcp_seq,eax
    mov eax,ds:tcp_rcv_next
    Reverse
    mov es:[di].tcp_ack,eax
    call SendSegment
    jmp receive_syn_sent_done

receive_syn_sent_ok:
    mov ds:tcp_state, STATE_ESTAB
    or ds:tcp_pending, FLAG_DELAY_ACK
    mov ds:tcp_ack_timeout,4
    call InitConnection
    call SendAck
    jmp receive_syn_sent_done

receive_syn_sent_reset:
    mov al,es:[di].tcp_flags
    test al,RST
    jnz receive_syn_sent_done
;
    xor ecx,ecx
    push es:[di].tcp_ack
    call CreateSegment
    mov es:[di].tcp_flags, RST
    pop es:[di].tcp_seq
    call SendSegment

receive_syn_sent_done:
    ret
ReceiveSynSent  Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveSynRcvd
;
;       Purpose:        Received data in SYN-RCVD state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveSynRcvd  Proc near
    call CheckSeq
    jc receive_syn_rcvd_done
;
    call CheckRst
    jc receive_syn_rcvd_done
;
    call CheckSyn
    jc receive_syn_rcvd_done
;
    test es:[di].tcp_flags, ACK
    jz receive_syn_rcvd_done
;
    mov eax,es:[di].tcp_ack
    Reverse
    cmp eax,ds:tcp_send_una
    jl receive_syn_rcvd_reset
;
    cmp eax,ds:tcp_send_next
    jle receive_syn_rcvd_ack_ok

receive_syn_rcvd_reset:
    xor ecx,ecx
    push es:[di].tcp_ack
    call CreateSegment
    mov es:[di].tcp_flags, RST
    pop es:[di].tcp_seq
    call SendSegment
    jmp receive_syn_rcvd_done

receive_syn_rcvd_ack_ok:
    mov ds:tcp_state,STATE_ESTAB
    call InitConnection
    call UpdateSendWnd
;
    mov al,es:[di].tcp_flags
    test al,FIN
    clc
    jz receive_syn_rcvd_done
;
    or ds:tcp_pending, FLAG_REC_FIN OR FLAG_ACK OR FLAG_CLOSED
    mov eax,es:[di].tcp_seq
    Reverse
    cmp eax,ds:tcp_rcv_next
    jne receive_syn_rcvd_done
;
    inc ds:tcp_rcv_next
    mov ds:tcp_state,STATE_CLOSE_WAIT

receive_syn_rcvd_done:
    ret
ReceiveSynRcvd  Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveEstab
;
;       Purpose:        Received data in ESTABLISHED state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveEstab    Proc near
    call CheckSeq
    jc receive_estab_check_ack
;
    call CheckRst
    jc receive_estab_done
;
    test es:[di].tcp_flags, SYN
    jz receive_estab_normal
;
    test es:[di].tcp_flags, ACK
    jz receive_estab_done
;
    and ds:tcp_pending,NOT FLAG_ACK
    call SendAck
    jmp receive_estab_done

receive_estab_normal:
    test es:[di].tcp_flags, ACK
    jz receive_estab_process
;
    call UpdateSendWnd

receive_estab_process:
    call ProcessData
;
    test ds:tcp_pending, FLAG_CLOSED
    jnz receive_estab_closed

receive_estab_check_ack:
    test ds:tcp_pending,FLAG_ACK
    jz receive_estab_done

receive_estab_ack:
    and ds:tcp_pending,NOT FLAG_ACK
    call SendAck
    jmp receive_estab_done

receive_estab_closed:
    mov ds:tcp_state,STATE_CLOSE_WAIT
    
receive_estab_done:
    ret
ReceiveEstab    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveFinWait1
;
;       Purpose:        Received data in FIN-WAIT1 state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveFinWait1 Proc near
    call CheckSeq
    jc receive_fin_wait1_done
;
    call CheckRst
    jc receive_fin_wait1_done
;
    call CheckSyn
    jc receive_fin_wait1_done
;
    test es:[di].tcp_flags, ACK
    jz receive_fin_wait1_process
;
    call UpdateSendWnd

receive_fin_wait1_process:
    call ProcessData
;
    test ds:tcp_pending, FLAG_CLOSED
    jz receive_fin_wait1_done
;
    mov al,ds:tcp_state
    cmp al,STATE_FIN_WAIT1
    je receive_fin_wait1_not_acked
;
    mov ds:tcp_state,STATE_TIME_WAIT
    mov ds:tcp_delete_timeout,240 * 10
    jmp receive_fin_wait1_done

receive_fin_wait1_not_acked:
    mov ds:tcp_state,STATE_CLOSING
    mov ds:tcp_delete_timeout,240 * 10

receive_fin_wait1_done:
    ret
ReceiveFinWait1 Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveFinWait2
;
;       Purpose:        Received data in FIN-WAIT2 state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveFinWait2 Proc near
    call CheckSeq
    jc receive_fin_wait2_done
;
    call CheckRst
    jc receive_fin_wait2_done
;
    call CheckSyn
    jc receive_fin_wait2_done
;
    test es:[di].tcp_flags, ACK
    jz receive_fin_wait2_process
;
    call UpdateSendWnd

receive_fin_wait2_process:
    call ProcessData
;
    test ds:tcp_pending, FLAG_CLOSED
    jz receive_fin_wait1_done
;
    mov ds:tcp_state,STATE_TIME_WAIT
    mov ds:tcp_delete_timeout,240 * 10

receive_fin_wait2_done:
    ret
ReceiveFinWait2 Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveCloseWait
;
;       Purpose:        Received data in CLOSE-WAIT state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveCloseWait    Proc near
    call CheckSeq
    jc receive_close_wait_done
;
    call CheckRst
    jc receive_close_wait_done
;
    call CheckSyn
    jc receive_close_wait_done
;
    test es:[di].tcp_flags, ACK
    jz receive_close_wait_done
;
    call UpdateSendWnd

receive_close_wait_done:
    ret
ReceiveCloseWait    Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveClosing
;
;       Purpose:        Received data in CLOSING state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveClosing  Proc near
    call CheckSeq
    jc receive_closing_done
;
    call CheckRst
    jc receive_closing_done
;
    call CheckSyn
    jc receive_closing_done
;
    test es:[di].tcp_flags, ACK
    jz receive_closing_done
;
    call UpdateSendWnd

receive_closing_done:
    ret
ReceiveClosing  Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveLastAck
;
;       Purpose:        Received data in LAST-ACK state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveLastAck  Proc near
    call CheckSeq
    jc receive_last_ack_done
;
    call CheckRst
    jc receive_last_ack_done
;
    call CheckSyn
    jc receive_last_ack_done
;
    test es:[di].tcp_flags, ACK
    jz receive_last_ack_done
;
    mov eax,es:[di].tcp_ack
    Reverse
    cmp eax,ds:tcp_send_next
    je receive_last_ack_delete
;
    xor ecx,ecx
    call CreateSegment
    mov es:[di].tcp_flags, FIN OR ACK
    mov eax,ds:tcp_send_next
    Reverse
    mov es:[di].tcp_seq,eax
    mov eax,ds:tcp_rcv_next
    Reverse
    mov es:[di].tcp_ack,eax
    call SendSegment
    jmp receive_last_ack_done

receive_last_ack_delete:
    or ds:tcp_pending, FLAG_DELETE_NET
    mov bx,ds:tcp_owner
    Signal

receive_last_ack_done:
    ret
ReceiveLastAck  Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveTimeWait
;
;       Purpose:        Received data in TIME-WAIT state
;
;       Parameters:         DS          Connection
;                       CX          Size of data
;                       EDX         Source IP address
;                       ES:SI   TCP data
;                       ES:DI   TCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveTimeWait Proc near
    call CheckSeq
    jc receive_time_wait_done
;
    call CheckRst
    jc receive_time_wait_done
;
    call CheckSyn
    jc receive_time_wait_done
;
    test es:[di].tcp_flags, ACK
    jz receive_time_wait_done

receive_time_wait_done:
    ret
ReceiveTimeWait Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ProcessOptions
;
;       Purpose:        Process IP & TCP options
;
;       Parameters:         DS          Connection
;                       CX          Size of data & header
;                       EDX         Source IP address
;                       ES:SI   IP options
;                       ES:DI   TCP header
;
;       Returns:        ES:ESI  TCP data
;                       CX          Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessOptions  Proc near
    movzx dx,es:[di].tcp_header_len
    shr dx,2
    sub dx,SIZE tcp_header
    or dx,dx
    jz process_options_done
;
    mov si,di
    add si,SIZE tcp_header

process_options_next:
    sub dx,1
    jz process_options_done
;
    lods byte ptr es:[si]
    or al,al
    jz process_options_done
;
    cmp al,1
    jz process_options_next
;
    cmp al,2
    je process_mtu
;
    jmp process_options_adv

process_mtu:
    mov al,es:[si]
    cmp al,4
    jne process_options_adv
;       
    inc si
    sub dx,3
    jc process_options_done
;
    lods word ptr es:[si]
    xchg al,ah
    cmp ax,ds:tcp_mtu
    ja process_options_ignore_mtu
;
    mov ds:tcp_mtu,ax

process_options_ignore_mtu:
    or dx,dx
    jz process_options_done
    jmp process_options_next

process_options_adv:
    sub dx,1
    jz process_options_done
    lods byte ptr es:[si]
    movzx ax,al
    sub al,2
    add si,ax
    sub dx,ax
    ja process_options_next

process_options_done:
    movzx ax,es:[di].tcp_header_len
    shr ax,2
    sub cx,ax
    mov si,di
    add si,ax
    ret
ProcessOptions  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveChecksum
;
;       Purpose:        Check receive checksum
;
;       Parameters:         AX          Size of options
;                       BX          Id
;                       CX          Size of data
;                       EDX         Source IP address
;                       DS:SI   Options
;                       ES:DI   Data
;
;       Returns:        NC          checksum ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveChecksum Proc near
    push dx
    push si
    push di
;
    mov dx,cx
    xchg dl,dh
    add dx,600h
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
    clc
    jz receive_checksum_done
    stc

receive_checksum_done:
    pop di
    pop si
    pop dx
    ret
ReceiveChecksum Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           Receive
;
;       Purpose:        IP callback
;
;       Parameters:         AX          Size of options
;                       BX          Id
;                       CX          Size of data
;                       EDX         Source IP address
;                       DS:SI   Options
;                       ES:DI   Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveTab:
rt00 DW OFFSET ReceiveSynSent
rt01 DW OFFSET ReceiveSynRcvd
rt02 DW OFFSET ReceiveEstab
rt03 DW OFFSET ReceiveFinWait1
rt04 DW OFFSET ReceiveFinWait2
rt05 DW OFFSET ReceiveCloseWait
rt06 DW OFFSET ReceiveLastAck
rt07 DW OFFSET ReceiveClosing
rt08 DW OFFSET ReceiveTimeWait

Receive Proc far
    call ReceiveChecksum
    jc receive_done
;   
    push di
    mov ax,es:[di].tcp_dest
    xchg al,ah
    mov si,ax
    mov ax,es:[di].tcp_source
    xchg al,ah
    mov di,ax
    call FindConnection
    pop di
    jnc receive_connection
;
    call FindListen
    jnc receive_listen
;
    call FindWildConnection
    jc receive_no_connection
;
    mov al,es:[di].tcp_flags
    test al,SYN
    jnz receive_wild_syn

receive_leave_no_connection:
    LeaveSection ds:tcp_section
    jmp receive_no_connection

receive_wild_syn:
    mov ax,es:[di].tcp_source
    xchg al,ah
    mov ds:tcp_remote_port,ax
    jmp receive_connection
    
receive_listen:
    mov al,es:[di].tcp_flags
    test al,RST
    jnz receive_done
;
    test al,ACK
    jnz receive_no_connection
;
    test al,SYN
    jz receive_done
;
    push ds
    push ecx
    push di
    mov ax,es:[di].tcp_source
    xchg al,ah
    mov di,ax
    mov eax,120
    mov ecx,ds:tcp_listen_buffer_size
    call CreateConnection
    pop di
    pop ecx
;
    push es
    call ProcessOptions
    call ReceiveListen
    pop es
    LeaveSection ds:tcp_section
;
    mov bx,ds
    pop ds
;
    push es
    mov es,bx
    EnterSection ds:tcp_listen_section
    mov ax,ds:tcp_listen_list
    mov es:tcp_listen_link,ax
    mov ds:tcp_listen_list,es
    LeaveSection ds:tcp_listen_section
    pop es
;
    xor bx,bx
    xchg bx,ds:tcp_listen_wait   
    or bx,bx
    jz receive_done
;
    push es
    mov es,bx
    SignalWait
    pop es
    jmp receive_done

receive_connection:
    push es
    call ProcessOptions
    and ds:tcp_pending,NOT FLAG_RETRY
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].ReceiveTab
    pop es
    mov ax,ds:tcp_pending
    test ax,FLAG_ACK
    jz receive_no_ack
;
    and ax,NOT FLAG_ACK
    test ax,FLAG_DELAY_ACK
    jnz receive_delay_ack_ok
;       
    mov ds:tcp_ack_timeout,4
    or ax,FLAG_DELAY_ACK

receive_delay_ack_ok:
    mov ds:tcp_pending,ax
    jmp receive_leave

receive_no_ack:
    call SendData

receive_leave:
    push ecx
    mov cx,ds:tcp_buffer_size
    sub cx,ds:tcp_send_count
    movzx ecx,cx
    mov eax,ds:tcp_send_next
    sub eax,ds:tcp_send_una
    sub ecx,eax
    pop ecx
    jbe receive_not_write
;
    call SignalChange
;
    xor bx,bx
    xchg bx,ds:tcp_write_wait
    or bx,bx
    jz receive_not_write
;
    SignalWriteHandle

receive_not_write:
    mov bx,ds:tcp_writer
    or bx,bx
    jz receive_no_writer
    Signal

receive_no_writer:    
    LeaveSection ds:tcp_section
    jmp receive_done

no_options      DB 0

receive_no_connection:
    mov ax,es
    mov ds,ax
    mov si,di
;
    mov al,ds:[si].tcp_flags
    test al,RST
    jnz receive_done
;
    test al,SYN
    jnz receive_done
;
    push ds
    push cx
    push si
    mov al,6
    mov ah,60
    mov ecx,SIZE tcp_header
    mov si,cs
    mov ds,si       
    mov esi,OFFSET no_options
    CreateIpHeader
    pop si
    pop cx
    pop ds
    jc receive_rst_done
;       
    mov ax,ds:[si].tcp_dest
    mov es:[di].tcp_source,ax
    mov ax,ds:[si].tcp_source
    mov es:[di].tcp_dest,ax
    mov es:[di].tcp_seq,0
    mov es:[di].tcp_ack,0
    mov es:[di].tcp_header_len,50h
    mov es:[di].tcp_window,0
    mov es:[di].tcp_urgent,0
;
    mov al,ds:[si].tcp_flags
    test al,ACK
    jz receive_rst_noack

receive_rst_ack:
    mov eax,ds:[si].tcp_ack
    mov es:[di].tcp_seq,eax
    mov es:[di].tcp_flags,RST
    jmp receive_rst_do

receive_rst_noack:
    mov eax,ds:[si].tcp_seq
    Reverse
    movzx ecx,cx
    add eax,ecx
    Reverse
    mov es:[di].tcp_ack,eax
    mov es:[di].tcp_flags,RST OR ACK

receive_rst_do:
    push edx
    pop bx
    pop ax
    add ax,bx
    GetIpAddress
    push edx
    pop bx
    adc ax,bx
    pop bx
    adc ax,bx
    adc ax,600h
    adc ax,0
    adc ax,0
    mov cx,SIZE tcp_header
    xchg cl,ch
    add ax,cx
    adc ax,0
    adc ax,0
    xchg cl,ch
    mov es:[di].tcp_checksum,0
    call CalcChecksum
    not ax
    mov es:[di].tcp_checksum,ax
    SendIp

receive_rst_done:
    mov ax,ds
    mov es,ax

receive_done:
    retf32
Receive Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateTcpListen
;
;       Purpose:        Create a TCP listen handle
;
;       Parameters:         AX      max connections
;           ECX         buffer size
;                       SI              local port
;
;   Returns:    BX      listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_tcp_listen_name  DB 'Create TCP listen',0

create_tcp_listen       Proc far
    push ds
    push es
    push eax
    push cx
    push dx
;
    call CreateListen
    mov dx,ds
;
    mov ax,TCP_LISTEN_HANDLE
    mov cx,SIZE listen_handle_seg
    AllocateHandle
    mov [ebx].listen_handle_sel,dx
    mov [ebx].hh_sign,TCP_LISTEN_HANDLE
    mov bx,[ebx].hh_handle
;       
    pop dx
    pop cx
    pop eax
    pop es
    pop ds
    retf32
create_tcp_listen   Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetTcpListen
;
;       Purpose:        Get a connection from a listen
;
;       Parameters:         BX      listen handle
;
;   Returns:    AX      connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_tcp_listen_name     DB 'Get TCP listen',0

get_tcp_listen  Proc far
    push ds
    push es
    push ebx
    push cx
    push dx
;
    mov ax,TCP_LISTEN_HANDLE
    DerefHandle
    jc get_listen_done
;    
    mov ax,[ebx].listen_handle_sel
    mov ds,ax
    EnterSection ds:tcp_listen_section
    mov dx,ds:tcp_listen_list
    or dx,dx
    jz get_listen_leave
;
    mov es,dx
    mov bx,es:tcp_listen_link
    mov ds:tcp_listen_list,bx

get_listen_leave:
    LeaveSection ds:tcp_listen_section          
    or dx,dx
    stc
    jz get_listen_done
;
    mov ax,TCP_SOCKET_HANDLE
    mov cx,SIZE tcp_handle_seg
    AllocateHandle
    mov [ebx].tcp_handle_sel,es
    mov [ebx].hh_sign,TCP_SOCKET_HANDLE
    mov ax,[ebx].hh_handle
    clc

get_listen_done:
    pop dx
    pop cx
    pop ebx
    pop es
    pop ds  
    retf32
get_tcp_listen  Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseTcpListen
;
;       Purpose:        Close listen
;
;       Parameters:         BX          Listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_tcp_listen_name DB 'Close TCP Listen',0

close_tcp_listen    Proc far
    push ds
    push es
    pushad
;
    mov ax,TCP_LISTEN_HANDLE
    DerefHandle
    jc close_tcp_listen_done
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    stc
    jz close_tcp_listen_done
;
    mov ds,ax
    call DeleteListen
    clc

close_tcp_listen_done:
    popad
    pop es
    pop ds
    retf32
close_tcp_listen    Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           WaitForConnection
;
;       Purpose:        Wait for a connection
;
;       Parameters:     SI          local port
;                       EBP         timeout
;                       DS          connection sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForConnection Proc near
    push es
    pushad
;
    EnterSection ds:tcp_section
    cmp ds:tcp_state,STATE_ESTAB
    jae wtcOk
;
    mov eax,ebp
    xor edx,edx
    mov ecx,100
    div ecx
    mov ds:tcp_user_timeout,ax
    ClearSignal
    or ds:tcp_pending,FLAG_WAIT

wtcRetry: 
    GetThread
    mov ds:tcp_owner,ax
    LeaveSection ds:tcp_section
;
    WaitForSignal
    mov ds:tcp_owner,0
    EnterSection ds:tcp_section
    cmp ds:tcp_state,STATE_ESTAB
    jae wtcOk
;
    mov ax,ds:tcp_user_timeout
    or ax,ax
    jnz wtcRetry
    jmp wtcFail

wtcOk:
    LeaveSection ds:tcp_section
    clc
    jmp wtcDone

wtcFail:
    mov ds:tcp_delete_timeout,240 * 10
    mov ds:tcp_owner,0
    LeaveSection ds:tcp_section
    stc

wtcDone:
    popad
    pop es
    ret
WaitForConnection Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           WaitForTcpConnection
;
;       Purpose:        Wait for a connection
;
;       Parameters:         SI          local port
;                       EAX         timeout
;                       BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_tcp_connection_name    DB 'Wait For TCP Connection',0

wait_for_tcp_connection Proc far
    push ds
    push eax
    push ebx
    push ebp
;
    mov ebp,eax
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc wait_tcp_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz wait_tcp_done
;
    mov ds,ax
    call WaitForConnection

wait_tcp_done:
    pop ebp
    pop ebx
    pop eax
    pop ds  
    retf32
wait_for_tcp_connection Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           OpenConnection
;
;       Purpose:        Open a tcp connection
;
;       Parameters:     EBP         Timeout in milliseconds for connection
;                       ECX         buffer size
;                       EDX         ip address
;                       SI          local port (or 0 for random port)
;                       DI          remote port (or 0 to accept any port)
;
;       Returns:        NC          ok
;                       DS          connection sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenConnection     Proc near
    push es
    pushad
;
    or si,si
    jz otcDyn
;
    call FindConnection
    jc otcCreate
;
    LeaveSection ds:tcp_section
    stc
    jmp otcDone

otcDyn:
    call AllocatePort
    jc otcDone

otcCreate:
    call CreateConnection
    mov eax,ds:tcp_iss
    mov ds:tcp_send_una,eax
    inc eax
    mov ds:tcp_send_next,eax
    mov ds:tcp_state,STATE_SYN_SENT
    mov ds:tcp_syn_timeout,50
;       
    ClearSignal
    GetThread
    mov ds:tcp_owner,ax
    mov eax,ebp
    xor edx,edx
    mov ecx,100
    div ecx
    mov ds:tcp_user_timeout,ax
    or ds:tcp_pending,FLAG_WAIT
    LeaveSection ds:tcp_section
;
    or di,di
    jz otcOk
;
    xor ecx,ecx
    call CreateSegment
    jc otcArpFail
;       
    mov es:[di].tcp_flags, SYN
    mov eax,ds:tcp_iss
    Reverse
    mov es:[di].tcp_seq,eax
    call SendSegment
;
    WaitForSignal
    mov ds:tcp_owner,0
    EnterSection ds:tcp_section
    cmp ds:tcp_state,STATE_ESTAB
    jne otcFail
;
    LeaveSection ds:tcp_section

otcOk:
    mov ds:tcp_owner,0
    clc
    jmp otcDone

otcFail:
    LeaveSection ds:tcp_section

otcArpFail:
    mov ax,SEG data
    mov es,ax
    RequestSpinlock es:ConnSpinlock
;    
    or ds:tcp_pending,FLAG_DELETE_NET
    or ds:tcp_pending,FLAG_DELETE_USER
    xor ax,ax
    mov ds,ax
;
    ReleaseSpinlock es:ConnSpinlock    
    stc

otcDone:
    popad
    pop es
    ret
OpenConnection     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           OpenTcpConnection
;
;       Purpose:        Open a tcp connection
;
;       Parameters:         EAX         Timeout in milliseconds for connection
;                       ECX         buffer size
;                       EDX         ip address
;                       SI          local port (or 0 for random port)
;                       DI          remote port (or 0 to accept any port)
;
;       Returns:        NC          ok
;                       BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_tcp_connection_name    DB 'Open TCP Connection',0

open_tcp_connection     Proc far
    push ds
    push eax
    push ecx
    push edx
    push ebp
;
    mov ebp,eax
    call OpenConnection
    jc open_tcp_done
;
    mov dx,ds
    mov ax,TCP_SOCKET_HANDLE
    mov cx,SIZE tcp_handle_seg
    AllocateHandle
    mov [ebx].tcp_handle_sel,dx
    mov [ebx].hh_sign,TCP_SOCKET_HANDLE
    mov bx,[ebx].hh_handle
    clc

open_tcp_done:
    pop ebp
    pop edx
    pop ecx
    pop eax
    pop ds
    retf32
open_tcp_connection     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseDelete
;
;       Purpose:        Delete close
;
;       Parameters:         DS          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseDelete     Proc near
    or ds:tcp_pending,FLAG_DELETE_NET
    ret
CloseDelete     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseNormal
;
;       Purpose:        Normal close
;
;       Parameters:         DS          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseNormal     Proc near
    mov ds:tcp_state,STATE_FIN_WAIT1
    or ds:tcp_pending,FLAG_CLOSING
    call SendData
    ret
CloseNormal     Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseCloseWait
;
;       Purpose:        Close in CLOSE-WAIT state
;
;       Parameters:         DS          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseCloseWait  Proc near
    mov ds:tcp_delete_timeout,240 * 10
    mov ds:tcp_state,STATE_LAST_ACK
    or ds:tcp_pending,FLAG_CLOSING
    call SendData
    ret
CloseCloseWait  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseConnection
;
;       Purpose:        Close connection
;
;       Parameters:     DS          Connection sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_tab:
cl0 DW OFFSET CloseDelete
cl1 DW OFFSET CloseDelete
cl2 DW OFFSET CloseNormal
cl3 DW OFFSET IgnoreDummy
cl4 DW OFFSET IgnoreDummy
cl5 DW OFFSET CloseCloseWait
cl6 DW OFFSET IgnoreDummy
cl7 DW OFFSET IgnoreDummy
cl8 DW OFFSET IgnoreDummy

CloseConnection    Proc near
    push ds
    push es
    pushad
;
    EnterSection ds:tcp_section
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].close_tab
    LeaveSection ds:tcp_section
;
    call SignalChange
;
    xor bx,bx
    xchg bx,ds:tcp_read_wait
    or bx,bx
    jz ctcNotRead
;
    SignalReadHandle

ctcNotRead:
    xor bx,bx
    xchg bx,ds:tcp_write_wait
    or bx,bx
    jz ctcNotWrite
;
    SignalWriteHandle

ctcNotWrite:
    xor bx,bx
    xchg bx,ds:tcp_exc_wait
    or bx,bx
    jz ctcNotExc
;
    SignalExceptionHandle

ctcNotExc:
    mov bx,ds:tcp_writer
    or bx,bx
    jz ctcNoWriter
;
    Signal

ctcNoWriter:
    mov bx,ds:tcp_owner
    or bx,bx
    jz ctcOwnerOk
;
    Signal

ctcOwnerOk:
    xor bx,bx
    xchg bx,ds:tcp_wait  
    or bx,bx
    clc
    jz ctcDone
;
    mov es,bx
    SignalWait
    clc

ctcDone:
    popad
    pop es
    pop ds
    ret
CloseConnection    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseTcpConnection
;
;       Purpose:        Close connection
;
;       Parameters:         BX          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_tcp_connection_name DB 'Close TCP Connection',0

close_tcp_connection    Proc far
    push ds
    push eax
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc close_tcp_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz close_tcp_done
;
    mov ds,ax
    call CloseConnection

close_tcp_done:
    pop ebx
    pop eax
    pop ds
    retf32
close_tcp_connection    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_socket_handle
;
;           DESCRIPTION:    Delete socket handle (called from handle module)
;
;           PARAMETERS:         BX              TCP CONNECTION HANDLE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_socket_handle    Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc delete_socket_handle_done
;
    push [ebx].tcp_handle_sel
    FreeHandle
    pop ds
;    
    or ax,ax
    stc
    jz delete_socket_handle_done
;    
    mov ds,ax
    EnterSection ds:tcp_section
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].close_tab
    LeaveSection ds:tcp_section
    clc

delete_socket_handle_done:
    pop dx
    pop ax
    pop es
    pop ds
    retf32
delete_socket_handle    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_listen_handle
;
;           DESCRIPTION:    Delete listen handle (called from handle module)
;
;           PARAMETERS:         BX              tcp listen handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_listen_handle    Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,TCP_LISTEN_HANDLE
    DerefHandle
    jc delete_listen_handle_done
;
    push [ebx].tcp_handle_sel
    FreeHandle
    pop ds
;    
    or ax,ax
    stc
    jz delete_listen_handle_done
;    
    mov ds,ax
    EnterSection ds:tcp_listen_section
    call DeleteListen
    clc

delete_listen_handle_done:
    pop dx
    pop ax
    pop es
    pop ds
    retf32
delete_listen_handle    Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DeleteTcpConnection
;
;       Purpose:        Delete connection handle
;
;       Parameters:         BX          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_tcp_connection_name DB 'Delete TCP Connection',0

delete_tcp_connection   Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push es
    push ax
    push ebx
;
    mov ax,SEG data
    mov es,ax
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc delete_tcp_done
;    
    xor ax,ax
    xchg ax,[ebx].tcp_handle_sel
    or ax,ax
    jz delete_tcp_handle
;
    RequestSpinlock es:ConnSpinlock    
    mov ds,ax
    test ds:tcp_pending,FLAG_UNLINKED
    jz delete_tcp_mark
;    
    ReleaseSpinlockNoSti es:ConnSpinlock
    EnterSection ds:tcp_section
    sti
;
    call DeleteConnection
    jmp delete_tcp_handle

delete_tcp_mark:
    or ds:tcp_pending,FLAG_DELETE_USER
    xor ax,ax
    mov ds,ax
    ReleaseSpinlock es:ConnSpinlock

delete_tcp_handle:
    FreeHandle
    clc

delete_tcp_done:
    pop ebx
    pop ax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
delete_tcp_connection   Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           IsTcpConnectionIdle
;
;       Purpose:        Check if connection is idle
;
;       Parameters:         BX          Connection handle
;
;   Returns:    NC      Connection is idle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_tcp_connection_idle_name DB 'Is TCP Connection Idle?',0

is_tcp_connection_idle  Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push eax
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc is_tcp_idle_ok
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    jz is_tcp_idle_ok
;
    mov ds,ax
;
    mov ax,ds:tcp_receive_count
    or ax,ax
    jnz is_tcp_idle_fail
;       
    mov ax,ds:tcp_send_count
    or ax,ax
    jnz is_tcp_idle_fail
;
    mov eax,ds:tcp_send_next
    cmp eax,ds:tcp_send_una
    jnz is_tcp_idle_fail

is_tcp_idle_ok:
    clc
    jmp is_tcp_idle_done

is_tcp_idle_fail:
    stc

is_tcp_idle_done:       
    pop ebx
    pop eax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
is_tcp_connection_idle  Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           IsTcpConnectionClosed
;
;       Purpose:        Check if connection is closed by remote site
;
;       Parameters:         BX          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_tcp_connection_closed_name DB 'Is TCP Connection Closed?',0

is_tcp_connection_closed    Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push ax
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc is_tcp_closed_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    jz is_tcp_closed_fail
;
    mov ds,ax
;
    mov ax,ds:tcp_receive_count
    or ax,ax
    jnz is_tcp_closed_ok
;       
    mov al,ds:tcp_state
    cmp al,STATE_ESTAB
    ja is_tcp_closed_fail
;
    mov ax,ds:tcp_pending
    test ax,FLAG_DELETE_NET OR FLAG_CLOSED
    jnz is_tcp_closed_fail

is_tcp_closed_ok:
    clc
    jmp is_tcp_closed_done

is_tcp_closed_fail:
    stc

is_tcp_closed_done:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
is_tcp_connection_closed    Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetRemoteTcpConnectionIP
;
;       Purpose:        Get remote IP of connection
;
;       Parameters:         BX          Connection handle
;
;   Returns:    EAX     IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_remote_tcp_connection_ip_name DB 'Get Remote TCP Connection IP',0

get_remote_tcp_connection_ip    Proc far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc get_rem_ip_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    jz get_rem_ip_fail
;
    mov ds,ax
    mov eax,ds:tcp_remote_ip
    clc
    jmp get_rem_ip_done

get_rem_ip_fail:
    stc

get_rem_ip_done:
    pop ebx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    retf32
get_remote_tcp_connection_ip    Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetRemoteTcpConnectionPort
;
;       Purpose:        Get remote port of connection
;
;       Parameters:         BX          Connection handle
;
;   Returns:    AX      port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_remote_tcp_connection_port_name DB 'Get Remote TCP Connection Port',0

get_remote_tcp_connection_port  Proc far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc get_rem_port_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    jz get_rem_port_fail
;
    mov ds,ax
    mov ax,ds:tcp_remote_port
    clc
    jmp get_rem_port_done

get_rem_port_fail:
    stc

get_rem_port_done:
    pop ebx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    retf32
get_remote_tcp_connection_port  Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetLocalTcpConnectionPort
;
;       Purpose:        Get local port of connection
;
;       Parameters:         BX          Connection handle
;
;   Returns:    AX      port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_local_tcp_connection_port_name DB 'Get Local TCP Connection Port',0

get_local_tcp_connection_port   Proc far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc get_local_port_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    jz get_local_port_fail
;
    mov ds,ax
    mov ax,ds:tcp_port
    clc
    jmp get_local_port_done

get_local_port_fail:
    stc

get_local_port_done:
    pop ebx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    retf32
get_local_tcp_connection_port   Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           AbortDelete
;
;       Purpose:        Delete abort
;
;       Parameters:         DS          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AbortDelete     Proc near
    mov ds:tcp_delete_timeout,240 * 10
    ret
AbortDelete     Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           AbortReset
;
;       Purpose:        Abort connection (reset & delete)
;
;       Parameters:         DS          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AbortReset      Proc near
    xor ecx,ecx
    call CreateSegment
    mov es:[di].tcp_flags, RST
    mov eax,ds:tcp_send_next
    Reverse
    mov es:[di].tcp_seq,eax
    call SendSegment
    mov ds:tcp_delete_timeout,240 * 10
    ret
AbortReset      Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           AbortTcpConnection
;
;       Purpose:        Abort connection
;
;       Parameters:         BX          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abort_tcp_connection_name DB 'Abort TCP Connection',0

abort_tab:
ab0     DW OFFSET AbortDelete
ab1 DW OFFSET AbortReset
ab2 DW OFFSET AbortReset
ab3     DW OFFSET AbortReset
ab4     DW OFFSET AbortReset
ab5 DW OFFSET AbortReset
ab6 DW OFFSET AbortDelete
ab7 DW OFFSET AbortDelete
ab8 DW OFFSET AbortDelete

abort_tcp_connection    Proc far
    push ds
    push es
    pushad
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc abort_tcp_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz abort_tcp_done
;
    mov ds,ax
    EnterSection ds:tcp_section
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].abort_tab
    LeaveSection ds:tcp_section
    pop bx

abort_tcp_done:
    popad
    pop es
    pop ds
    retf32
abort_tcp_connection    Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           Failed
;
;       Purpose:        Failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Failed  Proc near
    stc
    ret
Failed  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForConnection
;
;           DESCRIPTION:    Start a wait for connection
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_connection       PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:tw_handle
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc start_wait_for_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    jz start_wait_for_done
;
    mov ds,ax
    mov ds:tcp_wait,es
    mov ax,ds:tcp_receive_count
    or ax,ax
    jnz start_wait_signal
;
    mov ax,ds:tcp_pending
    test ax,FLAG_DELETE_NET
    jnz start_wait_signal
;    
    mov al,ds:tcp_state
    cmp al,STATE_ESTAB
    jbe start_wait_for_done

start_wait_signal:
    mov ds:tcp_wait,0
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
    mov bx,es:tw_handle
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc stop_wait_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    jz stop_wait_done
;
    mov ds,ax
    mov ds:tcp_wait,0

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
;           DESCRIPTION:    Clear tcp connection
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
    mov bx,es:tw_handle
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc is_idle_done
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz is_idle_done
;
    mov ds,ax
    mov ax,ds:tcp_pending
    test ax,FLAG_DELETE_NET
    stc
    jnz is_idle_done
;
    mov ax,ds:tcp_receive_count
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
;           NAME:           AddWaitForTcpConnection
;
;           DESCRIPTION:    Add a wait for TCP connection
;
;           PARAMETERS:         AX      Connection handle
;               BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_tcp_connection_name    DB 'Add Wait For TCP Connection',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_connection,    SEG code
aw1 DD OFFSET stop_wait_for_connection,     SEG code
aw2 DD OFFSET clear_connection,             SEG code
aw3 DD OFFSET is_connection_idle,           SEG code

add_wait_for_tcp_connection     PROC far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE tcp_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;
    mov es:tw_handle,ax

add_wait_done:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_tcp_connection     ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForListen
;
;           DESCRIPTION:    Start a wait for listen
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_listen   PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:tw_handle
    mov ax,TCP_LISTEN_HANDLE
    DerefHandle
    jc start_wait_for_listen_done
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jz start_wait_for_listen_done
;
    mov ds,ax
    mov ds:tcp_listen_wait,es
;
    mov ax,ds:tcp_listen_list
    or ax,ax
    jz start_wait_for_listen_done
;    
    mov ds:tcp_listen_wait,0
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
;           NAME:           StopWaitForListen
;
;           DESCRIPTION:    Stop a wait for listen
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_listen    PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:tw_handle
    mov ax,TCP_LISTEN_HANDLE
    DerefHandle
    jc stop_wait_listen_done
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    jz stop_wait_listen_done
;
    mov ds,ax
    mov ds:tcp_listen_wait,0

stop_wait_listen_done:
    pop ebx
    pop ax
    pop ds
    retf32
stop_wait_for_listen Endp


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearListen
;
;           DESCRIPTION:    Clear tcp listen
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_listen    PROC far
    retf32
clear_listen Endp


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsListenIdle
;
;           DESCRIPTION:    Check if listen is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_listen_idle  PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:tw_handle
    mov ax,TCP_LISTEN_HANDLE
    DerefHandle
    jc is_listen_idle_done
;    
    mov ax,[ebx].listen_handle_sel
    or ax,ax
    stc
    jz is_listen_idle_done
;
    mov ds,ax
    mov ax,ds:tcp_listen_list
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
;           NAME:           AddWaitForTcpListen
;
;           DESCRIPTION:    Add a wait for TCP listen
;
;           PARAMETERS:         AX      Listen handle
;               BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_tcp_listen_name    DB 'Add Wait For TCP Listen',0

add_wait_listen_tab:
al0 DD OFFSET start_wait_for_listen,        SEG code
al1 DD OFFSET stop_wait_for_listen,         SEG code
al2 DD OFFSET clear_listen,                 SEG code
al3 DD OFFSET is_listen_idle,               SEG code

add_wait_for_tcp_listen PROC far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE tcp_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_listen_tab
    AddWait
    pop ax
    jc add_wait_listen_done
;
    mov es:tw_handle,ax

add_wait_listen_done:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_tcp_listen ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           PollNormal
;
;       Purpose:        Poll connection
;
;       Parameters:     DS          connection sel
;                       ECX         wanted number of bytes
;                       ES:EDI      data buffer
;
;       Returns:        NC          ok
;                       EAX         size of received data
;                       CY          connection closed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollNormal      Proc near
    mov fs,ds:tcp_receive_buffer
    xor ebp,ebp

pnLoop:
    or ecx,ecx
    clc
    jz pnDone
;
    mov edx,ecx
    movzx eax,ds:tcp_receive_count
    or eax,eax
    jnz pnHasBytes
;
    test ds:tcp_pending,FLAG_DELETE_NET
    stc
    jnz pnDone

pnHasBytes:
    cmp ecx,eax
    jb pnSizeOk
;
    mov ecx,eax

pnSizeOk:
    add ebp,ecx
    sub ds:tcp_receive_count,cx
    mov bx,ds:tcp_receive_head
    call CopyFromBuffer
;
    xchg ecx,edx
    sub ecx,edx
    clc

pnDone:
    mov eax,ebp
    ret
PollNormal      Endp

poll_tab:
pd0 DW OFFSET Failed
pd1 DW OFFSET Failed
pd2 DW OFFSET PollNormal
pd3 DW OFFSET PollNormal
pd4 DW OFFSET PollNormal
pd5 DW OFFSET PollNormal
pd6 DW OFFSET Failed
pd7 DW OFFSET Failed
pd8 DW OFFSET Failed
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReadNormal
;
;       Purpose:        Read connection
;
;       Parameters:         EAX             timeout in ms for receive
;                       BX              connection handle
;                       (E)CX       wanted number of bytes
;                       ES:(E)DI    data buffer
;
;       Returns:        NC              ok
;                       (E)AX       size of received data
;                       CY              connection closed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_receive  Proc near
    call UpdateReceiveWnd
    test ds:tcp_pending,FLAG_ACK OR FLAG_DELAY_ACK
    jz update_rec_done
;
    and ds:tcp_pending,NOT FLAG_ACK
    call SendAck

update_rec_done:
    ret
update_receive  Endp

ReadNormal      Proc near
    mov fs,ds:tcp_receive_buffer
    xor ebp,ebp

read_tcp_loop:
    or ecx,ecx
    jz read_tcp_ok

read_tcp_retry:
    mov edx,ecx
    movzx eax,ds:tcp_receive_count
    or eax,eax
    jnz read_tcp_has_bytes
;
    test ds:tcp_pending,FLAG_DELETE_NET
    jnz read_tcp_fail

read_tcp_has_bytes:
    cmp ecx,eax
    jb read_tcp_size_ok
;
    mov ecx,eax

read_tcp_size_ok:
    add ebp,ecx
    sub ds:tcp_receive_count,cx
    mov bx,ds:tcp_receive_head
    call CopyFromBuffer
    mov ds:tcp_receive_head,bx
;
    xchg ecx,edx
    sub ecx,edx
    jz read_tcp_ok    
;
    test ds:tcp_pending, FLAG_REC_PUSH
    jz read_tcp_wait
;
    and ds:tcp_pending, NOT FLAG_REC_PUSH
    or eax,eax
    jnz read_tcp_ok

read_tcp_wait:
    test ds:tcp_pending, FLAG_CLOSED
    jnz read_tcp_ok
;
    push ecx
    push edi
    call update_receive
    ClearSignal
    GetThread
    mov ds:tcp_owner,ax
    LeaveSection ds:tcp_section
    WaitForSignal
    mov ds:tcp_owner,0
    pop edi
    pop ecx
    EnterSection ds:tcp_section
    jmp read_tcp_retry

read_tcp_fail:
    stc
    jmp read_tcp_done

read_tcp_ok:
    call update_receive
    clc

read_tcp_done:
    mov eax,ebp
    ret
ReadNormal      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReadTcpConnection
;
;       Purpose:        Read connection
;
;       Parameters:         EAX             timeout in ms for receive
;                       BX              connection handle
;                       (E)CX       wanted number of bytes
;                       ES:(E)DI    data buffer
;
;       Returns:        NC              ok
;                       (E)AX       size of received data
;                       CY              connection closed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_tcp_connection_name DB 'Read TCP Connection',0

read_tab:
rd0     DW OFFSET Failed
rd1 DW OFFSET Failed
rd2 DW OFFSET ReadNormal
rd3     DW OFFSET ReadNormal
rd4     DW OFFSET ReadNormal
rd5 DW OFFSET ReadNormal
rd6 DW OFFSET Failed
rd7 DW OFFSET Failed
rd8 DW OFFSET Failed

read_tcp_connection16   Proc far
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc read_tcp_done16
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz read_tcp_done16
;
    mov ds,ax
    movzx ecx,cx
    movzx edi,di
    EnterSection ds:tcp_section
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].read_tab
    pushf
    LeaveSection ds:tcp_section
    popf

read_tcp_done16:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    retf32
read_tcp_connection16   Endp

read_tcp_connection32   Proc far
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc read_tcp_done32
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz read_tcp_done32
;
    mov ds,ax
    EnterSection ds:tcp_section
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].read_tab
    pushf
    LeaveSection ds:tcp_section
    popf

read_tcp_done32:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    retf32
read_tcp_connection32   Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           WriteNormal
;
;       Purpose:        Write connection
;
;       Parameters:         BX              connection handle
;                       (E)CX       number of bytes to write
;                       ES:(E)DI    data buffer
;
;       Returns:        NC              ok
;                       CY              connection closed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteNormal     Proc near
    mov fs,ds:tcp_send_buffer
    mov esi,edi

write_tcp_retry:
    test ds:tcp_pending,FLAG_DELETE_NET OR FLAG_CLOSED
    jnz write_tcp_fail
;
    or ecx,ecx
    jz write_tcp_ok
;       
    mov dx,ds:tcp_buffer_size
    sub dx,ds:tcp_send_count
    movzx edx,dx
;
    mov eax,ds:tcp_send_next
    sub eax,ds:tcp_send_una
;
    sub edx,eax
    jc write_tcp_full
;
    mov eax,ecx
    cmp ecx,edx
    jc write_tcp_size_ok
;       
    mov ecx,edx

write_tcp_size_ok:      
    or ecx,ecx
    jz write_tcp_full
;
    add ds:tcp_send_count,cx
    mov bx,ds:tcp_send_tail
    call CopyToBuffer
    mov ds:tcp_send_tail,bx
;    
    xchg eax,ecx
    sub ecx,eax
    jmp write_tcp_retry

write_tcp_full:
    or ds:tcp_pending,FLAG_SEND_PUSH
    push eax
    push edi
    call SendData
    pop edi
    pop ecx
;
    ClearSignal
    GetThread
    mov ds:tcp_writer,ax
    LeaveSection ds:tcp_section
    WaitForSignal
    EnterSection ds:tcp_section
    mov ds:tcp_writer,0
    jmp write_tcp_retry

write_tcp_fail:
    stc
    jmp write_tcp_done

write_tcp_ok:
    mov ax,ds:tcp_send_count
    cmp ax,ds:tcp_mtu
    jc write_tcp_delay
;       
    call SendData
    jmp write_tcp_delay_done
    
write_tcp_delay:
    call SetSendTimeout

write_tcp_delay_done:
    clc

write_tcp_done:
    ret
WriteNormal     Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           WriteTcpConnection
;
;       Purpose:        Write connection
;
;       Parameters:         BX              connection handle
;                       (E)CX       number of bytes to write
;                       ES:(E)DI    data buffer
;
;       Returns:        NC              ok
;                       CY              connection closed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_tcp_connection_name       DB 'Write TCP Connection',0

write_tab:
wr0     DW OFFSET Failed
wr1 DW OFFSET Failed
wr2 DW OFFSET WriteNormal
wr3     DW OFFSET Failed
wr4     DW OFFSET Failed
wr5 DW OFFSET WriteNormal
wr6 DW OFFSET Failed
wr7 DW OFFSET Failed
wr8 DW OFFSET Failed

write_tcp_connection16  Proc far
    push ds
    push es
    push fs
    pushad
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc write_tcp_done16
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz write_tcp_done16
;
    mov ds,ax
    movzx ecx,cx
    movzx edi,di
    mov ds,bx
    EnterSection ds:tcp_section
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].write_tab
    pushf
    LeaveSection ds:tcp_section
    popf

write_tcp_done16:
    popad
    pop fs
    pop es
    pop ds
    retf32
write_tcp_connection16  Endp

write_tcp_connection32  Proc far
    push ds
    push es
    push fs
    pushad
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc write_tcp_done32
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz write_tcp_done32
;
    mov ds,ax
    EnterSection ds:tcp_section
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].write_tab
    pushf
    LeaveSection ds:tcp_section
    popf

write_tcp_done32:
    popad
    pop fs
    pop es
    pop ds
    retf32
write_tcp_connection32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           PushConnection
;
;       Purpose:        Push (commit) data connection
;
;       Parameters:     DS          Connection sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PushConnection     Proc near
    push es
    pushad
;
    EnterSection ds:tcp_section
    test ds:tcp_pending,FLAG_SEND_PUSH
    jnz ptcDone
;       
    mov ds:tcp_push_timeout,5
    or ds:tcp_pending,FLAG_SEND_PUSH
    call SendData

ptcDone:
    LeaveSection ds:tcp_section
    popad
    pop es
    ret
PushConnection	Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           PushTcpConnection
;
;       Purpose:        Push (commit) data connection
;
;       Parameters:         BX          Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

push_tcp_connection_name DB 'Push TCP Connection',0

push_tcp_connection     Proc far
    push ds
    push eax
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc push_tcp_done
;
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz push_tcp_done
;
    mov ds,ax
    call PushConnection

push_tcp_done:
    pop ebx
    pop eax
    pop ds
    retf32
push_tcp_connection     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           PollTcpConnection
;
;       Purpose:        Poll connection
;
;       Parameters:         BX          Connection handle
;
;   Returns:    EAX     Number of bytes in receive buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_tcp_connection_name DB 'Poll TCP Connection',0

poll_tcp_connection     Proc far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc poll_tcp_done
;
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz poll_tcp_done
;
    mov ds,ax
    EnterSection ds:tcp_section
    movzx eax,ds:tcp_receive_count
    LeaveSection ds:tcp_section
    clc

poll_tcp_done:
    pop ebx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    retf32
poll_tcp_connection     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetTcpConnectionWriteSpace
;
;       DESCRIPTION:    Get TCP connection write space
;
;       PARAMETERS;     IN  BX        Connection handle
;                       OUT EAX       Space in send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_tcp_connection_write_space_name DB 'Get Tcp connection Write Space', 0

get_tcp_connection_write_space    Proc far
    push ds
    push ebx
    push ecx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc gtcwsDone
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz gtcwsDone
;
    mov ds,ax
    EnterSection ds:tcp_section
    mov cx,ds:tcp_buffer_size
    sub cx,ds:tcp_send_count
    movzx ecx,cx
    mov eax,ds:tcp_send_next
    sub eax,ds:tcp_send_una
    sub ecx,eax
    jnc gtcwsSizeOk
;
    xor ecx,ecx

gtcwsSizeOk:
    LeaveSection ds:tcp_section
    clc

gtcwsDone:
    mov eax,ecx
    pop ecx
    pop ebx
    pop ds
    retf32
get_tcp_connection_write_space    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForWriteSpace
;
;       DESCRIPTION:    Wait for write space
;
;       PARAMETERS;     IN  BX        Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_tcp_connection_write_space_name DB 'Wait Tcp connection Write Space', 0

wait_for_tcp_connection_write_space    Proc far
    push ds
    push eax
    push ebx
    push ecx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc wcwsDone
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz wcwsDone
;
    mov ds,ax
    EnterSection ds:tcp_section
    mov cx,ds:tcp_buffer_size
    sub cx,ds:tcp_send_count
    movzx ecx,cx
    mov eax,ds:tcp_send_next
    sub eax,ds:tcp_send_una
    sub ecx,eax
    jnc wcwsSizeOk
;
    xor ecx,ecx

wcwsSizeOk:
    or ecx,ecx
    jnz wcwsLeave
;
    ClearSignal
    GetThread
    mov ds:tcp_writer,ax
    LeaveSection ds:tcp_section
;
    WaitForSignal
;
    EnterSection ds:tcp_section
    mov ds:tcp_writer,0

wcwsLeave:
    LeaveSection ds:tcp_section

wcwsDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
wait_for_tcp_connection_write_space    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartTcpConnectionNotify
;
;       DESCRIPTION:    Start TCP notify
;
;       PARAMETERS;     IN  BX        Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_tcp_connection_notify_name DB 'Start Tcp connection Notify', 0

start_tcp_connection_notify    Proc far
    push ds
    push eax
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc startNotifyDone
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz startNotifyDone
;
    mov ds,ax
    GetThread
    mov ds:tcp_signal_change,ax
    clc

startNotifyDone:
    pop ebx
    pop eax
    pop ds
    retf32
start_tcp_connection_notify    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopTcpConnectionNotify
;
;       DESCRIPTION:    Stop TCP notify
;
;       PARAMETERS;     IN  BX        Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_tcp_connection_notify_name DB 'Stop Tcp connection Notify', 0

stop_tcp_connection_notify    Proc far
    push ds
    push eax
    push ebx
;
    mov ax,TCP_SOCKET_HANDLE
    DerefHandle
    jc stopNotifyDone
;    
    mov ax,[ebx].tcp_handle_sel
    or ax,ax
    stc
    jz startNotifyDone
;
    mov ds,ax
    mov ds:tcp_signal_change,0
    clc

stopNotifyDone:
    pop ebx
    pop eax
    pop ds
    retf32
stop_tcp_connection_notify    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateConnection
;
;           DESCRIPTION:    Update a connection
;
;       PARAMETERS:     DS      connection
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateConnection    Proc near
    mov dx,ds:tcp_writer
    or dx,dx
    jz update_send_no_writer
;    
    or ds:tcp_pending,FLAG_SEND_PUSH
    
update_send_no_writer:    
    mov dx,ds:tcp_send_timeout
    or dx,dx
    jz update_send_timeout_done
;
    sub dx,1
    mov ds:tcp_send_timeout,dx
    jnz update_send_timeout_done
;
    or ds:tcp_pending,FLAG_SEND_PUSH
    
update_send_timeout_done:
    test ds:tcp_pending,FLAG_SEND_PUSH
    jz update_con_push_done
;
    mov cx,ds:tcp_send_count
    or cx,cx
    jnz update_con_check_push
;
    and ds:tcp_pending,NOT FLAG_SEND_PUSH
    jmp update_con_push_done

update_con_check_push:
    mov al,ds:tcp_push_timeout
    or al,al
    jz update_con_push_do
    dec al
    mov ds:tcp_push_timeout,al
    jmp update_con_push_done

update_con_push_do:
    call SendData

update_con_push_done:
    test ds:tcp_pending,FLAG_WAIT
    jz update_user_done
;       
    mov ax,ds:tcp_user_timeout
    sub ax,1
    mov ds:tcp_user_timeout,ax
    jnz update_user_done
;
    and ds:tcp_pending,NOT FLAG_WAIT
    mov bx,ds:tcp_owner
    Signal

update_user_done:       
    cmp ds:tcp_state,STATE_SYN_SENT
    jne update_con_syn_ok
;    
    cmp ds:tcp_remote_port,0
    je update_con_syn_ok
;

    mov ax,ds:tcp_syn_timeout
    sub ax,1
    mov ds:tcp_syn_timeout,ax
    or ax,ax
    jnz update_con_syn_ok
;    
    mov ds:tcp_syn_timeout,50
    push es
    push di
;
    xor ecx,ecx
    call CreateSegment
    jc update_con_syn_pop
;       
    GetSystemTime
    mov ds:tcp_time_val,eax
;
    mov es:[di].tcp_flags, SYN
    mov eax,ds:tcp_iss
    Reverse
    mov es:[di].tcp_seq,eax
    call SendSegment

update_con_syn_pop:
    pop di
    pop es

update_con_syn_ok:
    test dx,FLAG_DELAY_ACK
    jz update_delay_ack_done
;
    mov al,ds:tcp_ack_timeout
    sub al,1
    mov ds:tcp_ack_timeout,al
    jnz update_delay_ack_done
;
    call SendAck

update_delay_ack_done:
    mov eax,ds:tcp_send_next
    cmp eax,ds:tcp_send_una
    je update_resend_done
    mov ax,ds:tcp_resend_timeout
    sub ax,1
    mov ds:tcp_resend_timeout,ax
    jnz update_resend_done
;
    call Retransmit

update_resend_done:
    mov ax,ds:tcp_send_count
    or ax,ax
    jz update_con_done
;
    call SendData

update_con_done:
    ret
UpdateConnection    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           tcp_thread
;
;           DESCRIPTION:    supervisor thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tcp_thread_name DB 'TCP',0

LogFileName     DB 'z:\tcp.log',0

tcp_thread_pr:
    mov ax,250
    WaitMilliSec

tcp_sleep:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:TcpThread,ax
    WaitForSignal
    mov ds:TcpThread,0

tcp_active_loop:
    mov ax,ds:ConnectionList
    or ax,ax
    jz tcp_sleep
;
    EnterSection ds:ListSection
    mov ax,ds:ConnectionList
    push ds

tcp_active_next:
    or ax,ax
    jz tcp_active_wait
;
    mov ds,ax
    EnterSection ds:tcp_section
    test ds:tcp_pending,FLAG_DELETE_NET OR FLAG_DELETE_USER
    jz tcp_update
;
    test ds:tcp_pending,FLAG_WAIT
    jz tcp_user_done
;
    and ds:tcp_pending,NOT FLAG_WAIT
    mov bx,ds:tcp_owner
    Signal
    jmp tcp_update

tcp_user_done:
    or ds:tcp_pending,FLAG_UNLINKED
    mov bx,ds
    mov si,ds:tcp_next
    mov ax,SEG data
    mov ds,ax
    xor dx,dx
    mov ax,ds:ConnectionList

tcp_unlink_loop:
    cmp ax,bx
    je tcp_unlink_do
;
    mov dx,ax
    mov ds,ax
    mov ax,ds:tcp_next
    jmp tcp_unlink_loop

tcp_unlink_do:
    or dx,dx
    jz tcp_unlink_head
;
    mov ds:tcp_next,si
    jmp tcp_delete_do

tcp_unlink_head:
    mov ds:ConnectionList,si

tcp_delete_do:
    mov ax,SEG data
    mov ds,ax
    dec ds:ConnectionCount
    call CheckConnectionList    
;   
    push si
    mov ds,bx
;       
    test ds:tcp_pending,FLAG_DELETE_USER
    jnz tcp_delete_conn_del
;
    LeaveSection ds:tcp_section
    jmp tcp_delete_conn_done

tcp_delete_conn_del:
    call DeleteConnection

tcp_delete_conn_done:
    pop ax
    jmp tcp_active_next

tcp_update:
    call UpdateConnection

tcp_leave:
    mov ax,ds:tcp_delete_timeout
    or ax,ax
    jz tcp_delete_timeout_done
;
    sub ax,1
    mov ds:tcp_delete_timeout,ax
    jz tcp_delete_timeout_do
;
    GetSystemTime
    rcr edx,1
    rcr eax,1
    rcr edx,1
    rcr eax,1
    rcr edx,1
    rcr eax,1
    cmp eax,ds:tcp_send_next
    jl tcp_delete_timeout_done
    
tcp_delete_timeout_do:
    or ds:tcp_pending,FLAG_DELETE_NET
    mov bx,ds:tcp_owner
    Signal
;
    mov bx,ds:tcp_writer
    or bx,bx
    jz tcp_delete_no_writer
;
    Signal

tcp_delete_no_writer:
    xor bx,bx
    xchg bx,ds:tcp_wait  
    or bx,bx
    jz tcp_delete_timeout_done
;
    push es
    mov es,bx
    SignalWait
    pop es

tcp_delete_timeout_done:
    mov ax,ds:tcp_next
    LeaveSection ds:tcp_section
    jmp tcp_active_next

tcp_active_wait:
    pop ds
    LeaveSection ds:ListSection
    mov ax,100
    WaitMilliSec
    jmp tcp_active_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdateTcpMtu
;
;       DESCRIPTION:    Update Tcp MTU
;
;       PARAMETERS:     EDX     IP address
;                       DI      Remote port
;                       CX      New MTU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_tcp_mtu_name DB 'Update Tcp MTU', 0

update_tcp_mtu    Proc far
    push ds
    pushad
;    
    sub cx,64
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:ListSection
    mov ax,ds:ConnectionList

utmLoop:    
    or ax,ax
    jz utmLeave
;
    mov ds,ax
    cmp edx,ds:tcp_remote_ip
    jne utmNext
;
    cmp di,ds:tcp_remote_port
    jne utmNext
;
    mov ds:tcp_mtu,cx
    lock or ds:tcp_pending,FLAG_SEND_PUSH
    mov ds:tcp_push_timeout,0
    mov ds:tcp_resend_timeout,1

utmNext:    
    mov ax,ds:tcp_next
    jmp utmLoop

utmLeave:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:ListSection
;
    popad
    pop ds
    retf32
update_tcp_mtu  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ConnectTcpSocket
;
;           DESCRIPTION:    Connect TCP socket
;
;           PARAMETERS:    IN  EDX               IP
;                          IN  SI                port
;
;           RETURNS:       OUT AX                Tcp selector
;                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

connect_tcp_socket_name  DB 'Connect Tcp Socket', 0

connect_tcp_socket	Proc far
    push ds
    push ecx
    push esi
    push edi
    push ebp
;
    mov ebp,20000
    mov ecx,1000h
    mov di,si
    xor si,si
    call OpenConnection
    jc ctdFail
;
    mov ebp,20000
    call WaitForConnection
    jc ctdFail
;
    mov ax,ds
    clc
    jmp ctdDone

ctdFail:
    xor ax,ax
    stc

ctdDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ds
    retf32
connect_tcp_socket	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseTcpSocket
;
;       DESCRIPTION:    Close TCP socket
;
;       PARAMETERS:     IN  BX        Tcp selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_tcp_socket_name DB 'Close Tcp Socket', 0

close_tcp_socket    Proc far
    push ds
;
    or bx,bx
    jz ctsDone
;
    push es
    pushad
;
    mov ds,bx
    call PushConnection
    call CloseConnection
;
    popad
    pop es

ctsDone:
    pop ds
    retf32
close_tcp_socket    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PollTcpSocket
;
;       DESCRIPTION:    Poll TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       IN  ES:EDI    Buffer
;                       IN  ECX       Size
;                       OUT EAX       Read size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_tcp_socket_name DB 'Poll Tcp Socket', 0

poll_tcp_socket    Proc far
    push ds
;
    xor eax,eax
    or bx,bx
    stc
    jz ptsDone
;
    mov ds,bx
    EnterSection ds:tcp_section
    movzx eax,ds:tcp_receive_count
;
    cmp eax,ecx
    jae ptsDo
;
    mov ecx,eax

ptsDo:
    xor eax,eax
    or ecx,ecx
    clc
    jz ptsLeave
;
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov eax,2000
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].poll_tab
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es

ptsLeave:
    LeaveSection ds:tcp_section

ptsDone:
    pop ds
    retf32
poll_tcp_socket	   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadTcpSocket
;
;       DESCRIPTION:    Read TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       IN  EDX:EAX   Position
;                       IN  ES:EDI    Buffer
;                       IN  ECX       Size
;                       OUT ECX       Read size
;                       OUT EDX:EAX   New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_tcp_socket_name DB 'Read Tcp Socket', 0

read_tcp_socket    Proc far
    push ds
;
    xor eax,eax
    or bx,bx
    stc
    jz rtsDone
;
    mov ds,bx
    EnterSection ds:tcp_section
    movzx eax,ds:tcp_receive_count
;
    cmp eax,ecx
    jae rtsDo
;
    mov ecx,eax

rtsDo:
    xor eax,eax
    or ecx,ecx
    clc
    jz rtsLeave
;
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov eax,2000
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].read_tab
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es

rtsLeave:
    LeaveSection ds:tcp_section

rtsDone:
    mov ecx,eax
    xor edx,edx
    xor eax,eax
;
    pop ds
    retf32
read_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteTcpSocket
;
;       DESCRIPTION:    Write TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       IN  EDX       Position
;                       IN  ES:EDI    Buffer
;                       IN  ECX       Size
;                       OUT EAX       Written size
;                       OUT EDX       New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_tcp_socket_name DB 'Write Tcp Socket', 0

write_tcp_socket    Proc far
    push ds
;
    xor eax,eax
    or bx,bx
    jz wtsDone
;
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov ds,bx
    EnterSection ds:tcp_section
    movzx bx,ds:tcp_state
    add bx,bx
    call word ptr cs:[bx].write_tab
    jc wtsLeave
;
    test ds:tcp_pending,FLAG_SEND_PUSH
    clc
    jnz wtsLeave
;       
    mov ds:tcp_push_timeout,5
    or ds:tcp_pending,FLAG_SEND_PUSH
    call SendData
    clc

wtsLeave:
    LeaveSection ds:tcp_section
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
;
    mov eax,ecx

wtsDone:
    pop ds
    retf32
write_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartReadTcpSocket
;
;       DESCRIPTION:    Start read TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       IN  AX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_read_tcp_socket_name DB 'Start Read Tcp Socket', 0

start_read_tcp_socket    Proc far
    push ds
    push bx
    push cx
;
    or bx,bx
    stc
    jz srtsDone
;
    mov ds,bx
    mov bx,ax
    EnterSection ds:tcp_section
;
    test ds:tcp_pending,FLAG_DELETE_NET
    jnz srtsSignal
;    
    test ds:tcp_pending,FLAG_DELETE_USER
    jnz srtsSignal
;
    mov cx,ds:tcp_receive_count
    or cx,cx
    jnz srtsSignal
;
    mov ds:tcp_read_wait,ax
    jmp srtsLeave

srtsSignal:
    SignalReadHandle

srtsLeave:
    LeaveSection ds:tcp_section
    clc

srtsDone:
    pop cx
    pop bx
    pop ds
    retf32
start_read_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopReadTcpSocket
;
;       DESCRIPTION:    Stop read TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_read_tcp_socket_name DB 'Stop Read Tcp Socket', 0

stop_read_tcp_socket    Proc far
    push ds
;
    or bx,bx
    stc
    jz ertsDone
;
    mov ds,bx
    EnterSection ds:tcp_section
    mov ds:tcp_read_wait,0
    LeaveSection ds:tcp_section
    clc

ertsDone:
    pop ds
    retf32
stop_read_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartWriteTcpSocket
;
;       DESCRIPTION:    Start write TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       IN  AX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_write_tcp_socket_name DB 'Start Write Tcp Socket', 0

start_write_tcp_socket    Proc far
    push ds
    push eax
    push ebx
    push ecx
;
    or bx,bx
    jz swtsDone
;
    mov ds,bx
    mov bx,ax
    EnterSection ds:tcp_section
;
    test ds:tcp_pending,FLAG_DELETE_NET
    jnz swtsSignal
;    
    test ds:tcp_pending,FLAG_DELETE_USER
    jnz swtsSignal
;
    mov cx,ds:tcp_buffer_size
    sub cx,ds:tcp_send_count
    movzx ecx,cx
    mov eax,ds:tcp_send_next
    sub eax,ds:tcp_send_una
    sub ecx,eax
    ja swtsSignal
;
    mov ds:tcp_write_wait,es
    jmp swtsLeave

swtsSignal:
    SignalWriteHandle

swtsLeave:
    LeaveSection ds:tcp_section

swtsDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
start_write_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopWriteTcpSocket
;
;       DESCRIPTION:    Stop write TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_write_tcp_socket_name DB 'Stop Write Tcp Socket', 0

stop_write_tcp_socket    Proc far
    push ds
;
    or bx,bx
    jz ewtsDone
;
    mov ds,bx
    EnterSection ds:tcp_section
    mov ds:tcp_write_wait,0
    LeaveSection ds:tcp_section

ewtsDone:
    pop ds
    retf32
stop_write_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartExceptionTcpSocket
;
;       DESCRIPTION:    Start exception TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       IN  AX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_exception_tcp_socket_name DB 'Start Exception Tcp Socket', 0

start_exception_tcp_socket    Proc far
    push ds
    push bx
;
    or bx,bx
    jz setsDone
;
    mov ds,bx
    mov bx,ax
    EnterSection ds:tcp_section
;
    test ds:tcp_pending,FLAG_DELETE_NET
    jnz setsSignal
;    
    test ds:tcp_pending,FLAG_DELETE_USER
    jnz setsSignal
;
    mov ds:tcp_exc_wait,es
    jmp setsLeave

setsSignal:
    SignalExceptionHandle

setsLeave:
    LeaveSection ds:tcp_section

setsDone:
    pop bx
    pop ds
    retf32
start_exception_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopExceptionTcpSocket
;
;       DESCRIPTION:    Stop exception TCP socket
;
;       PARAMETERS;     IN  BX        Tcp selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_exception_tcp_socket_name DB 'Stop Exception Tcp Socket', 0

stop_exception_tcp_socket    Proc far
    push ds
;
    or bx,bx
    jz eetsDone
;
    mov ds,bx
    EnterSection ds:tcp_section
    mov ds:tcp_exc_wait,0
    LeaveSection ds:tcp_section

eetsDone:
    pop ds
    retf32
stop_exception_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetTcpSocketReadCount
;
;       DESCRIPTION:    Get TCP socket read count
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       OUT ECX       Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_tcp_socket_read_count_name DB 'Get Tcp Socket Read Count', 0

get_tcp_socket_read_count    Proc far
    push ds
;
    or bx,bx
    stc
    jz gtsrcDone
;
    mov ds,bx
    EnterSection ds:tcp_section
    movzx ecx,ds:tcp_receive_count
    LeaveSection ds:tcp_section
    clc

gtsrcDone:
    pop ds
    retf32
get_tcp_socket_read_count    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetTcpSocketWriteSpace
;
;       DESCRIPTION:    Get TCP socket write space
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       OUT ECX       Space in send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_tcp_socket_write_space_name DB 'Get Tcp Socket Write Space', 0

get_tcp_socket_write_space    Proc far
    push ds
    push eax
;
    or bx,bx
    stc
    jz gtswsDone
;
    mov ds,bx
    EnterSection ds:tcp_section
    mov cx,ds:tcp_buffer_size
    sub cx,ds:tcp_send_count
    movzx ecx,cx
    mov eax,ds:tcp_send_next
    sub eax,ds:tcp_send_una
    sub ecx,eax
    jnc gtswsSizeOk
;
    xor ecx,ecx

gtswsSizeOk:
    LeaveSection ds:tcp_section
    clc

gtswsDone:
    pop eax
    pop ds
    retf32
get_tcp_socket_write_space    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasTcpSocketException
;
;       DESCRIPTION:    Has TCP socket exception
;
;       PARAMETERS;     IN  BX        Tcp selector
;                       OUT CY        Exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_tcp_socket_exception_name DB 'Has Tcp Socket Exception', 0

has_tcp_socket_exception    Proc far
    push ds
;
    or bx,bx
    clc
    jz hseDone
;
    mov ds,bx
    EnterSection ds:tcp_section
;
    test ds:tcp_pending,FLAG_DELETE_NET
    jnz hseExc
;    
    test ds:tcp_pending,FLAG_DELETE_USER
    jnz hseExc
;
    clc
    jmp hseLeave

hseExc:
    stc

hseLeave:
    LeaveSection ds:tcp_section

hseDone:
    pop ds
    retf32
has_tcp_socket_exception    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_task_tcp
;
;           DESCRIPTION:    Init tcp driver, tasking part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task_tcp

init_task_tcp    PROC near
    mov bx,SEG data
    mov es,bx
    mov es:ConnectionList,0
    mov es:ConnectionCount,0
    mov es:ListenList,0
    mov es:Handle,0
    mov es:LastPort,545
    mov ax,es
    mov ds,ax
    InitSection ds:ListSection
    InitSpinlock ds:ConnSpinlock
;       
    mov cx,1F00h
    mov di,OFFSET PortMap
    mov al,0FFh
    rep stosb
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_socket_handle
    mov ax,TCP_SOCKET_HANDLE
    RegisterHandle
;
    mov edi,OFFSET delete_listen_handle
    mov ax,TCP_LISTEN_HANDLE
    RegisterHandle
;
    mov esi,OFFSET update_tcp_mtu
    mov edi,OFFSET update_tcp_mtu_name
    xor cl,cl
    mov ax,update_tcp_mtu_nr
    RegisterOsGate
;
    mov esi,OFFSET connect_tcp_socket
    mov edi,OFFSET connect_tcp_socket_name
    xor cl,cl
    mov ax,connect_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET close_tcp_socket
    mov edi,OFFSET close_tcp_socket_name
    xor cl,cl
    mov ax,close_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET poll_tcp_socket
    mov edi,OFFSET poll_tcp_socket_name
    xor cl,cl
    mov ax,poll_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET read_tcp_socket
    mov edi,OFFSET read_tcp_socket_name
    xor cl,cl
    mov ax,read_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET write_tcp_socket
    mov edi,OFFSET write_tcp_socket_name
    xor cl,cl
    mov ax,write_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET get_tcp_socket_read_count
    mov edi,OFFSET get_tcp_socket_read_count_name
    xor cl,cl
    mov ax,tcp_socket_read_count_nr
    RegisterOsGate
;
    mov esi,OFFSET get_tcp_socket_write_space
    mov edi,OFFSET get_tcp_socket_write_space_name
    xor cl,cl
    mov ax,tcp_socket_write_space_nr
    RegisterOsGate
;
    mov esi,OFFSET has_tcp_socket_exception
    mov edi,OFFSET has_tcp_socket_exception_name
    xor cl,cl
    mov ax,has_tcp_socket_exc_nr
    RegisterOsGate
;
    mov esi,OFFSET start_read_tcp_socket
    mov edi,OFFSET start_read_tcp_socket_name
    xor cl,cl
    mov ax,start_read_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_read_tcp_socket
    mov edi,OFFSET stop_read_tcp_socket_name
    xor cl,cl
    mov ax,stop_read_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET start_write_tcp_socket
    mov edi,OFFSET start_write_tcp_socket_name
    xor cl,cl
    mov ax,start_write_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_write_tcp_socket
    mov edi,OFFSET stop_write_tcp_socket_name
    xor cl,cl
    mov ax,stop_write_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET start_exception_tcp_socket
    mov edi,OFFSET start_exception_tcp_socket_name
    xor cl,cl
    mov ax,start_exc_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_exception_tcp_socket
    mov edi,OFFSET stop_exception_tcp_socket_name
    xor cl,cl
    mov ax,stop_exc_tcp_socket_nr
    RegisterOsGate
;
    mov esi,OFFSET start_tcp_connection_notify
    mov edi,OFFSET start_tcp_connection_notify_name
    xor cl,cl
    mov ax,start_tcp_conn_notify_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_tcp_connection_notify
    mov edi,OFFSET stop_tcp_connection_notify_name
    xor cl,cl
    mov ax,stop_tcp_conn_notify_nr
    RegisterOsGate
;
    mov esi,OFFSET open_tcp_connection
    mov edi,OFFSET open_tcp_connection_name
    xor dx,dx
    mov ax,open_tcp_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_tcp_listen
    mov edi,OFFSET create_tcp_listen_name
    xor dx,dx
    mov ax,create_tcp_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_tcp_listen
    mov edi,OFFSET get_tcp_listen_name
    xor dx,dx
    mov ax,get_tcp_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_tcp_listen
    mov edi,OFFSET close_tcp_listen_name
    xor dx,dx
    mov ax,close_tcp_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_for_tcp_connection
    mov edi,OFFSET wait_for_tcp_connection_name
    xor dx,dx
    mov ax,wait_for_tcp_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_tcp_connection
    mov edi,OFFSET close_tcp_connection_name
    xor dx,dx
    mov ax,close_tcp_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET delete_tcp_connection
    mov edi,OFFSET delete_tcp_connection_name
    xor dx,dx
    mov ax,delete_tcp_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_tcp_connection_closed
    mov edi,OFFSET is_tcp_connection_closed_name
    xor dx,dx
    mov ax,is_tcp_connection_closed_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_tcp_connection_idle
    mov edi,OFFSET is_tcp_connection_idle_name
    xor dx,dx
    mov ax,is_tcp_connection_idle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_remote_tcp_connection_ip
    mov edi,OFFSET get_remote_tcp_connection_ip_name
    xor dx,dx
    mov ax,get_remote_tcp_connection_ip_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_remote_tcp_connection_port
    mov edi,OFFSET get_remote_tcp_connection_port_name
    xor dx,dx
    mov ax,get_remote_tcp_connection_port_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_local_tcp_connection_port
    mov edi,OFFSET get_local_tcp_connection_port_name
    xor dx,dx
    mov ax,get_local_tcp_connection_port_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET abort_tcp_connection
    mov edi,OFFSET abort_tcp_connection_name
    xor dx,dx
    mov ax,abort_tcp_connection_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_tcp_connection16
    mov esi,OFFSET read_tcp_connection32
    mov edi,OFFSET read_tcp_connection_name
    mov dx,virt_es_in
    mov ax,read_tcp_connection_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_tcp_connection16
    mov esi,OFFSET write_tcp_connection32
    mov edi,OFFSET write_tcp_connection_name
    mov dx,virt_es_in
    mov ax,write_tcp_connection_nr
    RegisterUserGate
;
    mov esi,OFFSET push_tcp_connection
    mov edi,OFFSET push_tcp_connection_name
    xor dx,dx
    mov ax,push_tcp_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET poll_tcp_connection
    mov edi,OFFSET poll_tcp_connection_name
    xor dx,dx
    mov ax,poll_tcp_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_tcp_connection_write_space
    mov edi,OFFSET get_tcp_connection_write_space_name
    xor dx,dx
    mov ax,get_tcp_connection_write_space_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_for_tcp_connection_write_space
    mov edi,OFFSET wait_for_tcp_connection_write_space_name
    xor dx,dx
    mov ax,wait_for_tcp_connection_write_space_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_tcp_connection
    mov edi,OFFSET add_wait_for_tcp_connection_name
    xor dx,dx
    mov ax,add_wait_for_tcp_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_tcp_listen
    mov edi,OFFSET add_wait_for_tcp_listen_name
    xor dx,dx
    mov ax,add_wait_for_tcp_listen_nr
    RegisterBimodalUserGate
;
    mov al,6
    mov edi,OFFSET Receive
    HookIp
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET tcp_thread_pr
    mov di,OFFSET tcp_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;
    ret
init_task_tcp    ENDP

code    ENDS

    END
