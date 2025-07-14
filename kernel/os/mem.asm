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
; MEM.ASM
; Memory allocation module
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

mmap_struc  STRUC

mmap_len    DD ?
mmap_base   DD ?,?
mmap_size   DD ?,?
mmap_type   DD ?

mmap_struc  ENDS

small_linear_struc      STRUC
slf_prev    DD ?
slf_next    DD ?
sls_prev    DD ?
sls_next    DD ?
small_linear_struc      ENDS

vm_linear_struc STRUC
vmf_prev    DW ?
vmf_next    DW ?
vms_prev    DW ?
vms_next    DW ?
vm_linear_struc ENDS

mem_seg STRUC

big_avail_mem       DD ?
small_avail_mem     DD ?

big_used_mem        DD ?
small_used_mem      DD ?

big_section             section_typ <>
small_section       section_typ <>

small_alloc_count   DD ?
big_alloc_count     DD ?

system_alloc_base       DD ?
process_alloc_base      DD ?
fixed_vm_base       DD ?

mem_seg ENDS

local_mem_seg   STRUC

local_big_used_mem      DD ?
local_big_avail_mem     DD ?

local_big_base      DD ?

vm_avail_mem        DW ?
vm_used_mem             DW ?

local_mem_section       section_typ <>
vm_mem_section      section_typ <>

local_mem_seg   ENDS

long_mem_seg   STRUC

long_avail_mem      DD ?
long_used_mem       DD ?

long_base           DD ?

long_mem_section    section_typ <>

long_mem_seg   ENDS

    .386p

    extrn local_create_data_sel16:near

    extrn set_sys_page_entry_proc:word
    extrn reserve_page_entries_proc:word
    extrn allocate_page_entries_proc:word
    extrn allocate_sys_page_entries_proc:word
    extrn free_page_entries_proc:word
    extrn free_global_page_entries_proc:word
    extrn allocate_and_map_sys_dir_proc:word

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetAllocFlatSize
;
;           DESCRIPTION:    Get allocation flat size
;
;           RETURNS:        EAX     Alloc flat size         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllocFlatSize      PROC near
    GetFlatSize
    cmp eax,serv_linear
    jne gafDone
;
    mov eax,serv_alloc_linear

gafDone:
    ret
GetAllocFlatSize     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_MEM
;
;           DESCRIPTION:    Create memory selectors
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public create_mem

create_mem      PROC near
    push ds
    push eax
    push bx
    push edx
;
    mov edx,system_linear
    mov ecx,SIZE mem_seg
    mov bx,mem_sel
    call local_create_data_sel16
;
    mov ds,bx
    add edx,SIZE mem_seg
    mov ds:system_alloc_base,edx
;
    pop edx
    pop bx
    pop eax
    pop ds
    ret
create_mem      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_MEM
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_mem

init_mem    PROC near
    pusha
    push ds
;
    mov bx,small_mem_sel
    mov edx,global_byte_linear
    mov ecx,global_byte_size
    CreateDataSelector16
;
    mov ds,bx
    xor eax,eax
    mov edx,10h
    mov [eax].slf_next,edx
    mov [eax].sls_next,edx
    mov [eax].sls_prev,edx
    mov eax,edx
    mov edx,global_byte_size - 10h
    mov [eax].slf_prev,0
    mov [eax].slf_next,0
    mov [eax].sls_prev,0
    mov [eax].sls_next,edx
;
    mov ax,mem_sel
    mov ds,ax
    mov edx,global_page_size
    mov ds:big_avail_mem,edx
    InitSection ds:big_section
;
    mov edx,global_byte_size - 10h
    mov ds:small_avail_mem,edx
    InitSection ds:small_section
;
    mov ds:big_used_mem,0
    mov ds:small_used_mem,0
    mov ds:big_alloc_count,0
    mov ds:small_alloc_count,0
    mov ds:process_alloc_base,fixed_process_linear
    mov ds:fixed_vm_base,fixed_vm_linear
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov esi,OFFSET init_process_mem
    mov edi,OFFSET init_process_mem_name
    xor cl,cl
    mov ax,init_process_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_global_mem
    mov edi,OFFSET allocate_global_name
    xor cl,cl
    mov ax,allocate_global_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_small_global_mem
    mov edi,OFFSET allocate_small_global_name
    xor cl,cl
    mov ax,allocate_small_global_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_small_kernel_mem
    mov edi,OFFSET allocate_small_kernel_mem_name
    xor cl,cl
    mov ax,allocate_small_kernel_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET log_small_mem
    mov edi,OFFSET log_small_mem_name
    xor cl,cl
    mov ax,log_small_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET log_big_mem
    mov edi,OFFSET log_big_mem_name
    xor cl,cl
    mov ax,log_big_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET free_mem
    mov edi,OFFSET free_name
    mov dx,virt_es_in
    mov ax,free_mem_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET allocate_big_linear
    mov edi,OFFSET allocate_big_linear_name
    xor cl,cl
    mov ax,allocate_big_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_small_linear
    mov edi,OFFSET allocate_small_linear_name
    xor cl,cl
    mov ax,allocate_small_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_fixed_vm_linear
    mov edi,OFFSET allocate_fixed_vm_linear_name
    xor cl,cl
    mov ax,allocate_fixed_vm_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET free_linear
    mov edi,OFFSET free_linear_name
    xor cl,cl
    mov ax,free_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET resize_linear
    mov edi,OFFSET resize_linear_name
    xor cl,cl
    mov ax,resize_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET available_big_linear
    mov edi,OFFSET available_big_linear_name
    xor dx,dx
    mov ax,available_big_linear_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET available_small_linear
    mov edi,OFFSET available_small_linear_name
    xor dx,dx
    mov ax,available_small_linear_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET used_big_linear
    mov edi,OFFSET used_big_linear_name
    xor cl,cl
    mov ax,used_big_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET used_small_linear
    mov edi,OFFSET used_small_linear_name
    xor cl,cl
    mov ax,used_small_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET selector_to_segment
    mov edi,OFFSET selector_to_segment_name
    xor cl,cl
    mov ax,selector_to_segment_nr
    RegisterOsGate
;
    mov esi,OFFSET segment_to_selector
    mov edi,OFFSET segment_to_selector_name
    xor cl,cl
    mov ax,segment_to_selector_nr
    RegisterOsGate
;
    mov esi,OFFSET free_selector
    mov edi,OFFSET free_selector_name
    xor cl,cl
    mov ax,free_selector_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_process_linear
    mov edi,OFFSET allocate_process_linear_name
    xor cl,cl
    mov ax,allocate_process_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_system_linear
    mov edi,OFFSET allocate_system_linear_name
    xor cl,cl
    mov ax,allocate_system_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_fixed_process_mem
    mov edi,OFFSET allocate_fixed_process_mem_name
    xor cl,cl
    mov ax,allocate_fixed_process_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_fixed_system_mem
    mov edi,OFFSET allocate_fixed_system_mem_name
    xor cl,cl
    mov ax,allocate_fixed_system_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET get_thread_selector_page
    mov edi,OFFSET get_thread_selector_page_name
    xor cl,cl
    mov ax,get_thread_selector_page_nr
    RegisterOsGate
;
    mov esi,OFFSET read_thread_selector
    mov edi,OFFSET read_thread_selector_name
    xor cl,cl
    mov ax,read_thread_selector_nr
    RegisterOsGate
;
    mov esi,OFFSET write_thread_selector
    mov edi,OFFSET write_thread_selector_name
    xor cl,cl
    mov ax,write_thread_selector_nr
    RegisterOsGate
;
    mov esi,OFFSET read_thread_segment
    mov edi,OFFSET read_thread_segment_name
    xor cl,cl
    mov ax,read_thread_segment_nr
    RegisterOsGate
;
    mov esi,OFFSET write_thread_segment
    mov edi,OFFSET write_thread_segment_name
    xor cl,cl
    mov ax,write_thread_segment_nr
    RegisterOsGate
;
    mov esi,OFFSET read_thread64
    mov edi,OFFSET read_thread64_name
    xor cl,cl
    mov ax,read_thread64_nr
    RegisterOsGate
;
    mov esi,OFFSET write_thread64
    mov edi,OFFSET write_thread64_name
    xor cl,cl
    mov ax,write_thread64_nr
    RegisterOsGate
;
    mov esi,OFFSET get_thread_linear
    mov edi,OFFSET get_thread_linear_name
    xor dx,dx
    mov ax,get_thread_linear_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_thread_mem16
    mov esi,OFFSET read_thread_mem32
    mov edi,OFFSET read_thread_mem_name
    mov dx,virt_es_in
    mov ax,read_thread_mem_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_thread_mem16
    mov esi,OFFSET write_thread_mem32
    mov edi,OFFSET write_thread_mem_name
    mov dx,virt_es_in
    mov ax,write_thread_mem_nr
    RegisterUserGate
;
    mov esi,OFFSET allocate_local_linear
    mov edi,OFFSET allocate_local_linear_name
    xor cl,cl
    mov ax,allocate_local_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_debug_local_linear
    mov edi,OFFSET allocate_debug_local_linear_name
    xor cl,cl
    mov ax,allocate_debug_local_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET reserve_local_linear
    mov edi,OFFSET reserve_local_linear_name
    xor cl,cl
    mov ax,reserve_local_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET available_small_local_linear
    mov edi,OFFSET available_small_local_linear_name
    xor dx,dx
    mov ax,available_small_local_linear_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET available_big_local_linear
    mov edi,OFFSET available_big_local_linear_name
    xor dx,dx
    mov ax,available_big_local_linear_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET used_local_linear
    mov edi,OFFSET used_local_linear_name
    xor dx,dx
    mov ax,used_local_linear_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET allocate_vm_linear
    mov edi,OFFSET allocate_vm_linear_name
    xor cl,cl
    mov ax,allocate_vm_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET available_vm_linear
    mov edi,OFFSET available_vm_linear_name
    xor dx,dx
    mov ax,available_vm_linear_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET used_vm_linear
    mov edi,OFFSET used_vm_linear_name
    xor dx,dx
    mov ax,used_vm_linear_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET used_local_linear_thread
    mov edi,OFFSET used_local_linear_thread_name
    xor cl,cl
    mov ax,used_local_linear_thread_nr
    RegisterOsGate
;
    mov ebx,OFFSET allocate_local_mem16
    mov esi,OFFSET allocate_local_mem32
    mov edi,OFFSET allocate_local_mem_name
    mov dx,virt_es_out
    mov ax,allocate_local_mem_nr
    RegisterUserGate
;
    mov esi,OFFSET resize_flat_linear
    mov edi,OFFSET resize_flat_linear_name
    xor dx,dx
    mov ax,resize_flat_linear_nr
    RegisterBimodalUserGate
;
    pop ds
    popa
    ret
init_mem    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_MEM_SELS
;
;           DESCRIPTION:    Init selectors
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_mem_sels

init_mem_sels   PROC near
    push ds
    push es
    pushad
;
    AllocatePhysical64
    and ax,0F000h
    or ax,807h
    mov edx,fixed_vm_linear
    call cs:set_sys_page_entry_proc
;
    mov bx,vm_linear_sel
    mov edx,vm_linear
    mov ecx,0F000h
    CreateDataSelector16
;
    mov eax,SIZE local_mem_seg
    mov bx,local_mem_sel
    AllocateFixedProcessMem
;    
    mov ax,system_data_sel
    mov es,ax
;
    mov eax,es:ram2_size
    or eax,eax
    jz init_mem_has_multiboot
;
    push es
    mov eax,30h
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    pop es
;
    xor si,si
    mov ds:[si].mmap_len,14h
    mov ds:[si].mmap_base,0
    mov ds:[si].mmap_base+4,0
    mov eax,es:ram1_size
    mov ds:[si].mmap_size,eax
    mov ds:[si].mmap_size+4,0
    mov ds:[si].mmap_type,1
;
    add si,18h
    mov ds:[si].mmap_len,14h
    mov eax,es:ram2_base
    mov ds:[si].mmap_base,eax
    mov ds:[si].mmap_base+4,0
    mov eax,es:ram2_size
    mov ds:[si].mmap_size,eax
    mov ds:[si].mmap_size+4,0
    mov ds:[si].mmap_type,1
    mov es:multiboot_sel,ds
    mov es:multiboot_size,30h
    jmp imsDone        
    
init_mem_has_multiboot:
    mov eax,2000h
    AllocateBigLinear
    mov esi,edx
    mov ebp,edx
    xor ebx,ebx
    mov eax,es:multiboot_mmap_addr
    and ax,0F000h
    or al,67h
    SetPageEntry
;
    add edx,1000h
    add eax,1000h    
    SetPageEntry
;
    mov eax,es:multiboot_mmap_addr
    and eax,0FFFh
    or esi,eax
    movzx eax,es:multiboot_mmap_len
    AllocateSmallGlobalMem
    mov ecx,eax
;
    mov ax,flat_sel
    mov ds,ax
;
    push ecx
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]        
    pop ecx
;
    mov ax,system_data_sel
    mov ds,ax
;
    mov ds:multiboot_sel,es
    mov ds:multiboot_size,cx    
;    
    mov ax,system_data_sel
    mov es,ax
;    
    mov cx,es:multiboot_size
    mov ds,es:multiboot_sel
    xor di,di
;   
    movzx eax,cx
    AllocateSmallGlobalMem
    
OutLoop:  
    push cx
    push di
    xor si,si
    xor di,di    
    mov ebx,-1
    mov ebp,ebx

InLoop:
    mov eax,ds:[si].mmap_base
    mov edx,ds:[si].mmap_base+4
    sub eax,ebx
    sbb edx,ebp
    jnc InNext
;
    mov ebx,ds:[si].mmap_base
    mov ebp,ds:[si].mmap_base+4
    mov di,si

InNext:
    mov eax,ds:[si].mmap_len
    add ax,4
    add si,ax
    cmp si,cx
    jnz InLoop
;
    mov si,di
    pop di
    pop cx    
;
    push cx
    push si
    mov ecx,ds:[si].mmap_len
    add cx,4
    rep movs byte ptr es:[di],ds:[si]
    pop si
    pop cx
;
    mov eax,-1
    mov ds:[si].mmap_base,eax
    mov ds:[si].mmap_base+4,eax
;
    cmp di,cx
    jnz OutLoop
;
    mov bx,es
    mov ax,system_data_sel
    mov ds,ax    
    xchg bx,ds:multiboot_sel
    mov es,bx
    FreeMem

imsDone:
    popad
    pop es
    pop ds
    ret
init_mem_sels   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_BIG_LINEAR
;
;           DESCRIPTION:    Allocate page-aligned kernel memory
;
;           PARAMETERS:     EAX         # of bytes
;
;           RETURNS:        EDX         Linear base address
;                           CX          # of pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_big_linear_name    DB 'Allocate Big Linear',0

allocate_big_linear     PROC far
    push ds
    push es
    push eax
    push ebx
;
    mov dx,mem_sel
    mov ds,dx
    mov es,dx
    EnterSection ds:big_section
;    
    inc es:big_alloc_count
    mov edx,global_page_size
    sub edx,es:big_avail_mem
    add edx,global_page_linear
    dec eax
    and ax,0F000h
    add eax,1000h
    add es:big_used_mem,eax
    sub es:big_avail_mem,eax
    shr eax,12
    mov ecx,eax
    mov eax,global_page_linear + global_page_size
    call cs:allocate_sys_page_entries_proc
    jnc allocate_big_ok

allocate_big_retry:
    mov ax,100
    WaitMilliSec
;
    mov edx,global_page_linear
    mov eax,global_page_linear + global_page_size
    call cs:allocate_sys_page_entries_proc
    jc allocate_big_retry
        
allocate_big_ok:
    mov ax,mem_sel
    mov ds,ax
    LeaveSection ds:big_section
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
allocate_big_linear     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_SMALL_LINEAR
;
;           DESCRIPTION:    Allocate byte-aligned (dword) kernel memory
;
;           PARAMETERS:         EAX         # of bytes
;
;           RETURNS:        EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_small_linear_name      DB 'Allocate Small Linear',0

allocate_small_linear   PROC far
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    mov dx,mem_sel
    mov ds,dx
    mov es,dx
    EnterSection ds:small_section
;       
    dec eax
    and al,0FCh
    add eax,4
;
    add eax,10h
;
    mov dx,small_mem_sel
    mov ds,dx
    xor edx,edx
    xor ebx,ebx
    mov edx,[edx].slf_next
allocate_small_loop:
    mov ecx,[edx].sls_next
    sub ecx,edx
    cmp ecx,eax
    jnc allocate_small_found
    mov ebx,edx
    mov edx,[edx].slf_next
    jmp allocate_small_loop
allocate_small_found:
    sub ecx,eax
    cmp ecx,16
    jc allocate_small_no_split
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
    jz allocate_last_free
    mov [eax].slf_prev,ebx
allocate_last_free:
    mov eax,[edx].slf_prev
    mov [ebx].slf_prev,eax
    or eax,eax
    jz allocate_first_free
    mov [eax].slf_next,ebx
allocate_first_free:
;
    jmp allocate_small_done
allocate_small_no_split:
    mov eax,[edx].slf_prev
    mov ebx,[edx].slf_next
    mov [eax].slf_next,ebx
    mov [ebx].slf_prev,eax
allocate_small_done:
    xor eax,eax
    mov ebx,[eax].slf_next
    cmp ebx,edx
    jnz allocate_small_end
    mov ebx,[edx].slf_next
    mov [eax].slf_next,ebx
allocate_small_end:
    xor eax,eax
    mov ebx,[eax].sls_prev
    mov ecx,[edx].sls_next
    cmp ebx,ecx
    jnc no_small_biggest_block
    mov [eax].sls_prev,ecx
no_small_biggest_block: 
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
    inc es:small_alloc_count
;
    mov ax,mem_sel
    mov ds,ax
    LeaveSection ds:small_section
    add edx,global_byte_linear + 10h
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
allocate_small_linear   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_LOCAL_LINEAR
;
;           DESCRIPTION:    Allocate local memory (in process address space)
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_local_linear_name      DB 'Allocate Local Linear',0

allocate_local_linear   PROC far
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    dec eax
    and ax,0F000h
    add eax,1000h
    mov dx,local_mem_sel
    mov ds,dx
    mov es,dx
    EnterSection ds:local_mem_section
    add ds:local_big_used_mem,eax
    sub ds:local_big_avail_mem,eax
    shr eax,12
;    
    mov edx,local_page_linear + 1000h
    mov ecx,eax
    call GetAllocFlatSize
    call cs:allocate_page_entries_proc
    jnc allocate_page_local_ok
;
    int 3

allocate_page_local_ok:    
    mov ax,local_mem_sel
    mov ds,ax
    LeaveSection ds:local_mem_section
;
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
allocate_local_linear   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_DEBUG_LOCAL_LINEAR
;
;           DESCRIPTION:    Allocate local memory (in process address space)
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_debug_local_linear_name    DB 'Allocate Debug Local Linear',0

allocate_debug_local_linear     PROC far
    push ds
    push es
    push eax
    push ebx
    push ecx
;
    dec eax
    and ax,0F000h
    add eax,1000h
    mov dx,local_mem_sel
    mov ds,dx
    mov es,dx
    EnterSection ds:local_mem_section
    add ds:local_big_used_mem,eax
    sub ds:local_big_avail_mem,eax
    shr eax,12
;    
    mov edx,ds:local_big_base
    mov ecx,eax
    call GetAllocFlatSize
    call cs:allocate_page_entries_proc
    jnc allocate_debug_page_local_ok
;
    mov edx,local_page_linear + 1000h
    call cs:allocate_page_entries_proc
    jnc allocate_debug_page_local_ok
;
    int 3

allocate_debug_page_local_ok:    
    mov ax,local_mem_sel
    mov ds,ax
    shl ecx,12
    add ecx,edx
    mov ds:local_big_base,ecx
    LeaveSection ds:local_mem_section
;
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
allocate_debug_local_linear     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReserveLocalLinear
;
;           DESCRIPTION:    Reserve local memory
;
;           PARAMETERS:         EAX         Number of bytes
;                           EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reserve_local_linear_name       DB 'Reserve Local Linear',0

reserve_local_linear    PROC far
    push ds
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    push eax
    call GetAllocFlatSize
    mov edi,eax
    pop eax
;
    dec eax
    and ax,0F000h
    add eax,1000h
    mov bx,local_mem_sel
    mov ds,bx
    EnterSection ds:local_mem_section
    cmp edx,local_page_linear
    jc reserve_local_linear_inv_range
    cmp edx,edi
    jae reserve_local_linear_inv_range
    mov ecx,eax
    add ecx,edx
    cmp ecx,local_page_linear
    jc reserve_local_linear_inv_range
    cmp ecx,edi
    jae reserve_local_linear_inv_range
;
    shr eax,12
    mov ecx,eax
    call cs:reserve_page_entries_proc
    jnc reserve_local_linear_done

reserve_local_linear_inv_range:
    stc

reserve_local_linear_done:
    pushf
    mov ax,local_mem_sel
    mov ds,ax
    LeaveSection ds:local_mem_section
    popf
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
reserve_local_linear    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RESIZE_FLAT_LINEAR
;
;           DESCRIPTION:    Resize flat linear
;
;           PARAMETERS:         EAX         New size
;                           ECX         Old size
;                           EDX         Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resize_flat_linear_name DB 'Resize Flat Linear',0

resize_flat_linear      PROC far
    push ds
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;       
    push eax
    call GetAllocFlatSize
    mov edi,eax
    pop eax
;
    mov bx,system_data_sel
    mov ds,bx
    mov esi,ds:flat_base
;
    mov bx,local_mem_sel
    mov ds,bx
    EnterSection ds:local_mem_section
;
    cmp edx,edi
    jae resize_flat_leave
;
    add edx,esi
    cmp edx,ds:flat_base
    jc resize_flat_leave
;
    and dx,0F000h
    dec eax
    and ax,0F000h
    add eax,1000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
;
    cmp eax,ecx
    jz resize_flat_leave
    jc resize_flat_shrink

resize_flat_grow:
    push eax
    push ecx
    push edx
;
    add edx,ecx
    sub eax,ecx
    mov ecx,eax
    push ecx
    shr ecx,12
;
    push ecx
    push edx

resize_flat_test_grow_loop:
    GetPageEntry
    test al,7
    jnz resize_flat_grow_copy
;
    add edx,1000h
    loop resize_flat_test_grow_loop
;
    pop edx
    pop ecx
;
    mov eax,2
    xor ebx,ebx

resize_flat_grow_loop:
    SetPageEntry
    add edx,1000h
    loop resize_flat_grow_loop
;
    pop ecx
    mov bx,local_mem_sel
    mov ds,bx
    sub ds:local_big_avail_mem,ecx
    add ds:local_big_used_mem,ecx
    LeaveSection ds:local_mem_section
    add esp,12
    clc
    jmp resize_flat_done

resize_flat_grow_copy:
    add esp,12
    mov bx,local_mem_sel
    mov ds,bx
    LeaveSection ds:local_mem_section
;
    pop ebx
    pop ecx
    pop eax
    AllocateLocalLinear
;
    add esp,4
    sub edx,esi
    push edx
    add edx,esi
;
    push esi
    push edi
    push ecx
;
    mov esi,ebx
    mov edi,edx
    shr ecx,12
    CopyPageEntries
;
    pop ecx
    pop edi
    pop esi
;    
    FreeLinear
    clc
    jmp resize_flat_done

resize_flat_shrink:
    add edx,eax
    sub ecx,eax
    add ds:local_big_avail_mem,ecx
    sub ds:local_big_used_mem,ecx
    shr ecx,12
;
    mov eax,edi
    sub eax,edx
    jc resize_flat_leave
;    
    shl eax,12
    cmp ecx,eax
    jbe resize_flat_size_ok
;
    mov ecx,eax    

resize_flat_size_ok:
    or ecx,ecx
    jz resize_flat_leave
;
    xor eax,eax
    call cs:free_page_entries_proc
    clc

resize_flat_leave:
    LeaveSection ds:local_mem_section

resize_flat_done:    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
resize_flat_linear      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_VM_LINEAR
;
;           DESCRIPTION:    Allocate V86 mode addressable memory
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_vm_linear_name DB 'Allocate VM Linear',0

allocate_vm_linear      PROC far
    push ds
    push es
    push bx
    push cx
    push si
    push di
;
    mov dx,local_mem_sel
    mov ds,dx
    mov es,dx
    EnterSection ds:vm_mem_section
    mov dx,es:vm_avail_mem
    add es:vm_used_mem,ax
    sub dx,ax
    sub dx,8
    add ax,8
    mov es:vm_avail_mem,dx
;
    mov dx,vm_linear_sel
    mov ds,dx
    xor si,si
    xor bx,bx
    mov si,[si].vmf_next
allocate_vm_loop:
    mov cx,[si].vms_next
    sub cx,si
    cmp cx,ax
    jnc allocate_vm_found
    mov bx,si
    mov si,[si].vmf_next
    jmp allocate_vm_loop
allocate_vm_found:
    sub cx,ax
    cmp cx,8
    jc allocate_vm_no_split
    mov bx,ax
    add bx,si
;       
    mov di,[si].vms_next
    mov [bx].vms_next,di
    mov [bx].vms_prev,si
    mov [si].vms_next,bx
    mov [di].vms_prev,bx
;
    mov di,[si].vmf_next
    mov [bx].vmf_next,di
    mov [si].vmf_next,bx
    or di,di
    jz allocate_vm_last_free
    mov [di].vmf_prev,bx
allocate_vm_last_free:
    mov di,[si].vmf_prev
    mov [bx].vmf_prev,di
    or di,di
    jz allocate_vm_first_free
    mov [di].vmf_next,bx
allocate_vm_first_free:
;
    jmp allocate_vm_done
allocate_vm_no_split:
    mov di,[si].vmf_prev
    mov bx,[si].vmf_next
    mov [di].vmf_next,bx
    mov [bx].vmf_prev,di
allocate_vm_done:
    xor di,di
    mov bx,[di].vmf_next
    cmp bx,si
    jnz allocate_vm_end
    mov bx,[si].vmf_next
    mov [di].vmf_next,bx
allocate_vm_end:
    xor di,di
    mov bx,[di].vms_prev
    mov cx,[si].vms_next
    cmp bx,cx
    jnc no_vm_biggest_block
    mov [di].vms_prev,cx
no_vm_biggest_block:    
    dec di
    mov [si].vmf_prev,di
    mov [si].vmf_next,di
    mov bx,local_mem_sel
    mov ds,bx
    LeaveSection ds:vm_mem_section
    movzx edx,si
    add edx,vm_linear + 8
    pop di
    pop si
    pop cx
    pop bx
    pop es
    pop ds
    retf32
allocate_vm_linear      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AvailableBigLinear
;
;           DESCRIPTION:    Available page-aligned kernel memory
;
;           RETURNS:        EAX         Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_big_linear_name       DB 'Available Big Linear',0

available_big_linear    PROC far
    push ds
    mov ax,mem_sel
    mov ds,ax
    mov eax,ds:big_avail_mem
    pop ds
    retf32
available_big_linear    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AvailableSmallLinear
;
;           DESCRIPTION:    Available byte-aligned kernel memory
;
;           RETURNS:        EAX         Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_small_linear_name     DB 'Available Small Linear',0

available_small_linear  PROC far
    push ds
    mov ax,mem_sel
    mov ds,ax
    mov eax,ds:small_avail_mem
    pop ds
    retf32
available_small_linear  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AVAILABLE_LOCAL_SMALL_LINEAR
;
;           DESCRIPTION:    Available local small (process) memory
;
;           RETURNS:        EAX         Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_small_local_linear_name     DB 'Available Small Local Linear',0

available_small_local_linear  PROC far
    xor eax,eax
    stc
    retf32
available_small_local_linear  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AVAILABLE_LOCAL_BIG_LINEAR
;
;           DESCRIPTION:    Available local big (process) memory
;
;           RETURNS:        EAX         Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_big_local_linear_name     DB 'Available Big Local Linear',0

available_big_local_linear  PROC far
    push ds
    mov ax,local_mem_sel
    mov ds,ax
    mov eax,ds:local_big_avail_mem
    pop ds
    retf32
available_big_local_linear  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AVAILABLE_VM_LINEAR
;
;           DESCRIPTION:    Available V86 mode addressable memory
;
;           RETURNS:        EAX         Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_vm_linear_name    DB 'Available VM Linear',0

available_vm_linear     PROC far
    push ds
    mov ax,local_mem_sel
    mov ds,ax
    movzx eax,ds:vm_avail_mem
    pop ds
    retf32
available_vm_linear     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           USED_BIG_LINEAR
;
;           DESCRIPTION:    Used page-aligned kernel memory
;
;           PARAMETERS:         EAX         Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_big_linear_name    DB 'Used Big Linear',0

used_big_linear PROC far
    push ds
    mov ax,mem_sel
    mov ds,ax
    mov eax,ds:big_used_mem
    pop ds
    retf32
used_big_linear ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           USED_SMALL_LINEAR
;
;           DESCRIPTION:    Used byte-aligned kernel memory
;
;           PARAMETERS:         EAX         Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_small_linear_name  DB 'Used Small Linear',0

used_small_linear       PROC far
    push ds
    mov ax,mem_sel
    mov ds,ax
    mov eax,ds:small_used_mem
    pop ds
    retf32
used_small_linear       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           USED_LOCAL_LINEAR
;
;           DESCRIPTION:    User local (process) memory
;
;           PARAMETERS:         EAX     ANTAL BYTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_local_linear_name  DB 'Used Local Linear',0

used_local_linear       PROC far
    xor eax,eax
    stc
    retf32
used_local_linear       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           USED_VM_LINEAR
;
;           DESCRIPTION:    Used V86 addressable memory
;
;           PARAMETERS:         EAX         Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_vm_linear_name     DB 'Used VM Linear',0

used_vm_linear  PROC far
    push ds
    mov ax,local_mem_sel
    mov ds,ax
    movzx eax,ds:vm_used_mem
    pop ds
    retf32
used_vm_linear  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           USED_LOCAL_LINEAR_THREAD
;
;           DESCRIPTION:    User local (process) memory in other thread
;
;           PARAMETERS:         BX          Thread
;
;           RETURNS:        EAX         Number of bytes
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_local_linear_thread_name   DB 'Used Local Linear Thread',0

used_local_linear_thread    PROC far
    push ds
    push es
    push cx
    push dx
    push esi
;
    mov dx,local_mem_sel
    xor esi,esi
    ReadThreadSelector
    mov cx,ax
    inc esi
    ReadThreadSelector
    mov ah,al
    mov al,cl
    push ax
    inc esi
    ReadThreadSelector
    mov cx,ax
    inc esi
    ReadThreadSelector
    mov ah,al
    mov al,cl
    shl eax,16
    pop ax
;
    pop esi
    pop dx
    pop cx
    pop es
    pop ds
    retf32
used_local_linear_thread    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_GLOBAL_MEM
;
;           DESCRIPTION:    Allocate page-aligned kernel memory
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_global_name    DB 'Allocate Global Memory',0

allocate_global_mem     PROC far
    push ds
    push bx
    push ecx
    push edx
;
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector16
    mov es,bx
;
    pop edx
    pop ecx
    pop bx
    pop ds
    retf32
allocate_global_mem     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_SMALL_GLOBAL_MEM
;
;           DESCRIPTION:    Allocate byte-aligned kernel memory
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_small_global_name      DB 'Allocate Small Global Memory',0

allocate_small_global_mem       PROC far
    push ds
    push eax
    push bx
    push ecx
    push edx
;
    cmp eax,100000h
    jc alloc_small_g_not_page
    dec eax
    and ax,0F000h
    add eax,1000h
alloc_small_g_not_page:
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector16
    mov es,bx
;
    pop edx
    pop ecx
    pop bx
    pop eax
    pop ds
    retf32
allocate_small_global_mem       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_PAGES
;
;           DESCRIPTION:    Free used physical memory pages for linear region
;
;           PARAMETERS:         EDX         Start linear address
;                           EAX         End linear address
;                           DS          Page table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_pages      PROC near
    dec edx
    shr edx,10
    and dx,NOT 3
    add dx,4
    mov bx,dx
    mov edx,eax
    shr edx,10
    and dx,NOT 3
    mov cx,dx
    sub cx,bx
    jc no_free_pages
    jz no_free_pages
    shr cx,2
free_pages_loop:
    xor eax,eax
    xchg eax,[bx]
    test al,1
    jz free_pages_nopage
;
    test ax,800h
    jnz free_pages_nopage
;
    push ebx
    xor ebx,ebx
    FreePhysical
    pop ebx

free_pages_nopage:
    add bx,4
    loop free_pages_loop
no_free_pages:
    ret
free_pages      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_MEM
;
;           DESCRIPTION:    Free memory
;
;           PARAMETERS:         ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_name       DB 'Free Memory',0

free_big_mem    PROC near
    dec ecx
    and cx,0F000h
    add ecx,1000h
    mov ax,mem_sel
    mov ds,ax
    EnterSection ds:big_section
    dec es:big_alloc_count
    add es:big_avail_mem,ecx
    sub es:big_used_mem,ecx
    shr ecx,12
    xor eax,eax
    call cs:free_global_page_entries_proc
    LeaveSection ds:big_section
    ret
free_big_mem    ENDP

free_small_mem  PROC near
    sub edx,global_byte_linear + 10h
    mov ax,mem_sel
    mov ds,ax
    EnterSection ds:small_section
    mov ax,small_mem_sel
    mov ds,ax
    mov eax,[edx].sls_next
    sub eax,edx
    mov ebx,es:small_avail_mem
    add ebx,eax
    mov es:small_avail_mem,ebx
    sub eax,10h
    sub es:small_used_mem,eax
    dec es:small_alloc_count
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
    mov bx,mem_sel
    mov ds,bx
    LeaveSection ds:small_section
    ret
free_small_mem  ENDP

free_system:
    cmp edx,global_byte_linear
    jc free_error
    cmp edx,global_page_linear
    jc free_small_mem
    cmp edx,global_page_linear + global_page_size
    jc free_big_mem
    jmp free_error

free_local_mem  PROC near
    cmp edx,local_page_linear
    jc free_low_mem
    jmp free_big_local_mem
free_local_mem  Endp

free_low_mem    Proc near
    cmp edx,vm_linear
    jnc free_vm_mem
;
    FreeDosLinear
    ret
free_low_mem    Endp

free_vm_mem     PROC near
    mov ax,local_mem_sel
    mov ds,ax
    mov es,ax
    EnterSection ds:vm_mem_section
    sub edx,vm_linear
    mov si,dx
    sub si,8
    mov ax,vm_linear_sel
    mov ds,ax
    mov di,[si].vms_next
    sub di,si
    mov bx,es:vm_avail_mem
    add bx,di
    mov es:vm_avail_mem,bx
    add es:vm_used_mem,8
    sub es:vm_used_mem,di
;
    mov di,[si].vms_prev
    or di,di
    jz free_vm_no_merge_down
    mov di,[di].vmf_next
    inc di
    or di,di
    jz free_vm_no_merge_down
    mov di,si
    mov si,[di].vms_prev
    mov bx,[di].vms_next
    mov [si].vms_next,bx
    mov [bx].vms_prev,si
    jmp free_vm_test_up
free_vm_no_merge_down:
    xor di,di
    mov [si].vmf_prev,di
    mov bx,[di].vmf_next
    mov [si].vmf_next,bx
    mov [di].vmf_next,si
    mov [bx].vmf_prev,si
free_vm_test_up:
    mov di,[si].vms_next
    mov di,[di].vmf_prev
    inc di
    or di,di
    jz free_vm_no_merge_up
    push si
    mov si,[si].vms_next
    mov di,[si].vmf_prev
    mov bx,[si].vmf_next
    or di,di
    jz fm1_vm_bypass
    mov [di].vmf_next,bx
fm1_vm_bypass:
    or bx,bx
    jz fm2_vm_bypass
    mov [bx].vmf_prev,di
fm2_vm_bypass:
    xor di,di
    mov bx,[di].vmf_next
    cmp bx,si
    jne fm3_vm_bypass
    mov bx,[bx].vmf_next
    mov [di].vmf_next,bx
fm3_vm_bypass:
    pop si
    mov bx,[si].vms_next
    mov bx,[bx].vms_next
    mov [bx].vms_prev,si
    mov [si].vms_next,bx
free_vm_no_merge_up:
    xor di,di
    mov bx,[di].vms_prev
    mov di,[si].vms_next
    cmp di,bx
    jc free_vm_not_limit_page
    mov di,bx
    add di,1000h
    xor bx,bx
    mov [bx].vms_prev,si
free_vm_not_limit_page:
    movzx edx,si
    movzx eax,di
    add edx,vm_linear + 8
    add eax,vm_linear
    mov bx,local_mem_sel
    mov ds,bx
    LeaveSection ds:vm_mem_section
    ret
free_vm_mem     ENDP

free_big_local_mem      PROC near
    mov ax,local_mem_sel
    mov ds,ax
    mov es,ax
    EnterSection ds:local_mem_section
    dec ecx
    and cx,0F000h
    add ecx,1000h
    add es:local_big_avail_mem,ecx
    sub es:local_big_used_mem,ecx
    shr ecx,12
    xor eax,eax
    call cs:free_page_entries_proc
    LeaveSection ds:local_mem_section
    ret
free_big_local_mem      ENDP
    
free_error      PROC near
    int 3
    ret
free_error      ENDP

free_mem    PROC far
    pushad
    push ds
    push fs
    push gs
;
    xor ax,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax
;
    mov bx,es
    mov ax,mem_sel
    mov es,ax
    and bx,0FFFCh
    jz free_mem_end
    test bx,4
    pushf
    jz free_in_gdt
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bx,0FFF8h
    jmp free_descr
free_in_gdt:
    mov ax,gdt_sel
    mov ds,ax       
free_descr:
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    inc ecx
    test byte ptr [bx+6],80h
    jz free_not_huge
    shl ecx,12
free_not_huge:
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
    mov ax,[bx+6]

    cmp ecx,1000000h
    jc free_mem_size_ok
;
    int 3

free_mem_size_ok:
    
    mov byte ptr [bx+5],0
    popf
    jz free_descr_gdt
    FreeLdt
    jmp free_lin_mem
free_descr_gdt:
    FreeGdt
free_lin_mem:
    test al,10h
    jnz free_mem_end
;
    cmp edx,system_mem_start
    jc free_mem_local
;
    call free_system
    jmp free_mem_clear

free_mem_local:
    call free_local_mem

free_mem_clear:
    xor ax,ax
    mov es,ax
free_mem_end:
    pop ax
    verr ax
    jz free_mem_gs_ok
;
    xor ax,ax
    
free_mem_gs_ok:
    mov gs,ax
    pop ax
    verr ax
    jz free_mem_fs_ok
;
    xor ax,ax
    
free_mem_fs_ok:
    mov fs,ax
    pop ax
    verr ax
    jz free_mem_ds_ok
;
    xor ax,ax
    
free_mem_ds_ok:
    mov ds,ax
;    
    popad
    retf32
free_mem    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_SELECTOR
;
;           DESCRIPTION:    Free selector but not covered linear memory
;
;           PARAMETERS:         ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_selector_name      DB 'Free Selector',0

free_selector   PROC far
    push ds
    pushf
    push ax
    push bx
;
    mov bx,es
    xor ax,ax
    mov es,ax
    and bx,0FFFCh
    jz free_selector_end
    test bx,4
    jz free_selector_in_gdt
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bx,0FFF8h
    FreeLdt
    jmp free_selector_done
free_selector_in_gdt:
    FreeGdt
free_selector_done:
free_selector_end:
    pop bx
    pop ax
    popf
    pop ds
    retf32
free_selector   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_LINEAR
;
;           DESCRIPTION:    Free linear memory
;
;           PARAMETERS:         ECX         Size
;                           EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_linear_name    DB 'Free Linear',0

free_linear     PROC far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push si
;
    mov ax,mem_sel
    mov es,ax
    cmp edx,system_mem_start
    jc free_linear_local
;
    call free_system
    jmp free_linear_clear

free_linear_local:
    call free_local_mem

free_linear_clear:
    xor edx,edx
    pop si
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
free_linear     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RESIZE_LINEAR
;
;           DESCRIPTION:    Resize linear memory block
;
;           PARAMETERS:         EAX         New size
;                           ECX         Old size
;                           EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resize_linear_name      DB 'Resize Linear',0

resize_linear   PROC far
    push ds
    push esi
    push edi
;    
    push eax
    call GetAllocFlatSize
    mov edi,eax
    pop eax
;
    cmp edx,edi
    jnc resize_mem_error
;
    cmp edx,local_page_linear
    jc resize_low_mem
;
    mov si,system_data_sel
    mov ds,si
    mov esi,ds:flat_base
    sub edx,esi
    ResizeFlatLinear
    jc resize_mem_error
;
    add edx,ds:flat_base
    clc
    jmp resize_mem_done

resize_low_mem:
    cmp edx,vm_linear
    jnc resize_mem_error
;
    ResizeDosLinear
    jmp resize_mem_done

resize_mem_error:
    int 3
    stc

resize_mem_done:
    pop edi
    pop esi
    pop ds
    retf32
resize_linear   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LogSmallMem
;
;           DESCRIPTION:    Log small mem allocations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

log_small_mem_name DB 'Log Small Memory',0

log_small_mem      PROC far
    push ds
    push eax
;
    mov ax,mem_sel
    mov ds,ax
    mov eax,ds:small_alloc_count
    LogHexDword
;
    pop eax
    pop ds
    retf32
log_small_mem   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LogBigMem
;
;           DESCRIPTION:    Log big mem allocations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

log_big_mem_name DB 'Log Big Memory',0

log_big_mem      PROC far
    push ds
    push eax
;
    mov ax,mem_sel
    mov ds,ax
    mov eax,ds:big_alloc_count
    LogHexDword
;
    pop eax
    pop ds
    retf32
log_big_mem     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_SMALL_KERNEL_MEM
;
;           DESCRIPTION:    Allocate byte-aligned process memory with kernel-only access
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_small_kernel_mem_name  DB 'Allocate Small Kernel Memory',0

allocate_small_kernel_mem       PROC far
    push ds
    push eax
    push bx
    push ecx
    push edx
    mov ecx,eax
;
    AllocateSmallLinear
    AllocateLdt
    or bx,4
    CreateDataSelector16
    mov es,bx
;
    pop edx
    pop ecx
    pop bx
    pop eax
    pop ds
    retf32
allocate_small_kernel_mem       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_LOCAL_MEM16
;
;           DESCRIPTION:    Allocate process memory
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem_name       DB 'Allocate Memory',0

allocate_local_mem_name DB 'Allocate Local Memory',0

allocate_local_mem16    PROC far
    push ds
    push eax
    push bx
    push cx
    push edx
    cmp eax,100000h
    jc alloc_local_not_page16
    dec eax
    and ax,0F000h
    add eax,1000h
alloc_local_not_page16:
    AllocateLocalLinear
    AllocateLdt
    cmp eax,100000h
    jnc alloc_local_big_seg16
    dec eax
    mov [bx],ax
    mov [bx+2],edx
    mov dl,0F2h
    xchg dl,[bx+5]
    shr eax,16
    and ax,0Fh
    or ah,dl
    mov [bx+6],ax
    jmp alloc_local_big_seg_ok16
alloc_local_big_seg16:
    shr eax,12
    dec ax
    mov [bx],ax
    mov [bx+2],edx
    mov ah,0F2h
    xchg ah,[bx+5]
    mov al,80h
    mov [bx+6],ax
alloc_local_big_seg_ok16:
    or bx,7
    mov es,bx
    pop edx
    pop cx
    pop bx
    pop eax
    pop ds
    retf32
allocate_local_mem16    ENDP

allocate_local_mem32    PROC far
    push ds
    push eax
    push bx
    push cx
    push edx
    cmp eax,100000h
    jc alloc_local_not_page32
    dec eax
    and ax,0F000h
    add eax,1000h
alloc_local_not_page32:
    AllocateLocalLinear
    AllocateLdt
    cmp eax,100000h
    jnc alloc_local_big_seg32
    dec eax
    mov [bx],ax
    mov [bx+2],edx
    mov dl,0F2h
    xchg dl,[bx+5]
    shr eax,16
    and ax,0Fh
    or al,40h
    or ah,dl
    mov [bx+6],ax
    jmp alloc_local_big_seg_ok32
alloc_local_big_seg32:
    shr eax,12
    dec ax
    mov [bx],ax
    mov [bx+2],edx
    mov ah,0F2h
    xchg ah,[bx+5]
    mov al,0C0h
    mov [bx+6],ax
alloc_local_big_seg_ok32:
    or bx,7
    mov es,bx
    pop edx
    pop cx
    pop bx
    pop eax
    pop ds
    retf32
allocate_local_mem32    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SELECTOR_TO_SEGMENT
;
;           DESCRIPTION:    Convert a selector to a segment if possible     
;
;           PARAMETERS:         AX          Selector
;
;           RETURNS:        NC      EAX SEGMENT
;                           CY      EAX = F000      
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

selector_to_segment_name    DB 'Selector to Segment',0

selector_to_segment     PROC far
    push ds
    push bx
    mov bx,ax
    test bx,4
    jz get_in_gdt
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bx,0FFF8h
    jmp get_seg_do
get_in_gdt:
    mov ax,gdt_sel
    mov ds,ax       
get_seg_do:
    mov ax,[bx+6]
    or ax,ax
    jnz get_seg_error
    mov eax,[bx+2]
    shr eax,4
    and eax,0FFFFh
    clc
    jmp get_seg_end
get_seg_error:
    stc
    mov eax,0F000h
get_seg_end:
    pop bx
    pop ds
    retf32
selector_to_segment     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           TRANSLATE_SEGMENT
;
;           DESCRIPTION:    Translate a segment into a selector
;
;           PARAMETERS:         BX          Segment
;
;           RETURNS:        BX          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public translate_segment

translate_segment_base  PROC near
    push ds
    push ax
    push edx
    xor edx,edx
    mov dx,bx
    shl edx,4
    AllocateLdt
    mov word ptr [bx],0FFFFh
    mov [bx+2],edx
    mov byte ptr [bx+5],0F2h
    mov word ptr [bx+6],10h
    or bx,7
    pop edx
    pop ax
    pop ds
    ret
translate_segment_base  ENDP


translate_segment       PROC near
    push si
    xor si,si
    call translate_segment_base
    pop si
    ret
translate_segment       ENDP

    public translate_dpl_segment

translate_dpl_segment   PROC near
    push si
    mov si,ax
    call translate_segment_base
    pop si
    ret
translate_dpl_segment   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SEGMENT_TO_SELECTOR
;
;           DESCRIPTION:    Convert a segment into a selector
;
;           PARAMETERS:         BX          Segment
;
;           RETURNS:        BX          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment_to_selector_name    DB 'Segment To Selector',0

segment_to_selector     PROC far
    call translate_segment
    retf32
segment_to_selector     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           TRANSLATE_SELECTOR
;
;           DESCRIPTION:    Translate selector to segment
;
;           PARAMETERS:         BX          SELECTOR
;
;           RETURNS:        NC          BX      Segment
;                           CY          Invalid
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public translate_selector

translate_selector      PROC near
    test bx,4
    jz translate_in_gdt
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bx,0FFF8h
    mov ax,[bx+6]
    and ax,0FF00h
    or ax,ax
    stc
    jnz translate_sel_end
    mov eax,[bx+2]
    shr eax,4
    push ax
    mov ax,[bx+6]
    test ax,10h
    jz translate_no_ldt_free
    FreeLdt
translate_no_ldt_free:
    pop bx
    clc
    jmp translate_sel_end
translate_in_gdt:
    mov ax,gdt_sel
    mov ds,ax       
    mov ax,[bx+6]
    and ax,0FF00h
    stc
    jnz translate_sel_end
    mov eax,[bx+2]
    shr eax,4
    mov bx,ax
    clc
translate_sel_end:
    ret
translate_selector      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_PROCESS_LINEAR
;
;           DESCRIPTION:    Allocate fixed process linear
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_process_linear_name    DB 'Allocate Process Linear',0

allocate_process_linear PROC far
    push ds
    mov dx,mem_sel
    mov ds,dx
    mov edx,ds:process_alloc_base
    add ds:process_alloc_base,eax
    pop ds
    retf32
allocate_process_linear ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_SYSTEM_LINEAR
;
;           DESCRIPTION:    Allocate fixed system memory
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_system_linear_name     DB 'Allocate System Linear',0

allocate_system_linear  PROC far
    push ds
    mov dx,mem_sel
    mov ds,dx
    mov edx,ds:system_alloc_base
    add ds:system_alloc_base,eax
    pop ds
    retf32
allocate_system_linear  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_FIXED_VM_LINEAR
;
;           DESCRIPTION:    Allocate fixed V86 mode linear
;
;           PARAMETERS:         EAX         Number of bytes
;
;           RETURNS:        EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_vm_linear_name   DB 'Allocate Fixed VM Linear',0

allocate_fixed_vm_linear    PROC near
    push ds
    push eax
    mov dx,mem_sel
    dec eax
    and al,0F0h
    add eax,10h
    mov ds,dx
    mov edx,ds:fixed_vm_base
    add ds:fixed_vm_base,eax
    pop eax
    pop ds
    retf32
allocate_fixed_vm_linear    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Local_ALLOCATE_FIXED_PROCESS_MEM
;
;           DESCRIPTION:    Allocate fixed process memory
;
;           PARAMETERS:         EAX         Number of bytes
;                           BX          Selector
;                           
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_allocate_fixed_process_mem

local_allocate_fixed_process_mem      PROC near
    push ds
    push ecx
    push edx
;
    AllocateProcessLinear
    mov ecx,eax
    CreateDataSelector16
    mov es,bx
;
    pop edx
    pop ecx
    pop ds
    ret
local_allocate_fixed_process_mem      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LOCAL_ALLOCATE_FIXED_SYSTEM_MEM
;
;           DESCRIPTION:    Allocate fixed system memory
;
;           PARAMETERS:         EAX         Number of bytes
;                           BX          Selector
;
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_allocate_fixed_system_mem

local_allocate_fixed_system_mem       PROC near
    push ds
    push ecx
    push edx
;
    mov dx,mem_sel
    mov ds,dx
    mov edx,ds:system_alloc_base
    add ds:system_alloc_base,eax
;
    mov ecx,eax
    call local_create_data_sel16
    mov es,bx
;
    pop edx
    pop ecx
    pop ds
    ret
local_allocate_fixed_system_mem       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_FIXED_PROCESS_MEM
;
;           DESCRIPTION:    Allocate fixed process memory
;
;           PARAMETERS:         EAX         Number of bytes
;                           BX          Selector
;                           
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_process_mem_name DB 'Allocate Fixed Process Mem',0

allocate_fixed_process_mem      PROC far
    push ds
    push ecx
    push edx
;
    AllocateProcessLinear
    mov ecx,eax
    CreateDataSelector16
    mov es,bx
;
    pop edx
    pop ecx
    pop ds
    retf32
allocate_fixed_process_mem      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_FIXED_SYSTEM_MEM
;
;           DESCRIPTION:    Allocate fixed system memory
;
;           PARAMETERS:         EAX         Number of bytes
;                           BX          Selector
;
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_system_mem_name  DB 'Allocate Fixed System Mem',0

allocate_fixed_system_mem       PROC far
    push ds
    push ecx
    push edx
;
    mov dx,mem_sel
    mov ds,dx
    mov edx,ds:system_alloc_base
    add ds:system_alloc_base,eax
;
    mov ecx,eax
    call local_create_data_sel16
    mov es,bx
;
    pop edx
    pop ecx
    pop ds
    retf32
allocate_fixed_system_mem       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           VALIDATE_DESCRIPTOR
;
;           DESCRIPTION:    Validate descriptor
;
;           PARAMETERS:         DS:BX       Descriptor
;                           ESI             Offset within descriptor
;
;           RETURNS:        NC              Valid
;                               EDX         Linear address (including offset)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

validate_descriptor     PROC near
    mov dl,[bx+5]
    test dl,80h
    stc
    jz validate_descriptor_done
    test dl,10h
    jz validate_system_descriptor
validate_code_data_descriptor:
    test dl,8
    jnz validate_descriptor_up
    test dl,4
    jz validate_descriptor_up
    jmp validate_descriptor_down
validate_system_descriptor:
    and dl,0Fh
    cmp dl,2
    je validate_descriptor_up
    cmp dl,9
    je validate_descriptor_up
    cmp dl,0Bh
    je validate_descriptor_up
    stc
    jmp validate_descriptor_done
validate_descriptor_up:
    xor edx,edx
    mov dl,[bx+6]
    and dl,0Fh
    shl edx,16
    mov dx,[bx]
    test byte ptr [bx+6],80h
    jz validate_descriptor_byte_up
    shl edx,12
    or dx,0FFFh
validate_descriptor_byte_up:
    cmp edx,esi
    jc validate_descriptor_done
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
    add edx,esi
    clc
    jmp validate_descriptor_done
validate_descriptor_down:
    xor edx,edx
    mov dl,[bx+6]
    and dl,0Fh
    shl edx,16
    mov dx,[bx]
    test byte ptr [bx+6],80h
    jz validate_descriptor_byte_down
    shl edx,12
    or dx,0FFFh
validate_descriptor_byte_down:
    cmp esi,edx
    ja validate_descriptor_down_valid
;
    stc
    jmp validate_descriptor_done

validate_descriptor_down_valid:
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
    add edx,esi
    clc
validate_descriptor_done:
    ret
validate_descriptor     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           VALIDATE_DESCRIPTOR64
;
;           DESCRIPTION:    Validate 64-bit descriptor
;
;           PARAMETERS:     DX:ESI          Offset within descriptor
;                           BX              Thread
;
;           RETURNS:        NC              Valid
;                               EDX         Linear address (including offset)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

validate_descriptor64     PROC near
    push ecx
    push esi
    and dx,0FFF8h
    movzx esi,dx
    mov dx,long_ldt_sel
;
    add si,5        ; offset 5
    ReadThreadSelector
    jc vd_fail64
;
    test al,80h
    jz vd_fail64
;
    test al,10h
    jz vd_fail64

vd_code_data64:
    add si,2        ; offset 7
    ReadThreadSelector
    jc vd_fail64
;
    movzx ecx,al
    shl ecx,8
;
    sub si,3        ; offset 4
    ReadThreadSelector
    jc vd_fail64
;
    mov cl,al
    shl ecx,8
;
    dec si          ; offset 3    
    ReadThreadSelector
    jc vd_fail64
;
    mov cl,al
    shl ecx,8
;
    dec si          ; offset 2    
    ReadThreadSelector
    jc vd_fail64
;
    mov cl,al
    pop esi
    mov edx,ecx
    add edx,esi
    clc
    jmp vd_done64

vd_fail64:
    pop esi
    stc
    
vd_done64:
    pop ecx
    ret
validate_descriptor64     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           VALIDATE_THREAD_SELECTOR
;
;           DESCRIPTION:    Validate descriptor in other thread
;
;           PARAMETERS:         DX:ESI      Selector:Offset
;                           BX              Thread
;
;           RETURNS:        NC              Valid
;                               EDX         Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

validate_thread_selector    Proc near
    test dx,4
    jz validate_thread_gdt

validate_thread_ldt:
    push ds
    push ax
    push bx
    mov ds,bx
    mov ax,ds:p_ldt
    cmp ax,long_ldt_sel
    je validate_ldt64
;
    mov bx,ds:p_ldt_sel
    mov ax,gdt_sel
    mov ds,ax
    mov ax,[bx]
    cmp ax,dx
    jc validate_ldt_thread_done
;
    mov ds,bx
    mov bx,dx
    and bx,0FFF8h
    call validate_descriptor

validate_ldt_thread_done:
    pop bx
    pop ax
    pop ds
    jmp validate_thread_done

validate_ldt64:
    call validate_descriptor64    
;    
    pop bx
    pop ax
    pop ds
    jmp validate_thread_done

validate_thread_gdt:
    push ds
    push bx
    mov bx,gdt_sel
    mov ds,bx
    mov ax,[bx]
    cmp ax,dx
    jc validate_gdt_thread_done
;
    mov bx,dx       
    and bx,0FFF8h
    call validate_descriptor

validate_gdt_thread_done:
    pop bx
    pop ds
    jmp validate_thread_done

validate_thread_fail:
    stc
validate_thread_done:
    mov al,'!'
    ret
validate_thread_selector    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetThreadLinear
;
;           DESCRIPTION:    Get linear base for selector:offset from another thread
;
;           PARAMETERS:         DX:ESI      Selector:offset in thread
;                           BX              Thread
;
;           RETURNS:        NC              Valid
;               EDX     Base linear
;                           CY              Invalid
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_linear_name  DB 'Get Thread Linear',0

get_thread_linear       PROC far
    push es
    push ax
    push bx
;
    ThreadToSel
    jc get_thread_linear_done
;    
    mov ax,flat_sel
    mov es,ax
    call validate_thread_selector

get_thread_linear_done:
    pop bx
    pop ax
    pop es
    ret
get_thread_linear       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           GET_THREAD_SELECTOR_PAGE
;
;    DESCRIPTION:    Get paging settings for thread
;
;    PARAMETERS:     DX:ESI      Selector:offset in thread
;                    BX              Thread
;
;    RETURNS:        NC          Valid
;                                EAX          Page entry
;                    CY          Invalid
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_selector_page_name       DB 'Get Thread Selector Page',0

get_thread_selector_page    PROC far
    push es
    push ebx
    push ecx
    push edx
    push esi
    push bp
;
    mov bp,bx
    mov ax,flat_sel
    mov es,ax

get_thread_selector_page_retry:
    call validate_thread_selector
    jc get_thread_selector_page_done
;
    xor cx,cx
    movzx esi,dx
    and dx,0F000h
    and si,0FFFh
    GetThreadPageEntry
;
    test al,1
    jnz get_thread_selector_page_ok
;    
    stc
    xor eax,eax
    jmp get_thread_selector_page_done

get_thread_selector_page_ok:
    clc
    
get_thread_selector_page_done:
    pop bp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    retf32
get_thread_selector_page    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           READ_THREAD_SELECTOR
;
;           DESCRIPTION:    Read byte from another thread
;
;           PARAMETERS:         DX:ESI      Selector:offset in thread
;                           BX              Thread
;
;           RETURNS:        NC              Valid
;                               AL          Value
;                           CY              Invalid
;                               AL          Error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_thread_selector_name       DB 'Read Thread Selector',0

read_thread_selector    PROC far
    push es
    push ebx
    push ecx
    push edx
    push esi
    push bp
;
    mov bp,bx
    mov ax,flat_sel
    mov es,ax

read_thread_selector_retry:
    call validate_thread_selector
    jc read_thread_selector_done
;
    xor cx,cx
    movzx esi,dx
    and dx,0F000h
    and si,0FFFh
    GetThreadPageEntry
;
    test al,1
    jnz read_thread_selector_ok
;    
    stc
    mov al,'%'
    jmp read_thread_selector_done

read_thread_selector_ok:
    push eax
    mov eax,1000h
    AllocateLocalLinear
    pop eax
    SetPageEntry
;
    mov al,es:[edx+esi]
;
    push eax
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
    pop eax
;    
    mov ecx,1000h
    FreeLinear
    clc
    
read_thread_selector_done:
    pop bp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    retf32
read_thread_selector    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WRITE_THREAD_SELECTOR
;
;           DESCRIPTION:    Write byte to another thread
;
;           PARAMETERS:     DX:ESI          Selector:offset in thread
;                           BX              Thread
;                           AL              Value to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_thread_selector_name      DB 'Write Thread Selector',0

write_thread_selector   PROC far
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push bp
;
    mov bp,bx
    mov cl,al
    mov ax,flat_sel
    mov es,ax

write_thread_selector_retry:
    call validate_thread_selector
    jc write_thread_selector_done
;    
    push cx
    xor cx,cx
    movzx esi,dx
    and dx,0F000h
    and si,0FFFh
    GetThreadPageEntry
    pop cx
;
    test al,1
    jnz write_thread_selector_do
;
    AllocatePhysical64
    or al,7
    SetThreadPageEntry

write_thread_selector_do:
    push eax
    mov eax,1000h
    AllocateLocalLinear
    pop eax
;
    or al,2
    SetPageEntry
;
    mov es:[edx+esi],cl
;
    xor eax,eax
    xor ebx,ebx
    SetPageEntry    
;
    mov ecx,1000h
    FreeLinear
    clc
    
write_thread_selector_done:
    pop bp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    retf32
write_thread_selector   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           READ_THREAD_MEM
;
;           DESCRIPTION:    Read data from another thread
;
;           PARAMETERS:         DX:ESI      Selector:offset in thread
;                           BX              Thread
;                           ES:(E)DI    Buffer
;                           ECX             Size
;                           
;           RETURNS:        (E)AX       Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_thread_mem_name    DB 'Read Thread Mem',0

read_thread_mem PROC near
    push bx
    push ecx
    push esi
    push edi
;
    ThreadToSel
    jc read_thread_mem_done
;    
;       mov al,dl
;       and al,3
;       cmp al,3
;       jne read_thread_mem_done
;
    or ecx,ecx
    jz read_thread_mem_done

read_thread_mem_loop:
    ReadThreadSelector
    jc read_thread_mem_done
;
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jnz read_thread_mem_loop

read_thread_mem_done:
    mov eax,ecx
    pop edi
    pop esi
    pop ecx
    pop bx
    sub eax,ecx
    neg eax
    ret
read_thread_mem ENDP

read_thread_mem16       Proc far
    push edi
    push ecx
;
    movzx ecx,cx
    movzx edi,di
    call read_thread_mem
;
    pop ecx
    pop edi
    retf32
read_thread_mem16       Endp

read_thread_mem32       Proc far
    call read_thread_mem
    retf32
read_thread_mem32       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteThreadMem
;
;           DESCRIPTION:    Write data to another thread
;
;           PARAMETERS:         DX:ESI      Selector:offset in thread
;                           BX              Thread
;                           ES:(E)DI    Buffer
;                           ECX             Size
;                           
;           RETURNS:        (E)AX       Bytes written
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_thread_mem_name   DB 'Write Thread Mem',0

write_thread_mem    PROC near
    push bx
    push ecx
    push esi
    push edi
;
    ThreadToSel
    jc write_thread_mem_done
;    
    mov al,dl
    and al,3
    cmp al,3
    jne write_thread_mem_done
;
    or ecx,ecx
    jz write_thread_mem_done

write_thread_mem_loop:
    mov al,es:[edi]
    WriteThreadSelector
    jc write_thread_mem_done
;
    inc esi
    inc edi
    sub ecx,1
    jnz write_thread_mem_loop

write_thread_mem_done:
    mov eax,ecx
    pop edi
    pop esi
    pop ecx
    pop bx
    sub eax,ecx
    neg eax
    ret
write_thread_mem    ENDP

write_thread_mem16      Proc far
    push edi
    push ecx
;
    movzx ecx,cx
    movzx edi,di
    call write_thread_mem
;
    pop ecx
    pop edi
    retf32
write_thread_mem16      Endp

write_thread_mem32      Proc far
    call write_thread_mem
    retf32
write_thread_mem32      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           READ_THREAD_SEGMENT
;
;           DESCRIPTION:    Read data from another thread
;
;           PARAMETERS:         DX:ESI      Segment:offset in thread
;                           BX              Thread
;
;           RETURNS:        NC              Valid
;                               AL          Value
;                           CY              Invalid
;                               AL          Error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_thread_segment_name    DB 'Read Thread Segment',0

read_thread_segment     PROC far
    push es
    push ebx
    push ecx
    push edx
    push esi
    push bp
;
    mov bp,bx
    mov ax,flat_sel
    mov es,ax
;
    cmp esi,10000h
    jnc read_thread_segment_out_of_range
;
    movzx edx,dx
    shl edx,4
    add edx,esi

read_thread_segment_retry:
    movzx esi,dx
    and dx,0F000h
    or edx,edx
    jnz read_thread_segment_normal
;    
    mov dx,flat_sel
    movzx esi,si
    add esi,page0_linear
    call validate_thread_selector
    jc read_thread_selector_done
    jmp read_thread_segment_retry

read_thread_segment_normal:
    xor cx,cx
    and si,0FFFh
    GetThreadPageEntry
;
    test al,1
    jnz read_thread_segment_ok
;    
    stc
    mov al,'%'
    jmp read_thread_segment_done

read_thread_segment_out_of_range:
    stc
    mov al,'!'
    jmp read_thread_segment_done

read_thread_segment_ok:
    push eax
    mov eax,1000h
    AllocateLocalLinear
    pop eax
;
    SetPageEntry
;
    mov al,es:[edx+esi]
;
    push eax
    xor eax,eax
    xor ebx,ebx
    SetPageEntry    
    pop eax
;
    mov ecx,1000h
    FreeLinear
    clc

read_thread_segment_done:
    pop bp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    retf32
read_thread_segment     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WRITE_THREAD_SEGMENT
;
;           DESCRIPTION:    Write data to another thread
;
;           PARAMETERS:         DX:ESI      Segment:offset
;                           BX              Thread
;                           AL              Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_thread_segment_name       DB 'Write Thread Segment',0

write_thread_segment    PROC far
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push bp
;
    mov bp,bx
    mov cl,al
    mov ax,flat_sel
    mov es,ax
;
    movzx edx,dx
    shl edx,4
    add edx,esi

write_thread_segment_retry:
    movzx esi,dx
    and dx,0F000h
    or edx,edx
    jnz write_thread_segment_normal
;
    mov dx,flat_sel
    movzx esi,si
    add esi,page0_linear
    call validate_thread_selector
    jc write_thread_selector_done
    jmp write_thread_segment_retry

write_thread_segment_normal:
    push cx
    xor cx,cx
    and si,0FFFh
    GetThreadPageEntry
    pop cx
;
    test al,1
    jnz write_thread_segment_do
;    
    AllocatePhysical64
    or al,7
    SetThreadPageEntry

write_thread_segment_do:
    push eax
    mov eax,1000h
    AllocateLocalLinear
    pop eax
;
    SetPageEntry 
;    
    mov es:[edx+esi],cl
;
    xor eax,eax
    xor ebx,ebx
    SetPageEntry    
;    
    mov ecx,1000h
    FreeLinear
    clc
;
    pop bp    
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    retf32
write_thread_segment    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           READ_THREAD64
;
;           DESCRIPTION:    Read byte from another thread
;
;           PARAMETERS:     DX:ESI          Offset in thread
;                           BX              Thread
;
;           RETURNS:        NC              Valid
;                               AL          Value
;                           CY              Invalid
;                               AL          Error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_thread64_name       DB 'Read Thread64',0

read_thread64    PROC far
    push es
    push ebx
    push ecx
    push edx
    push esi
    push bp
;
    mov ax,flat_sel
    mov es,ax
;
    mov bp,bx
    mov cx,dx
    mov edx,esi
    and esi,0FFFh
    GetThreadPageEntry
;
    test al,1
    jnz read_thread64_ok
;    
    stc
    mov al,'%'
    jmp read_thread64_done

read_thread64_ok:
    push eax
    mov eax,1000h
    AllocateLocalLinear
    pop eax
    SetPageEntry
;
    mov al,es:[edx+esi]
;
    push eax
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
    pop eax
;    
    mov ecx,1000h
    FreeLinear
    clc
    
read_thread64_done:
    pop bp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    retf32
read_thread64    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WRITE_THREAD64
;
;           DESCRIPTION:    Write byte to another thread
;
;           PARAMETERS:     DX:EAX          Offset in thread
;                           BX              Thread
;                           AL              Value to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_thread64_name      DB 'Write Thread64',0

write_thread64   PROC far
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push bp
;
    push ax
    mov ax,flat_sel
    mov es,ax
;
    mov bp,bx
    mov cx,dx
    mov edx,esi
    and esi,0FFFh
    GetThreadPageEntry
;
    test al,1
    jnz write_thread64_do
;
    AllocatePhysical64
    or al,7
    SetThreadPageEntry

write_thread64_do:
    pop cx
;    
    push eax
    mov eax,1000h
    AllocateLocalLinear
    pop eax
;
    SetPageEntry
;
    mov es:[edx+esi],cl
;
    xor eax,eax
    xor ebx,ebx
    SetPageEntry    
;
    mov ecx,1000h
    FreeLinear
    clc
    
write_thread64_done:
    pop bp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    retf32
write_thread64   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitProcessMem
;
;           DESCRIPTION:    Initialize per-process memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_mem_name  DB 'Init Process Mem', 0

init_process_mem   Proc far
    push ds
    push es
    pushad
;
    mov ax,local_mem_sel
    mov ds,ax
    call GetAllocFlatSize
    sub eax,local_page_linear
    mov ds:local_big_avail_mem,eax
    mov ds:local_big_used_mem,0
    mov ds:local_big_base,local_page_linear
    InitSection ds:local_mem_section
    InitSection ds:vm_mem_section
;
    mov edx,vm_linear
    xor eax,eax
    xor ebx,ebx
    mov cx,0Fh

init_vm_linear_loop:
    SetPageEntry
    add edx,1000h
    loop init_vm_linear_loop
;
    mov ax,vm_linear_sel
    mov ds,ax
    xor bx,bx
    mov dx,8
    mov [bx].vmf_next,dx
    mov [bx].vms_next,dx
    mov [bx].vms_prev,dx
    mov bx,dx
    mov dx,0EFF8h
    mov [bx].vmf_prev,0
    mov [bx].vmf_next,0
    mov [bx].vms_prev,0
    mov [bx].vms_next,dx
;
    mov ax,local_mem_sel
    mov ds,ax
    mov ds:vm_avail_mem,dx
    mov ds:vm_used_mem,0

ipmDone:
    popad
    pop es
    pop ds
    retf32
init_process_mem   Endp

code    ENDS

.186

END

