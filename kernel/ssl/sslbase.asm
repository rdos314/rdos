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


secure_handle_seg      STRUC

secure_handle_base     handle_header <>
secure_handle_sel      DW ?

secure_handle_seg      ENDS


_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

    extrn CreateClientSession:near
    extrn FreeClientSession:near

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
    mov eax,SEG data
    mov ds,eax
    call CreateClientSession
;
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
;       Name:           FreeSecureSession
;
;       Purpose:        Free a secure session
;
;       Parameters:     EBX         Session handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_secure_session_name    DB 'Free Secure Session',0

free_secure_session     Proc far
    push ds
    pushad
;
    mov eax,SEG data
    mov ds,eax
    call FreeClientSession
;
    popad
    pop ds
    ret
free_secure_session     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateSecureConnection
;
;       Purpose:        Create a secure connection
;
;       Parameters:     EBX         Session handle
;
;       Returns:        NC          ok
;                       BX          connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_secure_connection_name    DB 'Create Secure Connection',0

create_secure_connection     Proc far
    push ds
    push eax
    push ecx
    push edx
;
;    call CreateConnection
;
    mov ax,SECURE_HANDLE
    mov cx,SIZE secure_handle_seg
    AllocateHandle
    mov [ebx].secure_handle_sel,dx
    mov [ebx].hh_sign,SECURE_HANDLE
    mov bx,[ebx].hh_handle
    clc
;
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
create_secure_connection     Endp

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
    mov edi,OFFSET delete_secure_connection
    mov ax,SECURE_HANDLE
    RegisterHandle
;
    mov esi,OFFSET create_secure_session
    mov edi,OFFSET create_secure_session_name
    xor dx,dx
    mov ax,create_secure_session_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET free_secure_session
    mov edi,OFFSET free_secure_session_name
    xor dx,dx
    mov ax,free_secure_session_nr
    RegisterBimodalUserGate
;
    ret
InitSecure_  ENDP

_TEXT    ENDS

    END
