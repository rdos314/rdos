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
; ssl.ASM
; SSL device driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
include ..\handle.inc
include ..\wait.inc
include dev\ssl.inc
include dev\devmsg.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

mem_struc   STRUC

mem_file       DB ?,?,?
mem_line       DB ?,?
mem_size       DB ?,?,?

mem_struc   ENDS


mem_lsb        = 0
mem_msb        = 4

ssl_mem_struc  STRUC

ssl_section section_typ <>
ssl_start   DD ?

ssl_mem_struc  ENDS

ssl_session_handle_seg      STRUC

ss_base     handle_header <>
ss_id       DD ?

ssl_session_handle_seg      ENDS

ssl_connection_handle_seg      STRUC

sc_base     handle_header <>
sc_id       DD ?

ssl_connection_handle_seg      ENDS

ssl_listen_handle_seg      STRUC

sl_base     handle_header <>
sl_id       DD ?

ssl_listen_handle_seg      ENDS

ssl_wait_header STRUC

sw_obj          wait_obj_header <>
sw_handle       DW ?

ssl_wait_header ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern init_server:near
    extern AllocateMsg:near
    extern AddMsgBuffer:near
    extern RunMsg:near
    extern GetMsgSel:near
    extern GetConnSel:near
    extern GetListenSel:near
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateSecureSession
;
;       Purpose:        Create a secure session
;
;       Returns:        EBX         Session handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_secure_session_name    DB 'Create Secure Session',0

create_secure_session     Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    call AllocateMsg
    jc crssDone
;
    mov eax,SSL_OPEN_SESSION
    call RunMsg
    jc crssDone
;
    mov edx,ebx
    mov ax,SSL_SESS_HANDLE
    mov cx,SIZE ssl_session_handle_seg
    AllocateHandle
    mov [ebx].ss_id,edx
    mov [ebx].hh_sign,SSL_SESS_HANDLE
    mov bx,[ebx].hh_handle
    clc

crssDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_secure_session     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseSecureSession
;
;       Purpose:        Close a secure session
;
;       Parameters:     EBX         Session handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_secure_session_name    DB 'Close Secure Session',0

close_secure_session     Proc far
    push ds
    push es
    pushad
;
    mov ax,SSL_SESS_HANDLE
    DerefHandle
    jc clssDone
;
    push ds:[ebx].ss_id
    FreeHandle
    pop ebx
;
    call AllocateMsg
    jc clssDone
;
    mov eax,SSL_CLOSE_SESSION
    call RunMsg

clssDone:
    popad
    pop es
    pop ds
    ret
close_secure_session     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateBuffer
;
;       Purpose:        Create a buffer
;
;       Parameters:     ECX     Buffer size
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
;       Parameters:     CX      Number of bytes
;                       FS:BX   Buffer pointer
;                       ES:EDI  Destination address
;
;       Returns:        BX      New buffer pointer
;                       EDI     New destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CopyFromBuffer

CopyFromBuffer    Proc near
    push ecx
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
    cmp bx,ds:sc_buffer_size
    jb cfbDone
;
    sub bx,ds:sc_buffer_size
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
    cmp bx,ds:sc_buffer_size
    jnz cfbWrapDone
    
    xor bx,bx
    
cfbWrapDone:
    loop cfbLoop
;       
    pop eax

cfbDone:
    pop ecx
    ret
CopyFromBuffer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CopyToBuffer
;
;       Purpose:        Copy to buffer
;
;       Parameters:     CX      Number of bytes
;                       FS:BX       Buffer pointer
;                       ES:ESI      Source address
;
;       Returns:        BX      New buffer pointer
;                       ESI     New source
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CopyToBuffer

CopyToBuffer    Proc near
    push eax
    push ecx
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
    cmp bx,ds:sc_buffer_size
    jb ctbDone
;
    sub bx,ds:sc_buffer_size
    jmp ctbDone

ctbSmall:
    or cx,cx
    jz ctbDone    

ctbLoop:
    mov al,es:[esi]
    mov fs:[bx],al
    inc bx
    inc esi
    cmp bx,ds:sc_buffer_size
    jnz ctbWrapDone
;
    xor bx,bx
    
ctbWrapDone:
    loop ctbLoop

ctbDone:
    pop ecx
    pop eax
    ret
CopyToBuffer    Endp    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateConnection
;
;       Purpose:        Create a connection and link it
;
;       Parameters:     ECX         buffer size
;                       EDX         ip address
;                       ESI         local port (0 for dynamic port)
;                       EDI         remote port
;
;       Returns:        DS          connection selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateConnection

CreateConnection    Proc near
    push es
    push ax
    push ecx
;
    dec ecx
    and cx,0F000h
    add ecx,1000h
;
    mov eax,SIZE ssl_connection
    AllocateSmallGlobalMem
;
    mov es:sc_buffer_size,cx
    mov es:sc_socket_handle,0
    mov es:sc_rem_ip,edx
    mov es:sc_rem_port,di
    mov es:sc_my_port,si
;
    call CreateBuffer
    mov es:sc_receive_buffer,ax
    mov es:sc_receive_count,0
    mov es:sc_receive_head,0
    mov es:sc_receive_tail,0
;
    call CreateBuffer
    mov es:sc_send_buffer,ax
    mov es:sc_send_count,0
    mov es:sc_send_pend,0
    mov es:sc_send_head,0
    mov es:sc_send_tail,0
;
    mov es:sc_server,0
    mov es:sc_wait_conn,0
    mov es:sc_wait_rec,0
    mov es:sc_active,0
    mov es:sc_closed,0
;       
    mov ax,es
    mov ds,ax
    InitSection ds:sc_section
;
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

    public DeleteConnection

DeleteConnection    Proc near
    push es
    push ax
    push bx
    push ecx
    push edx
    push esi
;
    mov ax,ds:sc_receive_buffer
    call FreeBuffer
;
    mov ax,ds:sc_send_buffer
    call FreeBuffer
;
    mov bx,ds
    mov es,bx
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
;       Name:           CreateListen
;
;       Purpose:        Create a listen
;
;       Parameters:     CX          max connections
;                       SI          listen port
;
;       Returns:        DS          listen selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateListen

CreateListen    Proc near
    push es
    push eax
    push edi
;
    movzx eax,cx
    dec eax
    shr eax,2
    shl eax,2
    add eax,4
    add eax,OFFSET sl_pend_mask
    AllocateSmallGlobalMem
;
    push ecx
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stosb
    pop ecx
;    
    mov es:sl_port,si
    mov es:sl_max_connections,cx
    mov es:sl_pend_count,0
    mov es:sl_wait,0
;       
    mov ax,es
    mov ds,ax
    InitSection ds:sl_section
;
    pop edi
    pop eax
    pop es
    ret
CreateListen    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DeleteListen
;
;       Purpose:        Delete a listen. ListSection & connection section
;                       must be taken prior to call
;
;       Parameters:     DS          listen selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DeleteListen

DeleteListen    Proc near
    push es
    push ebx
;
    mov ebx,ds
    mov es,ebx
    xor ebx,ebx
    mov ds,ebx
    FreeMem
;
    pop ebx
    pop es
    ret
DeleteListen    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateSecureConnection
;
;       Purpose:        Create a secure connection
;
;       Parameters:     EAX         Timeout in milliseconds for connection
;                       EBX         Session handle
;                       ECX         buffer size
;                       EDX         ip address
;                       SI          local port (0 for dynamic port)
;                       DI          remote port
;
;       Returns:        NC          ok
;                       BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_secure_connection_name    DB 'Create Secure Connection',0

create_secure_connection     Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    push eax
    mov ax,SSL_SESS_HANDLE
    DerefHandle
    pop eax
    jc crscDone
;
    mov ebx,ds:[ebx].ss_id
    movzx esi,si
    movzx edi,di
    call AllocateMsg
    jc crscDone
;
    mov eax,SSL_OPEN_CONNECTION
    call RunMsg
    jc crscDone
;
    mov edx,ebx
    mov ax,SSL_CONN_HANDLE
    mov cx,SIZE ssl_connection_handle_seg
    AllocateHandle
    mov [ebx].sc_id,edx
    mov [ebx].hh_sign,SSL_CONN_HANDLE
    mov bx,[ebx].hh_handle
    clc

crscDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_secure_connection     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseSecureConnection
;
;       Purpose:        Close a secure connection
;
;       Parameters:     BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_secure_connection_name    DB 'Close Secure Connection',0

close_secure_connection     Proc far
    push ds
    push es
    pushad
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc fscDone
;
    push ds:[ebx].sc_id
    FreeHandle
    pop ebx
;
    call AllocateMsg
    jc fscDone
;
    mov eax,SSL_CLOSE_CONNECTION
    call RunMsg

fscDone:
    popad
    pop es
    pop ds
    ret
close_secure_connection     Endp
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           WaitForSecureConnection
;
;       Purpose:        Wait for a connection
;
;       Parameters:     EAX         timeout
;                       BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_secure_connection_name    DB 'Wait For Secure Connection',0

wait_for_secure_connection Proc far
    push ds
    push eax
    push ebx
    push edx
    push ebp
;
    mov ebp,eax
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc wscDone
;    
    GetThread
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc wscDone
;
    mov ds:sc_wait_conn,ax
    mov al,ds:sc_active
    or al,al
    jnz wscDone
;
    GetSystemTime
    add eax,ebp
    adc edx,0
    WaitForSignalWithTimeout    

wscDone:
    pop ebp
    pop edx
    pop ebx
    pop eax
    pop ds  
    ret
wait_for_secure_connection Endp
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           IsSecureConnectionClose
;
;       Purpose:        Is connection closed?
;
;       Parameters:     BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_secure_connection_closed_name    DB 'Is Secure Connection Closed',0

is_secure_connection_closed Proc far
    push ds
    push eax
    push ebx
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc isccDone
;    
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc isccDone
;
    mov al,ds:sc_closed
    or al,al
    clc
    jz isccDone
;
    stc

isccDone:
    pop ebx
    pop eax
    pop ds  
    ret
is_secure_connection_closed Endp

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
    push eax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc swfcDone
;    
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc swfcDone
;
    mov ds:sc_wait_rec,es
    mov ax,ds:sc_receive_count
    or ax,ax
    jnz swfcSignal
;
    mov al,ds:sc_closed
    or al,al
    jz swfcDone

swfcSignal:
    mov ds:sc_wait_rec,0
    SignalWait

swfcDone:
    pop ebx
    pop eax
    pop ds
    ret
start_wait_for_connection Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForConnection
;
;           DESCRIPTION:    Stop a wait for connection
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_connection    PROC far
    push ds
    push eax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc swDone
;    
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc swDone
;
    mov ds:sc_wait_rec,0

swDone:
    pop ebx
    pop eax
    pop ds
    ret
stop_wait_for_connection Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearConnection
;
;           DESCRIPTION:    Clear tcp connection
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_connection    PROC far
    ret
clear_connection Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsConnectionIdle
;
;           DESCRIPTION:    Check if connection is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_connection_idle      PROC far
    push ds
    push eax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc iiDone
;    
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc iiDone
;
    mov ds,ax
    mov al,ds:sc_closed
    or al,al
    stc
    jnz iiDone
;
    mov ax,ds:sc_receive_count
    or ax,ax
    clc
    je iiDone
;
    stc

iiDone:
    pop ebx
    pop eax
    pop ds
    ret
is_connection_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForSecureConnection
;
;           DESCRIPTION:    Add a wait for secure connection
;
;           PARAMETERS:     AX      Connection handle
;                           BX      Wait handle
;                           ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_secure_connection_name    DB 'Add Wait For Secure Connection',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_connection,    SEG _TEXT
aw1 DD OFFSET stop_wait_for_connection,     SEG _TEXT
aw2 DD OFFSET clear_connection,             SEG _TEXT
aw3 DD OFFSET is_connection_idle,           SEG _TEXT

add_wait_for_secure_connection     PROC far
    push ds
    push es
    push eax
    push edi
;
    push eax
    mov eax,cs
    mov es,eax
    mov eax,SIZE ssl_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop eax
    jc awDone
;
    mov es:sw_handle,ax

awDone:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_secure_connection     ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           PollSecureConnection
;
;       Purpose:        Poll secure connection
;
;       Parameters:     BX              connection handle
;
;       Returns:        NC              ok
;                           EAX         bytes available
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_secure_connection_name       DB 'Poll Secure Connection',0

poll_secure_connection  Proc far
    push ds
    push ebx
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc pcDone
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc pcDone
;
    movzx eax,ds:sc_receive_count
    clc

pcDone:
    pop ebx
    pop ds
    ret
poll_secure_connection  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           PushSecureConnection
;
;       Purpose:        Push secure connection
;
;       Parameters:     BX              connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

push_secure_connection_name       DB 'Push Secure Connection',0

push_secure_connection  Proc far
    push ds
    push es
    pushad
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc pscDone
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc pscDone
;
    mov ax,ds:sc_send_pend
    or ax,ax
    jnz pscSend
;
    call AllocateMsg
    jc pscDone
;
    mov eax,SSL_PUSH_CONNECTION
    call RunMsg
    jmp pscDone

pscSend:
    EnterSection ds:sc_section
    xor ax,ax
    xchg ax,ds:sc_send_pend
    add ds:sc_send_count,ax
    LeaveSection ds:sc_section
;
    mov bx,ds:sc_server
    or bx,bx
    jz pscDone
;
    Signal

pscDone:
    popad
    pop es
    pop ds
    ret
push_secure_connection  Endp
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetRemoteSecureConnectionIP
;
;       Purpose:        Get remote IP of connection
;
;       Parameters:     BX      Connection handle
;
;       Returns:        EAX     IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_remote_secure_ip_name DB 'Get Remote Secure Connection IP',0

get_remote_secure_ip    Proc far
    push ds
    push ebx
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc grsiDone
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc grsiDone
;
    mov eax,ds:sc_rem_ip
    clc

grsiDone:
    pop ebx
    pop ds
    ret
get_remote_secure_ip    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetRemoteSecureConnectionPort
;
;       Purpose:        Get remote port of connection
;
;       Parameters:     BX      Connection handle
;
;       Returns:        AX      port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_remote_secure_port_name DB 'Get Remote Secure Connection Port',0

get_remote_secure_port  Proc far
    push ds
    push ebx
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc grspDone
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc grspDone
;
    mov ax,ds:sc_rem_port
    clc

grspDone:
    pop ebx
    pop ds
    ret
get_remote_secure_port  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetLocalSecureConnectionPort
;
;       Purpose:        Get local port of connection
;
;       Parameters:     BX      Connection handle
;
;       Returns:        AX      port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_local_secure_port_name DB 'Get Local Secure Connection Port',0

get_local_secure_port  Proc far
    push ds
    push ebx
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc glspDone
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc glspDone
;
    mov ax,ds:sc_my_port
    clc

glspDone:
    pop ebx
    pop ds
    ret
get_local_secure_port  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           IsSecureConnectionIdle
;
;       Purpose:        Check if connection is idle
;
;       Parameters:     BX      Connection handle
;
;       Returns:        NC      Connection is idle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_secure_connection_idle_name DB 'Is Secure Connection Idle?',0

is_secure_connection_idle  Proc far
    push ds
    push eax
    push ebx
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc isciOk
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc isciOk
;
    mov al,ds:sc_closed
    or al,al
    jnz isciOk
;
    mov ax,ds:sc_receive_count
    or ax,ax
    je isciOk
;
    stc
    jmp isciDone

isciOk:
    clc

isciDone:
    pop ebx
    pop eax
    pop ds
    ret
is_secure_connection_idle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetSecureConnectionWriteSpace
;
;       DESCRIPTION:    Get secure connection write space
;
;       PARAMETERS:     BX        Connection handle
;
;       RETURNS:        EAX       Space in send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_secure_write_space_name DB 'Get Secure connection Write Space', 0

get_secure_write_space    Proc far
    push ds
    push ebx
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc gswsDone
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc gswsDone
;
    mov ax,ds:sc_buffer_size
    sub ax,ds:sc_send_count
    sub ax,ds:sc_send_pend
    movzx eax,ax
    clc

gswsDone:
    pop ebx
    pop ds
    ret
get_secure_write_space    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReadSecureConnection
;
;       Purpose:        Read secure connection
;
;       Parameters:     BX              connection handle
;                       (E)CX           max number of bytes to read
;                       ES:(E)DI        data buffer
;
;       Returns:        NC              ok
;                           EAX         bytes read
;                       CY              connection closed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_secure_connection_name       DB 'Read Secure Connection',0

ReadConnection   Proc near
    push ds
    push fs
    push ecx
    push edi
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc rcDone
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc rcDone
;
    EnterSection ds:sc_section
;
    movzx eax,ds:sc_receive_count
    cmp ax,ds:sc_buffer_size
    pushfd
;
    cmp ecx,eax
    jbe rcSizeOk
;
    mov ecx,eax

rcSizeOk:
    movzx eax,cx
    sub ds:sc_receive_count,cx
    mov fs,ds:sc_receive_buffer
    mov bx,ds:sc_receive_head
    call CopyFromBuffer
    mov ds:sc_receive_head,bx
    LeaveSection ds:sc_section
;
    popfd
    jne rcServerOk
;
    push ebx
    mov bx,ds:sc_server
    Signal
    pop ebx

rcServerOk:
    clc

rcDone:
    pop edi
    pop ecx
    pop fs
    pop ds
    ret
ReadConnection   Endp

read_secure_connection16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call ReadConnection
;
    pop edi
    pop ecx
    ret
read_secure_connection16  Endp

read_secure_connection32  Proc far
    call ReadConnection
    ret
read_secure_connection32  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           WriteSecureConnection
;
;       Purpose:        Write secure connection
;
;       Parameters:     BX              connection handle
;                       (E)CX           number of bytes to write
;                       ES:(E)DI        data buffer
;
;       Returns:        NC              ok
;                       CY              connection closed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_secure_connection_name       DB 'Write Secure Connection',0

WriteConnection   Proc near
    push ds
    push fs
    pushad
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc wcDone
;
    mov ebx,[ebx].sc_id
    call GetConnSel
    jc wcDone
;
    EnterSection ds:sc_section

    mov fs,ds:sc_send_buffer
    mov esi,edi

wcRetry:
    mov al,ds:sc_active
    or al,al
    stc
    jz wcLeave
;
    or ecx,ecx
    jz wcOk
;       
    mov dx,ds:sc_buffer_size
    sub dx,ds:sc_send_count
    sub dx,ds:sc_send_pend
    movzx edx,dx
;
    mov eax,ecx
    cmp ecx,edx
    jc wcSizeOk
;       
    mov ecx,edx

wcSizeOk:      
    or ecx,ecx
    jz wcFull
;
    add ds:sc_send_pend,cx
    mov bx,ds:sc_send_tail
    call CopyToBuffer
    mov ds:sc_send_tail,bx
;
    xchg eax,ecx
    sub ecx,eax
    jmp wcRetry

wcFull:
    mov ecx,eax
    xor ax,ax
    xchg ax,ds:sc_send_pend
    add ds:sc_send_count,ax
    LeaveSection ds:sc_section
;
    mov bx,ds:sc_server
    or bx,bx
    stc
    jz wcDone
;
    Signal
;
    mov ax,10
    WaitMilliSec
;
    EnterSection ds:sc_section
    jmp wcRetry

wcOk:
    clc

wcLeave:
    LeaveSection ds:sc_section

wcDone:
    popad
    pop fs
    pop ds
    ret
WriteConnection   Endp

write_secure_connection16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call WriteConnection
;
    pop edi
    pop ecx
    ret
write_secure_connection16  Endp

write_secure_connection32  Proc far
    call WriteConnection
    ret
write_secure_connection32  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetSecureConnectionCertificate
;
;       Purpose:        Get secure connection certificate in JSON format
;
;       Parameters:     BX              connection handle
;                       ES:(E)DI        buffer
;                       (E)CX           buffer size
;
;       Returns:        NC              ok
;                         ECX           size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_secure_connection_cert_name       DB 'Get Secure Connection Certificate',0

GetConnectionCert   Proc near
    push ds
    push es
    push gs
    push eax
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    mov eax,es
    mov gs,eax
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc gccDone
;
    push edi
    mov ebx,[ebx].sc_id
    call AllocateMsg
    pop edi
    jc gccDone
;
    call AddMsgBuffer
;
    mov eax,SSL_GET_CONNECTION_CERT
    call RunMsg
;
    mov ecx,ebp

gccDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    pop gs
    pop es
    pop ds
    ret
GetConnectionCert   Endp

get_secure_connection_cert16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call GetConnectionCert
;
    pop edi
    pop ecx
    ret
get_secure_connection_cert16  Endp

get_secure_connection_cert32  Proc far
    call GetConnectionCert
    ret
get_secure_connection_cert32  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetCertificateJson
;
;       Purpose:        Get certificate in JSON format
;
;       Parameters:     DS:(E)SI        Filename
;                       ES:(E)DI        buffer
;                       (E)CX           buffer size
;
;       Returns:        NC              ok
;                         ECX           size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cert_json_name       DB 'Get Certificate Json',0

GetCertJson   Proc near
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    mov eax,ds
    mov fs,eax    
    mov eax,es
    mov gs,eax
;
    push edi
    call AllocateMsg
    mov ebp,edi
    pop edi
    jc gcjDone
;
    push edi
    mov edi,ebp

gcjCopyPath:
    lods byte ptr fs:[esi]
    stosb
    or al,al
    jnz gcjCopyPath
;
    pop edi
;
    call AddMsgBuffer
;
    mov eax,SSL_GET_CERT_JSON
    call RunMsg
;
    mov ecx,ebp

gcjDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
GetCertJson   Endp

get_cert_json16  Proc far
    push ecx
    push esi
    push edi
;
    movzx ecx,cx
    movzx esi,si
    movzx edi,di
    call GetCertJson
;
    pop edi
    pop esi
    pop ecx
    ret
get_cert_json16  Endp

get_cert_json32  Proc far
    call GetCertJson
    ret
get_cert_json32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateSecureListen
;
;       Purpose:        Create a secure listen handle
;
;       Parameters:     AX      max connections
;                       ECX     buffer size
;                       SI      local port
;
;       Returns:        BX      listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_secure_listen_name  DB 'Create Secure listen',0

create_secure_listen       Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    movzx eax,ax
    movzx esi,si
    call AllocateMsg
    jc crslDone
;
    mov eax,SSL_OPEN_SERVER
    call RunMsg
    jc crslDone
;
    mov edx,ebx
    mov ax,SSL_LISTEN_HANDLE
    mov cx,SIZE ssl_session_handle_seg
    AllocateHandle
    mov [ebx].ss_id,edx
    mov [ebx].hh_sign,SSL_LISTEN_HANDLE
    mov bx,[ebx].hh_handle
    clc

crslDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_secure_listen   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetSecureListen
;
;       Purpose:        Get a connection from a listen
;
;       Parameters:     BX      listen handle
;
;       Returns:        AX      connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_secure_listen_name     DB 'Get Secure listen',0

get_secure_listen  Proc far
    push ds
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov ax,SSL_LISTEN_HANDLE
    DerefHandle
    jc glDone
;
    mov ebx,ds:[ebx].sl_id
    call GetListenSel
    jc glDone
;
    EnterSection ds:sl_section
;
    mov cx,ds:sl_pend_count
    or cx,cx
    jz glLeave
;
    xor eax,eax
    xor edx,edx
    mov esi,OFFSET sl_pend_mask

glLoop:
    lodsb
    or al,al
    jz glNext
;
    bsf ecx,eax
    add edx,ecx
    jmp glMsg

glNext:
    add edx,8
    jmp glLoop

glLeave:
    LeaveSection ds:sl_section
    jmp glDone

glMsg:
    btr ds:sl_pend_mask,edx
    dec ds:sl_pend_count
    LeaveSection ds:sl_section
;
    movzx eax,cx  
    inc eax  
    call AllocateMsg
    jc glDone
;
    mov eax,SSL_ACCEPT_SERVER
    call RunMsg
    jc glDone
;
    mov edx,ebx
    mov ax,SSL_CONN_HANDLE
    mov cx,SIZE ssl_connection_handle_seg
    AllocateHandle
    mov [ebx].sc_id,edx
    mov [ebx].hh_sign,SSL_CONN_HANDLE
    mov ax,[ebx].hh_handle
    clc

glDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds  
    ret
get_secure_listen  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CloseSecureListen
;
;       Purpose:        Close listen
;
;       Parameters:     BX          Listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_secure_listen_name DB 'Close Secure Listen',0

close_secure_listen    Proc far
    push ds
    push es
    pushad
;
    mov ax,SSL_LISTEN_HANDLE
    DerefHandle
    jc clslDone
;
    push ds:[ebx].sl_id
    FreeHandle
    pop ebx
;
    call AllocateMsg
    jc clslDone
;
    mov eax,SSL_CLOSE_SERVER
    call RunMsg

clslDone:
    popad
    pop es
    pop ds
    ret
close_secure_listen    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SetSecureCertificate
;
;       Purpose:        Set certificate
;
;       Parameters:     BX          Listen handle
;                       DS:(E)SI    Cert filename
;                       ES:(E)DI    Key gilename
;                       ES:(E)DX    Chain filemane
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_secure_cert_name DB 'Set Secure Certificate',0

set_secure_cert    Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov eax,ds
    mov fs,eax
    mov eax,es
    mov gs,eax
    mov ebp,esi
    mov esi,edi
;
    mov ax,SSL_LISTEN_HANDLE
    DerefHandle
    jc sscDone
;
    mov ebx,ds:[ebx].sl_id
    call AllocateMsg
    jc sscDone
;
    push esi
;
    mov esi,ebp

sscCopyCert:
    lods byte ptr fs:[esi]
    stosb
    or al,al
    jnz sscCopyCert
;    
    pop esi
;
    mov eax,edi
    sub eax,SIZE ssl_reg
    mov es:reg_esi,eax

sscCopyKey:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz sscCopyKey
;
    mov eax,edi
    sub eax,SIZE ssl_reg
    mov es:reg_edx,eax
    mov esi,edx

sscCopyChain:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz sscCopyChain
;
    mov eax,SSL_SERVER_CERT
    call RunMsg

sscDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
set_secure_cert    Endp

set_secure_cert16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call set_secure_cert
;
    pop edi
    pop esi
    ret
set_secure_cert16  Endp

set_secure_cert32  Proc far
    call set_secure_cert
    ret
set_secure_cert32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForListen
;
;           DESCRIPTION:    Start a wait for listen
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_listen       PROC far
    push ds
    push eax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SSL_LISTEN_HANDLE
    DerefHandle
    jc swflDone
;    
    mov ebx,[ebx].sl_id
    call GetListenSel
    jc swflDone
;
    mov ds:sl_wait,es
    mov ax,ds:sl_pend_count
    or ax,ax
    jz swflDone
;
    mov ds:sl_wait,0
    SignalWait

swflDone:
    pop ebx
    pop eax
    pop ds
    ret
start_wait_for_listen Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForListen
;
;           DESCRIPTION:    Stop a wait for listen
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_listen    PROC far
    push ds
    push eax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SSL_LISTEN_HANDLE
    DerefHandle
    jc swlDone
;    
    mov ebx,[ebx].sl_id
    call GetListenSel
    jc swlDone
;
    mov ds:sl_wait,0

swlDone:
    pop ebx
    pop eax
    pop ds
    ret
stop_wait_for_listen Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearListen
;
;           DESCRIPTION:    Clear listen
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_listen    PROC far
    ret
clear_listen Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsListenIdle
;
;           DESCRIPTION:    Check if listen is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_listen_idle      PROC far
    push ds
    push eax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SSL_LISTEN_HANDLE
    DerefHandle
    jc iliDone
;    
    mov ebx,[ebx].sl_id
    call GetListenSel
    jc iliDone
;
    mov ds,ax
    mov ax,ds:sl_pend_count
    or ax,ax
    clc
    je iliDone
;
    stc

iliDone:
    pop ebx
    pop eax
    pop ds
    ret
is_listen_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForSecureListen
;
;           DESCRIPTION:    Add a wait for secure listen
;
;           PARAMETERS:     AX      Connection handle
;                           BX      Wait handle
;                           ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_secure_listen_name    DB 'Add Wait For Secure Listen',0

add_waitl_tab:
awl0 DD OFFSET start_wait_for_listen,    SEG _TEXT
awl1 DD OFFSET stop_wait_for_listen,     SEG _TEXT
awl2 DD OFFSET clear_listen,             SEG _TEXT
awl3 DD OFFSET is_listen_idle,           SEG _TEXT

add_wait_for_secure_listen     PROC far
    push ds
    push es
    push eax
    push edi
;
    push eax
    mov eax,cs
    mov es,eax
    mov eax,SIZE ssl_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_waitl_tab
    AddWait
    pop eax
    jc awlDone
;
    mov es:sw_handle,ax

awlDone:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_secure_listen     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_secure_session
;
;           DESCRIPTION:    Delete secure session (called from handle module)
;
;           PARAMETERS:     BX              SECURE SESSION HANDLE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_secure_session    Proc far
    push ds
    push es
    pushad
;
    mov ax,SSL_SESS_HANDLE
    DerefHandle
    jc dssDone
;
    push ds:[ebx].ss_id
    FreeHandle
    pop ebx
;
    call AllocateMsg
    jc dssDone
;
    mov eax,SSL_CLOSE_SESSION
    call RunMsg

dssDone:
    popad
    pop es
    pop ds
    ret
delete_secure_session    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_secure_connection
;
;           DESCRIPTION:    Delete secure connection (called from handle module)
;
;           PARAMETERS:     BX              SECURE CONNECTION HANDLE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_secure_connection    Proc far
    push ds
    push es
    pushad
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc dscDone
;
    push ds:[ebx].sc_id
    FreeHandle
    pop ebx
;
    call AllocateMsg
    jc dscDone
;
    mov eax,SSL_CLOSE_CONNECTION
    call RunMsg

dscDone:
    popad
    pop es
    pop ds
    ret
delete_secure_connection    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_secure_listen
;
;           DESCRIPTION:    Delete secure listen (called from handle module)
;
;           PARAMETERS:     BX              SECURE LISTEN HANDLE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_secure_listen    Proc far
    push ds
    push es
    pushad
;
    mov ax,SSL_LISTEN_HANDLE
    DerefHandle
    jc dslDone
;
    push ds:[ebx].sl_id
    FreeHandle
    pop ebx
;
    call AllocateMsg
    jc dslDone
;
    mov eax,SSL_CLOSE_SERVER
    call RunMsg

dslDone:
    popad
    pop es
    pop ds
    ret
delete_secure_listen     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_ssl_thread
;
;           DESCRIPTION:    init ssl thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_ssl_name      DB 'Init SSL',0

init_ssl_thread:
    call GetMsgSel
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_ssl
;
;           DESCRIPTION:    init ssl module
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_ssl      Proc far
    push ds
    push es
    pushad
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov edi,OFFSET init_ssl_name
    mov esi,OFFSET init_ssl_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;       
    popad
    pop es
    pop ds
    ret
init_ssl      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    call init_server
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_ssl
    HookInitTasking
;
    mov edi,OFFSET delete_secure_session
    mov ax,SSL_SESS_HANDLE
    RegisterHandle
;
    mov edi,OFFSET delete_secure_connection
    mov ax,SSL_CONN_HANDLE
    RegisterHandle
;
    mov edi,OFFSET delete_secure_listen
    mov ax,SSL_LISTEN_HANDLE
    RegisterHandle
;
    mov esi,OFFSET create_secure_session
    mov edi,OFFSET create_secure_session_name
    xor dx,dx
    mov ax,create_secure_session_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_secure_session
    mov edi,OFFSET close_secure_session_name
    xor dx,dx
    mov ax,close_secure_session_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_secure_connection
    mov edi,OFFSET create_secure_connection_name
    xor dx,dx
    mov ax,create_secure_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_secure_connection
    mov edi,OFFSET close_secure_connection_name
    xor dx,dx
    mov ax,close_secure_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_for_secure_connection
    mov edi,OFFSET wait_for_secure_connection_name
    xor dx,dx
    mov ax,wait_for_secure_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_secure_connection_closed
    mov edi,OFFSET is_secure_connection_closed_name
    xor dx,dx
    mov ax,is_secure_connection_closed_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_secure_connection_idle
    mov edi,OFFSET is_secure_connection_idle_name
    xor dx,dx
    mov ax,is_secure_connection_idle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET push_secure_connection
    mov edi,OFFSET push_secure_connection_name
    xor dx,dx
    mov ax,push_secure_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET push_secure_connection
    mov edi,OFFSET push_secure_connection_name
    xor dx,dx
    mov ax,push_secure_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_remote_secure_ip
    mov edi,OFFSET get_remote_secure_ip_name
    xor dx,dx
    mov ax,get_remote_secure_ip_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_remote_secure_port
    mov edi,OFFSET get_remote_secure_port_name
    xor dx,dx
    mov ax,get_remote_secure_port_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_local_secure_port
    mov edi,OFFSET get_local_secure_port_name
    xor dx,dx
    mov ax,get_local_secure_port_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET poll_secure_connection
    mov edi,OFFSET poll_secure_connection_name
    xor dx,dx
    mov ax,poll_secure_connection_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_secure_write_space
    mov edi,OFFSET get_secure_write_space_name
    xor dx,dx
    mov ax,get_secure_write_space_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_secure_connection
    mov edi,OFFSET add_wait_for_secure_connection_name
    xor dx,dx
    mov ax,add_wait_for_secure_connection_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_secure_connection16
    mov esi,OFFSET read_secure_connection32
    mov edi,OFFSET read_secure_connection_name
    mov dx,virt_es_in
    mov ax,read_secure_connection_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_secure_connection16
    mov esi,OFFSET write_secure_connection32
    mov edi,OFFSET write_secure_connection_name
    mov dx,virt_es_in
    mov ax,write_secure_connection_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_secure_connection_cert16
    mov esi,OFFSET get_secure_connection_cert32
    mov edi,OFFSET get_secure_connection_cert_name
    mov dx,virt_es_in
    mov ax,get_secure_connection_cert_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_cert_json16
    mov esi,OFFSET get_cert_json32
    mov edi,OFFSET get_cert_json_name
    mov dx,virt_es_in
    mov ax,get_cert_json_nr
    RegisterUserGate
;
    mov esi,OFFSET create_secure_listen
    mov edi,OFFSET create_secure_listen_name
    xor dx,dx
    mov ax,create_secure_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_secure_listen
    mov edi,OFFSET get_secure_listen_name
    xor dx,dx
    mov ax,get_secure_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_secure_listen
    mov edi,OFFSET close_secure_listen_name
    xor dx,dx
    mov ax,close_secure_listen_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_secure_listen
    mov edi,OFFSET add_wait_for_secure_listen_name
    xor dx,dx
    mov ax,add_wait_for_secure_listen_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET set_secure_cert16
    mov esi,OFFSET set_secure_cert32
    mov edi,OFFSET set_secure_cert_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,set_secure_cert_nr
    RegisterUserGate
    clc
;
    ret
init  ENDP

code    ENDS

    END init
