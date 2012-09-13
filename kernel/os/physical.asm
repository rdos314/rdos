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
; PHYSICAL.ASM
; Physical memory module
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

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

    extrn local_create_data_sel16:near
    extrn local_flush_process_tlb:near
    extrn AllocateRam:near

    extrn get_page_dir_attrib_proc:word
    extrn set_sys_page_dir_proc:word

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_physical_dir
;
;           DESCRIPTION:    init physical page directories & tables
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_physical_dir

init_physical_dir       Proc near
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov fs,ax
    mov fs:phys_free_pages,0
;
    call cs:get_page_dir_attrib_proc
    xor edi,edi

init_phys_page_pages_dir:
    push esi    
    call AllocateRam
    mov eax,esi
    pop esi
;    
    push eax
    xor ebx,ebx
    mov edx,phys_page_linear
    add edx,edi
    or al,3
    call cs:set_sys_page_dir_proc
    pop edx
;
    push ecx
    mov cx,400h
    xor eax,eax

init_phys_page_pages:
    mov [edx],eax
    add edx,4
    loop init_phys_page_pages
;
    pop ecx
    add edi,esi
    loop init_phys_page_pages_dir    
;
    mov ax,sys_dir_sel
    mov es,ax
    call AllocateRam
    mov edx,esi
    mov bx,(phys_list_linear SHR 20) AND 0FFFh
    and bl,0FCh
    or si,3
    mov es:[bx],esi
;
    mov cx,400h
    xor eax,eax
init_phys_list_pages:
    mov [edx],eax
    add edx,4
    loop init_phys_list_pages
;
    xor ebx,ebx
    xor ebp,ebp
init_free_dir_loop:
    call AllocateRam
    jc init_free_done
;
    mov di,(phys_page_linear SHR 20) AND 0FFFh
    mov edx,es:[di]
    xor dl,dl
;
    push esi
    or si,3
    mov [ebx+edx],esi
;
    call AllocateRam
    jc init_free_done
;
    mov edi,(phys_list_linear SHR 20) AND 0FFFh
    mov edx,es:[di]
    xor dl,dl
;
    push esi
    or si,3
    mov [ebx+edx],esi
;
    pop edx
    pop edi
    mov cx,400h
init_free_page_loop:
    call AllocateRam
    jc init_free_done
;
    or si,3
    mov [edi],esi
    add ebp,4
    mov [edx],ebp
    add edx,4
    add edi,4
;
    inc fs:phys_free_pages
    loop init_free_page_loop
;       
    add ebx,4
    jmp init_free_dir_loop

init_free_done:
    mov fs:unused_phys_list,-1
    mov fs:free_phys_list,0
    mov fs:free_dma_phys_list,0
    ret
init_physical_dir       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_PHYSICAL
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_physical

init_physical   PROC near
    mov ax,system_data_sel
    mov ds,ax
;
    InitSpinlock ds:phys_spinlock
    mov bx,phys_page_sel
    mov edx,phys_page_linear
    mov ecx,ds:phys_free_pages
    shl ecx,2
    call local_create_data_sel16
;
    mov bx,phys_list_sel
    mov ecx,ds:phys_free_pages
    shl ecx,2
    mov edx,phys_list_linear
    call local_create_data_sel16
    ret
init_physical   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_PHYSICAL_GATES
;
;           DESCRIPTION:    Init module syscalls
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_physical_gates

init_physical_gates     PROC near
    pusha
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_free_physical_mem
    mov edi,OFFSET get_free_physical_name
    xor dx,dx
    mov ax,get_free_physical_nr
    RegisterBimodalUserGate
;       
    mov esi,OFFSET free_physical
    mov edi,OFFSET free_physical_name
    xor cl,cl
    mov ax,free_physical_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_physical32
    mov edi,OFFSET allocate_physical32_name
    xor cl,cl
    mov ax,allocate_physical32_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_physical32
    mov edi,OFFSET allocate_physical32_name
    xor cl,cl
    mov ax,allocate_physical64_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_dma_physical
    mov edi,OFFSET allocate_dma_physical_name
    xor cl,cl
    mov ax,allocate_dma_physical_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_multiple_physical32
    mov edi,OFFSET allocate_multiple_physical32_name
    xor cl,cl
    mov ax,allocate_multiple_physical32_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_multiple_physical32
    mov edi,OFFSET allocate_multiple_physical32_name
    xor cl,cl
    mov ax,allocate_multiple_physical64_nr
    RegisterOsGate
;    
    pop ds
    popa
    ret
init_physical_gates     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalAllocatePhysical
;
;           DESCRIPTION:    Allocate physical page
;
;           PARAMETERS:     EDX:EAX         Address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_allocate_physical

local_allocate_physical       PROC near
    push ds
    push es
    push edx
;    
    mov bx,system_data_sel
    mov ds,bx
    pushf
    push ds
    RequestSpinlock ds:phys_spinlock
    dec ds:phys_free_pages
    mov dx,phys_list_sel
    mov es,dx
    mov ebx,ds:free_phys_list
    or ebx,ebx
    jnz allocate_normal
;
    mov ebx,ds:free_dma_phys_list
    mov edx,es:[ebx]
    mov ds:free_dma_phys_list,edx
    jmp allocate_mark

allocate_normal:
    mov edx,es:[ebx]
    mov ds:free_phys_list,edx

allocate_mark:
    mov edx,ds:unused_phys_list
    mov es:[ebx],edx
    mov ds:unused_phys_list,ebx
    mov ax,phys_page_sel
    mov ds,ax
    mov eax,ebx
    mov eax,[eax]
    xor al,al
    pop ds
    ReleaseSpinlockNoSti ds:phys_spinlock
    xor ebx,ebx
    popf
;
    pop edx
    pop es
    pop ds
    ret
local_allocate_physical       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocatePhysical32
;
;           DESCRIPTION:    Allocate physical page
;
;           RETURNS:        EBX:EAX         Address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_physical32_name  DB 'Allocate Physical Memory32',0

allocate_physical32       PROC far
    call local_allocate_physical
    retf32
allocate_physical32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocatePhysical64
;
;           DESCRIPTION:    Allocate physical page
;
;           RETURNS:        EBX:EAX         Address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_physical64_name  DB 'Allocate Physical Memory64',0

allocate_physical64       PROC far
    call local_allocate_physical
    retf32
allocate_physical64       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateDmaPhysical
;
;           DESCRIPTION:    Allocate DMA physical page
;
;           PARAMETERS:         EAX         Address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dma_physical_name      DB 'Allocate DMA Physical Memory',0

allocate_dma_physical   PROC far
    push ds
    push es
    push ebx
    push edx
    mov bx,system_data_sel
    mov ds,bx
    pushf
    push ds
    RequestSpinlock ds:phys_spinlock
    dec ds:phys_free_pages
    mov dx,phys_list_sel
    mov es,dx
    mov ebx,ds:free_dma_phys_list
    mov edx,es:[ebx]
    mov ds:free_dma_phys_list,edx
    mov edx,ds:unused_phys_list
    mov es:[ebx],edx
    mov ds:unused_phys_list,ebx
    mov ax,phys_page_sel
    mov ds,ax
    mov eax,ebx
    mov eax,[eax]
    xor al,al
    pop ds
    ReleaseSpinlockNoSti ds:phys_spinlock
    popf
    pop edx
    pop ebx
    pop es
    pop ds
    retf32
allocate_dma_physical   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalFreePhysical
;
;           DESCRIPTION:    Free physical page
;
;           PARAMETERS:     EBX:EAX         Address
;                           
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_free_physical

local_free_physical   PROC near
    push ds
    push es
    push ebx
    push edx
;
    or ebx,ebx
    jz fpdo
;
    int 3

fpdo:    
    and ax,0F000h
    mov bx,system_data_sel
    mov ds,bx
    pushf
    push ds
    RequestSpinlock ds:phys_spinlock
    inc ds:phys_free_pages
    xor ebx,ebx
    mov dx,phys_list_sel
    mov es,dx
    mov ebx,ds:unused_phys_list
    mov edx,es:[ebx]
    mov ds:unused_phys_list,edx
    cmp eax,1000000h
    jc free_dma_phys
;
    mov edx,ds:free_phys_list
    mov es:[ebx],edx
    mov ds:free_phys_list,ebx
    jmp free_link_page

free_dma_phys:
    mov edx,ds:free_dma_phys_list
    mov es:[ebx],edx
    mov ds:free_dma_phys_list,ebx

free_link_page:
    mov dx,phys_page_sel
    mov ds,dx
    mov [ebx],eax
    pop ds
    ReleaseSpinlockNoSti ds:phys_spinlock
    popf
;    
    pop edx
    pop ebx
    pop es
    pop ds  
    ret
local_free_physical   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreePhysical
;
;           DESCRIPTION:    Free physical page
;
;           PARAMETERS:     EBX:EAX         Address
;                           
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_physical_name      DB 'Free Physical Memory',0

free_physical   PROC far
    call local_free_physical
    retf32
free_physical   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateMultiplePhysical32
;
;           DESCRIPTION:    Allocate multiple physical page
;
;           PARAMETERS:     ECX         Number of pages
;
;           RETURN:         EBX:EAX     Physical base address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_multiple_physical32_name DB 'Allocate 32-bit Multiple Physical Memory',0

; edx address to check for

check_address   Proc near
    push eax
    push ebx
    push esi
;
    mov esi,ds:phys_free_pages
    shl esi,2
    mov ebx,ds:free_dma_phys_list

check_addr_loop:
    or ebx,ebx
    jz check_addr_fail
;       
    cmp ebx,esi
    jae check_addr_fail
;    
    mov eax,fs:[ebx]
    xor al,al
    cmp eax,edx
    je check_addr_found
;
    mov ebx,es:[ebx]
    jmp check_addr_loop

check_addr_fail:
    stc
    jmp check_addr_done

check_addr_found:
    clc

check_addr_done:
    pop esi
    pop ebx
    pop eax
    ret
check_address   Endp

; edx start address
; ecx number of pages

do_one_scan     Proc near
    push ecx
    push edx

do_one_scan_loop:
    call check_address
    jc do_one_scan_done
;
    add edx,1000h
    loop do_one_scan_loop
;
    clc

do_one_scan_done:
    pop edx
    pop ecx 
    ret
do_one_scan     Endp

; ecx number of pages
; edx start address

find_multi_page Proc near
    push ebx
;
    mov ebx,ds:free_dma_phys_list

find_multi_loop:
    or ebx,ebx
    jz find_multi_fail
;       
    mov edx,fs:[ebx]
    xor dl,dl
    call do_one_scan
    jnc find_multi_done
;
    mov ebx,es:[ebx]
    jmp find_multi_loop

find_multi_fail:
    stc

find_multi_done:
    pop ebx
    ret
find_multi_page Endp

; edx physical address

allocate_one_entry      Proc near
    push eax
    push ebx
    push esi
;
    xor esi,esi
    mov ebx,ds:free_dma_phys_list

allocate_one_loop:
    or ebx,ebx
    jz allocate_one_fail
;
    mov eax,fs:[ebx]
    xor al,al
    cmp eax,edx
    je allocate_one_do
;
    mov esi,ebx
    mov ebx,es:[ebx]
    jmp allocate_one_loop

allocate_one_do:
    or esi,esi
    jnz allocate_one_not_first
;
    mov eax,es:[ebx]
    mov ds:free_dma_phys_list,eax
    jmp allocate_one_unused

allocate_one_not_first:
    mov eax,es:[ebx]
    mov es:[esi],eax

allocate_one_unused:
    mov eax,ds:unused_phys_list
    mov es:[ebx],eax
    mov ds:unused_phys_list,ebx
    clc
    jmp allocate_one_done

allocate_one_fail:
    stc

allocate_one_done:
    pop esi
    pop ebx
    pop eax
    ret
allocate_one_entry      Endp

; ecx number of pages
; edx physical start address

allocate_multi_entries  Proc near
    push ecx
    push edx

allocate_multi_entry_loop:
    call allocate_one_entry
    add edx,1000h
    loop allocate_multi_entry_loop

allocate_multi_entry_done:
    pop edx
    pop ecx
    ret
allocate_multi_entries  Endp

allocate_multiple_physical32      PROC far
    push ds
    push es
    push fs
    push edx
;
    mov ax,system_data_sel
    mov ds,ax
    mov ax,phys_list_sel
    mov es,ax
    mov ax,phys_page_sel
    mov fs,ax
    pushf
    RequestSpinlock ds:phys_spinlock
    or ecx,ecx
    jz allocate_multi_fail
;
    cmp ecx,ds:phys_free_pages
    ja allocate_multi_fail
;
    call find_multi_page
    jc allocate_multi_fail
;
    call allocate_multi_entries
    sub ds:phys_free_pages,ecx
    mov eax,edx
    xor ebx,ebx
    ReleaseSpinlockNoSti ds:phys_spinlock
    popf
    clc
    jmp allocate_multi_done

allocate_multi_fail:
    ReleaseSpinlockNoSti ds:phys_spinlock
    popf
    stc

allocate_multi_done:
    pop edx
    pop fs
    pop es
    pop ds
    retf32
allocate_multiple_physical32      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_FREE_PHYSICAL_MEM
;
;           DESCRIPTION:    Get free physical memory
;
;           PARAMETERS:     EDX:EAX         # of free bytes
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_physical_name  DB 'Get Free Physical Memory',0

get_free_physical_mem   PROC far
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:phys_free_pages
    shl eax,12
    xor edx,edx
    pop ds
    retf32
get_free_physical_mem   ENDP


code    ENDS

    END

