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
; TRAPINT.ASM
; Trap gate handling
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
INCLUDE irq.inc

;
seg_es  EQU 0
seg_cs  EQU 1
seg_ss  EQU 2
seg_ds  EQU 3
seg_fs  EQU 4
seg_gs  EQU 5
seg_def EQU 7

op_word     EQU 0
op_byte     EQU 8
op_dword    EQU 10h

adr16   EQU 0
adr32   EQU 20h

code16  EQU 0
code32  EQU 40h

op_extend       EQU 40h

CheckIt MACRO
    local trap_no_stop

;       mov al,[bp].vm_eflags+2
;       test al,2
;       jz trap_no_stop
;       mov ax,[bp].vm_eflags
;       test ax,200h
;       jnz trap_no_stop
;       int 3
trap_no_stop:
        ENDM

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte use16 public 'CODE'

    extrn local_create_int_gate_sel:near
    extrn local_get_selector_base_size:near

    extrn timer_int:near

    extrn get_task_lock:near

    extrn get_thread:near
    extrn prot_exception:near
    extrn virt_exception:near

    extrn do_oscall:near
    extrn do_usercall16:near
    extrn do_usercall32:near
    extrn do_usergate32:near

    assume cs:code

emulate PROC near
    push ax
    mov ax,emulate_opcode_nr
    IsValidOsGate
    pop ax
    jc emulate_exception
;
    EmulateOpcode
    ret

emulate_exception:
    push ax
    mov eax,[bp].vm_eflags
    test eax,20000h
    pop ax
    jnz em_vm
;
    call prot_exception
    ret

em_vm:
    call virt_exception
    ret
emulate ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnterCodePatch
;
;           DESCRIPTION:    Take code-patching spinlock
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_code_patch    Proc near
    push ds
    push ax
;
    mov ax,system_data_sel
    mov ds,ax

enter_lock_loop:
    mov ax,1
    xchg ax,ds:patch_spinlock
    or ax,ax
    jz enter_locked
;
    pause
    jmp enter_lock_loop

enter_locked:     
    pop ax
    pop ds
    ret
enter_code_patch    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LeaveCodePatch
;
;           DESCRIPTION:    Release code-patching spinlock
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_code_patch    Proc near
    push ds
    push ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:patch_spinlock,0
;
    pop ax
    pop ds
    ret
leave_code_patch    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupMpPatch
;
;           DESCRIPTION:    Setup multiprocessor patch support
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetupMpPatch
    
SetupMpPatch    Proc near
    push ds
    push ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:enter_patch_proc,OFFSET enter_code_patch
    mov ds:leave_patch_proc,OFFSET leave_code_patch
;
    pop ax
    pop ds
    ret
SetupMpPatch    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int66, int67
;
;           DESCRIPTION:    Trap handlers for int 66 and 67
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_gate  Proc near
    mov al,0CCh
    mov ds:[ebx],al
    ret
dummy_gate  Endp

int_call_tab:
ict00   DW OFFSET dummy_gate
ict01   DW OFFSET do_usercall16
ict02   DW OFFSET do_oscall
ict03   DW OFFSET do_usercall32

int66:
int67:
    sub sp,8
    push ebp
    mov bp,sp
    push ds
    push es
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    call ds:enter_patch_proc
;
    mov ds,[bp+16]
    mov ebx,[bp+12]
    sub ebx,2
    mov al,ds:[ebx]
    cmp al,0CDh
    jne int_retry    
;
    mov si,ds:[ebx+7]
    cmp si,4
    jb int_call
;
    xor si,si

int_call:    
    add si,si
    call word ptr cs:[si].int_call_tab    
;
    mov ax,system_data_sel
    mov ds,ax
    call ds:leave_patch_proc
;        
    popad
    pop es
    pop ds     
    pop ebp
    iretd

int_retry:
    mov ax,system_data_sel
    mov ds,ax
    call ds:leave_patch_proc
    mov [bp+12],ebx
;    
    popad
    pop es
    pop ds
    pop ebp
    add sp,8
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           int9A
;
;           DESCRIPTION:    Trap handlers for int 9A
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int_gate_tab:
igt00   DW OFFSET dummy_gate
igt01   DW OFFSET dummy_gate
igt02   DW OFFSET dummy_gate
igt03   DW OFFSET do_usergate32

int9A:
    sub sp,8
    push ebp
    mov bp,sp
    push ds
    push es
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    EnterSection ds:patch_section
;
    mov ds,[bp+16]
    mov ebx,[bp+12]
    sub ebx,2
    mov [bp+12],ebx
    mov al,ds:[ebx]
    cmp al,0CDh
    jne intg_retry    
;
    mov si,ds:[ebx+6]
    cmp si,4
    jb intg_call
;
    xor si,si

intg_call:    
    add si,si
    call word ptr cs:[si].int_gate_tab    

intg_retry:
    mov ax,system_data_sel
    mov ds,ax
    LeaveSection ds:patch_section
;    
    popad
    pop es
    pop ds
    pop ebp
    add sp,8
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_0
;
;           DESCRIPTION:    Divide by zero
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_0:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,0
    mov ds:p_fault_code,0
    xor ax,ax
    mov ds,ax
    mov al,0
    call emulate
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_1
;
;           DESCRIPTION:    Single step
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_1:
    push dword ptr 0
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
;
    call get_task_lock
    add ax,1
    jnc t1_ret
;    
    GetThread
    or ax,ax
    jz t1_ret
;    
    mov ds,ax
    mov ds:p_fault_vector,1
    mov ds:p_fault_code,0
    sti
;
    xor ax,ax
    mov ds,ax
    mov eax,[bp].vm_eflags
    or eax,10100h
    mov [bp].vm_eflags,eax
    test eax,20000h
    jnz t1_vm
;
    mov al,1
    call prot_exception
    jmp t1_ret

t1_vm:
    mov al,1
    call virt_exception
    
t1_ret:
    pop ds
    pop ebx
    pop eax
    cli
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_2
;
;           DESCRIPTION:    NMI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_2:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,2
    mov ds:p_fault_code,0
    xor ax,ax
    mov ds,ax
    mov al,2
    test byte ptr [bp+2].vm_eflags,2
    jnz t2_vm
    call prot_exception
    jmp t2_ret
t2_vm:
    call virt_exception
t2_ret:
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_3
;
;           DESCRIPTION:    Breakpoint
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_3:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,3
    mov ds:p_fault_code,0
    xor ax,ax
    mov ds,ax
    mov eax,[bp].vm_eflags
    test eax,20000h
    jnz t3_vm
;
    mov al,3
    call prot_exception
    jmp t3_ret
t3_vm:
    mov al,3
    call virt_exception
t3_ret:
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_4
;
;           DESCRIPTION:    INTO
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_4:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,4
    mov ds:p_fault_code,0
    mov al,4
    call emulate
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_5
;
;           DESCRIPTION:    BOUND
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


trap_5:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,5
    mov ds:p_fault_code,0
    mov al,5
    call emulate
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_6
;
;           DESCRIPTION:    Invalid instruction
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    extrn translate_vm_reflect:near
    extrn translate_pm16_reflect:near
    extrn translate_pm32_reflect:near
    extrn default_exception16:near
    extrn break_exception16:near
    extrn default_exception32:near
    extrn break_exception32:near

    extrn do_usergate_vm:near

    extrn reflect_end:near
    extrn sim16_end:near
    extrn sim32_end:near
    extrn vm_callback16:near
    extrn pm_callback16:near
    extrn vm_callback32:near
    extrn pm_callback32:near
    extrn reflect_pm_to_vm_done:near
    extrn call_vm_ret:near
    extrn call_pm16_ret:near
    extrn call_pm32_ret:near

emulate_6:
    mov al,6
    jmp emulate

enter_dpmi      PROC near
    EnterDpmi
    ret
enter_dpmi      ENDP

vm_call_tab:
vm_00   DW OFFSET emulate_6,            OFFSET emulate_6
vm_02   DW OFFSET emulate_6,            OFFSET emulate_6
vm_04   DW OFFSET emulate_6,            OFFSET emulate_6
vm_06   DW OFFSET emulate_6,            OFFSET emulate_6
vm_08   DW OFFSET emulate_6,            OFFSET emulate_6
vm_0A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_0C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_0E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_10   DW OFFSET reflect_end,          OFFSET sim16_end
vm_12   DW OFFSET sim32_end,            OFFSET vm_callback16
vm_14   DW OFFSET vm_callback32,        OFFSET reflect_pm_to_vm_done
vm_16   DW OFFSET emulate_6,            OFFSET emulate_6
vm_18   DW OFFSET irq_vm,                   OFFSET emulate_6
vm_1A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_1C   DW OFFSET call_vm_ret,          OFFSET emulate_6
vm_1E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_20   DW OFFSET emulate_6,            OFFSET emulate_6
vm_22   DW OFFSET emulate_6,            OFFSET emulate_6
vm_24   DW OFFSET emulate_6,            OFFSET emulate_6
vm_26   DW OFFSET emulate_6,            OFFSET emulate_6
vm_28   DW OFFSET emulate_6,            OFFSET emulate_6
vm_2A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_2C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_2E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_30   DW OFFSET emulate_6,            OFFSET emulate_6
vm_32   DW OFFSET emulate_6,            OFFSET emulate_6
vm_34   DW OFFSET emulate_6,            OFFSET emulate_6
vm_36   DW OFFSET emulate_6,            OFFSET emulate_6
vm_38   DW OFFSET emulate_6,            OFFSET emulate_6
vm_3A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_3C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_3E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_40   DW OFFSET emulate_6,            OFFSET emulate_6
vm_42   DW OFFSET emulate_6,            OFFSET emulate_6
vm_44   DW OFFSET emulate_6,            OFFSET emulate_6
vm_46   DW OFFSET emulate_6,            OFFSET emulate_6
vm_48   DW OFFSET emulate_6,            OFFSET emulate_6
vm_4A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_4C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_4E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_50   DW OFFSET emulate_6,            OFFSET emulate_6
vm_52   DW OFFSET emulate_6,            OFFSET emulate_6
vm_54   DW OFFSET emulate_6,            OFFSET emulate_6
vm_56   DW OFFSET emulate_6,            OFFSET emulate_6
vm_58   DW OFFSET emulate_6,            OFFSET emulate_6
vm_5A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_5C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_5E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_60   DW OFFSET emulate_6,            OFFSET emulate_6
vm_62   DW OFFSET emulate_6,            OFFSET emulate_6
vm_64   DW OFFSET emulate_6,            OFFSET emulate_6
vm_66   DW OFFSET emulate_6,            OFFSET emulate_6
vm_68   DW OFFSET emulate_6,            OFFSET emulate_6
vm_6A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_6C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_6E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_70   DW OFFSET emulate_6,            OFFSET emulate_6
vm_72   DW OFFSET emulate_6,            OFFSET emulate_6
vm_74   DW OFFSET emulate_6,            OFFSET emulate_6
vm_76   DW OFFSET emulate_6,            OFFSET emulate_6
vm_78   DW OFFSET emulate_6,            OFFSET emulate_6
vm_7A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_7C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_7E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_80   DW OFFSET emulate_6,            OFFSET emulate_6
vm_82   DW OFFSET emulate_6,            OFFSET emulate_6
vm_84   DW OFFSET emulate_6,            OFFSET emulate_6
vm_86   DW OFFSET emulate_6,            OFFSET emulate_6
vm_88   DW OFFSET emulate_6,            OFFSET emulate_6
vm_8A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_8C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_8E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_90   DW OFFSET emulate_6,            OFFSET emulate_6
vm_92   DW OFFSET emulate_6,            OFFSET emulate_6
vm_94   DW OFFSET emulate_6,            OFFSET emulate_6
vm_96   DW OFFSET emulate_6,            OFFSET emulate_6
vm_98   DW OFFSET emulate_6,            OFFSET emulate_6
vm_9A   DW OFFSET emulate_6,            OFFSET emulate_6
vm_9C   DW OFFSET emulate_6,            OFFSET emulate_6
vm_9E   DW OFFSET emulate_6,            OFFSET emulate_6
vm_A0   DW OFFSET emulate_6,            OFFSET emulate_6
vm_A2   DW OFFSET emulate_6,            OFFSET emulate_6
vm_A4   DW OFFSET emulate_6,            OFFSET emulate_6
vm_A6   DW OFFSET emulate_6,            OFFSET emulate_6
vm_A8   DW OFFSET emulate_6,            OFFSET emulate_6
vm_AA   DW OFFSET emulate_6,            OFFSET emulate_6
vm_AC   DW OFFSET emulate_6,            OFFSET emulate_6
vm_AE   DW OFFSET emulate_6,            OFFSET emulate_6
vm_B0   DW OFFSET emulate_6,            OFFSET emulate_6
vm_B2   DW OFFSET emulate_6,            OFFSET emulate_6
vm_B4   DW OFFSET emulate_6,            OFFSET emulate_6
vm_B6   DW OFFSET emulate_6,            OFFSET emulate_6
vm_B8   DW OFFSET emulate_6,            OFFSET emulate_6
vm_BA   DW OFFSET emulate_6,            OFFSET emulate_6
vm_BC   DW OFFSET emulate_6,            OFFSET emulate_6
vm_BE   DW OFFSET emulate_6,            OFFSET emulate_6
vm_C0   DW OFFSET emulate_6,            OFFSET emulate_6
vm_C2   DW OFFSET emulate_6,            OFFSET emulate_6
vm_C4   DW OFFSET emulate_6,            OFFSET emulate_6
vm_C6   DW OFFSET emulate_6,            OFFSET emulate_6
vm_C8   DW OFFSET emulate_6,            OFFSET emulate_6
vm_CA   DW OFFSET emulate_6,            OFFSET emulate_6
vm_CC   DW OFFSET emulate_6,            OFFSET emulate_6
vm_CE   DW OFFSET emulate_6,            OFFSET emulate_6
vm_D0   DW OFFSET emulate_6,            OFFSET emulate_6
vm_D2   DW OFFSET emulate_6,            OFFSET emulate_6
vm_D4   DW OFFSET emulate_6,            OFFSET emulate_6
vm_D6   DW OFFSET do_usergate_vm,       OFFSET emulate_6
vm_D8   DW OFFSET emulate_6,            OFFSET emulate_6
vm_DA   DW OFFSET emulate_6,            OFFSET emulate_6
vm_DC   DW OFFSET emulate_6,            OFFSET emulate_6
vm_DE   DW OFFSET emulate_6,            OFFSET emulate_6
vm_E0   DW OFFSET emulate_6,            OFFSET emulate_6
vm_E2   DW OFFSET emulate_6,            OFFSET emulate_6
vm_E4   DW OFFSET emulate_6,            OFFSET emulate_6
vm_E6   DW OFFSET emulate_6,            OFFSET emulate_6
vm_E8   DW OFFSET emulate_6,            OFFSET emulate_6
vm_EA   DW OFFSET emulate_6,            OFFSET emulate_6
vm_EC   DW OFFSET emulate_6,            OFFSET emulate_6
vm_EE   DW OFFSET emulate_6,            OFFSET emulate_6
vm_F0   DW OFFSET emulate_6,            OFFSET translate_vm_reflect
vm_F2   DW OFFSET emulate_6,        OFFSET emulate_6
vm_F4   DW OFFSET emulate_6,            OFFSET emulate_6
vm_F6   DW OFFSET emulate_6,            OFFSET enter_dpmi
vm_F8   DW OFFSET emulate_6,            OFFSET emulate_6
vm_FA   DW OFFSET emulate_6,            OFFSET emulate_6
vm_FC   DW OFFSET emulate_6,            OFFSET emulate_6
vm_FE   DW OFFSET emulate_6,            OFFSET emulate_6

pm16_call_tab:
pm16_00 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_02 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_04 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_06 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_08 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_0A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_0C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_0E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_10 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_12 DW OFFSET emulate_6,            OFFSET pm_callback16
pm16_14 DW OFFSET pm_callback32,        OFFSET emulate_6
pm16_16 DW OFFSET translate_pm16_reflect,OFFSET translate_pm32_reflect
pm16_18 DW OFFSET emulate_6,            OFFSET irq_pm16
pm16_1A DW OFFSET irq_pm32,                 OFFSET emulate_6
pm16_1C DW OFFSET call_pm16_ret,        OFFSET call_pm32_ret
pm16_1E DW OFFSET default_exception16,  OFFSET break_exception16
pm16_20 DW OFFSET default_exception32,  OFFSET break_exception32
pm16_22 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_24 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_26 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_28 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_2A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_2C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_2E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_30 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_32 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_34 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_36 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_38 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_3A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_3C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_3E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_40 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_42 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_44 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_46 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_48 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_4A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_4C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_4E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_50 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_52 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_54 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_56 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_58 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_5A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_5C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_5E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_60 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_62 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_64 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_66 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_68 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_6A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_6C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_6E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_70 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_72 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_74 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_76 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_78 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_7A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_7C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_7E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_80 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_82 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_84 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_86 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_88 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_8A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_8C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_8E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_90 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_92 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_94 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_96 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_98 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_9A DW OFFSET emulate_6,            OFFSET emulate_6
pm16_9C DW OFFSET emulate_6,            OFFSET emulate_6
pm16_9E DW OFFSET emulate_6,            OFFSET emulate_6
pm16_A0 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_A2 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_A4 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_A6 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_A8 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_AA DW OFFSET emulate_6,            OFFSET emulate_6
pm16_AC DW OFFSET emulate_6,            OFFSET emulate_6
pm16_AE DW OFFSET emulate_6,            OFFSET emulate_6
pm16_B0 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_B2 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_B4 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_B6 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_B8 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_BA DW OFFSET emulate_6,            OFFSET emulate_6
pm16_BC DW OFFSET emulate_6,            OFFSET emulate_6
pm16_BE DW OFFSET emulate_6,            OFFSET emulate_6
pm16_C0 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_C2 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_C4 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_C6 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_C8 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_CA DW OFFSET emulate_6,            OFFSET emulate_6
pm16_CC DW OFFSET emulate_6,            OFFSET emulate_6
pm16_CE DW OFFSET emulate_6,            OFFSET emulate_6
pm16_D0 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_D2 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_D4 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_D6 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_D8 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_DA DW OFFSET emulate_6,            OFFSET emulate_6
pm16_DC DW OFFSET emulate_6,            OFFSET emulate_6
pm16_DE DW OFFSET emulate_6,            OFFSET emulate_6
pm16_E0 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_E2 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_E4 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_E6 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_E8 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_EA DW OFFSET emulate_6,            OFFSET emulate_6
pm16_EC DW OFFSET emulate_6,            OFFSET emulate_6
pm16_EE DW OFFSET emulate_6,            OFFSET emulate_6
pm16_F0 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_F2 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_F4 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_F6 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_F8 DW OFFSET emulate_6,            OFFSET emulate_6
pm16_FA DW OFFSET emulate_6,            OFFSET emulate_6
pm16_FC DW OFFSET emulate_6,            OFFSET emulate_6
pm16_FE DW OFFSET emulate_6,            OFFSET emulate_6

pm32_call_tab:
pm32_00 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_02 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_04 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_06 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_08 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_0A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_0C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_0E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_10 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_12 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_14 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_16 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_18 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_1A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_1C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_1E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_20 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_22 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_24 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_26 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_28 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_2A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_2C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_2E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_30 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_32 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_34 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_36 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_38 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_3A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_3C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_3E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_40 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_42 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_44 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_46 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_48 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_4A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_4C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_4E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_50 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_52 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_54 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_56 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_58 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_5A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_5C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_5E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_60 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_62 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_64 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_66 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_68 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_6A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_6C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_6E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_70 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_72 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_74 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_76 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_78 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_7A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_7C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_7E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_80 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_82 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_84 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_86 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_88 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_8A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_8C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_8E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_90 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_92 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_94 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_96 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_98 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_9A DW OFFSET emulate_6,            OFFSET emulate_6
pm32_9C DW OFFSET emulate_6,            OFFSET emulate_6
pm32_9E DW OFFSET emulate_6,            OFFSET emulate_6
pm32_A0 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_A2 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_A4 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_A6 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_A8 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_AA DW OFFSET emulate_6,            OFFSET emulate_6
pm32_AC DW OFFSET emulate_6,            OFFSET emulate_6
pm32_AE DW OFFSET emulate_6,            OFFSET emulate_6
pm32_B0 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_B2 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_B4 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_B6 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_B8 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_BA DW OFFSET emulate_6,            OFFSET emulate_6
pm32_BC DW OFFSET emulate_6,            OFFSET emulate_6
pm32_BE DW OFFSET emulate_6,            OFFSET emulate_6
pm32_C0 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_C2 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_C4 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_C6 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_C8 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_CA DW OFFSET emulate_6,            OFFSET emulate_6
pm32_CC DW OFFSET emulate_6,            OFFSET emulate_6
pm32_CE DW OFFSET emulate_6,            OFFSET emulate_6
pm32_D0 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_D2 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_D4 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_D6 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_D8 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_DA DW OFFSET emulate_6,            OFFSET emulate_6
pm32_DC DW OFFSET emulate_6,            OFFSET emulate_6
pm32_DE DW OFFSET emulate_6,            OFFSET emulate_6
pm32_E0 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_E2 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_E4 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_E6 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_E8 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_EA DW OFFSET emulate_6,            OFFSET emulate_6
pm32_EC DW OFFSET emulate_6,            OFFSET emulate_6
pm32_EE DW OFFSET emulate_6,            OFFSET emulate_6
pm32_F0 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_F2 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_F4 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_F6 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_F8 DW OFFSET emulate_6,            OFFSET emulate_6
pm32_FA DW OFFSET emulate_6,            OFFSET emulate_6
pm32_FC DW OFFSET emulate_6,            OFFSET emulate_6
pm32_FE DW OFFSET emulate_6,            OFFSET emulate_6

trap_6:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    cld
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,6
    mov ds:p_fault_code,0
;
    xor ax,ax
    mov ds,ax
    test byte ptr [bp+2].vm_eflags,2
    jnz t6_vm
    mov ds,[bp].vm_cs
    mov ebx,[bp].vm_eip
    mov ax,[ebx]
    cmp ax,00B0Fh
    jne emulate_62
    sti
    movzx eax,byte ptr [ebx+2]
    cmp al,66h
    je t6_pm32
    call word ptr cs:[eax*2].pm16_call_tab
    jmp t6_ret
t6_pm32:
    movzx eax,byte ptr [ebx+3]
    call word ptr cs:[eax*2].pm32_call_tab
    jmp t6_ret
emulate_62:
    mov al,6
    call emulate
    jmp t6_ret
t6_vm:
    xor ebx,ebx
    mov bx,[bp].vm_cs
    shl ebx,4
    add ebx,[bp].vm_eip
    mov ax,flat_sel
    mov ds,ax
    mov ax,[ebx]
    cmp ax,00B0Fh
    jne emulate_6
    add ebx,2
    sti
    movzx eax,byte ptr [ebx]
    call word ptr cs:[eax*2].vm_call_tab
t6_ret:
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_7
;
;           DESCRIPTION:    Co-processor fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_7:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,7
    mov ds:p_fault_code,0
    xor ax,ax
    mov ds,ax
    mov eax,cr0
    test al,4
    jz math_real_fpu

math_emulate_fpu:
    mov al,7
    call emulate
    jmp math_done

math_real_fpu:
    GetThread
    mov ds,ax
    mov bx,ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov ax,ds:math_tss
    clts
    cmp ax,bx
    je math_done
;
    mov ds:math_tss,bx
    or ax,ax
    jz math_reload
;
    verr ax
    jnz math_reload
;    
    mov ds,ax
    push bx
    mov bx,OFFSET p_math_control
    db 9Bh, 66h, 0DDh, 37h      ;       32-bit fsave [bx]
    pop bx

math_reload:
    mov ds,bx
    mov bx,OFFSET p_math_control
    db 9Bh, 66h, 0DDh, 27h      ;       32-bit frstor [bx]

math_done:
    pop ds
    pop ebx
    pop eax
    cli
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_9
;
;           DESCRIPTION:    Co-processor overrun error
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_9:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,7
    mov ds:p_fault_code,0
    xor ax,ax
    mov ds,ax
    mov al,9
    call emulate
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_10
;
;           DESCRIPTION:    Invalid TSS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_10:
    sti
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,10
    mov eax,[bp].vm_err
    mov ds:p_fault_code,eax
    xor ax,ax
    mov ds,ax
    mov al,10
    test byte ptr [bp+2].vm_eflags,2
    jnz t10_vm
;
    mov al,10
    call prot_exception
    jmp t10_ret

t10_vm:
    mov al,10
    call emulate

t10_ret:
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_11
;
;           DESCRIPTION:    Segment not present fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


trap_11:
    sti
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,11
    mov eax,[bp].vm_err
    mov ds:p_fault_code,eax
    xor ax,ax
    mov ds,ax
    mov al,11
    test byte ptr [bp+2].vm_eflags,2
    jnz t11_vm
    SegmentNotPresent
    jnc t11_ret
;
    mov al,11
    call prot_exception
    jmp t11_ret

t11_vm:
    mov al,11
    call emulate

t11_ret:
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

segment_not_present_name DB 'Segment Not Present',0

segment_not_present     PROC far
    stc
    ret
segment_not_present     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_12
;
;           DESCRIPTION:    Stack fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_12:
    sti
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    GetThread
    or ax,ax
    jnz t12_thread
;
    CrashFault

t12_thread:
    mov ds,ax
    mov ds:p_fault_vector,12
    mov eax,[bp].vm_err
    mov ds:p_fault_code,eax
    xor ax,ax
    mov ds,ax
    mov al,11
    test byte ptr [bp+2].vm_eflags,2
    jnz t11_vm
;
    mov al,12
    call prot_exception
    jmp t12_ret

t12_vm:
    mov al,12
    call emulate

t12_ret:
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_13
;
;           DESCRIPTION:    General protection fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_13:
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
;
    mov ax,system_data_sel
    mov ds,ax
    call ds:enter_patch_proc
;
    test byte ptr [bp+2].vm_eflags,2
    jnz t13_default
;    
    mov ds,[bp].vm_cs
    mov ebx,[bp].vm_eip
    mov al,[ebx]
;
    cmp al,0CDh
    jne t13_not_int
;
    mov al,[ebx+1]
    cmp al,66h
    je t13_retry
;
    cmp al,67h
    je t13_retry
;
    cmp al,9Ah
    je t13_retry
;
    jmp t13_default        
        
t13_not_int:
    cmp al,67h
    jne t13_default
;
    mov al,[ebx+1]
    cmp al,9Ah
    je t13_int_user
;    
    mov al,[ebx+2]
    cmp al,9Ah
    jne t13_default
;
    mov ax,[ebx+7]
    or ax,ax
    jz t13_default
;
    cmp ax,3
    ja t13_default

t13_int_call:
    push ds
    mov ax,system_data_sel
    mov ds,ax
    call ds:leave_patch_proc
    pop ds
;
    push ecx
    push edx
;    
    push ebx
    mov bx,ds
    call local_get_selector_base_size
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov al,0CDh
    xchg al,ds:[ebx]
    pop edx
    pop ecx
    jmp t13_end

t13_int_user:
    mov ax,[ebx+6]
    or ax,ax
    jz t13_default
;
    cmp ax,3
    ja t13_default
;
    push ds
    mov ax,system_data_sel
    mov ds,ax
    call ds:leave_patch_proc
    pop ds
;
    push ecx
    push edx
;    
    push ebx
    mov bx,ds
    call local_get_selector_base_size
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov al,0CDh
    xchg al,ds:[ebx]
    pop edx
    pop ecx
    jmp t13_end

t13_default:
    mov ax,system_data_sel
    mov ds,ax
    call ds:leave_patch_proc
;
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,13
    mov eax,[bp].vm_err
    mov ds:p_fault_code,eax
    xor ax,ax
    mov ds,ax
;
    mov al,13
    call emulate
    jmp t13_end

t13_retry:
    mov ax,system_data_sel
    mov ds,ax
    call ds:leave_patch_proc

t13_end:
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_16
;
;           DESCRIPTION:    Co-processor error
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_16:
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    GetThread
    mov ds,ax
    mov ds:p_fault_vector,16
    mov ds:p_fault_code,0
    xor ax,ax
    mov ds,ax
    mov al,16
    call emulate
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SpuriousApic
;
;           DESCRIPTION:    Spurious interrupt from APIC
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

apic_spur:
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DEFAULT_INT1
;
;           DESCRIPTION:    Default int 1
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_int1:
    push ax
    mov al,20h
    out INT0_CONTROL,al
    pop ax
    iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DEFAULT_INT2
;
;           DESCRIPTION:    Default int 2
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_int2:
    push ax
    mov al,20h
    out INT0_CONTROL,al
    jmp short $+2
    out INT1_CONTROL,al
    pop ax
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_IDT_TRAPS
;
;           DESCRIPTION:    Install all trap-gates
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_trap_gates_name    DB 'Init Trap Gates', 0

idt_trap_tab:
;
;               int #   Entry                   Selector        Dpl
;
tg0         DW      0,          OFFSET trap_0,          kernel_code,    0
tg1         DW      1,          OFFSET trap_1,          kernel_code,    0
tg3         DW      3,          OFFSET trap_3,          kernel_code,    0
tg4         DW      4,          OFFSET trap_4,          kernel_code,    0
tg5         DW      5,          OFFSET trap_5,          kernel_code,    0
tg6         DW      6,          OFFSET trap_6,          kernel_code,    0
tg7         DW      7,          OFFSET trap_7,          kernel_code,    0
tg9         DW      9,          OFFSET trap_9,          kernel_code,    0
tg10    DW      10,         OFFSET trap_10,         kernel_code,    0
tg11    DW      11,         OFFSET trap_11,         kernel_code,    0
tg12    DW      12,         OFFSET trap_12,         kernel_code,    0
tg13    DW      13,         OFFSET trap_13,         kernel_code,    0
tg16    DW      16,         OFFSET trap_16,         kernel_code,    0
tg7_end DW      0FFFFh

;
; tabell offsets
;
ig_nr       EQU 0
ig_entry    EQU 2
ig_sel      EQU 4
ig_dpl      EQU 6


init_trap_gates PROC far
    push ds
    pusha
;    
    mov di,OFFSET idt_trap_tab
init_task_trap_next:
    mov ax,cs:[di]
    cmp ax,0FFFFh
    jz init_task_trap_end
    mov ax,cs:[di].ig_sel
    mov ds,ax
    mov al,cs:[di].ig_nr
    mov bl,cs:[di].ig_dpl
    movzx esi,word ptr cs:[di].ig_entry
    CreateIntGateSelector
    add di,8
    jmp init_task_trap_next
init_task_trap_end:
    popa
    pop ds
    retf32
init_trap_gates ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PRETASKING_GATE0, PRETASKING_GATE4
;
;           DESCRIPTION:    Pretasking gates
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pretask0:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,0
    ShutDownPreTask

pretask1:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,1
    ShutDownPreTask

pretask2:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,2
    ShutDownPreTask

pretask3:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,3
    ShutDownPreTask

pretask4:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,4
    ShutDownPreTask

pretask5:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,5
    ShutDownPreTask

pretask6:
    push dword ptr 0
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,6
    ShutDownPreTask

pretask7:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,7
    ShutDownPreTask

pretask8:
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,8
    ShutDownPreTask

pretask9:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,9
    ShutDownPreTask

pretask10:
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,10
    ShutDownPreTask

pretask11:
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,11
    ShutDownPreTask

pretask12:
    sub sp,4
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,12
    ShutDownPreTask

pretask13:
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
;    
    test byte ptr [bp+2].vm_eflags,2
    jnz pretask_gpf_default
;
    mov ds,[bp].vm_cs
    mov ebx,[bp].vm_eip
    mov al,[ebx]
;
    cmp al,0CDh
    jne pretask_gpf_not_int
;
    mov al,[ebx+1]
    cmp al,66h
    je pretask_gpf_reexec
;
    cmp al,67h
    je pretask_gpf_reexec
;
    jmp pretask_gpf_default
        
pretask_gpf_not_int:
    cmp al,67h
    jne pretask_gpf_default
;
    mov al,[ebx+2]
    cmp al,9Ah
    jne pretask_gpf_default
;
    mov ax,[ebx+7]
    or ax,ax
    jz pretask_gpf_default
;
    cmp ax,3
    ja pretask_gpf_default

pretask_kernel_gate:
    push ecx
    push edx
;    
    push ebx
    mov bx,ds
    call local_get_selector_base_size
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov al,0CDh
    xchg al,ds:[ebx]
    pop edx
    pop ecx
    jmp pretask_gpf_reexec

pretask_gpf_default:
    mov al,13
    ShutDownPreTask

pretask_gpf_reexec:
    pop ds
    pop ebx
    pop eax
    and byte ptr [bp+2].vm_eflags, NOT 1
    pop bp
    add sp,4
    iretd

prepaging14:
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,14
    ShutDownPreTask

pretask16:
    push bp
    mov bp,sp
    push eax
    push ebx
    push ds
    mov al,16
    ShutDownPreTask

pretask_int_tab:
;
;               int #   Entry                   Selector        Dpl
;
pg0         DW      0,          OFFSET pretask0,        kernel_code,    0
pg1         DW      1,          OFFSET pretask1,        kernel_code,    0
pg2         DW      2,          OFFSET pretask2,        kernel_code,    0
pg3         DW      3,          OFFSET pretask3,        kernel_code,    0
pg4         DW      4,          OFFSET pretask4,        kernel_code,    0
pg5         DW      5,          OFFSET pretask5,        kernel_code,    0
pg6         DW      6,          OFFSET pretask6,        kernel_code,    0
pg7         DW      7,          OFFSET pretask7,        kernel_code,    0
pg8         DW      8,          OFFSET pretask8,        kernel_code,    0
pg9         DW      9,          OFFSET pretask9,        kernel_code,    0
pg10    DW      10,         OFFSET pretask10,           kernel_code,    0
pg11    DW      11,         OFFSET pretask11,           kernel_code,    0
pg12    DW      12,         OFFSET pretask12,           kernel_code,    0
pg13    DW      13,         OFFSET pretask13,           kernel_code,    0
pg14    DW      14,         OFFSET prepaging14,         kernel_code,    0
pg15    DW      15,         OFFSET apic_spur,           kernel_code,    0
pg16    DW      16,         OFFSET pretask16,           kernel_code,    0
ri0         DW      28h,    OFFSET timer_int,           kernel_code,    0
ri1         DW      29h,    OFFSET default_int1,    kernel_code,    0
ri2         DW      2Ah,    OFFSET default_int1,    kernel_code,    0
ri3         DW      2Bh,    OFFSET default_int1,    kernel_code,    0
ri4         DW      2Ch,    OFFSET default_int1,    kernel_code,    0
ri5         DW      2Dh,    OFFSET default_int1,    kernel_code,    0
ri6         DW      2Eh,    OFFSET default_int1,    kernel_code,    0
ri7         DW      2Fh,    OFFSET default_int1,    kernel_code,    0
ri10    DW      38h,    OFFSET default_int2,    kernel_code,    0
ri11    DW      39h,    OFFSET default_int2,    kernel_code,    0
ri12    DW      3Ah,    OFFSET default_int2,    kernel_code,    0
ri13    DW      3Bh,    OFFSET default_int2,    kernel_code,    0
ri14    DW      3Ch,    OFFSET default_int2,    kernel_code,    0
ri15    DW      3Dh,    OFFSET default_int2,    kernel_code,    0
ri17    DW      3Fh,    OFFSET default_int2,    kernel_code,    0
rg66    DW      66h,    OFFSET int66,           kernel_code,    3
rg67    DW      67h,    OFFSET int67,           kernel_code,    3
rg9A    DW      9Ah,    OFFSET int9A,           kernel_code,    3
pg7_end DW      0FFFFh

    public init_pretask_traps

init_pretask_traps      PROC near
    mov ax,idt_sel
    mov ds,ax
;
    xor bx,bx
    mov cx,100h
init_pretask_zero:
    mov byte ptr [bx+5],0
    add bx,8
    loop init_pretask_zero
;
    mov di,OFFSET pretask_int_tab
init_pretask_next:
    mov ax,cs:[di]
    cmp ax,0FFFFh
    jz init_pretask_end
    mov ax,cs:[di].ig_sel
    mov ds,ax
    mov al,cs:[di].ig_nr
    mov bl,cs:[di].ig_dpl
    movzx esi,word ptr cs:[di].ig_entry
    call local_create_int_gate_sel
    add di,8
    jmp init_pretask_next

init_pretask_end:
    mov ax,system_data_sel
    mov ds,ax
    InitSection ds:patch_section
    ret
init_pretask_traps      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_IDT
;
;           DESCRIPTION:    Move IDT from boot area to kernel area
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_idt

init_idt    Proc near
    push ds
    push es
    pusha
;
    mov bx,idt_sel
    mov ds,bx
    mov ecx,idt_size
    mov eax,idt_size
    mov bx,temp_sel
    AllocateFixedSystemMem
    xor si,si
    xor di,di
    rep movsb
    mov si,bx
    mov di,idt_sel
    mov ax,gdt_sel
    mov ds,ax
    mov es,ax
    movsd
    movsd   
    mov al,[bx+7]
    mov [bx+5],al
    db 66h
    lidt fword ptr [bx]
;
    popa
    pop es
    pop ds
    ret
init_idt    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           irq_offs_table
;
;           description:    Offsets in IRQ table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irq_offs_table:
io00 DW OFFSET irq_arr
io01 DW OFFSET irq_arr + SIZE irq_struc
io02 DW OFFSET irq_arr + 2 * SIZE irq_struc
io03 DW OFFSET irq_arr + 3 * SIZE irq_struc
io04 DW OFFSET irq_arr + 4 * SIZE irq_struc
io05 DW OFFSET irq_arr + 5 * SIZE irq_struc
io06 DW OFFSET irq_arr + 6 * SIZE irq_struc
io07 DW OFFSET irq_arr + 7 * SIZE irq_struc
io08 DW OFFSET irq_arr + 8 * SIZE irq_struc
io09 DW OFFSET irq_arr + 9 * SIZE irq_struc
io0A DW OFFSET irq_arr + 10 * SIZE irq_struc
io0B DW OFFSET irq_arr + 11 * SIZE irq_struc
io0C DW OFFSET irq_arr + 12 * SIZE irq_struc
io0D DW OFFSET irq_arr + 13 * SIZE irq_struc
io0E DW OFFSET irq_arr + 14 * SIZE irq_struc
io0F DW OFFSET irq_arr + 15 * SIZE irq_struc
io10 DW OFFSET irq_arr + 16 * SIZE irq_struc
io11 DW OFFSET irq_arr + 17 * SIZE irq_struc
io12 DW OFFSET irq_arr + 18 * SIZE irq_struc
io13 DW OFFSET irq_arr + 19 * SIZE irq_struc
io14 DW OFFSET irq_arr + 20 * SIZE irq_struc
io15 DW OFFSET irq_arr + 21 * SIZE irq_struc
io16 DW OFFSET irq_arr + 22 * SIZE irq_struc
io17 DW OFFSET irq_arr + 23 * SIZE irq_struc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           request_private_irq_handler
;
;           description:    Request for a private irq handler (non sharable)
;
;           PARAMETERS:     ds              data for handler
;                           al              irq nr
;                           es:edi          handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_private_irq_handler_name DB 'Request Private Irq Handler',0

request_private_irq_handler     Proc far
    push ds
    push ax
    push bx
    push dx
    push si
;    
    mov dx,ds
    movzx bx,al
    mov ax,irq_sys_sel
    mov ds,ax
    mov si,bx
    add si,si
    mov si,word ptr cs:[si].irq_offs_table
    EnterSection ds:[si].usage_section
    mov ds:[si].user_data,dx
    mov ds:[si].user_handler,edi
    mov word ptr ds:[si+4].user_handler,es
;
    mov al,bl
    call ds:[si].irq_enable_proc

rpDone:
    pop si
    pop dx
    pop bx
    pop ax
    pop ds
    retf32
request_private_irq_handler     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SharedIrq
;
;           description:    Shared IRQ handler
;
;           PARAMETERS:     DS  Irq share struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shared_irq  Proc far
    mov cx,ds:share_count
    mov bx,OFFSET share_handler
    or cx,cx
    jz shared_irq_done

shared_irq_loop:
    push ds
    push bx
    push cx
;
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET shared_irq_next
    push eax
    push ds:[bx+4].sh_user_handler
    push ds:[bx].sh_user_handler
    mov ax,ds:[bx].sh_user_data
    mov ds,ax
    retf32

shared_irq_next:
    pop cx
    pop bx
    pop ds
;    
    add bx,SIZE share_handle_struc
    loop shared_irq_loop

shared_irq_done:
    retf32
shared_irq  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           request_shared_irq_handler
;
;           description:    Request for a shared irq handler
;
;           PARAMETERS:     ds              data for handler
;                           al              irq nr
;                           es:edi          handler address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_shared_irq_handler_name DB 'Request Shared Irq Handler',0

request_shared_irq_handler      Proc far
    push ds
    pusha
;
    mov dx,ds
    movzx bx,al
    mov ax,irq_sys_sel
    mov ds,ax
    mov si,bx
    add si,si
    mov si,word ptr cs:[si].irq_offs_table
    mov ax,cs
    cmp ax,word ptr ds:[si+4].user_handler
    jne rsih_req
;       
    mov ax,word ptr ds:[si].user_handler
    cmp ax,OFFSET shared_irq
    je rsih_add

rsih_req:
    push ds
    push es
    push di
;    
    mov eax,SIZE share_struc
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor ax,ax
    rep stosb
;    
    mov ax,es
    mov ds,ax
    mov ax,cs
    mov es,ax
    mov al,bl
    mov edi,OFFSET shared_irq
    RequestPrivateIrqHandler   
;
    pop di
    pop es
    pop ds

rsih_add:
    mov ds,ds:[si].user_data
    mov cx,ds:share_count
    mov ax,cx
    push dx
    mov dx,SIZE share_handle_struc
    mul dx
    pop dx
    mov bx,ax
    add bx,OFFSET share_handler
    mov ds:[bx].sh_user_handler,edi
    mov word ptr ds:[bx+4].sh_user_handler,es
    mov ds:[bx].sh_user_data,dx
    inc cx
    mov ds:share_count,cx
;
    popa
    pop ds
    retf32
request_shared_irq_handler      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           is_irq_free
;
;           description:    Check if IRQ can be reserved
;
;           PARAMETERS:         al              irq nr
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_irq_free_name DB 'Is Irq Free',0

is_irq_free     Proc far
    push ds
    push ax
    push si
;
    movzx si,al
    mov ax,irq_sys_sel
    mov ds,ax
    add si,si
    mov si,word ptr cs:[si].irq_offs_table
    mov ax,ds:[si].usage_section.cs_value
    or ax,ax
    clc
    jz is_irq_free_done
;
    stc

is_irq_free_done:
    pop si
    pop ax
    pop ds
    retf32
is_irq_free     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           release_private_irq_handler
;
;           description:    Release a no shareable irq handler
;
;           PARAMETERS:         al              irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

release_private_irq_handler_name    DB 'Release Private Irq Handler',0

release_private_irq_handler     Proc far
    push ds
    push ax
    push bx
    push dx
;       
    movzx bx,al
    mov dx,irq_sys_sel
    mov ds,dx
    add bx,bx
    mov bx,word ptr cs:[bx].irq_offs_table
    call ds:[bx].irq_disable_proc
    LeaveSection ds:[bx].usage_section
;
    pop dx
    pop bx
    pop ax
    pop ds
    retf32
release_private_irq_handler     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setup_irq_detect
;
;           description:    Setup IRQ detect
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_irq_detect_name   DB 'Setup IRQ detect',0

setup_irq_detect    Proc far
    push ds
    push ax
;       
    mov ax,irq_sys_sel
    mov ds,ax
    mov ds:bad_irqs,0
;       
    call ds:irq_detect_proc
;
    Swap
    Swap
;
    mov ds:bad_irqs,0       
;
    pop ax
    pop ds
    retf32
setup_irq_detect    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           poll_irq_detect
;
;           description:    Poll detected IRQs
;
;       RETURNS:    EAX      Detected IRQs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_irq_detect_name    DB 'Poll IRQ detect',0

poll_irq_detect Proc far
    push ds
;       
    mov ax,irq_sys_sel
    mov ds,ax
    mov eax,ds:bad_irqs
;
    pop ds
    retf32
poll_irq_detect Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DummyEnable
;
;           DESCRIPTION:    Dummy enable IRQ
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_enable    Proc far
    ret
dummy_enable    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DummyDisable
;
;           DESCRIPTION:    Dummy disable IRQ
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_disable    Proc far
    ret
dummy_disable    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DummyDetect
;
;           DESCRIPTION:    Dummy detect IRQ
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dummy_detect    Proc far
    ret
dummy_detect    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_TRAP_VECTORS
;
;           DESCRIPTION:    Init default software ints
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irq_vm_0:
    IrqVm 0

irq_vm:
    int 3

irq_pm16_0:
    IrqProt16 0

irq_pm16:
    int 3

irq_pm32_0:
    IrqProt32 0

irq_pm32:
    int 3

    extrn vm_exception_handler:near
    extrn pm_exception_handler:near

    public init_trap_vectors

init_trap_vectors       PROC near
    xor eax,eax
    mov ax,SIZE irq_proc_seg
    mov bx,irq_proc_sel
    AllocateFixedProcessMem
;
    xor eax,eax
    mov ax,SIZE irq_sys_seg
    mov bx,irq_sys_sel
    AllocateFixedSystemMem
    mov ds,bx
;       
    mov word ptr ds:irq_detect_proc,OFFSET dummy_detect
    mov word ptr ds:irq_detect_proc+2,cs
;
    xor esi,esi
    mov cx,32
    mov bx,OFFSET irq_arr

init_irq_loop:
    mov ds:[bx].user_handler,0
    mov ds:[bx+4].user_handler,0
    mov ds:[bx].user_data,0
    InitSection ds:[bx].usage_section
;
    mov word ptr ds:[bx].irq_enable_proc,OFFSET dummy_enable
    mov word ptr ds:[bx].irq_enable_proc+2,cs
;
    mov word ptr ds:[bx].irq_disable_proc,OFFSET dummy_disable
    mov word ptr ds:[bx].irq_disable_proc+2,cs
;
    add bx,SIZE irq_struc
    loop init_irq_loop
;
    mov bx,OFFSET irq_arr
    EnterSection ds:[bx].usage_section
    add bx,2 * SIZE irq_struc
    EnterSection ds:[bx].usage_section
;
    xor cx,cx
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET vm_exception_handler
    mov al,0
    HookVMInt
    mov al,1
    HookVMInt
    mov al,3
    HookVMInt
    mov al,4
    HookVMInt
    mov al,5
    HookVMInt
    mov al,6
    HookVMInt
    mov al,8
    HookVMInt
    mov al,9
    HookVMInt
    mov al,11
    HookVMInt
    mov al,12
    HookVMInt
    mov al,13
    HookVMInt
;
    mov edi,OFFSET pm_exception_handler
    mov al,3
    HookProt16Int
;
    mov edi,OFFSET pm_exception_handler
    mov al,3
    HookProt32Int
;
    mov esi,OFFSET init_trap_gates
    mov edi,OFFSET init_trap_gates_name
    xor cl,cl
    mov ax,init_trap_gates_nr
    RegisterOsGate
;
    mov esi,OFFSET segment_not_present
    mov edi,OFFSET segment_not_present_name
    xor cl,cl
    mov ax,segment_not_present_nr
    RegisterOsGate
;
    mov esi,OFFSET is_irq_free
    mov edi,OFFSET is_irq_free_name
    xor cl,cl
    mov ax,is_irq_free_nr
    RegisterOsGate
;
    mov esi,OFFSET request_private_irq_handler
    mov edi,OFFSET request_private_irq_handler_name
    xor cl,cl
    mov ax,request_private_irq_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET request_shared_irq_handler
    mov edi,OFFSET request_shared_irq_handler_name
    xor cl,cl
    mov ax,request_shared_irq_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET release_private_irq_handler
    mov edi,OFFSET release_private_irq_handler_name
    xor cl,cl
    mov ax,release_private_irq_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_irq_detect
    mov edi,OFFSET setup_irq_detect_name
    xor cl,cl
    mov ax,setup_irq_detect_nr
    RegisterOsGate
;
    mov esi,OFFSET poll_irq_detect
    mov edi,OFFSET poll_irq_detect_name
    xor cl,cl
    mov ax,poll_irq_detect_nr
    RegisterOsGate
    ret
init_trap_vectors       ENDP


code    ENDS

    END
