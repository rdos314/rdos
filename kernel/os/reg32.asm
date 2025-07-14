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
; reg32.ASM
; reg32 handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE port.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE core.inc
include ..\debug\kdebug.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte use16 public 'CODE'
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CrashGateInt
;
;           DESCRIPTION:    Crash with a gate (from interrupt)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crash_gate_int:
    cli
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    push ds
    push es
    push fs
    push gs
;
    StartCoreDump
    jc cgiFail
;
    mov ds:[ebp].fault_vect,1Ah
;
    sldt bx
    mov ds:[ebp].reg_ldt.d_selector,bx
;    
    str bx
    mov ds:[ebp].reg_tr.d_selector,bx
;
    pop bx
    mov ds:[ebp].reg_gs.d_selector,bx
;
    pop bx
    mov ds:[ebp].reg_fs.d_selector,bx
;
    pop bx
    mov ds:[ebp].reg_es.d_selector,bx
;
    pop bx
    mov ds:[ebp].reg_ds.d_selector,bx
;
    pop eax
    mov ds:[ebp].reg_ebp,eax
;    
    pop eax
    mov ds:[ebp].reg_edi,eax
;    
    pop eax
    mov ds:[ebp].reg_esi,eax
;    
    pop eax
    mov ds:[ebp].reg_edx,eax
;    
    pop eax
    mov ds:[ebp].reg_ecx,eax
;    
    pop eax
    mov ds:[ebp].reg_ebx,eax
;    
    pop eax
    mov ds:[ebp].reg_eax,eax
;    
    pop eax
    mov ds:[ebp].reg_eip,eax
;
    pop ebx
    mov ds:[ebp].reg_cs.d_selector,bx
;
    pop eax
    mov ds:[ebp].reg_eflags,eax
;    
    mov bx,ss
    mov ds:[ebp].reg_ss.d_selector,bx
;            
    mov ds:[ebp].reg_esp,esp
    NotifyCoreDump

cgiFail:
    jmp cgiFail

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NmiInt
;
;           DESCRIPTION:    Crash from NMI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi_int:
    cli
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    push ds
    push es
    push fs
    push gs
;
    cli
    StartCoreDump
    jc nmi_ret
;
    mov ds:[ebp].fault_vect,19h
;
    sldt bx
    mov ds:[ebp].reg_ldt.d_selector,bx
;    
    str bx
    mov ds:[ebp].reg_tr.d_selector,bx
;
    pop bx
    mov ds:[ebp].reg_gs.d_selector,bx
;
    pop bx
    mov ds:[ebp].reg_fs.d_selector,bx
;
    pop bx
    mov ds:[ebp].reg_es.d_selector,bx
;
    pop bx
    mov ds:[ebp].reg_ds.d_selector,bx
;
    pop eax
    mov ds:[ebp].reg_ebp,eax
;    
    pop eax
    mov ds:[ebp].reg_edi,eax
;    
    pop eax
    mov ds:[ebp].reg_esi,eax
;    
    pop eax
    mov ds:[ebp].reg_edx,eax
;    
    pop eax
    mov ds:[ebp].reg_ecx,eax
;    
    pop eax
    mov ds:[ebp].reg_ebx,eax
;    
    pop eax
    mov ds:[ebp].reg_eax,eax
;    
    pop eax
    mov ds:[ebp].reg_eip,eax
;
    pop ebx
    mov ds:[ebp].reg_cs.d_selector,bx
;
    pop eax
    mov ds:[ebp].reg_eflags,eax
;    
    mov bx,ss
    mov ds:[ebp].reg_ss.d_selector,bx
;            
    mov ds:[ebp].reg_esp,esp
    NotifyCoreDump

nmi_ret:    
    pop gs
    pop fs
    pop es
    pop ds
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupNmiCoreDump
;
;           DESCRIPTION:    Setup NMI core dump
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_nmi_core_dump_name    DB 'Setup NMI Core Dump', 0

setup_nmi_core_dump Proc far
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov al,2
    xor bl,bl
    mov esi,OFFSET nmi_int
    SetupIntGate
;
    popad
    pop es
    pop ds    
    retf32
setup_nmi_core_dump Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoubleFault
;
;           DESCRIPTION:    Handle double fault exception (from task-gate)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
double_fault:
    pushf
    pop ax
    and ax,NOT 4000h
    push ax
    popf
;       
    mov ax,gdt_sel
    mov ds,ax
    mov bx,double_tss_sel
    and byte ptr ds:[bx+5],NOT 2
;    
    TryLockTask
    jc double_fault_lock_ok

double_crash:
    cli
    mov ax,double_tss_data_sel
    mov ds,ax
    mov bx,word ptr ds:tss32_back_link
    push bx
;
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    inc ecx
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
;       
    AllocateGdt
    CreateDataSelector16
    mov es,bx
;    
    StartCoreDump
    jc ctFail
;    
    mov ds:[ebp].fault_vect,8
;
    sldt bx
    mov ds:[ebp].reg_ldt.d_selector,bx
;    
    str bx
    mov ds:[ebp].reg_tr.d_selector,bx
;
    mov eax,es:tss32_eax
    mov ds:[ebp].reg_eax,eax
;    
    mov eax,es:tss32_ecx
    mov ds:[ebp].reg_ecx,eax
;
    mov eax,es:tss32_edx
    mov ds:[ebp].reg_edx,eax
;
    mov eax,es:tss32_ebx
    mov ds:[ebp].reg_ebx,eax
;
    mov eax,es:tss32_esp    
    mov ds:[ebp].reg_esp,eax
;
    mov eax,es:tss32_ebp    
    mov ds:[ebp].reg_ebp,eax
;
    mov eax,es:tss32_eip    
    mov ds:[ebp].reg_eip,eax
;    
    mov eax,es:tss32_esi
    mov ds:[ebp].reg_esi,eax
;
    mov eax,es:tss32_edi    
    mov ds:[ebp].reg_edi,eax
;    
    mov bx,es:tss32_es
    mov ds:[ebp].reg_es.d_selector,bx
;
    mov bx,es:tss32_cs    
    mov ds:[ebp].reg_cs.d_selector,bx
     
    mov bx,es:tss32_ss
    mov ds:[ebp].reg_ss.d_selector,bx
;
    mov bx,es:tss32_ds    
    mov ds:[ebp].reg_ds.d_selector,bx
;
    mov bx,es:tss32_fs    
    mov ds:[ebp].reg_fs.d_selector,bx
;
    mov bx,es:tss32_gs    
    mov ds:[ebp].reg_gs.d_selector,bx
;
    mov eax,es:tss32_eflags
    mov ds:[ebp].reg_eflags,eax
    NotifyCoreDump

ctFail:
    jmp ctFail
    
double_fault_lock_ok:    
    mov ax,fs:cs_curr_thread
    or ax,ax
    jz double_crash
;
    cmp ax,fs:cs_null_thread
    je double_crash
;
    mov es,ax    
    mov es:p_fault_vector,8
    mov dword ptr es:p_fault_code,0
    mov dword ptr es:p_fault_code+4,0
;    
    mov ax,double_tss_data_sel
    mov ds,ax
    mov bx,word ptr ds:tss32_back_link
;
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    inc ecx
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
;       
    AllocateGdt
    CreateDataSelector16
    mov ds,bx
;
    mov eax,ds:tss32_eflags
    mov dword ptr es:p_rflags,eax
;
    mov eax,ds:tss32_eax
    mov dword ptr es:p_rax,eax
;
    mov eax,ds:tss32_ebx
    mov dword ptr es:p_rbx,eax
;
    mov eax,ds:tss32_ecx
    mov dword ptr es:p_rcx,eax
;
    mov eax,ds:tss32_edx
    mov dword ptr es:p_rdx,eax
;
    mov eax,ds:tss32_esi
    mov dword ptr es:p_rsi,eax
;
    mov eax,ds:tss32_edi
    mov dword ptr es:p_rdi,eax
;
    mov eax,ds:tss32_ebp
    mov dword ptr es:p_rbp,eax
;
    mov eax,ds:tss32_esp
    mov dword ptr es:p_rsp,eax
;
    mov eax,ds:tss32_eip
    mov dword ptr es:p_rip,eax
;    
    mov ax,ds:tss32_es
    mov es:p_es,ax
;
    mov ax,ds:tss32_cs    
    mov es:p_cs,ax
;    
    mov ax,ds:tss32_ss
    mov es:p_ss,ax
;
    mov ax,ds:tss32_ds    
    mov es:p_ds,ax
;
    mov ax,ds:tss32_fs    
    mov es:p_fs,ax
;
    mov ax,ds:tss32_gs    
    mov es:p_gs,ax    
;
    xor ax,ax
    mov ds,ax
    FreeGdt
;        
    DebugBlock

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugException / LockedDebugException
;
;           DESCRIPTION:    Save current state from stack + local registers
;
;       PARAMETERS:     SS:EBP       Exception stack
;                       AL      Fault vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_exception_name            DB 'Debug Exception', 0
locked_debug_exception_name     DB 'Locked Debug Exception', 0

locked_debug_exception:
    movzx ax,al
    push fs
    push ax
    mov ax,core_data_sel
    mov fs,ax
    mov fs,fs:cs_sel
    pop ax
    jmp debug_normal

debug_exception:
    movzx ax,al
    push fs
    TryLockTask
    jc debug_normal

debug_fault:
    mov ebx,ebp
    StartCoreDump
    jc debug_dump_fail
;    
    mov ds:[ebp].fault_vect,al
;
    mov ax,ss:[ebx].trap_pds
    mov ds:[ebp].reg_ds.d_selector,ax
;
    mov eax,ss:[ebx].trap_ebx
    mov ds:[ebp].reg_ebx,eax
;
    mov eax,ss:[ebx].trap_eax
    mov ds:[ebp].reg_eax,eax
;
    mov eax,ss:[ebx].trap_ebp
    mov ds:[ebp].reg_ebp,eax
;
    mov eax,ss:[ebx].trap_err
    mov ds:[ebp].fault_error,eax     
;
    mov eax,ss:[ebx].trap_eflags
    mov ds:[ebp].reg_eflags,eax
;
    mov eax,ss:[ebx].trap_eip
    mov ds:[ebp].reg_eip,eax
;
    mov ax,ss:[ebx].trap_cs
    mov ds:[ebp].reg_cs.d_selector,ax
;
    test ax,3
    jz debug_fault_kernel
;
    mov eax,ss:[ebx].trap_esp
    mov ds:[ebp].reg_esp,eax
;
    mov ax,ss:[ebx].trap_ss
    mov ds:[ebp].reg_ss.d_selector,ax
    jmp debug_fault_stack_ok

debug_fault_kernel:
    lea eax,[ebx].trap_esp
    mov ds:[ebp].reg_esp,eax
;
    mov ax,ss
    mov ds:[ebp].reg_ss.d_selector,ax

debug_fault_stack_ok: 
    sldt bx
    mov ds:[ebp].reg_ldt.d_selector,bx
;    
    str bx
    mov ds:[ebp].reg_tr.d_selector,bx
;    
    mov ds:[ebp].reg_ecx,ecx
    mov ds:[ebp].reg_edx,edx
    mov ds:[ebp].reg_esi,esi
    mov ds:[ebp].reg_edi,edi
;    
    mov ds:[ebp].reg_es.d_selector,es
    mov ds:[ebp].reg_fs.d_selector,fs
    mov ds:[ebp].reg_gs.d_selector,gs
    NotifyCoreDump

debug_dump_fail:
    jmp debug_dump_fail
   
debug_normal:       
    push ax
    mov ax,fs:cs_curr_thread 
    or ax,ax
    pop ax
    jz debug_fault
;    
    push ax
    mov ax,fs:cs_curr_thread
    cmp ax,fs:cs_null_thread
    pop ax
    je debug_fault
;
    mov ds,fs:cs_curr_thread 
    mov al,[ebp].trap_exc_nr
    mov ds:p_fault_vector,al
    mov eax,[ebp].trap_err
    mov dword ptr ds:p_fault_code,eax
    mov dword ptr ds:p_fault_code+4,0
;
    mov eax,[ebp].trap_eax
    mov dword ptr ds:p_rax,eax
    mov eax,[ebp].trap_ebx
    mov dword ptr ds:p_rbx,eax
    mov dword ptr ds:p_rcx,ecx
    mov dword ptr ds:p_rdx,edx
    mov dword ptr ds:p_rsi,esi
    mov dword ptr ds:p_rdi,edi
    mov eax,[ebp].trap_ebp
    mov dword ptr ds:p_rbp,eax
;       
    mov eax,[ebp].trap_eflags
    mov dword ptr ds:p_rflags,eax
    mov ax,[ebp].trap_cs
    mov ds:p_cs,ax
    mov eax,[ebp].trap_eip
    mov dword ptr ds:p_rip,eax
;       
    pop si
    test dword ptr [ebp].trap_eflags,20000h
    jnz debug_vm

debug_pm:
    mov al,[ebp].trap_cs
    test al,3
    jz debug_kernel
;
    mov ax,[ebp].trap_ss
    mov ds:p_ss,ax
    mov eax,[ebp].trap_esp
    mov dword ptr ds:p_rsp,eax
    jmp debug_pm_common
    
debug_kernel:
    mov ax,ss
    mov ds:p_ss,ax
    mov eax,ebp
    add eax,trap_esp
    mov dword ptr ds:p_rsp,eax
    
debug_pm_common:
    mov ax,[ebp].trap_pds
    mov ds:p_ds,ax
    mov ax,es
    mov ds:p_es,ax
    mov ds:p_fs,si
    mov ax,gs
    mov ds:p_gs,ax
    jmp debug_save_ok

debug_vm:
    mov ax,[ebp].trap_gs
    mov ds:p_gs,ax
    mov ax,[ebp].trap_fs
    mov ds:p_fs,ax
    mov ax,[ebp].trap_ds
    mov ds:p_ds,ax
    mov ax,[ebp].trap_es
    mov ds:p_es,ax
    mov ax,[ebp].trap_ss
    mov ds:p_ss,ax
    mov eax,[ebp].trap_esp
    mov dword ptr ds:p_rsp,eax

debug_save_ok:
    DebugBlock

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetThreadTss
;
;           DESCRIPTION:    Get thread TSS
;
;           PARAMETERS:         ES:(E)DI        Buffer for TSS
;                           BX                  Thread handle
;                           NC                  Thread exists
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_tss_name DB 'Get Thread TSS',0

get_thread_tss  Proc near
    push ds
    push eax
    push dx
    push si
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    stc
    jz get_thread_tss_done
;
    mov dx,ax

get_thread_tss_loop:
    mov ds,ax
    cmp bx,ds:p_id
    je get_thread_tss_found
;
    mov ax,ds:p_next
    cmp ax,dx
    jne get_thread_tss_loop
    stc
    jmp get_thread_tss_done

get_thread_tss_found:
    fnop
    push ecx
    push esi
    push edi
    mov ds,ax
;
    mov eax,ds:p_cr3
    mov es:[edi].ut_cr3,eax
;    
    mov eax,dword ptr ds:p_rip
    mov es:[edi].ut_eip,eax
;    
    mov eax,dword ptr ds:p_rflags
    mov es:[edi].ut_eflags,eax
;    
    mov eax,dword ptr ds:p_rax
    mov es:[edi].ut_eax,eax
;    
    mov eax,dword ptr ds:p_rcx
    mov es:[edi].ut_ecx,eax
;    
    mov eax,dword ptr ds:p_rdx
    mov es:[edi].ut_edx,eax
;    
    mov eax,dword ptr ds:p_rbx
    mov es:[edi].ut_ebx,eax
;    
    mov eax,dword ptr ds:p_rsp
    mov es:[edi].ut_esp,eax
;    
    mov eax,dword ptr ds:p_rbp
    mov es:[edi].ut_ebp,eax
;    
    mov eax,dword ptr ds:p_rsi
    mov es:[edi].ut_esi,eax
;    
    mov eax,dword ptr ds:p_rdi
    mov es:[edi].ut_edi,eax
;    
    mov ax,ds:p_es
    mov es:[edi].ut_es,ax
;    
    mov ax,ds:p_cs
    mov es:[edi].ut_cs,ax
;    
    mov ax,ds:p_ss
    mov es:[edi].ut_ss,ax
;    
    mov ax,ds:p_ds
    mov es:[edi].ut_ds,ax
;    
    mov ax,ds:p_fs
    mov es:[edi].ut_fs,ax
;    
    mov ax,ds:p_gs
    mov es:[edi].ut_gs,ax
;    
    mov ax,ds:p_ldt
    mov es:[edi].ut_ldt,ax
;    
    mov eax,dword ptr ds:p_dr0
    mov es:[edi].ut_dr0,eax
;    
    mov eax,dword ptr ds:p_dr1
    mov es:[edi].ut_dr1,eax
;    
    mov eax,dword ptr ds:p_dr2
    mov es:[edi].ut_dr2,eax
;    
    mov eax,dword ptr ds:p_dr3
    mov es:[edi].ut_dr3,eax
;    
    mov eax,dword ptr ds:p_dr7
    mov es:[edi].ut_dr7,eax
;    
    mov eax,dword ptr ds:p_math_control
    mov es:[edi].ut_math_control,eax
;    
    mov eax,dword ptr ds:p_math_status
    mov es:[edi].ut_math_status,eax
;    
    mov eax,dword ptr ds:p_math_tag
    mov es:[edi].ut_math_tag,eax
;    
    mov eax,ds:p_math_eip
    mov es:[edi].ut_math_eip,eax
;    
    mov ax,ds:p_math_cs
    mov es:[edi].ut_math_cs,ax
;    
    mov eax,ds:p_math_data_offs
    mov es:[edi].ut_math_data_offs,eax
;    
    mov ax,ds:p_math_data_sel
    mov es:[edi].ut_math_data_sel,ax
;
    mov esi,OFFSET p_math_st0
    add edi,OFFSET ut_st0
;        
    mov eax,cr0
    test al,4
    jz get_thread_real_fpu

get_thread_emul_fpu:
    mov ax,ds:p_math_status
    shr ax,3
    mov al,ah
    and ax,7
    add ax,ax
    mov si,ax
    shl ax,2
    add si,ax
    add si,OFFSET p_math_st0
    shr ax,3
    mov dx,8

get_thread_emul_loop:
    mov ecx,10
    rep movs byte ptr es:[edi],ds:[esi]
;
    inc al
    cmp al,8
    jne get_thread_emul_next
;
    xor al,al
    mov si,OFFSET p_math_st0

get_thread_emul_next:
    sub dx,1
    jnz get_thread_emul_loop   
    jmp get_thread_fpu_done

get_thread_real_fpu:
    mov ecx,2 * 10
    rep movs dword ptr es:[edi],ds:[esi]

get_thread_fpu_done:
    pop edi
    pop esi
    pop ecx
    clc

get_thread_tss_done:
    pop si
    pop dx
    pop eax
    pop ds
    ret
get_thread_tss  Endp

get_thread_tss16    Proc far
    push edi
    movzx edi,di
    call get_thread_tss
    pop edi
    retf32
get_thread_tss16    Endp

get_thread_tss32    Proc far
    call get_thread_tss
    retf32
get_thread_tss32    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetThreadTss
;
;           DESCRIPTION:    Set thread TSS
;
;           PARAMETERS:         ES:(E)DI        Buffer for TSS
;                           BX                  Thread handle
;                           NC                  Thread exists
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_thread_tss_name DB 'Set Thread TSS',0

set_thread_tss  Proc near
    push ds
    push eax
    push dx
    push si
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    stc
    jz set_thread_tss_done
;
    mov dx,ax

set_thread_tss_loop:
    mov ds,ax
    cmp bx,ds:p_id
    je set_thread_tss_found
;
    mov ax,ds:p_next
    cmp ax,dx
    jne set_thread_tss_loop
    stc
    jmp set_thread_tss_done

set_thread_tss_found:
    push ds
    push es
    push ecx
    push esi
    push edi
;
    mov cx,es
    mov ds,cx
    mov es,ax
    mov esi,edi
;
    mov eax,ds:[esi].ut_cr3
    mov es:p_cr3,eax
;    
    mov eax,ds:[esi].ut_eip
    mov dword ptr es:p_rip,eax
;    
    mov eax,ds:[esi].ut_eflags
    mov dword ptr es:p_rflags,eax
;    
    mov eax,ds:[esi].ut_eax
    mov dword ptr es:p_rax,eax
;    
    mov eax,ds:[esi].ut_ecx
    mov dword ptr es:p_rcx,eax
;    
    mov eax,ds:[esi].ut_edx
    mov dword ptr es:p_rdx,eax
;    
    mov eax,ds:[esi].ut_ebx
    mov dword ptr es:p_rbx,eax
;    
    mov eax,ds:[esi].ut_esp
    mov dword ptr es:p_rsp,eax
;    
    mov eax,ds:[esi].ut_ebp
    mov dword ptr es:p_rbp,eax
;    
    mov eax,ds:[esi].ut_esi
    mov dword ptr es:p_rsi,eax
;    
    mov eax,ds:[esi].ut_edi
    mov dword ptr es:p_rdi,eax
;    
    mov ax,ds:[esi].ut_es
    mov es:p_es,ax
;    
    mov ax,ds:[esi].ut_cs
    mov es:p_cs,ax
;    
    mov ax,ds:[esi].ut_ss
    mov es:p_ss,ax
;    
    mov ax,ds:[esi].ut_ds
    mov es:p_ds,ax
;    
    mov ax,ds:[esi].ut_fs
    mov es:p_fs,ax
;    
    mov ax,ds:[esi].ut_gs
    mov es:p_gs,ax
;    
    mov ax,ds:[esi].ut_ldt
    mov es:p_ldt,ax
;    
    mov eax,ds:[esi].ut_dr0
    mov dword ptr es:p_dr0,eax
    mov dword ptr es:p_dr0+4,0
;    
    mov eax,ds:[esi].ut_dr1
    mov dword ptr es:p_dr1,eax
    mov dword ptr es:p_dr1+4,0
;    
    mov eax,ds:[esi].ut_dr2
    mov dword ptr es:p_dr2,eax
    mov dword ptr es:p_dr2+4,0
;    
    mov eax,ds:[esi].ut_dr3
    mov dword ptr es:p_dr3,eax
    mov dword ptr es:p_dr3+4,0
;    
    mov eax,ds:[esi].ut_dr7
    mov dword ptr es:p_dr7,eax
;    
    mov eax,ds:[esi].ut_math_control
    mov dword ptr es:p_math_control,eax
;    
    mov eax,ds:[esi].ut_math_status
    mov dword ptr es:p_math_status,eax
;    
    mov eax,ds:[esi].ut_math_tag
    mov dword ptr es:p_math_tag,eax
;    
    mov eax,ds:[esi].ut_math_eip
    mov es:p_math_eip,eax
;    
    mov ax,ds:[esi].ut_math_cs
    mov es:p_math_cs,ax
;    
    mov eax,ds:[esi].ut_math_data_offs
    mov es:p_math_data_offs,eax
;    
    mov ax,ds:[esi].ut_math_data_sel
    mov es:p_math_data_sel,ax
;
    add esi,OFFSET ut_st0
    mov edi,OFFSET p_math_st0
;
    mov eax,cr0
    test al,4
    jz set_thread_real_fpu

set_thread_emul_fpu:
    mov ax,es:p_math_status
    shr ax,3
    mov al,ah
    and ax,7
    add ax,ax
    mov di,ax
    shl ax,2
    add di,ax
    add di,OFFSET p_math_st0
    shr ax,3
    mov dx,8

set_thread_emul_loop:
    mov ecx,10
    rep movs byte ptr es:[edi],ds:[esi]
;
    inc al
    cmp al,8
    jne set_thread_emul_next
;
    xor al,al
    mov di,OFFSET p_math_st0

set_thread_emul_next:
    sub dx,1
    jnz set_thread_emul_loop   
    jmp set_thread_fpu_done

set_thread_real_fpu:
    mov ecx,2 * 10
    rep movs dword ptr es:[edi],ds:[esi]

set_thread_fpu_done:
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    clc

set_thread_tss_done:
    pop si
    pop dx
    pop eax
    pop ds
    ret
set_thread_tss  Endp

set_thread_tss16    Proc far
    push edi
    movzx edi,di
    call set_thread_tss
    pop edi
    retf32
set_thread_tss16    Endp

set_thread_tss32    Proc far
    call set_thread_tss
    retf32
set_thread_tss32    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_double_fault
;
;           DESCRIPTION:    Init double fault handler
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_double_fault
    
init_double_fault       Proc near
    push ds
    push es
    pushad
;    
    mov eax,400h
    AllocateSmallLinear
;
    mov bx,double_tss_sel
    mov ecx,400h
    CreateTssSelector
;
    mov bx,double_tss_data_sel
    mov ecx,400h
    CreateDataSelector16
    mov ds,bx
    mov es,bx
;    
    xor di,di
    mov cx,100h
    xor eax,eax
    rep stosd
;
    mov eax,200h
    AllocateSmallGlobalMem
    mov ds:tss32_ss,es
    mov ds:tss32_esp,200h
    mov eax,cr3
    mov ds:tss32_cr3,eax
;
    mov ds:tss32_bitmap, OFFSET tss32_bitmap_space
    mov bx,3FFh
    mov byte ptr ds:[bx],-1    
;
    mov ds:tss32_cs,cs
    mov ds:tss32_eip,OFFSET double_fault
;
    mov ax,idt_sel
    mov ds,ax
    mov bx,8 * 8
    mov word ptr [bx],0
    mov word ptr [bx+2],double_tss_sel
    mov byte ptr [bx+4],0
    mov byte ptr [bx+5],85h
    mov word ptr [bx+6],0    
;
    popad
    pop es
    pop ds
        ret
init_double_fault       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_REG32
;
;           DESCRIPTION:    Init reg32
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_reg32

init_reg32       PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    xor bl,bl
    mov al,84h
    mov esi,OFFSET crash_gate_int
    SetupIntGate
;    
    mov esi,OFFSET setup_nmi_core_dump
    mov edi,OFFSET setup_nmi_core_dump_name
    xor cl,cl
    mov ax,setup_nmi_core_dump_nr
    RegisterOsGate
;
    mov esi,OFFSET debug_exception
    mov edi,OFFSET debug_exception_name
    xor cl,cl
    mov ax,debug_exception_nr
    RegisterOsGate
;
    mov esi,OFFSET debug_exception
    mov edi,OFFSET debug_exception_name
    xor cl,cl
    mov ax,debug_exception_nr
    RegisterOsGate
;
    mov esi,OFFSET locked_debug_exception
    mov edi,OFFSET locked_debug_exception_name
    xor cl,cl
    mov ax,locked_debug_exception_nr
    RegisterOsGate
;
    mov ebx,OFFSET get_thread_tss16
    mov esi,OFFSET get_thread_tss32
    mov edi,OFFSET get_thread_tss_name
    mov dx,virt_es_in
    mov ax,get_thread_tss_nr
    RegisterUserGate
;
    mov ebx,OFFSET set_thread_tss16
    mov esi,OFFSET set_thread_tss32
    mov edi,OFFSET set_thread_tss_name
    mov dx,virt_es_in
    mov ax,set_thread_tss_nr
    RegisterUserGate
    ret
init_reg32       ENDP

code    ENDS

    END
