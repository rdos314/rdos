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

    extrn local_create_data_sel16:near
    extrn local_create_int_gate_sel:near

    extrn local_allocate_physical:near
    extrn local_free_physical:near
    extrn AllocateRam:near
    extrn prot_exception:near
    extrn virt_exception:near

    extrn local_flush_process_tlb:near

    extrn get_page_entry_proc:word
    extrn set_page_entry_proc:word
    
code    SEGMENT byte public 'CODE'

.386p

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_flat_dir
;
;           DESCRIPTION:    Setup flat (identity) mapped page-tables
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_flat_dir   Proc near
    push ds
    push eax
    push bx
    push cx
    push edx
;
    mov bx,sys_dir_sel
    mov ecx,1000h
    mov edx,cr3
    and dx,0F000h
    call local_create_data_sel16
;
    mov ds,bx
    xor eax,eax
    mov cx,400h
    xor bx,bx
init_empty_dir:
    mov [bx],eax
    add bx,4
    loop init_empty_dir
;
    pop edx
    pop cx
    pop bx
    pop eax
    pop ds
    ret
init_flat_dir   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_dir
;
;           DESCRIPTION:    Map dir selectors
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_dir Proc near
    mov ax,sys_dir_sel
    mov ds,ax
    mov eax,cr3
    mov bx,(sys_page_linear SHR 20) AND 0FFFh
    mov al,3
    mov [bx],eax
    mov bx,(process_page_linear SHR 20) AND 0FFFh
    mov [bx],eax
    ret
map_dir Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_flat
;
;           DESCRIPTION:    Map a page flat
;
;           PARAMETERS:         EDX             Linear base address
;                           ECX             Number of bytes to map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_flat    Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz map_flat_done

map_flat_more:
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,22
    shl bx,2
    mov edi,[bx]
    or edi,edi
    jnz map_flat_do
;
    call AllocateRam
    mov edi,esi
    or si,3
    mov [bx],esi
;
    mov ax,flat_sel
    mov ds,ax
    push cx
    mov cx,400h
    xor eax,eax
map_flat_init_loop:
    mov [edi],eax
    add edi,4
    loop map_flat_init_loop
    sub edi,1000h
    pop cx

map_flat_do:
    mov ax,flat_sel
    mov ds,ax
    mov ebx,edx
    shr ebx,12
    and ebx,3FFh
    mov eax,400h
    shr ecx,12
    sub eax,ebx
    sub ecx,eax
    jnc map_flat_start
;
    add ecx,eax
    mov eax,ecx
    xor ecx,ecx

map_flat_start:
    shl bx,2
    shl ecx,12
    push ecx
    mov cx,ax
    and dx,0F000h
    or dx,803h
    and di,0F000h
    or di,bx

map_flat_loop:
    mov [edi],edx
    add edi,4
    add edx,1000h
    loop map_flat_loop
    pop ecx
    or ecx,ecx
    jnz map_flat_more

map_flat_done:
    popad
    pop ds
    ret
map_flat    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_flat_user
;
;           DESCRIPTION:    Map a page flat, user access
;
;           PARAMETERS:         EDX             Linear base address
;                           ECX             Number of bytes to map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_flat_user   Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz map_flat_user_done

map_flat_user_more:
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,22
    shl bx,2
    mov edi,[bx]
    or edi,edi
    jnz map_flat_user_do
;
    call AllocateRam
    mov edi,esi
    or si,7
    mov [bx],esi
;
    mov ax,flat_sel
    mov ds,ax
    push cx
    mov cx,400h
    xor eax,eax
map_flat_user_init_loop:
    mov [edi],eax
    add edi,4
    loop map_flat_user_init_loop
    sub edi,1000h
    pop cx

map_flat_user_do:
    mov ax,flat_sel
    mov ds,ax
    mov ebx,edx
    shr ebx,12
    and ebx,3FFh
    mov eax,400h
    shr ecx,12
    sub eax,ebx
    sub ecx,eax
    jnc map_flat_user_start
;
    add ecx,eax
    mov eax,ecx
    xor ecx,ecx

map_flat_user_start:
    shl bx,2
    shl ecx,12
    push ecx
    mov cx,ax
    and dx,0F000h
    or dx,807h
    and di,0F000h
    or di,bx

map_flat_user_loop:
    mov [edi],edx
    add edi,4
    add edx,1000h
    loop map_flat_user_loop
    pop ecx
    or ecx,ecx
    jnz map_flat_user_more

map_flat_user_done:
    popad
    pop ds
    ret
map_flat_user   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_paging
;
;           DESCRIPTION:    Create initial paging for system process
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_paging

init_paging     PROC near
    mov ax,system_data_sel
    mov es,ax
;
    call init_flat_dir
    call map_dir
;
    xor edx,edx
    mov ecx,es:alloc_base
    add ecx,1000h
    call map_flat
;
    mov edx,es:rom1_base
    mov ecx,es:rom1_size
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    call map_flat
;
    mov edx,es:rom2_base
    mov ecx,es:rom2_size
    or ecx,ecx
    jz init_paging_ram
;
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    call map_flat

init_paging_ram:
    mov ecx,es:ram2_size
    or ecx,ecx
    jz init_paging_done
;
    mov edx,0A0000h
    mov ecx,100000h
    sub ecx,edx
    call map_flat_user
    
init_paging_done:
    ret
init_paging     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_paging
;
;           DESCRIPTION:    Start paging hardware
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public start_paging

start_paging    Proc near
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test ax,2000h
    jz start_paging_global_done
;    
;    db 0Fh
;    db 20h
;    db 0E0h     ; mov eax,cr4
;
;    or ax,80h   ; enable global pages
;
;    db 0Fh
;    db 22h
;    db 0E0h     ; mov cr4,eax

start_paging_global_done:
    mov bx,sys_dir_sel
    mov ecx,1000h
    mov edx,sys_page_linear
    shr edx,10
    add edx,sys_page_linear
    call local_create_data_sel16
;
    mov bx,sys_page_sel
    mov edx,sys_page_linear
    mov ecx,400000h
    call local_create_data_sel16
;
    mov bx,process_dir_sel
    mov ecx,1000h
    mov edx,process_page_linear
    shr edx,10
    add edx,process_page_linear
    call local_create_data_sel16
;
    mov bx,process_page_sel
    mov edx,process_page_linear
    mov ecx,400000h
    call local_create_data_sel16
    ret
start_paging    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           sys_dir_fault_user
;
;           DESCRIPTION:    Pagefault in user system page directory
;
;           PARAMETERS:         EAX         page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sys_dir_fault_user      Proc near
    push eax
    mov bx,sys_dir_sel
    mov ds,bx
    shr eax,20
    and ax,0FFCh
    mov bx,ax
    call local_allocate_physical
    mov al,7
    mov [bx],eax    
    pop eax
;
    shr eax,10
    and ax,0F000h
    mov bx,sys_page_sel
    mov ds,bx
    mov cx,400h
    xor ebx,ebx
sys_dir_fault_user_init:
    mov [eax],ebx
    add eax,4
    loop sys_dir_fault_user_init
    ret
sys_dir_fault_user      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           sys_dir_fault_system
;
;           DESCRIPTION:    Pagefault in system system page directory
;
;           PARAMETERS:         EAX         page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sys_dir_fault_system    Proc near
    push eax
    mov bx,sys_dir_sel
    mov ds,bx
    shr eax,20
    and ax,0FFCh
    mov bx,ax
    call local_allocate_physical
    mov al,3
    mov [bx],eax    
    pop eax
;
    shr eax,10
    and ax,0F000h
    mov bx,sys_page_sel
    mov ds,bx
    mov cx,400h
    xor ebx,ebx
sys_dir_fault_system_init:
    mov [eax],ebx
    add eax,4
    loop sys_dir_fault_system_init
    ret
sys_dir_fault_system    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           sys_dir_fault
;
;           DESCRIPTION:    Pagefault in system page directory
;
;           PARAMETERS:         EAX         page fault address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sys_dir_fault   Proc near
    sub eax,sys_page_linear
    shl eax,10
    cmp eax,system_mem_start
    jb page_fault_error2
    jmp sys_dir_fault_system
sys_dir_fault   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           process_dir_fault_move
;
;           DESCRIPTION:    Pagefault in user process page directory
;
;           PARAMETERS:         EAX         page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_dir_fault_move  Proc near
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,eax
    shr ebx,20
    and bx,0FFCh
    mov ecx,[bx]
    test cl,1
    jnz sys_dir_valid
    push bx
    cli
    mov eax,edx
    add eax,sys_page_linear
    call sys_dir_fault
    pop bx
    mov ax,sys_dir_sel
    mov ds,ax
    mov ecx,[bx]
sys_dir_valid:
    mov ax,process_dir_sel
    mov ds,ax
    mov [bx],ecx
    ret
process_dir_fault_move  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           process_dir_fault_local
;
;           DESCRIPTION:    Pagefault in local process page directory
;
;           PARAMETERS:         EAX         page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_dir_fault_local Proc near
    push eax
    mov bx,process_dir_sel
    mov ds,bx
    shr eax,20
    and ax,0FFCh
    mov bx,ax
    call local_allocate_physical
    mov al,7
    mov [bx],eax    
    pop eax
;
    shr eax,10
    and ax,0F000h
    mov bx,process_page_sel
    mov ds,bx
    mov cx,400h
    xor ebx,ebx
process_dir_fault_local_init:
    mov [eax],ebx
    add eax,4
    loop process_dir_fault_local_init
    ret
process_dir_fault_local Endp


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
    mov eax,cr2
    popf
;
    sub eax,process_page_linear
    mov edx,eax
    shl eax,10
;
    mov edi,eax
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
;
    jmp process_dir_fault_move
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
    mov eax,cr2
    popf
;    
    push eax
    push edx
    mov edx,eax
    call cs:get_page_entry_proc
    mov ecx,eax
    pop edx
    pop eax
;    
    test cl,1
    jnz page_fault_user_retry
;
    test cl,2
    jnz page_fault_user_valid
;
    cmp eax,local_page_linear
    jae page_fault_user_flat
;
    cmp eax,fixed_vm_linear
    jae page_fault_user_valid
;    
    push ds
    push bx
    mov bx,system_data_sel
    mov ds,bx
    cmp eax,ds:flat_base
    pop bx
    pop ds 
    jb page_fault_user_valid
    jmp page_fault_user_invalid

page_fault_user_flat:
    cmp eax,flat_size
    jb page_fault_user_invalid

page_fault_user_valid:
    and cl,7
    cmp cl,6
    jne page_fault_user_normal
;
    test ch,80h
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
    push edx
;    
    mov edx,eax
    call cs:get_page_entry_proc
;
    push cs
    push OFFSET page_fault_user_hook_end
    and ax,0FFF8h
    push ax
    shr eax,16
    push ax
    retf
    
page_fault_user_hook_end:
    pop edx
    jmp page_fault_user_retry

page_fault_user_invalid:
    jmp page_fault_error

page_fault_user_normal:
    push edx
    mov edx,eax
    call local_allocate_physical
    mov al,7    
    call cs:set_page_entry_proc
    pop edx

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
    mov eax,cr2
    popf

    mov bx,process_page_sel
    mov ds,bx
    mov ebx,eax
    shr ebx,10
    and bx,0FFFCh
    mov al,[ebx]
    test al,1
    jnz page_fault_global_retry
;
    push eax
    call local_allocate_physical
    or ax,107h
    mov [ebx],eax
    pop eax

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
    mov eax,cr2
    popf

    mov bx,process_page_sel
    mov ds,bx
    mov ebx,eax
    shr ebx,10
    and bx,0FFFCh
    mov al,[ebx]
    test al,1
    jnz page_fault_system_retry
;
    push eax
    call local_allocate_physical
    mov al,07h
    mov [ebx],eax
    pop eax

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
    mov eax,cr2
    popf
    jmp sys_dir_fault

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
    push bx
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
    mov bx,process_page_sel
    mov ds,bx
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,10
    shr ecx,12
    push cx

set_inv_mark:
    mov eax,[edx]
    test al,1
    jz set_inv_free
;
    push ax
    call local_free_physical
    pop ax
    not al
    and al,2
    shl al,4
    or al,4
    movzx eax,al
    mov [edx],eax
    jmp set_inv_next

set_inv_free:   
    and al,6
    jz set_inv_next
;
    cmp al,6
    je set_inv_next
;
    mov eax,[edx]
    and al,NOT 6
    or al,4
    mov [edx],eax

set_inv_next:
    add edx,4
    loop set_inv_mark
;
    pop cx
    pop edx
    call local_flush_process_tlb
    
set_inv_done:    
    pop edx
    pop ecx
    pop bx
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
    push bx
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
    mov bx,process_page_sel
    mov ds,bx
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,10
    shr ecx,12
    push cx

set_readwrite_mark:
    mov eax,[edx]
    test al,1
    jnz set_readwrite_allocated
    and al,6
    jz set_readwrite_next
;
    cmp al,6
    je set_readwrite_next
;
    and byte ptr [edx],NOT 20h
    jmp set_readwrite_next

set_readwrite_allocated:
    or al,2
    mov [edx],al

set_readwrite_next:
    add edx,4
    loop set_readwrite_mark
;
    pop cx
    pop edx
    call local_flush_process_tlb

set_readwrite_done:
    pop edx
    pop ecx
    pop bx
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
    push bx
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
    mov bx,process_page_sel
    mov ds,bx
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,10
    shr ecx,12

set_read_mark:
    mov eax,[edx]
    test al,1
    jnz set_read_allocated
;
    and al,6
    jz set_read_mark_next
;
    cmp al,6
    je set_read_mark_next
;
    or byte ptr [edx],20h
    jmp set_read_mark_next

set_read_allocated:
    and al,NOT 2
    mov [edx],al

set_read_mark_next:
    add edx,4
    loop set_read_mark

set_read_done:
    pop edx
    pop ecx
    pop bx
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
