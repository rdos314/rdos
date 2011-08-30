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
; KERNEL.ASM
; Kernel module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE protseg.def
INCLUDE system.def
INCLUDE port.def
INCLUDE ..\driver.def
INCLUDE ..\pcdev\apic.inc

MAJOR_VERSION = 9
MINOR_VERSION = 1
RELEASE = 8

IFDEF __WASM__
   .686p
ELSE
    .386p
ENDIF

    extrn local_get_selector_base_size:near
    extrn local_create_data_sel16:near
    extrn local_create_tss_sel:near

    extrn create_gdt:near
    extrn create_mem:near
    extrn init_pretask_traps:near

    extrn init_paging:near
    extrn start_paging:near
    extrn init_physical_dir:near
    extrn init_physical:near
    extrn init_paging_trap:near
    extrn init_physical_gates:near
    extrn init_os_protseg:near
    extrn init_user_protseg:near
    extrn init_paging_gates:near
    extrn init_mem:near
    extrn init_gdt:near
    extrn init_idt:near
    extrn init_ldt:near
    extrn init_state:near
    extrn init_task:near
    extrn init_thread:near
    extrn init_handle:near
    extrn init_mem_sels:near
    extrn init_osgate:near
    extrn init_usergate:near
    extrn init_int:near
    extrn init_app:near
    extrn init_trap_vectors:near
    extrn init_tss_int:near
    extrn move_adapters:near
    extrn init_device:near

    extrn init_first_process:near
    extrn init_first_thread:near
    
code    SEGMENT byte use16 public 'CODE'

    assume cs:code


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;           NAME:       Break for invalid returns
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    int 3

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Get version
;
;           DESCRIPTION:    Get RDOS version
;
;       RETURNS:    AX Minor version
;               DX Major version
;               CX Release #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_version_name    DB 'Get RDOS Version', 0

get_version Proc far
    mov dx,MAJOR_VERSION
    mov ax,MINOR_VERSION
    mov cx,RELEASE
    retf32
get_version Endp


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ZeroRam
;
;           DESCRIPTION:    zero ram content
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ZeroRam Proc near
    push ds
    push es
    push eax
    push edx
    push esi
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov es,ax
;
    xor eax,eax
    mov esi,es:alloc_base

ZeroRamLoop1:
    mov [esi],eax
ZeroRamNext1:
    add esi,1000h
    cmp esi,es:ram1_size
    jc ZeroRamLoop1
;
    mov esi,es:ram2_base
    mov ecx,es:ram2_size
    or ecx,ecx
    jz ZeroRamDone

ZeroRamLoop2:
    mov [esi],eax
ZeroRamNext2:
    add esi,1000h
    sub ecx,1000h
    jnz ZeroRamLoop2

ZeroRamDone:
    pop esi
    pop edx
    pop eax
    pop es
    pop ds
    ret
ZeroRam Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MarkupRam
;
;           DESCRIPTION:    mark up ram with boot signature
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MarkupRam       Proc near
    push ds
    push es
    push eax
    push edx
    push esi
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov es,ax
;
    mov esi,es:alloc_base

MarkupRamLoop1:
    mov eax,[esi]
    or eax,eax
    jnz MarkupRamNext1
    mov eax,BootMemSign
    mov [esi],eax
MarkupRamNext1:
    add esi,1000h
    cmp esi,es:ram1_size
    jc MarkupRamLoop1

    mov esi,es:ram2_base
    mov ecx,es:ram2_size
    or ecx,ecx
    jz MarkupRamDone

MarkupRamLoop2:
    mov eax,[esi]
    or eax,eax
    jnz MarkupRamNext2
    mov eax,BootMemSign
    mov [esi],eax
MarkupRamNext2:
    add esi,1000h
    sub ecx,1000h
    jnz MarkupRamLoop2

MarkupRamDone:
    pop esi
    pop edx
    pop eax
    pop es
    pop ds
    ret
MarkupRam       Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateRam
;
;           DESCRIPTION:    get free ram during startup
;
;           RETURNS:        NC      ESI         address to use
;                           CY              no more free ram
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateRam

AllocateRam     Proc near
    push ds
    push es
    push eax
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov es,ax
;
    mov esi,es:alloc_base
    cmp esi,es:ram1_size
    jb AllocRamNext1
;
    mov eax,es:ram2_size
    or eax,eax
    stc
    jz AllocRamDone
;
    cmp esi,es:ram2_base
    jae AllocRamNext2
;
    mov esi,es:ram2_base
    sub esi,1000h
    jmp AllocRamNext2

AllocRamLoop1:
    mov eax,[esi]
    cmp eax,BootMemSign
    jne AllocRamNext1
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je AllocRamFound
AllocRamNext1:
    add esi,1000h
    cmp esi,es:ram1_size
    jc AllocRamLoop1

    mov esi,es:ram2_base
    sub esi,1000h
    jmp AllocRamNext2

AllocRamLoop2:
    mov eax,[esi]
    cmp eax,BootMemSign
    jne AllocRamNext2
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je AllocRamFound
AllocRamNext2:
    add esi,1000h
    mov eax,es:ram2_base
    add eax,es:ram2_size
    cmp esi,eax
    jc AllocRamLoop2
    stc
    jmp AllocRamDone

AllocRamFound:
    mov es:alloc_base,esi
    clc

AllocRamDone:
    pop eax
    pop es
    pop ds
    ret
AllocateRam     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_PRE_TASKING
;
;           DESCRIPTION:    Init pretasking
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

virt_thread_name DB 'Pretasking              '

init_pre_tasking    PROC near
    call AllocateRam
    mov bx,virt_thread_sel
    mov ecx,1000h
    mov edx,esi
    call local_create_data_sel16
    mov es,bx
;
    call AllocateRam
    mov cr3,esi
    mov es:p_thread_sel,es
    mov es:p_cr3,esi
    mov ax,cs
    mov ds,ax
    mov si,OFFSET virt_thread_name
    mov di,OFFSET thread_name
    mov cx,32
    rep movsb
    ret
init_pre_tasking    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_BOOT_SYSTEM
;
;           DESCRIPTION:    Init system_data_sel
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_patch Proc near
    ret
dummy_patch Endp

init_boot_system    PROC near
    mov ax,system_data_sel
    mov ds,ax
    xor ax,ax
    mov ds:debug_list,ax
    mov ds:debug_thread,ax
    mov ds:flat_base,0
    mov ds:math_tss,ax
    mov ds:check_point,0
    mov ds:patch_spinlock,0
    mov ds:shut_spinlock,0
    mov ds:enter_patch_proc,OFFSET dummy_patch
    mov ds:leave_patch_proc,OFFSET dummy_patch
    ret
init_boot_system    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_SYSTEM
;
;           DESCRIPTION:    Move system_data_sel from boot area
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_system     Proc near
    push ds
    push es
    pusha
    mov bx,system_data_sel
    mov ds,bx
    mov cx,OFFSET system_size
    movzx eax,cx
    mov bx,temp_sel
    AllocateFixedSystemMem
    xor si,si
    xor di,di
    rep movsb
    mov si,bx
    mov di,system_data_sel
    mov ax,gdt_sel
    mov ds,ax
    mov es,ax
    movsd
    movsd   
    popa
    pop es
    pop ds
    ret
init_system     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_tsc
;
;           DESCRIPTION:    Init TSC (meassure frequency)
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_tics   MACRO
    mov al,0
    out TIMER_CONTROL,al
    jmp short $+2
    in al,TIMER0
    mov ah,al
    jmp short $+2
    in al,TIMER0
    xchg al,ah
        ENDM

init_tsc Proc near    
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test al,10h
    jz init_tsc_done    
;    
    xor cx,cx    

init_tsc_wait_start_high:
    read_tics    
    test ax,8000h
    jnz init_tsc_wait_start_high_ok
    loop init_tsc_wait_start_high    

init_tsc_wait_start_high_ok:
    xor cx,cx    

init_tsc_wait_start_low:
    read_tics    
    test ax,8000h
    jz init_tsc_wait_start_low_ok
    loop init_tsc_wait_start_low

init_tsc_wait_start_low_ok:    
    rdtsc
    mov esi,eax
    mov edi,edx
    xor cx,cx

init_tsc_wait_high:    
    read_tics
    test ax,8000h
    jnz init_tsc_wait_high_ok
    loop init_tsc_wait_high

init_tsc_wait_high_ok:
    xor cx,cx

init_tsc_wait_low:    
    read_tics
    test ax,8000h
    jz init_tsc_wait_low_ok
    loop init_tsc_wait_low

init_tsc_wait_low_ok:
    rdtsc
    sub eax,esi
    sbb edx,edi
;
    mov ecx,8000h
    div ecx
;    
    mov ds:tsc_tics,eax
    mov ds:tsc_rest,dx
;
    or eax,eax
    jnz init_tsc_done
;
    and ds:cpu_feature_flags, NOT 10h
    
init_tsc_done:
    ret
init_tsc Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setup_global_paging
;
;           DESCRIPTION:    Setup global paging
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_global_paging Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test ax,2000h
    jz setup_global_paging_done
;
    mov eax,cr4
    or al,80h
    mov cr4,eax

setup_global_paging_done:
    ret
setup_global_paging Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    Kernel startup procedure
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
    mov ax,flat_sel
    mov ds,ax
;
    mov ebx,40Eh
    mov bx,[bx]
    movzx ebx,bx
    shl ebx,4
;
    mov ax,system_data_sel
    mov ds,ax
;
    cmp ebx,80000h
    jb init_no_bda
;       
    mov eax,ds:ram1_size
    cmp eax,ebx
    jbe init_no_bda
;    
    mov ds:ram1_size,ebx

init_no_bda:   
    mov ds:cpu_type,3
    mov ds:cpu_vendor,0
    mov ds:cpu_feature_flags,0
    mov ds:max_cpuid,0
    mov ds:tsc_tics,0
    mov ds:tsc_rest,0
    mov ds:apic_tics,0
    mov ds:apic_rest,0
;
    pushfd
    pop eax
    mov ecx,eax
    xor eax,40000h
    push eax
    popfd
    pushfd
    pop eax
    xor eax,ecx
    jz init_cpu_ok
;
    mov ds:cpu_type,4
    mov eax,ecx
    xor eax,200000h
    push eax
    popfd
    pushfd
    pop eax
    xor eax,ecx
    je init_cpu_ok
;
    mov eax,0
    cpuid
    mov ds:cpu_vendor+12,0
    mov dword ptr ds:cpu_vendor,ebx   
    mov dword ptr ds:cpu_vendor+4,edx   
    mov dword ptr ds:cpu_vendor+8,ecx   
;
    mov eax,1
    cpuid
    mov ds:cpu_feature_flags,edx
    mov al,ah
    and al,0Fh
    mov ds:cpu_type,al       

init_cpu_ok:
    mov eax,ds:cpu_feature_flags
    test al,2
    jz init_cpu_vme_ok
;
    mov eax,cr4
    or al,1
    mov cr4,eax

init_cpu_vme_ok:
    mov eax,ds:cpu_feature_flags
    test al,1
    jz init_no_fpu

init_fpu:    
    mov eax,cr0
    and al,NOT 4    ; real FPU
    mov cr0,eax
    jmp init_cpu_done

init_no_fpu:
    mov eax,cr0
    or al,4     ; emulated FPU
    mov cr0,eax

init_cpu_done:
    call ZeroRam
    call MarkupRam
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,gdt_sel
    mov es,ax
;
    call AllocateRam
    mov bx,idt_sel
    mov word ptr es:[bx],7FFh
    mov es:[bx+2],esi
    lidt fword ptr es:[bx]
    mov ah,92h
    xchg ah,es:[bx+5]
    xor al,al
    mov es:[bx+6],ax
;
    call init_pretask_traps
;
    call AllocateRam
    mov edx,esi
    mov bx,kernel_stack
    mov ecx,800h
    call local_create_data_sel16
;
    add edx,800h
    mov bx,virt_tss
    mov ecx,400h
    call local_create_tss_sel
    ltr bx
;
    add edx,400h
    mov bx,kernel_tss
    mov ecx,400h
    call local_create_data_sel16
;
    mov ds,bx
    mov ds:c_tss_cs,cs
    mov dword ptr ds:c_tss_eip,OFFSET prot_init
    mov ds:c_tss_ss,kernel_stack
    mov ds:c_tss_esp,800h
    mov ds:c_tss_ds,0
    mov ds:c_tss_es,0
    mov ds:c_tss_fs,0
    mov ds:c_tss_gs,0
    mov ds:c_tss_ldt,0
    mov dword ptr ds:c_tss_eflags,0
    mov dword ptr ds:c_tss_back_link,0
    mov ds:c_tss_t,0
    mov ds:c_tss_bitmap,800h
    xor ax,ax
    mov ds,ax
    call local_create_tss_sel
;
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    lldt ax
;
    db 0EAh
    dw 0,kernel_tss

prot_init:
    cli
    call init_pre_tasking
    call init_boot_system
    call init_paging
    call init_physical_dir
    call start_paging
    call init_physical
    call init_paging_trap
    call create_mem
    call create_gdt
    call init_osgate
    call init_os_protseg
    call init_usergate
    call init_user_protseg
;        
    mov esi,OFFSET get_version
    mov edi,OFFSET get_version_name
    xor dx,dx
    mov ax,get_version_nr
    RegisterBimodalUserGate
;
    call init_mem
    call init_gdt
    call init_idt
    call init_system
    call init_physical_gates
    call move_adapters
    call setup_global_paging
;
    mov bx,cs
    call local_get_selector_base_size
    mov bx,kernel_patch_sel
    call local_create_data_sel16
;    
    call init_paging_gates
    call init_physical_gates
    call init_mem_sels
    call init_tsc
    call init_state
    call init_task
    call init_ldt
    call init_app
    call init_thread
    call init_handle
    call init_int
    call init_tss_int
    call init_trap_vectors
    call init_device    
;
    mov bx,system_data_sel
    mov ds,bx
    mov edx,ds:flat_base
    mov ecx,flat_size
    sub ecx,edx
    mov bx,flat_code_sel
    CreateCodeSelector32
;
    mov bx,flat_data_sel
    CreateDataSelector32
;
    call init_first_process
    jmp init_first_thread
    
code    ENDS

.186

    END init
