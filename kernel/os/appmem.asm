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
; APPMEM.ASM
; Application memory allocation module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE ..\serv.def
INCLUDE servdev.def

small_linear_struc      STRUC
slf_prev    DD ?
slf_next    DD ?
sls_prev    DD ?
sls_next    DD ?
small_linear_struc      ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitServMem
;
;           DESCRIPTION:    Create serv mem
;
;           PARAMETERS:     BX     Ldt obj
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitServMem

InitServMem  Proc near
    push ds
    push es
    pushad
;
    GetThread
    mov ds,ax
    mov ds:p_serv_sel,bx
;
    mov ds,bx
    mov es,bx
    mov edx,serv_size - serv_byte_size
    mov ds:serv_big_avail_mem,edx
    InitSection ds:serv_big_section
;
    mov edx,serv_byte_size - 10h
    mov ds:serv_small_avail_mem,edx
    InitSection ds:serv_small_section
;
    mov ds:serv_big_used_mem,0
    mov ds:serv_small_used_mem,0
;
    mov di,OFFSET serv_gate_arr
    xor ax,ax
    mov cx,serv_gate_entries
    rep stosw
;
    mov ax,serv_byte_sel
    mov ds,ax
    xor eax,eax
    mov edx,10h
    mov [eax].slf_next,edx
    mov [eax].sls_next,edx
    mov [eax].sls_prev,edx
    mov eax,edx
    mov edx,serv_byte_size - 10h
    mov [eax].slf_prev,0
    mov [eax].slf_next,0
    mov [eax].sls_prev,0
    mov [eax].sls_next,edx
;
    popad
    pop es
    pop ds
    ret
InitServMem  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateSmallServ
;
;           DESCRIPTION:    Allocate byte-aligned (dword) server memory
;
;           PARAMETERS:     EAX         # of bytes
;
;           RETURNS:        ES          LDT sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_small_serv_name      DB 'Allocate Small Server',0

allocate_small_serv   PROC far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    push ax
    GetThread
    mov ds,ax
    mov ax,ds:p_serv_sel
    mov ds,ax
    mov es,ax
    pop ax
;
    EnterSection ds:serv_small_section
    push ds
    push eax
;       
    dec eax
    and al,0FCh
    add eax,4
;
    add eax,10h
;
    mov dx,serv_byte_sel
    mov ds,dx
    xor edx,edx
    xor ebx,ebx
    mov edx,[edx].slf_next

assLoop:
    mov ecx,[edx].sls_next
    sub ecx,edx
    cmp ecx,eax
    jnc assFound
;
    mov ebx,edx
    mov edx,[edx].slf_next
    jmp assLoop

assFound:
    sub ecx,eax
    cmp ecx,16
    jc assNoSplit
;
    mov ebx,eax
    add ebx,edx
;       
    mov eax,[edx].sls_next
    mov [ebx].sls_next,eax
    mov [ebx].sls_prev,edx
    mov [edx].sls_next,ebx
    mov [eax].sls_prev,ebx
;
    mov eax,[edx].slf_next
    mov [ebx].slf_next,eax
    mov [edx].slf_next,ebx
    or eax,eax
    jz assLastFree
;
    mov [eax].slf_prev,ebx

assLastFree:
    mov eax,[edx].slf_prev
    mov [ebx].slf_prev,eax
    or eax,eax
    jz assFirstFree
;
    mov [eax].slf_next,ebx

assFirstFree:
    jmp assDone

assNoSplit:
    mov eax,[edx].slf_prev
    mov ebx,[edx].slf_next
    mov [eax].slf_next,ebx
    mov [ebx].slf_prev,eax

assDone:
    xor eax,eax
    mov ebx,[eax].slf_next
    cmp ebx,edx
    jnz assEnd
;
    mov ebx,[edx].slf_next
    mov [eax].slf_next,ebx

assEnd:
    xor eax,eax
    mov ebx,[eax].sls_prev
    mov ecx,[edx].sls_next
    cmp ebx,ecx
    jnc assNoBiggestBlock
;
    mov [eax].sls_prev,ecx

assNoBiggestBlock: 
    dec eax
    mov [edx].slf_prev,eax
    mov [edx].slf_next,eax
;
    mov eax,[edx].sls_next
    sub eax,edx    
    mov ebx,es:serv_small_avail_mem
    sub ebx,eax
    mov es:serv_small_avail_mem,ebx
    sub eax,10h
    add es:serv_small_used_mem,eax
;
    pop ecx
    pop ds
    LeaveSection ds:serv_small_section
;
    add edx,serv_byte_linear + 10h
    AllocateLdt
    or bx,4
    CreateDataSelector32
    mov es,bx
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
allocate_small_serv   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeSmallServ
;
;           DESCRIPTION:    Free byte-aligned (dword) server memory
;
;           PARAMETERS:     ES          LDT sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_small_serv_name      DB 'Free Small Server',0

free_small_serv   PROC far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov bx,es
    GetThread
    mov ds,ax
;
    mov es,ds:p_ldt_sel
    test bl,4
    stc
    jz fssDone
;
    and bx,0FFF8h
    mov edx,es:[bx+2]
    rol edx,8
    mov dl,es:[bx+7]
    ror edx,8
    mov byte ptr es:[bx+5],0
    FreeLdt
;
    mov ax,ds:p_serv_sel
    mov ds,ax
    mov es,ax
;
    EnterSection ds:serv_small_section
    push ds
    sub edx,serv_byte_linear + 10h
    mov ax,serv_byte_sel
    mov ds,ax
;
    mov eax,[edx].sls_next
    sub eax,edx
    mov ebx,es:serv_small_avail_mem
    add ebx,eax
    mov es:serv_small_avail_mem,ebx
    sub eax,10h
    sub es:serv_small_used_mem,eax
;
    mov eax,[edx].sls_prev
    or eax,eax
    jz free_small_no_merge_down
;
    mov eax,[eax].slf_next
    inc eax
    or eax,eax
    jz free_small_no_merge_down
;
    mov eax,edx
    mov edx,[eax].sls_prev
    mov ebx,[eax].sls_next
    mov [edx].sls_next,ebx
    mov [ebx].sls_prev,edx
    jmp free_small_test_up

free_small_no_merge_down:
    xor eax,eax
    mov ebx,[eax].slf_next
    cmp edx,ebx
    jc free_small_insert_first

free_small_insert_loop:
    mov ebx,[ebx].slf_next
    cmp edx,ebx
    jnc free_small_insert_loop
;
    mov eax,[ebx].slf_prev
    mov [edx].slf_prev,eax
    mov [eax].slf_next,edx
    mov [edx].slf_next,ebx
    mov [ebx].slf_prev,edx
    jmp free_small_test_up

free_small_insert_first:
    mov [edx].slf_prev,eax
    mov ebx,[eax].slf_next
    mov [edx].slf_next,ebx
    mov [eax].slf_next,edx
    mov [ebx].slf_prev,edx

free_small_test_up:
    mov eax,[edx].sls_next
    mov eax,[eax].slf_prev
    inc eax
    or eax,eax
    jz free_small_no_merge_up
    push edx
    mov edx,[edx].sls_next
    mov eax,[edx].slf_prev
    mov ebx,[edx].slf_next
    or eax,eax
    jz fm1_bypass
    mov [eax].slf_next,ebx
fm1_bypass:
    or ebx,ebx
    jz fm2_bypass
    mov [ebx].slf_prev,eax
fm2_bypass:
    xor eax,eax
    mov ebx,[eax].slf_next
    cmp ebx,edx
    jne fm3_bypass
    mov ebx,[ebx].slf_next
    mov [eax].slf_next,ebx
fm3_bypass:
    pop edx
    mov ebx,[edx].sls_next
    mov ebx,[ebx].sls_next
    mov [ebx].sls_prev,edx
    mov [edx].sls_next,ebx
free_small_no_merge_up:
    xor eax,eax
    mov ebx,[eax].sls_prev
    mov eax,[edx].sls_next
    cmp eax,ebx
    jc free_small_not_limit_page
    mov eax,ebx
    add eax,1000h
    xor ebx,ebx
    mov [ebx].sls_prev,edx

free_small_not_limit_page:
    pop ds
    LeaveSection ds:serv_small_section

fssDone:
    xor ax,ax
    mov es,ax
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
free_small_serv  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateBigServ
;
;           DESCRIPTION:    Allocate page-aligned (dword) server memory
;
;           PARAMETERS:     EAX         # of bytes
;
;           RETURNS:        EDX         Offset with server data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_big_serv_name      DB 'Allocate Big Server',0

allocate_big_serv   PROC far
    push ds
    push eax
    push ecx
;
    dec eax
    and ax,0F000h
    add eax,1000h
    mov ecx,eax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_serv_sel
;
    EnterSection ds:serv_big_section
    add ds:serv_big_used_mem,ecx
    sub ds:serv_big_avail_mem,ecx
    shr ecx,12
;    
    mov edx,serv_size - serv_byte_size
    sub edx,ds:serv_big_avail_mem
    add edx,serv_linear
    mov eax,serv_linear + serv_size - serv_byte_size
    AllocatePageEntries
    jnc absOk

absRetry:
    mov edx,serv_linear + 1000h
    mov eax,serv_linear + serv_size - serv_byte_size
    AllocatePageEntries
    jnc absOk
;
    LeaveSection ds:serv_big_section
    mov ax,100
    WaitMilliSec
    EnterSection ds:serv_big_section
    jmp absRetry
        
absOk:
    sub edx,serv_linear
    clc
    LeaveSection ds:serv_big_section
;
    pop ecx
    pop eax
    pop ds
    retf32
allocate_big_serv   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeBigServ
;
;           DESCRIPTION:    Free page-aligned (dword) server memory
;
;           PARAMETERS:     ECX         # of bytes
;                           EDX         Offset with server data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_big_serv_name      DB 'Free Big Server',0

free_big_serv   PROC far
    push ds
    push eax
    push ecx
;
    dec ecx
    and cx,0F000h
    add ecx,1000h
;
    GetThread
    mov ds,ax
    mov ds,ds:p_serv_sel
;
    EnterSection ds:serv_big_section
    sub ds:serv_big_used_mem,ecx
    add ds:serv_big_avail_mem,ecx
    shr ecx,12
;    
    add edx,serv_linear
    xor eax,eax
    FreeServPageEntries
;
    LeaveSection ds:serv_big_section
;
    pop ecx
    pop eax
    pop ds
    retf32
free_big_serv   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateBigServSel
;
;           DESCRIPTION:    Allocate page-aligned (dword) server memory
;
;           PARAMETERS:     EAX         # of bytes
;
;           RETURNS:        ES          LDT sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_big_serv_sel_name      DB 'Allocate Big Server Sel',0

allocate_big_serv_sel   PROC far
    push ds
    pushad
;
    dec eax
    and ax,0F000h
    add eax,1000h
    mov ecx,eax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_serv_sel
;
    EnterSection ds:serv_big_section
    add ds:serv_big_used_mem,ecx
    sub ds:serv_big_avail_mem,ecx
    shr ecx,12
;    
    mov edx,serv_size - serv_byte_size
    sub edx,ds:serv_big_avail_mem
    add edx,serv_linear
    mov eax,serv_linear + serv_size - serv_byte_size
    AllocatePageEntries
    jnc abssOk

abssRetry:
    mov edx,serv_linear + 1000h
    mov eax,serv_linear + serv_size - serv_byte_size
    AllocatePageEntries
    jnc abssOk
;
    LeaveSection ds:serv_big_section
    mov ax,100
    WaitMilliSec
    EnterSection ds:serv_big_section
    jmp abssRetry
        
abssOk:
    LeaveSection ds:serv_big_section
;
    AllocateLdt
    or bx,4
    shl ecx,12
    CreateDataSelector32
    mov es,bx
    clc
;
    popad
    pop ds
    retf32
allocate_big_serv_sel   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeBigServSel
;
;           DESCRIPTION:    Free page-aligned (dword) server memory
;
;           PARAMETERS:     ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_big_serv_sel_name      DB 'Free Big Server Sel',0

free_big_serv_sel   PROC far
    push ds
    pushad
;
    mov bx,es
    GetSelectorBaseSize
;
    xor ax,ax
    mov es,ax
    FreeLdt
;
    dec ecx
    and cx,0F000h
    add ecx,1000h
;
    GetThread
    mov ds,ax
    mov ds,ds:p_serv_sel
;
    EnterSection ds:serv_big_section
    sub ds:serv_big_used_mem,ecx
    add ds:serv_big_avail_mem,ecx
    shr ecx,12
;    
    xor eax,eax
    FreeServPageEntries
;
    LeaveSection ds:serv_big_section
;
    popad
    pop ds
    retf32
free_big_serv_sel   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_APP_MEM
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_app_mem

init_app_mem    PROC near
    push ds
    push es
    pushad
;
    mov bx,serv_byte_sel
    mov edx,serv_byte_linear
    mov ecx,serv_byte_size
    CreateDataSelector32
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET allocate_small_serv
    mov edi,OFFSET allocate_small_serv_name
    xor cl,cl
    mov ax,allocate_small_serv_nr
    RegisterOsGate
;
    mov esi,OFFSET free_small_serv
    mov edi,OFFSET free_small_serv_name
    xor cl,cl
    mov ax,free_small_serv_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_big_serv
    mov edi,OFFSET allocate_big_serv_name
    xor cl,cl
    mov ax,allocate_big_serv_nr
    RegisterOsGate
;
    mov esi,OFFSET free_big_serv
    mov edi,OFFSET free_big_serv_name
    xor cl,cl
    mov ax,free_big_serv_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_big_serv_sel
    mov edi,OFFSET allocate_big_serv_sel_name
    xor cl,cl
    mov ax,allocate_big_serv_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET free_big_serv_sel
    mov edi,OFFSET free_big_serv_sel_name
    xor cl,cl
    mov ax,free_big_serv_sel_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
init_app_mem    ENDP


code    ENDS

END

