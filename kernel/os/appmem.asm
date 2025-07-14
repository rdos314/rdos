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

serv_app_struc          STRUC

serv_app_alloc           DD ?
serv_app_section         section_typ <>

serv_app_struc          ENDS

share_block_struc       STRUC

sb_usage    DW ?
sb_pages    DW ?

share_block_struc       ENDS


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
;           PARAMETERS:     BX     Serv sel
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
;           NAME:           InitServProcess
;
;           DESCRIPTION:    Create serv process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_serv_proc  Proc far
    push ds
    pushad
;
    mov ax,serv_mem_sel
    mov ds,ax
;
    InitSection ds:serv_app_section
    mov ds:serv_app_alloc,serv_alloc_linear
;
    popad
    pop ds
    retf32
init_serv_proc  Endp

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
;           NAME:           CreateServShareBlock
;
;           DESCRIPTION:    Create a new share block in server context
;
;           RETURNS:        EDX      Flat linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_serv_share_block_name      DB 'Create Serv Share Block',0

create_serv_share_block   PROC far
    push ds
    push eax
    push ebx
    push ecx
;
    mov ax,serv_mem_sel
    mov ds,ax
;
    EnterSection ds:serv_app_section
;    
    mov ecx,1
    mov edx,ds:serv_app_alloc
    mov eax,serv_linear
    AllocatePageEntries
    jnc cssbOk

cssbRetry:
    mov ecx,1
    mov edx,serv_alloc_linear
    mov eax,serv_linear
    AllocatePageEntries
    jnc cssbOk
;
    LeaveSection ds:serv_app_section
    mov ax,100
    WaitMilliSec
    EnterSection ds:serv_app_section
    jmp cssbRetry
        
cssbOk:
    mov eax,edx
    add eax,1000h
    mov ds:serv_app_alloc,eax
;
    LeaveSection ds:serv_app_section
;
    mov ax,flat_sel
    mov ds,ax
    mov ds:[edx].sb_usage,1
    mov ds:[edx].sb_pages,1
;
    mov ax,system_data_sel
    mov ds,ax
    sub edx,ds:flat_base
    clc
;
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
create_serv_share_block  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeServShareBlock
;
;           DESCRIPTION:    Free share block in server context
;
;           PARAMETERS:     EDX      Flat linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_serv_share_block_name      DB 'Free Serv Share Block',0

free_serv_share_block   PROC far
    push ds
    push eax
    push ecx
;
    mov ax,system_data_sel
    mov ds,ax
    add edx,ds:flat_base
;
    mov ax,flat_sel
    mov ds,ax
    movzx ecx,ds:[edx].sb_pages
;
    lock sub ds:[edx].sb_usage,1
    jnz fssbClear

fssbFree:
    mov ax,serv_mem_sel
    mov ds,ax
;
    EnterSection ds:serv_app_section
;    
    mov eax,ecx
    shl eax,12
    sub ds:serv_app_alloc,eax
    xor eax,eax
    FreePageEntries
;
    LeaveSection ds:serv_app_section
    jmp fssbDone

fssbClear:
    mov ax,serv_mem_sel
    mov ds,ax
;
    EnterSection ds:serv_app_section
;    
    mov eax,ecx
    shl eax,12
    sub ds:serv_app_alloc,eax
    xor eax,eax
    ClearPageEntries
;
    LeaveSection ds:serv_app_section
        
fssbDone:
    pop ecx
    pop eax
    pop ds
    retf32
free_serv_share_block  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GrowServShareBlock
;
;           DESCRIPTION:    Grow share block in server context
;
;           PARAMETERS:     EDX      Flat linear address
;
;           RETURNS:        EDX      Flat linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

grow_serv_share_block_name      DB 'Grow Serv Share Block',0

grow_serv_share_block   PROC far
    push ds
    push eax
    push ebx
    push ecx
;
    mov ax,system_data_sel
    mov ds,ax
    add edx,ds:flat_base
;
    mov ax,flat_sel
    mov ds,ax
    movzx ecx,ds:[edx].sb_pages
    inc ds:[edx].sb_pages
;
    mov ax,serv_mem_sel
    mov ds,ax
;
    EnterSection ds:serv_app_section
    shl ecx,12
    add edx,ecx
    GetPageEntry
    test al,1
    jnz gssbCopy
;
    mov eax,2
    SetPageEntry
;
    sub edx,ecx
    jmp gssbDone

gssbCopy:
    push esi
    push edi
;
    sub edx,ecx
    shr ecx,12
    inc ecx
    mov esi,edx
;
    mov edx,ds:serv_app_alloc
    mov eax,serv_linear
    AllocatePageEntries
    jnc gssbCopyDo

gssbRetry:
    mov edx,serv_alloc_linear
    mov eax,serv_linear
    AllocatePageEntries
    jnc gssbCopyDo
;
    LeaveSection ds:serv_app_section
    mov ax,100
    WaitMilliSec
    EnterSection ds:serv_app_section
    jmp gssbRetry

gssbCopyDo:
    dec ecx
    mov edi,edx
    CopyPageEntries
;
    xor eax,eax
    mov edx,esi
    ClearPageEntries
;
    mov edx,edi
;
    pop edi
    pop esi

gssbDone:
    LeaveSection ds:serv_app_section
;
    mov ax,system_data_sel
    mov ds,ax
    sub edx,ds:flat_base
    clc
;
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
grow_serv_share_block  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ForkServShareBlock
;
;           DESCRIPTION:    Fork share block in server context
;
;           PARAMETERS:     EDX      Flat linear address
;
;           RETURNS:        EDX      Flat linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fork_serv_share_block_name      DB 'Fork Serv Share Block',0

fork_serv_share_block   PROC far
    push ds
    push eax
    push ebx
    push ecx
;
    mov ax,system_data_sel
    mov ds,ax
    add edx,ds:flat_base
;
    mov ax,flat_sel
    mov ds,ax
    movzx ecx,ds:[edx].sb_pages
;
    lock sub ds:[edx].sb_usage,1
    jnz frsbCopy

frsbReuse:
    lock add ds:[edx].sb_usage,1
    jmp frsbDone

frsbCopy:
    push esi
    push edi
;
    mov ax,serv_mem_sel
    mov ds,ax
;
    EnterSection ds:serv_app_section
;
    mov esi,edx
;
    mov edx,ds:serv_app_alloc
    mov eax,serv_linear
    AllocatePageEntries
    jnc frsbCopyDo

frsbRetry:
    mov edx,serv_alloc_linear
    mov eax,serv_linear
    AllocatePageEntries
    jnc frsbCopyDo
;
    LeaveSection ds:serv_app_section
    mov ax,100
    WaitMilliSec
    EnterSection ds:serv_app_section
    jmp frsbRetry

frsbCopyDo:
    mov edi,edx
;
    push es
    push ecx
    push esi
    push edi
;
    mov ax,flat_sel
    mov es,ax
    shl ecx,10
    rep movs dword ptr es:[edi],es:[esi]
;
    pop edi
    pop esi
    pop ecx
    pop es
;
    mov edx,esi
    ClearPageEntries
;
    mov edx,edi
    mov es:[edx].sb_usage,1
;
    pop edi
    pop esi
;
    LeaveSection ds:serv_app_section

frsbDone:
    mov ax,system_data_sel
    mov ds,ax
    sub edx,ds:flat_base
    clc
;
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
fork_serv_share_block  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ServToSystemShareBlock
;
;           DESCRIPTION:    Alias share block in system memory
;
;           PARAMETERS:     EDX      Flat linear address
;
;           RETURNS:        ES       System share sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_to_system_share_block_name      DB 'Serv To System Share Block',0

serv_to_system_share_block   PROC far
    pushad
;
    mov ax,system_data_sel
    mov es,ax
    add edx,es:flat_base
    mov esi,edx
;
    mov ax,flat_sel
    mov es,ax
;
    movzx eax,es:[esi].sb_pages
    shl eax,12
    AllocateBigLinear
    mov edi,edx
;
    movzx ecx,es:[esi].sb_pages
    mov edi,edx
    CopyPageEntries
;
    mov edx,edi
    AllocateGdt
    movzx ecx,es:[esi].sb_pages
    shl ecx,12
    CreateDataSelector32
    mov es,bx
;
    popad
    retf32
serv_to_system_share_block   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateShareBlock
;
;           DESCRIPTION:    Create a new share block in system context
;
;           RETURNS:        ES     Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_share_block_name      DB 'Create Share Block',0

create_share_block   PROC far
    push eax
    push ebx
    push ecx
    push edx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocateGdt
;
    mov ecx,1000h
    CreateDataSelector32    
    mov es,bx
    mov es:sb_usage,1
    mov es:sb_pages,1
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    retf32
create_share_block  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateFixedShareBlock
;
;           DESCRIPTION:    Create a fixed share block in system context
;
;           PARAMETERS:     BX     Selector
;
;           RETURNS:        ES     Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_fixed_share_block_name      DB 'Create Fixed Share Block',0

create_fixed_share_block   PROC far
    push eax
    push ebx
    push ecx
    push edx
;
    mov eax,1000h
    AllocateBigLinear
;
    mov ecx,1000h
    CreateDataSelector32    
    mov es,bx
    mov es:sb_usage,1
    mov es:sb_pages,1
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    retf32
create_fixed_share_block  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GrowShareBlock
;
;           DESCRIPTION:    Grow block in system context
;
;           PARAMETERS:     ES     Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

grow_share_block_name      DB 'Grow Share Block',0

grow_share_block   PROC far
    pushad
;
    mov bx,es
    GetSelectorBaseSize
    mov esi,edx
;
    inc es:sb_pages
    movzx eax,es:sb_pages
    shl eax,12
    AllocateBigLinear
    mov edi,edx
;
    movzx ecx,es:sb_pages
    dec ecx
    mov edi,edx
    CopyPageEntries
;
    mov edx,edi
    movzx ecx,es:sb_pages
    shl ecx,12
    CreateDataSelector32
    mov es,bx
;
    movzx ecx,es:sb_pages
    dec ecx
    mov edx,esi
    xor eax,eax
    ClearPageEntries
;
    popad
    retf32
grow_share_block  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeShareBlock
;
;           DESCRIPTION:    Free share block in system context
;
;           PARAMETERS:     ES     Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_share_block_name      DB 'Free Share Block',0

free_share_block   PROC far
    pushad
;
    mov bx,es
    GetSelectorBaseSize
;
    lock sub es:sb_usage,1
    jnz fsbClear

fsbFree:
    movzx ecx,es:sb_pages
    xor eax,eax
    FreePageEntries
    jmp fsbOk

fsbClear:
    movzx ecx,es:sb_pages
    xor eax,eax
    ClearPageEntries

fsbOk:
    FreeMem
;
    popad
    retf32
free_share_block  Endp

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
    mov eax,SIZE serv_app_struc
    mov bx,serv_mem_sel
    AllocateFixedProcessMem
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
    mov edi,OFFSET init_serv_proc
    HookCreateProcess
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
    mov esi,OFFSET create_share_block
    mov edi,OFFSET create_share_block_name
    xor dx,dx
    mov ax,create_share_block_nr
    RegisterOsGate
;
    mov esi,OFFSET create_fixed_share_block
    mov edi,OFFSET create_fixed_share_block_name
    xor dx,dx
    mov ax,create_fixed_share_block_nr
    RegisterOsGate
;
    mov esi,OFFSET free_share_block
    mov edi,OFFSET free_share_block_name
    xor dx,dx
    mov ax,free_share_block_nr
    RegisterOsGate
;
    mov esi,OFFSET grow_share_block
    mov edi,OFFSET grow_share_block_name
    xor dx,dx
    mov ax,grow_share_block_nr
    RegisterOsGate
;
    mov esi,OFFSET create_serv_share_block
    mov edi,OFFSET create_serv_share_block_name
    xor dx,dx
    mov ax,create_serv_share_block_nr
    RegisterServGate
;
    mov esi,OFFSET free_serv_share_block
    mov edi,OFFSET free_serv_share_block_name
    xor dx,dx
    mov ax,free_serv_share_block_nr
    RegisterServGate
;
    mov esi,OFFSET grow_serv_share_block
    mov edi,OFFSET grow_serv_share_block_name
    xor dx,dx
    mov ax,grow_serv_share_block_nr
    RegisterServGate
;
    mov esi,OFFSET fork_serv_share_block
    mov edi,OFFSET fork_serv_share_block_name
    xor dx,dx
    mov ax,fork_serv_share_block_nr
    RegisterServGate
;
    mov esi,OFFSET serv_to_system_share_block
    mov edi,OFFSET serv_to_system_share_block_name
    xor dx,dx
    mov ax,serv_to_system_share_block_nr
    RegisterServGate
;
    popad
    pop es
    pop ds
    ret
init_app_mem    ENDP


code    ENDS

END

