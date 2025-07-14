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
; WAIT.ASM
; Abortable single & multiple wait functionality
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
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE ..\apicheck.inc

wait_handle_seg STRUC

wh_handle_base  handle_header <>
wh_section      section_typ <>
wh_obj_list     DW ?
wh_thread       DW ?
wh_running      DB ?

wait_handle_seg ENDS

signal_wait_header      STRUC

sig_obj         wait_obj_header <>
sig_handle          DW ?

signal_wait_header      ENDS

signal_handle_seg           STRUC

sig_handle_base handle_header <>

sig_wait_obj        DW ?
sig_state           DB ?
sig_lock            DB ?

signal_handle_seg           ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

LockWaitObj Macro
    local lock_loop
    local lock_get
    local lock_done

lock_loop:
    sti
    mov al,ds:[ebx].sig_lock
    or al,al
    je lock_get
;
    pause
    jmp lock_loop

lock_get:
    cli
    inc al
    xchg al,ds:[ebx].sig_lock
    or al,al
    je lock_done
;
    jmp lock_loop

lock_done:
    Endm

UnlockWaitObj Macro
    mov ds:[ebx].sig_lock,0
    sti
            Endm
code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_wait
;
;           DESCRIPTION:    Delete contents in wait handle
;
;       PARAMETERS:     DS:EBX       Wait struct
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_wait Proc near
    push es
    push dx
;    
    mov dx,ds:[ebx].wh_obj_list
    or dx,dx
    jz delete_wait_done

delete_wait_loop:
    mov es,dx
    call fword ptr es:wo_delete_proc
    mov dx,es:wo_next
    FreeMem
    or dx,dx
    jnz delete_wait_loop

delete_wait_done:
    pop dx
    pop es
    ret
delete_wait Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateWait
;
;           DESCRIPTION:    Create a wait handle
;
;       RETURNS:    BX      Wait handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_wait_name    DB 'Create Wait', 0

create_wait Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push cx
;
    mov cx,SIZE wait_handle_seg
    AllocateHandle
    mov [ebx].hh_sign,WAIT_HANDLE
    mov [ebx].wh_obj_list,0
    mov [ebx].wh_running,0
    mov [ebx].wh_thread,0
    InitSection ds:[ebx].wh_section 
    mov bx,[ebx].hh_handle
    clc
;
    pop cx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
create_wait ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseWait
;
;           DESCRIPTION:    Close a wait handle
;
;       PARAMETERS:     BX      Wait handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_wait_name    DB 'Close Wait', 0

close_wait Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push ebx
;
    mov ax,WAIT_HANDLE
    DerefHandle
    jc close_wait_done
;
    call delete_wait
;
    FreeHandle
    clc

close_wait_done:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
close_wait ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    BX              Wait handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ax
    push ebx
;
    mov ax,WAIT_HANDLE
    DerefHandle
    jc delete_handle_done
;
    call delete_wait

delete_handle_done:
    pop ebx
    pop ax
    pop ds
    retf32
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsWaitIdle
;
;           DESCRIPTION:    Check if wait is idle
;
;       PARAMETERS:     BX      Wait handle
;
;       RETURNS:    NC
;                               ECX     Non-idle ID
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_wait_idle_name    DB 'Is Wait Idle', 0

is_wait_idle Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push es
    push eax
    push ebx
    push dx
;
    xor ecx,ecx
    mov ax,WAIT_HANDLE
    DerefHandle
    jc is_wait_idle_done
;
    EnterSection ds:[ebx].wh_section
    mov dx,ds:[ebx].wh_obj_list
    or dx,dx
    jz is_wait_idle_ok_leave

is_wait_idle_loop:
    mov es,dx
    call fword ptr es:wo_idle_proc
    jc is_wait_idle_fail_leave
;
    mov dx,es:wo_next
    or dx,dx
    jnz is_wait_idle_loop

is_wait_idle_ok_leave:
    LeaveSection ds:[ebx].wh_section
    clc
    jmp is_wait_idle_done

is_wait_idle_fail_leave:
    mov ecx,es:wo_id
    LeaveSection ds:[ebx].wh_section
    stc

is_wait_idle_done:
    pop dx
    pop ebx
    pop eax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEbx
    ApiCheckEax
    retf32
is_wait_idle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WaitWithoutTimeout
;
;           DESCRIPTION:    Wait without timeout
;
;       PARAMETERS:     BX      Wait handle
;
;       RETURNS:    ECX     Signalled ID
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_no_timeout_name    DB 'Wait Without Timeout', 0

wait_no_timeout Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push es
    push eax
    push ebx
    push dx
;
    xor ecx,ecx
    mov ax,WAIT_HANDLE
    DerefHandle
    jc wait_no_timeout_done
;
    EnterSection ds:[ebx].wh_section
    mov al,ds:[ebx].wh_running
    or al,al
    jnz wait_no_timeout_stopped_leave
;
    GetThread
    mov ds:[ebx].wh_thread,ax
    ClearSignal
    mov dx,ds:[ebx].wh_obj_list
    or dx,dx
    jz wait_no_timeout_start_leave

wait_no_timeout_start_loop:
    mov es,dx
    mov es:wo_thread,ax
    mov es:wo_signalled,0
    call fword ptr es:wo_init_proc
    mov dx,es:wo_next
    or dx,dx
    jnz wait_no_timeout_start_loop

wait_no_timeout_start_leave:
    inc ds:[ebx].wh_running
    LeaveSection ds:[ebx].wh_section

wait_no_timeout_do:
    xor ax,ax
    mov es,ax
    WaitForSignal
;
    EnterSection ds:[ebx].wh_section
    mov al,ds:[ebx].wh_running
    or al,al
    jz wait_no_timeout_stopped_leave
;
    dec ds:[ebx].wh_running
    mov ax,ds:[ebx].wh_obj_list
    or ax,ax
    jz wait_no_timeout_stopped_leave

wait_no_timeout_stop_loop:
    mov es,ax
    mov ax,es:wo_signalled
    or ax,ax
    jnz wait_no_timeout_stop_signalled
;
    call fword ptr es:wo_abort_proc
    jmp wait_no_timeout_stop_next

wait_no_timeout_stop_signalled:
    or ecx,ecx
    jnz wait_no_timeout_stop_next
;
    mov ecx,es:wo_id
    call fword ptr es:wo_clear_proc

wait_no_timeout_stop_next:
    mov ax,es:wo_next
    or ax,ax
    jnz wait_no_timeout_stop_loop

wait_no_timeout_stopped_leave:
    LeaveSection ds:[ebx].wh_section
    clc

wait_no_timeout_done:
    pop dx
    pop ebx
    pop eax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEbx
    ApiCheckEax
    retf32
wait_no_timeout  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           timeout_wait
;
;           DESCRIPTION:    Timeout on wait 
;
;       PARAMETERS:     CX       thread to signal
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timeout_wait Proc far
    mov bx,cx
    Signal
    retf32
timeout_wait  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WaitWithTimeout
;
;           DESCRIPTION:    Wait with timeout
;
;       PARAMETERS:     BX      Wait handle
;                           EDX:EAX Timeout time
;
;       RETURNS:    ECX     Signalled ID
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_timeout_name    DB 'Wait With Timeout', 0

wait_timeout Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push es
    push eax
    push ebx
    push dx
    push edi
;
    push ax
    xor ecx,ecx
    mov ax,WAIT_HANDLE
    DerefHandle
    pop ax
    jc wait_timeout_done
;
    EnterSection ds:[ebx].wh_section
    push ax
    mov al,ds:[ebx].wh_running
    or al,al
    pop ax
    jnz wait_timeout_stopped_leave
;
    push eax
    push edx
    GetThread
    mov ds:[ebx].wh_thread,ax
    ClearSignal
    mov dx,ds:[ebx].wh_obj_list
    or dx,dx
    jz wait_timeout_start_timer

wait_timeout_start_loop:
    mov es,dx
    mov es:wo_thread,ax
    mov es:wo_signalled,0
    push ax
    call fword ptr es:wo_init_proc
    pop ax
    mov dx,es:wo_next
    or dx,dx
    jnz wait_timeout_start_loop

wait_timeout_start_timer:
    GetThread
    mov cx,ax
    mov ax,cs
    mov es,ax
    pop edx
    pop eax
;
    push bx
    mov bx,cx
    mov edi,OFFSET timeout_wait
    StartTimer
    pop bx
;
    inc ds:[ebx].wh_running
    LeaveSection ds:[ebx].wh_section

wait_timeout_do:
    xor ax,ax
    mov es,ax
    WaitForSignal
;
    push bx
    mov bx,cx
    StopTimer
    pop bx
;
    xor ecx,ecx
    EnterSection ds:[ebx].wh_section
    mov al,ds:[ebx].wh_running
    or al,al
    jz wait_timeout_stopped_leave
;
    dec ds:[ebx].wh_running
    mov ax,ds:[ebx].wh_obj_list
    or ax,ax
    jz wait_timeout_stopped_leave

wait_timeout_stop_loop:
    mov es,ax
    mov ax,es:wo_signalled
    or ax,ax
    jnz wait_timeout_stop_signalled
;
    call fword ptr es:wo_abort_proc
    jmp wait_timeout_stop_next

wait_timeout_stop_signalled:
    or ecx,ecx
    jnz wait_timeout_stop_next
;
    mov ecx,es:wo_id
    call fword ptr es:wo_clear_proc

wait_timeout_stop_next:
    mov ax,es:wo_next
    or ax,ax
    jnz wait_timeout_stop_loop

wait_timeout_stopped_leave:
    LeaveSection ds:[ebx].wh_section
    clc

wait_timeout_done:
    pop edi
    pop dx
    pop ebx
    pop eax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEbx
    ApiCheckEax
    retf32
wait_timeout  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWait
;
;           DESCRIPTION:    Stop a wait
;
;       PARAMETERS:     BX      Wait handle
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_name    DB 'Stop Wait', 0

stop_wait Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push es
    push eax
    push ebx
;
    mov ax,WAIT_HANDLE
    DerefHandle
    jc stop_wait_done
;
    EnterSection ds:[ebx].wh_section
    mov al,ds:[ebx].wh_running
    or al,al
    jz stop_wait_leave
;
    dec ds:[ebx].wh_running
    mov ax,ds:[ebx].wh_obj_list
    or ax,ax
    jz stop_wait_signal

stop_wait_loop:
    mov es,ax
    mov ax,es:wo_signalled
    or ax,ax
    jnz stop_wait_next
;
    call fword ptr es:wo_abort_proc

stop_wait_next:
    mov ax,es:wo_next
    or ax,ax
    jnz stop_wait_loop

stop_wait_signal:
    push bx
    mov bx,ds:[ebx].wh_thread
    Signal
    pop bx

stop_wait_leave:
    LeaveSection ds:[ebx].wh_section
    clc

stop_wait_done:
    pop ebx
    pop eax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
stop_wait  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DefaultDelete
;
;       DESCRIPTION:    Default delete method
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_delete:
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWait
;
;           DESCRIPTION:    Add a generic wait object
;
;       PARAMETERS:     AX      Extra bytes needed in wait object
;                       BX      Wait handle
;                       ECX     Signalled ID
;                       ES:EDI   Method table
;
;       RETURNS:        ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_name   DB 'Add Wait', 0

add_wait    Proc far
    push ds
    push fs
    pushad
;
    mov si,es
    mov fs,si
    mov esi,edi
;
    push ax
    mov ax,WAIT_HANDLE
    DerefHandle
    pop ax
    jc add_wait_done
;
    EnterSection ds:[ebx].wh_section
;    
    movzx eax,ax
    add eax,SIZE wait_obj_header
    AllocateSmallGlobalMem
;
    mov es:wo_id,ecx
    mov edi,OFFSET wo_init_proc
    mov ecx,8
    rep movs dword ptr es:[edi],fs:[esi]
;
    mov es:wo_delete_proc,OFFSET default_delete
    mov es:wo_delete_proc+4,cs
;
    mov ax,ds:[ebx].wh_obj_list
    mov es:wo_next,ax
    mov ds:[ebx].wh_obj_list,es
;
    mov al,ds:[ebx].wh_running
    or al,al
    jz awLeave
;
    mov ax,ds:[ebx].wh_thread
    or ax,ax
    jz awLeave
;
    push bx
    mov bx,ax
    Signal
    pop bx

awLeave:
    LeaveSection ds:[ebx].wh_section
    clc

add_wait_done:
    popad
    pop fs
    pop ds
    retf32
add_wait    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddWaitDelete
;
;       DESCRIPTION:    Add a generic wait object with delete method
;
;       PARAMETERS:     AX      Extra bytes needed in wait object
;                       BX      Wait handle
;                       ECX     Signalled ID
;                       ES:EDI   Method table
;
;       RETURNS:        ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_del_name   DB 'Add Wait Delete', 0

add_wait_del    Proc far
    push ds
    push fs
    pushad
;
    mov si,es
    mov fs,si
    mov esi,edi
;
    push ax
    mov ax,WAIT_HANDLE
    DerefHandle
    pop ax
    jc awdDone
;
    EnterSection ds:[ebx].wh_section
;    
    movzx eax,ax
    add eax,SIZE wait_obj_header
    AllocateSmallGlobalMem
;
    mov es:wo_id,ecx
    mov edi,OFFSET wo_init_proc
    mov ecx,10
    rep movs dword ptr es:[edi],fs:[esi]
;
    mov ax,ds:[ebx].wh_obj_list
    mov es:wo_next,ax
    mov ds:[ebx].wh_obj_list,es
;
    mov al,ds:[ebx].wh_running
    or al,al
    jz awdLeave
;
    mov ax,ds:[ebx].wh_thread
    or ax,ax
    jz awdLeave
;
    push bx
    mov bx,ax
    Signal
    pop bx

awdLeave:
    LeaveSection ds:[ebx].wh_section
    clc

awdDone:
    popad
    pop fs
    pop ds
    retf32
add_wait_del    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveWait
;
;           DESCRIPTION:    Remove a wait object
;
;       PARAMETERS:     BX      Wait handle
;               ECX     Signal ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_wait_name   DB 'Remove Wait', 0

remove_wait    Proc far
    push ds
    push es
    push ax
    push ebx
    push dx
;
    mov ax,WAIT_HANDLE
    DerefHandle
    jc remove_wait_done
;
    EnterSection ds:[ebx].wh_section
;
    xor dx,dx
    mov ax,ds:[ebx].wh_obj_list
    
remove_wait_loop:
    or ax,ax
    jz remove_wait_leave
;
    mov es,ax
    cmp ecx,es:wo_id
    je remove_wait_do
;
    mov dx,es
    mov ax,es:wo_next
    jmp remove_wait_loop

remove_wait_do:
    mov ax,es:wo_next
    call fword ptr es:wo_delete_proc
    FreeMem
    or dx,dx
    jz remove_wait_head
;
    mov es,dx
    mov es:wo_next,ax
    jmp remove_wait_loop

remove_wait_head:
    mov ds:[ebx].wh_obj_list,ax
    jmp remove_wait_loop

remove_wait_leave:
    LeaveSection ds:[ebx].wh_section
    clc

remove_wait_done:
    pop dx
    pop ebx
    pop ax
    pop es
    pop ds
    retf32
remove_wait    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SignalWait
;
;           DESCRIPTION:    Signal object
;
;       PARAMETERS:     ES      object
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_wait_name    DB 'Signal Wait',0

signal_wait Proc far
    push bx
    inc es:wo_signalled
    mov bx,es:wo_thread
    Signal
    pop bx
    retf32
signal_wait Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_signal_handle
;
;           DESCRIPTION:    Delete signal handle (called from handle module)
;
;           PARAMETERS:         BX          Signal handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_signal_handle    Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc delete_signal_handle_done
;
    FreeHandle

delete_signal_handle_done:
    pop dx
    pop ax
    pop es
    pop ds
    retf32
delete_signal_handle    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSignal
;
;           DESCRIPTION:    Create a new signal handle
;
;           RETURNS:        BX          Signal handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_signal_name DB 'Create Signal',0

create_signal   Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push cx
;    
    mov ax,SIGNAL_HANDLE
    mov cx,SIZE signal_handle_seg
    AllocateHandle
    mov [ebx].sig_wait_obj,0
    mov [ebx].sig_state,0
    mov [ebx].sig_lock,0
    mov [ebx].hh_sign,SIGNAL_HANDLE
    mov bx,[ebx].hh_handle
;
    pop cx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
create_signal   Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetSignal
;
;           DESCRIPTION:    Reset signal (to inactive)
;
;           PARAMETERS:         BX          Signal handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_signal_name DB 'Reset Signal',0

reset_signal   Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push ebx
;    
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc reset_sig_done
;
    mov ds:[ebx].sig_state,0

reset_sig_done:
    sti
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
reset_signal Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsSignalled
;
;           DESCRIPTION:    Is signal active (CLC)
;
;           PARAMETERS:         BX          Signal handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_signalled_name DB 'Is Signalled',0

is_signalled   Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push ebx
;    
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc is_sig_done
;
    mov al,ds:[ebx].sig_state
    or al,al
    stc
    jz is_sig_done
;
    clc

is_sig_done:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
is_signalled Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSignal
;
;           DESCRIPTION:    Set signal (to active)
;
;           PARAMETERS:         BX          Signal handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_signal_name DB 'Set Signal',0

set_signal   Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push es
    push ax
    push ebx
;    
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc set_sig_done
;
    LockWaitObj
    mov ds:[ebx].sig_state,1
    mov ax,ds:[ebx].sig_wait_obj
    or ax,ax
    jz set_sig_unlock
;
    mov ds:[ebx].sig_wait_obj,0
    mov es,ax
    inc es:wo_signalled
    UnlockWaitObj
;        
    mov bx,es:wo_thread
    Signal
    jmp set_sig_done

set_sig_unlock:
    UnlockWaitObj

set_sig_done:
    pop ebx
    pop ax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
set_signal Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeSignal
;
;           DESCRIPTION:    Free a signal handle
;
;           PARAMETERS:         BX          Signal handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_signal_name DB 'Free Signal',0

free_signal   Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push ebx
;    
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc free_sig_done
;
    FreeHandle

free_sig_done:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
free_signal Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForSignal
;
;           DESCRIPTION:    Start a wait for signal
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_signal   PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:sig_handle
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc start_wait_for_done
;
    LockWaitObj
    mov ds:[ebx].sig_wait_obj,es
    mov al,ds:[ebx].sig_state
    or al,al
    je start_wait_for_unlock
;
    mov ds:[ebx].sig_state,0
    mov ds:[ebx].sig_wait_obj,0
    inc es:wo_signalled
    UnlockWaitObj
;
    mov bx,es:wo_thread
    Signal
    jmp start_wait_for_done

start_wait_for_unlock:    
    UnlockWaitObj

start_wait_for_done:
    pop ebx
    pop ax
    pop ds
    retf32
start_wait_for_signal Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForSignal
;
;           DESCRIPTION:    Stop a wait for signal
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_signal    PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:sig_handle
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc stop_wait_signal_done
;
    LockWaitObj
    mov ds:[ebx].sig_wait_obj,0
    UnlockWaitObj

stop_wait_signal_done:
    pop ebx
    pop ax
    pop ds
    retf32
stop_wait_for_signal Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearSignal
;
;           DESCRIPTION:    Clear signal
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_signal    PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:sig_handle
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc clear_signal_done
;
    mov ds:[ebx].sig_state,0

clear_signal_done:
    pop ebx
    pop ax
    pop ds
    retf32
clear_signal Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsSignalIdle
;
;           DESCRIPTION:    Check if signal is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_signal_idle  PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:sig_handle
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc is_idle_done
;
    mov al,ds:[ebx].sig_state
    or al,al
    clc
    je is_idle_done
;
    stc

is_idle_done:
    pop ebx
    pop ax
    pop ds
    retf32
is_signal_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForSignal
;
;           DESCRIPTION:    Add a wait for a signal object
;
;           PARAMETERS:         AX      Signal handle
;               BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_signal_name    DB 'Add Wait For Signal',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_signal,    SEG code
aw1 DD OFFSET stop_wait_for_signal,     SEG code
aw2 DD OFFSET clear_signal,             SEG code
aw3 DD OFFSET is_signal_idle,           SEG code

add_wait_for_signal     PROC far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE signal_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_signal_done
;
    mov es:sig_handle,ax

add_wait_signal_done:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_signal     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    Init device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_wait

init_wait       PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ax,WAIT_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov ax,SIGNAL_HANDLE
    mov edi,OFFSET delete_signal_handle
    RegisterHandle
;
    mov esi,OFFSET add_wait
    mov edi,OFFSET add_wait_name
    mov ax,add_wait_nr
    RegisterOsGate
;
    mov esi,OFFSET add_wait_del
    mov edi,OFFSET add_wait_del_name
    mov ax,add_wait_del_nr
    RegisterOsGate
;
    mov esi,OFFSET signal_wait
    mov edi,OFFSET signal_wait_name
    mov ax,signal_wait_nr
    RegisterOsGate
;
    mov esi,OFFSET create_wait
    mov edi,OFFSET create_wait_name
    xor dx,dx
    mov ax,create_wait_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_wait
    mov edi,OFFSET close_wait_name
    xor dx,dx
    mov ax,close_wait_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_wait_idle
    mov edi,OFFSET is_wait_idle_name
    xor dx,dx
    mov ax,is_wait_idle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_no_timeout
    mov edi,OFFSET wait_no_timeout_name
    xor dx,dx
    mov ax,wait_no_timeout_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_timeout
    mov edi,OFFSET wait_timeout_name
    xor dx,dx
    mov ax,wait_timeout_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_wait
    mov edi,OFFSET stop_wait_name
    xor dx,dx
    mov ax,stop_wait_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET remove_wait
    mov edi,OFFSET remove_wait_name
    xor dx,dx
    mov ax,remove_wait_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_signal
    mov edi,OFFSET create_signal_name
    xor dx,dx
    mov ax,create_signal_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_signal
    mov edi,OFFSET reset_signal_name
    xor dx,dx
    mov ax,reset_signal_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_signalled
    mov edi,OFFSET is_signalled_name
    xor dx,dx
    mov ax,is_signalled_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_signal
    mov edi,OFFSET set_signal_name
    xor dx,dx
    mov ax,set_signal_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET free_signal
    mov edi,OFFSET free_signal_name
    xor dx,dx
    mov ax,free_signal_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_signal
    mov edi,OFFSET add_wait_for_signal_name
    xor dx,dx
    mov ax,add_wait_for_signal_nr
    RegisterBimodalUserGate
    ret
init_wait       ENDP

code    ENDS

    END
