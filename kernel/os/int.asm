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
; INT.ASM
; Software interrupt handling module
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


    .386p

    extrn init_int16:near
    extrn init_int32:near
    extrn translate_segment:near
    extrn translate_selector:near

    extrn prot_exception16:near
    extrn prot_exception32:near

    extrn new_prot_exception16:near
    extrn new_prot_exception32:near

    extrn set_flags:near
    extrn get_flags:near

    extrn setup_idt16:near
    extrn setup_idt32:near

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_INT
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_int

call_vm_ret_op:
    CallVMRet

call_pm16_ret_op:
    CallPM16Ret

call_pm32_ret_op:
    CallPM32Ret

vm_reflect0:
    ReflectVMToPM 0

pm_reflect_end:
    ReflectEnd

pm_to_vm_reflect_done:
    ReflectPMToVMDone

init_int    PROC near
    pusha
    push ds
;
    mov bx,int_data_sel
    mov eax,OFFSET int_seg_size
    AllocateFixedSystemMem
;
    mov eax,100h
    mov bx,def_exception_sel
    AllocateFixedSystemMem
;
    mov eax,100h
    mov bx,new_def_exception_sel
    AllocateFixedSystemMem
;
    mov eax,400h
    mov bx,vm_int_sel
    AllocateFixedProcessMem
;
    mov eax,400h
    AllocateFixedVMLinear
    mov ax,int_data_sel
    mov ds,ax
    mov ds:vm_reflect_ads,edx
    shr edx,4
    mov ds:vm_reflect_seg,dx
    mov edx,ds:vm_reflect_ads
    mov cx,100h
    mov ax,flat_sel
    mov ds,ax
    mov eax,dword ptr cs:vm_reflect0
init_reflect_vm_to_pm_loop:
    mov [edx],eax
    add edx,4
    add eax,1000000h
    loop init_reflect_vm_to_pm_loop
;
    mov eax,4
    AllocateFixedVMLinear
    mov ax,int_data_sel
    mov ds,ax
    push edx
    shr edx,4
    mov ds:call_vm_ret_seg,dx
    pop edx
    mov eax,dword ptr cs:call_vm_ret_op
    mov bx,flat_sel
    mov ds,bx
    mov [edx],eax
;
    mov eax,4
    AllocateFixedVMLinear
    AllocateGdt
    mov ecx,eax
    or bx,3
    CreateCodeSelector16
;
    mov ax,int_data_sel
    mov ds,ax
    mov ds:call_pm16_ret_sel,bx
    mov eax,dword ptr cs:call_pm16_ret_op
    mov bx,flat_sel
    mov ds,bx
    mov [edx],eax
;
    mov eax,4
    AllocateFixedVMLinear
    mov ax,int_data_sel
    mov ds,ax
    mov ds:pm_reflect_ads,edx
    shr edx,4
    mov ds:pm_reflect_seg,dx
    mov edx,ds:pm_reflect_ads
    mov eax,dword ptr cs:pm_reflect_end
    mov bx,flat_sel
    mov ds,bx
    mov [edx],eax
;
    mov eax,4
    AllocateFixedVMLinear
    mov ax,int_data_sel
    mov ds,ax
    mov ds:pm_to_vm_done_ads,edx
    shr edx,4
    mov ds:pm_to_vm_done_seg,dx
    mov edx,ds:pm_to_vm_done_ads
    mov eax,dword ptr cs:pm_to_vm_reflect_done
    mov bx,flat_sel
    mov ds,bx
    mov [edx],eax
;
;       mov ax,int_data_sel
;       mov ds,ax
;       mov edx,vm_reflect_ads
;       shr edx,4
;       mov ax,flat_sel
;       mov ds,ax
;       xor bx,bx
;       mov cx,100h
;init_vm_int_loop:
;       mov [bx],bx
;       mov [bx+2],dx
;       add bx,4
;       loop init_vm_int_loop
;
    mov ax,int_data_sel
    mov ds,ax
    mov cx,100h
    mov bx,OFFSET vm_int_handlers
    mov eax,OFFSET reflect_pm_to_vm  
init_vm_handlers_loop:
    mov [bx],eax
    mov [bx+4],cs
    add bx,8
    loop init_vm_handlers_loop
;
    mov ax,int_data_sel
    mov ds,ax
    mov cx,100h
    mov bx,OFFSET pm16_int_handlers
    mov eax,OFFSET reflect_pm_to_vm  
init_pm16_handlers_loop:
    mov [bx],eax
    mov [bx+4],cs
    add bx,8
    loop init_pm16_handlers_loop
;
    mov ax,int_data_sel
    mov ds,ax
    mov cx,100h
    mov bx,OFFSET pm32_int_handlers
    mov eax,OFFSET reflect_pm_to_vm  
init_pm32_handlers_loop:
    mov [bx],eax
    mov [bx+4],cs
    add bx,8
    loop init_pm32_handlers_loop
;
    mov ax,int_data_sel
    mov ds,ax
    mov cx,100h
    mov bx,OFFSET get_vm_int_handlers
    mov eax,OFFSET default_get_vm_int
init_get_vm_int_loop:
    mov [bx],eax
    mov [bx+4],cs
    add bx,8
    loop init_get_vm_int_loop
;
    mov ax,int_data_sel
    mov ds,ax
    mov cx,100h
    mov bx,OFFSET set_vm_int_handlers
    mov eax,OFFSET default_set_vm_int
init_set_vm_int_loop:
    mov [bx],eax
    mov [bx+4],cs
    add bx,8
    loop init_set_vm_int_loop
;
    mov cx,20h
    mov ax,def_exception_sel
    mov ds,ax
    xor bx,bx
    mov edx,OFFSET pm_exception_handler
init_exc_loop:
    mov [bx],edx
    mov [bx+4],cs
    add bx,8
    loop init_exc_loop
;
    mov cx,20h
    mov ax,new_def_exception_sel
    mov ds,ax
    xor bx,bx
    mov edx,OFFSET new_pm_exception_handler
new_init_exc_loop:
    mov [bx],edx
    mov [bx+4],cs
    add bx,8
    loop new_init_exc_loop
;
    mov eax,OFFSET raw_switch_v86_end - OFFSET raw_switch_v86_begin
    mov ecx,eax
    AllocateFixedVMLinear
    push edx
    mov ax,int_data_sel
    mov ds,ax
    mov ax,dx
    shr edx,4
    mov ds:v86_raw_seg,dx
    and ax,0Fh
    mov ds:v86_raw_offs,ax
    pop edi
    mov ax,flat_sel
    mov es,ax
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET raw_switch_v86_begin
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov eax,OFFSET raw_switch_prot_end - OFFSET raw_switch_prot_begin
    mov ecx,eax
    AllocateFixedVMLinear
    mov bx,raw_switch_sel
    CreateDataSelector16
    push cx
    mov es,bx
    xor di,di
    mov ax,cs
    mov ds,ax
    mov si,OFFSET raw_switch_prot_begin
    rep movsb
    pop cx
    xor ax,ax
    mov es,ax
    CreateCodeSelector16
;
    call init_int16
    call init_int32
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov si,OFFSET set_bitness
    mov di,OFFSET set_bitness_name
    xor cl,cl
    mov ax,set_bitness_nr
    RegisterOsGate
;
    mov si,OFFSET hook_vm_int
    mov di,OFFSET hook_vm_int_name
    xor cl,cl
    mov ax,hook_vm_int_nr
    RegisterOsGate
;
    mov si,OFFSET hook_exception
    mov di,OFFSET hook_exception_name
    xor cl,cl
    mov ax,hook_exception_nr
    RegisterOsGate
;
    mov si,OFFSET reflect_pm_to_vm
    mov di,OFFSET reflect_pm_to_vm_name
    xor cl,cl
    mov ax,reflect_pm_to_vm_nr
    RegisterOsGate
;
    mov si,OFFSET get_vm_int
    mov di,OFFSET get_vm_int_name
    xor dx,dx
    mov ax,get_vm_int_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET set_vm_int
    mov di,OFFSET set_vm_int_name
    xor dx,dx
    mov ax,set_vm_int_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET get_exception_stack16
    mov di,OFFSET get_exception_stack16_name
    xor cl,cl
    mov ax,get_exception_stack16_nr
    RegisterOsGate
;
    mov si,OFFSET get_exception_stack32
    mov di,OFFSET get_exception_stack32_name
    xor cl,cl
    mov ax,get_exception_stack32_nr
    RegisterOsGate
;
    mov si,OFFSET hook_get_vm_int
    mov di,OFFSET hook_get_vm_int_name
    xor cl,cl
    mov ax,hook_get_vm_int_nr
    RegisterOsGate
;
    mov si,OFFSET hook_set_vm_int
    mov di,OFFSET hook_set_vm_int_name
    xor cl,cl
    mov ax,hook_set_vm_int_nr
    RegisterOsGate
;
    mov si,OFFSET reflect_exception
    mov di,OFFSET reflect_exception_name
    xor cl,cl
    mov ax,reflect_exception_nr
    RegisterOsGate
;
    mov si,OFFSET raw_switch16
    mov di,OFFSET raw_switch_name
    xor dx,dx
    mov ax,raw_switch_pm_nr
    RegisterUserGate16
;
    mov si,OFFSET raw_switch_v86
    mov di,OFFSET raw_switch_name
    xor dx,dx
    mov ax,raw_switch_vm_nr
    RegisterUserGate16
;
    mov si,OFFSET get_raw_switch_ads
    mov di,OFFSET get_raw_switch_name
    xor dx,dx
    mov ax,get_raw_switch_ads_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET save_context
    mov di,OFFSET save_context_name
    xor cl,cl
    mov ax,save_context_nr
    RegisterOsGate
;
    mov si,OFFSET restore_context
    mov di,OFFSET restore_context_name
    xor cl,cl
    mov ax,restore_context_nr
    RegisterOsGate
;
    mov si,OFFSET call_vm
    mov di,OFFSET call_vm_name
    xor cl,cl
    mov ax,call_vm_nr
    RegisterOsGate
;
    mov si,OFFSET call_pm16
    mov di,OFFSET call_pm16_name
    xor cl,cl
    mov ax,call_pm16_nr
    RegisterOsGate
;
    mov si,OFFSET call_pm32
    mov di,OFFSET call_pm32_name
    xor cl,cl
    mov ax,call_pm32_nr
    RegisterOsGate
;
    mov edi,OFFSET init_thread_int
    HookCreateThread
;
    mov edi,OFFSET free_thread_int
    HookTerminateThread
;
    mov edi,OFFSET init_process_int
    HookCreateProcess
    pop ds
    popa
    ret
init_int    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_THREAD_INT
;
;           DESCRIPTION:    Init per-thread data
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread_int PROC far
    push ds
    push bx
    push ax
    mov ax,200h
    call set_flags
    GetThread
    mov ds,ax   
    mov ds:p_int_locked_stack,0
    mov ds:p_int_prot16_stack,0
    mov ds:p_int_prot32_stack,0
    mov ds:p_int_real_stack,0
    pop ax
    pop bx
    pop ds
    retf32
init_thread_int ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_THREAD_INT
;
;           DESCRIPTION:    Free per-thread data
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread_int PROC far
    push ds
    push es
    push ax
    push ecx
    push edx
;
    GetThread
    mov ds,ax
    mov ax,ds:p_int_locked_stack
    or ax,ax
    jz free_locked_ok
;
    mov es,ax
    FreeMem

free_locked_ok:
    mov ax,ds:p_int_prot16_stack
    or ax,ax
    jz free_prot16_ok
;
    mov es,ax
    FreeMem

free_prot16_ok:
    mov ax,ds:p_int_prot32_stack
    or ax,ax
    jz free_prot32_ok
;
    mov es,ax
    FreeMem

free_prot32_ok:
    mov edx,ds:p_int_real_stack
    or edx,edx
    jz free_real_ok
;
    mov ecx,210h
    FreeLinear

free_real_ok:
    pop edx
    pop ecx
    pop ax
    pop es
    pop ds
    retf32
free_thread_int ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_PROCESS_INT
;
;           DESCRIPTION:    Init per-process data
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process_int    PROC far
    push ds
    push es
    pusha
    mov ax,vm_int_sel
    mov ds,ax
    xor bx,bx
    mov cx,100h
init_int_loop:
    mov [bx],bx
    mov word ptr [bx+2],0E000h
    add bx,4
    loop init_int_loop
;
    popa
    pop es
    pop ds
    retf32
init_process_int    ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           allocate_switch_stack
;
;       Purpose:        Allocate switch stack for mode-switching
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public allocate_switch_stack

allocate_switch_stack   Proc near
    push ds
    push es
    push eax
    push edx
;
    GetThread
    mov ds,ax
;    
    mov eax,800h
    AllocateSmallGlobalMem
    mov ds:p_int_locked_stack,es
    xor bx,bx
    mov word ptr es:[bx],800h
    mov bx,es
;
    pop edx
    pop eax
    pop es
    pop ds
    ret
allocate_switch_stack   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetExceptionStack16
;
;       Purpose:        Get 16-bit exception handling stack
;
;       Returns:        BX          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exception_stack16_name      DB 'Get 16-bit Exception Stack', 0

get_exception_stack16   Proc far
    push ds
    push es
    push eax
    push edx
;
    GetThread
    mov ds,ax
;
    mov bx,ds:p_int_prot16_stack
    or bx,bx
    jnz get_exc_stack16_done
;
    mov eax,800h
    AllocateLocalLinear
    AllocateGdt
    mov ecx,eax
    or bx,3
    CreateDataSelector16
;
    mov ds:p_int_prot16_stack,bx

get_exc_stack16_done:
    pop edx
    pop eax
    pop es
    pop ds
    retf32
get_exception_stack16   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetExceptionStack32
;
;       Purpose:        Get 32-bit exception handling stack
;
;       Returns:        BX          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exception_stack32_name      DB 'Get 32-bit Exception Stack', 0

get_exception_stack32   Proc far
    push ds
    push es
    push eax
    push edx
;
    GetThread
    mov ds,ax
;
    mov bx,ds:p_int_prot32_stack
    or bx,bx
    jnz get_exc_stack32_done
;
    mov eax,800h
    AllocateLocalLinear
    AllocateGdt
    mov ecx,eax
    or bx,3
    CreateDataSelector32
;
    mov ds:p_int_prot32_stack,bx

get_exc_stack32_done:
    pop edx
    pop eax
    pop es
    pop ds
    retf32
get_exception_stack32   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetBitness
;
;           DESCRIPTION:    Set bitness
;
;           PARAMETERS:         AL      16 or 32-bit bitness
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_bitness_name    DB 'Set Bitness',0

set_bitness     PROC far
    push ds
    push bx
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    pop ax
    cmp al,16
    je set_bitness16

set_bitness32:
    mov ds:app_bitness,1
    call setup_idt32
    jmp set_bitness_done

set_bitness16:
    mov ds:app_bitness,0
    call setup_idt16

set_bitness_done:
    pop bx
    pop ds
    retf32
set_bitness     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SAVE_CONTEXT
;
;           DESCRIPTION:    Save ring 0 stack context
;
;           RETURNS:        BX          Offset to state on locked stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

save_context_name       DB 'Save Context',0

save_context    PROC far
    push ds
    push es
    push fs
    push gs
    pushf
    pushad
    GetThread
    mov ds,ax
    mov bx,ds:p_int_locked_stack
    or bx,bx
    jnz save_context_start
    call allocate_switch_stack
save_context_start:
    mov cx,stack0_size
    sub cx,sp
    mov es,bx
    xor bx,bx
    sub es:[bx],cx
    sub word ptr es:[bx],2
    mov di,es:[bx]
    mov ax,cx
    stosw
    mov ax,ss
    mov ds,ax
    mov si,sp
    shr cx,1
    rep movsw
    popad
    popf
    pop gs
    pop fs
    pop es
    pop ds
    pop eax
    pop edx
    mov sp,stack0_size
    push dword ptr 0
    push dword ptr 0
    push dword ptr 0
    push dword ptr 0
    push dword ptr 0
    push dword ptr 0
    push dword ptr 0
    push dword ptr 0
    push dword ptr 0
    mov bp,sp
    push ds
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_int_locked_stack
    xor bx,bx
    mov bx,[bx]
    pop ax
    pop ds
    push edx
    push eax
    retf32
save_context    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RESTORE_CONTEXT
;
;           DESCRIPTION:    Restore ring 0 stack context
;
;           PARAMETERS:         BX          Offset to state on locked stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

restore_context_name    DB 'Restore Context',0

restore_context PROC far
    GetThread
    mov ds,ax
    mov ds,ds:p_int_locked_stack
    mov si,bx
    lodsw
    mov cx,ax
    pop eax
    pop edx
    mov sp,stack0_size
    sub sp,cx
    mov bx,ss
    mov es,bx
    mov di,sp
    shr cx,1
    rep movsw
    xor bx,bx
    mov [bx],si
    mov bp,sp
    mov [bp+42],eax
    mov [bp+46],edx
    popad
    popf
;
    pop ax
    pushf
    verr ax
    jz restore_zero_gs
    xor ax,ax
restore_zero_gs:
    mov gs,ax
    popf
;
    pop ax
    pushf
    verr ax
    jz restore_zero_fs
    xor ax,ax
restore_zero_fs:
    mov fs,ax
    popf
;
    pop ax
    pushf
    verr ax
    jz restore_zero_es
    xor ax,ax
restore_zero_es:
    mov es,ax
    popf
;
    pop ax
    pushf
    verr ax
    jz restore_zero_ds
    xor ax,ax
restore_zero_ds:
    mov ds,ax
    popf
    retf32
restore_context ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PM_EXCEPTION_HANDLER
;
;           DESCRIPTION:    Protected mode exception handler
;
;           PARAMETERS:         AL          Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public pm_exception_handler

pm_exception_handler:
    DebugException

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NEW_PM_EXCEPTION_HANDLER
;
;           DESCRIPTION:    Protected mode exception handler
;
;           PARAMETERS:         AL          Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public new_pm_exception_handler

new_pm_exception_handler:
    NewDebugException

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           VM_EXCEPTION_HANDLER
;
;           DESCRIPTION:    V86 mode exception handler
;
;           PARAMETERS:         AL          Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public vm_exception_handler

vm_exception_handler    PROC far
    mov al,[bp+2].vm_err
    cmp byte ptr [bp].vm_err,0
    je vm_except_do
;
    mov bx,flat_sel
    mov ds,bx
    movzx ebx,word ptr [bp].vm_ss
    shl ebx,4
    movzx eax,word ptr [bp].vm_esp
    add ebx,eax
    mov ax,[ebx]
    mov [bp].vm_eip,ax
    mov ax,[ebx+2]
    mov [bp].vm_cs,ax
    add word ptr [bp].vm_esp,6

vm_except_do:
    DebugException
    retf32
vm_exception_handler    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRANSLATE_SEGMENTS
;
;           DESCRIPTION:    Translate segments to selectors
;
;           PARAMETERS:         AL          Segment transfer flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

translate_segments      PROC near
    test al,virt_es_in
    jz translate_not_es_in
    mov bx,[bp].vm_es
    call translate_segment
    mov es,bx
translate_not_es_in:
    test al,virt_fs_in
    jz translate_not_fs_in
    mov bx,[bp].vm_fs
    call translate_segment
    mov fs,bx
translate_not_fs_in:
    test al,virt_gs_in
    jz translate_not_gs_in
    mov bx,[bp].vm_gs
    call translate_segment
    mov gs,bx
translate_not_gs_in:
    test al,virt_ds_in
    jz translate_not_ds_in
    mov bx,[bp].vm_ds
    call translate_segment
    mov ds,bx
    jmp translate_seg_end
translate_not_ds_in:
    xor bx,bx
    mov ds,bx
translate_seg_end:
    ret
translate_segments      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRANSLATE_SELECTORS
;
;           DESCRIPTION:    Translate selectors to segments
;
;           PARAMETERS:         AL          Segment transfer flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

translate_selectors     PROC near
    mov bx,ds
    or bx,bx
    jz translate_out_ds_done
    xor ax,ax
    mov ds,ax
    call translate_selector
    jc translate_out_ds_done
    mov [bp].vm_ds,bx
translate_out_ds_done:
    mov bx,es
    or bx,bx
    jz translate_out_es_done
    xor ax,ax
    mov es,ax
    call translate_selector
    jc translate_out_es_done
    mov [bp].vm_es,bx
translate_out_es_done:
    mov bx,fs
    or bx,bx
    jz translate_out_fs_done
    xor ax,ax
    mov fs,ax
    call translate_selector
    jc translate_out_fs_done
    mov [bp].vm_fs,bx
translate_out_fs_done:
    mov bx,gs
    or bx,bx
    jz translate_out_gs_done
    xor ax,ax
    mov gs,ax
    call translate_selector
    jc translate_out_gs_done
    mov [bp].vm_gs,bx
translate_out_gs_done:
    ret
translate_selectors     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CALL_VM
;
;           DESCRIPTION:    Call V86 code without destroying ring 0 stack
;
;           PARAMETERS:         V86 segment:offset to call on stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

call_vm_name    DB 'Call VM',0

call_vm_bp          EQU 16
call_vm_seg         EQU 14
call_vm_offs    EQU 12
call_vm_eax         EQU 8
call_vm_ebx         EQU 4
call_vm_edx         EQU 0

call_vm Proc far
    push ds
    push es
    push fs
    push gs
    push bp
    mov bp,sp
    push dword ptr [bp+18]
;
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    push di
;
    GetThread
    mov ds,ax
    mov bx,ds:p_int_locked_stack
    or bx,bx
    jnz call_vm_save_context
    call allocate_switch_stack
call_vm_save_context:
    mov cx,stack0_size-14
    sub cx,sp
    mov es,bx
    xor bx,bx
    sub es:[bx],cx
    sub word ptr es:[bx],2
    mov di,es:[bx]
    mov ax,cx
    stosw
    mov ax,ss
    mov ds,ax
    mov si,sp
    add si,14
    shr cx,1
    rep movsw
;
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
;
    cli
    mov bp,sp
    mov sp,stack0_size
    push word ptr [bp+4]
    push word ptr [bp+2]
    push word ptr [bp]
    sti
    push eax
    push ebx
    push edx
    mov bp,sp
;
    push dword ptr 0
    push dword ptr 0
    mov bx,ds
    call translate_selector
    push word ptr 0
    push bx
    mov bx,es
    call translate_selector
    push word ptr 0
    push bx
;
    GetThread
    mov ds,ax
    mov edx,ds:p_int_real_stack
    or edx,edx
    jnz call_vm_real_stack_ok
    mov eax,210h
    AllocateVMLinear
    mov ds:p_int_real_stack,edx
call_vm_real_stack_ok:
    mov eax,edx
    shr eax,4
    and edx,0Fh
    add edx,200h-6
    push eax
    push edx
    shl eax,4
    add edx,eax
    mov ax,int_data_sel
    mov ds,ax
    mov bx,ds:call_vm_ret_seg
    push bx
    pushf
    pop ax
    call get_flags
    pop bx
    push ax
    mov ax,flat_sel
    mov ds,ax
    mov word ptr [edx],0
    mov [edx+2],bx
    pop ax
    mov [edx+4],ax
    call set_flags
    and ax,NOT 4000h
    push ax
    popf
;
    push word ptr 2
    push ax
    push word ptr 0
    push word ptr [bp].call_vm_seg
    push word ptr 0
    push word ptr [bp].call_vm_offs
    mov eax,[bp].call_vm_eax
    mov ebx,[bp].call_vm_ebx
    mov edx,[bp].call_vm_edx
    mov bp,[bp].call_vm_bp
    iretd

    public call_vm_ret

call_vm_ret:
    cli
    xor bx,bx
    mov ax,[bp].vm_ds
    mov ss:[bx+2],ax
    mov ax,[bp].vm_es
    mov ss:[bx+4],ax
    mov eax,[bp].vm_eax
    mov ss:[bx+6],ax
    mov ax,[bp].vm_ebx
    mov ss:[bx+8],ax
    mov ebx,[bp].vm_ebx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_int_locked_stack
    xor bx,bx
    mov bx,[bx]
    mov ax,stack0_size
    sub ax,[bx]
    mov bx,ax
;
    mov sp,bx
    sub sp,8
    push cx
    push si
    push di
;       
    xor bx,bx
    mov si,[bx]
    lodsw
    mov cx,ax
    mov bx,ss
    mov es,bx
    mov di,sp
    add di,14
    shr cx,1
    rep movsw
    xor bx,bx
    mov [bx],si
;
    pop di
    pop si
    pop cx
;
    xor bx,bx
    mov ax,ss:[bx+6]
    mov bx,ss:[bx+8]
;
    add sp,12
    pop bp
    pop gs
    pop fs
    pop es
    pop ds
;
    push eax
    push bx
    push bp
    xor bx,bx
    push dword ptr ss:[bx+2]
    sti
    mov bp,sp
    mov bx,ds
    push ds
    call translate_selector
    pop ds
    cmp bx,[bp]
    je call_vm_ds_done
;
    mov bx,[bp]
    call translate_segment
    mov ds,bx

call_vm_ds_done:
    mov bx,es
    push ds
    call translate_selector
    pop ds
    cmp bx,[bp+2]
    je call_vm_es_done
;
    mov bx,[bp+2]
    call translate_segment
    mov es,bx

call_vm_es_done:
    add sp,4
    pop bp
    pop bx
    pop eax
    Retf32Pop 4
call_vm Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CALL_PM16
;
;           DESCRIPTION:    Call 16-bit protected mode user code
;
;           PARAMETERS:         16-bit protected mode segment:offset on stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

call_pm16_name  DB 'Call Prot16 App',0

call_pm16_sel       EQU 20
call_pm16_offs      EQU 18
call_pm16_bp        EQU 16
call_pm16_ds        EQU 14
call_pm16_es        EQU 12
call_pm16_eax       EQU 8
call_pm16_ebx       EQU 4
call_pm16_edx       EQU 0

call_pm16       Proc far
    push bp
;
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    push di
;
    GetThread
    mov ds,ax    
    mov bx,ds:p_int_locked_stack
    or bx,bx
    jnz call_pm16_save_context
    call allocate_switch_stack
call_pm16_save_context:
    mov cx,stack0_size-14
    sub cx,sp
    mov es,bx
    xor bx,bx
    sub es:[bx],cx
    sub word ptr es:[bx],2
    mov di,es:[bx]
    mov ax,cx
    stosw
    mov ax,ss
    mov ds,ax
    mov si,sp
    add si,14
    shr cx,1
    rep movsw
;
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
;
    cli
    mov bp,sp
    mov sp,stack0_size
    push word ptr [bp+12]
    push word ptr [bp+10]
    push word ptr [bp]
    sti
    push ds
    push es
    push eax
    push ebx
    push edx
    mov bp,sp
;
    GetExceptionStack16
    mov es,bx
    push word ptr 0
    push es
    mov edx,800h-6
    push edx
    mov ax,int_data_sel
    mov ds,ax
    mov bx,ds:call_pm16_ret_sel
    push bx
    pushf
    pop ax
    call get_flags
    pop bx
    push ax
    mov word ptr es:[edx],0
    mov es:[edx+2],bx
    pop ax
    mov es:[edx+4],ax
    call set_flags
    and ax,NOT 4000h
    push ax
    popf
    push word ptr 0
    push ax
    push word ptr 0
    push word ptr [bp].call_pm16_sel
    push word ptr 0
    push word ptr [bp].call_pm16_offs
    mov ds,[bp].call_pm16_ds
    mov es,[bp].call_pm16_es
    mov eax,[bp].call_pm16_eax
    mov ebx,[bp].call_pm16_ebx
    mov edx,[bp].call_pm16_edx
    mov bp,[bp].call_pm16_bp
    iretd

    public call_pm16_ret

call_pm16_ret:
    xor bx,bx
    mov ax,[bp].pm_ds
    mov ss:[bx],ax
    mov eax,[bp].vm_eax
    mov ss:[bx+2],ax
    mov ax,[bp].vm_ebx
    mov ss:[bx+4],ax
    mov ebx,[bp].vm_ebx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_int_locked_stack
    xor bx,bx
    mov bx,[bx]
    mov ax,stack0_size
    sub ax,[bx]
    mov bx,ax
;
    mov sp,bx
    xor bx,bx
    mov ax,ss:[bx]
    push ax
    push es
    mov ax,ss:[bx+2]
    push ax
    mov ax,ss:[bx+4]
    push ax
    push cx
    push si
    push di
;       
    xor bx,bx
    mov si,[bx]
    lodsw
    mov cx,ax
    mov bx,ss
    mov es,bx
    mov di,sp
    add di,14
    shr cx,1
    rep movsw
    xor bx,bx
    mov [bx],si
;
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
    pop bp
    Retf32Pop 4
call_pm16       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CALL_PM32
;
;           DESCRIPTION:    Call 32-bit flat mode user code
;
;           PARAMETERS:         32-bit flat mode offset on stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

call_pm32_name  DB 'Call Prot32 App',0

call_pm32_offs      EQU 14
call_pm32_bp        EQU 12
call_pm32_eax       EQU 8
call_pm32_ebx       EQU 4
call_pm32_edx       EQU 0

call_pm32       Proc far
    push bp
;
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    push di
;
    GetThread
    mov ds,ax
    mov bx,ds:p_int_locked_stack
    or bx,bx
    jnz call_pm32_save_context
    call allocate_switch_stack
call_pm32_save_context:
    mov cx,stack0_size-14
    sub cx,sp
    mov es,bx
    xor bx,bx
    sub es:[bx],cx
    sub word ptr es:[bx],2
    mov di,es:[bx]
    mov ax,cx
    stosw
    mov ax,ss
    mov ds,ax
    mov si,sp
    add si,14
    shr cx,1
    rep movsw
;
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
;
    cli
    mov bp,sp
    mov sp,stack0_size
    push dword ptr [bp+10]
    push word ptr [bp]
    sti
    push eax
    push ebx
    push edx
    mov bp,sp
;
    mov eax,1000h
    AllocateLocalLinear
    mov bx,system_data_sel
    mov ds,bx
    sub edx,ds:flat_base
    mov bx,flat_data_sel
    mov ds,bx
    mov eax,dword ptr cs:call_pm32_ret_op
    add edx,0FFCh
    mov ebx,edx
    mov [edx],eax
    sub edx,12
;
    sub sp,2
    push ds
    push edx
    pushf
    pop ax
;
    push ds
    push ebx
    call get_flags
    movzx eax,ax
    call set_flags
    and ax,NOT 4000h
    push ax
    popf
    pop ebx
    pop ds
;
    push eax
    mov [edx+8],eax
    mov eax,flat_code_sel
    mov [edx+4],eax
    mov [edx],ebx
    push eax
    push dword ptr [bp].call_pm32_offs
    mov ax,flat_data_sel
    mov ds,ax
    mov es,ax
    mov eax,[bp].call_pm32_eax
    mov ebx,[bp].call_pm32_ebx
    mov edx,[bp].call_pm32_edx
    mov bp,[bp].call_pm32_bp
    iretd

    public call_pm32_ret

call_pm32_ret:
    xor bx,bx
    mov ax,[bp].pm_ds
    mov ss:[bx],ax
    mov eax,[bp].vm_eax
    mov ss:[bx+2],ax
    mov ax,[bp].vm_ebx
    mov ss:[bx+4],ax
    mov ebx,[bp].vm_ebx
;
    push ecx
    mov edx,[bp].vm_esp
    and dx,0F000h
    mov ecx,1000h
    mov ax,system_data_sel
    mov ds,ax
    add edx,ds:flat_base
    FreeLinear
    pop ecx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_int_locked_stack
    xor bx,bx
    mov bx,[bx]
    mov ax,stack0_size
    sub ax,[bx]
    mov bx,ax
;
    mov sp,bx
    xor bx,bx
    mov ax,ss:[bx]
    push ax
    push es
    mov ax,ss:[bx+2]
    push ax
    mov ax,ss:[bx+4]
    push ax
    push cx
    push si
    push di
;       
    xor bx,bx
    mov si,[bx]
    lodsw
    mov cx,ax
    mov bx,ss
    mov es,bx
    mov di,sp
    add di,14
    shr cx,1
    rep movsw
    xor bx,bx
    mov [bx],si
;
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
    pop bp
    Retf32Pop 4
call_pm32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REFLECT_TO_PM
;
;           DESCRIPTION:    Reflect V86 mode interrupt to protected mode
;
;           PARAMETERS:         AL          Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reflect_to_pm:
    mov [bp+2].vm_err,al
    mov bx,int_data_sel
    mov ds,bx
    movzx bx,al
    shl bx,3
    xor eax,eax
    mov ax,cs
    push eax
    mov eax,OFFSET reflect_to_pm_done
    push eax
    push dword ptr ds:[bx+4].vm_int_handlers
    push dword ptr ds:[bx].vm_int_handlers
    xor ax,ax
    mov ds,ax

reflect_do:
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    retf32

reflect_to_pm_done:
    mov [bp].vm_eax,eax
    mov [bp].vm_ebx,ebx
    mov al,[bp+1].vm_err
    or al,al
    jz reflect_leave
    call translate_selectors
reflect_leave:
    mov al,[bp+2].vm_err
    cmp byte ptr [bp].vm_err,0
    je no_sim_iret
;
    mov bx,flat_sel
    mov ds,bx
    movzx ebx,word ptr [bp].vm_ss
    shl ebx,4
    movzx eax,word ptr [bp].vm_esp
    add ebx,eax
    mov ax,[ebx]
    mov [bp].vm_eip,ax
    mov ax,[ebx+2]
    mov [bp].vm_cs,ax
    add word ptr [bp].vm_esp,6
    retf32
no_sim_iret:
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REFLECT_END
;
;           DESCRIPTION:    Abort reflect to protected mode
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public reflect_end

reflect_end     PROC near
    push ds
    push cx
    push si
    push di
;
    GetThread
    mov ds,ax   
    xor bx,bx
    mov ds,ds:p_int_locked_stack
    mov si,[bx]
    mov ax,ss
    mov es,ax
    mov di,bp
    add di,vm_eip
    mov cx,vm_ss - vm_eip + 4
    rep movsb
;       
    GetThread
    mov ds,ax
    xor bx,bx
    mov [bx],si
;       
    pop di
    pop si
    pop cx
    pop ds
    ret
reflect_end     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REFLECT_PM_TO_VM
;
;           DESCRIPTION:    Reflect protected mode to V86 mode
;
;           PARAMETERS:         BP              Gate parameters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reflect_pm_to_vm_name   DB 'Reflect PM to VM',0

reflect_pm_to_vm    PROC far
    test byte ptr [bp+2].vm_eflags,2
    jnz reflect_from_vm
    push ds
    push es
    push fs
    push gs
    push bp
;
    xor bx,bx
    mov ax,[bp].vm_bp
    mov ss:[bx],ax
    mov ss:[bx+2],cx
    mov ss:[bx+4],si
    mov ss:[bx+6],di
    mov eax,[bp].vm_eax
    mov ss:[bx+8],eax
    mov eax,[bp].vm_ebx
    mov ss:[bx+12],eax
    mov ss:[bx+16],edx
    mov eax,[bp].vm_eflags
    mov ss:[bx+20],eax
;
    GetThread
    mov ds,ax
    mov bx,ds:p_int_locked_stack
    or bx,bx
    jnz reflect_pm_locked_move
    call allocate_switch_stack
reflect_pm_locked_move:
    mov es,bx
    xor bx,bx
    mov di,es:[bx]
    mov ax,ss
    mov ds,ax
    mov bx,[bp+2].vm_err
    mov es:[di-2],bx
    mov si,sp
    mov cx,stack0_size
    sub cx,si
    sub di,cx
    sub di,4
    push bx
    xor bx,bx
    mov es:[bx],di
    pop bx
    mov ax,cx
    stosw
    rep movsb
;
    mov sp,stack0_size
    xor si,si
    mov eax,0F000h
    push eax
    push eax
    push eax
    push eax
;
    GetThread
    mov ds,ax
    mov edx,ds:p_int_real_stack
    or edx,edx
    jnz refl_pm_to_vm_stack_ok
    mov eax,210h
    AllocateVMLinear
    mov ds:p_int_real_stack,edx
refl_pm_to_vm_stack_ok:
    mov eax,edx
    shr edx,4
    and eax,0Fh
    add eax,200h
    push edx
    sub ax,10
    push eax
;
    mov cx,int_data_sel
    mov ds,cx
    push ds:pm_to_vm_done_seg
    mov cx,flat_sel
    mov ds,cx
    shl edx,4
    add edx,eax
    push ds
    push bx
    mov ax,ss:[si+20]
    call get_flags
    pop bx
    pop ds
    mov [edx+4],ax
    pop ax
    mov [edx+2],ax
    mov word ptr [edx],0
;
    mov eax,ss:[si+20]
    push ds
    push bx
    and ax,NOT 300h
    call set_flags
    pop bx
    pop ds
    or eax,20000h
    and ax,NOT 4000h
    push ax
    popf
    push eax
;
    mov al,bl
    GetVmInt
    movzx eax,dx
    push eax
    movzx eax,bx
    push eax
;
    mov eax,ss:[si+8]
    mov ebx,ss:[si+12]
    mov cx,ss:[si+2]
    mov edx,ss:[si+16]
    mov di,ss:[si+6]
    mov bp,ss:[si]
    mov si,ss:[si+4]
    iretd

reflect_from_vm:
    mov [bp].vm_eax,eax
    mov [bp].vm_ebx,ebx
    xor bl,bl
    xchg bl,[bp].vm_err
    cmp bl,1
    jne reflect_vm_done
    mov bx,flat_sel
    mov ds,bx
    movzx ebx,word ptr [bp].vm_ss
    shl ebx,4
    movzx eax,word ptr [bp].vm_esp
    add ebx,eax
    mov ax,[ebx]
    mov [bp].vm_eip,ax
    mov ax,[ebx+2]
    mov [bp].vm_cs,ax
    mov ax,[ebx+4]
    call set_flags
    and ax,NOT 4000h
    push ax
    popf
    mov [bp].vm_eflags,ax
    add word ptr [bp].vm_esp,6
reflect_vm_done:
    mov ax,bp
    add ax,vm_ebx
    mov sp,ax
    pop ebx
    pop eax
    pop bp
    add sp,4
    iretd
reflect_pm_to_vm    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REFLECT_PM_TO_VM_DONE
;
;           DESCRIPTION:    Abort reflect to V86 mode
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public reflect_pm_to_vm_done

reflect_pm_to_vm_done   PROC far
    cld
    xor bx,bx
    mov ax,[bp].vm_bp
    mov ss:[bx],ax
    mov ss:[bx+2],cx
    mov ss:[bx+4],si
    mov ss:[bx+6],di
    mov eax,[bp].vm_eax
    mov ss:[bx+8],eax
    mov eax,[bp].vm_ebx
    mov ss:[bx+12],eax
    mov ss:[bx+16],edx
    mov eax,[bp].vm_eflags
    mov ss:[bx+20],eax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_int_locked_stack
    xor bx,bx
    mov si,[bx]
    lodsw
    mov cx,ax
    add word ptr [bx],4
    add [bx],cx
    mov ax,ss
    mov es,ax
    mov di,stack0_size
    sub di,cx
    mov sp,di
    rep movsb
;
    mov ax,ss:[bx+20]
    push bx
    call set_flags
    pop bx
    push ax
    popf
    pop bp
    mov ax,ss:[bx]
    mov [bp].vm_bp,ax
    mov cx,ss:[bx+2]
    mov edx,ss:[bx+16]
    mov si,ss:[bx+4]
    mov di,ss:[bx+6]
    mov eax,ss:[bx+8]
    mov ebx,ss:[bx+12]
;
    pop gs
    pop fs
    pop es
    pop ds
    retf32
reflect_pm_to_vm_done   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           VIRT_EXCEPTION
;
;           DESCRIPTION:    V86 mode exception
;
;           PARAMETERS:         AL          Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public virt_exception

virt_exception  PROC near
    mov bx,vm_int_sel
    mov ds,bx
    movzx bx,al
    shl bx,2
    cmp bx,[bx]
    jne simulate_exception
    mov bx,[bx+2]
    push int_data_sel
    pop ds
    cmp bx,ds:vm_reflect_seg
    jne simulate_exception
    mov word ptr [bp].vm_err,0
    jmp reflect_to_pm
simulate_exception:
    mov byte ptr [bp].vm_err,1
    push edx
    mov bx,vm_int_sel
    mov ds,bx
    xor ebx,ebx
    mov bl,al
    shl ebx,2
    mov dx,[ebx]
    xchg dx,[bp].vm_eip
    mov ax,[ebx+2]
    xchg ax,[bp].vm_cs
    push ax
    push dx
    movzx edx,word ptr [bp].vm_esp
    mov bx,flat_sel
    mov ds,bx
    movzx ebx,word ptr [bp].vm_ss
    shl ebx,4
    sub dx,6
    mov [bp].vm_esp,dx
    add ebx,edx
    pop ax
    mov [ebx],ax
    pop ax
    mov [ebx+2],ax
    mov ax,[bp].vm_eflags
    push bx
    call get_flags
    mov bx,flat_sel
    mov ds,bx
    pop bx
    mov [ebx+4],ax  
    and ax,NOT 300h
    call set_flags
    mov [bp].vm_eflags,ax
    pop edx
    ret
virt_exception  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PROT_EXCEPTION
;
;           DESCRIPTION:    Protected mode exception
;
;           PARAMETERS:         AL          Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public prot_exception

prot_exception:
    cld
    mov [bp+2].vm_err,al
    mov bx,[bp].vm_cs
    and bl,3
    cmp bl,3
    je prot_exception_user
    mov bx,def_exception_sel
    mov ds,bx
    movzx bx,al
    shl bx,3
    jmp fword ptr [bx]
prot_exception_user:
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    pop ax
    test ds:app_bitness,1
    jz prot_exception16
    jmp prot_exception32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NEW_VIRT_EXCEPTION
;
;           DESCRIPTION:    V86 mode exception
;
;           PARAMETERS:         AL          Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public new_virt_exception

new_virt_exception  PROC near
    mov bx,vm_int_sel
    mov ds,bx
    movzx bx,al
    shl bx,2
    cmp bx,[bx]
    jne simulate_exception
    mov bx,[bx+2]
    push int_data_sel
    pop ds
    cmp bx,ds:vm_reflect_seg
    jne new_simulate_exception
    mov word ptr [ebp].trap_err,0
    jmp reflect_to_pm

new_simulate_exception:
    mov byte ptr [ebp].trap_err,1
    push edx
    mov bx,vm_int_sel
    mov ds,bx
    xor ebx,ebx
    mov bl,al
    shl ebx,2
    mov dx,[ebx]
    xchg dx,[ebp].trap_eip
    mov ax,[ebx+2]
    xchg ax,[ebp].trap_cs
    push ax
    push dx
    movzx edx,word ptr [ebp].trap_esp
    mov bx,flat_sel
    mov ds,bx
    movzx ebx,word ptr [ebp].trap_ss
    shl ebx,4
    sub dx,6
    mov [ebp].trap_esp,dx
    add ebx,edx
    pop ax
    mov [ebx],ax
    pop ax
    mov [ebx+2],ax
    mov ax,[ebp].trap_eflags
    push bx
    call get_flags
    mov bx,flat_sel
    mov ds,bx
    pop bx
    mov [ebx+4],ax  
    and ax,NOT 300h
    call set_flags
    mov [ebp].trap_eflags,ax
    pop edx
    ret
new_virt_exception  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NEW_PROT_EXCEPTION
;
;           DESCRIPTION:    Protected mode exception
;
;           PARAMETERS:         AL          Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public new_prot_exception

new_prot_exception:
    cld
    mov [ebp+2].trap_err,al
    mov ebx,[ebp].trap_cs
    and bl,3
    cmp bl,3
    je new_prot_exception_user
;
    mov bx,new_def_exception_sel
    mov ds,bx
    movzx bx,al
    shl bx,3
    jmp fword ptr [bx]
    
new_prot_exception_user:
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    pop ax
    test ds:app_bitness,1
    jz new_prot_exception16
    jmp new_prot_exception32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReflectException
;
;           DESCRIPTION:    Reflect a exception to the proper mode
;
;           PARAMETERS:         AL          Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reflect_exception_name  DB 'Reflect Exception', 0

reflect_exception:
    test byte ptr [bp+2].vm_eflags,2
    jnz reflect_exc_break
;
    mov bx,[bp].vm_cs
    and bl,3
    cmp bl,3
    jne reflect_exc_break
;       
    cmp al,8
    je reflect_exc_break
;
    call prot_exception
    mov ds,[bp].pm_ds
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov sp,bp
    pop bp
    add sp,4
    iretd

reflect_exc_break:
    DebugException

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRANSLATE_VM_REFLECT
;
;           DESCRIPTION:    Reflect V86 mode -> to protected mode
;
;           PARAMETERS:         AL          Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public translate_vm_reflect

translate_vm_reflect:
    sub ebx,2
    mov al,[ebx+3]
    mov word ptr [bp].vm_err,1
    push ax
    movzx ebx,word ptr [bp].vm_ss
    shl ebx,4
    movzx eax,word ptr [bp].vm_esp
    mov ax,[eax+ebx+4]
    SetFlags
    mov [bp].vm_eflags,ax
    pop ax
    jmp reflect_to_pm

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RawSwitch (from PM)
;
;           DESCRIPTION:    Raw mode switch protected mode -> V86 mode
;
;           PARAMETERS:         AX          New DS
;                           CX          New ES
;                           DX          New SS
;                           BX          New SP
;                           SI          New CS
;                           DI          New IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

raw_switch_name DB 'Raw Mode Switch',0

raw_switch16:
    mov sp,stack0_size
    push 0
    push 0
    push 0
    push 0
    movzx eax,ax
    push eax
    movzx eax,cx
    push eax
    movzx eax,dx
    push eax
    movzx eax,bx
    push eax
    pushfd
    pop eax
    or eax,23200h
    and eax,NOT 4000h
    call set_flags
    push ax
    popf
    push eax
    movzx eax,si
    push eax
    movzx eax,di
    push eax
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RawSwitch (from V86)
;
;           DESCRIPTION:    Raw mode switch V86 mode -> protected mode
;
;           PARAMETERS:         AX          New DS
;                           CX          New ES
;                           DX          New SS
;                           (E)BX   New (E)SP
;                           SI          New CS
;                           (E)DI   New (E)IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

raw_switch_v86:
    mov sp,stack0_size
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    test ds:app_bitness,1
    jz raw_switch16_v86

raw_switch32_v86:
    pop ds
    mov es,cx
    movzx eax,dx
    push eax
    push ebx
    pushfd
    pop eax
    or eax,3200h
    and eax,NOT 4000h
    push ds
    call set_flags
    pop ds
    push ax
    popf
    push eax
    movzx eax,si
    push eax
    push edi
    iretd

raw_switch16_v86:
    pop ds
    mov es,cx
    movzx eax,dx
    push eax
    movzx ebx,bx
    push ebx
    pushfd
    pop eax
    or eax,3200h
    and eax,NOT 4000h
    push ds
    call set_flags
    pop ds
    push ax
    popf
    push eax
    movzx eax,si
    push eax
    movzx edi,di
    push edi
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_RAW_SWITCH_ADS
;
;           DESCRIPTION:    Get raw mode switch addresses
;
;           RETURNS:        BX:CX       V86 address to use to switch to Prot mode
;                           SI:(E)DI    Prot mode address to use to switch to V86.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_raw_switch_name     DB 'Get Raw Switch Adress',0

raw_switch_prot_begin:
    RawSwitchPm

raw_switch_prot_end:

raw_switch_v86_begin:
    RawSwitchVm
raw_switch_v86_end:

get_raw_switch_ads      PROC far
    push ds
    mov bx,int_data_sel
    mov ds,bx
    mov bx,ds:v86_raw_seg
    mov cx,ds:v86_raw_offs
    mov di,raw_switch_sel
    mov si,di
    xor edi,edi
    pop ds  
    retf32
get_raw_switch_ads      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_VM_INT
;
;           DESCRIPTION:    Add V86 mode int hook
;
;           PARAMETERS:         AL          Int #
;                               DS:EDI   Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_vm_int_name    DB 'Hook Vm Int',0

hook_vm_int     PROC far
    push ds
    push es
    push bx
    mov bx,int_data_sel
    mov es,bx
    movzx bx,al
    shl bx,3
    mov es:[bx].vm_int_handlers,edi
    mov es:[bx+4].vm_int_handlers,ds
    pop bx
    pop es
    pop ds
    retf32
hook_vm_int     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_EXCEPTION
;
;           DESCRIPTION:    Add protected mode exception hook
;
;           PARAMETERS:         AL          Exception #
;                           ES:EDI   Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_exception_name     DB 'Hook Exception',0

hook_exception  PROC far
    push ds
    push bx
    mov bx,def_exception_sel
    mov ds,bx
    movzx bx,al
    shl bx,3
    mov [bx],edi
    mov [bx+4],es
    pop bx
    pop ds
    retf32
hook_exception  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEFAULT_EXCEPTION
;
;           DESCRIPTION:    Default exception handler
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public default_exception

    extrn default_exception16:near
    extrn default_exception32:near

default_exception:
    mov ax,[bp].vm_cs
    cmp ax,callb_exc16_sel
    je default_exception16
    jmp default_exception32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           BREAK_EXCEPTION
;
;           DESCRIPTION:    Break exception handler chain
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public break_exception

    extrn break_exception16:near
    extrn break_exception32:near

break_exception:
    mov ax,[bp].vm_cs
    cmp ax,callb_exc16_sel
    je break_exception16
    jmp break_exception32



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEFAULT_GET_VM_INT
;
;           DESCRIPTION:    Default get V86 int 
;
;           PARAMETERS:         AL              Int #
;
;           RETURNS:        DX:BX       Segment:offset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_get_vm_int      PROC far
    mov bx,vm_int_sel
    mov ds,bx
    movzx bx,al
    shl bx,2
    mov dx,[bx+2]
    mov bx,[bx]
    retf32
default_get_vm_int      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEFAULT_SET_VM_INT
;
;           DESCRIPTION:    Default set V86 int
;
;           PARAMETERS:         AL              Int #
;                           DX:BX       Segment:offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_set_vm_int      PROC far
    push ax
    push si
    mov si,vm_int_sel
    mov ds,si
    xor ah,ah
    mov si,ax
    shl si,2
    mov [si],bx
    mov [si+2],dx
    pop si
    pop ax
    retf32
default_set_vm_int      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_VM_INT
;
;           DESCRIPTION:    Get V86 interrupt vector
;
;           PARAMETERS:         AL              Int #
;
;           RETURNS:        DX:BX       Segment:offset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vm_int_name DB 'Get VM Int',0

get_vm_int      PROC far
    push ds
    push si
    mov si,int_data_sel
    mov ds,si
    movzx si,al
    shl si,3
    call fword ptr ds:[si].get_vm_int_handlers
    pop si
    pop ds
    retf32
get_vm_int      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_VM_INT
;
;           DESCRIPTION:    Set V86 interrupt vector
;
;           PARAMETERS:         AL              Int #
;                           DX:BX       Segment:offset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_vm_int_name DB 'Set VM Int',0

set_vm_int      PROC far
    push ds
    push si
    mov si,int_data_sel
    mov ds,si
    movzx si,al
    shl si,3
    call fword ptr ds:[si].set_vm_int_handlers
    pop si
    pop ds
    retf32
set_vm_int      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_GET_VM_INT
;
;           DESCRIPTION:    Add GetVmInt hook
;
;           PARAMETERS:     ES:EDI       Callback
;                           AL              Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_get_vm_int_name    DB 'Hook Get VM Int',0

hook_get_vm_int PROC far
    push ds
    push si
    mov si,int_data_sel
    mov ds,si
    movzx si,al
    shl si,3
    mov ds:[si].get_vm_int_handlers,edi
    mov ds:[si+4].get_vm_int_handlers,es
    pop si
    pop ds
    retf32
hook_get_vm_int ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_SET_VM_INT
;
;           DESCRIPTION:    Add SetVmInt hook
;
;           PARAMETERS:     ES:EDI       Callback
;                           AL              Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_set_vm_int_name    DB 'Hook Set VM Int',0

hook_set_vm_int PROC far
    push ds
    push si
    mov si,int_data_sel
    mov ds,si
    movzx si,al
    shl si,3
    mov ds:[si].set_vm_int_handlers,edi
    mov ds:[si+4].set_vm_int_handlers,es
    pop si
    pop ds
    retf32
hook_set_vm_int ENDP

code    ENDS

    END

