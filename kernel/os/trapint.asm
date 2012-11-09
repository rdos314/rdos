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
INCLUDE proc.inc

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

irq_data_seg     STRUC

irq_bitmask         DB 32 DUP(?)

irq_data_seg     ENDS

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
    extrn do_usercall16:near
    extrn do_usercall32:near
    extrn do_usergate32:near

    assume cs:code

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
    mov fs,fs:ps_sel
    pop ax
    jmp debug_normal

debug_exception:
    movzx ax,al
    push fs
    TryLockTask
    jc debug_normal

debug_fault:
    movzx eax,al
    CrashFault
   
debug_normal:       
    push ax
    mov ax,fs:ps_curr_thread 
    or ax,ax
    pop ax
    jz debug_fault
;    
    push ax
    mov ax,fs:ps_curr_thread
    cmp ax,fs:ps_null_thread
    pop ax
    je debug_fault
;
    mov ds,fs:ps_curr_thread 
    mov al,[ebp].trap_exc_nr
    mov ds:p_fault_vector,al
    mov eax,[ebp].trap_err
    mov ds:p_fault_code,eax
;
    mov eax,[ebp].trap_eax
    mov ds:p_tss_eax,eax
    mov eax,[ebp].trap_ebx
    mov ds:p_tss_ebx,eax
    mov ds:p_tss_ecx,ecx
    mov ds:p_tss_edx,edx
    mov ds:p_tss_esi,esi
    mov ds:p_tss_edi,edi
    mov eax,[ebp].trap_ebp
    mov ds:p_tss_ebp,eax
;       
    mov eax,[ebp].trap_eflags
    mov ds:p_tss_eflags,eax
    mov ax,[ebp].trap_cs
    mov ds:p_tss_cs,ax
    mov eax,[ebp].trap_eip
    mov ds:p_tss_eip,eax
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
    mov ds:p_tss_ss,ax
    mov eax,[ebp].trap_esp
    mov ds:p_tss_esp,eax
    jmp debug_pm_common
    
debug_kernel:
    mov ax,ss
    mov ds:p_tss_ss,ax
    mov eax,ebp
    add eax,trap_esp
    mov ds:p_tss_esp,eax
    
debug_pm_common:
    mov ax,[ebp].trap_pds
    mov ds:p_tss_ds,ax
    mov ax,es
    mov ds:p_tss_es,ax
    mov ds:p_tss_fs,si
    mov ax,gs
    mov ds:p_tss_gs,ax
    jmp debug_save_ok

debug_vm:
    mov ax,[ebp].trap_gs
    mov ds:p_tss_gs,ax
    mov ax,[ebp].trap_fs
    mov ds:p_tss_fs,ax
    mov ax,[ebp].trap_ds
    mov ds:p_tss_ds,ax
    mov ax,[ebp].trap_es
    mov ds:p_tss_es,ax
    mov ax,[ebp].trap_ss
    mov ds:p_tss_ss,ax
    mov eax,[ebp].trap_esp
    mov ds:p_tss_esp,eax

debug_save_ok:
    DebugBlock

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadWord
;
;           DESCRIPTION:    Read a word in another thread
;
;           PARAMETERS:         DX:ESI  Address
;                           ES          TSS
;
;           RETURNS:        AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadWord    Proc near
    push bx
    push cx
    push esi
    mov bx,es
    test word ptr es:p_tss_eflags+2,2
    jz read_word_prot
read_word_virt:
    ReadThreadSegment
    mov cx,ax
    inc si
    ReadThreadSegment
    mov ah,al
    mov al,cl
    jmp read_word_done
read_word_prot:
    ReadThreadSelector
    mov cx,ax
    inc esi
    ReadThreadSelector
    mov ah,al
    mov al,cl
read_word_done:
    pop esi
    pop cx
    pop bx  
    ret
ReadWord    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteWord
;
;           DESCRIPTION:    Write a word in another thread
;
;           PARAMETERS:         DX:ESI  Address
;                           ES          TSS
;                           AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteWord       Proc near
    push bx
    push cx
    push esi
    mov cx,ax
    mov bx,es
    test word ptr es:p_tss_eflags+2,2
    jz write_word_prot
write_word_virt:
    mov al,cl
    WriteThreadSegment
    inc si
    mov al,ch
    WriteThreadSegment
    jmp write_word_done
write_word_prot:
    mov al,cl
    WriteThreadSelector
    inc esi
    mov al,ch
    WriteThreadSelector
write_word_done:
    pop esi
    pop cx
    pop bx  
    ret
WriteWord       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LOCAL_GET_DEBUG_THREAD_SEL
;
;           DESCRIPTION:    Get currently debugged thread selector
;
;           PARAMETERS:         AX          DEBUG THREAD OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_debug_thread_sel    PROC near
    push ds
    push es
    push cx
    push dx
    push si
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:debug_thread
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    jz get_debug_sel_done

    mov dx,ax
get_debug_sel_try_next:
    cmp ax,cx
    je get_debug_sel_default
    mov es,ax
    mov ax,es:p_next
    cmp dx,ax
    je get_debug_sel_new
    jmp get_debug_sel_try_next
get_debug_sel_new:
    mov cx,[si]
get_debug_sel_default:
    mov ds:debug_thread,cx
    mov ax,cx
get_debug_sel_done:
    pop si
    pop dx
    pop cx
    pop es
    pop ds
    ret
local_get_debug_thread_sel    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DEBUG_THREAD_SEL
;
;           DESCRIPTION:    Get currently debugged thread selector
;
;           PARAMETERS:         AX          DEBUG THREAD OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_thread_sel_name   DB 'Get Debug Thread Sel', 0

get_debug_thread_sel    PROC far
    call local_get_debug_thread_sel
    retf32
get_debug_thread_sel    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DEBUG_THREAD
;
;           DESCRIPTION:    Get currently debugged thread ID
;
;           PARAMETERS:     AX         DEBUG THREAD ID OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_thread_name   DB 'Get Debug Thread', 0

get_debug_thread    PROC far
    push es
    call local_get_debug_thread_sel
    or ax,ax
    jz get_debug_done
;
    mov es,ax
    mov ax,es:p_id

get_debug_done:
    pop es
    retf32
get_debug_thread    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_TRACE
;
;           DESCRIPTION:    Trace one instruction in debugged thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_trace_name    DB 'Debug Trace',0

debug_trace     PROC far
    push ds
    push es
    pushad
    call local_get_debug_thread_sel
    or ax,ax
    jz debug_trace_done
    mov bx,ax
    mov es,bx
    mov dx,es:p_tss_cs
    mov esi,es:p_tss_eip
    call ReadWord
    push ax
    add esi,2
    call ReadWord
    mov dx,ax
    pop ax  
    cmp al,0CDh
    jne debug_trace_trace
;
    test word ptr es:p_tss_eflags+2,2
    jz debug_trace_trace
    and word ptr es:p_tss_eflags+2,NOT 2
    mov dx,vm_int_sel
    movzx esi,ah
    shl esi,2
    call ReadWord
    push ax
    add si,2
    call ReadWord
    mov dx,ax
    pop bx
;
    push dx
    push bx
    or word ptr es:p_tss_eflags+2,2
    mov bx,es
    mov dx,es:p_tss_ss
    movzx esi,word ptr es:p_tss_esp
    sub esi,6
    pop ax
    pop cx
    xchg ax,word ptr es:p_tss_eip
    xchg cx,es:p_tss_cs
    add ax,2
    call WriteWord
    mov ax,cx
    add esi,2
    call WriteWord
    mov ax,word ptr es:p_tss_eflags
    add esi,2
    call WriteWord
    sub es:p_tss_esp,6
    jmp debug_trace_done
debug_trace_trace:
    mov eax,es:p_tss_dr7
    and ax,0FFFCh
    mov es:p_tss_dr7,eax
    mov bx,es
    mov ax,word ptr es:p_tss_eflags
    or ax,100h
    mov word ptr es:p_tss_eflags,ax
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake
debug_trace_done:
    popad
    pop es
    pop ds
    retf32
debug_trace     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_PACE
;
;           DESCRIPTION:    Pace one instruction in debugged thread
;
;           PARAMETERS:         DS      Tss sel
;               ES      Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_pace_name DB 'Debug Pace',0

debug_pace      PROC far
    push ds
    push es
    pushad
;    
    call local_get_debug_thread_sel
    or ax,ax
    jz debug_pace_done
;
    mov bx,ax
    mov es,bx
;
    xor cl,cl
    mov bx,es:p_tss_cs
    test byte ptr es:p_tss_eflags+2,2
    jnz debug_pace_bitness_done
;
    test bx,4
    jz debug_pace_bitness_gdt

debug_pace_bitness_ldt:
    mov ds,es:p_ldt_sel
    jmp debug_pace_bitness_get

debug_pace_bitness_gdt:
    mov ax,gdt_sel
    mov ds,ax

debug_pace_bitness_get:
    and bx,0FFF8h
    mov cl,ds:[bx+6]
    shr cl,6
    and cl,1

debug_pace_bitness_done:
    mov dx,es:p_tss_cs
    mov esi,es:p_tss_eip
    call ReadWord
;    
    xor ebx,ebx
    add bx,2
    cmp al,0E2h
    je debug_pace_step
;
    cmp al,0CDh
    je debug_pace_step
;    
    inc bx
    test cl,1
    jz debug_pace_size_ok
;
    add bx,2

debug_pace_size_ok:    
    cmp al,0E8h
    je debug_pace_step
;
    xor ebx,ebx

debug_pace_far_loop:
    mov esi,es:p_tss_eip
    add esi,ebx
    call ReadWord
    cmp al,66h
    je debug_pace_far_ov66
;   
    cmp al,67h
    je debug_pace_far_ov67 
;
    cmp al,9Ah
    je debug_pace_far_call
;
    jmp debug_pace_trace   

debug_pace_far_ov66:
    inc bx
    xor cl,1
    jmp debug_pace_far_loop

debug_pace_far_ov67:
    inc bx
    jmp debug_pace_far_loop

debug_pace_far_call:
    add bx,5
    test cl,1
    jz debug_pace_step
;
    add bx,2
    
debug_pace_step:
    mov ax,word ptr es:p_tss_eflags+2
    test ax,2
    jz debug_pace_step_prot    
;
    xor eax,eax
    xor edx,edx
    mov ax,es:p_tss_cs
    shl eax,4
    mov dx,word ptr es:p_tss_eip
    add eax,edx
    jmp debug_pace_step_do
    
debug_pace_step_prot:
    mov si,es:p_tss_cs
    test si,4
    jz debug_pace_step_gdt
;
    xor eax,eax
    mov ds,es:p_ldt_sel
    mov si,es:p_tss_cs
    and si,0FFF8h
    mov eax,[si+2]
    rol eax,8
    mov al,[si+7]
    ror eax,8
    add eax,es:p_tss_eip
    jmp debug_pace_step_do

debug_pace_step_gdt:
    and si,0FFF8h
    mov ax,gdt_sel
    mov ds,ax    
    mov eax,[si+2]
    rol eax,8
    mov al,[si+7]
    ror eax,8
    add eax,es:p_tss_eip

debug_pace_step_do:
    add eax,ebx
    mov es:p_tss_dr0,eax
    mov eax,es:p_tss_dr7
    and eax,0FFF0FFFCh
    or ax,1
    mov es:p_tss_dr7,eax
    mov ax,word ptr es:p_tss_eflags
    and ax,NOT 100h
    mov word ptr es:p_tss_eflags,ax
    jmp debug_pace_do
    
debug_pace_trace:
    mov eax,es:p_tss_dr7
    and ax,0FFFCh
    mov es:p_tss_dr7,eax
    mov ax,word ptr es:p_tss_eflags
    or ax,100h
    mov word ptr es:p_tss_eflags,ax

debug_pace_do:
    mov bx,es
    mov ds,bx
    or ds:p_flags,THREAD_FLAG_BP
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake

debug_pace_done:
    popad
    pop es
    pop ds
    retf32
debug_pace      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_GO
;
;           DESCRIPTION:    Run currently debugged thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_go_name   DB 'Debug Go',0

debug_go    PROC far
    push ds
    push es
    pushad
    call local_get_debug_thread_sel
    or ax,ax
    jz debug_go_done
    mov bx,ax
    mov es,bx
    mov eax,es:p_tss_dr7
    and ax,0FFFCh
    mov es:p_tss_dr7,eax
    mov ax,word ptr es:p_tss_eflags
    and ax,NOT 100h
    mov word ptr es:p_tss_eflags,ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake
debug_go_done:
    popad
    pop es
    pop ds
    retf32
debug_go    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DebugRun
;
;           DESCRIPTION:    Run currently debugged thread with current DR-settings
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_run_name   DB 'Debug Run',0

debug_run    PROC far
    push ds
    push es
    pushad
    call local_get_debug_thread_sel
    or ax,ax
    jz debug_run_done
;
    mov bx,ax
    mov es,bx
;
    mov ax,word ptr es:p_tss_eflags
    and ax,NOT 100h
    mov word ptr es:p_tss_eflags,ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake

debug_run_done:
    popad
    pop es
    pop ds
    retf32
debug_run    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEBUG_NEXT
;
;           DESCRIPTION:    Select next thread as currently debugged
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_next_name DB 'Debug Next',0

debug_next      PROC far
    push ds
    push es
    push ax
    push si
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    je debug_next_end
    mov es,ax
    mov es,es:p_next
    mov [si],es
    mov ds:debug_thread,es
debug_next_end:
    pop si
    pop ax
    pop es
    pop ds
    retf32
debug_next      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ConvBreakThread
;
;           DESCRIPTION:    Convert thread into selector
;
;           PARAMETERS:     BX          Thread ID
;
;           RETURNS:        ES          Thread selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvBreakThread PROC near
    push ax
    push bx
;    
    or bx,bx
    jnz cbtDo
;
    GetThread
    mov es,ax
    clc
    jmp cbtDone

cbtDo:
    ThreadToSel
    jc cbtDone
;    
    mov es,bx

cbtDone:
    pop bx
    pop ax
    ret
ConvBreakThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           BreakToLinear
;
;           DESCRIPTION:    Convert break address to linear address
;
;           PARAMETERS:     SI:(E)DI        Address
;
;           RETURNS:        EDX             Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BreakToLinear PROC near
    push bx
    push ecx
;
    mov bx,si
    GetSelectorBaseSize
    jc btlDone
;
    or ecx,ecx
    jz btlAdd
;    
    cmp edi,ecx
    jae btlFail

btlAdd:
    add edx,edi
    clc
    jmp btlDone

btlFail:
    stc

btlDone:
    pop ecx
    pop bx    
    ret
BreakToLinear ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddBreak
;
;           DESCRIPTION:    Add a local breakpoint
;
;           PARAMETERS:     EDX     Linear address
;                           ES      Thread sel
;                           AL      Debug register
;                           AH      Type coding
;                           CL      Size of region
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abSizeTab:
ast00  DB 0
ast01  DB 0
ast02  DB 1
ast03  DB 3
ast04  DB 3
ast05  DB 2
ast06  DB 2
ast07  DB 2

AddBreak PROC near
    push bx
    push cx
    push edx
    push esi
;
    cmp al,4
    jae abFail
;   
    mov ch,1
    mov esi,edx

abFixSizeLoop:
    test esi,1
    jnz abFixSizeFix
;
    cmp ch,cl
    jae abFixSizeOk
;
    shl ch,1
    shr esi,1
    jmp abFixSizeLoop

abFixSizeFix:
    mov cl,ch

abFixSizeOk:
    movzx bx,al
    shl bx,2 
    add bx,OFFSET p_tss_dr0
    mov es:[bx],edx
;
    cmp cl,7
    jbe abSizeOk
;
    mov cl,7

abSizeOk:
    movzx bx,cl
;    
    mov esi,0Fh
    mov cl,al
    shl cl,2
    add cl,16
    shl esi,cl
;    
    mov si,3
    mov cl,al
    shl cl,1
    shl si,cl
;    
    not esi
;    
    push eax
    mov cl,al
    shl cl,2
    add cl,16
    movzx eax,ah
    shl eax,cl
    movzx edx,byte ptr cs:[bx].abSizeTab
    add cl,2
    shl edx,cl
    or edx,eax
    pop eax
;
    mov cl,al
    shl cl,1
    mov dx,1
    shl dx,cl
    and es:p_tss_dr7,esi
    or es:p_tss_dr7,edx
    or es:p_flags,THREAD_FLAG_BP
    clc
    jmp abDone

abFail:
    stc

abDone:   
    pop esi
    pop edx
    pop cx
    pop bx
    ret
AddBreak ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveBreak
;
;           DESCRIPTION:    Remove a local breakpoint
;
;           PARAMETERS:     ES      Thread sel
;                           AL      Debug register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveBreak PROC near
    push cx
    push edx
;
    cmp al,4
    jae rbFail
;    
    mov edx,0Fh
    mov cl,al
    shl cl,2
    add cl,16
    shl edx,cl
;    
    mov dx,3
    mov cl,al
    shl cl,1
    shl dx,cl
;    
    not edx
    and es:p_tss_dr7,edx
    clc
    jmp rbDone

rbFail:
    stc

rbDone:   
    pop edx
    pop cx
    ret
RemoveBreak ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCodeBreak
;
;           DESCRIPTION:    Set a code breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           SI:(E)DI        Address
;                           AL              Debug register (0..3)    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_code_break_name DB 'Set Code Break',0

set_code_break PROC near
    push es
    push ax
    push bx
    push cx
    push edx
;    
    call BreakToLinear
    jc scbDone
;
    call ConvBreakThread
    jc scbDone
;
    xor ah,ah
    mov cl,1
    call AddBreak

scbDone:
    pop edx
    pop cx
    pop bx
    pop ax
    pop es
    ret
set_code_break ENDP

set_code_break16  Proc far
    push edi
    movzx edi,di
    call set_code_break
    pop edi
    retf32
set_code_break16  Endp

set_code_break32  Proc far
    call set_code_break
    retf32
set_code_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetReadDataBreak
;
;           DESCRIPTION:    Set a read-data breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           SI:(E)DI        Address
;                           AL              Debug register (1..3)    
;                           CL              Size of region (1,2,4 or 8)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_read_data_break_name DB 'Set Read Data Break',0

set_read_data_break PROC near
    push es
    push ax
    push bx
    push edx
;    
    call BreakToLinear
    jc srdDone
;
    call ConvBreakThread
    jc srdDone
;
    mov ah,3
    call AddBreak

srdDone:
    pop edx
    pop bx
    pop ax
    pop es
    ret
set_read_data_break ENDP

set_read_data_break16  Proc far
    push edi
    movzx edi,di
    call set_read_data_break
    pop edi
    retf32
set_read_data_break16  Endp

set_read_data_break32  Proc far
    call set_read_data_break
    retf32
set_read_data_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetWriteDataBreak
;
;           DESCRIPTION:    Set a write-data breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           SI:(E)DI        Address
;                           AL              Debug register (1..3)    
;                           CL              Size of region (1,2,4 or 8)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_write_data_break_name DB 'Set Write Data Break',0

set_write_data_break PROC near
    push es
    push ax
    push bx
    push edx
;    
    call BreakToLinear
    jc swdDone
;
    call ConvBreakThread
    jc swdDone
;
    mov ah,1
    call AddBreak

swdDone:
    pop edx
    pop bx
    pop ax
    pop es
    ret
set_write_data_break ENDP

set_write_data_break16  Proc far
    push edi
    movzx edi,di
    call set_write_data_break
    pop edi
    retf32
set_write_data_break16  Endp

set_write_data_break32  Proc far
    call set_write_data_break
    retf32
set_write_data_break32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearBreak
;
;           DESCRIPTION:    Clear a breakpoint
;
;           PARAMETERS:     BX              Thread ID
;                           AL              Debug register (0..3)    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_break_name DB 'Clear Break',0

clear_break PROC far
    push es
    push ax
    push bx
;
    call ConvBreakThread
    jc cbDone
;    
    call RemoveBreak

cbDone:
    pop bx
    pop ax
    pop es
    retf32
clear_break ENDP


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
    call virt_exception
    
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
;           NAME:           TRAP_2
;
;           DESCRIPTION:    NMI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_2:
    push dword ptr 0
    push ebp
    mov ebp,esp
    sti
    push eax
    push ebx
    mov ax,2
    push ax
    push ds
;
    test byte ptr [ebp+2].trap_eflags,2
    jnz t2_vm
    call prot_exception
    jmp t2_ret
t2_vm:
    call virt_exception
t2_ret:
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
    call virt_exception
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
    GetThread
    mov ds,ax
    mov bx,OFFSET p_math_control
    clts
    db 9Bh, 66h, 0DDh, 27h      ;       32-bit frstor [bx]
;
    mov bx,core_data_sel
    mov ds,bx
    mov ds:ps_math_thread,ax
    lock or ds:ps_flags,PS_FLAG_FPU

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

trap_13:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,13
    push ax
    push ds
;
    mov ax,system_data_sel
    mov ds,ax
    call ds:enter_patch_proc
;
    test byte ptr [ebp+2].trap_eflags,2
    jnz t13_default
;    
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
    cmp ax,3
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
;           NAME:           TRAP_16
;
;           DESCRIPTION:    Co-processor error
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_16:
    push dword ptr 0
    push ebp
    mov ebp,esp
    sti
    push eax
    push ebx
    mov ax,16
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
    ShutDownPreTask

pretask2:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,2
    push ax
    push ds
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
    ShutDownPreTask

pretask8:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,8
    push ax
    push ds
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
    ShutDownPreTask

pretask10:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,10
    push ax
    push ds
    ShutDownPreTask

pretask11:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,11
    push ax
    push ds
    ShutDownPreTask

pretask12:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,12
    push ax
    push ds
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
;           NAME:           SetupIntGate
;
;           description:    Setup int gate
;
;           PARAMETERS:     AL              Int #
;                           BL              DPL
;                           DS:ESI          Entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_int_gate_name DB 'Setup Int Gate',0

setup_int_gate     Proc far
    push ds
    push ax
    push bx
;
    call local_create_int_gate_sel
    mov bx,irq_data_sel
    mov ds,bx
    mov bx,OFFSET irq_bitmask
    movzx ax,al
    bts [bx],ax
;
    pop bx
    pop ax
    pop ds    
    retf32
setup_int_gate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupTrapGate
;
;           description:    Setup trap gate
;
;           PARAMETERS:     AL              Int #
;                           BL              DPL
;                           DS:ESI          Entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_trap_gate_name DB 'Setup Trap Gate',0

setup_trap_gate     Proc far
    push ds
    push ax
    push bx
;
    call local_create_trap_gate_sel
    mov bx,irq_data_sel
    mov ds,bx
    mov bx,OFFSET irq_bitmask
    movzx ax,al
    bts [bx],ax
;
    pop bx
    pop ax
    pop ds    
    retf32
setup_trap_gate     Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateInts
;
;       DESCRIPTION:    Allocate interrupts
;
;       PARAMETERS:     CX      Number of ints (1,2,4,8,16 or 32)
;                       AL      Priority (0..31)
;
;       RETURNS:        AL      Base int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_ints_name    DB 'Allocate Ints',0

allocate_ints  Proc far
    push ds
    push cx
    push edx
    push si
;    
    mov dx,irq_data_sel
    mov ds,dx
;    
    and al,1Fh
    movzx si,al
    add si,OFFSET irq_bitmask
    shl al,3
;
    cmp cx,32
    ja aiFailed
;
    cmp cx,16
    jbe aiNot32

ai32:
    test al,1Fh
    jnz aiFailed

ai32Loop:
    mov edx,ds:[si]
    or edx,edx
    jz ai32Ok
;
    add al,32
    jc aiFailed
;
    add si,4
    jmp ai32Loop
    
ai32Ok:
    mov edx,-1
    mov ds:[si],edx    
    jmp aiOk

aiNot32:    
    cmp cx,8
    jbe aiNot16

ai16:
    test al,0Fh
    jnz aiFailed

ai16Loop:
    mov dx,ds:[si]
    or dx,dx
    jz ai16Ok
;
    add al,16
    jc aiFailed
;
    add si,2
    jmp ai16Loop
    
ai16Ok:
    mov dx,-1
    mov ds:[si],dx    
    jmp aiOk

aiNot16:
    cmp cx,4
    jbe aiNot8

ai8:

ai8Loop:
    mov dl,ds:[si]
    or dl,dl
    jz ai8Ok
;
    add al,8
    jc aiFailed
;
    inc si
    jmp ai8Loop
    
ai8Ok:
    mov dl,-1
    mov ds:[si],dl
    jmp aiOk
        
aiNot8:
    cmp cx,2
    jbe aiNot4

ai4:

ai4Loop:
    mov dl,ds:[si]
    mov dh,0Fh
    test dl,dh
    jz ai4Ok
;
    add al,4
    shl dh,4
    test dl,dh
    jz ai4Ok
;    
    add al,4
    jc aiFailed
;
    inc si
    jmp ai4Loop

ai4Ok:
    or ds:[si],dh
    jmp aiOk
        
aiNot4:
    cmp cx,1
    jbe ai1

ai2:

ai2Loop:
    mov cx,4
    mov dl,ds:[si]
    mov dh,3

ai2BitLoop:    
    test dl,dh
    jz ai2Ok
;
    add al,2
    jc aiFailed
;
    shl dh,2
    loop ai2BitLoop
;
    inc si
    jmp ai2Loop

ai2Ok:
    or ds:[si],dh
    jmp aiOk

ai1:

ai1Loop:
    mov cx,8
    mov dl,ds:[si]
    mov dh,1

ai1BitLoop:    
    test dl,dh
    jz ai1Ok
;
    add al,1
    jc aiFailed
;
    shl dh,1
    loop ai1BitLoop
;
    inc si
    jmp ai1Loop

ai1Ok:
    or ds:[si],dh

aiOk:
    clc
    jmp aiDone

aiFailed:
    stc

aiDone:    
    pop si
    pop edx
    pop cx
    pop ds    
    retf32
allocate_ints  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeInt
;
;       DESCRIPTION:    Free a single int vector
;
;       PARAMETERS:     AL      Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_int_name    DB 'Free Int',0

free_int  Proc far
    push ds
    push ax
    push si
;    
    mov si,irq_data_sel
    mov ds,si
;
    movzx ax,al
    mov si,OFFSET irq_bitmask
    btc ds:[si],ax
;
    pop si
    pop ax
    pop ds
    retf32
free_int    Endp

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
    mov ax,SIZE irq_data_seg
    mov bx,irq_data_sel
    AllocateFixedSystemMem
    mov ds,bx
;
    mov bx,OFFSET irq_bitmask
    mov cx,4

init_used_irq_loop:
    mov byte ptr ds:[bx],0FFh
    inc bx
    loop init_used_irq_loop
;
    mov cx,32-4

init_avail_irq_loop:
    mov byte ptr ds:[bx],0
    inc bx
    loop init_avail_irq_loop
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
    mov esi,OFFSET setup_int_gate
    mov edi,OFFSET setup_int_gate_name
    xor cl,cl
    mov ax,setup_int_gate_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_trap_gate
    mov edi,OFFSET setup_trap_gate_name
    xor cl,cl
    mov ax,setup_trap_gate_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_ints
    mov edi,OFFSET allocate_ints_name
    xor cl,cl
    mov ax,allocate_ints_nr
    RegisterOsGate
;
    mov esi,OFFSET free_int
    mov edi,OFFSET free_int_name
    xor cl,cl
    mov ax,free_int_nr
    RegisterOsGate
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
    mov si,OFFSET debug_exception
    mov di,OFFSET debug_exception_name
    xor cl,cl
    mov ax,debug_exception_nr
    RegisterOsGate
;
    mov si,OFFSET locked_debug_exception
    mov di,OFFSET locked_debug_exception_name
    xor cl,cl
    mov ax,locked_debug_exception_nr
    RegisterOsGate
;
    mov si,OFFSET get_debug_thread_sel
    mov di,OFFSET get_debug_thread_sel_name
    xor cl,cl
    mov ax,get_debug_thread_sel_nr
    RegisterOsGate
;
    mov si,OFFSET get_debug_thread
    mov di,OFFSET get_debug_thread_name
    xor dx,dx
    mov ax,get_debug_thread_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_trace
    mov di,OFFSET debug_trace_name
    xor dx,dx
    mov ax,debug_trace_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_pace
    mov di,OFFSET debug_pace_name
    xor dx,dx
    mov ax,debug_pace_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_go
    mov di,OFFSET debug_go_name
    xor dx,dx
    mov ax,debug_go_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_run
    mov di,OFFSET debug_run_name
    xor dx,dx
    mov ax,debug_run_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET debug_next
    mov di,OFFSET debug_next_name
    xor dx,dx
    mov ax,debug_next_nr
    RegisterBimodalUserGate
;
    mov bx,OFFSET set_code_break16
    mov si,OFFSET set_code_break32
    mov edi,OFFSET set_code_break_name
    mov dx,virt_es_in
    mov ax,set_code_break_nr
    RegisterUserGate
;
    mov bx,OFFSET set_read_data_break16
    mov si,OFFSET set_read_data_break32
    mov di,OFFSET set_read_data_break_name
    mov dx,virt_es_in
    mov ax,set_read_data_break_nr
    RegisterUserGate
;
    mov bx,OFFSET set_write_data_break16
    mov si,OFFSET set_write_data_break32
    mov di,OFFSET set_write_data_break_name
    mov dx,virt_es_in
    mov ax,set_write_data_break_nr
    RegisterUserGate
;
    mov si,OFFSET clear_break
    mov di,OFFSET clear_break_name
    xor dx,dx
    mov ax,clear_break_nr
    RegisterBimodalUserGate
    ret
init_trap_vectors       ENDP


code    ENDS

    END
