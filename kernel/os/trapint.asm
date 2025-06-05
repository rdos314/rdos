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
INCLUDE core.inc

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

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte use16 public 'CODE'

    extrn local_create_int_gate_sel:near
    extrn local_create_trap_gate_sel:near
    extrn local_get_selector_base_size:near

    extrn prot_exception:near
    extrn virt_exception:near

    extrn do_oscall:near
    extrn do_user_serv:near
    extrn do_usercall16:near
    extrn do_usercall32:near
    extrn do_usergate32:near

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Inbyte
;
;           description:    read a byte from I/O port
;
;           parameters:     DX              IO PORT
;
;           RETURNS:        AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InByte Proc near
    push bx
    push cx
    push si
;
    mov ax,hook_in_sel
    mov ds,ax
    cmp dx,400h
    jnc in_byte_real
;
    mov bx,dx
    shl bx,3
    mov ax,[bx+4]
    or ax,ax
    jz in_byte_real
;
    push ds
    call fword ptr [bx]
    pop ds
    jmp in_byte_done

in_byte_real:
    in al,dx

in_byte_done:
    pop si
    pop cx
    pop bx
    ret
InByte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OutByte
;
;           description:    write a byte to I/O port
;
;           PARAMETERS:         SS:ebp       CPU
;                           DX              IO PORT
;                           AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutByte Proc near
    push bx
    push cx
    push si
;
    mov bx,hook_out_sel
    mov ds,bx
    cmp dx,400h
    jnc out_byte_real
;
    mov bx,dx
    shl bx,3
    mov cx,[bx+4]
    or cx,cx
    jz out_byte_real
;
    push ds
    call fword ptr [bx]
    pop ds
    jmp out_byte_done

out_byte_real:
    out dx,al

out_byte_done:
    pop si
    pop cx
    pop bx
    ret
OutByte Endp

emulate PROC near
    mov ax,emulate_opcode_nr
    IsValidOsGate
    jc emulate_exception
;
    mov al,[ebp].trap_exc_nr
    EmulateOpcode
    ret

emulate_exception:
    mov eax,[ebp].trap_eflags
    test eax,20000h
    jnz em_vm
;
    call prot_exception
    ret

em_vm:
    mov ax,flat_sel
    mov ds,ax    
    movzx ebx,word ptr [ebp].trap_cs
    shl ebx,4
    add ebx,[ebp].trap_eip
    mov al,[ebx]
;    
    cmp al,0E4h
    jne not_em_in_al
;    
    push dx
    movzx dx,byte ptr [ebx+1]
    call InByte
    pop dx
    mov [ebp].trap_eax,al
    add word ptr [ebp].trap_eip,2  
    ret

not_em_in_al:
    cmp al,0E6h
    jne not_em_out_al
;
    push dx
    movzx dx,byte ptr [ebx+1]
    mov al,[ebp].trap_eax
    call OutByte
    pop dx
    add word ptr [ebp].trap_eip,2  
    ret

not_em_out_al:
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
;           NAME:           SetupSmpPatch
;
;           DESCRIPTION:    Setup multiprocessor patch support
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_smp_patch_name DB 'Setup SMP Patch', 0
    
setup_smp_patch    Proc far
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
    retf32
setup_smp_patch    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyThreadSuspend
;
;           DESCRIPTION:    Notify thread suspend
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_thread_suspend_name DB 'Notify Thread Suspend', 0
    
notify_thread_suspend    Proc far
    mov eax,[ebp].trap_eflags
    or eax,10100h
    mov [ebp].trap_eflags,eax
    test eax,20000h
    jnz tsVm
;
    mov al,1
    call prot_exception
    jmp tsRet

tsVm:
    mov al,1
    call virt_exception

tsRet:
    retf32
notify_thread_suspend   Endp

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
ict04   DW OFFSET dummy_gate

int66:
int67:
    sub esp,8
    push ebp
    mov ebp,esp
    push ds
    push es
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    call ds:enter_patch_proc
;
    mov ds,[ebp+16]
    mov ebx,[ebp+12]
    sub ebx,2
    mov al,ds:[ebx]
    cmp al,0CDh
    jne int_retry    
;
    mov si,ds:[ebx+7]
    cmp si,5
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
    mov [ebp+12],ebx
;    
    popad
    pop es
    pop ds
    pop ebp
    add esp,8
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
igt04   DW OFFSET do_user_serv

int9A:
intE8:
    sub sp,8
    push ebp
    mov ebp,esp
    push ds
    push es
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    EnterSection ds:patch_section
;
    mov ds,[ebp+16]
    mov ebx,[ebp+12]
    sub ebx,2
    mov [ebp+12],ebx
    mov al,ds:[ebx]
    cmp al,0CDh
    jne intg_retry    
;
    mov si,ds:[ebx+6]
    cmp si,5
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
    push ebp
    mov ebp,esp
    sti
    push eax
    push ebx
    mov ax,0
    push ax
    push ds
;
    call emulate
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
;           NAME:           TRAP_1
;
;           DESCRIPTION:    Single step
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_1:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,1
    push ax
    push ds
;
    GetSchedulerLockCounter
    add ax,1
    jnc t1_ret
;    
    GetThread
    or ax,ax
    jz t1_ret
;    
    sti
    mov eax,[ebp].trap_eflags
    or eax,10100h
    mov [ebp].trap_eflags,eax
    test eax,20000h
    jnz t1_vm
;
    call prot_exception
    jmp t1_ret

t1_vm:
    DebugException
    
t1_ret:
    pop eax
    mov ds,ax
    pop ebx
    pop eax
    cli
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
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
    push ebp
    mov ebp,esp
    sti
    push eax
    push ebx
    mov ax,3
    push ax
    push ds
;
    mov eax,[ebp].trap_eflags
    test eax,20000h
    jnz t3_vm
;
    call prot_exception
    jmp t3_ret

t3_vm:
    DebugException
    
t3_ret:
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
;           NAME:           TRAP_4
;
;           DESCRIPTION:    INTO
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_4:
    push dword ptr 0
    push ebp
    mov ebp,esp
    sti
    push eax
    push ebx
    mov ax,4
    push ax
    push ds
;
    call emulate
;    
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
;           NAME:           TRAP_5
;
;           DESCRIPTION:    BOUND
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


trap_5:
    push dword ptr 0
    push ebp
    mov ebp,esp
    sti
    push eax
    push ebx
    mov ax,5
    push ax
    push ds
;
    call emulate
;    
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

enter_dpmi      PROC near
    EnterDpmi
    ret
enter_dpmi      ENDP

vm_call_tab:
vm_00   DW OFFSET emulate,            OFFSET emulate
vm_02   DW OFFSET emulate,            OFFSET emulate
vm_04   DW OFFSET emulate,            OFFSET emulate
vm_06   DW OFFSET emulate,            OFFSET emulate
vm_08   DW OFFSET emulate,            OFFSET emulate
vm_0A   DW OFFSET emulate,            OFFSET emulate
vm_0C   DW OFFSET emulate,            OFFSET emulate
vm_0E   DW OFFSET emulate,            OFFSET emulate
vm_10   DW OFFSET reflect_end,        OFFSET sim16_end
vm_12   DW OFFSET sim32_end,          OFFSET vm_callback16
vm_14   DW OFFSET vm_callback32,      OFFSET reflect_pm_to_vm_done
vm_16   DW OFFSET emulate,            OFFSET emulate
vm_18   DW OFFSET irq_vm,             OFFSET emulate
vm_1A   DW OFFSET emulate,            OFFSET emulate
vm_1C   DW OFFSET call_vm_ret,        OFFSET emulate
vm_1E   DW OFFSET emulate,            OFFSET emulate
vm_20   DW OFFSET emulate,            OFFSET emulate
vm_22   DW OFFSET emulate,            OFFSET emulate
vm_24   DW OFFSET emulate,            OFFSET emulate
vm_26   DW OFFSET emulate,            OFFSET emulate
vm_28   DW OFFSET emulate,            OFFSET emulate
vm_2A   DW OFFSET emulate,            OFFSET emulate
vm_2C   DW OFFSET emulate,            OFFSET emulate
vm_2E   DW OFFSET emulate,            OFFSET emulate
vm_30   DW OFFSET emulate,            OFFSET emulate
vm_32   DW OFFSET emulate,            OFFSET emulate
vm_34   DW OFFSET emulate,            OFFSET emulate
vm_36   DW OFFSET emulate,            OFFSET emulate
vm_38   DW OFFSET emulate,            OFFSET emulate
vm_3A   DW OFFSET emulate,            OFFSET emulate
vm_3C   DW OFFSET emulate,            OFFSET emulate
vm_3E   DW OFFSET emulate,            OFFSET emulate
vm_40   DW OFFSET emulate,            OFFSET emulate
vm_42   DW OFFSET emulate,            OFFSET emulate
vm_44   DW OFFSET emulate,            OFFSET emulate
vm_46   DW OFFSET emulate,            OFFSET emulate
vm_48   DW OFFSET emulate,            OFFSET emulate
vm_4A   DW OFFSET emulate,            OFFSET emulate
vm_4C   DW OFFSET emulate,            OFFSET emulate
vm_4E   DW OFFSET emulate,            OFFSET emulate
vm_50   DW OFFSET emulate,            OFFSET emulate
vm_52   DW OFFSET emulate,            OFFSET emulate
vm_54   DW OFFSET emulate,            OFFSET emulate
vm_56   DW OFFSET emulate,            OFFSET emulate
vm_58   DW OFFSET emulate,            OFFSET emulate
vm_5A   DW OFFSET emulate,            OFFSET emulate
vm_5C   DW OFFSET emulate,            OFFSET emulate
vm_5E   DW OFFSET emulate,            OFFSET emulate
vm_60   DW OFFSET emulate,            OFFSET emulate
vm_62   DW OFFSET emulate,            OFFSET emulate
vm_64   DW OFFSET emulate,            OFFSET emulate
vm_66   DW OFFSET emulate,            OFFSET emulate
vm_68   DW OFFSET emulate,            OFFSET emulate
vm_6A   DW OFFSET emulate,            OFFSET emulate
vm_6C   DW OFFSET emulate,            OFFSET emulate
vm_6E   DW OFFSET emulate,            OFFSET emulate
vm_70   DW OFFSET emulate,            OFFSET emulate
vm_72   DW OFFSET emulate,            OFFSET emulate
vm_74   DW OFFSET emulate,            OFFSET emulate
vm_76   DW OFFSET emulate,            OFFSET emulate
vm_78   DW OFFSET emulate,            OFFSET emulate
vm_7A   DW OFFSET emulate,            OFFSET emulate
vm_7C   DW OFFSET emulate,            OFFSET emulate
vm_7E   DW OFFSET emulate,            OFFSET emulate
vm_80   DW OFFSET emulate,            OFFSET emulate
vm_82   DW OFFSET emulate,            OFFSET emulate
vm_84   DW OFFSET emulate,            OFFSET emulate
vm_86   DW OFFSET emulate,            OFFSET emulate
vm_88   DW OFFSET emulate,            OFFSET emulate
vm_8A   DW OFFSET emulate,            OFFSET emulate
vm_8C   DW OFFSET emulate,            OFFSET emulate
vm_8E   DW OFFSET emulate,            OFFSET emulate
vm_90   DW OFFSET emulate,            OFFSET emulate
vm_92   DW OFFSET emulate,            OFFSET emulate
vm_94   DW OFFSET emulate,            OFFSET emulate
vm_96   DW OFFSET emulate,            OFFSET emulate
vm_98   DW OFFSET emulate,            OFFSET emulate
vm_9A   DW OFFSET emulate,            OFFSET emulate
vm_9C   DW OFFSET emulate,            OFFSET emulate
vm_9E   DW OFFSET emulate,            OFFSET emulate
vm_A0   DW OFFSET emulate,            OFFSET emulate
vm_A2   DW OFFSET emulate,            OFFSET emulate
vm_A4   DW OFFSET emulate,            OFFSET emulate
vm_A6   DW OFFSET emulate,            OFFSET emulate
vm_A8   DW OFFSET emulate,            OFFSET emulate
vm_AA   DW OFFSET emulate,            OFFSET emulate
vm_AC   DW OFFSET emulate,            OFFSET emulate
vm_AE   DW OFFSET emulate,            OFFSET emulate
vm_B0   DW OFFSET emulate,            OFFSET emulate
vm_B2   DW OFFSET emulate,            OFFSET emulate
vm_B4   DW OFFSET emulate,            OFFSET emulate
vm_B6   DW OFFSET emulate,            OFFSET emulate
vm_B8   DW OFFSET emulate,            OFFSET emulate
vm_BA   DW OFFSET emulate,            OFFSET emulate
vm_BC   DW OFFSET emulate,            OFFSET emulate
vm_BE   DW OFFSET emulate,            OFFSET emulate
vm_C0   DW OFFSET emulate,            OFFSET emulate
vm_C2   DW OFFSET emulate,            OFFSET emulate
vm_C4   DW OFFSET emulate,            OFFSET emulate
vm_C6   DW OFFSET emulate,            OFFSET emulate
vm_C8   DW OFFSET emulate,            OFFSET emulate
vm_CA   DW OFFSET emulate,            OFFSET emulate
vm_CC   DW OFFSET emulate,            OFFSET emulate
vm_CE   DW OFFSET emulate,            OFFSET emulate
vm_D0   DW OFFSET emulate,            OFFSET emulate
vm_D2   DW OFFSET emulate,            OFFSET emulate
vm_D4   DW OFFSET emulate,            OFFSET emulate
vm_D6   DW OFFSET do_usergate_vm,     OFFSET emulate
vm_D8   DW OFFSET emulate,            OFFSET emulate
vm_DA   DW OFFSET emulate,            OFFSET emulate
vm_DC   DW OFFSET emulate,            OFFSET emulate
vm_DE   DW OFFSET emulate,            OFFSET emulate
vm_E0   DW OFFSET emulate,            OFFSET emulate
vm_E2   DW OFFSET emulate,            OFFSET emulate
vm_E4   DW OFFSET emulate,            OFFSET emulate
vm_E6   DW OFFSET emulate,            OFFSET emulate
vm_E8   DW OFFSET emulate,            OFFSET emulate
vm_EA   DW OFFSET emulate,            OFFSET emulate
vm_EC   DW OFFSET emulate,            OFFSET emulate
vm_EE   DW OFFSET emulate,            OFFSET emulate
vm_F0   DW OFFSET emulate,            OFFSET translate_vm_reflect
vm_F2   DW OFFSET emulate,            OFFSET emulate
vm_F4   DW OFFSET emulate,            OFFSET emulate
vm_F6   DW OFFSET emulate,            OFFSET enter_dpmi
vm_F8   DW OFFSET emulate,            OFFSET emulate
vm_FA   DW OFFSET emulate,            OFFSET emulate
vm_FC   DW OFFSET emulate,            OFFSET emulate
vm_FE   DW OFFSET emulate,            OFFSET emulate

pm16_call_tab:
pm16_00 DW OFFSET emulate,            OFFSET emulate
pm16_02 DW OFFSET emulate,            OFFSET emulate
pm16_04 DW OFFSET emulate,            OFFSET emulate
pm16_06 DW OFFSET emulate,            OFFSET emulate
pm16_08 DW OFFSET emulate,            OFFSET emulate
pm16_0A DW OFFSET emulate,            OFFSET emulate
pm16_0C DW OFFSET emulate,            OFFSET emulate
pm16_0E DW OFFSET emulate,            OFFSET emulate
pm16_10 DW OFFSET emulate,            OFFSET emulate
pm16_12 DW OFFSET emulate,            OFFSET pm_callback16
pm16_14 DW OFFSET pm_callback32,      OFFSET emulate
pm16_16 DW OFFSET translate_pm16_reflect,OFFSET translate_pm32_reflect
pm16_18 DW OFFSET emulate,            OFFSET irq_pm16
pm16_1A DW OFFSET irq_pm32,           OFFSET emulate
pm16_1C DW OFFSET call_pm16_ret,      OFFSET call_pm32_ret
pm16_1E DW OFFSET default_exception16,OFFSET break_exception16
pm16_20 DW OFFSET default_exception32,OFFSET break_exception32
pm16_22 DW OFFSET emulate,            OFFSET emulate
pm16_24 DW OFFSET emulate,            OFFSET emulate
pm16_26 DW OFFSET emulate,            OFFSET emulate
pm16_28 DW OFFSET emulate,            OFFSET emulate
pm16_2A DW OFFSET emulate,            OFFSET emulate
pm16_2C DW OFFSET emulate,            OFFSET emulate
pm16_2E DW OFFSET emulate,            OFFSET emulate
pm16_30 DW OFFSET emulate,            OFFSET emulate
pm16_32 DW OFFSET emulate,            OFFSET emulate
pm16_34 DW OFFSET emulate,            OFFSET emulate
pm16_36 DW OFFSET emulate,            OFFSET emulate
pm16_38 DW OFFSET emulate,            OFFSET emulate
pm16_3A DW OFFSET emulate,            OFFSET emulate
pm16_3C DW OFFSET emulate,            OFFSET emulate
pm16_3E DW OFFSET emulate,            OFFSET emulate
pm16_40 DW OFFSET emulate,            OFFSET emulate
pm16_42 DW OFFSET emulate,            OFFSET emulate
pm16_44 DW OFFSET emulate,            OFFSET emulate
pm16_46 DW OFFSET emulate,            OFFSET emulate
pm16_48 DW OFFSET emulate,            OFFSET emulate
pm16_4A DW OFFSET emulate,            OFFSET emulate
pm16_4C DW OFFSET emulate,            OFFSET emulate
pm16_4E DW OFFSET emulate,            OFFSET emulate
pm16_50 DW OFFSET emulate,            OFFSET emulate
pm16_52 DW OFFSET emulate,            OFFSET emulate
pm16_54 DW OFFSET emulate,            OFFSET emulate
pm16_56 DW OFFSET emulate,            OFFSET emulate
pm16_58 DW OFFSET emulate,            OFFSET emulate
pm16_5A DW OFFSET emulate,            OFFSET emulate
pm16_5C DW OFFSET emulate,            OFFSET emulate
pm16_5E DW OFFSET emulate,            OFFSET emulate
pm16_60 DW OFFSET emulate,            OFFSET emulate
pm16_62 DW OFFSET emulate,            OFFSET emulate
pm16_64 DW OFFSET emulate,            OFFSET emulate
pm16_66 DW OFFSET emulate,            OFFSET emulate
pm16_68 DW OFFSET emulate,            OFFSET emulate
pm16_6A DW OFFSET emulate,            OFFSET emulate
pm16_6C DW OFFSET emulate,            OFFSET emulate
pm16_6E DW OFFSET emulate,            OFFSET emulate
pm16_70 DW OFFSET emulate,            OFFSET emulate
pm16_72 DW OFFSET emulate,            OFFSET emulate
pm16_74 DW OFFSET emulate,            OFFSET emulate
pm16_76 DW OFFSET emulate,            OFFSET emulate
pm16_78 DW OFFSET emulate,            OFFSET emulate
pm16_7A DW OFFSET emulate,            OFFSET emulate
pm16_7C DW OFFSET emulate,            OFFSET emulate
pm16_7E DW OFFSET emulate,            OFFSET emulate
pm16_80 DW OFFSET emulate,            OFFSET emulate
pm16_82 DW OFFSET emulate,            OFFSET emulate
pm16_84 DW OFFSET emulate,            OFFSET emulate
pm16_86 DW OFFSET emulate,            OFFSET emulate
pm16_88 DW OFFSET emulate,            OFFSET emulate
pm16_8A DW OFFSET emulate,            OFFSET emulate
pm16_8C DW OFFSET emulate,            OFFSET emulate
pm16_8E DW OFFSET emulate,            OFFSET emulate
pm16_90 DW OFFSET emulate,            OFFSET emulate
pm16_92 DW OFFSET emulate,            OFFSET emulate
pm16_94 DW OFFSET emulate,            OFFSET emulate
pm16_96 DW OFFSET emulate,            OFFSET emulate
pm16_98 DW OFFSET emulate,            OFFSET emulate
pm16_9A DW OFFSET emulate,            OFFSET emulate
pm16_9C DW OFFSET emulate,            OFFSET emulate
pm16_9E DW OFFSET emulate,            OFFSET emulate
pm16_A0 DW OFFSET emulate,            OFFSET emulate
pm16_A2 DW OFFSET emulate,            OFFSET emulate
pm16_A4 DW OFFSET emulate,            OFFSET emulate
pm16_A6 DW OFFSET emulate,            OFFSET emulate
pm16_A8 DW OFFSET emulate,            OFFSET emulate
pm16_AA DW OFFSET emulate,            OFFSET emulate
pm16_AC DW OFFSET emulate,            OFFSET emulate
pm16_AE DW OFFSET emulate,            OFFSET emulate
pm16_B0 DW OFFSET emulate,            OFFSET emulate
pm16_B2 DW OFFSET emulate,            OFFSET emulate
pm16_B4 DW OFFSET emulate,            OFFSET emulate
pm16_B6 DW OFFSET emulate,            OFFSET emulate
pm16_B8 DW OFFSET emulate,            OFFSET emulate
pm16_BA DW OFFSET emulate,            OFFSET emulate
pm16_BC DW OFFSET emulate,            OFFSET emulate
pm16_BE DW OFFSET emulate,            OFFSET emulate
pm16_C0 DW OFFSET emulate,            OFFSET emulate
pm16_C2 DW OFFSET emulate,            OFFSET emulate
pm16_C4 DW OFFSET emulate,            OFFSET emulate
pm16_C6 DW OFFSET emulate,            OFFSET emulate
pm16_C8 DW OFFSET emulate,            OFFSET emulate
pm16_CA DW OFFSET emulate,            OFFSET emulate
pm16_CC DW OFFSET emulate,            OFFSET emulate
pm16_CE DW OFFSET emulate,            OFFSET emulate
pm16_D0 DW OFFSET emulate,            OFFSET emulate
pm16_D2 DW OFFSET emulate,            OFFSET emulate
pm16_D4 DW OFFSET emulate,            OFFSET emulate
pm16_D6 DW OFFSET emulate,            OFFSET emulate
pm16_D8 DW OFFSET emulate,            OFFSET emulate
pm16_DA DW OFFSET emulate,            OFFSET emulate
pm16_DC DW OFFSET emulate,            OFFSET emulate
pm16_DE DW OFFSET emulate,            OFFSET emulate
pm16_E0 DW OFFSET emulate,            OFFSET emulate
pm16_E2 DW OFFSET emulate,            OFFSET emulate
pm16_E4 DW OFFSET emulate,            OFFSET emulate
pm16_E6 DW OFFSET emulate,            OFFSET emulate
pm16_E8 DW OFFSET emulate,            OFFSET emulate
pm16_EA DW OFFSET emulate,            OFFSET emulate
pm16_EC DW OFFSET emulate,            OFFSET emulate
pm16_EE DW OFFSET emulate,            OFFSET emulate
pm16_F0 DW OFFSET emulate,            OFFSET emulate
pm16_F2 DW OFFSET emulate,            OFFSET emulate
pm16_F4 DW OFFSET emulate,            OFFSET emulate
pm16_F6 DW OFFSET emulate,            OFFSET emulate
pm16_F8 DW OFFSET emulate,            OFFSET emulate
pm16_FA DW OFFSET emulate,            OFFSET emulate
pm16_FC DW OFFSET emulate,            OFFSET emulate
pm16_FE DW OFFSET emulate,            OFFSET emulate

pm32_call_tab:
pm32_00 DW OFFSET emulate,            OFFSET emulate
pm32_02 DW OFFSET emulate,            OFFSET emulate
pm32_04 DW OFFSET emulate,            OFFSET emulate
pm32_06 DW OFFSET emulate,            OFFSET emulate
pm32_08 DW OFFSET emulate,            OFFSET emulate
pm32_0A DW OFFSET emulate,            OFFSET emulate
pm32_0C DW OFFSET emulate,            OFFSET emulate
pm32_0E DW OFFSET emulate,            OFFSET emulate
pm32_10 DW OFFSET emulate,            OFFSET emulate
pm32_12 DW OFFSET emulate,            OFFSET emulate
pm32_14 DW OFFSET emulate,            OFFSET emulate
pm32_16 DW OFFSET emulate,            OFFSET emulate
pm32_18 DW OFFSET emulate,            OFFSET emulate
pm32_1A DW OFFSET emulate,            OFFSET emulate
pm32_1C DW OFFSET emulate,            OFFSET emulate
pm32_1E DW OFFSET emulate,            OFFSET emulate
pm32_20 DW OFFSET emulate,            OFFSET emulate
pm32_22 DW OFFSET emulate,            OFFSET emulate
pm32_24 DW OFFSET emulate,            OFFSET emulate
pm32_26 DW OFFSET emulate,            OFFSET emulate
pm32_28 DW OFFSET emulate,            OFFSET emulate
pm32_2A DW OFFSET emulate,            OFFSET emulate
pm32_2C DW OFFSET emulate,            OFFSET emulate
pm32_2E DW OFFSET emulate,            OFFSET emulate
pm32_30 DW OFFSET emulate,            OFFSET emulate
pm32_32 DW OFFSET emulate,            OFFSET emulate
pm32_34 DW OFFSET emulate,            OFFSET emulate
pm32_36 DW OFFSET emulate,            OFFSET emulate
pm32_38 DW OFFSET emulate,            OFFSET emulate
pm32_3A DW OFFSET emulate,            OFFSET emulate
pm32_3C DW OFFSET emulate,            OFFSET emulate
pm32_3E DW OFFSET emulate,            OFFSET emulate
pm32_40 DW OFFSET emulate,            OFFSET emulate
pm32_42 DW OFFSET emulate,            OFFSET emulate
pm32_44 DW OFFSET emulate,            OFFSET emulate
pm32_46 DW OFFSET emulate,            OFFSET emulate
pm32_48 DW OFFSET emulate,            OFFSET emulate
pm32_4A DW OFFSET emulate,            OFFSET emulate
pm32_4C DW OFFSET emulate,            OFFSET emulate
pm32_4E DW OFFSET emulate,            OFFSET emulate
pm32_50 DW OFFSET emulate,            OFFSET emulate
pm32_52 DW OFFSET emulate,            OFFSET emulate
pm32_54 DW OFFSET emulate,            OFFSET emulate
pm32_56 DW OFFSET emulate,            OFFSET emulate
pm32_58 DW OFFSET emulate,            OFFSET emulate
pm32_5A DW OFFSET emulate,            OFFSET emulate
pm32_5C DW OFFSET emulate,            OFFSET emulate
pm32_5E DW OFFSET emulate,            OFFSET emulate
pm32_60 DW OFFSET emulate,            OFFSET emulate
pm32_62 DW OFFSET emulate,            OFFSET emulate
pm32_64 DW OFFSET emulate,            OFFSET emulate
pm32_66 DW OFFSET emulate,            OFFSET emulate
pm32_68 DW OFFSET emulate,            OFFSET emulate
pm32_6A DW OFFSET emulate,            OFFSET emulate
pm32_6C DW OFFSET emulate,            OFFSET emulate
pm32_6E DW OFFSET emulate,            OFFSET emulate
pm32_70 DW OFFSET emulate,            OFFSET emulate
pm32_72 DW OFFSET emulate,            OFFSET emulate
pm32_74 DW OFFSET emulate,            OFFSET emulate
pm32_76 DW OFFSET emulate,            OFFSET emulate
pm32_78 DW OFFSET emulate,            OFFSET emulate
pm32_7A DW OFFSET emulate,            OFFSET emulate
pm32_7C DW OFFSET emulate,            OFFSET emulate
pm32_7E DW OFFSET emulate,            OFFSET emulate
pm32_80 DW OFFSET emulate,            OFFSET emulate
pm32_82 DW OFFSET emulate,            OFFSET emulate
pm32_84 DW OFFSET emulate,            OFFSET emulate
pm32_86 DW OFFSET emulate,            OFFSET emulate
pm32_88 DW OFFSET emulate,            OFFSET emulate
pm32_8A DW OFFSET emulate,            OFFSET emulate
pm32_8C DW OFFSET emulate,            OFFSET emulate
pm32_8E DW OFFSET emulate,            OFFSET emulate
pm32_90 DW OFFSET emulate,            OFFSET emulate
pm32_92 DW OFFSET emulate,            OFFSET emulate
pm32_94 DW OFFSET emulate,            OFFSET emulate
pm32_96 DW OFFSET emulate,            OFFSET emulate
pm32_98 DW OFFSET emulate,            OFFSET emulate
pm32_9A DW OFFSET emulate,            OFFSET emulate
pm32_9C DW OFFSET emulate,            OFFSET emulate
pm32_9E DW OFFSET emulate,            OFFSET emulate
pm32_A0 DW OFFSET emulate,            OFFSET emulate
pm32_A2 DW OFFSET emulate,            OFFSET emulate
pm32_A4 DW OFFSET emulate,            OFFSET emulate
pm32_A6 DW OFFSET emulate,            OFFSET emulate
pm32_A8 DW OFFSET emulate,            OFFSET emulate
pm32_AA DW OFFSET emulate,            OFFSET emulate
pm32_AC DW OFFSET emulate,            OFFSET emulate
pm32_AE DW OFFSET emulate,            OFFSET emulate
pm32_B0 DW OFFSET emulate,            OFFSET emulate
pm32_B2 DW OFFSET emulate,            OFFSET emulate
pm32_B4 DW OFFSET emulate,            OFFSET emulate
pm32_B6 DW OFFSET emulate,            OFFSET emulate
pm32_B8 DW OFFSET emulate,            OFFSET emulate
pm32_BA DW OFFSET emulate,            OFFSET emulate
pm32_BC DW OFFSET emulate,            OFFSET emulate
pm32_BE DW OFFSET emulate,            OFFSET emulate
pm32_C0 DW OFFSET emulate,            OFFSET emulate
pm32_C2 DW OFFSET emulate,            OFFSET emulate
pm32_C4 DW OFFSET emulate,            OFFSET emulate
pm32_C6 DW OFFSET emulate,            OFFSET emulate
pm32_C8 DW OFFSET emulate,            OFFSET emulate
pm32_CA DW OFFSET emulate,            OFFSET emulate
pm32_CC DW OFFSET emulate,            OFFSET emulate
pm32_CE DW OFFSET emulate,            OFFSET emulate
pm32_D0 DW OFFSET emulate,            OFFSET emulate
pm32_D2 DW OFFSET emulate,            OFFSET emulate
pm32_D4 DW OFFSET emulate,            OFFSET emulate
pm32_D6 DW OFFSET emulate,            OFFSET emulate
pm32_D8 DW OFFSET emulate,            OFFSET emulate
pm32_DA DW OFFSET emulate,            OFFSET emulate
pm32_DC DW OFFSET emulate,            OFFSET emulate
pm32_DE DW OFFSET emulate,            OFFSET emulate
pm32_E0 DW OFFSET emulate,            OFFSET emulate
pm32_E2 DW OFFSET emulate,            OFFSET emulate
pm32_E4 DW OFFSET emulate,            OFFSET emulate
pm32_E6 DW OFFSET emulate,            OFFSET emulate
pm32_E8 DW OFFSET emulate,            OFFSET emulate
pm32_EA DW OFFSET emulate,            OFFSET emulate
pm32_EC DW OFFSET emulate,            OFFSET emulate
pm32_EE DW OFFSET emulate,            OFFSET emulate
pm32_F0 DW OFFSET emulate,            OFFSET emulate
pm32_F2 DW OFFSET emulate,            OFFSET emulate
pm32_F4 DW OFFSET emulate,            OFFSET emulate
pm32_F6 DW OFFSET emulate,            OFFSET emulate
pm32_F8 DW OFFSET emulate,            OFFSET emulate
pm32_FA DW OFFSET emulate,            OFFSET emulate
pm32_FC DW OFFSET emulate,            OFFSET emulate
pm32_FE DW OFFSET emulate,            OFFSET emulate

trap_6:
    push dword ptr 0
    push ebp
    mov ebp,esp
    sti
    cld
    push eax
    push ebx
    mov ax,6
    push ax
    push ds
;
    test byte ptr [ebp+2].trap_eflags,2
    jnz t6_vm
    mov ds,[ebp].trap_cs
    mov ebx,[ebp].trap_eip
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
    call emulate
    jmp t6_ret
t6_vm:
    xor ebx,ebx
    mov bx,[ebp].trap_cs
    shl ebx,4
    add ebx,[ebp].trap_eip
    mov ax,flat_sel
    mov ds,ax
    mov ax,[ebx]
    cmp ax,00B0Fh
    jne emulate
    add ebx,2
    sti
    movzx eax,byte ptr [ebx]
    call word ptr cs:[eax*2].vm_call_tab
t6_ret:
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
;           NAME:           TRAP_7
;
;           DESCRIPTION:    Co-processor fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_7:
    push dword ptr 0
    push ebp
    mov ebp,esp
    sti
    push eax
    push ebx
    mov ax,7
    push ax
    push ds
;
    mov eax,cr0
    test al,4
    jz math_real_fpu

math_emulate_fpu:
    call emulate
    jmp math_done

math_real_fpu:
    FpuException

math_done:
    pop eax
    mov ds,ax
    pop ebx
    pop eax
    cli
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
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
    push ebp
    mov ebp,esp
    sti
    push eax
    push ebx
    mov ax,9
    push ax
    push ds
;
    call emulate
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
;           NAME:           TRAP_10
;
;           DESCRIPTION:    Invalid TSS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_10:
    sti
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,10
    push ax
    push ds
;
    test byte ptr [ebp+2].trap_eflags,2
    jnz t10_vm
;
    call prot_exception
    jmp t10_ret

t10_vm:
    call emulate

t10_ret:
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
;           NAME:           TRAP_11
;
;           DESCRIPTION:    Segment not present fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


trap_11:
    sti
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,11
    push ax
    push ds
;
    test byte ptr [ebp+2].trap_eflags,2
    jnz t11_vm
    SegmentNotPresent
    jnc t11_ret
;
    call prot_exception
    jmp t11_ret

t11_vm:
    call emulate

t11_ret:
    pop eax
    mov ds,ax
    pop ebx
    pop eax
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
    add sp,4
    iretd

segment_not_present_name DB 'Segment Not Present',0

segment_not_present     PROC far
    stc
    retf32
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
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,12
    push ax
    push ds
;
    test byte ptr [ebp+2].trap_eflags,2
    jnz t12_vm
;
    call prot_exception
    jmp t12_ret

t12_vm:
    call emulate

t12_ret:
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
;           NAME:           TRAP_13
;
;           DESCRIPTION:    General protection fault
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_ds Proc near
    add ebx,2
    mov [ebp].trap_eip,ebx
    mov word ptr [ebp].trap_pds,0
    ret
load_ds Endp

load_es Proc near
    add ebx,2
    mov [ebp].trap_eip,ebx
    xor ax,ax
    mov es,ax
    ret
load_es Endp

load_fs Proc near
    add ebx,2
    mov [ebp].trap_eip,ebx
    xor ax,ax
    mov fs,ax
    ret
load_fs Endp

load_gs Proc near
    add ebx,2
    mov [ebp].trap_eip,ebx
    xor ax,ax
    mov gs,ax
    ret
load_gs Endp

load_seg_tab:
lst00  DW OFFSET load_es
lst01  DW OFFSET emulate
lst02  DW OFFSET emulate
lst03  DW OFFSET load_ds
lst04  DW OFFSET load_fs
lst05  DW OFFSET load_gs
lst06  DW OFFSET emulate
lst07  DW OFFSET emulate

load_sreg   Proc near
    mov al,ds:[ebx+1]
    and al,0C0h
    cmp al,0C0h
    jne lsEm
;    
    mov al,ds:[ebx+1]
    and al,38h
    shr al,3
    movzx eax,al
    jmp word ptr cs:[eax*2].load_seg_tab

lsEm:
    jmp emulate    
load_sreg   Endp

pop_ds:
    mov ax,[ebp].trap_esp
    and ax,0FFFCh
    mov bx,[ebp].trap_err
    and bx,0FFFCh
    cmp ax,bx
    je pop_ds_clear
    jmp emulate

pop_ds_clear:    
    mov bx,[ebp].trap_cs
    GetSelectorBitness
    cmp al,16
    je pop_ds16
;
    cmp al,32
    je pop_ds32
    jmp emulate    

pop_ds16:    
    inc dword ptr [ebp].trap_eip
    add sp,6
    xor ax,ax
    mov ds,ax
    jmp ret_seg16

pop_ds32:    
    inc dword ptr [ebp].trap_eip
    add sp,6
    xor ax,ax
    mov ds,ax
    jmp ret_seg32
    
pop_es:
    mov ax,[ebp].trap_esp
    and ax,0FFFCh
    mov bx,[ebp].trap_err
    and bx,0FFFCh
    cmp ax,bx
    je pop_es_clear
    jmp emulate

pop_es_clear:    
    mov bx,[ebp].trap_cs
    GetSelectorBitness
    cmp al,16
    je pop_es16
;
    cmp al,32
    je pop_es32
    jmp emulate    

pop_es16:    
    inc dword ptr [ebp].trap_eip
    xor ax,ax
    mov es,ax
    jmp ret_ds_seg16
    
pop_es32:    
    inc dword ptr [ebp].trap_eip
    xor ax,ax
    mov es,ax
    jmp ret_ds_seg32
    
pop_fs:
    mov ax,[ebp].trap_esp
    and ax,0FFFCh
    mov bx,[ebp].trap_err
    and bx,0FFFCh
    cmp ax,bx
    je pop_fs_clear
    jmp emulate

pop_fs_clear:    
    mov bx,[ebp].trap_cs
    GetSelectorBitness
    cmp al,16
    je pop_fs16
;
    cmp al,32
    je pop_fs32
    jmp emulate    

pop_fs16:    
    add dword ptr [ebp].trap_eip,2
    xor ax,ax
    mov fs,ax
    jmp ret_ds_seg16
    
pop_fs32:    
    add dword ptr [ebp].trap_eip,2
    xor ax,ax
    mov fs,ax
    jmp ret_ds_seg32
    
pop_gs:
    mov ax,[ebp].trap_esp
    and ax,0FFFCh
    mov bx,[ebp].trap_err
    and bx,0FFFCh
    cmp ax,bx
    je pop_gs_clear
    jmp emulate

pop_gs_clear:    
    mov bx,[ebp].trap_cs
    GetSelectorBitness
    cmp al,16
    je pop_gs16
;
    cmp al,32
    je pop_gs32
    jmp emulate    

pop_gs16:    
    add dword ptr [ebp].trap_eip,2
    xor ax,ax
    mov gs,ax
    jmp ret_ds_seg16
    
pop_gs32:    
    add dword ptr [ebp].trap_eip,2
    xor ax,ax
    mov gs,ax
    jmp ret_ds_seg32

ret_ds_seg16:
    add sp,2
    pop eax
    mov ds,ax
    jmp ret_seg16

ret_ds_seg32:
    add sp,2
    pop eax
    mov ds,ax
    jmp ret_seg32

ret_seg16:
    mov eax,[ebp].trap_eflags
    and eax,NOT 10000h
    mov [ebp].trap_eflags+2,eax
    mov eax,[ebp].trap_cs
    mov [ebp].trap_cs+2,eax
    mov eax,[ebp].trap_eip
    mov [ebp].trap_eip+2,eax 
;
    pop ebx
    pop eax
    pop ebp
    add sp,6
    iretd

ret_seg32:
    mov eax,[ebp].trap_eflags
    and eax,NOT 10000h
    mov [ebp].trap_eflags+4,eax
    mov eax,[ebp].trap_cs
    mov [ebp].trap_cs+4,eax
    mov eax,[ebp].trap_eip
    mov [ebp].trap_eip+4,eax 
;
    pop ebx
    pop eax
    pop ebp
    add sp,8
    iretd
    

load_opov:
    inc ebx
    mov al,ds:[ebx]
    cmp al,8Eh
    je load_sreg
    jmp emulate

fault_0F:
    mov al,ds:[ebx+1]
    cmp al,0A1h
    je pop_fs
;
    cmp al,0A9h
    je pop_gs 
;       
    jmp emulate    

fault_call_tab:
flt_00 DW OFFSET emulate,            OFFSET emulate
flt_02 DW OFFSET emulate,            OFFSET emulate
flt_04 DW OFFSET emulate,            OFFSET emulate
flt_06 DW OFFSET emulate,            OFFSET pop_es
flt_08 DW OFFSET emulate,            OFFSET emulate
flt_0A DW OFFSET emulate,            OFFSET emulate
flt_0C DW OFFSET emulate,            OFFSET emulate
flt_0E DW OFFSET emulate,            OFFSET fault_0F
flt_10 DW OFFSET emulate,            OFFSET emulate
flt_12 DW OFFSET emulate,            OFFSET emulate
flt_14 DW OFFSET emulate,            OFFSET emulate
flt_16 DW OFFSET emulate,            OFFSET emulate
flt_18 DW OFFSET emulate,            OFFSET emulate
flt_1A DW OFFSET emulate,            OFFSET emulate
flt_1C DW OFFSET emulate,            OFFSET emulate
flt_1E DW OFFSET emulate,            OFFSET pop_ds
flt_20 DW OFFSET emulate,            OFFSET emulate
flt_22 DW OFFSET emulate,            OFFSET emulate
flt_24 DW OFFSET emulate,            OFFSET emulate
flt_26 DW OFFSET emulate,            OFFSET emulate
flt_28 DW OFFSET emulate,            OFFSET emulate
flt_2A DW OFFSET emulate,            OFFSET emulate
flt_2C DW OFFSET emulate,            OFFSET emulate
flt_2E DW OFFSET emulate,            OFFSET emulate
flt_30 DW OFFSET emulate,            OFFSET emulate
flt_32 DW OFFSET emulate,            OFFSET emulate
flt_34 DW OFFSET emulate,            OFFSET emulate
flt_36 DW OFFSET emulate,            OFFSET emulate
flt_38 DW OFFSET emulate,            OFFSET emulate
flt_3A DW OFFSET emulate,            OFFSET emulate
flt_3C DW OFFSET emulate,            OFFSET emulate
flt_3E DW OFFSET emulate,            OFFSET emulate
flt_40 DW OFFSET emulate,            OFFSET emulate
flt_42 DW OFFSET emulate,            OFFSET emulate
flt_44 DW OFFSET emulate,            OFFSET emulate
flt_46 DW OFFSET emulate,            OFFSET emulate
flt_48 DW OFFSET emulate,            OFFSET emulate
flt_4A DW OFFSET emulate,            OFFSET emulate
flt_4C DW OFFSET emulate,            OFFSET emulate
flt_4E DW OFFSET emulate,            OFFSET emulate
flt_50 DW OFFSET emulate,            OFFSET emulate
flt_52 DW OFFSET emulate,            OFFSET emulate
flt_54 DW OFFSET emulate,            OFFSET emulate
flt_56 DW OFFSET emulate,            OFFSET emulate
flt_58 DW OFFSET emulate,            OFFSET emulate
flt_5A DW OFFSET emulate,            OFFSET emulate
flt_5C DW OFFSET emulate,            OFFSET emulate
flt_5E DW OFFSET emulate,            OFFSET emulate
flt_60 DW OFFSET emulate,            OFFSET emulate
flt_62 DW OFFSET emulate,            OFFSET emulate
flt_64 DW OFFSET emulate,            OFFSET emulate
flt_66 DW OFFSET load_opov,          OFFSET emulate
flt_68 DW OFFSET emulate,            OFFSET emulate
flt_6A DW OFFSET emulate,            OFFSET emulate
flt_6C DW OFFSET emulate,            OFFSET emulate
flt_6E DW OFFSET emulate,            OFFSET emulate
flt_70 DW OFFSET emulate,            OFFSET emulate
flt_72 DW OFFSET emulate,            OFFSET emulate
flt_74 DW OFFSET emulate,            OFFSET emulate
flt_76 DW OFFSET emulate,            OFFSET emulate
flt_78 DW OFFSET emulate,            OFFSET emulate
flt_7A DW OFFSET emulate,            OFFSET emulate
flt_7C DW OFFSET emulate,            OFFSET emulate
flt_7E DW OFFSET emulate,            OFFSET emulate
flt_80 DW OFFSET emulate,            OFFSET emulate
flt_82 DW OFFSET emulate,            OFFSET emulate
flt_84 DW OFFSET emulate,            OFFSET emulate
flt_86 DW OFFSET emulate,            OFFSET emulate
flt_88 DW OFFSET emulate,            OFFSET emulate
flt_8A DW OFFSET emulate,            OFFSET emulate
flt_8C DW OFFSET emulate,            OFFSET emulate
flt_8E DW OFFSET load_sreg,          OFFSET emulate
flt_90 DW OFFSET emulate,            OFFSET emulate
flt_92 DW OFFSET emulate,            OFFSET emulate
flt_94 DW OFFSET emulate,            OFFSET emulate
flt_96 DW OFFSET emulate,            OFFSET emulate
flt_98 DW OFFSET emulate,            OFFSET emulate
flt_9A DW OFFSET emulate,            OFFSET emulate
flt_9C DW OFFSET emulate,            OFFSET emulate
flt_9E DW OFFSET emulate,            OFFSET emulate
flt_A0 DW OFFSET emulate,            OFFSET emulate
flt_A2 DW OFFSET emulate,            OFFSET emulate
flt_A4 DW OFFSET emulate,            OFFSET emulate
flt_A6 DW OFFSET emulate,            OFFSET emulate
flt_A8 DW OFFSET emulate,            OFFSET emulate
flt_AA DW OFFSET emulate,            OFFSET emulate
flt_AC DW OFFSET emulate,            OFFSET emulate
flt_AE DW OFFSET emulate,            OFFSET emulate
flt_B0 DW OFFSET emulate,            OFFSET emulate
flt_B2 DW OFFSET emulate,            OFFSET emulate
flt_B4 DW OFFSET emulate,            OFFSET emulate
flt_B6 DW OFFSET emulate,            OFFSET emulate
flt_B8 DW OFFSET emulate,            OFFSET emulate
flt_BA DW OFFSET emulate,            OFFSET emulate
flt_BC DW OFFSET emulate,            OFFSET emulate
flt_BE DW OFFSET emulate,            OFFSET emulate
flt_C0 DW OFFSET emulate,            OFFSET emulate
flt_C2 DW OFFSET emulate,            OFFSET emulate
flt_C4 DW OFFSET emulate,            OFFSET emulate
flt_C6 DW OFFSET emulate,            OFFSET emulate
flt_C8 DW OFFSET emulate,            OFFSET emulate
flt_CA DW OFFSET emulate,            OFFSET emulate
flt_CC DW OFFSET emulate,            OFFSET emulate
flt_CE DW OFFSET emulate,            OFFSET emulate
flt_D0 DW OFFSET emulate,            OFFSET emulate
flt_D2 DW OFFSET emulate,            OFFSET emulate
flt_D4 DW OFFSET emulate,            OFFSET emulate
flt_D6 DW OFFSET emulate,            OFFSET emulate
flt_D8 DW OFFSET emulate,            OFFSET emulate
flt_DA DW OFFSET emulate,            OFFSET emulate
flt_DC DW OFFSET emulate,            OFFSET emulate
flt_DE DW OFFSET emulate,            OFFSET emulate
flt_E0 DW OFFSET emulate,            OFFSET emulate
flt_E2 DW OFFSET emulate,            OFFSET emulate
flt_E4 DW OFFSET emulate,            OFFSET emulate
flt_E6 DW OFFSET emulate,            OFFSET emulate
flt_E8 DW OFFSET emulate,            OFFSET emulate
flt_EA DW OFFSET emulate,            OFFSET emulate
flt_EC DW OFFSET emulate,            OFFSET emulate
flt_EE DW OFFSET emulate,            OFFSET emulate
flt_F0 DW OFFSET emulate,            OFFSET emulate
flt_F2 DW OFFSET emulate,            OFFSET emulate
flt_F4 DW OFFSET emulate,            OFFSET emulate
flt_F6 DW OFFSET emulate,            OFFSET emulate
flt_F8 DW OFFSET emulate,            OFFSET emulate
flt_FA DW OFFSET emulate,            OFFSET emulate
flt_FC DW OFFSET emulate,            OFFSET emulate
flt_FE DW OFFSET emulate,            OFFSET emulate

trap_13:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,13
    push ax
    push ds
;
    test byte ptr [ebp+2].trap_eflags,2
    jz t13_enter_patch
;
    mov bx,flat_sel
    mov ds,bx
    movzx ebx,word ptr [ebp].trap_cs
    shl ebx,4
    add ebx,dword ptr [ebp].trap_eip
    mov al,ds:[ebx]    
    cmp al,0CCh
    jne t13_vm_em
;   
    inc dword ptr [ebp].trap_eip
    pop ds
    pop ax
    mov al,3    
    push ax
    push ds

t13_vm_em:    
    call emulate
    jmp t13_end

t13_enter_patch:
    mov ax,system_data_sel
    mov ds,ax
    call ds:enter_patch_proc
    
t13_prot:    
    mov ds,[ebp].trap_cs
    mov ebx,[ebp].trap_eip
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
    cmp al,3Eh
    je t13_32
;
    cmp al,67h
    jne t13_default

t13_16:
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
    cmp ax,4
    ja t13_default

t13_int_call16:
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
    mov edx,cr0
    pushf
    push edx
    and edx,NOT 10000h
    cli
    mov cr0,edx
;
    mov al,0CDh
    xchg al,ds:[ebx]
;
    pop edx
    mov cr0,edx
    popf
;
    pop edx
    pop ecx
    jmp t13_end

t13_int_user:
    mov ax,[ebx+6]
    or ax,ax
    jz t13_default
;
    cmp ax,4
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
    mov edx,cr0
    pushf
    push edx
    and edx,NOT 10000h
    cli
    mov cr0,edx
;
    mov al,0CDh
    xchg al,ds:[ebx]
;
    pop edx
    mov cr0,edx
    popf
;
    pop edx
    pop ecx
    jmp t13_end

t13_32:
    mov al,[ebx+1]
    cmp al,67h
    jne t13_default
;
    mov ax,[ebx+7]
    cmp ax,3
    ja t13_default

t13_int_call32:
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
    mov edx,cr0
    pushf
    push edx
    and edx,NOT 10000h
    cli
    mov cr0,edx 
;
    mov al,0CDh
    xchg al,ds:[ebx]
; 
    pop edx
    mov cr0,edx
    popf
;
    pop edx
    pop ecx
    jmp t13_end

t13_default:
    mov ax,system_data_sel
    mov ds,ax
    call ds:leave_patch_proc
;
    mov bx,[ebp].trap_cs
    test bx,3
    jnz t13_em_app
;    
;    mov ax,wd_code_sel
;    verr ax
;    jnz t13_em_app
;
    mov ds,[ebp].trap_cs
    mov ebx,[ebp].trap_eip
    movzx eax,byte ptr [ebx]
    call word ptr cs:[eax*2].fault_call_tab
    jmp t13_end

t13_em_app:
    call emulate
    jmp t13_end

t13_retry:
    mov ax,system_data_sel
    mov ds,ax
    call ds:leave_patch_proc

t13_end:
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
    SetupIntGate
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
;           NAME:           TRAP_2
;
;           DESCRIPTION:    NMI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_nmi:
    retf32

nmi_handler:
    cli
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,system_data_sel
    mov es,ax
    mov ds,es:nmi_data
    call fword ptr es:nmi_proc

nmi_ret:    
    popad
    pop gs
    pop fs
    pop es
    pop ds
    iretd

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
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,0
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask1:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,1
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask3:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,3
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask4:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,4
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask5:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,5
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask6:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,6
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask7:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,7
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask8:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,8
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask9:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,9
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask10:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,10
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask11:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,11
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask12:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,12
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask13:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,13
    push ax
    push ds
;    
    test byte ptr [ebp+2].trap_eflags,2
    jnz pretask_gpf_default
;
    mov ds,[ebp].trap_cs
    mov ebx,[ebp].trap_eip
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
    cmp al,9Ah
    je pretask_gpf_reexec
;
    jmp pretask_gpf_default
        
pretask_gpf_not_int:
    cmp al,3Eh
    je pretask_gpf_32
;
    cmp al,67h
    jne pretask_gpf_default

pretask_gpf_16:
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

pretask_kernel_gate16:
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

pretask_gpf_32:
    mov al,[ebx+1]
    cmp al,67h
    jne pretask_gpf_default
;
    mov ax,[ebx+7]
    cmp ax,3
    ja pretask_gpf_default

pretask_kernel_gate32:
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
    mov ax,-1
    ShutDownPreTask

pretask_gpf_reexec:
    pop eax
    mov ds,ax
    pop ebx
    pop eax
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
    add sp,4
    iretd

prepaging14:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,14
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask16:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,16
    push ax
    push ds
    mov ax,-1
    ShutDownPreTask

pretask_int_tab:
;
;               int #   Entry                   Selector        Dpl
;
pg0         DW      0,          OFFSET pretask0,        kernel_code,    0
pg1         DW      1,          OFFSET pretask1,        kernel_code,    0
pg2         DW      2,          OFFSET nmi_handler,     kernel_code,    0
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
rgE8    DW      0E8h,   OFFSET intE8,           kernel_code,    3
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
    mov ax,system_data_sel
    mov ds,ax
    mov ds:nmi_data,0
    mov ds:nmi_proc,OFFSET default_nmi
    mov ds:nmi_proc+4,cs
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
;           NAME:           SetupNmiHandler
;
;           DESCRIPTION:    Setup NMI handler
;
;           PARAMETERS:     DS          Data
;                           ES:EDI      Handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_nmi_handler_name  DB 'Setup NMI Handler',0

setup_nmi_handler       Proc far
    push ds
    push es
    push fs
    pushad
;
    mov ax,system_data_sel
    mov fs,ax
    mov fs:nmi_data,ds
    mov fs:nmi_proc,edi
    mov fs:nmi_proc+4,es
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov al,2
    xor bl,bl
    mov esi,OFFSET nmi_handler
    SetupIntGate
;
    popad
    pop fs
    pop es
    pop ds
    retf32
setup_nmi_handler       Endp

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
    mov al,14
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
    mov esi,OFFSET setup_smp_patch
    mov edi,OFFSET setup_smp_patch_name
    xor cl,cl
    mov ax,setup_smp_patch_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_thread_suspend
    mov edi,OFFSET notify_thread_suspend_name
    xor cl,cl
    mov ax,notify_thread_suspend_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_nmi_handler
    mov edi,OFFSET setup_nmi_handler_name
    xor cl,cl
    mov ax,setup_nmi_handler_nr
    RegisterOsGate
    ret
init_trap_vectors       ENDP


code    ENDS

    END
