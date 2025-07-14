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
INCLUDE exec.def

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
    extrn cow_dir_proc:word
    extrn cow_page_proc:word

    extrn get_serv_page_dir_proc:word
    extrn set_serv_page_dir_proc:word
    extrn create_serv_page_dir_proc:word
    
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
    cmp edi,fixed_process_linear
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
;           NAME:           page_fault_global_page
;
;           DESCRIPTION:    pagefault in global page memory
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_global_page       PROC near
    mov ax,[ebp].trap_eflags
    and ax,NOT 4500h
    push ax
    mov edx,cr2
    popf
;    
    call cs:get_page_entry_proc
    test al,1
    jnz page_fault_global_page_retry
;
    cmp eax,4
    je page_fault_error
;
    call local_allocate_physical
    mov al,07h
    call cs:set_page_entry_proc

page_fault_global_page_retry:
    ret
page_fault_global_page       ENDP


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
    and eax,0FF800000h
    cmp eax,process_page_linear
    je process_dir_fault
;
    cmp eax,sys_page_linear
    je page_fault_sys_page
;
    mov eax,cr2
    and eax,0FFC00000h
;
    cmp eax,system_mem_start
    jc page_fault_error2
;
    cmp eax,handle_linear
    je page_fault_error2
;    
    cmp eax,global_page_linear
    jc page_fault_global    
;
    cmp eax,kernel_linear
    jnc page_fault_global
;
    cmp eax,fixed_process_linear
    je page_fault_process
;
    cmp eax,phys_bitmap_linear
    jc page_fault_global_page
    jmp page_fault_system

page_fault_sys_page:
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

page_fault_process:
    mov edx,cr2
    call local_allocate_physical
    mov al,7    
    jmp cs:set_page_entry_proc

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
;
    push es
    push ecx
    push edx
    push edi
;
    mov edx,cr2
    cmp edx,sys_page_linear
    jae ptKernel
;
    cmp edx,process_page_linear
    jb ptUser
;
    push edx
    call cs:fault_to_dir_proc
    mov eax,edx
    pop edx
;
    cmp eax,sys_page_linear
    jae ptKernel
;
    cmp eax,serv_linear
    jae ptUser
;
    sti
    GetThread
    mov ds,ax
    jmp ptNotServ

ptUser:
    sti
    GetThread
    mov ds,ax
    mov bx,ds:p_serv_sel
    or bx,bx
    jz ptNotServ
;
    mov es,ax
    cmp edx,serv_linear
    jb ptNotServ
;
    cmp edx,flat_size
    jb ptServPage
;
    cmp edx,process_page_linear
    jc ptNotServ

ptServDir:
    call cs:fault_to_dir_proc
    call cs:get_serv_page_dir_proc
    test al,1
    jnz ptServDirSet
;
    call cs:create_serv_page_dir_proc
    call cs:get_serv_page_dir_proc

ptServDirSet:
    call cs:set_page_dir_proc
    jmp ptRetry

ptServPage:
    call cs:get_page_dir_proc
    test al,1
    jnz ptServDirOk
;
    call cs:get_serv_page_dir_proc
    test al,1
    jnz ptHasServ
;
    call cs:create_serv_page_dir_proc
    call cs:get_serv_page_dir_proc

ptHasServ:
    call cs:set_page_dir_proc

ptServDirOk:
    cmp edx,serv_byte_linear
    jae ptServSmall

ptServBig:
    call cs:get_page_entry_proc
    cmp eax,2
    jne ptFault
    jmp ptServAlloc

ptServSmall:
    call cs:get_page_entry_proc
    cmp eax,4
    je ptFault

ptServAlloc:
    call local_allocate_physical
    mov al,07h
    call cs:set_page_entry_proc
    jmp ptRetry

ptNotServ:
    mov ds,ds:p_prog_sel
    cmp ax,ds:pr_cow_thread
    jne ptSection
;
    inc ds:pr_cow_counter
    jmp ptEnter

ptSection:
    EnterSection ds:pr_cow_section
    mov ds:pr_cow_counter,0
    mov ds:pr_cow_thread,ax

ptEnter:
    cmp edx,process_page_linear
    jb ptNotDir
;
    call cs:get_page_entry_proc
    test al,1
    jz ptNoDir
;
    test ax,400h
    jz ptUserDone
;
    call cs:fault_to_dir_proc
    call cs:cow_dir_proc
    mov eax,cr3
    mov cr3,eax
    jmp ptUserDone

ptNoDir:
    call cs:fault_to_dir_proc
    call cs:create_page_dir_proc
    jmp ptUserDone

ptNotDir:
    call cs:get_page_dir_proc 
    test al,1
    jnz ptUserDirValid
;
    call cs:create_page_dir_proc
    jmp ptUserDone
    
ptUserDirValid:
    test ax,400h
    jz ptUserCheckPage
;
    call cs:cow_dir_proc
    mov eax,cr3
    mov cr3,eax
    jmp ptUserDone

ptUserCheckPage:
    call cs:get_page_entry_proc
;    
    test al,1
    jz ptUserNotPresent
;
    test ax,400h
    jz ptUserPossibleFault
;
    call cs:cow_page_proc
    mov eax,cr3
    mov cr3,eax
    jmp ptUserDone

ptUserNotPresent:
    test al,2
    jnz ptUserReserved
;
    cmp edx,local_page_linear
    jae ptUserPossibleFault
;
    cmp edx,fixed_vm_linear
    jb ptUserPossibleFault
;
    jmp ptNormal

ptUserReserved:
    and al,7
    cmp al,6
    jne ptNormal
;
    test ah,80h
    jz ptLoader
;
    int 3

ptLoader:
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ax,ds:pr_cow_counter
    or ax,ax
    pop ax
    jz ptLoaderLeave
;
    CrashGate

ptLoaderLeave:
    mov ds:pr_cow_thread,0
    mov ds:pr_cow_counter,0
    LeaveSection ds:pr_cow_section
;
    shr eax,16
    mov es,ax
;
    mov eax,cs
    push eax
;
    mov eax,OFFSET ptLoaderCheck
    push eax
;
    mov eax,es:loader_pagefault_proc+4
    push eax
;
    mov eax,es:loader_pagefault_proc
    push eax
    retf32

ptNormal:
    call local_allocate_physical
    mov al,7    
    call cs:set_page_entry_proc
    jmp ptUserDone

ptUserFlat:
    CrashGate

ptUserPossibleFault:
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    xor ax,ax
    cmp edx,ds:pr_fault_linear
    jne ptUserFaultRetry
;
    mov ax,ds:pr_fault_counter
    inc ax
    cmp ax,3
    jae ptUserFault

ptUserFaultRetry:
    mov ds:pr_fault_linear,edx
    mov ds:pr_fault_counter,ax
    mov eax,cr3
    mov cr3,eax
    jmp ptUserDone

ptUserFault:
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov ds:pr_cow_thread,0
    mov ds:pr_cow_counter,0
    LeaveSection ds:pr_cow_section
    jmp ptFault

ptUserDone:
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov bx,ds:pr_cow_counter
    or bx,bx
    jz ptLeave
;
    dec ds:pr_cow_counter
    jmp ptRetry

ptLeave:
    mov ds:pr_cow_thread,0
    LeaveSection ds:pr_cow_section
    jmp ptRetry

ptKernel:    
    mov eax,[ebp].trap_err
    test ax,1
    jnz ptFault
;
    call page_fault
    mov eax,cr3
    mov cr3,eax
    jmp ptRetry

ptLoaderCheck:
    jnc ptRetry

ptFault:
    pop edi
    pop edx
    pop ecx
    pop es
;    
    mov eax,[ebp].trap_eflags
    test eax,20000h
    jnz ptVm
;
    call prot_exception
    jmp ptRet

ptVm:
    call virt_exception
    jmp ptRet

ptRetry:
    pop edi
    pop edx
    pop ecx
    pop es

ptRet:
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
    push eax
    GetFlatSize
    cmp edx,eax
    pop eax
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
    push eax
    GetFlatSize
    cmp edx,eax
    pop eax
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
    push eax
    GetFlatSize
    cmp edx,eax
    pop eax
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
    push eax
    GetFlatSize
    cmp edx,eax
    pop eax
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
