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
; KERNEL.ASM
; Kernel module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE protseg.def
INCLUDE system.def
INCLUDE port.def
INCLUDE ..\driver.def
INCLUDE ..\acpi\apic.inc
INCLUDE system.inc

IA32_PAT      = 277h

MAJOR_VERSION = 15
MINOR_VERSION = 0
RELEASE = 0

IFDEF __WASM__
   .686p
ELSE
    .386p
ENDIF

    extrn local_get_selector_base_size:near
    extrn local_create_data_sel16:near
    extrn local_create_tss_sel:near
    extrn init_double_fault:near

    extrn create_gdt:near
    extrn create_mem:near
    extrn init_pretask_traps:near

    extrn start_paging:near
    extrn init_physical:near
    extrn init_paging_trap:near
    extrn init_physical_gates:near
    extrn init_os_protseg:near
    extrn init_user_protseg:near
    extrn init_paging_gates:near
    extrn init_page_table:near
    extrn init_mem:near
    extrn init_gdt:near
    extrn init_idt:near
    extrn init_handle:near
    extrn init_mem_sels:near
    extrn init_osgate:near
    extrn init_serv_gate:near
    extrn init_usergate:near
    extrn init_int:near
    extrn init_trap_vectors:near
    extrn init_reg32:near
    extrn move_adapters:near
    extrn init_device:near
    extrn init_hooks:near
    
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
    add esi,1000h

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
    add esi,1000h

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
;           NAME:           AllocateMultipleRam
;
;           DESCRIPTION:    get free ram during startup
;
;           PARAMETERS:     ECX     Number of pages
;
;           RETURNS:        ESI     Address to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateMultipleRam

AllocateMultipleRam     Proc near
    push ds
    push eax
    push ecx
;
    mov ax,system_data_sel
    mov ds,ax
;
    mov esi,ds:alloc_base
    add esi,1000h
;
    dec ecx
    shl ecx,12
    add ecx,esi
    mov ds:alloc_base,ecx
;
    clc
    pop ecx
    pop eax
    pop ds
    ret
AllocateMultipleRam     Endp

    
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
    pushad
;
    mov bx,system_data_sel
    mov ds,bx
    mov ds:acpi_reset_method,-1
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
;
    mov bx,system_data_sel
    call local_get_selector_base_size
    mov eax,OFFSET core_init
    add edx,eax
    mov ecx,SIZE core_base_struc
    mov bx,core_data_sel
    call local_create_data_sel16
;
    popad
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
    mov ds:sys_tsc_tics,eax
    mov ds:sys_tsc_rest,dx
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
;           NAME:           move_efi_lfb
;
;           DESCRIPTION:    Move EFI lfb
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_efi_lfb Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov ds:fixed_lfb_phys,0
    mov ds:fixed_lfb_phys+4,0
;    
    mov edx,ds:efi_acpi
    or edx,ds:efi_acpi+4
    jnz move_efi_lfb_do
;
    mov ds:efi_lfb,0
    mov ds:efi_lfb+4,0
    mov ds:fixed_lfb_linear,0
    jmp move_efi_lfb_done        

move_efi_lfb_do:        
    mov edx,ds:efi_scan_size
    movzx eax,ds:efi_height
    mul edx
    shl eax,2
    AllocateBigLinear
;
    mov eax,ds:efi_lfb
    mov ebx,ds:efi_lfb+4
    mov al,0Bh
    mov ds:efi_lfb,edx
    mov ds:mon_fixed_lfb,edx
;
    mov ds:fixed_lfb_phys,eax
    mov ds:fixed_lfb_phys+4,ebx
    mov ds:fixed_lfb_linear,edx

move_efi_loop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    loop move_efi_loop

move_efi_lfb_done:
    mov ds:efi_fore_col,0FFFFFFh
    mov ds:efi_back_col,0
    ret
move_efi_lfb    ENDP


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
    xor eax,eax
    mov cx,100h
    xor bx,bx

init_vm_vect_loop:
    or eax,ds:[bx]
    add bx,4
    loop init_vm_vect_loop
;
    or eax,eax
    jz init_no_bda
;
    mov ebx,40Eh
    mov bx,[bx]
    movzx ebx,bx
    shl ebx,4
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:efi_acpi,0
    mov ds:efi_acpi+4,0
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
    mov ax,system_data_sel
    mov ds,ax
    mov ds:cpu_type,3
    mov ds:cpu_vendor,0
    mov ds:cpu_feature_flags,0
    mov ds:cpu_ext_feature_flags,0
    mov ds:max_cpuid,0
    mov ds:sys_tsc_tics,0
    mov ds:sys_tsc_rest,0
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
    mov ds:cpu_feature_flags,1
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
    mov ds:cpu_ext_flags,ecx
    shr eax,8
    mov cl,al
    and cl,0Fh
    shr eax,12
    and al,0Fh
    add al,cl
    mov ds:cpu_type,al       
;
    mov eax,80000000h    
    cpuid
    cmp eax,80000001h
    jb init_cpu_ok
;
    mov eax,80000001h
    cpuid
    mov ds:cpu_ext_feature_flags,edx

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
    mov eax,ds:cpu_feature_flags
    test eax,10000h
    jz init_pat_done
;
    mov ecx,IA32_PAT
    rdmsr
    and ah,NOT 7
    or ah,1
    wrmsr

init_pat_done:
    call ZeroRam
    call MarkupRam
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,gdt_sel
    mov es,ax
    mov ax,system_data_sel
    mov fs,ax
;
    mov cx,800h - 70h
    mov di,70h
    xor al,al
    rep stosb
;
    mov cx,18h
    mov di,40h    
    xor al,al
    rep stosb
;    
    mov eax,fs:efi_acpi
    or eax,fs:efi_acpi+4
    jnz init_cpu_text_mode_ok
;    
    mov edx,0B8000h
    mov bx,dosb800
    mov ecx,1000h
    call local_create_data_sel16

init_cpu_text_mode_ok:
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
    mov ds:tss32_cs,cs
    mov dword ptr ds:tss32_eip,OFFSET prot_init
    mov ds:tss32_ss,kernel_stack
    mov ds:tss32_esp,800h
    mov ds:tss32_ds,0
    mov ds:tss32_es,0
    mov ds:tss32_fs,0
    mov ds:tss32_gs,0
    mov ds:tss32_ldt,0
    mov dword ptr ds:tss32_eflags,0
    mov dword ptr ds:tss32_back_link,0
    mov ds:tss32_t,0
    mov ds:tss32_bitmap,800h
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
    mov ax,gdt_sel
    mov es,ax
;
    mov cx,800h
    mov di,800h
    xor al,al
    rep stosb
;
    call init_pre_tasking
    call init_boot_system
    call start_paging
    call init_paging_trap
    call init_physical
    call create_mem
    call create_gdt
    call init_osgate
    call init_serv_gate
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
    call init_page_table
    call init_paging_gates
    call init_physical_gates
    call move_efi_lfb        
    call init_mem_sels
    call init_tsc
    call init_hooks
    call init_handle
    call init_int
    call init_trap_vectors
    call init_reg32
    call init_device    
    call init_double_fault
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
    mov edx,serv_linear
    mov ecx,serv_size
    mov bx,serv_flat_sel
    CreateDataSelector32
;
    mov bx,system_data_sel
    mov ds,bx
    mov edx,ds:flat_base
    mov ecx,serv_linear
    sub ecx,edx
    mov bx,serv_code_sel
    CreateCodeSelector32
;
    mov bx,serv_data_sel
    CreateDataSelector32
;
    StartTasking
    int 3
    
code    ENDS

.186

    END init
