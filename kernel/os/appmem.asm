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

small_linear_struc      STRUC
slf_prev    DD ?
slf_next    DD ?
sls_prev    DD ?
sls_next    DD ?
small_linear_struc      ENDS

mem_seg STRUC

big_avail_mem       DD ?
small_avail_mem     DD ?

big_used_mem        DD ?
small_used_mem      DD ?

big_section             section_typ <>
small_section       section_typ <>

mem_seg ENDS


    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateSharedMem
;
;           DESCRIPTION:    Create shared mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_shared_mem_name      DB 'Create Shared Mem',0

create_shared_mem  Proc far
    push ds
    pushad
;
    CreateSharedDir
    GetThread
    mov ds,ax
    mov ds:p_shared_dir_sel,bx
    int 3
;
    mov ax,shared_byte_sel
    mov ds,ax
    xor eax,eax
    mov edx,10h
    mov [eax].slf_next,edx
    mov [eax].sls_next,edx
    mov [eax].sls_prev,edx
    mov eax,edx
    mov edx,shared_byte_size - 10h
    mov [eax].slf_prev,0
    mov [eax].slf_next,0
    mov [eax].sls_prev,0
    mov [eax].sls_next,edx
;
    mov ds,bx
    mov edx,shared_size - shared_byte_size
    mov ds:big_avail_mem,edx
    InitSection ds:big_section
;
    mov edx,shared_byte_size - 10h
    mov ds:small_avail_mem,edx
    InitSection ds:small_section
;
    mov ds:big_used_mem,0
    mov ds:small_used_mem,0
;
    popad
    pop ds
    retf32
create_shared_mem  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateSmallShared
;
;           DESCRIPTION:    Allocate byte-aligned (dword) shared memory
;
;           PARAMETERS:     EAX         # of bytes
;
;           RETURNS:        ES          LDT sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_small_shared_name      DB 'Allocate Small Shared',0

allocate_small_shared   PROC far
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    push ax
    GetThread
    mov ds,ax
    mov ax,ds:p_shared_dir_sel
    mov ds,ax
    mov es,ax
    pop ax
;
    EnterSection ds:small_section
    push ds
    push eax
;       
    dec eax
    and al,0FCh
    add eax,4
;
    add eax,10h
;
    mov dx,shared_flat_sel
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
    mov ebx,es:small_avail_mem
    sub ebx,eax
    mov es:small_avail_mem,ebx
    sub eax,10h
    add es:small_used_mem,eax
;
    pop ecx
    pop ds
    LeaveSection ds:small_section
    add edx,10h
;
    AllocateLdt
    CreateDataSelector32
;
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
allocate_small_shared   ENDP

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
    mov bx,shared_byte_sel
    mov edx,shared_byte_linear
    mov ecx,shared_byte_size
    CreateDataSelector32
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_shared_mem
    mov edi,OFFSET create_shared_mem_name
    xor cl,cl
    mov ax,create_shared_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_small_shared
    mov edi,OFFSET allocate_small_shared_name
    xor cl,cl
    mov ax,allocate_small_shared_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
init_app_mem    ENDP


code    ENDS

END

