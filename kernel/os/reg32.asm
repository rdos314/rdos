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
INCLUDE proc.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte use16 public 'CODE'

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
    CrashTss
    
double_fault_lock_ok:    
    mov ax,fs:ps_curr_thread
    or ax,ax
    jz double_crash
;
    cmp ax,fs:ps_null_thread
    je double_crash
;
    mov es,ax    
    mov es:p_fault_vector,8
    mov es:p_fault_code,0
;
    mov eax,es:p_tss_eax
    mov dword ptr es:p_tss_rax,eax
;
    mov eax,es:p_tss_ebx
    mov dword ptr es:p_tss_rbx,eax
;
    mov eax,es:p_tss_ecx
    mov dword ptr es:p_tss_rcx,eax
;
    mov eax,es:p_tss_edx
    mov dword ptr es:p_tss_rdx,eax
;
    mov eax,es:p_tss_esi
    mov dword ptr es:p_tss_rsi,eax
;
    mov eax,es:p_tss_edi
    mov dword ptr es:p_tss_rdi,eax
;
    mov eax,es:p_tss_ebp
    mov dword ptr es:p_tss_rbp,eax
;
    mov eax,es:p_tss_esp
    mov dword ptr es:p_tss_rsp,eax
;
    mov eax,es:p_tss_eip
    mov dword ptr es:p_tss_rip,eax
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
    mov eax,ds:p_tss_cr3
    mov es:[edi].ut_cr3,eax
;    
    mov eax,ds:p_tss_eip
    mov es:[edi].ut_eip,eax
;    
    mov eax,ds:p_tss_eflags
    mov es:[edi].ut_eflags,eax
;    
    mov eax,ds:p_tss_eax
    mov es:[edi].ut_eax,eax
;    
    mov eax,ds:p_tss_ecx
    mov es:[edi].ut_ecx,eax
;    
    mov eax,ds:p_tss_edx
    mov es:[edi].ut_edx,eax
;    
    mov eax,ds:p_tss_ebx
    mov es:[edi].ut_ebx,eax
;    
    mov eax,ds:p_tss_esp
    mov es:[edi].ut_esp,eax
;    
    mov eax,ds:p_tss_ebp
    mov es:[edi].ut_ebp,eax
;    
    mov eax,ds:p_tss_esi
    mov es:[edi].ut_esi,eax
;    
    mov eax,ds:p_tss_edi
    mov es:[edi].ut_edi,eax
;    
    mov ax,ds:p_tss_es
    mov es:[edi].ut_es,ax
;    
    mov ax,ds:p_tss_cs
    mov es:[edi].ut_cs,ax
;    
    mov ax,ds:p_tss_ss
    mov es:[edi].ut_ss,ax
;    
    mov ax,ds:p_tss_ds
    mov es:[edi].ut_ds,ax
;    
    mov ax,ds:p_tss_fs
    mov es:[edi].ut_fs,ax
;    
    mov ax,ds:p_tss_gs
    mov es:[edi].ut_gs,ax
;    
    mov ax,ds:p_tss_ldt
    mov es:[edi].ut_ldt,ax
;    
    mov eax,ds:p_tss_dr0
    mov es:[edi].ut_dr0,eax
;    
    mov eax,ds:p_tss_dr1
    mov es:[edi].ut_dr1,eax
;    
    mov eax,ds:p_tss_dr2
    mov es:[edi].ut_dr2,eax
;    
    mov eax,ds:p_tss_dr3
    mov es:[edi].ut_dr3,eax
;    
    mov eax,ds:p_tss_dr7
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
    mov es:p_tss_eip,eax
;    
    mov eax,ds:[esi].ut_eflags
    mov es:p_tss_eflags,eax
;    
    mov eax,ds:[esi].ut_eax
    mov es:p_tss_eax,eax
;    
    mov eax,ds:[esi].ut_ecx
    mov es:p_tss_ecx,eax
;    
    mov eax,ds:[esi].ut_edx
    mov es:p_tss_edx,eax
;    
    mov eax,ds:[esi].ut_ebx
    mov es:p_tss_ebx,eax
;    
    mov eax,ds:[esi].ut_esp
    mov es:p_tss_esp,eax
;    
    mov eax,ds:[esi].ut_ebp
    mov es:p_tss_ebp,eax
;    
    mov eax,ds:[esi].ut_esi
    mov es:p_tss_esi,eax
;    
    mov eax,ds:[esi].ut_edi
    mov es:p_tss_edi,eax
;    
    mov ax,ds:[esi].ut_es
    mov es:p_tss_es,ax
;    
    mov ax,ds:[esi].ut_cs
    mov es:p_tss_cs,ax
;    
    mov ax,ds:[esi].ut_ss
    mov es:p_tss_ss,ax
;    
    mov ax,ds:[esi].ut_ds
    mov es:p_tss_ds,ax
;    
    mov ax,ds:[esi].ut_fs
    mov es:p_tss_fs,ax
;    
    mov ax,ds:[esi].ut_gs
    mov es:p_tss_gs,ax
;    
    mov ax,ds:[esi].ut_ldt
    mov es:p_tss_ldt,ax
;    
    mov eax,ds:[esi].ut_dr0
    mov es:p_tss_dr0,eax
;    
    mov eax,ds:[esi].ut_dr1
    mov es:p_tss_dr1,eax
;    
    mov eax,ds:[esi].ut_dr2
    mov es:p_tss_dr2,eax
;    
    mov eax,ds:[esi].ut_dr3
    mov es:p_tss_dr3,eax
;    
    mov eax,ds:[esi].ut_dr7
    mov es:p_tss_dr7,eax
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
