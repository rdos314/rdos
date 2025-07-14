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
; INT16.ASM
; 16-bit protected mode interrupt handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE int.def
INCLUDE exec.def

sim_ss      EQU 52
sim_psp     EQU 50
sim_cs      EQU 48
sim_ip      EQU 46
sim_type    EQU 44
sim_ds      EQU 42
sim_es      EQU 40
sim_fs      EQU 38
sim_gs      EQU 36
sim_flags       EQU 34
sim_eax     EQU 30
sim_ecx     EQU 26
sim_edx     EQU 22
sim_ebx     EQU 18
sim_esp     EQU 14
sim_ebp     EQU 10
sim_esi     EQU 6
sim_edi     EQU 2
sim_client      EQU 0

sim_int     EQU 0
sim_iret    EQU 1
sim_ret     EQU 2


    .386p

code    SEGMENT byte public use16 'CODE'

    extrn set_flags:near
    extrn get_flags:near
    extrn allocate_switch_stack:near

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_INT16
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pm_reflect0:
    ReflectPM16 0

pm_break_exc0:
    BreakException16 0

pm_default_exc0:
    DefaultException16 0

sim_int_end:
    SimVM16End

    public init_int16

init_int16      PROC near
    mov eax,4
    AllocateFixedVMLinear
    mov ax,flat_sel
    mov ds,ax
    mov eax,dword ptr cs:sim_int_end
    mov [edx],eax
    mov ax,int_data_sel
    mov ds,ax
    mov eax,edx
    shr eax,4
    mov ds:sim_int16_seg,ax
    and dx,0Fh
    mov ds:sim_int16_offs,dx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov esi,OFFSET hook_pm_int
    mov edi,OFFSET hook_pm_int_name
    xor cl,cl
    mov ax,hook_pm16_int_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_get_pm_int
    mov edi,OFFSET hook_get_pm_int_name
    xor cl,cl
    mov ax,hook_get_pm16_int_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_set_pm_int
    mov edi,OFFSET hook_set_pm_int_name
    xor cl,cl
    mov ax,hook_set_pm16_int_nr
    RegisterOsGate
;
    mov esi,OFFSET get_exception_vector
    mov edi,OFFSET get_exception_vector_name
    xor dx,dx
    mov ax,get_exception_nr
    RegisterUserGate16
;
    mov esi,OFFSET set_exception_vector
    mov edi,OFFSET set_exception_vector_name
    xor dx,dx
    mov ax,set_exception_nr
    RegisterUserGate16
;
    mov esi,OFFSET get_pm_int
    mov edi,OFFSET get_pm_int_name
    xor dx,dx
    mov ax,get_pm_int_nr
    RegisterUserGate16
;
    mov esi,OFFSET set_pm_int
    mov edi,OFFSET set_pm_int_name
    xor dx,dx
    mov ax,set_pm_int_nr
    RegisterUserGate16
;
    mov esi,OFFSET dpmi_int
    mov edi,OFFSET dpmi_int_name
    xor dx,dx
    mov ax,dpmi_int_nr
    RegisterUserGate16
;
    mov esi,OFFSET dpmi_call_int
    mov edi,OFFSET dpmi_call_int_name
    xor dx,dx
    mov ax,dpmi_call_int_nr
    RegisterUserGate16
;
    mov esi,OFFSET dpmi_call
    mov edi,OFFSET dpmi_call_name
    xor dx,dx
    mov ax,dpmi_call_nr
    RegisterUserGate16
;
    mov esi,OFFSET allocate_vm_callback
    mov edi,OFFSET allocate_vm_callback_name
    xor dx,dx
    mov ax,allocate_vm_callback_nr
    RegisterUserGate16
;
    mov esi,OFFSET free_vm_callback
    mov edi,OFFSET free_vm_callback_name
    xor dx,dx
    mov ax,free_vm_callback_nr
    RegisterUserGate16
;
; create default reflection
;
    mov eax,400h
    AllocateFixedVMLinear
    mov ecx,eax
    mov bx,callb_int16_sel
    CreateDataSelector16
;
    mov ax,int_data_sel
    mov ds,ax
    mov cx,100h
    mov bx,OFFSET get_pm16_int_handlers
    mov eax,OFFSET default_get_pm_int
init_get_pm_int_loop:
    mov [bx],eax
    mov [bx+4],cs
    add bx,8
    loop init_get_pm_int_loop
;
    mov ax,int_data_sel
    mov ds,ax
    mov cx,100h
    mov bx,OFFSET set_pm16_int_handlers
    mov eax,OFFSET default_set_pm_int
init_set_pm_int_loop:
    mov [bx],eax
    mov [bx+4],cs
    add bx,8
    loop init_set_pm_int_loop
;
    mov cx,100h
    mov ax,callb_int16_sel
    mov ds,ax
    xor bx,bx
    mov eax,dword ptr cs:pm_reflect0
init_reflect_loop:
    mov [bx],eax
    add bx,4
    add eax,1000000h
    loop init_reflect_loop
;
    mov bx,gdt_sel
    mov ds,bx
    mov bx,callb_int16_sel AND 0FFF8h
    mov byte ptr [bx+5],0FAh
;
    mov eax,100h
    AllocateFixedVMLinear
    mov ecx,eax
    mov bx,callb_exc16_sel
    CreateDataSelector16
;
    mov cx,20h
    mov ax,callb_exc16_sel
    mov ds,ax
    xor bx,bx
    mov eax,dword ptr cs:pm_break_exc0
    mov edx,dword ptr cs:pm_default_exc0
init_exc_loop:
    mov [bx],eax
    add bx,4
    mov [bx],edx
    add bx,4
    add eax,1000000h
    add edx,1000000h
    loop init_exc_loop
;
    mov bx,gdt_sel
    mov ds,bx
    mov bx,callb_exc16_sel AND 0FFF8h
    mov byte ptr [bx+5],0FAh
;
; create vm callback ret
;
    mov ax,gdt_sel
    mov ds,ax
    mov es,ax
    mov bx,callb_vm16_sel
    and bl,0F8h
    mov di,bx
    xor si,si
    mov si,cs
    movsd
    movsd
    mov edx,[bx+2]
    add edx,OFFSET vm_callback_begin
    mov [bx+2],edx
    mov al,[bx+5]
    or al,60h
    mov [bx+5],al
    mov ax,OFFSET vm_callback_end - vm_callback_begin
    dec ax
    mov [bx],ax
;
    ret
init_int16      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           setup_idt16
;
;           DESCRIPTION:    Setup a default 16-bit IDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public setup_idt16

setup_idt16     PROC near
    push ds
    push ax
    push bx
    push cx
    push edx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    mov bx,OFFSET pr_pm_int
    mov cx,100h
    xor edx,edx

setup_int_loop:
    mov [bx],edx
    add bx,4
    mov word ptr [bx],callb_int16_sel
    add bx,4
    add dx,4
    loop setup_int_loop
;
    mov bx,OFFSET pr_pm_exc
    mov cx,20h
    mov edx,4

setup_pm_exception_loop:
    mov [bx],edx
    add bx,4
    mov word ptr [bx],callb_exc16_sel
    add bx,4
    add dx,8
    loop setup_pm_exception_loop
;
    pop edx
    pop cx
    pop bx
    pop ax
    pop ds
    ret
setup_idt16     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_PM_INT
;
;           DESCRIPTION:    Add default protected mode interrupt handler
;
;           PARAMETERS:         AL          Int #
;                       DS:EDI   Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_pm_int_name    DB 'Hook Prot16 Int',0

hook_pm_int     PROC far
    push ds
    push es
    push bx
    mov bx,int_data_sel
    mov es,bx
    movzx bx,al
    shl bx,3
    mov es:[bx].pm16_int_handlers,edi
    mov es:[bx+4].pm16_int_handlers,ds
    pop bx
    pop es
    pop ds
    retf32
hook_pm_int     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_EXCEPTION_VECTOR
;
;           DESCRIPTION:    Get exception vector
;
;           PARAMETERS:         AL          Exception #
;
;           RETURNS:        ES:DI   Selector:offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exception_vector_name       DB 'Get Exception Vector',0

get_exception_vector    PROC far
    push ds
    push bx
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    pop ax
    movzx bx,al
    shl bx,3
    mov di,word ptr ds:[bx].pr_pm_exc
    mov es,word ptr ds:[bx+4].pr_pm_exc
    pop bx
    pop ds
    retf32
get_exception_vector    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_EXCEPTION_VECTOR
;
;           DESCRIPTION:    Set exception vector
;
;           PARAMETERS:         AL          Exception #
;                           ES:DI   Selector:offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_exception_vector_name       DB 'Set Exception Vector',0

set_exception_vector    PROC far
    push ds
    push bx
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    pop ax
    movzx bx,al
    shl bx,3
    mov word ptr ds:[bx].pr_pm_exc,di
    mov word ptr ds:[bx+4].pr_pm_exc,es
    pop bx
    pop ds
    retf32
set_exception_vector    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEFAULT_GET_PM_INT
;
;           DESCRIPTION:    Default get interrpt vector
;
;           PARAMETERS:         AL          Int #
;
;           RETURNS:        ES:DI   Selector:offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_get_pm_int      PROC far
    push ds
    push bx
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    pop ax
    movzx bx,al
    shl bx,3
    mov di,word ptr ds:[bx].pr_pm_int
    mov es,word ptr ds:[bx+4].pr_pm_int
    pop bx
    pop ds
    retf32
default_get_pm_int      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEFAULT_SET_PM_INT
;
;           DESCRIPTION:    Default set interrupt vector
;
;           PARAMETERS:         AL          Int #
;                           ES:DI   Selector:offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_set_pm_int      PROC far
    push ds
    push bx
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    pop ax
    movzx bx,al
    shl bx,3
    mov word ptr ds:[bx].pr_pm_int,di
    mov word ptr ds:[bx+4].pr_pm_int,es
    pop bx
    pop ds
    retf32
default_set_pm_int      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_PM_INT
;
;           DESCRIPTION:    Get interrupt vector
;
;           PARAMETERS:         AL              Int #
;
;           RETURNS:        ES:DI       Selector:offset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pm_int_name DB 'Get Prot Int',0

get_pm_int      PROC far
    push ds
    push si
    mov si,int_data_sel
    mov ds,si
    movzx si,al
    shl si,3
    call fword ptr ds:[si].get_pm16_int_handlers
    pop si
    pop ds
    retf32
get_pm_int      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_PM_INT
;
;           DESCRIPTION:    Set interrupt vector
;
;           PARAMETERS:         AL              Int #
;                           ES:DI       Selector:offset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_pm_int_name DB 'Set Prot Int',0

set_pm_int      PROC far
    push ds
    push si
    mov si,int_data_sel
    mov ds,si
    movzx si,al
    shl si,3
    call fword ptr ds:[si].set_pm16_int_handlers
    pop si
    pop ds
    retf32
set_pm_int      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_GET_PM_INT
;
;           DESCRIPTION:    Add GetPmInt hook
;
;           PARAMETERS:     ES:EDI       Callback
;                           AL              Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_get_pm_int_name    DB 'Hook Get Prot16 Int',0

hook_get_pm_int PROC far
    push ds
    push si
    mov si,int_data_sel
    mov ds,si
    movzx si,al
    shl si,3
    mov ds:[si].get_pm16_int_handlers,edi
    mov ds:[si+4].get_pm16_int_handlers,es
    pop si
    pop ds
    retf32
hook_get_pm_int ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_SET_PM_INT
;
;           DESCRIPTION:    Add SetPmInt hook
;
;           PARAMETERS:     ES:EDI       Callback
;                           AL              Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_set_pm_int_name    DB 'Hook Set Prot16 Int',0

hook_set_pm_int PROC far
    push ds
    push si
    mov si,int_data_sel
    mov ds,si
    movzx si,al
    shl si,3
    mov ds:[si].set_pm16_int_handlers,edi
    mov ds:[si+4].set_pm16_int_handlers,es
    pop si
    pop ds
    retf32
hook_set_pm_int ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SIM16_END
;
;           DESCRIPTION:    End V86 mode reflection
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public sim16_end

sim16_end       PROC far
    GetThread
    mov ds,ax
    mov es,ax
    mov ds,ds:p_int_locked_stack
    xor bx,bx
    mov bx,[bx]
    movzx eax,word ptr [bx].sim_edi
    mov ds,[bx].sim_es
    mov [eax].vcs_ecx,ecx
    mov [eax].vcs_edx,edx
    mov [eax].vcs_esi,esi
    mov [eax].vcs_edi,edi
    mov si,ax
    mov ax,[bp].vm_gs
    mov [si].vcs_gs,ax
    mov ax,[bp].vm_fs
    mov [si].vcs_fs,ax
    mov ax,[bp].vm_es
    mov [si].vcs_es,ax
    mov ax,[bp].vm_ds
    mov [si].vcs_ds,ax
    mov ax,[bp].vm_eflags
    push ds
    push bx
    call get_flags
    pop bx
    pop ds
    mov [si].vcs_flags,ax
    mov eax,[bp].vm_eax
    mov [si].vcs_eax,eax
    mov eax,[bp].vm_ebx
    mov [si].vcs_ebx,eax
    mov bp,[bp].vm_bp
    mov [si].vcs_ebp,ebp
;
    mov ds,es:p_int_locked_stack
    mov si,bx
    mov di,[si].sim_esp
    sub di,22h
    mov cx,stack0_size
    sub cx,di
    mov sp,di
    mov ax,ss
    mov es,ax
    shr cx,1
    rep movsw
    xor bx,bx
    mov [bx],si
    pop ax
    popad
    popf
    pop gs
    pop fs
    pop es
    pop ds
    add sp,2
    retf32
sim16_end       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SIM16_BEGIN
;
;           DESCRIPTION:    Reflect to V86 mode
;
;           PARAMETERS:         CX              Number of words to copy
;                           DS:SI       Parameters
;                           ES:DI       VM_CALL_STRUC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim16_begin:
    push ds
    push es
    push fs
    push gs
    pushf
    pushad
    push word ptr 0
    mov bp,sp
    cld
    cmp word ptr [bp].sim_type,sim_ret
    je sim_no_cli
    xor ax,ax
    call set_flags
sim_no_cli:
    GetThread
    mov ds,ax
    mov bx,ds:p_int_locked_stack
    or bx,bx
    jnz sim_int_save_pm
    call allocate_switch_stack
sim_int_save_pm:
    mov cx,stack0_size
    sub cx,sp
    mov es,bx
    xor bx,bx
    sub es:[bx],cx
    mov di,es:[bx]
    mov ax,ss
    mov ds,ax
    mov si,sp
    shr cx,1
    rep movsw
    mov si,[bp].sim_esi
    mov fs,[bp].sim_ds
    mov cx,[bp].sim_ecx
    mov es,[bp].sim_es
    mov di,[bp].sim_edi
    mov bl,[bp].sim_type
    mov bh,[bp].sim_eax
    mov sp,stack0_size
    mov ax,flat_sel
    mov ds,ax
    xor eax,eax
    mov ax,es:[di].vcs_gs
    push eax
    mov ax,es:[di].vcs_fs
    push eax
    mov ax,es:[di].vcs_ds
    push eax
    mov ax,es:[di].vcs_es
    push eax
    mov ax,es:[di].vcs_ss
    movzx edx,es:[di].vcs_sp
    or ax,ax
    jnz sim_int_push_stack
    push ds
    GetThread
    mov ds,ax
    mov edx,ds:p_int_real_stack
    or edx,edx
    jnz sim_int_stack_ok
    mov eax,210h
    AllocateVMLinear
    mov ds:p_int_real_stack,edx
sim_int_stack_ok:
    mov eax,edx
    shr eax,4
    and edx,0Fh
    add edx,200h
    pop ds
sim_int_push_stack:
    cmp bl,sim_ret
    je sim_ret_ss
    sub dx,6
    sub dx,cx
    sub dx,cx
    push eax
    push edx
    shl eax,4
    add edx,eax
    mov ax,int_data_sel
    mov gs,ax
    mov ax,es:[di].vcs_flags
    push ds
    push bx
    call get_flags
    pop bx
    pop ds
    mov [edx+4],ax
    mov ax,gs:sim_int16_seg
    mov [edx+2],ax
    mov ax,gs:sim_int16_offs
    mov [edx],ax
    add edx,6
    jmp sim_push_test
sim_ret_ss:
    sub dx,4
    sub dx,cx
    sub dx,cx
    push eax
    push edx
    shl eax,4
    add edx,eax
    mov ax,int_data_sel
    mov gs,ax
    mov ax,gs:sim_int16_seg
    mov [edx+2],ax
    mov ax,gs:sim_int16_offs
    mov [edx],ax
    add edx,4
sim_push_test:
    or cx,cx
    jz sim_int_no_push
sim_int_push:
    mov ax,fs:[si]
    mov [edx],ax
    add si,2
    add edx,2
    loop sim_int_push
sim_int_no_push:
    movzx eax,word ptr es:[di].vcs_flags
    push bx
    call set_flags
    pop bx
    or eax,20000h
    and ax,NOT 4000h
    push ax
    popf
    push eax
    cmp bl,sim_int
    je sim_get_int_ads
    xor eax,eax
    mov ax,es:[di].vcs_cs
    push eax
    mov ax,es:[di].vcs_ip
    push eax
    jmp sim_load_regs
sim_get_int_ads:
    mov ax,flat_sel
    mov ds,ax
    movzx bx,bh
    shl bx,2
    xor eax,eax
    mov ax,[bx+2]
    push eax
    mov ax,[bx]
    push eax
sim_load_regs:
    mov eax,es:[di].vcs_eax
    mov ebx,es:[di].vcs_ebx
    mov ecx,es:[di].vcs_ecx
    mov edx,es:[di].vcs_edx
    mov ebp,es:[di].vcs_ebp
    mov esi,es:[di].vcs_esi
    mov edi,es:[di].vcs_edi
    iretd
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DPMI_INT
;
;           DESCRIPTION:    Call V86 int from protected mode
;
;           PARAMETERS:         AL              Int #
;                           CX              Number of words to copy
;                           DS:SI       Parameters
;                           ES:DI       VM_CALL_STRUC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_int_name   DB 'Dpmi Int',0

dpmi_int:
    push sim_int
    jmp sim16_begin
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DPMI_CALL_INT
;
;           DESCRIPTION:    Call V86 int frame from protected mode
;
;           PARAMETERS:         CX              Number of words to copy
;                           DS:SI       Parameters
;                           ES:DI       VM_CALL_STRUC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_call_int_name      DB 'Dpmi Call Int',0

dpmi_call_int:
    push sim_iret
    jmp sim16_begin
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DPMI_CALL
;
;           DESCRIPTION:    Call V86 procedure from protected mode
;
;           PARAMETERS:         CX              Number of words to copy
;                           DS:SI       Parameters
;                           ES:DI       VM_CALL_STRUC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_call_name  DB 'Dpmi Call',0

dpmi_call:
    push sim_ret
    jmp sim16_begin

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_VM_CALLBACK
;
;           DESCRIPTION:    Allocate V86 callback frame
;
;           PARAMETERS:         DS:SI       Protected mode procedure
;                           ES:DI       VM_CALL_STRUC
;                           DX:AX       V86 call address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_vm_callback_name       DB 'Allocate VM Callback',0

vm_callback_begin:
    VMCallback16
vm_callback_end:

    public vm_callback16

vm_callback16:
    int 3
    push ds
    push ebx
    lds bx,[ebx+6]
    mov [bx].vcs_ecx,ecx
    mov [bx].vcs_edx,edx
    mov [bx].vcs_esi,esi
    mov [bx].vcs_edi,edi
    mov ax,[bp].vm_gs
    mov [bx].vcs_gs,ax
    mov ax,[bp].vm_fs
    mov [bx].vcs_fs,ax
    mov ax,[bp].vm_ds
    mov [bx].vcs_ds,ax
    mov ax,[bp].vm_es
    mov [bx].vcs_es,ax
    mov ax,[bp].vm_ss
    mov [bx].vcs_ss,ax
    mov ax,[bp].vm_esp
    mov [bx].vcs_sp,ax
    mov ax,[bp].vm_eflags
    push ds
    push bx
    call get_flags
    pop bx
    pop ds
    mov [bx].vcs_flags,ax
    mov ax,[bp].vm_cs
    mov [bx].vcs_cs,ax
    mov ax,[bp].vm_eip
    mov [bx].vcs_ip,ax
    mov eax,[bp].vm_eax
    mov [bx].vcs_eax,eax
    mov eax,[bp].vm_ebx
    mov [bx].vcs_ebx,eax
    mov bp,[bp].vm_bp
    mov [bx].vcs_ebp,ebp
    mov di,bx
    mov ax,ds
    mov es,ax
    pop esi
    pop fs
    mov sp,stack0_size
;
    GetThread
    mov ds,ax
    mov bx,ds:p_int_locked_stack
    or bx,bx
    jnz vm_callback_do
    call allocate_switch_stack
vm_callback_do:
    push 0
    push bx
;
    push bx
    movzx edx,es:[di].vcs_ss
    shl edx,4
    AllocateLdt
    mov word ptr [bx],0FFFFh
    mov [bx+2],edx
    mov dl,0F2h
    xchg dl,[bx+5]
    xor ax,ax
    or ah,dl
    mov [bx+6],ax
    or bl,7
    mov cx,bx
    pop ds
    xor ebx,ebx
    mov bx,[bx]
    pushf
    pop ax
    mov [bx-2],cx
    mov [bx-4],ax
    mov word ptr [bx-6],callb_vm16_sel
    mov word ptr [bx-8],0
    sub bx,8
    push ebx
    xor dx,dx
    xchg dx,bx
    mov [bx],dx
;
    pushfd
    pop eax
    call set_flags
    or eax,20000h
    and ax,NOT 4000h
    push ax
    popf
    push eax
;
    mov bx,fs:[esi+4]
    push ebx
    mov bx,fs:[esi+2]
    push ebx
    mov ds,cx
    mov si,es:[di].vcs_sp
    and byte ptr [bp+2].vm_eflags,NOT 1
    iretd

    public pm_callback16

pm_callback16:
    int 3
    mov sp,stack0_size
    push 0
    push es:[di].vcs_gs
    push 0
    push es:[di].vcs_fs
    push 0
    push es:[di].vcs_ds
    push 0
    push es:[di].vcs_es
    push 0
    push es:[di].vcs_ss
    push 0
    push es:[di].vcs_sp
    movzx eax,es:[di].vcs_flags
    call set_flags
    or eax,20000h
    and ax,NOT 4000h
    push ax
    popf
    push eax
    push 0
    push es:[di].vcs_cs
    push 0
    push es:[di].vcs_ip
    GetThread
    mov ds,ax
    mov ds,ds:p_int_locked_stack
    xor bx,bx
    mov si,[bx]
    add si,8
    mov [bx],si
    mov bx,[si-2]
    and bl,0F8h
    FreeLdt
    mov eax,es:[di].vcs_eax
    mov ebx,es:[di].vcs_ebx
    mov ecx,es:[di].vcs_ecx
    mov edx,es:[di].vcs_edx
    mov ebp,es:[di].vcs_ebp
    mov esi,es:[di].vcs_esi
    mov edi,es:[di].vcs_edi
    and byte ptr [bp+2].vm_eflags,NOT 1
    iretd   

allocate_vm_callback    PROC far
    push edx
    mov eax,12
    AllocateVMLinear
    push fs
    mov ax,flat_sel
    mov fs,ax
    mov ax,word ptr cs:vm_callback_begin
    mov fs:[edx],ax
    mov ax,word ptr cs:vm_callback_begin+2
    mov fs:[edx+2],ax
    mov fs:[edx+4],si
    mov fs:[edx+6],ds
    mov fs:[edx+8],di
    mov fs:[edx+10],es
    pop fs
    mov ax,dx
    shr edx,4
    add sp,2
    push dx
    pop edx
    and ax,0Fh
    retf32
allocate_vm_callback    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_VM_CALLBACK
;
;           DESCRIPTION:    Free V86 callback
;
;           PARAMETERS:         DX:AX       V86 call address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_vm_callback_name   DB 'Free VM Callback',0

free_vm_callback    PROC far
    push ecx
    push edx
    movzx edx,dx
    shl edx,4
    movzx ecx,ax
    add edx,ecx
    mov ecx,12
    FreeLinear
    pop edx
    pop ecx
    retf32
free_vm_callback    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           BREAK_EXCEPTION16
;
;           DESCRIPTION:    Break exception handler chain
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public break_exception16

break_exception16       PROC near
    mov al,[ebx+3]
    mov [bp+2].vm_err,al
;
    mov ds,[bp].vm_ss
    mov bx,[bp].vm_esp
    add bx,2
;
    mov ax,[bx]
    mov [bp].vm_eip,ax
    add bx,2
;
    mov ax,[bx]
    mov [bp].vm_cs,ax
    add bx,2
;
    mov ax,[bx]
    push ds
    push bx
    call set_flags
    pop bx
    pop ds
    mov [bp].vm_eflags,ax
    add bx,2
;
    mov ax,[bx]
    mov [bp].vm_esp,ax
    mov ax,[bx+2]
    mov [bp].vm_ss,ax
    ret
break_exception16       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DEFAULT_EXCEPTION16
;
;           DESCRIPTION:    Default exception handler
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public default_exception16

default_exception16:
    mov al,[ebx+3]
    push ax
    mov [ebp].trap_state,al
;
    mov ds,[ebp].trap_ss
    mov bx,[ebp].trap_esp
    add bx,6
;
    mov ax,[bx]
    mov [ebp].trap_eip,ax
    add bx,2
;
    mov ax,[bx]
    mov [ebp].trap_cs,ax
    add bx,2
;
    mov ax,[bx]
    push ds
    push bx
    call set_flags
    pop bx
    pop ds
    mov [ebp].trap_eflags,ax
    add bx,2
;
    mov ax,[bx]
    mov [ebp].trap_esp,ax
    mov ax,[bx+2]
    mov [ebp].trap_ss,ax
    pop ax

run_default_exception:
    mov bx,def_exception_sel
    mov ds,bx
    movzx bx,al
    shl bx,3
    jmp fword ptr [bx]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PROT_EXCEPTION16
;
;           DESCRIPTION:    Exception handler
;
;           PARAMETERS:         AL          Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public prot_exception16

prot_exception16    PROC near
    mov bx,[ebp].trap_cs
    and bl,3
    cmp bl,3
    jne run_default_exception
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    pop ax
    movzx bx,al
;
    shl bx,3
    cmp word ptr ds:[bx+4].pr_pm_exc,callb_exc16_sel
    je run_default_exception
;
    push word ptr ds:[bx+4].pr_pm_exc
    push word ptr ds:[bx].pr_pm_exc
    push ax
;
    GetExceptionStack16
    mov ds,bx
;
    push ax
    mov ax,[ebp].trap_ss
    cmp ax,bx
    je prot_exc16_same_stack
;
    mov bx,800h
    jmp prot_exc16_stack_ok

prot_exc16_same_stack:
    mov bx,[ebp].trap_esp
    
prot_exc16_stack_ok:
    mov [bx-2],ax
    mov ax,[ebp].trap_esp
    mov [bx-4],ax
    sub bx,4
    pop ax
;
    cmp al,1
    mov ax,[ebp].trap_eflags
    jne prot_exc16_step_ok
;
    push ax
    and ax,NOT 100h
    mov [ebp].trap_eflags,ax
    pop ax

prot_exc16_step_ok:
    push ds
    push bx
    call get_flags
    pop bx
    pop ds
    sub bx,2
    mov [bx],ax
;
    sub bx,2
    mov ax,[ebp].trap_cs
    mov [bx],ax
;
    sub bx,2
    mov ax,[ebp].trap_eip
    mov [bx],ax
;
    sub bx,2
    mov ax,[ebp].trap_err
    mov [bx],ax
;
    sub bx,2
    mov word ptr [bx], callb_exc16_sel
;
    sub bx,2
    pop ax
    movzx ax,al
    shl ax,3
    mov [bx],ax
;
    mov [ebp].trap_esp,bx
    mov [ebp].trap_ss,ds
    pop word ptr [ebp].trap_eip
    pop word ptr [ebp].trap_cs 
prot_exception_do:
    ret
prot_exception16    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRANSLATE_PM16_REFLECT
;
;           DESCRIPTION:    Run default int
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public exception_pm16_reflect

exception_pm16_reflect:

    public translate_pm16_reflect

translate_pm16_reflect  PROC near
    mov al,[ebx+3]
    mov [bp+2].vm_err,al
    mov bx,int_data_sel
    mov ds,bx
    movzx bx,al
    shl bx,3
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET reflect_to_pm_done
    push eax
    push dword ptr ds:[bx+4].pm16_int_handlers
    push dword ptr ds:[bx].pm16_int_handlers
;
    mov ds,[bp].vm_ss
    mov bx,[bp].vm_esp
    mov ax,[bx]
    mov [bp].vm_eip,ax
    mov ax,[bx+2]
    mov [bp].vm_cs,ax
    mov ax,[bx+4]
    add bx,6
    mov [bp].vm_esp,bx
    call set_flags
    mov [bp].vm_eflags,ax
;
    mov ds,[bp].pm_ds
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    retf32

reflect_to_pm_done:
    mov [bp].pm_ds,ds
    mov [bp].vm_eax,eax
    mov [bp].vm_ebx,ebx
    mov al,[bp+2].vm_err
    retf32
translate_pm16_reflect  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DEFAULT_INT
;
;           DESCRIPTION:    Default interrupt handler
;
;           PARAMETERS:         AL          Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_int     PROC near
    mov [bp+2].vm_err,al
    mov bx,int_data_sel
    mov ds,bx
    movzx bx,al
    shl bx,3
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET reflect_to_pm_done
    push eax
    push dword ptr ds:[bx+4].pm16_int_handlers
    push dword ptr ds:[bx].pm16_int_handlers
;
    mov ds,[bp].pm_ds
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    retf32
default_int     ENDP

code    ENDS

    END

