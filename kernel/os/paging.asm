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
; PAGING.ASM
; Paging & page fault handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc

    extrn local_create_int_gate_sel:near

    extrn local_allocate_physical:near
    extrn local_free_physical:near
    extrn prot_exception:near
    extrn virt_exception:near

    extrn get_page_entry_proc:word
    extrn set_page_entry_proc:word
    extrn get_page_dir_proc:word
    extrn fault_to_dir_proc:word
    extrn get_sys_page_dir_proc:word
    extrn set_page_dir_proc:word
    extrn set_sys_page_dir_proc:word
    extrn create_page_dir_proc:word
    extrn create_sys_page_dir_proc:word
    
code    SEGMENT byte public 'CODE'

.386p

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           process_dir_fault
;
;           DESCRIPTION:    Pagefault in process page directory
;
;           PARAMETERS:         EAX         page fault address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_dir_fault       Proc near
    mov ax,[ebp].trap_eflags
    and ax,NOT 4500h
    push ax
    mov edx,cr2
    popf
;
    call cs:fault_to_dir_proc
    mov edi,edx
    and edi,0FFC00000h
;
    cmp edi,system_mem_start
    jc process_dir_fault_local
;
    cmp edi,handle_linear
    je process_dir_fault_local
;
    cmp edi,io_local_linear
    je process_dir_fault_local

process_dir_fault_move:
    call cs:get_sys_page_dir_proc    
    test al,1
    jnz process_dir_fault_valid
;    
    cli
    cmp edx,system_mem_start
    jb page_fault_error2
;
    call cs:create_sys_page_dir_proc
    call cs:get_sys_page_dir_proc    

process_dir_fault_valid:
    jmp cs:set_page_dir_proc

process_dir_fault_local:
    jmp cs:create_page_dir_proc    

process_dir_fault       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_user
;
;           DESCRIPTION:    Pagefault in global memory
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pm_es   EQU -12
pm_ecx  EQU -16
pm_di   EQU -18

page_fault_user PROC near
    mov ax,[ebp].trap_eflags
    and ax,NOT 4500h
    push ax
    mov edx,cr2
    popf
;    
    call cs:get_page_entry_proc
;    
    test al,1
    jnz page_fault_user_retry
;
    test al,2
    jnz page_fault_user_valid
;
    cmp edx,local_page_linear
    jae page_fault_user_flat
;
    cmp edx,fixed_vm_linear
    jae page_fault_user_valid
;    
    push ds
    push bx
    mov bx,system_data_sel
    mov ds,bx
    cmp edx,ds:flat_base
    pop bx
    pop ds 
    jb page_fault_user_valid
    jmp page_fault_user_invalid

page_fault_user_flat:
    cmp edx,flat_size
    jb page_fault_user_invalid

page_fault_user_valid:
    and al,7
    cmp al,6
    jne page_fault_user_normal
;
    test ah,80h
    jz page_fault_em_normal
;
    mov ax,emulate_opcode_nr
    IsValidOsGate
    jc page_fault_user_invalid
;    
    pop ax
    pop edi
    pop edx
    pop ecx
    pop es
    push ax
    mov al,0Eh
    EmulateOpcode
    pop ax
    pop eax
    mov ds,ax
    pop ebx 
    pop eax
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
    add sp,4
    iretd

page_fault_em_normal:
    call cs:get_page_entry_proc
;
    push cs
    push OFFSET page_fault_user_retry
    and ax,0FFF8h
    push ax
    shr eax,16
    push ax
    retf

page_fault_user_invalid:
    jmp page_fault_error

page_fault_user_normal:
    call local_allocate_physical
    mov al,7    
    call cs:set_page_entry_proc

page_fault_user_retry:
    ret
page_fault_user ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_global
;
;           DESCRIPTION:    pagefault in global system memory
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_global       PROC near
    mov ax,[ebp].trap_eflags
    and ax,NOT 4500h
    push ax
    mov edx,cr2
    popf
;    
    call cs:get_page_entry_proc
    test al,1
    jnz page_fault_global_retry
;
    call local_allocate_physical
    or ax,107h
    call cs:set_page_entry_proc

page_fault_global_retry:
    ret
page_fault_global       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_system
;
;           DESCRIPTION:    pagefault in system memory
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_system       PROC near
    mov ax,[ebp].trap_eflags
    and ax,NOT 4500h
    push ax
    mov edx,cr2
    popf
;
    call cs:get_page_entry_proc
    test al,1
    jnz page_fault_system_retry
;
    call local_allocate_physical
    mov al,07h
    call cs:set_page_entry_proc

page_fault_system_retry:
    ret
page_fault_system       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           page_fault_kernel
;
;           DESCRIPTION:    pagefault in kernel memory
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault      Proc near
    mov eax,cr2
    and eax,0FFC00000h
;
    cmp eax,system_mem_start
    jc page_fault_user
;
    cmp eax,global_page_linear
    jc page_fault_global    
;
    cmp eax,kernel_linear
    jnc page_fault_global
;
    cmp eax,handle_linear
    je page_fault_user
;
    cmp eax,io_focus_linear
    je page_fault_user
;
    cmp eax,io_local_linear
    je page_fault_user
;
    cmp eax,process_page_linear
    je process_dir_fault
;
    cmp eax,sys_page_linear
    jne page_fault_system
;
    mov ax,[ebp].trap_eflags
    and ax,NOT 4500h
    push ax
    mov edx,cr2
    popf
    call cs:fault_to_dir_proc
;    
    cmp edx,system_mem_start
    jb page_fault_error2
;
    jmp cs:create_sys_page_dir_proc

page_fault      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           pagefault_error
;
;           DESCRIPTION:    pagefault error
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_error2:
    int 3
    pop ax
    mov eax,cr2
    pop edi
    pop edx
    pop ecx
    pop es
    pop eax
    mov ds,ax
    pop ebx
    pop eax
    pop ebp
    add sp,12
    DebugException

page_fault_error:
    pop ax
    mov eax,cr2
    sti
    pop edi
    pop edx
    pop ecx
    pop es
;    
    mov eax,[ebp].trap_eflags
    test eax,20000h
    jnz pgf_vm
;
    call prot_exception
    jmp pgf_ret

pgf_vm:
    call virt_exception

pgf_ret:    
    pop eax
    mov ds,ax
    pop ebx 
    pop eax
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
    add sp,4
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PAGEFAULT_TRAP
;
;           DESCRIPTION:    Pagefault handler
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pagefault_trap:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,14
    push ax
    push ds
    push es
    push ecx
    push edx
    push edi
;
    mov eax,[ebp].trap_err
    test ax,1
    jz trap_not_present
;
trap_error_do:
    call page_fault_error
    jmp trap_14_done

trap_not_present:
    call page_fault
    mov eax,cr3
    mov cr3,eax

trap_14_done:
    pop edi
    pop edx
    pop ecx
    pop es
    pop eax
    mov ds,ax
    pop ebx 
    pop eax
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeV86
;
;           DESCRIPTION:    Free adapter areas in V86 process (C0000-FFFFF)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_v86_name   DB 'Free V86',0

free_v86    PROC far
    push eax
    push ebx
    push ecx
    push edx
;       
    mov edx,0A0000h
    mov ecx,060000h SHR 12
    mov eax,2
    xor ebx,ebx

free_v86_loop:
    call cs:set_page_entry_proc
    add edx,1000h
    loop free_v86_loop
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    retf32
free_v86    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_FLAT_LINEAR_VALID
;
;           DESCRIPTION:    Set flat page to valid
;
;           PARAMETERS:     EAX         Size
;                           EDX         Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_flat_linear_valid_name      DB 'Set Flat Linear Valid',0

set_flat_linear_valid   PROC far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    or eax,eax
    jz set_valid_done
;
    mov bx,system_data_sel
    mov ds,bx
    add edx,ds:flat_base
    cmp edx,local_page_linear
    jc set_valid_done
;
    cmp edx,flat_size
    jae set_valid_done
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr ecx,12

set_valid_mark:
    call cs:get_page_entry_proc
    test al,1
    jnz set_valid_next
;
    and al,6
    jz set_valid_next
;
    cmp al,6
    je set_valid_next
;
    call cs:get_page_entry_proc
    and al,NOT 6
    or al,2
    call cs:set_page_entry_proc

set_valid_next:
    add edx,1000h
    loop set_valid_mark

set_valid_done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
set_flat_linear_valid   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_FLAT_LINEAR_INVALID
;
;           DESCRIPTION:    Set flat page to invalid
;
;           PARAMETERS:     EAX         Size
;                           EDX         Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_flat_linear_invalid_name    DB 'Set Flat Linear Invalid',0

set_flat_linear_invalid PROC far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    or eax,eax
    jz set_inv_done
;
    mov bx,system_data_sel
    mov ds,bx
    add edx,ds:flat_base
    cmp edx,local_page_linear
    jc set_inv_done
;
    cmp edx,flat_size
    jae set_inv_done
;
    push edx
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr ecx,12
    push cx

set_inv_mark:
    call cs:get_page_entry_proc
    test al,1
    jz set_inv_free
;
    push ax
    call local_free_physical
    pop ax
;
    not al
    and al,2
    shl al,4
    or al,4
    movzx eax,al
    xor ebx,ebx
    call cs:set_page_entry_proc
    jmp set_inv_next

set_inv_free:   
    and al,6
    jz set_inv_next
;
    cmp al,6
    je set_inv_next
;
    call cs:get_page_entry_proc
    and al,NOT 6
    or al,4
    call cs:set_page_entry_proc

set_inv_next:
    add edx,1000h
    loop set_inv_mark
;
    pop cx
    pop edx
    FlushTlb
    
set_inv_done:    
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
set_flat_linear_invalid ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_FLAT_LINEAR_READWRITE
;
;           DESCRIPTION:    Set flat page access to read/write
;
;           PARAMETERS:         EAX         Size
;                           EDX         Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_flat_linear_readwrite_name  DB 'Set Flat Linear Read/Write',0

set_flat_linear_readwrite       PROC far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    or eax,eax
    jz set_readwrite_done
;
    mov bx,system_data_sel
    mov ds,bx
    add edx,ds:flat_base
    cmp edx,local_page_linear
    jc set_readwrite_done
;
    cmp edx,flat_size
    jae set_readwrite_done
;
    push edx
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr ecx,12
    push cx

set_readwrite_mark:
    call cs:get_page_entry_proc
    test al,1
    jnz set_readwrite_allocated
    and al,6
    jz set_readwrite_next
;
    cmp al,6
    je set_readwrite_next
;
    call cs:get_page_entry_proc
    and al,NOT 20h
    call cs:set_page_entry_proc
    jmp set_readwrite_next

set_readwrite_allocated:
    or al,2
    call cs:set_page_entry_proc

set_readwrite_next:
    add edx,1000h
    loop set_readwrite_mark
;
    pop cx
    pop edx
    FlushTlb

set_readwrite_done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
set_flat_linear_readwrite       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_FLAT_LINEAR_READ
;
;           DESCRIPTION:    Set flat page access to read-only
;
;           PARAMETERS:         EAX         Size
;                           EDX         Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_flat_linear_read_name       DB 'Set Flat Linear Read',0

set_flat_linear_read    PROC far
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    or eax,eax
    jz set_read_done
;
    mov bx,system_data_sel
    mov ds,bx
    add edx,ds:flat_base
    cmp edx,local_page_linear
    jc set_read_done
;
    cmp edx,flat_size
    jae set_read_done
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr ecx,12

set_read_mark:
    call cs:get_page_entry_proc
    test al,1
    jnz set_read_allocated
;
    and al,6
    jz set_read_mark_next
;
    cmp al,6
    je set_read_mark_next
;
    call cs:get_page_entry_proc
    or al,20h
    call cs:set_page_entry_proc
    jmp set_read_mark_next

set_read_allocated:
    and al,NOT 2
    call cs:set_page_entry_proc

set_read_mark_next:
    add edx,1000h
    loop set_read_mark

set_read_done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    retf32
set_flat_linear_read    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_paging_gates
;
;           DESCRIPTION:    Init paging call-gates
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_paging_gates

init_paging_gates       PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov si,OFFSET free_v86
    mov di,OFFSET free_v86_name
    xor dx,dx
    mov ax,free_v86_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET set_flat_linear_invalid
    mov di,OFFSET set_flat_linear_invalid_name
    xor dx,dx
    mov ax,set_flat_linear_invalid_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET set_flat_linear_valid
    mov di,OFFSET set_flat_linear_valid_name
    xor dx,dx
    mov ax,set_flat_linear_valid_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET set_flat_linear_read
    mov di,OFFSET set_flat_linear_read_name
    xor dx,dx
    mov ax,set_flat_linear_read_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET set_flat_linear_readwrite
    mov di,OFFSET set_flat_linear_readwrite_name
    xor dx,dx
    mov ax,set_flat_linear_readwrite_nr
    RegisterBimodalUserGate
;
    ret
init_paging_gates       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_paging_trap
;
;           DESCRIPTION:    Setup page-fault handler
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_paging_trap

init_paging_trap    PROC near
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET pagefault_trap
    xor bl,bl
    mov al,14
    call local_create_int_gate_sel
    ret
init_paging_trap    ENDP
    
code    ENDS

    END
