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

code    SEGMENT byte public use16 'CODE'

    assume cs:code

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
    mov eax,flat_size
    AllocatePageEntries
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
    mov eax,flat_size
    AllocatePageEntries
    jnc allocate_debug_page_local_ok
;
    mov edx,local_page_linear + 1000h
    AllocatePageEntries
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
;
    dec eax
    and ax,0F000h
    add eax,1000h
    mov bx,local_mem_sel
    mov ds,bx
    EnterSection ds:local_mem_section
    cmp edx,local_page_linear
    jc reserve_local_linear_inv_range
    cmp edx,flat_size
    jae reserve_local_linear_inv_range
    mov ecx,eax
    add ecx,edx
    cmp ecx,local_page_linear
    jc reserve_local_linear_inv_range
    cmp ecx,flat_size
    jae reserve_local_linear_inv_range
;
    shr eax,12
    mov ecx,eax
    ReservePageEntries
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
;       
    mov bx,system_data_sel
    mov ds,bx
    mov esi,ds:flat_base
;
    mov bx,local_mem_sel
    mov ds,bx
    EnterSection ds:local_mem_section
;
    cmp edx,flat_size
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
    mov eax,flat_size
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
    FreePageEntries
    clc

resize_flat_leave:
    LeaveSection ds:local_mem_section

resize_flat_done:    
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
    mov ax,cs
    mov ds,ax
    mov es,ax
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
    popad
    pop es
    pop ds
    ret
init_app_mem    ENDP


code    ENDS

END

