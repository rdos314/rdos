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
; sslbase.ASM
; SSL RDOS interface
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
ss_ctx      DD ?,?

ssl_session_handle_seg      ENDS

ssl_connection	STRUC

sc_section		section_typ <>
sc_socket_handle        DW ?
sc_buffer_size		DW ?
sc_receive_buffer	DW ?
sc_receive_count	DW ?
sc_receive_head		DW ?
sc_receive_tail		DW ?
sc_send_buffer		DW ?
sc_send_count		DW ?
sc_send_head		DW ?
sc_send_tail		DW ?

sc_server               DW ?
sc_wait                 DW ?
sc_active               DB ?
sc_closed               DB ?

ssl_connection	ENDS

ssl_connection_handle_seg      STRUC

sc_base     handle_header <>
sc_conn_sel DW ?
sc_ctx      DD ?,?
sc_con      DD ?,?

ssl_connection_handle_seg      ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn CreateClientSession:near
    extrn FreeClientSession:near
    extrn CreateClientConnection:near
    extrn FreeClientConnection:near
    extrn HandleClientConnection:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateMem
;
;       DESCRIPTION:    Allocate SSL memory
;
;       PARAMETERS:     ECX         Size
;                       ES:EDI      File
;                       BX          Line
;
;       RETURNS:        DX:EAX      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateMem_

AllocateMem_    PROC near
    push es
    mov eax,eax
    AllocateSmallGlobalMem
    mov dx,es
    xor eax,eax
    pop es
    ret

    push ds
    push ecx
    push esi
;
    or ecx,ecx
    jnz asSome
;
    xor eax,eax
    xor edx,edx
    jz asDone

asSome: 
    dec ecx
    shr ecx,3
    inc ecx
    shl ecx,3
;
    mov esi,ssl_alloc_sel
    mov ds,esi
    EnterSection ds:ssl_section
;
    mov esi,ds:ssl_start

asLoop:
    mov eax,ds:[esi]
    or eax,eax
    jnz asNext
;
    mov eax,ds:[esi+4]
    or eax,eax
    jz asLast
;
    shr eax,8
    test eax,0FFF00000h
    jnz asCorrupt
;
    cmp eax,ecx
    jae asTake
    jmp asNext

asLast:
    mov eax,ssl_size - 8
    sub eax,esi
    cmp eax,ecx
    jae asTake
;
    stc
    jmp asDone

asNext:
    mov eax,ds:[esi+4]
    shr eax,8
    test eax,0FFF00000h
    jnz asCorrupt
;
    add esi,eax
    add esi,8
    jmp asLoop

asCorrupt:
    int 3
    stc
    jmp asDone

asTake:    
    mov edx,esi
    add edx,8
;
    sub eax,ecx
    cmp eax,8
    ja asSplit
;
    add ecx,eax
    mov ds:[esi],edi
    mov word ptr ds:[esi].mem_line,bx
    mov dword ptr ds:[esi].mem_size,ecx
    jmp asOk

asSplit:
    mov ds:[esi],edi
    mov word ptr ds:[esi].mem_line,bx
    mov dword ptr ds:[esi].mem_size,ecx
;
    add esi,ecx
    add esi,8
    mov ecx,esi
    add ecx,eax
    cmp ecx,ssl_size
    je asSetupLast
;
    sub eax,8
    xor ecx,ecx
    mov ds:[esi],ecx
    mov dword ptr ds:[esi].mem_size,eax
    jmp asOk

asSetupLast:
    xor ecx,ecx
    mov ds:[esi],ecx
    mov ds:[esi+4],ecx

asOk:
    mov eax,edx
    mov edx,ds
    LeaveSection ds:ssl_section

asDone:
    pop esi
    pop ecx
    pop ds
    ret
AllocateMem_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindBlock
;
;       DESCRIPTION:    Find memory block
;
;       PARAMETERS:     DS:EDX      Offset
;
;       RETURNS:        NC
;                           DS:ESI  Memory block
;                           DS:EDI  Previous block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindBlock    PROC near
    push eax
    push edx
;
    sub edx,8
    mov esi,ds:ssl_start
    xor edi,edi

fbLoop:
    mov eax,ds:[esi]
    or eax,eax
    jnz fbCheck
;
    mov eax,ds:[esi+4]
    or eax,eax
    jnz fbNext
    jmp fbFail

fbCheck:
    cmp edx,esi
    clc
    je fbDone

fbNext:
    mov eax,ds:[esi+4]
    shr eax,8
    test eax,0FFF00000h
    jnz fbCorrupt
;
    mov edi,esi
    add esi,eax
    add esi,8
    jmp fbLoop

fbCorrupt:
    int 3

fbFail:
    stc
    jmp fbDone

fbDone:
    pop edx
    pop eax
    ret
FindBlock    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeMem
;
;       DESCRIPTION:    Free ssl memory block
;
;       PARAMETERS:     DX:EAX         Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeMem_

FreeMem_   PROC near
    push es
    mov es,dx
    FreeMem
    pop es
    ret


    push ds
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    or dx,dx
    jz fsDone
;
    cmp dx,ssl_alloc_sel
    je fsMine
;
    int 3
    jmp fsDone

fsMine:
    mov ds,edx
    EnterSection ds:ssl_section
;
    mov edx,eax
    call FindBlock
    jnc fsDo
;
    int 3
    jmp fsLeave

fsDo:
    mov ecx,ds:[esi+4]
    shr ecx,8
;
    or edi,edi
    jz fsMergeDownOk
;
    mov eax,ds:[edi]
    or eax,eax
    jnz fsMergeDownOk
;
    mov esi,edi
    add ecx,8
    mov eax,ds:[esi+4]
    shr eax,8
    add ecx,eax

fsMergeDownOk:
    mov edi,esi
    add edi,ecx
    add edi,8
;
    mov eax,ds:[edi]
    or eax,eax
    jnz fsMergeUpOk
;
    mov eax,ds:[edi+4]
    or eax,eax
    jnz fsMergeNotLast
;
    mov ds:[esi],eax
    mov ds:[esi+4],eax
    clc
    jmp fsLeave

fsMergeNotLast:
    shr eax,8
    add eax,8
    add ecx,eax

fsMergeUpOk:
    mov dword ptr ds:[esi].mem_size,ecx
    xor eax,eax
    mov ds:[esi],eax
    clc

fsLeave:
    LeaveSection ds:ssl_section

fsDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
FreeMem_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReallocateMem
;
;       DESCRIPTION:    Reallocate mem
;
;       PARAMETERS:     DX:EAX      Address
;                       ECX         New size
;                       ES:EDI      File
;                       BX          Line
;
;       RETURNS:        DX:EAX      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReallocateMem_

ReallocateMem_    PROC near
    xor eax,eax
    xor edx,edx
    ret


    push ds
    push ecx
    push esi
    push edi
; 
    dec ecx
    shr ecx,3
    inc ecx
    shl ecx,3
;
    cmp dx,ssl_alloc_sel
    je rsMine
;
    int 3
    jmp rsDone

rsMine:
    mov ds,edx
    EnterSection ds:ssl_section
;
    mov edx,eax
    call FindBlock
    jnc rsDo
;
    int 3
    jmp rsFail

rsDo:
    mov eax,ds:[esi+4]
    shr eax,8
    sub eax,ecx
    or eax,eax
    jz rsOk
;
    cmp eax,8
    je rsOk
;
    test eax,80000000h
    jz rsShrink

rsGrow:
    add eax,ecx
    mov edi,esi
    add edi,eax
    add edi,8
    mov eax,ds:[edi]
    or eax,eax
    jnz rsFail
;
    push ecx
    mov eax,ds:[esi+4]
    shr eax,8
    mov ecx,ds:[edi+4]
    shr ecx,8
    add ecx,eax
    add ecx,8
    shl ecx,8
    mov cl,ds:[esi+4]
    mov ds:[esi+4],ecx
    pop ecx
    jmp rsDo

rsFail:    
    xor eax,eax
    xor edx,edx
    LeaveSection ds:ssl_section
    jmp rsDone

rsShrink:
    shl ecx,8
    mov cl,ds:[esi+4]
    mov ds:[esi+4],ecx
    shr ecx,8
;
    add esi,ecx
    add esi,8
    sub eax,8
    mov dword ptr ds:[esi].mem_size,eax
    xor eax,eax
    mov ds:[esi],eax

rsOk:
    mov eax,edx
    mov edx,ds
    LeaveSection ds:ssl_section

rsDone:
    pop edi
    pop esi
    pop ecx
    pop ds
    ret
ReallocateMem_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMemSize
;
;       DESCRIPTION:    Get size of ssl memory block
;
;       PARAMETERS:     DX:EAX         Address
;
;       RETURNS:        ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetMemSize_

GetMemSize_   PROC near
    push ebx
    push edx
;
    mov bx,dx
    GetSelectorBaseSize
;
    pop edx
    pop ebx
    ret



    push ds
    push eax
    push edx
    push esi
    push edi
;
    cmp dx,ssl_alloc_sel
    je gmsMine
;
    int 3
    jmp gmsDone

gmsMine:
    mov ds,edx
    EnterSection ds:ssl_section
;
    mov edx,eax
    call FindBlock
    jnc gmsGet
;
    int 3
    jmp gmsLeave

gmsGet:
    mov ecx,ds:[esi+4]
    shr ecx,8

gmsLeave:
    LeaveSection ds:ssl_section

gmsDone:
    pop edi
    pop esi
    pop edx
    pop eax
    pop ds
    ret
GetMemSize_   ENDP
        
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
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    mov eax,ssl_data_sel
    mov ds,eax
    call CreateClientSession
;
    or dx,dx
    stc
    jz cssDone
;
    mov ax,SSL_SESS_HANDLE
    mov cx,SIZE ssl_session_handle_seg
    AllocateHandle
    mov dword ptr [ebx].ss_ctx,edi
    mov word ptr [ebx].ss_ctx+4,dx
    mov [ebx].hh_sign,SSL_SESS_HANDLE
    mov bx,[ebx].hh_handle
    clc

cssDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
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
    jc cssDone
;
    les edi,fword ptr [ebx].ss_ctx
    mov eax,ssl_data_sel
    mov ds,eax
    call FreeClientSession
;
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
;           		FS:BX   Buffer pointer
;           		ES:EDI  Destination address
;
;       Returns:    	BX      New buffer pointer
;           		EDI     New destination
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
    pop cx
    ret
CopyFromBuffer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CopyToBuffer
;
;       Purpose:        Copy to buffer
;
;       Parameters:     CX      Number of bytes
;           		FS:BX       Buffer pointer
;           		ES:ESI      Source address
;
;       Returns:    	BX      New buffer pointer
;           		ESI     New source
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
;       Parameters:     BX          socket handle
;			CX          buffer size
;
;       Returns:        DS          connection selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateConnection    Proc near
    push es
    push ax
    push ecx
    push edx

    dec ecx
    and cx,0F000h
    add ecx,1000h
;
    mov eax,SIZE ssl_connection
    AllocateSmallGlobalMem
;
    mov es:sc_buffer_size,cx
    mov es:sc_socket_handle,bx
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
    mov es:sc_send_head,0
    mov es:sc_send_tail,0
;
    mov es:sc_server,0
    mov es:sc_wait,0
    mov es:sc_active,0
    mov es:sc_closed,0
;       
    mov ax,es
    mov ds,ax
    InitSection ds:sc_section
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
    push ebp
;
    mov ebp,ebx
;
    OpenTcpConnection
    jc cscDone
;
    mov eax,6000
    WaitForTcpConnection
    jnc cscOk

cscFree:
    CloseTcpConnection
    stc
    jmp cscDone

cscOk:
    call CreateConnection
;
    mov ebx,ebp
    mov ebp,ds
    mov ax,SSL_SESS_HANDLE
    DerefHandle
    jnc cscCreate
;
    mov ds,ebp
    call DeleteConnection
    jmp cscFree

cscCreate:
    les edi,fword ptr [ebx].ss_ctx
    push es
    push edi
;
    mov ds,ebp
    movzx ebx,ds:sc_socket_handle
    call CreateClientConnection
;
    mov ax,SSL_CONN_HANDLE
    mov cx,SIZE ssl_connection_handle_seg
    AllocateHandle
    mov [ebx].sc_conn_sel,bp
;
    mov dword ptr [ebx].sc_con,edi
    mov word ptr [ebx].sc_con+4,dx
;
    pop edi
    pop es
    mov dword ptr [ebx].sc_ctx,edi
    mov word ptr [ebx].sc_ctx+4,es
;
    mov [ebx].hh_sign,SSL_CONN_HANDLE
    mov bx,[ebx].hh_handle
    clc

cscDone:
    pop ebp
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
    push ds
    push ebx
    les edi,fword ptr [ebx].sc_con
    call FreeClientConnection
;
    pop ebx
    pop ds
;
    push ds
    push ebx
;
    mov ds,[ebx].sc_conn_sel
    mov bx,ds:sc_socket_handle
    CloseTcpConnection
;    
    call DeleteConnection
;
    pop ebx
    pop ds

fscDone:
    popad
    pop es
    pop ds
    ret
close_secure_connection     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           HandleSecureConnection
;
;       Purpose:        Handle a secure connection
;
;       Parameters:     BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_secure_connection_name    DB 'Handle Secure Connection',0

handle_secure_connection     Proc far
    push ds
    push es
    pushad
;
    mov ax,SSL_CONN_HANDLE
    DerefHandle
    jc hscDone
;
    mov ebp,esp
    mov edi,ss
;
    push ebx
    mov eax,8000h
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector32
    mov eax,ebx
    pop ebx
;
    push es
    push eax
    push ecx
    push edi
;
    mov es,eax
    xor edi,edi
    xor al,al
    rep stosb
;
    pop edi
    pop ecx
    pop eax
    pop es
;
    mov ss,eax
    mov esp,ecx
;
    mov dword ptr [esp-4],0
    movzx eax,[ebx].sc_conn_sel
;
    push ds
    push eax
    mov ds,eax
    GetThread
    mov ds:sc_server,ax
    pop eax
    pop ds
;
    push eax
    push edi
    push ebp
    les edi,fword ptr [ebx].sc_con
    call HandleClientConnection
    pop ebp
    pop edi
    pop eax
;
    mov ebx,ss
    mov es,ebx
;
    mov ss,edi
    mov esp,ebp
;
    FreeMem
;
    mov ds,eax
    mov ds:sc_server,0
    mov ds:sc_active,0
    mov ds:sc_closed,1
    
hscDone:
    popad
    pop es
    pop ds
    ret
handle_secure_connection     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitStart
;
;       DESCRIPTION:    Start initialization process
;
;       PARAMETERS:     EBX            Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitStart_

InitStart_   PROC near
    push ds
;
    mov ds,ebx
    mov ds:sc_active,0
;
    pop ds
    ret
InitStart_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitDone
;
;       DESCRIPTION:    Initialization process done
;
;       PARAMETERS:     EBX            Connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitDone_

InitDone_   PROC near
    push ds
    push ebx
;
    mov ds,ebx
    mov ds:sc_active,1
    mov bx,ds:sc_wait
    or bx,bx
    jz idDone
;
    Signal

idDone:
    pop ebx
    pop ds
    ret
InitDone_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateBuf
;
;       DESCRIPTION:    Allocate connection buffer
;
;       PARAMETERS:     EBX            Connection
;
;       RETURNS:        DX:EAX         Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateBuf_

AllocateBuf_   PROC near
    push ds
    push es
    push ebx    
;
    mov ds,ebx
    movzx eax,ds:sc_buffer_size
    AllocateSmallGlobalMem
    mov edx,es
    xor eax,eax
;
    pop ebx
    pop es
    pop ds
    ret
AllocateBuf_  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeBuf
;
;       DESCRIPTION:    Free connection buffer
;
;       PARAMETERS:     EBX            Connection
;                       DX:EAX         Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeBuf_

FreeBuf_   PROC near
    push es
    mov es,edx
    FreeMem
    pop es
    ret
FreeBuf_  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetReceiveSpace
;
;       DESCRIPTION:    Get space in receive buffer
;
;       PARAMETERS:     EBX            Connection
;
;       RETURNS:        ECX            Space in receive buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetReceiveSpace_

GetReceiveSpace_   PROC near
    push ds
    push ebx
;
    mov ds,ebx
    mov cx,ds:sc_buffer_size
    sub cx,ds:sc_receive_count
    movzx ecx,cx
;
    pop ebx
    pop ds
    ret
GetReceiveSpace_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddReceiveBuf
;
;       DESCRIPTION:    Add data to receive buffer
;
;       PARAMETERS:     EBX            Connection
;                       ES:EDI         Buffer
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddReceiveBuf_

AddReceiveBuf_   Proc near
    push ds
    push fs
    push ebx
;
    mov ds,ebx
    EnterSection ds:sc_section
    mov fs,ds:sc_receive_buffer
    add ds:sc_receive_count,cx
    mov bx,ds:sc_receive_tail
    call CopyToBuffer
    mov ds:sc_receive_tail,bx
    LeaveSection ds:sc_section
;
    pop ebx
    pop fs
    pop ds
    ret
AddReceiveBuf_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSendCount
;
;       DESCRIPTION:    Get bytes in send buffer
;
;       PARAMETERS:     EBX            Connection
;
;       RETURNS:        ECX            Bytes in send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetSendCount_

GetSendCount_   PROC near
    push ds
    push ebx
;
    mov ds,ebx
    movzx ecx,ds:sc_send_count
;
    pop ebx
    pop ds
    ret
GetSendCount_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSendBuf
;
;       DESCRIPTION:    Get send buffer size
;
;       PARAMETERS:     EBX            Connection
;                       ES:EDI         Buffer
;
;       RETURNS:        ECX            Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetSendBuf_

GetSendBuf_   PROC near
    push ds
    push fs
    push ecx
    push ebx
    push edi
;
    mov ds,ebx
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
GetSendBuf_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ClearSendCount
;
;       DESCRIPTION:    Remove bytes in send buffer
;
;       PARAMETERS:     EBX            Connection
;                       ECX            Bytes to remove from send buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ClearSendCount_

ClearSendCount_   PROC near
    push ds
    push ebx
;
    mov ds,ebx
    EnterSection ds:sc_section
    sub ds:sc_send_count,cx
    mov bx,ds:sc_send_head
    add bx,cx
;
    cmp bx,ds:sc_buffer_size
    jb cscSave
;
    sub bx,ds:sc_buffer_size

cscSave:
    mov ds:sc_send_head,bx
    LeaveSection ds:sc_section
;
    pop ebx
    pop ds
    ret
ClearSendCount_   Endp
                
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
    mov ds,[ebx].sc_conn_sel
    mov ds:sc_wait,ax
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
    mov ds,[ebx].sc_conn_sel
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
    mov ds,[ebx].sc_conn_sel
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
    add ds:sc_send_count,cx
    mov bx,ds:sc_send_tail
    call CopyToBuffer
    mov ds:sc_send_tail,bx
;
    xchg eax,ecx
    sub ecx,eax
    jmp wcRetry

wcFull:
    int 3

wcOk:
    clc

wcLeave:
    LeaveSection ds:sc_section
;
    mov bx,ds:sc_server
    or bx,bx
    jz wcDone
;
    Signal

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
    ret
delete_secure_connection    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateTls
;
;           DESCRIPTION:    Allocate TLS
;
;           RETURNS:        EAX         Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateTls_

AllocateTls_    Proc near
    push ds
    push es
    push ecx
;
    mov ax,flat_data_sel
    mov ds,ax
;
    GetThread
    mov es,eax
    mov ecx,es:p_tls_bitmap

atRetry:
    bsf eax, dword ptr [ecx]
    jnz atOk
;
    add ecx,4
    bsf eax, dword ptr [ecx]
    jnz atOk
;
    or eax,-1
    jmp atDone

atOk:
    btr dword ptr [ecx], eax
    jnc atRetry
;
    inc eax
    btr dword ptr [ecx], eax
    jc atDecode
;
    dec eax
    bts dword ptr [ecx], eax
    inc ecx
    jmp atRetry

atDecode:
    sub ecx,es:p_tls_bitmap
    shl ecx,3
    dec eax
    add eax,ecx

atDone:
    pop ecx
    pop es
    pop ds
    ret
AllocateTls_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeTls
;
;           DESCRIPTION:    Free TLS
;
;           PARAMETERS:     ECX         Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeTls_

FreeTls_    Proc near
    push ds
    push es
    push eax
;
    mov ax,flat_data_sel
    mov ds,ax
;
    GetThread
    mov es,eax
    mov eax,es:p_tls_bitmap
;
    cmp ecx, 64
    jae ftDone
;
    bts dword ptr [eax],ecx
    inc ecx
    bts dword ptr [eax],ecx

ftDone:
    pop eax
    pop es
    pop ds
    ret
FreeTls_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetTls
;
;           DESCRIPTION:    Get TLS data
;
;           PARAMETERS:     ECX         Entry
;
;           RETURNS:        EDX:EAX     Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetTls_

GetTls_    Proc near
    push ds
;
    GetThread
    mov ds,eax
    mov edx,ds:p_tls_array
;
    mov ax,flat_data_sel
    mov ds,ax
;
    xor eax,eax 
    cmp ecx,64
    jnc gtDone
;
    mov eax,[edx + ecx * 4]
    mov edx,[edx + ecx * 4 + 4]

gtDone:   
    pop ds
    ret
GetTls_  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetTls
;
;           DESCRIPTION:    Set TLS data
;
;           PARAMETERS:     ECX         Entry
;                           EDX:EAX     Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetTls_

SetTls_    Proc near
    push ds
    push edx
    push edi
;
    push eax
;
    GetThread
    mov ds,eax
    mov edi,ds:p_tls_array
    mov ax,flat_data_sel
    mov ds,ax
;
    pop eax
;
    cmp ecx,64
    jnc stDone
;
    mov [edi + ecx * 4], eax
    mov [edi + ecx * 4 + 4], edx

stDone:
    pop edi
    pop edx
    pop ds
    ret
SetTls_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitSecure_

InitSecure_    Proc near
    mov edx,ssl_linear
    mov ecx,ssl_size
    mov bx,ssl_alloc_sel
    CreateDataSelector32
    mov ds,ebx
    mov ebx,SIZE ssl_mem_struc
    add ebx,8
    and bl,0F8h
    mov ds:ssl_start,ebx
    InitSection ds:ssl_section
;
    xor eax,eax
    mov ds:[ebx],eax
    mov ds:[ebx+4],eax
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_secure_session
    mov ax,SSL_SESS_HANDLE
    RegisterHandle
;
    mov edi,OFFSET delete_secure_connection
    mov ax,SSL_CONN_HANDLE
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
    mov esi,OFFSET handle_secure_connection
    mov edi,OFFSET handle_secure_connection_name
    xor dx,dx
    mov ax,handle_secure_connection_nr
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
    mov ebx,OFFSET write_secure_connection16
    mov esi,OFFSET write_secure_connection32
    mov edi,OFFSET write_secure_connection_name
    mov dx,virt_es_in
    mov ax,write_secure_connection_nr
    RegisterUserGate
;
    ret
InitSecure_  ENDP

_TEXT    ENDS

    END
